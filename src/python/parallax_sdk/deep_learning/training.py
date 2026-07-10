from __future__ import annotations

import copy
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Optional

import torch
from torch import Tensor, nn
from torch.nn.parallel import DistributedDataParallel
from torch.utils.data import DataLoader


@dataclass(frozen=True)
class EpochResult:
    loss: float
    metrics: dict[str, float] = field(default_factory=dict)


@dataclass(frozen=True)
class FitResult:
    best_metric: float
    best_epoch: int
    train_history: list[EpochResult]
    val_history: list[EpochResult]


class EarlyStopping:
    """Early stopping with patience and minimum improvement tracking."""

    def __init__(self, patience: int = 10, min_delta: float = 0.0, mode: str = "min") -> None:
        if mode not in {"min", "max"}:
            raise ValueError("mode must be 'min' or 'max'")
        self.patience = patience
        self.min_delta = min_delta
        self.mode = mode
        self.best_score = float("inf") if mode == "min" else float("-inf")
        self.bad_epochs = 0

    def _is_improvement(self, score: float) -> bool:
        if self.mode == "min":
            return score < self.best_score - self.min_delta
        return score > self.best_score + self.min_delta

    def step(self, score: float) -> bool:
        if self._is_improvement(score):
            self.best_score = score
            self.bad_epochs = 0
            return False
        self.bad_epochs += 1
        return self.bad_epochs > self.patience


class CheckpointManager:
    """Checkpoint saver with best-model tracking."""

    def __init__(self, directory: str | Path, monitor: str = "val_loss", mode: str = "min") -> None:
        if mode not in {"min", "max"}:
            raise ValueError("mode must be 'min' or 'max'")
        self.directory = Path(directory)
        self.directory.mkdir(parents=True, exist_ok=True)
        self.monitor = monitor
        self.mode = mode
        self.best_score = float("inf") if mode == "min" else float("-inf")
        self.best_path = self.directory / "best.pt"

    def _is_better(self, score: float) -> bool:
        return score < self.best_score if self.mode == "min" else score > self.best_score

    def save(
        self,
        model: nn.Module,
        optimizer: Optional[torch.optim.Optimizer],
        epoch: int,
        metrics: dict[str, float],
        scheduler: Optional[torch.optim.lr_scheduler.LRScheduler] = None,
    ) -> Path:
        state = {
            "model": model.state_dict(),
            "epoch": epoch,
            "metrics": metrics,
        }
        if optimizer is not None:
            state["optimizer"] = optimizer.state_dict()
        if scheduler is not None:
            state["scheduler"] = scheduler.state_dict()
        latest_path = self.directory / "last.pt"
        torch.save(state, latest_path)
        score = metrics[self.monitor]
        if self._is_better(score):
            self.best_score = score
            torch.save(state, self.best_path)
        return latest_path


class ExponentialMovingAverage:
    """EMA shadow weights for more stable validation checkpoints."""

    def __init__(self, model: nn.Module, decay: float = 0.999) -> None:
        self.decay = decay
        self.shadow = {name: parameter.detach().clone() for name, parameter in model.named_parameters() if parameter.requires_grad}

    def update(self, model: nn.Module) -> None:
        for name, parameter in model.named_parameters():
            if not parameter.requires_grad:
                continue
            self.shadow[name].mul_(self.decay).add_(parameter.detach(), alpha=1.0 - self.decay)

    def apply_to(self, model: nn.Module) -> dict[str, Tensor]:
        backup = {}
        for name, parameter in model.named_parameters():
            if name in self.shadow:
                backup[name] = parameter.detach().clone()
                parameter.data.copy_(self.shadow[name])
        return backup

    def restore(self, model: nn.Module, backup: dict[str, Tensor]) -> None:
        for name, parameter in model.named_parameters():
            if name in backup:
                parameter.data.copy_(backup[name])


@dataclass(frozen=True)
class DistributedContext:
    enabled: bool
    rank: int = 0
    world_size: int = 1
    local_rank: int = 0
    device: Optional[torch.device] = None


def setup_distributed() -> DistributedContext:
    if not torch.distributed.is_available() or not torch.distributed.is_initialized():
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        return DistributedContext(enabled=False, device=device)
    rank = torch.distributed.get_rank()
    world_size = torch.distributed.get_world_size()
    local_rank = int(torch.cuda.current_device()) if torch.cuda.is_available() else 0
    device = torch.device("cuda", local_rank) if torch.cuda.is_available() else torch.device("cpu")
    return DistributedContext(enabled=True, rank=rank, world_size=world_size, local_rank=local_rank, device=device)


def maybe_wrap_distributed(model: nn.Module, context: DistributedContext) -> nn.Module:
    if not context.enabled:
        return model.to(context.device)
    if context.device is None:
        raise ValueError("Distributed context must include a device")
    model = model.to(context.device)
    if context.device.type == "cuda":
        return DistributedDataParallel(model, device_ids=[context.local_rank], output_device=context.local_rank)
    return DistributedDataParallel(model)


def build_scheduler(
    optimizer: torch.optim.Optimizer,
    schedule: str,
    *,
    total_epochs: int,
    steps_per_epoch: int,
    max_lr: Optional[float] = None,
) -> torch.optim.lr_scheduler.LRScheduler:
    schedule = schedule.lower()
    if schedule == "cosine":
        return torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=total_epochs)
    if schedule == "onecycle":
        if max_lr is None:
            raise ValueError("max_lr is required for OneCycleLR")
        return torch.optim.lr_scheduler.OneCycleLR(optimizer, max_lr=max_lr, epochs=total_epochs, steps_per_epoch=steps_per_epoch)
    if schedule == "plateau":
        return torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=3)
    raise ValueError(f"Unsupported schedule: {schedule}")


def _move_to_device(batch: object, device: torch.device) -> object:
    if isinstance(batch, Tensor):
        return batch.to(device)
    if isinstance(batch, (tuple, list)):
        return type(batch)(_move_to_device(item, device) for item in batch)
    if isinstance(batch, dict):
        return {key: _move_to_device(value, device) for key, value in batch.items()}
    return batch


def _default_loss_step(model: nn.Module, batch: object, criterion: Callable[[Tensor, Tensor], Tensor]) -> tuple[Tensor, Tensor]:
    if not isinstance(batch, (tuple, list)) or len(batch) < 2:
        raise ValueError("Expected batch to be a tuple/list of (inputs, targets)")
    inputs, targets = batch[0], batch[1]
    predictions = model(inputs)
    if hasattr(predictions, "prediction"):
        predictions = predictions.prediction
    loss = criterion(predictions, targets)
    return loss, predictions


def train_one_epoch(
    model: nn.Module,
    dataloader: DataLoader,
    optimizer: torch.optim.Optimizer,
    criterion: Callable[[Tensor, Tensor], Tensor],
    *,
    device: torch.device,
    scheduler: Optional[torch.optim.lr_scheduler.LRScheduler] = None,
    scaler: Optional[torch.cuda.amp.GradScaler] = None,
    grad_clip_norm: Optional[float] = None,
    metric_fns: Optional[dict[str, Callable[[Tensor, Tensor], Tensor]]] = None,
) -> EpochResult:
    model.train()
    total_loss = 0.0
    metric_sums = {name: 0.0 for name in (metric_fns or {})}
    for batch in dataloader:
        batch = _move_to_device(batch, device)
        optimizer.zero_grad(set_to_none=True)
        autocast_enabled = scaler is not None and device.type == "cuda"
        with torch.autocast(device_type=device.type, enabled=autocast_enabled):
            loss, predictions = _default_loss_step(model, batch, criterion)
        if scaler is not None and device.type == "cuda":
            scaler.scale(loss).backward()
            if grad_clip_norm is not None:
                scaler.unscale_(optimizer)
                nn.utils.clip_grad_norm_(model.parameters(), grad_clip_norm)
            scaler.step(optimizer)
            scaler.update()
        else:
            loss.backward()
            if grad_clip_norm is not None:
                nn.utils.clip_grad_norm_(model.parameters(), grad_clip_norm)
            optimizer.step()
        if scheduler is not None and not isinstance(scheduler, torch.optim.lr_scheduler.ReduceLROnPlateau):
            scheduler.step()
        total_loss += float(loss.detach().item())
        if metric_fns:
            targets = batch[1]
            for name, metric_fn in metric_fns.items():
                metric_sums[name] += float(metric_fn(predictions.detach(), targets).item())
    length = max(len(dataloader), 1)
    return EpochResult(loss=total_loss / length, metrics={name: value / length for name, value in metric_sums.items()})


@torch.no_grad()
def evaluate(
    model: nn.Module,
    dataloader: DataLoader,
    criterion: Callable[[Tensor, Tensor], Tensor],
    *,
    device: torch.device,
    metric_fns: Optional[dict[str, Callable[[Tensor, Tensor], Tensor]]] = None,
) -> EpochResult:
    model.eval()
    total_loss = 0.0
    metric_sums = {name: 0.0 for name in (metric_fns or {})}
    for batch in dataloader:
        batch = _move_to_device(batch, device)
        loss, predictions = _default_loss_step(model, batch, criterion)
        total_loss += float(loss.detach().item())
        if metric_fns:
            targets = batch[1]
            for name, metric_fn in metric_fns.items():
                metric_sums[name] += float(metric_fn(predictions, targets).item())
    length = max(len(dataloader), 1)
    return EpochResult(loss=total_loss / length, metrics={name: value / length for name, value in metric_sums.items()})


def fit(
    model: nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    optimizer: torch.optim.Optimizer,
    criterion: Callable[[Tensor, Tensor], Tensor],
    *,
    epochs: int,
    device: torch.device,
    scheduler: Optional[torch.optim.lr_scheduler.LRScheduler] = None,
    early_stopper: Optional[EarlyStopping] = None,
    checkpoint_manager: Optional[CheckpointManager] = None,
    metric_fns: Optional[dict[str, Callable[[Tensor, Tensor], Tensor]]] = None,
    monitor_metric: str = "val_loss",
    monitor_mode: str = "min",
    ema: Optional[ExponentialMovingAverage] = None,
    grad_clip_norm: Optional[float] = None,
    mixed_precision: bool = True,
) -> FitResult:
    if monitor_mode not in {"min", "max"}:
        raise ValueError("monitor_mode must be 'min' or 'max'")
    model.to(device)
    scaler = torch.cuda.amp.GradScaler(enabled=mixed_precision and device.type == "cuda")
    best_model_state = copy.deepcopy(model.state_dict())
    best_score = float("inf") if monitor_mode == "min" else float("-inf")
    best_epoch = 0
    train_history: list[EpochResult] = []
    val_history: list[EpochResult] = []

    for epoch in range(1, epochs + 1):
        train_result = train_one_epoch(
            model,
            train_loader,
            optimizer,
            criterion,
            device=device,
            scheduler=scheduler,
            scaler=scaler,
            grad_clip_norm=grad_clip_norm,
            metric_fns=metric_fns,
        )
        if ema is not None:
            ema.update(model)
            backup = ema.apply_to(model)
        else:
            backup = None
        val_result = evaluate(model, val_loader, criterion, device=device, metric_fns=metric_fns)
        if backup is not None and ema is not None:
            ema.restore(model, backup)

        train_history.append(train_result)
        val_history.append(val_result)
        metrics = {"train_loss": train_result.loss, "val_loss": val_result.loss, **{f"val_{k}": v for k, v in val_result.metrics.items()}}
        score = metrics[monitor_metric]
        is_better = score < best_score if monitor_mode == "min" else score > best_score
        if is_better:
            best_score = score
            best_epoch = epoch
            best_model_state = copy.deepcopy(model.state_dict())
        if checkpoint_manager is not None:
            checkpoint_manager.save(model, optimizer, epoch, metrics, scheduler=scheduler)
        if scheduler is not None and isinstance(scheduler, torch.optim.lr_scheduler.ReduceLROnPlateau):
            scheduler.step(val_result.loss)
        if early_stopper is not None and early_stopper.step(score):
            break

    model.load_state_dict(best_model_state)
    return FitResult(best_metric=best_score, best_epoch=best_epoch, train_history=train_history, val_history=val_history)


__all__ = [
    "CheckpointManager",
    "DistributedContext",
    "EarlyStopping",
    "EpochResult",
    "ExponentialMovingAverage",
    "FitResult",
    "build_scheduler",
    "evaluate",
    "fit",
    "maybe_wrap_distributed",
    "setup_distributed",
    "train_one_epoch",
]
