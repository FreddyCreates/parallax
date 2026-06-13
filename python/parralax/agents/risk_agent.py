"""Risk management agent — validates orders and monitors exposure."""

from typing import Any

from .base import AgentCapital, AgentRole, BaseAgent


class RiskAgent(BaseAgent):
    """Agent responsible for risk validation and monitoring."""

    def __init__(self, name: str, limits: AgentCapital | None = None):
        super().__init__(name=name, role=AgentRole.GOVERNOR, capital=limits)
        self.blocked_orders: list[dict[str, Any]] = []
        self.risk_events: list[dict[str, Any]] = []

    async def tick(self, market_state: dict[str, Any]) -> list[dict[str, Any]]:
        """Monitor portfolio risk metrics."""
        actions: list[dict[str, Any]] = []

        portfolio = market_state.get("portfolio", {})
        total_exposure = sum(
            abs(pos.get("notional", 0)) for pos in portfolio.get("positions", [])
        )

        # Check total exposure
        if total_exposure > self.capital.max_notional * 0.9:
            actions.append({
                "type": "risk_alert",
                "level": "warning",
                "message": f"Exposure at {total_exposure / self.capital.max_notional:.1%} of limit",
                "agent_id": str(self.id),
            })

        # Check daily PnL
        daily_pnl = portfolio.get("daily_pnl", 0)
        if daily_pnl < -self.capital.max_daily_loss * 0.8:
            actions.append({
                "type": "risk_alert",
                "level": "critical",
                "message": f"Daily PnL at {daily_pnl:.2f}, approaching limit",
                "agent_id": str(self.id),
                "action": "reduce_exposure",
            })

        return actions

    async def on_fill(self, fill: dict[str, Any]) -> None:
        """Update exposure tracking on fill."""
        self.capital.current_exposure += abs(fill.get("notional", 0))
        self.memory.record_trade(fill)

    def validate_order(self, order: dict[str, Any]) -> tuple[bool, str]:
        """Validate an order against risk limits."""
        size = order.get("notional", 0)

        # Position size check
        if abs(size) > self.capital.max_position_size:
            reason = f"Order size {size} exceeds max position {self.capital.max_position_size}"
            self.blocked_orders.append({**order, "block_reason": reason})
            return False, reason

        # Exposure check
        if self.capital.current_exposure + abs(size) > self.capital.max_notional:
            reason = "Would exceed max notional exposure"
            self.blocked_orders.append({**order, "block_reason": reason})
            return False, reason

        # Daily loss check
        if self.capital.daily_pnl < -self.capital.max_daily_loss:
            reason = "Daily loss limit already breached"
            self.blocked_orders.append({**order, "block_reason": reason})
            return False, reason

        return True, "approved"

    def get_risk_report(self) -> dict[str, Any]:
        """Generate current risk report."""
        return {
            "agent_id": str(self.id),
            "current_exposure": self.capital.current_exposure,
            "max_notional": self.capital.max_notional,
            "utilization": self.capital.current_exposure / self.capital.max_notional
            if self.capital.max_notional > 0
            else 0,
            "daily_pnl": self.capital.daily_pnl,
            "max_daily_loss": self.capital.max_daily_loss,
            "blocked_orders_count": len(self.blocked_orders),
            "kill_switch": self.kill_switch,
        }
