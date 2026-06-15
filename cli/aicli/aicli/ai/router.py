from __future__ import annotations

from dataclasses import asdict
from datetime import datetime, timezone
from hashlib import sha256
import json
import sqlite3
import time
from pathlib import Path
from typing import Any, Callable

import requests

from .compression import ThoughtCompressor
from .models import AIRequest, AIResponse, TaskType
from .reasoning import ReasoningEngine
from ..utils.logging import AuditLogger

ChunkCallback = Callable[[str], None]


class AIBackendError(RuntimeError):
    def __init__(self, message: str, suggestion: str | None = None) -> None:
        super().__init__(message)
        self.suggestion = suggestion


class ConversationStore:
    def __init__(self, sessions_dir: Path) -> None:
        self.sessions_dir = sessions_dir
        self.sessions_dir.mkdir(parents=True, exist_ok=True)

    def load(self, conversation_id: str) -> list[dict[str, Any]]:
        path = self.sessions_dir / f"{conversation_id}.json"
        if not path.exists():
            return []
        return json.loads(path.read_text(encoding="utf-8"))

    def append(self, conversation_id: str, role: str, content: str) -> None:
        messages = self.load(conversation_id)
        messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        (self.sessions_dir / f"{conversation_id}.json").write_text(
            json.dumps(messages, indent=2), encoding="utf-8"
        )

    def clear(self, conversation_id: str) -> None:
        path = self.sessions_dir / f"{conversation_id}.json"
        if path.exists():
            path.unlink()


class QueryCache:
    def __init__(self, database: Path, ttl_seconds: int = 900, enabled: bool = True) -> None:
        self.database = database
        self.ttl_seconds = ttl_seconds
        self.enabled = enabled
        self.database.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self) -> None:
        with sqlite3.connect(self.database) as conn:
            conn.execute(
                "CREATE TABLE IF NOT EXISTS cache (cache_key TEXT PRIMARY KEY, response_json TEXT NOT NULL, created_at REAL NOT NULL)"
            )

    def get(self, cache_key: str) -> AIResponse | None:
        if not self.enabled:
            return None
        cutoff = time.time() - self.ttl_seconds
        with sqlite3.connect(self.database) as conn:
            row = conn.execute(
                "SELECT response_json FROM cache WHERE cache_key = ? AND created_at >= ?",
                (cache_key, cutoff),
            ).fetchone()
        if not row:
            return None
        payload = json.loads(row[0])
        payload["cached"] = True
        return AIResponse(**payload)

    def set(self, cache_key: str, response: AIResponse) -> None:
        if not self.enabled:
            return
        payload = response.to_dict()
        with sqlite3.connect(self.database) as conn:
            conn.execute(
                "REPLACE INTO cache(cache_key, response_json, created_at) VALUES (?, ?, ?)",
                (cache_key, json.dumps(payload), time.time()),
            )
            conn.commit()


class ModelRouter:
    def __init__(self, config: dict[str, Any], *, paths: Any, audit_logger: AuditLogger) -> None:
        self.config = config
        self.paths = paths
        cache_cfg = config.get("cache", {})
        self.cache = QueryCache(
            paths.cache_file,
            ttl_seconds=int(cache_cfg.get("ttl_seconds", 900)),
            enabled=bool(cache_cfg.get("enabled", True)),
        )
        self.audit_logger = audit_logger
        self.reasoning_engine = ReasoningEngine()
        self.compressor = ThoughtCompressor()
        self.conversations = ConversationStore(paths.sessions_dir)

    def query(self, request: AIRequest, on_chunk: ChunkCallback | None = None) -> AIResponse:
        started = time.perf_counter()
        cache_key = self._cache_key(request)
        cached = self.cache.get(cache_key)
        if cached:
            if on_chunk:
                for chunk in self._chunk(cached.text):
                    on_chunk(chunk)
            return cached

        if request.conversation_id:
            self.conversations.append(request.conversation_id, "user", request.prompt)

        reasoning = self.reasoning_engine.build_steps(request.task, request.context)
        compressed = self.compressor.compress_context(request.context)
        fallback_used = False
        try:
            provider, model = self._route(request)
            if provider == "parallax":
                response = self._query_parallax(request, compressed.summary, reasoning, on_chunk)
            elif provider == "ollama":
                response = self._query_ollama(request, compressed.summary, reasoning, on_chunk)
            else:
                response = self._offline_response(request, compressed.summary, reasoning, on_chunk)
        except AIBackendError:
            if self.config.get("offline_mode"):
                response = self._offline_response(request, compressed.summary, reasoning, on_chunk)
                fallback_used = True
            else:
                fallback_used = True
                response = self._fallback_query(request, compressed.summary, reasoning, on_chunk)
        except requests.RequestException as exc:
            fallback_used = True
            response = self._fallback_query(request, compressed.summary, reasoning, on_chunk, error=str(exc))

        response.confidence = self.reasoning_engine.confidence(
            completeness=0.82 if response.text else 0.35,
            evidence=0.85 if request.context else 0.55,
            fallback_used=fallback_used or response.provider != "parallax",
        )
        response.reasoning = reasoning
        response.latency_ms = round((time.perf_counter() - started) * 1000, 2)

        if request.conversation_id:
            self.conversations.append(request.conversation_id, "assistant", response.text)

        self.cache.set(cache_key, response)
        self.audit_logger.log(
            "ai.query",
            {
                "request": request.to_cache_key(),
                "response": response.to_dict(),
            },
        )
        return response

    def query_batch(self, requests_: list[AIRequest]) -> list[AIResponse]:
        return [self.query(request) for request in requests_]

    def clear_conversation(self, conversation_id: str) -> None:
        self.conversations.clear(conversation_id)

    def _route(self, request: AIRequest) -> tuple[str, str]:
        model = request.model or self.config.get("profiles", {}).get(request.profile, {}).get("backend_model", "parallax-dev")
        if self.config.get("offline_mode"):
            return ("ollama" if self.config.get("ollama", {}).get("enabled", True) else "offline", model)
        if request.model and request.model.startswith("ollama/"):
            return ("ollama", request.model.split("/", 1)[1])
        if request.task in {TaskType.EXPLAIN, TaskType.OPTIMIZE, TaskType.TRACE, TaskType.QUERY}:
            return ("parallax", model)
        return ("parallax", model)

    def _build_prompt(self, request: AIRequest, compressed_context: str, reasoning: list[str]) -> str:
        context_block = compressed_context.strip() or "No additional context provided."
        return (
            f"Task: {request.task.value}
"
            f"Profile: {request.profile}
"
            f"Reasoning plan:
- " + "
- ".join(reasoning) + "

"
            f"Context summary:
{context_block}

"
            f"User prompt:
{request.prompt}
"
        )

    def _parallax_headers(self) -> dict[str, str]:
        auth = self.config.get("backend", {}).get("auth", {})
        headers = {"Content-Type": "application/json"}
        if auth.get("delegation_token"):
            headers["Authorization"] = f"******'delegation_token']}"
        if auth.get("principal"):
            headers["X-ICP-Principal"] = auth["principal"]
        return headers

    def _query_parallax(self, request: AIRequest, compressed_context: str, reasoning: list[str], on_chunk: ChunkCallback | None) -> AIResponse:
        endpoint = self.config.get("backend", {}).get("url")
        if not endpoint:
            raise AIBackendError("PARALLAX backend URL is not configured.", "Set backend.url in ~/.aicli/config.yaml.")
        payload = {
            "task": request.task.value,
            "prompt": self._build_prompt(request, compressed_context, reasoning),
            "context": request.context,
            "model": request.model,
            "temperature": request.temperature,
            "max_tokens": request.max_tokens,
            "stream": False,
            "metadata": request.metadata,
        }
        response = requests.post(
            endpoint,
            headers=self._parallax_headers(),
            json=payload,
            timeout=self.config.get("backend", {}).get("timeout_seconds", 30),
        )
        if response.status_code == 429:
            retry_after = response.headers.get("Retry-After", "unknown")
            raise AIBackendError(
                f"PARALLAX backend rate limited the request (retry after {retry_after}s).",
                "Retry later, lower concurrency, or switch to --offline / ollama fallback.",
            )
        response.raise_for_status()
        body = response.json()
        text = body.get("text") or body.get("message") or json.dumps(body, indent=2)
        if on_chunk:
            for chunk in self._chunk(text):
                on_chunk(chunk)
        return AIResponse(
            text=text,
            model=body.get("model") or request.model or "parallax",
            provider="parallax",
            confidence=float(body.get("confidence", 0.75)),
            structured=body.get("structured", {}),
            suggestions=body.get("suggestions", []),
            citations=body.get("citations", []),
        )

    def _query_ollama(self, request: AIRequest, compressed_context: str, reasoning: list[str], on_chunk: ChunkCallback | None) -> AIResponse:
        ollama_cfg = self.config.get("ollama", {})
        url = ollama_cfg.get("url", "http://127.0.0.1:11434").rstrip("/") + "/api/generate"
        model = request.model.split("/", 1)[1] if request.model and request.model.startswith("ollama/") else request.model or ollama_cfg.get("model", "llama3.1:8b")
        payload = {
            "model": model,
            "prompt": self._build_prompt(request, compressed_context, reasoning),
            "stream": bool(on_chunk),
            "options": {
                "temperature": request.temperature,
                "num_predict": request.max_tokens,
            },
        }
        if on_chunk:
            resp = requests.post(url, json=payload, timeout=self.config.get("backend", {}).get("stream_timeout_seconds", 300), stream=True)
            resp.raise_for_status()
            parts: list[str] = []
            for line in resp.iter_lines():
                if not line:
                    continue
                record = json.loads(line.decode("utf-8"))
                chunk = record.get("response", "")
                parts.append(chunk)
                if chunk:
                    on_chunk(chunk)
            text = "".join(parts)
        else:
            resp = requests.post(url, json=payload, timeout=self.config.get("backend", {}).get("timeout_seconds", 30))
            resp.raise_for_status()
            body = resp.json()
            text = body.get("response", "")
        return AIResponse(
            text=text or "No response from Ollama.",
            model=model,
            provider="ollama",
            confidence=0.62,
            structured={"fallback": "local"},
            suggestions=["Verify Ollama model quality before applying generated changes."],
        )

    def _offline_response(self, request: AIRequest, compressed_context: str, reasoning: list[str], on_chunk: ChunkCallback | None) -> AIResponse:
        text = (
            f"Offline {request.task.value} analysis

"
            f"Prompt: {request.prompt}

"
            f"Compressed context:
{compressed_context or 'No context provided.'}

"
            f"Recommended reasoning path:
- " + "
- ".join(reasoning)
        )
        if on_chunk:
            for chunk in self._chunk(text):
                on_chunk(chunk)
        return AIResponse(
            text=text,
            model="heuristic-offline",
            provider="offline",
            confidence=0.48,
            structured={"mode": "offline"},
            suggestions=["Reconnect to PARALLAX backend or start Ollama for richer answers."],
        )

    def _fallback_query(self, request: AIRequest, compressed_context: str, reasoning: list[str], on_chunk: ChunkCallback | None, error: str | None = None) -> AIResponse:
        if self.config.get("ollama", {}).get("enabled", True):
            try:
                return self._query_ollama(request, compressed_context, reasoning, on_chunk)
            except requests.RequestException:
                pass
        response = self._offline_response(request, compressed_context, reasoning, on_chunk)
        if error:
            response.suggestions.append(f"Original backend error: {error}")
        return response

    def _cache_key(self, request: AIRequest) -> str:
        payload = json.dumps(request.to_cache_key(), sort_keys=True, default=str)
        return sha256(payload.encode("utf-8")).hexdigest()

    @staticmethod
    def _chunk(text: str, size: int = 120) -> list[str]:
        return [text[i : i + size] for i in range(0, len(text), size)]
