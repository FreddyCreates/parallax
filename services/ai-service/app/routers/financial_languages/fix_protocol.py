"""FIX Protocol Engine — Financial Information eXchange.

Implements FIX 4.4 / 5.0 SP2 message construction, parsing, and session management
for high-frequency order routing across multiple venues.
"""

from __future__ import annotations

import hashlib
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class FIXMsgType(str, Enum):
    """FIX message types."""
    HEARTBEAT = "0"
    LOGON = "A"
    LOGOUT = "5"
    NEW_ORDER_SINGLE = "D"
    EXECUTION_REPORT = "8"
    ORDER_CANCEL_REQUEST = "F"
    ORDER_CANCEL_REPLACE = "G"
    ORDER_STATUS_REQUEST = "H"
    MARKET_DATA_REQUEST = "V"
    MARKET_DATA_SNAPSHOT = "W"
    MARKET_DATA_INCREMENTAL = "X"
    SECURITY_LIST_REQUEST = "x"
    QUOTE_REQUEST = "R"
    QUOTE = "S"
    MASS_QUOTE = "i"


class FIXOrdType(str, Enum):
    MARKET = "1"
    LIMIT = "2"
    STOP = "3"
    STOP_LIMIT = "4"
    PEGGED = "P"
    ICEBERG = "I"


class FIXSide(str, Enum):
    BUY = "1"
    SELL = "2"
    SHORT_SELL = "5"
    CROSS = "8"


class FIXTimeInForce(str, Enum):
    DAY = "0"
    GTC = "1"
    IOC = "3"
    FOK = "4"
    GTD = "6"


@dataclass
class FIXMessage:
    """FIX protocol message."""
    msg_type: FIXMsgType
    fields: dict[int, str] = field(default_factory=dict)
    sender_comp_id: str = "PARRALAX"
    target_comp_id: str = ""
    msg_seq_num: int = 0
    sending_time: str = ""

    def __post_init__(self) -> None:
        if not self.sending_time:
            self.sending_time = time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime())

    def set_field(self, tag: int, value: str) -> "FIXMessage":
        self.fields[tag] = value
        return self

    def encode(self) -> str:
        """Encode to FIX tag=value format with SOH delimiter."""
        body_fields = [
            f"35={self.msg_type.value}",
            f"49={self.sender_comp_id}",
            f"56={self.target_comp_id}",
            f"34={self.msg_seq_num}",
            f"52={self.sending_time}",
        ]
        body_fields.extend(f"{tag}={value}" for tag, value in sorted(self.fields.items()))
        body = "\x01".join(body_fields) + "\x01"

        # Header: BeginString + BodyLength
        header = f"8=FIX.4.4\x019={len(body)}\x01"

        # Checksum
        raw = header + body
        checksum = sum(ord(c) for c in raw) % 256
        return f"{raw}10={checksum:03d}\x01"

    @classmethod
    def decode(cls, raw: str) -> "FIXMessage":
        """Parse FIX message from raw string."""
        fields_raw = raw.split("\x01")
        parsed: dict[int, str] = {}
        for f in fields_raw:
            if "=" in f:
                tag_str, value = f.split("=", 1)
                parsed[int(tag_str)] = value

        msg_type = FIXMsgType(parsed.get(35, "0"))
        msg = cls(
            msg_type=msg_type,
            sender_comp_id=parsed.get(49, ""),
            target_comp_id=parsed.get(56, ""),
            msg_seq_num=int(parsed.get(34, "0")),
            sending_time=parsed.get(52, ""),
        )
        # Add remaining fields
        skip_tags = {8, 9, 10, 35, 49, 56, 34, 52}
        for tag, value in parsed.items():
            if tag not in skip_tags:
                msg.fields[tag] = value
        return msg


@dataclass
class FIXSession:
    """FIX session state management."""
    sender_comp_id: str
    target_comp_id: str
    outgoing_seq: int = 1
    incoming_seq: int = 1
    is_connected: bool = False
    heartbeat_interval: int = 30
    last_sent: float = 0.0
    last_received: float = 0.0

    def next_outgoing_seq(self) -> int:
        seq = self.outgoing_seq
        self.outgoing_seq += 1
        return seq


class FIXEngine:
    """FIX Protocol Engine for multi-venue order routing."""

    def __init__(self, sender_comp_id: str = "PARRALAX-HFT") -> None:
        self.sender_comp_id = sender_comp_id
        self.sessions: dict[str, FIXSession] = {}
        self.order_id_counter = 0

    def create_session(self, target: str, heartbeat: int = 30) -> FIXSession:
        """Create a new FIX session."""
        session = FIXSession(
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            heartbeat_interval=heartbeat,
        )
        self.sessions[target] = session
        return session

    def new_order_single(
        self,
        target: str,
        symbol: str,
        side: FIXSide,
        order_type: FIXOrdType,
        quantity: float,
        price: float | None = None,
        time_in_force: FIXTimeInForce = FIXTimeInForce.IOC,
        account: str = "",
    ) -> FIXMessage:
        """Create New Order Single (D) message."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        self.order_id_counter += 1
        cl_ord_id = f"PARRALAX-{int(time.time() * 1000)}-{self.order_id_counter}"

        msg = FIXMessage(
            msg_type=FIXMsgType.NEW_ORDER_SINGLE,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(11, cl_ord_id)        # ClOrdID
        msg.set_field(55, symbol)           # Symbol
        msg.set_field(54, side.value)       # Side
        msg.set_field(40, order_type.value) # OrdType
        msg.set_field(38, str(quantity))    # OrderQty
        msg.set_field(59, time_in_force.value)  # TimeInForce

        if price is not None:
            msg.set_field(44, f"{price:.8f}")  # Price

        if account:
            msg.set_field(1, account)  # Account

        msg.set_field(60, time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()))  # TransactTime

        return msg

    def cancel_order(self, target: str, orig_cl_ord_id: str, symbol: str, side: FIXSide) -> FIXMessage:
        """Create Order Cancel Request (F)."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        self.order_id_counter += 1
        cl_ord_id = f"PARRALAX-CXL-{int(time.time() * 1000)}-{self.order_id_counter}"

        msg = FIXMessage(
            msg_type=FIXMsgType.ORDER_CANCEL_REQUEST,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(11, cl_ord_id)
        msg.set_field(41, orig_cl_ord_id)  # OrigClOrdID
        msg.set_field(55, symbol)
        msg.set_field(54, side.value)
        msg.set_field(60, time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()))

        return msg

    def market_data_request(self, target: str, symbols: list[str], depth: int = 10) -> FIXMessage:
        """Create Market Data Request (V)."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.MARKET_DATA_REQUEST,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        md_req_id = hashlib.md5(f"{symbols}{time.time()}".encode()).hexdigest()[:12]
        msg.set_field(262, md_req_id)     # MDReqID
        msg.set_field(263, "1")           # SubscriptionRequestType (Snapshot + Updates)
        msg.set_field(264, str(depth))    # MarketDepth
        msg.set_field(267, "2")           # NoMDEntryTypes
        msg.set_field(269, "0")           # MDEntryType (Bid)
        msg.set_field(146, str(len(symbols)))  # NoRelatedSym

        for i, sym in enumerate(symbols):
            msg.set_field(55 + i * 1000, sym)  # Simplified — real impl uses repeating groups

        return msg
