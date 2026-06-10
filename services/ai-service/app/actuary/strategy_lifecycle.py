"""Strategy Lifecycle / Mortality Models.

Actuarial survival analysis applied to trading strategy lifecycles.
Models when strategies decay, become unprofitable, or need replacement.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class StrategyState(str, Enum):
    INCUBATION = "incubation"
    ACTIVE = "active"
    DEGRADING = "degrading"
    TERMINAL = "terminal"
    RETIRED = "retired"


@dataclass
class StrategyLifecycleMetrics:
    strategy_id: str
    state: StrategyState
    age_days: int
    expected_remaining_life: float
    hazard_rate: float
    survival_probability: float
    alpha_decay_rate: float
    capacity_utilization: float


class StrategyMortality:
    """Weibull mortality model for strategy decay/survival."""

    def __init__(self, shape: float = 1.5, scale: float = 180.0) -> None:
        """Initialize with Weibull parameters.

        Args:
            shape: Weibull shape parameter (>1 means increasing hazard rate)
            scale: Weibull scale parameter (characteristic life in days)
        """
        self.shape = shape
        self.scale = scale

    def survival_function(self, t: float) -> float:
        """Probability strategy survives beyond time t."""
        return math.exp(-((t / self.scale) ** self.shape))

    def hazard_rate(self, t: float) -> float:
        """Instantaneous failure rate at time t."""
        if t <= 0:
            return 0.0
        return (self.shape / self.scale) * ((t / self.scale) ** (self.shape - 1))

    def expected_remaining_life(self, t: float) -> float:
        """Expected remaining life given survived to time t."""
        # Approximate using discrete integration
        dt = 1.0
        remaining = 0.0
        for i in range(1, 1000):
            s = t + i * dt
            prob = self.survival_function(s) / self.survival_function(t)
            if prob < 0.001:
                break
            remaining += prob * dt
        return remaining

    def alpha_decay_rate(self, initial_alpha: float, t: float, half_life: float = 90.0) -> float:
        """Model alpha decay as exponential with strategy age."""
        return initial_alpha * math.exp(-math.log(2) * t / half_life)


class StrategyLifecycleModel:
    """Complete strategy lifecycle management with actuarial models."""

    def __init__(self) -> None:
        self.mortality = StrategyMortality()
        self.strategies: dict[str, dict[str, Any]] = {}

    def register_strategy(
        self,
        strategy_id: str,
        initial_alpha: float = 0.05,
        capacity: float = 1_000_000.0,
    ) -> None:
        """Register a new strategy for lifecycle tracking."""
        self.strategies[strategy_id] = {
            "age_days": 0,
            "initial_alpha": initial_alpha,
            "capacity": capacity,
            "utilization": 0.0,
            "state": StrategyState.INCUBATION,
            "cumulative_pnl": 0.0,
            "peak_pnl": 0.0,
        }

    def assess_strategy(self, strategy_id: str) -> StrategyLifecycleMetrics | None:
        """Full lifecycle assessment for a strategy."""
        strat = self.strategies.get(strategy_id)
        if not strat:
            return None

        age = strat["age_days"]
        survival_prob = self.mortality.survival_function(age)
        hazard = self.mortality.hazard_rate(age)
        remaining_life = self.mortality.expected_remaining_life(age)
        alpha_decay = self.mortality.alpha_decay_rate(strat["initial_alpha"], age)

        # Determine state
        if age < 30:
            state = StrategyState.INCUBATION
        elif survival_prob > 0.7:
            state = StrategyState.ACTIVE
        elif survival_prob > 0.3:
            state = StrategyState.DEGRADING
        else:
            state = StrategyState.TERMINAL

        strat["state"] = state

        return StrategyLifecycleMetrics(
            strategy_id=strategy_id,
            state=state,
            age_days=age,
            expected_remaining_life=remaining_life,
            hazard_rate=hazard,
            survival_probability=survival_prob,
            alpha_decay_rate=alpha_decay,
            capacity_utilization=strat["utilization"],
        )

    def advance_day(self, strategy_id: str, daily_pnl: float) -> None:
        """Advance strategy by one day with P&L update."""
        strat = self.strategies.get(strategy_id)
        if not strat:
            return

        strat["age_days"] += 1
        strat["cumulative_pnl"] += daily_pnl
        strat["peak_pnl"] = max(strat["peak_pnl"], strat["cumulative_pnl"])

    def get_replacement_schedule(self) -> list[dict[str, Any]]:
        """Generate replacement schedule for degrading strategies."""
        schedule = []
        for sid, strat in self.strategies.items():
            metrics = self.assess_strategy(sid)
            if metrics and metrics.state in (StrategyState.DEGRADING, StrategyState.TERMINAL):
                schedule.append({
                    "strategy_id": sid,
                    "state": metrics.state.value,
                    "remaining_life_days": metrics.expected_remaining_life,
                    "urgency": "high" if metrics.state == StrategyState.TERMINAL else "medium",
                })
        return schedule
