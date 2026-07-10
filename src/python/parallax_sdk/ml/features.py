"""Feature engineering for PARALLAX market intelligence models."""

from __future__ import annotations

import math
import statistics
from dataclasses import dataclass, field


@dataclass(slots=True)
class PricePoint:
    timestamp_ms: int
    close: float
    volume: float = 0.0


@dataclass(slots=True)
class OrderBookLevel:
    price: float
    size: float


@dataclass(slots=True)
class OrderBookSnapshot:
    bids: list[OrderBookLevel]
    asks: list[OrderBookLevel]


@dataclass(slots=True)
class CrossAssetSnapshot:
    symbol: str
    close_prices: list[float]


@dataclass(slots=True)
class MarketSample:
    symbol: str
    price_history: list[PricePoint]
    order_book: OrderBookSnapshot
    peers: list[CrossAssetSnapshot] = field(default_factory=list)
    headline_text: str = ""


@dataclass(slots=True)
class EngineeredFeatures:
    symbol: str
    values: dict[str, float]

    def to_dict(self) -> dict[str, float]:
        return dict(self.values)


POSITIVE_WORDS = {
    "beat", "bull", "growth", "gain", "upgrade", "surge", "strong", "alpha", "outperform"
}
NEGATIVE_WORDS = {
    "bear", "drop", "loss", "downgrade", "weak", "selloff", "panic", "fraud", "stress"
}


def _closes(points: list[PricePoint]) -> list[float]:
    return [point.close for point in points]


def _pct_return(current: float, anchor: float) -> float:
    if anchor == 0.0:
        return 0.0
    return (current - anchor) / anchor


def _safe_mean(values: list[float]) -> float:
    return statistics.fmean(values) if values else 0.0


def _safe_std(values: list[float]) -> float:
    if len(values) < 2:
        return 0.0
    return statistics.pstdev(values)


def _lag_return(values: list[float], lag: int) -> float:
    if len(values) <= lag:
        return 0.0
    return _pct_return(values[-1], values[-1 - lag])


def compute_price_features(price_history: list[PricePoint]) -> dict[str, float]:
    closes = _closes(price_history)
    if not closes:
        return {
            "returns": 0.0,
            "volatility": 0.0,
            "momentum": 0.0,
            "rolling_mean": 0.0,
            "rolling_std": 0.0,
            "volume_trend": 0.0,
        }
    volumes = [point.volume for point in price_history]
    current = closes[-1]
    previous = closes[-2] if len(closes) > 1 else current
    volume_avg = _safe_mean(volumes)
    return {
        "returns": _pct_return(current, previous),
        "volatility": _safe_std(closes),
        "momentum": _lag_return(closes, min(5, max(1, len(closes) - 1))),
        "rolling_mean": _safe_mean(closes[-20:]),
        "rolling_std": _safe_std(closes[-20:]),
        "volume_trend": _pct_return(volumes[-1], volume_avg) if volumes and volume_avg else 0.0,
    }


def compute_order_book_features(order_book: OrderBookSnapshot) -> dict[str, float]:
    best_bid = order_book.bids[0].price if order_book.bids else 0.0
    best_ask = order_book.asks[0].price if order_book.asks else 0.0
    bid_depth = sum(level.size for level in order_book.bids)
    ask_depth = sum(level.size for level in order_book.asks)
    total_depth = bid_depth + ask_depth
    spread = max(0.0, best_ask - best_bid) if best_bid and best_ask else 0.0
    imbalance = (bid_depth - ask_depth) / total_depth if total_depth else 0.0
    return {
        "spread": spread,
        "bid_depth": bid_depth,
        "ask_depth": ask_depth,
        "imbalance": imbalance,
        "depth_ratio": bid_depth / ask_depth if ask_depth else 0.0,
    }


def compute_time_series_features(price_history: list[PricePoint]) -> dict[str, float]:
    closes = _closes(price_history)
    if not closes:
        return {"lag_1": 0.0, "lag_5": 0.0, "lag_20": 0.0, "zscore": 0.0}
    rolling_mean = _safe_mean(closes[-20:])
    rolling_std = _safe_std(closes[-20:])
    current = closes[-1]
    return {
        "lag_1": _lag_return(closes, 1),
        "lag_5": _lag_return(closes, 5),
        "lag_20": _lag_return(closes, 20),
        "zscore": (current - rolling_mean) / rolling_std if rolling_std else 0.0,
    }


def compute_cross_asset_features(symbol: str, price_history: list[PricePoint], peers: list[CrossAssetSnapshot]) -> dict[str, float]:
    closes = _closes(price_history)
    current = closes[-1] if closes else 0.0
    if not peers or not closes:
        return {"peer_correlation": 0.0, "price_ratio": 0.0, "relative_strength": 0.0}
    primary_mean = _safe_mean(closes)
    primary_std = _safe_std(closes)
    correlations: list[float] = []
    ratios: list[float] = []
    strengths: list[float] = []
    for peer in peers:
        if not peer.close_prices:
            continue
        peer_prices = peer.close_prices[-len(closes):]
        peer_mean = _safe_mean(peer_prices)
        peer_std = _safe_std(peer_prices)
        peer_last = peer_prices[-1]
        if peer_last:
            ratios.append(current / peer_last)
        strengths.append(_pct_return(current, primary_mean) - _pct_return(peer_last, peer_mean) if peer_mean else 0.0)
        if primary_std and peer_std:
            numerator = (current - primary_mean) * (peer_last - peer_mean)
            correlations.append(numerator / (primary_std * peer_std))
    return {
        "peer_correlation": _safe_mean(correlations),
        "price_ratio": _safe_mean(ratios),
        "relative_strength": _safe_mean(strengths),
    }


def compute_sentiment_signal(headline_text: str) -> dict[str, float]:
    tokens = [token.strip(".,:;!?()[]{}\"'").lower() for token in headline_text.split()]
    if not tokens:
        return {"sentiment_score": 0.0, "headline_intensity": 0.0}
    positive = sum(token in POSITIVE_WORDS for token in tokens)
    negative = sum(token in NEGATIVE_WORDS for token in tokens)
    score = (positive - negative) / max(1, len(tokens))
    intensity = math.tanh((positive + negative) / max(1, len(tokens)))
    return {"sentiment_score": score, "headline_intensity": intensity}


def engineer_features(sample: MarketSample) -> EngineeredFeatures:
    values: dict[str, float] = {}
    values.update(compute_price_features(sample.price_history))
    values.update(compute_order_book_features(sample.order_book))
    values.update(compute_time_series_features(sample.price_history))
    values.update(compute_cross_asset_features(sample.symbol, sample.price_history, sample.peers))
    values.update(compute_sentiment_signal(sample.headline_text))
    return EngineeredFeatures(symbol=sample.symbol, values=values)


def batch_engineer_features(samples: list[MarketSample]) -> list[EngineeredFeatures]:
    return [engineer_features(sample) for sample in samples]
