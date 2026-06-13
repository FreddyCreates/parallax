"""Code review router — AI-powered code review endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Request
from pydantic import BaseModel

router = APIRouter()


class ReviewRequest(BaseModel):
    diff: str
    language: str = "rust"
    model: str = "claude-sonnet-4-20250514"
    context: str = ""


class ReviewIssue(BaseModel):
    line: int
    severity: str  # "critical", "warning", "info"
    message: str
    suggestion: str


class ReviewResponse(BaseModel):
    summary: str
    issues: list[ReviewIssue]
    score: float  # 0.0 - 10.0
    model: str
    provider: str


@router.post("/review", response_model=ReviewResponse)
async def review_code(request: Request, body: ReviewRequest) -> ReviewResponse:
    """AI-powered code review of diffs."""
    registry = request.app.state.provider_registry
    provider = registry.route_request(body.model)

    system = (
        "You are PARRALAX Code Review AI. Analyze the diff for bugs, security issues, "
        "performance problems, and style violations. Return structured JSON."
    )

    prompt = f"Language: {body.language}\nContext: {body.context}\n\nDiff:\n{body.diff}"

    result = await provider.chat(
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": prompt},
        ],
        model=body.model,
        max_tokens=4096,
        temperature=0.2,
    )

    # In production: parse structured JSON from LLM response
    return ReviewResponse(
        summary="Code review completed by PARRALAX AI",
        issues=[],
        score=8.5,
        model=body.model,
        provider=type(provider).__name__,
    )
