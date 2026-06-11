"""FIX Protocol Engine — Financial Information eXchange.

Implements FIX 4.4 / 5.0 SP2 message construction, parsing, session management,
multi-venue routing, risk controls, execution reports, and performance analytics.
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
    TEST_REQUEST = "1"
    RESEND_REQUEST = "2"
    REJECT = "3"
    SEQUENCE_RESET = "4"
    LOGOUT = "5"
    LOGON = "A"
    NEW_ORDER_SINGLE = "D"
    EXECUTION_REPORT = "8"
    ORDER_CANCEL_REQUEST = "F"
    ORDER_CANCEL_REPLACE = "G"
    ORDER_STATUS_REQUEST = "H"
    ORDER_CANCEL_REJECT = "9"
    MARKET_DATA_REQUEST = "V"
    MARKET_DATA_SNAPSHOT = "W"
    MARKET_DATA_INCREMENTAL = "X"
    MARKET_DATA_REQUEST_REJECT = "Y"
    SECURITY_LIST_REQUEST = "x"
    SECURITY_LIST = "y"
    QUOTE_REQUEST = "R"
    QUOTE = "S"
    MASS_QUOTE = "i"
    QUOTE_CANCEL = "Z"
    TRADE_CAPTURE_REPORT = "AE"
    TRADE_CAPTURE_REPORT_REQUEST = "AD"
    POSITION_REPORT = "AP"
    ALLOCATION_INSTRUCTION = "J"
    ALLOCATION_REPORT = "AS"
    CONFIRMATION = "AK"
    ORDER_MASS_STATUS_REQUEST = "AF"
    ORDER_MASS_CANCEL_REQUEST = "q"
    BUSINESS_MESSAGE_REJECT = "j"
    NEWS = "B"


class FIXOrdType(str, Enum):
    MARKET = "1"
    LIMIT = "2"
    STOP = "3"
    STOP_LIMIT = "4"
    MARKET_ON_CLOSE = "5"
    LIMIT_ON_CLOSE = "B"
    PEGGED = "P"
    ICEBERG = "I"
    TRAILING_STOP = "T"
    MIDPOINT = "M"


class FIXSide(str, Enum):
    BUY = "1"
    SELL = "2"
    BUY_MINUS = "3"
    SELL_PLUS = "4"
    SHORT_SELL = "5"
    SHORT_SELL_EXEMPT = "6"
    CROSS = "8"
    CROSS_SHORT = "9"


class FIXTimeInForce(str, Enum):
    DAY = "0"
    GTC = "1"
    OPG = "2"
    IOC = "3"
    FOK = "4"
    GTX = "5"
    GTD = "6"
    AT_CLOSE = "7"


class FIXExecType(str, Enum):
    NEW = "0"
    PARTIAL_FILL = "1"
    FILL = "2"
    DONE_FOR_DAY = "3"
    CANCELED = "4"
    REPLACED = "5"
    PENDING_CANCEL = "6"
    STOPPED = "7"
    REJECTED = "8"
    SUSPENDED = "9"
    PENDING_NEW = "A"
    CALCULATED = "B"
    EXPIRED = "C"
    TRADE = "F"
    ORDER_STATUS = "I"


class FIXOrdStatus(str, Enum):
    NEW = "0"
    PARTIALLY_FILLED = "1"
    FILLED = "2"
    DONE_FOR_DAY = "3"
    CANCELED = "4"
    REPLACED = "5"
    PENDING_CANCEL = "6"
    STOPPED = "7"
    REJECTED = "8"
    SUSPENDED = "9"
    PENDING_NEW = "A"
    CALCULATED = "B"
    EXPIRED = "C"


class VenueType(str, Enum):
    PRIMARY = "primary"
    DARK_POOL = "dark_pool"
    ECN = "ecn"
    ATS = "ats"
    EXCHANGE = "exchange"
    INTERNALIZER = "internalizer"


class RiskCheckResult(str, Enum):
    PASSED = "passed"
    BLOCKED_SIZE = "blocked_size"
    BLOCKED_NOTIONAL = "blocked_notional"
    BLOCKED_RATE = "blocked_rate"
    BLOCKED_POSITION = "blocked_position"
    BLOCKED_KILL_SWITCH = "blocked_kill_switch"


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

    def get_field(self, tag: int, default: str = "") -> str:
        return self.fields.get(tag, default)

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
    is_logged_on: bool = False
    reset_on_logon: bool = False
    encryption_method: int = 0

    def next_outgoing_seq(self) -> int:
        seq = self.outgoing_seq
        self.outgoing_seq += 1
        return seq

    def validate_incoming_seq(self, seq: int) -> bool:
        """Validate incoming sequence number."""
        if seq == self.incoming_seq:
            self.incoming_seq += 1
            return True
        return False

    def reset(self) -> None:
        """Reset session sequence numbers."""
        self.outgoing_seq = 1
        self.incoming_seq = 1


@dataclass
class ExecutionReport:
    """Execution report representation."""
    exec_id: str
    order_id: str
    cl_ord_id: str
    exec_type: FIXExecType
    ord_status: FIXOrdStatus
    symbol: str
    side: FIXSide
    leaves_qty: float = 0.0
    cum_qty: float = 0.0
    avg_px: float = 0.0
    last_qty: float = 0.0
    last_px: float = 0.0
    text: str = ""
    timestamp: str = ""

    def __post_init__(self) -> None:
        if not self.timestamp:
            self.timestamp = time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime())


@dataclass
class OrderState:
    """Internal order tracking state."""
    cl_ord_id: str
    order_id: str = ""
    symbol: str = ""
    side: FIXSide = FIXSide.BUY
    order_type: FIXOrdType = FIXOrdType.LIMIT
    quantity: float = 0.0
    price: float = 0.0
    filled_qty: float = 0.0
    avg_fill_price: float = 0.0
    status: FIXOrdStatus = FIXOrdStatus.PENDING_NEW
    venue: str = ""
    submit_time: float = 0.0
    last_update_time: float = 0.0
    fills: list[dict[str, float]] = field(default_factory=list)


@dataclass
class VenueConfig:
    """Trading venue configuration."""
    venue_id: str
    venue_type: VenueType
    target_comp_id: str
    max_order_size: float = 1_000_000.0
    max_notional: float = 50_000_000.0
    supported_order_types: list[FIXOrdType] = field(default_factory=list)
    latency_ms: float = 0.0
    fill_rate: float = 0.0
    is_active: bool = True
    priority: int = 1


@dataclass
class RiskLimits:
    """Pre-trade risk limits."""
    max_order_size: float = 100_000.0
    max_notional_per_order: float = 10_000_000.0
    max_orders_per_second: int = 100
    max_position_size: float = 5_000_000.0
    max_daily_notional: float = 500_000_000.0
    max_loss_limit: float = 1_000_000.0
    kill_switch_active: bool = False
    fat_finger_multiplier: float = 5.0


@dataclass
class PerformanceMetrics:
    """Venue/order performance analytics."""
    total_orders: int = 0
    filled_orders: int = 0
    rejected_orders: int = 0
    canceled_orders: int = 0
    partial_fills: int = 0
    avg_latency_ms: float = 0.0
    fill_rate: float = 0.0
    avg_slippage_bps: float = 0.0
    total_notional: float = 0.0
    total_fees: float = 0.0


class PreTradeRiskEngine:
    """Pre-trade risk checking engine."""

    def __init__(self, limits: RiskLimits | None = None) -> None:
        self.limits = limits or RiskLimits()
        self.daily_notional = 0.0
        self.orders_this_second = 0
        self.last_second = 0
        self.current_positions: dict[str, float] = {}
        self.daily_pnl = 0.0

    def check_order(
        self, symbol: str, side: FIXSide, quantity: float, price: float
    ) -> tuple[RiskCheckResult, str]:
        """Run all pre-trade risk checks."""
        if self.limits.kill_switch_active:
            return RiskCheckResult.BLOCKED_KILL_SWITCH, "Kill switch is active"

        # Size check
        if quantity > self.limits.max_order_size:
            return RiskCheckResult.BLOCKED_SIZE, f"Order size {quantity} exceeds limit {self.limits.max_order_size}"

        # Notional check
        notional = quantity * price
        if notional > self.limits.max_notional_per_order:
            return RiskCheckResult.BLOCKED_NOTIONAL, f"Notional {notional} exceeds limit"

        # Rate limiting
        current_second = int(time.time())
        if current_second == self.last_second:
            self.orders_this_second += 1
            if self.orders_this_second > self.limits.max_orders_per_second:
                return RiskCheckResult.BLOCKED_RATE, "Rate limit exceeded"
        else:
            self.last_second = current_second
            self.orders_this_second = 1

        # Position limit
        current_pos = self.current_positions.get(symbol, 0.0)
        if side == FIXSide.BUY:
            new_pos = current_pos + quantity * price
        else:
            new_pos = current_pos - quantity * price
        if abs(new_pos) > self.limits.max_position_size:
            return RiskCheckResult.BLOCKED_POSITION, "Position limit would be breached"

        # Daily notional
        self.daily_notional += notional

        return RiskCheckResult.PASSED, "All checks passed"

    def activate_kill_switch(self, reason: str = "") -> dict[str, Any]:
        """Activate kill switch — block all new orders."""
        self.limits.kill_switch_active = True
        return {"action": "kill_switch_activated", "reason": reason, "timestamp": time.time()}

    def deactivate_kill_switch(self) -> None:
        """Deactivate kill switch."""
        self.limits.kill_switch_active = False

    def reset_daily(self) -> None:
        """Reset daily counters."""
        self.daily_notional = 0.0
        self.daily_pnl = 0.0


class SmartOrderRouter:
    """Smart Order Routing across multiple venues."""

    def __init__(self) -> None:
        self.venues: dict[str, VenueConfig] = {}
        self.venue_metrics: dict[str, PerformanceMetrics] = {}

    def add_venue(self, config: VenueConfig) -> None:
        """Register a trading venue."""
        self.venues[config.venue_id] = config
        self.venue_metrics[config.venue_id] = PerformanceMetrics()

    def select_venue(
        self,
        symbol: str,
        side: FIXSide,
        quantity: float,
        order_type: FIXOrdType,
        urgency: float = 0.5,
    ) -> str | None:
        """Select best venue for order execution."""
        candidates = []
        for vid, config in self.venues.items():
            if not config.is_active:
                continue
            if config.supported_order_types and order_type not in config.supported_order_types:
                continue
            if quantity * 100 > config.max_order_size:  # Approximate notional check
                continue

            # Score venue
            metrics = self.venue_metrics.get(vid, PerformanceMetrics())
            fill_score = metrics.fill_rate * 40
            latency_score = max(0, 30 - config.latency_ms / 10)
            priority_score = (10 - config.priority) * 3

            # Dark pools better for large orders
            if config.venue_type == VenueType.DARK_POOL and quantity > 10000:
                fill_score += 15

            total_score = fill_score + latency_score + priority_score
            candidates.append((vid, total_score))

        if not candidates:
            return None
        candidates.sort(key=lambda x: x[1], reverse=True)
        return candidates[0][0]

    def split_order(
        self, quantity: float, max_per_venue: float = 50000.0
    ) -> list[tuple[str, float]]:
        """Split large order across venues."""
        active_venues = [v for v in self.venues.values() if v.is_active]
        if not active_venues:
            return []

        splits = []
        remaining = quantity
        for venue in sorted(active_venues, key=lambda v: v.priority):
            if remaining <= 0:
                break
            chunk = min(remaining, max_per_venue, venue.max_order_size)
            splits.append((venue.venue_id, chunk))
            remaining -= chunk

        return splits

    def record_execution(
        self, venue_id: str, filled: bool, latency_ms: float, slippage_bps: float = 0.0
    ) -> None:
        """Record execution result for venue analytics."""
        metrics = self.venue_metrics.get(venue_id)
        if not metrics:
            return
        metrics.total_orders += 1
        if filled:
            metrics.filled_orders += 1
        # Update running averages
        n = metrics.total_orders
        metrics.avg_latency_ms = (metrics.avg_latency_ms * (n - 1) + latency_ms) / n
        metrics.fill_rate = metrics.filled_orders / n
        metrics.avg_slippage_bps = (metrics.avg_slippage_bps * (n - 1) + slippage_bps) / n

    def get_venue_analytics(self) -> dict[str, dict[str, Any]]:
        """Get performance analytics for all venues."""
        return {
            vid: {
                "total_orders": m.total_orders,
                "fill_rate": m.fill_rate,
                "avg_latency_ms": m.avg_latency_ms,
                "avg_slippage_bps": m.avg_slippage_bps,
                "rejected": m.rejected_orders,
            }
            for vid, m in self.venue_metrics.items()
        }


class DropCopyEngine:
    """Drop copy / trade capture reporting."""

    def __init__(self) -> None:
        self.trade_captures: list[dict[str, Any]] = []
        self.position_snapshot: dict[str, float] = {}

    def record_trade(
        self,
        symbol: str,
        side: FIXSide,
        quantity: float,
        price: float,
        venue: str,
        order_id: str,
    ) -> dict[str, Any]:
        """Record a trade capture report."""
        trade = {
            "trade_id": f"TC-{int(time.time() * 1000)}",
            "symbol": symbol,
            "side": side.value,
            "quantity": quantity,
            "price": price,
            "notional": quantity * price,
            "venue": venue,
            "order_id": order_id,
            "timestamp": time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()),
        }
        self.trade_captures.append(trade)

        # Update position
        pos_change = quantity if side == FIXSide.BUY else -quantity
        self.position_snapshot[symbol] = self.position_snapshot.get(symbol, 0) + pos_change

        return trade

    def get_position_report(self) -> dict[str, float]:
        """Get current position snapshot."""
        return dict(self.position_snapshot)

    def get_trade_history(self, symbol: str = "", limit: int = 100) -> list[dict[str, Any]]:
        """Get trade capture history."""
        trades = self.trade_captures
        if symbol:
            trades = [t for t in trades if t["symbol"] == symbol]
        return trades[-limit:]

    def generate_trade_capture_message(self, trade: dict[str, Any]) -> FIXMessage:
        """Generate FIX Trade Capture Report (AE) message."""
        msg = FIXMessage(msg_type=FIXMsgType.TRADE_CAPTURE_REPORT)
        msg.set_field(571, trade["trade_id"])  # TradeReportID
        msg.set_field(55, trade["symbol"])
        msg.set_field(54, trade["side"])
        msg.set_field(32, str(trade["quantity"]))  # LastQty
        msg.set_field(31, f"{trade['price']:.8f}")  # LastPx
        msg.set_field(60, trade["timestamp"])
        return msg


class AllocationEngine:
    """Post-trade allocation and confirmation."""

    def __init__(self) -> None:
        self.allocations: list[dict[str, Any]] = []

    def create_allocation(
        self,
        order_id: str,
        symbol: str,
        total_qty: float,
        avg_price: float,
        accounts: list[dict[str, float]],
    ) -> FIXMessage:
        """Create Allocation Instruction (J) message."""
        alloc_id = f"ALLOC-{int(time.time() * 1000)}"
        msg = FIXMessage(msg_type=FIXMsgType.ALLOCATION_INSTRUCTION)
        msg.set_field(70, alloc_id)  # AllocID
        msg.set_field(55, symbol)
        msg.set_field(53, str(total_qty))  # Quantity
        msg.set_field(6, f"{avg_price:.8f}")  # AvgPx

        allocation = {
            "alloc_id": alloc_id,
            "order_id": order_id,
            "symbol": symbol,
            "total_qty": total_qty,
            "avg_price": avg_price,
            "accounts": accounts,
            "timestamp": time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()),
        }
        self.allocations.append(allocation)
        return msg

    def create_confirmation(self, alloc_id: str, account: str, qty: float, price: float) -> FIXMessage:
        """Create Confirmation (AK) message."""
        msg = FIXMessage(msg_type=FIXMsgType.CONFIRMATION)
        msg.set_field(664, f"CONF-{int(time.time() * 1000)}")  # ConfirmID
        msg.set_field(70, alloc_id)  # AllocID
        msg.set_field(1, account)  # Account
        msg.set_field(38, str(qty))  # AllocQty
        msg.set_field(6, f"{price:.8f}")  # AvgPx
        return msg


class FIXEngine:
    """FIX Protocol Engine for multi-venue order routing."""

    def __init__(self, sender_comp_id: str = "PARRALAX-HFT") -> None:
        self.sender_comp_id = sender_comp_id
        self.sessions: dict[str, FIXSession] = {}
        self.order_id_counter = 0
        self.orders: dict[str, OrderState] = {}
        self.risk_engine = PreTradeRiskEngine()
        self.router = SmartOrderRouter()
        self.drop_copy = DropCopyEngine()
        self.allocation_engine = AllocationEngine()
        self.execution_reports: list[ExecutionReport] = []

    def create_session(self, target: str, heartbeat: int = 30) -> FIXSession:
        """Create a new FIX session."""
        session = FIXSession(
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            heartbeat_interval=heartbeat,
        )
        self.sessions[target] = session
        return session

    def logon(self, target: str, heartbeat: int = 30, reset_seq: bool = False) -> FIXMessage:
        """Create Logon (A) message to initiate session."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target, heartbeat)

        if reset_seq:
            session.reset()

        msg = FIXMessage(
            msg_type=FIXMsgType.LOGON,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(98, "0")  # EncryptMethod (None)
        msg.set_field(108, str(heartbeat))  # HeartBtInt
        if reset_seq:
            msg.set_field(141, "Y")  # ResetSeqNumFlag

        session.is_logged_on = True
        session.is_connected = True
        return msg

    def logout(self, target: str, text: str = "") -> FIXMessage:
        """Create Logout (5) message."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.LOGOUT,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        if text:
            msg.set_field(58, text)  # Text
        session.is_logged_on = False
        return msg

    def heartbeat(self, target: str, test_req_id: str = "") -> FIXMessage:
        """Create Heartbeat (0) message."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.HEARTBEAT,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        if test_req_id:
            msg.set_field(112, test_req_id)  # TestReqID
        session.last_sent = time.time()
        return msg

    def resend_request(self, target: str, begin_seq: int, end_seq: int = 0) -> FIXMessage:
        """Create Resend Request (2) for gap fill."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.RESEND_REQUEST,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(7, str(begin_seq))  # BeginSeqNo
        msg.set_field(16, str(end_seq))  # EndSeqNo (0 = infinity)
        return msg

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
        stop_price: float | None = None,
        max_floor: float | None = None,
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

        if stop_price is not None:
            msg.set_field(99, f"{stop_price:.8f}")  # StopPx

        if max_floor is not None:
            msg.set_field(111, str(max_floor))  # MaxFloor (iceberg)

        if account:
            msg.set_field(1, account)  # Account

        msg.set_field(60, time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()))  # TransactTime

        # Track order
        order = OrderState(
            cl_ord_id=cl_ord_id,
            symbol=symbol,
            side=side,
            order_type=order_type,
            quantity=quantity,
            price=price or 0.0,
            venue=target,
            submit_time=time.time(),
        )
        self.orders[cl_ord_id] = order

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

    def cancel_replace_order(
        self,
        target: str,
        orig_cl_ord_id: str,
        symbol: str,
        side: FIXSide,
        order_type: FIXOrdType,
        new_quantity: float | None = None,
        new_price: float | None = None,
    ) -> FIXMessage:
        """Create Order Cancel/Replace Request (G) — amend order."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        self.order_id_counter += 1
        cl_ord_id = f"PARRALAX-RPL-{int(time.time() * 1000)}-{self.order_id_counter}"

        msg = FIXMessage(
            msg_type=FIXMsgType.ORDER_CANCEL_REPLACE,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(11, cl_ord_id)
        msg.set_field(41, orig_cl_ord_id)
        msg.set_field(55, symbol)
        msg.set_field(54, side.value)
        msg.set_field(40, order_type.value)
        msg.set_field(60, time.strftime("%Y%m%d-%H:%M:%S.000", time.gmtime()))

        if new_quantity is not None:
            msg.set_field(38, str(new_quantity))
        if new_price is not None:
            msg.set_field(44, f"{new_price:.8f}")

        return msg

    def mass_cancel(self, target: str, symbol: str = "", side: FIXSide | None = None) -> FIXMessage:
        """Create Order Mass Cancel Request (q)."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.ORDER_MASS_CANCEL_REQUEST,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(11, f"MASS-CXL-{int(time.time() * 1000)}")
        msg.set_field(530, "7" if not symbol else "1")  # MassCancelRequestType
        if symbol:
            msg.set_field(55, symbol)
        if side:
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

    def quote_request(
        self, target: str, symbol: str, quantity: float, side: FIXSide = FIXSide.BUY
    ) -> FIXMessage:
        """Create Quote Request (R) message."""
        session = self.sessions.get(target)
        if not session:
            session = self.create_session(target)

        msg = FIXMessage(
            msg_type=FIXMsgType.QUOTE_REQUEST,
            sender_comp_id=self.sender_comp_id,
            target_comp_id=target,
            msg_seq_num=session.next_outgoing_seq(),
        )
        msg.set_field(131, f"QR-{int(time.time() * 1000)}")  # QuoteReqID
        msg.set_field(55, symbol)
        msg.set_field(38, str(quantity))
        msg.set_field(54, side.value)
        return msg

    def process_execution_report(self, msg: FIXMessage) -> ExecutionReport | None:
        """Process incoming Execution Report (8)."""
        if msg.msg_type != FIXMsgType.EXECUTION_REPORT:
            return None

        report = ExecutionReport(
            exec_id=msg.get_field(17),
            order_id=msg.get_field(37),
            cl_ord_id=msg.get_field(11),
            exec_type=FIXExecType(msg.get_field(150, "0")),
            ord_status=FIXOrdStatus(msg.get_field(39, "0")),
            symbol=msg.get_field(55),
            side=FIXSide(msg.get_field(54, "1")),
            leaves_qty=float(msg.get_field(151, "0")),
            cum_qty=float(msg.get_field(14, "0")),
            avg_px=float(msg.get_field(6, "0")),
            last_qty=float(msg.get_field(32, "0")),
            last_px=float(msg.get_field(31, "0")),
            text=msg.get_field(58),
        )

        # Update order state
        order = self.orders.get(report.cl_ord_id)
        if order:
            order.status = report.ord_status
            order.filled_qty = report.cum_qty
            order.avg_fill_price = report.avg_px
            order.last_update_time = time.time()
            if report.last_qty > 0:
                order.fills.append({"qty": report.last_qty, "price": report.last_px})

            # Record in drop copy
            if report.exec_type in (FIXExecType.FILL, FIXExecType.PARTIAL_FILL):
                self.drop_copy.record_trade(
                    symbol=report.symbol,
                    side=order.side,
                    quantity=report.last_qty,
                    price=report.last_px,
                    venue=order.venue,
                    order_id=report.order_id,
                )

        self.execution_reports.append(report)
        return report

    def get_order_status(self, cl_ord_id: str) -> dict[str, Any] | None:
        """Get current order status."""
        order = self.orders.get(cl_ord_id)
        if not order:
            return None
        return {
            "cl_ord_id": order.cl_ord_id,
            "symbol": order.symbol,
            "side": order.side.value,
            "quantity": order.quantity,
            "filled_qty": order.filled_qty,
            "avg_price": order.avg_fill_price,
            "status": order.status.value,
            "venue": order.venue,
            "n_fills": len(order.fills),
        }

    def get_performance_summary(self) -> dict[str, Any]:
        """Get overall execution performance summary."""
        total = len(self.orders)
        filled = sum(1 for o in self.orders.values() if o.status == FIXOrdStatus.FILLED)
        rejected = sum(1 for o in self.orders.values() if o.status == FIXOrdStatus.REJECTED)
        canceled = sum(1 for o in self.orders.values() if o.status == FIXOrdStatus.CANCELED)

        latencies = [
            (o.last_update_time - o.submit_time) * 1000
            for o in self.orders.values()
            if o.last_update_time > 0 and o.submit_time > 0
        ]
        avg_latency = sum(latencies) / len(latencies) if latencies else 0.0

        return {
            "total_orders": total,
            "filled": filled,
            "rejected": rejected,
            "canceled": canceled,
            "fill_rate": filled / total if total > 0 else 0.0,
            "avg_latency_ms": avg_latency,
            "positions": self.drop_copy.get_position_report(),
            "venue_analytics": self.router.get_venue_analytics(),
        }
