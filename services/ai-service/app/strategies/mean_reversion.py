"""Mean Reversion Strategy.

Identifies and trades temporary price dislocations back to equilibrium.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class MeanReversionSignal:
    symbol: str
    direction: str
    distance_from_mean: float
    bollinger_position: float  # 0=lower band, 1=upper band
    rsi: float
    mean_target: float
    confidence: float


class MeanReversionStrategy:
    """Mean reversion using Bollinger Bands, RSI, and Ornstein-Uhlenbeck."""

    def __init__(
        self,
        bb_period: int = 20,
        bb_std: float = 2.0,
        rsi_period: int = 14,
        rsi_oversold: float = 30.0,
        rsi_overbought: float = 70.0,
        entry_threshold: float = 0.8,
    ) -> None:
        self.bb_period = bb_period
        self.bb_std = bb_std
        self.rsi_period = rsi_period
        self.rsi_oversold = rsi_oversold
        self.rsi_overbought = rsi_overbought
        self.entry_threshold = entry_threshold

    def bollinger_bands(self, prices: list[float]) -> tuple[float, float, float]:
        """Calculate Bollinger Bands (upper, middle, lower)."""
        if len(prices) < self.bb_period:
            mid = prices[-1] if prices else 0
            return mid, mid, mid

        window = prices[-self.bb_period:]
        mean = sum(window) / len(window)
        std = math.sqrt(sum((x - mean) ** 2 for x in window) / len(window))

        upper = mean + self.bb_std * std
        lower = mean - self.bb_std * std
        return upper, mean, lower

    def calculate_rsi(self, prices: list[float]) -> float:
        """Calculate Relative Strength Index."""
        if len(prices) < self.rsi_period + 1:
            return 50.0

        changes = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
        recent = changes[-self.rsi_period:]

        gains = [c for c in recent if c > 0]
        losses = [-c for c in recent if c < 0]

        avg_gain = sum(gains) / self.rsi_period if gains else 0
        avg_loss = sum(losses) / self.rsi_period if losses else 0

        if avg_loss == 0:
            return 100.0
        rs = avg_gain / avg_loss
        return 100 - (100 / (1 + rs))

    def generate_signal(self, symbol: str, prices: list[float]) -> MeanReversionSignal:
        """Generate mean reversion signal."""
        if len(prices) < self.bb_period:
            return MeanReversionSignal(
                symbol=symbol, direction="flat",
                distance_from_mean=0.0, bollinger_position=0.5,
                rsi=50.0, mean_target=prices[-1] if prices else 0,
                confidence=0.0,
            )

        upper, mean, lower = self.bollinger_bands(prices)
        rsi = self.calculate_rsi(prices)
        current = prices[-1]

        # Bollinger position (0=at lower, 1=at upper)
        bb_width = upper - lower if upper != lower else 1
        bb_position = (current - lower) / bb_width

        # Distance from mean (normalized)
        distance = (current - mean) / (upper - mean) if upper != mean else 0

        # Signal logic
        confidence = 0.0
        if bb_position < (1 - self.entry_threshold) and rsi < self.rsi_oversold:
            direction = "long"
            confidence = min(1.0, (1 - bb_position) * (1 - rsi / 100))
        elif bb_position > self.entry_threshold and rsi > self.rsi_overbought:
            direction = "short"
            confidence = min(1.0, bb_position * (rsi / 100))
        else:
            direction = "flat"

        return MeanReversionSignal(
            symbol=symbol,
            direction=direction,
            distance_from_mean=distance,
            bollinger_position=bb_position,
            rsi=rsi,
            mean_target=mean,
            confidence=confidence,
        )
