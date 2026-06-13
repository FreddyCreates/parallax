"""Portfolio insurance models for capital-preserving trading programs.

The module keeps the original CPPI, OBPI and portfolio engine interfaces intact,
while materially expanding the analytical surface around the following themes:

* Dynamic CPPI with market-sensitive multipliers and borrowing constraints.
* TIPP (Time-Invariant Portfolio Protection) with ratcheting floors.
* Tail-risk hedging overlays spanning put spreads, collars and VIX hedges.
* Drawdown-control, recovery-time and conditional drawdown analysis.
* Volatility targeting and inverse-volatility budget allocation.
* Jump-diffusion and overnight gap-risk diagnostics.
* Multi-asset insurance with correlation-aware basket protection.
* Insurance cost decomposition and protection-level optimization.
* Rebalancing optimization with transaction-cost-aware thresholds.
* Regime-adaptive switching across CPPI, OBPI and TIPP implementations.

The implementation intentionally uses only the Python standard library so that it
remains portable inside lightweight service deployments.
"""

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Mapping, Sequence


TRADING_DAYS_PER_YEAR = 252.0
DAYS_PER_YEAR = 365.0


class MarketRegime(Enum):
    """High-level market regimes used by adaptive insurance policies."""

    CALM = "calm"
    NORMAL = "normal"
    STRESSED = "stressed"
    CRASH = "crash"
    RECOVERY = "recovery"


class InsuranceStyle(Enum):
    """Portfolio-insurance styles available to the adaptive engine."""

    CPPI = "CPPI"
    OBPI = "OBPI"
    TIPP = "TIPP"


@dataclass
class InsuranceState:
    """State container for insurance allocations.

    The first seven fields are kept exactly as they existed in the original file,
    preserving backwards compatibility for any code instantiating or serializing
    the structure. Additional optional fields enrich the state for the expanded
    analytics without affecting legacy call sites.
    """

    floor_value: float
    cushion: float
    risky_allocation: float
    safe_allocation: float
    portfolio_value: float
    multiplier: float
    breach_count: int = 0
    peak_value: float = 0.0
    locked_in_value: float = 0.0
    current_drawdown: float = 0.0
    floor_history: list[float] = field(default_factory=list)
    risky_weight: float = 0.0
    safe_weight: float = 0.0
    regime: str = MarketRegime.NORMAL.value


@dataclass
class MarketConditions:
    """Summary statistics describing the current market environment."""

    volatility: float = 0.20
    downside_volatility: float = 0.20
    correlation: float = 0.0
    liquidity_stress: float = 0.0
    trend: float = 0.0
    momentum: float = 0.0
    jump_intensity: float = 0.02
    gap_risk: float = 0.03
    vix_level: float = 20.0
    regime: MarketRegime = MarketRegime.NORMAL


@dataclass
class GapRiskProfile:
    """Gap-risk measures used to size insurance buffers."""

    expected_gap: float
    tail_gap: float
    crash_gap: float
    overnight_probability: float
    flash_crash_probability: float


@dataclass
class TailHedgeRecommendation:
    """Recommended tail-risk hedge package."""

    put_spread_notional: float
    collar_floor: float
    collar_cap: float
    variance_swap_vega: float
    vix_hedge_notional: float
    hedge_cost: float


@dataclass
class DrawdownMetrics:
    """Drawdown-control outputs for the insured portfolio."""

    current_drawdown: float
    max_drawdown: float
    conditional_drawdown: float
    expected_recovery_days: float
    drawdown_budget: float


@dataclass
class VolatilityTargetingResult:
    """Dynamic volatility-targeting decision metrics."""

    target_volatility: float
    realized_volatility: float
    scaling_factor: float
    inverse_vol_weight: float
    adjusted_risky_allocation: float


@dataclass
class RebalancingPlan:
    """Recommended rebalancing schedule and execution decision."""

    frequency_days: int
    threshold: float
    turnover_estimate: float
    transaction_cost_estimate: float
    should_rebalance: bool


@dataclass
class CostBreakdown:
    """Insurance cost decomposition across explicit and implicit channels."""

    strategy: str
    explicit_option_cost: float
    carry_cost: float
    financing_cost: float
    turnover_cost: float
    gap_risk_cost: float
    total_cost: float


@dataclass
class ProtectionFrontierPoint:
    """Point on the cost-benefit frontier of insurance levels."""

    protection_level: float
    expected_cost: float
    floor_value: float
    expected_drawdown: float
    utility_score: float


@dataclass
class BasketInsuranceResult:
    """Cross-asset portfolio-insurance recommendation."""

    total_value: float
    protected_floor: float
    effective_correlation: float
    cushion: float
    risky_budget: float
    asset_allocations: dict[str, float]


def _clamp(value: float, lower: float, upper: float) -> float:
    """Clamp a floating-point value to an inclusive interval."""

    return max(lower, min(upper, value))


def _safe_div(numerator: float, denominator: float, default: float = 0.0) -> float:
    """Safely divide numbers while avoiding zero-division noise."""

    if abs(denominator) <= 1e-12:
        return default
    return numerator / denominator


def _mean(values: Sequence[float]) -> float:
    """Return the arithmetic mean of a sequence."""

    if not values:
        return 0.0
    return sum(values) / len(values)


def _stdev(values: Sequence[float]) -> float:
    """Population standard deviation for small analytical utilities."""

    if len(values) < 2:
        return 0.0
    mean_value = _mean(values)
    variance = sum((value - mean_value) ** 2 for value in values) / len(values)
    return math.sqrt(max(variance, 0.0))


def _semideviation(values: Sequence[float]) -> float:
    """Downside semideviation using only negative observations."""

    downside = [value for value in values if value < 0]
    if not downside:
        return 0.0
    return _stdev(downside)


def _quantile(values: Sequence[float], quantile: float) -> float:
    """Simple linear-interpolated empirical quantile."""

    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    bounded_q = _clamp(quantile, 0.0, 1.0)
    position = (len(ordered) - 1) * bounded_q
    lower_index = int(math.floor(position))
    upper_index = int(math.ceil(position))
    if lower_index == upper_index:
        return ordered[lower_index]
    weight = position - lower_index
    return ordered[lower_index] * (1 - weight) + ordered[upper_index] * weight


def _norm_cdf(value: float) -> float:
    """Standard normal cumulative distribution function."""

    return 0.5 * (1.0 + math.erf(value / math.sqrt(2.0)))


def _norm_pdf(value: float) -> float:
    """Standard normal probability density function."""

    return math.exp(-0.5 * value * value) / math.sqrt(2.0 * math.pi)


def _annualize_volatility(period_volatility: float, periods_per_year: float = TRADING_DAYS_PER_YEAR) -> float:
    """Annualize volatility assuming independent periods."""

    return max(period_volatility, 0.0) * math.sqrt(periods_per_year)


def _portfolio_path(initial_value: float, returns: Sequence[float]) -> list[float]:
    """Construct a portfolio path from simple returns."""

    path = [initial_value]
    current = initial_value
    for value in returns:
        current *= 1.0 + value
        current = max(current, 0.0)
        path.append(current)
    return path


def _max_drawdown(path: Sequence[float]) -> tuple[float, float]:
    """Return current drawdown and maximum historical drawdown."""

    if not path:
        return 0.0, 0.0
    peak = path[0]
    current_drawdown = 0.0
    max_drawdown = 0.0
    for value in path:
        peak = max(peak, value)
        drawdown = 1.0 - _safe_div(value, peak, 1.0)
        current_drawdown = drawdown
        max_drawdown = max(max_drawdown, drawdown)
    return current_drawdown, max_drawdown


class CPPIModel:
    """Constant Proportion Portfolio Insurance.

    The original implementation exposed a lean initialize/rebalance interface. The
    expanded version retains those methods while augmenting the model with:

    * dynamic, regime-sensitive multipliers;
    * gap-risk-aware cushion management;
    * leverage and borrowing constraints;
    * rebalancing threshold analysis; and
    * helper diagnostics for portfolio-engine reporting.
    """

    def __init__(
        self,
        floor_pct: float = 0.80,
        multiplier: float = 5.0,
        rebalance_threshold: float = 0.05,
        min_multiplier: float = 1.0,
        max_multiplier: float = 8.0,
        max_leverage: float = 1.0,
        borrowing_limit: float = 0.0,
    ) -> None:
        self.floor_pct = floor_pct
        self.multiplier = multiplier
        self.rebalance_threshold = rebalance_threshold
        self.min_multiplier = min_multiplier
        self.max_multiplier = max_multiplier
        self.max_leverage = max_leverage
        self.borrowing_limit = borrowing_limit

    def initialize(self, portfolio_value: float) -> InsuranceState:
        """Initialize CPPI state.

        This remains backwards compatible with the original implementation while
        enriching the state with peak tracking and stored weights.
        """

        floor = portfolio_value * self.floor_pct
        cushion = max(0.0, portfolio_value - floor)
        risky = min(cushion * self.multiplier, portfolio_value * self.max_leverage)
        safe = portfolio_value - risky
        return InsuranceState(
            floor_value=floor,
            cushion=cushion,
            risky_allocation=risky,
            safe_allocation=safe,
            portfolio_value=portfolio_value,
            multiplier=self.multiplier,
            peak_value=portfolio_value,
            locked_in_value=floor,
            floor_history=[floor],
            risky_weight=_safe_div(risky, portfolio_value),
            safe_weight=_safe_div(safe, portfolio_value),
        )

    def rebalance(self, state: InsuranceState, new_portfolio_value: float) -> InsuranceState:
        """Rebalance allocations based on the latest portfolio value."""

        state.portfolio_value = new_portfolio_value
        state.peak_value = max(state.peak_value, new_portfolio_value)
        state.cushion = max(0.0, new_portfolio_value - state.floor_value)
        risky_target = min(
            state.cushion * self.multiplier,
            new_portfolio_value * self.max_leverage,
        )
        drift = abs(risky_target - state.risky_allocation) / max(state.portfolio_value, 1.0)
        if drift > self.rebalance_threshold:
            state.risky_allocation = risky_target
            state.safe_allocation = new_portfolio_value - risky_target
        if new_portfolio_value < state.floor_value:
            state.breach_count += 1
            state.risky_allocation = 0.0
            state.safe_allocation = new_portfolio_value
        state.current_drawdown = 1.0 - _safe_div(new_portfolio_value, state.peak_value, 1.0)
        state.risky_weight = _safe_div(state.risky_allocation, max(new_portfolio_value, 1e-9))
        state.safe_weight = _safe_div(state.safe_allocation, max(new_portfolio_value, 1e-9))
        return state

    def analyze_market_conditions(
        self,
        returns: Sequence[float] | None = None,
        overnight_gaps: Sequence[float] | None = None,
        vix_level: float | None = None,
        correlation: float = 0.0,
        liquidity_stress: float = 0.0,
    ) -> MarketConditions:
        """Estimate market conditions from observed returns and gap series."""

        observations = list(returns or [])
        gaps = list(overnight_gaps or [])
        daily_vol = _stdev(observations)
        downside_vol = _semideviation(observations)
        trend = _mean(observations[-20:]) if observations else 0.0
        if len(observations) >= 10:
            midpoint = len(observations) // 2
            momentum = _mean(observations[midpoint:]) - _mean(observations[:midpoint])
        else:
            momentum = trend
        jump_source = gaps if gaps else observations
        left_tail = abs(min(_quantile(jump_source, 0.05), 0.0))
        jump_intensity = _clamp(left_tail * 8.0 + downside_vol * 2.0, 0.01, 0.35)
        gap_risk = max(abs(_quantile(gaps, 0.05)), abs(_quantile(gaps, 0.01))) if gaps else 0.0
        if gap_risk <= 0.0:
            gap_risk = max(left_tail * 0.8, daily_vol * 1.5)
        inferred_vix = vix_level if vix_level is not None else max(12.0, daily_vol * 100.0 * math.sqrt(TRADING_DAYS_PER_YEAR))
        provisional = MarketConditions(
            volatility=_annualize_volatility(daily_vol),
            downside_volatility=_annualize_volatility(downside_vol),
            correlation=correlation,
            liquidity_stress=_clamp(liquidity_stress, 0.0, 1.0),
            trend=trend,
            momentum=momentum,
            jump_intensity=jump_intensity,
            gap_risk=_clamp(gap_risk, 0.0, 1.0),
            vix_level=inferred_vix,
        )
        provisional.regime = self.infer_regime(provisional)
        return provisional

    def infer_regime(self, conditions: MarketConditions) -> MarketRegime:
        """Infer a market regime from volatility, gaps and trend."""

        if (
            conditions.volatility > 0.45
            or conditions.gap_risk > 0.08
            or conditions.vix_level > 38.0
        ):
            return MarketRegime.CRASH
        if (
            conditions.volatility > 0.28
            or conditions.downside_volatility > 0.26
            or conditions.vix_level > 28.0
            or conditions.liquidity_stress > 0.65
        ):
            return MarketRegime.STRESSED
        if conditions.trend > 0.0005 and conditions.momentum > 0.0 and conditions.volatility < 0.18:
            return MarketRegime.CALM
        if conditions.trend > 0.0 and conditions.momentum > 0.0:
            return MarketRegime.RECOVERY
        return MarketRegime.NORMAL

    def gap_risk_profile(
        self,
        conditions: MarketConditions,
        confidence: float = 0.99,
    ) -> GapRiskProfile:
        """Convert market conditions into a stylized gap-risk profile."""

        z_score = 2.33 if confidence >= 0.99 else 1.65
        daily_gap_component = conditions.volatility / math.sqrt(TRADING_DAYS_PER_YEAR) * z_score
        jump_component = conditions.jump_intensity * max(0.02, conditions.gap_risk)
        expected_gap = max(conditions.gap_risk * 0.5, daily_gap_component * 0.5)
        tail_gap = daily_gap_component + jump_component
        crash_gap = max(tail_gap * 1.8, conditions.gap_risk * 2.4)
        overnight_probability = _clamp(conditions.jump_intensity * 0.55 + conditions.gap_risk, 0.01, 0.95)
        flash_crash_probability = _clamp(
            conditions.liquidity_stress * 0.25 + conditions.jump_intensity * 0.15,
            0.001,
            0.25,
        )
        return GapRiskProfile(
            expected_gap=expected_gap,
            tail_gap=tail_gap,
            crash_gap=crash_gap,
            overnight_probability=overnight_probability,
            flash_crash_probability=flash_crash_probability,
        )

    def dynamic_multiplier(
        self,
        portfolio_value: float,
        floor_value: float,
        conditions: MarketConditions,
        time_horizon_days: int = 21,
        borrowing_spread: float = 0.0,
    ) -> float:
        """Calculate a time-varying CPPI multiplier.

        The multiplier is reduced when volatility, jump intensity, gap risk or
        financing costs make the cushion more fragile. It can rise modestly when
        the trend environment is supportive and the cushion is comfortably funded.
        """

        cushion_ratio = _safe_div(max(portfolio_value - floor_value, 0.0), portfolio_value)
        horizon_scale = math.sqrt(max(time_horizon_days, 1) / 21.0)
        risk_penalty = (
            conditions.volatility * 0.55
            + conditions.downside_volatility * 0.35
            + conditions.gap_risk * 2.2
            + conditions.jump_intensity * 1.8
            + conditions.liquidity_stress * 0.75
            + borrowing_spread * 4.0
        ) * horizon_scale
        trend_boost = _clamp(conditions.trend * 250.0 + conditions.momentum * 75.0, -0.30, 0.20)
        regime_scalar = {
            MarketRegime.CALM: 1.10,
            MarketRegime.NORMAL: 1.00,
            MarketRegime.RECOVERY: 0.95,
            MarketRegime.STRESSED: 0.72,
            MarketRegime.CRASH: 0.42,
        }[conditions.regime]
        cushion_cap = _safe_div(1.0 - max(conditions.gap_risk, 0.01), max(cushion_ratio, 0.01))
        raw_multiplier = self.multiplier * regime_scalar * (1.0 - risk_penalty + trend_boost)
        raw_multiplier = min(raw_multiplier, cushion_cap)
        return _clamp(raw_multiplier, self.min_multiplier, self.max_multiplier)

    def constrained_risky_allocation(
        self,
        portfolio_value: float,
        cushion: float,
        multiplier: float,
    ) -> tuple[float, float]:
        """Apply leverage and borrowing constraints to the risky budget."""

        unconstrained_risky = cushion * max(multiplier, 0.0)
        max_risky_from_leverage = portfolio_value * self.max_leverage
        max_risky_from_borrowing = portfolio_value * (1.0 + max(self.borrowing_limit, 0.0))
        risky = min(unconstrained_risky, max_risky_from_leverage, max_risky_from_borrowing)
        minimum_safe = -portfolio_value * max(self.borrowing_limit, 0.0)
        safe = portfolio_value - risky
        if safe < minimum_safe:
            safe = minimum_safe
            risky = portfolio_value - safe
        return max(risky, 0.0), safe

    def rebalance_dynamic(
        self,
        state: InsuranceState,
        new_portfolio_value: float,
        conditions: MarketConditions,
        time_horizon_days: int = 21,
        threshold: float | None = None,
        borrowing_spread: float = 0.0,
    ) -> InsuranceState:
        """Dynamic CPPI rebalance with regime and gap-risk adjustments."""

        state.portfolio_value = new_portfolio_value
        state.peak_value = max(state.peak_value, new_portfolio_value)
        state.current_drawdown = 1.0 - _safe_div(new_portfolio_value, state.peak_value, 1.0)
        profile = self.gap_risk_profile(conditions)
        effective_floor = max(state.floor_value, new_portfolio_value * min(self.floor_pct, 0.99))
        buffer = new_portfolio_value * profile.expected_gap
        state.cushion = max(0.0, new_portfolio_value - effective_floor - buffer)
        state.multiplier = self.dynamic_multiplier(
            portfolio_value=new_portfolio_value,
            floor_value=effective_floor,
            conditions=conditions,
            time_horizon_days=time_horizon_days,
            borrowing_spread=borrowing_spread,
        )
        risky_target, safe_target = self.constrained_risky_allocation(
            portfolio_value=new_portfolio_value,
            cushion=state.cushion,
            multiplier=state.multiplier,
        )
        rebalance_barrier = threshold if threshold is not None else self.rebalance_threshold
        drift = abs(risky_target - state.risky_allocation) / max(new_portfolio_value, 1.0)
        if drift > rebalance_barrier or state.breach_count > 0:
            state.risky_allocation = risky_target
            state.safe_allocation = safe_target
        if new_portfolio_value <= effective_floor or profile.crash_gap > max(_safe_div(state.cushion, new_portfolio_value), 0.0):
            state.breach_count += 1
            state.risky_allocation = min(state.risky_allocation, max(new_portfolio_value * 0.10, 0.0))
            state.safe_allocation = new_portfolio_value - state.risky_allocation
        state.floor_value = effective_floor
        state.floor_history.append(effective_floor)
        state.risky_weight = _safe_div(state.risky_allocation, max(new_portfolio_value, 1e-9))
        state.safe_weight = _safe_div(state.safe_allocation, max(new_portfolio_value, 1e-9))
        state.regime = conditions.regime.value
        return state

    def floor_buffer_analysis(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
    ) -> dict[str, float]:
        """Quantify the floor buffer relative to expected gap and drawdown shocks."""

        floor_value = portfolio_value * self.floor_pct
        cushion = max(portfolio_value - floor_value, 0.0)
        profile = self.gap_risk_profile(conditions)
        gap_buffer = cushion - portfolio_value * profile.tail_gap
        crash_buffer = cushion - portfolio_value * profile.crash_gap
        return {
            "floor_value": floor_value,
            "cushion": cushion,
            "gap_buffer": gap_buffer,
            "crash_buffer": crash_buffer,
            "buffer_ratio": _safe_div(gap_buffer, portfolio_value),
        }

    def strategy_summary(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
    ) -> dict[str, float | str]:
        """Compact CPPI summary for external reporting layers."""

        state = self.initialize(portfolio_value)
        dynamic_state = self.rebalance_dynamic(state, portfolio_value, conditions)
        return {
            "floor": dynamic_state.floor_value,
            "cushion": dynamic_state.cushion,
            "multiplier": dynamic_state.multiplier,
            "risky_allocation": dynamic_state.risky_allocation,
            "safe_allocation": dynamic_state.safe_allocation,
            "regime": dynamic_state.regime,
        }


class TIPPModel:
    """Time-Invariant Portfolio Protection with ratcheting floors.

    TIPP behaves similarly to CPPI but anchors the floor to a ratcheting fraction
    of the running peak. The model is useful when investors want gains to be
    locked in progressively rather than merely preserving a static capital floor.
    """

    def __init__(
        self,
        floor_pct: float = 0.80,
        multiplier: float = 4.0,
        lock_in_ratio: float = 0.80,
        ratchet_step: float = 0.02,
        rebalance_threshold: float = 0.04,
    ) -> None:
        self.floor_pct = floor_pct
        self.multiplier = multiplier
        self.lock_in_ratio = lock_in_ratio
        self.ratchet_step = ratchet_step
        self.rebalance_threshold = rebalance_threshold

    def initialize(self, portfolio_value: float) -> InsuranceState:
        """Initialize TIPP state from a starting portfolio value."""

        floor_value = portfolio_value * self.floor_pct
        cushion = max(portfolio_value - floor_value, 0.0)
        risky = min(cushion * self.multiplier, portfolio_value)
        safe = portfolio_value - risky
        return InsuranceState(
            floor_value=floor_value,
            cushion=cushion,
            risky_allocation=risky,
            safe_allocation=safe,
            portfolio_value=portfolio_value,
            multiplier=self.multiplier,
            peak_value=portfolio_value,
            locked_in_value=floor_value,
            floor_history=[floor_value],
            risky_weight=_safe_div(risky, portfolio_value),
            safe_weight=_safe_div(safe, portfolio_value),
        )

    def ratchet_floor(self, state: InsuranceState, new_portfolio_value: float) -> float:
        """Raise the floor as the portfolio reaches fresh highs."""

        previous_peak = max(state.peak_value, 1e-9)
        state.peak_value = max(state.peak_value, new_portfolio_value)
        base_floor = state.peak_value * self.floor_pct
        locked_in_component = max(state.peak_value - previous_peak, 0.0) * self.lock_in_ratio
        candidate_floor = max(state.floor_value, base_floor, state.locked_in_value + locked_in_component)
        ratchet_increment = previous_peak * self.ratchet_step
        if candidate_floor - state.floor_value >= ratchet_increment:
            state.floor_value = min(candidate_floor, state.peak_value)
            state.locked_in_value = state.floor_value
        return state.floor_value

    def rebalance(self, state: InsuranceState, new_portfolio_value: float) -> InsuranceState:
        """Rebalance TIPP allocations after updating the ratcheting floor."""

        state.portfolio_value = new_portfolio_value
        self.ratchet_floor(state, new_portfolio_value)
        state.cushion = max(0.0, new_portfolio_value - state.floor_value)
        risky_target = min(state.cushion * self.multiplier, new_portfolio_value)
        drift = abs(risky_target - state.risky_allocation) / max(new_portfolio_value, 1.0)
        if drift > self.rebalance_threshold:
            state.risky_allocation = risky_target
            state.safe_allocation = new_portfolio_value - risky_target
        if new_portfolio_value < state.floor_value:
            state.breach_count += 1
            state.risky_allocation = 0.0
            state.safe_allocation = new_portfolio_value
        state.current_drawdown = 1.0 - _safe_div(new_portfolio_value, state.peak_value, 1.0)
        state.floor_history.append(state.floor_value)
        state.risky_weight = _safe_div(state.risky_allocation, max(new_portfolio_value, 1e-9))
        state.safe_weight = _safe_div(state.safe_allocation, max(new_portfolio_value, 1e-9))
        return state

    def performance_lock_in(self, state: InsuranceState) -> dict[str, float]:
        """Describe the amount of gain that has been locked into the floor."""

        locked_in_gain = max(state.floor_value - state.floor_history[0], 0.0) if state.floor_history else 0.0
        unlocked_gain = max(state.portfolio_value - state.floor_value, 0.0)
        return {
            "locked_in_gain": locked_in_gain,
            "unlocked_gain": unlocked_gain,
            "lock_in_ratio": _safe_div(locked_in_gain, max(locked_in_gain + unlocked_gain, 1e-9)),
        }

    def analyze_path(self, portfolio_values: Sequence[float]) -> dict[str, Any]:
        """Run TIPP through a historical value path."""

        if not portfolio_values:
            return {
                "floor_path": [],
                "peak_path": [],
                "max_drawdown": 0.0,
                "breach_count": 0,
            }
        state = self.initialize(portfolio_values[0])
        floor_path = [state.floor_value]
        peak_path = [state.peak_value]
        for value in portfolio_values[1:]:
            self.rebalance(state, value)
            floor_path.append(state.floor_value)
            peak_path.append(state.peak_value)
        _, max_drawdown = _max_drawdown(portfolio_values)
        return {
            "floor_path": floor_path,
            "peak_path": peak_path,
            "max_drawdown": max_drawdown,
            "breach_count": state.breach_count,
            "locked_in": self.performance_lock_in(state),
        }

    def strategy_summary(self, portfolio_value: float) -> dict[str, float]:
        """Compact summary of TIPP protection at a point in time."""

        state = self.initialize(portfolio_value)
        return {
            "floor": state.floor_value,
            "cushion": state.cushion,
            "risky_allocation": state.risky_allocation,
            "safe_allocation": state.safe_allocation,
            "multiplier": self.multiplier,
        }


class OBPIModel:
    """Option-Based Portfolio Insurance using synthetic put protection."""

    def __init__(
        self,
        strike_pct: float = 0.95,
        volatility: float = 0.20,
        risk_free_rate: float = 0.05,
    ) -> None:
        self.strike_pct = strike_pct
        self.volatility = volatility
        self.risk_free_rate = risk_free_rate

    def black_scholes_put(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
    ) -> float:
        """Calculate put option price using Black-Scholes."""

        if time_to_expiry <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return max(0.0, strike - spot)
        if self.volatility <= 1e-12:
            return max(0.0, strike * math.exp(-risk_free_rate * time_to_expiry) - spot)
        d1 = (
            math.log(spot / strike)
            + (risk_free_rate + 0.5 * self.volatility**2) * time_to_expiry
        ) / (self.volatility * math.sqrt(time_to_expiry))
        d2 = d1 - self.volatility * math.sqrt(time_to_expiry)
        put_price = (
            strike * math.exp(-risk_free_rate * time_to_expiry) * _norm_cdf(-d2)
            - spot * _norm_cdf(-d1)
        )
        return max(0.0, put_price)

    def _black_scholes_call(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float,
        volatility: float,
    ) -> float:
        """Internal Black-Scholes call pricer used for collars."""

        if time_to_expiry <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return max(0.0, spot - strike)
        if volatility <= 1e-12:
            return max(0.0, spot - strike * math.exp(-risk_free_rate * time_to_expiry))
        d1 = (
            math.log(spot / strike)
            + (risk_free_rate + 0.5 * volatility**2) * time_to_expiry
        ) / (volatility * math.sqrt(time_to_expiry))
        d2 = d1 - volatility * math.sqrt(time_to_expiry)
        return max(
            0.0,
            spot * _norm_cdf(d1) - strike * math.exp(-risk_free_rate * time_to_expiry) * _norm_cdf(d2),
        )

    def option_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float | None = None,
        volatility: float | None = None,
    ) -> dict[str, float]:
        """Approximate Black-Scholes Greeks for the protective put."""

        rate = self.risk_free_rate if risk_free_rate is None else risk_free_rate
        sigma = self.volatility if volatility is None else volatility
        if time_to_expiry <= 0.0 or spot <= 0.0 or strike <= 0.0 or sigma <= 1e-12:
            intrinsic_delta = -1.0 if strike > spot else 0.0
            return {"delta": intrinsic_delta, "gamma": 0.0, "vega": 0.0, "theta": 0.0}
        sqrt_t = math.sqrt(time_to_expiry)
        d1 = (math.log(spot / strike) + (rate + 0.5 * sigma**2) * time_to_expiry) / (sigma * sqrt_t)
        d2 = d1 - sigma * sqrt_t
        delta = _norm_cdf(d1) - 1.0
        gamma = _norm_pdf(d1) / (spot * sigma * sqrt_t)
        vega = spot * _norm_pdf(d1) * sqrt_t
        theta = -spot * _norm_pdf(d1) * sigma / (2.0 * sqrt_t) + rate * strike * math.exp(-rate * time_to_expiry) * _norm_cdf(-d2)
        return {"delta": delta, "gamma": gamma, "vega": vega, "theta": theta}

    def protection_cost(
        self, portfolio_value: float, protection_period_days: int = 30
    ) -> dict[str, float]:
        """Calculate the direct cost of a plain-vanilla OBPI overlay."""

        strike = portfolio_value * self.strike_pct
        time_to_expiry = protection_period_days / DAYS_PER_YEAR
        put_cost = self.black_scholes_put(
            portfolio_value,
            strike,
            time_to_expiry,
            risk_free_rate=self.risk_free_rate,
        )
        return {
            "put_cost": put_cost,
            "cost_pct": _safe_div(put_cost, portfolio_value) * 100.0,
            "protected_floor": strike,
            "max_loss_pct": (1.0 - self.strike_pct) * 100.0 + _safe_div(put_cost, portfolio_value) * 100.0,
            "break_even_return": _safe_div(put_cost, portfolio_value) * 100.0,
        }

    def put_spread_collar(
        self,
        portfolio_value: float,
        protection_period_days: int = 30,
        long_put_pct: float = 0.95,
        short_put_pct: float = 0.85,
        short_call_pct: float = 1.08,
        implied_volatility: float | None = None,
    ) -> dict[str, float]:
        """Build a put-spread collar for lower-cost tail protection."""

        sigma = self.volatility if implied_volatility is None else implied_volatility
        time_to_expiry = protection_period_days / DAYS_PER_YEAR
        long_strike = portfolio_value * long_put_pct
        short_put_strike = portfolio_value * short_put_pct
        short_call_strike = portfolio_value * short_call_pct
        long_put = self.black_scholes_put(portfolio_value, long_strike, time_to_expiry, self.risk_free_rate)
        short_put = self.black_scholes_put(portfolio_value, short_put_strike, time_to_expiry, self.risk_free_rate)
        short_call = self._black_scholes_call(
            portfolio_value,
            short_call_strike,
            time_to_expiry,
            self.risk_free_rate,
            sigma,
        )
        net_cost = max(long_put - short_put - short_call, 0.0)
        return {
            "long_put_strike": long_strike,
            "short_put_strike": short_put_strike,
            "short_call_strike": short_call_strike,
            "net_cost": net_cost,
            "cost_pct": _safe_div(net_cost, portfolio_value) * 100.0,
            "downside_band": long_strike - short_put_strike,
            "upside_cap": short_call_strike - portfolio_value,
        }

    def variance_swap_tail_protection(
        self,
        realized_volatility: float,
        strike_volatility: float,
        vega_notional: float,
        protection_period_days: int = 30,
    ) -> dict[str, float]:
        """Estimate the payoff and carry of a variance-swap hedge."""

        time_fraction = protection_period_days / DAYS_PER_YEAR
        variance_payoff = vega_notional * (realized_volatility**2 - strike_volatility**2) * time_fraction
        carry_cost = max(vega_notional * strike_volatility**2 * time_fraction * 0.25, 0.0)
        return {
            "vega_notional": vega_notional,
            "variance_payoff": variance_payoff,
            "carry_cost": carry_cost,
            "net_value": variance_payoff - carry_cost,
        }

    def vix_tail_hedge(
        self,
        portfolio_value: float,
        vix_level: float,
        stress_trigger: float = 25.0,
    ) -> dict[str, float]:
        """Size a VIX overlay that activates in stressed volatility regimes."""

        excess_vix = max(vix_level - stress_trigger, 0.0)
        hedge_ratio = _clamp(0.04 + excess_vix / 200.0, 0.04, 0.15)
        hedge_notional = portfolio_value * hedge_ratio
        premium_cost = hedge_notional * max(vix_level / 100.0, 0.10) * 0.18
        return {
            "vix_level": vix_level,
            "hedge_ratio": hedge_ratio,
            "hedge_notional": hedge_notional,
            "premium_cost": premium_cost,
        }

    def synthetic_tail_hedge(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
        protection_period_days: int = 30,
    ) -> TailHedgeRecommendation:
        """Combine a put spread, variance swap and VIX overlay."""

        collar = self.put_spread_collar(
            portfolio_value=portfolio_value,
            protection_period_days=protection_period_days,
            long_put_pct=max(self.strike_pct, 0.90),
            short_put_pct=max(self.strike_pct - 0.10, 0.75),
            short_call_pct=1.06 + conditions.trend * 20.0,
            implied_volatility=max(conditions.volatility, self.volatility),
        )
        variance = self.variance_swap_tail_protection(
            realized_volatility=max(conditions.volatility, self.volatility),
            strike_volatility=max(self.volatility * 0.9, 0.05),
            vega_notional=portfolio_value * _clamp(conditions.gap_risk * 1.2, 0.05, 0.25),
            protection_period_days=protection_period_days,
        )
        vix = self.vix_tail_hedge(
            portfolio_value=portfolio_value,
            vix_level=conditions.vix_level,
        )
        hedge_cost = collar["net_cost"] + variance["carry_cost"] + vix["premium_cost"]
        return TailHedgeRecommendation(
            put_spread_notional=portfolio_value * _clamp(conditions.gap_risk * 1.5, 0.10, 0.35),
            collar_floor=collar["long_put_strike"],
            collar_cap=collar["short_call_strike"],
            variance_swap_vega=variance["vega_notional"],
            vix_hedge_notional=vix["hedge_notional"],
            hedge_cost=hedge_cost,
        )

    def strategy_summary(
        self,
        portfolio_value: float,
        protection_period_days: int = 30,
    ) -> dict[str, float]:
        """Compact summary of OBPI economics."""

        cost = self.protection_cost(portfolio_value, protection_period_days)
        greeks = self.option_greeks(
            spot=portfolio_value,
            strike=cost["protected_floor"],
            time_to_expiry=protection_period_days / DAYS_PER_YEAR,
        )
        return {
            "put_cost": cost["put_cost"],
            "cost_pct": cost["cost_pct"],
            "protected_floor": cost["protected_floor"],
            "delta": greeks["delta"],
            "vega": greeks["vega"],
        }


class DrawdownControlModel:
    """Drawdown-aware overlays for portfolio insurance programs."""

    def maximum_drawdown_targeting(
        self,
        portfolio_values: Sequence[float],
        max_drawdown_target: float = 0.10,
    ) -> DrawdownMetrics:
        """Estimate drawdown pressure against a maximum-drawdown budget."""

        current_drawdown, max_drawdown = _max_drawdown(portfolio_values)
        drawdowns: list[float] = []
        peak = portfolio_values[0] if portfolio_values else 1.0
        for value in portfolio_values:
            peak = max(peak, value)
            drawdowns.append(1.0 - _safe_div(value, peak, 1.0))
        tail_drawdowns = [drawdown for drawdown in drawdowns if drawdown > max_drawdown_target]
        conditional_drawdown = _mean(tail_drawdowns) if tail_drawdowns else current_drawdown
        recovery_days = self.recovery_time_model(
            drawdown=max_drawdown,
            expected_return=0.08,
            volatility=0.18,
        )
        return DrawdownMetrics(
            current_drawdown=current_drawdown,
            max_drawdown=max_drawdown,
            conditional_drawdown=conditional_drawdown,
            expected_recovery_days=recovery_days,
            drawdown_budget=max(max_drawdown_target - current_drawdown, 0.0),
        )

    def conditional_drawdown_optimization(
        self,
        portfolio_values: Sequence[float],
        confidence: float = 0.95,
    ) -> dict[str, float]:
        """Compute conditional drawdown statistics and a risk budget recommendation."""

        if not portfolio_values:
            return {
                "conditional_drawdown": 0.0,
                "drawdown_at_risk": 0.0,
                "recommended_risky_weight": 0.0,
            }
        drawdowns: list[float] = []
        peak = portfolio_values[0]
        for value in portfolio_values:
            peak = max(peak, value)
            drawdowns.append(1.0 - _safe_div(value, peak, 1.0))
        dar = _quantile(drawdowns, confidence)
        tail_drawdowns = [value for value in drawdowns if value >= dar]
        cdd = _mean(tail_drawdowns) if tail_drawdowns else dar
        recommended_risky_weight = _clamp(1.0 - cdd * 3.0, 0.0, 1.0)
        return {
            "conditional_drawdown": cdd,
            "drawdown_at_risk": dar,
            "recommended_risky_weight": recommended_risky_weight,
        }

    def recovery_time_model(
        self,
        drawdown: float,
        expected_return: float,
        volatility: float,
    ) -> float:
        """Estimate the time required to recover from a drawdown.

        Recovery time depends on both expected drift and the drag from realized
        volatility. The estimate is stylized but directionally useful for sizing
        the aggressiveness of post-drawdown risk taking.
        """

        if drawdown <= 0.0:
            return 0.0
        effective_growth = max(expected_return - 0.5 * volatility**2, 0.01)
        return math.log(1.0 / max(1.0 - drawdown, 1e-6)) / effective_growth * TRADING_DAYS_PER_YEAR

    def recovery_time_distribution(
        self,
        drawdown_levels: Sequence[float],
        expected_return: float,
        volatility: float,
    ) -> dict[str, float]:
        """Build recovery-time statistics across multiple drawdown severities."""

        recovery_days = [
            self.recovery_time_model(level, expected_return, volatility)
            for level in drawdown_levels
        ]
        return {
            "average_recovery_days": _mean(recovery_days),
            "worst_case_recovery_days": max(recovery_days) if recovery_days else 0.0,
            "best_case_recovery_days": min(recovery_days) if recovery_days else 0.0,
        }

    def drawdown_budget_path(
        self,
        portfolio_values: Sequence[float],
        max_drawdown_target: float = 0.10,
    ) -> list[float]:
        """Track the remaining drawdown budget over time."""

        if not portfolio_values:
            return []
        budgets: list[float] = []
        peak = portfolio_values[0]
        for value in portfolio_values:
            peak = max(peak, value)
            drawdown = 1.0 - _safe_div(value, peak, 1.0)
            budgets.append(max(max_drawdown_target - drawdown, 0.0))
        return budgets


class VolatilityTargetingModel:
    """Dynamic volatility-targeting and inverse-volatility weighting."""

    def estimate_realized_volatility(self, returns: Sequence[float]) -> float:
        """Estimate realized annualized volatility from returns."""

        return _annualize_volatility(_stdev(returns))

    def dynamic_vol_scaling(
        self,
        target_volatility: float,
        realized_volatility: float,
        cushion_ratio: float,
        floor_buffer: float,
    ) -> float:
        """Scale risky exposure to the target volatility while respecting floor buffers."""

        raw_scale = _safe_div(target_volatility, max(realized_volatility, 0.01), 1.0)
        buffer_scalar = _clamp(cushion_ratio * 2.0 + floor_buffer, 0.20, 1.25)
        return _clamp(raw_scale * buffer_scalar, 0.0, 2.0)

    def inverse_vol_weights(self, asset_volatilities: Mapping[str, float]) -> dict[str, float]:
        """Compute inverse-volatility weights for risky-budget distribution."""

        inverse_scores: dict[str, float] = {}
        for asset, volatility in asset_volatilities.items():
            inverse_scores[asset] = _safe_div(1.0, max(volatility, 0.01), 0.0)
        total_score = sum(inverse_scores.values())
        if total_score <= 0.0:
            return {asset: 0.0 for asset in asset_volatilities}
        return {asset: score / total_score for asset, score in inverse_scores.items()}

    def vol_adjusted_position_sizing(
        self,
        risky_budget: float,
        asset_volatilities: Mapping[str, float],
        target_portfolio_volatility: float,
    ) -> dict[str, float]:
        """Allocate risky budget using inverse-volatility weights and target-vol scaling."""

        weights = self.inverse_vol_weights(asset_volatilities)
        weighted_vol = sum(weights[asset] * asset_volatilities[asset] for asset in weights)
        scaling = self.dynamic_vol_scaling(
            target_volatility=target_portfolio_volatility,
            realized_volatility=max(weighted_vol, 0.01),
            cushion_ratio=1.0,
            floor_buffer=0.0,
        )
        return {asset: risky_budget * weight * scaling for asset, weight in weights.items()}

    def allocation_report(
        self,
        portfolio_value: float,
        target_volatility: float,
        realized_volatility: float,
        cushion_ratio: float,
        floor_buffer: float,
        asset_volatilities: Mapping[str, float] | None = None,
    ) -> dict[str, Any]:
        """Comprehensive volatility-targeting report for a protected portfolio."""

        scale = self.dynamic_vol_scaling(
            target_volatility=target_volatility,
            realized_volatility=realized_volatility,
            cushion_ratio=cushion_ratio,
            floor_buffer=floor_buffer,
        )
        inverse_weights = self.inverse_vol_weights(asset_volatilities or {"risky": max(realized_volatility, 0.01)})
        adjusted_allocation = portfolio_value * min(scale, 1.0)
        result = VolatilityTargetingResult(
            target_volatility=target_volatility,
            realized_volatility=realized_volatility,
            scaling_factor=scale,
            inverse_vol_weight=max(inverse_weights.values()) if inverse_weights else 0.0,
            adjusted_risky_allocation=adjusted_allocation,
        )
        return {
            "target_volatility": result.target_volatility,
            "realized_volatility": result.realized_volatility,
            "scaling_factor": result.scaling_factor,
            "inverse_vol_weight": result.inverse_vol_weight,
            "adjusted_risky_allocation": result.adjusted_risky_allocation,
            "asset_weights": inverse_weights,
        }


class GapRiskAnalyzer:
    """Jump-diffusion and overnight gap-risk analytics."""

    def jump_diffusion_profile(
        self,
        conditions: MarketConditions,
        confidence: float = 0.99,
        jump_mean: float = -0.03,
        jump_volatility: float = 0.06,
    ) -> GapRiskProfile:
        """Estimate gap risk using a stylized jump-diffusion process."""

        z_score = 2.33 if confidence >= 0.99 else 1.65
        diffusion_gap = conditions.volatility / math.sqrt(TRADING_DAYS_PER_YEAR) * z_score
        jump_gap = abs(jump_mean) * conditions.jump_intensity + jump_volatility * math.sqrt(conditions.jump_intensity)
        tail_gap = diffusion_gap + jump_gap + conditions.gap_risk * 0.5
        crash_gap = tail_gap + conditions.liquidity_stress * 0.10
        overnight_probability = _clamp(conditions.jump_intensity * 0.50 + conditions.gap_risk, 0.01, 0.95)
        flash_crash_probability = _clamp(conditions.liquidity_stress * 0.30 + jump_gap, 0.001, 0.35)
        return GapRiskProfile(
            expected_gap=max(diffusion_gap * 0.5, conditions.gap_risk * 0.5),
            tail_gap=tail_gap,
            crash_gap=crash_gap,
            overnight_probability=overnight_probability,
            flash_crash_probability=flash_crash_probability,
        )

    def overnight_gap_risk(
        self,
        overnight_gaps: Sequence[float],
        intraday_returns: Sequence[float] | None = None,
    ) -> GapRiskProfile:
        """Estimate gap risk directly from overnight return observations."""

        intraday = list(intraday_returns or [])
        gaps = list(overnight_gaps)
        base_vol = _stdev(gaps if gaps else intraday)
        conditions = MarketConditions(
            volatility=_annualize_volatility(_stdev(intraday)),
            downside_volatility=_annualize_volatility(_semideviation(intraday)),
            liquidity_stress=_clamp(abs(_quantile(gaps, 0.01)) * 8.0, 0.0, 1.0),
            jump_intensity=_clamp(base_vol * 10.0, 0.01, 0.35),
            gap_risk=max(abs(_quantile(gaps, 0.05)), abs(_quantile(gaps, 0.01))) if gaps else base_vol,
            vix_level=max(12.0, base_vol * 100.0 * math.sqrt(TRADING_DAYS_PER_YEAR)),
        )
        return self.jump_diffusion_profile(conditions)

    def flash_crash_protection(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
    ) -> dict[str, float]:
        """Quantify capital reserved for flash-crash protection."""

        profile = self.jump_diffusion_profile(conditions)
        reserve_ratio = _clamp(profile.crash_gap * 1.25 + conditions.liquidity_stress * 0.10, 0.05, 0.35)
        reserve = portfolio_value * reserve_ratio
        stop_loss_distance = portfolio_value * _clamp(profile.tail_gap, 0.01, 0.15)
        return {
            "reserve_ratio": reserve_ratio,
            "reserve": reserve,
            "stop_loss_distance": stop_loss_distance,
            "flash_crash_probability": profile.flash_crash_probability,
        }

    def protective_buffer(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
    ) -> dict[str, float]:
        """Translate gap-risk analytics into required cash buffers."""

        profile = self.jump_diffusion_profile(conditions)
        expected_buffer = portfolio_value * profile.expected_gap
        tail_buffer = portfolio_value * profile.tail_gap
        crash_buffer = portfolio_value * profile.crash_gap
        return {
            "expected_buffer": expected_buffer,
            "tail_buffer": tail_buffer,
            "crash_buffer": crash_buffer,
        }


class MultiAssetInsuranceModel:
    """Cross-asset insurance for diversified risky baskets."""

    def effective_correlation(
        self,
        correlations: Mapping[str, Mapping[str, float]] | None,
        assets: Sequence[str],
    ) -> float:
        """Estimate effective average correlation for a basket."""

        if not correlations or len(assets) < 2:
            return 0.0
        pairs: list[float] = []
        for left_index, left_asset in enumerate(assets):
            for right_asset in assets[left_index + 1 :]:
                left_map = correlations.get(left_asset, {})
                right_map = correlations.get(right_asset, {})
                correlation = left_map.get(right_asset, right_map.get(left_asset, 0.0))
                pairs.append(correlation)
        return _mean(pairs) if pairs else 0.0

    def cross_asset_floor_protection(
        self,
        asset_values: Mapping[str, float],
        floor_pct: float = 0.85,
        asset_volatilities: Mapping[str, float] | None = None,
        correlations: Mapping[str, Mapping[str, float]] | None = None,
    ) -> BasketInsuranceResult:
        """Calculate a correlation-adjusted insured floor for multi-asset portfolios."""

        total_value = sum(max(value, 0.0) for value in asset_values.values())
        assets = list(asset_values.keys())
        effective_corr = self.effective_correlation(correlations, assets)
        diversification_bonus = _clamp((1.0 - effective_corr) * 0.08, 0.0, 0.08)
        protected_floor = total_value * _clamp(floor_pct + diversification_bonus, 0.0, 0.98)
        cushion = max(total_value - protected_floor, 0.0)
        if asset_volatilities:
            inverse_weights = VolatilityTargetingModel().inverse_vol_weights(asset_volatilities)
        else:
            inverse_weights = {asset: _safe_div(value, total_value) for asset, value in asset_values.items()}
        risky_budget = cushion * (3.0 - effective_corr)
        asset_allocations = {
            asset: risky_budget * inverse_weights.get(asset, 0.0)
            for asset in asset_values
        }
        return BasketInsuranceResult(
            total_value=total_value,
            protected_floor=protected_floor,
            effective_correlation=effective_corr,
            cushion=cushion,
            risky_budget=max(risky_budget, 0.0),
            asset_allocations=asset_allocations,
        )

    def basket_cppi(
        self,
        asset_values: Mapping[str, float],
        floor_pct: float = 0.80,
        multiplier: float = 4.0,
        asset_volatilities: Mapping[str, float] | None = None,
        correlations: Mapping[str, Mapping[str, float]] | None = None,
    ) -> dict[str, Any]:
        """Run a basket-level CPPI allocation with correlation adjustment."""

        basket = self.cross_asset_floor_protection(
            asset_values=asset_values,
            floor_pct=floor_pct,
            asset_volatilities=asset_volatilities,
            correlations=correlations,
        )
        effective_multiplier = multiplier * _clamp(1.0 - basket.effective_correlation * 0.4, 0.6, 1.2)
        risky_budget = min(basket.cushion * effective_multiplier, basket.total_value)
        if asset_volatilities:
            weights = VolatilityTargetingModel().inverse_vol_weights(asset_volatilities)
        else:
            weights = {asset: _safe_div(value, basket.total_value) for asset, value in asset_values.items()}
        allocations = {asset: risky_budget * weights.get(asset, 0.0) for asset in asset_values}
        return {
            "total_value": basket.total_value,
            "protected_floor": basket.protected_floor,
            "effective_multiplier": effective_multiplier,
            "risky_budget": risky_budget,
            "allocations": allocations,
        }

    def basket_floor_breach_probability(
        self,
        asset_volatilities: Mapping[str, float],
        effective_correlation: float,
        floor_buffer_ratio: float,
    ) -> float:
        """Estimate the probability that a basket breaches its insured floor."""

        if not asset_volatilities:
            return 0.0
        average_vol = _mean(list(asset_volatilities.values()))
        portfolio_vol = average_vol * math.sqrt(max(1.0 + (len(asset_volatilities) - 1) * effective_correlation, 0.1))
        breach_score = _safe_div(portfolio_vol, max(floor_buffer_ratio, 0.01))
        return _clamp(_norm_cdf(breach_score - 2.0), 0.0, 1.0)


class CostAnalysisModel:
    """Cost analytics for selecting the appropriate insurance overlay."""

    def insurance_cost_decomposition(
        self,
        portfolio_value: float,
        strategy: str,
        turnover: float,
        transaction_cost_bps: float,
        financing_spread: float,
        tail_hedge_cost: float,
        gap_profile: GapRiskProfile,
    ) -> CostBreakdown:
        """Break insurance cost into explicit and implicit components."""

        explicit_option_cost = tail_hedge_cost
        carry_cost = portfolio_value * gap_profile.expected_gap * 0.15
        financing_cost = portfolio_value * max(financing_spread, 0.0) / TRADING_DAYS_PER_YEAR * 30.0
        turnover_cost = portfolio_value * turnover * transaction_cost_bps / 10000.0
        gap_risk_cost = portfolio_value * gap_profile.flash_crash_probability * gap_profile.tail_gap * 0.5
        total_cost = explicit_option_cost + carry_cost + financing_cost + turnover_cost + gap_risk_cost
        return CostBreakdown(
            strategy=strategy,
            explicit_option_cost=explicit_option_cost,
            carry_cost=carry_cost,
            financing_cost=financing_cost,
            turnover_cost=turnover_cost,
            gap_risk_cost=gap_risk_cost,
            total_cost=total_cost,
        )

    def optimal_protection_level_selection(
        self,
        portfolio_value: float,
        candidate_levels: Sequence[float],
        expected_return: float,
        expected_drawdown: float,
        risk_aversion: float,
        estimated_cost_rate: float,
    ) -> dict[str, float]:
        """Choose the best protection level by balancing utility and cost."""

        best_level = 0.0
        best_utility = -float("inf")
        for level in candidate_levels:
            protected_floor = portfolio_value * level
            retained_risk = max(expected_drawdown - (level - 0.70), 0.0)
            cost = portfolio_value * estimated_cost_rate * max(level - 0.70, 0.01)
            utility = expected_return - risk_aversion * retained_risk - _safe_div(cost, portfolio_value)
            if utility > best_utility:
                best_utility = utility
                best_level = level
        return {
            "optimal_protection_level": best_level,
            "optimal_floor_value": portfolio_value * best_level,
            "utility_score": best_utility,
        }

    def cost_benefit_frontier(
        self,
        portfolio_value: float,
        protection_levels: Sequence[float],
        expected_return: float,
        expected_drawdown: float,
        estimated_cost_rate: float,
    ) -> list[ProtectionFrontierPoint]:
        """Construct the cost-benefit frontier of available protection levels."""

        frontier: list[ProtectionFrontierPoint] = []
        for level in protection_levels:
            expected_cost = portfolio_value * estimated_cost_rate * max(level - 0.70, 0.01)
            reduced_drawdown = max(expected_drawdown - (level - 0.70) * 0.8, 0.0)
            utility_score = expected_return - reduced_drawdown - _safe_div(expected_cost, portfolio_value)
            frontier.append(
                ProtectionFrontierPoint(
                    protection_level=level,
                    expected_cost=expected_cost,
                    floor_value=portfolio_value * level,
                    expected_drawdown=reduced_drawdown,
                    utility_score=utility_score,
                )
            )
        frontier.sort(key=lambda point: point.protection_level)
        return frontier

    def marginal_protection_benefit(
        self,
        frontier: Sequence[ProtectionFrontierPoint],
    ) -> list[dict[str, float]]:
        """Compute marginal drawdown reduction per unit of extra protection cost."""

        analysis: list[dict[str, float]] = []
        ordered = sorted(frontier, key=lambda point: point.protection_level)
        for previous, current in zip(ordered, ordered[1:]):
            delta_cost = current.expected_cost - previous.expected_cost
            delta_drawdown = previous.expected_drawdown - current.expected_drawdown
            analysis.append(
                {
                    "from_level": previous.protection_level,
                    "to_level": current.protection_level,
                    "marginal_benefit": _safe_div(delta_drawdown, max(delta_cost, 1e-9)),
                }
            )
        return analysis


class RebalancingOptimizer:
    """Optimize rebalancing frequency and threshold policies."""

    def threshold_optimization(
        self,
        volatility: float,
        transaction_cost_bps: float,
        gap_risk: float,
    ) -> float:
        """Find a transaction-cost-aware no-trade threshold."""

        volatility_component = max(volatility / 8.0, 0.01)
        cost_component = max(transaction_cost_bps / 500.0, 0.005)
        gap_component = gap_risk * 0.5
        return _clamp(volatility_component + cost_component + gap_component, 0.01, 0.25)

    def optimal_rebalancing_frequency(
        self,
        volatility: float,
        transaction_cost_bps: float,
        gap_risk: float,
        drawdown_budget: float,
    ) -> RebalancingPlan:
        """Estimate the best rebalance frequency for an insured portfolio."""

        threshold = self.threshold_optimization(volatility, transaction_cost_bps, gap_risk)
        urgency = volatility + gap_risk * 2.0 + max(0.10 - drawdown_budget, 0.0)
        raw_frequency = int(round(_clamp(14.0 - urgency * 20.0 + transaction_cost_bps / 8.0, 1.0, 21.0)))
        turnover_estimate = _clamp(volatility * 1.4 + gap_risk * 2.0, 0.05, 1.50)
        transaction_cost_estimate = turnover_estimate * transaction_cost_bps / 10000.0
        return RebalancingPlan(
            frequency_days=raw_frequency,
            threshold=threshold,
            turnover_estimate=turnover_estimate,
            transaction_cost_estimate=transaction_cost_estimate,
            should_rebalance=urgency > threshold,
        )

    def transaction_cost_aware_rebalance(
        self,
        current_risky_allocation: float,
        target_risky_allocation: float,
        portfolio_value: float,
        transaction_cost_bps: float,
        threshold: float,
    ) -> RebalancingPlan:
        """Decide whether the target rebalance is worth the transaction cost."""

        drift = abs(target_risky_allocation - current_risky_allocation) / max(portfolio_value, 1.0)
        turnover_estimate = drift
        transaction_cost_estimate = turnover_estimate * transaction_cost_bps / 10000.0
        should_rebalance = drift > threshold and drift > transaction_cost_estimate * 4.0
        return RebalancingPlan(
            frequency_days=1,
            threshold=threshold,
            turnover_estimate=turnover_estimate,
            transaction_cost_estimate=transaction_cost_estimate,
            should_rebalance=should_rebalance,
        )

    def schedule_summary(
        self,
        plan: RebalancingPlan,
    ) -> dict[str, float | bool]:
        """Serialize a rebalancing plan into primitive values."""

        return {
            "frequency_days": plan.frequency_days,
            "threshold": plan.threshold,
            "turnover_estimate": plan.turnover_estimate,
            "transaction_cost_estimate": plan.transaction_cost_estimate,
            "should_rebalance": plan.should_rebalance,
        }


class RegimeAdaptiveInsurance:
    """Switch between CPPI, OBPI and TIPP based on market regime."""

    def classify_regime(self, conditions: MarketConditions) -> MarketRegime:
        """Map conditions into a regime for strategy selection."""

        return conditions.regime

    def adaptive_floor(
        self,
        base_floor_pct: float,
        conditions: MarketConditions,
        drawdown_budget: float = 0.10,
    ) -> float:
        """Raise or lower the floor based on regime and drawdown pressure."""

        regime_adjustment = {
            MarketRegime.CALM: -0.02,
            MarketRegime.NORMAL: 0.0,
            MarketRegime.RECOVERY: 0.01,
            MarketRegime.STRESSED: 0.05,
            MarketRegime.CRASH: 0.08,
        }[conditions.regime]
        drawdown_adjustment = max(0.10 - drawdown_budget, 0.0) * 0.5
        return _clamp(base_floor_pct + regime_adjustment + drawdown_adjustment, 0.65, 0.98)

    def select_strategy(
        self,
        conditions: MarketConditions,
        protection_horizon_days: int = 30,
    ) -> InsuranceStyle:
        """Choose the insurance style that best matches the regime."""

        if conditions.regime == MarketRegime.CRASH or conditions.gap_risk > 0.08:
            return InsuranceStyle.OBPI
        if conditions.regime == MarketRegime.STRESSED or protection_horizon_days > 60:
            return InsuranceStyle.TIPP
        return InsuranceStyle.CPPI

    def strategy_transition_score(self, conditions: MarketConditions) -> dict[str, float]:
        """Provide soft scores for each strategy under the current regime."""

        cppi_score = _clamp(1.2 - conditions.volatility * 2.0 - conditions.gap_risk * 3.0, 0.0, 1.0)
        obpi_score = _clamp(conditions.gap_risk * 4.0 + conditions.vix_level / 40.0, 0.0, 1.0)
        tipp_score = _clamp(conditions.downside_volatility * 2.0 + (0.04 - conditions.trend) * 8.0, 0.0, 1.0)
        return {
            "CPPI": cppi_score,
            "OBPI": obpi_score,
            "TIPP": tipp_score,
        }

    def regime_policy(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
        base_floor_pct: float,
        drawdown_budget: float,
        protection_horizon_days: int = 30,
    ) -> dict[str, float | str | dict[str, float]]:
        """Return the regime-adaptive insurance policy for the portfolio."""

        floor_pct = self.adaptive_floor(base_floor_pct, conditions, drawdown_budget)
        strategy = self.select_strategy(conditions, protection_horizon_days)
        scores = self.strategy_transition_score(conditions)
        return {
            "regime": self.classify_regime(conditions).value,
            "selected_strategy": strategy.value,
            "adaptive_floor_pct": floor_pct,
            "adaptive_floor_value": portfolio_value * floor_pct,
            "strategy_scores": scores,
        }


class PortfolioInsuranceEngine:
    """Unified portfolio insurance combining CPPI, OBPI and TIPP strategies.

    The engine preserves the original public interface and adds richer scenario
    analysis so callers can obtain a single structured report spanning dynamic
    protection design, cost diagnostics and regime-adaptive recommendations.
    """

    def __init__(self) -> None:
        self.cppi = CPPIModel()
        self.obpi = OBPIModel()
        self.tipp = TIPPModel()
        self.drawdown_control = DrawdownControlModel()
        self.volatility_targeting = VolatilityTargetingModel()
        self.gap_risk = GapRiskAnalyzer()
        self.multi_asset = MultiAssetInsuranceModel()
        self.cost_analysis = CostAnalysisModel()
        self.rebalancing_optimizer = RebalancingOptimizer()
        self.regime_adaptive = RegimeAdaptiveInsurance()
        self.active_insurance: dict[str, InsuranceState] = {}
        self.active_styles: dict[str, InsuranceStyle] = {}

    def activate_cppi(self, portfolio_id: str, value: float, **kwargs: Any) -> InsuranceState:
        """Activate CPPI protection for a portfolio."""

        model = CPPIModel(**kwargs) if kwargs else self.cppi
        state = model.initialize(value)
        self.active_insurance[portfolio_id] = state
        self.active_styles[portfolio_id] = InsuranceStyle.CPPI
        return state

    def activate_tipp(self, portfolio_id: str, value: float, **kwargs: Any) -> InsuranceState:
        """Activate TIPP protection for a portfolio."""

        model = TIPPModel(**kwargs) if kwargs else self.tipp
        state = model.initialize(value)
        self.active_insurance[portfolio_id] = state
        self.active_styles[portfolio_id] = InsuranceStyle.TIPP
        return state

    def activate_regime_adaptive(
        self,
        portfolio_id: str,
        value: float,
        market_returns: Sequence[float] | None = None,
        overnight_gaps: Sequence[float] | None = None,
    ) -> dict[str, Any]:
        """Activate the strategy chosen by the regime-adaptive policy."""

        conditions = self.cppi.analyze_market_conditions(
            returns=market_returns,
            overnight_gaps=overnight_gaps,
        )
        policy = self.regime_adaptive.regime_policy(
            portfolio_value=value,
            conditions=conditions,
            base_floor_pct=self.cppi.floor_pct,
            drawdown_budget=0.10,
        )
        strategy = InsuranceStyle(policy["selected_strategy"])
        if strategy == InsuranceStyle.TIPP:
            state = self.activate_tipp(portfolio_id, value, floor_pct=policy["adaptive_floor_pct"])
        else:
            state = self.activate_cppi(portfolio_id, value, floor_pct=policy["adaptive_floor_pct"])
        state.regime = policy["regime"]
        self.active_styles[portfolio_id] = strategy
        return {
            "strategy": strategy.value,
            "policy": policy,
            "state": self._state_to_dict(state),
        }

    def rebalance_active_insurance(
        self,
        portfolio_id: str,
        new_value: float,
        market_returns: Sequence[float] | None = None,
        overnight_gaps: Sequence[float] | None = None,
    ) -> dict[str, Any]:
        """Rebalance an activated insurance program using its assigned style."""

        state = self.active_insurance.get(portfolio_id)
        if state is None:
            state = self.activate_cppi(portfolio_id, new_value)
        style = self.active_styles.get(portfolio_id, InsuranceStyle.CPPI)
        conditions = self.cppi.analyze_market_conditions(
            returns=market_returns,
            overnight_gaps=overnight_gaps,
        )
        if style == InsuranceStyle.TIPP:
            state = self.tipp.rebalance(state, new_value)
        elif style == InsuranceStyle.OBPI:
            state.portfolio_value = new_value
            state.regime = conditions.regime.value
        else:
            state = self.cppi.rebalance_dynamic(state, new_value, conditions)
        self.active_insurance[portfolio_id] = state
        return {
            "portfolio_id": portfolio_id,
            "style": style.value,
            "state": self._state_to_dict(state),
        }

    def _default_asset_values(self, portfolio_value: float) -> dict[str, float]:
        """Construct a simple three-bucket asset decomposition when none is supplied."""

        return {
            "equities": portfolio_value * 0.50,
            "macro": portfolio_value * 0.30,
            "carry": portfolio_value * 0.20,
        }

    def _default_asset_volatilities(self) -> dict[str, float]:
        """Default asset volatilities for generic basket analysis."""

        return {"equities": 0.24, "macro": 0.16, "carry": 0.11}

    def _default_correlations(self) -> dict[str, dict[str, float]]:
        """Default cross-asset correlation assumptions."""

        return {
            "equities": {"macro": 0.35, "carry": 0.25},
            "macro": {"equities": 0.35, "carry": 0.20},
            "carry": {"equities": 0.25, "macro": 0.20},
        }

    def _state_to_dict(self, state: InsuranceState) -> dict[str, Any]:
        """Serialize an insurance state using JSON-friendly primitives."""

        return {
            "floor_value": state.floor_value,
            "cushion": state.cushion,
            "risky_allocation": state.risky_allocation,
            "safe_allocation": state.safe_allocation,
            "portfolio_value": state.portfolio_value,
            "multiplier": state.multiplier,
            "breach_count": state.breach_count,
            "peak_value": state.peak_value,
            "locked_in_value": state.locked_in_value,
            "current_drawdown": state.current_drawdown,
            "floor_history": state.floor_history,
            "risky_weight": state.risky_weight,
            "safe_weight": state.safe_weight,
            "regime": state.regime,
        }

    def compare_strategies(
        self,
        portfolio_value: float,
        conditions: MarketConditions,
        protection_period_days: int = 30,
    ) -> dict[str, Any]:
        """Compare CPPI, OBPI and TIPP under a shared market regime."""

        cppi_state = self.cppi.rebalance_dynamic(self.cppi.initialize(portfolio_value), portfolio_value, conditions)
        tipp_state = self.tipp.initialize(portfolio_value)
        obpi_cost = self.obpi.protection_cost(portfolio_value, protection_period_days)
        return {
            "CPPI": self._state_to_dict(cppi_state),
            "OBPI": obpi_cost,
            "TIPP": self._state_to_dict(tipp_state),
        }

    def scenario_report(
        self,
        portfolio_value: float,
        market_returns: Sequence[float] | None = None,
        overnight_gaps: Sequence[float] | None = None,
    ) -> dict[str, Any]:
        """Produce a scenario report focused on drawdown and gap stress."""

        path = _portfolio_path(portfolio_value, market_returns or [])
        conditions = self.cppi.analyze_market_conditions(market_returns, overnight_gaps)
        drawdown = self.drawdown_control.maximum_drawdown_targeting(path)
        gap_profile = self.gap_risk.jump_diffusion_profile(conditions)
        flash_crash = self.gap_risk.flash_crash_protection(portfolio_value, conditions)
        return {
            "drawdown": {
                "current_drawdown": drawdown.current_drawdown,
                "max_drawdown": drawdown.max_drawdown,
                "conditional_drawdown": drawdown.conditional_drawdown,
                "expected_recovery_days": drawdown.expected_recovery_days,
            },
            "gap_risk": {
                "expected_gap": gap_profile.expected_gap,
                "tail_gap": gap_profile.tail_gap,
                "crash_gap": gap_profile.crash_gap,
                "overnight_probability": gap_profile.overnight_probability,
                "flash_crash_probability": gap_profile.flash_crash_probability,
            },
            "flash_crash": flash_crash,
        }

    def get_protection_report(
        self,
        portfolio_value: float,
        market_returns: Sequence[float] | None = None,
        overnight_gaps: Sequence[float] | None = None,
        asset_values: Mapping[str, float] | None = None,
        asset_volatilities: Mapping[str, float] | None = None,
        correlations: Mapping[str, Mapping[str, float]] | None = None,
    ) -> dict[str, Any]:
        """Full protection analysis combining CPPI, OBPI, TIPP and overlays."""

        assets = dict(asset_values or self._default_asset_values(portfolio_value))
        vols = dict(asset_volatilities or self._default_asset_volatilities())
        corr = dict(correlations or self._default_correlations())
        conditions = self.cppi.analyze_market_conditions(
            returns=market_returns,
            overnight_gaps=overnight_gaps,
            correlation=self.multi_asset.effective_correlation(corr, list(assets.keys())),
        )
        path = _portfolio_path(portfolio_value, market_returns or [])
        cppi_state = self.cppi.initialize(portfolio_value)
        dynamic_cppi_state = self.cppi.rebalance_dynamic(cppi_state, portfolio_value, conditions)
        obpi_cost = self.obpi.protection_cost(portfolio_value)
        tipp_state = self.tipp.initialize(portfolio_value)
        tipp_lock_in = self.tipp.performance_lock_in(tipp_state)
        tail_hedge = self.obpi.synthetic_tail_hedge(portfolio_value, conditions)
        drawdown_metrics = self.drawdown_control.maximum_drawdown_targeting(path)
        conditional_drawdown = self.drawdown_control.conditional_drawdown_optimization(path)
        vol_report = self.volatility_targeting.allocation_report(
            portfolio_value=portfolio_value,
            target_volatility=0.12,
            realized_volatility=max(conditions.volatility, 0.01),
            cushion_ratio=_safe_div(dynamic_cppi_state.cushion, max(portfolio_value, 1e-9)),
            floor_buffer=_safe_div(dynamic_cppi_state.floor_value, max(portfolio_value, 1e-9)),
            asset_volatilities=vols,
        )
        gap_profile = self.gap_risk.jump_diffusion_profile(conditions)
        gap_buffers = self.gap_risk.protective_buffer(portfolio_value, conditions)
        flash_crash = self.gap_risk.flash_crash_protection(portfolio_value, conditions)
        basket = self.multi_asset.cross_asset_floor_protection(
            asset_values=assets,
            floor_pct=self.cppi.floor_pct,
            asset_volatilities=vols,
            correlations=corr,
        )
        basket_cppi = self.multi_asset.basket_cppi(
            asset_values=assets,
            floor_pct=self.cppi.floor_pct,
            multiplier=self.cppi.multiplier,
            asset_volatilities=vols,
            correlations=corr,
        )
        basket_breach_probability = self.multi_asset.basket_floor_breach_probability(
            asset_volatilities=vols,
            effective_correlation=basket.effective_correlation,
            floor_buffer_ratio=_safe_div(basket.cushion, max(basket.total_value, 1e-9)),
        )
        rebalancing_plan = self.rebalancing_optimizer.optimal_rebalancing_frequency(
            volatility=max(conditions.volatility, 0.01),
            transaction_cost_bps=8.0,
            gap_risk=conditions.gap_risk,
            drawdown_budget=drawdown_metrics.drawdown_budget,
        )
        execution_plan = self.rebalancing_optimizer.transaction_cost_aware_rebalance(
            current_risky_allocation=dynamic_cppi_state.risky_allocation,
            target_risky_allocation=vol_report["adjusted_risky_allocation"],
            portfolio_value=portfolio_value,
            transaction_cost_bps=8.0,
            threshold=rebalancing_plan.threshold,
        )
        regime_policy = self.regime_adaptive.regime_policy(
            portfolio_value=portfolio_value,
            conditions=conditions,
            base_floor_pct=self.cppi.floor_pct,
            drawdown_budget=drawdown_metrics.drawdown_budget,
        )
        cost_breakdown = self.cost_analysis.insurance_cost_decomposition(
            portfolio_value=portfolio_value,
            strategy=regime_policy["selected_strategy"],
            turnover=execution_plan.turnover_estimate,
            transaction_cost_bps=8.0,
            financing_spread=0.015,
            tail_hedge_cost=tail_hedge.hedge_cost,
            gap_profile=gap_profile,
        )
        optimal_protection = self.cost_analysis.optimal_protection_level_selection(
            portfolio_value=portfolio_value,
            candidate_levels=[0.75, 0.80, 0.85, 0.90, 0.95],
            expected_return=max(_mean(market_returns or [0.0004]) * TRADING_DAYS_PER_YEAR, 0.02),
            expected_drawdown=max(drawdown_metrics.max_drawdown, gap_profile.tail_gap),
            risk_aversion=2.5,
            estimated_cost_rate=_safe_div(cost_breakdown.total_cost, max(portfolio_value, 1e-9)),
        )
        frontier = self.cost_analysis.cost_benefit_frontier(
            portfolio_value=portfolio_value,
            protection_levels=[0.75, 0.80, 0.85, 0.90, 0.95],
            expected_return=max(_mean(market_returns or [0.0004]) * TRADING_DAYS_PER_YEAR, 0.02),
            expected_drawdown=max(drawdown_metrics.max_drawdown, gap_profile.tail_gap),
            estimated_cost_rate=_safe_div(cost_breakdown.total_cost, max(portfolio_value, 1e-9)),
        )
        marginal_benefit = self.cost_analysis.marginal_protection_benefit(frontier)
        recommendation = regime_policy["selected_strategy"] if obpi_cost["cost_pct"] <= 3.0 else InsuranceStyle.CPPI.value
        return {
            "portfolio_value": portfolio_value,
            "cppi": {
                "floor": dynamic_cppi_state.floor_value,
                "cushion": dynamic_cppi_state.cushion,
                "risky_pct": _safe_div(dynamic_cppi_state.risky_allocation, portfolio_value) * 100.0,
                "safe_pct": _safe_div(dynamic_cppi_state.safe_allocation, portfolio_value) * 100.0,
            },
            "obpi": obpi_cost,
            "recommendation": recommendation,
            "market_regime": conditions.regime.value,
            "dynamic_cppi": {
                "state": self._state_to_dict(dynamic_cppi_state),
                "gap_risk_profile": {
                    "expected_gap": self.cppi.gap_risk_profile(conditions).expected_gap,
                    "tail_gap": self.cppi.gap_risk_profile(conditions).tail_gap,
                    "crash_gap": self.cppi.gap_risk_profile(conditions).crash_gap,
                },
                "floor_buffer": self.cppi.floor_buffer_analysis(portfolio_value, conditions),
            },
            "tipp": {
                "state": self._state_to_dict(tipp_state),
                "lock_in": tipp_lock_in,
            },
            "tail_risk_hedging": {
                "put_spread_notional": tail_hedge.put_spread_notional,
                "collar_floor": tail_hedge.collar_floor,
                "collar_cap": tail_hedge.collar_cap,
                "variance_swap_vega": tail_hedge.variance_swap_vega,
                "vix_hedge_notional": tail_hedge.vix_hedge_notional,
                "hedge_cost": tail_hedge.hedge_cost,
                "vix_overlay": self.obpi.vix_tail_hedge(portfolio_value, conditions.vix_level),
            },
            "drawdown_control": {
                "current_drawdown": drawdown_metrics.current_drawdown,
                "max_drawdown": drawdown_metrics.max_drawdown,
                "conditional_drawdown": drawdown_metrics.conditional_drawdown,
                "expected_recovery_days": drawdown_metrics.expected_recovery_days,
                "drawdown_budget": drawdown_metrics.drawdown_budget,
                "conditional_drawdown_optimization": conditional_drawdown,
            },
            "volatility_targeting": vol_report,
            "gap_risk": {
                "expected_gap": gap_profile.expected_gap,
                "tail_gap": gap_profile.tail_gap,
                "crash_gap": gap_profile.crash_gap,
                "overnight_probability": gap_profile.overnight_probability,
                "flash_crash_probability": gap_profile.flash_crash_probability,
                "buffers": gap_buffers,
                "flash_crash_protection": flash_crash,
            },
            "multi_asset_insurance": {
                "total_value": basket.total_value,
                "protected_floor": basket.protected_floor,
                "effective_correlation": basket.effective_correlation,
                "cushion": basket.cushion,
                "risky_budget": basket.risky_budget,
                "asset_allocations": basket.asset_allocations,
                "basket_cppi": basket_cppi,
                "basket_floor_breach_probability": basket_breach_probability,
            },
            "cost_analysis": {
                "cost_breakdown": {
                    "strategy": cost_breakdown.strategy,
                    "explicit_option_cost": cost_breakdown.explicit_option_cost,
                    "carry_cost": cost_breakdown.carry_cost,
                    "financing_cost": cost_breakdown.financing_cost,
                    "turnover_cost": cost_breakdown.turnover_cost,
                    "gap_risk_cost": cost_breakdown.gap_risk_cost,
                    "total_cost": cost_breakdown.total_cost,
                },
                "optimal_protection": optimal_protection,
                "frontier": [
                    {
                        "protection_level": point.protection_level,
                        "expected_cost": point.expected_cost,
                        "floor_value": point.floor_value,
                        "expected_drawdown": point.expected_drawdown,
                        "utility_score": point.utility_score,
                    }
                    for point in frontier
                ],
                "marginal_benefit": marginal_benefit,
            },
            "rebalancing_optimization": {
                "optimal_plan": self.rebalancing_optimizer.schedule_summary(rebalancing_plan),
                "execution_decision": self.rebalancing_optimizer.schedule_summary(execution_plan),
            },
            "regime_adaptive_insurance": regime_policy,
            "strategy_comparison": self.compare_strategies(
                portfolio_value=portfolio_value,
                conditions=conditions,
            ),
        }
