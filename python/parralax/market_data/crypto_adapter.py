"""Crypto market data adapter using CCXT."""

from datetime import datetime, timezone
from typing import Any, AsyncIterator

import structlog

from .base import OHLCV, MarketDataAdapter, OrderBook, Trade

logger = structlog.get_logger()


class CryptoMarketAdapter(MarketDataAdapter):
    """Market data adapter for crypto exchanges via CCXT."""

    def __init__(self, exchange_id: str = "binance"):
        super().__init__(venue_id=exchange_id)
        self.exchange_id = exchange_id
        self._exchange: Any = None

    async def connect(self) -> None:
        """Initialize CCXT exchange connection."""
        try:
            import ccxt.async_support as ccxt_async

            exchange_class = getattr(ccxt_async, self.exchange_id)
            self._exchange = exchange_class({"enableRateLimit": True})
            await self._exchange.load_markets()
            self.connected = True
            logger.info("Connected to crypto exchange", exchange=self.exchange_id)
        except Exception as e:
            logger.error("Failed to connect", exchange=self.exchange_id, error=str(e))
            raise

    async def disconnect(self) -> None:
        if self._exchange:
            await self._exchange.close()
            self.connected = False

    async def subscribe(self, symbols: list[str]) -> None:
        self.subscriptions.update(symbols)

    async def get_candles(
        self, symbol: str, interval: str = "1m", limit: int = 100
    ) -> list[OHLCV]:
        if not self._exchange:
            raise RuntimeError("Not connected")

        raw = await self._exchange.fetch_ohlcv(symbol, interval, limit=limit)
        return [
            OHLCV(
                timestamp=datetime.fromtimestamp(c[0] / 1000, tz=timezone.utc),
                open=c[1],
                high=c[2],
                low=c[3],
                close=c[4],
                volume=c[5],
                symbol=symbol,
                interval=interval,
            )
            for c in raw
        ]

    async def get_orderbook(self, symbol: str, depth: int = 20) -> OrderBook:
        if not self._exchange:
            raise RuntimeError("Not connected")

        raw = await self._exchange.fetch_order_book(symbol, limit=depth)
        return OrderBook(
            symbol=symbol,
            timestamp=datetime.now(timezone.utc),
            bids=[(b[0], b[1]) for b in raw["bids"][:depth]],
            asks=[(a[0], a[1]) for a in raw["asks"][:depth]],
        )

    async def stream_trades(self, symbol: str) -> AsyncIterator[Trade]:
        """Stream trades via polling (upgrade to WebSocket for production HFT)."""
        if not self._exchange:
            raise RuntimeError("Not connected")

        while True:
            trades = await self._exchange.fetch_trades(symbol, limit=50)
            for t in trades:
                yield Trade(
                    symbol=symbol,
                    price=t["price"],
                    quantity=t["amount"],
                    side=t["side"],
                    timestamp=datetime.fromtimestamp(t["timestamp"] / 1000, tz=timezone.utc),
                    venue=self.exchange_id,
                )
