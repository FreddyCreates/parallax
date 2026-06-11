"""Reserve engine for capital, buffer, and solvency management.

The module keeps the original reserve engine API intact while expanding the
implementation into a broader solvency toolkit for an AI-enabled trading fund.
It covers reserve sizing, stress testing, reverse stress testing, capital
allocation, ICAAP-style capital planning, recovery planning, countercyclical
buffering, concentration risk, counterparty risk, capital adequacy ratios, and
forward-looking reserve forecasts.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Iterable, Mapping, Sequence


class ReserveType(str, Enum):
    """Core reserve buckets tracked by the fund."""

    OPERATIONAL = "operational"
    MARKET = "market"
    CREDIT = "credit"
    LIQUIDITY = "liquidity"
    MODEL = "model"
    TECHNOLOGY = "technology"


class StressCategory(str, Enum):
    """High-level classification of stress scenarios."""

    MACRO = "macro"
    FACTOR = "factor"
    CORRELATION = "correlation"
    COMBINED = "combined"
    REVERSE = "reverse"


class RecoveryStage(str, Enum):
    """Escalation stages used in recovery planning."""

    NORMAL = "normal"
    HEIGHTENED = "heightened"
    EARLY_ACTION = "early_action"
    RECOVERY = "recovery"
    RESOLUTION = "resolution"


class CounterpartyQuality(str, Enum):
    """Simplified counterparty credit quality bands."""

    SOVEREIGN = "sovereign"
    INVESTMENT_GRADE = "investment_grade"
    SUB_INVESTMENT_GRADE = "sub_investment_grade"
    DISTRESSED = "distressed"


@dataclass
class ReserveRequirement:
    """Simple reserve requirement record kept for backward compatibility."""

    reserve_type: ReserveType
    amount: float
    confidence_level: float
    holding_period_days: int
    stress_multiplier: float = 1.0


@dataclass
class LossDistribution:
    """Aggregate loss distribution for reserve calculations.

    The class intentionally remains lightweight and deterministic so it can be
    used in API responses and unit tests without heavy dependencies.
    """

    expected_loss: float = 0.0
    unexpected_loss_95: float = 0.0
    unexpected_loss_99: float = 0.0
    catastrophic_loss: float = 0.0
    frequency: float = 0.0
    severity_mean: float = 0.0
    severity_std: float = 0.0

    @classmethod
    def from_historical(cls, losses: list[float]) -> "LossDistribution":
        """Build a loss distribution from historical loss observations."""
        if not losses:
            return cls()

        n = len(losses)
        mean = sum(losses) / n
        variance = sum((x - mean) ** 2 for x in losses) / n
        std = math.sqrt(variance) if variance > 0 else 0.0

        sorted_losses = sorted(losses)
        idx_95 = min(int(0.95 * n), n - 1)
        idx_99 = min(int(0.99 * n), n - 1)

        return cls(
            expected_loss=mean,
            unexpected_loss_95=max(0.0, sorted_losses[idx_95] - mean),
            unexpected_loss_99=max(0.0, sorted_losses[idx_99] - mean),
            catastrophic_loss=max(0.0, sorted_losses[-1]),
            frequency=n / 252.0,
            severity_mean=mean,
            severity_std=std,
        )

    def quantile_loss(self, confidence: float) -> float:
        """Approximate the loss amount at a requested confidence level."""
        if confidence >= 0.99:
            tail_share = (confidence - 0.99) / 0.01 if confidence > 0.99 else 0.0
            return self.expected_loss + self.unexpected_loss_99 + (
                self.catastrophic_loss - self.expected_loss - self.unexpected_loss_99
            ) * self._clamp(tail_share, 0.0, 1.0)

        if confidence >= 0.95:
            share = (confidence - 0.95) / 0.04
            unexpected = self.unexpected_loss_95 + (
                self.unexpected_loss_99 - self.unexpected_loss_95
            ) * self._clamp(share, 0.0, 1.0)
            return self.expected_loss + unexpected

        share = confidence / 0.95 if confidence > 0 else 0.0
        return self.expected_loss * self._clamp(share, 0.0, 1.0)

    def expected_shortfall(self, confidence: float = 0.99) -> float:
        """Approximate expected shortfall from the tracked tail statistics."""
        base = self.quantile_loss(confidence)
        tail_anchor = max(base, self.catastrophic_loss)
        return (base + tail_anchor) / 2.0

    def stressed(
        self,
        multiplier: float,
        tail_multiplier: float = 1.0,
    ) -> "LossDistribution":
        """Return a stressed version of the loss distribution."""
        safe_multiplier = max(0.0, multiplier)
        safe_tail = max(0.0, tail_multiplier)
        return LossDistribution(
            expected_loss=self.expected_loss * safe_multiplier,
            unexpected_loss_95=self.unexpected_loss_95 * safe_multiplier,
            unexpected_loss_99=self.unexpected_loss_99 * safe_tail,
            catastrophic_loss=self.catastrophic_loss * max(safe_multiplier, safe_tail),
            frequency=self.frequency,
            severity_mean=self.severity_mean * safe_multiplier,
            severity_std=self.severity_std * safe_tail,
        )

    @staticmethod
    def _clamp(value: float, lower: float, upper: float) -> float:
        """Clamp a numeric value into a closed interval."""
        return max(lower, min(upper, value))


@dataclass
class StressScenario:
    """Structured scenario definition for reserve stress testing."""

    name: str
    description: str
    category: StressCategory = StressCategory.MACRO
    macro_shocks: dict[str, float] = field(default_factory=dict)
    factor_shocks: dict[str, float] = field(default_factory=dict)
    correlation_multiplier: float = 1.0
    combined_multiplier: float = 1.0
    liquidity_horizon_multiplier: float = 1.0
    wrong_way_multiplier: float = 1.0
    recovery_rate_shift: float = 0.0
    reserve_floors: dict[ReserveType, float] = field(default_factory=dict)

    def scaled(self, multiplier: float) -> "StressScenario":
        """Scale scenario severity for sensitivity and reverse stress analysis."""
        safe = max(0.0, multiplier)
        return StressScenario(
            name=f"{self.name} x{safe:.2f}",
            description=self.description,
            category=self.category,
            macro_shocks={k: v * safe for k, v in self.macro_shocks.items()},
            factor_shocks={k: v * safe for k, v in self.factor_shocks.items()},
            correlation_multiplier=1.0 + (self.correlation_multiplier - 1.0) * safe,
            combined_multiplier=1.0 + (self.combined_multiplier - 1.0) * safe,
            liquidity_horizon_multiplier=(
                1.0 + (self.liquidity_horizon_multiplier - 1.0) * safe
            ),
            wrong_way_multiplier=1.0 + (self.wrong_way_multiplier - 1.0) * safe,
            recovery_rate_shift=self.recovery_rate_shift * safe,
            reserve_floors=self.reserve_floors.copy(),
        )


@dataclass
class StressImpact:
    """Impact of a stress scenario on a single reserve bucket."""

    reserve_type: ReserveType
    baseline_amount: float
    stressed_amount: float
    stress_multiplier: float
    driver_contributions: dict[str, float] = field(default_factory=dict)

    @property
    def delta(self) -> float:
        """Absolute reserve increase created by the scenario."""
        return self.stressed_amount - self.baseline_amount

    @property
    def pct_change(self) -> float:
        """Relative change versus the starting reserve amount."""
        if self.baseline_amount <= 0:
            return 0.0 if self.stressed_amount <= 0 else 1.0
        return self.delta / self.baseline_amount


@dataclass
class StressTestResult:
    """Full result set for a macro, factor, or combined stress test."""

    scenario_name: str
    category: StressCategory
    impacts: list[StressImpact]
    total_baseline: float
    total_stressed: float
    narrative: list[str] = field(default_factory=list)

    @property
    def total_delta(self) -> float:
        """Increase in reserves required under stress."""
        return self.total_stressed - self.total_baseline

    @property
    def worst_reserve_type(self) -> ReserveType | None:
        """Reserve type with the largest stressed increase."""
        if not self.impacts:
            return None
        return max(self.impacts, key=lambda item: item.delta).reserve_type

    def as_dict(self) -> dict[str, Any]:
        """Convert the result into a simple mapping for APIs or serialization."""
        return {
            "scenario_name": self.scenario_name,
            "category": self.category.value,
            "total_baseline": self.total_baseline,
            "total_stressed": self.total_stressed,
            "total_delta": self.total_delta,
            "worst_reserve_type": (
                self.worst_reserve_type.value if self.worst_reserve_type else None
            ),
            "narrative": self.narrative,
            "impacts": [
                {
                    "reserve_type": impact.reserve_type.value,
                    "baseline_amount": impact.baseline_amount,
                    "stressed_amount": impact.stressed_amount,
                    "stress_multiplier": impact.stress_multiplier,
                    "delta": impact.delta,
                    "pct_change": impact.pct_change,
                    "driver_contributions": impact.driver_contributions,
                }
                for impact in self.impacts
            ],
        }


@dataclass
class ReverseStressResult:
    """Outcome of reverse stress testing against a failure threshold."""

    target_metric: str
    threshold: float
    breach_scenarios: list[dict[str, Any]] = field(default_factory=list)
    minimum_breach_multiplier: float | None = None
    critical_losses: list[float] = field(default_factory=list)
    observations: list[str] = field(default_factory=list)


@dataclass
class AllocationInput:
    """Input used by reserve capital allocation optimization routines."""

    name: str
    reserve_amount: float
    expected_return: float
    standalone_risk: float
    diversification_credit: float = 0.0
    liquidity_penalty: float = 0.0
    strategic_weight: float = 1.0


@dataclass
class CapitalAllocationResult:
    """Container for reserve allocation outputs."""

    method: str
    allocations: dict[str, float]
    total_allocated: float
    diversification_benefit: float
    return_on_allocated_capital: float
    commentary: list[str] = field(default_factory=list)


@dataclass
class Pillar2Addon:
    """Pillar 2 capital add-on used within the ICAAP framework."""

    name: str
    amount: float
    rationale: str
    multiplier: float = 1.0

    @property
    def stressed_amount(self) -> float:
        """Amount after applying the management stress multiplier."""
        return self.amount * max(0.0, self.multiplier)


@dataclass
class CapitalPlanPoint:
    """One point on a multi-period capital plan."""

    period: int
    starting_capital: float
    projected_profit: float
    distribution: float
    capital_raised: float
    ending_capital: float
    target_reserves: float
    headroom: float
    stress_headroom: float


@dataclass
class ICAAPAssessment:
    """Internal capital adequacy assessment output."""

    pillar1_capital: float
    pillar2_addons: list[Pillar2Addon]
    management_buffer: float
    internal_capital_target: float
    available_financial_resources: float
    capital_plan: list[CapitalPlanPoint] = field(default_factory=list)
    surplus_deficit: float = 0.0
    adequate: bool = False
    commentary: list[str] = field(default_factory=list)


@dataclass
class RecoveryIndicator:
    """Monitored indicator used in the recovery and resolution framework."""

    name: str
    current_value: float
    early_warning_threshold: float
    breach_threshold: float
    direction: str = "lower_is_worse"
    stage: RecoveryStage = RecoveryStage.NORMAL
    note: str = ""


@dataclass
class RecoveryAction:
    """Action available in the recovery playbook."""

    stage: RecoveryStage
    actions: list[str]
    capital_released: float = 0.0
    days_to_execute: int = 0


@dataclass
class RecoveryPlan:
    """Consolidated recovery plan recommendation."""

    indicators: list[RecoveryIndicator]
    actions: list[RecoveryAction]
    current_stage: RecoveryStage
    estimated_capital_release: float
    resolution_considerations: list[str] = field(default_factory=list)


@dataclass
class WindDownAnalysis:
    """Structured wind-down and orderly resolution analysis."""

    liquidation_value: float
    obligations_covered: float
    shortfall: float
    days_to_exit: float
    residual_risk_buffer: float
    feasible: bool
    commentary: list[str] = field(default_factory=list)


@dataclass
class CountercyclicalBufferAssessment:
    """Assessment of time-varying capital and reserve buffers."""

    cycle_score: float
    buffer_rate: float
    release_rate: float
    adjusted_reserve: float
    commentary: list[str] = field(default_factory=list)


@dataclass
class ConcentrationRiskAssessment:
    """Summary of reserve needs created by concentration risk."""

    single_name_reserve: float
    sector_reserve: float
    geographic_reserve: float
    aggregate_concentration_reserve: float
    hhi: float
    top_exposures: dict[str, float] = field(default_factory=dict)
    commentary: list[str] = field(default_factory=list)


@dataclass
class CounterpartyExposure:
    """Exposure profile needed for simplified CVA and PFE calculations."""

    name: str
    current_exposure: float
    notional: float
    probability_of_default: float
    loss_given_default: float
    tenor_years: float
    credit_spread: float = 0.0
    collateral: float = 0.0
    wrong_way_factor: float = 1.0
    sector: str = "unknown"
    geography: str = "unknown"
    quality: CounterpartyQuality = CounterpartyQuality.INVESTMENT_GRADE


@dataclass
class CounterpartyRiskAssessment:
    """Aggregate counterparty reserve recommendation."""

    total_cva: float
    total_pfe: float
    wrong_way_adjustment: float
    stressed_cva: float
    reserve_recommendation: float
    exposures_by_counterparty: dict[str, dict[str, float]] = field(default_factory=dict)
    commentary: list[str] = field(default_factory=list)


@dataclass
class CapitalAdequacyRatios:
    """Capital adequacy ratios adapted to a trading-fund setting."""

    cet1_ratio: float
    tier1_ratio: float
    total_capital_ratio: float
    leverage_ratio: float
    buffer_ratio: float
    management_target_met: bool
    minimum_requirement_met: bool
    headroom: float
    commentary: list[str] = field(default_factory=list)


@dataclass
class ReserveProjectionPoint:
    """Single period reserve projection for forecasting and planning."""

    period: int
    projected_revenue: float
    projected_losses: float
    baseline_reserve: float
    stressed_reserve: float
    buffer: float
    capital_ratio: float
    scenario_label: str = "base"


@dataclass
class ReserveForecastResult:
    """Forward-looking reserve forecast under baseline and stress assumptions."""

    projections: list[ReserveProjectionPoint]
    peak_reserve: float
    ending_reserve: float
    peak_buffer_draw: float
    adequate_under_stress: bool
    commentary: list[str] = field(default_factory=list)


class ReserveEngine:
    """Capital reserve calculation engine for an AI HFT fund.

    The original reserve calculations are preserved for backwards compatibility.
    Additional methods extend the module into a production-style solvency and
    resilience toolkit that can be used by risk, finance, and treasury teams.
    """

    def __init__(
        self,
        total_capital: float = 10_000_000.0,
        min_reserve_ratio: float = 0.15,
    ) -> None:
        self.total_capital = total_capital
        self.min_reserve_ratio = min_reserve_ratio
        self.reserves: dict[ReserveType, float] = {rt: 0.0 for rt in ReserveType}
        self.loss_history: list[float] = []
        self.stress_scenarios: dict[str, StressScenario] = {}
        self.recovery_actions: list[RecoveryAction] = self._default_recovery_actions()

    def calculate_market_reserve(
        self,
        portfolio_var_99: float,
        stress_factor: float = 3.0,
    ) -> float:
        """Market risk reserve based on stressed 10-day VaR."""
        base_reserve = max(0.0, portfolio_var_99) * math.sqrt(10)
        stressed = base_reserve * max(0.0, stress_factor)
        self.reserves[ReserveType.MARKET] = stressed
        return stressed

    def calculate_operational_reserve(
        self,
        annual_revenue: float,
        loss_events: list[float],
    ) -> float:
        """Operational reserve using a basic indicator and loss data overlay."""
        basic = max(0.0, annual_revenue) * 0.15

        if loss_events:
            dist = LossDistribution.from_historical(loss_events)
            lda_reserve = dist.expected_loss + 2.33 * dist.severity_std * math.sqrt(
                max(dist.frequency, 1.0 / 252.0)
            )
            reserve = max(basic, lda_reserve)
            self.loss_history.extend(loss_events)
        else:
            reserve = basic

        self.reserves[ReserveType.OPERATIONAL] = reserve
        return reserve

    def calculate_model_risk_reserve(
        self,
        strategy_count: int,
        avg_model_uncertainty: float = 0.10,
    ) -> float:
        """Model risk reserve for AI and ML strategy uncertainty."""
        safe_strategy_count = max(1, strategy_count)
        correlation_factor = 1 + math.log(safe_strategy_count) * 0.2
        per_model_reserve = (
            self.total_capital * max(0.0, avg_model_uncertainty) / safe_strategy_count
        )
        total_model_reserve = per_model_reserve * safe_strategy_count * correlation_factor
        self.reserves[ReserveType.MODEL] = total_model_reserve
        return total_model_reserve

    def calculate_liquidity_reserve(
        self,
        daily_volume: float,
        position_size: float,
        market_depth: float,
    ) -> float:
        """Liquidity reserve for market impact and liquidation slippage."""
        safe_daily_volume = max(daily_volume, 1.0)
        safe_market_depth = max(market_depth, 1.0)
        safe_position = max(0.0, position_size)

        days_to_liquidate = safe_position / max(safe_daily_volume * 0.10, 1.0)
        depth_penalty = 1.0 + safe_position / safe_market_depth
        impact_cost = 0.1 * math.sqrt(safe_position / safe_daily_volume) * safe_position
        liquidity_reserve = impact_cost * days_to_liquidate * depth_penalty
        self.reserves[ReserveType.LIQUIDITY] = liquidity_reserve
        return liquidity_reserve

    def calculate_technology_reserve(self, annual_tech_spend: float) -> float:
        """Technology failure reserve for outages, cyber events, and vendor risk."""
        tech_reserve = max(0.0, annual_tech_spend) * 0.30
        self.reserves[ReserveType.TECHNOLOGY] = tech_reserve
        return tech_reserve

    def calculate_credit_reserve(
        self,
        exposures: Sequence[CounterpartyExposure],
        concentration_addon: float = 0.0,
        market_stress: float = 0.0,
    ) -> float:
        """Credit reserve using CVA, PFE, and concentration overlays."""
        assessment = self.counterparty_risk_assessment(
            exposures,
            market_stress=market_stress,
        )
        credit_reserve = assessment.reserve_recommendation + max(0.0, concentration_addon)
        self.reserves[ReserveType.CREDIT] = credit_reserve
        return credit_reserve

    def total_required_reserves(self) -> dict[str, Any]:
        """Calculate total reserve requirements across tracked reserve buckets."""
        total = sum(self.reserves.values())
        min_required = self.total_capital * self.min_reserve_ratio

        return {
            "reserves_by_type": {rt.value: amt for rt, amt in self.reserves.items()},
            "total_reserves": total,
            "minimum_required": min_required,
            "surplus_deficit": total - min_required,
            "reserve_ratio": total / self.total_capital if self.total_capital > 0 else 0,
            "capital_adequacy": total >= min_required,
            "deployable_capital": self.total_capital - total,
        }

    def register_loss(self, amount: float) -> None:
        """Record a realized loss for later reserve analytics."""
        if amount > 0:
            self.loss_history.append(amount)

    def build_loss_distribution(self) -> LossDistribution:
        """Build a loss distribution from the internally stored loss history."""
        return LossDistribution.from_historical(self.loss_history)

    def register_stress_scenario(self, scenario: StressScenario) -> None:
        """Register a reusable scenario in the local scenario library."""
        self.stress_scenarios[scenario.name] = scenario

    def create_macro_stress_scenario(
        self,
        name: str,
        description: str,
        gdp_shock: float = 0.0,
        volatility_shock: float = 0.0,
        spread_shock: float = 0.0,
        liquidity_shock: float = 0.0,
        operational_shock: float = 0.0,
        model_error_shock: float = 0.0,
        correlation_shock: float = 0.0,
        counterparty_shock: float = 0.0,
        concentration_shock: float = 0.0,
    ) -> StressScenario:
        """Create and store a macro stress scenario in one step."""
        scenario = StressScenario(
            name=name,
            description=description,
            category=StressCategory.MACRO,
            macro_shocks={
                "gdp": gdp_shock,
                "volatility": volatility_shock,
                "spread": spread_shock,
                "liquidity": liquidity_shock,
                "operational": operational_shock,
                "model_error": model_error_shock,
                "counterparty": counterparty_shock,
                "concentration": concentration_shock,
            },
            correlation_multiplier=max(0.0, 1.0 + correlation_shock),
            combined_multiplier=1.0,
            liquidity_horizon_multiplier=max(0.0, 1.0 + liquidity_shock),
            wrong_way_multiplier=max(0.0, 1.0 + counterparty_shock),
        )
        self.register_stress_scenario(scenario)
        return scenario

    def run_macro_stress_test(
        self,
        baseline_reserves: Mapping[ReserveType | str, float] | None = None,
        scenario: StressScenario | None = None,
    ) -> StressTestResult:
        """Run a macro scenario against the reserve stack."""
        scenario_to_run = scenario or self.stress_scenarios.get("baseline_macro")
        if scenario_to_run is None:
            scenario_to_run = StressScenario(
                name="default_macro",
                description="Default macro stress with moderate volatility and spread shocks.",
                category=StressCategory.MACRO,
                macro_shocks={"volatility": 0.25, "spread": 0.10, "liquidity": 0.10},
                correlation_multiplier=1.15,
                liquidity_horizon_multiplier=1.20,
            )

        normalized = self._normalize_reserve_mapping(baseline_reserves)
        impacts: list[StressImpact] = []
        narrative: list[str] = []

        for reserve_type, baseline_amount in normalized.items():
            stressed_amount, multiplier, drivers = self._stress_amount(
                reserve_type,
                baseline_amount,
                scenario_to_run,
            )
            impacts.append(
                StressImpact(
                    reserve_type=reserve_type,
                    baseline_amount=baseline_amount,
                    stressed_amount=stressed_amount,
                    stress_multiplier=multiplier,
                    driver_contributions=drivers,
                )
            )

        if scenario_to_run.macro_shocks.get("volatility", 0.0) > 0:
            narrative.append("Market and liquidity reserves respond strongly to volatility stress.")
        if scenario_to_run.macro_shocks.get("counterparty", 0.0) > 0:
            narrative.append("Counterparty shocks feed directly into credit reserve inflation.")
        if scenario_to_run.correlation_multiplier > 1.0:
            narrative.append("Correlation breakdown reduces diversification benefits.")

        total_baseline = sum(item.baseline_amount for item in impacts)
        total_stressed = sum(item.stressed_amount for item in impacts)
        return StressTestResult(
            scenario_name=scenario_to_run.name,
            category=scenario_to_run.category,
            impacts=impacts,
            total_baseline=total_baseline,
            total_stressed=total_stressed,
            narrative=narrative,
        )

    def run_factor_stress_test(
        self,
        exposures: Mapping[str, float],
        factor_shocks: Mapping[str, float],
        factor_elasticities: Mapping[str, Mapping[ReserveType, float]] | None = None,
        reserve_base: Mapping[ReserveType | str, float] | None = None,
    ) -> StressTestResult:
        """Apply factor shocks to reserve buckets using configurable elasticities."""
        normalized = self._normalize_reserve_mapping(reserve_base)
        elasticities = self._default_factor_elasticities()
        if factor_elasticities:
            for factor, mapping in factor_elasticities.items():
                elasticities[factor] = dict(mapping)

        impacts: list[StressImpact] = []
        for reserve_type, baseline_amount in normalized.items():
            multiplier = 1.0
            drivers: dict[str, float] = {}
            for factor_name, shock in factor_shocks.items():
                elasticity = elasticities.get(factor_name, {}).get(reserve_type, 0.0)
                exposure_scale = max(0.0, exposures.get(factor_name, 1.0))
                effect = shock * elasticity * max(0.25, exposure_scale)
                drivers[factor_name] = effect
                multiplier += effect

            stressed_amount = max(0.0, baseline_amount * max(0.0, multiplier))
            impacts.append(
                StressImpact(
                    reserve_type=reserve_type,
                    baseline_amount=baseline_amount,
                    stressed_amount=stressed_amount,
                    stress_multiplier=max(0.0, multiplier),
                    driver_contributions=drivers,
                )
            )

        narrative = [
            "Factor stress test applies risk-driver elasticities to baseline reserves.",
            "Use this framework to test volatility, spread, model drift, funding, or basis shocks.",
        ]
        return StressTestResult(
            scenario_name="factor_stress",
            category=StressCategory.FACTOR,
            impacts=impacts,
            total_baseline=sum(item.baseline_amount for item in impacts),
            total_stressed=sum(item.stressed_amount for item in impacts),
            narrative=narrative,
        )

    def run_correlation_stress_test(
        self,
        strategy_returns: Mapping[str, Sequence[float]],
        stressed_correlation: float = 0.85,
    ) -> dict[str, Any]:
        """Estimate diversification loss under elevated strategy correlations."""
        risk_vector: dict[str, float] = {}
        names = list(strategy_returns.keys())
        for name, returns in strategy_returns.items():
            risk_vector[name] = self._series_std(returns) * math.sqrt(252)

        base_corr = self.estimate_correlation_matrix(strategy_returns)
        stressed_corr = {
            left: {
                right: (
                    1.0
                    if left == right
                    else max(base_corr[left][right], self._clamp(stressed_correlation, -1.0, 1.0))
                )
                for right in names
            }
            for left in names
        }

        base_risk = self._portfolio_risk(risk_vector, base_corr)
        stressed_risk = self._portfolio_risk(risk_vector, stressed_corr)
        diversification_loss = max(0.0, stressed_risk - base_risk)

        return {
            "base_portfolio_risk": base_risk,
            "stressed_portfolio_risk": stressed_risk,
            "diversification_loss": diversification_loss,
            "base_correlation_matrix": base_corr,
            "stressed_correlation_matrix": stressed_corr,
            "capital_multiplier": (
                stressed_risk / base_risk if base_risk > 0 else 1.0
            ),
        }

    def run_combined_stress_test(
        self,
        baseline_reserves: Mapping[ReserveType | str, float] | None,
        scenario: StressScenario,
        exposures: Mapping[str, float] | None = None,
        factor_shocks: Mapping[str, float] | None = None,
        strategy_returns: Mapping[str, Sequence[float]] | None = None,
    ) -> dict[str, Any]:
        """Combine macro, factor, and correlation stress tests into one framework."""
        macro_result = self.run_macro_stress_test(baseline_reserves, scenario)
        factor_result = self.run_factor_stress_test(
            exposures or {},
            factor_shocks or scenario.factor_shocks,
            reserve_base={
                impact.reserve_type: impact.stressed_amount for impact in macro_result.impacts
            },
        )

        correlation_result = (
            self.run_correlation_stress_test(strategy_returns)
            if strategy_returns
            else {
                "base_portfolio_risk": 0.0,
                "stressed_portfolio_risk": 0.0,
                "diversification_loss": 0.0,
                "capital_multiplier": 1.0,
            }
        )

        total_combined = factor_result.total_stressed + correlation_result["diversification_loss"]
        baseline_total = macro_result.total_baseline
        return {
            "macro": macro_result.as_dict(),
            "factor": factor_result.as_dict(),
            "correlation": correlation_result,
            "combined_total": total_combined,
            "combined_delta": total_combined - baseline_total,
            "combined_multiplier": (
                total_combined / baseline_total if baseline_total > 0 else 1.0
            ),
        }

    def reverse_stress_test(
        self,
        available_capital: float,
        scenarios: Sequence[StressScenario],
        baseline_reserves: Mapping[ReserveType | str, float] | None = None,
        failure_threshold: float | None = None,
        step: float = 0.1,
        max_multiplier: float = 5.0,
    ) -> ReverseStressResult:
        """Find scenario severities that cause reserve adequacy failure."""
        threshold = (
            failure_threshold
            if failure_threshold is not None
            else available_capital * max(self.min_reserve_ratio, 0.01)
        )
        normalized = self._normalize_reserve_mapping(baseline_reserves)
        breach_scenarios: list[dict[str, Any]] = []
        minimum_breach_multiplier: float | None = None
        observations: list[str] = []

        for scenario in scenarios:
            multiplier = step
            while multiplier <= max_multiplier + 1e-9:
                stressed_result = self.run_macro_stress_test(
                    normalized,
                    scenario.scaled(multiplier),
                )
                stressed_total = stressed_result.total_stressed
                if stressed_total >= threshold:
                    breach_scenarios.append(
                        {
                            "scenario": scenario.name,
                            "breach_multiplier": multiplier,
                            "stressed_total": stressed_total,
                            "threshold": threshold,
                            "shortfall": stressed_total - threshold,
                            "worst_reserve_type": (
                                stressed_result.worst_reserve_type.value
                                if stressed_result.worst_reserve_type
                                else None
                            ),
                        }
                    )
                    if minimum_breach_multiplier is None:
                        minimum_breach_multiplier = multiplier
                    else:
                        minimum_breach_multiplier = min(
                            minimum_breach_multiplier,
                            multiplier,
                        )
                    break
                multiplier += step

        if breach_scenarios:
            observations.append("At least one scenario can exhaust the available reserve threshold.")
        else:
            observations.append("No scenario breached the target threshold within the tested range.")

        return ReverseStressResult(
            target_metric="total_reserves",
            threshold=threshold,
            breach_scenarios=breach_scenarios,
            minimum_breach_multiplier=minimum_breach_multiplier,
            critical_losses=self.identify_critical_losses(self.loss_history, threshold),
            observations=observations,
        )

    def threshold_analysis(
        self,
        values: Sequence[float],
        threshold: float,
        higher_is_worse: bool = True,
    ) -> dict[str, Any]:
        """Identify when a metric first breaches a management threshold."""
        breach_index: int | None = None
        for index, value in enumerate(values):
            breached = value >= threshold if higher_is_worse else value <= threshold
            if breached:
                breach_index = index
                break

        return {
            "threshold": threshold,
            "higher_is_worse": higher_is_worse,
            "breach_index": breach_index,
            "breach_value": values[breach_index] if breach_index is not None else None,
            "distance_to_threshold": (
                values[-1] - threshold if values else -threshold
            ),
        }

    def identify_critical_losses(
        self,
        losses: Sequence[float],
        threshold: float,
        top_n: int = 5,
    ) -> list[float]:
        """Identify the largest realized or assumed losses relevant to failure."""
        if not losses:
            return []
        sorted_losses = sorted((max(0.0, loss) for loss in losses), reverse=True)
        critical = [loss for loss in sorted_losses if loss >= threshold]
        if critical:
            return critical[:top_n]
        return sorted_losses[:top_n]

    def euler_capital_allocation(
        self,
        standalone_risks: Mapping[str, float],
        correlation_matrix: Mapping[str, Mapping[str, float]],
    ) -> CapitalAllocationResult:
        """Allocate reserve capital using Euler marginal contributions."""
        total_risk = self._portfolio_risk(standalone_risks, correlation_matrix)
        allocations: dict[str, float] = {}
        for name, amount in standalone_risks.items():
            marginal = 0.0
            for other_name, other_amount in standalone_risks.items():
                corr = self._matrix_value(correlation_matrix, name, other_name, default=0.0)
                if name == other_name:
                    corr = 1.0
                marginal += corr * other_amount
            contribution = amount * marginal / total_risk if total_risk > 0 else 0.0
            allocations[name] = max(0.0, contribution)

        diversification = max(0.0, sum(standalone_risks.values()) - total_risk)
        return CapitalAllocationResult(
            method="euler",
            allocations=allocations,
            total_allocated=sum(allocations.values()),
            diversification_benefit=diversification,
            return_on_allocated_capital=0.0,
            commentary=[
                "Euler allocation measures each component's marginal contribution to total risk.",
            ],
        )

    def shapley_value_allocation(
        self,
        standalone_risks: Mapping[str, float],
        correlation_matrix: Mapping[str, Mapping[str, float]],
    ) -> CapitalAllocationResult:
        """Allocate reserve capital with a Shapley-value diversification approach."""
        names = list(standalone_risks.keys())
        n = len(names)
        if n == 0:
            return CapitalAllocationResult(
                method="shapley",
                allocations={},
                total_allocated=0.0,
                diversification_benefit=0.0,
                return_on_allocated_capital=0.0,
            )

        factorial_n = math.factorial(n)
        allocations = {name: 0.0 for name in names}

        for bitmask in range(1 << n):
            subset = [names[idx] for idx in range(n) if bitmask & (1 << idx)]
            subset_size = len(subset)
            for idx, name in enumerate(names):
                if bitmask & (1 << idx):
                    continue
                expanded_subset = subset + [name]
                weight = (
                    math.factorial(subset_size)
                    * math.factorial(n - subset_size - 1)
                    / factorial_n
                )
                marginal = self._subset_portfolio_risk(
                    expanded_subset,
                    standalone_risks,
                    correlation_matrix,
                ) - self._subset_portfolio_risk(
                    subset,
                    standalone_risks,
                    correlation_matrix,
                )
                allocations[name] += weight * marginal

        total_risk = self._portfolio_risk(standalone_risks, correlation_matrix)
        diversification = max(0.0, sum(standalone_risks.values()) - total_risk)
        return CapitalAllocationResult(
            method="shapley",
            allocations=allocations,
            total_allocated=sum(allocations.values()),
            diversification_benefit=diversification,
            return_on_allocated_capital=0.0,
            commentary=[
                "Shapley allocation distributes diversification gains across reserve consumers.",
            ],
        )

    def optimize_risk_return_reserves(
        self,
        opportunities: Sequence[AllocationInput],
        total_reserve_budget: float,
        minimum_allocations: Mapping[str, float] | None = None,
    ) -> CapitalAllocationResult:
        """Allocate reserve budget to maximize risk-adjusted strategic benefit."""
        minimum_allocations = minimum_allocations or {}
        allocations = {
            item.name: min(max(0.0, minimum_allocations.get(item.name, 0.0)), item.reserve_amount)
            for item in opportunities
        }
        remaining = max(0.0, total_reserve_budget - sum(allocations.values()))

        scored_items: list[tuple[float, AllocationInput]] = []
        for item in opportunities:
            effective_risk = max(
                1e-9,
                item.standalone_risk - item.diversification_credit + item.liquidity_penalty,
            )
            score = item.expected_return * max(0.0, item.strategic_weight) / effective_risk
            scored_items.append((score, item))

        scored_items.sort(key=lambda item: item[0], reverse=True)
        for _score, item in scored_items:
            if remaining <= 0:
                break
            already_allocated = allocations[item.name]
            capacity = max(0.0, item.reserve_amount - already_allocated)
            add_amount = min(capacity, remaining)
            allocations[item.name] += add_amount
            remaining -= add_amount

        total_allocated = sum(allocations.values())
        weighted_return = 0.0
        diversification = 0.0
        for item in opportunities:
            allocation = allocations.get(item.name, 0.0)
            scale = allocation / item.reserve_amount if item.reserve_amount > 0 else 0.0
            weighted_return += item.expected_return * scale
            diversification += item.diversification_credit * scale

        return CapitalAllocationResult(
            method="risk_return_optimization",
            allocations=allocations,
            total_allocated=total_allocated,
            diversification_benefit=max(0.0, diversification),
            return_on_allocated_capital=(
                weighted_return / total_allocated if total_allocated > 0 else 0.0
            ),
            commentary=[
                "Optimization ranks reserve uses by expected return per unit of effective risk.",
            ],
        )

    def calculate_pillar2_addons(
        self,
        governance_score: float,
        model_complexity_score: float,
        concentration_score: float,
        outsourcing_score: float,
    ) -> list[Pillar2Addon]:
        """Derive Pillar 2 add-ons from qualitative and quantitative risk scores."""
        capital_base = max(self.total_capital, 1.0)
        return [
            Pillar2Addon(
                name="governance",
                amount=capital_base * 0.01 * self._clamp(governance_score, 0.0, 2.0),
                rationale="Governance weaknesses increase execution and oversight risk.",
            ),
            Pillar2Addon(
                name="model_complexity",
                amount=(
                    capital_base * 0.012 * self._clamp(model_complexity_score, 0.0, 2.0)
                ),
                rationale="Complex AI model stacks raise validation and model drift risk.",
            ),
            Pillar2Addon(
                name="concentration",
                amount=(
                    capital_base * 0.008 * self._clamp(concentration_score, 0.0, 2.0)
                ),
                rationale="Concentration can cause losses that Pillar 1 metrics understate.",
            ),
            Pillar2Addon(
                name="outsourcing",
                amount=(
                    capital_base * 0.006 * self._clamp(outsourcing_score, 0.0, 2.0)
                ),
                rationale="Cloud, market-data, and vendor dependence require extra capital.",
            ),
        ]

    def run_icaap_assessment(
        self,
        pillar1_capital: float,
        pillar2_addons: Sequence[Pillar2Addon],
        available_financial_resources: float | None = None,
        management_buffer_ratio: float = 0.10,
        stress_results: Sequence[StressTestResult] | None = None,
        capital_plan: Sequence[CapitalPlanPoint] | None = None,
    ) -> ICAAPAssessment:
        """Run an ICAAP-style adequacy assessment with Pillar 2 overlays."""
        available = (
            available_financial_resources
            if available_financial_resources is not None
            else self.total_capital
        )
        addon_total = sum(addon.stressed_amount for addon in pillar2_addons)
        stress_overlay = 0.0
        if stress_results:
            stress_overlay = max(max(0.0, result.total_delta) for result in stress_results)
        management_buffer = max(0.0, pillar1_capital + addon_total + stress_overlay) * max(
            0.0,
            management_buffer_ratio,
        )
        internal_target = pillar1_capital + addon_total + stress_overlay + management_buffer
        surplus_deficit = available - internal_target
        adequate = surplus_deficit >= 0

        commentary = [
            "ICAAP combines regulatory capital, Pillar 2 add-ons, stress overlays, and a management buffer.",
        ]
        if adequate:
            commentary.append("Available financial resources cover the internal capital target.")
        else:
            commentary.append("Capital resources are below the internally assessed requirement.")

        return ICAAPAssessment(
            pillar1_capital=max(0.0, pillar1_capital),
            pillar2_addons=list(pillar2_addons),
            management_buffer=management_buffer,
            internal_capital_target=internal_target,
            available_financial_resources=max(0.0, available),
            capital_plan=list(capital_plan or []),
            surplus_deficit=surplus_deficit,
            adequate=adequate,
            commentary=commentary,
        )

    def capital_planning(
        self,
        starting_capital: float,
        projected_profits: Sequence[float],
        payout_ratio: float,
        reserve_targets: Sequence[float],
        stress_losses: Sequence[float] | None = None,
        capital_raises: Sequence[float] | None = None,
    ) -> list[CapitalPlanPoint]:
        """Build a simple multi-period capital plan for ICAAP and budgeting."""
        plan: list[CapitalPlanPoint] = []
        capital = max(0.0, starting_capital)
        stress_losses = list(stress_losses or [0.0] * len(projected_profits))
        capital_raises = list(capital_raises or [0.0] * len(projected_profits))

        for period, profit in enumerate(projected_profits, start=1):
            distribution = max(0.0, profit) * self._clamp(payout_ratio, 0.0, 1.0)
            capital_raise = capital_raises[period - 1] if period - 1 < len(capital_raises) else 0.0
            stress_loss = stress_losses[period - 1] if period - 1 < len(stress_losses) else 0.0
            target_reserve = (
                reserve_targets[period - 1]
                if period - 1 < len(reserve_targets)
                else reserve_targets[-1]
            )
            ending_capital = capital + profit - distribution + capital_raise
            headroom = ending_capital - target_reserve
            stress_headroom = ending_capital - target_reserve - max(0.0, stress_loss)
            plan.append(
                CapitalPlanPoint(
                    period=period,
                    starting_capital=capital,
                    projected_profit=profit,
                    distribution=distribution,
                    capital_raised=capital_raise,
                    ending_capital=ending_capital,
                    target_reserves=target_reserve,
                    headroom=headroom,
                    stress_headroom=stress_headroom,
                )
            )
            capital = ending_capital

        return plan

    def evaluate_recovery_indicators(
        self,
        indicators: Mapping[str, tuple[float, float, float, str]],
    ) -> list[RecoveryIndicator]:
        """Evaluate recovery indicators against early warning and breach thresholds."""
        results: list[RecoveryIndicator] = []
        for name, params in indicators.items():
            current_value, early_warning, breach, direction = params
            if direction == "lower_is_worse":
                if current_value <= breach:
                    stage = RecoveryStage.RECOVERY
                elif current_value <= early_warning:
                    stage = RecoveryStage.EARLY_ACTION
                else:
                    stage = RecoveryStage.NORMAL
            else:
                if current_value >= breach:
                    stage = RecoveryStage.RECOVERY
                elif current_value >= early_warning:
                    stage = RecoveryStage.EARLY_ACTION
                else:
                    stage = RecoveryStage.NORMAL

            results.append(
                RecoveryIndicator(
                    name=name,
                    current_value=current_value,
                    early_warning_threshold=early_warning,
                    breach_threshold=breach,
                    direction=direction,
                    stage=stage,
                    note=f"Indicator {name} evaluated under {direction} logic.",
                )
            )
        return results

    def build_recovery_plan(
        self,
        indicators: Sequence[RecoveryIndicator],
        extra_actions: Sequence[RecoveryAction] | None = None,
    ) -> RecoveryPlan:
        """Build a recovery plan based on indicator escalation stages."""
        available_actions = list(self.recovery_actions)
        if extra_actions:
            available_actions.extend(extra_actions)

        stage_order = {
            RecoveryStage.NORMAL: 0,
            RecoveryStage.HEIGHTENED: 1,
            RecoveryStage.EARLY_ACTION: 2,
            RecoveryStage.RECOVERY: 3,
            RecoveryStage.RESOLUTION: 4,
        }
        current_stage = RecoveryStage.NORMAL
        for indicator in indicators:
            if stage_order[indicator.stage] > stage_order[current_stage]:
                current_stage = indicator.stage

        actions = [
            action for action in available_actions if stage_order[action.stage] <= stage_order[current_stage]
        ]
        estimated_release = sum(action.capital_released for action in actions)
        considerations = self.resolution_planning(indicators)

        return RecoveryPlan(
            indicators=list(indicators),
            actions=actions,
            current_stage=current_stage,
            estimated_capital_release=estimated_release,
            resolution_considerations=considerations,
        )

    def resolution_planning(
        self,
        indicators: Sequence[RecoveryIndicator],
    ) -> list[str]:
        """Produce concise resolution-planning notes based on indicator severity."""
        considerations: list[str] = []
        for indicator in indicators:
            if indicator.stage == RecoveryStage.RECOVERY:
                considerations.append(
                    f"Prepare resolution options if {indicator.name} remains beyond breach threshold."
                )
            elif indicator.stage == RecoveryStage.EARLY_ACTION:
                considerations.append(
                    f"Escalate governance review for {indicator.name} and pre-position recovery actions."
                )

        if not considerations:
            considerations.append("No immediate resolution planning actions are required.")
        return considerations

    def wind_down_analysis(
        self,
        position_values: Mapping[str, float],
        obligations: float,
        liquidation_haircut: float = 0.10,
        operational_runoff_cost: float = 0.0,
        daily_exit_rate: float = 0.20,
    ) -> WindDownAnalysis:
        """Estimate orderly wind-down capacity and residual risk needs."""
        gross_value = sum(max(0.0, value) for value in position_values.values())
        liquidation_value = gross_value * (1.0 - self._clamp(liquidation_haircut, 0.0, 0.95))
        obligations_covered = liquidation_value - max(0.0, operational_runoff_cost)
        shortfall = max(0.0, obligations - obligations_covered)
        days_to_exit = 1.0 / max(daily_exit_rate, 1e-9)
        residual_buffer = shortfall + gross_value * 0.02
        commentary = [
            "Wind-down analysis applies liquidation haircuts and runoff costs to asset values.",
        ]
        if shortfall > 0:
            commentary.append("Wind-down resources do not fully cover obligations.")
        else:
            commentary.append("Wind-down appears feasible without an external capital backstop.")

        return WindDownAnalysis(
            liquidation_value=liquidation_value,
            obligations_covered=obligations_covered,
            shortfall=shortfall,
            days_to_exit=days_to_exit,
            residual_risk_buffer=residual_buffer,
            feasible=shortfall <= 0,
            commentary=commentary,
        )

    def calculate_countercyclical_buffer(
        self,
        credit_growth_gap: float,
        pnl_volatility: float,
        liquidity_regime_score: float,
        current_buffer_rate: float = 0.0,
        max_buffer_rate: float = 0.025,
        base_reserve: float | None = None,
    ) -> CountercyclicalBufferAssessment:
        """Calculate a dynamic countercyclical buffer for reserves and capital."""
        cycle_score = (
            0.5 * max(0.0, credit_growth_gap)
            + 0.3 * max(0.0, pnl_volatility)
            + 0.2 * max(0.0, liquidity_regime_score)
        )
        target_buffer = self._clamp(cycle_score * 0.01, 0.0, max_buffer_rate)
        release_rate = max(0.0, current_buffer_rate - target_buffer)
        reserve_base = base_reserve if base_reserve is not None else sum(self.reserves.values())
        adjusted_reserve = max(0.0, reserve_base * (1.0 + target_buffer))
        commentary = [
            "Countercyclical buffers rise in benign expansions and can be released in downturns.",
        ]
        if target_buffer > current_buffer_rate:
            commentary.append("Buffer build-up is recommended to mitigate future pro-cyclicality.")
        elif release_rate > 0:
            commentary.append("A partial buffer release can support resilience during stress.")

        return CountercyclicalBufferAssessment(
            cycle_score=cycle_score,
            buffer_rate=target_buffer,
            release_rate=release_rate,
            adjusted_reserve=adjusted_reserve,
            commentary=commentary,
        )

    def dynamic_reserve_adjustment(
        self,
        base_reserve: float,
        buffer_assessment: CountercyclicalBufferAssessment,
        earnings_capacity: float,
    ) -> float:
        """Adjust reserves dynamically with attention to earnings absorption capacity."""
        target = base_reserve * (1.0 + buffer_assessment.buffer_rate)
        earnings_offset = max(0.0, earnings_capacity) * 0.25
        return max(base_reserve, target - earnings_offset)

    def test_buffer_adequacy(
        self,
        base_reserve: float,
        scenario_losses: Sequence[float],
        buffer_rate: float,
    ) -> dict[str, Any]:
        """Test whether a reserve buffer is adequate across adverse scenarios."""
        reserve_with_buffer = max(0.0, base_reserve) * (1.0 + max(0.0, buffer_rate))
        breaches = [loss for loss in scenario_losses if loss > reserve_with_buffer]
        return {
            "reserve_with_buffer": reserve_with_buffer,
            "breach_count": len(breaches),
            "max_breach": max((loss - reserve_with_buffer) for loss in breaches) if breaches else 0.0,
            "adequate": not breaches,
        }

    def single_name_concentration_reserve(
        self,
        exposures: Mapping[str, float],
        threshold_ratio: float = 0.10,
        penalty_multiplier: float = 0.50,
    ) -> float:
        """Calculate reserve for outsized exposure to single names."""
        total = sum(max(0.0, value) for value in exposures.values())
        if total <= 0:
            return 0.0
        threshold = total * max(0.0, threshold_ratio)
        reserve = 0.0
        for value in exposures.values():
            excess = max(0.0, value - threshold)
            reserve += excess * max(0.0, penalty_multiplier)
        return reserve

    def sector_concentration_reserve(
        self,
        sector_exposures: Mapping[str, float],
        threshold_ratio: float = 0.25,
        penalty_multiplier: float = 0.25,
    ) -> float:
        """Calculate reserve for excessive sector concentration."""
        total = sum(max(0.0, value) for value in sector_exposures.values())
        if total <= 0:
            return 0.0
        reserve = 0.0
        for value in sector_exposures.values():
            ratio = value / total
            reserve += max(0.0, ratio - threshold_ratio) * total * max(0.0, penalty_multiplier)
        return reserve

    def geographic_concentration_reserve(
        self,
        geography_exposures: Mapping[str, float],
        threshold_ratio: float = 0.35,
        penalty_multiplier: float = 0.20,
    ) -> float:
        """Calculate reserve for geographic concentration risk."""
        total = sum(max(0.0, value) for value in geography_exposures.values())
        if total <= 0:
            return 0.0
        reserve = 0.0
        for value in geography_exposures.values():
            ratio = value / total
            reserve += max(0.0, ratio - threshold_ratio) * total * max(0.0, penalty_multiplier)
        return reserve

    def concentration_risk_assessment(
        self,
        single_name_exposures: Mapping[str, float],
        sector_exposures: Mapping[str, float],
        geography_exposures: Mapping[str, float],
    ) -> ConcentrationRiskAssessment:
        """Assess concentration reserve needs across names, sectors, and geographies."""
        single_name = self.single_name_concentration_reserve(single_name_exposures)
        sector = self.sector_concentration_reserve(sector_exposures)
        geography = self.geographic_concentration_reserve(geography_exposures)
        top_exposures = dict(
            sorted(single_name_exposures.items(), key=lambda item: item[1], reverse=True)[:5]
        )
        hhi = self._herfindahl_index(single_name_exposures.values())
        aggregate = single_name + sector + geography
        commentary = [
            "Concentration reserves cover single-name, sector, and geography clustering.",
        ]
        if hhi > 0.18:
            commentary.append("Portfolio concentration is elevated on an HHI basis.")

        return ConcentrationRiskAssessment(
            single_name_reserve=single_name,
            sector_reserve=sector,
            geographic_reserve=geography,
            aggregate_concentration_reserve=aggregate,
            hhi=hhi,
            top_exposures=top_exposures,
            commentary=commentary,
        )

    def calculate_potential_future_exposure(
        self,
        current_exposure: float,
        notional: float,
        tenor_years: float,
        volatility: float,
        netting_benefit: float = 0.0,
    ) -> float:
        """Calculate simplified potential future exposure for a counterparty."""
        addon = max(0.0, notional) * max(0.0, volatility) * math.sqrt(max(tenor_years, 0.0)) * 0.25
        gross = max(0.0, current_exposure) + addon
        return max(0.0, gross - max(0.0, netting_benefit))

    def calculate_cva(
        self,
        exposures: Sequence[CounterpartyExposure],
        risk_free_rate: float = 0.02,
    ) -> CounterpartyRiskAssessment:
        """Calculate deterministic CVA and reserve recommendation for counterparties."""
        total_cva = 0.0
        total_pfe = 0.0
        wrong_way_adjustment = 0.0
        details: dict[str, dict[str, float]] = {}

        for exposure in exposures:
            pfe = self.calculate_potential_future_exposure(
                exposure.current_exposure,
                exposure.notional,
                exposure.tenor_years,
                max(0.05, exposure.credit_spread if exposure.credit_spread > 0 else 0.10),
                netting_benefit=exposure.collateral,
            )
            effective_exposure = max(0.0, exposure.current_exposure - exposure.collateral) + 0.5 * pfe
            discount = math.exp(-max(0.0, risk_free_rate) * max(0.0, exposure.tenor_years))
            cva = (
                effective_exposure
                * max(0.0, exposure.probability_of_default)
                * max(0.0, exposure.loss_given_default)
                * discount
            )
            wrong_way = cva * max(0.0, exposure.wrong_way_factor - 1.0)
            total_cva += cva
            total_pfe += pfe
            wrong_way_adjustment += wrong_way
            details[exposure.name] = {
                "pfe": pfe,
                "effective_exposure": effective_exposure,
                "cva": cva,
                "wrong_way_adjustment": wrong_way,
            }

        stressed_cva = total_cva + wrong_way_adjustment
        reserve_recommendation = stressed_cva + 0.10 * total_pfe
        commentary = [
            "Counterparty reserve combines CVA, PFE, and wrong-way risk adjustments.",
        ]

        return CounterpartyRiskAssessment(
            total_cva=total_cva,
            total_pfe=total_pfe,
            wrong_way_adjustment=wrong_way_adjustment,
            stressed_cva=stressed_cva,
            reserve_recommendation=reserve_recommendation,
            exposures_by_counterparty=details,
            commentary=commentary,
        )

    def wrong_way_risk_adjustment(
        self,
        base_cva: float,
        stress_correlation: float,
    ) -> float:
        """Apply a wrong-way risk adjustment to base CVA."""
        multiplier = 1.0 + max(0.0, stress_correlation) * 0.75
        return max(0.0, base_cva) * multiplier

    def counterparty_risk_assessment(
        self,
        exposures: Sequence[CounterpartyExposure],
        market_stress: float = 0.0,
    ) -> CounterpartyRiskAssessment:
        """Full counterparty risk assessment with wrong-way stress overlay."""
        base = self.calculate_cva(exposures)
        stressed_cva = self.wrong_way_risk_adjustment(base.stressed_cva, market_stress)
        reserve_recommendation = stressed_cva + 0.10 * base.total_pfe
        commentary = list(base.commentary)
        if market_stress > 0:
            commentary.append("Market stress amplifies wrong-way risk and CVA reserve needs.")

        return CounterpartyRiskAssessment(
            total_cva=base.total_cva,
            total_pfe=base.total_pfe,
            wrong_way_adjustment=max(0.0, stressed_cva - base.total_cva),
            stressed_cva=stressed_cva,
            reserve_recommendation=reserve_recommendation,
            exposures_by_counterparty=base.exposures_by_counterparty,
            commentary=commentary,
        )

    def calculate_capital_adequacy_ratios(
        self,
        cet1_capital: float,
        additional_tier1: float,
        tier2_capital: float,
        risk_weighted_assets: float,
        leverage_exposure: float,
        conservation_buffer: float = 0.025,
        management_target: float = 0.12,
    ) -> CapitalAdequacyRatios:
        """Calculate CET1, Tier 1, Total Capital, and leverage ratios."""
        rwa = max(risk_weighted_assets, 1.0)
        leverage_base = max(leverage_exposure, 1.0)
        cet1 = max(0.0, cet1_capital)
        tier1 = cet1 + max(0.0, additional_tier1)
        total_capital = tier1 + max(0.0, tier2_capital)

        cet1_ratio = cet1 / rwa
        tier1_ratio = tier1 / rwa
        total_ratio = total_capital / rwa
        leverage_ratio = tier1 / leverage_base
        buffer_ratio = max(0.0, total_ratio - 0.08)
        minimum_requirement_met = cet1_ratio >= 0.045 and tier1_ratio >= 0.06 and total_ratio >= 0.08
        management_target_met = total_ratio >= management_target + conservation_buffer
        headroom = total_capital - rwa * (management_target + conservation_buffer)
        commentary = [
            "Capital ratios are adapted to an AI trading fund but anchored to Basel-style thresholds.",
        ]
        if not minimum_requirement_met:
            commentary.append("Minimum capital requirements are not met.")
        if management_target_met:
            commentary.append("Management capital target is satisfied with current resources.")

        return CapitalAdequacyRatios(
            cet1_ratio=cet1_ratio,
            tier1_ratio=tier1_ratio,
            total_capital_ratio=total_ratio,
            leverage_ratio=leverage_ratio,
            buffer_ratio=buffer_ratio,
            management_target_met=management_target_met,
            minimum_requirement_met=minimum_requirement_met,
            headroom=headroom,
            commentary=commentary,
        )

    def forecast_reserves(
        self,
        current_reserve: float,
        projected_revenues: Sequence[float],
        projected_losses: Sequence[float],
        scenario_multipliers: Sequence[float] | None = None,
        available_capital: float | None = None,
        minimum_ratio: float | None = None,
        scenario_label: str = "base",
    ) -> ReserveForecastResult:
        """Forecast reserves and capital adequacy over future periods."""
        scenario_multipliers = list(scenario_multipliers or [1.0] * len(projected_revenues))
        capital_base = available_capital if available_capital is not None else self.total_capital
        ratio_floor = minimum_ratio if minimum_ratio is not None else self.min_reserve_ratio
        projections: list[ReserveProjectionPoint] = []
        reserve = max(0.0, current_reserve)
        peak_reserve = reserve
        peak_buffer_draw = 0.0
        adequate_under_stress = True

        for period, revenue in enumerate(projected_revenues, start=1):
            losses = projected_losses[period - 1] if period - 1 < len(projected_losses) else 0.0
            scenario_multiplier = (
                scenario_multipliers[period - 1]
                if period - 1 < len(scenario_multipliers)
                else scenario_multipliers[-1]
            )
            baseline_reserve = max(ratio_floor * capital_base, reserve + max(0.0, losses) - max(0.0, revenue) * 0.10)
            stressed_reserve = baseline_reserve * max(1.0, scenario_multiplier)
            buffer = capital_base - stressed_reserve
            capital_ratio = stressed_reserve / capital_base if capital_base > 0 else 0.0
            peak_reserve = max(peak_reserve, stressed_reserve)
            peak_buffer_draw = max(peak_buffer_draw, max(0.0, stressed_reserve - reserve))
            if buffer < 0:
                adequate_under_stress = False
            projections.append(
                ReserveProjectionPoint(
                    period=period,
                    projected_revenue=revenue,
                    projected_losses=losses,
                    baseline_reserve=baseline_reserve,
                    stressed_reserve=stressed_reserve,
                    buffer=buffer,
                    capital_ratio=capital_ratio,
                    scenario_label=scenario_label,
                )
            )
            reserve = baseline_reserve

        commentary = [
            "Reserve forecasting projects baseline and stressed needs forward through the planning horizon.",
        ]
        if not adequate_under_stress:
            commentary.append("At least one forecast period exhausts available capital under stress.")

        return ReserveForecastResult(
            projections=projections,
            peak_reserve=peak_reserve,
            ending_reserve=reserve,
            peak_buffer_draw=peak_buffer_draw,
            adequate_under_stress=adequate_under_stress,
            commentary=commentary,
        )

    def capital_planning_under_scenarios(
        self,
        starting_capital: float,
        current_reserve: float,
        projected_revenues: Sequence[float],
        projected_losses: Sequence[float],
        scenario_sets: Mapping[str, Sequence[float]],
    ) -> dict[str, ReserveForecastResult]:
        """Run reserve forecasts under multiple planning scenarios."""
        results: dict[str, ReserveForecastResult] = {}
        for name, multipliers in scenario_sets.items():
            results[name] = self.forecast_reserves(
                current_reserve=current_reserve,
                projected_revenues=projected_revenues,
                projected_losses=projected_losses,
                scenario_multipliers=multipliers,
                available_capital=starting_capital,
                scenario_label=name,
            )
        return results

    def buffer_adequacy_testing(
        self,
        forecast: ReserveForecastResult,
        management_buffer: float,
    ) -> dict[str, Any]:
        """Test whether forecast reserves preserve a desired management buffer."""
        shortfalls = [
            max(0.0, management_buffer - point.buffer)
            for point in forecast.projections
        ]
        return {
            "management_buffer": management_buffer,
            "max_shortfall": max(shortfalls) if shortfalls else 0.0,
            "buffer_preserved": all(shortfall <= 0 for shortfall in shortfalls),
            "periods_tested": len(forecast.projections),
        }

    def estimate_correlation_matrix(
        self,
        series_map: Mapping[str, Sequence[float]],
    ) -> dict[str, dict[str, float]]:
        """Estimate a simple correlation matrix from aligned return series."""
        names = list(series_map.keys())
        matrix: dict[str, dict[str, float]] = {name: {} for name in names}
        for left in names:
            for right in names:
                if left == right:
                    matrix[left][right] = 1.0
                else:
                    matrix[left][right] = self._pairwise_correlation(
                        series_map[left],
                        series_map[right],
                    )
        return matrix

    def reserve_requirements_from_distribution(
        self,
        reserve_type: ReserveType,
        distribution: LossDistribution,
        confidence_level: float,
        holding_period_days: int,
        stress_multiplier: float = 1.0,
    ) -> ReserveRequirement:
        """Translate a loss distribution into a reserve requirement object."""
        amount = distribution.quantile_loss(confidence_level) * max(0.0, stress_multiplier)
        return ReserveRequirement(
            reserve_type=reserve_type,
            amount=amount,
            confidence_level=confidence_level,
            holding_period_days=holding_period_days,
            stress_multiplier=stress_multiplier,
        )

    def comprehensive_reserve_dashboard(
        self,
        available_capital: float | None = None,
    ) -> dict[str, Any]:
        """Provide a consolidated dashboard-style snapshot of reserve adequacy."""
        total_info = self.total_required_reserves()
        capital = available_capital if available_capital is not None else self.total_capital
        ratios = self.calculate_capital_adequacy_ratios(
            cet1_capital=max(0.0, capital - total_info["total_reserves"] * 0.25),
            additional_tier1=total_info["total_reserves"] * 0.05,
            tier2_capital=total_info["total_reserves"] * 0.10,
            risk_weighted_assets=max(1.0, capital * 0.80),
            leverage_exposure=max(1.0, capital * 1.20),
        )
        return {
            "reserves": total_info,
            "capital_adequacy": ratios,
            "loss_distribution": self.build_loss_distribution(),
        }

    def _normalize_reserve_mapping(
        self,
        baseline_reserves: Mapping[ReserveType | str, float] | None,
    ) -> dict[ReserveType, float]:
        """Normalize reserve keys to ReserveType values and fill missing buckets."""
        if baseline_reserves is None:
            normalized = self.reserves.copy()
        else:
            normalized = {rt: 0.0 for rt in ReserveType}
            for key, value in baseline_reserves.items():
                reserve_type = key if isinstance(key, ReserveType) else ReserveType(str(key))
                normalized[reserve_type] = max(0.0, value)
        return normalized

    def _stress_amount(
        self,
        reserve_type: ReserveType,
        baseline_amount: float,
        scenario: StressScenario,
    ) -> tuple[float, float, dict[str, float]]:
        """Calculate the stressed amount for a single reserve bucket."""
        macro = scenario.macro_shocks
        drivers = {
            "combined": max(0.0, scenario.combined_multiplier - 1.0),
            "correlation": max(0.0, scenario.correlation_multiplier - 1.0),
            "liquidity_horizon": max(0.0, scenario.liquidity_horizon_multiplier - 1.0),
        }
        multiplier = 1.0 + drivers["combined"]

        if reserve_type == ReserveType.MARKET:
            vol = max(0.0, macro.get("volatility", 0.0))
            spread = max(0.0, macro.get("spread", 0.0))
            concentration = max(0.0, macro.get("concentration", 0.0))
            multiplier += 1.8 * vol + 0.8 * spread + 0.5 * concentration
            multiplier *= scenario.correlation_multiplier
            drivers.update({"volatility": 1.8 * vol, "spread": 0.8 * spread})
        elif reserve_type == ReserveType.LIQUIDITY:
            vol = max(0.0, macro.get("volatility", 0.0))
            liquidity = max(0.0, macro.get("liquidity", 0.0))
            multiplier += 1.2 * vol + 1.5 * liquidity
            multiplier *= scenario.liquidity_horizon_multiplier
            drivers.update({"volatility": 1.2 * vol, "liquidity": 1.5 * liquidity})
        elif reserve_type == ReserveType.OPERATIONAL:
            gdp = abs(min(0.0, macro.get("gdp", 0.0)))
            operational = max(0.0, macro.get("operational", 0.0))
            multiplier += 0.5 * gdp + 1.1 * operational
            drivers.update({"gdp": 0.5 * gdp, "operational": 1.1 * operational})
        elif reserve_type == ReserveType.MODEL:
            model_error = max(0.0, macro.get("model_error", 0.0))
            vol = max(0.0, macro.get("volatility", 0.0))
            multiplier += 1.2 * model_error + 0.6 * vol
            multiplier *= scenario.correlation_multiplier
            drivers.update({"model_error": 1.2 * model_error, "volatility": 0.6 * vol})
        elif reserve_type == ReserveType.CREDIT:
            spread = max(0.0, macro.get("spread", 0.0))
            counterparty = max(0.0, macro.get("counterparty", 0.0))
            concentration = max(0.0, macro.get("concentration", 0.0))
            multiplier += 1.1 * spread + 1.3 * counterparty + 0.7 * concentration
            multiplier *= scenario.wrong_way_multiplier
            drivers.update(
                {
                    "spread": 1.1 * spread,
                    "counterparty": 1.3 * counterparty,
                    "concentration": 0.7 * concentration,
                }
            )
        elif reserve_type == ReserveType.TECHNOLOGY:
            operational = max(0.0, macro.get("operational", 0.0))
            liquidity = max(0.0, macro.get("liquidity", 0.0))
            multiplier += 0.9 * operational + 0.4 * liquidity
            drivers.update({"operational": 0.9 * operational, "liquidity": 0.4 * liquidity})

        factor_override = scenario.factor_shocks.get(reserve_type.value, 0.0)
        if factor_override:
            multiplier += factor_override
            drivers["factor_override"] = factor_override

        floor = max(0.0, scenario.reserve_floors.get(reserve_type, 0.0))
        stressed_amount = max(floor, baseline_amount * max(0.0, multiplier))
        return stressed_amount, max(0.0, multiplier), drivers

    def _default_factor_elasticities(self) -> dict[str, dict[ReserveType, float]]:
        """Return default reserve elasticities for factor-based stress testing."""
        return {
            "volatility": {
                ReserveType.MARKET: 1.40,
                ReserveType.LIQUIDITY: 1.00,
                ReserveType.MODEL: 0.50,
            },
            "spread": {
                ReserveType.MARKET: 0.80,
                ReserveType.CREDIT: 1.10,
            },
            "funding": {
                ReserveType.LIQUIDITY: 1.25,
                ReserveType.CREDIT: 0.35,
            },
            "model_drift": {
                ReserveType.MODEL: 1.50,
                ReserveType.OPERATIONAL: 0.30,
            },
            "incident": {
                ReserveType.OPERATIONAL: 1.20,
                ReserveType.TECHNOLOGY: 1.10,
            },
        }

    def _portfolio_risk(
        self,
        standalone_risks: Mapping[str, float],
        correlation_matrix: Mapping[str, Mapping[str, float]],
    ) -> float:
        """Calculate portfolio risk under a variance-covariance approximation."""
        total_variance = 0.0
        for left_name, left_risk in standalone_risks.items():
            for right_name, right_risk in standalone_risks.items():
                corr = self._matrix_value(correlation_matrix, left_name, right_name, default=0.0)
                if left_name == right_name:
                    corr = 1.0
                total_variance += left_risk * right_risk * corr
        return math.sqrt(max(0.0, total_variance))

    def _subset_portfolio_risk(
        self,
        subset: Sequence[str],
        standalone_risks: Mapping[str, float],
        correlation_matrix: Mapping[str, Mapping[str, float]],
    ) -> float:
        """Portfolio risk restricted to a subset of names."""
        if not subset:
            return 0.0
        return self._portfolio_risk(
            {name: standalone_risks[name] for name in subset},
            correlation_matrix,
        )

    def _matrix_value(
        self,
        matrix: Mapping[str, Mapping[str, float]],
        left: str,
        right: str,
        default: float = 0.0,
    ) -> float:
        """Safely extract a value from a nested mapping matrix."""
        if left in matrix and right in matrix[left]:
            return matrix[left][right]
        if right in matrix and left in matrix[right]:
            return matrix[right][left]
        return default

    def _pairwise_correlation(
        self,
        series_a: Sequence[float],
        series_b: Sequence[float],
    ) -> float:
        """Estimate pairwise correlation without external numerical libraries."""
        n = min(len(series_a), len(series_b))
        if n == 0:
            return 0.0
        values_a = list(series_a[:n])
        values_b = list(series_b[:n])
        mean_a = sum(values_a) / n
        mean_b = sum(values_b) / n
        cov = sum((a - mean_a) * (b - mean_b) for a, b in zip(values_a, values_b)) / n
        std_a = self._series_std(values_a)
        std_b = self._series_std(values_b)
        if std_a <= 0 or std_b <= 0:
            return 0.0
        return self._clamp(cov / (std_a * std_b), -1.0, 1.0)

    def _series_std(self, values: Sequence[float]) -> float:
        """Compute population standard deviation for a sequence."""
        if not values:
            return 0.0
        mean = sum(values) / len(values)
        variance = sum((value - mean) ** 2 for value in values) / len(values)
        return math.sqrt(max(0.0, variance))

    def _herfindahl_index(self, values: Iterable[float]) -> float:
        """Calculate the Herfindahl-Hirschman Index of a set of exposures."""
        positive_values = [max(0.0, value) for value in values]
        total = sum(positive_values)
        if total <= 0:
            return 0.0
        return sum((value / total) ** 2 for value in positive_values)

    def _clamp(self, value: float, lower: float, upper: float) -> float:
        """Clamp a numeric value into a closed interval."""
        return max(lower, min(upper, value))

    def _default_recovery_actions(self) -> list[RecoveryAction]:
        """Return a default recovery playbook for the fund."""
        return [
            RecoveryAction(
                stage=RecoveryStage.NORMAL,
                actions=["Maintain routine monitoring and monthly reserve review."],
                capital_released=0.0,
                days_to_execute=0,
            ),
            RecoveryAction(
                stage=RecoveryStage.EARLY_ACTION,
                actions=[
                    "Reduce non-core risk positions.",
                    "Suspend discretionary capital deployment.",
                ],
                capital_released=self.total_capital * 0.03,
                days_to_execute=3,
            ),
            RecoveryAction(
                stage=RecoveryStage.RECOVERY,
                actions=[
                    "Execute contingency hedges and cut leverage.",
                    "Raise committed liquidity from investors or credit lines.",
                    "Pause model rollouts and tighten trading limits.",
                ],
                capital_released=self.total_capital * 0.08,
                days_to_execute=7,
            ),
            RecoveryAction(
                stage=RecoveryStage.RESOLUTION,
                actions=[
                    "Prepare orderly wind-down of strategies.",
                    "Transfer or novate counterparty exposures where feasible.",
                    "Communicate resolution plan to stakeholders and service providers.",
                ],
                capital_released=self.total_capital * 0.12,
                days_to_execute=14,
            ),
        ]
