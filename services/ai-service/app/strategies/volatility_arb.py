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
        self.last_state: dict[str, Any] = {}
        self.position_greeks: dict[str, dict[str, float]] = {}

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

    def _normal_cdf(self, x: float) -> float:
        return 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))

    def calculate_realized_vol(self, prices: list[float], annualize: bool = True) -> float:
        """Calculate realized volatility from price series."""
        if len(prices) < 3:
            return 0.0
        log_returns = [math.log(prices[index] / prices[index - 1]) for index in range(1, len(prices)) if prices[index - 1] > 0]
        if len(log_returns) < 2:
            return 0.0
        variance = self._std(log_returns) ** 2
        vol = math.sqrt(variance)
        if annualize:
            vol *= math.sqrt(252)
        return vol

    def calculate_vol_of_vol(self, prices: list[float], window: int = 5) -> float:
        """Calculate volatility of volatility (vol clustering)."""
        if len(prices) < window * 3:
            return 0.0
        rolling_vols = []
        for index in range(window, len(prices)):
            sub_prices = prices[index - window : index + 1]
            rolling_vols.append(self.calculate_realized_vol(sub_prices, annualize=False))
        return self._std(rolling_vols) * math.sqrt(252) if len(rolling_vols) > 1 else 0.0

    def estimate_implied_vol(
        self,
        option_price: float,
        spot: float,
        strike: float,
        time_to_expiry: float,
        option_type: str = "call",
    ) -> float:
        """Estimate Black-Scholes implied volatility with a bounded bisection search."""
        if min(option_price, spot, strike, time_to_expiry) <= 0:
            return 0.0
        low, high = 0.01, 3.0
        for _ in range(40):
            mid = (low + high) / 2
            price = self.black_scholes_price(spot, strike, time_to_expiry, mid, option_type)
            if price > option_price:
                high = mid
            else:
                low = mid
        return (low + high) / 2

    def black_scholes_price(
        self, spot: float, strike: float, time_to_expiry: float, vol: float, option_type: str
    ) -> float:
        """Calculate Black-Scholes option price."""
        if min(spot, strike, time_to_expiry, vol) <= 0:
            return max(0.0, spot - strike) if option_type == "call" else max(0.0, strike - spot)
        sqrt_t = math.sqrt(time_to_expiry)
        d1 = (math.log(spot / strike) + 0.5 * vol * vol * time_to_expiry) / (vol * sqrt_t)
        d2 = d1 - vol * sqrt_t
        if option_type == "call":
            return spot * self._normal_cdf(d1) - strike * self._normal_cdf(d2)
        return strike * self._normal_cdf(-d2) - spot * self._normal_cdf(-d1)

    def calculate_greeks(
        self, spot: float, strike: float, time_to_expiry: float, implied_vol: float
    ) -> dict[str, float]:
        """Calculate delta, gamma, and vega for positioning decisions."""
        if min(spot, strike, time_to_expiry, implied_vol) <= 0:
            return {"delta": 0.0, "gamma": 0.0, "vega": 0.0}
        sqrt_t = math.sqrt(time_to_expiry)
        d1 = (math.log(spot / strike) + 0.5 * implied_vol * implied_vol * time_to_expiry) / (implied_vol * sqrt_t)
        pdf = math.exp(-0.5 * d1 * d1) / math.sqrt(2.0 * math.pi)
        gamma = pdf / (spot * implied_vol * sqrt_t)
        vega = spot * pdf * sqrt_t / 100.0
        delta = self._normal_cdf(d1)
        return {"delta": delta, "gamma": gamma, "vega": vega}

    def target_position_size(self, vol_spread: float, greeks: dict[str, float], vol_of_vol: float) -> float:
        """Size volatility positions using spread edge and Greek sensitivity."""
        vega = max(greeks.get("vega", 0.0), 1e-6)
        vol_penalty = 1.0 + vol_of_vol * 2.0
        return abs(vol_spread) / (vega * vol_penalty)

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return option-greek risk metrics."""
        greeks = self.last_state.get("greeks", {"gamma": 0.0, "vega": 0.0})
        max_loss = abs(float(self.last_state.get("position_size", 0.0))) * (abs(greeks.get("vega", 0.0)) + 1.0)
        expected_drawdown = max_loss * 0.45
        return {
            "greeks": greeks,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
            "vol_spread": self.last_state.get("vol_spread", 0.0),
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return volatility-arbitrage state and health."""
        confidence = float(self.last_state.get("confidence", 0.0))
        return {
            "healthy": not self.last_state or confidence >= self.min_confidence * 0.5,
            "last_state": self.last_state,
            "open_positions": list(self.position_greeks.keys()),
        }

    def generate_signal(
        self,
        symbol: str,
        prices: list[float],
        implied_vol: float,
        term_structure: list[float] | None = None,
    ) -> VolArbSignal:
        """Generate volatility arbitrage signal."""
        window_prices = prices[-self.rv_window :] if len(prices) >= self.rv_window else prices
        realized_vol = self.calculate_realized_vol(window_prices)
        vol_spread = implied_vol - realized_vol
        vol_of_vol = self.calculate_vol_of_vol(prices)
        slope = 0.0
        if term_structure and len(term_structure) >= 2:
            slope = (term_structure[-1] - term_structure[0]) / max(len(term_structure) - 1, 1)

        direction = "flat"
        if vol_spread > self.entry_spread:
            direction = "sell_vol"
        elif vol_spread < -self.entry_spread:
            direction = "buy_vol"

        spot = prices[-1] if prices else 1.0
        greeks = self.calculate_greeks(spot, spot, 30 / 365, max(implied_vol, 0.01))
        position_size = self.target_position_size(vol_spread, greeks, vol_of_vol) if direction != "flat" else 0.0
        confidence = self._clamp(
            abs(vol_spread) / max(self.entry_spread * (1.0 + vol_of_vol), 1e-6) * (0.6 + 0.4 * abs(greeks["vega"])),
            0.0,
            1.0,
        )
        if abs(vol_spread) < self.exit_spread:
            direction = "flat"
            confidence = 0.0
            position_size = 0.0

        self.position_greeks[symbol] = greeks if direction != "flat" else {"delta": 0.0, "gamma": 0.0, "vega": 0.0}
        self.last_state = {
            "symbol": symbol,
            "vol_spread": vol_spread,
            "confidence": confidence,
            "term_structure_slope": slope,
            "vol_of_vol": vol_of_vol,
            "greeks": greeks,
            "position_size": position_size,
        }
        return VolArbSignal(
            symbol=symbol,
            implied_vol=implied_vol,
            realized_vol=realized_vol,
            vol_spread=vol_spread,
            direction=direction,
            confidence=confidence,
            term_structure_slope=slope,
        )
