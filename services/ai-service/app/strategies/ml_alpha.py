"""Machine Learning Alpha Strategy.

AI-driven alpha generation using ensemble models and feature engineering.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class ModelType(str, Enum):
    GRADIENT_BOOST = "gradient_boost"
    NEURAL_NETWORK = "neural_network"
    TRANSFORMER = "transformer"
    RANDOM_FOREST = "random_forest"
    ENSEMBLE = "ensemble"


@dataclass
class AlphaSignal:
    symbol: str
    prediction: float  # Expected return
    confidence: float
    model_type: ModelType
    features_used: list[str]
    feature_importance: dict[str, float]
    ensemble_agreement: float


@dataclass
class Feature:
    name: str
    value: float
    importance: float = 0.0


class MLAlphaStrategy:
    """ML-based alpha generation with feature engineering."""

    def __init__(
        self,
        min_confidence: float = 0.6,
        ensemble_threshold: float = 0.7,
        max_features: int = 50,
    ) -> None:
        self.min_confidence = min_confidence
        self.ensemble_threshold = ensemble_threshold
        self.max_features = max_features
        self.feature_registry: dict[str, Feature] = {}

    def engineer_features(self, prices: list[float], volumes: list[float] | None = None) -> list[Feature]:
        """Generate trading features from raw data."""
        features = []
        n = len(prices)

        if n < 20:
            return features

        # Returns at multiple horizons
        for horizon in [1, 5, 10, 20]:
            if n > horizon:
                ret = (prices[-1] / prices[-1 - horizon]) - 1
                features.append(Feature(f"return_{horizon}d", ret))

        # Volatility features
        returns = [(prices[i] / prices[i - 1]) - 1 for i in range(1, n)]
        if returns:
            vol_5 = math.sqrt(sum(r**2 for r in returns[-5:]) / 5) if len(returns) >= 5 else 0
            vol_20 = math.sqrt(sum(r**2 for r in returns[-20:]) / 20) if len(returns) >= 20 else 0
            features.append(Feature("volatility_5d", vol_5))
            features.append(Feature("volatility_20d", vol_20))
            if vol_20 > 0:
                features.append(Feature("vol_ratio", vol_5 / vol_20))

        # Price momentum features
        if n >= 50:
            sma_10 = sum(prices[-10:]) / 10
            sma_50 = sum(prices[-50:]) / 50
            features.append(Feature("sma_ratio_10_50", sma_10 / sma_50 - 1))

        # Mean reversion feature
        if n >= 20:
            mean_20 = sum(prices[-20:]) / 20
            features.append(Feature("mean_deviation", (prices[-1] - mean_20) / mean_20))

        # Volume features
        if volumes and len(volumes) >= 20:
            avg_vol = sum(volumes[-20:]) / 20
            if avg_vol > 0:
                features.append(Feature("volume_ratio", volumes[-1] / avg_vol))
                recent_vol = sum(volumes[-5:]) / 5
                features.append(Feature("volume_trend", recent_vol / avg_vol - 1))

        # Skewness
        if len(returns) >= 20:
            mean_r = sum(returns[-20:]) / 20
            std_r = math.sqrt(sum((r - mean_r) ** 2 for r in returns[-20:]) / 20)
            if std_r > 0:
                skew = sum((r - mean_r) ** 3 for r in returns[-20:]) / (20 * std_r**3)
                features.append(Feature("skewness_20d", skew))

        return features

    def predict_alpha(
        self,
        symbol: str,
        features: list[Feature],
        model_predictions: dict[str, float] | None = None,
    ) -> AlphaSignal:
        """Generate alpha prediction from features."""
        if not features:
            return AlphaSignal(
                symbol=symbol, prediction=0.0, confidence=0.0,
                model_type=ModelType.ENSEMBLE, features_used=[],
                feature_importance={}, ensemble_agreement=0.0,
            )

        # Simulate ensemble predictions (in production, these come from trained models)
        if model_predictions is None:
            # Simple feature-weighted prediction as placeholder
            momentum_features = [f for f in features if "return" in f.name or "sma" in f.name]
            reversion_features = [f for f in features if "deviation" in f.name]

            momentum_signal = sum(f.value for f in momentum_features) / max(1, len(momentum_features))
            reversion_signal = -sum(f.value for f in reversion_features) / max(1, len(reversion_features))

            model_predictions = {
                "gradient_boost": momentum_signal * 0.6 + reversion_signal * 0.4,
                "neural_network": momentum_signal * 0.4 + reversion_signal * 0.6,
                "random_forest": (momentum_signal + reversion_signal) / 2,
            }

        # Ensemble agreement
        predictions = list(model_predictions.values())
        mean_pred = sum(predictions) / len(predictions)
        signs = [1 if p > 0 else -1 for p in predictions]
        agreement = abs(sum(signs)) / len(signs)

        # Feature importance (simplified)
        feature_importance = {f.name: abs(f.value) for f in features[:10]}
        total_imp = sum(feature_importance.values()) or 1
        feature_importance = {k: v / total_imp for k, v in feature_importance.items()}

        confidence = agreement * min(1.0, abs(mean_pred) * 50)

        return AlphaSignal(
            symbol=symbol,
            prediction=mean_pred,
            confidence=min(1.0, confidence),
            model_type=ModelType.ENSEMBLE,
            features_used=[f.name for f in features],
            feature_importance=feature_importance,
            ensemble_agreement=agreement,
        )
