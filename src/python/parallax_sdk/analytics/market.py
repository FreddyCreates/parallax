from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class MarketStatistics:
    total_volume: float
    total_notional: float
    vwap: float
    average_trade_size: float
    turnover_ratio: float
    free_float_turnover: float
    realized_volatility: float
    trade_count: int


@dataclass(slots=True)
class MarketQualityMetrics:
    quoted_spread_bps: float
    effective_spread_bps: float
    realized_spread_bps: float
    price_impact_bps: float
    trade_to_quote_ratio: float
    midpoint_volatility: float


@dataclass(slots=True)
class LiquidityMetrics:
    amihud_illiquidity: float
    kyle_lambda: float
    average_daily_volume: float
    turnover_velocity: float
    order_book_depth: float
    liquidity_score: float


@dataclass(slots=True)
class OrderBookAnalytics:
    best_bid: float
    best_ask: float
    mid_price: float
    spread: float
    spread_bps: float
    bid_depth: float
    ask_depth: float
    imbalance: float
    weighted_mid_price: float
    depth_by_level: pd.DataFrame


@dataclass(slots=True)
class TradeFlowAnalysis:
    buy_volume: float
    sell_volume: float
    signed_volume: float
    volume_imbalance: float
    buy_ratio: float
    sell_ratio: float
    order_flow_autocorrelation: float
    vpin_proxy: float
    interval_flow: pd.DataFrame


@dataclass(slots=True)
class MarketAnalyticsReport:
    statistics: MarketStatistics
    quality: MarketQualityMetrics | None
    liquidity: LiquidityMetrics
    order_book: OrderBookAnalytics | None
    trade_flow: TradeFlowAnalysis


class MarketAnalytics:
    """Market microstructure, liquidity, and trading-flow analytics."""

    def __init__(
        self,
        trades: pd.DataFrame,
        quotes: pd.DataFrame | None = None,
        order_book: pd.DataFrame | dict[str, list[tuple[float, float]]] | None = None,
        periods_per_year: int = 252,
    ) -> None:
        self.trades = self._prepare_trades(trades)
        self.quotes = None if quotes is None else self._prepare_quotes(quotes)
        self.order_book = order_book
        self.periods_per_year = int(periods_per_year)

    @staticmethod
    def _prepare_trades(trades: pd.DataFrame) -> pd.DataFrame:
        frame = trades.copy()
        if "timestamp" in frame.columns:
            frame["timestamp"] = pd.to_datetime(frame["timestamp"])
            frame = frame.sort_values("timestamp").set_index("timestamp")
        frame.index = pd.to_datetime(frame.index)
        if "size" not in frame.columns or "price" not in frame.columns:
            raise ValueError("trades must contain price and size columns")
        frame["price"] = frame["price"].astype(float)
        frame["size"] = frame["size"].astype(float)
        if "side" not in frame.columns:
            frame["side"] = np.where(frame.get("signed_size", 0.0) >= 0, "buy", "sell")
        frame["notional"] = frame["price"] * frame["size"]
        frame["signed_size"] = np.where(frame["side"].astype(str).str.lower().eq("buy"), frame["size"], -frame["size"])
        return frame.sort_index()

    @staticmethod
    def _prepare_quotes(quotes: pd.DataFrame) -> pd.DataFrame:
        frame = quotes.copy()
        if "timestamp" in frame.columns:
            frame["timestamp"] = pd.to_datetime(frame["timestamp"])
            frame = frame.sort_values("timestamp").set_index("timestamp")
        frame.index = pd.to_datetime(frame.index)
        required = {"bid", "ask"}
        if not required.issubset(frame.columns):
            raise ValueError("quotes must contain bid and ask columns")
        frame[["bid", "ask"]] = frame[["bid", "ask"]].astype(float)
        frame["mid"] = (frame["bid"] + frame["ask"]) / 2.0
        return frame.sort_index()

    def market_statistics(self, shares_outstanding: float | None = None, free_float_shares: float | None = None) -> MarketStatistics:
        trades = self.trades
        returns = trades["price"].resample("1D").last().pct_change().dropna()
        total_volume = float(trades["size"].sum())
        total_notional = float(trades["notional"].sum())
        turnover_ratio = total_volume / shares_outstanding if shares_outstanding else 0.0
        free_float_turnover = total_volume / free_float_shares if free_float_shares else 0.0
        return MarketStatistics(
            total_volume=total_volume,
            total_notional=total_notional,
            vwap=float(total_notional / total_volume) if total_volume else 0.0,
            average_trade_size=float(trades["size"].mean()) if not trades.empty else 0.0,
            turnover_ratio=float(turnover_ratio),
            free_float_turnover=float(free_float_turnover),
            realized_volatility=float(returns.std(ddof=0) * np.sqrt(self.periods_per_year)) if not returns.empty else 0.0,
            trade_count=int(len(trades)),
        )

    def market_quality_metrics(self) -> MarketQualityMetrics | None:
        if self.quotes is None:
            return None
        aligned = pd.merge_asof(
            self.trades.reset_index().sort_values("timestamp"),
            self.quotes.reset_index().sort_values("timestamp"),
            on="timestamp",
            direction="backward",
        ).dropna(subset=["bid", "ask", "mid"])
        if aligned.empty:
            return None
        aligned["quoted_spread_bps"] = (aligned["ask"] - aligned["bid"]) / aligned["mid"] * 10_000.0
        aligned["effective_spread_bps"] = (2.0 * (aligned["price"] - aligned["mid"]).abs() / aligned["mid"]) * 10_000.0
        future_mid = aligned["mid"].shift(-1).fillna(aligned["mid"])
        aligned["realized_spread_bps"] = (2.0 * (aligned["price"] - future_mid).abs() / aligned["mid"]) * 10_000.0
        aligned["price_impact_bps"] = ((future_mid - aligned["mid"]).abs() / aligned["mid"]) * 10_000.0
        midpoint_returns = pd.Series(aligned["mid"].to_numpy(), index=pd.to_datetime(aligned["timestamp"])).pct_change().dropna()
        return MarketQualityMetrics(
            quoted_spread_bps=float(aligned["quoted_spread_bps"].mean()),
            effective_spread_bps=float(aligned["effective_spread_bps"].mean()),
            realized_spread_bps=float(aligned["realized_spread_bps"].mean()),
            price_impact_bps=float(aligned["price_impact_bps"].mean()),
            trade_to_quote_ratio=float(len(self.trades) / max(len(self.quotes), 1)),
            midpoint_volatility=float(midpoint_returns.std(ddof=0) * np.sqrt(self.periods_per_year)) if not midpoint_returns.empty else 0.0,
        )

    def liquidity_metrics(self) -> LiquidityMetrics:
        trades = self.trades
        daily = trades.resample("1D").agg(price=("price", "last"), volume=("size", "sum"), notional=("notional", "sum"))
        daily_returns = daily["price"].pct_change().dropna()
        aligned = daily.loc[daily_returns.index]
        amihud = float((daily_returns.abs() / aligned["notional"].replace(0.0, np.nan)).replace([np.inf, -np.inf], np.nan).dropna().mean()) if not aligned.empty else 0.0
        price_change = trades["price"].diff().fillna(0.0)
        signed_volume = trades["signed_size"].replace(0.0, np.nan)
        denominator = float((signed_volume ** 2).sum())
        kyle_lambda = 0.0 if denominator == 0 else float((price_change * signed_volume.fillna(0.0)).sum() / denominator)
        order_book_depth = 0.0
        if self.order_book is not None:
            book = self.order_book_analytics(depth=5)
            order_book_depth = book.bid_depth + book.ask_depth
        average_daily_volume = float(daily["volume"].mean()) if not daily.empty else 0.0
        turnover_velocity = float(daily["volume"].sum() / max(len(daily), 1)) if not daily.empty else 0.0
        liquidity_score = float(
            np.clip(
                (average_daily_volume / max(trades["size"].sum(), 1.0)) * 50.0
                + (1.0 / max(abs(amihud), 1e-12)) * 1e-6
                + max(order_book_depth, 0.0) / max(trades["size"].sum(), 1.0) * 50.0,
                0.0,
                100.0,
            )
        )
        return LiquidityMetrics(
            amihud_illiquidity=amihud,
            kyle_lambda=kyle_lambda,
            average_daily_volume=average_daily_volume,
            turnover_velocity=turnover_velocity,
            order_book_depth=float(order_book_depth),
            liquidity_score=liquidity_score,
        )

    def order_book_analytics(self, depth: int | None = None) -> OrderBookAnalytics:
        if self.order_book is None:
            raise ValueError("order_book data is required for order book analytics")
        if isinstance(self.order_book, dict):
            bids = pd.DataFrame(self.order_book.get("bids", []), columns=["price", "size"])
            bids["side"] = "bid"
            asks = pd.DataFrame(self.order_book.get("asks", []), columns=["price", "size"])
            asks["side"] = "ask"
            levels = pd.concat([bids, asks], ignore_index=True)
        else:
            levels = self.order_book.copy()
        if levels.empty:
            raise ValueError("order_book must not be empty")
        levels[["price", "size"]] = levels[["price", "size"]].astype(float)
        levels["side"] = levels["side"].astype(str).str.lower()
        bids = levels[levels["side"].eq("bid")].sort_values("price", ascending=False)
        asks = levels[levels["side"].eq("ask")].sort_values("price", ascending=True)
        if depth is not None:
            bids = bids.head(depth)
            asks = asks.head(depth)
        best_bid = float(bids["price"].iloc[0]) if not bids.empty else 0.0
        best_ask = float(asks["price"].iloc[0]) if not asks.empty else 0.0
        mid = (best_bid + best_ask) / 2.0 if best_bid and best_ask else 0.0
        bid_depth = float(bids["size"].sum())
        ask_depth = float(asks["size"].sum())
        total_depth = bid_depth + ask_depth
        weighted_mid = 0.0 if total_depth == 0 or best_bid == 0 or best_ask == 0 else float((best_ask * bid_depth + best_bid * ask_depth) / total_depth)
        depth_levels = pd.concat([bids.assign(side="bid"), asks.assign(side="ask")], ignore_index=True)
        return OrderBookAnalytics(
            best_bid=best_bid,
            best_ask=best_ask,
            mid_price=mid,
            spread=best_ask - best_bid if best_ask and best_bid else 0.0,
            spread_bps=float(((best_ask - best_bid) / mid) * 10_000.0) if mid else 0.0,
            bid_depth=bid_depth,
            ask_depth=ask_depth,
            imbalance=float((bid_depth - ask_depth) / total_depth) if total_depth else 0.0,
            weighted_mid_price=weighted_mid,
            depth_by_level=depth_levels,
        )

    def trade_flow_analysis(self, interval: str = "5min") -> TradeFlowAnalysis:
        flow = self.trades.resample(interval).agg(
            buy_volume=("signed_size", lambda values: float(values[values > 0].sum())),
            sell_volume=("signed_size", lambda values: float(abs(values[values < 0].sum()))),
            signed_volume=("signed_size", "sum"),
            total_volume=("size", "sum"),
        ).fillna(0.0)
        total_buy = float(flow["buy_volume"].sum())
        total_sell = float(flow["sell_volume"].sum())
        signed_volume = float(flow["signed_volume"].sum())
        total_volume = total_buy + total_sell
        imbalance = signed_volume / total_volume if total_volume else 0.0
        autocorrelation = float(flow["signed_volume"].autocorr()) if len(flow) > 1 else 0.0
        vpin_proxy = float((flow["signed_volume"].abs() / flow["total_volume"].replace(0.0, np.nan)).replace([np.inf, -np.inf], np.nan).dropna().mean()) if not flow.empty else 0.0
        return TradeFlowAnalysis(
            buy_volume=total_buy,
            sell_volume=total_sell,
            signed_volume=signed_volume,
            volume_imbalance=float(imbalance),
            buy_ratio=float(total_buy / total_volume) if total_volume else 0.0,
            sell_ratio=float(total_sell / total_volume) if total_volume else 0.0,
            order_flow_autocorrelation=autocorrelation,
            vpin_proxy=vpin_proxy,
            interval_flow=flow,
        )

    def report(
        self,
        shares_outstanding: float | None = None,
        free_float_shares: float | None = None,
        interval: str = "5min",
    ) -> MarketAnalyticsReport:
        order_book = self.order_book_analytics(depth=10) if self.order_book is not None else None
        return MarketAnalyticsReport(
            statistics=self.market_statistics(shares_outstanding=shares_outstanding, free_float_shares=free_float_shares),
            quality=self.market_quality_metrics(),
            liquidity=self.liquidity_metrics(),
            order_book=order_book,
            trade_flow=self.trade_flow_analysis(interval=interval),
        )
