from __future__ import annotations

import os
from pathlib import Path
import platform
import shutil
from typing import Any

import requests
import typer

from ..ai.models import AIRequest, DiagnosticIssue, TaskType
from ..utils.formatting import render_output


def diagnose_command(
    ctx: typer.Context,
    deep: bool = typer.Option(False, "--deep", help="Run deeper diagnostics."),
    output: str = typer.Option("text", "--output", help="Output format: text, json, html."),
) -> None:
    app = ctx.obj
    report = _run_checks(app.config, app.paths.config_file, deep=deep)
    request = AIRequest(
        task=TaskType.DIAGNOSE,
        prompt="Summarize the current system diagnostic state and propose prioritized fixes.",
        context=report,
        profile=app.profile,
    )
    response = app.router.query(request)
    payload = {
        **report,
        "ai_summary": response.text,
        "confidence": response.confidence,
        "suggestions": response.suggestions,
    }
    if output == "text":
        render_output(_text_report(payload), output, title="Diagnostics")
    else:
        render_output(payload, output, title="Diagnostics")


def _run_checks(config: dict[str, Any], config_file: Path, *, deep: bool) -> dict[str, Any]:
    issues: list[DiagnosticIssue] = []
    backend_url = config.get("backend", {}).get("url")
    if not config_file.exists():
        issues.append(DiagnosticIssue("high", "missing-config", "Config file does not exist.", "Run any aicli command once to bootstrap ~/.aicli/config.yaml."))
    if not shutil.which("python"):
        issues.append(DiagnosticIssue("critical", "missing-python", "Python executable not found in PATH.", "Install Python 3.10+ and re-run diagnostics."))
    auth = config.get("backend", {}).get("auth", {})
    if not auth.get("principal"):
        issues.append(DiagnosticIssue("medium", "missing-principal", "ICP principal is not configured.", "Set PARALLAX_AI_PRINCIPAL or backend.auth.principal for authenticated requests."))
    if config.get("offline_mode"):
        issues.append(DiagnosticIssue("info", "offline-mode", "Offline mode is enabled.", "Disable offline mode to restore remote PARALLAX calls."))

    checks = {
        "python_version": platform.python_version(),
        "platform": platform.platform(),
        "config_file": str(config_file),
        "backend_url": backend_url,
        "ollama_url": config.get("ollama", {}).get("url"),
        "cwd": os.getcwd(),
        "deep": deep,
    }

    health = {
        "backend_reachable": _check_http(backend_url) if backend_url and not config.get("offline_mode") else False,
        "ollama_reachable": _check_http(config.get("ollama", {}).get("url")) if deep else False,
        "git_available": bool(shutil.which("git")),
    }

    if backend_url and not health["backend_reachable"] and not config.get("offline_mode"):
        issues.append(DiagnosticIssue("high", "backend-unreachable", "PARALLAX backend did not respond.", "Check backend.url, network access, or use local Ollama fallback."))
    if deep and not health["ollama_reachable"]:
        issues.append(DiagnosticIssue("medium", "ollama-unreachable", "Ollama endpoint is not reachable.", "Start Ollama locally or disable the fallback in config."))

    return {
        "checks": checks,
        "health": health,
        "issues": [issue.to_dict() for issue in issues],
        "status": "healthy" if not [issue for issue in issues if issue.severity in {"critical", "high"}] else "attention-needed",
    }


def _check_http(url: str | None) -> bool:
    if not url:
        return False
    try:
        requests.get(url, timeout=2)
        return True
    except requests.RequestException:
        return False


def _text_report(payload: dict[str, Any]) -> str:
    lines = [
        f"Status: {payload['status']}",
        f"Confidence: {payload['confidence']}",
        "",
        "Checks:",
    ]
    for key, value in payload["checks"].items():
        lines.append(f"- {key}: {value}")
    lines.append("
Health:")
    for key, value in payload["health"].items():
        lines.append(f"- {key}: {value}")
    lines.append("
Issues:")
    if payload["issues"]:
        for issue in payload["issues"]:
            lines.append(f"- [{issue['severity']}] {issue['code']}: {issue['message']} -> {issue['suggestion']}")
    else:
        lines.append("- none")
    lines.append("
AI Summary:")
    lines.append(payload["ai_summary"])
    return "
".join(lines)
