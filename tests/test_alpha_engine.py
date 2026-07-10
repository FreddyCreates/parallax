"""Tests for the PARALLAX alpha engine."""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src", "python"))

from parallax_sdk.alpha_engine import (
    AlphaCombiner,
    AlphaPipeline,
    AlphaResearch,
    Backtester,
    FactorConstructor,
    FactorInput,
    SignalFactory,
)


def test_information_coefficient_positive_for_aligned_signal():
    prices = [100, 101, 103, 106, 110, 115, 121]
    signal = [0.1, 0.2, 0.25, 0.3, 0.35, 0.4]
    forward = [(prices[i + 1] - prices[i]) / prices[i] for i in range(len(prices) - 1)]
    assert AlphaCombiner.information_coefficient(signal, forward) > 0


def test_signal_aggregation_returns_weights_and_decay():
    prices = [100, 101, 103, 104, 106, 108, 109, 111]
    signal_map = {
        "momentum": SignalFactory.momentum(prices, lookback=2),
        "mean_reversion": SignalFactory.mean_reversion(prices, lookback=2),
    }
    result = AlphaCombiner.aggregate(signal_map, prices, method="phi")
    assert result.weights
    assert 1 in result.decay_by_horizon
    assert len(result.combined_signal) == min(len(v) for v in signal_map.values())


def test_factor_constructor_builds_all_factor_families():
    items = [
        FactorInput(asset="AAA", price_to_book=1.1, earnings_yield=0.08, free_cash_flow_yield=0.04, return_21d=0.12, return_63d=0.18, return_126d=0.25, return_on_equity=0.16, gross_margin=0.42, leverage=0.3, macro_beta=0.5, inflation_sensitivity=0.2, yield_curve_sensitivity=0.1, alt_data_score=0.7, web_traffic_score=0.5, sentiment_score=0.4),
        FactorInput(asset="BBB", price_to_book=2.4, earnings_yield=0.03, free_cash_flow_yield=0.01, return_21d=-0.02, return_63d=0.01, return_126d=0.08, return_on_equity=0.08, gross_margin=0.22, leverage=0.8, macro_beta=-0.1, inflation_sensitivity=0.4, yield_curve_sensitivity=0.3, alt_data_score=0.2, web_traffic_score=0.3, sentiment_score=0.1),
        FactorInput(asset="CCC", price_to_book=1.7, earnings_yield=0.06, free_cash_flow_yield=0.03, return_21d=0.05, return_63d=0.09, return_126d=0.11, return_on_equity=0.11, gross_margin=0.35, leverage=0.5, macro_beta=0.2, inflation_sensitivity=0.1, yield_curve_sensitivity=0.2, alt_data_score=0.4, web_traffic_score=0.4, sentiment_score=0.2),
    ]
    style = FactorConstructor.style_factors(items)
    macro = FactorConstructor.macro_factors(items)
    alt = FactorConstructor.alternative_data_factors(items)
    pca = FactorConstructor.pca_factor(items)
    assert set(style) == {"value", "momentum", "quality"}
    assert "macro" in macro and "alternative" in alt
    assert set(pca) == {"AAA", "BBB", "CCC"}


def test_backtester_produces_equity_curve():
    prices_by_asset = {
        "AAA": [100, 101, 103, 104, 106, 107],
        "BBB": [100, 99, 98, 97, 96, 95],
    }
    signals = {
        "AAA": [0.2, 0.3, 0.4, 0.35, 0.25, 0.1],
        "BBB": [-0.2, -0.25, -0.3, -0.28, -0.2, -0.1],
    }
    result = Backtester.run(prices_by_asset, signals)
    assert len(result.equity_curve) == len(result.portfolio_returns) + 1
    assert result.cumulative_return >= 0


def test_pipeline_returns_report_with_robustness_metrics():
    prices_by_asset = {
        "AAA": [100, 101, 102, 104, 105, 107, 108, 110],
        "BBB": [100, 99, 98, 97, 97, 96, 95, 94],
    }
    signal_library = {
        "AAA": {
            "momentum": SignalFactory.momentum(prices_by_asset["AAA"], lookback=2),
            "sentiment": SignalFactory.sentiment([0.1, 0.2, 0.3, 0.4, 0.35, 0.5, 0.45, 0.5]),
        },
        "BBB": {
            "momentum": SignalFactory.momentum(prices_by_asset["BBB"], lookback=2),
            "sentiment": SignalFactory.sentiment([-0.1, -0.2, -0.25, -0.3, -0.35, -0.4, -0.45, -0.5]),
        },
    }
    combo, backtest, report = AlphaPipeline().run(prices_by_asset, signal_library)
    assert combo.weights
    assert backtest.equity_curve[-1] > 0
    assert report.robustness_hit_rate >= 0
    assert isinstance(AlphaResearch.performance_attribution(backtest.portfolio_returns, {"market": backtest.portfolio_returns}), dict)
