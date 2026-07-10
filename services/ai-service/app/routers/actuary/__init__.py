"""Actuary Suite API Router — Risk, Insurance, Greeks, Lifecycle, Reserves."""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from app.actuary import (
    RiskPricingEngine,
    GreeksEngine,
    PortfolioInsuranceEngine,
    StrategyLifecycleModel,
    ReserveEngine,
)

router = APIRouter()

# Initialize engines
risk_engine = RiskPricingEngine()
greeks_engine = GreeksEngine()
insurance_engine = PortfolioInsuranceEngine()
lifecycle_model = StrategyLifecycleModel()
reserve_engine = ReserveEngine()


class RiskAssessmentRequest(BaseModel):
    returns: list[float]


class GreeksRequest(BaseModel):
    spot: float
    strike: float
    time_to_expiry: float
    risk_free_rate: float = 0.05
    volatility: float = 0.20
    is_call: bool = True


class PortfolioGreeksRequest(BaseModel):
    positions: list[dict]


class InsuranceRequest(BaseModel):
    portfolio_value: float


class LifecycleRequest(BaseModel):
    strategy_id: str
    initial_alpha: float = 0.05
    capacity: float = 1000000.0


class ReserveRequest(BaseModel):
    portfolio_var_99: float
    annual_revenue: float
    strategy_count: int
    daily_volume: float = 1000000.0
    position_size: float = 500000.0
    market_depth: float = 100000.0
    annual_tech_spend: float = 500000.0


class RiskBudgetRequest(BaseModel):
    strategy_returns: dict[str, list[float]]
    total_risk_budget: float


@router.post("/actuary/risk-assessment")
async def risk_assessment(body: RiskAssessmentRequest) -> dict:
    """Full actuarial risk assessment — VaR, CVaR, Sharpe, tail risk."""
    metrics = risk_engine.full_risk_assessment(body.returns)
    return {
        "var_95": metrics.var_95,
        "var_99": metrics.var_99,
        "cvar_95": metrics.cvar_95,
        "cvar_99": metrics.cvar_99,
        "max_drawdown": metrics.max_drawdown,
        "sharpe_ratio": metrics.sharpe_ratio,
        "sortino_ratio": metrics.sortino_ratio,
        "calmar_ratio": metrics.calmar_ratio,
        "tail_index": metrics.tail_index,
        "expected_shortfall": metrics.expected_shortfall,
    }


@router.post("/actuary/greeks")
async def calculate_greeks(body: GreeksRequest) -> dict:
    """Calculate all options Greeks for a position."""
    result = greeks_engine.calculate_all(
        spot=body.spot,
        strike=body.strike,
        time_to_expiry=body.time_to_expiry,
        risk_free_rate=body.risk_free_rate,
        volatility=body.volatility,
        is_call=body.is_call,
    )
    return {
        "delta": result.delta,
        "gamma": result.gamma,
        "vega": result.vega,
        "theta": result.theta,
        "rho": result.rho,
    }


@router.post("/actuary/portfolio-greeks")
async def portfolio_greeks(body: PortfolioGreeksRequest) -> dict:
    """Aggregate Greeks across a portfolio."""
    return greeks_engine.portfolio_greeks(body.positions)


@router.post("/actuary/insurance")
async def insurance_report(body: InsuranceRequest) -> dict:
    """Portfolio insurance analysis — CPPI and OBPI."""
    return insurance_engine.get_protection_report(body.portfolio_value)


@router.post("/actuary/lifecycle/register")
async def register_strategy(body: LifecycleRequest) -> dict:
    """Register strategy for lifecycle tracking."""
    lifecycle_model.register_strategy(
        body.strategy_id, body.initial_alpha, body.capacity
    )
    return {"status": "registered", "strategy_id": body.strategy_id}


@router.get("/actuary/lifecycle/{strategy_id}")
async def get_lifecycle(strategy_id: str) -> dict:
    """Get strategy lifecycle metrics."""
    metrics = lifecycle_model.assess_strategy(strategy_id)
    if not metrics:
        return {"error": "strategy not found"}
    return {
        "strategy_id": metrics.strategy_id,
        "state": metrics.state.value,
        "age_days": metrics.age_days,
        "expected_remaining_life": metrics.expected_remaining_life,
        "hazard_rate": metrics.hazard_rate,
        "survival_probability": metrics.survival_probability,
        "alpha_decay_rate": metrics.alpha_decay_rate,
        "capacity_utilization": metrics.capacity_utilization,
    }


@router.get("/actuary/lifecycle/replacement-schedule")
async def replacement_schedule() -> list:
    """Get strategy replacement schedule."""
    return lifecycle_model.get_replacement_schedule()


@router.post("/actuary/reserves")
async def calculate_reserves(body: ReserveRequest) -> dict:
    """Calculate comprehensive capital reserves."""
    reserve_engine.calculate_market_reserve(body.portfolio_var_99)
    reserve_engine.calculate_operational_reserve(body.annual_revenue, [])
    reserve_engine.calculate_model_risk_reserve(body.strategy_count)
    reserve_engine.calculate_liquidity_reserve(
        body.daily_volume, body.position_size, body.market_depth
    )
    reserve_engine.calculate_technology_reserve(body.annual_tech_spend)
    return reserve_engine.total_required_reserves()


@router.post("/actuary/risk-budget")
async def risk_budget_allocation(body: RiskBudgetRequest) -> dict:
    """Allocate risk budget across strategies."""
    return risk_engine.strategy_risk_budget(
        body.strategy_returns, body.total_risk_budget
    )
