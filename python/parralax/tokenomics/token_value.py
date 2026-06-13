"""Token Value Function (Section 15.1).

Evaluates each token's contribution to cognitive output using a weighted
multi-factor model:

    TV(t) = w_d·D_t + w_a·A_t + w_r·R_t + w_c·C_t + w_m·M_t − w_n·N_t

Simplified operational formula:

    TV = DQ + ACT + RISK + REUSE + LEARN − WASTE

A token has positive value when it improves decision quality, enables action,
reduces risk, compresses useful knowledge, or creates reusable memory.
A token has negative value when it repeats known context, adds filler, increases
ambiguity, or consumes attention without improving the outcome.

The guiding principle: **Do not optimize for fewer tokens. Optimize for
higher-value tokens.**
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class TokenValueWeights:
    """Task-specific weighting coefficients for the Token Value Function.

    Each weight scales the corresponding factor's contribution to the overall
    token value score.  All weights default to ``1.0`` (equal weighting).
    """

    decision: float = 1.0
    action: float = 1.0
    risk: float = 1.0
    compression: float = 1.0
    memory: float = 1.0
    noise: float = 1.0


@dataclass(frozen=True)
class TokenValueScore:
    """Score produced by the Token Value Function for a single token or span.

    Attributes:
        decision_quality: Improvement to the actual decision (D_t).
        actionability: Degree to which the user/system can act immediately (A_t).
        risk_reduction: Meaningful failure modes identified or mitigated (R_t).
        compression: Useful knowledge compressed or distilled (C_t).
        memory_reuse: Reusable rule, template, memory, artifact, or procedure (M_t).
        noise: Redundancy, filler, or irrelevant output (N_t).
        weights: Coefficients used for the weighted sum.
    """

    decision_quality: float = 0.0
    actionability: float = 0.0
    risk_reduction: float = 0.0
    compression: float = 0.0
    memory_reuse: float = 0.0
    noise: float = 0.0
    weights: TokenValueWeights = field(default_factory=TokenValueWeights)

    @property
    def value(self) -> float:
        """Compute the weighted token value.

        TV(t) = w_d·D + w_a·A + w_r·R + w_c·C + w_m·M − w_n·N
        """
        w = self.weights
        return (
            w.decision * self.decision_quality
            + w.action * self.actionability
            + w.risk * self.risk_reduction
            + w.compression * self.compression
            + w.memory * self.memory_reuse
            - w.noise * self.noise
        )

    @property
    def is_positive(self) -> bool:
        """Return ``True`` if this token contributes net-positive value."""
        return self.value > 0.0


class TokenValueFunction:
    """Compute Token Value scores for token spans.

    Parameters:
        weights: Optional custom weighting coefficients.  Defaults to equal
            weighting across all factors.
    """

    def __init__(self, weights: TokenValueWeights | None = None) -> None:
        self.weights = weights or TokenValueWeights()

    def score(
        self,
        *,
        decision_quality: float = 0.0,
        actionability: float = 0.0,
        risk_reduction: float = 0.0,
        compression: float = 0.0,
        memory_reuse: float = 0.0,
        noise: float = 0.0,
    ) -> TokenValueScore:
        """Score a token or span across all value dimensions.

        Each factor is rated on a ``0–5`` scale.

        Returns:
            A :class:`TokenValueScore` with the computed weighted value.
        """
        return TokenValueScore(
            decision_quality=decision_quality,
            actionability=actionability,
            risk_reduction=risk_reduction,
            compression=compression,
            memory_reuse=memory_reuse,
            noise=noise,
            weights=self.weights,
        )

    def score_batch(
        self, scores: list[dict[str, float]]
    ) -> list[TokenValueScore]:
        """Score multiple token spans at once.

        Parameters:
            scores: List of dicts, each mapping factor names to float ratings.

        Returns:
            Corresponding list of :class:`TokenValueScore` instances.
        """
        return [self.score(**s) for s in scores]

    def aggregate(self, scores: list[TokenValueScore]) -> float:
        """Return the mean token value across a list of scores."""
        if not scores:
            return 0.0
        return sum(s.value for s in scores) / len(scores)
