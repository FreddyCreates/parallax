"""Actuarial Risk Pricing Models for HFT Fund.

Implements VaR, CVaR, tail risk analysis, copula models, stress testing,
regime-conditional risk, risk decomposition, and advanced distribution fitting.
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class DistributionType(str, Enum):
    NORMAL = "normal"
    STUDENT_T = "student_t"
    GENERALIZED_PARETO = "generalized_pareto"
    EXTREME_VALUE = "extreme_value"
    STABLE = "stable"
    CORNISH_FISHER = "cornish_fisher"
    JOHNSON_SU = "johnson_su"
    MIXTURE = "mixture"
    KERNEL = "kernel"


class CopulaType(str, Enum):
    GAUSSIAN = "gaussian"
    STUDENT_T = "student_t"
    CLAYTON = "clayton"
    GUMBEL = "gumbel"
    FRANK = "frank"


class StressScenario(str, Enum):
    GFC_2008 = "gfc_2008"
    COVID_2020 = "covid_2020"
    FLASH_CRASH_2010 = "flash_crash_2010"
    VOLMAGEDDON_2018 = "volmageddon_2018"
    LTCM_1998 = "ltcm_1998"
    DOT_COM_2000 = "dot_com_2000"
    TAPER_TANTRUM_2013 = "taper_tantrum_2013"
    CUSTOM = "custom"


class RiskRegime(str, Enum):
    LOW_VOL = "low_vol"
    NORMAL = "normal"
    HIGH_VOL = "high_vol"
    CRISIS = "crisis"
    TRENDING = "trending"
    MEAN_REVERTING = "mean_reverting"


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
class DrawdownMetrics:
    """Comprehensive drawdown analysis."""
    max_drawdown: float = 0.0
    max_drawdown_duration: int = 0
    current_drawdown: float = 0.0
    average_drawdown: float = 0.0
    drawdown_frequency: float = 0.0
    recovery_time_avg: float = 0.0
    cdar_95: float = 0.0  # Conditional Drawdown at Risk
    ulcer_index: float = 0.0


@dataclass
class CopulaResult:
    """Result from copula dependency modeling."""
    copula_type: CopulaType
    parameter: float = 0.0
    tail_dependence_lower: float = 0.0
    tail_dependence_upper: float = 0.0
    kendall_tau: float = 0.0
    joint_var: float = 0.0
    diversification_benefit: float = 0.0


@dataclass
class StressTestResult:
    """Result from stress testing."""
    scenario: StressScenario
    portfolio_loss: float = 0.0
    worst_strategy_loss: float = 0.0
    correlation_impact: float = 0.0
    liquidity_impact: float = 0.0
    recovery_days: int = 0
    capital_breach: bool = False
    strategy_losses: dict[str, float] = field(default_factory=dict)


@dataclass
class RiskDecomposition:
    """Portfolio risk decomposition."""
    total_var: float = 0.0
    marginal_var: dict[str, float] = field(default_factory=dict)
    component_var: dict[str, float] = field(default_factory=dict)
    incremental_var: dict[str, float] = field(default_factory=dict)
    pct_contribution: dict[str, float] = field(default_factory=dict)
    diversification_ratio: float = 0.0


@dataclass
class LiquidityAdjustedRisk:
    """Liquidity-adjusted risk metrics."""
    base_var: float = 0.0
    liquidity_var: float = 0.0
    spread_cost: float = 0.0
    market_impact: float = 0.0
    days_to_liquidate: float = 0.0
    liquidation_cost: float = 0.0
    lvar_total: float = 0.0


@dataclass
class CorrelationAnalysis:
    """Dynamic correlation analysis results."""
    current_correlation: float = 0.0
    historical_avg: float = 0.0
    stress_correlation: float = 0.0
    correlation_breakpoint: bool = False
    dcc_estimate: float = 0.0
    regime: RiskRegime = RiskRegime.NORMAL


class VaRModel:
    """Value at Risk model with parametric, historical, and Monte Carlo methods."""

    confidence_levels: list[float]
    lookback_days: int
    method: str

    def __init__(
        self,
        confidence_levels: list[float] | None = None,
        lookback_days: int = 252,
        method: str = "parametric",
    ) -> None:
        self.confidence_levels = confidence_levels or [0.95, 0.99, 0.999]
        self.lookback_days = lookback_days
        self.method = method

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
        scenarios = [random.gauss(mean, std) for _ in range(simulations)]
        scenarios.sort()
        index = int((1 - confidence) * simulations)
        return -scenarios[index]

    def cornish_fisher_var(
        self, mean: float, std: float, skewness: float, kurtosis: float, confidence: float = 0.95
    ) -> float:
        """Cornish-Fisher expansion for non-normal VaR."""
        z_scores = {0.90: 1.282, 0.95: 1.645, 0.99: 2.326, 0.999: 3.090}
        z = z_scores.get(confidence, 1.645)
        # Cornish-Fisher adjustment
        z_cf = (
            z
            + (z**2 - 1) * skewness / 6
            + (z**3 - 3 * z) * (kurtosis - 3) / 24
            - (2 * z**3 - 5 * z) * skewness**2 / 36
        )
        return -(mean - z_cf * std)

    def filtered_historical_var(
        self, returns: list[float], volatilities: list[float], confidence: float = 0.95
    ) -> float:
        """Filtered Historical Simulation VaR using GARCH-like vol scaling."""
        if not returns or not volatilities or len(returns) != len(volatilities):
            return 0.0
        current_vol = volatilities[-1] if volatilities[-1] > 0 else 1.0
        scaled = [r * current_vol / max(v, 1e-8) for r, v in zip(returns, volatilities)]
        scaled.sort()
        n = len(scaled)
        index = int((1 - confidence) * n)
        return -scaled[max(0, index)]

    def ewma_var(
        self, returns: list[float], confidence: float = 0.95, decay: float = 0.94
    ) -> float:
        """EWMA (RiskMetrics) VaR with exponential weighting."""
        if not returns:
            return 0.0
        variance = returns[0] ** 2
        for r in returns[1:]:
            variance = decay * variance + (1 - decay) * r**2
        std = math.sqrt(variance)
        mean = sum(returns) / len(returns)
        return self.parametric_var(mean, std, confidence)


class CVaRModel:
    """Conditional Value at Risk (Expected Shortfall) model."""

    def __init__(self, confidence: float = 0.95) -> None:
        self.confidence = confidence

    def calculate(self, returns: list[float]) -> float:
        """Calculate CVaR — expected loss beyond VaR threshold."""
        if not returns:
            return 0.0
        sorted_returns = sorted(returns)
        n = len(sorted_returns)
        cutoff = int((1 - self.confidence) * n)
        tail_losses = sorted_returns[:max(1, cutoff)]
        return -sum(tail_losses) / len(tail_losses)

    def parametric_cvar(self, mean: float, std: float, confidence: float = 0.95) -> float:
        """Parametric CVaR assuming normal distribution."""
        z_scores = {0.90: 1.282, 0.95: 1.645, 0.99: 2.326}
        z = z_scores.get(confidence, 1.645)
        # E[X | X < -VaR] for normal
        phi_z = math.exp(-0.5 * z**2) / math.sqrt(2 * math.pi)
        return -(mean - std * phi_z / (1 - confidence))

    def tail_cvar(self, returns: list[float], threshold_pct: float = 0.01) -> float:
        """Extreme tail CVaR at very low percentiles."""
        if not returns:
            return 0.0
        sorted_returns = sorted(returns)
        n = len(sorted_returns)
        cutoff = max(1, int(threshold_pct * n))
        tail = sorted_returns[:cutoff]
        return -sum(tail) / len(tail)


class TailRiskAnalyzer:
    """Extreme value theory for tail risk analysis."""

    def __init__(
        self,
        threshold_percentile: float = 0.05,
        distribution: DistributionType = DistributionType.GENERALIZED_PARETO,
    ) -> None:
        self.threshold_percentile = threshold_percentile
        self.distribution = distribution

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

    def peaks_over_threshold(self, returns: list[float], threshold: float) -> dict[str, float]:
        """POT method for EVT analysis."""
        exceedances = [-r - threshold for r in returns if r < -threshold]
        if not exceedances:
            return {"n_exceedances": 0, "mean_excess": 0.0, "shape": 0.0, "scale": 0.0}
        mean_excess = sum(exceedances) / len(exceedances)
        var_excess = sum((x - mean_excess) ** 2 for x in exceedances) / len(exceedances)
        # Method of moments for GPD
        scale = mean_excess * (mean_excess**2 / var_excess + 1) / 2
        shape = (mean_excess**2 / var_excess - 1) / 2
        return {
            "n_exceedances": len(exceedances),
            "mean_excess": mean_excess,
            "shape": shape,
            "scale": scale,
            "exceedance_rate": len(exceedances) / len(returns),
        }

    def return_level(self, returns: list[float], period: int = 100) -> float:
        """Estimate return level for given return period (e.g., 100-year loss)."""
        pot = self.peaks_over_threshold(returns, 0.02)
        if pot["n_exceedances"] == 0:
            return 0.0
        xi = pot["shape"]
        sigma = pot["scale"]
        rate = pot["exceedance_rate"]
        if abs(xi) < 1e-8:
            return 0.02 + sigma * math.log(period * rate)
        return 0.02 + (sigma / xi) * ((period * rate) ** xi - 1)

    def block_maxima(self, returns: list[float], block_size: int = 21) -> dict[str, float]:
        """Block maxima approach for GEV fitting."""
        if len(returns) < block_size:
            return {"location": 0.0, "scale": 0.0, "shape": 0.0}
        losses = [-r for r in returns]
        n_blocks = len(losses) // block_size
        maxima = []
        for i in range(n_blocks):
            block = losses[i * block_size : (i + 1) * block_size]
            maxima.append(max(block))
        if not maxima:
            return {"location": 0.0, "scale": 0.0, "shape": 0.0}
        mu = sum(maxima) / len(maxima)
        var_m = sum((x - mu) ** 2 for x in maxima) / len(maxima)
        sigma = math.sqrt(var_m) if var_m > 0 else 0.0
        return {"location": mu, "scale": sigma, "shape": 0.1, "n_blocks": n_blocks}


class CopulaModel:
    """Copula-based dependency modeling for multi-asset risk."""

    def __init__(self, copula_type: CopulaType = CopulaType.GAUSSIAN) -> None:
        self.copula_type = copula_type

    def fit(self, returns_a: list[float], returns_b: list[float]) -> CopulaResult:
        """Fit copula to bivariate return data."""
        if len(returns_a) != len(returns_b) or len(returns_a) < 10:
            return CopulaResult(copula_type=self.copula_type)

        n = len(returns_a)
        # Compute rank correlation (Kendall's tau approximation)
        concordant = 0
        discordant = 0
        for i in range(n):
            for j in range(i + 1, min(i + 50, n)):  # Sample for efficiency
                da = returns_a[i] - returns_a[j]
                db = returns_b[i] - returns_b[j]
                if da * db > 0:
                    concordant += 1
                elif da * db < 0:
                    discordant += 1
        total_pairs = concordant + discordant
        tau = (concordant - discordant) / total_pairs if total_pairs > 0 else 0.0

        # Estimate copula parameter from tau
        param = self._tau_to_param(tau)
        lower_td, upper_td = self._tail_dependence(param)

        # Joint VaR estimation
        std_a = math.sqrt(sum(r**2 for r in returns_a) / n)
        std_b = math.sqrt(sum(r**2 for r in returns_b) / n)
        rho = math.sin(math.pi * tau / 2)  # Convert tau to linear correlation
        joint_std = math.sqrt(std_a**2 + std_b**2 + 2 * rho * std_a * std_b)
        standalone_std = std_a + std_b
        div_benefit = 1.0 - joint_std / standalone_std if standalone_std > 0 else 0.0

        return CopulaResult(
            copula_type=self.copula_type,
            parameter=param,
            tail_dependence_lower=lower_td,
            tail_dependence_upper=upper_td,
            kendall_tau=tau,
            joint_var=joint_std * 1.645,
            diversification_benefit=div_benefit,
        )

    def _tau_to_param(self, tau: float) -> float:
        """Convert Kendall's tau to copula parameter."""
        if self.copula_type == CopulaType.GAUSSIAN:
            return math.sin(math.pi * tau / 2)
        elif self.copula_type == CopulaType.CLAYTON:
            return max(0.01, 2 * tau / (1 - tau)) if tau < 1 else 10.0
        elif self.copula_type == CopulaType.GUMBEL:
            return max(1.0, 1.0 / (1 - tau)) if tau < 1 else 10.0
        elif self.copula_type == CopulaType.FRANK:
            return tau * 9.0  # Simplified approximation
        return tau

    def _tail_dependence(self, param: float) -> tuple[float, float]:
        """Compute lower and upper tail dependence coefficients."""
        if self.copula_type == CopulaType.GAUSSIAN:
            return 0.0, 0.0  # Gaussian has no tail dependence
        elif self.copula_type == CopulaType.STUDENT_T:
            return 0.2, 0.2  # Symmetric, depends on df
        elif self.copula_type == CopulaType.CLAYTON:
            return 2 ** (-1.0 / max(param, 0.01)), 0.0
        elif self.copula_type == CopulaType.GUMBEL:
            return 0.0, 2.0 - 2.0 ** (1.0 / max(param, 1.0))
        return 0.0, 0.0

    def simulate_joint(
        self, n_simulations: int, marginal_params: list[tuple[float, float]]
    ) -> list[list[float]]:
        """Simulate joint returns using copula."""
        results: list[list[float]] = []
        for _ in range(n_simulations):
            u = random.random()
            v = random.random()
            # Transform through inverse CDF of marginals
            row = []
            for mean, std in marginal_params:
                z = _inv_norm_cdf(u) if len(row) == 0 else _inv_norm_cdf(v)
                row.append(mean + std * z)
            results.append(row)
            u = random.random()
        return results


class StressTestingEngine:
    """Comprehensive stress testing framework."""

    # Historical scenario parameters: (equity_shock, vol_multiplier, corr_increase, duration_days)
    SCENARIO_PARAMS: dict[StressScenario, dict[str, float]] = {
        StressScenario.GFC_2008: {
            "equity_shock": -0.55, "vol_multiplier": 4.0,
            "correlation_increase": 0.4, "credit_spread_widen": 0.08,
            "liquidity_dry_up": 0.7, "duration_days": 380,
        },
        StressScenario.COVID_2020: {
            "equity_shock": -0.34, "vol_multiplier": 5.0,
            "correlation_increase": 0.5, "credit_spread_widen": 0.04,
            "liquidity_dry_up": 0.5, "duration_days": 33,
        },
        StressScenario.FLASH_CRASH_2010: {
            "equity_shock": -0.09, "vol_multiplier": 3.0,
            "correlation_increase": 0.6, "credit_spread_widen": 0.01,
            "liquidity_dry_up": 0.9, "duration_days": 1,
        },
        StressScenario.VOLMAGEDDON_2018: {
            "equity_shock": -0.10, "vol_multiplier": 6.0,
            "correlation_increase": 0.3, "credit_spread_widen": 0.02,
            "liquidity_dry_up": 0.4, "duration_days": 5,
        },
        StressScenario.LTCM_1998: {
            "equity_shock": -0.22, "vol_multiplier": 2.5,
            "correlation_increase": 0.5, "credit_spread_widen": 0.06,
            "liquidity_dry_up": 0.8, "duration_days": 90,
        },
        StressScenario.DOT_COM_2000: {
            "equity_shock": -0.49, "vol_multiplier": 2.0,
            "correlation_increase": 0.2, "credit_spread_widen": 0.03,
            "liquidity_dry_up": 0.3, "duration_days": 750,
        },
        StressScenario.TAPER_TANTRUM_2013: {
            "equity_shock": -0.06, "vol_multiplier": 1.8,
            "correlation_increase": 0.2, "credit_spread_widen": 0.015,
            "liquidity_dry_up": 0.2, "duration_days": 45,
        },
    }

    def __init__(self, portfolio_value: float = 10_000_000.0) -> None:
        self.portfolio_value = portfolio_value

    def run_historical_scenario(
        self,
        scenario: StressScenario,
        strategy_exposures: dict[str, float],
        strategy_betas: dict[str, float] | None = None,
    ) -> StressTestResult:
        """Run a historical stress scenario against portfolio."""
        params = self.SCENARIO_PARAMS.get(scenario, self.SCENARIO_PARAMS[StressScenario.GFC_2008])
        equity_shock = params["equity_shock"]
        corr_increase = params["correlation_increase"]
        liquidity_hit = params["liquidity_dry_up"]

        betas = strategy_betas or {s: 1.0 for s in strategy_exposures}
        strategy_losses: dict[str, float] = {}
        total_loss = 0.0

        for strategy, exposure in strategy_exposures.items():
            beta = betas.get(strategy, 1.0)
            base_loss = exposure * equity_shock * beta
            corr_impact = abs(base_loss) * corr_increase * 0.5
            liq_impact = abs(base_loss) * liquidity_hit * 0.3
            strategy_loss = base_loss - corr_impact - liq_impact
            strategy_losses[strategy] = strategy_loss
            total_loss += strategy_loss

        worst_loss = min(strategy_losses.values()) if strategy_losses else 0.0
        capital_breach = abs(total_loss) > self.portfolio_value * 0.3

        return StressTestResult(
            scenario=scenario,
            portfolio_loss=total_loss,
            worst_strategy_loss=worst_loss,
            correlation_impact=corr_increase,
            liquidity_impact=liquidity_hit,
            recovery_days=int(params["duration_days"]),
            capital_breach=capital_breach,
            strategy_losses=strategy_losses,
        )

    def run_all_scenarios(
        self, strategy_exposures: dict[str, float]
    ) -> list[StressTestResult]:
        """Run all historical stress scenarios."""
        return [
            self.run_historical_scenario(scenario, strategy_exposures)
            for scenario in StressScenario
            if scenario != StressScenario.CUSTOM
        ]

    def reverse_stress_test(
        self, max_loss_threshold: float, strategy_exposures: dict[str, float]
    ) -> dict[str, Any]:
        """Find scenarios that cause losses exceeding threshold."""
        breaching_scenarios = []
        for scenario in StressScenario:
            if scenario == StressScenario.CUSTOM:
                continue
            result = self.run_historical_scenario(scenario, strategy_exposures)
            if abs(result.portfolio_loss) >= max_loss_threshold:
                breaching_scenarios.append({
                    "scenario": scenario.value,
                    "loss": result.portfolio_loss,
                    "excess": abs(result.portfolio_loss) - max_loss_threshold,
                })

        # Find minimum shock that causes breach
        min_shock = -max_loss_threshold / sum(abs(v) for v in strategy_exposures.values()) if strategy_exposures else -1.0

        return {
            "threshold": max_loss_threshold,
            "breaching_scenarios": breaching_scenarios,
            "min_equity_shock_for_breach": min_shock,
            "n_breaching": len(breaching_scenarios),
            "most_dangerous": breaching_scenarios[0]["scenario"] if breaching_scenarios else None,
        }

    def factor_stress_test(
        self,
        strategy_exposures: dict[str, float],
        factor_shocks: dict[str, float],
        factor_sensitivities: dict[str, dict[str, float]],
    ) -> dict[str, Any]:
        """Factor-based stress test with custom factor shocks."""
        strategy_losses: dict[str, float] = {}
        for strategy, exposure in strategy_exposures.items():
            loss = 0.0
            sensitivities = factor_sensitivities.get(strategy, {})
            for factor, shock in factor_shocks.items():
                sensitivity = sensitivities.get(factor, 0.0)
                loss += exposure * sensitivity * shock
            strategy_losses[strategy] = loss

        total_loss = sum(strategy_losses.values())
        return {
            "total_loss": total_loss,
            "strategy_losses": strategy_losses,
            "factor_shocks": factor_shocks,
            "loss_pct": total_loss / self.portfolio_value * 100,
        }


class RegimeConditionalRisk:
    """Risk models conditioned on market regime."""

    def __init__(self) -> None:
        self.regime_params: dict[RiskRegime, dict[str, float]] = {
            RiskRegime.LOW_VOL: {"vol_scale": 0.6, "tail_thickness": 0.8, "correlation": 0.3},
            RiskRegime.NORMAL: {"vol_scale": 1.0, "tail_thickness": 1.0, "correlation": 0.4},
            RiskRegime.HIGH_VOL: {"vol_scale": 2.0, "tail_thickness": 1.5, "correlation": 0.6},
            RiskRegime.CRISIS: {"vol_scale": 3.5, "tail_thickness": 2.5, "correlation": 0.85},
            RiskRegime.TRENDING: {"vol_scale": 1.2, "tail_thickness": 0.9, "correlation": 0.5},
            RiskRegime.MEAN_REVERTING: {"vol_scale": 0.8, "tail_thickness": 1.1, "correlation": 0.35},
        }

    def detect_regime(self, returns: list[float], lookback: int = 60) -> tuple[RiskRegime, float]:
        """Detect current risk regime from returns."""
        if not returns:
            return RiskRegime.NORMAL, 0.5
        recent = returns[-lookback:] if len(returns) > lookback else returns
        vol = math.sqrt(sum(r**2 for r in recent) / len(recent)) * math.sqrt(252)
        trend = sum(recent) / len(recent) * 252

        if vol > 0.40:
            return RiskRegime.CRISIS, min(1.0, vol / 0.60)
        if vol > 0.25:
            return RiskRegime.HIGH_VOL, min(1.0, vol / 0.40)
        if vol < 0.10:
            return RiskRegime.LOW_VOL, min(1.0, (0.12 - vol) / 0.08)
        if abs(trend) > 0.15:
            return RiskRegime.TRENDING, min(1.0, abs(trend) / 0.30)
        # Check mean reversion via autocorrelation
        if len(recent) > 5:
            ac = sum(recent[i] * recent[i - 1] for i in range(1, len(recent)))
            ac /= sum(r**2 for r in recent) or 1.0
            if ac < -0.3:
                return RiskRegime.MEAN_REVERTING, min(1.0, abs(ac))
        return RiskRegime.NORMAL, 0.5

    def regime_var(
        self, returns: list[float], regime: RiskRegime, confidence: float = 0.99
    ) -> float:
        """Calculate regime-conditional VaR."""
        params = self.regime_params[regime]
        if not returns:
            return 0.0
        mean = sum(returns) / len(returns)
        std = math.sqrt(sum((r - mean) ** 2 for r in returns) / len(returns))
        adjusted_std = std * params["vol_scale"]
        var_model = VaRModel()
        base_var = var_model.parametric_var(mean, adjusted_std, confidence)
        # Tail adjustment
        tail_adj = params["tail_thickness"]
        return base_var * tail_adj

    def regime_correlation_matrix(
        self, regime: RiskRegime, base_correlations: dict[tuple[str, str], float]
    ) -> dict[tuple[str, str], float]:
        """Adjust correlation matrix for regime."""
        params = self.regime_params[regime]
        target_corr = params["correlation"]
        adjusted = {}
        for pair, corr in base_correlations.items():
            # Shift correlations toward regime-specific level
            adj_corr = corr + (target_corr - corr) * 0.5
            adjusted[pair] = max(-1.0, min(1.0, adj_corr))
        return adjusted


class RiskDecompositionEngine:
    """Portfolio risk decomposition — marginal, component, incremental VaR."""

    def __init__(self) -> None:
        self.var_model = VaRModel()

    def decompose(
        self,
        strategy_returns: dict[str, list[float]],
        weights: dict[str, float],
        confidence: float = 0.99,
    ) -> RiskDecomposition:
        """Full risk decomposition across strategies."""
        if not strategy_returns:
            return RiskDecomposition()

        # Portfolio returns
        n = min(len(r) for r in strategy_returns.values()) if strategy_returns else 0
        if n == 0:
            return RiskDecomposition()

        portfolio_returns = []
        for i in range(n):
            port_ret = sum(
                weights.get(s, 0) * strategy_returns[s][i]
                for s in strategy_returns
            )
            portfolio_returns.append(port_ret)

        total_var = self.var_model.calculate(portfolio_returns, confidence)

        # Marginal VaR: dVaR/dw_i (approximated by small weight perturbation)
        marginal_var: dict[str, float] = {}
        component_var: dict[str, float] = {}
        incremental_var: dict[str, float] = {}

        for strategy in strategy_returns:
            # Marginal: VaR sensitivity to weight
            dw = 0.01
            perturbed_weights = dict(weights)
            perturbed_weights[strategy] = weights.get(strategy, 0) + dw
            perturbed_returns = []
            for i in range(n):
                pr = sum(
                    perturbed_weights.get(s, 0) * strategy_returns[s][i]
                    for s in strategy_returns
                )
                perturbed_returns.append(pr)
            perturbed_var = self.var_model.calculate(perturbed_returns, confidence)
            m_var = (perturbed_var - total_var) / dw
            marginal_var[strategy] = m_var

            # Component VaR = weight * marginal VaR
            w = weights.get(strategy, 0)
            component_var[strategy] = w * m_var

            # Incremental VaR: VaR with vs without strategy
            excl_returns = []
            for i in range(n):
                pr = sum(
                    weights.get(s, 0) * strategy_returns[s][i]
                    for s in strategy_returns if s != strategy
                )
                excl_returns.append(pr)
            excl_var = self.var_model.calculate(excl_returns, confidence) if excl_returns else 0.0
            incremental_var[strategy] = total_var - excl_var

        # Percentage contribution
        pct_contrib = {
            s: cv / total_var * 100 if total_var > 0 else 0.0
            for s, cv in component_var.items()
        }

        # Diversification ratio
        standalone_vars = sum(
            self.var_model.calculate(strategy_returns[s][:n], confidence) * weights.get(s, 0)
            for s in strategy_returns
        )
        div_ratio = standalone_vars / total_var if total_var > 0 else 1.0

        return RiskDecomposition(
            total_var=total_var,
            marginal_var=marginal_var,
            component_var=component_var,
            incremental_var=incremental_var,
            pct_contribution=pct_contrib,
            diversification_ratio=div_ratio,
        )


class DrawdownAnalyzer:
    """Comprehensive drawdown analysis and CDaR."""

    def analyze(self, returns: list[float]) -> DrawdownMetrics:
        """Full drawdown analysis."""
        if not returns:
            return DrawdownMetrics()

        cumulative = 0.0
        peak = 0.0
        max_dd = 0.0
        current_dd_start = 0
        max_dd_duration = 0
        dd_periods: list[float] = []
        dd_durations: list[int] = []
        in_drawdown = False
        dd_start = 0

        drawdowns: list[float] = []

        for i, r in enumerate(returns):
            cumulative += r
            if cumulative > peak:
                peak = cumulative
                if in_drawdown:
                    dd_durations.append(i - dd_start)
                    in_drawdown = False
            else:
                if not in_drawdown:
                    dd_start = i
                    in_drawdown = True

            dd = cumulative - peak
            drawdowns.append(dd)
            if dd < max_dd:
                max_dd = dd

        if in_drawdown:
            dd_durations.append(len(returns) - dd_start)

        max_dd_duration = max(dd_durations) if dd_durations else 0
        avg_dd = sum(min(0, d) for d in drawdowns) / len(drawdowns) if drawdowns else 0.0

        # CDaR (Conditional Drawdown at Risk) at 95%
        sorted_dds = sorted(drawdowns)
        cutoff = max(1, int(0.05 * len(sorted_dds)))
        cdar = -sum(sorted_dds[:cutoff]) / cutoff if cutoff > 0 else 0.0

        # Ulcer index
        sq_dds = [d**2 for d in drawdowns if d < 0]
        ulcer = math.sqrt(sum(sq_dds) / len(returns)) if returns else 0.0

        return DrawdownMetrics(
            max_drawdown=max_dd,
            max_drawdown_duration=max_dd_duration,
            current_drawdown=drawdowns[-1] if drawdowns else 0.0,
            average_drawdown=avg_dd,
            drawdown_frequency=len(dd_durations) / (len(returns) / 252) if returns else 0.0,
            recovery_time_avg=sum(dd_durations) / len(dd_durations) if dd_durations else 0.0,
            cdar_95=cdar,
            ulcer_index=ulcer,
        )


class LiquidityRiskModel:
    """Liquidity-adjusted risk metrics."""

    def calculate_lvar(
        self,
        returns: list[float],
        position_size: float,
        daily_volume: float,
        bid_ask_spread: float = 0.001,
        market_impact_coeff: float = 0.1,
        confidence: float = 0.99,
    ) -> LiquidityAdjustedRisk:
        """Calculate Liquidity-adjusted VaR."""
        var_model = VaRModel()
        base_var = var_model.calculate(returns, confidence) if returns else 0.0

        # Spread cost
        spread_cost = position_size * bid_ask_spread / 2

        # Market impact (square-root model)
        participation_rate = position_size / daily_volume if daily_volume > 0 else 1.0
        market_impact = market_impact_coeff * math.sqrt(participation_rate) * position_size

        # Days to liquidate at 10% ADV
        days_to_liq = position_size / (daily_volume * 0.10) if daily_volume > 0 else 100.0

        # Holding period adjustment
        holding_adj = math.sqrt(max(1, days_to_liq))
        liquidity_var = base_var * position_size * holding_adj

        total_lvar = base_var * position_size + spread_cost + market_impact

        return LiquidityAdjustedRisk(
            base_var=base_var * position_size,
            liquidity_var=liquidity_var,
            spread_cost=spread_cost,
            market_impact=market_impact,
            days_to_liquidate=days_to_liq,
            liquidation_cost=spread_cost + market_impact,
            lvar_total=total_lvar,
        )


class DynamicCorrelationModel:
    """Dynamic Conditional Correlation (DCC) model."""

    def __init__(self, decay_factor: float = 0.94) -> None:
        self.decay_factor = decay_factor

    def estimate_dcc(
        self, returns_a: list[float], returns_b: list[float]
    ) -> CorrelationAnalysis:
        """Estimate dynamic conditional correlation."""
        if len(returns_a) != len(returns_b) or len(returns_a) < 20:
            return CorrelationAnalysis()

        n = len(returns_a)
        # EWMA correlation
        cov = 0.0
        var_a = returns_a[0] ** 2
        var_b = returns_b[0] ** 2
        correlations = []

        for i in range(1, n):
            cov = self.decay_factor * cov + (1 - self.decay_factor) * returns_a[i] * returns_b[i]
            var_a = self.decay_factor * var_a + (1 - self.decay_factor) * returns_a[i] ** 2
            var_b = self.decay_factor * var_b + (1 - self.decay_factor) * returns_b[i] ** 2
            denom = math.sqrt(var_a * var_b)
            rho = cov / denom if denom > 0 else 0.0
            correlations.append(max(-1.0, min(1.0, rho)))

        current_corr = correlations[-1] if correlations else 0.0
        hist_avg = sum(correlations) / len(correlations) if correlations else 0.0

        # Stress correlation (worst 5% of markets)
        sorted_a = sorted(returns_a)
        stress_threshold = sorted_a[int(0.05 * n)]
        stress_pairs = [(a, b) for a, b in zip(returns_a, returns_b) if a < stress_threshold]
        if len(stress_pairs) > 2:
            sa = [p[0] for p in stress_pairs]
            sb = [p[1] for p in stress_pairs]
            mean_a = sum(sa) / len(sa)
            mean_b = sum(sb) / len(sb)
            cov_s = sum((a - mean_a) * (b - mean_b) for a, b in zip(sa, sb)) / len(sa)
            std_sa = math.sqrt(sum((a - mean_a) ** 2 for a in sa) / len(sa))
            std_sb = math.sqrt(sum((b - mean_b) ** 2 for b in sb) / len(sb))
            stress_corr = cov_s / (std_sa * std_sb) if std_sa > 0 and std_sb > 0 else 0.0
        else:
            stress_corr = current_corr

        # Breakpoint detection
        breakpoint = abs(current_corr - hist_avg) > 0.3

        return CorrelationAnalysis(
            current_correlation=current_corr,
            historical_avg=hist_avg,
            stress_correlation=stress_corr,
            correlation_breakpoint=breakpoint,
            dcc_estimate=current_corr,
        )


class RiskBudgetingEngine:
    """Risk parity and risk budgeting models."""

    def risk_parity(
        self, strategy_returns: dict[str, list[float]]
    ) -> dict[str, float]:
        """Equal Risk Contribution (risk parity) allocation."""
        if not strategy_returns:
            return {}
        # Compute vol for each strategy
        vols: dict[str, float] = {}
        for name, returns in strategy_returns.items():
            if returns:
                var = sum(r**2 for r in returns) / len(returns)
                vols[name] = math.sqrt(var) * math.sqrt(252)
            else:
                vols[name] = 0.01

        # Inverse-vol weighting
        total_inv_vol = sum(1.0 / v for v in vols.values() if v > 0)
        weights = {
            name: (1.0 / vol) / total_inv_vol if vol > 0 else 0.0
            for name, vol in vols.items()
        }
        return weights

    def hierarchical_risk_parity(
        self, strategy_returns: dict[str, list[float]]
    ) -> dict[str, float]:
        """Simplified Hierarchical Risk Parity (HRP) allocation."""
        if not strategy_returns:
            return {}

        strategies = list(strategy_returns.keys())
        n = len(strategies)
        if n <= 1:
            return {s: 1.0 for s in strategies}

        # Compute correlation distance matrix
        vols: dict[str, float] = {}
        for name, returns in strategy_returns.items():
            if returns:
                var = sum(r**2 for r in returns) / len(returns)
                vols[name] = math.sqrt(var) * math.sqrt(252)
            else:
                vols[name] = 0.01

        # Simplified: cluster by vol similarity, then inverse-vol within clusters
        sorted_by_vol = sorted(strategies, key=lambda s: vols[s])
        mid = n // 2
        cluster_a = sorted_by_vol[:mid]
        cluster_b = sorted_by_vol[mid:]

        # Equal weight between clusters, inverse-vol within
        weights: dict[str, float] = {}
        for cluster in [cluster_a, cluster_b]:
            cluster_inv_vol = sum(1.0 / vols[s] for s in cluster if vols[s] > 0)
            for s in cluster:
                w = (1.0 / vols[s]) / cluster_inv_vol if cluster_inv_vol > 0 else 1.0 / len(cluster)
                weights[s] = w * 0.5  # 50% per cluster
        return weights

    def target_risk_budget(
        self, strategy_returns: dict[str, list[float]], risk_budgets: dict[str, float]
    ) -> dict[str, float]:
        """Allocate to achieve target risk budget per strategy."""
        if not strategy_returns:
            return {}
        vols: dict[str, float] = {}
        for name, returns in strategy_returns.items():
            if returns:
                var = sum(r**2 for r in returns) / len(returns)
                vols[name] = math.sqrt(var) * math.sqrt(252)
            else:
                vols[name] = 0.01

        # w_i proportional to budget_i / vol_i
        raw = {s: risk_budgets.get(s, 1.0 / len(strategy_returns)) / vols[s] for s in strategy_returns if vols[s] > 0}
        total = sum(raw.values()) or 1.0
        return {s: w / total for s, w in raw.items()}


def _inv_norm_cdf(p: float) -> float:
    """Approximate inverse normal CDF (Beasley-Springer-Moro algorithm)."""
    if p <= 0:
        return -4.0
    if p >= 1:
        return 4.0
    if p == 0.5:
        return 0.0

    # Rational approximation
    a = [
        -3.969683028665376e1, 2.209460984245205e2,
        -2.759285104469687e2, 1.383577518672690e2,
        -3.066479806614716e1, 2.506628277459239e0,
    ]
    b = [
        -5.447609879822406e1, 1.615858368580409e2,
        -1.556989798598866e2, 6.680131188771972e1, -1.328068155288572e1,
    ]
    c = [
        -7.784894002430293e-3, -3.223964580411365e-1,
        -2.400758277161838e0, -2.549732539343734e0,
        4.374664141464968e0, 2.938163982698783e0,
    ]
    d = [
        7.784695709041462e-3, 3.224671290700398e-1,
        2.445134137142996e0, 3.754408661907416e0,
    ]

    p_low = 0.02425
    p_high = 1 - p_low

    if p < p_low:
        q = math.sqrt(-2 * math.log(p))
        return (((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) / ((((d[0]*q+d[1])*q+d[2])*q+d[3])*q+1)
    elif p <= p_high:
        q = p - 0.5
        r = q * q
        return (((((a[0]*r+a[1])*r+a[2])*r+a[3])*r+a[4])*r+a[5])*q / (((((b[0]*r+b[1])*r+b[2])*r+b[3])*r+b[4])*r+1)
    else:
        q = math.sqrt(-2 * math.log(1 - p))
        return -(((((c[0]*q+c[1])*q+c[2])*q+c[3])*q+c[4])*q+c[5]) / ((((d[0]*q+d[1])*q+d[2])*q+d[3])*q+1)


class RiskPricingEngine:
    """Full actuarial risk pricing engine for AI HFT fund."""

    def __init__(self) -> None:
        self.var_model = VaRModel()
        self.cvar_model = CVaRModel()
        self.tail_analyzer = TailRiskAnalyzer()
        self.copula_model = CopulaModel()
        self.stress_engine = StressTestingEngine()
        self.regime_model = RegimeConditionalRisk()
        self.decomposition_engine = RiskDecompositionEngine()
        self.drawdown_analyzer = DrawdownAnalyzer()
        self.liquidity_model = LiquidityRiskModel()
        self.correlation_model = DynamicCorrelationModel()
        self.risk_budgeting = RiskBudgetingEngine()

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

    def comprehensive_risk_report(
        self, returns: list[float], strategy_returns: dict[str, list[float]] | None = None
    ) -> dict[str, Any]:
        """Generate comprehensive risk report with all analytics."""
        metrics = self.full_risk_assessment(returns)
        drawdown = self.drawdown_analyzer.analyze(returns)
        regime, confidence = self.regime_model.detect_regime(returns)
        regime_var = self.regime_model.regime_var(returns, regime, 0.99)

        report: dict[str, Any] = {
            "risk_metrics": {
                "var_95": metrics.var_95,
                "var_99": metrics.var_99,
                "cvar_95": metrics.cvar_95,
                "cvar_99": metrics.cvar_99,
                "sharpe": metrics.sharpe_ratio,
                "sortino": metrics.sortino_ratio,
                "calmar": metrics.calmar_ratio,
                "tail_index": metrics.tail_index,
            },
            "drawdown": {
                "max_drawdown": drawdown.max_drawdown,
                "max_duration": drawdown.max_drawdown_duration,
                "current": drawdown.current_drawdown,
                "cdar_95": drawdown.cdar_95,
                "ulcer_index": drawdown.ulcer_index,
            },
            "regime": {
                "current": regime.value,
                "confidence": confidence,
                "regime_var_99": regime_var,
            },
            "tail_risk": {
                "hill_estimator": self.tail_analyzer.hill_estimator(returns),
                "pot": self.tail_analyzer.peaks_over_threshold(returns, 0.02),
                "return_level_100": self.tail_analyzer.return_level(returns, 100),
            },
        }

        if strategy_returns:
            weights = {s: 1.0 / len(strategy_returns) for s in strategy_returns}
            decomp = self.decomposition_engine.decompose(strategy_returns, weights)
            report["decomposition"] = {
                "total_var": decomp.total_var,
                "component_var": decomp.component_var,
                "diversification_ratio": decomp.diversification_ratio,
            }

        return report
