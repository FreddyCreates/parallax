from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Iterable, Optional

import pandas as pd


@dataclass(slots=True)
class Signal:
    """Strategy instruction sent to the execution engine.

    Quantities are signed: positive values buy, negative values sell.
    One of `quantity`, `target_quantity`, or `target_weight` should be set.
    """

    timestamp: pd.Timestamp
    symbol: str
    quantity: float | None = None
    target_quantity: float | None = None
    target_weight: float | None = None
    order_type: str = 'market'
    limit_price: float | None = None
    stop_price: float | None = None
    strength: float = 1.0
    strategy_id: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class StrategyContext:
    """Runtime state made available to strategies during replay."""

    timestamp: pd.Timestamp
    cash: float
    equity: float
    positions: dict[str, float]
    prices: dict[str, float]
    history: dict[str, pd.DataFrame]
    realized_pnl: float = 0.0
    unrealized_pnl: float = 0.0
    benchmark_value: float | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    def position(self, symbol: str) -> float:
        return float(self.positions.get(symbol, 0.0))

    def price(self, symbol: str) -> float | None:
        value = self.prices.get(symbol)
        return None if value is None else float(value)


class StrategyBase(ABC):
    """Base class for event-driven strategies."""

    def __init__(
        self,
        name: str,
        symbols: Optional[list[str]] = None,
        risk_manager: Any | None = None,
        max_position_weight: float = 1.0,
    ) -> None:
        self.name = name
        self.symbols = symbols or []
        self.risk_manager = risk_manager
        self.max_position_weight = max_position_weight

    def on_start(self, context: StrategyContext) -> None:
        """Hook invoked before the event loop starts."""

    def on_finish(self, result: Any) -> None:
        """Hook invoked after the backtest completes."""

    def on_fill(self, fill: Any, context: StrategyContext) -> None:
        """Hook invoked after a fill is processed."""

    def manage_position(self, event: dict[str, Any], context: StrategyContext) -> Iterable[Signal]:
        """Optional position management overlay."""
        return []

    @abstractmethod
    def generate_signals(self, event: dict[str, Any], context: StrategyContext) -> Iterable[Signal]:
        """Return zero or more signals for the current event."""

    def apply_risk_management(self, signals: Iterable[Signal], context: StrategyContext) -> list[Signal]:
        managed: list[Signal] = []
        for signal in signals:
            if signal.target_weight is not None:
                signal.target_weight = max(
                    -self.max_position_weight,
                    min(self.max_position_weight, signal.target_weight),
                )
            if self.risk_manager and hasattr(self.risk_manager, 'review_signal'):
                signal = self.risk_manager.review_signal(signal, context)
                if signal is None:
                    continue
            managed.append(signal)
        return managed

    def on_market_event(self, event: dict[str, Any], context: StrategyContext) -> list[Signal]:
        signals = list(self.generate_signals(event, context))
        signals.extend(self.manage_position(event, context))
        managed = self.apply_risk_management(signals, context)
        for signal in managed:
            signal.strategy_id = signal.strategy_id or self.name
        return managed

    def rebalance_to_weight(
        self,
        symbol: str,
        target_weight: float,
        context: StrategyContext,
        **kwargs: Any,
    ) -> Signal:
        return Signal(
            timestamp=context.timestamp,
            symbol=symbol,
            target_weight=target_weight,
            strategy_id=self.name,
            **kwargs,
        )


class StrategyEnsemble(StrategyBase):
    """Combines multiple strategies into a single orchestrated strategy."""

    def __init__(
        self,
        strategies: list[StrategyBase],
        weights: Optional[dict[str, float]] = None,
        aggregation: str = 'net',
        name: str = 'ensemble',
    ) -> None:
        super().__init__(name=name)
        self.strategies = strategies
        self.weights = weights or {strategy.name: 1.0 for strategy in strategies}
        self.aggregation = aggregation

    def on_start(self, context: StrategyContext) -> None:
        for strategy in self.strategies:
            strategy.on_start(context)

    def on_finish(self, result: Any) -> None:
        for strategy in self.strategies:
            strategy.on_finish(result)

    def on_fill(self, fill: Any, context: StrategyContext) -> None:
        for strategy in self.strategies:
            if fill.strategy_id in {strategy.name, self.name, None}:
                strategy.on_fill(fill, context)

    def generate_signals(self, event: dict[str, Any], context: StrategyContext) -> Iterable[Signal]:
        raw_signals: list[Signal] = []
        for strategy in self.strategies:
            raw_signals.extend(strategy.on_market_event(event, context))
        if self.aggregation == 'raw':
            return raw_signals
        return self._aggregate(raw_signals)

    def _aggregate(self, signals: list[Signal]) -> list[Signal]:
        if not signals:
            return []

        aggregated: dict[tuple[Any, ...], Signal] = {}
        for signal in signals:
            weight = float(self.weights.get(signal.strategy_id or '', 1.0))
            key = (signal.symbol, signal.order_type, signal.limit_price, signal.stop_price)
            if key not in aggregated:
                base = Signal(
                    timestamp=signal.timestamp,
                    symbol=signal.symbol,
                    quantity=0.0,
                    target_quantity=None,
                    target_weight=0.0 if signal.target_weight is not None else None,
                    order_type=signal.order_type,
                    limit_price=signal.limit_price,
                    stop_price=signal.stop_price,
                    strength=0.0,
                    strategy_id=self.name,
                    metadata={'contributors': []},
                )
                aggregated[key] = base

            current = aggregated[key]
            if signal.quantity is not None:
                current.quantity = (current.quantity or 0.0) + signal.quantity * weight
            if signal.target_quantity is not None:
                current.target_quantity = (current.target_quantity or 0.0) + signal.target_quantity * weight
            if signal.target_weight is not None:
                current.target_weight = (current.target_weight or 0.0) + signal.target_weight * weight
            current.strength += signal.strength * weight
            current.metadata.setdefault('contributors', []).append(signal.strategy_id)

        if self.aggregation == 'average':
            divisor = max(len(self.strategies), 1)
            for signal in aggregated.values():
                if signal.quantity is not None:
                    signal.quantity /= divisor
                if signal.target_quantity is not None:
                    signal.target_quantity /= divisor
                if signal.target_weight is not None:
                    signal.target_weight /= divisor
                signal.strength /= divisor
        return list(aggregated.values())
