"""Evaluation Criteria (Section 15.7).

A mature tokenomic system is evaluated by eight criteria that move Tokenomics
from stylistic preference to measurable system performance:

    1. Cognitive Return Per Token — useful cognition per total token spent
    2. Compression Fidelity — compressed output preserves meaning
    3. Action Conversion Rate — outputs lead directly to correct action
    4. Risk Preservation — concise without hiding important uncertainty
    5. Reuse Extraction Rate — interactions converted into reusable artifacts
    6. Context Hygiene — avoiding context pollution with irrelevant info
    7. Adaptive Depth Accuracy — expand/compress based on task stakes
    8. Error Avoidance — prevent math, scope, logic, or operational mistakes
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class EvaluationCriterion(str, Enum):
    """The eight evaluation criteria for a mature tokenomic system."""

    COGNITIVE_RETURN_PER_TOKEN = "cognitive_return_per_token"
    COMPRESSION_FIDELITY = "compression_fidelity"
    ACTION_CONVERSION_RATE = "action_conversion_rate"
    RISK_PRESERVATION = "risk_preservation"
    REUSE_EXTRACTION_RATE = "reuse_extraction_rate"
    CONTEXT_HYGIENE = "context_hygiene"
    ADAPTIVE_DEPTH_ACCURACY = "adaptive_depth_accuracy"
    ERROR_AVOIDANCE = "error_avoidance"


CRITERION_DEFINITIONS: dict[EvaluationCriterion, str] = {
    EvaluationCriterion.COGNITIVE_RETURN_PER_TOKEN: (
        "Useful cognition generated per total token spent"
    ),
    EvaluationCriterion.COMPRESSION_FIDELITY: (
        "Degree to which compressed output preserves meaning"
    ),
    EvaluationCriterion.ACTION_CONVERSION_RATE: (
        "Percentage of outputs that lead directly to correct action"
    ),
    EvaluationCriterion.RISK_PRESERVATION: (
        "Ability to stay concise without hiding important uncertainty"
    ),
    EvaluationCriterion.REUSE_EXTRACTION_RATE: (
        "Frequency of converting interactions into reusable rules, templates, or memory"
    ),
    EvaluationCriterion.CONTEXT_HYGIENE: (
        "Ability to avoid polluting context with irrelevant information"
    ),
    EvaluationCriterion.ADAPTIVE_DEPTH_ACCURACY: (
        "Ability to expand or compress based on task stakes"
    ),
    EvaluationCriterion.ERROR_AVOIDANCE: (
        "Ability to prevent math, scope, logic, or operational mistakes"
    ),
}


@dataclass(frozen=True)
class CriterionScore:
    """Score for a single evaluation criterion.

    Attributes:
        criterion: Which criterion is being scored.
        score: Rating on 0–5 scale.
        evidence: Optional evidence or notes supporting the score.
    """

    criterion: EvaluationCriterion
    score: float = 0.0
    evidence: str = ""

    @property
    def definition(self) -> str:
        """Return the definition for this criterion."""
        return CRITERION_DEFINITIONS[self.criterion]


@dataclass
class EvaluationResult:
    """Complete evaluation of a system across all eight criteria.

    Attributes:
        system_name: Identifier for the system being evaluated.
        scores: Individual criterion scores.
        metadata: Arbitrary metadata.
    """

    system_name: str = ""
    scores: list[CriterionScore] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def total_score(self) -> float:
        """Sum of all criterion scores (max 40)."""
        return sum(s.score for s in self.scores)

    @property
    def average_score(self) -> float:
        """Average score across scored criteria."""
        if not self.scores:
            return 0.0
        return self.total_score / len(self.scores)

    @property
    def maturity_level(self) -> str:
        """Classify system maturity based on average score.

        - ≥ 4.0: "production" — deployable tokenomic system
        - ≥ 3.0: "operational" — functional but improvable
        - ≥ 2.0: "developing" — partial tokenomic capability
        - < 2.0: "nascent" — minimal tokenomic behavior
        """
        avg = self.average_score
        if avg >= 4.0:
            return "production"
        if avg >= 3.0:
            return "operational"
        if avg >= 2.0:
            return "developing"
        return "nascent"

    def by_criterion(self, criterion: EvaluationCriterion) -> CriterionScore | None:
        """Look up score for a specific criterion."""
        for s in self.scores:
            if s.criterion == criterion:
                return s
        return None

    def summary(self) -> dict[str, Any]:
        """Return a summary dict suitable for reporting."""
        return {
            "system_name": self.system_name,
            "total_score": round(self.total_score, 4),
            "average_score": round(self.average_score, 4),
            "maturity_level": self.maturity_level,
            "criteria_scored": len(self.scores),
            "scores": {
                s.criterion.value: round(s.score, 2) for s in self.scores
            },
        }


class TokenomicEvaluator:
    """Evaluate one or more systems against the tokenomic criteria.

    Usage::

        evaluator = TokenomicEvaluator()
        result = evaluator.evaluate(
            system_name="parallax-v2",
            scores={
                EvaluationCriterion.COGNITIVE_RETURN_PER_TOKEN: 4.5,
                EvaluationCriterion.COMPRESSION_FIDELITY: 4.0,
                EvaluationCriterion.ACTION_CONVERSION_RATE: 3.8,
                EvaluationCriterion.RISK_PRESERVATION: 4.2,
                EvaluationCriterion.REUSE_EXTRACTION_RATE: 3.5,
                EvaluationCriterion.CONTEXT_HYGIENE: 4.0,
                EvaluationCriterion.ADAPTIVE_DEPTH_ACCURACY: 3.7,
                EvaluationCriterion.ERROR_AVOIDANCE: 4.3,
            },
        )
        print(result.maturity_level)
        print(evaluator.compare("parallax-v2", "baseline-v1"))
    """

    def __init__(self) -> None:
        self._results: dict[str, EvaluationResult] = {}

    def evaluate(
        self,
        *,
        system_name: str,
        scores: dict[EvaluationCriterion, float],
        evidence: dict[EvaluationCriterion, str] | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> EvaluationResult:
        """Evaluate a system across provided criteria.

        Parameters:
            system_name: Identifier for the system.
            scores: Map of criterion to score (0–5).
            evidence: Optional evidence per criterion.
            metadata: Arbitrary metadata.

        Returns:
            An :class:`EvaluationResult` with all scores.
        """
        evidence = evidence or {}
        criterion_scores = [
            CriterionScore(
                criterion=criterion,
                score=score,
                evidence=evidence.get(criterion, ""),
            )
            for criterion, score in scores.items()
        ]
        result = EvaluationResult(
            system_name=system_name,
            scores=criterion_scores,
            metadata=metadata or {},
        )
        self._results[system_name] = result
        return result

    def get_result(self, system_name: str) -> EvaluationResult | None:
        """Retrieve evaluation result for a system."""
        return self._results.get(system_name)

    @property
    def results(self) -> dict[str, EvaluationResult]:
        """All evaluation results keyed by system name."""
        return dict(self._results)

    def compare(
        self, system_a: str, system_b: str
    ) -> dict[str, Any] | None:
        """Compare two evaluated systems.

        Returns a comparison dict, or None if either system hasn't been evaluated.
        """
        a = self._results.get(system_a)
        b = self._results.get(system_b)
        if a is None or b is None:
            return None

        comparison: dict[str, Any] = {
            "system_a": system_a,
            "system_b": system_b,
            "score_a": round(a.total_score, 4),
            "score_b": round(b.total_score, 4),
            "maturity_a": a.maturity_level,
            "maturity_b": b.maturity_level,
            "winner": system_a if a.total_score >= b.total_score else system_b,
            "delta": round(a.total_score - b.total_score, 4),
        }

        # Per-criterion comparison
        criteria_delta: dict[str, float] = {}
        for criterion in EvaluationCriterion:
            sa = a.by_criterion(criterion)
            sb = b.by_criterion(criterion)
            if sa is not None and sb is not None:
                criteria_delta[criterion.value] = round(sa.score - sb.score, 2)
        comparison["criteria_delta"] = criteria_delta

        return comparison
