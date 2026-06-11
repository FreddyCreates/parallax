"""Pairs Trading Strategy.

Identifies cointegrated pairs and trades the spread.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any

from .statistical_arbitrage import StatArbSignal, StatisticalArbitrageStrategy


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
            entry_z=entry_z,
            exit_z=exit_z,
            min_half_life=min_half_life,
            max_half_life=max_half_life,
        )
        self.active_pairs: dict[str, PairCandidate] = {}
        self.pair_diagnostics: dict[str, dict[str, Any]] = {}

    def _mean(self, values: list[float]) -> float:
        return sum(values) / len(values) if values else 0.0

    def _std(self, values: list[float]) -> float:
        if len(values) < 2:
            return 0.0
        mean = self._mean(values)
        variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
        return math.sqrt(max(variance, 0.0))

    def calculate_correlation(self, prices_a: list[float], prices_b: list[float]) -> float:
        """Calculate Pearson correlation between two price series."""
        if len(prices_a) != len(prices_b) or len(prices_a) < 5:
            return 0.0
        mean_a = self._mean(prices_a)
        mean_b = self._mean(prices_b)
        covariance = sum((a - mean_a) * (b - mean_b) for a, b in zip(prices_a, prices_b)) / len(prices_a)
        std_a = self._std(prices_a)
        std_b = self._std(prices_b)
        if std_a == 0 or std_b == 0:
            return 0.0
        return covariance / (std_a * std_b)

    def dynamic_hedge_ratio(self, prices_a: list[float], prices_b: list[float], window: int = 20) -> float:
        """Blend long-term and short-term hedge ratios for better responsiveness."""
        long_ratio = self.stat_arb.calculate_hedge_ratio(prices_a, prices_b)
        if len(prices_a) < window or len(prices_b) < window:
            return long_ratio
        short_ratio = self.stat_arb.calculate_hedge_ratio(prices_a[-window:], prices_b[-window:])
        return 0.65 * short_ratio + 0.35 * long_ratio

    def select_pairs(self, universe: dict[str, list[float]]) -> list[PairCandidate]:
        """Rank a universe of assets and retain valid pair candidates."""
        symbols = sorted(universe)
        candidates: list[PairCandidate] = []
        for index, asset_a in enumerate(symbols):
            for asset_b in symbols[index + 1 :]:
                candidate = self.evaluate_pair(asset_a, asset_b, universe[asset_a], universe[asset_b])
                if candidate.is_valid:
                    candidates.append(candidate)
        candidates.sort(key=lambda item: (item.cointegration_score, abs(item.correlation)), reverse=True)
        return candidates

    def evaluate_pair(
        self, asset_a: str, asset_b: str, prices_a: list[float], prices_b: list[float]
    ) -> PairCandidate:
        """Evaluate if a pair is suitable for trading."""
        correlation = self.calculate_correlation(prices_a, prices_b)
        hedge_ratio = self.dynamic_hedge_ratio(prices_a, prices_b)
        spread = [a - hedge_ratio * b for a, b in zip(prices_a, prices_b)]
        half_life = self.stat_arb.estimate_half_life(spread)
        cointegration = self.stat_arb.calculate_cointegration_score(prices_a, prices_b, hedge_ratio)
        spread_vol = self._std(spread[-self.stat_arb.lookback :]) if spread else 0.0

        is_valid = (
            abs(correlation) >= self.min_correlation
            and self.min_half_life <= half_life <= self.max_half_life
            and cointegration >= 0.35
            and spread_vol > 0
        )
        candidate = PairCandidate(
            asset_a=asset_a,
            asset_b=asset_b,
            correlation=correlation,
            cointegration_score=cointegration,
            half_life=half_life,
            is_valid=is_valid,
        )
        pair_key = f"{asset_a}/{asset_b}"
        self.pair_diagnostics[pair_key] = {
            "hedge_ratio": hedge_ratio,
            "spread_vol": spread_vol,
            "cointegration": cointegration,
            "half_life": half_life,
        }
        if is_valid:
            self.active_pairs[pair_key] = candidate
        else:
            self.active_pairs.pop(pair_key, None)
        return candidate

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return portfolio risk metrics for active pairs."""
        gross_pairs = len(self.active_pairs)
        average_half_life = self._mean([pair.half_life for pair in self.active_pairs.values()]) if self.active_pairs else 0.0
        average_cointegration = self._mean([pair.cointegration_score for pair in self.active_pairs.values()]) if self.active_pairs else 0.0
        max_loss = gross_pairs * max(average_half_life, 1.0) * 0.05
        expected_drawdown = max_loss * (1.0 - min(average_cointegration, 1.0) * 0.4)
        return {
            "active_pairs": gross_pairs,
            "average_half_life": average_half_life,
            "average_cointegration": average_cointegration,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current pair universe state and health."""
        healthy_pairs = [key for key, pair in self.active_pairs.items() if pair.is_valid]
        return {
            "healthy": bool(healthy_pairs),
            "active_pairs": healthy_pairs,
            "diagnostics": self.pair_diagnostics,
            "stat_arb_state": self.stat_arb.get_strategy_state(),
        }

    def generate_signal(
        self, asset_a: str, asset_b: str, prices_a: list[float], prices_b: list[float]
    ) -> StatArbSignal:
        """Generate pairs trading signal."""
        self.evaluate_pair(asset_a, asset_b, prices_a, prices_b)
        hedge_ratio = self.dynamic_hedge_ratio(prices_a, prices_b)
        pair_key = f"{asset_a}/{asset_b}"
        signal = self.stat_arb.generate_signal((asset_a, asset_b), prices_a, prices_b)
        diagnostics = self.pair_diagnostics.get(pair_key, {})
        diagnostics.update(
            {
                "generated_signal": signal.signal.value,
                "signal_confidence": signal.confidence,
                "dynamic_hedge_ratio": hedge_ratio,
            }
        )
        self.pair_diagnostics[pair_key] = diagnostics
        return signal
