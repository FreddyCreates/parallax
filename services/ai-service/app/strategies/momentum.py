"""Momentum / Trend Following Strategy.

Multi-timeframe momentum with adaptive lookbacks and regime detection.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class MomentumSignal:
    symbol: str
    direction: str  # "long", "short", "flat"
    strength: float  # 0-1
    timeframe: str
    momentum_score: float
    trend_quality: float
    breakout_level: float


class MomentumStrategy:
    """Multi-timeframe momentum with adaptive parameters."""

    def __init__(
        self,
        fast_period: int = 10,
        slow_period: int = 50,
        signal_period: int = 9,
        breakout_threshold: float = 2.0,
        atr_period: int = 14,
    ) -> None:
        self.fast_period = fast_period
        self.slow_period = slow_period
        self.signal_period = signal_period
        self.breakout_threshold = breakout_threshold
        self.atr_period = atr_period

    def exponential_moving_average(self, prices: list[float], period: int) -> list[float]:
        """Calculate EMA."""
        if len(prices) < period:
            return prices[:]

        multiplier = 2 / (period + 1)
        ema = [sum(prices[:period]) / period]

        for price in prices[period:]:
            ema.append(price * multiplier + ema[-1] * (1 - multiplier))

        return ema

    def calculate_atr(self, highs: list[float], lows: list[float], closes: list[float]) -> float:
        """Calculate Average True Range."""
        if len(highs) < 2:
            return 0.0

        true_ranges = []
        for i in range(1, len(highs)):
            tr = max(
                highs[i] - lows[i],
                abs(highs[i] - closes[i - 1]),
                abs(lows[i] - closes[i - 1]),
            )
            true_ranges.append(tr)

        period = min(self.atr_period, len(true_ranges))
        return sum(true_ranges[-period:]) / period

    def calculate_momentum_score(self, prices: list[float]) -> float:
        """Multi-timeframe momentum composite score."""
        if len(prices) < self.slow_period:
            return 0.0

        scores = []

        # Short-term momentum (returns over fast period)
        short_ret = (prices[-1] / prices[-self.fast_period] - 1) if prices[-self.fast_period] > 0 else 0
        scores.append(short_ret)

        # Medium-term momentum
        med_period = (self.fast_period + self.slow_period) // 2
        if len(prices) >= med_period:
            med_ret = (prices[-1] / prices[-med_period] - 1) if prices[-med_period] > 0 else 0
            scores.append(med_ret)

        # Long-term momentum
        long_ret = (prices[-1] / prices[-self.slow_period] - 1) if prices[-self.slow_period] > 0 else 0
        scores.append(long_ret)

        # Weighted composite
        weights = [0.5, 0.3, 0.2] if len(scores) == 3 else [0.6, 0.4]
        composite = sum(s * w for s, w in zip(scores, weights[: len(scores)]))

        return composite

    def trend_quality(self, prices: list[float]) -> float:
        """Measure trend quality / consistency (R-squared of linear fit)."""
        n = len(prices)
        if n < 5:
            return 0.0

        # Linear regression R²
        x_mean = (n - 1) / 2
        y_mean = sum(prices) / n

        ss_xy = sum((i - x_mean) * (prices[i] - y_mean) for i in range(n))
        ss_xx = sum((i - x_mean) ** 2 for i in range(n))
        ss_yy = sum((prices[i] - y_mean) ** 2 for i in range(n))

        if ss_xx == 0 or ss_yy == 0:
            return 0.0

        r_squared = (ss_xy**2) / (ss_xx * ss_yy)
        return min(1.0, r_squared)

    def generate_signal(
        self,
        symbol: str,
        prices: list[float],
        highs: list[float] | None = None,
        lows: list[float] | None = None,
    ) -> MomentumSignal:
        """Generate momentum trading signal."""
        if len(prices) < self.slow_period:
            return MomentumSignal(
                symbol=symbol, direction="flat", strength=0.0,
                timeframe="multi", momentum_score=0.0,
                trend_quality=0.0, breakout_level=0.0,
            )

        momentum = self.calculate_momentum_score(prices)
        quality = self.trend_quality(prices[-self.slow_period:])

        # ATR for breakout level
        h = highs or prices
        l = lows or prices
        atr = self.calculate_atr(h, l, prices) if len(h) >= 2 else 0.0

        # Signal generation
        strength = min(1.0, abs(momentum) * 10 * quality)

        if momentum > 0 and quality > 0.3:
            direction = "long"
            breakout_level = prices[-1] + atr * self.breakout_threshold
        elif momentum < 0 and quality > 0.3:
            direction = "short"
            breakout_level = prices[-1] - atr * self.breakout_threshold
        else:
            direction = "flat"
            breakout_level = prices[-1]
            strength = 0.0

        return MomentumSignal(
            symbol=symbol,
            direction=direction,
            strength=strength,
            timeframe="multi",
            momentum_score=momentum,
            trend_quality=quality,
            breakout_level=breakout_level,
        )
