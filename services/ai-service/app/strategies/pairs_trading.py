"""Pairs Trading Strategy.

Identifies cointegrated pairs and trades the spread.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .statistical_arbitrage import StatisticalArbitrageStrategy, StatArbSignal


@dataclass
class PairCandidate:
    asset_a: str
    asset_b: str
    correlation: float
    cointegration_score: float
    half_life: float
    is_valid: bool


class PairsTradingStrategy:
    """Pairs trading with dynamic pair selection and monitoring."""

    def __init__(
        self,
        min_correlation: float = 0.7,
        max_half_life: float = 60.0,
        min_half_life: float = 5.0,
        entry_z: float = 2.0,
        exit_z: float = 0.5,
    ) -> None:
        self.min_correlation = min_correlation
        self.max_half_life = max_half_life
        self.min_half_life = min_half_life
        self.stat_arb = StatisticalArbitrageStrategy(
            entry_z=entry_z, exit_z=exit_z,
            min_half_life=min_half_life, max_half_life=max_half_life,
        )
        self.active_pairs: dict[str, PairCandidate] = {}

    def calculate_correlation(self, prices_a: list[float], prices_b: list[float]) -> float:
        """Calculate Pearson correlation between two price series."""
        if len(prices_a) != len(prices_b) or len(prices_a) < 5:
            return 0.0

        n = len(prices_a)
        mean_a = sum(prices_a) / n
        mean_b = sum(prices_b) / n

        cov = sum((a - mean_a) * (b - mean_b) for a, b in zip(prices_a, prices_b)) / n
        std_a = (sum((a - mean_a) ** 2 for a in prices_a) / n) ** 0.5
        std_b = (sum((b - mean_b) ** 2 for b in prices_b) / n) ** 0.5

        if std_a == 0 or std_b == 0:
            return 0.0
        return cov / (std_a * std_b)

    def evaluate_pair(
        self, asset_a: str, asset_b: str, prices_a: list[float], prices_b: list[float]
    ) -> PairCandidate:
        """Evaluate if a pair is suitable for trading."""
        correlation = self.calculate_correlation(prices_a, prices_b)
        hedge_ratio = self.stat_arb.calculate_hedge_ratio(prices_a, prices_b)
        spread = [a - hedge_ratio * b for a, b in zip(prices_a, prices_b)]
        half_life = self.stat_arb.estimate_half_life(spread)

        is_valid = (
            abs(correlation) >= self.min_correlation
            and self.min_half_life <= half_life <= self.max_half_life
        )

        candidate = PairCandidate(
            asset_a=asset_a,
            asset_b=asset_b,
            correlation=correlation,
            cointegration_score=1.0 / half_life if half_life > 0 else 0.0,
            half_life=half_life,
            is_valid=is_valid,
        )

        if is_valid:
            self.active_pairs[f"{asset_a}/{asset_b}"] = candidate

        return candidate

    def generate_signal(
        self, asset_a: str, asset_b: str, prices_a: list[float], prices_b: list[float]
    ) -> StatArbSignal:
        """Generate pairs trading signal."""
        return self.stat_arb.generate_signal((asset_a, asset_b), prices_a, prices_b)
