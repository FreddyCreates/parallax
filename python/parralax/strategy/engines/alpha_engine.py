"""Alpha Engine — Multi-strategy alpha generation and combination."""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Any


@dataclass
class AlphaFactor:
    name: str
    value: float
    weight: float
    decay_halflife: int = 5
    ic: float = 0.0  # Information coefficient


@dataclass
class CombinedAlpha:
    symbol: str
    raw_alpha: float
    risk_adjusted_alpha: float
    confidence: float
    contributing_factors: list[AlphaFactor]
    position_size_suggestion: float


class AlphaEngine:
    """Multi-factor alpha generation engine.

    Combines signals from multiple sources into a unified alpha score
    that drives position sizing and trade execution.
    """

    def __init__(self, risk_aversion: float = 2.0) -> None:
        self.risk_aversion = risk_aversion
        self.factors: dict[str, AlphaFactor] = {}
        self.alpha_history: dict[str, list[float]] = {}

    def register_factor(
        self,
        name: str,
        weight: float = 1.0,
        decay_halflife: int = 5,
    ) -> None:
        """Register an alpha factor."""
        self.factors[name] = AlphaFactor(
            name=name, value=0.0, weight=weight, decay_halflife=decay_halflife
        )

    def update_factor(self, name: str, value: float) -> None:
        """Update a factor's current value."""
        if name in self.factors:
            self.factors[name].value = value

    def combine_alphas(
        self,
        symbol: str,
        factor_values: dict[str, float],
        volatility: float = 0.02,
    ) -> CombinedAlpha:
        """Combine multiple alpha factors into unified signal."""
        contributing = []
        weighted_sum = 0.0
        total_weight = 0.0

        for name, value in factor_values.items():
            factor = self.factors.get(name)
            if factor:
                factor.value = value
                weighted_sum += value * factor.weight
                total_weight += factor.weight
                contributing.append(factor)

        if total_weight == 0:
            raw_alpha = 0.0
        else:
            raw_alpha = weighted_sum / total_weight

        # Risk-adjusted alpha (Kelly-inspired sizing)
        if volatility > 0:
            risk_adjusted = raw_alpha / (self.risk_aversion * volatility**2)
        else:
            risk_adjusted = raw_alpha

        # Confidence from factor agreement
        signs = [1 if f.value > 0 else -1 for f in contributing if f.value != 0]
        confidence = abs(sum(signs)) / max(1, len(signs)) if signs else 0.0

        # Position size suggestion (fraction of capital)
        size = min(0.10, abs(risk_adjusted) * confidence * 0.01)

        # Track history
        if symbol not in self.alpha_history:
            self.alpha_history[symbol] = []
        self.alpha_history[symbol].append(raw_alpha)

        return CombinedAlpha(
            symbol=symbol,
            raw_alpha=raw_alpha,
            risk_adjusted_alpha=risk_adjusted,
            confidence=confidence,
            contributing_factors=contributing,
            position_size_suggestion=size,
        )
