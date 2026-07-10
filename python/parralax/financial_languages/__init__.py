"""PARRALAX Financial Languages Integration.

Bridges between internal trading formats and industry-standard
financial messaging protocols (FIX, SWIFT, FpML, ISDA CDM, XBRL, ISO 20022).
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any


class Protocol(str, Enum):
    FIX = "FIX"
    FPML = "FpML"
    SWIFT = "SWIFT"
    ISDA_CDM = "ISDA_CDM"
    XBRL = "XBRL"
    ISO20022 = "ISO20022"


@dataclass
class ProtocolMessage:
    protocol: Protocol
    message_type: str
    payload: dict[str, Any]
    raw: str = ""


class FinancialLanguageRouter:
    """Routes internal trade events to appropriate financial messaging protocol.

    Determines which protocol(s) to use based on:
    - Asset class (equities → FIX, OTC derivatives → FpML, payments → SWIFT/ISO20022)
    - Counterparty requirements
    - Regulatory jurisdiction (XBRL for reporting)
    - Trade lifecycle stage (ISDA CDM for events)
    """

    # Protocol selection rules by asset class
    ASSET_CLASS_PROTOCOLS: dict[str, list[Protocol]] = {
        "equity": [Protocol.FIX, Protocol.SWIFT],
        "futures": [Protocol.FIX],
        "options": [Protocol.FIX, Protocol.FPML],
        "fx": [Protocol.FIX, Protocol.SWIFT, Protocol.ISO20022],
        "fx_derivative": [Protocol.FPML, Protocol.ISDA_CDM],
        "interest_rate": [Protocol.FPML, Protocol.ISDA_CDM],
        "credit": [Protocol.FPML, Protocol.ISDA_CDM],
        "crypto": [Protocol.FIX],
        "commodity": [Protocol.FIX, Protocol.FPML],
    }

    # Lifecycle events → ISDA CDM
    LIFECYCLE_EVENTS = [
        "execution", "confirmation", "clearing", "settlement",
        "novation", "termination", "amendment", "exercise",
    ]

    def __init__(self) -> None:
        self.message_log: list[ProtocolMessage] = []

    def route_trade(
        self,
        asset_class: str,
        event_type: str,
        trade_data: dict[str, Any],
    ) -> list[ProtocolMessage]:
        """Route a trade event to appropriate protocols."""
        messages = []

        # Get protocols for asset class
        protocols = self.ASSET_CLASS_PROTOCOLS.get(
            asset_class, [Protocol.FIX]
        )

        # Always use ISDA CDM for lifecycle events
        if event_type in self.LIFECYCLE_EVENTS:
            protocols = list(set(protocols + [Protocol.ISDA_CDM]))

        for proto in protocols:
            msg = ProtocolMessage(
                protocol=proto,
                message_type=event_type,
                payload=trade_data,
            )
            messages.append(msg)
            self.message_log.append(msg)

        return messages

    def route_payment(self, payment_data: dict[str, Any]) -> list[ProtocolMessage]:
        """Route payment to SWIFT and ISO 20022."""
        messages = []
        for proto in [Protocol.SWIFT, Protocol.ISO20022]:
            msg = ProtocolMessage(
                protocol=proto,
                message_type="credit_transfer",
                payload=payment_data,
            )
            messages.append(msg)
            self.message_log.append(msg)
        return messages

    def route_regulatory_report(
        self, report_type: str, data: dict[str, Any]
    ) -> ProtocolMessage:
        """Route to XBRL for regulatory reporting."""
        msg = ProtocolMessage(
            protocol=Protocol.XBRL,
            message_type=report_type,
            payload=data,
        )
        self.message_log.append(msg)
        return msg

    def get_supported_protocols(self) -> dict[str, Any]:
        """Get all supported financial languages and capabilities."""
        return {
            "protocols": [p.value for p in Protocol],
            "asset_class_routing": {
                k: [p.value for p in v]
                for k, v in self.ASSET_CLASS_PROTOCOLS.items()
            },
            "lifecycle_events": self.LIFECYCLE_EVENTS,
            "total_messages_routed": len(self.message_log),
        }
