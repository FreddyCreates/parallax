"""PARRALAX AI Trading Strategies Suite.

Complete library of AI-driven trading strategies:
- Statistical Arbitrage
- Market Making
- Momentum / Trend Following
- Mean Reversion
- Pairs Trading
- Volatility Arbitrage
- Liquidity Provision
- Cross-Asset Arbitrage
- Event-Driven
- Machine Learning Alpha
"""

from .statistical_arbitrage import StatisticalArbitrageStrategy
from .market_making import MarketMakingStrategy
from .momentum import MomentumStrategy
from .mean_reversion import MeanReversionStrategy
from .pairs_trading import PairsTradingStrategy
from .volatility_arb import VolatilityArbitrageStrategy
from .liquidity_provision import LiquidityProvisionStrategy
from .cross_asset import CrossAssetArbitrageStrategy
from .event_driven import EventDrivenStrategy
from .ml_alpha import MLAlphaStrategy
from .strategy_router import StrategyRouter, StrategyAllocation

__all__ = [
    "StatisticalArbitrageStrategy",
    "MarketMakingStrategy",
    "MomentumStrategy",
    "MeanReversionStrategy",
    "PairsTradingStrategy",
    "VolatilityArbitrageStrategy",
    "LiquidityProvisionStrategy",
    "CrossAssetArbitrageStrategy",
    "EventDrivenStrategy",
    "MLAlphaStrategy",
    "StrategyRouter",
    "StrategyAllocation",
]
