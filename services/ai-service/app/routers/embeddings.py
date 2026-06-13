"""Embeddings router — vector embedding generation."""

from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter()


class EmbeddingRequest(BaseModel):
    texts: list[str]
    model: str = "text-embedding-3-large"


class EmbeddingResponse(BaseModel):
    embeddings: list[list[float]]
    model: str
    dimensions: int
    provider: str


@router.post("/embeddings", response_model=EmbeddingResponse)
async def create_embeddings(request: Request, body: EmbeddingRequest) -> EmbeddingResponse:
    """Generate vector embeddings for code/text."""
    registry = request.app.state.provider_registry

    # Embeddings always route to OpenAI (or local fallback)
    provider = registry.get_provider("openai") or registry.get_provider("local")
    if provider is None:
        provider = registry.providers["local"]

    vectors = await provider.embed(body.texts, model=body.model)

    return EmbeddingResponse(
        embeddings=vectors,
        model=body.model,
        dimensions=len(vectors[0]) if vectors else 0,
        provider=type(provider).__name__,
    )
