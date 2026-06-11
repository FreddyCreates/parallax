"""Machine Learning Alpha Strategy.

AI-driven alpha generation using ensemble models and feature engineering.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
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
        self.last_state: dict[str, Any] = {}

    def _mean(self, values: list[float]) -> float:
        return sum(values) / len(values) if values else 0.0

    def _std(self, values: list[float]) -> float:
        if len(values) < 2:
            return 0.0
        mean = self._mean(values)
        variance = sum((value - mean) ** 2 for value in values) / (len(values) - 1)
        return math.sqrt(max(variance, 0.0))

    def detect_regime(self, prices: list[float]) -> str:
        """Detect trend and volatility regime used to weight ensemble models."""
        if len(prices) < 30:
            return "neutral"
        returns = [math.log(prices[index] / prices[index - 1]) for index in range(1, len(prices)) if prices[index - 1] > 0]
        volatility = self._std(returns[-20:]) * math.sqrt(252) if returns else 0.0
        trend = prices[-1] / self._mean(prices[-20:]) - 1 if self._mean(prices[-20:]) else 0.0
        if volatility > 0.5:
            return "high_vol"
        if trend > 0.03:
            return "uptrend"
        if trend < -0.03:
            return "downtrend"
        return "range"

    def engineer_features(self, prices: list[float], volumes: list[float] | None = None) -> list[Feature]:
        """Generate trading features from raw data."""
        features: list[Feature] = []
        n = len(prices)
        if n < 20:
            return features

        returns = [(prices[index] / prices[index - 1]) - 1 for index in range(1, n) if prices[index - 1] > 0]
        for horizon in [1, 5, 10, 20]:
            if n > horizon and prices[-1 - horizon] > 0:
                features.append(Feature(f"return_{horizon}d", prices[-1] / prices[-1 - horizon] - 1))

        vol_5 = self._std(returns[-5:]) * math.sqrt(252) if len(returns) >= 5 else 0.0
        vol_20 = self._std(returns[-20:]) * math.sqrt(252) if len(returns) >= 20 else 0.0
        features.extend([Feature("volatility_5d", vol_5), Feature("volatility_20d", vol_20)])
        if vol_20 > 0:
            features.append(Feature("vol_ratio", vol_5 / vol_20))

        sma_10 = self._mean(prices[-10:])
        sma_20 = self._mean(prices[-20:])
        features.append(Feature("sma_ratio_10_20", sma_10 / sma_20 - 1 if sma_20 else 0.0))
        features.append(Feature("mean_deviation", (prices[-1] - sma_20) / sma_20 if sma_20 else 0.0))

        if len(returns) >= 20:
            mean_r = self._mean(returns[-20:])
            std_r = self._std(returns[-20:])
            downside = math.sqrt(sum(min(ret, 0.0) ** 2 for ret in returns[-20:]) / 20)
            features.append(Feature("return_mean_20d", mean_r))
            features.append(Feature("downside_vol_20d", downside * math.sqrt(252)))
            if std_r > 0:
                skew = sum((ret - mean_r) ** 3 for ret in returns[-20:]) / (20 * std_r**3)
                features.append(Feature("skewness_20d", skew))

        regime = self.detect_regime(prices)
        regime_map = {"uptrend": 1.0, "downtrend": -1.0, "high_vol": -0.5, "range": 0.25, "neutral": 0.0}
        features.append(Feature("regime_score", regime_map.get(regime, 0.0)))

        if volumes and len(volumes) >= 20:
            avg_vol = self._mean(volumes[-20:])
            recent_vol = self._mean(volumes[-5:])
            if avg_vol > 0:
                features.append(Feature("volume_ratio", volumes[-1] / avg_vol))
                features.append(Feature("volume_trend", recent_vol / avg_vol - 1))

        ranked = sorted(features, key=lambda feature: abs(feature.value), reverse=True)[: self.max_features]
        self.feature_registry = {feature.name: feature for feature in ranked}
        return ranked

    def model_scores(self, features: list[Feature], regime: str) -> dict[str, float]:
        """Create deterministic model outputs that mimic an ensemble stack."""
        feature_map = {feature.name: feature.value for feature in features}
        momentum = feature_map.get("return_5d", 0.0) + feature_map.get("sma_ratio_10_20", 0.0)
        mean_reversion = -feature_map.get("mean_deviation", 0.0)
        risk_filter = 1.0 / (1.0 + abs(feature_map.get("volatility_20d", 0.0)))
        regime_bias = feature_map.get("regime_score", 0.0)
        if regime == "high_vol":
            momentum *= 0.6
            mean_reversion *= 1.2
        return {
            "gradient_boost": (0.55 * momentum + 0.25 * regime_bias + 0.20 * mean_reversion) * risk_filter,
            "neural_network": (0.35 * momentum + 0.45 * mean_reversion + 0.20 * regime_bias) * risk_filter,
            "random_forest": (0.40 * momentum + 0.30 * mean_reversion + 0.30 * regime_bias) * risk_filter,
            "transformer": (0.50 * momentum + 0.20 * mean_reversion + 0.30 * regime_bias) * risk_filter,
        }

    def feature_importance(self, features: list[Feature]) -> dict[str, float]:
        """Normalize absolute feature magnitudes into an importance distribution."""
        raw = {feature.name: abs(feature.value) for feature in features[:10]}
        total = sum(raw.values()) or 1.0
        return {name: value / total for name, value in raw.items()}

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return forecast and feature-concentration risk metrics."""
        prediction = abs(float(self.last_state.get("prediction", 0.0)))
        dispersion = float(self.last_state.get("dispersion", 0.0))
        max_loss = prediction * (1.0 + dispersion * 5.0)
        expected_drawdown = max_loss * 0.5
        return {
            "prediction": prediction,
            "dispersion": dispersion,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return alpha-engine health and latest regime state."""
        return {
            "healthy": not self.last_state or float(self.last_state.get("agreement", 0.0)) >= 0.25,
            "feature_count": len(self.feature_registry),
            "last_state": self.last_state,
        }

    def predict_alpha(
        self,
        symbol: str,
        features: list[Feature],
        model_predictions: dict[str, float] | None = None,
    ) -> AlphaSignal:
        """Generate alpha prediction from features."""
        if not features:
            return AlphaSignal(symbol, 0.0, 0.0, ModelType.ENSEMBLE, [], {}, 0.0)

        regime = "neutral"
        regime_feature = next((feature for feature in features if feature.name == "regime_score"), None)
        if regime_feature is not None:
            if regime_feature.value > 0.8:
                regime = "uptrend"
            elif regime_feature.value < -0.8:
                regime = "downtrend"
            elif regime_feature.value < 0:
                regime = "high_vol"
            else:
                regime = "range"

        if model_predictions is None:
            model_predictions = self.model_scores(features, regime)

        predictions = list(model_predictions.values())
        mean_pred = self._mean(predictions)
        dispersion = self._std(predictions)
        agreement = 1.0 - min(1.0, dispersion / max(abs(mean_pred), 0.01))
        confidence = max(0.0, min(1.0, agreement * min(1.0, abs(mean_pred) * 40)))
        if confidence < self.min_confidence * 0.5:
            mean_pred *= 0.5

        importance = self.feature_importance(features)
        self.last_state = {
            "symbol": symbol,
            "prediction": mean_pred,
            "agreement": agreement,
            "dispersion": dispersion,
            "regime": regime,
        }
        return AlphaSignal(
            symbol=symbol,
            prediction=mean_pred,
            confidence=confidence,
            model_type=ModelType.ENSEMBLE,
            features_used=[feature.name for feature in features],
            feature_importance=importance,
            ensemble_agreement=agreement,
        )
