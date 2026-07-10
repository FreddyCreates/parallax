"""Paper trading engine for strategy simulation and backtesting."""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid4

import structlog

logger = structlog.get_logger()


@dataclass
class Position:
    """Simulated position."""

    symbol: str
    side: str
    quantity: float
    entry_price: float
    current_price: float = 0.0
    unrealized_pnl: float = 0.0
    opened_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    @property
    def notional(self) -> float:
        return abs(self.quantity * self.current_price)

    def update_price(self, price: float) -> None:
        self.current_price = price
        if self.side == "buy":
            self.unrealized_pnl = (price - self.entry_price) * self.quantity
        else:
            self.unrealized_pnl = (self.entry_price - price) * self.quantity


@dataclass
class PaperFill:
    """Simulated fill."""

    id: UUID
    order_id: UUID
    symbol: str
    side: str
    price: float
    quantity: float
    fee: float
    timestamp: datetime
    latency_ms: float


class PaperTradingEngine:
    """Paper trading engine for simulation without real capital."""

    def __init__(self, initial_capital: float = 1_000_000.0):
        self.capital = initial_capital
        self.available_cash = initial_capital
        self.positions: dict[str, Position] = {}
        self.fills: list[PaperFill] = []
        self.orders: list[dict[str, Any]] = []
        self.daily_pnl: float = 0.0
        self.total_pnl: float = 0.0
        self.trade_count: int = 0

    def submit_order(
        self,
        symbol: str,
        side: str,
        quantity: float,
        price: float,
        order_type: str = "market",
        agent_id: str = "",
    ) -> PaperFill | None:
        """Submit and immediately fill a paper order."""
        order_id = uuid4()

        # Simulate slippage for market orders
        if order_type == "market":
            slippage = price * 0.0001  # 1 bps
            fill_price = price + slippage if side == "buy" else price - slippage
        else:
            fill_price = price

        # Check capital
        notional = fill_price * quantity
        fee = notional * 0.001  # 10 bps fee

        if side == "buy" and notional + fee > self.available_cash:
            logger.warning("Insufficient capital", required=notional, available=self.available_cash)
            return None

        # Execute fill
        fill = PaperFill(
            id=uuid4(),
            order_id=order_id,
            symbol=symbol,
            side=side,
            price=fill_price,
            quantity=quantity,
            fee=fee,
            timestamp=datetime.now(timezone.utc),
            latency_ms=0.5,
        )

        self._update_position(fill)
        self.fills.append(fill)
        self.trade_count += 1
        self.available_cash -= fee

        logger.info(
            "Paper fill executed",
            symbol=symbol,
            side=side,
            price=fill_price,
            qty=quantity,
            agent=agent_id,
        )

        return fill

    def _update_position(self, fill: PaperFill) -> None:
        """Update positions based on fill."""
        if fill.symbol in self.positions:
            pos = self.positions[fill.symbol]
            if pos.side == fill.side:
                # Add to position
                total_qty = pos.quantity + fill.quantity
                pos.entry_price = (
                    (pos.entry_price * pos.quantity + fill.price * fill.quantity) / total_qty
                )
                pos.quantity = total_qty
            else:
                # Reduce/close position
                if fill.quantity >= pos.quantity:
                    # Close position
                    realized = (fill.price - pos.entry_price) * pos.quantity
                    if pos.side == "sell":
                        realized = -realized
                    self.daily_pnl += realized
                    self.total_pnl += realized
                    self.available_cash += realized + pos.quantity * pos.entry_price

                    remaining = fill.quantity - pos.quantity
                    if remaining > 0:
                        self.positions[fill.symbol] = Position(
                            symbol=fill.symbol,
                            side=fill.side,
                            quantity=remaining,
                            entry_price=fill.price,
                            current_price=fill.price,
                        )
                    else:
                        del self.positions[fill.symbol]
                else:
                    pos.quantity -= fill.quantity
        else:
            # New position
            self.positions[fill.symbol] = Position(
                symbol=fill.symbol,
                side=fill.side,
                quantity=fill.quantity,
                entry_price=fill.price,
                current_price=fill.price,
            )
            if fill.side == "buy":
                self.available_cash -= fill.price * fill.quantity

    def update_prices(self, prices: dict[str, float]) -> None:
        """Update all position mark-to-market."""
        for symbol, price in prices.items():
            if symbol in self.positions:
                self.positions[symbol].update_price(price)

    def get_portfolio_state(self) -> dict[str, Any]:
        """Get current portfolio snapshot."""
        total_unrealized = sum(p.unrealized_pnl for p in self.positions.values())
        total_exposure = sum(p.notional for p in self.positions.values())

        return {
            "capital": self.capital,
            "available_cash": self.available_cash,
            "positions": [
                {
                    "symbol": p.symbol,
                    "side": p.side,
                    "quantity": p.quantity,
                    "entry_price": p.entry_price,
                    "current_price": p.current_price,
                    "unrealized_pnl": p.unrealized_pnl,
                    "notional": p.notional,
                }
                for p in self.positions.values()
            ],
            "total_unrealized_pnl": total_unrealized,
            "total_realized_pnl": self.total_pnl,
            "daily_pnl": self.daily_pnl,
            "total_exposure": total_exposure,
            "trade_count": self.trade_count,
        }

    def reset_daily(self) -> None:
        """Reset daily metrics."""
        self.daily_pnl = 0.0
