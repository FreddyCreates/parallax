"""Risk management models for portfolios and trading books.

The module provides market-risk estimators, scenario analysis, copula-based
simulation, and factor-level analytics suitable for research and risk
reporting workflows.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np
import pandas as pd
from numpy.typing import ArrayLike
from scipy.stats import kurtosis, norm, skew


@dataclass(slots=True)
class RiskReport:
    """Unified VaR/CVaR report."""

    method: str
    confidence: float
    var: float
    cvar: float
    horizon_days: int


@dataclass(slots=True)
class StressScenario:
    """Scenario definition for factor-based stress testing."""

    name: str
    shocks: dict[str, float]
    description: str = ""


@dataclass(slots=True)
class RiskFactorDecomposition:
    """Factor exposure and attribution summary."""

    exposures: pd.Series
    factor_contributions: pd.Series
    residual_volatility: float
    r_squared: float


class GaussianCopulaModel:
    """Gaussian copula fitted to empirical marginal distributions."""

    def __init__(self) -> None:
        self.columns: list[str] | None = None
        self.correlation: np.ndarray | None = None
        self.sorted_marginals: dict[str, np.ndarray] | None = None

    def fit(self, data: pd.DataFrame) -> "GaussianCopulaModel":
        """Estimate the copula correlation matrix from observations."""
        frame = data.dropna().copy()
        self.columns = list(frame.columns)
        uniforms = frame.rank(method="average", pct=True).clip(1e-6, 1.0 - 1e-6)
        gaussian = uniforms.apply(norm.ppf)
        self.correlation = gaussian.corr().to_numpy()
        self.sorted_marginals = {column: np.sort(frame[column].to_numpy()) for column in frame.columns}
        return self

    def simulate(self, n_samples: int, random_state: int | None = None) -> pd.DataFrame:
        """Generate samples that preserve empirical marginals and copula dependence."""
        if self.columns is None or self.correlation is None or self.sorted_marginals is None:
            raise RuntimeError("fit must be called before simulate")
        rng = np.random.default_rng(random_state)
        chol = np.linalg.cholesky(self.correlation + np.eye(len(self.columns)) * 1e-12)
        gaussian = rng.standard_normal((n_samples, len(self.columns))) @ chol.T
        uniforms = norm.cdf(gaussian)
        samples: dict[str, np.ndarray] = {}
        for idx, column in enumerate(self.columns):
            sorted_values = self.sorted_marginals[column]
            positions = np.linspace(0.0, 1.0, len(sorted_values), endpoint=False) + 0.5 / len(sorted_values)
            samples[column] = np.interp(uniforms[:, idx], positions, sorted_values)
        return pd.DataFrame(samples)


def _returns_series(returns: ArrayLike) -> pd.Series:
    return pd.Series(returns, dtype=float).dropna()


def historical_var_cvar(returns: ArrayLike, confidence: float = 0.95, horizon_days: int = 1) -> RiskReport:
    """Compute historical VaR and CVaR from a return distribution."""
    series = _returns_series(returns)
    quantile = float(series.quantile(1.0 - confidence))
    tail = series[series <= quantile]
    scale = np.sqrt(horizon_days)
    return RiskReport(
        method="historical",
        confidence=confidence,
        var=float(-quantile * scale),
        cvar=float(-tail.mean() * scale),
        horizon_days=horizon_days,
    )


def gaussian_var_cvar(returns: ArrayLike, confidence: float = 0.95, horizon_days: int = 1) -> RiskReport:
    """Compute parametric Gaussian VaR/CVaR."""
    series = _returns_series(returns)
    mean = float(series.mean())
    sigma = float(series.std(ddof=1))
    alpha = 1.0 - confidence
    z = norm.ppf(alpha)
    scale = np.sqrt(horizon_days)
    var = -(mean + sigma * z) * scale
    cvar = (-mean + sigma * norm.pdf(z) / alpha) * scale
    return RiskReport(method="gaussian", confidence=confidence, var=float(var), cvar=float(cvar), horizon_days=horizon_days)


def cornish_fisher_var_cvar(returns: ArrayLike, confidence: float = 0.95, horizon_days: int = 1) -> RiskReport:
    """Adjust parametric VaR/CVaR for skewness and kurtosis."""
    series = _returns_series(returns)
    mean = float(series.mean())
    sigma = float(series.std(ddof=1))
    s = float(skew(series, bias=False))
    k = float(kurtosis(series, fisher=True, bias=False))
    alpha = 1.0 - confidence
    z = norm.ppf(alpha)
    z_cf = z + (z**2 - 1) * s / 6 + (z**3 - 3 * z) * k / 24 - (2 * z**3 - 5 * z) * s**2 / 36
    scale = np.sqrt(horizon_days)
    var = -(mean + sigma * z_cf) * scale
    cvar = (-mean + sigma * norm.pdf(z_cf) / alpha) * scale
    return RiskReport(method="cornish_fisher", confidence=confidence, var=float(var), cvar=float(cvar), horizon_days=horizon_days)


def monte_carlo_portfolio_risk(
    weights: ArrayLike,
    expected_returns: ArrayLike,
    covariance: ArrayLike,
    confidence: float = 0.95,
    horizon_days: int = 1,
    n_scenarios: int = 50_000,
    random_state: int | None = None,
) -> RiskReport:
    """Estimate portfolio VaR/CVaR via multivariate Monte Carlo simulation."""
    rng = np.random.default_rng(random_state)
    weights_arr = np.asarray(weights, dtype=float)
    mean = np.asarray(expected_returns, dtype=float) * horizon_days
    cov = np.asarray(covariance, dtype=float) * horizon_days
    scenarios = rng.multivariate_normal(mean, cov, size=n_scenarios)
    losses = -(scenarios @ weights_arr)
    var = float(np.quantile(losses, confidence))
    cvar = float(losses[losses >= var].mean())
    return RiskReport(method="monte_carlo", confidence=confidence, var=var, cvar=cvar, horizon_days=horizon_days)


def stress_test_portfolio(exposures: pd.Series, scenarios: Sequence[StressScenario]) -> pd.DataFrame:
    """Apply deterministic factor shocks to a portfolio exposure vector."""
    rows = []
    exposures = exposures.astype(float)
    for scenario in scenarios:
        pnl = 0.0
        shocked = {}
        for factor, shock in scenario.shocks.items():
            factor_pnl = exposures.get(factor, 0.0) * shock
            shocked[factor] = factor_pnl
            pnl += factor_pnl
        rows.append({"scenario": scenario.name, "pnl": pnl, "description": scenario.description, **shocked})
    return pd.DataFrame(rows).set_index("scenario")


def risk_factor_decomposition(portfolio_returns: pd.Series, factor_returns: pd.DataFrame) -> RiskFactorDecomposition:
    """Decompose portfolio risk into systematic factor contributions."""
    aligned = pd.concat([portfolio_returns.rename("portfolio"), factor_returns], axis=1).dropna()
    y = aligned["portfolio"].to_numpy()
    x = aligned[factor_returns.columns].to_numpy()
    x_design = np.column_stack([np.ones(len(x)), x])
    coefficients, _, _, _ = np.linalg.lstsq(x_design, y, rcond=None)
    fitted = x_design @ coefficients
    residual = y - fitted
    factor_exposures = pd.Series(coefficients[1:], index=factor_returns.columns, name="exposure")
    covariance = factor_returns.loc[aligned.index].cov()
    marginal = covariance.to_numpy() @ factor_exposures.to_numpy()
    contributions = factor_exposures.to_numpy() * marginal
    contribution_series = pd.Series(contributions, index=factor_returns.columns, name="risk_contribution")
    total_variance = np.var(y, ddof=1)
    r_squared = 1.0 - np.var(residual, ddof=1) / total_variance if total_variance > 1e-16 else 0.0
    return RiskFactorDecomposition(
        exposures=factor_exposures,
        factor_contributions=contribution_series,
        residual_volatility=float(np.std(residual, ddof=1)),
        r_squared=float(r_squared),
    )


class PortfolioAnalytics:
    """High-level portfolio analytics and decomposition helpers."""

    @staticmethod
    def risk_contributions(weights: ArrayLike, covariance: ArrayLike) -> pd.Series:
        """Compute marginal contribution to portfolio volatility."""
        weights_arr = np.asarray(weights, dtype=float)
        cov = np.asarray(covariance, dtype=float)
        portfolio_vol = np.sqrt(weights_arr @ cov @ weights_arr)
        contributions = weights_arr * (cov @ weights_arr) / portfolio_vol
        return pd.Series(contributions, name="volatility_contribution")

    @staticmethod
    def summary(returns: pd.Series, benchmark: pd.Series | None = None, risk_free_rate: float = 0.0, annualization: int = 252) -> dict[str, float]:
        """Compute standard portfolio performance and benchmark metrics."""
        series = pd.Series(returns, dtype=float).dropna()
        total_return = (1.0 + series).prod() - 1.0
        annual_return = (1.0 + total_return) ** (annualization / max(len(series), 1)) - 1.0
        annual_vol = float(series.std(ddof=0) * np.sqrt(annualization))
        excess = annual_return - risk_free_rate
        sharpe = excess / annual_vol if annual_vol > 1e-12 else np.nan
        downside = series[series < 0].std(ddof=0) * np.sqrt(annualization)
        sortino = excess / downside if downside and downside > 1e-12 else np.nan
        wealth = (1.0 + series).cumprod()
        drawdown = wealth / wealth.cummax() - 1.0
        metrics = {
            "total_return": float(total_return),
            "annual_return": float(annual_return),
            "annual_volatility": float(annual_vol),
            "sharpe_ratio": float(sharpe),
            "sortino_ratio": float(sortino),
            "max_drawdown": float(drawdown.min()),
        }
        if benchmark is not None:
            aligned = pd.concat([series.rename("portfolio"), benchmark.rename("benchmark")], axis=1).dropna()
            beta = aligned.cov().iloc[0, 1] / aligned["benchmark"].var(ddof=1)
            tracking_error = float((aligned["portfolio"] - aligned["benchmark"]).std(ddof=0) * np.sqrt(annualization))
            information_ratio = ((aligned["portfolio"] - aligned["benchmark"]).mean() * annualization) / tracking_error if tracking_error > 1e-12 else np.nan
            metrics.update({"beta": float(beta), "tracking_error": tracking_error, "information_ratio": float(information_ratio)})
        return metrics
