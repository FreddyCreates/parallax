"""Cross-Asset Arbitrage Strategy.

Exploits pricing inefficiencies across correlated assets, markets, and instruments.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class CrossAssetSignal:
    asset_a: str
    asset_b: str
    spread: float
    z_score: float
    direction: str
    expected_convergence: float
    confidence: float
    asset_class_a: str
    asset_class_b: str


class CrossAssetArbitrageStrategy:
    """Cross-asset arbitrage across equities, futures, FX, crypto."""

    def __init__(
        self,
        entry_threshold: float = 2.5,
        exit_threshold: float = 0.5,
        max_divergence: float = 5.0,
    ) -> None:
        self.entry_threshold = entry_threshold
        self.exit_threshold = exit_threshold
        self.max_divergence = max_divergence
        self.relationships: dict[str, dict[str, Any]] = {}
        self.last_state: dict[str, Any] = {}

    def _mean(self, values: list[float]) -> float:
        return sum(values) / len(values) if values else 0.0

    def _std(self, values: list[float]) -> float:
        if len(values) < 2:
            return 0.0
        mean = self._mean(values)
        variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
        return math.sqrt(max(variance, 0.0))

    def register_relationship(
        self,
        asset_a: str,
        asset_b: str,
        asset_class_a: str,
        asset_class_b: str,
        theoretical_ratio: float = 1.0,
    ) -> None:
        """Register a cross-asset relationship."""
        key = f"{asset_a}/{asset_b}"
        self.relationships[key] = {
            "asset_a": asset_a,
            "asset_b": asset_b,
            "class_a": asset_class_a,
            "class_b": asset_class_b,
            "ratio": theoretical_ratio,
            "history": [],
        }

    def calculate_correlation(self, series_a: list[float], series_b: list[float]) -> float:
        """Calculate cross-asset Pearson correlation."""
        if len(series_a) != len(series_b) or len(series_a) < 5:
            return 0.0
        mean_a = self._mean(series_a)
        mean_b = self._mean(series_b)
        covariance = sum((a - mean_a) * (b - mean_b) for a, b in zip(series_a, series_b)) / len(series_a)
        std_a = self._std(series_a)
        std_b = self._std(series_b)
        if std_a == 0 or std_b == 0:
            return 0.0
        return covariance / (std_a * std_b)

    def calculate_basis(self, spot: float, futures: float) -> float:
        """Calculate basis for spot-futures relationships."""
        if spot == 0:
            return 0.0
        return (futures - spot) / spot

    def fair_value_ratio(self, historical_ratios: list[float], theoretical_ratio: float) -> float:
        """Blend theoretical and empirical relative-value anchors."""
        if len(historical_ratios) < 5:
            return theoretical_ratio
        return 0.4 * theoretical_ratio + 0.6 * self._mean(historical_ratios)

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return cross-asset divergence risk metrics."""
        z_score = abs(float(self.last_state.get("z_score", 0.0)))
        correlation = abs(float(self.last_state.get("correlation", 0.0)))
        max_loss = z_score * max(1.0, 1.0 - correlation + 0.5)
        expected_drawdown = max_loss * 0.4
        return {
            "correlation": correlation,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return cross-asset relationship health."""
        return {
            "healthy": not self.last_state or abs(float(self.last_state.get("correlation", 0.0))) >= 0.25,
            "relationships": list(self.relationships.keys()),
            "last_state": self.last_state,
        }

    def generate_signal(
        self,
        asset_a: str,
        asset_b: str,
        price_a: float,
        price_b: float,
        historical_ratios: list[float] | None = None,
    ) -> CrossAssetSignal:
        """Generate cross-asset arbitrage signal."""
        key = f"{asset_a}/{asset_b}"
        rel = self.relationships.get(key, {})
        ratio = price_a / price_b if price_b != 0 else 0.0
        theoretical_ratio = float(rel.get("ratio", 1.0))
        history = historical_ratios or list(rel.get("history", []))
        fair_ratio = self.fair_value_ratio(history, theoretical_ratio)
        spread = ratio - fair_ratio
        ratio_std = self._std(history) if history else abs(fair_ratio) * 0.02
        z_score = spread / ratio_std if ratio_std > 0 else 0.0
        correlation = self.calculate_correlation(history[:-1], history[1:]) if len(history) > 6 else 0.0

        if z_score > self.entry_threshold:
            direction = "short_a_long_b"
        elif z_score < -self.entry_threshold:
            direction = "long_a_short_b"
        elif abs(z_score) < self.exit_threshold:
            direction = "flat"
        else:
            direction = "flat"

        basis = self.calculate_basis(price_b, price_a) if "future" in str(rel.get("class_a", "")).lower() else 0.0
        confidence = min(1.0, abs(z_score) / self.max_divergence) * (0.6 + 0.4 * min(abs(correlation), 1.0))
        expected_convergence = abs(spread) * (0.4 + 0.6 * min(abs(correlation), 1.0))

        rel.setdefault("history", []).append(ratio)
        if len(rel.get("history", [])) > 120:
            rel["history"] = rel["history"][-120:]
        if rel:
            self.relationships[key] = rel

        self.last_state = {
            "pair": key,
            "z_score": z_score,
            "correlation": correlation,
            "basis": basis,
            "fair_ratio": fair_ratio,
        }
        return CrossAssetSignal(
            asset_a=asset_a,
            asset_b=asset_b,
            spread=spread,
            z_score=z_score,
            direction=direction,
            expected_convergence=expected_convergence,
            confidence=confidence,
            asset_class_a=str(rel.get("class_a", "unknown")),
            asset_class_b=str(rel.get("class_b", "unknown")),
        )
