"""Execution Orchestrator — Routes signals to execution venues.

Manages order lifecycle from signal generation through fill confirmation,
with smart order routing across multiple venues.
"""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class Venue(str, Enum):
    BINANCE = "binance"
    COINBASE = "coinbase"
    KRAKEN = "kraken"
    NYSE = "nyse"
    NASDAQ = "nasdaq"
    CME = "cme"
    DARK_POOL = "dark_pool"
    INTERNAL = "internal"


class OrderState(str, Enum):
    PENDING = "pending"
    ROUTED = "routed"
    PARTIAL_FILL = "partial_fill"
    FILLED = "filled"
    CANCELLED = "cancelled"
    REJECTED = "rejected"


class ExecutionAlgo(str, Enum):
    MARKET = "market"
    LIMIT = "limit"
    TWAP = "twap"
    VWAP = "vwap"
    ICEBERG = "iceberg"
    SNIPER = "sniper"
    POV = "pov"  # Percentage of Volume


@dataclass
class ExecutionOrder:
    order_id: str
    symbol: str
    side: str
    quantity: float
    algo: ExecutionAlgo
    venue: Venue
    state: OrderState = OrderState.PENDING
    price_limit: float | None = None
    filled_qty: float = 0.0
    avg_fill_price: float = 0.0
    slippage_bps: float = 0.0
    created_at: float = 0.0
    filled_at: float = 0.0

    def __post_init__(self) -> None:
        if not self.created_at:
            self.created_at = time.time()


class ExecutionOrchestrator:
    """Smart order routing and execution management."""

    def __init__(self) -> None:
        self.orders: dict[str, ExecutionOrder] = {}
        self.venue_stats: dict[Venue, dict[str, float]] = {
            v: {"fill_rate": 0.95, "avg_latency_ms": 5.0, "avg_slippage_bps": 1.0}
            for v in Venue
        }

    def select_venue(
        self,
        symbol: str,
        side: str,
        quantity: float,
        urgency: str = "normal",
    ) -> Venue:
        """Select optimal execution venue based on historical performance."""
        # For large orders, prefer dark pools
        if quantity > 10000 and urgency != "high":
            return Venue.DARK_POOL

        # Select venue with best fill rate and lowest slippage
        best_venue = Venue.INTERNAL
        best_score = 0.0

        for venue, stats in self.venue_stats.items():
            score = stats["fill_rate"] * 100 - stats["avg_slippage_bps"]
            if urgency == "high":
                score -= stats["avg_latency_ms"] * 0.1
            if score > best_score:
                best_score = score
                best_venue = venue

        return best_venue

    def select_algo(
        self,
        quantity: float,
        urgency: str = "normal",
        market_impact_concern: bool = True,
    ) -> ExecutionAlgo:
        """Select execution algorithm based on order characteristics."""
        if urgency == "high":
            return ExecutionAlgo.MARKET
        if quantity > 50000 and market_impact_concern:
            return ExecutionAlgo.ICEBERG
        if quantity > 10000:
            return ExecutionAlgo.TWAP
        return ExecutionAlgo.LIMIT

    def submit_order(
        self,
        symbol: str,
        side: str,
        quantity: float,
        price_limit: float | None = None,
        urgency: str = "normal",
    ) -> ExecutionOrder:
        """Submit order with smart routing."""
        venue = self.select_venue(symbol, side, quantity, urgency)
        algo = self.select_algo(quantity, urgency)

        order = ExecutionOrder(
            order_id=f"EXE-{uuid.uuid4().hex[:12].upper()}",
            symbol=symbol,
            side=side,
            quantity=quantity,
            algo=algo,
            venue=venue,
            price_limit=price_limit,
            state=OrderState.ROUTED,
        )

        self.orders[order.order_id] = order
        return order

    def get_execution_report(self) -> dict[str, Any]:
        """Get execution performance report."""
        total_orders = len(self.orders)
        filled = sum(1 for o in self.orders.values() if o.state == OrderState.FILLED)
        avg_slippage = (
            sum(o.slippage_bps for o in self.orders.values() if o.state == OrderState.FILLED)
            / max(1, filled)
        )

        return {
            "total_orders": total_orders,
            "filled": filled,
            "fill_rate": filled / max(1, total_orders),
            "avg_slippage_bps": avg_slippage,
            "by_venue": {
                v.value: sum(1 for o in self.orders.values() if o.venue == v)
                for v in Venue
            },
            "by_algo": {
                a.value: sum(1 for o in self.orders.values() if o.algo == a)
                for a in ExecutionAlgo
            },
        }
