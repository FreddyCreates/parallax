"""HTTP inference service and ensemble orchestration for PARALLAX."""

from __future__ import annotations

import json
import statistics
import time
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Iterable, Iterator

from .features import MarketSample, engineer_features
from .models import ModelPrediction, ModelRegistry, build_default_registry


@dataclass(slots=True)
class InferenceRequest:
    model_ids: list[str]
    sample: MarketSample | None = None
    features: dict[str, float] = field(default_factory=dict)
    version: str | None = None
    aggregation: str = "confidence_weighted"
    request_id: str = field(default_factory=lambda: f"req-{time.time_ns()}")


@dataclass(slots=True)
class AggregatePrediction:
    request_id: str
    label: str
    value: float
    confidence: float
    member_predictions: list[ModelPrediction]

    def to_dict(self) -> dict[str, object]:
        return {
            "request_id": self.request_id,
            "label": self.label,
            "value": self.value,
            "confidence": self.confidence,
            "member_predictions": [prediction.to_dict() for prediction in self.member_predictions],
        }


@dataclass(slots=True)
class StreamEvent:
    cursor: int
    created_at_ns: int
    aggregate: AggregatePrediction

    def to_sse(self) -> str:
        return f"id: {self.cursor}\nevent: inference\ndata: {json.dumps(self.aggregate.to_dict())}\n\n"


class InferenceService:
    def __init__(self, registry: ModelRegistry | None = None) -> None:
        self.registry = registry or build_default_registry()

    def predict(self, request: InferenceRequest) -> AggregatePrediction:
        features = dict(request.features) if request.features else engineer_features(request.sample).to_dict() if request.sample else {}
        predictions = [
            self.registry.predict(model_id, features, version=request.version if len(request.model_ids) == 1 else None)
            for model_id in request.model_ids
        ]
        return self.aggregate(request.request_id, predictions, request.aggregation)

    def predict_batch(self, requests: list[InferenceRequest]) -> list[AggregatePrediction]:
        return [self.predict(request) for request in requests]

    def stream_predictions(self, requests: Iterable[InferenceRequest], *, start_cursor: int = 0) -> Iterator[StreamEvent]:
        cursor = start_cursor
        for request in requests:
            cursor += 1
            yield StreamEvent(cursor=cursor, created_at_ns=time.time_ns(), aggregate=self.predict(request))

    def aggregate(self, request_id: str, predictions: list[ModelPrediction], strategy: str) -> AggregatePrediction:
        if not predictions:
            return AggregatePrediction(request_id=request_id, label="no_prediction", value=0.0, confidence=0.0, member_predictions=[])
        if strategy == "max_confidence":
            winner = max(predictions, key=lambda item: item.confidence)
            label = winner.label
            value = winner.value
        elif strategy == "majority_vote":
            labels = [prediction.label for prediction in predictions]
            label = max(set(labels), key=labels.count)
            value = 1.0 if label in {"up", "bullish", "high_volatility", "anomaly", "opportunity"} else -1.0
        elif strategy == "weighted_average":
            value = statistics.fmean(prediction.value for prediction in predictions)
            label = max(predictions, key=lambda item: item.confidence).label
        else:
            numerator = sum(prediction.value * prediction.confidence for prediction in predictions)
            denominator = sum(prediction.confidence for prediction in predictions) or 1.0
            value = numerator / denominator
            label = max(predictions, key=lambda item: item.confidence).label
        confidence = self.confidence_score(predictions)
        return AggregatePrediction(
            request_id=request_id,
            label=label,
            value=value,
            confidence=confidence,
            member_predictions=predictions,
        )

    @staticmethod
    def confidence_score(predictions: list[ModelPrediction]) -> float:
        if not predictions:
            return 0.0
        average_confidence = statistics.fmean(prediction.confidence for prediction in predictions)
        dispersion = statistics.pstdev([prediction.value for prediction in predictions]) if len(predictions) > 1 else 0.0
        return max(0.0, min(0.999, average_confidence * (1.0 / (1.0 + dispersion))))

    def make_handler(self):
        service = self

        class Handler(BaseHTTPRequestHandler):
            def _send(self, status: int, payload: dict[str, object]) -> None:
                body = json.dumps(payload).encode("utf-8")
                self.send_response(status)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_GET(self) -> None:
                if self.path == "/health":
                    self._send(200, {"status": "ok", "models": len(service.registry.list_models())})
                else:
                    self._send(404, {"error": "not_found"})

            def do_POST(self) -> None:
                length = int(self.headers.get("Content-Length", "0"))
                body = self.rfile.read(length) if length else b"{}"
                payload = json.loads(body.decode("utf-8"))
                if self.path == "/infer":
                    request = _request_from_payload(payload)
                    result = service.predict(request)
                    self._send(200, result.to_dict())
                elif self.path == "/batch":
                    requests = [_request_from_payload(item) for item in payload.get("requests", [])]
                    results = [result.to_dict() for result in service.predict_batch(requests)]
                    self._send(200, {"results": results})
                else:
                    self._send(404, {"error": "not_found"})

            def log_message(self, format: str, *args) -> None:
                return

        return Handler

    def serve(self, host: str = "127.0.0.1", port: int = 8080) -> ThreadingHTTPServer:
        server = ThreadingHTTPServer((host, port), self.make_handler())
        return server


def _normalize_features(values: dict[str, float]) -> dict[str, float]:
    aliases = {
        "realized_volatility": "volatility",
        "cross_asset_correlation": "peer_correlation",
        "lag1": "lag_1",
        "lag5": "lag_5",
        "lag20": "lag_20",
    }
    normalized: dict[str, float] = {}
    for key, value in values.items():
        normalized[aliases.get(key, key)] = float(value)
    return normalized



def _request_from_payload(payload: dict[str, object]) -> InferenceRequest:
    model_ids = list(payload.get("model_ids") or [payload["model_id"]])
    if "features" in payload:
        return InferenceRequest(
            model_ids=model_ids,
            features=_normalize_features(payload["features"]),
            version=str(payload["version"]) if payload.get("version") is not None else None,
            aggregation=payload.get("aggregation", "confidence_weighted"),
            request_id=payload.get("request_id", f"req-{time.time_ns()}"),
        )
    return InferenceRequest(
        model_ids=model_ids,
        sample=_sample_from_payload(payload["sample"]),
        version=str(payload["version"]) if payload.get("version") is not None else None,
        aggregation=payload.get("aggregation", "confidence_weighted"),
        request_id=payload.get("request_id", f"req-{time.time_ns()}"),
    )



def _sample_from_payload(payload: dict[str, object]) -> MarketSample:
    from .features import CrossAssetSnapshot, OrderBookLevel, OrderBookSnapshot, PricePoint

    price_history = [
        PricePoint(
            timestamp_ms=item["timestamp_ms"],
            close=item["close"],
            volume=item.get("volume", 0.0),
        )
        for item in payload.get("price_history", [])
    ]
    order_book = OrderBookSnapshot(
        bids=[OrderBookLevel(price=level["price"], size=level["size"]) for level in payload.get("order_book", {}).get("bids", [])],
        asks=[OrderBookLevel(price=level["price"], size=level["size"]) for level in payload.get("order_book", {}).get("asks", [])],
    )
    peers = [
        CrossAssetSnapshot(symbol=peer["symbol"], close_prices=list(peer.get("close_prices", [])))
        for peer in payload.get("peers", [])
    ]
    return MarketSample(
        symbol=payload["symbol"],
        price_history=price_history,
        order_book=order_book,
        peers=peers,
        headline_text=payload.get("headline_text", ""),
    )
