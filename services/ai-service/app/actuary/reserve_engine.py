"""Reserve Engine — Loss distribution and capital reserve calculations.

Implements actuarial reserve requirements for AI trading fund operations.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class ReserveType(str, Enum):
    OPERATIONAL = "operational"
    MARKET = "market"
    CREDIT = "credit"
    LIQUIDITY = "liquidity"
    MODEL = "model"
    TECHNOLOGY = "technology"


@dataclass
class ReserveRequirement:
    reserve_type: ReserveType
    amount: float
    confidence_level: float
    holding_period_days: int
    stress_multiplier: float = 1.0


@dataclass
class LossDistribution:
    """Aggregate loss distribution for reserve calculations."""

    expected_loss: float = 0.0
    unexpected_loss_95: float = 0.0
    unexpected_loss_99: float = 0.0
    catastrophic_loss: float = 0.0
    frequency: float = 0.0  # Expected number of loss events per period
    severity_mean: float = 0.0
    severity_std: float = 0.0

    @classmethod
    def from_historical(cls, losses: list[float]) -> "LossDistribution":
        """Build loss distribution from historical loss data."""
        if not losses:
            return cls()

        n = len(losses)
        mean = sum(losses) / n
        variance = sum((x - mean) ** 2 for x in losses) / n
        std = math.sqrt(variance) if variance > 0 else 0.0

        sorted_losses = sorted(losses)
        idx_95 = min(int(0.95 * n), n - 1)
        idx_99 = min(int(0.99 * n), n - 1)

        return cls(
            expected_loss=mean,
            unexpected_loss_95=sorted_losses[idx_95] - mean,
            unexpected_loss_99=sorted_losses[idx_99] - mean,
            catastrophic_loss=sorted_losses[-1],
            frequency=n / 252.0,  # Annualized from daily
            severity_mean=mean,
            severity_std=std,
        )


class ReserveEngine:
    """Capital reserve calculation engine for AI HFT fund.

    Implements Basel III-inspired capital requirements adapted for
    algorithmic trading operations.
    """

    def __init__(
        self,
        total_capital: float = 10_000_000.0,
        min_reserve_ratio: float = 0.15,
    ) -> None:
        self.total_capital = total_capital
        self.min_reserve_ratio = min_reserve_ratio
        self.reserves: dict[ReserveType, float] = {rt: 0.0 for rt in ReserveType}
        self.loss_history: list[float] = []

    def calculate_market_reserve(
        self, portfolio_var_99: float, stress_factor: float = 3.0
    ) -> float:
        """Market risk reserve based on stressed VaR."""
        base_reserve = portfolio_var_99 * math.sqrt(10)  # 10-day holding period
        stressed = base_reserve * stress_factor
        self.reserves[ReserveType.MARKET] = stressed
        return stressed

    def calculate_operational_reserve(
        self, annual_revenue: float, loss_events: list[float]
    ) -> float:
        """Operational risk reserve using Advanced Measurement Approach."""
        # Basic indicator: 15% of gross income
        basic = annual_revenue * 0.15

        # Loss distribution approach if data available
        if loss_events:
            dist = LossDistribution.from_historical(loss_events)
            lda_reserve = dist.expected_loss + 2.33 * dist.severity_std * math.sqrt(dist.frequency)
            reserve = max(basic, lda_reserve)
        else:
            reserve = basic

        self.reserves[ReserveType.OPERATIONAL] = reserve
        return reserve

    def calculate_model_risk_reserve(
        self, strategy_count: int, avg_model_uncertainty: float = 0.10
    ) -> float:
        """Model risk reserve for AI/ML strategy uncertainty."""
        # Each model carries uncertainty; correlated failures multiply risk
        correlation_factor = 1 + math.log(max(1, strategy_count)) * 0.2
        per_model_reserve = self.total_capital * avg_model_uncertainty / strategy_count
        total_model_reserve = per_model_reserve * strategy_count * correlation_factor
        self.reserves[ReserveType.MODEL] = total_model_reserve
        return total_model_reserve

    def calculate_liquidity_reserve(
        self, daily_volume: float, position_size: float, market_depth: float
    ) -> float:
        """Liquidity risk reserve for potential market impact."""
        # Days to liquidate at 10% of ADV
        days_to_liquidate = position_size / (daily_volume * 0.10)
        # Market impact estimate (square-root model)
        impact_cost = 0.1 * math.sqrt(position_size / daily_volume) * position_size
        liquidity_reserve = impact_cost * days_to_liquidate
        self.reserves[ReserveType.LIQUIDITY] = liquidity_reserve
        return liquidity_reserve

    def calculate_technology_reserve(self, annual_tech_spend: float) -> float:
        """Technology failure reserve — system outages, connectivity loss."""
        # 30% of annual tech spend as reserve for failure scenarios
        tech_reserve = annual_tech_spend * 0.30
        self.reserves[ReserveType.TECHNOLOGY] = tech_reserve
        return tech_reserve

    def total_required_reserves(self) -> dict[str, Any]:
        """Calculate total reserve requirements."""
        total = sum(self.reserves.values())
        min_required = self.total_capital * self.min_reserve_ratio

        return {
            "reserves_by_type": {rt.value: amt for rt, amt in self.reserves.items()},
            "total_reserves": total,
            "minimum_required": min_required,
            "surplus_deficit": total - min_required,
            "reserve_ratio": total / self.total_capital if self.total_capital > 0 else 0,
            "capital_adequacy": total >= min_required,
            "deployable_capital": self.total_capital - total,
        }
