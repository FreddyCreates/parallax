from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class FactorExposureReport:
    factor_exposures: pd.Series
    asset_contributions: pd.DataFrame


@dataclass(slots=True)
class RiskContributionReport:
    portfolio_volatility: float
    marginal_contribution: pd.Series
    component_contribution: pd.Series
    percentage_contribution: pd.Series


@dataclass(slots=True)
class ScenarioRiskResult:
    scenario_impacts: pd.DataFrame
    worst_case_return: float
    expected_shortfall: float


@dataclass(slots=True)
class RiskAnalyticsReport:
    exposures: FactorExposureReport | None
    risk_contribution: RiskContributionReport
    scenario_analysis: ScenarioRiskResult | None
    incremental_risk: pd.Series


class RiskAnalytics:
    """Portfolio risk decomposition and scenario analytics."""

    def __init__(
        self,
        weights: pd.Series | dict[str, float],
        covariance_matrix: pd.DataFrame,
        factor_loadings: pd.DataFrame | None = None,
    ) -> None:
        self.weights = self._to_series(weights, "weight")
        self.covariance_matrix = covariance_matrix.copy().astype(float)
        self.covariance_matrix = self.covariance_matrix.reindex(index=self.weights.index, columns=self.weights.index).fillna(0.0)
        self.factor_loadings = None if factor_loadings is None else factor_loadings.copy().astype(float).reindex(self.weights.index).fillna(0.0)

    @staticmethod
    def _to_series(data: pd.Series | dict[str, float], name: str) -> pd.Series:
        series = pd.Series(data, dtype=float).copy() if not isinstance(data, pd.Series) else data.astype(float).copy()
        return series.rename(name)

    def portfolio_volatility(self, weights: pd.Series | None = None) -> float:
        vector = self.weights if weights is None else self._to_series(weights, "weight").reindex(self.weights.index).fillna(0.0)
        variance = float(vector.to_numpy() @ self.covariance_matrix.to_numpy() @ vector.to_numpy())
        return float(np.sqrt(max(variance, 0.0)))

    def factor_exposures(self, factor_loadings: pd.DataFrame | None = None) -> FactorExposureReport | None:
        loadings = self.factor_loadings if factor_loadings is None else factor_loadings.copy().astype(float).reindex(self.weights.index).fillna(0.0)
        if loadings is None:
            return None
        asset_contributions = loadings.mul(self.weights, axis=0)
        exposures = asset_contributions.sum(axis=0).rename("factor_exposure")
        return FactorExposureReport(factor_exposures=exposures, asset_contributions=asset_contributions)

    def marginal_risk_contribution(self) -> pd.Series:
        portfolio_vol = self.portfolio_volatility()
        if portfolio_vol == 0.0:
            return pd.Series(0.0, index=self.weights.index, name="marginal_risk_contribution")
        marginal = self.covariance_matrix.to_numpy() @ self.weights.to_numpy() / portfolio_vol
        return pd.Series(marginal, index=self.weights.index, name="marginal_risk_contribution")

    def risk_contribution(self) -> RiskContributionReport:
        portfolio_vol = self.portfolio_volatility()
        marginal = self.marginal_risk_contribution()
        component = (self.weights * marginal).rename("component_contribution")
        percent = component / portfolio_vol if portfolio_vol else component * 0.0
        return RiskContributionReport(
            portfolio_volatility=portfolio_vol,
            marginal_contribution=marginal,
            component_contribution=component,
            percentage_contribution=percent.rename("percentage_contribution"),
        )

    def incremental_risk(self, step: float = 0.01) -> pd.Series:
        base_vol = self.portfolio_volatility()
        increments: dict[str, float] = {}
        for asset in self.weights.index:
            bumped = self.weights.copy()
            bumped[asset] += step
            increments[asset] = self.portfolio_volatility(bumped) - base_vol
        return pd.Series(increments, name="incremental_risk")

    def scenario_risk_analysis(
        self,
        scenarios: pd.DataFrame,
        factor_scenarios: bool = False,
    ) -> ScenarioRiskResult:
        scenario_frame = scenarios.copy().astype(float)
        if factor_scenarios:
            if self.factor_loadings is None:
                raise ValueError("factor_loadings are required for factor scenario analysis")
            asset_shocks = scenario_frame @ self.factor_loadings.T
            scenario_impacts = asset_shocks.mul(self.weights, axis=1)
        else:
            scenario_impacts = scenario_frame.reindex(columns=self.weights.index).fillna(0.0).mul(self.weights, axis=1)
        scenario_returns = scenario_impacts.sum(axis=1)
        tail = scenario_returns[scenario_returns <= scenario_returns.quantile(0.05)]
        return ScenarioRiskResult(
            scenario_impacts=pd.concat([scenario_impacts, scenario_returns.rename("portfolio_return")], axis=1),
            worst_case_return=float(scenario_returns.min()) if not scenario_returns.empty else 0.0,
            expected_shortfall=float(tail.mean()) if not tail.empty else float(scenario_returns.min()) if not scenario_returns.empty else 0.0,
        )

    def report(self, scenarios: pd.DataFrame | None = None, factor_scenarios: bool = False) -> RiskAnalyticsReport:
        scenario_analysis = None if scenarios is None else self.scenario_risk_analysis(scenarios, factor_scenarios=factor_scenarios)
        return RiskAnalyticsReport(
            exposures=self.factor_exposures(),
            risk_contribution=self.risk_contribution(),
            scenario_analysis=scenario_analysis,
            incremental_risk=self.incremental_risk(),
        )
