#!/usr/bin/env python3
"""PARALLAX SDK — production data ingestion primitives."""

from __future__ import annotations

import json
import time
import urllib.parse
import urllib.request
from collections import deque
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, Iterable, Optional


class DataKind(Enum):
    """Normalized market data event families."""

    PRICE = "price"
    TRADE = "trade"
    ORDER_BOOK = "order_book"
    HISTORICAL = "historical"
    EXTERNAL = "external"


@dataclass(slots=True)
class MarketEvent:
    """Canonical event emitted by the ingestion layer."""

    event_id: str
    source: str
    asset: str
    kind: DataKind
    timestamp_ns: int
    payload: dict[str, Any]
    sequence: Optional[int] = None
    ingest_time_ns: int = field(default_factory=time.time_ns)


@dataclass(slots=True)
class IngestionMetrics:
    events_seen: int = 0
    duplicates_dropped: int = 0
    validation_failures: int = 0
    last_event_ns: int = 0


class ExternalAPIClient:
    """Small standard-library HTTP client with retry/backoff support."""

    def __init__(
        self,
        base_url: str,
        *,
        default_headers: Optional[dict[str, str]] = None,
        timeout_s: float = 10.0,
        max_retries: int = 3,
        retry_backoff_s: float = 0.5,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.default_headers = default_headers or {}
        self.timeout_s = timeout_s
        self.max_retries = max_retries
        self.retry_backoff_s = retry_backoff_s

    def request(
        self,
        path: str,
        *,
        params: Optional[dict[str, Any]] = None,
        headers: Optional[dict[str, str]] = None,
        method: str = "GET",
        body: Optional[dict[str, Any]] = None,
    ) -> Any:
        query = urllib.parse.urlencode(params or {}, doseq=True)
        url = f"{self.base_url}/{path.lstrip('/')}"
        if query:
            url = f"{url}?{query}"

        merged_headers = {"Accept": "application/json", **self.default_headers, **(headers or {})}
        payload = None if body is None else json.dumps(body).encode("utf-8")
        if payload is not None:
            merged_headers.setdefault("Content-Type", "application/json")

        last_error: Optional[Exception] = None
        for attempt in range(self.max_retries + 1):
            request = urllib.request.Request(url, data=payload, headers=merged_headers, method=method)
            try:
                with urllib.request.urlopen(request, timeout=self.timeout_s) as response:
                    raw = response.read()
                    if not raw:
                        return None
                    if response.headers.get_content_type() == "application/json":
                        return json.loads(raw.decode("utf-8"))
                    return raw.decode("utf-8")
            except Exception as exc:  # pragma: no cover - network variability
                last_error = exc
                if attempt >= self.max_retries:
                    break
                time.sleep(self.retry_backoff_s * (attempt + 1))
        raise RuntimeError(f"External API request failed for {url}") from last_error


class _DeduplicationIndex:
    def __init__(self, max_entries: int = 50_000) -> None:
        self._order: deque[str] = deque()
        self._seen: set[str] = set()
        self._max_entries = max_entries

    def add(self, item_id: str) -> bool:
        if item_id in self._seen:
            return False
        self._seen.add(item_id)
        self._order.append(item_id)
        while len(self._order) > self._max_entries:
            evicted = self._order.popleft()
            self._seen.discard(evicted)
        return True


class RealTimePriceFeedHandler:
    """Handles normalized tick ingestion and listener fan-out."""

    def __init__(self, source: str, *, max_listeners: int = 32) -> None:
        self.source = source
        self.metrics = IngestionMetrics()
        self._listeners: list[Callable[[MarketEvent], None]] = []
        self._max_listeners = max_listeners

    def subscribe(self, listener: Callable[[MarketEvent], None]) -> None:
        if len(self._listeners) >= self._max_listeners:
            raise ValueError("listener capacity exceeded")
        self._listeners.append(listener)

    def ingest_tick(
        self,
        asset: str,
        *,
        bid: float,
        ask: float,
        last: float,
        volume: float = 0.0,
        timestamp_ns: Optional[int] = None,
        metadata: Optional[dict[str, Any]] = None,
    ) -> MarketEvent:
        if min(bid, ask, last) <= 0:
            self.metrics.validation_failures += 1
            raise ValueError("prices must be positive")
        if ask < bid:
            self.metrics.validation_failures += 1
            raise ValueError("ask must be greater than or equal to bid")

        event_ts = timestamp_ns or time.time_ns()
        event = MarketEvent(
            event_id=f"PX-{self.source}-{asset}-{event_ts}",
            source=self.source,
            asset=asset,
            kind=DataKind.PRICE,
            timestamp_ns=event_ts,
            payload={
                "bid": bid,
                "ask": ask,
                "last": last,
                "mid": (bid + ask) / 2.0,
                "spread": ask - bid,
                "volume": volume,
                **(metadata or {}),
            },
        )
        self.metrics.events_seen += 1
        self.metrics.last_event_ns = event_ts
        for listener in self._listeners:
            listener(event)
        return event


class HistoricalDataDownloader:
    """Downloads paginated historical datasets through an external API."""

    def __init__(self, client: ExternalAPIClient, *, page_size: int = 1_000) -> None:
        self.client = client
        self.page_size = page_size

    def download_range(
        self,
        path: str,
        *,
        asset: str,
        start_ns: int,
        end_ns: int,
        extra_params: Optional[dict[str, Any]] = None,
    ) -> list[MarketEvent]:
        if end_ns <= start_ns:
            raise ValueError("end_ns must be greater than start_ns")

        rows: list[dict[str, Any]] = []
        cursor: Optional[str] = None
        while True:
            payload = self.client.request(
                path,
                params={
                    "asset": asset,
                    "start_ns": start_ns,
                    "end_ns": end_ns,
                    "limit": self.page_size,
                    "cursor": cursor,
                    **(extra_params or {}),
                },
            )
            if isinstance(payload, dict):
                page_rows = payload.get("data", [])
                cursor = payload.get("next_cursor")
            elif isinstance(payload, list):
                page_rows = payload
                cursor = None
            else:
                raise ValueError("historical API must return a list or mapping")
            rows.extend(page_rows)
            if not cursor or not page_rows:
                break

        return [
            MarketEvent(
                event_id=str(row.get("event_id") or f"HIST-{asset}-{row['timestamp_ns']}"),
                source=str(row.get("source") or self.client.base_url),
                asset=asset,
                kind=DataKind.HISTORICAL,
                timestamp_ns=int(row["timestamp_ns"]),
                payload=dict(row),
                sequence=row.get("sequence"),
            )
            for row in rows
            if start_ns <= int(row["timestamp_ns"]) <= end_ns
        ]


class OrderBookStreamProcessor:
    """Maintains a live order book from snapshot and delta events."""

    def __init__(self, asset: str, *, depth: int = 50) -> None:
        self.asset = asset
        self.depth = depth
        self.metrics = IngestionMetrics()
        self._bids: dict[float, float] = {}
        self._asks: dict[float, float] = {}
        self._last_sequence: Optional[int] = None

    def apply_snapshot(
        self,
        bids: Iterable[tuple[float, float]],
        asks: Iterable[tuple[float, float]],
        *,
        sequence: int,
        timestamp_ns: Optional[int] = None,
    ) -> MarketEvent:
        self._bids = {float(price): float(size) for price, size in bids if size > 0}
        self._asks = {float(price): float(size) for price, size in asks if size > 0}
        self._last_sequence = sequence
        return self._build_event(sequence=sequence, timestamp_ns=timestamp_ns, snapshot=True)

    def apply_delta(
        self,
        *,
        bid_updates: Iterable[tuple[float, float]] = (),
        ask_updates: Iterable[tuple[float, float]] = (),
        sequence: int,
        timestamp_ns: Optional[int] = None,
    ) -> MarketEvent:
        if self._last_sequence is not None and sequence <= self._last_sequence:
            self.metrics.duplicates_dropped += 1
            raise ValueError("out-of-order order book delta")
        if self._last_sequence is not None and sequence != self._last_sequence + 1:
            self.metrics.validation_failures += 1
            raise ValueError("order book sequence gap detected")

        for price, size in bid_updates:
            self._apply_level(self._bids, float(price), float(size))
        for price, size in ask_updates:
            self._apply_level(self._asks, float(price), float(size))
        self._last_sequence = sequence
        return self._build_event(sequence=sequence, timestamp_ns=timestamp_ns, snapshot=False)

    def top_of_book(self) -> dict[str, Optional[tuple[float, float]]]:
        best_bid = max(self._bids.items(), default=None)
        best_ask = min(self._asks.items(), default=None)
        return {"bid": best_bid, "ask": best_ask}

    def _apply_level(self, book: dict[float, float], price: float, size: float) -> None:
        if size <= 0:
            book.pop(price, None)
        else:
            book[price] = size

    def _build_event(self, *, sequence: int, timestamp_ns: Optional[int], snapshot: bool) -> MarketEvent:
        ts = timestamp_ns or time.time_ns()
        event = MarketEvent(
            event_id=f"BOOK-{self.asset}-{sequence}",
            source="order-book-stream",
            asset=self.asset,
            kind=DataKind.ORDER_BOOK,
            timestamp_ns=ts,
            sequence=sequence,
            payload={
                "snapshot": snapshot,
                "bids": sorted(self._bids.items(), key=lambda level: level[0], reverse=True)[: self.depth],
                "asks": sorted(self._asks.items(), key=lambda level: level[0])[: self.depth],
                "top_of_book": self.top_of_book(),
            },
        )
        self.metrics.events_seen += 1
        self.metrics.last_event_ns = ts
        return event


class TradeDataCollector:
    """Collects normalized trades with duplicate suppression."""

    def __init__(self, source: str, *, max_cache_entries: int = 100_000) -> None:
        self.source = source
        self.metrics = IngestionMetrics()
        self._dedupe = _DeduplicationIndex(max_cache_entries)
        self._trades: deque[MarketEvent] = deque()

    def ingest_trade(
        self,
        trade_id: str,
        *,
        asset: str,
        price: float,
        size: float,
        side: str,
        timestamp_ns: Optional[int] = None,
        metadata: Optional[dict[str, Any]] = None,
    ) -> Optional[MarketEvent]:
        if price <= 0 or size <= 0:
            self.metrics.validation_failures += 1
            raise ValueError("trade price and size must be positive")
        if side not in {"buy", "sell"}:
            self.metrics.validation_failures += 1
            raise ValueError("trade side must be 'buy' or 'sell'")
        if not self._dedupe.add(trade_id):
            self.metrics.duplicates_dropped += 1
            return None

        ts = timestamp_ns or time.time_ns()
        event = MarketEvent(
            event_id=trade_id,
            source=self.source,
            asset=asset,
            kind=DataKind.TRADE,
            timestamp_ns=ts,
            payload={"price": price, "size": size, "side": side, **(metadata or {})},
        )
        self._trades.append(event)
        self.metrics.events_seen += 1
        self.metrics.last_event_ns = ts
        return event

    def recent_trades(self, limit: int = 100) -> list[MarketEvent]:
        return list(self._trades)[-limit:]


class DataIngestionOrchestrator:
    """Coordinates price, trade, order book, and external ingestion flows."""

    def __init__(self) -> None:
        self.price_feeds: dict[str, RealTimePriceFeedHandler] = {}
        self.trade_collectors: dict[str, TradeDataCollector] = {}
        self.order_books: dict[str, OrderBookStreamProcessor] = {}

    def register_price_feed(self, name: str, handler: RealTimePriceFeedHandler) -> None:
        self.price_feeds[name] = handler

    def register_trade_collector(self, name: str, collector: TradeDataCollector) -> None:
        self.trade_collectors[name] = collector

    def register_order_book(self, asset: str, stream: OrderBookStreamProcessor) -> None:
        self.order_books[asset] = stream

    def metrics(self) -> dict[str, dict[str, int]]:
        return {
            "price_feeds": {name: handler.metrics.events_seen for name, handler in self.price_feeds.items()},
            "trade_collectors": {name: collector.metrics.events_seen for name, collector in self.trade_collectors.items()},
            "order_books": {asset: stream.metrics.events_seen for asset, stream in self.order_books.items()},
        }
