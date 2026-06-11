"""Statistical Arbitrage Strategy."""

from __future__ import annotations

import math
from dataclasses import dataclass
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
        self.signal_history: list[StatArbSignal] = []
        self.last_diagnostics: dict[str, Any] = {}

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

    def _linear_regression(self, x: list[float], y: list[float]) -> tuple[float, float]:
        if len(x) != len(y) or len(x) < 2:
            return 0.0, 0.0
        x_mean = self._mean(x)
        y_mean = self._mean(y)
        denominator = sum((value - x_mean) ** 2 for value in x)
        if denominator == 0:
            return y_mean, 0.0
        beta = sum((vx - x_mean) * (vy - y_mean) for vx, vy in zip(x, y)) / denominator
        return y_mean - beta * x_mean, beta

    def calculate_z_score(self, spread: list[float]) -> float:
        """Calculate z-score of current spread value."""
        if len(spread) < 2:
            return 0.0
        window = spread[-self.lookback :] if len(spread) > self.lookback else spread
        std = self._std(window)
        return (window[-1] - self._mean(window)) / std if std > 0 else 0.0

    def calculate_hedge_ratio(self, prices_a: list[float], prices_b: list[float]) -> float:
        """Calculate optimal hedge ratio via OLS regression."""
        if len(prices_a) != len(prices_b) or len(prices_a) < 10:
            return 1.0
        _, beta = self._linear_regression(prices_b[-self.lookback :], prices_a[-self.lookback :])
        return beta if beta != 0 else 1.0

    def estimate_ou_parameters(self, spread: list[float]) -> dict[str, float]:
        """Estimate Ornstein-Uhlenbeck parameters for the spread."""
        if len(spread) < 10:
            return {"mean": 0.0, "speed": 0.0, "vol": 0.0, "residual_std": 0.0}
        window = spread[-self.lookback :] if len(spread) > self.lookback else spread
        mean_level = self._mean(window)
        lagged = [value - mean_level for value in window[:-1]]
        delta = [window[index + 1] - window[index] for index in range(len(window) - 1)]
        _, beta = self._linear_regression(lagged, delta)
        residuals = [dy - beta * x for x, dy in zip(lagged, delta)]
        return {
            "mean": mean_level,
            "speed": max(0.0, -beta),
            "vol": self._std(residuals) * math.sqrt(252),
            "residual_std": self._std(residuals),
        }

    def estimate_half_life(self, spread: list[float]) -> float:
        """Estimate mean-reversion half-life using an OU approximation."""
        speed = self.estimate_ou_parameters(spread)["speed"]
        return math.log(2) / speed if speed > 0 else float("inf")

    def calculate_cointegration_score(
        self, prices_a: list[float], prices_b: list[float], hedge_ratio: float | None = None
    ) -> float:
        """Approximate Engle-Granger strength using residual stationarity diagnostics."""
        if len(prices_a) != len(prices_b) or len(prices_a) < 20:
            return 0.0
        beta = hedge_ratio if hedge_ratio is not None else self.calculate_hedge_ratio(prices_a, prices_b)
        spread = [a - beta * b for a, b in zip(prices_a[-self.lookback :], prices_b[-self.lookback :])]
        spread_std = self._std(spread)
        if spread_std == 0:
            return 0.0
        lagged = spread[:-1]
        delta = [spread[index + 1] - spread[index] for index in range(len(spread) - 1)]
        _, beta_delta = self._linear_regression(lagged, delta)
        residuals = [dy - beta_delta * x for x, dy in zip(lagged, delta)]
        residual_std = self._std(residuals)
        x_var = sum(value * value for value in lagged)
        if residual_std == 0 or x_var == 0:
            return 0.0
        stderr = residual_std / math.sqrt(x_var)
        t_stat = beta_delta / stderr if stderr > 0 else 0.0
        stationarity = self._clamp((abs(t_stat) - 2.0) / 4.0, 0.0, 1.0)
        drift_penalty = self._clamp(abs(self._mean(spread)) / spread_std, 0.0, 1.0)
        return self._clamp(stationarity * (1.0 - 0.5 * drift_penalty), 0.0, 1.0)

    def expected_reversion(self, spread: list[float], half_life: float) -> float:
        """Estimate one-step convergence toward the equilibrium mean."""
        if not spread or not math.isfinite(half_life) or half_life <= 0:
            return 0.0
        distance = spread[-1] - self._mean(spread[-self.lookback :])
        return -distance * (1.0 - math.exp(-1.0 / half_life))

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return position-level statistical arbitrage risk metrics."""
        spread_std = float(self.last_diagnostics.get("spread_std", 0.0))
        z_score = float(self.last_diagnostics.get("z_score", 0.0))
        gross_exposure = sum(abs(position.get("notional", 0.0)) for position in self.positions.values())
        max_loss = gross_exposure * spread_std * max(1.0, abs(z_score))
        return {
            "active_pairs": len(self.positions),
            "gross_exposure": gross_exposure,
            "spread_volatility": spread_std,
            "max_loss": max_loss,
            "expected_drawdown": max_loss * 0.35,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current strategy health and diagnostics."""
        last_signal = self.signal_history[-1] if self.signal_history else None
        half_life = float(self.last_diagnostics.get("half_life", float("inf")))
        return {
            "healthy": bool(self.last_diagnostics) and math.isfinite(half_life) and half_life <= self.max_half_life * 1.5,
            "positions": list(self.positions.keys()),
            "signals_generated": len(self.signal_history),
            "last_signal": last_signal.signal.value if last_signal else SignalStrength.NEUTRAL.value,
            "diagnostics": self.last_diagnostics,
        }

    def generate_signal(
        self, pair: tuple[str, str], prices_a: list[float], prices_b: list[float]
    ) -> StatArbSignal:
        """Generate trading signal for a pair."""
        pair_key = f"{pair[0]}/{pair[1]}"
        if len(prices_a) != len(prices_b) or len(prices_a) < max(20, self.lookback // 2):
            signal = StatArbSignal(pair, 0.0, float("inf"), SignalStrength.NEUTRAL, 0.0, 1.0, 0.0)
            self.signal_history.append(signal)
            return signal
        hedge_ratio = self.calculate_hedge_ratio(prices_a, prices_b)
        spread = [a - hedge_ratio * b for a, b in zip(prices_a, prices_b)]
        spread_window = spread[-self.lookback :] if len(spread) > self.lookback else spread
        z_score = self.calculate_z_score(spread_window)
        half_life = self.estimate_half_life(spread_window)
        cointegration = self.calculate_cointegration_score(prices_a, prices_b, hedge_ratio)
        ou_params = self.estimate_ou_parameters(spread_window)
        expected_move = self.expected_reversion(spread_window, half_life)
        spread_std = self._std(spread_window)
        tradeable = cointegration >= 0.35 and math.isfinite(half_life) and self.min_half_life <= half_life <= self.max_half_life and spread_std > 0
        confidence = 0.0
        signal_strength = SignalStrength.NEUTRAL
        if tradeable and abs(z_score) >= self.entry_z:
            normalized = self._clamp(abs(z_score) / self.stop_z, 0.0, 1.0)
            reversion_quality = self._clamp(ou_params["speed"] * 10.0, 0.0, 1.0)
            confidence = normalized * 0.45 + cointegration * 0.35 + reversion_quality * 0.20
            if z_score > 0:
                signal_strength = SignalStrength.STRONG_SELL if z_score > self.entry_z * 1.5 else SignalStrength.SELL
            else:
                signal_strength = SignalStrength.STRONG_BUY if z_score < -self.entry_z * 1.5 else SignalStrength.BUY
        elif abs(z_score) <= self.exit_z or abs(z_score) >= self.stop_z:
            signal_strength = SignalStrength.NEUTRAL
        if signal_strength is SignalStrength.NEUTRAL:
            self.positions.pop(pair_key, None)
        else:
            self.positions[pair_key] = {
                "pair": pair,
                "signal": signal_strength.value,
                "z_score": z_score,
                "notional": abs(spread_window[-1]) + abs(hedge_ratio * prices_b[-1]),
                "expected_move": expected_move,
            }
        self.last_diagnostics = {
            "pair": pair_key,
            "z_score": z_score,
            "cointegration": cointegration,
            "half_life": half_life,
            "spread_std": spread_std,
            "ou_speed": ou_params["speed"],
            "expected_reversion": expected_move,
        }
        signal = StatArbSignal(pair, z_score, half_life, signal_strength, self._clamp(confidence, 0.0, 1.0), hedge_ratio, spread_window[-1])
        self.signal_history.append(signal)
        return signal
