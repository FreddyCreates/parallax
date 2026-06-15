from __future__ import annotations

from pathlib import Path

import typer

from ..ai.models import AIRequest, TaskType
from ..utils.formatting import console, emit_syntax

TEMPLATES = {
    "test": ("py", "import pytest


def test_{name}():
    assert True
"),
    "script": ("py", "def main() -> None:
    print("hello from {name}")


if __name__ == "__main__":
    main()
"),
    "docs": ("md", "# {name}

## Overview

Describe the purpose of `{name}` here.
"),
    "handler": ("py", "from fastapi import APIRouter

router = APIRouter()


@router.get("/{name}")
def get_{safe_name}() -> dict[str, str]:
    return {"status": "ok", "handler": "{name}"}
"),
    "component": ("tsx", "type {component_name}Props = {
  title?: string;
};

export function {component_name}({{ title = "{component_name}" }}: {component_name}Props) {{
  return <section>{'{'}title{'}'}</section>;
}}
"),
}


def generate_command(
    ctx: typer.Context,
    type: str = typer.Argument(..., help="Artifact type: test, script, docs, handler, component."),
    name: str | None = typer.Option(None, "--name", help="Artifact name."),
    template: str | None = typer.Option(None, "--template", help="Template variant label."),
    dry_run: bool = typer.Option(False, "--dry-run", help="Print generated output without writing a file."),
) -> None:
    app = ctx.obj
    artifact_type = type.lower()
    if artifact_type not in TEMPLATES:
        raise typer.BadParameter(f"Unsupported type '{type}'. Choose from: {', '.join(TEMPLATES)}")

    artifact_name = name or _interactive_prompt("Artifact name", default=f"sample_{artifact_type}")
    template_name = template or _interactive_prompt("Template label", default="default")
    ext, template_text = TEMPLATES[artifact_type]
    safe_name = artifact_name.replace("-", "_")
    component_name = "".join(part.capitalize() for part in safe_name.split("_"))
    generated = template_text.format(name=artifact_name, safe_name=safe_name, component_name=component_name)

    request = AIRequest(
        task=TaskType.GENERATE,
        prompt=f"Refine the generated {artifact_type} boilerplate named {artifact_name} using template {template_name}.",
        context={"artifact_type": artifact_type, "template": template_name, "generated": generated},
        profile=app.profile,
    )
    response = app.router.query(request)
    final_output = response.text if response.provider != "offline" and response.text.strip() else generated

    emit_syntax(final_output, _syntax_lang(ext))
    if dry_run:
        console.print("[yellow]Dry run enabled; no file written.[/yellow]")
        return

    target_path = Path.cwd() / f"{artifact_name}.{ext}"
    if target_path.exists():
        raise typer.BadParameter(f"Refusing to overwrite existing file: {target_path}")
    target_path.write_text(final_output, encoding="utf-8")
    console.print(f"[green]Generated[/green] {target_path}")


def _interactive_prompt(label: str, default: str) -> str:
    if not console.is_terminal:
        return default
    return typer.prompt(label, default=default)


def _syntax_lang(ext: str) -> str:
    return {"py": "python", "tsx": "tsx", "md": "markdown"}.get(ext, "text")
