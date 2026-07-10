from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class BenchmarkComparison:
    alpha: float
    beta: float
    correlation: float
    tracking_error: float
    information_ratio: float
    up_capture: float
    down_capture: float
    active_return: float
    active_risk: float


@dataclass(slots=True)
class StyleAnalysisResult:
    exposures: pd.Series
    intercept: float
    r_squared: float
    explained_return: float
    residual_volatility: float


@dataclass(slots=True)
class PerformanceDecomposition:
    components: pd.DataFrame
    totals: dict[str, float]


@dataclass(slots=True)
class PerformanceAnalyticsReport:
    returns: pd.Series
    metrics: dict[str, float]
    benchmark_comparison: BenchmarkComparison | None
    attribution: pd.DataFrame | None
    style_analysis: StyleAnalysisResult | None
    decomposition: PerformanceDecomposition | None


class PerformanceAnalytics:
    """Comprehensive portfolio performance and attribution analytics."""

    def __init__(
        self,
        portfolio_returns: pd.Series | pd.DataFrame,
        benchmark_returns: pd.Series | pd.DataFrame | None = None,
        risk_free_rate: float = 0.0,
        periods_per_year: int = 252,
    ) -> None:
        self.portfolio_returns = self._to_series(portfolio_returns, "portfolio_return")
        self.benchmark_returns = None if benchmark_returns is None else self._to_series(benchmark_returns, "benchmark_return")
        self.risk_free_rate = float(risk_free_rate)
        self.periods_per_year = int(periods_per_year)

    @staticmethod
    def _to_series(data: pd.Series | pd.DataFrame, name: str) -> pd.Series:
        series = data.iloc[:, 0].copy() if isinstance(data, pd.DataFrame) else data.copy()
        series.index = pd.to_datetime(series.index)
        return series.sort_index().astype(float).rename(name)

    @staticmethod
    def _to_frame(data: pd.DataFrame | dict[str, Any], *, sort_index: bool = True) -> pd.DataFrame:
        frame = pd.DataFrame(data).copy()
        if isinstance(frame.index, pd.DatetimeIndex) or "timestamp" in frame.columns:
            if "timestamp" in frame.columns:
                frame["timestamp"] = pd.to_datetime(frame["timestamp"])
                frame = frame.set_index("timestamp")
            frame.index = pd.to_datetime(frame.index)
            if sort_index:
                frame = frame.sort_index()
        return frame.astype(float)

    @staticmethod
    def _max_drawdown(returns: pd.Series) -> float:
        wealth = (1.0 + returns.fillna(0.0)).cumprod()
        drawdown = wealth / wealth.cummax() - 1.0
        return float(drawdown.min()) if not drawdown.empty else 0.0

    def _annualized_return(self, returns: pd.Series) -> float:
        cleaned = returns.dropna()
        if cleaned.empty:
            return 0.0
        compounded = float((1.0 + cleaned).prod())
        return float(compounded ** (self.periods_per_year / len(cleaned)) - 1.0)

    def _annualized_volatility(self, returns: pd.Series) -> float:
        cleaned = returns.dropna()
        if cleaned.empty:
            return 0.0
        return float(cleaned.std(ddof=0) * np.sqrt(self.periods_per_year))

    def risk_adjusted_returns(self, returns: pd.Series | None = None) -> dict[str, float]:
        series = self.portfolio_returns if returns is None else self._to_series(returns, "portfolio_return")
        excess = series - (self.risk_free_rate / self.periods_per_year)
        downside = excess[excess < 0]
        volatility = excess.std(ddof=0)
        downside_deviation = downside.std(ddof=0)
        annual_return = self._annualized_return(series)
        annual_volatility = self._annualized_volatility(series)
        max_drawdown = self._max_drawdown(series)
        sharpe = 0.0 if volatility == 0 or np.isnan(volatility) else float(np.sqrt(self.periods_per_year) * excess.mean() / volatility)
        sortino = 0.0 if downside_deviation == 0 or np.isnan(downside_deviation) else float(np.sqrt(self.periods_per_year) * excess.mean() / downside_deviation)
        calmar = 0.0 if max_drawdown == 0 else float(annual_return / abs(max_drawdown))
        return {
            "total_return": float((1.0 + series.fillna(0.0)).prod() - 1.0),
            "annualized_return": annual_return,
            "annualized_volatility": annual_volatility,
            "sharpe_ratio": sharpe,
            "sortino_ratio": sortino,
            "calmar_ratio": calmar,
            "max_drawdown": max_drawdown,
        }

    def benchmark_comparison(self) -> BenchmarkComparison | None:
        if self.benchmark_returns is None:
            return None
        aligned = pd.concat([self.portfolio_returns, self.benchmark_returns], axis=1).dropna()
        if aligned.empty:
            return None
        portfolio = aligned.iloc[:, 0]
        benchmark = aligned.iloc[:, 1]
        covariance = np.cov(portfolio, benchmark, ddof=0)[0, 1]
        benchmark_variance = np.var(benchmark, ddof=0)
        beta = 0.0 if benchmark_variance == 0 else float(covariance / benchmark_variance)
        correlation = float(portfolio.corr(benchmark)) if len(aligned) > 1 else 0.0
        active = portfolio - benchmark
        tracking_error = float(active.std(ddof=0) * np.sqrt(self.periods_per_year)) if len(active) > 1 else 0.0
        information_ratio = 0.0 if active.std(ddof=0) == 0 else float(np.sqrt(self.periods_per_year) * active.mean() / active.std(ddof=0))
        alpha = float((portfolio.mean() - self.risk_free_rate / self.periods_per_year) - beta * (benchmark.mean() - self.risk_free_rate / self.periods_per_year))
        alpha *= self.periods_per_year
        up_market = benchmark > 0
        down_market = benchmark < 0
        up_capture = float(portfolio[up_market].mean() / benchmark[up_market].mean()) if up_market.any() and benchmark[up_market].mean() != 0 else 0.0
        down_capture = float(portfolio[down_market].mean() / benchmark[down_market].mean()) if down_market.any() and benchmark[down_market].mean() != 0 else 0.0
        return BenchmarkComparison(
            alpha=alpha,
            beta=beta,
            correlation=correlation,
            tracking_error=tracking_error,
            information_ratio=information_ratio,
            up_capture=up_capture,
            down_capture=down_capture,
            active_return=self._annualized_return(active),
            active_risk=tracking_error,
        )

    def portfolio_performance_attribution(
        self,
        asset_returns: pd.DataFrame,
        asset_weights: pd.DataFrame,
        benchmark_weights: pd.DataFrame | None = None,
    ) -> pd.DataFrame:
        returns = self._to_frame(asset_returns)
        weights = self._to_frame(asset_weights).reindex(returns.index).ffill().fillna(0.0)
        if set(returns.columns) != set(weights.columns):
            common = [column for column in returns.columns if column in weights.columns]
            returns = returns[common]
            weights = weights[common]
        period_contributions = returns.mul(weights, axis=0)
        attribution = pd.DataFrame(
            {
                "average_weight": weights.mean(),
                "cumulative_return": (1.0 + returns).prod() - 1.0,
                "cumulative_contribution": period_contributions.sum(),
                "annualized_contribution": period_contributions.mean() * self.periods_per_year,
            }
        )
        if benchmark_weights is not None:
            benchmark_frame = self._to_frame(benchmark_weights).reindex(returns.index).ffill().fillna(0.0)
            benchmark_frame = benchmark_frame[attribution.index]
            active_contributions = returns.mul(weights - benchmark_frame, axis=0).sum()
            attribution["active_contribution"] = active_contributions
        return attribution.sort_values("cumulative_contribution", ascending=False)

    def style_analysis(self, style_factor_returns: pd.DataFrame) -> StyleAnalysisResult:
        factors = self._to_frame(style_factor_returns)
        aligned = pd.concat([self.portfolio_returns, factors], axis=1).dropna()
        if aligned.empty:
            raise ValueError("No overlapping observations for style analysis")
        y = aligned.iloc[:, 0].to_numpy()
        x = aligned.iloc[:, 1:].to_numpy()
        design = np.column_stack([np.ones(len(aligned)), x])
        coefficients, *_ = np.linalg.lstsq(design, y, rcond=None)
        fitted = design @ coefficients
        residuals = y - fitted
        ss_total = np.sum((y - y.mean()) ** 2)
        ss_residual = np.sum(residuals ** 2)
        r_squared = 0.0 if ss_total == 0 else float(1.0 - ss_residual / ss_total)
        return StyleAnalysisResult(
            exposures=pd.Series(coefficients[1:], index=aligned.columns[1:], name="style_exposure"),
            intercept=float(coefficients[0]),
            r_squared=r_squared,
            explained_return=float(np.mean(fitted) * self.periods_per_year),
            residual_volatility=float(np.std(residuals, ddof=0) * np.sqrt(self.periods_per_year)),
        )

    def performance_decomposition(
        self,
        asset_returns: pd.DataFrame,
        asset_weights: pd.DataFrame,
        trading_costs: pd.Series | None = None,
        management_fee: float = 0.0,
        style_factor_returns: pd.DataFrame | None = None,
    ) -> PerformanceDecomposition:
        returns = self._to_frame(asset_returns)
        weights = self._to_frame(asset_weights).reindex(returns.index).ffill().fillna(0.0)
        contributions = returns.mul(weights, axis=0)
        gross = contributions.sum(axis=1).rename("gross_return")
        components = pd.DataFrame({"gross_return": gross})
        additive_adjustments: list[str] = []
        if self.benchmark_returns is not None:
            benchmark = self.benchmark_returns.reindex(returns.index).fillna(0.0)
            comparison = self.benchmark_comparison()
            beta = 0.0 if comparison is None else comparison.beta
            components["benchmark_component"] = benchmark * beta
            components["active_component"] = gross - components["benchmark_component"]
        if style_factor_returns is not None:
            style = self.style_analysis(style_factor_returns)
            aligned_factors = self._to_frame(style_factor_returns).reindex(returns.index).fillna(0.0)
            components["style_component"] = aligned_factors.mul(style.exposures, axis=1).sum(axis=1) + style.intercept
        if trading_costs is not None:
            costs = self._to_series(trading_costs, "trading_cost").reindex(returns.index).fillna(0.0)
            components["trading_cost"] = -costs.abs()
            additive_adjustments.append("trading_cost")
        if management_fee:
            components["management_fee"] = -(management_fee / self.periods_per_year)
            additive_adjustments.append("management_fee")
        components["net_return"] = components["gross_return"] + components[additive_adjustments].sum(axis=1) if additive_adjustments else components["gross_return"]
        totals = {column: float(components[column].sum()) for column in components.columns}
        return PerformanceDecomposition(components=components, totals=totals)

    def report(
        self,
        asset_returns: pd.DataFrame | None = None,
        asset_weights: pd.DataFrame | None = None,
        benchmark_weights: pd.DataFrame | None = None,
        style_factor_returns: pd.DataFrame | None = None,
        trading_costs: pd.Series | None = None,
        management_fee: float = 0.0,
    ) -> PerformanceAnalyticsReport:
        attribution = None
        decomposition = None
        style = None
        if asset_returns is not None and asset_weights is not None:
            attribution = self.portfolio_performance_attribution(asset_returns, asset_weights, benchmark_weights=benchmark_weights)
            decomposition = self.performance_decomposition(
                asset_returns,
                asset_weights,
                trading_costs=trading_costs,
                management_fee=management_fee,
                style_factor_returns=style_factor_returns,
            )
        if style_factor_returns is not None:
            style = self.style_analysis(style_factor_returns)
        metrics = self.risk_adjusted_returns()
        comparison = self.benchmark_comparison()
        if comparison is not None:
            metrics.update(
                {
                    "alpha": comparison.alpha,
                    "beta": comparison.beta,
                    "tracking_error": comparison.tracking_error,
                    "information_ratio": comparison.information_ratio,
                }
            )
        return PerformanceAnalyticsReport(
            returns=self.portfolio_returns,
            metrics=metrics,
            benchmark_comparison=comparison,
            attribution=attribution,
            style_analysis=style,
            decomposition=decomposition,
        )
