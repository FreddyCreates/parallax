"""PARRALAX Tokenomics — Measurement and Benchmarking Framework.

Implements Section 15 of the Tokenomics doctrine: a measurement layer that evaluates
AI system performance not by token count, but by cognitive return per token.

Modules:
    token_value: Token Value Function (TV) scoring (Section 15.1)
    cognitive_return: Cognitive Return Per Token (CRPT) metrics (Section 15.2)
    salience: Salience Allocation Equations (Section 15.3)
    compression: Compression Efficiency Metrics (Section 15.4)
    benchmark: Benchmark harness for tokenomic vs non-tokenomic comparison (Section 15.5)
    runtime_loop: Runtime Measurement Loop (Section 15.6)
    evaluation: Evaluation Criteria (Section 15.7)
"""

from parralax.tokenomics.token_value import TokenValueFunction, TokenValueScore
from parralax.tokenomics.cognitive_return import (
    CognitiveReturnMetrics,
    CognitiveReturnScore,
)
from parralax.tokenomics.salience import SalienceEngine, SalienceItem, SalienceScore
from parralax.tokenomics.compression import CompressionAuditor, CompressionScore
from parralax.tokenomics.benchmark import TokenomicBenchmark, BenchmarkResult
from parralax.tokenomics.runtime_loop import RuntimeMeasurementLoop, TaskClass, TaskContext
from parralax.tokenomics.evaluation import (
    TokenomicEvaluator,
    EvaluationCriterion,
    EvaluationResult,
)

__all__ = [
    "TokenValueFunction",
    "TokenValueScore",
    "CognitiveReturnMetrics",
    "CognitiveReturnScore",
    "SalienceEngine",
    "SalienceItem",
    "SalienceScore",
    "CompressionAuditor",
    "CompressionScore",
    "TokenomicBenchmark",
    "BenchmarkResult",
    "RuntimeMeasurementLoop",
    "TaskClass",
    "TaskContext",
    "TokenomicEvaluator",
    "EvaluationCriterion",
    "EvaluationResult",
]
