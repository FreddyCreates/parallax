from __future__ import annotations

from pathlib import Path
from typing import Any

import typer

from ..ai.models import AIRequest, TaskType
from ..utils.formatting import render_output


def optimize_command(
    ctx: typer.Context,
    component: Path = typer.Argument(..., exists=True, resolve_path=True),
    target: str = typer.Option("speed", "--target", help="Optimization target: speed, memory, or cost."),
    model: str | None = typer.Option(None, "--model", help="Explicit model override."),
    output: str = typer.Option("text", "--output", help="Output format: text, json, markdown, csv."),
) -> None:
    app = ctx.obj
    analysis = _analyze_component(component)
    request = AIRequest(
        task=TaskType.OPTIMIZE,
        prompt=f"Suggest production-ready {target} optimizations for {component.name}. Include refactors and impact estimates.",
        context={"component": str(component), "target": target, "analysis": analysis},
        model=model,
        profile=app.profile,
        stream=output != "json",
    )
    response = app.router.query(request)
    payload = {
        "component": str(component),
        "target": target,
        "analysis": analysis,
        "suggestions": response.suggestions or _fallback_suggestions(analysis, target),
        "narrative": response.text,
        "confidence": response.confidence,
        "provider": response.provider,
    }
    render_output(payload if output in {"json", "csv", "markdown"} else _text_output(payload), output, title="Optimization Report")


def _analyze_component(component: Path) -> dict[str, Any]:
    if component.is_file():
        files = [component]
    else:
        files = [path for path in component.rglob("*") if path.is_file()][:100]
    total_lines = 0
    total_bytes = 0
    largest_file = None
    largest_size = -1
    for path in files:
        try:
            content = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        total_lines += len(content.splitlines())
        size = path.stat().st_size
        total_bytes += size
        if size > largest_size:
            largest_size = size
            largest_file = path
    return {
        "files_scanned": len(files),
        "total_lines": total_lines,
        "total_bytes": total_bytes,
        "largest_file": str(largest_file) if largest_file else None,
        "average_lines_per_file": round(total_lines / len(files), 2) if files else 0,
    }


def _fallback_suggestions(analysis: dict[str, Any], target: str) -> list[dict[str, Any]]:
    suggestions: list[dict[str, Any]] = []
    if analysis.get("average_lines_per_file", 0) > 250:
        suggestions.append({
            "title": "Split oversized modules",
            "impact": "medium",
            "target": target,
            "reason": "Large files often hide mixed responsibilities and inhibit focused optimization.",
        })
    if target == "speed":
        suggestions.append({
            "title": "Cache repeated expensive computations",
            "impact": "high",
            "target": target,
            "reason": "Memoization or result caching can reduce recomputation cost in hot code paths.",
        })
    elif target == "memory":
        suggestions.append({
            "title": "Prefer streaming over eager materialization",
            "impact": "high",
            "target": target,
            "reason": "Generators, iterators, and chunked processing lower peak memory usage.",
        })
    else:
        suggestions.append({
            "title": "Reduce model and network round trips",
            "impact": "high",
            "target": target,
            "reason": "Batching and caching are usually the fastest path to lower AI execution cost.",
        })
    return suggestions


def _text_output(payload: dict[str, Any]) -> str:
    lines = [
        f"Component: {payload['component']}",
        f"Target: {payload['target']}",
        f"Confidence: {payload['confidence']}",
        f"Provider: {payload['provider']}",
        "",
        payload["narrative"],
        "",
        "Suggestions:",
    ]
    for suggestion in payload["suggestions"]:
        if isinstance(suggestion, dict):
            lines.append(f"- {suggestion.get('title', 'Suggestion')} ({suggestion.get('impact', 'n/a')}): {suggestion.get('reason', '')}")
        else:
            lines.append(f"- {suggestion}")
    return "
".join(lines)
