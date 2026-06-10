"""Cross-Asset Arbitrage Strategy.

Exploits pricing inefficiencies across correlated assets, markets, and instruments.
"""

from __future__ import annotations

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

        current_ratio = price_a / price_b if price_b != 0 else 0

        if historical_ratios and len(historical_ratios) > 5:
            mean = sum(historical_ratios) / len(historical_ratios)
            std = (sum((r - mean) ** 2 for r in historical_ratios) / len(historical_ratios)) ** 0.5
            z_score = (current_ratio - mean) / std if std > 0 else 0
        else:
            theo = rel.get("ratio", 1.0)
            z_score = (current_ratio - theo) / (theo * 0.01) if theo > 0 else 0

        spread = current_ratio - (rel.get("ratio", 1.0) if rel else 1.0)

        if z_score > self.entry_threshold:
            direction = "short_a_long_b"
            confidence = min(1.0, z_score / self.max_divergence)
        elif z_score < -self.entry_threshold:
            direction = "long_a_short_b"
            confidence = min(1.0, abs(z_score) / self.max_divergence)
        else:
            direction = "flat"
            confidence = 0.0

        return CrossAssetSignal(
            asset_a=asset_a,
            asset_b=asset_b,
            spread=spread,
            z_score=z_score,
            direction=direction,
            expected_convergence=abs(z_score) * 0.1,
            confidence=confidence,
            asset_class_a=rel.get("class_a", "unknown"),
            asset_class_b=rel.get("class_b", "unknown"),
        )
