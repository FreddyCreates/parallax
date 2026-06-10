"""Strategy Router — AI-driven strategy orchestration and allocation.

Routes capital and signals across all strategies based on market regime,
risk budgets, and AI-determined optimal allocation.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class MarketRegime(str, Enum):
    TRENDING = "trending"
    MEAN_REVERTING = "mean_reverting"
    HIGH_VOLATILITY = "high_volatility"
    LOW_VOLATILITY = "low_volatility"
    CRISIS = "crisis"
    NORMAL = "normal"


class StrategyType(str, Enum):
    STAT_ARB = "statistical_arbitrage"
    MARKET_MAKING = "market_making"
    MOMENTUM = "momentum"
    MEAN_REVERSION = "mean_reversion"
    PAIRS = "pairs_trading"
    VOL_ARB = "volatility_arbitrage"
    LIQUIDITY = "liquidity_provision"
    CROSS_ASSET = "cross_asset_arbitrage"
    EVENT_DRIVEN = "event_driven"
    ML_ALPHA = "ml_alpha"


@dataclass
class StrategyAllocation:
    strategy_type: StrategyType
    weight: float
    risk_budget: float
    capital_allocated: float
    is_active: bool = True
    max_position: float = 0.0
    current_pnl: float = 0.0


@dataclass
class RoutingDecision:
    regime: MarketRegime
    allocations: list[StrategyAllocation]
    total_capital_deployed: float
    reserve_capital: float
    active_strategies: int
    regime_confidence: float


class StrategyRouter:
    """AI Strategy Router — orchestrates all trading strategies.

    Determines market regime and dynamically allocates capital
    across strategies for optimal risk-adjusted returns.
    """

    def __init__(self, total_capital: float = 10_000_000.0) -> None:
        self.total_capital = total_capital
        self.reserve_pct = 0.15  # 15% always in reserve
        self.current_regime = MarketRegime.NORMAL
        self.allocations: dict[StrategyType, StrategyAllocation] = {}

        # Regime-specific allocation templates
        self.regime_templates: dict[MarketRegime, dict[StrategyType, float]] = {
            MarketRegime.TRENDING: {
                StrategyType.MOMENTUM: 0.30,
                StrategyType.ML_ALPHA: 0.20,
                StrategyType.EVENT_DRIVEN: 0.15,
                StrategyType.CROSS_ASSET: 0.15,
                StrategyType.MARKET_MAKING: 0.10,
                StrategyType.LIQUIDITY: 0.10,
            },
            MarketRegime.MEAN_REVERTING: {
                StrategyType.STAT_ARB: 0.25,
                StrategyType.MEAN_REVERSION: 0.25,
                StrategyType.PAIRS: 0.20,
                StrategyType.MARKET_MAKING: 0.15,
                StrategyType.LIQUIDITY: 0.10,
                StrategyType.ML_ALPHA: 0.05,
            },
            MarketRegime.HIGH_VOLATILITY: {
                StrategyType.VOL_ARB: 0.25,
                StrategyType.EVENT_DRIVEN: 0.20,
                StrategyType.MARKET_MAKING: 0.05,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.ML_ALPHA: 0.20,
                StrategyType.MOMENTUM: 0.15,
            },
            MarketRegime.LOW_VOLATILITY: {
                StrategyType.MARKET_MAKING: 0.30,
                StrategyType.LIQUIDITY: 0.25,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.PAIRS: 0.15,
                StrategyType.MEAN_REVERSION: 0.10,
                StrategyType.ML_ALPHA: 0.05,
            },
            MarketRegime.CRISIS: {
                StrategyType.VOL_ARB: 0.30,
                StrategyType.EVENT_DRIVEN: 0.25,
                StrategyType.MOMENTUM: 0.20,
                StrategyType.ML_ALPHA: 0.15,
                StrategyType.CROSS_ASSET: 0.10,
            },
            MarketRegime.NORMAL: {
                StrategyType.STAT_ARB: 0.15,
                StrategyType.MARKET_MAKING: 0.15,
                StrategyType.MOMENTUM: 0.12,
                StrategyType.MEAN_REVERSION: 0.12,
                StrategyType.PAIRS: 0.10,
                StrategyType.VOL_ARB: 0.10,
                StrategyType.ML_ALPHA: 0.10,
                StrategyType.LIQUIDITY: 0.08,
                StrategyType.CROSS_ASSET: 0.05,
                StrategyType.EVENT_DRIVEN: 0.03,
            },
        }

    def detect_regime(
        self,
        returns: list[float],
        volatility: float,
        trend_strength: float,
        correlation_breakdown: bool = False,
    ) -> tuple[MarketRegime, float]:
        """Detect current market regime from market data."""
        if correlation_breakdown or (volatility > 0.40 and any(r < -0.05 for r in returns[-5:])):
            return MarketRegime.CRISIS, 0.9

        if volatility > 0.25:
            return MarketRegime.HIGH_VOLATILITY, min(1.0, volatility / 0.40)

        if volatility < 0.10:
            return MarketRegime.LOW_VOLATILITY, min(1.0, (0.15 - volatility) / 0.10)

        if trend_strength > 0.6:
            return MarketRegime.TRENDING, trend_strength

        if trend_strength < 0.3:
            return MarketRegime.MEAN_REVERTING, 1.0 - trend_strength

        return MarketRegime.NORMAL, 0.5

    def allocate(
        self,
        regime: MarketRegime,
        strategy_performance: dict[StrategyType, float] | None = None,
    ) -> RoutingDecision:
        """Allocate capital across strategies based on regime."""
        self.current_regime = regime
        deployable = self.total_capital * (1 - self.reserve_pct)

        template = self.regime_templates.get(regime, self.regime_templates[MarketRegime.NORMAL])

        # Adjust weights by performance if available
        weights = dict(template)
        if strategy_performance:
            total_perf = sum(max(0, p) for p in strategy_performance.values()) or 1
            for st, perf in strategy_performance.items():
                if st in weights and perf > 0:
                    weights[st] *= 1 + (perf / total_perf) * 0.3  # Boost performers

            # Renormalize
            total_weight = sum(weights.values())
            weights = {k: v / total_weight for k, v in weights.items()}

        allocations = []
        for strategy_type, weight in weights.items():
            capital = deployable * weight
            alloc = StrategyAllocation(
                strategy_type=strategy_type,
                weight=weight,
                risk_budget=capital * 0.02,  # 2% risk per strategy
                capital_allocated=capital,
                is_active=weight > 0.01,
                max_position=capital * 0.5,
            )
            self.allocations[strategy_type] = alloc
            allocations.append(alloc)

        regime_confidence = 0.7  # Default

        return RoutingDecision(
            regime=regime,
            allocations=allocations,
            total_capital_deployed=deployable,
            reserve_capital=self.total_capital * self.reserve_pct,
            active_strategies=sum(1 for a in allocations if a.is_active),
            regime_confidence=regime_confidence,
        )

    def get_routing_state(self) -> dict[str, Any]:
        """Get current routing state."""
        return {
            "regime": self.current_regime.value,
            "total_capital": self.total_capital,
            "deployable": self.total_capital * (1 - self.reserve_pct),
            "reserve": self.total_capital * self.reserve_pct,
            "allocations": {
                st.value: {
                    "weight": alloc.weight,
                    "capital": alloc.capital_allocated,
                    "risk_budget": alloc.risk_budget,
                    "active": alloc.is_active,
                    "pnl": alloc.current_pnl,
                }
                for st, alloc in self.allocations.items()
            },
            "active_count": sum(1 for a in self.allocations.values() if a.is_active),
        }

    def emergency_deleverage(self, target_pct: float = 0.50) -> dict[str, Any]:
        """Emergency deleveraging — reduce all positions."""
        actions = []
        for st, alloc in self.allocations.items():
            if alloc.is_active:
                reduction = alloc.capital_allocated * (1 - target_pct)
                alloc.capital_allocated *= target_pct
                alloc.max_position *= target_pct
                actions.append({
                    "strategy": st.value,
                    "action": "reduce",
                    "reduction_amount": reduction,
                    "new_allocation": alloc.capital_allocated,
                })

        return {
            "action": "emergency_deleverage",
            "target_pct": target_pct,
            "strategies_affected": len(actions),
            "details": actions,
        }
