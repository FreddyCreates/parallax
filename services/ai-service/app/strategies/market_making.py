"""Market Making Strategy.

Provides liquidity by quoting bid/ask prices, earning the spread
while managing inventory risk through dynamic quoting.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class Quote:
    symbol: str
    bid_price: float
    ask_price: float
    bid_size: float
    ask_size: float
    spread: float
    skew: float


class MarketMakingStrategy:
    """Avellaneda-Stoikov market making with inventory management."""

    def __init__(
        self,
        base_spread_bps: float = 5.0,
        gamma: float = 0.1,
        sigma: float = 0.02,
        kappa: float = 1.5,
        max_inventory: float = 100.0,
        tick_size: float = 0.01,
    ) -> None:
        self.base_spread_bps = base_spread_bps
        self.gamma = gamma
        self.sigma = sigma
        self.kappa = kappa
        self.max_inventory = max_inventory
        self.tick_size = tick_size
        self.inventory: dict[str, float] = {}
        self.quote_history: dict[str, list[Quote]] = {}
        self.fill_stats: dict[str, dict[str, float]] = {}
        self.last_metrics: dict[str, Any] = {}

    def _clamp(self, value: float, lower: float, upper: float) -> float:
        return max(lower, min(upper, value))

    def _round_down(self, price: float) -> float:
        return math.floor(price / self.tick_size) * self.tick_size

    def _round_up(self, price: float) -> float:
        return math.ceil(price / self.tick_size) * self.tick_size

    def calculate_reservation_price(
        self, mid_price: float, inventory: float, time_remaining: float = 1.0
    ) -> float:
        """Calculate reservation (indifference) price based on inventory."""
        inventory_penalty = inventory * self.gamma * self.sigma**2 * max(time_remaining, 0.05)
        return mid_price - inventory_penalty

    def calculate_optimal_spread(self, time_remaining: float = 1.0) -> float:
        """Calculate optimal spread width."""
        adjusted_time = max(time_remaining, 0.05)
        model_spread = (
            self.gamma * self.sigma**2 * adjusted_time
            + (2 / self.gamma) * math.log(1 + self.gamma / self.kappa)
        )
        return max(model_spread, self.base_spread_bps / 10000.0)

    def inventory_skew(self, current_inventory: float) -> float:
        """Lean quotes away from existing inventory concentration."""
        if self.max_inventory <= 0:
            return 0.0
        utilization = self._clamp(current_inventory / self.max_inventory, -1.0, 1.0)
        return utilization + 0.4 * utilization**3

    def estimate_fill_probability(self, distance: float, spread: float, utilization: float) -> float:
        """Estimate fill probability from quote aggressiveness and balance sheet usage."""
        if spread <= 0:
            return 0.0
        normalized_distance = distance / spread
        base_probability = math.exp(-self.kappa * max(normalized_distance, 0.0))
        inventory_penalty = 1.0 - 0.35 * min(1.0, abs(utilization))
        return self._clamp(base_probability * inventory_penalty, 0.0, 1.0)

    def target_order_sizes(
        self, symbol: str, current_inventory: float, fill_probability: float
    ) -> tuple[float, float]:
        """Size quotes asymmetrically to reduce inventory risk while preserving presence."""
        utilization = self._clamp(current_inventory / self.max_inventory, -1.0, 1.0) if self.max_inventory else 0.0
        remaining_capacity = max(0.0, self.max_inventory - abs(current_inventory))
        base_size = max(self.max_inventory * 0.02, remaining_capacity * 0.12)
        participation = 0.5 + 0.5 * fill_probability
        bid_size = base_size * participation * (1.0 - max(0.0, utilization))
        ask_size = base_size * participation * (1.0 + min(0.0, utilization))
        if utilization > 0.75:
            bid_size *= 0.25
        elif utilization < -0.75:
            ask_size *= 0.25
        self.fill_stats.setdefault(symbol, {"posted": 0.0, "estimated_fills": 0.0})
        self.fill_stats[symbol]["posted"] += bid_size + ask_size
        self.fill_stats[symbol]["estimated_fills"] += (bid_size + ask_size) * fill_probability
        return max(0.0, bid_size), max(0.0, ask_size)

    def update_inventory(self, symbol: str, fill_size: float, side: str) -> float:
        """Update internal inventory after a fill event."""
        signed_fill = fill_size if side == "buy" else -fill_size
        self.inventory[symbol] = self.inventory.get(symbol, 0.0) + signed_fill
        return self.inventory[symbol]

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return inventory and adverse-selection risk metrics."""
        gross_inventory = sum(abs(value) for value in self.inventory.values())
        max_loss = gross_inventory * self.sigma * 3.0
        expected_drawdown = max_loss * 0.4
        utilization = gross_inventory / self.max_inventory if self.max_inventory else 0.0
        return {
            "symbols": len(self.inventory),
            "gross_inventory": gross_inventory,
            "inventory_utilization": utilization,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current market-making health and quote quality."""
        fill_ratio = 0.0
        posted = sum(stats["posted"] for stats in self.fill_stats.values())
        estimated = sum(stats["estimated_fills"] for stats in self.fill_stats.values())
        if posted > 0:
            fill_ratio = estimated / posted
        return {
            "healthy": fill_ratio >= 0.05 or not self.fill_stats,
            "inventory": self.inventory,
            "fill_ratio": fill_ratio,
            "last_metrics": self.last_metrics,
        }

    def generate_quotes(
        self,
        symbol: str,
        mid_price: float,
        current_inventory: float = 0.0,
        time_remaining: float = 1.0,
        volatility_override: float | None = None,
    ) -> Quote:
        """Generate bid/ask quotes with inventory skew."""
        sigma = volatility_override if volatility_override is not None else self.sigma
        self.sigma = max(sigma, 0.0001)
        inventory = current_inventory if current_inventory else self.inventory.get(symbol, 0.0)
        utilization = inventory / self.max_inventory if self.max_inventory else 0.0

        reservation = self.calculate_reservation_price(mid_price, inventory, time_remaining)
        optimal_spread = self.calculate_optimal_spread(time_remaining)
        stress_multiplier = 1.0 + abs(utilization) * 0.75 + self.sigma * 5.0
        quoted_spread = optimal_spread * stress_multiplier
        skew_signal = self.inventory_skew(inventory)
        skew = skew_signal * quoted_spread * 0.35

        bid_price = self._round_down(reservation - quoted_spread / 2 - skew)
        ask_price = self._round_up(reservation + quoted_spread / 2 - skew)
        if ask_price <= bid_price:
            ask_price = bid_price + self.tick_size

        half_spread = max((ask_price - bid_price) / 2, self.tick_size)
        fill_probability = self.estimate_fill_probability(abs(mid_price - reservation), half_spread, utilization)
        bid_size, ask_size = self.target_order_sizes(symbol, inventory, fill_probability)

        quote = Quote(
            symbol=symbol,
            bid_price=bid_price,
            ask_price=ask_price,
            bid_size=bid_size,
            ask_size=ask_size,
            spread=ask_price - bid_price,
            skew=skew,
        )
        self.quote_history.setdefault(symbol, []).append(quote)
        self.last_metrics = {
            "symbol": symbol,
            "reservation_price": reservation,
            "inventory": inventory,
            "utilization": utilization,
            "fill_probability": fill_probability,
            "quoted_spread": quote.spread,
        }
        return quote

    def should_cancel_quotes(self, inventory: float, volatility_spike: bool = False) -> bool:
        """Determine if quotes should be pulled (risk management)."""
        utilization = abs(inventory) / self.max_inventory if self.max_inventory else 0.0
        if utilization >= 0.9:
            return True
        if volatility_spike or self.sigma > 0.08:
            return True
        return False
