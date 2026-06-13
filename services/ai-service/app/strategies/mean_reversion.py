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
        self.signal_history: list[MeanReversionSignal] = []
        self.last_state: dict[str, Any] = {}

    def _mean(self, values: list[float]) -> float:
        return sum(values) / len(values) if values else 0.0

    def _std(self, values: list[float]) -> float:
        if len(values) < 2:
            return 0.0
        mean = self._mean(values)
        variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
        return math.sqrt(max(variance, 0.0))

    def _clamp(self, value: float, lower: float, upper: float) -> float:
        return max(lower, min(upper, value))

    def bollinger_bands(self, prices: list[float]) -> tuple[float, float, float]:
        """Calculate Bollinger Bands (upper, middle, lower)."""
        if len(prices) < self.bb_period:
            mid = prices[-1] if prices else 0.0
            return mid, mid, mid

        window = prices[-self.bb_period :]
        mean = self._mean(window)
        std = self._std(window)
        upper = mean + self.bb_std * std
        lower = mean - self.bb_std * std
        return upper, mean, lower

    def calculate_rsi(self, prices: list[float]) -> float:
        """Calculate Relative Strength Index using smoothed gains and losses."""
        if len(prices) < self.rsi_period + 1:
            return 50.0

        changes = [prices[index] - prices[index - 1] for index in range(1, len(prices))]
        recent = changes[-self.rsi_period :]
        gains = [max(change, 0.0) for change in recent]
        losses = [abs(min(change, 0.0)) for change in recent]
        avg_gain = sum(gains) / self.rsi_period
        avg_loss = sum(losses) / self.rsi_period
        if avg_loss == 0:
            return 100.0 if avg_gain > 0 else 50.0
        rs = avg_gain / avg_loss
        return 100 - (100 / (1 + rs))

    def calculate_z_score(self, prices: list[float]) -> float:
        """Calculate normalized deviation from the rolling mean."""
        if len(prices) < self.bb_period:
            return 0.0
        window = prices[-self.bb_period :]
        std = self._std(window)
        if std == 0:
            return 0.0
        return (window[-1] - self._mean(window)) / std

    def estimate_half_life(self, prices: list[float]) -> float:
        """Estimate half-life of mean reversion from price deviations."""
        if len(prices) < self.bb_period + 2:
            return float("inf")
        window = prices[-self.bb_period :]
        mean = self._mean(window)
        deviations = [value - mean for value in window]
        lagged = deviations[:-1]
        delta = [deviations[index + 1] - deviations[index] for index in range(len(deviations) - 1)]
        denominator = sum(value * value for value in lagged)
        if denominator == 0:
            return float("inf")
        beta = sum(x * y for x, y in zip(lagged, delta)) / denominator
        speed = max(0.0, -beta)
        if speed <= 0:
            return float("inf")
        return math.log(2) / speed

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return drawdown and stop-out risk metrics."""
        z_score = abs(float(self.last_state.get("z_score", 0.0)))
        band_width = float(self.last_state.get("band_width", 0.0))
        max_loss = band_width * max(1.0, z_score)
        expected_drawdown = max_loss * 0.5
        return {
            "z_score": z_score,
            "band_width": band_width,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current mean-reversion health and state."""
        half_life = float(self.last_state.get("half_life", float("inf")))
        return {
            "healthy": math.isfinite(half_life) and half_life < self.bb_period * 3,
            "signals_generated": len(self.signal_history),
            "last_state": self.last_state,
        }

    def generate_signal(self, symbol: str, prices: list[float]) -> MeanReversionSignal:
        """Generate mean reversion signal."""
        if len(prices) < self.bb_period:
            signal = MeanReversionSignal(symbol, "flat", 0.0, 0.5, 50.0, prices[-1] if prices else 0.0, 0.0)
            self.signal_history.append(signal)
            return signal

        upper, mean, lower = self.bollinger_bands(prices)
        rsi = self.calculate_rsi(prices)
        current = prices[-1]
        band_width = max(upper - lower, 1e-9)
        bb_position = self._clamp((current - lower) / band_width, 0.0, 1.0)
        z_score = self.calculate_z_score(prices)
        half_life = self.estimate_half_life(prices)

        bb_signal = 0.5 - bb_position
        rsi_signal = 0.0
        if rsi <= self.rsi_oversold:
            rsi_signal = (self.rsi_oversold - rsi) / max(self.rsi_oversold, 1.0)
        elif rsi >= self.rsi_overbought:
            rsi_signal = -(rsi - self.rsi_overbought) / max(100.0 - self.rsi_overbought, 1.0)

        z_signal = -z_score / max(self.bb_std, 1.0)
        composite = 0.45 * bb_signal + 0.30 * rsi_signal + 0.25 * z_signal
        confidence = self._clamp(abs(composite), 0.0, 1.0)

        if composite > self.entry_threshold - 0.5 and math.isfinite(half_life):
            direction = "long"
        elif composite < -(self.entry_threshold - 0.5) and math.isfinite(half_life):
            direction = "short"
        else:
            direction = "flat"
            confidence = 0.0

        if not (1.0 <= half_life <= self.bb_period * 4):
            confidence *= 0.5
        signal = MeanReversionSignal(
            symbol=symbol,
            direction=direction,
            distance_from_mean=(current - mean) / mean if mean != 0 else 0.0,
            bollinger_position=bb_position,
            rsi=rsi,
            mean_target=mean,
            confidence=self._clamp(confidence, 0.0, 1.0),
        )
        self.last_state = {
            "symbol": symbol,
            "z_score": z_score,
            "half_life": half_life,
            "band_width": band_width,
            "composite_score": composite,
        }
        self.signal_history.append(signal)
        return signal
