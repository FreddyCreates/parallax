"""ISDA CDM Engine — Common Domain Model for trade lifecycle events.

Implements ISDA's Common Domain Model for standardized trade
representation, lifecycle event processing, collateral management,
regulatory reporting, and credit event handling.
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any


class EventType(str, Enum):
    EXECUTION = "execution"
    CONFIRMATION = "confirmation"
    CLEARING = "clearing"
    SETTLEMENT = "settlement"
    VALUATION = "valuation"
    AMENDMENT = "amendment"
    NOVATION = "novation"
    TERMINATION = "termination"
    COMPRESSION = "compression"
    EXERCISE = "exercise"
    RESET = "reset"
    TRANSFER = "transfer"
    ALLOCATION = "allocation"
    MARGIN_CALL = "margin_call"
    COLLATERAL = "collateral"
    CREDIT_EVENT = "credit_event"
    PARTIAL_TERMINATION = "partial_termination"
    INCREASE = "increase"
    NETTING = "netting"
    REGULATORY_REPORT = "regulatory_report"


class TradeStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CLEARED = "cleared"
    SETTLED = "settled"
    MATURED = "matured"
    TERMINATED = "terminated"
    DEFAULTED = "defaulted"
    DISPUTED = "disputed"
    COMPRESSED = "compressed"
    NOVATED = "novated"


class ExerciseType(str, Enum):
    EUROPEAN = "european"
    AMERICAN = "american"
    BERMUDAN = "bermudan"
    AUTOMATIC = "automatic"


class ExerciseOutcome(str, Enum):
    CASH_SETTLEMENT = "cash_settlement"
    PHYSICAL_DELIVERY = "physical_delivery"
    EXPIRED = "expired"
    ABANDONED = "abandoned"


class CreditEventType(str, Enum):
    BANKRUPTCY = "bankruptcy"
    FAILURE_TO_PAY = "failure_to_pay"
    RESTRUCTURING = "restructuring"
    OBLIGATION_ACCELERATION = "obligation_acceleration"
    OBLIGATION_DEFAULT = "obligation_default"
    REPUDIATION = "repudiation"
    GOVERNMENTAL_INTERVENTION = "governmental_intervention"


class MarginType(str, Enum):
    INITIAL = "initial"
    VARIATION = "variation"
    ADDITIONAL = "additional"


class ReportingRegime(str, Enum):
    EMIR = "emir"
    DODD_FRANK = "dodd_frank"
    MIFID2 = "mifid2"
    SFTR = "sftr"
    ASIC = "asic"
    MAS = "mas"


class WorkflowState(str, Enum):
    INITIATED = "initiated"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    REJECTED = "rejected"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class TradeEvent:
    """ISDA CDM Trade Lifecycle Event."""
    event_id: str = ""
    event_type: EventType = EventType.EXECUTION
    timestamp: str = ""
    trade_id: str = ""
    parties: list[str] = field(default_factory=list)
    economic_terms: dict[str, Any] = field(default_factory=dict)
    lineage: list[str] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)
    hash_value: str = ""

    def __post_init__(self) -> None:
        if not self.event_id:
            self.event_id = f"EVT-{uuid.uuid4().hex[:12].upper()}"
        if not self.timestamp:
            self.timestamp = datetime.utcnow().isoformat() + "Z"
        if not self.hash_value:
            self.hash_value = self._compute_hash()

    def _compute_hash(self) -> str:
        """Compute hash for audit trail integrity."""
        content = f"{self.event_id}{self.event_type.value}{self.trade_id}{self.timestamp}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]


@dataclass
class CDMTrade:
    """CDM Trade representation with full lifecycle."""
    trade_id: str
    status: TradeStatus = TradeStatus.PENDING
    product_type: str = ""
    parties: list[str] = field(default_factory=list)
    economic_terms: dict[str, Any] = field(default_factory=dict)
    events: list[TradeEvent] = field(default_factory=list)
    collateral: dict[str, float] = field(default_factory=dict)
    valuations: list[dict[str, Any]] = field(default_factory=list)
    workflow_state: WorkflowState = WorkflowState.INITIATED
    regulatory_reports: list[dict[str, Any]] = field(default_factory=list)
    netting_set: str = ""


@dataclass
class CollateralState:
    """Collateral management state."""
    trade_id: str
    initial_margin: float = 0.0
    variation_margin: float = 0.0
    additional_margin: float = 0.0
    collateral_posted: dict[str, float] = field(default_factory=dict)
    collateral_received: dict[str, float] = field(default_factory=dict)
    margin_calls_pending: list[dict[str, Any]] = field(default_factory=list)
    last_margin_date: str = ""
    threshold: float = 0.0
    minimum_transfer: float = 100_000.0


@dataclass
class NettingSet:
    """Netting set for close-out and payment netting."""
    netting_set_id: str
    parties: list[str] = field(default_factory=list)
    trade_ids: list[str] = field(default_factory=list)
    net_exposure: float = 0.0
    gross_exposure: float = 0.0
    netting_benefit: float = 0.0
    agreement_type: str = "ISDA_MA"  # Master Agreement type


@dataclass
class CompressionProposal:
    """Portfolio compression proposal."""
    proposal_id: str
    trade_ids: list[str] = field(default_factory=list)
    replacement_trades: list[dict[str, Any]] = field(default_factory=list)
    notional_reduction: float = 0.0
    trade_count_reduction: int = 0
    status: WorkflowState = WorkflowState.INITIATED
    participants: list[str] = field(default_factory=list)


@dataclass
class AuditEntry:
    """Immutable audit trail entry."""
    entry_id: str
    event_id: str
    trade_id: str
    action: str
    actor: str
    timestamp: str
    previous_hash: str = ""
    current_hash: str = ""
    details: dict[str, Any] = field(default_factory=dict)


class CollateralManager:
    """Collateral and margin management engine."""

    def __init__(self) -> None:
        self.collateral_states: dict[str, CollateralState] = {}

    def initialize_collateral(
        self, trade_id: str, threshold: float = 500_000.0, min_transfer: float = 100_000.0
    ) -> CollateralState:
        """Initialize collateral tracking for a trade."""
        state = CollateralState(
            trade_id=trade_id,
            threshold=threshold,
            minimum_transfer=min_transfer,
        )
        self.collateral_states[trade_id] = state
        return state

    def calculate_margin_call(
        self, trade_id: str, current_mtm: float, margin_type: MarginType = MarginType.VARIATION
    ) -> dict[str, Any] | None:
        """Calculate margin call based on current MTM."""
        state = self.collateral_states.get(trade_id)
        if not state:
            return None

        exposure = abs(current_mtm)
        existing_margin = state.variation_margin if margin_type == MarginType.VARIATION else state.initial_margin

        required = max(0, exposure - state.threshold)
        call_amount = required - existing_margin

        if call_amount < state.minimum_transfer:
            return None

        call = {
            "trade_id": trade_id,
            "margin_type": margin_type.value,
            "call_amount": call_amount,
            "current_exposure": exposure,
            "existing_margin": existing_margin,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }
        state.margin_calls_pending.append(call)
        return call

    def post_collateral(
        self, trade_id: str, asset_type: str, amount: float, margin_type: MarginType
    ) -> dict[str, Any] | None:
        """Post collateral against margin requirement."""
        state = self.collateral_states.get(trade_id)
        if not state:
            return None

        state.collateral_posted[asset_type] = state.collateral_posted.get(asset_type, 0) + amount
        if margin_type == MarginType.INITIAL:
            state.initial_margin += amount
        elif margin_type == MarginType.VARIATION:
            state.variation_margin += amount
        else:
            state.additional_margin += amount

        state.last_margin_date = datetime.utcnow().isoformat()
        return {
            "trade_id": trade_id,
            "posted": amount,
            "asset_type": asset_type,
            "margin_type": margin_type.value,
            "total_collateral": sum(state.collateral_posted.values()),
        }

    def substitute_collateral(
        self, trade_id: str, remove_asset: str, remove_amount: float, add_asset: str, add_amount: float
    ) -> dict[str, Any] | None:
        """Substitute one form of collateral for another."""
        state = self.collateral_states.get(trade_id)
        if not state:
            return None
        current = state.collateral_posted.get(remove_asset, 0)
        if current < remove_amount:
            return None
        state.collateral_posted[remove_asset] -= remove_amount
        state.collateral_posted[add_asset] = state.collateral_posted.get(add_asset, 0) + add_amount
        return {
            "trade_id": trade_id,
            "removed": {"asset": remove_asset, "amount": remove_amount},
            "added": {"asset": add_asset, "amount": add_amount},
        }


class RegulatoryReporter:
    """Regulatory reporting engine for trade reporting obligations."""

    def __init__(self) -> None:
        self.reports: list[dict[str, Any]] = []

    def generate_report(
        self, trade: CDMTrade, regime: ReportingRegime, action: str = "NEW"
    ) -> dict[str, Any]:
        """Generate regulatory report for a trade."""
        uti = f"PRLX{hashlib.sha256(trade.trade_id.encode()).hexdigest()[:20].upper()}"
        report = {
            "uti": uti,
            "trade_id": trade.trade_id,
            "regime": regime.value,
            "action": action,
            "reporting_timestamp": datetime.utcnow().isoformat() + "Z",
            "product_type": trade.product_type,
            "parties": trade.parties,
            "notional": trade.economic_terms.get("notional", 0),
            "currency": trade.economic_terms.get("currency", "USD"),
            "effective_date": trade.economic_terms.get("effective_date", ""),
            "termination_date": trade.economic_terms.get("termination_date", ""),
            "status": trade.status.value,
        }

        # Regime-specific fields
        if regime == ReportingRegime.EMIR:
            report.update({
                "lei_counterparty_1": f"LEI-{trade.parties[0][:16]}" if trade.parties else "",
                "lei_counterparty_2": f"LEI-{trade.parties[1][:16]}" if len(trade.parties) > 1 else "",
                "intragroup": False,
                "clearing_obligation": trade.status == TradeStatus.CLEARED,
            })
        elif regime == ReportingRegime.DODD_FRANK:
            report.update({
                "swap_data_repository": "DTCC",
                "block_trade": trade.economic_terms.get("notional", 0) > 50_000_000,
                "execution_venue": trade.economic_terms.get("venue", "OFF_FACILITY"),
            })
        elif regime == ReportingRegime.MIFID2:
            report.update({
                "trading_venue": trade.economic_terms.get("venue", "XOFF"),
                "transaction_reference": uti,
                "buyer_seller": trade.parties[:2] if len(trade.parties) >= 2 else trade.parties,
            })

        self.reports.append(report)
        trade.regulatory_reports.append(report)
        return report

    def generate_emir_report(self, trade: CDMTrade) -> dict[str, Any]:
        return self.generate_report(trade, ReportingRegime.EMIR)

    def generate_dodd_frank_report(self, trade: CDMTrade) -> dict[str, Any]:
        return self.generate_report(trade, ReportingRegime.DODD_FRANK)


class AuditTrailEngine:
    """Immutable audit trail with hash chain."""

    def __init__(self) -> None:
        self.entries: list[AuditEntry] = []
        self.last_hash: str = "GENESIS"

    def record(self, event: TradeEvent, actor: str, action: str, details: dict[str, Any] | None = None) -> AuditEntry:
        """Record an audit entry with hash chain integrity."""
        content = f"{event.event_id}{action}{actor}{self.last_hash}"
        current_hash = hashlib.sha256(content.encode()).hexdigest()[:32]

        entry = AuditEntry(
            entry_id=f"AUD-{uuid.uuid4().hex[:12].upper()}",
            event_id=event.event_id,
            trade_id=event.trade_id,
            action=action,
            actor=actor,
            timestamp=datetime.utcnow().isoformat() + "Z",
            previous_hash=self.last_hash,
            current_hash=current_hash,
            details=details or {},
        )
        self.entries.append(entry)
        self.last_hash = current_hash
        return entry

    def verify_chain(self) -> bool:
        """Verify integrity of audit trail hash chain."""
        if not self.entries:
            return True
        prev_hash = "GENESIS"
        for entry in self.entries:
            if entry.previous_hash != prev_hash:
                return False
            prev_hash = entry.current_hash
        return True

    def get_trade_audit(self, trade_id: str) -> list[dict[str, Any]]:
        """Get audit trail for a specific trade."""
        return [
            {
                "entry_id": e.entry_id,
                "action": e.action,
                "actor": e.actor,
                "timestamp": e.timestamp,
                "hash": e.current_hash,
            }
            for e in self.entries if e.trade_id == trade_id
        ]


class CompressionEngine:
    """Portfolio compression engine for trade reduction."""

    def __init__(self) -> None:
        self.proposals: list[CompressionProposal] = []

    def identify_candidates(self, trades: list[CDMTrade]) -> list[list[str]]:
        """Identify groups of trades eligible for compression."""
        # Group by party pair and product type
        groups: dict[str, list[str]] = {}
        for trade in trades:
            if trade.status not in (TradeStatus.CONFIRMED, TradeStatus.CLEARED):
                continue
            key = f"{sorted(trade.parties)}-{trade.product_type}"
            if key not in groups:
                groups[key] = []
            groups[key].append(trade.trade_id)

        # Only groups with 2+ trades are candidates
        return [ids for ids in groups.values() if len(ids) >= 2]

    def create_proposal(
        self, trades: list[CDMTrade], target_reduction_pct: float = 0.5
    ) -> CompressionProposal:
        """Create a compression proposal."""
        total_notional = sum(t.economic_terms.get("notional", 0) for t in trades)
        net_notional = abs(sum(
            t.economic_terms.get("notional", 0) * (1 if "payer" in str(t.parties[0:1]) else -1)
            for t in trades
        ))

        proposal = CompressionProposal(
            proposal_id=f"COMP-{uuid.uuid4().hex[:12].upper()}",
            trade_ids=[t.trade_id for t in trades],
            notional_reduction=total_notional - net_notional,
            trade_count_reduction=len(trades) - 1,
            participants=list(set(p for t in trades for p in t.parties)),
        )

        if net_notional > 0:
            proposal.replacement_trades.append({
                "product_type": trades[0].product_type,
                "notional": net_notional,
                "parties": list(set(p for t in trades for p in t.parties))[:2],
            })

        self.proposals.append(proposal)
        return proposal


class ValuationEngine:
    """Independent valuation and reconciliation."""

    def __init__(self) -> None:
        self.valuations: list[dict[str, Any]] = []

    def value_trade(self, trade: CDMTrade, market_data: dict[str, float]) -> dict[str, Any]:
        """Value a trade given market data."""
        notional = trade.economic_terms.get("notional", 0)
        fixed_rate = trade.economic_terms.get("fixed_rate", 0)
        market_rate = market_data.get("rate", 0.03)
        remaining_years = trade.economic_terms.get("remaining_years", 3)

        # Simplified swap valuation
        if "swap" in trade.product_type.lower():
            mtm = notional * (market_rate - fixed_rate) * remaining_years * 0.95  # PV01 approx
        else:
            mtm = notional * 0.01  # Default 1% for other products

        valuation = {
            "trade_id": trade.trade_id,
            "mtm": mtm,
            "currency": trade.economic_terms.get("currency", "USD"),
            "valuation_date": datetime.utcnow().isoformat(),
            "methodology": "analytical",
            "market_data_snapshot": market_data,
        }
        trade.valuations.append(valuation)
        self.valuations.append(valuation)
        return valuation

    def reconcile(self, trade_id: str, our_mtm: float, cpty_mtm: float, tolerance: float = 10000.0) -> dict[str, Any]:
        """Reconcile valuations between counterparties."""
        diff = abs(our_mtm - cpty_mtm)
        agreed = diff <= tolerance
        return {
            "trade_id": trade_id,
            "our_mtm": our_mtm,
            "counterparty_mtm": cpty_mtm,
            "difference": diff,
            "within_tolerance": agreed,
            "tolerance": tolerance,
            "status": "agreed" if agreed else "disputed",
        }


class ISDACDMEngine:
    """ISDA Common Domain Model engine for trade lifecycle management."""

    def __init__(self) -> None:
        self.trades: dict[str, CDMTrade] = {}
        self.events: list[TradeEvent] = []
        self.collateral_manager = CollateralManager()
        self.regulatory_reporter = RegulatoryReporter()
        self.audit_trail = AuditTrailEngine()
        self.compression_engine = CompressionEngine()
        self.valuation_engine = ValuationEngine()
        self.netting_sets: dict[str, NettingSet] = {}

    def create_trade(
        self,
        product_type: str,
        parties: list[str],
        economic_terms: dict[str, Any],
    ) -> CDMTrade:
        """Create a new trade with execution event."""
        trade_id = f"TRD-{uuid.uuid4().hex[:12].upper()}"
        trade = CDMTrade(
            trade_id=trade_id,
            product_type=product_type,
            parties=parties,
            economic_terms=economic_terms,
        )

        exec_event = TradeEvent(
            event_type=EventType.EXECUTION,
            trade_id=trade_id,
            parties=parties,
            economic_terms=economic_terms,
        )
        trade.events.append(exec_event)
        self.events.append(exec_event)
        self.trades[trade_id] = trade

        # Audit
        self.audit_trail.record(exec_event, "SYSTEM", "TRADE_CREATED")
        # Initialize collateral
        self.collateral_manager.initialize_collateral(trade_id)

        return trade

    def confirm_trade(self, trade_id: str) -> TradeEvent | None:
        """Process trade confirmation."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.CONFIRMATION,
            trade_id=trade_id,
            parties=trade.parties,
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.status = TradeStatus.CONFIRMED
        trade.workflow_state = WorkflowState.COMPLETED
        self.events.append(event)
        self.audit_trail.record(event, "CONFIRMATION_SERVICE", "TRADE_CONFIRMED")
        return event

    def clear_trade(self, trade_id: str, ccp: str = "LCH") -> TradeEvent | None:
        """Submit trade for clearing."""
        trade = self.trades.get(trade_id)
        if not trade or trade.status != TradeStatus.CONFIRMED:
            return None

        event = TradeEvent(
            event_type=EventType.CLEARING,
            trade_id=trade_id,
            parties=trade.parties + [ccp],
            metadata={"ccp": ccp, "clearing_member": trade.parties[0]},
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.status = TradeStatus.CLEARED
        self.events.append(event)
        self.audit_trail.record(event, ccp, "TRADE_CLEARED")
        return event

    def settle_trade(self, trade_id: str, settlement_amount: float) -> TradeEvent | None:
        """Process trade settlement."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.SETTLEMENT,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={"settlement_amount": settlement_amount},
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.status = TradeStatus.SETTLED
        self.events.append(event)
        self.audit_trail.record(event, "SETTLEMENT_SERVICE", "TRADE_SETTLED")
        return event

    def process_margin_call(
        self, trade_id: str, margin_amount: float, margin_type: str = "variation"
    ) -> TradeEvent | None:
        """Process margin call event."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.MARGIN_CALL,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={"margin_amount": margin_amount, "margin_type": margin_type},
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.collateral[margin_type] = trade.collateral.get(margin_type, 0) + margin_amount
        self.events.append(event)
        self.audit_trail.record(event, "MARGIN_SERVICE", "MARGIN_CALL_PROCESSED")
        return event

    def novate_trade(
        self, trade_id: str, old_party: str, new_party: str
    ) -> TradeEvent | None:
        """Process novation — transfer obligation to new party."""
        trade = self.trades.get(trade_id)
        if not trade or old_party not in trade.parties:
            return None

        event = TradeEvent(
            event_type=EventType.NOVATION,
            trade_id=trade_id,
            parties=trade.parties + [new_party],
            metadata={"stepping_out": old_party, "stepping_in": new_party},
            lineage=[e.event_id for e in trade.events],
        )
        trade.parties = [new_party if p == old_party else p for p in trade.parties]
        trade.events.append(event)
        self.events.append(event)
        self.audit_trail.record(event, "NOVATION_SERVICE", "TRADE_NOVATED")
        return event

    def terminate_trade(self, trade_id: str, termination_amount: float = 0.0) -> TradeEvent | None:
        """Early termination of trade."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.TERMINATION,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={"termination_amount": termination_amount},
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.status = TradeStatus.TERMINATED
        self.events.append(event)
        self.audit_trail.record(event, "LIFECYCLE_SERVICE", "TRADE_TERMINATED")
        return event

    def exercise_option(
        self,
        trade_id: str,
        exercise_type: ExerciseType = ExerciseType.EUROPEAN,
        outcome: ExerciseOutcome = ExerciseOutcome.CASH_SETTLEMENT,
        settlement_amount: float = 0.0,
    ) -> TradeEvent | None:
        """Process option exercise event."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.EXERCISE,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={
                "exercise_type": exercise_type.value,
                "outcome": outcome.value,
                "settlement_amount": settlement_amount,
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        if outcome == ExerciseOutcome.EXPIRED:
            trade.status = TradeStatus.MATURED
        self.events.append(event)
        self.audit_trail.record(event, "EXERCISE_SERVICE", "OPTION_EXERCISED")
        return event

    def process_reset(
        self, trade_id: str, fixing_rate: float, reset_date: str = ""
    ) -> TradeEvent | None:
        """Process floating rate reset/fixing event."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        event = TradeEvent(
            event_type=EventType.RESET,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={
                "fixing_rate": fixing_rate,
                "reset_date": reset_date or datetime.utcnow().isoformat(),
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        self.events.append(event)
        return event

    def process_credit_event(
        self,
        trade_id: str,
        credit_event: CreditEventType,
        reference_entity: str,
        recovery_rate: float = 0.4,
    ) -> TradeEvent | None:
        """Process credit event (for CDS)."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        notional = trade.economic_terms.get("notional", 0)
        payout = notional * (1 - recovery_rate)

        event = TradeEvent(
            event_type=EventType.CREDIT_EVENT,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={
                "credit_event_type": credit_event.value,
                "reference_entity": reference_entity,
                "recovery_rate": recovery_rate,
                "payout_amount": payout,
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.status = TradeStatus.TERMINATED
        self.events.append(event)
        self.audit_trail.record(event, "CREDIT_EVENT_SERVICE", "CREDIT_EVENT_TRIGGERED")
        return event

    def partial_termination(self, trade_id: str, reduction_notional: float) -> TradeEvent | None:
        """Partially terminate a trade (reduce notional)."""
        trade = self.trades.get(trade_id)
        if not trade:
            return None

        current_notional = trade.economic_terms.get("notional", 0)
        new_notional = current_notional - reduction_notional

        event = TradeEvent(
            event_type=EventType.PARTIAL_TERMINATION,
            trade_id=trade_id,
            parties=trade.parties,
            economic_terms={
                "original_notional": current_notional,
                "reduction": reduction_notional,
                "new_notional": new_notional,
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.economic_terms["notional"] = new_notional
        trade.events.append(event)
        self.events.append(event)
        return event

    def create_netting_set(self, parties: list[str], trade_ids: list[str]) -> NettingSet:
        """Create a netting set for close-out netting."""
        ns_id = f"NS-{uuid.uuid4().hex[:8].upper()}"
        gross = 0.0
        net = 0.0
        for tid in trade_ids:
            trade = self.trades.get(tid)
            if trade and trade.valuations:
                mtm = trade.valuations[-1].get("mtm", 0)
                gross += abs(mtm)
                net += mtm

        ns = NettingSet(
            netting_set_id=ns_id,
            parties=parties,
            trade_ids=trade_ids,
            net_exposure=abs(net),
            gross_exposure=gross,
            netting_benefit=1 - abs(net) / gross if gross > 0 else 0.0,
        )
        self.netting_sets[ns_id] = ns
        return ns

    def close_out_netting(self, netting_set_id: str) -> dict[str, Any] | None:
        """Execute close-out netting on default."""
        ns = self.netting_sets.get(netting_set_id)
        if not ns:
            return None

        net_amount = 0.0
        terminated_trades = []
        for tid in ns.trade_ids:
            trade = self.trades.get(tid)
            if trade:
                mtm = trade.valuations[-1].get("mtm", 0) if trade.valuations else 0
                net_amount += mtm
                self.terminate_trade(tid, abs(mtm))
                terminated_trades.append(tid)

        return {
            "netting_set_id": netting_set_id,
            "net_settlement_amount": net_amount,
            "trades_terminated": len(terminated_trades),
            "gross_exposure_eliminated": ns.gross_exposure,
        }

    def get_trade_lifecycle(self, trade_id: str) -> list[dict[str, Any]]:
        """Get complete lifecycle event chain for a trade."""
        trade = self.trades.get(trade_id)
        if not trade:
            return []

        return [
            {
                "event_id": e.event_id,
                "type": e.event_type.value,
                "timestamp": e.timestamp,
                "parties": e.parties,
                "economic_terms": e.economic_terms,
                "hash": e.hash_value,
            }
            for e in trade.events
        ]

    def get_portfolio_summary(self) -> dict[str, Any]:
        """Get summary of entire trade portfolio."""
        by_status: dict[str, int] = {}
        by_product: dict[str, int] = {}
        total_notional = 0.0

        for trade in self.trades.values():
            by_status[trade.status.value] = by_status.get(trade.status.value, 0) + 1
            by_product[trade.product_type] = by_product.get(trade.product_type, 0) + 1
            total_notional += trade.economic_terms.get("notional", 0)

        return {
            "total_trades": len(self.trades),
            "total_events": len(self.events),
            "total_notional": total_notional,
            "by_status": by_status,
            "by_product": by_product,
            "audit_chain_valid": self.audit_trail.verify_chain(),
            "netting_sets": len(self.netting_sets),
        }
