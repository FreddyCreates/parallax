"""PARRALAX Tokenomics — Measurement and Benchmarking Framework.

Implements Section 15 of the Tokenomics doctrine: a measurement layer that evaluates
AI system performance not by token count, but by cognitive return per token.

Modules:
    token_value: Token Value Function (TV) scoring
    cognitive_return: Cognitive Return Per Token (CRPT) metrics
    benchmark: Benchmark harness for tokenomic vs non-tokenomic comparison
"""

from parralax.tokenomics.token_value import TokenValueFunction, TokenValueScore
from parralax.tokenomics.cognitive_return import (
    CognitiveReturnMetrics,
    CognitiveReturnScore,
)
from parralax.tokenomics.benchmark import TokenomicBenchmark, BenchmarkResult

__all__ = [
    "TokenValueFunction",
    "TokenValueScore",
    "CognitiveReturnMetrics",
    "CognitiveReturnScore",
    "TokenomicBenchmark",
    "BenchmarkResult",
]
