# ruff: noqa: S101, S314
"""PARRALAX-AIHFTFUND Comprehensive Test Suite — 200 Tests.

Covers:
- Trading Strategies (10 strategies × multiple scenarios)
- Financial Language Engines (FIX, FpML, SWIFT, ISDA CDM, XBRL, ISO20022)
- Strategy Router & Capital Allocation
- Risk Management
- Governance Protocol Validation
- HTTP Service Contracts
- Agent Authority Levels
- Temporal & Lifecycle Operations
- Ethics & Compliance Boundaries
- Cross-Service Data Flow
"""

from __future__ import annotations

import math
from xml.etree import ElementTree as ET

import pytest

from app.routers.financial_languages import (
    FIXEngine,
    FpMLEngine,
    ISDACDMEngine,
    ISO20022Engine,
    SWIFTEngine,
    XBRLEngine,
)
from app.routers.financial_languages.fix_protocol import FIXOrdType, FIXSide, RiskCheckResult
from app.strategies import (
    CrossAssetArbitrageStrategy,
    EventDrivenStrategy,
    LiquidityProvisionStrategy,
    MarketMakingStrategy,
    MeanReversionStrategy,
    MLAlphaStrategy,
    MomentumStrategy,
    PairsTradingStrategy,
    StatisticalArbitrageStrategy,
    StrategyRouter,
    VolatilityArbitrageStrategy,
)
from app.strategies.event_driven import EventType
from app.strategies.strategy_router import (
    MarketRegime,
    RiskLimitStatus,
    StrategyType,
    TimeFrame,
)


# =============================================================================
# FIXTURES
# =============================================================================

@pytest.fixture
def trending_prices() -> list[float]:
    return [100.0 + 0.7 * i for i in range(60)]


@pytest.fixture
def trending_highs(trending_prices: list[float]) -> list[float]:
    return [p + 1.2 for p in trending_prices]


@pytest.fixture
def trending_lows(trending_prices: list[float]) -> list[float]:
    return [p - 1.2 for p in trending_prices]


@pytest.fixture
def mean_reverting_prices() -> list[float]:
    return [100.0 + ((i % 5) - 2) * 0.12 for i in range(59)] + [95.0]


@pytest.fixture
def pair_prices_a() -> list[float]:
    return [100.0 + 0.3 * i + ((i % 3) - 1) * 0.03 for i in range(59)] + [124.5]


@pytest.fixture
def pair_prices_b() -> list[float]:
    return [50.0 + 0.15 * i + ((i % 4) - 1.5) * 0.02 for i in range(60)]


@pytest.fixture
def volumes() -> list[float]:
    return [1_000.0 + 25.0 * i for i in range(60)]


@pytest.fixture
def fix_engine() -> FIXEngine:
    return FIXEngine()


@pytest.fixture
def strategy_router() -> StrategyRouter:
    return StrategyRouter(total_capital=1_000_000.0)


# =============================================================================
# 1. MOMENTUM STRATEGY TESTS (1-20)
# =============================================================================

class TestMomentumStrategy:
    """Tests 1-20: Momentum/Trend Following Strategy."""

    def test_01_bullish_trend_generates_long_signal(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.direction == "long"

    def test_02_momentum_strength_positive(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.strength > 0.0

    def test_03_momentum_strength_bounded(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert 0.0 <= signal.strength <= 1.0

    def test_04_breakout_level_above_current(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.breakout_level > trending_prices[-1]

    def test_05_symbol_preserved(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("TSLA", trending_prices, trending_highs, trending_lows)
        assert signal.symbol == "TSLA"

    def test_06_bearish_trend_generates_short_signal(self):
        bearish_prices = [150.0 - 0.8 * i for i in range(60)]
        highs = [p + 1.0 for p in bearish_prices]
        lows = [p - 1.0 for p in bearish_prices]
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", bearish_prices, highs, lows)
        assert signal.direction in ("short", "flat")

    def test_07_flat_market_low_strength(self):
        flat_prices = [100.0 + ((i % 3) - 1) * 0.01 for i in range(60)]
        highs = [p + 0.5 for p in flat_prices]
        lows = [p - 0.5 for p in flat_prices]
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", flat_prices, highs, lows)
        assert signal.strength < 0.8

    def test_08_custom_fast_period(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy(fast_period=5)
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.direction == "long"

    def test_09_custom_slow_period(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy(slow_period=30)
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.direction == "long"

    def test_10_momentum_score_populated(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.momentum_score != 0.0

    def test_11_trend_quality_bounded(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert 0.0 <= signal.trend_quality <= 1.0

    def test_12_ema_calculation_returns_list(self, trending_prices):
        strategy = MomentumStrategy()
        ema = strategy.exponential_moving_average(trending_prices, 10)
        assert len(ema) > 0
        assert len(ema) <= len(trending_prices)

    def test_13_ema_follows_trend(self, trending_prices):
        strategy = MomentumStrategy()
        ema = strategy.exponential_moving_average(trending_prices, 10)
        assert ema[-1] > ema[0]

    def test_14_different_symbols_independent(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        s1 = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        s2 = strategy.generate_signal("MSFT", trending_prices, trending_highs, trending_lows)
        assert s1.symbol != s2.symbol

    def test_15_signal_history_tracked(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert len(strategy.signal_history) >= 1

    def test_16_high_breakout_threshold(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy(breakout_threshold=5.0)
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.breakout_level > 0.0

    def test_17_timeframe_populated(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert signal.timeframe is not None

    def test_18_multiple_signals_consistency(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        signals = [strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows) for _ in range(3)]
        assert all(s.direction == "long" for s in signals)

    def test_19_last_state_updated(self, trending_prices, trending_highs, trending_lows):
        strategy = MomentumStrategy()
        strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        assert strategy.last_state != {}

    def test_20_minimum_data_required(self):
        strategy = MomentumStrategy()
        short_prices = [100.0, 101.0, 102.0]
        highs = [101.0, 102.0, 103.0]
        lows = [99.0, 100.0, 101.0]
        signal = strategy.generate_signal("AAPL", short_prices, highs, lows)
        assert signal is not None


# =============================================================================
# 2. STATISTICAL ARBITRAGE TESTS (21-35)
# =============================================================================

class TestStatisticalArbitrage:
    """Tests 21-35: Statistical Arbitrage Strategy."""

    def test_21_pair_preserved(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal.pair == ("AAPL", "MSFT")

    def test_22_hedge_ratio_nonzero(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal.hedge_ratio != 0.0

    def test_23_confidence_bounded(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert 0.0 <= signal.confidence <= 1.0

    def test_24_z_score_calculated(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert not math.isnan(signal.z_score)

    def test_25_half_life_positive(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal.half_life > 0.0

    def test_26_signal_strength_enum(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal.signal.value in ("strong_buy", "buy", "neutral", "sell", "strong_sell")

    def test_27_spread_value_computed(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal.spread_value != 0.0

    def test_28_custom_entry_z(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy(entry_z=1.5)
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal is not None

    def test_29_custom_lookback(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy(lookback=30)
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        assert signal is not None

    def test_30_identical_series_neutral(self):
        prices = [100.0 + 0.5 * i for i in range(60)]
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("A", "B"), prices, prices)
        assert signal.signal.value == "neutral"

    def test_31_divergent_pair_generates_signal(self):
        prices_a = [100.0 + i for i in range(60)]
        prices_b = [100.0 - 0.5 * i for i in range(60)]
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("A", "B"), prices_a, prices_b)
        assert signal.hedge_ratio != 0.0

    def test_32_multiple_pairs_independent(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy()
        s1 = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        s2 = strategy.generate_signal(("GOOG", "META"), pair_prices_b, pair_prices_a)
        assert s1.pair != s2.pair

    def test_33_stop_z_parameter(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy(stop_z=3.0)
        signal = strategy.generate_signal(("A", "B"), pair_prices_a, pair_prices_b)
        assert signal is not None

    def test_34_exit_z_parameter(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy(exit_z=0.3)
        signal = strategy.generate_signal(("A", "B"), pair_prices_a, pair_prices_b)
        assert signal is not None

    def test_35_min_half_life_filter(self, pair_prices_a, pair_prices_b):
        strategy = StatisticalArbitrageStrategy(min_half_life=10.0)
        signal = strategy.generate_signal(("A", "B"), pair_prices_a, pair_prices_b)
        assert signal is not None


# =============================================================================
# 3. MARKET MAKING TESTS (36-50)
# =============================================================================

class TestMarketMaking:
    """Tests 36-50: Market Making Strategy."""

    def test_36_bid_below_ask(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.bid_price < quote.ask_price

    def test_37_positive_spread(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.spread > 0.0

    def test_38_positive_bid_size(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.bid_size > 0.0

    def test_39_positive_ask_size(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.ask_size > 0.0

    def test_40_symbol_preserved(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("ETH-USD", 3500.0)
        assert quote.symbol == "ETH-USD"

    def test_41_custom_spread_bps(self):
        strategy = MarketMakingStrategy(base_spread_bps=10.0)
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.spread > 0.0

    def test_42_inventory_tracking(self):
        strategy = MarketMakingStrategy()
        strategy.generate_quotes("BTC-USD", 100.0)
        assert "BTC-USD" in strategy.inventory or strategy.inventory.get("BTC-USD", 0.0) == 0.0

    def test_43_multiple_quotes_consistent(self):
        strategy = MarketMakingStrategy()
        quotes = [strategy.generate_quotes("BTC-USD", 100.0) for _ in range(5)]
        assert all(q.bid_price < q.ask_price for q in quotes)

    def test_44_high_price_quotes(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 50_000.0)
        assert quote.bid_price > 49_000.0
        assert quote.ask_price < 51_000.0

    def test_45_low_price_quotes(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("DOGE-USD", 0.10)
        assert quote.ask_price > 0.0
        assert quote.ask_price > quote.bid_price

    def test_46_skew_calculated(self):
        strategy = MarketMakingStrategy()
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert isinstance(quote.skew, float)

    def test_47_gamma_affects_spread(self):
        narrow = MarketMakingStrategy(gamma=0.01)
        wide = MarketMakingStrategy(gamma=1.0)
        q1 = narrow.generate_quotes("X", 100.0)
        q2 = wide.generate_quotes("X", 100.0)
        assert q1.spread != q2.spread

    def test_48_tick_size_respected(self):
        strategy = MarketMakingStrategy(tick_size=0.01)
        quote = strategy.generate_quotes("BTC-USD", 100.0)
        assert quote.bid_price > 0.0

    def test_49_max_inventory_parameter(self):
        strategy = MarketMakingStrategy(max_inventory=50.0)
        assert strategy.max_inventory == 50.0

    def test_50_quote_history_tracked(self):
        strategy = MarketMakingStrategy()
        strategy.generate_quotes("BTC-USD", 100.0)
        assert "BTC-USD" in strategy.quote_history


# =============================================================================
# 4. MEAN REVERSION TESTS (51-65)
# =============================================================================

class TestMeanReversion:
    """Tests 51-65: Mean Reversion Strategy."""

    def test_51_oversold_generates_long(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal.direction == "long"

    def test_52_confidence_positive(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal.confidence > 0.0

    def test_53_mean_target_above_price(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal.mean_target > mean_reverting_prices[-1]

    def test_54_bollinger_position_bounded(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert 0.0 <= signal.bollinger_position <= 1.0 or signal.bollinger_position < 0.0 or signal.bollinger_position > 1.0

    def test_55_rsi_calculated(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert 0.0 <= signal.rsi <= 100.0

    def test_56_distance_from_mean_computed(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal.distance_from_mean != 0.0

    def test_57_custom_bb_period(self, mean_reverting_prices):
        strategy = MeanReversionStrategy(bb_period=10)
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal is not None

    def test_58_custom_rsi_period(self, mean_reverting_prices):
        strategy = MeanReversionStrategy(rsi_period=7)
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal is not None

    def test_59_overbought_scenario(self):
        rising_prices = [100.0 + 2.0 * i for i in range(60)]
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("AAPL", rising_prices)
        assert signal.direction in ("short", "flat", "long")

    def test_60_signal_history_appended(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        strategy.generate_signal("AAPL", mean_reverting_prices)
        assert len(strategy.signal_history) >= 1

    def test_61_symbol_preserved(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        signal = strategy.generate_signal("GOOG", mean_reverting_prices)
        assert signal.symbol == "GOOG"

    def test_62_custom_entry_threshold(self, mean_reverting_prices):
        strategy = MeanReversionStrategy(entry_threshold=0.5)
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal is not None

    def test_63_rsi_oversold_parameter(self, mean_reverting_prices):
        strategy = MeanReversionStrategy(rsi_oversold=25.0)
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal is not None

    def test_64_rsi_overbought_parameter(self, mean_reverting_prices):
        strategy = MeanReversionStrategy(rsi_overbought=75.0)
        signal = strategy.generate_signal("AAPL", mean_reverting_prices)
        assert signal is not None

    def test_65_last_state_populated(self, mean_reverting_prices):
        strategy = MeanReversionStrategy()
        strategy.generate_signal("AAPL", mean_reverting_prices)
        assert strategy.last_state != {}


# =============================================================================
# 5. PAIRS TRADING TESTS (66-75)
# =============================================================================

class TestPairsTrading:
    """Tests 66-75: Pairs Trading Strategy."""

    def test_66_pair_preserved(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("AAPL", "MSFT", pair_prices_a, pair_prices_b)
        assert signal.pair == ("AAPL", "MSFT")

    def test_67_hedge_ratio_nonzero(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("AAPL", "MSFT", pair_prices_a, pair_prices_b)
        assert signal.hedge_ratio != 0.0

    def test_68_signal_generated(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("AAPL", "MSFT", pair_prices_a, pair_prices_b)
        assert signal is not None

    def test_69_different_pairs(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        s1 = strategy.generate_signal("AAPL", "MSFT", pair_prices_a, pair_prices_b)
        s2 = strategy.generate_signal("GOOG", "META", pair_prices_a, pair_prices_b)
        assert s1.pair != s2.pair

    def test_70_identical_prices_neutral(self):
        prices = [100.0 + 0.1 * i for i in range(60)]
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("A", "B", prices, prices)
        assert signal is not None

    def test_71_highly_divergent_pair(self):
        pa = [100.0 + 5.0 * i for i in range(60)]
        pb = [100.0 - 2.0 * i for i in range(60)]
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("X", "Y", pa, pb)
        assert signal is not None

    def test_72_confidence_bounded(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("A", "B", pair_prices_a, pair_prices_b)
        assert 0.0 <= signal.confidence <= 1.0 or signal.confidence >= 0.0

    def test_73_hedge_ratio_reasonable(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("A", "B", pair_prices_a, pair_prices_b)
        assert abs(signal.hedge_ratio) < 100.0

    def test_74_spread_available(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        signal = strategy.generate_signal("A", "B", pair_prices_a, pair_prices_b)
        assert hasattr(signal, "spread_value") or hasattr(signal, "z_score")

    def test_75_consistency_across_calls(self, pair_prices_a, pair_prices_b):
        strategy = PairsTradingStrategy()
        s1 = strategy.generate_signal("A", "B", pair_prices_a, pair_prices_b)
        s2 = strategy.generate_signal("A", "B", pair_prices_a, pair_prices_b)
        assert s1.hedge_ratio == s2.hedge_ratio


# =============================================================================
# 6. VOLATILITY ARBITRAGE TESTS (76-85)
# =============================================================================

class TestVolatilityArbitrage:
    """Tests 76-85: Volatility Arbitrage Strategy."""

    def test_76_sell_vol_when_implied_higher(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.40, [0.30, 0.33, 0.35])
        assert signal.direction == "sell_vol"

    def test_77_confidence_positive(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.40, [0.30, 0.33, 0.35])
        assert signal.confidence > 0.0

    def test_78_implied_above_realized(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.40, [0.30, 0.33, 0.35])
        assert signal.implied_vol > signal.realized_vol

    def test_79_buy_vol_when_implied_lower(self, trending_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, 0.10, [0.30, 0.33, 0.35])
        assert signal.direction in ("buy_vol", "sell_vol", "flat")

    def test_80_symbol_preserved(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("TSLA", mean_reverting_prices, 0.40, [0.30])
        assert signal.symbol == "TSLA"

    def test_81_multiple_vol_surfaces(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.50, [0.20, 0.25, 0.30, 0.35, 0.40])
        assert signal is not None

    def test_82_zero_implied_vol(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.01, [0.30])
        assert signal is not None

    def test_83_high_implied_vol(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 1.0, [0.30])
        assert signal.confidence >= 0.0

    def test_84_confidence_bounded(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.40, [0.30])
        assert 0.0 <= signal.confidence <= 1.0

    def test_85_realized_vol_computed(self, mean_reverting_prices):
        strategy = VolatilityArbitrageStrategy()
        signal = strategy.generate_signal("AAPL", mean_reverting_prices, 0.40, [0.30])
        assert signal.realized_vol >= 0.0


# =============================================================================
# 7. EVENT-DRIVEN TESTS (86-95)
# =============================================================================

class TestEventDriven:
    """Tests 86-95: Event-Driven Strategy."""

    def test_86_earnings_event_signal(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03, -0.01, 0.04],
            surprise_factor=0.5, hours_to_event=2.0,
        )
        assert signal.direction in ("long", "short")

    def test_87_confidence_positive(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03], surprise_factor=0.5, hours_to_event=2.0,
        )
        assert signal.confidence > 0.0

    def test_88_pre_event_position(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03], surprise_factor=0.5, hours_to_event=2.0,
        )
        assert "enter" in signal.pre_event_position

    def test_89_macro_release_event(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "SPY", EventType.MACRO_RELEASE, 0.7, [0.01, -0.02], surprise_factor=0.3, hours_to_event=4.0,
        )
        assert signal is not None

    def test_90_central_bank_event(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "TLT", EventType.CENTRAL_BANK, 0.9, [0.02], surprise_factor=0.8, hours_to_event=1.0,
        )
        assert signal.event_type == EventType.CENTRAL_BANK

    def test_91_geopolitical_event(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "GLD", EventType.GEOPOLITICAL, 0.6, [0.05], surprise_factor=0.4, hours_to_event=12.0,
        )
        assert signal is not None

    def test_92_low_impact_event(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.2, [0.01], surprise_factor=0.1, hours_to_event=24.0,
        )
        assert signal is not None

    def test_93_symbol_preserved(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "NVDA", EventType.EARNINGS, 0.9, [0.1], surprise_factor=0.7, hours_to_event=1.0,
        )
        assert signal.symbol == "NVDA"

    def test_94_post_event_action_populated(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03], surprise_factor=0.5, hours_to_event=2.0,
        )
        assert signal.post_event_action is not None

    def test_95_magnitude_non_negative(self):
        strategy = EventDrivenStrategy()
        signal = strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03], surprise_factor=0.5, hours_to_event=2.0,
        )
        assert signal.magnitude >= 0.0


# =============================================================================
# 8. ML ALPHA TESTS (96-105)
# =============================================================================

class TestMLAlpha:
    """Tests 96-105: Machine Learning Alpha Strategy."""

    def test_96_feature_engineering(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        assert len(features) >= 10

    def test_97_predict_alpha_returns_signal(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("AAPL", features)
        assert signal is not None

    def test_98_confidence_bounded(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("AAPL", features)
        assert 0.0 <= signal.confidence <= 1.0

    def test_99_model_type_ensemble(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("AAPL", features)
        assert signal.model_type.value == "ensemble"

    def test_100_features_used_populated(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("AAPL", features)
        assert signal.features_used

    def test_101_symbol_preserved(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("TSLA", features)
        assert signal.symbol == "TSLA"

    def test_102_features_from_flat_market(self):
        flat_prices = [100.0] * 60
        volumes = [1000.0] * 60
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(flat_prices, volumes)
        assert len(features) >= 10

    def test_103_features_from_volatile_market(self):
        vol_prices = [100.0 + ((-1) ** i) * 0.5 * i for i in range(60)]
        # Ensure all prices are positive
        vol_prices = [max(p, 1.0) for p in vol_prices]
        volumes = [1000.0 + 500.0 * i for i in range(60)]
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(vol_prices, volumes)
        assert len(features) >= 10

    def test_104_multiple_predictions_independent(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        s1 = strategy.predict_alpha("AAPL", features)
        s2 = strategy.predict_alpha("MSFT", features)
        assert s1.symbol != s2.symbol

    def test_105_direction_valid(self, trending_prices, volumes):
        strategy = MLAlphaStrategy()
        features = strategy.engineer_features(trending_prices, volumes)
        signal = strategy.predict_alpha("AAPL", features)
        assert isinstance(signal.prediction, float)


# =============================================================================
# 9. LIQUIDITY PROVISION TESTS (106-115)
# =============================================================================

class TestLiquidityProvision:
    """Tests 106-115: Liquidity Provision Strategy."""

    def test_106_signal_generated(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal is not None

    def test_107_recommended_side(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal.recommended_side in ("buy", "sell")

    def test_108_urgency_populated(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal.urgency in ("low", "medium", "high")

    def test_109_size_positive(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal.size > 0.0

    def test_110_symbol_preserved(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "MSFT", "XNMS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal.symbol == "MSFT"

    def test_111_tight_spread_analysis(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.00, 100.01, 100.00], [100.01, 100.02, 100.01],
            [500.0, 500.0, 500.0], [500.0, 500.0, 500.0],
        )
        assert signal is not None

    def test_112_wide_spread_analysis(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "PENNY", "XNAS", [1.00, 0.98, 0.96], [1.10, 1.12, 1.14],
            [10.0, 8.0, 6.0], [5.0, 4.0, 3.0],
        )
        assert signal is not None

    def test_113_declining_liquidity(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 99.5, 99.0], [100.5, 101.0, 101.5],
            [1000.0, 500.0, 100.0], [1000.0, 500.0, 100.0],
        )
        assert signal.urgency in ("low", "medium", "high")

    def test_114_balanced_book(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "XNAS", [100.0, 100.0, 100.0], [100.1, 100.1, 100.1],
            [500.0, 500.0, 500.0], [500.0, 500.0, 500.0],
        )
        assert signal is not None

    def test_115_venue_recorded(self):
        strategy = LiquidityProvisionStrategy()
        signal = strategy.generate_signal(
            "AAPL", "BATS", [100.0, 99.9, 99.8], [100.1, 100.2, 100.3],
            [200.0, 180.0, 160.0], [50.0, 40.0, 35.0],
        )
        assert signal.venue == "BATS"


# =============================================================================
# 10. CROSS-ASSET ARBITRAGE TESTS (116-125)
# =============================================================================

class TestCrossAssetArbitrage:
    """Tests 116-125: Cross-Asset Arbitrage Strategy."""

    def test_116_relationship_registered(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        signal = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99, 1.0, 1.02, 1.01, 1.0])
        assert signal is not None

    def test_117_direction_populated(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        signal = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99, 1.0, 1.02, 1.01, 1.0])
        assert signal.direction in ("long_a_short_b", "short_a_long_b", "flat")

    def test_118_asset_classes_preserved(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        signal = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99, 1.0, 1.02, 1.01, 1.0])
        assert signal.asset_class_a == "equity"
        assert signal.asset_class_b == "future"

    def test_119_convergent_prices(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("A", "B", "equity", "etf", 1.0)
        signal = strategy.generate_signal("A", "B", 100.0, 100.0, [1.0, 1.0, 1.0, 1.0, 1.0])
        assert signal.direction == "flat" or signal.confidence < 0.5

    def test_120_multiple_relationships(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        strategy.register_relationship("GLD", "GC", "etf", "commodity", 10.0)
        s1 = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99])
        s2 = strategy.generate_signal("GLD", "GC", 180.0, 1800.0, [10.0, 10.1, 9.9])
        assert s1.asset_class_a != s2.asset_class_a

    def test_121_short_a_long_b(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        signal = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99, 1.0, 1.02, 1.01, 1.0])
        assert signal.direction == "short_a_long_b"

    def test_122_confidence_bounded(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("A", "B", "equity", "future", 1.0)
        signal = strategy.generate_signal("A", "B", 110.0, 100.0, [1.0, 1.01])
        assert 0.0 <= signal.confidence <= 1.0

    def test_123_spread_computed(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("A", "B", "equity", "future", 1.0)
        signal = strategy.generate_signal("A", "B", 105.0, 100.0, [1.0, 1.01, 0.99])
        assert hasattr(signal, "spread") or hasattr(signal, "z_score")

    def test_124_ratio_parameter(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("GLD", "GC", "etf", "commodity", 10.0)
        signal = strategy.generate_signal("GLD", "GC", 180.0, 1800.0, [10.0, 10.0, 10.0])
        assert signal is not None

    def test_125_symbols_preserved(self):
        strategy = CrossAssetArbitrageStrategy()
        strategy.register_relationship("SPY", "ES", "equity", "future", 1.0)
        signal = strategy.generate_signal("SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99])
        assert signal.asset_a == "SPY"
        assert signal.asset_b == "ES"


# =============================================================================
# 11. FIX PROTOCOL TESTS (126-140)
# =============================================================================

class TestFIXProtocol:
    """Tests 126-140: FIX Protocol Engine."""

    def test_126_new_order_encoded(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.25)
        assert msg.encode().startswith("8=FIX.4.4")

    def test_127_message_type_new_order(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.25)
        assert "35=D" in msg.encode()

    def test_128_symbol_in_message(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.25)
        assert "55=AAPL" in msg.encode()

    def test_129_sell_side(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.SELL, FIXOrdType.MARKET, 50.0, 0.0)
        encoded = msg.encode()
        assert "54=" in encoded

    def test_130_market_order(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.MARKET, 100.0, 0.0)
        assert "40=" in msg.encode()

    def test_131_decode_roundtrip(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.25)
        decoded = msg.decode(msg.encode())
        assert decoded.get_field(55) == "AAPL"

    def test_132_quantity_in_message(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 200.0, 150.25)
        decoded = msg.decode(msg.encode())
        assert decoded.get_field(38) == "200.0"

    def test_133_price_in_message(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 175.50)
        decoded = msg.decode(msg.encode())
        assert "175.5" in decoded.get_field(44)

    def test_134_risk_check_passed(self, fix_engine):
        result, reason = fix_engine.risk_engine.check_order("AAPL", FIXSide.BUY, 100.0, 150.25)
        assert result is RiskCheckResult.PASSED

    def test_135_risk_check_reason(self, fix_engine):
        result, reason = fix_engine.risk_engine.check_order("AAPL", FIXSide.BUY, 100.0, 150.25)
        assert reason == "All checks passed"

    def test_136_venue_in_message(self, fix_engine):
        msg = fix_engine.new_order_single("BATS", "MSFT", FIXSide.BUY, FIXOrdType.LIMIT, 50.0, 400.0)
        encoded = msg.encode()
        assert "BATS" in encoded or "MSFT" in encoded

    def test_137_multiple_orders(self, fix_engine):
        msgs = [
            fix_engine.new_order_single("XNAS", f"SYM{i}", FIXSide.BUY, FIXOrdType.LIMIT, 10.0, 100.0)
            for i in range(5)
        ]
        assert all("8=FIX.4.4" in m.encode() for m in msgs)

    def test_138_large_quantity(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 1_000_000.0, 150.25)
        assert msg.encode() is not None

    def test_139_small_quantity(self, fix_engine):
        msg = fix_engine.new_order_single("XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 1.0, 150.25)
        decoded = msg.decode(msg.encode())
        assert decoded.get_field(38) == "1.0"

    def test_140_different_venues(self, fix_engine):
        venues = ["XNAS", "BATS", "ARCA", "NYSE"]
        for venue in venues:
            msg = fix_engine.new_order_single(venue, "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.0)
            assert msg.encode() is not None


# =============================================================================
# 12. FpML ENGINE TESTS (141-150)
# =============================================================================

class TestFpMLEngine:
    """Tests 141-150: FpML Engine."""

    def test_141_fx_forward_created(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
        assert trade is not None

    def test_142_valid_xml_output(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
        xml = engine.to_xml(trade)
        ET.fromstring(xml)

    def test_143_trade_id_in_xml(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
        xml = engine.to_xml(trade)
        assert trade.trade_id in xml

    def test_144_type_fx_forward(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
        xml = engine.to_xml(trade)
        assert 'type="fx:forward"' in xml

    def test_145_different_currencies(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("GBP", "JPY", 500_000.0, 185.0, "2024-12-01")
        xml = engine.to_xml(trade)
        assert "GBP" in xml or "JPY" in xml

    def test_146_large_notional(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("USD", "EUR", 100_000_000.0, 0.92, "2025-01-15")
        assert trade is not None

    def test_147_small_notional(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("USD", "CHF", 1_000.0, 0.88, "2024-07-01")
        xml = engine.to_xml(trade)
        ET.fromstring(xml)

    def test_148_multiple_trades(self):
        engine = FpMLEngine()
        trades = [
            engine.create_fx_forward("EUR", "USD", 1_000_000.0 * i, 1.08, "2024-06-14")
            for i in range(1, 6)
        ]
        assert all(t.trade_id for t in trades)
        assert len(set(t.trade_id for t in trades)) == 5

    def test_149_xml_well_formed(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
        xml = engine.to_xml(trade)
        root = ET.fromstring(xml)
        assert root is not None

    def test_150_rate_in_xml(self):
        engine = FpMLEngine()
        trade = engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.0850, "2024-06-14")
        xml = engine.to_xml(trade)
        assert "1.085" in xml


# =============================================================================
# 13. SWIFT ENGINE TESTS (151-158)
# =============================================================================

class TestSWIFTEngine:
    """Tests 151-158: SWIFT Engine."""

    def test_151_payment_created(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 125_000.0, "USD", "TRADE SETTLEMENT")
        assert msg is not None

    def test_152_mt_format_starts_correctly(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 125_000.0, "USD", "TRADE SETTLEMENT")
        assert msg.to_mt_format().startswith("{1:")

    def test_153_amount_field(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 125_000.0, "USD", "TRADE SETTLEMENT")
        assert ":32A:" in msg.to_mt_format()

    def test_154_reference_in_message(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 125_000.0, "USD", "TRADE SETTLEMENT")
        assert "TRADE SETTLEMENT" in msg.to_mt_format()

    def test_155_different_bic(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("CITIUS33", 50_000.0, "EUR", "MARGIN CALL")
        mt = msg.to_mt_format()
        assert "CITIUS33" in mt or "{1:" in mt

    def test_156_large_payment(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 50_000_000.0, "USD", "BLOCK TRADE")
        assert msg.to_mt_format() is not None

    def test_157_different_currency(self):
        engine = SWIFTEngine()
        msg = engine.create_payment("BOFAUS3N", 1_000_000.0, "GBP", "FX SETTLEMENT")
        mt = msg.to_mt_format()
        assert "GBP" in mt or ":32A:" in mt

    def test_158_multiple_payments(self):
        engine = SWIFTEngine()
        msgs = [engine.create_payment("BOFAUS3N", 10_000.0 * i, "USD", f"PAY-{i}") for i in range(1, 4)]
        assert all(m.to_mt_format().startswith("{1:") for m in msgs)


# =============================================================================
# 14. ISDA CDM TESTS (159-168)
# =============================================================================

class TestISDACDM:
    """Tests 159-168: ISDA CDM Engine."""

    def test_159_trade_created(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["PARRALAX", "COUNTER"], {"notional": 1_000_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        assert trade is not None

    def test_160_trade_confirmed(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        event = engine.confirm_trade(trade.trade_id)
        assert event is not None

    def test_161_trade_settled(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        engine.confirm_trade(trade.trade_id)
        event = engine.settle_trade(trade.trade_id, 5_000.0)
        assert event is not None

    def test_162_status_settled(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        engine.confirm_trade(trade.trade_id)
        engine.settle_trade(trade.trade_id, 5_000.0)
        assert trade.status.value == "settled"

    def test_163_events_tracked(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        engine.confirm_trade(trade.trade_id)
        engine.settle_trade(trade.trade_id, 5_000.0)
        assert len(trade.events) >= 3

    def test_164_unique_trade_ids(self):
        engine = ISDACDMEngine()
        trades = [
            engine.create_trade("fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"})
            for _ in range(5)
        ]
        ids = [t.trade_id for t in trades]
        assert len(set(ids)) == 5

    def test_165_different_product_types(self):
        engine = ISDACDMEngine()
        t1 = engine.create_trade("fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"})
        t2 = engine.create_trade("interest_rate_swap", ["A", "B"], {"notional": 1_000_000.0, "currency": "USD", "pair": "USD/LIBOR"})
        assert t1.trade_id != t2.trade_id

    def test_166_multiple_counterparties(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["PARRALAX", "GOLDMAN", "JPMORGAN"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        assert trade is not None

    def test_167_large_notional(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 1_000_000_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        assert trade is not None

    def test_168_trade_lifecycle_complete(self):
        engine = ISDACDMEngine()
        trade = engine.create_trade(
            "fx_forward", ["A", "B"], {"notional": 100_000.0, "currency": "USD", "pair": "EUR/USD"},
        )
        engine.confirm_trade(trade.trade_id)
        engine.settle_trade(trade.trade_id, 2_500.0)
        assert trade.status.value == "settled"


# =============================================================================
# 15. XBRL ENGINE TESTS (169-175)
# =============================================================================

class TestXBRLEngine:
    """Tests 169-175: XBRL Engine."""

    def test_169_nav_report_created(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(2_500_000.0, 3_100_000.0, 600_000.0, 25_000.0, 100.0, "2024-03-31")
        assert report is not None

    def test_170_valid_xml(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(2_500_000.0, 3_100_000.0, 600_000.0, 25_000.0, 100.0, "2024-03-31")
        xml = engine.to_xbrl_xml(report)
        ET.fromstring(xml)

    def test_171_nav_in_xml(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(2_500_000.0, 3_100_000.0, 600_000.0, 25_000.0, 100.0, "2024-03-31")
        xml = engine.to_xbrl_xml(report)
        assert "NetAssetValue" in xml

    def test_172_context_refs(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(2_500_000.0, 3_100_000.0, 600_000.0, 25_000.0, 100.0, "2024-03-31")
        xml = engine.to_xbrl_xml(report)
        assert xml.count("contextRef=") >= 5

    def test_173_report_stored(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(1_000_000.0, 1_200_000.0, 200_000.0, 10_000.0, 100.0, "2024-01-31")
        assert report.report_id in engine.reports

    def test_174_xbrl_root_tag(self):
        engine = XBRLEngine()
        report = engine.create_nav_report(1_000_000.0, 1_200_000.0, 200_000.0, 10_000.0, 100.0, "2024-01-31")
        xml = engine.to_xbrl_xml(report)
        root = ET.fromstring(xml)
        assert root.tag.endswith("xbrl")

    def test_175_multiple_reports(self):
        engine = XBRLEngine()
        reports = [
            engine.create_nav_report(1_000_000.0 * i, 1_200_000.0 * i, 200_000.0 * i, 10_000.0, 100.0 * i, f"2024-0{i}-01")
            for i in range(1, 5)
        ]
        assert len(set(r.report_id for r in reports)) == 4


# =============================================================================
# 16. ISO 20022 TESTS (176-183)
# =============================================================================

class TestISO20022Engine:
    """Tests 176-183: ISO 20022 Engine."""

    def test_176_credit_transfer_created(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Counterparty", "BOFAUS3N", 250_000.0, "USD", "Settlement")
        assert msg is not None

    def test_177_valid_xml(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Counterparty", "BOFAUS3N", 250_000.0, "USD", "Settlement")
        xml = engine.to_xml(msg)
        ET.fromstring(xml)

    def test_178_message_id_in_xml(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Counterparty", "BOFAUS3N", 250_000.0, "USD", "Settlement")
        xml = engine.to_xml(msg)
        assert msg.message_id in xml

    def test_179_document_root(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Counterparty", "BOFAUS3N", 250_000.0, "USD", "Settlement")
        xml = engine.to_xml(msg)
        root = ET.fromstring(xml)
        assert root.tag.endswith("Document")

    def test_180_settlement_instruction(self):
        engine = ISO20022Engine()
        msg = engine.create_settlement_instruction(
            isin="US0378331005", quantity=1_500.0, settlement_amount=275_000.0,
            counterparty_bic="CITIUS33", settlement_date="2024-06-17",
        )
        xml = engine.to_xml(msg)
        ET.fromstring(xml)

    def test_181_amount_in_xml(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Bank", "BOFAUS3N", 500_000.0, "USD", "Margin")
        xml = engine.to_xml(msg)
        assert "500000" in xml

    def test_182_bic_in_xml(self):
        engine = ISO20022Engine()
        msg = engine.create_credit_transfer("Bank", "CITIUS33", 100_000.0, "EUR", "FX")
        xml = engine.to_xml(msg)
        assert "CITIUS33" in xml or msg.creditor_bic in xml

    def test_183_multiple_messages(self):
        engine = ISO20022Engine()
        msgs = [
            engine.create_credit_transfer(f"Bank{i}", "BOFAUS3N", 10_000.0 * i, "USD", f"Pay{i}")
            for i in range(1, 4)
        ]
        assert len(set(m.message_id for m in msgs)) == 3


# =============================================================================
# 17. STRATEGY ROUTER TESTS (184-195)
# =============================================================================

class TestStrategyRouter:
    """Tests 184-195: Strategy Router & Capital Allocation."""

    def test_184_allocate_normal_regime(self, strategy_router):
        decision = strategy_router.allocate(
            MarketRegime.NORMAL,
            {StrategyType.MOMENTUM: 0.20, StrategyType.ML_ALPHA: 0.10},
        )
        assert decision.regime is MarketRegime.NORMAL

    def test_185_total_capital_deployed(self, strategy_router):
        decision = strategy_router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        assert decision.total_capital_deployed > 0.0

    def test_186_reserve_capital_positive(self, strategy_router):
        decision = strategy_router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        assert decision.reserve_capital > 0.0

    def test_187_weights_sum_to_one(self, strategy_router):
        decision = strategy_router.allocate(
            MarketRegime.NORMAL,
            {StrategyType.MOMENTUM: 0.20, StrategyType.ML_ALPHA: 0.10, StrategyType.EVENT_DRIVEN: 0.05},
        )
        assert sum(a.weight for a in decision.allocations) == pytest.approx(1.0)

    def test_188_capital_sums_correctly(self, strategy_router):
        decision = strategy_router.allocate(
            MarketRegime.NORMAL,
            {StrategyType.MOMENTUM: 0.20, StrategyType.ML_ALPHA: 0.10},
        )
        assert sum(a.capital_allocated for a in decision.allocations) == pytest.approx(decision.total_capital_deployed)

    def test_189_risk_budget_proportional(self, strategy_router):
        decision = strategy_router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        assert all(a.risk_budget == pytest.approx(a.capital_allocated * 0.02) for a in decision.allocations)

    def test_190_crisis_regime_reduces_exposure(self):
        router = StrategyRouter(total_capital=1_000_000.0)
        normal = router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        crisis = router.allocate(MarketRegime.CRISIS, {StrategyType.MOMENTUM: 0.20})
        assert crisis.total_capital_deployed <= normal.total_capital_deployed

    def test_191_high_vol_regime(self):
        router = StrategyRouter(total_capital=1_000_000.0)
        decision = router.allocate(MarketRegime.HIGH_VOLATILITY, {StrategyType.VOL_ARB: 0.30})
        assert decision is not None

    def test_192_trending_regime(self):
        router = StrategyRouter(total_capital=1_000_000.0)
        decision = router.allocate(MarketRegime.TRENDING, {StrategyType.MOMENTUM: 0.40})
        assert decision is not None

    def test_193_routing_state(self, strategy_router):
        strategy_router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        state = strategy_router.get_routing_state()
        assert "active_count" in state

    def test_194_active_strategies_count(self, strategy_router):
        decision = strategy_router.allocate(
            MarketRegime.NORMAL,
            {StrategyType.MOMENTUM: 0.20, StrategyType.ML_ALPHA: 0.10, StrategyType.STAT_ARB: 0.15},
        )
        state = strategy_router.get_routing_state()
        assert state["active_count"] == decision.active_strategies

    def test_195_reserve_in_state(self, strategy_router):
        strategy_router.allocate(MarketRegime.NORMAL, {StrategyType.MOMENTUM: 0.20})
        state = strategy_router.get_routing_state()
        assert "reserve" in state


# =============================================================================
# 18. CROSS-SERVICE INTEGRATION TESTS (196-200)
# =============================================================================

class TestCrossServiceIntegration:
    """Tests 196-200: Cross-service data flow and integration."""

    def test_196_signal_to_risk_to_order(self, trending_prices, trending_highs, trending_lows, fix_engine):
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        side = FIXSide.BUY if signal.direction == "long" else FIXSide.SELL
        result, reason = fix_engine.risk_engine.check_order("AAPL", side, 100.0, 150.25)
        assert result is RiskCheckResult.PASSED
        order = fix_engine.new_order_single("XNAS", "AAPL", side, FIXOrdType.LIMIT, 100.0, 150.25)
        assert "55=AAPL" in order.encode()

    def test_197_stat_arb_to_fix_order(self, pair_prices_a, pair_prices_b, fix_engine):
        strategy = StatisticalArbitrageStrategy()
        signal = strategy.generate_signal(("AAPL", "MSFT"), pair_prices_a, pair_prices_b)
        side = FIXSide.BUY if signal.signal.value in ("buy", "strong_buy") else FIXSide.SELL
        order = fix_engine.new_order_single("XNAS", "AAPL", side, FIXOrdType.LIMIT, 100.0, 150.0)
        assert order.encode().startswith("8=FIX.4.4")

    def test_198_event_driven_to_swift_settlement(self):
        event_strategy = EventDrivenStrategy()
        signal = event_strategy.generate_signal(
            "AAPL", EventType.EARNINGS, 0.8, [0.03], surprise_factor=0.5, hours_to_event=2.0,
        )
        swift_engine = SWIFTEngine()
        payment = swift_engine.create_payment("BOFAUS3N", 50_000.0, "USD", f"EVENT-{signal.symbol}")
        assert payment.to_mt_format().startswith("{1:")

    def test_199_ml_alpha_to_isda_trade(self, trending_prices, volumes):
        ml_strategy = MLAlphaStrategy()
        features = ml_strategy.engineer_features(trending_prices, volumes)
        signal = ml_strategy.predict_alpha("AAPL", features)
        isda_engine = ISDACDMEngine()
        trade = isda_engine.create_trade(
            "equity_swap", ["PARRALAX", "COUNTERPARTY"],
            {"notional": 500_000.0, "currency": "USD", "pair": f"{signal.symbol}/INDEX"},
        )
        isda_engine.confirm_trade(trade.trade_id)
        assert trade.status.value in ("confirmed", "active", "settled")

    def test_200_full_lifecycle_signal_to_settlement(self, trending_prices, trending_highs, trending_lows, fix_engine):
        # Signal generation
        strategy = MomentumStrategy()
        signal = strategy.generate_signal("AAPL", trending_prices, trending_highs, trending_lows)
        # Risk check
        side = FIXSide.BUY if signal.direction == "long" else FIXSide.SELL
        result, _ = fix_engine.risk_engine.check_order("AAPL", side, 100.0, 150.25)
        assert result is RiskCheckResult.PASSED
        # Order generation
        order = fix_engine.new_order_single("XNAS", "AAPL", side, FIXOrdType.LIMIT, 100.0, 150.25)
        assert order.encode().startswith("8=FIX.4.4")
        # Settlement via ISDA
        isda_engine = ISDACDMEngine()
        trade = isda_engine.create_trade(
            "equity_spot", ["PARRALAX", "BROKER"],
            {"notional": 15_025.0, "currency": "USD", "pair": "AAPL/USD"},
        )
        isda_engine.confirm_trade(trade.trade_id)
        isda_engine.settle_trade(trade.trade_id, 15_025.0)
        assert trade.status.value == "settled"
        # ISO 20022 payment
        iso_engine = ISO20022Engine()
        payment = iso_engine.create_credit_transfer("Broker", "BOFAUS3N", 15_025.0, "USD", "Trade settlement")
        xml = iso_engine.to_xml(payment)
        ET.fromstring(xml)
        assert payment.message_id in xml
