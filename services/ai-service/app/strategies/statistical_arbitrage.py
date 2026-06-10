"""Statistical Arbitrage Strategy.

Exploits mean-reversion in statistically related instruments using
cointegration, Ornstein-Uhlenbeck processes, and factor models.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class SignalStrength(str, Enum):
    STRONG_BUY = "strong_buy"
    BUY = "buy"
    NEUTRAL = "neutral"
    SELL = "sell"
    STRONG_SELL = "strong_sell"


@dataclass
class StatArbSignal:
    pair: tuple[str, str]
    z_score: float
    half_life: float
    signal: SignalStrength
    confidence: float
    hedge_ratio: float
    spread_value: float


class StatisticalArbitrageStrategy:
    """Statistical arbitrage using cointegration and z-score signals."""

    def __init__(
        self,
        entry_z: float = 2.0,
        exit_z: float = 0.5,
        stop_z: float = 4.0,
        lookback: int = 60,
        min_half_life: float = 5.0,
        max_half_life: float = 60.0,
    ) -> None:
        self.entry_z = entry_z
        self.exit_z = exit_z
        self.stop_z = stop_z
        self.lookback = lookback
        self.min_half_life = min_half_life
        self.max_half_life = max_half_life
        self.positions: dict[str, dict[str, Any]] = {}

    def calculate_z_score(self, spread: list[float]) -> float:
        """Calculate z-score of current spread value."""
        if len(spread) < 2:
            return 0.0
        mean = sum(spread) / len(spread)
        std = math.sqrt(sum((x - mean) ** 2 for x in spread) / len(spread))
        if std == 0:
            return 0.0
        return (spread[-1] - mean) / std

    def estimate_half_life(self, spread: list[float]) -> float:
        """Estimate mean-reversion half-life using OLS on lagged spread."""
        if len(spread) < 10:
            return float("inf")

        # Simplified OU process parameter estimation
        n = len(spread)
        y = spread[1:]
        x = spread[:-1]

        x_mean = sum(x) / len(x)
        y_mean = sum(y) / len(y)

        numerator = sum((xi - x_mean) * (yi - y_mean) for xi, yi in zip(x, y))
        denominator = sum((xi - x_mean) ** 2 for xi in x)

        if denominator == 0:
            return float("inf")

        beta = numerator / denominator

        if beta >= 1 or beta <= 0:
            return float("inf")

        half_life = -math.log(2) / math.log(beta)
        return half_life

    def calculate_hedge_ratio(self, prices_a: list[float], prices_b: list[float]) -> float:
        """Calculate optimal hedge ratio via OLS regression."""
        if len(prices_a) != len(prices_b) or len(prices_a) < 10:
            return 1.0

        mean_a = sum(prices_a) / len(prices_a)
        mean_b = sum(prices_b) / len(prices_b)

        numerator = sum((a - mean_a) * (b - mean_b) for a, b in zip(prices_a, prices_b))
        denominator = sum((b - mean_b) ** 2 for b in prices_b)

        if denominator == 0:
            return 1.0

        return numerator / denominator

    def generate_signal(
        self, pair: tuple[str, str], prices_a: list[float], prices_b: list[float]
    ) -> StatArbSignal:
        """Generate trading signal for a pair."""
        hedge_ratio = self.calculate_hedge_ratio(prices_a, prices_b)
        spread = [a - hedge_ratio * b for a, b in zip(prices_a, prices_b)]

        z_score = self.calculate_z_score(spread)
        half_life = self.estimate_half_life(spread)

        # Determine signal
        if abs(z_score) > self.stop_z:
            signal = SignalStrength.NEUTRAL  # Stop-loss zone
            confidence = 0.0
        elif z_score > self.entry_z:
            signal = SignalStrength.STRONG_SELL if z_score > self.entry_z * 1.5 else SignalStrength.SELL
            confidence = min(1.0, abs(z_score) / self.stop_z)
        elif z_score < -self.entry_z:
            signal = SignalStrength.STRONG_BUY if z_score < -self.entry_z * 1.5 else SignalStrength.BUY
            confidence = min(1.0, abs(z_score) / self.stop_z)
        elif abs(z_score) < self.exit_z:
            signal = SignalStrength.NEUTRAL
            confidence = 0.0
        else:
            signal = SignalStrength.NEUTRAL
            confidence = 0.0

        # Penalize if half-life out of range
        if half_life < self.min_half_life or half_life > self.max_half_life:
            confidence *= 0.3

        return StatArbSignal(
            pair=pair,
            z_score=z_score,
            half_life=half_life,
            signal=signal,
            confidence=confidence,
            hedge_ratio=hedge_ratio,
            spread_value=spread[-1] if spread else 0.0,
        )
