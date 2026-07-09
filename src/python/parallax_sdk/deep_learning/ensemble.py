from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Optional, Sequence

import torch
from torch import Tensor, nn
import torch.nn.functional as F


def _normalize_weights(weights: Tensor) -> Tensor:
    return weights / weights.sum().clamp_min(1e-8)


@dataclass(frozen=True)
class EnsembleOutput:
    prediction: Tensor
    member_predictions: Tensor
    weights: Optional[Tensor] = None
    confidences: Optional[Tensor] = None


class WeightedAverageEnsemble(nn.Module):
    """Weighted averaging for multi-model forecasts."""

    def __init__(self, models: Sequence[nn.Module], weights: Optional[Sequence[float]] = None, learnable: bool = False) -> None:
        super().__init__()
        if len(models) == 0:
            raise ValueError("At least one model is required")
        self.models = nn.ModuleList(models)
        if weights is None:
            initial = torch.ones(len(models), dtype=torch.float32) / len(models)
        else:
            initial = torch.tensor(weights, dtype=torch.float32)
            initial = _normalize_weights(initial)
        if learnable:
            self.weights = nn.Parameter(initial)
        else:
            self.register_buffer("weights", initial, persistent=True)

    def forward(self, x: Tensor) -> EnsembleOutput:
        member_predictions = torch.stack([_unwrap_prediction(model(x)) for model in self.models], dim=1)
        weights = _normalize_weights(self.weights)
        prediction = torch.einsum("m,bm...->b...", weights, member_predictions)
        return EnsembleOutput(prediction=prediction, member_predictions=member_predictions, weights=weights)


class ConfidenceBasedSelector(nn.Module):
    """Selects or mixes forecasts based on per-model confidence estimates."""

    def __init__(
        self,
        models: Sequence[nn.Module],
        confidence_heads: Sequence[nn.Module],
        temperature: float = 1.0,
        hard_selection: bool = False,
    ) -> None:
        super().__init__()
        if len(models) != len(confidence_heads):
            raise ValueError("models and confidence_heads must have the same length")
        self.models = nn.ModuleList(models)
        self.confidence_heads = nn.ModuleList(confidence_heads)
        self.temperature = temperature
        self.hard_selection = hard_selection

    def forward(self, x: Tensor) -> EnsembleOutput:
        predictions = torch.stack([_unwrap_prediction(model(x)) for model in self.models], dim=1)
        confidences = torch.stack([head(x).squeeze(-1) for head in self.confidence_heads], dim=1)
        weights = torch.softmax(confidences / max(self.temperature, 1e-6), dim=1)
        if self.hard_selection:
            indices = weights.argmax(dim=1)
            gathered = predictions[torch.arange(predictions.size(0), device=predictions.device), indices]
            return EnsembleOutput(prediction=gathered, member_predictions=predictions, weights=weights, confidences=confidences)
        blended = torch.sum(predictions * weights.view(weights.size(0), weights.size(1), *([1] * (predictions.dim() - 2))), dim=1)
        return EnsembleOutput(prediction=blended, member_predictions=predictions, weights=weights, confidences=confidences)


class StackingEnsemble(nn.Module):
    """Stacking ensemble with trainable meta-learner."""

    def __init__(self, base_models: Sequence[nn.Module], meta_learner: nn.Module) -> None:
        super().__init__()
        if len(base_models) == 0:
            raise ValueError("At least one base model is required")
        self.base_models = nn.ModuleList(base_models)
        self.meta_learner = meta_learner

    def base_predictions(self, x: Tensor) -> Tensor:
        return torch.cat([_unwrap_prediction(model(x)).flatten(start_dim=1) for model in self.base_models], dim=-1)

    def forward(self, x: Tensor) -> EnsembleOutput:
        member_predictions = torch.stack([_unwrap_prediction(model(x)) for model in self.base_models], dim=1)
        prediction = _unwrap_prediction(self.meta_learner(self.base_predictions(x)))
        return EnsembleOutput(prediction=prediction, member_predictions=member_predictions)


class BaggingEnsemble(nn.Module):
    """Bootstrap aggregation wrapper for PyTorch forecasters."""

    def __init__(self, model_factories: Sequence[Callable[[], nn.Module]]) -> None:
        super().__init__()
        if len(model_factories) == 0:
            raise ValueError("At least one model factory is required")
        self.models = nn.ModuleList([factory() for factory in model_factories])

    @staticmethod
    def bootstrap_indices(num_samples: int, device: Optional[torch.device] = None) -> Tensor:
        return torch.randint(0, num_samples, (num_samples,), device=device)

    def forward(self, x: Tensor) -> EnsembleOutput:
        member_predictions = torch.stack([_unwrap_prediction(model(x)) for model in self.models], dim=1)
        prediction = member_predictions.mean(dim=1)
        return EnsembleOutput(prediction=prediction, member_predictions=member_predictions)


class ResidualBoostingEnsemble(nn.Module):
    """Residual boosting for sequential error correction."""

    def __init__(self, models: Sequence[nn.Module], learning_rate: float = 0.5) -> None:
        super().__init__()
        if len(models) == 0:
            raise ValueError("At least one model is required")
        self.models = nn.ModuleList(models)
        self.learning_rate = learning_rate

    def forward(self, x: Tensor) -> EnsembleOutput:
        member_predictions = []
        running = None
        for index, model in enumerate(self.models):
            prediction = _unwrap_prediction(model(x))
            member_predictions.append(prediction)
            if index == 0:
                running = prediction
            else:
                running = running + self.learning_rate * prediction
        stacked = torch.stack(member_predictions, dim=1)
        return EnsembleOutput(prediction=running, member_predictions=stacked)

    def residual_loss(self, base_prediction: Tensor, target: Tensor, stage_prediction: Tensor) -> Tensor:
        residual = target - base_prediction
        return F.mse_loss(stage_prediction, residual)


class BoostingTrainer:
    """Utility for training residual boosting stages against evolving residuals."""

    def __init__(self, ensemble: ResidualBoostingEnsemble) -> None:
        self.ensemble = ensemble

    @torch.no_grad()
    def current_prediction(self, x: Tensor, upto_stage: int) -> Tensor:
        running = None
        for index in range(upto_stage):
            stage_prediction = _unwrap_prediction(self.ensemble.models[index](x))
            if running is None:
                running = stage_prediction
            else:
                running = running + self.ensemble.learning_rate * stage_prediction
        if running is None:
            raise ValueError("upto_stage must be at least 1")
        return running

    def stage_loss(self, stage_index: int, x: Tensor, target: Tensor) -> Tensor:
        if stage_index == 0:
            return F.mse_loss(_unwrap_prediction(self.ensemble.models[stage_index](x)), target)
        base_prediction = self.current_prediction(x, stage_index)
        stage_prediction = _unwrap_prediction(self.ensemble.models[stage_index](x))
        return self.ensemble.residual_loss(base_prediction, target, stage_prediction)


def _unwrap_prediction(output: object) -> Tensor:
    if isinstance(output, Tensor):
        return output
    if hasattr(output, "prediction"):
        return output.prediction
    raise TypeError("Model outputs must be Tensor-like or expose a 'prediction' attribute")


__all__ = [
    "BaggingEnsemble",
    "BoostingTrainer",
    "ConfidenceBasedSelector",
    "EnsembleOutput",
    "ResidualBoostingEnsemble",
    "StackingEnsemble",
    "WeightedAverageEnsemble",
]
