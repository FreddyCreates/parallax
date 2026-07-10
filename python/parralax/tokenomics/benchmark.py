"""Tokenomic Benchmark Harness (Sections 15.8–15.9).

Provides a framework for comparing tokenomic vs non-tokenomic AI system outputs.

Research Hypotheses:

    Primary — AI systems governed by Tokenomic allocation will produce higher
    cognitive return per token than non-tokenomic systems, especially in
    operational, financial, research, and multi-step reasoning tasks.

    Secondary — Tokenomic systems will improve over time because reuse extraction
    and memory consolidation reduce future token cost while increasing task accuracy.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from parralax.tokenomics.cognitive_return import (
    CognitiveReturnMetrics,
    CognitiveReturnScore,
)
from parralax.tokenomics.token_value import TokenValueFunction, TokenValueScore


@dataclass
class BenchmarkResult:
    """Result of a single benchmark comparison between two systems.

    Attributes:
        task_name: Human-readable task identifier.
        task_category: Category (e.g. "operational", "financial", "research",
            "multi-step reasoning").
        tokenomic_score: Cognitive return score from the tokenomic system.
        baseline_score: Cognitive return score from the baseline (non-tokenomic) system.
        tokenomic_token_values: Per-token value scores for the tokenomic output.
        baseline_token_values: Per-token value scores for the baseline output.
        metadata: Arbitrary key-value metadata for the run.
    """

    task_name: str
    task_category: str = "general"
    tokenomic_score: CognitiveReturnScore | None = None
    baseline_score: CognitiveReturnScore | None = None
    tokenomic_token_values: list[TokenValueScore] = field(default_factory=list)
    baseline_token_values: list[TokenValueScore] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def crpt_improvement(self) -> float | None:
        """Ratio of tokenomic CRPT to baseline CRPT.

        Returns ``None`` if either score is missing or baseline CRPT is zero.
        A value > 1.0 means the tokenomic system outperforms the baseline.
        """
        if self.tokenomic_score is None or self.baseline_score is None:
            return None
        b = self.baseline_score.crpt
        if b == 0.0:
            return None
        return self.tokenomic_score.crpt / b

    @property
    def token_efficiency_gain(self) -> float | None:
        """Percentage fewer tokens used by tokenomic system for same/better CR.

        Returns ``None`` if either score is missing or baseline has zero tokens.
        Positive means tokenomic used fewer tokens.
        """
        if self.tokenomic_score is None or self.baseline_score is None:
            return None
        bt = self.baseline_score.total_tokens
        if bt == 0:
            return None
        tt = self.tokenomic_score.total_tokens
        return (bt - tt) / bt * 100.0

    @property
    def cognitive_return_delta(self) -> float | None:
        """Absolute difference in cognitive return (tokenomic − baseline)."""
        if self.tokenomic_score is None or self.baseline_score is None:
            return None
        return (
            self.tokenomic_score.cognitive_return
            - self.baseline_score.cognitive_return
        )

    def summary(self) -> dict[str, Any]:
        """Return a summary dict suitable for reporting."""
        result: dict[str, Any] = {
            "task_name": self.task_name,
            "task_category": self.task_category,
        }
        if self.tokenomic_score is not None:
            result["tokenomic_crpt"] = round(self.tokenomic_score.crpt, 6)
            result["tokenomic_cr"] = round(
                self.tokenomic_score.cognitive_return, 4
            )
            result["tokenomic_tokens"] = self.tokenomic_score.total_tokens
        if self.baseline_score is not None:
            result["baseline_crpt"] = round(self.baseline_score.crpt, 6)
            result["baseline_cr"] = round(
                self.baseline_score.cognitive_return, 4
            )
            result["baseline_tokens"] = self.baseline_score.total_tokens
        if self.crpt_improvement is not None:
            result["crpt_improvement_ratio"] = round(
                self.crpt_improvement, 4
            )
        if self.token_efficiency_gain is not None:
            result["token_efficiency_gain_pct"] = round(
                self.token_efficiency_gain, 2
            )
        if self.cognitive_return_delta is not None:
            result["cognitive_return_delta"] = round(
                self.cognitive_return_delta, 4
            )
        return result


class TokenomicBenchmark:
    """Harness for running tokenomic vs baseline comparisons.

    Usage::

        bench = TokenomicBenchmark()

        result = bench.compare(
            task_name="risk-assessment-001",
            task_category="financial",
            tokenomic=dict(
                decision_quality=5, actionability=4, risk_control=5,
                reuse_value=3, learning_gain=4,
                prompt_tokens=400, output_tokens=200,
            ),
            baseline=dict(
                decision_quality=3, actionability=2, risk_control=2,
                reuse_value=1, learning_gain=1,
                prompt_tokens=400, output_tokens=600,
            ),
        )

        print(result.summary())
        print(bench.report())
    """

    def __init__(self) -> None:
        self._results: list[BenchmarkResult] = []
        self._tokenomic_metrics = CognitiveReturnMetrics()
        self._baseline_metrics = CognitiveReturnMetrics()
        self._tvf = TokenValueFunction()

    def compare(
        self,
        *,
        task_name: str,
        task_category: str = "general",
        tokenomic: dict[str, float | int],
        baseline: dict[str, float | int],
        tokenomic_token_values: list[dict[str, float]] | None = None,
        baseline_token_values: list[dict[str, float]] | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> BenchmarkResult:
        """Run a single comparison and record results.

        Parameters:
            task_name: Human-readable task label.
            task_category: Task category for grouping.
            tokenomic: Keyword args for
                :meth:`CognitiveReturnMetrics.record` (tokenomic system).
            baseline: Same, for the baseline system.
            tokenomic_token_values: Optional per-token value factor dicts.
            baseline_token_values: Same for baseline.
            metadata: Arbitrary metadata for the run.

        Returns:
            A :class:`BenchmarkResult` summarizing the comparison.
        """
        t_score = self._tokenomic_metrics.record(**tokenomic)
        b_score = self._baseline_metrics.record(**baseline)

        t_tvs = (
            self._tvf.score_batch(tokenomic_token_values)
            if tokenomic_token_values
            else []
        )
        b_tvs = (
            self._tvf.score_batch(baseline_token_values)
            if baseline_token_values
            else []
        )

        result = BenchmarkResult(
            task_name=task_name,
            task_category=task_category,
            tokenomic_score=t_score,
            baseline_score=b_score,
            tokenomic_token_values=t_tvs,
            baseline_token_values=b_tvs,
            metadata=metadata or {},
        )
        self._results.append(result)
        return result

    @property
    def results(self) -> list[BenchmarkResult]:
        """All recorded benchmark results."""
        return list(self._results)

    def report(self) -> dict[str, Any]:
        """Generate an aggregate benchmark report.

        Returns a dict with overall metrics for both systems and per-category
        breakdowns.
        """
        categories: dict[str, list[BenchmarkResult]] = {}
        for r in self._results:
            categories.setdefault(r.task_category, []).append(r)

        per_category: dict[str, dict[str, Any]] = {}
        for cat, results in categories.items():
            improvements = [
                r.crpt_improvement
                for r in results
                if r.crpt_improvement is not None
            ]
            per_category[cat] = {
                "tasks": len(results),
                "avg_crpt_improvement": (
                    round(sum(improvements) / len(improvements), 4)
                    if improvements
                    else None
                ),
            }

        return {
            "total_tasks": len(self._results),
            "tokenomic_aggregate": self._tokenomic_metrics.summary(),
            "baseline_aggregate": self._baseline_metrics.summary(),
            "per_category": per_category,
            "hypothesis_supported": (
                self._tokenomic_metrics.average_crpt
                > self._baseline_metrics.average_crpt
                if self._results
                else None
            ),
        }
