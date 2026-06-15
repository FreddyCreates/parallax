from __future__ import annotations

import typer

from ..ai.models import AIRequest, TaskType
from ..utils.formatting import console, emit_json, emit_markdown, export_payload


def query_model_command(
    ctx: typer.Context,
    prompt: str = typer.Argument(..., help="Prompt to send to the routed model."),
    model: str | None = typer.Option(None, "--model", help="Explicit model override."),
    temperature: float = typer.Option(0.2, "--temperature", min=0.0, max=2.0),
    max_tokens: int = typer.Option(1200, "--max-tokens", min=64, max=8192),
    format: str = typer.Option("text", "--format", help="Output format: text, json, markdown, csv."),
    session: str | None = typer.Option(None, "--session", help="Conversation session id for multi-turn chats."),
    clear_session: bool = typer.Option(False, "--clear-session", help="Clear the named session before sending the prompt."),
    no_stream: bool = typer.Option(False, "--no-stream", help="Disable streamed display output."),
) -> None:
    app = ctx.obj
    if clear_session and session:
        app.router.clear_conversation(session)
    request = AIRequest(
        task=TaskType.QUERY,
        prompt=prompt,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
        stream=not no_stream,
        conversation_id=session,
        profile=app.profile,
        context={"format": format},
    )

    chunks: list[str] = []

    def _on_chunk(chunk: str) -> None:
        chunks.append(chunk)
        if format == "text":
            console.print(chunk, end="")

    response = app.router.query(request, on_chunk=_on_chunk if request.stream and format == "text" else None)
    if format == "text":
        if request.stream:
            console.print()
        else:
            console.print(response.text)
        console.print(f"
[dim]provider={response.provider} model={response.model} confidence={response.confidence} cached={response.cached}[/dim]")
        return

    payload = {
        "prompt": prompt,
        "response": response.to_dict(),
        "session": session,
    }
    if format == "json":
        emit_json(payload)
    elif format == "markdown":
        emit_markdown(f"# Query Result

{response.text}

- Provider: {response.provider}
- Model: {response.model}
- Confidence: {response.confidence}")
    else:
        console.print(export_payload(payload, format))
