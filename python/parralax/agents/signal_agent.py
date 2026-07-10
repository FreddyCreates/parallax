"""Signal generation agent — produces trading signals from market data."""

from typing import Any

import numpy as np

from .base import AgentRole, BaseAgent


class SignalAgent(BaseAgent):
    """Agent that generates trading signals from market data analysis."""

    def __init__(self, name: str, strategies: list[str] | None = None):
        super().__init__(name=name, role=AgentRole.OBSERVER)
        self.strategies = strategies or ["momentum", "mean_reversion", "breakout"]
        self.signal_history: list[dict[str, Any]] = []

    async def tick(self, market_state: dict[str, Any]) -> list[dict[str, Any]]:
        """Analyze market state and produce signals."""
        signals: list[dict[str, Any]] = []

        prices = market_state.get("prices", {})
        for symbol, price_data in prices.items():
            for strategy in self.strategies:
                signal = self._evaluate_strategy(strategy, symbol, price_data)
                if signal:
                    signals.append(signal)
                    self.memory.record_signal(signal)

        return signals

    async def on_fill(self, fill: dict[str, Any]) -> None:
        """Record fill for signal quality feedback."""
        self.memory.record_trade(fill)

    def _evaluate_strategy(
        self, strategy: str, symbol: str, price_data: dict[str, Any]
    ) -> dict[str, Any] | None:
        """Evaluate a single strategy against price data."""
        closes = price_data.get("closes", [])
        if len(closes) < 20:
            return None

        arr = np.array(closes, dtype=np.float64)

        if strategy == "momentum":
            return self._momentum_signal(symbol, arr)
        elif strategy == "mean_reversion":
            return self._mean_reversion_signal(symbol, arr)
        elif strategy == "breakout":
            return self._breakout_signal(symbol, arr)
        return None

    def _momentum_signal(self, symbol: str, closes: np.ndarray) -> dict[str, Any] | None:
        """Simple momentum: compare short MA to long MA."""
        short_ma = float(np.mean(closes[-5:]))
        long_ma = float(np.mean(closes[-20:]))
        strength = (short_ma - long_ma) / long_ma

        if abs(strength) < 0.005:
            return None

        return {
            "type": "signal",
            "strategy": "momentum",
            "symbol": symbol,
            "direction": "buy" if strength > 0 else "sell",
            "strength": abs(strength),
            "agent_id": str(self.id),
        }

    def _mean_reversion_signal(self, symbol: str, closes: np.ndarray) -> dict[str, Any] | None:
        """Mean reversion: z-score based signal."""
        mean = float(np.mean(closes[-20:]))
        std = float(np.std(closes[-20:]))
        if std == 0:
            return None

        z_score = (float(closes[-1]) - mean) / std

        if abs(z_score) < 1.5:
            return None

        return {
            "type": "signal",
            "strategy": "mean_reversion",
            "symbol": symbol,
            "direction": "buy" if z_score < -1.5 else "sell",
            "strength": min(abs(z_score) / 3.0, 1.0),
            "agent_id": str(self.id),
        }

    def _breakout_signal(self, symbol: str, closes: np.ndarray) -> dict[str, Any] | None:
        """Breakout: price exceeds recent high/low channel."""
        high = float(np.max(closes[-20:-1]))
        low = float(np.min(closes[-20:-1]))
        current = float(closes[-1])

        if current > high:
            return {
                "type": "signal",
                "strategy": "breakout",
                "symbol": symbol,
                "direction": "buy",
                "strength": min((current - high) / high * 10, 1.0),
                "agent_id": str(self.id),
            }
        elif current < low:
            return {
                "type": "signal",
                "strategy": "breakout",
                "symbol": symbol,
                "direction": "sell",
                "strength": min((low - current) / low * 10, 1.0),
                "agent_id": str(self.id),
            }
        return None
