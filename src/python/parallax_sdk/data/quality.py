#!/usr/bin/env python3
"""PARALLAX SDK — data quality, anomaly detection, and lineage."""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Any, Optional

from ..provenance import ComputeReceipt, ProvenanceChain


@dataclass(slots=True)
class QualityMetric:
    name: str
    value: float
    threshold: float
    passed: bool


@dataclass(slots=True)
class ConsistencyIssue:
    severity: str
    message: str
    record_index: Optional[int] = None


@dataclass(slots=True)
class LineageEvent:
    dataset: str
    stage: str
    timestamp_ns: int
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class QualityReport:
    dataset: str
    generated_at_ns: int
    metrics: list[QualityMetric]
    issues: list[ConsistencyIssue]
    anomalies: list[ConsistencyIssue]
    lineage_receipt: Optional[ComputeReceipt] = None

    def passed(self) -> bool:
        return all(metric.passed for metric in self.metrics) and not any(
            issue.severity in {"high", "critical"} for issue in self.issues + self.anomalies
        )


class DataLineageTracker:
    """Tracks pipeline stages and seals them into a provenance chain."""

    def __init__(self, engine_id: str = "parallax-data-quality") -> None:
        self._events: list[LineageEvent] = []
        self._chain = ProvenanceChain(engine_id=engine_id)

    def record(self, dataset: str, stage: str, *, metadata: Optional[dict[str, Any]] = None) -> LineageEvent:
        event = LineageEvent(
            dataset=dataset,
            stage=stage,
            timestamp_ns=time.time_ns(),
            metadata=metadata or {},
        )
        self._events.append(event)
        return event

    def seal(self, dataset: str, *, metadata: Optional[dict[str, Any]] = None) -> ComputeReceipt:
        relevant = [
            {
                "dataset": event.dataset,
                "stage": event.stage,
                "timestamp_ns": event.timestamp_ns,
                "metadata": event.metadata,
            }
            for event in self._events
            if event.dataset == dataset
        ]
        return self._chain.seal(
            input_data={"dataset": dataset, "events": relevant},
            output_data={"lineage_length": len(relevant)},
            worker_id="quality-monitor",
            computation_type="data_lineage",
            metadata=metadata,
        )

    def export(self, dataset: Optional[str] = None) -> list[LineageEvent]:
        if dataset is None:
            return list(self._events)
        return [event for event in self._events if event.dataset == dataset]


class DataQualityMonitor:
    """Evaluates dataset quality metrics and common market-data anomalies."""

    def __init__(self, *, lineage_tracker: Optional[DataLineageTracker] = None) -> None:
        self.lineage_tracker = lineage_tracker or DataLineageTracker()

    def evaluate(
        self,
        dataset: str,
        records: list[dict[str, Any]],
        *,
        required_fields: list[str],
        freshness_sla_ns: int = 5_000_000_000,
        id_field: Optional[str] = None,
    ) -> QualityReport:
        now_ns = time.time_ns()
        self.lineage_tracker.record(dataset, "quality_evaluation_started", metadata={"records": len(records)})

        metrics = [
            self._completeness_metric(records, required_fields),
            self._timeliness_metric(records, now_ns, freshness_sla_ns),
            self._uniqueness_metric(records, id_field=id_field),
            self._consistency_metric(records),
        ]
        issues = self._consistency_checks(records)
        anomalies = self._detect_anomalies(records)
        receipt = self.lineage_tracker.seal(dataset, metadata={"metrics": [metric.name for metric in metrics]})
        self.lineage_tracker.record(dataset, "quality_evaluation_completed", metadata={"passed": not issues and not anomalies})
        return QualityReport(
            dataset=dataset,
            generated_at_ns=now_ns,
            metrics=metrics,
            issues=issues,
            anomalies=anomalies,
            lineage_receipt=receipt,
        )

    def _completeness_metric(self, records: list[dict[str, Any]], required_fields: list[str]) -> QualityMetric:
        if not records or not required_fields:
            return QualityMetric("completeness", 1.0, 0.99, True)
        expected = len(records) * len(required_fields)
        present = sum(1 for record in records for field_name in required_fields if record.get(field_name) is not None)
        score = present / expected if expected else 1.0
        return QualityMetric("completeness", score, 0.99, score >= 0.99)

    def _timeliness_metric(self, records: list[dict[str, Any]], now_ns: int, freshness_sla_ns: int) -> QualityMetric:
        if not records:
            return QualityMetric("timeliness", 1.0, 0.95, True)
        latest_ts = max(int(record.get("timestamp_ns", now_ns)) for record in records)
        lag = max(0, now_ns - latest_ts)
        score = 1.0 if lag <= freshness_sla_ns else freshness_sla_ns / lag
        return QualityMetric("timeliness", score, 0.95, score >= 0.95)

    def _uniqueness_metric(self, records: list[dict[str, Any]], *, id_field: Optional[str]) -> QualityMetric:
        if not records or not id_field:
            return QualityMetric("uniqueness", 1.0, 0.99, True)
        seen = [record.get(id_field) for record in records if record.get(id_field) is not None]
        score = len(set(seen)) / len(seen) if seen else 1.0
        return QualityMetric("uniqueness", score, 0.99, score >= 0.99)

    def _consistency_metric(self, records: list[dict[str, Any]]) -> QualityMetric:
        issues = self._consistency_checks(records)
        total = max(1, len(records))
        score = max(0.0, 1.0 - len(issues) / total)
        return QualityMetric("consistency", score, 0.98, score >= 0.98)

    def _consistency_checks(self, records: list[dict[str, Any]]) -> list[ConsistencyIssue]:
        issues: list[ConsistencyIssue] = []
        previous_timestamp: Optional[int] = None
        for index, record in enumerate(records):
            timestamp_ns = record.get("timestamp_ns")
            if timestamp_ns is not None:
                timestamp_value = int(timestamp_ns)
                if previous_timestamp is not None and timestamp_value < previous_timestamp:
                    issues.append(ConsistencyIssue("high", "timestamps are not monotonic", index))
                previous_timestamp = timestamp_value
            bid = record.get("bid")
            ask = record.get("ask")
            if bid is not None and ask is not None and float(ask) < float(bid):
                issues.append(ConsistencyIssue("critical", "negative spread detected", index))
            if record.get("price") is not None and float(record["price"]) <= 0:
                issues.append(ConsistencyIssue("critical", "non-positive price detected", index))
            if record.get("size") is not None and float(record["size"]) < 0:
                issues.append(ConsistencyIssue("high", "negative size detected", index))
        return issues

    def _detect_anomalies(self, records: list[dict[str, Any]]) -> list[ConsistencyIssue]:
        anomalies: list[ConsistencyIssue] = []
        previous_price: Optional[float] = None
        previous_timestamp: Optional[int] = None
        for index, record in enumerate(records):
            price = record.get("price") or record.get("last") or record.get("mid_price")
            timestamp_ns = record.get("timestamp_ns")
            if price is not None and previous_price not in (None, 0.0):
                move = abs(float(price) / previous_price - 1.0)
                if move > 0.2:
                    anomalies.append(ConsistencyIssue("high", f"price jump detected: {move:.2%}", index))
            if timestamp_ns is not None and previous_timestamp is not None:
                gap_ns = int(timestamp_ns) - previous_timestamp
                if gap_ns > 10_000_000_000:
                    anomalies.append(ConsistencyIssue("medium", f"timestamp gap detected: {gap_ns}ns", index))
            if price is not None:
                previous_price = float(price)
            if timestamp_ns is not None:
                previous_timestamp = int(timestamp_ns)
        return anomalies
