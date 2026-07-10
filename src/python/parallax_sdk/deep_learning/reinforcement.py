from __future__ import annotations

import random
from collections import deque
from dataclasses import dataclass
from typing import Iterable, Optional

import torch
from torch import Tensor, nn
import torch.nn.functional as F
from torch.distributions import Categorical


@dataclass(frozen=True)
class TradingRewardComponents:
    """Decomposed reward terms for trading and market-making objectives."""

    pnl: float
    inventory_penalty: float = 0.0
    transaction_cost: float = 0.0
    drawdown_penalty: float = 0.0
    liquidity_reward: float = 0.0
    adverse_selection_penalty: float = 0.0
    risk_budget_penalty: float = 0.0

    @property
    def total(self) -> float:
        return (
            self.pnl
            + self.liquidity_reward
            - self.inventory_penalty
            - self.transaction_cost
            - self.drawdown_penalty
            - self.adverse_selection_penalty
            - self.risk_budget_penalty
        )


@dataclass(frozen=True)
class Transition:
    state: Tensor
    action: Tensor
    reward: Tensor
    next_state: Tensor
    done: Tensor


@dataclass(frozen=True)
class TrajectoryStep:
    state: Tensor
    action: Tensor
    log_prob: Tensor
    reward: Tensor
    value: Optional[Tensor] = None
    done: Optional[Tensor] = None


class ReplayBuffer:
    """Vectorized replay buffer for off-policy trading agents."""

    def __init__(self, capacity: int) -> None:
        self._buffer: deque[Transition] = deque(maxlen=capacity)

    def __len__(self) -> int:
        return len(self._buffer)

    def push(self, transition: Transition) -> None:
        self._buffer.append(transition)

    def sample(self, batch_size: int) -> Transition:
        batch = random.sample(self._buffer, batch_size)
        return Transition(
            state=torch.stack([item.state for item in batch]),
            action=torch.stack([item.action for item in batch]),
            reward=torch.stack([item.reward for item in batch]),
            next_state=torch.stack([item.next_state for item in batch]),
            done=torch.stack([item.done for item in batch]),
        )


class DQNNetwork(nn.Module):
    """Deep Q-network with optional dueling heads."""

    def __init__(
        self,
        state_dim: int,
        action_dim: int,
        hidden_dims: Iterable[int] = (256, 256),
        dropout: float = 0.1,
        dueling: bool = True,
    ) -> None:
        super().__init__()
        layers: list[nn.Module] = []
        in_features = state_dim
        for hidden_dim in hidden_dims:
            layers.extend([nn.Linear(in_features, hidden_dim), nn.ReLU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        self.backbone = nn.Sequential(*layers)
        self.dueling = dueling
        self.action_dim = action_dim
        if dueling:
            self.value_head = nn.Linear(in_features, 1)
            self.advantage_head = nn.Linear(in_features, action_dim)
        else:
            self.q_head = nn.Linear(in_features, action_dim)

    def forward(self, state: Tensor) -> Tensor:
        features = self.backbone(state)
        if self.dueling:
            value = self.value_head(features)
            advantage = self.advantage_head(features)
            return value + advantage - advantage.mean(dim=-1, keepdim=True)
        return self.q_head(features)


class DQNAgent:
    """Production-ready DQN agent for discrete trading actions."""

    def __init__(
        self,
        policy_network: DQNNetwork,
        target_network: DQNNetwork,
        optimizer: torch.optim.Optimizer,
        gamma: float = 0.99,
        tau: float = 0.005,
        epsilon_start: float = 1.0,
        epsilon_end: float = 0.05,
        epsilon_decay: int = 10_000,
        gradient_clip_norm: float = 5.0,
    ) -> None:
        self.policy_network = policy_network
        self.target_network = target_network
        self.optimizer = optimizer
        self.gamma = gamma
        self.tau = tau
        self.epsilon_start = epsilon_start
        self.epsilon_end = epsilon_end
        self.epsilon_decay = epsilon_decay
        self.gradient_clip_norm = gradient_clip_norm
        self.steps = 0
        self.target_network.load_state_dict(self.policy_network.state_dict())
        self.target_network.eval()

    def epsilon(self) -> float:
        ratio = min(self.steps / max(self.epsilon_decay, 1), 1.0)
        return self.epsilon_start + ratio * (self.epsilon_end - self.epsilon_start)

    @torch.no_grad()
    def act(self, state: Tensor, deterministic: bool = False) -> Tensor:
        if state.dim() == 1:
            state = state.unsqueeze(0)
        if not deterministic and random.random() < self.epsilon():
            action = torch.randint(0, self.policy_network.action_dim, (state.size(0),), device=state.device)
        else:
            action = self.policy_network(state).argmax(dim=-1)
        self.steps += 1
        return action

    def soft_update(self) -> None:
        for target, policy in zip(self.target_network.parameters(), self.policy_network.parameters()):
            target.data.lerp_(policy.data, self.tau)

    def training_step(self, batch: Transition) -> Tensor:
        q_values = self.policy_network(batch.state).gather(1, batch.action.long().unsqueeze(-1)).squeeze(-1)
        with torch.no_grad():
            next_policy_actions = self.policy_network(batch.next_state).argmax(dim=-1, keepdim=True)
            next_q = self.target_network(batch.next_state).gather(1, next_policy_actions).squeeze(-1)
            td_target = batch.reward.squeeze(-1) + self.gamma * (1.0 - batch.done.squeeze(-1)) * next_q
        loss = F.smooth_l1_loss(q_values, td_target)
        self.optimizer.zero_grad(set_to_none=True)
        loss.backward()
        nn.utils.clip_grad_norm_(self.policy_network.parameters(), self.gradient_clip_norm)
        self.optimizer.step()
        self.soft_update()
        return loss.detach()


class PolicyGradientNetwork(nn.Module):
    """Policy network for REINFORCE-style methods."""

    def __init__(self, state_dim: int, action_dim: int, hidden_dims: Iterable[int] = (256, 256), dropout: float = 0.1) -> None:
        super().__init__()
        layers: list[nn.Module] = []
        in_features = state_dim
        for hidden_dim in hidden_dims:
            layers.extend([nn.Linear(in_features, hidden_dim), nn.GELU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        layers.append(nn.Linear(in_features, action_dim))
        self.network = nn.Sequential(*layers)

    def forward(self, state: Tensor) -> Tensor:
        return self.network(state)

    def distribution(self, state: Tensor) -> Categorical:
        return Categorical(logits=self(state))


def compute_returns(rewards: Tensor, gamma: float) -> Tensor:
    returns = torch.zeros_like(rewards)
    running = torch.zeros(1, device=rewards.device, dtype=rewards.dtype)
    for index in reversed(range(rewards.size(0))):
        running = rewards[index] + gamma * running
        returns[index] = running
    return returns


def policy_gradient_loss(log_probs: Tensor, rewards: Tensor, gamma: float = 0.99, normalize: bool = True) -> Tensor:
    returns = compute_returns(rewards, gamma)
    if normalize:
        returns = (returns - returns.mean()) / (returns.std().clamp_min(1e-6))
    return -(log_probs * returns.detach()).mean()


class ActorCriticNetwork(nn.Module):
    """Shared-backbone actor-critic network used by A2C and PPO."""

    def __init__(self, state_dim: int, action_dim: int, hidden_dims: Iterable[int] = (256, 256), dropout: float = 0.1) -> None:
        super().__init__()
        layers: list[nn.Module] = []
        in_features = state_dim
        for hidden_dim in hidden_dims:
            layers.extend([nn.Linear(in_features, hidden_dim), nn.GELU(), nn.Dropout(dropout)])
            in_features = hidden_dim
        self.backbone = nn.Sequential(*layers)
        self.policy_head = nn.Linear(in_features, action_dim)
        self.value_head = nn.Linear(in_features, 1)

    def forward(self, state: Tensor) -> tuple[Tensor, Tensor]:
        features = self.backbone(state)
        return self.policy_head(features), self.value_head(features).squeeze(-1)

    def distribution(self, state: Tensor) -> Categorical:
        logits, _ = self(state)
        return Categorical(logits=logits)


def generalized_advantage_estimation(
    rewards: Tensor,
    values: Tensor,
    dones: Tensor,
    gamma: float,
    gae_lambda: float,
) -> tuple[Tensor, Tensor]:
    advantages = torch.zeros_like(rewards)
    last_advantage = torch.zeros(1, device=rewards.device, dtype=rewards.dtype)
    next_value = torch.zeros(1, device=rewards.device, dtype=rewards.dtype)
    for t in reversed(range(rewards.size(0))):
        mask = 1.0 - dones[t]
        delta = rewards[t] + gamma * next_value * mask - values[t]
        last_advantage = delta + gamma * gae_lambda * mask * last_advantage
        advantages[t] = last_advantage
        next_value = values[t]
    returns = advantages + values
    return advantages, returns


class A2CAgent:
    def __init__(
        self,
        network: ActorCriticNetwork,
        optimizer: torch.optim.Optimizer,
        value_coef: float = 0.5,
        entropy_coef: float = 0.01,
        gamma: float = 0.99,
        gae_lambda: float = 0.95,
        gradient_clip_norm: float = 5.0,
    ) -> None:
        self.network = network
        self.optimizer = optimizer
        self.value_coef = value_coef
        self.entropy_coef = entropy_coef
        self.gamma = gamma
        self.gae_lambda = gae_lambda
        self.gradient_clip_norm = gradient_clip_norm

    def training_step(self, states: Tensor, actions: Tensor, rewards: Tensor, dones: Tensor) -> dict[str, Tensor]:
        logits, values = self.network(states)
        dist = Categorical(logits=logits)
        log_probs = dist.log_prob(actions)
        advantages, returns = generalized_advantage_estimation(rewards, values.detach(), dones, self.gamma, self.gae_lambda)
        advantages = (advantages - advantages.mean()) / advantages.std().clamp_min(1e-6)
        policy_loss = -(log_probs * advantages.detach()).mean()
        value_loss = F.mse_loss(values, returns.detach())
        entropy_bonus = dist.entropy().mean()
        loss = policy_loss + self.value_coef * value_loss - self.entropy_coef * entropy_bonus
        self.optimizer.zero_grad(set_to_none=True)
        loss.backward()
        nn.utils.clip_grad_norm_(self.network.parameters(), self.gradient_clip_norm)
        self.optimizer.step()
        return {
            "loss": loss.detach(),
            "policy_loss": policy_loss.detach(),
            "value_loss": value_loss.detach(),
            "entropy": entropy_bonus.detach(),
        }


class PPOClipAgent:
    """Clipped PPO implementation for trading policy optimization."""

    def __init__(
        self,
        network: ActorCriticNetwork,
        optimizer: torch.optim.Optimizer,
        clip_epsilon: float = 0.2,
        value_coef: float = 0.5,
        entropy_coef: float = 0.01,
        gamma: float = 0.99,
        gae_lambda: float = 0.95,
        gradient_clip_norm: float = 5.0,
    ) -> None:
        self.network = network
        self.optimizer = optimizer
        self.clip_epsilon = clip_epsilon
        self.value_coef = value_coef
        self.entropy_coef = entropy_coef
        self.gamma = gamma
        self.gae_lambda = gae_lambda
        self.gradient_clip_norm = gradient_clip_norm

    def training_step(
        self,
        states: Tensor,
        actions: Tensor,
        rewards: Tensor,
        dones: Tensor,
        old_log_probs: Tensor,
        epochs: int = 4,
        minibatch_size: int = 256,
    ) -> dict[str, Tensor]:
        with torch.no_grad():
            _, values = self.network(states)
            advantages, returns = generalized_advantage_estimation(rewards, values, dones, self.gamma, self.gae_lambda)
            advantages = (advantages - advantages.mean()) / advantages.std().clamp_min(1e-6)

        stats = {"loss": [], "policy_loss": [], "value_loss": [], "entropy": []}
        for _ in range(epochs):
            permutation = torch.randperm(states.size(0), device=states.device)
            for start in range(0, states.size(0), minibatch_size):
                indices = permutation[start : start + minibatch_size]
                logits, values = self.network(states[indices])
                dist = Categorical(logits=logits)
                log_probs = dist.log_prob(actions[indices])
                ratio = torch.exp(log_probs - old_log_probs[indices])
                unclipped = ratio * advantages[indices]
                clipped = torch.clamp(ratio, 1.0 - self.clip_epsilon, 1.0 + self.clip_epsilon) * advantages[indices]
                policy_loss = -torch.minimum(unclipped, clipped).mean()
                value_loss = F.mse_loss(values, returns[indices])
                entropy_bonus = dist.entropy().mean()
                loss = policy_loss + self.value_coef * value_loss - self.entropy_coef * entropy_bonus
                self.optimizer.zero_grad(set_to_none=True)
                loss.backward()
                nn.utils.clip_grad_norm_(self.network.parameters(), self.gradient_clip_norm)
                self.optimizer.step()
                stats["loss"].append(loss.detach())
                stats["policy_loss"].append(policy_loss.detach())
                stats["value_loss"].append(value_loss.detach())
                stats["entropy"].append(entropy_bonus.detach())
        return {key: torch.stack(value).mean() for key, value in stats.items()}


class MultiAgentMarketMaker(nn.Module):
    """Shared policy/value backbone with agent-specific heads for market making."""

    def __init__(self, observation_dim: int, action_dim: int, agent_count: int, hidden_dim: int = 256, dropout: float = 0.1) -> None:
        super().__init__()
        self.shared = nn.Sequential(
            nn.Linear(observation_dim, hidden_dim),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(hidden_dim, hidden_dim),
            nn.GELU(),
        )
        self.policy_heads = nn.ModuleList([nn.Linear(hidden_dim, action_dim) for _ in range(agent_count)])
        self.value_heads = nn.ModuleList([nn.Linear(hidden_dim, 1) for _ in range(agent_count)])

    def forward(self, observations: Tensor) -> tuple[Tensor, Tensor]:
        shared_features = self.shared(observations)
        logits = torch.stack([head(shared_features) for head in self.policy_heads], dim=1)
        values = torch.stack([head(shared_features).squeeze(-1) for head in self.value_heads], dim=1)
        return logits, values


def shape_trading_reward(
    pnl: Tensor,
    inventory: Tensor,
    transaction_cost: Tensor,
    drawdown: Tensor,
    fill_rate: Optional[Tensor] = None,
    adverse_selection: Optional[Tensor] = None,
    risk_budget: Optional[Tensor] = None,
    inventory_penalty_weight: float = 0.1,
    transaction_cost_weight: float = 1.0,
    drawdown_penalty_weight: float = 0.2,
    fill_rate_weight: float = 0.05,
    adverse_selection_weight: float = 0.1,
    risk_budget_weight: float = 0.1,
) -> Tensor:
    """Reward shaping aligned with pnl, inventory, liquidity, and drawdown targets."""

    reward = pnl
    reward = reward - inventory_penalty_weight * inventory.abs()
    reward = reward - transaction_cost_weight * transaction_cost
    reward = reward - drawdown_penalty_weight * drawdown.relu()
    if fill_rate is not None:
        reward = reward + fill_rate_weight * fill_rate
    if adverse_selection is not None:
        reward = reward - adverse_selection_weight * adverse_selection.relu()
    if risk_budget is not None:
        reward = reward - risk_budget_weight * risk_budget.relu()
    return reward


__all__ = [
    "A2CAgent",
    "ActorCriticNetwork",
    "DQNAgent",
    "DQNNetwork",
    "MultiAgentMarketMaker",
    "PPOClipAgent",
    "PolicyGradientNetwork",
    "ReplayBuffer",
    "TradingRewardComponents",
    "TrajectoryStep",
    "Transition",
    "compute_returns",
    "generalized_advantage_estimation",
    "policy_gradient_loss",
    "shape_trading_reward",
]
