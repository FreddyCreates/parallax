"""Volatility Arbitrage Strategy.

Trades the spread between implied and realized volatility.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class VolArbSignal:
    symbol: str
    implied_vol: float
    realized_vol: float
    vol_spread: float
    direction: str  # "sell_vol", "buy_vol", "flat"
    confidence: float
    term_structure_slope: float


class VolatilityArbitrageStrategy:
    """Volatility arbitrage — trade IV vs RV spread."""

    def __init__(
        self,
        entry_spread: float = 0.03,
        exit_spread: float = 0.01,
        rv_window: int = 20,
        min_confidence: float = 0.5,
    ) -> None:
        self.entry_spread = entry_spread
        self.exit_spread = exit_spread
        self.rv_window = rv_window
        self.min_confidence = min_confidence

    def calculate_realized_vol(self, prices: list[float], annualize: bool = True) -> float:
        """Calculate realized volatility from price series."""
        if len(prices) < 3:
            return 0.0

        log_returns = [math.log(prices[i] / prices[i - 1]) for i in range(1, len(prices))]
        n = len(log_returns)
        mean = sum(log_returns) / n
        variance = sum((r - mean) ** 2 for r in log_returns) / (n - 1)
        vol = math.sqrt(variance)

        if annualize:
            vol *= math.sqrt(252)

        return vol

    def calculate_vol_of_vol(self, prices: list[float], window: int = 5) -> float:
        """Calculate volatility of volatility (vol clustering)."""
        if len(prices) < window * 3:
            return 0.0

        rolling_vols = []
        for i in range(window, len(prices)):
            sub_prices = prices[i - window: i + 1]
            rv = self.calculate_realized_vol(sub_prices, annualize=False)
            rolling_vols.append(rv)

        if len(rolling_vols) < 3:
            return 0.0

        return self.calculate_realized_vol(
            [1 + v for v in rolling_vols], annualize=False
        )

    def generate_signal(
        self,
        symbol: str,
        prices: list[float],
        implied_vol: float,
        term_structure: list[float] | None = None,
    ) -> VolArbSignal:
        """Generate volatility arbitrage signal."""
        realized_vol = self.calculate_realized_vol(prices[-self.rv_window:])
        vol_spread = implied_vol - realized_vol

        # Term structure slope
        slope = 0.0
        if term_structure and len(term_structure) >= 2:
            slope = term_structure[-1] - term_structure[0]

        # Signal
        if vol_spread > self.entry_spread:
            direction = "sell_vol"
            confidence = min(1.0, vol_spread / (self.entry_spread * 3))
        elif vol_spread < -self.entry_spread:
            direction = "buy_vol"
            confidence = min(1.0, abs(vol_spread) / (self.entry_spread * 3))
        else:
            direction = "flat"
            confidence = 0.0

        return VolArbSignal(
            symbol=symbol,
            implied_vol=implied_vol,
            realized_vol=realized_vol,
            vol_spread=vol_spread,
            direction=direction,
            confidence=confidence,
            term_structure_slope=slope,
        )
