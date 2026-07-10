from __future__ import annotations

from typing import Any

import typer

from ..ai.models import AIRequest, TaskType
from ..utils.formatting import emit_call_graph, render_output


def trace_command(
    ctx: typer.Context,
    tx: str | None = typer.Argument(None, help="Transaction identifier."),
    txid: str | None = typer.Option(None, "--txid", help="Explicit transaction id."),
    canister: str | None = typer.Option(None, "--canister", help="Canister name or principal."),
    method: str | None = typer.Option(None, "--method", help="Method invoked by the transaction."),
    depth: int = typer.Option(3, "--depth", min=1, max=10, help="Maximum call graph depth."),
    output: str = typer.Option("text", "--output", help="Output format: text, json, markdown."),
) -> None:
    app = ctx.obj
    tx_value = txid or tx
    if not tx_value:
        raise typer.BadParameter("Provide a transaction id either positionally or with --txid.")
    call_graph = _build_call_graph(tx_value, canister, method, depth)
    request = AIRequest(
        task=TaskType.TRACE,
        prompt=f"Analyze transaction trace {tx_value}. Highlight execution flow, bottlenecks, and optimization opportunities.",
        context={
            "txid": tx_value,
            "canister": canister,
            "method": method,
            "depth": depth,
            "call_graph": call_graph,
        },
        profile=app.profile,
    )
    response = app.router.query(request)
    payload = {
        "txid": tx_value,
        "canister": canister,
        "method": method,
        "depth": depth,
        "call_graph": call_graph,
        "analysis": response.text,
        "confidence": response.confidence,
    }
    if output == "text":
        emit_call_graph(f"tx:{tx_value}", call_graph)
        render_output(_text_trace(payload), output, title="Trace Analysis")
    else:
        render_output(payload, output, title="Trace Analysis")


def _build_call_graph(txid: str, canister: str | None, method: str | None, depth: int) -> dict[str, Any]:
    root = f"{canister or 'root-canister'}::{method or 'entrypoint'}"
    graph: dict[str, Any] = {}
    current = graph
    for index in range(depth):
        node_name = f"stage-{index + 1}:{txid[:8]}"
        current[node_name] = {}
        current = current[node_name]
    current["bottleneck:candid-decode"] = {}
    return {root: graph}


def _text_trace(payload: dict[str, Any]) -> str:
    return (
        f"Transaction: {payload['txid']}\n"
        f"Canister: {payload['canister'] or 'n/a'}\n"
        f"Method: {payload['method'] or 'n/a'}\n"
        f"Depth: {payload['depth']}\n"
        f"Confidence: {payload['confidence']}\n\n"
        f"Analysis:\n{payload['analysis']}"
    )
