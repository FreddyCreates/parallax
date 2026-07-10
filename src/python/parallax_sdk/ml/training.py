"""Training pipelines, online learning, and drift monitoring for PARALLAX."""

from __future__ import annotations

import math
import statistics
import time
from dataclasses import dataclass, field

from .models import LinearSignalModel, ModelFamily, ModelMetadata


@dataclass(slots=True)
class TrainingExample:
    features: dict[str, float]
    target: float
    sample_weight: float = 1.0


@dataclass(slots=True)
class TrainingConfig:
    learning_rate: float = 0.05
    epochs: int = 30
    l2_penalty: float = 1e-4
    classification: bool = True
    threshold: float = 0.5


@dataclass(slots=True)
class TrainingMetrics:
    loss: float
    mae: float
    rmse: float
    accuracy: float
    evaluated_at_ns: int = field(default_factory=time.time_ns)


@dataclass(slots=True)
class DriftReport:
    feature_shift: float
    target_shift: float
    accuracy_decay: float
    is_drifting: bool
    severity: str


def _sigmoid(value: float) -> float:
    if value >= 0:
        exp_value = math.exp(-value)
        return 1.0 / (1.0 + exp_value)
    exp_value = math.exp(value)
    return exp_value / (1.0 + exp_value)


def _feature_space(examples: list[TrainingExample]) -> list[str]:
    return sorted({name for example in examples for name in example.features})


def _prediction(weights: dict[str, float], bias: float, features: dict[str, float], classification: bool) -> float:
    score = bias + sum(weights.get(name, 0.0) * features.get(name, 0.0) for name in weights)
    return _sigmoid(score) if classification else score


def _evaluate(
    weights: dict[str, float],
    bias: float,
    examples: list[TrainingExample],
    config: TrainingConfig,
) -> TrainingMetrics:
    if not examples:
        return TrainingMetrics(loss=0.0, mae=0.0, rmse=0.0, accuracy=0.0)
    errors: list[float] = []
    absolute_errors: list[float] = []
    correct = 0
    for example in examples:
        estimate = _prediction(weights, bias, example.features, config.classification)
        error = estimate - example.target
        errors.append(error * error)
        absolute_errors.append(abs(error))
        if config.classification:
            predicted_label = 1.0 if estimate >= config.threshold else 0.0
            if predicted_label == example.target:
                correct += 1
    return TrainingMetrics(
        loss=statistics.fmean(errors),
        mae=statistics.fmean(absolute_errors),
        rmse=math.sqrt(statistics.fmean(errors)),
        accuracy=(correct / len(examples)) if config.classification else max(0.0, 1.0 - statistics.fmean(absolute_errors)),
    )


def train_model(
    model_id: str,
    family: ModelFamily,
    examples: list[TrainingExample],
    config: TrainingConfig | None = None,
    *,
    architecture: str = "linear_sgd",
    version: str = "1.0.0",
) -> tuple[LinearSignalModel, TrainingMetrics]:
    config = config or TrainingConfig()
    feature_names = _feature_space(examples)
    weights = {name: 0.0 for name in feature_names}
    bias = 0.0
    for _ in range(config.epochs):
        for example in examples:
            estimate = _prediction(weights, bias, example.features, config.classification)
            error = estimate - example.target
            for name in feature_names:
                gradient = error * example.features.get(name, 0.0) + config.l2_penalty * weights[name]
                weights[name] -= config.learning_rate * example.sample_weight * gradient
            bias -= config.learning_rate * error * example.sample_weight
    metrics = _evaluate(weights, bias, examples, config)
    label_positive, label_negative = (
        ("up", "down") if family == ModelFamily.PRICE_PREDICTION else
        ("high_volatility", "stable") if family == ModelFamily.VOLATILITY_FORECASTING else
        ("bullish", "bearish") if family == ModelFamily.SENTIMENT_ANALYSIS else
        ("anomaly", "normal") if family == ModelFamily.ANOMALY_DETECTION else
        ("opportunity", "no_opportunity")
    )
    model = LinearSignalModel(
        model_id=model_id,
        family=family,
        metadata=ModelMetadata(
            architecture=architecture,
            parameter_count=len(weights),
            accuracy=metrics.accuracy,
            version=version,
            tags=("trained", family.value),
        ),
        weights=weights,
        bias=bias,
        label_positive=label_positive,
        label_negative=label_negative,
    )
    return model, metrics


class OnlineLearningManager:
    def __init__(self, learning_rate: float = 0.01) -> None:
        self.learning_rate = learning_rate
        self.updates_applied = 0

    def incremental_update(self, model: LinearSignalModel, example: TrainingExample) -> None:
        prediction = model.predict(example.features)
        error = prediction.probability - example.target
        delta = {
            name: -error * value for name, value in example.features.items()
        }
        model.update_weights(delta, learning_rate=self.learning_rate * example.sample_weight)
        self.updates_applied += 1

    def monitor_performance(self, model: LinearSignalModel, examples: list[TrainingExample]) -> TrainingMetrics:
        config = TrainingConfig(classification=True)
        return _evaluate(model.weights, model.bias, examples, config)

    def detect_drift(
        self,
        baseline_features: list[dict[str, float]],
        recent_features: list[dict[str, float]],
        baseline_metrics: TrainingMetrics,
        recent_metrics: TrainingMetrics,
    ) -> DriftReport:
        feature_names = sorted({name for row in baseline_features + recent_features for name in row})
        feature_shift_components: list[float] = []
        for name in feature_names:
            baseline_mean = statistics.fmean([row.get(name, 0.0) for row in baseline_features]) if baseline_features else 0.0
            recent_mean = statistics.fmean([row.get(name, 0.0) for row in recent_features]) if recent_features else 0.0
            feature_shift_components.append(abs(recent_mean - baseline_mean))
        feature_shift = statistics.fmean(feature_shift_components) if feature_shift_components else 0.0
        target_shift = abs(recent_metrics.loss - baseline_metrics.loss)
        accuracy_decay = max(0.0, baseline_metrics.accuracy - recent_metrics.accuracy)
        magnitude = feature_shift + target_shift + accuracy_decay
        severity = "high" if magnitude >= 0.38 else "medium" if magnitude >= 0.236 else "low"
        return DriftReport(
            feature_shift=feature_shift,
            target_shift=target_shift,
            accuracy_decay=accuracy_decay,
            is_drifting=magnitude >= 0.236 or accuracy_decay >= 0.15,
            severity=severity,
        )

    def should_trigger_retraining(self, drift: DriftReport, recent_metrics: TrainingMetrics) -> bool:
        return drift.is_drifting and (drift.severity == "high" or recent_metrics.accuracy < 0.65)
