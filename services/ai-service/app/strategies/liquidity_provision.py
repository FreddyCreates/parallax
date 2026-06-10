"""Liquidity Provision Strategy.

Provides liquidity in fragmented markets, earning rebates and spread.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass
class LiquiditySignal:
    symbol: str
    venue: str
    bid_depth: float
    ask_depth: float
    imbalance: float
    recommended_side: str
    size: float
    urgency: str


class LiquidityProvisionStrategy:
    """Smart liquidity provision across venues."""

    def __init__(
        self,
        max_position: float = 1000.0,
        imbalance_threshold: float = 0.3,
        min_edge_bps: float = 1.0,
    ) -> None:
        self.max_position = max_position
        self.imbalance_threshold = imbalance_threshold
        self.min_edge_bps = min_edge_bps

    def calculate_order_imbalance(self, bid_sizes: list[float], ask_sizes: list[float]) -> float:
        """Calculate order book imbalance."""
        total_bid = sum(bid_sizes) if bid_sizes else 0
        total_ask = sum(ask_sizes) if ask_sizes else 0
        total = total_bid + total_ask
        if total == 0:
            return 0.0
        return (total_bid - total_ask) / total

    def generate_signal(
        self,
        symbol: str,
        venue: str,
        bid_prices: list[float],
        ask_prices: list[float],
        bid_sizes: list[float],
        ask_sizes: list[float],
    ) -> LiquiditySignal:
        """Generate liquidity provision signal."""
        imbalance = self.calculate_order_imbalance(bid_sizes, ask_sizes)
        bid_depth = sum(bid_sizes)
        ask_depth = sum(ask_sizes)

        # Provide liquidity on thin side
        if imbalance > self.imbalance_threshold:
            side = "sell"  # Bid-heavy → provide asks
            size = min(self.max_position * 0.1, ask_depth * 0.05)
            urgency = "high" if imbalance > 0.5 else "medium"
        elif imbalance < -self.imbalance_threshold:
            side = "buy"   # Ask-heavy → provide bids
            size = min(self.max_position * 0.1, bid_depth * 0.05)
            urgency = "high" if imbalance < -0.5 else "medium"
        else:
            side = "both"
            size = self.max_position * 0.05
            urgency = "low"

        return LiquiditySignal(
            symbol=symbol,
            venue=venue,
            bid_depth=bid_depth,
            ask_depth=ask_depth,
            imbalance=imbalance,
            recommended_side=side,
            size=size,
            urgency=urgency,
        )
