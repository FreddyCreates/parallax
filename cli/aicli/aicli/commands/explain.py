from __future__ import annotations

import ast
from collections import Counter
from pathlib import Path
from typing import Any

import typer

from ..ai.models import AIRequest, TaskType
from ..utils.formatting import console, render_output


def explain_command(
    ctx: typer.Context,
    file: Path = typer.Argument(..., exists=True, dir_okay=False, readable=True, resolve_path=True),
    lang: str | None = typer.Option(None, "--lang", help="Force a language override."),
    detail: str = typer.Option("brief", "--detail", help="Explanation detail level: brief or full."),
    output: str = typer.Option("text", "--output", help="Output format: text, json, markdown."),
) -> None:
    app = ctx.obj
    language = lang or _detect_language(file)
    analysis = _analyze_file(file, language)
    prompt = (
        f"Explain the {language} file {file.name}. Include architecture, dependencies, logic flow, "
        f"documentation guidance, and complexity hotspots. Detail level: {detail}."
    )
    request = AIRequest(
        task=TaskType.EXPLAIN,
        prompt=prompt,
        context={
            "path": str(file),
            "detail": detail,
            "analysis": analysis,
            "snippet": file.read_text(encoding="utf-8", errors="ignore")[:5000],
        },
        profile=app.profile,
        stream=output != "json",
    )

    with console.status("Explaining code with routed AI analysis..."):
        response = app.router.query(request)

    payload = {
        "file": str(file),
        "language": language,
        "analysis": analysis,
        "explanation": response.text,
        "confidence": response.confidence,
        "reasoning": response.reasoning,
        "suggestions": response.suggestions,
    }
    if output == "markdown":
        render_output(_to_markdown(payload), "markdown", title="Code Explanation")
    else:
        render_output(payload if output == "json" else _text_summary(payload), output, title="Code Explanation")


def _analyze_file(file: Path, language: str) -> dict[str, Any]:
    text = file.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines()
    hotspots = _hotspots(lines)
    if language == "python":
        try:
            return _analyze_python(file, text, hotspots)
        except SyntaxError:
            return {
                "line_count": len(lines),
                "dependencies": _guess_dependencies(text),
                "logic_flow": [
                    "Python parsing failed; falling back to text-level inspection.",
                    "Inspect imports and branching-heavy lines heuristically.",
                    "Use routed AI to explain probable behavior and risks.",
                ],
                "hotspots": hotspots,
                "parse_error": "syntax-error",
            }
    return {
        "line_count": len(lines),
        "dependencies": _guess_dependencies(text),
        "logic_flow": [
            "Read source file.",
            "Inspect top-level declarations and branching statements.",
            "Summarize notable hotspots and risks.",
        ],
        "hotspots": hotspots,
    }


def _analyze_python(file: Path, text: str, hotspots: list[dict[str, Any]]) -> dict[str, Any]:
    tree = ast.parse(text, filename=str(file))
    imports: list[str] = []
    functions: list[dict[str, Any]] = []
    classes: list[str] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imports.extend(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom):
            module = node.module or ""
            imports.extend(f"{module}.{alias.name}".strip(".") for alias in node.names)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            branch_nodes = sum(
                isinstance(child, (ast.If, ast.For, ast.While, ast.Try, ast.Match))
                for child in ast.walk(node)
            )
            functions.append(
                {
                    "name": node.name,
                    "line": getattr(node, "lineno", 0),
                    "branch_points": branch_nodes,
                    "docstring": bool(ast.get_docstring(node)),
                }
            )
        elif isinstance(node, ast.ClassDef):
            classes.append(node.name)

    return {
        "line_count": len(text.splitlines()),
        "dependencies": sorted(set(imports)),
        "classes": classes,
        "functions": sorted(functions, key=lambda item: (-item["branch_points"], item["line"])),
        "logic_flow": [
            "Parse imports, classes, and functions.",
            "Measure branch-heavy regions to identify complexity hotspots.",
            "Use routed AI to generate explanation and documentation guidance.",
        ],
        "hotspots": hotspots,
    }


def _hotspots(lines: list[str]) -> list[dict[str, Any]]:
    findings: list[dict[str, Any]] = []
    for idx, line in enumerate(lines, start=1):
        score = sum(token in line for token in ("if ", "for ", "while ", "try:", "except", "match ", "lambda "))
        score += max(0, (len(line) - 100) // 20)
        if score > 0:
            findings.append({"line": idx, "score": score, "preview": line.strip()[:120]})
    return sorted(findings, key=lambda item: (-item["score"], item["line"]))[:8]


def _guess_dependencies(text: str) -> list[str]:
    counter: Counter[str] = Counter()
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("import ") or stripped.startswith("from "):
            counter[stripped] += 1
        elif "require(" in stripped or 'from "' in stripped or "from '" in stripped:
            counter[stripped[:120]] += 1
    return list(counter.keys())[:12]


def _detect_language(file: Path) -> str:
    return {
        ".py": "python",
        ".ts": "typescript",
        ".tsx": "tsx",
        ".js": "javascript",
        ".rs": "rust",
        ".mo": "motoko",
        ".md": "markdown",
        ".json": "json",
        ".yaml": "yaml",
        ".yml": "yaml",
    }.get(file.suffix.lower(), file.suffix.lstrip(".") or "text")


def _to_markdown(payload: dict[str, Any]) -> str:
    analysis = payload["analysis"]
    logic_flow = "\n".join(f"- {step}" for step in analysis.get("logic_flow", []))
    hotspots = "\n".join(
        f"- Line {item['line']} (score {item['score']}): `{item['preview']}`"
        for item in analysis.get("hotspots", [])
    ) or "- none detected"
    return (
        f"# Explanation for `{Path(payload['file']).name}`\n\n"
        f"**Language:** {payload['language']}  \n"
        f"**Confidence:** {payload['confidence']}\n\n"
        "## Analysis Snapshot\n\n"
        f"- Line count: {analysis.get('line_count', 'n/a')}\n"
        f"- Dependencies: {', '.join(analysis.get('dependencies', [])) or 'none detected'}\n"
        f"- Hotspots: {len(analysis.get('hotspots', []))}\n\n"
        "## Logic Flow\n\n"
        f"{logic_flow}\n\n"
        "## AI Explanation\n\n"
        f"{payload['explanation']}\n\n"
        "## Complexity Hotspots\n\n"
        f"{hotspots}"
    )


def _text_summary(payload: dict[str, Any]) -> str:
    analysis = payload["analysis"]
    return (
        f"File: {payload['file']}\n"
        f"Language: {payload['language']}\n"
        f"Confidence: {payload['confidence']}\n"
        f"Dependencies: {', '.join(analysis.get('dependencies', [])) or 'none detected'}\n"
        f"Hotspots: {len(analysis.get('hotspots', []))}\n\n"
        f"Explanation:\n{payload['explanation']}"
    )
