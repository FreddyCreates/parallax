"""Financial Languages API Router — XBRL, ISO20022, FIX, FpML, SWIFT, ISDA CDM."""

from __future__ import annotations

from dataclasses import asdict, is_dataclass
from datetime import date
from enum import Enum
from typing import Any

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

from app.routers.financial_languages import (
    FIXEngine,
    FpMLEngine,
    ISO20022Engine,
    ISDACDMEngine,
    PaymentMessage,
    SWIFTEngine,
    XBRLEngine,
)
from app.routers.financial_languages.fix_protocol import (
    FIXOrdType,
    FIXSide,
    FIXTimeInForce,
    RiskCheckResult,
)
from app.routers.financial_languages.fpml_engine import (
    AveragingMethod,
    BarrierDirection,
    BarrierType,
    ExerciseStyle,
    OptionType,
)
from app.routers.financial_languages.isda_cdm import (
    CreditEventType,
    ExerciseOutcome,
    ExerciseType,
)
from app.routers.financial_languages.iso20022 import ISO20022MessageType
from app.routers.financial_languages.swift_engine import SWIFTMessage, SWIFTMessageType
from app.routers.financial_languages.xbrl_engine import (
    XBRLFact,
    XBRLPeriodType,
    XBRLReport,
    XBRLTaxonomy,
)

router = APIRouter()

xbrl_engine = XBRLEngine()
iso20022_engine = ISO20022Engine()
fix_engine = FIXEngine()
swift_engine = SWIFTEngine()
fpml_engine = FpMLEngine()
isda_engine = ISDACDMEngine()


class ValidationIssueModel(BaseModel):
    field: str
    message: str
    severity: str = "error"


class DocumentResponse(BaseModel):
    payload: dict[str, Any]
    rendered: str


class ValidationResponse(BaseModel):
    valid: bool
    issues: list[ValidationIssueModel] = Field(default_factory=list)
    payload: list[dict[str, Any]] = Field(default_factory=list)


class TaxonomyListResponse(BaseModel):
    taxonomies: list[str]


class FIXOrderResponse(BaseModel):
    payload: dict[str, Any]
    encoded_message: str
    order_status: dict[str, Any] | None = None
    risk_check: dict[str, str]
    session: dict[str, Any]


class FIXSessionStatusResponse(BaseModel):
    sessions: list[dict[str, Any]]
    orders: int
    performance: dict[str, Any]


class ISDAResponse(BaseModel):
    trade: dict[str, Any]
    latest_event: dict[str, Any]
    lifecycle: list[dict[str, Any]]


class SWIFTTrackingResponse(BaseModel):
    reference: str
    status: str
    tracking_reference: str
    routing: dict[str, Any]
    message_type: str | None = None
    validation_issues: list[dict[str, str]] = Field(default_factory=list)


class XBRLNavReportRequest(BaseModel):
    nav: float
    total_assets: float
    total_liabilities: float
    shares_outstanding: float
    nav_per_share: float
    reporting_date: str = ""


class XBRLPnLReportRequest(BaseModel):
    revenue: float
    trading_gains: float
    management_fees: float
    performance_fees: float
    expenses: float
    net_income: float
    period_start: str = ""
    period_end: str = ""


class XBRLRiskDisclosureRequest(BaseModel):
    var_95: float
    max_drawdown: float
    sharpe_ratio: float
    leverage_ratio: float
    concentration_top5: float


class XBRLFundPerformanceRequest(BaseModel):
    total_return: float
    benchmark_return: float
    alpha: float
    sharpe_ratio: float
    gross_exposure: float
    net_exposure: float
    period_start: str = ""
    period_end: str = ""


class XBRLFactInput(BaseModel):
    concept: str
    value: str | float
    taxonomy: str = XBRLTaxonomy.US_GAAP.value
    period_type: str = XBRLPeriodType.INSTANT.value
    period_start: str = ""
    period_end: str = ""
    instant_date: str = ""
    unit: str = "USD"
    decimals: int = 2
    context_id: str = ""


class XBRLValidationRequest(BaseModel):
    facts: list[XBRLFactInput]


class ISO20022CreditTransferRequest(BaseModel):
    creditor_name: str
    creditor_bic: str
    amount: float
    currency: str = "USD"
    remittance: str = ""


class ISO20022PaymentItem(BaseModel):
    creditor_name: str
    creditor_bic: str
    amount: float
    currency: str = "USD"
    remittance_info: str = ""


class ISO20022PaymentInitiationRequest(BaseModel):
    payments: list[ISO20022PaymentItem]


class ISO20022SettlementRequest(BaseModel):
    isin: str
    quantity: float
    settlement_amount: float
    counterparty_bic: str
    settlement_date: str = ""


class ISO20022FXTradeRequest(BaseModel):
    buy_currency: str
    buy_amount: float
    sell_currency: str
    sell_amount: float
    counterparty_bic: str
    value_date: str = ""


class ISO20022StatementEntry(BaseModel):
    entry_date: str = ""
    amount: float
    direction: str = "CRDT"
    reference: str = ""
    details: str = ""


class ISO20022BankStatementRequest(BaseModel):
    receiver_bic: str
    account_id: str
    opening_balance: float
    closing_balance: float
    currency: str = "USD"
    statement_date: str = ""
    entries: list[ISO20022StatementEntry] = Field(default_factory=list)


class ISO20022ValidationRequest(BaseModel):
    message_type: str
    debtor_bic: str = "PARRALAXXX"
    creditor_bic: str = ""
    amount: float = 0.0
    currency: str = "USD"
    metadata: dict[str, Any] = Field(default_factory=dict)


class FIXNewOrderRequest(BaseModel):
    target: str
    symbol: str
    side: str
    order_type: str
    quantity: float
    price: float | None = None
    time_in_force: str = FIXTimeInForce.IOC.value
    account: str = ""
    stop_price: float | None = None
    max_floor: float | None = None
    heartbeat: int = 30


class FIXCancelOrderRequest(BaseModel):
    target: str
    orig_cl_ord_id: str
    symbol: str
    side: str


class SWIFTMT103Request(BaseModel):
    receiver_bic: str
    amount: float
    currency: str = "USD"
    narrative: str = ""


class SWIFTMT202Request(BaseModel):
    receiver_bic: str
    amount: float
    currency: str = "USD"
    related_reference: str = ""
    sender_correspondent: str = ""
    account_with_institution: str = ""
    intermediaries: list[str] = Field(default_factory=list)
    narrative: str = ""


class FpMLIRSRequest(BaseModel):
    notional: float
    fixed_rate: float
    floating_index: str = "USD-SOFR"
    tenor_years: int = 5
    currency: str = "USD"
    payer: str = "PARRALAX"
    receiver: str = "COUNTERPARTY"


class FpMLOptionRequest(BaseModel):
    structure: str = "asian"
    underlying: str = "SPX"
    notional: float
    strike: float | None = None
    strike_rate: float | None = None
    option_type: str = OptionType.CALL.value
    currency: str = "USD"
    expiry_date: str | None = None
    averaging_method: str = AveragingMethod.ARITHMETIC.value
    averaging_frequency: str = "1M"
    barrier_level: float | None = None
    barrier_direction: str = BarrierDirection.UP.value
    barrier_type: str = BarrierType.KNOCK_OUT.value
    monitoring_frequency: str = "1D"
    rebate: float = 0.0
    observation_start: str | None = None
    observation_end: str | None = None
    exercise_style: str = ExerciseStyle.EUROPEAN.value
    underlying_tenor_years: int = 5
    payer: str = "PARRALAX"
    receiver: str = "COUNTERPARTY"
    floating_index: str = "USD-SOFR"
    settlement_type: str = "physical"
    bermudan_dates: list[str] = Field(default_factory=list)


class ISDATradeEventRequest(BaseModel):
    product_type: str
    parties: list[str]
    economic_terms: dict[str, Any]


class ISDALifecycleRequest(BaseModel):
    trade_id: str
    lifecycle_event: str
    settlement_amount: float = 0.0
    ccp: str = "LCH"
    margin_amount: float = 0.0
    margin_type: str = "variation"
    old_party: str = ""
    new_party: str = ""
    termination_amount: float = 0.0
    exercise_type: str = ExerciseType.EUROPEAN.value
    exercise_outcome: str = ExerciseOutcome.CASH_SETTLEMENT.value
    fixing_rate: float = 0.0
    reset_date: str = ""
    credit_event_type: str = CreditEventType.BANKRUPTCY.value
    reference_entity: str = ""
    recovery_rate: float = 0.4
    reduction_notional: float = 0.0


def _serialize(value: Any) -> Any:
    if isinstance(value, Enum):
        return value.value
    if is_dataclass(value):
        return _serialize(asdict(value))
    if isinstance(value, dict):
        return {str(key): _serialize(item) for key, item in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_serialize(item) for item in value]
    return value


def _validation_issue(field: str, message: str, severity: str = "error") -> ValidationIssueModel:
    return ValidationIssueModel(field=field, message=message, severity=severity)


def _is_valid_bic(value: str) -> bool:
    return len(value) in {8, 11} and value.isalnum() and value.upper() == value


def _is_valid_currency(value: str) -> bool:
    return len(value) == 3 and value.isalpha() and value.upper() == value


def _parse_fix_side(value: str) -> FIXSide:
    alias_map = {
        "1": FIXSide.BUY,
        "buy": FIXSide.BUY,
        "2": FIXSide.SELL,
        "sell": FIXSide.SELL,
        "5": FIXSide.SHORT_SELL,
        "short_sell": FIXSide.SHORT_SELL,
        "short-sell": FIXSide.SHORT_SELL,
    }
    parsed = alias_map.get(value.lower())
    if parsed is None:
        raise HTTPException(status_code=400, detail=f"Unsupported FIX side: {value}")
    return parsed


def _parse_fix_order_type(value: str) -> FIXOrdType:
    alias_map = {
        "1": FIXOrdType.MARKET,
        "market": FIXOrdType.MARKET,
        "2": FIXOrdType.LIMIT,
        "limit": FIXOrdType.LIMIT,
        "3": FIXOrdType.STOP,
        "stop": FIXOrdType.STOP,
        "4": FIXOrdType.STOP_LIMIT,
        "stop_limit": FIXOrdType.STOP_LIMIT,
        "stop-limit": FIXOrdType.STOP_LIMIT,
        "i": FIXOrdType.ICEBERG,
        "iceberg": FIXOrdType.ICEBERG,
    }
    parsed = alias_map.get(value.lower())
    if parsed is None:
        raise HTTPException(status_code=400, detail=f"Unsupported FIX order type: {value}")
    return parsed


def _parse_fix_tif(value: str) -> FIXTimeInForce:
    alias_map = {
        "0": FIXTimeInForce.DAY,
        "day": FIXTimeInForce.DAY,
        "1": FIXTimeInForce.GTC,
        "gtc": FIXTimeInForce.GTC,
        "3": FIXTimeInForce.IOC,
        "ioc": FIXTimeInForce.IOC,
        "4": FIXTimeInForce.FOK,
        "fok": FIXTimeInForce.FOK,
    }
    parsed = alias_map.get(value.lower())
    if parsed is None:
        raise HTTPException(status_code=400, detail=f"Unsupported time in force: {value}")
    return parsed


def _serialize_fix_session(target: str) -> dict[str, Any]:
    session = fix_engine.sessions[target]
    return {
        "target": session.target_comp_id,
        "sender": session.sender_comp_id,
        "outgoing_seq": session.outgoing_seq,
        "incoming_seq": session.incoming_seq,
        "is_connected": session.is_connected,
        "is_logged_on": session.is_logged_on,
        "heartbeat_interval": session.heartbeat_interval,
    }


def _normalize_xbrl_fact(payload: XBRLFactInput) -> tuple[XBRLFact | None, list[ValidationIssueModel]]:
    issues: list[ValidationIssueModel] = []
    try:
        taxonomy = XBRLTaxonomy(payload.taxonomy)
    except ValueError:
        issues.append(_validation_issue("taxonomy", f"Unsupported taxonomy: {payload.taxonomy}"))
        taxonomy = None
    try:
        period_type = XBRLPeriodType(payload.period_type)
    except ValueError:
        issues.append(_validation_issue("period_type", f"Unsupported period type: {payload.period_type}"))
        period_type = None

    if ":" not in payload.concept:
        issues.append(_validation_issue("concept", "Concept must include a namespace prefix"))
    if payload.decimals < 0:
        issues.append(_validation_issue("decimals", "Decimals must be non-negative"))
    if period_type == XBRLPeriodType.DURATION and (
        not payload.period_start or not payload.period_end
    ):
        issues.append(
            _validation_issue(
                "period_range", "Duration facts require period_start and period_end",
            )
        )
    if period_type == XBRLPeriodType.INSTANT and not payload.instant_date:
        issues.append(_validation_issue("instant_date", "Instant facts require instant_date"))

    if issues or taxonomy is None or period_type is None:
        return None, issues

    fact = XBRLFact(
        concept=payload.concept,
        value=payload.value,
        taxonomy=taxonomy,
        period_type=period_type,
        period_start=payload.period_start,
        period_end=payload.period_end,
        instant_date=payload.instant_date,
        unit=payload.unit,
        decimals=payload.decimals,
        context_id=payload.context_id,
    )
    return fact, issues


def _build_fund_performance_report(payload: XBRLFundPerformanceRequest) -> XBRLReport:
    period_end = payload.period_end or date.today().isoformat()
    period_start = payload.period_start or date.fromisoformat(period_end).replace(day=1).isoformat()
    report = XBRLReport(
        report_id=f"PERF-{period_end}",
        reporting_period_start=period_start,
        reporting_period_end=period_end,
        taxonomy=XBRLTaxonomy.FUND,
    )
    report.facts = [
        XBRLFact(
            concept="rr:FundTotalReturn",
            value=payload.total_return,
            taxonomy=XBRLTaxonomy.FUND,
            period_type=XBRLPeriodType.DURATION,
            period_start=period_start,
            period_end=period_end,
            unit="ratio",
            decimals=4,
        ),
        XBRLFact(
            concept="rr:BenchmarkReturn",
            value=payload.benchmark_return,
            taxonomy=XBRLTaxonomy.FUND,
            period_type=XBRLPeriodType.DURATION,
            period_start=period_start,
            period_end=period_end,
            unit="ratio",
            decimals=4,
        ),
        XBRLFact(
            concept="rr:Alpha",
            value=payload.alpha,
            taxonomy=XBRLTaxonomy.FUND,
            period_type=XBRLPeriodType.DURATION,
            period_start=period_start,
            period_end=period_end,
            unit="ratio",
            decimals=4,
        ),
        XBRLFact(
            concept="rr:SharpeRatio",
            value=payload.sharpe_ratio,
            taxonomy=XBRLTaxonomy.FUND,
            instant_date=period_end,
            unit="ratio",
            decimals=4,
        ),
        XBRLFact(
            concept="rr:GrossExposure",
            value=payload.gross_exposure,
            taxonomy=XBRLTaxonomy.FUND,
            instant_date=period_end,
            unit="ratio",
            decimals=4,
        ),
        XBRLFact(
            concept="rr:NetExposure",
            value=payload.net_exposure,
            taxonomy=XBRLTaxonomy.FUND,
            instant_date=period_end,
            unit="ratio",
            decimals=4,
        ),
    ]
    xbrl_engine.reports[report.report_id] = report
    return report


def _serialize_document(payload: Any, rendered: str) -> DocumentResponse:
    return DocumentResponse(payload=_serialize(payload), rendered=rendered)


@router.post("/financial/xbrl/nav-report", response_model=DocumentResponse)
async def create_xbrl_nav_report(body: XBRLNavReportRequest) -> DocumentResponse:
    """Generate a fund NAV XBRL report."""
    report = xbrl_engine.create_nav_report(
        nav=body.nav,
        total_assets=body.total_assets,
        total_liabilities=body.total_liabilities,
        shares_outstanding=body.shares_outstanding,
        nav_per_share=body.nav_per_share,
        reporting_date=body.reporting_date,
    )
    return _serialize_document(report, xbrl_engine.to_xbrl_xml(report))


@router.post("/financial/xbrl/pnl-report", response_model=DocumentResponse)
async def create_xbrl_pnl_report(body: XBRLPnLReportRequest) -> DocumentResponse:
    """Generate a fund P&L XBRL report."""
    report = xbrl_engine.create_pnl_report(
        revenue=body.revenue,
        trading_gains=body.trading_gains,
        management_fees=body.management_fees,
        performance_fees=body.performance_fees,
        expenses=body.expenses,
        net_income=body.net_income,
        period_start=body.period_start,
        period_end=body.period_end,
    )
    return _serialize_document(report, xbrl_engine.to_xbrl_xml(report))


@router.post("/financial/xbrl/risk-disclosure", response_model=DocumentResponse)
async def create_xbrl_risk_disclosure(body: XBRLRiskDisclosureRequest) -> DocumentResponse:
    """Generate a fund risk disclosure XBRL report."""
    report = xbrl_engine.create_risk_disclosure(
        var_95=body.var_95,
        max_drawdown=body.max_drawdown,
        sharpe_ratio=body.sharpe_ratio,
        leverage_ratio=body.leverage_ratio,
        concentration_top5=body.concentration_top5,
    )
    return _serialize_document(report, xbrl_engine.to_xbrl_xml(report))


@router.post("/financial/xbrl/fund-performance", response_model=DocumentResponse)
async def create_xbrl_fund_performance(body: XBRLFundPerformanceRequest) -> DocumentResponse:
    """Generate a fund performance XBRL report."""
    report = _build_fund_performance_report(body)
    return _serialize_document(report, xbrl_engine.to_xbrl_xml(report))


@router.post("/financial/xbrl/validate", response_model=ValidationResponse)
async def validate_xbrl_facts(body: XBRLValidationRequest) -> ValidationResponse:
    """Validate XBRL facts before report generation."""
    normalized: list[dict[str, Any]] = []
    issues: list[ValidationIssueModel] = []
    for fact_payload in body.facts:
        fact, fact_issues = _normalize_xbrl_fact(fact_payload)
        issues.extend(fact_issues)
        if fact is not None:
            normalized.append(_serialize(fact))
    return ValidationResponse(valid=not issues, issues=issues, payload=normalized)


@router.get("/financial/xbrl/taxonomies", response_model=TaxonomyListResponse)
async def list_xbrl_taxonomies() -> TaxonomyListResponse:
    """List supported XBRL taxonomies."""
    return TaxonomyListResponse(taxonomies=[taxonomy.value for taxonomy in XBRLTaxonomy])


@router.post("/financial/iso20022/credit-transfer", response_model=DocumentResponse)
async def create_iso20022_credit_transfer(
    body: ISO20022CreditTransferRequest,
) -> DocumentResponse:
    """Create a pacs.008 customer credit transfer."""
    message = iso20022_engine.create_credit_transfer(
        creditor_name=body.creditor_name,
        creditor_bic=body.creditor_bic,
        amount=body.amount,
        currency=body.currency,
        remittance=body.remittance,
    )
    return _serialize_document(message, iso20022_engine.to_xml(message))


@router.post("/financial/iso20022/payment-initiation", response_model=DocumentResponse)
async def create_iso20022_payment_initiation(
    body: ISO20022PaymentInitiationRequest,
) -> DocumentResponse:
    """Create a pain.001 batch payment initiation."""
    message = iso20022_engine.create_payment_initiation(
        payments=[item.model_dump() for item in body.payments]
    )
    return _serialize_document(message, iso20022_engine.to_xml(message))


@router.post("/financial/iso20022/settlement", response_model=DocumentResponse)
async def create_iso20022_settlement(body: ISO20022SettlementRequest) -> DocumentResponse:
    """Create a sese.023 settlement instruction."""
    message = iso20022_engine.create_settlement_instruction(
        isin=body.isin,
        quantity=body.quantity,
        settlement_amount=body.settlement_amount,
        counterparty_bic=body.counterparty_bic,
        settlement_date=body.settlement_date,
    )
    return _serialize_document(message, iso20022_engine.to_xml(message))


@router.post("/financial/iso20022/fx-trade", response_model=DocumentResponse)
async def create_iso20022_fx_trade(body: ISO20022FXTradeRequest) -> DocumentResponse:
    """Create an fxtr.014 FX trade instruction."""
    message = iso20022_engine.create_fx_trade(
        buy_currency=body.buy_currency,
        buy_amount=body.buy_amount,
        sell_currency=body.sell_currency,
        sell_amount=body.sell_amount,
        counterparty_bic=body.counterparty_bic,
        value_date=body.value_date,
    )
    return _serialize_document(message, iso20022_engine.to_xml(message))


@router.post("/financial/iso20022/bank-statement", response_model=DocumentResponse)
async def create_iso20022_bank_statement(body: ISO20022BankStatementRequest) -> DocumentResponse:
    """Create a camt.053 bank statement."""
    message = PaymentMessage(
        message_type=ISO20022MessageType.CAMT_053,
        creditor_bic=body.receiver_bic,
        amount=body.closing_balance,
        currency=body.currency,
        remittance_info="BANK STATEMENT",
        metadata={
            "account_id": body.account_id,
            "statement_date": body.statement_date or date.today().isoformat(),
            "opening_balance": body.opening_balance,
            "closing_balance": body.closing_balance,
            "entries": [entry.model_dump() for entry in body.entries],
        },
    )
    iso20022_engine.messages.append(message)
    return _serialize_document(message, iso20022_engine.to_xml(message))


@router.post("/financial/iso20022/validate", response_model=ValidationResponse)
async def validate_iso20022_message(body: ISO20022ValidationRequest) -> ValidationResponse:
    """Validate a minimal ISO 20022 payment or statement envelope."""
    issues: list[ValidationIssueModel] = []
    try:
        ISO20022MessageType(body.message_type)
    except ValueError:
        issues.append(
            _validation_issue("message_type", f"Unsupported ISO 20022 message type: {body.message_type}")
        )
    if not _is_valid_bic(body.debtor_bic):
        issues.append(_validation_issue("debtor_bic", "Debtor BIC must be 8 or 11 uppercase characters"))
    if body.creditor_bic and not _is_valid_bic(body.creditor_bic):
        issues.append(_validation_issue("creditor_bic", "Creditor BIC must be 8 or 11 uppercase characters"))
    if body.amount < 0:
        issues.append(_validation_issue("amount", "Amount must be non-negative"))
    if not _is_valid_currency(body.currency):
        issues.append(_validation_issue("currency", "Currency must be a 3-letter uppercase ISO code"))
    return ValidationResponse(valid=not issues, issues=issues, payload=[body.model_dump()])


@router.post("/financial/fix/new-order", response_model=FIXOrderResponse)
async def submit_fix_new_order(body: FIXNewOrderRequest) -> FIXOrderResponse:
    """Submit a new FIX order."""
    side = _parse_fix_side(body.side)
    order_type = _parse_fix_order_type(body.order_type)
    time_in_force = _parse_fix_tif(body.time_in_force)
    if body.target not in fix_engine.sessions or not fix_engine.sessions[body.target].is_logged_on:
        fix_engine.logon(body.target, heartbeat=body.heartbeat)
    risk_price = body.price if body.price is not None else 1.0
    risk_result, risk_message = fix_engine.risk_engine.check_order(
        symbol=body.symbol,
        side=side,
        quantity=body.quantity,
        price=risk_price,
    )
    if risk_result != RiskCheckResult.PASSED:
        raise HTTPException(status_code=400, detail={"risk_check": risk_result.value, "message": risk_message})
    message = fix_engine.new_order_single(
        target=body.target,
        symbol=body.symbol,
        side=side,
        order_type=order_type,
        quantity=body.quantity,
        price=body.price,
        time_in_force=time_in_force,
        account=body.account,
        stop_price=body.stop_price,
        max_floor=body.max_floor,
    )
    order_status = fix_engine.get_order_status(message.get_field(11))
    return FIXOrderResponse(
        payload=_serialize(message),
        encoded_message=message.encode(),
        order_status=order_status,
        risk_check={"status": risk_result.value, "message": risk_message},
        session=_serialize_fix_session(body.target),
    )


@router.post("/financial/fix/cancel-order", response_model=FIXOrderResponse)
async def cancel_fix_order(body: FIXCancelOrderRequest) -> FIXOrderResponse:
    """Cancel an existing FIX order."""
    side = _parse_fix_side(body.side)
    if body.target not in fix_engine.sessions or not fix_engine.sessions[body.target].is_logged_on:
        fix_engine.logon(body.target)
    message = fix_engine.cancel_order(
        target=body.target,
        orig_cl_ord_id=body.orig_cl_ord_id,
        symbol=body.symbol,
        side=side,
    )
    return FIXOrderResponse(
        payload=_serialize(message),
        encoded_message=message.encode(),
        order_status=fix_engine.get_order_status(body.orig_cl_ord_id),
        risk_check={"status": RiskCheckResult.PASSED.value, "message": "Cancel request created"},
        session=_serialize_fix_session(body.target),
    )


@router.get("/financial/fix/session-status", response_model=FIXSessionStatusResponse)
async def get_fix_session_status(
    target: str | None = Query(default=None, description="Optional FIX target CompID filter"),
) -> FIXSessionStatusResponse:
    """Return FIX session health and execution summary."""
    sessions = [
        _serialize_fix_session(session_target)
        for session_target in fix_engine.sessions
        if target is None or session_target == target
    ]
    return FIXSessionStatusResponse(
        sessions=sessions,
        orders=len(fix_engine.orders),
        performance=fix_engine.get_performance_summary(),
    )


@router.post("/financial/swift/mt103", response_model=DocumentResponse)
async def create_swift_mt103(body: SWIFTMT103Request) -> DocumentResponse:
    """Create an MT103 SWIFT payment message."""
    message = swift_engine.create_payment(
        receiver_bic=body.receiver_bic,
        amount=body.amount,
        currency=body.currency,
        narrative=body.narrative,
    )
    return _serialize_document(message, message.to_mt_format())


@router.post("/financial/swift/mt202", response_model=DocumentResponse)
async def create_swift_mt202(body: SWIFTMT202Request) -> DocumentResponse:
    """Create an MT202 financial institution transfer."""
    message = SWIFTMessage(
        message_type=SWIFTMessageType.MT202,
        sender_bic=swift_engine.sender_bic,
        receiver_bic=body.receiver_bic,
        amount=body.amount,
        currency=body.currency,
        narrative=body.narrative or "FINANCIAL INSTITUTION TRANSFER",
        related_reference=body.related_reference,
    )
    swift_engine._apply_routing(
        message,
        sender_correspondent=body.sender_correspondent,
        account_with_institution=body.account_with_institution or body.receiver_bic,
        intermediaries=body.intermediaries,
        service_level="SWIFT GPI",
    )
    message = swift_engine._record_message(message)
    return _serialize_document(message, message.to_mt_format())


@router.get("/financial/swift/gpi-status", response_model=SWIFTTrackingResponse)
async def get_swift_gpi_status(
    reference: str = Query(..., description="SWIFT sender reference to track"),
) -> SWIFTTrackingResponse:
    """Return GPI tracking metadata for a generated SWIFT message."""
    return SWIFTTrackingResponse(**swift_engine.get_tracking_status(reference))


@router.post("/financial/fpml/irs", response_model=DocumentResponse)
async def create_fpml_irs(body: FpMLIRSRequest) -> DocumentResponse:
    """Create an FpML interest rate swap trade."""
    trade = fpml_engine.create_irs(
        notional=body.notional,
        fixed_rate=body.fixed_rate,
        floating_index=body.floating_index,
        tenor_years=body.tenor_years,
        currency=body.currency,
        payer=body.payer,
        receiver=body.receiver,
    )
    return _serialize_document(trade, fpml_engine.to_xml(trade))


@router.post("/financial/fpml/option", response_model=DocumentResponse)
async def create_fpml_option(body: FpMLOptionRequest) -> DocumentResponse:
    """Create an FpML option trade across supported structures."""
    structure = body.structure.lower()
    if structure == "swaption":
        if body.strike_rate is None:
            raise HTTPException(status_code=400, detail="strike_rate is required for swaptions")
        trade = fpml_engine.create_swaption(
            notional=body.notional,
            strike_rate=body.strike_rate,
            exercise_style=ExerciseStyle(body.exercise_style),
            underlying_tenor_years=body.underlying_tenor_years,
            expiry_date=body.expiry_date,
            currency=body.currency,
            payer=body.payer,
            receiver=body.receiver,
            floating_index=body.floating_index,
            option_type=body.option_type,
            bermudan_dates=body.bermudan_dates or None,
            settlement_type=body.settlement_type,
        )
    elif structure == "barrier":
        if body.strike is None or body.barrier_level is None:
            raise HTTPException(status_code=400, detail="strike and barrier_level are required")
        trade = fpml_engine.create_barrier_option(
            underlying=body.underlying,
            notional=body.notional,
            strike=body.strike,
            barrier_level=body.barrier_level,
            option_type=body.option_type,
            barrier_direction=BarrierDirection(body.barrier_direction),
            barrier_type=BarrierType(body.barrier_type),
            expiry_date=body.expiry_date,
            currency=body.currency,
            monitoring_frequency=body.monitoring_frequency,
            rebate=body.rebate,
        )
    elif structure == "lookback":
        if body.strike is None:
            raise HTTPException(status_code=400, detail="strike is required for lookback options")
        trade = fpml_engine.create_lookback_option(
            underlying=body.underlying,
            notional=body.notional,
            strike=body.strike,
            option_type=body.option_type,
            observation_start=body.observation_start,
            observation_end=body.observation_end,
            currency=body.currency,
        )
    else:
        if body.strike is None:
            raise HTTPException(status_code=400, detail="strike is required for option trades")
        trade = fpml_engine.create_asian_option(
            underlying=body.underlying,
            notional=body.notional,
            strike=body.strike,
            option_type=body.option_type,
            expiry_date=body.expiry_date,
            currency=body.currency,
            averaging_method=AveragingMethod(body.averaging_method),
            averaging_frequency=body.averaging_frequency,
        )
    return _serialize_document(trade, fpml_engine.to_xml(trade))


@router.post("/financial/isda/trade-event", response_model=ISDAResponse)
async def record_isda_trade_event(body: ISDATradeEventRequest) -> ISDAResponse:
    """Record an ISDA CDM trade execution event."""
    trade = isda_engine.create_trade(
        product_type=body.product_type,
        parties=body.parties,
        economic_terms=body.economic_terms,
    )
    lifecycle = isda_engine.get_trade_lifecycle(trade.trade_id)
    return ISDAResponse(
        trade=_serialize(trade),
        latest_event=lifecycle[-1],
        lifecycle=lifecycle,
    )


@router.post("/financial/isda/lifecycle", response_model=ISDAResponse)
async def process_isda_lifecycle_event(body: ISDALifecycleRequest) -> ISDAResponse:
    """Process an ISDA CDM lifecycle event for an existing trade."""
    lifecycle_event = body.lifecycle_event.lower()
    if lifecycle_event == "confirmation":
        event = isda_engine.confirm_trade(body.trade_id)
    elif lifecycle_event == "clearing":
        event = isda_engine.clear_trade(body.trade_id, ccp=body.ccp)
    elif lifecycle_event == "settlement":
        event = isda_engine.settle_trade(body.trade_id, settlement_amount=body.settlement_amount)
    elif lifecycle_event == "margin_call":
        event = isda_engine.process_margin_call(
            body.trade_id,
            margin_amount=body.margin_amount,
            margin_type=body.margin_type,
        )
    elif lifecycle_event == "novation":
        event = isda_engine.novate_trade(body.trade_id, old_party=body.old_party, new_party=body.new_party)
    elif lifecycle_event == "termination":
        event = isda_engine.terminate_trade(
            body.trade_id,
            termination_amount=body.termination_amount,
        )
    elif lifecycle_event == "exercise":
        event = isda_engine.exercise_option(
            body.trade_id,
            exercise_type=ExerciseType(body.exercise_type),
            outcome=ExerciseOutcome(body.exercise_outcome),
            settlement_amount=body.settlement_amount,
        )
    elif lifecycle_event == "reset":
        event = isda_engine.process_reset(
            body.trade_id,
            fixing_rate=body.fixing_rate,
            reset_date=body.reset_date,
        )
    elif lifecycle_event == "credit_event":
        event = isda_engine.process_credit_event(
            body.trade_id,
            credit_event=CreditEventType(body.credit_event_type),
            reference_entity=body.reference_entity,
            recovery_rate=body.recovery_rate,
        )
    elif lifecycle_event == "partial_termination":
        event = isda_engine.partial_termination(
            body.trade_id,
            reduction_notional=body.reduction_notional,
        )
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported lifecycle event: {body.lifecycle_event}")

    trade = isda_engine.trades.get(body.trade_id)
    if event is None or trade is None:
        raise HTTPException(status_code=404, detail=f"Unable to process lifecycle event for trade {body.trade_id}")
    lifecycle = isda_engine.get_trade_lifecycle(body.trade_id)
    return ISDAResponse(
        trade=_serialize(trade),
        latest_event=_serialize(event),
        lifecycle=lifecycle,
    )
