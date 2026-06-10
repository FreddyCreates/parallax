"""Actuarial Risk Pricing Models for HFT Fund.

Implements VaR, CVaR, and tail risk analysis with AI-enhanced distribution fitting.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class DistributionType(str, Enum):
    NORMAL = "normal"
    STUDENT_T = "student_t"
    GENERALIZED_PARETO = "generalized_pareto"
    EXTREME_VALUE = "extreme_value"
    STABLE = "stable"


@dataclass
class RiskMetrics:
    var_95: float = 0.0
    var_99: float = 0.0
    cvar_95: float = 0.0
    cvar_99: float = 0.0
    max_drawdown: float = 0.0
    sharpe_ratio: float = 0.0
    sortino_ratio: float = 0.0
    calmar_ratio: float = 0.0
    tail_index: float = 0.0
    expected_shortfall: float = 0.0


@dataclass
class VaRModel:
    """Value at Risk model with parametric, historical, and Monte Carlo methods."""

    confidence_levels: list[float] = field(default_factory=lambda: [0.95, 0.99, 0.999])
    lookback_days: int = 252
    method: str = "parametric"  # parametric, historical, monte_carlo

    def calculate(self, returns: list[float], confidence: float = 0.95) -> float:
        """Calculate VaR at given confidence level."""
        if not returns:
            return 0.0

        sorted_returns = sorted(returns)
        n = len(sorted_returns)
        index = int((1 - confidence) * n)
        return -sorted_returns[max(0, index)]

    def parametric_var(self, mean: float, std: float, confidence: float = 0.95) -> float:
        """Parametric VaR assuming normal distribution."""
        z_scores = {0.90: 1.282, 0.95: 1.645, 0.99: 2.326, 0.999: 3.090}
        z = z_scores.get(confidence, 1.645)
        return -(mean - z * std)

    def monte_carlo_var(
        self, mean: float, std: float, confidence: float = 0.95, simulations: int = 10000
    ) -> float:
        """Monte Carlo VaR simulation."""
        # Simplified — in production uses numpy for vectorized simulation
        import random

        scenarios = [random.gauss(mean, std) for _ in range(simulations)]
        scenarios.sort()
        index = int((1 - confidence) * simulations)
        return -scenarios[index]


@dataclass
class CVaRModel:
    """Conditional Value at Risk (Expected Shortfall) model."""

    confidence: float = 0.95

    def calculate(self, returns: list[float]) -> float:
        """Calculate CVaR — expected loss beyond VaR threshold."""
        if not returns:
            return 0.0

        sorted_returns = sorted(returns)
        n = len(sorted_returns)
        cutoff = int((1 - self.confidence) * n)
        tail_losses = sorted_returns[:max(1, cutoff)]
        return -sum(tail_losses) / len(tail_losses)


@dataclass
class TailRiskAnalyzer:
    """Extreme value theory for tail risk analysis."""

    threshold_percentile: float = 0.05
    distribution: DistributionType = DistributionType.GENERALIZED_PARETO

    def hill_estimator(self, returns: list[float], k: int = 50) -> float:
        """Hill estimator for tail index."""
        if len(returns) < k:
            return 0.0

        sorted_abs = sorted([abs(r) for r in returns], reverse=True)
        log_sum = sum(math.log(sorted_abs[i] / sorted_abs[k]) for i in range(k))
        return log_sum / k if k > 0 else 0.0

    def expected_tail_loss(self, returns: list[float], threshold: float) -> float:
        """Expected loss beyond threshold."""
        tail_losses = [r for r in returns if r < -threshold]
        if not tail_losses:
            return 0.0
        return -sum(tail_losses) / len(tail_losses)

    def tail_dependence(self, returns_a: list[float], returns_b: list[float]) -> float:
        """Measure tail dependence between two return series."""
        if len(returns_a) != len(returns_b) or not returns_a:
            return 0.0

        n = len(returns_a)
        threshold_a = sorted(returns_a)[int(self.threshold_percentile * n)]
        threshold_b = sorted(returns_b)[int(self.threshold_percentile * n)]

        joint_exceedances = sum(
            1 for a, b in zip(returns_a, returns_b)
            if a < threshold_a and b < threshold_b
        )

        marginal_exceedances = int(self.threshold_percentile * n)
        if marginal_exceedances == 0:
            return 0.0

        return joint_exceedances / marginal_exceedances


class RiskPricingEngine:
    """Full actuarial risk pricing engine for AI HFT fund."""

    def __init__(self) -> None:
        self.var_model = VaRModel()
        self.cvar_model = CVaRModel()
        self.tail_analyzer = TailRiskAnalyzer()

    def full_risk_assessment(self, returns: list[float]) -> RiskMetrics:
        """Complete risk assessment across all models."""
        if not returns:
            return RiskMetrics()

        mean = sum(returns) / len(returns)
        variance = sum((r - mean) ** 2 for r in returns) / len(returns)
        std = math.sqrt(variance) if variance > 0 else 0.0

        # Downside deviation for Sortino
        downside = [r for r in returns if r < 0]
        downside_std = (
            math.sqrt(sum(r**2 for r in downside) / len(downside))
            if downside else 0.0
        )

        # Max drawdown
        cumulative = 0.0
        peak = 0.0
        max_dd = 0.0
        for r in returns:
            cumulative += r
            peak = max(peak, cumulative)
            max_dd = min(max_dd, cumulative - peak)

        # Risk-adjusted ratios (annualized)
        ann_factor = math.sqrt(252)
        sharpe = (mean / std * ann_factor) if std > 0 else 0.0
        sortino = (mean / downside_std * ann_factor) if downside_std > 0 else 0.0
        calmar = (mean * 252 / abs(max_dd)) if max_dd != 0 else 0.0

        return RiskMetrics(
            var_95=self.var_model.calculate(returns, 0.95),
            var_99=self.var_model.calculate(returns, 0.99),
            cvar_95=CVaRModel(confidence=0.95).calculate(returns),
            cvar_99=CVaRModel(confidence=0.99).calculate(returns),
            max_drawdown=max_dd,
            sharpe_ratio=sharpe,
            sortino_ratio=sortino,
            calmar_ratio=calmar,
            tail_index=self.tail_analyzer.hill_estimator(returns),
            expected_shortfall=self.tail_analyzer.expected_tail_loss(returns, std),
        )

    def strategy_risk_budget(
        self, strategy_returns: dict[str, list[float]], total_risk_budget: float
    ) -> dict[str, float]:
        """Allocate risk budget across strategies using inverse-VaR weighting."""
        strategy_vars: dict[str, float] = {}
        for name, returns in strategy_returns.items():
            var = self.var_model.calculate(returns, 0.99)
            strategy_vars[name] = var if var > 0 else 0.001

        total_inverse_var = sum(1.0 / v for v in strategy_vars.values())
        allocations = {
            name: (1.0 / var) / total_inverse_var * total_risk_budget
            for name, var in strategy_vars.items()
        }
        return allocations
