"""Bridge utilities for communicating quantitative results to Motoko backends."""

from __future__ import annotations

from dataclasses import asdict, is_dataclass, dataclass
from datetime import date, datetime
import json
from typing import Any, Generator
from urllib.error import HTTPError
from urllib.parse import urlencode, urljoin
from urllib.request import Request, urlopen

import numpy as np
import pandas as pd


@dataclass(slots=True)
class CanisterResponse:
    """Standard HTTP response wrapper used by the bridge client."""

    status_code: int
    data: Any
    headers: dict[str, str]
    raw_text: str


def _normalise(value: Any) -> Any:
    if is_dataclass(value):
        return _normalise(asdict(value))
    if isinstance(value, pd.DataFrame):
        return {"__type__": "DataFrame", "value": value.to_dict(orient="split")}
    if isinstance(value, pd.Series):
        return {"__type__": "Series", "name": value.name, "index": value.index.tolist(), "value": value.tolist()}
    if isinstance(value, np.ndarray):
        return {"__type__": "ndarray", "value": value.tolist()}
    if isinstance(value, (np.integer, np.floating)):
        return value.item()
    if isinstance(value, (datetime, date, pd.Timestamp)):
        return {"__type__": "datetime", "value": value.isoformat()}
    if isinstance(value, dict):
        return {str(key): _normalise(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_normalise(item) for item in value]
    return value


def _denormalise(value: Any) -> Any:
    if isinstance(value, dict) and "__type__" in value:
        if value["__type__"] == "DataFrame":
            return pd.DataFrame(**value["value"])
        if value["__type__"] == "Series":
            return pd.Series(value["value"], index=value["index"], name=value.get("name"))
        if value["__type__"] == "ndarray":
            return np.asarray(value["value"])
        if value["__type__"] == "datetime":
            return pd.Timestamp(value["value"])
    if isinstance(value, dict):
        return {key: _denormalise(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_denormalise(item) for item in value]
    return value


def serialize_payload(payload: Any, **json_kwargs: Any) -> str:
    """Serialize rich Python objects into JSON for canister submission."""
    kwargs = {"ensure_ascii": False}
    kwargs.update(json_kwargs)
    return json.dumps(_normalise(payload), **kwargs)


def deserialize_payload(payload: str | bytes) -> Any:
    """Deserialize JSON emitted by :func:`serialize_payload`."""
    text = payload.decode("utf-8") if isinstance(payload, bytes) else payload
    return _denormalise(json.loads(text))


class CanisterHTTPClient:
    """HTTP client for PARALLAX/Motoko canister integrations."""

    def __init__(
        self,
        base_url: str,
        api_key: str | None = None,
        timeout: float = 30.0,
        user_agent: str = "PARALLAX-Quant/0.2.0",
    ) -> None:
        self.base_url = base_url.rstrip("/") + "/"
        self.api_key = api_key
        self.timeout = float(timeout)
        self.user_agent = user_agent

    def _request(
        self,
        method: str,
        endpoint: str,
        payload: Any | None = None,
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
    ) -> CanisterResponse:
        """Perform an HTTP request and decode JSON responses when possible."""
        query = "" if not params else "?" + urlencode(params, doseq=True)
        url = urljoin(self.base_url, endpoint.lstrip("/")) + query
        request_headers = {"User-Agent": self.user_agent, "Accept": "application/json"}
        if payload is not None:
            request_headers["Content-Type"] = "application/json"
        if self.api_key:
            request_headers["Authorization"] = "Bearer " + self.api_key
        if headers:
            request_headers.update(headers)
        data = serialize_payload(payload).encode("utf-8") if payload is not None else None
        request = Request(url=url, data=data, headers=request_headers, method=method.upper())
        try:
            with urlopen(request, timeout=self.timeout) as response:
                raw = response.read().decode("utf-8")
                try:
                    decoded = deserialize_payload(raw)
                except json.JSONDecodeError:
                    decoded = raw
                return CanisterResponse(
                    status_code=int(response.status),
                    data=decoded,
                    headers=dict(response.headers.items()),
                    raw_text=raw,
                )
        except HTTPError as error:
            raw = error.read().decode("utf-8")
            try:
                decoded = deserialize_payload(raw)
            except json.JSONDecodeError:
                decoded = raw
            return CanisterResponse(
                status_code=int(error.code),
                data=decoded,
                headers=dict(error.headers.items()),
                raw_text=raw,
            )

    def call_canister(self, canister_id: str, method_name: str, payload: Any | None = None, update: bool = False) -> CanisterResponse:
        """Call a canister method via a JSON gateway."""
        mode = "update" if update else "query"
        endpoint = f"/api/v2/canister/{canister_id}/{mode}/{method_name}"
        return self._request("POST", endpoint, payload=payload)

    def query_canister(self, canister_id: str, method_name: str, payload: Any | None = None) -> CanisterResponse:
        """Convenience wrapper for read-only canister calls."""
        return self.call_canister(canister_id=canister_id, method_name=method_name, payload=payload, update=False)

    def update_canister(self, canister_id: str, method_name: str, payload: Any | None = None) -> CanisterResponse:
        """Convenience wrapper for state-mutating canister calls."""
        return self.call_canister(canister_id=canister_id, method_name=method_name, payload=payload, update=True)

    def stream(
        self,
        endpoint: str,
        payload: Any | None = None,
        params: dict[str, Any] | None = None,
    ) -> Generator[Any, None, None]:
        """Consume newline-delimited JSON or SSE-style event streams."""
        query = "" if not params else "?" + urlencode(params, doseq=True)
        url = urljoin(self.base_url, endpoint.lstrip("/")) + query
        request_headers = {
            "User-Agent": self.user_agent,
            "Accept": "text/event-stream, application/x-ndjson, application/json",
        }
        if self.api_key:
            request_headers["Authorization"] = "Bearer " + self.api_key
        data = serialize_payload(payload).encode("utf-8") if payload is not None else None
        request = Request(url=url, data=data, headers=request_headers, method="POST" if payload is not None else "GET")
        with urlopen(request, timeout=self.timeout) as response:
            for raw_line in response:
                line = raw_line.decode("utf-8").strip()
                if not line:
                    continue
                if line.startswith("data:"):
                    line = line[5:].strip()
                try:
                    yield deserialize_payload(line)
                except json.JSONDecodeError:
                    yield line

    def submit_model_result(
        self,
        model_name: str,
        result: Any,
        metadata: dict[str, Any] | None = None,
        endpoint: str = "/v1/quant/results",
    ) -> CanisterResponse:
        """Submit model output for persistence or downstream settlement logic."""
        payload = {
            "model_name": model_name,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "result": result,
            "metadata": metadata or {},
        }
        return self._request("POST", endpoint, payload=payload)
