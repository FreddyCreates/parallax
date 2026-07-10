#!/usr/bin/env python3
"""PARALLAX SDK — market data aggregation primitives."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional


@dataclass(slots=True)
class TradeTick:
    timestamp_ns: int
    price: float
    size: float
    asset: str
    side: str = "buy"


@dataclass(slots=True)
class OHLCVBar:
    asset: str
    start_ns: int
    end_ns: int
    open: float
    high: float
    low: float
    close: float
    volume: float
    trade_count: int
    vwap: float


@dataclass(slots=True)
class VolumeProfileBucket:
    price_floor: float
    price_ceiling: float
    volume: float
    trades: int


@dataclass(slots=True)
class CrossAssetAggregate:
    timeframe_ns: int
    start_ns: int
    end_ns: int
    total_volume: float
    weighted_close: float
    asset_closes: dict[str, float] = field(default_factory=dict)


class OhlcvAggregator:
    """Generates OHLCV bars from trade ticks."""

    def generate(self, trades: list[TradeTick], *, interval_ns: int) -> list[OHLCVBar]:
        if interval_ns <= 0:
            raise ValueError("interval_ns must be positive")
        grouped: dict[tuple[str, int], list[TradeTick]] = defaultdict(list)
        for trade in sorted(trades, key=lambda item: item.timestamp_ns):
            bucket_start = (trade.timestamp_ns // interval_ns) * interval_ns
            grouped[(trade.asset, bucket_start)].append(trade)

        bars: list[OHLCVBar] = []
        for (asset, bucket_start), bucket_trades in sorted(grouped.items(), key=lambda item: item[0][1]):
            prices = [trade.price for trade in bucket_trades]
            volume = sum(trade.size for trade in bucket_trades)
            notional = sum(trade.price * trade.size for trade in bucket_trades)
            bars.append(
                OHLCVBar(
                    asset=asset,
                    start_ns=bucket_start,
                    end_ns=bucket_start + interval_ns,
                    open=prices[0],
                    high=max(prices),
                    low=min(prices),
                    close=prices[-1],
                    volume=volume,
                    trade_count=len(bucket_trades),
                    vwap=notional / volume if volume else prices[-1],
                )
            )
        return bars


class MultiTimeframeResampler:
    """Resamples existing bars into coarser timeframes."""

    def resample(self, bars: list[OHLCVBar], *, timeframe_ns: int) -> list[OHLCVBar]:
        grouped: dict[tuple[str, int], list[OHLCVBar]] = defaultdict(list)
        for bar in sorted(bars, key=lambda item: item.start_ns):
            bucket_start = (bar.start_ns // timeframe_ns) * timeframe_ns
            grouped[(bar.asset, bucket_start)].append(bar)

        output: list[OHLCVBar] = []
        for (asset, bucket_start), bucket in sorted(grouped.items(), key=lambda item: item[0][1]):
            output.append(
                OHLCVBar(
                    asset=asset,
                    start_ns=bucket_start,
                    end_ns=bucket_start + timeframe_ns,
                    open=bucket[0].open,
                    high=max(item.high for item in bucket),
                    low=min(item.low for item in bucket),
                    close=bucket[-1].close,
                    volume=sum(item.volume for item in bucket),
                    trade_count=sum(item.trade_count for item in bucket),
                    vwap=(
                        sum(item.vwap * item.volume for item in bucket) / sum(item.volume for item in bucket)
                        if sum(item.volume for item in bucket)
                        else bucket[-1].close
                    ),
                )
            )
        return output


class VolumeProfiler:
    """Builds price-bucket volume distributions."""

    def profile(self, trades: list[TradeTick], *, bucket_size: float) -> list[VolumeProfileBucket]:
        if bucket_size <= 0:
            raise ValueError("bucket_size must be positive")
        buckets: dict[float, VolumeProfileBucket] = {}
        for trade in trades:
            floor = int(trade.price / bucket_size) * bucket_size
            if floor not in buckets:
                buckets[floor] = VolumeProfileBucket(
                    price_floor=floor,
                    price_ceiling=floor + bucket_size,
                    volume=0.0,
                    trades=0,
                )
            bucket = buckets[floor]
            bucket.volume += trade.size
            bucket.trades += 1
        return [buckets[key] for key in sorted(buckets)]


class OrderBookAggregator:
    """Aggregates book depth into price increments."""

    def aggregate(
        self,
        levels: list[tuple[float, float]],
        *,
        price_increment: float,
        depth: Optional[int] = None,
        descending: bool = True,
    ) -> list[tuple[float, float]]:
        if price_increment <= 0:
            raise ValueError("price_increment must be positive")
        aggregated: dict[float, float] = defaultdict(float)
        for price, size in levels:
            bucket = int(price / price_increment) * price_increment
            aggregated[bucket] += size
        ordered = sorted(aggregated.items(), key=lambda item: item[0], reverse=descending)
        return ordered if depth is None else ordered[:depth]


class CrossAssetAggregator:
    """Combines bars from multiple assets into a unified portfolio view."""

    def aggregate(self, bars_by_asset: dict[str, list[OHLCVBar]], *, timeframe_ns: int) -> list[CrossAssetAggregate]:
        grouped: dict[int, list[OHLCVBar]] = defaultdict(list)
        for bars in bars_by_asset.values():
            for bar in bars:
                bucket_start = (bar.start_ns // timeframe_ns) * timeframe_ns
                grouped[bucket_start].append(bar)

        aggregates: list[CrossAssetAggregate] = []
        for bucket_start, bucket in sorted(grouped.items()):
            total_volume = sum(item.volume for item in bucket)
            weighted_close = (
                sum(item.close * item.volume for item in bucket) / total_volume
                if total_volume
                else 0.0
            )
            aggregates.append(
                CrossAssetAggregate(
                    timeframe_ns=timeframe_ns,
                    start_ns=bucket_start,
                    end_ns=bucket_start + timeframe_ns,
                    total_volume=total_volume,
                    weighted_close=weighted_close,
                    asset_closes={item.asset: item.close for item in bucket},
                )
            )
        return aggregates
