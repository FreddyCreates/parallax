#!/usr/bin/env python3
"""
PARALLAX SDK — Tokenomics Measurement & Benchmarking Engine
=============================================================
Implements the Measurement and Benchmarking Framework (Section 15) as a
deployable runtime module.  Provides:

  1. Token Value Function (TV)
  2. Cognitive Return Per Token (CRPT)
  3. Salience Allocation Engine
  4. Compression Efficiency Metrics (CE / CEF)
  5. Benchmark Scoring (Tokenomic vs Non-Tokenomic)
  6. Runtime Measurement Loop

Designed for internal system self-evaluation, external API exposure,
and integration with the Motoko backend via canister calls.

Author: PARALLAX Research Division
License: PARALLAX Sovereign License
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

from .constants import PHI, PHI_INV, PHI_INV_2, PHI_INV_3


# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS
# ═══════════════════════════════════════════════════════════════════════════════


class TaskClass(Enum):
    """Benchmark task classes from Section 15.5."""
    INVOICE_EXECUTION = "invoice_execution"
    ESTIMATING = "estimating"
    CASHFLOW_DECISION = "cashflow_decision"
    PROPOSAL_GENERATION = "proposal_generation"
    RESEARCH_SYNTHESIS = "research_synthesis"
    ARCHITECTURE_DESIGN = "architecture_design"
    RED_TEAM_REVIEW = "red_team_review"
    MEMORY_CONSOLIDATION = "memory_consolidation"


class TaskRisk(Enum):
    """Risk classification for token budget allocation."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


# ═══════════════════════════════════════════════════════════════════════════════
# DATA MODELS
# ═══════════════════════════════════════════════════════════════════════════════


@dataclass
class TokenValueWeights:
    """Task-specific weighting coefficients for Token Value Function.

    Weights use phi-derived defaults but can be overridden per task.
    """
    w_decision: float = PHI_INV       # 0.618
    w_action: float = PHI_INV         # 0.618
    w_risk: float = PHI_INV_2         # 0.382
    w_compression: float = PHI_INV_3  # 0.236
    w_memory: float = PHI_INV_3       # 0.236
    w_noise: float = PHI_INV          # 0.618 (penalty weight)


@dataclass
class TokenValueScore:
    """Result of the Token Value Function for a single token or response."""
    decision_quality: float     # D_t: [0, 5]
    action_usefulness: float    # A_t: [0, 5]
    risk_reduction: float       # R_t: [0, 5]
    compression_contribution: float  # C_t: [0, 5]
    memory_reuse_value: float   # M_t: [0, 5]
    noise_waste: float          # N_t: [0, 5]
    token_value: float          # TV(t) computed result
    weights: TokenValueWeights = field(default_factory=TokenValueWeights)


@dataclass
class CognitiveReturnScore:
    """Cognitive Return scored across five categories (0-5 each)."""
    decision_quality: float = 0.0   # DQ
    actionability: float = 0.0      # ACT
    risk_control: float = 0.0       # RISK
    reuse_value: float = 0.0        # REUSE
    learning_gain: float = 0.0      # LEARN

    @property
    def total(self) -> float:
        """CR = DQ + ACT + RISK + REUSE + LEARN"""
        return (
            self.decision_quality
            + self.actionability
            + self.risk_control
            + self.reuse_value
            + self.learning_gain
        )


@dataclass
class CRPTResult:
    """Cognitive Return Per Token measurement."""
    cognitive_return: float
    prompt_tokens: int
    output_tokens: int
    total_tokens: int
    crpt: float  # Cognitive Return / Total Tokens


@dataclass
class SalienceItem:
    """A single information unit scored for salience-based budget allocation."""
    item_id: str
    label: str
    urgency: float = 0.0          # U_i: [0, 1]
    risk: float = 0.0             # R_i: [0, 1]
    mission_relevance: float = 0.0  # M_i: [0, 1]
    time_sensitivity: float = 0.0   # T_i: [0, 1]
    novelty: float = 0.0          # N_i: [0, 1]
    known_context: float = 0.0    # K_i: [0, 1] — penalty for already known


@dataclass
class SalienceWeights:
    """Task-specific weights for salience scoring (Greek letter coefficients)."""
    alpha: float = PHI_INV       # urgency
    beta: float = PHI_INV        # risk
    gamma: float = PHI_INV_2     # mission relevance
    delta: float = PHI_INV_2     # time sensitivity
    epsilon: float = PHI_INV_3   # novelty
    zeta: float = PHI_INV        # known context penalty


@dataclass
class SalienceResult:
    """Result of salience scoring and budget allocation."""
    item_id: str
    label: str
    salience_score: float
    allocated_budget: int  # tokens allocated


@dataclass
class CompressionResult:
    """Result of compression efficiency measurement."""
    information_retained: float  # [0, 5]
    action_clarity: float        # [0, 5]
    risk_preserved: float        # [0, 5]
    output_tokens: int
    ce: float   # MeaningPreserved / TokensUsed (simplified)
    cef: float  # (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens


@dataclass
class BenchmarkScore:
    """Complete benchmark score for a single task."""
    task_class: TaskClass
    decision_quality: float = 0.0
    actionability: float = 0.0
    risk_control: float = 0.0
    reuse_value: float = 0.0
    accuracy: float = 0.0
    waste: float = 0.0
    tokens_used: int = 0

    @property
    def score(self) -> float:
        """Score = DQ + ACT + RISK + REUSE + ACCURACY - WASTE"""
        return (
            self.decision_quality
            + self.actionability
            + self.risk_control
            + self.reuse_value
            + self.accuracy
            - self.waste
        )

    @property
    def score_per_token(self) -> float:
        """Score / Tokens"""
        if self.tokens_used == 0:
            return 0.0
        return self.score / self.tokens_used


@dataclass
class TokenomicGainResult:
    """Comparison result between tokenomic and non-tokenomic systems."""
    score_a: float        # Non-tokenomic score
    tokens_a: int         # Non-tokenomic tokens
    score_b: float        # Tokenomic score
    tokens_b: int         # Tokenomic tokens
    spt_a: float          # Score per token A
    spt_b: float          # Score per token B
    tokenomic_gain: float  # SPT_B - SPT_A
    is_superior: bool      # True if tokenomic system wins


@dataclass
class MeasurementLoopResult:
    """Output of a single pass through the runtime measurement loop."""
    task_class: TaskClass
    risk_level: TaskRisk
    salience_results: list[SalienceResult]
    total_budget: int
    cognitive_return: CRPTResult
    compression: CompressionResult
    wasted_tokens: int
    reusable_rules_extracted: int
    timestamp_ns: int


# ═══════════════════════════════════════════════════════════════════════════════
# 15.1 TOKEN VALUE FUNCTION
# ═══════════════════════════════════════════════════════════════════════════════


def compute_token_value(
    decision_quality: float,
    action_usefulness: float,
    risk_reduction: float,
    compression_contribution: float,
    memory_reuse_value: float,
    noise_waste: float,
    weights: Optional[TokenValueWeights] = None,
) -> TokenValueScore:
    """
    Compute Token Value: TV(t) = w_d*D + w_a*A + w_r*R + w_c*C + w_m*M - w_n*N

    Each input is scored on [0, 5]. The result is the weighted combination.
    Positive TV means the token contributes value; negative means waste.

    Args:
        decision_quality: Did this token improve a decision? [0, 5]
        action_usefulness: Does this token enable action? [0, 5]
        risk_reduction: Does this token reduce risk? [0, 5]
        compression_contribution: Does this token compress knowledge? [0, 5]
        memory_reuse_value: Does this token create reusable memory? [0, 5]
        noise_waste: Is this token redundant/filler/noise? [0, 5]
        weights: Task-specific weighting coefficients.

    Returns:
        TokenValueScore with computed TV.
    """
    if weights is None:
        weights = TokenValueWeights()

    tv = (
        weights.w_decision * decision_quality
        + weights.w_action * action_usefulness
        + weights.w_risk * risk_reduction
        + weights.w_compression * compression_contribution
        + weights.w_memory * memory_reuse_value
        - weights.w_noise * noise_waste
    )

    return TokenValueScore(
        decision_quality=decision_quality,
        action_usefulness=action_usefulness,
        risk_reduction=risk_reduction,
        compression_contribution=compression_contribution,
        memory_reuse_value=memory_reuse_value,
        noise_waste=noise_waste,
        token_value=tv,
        weights=weights,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# 15.2 COGNITIVE RETURN PER TOKEN
# ═══════════════════════════════════════════════════════════════════════════════


def compute_crpt(
    score: CognitiveReturnScore,
    prompt_tokens: int,
    output_tokens: int,
) -> CRPTResult:
    """
    Compute Cognitive Return Per Token.

    CRPT = CR / (Prompt Tokens + Output Tokens)

    This metric rewards systems that produce compact but useful outputs.
    It penalizes long outputs that don't improve action or judgment.

    Args:
        score: The cognitive return scored across 5 categories.
        prompt_tokens: Number of prompt/input tokens consumed.
        output_tokens: Number of output tokens generated.

    Returns:
        CRPTResult with the computed metric.
    """
    total_tokens = prompt_tokens + output_tokens
    crpt = score.total / total_tokens if total_tokens > 0 else 0.0

    return CRPTResult(
        cognitive_return=score.total,
        prompt_tokens=prompt_tokens,
        output_tokens=output_tokens,
        total_tokens=total_tokens,
        crpt=crpt,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# 15.3 SALIENCE ALLOCATION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════


class SalienceEngine:
    """
    Salience-based token budget allocator.

    Ranks information units by urgency, risk, mission relevance, novelty,
    time sensitivity, and penalizes already-known context. Then allocates
    the total token budget proportionally to salience scores.

    Usage:
        engine = SalienceEngine(total_budget=2000)
        engine.add_item(SalienceItem(
            item_id="critical_risk",
            label="Cash flow gap detected",
            urgency=0.9,
            risk=0.95,
            mission_relevance=0.8,
            time_sensitivity=0.7,
            novelty=0.6,
            known_context=0.1,
        ))
        engine.add_item(SalienceItem(
            item_id="fyi_info",
            label="General market update",
            urgency=0.2,
            risk=0.1,
            mission_relevance=0.3,
            time_sensitivity=0.1,
            novelty=0.4,
            known_context=0.7,
        ))
        results = engine.allocate()
    """

    def __init__(
        self,
        total_budget: int = 2000,
        weights: Optional[SalienceWeights] = None,
    ):
        self._total_budget = total_budget
        self._weights = weights or SalienceWeights()
        self._items: list[SalienceItem] = []

    @property
    def total_budget(self) -> int:
        return self._total_budget

    @total_budget.setter
    def total_budget(self, value: int) -> None:
        self._total_budget = max(0, value)

    @property
    def item_count(self) -> int:
        return len(self._items)

    def add_item(self, item: SalienceItem) -> None:
        """Add an information unit to be scored and allocated budget."""
        self._items.append(item)

    def clear(self) -> None:
        """Clear all items."""
        self._items.clear()

    def score_item(self, item: SalienceItem) -> float:
        """
        Compute salience score for a single item.

        S_i = α*U_i + β*R_i + γ*M_i + δ*T_i + ε*N_i - ζ*K_i
        """
        w = self._weights
        return (
            w.alpha * item.urgency
            + w.beta * item.risk
            + w.gamma * item.mission_relevance
            + w.delta * item.time_sensitivity
            + w.epsilon * item.novelty
            - w.zeta * item.known_context
        )

    def allocate(self) -> list[SalienceResult]:
        """
        Score all items and allocate token budget proportionally.

        B_i = B_total * (S_i / ΣS)

        Items with negative salience receive zero budget.

        Returns:
            List of SalienceResult ordered by salience (descending).
        """
        if not self._items:
            return []

        # Score all items
        scored: list[tuple[SalienceItem, float]] = []
        for item in self._items:
            s = self.score_item(item)
            scored.append((item, max(0.0, s)))  # Floor at 0

        # Total salience
        total_salience = sum(s for _, s in scored)

        # Allocate budgets
        results: list[SalienceResult] = []
        for item, salience in scored:
            if total_salience > 0:
                budget = int(self._total_budget * (salience / total_salience))
            else:
                budget = 0
            results.append(SalienceResult(
                item_id=item.item_id,
                label=item.label,
                salience_score=salience,
                allocated_budget=budget,
            ))

        # Sort by salience descending
        results.sort(key=lambda r: r.salience_score, reverse=True)
        return results


# ═══════════════════════════════════════════════════════════════════════════════
# 15.4 COMPRESSION EFFICIENCY METRICS
# ═══════════════════════════════════════════════════════════════════════════════


def compute_compression_efficiency(
    information_retained: float,
    action_clarity: float,
    risk_preserved: float,
    output_tokens: int,
) -> CompressionResult:
    """
    Compute Compression Efficiency.

    CEF = (InformationRetained + ActionClarity + RiskPreserved) / OutputTokens

    Good compression reduces surface length while preserving correct action.
    Bad compression merely deletes context and increases operational risk.

    Args:
        information_retained: Preservation of task-relevant content [0, 5]
        action_clarity: Clarity of next step or decision [0, 5]
        risk_preserved: Preservation of uncertainty/constraints [0, 5]
        output_tokens: Total output tokens used.

    Returns:
        CompressionResult with CE and CEF scores.
    """
    meaning_preserved = (information_retained + action_clarity + risk_preserved) / 3.0
    ce = meaning_preserved / output_tokens if output_tokens > 0 else 0.0
    cef = (information_retained + action_clarity + risk_preserved) / output_tokens if output_tokens > 0 else 0.0

    return CompressionResult(
        information_retained=information_retained,
        action_clarity=action_clarity,
        risk_preserved=risk_preserved,
        output_tokens=output_tokens,
        ce=ce,
        cef=cef,
    )


# ═══════════════════════════════════════════════════════════════════════════════
# 15.5 BENCHMARK SCORING
# ═══════════════════════════════════════════════════════════════════════════════


def compute_tokenomic_gain(
    score_a: BenchmarkScore,
    score_b: BenchmarkScore,
) -> TokenomicGainResult:
    """
    Compute Tokenomic Gain between a baseline system (A) and tokenomic system (B).

    TokenomicGain = Score_B/Tokens_B - Score_A/Tokens_A

    A tokenomic system is superior when it produces equal or higher task score
    with fewer tokens, or significantly higher task score with justified increase.

    Args:
        score_a: Benchmark score from non-tokenomic baseline system.
        score_b: Benchmark score from tokenomic system.

    Returns:
        TokenomicGainResult with comparison metrics.
    """
    spt_a = score_a.score_per_token
    spt_b = score_b.score_per_token
    gain = spt_b - spt_a

    return TokenomicGainResult(
        score_a=score_a.score,
        tokens_a=score_a.tokens_used,
        score_b=score_b.score,
        tokens_b=score_b.tokens_used,
        spt_a=spt_a,
        spt_b=spt_b,
        tokenomic_gain=gain,
        is_superior=(gain > 0),
    )


# ═══════════════════════════════════════════════════════════════════════════════
# 15.6 RUNTIME MEASUREMENT LOOP
# ═══════════════════════════════════════════════════════════════════════════════


class TokenomicsRuntime:
    """
    Runtime Measurement Loop — the deployable tokenomic evaluation engine.

    Implements the 11-step runtime loop:
      1. Classify the task
      2. Estimate task risk and complexity
      3. Rank salience targets
      4. Allocate token budget
      5. Recruit only necessary modules/agents
      6. Generate the response/artifact
      7. Audit compression quality
      8. Score cognitive return
      9. Detect wasted tokens
     10. Extract reusable rules/memory
     11. Update future token allocation policy

    This creates a feedback loop where every interaction improves future efficiency.

    Usage:
        runtime = TokenomicsRuntime()

        # Configure for a task
        runtime.classify_task(TaskClass.INVOICE_EXECUTION, TaskRisk.HIGH)
        runtime.set_budget(1500)

        # Add salience items
        runtime.add_salience_item(SalienceItem(...))

        # After response generation, audit
        result = runtime.audit(
            prompt_tokens=500,
            output_tokens=800,
            cognitive_return=CognitiveReturnScore(dq=4, act=4, risk=3, reuse=2, learn=1),
            compression_scores=(4.0, 4.5, 3.5),
            wasted_tokens=50,
            reusable_rules=2,
        )
    """

    def __init__(self):
        self._task_class: Optional[TaskClass] = None
        self._risk_level: TaskRisk = TaskRisk.MEDIUM
        self._salience_engine = SalienceEngine()
        self._history: list[MeasurementLoopResult] = []
        self._cumulative_waste: int = 0
        self._cumulative_reuse: int = 0
        self._budget_adjustment: float = 1.0  # Adaptive budget multiplier

    @property
    def task_class(self) -> Optional[TaskClass]:
        return self._task_class

    @property
    def risk_level(self) -> TaskRisk:
        return self._risk_level

    @property
    def history_count(self) -> int:
        return len(self._history)

    @property
    def budget_adjustment(self) -> float:
        """Current adaptive budget multiplier (updated by feedback loop)."""
        return self._budget_adjustment

    def classify_task(self, task_class: TaskClass, risk: TaskRisk) -> None:
        """Step 1-2: Classify task and estimate risk."""
        self._task_class = task_class
        self._risk_level = risk

        # Adjust budget based on risk (phi-scaled)
        risk_multipliers = {
            TaskRisk.LOW: PHI_INV_3,       # 0.236 — tight budget
            TaskRisk.MEDIUM: PHI_INV,      # 0.618 — moderate
            TaskRisk.HIGH: 1.0,            # full budget
            TaskRisk.CRITICAL: PHI,        # 1.618 — expanded budget
        }
        self._budget_adjustment = risk_multipliers[risk]

    def set_budget(self, total_tokens: int) -> None:
        """Step 4: Set the total token budget (adjusted by risk)."""
        adjusted = int(total_tokens * self._budget_adjustment)
        self._salience_engine.total_budget = adjusted

    def add_salience_item(self, item: SalienceItem) -> None:
        """Step 3: Add items for salience ranking."""
        self._salience_engine.add_item(item)

    def allocate(self) -> list[SalienceResult]:
        """Step 3-4: Rank salience and allocate budget."""
        return self._salience_engine.allocate()

    def audit(
        self,
        prompt_tokens: int,
        output_tokens: int,
        cognitive_return: CognitiveReturnScore,
        compression_scores: tuple[float, float, float],
        wasted_tokens: int = 0,
        reusable_rules: int = 0,
    ) -> MeasurementLoopResult:
        """
        Steps 7-11: Audit the response, score, detect waste, extract reuse.

        Args:
            prompt_tokens: Input tokens consumed.
            output_tokens: Output tokens generated.
            cognitive_return: Scored cognitive return (5 categories).
            compression_scores: (info_retained, action_clarity, risk_preserved)
            wasted_tokens: Estimated wasted/redundant tokens.
            reusable_rules: Number of reusable rules/templates extracted.

        Returns:
            MeasurementLoopResult capturing the full audit.
        """
        if self._task_class is None:
            raise ValueError("Task not classified. Call classify_task() first.")

        # Step 7: Audit compression
        info_ret, action_clar, risk_pres = compression_scores
        compression = compute_compression_efficiency(
            information_retained=info_ret,
            action_clarity=action_clar,
            risk_preserved=risk_pres,
            output_tokens=output_tokens,
        )

        # Step 8: Score cognitive return
        crpt = compute_crpt(cognitive_return, prompt_tokens, output_tokens)

        # Step 9: Detect waste
        self._cumulative_waste += wasted_tokens

        # Step 10: Extract reuse
        self._cumulative_reuse += reusable_rules

        # Step 11: Update future allocation policy
        # If high waste, tighten future budgets; if high reuse, reward
        if crpt.crpt > 0:
            waste_ratio = wasted_tokens / max(1, output_tokens)
            # Phi-dampened adjustment
            self._budget_adjustment *= (1.0 - waste_ratio * PHI_INV_3)
            if reusable_rules > 0:
                # Reward reuse with slight budget increase for future complexity
                self._budget_adjustment *= (1.0 + reusable_rules * PHI_INV_3 * 0.1)

        # Get salience allocation
        salience_results = self._salience_engine.allocate()

        result = MeasurementLoopResult(
            task_class=self._task_class,
            risk_level=self._risk_level,
            salience_results=salience_results,
            total_budget=self._salience_engine.total_budget,
            cognitive_return=crpt,
            compression=compression,
            wasted_tokens=wasted_tokens,
            reusable_rules_extracted=reusable_rules,
            timestamp_ns=time.time_ns(),
        )

        self._history.append(result)
        return result

    def reset(self) -> None:
        """Reset for a new task (preserves history and adaptive state)."""
        self._task_class = None
        self._risk_level = TaskRisk.MEDIUM
        self._salience_engine.clear()

    def get_stats(self) -> dict:
        """Return cumulative runtime statistics."""
        if not self._history:
            return {
                "interactions": 0,
                "avg_crpt": 0.0,
                "cumulative_waste": 0,
                "cumulative_reuse": 0,
                "budget_adjustment": self._budget_adjustment,
            }

        avg_crpt = sum(h.cognitive_return.crpt for h in self._history) / len(self._history)
        avg_cef = sum(h.compression.cef for h in self._history) / len(self._history)

        return {
            "interactions": len(self._history),
            "avg_crpt": avg_crpt,
            "avg_cef": avg_cef,
            "cumulative_waste": self._cumulative_waste,
            "cumulative_reuse": self._cumulative_reuse,
            "budget_adjustment": self._budget_adjustment,
            "total_tokens_spent": sum(
                h.cognitive_return.total_tokens for h in self._history
            ),
        }
