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
        """
        Args:
            base_spread_bps: Minimum spread in basis points
            gamma: Risk aversion parameter
            sigma: Volatility of the asset
            kappa: Order arrival rate parameter
            max_inventory: Maximum allowed inventory
            tick_size: Minimum price increment
        """
        self.base_spread_bps = base_spread_bps
        self.gamma = gamma
        self.sigma = sigma
        self.kappa = kappa
        self.max_inventory = max_inventory
        self.tick_size = tick_size
        self.inventory: dict[str, float] = {}

    def calculate_reservation_price(
        self, mid_price: float, inventory: float, time_remaining: float = 1.0
    ) -> float:
        """Calculate reservation (indifference) price based on inventory."""
        # Avellaneda-Stoikov reservation price
        return mid_price - inventory * self.gamma * self.sigma**2 * time_remaining

    def calculate_optimal_spread(self, time_remaining: float = 1.0) -> float:
        """Calculate optimal spread width."""
        spread = (
            self.gamma * self.sigma**2 * time_remaining
            + (2 / self.gamma) * math.log(1 + self.gamma / self.kappa)
        )
        return max(spread, self.base_spread_bps / 10000.0)

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
        self.sigma = sigma

        # Reservation price (skewed by inventory)
        reservation = self.calculate_reservation_price(mid_price, current_inventory, time_remaining)
        optimal_spread = self.calculate_optimal_spread(time_remaining)

        # Inventory skew — lean away from large positions
        inventory_ratio = current_inventory / self.max_inventory if self.max_inventory > 0 else 0
        skew = inventory_ratio * optimal_spread * 0.5

        bid_price = reservation - optimal_spread / 2 - skew
        ask_price = reservation + optimal_spread / 2 - skew

        # Round to tick size
        bid_price = math.floor(bid_price / self.tick_size) * self.tick_size
        ask_price = math.ceil(ask_price / self.tick_size) * self.tick_size

        # Size based on inventory capacity
        remaining_capacity = self.max_inventory - abs(current_inventory)
        base_size = remaining_capacity * 0.1

        # Reduce size on the side we're exposed to
        bid_size = base_size * (1 - max(0, inventory_ratio))
        ask_size = base_size * (1 + min(0, inventory_ratio))

        return Quote(
            symbol=symbol,
            bid_price=bid_price,
            ask_price=ask_price,
            bid_size=max(0, bid_size),
            ask_size=max(0, ask_size),
            spread=ask_price - bid_price,
            skew=skew,
        )

    def should_cancel_quotes(self, inventory: float, volatility_spike: bool = False) -> bool:
        """Determine if quotes should be pulled (risk management)."""
        if abs(inventory) >= self.max_inventory * 0.9:
            return True
        if volatility_spike:
            return True
        return False
