"""Chat router — conversational AI endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter()


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    model: str = "claude-sonnet-4-20250514"
    max_tokens: int = 4096
    temperature: float = 0.7
    system: str = "You are PARRALAX AI — a sovereign financial intelligence system."


class ChatResponse(BaseModel):
    message: ChatMessage
    model: str
    tokens_used: int
    provider: str


@router.post("/chat", response_model=ChatResponse)
async def create_chat(request: Request, body: ChatRequest) -> ChatResponse:
    """Multi-turn chat with intelligent provider routing."""
    registry = request.app.state.provider_registry
    provider = registry.route_request(body.model)

    messages = [{"role": "system", "content": body.system}]
    messages.extend([{"role": m.role, "content": m.content} for m in body.messages])

    result = await provider.chat(
        messages=messages,
        model=body.model,
        max_tokens=body.max_tokens,
        temperature=body.temperature,
    )

    response_text = ""
    if "choices" in result and result["choices"]:
        choice = result["choices"][0]
        msg = choice.get("message", {})
        response_text = msg.get("content", "")
    elif "content" in result:
        # Anthropic format
        content_blocks = result.get("content", [])
        if content_blocks:
            response_text = content_blocks[0].get("text", "")

    tokens = result.get("usage", {}).get("completion_tokens", 0)

    return ChatResponse(
        message=ChatMessage(role="assistant", content=response_text),
        model=body.model,
        tokens_used=tokens,
        provider=type(provider).__name__,
    )
