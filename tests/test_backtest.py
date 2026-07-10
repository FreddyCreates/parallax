import os
import sys

import matplotlib
import numpy as np
import pandas as pd

matplotlib.use('Agg')

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src', 'python'))

from parallax_sdk.backtest import (  # noqa: E402
    BacktestEngine,
    BacktestVisualizer,
    ExposureLimits,
    RiskManager,
    StrategyBase,
)


class BuyHoldThenExit(StrategyBase):
    def __init__(self):
        super().__init__('buy_hold_exit')
        self.bar_count = 0

    def generate_signals(self, event, context):
        self.bar_count += 1
        if self.bar_count == 1:
            return [self.rebalance_to_weight(event['symbol'], 0.5, context)]
        if self.bar_count == 6:
            return [self.rebalance_to_weight(event['symbol'], 0.0, context)]
        return []


def test_backtest_engine_end_to_end():
    dates = pd.date_range('2024-01-01', periods=6, freq='D')
    prices = pd.DataFrame(
        {
            'open': [100, 101, 102, 103, 104, 105],
            'high': [101, 102, 103, 104, 105, 106],
            'low': [99, 100, 101, 102, 103, 104],
            'close': [100, 101, 102, 103, 104, 105],
            'volume': [10_000] * 6,
        },
        index=dates,
    )

    engine = BacktestEngine(
        strategies=BuyHoldThenExit(),
        initial_cash=100_000,
        risk_manager=RiskManager(ExposureLimits(max_symbol_exposure=0.6, max_gross_exposure=1.0, max_leverage=1.0)),
    )
    result = engine.run({'PARALLAX': prices})

    assert not result.equity_curve.empty
    assert not result.orders.empty
    assert not result.fills.empty
    assert result.performance.summary['ending_equity'] > 100_000
    assert result.metrics['max_drawdown'] <= 0.0


def test_visualization_and_risk_outputs():
    dates = pd.date_range('2024-01-01', periods=10, freq='D')
    prices = pd.DataFrame(
        {
            'close': np.linspace(100, 110, 10),
            'volume': [5_000] * 10,
        },
        index=dates,
    )
    benchmark = pd.Series(np.linspace(100, 108, 10), index=dates)
    engine = BacktestEngine(strategies=BuyHoldThenExit(), initial_cash=50_000, benchmark=benchmark)
    result = engine.run({'PX': prices})

    visualizer = BacktestVisualizer()
    tearsheet = visualizer.generate_tearsheet(result)

    assert 'equity_curve' in tearsheet
    assert 'drawdown' in tearsheet
    assert 'value_at_risk' in result.risk
    assert np.isfinite(result.metrics['sharpe_ratio'])
