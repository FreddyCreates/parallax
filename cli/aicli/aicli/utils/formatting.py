from __future__ import annotations

from html import escape
import csv
import io
import json
from pathlib import Path
from typing import Any, Iterable

from rich.console import Console
from rich.json import JSON
from rich.markdown import Markdown
from rich.panel import Panel
from rich.syntax import Syntax
from rich.table import Table
from rich.tree import Tree

console = Console()


def emit_text(title: str, body: str) -> None:
    console.print(Panel.fit(body, title=title, border_style="cyan"))


def emit_markdown(markdown_text: str) -> None:
    console.print(Markdown(markdown_text))


def emit_json(payload: Any) -> None:
    console.print(JSON.from_data(payload))


def emit_syntax(code: str, language: str = "python") -> None:
    console.print(Syntax(code, language, line_numbers=True, word_wrap=True))


def emit_key_value_table(title: str, data: dict[str, Any]) -> None:
    table = Table(title=title)
    table.add_column("Key", style="bold cyan")
    table.add_column("Value", style="white")
    for key, value in data.items():
        table.add_row(str(key), _stringify(value))
    console.print(table)


def emit_list_table(title: str, rows: Iterable[dict[str, Any]]) -> None:
    rows = list(rows)
    if not rows:
        console.print(Panel.fit("No data.", title=title, border_style="yellow"))
        return
    headers = list(rows[0].keys())
    table = Table(title=title)
    for header in headers:
        table.add_column(str(header), overflow="fold")
    for row in rows:
        table.add_row(*[_stringify(row.get(header, "")) for header in headers])
    console.print(table)


def emit_call_graph(root_name: str, graph: dict[str, Any]) -> None:
    tree = Tree(root_name)
    _walk_graph(tree, graph)
    console.print(tree)


def export_payload(payload: Any, output_format: str) -> str:
    normalized = output_format.lower()
    if normalized == "json":
        return json.dumps(payload, indent=2, default=str)
    if normalized == "markdown":
        return payload if isinstance(payload, str) else _dict_to_markdown(payload)
    if normalized == "csv":
        return _to_csv(payload)
    if normalized == "html":
        return _to_html(payload)
    return payload if isinstance(payload, str) else _stringify(payload)


def write_export(payload: Any, output_format: str, target: str | Path) -> Path:
    target_path = Path(target).expanduser()
    target_path.write_text(export_payload(payload, output_format), encoding="utf-8")
    return target_path


def render_output(payload: Any, output_format: str, title: str = "Result") -> None:
    normalized = output_format.lower()
    if normalized == "json":
        emit_json(payload)
    elif normalized == "markdown":
        emit_markdown(payload if isinstance(payload, str) else _dict_to_markdown(payload))
    else:
        emit_text(title, export_payload(payload, normalized))


def _dict_to_markdown(payload: Any) -> str:
    if isinstance(payload, dict):
        lines: list[str] = []
        for key, value in payload.items():
            lines.append(f"## {key}")
            if isinstance(value, list):
                for item in value:
                    lines.append(f"- {_stringify(item)}")
            else:
                lines.append(_stringify(value))
            lines.append("")
        return "
".join(lines).strip()
    return _stringify(payload)


def _to_csv(payload: Any) -> str:
    rows: list[dict[str, Any]]
    if isinstance(payload, list):
        rows = [item if isinstance(item, dict) else {"value": item} for item in payload]
    elif isinstance(payload, dict):
        rows = [{"key": key, "value": value} for key, value in payload.items()]
    else:
        rows = [{"value": payload}]
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    for row in rows:
        writer.writerow({key: _stringify(value) for key, value in row.items()})
    return output.getvalue().strip()


def _to_html(payload: Any) -> str:
    body = escape(json.dumps(payload, indent=2, default=str)) if not isinstance(payload, str) else payload
    return (
        "<html><head><style>body{font-family:Arial;margin:2rem;}pre{background:#111;color:#f5f5f5;padding:1rem;border-radius:8px;}"
        "</style></head><body><pre>" + body + "</pre></body></html>"
    )


def _walk_graph(tree: Tree, graph: dict[str, Any]) -> None:
    for name, children in graph.items():
        branch = tree.add(name)
        if isinstance(children, dict):
            _walk_graph(branch, children)


def _stringify(value: Any) -> str:
    if isinstance(value, (dict, list, tuple)):
        return json.dumps(value, indent=2, default=str)
    return str(value)
