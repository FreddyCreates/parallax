"""Cognitive Return Metrics (Section 15.2).

The primary system-level metric is **Cognitive Return Per Token** (CRPT):

    CRPT = Cognitive Return / (Prompt Tokens + Output Tokens)

Cognitive Return is scored across five categories:

    CR = DQ + ACT + RISK + REUSE + LEARN

Each category is evaluated on a 0–5 scale:

    Metric              Evaluation Question
    ──────────────────  ───────────────────────────────────────────────────────
    Decision Quality    Did the response improve the actual decision?
    Actionability       Can the user or system act immediately?
    Risk Control        Did the response identify or reduce meaningful failure modes?
    Reuse Value         Did the response create a reusable rule, template, memory,
                        artifact, or procedure?
    Learning Gain       Did the interaction improve future system behavior?
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CognitiveReturnScore:
    """Individual cognitive return measurement for a single interaction.

    Attributes:
        decision_quality: 0–5 rating — Did the response improve the decision?
        actionability: 0–5 rating — Can the user/system act immediately?
        risk_control: 0–5 rating — Were failure modes identified or mitigated?
        reuse_value: 0–5 rating — Was a reusable artifact produced?
        learning_gain: 0–5 rating — Did the interaction improve future behavior?
        prompt_tokens: Number of tokens in the prompt.
        output_tokens: Number of tokens in the output.
    """

    decision_quality: float = 0.0
    actionability: float = 0.0
    risk_control: float = 0.0
    reuse_value: float = 0.0
    learning_gain: float = 0.0
    prompt_tokens: int = 0
    output_tokens: int = 0

    @property
    def cognitive_return(self) -> float:
        """CR = DQ + ACT + RISK + REUSE + LEARN (max 25)."""
        return (
            self.decision_quality
            + self.actionability
            + self.risk_control
            + self.reuse_value
            + self.learning_gain
        )

    @property
    def total_tokens(self) -> int:
        """Total tokens consumed (prompt + output)."""
        return self.prompt_tokens + self.output_tokens

    @property
    def crpt(self) -> float:
        """Cognitive Return Per Token.

        Returns 0.0 if total_tokens is zero to avoid division errors.
        """
        total = self.total_tokens
        if total == 0:
            return 0.0
        return self.cognitive_return / total


class CognitiveReturnMetrics:
    """Accumulator for measuring Cognitive Return Per Token over many interactions.

    Usage::

        metrics = CognitiveReturnMetrics()
        metrics.record(
            decision_quality=4,
            actionability=5,
            risk_control=3,
            reuse_value=4,
            learning_gain=2,
            prompt_tokens=500,
            output_tokens=350,
        )
        print(metrics.average_crpt)
    """

    def __init__(self) -> None:
        self._scores: list[CognitiveReturnScore] = []

    def record(
        self,
        *,
        decision_quality: float = 0.0,
        actionability: float = 0.0,
        risk_control: float = 0.0,
        reuse_value: float = 0.0,
        learning_gain: float = 0.0,
        prompt_tokens: int = 0,
        output_tokens: int = 0,
    ) -> CognitiveReturnScore:
        """Record a single interaction's cognitive return.

        Returns the computed :class:`CognitiveReturnScore`.
        """
        score = CognitiveReturnScore(
            decision_quality=decision_quality,
            actionability=actionability,
            risk_control=risk_control,
            reuse_value=reuse_value,
            learning_gain=learning_gain,
            prompt_tokens=prompt_tokens,
            output_tokens=output_tokens,
        )
        self._scores.append(score)
        return score

    @property
    def scores(self) -> list[CognitiveReturnScore]:
        """All recorded scores."""
        return list(self._scores)

    @property
    def total_cognitive_return(self) -> float:
        """Sum of cognitive return across all recorded interactions."""
        return sum(s.cognitive_return for s in self._scores)

    @property
    def total_tokens(self) -> int:
        """Total tokens consumed across all interactions."""
        return sum(s.total_tokens for s in self._scores)

    @property
    def average_crpt(self) -> float:
        """Aggregate CRPT: total cognitive return / total tokens."""
        total = self.total_tokens
        if total == 0:
            return 0.0
        return self.total_cognitive_return / total

    @property
    def average_cognitive_return(self) -> float:
        """Mean cognitive return per interaction."""
        if not self._scores:
            return 0.0
        return self.total_cognitive_return / len(self._scores)

    def summary(self) -> dict[str, float | int]:
        """Return a summary dict suitable for logging or display."""
        return {
            "interactions": len(self._scores),
            "total_tokens": self.total_tokens,
            "total_cognitive_return": round(self.total_cognitive_return, 4),
            "average_crpt": round(self.average_crpt, 6),
            "average_cognitive_return": round(self.average_cognitive_return, 4),
        }
