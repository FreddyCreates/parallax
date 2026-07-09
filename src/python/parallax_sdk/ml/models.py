"""Pre-trained model definitions and registry primitives for PARALLAX."""

from __future__ import annotations

import math
import time
from dataclasses import dataclass, field
from enum import Enum


class ModelFamily(Enum):
    PRICE_PREDICTION = "price_prediction"
    VOLATILITY_FORECASTING = "volatility_forecasting"
    SENTIMENT_ANALYSIS = "sentiment_analysis"
    ANOMALY_DETECTION = "anomaly_detection"
    ARBITRAGE_DETECTION = "arbitrage_detection"


class ModelLifecycleStage(Enum):
    DRAFT = "draft"
    SHADOW = "shadow"
    ACTIVE = "active"
    DEGRADED = "degraded"
    RETIRED = "retired"
    ARCHIVED = "archived"


@dataclass(slots=True)
class ModelMetadata:
    architecture: str
    parameter_count: int
    accuracy: float
    version: str
    trained_at_ns: int = field(default_factory=time.time_ns)
    tags: tuple[str, ...] = ()


@dataclass(slots=True)
class ModelPrediction:
    model_id: str
    version: str
    label: str
    value: float
    probability: float
    confidence: float
    family: ModelFamily
    metadata: dict[str, float] = field(default_factory=dict)

    def to_dict(self) -> dict[str, object]:
        return {
            "model_id": self.model_id,
            "version": self.version,
            "label": self.label,
            "value": self.value,
            "probability": self.probability,
            "confidence": self.confidence,
            "family": self.family.value,
            "metadata": dict(self.metadata),
        }


def _sigmoid(value: float) -> float:
    if value >= 0:
        exp_value = math.exp(-value)
        return 1.0 / (1.0 + exp_value)
    exp_value = math.exp(value)
    return exp_value / (1.0 + exp_value)


def _bounded_confidence(logit: float, base_accuracy: float) -> float:
    margin = abs(_sigmoid(logit) - 0.5) * 2.0
    return max(0.0, min(0.999, 0.35 + 0.45 * margin + 0.20 * base_accuracy))


class LinearSignalModel:
    def __init__(
        self,
        model_id: str,
        family: ModelFamily,
        metadata: ModelMetadata,
        weights: dict[str, float],
        bias: float = 0.0,
        label_positive: str = "positive",
        label_negative: str = "negative",
    ) -> None:
        self.model_id = model_id
        self.family = family
        self.metadata = metadata
        self.weights = dict(weights)
        self.bias = bias
        self.label_positive = label_positive
        self.label_negative = label_negative
        self.stage = ModelLifecycleStage.ACTIVE

    @property
    def version(self) -> str:
        return self.metadata.version

    def score(self, features: dict[str, float]) -> float:
        return self.bias + sum(features.get(name, 0.0) * weight for name, weight in self.weights.items())

    def predict(self, features: dict[str, float]) -> ModelPrediction:
        logit = self.score(features)
        probability = _sigmoid(logit)
        label = self.label_positive if probability >= 0.5 else self.label_negative
        value = logit if self.family != ModelFamily.ANOMALY_DETECTION else abs(logit)
        return ModelPrediction(
            model_id=self.model_id,
            version=self.version,
            label=label,
            value=value,
            probability=probability,
            confidence=_bounded_confidence(logit, self.metadata.accuracy),
            family=self.family,
            metadata={"logit": logit},
        )

    def update_weights(self, delta: dict[str, float], learning_rate: float = 1.0) -> None:
        for name, value in delta.items():
            self.weights[name] = self.weights.get(name, 0.0) + learning_rate * value


class AnomalyModel(LinearSignalModel):
    def predict(self, features: dict[str, float]) -> ModelPrediction:
        baseline = {
            "zscore": abs(features.get("zscore", 0.0)),
            "volatility": abs(features.get("volatility", 0.0)),
            "imbalance": abs(features.get("imbalance", 0.0)),
            "spread": abs(features.get("spread", 0.0)),
        }
        logit = self.score(baseline)
        probability = _sigmoid(logit)
        return ModelPrediction(
            model_id=self.model_id,
            version=self.version,
            label="anomaly" if probability >= 0.5 else "normal",
            value=logit,
            probability=probability,
            confidence=_bounded_confidence(logit, self.metadata.accuracy),
            family=self.family,
            metadata={"anomaly_score": logit},
        )


class ModelRegistry:
    def __init__(self) -> None:
        self._models: dict[str, list[LinearSignalModel]] = {}
        self._events: list[dict[str, object]] = []

    def register(self, model: LinearSignalModel) -> None:
        self._models.setdefault(model.model_id, []).append(model)
        self._events.append({
            "event": "registered",
            "model_id": model.model_id,
            "version": model.version,
            "timestamp_ns": time.time_ns(),
        })

    def list_models(self, family: ModelFamily | None = None) -> list[LinearSignalModel]:
        models = [item for versions in self._models.values() for item in versions]
        if family is None:
            return models
        return [model for model in models if model.family == family]

    def latest(self, model_id: str) -> LinearSignalModel:
        versions = self._models[model_id]
        return sorted(versions, key=lambda model: model.version)[-1]

    def transition(self, model_id: str, version: str, stage: ModelLifecycleStage) -> None:
        for model in self._models.get(model_id, []):
            if model.version == version:
                model.stage = stage
        self._events.append({
            "event": "transitioned",
            "model_id": model_id,
            "version": version,
            "stage": stage.value,
            "timestamp_ns": time.time_ns(),
        })

    def activate(self, model_id: str, version: str) -> None:
        for model in self._models.get(model_id, []):
            model.stage = ModelLifecycleStage.ACTIVE if model.version == version else ModelLifecycleStage.SHADOW
        self._events.append({
            "event": "activated",
            "model_id": model_id,
            "version": version,
            "timestamp_ns": time.time_ns(),
        })

    def lifecycle_events(self) -> list[dict[str, object]]:
        return list(self._events)

    def predict(self, model_id: str, features: dict[str, float], version: str | None = None) -> ModelPrediction:
        model = self.latest(model_id) if version is None else next(
            candidate for candidate in self._models[model_id] if candidate.version == version
        )
        return model.predict(features)


def build_default_registry() -> ModelRegistry:
    registry = ModelRegistry()
    registry.register(LinearSignalModel(
        model_id="price-transformer-v1",
        family=ModelFamily.PRICE_PREDICTION,
        metadata=ModelMetadata("temporal_transformer", 1_250_000, 0.82, "1.0.0", tags=("price", "returns", "momentum")),
        weights={"returns": 0.85, "momentum": 0.65, "peer_correlation": 0.30, "sentiment_score": 0.20},
        bias=0.05,
        label_positive="up",
        label_negative="down",
    ))
    registry.register(LinearSignalModel(
        model_id="vol-garch-lite-v1",
        family=ModelFamily.VOLATILITY_FORECASTING,
        metadata=ModelMetadata("garch_hybrid", 320_000, 0.79, "1.0.0", tags=("volatility", "risk")),
        weights={"volatility": 1.20, "rolling_std": 0.90, "spread": 0.35, "imbalance": 0.15},
        bias=-0.15,
        label_positive="high_volatility",
        label_negative="stable",
    ))
    registry.register(LinearSignalModel(
        model_id="sentiment-lexicon-v1",
        family=ModelFamily.SENTIMENT_ANALYSIS,
        metadata=ModelMetadata("lexicon_linear", 48_000, 0.76, "1.0.0", tags=("sentiment", "headline")),
        weights={"sentiment_score": 2.8, "headline_intensity": 0.8, "returns": 0.15},
        bias=0.0,
        label_positive="bullish",
        label_negative="bearish",
    ))
    registry.register(AnomalyModel(
        model_id="anomaly-sentinel-v1",
        family=ModelFamily.ANOMALY_DETECTION,
        metadata=ModelMetadata("robust_zscore", 96_000, 0.84, "1.0.0", tags=("anomaly", "microstructure")),
        weights={"zscore": 1.5, "volatility": 0.9, "imbalance": 0.7, "spread": 0.6},
        bias=-0.4,
        label_positive="anomaly",
        label_negative="normal",
    ))
    registry.register(LinearSignalModel(
        model_id="arb-spread-hunter-v1",
        family=ModelFamily.ARBITRAGE_DETECTION,
        metadata=ModelMetadata("cross_asset_linear", 180_000, 0.81, "1.0.0", tags=("arbitrage", "cross_asset")),
        weights={"price_ratio": 1.25, "relative_strength": 0.90, "spread": -0.20, "peer_correlation": -0.35},
        bias=-0.05,
        label_positive="opportunity",
        label_negative="no_opportunity",
    ))
    return registry
