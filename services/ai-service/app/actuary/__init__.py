"""PARRALAX AI Intelligence Actuary Suite.

Comprehensive actuarial models for AI-driven HFT fund operations:
- Risk pricing (VaR, CVaR, Greeks, tail risk)
- Strategy allocation and rebalancing
- Portfolio insurance and hedging
- Mortality/survival models for strategy lifecycles
- Loss distribution and reserve calculations
"""

from .risk_models import RiskPricingEngine, VaRModel, CVaRModel, TailRiskAnalyzer
from .strategy_lifecycle import StrategyLifecycleModel, StrategyMortality
from .portfolio_insurance import PortfolioInsuranceEngine, CPPIModel, OBPIModel
from .reserve_engine import ReserveEngine, LossDistribution
from .greeks import GreeksEngine, DeltaModel, GammaModel, VegaModel, ThetaModel

__all__ = [
    "RiskPricingEngine",
    "VaRModel",
    "CVaRModel",
    "TailRiskAnalyzer",
    "StrategyLifecycleModel",
    "StrategyMortality",
    "PortfolioInsuranceEngine",
    "CPPIModel",
    "OBPIModel",
    "ReserveEngine",
    "LossDistribution",
    "GreeksEngine",
    "DeltaModel",
    "GammaModel",
    "VegaModel",
    "ThetaModel",
]
