"""Salience Allocation Equations (Section 15.3).

Tokenomic systems allocate attention *before* generating output. A Salience Engine
ranks what deserves token budget based on urgency, risk, mission relevance, novelty,
time sensitivity, and whether the context is already known.

Salience score for each information unit *i*:

    S_i = α·U_i + β·R_i + γ·M_i + δ·T_i + ε·N_i − ζ·K_i

Token budget is allocated proportionally:

    B_i = B_total · (S_i / ΣS)

This prevents low-value context from consuming high-value token space.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class SalienceWeights:
    """Task-specific weighting coefficients for salience scoring.

    Attributes:
        urgency: α — weight for urgency.
        risk: β — weight for risk or consequence.
        mission: γ — weight for mission relevance.
        time: δ — weight for time sensitivity.
        novelty: ε — weight for novelty or uncertainty.
        known: ζ — penalty for already-settled context.
    """

    urgency: float = 1.0
    risk: float = 1.0
    mission: float = 1.0
    time: float = 1.0
    novelty: float = 1.0
    known: float = 1.0


@dataclass(frozen=True)
class SalienceItem:
    """A single information unit to be ranked by salience.

    Attributes:
        label: Human-readable identifier for this item.
        urgency: U_i — how urgent is this item (0–5).
        risk: R_i — risk or consequence if ignored (0–5).
        mission_relevance: M_i — relevance to current mission (0–5).
        time_sensitivity: T_i — time sensitivity (0–5).
        novelty: N_i — novelty or uncertainty (0–5).
        known: K_i — degree to which this is already known/settled (0–5).
    """

    label: str = ""
    urgency: float = 0.0
    risk: float = 0.0
    mission_relevance: float = 0.0
    time_sensitivity: float = 0.0
    novelty: float = 0.0
    known: float = 0.0


@dataclass(frozen=True)
class SalienceScore:
    """Computed salience score for an information unit.

    Attributes:
        item: The original item that was scored.
        score: The computed salience score S_i.
        budget_fraction: Proportional share of total budget (0–1).
        allocated_tokens: Actual token budget allocated.
    """

    item: SalienceItem
    score: float = 0.0
    budget_fraction: float = 0.0
    allocated_tokens: int = 0


class SalienceEngine:
    """Rank information units and allocate token budget proportionally.

    Parameters:
        weights: Optional custom weighting coefficients.
        total_budget: Total available output token budget.

    Usage::

        engine = SalienceEngine(total_budget=1000)
        items = [
            SalienceItem(label="critical-risk", urgency=5, risk=5, novelty=4),
            SalienceItem(label="known-context", known=5),
        ]
        scores = engine.allocate(items)
        # scores[0].allocated_tokens >> scores[1].allocated_tokens
    """

    def __init__(
        self,
        weights: SalienceWeights | None = None,
        total_budget: int = 1000,
    ) -> None:
        self.weights = weights or SalienceWeights()
        self.total_budget = total_budget

    def score_item(self, item: SalienceItem) -> float:
        """Compute raw salience score for a single item.

        S_i = α·U_i + β·R_i + γ·M_i + δ·T_i + ε·N_i − ζ·K_i
        """
        w = self.weights
        return (
            w.urgency * item.urgency
            + w.risk * item.risk
            + w.mission * item.mission_relevance
            + w.time * item.time_sensitivity
            + w.novelty * item.novelty
            - w.known * item.known
        )

    def allocate(self, items: list[SalienceItem]) -> list[SalienceScore]:
        """Score all items and allocate token budget proportionally.

        B_i = B_total · (S_i / ΣS)

        Items with non-positive salience receive zero budget.

        Returns:
            List of :class:`SalienceScore` in same order as input.
        """
        if not items:
            return []

        raw_scores = [self.score_item(item) for item in items]

        # Only positive salience items get budget
        positive_scores = [max(0.0, s) for s in raw_scores]
        total_salience = sum(positive_scores)

        results: list[SalienceScore] = []
        for item, raw, positive in zip(items, raw_scores, positive_scores):
            if total_salience > 0:
                fraction = positive / total_salience
            else:
                fraction = 0.0
            allocated = int(round(self.total_budget * fraction))
            results.append(
                SalienceScore(
                    item=item,
                    score=raw,
                    budget_fraction=fraction,
                    allocated_tokens=allocated,
                )
            )
        return results

    def rank(self, items: list[SalienceItem]) -> list[SalienceScore]:
        """Score and return items sorted by descending salience."""
        scores = self.allocate(items)
        return sorted(scores, key=lambda s: s.score, reverse=True)
