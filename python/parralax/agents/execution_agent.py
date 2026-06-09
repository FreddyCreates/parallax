"""Execution agent — routes approved orders to venues."""

from typing import Any

from .base import AgentRole, BaseAgent


class ExecutionAgent(BaseAgent):
    """Agent responsible for order execution and venue routing."""

    def __init__(self, name: str, venues: list[str] | None = None):
        super().__init__(name=name, role=AgentRole.EXECUTOR)
        self.venues = venues or ["alpaca", "binance", "interactive_brokers"]
        self.pending_orders: list[dict[str, Any]] = []
        self.execution_log: list[dict[str, Any]] = []

    async def tick(self, market_state: dict[str, Any]) -> list[dict[str, Any]]:
        """Process pending orders and route to venues."""
        actions: list[dict[str, Any]] = []

        for order in self.pending_orders[:]:
            venue = self._select_venue(order)
            actions.append({
                "type": "route_order",
                "order": order,
                "venue": venue,
                "agent_id": str(self.id),
            })
            self.pending_orders.remove(order)

        return actions

    async def on_fill(self, fill: dict[str, Any]) -> None:
        """Record execution result."""
        self.execution_log.append(fill)
        self.memory.record_trade(fill)
        self.capital.current_exposure += abs(fill.get("notional", 0))

    def queue_order(self, order: dict[str, Any]) -> None:
        """Add order to execution queue."""
        self.pending_orders.append(order)

    def _select_venue(self, order: dict[str, Any]) -> str:
        """Select best venue for order based on asset class and liquidity."""
        asset_class = order.get("asset_class", "crypto")

        venue_map = {
            "equity": "interactive_brokers",
            "crypto": "binance",
            "forex": "interactive_brokers",
            "token": "binance",
        }

        preferred = venue_map.get(asset_class, self.venues[0])
        return preferred if preferred in self.venues else self.venues[0]

    def get_execution_stats(self) -> dict[str, Any]:
        """Get execution statistics."""
        total = len(self.execution_log)
        return {
            "total_executions": total,
            "pending_orders": len(self.pending_orders),
            "venues": self.venues,
            "avg_latency_ms": (
                sum(f.get("latency_ms", 0) for f in self.execution_log) / total
                if total > 0
                else 0
            ),
        }
