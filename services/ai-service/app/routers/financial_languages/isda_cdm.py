"""ISDA CDM Engine — Common Domain Model for trade lifecycle events.

Implements ISDA's Common Domain Model for standardized trade
representation and lifecycle event processing.
"""

from __future__ import annotations

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


class TradeStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CLEARED = "cleared"
    SETTLED = "settled"
    MATURED = "matured"
    TERMINATED = "terminated"
    DEFAULTED = "defaulted"


@dataclass
class TradeEvent:
    """ISDA CDM Trade Lifecycle Event."""
    event_id: str = ""
    event_type: EventType = EventType.EXECUTION
    timestamp: str = ""
    trade_id: str = ""
    parties: list[str] = field(default_factory=list)
    economic_terms: dict[str, Any] = field(default_factory=dict)
    lineage: list[str] = field(default_factory=list)  # Prior event chain
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.event_id:
            self.event_id = f"EVT-{uuid.uuid4().hex[:12].upper()}"
        if not self.timestamp:
            self.timestamp = datetime.utcnow().isoformat() + "Z"


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


class ISDACDMEngine:
    """ISDA Common Domain Model engine for trade lifecycle management."""

    def __init__(self) -> None:
        self.trades: dict[str, CDMTrade] = {}
        self.events: list[TradeEvent] = []

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

        # Create execution event
        exec_event = TradeEvent(
            event_type=EventType.EXECUTION,
            trade_id=trade_id,
            parties=parties,
            economic_terms=economic_terms,
        )
        trade.events.append(exec_event)
        self.events.append(exec_event)
        self.trades[trade_id] = trade
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
        self.events.append(event)
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
            economic_terms={
                "margin_amount": margin_amount,
                "margin_type": margin_type,
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.events.append(event)
        trade.collateral[margin_type] = trade.collateral.get(margin_type, 0) + margin_amount
        self.events.append(event)
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
            metadata={
                "stepping_out": old_party,
                "stepping_in": new_party,
            },
            lineage=[e.event_id for e in trade.events],
        )
        trade.parties = [new_party if p == old_party else p for p in trade.parties]
        trade.events.append(event)
        self.events.append(event)
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
        return event

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
            }
            for e in trade.events
        ]
