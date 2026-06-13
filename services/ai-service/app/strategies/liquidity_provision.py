"""Liquidity Provision Strategy.

Provides liquidity in fragmented markets, earning rebates and spread.
"""

from __future__ import annotations

import math
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
        self.venue_profiles: dict[str, dict[str, float]] = {}
        self.last_state: dict[str, Any] = {}

    def register_venue(
        self,
        venue: str,
        maker_rebate_bps: float,
        taker_fee_bps: float,
        latency_ms: float = 1.0,
    ) -> None:
        """Register venue economics and execution characteristics."""
        self.venue_profiles[venue] = {
            "maker_rebate_bps": maker_rebate_bps,
            "taker_fee_bps": taker_fee_bps,
            "latency_ms": latency_ms,
            "posted_size": 0.0,
            "estimated_fill": 0.0,
        }

    def calculate_order_imbalance(self, bid_sizes: list[float], ask_sizes: list[float]) -> float:
        """Calculate order book imbalance."""
        total_bid = sum(bid_sizes) if bid_sizes else 0.0
        total_ask = sum(ask_sizes) if ask_sizes else 0.0
        total = total_bid + total_ask
        if total == 0:
            return 0.0
        return (total_bid - total_ask) / total

    def fill_rate_analysis(self, venue: str) -> float:
        """Estimate historical fill rate from posted versus executed liquidity."""
        profile = self.venue_profiles.get(venue)
        if not profile or profile["posted_size"] <= 0:
            return 0.0
        return profile["estimated_fill"] / profile["posted_size"]

    def estimate_edge_bps(
        self,
        bid_prices: list[float],
        ask_prices: list[float],
        imbalance: float,
        venue: str,
    ) -> float:
        """Estimate all-in edge combining spread capture, imbalance alpha, and rebates."""
        if not bid_prices or not ask_prices or bid_prices[0] <= 0:
            return 0.0
        spread_bps = (ask_prices[0] - bid_prices[0]) / bid_prices[0] * 10000
        profile = self.venue_profiles.get(venue, {"maker_rebate_bps": 0.0, "latency_ms": 1.0})
        rebate = profile["maker_rebate_bps"]
        latency_penalty = math.log1p(profile.get("latency_ms", 1.0)) * 0.3
        imbalance_edge = abs(imbalance) * spread_bps * 0.4
        return spread_bps * 0.5 + rebate + imbalance_edge - latency_penalty

    def select_best_venue(self, symbol: str, venue_books: list[dict[str, Any]]) -> str:
        """Select the best venue using edge, fill rate, and latency economics."""
        best_venue = ""
        best_score = float("-inf")
        for book in venue_books:
            venue = str(book.get("venue", ""))
            imbalance = self.calculate_order_imbalance(book.get("bid_sizes", []), book.get("ask_sizes", []))
            edge = self.estimate_edge_bps(book.get("bid_prices", []), book.get("ask_prices", []), imbalance, venue)
            fill_rate = self.fill_rate_analysis(venue)
            score = edge + fill_rate * 5.0
            if score > best_score:
                best_score = score
                best_venue = venue
        return best_venue or (venue_books[0]["venue"] if venue_books else "")

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return liquidity and execution risk metrics."""
        size = float(self.last_state.get("size", 0.0))
        edge = float(self.last_state.get("edge_bps", 0.0))
        max_loss = size * max(1.0, self.min_edge_bps - edge * 0.1)
        expected_drawdown = max_loss * 0.35
        return {
            "size": size,
            "edge_bps": edge,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return current venue health and liquidity state."""
        venue_health = {venue: self.fill_rate_analysis(venue) for venue in self.venue_profiles}
        return {
            "healthy": not venue_health or max(venue_health.values(), default=0.0) >= 0.02,
            "venue_health": venue_health,
            "last_state": self.last_state,
        }

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
        edge_bps = self.estimate_edge_bps(bid_prices, ask_prices, imbalance, venue)
        fill_rate = self.fill_rate_analysis(venue)

        if imbalance > self.imbalance_threshold:
            side = "sell"
            size = min(self.max_position * 0.12, ask_depth * (0.08 + fill_rate))
            urgency = "high" if imbalance > 0.5 else "medium"
        elif imbalance < -self.imbalance_threshold:
            side = "buy"
            size = min(self.max_position * 0.12, bid_depth * (0.08 + fill_rate))
            urgency = "high" if imbalance < -0.5 else "medium"
        else:
            side = "both"
            size = self.max_position * 0.05
            urgency = "low"

        if edge_bps < self.min_edge_bps:
            size *= 0.4
            urgency = "low"

        profile = self.venue_profiles.setdefault(
            venue,
            {"maker_rebate_bps": 0.0, "taker_fee_bps": 0.0, "latency_ms": 1.0, "posted_size": 0.0, "estimated_fill": 0.0},
        )
        profile["posted_size"] += size
        profile["estimated_fill"] += size * (0.1 + min(0.6, abs(imbalance)))

        self.last_state = {
            "symbol": symbol,
            "venue": venue,
            "edge_bps": edge_bps,
            "fill_rate": fill_rate,
            "size": size,
            "imbalance": imbalance,
        }
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
