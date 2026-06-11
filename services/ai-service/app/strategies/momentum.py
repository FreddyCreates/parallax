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
        self.signal_history: list[MomentumSignal] = []
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
        if len(highs) < 2 or len(lows) < 2 or len(closes) < 2:
            return 0.0
        true_ranges = []
        for index in range(1, len(highs)):
            tr = max(highs[index] - lows[index], abs(highs[index] - closes[index - 1]), abs(lows[index] - closes[index - 1]))
            true_ranges.append(tr)
        period = min(self.atr_period, len(true_ranges))
        return sum(true_ranges[-period:]) / period if period > 0 else 0.0

    def calculate_momentum_score(self, prices: list[float]) -> float:
        """Multi-timeframe momentum composite score."""
        if len(prices) < self.slow_period:
            return 0.0
        scores = []
        short_ret = (prices[-1] / prices[-self.fast_period] - 1) if prices[-self.fast_period] > 0 else 0.0
        scores.append(short_ret)
        med_period = (self.fast_period + self.slow_period) // 2
        if len(prices) >= med_period and prices[-med_period] > 0:
            scores.append(prices[-1] / prices[-med_period] - 1)
        long_ret = (prices[-1] / prices[-self.slow_period] - 1) if prices[-self.slow_period] > 0 else 0.0
        scores.append(long_ret)
        weights = [0.5, 0.3, 0.2] if len(scores) == 3 else [0.6, 0.4]
        return sum(score * weight for score, weight in zip(scores, weights[: len(scores)]))

    def trend_quality(self, prices: list[float]) -> float:
        """Measure trend quality / consistency (R-squared of linear fit)."""
        n = len(prices)
        if n < 5:
            return 0.0
        x_mean = (n - 1) / 2
        y_mean = sum(prices) / n
        ss_xy = sum((index - x_mean) * (prices[index] - y_mean) for index in range(n))
        ss_xx = sum((index - x_mean) ** 2 for index in range(n))
        ss_yy = sum((price - y_mean) ** 2 for price in prices)
        if ss_xx == 0 or ss_yy == 0:
            return 0.0
        return min(1.0, (ss_xy**2) / (ss_xx * ss_yy))

    def detect_regime(self, prices: list[float]) -> str:
        """Classify the environment into trending, choppy, or stressed regimes."""
        if len(prices) < self.fast_period + 2:
            return "neutral"
        returns = [math.log(prices[index] / prices[index - 1]) for index in range(1, len(prices)) if prices[index - 1] > 0]
        volatility = self._std(returns[-self.atr_period :]) * math.sqrt(252) if returns else 0.0
        trend = self.trend_quality(prices[-self.slow_period :])
        if volatility > 0.45:
            return "stressed"
        if trend > 0.55:
            return "trending"
        return "choppy"

    def regime_adaptive_parameters(self, prices: list[float]) -> dict[str, float]:
        """Adapt breakout and confidence thresholds based on the current regime."""
        regime = self.detect_regime(prices)
        if regime == "trending":
            return {"breakout_multiplier": 1.25, "strength_scale": 1.15, "quality_floor": 0.25}
        if regime == "stressed":
            return {"breakout_multiplier": 1.75, "strength_scale": 0.7, "quality_floor": 0.4}
        return {"breakout_multiplier": 1.0, "strength_scale": 0.85, "quality_floor": 0.35}

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return momentum-specific risk metrics."""
        strength = float(self.last_state.get("strength", 0.0))
        atr = float(self.last_state.get("atr", 0.0))
        max_loss = atr * max(1.0, strength * 2.5)
        expected_drawdown = max_loss * 0.45
        return {
            "regime": self.last_state.get("regime", "neutral"),
            "atr": atr,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current strategy state and health."""
        return {
            "healthy": bool(self.last_state) and self.last_state.get("trend_quality", 0.0) >= 0.15,
            "signals_generated": len(self.signal_history),
            "last_state": self.last_state,
        }

    def generate_signal(
        self,
        symbol: str,
        prices: list[float],
        highs: list[float] | None = None,
        lows: list[float] | None = None,
    ) -> MomentumSignal:
        """Generate momentum trading signal."""
        if len(prices) < self.slow_period:
            signal = MomentumSignal(symbol, "flat", 0.0, "multi", 0.0, 0.0, prices[-1] if prices else 0.0)
            self.signal_history.append(signal)
            return signal

        momentum = self.calculate_momentum_score(prices)
        quality = self.trend_quality(prices[-self.slow_period :])
        regime_params = self.regime_adaptive_parameters(prices)
        regime = self.detect_regime(prices)

        fast_ema = self.exponential_moving_average(prices, self.fast_period)
        slow_ema = self.exponential_moving_average(prices, self.slow_period)
        ema_spread = fast_ema[-1] - slow_ema[-1] if fast_ema and slow_ema else 0.0

        h = highs or prices
        l = lows or prices
        atr = self.calculate_atr(h, l, prices)
        breakout_distance = atr * self.breakout_threshold * regime_params["breakout_multiplier"]
        normalized_momentum = momentum + (ema_spread / prices[-1] if prices[-1] > 0 else 0.0)
        raw_strength = abs(normalized_momentum) * 8.0 * max(quality, 0.1)
        strength = self._clamp(raw_strength * regime_params["strength_scale"], 0.0, 1.0)

        if normalized_momentum > 0 and quality >= regime_params["quality_floor"]:
            direction = "long"
            breakout_level = prices[-1] + breakout_distance
        elif normalized_momentum < 0 and quality >= regime_params["quality_floor"]:
            direction = "short"
            breakout_level = prices[-1] - breakout_distance
        else:
            direction = "flat"
            breakout_level = prices[-1]
            strength = 0.0

        signal = MomentumSignal(
            symbol=symbol,
            direction=direction,
            strength=strength,
            timeframe="multi",
            momentum_score=normalized_momentum,
            trend_quality=quality,
            breakout_level=breakout_level,
        )
        self.last_state = {
            "symbol": symbol,
            "regime": regime,
            "atr": atr,
            "strength": strength,
            "trend_quality": quality,
            "momentum": normalized_momentum,
        }
        self.signal_history.append(signal)
        return signal
