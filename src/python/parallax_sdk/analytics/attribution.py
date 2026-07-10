from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class BrinsonAttributionResult:
    attribution: pd.DataFrame
    totals: pd.Series


@dataclass(slots=True)
class FactorAttributionResult:
    factor_contributions: pd.DataFrame
    total_factor_return: pd.Series
    specific_return: pd.Series


@dataclass(slots=True)
class MultiPeriodAttributionResult:
    linked_effects: pd.Series
    period_effects: pd.DataFrame
    method: str


@dataclass(slots=True)
class AttributionAnalysisReport:
    brinson: BrinsonAttributionResult | None
    factor: FactorAttributionResult | None
    multi_period: MultiPeriodAttributionResult | None


class AttributionAnalyzer:
    """Brinson and factor-based performance attribution."""

    @staticmethod
    def _to_frame(data: pd.DataFrame | dict[str, Any]) -> pd.DataFrame:
        frame = pd.DataFrame(data).copy().astype(float)
        if isinstance(frame.index, pd.DatetimeIndex) or "timestamp" in frame.columns:
            if "timestamp" in frame.columns:
                frame["timestamp"] = pd.to_datetime(frame["timestamp"])
                frame = frame.set_index("timestamp")
            frame.index = pd.to_datetime(frame.index)
            frame = frame.sort_index()
        return frame

    def brinson_attribution(
        self,
        portfolio_weights: pd.DataFrame,
        benchmark_weights: pd.DataFrame,
        portfolio_returns: pd.DataFrame,
        benchmark_returns: pd.DataFrame,
    ) -> BrinsonAttributionResult:
        pw = self._to_frame(portfolio_weights)
        bw = self._to_frame(benchmark_weights).reindex(index=pw.index, columns=pw.columns).ffill().fillna(0.0)
        pr = self._to_frame(portfolio_returns).reindex(index=pw.index, columns=pw.columns).fillna(0.0)
        br = self._to_frame(benchmark_returns).reindex(index=pw.index, columns=pw.columns).fillna(0.0)
        benchmark_total = (bw * br).sum(axis=1)
        allocation = ((pw - bw) * (br.sub(benchmark_total, axis=0))).sum(axis=0)
        selection = (bw * (pr - br)).sum(axis=0)
        interaction = ((pw - bw) * (pr - br)).sum(axis=0)
        total = allocation + selection + interaction
        attribution = pd.DataFrame(
            {
                "allocation": allocation,
                "selection": selection,
                "interaction": interaction,
                "total": total,
            }
        )
        return BrinsonAttributionResult(attribution=attribution, totals=attribution.sum(axis=0))

    def factor_attribution(
        self,
        factor_exposures: pd.DataFrame,
        factor_returns: pd.DataFrame,
        portfolio_weights: pd.Series | dict[str, float],
        asset_returns: pd.DataFrame | None = None,
    ) -> FactorAttributionResult:
        exposures = self._to_frame(factor_exposures)
        factors = self._to_frame(factor_returns)
        weights = pd.Series(portfolio_weights, dtype=float) if not isinstance(portfolio_weights, pd.Series) else portfolio_weights.astype(float)
        exposures = exposures.reindex(weights.index).fillna(0.0)
        portfolio_factor_exposure = exposures.mul(weights, axis=0).sum(axis=0)
        factor_contributions = factors.mul(portfolio_factor_exposure, axis=1)
        total_factor_return = factor_contributions.sum(axis=1).rename("factor_return")
        if asset_returns is None:
            specific = pd.Series(0.0, index=total_factor_return.index, name="specific_return")
        else:
            realized = self._to_frame(asset_returns).reindex(columns=weights.index).fillna(0.0).mul(weights, axis=1).sum(axis=1)
            specific = (realized - total_factor_return).rename("specific_return")
        return FactorAttributionResult(
            factor_contributions=factor_contributions,
            total_factor_return=total_factor_return,
            specific_return=specific,
        )

    def allocation_vs_selection(self, brinson: BrinsonAttributionResult) -> pd.Series:
        return brinson.attribution[["allocation", "selection"]].sum(axis=0)

    def interaction_effects(self, brinson: BrinsonAttributionResult) -> pd.Series:
        return brinson.attribution["interaction"].rename("interaction_effect")

    def multi_period_attribution(
        self,
        period_effects: pd.DataFrame,
        method: str = "geometric",
    ) -> MultiPeriodAttributionResult:
        effects = self._to_frame(period_effects)
        method_normalized = method.lower()
        if method_normalized == "arithmetic":
            linked = effects.sum(axis=0)
        elif method_normalized == "geometric":
            linked = (1.0 + effects).prod(axis=0) - 1.0
        else:
            raise ValueError("method must be 'arithmetic' or 'geometric'")
        return MultiPeriodAttributionResult(linked_effects=linked.rename("linked_effect"), period_effects=effects, method=method_normalized)

    def report(
        self,
        portfolio_weights: pd.DataFrame | None = None,
        benchmark_weights: pd.DataFrame | None = None,
        portfolio_returns: pd.DataFrame | None = None,
        benchmark_returns: pd.DataFrame | None = None,
        factor_exposures: pd.DataFrame | None = None,
        factor_returns: pd.DataFrame | None = None,
        asset_returns: pd.DataFrame | None = None,
        asset_weights: pd.Series | dict[str, float] | None = None,
        period_effects: pd.DataFrame | None = None,
        method: str = "geometric",
    ) -> AttributionAnalysisReport:
        brinson = None
        factor = None
        multi_period = None
        if all(item is not None for item in [portfolio_weights, benchmark_weights, portfolio_returns, benchmark_returns]):
            brinson = self.brinson_attribution(portfolio_weights, benchmark_weights, portfolio_returns, benchmark_returns)
        if factor_exposures is not None and factor_returns is not None and asset_weights is not None:
            factor = self.factor_attribution(factor_exposures, factor_returns, asset_weights, asset_returns=asset_returns)
        if period_effects is not None:
            multi_period = self.multi_period_attribution(period_effects, method=method)
        return AttributionAnalysisReport(brinson=brinson, factor=factor, multi_period=multi_period)
