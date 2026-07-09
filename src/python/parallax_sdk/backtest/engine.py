from __future__ import annotations

from collections import deque
from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Any, Iterable, Optional
import math
import uuid

import numpy as np
import pandas as pd

from .performance import PerformanceAnalyzer, PerformanceReport
from .risk import OrderRiskDecision, RiskManager
from .strategy import Signal, StrategyBase, StrategyContext, StrategyEnsemble


class OrderSide(str, Enum):
    BUY = 'BUY'
    SELL = 'SELL'


class OrderType(str, Enum):
    MARKET = 'market'
    LIMIT = 'limit'
    STOP = 'stop'


class OrderStatus(str, Enum):
    PENDING = 'pending'
    FILLED = 'filled'
    PARTIALLY_FILLED = 'partially_filled'
    CANCELLED = 'cancelled'
    REJECTED = 'rejected'


@dataclass(slots=True)
class MarketEvent:
    timestamp: pd.Timestamp
    symbol: str
    open: float
    high: float
    low: float
    close: float
    volume: float
    data: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class Order:
    timestamp: pd.Timestamp
    symbol: str
    side: OrderSide
    quantity: float
    order_type: OrderType = OrderType.MARKET
    limit_price: float | None = None
    stop_price: float | None = None
    strategy_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)
    order_id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    status: OrderStatus = OrderStatus.PENDING
    remaining_quantity: float | None = None

    def __post_init__(self) -> None:
        if self.remaining_quantity is None:
            self.remaining_quantity = float(self.quantity)


@dataclass(slots=True)
class Fill:
    timestamp: pd.Timestamp
    order_id: str
    symbol: str
    side: OrderSide
    quantity: float
    price: float
    slippage_bps: float
    impact_bps: float
    fees: float
    strategy_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class ClosedTrade:
    trade_id: str
    symbol: str
    side: str
    quantity: float
    entry_time: pd.Timestamp
    exit_time: pd.Timestamp
    entry_price: float
    exit_price: float
    gross_pnl: float
    net_pnl: float
    fees: float
    holding_period_days: float
    strategy_id: str | None = None


@dataclass(slots=True)
class BacktestResult:
    equity_curve: pd.DataFrame
    orders: pd.DataFrame
    fills: pd.DataFrame
    trades: pd.DataFrame
    positions: pd.DataFrame
    metrics: dict[str, Any]
    performance: PerformanceReport
    risk: dict[str, Any]
    benchmark: pd.Series | None = None


@dataclass(slots=True)
class SlippageModel:
    base_bps: float = 1.0
    volatility_bps: float = 5.0
    participation_bps: float = 10.0

    def estimate(self, event: MarketEvent, quantity: float) -> float:
        volatility = abs(event.high - event.low) / event.close if event.close else 0.0
        participation = abs(quantity) / max(event.volume, abs(quantity), 1.0)
        return float(self.base_bps + volatility * self.volatility_bps * 100.0 + participation * self.participation_bps)


@dataclass(slots=True)
class TransactionCostModel:
    commission_rate: float = 0.0005
    fixed_commission: float = 0.0
    tax_rate: float = 0.0
    minimum_commission: float = 0.0

    def estimate(self, notional: float) -> float:
        commission = max(self.minimum_commission, abs(notional) * self.commission_rate + self.fixed_commission)
        taxes = abs(notional) * self.tax_rate
        return float(commission + taxes)


@dataclass(slots=True)
class MarketImpactModel:
    impact_coefficient: float = 15.0
    participation_cap: float = 0.2

    def estimate(self, event: MarketEvent, quantity: float) -> tuple[float, float]:
        if event.volume <= 0:
            return float(self.impact_coefficient), float(abs(quantity))
        max_fill = max(event.volume * self.participation_cap, 1.0)
        fill_quantity = min(abs(quantity), max_fill)
        participation = fill_quantity / max(event.volume, 1.0)
        impact = self.impact_coefficient * math.sqrt(max(participation, 0.0))
        return float(impact), float(fill_quantity)


@dataclass(slots=True)
class Lot:
    quantity: float
    price: float
    timestamp: pd.Timestamp
    strategy_id: str | None = None
    fee_per_unit: float = 0.0


class Position:
    def __init__(self, symbol: str) -> None:
        self.symbol = symbol
        self.lots: deque[Lot] = deque()
        self.market_price: float = 0.0
        self.realized_pnl: float = 0.0

    @property
    def quantity(self) -> float:
        return float(sum(lot.quantity for lot in self.lots))

    @property
    def avg_price(self) -> float:
        total_qty = sum(abs(lot.quantity) for lot in self.lots)
        if total_qty == 0:
            return 0.0
        weighted = sum(abs(lot.quantity) * lot.price for lot in self.lots)
        return float(weighted / total_qty)

    @property
    def market_value(self) -> float:
        return self.quantity * self.market_price

    @property
    def unrealized_pnl(self) -> float:
        if not self.lots:
            return 0.0
        pnl = 0.0
        for lot in self.lots:
            pnl += (self.market_price - lot.price) * lot.quantity
        return float(pnl)

    def mark_to_market(self, price: float) -> None:
        self.market_price = float(price)

    def apply_fill(self, fill: Fill) -> list[ClosedTrade]:
        signed_quantity = fill.quantity if fill.side == OrderSide.BUY else -fill.quantity
        remaining = float(signed_quantity)
        closed_trades: list[ClosedTrade] = []
        exit_fee_per_unit = fill.fees / fill.quantity if fill.quantity else 0.0

        while self.lots and remaining and np.sign(self.lots[0].quantity) != np.sign(remaining):
            lot = self.lots[0]
            close_qty = min(abs(remaining), abs(lot.quantity))
            gross_pnl = (fill.price - lot.price) * close_qty * np.sign(lot.quantity)
            allocated_fees = (lot.fee_per_unit + exit_fee_per_unit) * close_qty
            net_pnl = gross_pnl - allocated_fees
            self.realized_pnl += net_pnl
            holding_days = (fill.timestamp - lot.timestamp).total_seconds() / 86400.0
            closed_trades.append(
                ClosedTrade(
                    trade_id=uuid.uuid4().hex[:12],
                    symbol=self.symbol,
                    side='LONG' if lot.quantity > 0 else 'SHORT',
                    quantity=float(close_qty),
                    entry_time=lot.timestamp,
                    exit_time=fill.timestamp,
                    entry_price=float(lot.price),
                    exit_price=float(fill.price),
                    gross_pnl=float(gross_pnl),
                    net_pnl=float(net_pnl),
                    fees=float(allocated_fees),
                    holding_period_days=float(holding_days),
                    strategy_id=fill.strategy_id or lot.strategy_id,
                )
            )
            lot.quantity += close_qty * np.sign(remaining)
            remaining -= close_qty * np.sign(remaining)
            if abs(lot.quantity) < 1e-12:
                self.lots.popleft()

        if remaining:
            self.lots.append(
                Lot(
                    quantity=float(remaining),
                    price=float(fill.price),
                    timestamp=fill.timestamp,
                    strategy_id=fill.strategy_id,
                    fee_per_unit=exit_fee_per_unit,
                )
            )

        self.market_price = float(fill.price)
        return closed_trades


class BacktestEngine:
    """Event-driven backtesting engine with replay, execution, and analytics."""

    def __init__(
        self,
        strategies: StrategyBase | StrategyEnsemble | list[StrategyBase],
        initial_cash: float = 1_000_000.0,
        slippage_model: SlippageModel | None = None,
        transaction_cost_model: TransactionCostModel | None = None,
        impact_model: MarketImpactModel | None = None,
        risk_manager: RiskManager | None = None,
        benchmark: pd.Series | pd.DataFrame | None = None,
    ) -> None:
        if isinstance(strategies, list):
            self.strategy: StrategyBase = StrategyEnsemble(strategies)
        else:
            self.strategy = strategies
        self.initial_cash = float(initial_cash)
        self.slippage_model = slippage_model or SlippageModel()
        self.transaction_cost_model = transaction_cost_model or TransactionCostModel()
        self.impact_model = impact_model or MarketImpactModel()
        self.risk_manager = risk_manager
        self.benchmark = self._prepare_benchmark(benchmark)
        self.reset()

    def reset(self) -> None:
        self.cash = self.initial_cash
        self.positions: dict[str, Position] = {}
        self.pending_orders: list[Order] = []
        self.orders_log: list[dict[str, Any]] = []
        self.fills_log: list[dict[str, Any]] = []
        self.trades_log: list[dict[str, Any]] = []
        self.equity_log: list[dict[str, Any]] = []
        self.position_log: list[dict[str, Any]] = []
        self.market_state: dict[str, dict[str, Any]] = {}
        self.history: dict[str, pd.DataFrame] = {}
        self.realized_pnl = 0.0
        self._event_counter = 0

    def _prepare_benchmark(self, benchmark: pd.Series | pd.DataFrame | None) -> pd.Series | None:
        if benchmark is None:
            return None
        if isinstance(benchmark, pd.DataFrame):
            benchmark = benchmark.iloc[:, 0]
        benchmark.index = pd.to_datetime(benchmark.index)
        return benchmark.sort_index().astype(float)

    def _normalize_frame(self, symbol: str, frame: pd.DataFrame) -> pd.DataFrame:
        data = frame.copy()
        if 'timestamp' in data.columns:
            data['timestamp'] = pd.to_datetime(data['timestamp'])
            data = data.set_index('timestamp')
        if not isinstance(data.index, pd.DatetimeIndex):
            data.index = pd.to_datetime(data.index)
        data.columns = [str(column).lower() for column in data.columns]
        if 'close' not in data.columns:
            raise ValueError(f'{symbol} is missing a close column')
        for column in ('open', 'high', 'low'):
            if column not in data.columns:
                data[column] = data['close']
        if 'volume' not in data.columns:
            data['volume'] = np.nan
        data = data[['open', 'high', 'low', 'close', 'volume']].sort_index()
        return data.astype(float)

    def _build_event_stream(self, historical_data: dict[str, pd.DataFrame]) -> list[MarketEvent]:
        frames: list[pd.DataFrame] = []
        self.history = {}
        for symbol, frame in historical_data.items():
            normalized = self._normalize_frame(symbol, frame)
            self.history[symbol] = normalized
            temp = normalized.copy()
            temp['symbol'] = symbol
            temp['timestamp'] = temp.index
            frames.append(temp.reset_index(drop=True))
        if not frames:
            return []
        stream = pd.concat(frames, ignore_index=True).sort_values(['timestamp', 'symbol'])
        events = [
            MarketEvent(
                timestamp=row.timestamp,
                symbol=row.symbol,
                open=float(row.open),
                high=float(row.high),
                low=float(row.low),
                close=float(row.close),
                volume=float(row.volume) if pd.notna(row.volume) else np.nan,
            )
            for row in stream.itertuples(index=False)
        ]
        return events

    def _context(self, timestamp: pd.Timestamp) -> StrategyContext:
        prices = {symbol: state['close'] for symbol, state in self.market_state.items()}
        positions = {symbol: position.quantity for symbol, position in self.positions.items() if abs(position.quantity) > 1e-12}
        unrealized = sum(position.unrealized_pnl for position in self.positions.values())
        equity = self.cash + sum(position.market_value for position in self.positions.values())
        benchmark_value = None
        if self.benchmark is not None and timestamp in self.benchmark.index:
            benchmark_value = float(self.benchmark.loc[timestamp])
        return StrategyContext(
            timestamp=timestamp,
            cash=float(self.cash),
            equity=float(equity),
            positions=positions,
            prices=prices,
            history=self.history,
            realized_pnl=float(self.realized_pnl),
            unrealized_pnl=float(unrealized),
            benchmark_value=benchmark_value,
        )

    def _resolve_signal_quantity(self, signal: Signal, context: StrategyContext) -> float:
        price = context.price(signal.symbol) or 0.0
        current_quantity = context.position(signal.symbol)
        if signal.quantity is not None:
            return float(signal.quantity)
        if signal.target_quantity is not None:
            return float(signal.target_quantity - current_quantity)
        if signal.target_weight is not None and price > 0:
            target_quantity = (signal.target_weight * context.equity) / price
            return float(target_quantity - current_quantity)
        return 0.0

    def _signal_to_order(self, signal: Signal, context: StrategyContext) -> Order | None:
        quantity = self._resolve_signal_quantity(signal, context)
        if abs(quantity) < 1e-12:
            return None
        side = OrderSide.BUY if quantity > 0 else OrderSide.SELL
        order = Order(
            timestamp=signal.timestamp,
            symbol=signal.symbol,
            side=side,
            quantity=abs(quantity),
            order_type=OrderType(signal.order_type.lower()),
            limit_price=signal.limit_price,
            stop_price=signal.stop_price,
            strategy_id=signal.strategy_id,
            metadata=dict(signal.metadata),
        )
        if self.risk_manager:
            price = context.price(order.symbol) or 0.0
            decision = self.risk_manager.check_order(
                symbol=order.symbol,
                desired_quantity=quantity,
                price=price,
                positions=context.positions,
                equity=context.equity,
                prices=context.prices,
            )
            order = self._apply_risk_decision(order, decision)
        return None if order.quantity <= 0 else order

    def _apply_risk_decision(self, order: Order, decision: OrderRiskDecision) -> Order:
        if not decision.approved or decision.approved_quantity == 0:
            order.quantity = 0.0
            order.remaining_quantity = 0.0
            order.status = OrderStatus.REJECTED
            order.metadata['risk_reason'] = decision.reason
            return order
        order.side = OrderSide.BUY if decision.approved_quantity > 0 else OrderSide.SELL
        order.quantity = abs(float(decision.approved_quantity))
        order.remaining_quantity = order.quantity
        order.metadata['risk_reason'] = decision.reason
        return order

    def _fill_price(self, order: Order, event: MarketEvent, quantity: float) -> tuple[float, float, float]:
        if order.order_type == OrderType.LIMIT:
            triggered = (order.side == OrderSide.BUY and event.low <= float(order.limit_price)) or (
                order.side == OrderSide.SELL and event.high >= float(order.limit_price)
            )
            if not triggered:
                raise ValueError('limit_not_triggered')
            reference_price = float(order.limit_price)
        elif order.order_type == OrderType.STOP:
            triggered = (order.side == OrderSide.BUY and event.high >= float(order.stop_price)) or (
                order.side == OrderSide.SELL and event.low <= float(order.stop_price)
            )
            if not triggered:
                raise ValueError('stop_not_triggered')
            reference_price = float(order.stop_price)
        else:
            reference_price = event.close

        slippage_bps = self.slippage_model.estimate(event, quantity)
        impact_bps, _ = self.impact_model.estimate(event, quantity)
        direction = 1.0 if order.side == OrderSide.BUY else -1.0
        execution_price = reference_price * (1.0 + direction * (slippage_bps + impact_bps) / 10000.0)
        return float(execution_price), float(slippage_bps), float(impact_bps)

    def _execute_order(self, order: Order, event: MarketEvent) -> list[Fill]:
        if order.symbol != event.symbol or order.status == OrderStatus.REJECTED:
            return []

        try:
            impact_bps, max_fill_quantity = self.impact_model.estimate(event, order.remaining_quantity or order.quantity)
            fill_quantity = min(order.remaining_quantity or order.quantity, max_fill_quantity)
            if fill_quantity <= 0:
                return []
            execution_price, slippage_bps, _ = self._fill_price(order, event, fill_quantity)
            fees = self.transaction_cost_model.estimate(execution_price * fill_quantity)
            fill = Fill(
                timestamp=event.timestamp,
                order_id=order.order_id,
                symbol=order.symbol,
                side=order.side,
                quantity=float(fill_quantity),
                price=float(execution_price),
                slippage_bps=float(slippage_bps),
                impact_bps=float(impact_bps),
                fees=float(fees),
                strategy_id=order.strategy_id,
                metadata=dict(order.metadata),
            )
            order.remaining_quantity = max((order.remaining_quantity or order.quantity) - fill_quantity, 0.0)
            order.status = OrderStatus.FILLED if order.remaining_quantity == 0 else OrderStatus.PARTIALLY_FILLED
            return [fill]
        except ValueError:
            return []

    def _process_fill(self, fill: Fill) -> None:
        position = self.positions.setdefault(fill.symbol, Position(fill.symbol))
        position.mark_to_market(fill.price)
        closed_trades = position.apply_fill(fill)
        notional = fill.price * fill.quantity
        if fill.side == OrderSide.BUY:
            self.cash -= notional + fill.fees
        else:
            self.cash += notional - fill.fees
        self.realized_pnl = sum(position.realized_pnl for position in self.positions.values())
        self.fills_log.append(asdict(fill))
        for trade in closed_trades:
            self.trades_log.append(asdict(trade))

    def _mark_positions(self, event: MarketEvent) -> None:
        self.market_state[event.symbol] = {
            'open': event.open,
            'high': event.high,
            'low': event.low,
            'close': event.close,
            'volume': event.volume,
        }
        if event.symbol in self.positions:
            self.positions[event.symbol].mark_to_market(event.close)

    def _record_state(self, timestamp: pd.Timestamp) -> None:
        prices = {symbol: state['close'] for symbol, state in self.market_state.items()}
        equity = self.cash + sum(position.market_value for position in self.positions.values())
        gross_exposure = sum(abs(position.market_value) for position in self.positions.values())
        net_exposure = sum(position.market_value for position in self.positions.values())
        leverage = gross_exposure / equity if equity else 0.0
        benchmark_value = float(self.benchmark.loc[timestamp]) if self.benchmark is not None and timestamp in self.benchmark.index else np.nan
        self.equity_log.append(
            {
                'timestamp': timestamp,
                'cash': float(self.cash),
                'equity': float(equity),
                'realized_pnl': float(self.realized_pnl),
                'unrealized_pnl': float(sum(position.unrealized_pnl for position in self.positions.values())),
                'gross_exposure': float(gross_exposure),
                'net_exposure': float(net_exposure),
                'leverage': float(leverage),
                'benchmark': benchmark_value,
            }
        )
        for symbol, position in self.positions.items():
            self.position_log.append(
                {
                    'timestamp': timestamp,
                    'symbol': symbol,
                    'quantity': float(position.quantity),
                    'avg_price': float(position.avg_price),
                    'market_price': float(prices.get(symbol, position.market_price)),
                    'market_value': float(position.market_value),
                    'unrealized_pnl': float(position.unrealized_pnl),
                    'realized_pnl': float(position.realized_pnl),
                }
            )

    def run(self, historical_data: dict[str, pd.DataFrame]) -> BacktestResult:
        self.reset()
        events = self._build_event_stream(historical_data)
        if not events:
            raise ValueError('historical_data produced no events')

        first_context = self._context(events[0].timestamp)
        self.strategy.on_start(first_context)

        for event in events:
            self._mark_positions(event)
            context = self._context(event.timestamp)
            event_payload = {
                'timestamp': event.timestamp,
                'symbol': event.symbol,
                'open': event.open,
                'high': event.high,
                'low': event.low,
                'close': event.close,
                'volume': event.volume,
            }

            signals = self.strategy.on_market_event(event_payload, context)
            new_orders = [order for signal in signals if (order := self._signal_to_order(signal, context)) is not None]
            self.pending_orders.extend(new_orders)

            still_pending: list[Order] = []
            for order in self.pending_orders:
                fills = self._execute_order(order, event)
                if not fills and order.symbol == event.symbol and order.order_type == OrderType.MARKET:
                    order.status = OrderStatus.CANCELLED
                for fill in fills:
                    self._process_fill(fill)
                    self.strategy.on_fill(fill, self._context(fill.timestamp))
                if order.status in {OrderStatus.PENDING, OrderStatus.PARTIALLY_FILLED}:
                    still_pending.append(order)
                self.orders_log.append(
                    {
                        'timestamp': order.timestamp,
                        'order_id': order.order_id,
                        'symbol': order.symbol,
                        'side': order.side.value,
                        'quantity': float(order.quantity),
                        'remaining_quantity': float(order.remaining_quantity or 0.0),
                        'order_type': order.order_type.value,
                        'limit_price': order.limit_price,
                        'stop_price': order.stop_price,
                        'strategy_id': order.strategy_id,
                        'status': order.status.value,
                        'metadata': order.metadata,
                    }
                )
            self.pending_orders = still_pending
            self._record_state(event.timestamp)

        equity_curve = pd.DataFrame(self.equity_log).drop_duplicates(subset=['timestamp'], keep='last')
        fills = pd.DataFrame(self.fills_log)
        trades = pd.DataFrame(self.trades_log)
        positions = pd.DataFrame(self.position_log)
        orders = pd.DataFrame(self.orders_log)

        benchmark_series = None
        if self.benchmark is not None:
            benchmark_series = self.benchmark.reindex(pd.to_datetime(equity_curve['timestamp'])).ffill()
            benchmark_series.index = pd.to_datetime(equity_curve['timestamp'])

        performance = PerformanceAnalyzer(equity_curve, trades=trades, benchmark=benchmark_series).summary()
        risk_returns = performance.returns['return']
        benchmark_returns = performance.returns['benchmark_return'] if 'benchmark_return' in performance.returns.columns else None
        risk = (self.risk_manager or RiskManager()).summarize(
            returns=risk_returns,
            benchmark_returns=benchmark_returns,
            positions={symbol: position.quantity for symbol, position in self.positions.items()},
            prices={symbol: position.market_price for symbol, position in self.positions.items()},
            equity=float(equity_curve['equity'].iloc[-1]),
        )
        metrics = {**performance.summary, **performance.trade_statistics, **risk}
        result = BacktestResult(
            equity_curve=equity_curve,
            orders=orders,
            fills=fills,
            trades=trades,
            positions=positions,
            metrics=metrics,
            performance=performance,
            risk=risk,
            benchmark=benchmark_series,
        )
        self.strategy.on_finish(result)
        return result
