"""Quantitative finance toolkit for the PARALLAX Python SDK.

The :mod:`parallax_sdk.quant` package groups together reusable building
blocks for derivatives pricing, quantitative portfolio construction,
trading research, risk management, game theory, and backend integration.
The implementations are intentionally pragmatic: they expose sensible
high-level APIs while remaining transparent enough for research notebooks,
production services, and model validation workflows.
"""

from .stochastic import (
    BlackScholesResult,
    HestonCalibrationResult,
    HestonParameters,
    MonteCarloPricer,
    MonteCarloResult,
    VarianceReduction,
    black_scholes_price,
    black_scholes_with_greeks,
    calibrate_heston_model,
    heston_price,
    simulate_jump_diffusion_paths,
)
from .optimization import (
    ConvexOptimizationResult,
    ConvexOptimizer,
    GeneticAlgorithmOptimizer,
    GeneticAlgorithmResult,
    ParticleSwarmOptimizer,
    ParticleSwarmResult,
    PortfolioOptimizationResult,
    PortfolioOptimizer,
    SimulatedAnnealingResult,
    simulated_annealing_optimize,
)
from .trading import (
    BacktestEngine,
    BacktestResult,
    GARCHFitResult,
    GARCHModel,
    KalmanPairsTradingModel,
    PairsTradingResult,
    SKLearnTradingModel,
    engineer_price_features,
)
from .risk import (
    GaussianCopulaModel,
    PortfolioAnalytics,
    RiskFactorDecomposition,
    RiskReport,
    StressScenario,
    monte_carlo_portfolio_risk,
)
from .game_theory import (
    AuctionOutcome,
    NashEquilibriumResult,
    StrategicGameAnalyzer,
    english_auction,
    first_price_sealed_bid_auction,
    second_price_sealed_bid_auction,
)
from .bridge import (
    CanisterHTTPClient,
    CanisterResponse,
    deserialize_payload,
    serialize_payload,
)

__all__ = [
    "AuctionOutcome",
    "BacktestEngine",
    "BacktestResult",
    "BlackScholesResult",
    "CanisterHTTPClient",
    "CanisterResponse",
    "ConvexOptimizationResult",
    "ConvexOptimizer",
    "GARCHFitResult",
    "GARCHModel",
    "GaussianCopulaModel",
    "GeneticAlgorithmOptimizer",
    "GeneticAlgorithmResult",
    "HestonCalibrationResult",
    "HestonParameters",
    "KalmanPairsTradingModel",
    "MonteCarloPricer",
    "MonteCarloResult",
    "NashEquilibriumResult",
    "PairsTradingResult",
    "ParticleSwarmOptimizer",
    "ParticleSwarmResult",
    "PortfolioAnalytics",
    "PortfolioOptimizationResult",
    "PortfolioOptimizer",
    "RiskFactorDecomposition",
    "RiskReport",
    "SKLearnTradingModel",
    "SimulatedAnnealingResult",
    "StrategicGameAnalyzer",
    "StressScenario",
    "VarianceReduction",
    "black_scholes_price",
    "black_scholes_with_greeks",
    "calibrate_heston_model",
    "deserialize_payload",
    "engineer_price_features",
    "english_auction",
    "first_price_sealed_bid_auction",
    "heston_price",
    "monte_carlo_portfolio_risk",
    "second_price_sealed_bid_auction",
    "serialize_payload",
    "simulated_annealing_optimize",
    "simulate_jump_diffusion_paths",
]
