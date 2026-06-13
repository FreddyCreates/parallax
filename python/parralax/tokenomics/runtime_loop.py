"""Runtime Measurement Loop (Section 15.6).

A deployable Tokenomic AI System evaluates itself through an 11-step runtime
measurement loop:

    1. Classify the task.
    2. Estimate task risk and complexity.
    3. Rank salience targets.
    4. Allocate token budget.
    5. Recruit only necessary modules or agents.
    6. Generate the response or artifact.
    7. Audit compression quality.
    8. Score cognitive return.
    9. Detect wasted tokens.
   10. Extract reusable rules or memory.
   11. Update future token allocation policy.

This creates a feedback loop where every interaction improves future efficiency.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any

from parralax.tokenomics.cognitive_return import CognitiveReturnMetrics, CognitiveReturnScore
from parralax.tokenomics.compression import CompressionAuditor, CompressionScore
from parralax.tokenomics.salience import SalienceEngine, SalienceItem, SalienceScore


class TaskClass(str, Enum):
    """Standard task classes for tokenomic benchmarking (Section 15.5)."""

    INVOICE_EXECUTION = "invoice_execution"
    ESTIMATING = "estimating"
    CASHFLOW_DECISION = "cashflow_decision"
    PROPOSAL_GENERATION = "proposal_generation"
    RESEARCH_SYNTHESIS = "research_synthesis"
    ARCHITECTURE_DESIGN = "architecture_design"
    RED_TEAM_REVIEW = "red_team_review"
    MEMORY_CONSOLIDATION = "memory_consolidation"
    GENERAL = "general"


@dataclass
class TaskContext:
    """Context for a single task entering the runtime loop.

    Attributes:
        task_class: The classification of this task.
        risk_level: Estimated risk (0–5).
        complexity: Estimated complexity (0–5).
        salience_items: Information units to rank for attention.
        total_budget: Total available token budget.
        modules_available: List of available module/agent names.
        metadata: Arbitrary metadata.
    """

    task_class: TaskClass = TaskClass.GENERAL
    risk_level: float = 0.0
    complexity: float = 0.0
    salience_items: list[SalienceItem] = field(default_factory=list)
    total_budget: int = 1000
    modules_available: list[str] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class LoopResult:
    """Result of a complete runtime measurement loop iteration.

    Attributes:
        task_context: The input task context.
        salience_scores: Ranked salience allocations.
        recruited_modules: Modules selected for this task.
        compression_score: Compression audit result (if applicable).
        cognitive_return_score: Cognitive return measurement.
        wasted_tokens: Estimated number of wasted tokens detected.
        extracted_rules: Reusable rules/memory extracted from this interaction.
        policy_update: Suggested updates to future token allocation policy.
    """

    task_context: TaskContext
    salience_scores: list[SalienceScore] = field(default_factory=list)
    recruited_modules: list[str] = field(default_factory=list)
    compression_score: CompressionScore | None = None
    cognitive_return_score: CognitiveReturnScore | None = None
    wasted_tokens: int = 0
    extracted_rules: list[str] = field(default_factory=list)
    policy_update: dict[str, Any] = field(default_factory=dict)

    @property
    def efficiency_score(self) -> float:
        """Overall efficiency: CRPT minus waste penalty.

        Returns 0.0 if cognitive return is not measured.
        """
        if self.cognitive_return_score is None:
            return 0.0
        crpt = self.cognitive_return_score.crpt
        total = self.cognitive_return_score.total_tokens
        if total == 0:
            return 0.0
        waste_fraction = self.wasted_tokens / total
        return crpt * (1.0 - waste_fraction)


class RuntimeMeasurementLoop:
    """Orchestrates the 11-step tokenomic runtime measurement loop.

    This class coordinates salience allocation, module recruitment, compression
    auditing, cognitive return scoring, waste detection, rule extraction, and
    policy updating across interactions.

    Usage::

        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(
            task_class=TaskClass.CASHFLOW_DECISION,
            risk_level=4,
            complexity=3,
            salience_items=[...],
            total_budget=800,
        )
        result = loop.execute(ctx, cognitive_scores={...}, compression_scores={...})
        print(result.efficiency_score)
        print(loop.policy)
    """

    def __init__(self) -> None:
        self._salience_engine = SalienceEngine()
        self._compression_auditor = CompressionAuditor()
        self._cognitive_metrics = CognitiveReturnMetrics()
        self._history: list[LoopResult] = []
        self._policy: dict[str, Any] = {
            "budget_multiplier": 1.0,
            "min_salience_threshold": 0.0,
            "waste_penalty_weight": 1.0,
        }
        self._extracted_rules: list[str] = []

    @property
    def history(self) -> list[LoopResult]:
        """All completed loop iterations."""
        return list(self._history)

    @property
    def policy(self) -> dict[str, Any]:
        """Current token allocation policy (evolves over time)."""
        return dict(self._policy)

    @property
    def extracted_rules(self) -> list[str]:
        """All reusable rules extracted across all interactions."""
        return list(self._extracted_rules)

    def execute(
        self,
        context: TaskContext,
        *,
        cognitive_scores: dict[str, float] | None = None,
        compression_scores: dict[str, float | int] | None = None,
        wasted_tokens: int = 0,
        extracted_rules: list[str] | None = None,
    ) -> LoopResult:
        """Execute one full iteration of the runtime measurement loop.

        Steps 1–2 are provided by the TaskContext. Steps 5–6 are external
        (the actual generation). This method handles Steps 3–4, 7–11.

        Parameters:
            context: Task classification and salience items.
            cognitive_scores: Dict with keys matching CognitiveReturnMetrics.record().
            compression_scores: Dict with keys matching CompressionAuditor.evaluate().
            wasted_tokens: Number of tokens detected as waste.
            extracted_rules: Reusable rules/memory extracted from this interaction.

        Returns:
            A :class:`LoopResult` summarizing the complete loop iteration.
        """
        # Step 3–4: Rank salience targets and allocate budget
        adjusted_budget = int(
            context.total_budget * self._policy["budget_multiplier"]
        )
        self._salience_engine = SalienceEngine(
            weights=self._salience_engine.weights,
            total_budget=adjusted_budget,
        )
        salience_scores = self._salience_engine.allocate(context.salience_items)

        # Step 5: Recruit modules based on task class and complexity
        recruited = self._recruit_modules(context)

        # Step 7: Audit compression quality
        comp_score: CompressionScore | None = None
        if compression_scores:
            comp_score = self._compression_auditor.evaluate(**compression_scores)

        # Step 8: Score cognitive return
        cr_score: CognitiveReturnScore | None = None
        if cognitive_scores:
            cr_score = self._cognitive_metrics.record(**cognitive_scores)

        # Step 9: Detect wasted tokens (provided externally)
        # Step 10: Extract reusable rules
        rules = extracted_rules or []
        self._extracted_rules.extend(rules)

        # Step 11: Update future token allocation policy
        policy_update = self._update_policy(cr_score, wasted_tokens, context)

        result = LoopResult(
            task_context=context,
            salience_scores=salience_scores,
            recruited_modules=recruited,
            compression_score=comp_score,
            cognitive_return_score=cr_score,
            wasted_tokens=wasted_tokens,
            extracted_rules=rules,
            policy_update=policy_update,
        )
        self._history.append(result)
        return result

    def _recruit_modules(self, context: TaskContext) -> list[str]:
        """Select modules based on task class, risk, and complexity (Step 5).

        Higher risk/complexity recruits more modules. Simple tasks use fewer.
        """
        if not context.modules_available:
            return []
        # Recruit proportional to risk + complexity (scaled 0–10 to 0–1)
        recruit_fraction = min(1.0, (context.risk_level + context.complexity) / 10.0)
        recruit_count = max(1, int(len(context.modules_available) * recruit_fraction))
        return context.modules_available[:recruit_count]

    def _update_policy(
        self,
        cr_score: CognitiveReturnScore | None,
        wasted_tokens: int,
        context: TaskContext,
    ) -> dict[str, Any]:
        """Adapt token allocation policy based on this iteration's results (Step 11).

        - If waste is high relative to output, reduce budget multiplier slightly.
        - If CRPT is high, maintain or increase budget multiplier.
        - Accumulate learning over time.
        """
        update: dict[str, Any] = {}

        if cr_score and cr_score.total_tokens > 0:
            waste_ratio = wasted_tokens / cr_score.total_tokens
            if waste_ratio > 0.3:
                # High waste: tighten budget
                self._policy["budget_multiplier"] = max(
                    0.5, self._policy["budget_multiplier"] - 0.05
                )
                update["action"] = "tighten_budget"
                update["waste_ratio"] = waste_ratio
            elif cr_score.crpt > 0.05:
                # Good efficiency: allow slight expansion
                self._policy["budget_multiplier"] = min(
                    2.0, self._policy["budget_multiplier"] + 0.02
                )
                update["action"] = "expand_budget"
                update["crpt"] = cr_score.crpt

        return update

    def summary(self) -> dict[str, Any]:
        """Return aggregate summary of all loop iterations."""
        return {
            "total_iterations": len(self._history),
            "policy": self.policy,
            "total_extracted_rules": len(self._extracted_rules),
            "cognitive_metrics": self._cognitive_metrics.summary(),
            "compression_metrics": self._compression_auditor.summary(),
            "average_efficiency": (
                round(
                    sum(r.efficiency_score for r in self._history) / len(self._history),
                    6,
                )
                if self._history
                else 0.0
            ),
        }
