"""Completions router — code completion endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter()


class CompletionRequest(BaseModel):
    prompt: str
    model: str = "gpt-4o"
    max_tokens: int = 2048
    temperature: float = 0.3
    language: str = "rust"
    context: str = ""


class CompletionResponse(BaseModel):
    completion: str
    model: str
    tokens_used: int
    provider: str


@router.post("/completions", response_model=CompletionResponse)
async def create_completion(request: Request, body: CompletionRequest) -> CompletionResponse:
    """Generate code completion using routed LLM provider."""
    registry = request.app.state.provider_registry
    provider = registry.route_request(body.model)

    system_prompt = (
        f"You are PARRALAX AI — a sovereign code completion engine. "
        f"Language: {body.language}. Provide only code, no explanations."
    )

    full_prompt = f"{system_prompt}\n\nContext:\n{body.context}\n\nComplete:\n{body.prompt}"

    result = await provider.complete(
        prompt=full_prompt,
        model=body.model,
        max_tokens=body.max_tokens,
        temperature=body.temperature,
    )

    completion_text = ""
    if "choices" in result and result["choices"]:
        choice = result["choices"][0]
        completion_text = choice.get("text", choice.get("message", {}).get("content", ""))

    tokens = result.get("usage", {}).get("completion_tokens", 0)

    return CompletionResponse(
        completion=completion_text,
        model=body.model,
        tokens_used=tokens,
        provider=type(provider).__name__,
    )
