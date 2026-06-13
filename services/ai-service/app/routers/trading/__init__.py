"""Trading Strategy API Router — Strategy routing, signals, and allocation."""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from app.strategies import (
    StrategyRouter,
    StatisticalArbitrageStrategy,
    MarketMakingStrategy,
    MomentumStrategy,
    MeanReversionStrategy,
    PairsTradingStrategy,
    VolatilityArbitrageStrategy,
    MLAlphaStrategy,
    EventDrivenStrategy,
)
from app.strategies.strategy_router import MarketRegime, StrategyType

router = APIRouter()

# Initialize all strategies
strategy_router = StrategyRouter(total_capital=10_000_000.0)
stat_arb = StatisticalArbitrageStrategy()
market_maker = MarketMakingStrategy()
momentum = MomentumStrategy()
mean_reversion = MeanReversionStrategy()
pairs = PairsTradingStrategy()
vol_arb = VolatilityArbitrageStrategy()
ml_alpha = MLAlphaStrategy()
event_driven = EventDrivenStrategy()


class RegimeDetectionRequest(BaseModel):
    returns: list[float]
    volatility: float
    trend_strength: float
    correlation_breakdown: bool = False


class AllocationRequest(BaseModel):
    regime: str = "normal"
    strategy_performance: dict[str, float] | None = None


class StatArbRequest(BaseModel):
    pair: list[str]
    prices_a: list[float]
    prices_b: list[float]


class MarketMakingRequest(BaseModel):
    symbol: str
    mid_price: float
    inventory: float = 0.0
    time_remaining: float = 1.0
    volatility: float | None = None


class MomentumRequest(BaseModel):
    symbol: str
    prices: list[float]
    highs: list[float] | None = None
    lows: list[float] | None = None


class MeanReversionRequest(BaseModel):
    symbol: str
    prices: list[float]


class VolArbRequest(BaseModel):
    symbol: str
    prices: list[float]
    implied_vol: float
    term_structure: list[float] | None = None


class MLAlphaRequest(BaseModel):
    symbol: str
    prices: list[float]
    volumes: list[float] | None = None


class EventRequest(BaseModel):
    symbol: str
    event_type: str
    sentiment_score: float
    historical_moves: list[float] | None = None
    surprise_factor: float = 0.0
    hours_to_event: float = 0.0


class DeleverageRequest(BaseModel):
    target_pct: float = 0.50


@router.post("/trading/regime-detect")
async def detect_regime(body: RegimeDetectionRequest) -> dict:
    """Detect current market regime."""
    regime, confidence = strategy_router.detect_regime(
        body.returns, body.volatility, body.trend_strength, body.correlation_breakdown
    )
    return {"regime": regime.value, "confidence": confidence}


@router.post("/trading/allocate")
async def allocate_capital(body: AllocationRequest) -> dict:
    """Allocate capital across strategies based on regime."""
    regime = MarketRegime(body.regime)
    perf = None
    if body.strategy_performance:
        perf = {StrategyType(k): v for k, v in body.strategy_performance.items()}

    decision = strategy_router.allocate(regime, perf)
    return {
        "regime": decision.regime.value,
        "total_deployed": decision.total_capital_deployed,
        "reserve": decision.reserve_capital,
        "active_strategies": decision.active_strategies,
        "regime_confidence": decision.regime_confidence,
        "allocations": [
            {
                "strategy": a.strategy_type.value,
                "weight": a.weight,
                "capital": a.capital_allocated,
                "risk_budget": a.risk_budget,
                "active": a.is_active,
            }
            for a in decision.allocations
        ],
    }


@router.get("/trading/routing-state")
async def routing_state() -> dict:
    """Get current strategy routing state."""
    return strategy_router.get_routing_state()


@router.post("/trading/signal/stat-arb")
async def stat_arb_signal(body: StatArbRequest) -> dict:
    """Generate statistical arbitrage signal."""
    signal = stat_arb.generate_signal(
        tuple(body.pair), body.prices_a, body.prices_b
    )
    return {
        "pair": list(signal.pair),
        "z_score": signal.z_score,
        "half_life": signal.half_life,
        "signal": signal.signal.value,
        "confidence": signal.confidence,
        "hedge_ratio": signal.hedge_ratio,
        "spread": signal.spread_value,
    }


@router.post("/trading/signal/market-making")
async def market_making_signal(body: MarketMakingRequest) -> dict:
    """Generate market making quotes."""
    quote = market_maker.generate_quotes(
        body.symbol, body.mid_price, body.inventory, body.time_remaining, body.volatility
    )
    return {
        "symbol": quote.symbol,
        "bid": quote.bid_price,
        "ask": quote.ask_price,
        "bid_size": quote.bid_size,
        "ask_size": quote.ask_size,
        "spread": quote.spread,
        "skew": quote.skew,
    }


@router.post("/trading/signal/momentum")
async def momentum_signal(body: MomentumRequest) -> dict:
    """Generate momentum signal."""
    signal = momentum.generate_signal(body.symbol, body.prices, body.highs, body.lows)
    return {
        "symbol": signal.symbol,
        "direction": signal.direction,
        "strength": signal.strength,
        "momentum_score": signal.momentum_score,
        "trend_quality": signal.trend_quality,
        "breakout_level": signal.breakout_level,
    }


@router.post("/trading/signal/mean-reversion")
async def mean_reversion_signal(body: MeanReversionRequest) -> dict:
    """Generate mean reversion signal."""
    signal = mean_reversion.generate_signal(body.symbol, body.prices)
    return {
        "symbol": signal.symbol,
        "direction": signal.direction,
        "distance_from_mean": signal.distance_from_mean,
        "bollinger_position": signal.bollinger_position,
        "rsi": signal.rsi,
        "mean_target": signal.mean_target,
        "confidence": signal.confidence,
    }


@router.post("/trading/signal/vol-arb")
async def vol_arb_signal(body: VolArbRequest) -> dict:
    """Generate volatility arbitrage signal."""
    signal = vol_arb.generate_signal(
        body.symbol, body.prices, body.implied_vol, body.term_structure
    )
    return {
        "symbol": signal.symbol,
        "implied_vol": signal.implied_vol,
        "realized_vol": signal.realized_vol,
        "vol_spread": signal.vol_spread,
        "direction": signal.direction,
        "confidence": signal.confidence,
        "term_structure_slope": signal.term_structure_slope,
    }


@router.post("/trading/signal/ml-alpha")
async def ml_alpha_signal(body: MLAlphaRequest) -> dict:
    """Generate ML alpha prediction."""
    features = ml_alpha.engineer_features(body.prices, body.volumes)
    signal = ml_alpha.predict_alpha(body.symbol, features)
    return {
        "symbol": signal.symbol,
        "prediction": signal.prediction,
        "confidence": signal.confidence,
        "model_type": signal.model_type.value,
        "features_used": len(signal.features_used),
        "ensemble_agreement": signal.ensemble_agreement,
        "top_features": dict(list(signal.feature_importance.items())[:5]),
    }


@router.post("/trading/signal/event-driven")
async def event_driven_signal(body: EventRequest) -> dict:
    """Generate event-driven signal."""
    from app.strategies.event_driven import EventType as ET
    signal = event_driven.generate_signal(
        body.symbol, ET(body.event_type), body.sentiment_score,
        body.historical_moves, body.surprise_factor, body.hours_to_event,
    )
    return {
        "symbol": signal.symbol,
        "event_type": signal.event_type.value,
        "impact": signal.impact.value,
        "direction": signal.direction,
        "magnitude": signal.magnitude,
        "pre_event_position": signal.pre_event_position,
        "post_event_action": signal.post_event_action,
        "confidence": signal.confidence,
    }


@router.post("/trading/emergency-deleverage")
async def emergency_deleverage(body: DeleverageRequest) -> dict:
    """Emergency deleveraging across all strategies."""
    return strategy_router.emergency_deleverage(body.target_pct)
