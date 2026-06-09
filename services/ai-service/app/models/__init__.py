"""Pydantic models for the AI service."""

from __future__ import annotations

from pydantic import BaseModel
from enum import Enum


class Provider(str, Enum):
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    LOCAL = "local"


class ModelInfo(BaseModel):
    name: str
    provider: Provider
    max_tokens: int
    supports_streaming: bool
    cost_per_1k_input: float
    cost_per_1k_output: float


# Available models registry
AVAILABLE_MODELS: list[ModelInfo] = [
    ModelInfo(
        name="gpt-4o",
        provider=Provider.OPENAI,
        max_tokens=128000,
        supports_streaming=True,
        cost_per_1k_input=0.005,
        cost_per_1k_output=0.015,
    ),
    ModelInfo(
        name="gpt-4-turbo",
        provider=Provider.OPENAI,
        max_tokens=128000,
        supports_streaming=True,
        cost_per_1k_input=0.01,
        cost_per_1k_output=0.03,
    ),
    ModelInfo(
        name="claude-sonnet-4-20250514",
        provider=Provider.ANTHROPIC,
        max_tokens=200000,
        supports_streaming=True,
        cost_per_1k_input=0.003,
        cost_per_1k_output=0.015,
    ),
    ModelInfo(
        name="claude-3-opus-20240229",
        provider=Provider.ANTHROPIC,
        max_tokens=200000,
        supports_streaming=True,
        cost_per_1k_input=0.015,
        cost_per_1k_output=0.075,
    ),
    ModelInfo(
        name="local-fallback",
        provider=Provider.LOCAL,
        max_tokens=4096,
        supports_streaming=False,
        cost_per_1k_input=0.0,
        cost_per_1k_output=0.0,
    ),
]
