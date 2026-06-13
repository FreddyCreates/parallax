"""Expanded actuarial strategy lifecycle models.

This module keeps the original ``StrategyMortality`` and
``StrategyLifecycleModel`` interfaces intact while extending the lifecycle
framework into a richer actuarial operating system for quantitative trading
strategies.  The implementation remains dependency-light and deterministic so it
can run inside service layers without scientific Python packages.

The expanded feature set includes:

* Weibull survival analysis for baseline mortality.
* Competing-risks failure decomposition across multiple failure causes.
* Cohort and vintage analysis for comparing generations of strategies.
* Alpha decay forecasting with mean reversion and structural break detection.
* Capacity erosion modeling driven by utilization, impact, and crowding.
* Regime-conditional mortality using a Cox-style multiplicative hazard analog.
* Rule-based clustering for lifecycle segmentation and cascade-risk analysis.
* Replacement timing and incubation pipeline optimization.
* Return attribution across alpha, beta, and factor contributions.
* Multi-dimensional health scoring and portfolio-level lifecycle construction.

The code favors interpretability over statistical sophistication.  It is meant to
provide production-safe heuristics that can be refined later with empirical
calibration, while preserving backwards compatibility with the original file.
"""

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Iterable


class StrategyState(str, Enum):
    """High-level lifecycle state for a strategy."""

    INCUBATION = "incubation"
    ACTIVE = "active"
    DEGRADING = "degrading"
    TERMINAL = "terminal"
    RETIRED = "retired"


class FailureMode(str, Enum):
    """Primary competing failure causes for strategy mortality."""

    ALPHA_DECAY = "alpha_decay"
    CAPACITY_EXHAUSTION = "capacity_exhaustion"
    REGIME_SHIFT = "regime_shift"
    CROWDING = "crowding"


class MarketRegime(str, Enum):
    """Simple market-regime taxonomy used by the lifecycle models."""

    BULL = "bull"
    BEAR = "bear"
    SIDEWAYS = "sideways"
    STRESSED = "stressed"
    RECOVERY = "recovery"


class HealthSignal(str, Enum):
    """Named health warnings surfaced by the scoring engine."""

    ALPHA_BREAK = "alpha_break"
    CROWDING = "crowding"
    CAPACITY_STRESS = "capacity_stress"
    REGIME_MISMATCH = "regime_mismatch"
    DRAWDOWN = "drawdown"
    CASCADE_RISK = "cascade_risk"
    TERMINAL_DRIFT = "terminal_drift"


@dataclass
class StrategyLifecycleMetrics:
    """Backwards-compatible lifecycle metrics returned by assessment.

    The original fields remain unchanged.  Additional optional fields provide a
    richer representation without breaking existing callers that only access the
    original attributes.
    """

    strategy_id: str
    state: StrategyState
    age_days: int
    expected_remaining_life: float
    hazard_rate: float
    survival_probability: float
    alpha_decay_rate: float
    capacity_utilization: float
    dominant_failure_mode: FailureMode | None = None
    health_score: float = 0.0
    regime: MarketRegime = MarketRegime.SIDEWAYS
    crowding_score: float = 0.0


@dataclass
class CauseSpecificHazard:
    """Cause-specific hazard component used in a competing-risks model."""

    mode: FailureMode
    instantaneous_hazard: float
    cumulative_hazard: float
    incidence_share: float
    explanatory_score: float


@dataclass
class CompetingRiskAssessment:
    """Aggregate competing-risk view for a single strategy."""

    strategy_id: str
    total_hazard: float
    survival_probability: float
    dominant_mode: FailureMode | None
    hazards: list[CauseSpecificHazard] = field(default_factory=list)
    failure_probability_30d: float = 0.0
    failure_probability_90d: float = 0.0


@dataclass
class CohortSnapshot:
    """Vintage-level cohort metrics and a coarse survival curve."""

    vintage: str
    strategy_count: int
    active_count: int
    degrading_count: int
    terminal_count: int
    average_age_days: float
    average_hazard: float
    average_health_score: float
    survival_curve: list[dict[str, float]] = field(default_factory=list)


@dataclass
class CohortComparison:
    """Comparison between two generations of strategies."""

    source_vintage: str
    target_vintage: str
    survival_advantage: float
    hazard_gap: float
    health_gap: float
    commentary: str


@dataclass
class AlphaForecast:
    """Alpha forecast and diagnostics for a strategy."""

    strategy_id: str
    current_alpha: float
    expected_alpha_30d: float
    expected_alpha_90d: float
    half_life_days: float
    mean_reversion_level: float
    structural_break_score: float
    confidence: float
    trajectory: list[dict[str, float]] = field(default_factory=list)


@dataclass
class CapacityProfile:
    """Capacity erosion profile for a strategy."""

    strategy_id: str
    nominal_capacity: float
    effective_capacity: float
    utilization: float
    optimal_utilization: float
    crowding_score: float
    impact_cost_score: float
    capacity_decay_rate: float
    residual_capacity_headroom: float


@dataclass
class RegimeHazardProfile:
    """Regime-conditional mortality report."""

    strategy_id: str
    current_regime: MarketRegime
    current_hazard: float
    current_survival_30d: float
    regime_hazards: dict[str, float] = field(default_factory=dict)
    cox_multiplier: float = 1.0


@dataclass
class ClusterAssignment:
    """Cluster label for lifecycle grouping."""

    strategy_id: str
    cluster_id: str
    lifecycle_stage: StrategyState
    health_band: str
    cascade_exposure: float


@dataclass
class CorrelatedFailure:
    """Pairwise correlated-failure signal."""

    left_strategy_id: str
    right_strategy_id: str
    correlation: float
    shared_mode: FailureMode | None
    shared_regime: MarketRegime | None
    cascade_probability: float


@dataclass
class ReplacementRecommendation:
    """Replacement timing and pipeline recommendation."""

    strategy_id: str
    current_state: StrategyState
    recommended_action: str
    optimal_replacement_day: int
    urgency: str
    pipeline_slot: int
    replacement_score: float
    rationale: list[str] = field(default_factory=list)


@dataclass
class PerformanceAttribution:
    """Lifecycle performance decomposition for a strategy."""

    strategy_id: str
    total_return: float
    alpha_return: float
    beta_return: float
    factor_return: float
    unexplained_return: float
    alpha_share: float
    stability_score: float


@dataclass
class HealthScore:
    """Multi-dimensional strategy health score."""

    strategy_id: str
    overall_score: float
    alpha_score: float
    stability_score: float
    capacity_score: float
    regime_score: float
    survival_score: float
    warning_signals: list[HealthSignal] = field(default_factory=list)
    degradation_signals: dict[str, float] = field(default_factory=dict)


@dataclass
class StrategyAllocation:
    """Target allocation for a strategy in a lifecycle portfolio."""

    strategy_id: str
    target_weight: float
    lifecycle_stage: StrategyState
    health_score: float
    expected_alpha: float
    rationale: str


@dataclass
class PortfolioLifecycleReport:
    """Portfolio-level strategy lifecycle construction report."""

    strategies: list[StrategyAllocation] = field(default_factory=list)
    stage_diversification_score: float = 0.0
    concentration_risk: float = 0.0
    average_health_score: float = 0.0
    average_expected_alpha: float = 0.0
    cascade_risk: float = 0.0


def _clamp(value: float, lower: float, upper: float) -> float:
    """Clamp a numeric value into a closed interval."""

    return max(lower, min(upper, value))


def _safe_div(numerator: float, denominator: float, default: float = 0.0) -> float:
    """Return a safe division result with a deterministic fallback."""

    if abs(denominator) <= 1e-12:
        return default
    return numerator / denominator


def _mean(values: Iterable[float]) -> float:
    """Compute the arithmetic mean for an iterable of floats."""

    items = [float(value) for value in values]
    if not items:
        return 0.0
    return sum(items) / len(items)


def _variance(values: Iterable[float]) -> float:
    """Compute a population variance for an iterable of floats."""

    items = [float(value) for value in values]
    if len(items) <= 1:
        return 0.0
    avg = _mean(items)
    return sum((value - avg) ** 2 for value in items) / len(items)


def _stddev(values: Iterable[float]) -> float:
    """Compute a population standard deviation for an iterable of floats."""

    return math.sqrt(max(_variance(values), 0.0))


def _covariance(left: Iterable[float], right: Iterable[float]) -> float:
    """Compute a population covariance using aligned observations."""

    left_items = [float(value) for value in left]
    right_items = [float(value) for value in right]
    size = min(len(left_items), len(right_items))
    if size <= 1:
        return 0.0
    left_slice = left_items[-size:]
    right_slice = right_items[-size:]
    left_mean = _mean(left_slice)
    right_mean = _mean(right_slice)
    return sum(
        (left_slice[index] - left_mean) * (right_slice[index] - right_mean)
        for index in range(size)
    ) / size


def _correlation(left: Iterable[float], right: Iterable[float]) -> float:
    """Compute a bounded correlation estimate from aligned observations."""

    left_items = [float(value) for value in left]
    right_items = [float(value) for value in right]
    size = min(len(left_items), len(right_items))
    if size <= 1:
        return 0.0
    cov = _covariance(left_items[-size:], right_items[-size:])
    denom = _stddev(left_items[-size:]) * _stddev(right_items[-size:])
    return _clamp(_safe_div(cov, denom, 0.0), -1.0, 1.0)


def _ema(values: Iterable[float], alpha: float = 0.25) -> float:
    """Compute a simple exponential moving average."""

    items = [float(value) for value in values]
    if not items:
        return 0.0
    result = items[0]
    smoothing = _clamp(alpha, 0.01, 1.0)
    for value in items[1:]:
        result = smoothing * value + (1.0 - smoothing) * result
    return result


def _tail_mean(values: Iterable[float], tail_fraction: float = 0.25) -> float:
    """Return a left-tail mean for a list of observations."""

    items = sorted(float(value) for value in values)
    if not items:
        return 0.0
    tail_size = max(1, int(len(items) * _clamp(tail_fraction, 0.05, 1.0)))
    return _mean(items[:tail_size])


def _max_drawdown(cumulative_path: Iterable[float]) -> float:
    """Compute maximum drawdown from a cumulative PnL or return path."""

    peak = None
    max_drawdown = 0.0
    for value in cumulative_path:
        current = float(value)
        if peak is None or current > peak:
            peak = current
        if peak is None:
            continue
        drawdown = peak - current
        if drawdown > max_drawdown:
            max_drawdown = drawdown
    return max_drawdown


def _normalize_weights(weights: dict[str, float]) -> dict[str, float]:
    """Normalize a set of non-negative weights to sum to one."""

    cleaned = {key: max(0.0, float(value)) for key, value in weights.items()}
    total = sum(cleaned.values())
    if total <= 0.0:
        return {key: 0.0 for key in cleaned}
    return {key: value / total for key, value in cleaned.items()}


def _band(score: float) -> str:
    """Map a score in ``[0, 1]`` into a named health band."""

    if score >= 0.8:
        return "strong"
    if score >= 0.6:
        return "stable"
    if score >= 0.4:
        return "fragile"
    return "critical"


class StrategyMortality:
    """Weibull mortality model for strategy decay and survival.

    The original public methods are preserved exactly.  Additional helper
    methods allow the richer models in this module to reuse the Weibull baseline
    as a common hazard term.
    """

    def __init__(self, shape: float = 1.5, scale: float = 180.0) -> None:
        """Initialize the baseline Weibull mortality model.

        Args:
            shape: Weibull shape parameter.  Values above one imply increasing
                hazard with age.
            scale: Weibull scale parameter, roughly the characteristic life in
                days.
        """

        self.shape = max(shape, 0.1)
        self.scale = max(scale, 1.0)

    def survival_function(self, t: float) -> float:
        """Return the probability the strategy survives beyond time ``t``."""

        if t <= 0:
            return 1.0
        return math.exp(-((t / self.scale) ** self.shape))

    def hazard_rate(self, t: float) -> float:
        """Return the instantaneous Weibull hazard at time ``t``."""

        if t <= 0:
            return 0.0
        return (self.shape / self.scale) * ((t / self.scale) ** (self.shape - 1))

    def expected_remaining_life(self, t: float) -> float:
        """Approximate expected remaining life conditional on survival to ``t``."""

        current_survival = self.survival_function(t)
        if current_survival <= 1e-12:
            return 0.0

        dt = 1.0
        remaining = 0.0
        for step in range(1, 2000):
            sample_t = t + step * dt
            conditional_survival = self.survival_function(sample_t) / current_survival
            if conditional_survival < 0.001:
                break
            remaining += conditional_survival * dt
        return remaining

    def alpha_decay_rate(
        self,
        initial_alpha: float,
        t: float,
        half_life: float = 90.0,
    ) -> float:
        """Model alpha decay using exponential half-life decay."""

        half_life = max(half_life, 1.0)
        return initial_alpha * math.exp(-math.log(2.0) * max(t, 0.0) / half_life)

    def cumulative_hazard(self, t: float) -> float:
        """Return the cumulative Weibull hazard up to time ``t``."""

        if t <= 0:
            return 0.0
        return (t / self.scale) ** self.shape

    def density(self, t: float) -> float:
        """Return the failure density at time ``t``."""

        return self.hazard_rate(t) * self.survival_function(t)

    def failure_probability(self, start_t: float, horizon_days: float) -> float:
        """Return failure probability between two horizons."""

        start = max(start_t, 0.0)
        end = max(start + horizon_days, start)
        start_survival = self.survival_function(start)
        end_survival = self.survival_function(end)
        if start_survival <= 1e-12:
            return 1.0
        return _clamp(1.0 - end_survival / start_survival, 0.0, 1.0)


class CompetingRisksModel:
    """Competing-risks extension over the Weibull baseline mortality.

    Each failure mode is modeled as a cause-specific hazard that scales the
    baseline hazard.  This produces an interpretable decomposition of total
    mortality into alpha decay, capacity exhaustion, regime shift, and crowding.
    """

    def __init__(self, mortality: StrategyMortality) -> None:
        self.mortality = mortality

    def cause_specific_hazards(
        self,
        age_days: float,
        alpha_pressure: float,
        utilization: float,
        crowding_score: float,
        regime_instability: float,
        drawdown_pressure: float = 0.0,
    ) -> list[CauseSpecificHazard]:
        """Return cause-specific hazards for the current strategy state."""

        baseline = max(self.mortality.hazard_rate(max(age_days, 1.0)), 1e-6)
        alpha_pressure = _clamp(alpha_pressure, 0.0, 3.0)
        utilization = _clamp(utilization, 0.0, 2.0)
        crowding_score = _clamp(crowding_score, 0.0, 2.0)
        regime_instability = _clamp(regime_instability, 0.0, 3.0)
        drawdown_pressure = _clamp(drawdown_pressure, 0.0, 3.0)

        raw_hazards = {
            FailureMode.ALPHA_DECAY: baseline
            * (0.90 + 2.70 * alpha_pressure + 0.55 * drawdown_pressure),
            FailureMode.CAPACITY_EXHAUSTION: baseline
            * (0.65 + 3.10 * max(utilization - 0.55, 0.0) + 1.20 * crowding_score),
            FailureMode.REGIME_SHIFT: baseline
            * (0.60 + 2.40 * regime_instability + 0.45 * alpha_pressure),
            FailureMode.CROWDING: baseline
            * (0.50 + 2.75 * crowding_score + 0.35 * utilization),
        }

        total = sum(raw_hazards.values())
        hazards: list[CauseSpecificHazard] = []
        for mode, hazard in raw_hazards.items():
            share = _safe_div(hazard, total, 0.0)
            hazards.append(
                CauseSpecificHazard(
                    mode=mode,
                    instantaneous_hazard=hazard,
                    cumulative_hazard=hazard * max(age_days, 1.0),
                    incidence_share=share,
                    explanatory_score=_clamp(hazard / baseline, 0.0, 10.0),
                )
            )
        hazards.sort(key=lambda item: item.instantaneous_hazard, reverse=True)
        return hazards

    def assess(
        self,
        strategy_id: str,
        age_days: float,
        alpha_pressure: float,
        utilization: float,
        crowding_score: float,
        regime_instability: float,
        drawdown_pressure: float = 0.0,
    ) -> CompetingRiskAssessment:
        """Produce a complete competing-risks assessment for a strategy."""

        hazards = self.cause_specific_hazards(
            age_days=age_days,
            alpha_pressure=alpha_pressure,
            utilization=utilization,
            crowding_score=crowding_score,
            regime_instability=regime_instability,
            drawdown_pressure=drawdown_pressure,
        )
        total_hazard = sum(item.instantaneous_hazard for item in hazards)
        survival_30d = math.exp(-total_hazard * 30.0)
        survival_90d = math.exp(-total_hazard * 90.0)
        dominant_mode = hazards[0].mode if hazards else None
        return CompetingRiskAssessment(
            strategy_id=strategy_id,
            total_hazard=total_hazard,
            survival_probability=math.exp(-total_hazard),
            dominant_mode=dominant_mode,
            hazards=hazards,
            failure_probability_30d=1.0 - survival_30d,
            failure_probability_90d=1.0 - survival_90d,
        )


class CohortAnalyzer:
    """Vintage and cohort analysis for strategy generations."""

    def build_cohorts(self, strategies: dict[str, dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
        """Group strategy records by their configured vintage."""

        cohorts: dict[str, list[dict[str, Any]]] = {}
        for strategy in strategies.values():
            vintage = str(strategy.get("vintage") or "default")
            cohorts.setdefault(vintage, []).append(strategy)
        return cohorts

    def _estimated_survival_curve(
        self,
        strategies: list[dict[str, Any]],
        horizon_days: int,
    ) -> list[dict[str, float]]:
        """Construct a coarse survival curve from current state snapshots."""

        if not strategies:
            return []
        step = max(7, int(horizon_days / 12) or 1)
        curve: list[dict[str, float]] = []
        for age in range(0, horizon_days + 1, step):
            survivors = 0
            for strategy in strategies:
                age_days = int(strategy.get("age_days", 0))
                terminal_age = int(strategy.get("terminal_age_days") or 10**9)
                retired_age = int(strategy.get("retired_age_days") or 10**9)
                alive_until = min(terminal_age, retired_age)
                if age <= min(age_days, alive_until):
                    survivors += 1
            curve.append({"age_days": float(age), "survival": survivors / len(strategies)})
        return curve

    def snapshot(
        self,
        vintage: str,
        strategies: list[dict[str, Any]],
        metrics_map: dict[str, StrategyLifecycleMetrics],
        health_map: dict[str, HealthScore],
    ) -> CohortSnapshot:
        """Create a cohort snapshot for a single vintage."""

        average_age = _mean(item.get("age_days", 0.0) for item in strategies)
        average_hazard = _mean(
            metrics_map.get(str(item.get("strategy_id")), StrategyLifecycleMetrics(
                strategy_id=str(item.get("strategy_id")),
                state=StrategyState.INCUBATION,
                age_days=0,
                expected_remaining_life=0.0,
                hazard_rate=0.0,
                survival_probability=1.0,
                alpha_decay_rate=0.0,
                capacity_utilization=0.0,
            )).hazard_rate
            for item in strategies
        )
        average_health = _mean(
            health_map.get(str(item.get("strategy_id")), HealthScore(
                strategy_id=str(item.get("strategy_id")),
                overall_score=0.0,
                alpha_score=0.0,
                stability_score=0.0,
                capacity_score=0.0,
                regime_score=0.0,
                survival_score=0.0,
            )).overall_score
            for item in strategies
        )
        horizon = max([int(item.get("age_days", 0)) for item in strategies] + [90])
        return CohortSnapshot(
            vintage=vintage,
            strategy_count=len(strategies),
            active_count=sum(1 for item in strategies if item.get("state") == StrategyState.ACTIVE),
            degrading_count=sum(1 for item in strategies if item.get("state") == StrategyState.DEGRADING),
            terminal_count=sum(
                1
                for item in strategies
                if item.get("state") in (StrategyState.TERMINAL, StrategyState.RETIRED)
            ),
            average_age_days=average_age,
            average_hazard=average_hazard,
            average_health_score=average_health,
            survival_curve=self._estimated_survival_curve(strategies, horizon),
        )

    def compare(self, snapshots: list[CohortSnapshot]) -> list[CohortComparison]:
        """Compare cohorts pairwise on survival, hazard, and health."""

        comparisons: list[CohortComparison] = []
        for left_index in range(len(snapshots)):
            for right_index in range(left_index + 1, len(snapshots)):
                left = snapshots[left_index]
                right = snapshots[right_index]
                left_survival = left.survival_curve[-1]["survival"] if left.survival_curve else 0.0
                right_survival = right.survival_curve[-1]["survival"] if right.survival_curve else 0.0
                survival_advantage = right_survival - left_survival
                hazard_gap = right.average_hazard - left.average_hazard
                health_gap = right.average_health_score - left.average_health_score
                if survival_advantage > 0.05:
                    commentary = "newer cohort is aging more gracefully"
                elif survival_advantage < -0.05:
                    commentary = "older cohort remains structurally stronger"
                else:
                    commentary = "cohorts are aging at similar speeds"
                comparisons.append(
                    CohortComparison(
                        source_vintage=left.vintage,
                        target_vintage=right.vintage,
                        survival_advantage=survival_advantage,
                        hazard_gap=hazard_gap,
                        health_gap=health_gap,
                        commentary=commentary,
                    )
                )
        return comparisons


class AlphaDecayForecaster:
    """Alpha forecast engine with mean reversion and structural breaks."""

    def __init__(self, base_half_life_days: float = 90.0) -> None:
        self.base_half_life_days = max(base_half_life_days, 5.0)

    def infer_current_alpha(
        self,
        initial_alpha: float,
        alpha_history: list[float],
        age_days: int,
    ) -> float:
        """Infer the current alpha using history with a decay fallback."""

        if alpha_history:
            return alpha_history[-1]
        return initial_alpha * math.exp(-math.log(2.0) * max(age_days, 0) / self.base_half_life_days)

    def structural_break_score(self, alpha_history: list[float], pnl_history: list[float]) -> float:
        """Estimate structural-break severity from shifts in mean and volatility."""

        if len(alpha_history) < 8:
            return 0.0
        split = max(2, len(alpha_history) // 2)
        older = alpha_history[:split]
        newer = alpha_history[split:]
        mean_shift = abs(_mean(newer) - _mean(older))
        baseline = abs(_mean(older)) + 1e-6
        variance_ratio = _safe_div(_stddev(newer), _stddev(older) + 1e-6, 1.0)
        pnl_penalty = abs(_tail_mean(pnl_history[-20:], 0.30)) if pnl_history else 0.0
        raw_score = mean_shift / baseline + max(variance_ratio - 1.0, 0.0) + pnl_penalty
        return _clamp(raw_score / 4.0, 0.0, 1.0)

    def calibrated_half_life(
        self,
        current_alpha: float,
        initial_alpha: float,
        break_score: float,
    ) -> float:
        """Derive a dynamic half-life from realized decay and break severity."""

        ratio = _safe_div(abs(current_alpha), abs(initial_alpha) + 1e-6, 0.0)
        ratio = _clamp(ratio, 0.05, 1.5)
        compression = 0.60 + 0.80 * ratio
        break_adjustment = 1.0 - 0.55 * break_score
        half_life = self.base_half_life_days * compression * break_adjustment
        return _clamp(half_life, 15.0, 240.0)

    def forecast(
        self,
        strategy_id: str,
        initial_alpha: float,
        age_days: int,
        alpha_history: list[float],
        pnl_history: list[float],
        horizon_days: int = 90,
    ) -> AlphaForecast:
        """Produce a forward alpha trajectory with mean reversion."""

        current_alpha = self.infer_current_alpha(initial_alpha, alpha_history, age_days)
        break_score = self.structural_break_score(alpha_history, pnl_history)
        mean_reversion_level = _ema(alpha_history[-30:], 0.20) if alpha_history else current_alpha * 0.70
        half_life = self.calibrated_half_life(current_alpha, initial_alpha, break_score)
        decay_speed = math.log(2.0) / max(half_life, 1.0)
        confidence = _clamp(1.0 - break_score - 2.5 * _stddev(alpha_history[-30:]), 0.05, 0.95)

        trajectory: list[dict[str, float]] = []
        for day in range(0, max(horizon_days, 1) + 1, max(1, int(horizon_days / 10) or 1)):
            decayed = current_alpha * math.exp(-decay_speed * day)
            reverted = mean_reversion_level * (1.0 - math.exp(-0.03 * day))
            forecast_alpha = decayed + reverted * (0.35 + 0.65 * break_score)
            trajectory.append({"day": float(day), "alpha": forecast_alpha})

        expected_alpha_30d = trajectory[min(len(trajectory) - 1, 3)]["alpha"] if trajectory else current_alpha
        expected_alpha_90d = trajectory[-1]["alpha"] if trajectory else current_alpha
        return AlphaForecast(
            strategy_id=strategy_id,
            current_alpha=current_alpha,
            expected_alpha_30d=expected_alpha_30d,
            expected_alpha_90d=expected_alpha_90d,
            half_life_days=half_life,
            mean_reversion_level=mean_reversion_level,
            structural_break_score=break_score,
            confidence=confidence,
            trajectory=trajectory,
        )


class CapacityDecayModel:
    """Model capacity erosion from utilization, impact, and crowding."""

    def crowding_indicator(
        self,
        utilization_history: list[float],
        alpha_history: list[float],
        peer_count: int,
    ) -> float:
        """Infer crowding from sustained utilization and alpha compression."""

        utilization_pressure = _ema(utilization_history[-30:], 0.20)
        alpha_trend = 0.0
        if len(alpha_history) >= 4:
            alpha_trend = max(_mean(alpha_history[: len(alpha_history) // 2]) - _mean(alpha_history[len(alpha_history) // 2 :]), 0.0)
        peer_multiplier = 0.15 * max(peer_count - 1, 0)
        return _clamp(utilization_pressure + 4.0 * alpha_trend + peer_multiplier, 0.0, 1.0)

    def impact_cost_score(self, utilization: float, crowding_score: float) -> float:
        """Approximate impact cost growth with convex utilization pressure."""

        utilization = _clamp(utilization, 0.0, 2.0)
        crowding_score = _clamp(crowding_score, 0.0, 1.0)
        return _clamp((utilization**2) * (0.55 + 0.90 * crowding_score), 0.0, 5.0)

    def effective_capacity(
        self,
        nominal_capacity: float,
        impact_cost_score: float,
        alpha_break_score: float,
        age_days: int,
    ) -> float:
        """Convert nominal capacity into effective deployable capacity."""

        age_penalty = 0.05 * math.log(max(age_days, 1), 10) if age_days > 1 else 0.0
        decay = _clamp(impact_cost_score * 0.18 + alpha_break_score * 0.28 + age_penalty, 0.0, 0.85)
        return nominal_capacity * (1.0 - decay)

    def optimal_utilization(
        self,
        expected_alpha: float,
        crowding_score: float,
        health_score: float,
    ) -> float:
        """Estimate utilization that balances monetization and capacity decay."""

        alpha_support = _clamp(abs(expected_alpha) * 8.0, 0.10, 0.80)
        crowding_penalty = 0.35 * crowding_score
        health_bonus = 0.20 * _clamp(health_score, 0.0, 1.0)
        return _clamp(alpha_support + health_bonus - crowding_penalty, 0.15, 0.90)

    def assess(
        self,
        strategy_id: str,
        nominal_capacity: float,
        utilization: float,
        utilization_history: list[float],
        alpha_history: list[float],
        alpha_break_score: float,
        age_days: int,
        peer_count: int,
        health_score: float,
        expected_alpha: float,
    ) -> CapacityProfile:
        """Build a capacity profile for the strategy."""

        crowding = self.crowding_indicator(utilization_history, alpha_history, peer_count)
        impact = self.impact_cost_score(utilization, crowding)
        effective = self.effective_capacity(nominal_capacity, impact, alpha_break_score, age_days)
        optimal = self.optimal_utilization(expected_alpha, crowding, health_score)
        residual_headroom = max(effective * max(optimal - utilization, 0.0), 0.0)
        decay_rate = _safe_div(nominal_capacity - effective, nominal_capacity, 0.0)
        return CapacityProfile(
            strategy_id=strategy_id,
            nominal_capacity=nominal_capacity,
            effective_capacity=effective,
            utilization=utilization,
            optimal_utilization=optimal,
            crowding_score=crowding,
            impact_cost_score=impact,
            capacity_decay_rate=decay_rate,
            residual_capacity_headroom=residual_headroom,
        )


class RegimeConditionalMortality:
    """Cox-style multiplicative hazard analog conditioned on market regime."""

    def __init__(self, mortality: StrategyMortality) -> None:
        self.mortality = mortality
        self.regime_multipliers = {
            MarketRegime.BULL: 0.85,
            MarketRegime.BEAR: 1.15,
            MarketRegime.SIDEWAYS: 1.00,
            MarketRegime.STRESSED: 1.55,
            MarketRegime.RECOVERY: 0.95,
        }
        self.coefficients = {
            "alpha_pressure": 0.85,
            "capacity_pressure": 0.65,
            "crowding": 0.75,
            "drawdown": 0.60,
            "turnover": 0.25,
            "negative_momentum": 0.40,
        }

    def cox_multiplier(self, covariates: dict[str, float]) -> float:
        """Convert covariates into a Cox-style multiplicative hazard term."""

        linear_predictor = 0.0
        for key, coefficient in self.coefficients.items():
            linear_predictor += coefficient * _clamp(float(covariates.get(key, 0.0)), 0.0, 3.0)
        return math.exp(linear_predictor)

    def hazard_rate(
        self,
        age_days: int,
        regime: MarketRegime,
        covariates: dict[str, float],
    ) -> float:
        """Return a time-varying regime-conditional hazard rate."""

        base = self.mortality.hazard_rate(max(age_days, 1))
        multiplier = self.regime_multipliers.get(regime, 1.0)
        return base * multiplier * self.cox_multiplier(covariates)

    def survival_probability(
        self,
        age_days: int,
        horizon_days: int,
        regime: MarketRegime,
        covariates: dict[str, float],
    ) -> float:
        """Approximate horizon survival under constant current regime."""

        hazard = self.hazard_rate(age_days, regime, covariates)
        return math.exp(-hazard * max(horizon_days, 0))

    def assess(
        self,
        strategy_id: str,
        age_days: int,
        current_regime: MarketRegime,
        covariates: dict[str, float],
    ) -> RegimeHazardProfile:
        """Produce a regime-conditional hazard profile across all regimes."""

        regime_hazards: dict[str, float] = {}
        for regime in MarketRegime:
            regime_hazards[regime.value] = self.hazard_rate(age_days, regime, covariates)
        current_hazard = regime_hazards[current_regime.value]
        return RegimeHazardProfile(
            strategy_id=strategy_id,
            current_regime=current_regime,
            current_hazard=current_hazard,
            current_survival_30d=self.survival_probability(age_days, 30, current_regime, covariates),
            regime_hazards=regime_hazards,
            cox_multiplier=self.cox_multiplier(covariates),
        )


class StrategyClusterer:
    """Rule-based clustering for lifecycle segmentation and cascade analysis."""

    def assign_cluster(
        self,
        metrics: StrategyLifecycleMetrics,
        health: HealthScore,
        competing: CompetingRiskAssessment,
    ) -> ClusterAssignment:
        """Assign a lifecycle cluster from state, health, and failure pressure."""

        health_band = _band(health.overall_score)
        dominant = competing.dominant_mode.value if competing.dominant_mode else "balanced"
        cluster_id = f"{metrics.state.value}:{health_band}:{dominant}"
        cascade_exposure = _clamp(competing.failure_probability_30d * (1.0 - health.overall_score), 0.0, 1.0)
        return ClusterAssignment(
            strategy_id=metrics.strategy_id,
            cluster_id=cluster_id,
            lifecycle_stage=metrics.state,
            health_band=health_band,
            cascade_exposure=cascade_exposure,
        )

    def correlated_failures(
        self,
        strategies: dict[str, dict[str, Any]],
        competing_map: dict[str, CompetingRiskAssessment],
    ) -> list[CorrelatedFailure]:
        """Identify strategy pairs with correlated failure pressure."""

        ids = list(strategies.keys())
        correlations: list[CorrelatedFailure] = []
        for left_index in range(len(ids)):
            for right_index in range(left_index + 1, len(ids)):
                left_id = ids[left_index]
                right_id = ids[right_index]
                left = strategies[left_id]
                right = strategies[right_id]
                pnl_corr = _correlation(left.get("pnl_history", []), right.get("pnl_history", []))
                hazard_corr = _correlation(
                    [item.instantaneous_hazard for item in competing_map[left_id].hazards],
                    [item.instantaneous_hazard for item in competing_map[right_id].hazards],
                )
                combined = _clamp(0.65 * max(pnl_corr, 0.0) + 0.35 * max(hazard_corr, 0.0), 0.0, 1.0)
                shared_mode = None
                if competing_map[left_id].dominant_mode == competing_map[right_id].dominant_mode:
                    shared_mode = competing_map[left_id].dominant_mode
                shared_regime = None
                if left.get("current_regime") == right.get("current_regime"):
                    shared_regime = left.get("current_regime")
                if combined >= 0.30:
                    correlations.append(
                        CorrelatedFailure(
                            left_strategy_id=left_id,
                            right_strategy_id=right_id,
                            correlation=combined,
                            shared_mode=shared_mode,
                            shared_regime=shared_regime,
                            cascade_probability=_clamp(combined * (1.15 if shared_mode else 0.90), 0.0, 1.0),
                        )
                    )
        correlations.sort(key=lambda item: item.cascade_probability, reverse=True)
        return correlations

    def cascade_risk(
        self,
        assignments: list[ClusterAssignment],
        correlated_failures: list[CorrelatedFailure],
    ) -> float:
        """Estimate cascade risk from cluster concentration and pairwise dependence."""

        if not assignments:
            return 0.0
        cluster_weights: dict[str, float] = {}
        for assignment in assignments:
            cluster_weights[assignment.cluster_id] = cluster_weights.get(assignment.cluster_id, 0.0) + 1.0
        normalized = _normalize_weights(cluster_weights)
        concentration = sum(weight**2 for weight in normalized.values())
        pairwise = _mean(item.cascade_probability for item in correlated_failures[:10])
        return _clamp(0.55 * concentration + 0.45 * pairwise, 0.0, 1.0)


class ReplacementOptimizer:
    """Optimize replacement timing and incubation pipeline flow."""

    def recommendation(
        self,
        metrics: StrategyLifecycleMetrics,
        forecast: AlphaForecast,
        competing: CompetingRiskAssessment,
        health: HealthScore,
        pipeline_score: float,
        queue_position: int,
    ) -> ReplacementRecommendation:
        """Create a replacement recommendation for a strategy."""

        replacement_pressure = _clamp(
            0.35 * competing.failure_probability_30d
            + 0.20 * competing.failure_probability_90d
            + 0.25 * (1.0 - health.overall_score)
            + 0.20 * max(-forecast.expected_alpha_30d, 0.0),
            0.0,
            1.0,
        )
        optimal_day = int(max(metrics.age_days, 0) + 30.0 * (1.0 - replacement_pressure))
        if metrics.state == StrategyState.TERMINAL:
            action = "replace_immediately"
            urgency = "high"
        elif metrics.state == StrategyState.DEGRADING:
            action = "prepare_replacement"
            urgency = "medium"
        elif replacement_pressure > 0.55:
            action = "open_incubation_slot"
            urgency = "medium"
        else:
            action = "continue_monitoring"
            urgency = "low"

        rationale: list[str] = []
        if forecast.structural_break_score > 0.50:
            rationale.append("alpha process shows structural break characteristics")
        if competing.dominant_mode is not None:
            rationale.append(f"dominant failure mode is {competing.dominant_mode.value}")
        if health.overall_score < 0.50:
            rationale.append("health score has moved into a fragile zone")
        if pipeline_score > 0.65:
            rationale.append("replacement pipeline appears ready for handoff")
        if not rationale:
            rationale.append("current operating profile remains serviceable")

        return ReplacementRecommendation(
            strategy_id=metrics.strategy_id,
            current_state=metrics.state,
            recommended_action=action,
            optimal_replacement_day=optimal_day,
            urgency=urgency,
            pipeline_slot=queue_position,
            replacement_score=replacement_pressure,
            rationale=rationale,
        )

    def incubation_schedule(
        self,
        recommendations: list[ReplacementRecommendation],
        available_slots: int,
    ) -> list[ReplacementRecommendation]:
        """Prioritize replacement candidates into finite incubation slots."""

        ordered = sorted(
            recommendations,
            key=lambda item: (item.urgency == "high", item.replacement_score),
            reverse=True,
        )
        for index, item in enumerate(ordered):
            item.pipeline_slot = index + 1 if index < available_slots else 0
        return ordered


class PerformanceAttributionModel:
    """Decompose realized performance across lifecycle sources."""

    def attribute(self, strategy_id: str, strategy: dict[str, Any]) -> PerformanceAttribution:
        """Decompose total returns into alpha, beta, factor, and residual effects."""

        realized_returns = [float(value) for value in strategy.get("realized_returns", [])]
        market_returns = [float(value) for value in strategy.get("market_returns", [])]
        factor_history = strategy.get("factor_return_history", [])
        factor_exposures = strategy.get("factor_exposures", {})
        beta = float(strategy.get("beta", 0.0))

        total_return = sum(realized_returns)
        beta_return = 0.0
        factor_return = 0.0
        size = min(len(realized_returns), len(market_returns))
        for index in range(size):
            beta_return += beta * market_returns[index]
        for daily_returns in factor_history:
            for factor_name, factor_value in daily_returns.items():
                factor_return += float(factor_exposures.get(factor_name, 0.0)) * float(factor_value)
        alpha_return = total_return - beta_return - factor_return
        unexplained = total_return - alpha_return - beta_return - factor_return
        alpha_share = _safe_div(alpha_return, total_return, 0.0) if abs(total_return) > 1e-12 else 0.0

        alpha_path: list[float] = []
        cumulative = 0.0
        for index in range(len(realized_returns)):
            market_component = beta * market_returns[index] if index < len(market_returns) else 0.0
            factor_component = 0.0
            if index < len(factor_history):
                for factor_name, factor_value in factor_history[index].items():
                    factor_component += float(factor_exposures.get(factor_name, 0.0)) * float(factor_value)
            alpha_component = realized_returns[index] - market_component - factor_component
            cumulative += alpha_component
            alpha_path.append(cumulative)
        stability_score = _clamp(1.0 / (1.0 + 8.0 * _stddev(realized_returns) + _max_drawdown(alpha_path)), 0.0, 1.0)

        return PerformanceAttribution(
            strategy_id=strategy_id,
            total_return=total_return,
            alpha_return=alpha_return,
            beta_return=beta_return,
            factor_return=factor_return,
            unexplained_return=unexplained,
            alpha_share=alpha_share,
            stability_score=stability_score,
        )


class StrategyHealthMonitor:
    """Generate multi-dimensional health scores and warnings."""

    def score(
        self,
        metrics: StrategyLifecycleMetrics,
        forecast: AlphaForecast,
        capacity: CapacityProfile,
        regime: RegimeHazardProfile,
        competing: CompetingRiskAssessment,
        attribution: PerformanceAttribution,
    ) -> HealthScore:
        """Build a composite health score for a strategy."""

        alpha_score = _clamp(
            0.55 * _clamp(_safe_div(forecast.expected_alpha_30d, abs(forecast.current_alpha) + 1e-6, 0.0), -1.0, 1.0)
            + 0.45 * forecast.confidence,
            0.0,
            1.0,
        )
        stability_score = _clamp(0.60 * attribution.stability_score + 0.40 * metrics.survival_probability, 0.0, 1.0)
        capacity_score = _clamp(1.0 - capacity.capacity_decay_rate - 0.50 * max(capacity.utilization - capacity.optimal_utilization, 0.0), 0.0, 1.0)
        regime_score = _clamp(1.0 - min(regime.current_hazard / (metrics.hazard_rate + 1e-6), 3.0) / 3.0, 0.0, 1.0)
        survival_score = _clamp(0.50 * metrics.survival_probability + 0.50 * (1.0 - competing.failure_probability_30d), 0.0, 1.0)
        overall_score = _clamp(
            0.24 * alpha_score
            + 0.20 * stability_score
            + 0.20 * capacity_score
            + 0.16 * regime_score
            + 0.20 * survival_score,
            0.0,
            1.0,
        )

        warnings: list[HealthSignal] = []
        degradation_signals: dict[str, float] = {}
        if forecast.structural_break_score > 0.55:
            warnings.append(HealthSignal.ALPHA_BREAK)
            degradation_signals["structural_break"] = forecast.structural_break_score
        if capacity.crowding_score > 0.55:
            warnings.append(HealthSignal.CROWDING)
            degradation_signals["crowding"] = capacity.crowding_score
        if capacity.utilization > capacity.optimal_utilization + 0.10:
            warnings.append(HealthSignal.CAPACITY_STRESS)
            degradation_signals["capacity_overstretch"] = capacity.utilization - capacity.optimal_utilization
        if regime.current_survival_30d < 0.70:
            warnings.append(HealthSignal.REGIME_MISMATCH)
            degradation_signals["regime_survival_gap"] = 1.0 - regime.current_survival_30d
        if attribution.stability_score < 0.40:
            warnings.append(HealthSignal.DRAWDOWN)
            degradation_signals["instability"] = 1.0 - attribution.stability_score
        if metrics.state == StrategyState.TERMINAL:
            warnings.append(HealthSignal.TERMINAL_DRIFT)
            degradation_signals["terminality"] = 1.0

        return HealthScore(
            strategy_id=metrics.strategy_id,
            overall_score=overall_score,
            alpha_score=alpha_score,
            stability_score=stability_score,
            capacity_score=capacity_score,
            regime_score=regime_score,
            survival_score=survival_score,
            warning_signals=warnings,
            degradation_signals=degradation_signals,
        )


class StrategyPortfolioOptimizer:
    """Construct a portfolio diversified across lifecycle stages."""

    def build(
        self,
        metrics_map: dict[str, StrategyLifecycleMetrics],
        health_map: dict[str, HealthScore],
        forecast_map: dict[str, AlphaForecast],
        cluster_assignments: list[ClusterAssignment],
        cascade_risk: float,
    ) -> PortfolioLifecycleReport:
        """Generate target strategy weights and portfolio lifecycle diagnostics."""

        stage_caps = {
            StrategyState.INCUBATION: 0.20,
            StrategyState.ACTIVE: 0.50,
            StrategyState.DEGRADING: 0.20,
            StrategyState.TERMINAL: 0.05,
            StrategyState.RETIRED: 0.0,
        }

        raw_scores: dict[str, float] = {}
        stage_totals: dict[StrategyState, float] = {}
        assignment_lookup = {item.strategy_id: item for item in cluster_assignments}
        for strategy_id, metrics in metrics_map.items():
            health = health_map[strategy_id]
            forecast = forecast_map[strategy_id]
            score = max(forecast.expected_alpha_30d, 0.0) + 0.10
            score *= 0.45 + 0.55 * health.overall_score
            score *= 1.0 - 0.35 * metrics.crowding_score
            if metrics.state == StrategyState.TERMINAL:
                score *= 0.20
            raw_scores[strategy_id] = max(score, 0.0)
            stage_totals[metrics.state] = stage_totals.get(metrics.state, 0.0) + raw_scores[strategy_id]

        weights: dict[str, float] = {}
        for strategy_id, metrics in metrics_map.items():
            stage_total = stage_totals.get(metrics.state, 0.0)
            stage_share = _safe_div(raw_scores[strategy_id], stage_total, 0.0)
            weights[strategy_id] = stage_caps.get(metrics.state, 0.0) * stage_share
        weights = _normalize_weights(weights)

        allocations: list[StrategyAllocation] = []
        for strategy_id, target_weight in sorted(weights.items(), key=lambda item: item[1], reverse=True):
            metrics = metrics_map[strategy_id]
            health = health_map[strategy_id]
            forecast = forecast_map[strategy_id]
            assignment = assignment_lookup.get(strategy_id)
            rationale = (
                f"{metrics.state.value} stage with {assignment.health_band if assignment else 'unknown'} health, "
                f"expected alpha {forecast.expected_alpha_30d:.4f}"
            )
            allocations.append(
                StrategyAllocation(
                    strategy_id=strategy_id,
                    target_weight=target_weight,
                    lifecycle_stage=metrics.state,
                    health_score=health.overall_score,
                    expected_alpha=forecast.expected_alpha_30d,
                    rationale=rationale,
                )
            )

        stage_weight_map: dict[str, float] = {}
        for allocation in allocations:
            stage_weight_map[allocation.lifecycle_stage.value] = (
                stage_weight_map.get(allocation.lifecycle_stage.value, 0.0) + allocation.target_weight
            )
        normalized_stage_weights = _normalize_weights(stage_weight_map) if stage_weight_map else {}
        stage_diversification = 1.0 - sum(weight**2 for weight in normalized_stage_weights.values())
        concentration_risk = sum(allocation.target_weight**2 for allocation in allocations)
        average_health = _mean(health_map[strategy_id].overall_score for strategy_id in metrics_map)
        average_alpha = _mean(forecast_map[strategy_id].expected_alpha_30d for strategy_id in metrics_map)
        return PortfolioLifecycleReport(
            strategies=allocations,
            stage_diversification_score=_clamp(stage_diversification, 0.0, 1.0),
            concentration_risk=_clamp(concentration_risk, 0.0, 1.0),
            average_health_score=average_health,
            average_expected_alpha=average_alpha,
            cascade_risk=cascade_risk,
        )


class StrategyLifecycleModel:
    """Complete strategy lifecycle management with actuarial extensions.

    The original lifecycle API remains available:

    * ``register_strategy``
    * ``assess_strategy``
    * ``advance_day``
    * ``get_replacement_schedule``

    New methods provide deeper diagnostics while still using plain Python data
    structures and deterministic heuristics suitable for service-layer use.
    """

    def __init__(self) -> None:
        self.mortality = StrategyMortality()
        self.competing_risks = CompetingRisksModel(self.mortality)
        self.cohorts = CohortAnalyzer()
        self.alpha_forecaster = AlphaDecayForecaster()
        self.capacity_model = CapacityDecayModel()
        self.regime_mortality = RegimeConditionalMortality(self.mortality)
        self.clusterer = StrategyClusterer()
        self.replacement_optimizer = ReplacementOptimizer()
        self.attribution_model = PerformanceAttributionModel()
        self.health_monitor = StrategyHealthMonitor()
        self.portfolio_optimizer = StrategyPortfolioOptimizer()
        self.strategies: dict[str, dict[str, Any]] = {}

    def register_strategy(
        self,
        strategy_id: str,
        initial_alpha: float = 0.05,
        capacity: float = 1_000_000.0,
        vintage: str | None = None,
        regime: MarketRegime | str = MarketRegime.SIDEWAYS,
        beta: float = 0.0,
        factor_exposures: dict[str, float] | None = None,
        pipeline_score: float = 0.50,
    ) -> None:
        """Register a new strategy for lifecycle tracking.

        The original positional arguments remain unchanged.  Additional keyword
        arguments allow richer portfolio, cohort, and attribution modeling.
        """

        current_regime = self._normalize_regime(regime)
        self.strategies[strategy_id] = {
            "strategy_id": strategy_id,
            "age_days": 0,
            "initial_alpha": float(initial_alpha),
            "capacity": float(capacity),
            "utilization": 0.0,
            "state": StrategyState.INCUBATION,
            "cumulative_pnl": 0.0,
            "peak_pnl": 0.0,
            "pnl_history": [],
            "alpha_history": [],
            "utilization_history": [],
            "realized_returns": [],
            "market_returns": [],
            "factor_return_history": [],
            "factor_exposures": dict(factor_exposures or {}),
            "beta": float(beta),
            "vintage": vintage or "default",
            "current_regime": current_regime,
            "regime_history": [current_regime],
            "crowding_history": [],
            "manual_crowding_score": None,
            "pipeline_score": _clamp(float(pipeline_score), 0.0, 1.0),
            "retired_age_days": None,
            "terminal_age_days": None,
            "last_assessment": None,
        }

    def retire_strategy(self, strategy_id: str) -> None:
        """Retire a strategy explicitly without deleting its history."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return
        strategy["state"] = StrategyState.RETIRED
        strategy["retired_age_days"] = strategy.get("age_days", 0)

    def set_strategy_utilization(self, strategy_id: str, utilization: float) -> None:
        """Update current capacity utilization for a strategy."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return
        strategy["utilization"] = max(0.0, float(utilization))
        self._append_bounded(strategy["utilization_history"], strategy["utilization"], 720)

    def set_strategy_regime(self, strategy_id: str, regime: MarketRegime | str) -> None:
        """Update the current market regime for a strategy."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return
        normalized = self._normalize_regime(regime)
        strategy["current_regime"] = normalized
        self._append_bounded(strategy["regime_history"], normalized, 720)

    def set_factor_exposures(self, strategy_id: str, factor_exposures: dict[str, float]) -> None:
        """Replace factor exposures used for performance attribution."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return
        strategy["factor_exposures"] = dict(factor_exposures)

    def advance_day(
        self,
        strategy_id: str,
        daily_pnl: float,
        daily_alpha: float | None = None,
        utilization: float | None = None,
        market_return: float | None = None,
        factor_returns: dict[str, float] | None = None,
        regime: MarketRegime | str | None = None,
        crowding_score: float | None = None,
    ) -> None:
        """Advance a strategy by one day and update all lifecycle histories."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return

        strategy["age_days"] += 1
        strategy["cumulative_pnl"] += float(daily_pnl)
        strategy["peak_pnl"] = max(strategy["peak_pnl"], strategy["cumulative_pnl"])
        self._append_bounded(strategy["pnl_history"], float(daily_pnl), 720)

        capacity = max(float(strategy.get("capacity", 1.0)), 1.0)
        realized_return = float(daily_pnl) / capacity
        self._append_bounded(strategy["realized_returns"], realized_return, 720)

        if daily_alpha is None:
            implied_alpha = realized_return
            if market_return is not None:
                implied_alpha -= float(strategy.get("beta", 0.0)) * float(market_return)
        else:
            implied_alpha = float(daily_alpha)
        self._append_bounded(strategy["alpha_history"], implied_alpha, 720)

        if utilization is not None:
            strategy["utilization"] = max(0.0, float(utilization))
        self._append_bounded(strategy["utilization_history"], float(strategy["utilization"]), 720)

        if market_return is not None:
            self._append_bounded(strategy["market_returns"], float(market_return), 720)
        if factor_returns is None:
            factor_returns = {}
        self._append_bounded(strategy["factor_return_history"], dict(factor_returns), 720)

        if regime is not None:
            strategy["current_regime"] = self._normalize_regime(regime)
        self._append_bounded(strategy["regime_history"], strategy["current_regime"], 720)

        if crowding_score is not None:
            strategy["manual_crowding_score"] = _clamp(float(crowding_score), 0.0, 1.0)
        if strategy.get("manual_crowding_score") is not None:
            self._append_bounded(strategy["crowding_history"], float(strategy["manual_crowding_score"]), 720)

        metrics = self.assess_strategy(strategy_id)
        if metrics and metrics.state == StrategyState.TERMINAL and strategy.get("terminal_age_days") is None:
            strategy["terminal_age_days"] = strategy["age_days"]

    def assess_strategy(self, strategy_id: str) -> StrategyLifecycleMetrics | None:
        """Return the full lifecycle assessment for a strategy."""

        strategy = self.strategies.get(strategy_id)
        if not strategy:
            return None

        age = int(strategy.get("age_days", 0))
        baseline_survival = self.mortality.survival_function(age)
        baseline_hazard = self.mortality.hazard_rate(age)
        remaining_life = self.mortality.expected_remaining_life(age)
        baseline_alpha = self.mortality.alpha_decay_rate(strategy["initial_alpha"], age)

        forecast = self.forecast_alpha(strategy_id)
        attribution = self.attribute_performance(strategy_id)
        peer_count = max(len(self.strategies) - 1, 0)
        temporary_metrics = StrategyLifecycleMetrics(
            strategy_id=strategy_id,
            state=strategy.get("state", StrategyState.INCUBATION),
            age_days=age,
            expected_remaining_life=remaining_life,
            hazard_rate=baseline_hazard,
            survival_probability=baseline_survival,
            alpha_decay_rate=baseline_alpha,
            capacity_utilization=float(strategy.get("utilization", 0.0)),
            regime=strategy.get("current_regime", MarketRegime.SIDEWAYS),
        )

        provisional_health = HealthScore(
            strategy_id=strategy_id,
            overall_score=0.60,
            alpha_score=0.60,
            stability_score=0.60,
            capacity_score=0.60,
            regime_score=0.60,
            survival_score=0.60,
        )
        capacity = self.capacity_profile(strategy_id, provisional_health.overall_score, peer_count, forecast)
        competing = self.competing_risk_assessment(strategy_id, forecast, capacity)
        regime_profile = self.regime_assessment(strategy_id, forecast, capacity)
        health = self.health_monitor.score(
            temporary_metrics,
            forecast,
            capacity,
            regime_profile,
            competing,
            attribution,
        )
        capacity = self.capacity_profile(strategy_id, health.overall_score, peer_count, forecast)
        competing = self.competing_risk_assessment(strategy_id, forecast, capacity)
        regime_profile = self.regime_assessment(strategy_id, forecast, capacity)
        health = self.health_monitor.score(
            temporary_metrics,
            forecast,
            capacity,
            regime_profile,
            competing,
            attribution,
        )

        adjusted_hazard = baseline_hazard + 0.35 * competing.total_hazard + 0.25 * regime_profile.current_hazard
        adjusted_survival = _clamp(
            baseline_survival * math.exp(-0.20 * competing.total_hazard * max(age, 1)) * regime_profile.current_survival_30d ** (1.0 / 30.0),
            0.0,
            1.0,
        )
        adjusted_remaining_life = remaining_life * (0.70 + 0.30 * adjusted_survival)
        state = self._determine_state(age, adjusted_survival, forecast, capacity, health)
        strategy["state"] = state
        if state == StrategyState.TERMINAL and strategy.get("terminal_age_days") is None:
            strategy["terminal_age_days"] = age

        metrics = StrategyLifecycleMetrics(
            strategy_id=strategy_id,
            state=state,
            age_days=age,
            expected_remaining_life=adjusted_remaining_life,
            hazard_rate=adjusted_hazard,
            survival_probability=adjusted_survival,
            alpha_decay_rate=forecast.current_alpha,
            capacity_utilization=float(strategy.get("utilization", 0.0)),
            dominant_failure_mode=competing.dominant_mode,
            health_score=health.overall_score,
            regime=strategy.get("current_regime", MarketRegime.SIDEWAYS),
            crowding_score=capacity.crowding_score,
        )
        strategy["last_assessment"] = {
            "metrics": metrics,
            "forecast": forecast,
            "capacity": capacity,
            "competing": competing,
            "regime": regime_profile,
            "health": health,
            "attribution": attribution,
        }
        return metrics

    def get_replacement_schedule(self) -> list[dict[str, Any]]:
        """Generate a replacement schedule for degrading and terminal strategies."""

        recommendations = self.optimize_replacements()
        schedule: list[dict[str, Any]] = []
        for recommendation in recommendations:
            if recommendation.current_state not in (StrategyState.DEGRADING, StrategyState.TERMINAL):
                continue
            metrics = self.assess_strategy(recommendation.strategy_id)
            schedule.append(
                {
                    "strategy_id": recommendation.strategy_id,
                    "state": recommendation.current_state.value,
                    "remaining_life_days": max(
                        0.0,
                        metrics.expected_remaining_life if metrics is not None else 0.0,
                    ),
                    "urgency": recommendation.urgency,
                    "recommended_action": recommendation.recommended_action,
                    "optimal_replacement_day": recommendation.optimal_replacement_day,
                    "replacement_score": recommendation.replacement_score,
                    "rationale": recommendation.rationale,
                }
            )
        return schedule

    def competing_risk_assessment(
        self,
        strategy_id: str,
        forecast: AlphaForecast | None = None,
        capacity: CapacityProfile | None = None,
    ) -> CompetingRiskAssessment:
        """Return the competing-risks mortality assessment for a strategy."""

        strategy = self.strategies[strategy_id]
        if forecast is None:
            forecast = self.forecast_alpha(strategy_id)
        if capacity is None:
            capacity = self.capacity_profile(strategy_id, 0.60, max(len(self.strategies) - 1, 0), forecast)

        alpha_pressure = max(strategy["initial_alpha"] - forecast.expected_alpha_30d, 0.0)
        alpha_pressure = _safe_div(alpha_pressure, abs(strategy["initial_alpha"]) + 1e-6, 0.0)
        regime_instability = self._regime_instability(strategy)
        cumulative_path = self._cumulative_path(strategy.get("pnl_history", []))
        drawdown_pressure = _safe_div(_max_drawdown(cumulative_path), abs(strategy.get("peak_pnl", 0.0)) + 1e-6, 0.0)
        return self.competing_risks.assess(
            strategy_id=strategy_id,
            age_days=int(strategy.get("age_days", 0)),
            alpha_pressure=alpha_pressure,
            utilization=float(strategy.get("utilization", 0.0)),
            crowding_score=capacity.crowding_score,
            regime_instability=regime_instability,
            drawdown_pressure=drawdown_pressure,
        )

    def cohort_analysis(self) -> dict[str, Any]:
        """Return vintage-level survival snapshots and generation comparisons."""

        metrics_map = self._metrics_map()
        health_map = self._health_map(metrics_map)
        snapshots: list[CohortSnapshot] = []
        for vintage, cohort in self.cohorts.build_cohorts(self.strategies).items():
            snapshots.append(self.cohorts.snapshot(vintage, cohort, metrics_map, health_map))
        snapshots.sort(key=lambda item: item.vintage)
        return {
            "cohorts": snapshots,
            "comparisons": self.cohorts.compare(snapshots),
        }

    def forecast_alpha(self, strategy_id: str, horizon_days: int = 90) -> AlphaForecast:
        """Return alpha-decay forecasts for a strategy."""

        strategy = self.strategies[strategy_id]
        return self.alpha_forecaster.forecast(
            strategy_id=strategy_id,
            initial_alpha=float(strategy.get("initial_alpha", 0.0)),
            age_days=int(strategy.get("age_days", 0)),
            alpha_history=list(strategy.get("alpha_history", [])),
            pnl_history=list(strategy.get("pnl_history", [])),
            horizon_days=horizon_days,
        )

    def capacity_profile(
        self,
        strategy_id: str,
        health_score: float | None = None,
        peer_count: int | None = None,
        forecast: AlphaForecast | None = None,
    ) -> CapacityProfile:
        """Return capacity decay and utilization diagnostics for a strategy."""

        strategy = self.strategies[strategy_id]
        if forecast is None:
            forecast = self.forecast_alpha(strategy_id)
        if health_score is None:
            health_score = 0.60
        if peer_count is None:
            peer_count = max(len(self.strategies) - 1, 0)
        profile = self.capacity_model.assess(
            strategy_id=strategy_id,
            nominal_capacity=float(strategy.get("capacity", 0.0)),
            utilization=float(strategy.get("utilization", 0.0)),
            utilization_history=list(strategy.get("utilization_history", [])),
            alpha_history=list(strategy.get("alpha_history", [])),
            alpha_break_score=forecast.structural_break_score,
            age_days=int(strategy.get("age_days", 0)),
            peer_count=peer_count,
            health_score=health_score,
            expected_alpha=forecast.expected_alpha_30d,
        )
        manual_crowding = strategy.get("manual_crowding_score")
        if manual_crowding is not None:
            profile.crowding_score = _clamp(0.50 * profile.crowding_score + 0.50 * float(manual_crowding), 0.0, 1.0)
            profile.impact_cost_score = self.capacity_model.impact_cost_score(profile.utilization, profile.crowding_score)
            profile.effective_capacity = self.capacity_model.effective_capacity(
                profile.nominal_capacity,
                profile.impact_cost_score,
                forecast.structural_break_score,
                int(strategy.get("age_days", 0)),
            )
            profile.capacity_decay_rate = _safe_div(
                profile.nominal_capacity - profile.effective_capacity,
                profile.nominal_capacity,
                0.0,
            )
        return profile

    def regime_assessment(
        self,
        strategy_id: str,
        forecast: AlphaForecast | None = None,
        capacity: CapacityProfile | None = None,
    ) -> RegimeHazardProfile:
        """Return regime-conditional hazard diagnostics for a strategy."""

        strategy = self.strategies[strategy_id]
        if forecast is None:
            forecast = self.forecast_alpha(strategy_id)
        if capacity is None:
            capacity = self.capacity_profile(strategy_id, 0.60, max(len(self.strategies) - 1, 0), forecast)

        alpha_pressure = max(strategy["initial_alpha"] - forecast.expected_alpha_30d, 0.0)
        alpha_pressure = _safe_div(alpha_pressure, abs(strategy["initial_alpha"]) + 1e-6, 0.0)
        covariates = {
            "alpha_pressure": alpha_pressure,
            "capacity_pressure": max(capacity.utilization - capacity.optimal_utilization, 0.0),
            "crowding": capacity.crowding_score,
            "drawdown": _safe_div(
                strategy.get("peak_pnl", 0.0) - strategy.get("cumulative_pnl", 0.0),
                abs(strategy.get("peak_pnl", 0.0)) + 1e-6,
                0.0,
            ),
            "turnover": _ema(strategy.get("utilization_history", []), 0.30),
            "negative_momentum": max(-_mean(strategy.get("pnl_history", [])[-10:]), 0.0),
        }
        return self.regime_mortality.assess(
            strategy_id=strategy_id,
            age_days=int(strategy.get("age_days", 0)),
            current_regime=strategy.get("current_regime", MarketRegime.SIDEWAYS),
            covariates=covariates,
        )

    def cluster_strategies(self) -> dict[str, Any]:
        """Group strategies by lifecycle stage and identify cascade exposure."""

        metrics_map = self._metrics_map()
        health_map = self._health_map(metrics_map)
        competing_map = self._competing_map(metrics_map)
        assignments = [
            self.clusterer.assign_cluster(metrics_map[strategy_id], health_map[strategy_id], competing_map[strategy_id])
            for strategy_id in metrics_map
        ]
        correlated = self.clusterer.correlated_failures(self.strategies, competing_map)
        cascade_risk = self.clusterer.cascade_risk(assignments, correlated)
        return {
            "clusters": assignments,
            "correlated_failures": correlated,
            "cascade_risk": cascade_risk,
        }

    def optimize_replacements(self, available_slots: int = 3) -> list[ReplacementRecommendation]:
        """Return optimized replacement and incubation recommendations."""

        metrics_map = self._metrics_map()
        health_map = self._health_map(metrics_map)
        recommendations: list[ReplacementRecommendation] = []
        queue_position = 1
        for strategy_id, metrics in metrics_map.items():
            forecast = self.forecast_alpha(strategy_id)
            competing = self.competing_risk_assessment(strategy_id, forecast)
            health = health_map[strategy_id]
            recommendation = self.replacement_optimizer.recommendation(
                metrics=metrics,
                forecast=forecast,
                competing=competing,
                health=health,
                pipeline_score=float(self.strategies[strategy_id].get("pipeline_score", 0.50)),
                queue_position=queue_position,
            )
            recommendations.append(recommendation)
            queue_position += 1
        return self.replacement_optimizer.incubation_schedule(recommendations, available_slots)

    def attribute_performance(self, strategy_id: str) -> PerformanceAttribution:
        """Return lifecycle performance attribution for a strategy."""

        return self.attribution_model.attribute(strategy_id, self.strategies[strategy_id])

    def strategy_health(self, strategy_id: str) -> HealthScore:
        """Return the strategy health score and warning signals."""

        metrics = self.assess_strategy(strategy_id)
        if metrics is None:
            return HealthScore(
                strategy_id=strategy_id,
                overall_score=0.0,
                alpha_score=0.0,
                stability_score=0.0,
                capacity_score=0.0,
                regime_score=0.0,
                survival_score=0.0,
            )
        cached = self.strategies[strategy_id].get("last_assessment")
        if cached is not None:
            return cached["health"]
        forecast = self.forecast_alpha(strategy_id)
        capacity = self.capacity_profile(strategy_id, 0.60, max(len(self.strategies) - 1, 0), forecast)
        competing = self.competing_risk_assessment(strategy_id, forecast, capacity)
        regime = self.regime_assessment(strategy_id, forecast, capacity)
        attribution = self.attribute_performance(strategy_id)
        return self.health_monitor.score(metrics, forecast, capacity, regime, competing, attribution)

    def portfolio_report(self) -> PortfolioLifecycleReport:
        """Build a portfolio-level lifecycle allocation report."""

        metrics_map = self._metrics_map()
        health_map = self._health_map(metrics_map)
        forecast_map = {strategy_id: self.forecast_alpha(strategy_id) for strategy_id in metrics_map}
        cluster_result = self.cluster_strategies()
        return self.portfolio_optimizer.build(
            metrics_map=metrics_map,
            health_map=health_map,
            forecast_map=forecast_map,
            cluster_assignments=cluster_result["clusters"],
            cascade_risk=cluster_result["cascade_risk"],
        )

    def get_strategy_snapshot(self, strategy_id: str) -> dict[str, Any] | None:
        """Return a rich diagnostics snapshot for a strategy."""

        metrics = self.assess_strategy(strategy_id)
        if metrics is None:
            return None
        cached = self.strategies[strategy_id].get("last_assessment") or {}
        return {
            "metrics": metrics,
            "alpha_forecast": cached.get("forecast") or self.forecast_alpha(strategy_id),
            "capacity": cached.get("capacity") or self.capacity_profile(strategy_id),
            "competing_risks": cached.get("competing") or self.competing_risk_assessment(strategy_id),
            "regime": cached.get("regime") or self.regime_assessment(strategy_id),
            "health": cached.get("health") or self.strategy_health(strategy_id),
            "attribution": cached.get("attribution") or self.attribute_performance(strategy_id),
        }

    def _metrics_map(self) -> dict[str, StrategyLifecycleMetrics]:
        """Compute lifecycle metrics for all registered strategies."""

        return {
            strategy_id: metrics
            for strategy_id in list(self.strategies.keys())
            if (metrics := self.assess_strategy(strategy_id)) is not None
        }

    def _health_map(
        self,
        metrics_map: dict[str, StrategyLifecycleMetrics],
    ) -> dict[str, HealthScore]:
        """Compute health scores for a set of lifecycle metrics."""

        result: dict[str, HealthScore] = {}
        for strategy_id in metrics_map:
            cached = self.strategies[strategy_id].get("last_assessment")
            if cached is not None:
                result[strategy_id] = cached["health"]
            else:
                result[strategy_id] = self.strategy_health(strategy_id)
        return result

    def _competing_map(
        self,
        metrics_map: dict[str, StrategyLifecycleMetrics],
    ) -> dict[str, CompetingRiskAssessment]:
        """Compute competing-risk assessments for all strategies."""

        result: dict[str, CompetingRiskAssessment] = {}
        for strategy_id in metrics_map:
            cached = self.strategies[strategy_id].get("last_assessment")
            if cached is not None:
                result[strategy_id] = cached["competing"]
            else:
                result[strategy_id] = self.competing_risk_assessment(strategy_id)
        return result

    def _determine_state(
        self,
        age_days: int,
        survival_probability: float,
        forecast: AlphaForecast,
        capacity: CapacityProfile,
        health: HealthScore,
    ) -> StrategyState:
        """Convert diagnostics into a lifecycle state."""

        if age_days < 30:
            return StrategyState.INCUBATION
        if health.overall_score < 0.25 or survival_probability < 0.20 or forecast.expected_alpha_30d < 0.0:
            return StrategyState.TERMINAL
        if health.overall_score < 0.55 or survival_probability < 0.55:
            return StrategyState.DEGRADING
        if capacity.utilization > capacity.optimal_utilization + 0.20 and health.overall_score < 0.65:
            return StrategyState.DEGRADING
        return StrategyState.ACTIVE

    def _regime_instability(self, strategy: dict[str, Any]) -> float:
        """Estimate regime instability from recent regime switching activity."""

        regime_history = strategy.get("regime_history", [])[-20:]
        if len(regime_history) <= 1:
            return 0.0
        switches = 0
        for index in range(1, len(regime_history)):
            if regime_history[index] != regime_history[index - 1]:
                switches += 1
        return _clamp(_safe_div(switches, len(regime_history) - 1, 0.0) * 2.0, 0.0, 1.0)

    def _normalize_regime(self, regime: MarketRegime | str) -> MarketRegime:
        """Normalize string input into the regime enum."""

        if isinstance(regime, MarketRegime):
            return regime
        try:
            return MarketRegime(str(regime))
        except ValueError:
            return MarketRegime.SIDEWAYS

    def _append_bounded(self, container: list[Any], value: Any, max_size: int) -> None:
        """Append to a history list while enforcing a maximum size."""

        container.append(value)
        overflow = len(container) - max_size
        if overflow > 0:
            del container[:overflow]

    def _cumulative_path(self, pnl_history: list[float]) -> list[float]:
        """Convert daily PnL into a cumulative path."""

        cumulative: list[float] = []
        running = 0.0
        for pnl in pnl_history:
            running += float(pnl)
            cumulative.append(running)
        return cumulative


__all__ = [
    "AlphaForecast",
    "CapacityProfile",
    "CauseSpecificHazard",
    "ClusterAssignment",
    "CohortComparison",
    "CohortSnapshot",
    "CompetingRiskAssessment",
    "CorrelatedFailure",
    "FailureMode",
    "HealthScore",
    "HealthSignal",
    "MarketRegime",
    "PerformanceAttribution",
    "PortfolioLifecycleReport",
    "RegimeHazardProfile",
    "ReplacementRecommendation",
    "StrategyAllocation",
    "StrategyLifecycleMetrics",
    "StrategyLifecycleModel",
    "StrategyMortality",
    "StrategyState",
]
