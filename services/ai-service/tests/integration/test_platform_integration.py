# ruff: noqa: S101, S314
from __future__ import annotations

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
from app.strategies.strategy_router import MarketRegime, StrategyType


def test_all_trading_strategies_generate_signals() -> None:
    trending_prices = [100.0 + 0.7 * i for i in range(60)]
    trending_highs = [price + 1.2 for price in trending_prices]
    trending_lows = [price - 1.2 for price in trending_prices]
    mean_reverting_prices = [100.0 + ((i % 5) - 2) * 0.12 for i in range(59)] + [95.0]
    pair_prices_b = [50.0 + 0.15 * i + ((i % 4) - 1.5) * 0.02 for i in range(60)]
    pair_prices_a = [100.0 + 0.3 * i + ((i % 3) - 1) * 0.03 for i in range(59)] + [124.5]
    volumes = [1_000.0 + 25.0 * i for i in range(60)]

    stat_signal = StatisticalArbitrageStrategy().generate_signal(
        ("AAPL", "MSFT"), pair_prices_a, pair_prices_b
    )
    market_quote = MarketMakingStrategy().generate_quotes("BTC-USD", 100.0)
    momentum_signal = MomentumStrategy().generate_signal(
        "AAPL", trending_prices, trending_highs, trending_lows
    )
    mean_reversion_signal = MeanReversionStrategy().generate_signal(
        "AAPL", mean_reverting_prices
    )
    pairs_signal = PairsTradingStrategy().generate_signal(
        "AAPL", "MSFT", pair_prices_a, pair_prices_b
    )
    vol_signal = VolatilityArbitrageStrategy().generate_signal(
        "AAPL", mean_reverting_prices, 0.40, [0.30, 0.33, 0.35]
    )
    liquidity_signal = LiquidityProvisionStrategy().generate_signal(
        "AAPL",
        "XNAS",
        [100.0, 99.9, 99.8],
        [100.1, 100.2, 100.3],
        [200.0, 180.0, 160.0],
        [50.0, 40.0, 35.0],
    )
    cross_asset = CrossAssetArbitrageStrategy()
    cross_asset.register_relationship("SPY", "ES", "equity", "future", 1.0)
    cross_asset_signal = cross_asset.generate_signal(
        "SPY", "ES", 105.0, 100.0, [1.0, 1.01, 0.99, 1.0, 1.02, 1.01, 1.0]
    )
    event_signal = EventDrivenStrategy().generate_signal(
        "AAPL",
        EventType.EARNINGS,
        0.8,
        [0.03, -0.01, 0.04],
        surprise_factor=0.5,
        hours_to_event=2.0,
    )
    ml_strategy = MLAlphaStrategy()
    ml_features = ml_strategy.engineer_features(trending_prices, volumes)
    ml_signal = ml_strategy.predict_alpha("AAPL", ml_features)

    assert stat_signal.pair == ("AAPL", "MSFT")
    assert stat_signal.hedge_ratio != 0.0
    assert 0.0 <= stat_signal.confidence <= 1.0

    assert market_quote.symbol == "BTC-USD"
    assert market_quote.bid_price < market_quote.ask_price
    assert market_quote.bid_size > 0.0
    assert market_quote.ask_size > 0.0

    assert momentum_signal.direction == "long"
    assert momentum_signal.strength > 0.0
    assert momentum_signal.breakout_level > trending_prices[-1]

    assert mean_reversion_signal.direction == "long"
    assert mean_reversion_signal.confidence > 0.0
    assert mean_reversion_signal.mean_target > mean_reverting_prices[-1]

    assert pairs_signal.pair == ("AAPL", "MSFT")
    assert pairs_signal.hedge_ratio != 0.0

    assert vol_signal.direction == "sell_vol"
    assert vol_signal.confidence > 0.0
    assert vol_signal.implied_vol > vol_signal.realized_vol

    assert liquidity_signal.recommended_side == "sell"
    assert liquidity_signal.urgency == "high"
    assert liquidity_signal.size > 0.0

    assert cross_asset_signal.direction == "short_a_long_b"
    assert cross_asset_signal.asset_class_a == "equity"
    assert cross_asset_signal.asset_class_b == "future"

    assert event_signal.direction == "long"
    assert "enter" in event_signal.pre_event_position
    assert event_signal.confidence > 0.0

    assert len(ml_features) >= 10
    assert ml_signal.model_type.value == "ensemble"
    assert ml_signal.features_used
    assert 0.0 <= ml_signal.confidence <= 1.0


def test_financial_language_engines_generate_valid_output() -> None:
    fix_engine = FIXEngine()
    fix_message = fix_engine.new_order_single(
        "XNAS", "AAPL", FIXSide.BUY, FIXOrdType.LIMIT, 100.0, 150.25
    )
    encoded_fix = fix_message.encode()

    fpml_engine = FpMLEngine()
    fpml_trade = fpml_engine.create_fx_forward("EUR", "USD", 1_000_000.0, 1.08, "2024-06-14")
    fpml_xml = fpml_engine.to_xml(fpml_trade)

    swift_engine = SWIFTEngine()
    swift_message = swift_engine.create_payment(
        "BOFAUS3N", 125_000.0, "USD", "TRADE SETTLEMENT"
    )
    swift_mt = swift_message.to_mt_format()

    isda_engine = ISDACDMEngine()
    isda_trade = isda_engine.create_trade(
        "fx_forward",
        ["PARRALAX", "COUNTERPARTY"],
        {"notional": 1_000_000.0, "currency": "USD", "pair": "EUR/USD"},
    )
    confirmation_event = isda_engine.confirm_trade(isda_trade.trade_id)
    settlement_event = isda_engine.settle_trade(isda_trade.trade_id, 12_500.0)

    xbrl_engine = XBRLEngine()
    xbrl_report = xbrl_engine.create_nav_report(
        1_000_000.0, 1_250_000.0, 250_000.0, 10_000.0, 100.0, "2024-01-31"
    )
    xbrl_xml = xbrl_engine.to_xbrl_xml(xbrl_report)

    iso_engine = ISO20022Engine()
    iso_message = iso_engine.create_credit_transfer(
        "Counterparty Bank", "BOFAUS3N", 250_000.0, "USD", "Prime brokerage settlement"
    )
    iso_xml = iso_engine.to_xml(iso_message)

    assert encoded_fix.startswith("8=FIX.4.4")
    assert "35=D" in encoded_fix
    assert "55=AAPL" in encoded_fix

    ET.fromstring(fpml_xml)
    assert fpml_trade.trade_id in fpml_xml
    assert 'type="fx:forward"' in fpml_xml

    assert swift_mt.startswith("{1:")
    assert ":32A:" in swift_mt
    assert "TRADE SETTLEMENT" in swift_mt

    assert confirmation_event is not None
    assert settlement_event is not None
    assert isda_trade.status.value == "settled"
    assert len(isda_trade.events) >= 3

    ET.fromstring(xbrl_xml)
    assert xbrl_report.report_id in xbrl_engine.reports
    assert "NetAssetValue" in xbrl_xml

    ET.fromstring(iso_xml)
    assert iso_message.message_id in iso_xml
    assert iso_message.creditor_bic in iso_xml


def test_strategy_router_allocates_capital_correctly() -> None:
    router = StrategyRouter(total_capital=1_000_000.0)
    decision = router.allocate(
        MarketRegime.NORMAL,
        {
            StrategyType.MOMENTUM: 0.20,
            StrategyType.ML_ALPHA: 0.10,
            StrategyType.EVENT_DRIVEN: 0.05,
        },
    )

    allocations = {allocation.strategy_type: allocation for allocation in decision.allocations}
    state = router.get_routing_state()

    assert decision.regime is MarketRegime.NORMAL
    assert decision.total_capital_deployed == pytest.approx(850_000.0)
    assert decision.reserve_capital == pytest.approx(150_000.0)
    assert sum(item.weight for item in decision.allocations) == pytest.approx(1.0)
    assert sum(item.capital_allocated for item in decision.allocations) == pytest.approx(
        decision.total_capital_deployed
    )
    assert allocations[StrategyType.MOMENTUM].capital_allocated > allocations[
        StrategyType.CROSS_ASSET
    ].capital_allocated
    assert allocations[StrategyType.ML_ALPHA].capital_allocated > allocations[
        StrategyType.EVENT_DRIVEN
    ].capital_allocated
    assert all(
        allocation.risk_budget == pytest.approx(allocation.capital_allocated * 0.02)
        for allocation in decision.allocations
    )
    assert state["active_count"] == decision.active_strategies
    assert state["reserve"] == pytest.approx(150_000.0)


def test_xbrl_engine_generates_valid_xml() -> None:
    engine = XBRLEngine()
    report = engine.create_nav_report(
        nav=2_500_000.0,
        total_assets=3_100_000.0,
        total_liabilities=600_000.0,
        shares_outstanding=25_000.0,
        nav_per_share=100.0,
        reporting_date="2024-03-31",
    )

    xml_output = engine.to_xbrl_xml(report)
    root = ET.fromstring(xml_output)
    serialized = ET.tostring(root, encoding="unicode")

    assert root.tag.endswith("xbrl")
    assert "0001234567" in xml_output or "PARRALAX" in xml_output
    assert "NetAssetValue" in serialized
    assert serialized.count("contextRef=") >= 5


def test_iso_20022_engine_generates_valid_xml_messages() -> None:
    engine = ISO20022Engine()
    credit_transfer = engine.create_credit_transfer(
        "Prime Broker", "BOFAUS3N", 250_000.0, "USD", "Margin top-up"
    )
    settlement_instruction = engine.create_settlement_instruction(
        isin="US0378331005",
        quantity=1_500.0,
        settlement_amount=275_000.0,
        counterparty_bic="CITIUS33",
        settlement_date="2024-06-17",
    )

    credit_transfer_xml = engine.to_xml(credit_transfer)
    settlement_xml = engine.to_xml(settlement_instruction)

    credit_transfer_root = ET.fromstring(credit_transfer_xml)
    settlement_root = ET.fromstring(settlement_xml)

    assert credit_transfer_root.tag.endswith("Document")
    assert settlement_root.tag.endswith("Document")
    assert credit_transfer.message_id in credit_transfer_xml
    assert settlement_instruction.message_id in settlement_xml
    assert "InstdAmt" in credit_transfer_xml
    assert "275000.00" in settlement_xml


def test_cross_service_data_flow_from_signal_to_risk_to_order_generation() -> None:
    momentum_strategy = MomentumStrategy()
    fix_engine = FIXEngine()
    prices = [100.0 + 0.8 * i for i in range(60)]
    highs = [price + 1.0 for price in prices]
    lows = [price - 1.0 for price in prices]

    signal = momentum_strategy.generate_signal("AAPL", prices, highs, lows)
    side = FIXSide.BUY if signal.direction == "long" else FIXSide.SELL
    risk_result, risk_reason = fix_engine.risk_engine.check_order("AAPL", side, 100.0, 150.25)

    assert signal.direction == "long"
    assert risk_result is RiskCheckResult.PASSED
    assert risk_reason == "All checks passed"

    order = fix_engine.new_order_single(
        "XNAS", "AAPL", side, FIXOrdType.LIMIT, 100.0, 150.25
    )
    decoded_order = order.decode(order.encode())

    assert decoded_order.get_field(55) == "AAPL"
    assert decoded_order.get_field(54) == FIXSide.BUY.value
    assert decoded_order.get_field(38) == "100.0"
    assert decoded_order.get_field(44) == "150.25000000"
