"""PARRALAX AI Service — FastAPI with OpenAI + Anthropic LLM routing."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app

from app.routers import completions, chat, review, embeddings
from app.routers.actuary import router as actuary_router
from app.routers.financial_languages.router import router as financial_router
from app.routers.trading import router as trading_router
from app.providers import ProviderRegistry

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan — initialize and teardown resources."""
    logger.info("parralax_ai_service_starting")
    app.state.provider_registry = ProviderRegistry()
    await app.state.provider_registry.initialize()
    yield
    logger.info("parralax_ai_service_stopping")
    await app.state.provider_registry.shutdown()


app = FastAPI(
    title="PARRALAX AI Service",
    description="Sovereign AI-Native LLM Routing — OpenAI + Anthropic + Local Models",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Prometheus metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Register routers
app.include_router(completions.router, prefix="/api/v1", tags=["completions"])
app.include_router(chat.router, prefix="/api/v1", tags=["chat"])
app.include_router(review.router, prefix="/api/v1", tags=["review"])
app.include_router(embeddings.router, prefix="/api/v1", tags=["embeddings"])
app.include_router(actuary_router, prefix="/api/v1", tags=["actuary"])
app.include_router(trading_router, prefix="/api/v1", tags=["trading"])
app.include_router(financial_router, prefix="/api/v1", tags=["financial_languages"])


@app.get("/health")
async def health() -> dict:
    return {
        "status": "healthy",
        "service": "parralax-ai-intelligence-actuary-suite",
        "version": "2.0.0",
        "providers": ["openai", "anthropic", "local"],
        "modules": {
            "actuary": ["risk_pricing", "greeks", "portfolio_insurance", "strategy_lifecycle", "reserves"],
            "trading": [
                "statistical_arbitrage", "market_making", "momentum", "mean_reversion",
                "pairs_trading", "volatility_arbitrage", "liquidity_provision",
                "cross_asset_arbitrage", "event_driven", "ml_alpha",
            ],
            "financial_languages": ["FIX", "FpML", "SWIFT", "ISDA_CDM", "XBRL", "ISO20022"],
        },
    }
