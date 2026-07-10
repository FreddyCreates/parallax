#!/usr/bin/env python3
"""PARALLAX SDK — production-grade data storage primitives."""

from __future__ import annotations

import base64
import gzip
import hashlib
import json
import time
from bisect import bisect_left, bisect_right
from dataclasses import dataclass, field
from typing import Any, Optional


@dataclass(slots=True)
class TimeSeriesPoint:
    """Single immutable time-series point."""

    timestamp_ns: int
    fields: dict[str, float]
    tags: dict[str, str] = field(default_factory=dict)
    version: int = 1


@dataclass(slots=True)
class RetentionPolicy:
    """Controls lifecycle of dataset partitions."""

    max_age_ns: Optional[int] = None
    max_records: Optional[int] = None


@dataclass(slots=True)
class StorageSnapshot:
    """Compressed point-in-time dataset snapshot."""

    snapshot_id: str
    dataset: str
    created_at_ns: int
    record_count: int
    checksum: str
    payload_b64: str


class DataCompressor:
    """Deterministic JSON + gzip compression helpers."""

    @staticmethod
    def compress(payload: Any) -> str:
        raw = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
        return base64.b64encode(gzip.compress(raw, compresslevel=9)).decode("ascii")

    @staticmethod
    def decompress(payload_b64: str) -> Any:
        raw = gzip.decompress(base64.b64decode(payload_b64.encode("ascii")))
        return json.loads(raw.decode("utf-8"))


class VersionedDatasetStore:
    """Maintains versioned blobs for datasets and metadata."""

    def __init__(self) -> None:
        self._store: dict[str, list[dict[str, Any]]] = {}

    def put_version(self, dataset: str, payload: Any, *, metadata: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        versions = self._store.setdefault(dataset, [])
        version = len(versions) + 1
        serialized = json.dumps(payload, sort_keys=True, default=str)
        checksum = hashlib.sha256(serialized.encode("utf-8")).hexdigest()
        record = {
            "version": version,
            "created_at_ns": time.time_ns(),
            "checksum": checksum,
            "metadata": metadata or {},
            "payload": payload,
        }
        versions.append(record)
        return record

    def latest_version(self, dataset: str) -> Optional[dict[str, Any]]:
        versions = self._store.get(dataset, [])
        return versions[-1] if versions else None

    def get_version(self, dataset: str, version: int) -> Optional[dict[str, Any]]:
        versions = self._store.get(dataset, [])
        if 1 <= version <= len(versions):
            return versions[version - 1]
        return None

    def list_versions(self, dataset: str) -> list[dict[str, Any]]:
        return list(self._store.get(dataset, []))


class TimeSeriesDatabase:
    """In-memory time-series storage with snapshots and retention controls."""

    def __init__(self) -> None:
        self._datasets: dict[str, list[TimeSeriesPoint]] = {}
        self._snapshots: dict[str, list[StorageSnapshot]] = {}
        self._retention: dict[str, RetentionPolicy] = {}
        self._versions = VersionedDatasetStore()

    @property
    def versions(self) -> VersionedDatasetStore:
        return self._versions

    def configure_retention(self, dataset: str, policy: RetentionPolicy) -> None:
        self._retention[dataset] = policy

    def write_points(self, dataset: str, points: list[TimeSeriesPoint]) -> int:
        if not points:
            return 0
        ordered = sorted(points, key=lambda point: point.timestamp_ns)
        series = self._datasets.setdefault(dataset, [])
        for point in ordered:
            insert_at = bisect_right([existing.timestamp_ns for existing in series], point.timestamp_ns)
            series.insert(insert_at, point)
        self._versions.put_version(
            dataset,
            [self._serialize_point(point) for point in ordered],
            metadata={"operation": "write_points", "count": len(ordered)},
        )
        self.apply_retention(dataset)
        return len(ordered)

    def query_range(self, dataset: str, *, start_ns: Optional[int] = None, end_ns: Optional[int] = None) -> list[TimeSeriesPoint]:
        series = self._datasets.get(dataset, [])
        timestamps = [point.timestamp_ns for point in series]
        left = 0 if start_ns is None else bisect_left(timestamps, start_ns)
        right = len(series) if end_ns is None else bisect_right(timestamps, end_ns)
        return series[left:right]

    def snapshot_dataset(self, dataset: str) -> StorageSnapshot:
        series = self._datasets.get(dataset, [])
        payload = [self._serialize_point(point) for point in series]
        compressed = DataCompressor.compress(payload)
        checksum = hashlib.sha256(compressed.encode("utf-8")).hexdigest()
        snapshot = StorageSnapshot(
            snapshot_id=f"SNAP-{dataset}-{time.time_ns()}",
            dataset=dataset,
            created_at_ns=time.time_ns(),
            record_count=len(series),
            checksum=checksum,
            payload_b64=compressed,
        )
        self._snapshots.setdefault(dataset, []).append(snapshot)
        return snapshot

    def restore_snapshot(self, snapshot: StorageSnapshot) -> int:
        decoded = DataCompressor.decompress(snapshot.payload_b64)
        restored = [self._deserialize_point(point) for point in decoded]
        self._datasets[snapshot.dataset] = restored
        self._versions.put_version(
            snapshot.dataset,
            decoded,
            metadata={"operation": "restore_snapshot", "snapshot_id": snapshot.snapshot_id},
        )
        return len(restored)

    def list_snapshots(self, dataset: str) -> list[StorageSnapshot]:
        return list(self._snapshots.get(dataset, []))

    def apply_retention(self, dataset: str, *, now_ns: Optional[int] = None) -> int:
        policy = self._retention.get(dataset)
        series = self._datasets.get(dataset, [])
        if not policy or not series:
            return 0

        now_value = now_ns or time.time_ns()
        trimmed = series
        if policy.max_age_ns is not None:
            min_allowed = now_value - policy.max_age_ns
            trimmed = [point for point in trimmed if point.timestamp_ns >= min_allowed]
        if policy.max_records is not None and len(trimmed) > policy.max_records:
            trimmed = trimmed[-policy.max_records :]
        removed = len(series) - len(trimmed)
        self._datasets[dataset] = trimmed
        return removed

    def _serialize_point(self, point: TimeSeriesPoint) -> dict[str, Any]:
        return {
            "timestamp_ns": point.timestamp_ns,
            "fields": point.fields,
            "tags": point.tags,
            "version": point.version,
        }

    def _deserialize_point(self, payload: dict[str, Any]) -> TimeSeriesPoint:
        return TimeSeriesPoint(
            timestamp_ns=int(payload["timestamp_ns"]),
            fields={key: float(value) for key, value in payload["fields"].items()},
            tags={key: str(value) for key, value in payload.get("tags", {}).items()},
            version=int(payload.get("version", 1)),
        )
