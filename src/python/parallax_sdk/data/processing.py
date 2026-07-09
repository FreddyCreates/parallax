#!/usr/bin/env python3
"""PARALLAX SDK — production data processing pipelines."""

from __future__ import annotations

import math
from dataclasses import dataclass
from enum import Enum
from statistics import fmean, median
from typing import Any, Callable, Optional


class NormalizationStrategy(Enum):
    MIN_MAX = "min_max"
    Z_SCORE = "z_score"
    ROBUST = "robust"


@dataclass(slots=True)
class ValidationResult:
    valid: bool
    errors: list[str]


class DataValidator:
    """Schema-lite validator for market-data records."""

    def __init__(self, *, required_fields: Optional[dict[str, type]] = None) -> None:
        self.required_fields = required_fields or {}

    def validate(self, record: dict[str, Any]) -> ValidationResult:
        errors: list[str] = []
        for field_name, expected_type in self.required_fields.items():
            if field_name not in record:
                errors.append(f"missing field: {field_name}")
                continue
            if record[field_name] is None:
                errors.append(f"null field: {field_name}")
                continue
            if not isinstance(record[field_name], expected_type):
                errors.append(f"invalid type for {field_name}: expected {expected_type.__name__}")
        return ValidationResult(valid=not errors, errors=errors)

    def filter_valid(self, records: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[ValidationResult]]:
        valid_records: list[dict[str, Any]] = []
        results: list[ValidationResult] = []
        for record in records:
            result = self.validate(record)
            results.append(result)
            if result.valid:
                valid_records.append(record)
        return valid_records, results


class MissingDataImputer:
    """Imputes sparse numeric market data."""

    def forward_fill(self, records: list[dict[str, Any]], fields: list[str]) -> list[dict[str, Any]]:
        last_seen: dict[str, Any] = {}
        output: list[dict[str, Any]] = []
        for record in records:
            filled = dict(record)
            for field_name in fields:
                value = filled.get(field_name)
                if value is None and field_name in last_seen:
                    filled[field_name] = last_seen[field_name]
                elif value is not None:
                    last_seen[field_name] = value
            output.append(filled)
        return output

    def mean_fill(self, records: list[dict[str, Any]], fields: list[str]) -> list[dict[str, Any]]:
        means = {
            field_name: fmean(
                float(record[field_name])
                for record in records
                if record.get(field_name) is not None
            )
            for field_name in fields
            if any(record.get(field_name) is not None for record in records)
        }
        output: list[dict[str, Any]] = []
        for record in records:
            filled = dict(record)
            for field_name, mean_value in means.items():
                if filled.get(field_name) is None:
                    filled[field_name] = mean_value
            output.append(filled)
        return output


class OutlierHandler:
    """Detects and mitigates numeric outliers."""

    def detect_zscore(self, values: list[float], *, threshold: float = 3.0) -> set[int]:
        if len(values) < 2:
            return set()
        mean_value = fmean(values)
        variance = sum((value - mean_value) ** 2 for value in values) / len(values)
        stddev = math.sqrt(variance)
        if stddev == 0:
            return set()
        return {
            index
            for index, value in enumerate(values)
            if abs((value - mean_value) / stddev) > threshold
        }

    def detect_mad(self, values: list[float], *, threshold: float = 3.5) -> set[int]:
        if len(values) < 2:
            return set()
        med = median(values)
        deviations = [abs(value - med) for value in values]
        mad = median(deviations)
        if mad == 0:
            return set()
        return {
            index
            for index, value in enumerate(values)
            if abs(0.6745 * (value - med) / mad) > threshold
        }

    def clip_records(
        self,
        records: list[dict[str, Any]],
        field_name: str,
        *,
        lower: float,
        upper: float,
    ) -> list[dict[str, Any]]:
        output: list[dict[str, Any]] = []
        for record in records:
            clipped = dict(record)
            value = clipped.get(field_name)
            if value is not None:
                clipped[field_name] = min(upper, max(lower, float(value)))
            output.append(clipped)
        return output


class DataNormalizer:
    """Fits per-field normalization parameters and transforms records."""

    def fit_transform(
        self,
        records: list[dict[str, Any]],
        fields: list[str],
        *,
        strategy: NormalizationStrategy,
    ) -> list[dict[str, Any]]:
        output = [dict(record) for record in records]
        for field_name in fields:
            values = [float(record[field_name]) for record in output if record.get(field_name) is not None]
            if not values:
                continue
            if strategy is NormalizationStrategy.MIN_MAX:
                lo, hi = min(values), max(values)
                scale = hi - lo or 1.0
                for record in output:
                    if record.get(field_name) is not None:
                        record[field_name] = (float(record[field_name]) - lo) / scale
            elif strategy is NormalizationStrategy.Z_SCORE:
                mean_value = fmean(values)
                variance = sum((value - mean_value) ** 2 for value in values) / len(values)
                stddev = math.sqrt(variance) or 1.0
                for record in output:
                    if record.get(field_name) is not None:
                        record[field_name] = (float(record[field_name]) - mean_value) / stddev
            else:
                med = median(values)
                mad = median([abs(value - med) for value in values]) or 1.0
                for record in output:
                    if record.get(field_name) is not None:
                        record[field_name] = (float(record[field_name]) - med) / mad
        return output


class FeatureEngineeringPipeline:
    """Composable feature engineering transformations."""

    def __init__(self) -> None:
        self._steps: list[Callable[[list[dict[str, Any]]], list[dict[str, Any]]]] = []

    def add_step(self, step: Callable[[list[dict[str, Any]]], list[dict[str, Any]]]) -> "FeatureEngineeringPipeline":
        self._steps.append(step)
        return self

    def add_mid_price(self, *, bid_field: str = "bid", ask_field: str = "ask") -> "FeatureEngineeringPipeline":
        def step(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
            output: list[dict[str, Any]] = []
            for record in records:
                enriched = dict(record)
                bid = enriched.get(bid_field)
                ask = enriched.get(ask_field)
                if bid is not None and ask is not None:
                    enriched["mid_price"] = (float(bid) + float(ask)) / 2.0
                    enriched["spread"] = float(ask) - float(bid)
                output.append(enriched)
            return output

        return self.add_step(step)

    def add_returns(self, *, price_field: str = "price", output_field: str = "return_1") -> "FeatureEngineeringPipeline":
        def step(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
            output: list[dict[str, Any]] = []
            previous_price: Optional[float] = None
            for record in records:
                enriched = dict(record)
                current_price = enriched.get(price_field)
                if current_price is not None and previous_price not in (None, 0.0):
                    enriched[output_field] = float(current_price) / previous_price - 1.0
                else:
                    enriched[output_field] = 0.0
                if current_price is not None:
                    previous_price = float(current_price)
                output.append(enriched)
            return output

        return self.add_step(step)

    def add_rolling_average(
        self,
        *,
        field_name: str,
        window: int,
        output_field: Optional[str] = None,
    ) -> "FeatureEngineeringPipeline":
        destination = output_field or f"{field_name}_ma_{window}"

        def step(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
            output: list[dict[str, Any]] = []
            buffer: list[float] = []
            for record in records:
                enriched = dict(record)
                if enriched.get(field_name) is not None:
                    buffer.append(float(enriched[field_name]))
                if len(buffer) > window:
                    buffer = buffer[-window:]
                enriched[destination] = fmean(buffer) if buffer else 0.0
                output.append(enriched)
            return output

        return self.add_step(step)

    def run(self, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        output = records
        for step in self._steps:
            output = step(output)
        return output


class DataProcessingPipeline:
    """End-to-end cleaning, imputation, normalization, and feature generation."""

    def __init__(
        self,
        *,
        validator: Optional[DataValidator] = None,
        imputer: Optional[MissingDataImputer] = None,
        outlier_handler: Optional[OutlierHandler] = None,
        normalizer: Optional[DataNormalizer] = None,
        feature_pipeline: Optional[FeatureEngineeringPipeline] = None,
    ) -> None:
        self.validator = validator or DataValidator()
        self.imputer = imputer or MissingDataImputer()
        self.outlier_handler = outlier_handler or OutlierHandler()
        self.normalizer = normalizer or DataNormalizer()
        self.feature_pipeline = feature_pipeline or FeatureEngineeringPipeline()

    def run(
        self,
        records: list[dict[str, Any]],
        *,
        impute_fields: Optional[list[str]] = None,
        normalize_fields: Optional[list[str]] = None,
        normalization_strategy: NormalizationStrategy = NormalizationStrategy.Z_SCORE,
    ) -> tuple[list[dict[str, Any]], list[ValidationResult]]:
        valid_records, validation_results = self.validator.filter_valid(records)
        if impute_fields:
            valid_records = self.imputer.forward_fill(valid_records, impute_fields)
        if normalize_fields:
            valid_records = self.normalizer.fit_transform(
                valid_records,
                normalize_fields,
                strategy=normalization_strategy,
            )
        valid_records = self.feature_pipeline.run(valid_records)
        return valid_records, validation_results
