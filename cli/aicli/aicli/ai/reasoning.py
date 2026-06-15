from __future__ import annotations

from typing import Any

from .models import TaskType


class ReasoningEngine:
    def build_steps(self, task: TaskType, context: dict[str, Any]) -> list[str]:
        if task is TaskType.EXPLAIN:
            return [
                "Inspect file structure and imports.",
                "Trace primary logic flow and identify hotspots.",
                "Summarize behavior, risks, and documentation opportunities.",
            ]
        if task is TaskType.OPTIMIZE:
            return [
                "Profile target characteristics from supplied metadata.",
                "Map likely performance, memory, or cost bottlenecks.",
                "Rank refactors by impact and implementation effort.",
            ]
        if task is TaskType.DIAGNOSE:
            return [
                "Check environment, configuration, and dependency health.",
                "Correlate failures with likely causes.",
                "Recommend the safest fixes first.",
            ]
        if task is TaskType.TRACE:
            return [
                "Collect transaction context and execution edges.",
                "Highlight bottlenecks and deep call chains.",
                "Present an actionable trace summary.",
            ]
        return [
            "Compress context while preserving actionable detail.",
            "Route the request to the best available model.",
            "Return structured output with confidence metadata.",
        ]

    def confidence(self, *, completeness: float, evidence: float, fallback_used: bool = False) -> float:
        score = (completeness * 0.55) + (evidence * 0.45)
        if fallback_used:
            score -= 0.15
        return round(max(0.05, min(score, 0.99)), 2)
