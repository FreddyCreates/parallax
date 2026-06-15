from __future__ import annotations

from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Any


class TaskType(str, Enum):
    EXPLAIN = "explain"
    OPTIMIZE = "optimize"
    GENERATE = "generate"
    DIAGNOSE = "diagnose"
    QUERY = "query"
    TRACE = "trace"


@dataclass
class AIRequest:
    task: TaskType
    prompt: str
    context: dict[str, Any] = field(default_factory=dict)
    model: str | None = None
    temperature: float = 0.2
    max_tokens: int = 1200
    stream: bool = False
    conversation_id: str | None = None
    profile: str = "dev"
    metadata: dict[str, Any] = field(default_factory=dict)

    def to_cache_key(self) -> dict[str, Any]:
        payload = asdict(self)
        payload["task"] = self.task.value
        payload["metadata"] = {k: v for k, v in self.metadata.items() if k not in {"timestamp"}}
        return payload


@dataclass
class AIResponse:
    text: str
    model: str
    provider: str
    confidence: float
    reasoning: list[str] = field(default_factory=list)
    structured: dict[str, Any] = field(default_factory=dict)
    suggestions: list[str] = field(default_factory=list)
    citations: list[str] = field(default_factory=list)
    cached: bool = False
    latency_ms: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "text": self.text,
            "model": self.model,
            "provider": self.provider,
            "confidence": self.confidence,
            "reasoning": self.reasoning,
            "structured": self.structured,
            "suggestions": self.suggestions,
            "citations": self.citations,
            "cached": self.cached,
            "latency_ms": self.latency_ms,
        }


@dataclass
class DiagnosticIssue:
    severity: str
    code: str
    message: str
    suggestion: str
    details: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
