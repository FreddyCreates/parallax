"""LLM Provider registry — routes requests to OpenAI, Anthropic, or local models."""

from __future__ import annotations

import os
from typing import Any

import httpx
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential

logger = structlog.get_logger()


class ProviderRegistry:
    """Manages LLM provider connections and intelligent routing."""

    def __init__(self) -> None:
        self.providers: dict[str, LLMProvider] = {}
        self._http_client: httpx.AsyncClient | None = None

    async def initialize(self) -> None:
        self._http_client = httpx.AsyncClient(timeout=120.0)

        # Register OpenAI
        openai_key = os.environ.get("OPENAI_API_KEY", "")
        if openai_key:
            self.providers["openai"] = OpenAIProvider(openai_key, self._http_client)
            logger.info("provider_registered", provider="openai")

        # Register Anthropic
        anthropic_key = os.environ.get("ANTHROPIC_API_KEY", "")
        if anthropic_key:
            self.providers["anthropic"] = AnthropicProvider(anthropic_key, self._http_client)
            logger.info("provider_registered", provider="anthropic")

        # Always register local fallback
        self.providers["local"] = LocalProvider()
        logger.info("provider_registered", provider="local")

    async def shutdown(self) -> None:
        if self._http_client:
            await self._http_client.aclose()

    def get_provider(self, name: str) -> LLMProvider | None:
        return self.providers.get(name)

    def route_request(self, model: str) -> LLMProvider:
        """Intelligently route to the best available provider."""
        if model.startswith("gpt-") or model.startswith("o1"):
            if "openai" in self.providers:
                return self.providers["openai"]
        elif model.startswith("claude-"):
            if "anthropic" in self.providers:
                return self.providers["anthropic"]
        # Fallback to local
        return self.providers["local"]

    @property
    def available_providers(self) -> list[str]:
        return list(self.providers.keys())


class LLMProvider:
    """Base class for LLM providers."""

    async def complete(self, prompt: str, model: str, **kwargs: Any) -> dict[str, Any]:
        raise NotImplementedError

    async def chat(self, messages: list[dict], model: str, **kwargs: Any) -> dict[str, Any]:
        raise NotImplementedError

    async def embed(self, texts: list[str], model: str) -> list[list[float]]:
        raise NotImplementedError


class OpenAIProvider(LLMProvider):
    """OpenAI API provider (GPT-4, GPT-4o, o1, embeddings)."""

    BASE_URL = "https://api.openai.com/v1"

    def __init__(self, api_key: str, client: httpx.AsyncClient) -> None:
        self.api_key = api_key
        self.client = client
        self.headers = {
            "Authorization": f"******",
            "Content-Type": "application/json",
        }

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def complete(self, prompt: str, model: str = "gpt-4o", **kwargs: Any) -> dict[str, Any]:
        response = await self.client.post(
            f"{self.BASE_URL}/completions",
            headers=self.headers,
            json={
                "model": model,
                "prompt": prompt,
                "max_tokens": kwargs.get("max_tokens", 2048),
                "temperature": kwargs.get("temperature", 0.7),
            },
        )
        response.raise_for_status()
        return response.json()

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def chat(self, messages: list[dict], model: str = "gpt-4o", **kwargs: Any) -> dict[str, Any]:
        response = await self.client.post(
            f"{self.BASE_URL}/chat/completions",
            headers=self.headers,
            json={
                "model": model,
                "messages": messages,
                "max_tokens": kwargs.get("max_tokens", 4096),
                "temperature": kwargs.get("temperature", 0.7),
                "stream": kwargs.get("stream", False),
            },
        )
        response.raise_for_status()
        return response.json()

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def embed(self, texts: list[str], model: str = "text-embedding-3-large") -> list[list[float]]:
        response = await self.client.post(
            f"{self.BASE_URL}/embeddings",
            headers=self.headers,
            json={"model": model, "input": texts},
        )
        response.raise_for_status()
        data = response.json()
        return [item["embedding"] for item in data["data"]]


class AnthropicProvider(LLMProvider):
    """Anthropic API provider (Claude 3.5, Claude 3 Opus)."""

    BASE_URL = "https://api.anthropic.com/v1"

    def __init__(self, api_key: str, client: httpx.AsyncClient) -> None:
        self.api_key = api_key
        self.client = client
        self.headers = {
            "x-api-key": api_key,
            "Content-Type": "application/json",
            "anthropic-version": "2024-01-01",
        }

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def complete(self, prompt: str, model: str = "claude-sonnet-4-20250514", **kwargs: Any) -> dict[str, Any]:
        return await self.chat(
            [{"role": "user", "content": prompt}],
            model=model,
            **kwargs,
        )

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))
    async def chat(self, messages: list[dict], model: str = "claude-sonnet-4-20250514", **kwargs: Any) -> dict[str, Any]:
        response = await self.client.post(
            f"{self.BASE_URL}/messages",
            headers=self.headers,
            json={
                "model": model,
                "messages": messages,
                "max_tokens": kwargs.get("max_tokens", 4096),
                "temperature": kwargs.get("temperature", 0.7),
            },
        )
        response.raise_for_status()
        return response.json()

    async def embed(self, texts: list[str], model: str = "") -> list[list[float]]:
        # Anthropic doesn't have embeddings; route to OpenAI
        raise NotImplementedError("Use OpenAI for embeddings")


class LocalProvider(LLMProvider):
    """Local/self-hosted model provider (fallback)."""

    async def complete(self, prompt: str, model: str = "local", **kwargs: Any) -> dict[str, Any]:
        return {
            "choices": [{"text": f"[LOCAL] Processed: {prompt[:100]}"}],
            "model": "local-fallback",
            "usage": {"prompt_tokens": len(prompt.split()), "completion_tokens": 10},
        }

    async def chat(self, messages: list[dict], model: str = "local", **kwargs: Any) -> dict[str, Any]:
        last_msg = messages[-1]["content"] if messages else ""
        return {
            "choices": [{"message": {"role": "assistant", "content": f"[LOCAL] {last_msg[:100]}"}}],
            "model": "local-fallback",
            "usage": {"prompt_tokens": 10, "completion_tokens": 10},
        }

    async def embed(self, texts: list[str], model: str = "") -> list[list[float]]:
        # Return zero vectors as placeholder
        return [[0.0] * 1536 for _ in texts]
