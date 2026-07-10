"""Base market data adapter interface."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, AsyncIterator


@dataclass
class OHLCV:
    """Standard OHLCV candle."""

    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: float
    symbol: str
    interval: str


@dataclass
class OrderBook:
    """Level 2 order book snapshot."""

    symbol: str
    timestamp: datetime
    bids: list[tuple[float, float]] = field(default_factory=list)
    asks: list[tuple[float, float]] = field(default_factory=list)

    @property
    def spread(self) -> float:
        if self.bids and self.asks:
            return self.asks[0][0] - self.bids[0][0]
        return 0.0

    @property
    def mid_price(self) -> float:
        if self.bids and self.asks:
            return (self.asks[0][0] + self.bids[0][0]) / 2.0
        return 0.0


@dataclass
class Trade:
    """Individual trade tick."""

    symbol: str
    price: float
    quantity: float
    side: str
    timestamp: datetime
    venue: str


class MarketDataAdapter(ABC):
    """Abstract market data adapter — implement per venue."""

    def __init__(self, venue_id: str):
        self.venue_id = venue_id
        self.connected = False
        self.subscriptions: set[str] = set()

    @abstractmethod
    async def connect(self) -> None:
        """Connect to the market data source."""
        ...

    @abstractmethod
    async def disconnect(self) -> None:
        """Disconnect from the market data source."""
        ...

    @abstractmethod
    async def subscribe(self, symbols: list[str]) -> None:
        """Subscribe to market data for symbols."""
        ...

    @abstractmethod
    async def get_candles(
        self, symbol: str, interval: str = "1m", limit: int = 100
    ) -> list[OHLCV]:
        """Get historical candles."""
        ...

    @abstractmethod
    async def get_orderbook(self, symbol: str, depth: int = 20) -> OrderBook:
        """Get current order book."""
        ...

    @abstractmethod
    async def stream_trades(self, symbol: str) -> AsyncIterator[Trade]:
        """Stream real-time trades."""
        ...

    def get_status(self) -> dict[str, Any]:
        return {
            "venue_id": self.venue_id,
            "connected": self.connected,
            "subscriptions": list(self.subscriptions),
        }
