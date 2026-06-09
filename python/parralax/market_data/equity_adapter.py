"""Equity market data adapter."""

from datetime import datetime, timezone
from typing import Any, AsyncIterator

import structlog

from .base import OHLCV, MarketDataAdapter, OrderBook, Trade

logger = structlog.get_logger()


class EquityMarketAdapter(MarketDataAdapter):
    """Market data adapter for equity markets (Alpaca, IBKR)."""

    def __init__(self, provider: str = "alpaca"):
        super().__init__(venue_id=provider)
        self.provider = provider
        self._client: Any = None

    async def connect(self) -> None:
        """Connect to equity data provider."""
        self.connected = True
        logger.info("Equity adapter connected", provider=self.provider)

    async def disconnect(self) -> None:
        self.connected = False

    async def subscribe(self, symbols: list[str]) -> None:
        self.subscriptions.update(symbols)

    async def get_candles(
        self, symbol: str, interval: str = "1m", limit: int = 100
    ) -> list[OHLCV]:
        """Fetch historical bars from equity provider."""
        # Implementation depends on provider API
        # Alpaca: GET /v2/stocks/{symbol}/bars
        logger.info("Fetching equity candles", symbol=symbol, interval=interval)
        return []

    async def get_orderbook(self, symbol: str, depth: int = 20) -> OrderBook:
        """Get L2 quotes from equity provider."""
        return OrderBook(
            symbol=symbol,
            timestamp=datetime.now(timezone.utc),
        )

    async def stream_trades(self, symbol: str) -> AsyncIterator[Trade]:
        """Stream equity trades — placeholder for WebSocket implementation."""
        # TODO: Implement via Alpaca/IBKR WebSocket stream
        if False:  # pragma: no cover
            yield Trade(
                symbol=symbol,
                price=0.0,
                quantity=0.0,
                side="buy",
                timestamp=datetime.now(timezone.utc),
                venue=self.provider,
            )
