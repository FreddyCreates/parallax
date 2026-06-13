"""Comprehensive FpML engine for OTC derivative representation and reporting.

The engine preserves the original lightweight trade factories while expanding the
module into a richer in-memory representation layer for common FpML workflows.
It covers vanilla and exotic derivatives, lifecycle processing, valuation
summaries, portfolio compression, and regulatory reporting helpers.
"""

import uuid
from dataclasses import asdict, dataclass, field, is_dataclass
from datetime import date, datetime, timedelta
from enum import Enum
from typing import Any, Iterable


class ProductType(str, Enum):
    """Supported product identifiers."""

    INTEREST_RATE_SWAP = "ird:swap"
    FX_FORWARD = "fx:forward"
    FX_OPTION = "fx:option"
    CREDIT_DEFAULT_SWAP = "cd:swap"
    EQUITY_OPTION = "eq:option"
    EQUITY_SWAP = "eq:swap"
    COMMODITY_SWAP = "com:swap"
    TOTAL_RETURN_SWAP = "eq:totalReturnSwap"
    VARIANCE_SWAP = "eq:varianceSwap"
    SWAPTION = "ird:swaption"
    BARRIER_OPTION = "eq:barrierOption"
    ASIAN_OPTION = "eq:asianOption"
    LOOKBACK_OPTION = "eq:lookbackOption"
    CLIQUET_OPTION = "eq:cliquetOption"
    COMMODITY_OPTION = "com:option"
    WEATHER_DERIVATIVE = "com:weatherDerivative"
    CROSS_CURRENCY_SWAP = "ird:crossCurrencySwap"
    INTEREST_RATE_CAP = "ird:cap"
    INTEREST_RATE_FLOOR = "ird:floor"
    INTEREST_RATE_COLLAR = "ird:collar"
    CDO_TRANCHE = "cd:cdoTranche"
    CREDIT_INDEX = "cd:creditIndex"
    CREDIT_OPTION = "cd:creditOption"
    RECOVERY_SWAP = "cd:recoverySwap"


class DayCountFraction(str, Enum):
    """Day count fraction conventions."""

    ACT_360 = "ACT/360"
    ACT_365 = "ACT/365.FIXED"
    THIRTY_360 = "30/360"
    ACT_ACT = "ACT/ACT.ISDA"


class ExerciseStyle(str, Enum):
    """Exercise styles used by swaptions and options."""

    EUROPEAN = "european"
    BERMUDAN = "bermudan"
    AMERICAN = "american"


class OptionType(str, Enum):
    """Option direction or settlement type."""

    CALL = "call"
    PUT = "put"
    PAYER = "payer"
    RECEIVER = "receiver"


class BarrierDirection(str, Enum):
    """Barrier direction relative to spot."""

    UP = "up"
    DOWN = "down"


class BarrierType(str, Enum):
    """Barrier trigger behaviour."""

    KNOCK_IN = "knock-in"
    KNOCK_OUT = "knock-out"


class AveragingMethod(str, Enum):
    """Averaging methodologies for Asian options."""

    ARITHMETIC = "arithmetic"
    GEOMETRIC = "geometric"


class CommoditySettlementType(str, Enum):
    """Commodity settlement methods."""

    CASH = "cash"
    PHYSICAL = "physical"


class WeatherIndexType(str, Enum):
    """Supported weather indices."""

    HDD = "heatingDegreeDays"
    CDD = "coolingDegreeDays"
    RAINFALL = "rainfall"
    WIND = "wind"
    SNOWFALL = "snowfall"


class CapFloorType(str, Enum):
    """Interest rate option family."""

    CAP = "cap"
    FLOOR = "floor"
    COLLAR = "collar"


class CreditIndexFamily(str, Enum):
    """Common credit index families."""

    CDX = "CDX"
    ITRAXX = "iTraxx"
    BESPOKE = "Bespoke"


class RegulatoryRegime(str, Enum):
    """Trade reporting regimes."""

    EMIR = "EMIR"
    DODD_FRANK = "DODD_FRANK"
    BOTH = "BOTH"


class EventType(str, Enum):
    """Supported lifecycle events."""

    RATE_RESET = "rateReset"
    CASHFLOW_GENERATION = "cashflowGeneration"
    EARLY_TERMINATION = "earlyTermination"
    PARTIAL_TERMINATION = "partialTermination"
    COMPRESSION = "compression"
    VALUATION = "valuation"


@dataclass
class FpMLParty:
    """FpML party representation."""

    party_id: str
    party_name: str
    role: str = "party"
    lei: str = ""


@dataclass
class SchedulePeriod:
    """Generic schedule period used across rates, credit, and commodity products."""

    start_date: str
    end_date: str
    payment_date: str
    fixing_date: str = ""
    accrual_factor: float = 0.0
    notional: float = 0.0
    rate: float = 0.0
    spread: float = 0.0


@dataclass
class ExerciseDate:
    """A discrete exercise date with optional notice period."""

    exercise_date: str
    notice_days: int = 0
    settlement_date: str = ""


@dataclass
class ExerciseSchedule:
    """Exercise schedule definition for swaptions and exotic options."""

    style: ExerciseStyle
    exercise_dates: list[ExerciseDate] = field(default_factory=list)
    window_start: str = ""
    window_end: str = ""
    notice_days: int = 0


@dataclass
class SwaptionTerms:
    """Underlying swaption terms."""

    option_type: OptionType
    strike_rate: float
    settlement_type: str
    exercise_schedule: ExerciseSchedule
    underlying_swap_start: str
    underlying_swap_end: str
    underlying_fixed_rate: float
    underlying_floating_index: str
    underlying_payment_frequency: str


@dataclass
class BarrierTerms:
    """Barrier option terms."""

    option_type: OptionType
    strike: float
    barrier_level: float
    barrier_direction: BarrierDirection
    barrier_type: BarrierType
    monitoring_frequency: str
    rebate: float = 0.0


@dataclass
class AsianTerms:
    """Asian option terms."""

    option_type: OptionType
    strike: float
    averaging_method: AveragingMethod
    averaging_dates: list[str] = field(default_factory=list)


@dataclass
class LookbackTerms:
    """Lookback option terms."""

    option_type: OptionType
    strike: float
    observation_start: str
    observation_end: str
    settlement_style: str = "cash"


@dataclass
class CliquetTerms:
    """Cliquet option terms."""

    option_type: OptionType
    local_cap: float
    local_floor: float
    global_cap: float
    global_floor: float
    reset_schedule: list[SchedulePeriod] = field(default_factory=list)


@dataclass
class CommodityLeg:
    """Commodity leg representation."""

    commodity: str
    currency: str
    quantity: float
    unit: str
    price: float = 0.0
    floating_reference: str = ""
    settlement_type: CommoditySettlementType = CommoditySettlementType.CASH
    schedule: list[SchedulePeriod] = field(default_factory=list)


@dataclass
class CommodityOptionTerms:
    """Commodity option terms."""

    commodity: str
    quantity: float
    strike_price: float
    option_type: OptionType
    settlement_type: CommoditySettlementType
    expiry_date: str
    unit: str = "BBL"


@dataclass
class WeatherDerivativeTerms:
    """Weather derivative terms."""

    location: str
    index_type: WeatherIndexType
    strike: float
    index_multiplier: float
    observation_start: str
    observation_end: str
    cap: float = 0.0
    floor: float = 0.0


@dataclass
class CrossCurrencyLeg:
    """Cross-currency swap leg."""

    currency: str
    notional: float
    fixed_rate: float = 0.0
    floating_index: str = ""
    spread: float = 0.0
    payment_frequency: str = "3M"
    day_count: DayCountFraction = DayCountFraction.ACT_360
    schedule: list[SchedulePeriod] = field(default_factory=list)


@dataclass
class CrossCurrencySwapTerms:
    """Cross-currency swap terms."""

    pay_leg: CrossCurrencyLeg
    receive_leg: CrossCurrencyLeg
    exchange_initial_notional: bool = True
    exchange_final_notional: bool = True
    amortization_schedule: list[dict[str, Any]] = field(default_factory=list)


@dataclass
class CapFloorTerms:
    """Cap, floor, or collar terms."""

    product_kind: CapFloorType
    strike_rate: float
    floor_rate: float = 0.0
    floating_index: str = ""
    payment_frequency: str = "3M"
    option_schedule: list[SchedulePeriod] = field(default_factory=list)


@dataclass
class CreditTrancheTerms:
    """CDO tranche terms."""

    reference_pool: str
    attachment_point: float
    detachment_point: float
    spread_bps: float
    loss_allocation: str = "pro-rata"


@dataclass
class CreditIndexTerms:
    """Credit index terms."""

    family: CreditIndexFamily
    series: str
    version: str
    index_name: str
    constituents: int
    spread_bps: float


@dataclass
class CreditOptionTerms:
    """Credit option terms."""

    reference_obligation: str
    option_type: OptionType
    strike_spread_bps: float
    expiry_date: str
    knockout_on_default: bool = True


@dataclass
class RecoverySwapTerms:
    """Recovery swap terms."""

    reference_entity: str
    fixed_recovery_rate: float
    floating_recovery_source: str = "auction"


@dataclass
class CompressionCandidate:
    """Potential portfolio compression package."""

    candidate_id: str
    product_type: ProductType
    currency: str
    trade_ids: list[str]
    gross_notional: float
    net_notional: float
    termination_date: str
    rationale: str


@dataclass
class CompressionResult:
    """Compression result set."""

    candidates: list[CompressionCandidate] = field(default_factory=list)
    replacement_trades: list[str] = field(default_factory=list)
    terminated_trades: list[str] = field(default_factory=list)
    gross_notional_reduced: float = 0.0


@dataclass
class SensitivityPoint:
    """Simple sensitivity representation."""

    risk_factor: str
    shock: float
    delta: float
    gamma: float = 0.0
    vega: float = 0.0


@dataclass
class ValuationReport:
    """Valuation report snapshot."""

    valuation_date: str
    mark_to_market: float
    present_value: float
    currency: str
    accrued_interest: float = 0.0
    clean_price: float = 0.0
    sensitivities: list[SensitivityPoint] = field(default_factory=list)
    projected_cashflows: list[dict[str, Any]] = field(default_factory=list)


@dataclass
class RegulatoryReport:
    """Regulatory reporting package."""

    regime: RegulatoryRegime
    uti: str
    upi: str
    reporting_counterparty_lei: str
    other_counterparty_lei: str
    venue_of_execution: str
    collateralization: str
    reporting_fields: dict[str, Any] = field(default_factory=dict)


@dataclass
class LifecycleEvent:
    """Stored lifecycle event."""

    event_type: EventType
    event_time: str
    description: str
    details: dict[str, Any] = field(default_factory=dict)


@dataclass
class FpMLTrade:
    """FpML trade representation."""

    trade_id: str = ""
    product_type: ProductType = ProductType.INTEREST_RATE_SWAP
    trade_date: str = ""
    effective_date: str = ""
    termination_date: str = ""
    notional: float = 0.0
    currency: str = "USD"
    parties: list[FpMLParty] = field(default_factory=list)
    fixed_rate: float = 0.0
    floating_index: str = "USD-SOFR"
    day_count: DayCountFraction = DayCountFraction.ACT_360
    payment_frequency: str = "3M"
    metadata: dict[str, Any] = field(default_factory=dict)
    portfolio_id: str = ""
    status: str = "active"
    version: int = 1
    lifecycle_events: list[LifecycleEvent] = field(default_factory=list)
    valuations: list[ValuationReport] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)

    def __post_init__(self) -> None:
        if not self.trade_id:
            self.trade_id = f"PARRALAX-{uuid.uuid4().hex[:12].upper()}"
        if not self.trade_date:
            self.trade_date = date.today().isoformat()


class FpMLEngine:
    """FpML message generation, scheduling, valuation, and lifecycle engine."""

    def __init__(self) -> None:
        self.trades: dict[str, FpMLTrade] = {}
        self.namespace = "http://www.fpml.org/FpML-5/confirmation"

    def _register_trade(self, trade: FpMLTrade) -> FpMLTrade:
        """Persist a trade in the in-memory trade store."""
        self.trades[trade.trade_id] = trade
        return trade

    def _parse_date(self, value: str | date | datetime | None) -> date:
        """Parse common date inputs into a ``date`` instance."""
        if value is None:
            return date.today()
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        return datetime.fromisoformat(value).date()

    def _iso(self, value: str | date | datetime | None) -> str:
        """Convert supported date inputs into an ISO date string."""
        return self._parse_date(value).isoformat()

    def _add_months(self, value: str | date | datetime, months: int) -> date:
        """Add months to a date while keeping month-end safety."""
        base = self._parse_date(value)
        month_index = base.month - 1 + months
        year = base.year + month_index // 12
        month = month_index % 12 + 1
        last_day_lookup = [
            31,
            29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31,
        ]
        day = min(base.day, last_day_lookup[month - 1])
        return date(year, month, day)

    def _add_tenor(self, value: str | date | datetime, tenor: str) -> date:
        """Advance a date by a tenor string such as 3M, 1Y, or 2W."""
        base = self._parse_date(value)
        unit = tenor[-1].upper()
        amount = int(tenor[:-1])
        if unit == "D":
            return base + timedelta(days=amount)
        if unit == "W":
            return base + timedelta(weeks=amount)
        if unit == "M":
            return self._add_months(base, amount)
        if unit == "Y":
            return self._add_months(base, amount * 12)
        raise ValueError(f"Unsupported tenor: {tenor}")

    def _frequency_to_months(self, frequency: str) -> int:
        """Translate standard payment frequencies into month increments."""
        unit = frequency[-1].upper()
        amount = int(frequency[:-1])
        if unit == "M":
            return amount
        if unit == "Y":
            return amount * 12
        if unit == "W":
            return 0
        if unit == "D":
            return 0
        raise ValueError(f"Unsupported frequency: {frequency}")

    def _generate_schedule(
        self,
        start_date: str | date | datetime,
        end_date: str | date | datetime,
        frequency: str,
        notional: float,
        rate: float = 0.0,
        spread: float = 0.0,
    ) -> list[SchedulePeriod]:
        """Generate a regular schedule between two dates."""
        start = self._parse_date(start_date)
        end = self._parse_date(end_date)
        periods: list[SchedulePeriod] = []
        current = start
        while current < end:
            next_date = self._add_tenor(current, frequency)
            if next_date > end:
                next_date = end
            days = max((next_date - current).days, 1)
            fixing_date = max(current - timedelta(days=2), start)
            periods.append(
                SchedulePeriod(
                    start_date=current.isoformat(),
                    end_date=next_date.isoformat(),
                    payment_date=next_date.isoformat(),
                    fixing_date=fixing_date.isoformat(),
                    accrual_factor=days / 360.0,
                    notional=notional,
                    rate=rate,
                    spread=spread,
                )
            )
            current = next_date
        return periods

    def _exercise_schedule(
        self,
        style: ExerciseStyle,
        effective_date: str,
        expiry_date: str,
        bermudan_dates: list[str] | None = None,
        notice_days: int = 2,
    ) -> ExerciseSchedule:
        """Create an exercise schedule for swaption-style products."""
        expiry = self._parse_date(expiry_date)
        effective = self._parse_date(effective_date)
        if style == ExerciseStyle.EUROPEAN:
            return ExerciseSchedule(
                style=style,
                exercise_dates=[
                    ExerciseDate(
                        exercise_date=expiry.isoformat(),
                        notice_days=notice_days,
                        settlement_date=expiry.isoformat(),
                    )
                ],
                notice_days=notice_days,
            )
        if style == ExerciseStyle.BERMUDAN:
            exercise_dates = bermudan_dates or []
            if not exercise_dates:
                cursor = self._add_months(effective, 6)
                while cursor <= expiry:
                    exercise_dates.append(cursor.isoformat())
                    cursor = self._add_months(cursor, 3)
            return ExerciseSchedule(
                style=style,
                exercise_dates=[
                    ExerciseDate(
                        exercise_date=exercise_date,
                        notice_days=notice_days,
                        settlement_date=exercise_date,
                    )
                    for exercise_date in exercise_dates
                ],
                notice_days=notice_days,
            )
        return ExerciseSchedule(
            style=style,
            window_start=effective.isoformat(),
            window_end=expiry.isoformat(),
            exercise_dates=[
                ExerciseDate(
                    exercise_date=effective.isoformat(),
                    notice_days=notice_days,
                    settlement_date=effective.isoformat(),
                ),
                ExerciseDate(
                    exercise_date=expiry.isoformat(),
                    notice_days=notice_days,
                    settlement_date=expiry.isoformat(),
                ),
            ],
            notice_days=notice_days,
        )

    def _option_type(self, value: str | OptionType) -> OptionType:
        """Normalize string inputs into an ``OptionType`` enum."""
        if isinstance(value, OptionType):
            return value
        normalized = value.lower().replace("-", "_")
        mapping = {
            "call": OptionType.CALL,
            "put": OptionType.PUT,
            "payer": OptionType.PAYER,
            "receiver": OptionType.RECEIVER,
        }
        if normalized not in mapping:
            raise ValueError(f"Unsupported option type: {value}")
        return mapping[normalized]

    def _product_family(self, trade: FpMLTrade) -> str:
        """Group trades into simple valuation and schedule families."""
        if trade.product_type in {
            ProductType.INTEREST_RATE_SWAP,
            ProductType.CROSS_CURRENCY_SWAP,
            ProductType.INTEREST_RATE_CAP,
            ProductType.INTEREST_RATE_FLOOR,
            ProductType.INTEREST_RATE_COLLAR,
            ProductType.SWAPTION,
        }:
            return "rates"
        if trade.product_type in {
            ProductType.CREDIT_DEFAULT_SWAP,
            ProductType.CDO_TRANCHE,
            ProductType.CREDIT_INDEX,
            ProductType.CREDIT_OPTION,
            ProductType.RECOVERY_SWAP,
        }:
            return "credit"
        if trade.product_type in {
            ProductType.FX_FORWARD,
            ProductType.FX_OPTION,
            ProductType.CROSS_CURRENCY_SWAP,
        }:
            return "fx"
        if trade.product_type in {
            ProductType.COMMODITY_SWAP,
            ProductType.COMMODITY_OPTION,
            ProductType.WEATHER_DERIVATIVE,
        }:
            return "commodity"
        return "equity"

    def _xml_escape(self, value: Any) -> str:
        """Escape XML special characters."""
        text = str(value)
        return (
            text.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("'", "&apos;")
        )

    def _xml_tag(self, name: str) -> str:
        """Convert snake_case keys into lower camel XML tags."""
        parts = name.replace("-", "_").split("_")
        if not parts:
            return name
        return parts[0] + "".join(part[:1].upper() + part[1:] for part in parts[1:])

    def _singularize(self, tag: str) -> str:
        """Convert simple plural tags to singular tags."""
        if tag.endswith("ies"):
            return tag[:-3] + "y"
        if tag.endswith("s") and not tag.endswith("ss"):
            return tag[:-1]
        return "item"

    def _serialize_xml(self, tag: str, value: Any, indent: int = 0) -> str:
        """Serialize nested Python objects into simple XML."""
        if value in (None, "", [], {}):
            return ""
        spacing = " " * indent
        if isinstance(value, Enum):
            value = value.value
        if isinstance(value, (date, datetime)):
            value = value.isoformat()
        if is_dataclass(value):
            value = asdict(value)
        if isinstance(value, dict):
            lines = [f"{spacing}<{tag}>"]
            for key, item in value.items():
                child_xml = self._serialize_xml(self._xml_tag(key), item, indent + 2)
                if child_xml:
                    lines.append(child_xml)
            lines.append(f"{spacing}</{tag}>")
            return "\n".join(lines)
        if isinstance(value, list):
            lines = [f"{spacing}<{tag}>"]
            item_tag = self._singularize(tag)
            for item in value:
                child_xml = self._serialize_xml(item_tag, item, indent + 2)
                if child_xml:
                    lines.append(child_xml)
            lines.append(f"{spacing}</{tag}>")
            return "\n".join(lines)
        return f"{spacing}<{tag}>{self._xml_escape(value)}</{tag}>"

    def _counterparty_roles(self, payer: str, receiver: str) -> list[FpMLParty]:
        """Create payer and receiver party records."""
        return [
            FpMLParty(party_id=payer, party_name=payer, role="payer"),
            FpMLParty(party_id=receiver, party_name=receiver, role="receiver"),
        ]

    def _default_end_date(self, start: str | date | datetime, tenor_years: int) -> str:
        """Compute a tenor end date safely."""
        return self._add_months(start, tenor_years * 12).isoformat()

    def create_irs(
        self,
        notional: float,
        fixed_rate: float,
        floating_index: str = "USD-SOFR",
        tenor_years: int = 5,
        currency: str = "USD",
        payer: str = "PARRALAX",
        receiver: str = "COUNTERPARTY",
    ) -> FpMLTrade:
        """Create Interest Rate Swap trade."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        schedule = self._generate_schedule(today, termination_date, "3M", notional, fixed_rate)
        trade = FpMLTrade(
            product_type=ProductType.INTEREST_RATE_SWAP,
            trade_date=today.isoformat(),
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=fixed_rate,
            floating_index=floating_index,
            parties=self._counterparty_roles(payer, receiver),
            metadata={
                "fixed_leg_schedule": schedule,
                "floating_leg_schedule": self._generate_schedule(
                    today,
                    termination_date,
                    "3M",
                    notional,
                    0.0,
                ),
            },
        )
        return self._register_trade(trade)

    def create_cds(
        self,
        reference_entity: str,
        notional: float,
        spread_bps: float,
        tenor_years: int = 5,
        currency: str = "USD",
    ) -> FpMLTrade:
        """Create Credit Default Swap."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        premium_schedule = self._generate_schedule(today, termination_date, "3M", notional)
        trade = FpMLTrade(
            product_type=ProductType.CREDIT_DEFAULT_SWAP,
            trade_date=today.isoformat(),
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=spread_bps / 10000.0,
            metadata={
                "reference_entity": reference_entity,
                "spread_bps": spread_bps,
                "premium_schedule": premium_schedule,
                "protection_start": today.isoformat(),
                "protection_end": termination_date,
            },
        )
        return self._register_trade(trade)

    def create_fx_forward(
        self,
        buy_currency: str,
        sell_currency: str,
        buy_amount: float,
        forward_rate: float,
        value_date: str,
    ) -> FpMLTrade:
        """Create FX Forward trade."""
        trade = FpMLTrade(
            product_type=ProductType.FX_FORWARD,
            effective_date=value_date,
            termination_date=value_date,
            notional=buy_amount,
            currency=buy_currency,
            metadata={
                "sell_currency": sell_currency,
                "sell_amount": buy_amount * forward_rate,
                "forward_rate": forward_rate,
                "settlement_date": value_date,
                "near_leg": {
                    "currency": buy_currency,
                    "amount": buy_amount,
                },
                "far_leg": {
                    "currency": sell_currency,
                    "amount": buy_amount * forward_rate,
                },
            },
        )
        return self._register_trade(trade)

    def create_variance_swap(
        self,
        underlying: str,
        notional_vega: float,
        strike_vol: float,
        observation_days: int = 252,
    ) -> FpMLTrade:
        """Create Variance Swap for volatility trading."""
        today = date.today()
        observation_end = today + timedelta(days=observation_days)
        trade = FpMLTrade(
            product_type=ProductType.VARIANCE_SWAP,
            effective_date=today.isoformat(),
            termination_date=observation_end.isoformat(),
            notional=notional_vega,
            metadata={
                "underlying": underlying,
                "strike_volatility": strike_vol,
                "variance_strike": strike_vol**2,
                "observation_days": observation_days,
                "vega_notional": notional_vega,
                "observation_start": today.isoformat(),
                "observation_end": observation_end.isoformat(),
            },
        )
        return self._register_trade(trade)

    def create_swaption(
        self,
        notional: float,
        strike_rate: float,
        exercise_style: ExerciseStyle = ExerciseStyle.EUROPEAN,
        underlying_tenor_years: int = 5,
        expiry_date: str | None = None,
        currency: str = "USD",
        payer: str = "PARRALAX",
        receiver: str = "COUNTERPARTY",
        floating_index: str = "USD-SOFR",
        option_type: str | OptionType = OptionType.PAYER,
        bermudan_dates: list[str] | None = None,
        settlement_type: str = "physical",
    ) -> FpMLTrade:
        """Create European, Bermudan, or American swaption representation."""
        today = date.today()
        expiry = self._iso(expiry_date or self._add_months(today, 12))
        exercise_schedule = self._exercise_schedule(
            exercise_style,
            today.isoformat(),
            expiry,
            bermudan_dates=bermudan_dates,
        )
        underlying_end = self._default_end_date(expiry, underlying_tenor_years)
        terms = SwaptionTerms(
            option_type=self._option_type(option_type),
            strike_rate=strike_rate,
            settlement_type=settlement_type,
            exercise_schedule=exercise_schedule,
            underlying_swap_start=expiry,
            underlying_swap_end=underlying_end,
            underlying_fixed_rate=strike_rate,
            underlying_floating_index=floating_index,
            underlying_payment_frequency="3M",
        )
        trade = FpMLTrade(
            product_type=ProductType.SWAPTION,
            effective_date=today.isoformat(),
            termination_date=expiry,
            notional=notional,
            currency=currency,
            fixed_rate=strike_rate,
            floating_index=floating_index,
            parties=self._counterparty_roles(payer, receiver),
            metadata={
                "swaption_terms": terms,
                "underlying_swap_schedule": self._generate_schedule(
                    expiry,
                    underlying_end,
                    "3M",
                    notional,
                    strike_rate,
                ),
            },
        )
        return self._register_trade(trade)

    def create_barrier_option(
        self,
        underlying: str,
        notional: float,
        strike: float,
        barrier_level: float,
        option_type: str | OptionType = OptionType.CALL,
        barrier_direction: BarrierDirection = BarrierDirection.UP,
        barrier_type: BarrierType = BarrierType.KNOCK_OUT,
        expiry_date: str | None = None,
        currency: str = "USD",
        monitoring_frequency: str = "1D",
        rebate: float = 0.0,
    ) -> FpMLTrade:
        """Create a barrier option representation."""
        today = date.today()
        expiry = self._iso(expiry_date or self._add_months(today, 6))
        terms = BarrierTerms(
            option_type=self._option_type(option_type),
            strike=strike,
            barrier_level=barrier_level,
            barrier_direction=barrier_direction,
            barrier_type=barrier_type,
            monitoring_frequency=monitoring_frequency,
            rebate=rebate,
        )
        trade = FpMLTrade(
            product_type=ProductType.BARRIER_OPTION,
            effective_date=today.isoformat(),
            termination_date=expiry,
            notional=notional,
            currency=currency,
            metadata={
                "underlying": underlying,
                "barrier_terms": terms,
                "premium_currency": currency,
                "expiry_date": expiry,
            },
        )
        return self._register_trade(trade)

    def create_asian_option(
        self,
        underlying: str,
        notional: float,
        strike: float,
        option_type: str | OptionType = OptionType.CALL,
        expiry_date: str | None = None,
        currency: str = "USD",
        averaging_method: AveragingMethod = AveragingMethod.ARITHMETIC,
        averaging_frequency: str = "1M",
    ) -> FpMLTrade:
        """Create an Asian option with averaging schedule generation."""
        today = date.today()
        expiry = self._parse_date(expiry_date or self._add_months(today, 12))
        averaging_dates: list[str] = []
        cursor = today
        while cursor <= expiry:
            averaging_dates.append(cursor.isoformat())
            next_cursor = self._add_tenor(cursor, averaging_frequency)
            if next_cursor == cursor:
                break
            cursor = next_cursor
        if averaging_dates[-1] != expiry.isoformat():
            averaging_dates.append(expiry.isoformat())
        terms = AsianTerms(
            option_type=self._option_type(option_type),
            strike=strike,
            averaging_method=averaging_method,
            averaging_dates=averaging_dates,
        )
        trade = FpMLTrade(
            product_type=ProductType.ASIAN_OPTION,
            effective_date=today.isoformat(),
            termination_date=expiry.isoformat(),
            notional=notional,
            currency=currency,
            metadata={
                "underlying": underlying,
                "asian_terms": terms,
                "settlement_date": expiry.isoformat(),
            },
        )
        return self._register_trade(trade)

    def create_lookback_option(
        self,
        underlying: str,
        notional: float,
        strike: float,
        option_type: str | OptionType = OptionType.CALL,
        observation_start: str | None = None,
        observation_end: str | None = None,
        currency: str = "USD",
    ) -> FpMLTrade:
        """Create a lookback option representation."""
        today = date.today()
        observation_start_value = self._iso(observation_start or today)
        observation_end_value = self._iso(observation_end or self._add_months(today, 12))
        terms = LookbackTerms(
            option_type=self._option_type(option_type),
            strike=strike,
            observation_start=observation_start_value,
            observation_end=observation_end_value,
        )
        trade = FpMLTrade(
            product_type=ProductType.LOOKBACK_OPTION,
            effective_date=observation_start_value,
            termination_date=observation_end_value,
            notional=notional,
            currency=currency,
            metadata={
                "underlying": underlying,
                "lookback_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_cliquet_option(
        self,
        underlying: str,
        notional: float,
        local_cap: float,
        local_floor: float,
        global_cap: float,
        global_floor: float,
        tenor_years: int = 2,
        currency: str = "USD",
        reset_frequency: str = "3M",
        option_type: str | OptionType = OptionType.CALL,
    ) -> FpMLTrade:
        """Create a cliquet option representation."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        schedule = self._generate_schedule(today, termination_date, reset_frequency, notional)
        terms = CliquetTerms(
            option_type=self._option_type(option_type),
            local_cap=local_cap,
            local_floor=local_floor,
            global_cap=global_cap,
            global_floor=global_floor,
            reset_schedule=schedule,
        )
        trade = FpMLTrade(
            product_type=ProductType.CLIQUET_OPTION,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            metadata={
                "underlying": underlying,
                "cliquet_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_commodity_swap(
        self,
        commodity: str,
        notional: float,
        fixed_price: float,
        quantity: float,
        tenor_months: int = 12,
        frequency: str = "1M",
        currency: str = "USD",
        unit: str = "BBL",
        floating_reference: str = "ICE",
        settlement_type: CommoditySettlementType = CommoditySettlementType.CASH,
    ) -> FpMLTrade:
        """Create a commodity swap with fixed and floating commodity legs."""
        today = date.today()
        termination_date = self._add_months(today, tenor_months).isoformat()
        fixed_schedule = self._generate_schedule(today, termination_date, frequency, quantity, fixed_price)
        floating_schedule = self._generate_schedule(today, termination_date, frequency, quantity)
        fixed_leg = CommodityLeg(
            commodity=commodity,
            currency=currency,
            quantity=quantity,
            unit=unit,
            price=fixed_price,
            settlement_type=settlement_type,
            schedule=fixed_schedule,
        )
        floating_leg = CommodityLeg(
            commodity=commodity,
            currency=currency,
            quantity=quantity,
            unit=unit,
            floating_reference=floating_reference,
            settlement_type=settlement_type,
            schedule=floating_schedule,
        )
        trade = FpMLTrade(
            product_type=ProductType.COMMODITY_SWAP,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=fixed_price,
            payment_frequency=frequency,
            metadata={
                "fixed_leg": fixed_leg,
                "floating_leg": floating_leg,
            },
        )
        return self._register_trade(trade)

    def create_commodity_option(
        self,
        commodity: str,
        quantity: float,
        strike_price: float,
        option_type: str | OptionType = OptionType.CALL,
        expiry_date: str | None = None,
        currency: str = "USD",
        settlement_type: CommoditySettlementType = CommoditySettlementType.CASH,
        unit: str = "BBL",
    ) -> FpMLTrade:
        """Create a commodity option representation."""
        today = date.today()
        expiry = self._iso(expiry_date or self._add_months(today, 6))
        terms = CommodityOptionTerms(
            commodity=commodity,
            quantity=quantity,
            strike_price=strike_price,
            option_type=self._option_type(option_type),
            settlement_type=settlement_type,
            expiry_date=expiry,
            unit=unit,
        )
        trade = FpMLTrade(
            product_type=ProductType.COMMODITY_OPTION,
            effective_date=today.isoformat(),
            termination_date=expiry,
            notional=quantity * strike_price,
            currency=currency,
            metadata={
                "commodity_option_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_weather_derivative(
        self,
        location: str,
        index_type: WeatherIndexType,
        strike: float,
        notional: float,
        start_date: str | None = None,
        end_date: str | None = None,
        payout_per_index: float = 1.0,
        currency: str = "USD",
        cap: float = 0.0,
        floor: float = 0.0,
    ) -> FpMLTrade:
        """Create a weather derivative representation."""
        observation_start = self._iso(start_date or date.today())
        observation_end = self._iso(end_date or self._add_months(observation_start, 3))
        terms = WeatherDerivativeTerms(
            location=location,
            index_type=index_type,
            strike=strike,
            index_multiplier=payout_per_index,
            observation_start=observation_start,
            observation_end=observation_end,
            cap=cap,
            floor=floor,
        )
        trade = FpMLTrade(
            product_type=ProductType.WEATHER_DERIVATIVE,
            effective_date=observation_start,
            termination_date=observation_end,
            notional=notional,
            currency=currency,
            metadata={
                "weather_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_cross_currency_swap(
        self,
        pay_notional: float,
        receive_notional: float,
        pay_currency: str = "USD",
        receive_currency: str = "EUR",
        pay_fixed_rate: float = 0.0,
        receive_fixed_rate: float = 0.0,
        pay_floating_index: str = "USD-SOFR",
        receive_floating_index: str = "EUR-EURIBOR-3M",
        tenor_years: int = 5,
        payment_frequency: str = "3M",
        exchange_initial_notional: bool = True,
        exchange_final_notional: bool = True,
        amortization_schedule: list[dict[str, Any]] | None = None,
        payer: str = "PARRALAX",
        receiver: str = "COUNTERPARTY",
    ) -> FpMLTrade:
        """Create a cross-currency swap with notional exchanges and amortization."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        pay_schedule = self._generate_schedule(
            today,
            termination_date,
            payment_frequency,
            pay_notional,
            pay_fixed_rate,
        )
        receive_schedule = self._generate_schedule(
            today,
            termination_date,
            payment_frequency,
            receive_notional,
            receive_fixed_rate,
        )
        pay_leg = CrossCurrencyLeg(
            currency=pay_currency,
            notional=pay_notional,
            fixed_rate=pay_fixed_rate,
            floating_index=pay_floating_index,
            payment_frequency=payment_frequency,
            schedule=pay_schedule,
        )
        receive_leg = CrossCurrencyLeg(
            currency=receive_currency,
            notional=receive_notional,
            fixed_rate=receive_fixed_rate,
            floating_index=receive_floating_index,
            payment_frequency=payment_frequency,
            schedule=receive_schedule,
        )
        terms = CrossCurrencySwapTerms(
            pay_leg=pay_leg,
            receive_leg=receive_leg,
            exchange_initial_notional=exchange_initial_notional,
            exchange_final_notional=exchange_final_notional,
            amortization_schedule=amortization_schedule or [],
        )
        trade = FpMLTrade(
            product_type=ProductType.CROSS_CURRENCY_SWAP,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=pay_notional,
            currency=pay_currency,
            fixed_rate=pay_fixed_rate,
            floating_index=pay_floating_index,
            parties=self._counterparty_roles(payer, receiver),
            payment_frequency=payment_frequency,
            metadata={
                "cross_currency_terms": terms,
                "notional_exchange_schedule": self._build_notional_exchange_schedule(terms),
            },
        )
        return self._register_trade(trade)

    def _build_notional_exchange_schedule(
        self,
        terms: CrossCurrencySwapTerms,
    ) -> list[dict[str, Any]]:
        """Create principal exchange events for cross-currency swaps."""
        exchanges: list[dict[str, Any]] = []
        pay_start = terms.pay_leg.schedule[0].start_date if terms.pay_leg.schedule else ""
        pay_end = terms.pay_leg.schedule[-1].end_date if terms.pay_leg.schedule else ""
        if terms.exchange_initial_notional and pay_start:
            exchanges.append(
                {
                    "exchange_date": pay_start,
                    "pay_currency": terms.pay_leg.currency,
                    "pay_amount": terms.pay_leg.notional,
                    "receive_currency": terms.receive_leg.currency,
                    "receive_amount": terms.receive_leg.notional,
                    "type": "initial",
                }
            )
        for amortization in terms.amortization_schedule:
            exchanges.append(
                {
                    "exchange_date": amortization.get("date", pay_end),
                    "pay_currency": terms.pay_leg.currency,
                    "pay_amount": amortization.get("pay_notional", 0.0),
                    "receive_currency": terms.receive_leg.currency,
                    "receive_amount": amortization.get("receive_notional", 0.0),
                    "type": "amortization",
                }
            )
        if terms.exchange_final_notional and pay_end:
            exchanges.append(
                {
                    "exchange_date": pay_end,
                    "pay_currency": terms.receive_leg.currency,
                    "pay_amount": terms.receive_leg.notional,
                    "receive_currency": terms.pay_leg.currency,
                    "receive_amount": terms.pay_leg.notional,
                    "type": "final",
                }
            )
        return exchanges

    def create_cap_floor(
        self,
        notional: float,
        strike_rate: float,
        tenor_years: int = 5,
        currency: str = "USD",
        floating_index: str = "USD-SOFR",
        product_kind: CapFloorType = CapFloorType.CAP,
        payment_frequency: str = "3M",
        floor_rate: float = 0.0,
        payer: str = "PARRALAX",
        receiver: str = "COUNTERPARTY",
    ) -> FpMLTrade:
        """Create interest rate caps, floors, or collars with option schedules."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        option_schedule = self._generate_schedule(
            today,
            termination_date,
            payment_frequency,
            notional,
            strike_rate,
        )
        terms = CapFloorTerms(
            product_kind=product_kind,
            strike_rate=strike_rate,
            floor_rate=floor_rate,
            floating_index=floating_index,
            payment_frequency=payment_frequency,
            option_schedule=option_schedule,
        )
        product_type = {
            CapFloorType.CAP: ProductType.INTEREST_RATE_CAP,
            CapFloorType.FLOOR: ProductType.INTEREST_RATE_FLOOR,
            CapFloorType.COLLAR: ProductType.INTEREST_RATE_COLLAR,
        }[product_kind]
        trade = FpMLTrade(
            product_type=product_type,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=strike_rate,
            floating_index=floating_index,
            payment_frequency=payment_frequency,
            parties=self._counterparty_roles(payer, receiver),
            metadata={
                "cap_floor_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_cap(
        self,
        notional: float,
        strike_rate: float,
        tenor_years: int = 5,
        currency: str = "USD",
        floating_index: str = "USD-SOFR",
        payment_frequency: str = "3M",
    ) -> FpMLTrade:
        """Convenience wrapper for cap creation."""
        return self.create_cap_floor(
            notional=notional,
            strike_rate=strike_rate,
            tenor_years=tenor_years,
            currency=currency,
            floating_index=floating_index,
            product_kind=CapFloorType.CAP,
            payment_frequency=payment_frequency,
        )

    def create_floor(
        self,
        notional: float,
        strike_rate: float,
        tenor_years: int = 5,
        currency: str = "USD",
        floating_index: str = "USD-SOFR",
        payment_frequency: str = "3M",
    ) -> FpMLTrade:
        """Convenience wrapper for floor creation."""
        return self.create_cap_floor(
            notional=notional,
            strike_rate=strike_rate,
            tenor_years=tenor_years,
            currency=currency,
            floating_index=floating_index,
            product_kind=CapFloorType.FLOOR,
            payment_frequency=payment_frequency,
        )

    def create_collar(
        self,
        notional: float,
        cap_rate: float,
        floor_rate: float,
        tenor_years: int = 5,
        currency: str = "USD",
        floating_index: str = "USD-SOFR",
        payment_frequency: str = "3M",
    ) -> FpMLTrade:
        """Convenience wrapper for collar creation."""
        return self.create_cap_floor(
            notional=notional,
            strike_rate=cap_rate,
            tenor_years=tenor_years,
            currency=currency,
            floating_index=floating_index,
            product_kind=CapFloorType.COLLAR,
            payment_frequency=payment_frequency,
            floor_rate=floor_rate,
        )

    def create_cdo_tranche(
        self,
        reference_pool: str,
        notional: float,
        attachment_point: float,
        detachment_point: float,
        spread_bps: float,
        tenor_years: int = 5,
        currency: str = "USD",
    ) -> FpMLTrade:
        """Create a CDO tranche representation."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        terms = CreditTrancheTerms(
            reference_pool=reference_pool,
            attachment_point=attachment_point,
            detachment_point=detachment_point,
            spread_bps=spread_bps,
        )
        trade = FpMLTrade(
            product_type=ProductType.CDO_TRANCHE,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=spread_bps / 10000.0,
            metadata={
                "tranche_terms": terms,
                "premium_schedule": self._generate_schedule(
                    today,
                    termination_date,
                    "3M",
                    notional,
                    spread_bps / 10000.0,
                ),
            },
        )
        return self._register_trade(trade)

    def create_credit_index(
        self,
        index_name: str,
        notional: float,
        spread_bps: float,
        family: CreditIndexFamily = CreditIndexFamily.CDX,
        series: str = "41",
        version: str = "1",
        constituents: int = 125,
        tenor_years: int = 5,
        currency: str = "USD",
    ) -> FpMLTrade:
        """Create a CDX/iTraxx style credit index trade."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        terms = CreditIndexTerms(
            family=family,
            series=series,
            version=version,
            index_name=index_name,
            constituents=constituents,
            spread_bps=spread_bps,
        )
        trade = FpMLTrade(
            product_type=ProductType.CREDIT_INDEX,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=spread_bps / 10000.0,
            metadata={
                "credit_index_terms": terms,
                "premium_schedule": self._generate_schedule(
                    today,
                    termination_date,
                    "3M",
                    notional,
                    spread_bps / 10000.0,
                ),
            },
        )
        return self._register_trade(trade)

    def create_credit_option(
        self,
        reference_obligation: str,
        notional: float,
        strike_spread_bps: float,
        expiry_date: str | None = None,
        option_type: str | OptionType = OptionType.PAYER,
        currency: str = "USD",
        knockout_on_default: bool = True,
    ) -> FpMLTrade:
        """Create a credit option representation."""
        today = date.today()
        expiry = self._iso(expiry_date or self._add_months(today, 9))
        terms = CreditOptionTerms(
            reference_obligation=reference_obligation,
            option_type=self._option_type(option_type),
            strike_spread_bps=strike_spread_bps,
            expiry_date=expiry,
            knockout_on_default=knockout_on_default,
        )
        trade = FpMLTrade(
            product_type=ProductType.CREDIT_OPTION,
            effective_date=today.isoformat(),
            termination_date=expiry,
            notional=notional,
            currency=currency,
            fixed_rate=strike_spread_bps / 10000.0,
            metadata={
                "credit_option_terms": terms,
            },
        )
        return self._register_trade(trade)

    def create_recovery_swap(
        self,
        reference_entity: str,
        notional: float,
        fixed_recovery_rate: float,
        tenor_years: int = 5,
        currency: str = "USD",
        floating_recovery_source: str = "auction",
    ) -> FpMLTrade:
        """Create a recovery swap representation."""
        today = date.today()
        termination_date = self._default_end_date(today, tenor_years)
        terms = RecoverySwapTerms(
            reference_entity=reference_entity,
            fixed_recovery_rate=fixed_recovery_rate,
            floating_recovery_source=floating_recovery_source,
        )
        trade = FpMLTrade(
            product_type=ProductType.RECOVERY_SWAP,
            effective_date=today.isoformat(),
            termination_date=termination_date,
            notional=notional,
            currency=currency,
            fixed_rate=fixed_recovery_rate,
            metadata={
                "recovery_swap_terms": terms,
            },
        )
        return self._register_trade(trade)

    def attach_lei(self, trade: FpMLTrade, party_id: str, lei: str) -> None:
        """Attach or update a party LEI on a trade."""
        normalized_lei = lei.strip().upper()
        for party in trade.parties:
            if party.party_id == party_id:
                party.lei = normalized_lei
        trade.metadata.setdefault("lei_mapping", {})[party_id] = normalized_lei

    def generate_uti(self, namespace: str = "PARRALAX", trade_date: str | None = None) -> str:
        """Generate a unique transaction identifier."""
        date_portion = self._iso(trade_date or date.today()).replace("-", "")
        unique_portion = uuid.uuid4().hex[:20].upper()
        return f"{namespace[:10].upper()}{date_portion}{unique_portion}"

    def _generate_upi(self, trade: FpMLTrade) -> str:
        """Create a lightweight unique product identifier."""
        product_code = trade.product_type.value.replace(":", "").replace("-", "").upper()
        return f"UPI-{product_code[:12]}-{trade.currency}-{trade.payment_frequency}"

    def generate_regulatory_report(
        self,
        trade: FpMLTrade,
        regime: RegulatoryRegime = RegulatoryRegime.BOTH,
        reporting_counterparty_lei: str = "",
        other_counterparty_lei: str = "",
        venue_of_execution: str = "OFF-FACILITY",
        collateralization: str = "UNCOLLATERALIZED",
    ) -> dict[str, Any]:
        """Generate EMIR and Dodd-Frank style reporting fields."""
        if trade.parties:
            if not reporting_counterparty_lei:
                reporting_counterparty_lei = trade.parties[0].lei or trade.metadata.get(
                    "lei_mapping", {}
                ).get(trade.parties[0].party_id, "")
            if len(trade.parties) > 1 and not other_counterparty_lei:
                other_counterparty_lei = trade.parties[1].lei or trade.metadata.get(
                    "lei_mapping", {}
                ).get(trade.parties[1].party_id, "")
        report = RegulatoryReport(
            regime=regime,
            uti=self.generate_uti(trade_date=trade.trade_date),
            upi=self._generate_upi(trade),
            reporting_counterparty_lei=reporting_counterparty_lei,
            other_counterparty_lei=other_counterparty_lei,
            venue_of_execution=venue_of_execution,
            collateralization=collateralization,
            reporting_fields={
                "trade_id": trade.trade_id,
                "product_type": trade.product_type.value,
                "trade_date": trade.trade_date,
                "effective_date": trade.effective_date,
                "termination_date": trade.termination_date,
                "notional_amount": trade.notional,
                "notional_currency": trade.currency,
                "price_or_rate": trade.fixed_rate,
                "floating_rate_index": trade.floating_index,
                "clearing_obligation": "false",
                "execution_timestamp": datetime.utcnow().isoformat(timespec="seconds"),
                "reporting_timestamp": datetime.utcnow().isoformat(timespec="seconds"),
                "portfolio_code": trade.portfolio_id,
                "event_count": len(trade.lifecycle_events),
                "regime_specific": {
                    "EMIR": {
                        "action_type": "NEW",
                        "report_tracking_number": trade.trade_id,
                        "buyer_identifier": trade.parties[0].party_id if trade.parties else "",
                        "seller_identifier": trade.parties[1].party_id if len(trade.parties) > 1 else "",
                    },
                    "DODD_FRANK": {
                        "primary_economic_terms": {
                            "payment_frequency": trade.payment_frequency,
                            "day_count_fraction": trade.day_count.value,
                        },
                        "execution_agent": trade.parties[0].party_id if trade.parties else "",
                    },
                },
            },
        )
        trade.metadata["regulatory_report"] = report
        return asdict(report)

    def generate_cashflow_schedule(
        self,
        trade: FpMLTrade,
        as_of_date: str | None = None,
        market_data: dict[str, float] | None = None,
    ) -> list[dict[str, Any]]:
        """Generate projected cashflow schedules for supported products."""
        market = market_data or {}
        base_rate = market.get("forward_rate", trade.fixed_rate or 0.04)
        generated: list[dict[str, Any]] = []
        if trade.product_type == ProductType.INTEREST_RATE_SWAP:
            schedule: list[SchedulePeriod] = trade.metadata.get("fixed_leg_schedule") or self._generate_schedule(
                trade.effective_date,
                trade.termination_date,
                trade.payment_frequency,
                trade.notional,
                trade.fixed_rate,
            )
            for period in schedule:
                fixed_amount = period.notional * trade.fixed_rate * period.accrual_factor
                float_amount = period.notional * base_rate * period.accrual_factor
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": trade.currency,
                        "leg_type": "fixed",
                        "amount": round(fixed_amount, 2),
                        "rate": trade.fixed_rate,
                        "notional": period.notional,
                    }
                )
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": trade.currency,
                        "leg_type": "floating",
                        "amount": round(float_amount, 2),
                        "rate": base_rate,
                        "notional": period.notional,
                    }
                )
        elif trade.product_type == ProductType.CREDIT_DEFAULT_SWAP:
            schedule = trade.metadata.get("premium_schedule") or self._generate_schedule(
                trade.effective_date,
                trade.termination_date,
                "3M",
                trade.notional,
                trade.fixed_rate,
            )
            for period in schedule:
                premium = period.notional * trade.fixed_rate * period.accrual_factor
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": trade.currency,
                        "leg_type": "premium",
                        "amount": round(premium, 2),
                        "rate": trade.fixed_rate,
                        "reference_entity": trade.metadata.get("reference_entity", ""),
                    }
                )
        elif trade.product_type == ProductType.FX_FORWARD:
            generated.extend(
                [
                    {
                        "payment_date": trade.termination_date,
                        "currency": trade.currency,
                        "leg_type": "buy",
                        "amount": round(trade.notional, 2),
                    },
                    {
                        "payment_date": trade.termination_date,
                        "currency": trade.metadata.get("sell_currency", ""),
                        "leg_type": "sell",
                        "amount": round(trade.metadata.get("sell_amount", 0.0), 2),
                    },
                ]
            )
        elif trade.product_type == ProductType.VARIANCE_SWAP:
            realized_variance = market.get(
                "realized_variance",
                trade.metadata.get("variance_strike", 0.0),
            )
            settlement = trade.notional * (
                realized_variance - trade.metadata.get("variance_strike", 0.0)
            )
            generated.append(
                {
                    "payment_date": trade.termination_date,
                    "currency": trade.currency,
                    "leg_type": "variance_settlement",
                    "amount": round(settlement, 2),
                }
            )
        elif trade.product_type == ProductType.SWAPTION:
            generated.append(
                {
                    "payment_date": trade.termination_date,
                    "currency": trade.currency,
                    "leg_type": "exercise_premium",
                    "amount": round(trade.notional * 0.01, 2),
                }
            )
        elif trade.product_type in {
            ProductType.BARRIER_OPTION,
            ProductType.ASIAN_OPTION,
            ProductType.LOOKBACK_OPTION,
            ProductType.CLIQUET_OPTION,
            ProductType.CREDIT_OPTION,
            ProductType.COMMODITY_OPTION,
        }:
            generated.append(
                {
                    "payment_date": trade.termination_date,
                    "currency": trade.currency,
                    "leg_type": "option_settlement",
                    "amount": round(trade.notional * 0.05, 2),
                }
            )
        elif trade.product_type == ProductType.COMMODITY_SWAP:
            fixed_leg: CommodityLeg = trade.metadata["fixed_leg"]
            floating_leg: CommodityLeg = trade.metadata["floating_leg"]
            commodity_price = market.get("commodity_price", fixed_leg.price)
            for fixed_period, floating_period in zip(
                fixed_leg.schedule,
                floating_leg.schedule,
                strict=False,
            ):
                fixed_amount = fixed_leg.quantity * fixed_leg.price
                floating_amount = floating_leg.quantity * commodity_price
                generated.append(
                    {
                        "payment_date": fixed_period.payment_date,
                        "currency": fixed_leg.currency,
                        "leg_type": "commodity_fixed",
                        "amount": round(fixed_amount, 2),
                    }
                )
                generated.append(
                    {
                        "payment_date": floating_period.payment_date,
                        "currency": floating_leg.currency,
                        "leg_type": "commodity_floating",
                        "amount": round(floating_amount, 2),
                    }
                )
        elif trade.product_type == ProductType.WEATHER_DERIVATIVE:
            observed_index = market.get("weather_index", 0.0)
            terms: WeatherDerivativeTerms = trade.metadata["weather_terms"]
            intrinsic = (observed_index - terms.strike) * terms.index_multiplier
            if terms.cap:
                intrinsic = min(intrinsic, terms.cap)
            if terms.floor:
                intrinsic = max(intrinsic, terms.floor)
            generated.append(
                {
                    "payment_date": trade.termination_date,
                    "currency": trade.currency,
                    "leg_type": "weather_settlement",
                    "amount": round(intrinsic, 2),
                }
            )
        elif trade.product_type == ProductType.CROSS_CURRENCY_SWAP:
            terms: CrossCurrencySwapTerms = trade.metadata["cross_currency_terms"]
            pay_rate = market.get("pay_rate", terms.pay_leg.fixed_rate or 0.04)
            receive_rate = market.get("receive_rate", terms.receive_leg.fixed_rate or 0.03)
            for period in terms.pay_leg.schedule:
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": terms.pay_leg.currency,
                        "leg_type": "pay_leg",
                        "amount": round(period.notional * pay_rate * period.accrual_factor, 2),
                        "rate": pay_rate,
                    }
                )
            for period in terms.receive_leg.schedule:
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": terms.receive_leg.currency,
                        "leg_type": "receive_leg",
                        "amount": round(
                            period.notional * receive_rate * period.accrual_factor,
                            2,
                        ),
                        "rate": receive_rate,
                    }
                )
            generated.extend(trade.metadata.get("notional_exchange_schedule", []))
        elif trade.product_type in {
            ProductType.INTEREST_RATE_CAP,
            ProductType.INTEREST_RATE_FLOOR,
            ProductType.INTEREST_RATE_COLLAR,
        }:
            terms: CapFloorTerms = trade.metadata["cap_floor_terms"]
            forward = market.get("forward_rate", trade.fixed_rate)
            for period in terms.option_schedule:
                caplet = max(forward - terms.strike_rate, 0.0)
                floorlet = max(terms.floor_rate - forward, 0.0)
                amount = period.notional * period.accrual_factor * caplet
                if trade.product_type == ProductType.INTEREST_RATE_FLOOR:
                    amount = period.notional * period.accrual_factor * max(
                        terms.strike_rate - forward,
                        0.0,
                    )
                if trade.product_type == ProductType.INTEREST_RATE_COLLAR:
                    amount -= period.notional * period.accrual_factor * floorlet
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": trade.currency,
                        "leg_type": terms.product_kind.value,
                        "amount": round(amount, 2),
                        "forward_rate": forward,
                    }
                )
        elif trade.product_type in {ProductType.CDO_TRANCHE, ProductType.CREDIT_INDEX}:
            schedule = trade.metadata.get("premium_schedule") or []
            for period in schedule:
                premium = period.notional * trade.fixed_rate * period.accrual_factor
                generated.append(
                    {
                        "payment_date": period.payment_date,
                        "currency": trade.currency,
                        "leg_type": "premium",
                        "amount": round(premium, 2),
                    }
                )
        elif trade.product_type == ProductType.RECOVERY_SWAP:
            realized_recovery = market.get("realized_recovery", trade.fixed_rate)
            generated.append(
                {
                    "payment_date": trade.termination_date,
                    "currency": trade.currency,
                    "leg_type": "recovery_settlement",
                    "amount": round(trade.notional * (realized_recovery - trade.fixed_rate), 2),
                }
            )
        if as_of_date:
            cutoff = self._parse_date(as_of_date)
            generated = [
                item
                for item in generated
                if self._parse_date(item.get("payment_date", trade.termination_date)) >= cutoff
            ]
        trade.metadata["cashflow_schedule"] = generated
        return generated

    def generate_cashflows(
        self,
        trade: FpMLTrade,
        as_of_date: str | None = None,
        market_data: dict[str, float] | None = None,
    ) -> list[dict[str, Any]]:
        """Alias for cashflow generation."""
        return self.generate_cashflow_schedule(trade, as_of_date=as_of_date, market_data=market_data)

    def calculate_mark_to_market(
        self,
        trade: FpMLTrade,
        market_data: dict[str, float] | None = None,
        valuation_date: str | None = None,
    ) -> dict[str, Any]:
        """Produce a simple mark-to-market valuation for a trade."""
        market = market_data or {}
        cashflows = self.generate_cashflow_schedule(trade, valuation_date, market)
        discount_rate = market.get("discount_rate", 0.05)
        valuation_day = self._parse_date(valuation_date or date.today())
        present_value = 0.0
        for cashflow in cashflows:
            payment_day = self._parse_date(cashflow.get("payment_date", trade.termination_date))
            year_fraction = max((payment_day - valuation_day).days / 365.0, 0.0)
            amount = float(cashflow.get("amount", 0.0))
            present_value += amount / ((1 + discount_rate) ** year_fraction)
        accrued_interest = 0.0
        if trade.product_type in {
            ProductType.INTEREST_RATE_SWAP,
            ProductType.CREDIT_DEFAULT_SWAP,
            ProductType.CDO_TRANCHE,
            ProductType.CREDIT_INDEX,
        }:
            accrued_interest = trade.notional * trade.fixed_rate / 360.0 * 30.0
        mark_to_market = present_value - accrued_interest
        report = {
            "trade_id": trade.trade_id,
            "valuation_date": valuation_day.isoformat(),
            "currency": trade.currency,
            "present_value": round(present_value, 2),
            "accrued_interest": round(accrued_interest, 2),
            "mark_to_market": round(mark_to_market, 2),
            "clean_price": round(mark_to_market / trade.notional, 8) if trade.notional else 0.0,
        }
        return report

    def generate_sensitivity_report(
        self,
        trade: FpMLTrade,
        market_data: dict[str, float] | None = None,
        valuation_date: str | None = None,
    ) -> dict[str, Any]:
        """Produce a stylized sensitivity report for a trade."""
        market = market_data or {}
        bump = market.get("shock_size", 0.0001)
        base = self.calculate_mark_to_market(trade, market, valuation_date)
        shifted_up_market = dict(market)
        shifted_down_market = dict(market)
        if self._product_family(trade) == "rates":
            shifted_up_market["forward_rate"] = market.get("forward_rate", trade.fixed_rate) + bump
            shifted_down_market["forward_rate"] = market.get("forward_rate", trade.fixed_rate) - bump
            risk_factor = "interest_rate"
        elif self._product_family(trade) == "credit":
            shifted_up_market["credit_spread"] = market.get("credit_spread", trade.fixed_rate) + bump
            shifted_down_market["credit_spread"] = market.get("credit_spread", trade.fixed_rate) - bump
            risk_factor = "credit_spread"
        elif self._product_family(trade) == "fx":
            shifted_up_market["fx_rate"] = market.get("fx_rate", 1.0) + 0.01
            shifted_down_market["fx_rate"] = market.get("fx_rate", 1.0) - 0.01
            risk_factor = "fx_rate"
        else:
            shifted_up_market["commodity_price"] = market.get("commodity_price", trade.fixed_rate) + 1.0
            shifted_down_market["commodity_price"] = market.get("commodity_price", trade.fixed_rate) - 1.0
            risk_factor = "commodity_price"
        up = self.calculate_mark_to_market(trade, shifted_up_market, valuation_date)
        down = self.calculate_mark_to_market(trade, shifted_down_market, valuation_date)
        delta = (up["mark_to_market"] - down["mark_to_market"]) / (2 * bump)
        gamma = (up["mark_to_market"] - 2 * base["mark_to_market"] + down["mark_to_market"]) / (
            bump**2
        )
        vega = trade.notional * market.get("volatility_shock", 0.01) * 0.1
        sensitivity = SensitivityPoint(
            risk_factor=risk_factor,
            shock=bump,
            delta=round(delta, 2),
            gamma=round(gamma, 2),
            vega=round(vega, 2),
        )
        return {
            "trade_id": trade.trade_id,
            "valuation_date": base["valuation_date"],
            "sensitivities": [asdict(sensitivity)],
        }

    def generate_valuation_report(
        self,
        trade: FpMLTrade,
        market_data: dict[str, float] | None = None,
        valuation_date: str | None = None,
    ) -> dict[str, Any]:
        """Generate a combined valuation package with PV, sensitivities, and cashflows."""
        mtm = self.calculate_mark_to_market(trade, market_data, valuation_date)
        sensitivity_report = self.generate_sensitivity_report(trade, market_data, valuation_date)
        cashflows = self.generate_cashflow_schedule(trade, valuation_date, market_data)
        report = ValuationReport(
            valuation_date=mtm["valuation_date"],
            mark_to_market=mtm["mark_to_market"],
            present_value=mtm["present_value"],
            currency=trade.currency,
            accrued_interest=mtm["accrued_interest"],
            clean_price=mtm["clean_price"],
            sensitivities=[SensitivityPoint(**item) for item in sensitivity_report["sensitivities"]],
            projected_cashflows=cashflows,
        )
        trade.valuations.append(report)
        return asdict(report)

    def find_compression_candidates(
        self,
        trades: Iterable[FpMLTrade] | None = None,
    ) -> list[CompressionCandidate]:
        """Identify groups of offsetting trades that are compressible."""
        trade_list = list(trades or self.trades.values())
        grouped: dict[tuple[Any, ...], list[FpMLTrade]] = {}
        for trade in trade_list:
            key = (
                trade.product_type,
                trade.currency,
                round(trade.fixed_rate, 8),
                trade.floating_index,
                trade.termination_date,
            )
            grouped.setdefault(key, []).append(trade)
        candidates: list[CompressionCandidate] = []
        for key, group in grouped.items():
            if len(group) < 2:
                continue
            gross_notional = sum(abs(item.notional) for item in group)
            net_notional = sum(item.notional for item in group)
            if gross_notional <= abs(net_notional):
                continue
            candidate = CompressionCandidate(
                candidate_id=f"CMP-{uuid.uuid4().hex[:10].upper()}",
                product_type=key[0],
                currency=key[1],
                trade_ids=[item.trade_id for item in group],
                gross_notional=gross_notional,
                net_notional=net_notional,
                termination_date=key[4],
                rationale="Matching economic terms with offsetting notionals.",
            )
            candidates.append(candidate)
        return candidates

    def generate_replacement_trade(self, candidate: CompressionCandidate) -> FpMLTrade:
        """Generate a replacement trade for a compression candidate."""
        source_trades = [self.trades[trade_id] for trade_id in candidate.trade_ids if trade_id in self.trades]
        if not source_trades:
            raise ValueError("No source trades available for compression candidate")
        template = source_trades[0]
        net_notional = abs(candidate.net_notional)
        replacement = FpMLTrade(
            product_type=template.product_type,
            effective_date=template.effective_date,
            termination_date=template.termination_date,
            notional=net_notional,
            currency=template.currency,
            fixed_rate=template.fixed_rate,
            floating_index=template.floating_index,
            day_count=template.day_count,
            payment_frequency=template.payment_frequency,
            parties=template.parties,
            metadata={
                "replacement_for": candidate.trade_ids,
                "compression_candidate_id": candidate.candidate_id,
                "net_notional": candidate.net_notional,
            },
            tags=["compression-replacement"],
        )
        return self._register_trade(replacement)

    def compress_portfolio(
        self,
        trades: Iterable[FpMLTrade] | None = None,
    ) -> CompressionResult:
        """Perform simple trade netting and replacement trade generation."""
        candidates = self.find_compression_candidates(trades)
        result = CompressionResult(candidates=candidates)
        for candidate in candidates:
            replacement = self.generate_replacement_trade(candidate)
            result.replacement_trades.append(replacement.trade_id)
            result.terminated_trades.extend(candidate.trade_ids)
            result.gross_notional_reduced += candidate.gross_notional - abs(candidate.net_notional)
            for trade_id in candidate.trade_ids:
                if trade_id in self.trades:
                    self.trades[trade_id].status = "compressed"
                    self.trades[trade_id].lifecycle_events.append(
                        LifecycleEvent(
                            event_type=EventType.COMPRESSION,
                            event_time=datetime.utcnow().isoformat(timespec="seconds"),
                            description="Trade included in portfolio compression.",
                            details={
                                "replacement_trade_id": replacement.trade_id,
                                "candidate_id": candidate.candidate_id,
                            },
                        )
                    )
        return result

    def apply_rate_reset(
        self,
        trade: FpMLTrade,
        reset_rate: float,
        reset_date: str | None = None,
    ) -> dict[str, Any]:
        """Store a rate reset event and update trade metadata."""
        effective_reset_date = self._iso(reset_date or date.today())
        reset_record = {
            "reset_date": effective_reset_date,
            "reset_rate": reset_rate,
            "floating_index": trade.floating_index,
        }
        trade.metadata.setdefault("rate_resets", []).append(reset_record)
        trade.metadata["last_reset_rate"] = reset_rate
        return reset_record

    def process_early_termination(
        self,
        trade: FpMLTrade,
        termination_date: str | None = None,
        termination_fee: float = 0.0,
        reason: str = "bilateral agreement",
    ) -> dict[str, Any]:
        """Process an early termination event."""
        effective_termination = self._iso(termination_date or date.today())
        trade.termination_date = effective_termination
        trade.status = "terminated"
        trade.metadata["termination_fee"] = termination_fee
        trade.metadata["termination_reason"] = reason
        event_result = {
            "termination_date": effective_termination,
            "termination_fee": termination_fee,
            "reason": reason,
        }
        trade.metadata.setdefault("termination_events", []).append(event_result)
        return event_result

    def process_partial_termination(
        self,
        trade: FpMLTrade,
        reduction_amount: float,
        event_date: str | None = None,
        reason: str = "partial unwind",
    ) -> dict[str, Any]:
        """Process a partial termination and reduce outstanding notional."""
        effective_date = self._iso(event_date or date.today())
        remaining_notional = max(trade.notional - reduction_amount, 0.0)
        event_result = {
            "event_date": effective_date,
            "reduction_amount": reduction_amount,
            "remaining_notional": remaining_notional,
            "reason": reason,
        }
        trade.notional = remaining_notional
        trade.metadata.setdefault("partial_terminations", []).append(event_result)
        if trade.notional == 0.0:
            trade.status = "terminated"
        return event_result

    def process_event(
        self,
        trade: FpMLTrade,
        event_type: EventType,
        event_data: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Process supported lifecycle events and record them on the trade."""
        payload = event_data or {}
        if event_type == EventType.RATE_RESET:
            result = self.apply_rate_reset(
                trade,
                reset_rate=float(payload.get("reset_rate", trade.fixed_rate)),
                reset_date=payload.get("reset_date"),
            )
        elif event_type == EventType.CASHFLOW_GENERATION:
            result = {
                "cashflows": self.generate_cashflow_schedule(
                    trade,
                    as_of_date=payload.get("as_of_date"),
                    market_data=payload.get("market_data"),
                )
            }
        elif event_type == EventType.EARLY_TERMINATION:
            result = self.process_early_termination(
                trade,
                termination_date=payload.get("termination_date"),
                termination_fee=float(payload.get("termination_fee", 0.0)),
                reason=payload.get("reason", "bilateral agreement"),
            )
        elif event_type == EventType.PARTIAL_TERMINATION:
            result = self.process_partial_termination(
                trade,
                reduction_amount=float(payload.get("reduction_amount", 0.0)),
                event_date=payload.get("event_date"),
                reason=payload.get("reason", "partial unwind"),
            )
        elif event_type == EventType.VALUATION:
            result = self.generate_valuation_report(
                trade,
                market_data=payload.get("market_data"),
                valuation_date=payload.get("valuation_date"),
            )
        elif event_type == EventType.COMPRESSION:
            result = {"compression_candidates": [asdict(item) for item in self.find_compression_candidates([trade])]}
        else:
            raise ValueError(f"Unsupported event type: {event_type}")
        trade.lifecycle_events.append(
            LifecycleEvent(
                event_type=event_type,
                event_time=datetime.utcnow().isoformat(timespec="seconds"),
                description=f"Processed {event_type.value} event.",
                details=result,
            )
        )
        return result

    def _party_xml(self, party: FpMLParty) -> str:
        """Serialize a party definition."""
        lines = [f'  <party id="{self._xml_escape(party.party_id)}">']
        lines.append(f"    <partyName>{self._xml_escape(party.party_name)}</partyName>")
        lines.append(f"    <role>{self._xml_escape(party.role)}</role>")
        if party.lei:
            lines.append(f"    <lei>{self._xml_escape(party.lei)}</lei>")
        lines.append("  </party>")
        return "\n".join(lines)

    def to_xml(self, trade: FpMLTrade) -> str:
        """Generate FpML XML representation."""
        lines = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<FpML xmlns="{self.namespace}" version="5.12">',
            "  <trade>",
            "    <tradeHeader>",
            "      <tradeIdentifier>",
            f"        <tradeId>{self._xml_escape(trade.trade_id)}</tradeId>",
            "      </tradeIdentifier>",
            f"      <tradeDate>{self._xml_escape(trade.trade_date)}</tradeDate>",
            f"      <status>{self._xml_escape(trade.status)}</status>",
            f"      <version>{trade.version}</version>",
            "    </tradeHeader>",
            f'    <product type="{self._xml_escape(trade.product_type.value)}">',
            "      <notional>",
            f"        <currency>{self._xml_escape(trade.currency)}</currency>",
            f"        <amount>{trade.notional}</amount>",
            "      </notional>",
            f"      <effectiveDate>{self._xml_escape(trade.effective_date)}</effectiveDate>",
            f"      <terminationDate>{self._xml_escape(trade.termination_date)}</terminationDate>",
            f"      <fixedRate>{trade.fixed_rate}</fixedRate>",
            f"      <floatingRateIndex>{self._xml_escape(trade.floating_index)}</floatingRateIndex>",
            f"      <dayCountFraction>{self._xml_escape(trade.day_count.value)}</dayCountFraction>",
            f"      <paymentFrequency>{self._xml_escape(trade.payment_frequency)}</paymentFrequency>",
        ]
        if trade.portfolio_id:
            lines.append(f"      <portfolioId>{self._xml_escape(trade.portfolio_id)}</portfolioId>")
        if trade.tags:
            lines.append(self._serialize_xml("tags", trade.tags, 6))
        if trade.metadata:
            lines.append(self._serialize_xml("productDetails", trade.metadata, 6))
        if trade.lifecycle_events:
            lines.append(self._serialize_xml("lifecycleEvents", trade.lifecycle_events, 6))
        if trade.valuations:
            lines.append(self._serialize_xml("valuationReports", trade.valuations, 6))
        lines.extend(["    </product>", "  </trade>"])
        for party in trade.parties:
            lines.append(self._party_xml(party))
        lines.append("</FpML>")
        return "\n".join(lines)
