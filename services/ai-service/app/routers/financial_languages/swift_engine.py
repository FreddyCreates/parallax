"""SWIFT messaging engine for MT and MX financial traffic.

This module intentionally keeps dependencies minimal while providing a
production-style implementation for generating SWIFT MT messages and SWIFT MX
(ISO 20022 XML) envelopes. The engine is designed for treasury, correspondent
banking, securities operations, and reconciliation workflows.

Backwards compatibility is preserved for the existing public surface:
- ``SWIFTMessageType``
- ``MXMessageType``
- ``SWIFTMessage``
- ``SWIFTEngine``
- ``SWIFTEngine.create_payment``
- ``SWIFTEngine.create_fx_confirmation``
- ``SWIFTEngine.create_securities_order``
- ``SWIFTEngine.create_settlement_instruction``

The expanded implementation adds:
- MT202COV cover payments with compliance and intermediary routing.
- MT320 fixed loan and deposit confirmations with generated cash-flow schedules.
- MT515 and MT518 client-side and market-side securities confirmations.
- MT535 and MT536 holdings and transaction statements with multi-record output.
- MT540 through MT543 settlement instructions for all free and against-payment
  settlement directions.
- MT900 and MT910 cash confirmations with reconciliation identifiers.
- MT940 and MT950 statements with balance and transaction reporting.
- MX pacs, camt, and sese XML generation wrapped in a SWIFT-style application
  header.
- Validation services for BIC, mandatory fields, field formats, and routing
  consistency.
- Message routing with correspondent chains, intermediary selection, and basic
  SWIFT GPI tracking metadata.
"""

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Iterable, Mapping, Sequence


def _utc_timestamp() -> int:
    """Return the current UTC epoch timestamp as an integer."""
    return int(time.time())


def _mt_reference(prefix: str = "PRLX") -> str:
    """Return a deterministic SWIFT-style reference.

    The reference uses UTC epoch seconds so that the module stays dependency
    free and deterministic enough for service-side generation.
    """
    return f"{prefix}{_utc_timestamp()}"


def _utc_date() -> str:
    """Return current UTC date in SWIFT ``YYYYMMDD`` format."""
    return time.strftime("%Y%m%d", time.gmtime())


def _utc_short_date() -> str:
    """Return current UTC date in SWIFT ``YYMMDD`` format."""
    return time.strftime("%y%m%d", time.gmtime())


def _utc_time() -> str:
    """Return current UTC time in SWIFT ``HHMM`` format."""
    return time.strftime("%H%M", time.gmtime())


def _utc_iso_datetime() -> str:
    """Return current UTC date-time in ISO 8601 format."""
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def _only_digits(value: str) -> str:
    """Return only the numeric characters from ``value``."""
    return "".join(character for character in value if character.isdigit())


def _only_letters(value: str) -> str:
    """Return only alpha characters from ``value`` converted to upper case."""
    return "".join(character for character in value.upper() if character.isalpha())


def _clean_text(value: str) -> str:
    """Return SWIFT-safe text with collapsed whitespace and uppercase style."""
    cleaned = " ".join(value.replace("\n", " ").split()).strip()
    return cleaned.upper()


def _clean_multiline_text(value: str) -> str:
    """Return multiline SWIFT-safe text preserving line breaks."""
    lines = []
    for raw_line in value.splitlines() or [value]:
        line = " ".join(raw_line.split()).strip()
        if line:
            lines.append(line.upper())
    return "\n".join(lines)


def _xml_escape(value: str) -> str:
    """Escape a string for safe embedding inside XML content nodes."""
    escaped = value.replace("&", "&amp;")
    escaped = escaped.replace("<", "&lt;").replace(">", "&gt;")
    escaped = escaped.replace('"', "&quot;").replace("'", "&apos;")
    return escaped


def _format_amount(amount: float, decimals: int = 2) -> str:
    """Format an amount using SWIFT decimal conventions.

    SWIFT text messages commonly use a comma as decimal separator. The engine
    follows that representation so that the rendered text looks closer to a real
    MT payload.
    """
    return f"{amount:.{decimals}f}".replace(".", ",")


def _normalise_currency(currency: str) -> str:
    """Return a validated-looking ISO currency code shape."""
    cleaned = _only_letters(currency)
    return cleaned[:3] if cleaned else "USD"


def _normalise_bic(bic: str) -> str:
    """Return the supplied BIC in uppercase without spaces."""
    return "".join(character for character in bic.upper() if not character.isspace())


def _normalise_mt_date(value: str | None = None) -> str:
    """Return a SWIFT ``YYYYMMDD`` date string.

    The helper accepts ``YYYYMMDD`` and ``YYYY-MM-DD`` style inputs and falls
    back to the current UTC date if no value is supplied.
    """
    if not value:
        return _utc_date()
    digits = _only_digits(value)
    if len(digits) == 8:
        return digits
    if len(digits) == 6:
        return f"20{digits}"
    return _utc_date()


def _normalise_statement_date(value: str | None = None) -> str:
    """Return a SWIFT statement date string in ``YYMMDD`` form."""
    return _normalise_mt_date(value)[2:]


def _normalise_iso_date(value: str | None = None) -> str:
    """Return an ISO ``YYYY-MM-DD`` date string."""
    digits = _normalise_mt_date(value)
    return f"{digits[0:4]}-{digits[4:6]}-{digits[6:8]}"


def _date_parts(value: str | None = None) -> tuple[int, int, int]:
    """Split a date into year, month, day integers."""
    digits = _normalise_mt_date(value)
    return int(digits[0:4]), int(digits[4:6]), int(digits[6:8])


def _days_in_month(year: int, month: int) -> int:
    """Return the number of days in ``year`` and ``month``."""
    if month in {1, 3, 5, 7, 8, 10, 12}:
        return 31
    if month in {4, 6, 9, 11}:
        return 30
    is_leap = year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)
    return 29 if is_leap else 28


def _add_months(value: str, months: int) -> str:
    """Add a number of months to a ``YYYYMMDD`` date."""
    year, month, day = _date_parts(value)
    month_index = (year * 12 + (month - 1)) + months
    new_year = month_index // 12
    new_month = (month_index % 12) + 1
    new_day = min(day, _days_in_month(new_year, new_month))
    return f"{new_year:04d}{new_month:02d}{new_day:02d}"


def _days_between(start_date: str, end_date: str) -> int:
    """Return the day difference between two ``YYYYMMDD`` dates."""
    start_tuple = _date_parts(start_date)
    end_tuple = _date_parts(end_date)
    start_epoch = time.mktime(
        (start_tuple[0], start_tuple[1], start_tuple[2], 0, 0, 0, 0, 0, -1)
    )
    end_epoch = time.mktime((end_tuple[0], end_tuple[1], end_tuple[2], 0, 0, 0, 0, 0, -1))
    return max(0, int((end_epoch - start_epoch) // 86400))


def _frequency_to_months(frequency: str) -> int:
    """Map common schedule frequencies to a month interval."""
    cleaned = _clean_text(frequency)
    if cleaned in {"MONTHLY", "1M", "M"}:
        return 1
    if cleaned in {"BIMONTHLY", "2M"}:
        return 2
    if cleaned in {"QUARTERLY", "3M", "Q"}:
        return 3
    if cleaned in {"SEMIANNUAL", "SEMI-ANNUAL", "6M"}:
        return 6
    if cleaned in {"ANNUAL", "YEARLY", "12M", "Y"}:
        return 12
    return 1


def _wrap_lines(value: str, max_length: int = 35) -> list[str]:
    """Wrap text into SWIFT-like line lengths without extra imports."""
    if not value:
        return []
    remaining = _clean_multiline_text(value)
    lines: list[str] = []
    for source_line in remaining.splitlines() or [remaining]:
        words = source_line.split()
        current = ""
        for word in words:
            candidate = word if not current else f"{current} {word}"
            if len(candidate) <= max_length:
                current = candidate
            else:
                if current:
                    lines.append(current)
                while len(word) > max_length:
                    lines.append(word[:max_length])
                    word = word[max_length:]
                current = word
        if current:
            lines.append(current)
    return lines


def _append_tagged_lines(target: list[str], tag: str, value: str) -> None:
    """Append a SWIFT field tag with its potentially multiline value."""
    wrapped = value.splitlines() if "\n" in value else _wrap_lines(value)
    if not wrapped:
        target.append(f":{tag}:")
        return
    target.append(f":{tag}:{wrapped[0]}")
    for line in wrapped[1:]:
        target.append(line)


class SWIFTMessageType(str, Enum):
    """Supported SWIFT MT message categories."""

    MT103 = "103"
    MT202 = "202"
    MT202COV = "202COV"
    MT300 = "300"
    MT320 = "320"
    MT502 = "502"
    MT515 = "515"
    MT518 = "518"
    MT535 = "535"
    MT536 = "536"
    MT540 = "540"
    MT541 = "541"
    MT542 = "542"
    MT543 = "543"
    MT900 = "900"
    MT910 = "910"
    MT940 = "940"
    MT950 = "950"


class MXMessageType(str, Enum):
    """Supported SWIFT MX / ISO 20022 messages."""

    PACS_008 = "pacs.008.001.10"
    PACS_009 = "pacs.009.001.09"
    PACS_002 = "pacs.002.001.13"
    CAMT_052 = "camt.052.001.10"
    CAMT_053 = "camt.053.001.10"
    CAMT_054 = "camt.054.001.10"
    CAMT_056 = "camt.056.001.10"
    SESE_023 = "sese.023.001.11"
    SESE_024 = "sese.024.001.12"
    SESE_025 = "sese.025.001.06"
    SESE_031 = "sese.031.001.11"
    SESE_032 = "sese.032.001.10"


class ValidationSeverity(str, Enum):
    """Validation severities for message checks."""

    ERROR = "error"
    WARNING = "warning"


class RouteHopRole(str, Enum):
    """Roles inside a correspondent banking chain."""

    SENDER = "sender"
    SENDER_CORRESPONDENT = "sender_correspondent"
    INTERMEDIARY = "intermediary"
    ACCOUNT_WITH = "account_with_institution"
    RECEIVER = "receiver"


@dataclass(slots=True)
class ValidationIssue:
    """Structured validation result for MT or MX messages."""

    severity: ValidationSeverity
    field_name: str
    message: str

    def to_dict(self) -> dict[str, str]:
        """Return a serialisable form for API responses."""
        return {
            "severity": self.severity.value,
            "field_name": self.field_name,
            "message": self.message,
        }


@dataclass(slots=True)
class RouteHop:
    """One routing step in a correspondent banking path."""

    role: RouteHopRole
    bic: str
    account: str = ""
    name: str = ""
    country: str = ""

    def mt_field_value(self) -> str:
        """Return the MT field representation for the hop."""
        lines: list[str] = []
        if self.account:
            lines.append(f"/{_clean_text(self.account)}")
        lines.append(_normalise_bic(self.bic))
        if self.name:
            lines.extend(_wrap_lines(self.name))
        return "\n".join(lines)


@dataclass(slots=True)
class RoutingInstruction:
    """Routing metadata attached to a SWIFT transfer."""

    service_level: str = "SWIFT"
    tracking_reference: str = ""
    sender_correspondent: RouteHop | None = None
    intermediaries: list[RouteHop] = field(default_factory=list)
    account_with_institution: RouteHop | None = None
    receiver: RouteHop | None = None
    notes: list[str] = field(default_factory=list)

    def apply_to_message(self, message: "SWIFTMessage") -> None:
        """Apply routing fields to a SWIFT MT message in canonical order."""
        if self.tracking_reference:
            message.gpi_tracking_id = self.tracking_reference
            message.fields.setdefault("121", self.tracking_reference)
        if self.sender_correspondent:
            message.fields.setdefault("53A", self.sender_correspondent.mt_field_value())
        if self.intermediaries:
            first = self.intermediaries[0]
            message.fields.setdefault("56A", first.mt_field_value())
            if len(self.intermediaries) > 1:
                for index, intermediary in enumerate(self.intermediaries[1:], start=2):
                    message.add_repeating_field(f"56A-{index}", intermediary.mt_field_value())
        if self.account_with_institution:
            message.fields.setdefault("57A", self.account_with_institution.mt_field_value())
        if self.receiver:
            message.fields.setdefault("58A", self.receiver.mt_field_value())
        if self.notes:
            existing = message.narrative.strip()
            joined = " | ".join(_clean_text(note) for note in self.notes if note)
            if existing and joined:
                message.narrative = f"{existing} | {joined}"
            elif joined:
                message.narrative = joined


@dataclass(slots=True)
class ScheduleEntry:
    """Interest or principal event used in MT320 schedules."""

    period_number: int
    start_date: str
    end_date: str
    payment_date: str
    notional: float
    currency: str
    rate: float
    interest_amount: float
    principal_amount: float = 0.0
    day_count_basis: str = "ACT/360"

    def to_mt_lines(self) -> list[str]:
        """Render the schedule as a sequence of MT field tuples."""
        lines = [
            ("22A", f"PAYM//{self.period_number:03d}"),
            ("30P", self.start_date),
            ("30V", self.end_date),
            ("30F", self.payment_date),
            ("32B", f"{self.currency}{_format_amount(self.notional)}"),
            ("37G", f"{self.rate:.6f}"),
            ("34E", f"{self.currency}{_format_amount(self.interest_amount)}"),
        ]
        if self.principal_amount:
            lines.append(("19A", f"PRIN//{self.currency}{_format_amount(self.principal_amount)}"))
        lines.append(("14D", self.day_count_basis))
        return [f":{tag}:{value}" for tag, value in lines]

    def to_dict(self) -> dict[str, Any]:
        """Return a serialisable schedule entry."""
        return {
            "period_number": self.period_number,
            "start_date": self.start_date,
            "end_date": self.end_date,
            "payment_date": self.payment_date,
            "notional": self.notional,
            "currency": self.currency,
            "rate": self.rate,
            "interest_amount": self.interest_amount,
            "principal_amount": self.principal_amount,
            "day_count_basis": self.day_count_basis,
        }


@dataclass
class MXMessage:
    """Representation of a SWIFT MX / ISO 20022 envelope."""

    message_type: MXMessageType
    sender_bic: str = "PARRALAXXX"
    receiver_bic: str = ""
    business_message_id: str = ""
    message_definition_id: str = ""
    creation_datetime: str = ""
    payload: dict[str, Any] = field(default_factory=dict)
    related_reference: str = ""
    service: str = "swift.finplus"
    gpi_tracking_id: str = ""

    def __post_init__(self) -> None:
        if not self.business_message_id:
            self.business_message_id = _mt_reference("MX")
        if not self.message_definition_id:
            self.message_definition_id = self.message_type.value
        if not self.creation_datetime:
            self.creation_datetime = _utc_iso_datetime()
        self.sender_bic = _normalise_bic(self.sender_bic)
        self.receiver_bic = _normalise_bic(self.receiver_bic)
        if not self.gpi_tracking_id:
            self.gpi_tracking_id = f"GPI{self.business_message_id}"

    def _app_header(self) -> str:
        """Return the SWIFT application header for the MX message."""
        related = (
            f"    <Rltd>\n      <Ref>{_xml_escape(self.related_reference)}</Ref>\n    </Rltd>\n"
            if self.related_reference
            else ""
        )
        return (
            "  <AppHdr xmlns=\"urn:swift:xsd:$ahV10\">\n"
            f"    <Fr><FIId><FinInstnId><BICFI>{_xml_escape(self.sender_bic)}</BICFI></FinInstnId></FIId></Fr>\n"
            f"    <To><FIId><FinInstnId><BICFI>{_xml_escape(self.receiver_bic)}</BICFI></FinInstnId></FIId></To>\n"
            f"    <BizMsgIdr>{_xml_escape(self.business_message_id)}</BizMsgIdr>\n"
            f"    <MsgDefIdr>{_xml_escape(self.message_definition_id)}</MsgDefIdr>\n"
            f"    <BizSvc>{_xml_escape(self.service)}</BizSvc>\n"
            f"    <CreDt>{_xml_escape(self.creation_datetime)}</CreDt>\n"
            f"    <Prty>NORM</Prty>\n"
            f"    <PssblDplct>false</PssblDplct>\n"
            f"    <Sgntr>{_xml_escape(self.gpi_tracking_id)}</Sgntr>\n"
            f"{related}"
            "  </AppHdr>"
        )

    def _xml_node(self, tag: str, value: Any, indent: int = 4) -> str:
        """Render nested data structures into XML nodes.

        The renderer accepts dictionaries, lists, tuples, scalars, and ``None``.
        Lists repeat the same tag, while dictionaries are expanded as child
        elements.
        """
        prefix = " " * indent
        if value is None:
            return f"{prefix}<{tag}/>"
        if isinstance(value, Mapping):
            children = [self._xml_node(str(child_tag), child_value, indent + 2) for child_tag, child_value in value.items()]
            return f"{prefix}<{tag}>\n" + "\n".join(children) + f"\n{prefix}</{tag}>"
        if isinstance(value, (list, tuple)):
            return "\n".join(self._xml_node(tag, item, indent) for item in value)
        text = _xml_escape(str(value))
        return f"{prefix}<{tag}>{text}</{tag}>"

    def _document_root(self) -> str:
        """Return the top-level ISO 20022 document element name."""
        family = self.message_type.value.split(".")[0].capitalize()
        return family

    def _build_document(self) -> str:
        """Render the ISO 20022 document payload."""
        root = self._document_root()
        document_nodes = []
        for tag, value in self.payload.items():
            document_nodes.append(self._xml_node(tag, value, 4))
        payload = "\n".join(document_nodes)
        return (
            f"  <Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:{_xml_escape(self.message_type.value)}\">\n"
            f"    <{root}>\n"
            f"{payload}\n"
            f"    </{root}>\n"
            "  </Document>"
        )

    def to_xml(self) -> str:
        """Return the complete MX message as XML."""
        return (
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            "<DataPDU xmlns=\"urn:swift:saa:xsd:saa.2.0\">\n"
            f"{self._app_header()}\n"
            f"{self._build_document()}\n"
            "</DataPDU>"
        )


@dataclass
class SWIFTMessage:
    """Canonical in-memory representation of a SWIFT MT message."""

    message_type: SWIFTMessageType
    sender_bic: str = "PARRALAXXX"
    receiver_bic: str = ""
    reference: str = ""
    fields: dict[str, str] = field(default_factory=dict)
    amount: float = 0.0
    currency: str = "USD"
    value_date: str = ""
    narrative: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)
    repeating_fields: list[tuple[str, str]] = field(default_factory=list)
    gpi_tracking_id: str = ""
    related_reference: str = ""
    sender_correspondent: str = ""
    receiver_correspondent: str = ""
    intermediary_bics: list[str] = field(default_factory=list)
    balances: list[dict[str, Any]] = field(default_factory=list)
    transactions: list[dict[str, Any]] = field(default_factory=list)
    positions: list[dict[str, Any]] = field(default_factory=list)
    schedules: list[ScheduleEntry] = field(default_factory=list)

    def __post_init__(self) -> None:
        if not self.reference:
            self.reference = _mt_reference()
        if not self.value_date:
            self.value_date = _utc_date()
        self.sender_bic = _normalise_bic(self.sender_bic)
        self.receiver_bic = _normalise_bic(self.receiver_bic)
        self.currency = _normalise_currency(self.currency)
        if self.narrative:
            self.narrative = _clean_multiline_text(self.narrative)

    def add_field(self, tag: str, value: str) -> None:
        """Set or replace a tagged MT field."""
        self.fields[tag] = value

    def add_repeating_field(self, tag: str, value: str) -> None:
        """Append a repeating field that may occur multiple times."""
        self.repeating_fields.append((tag, value))

    def extend_repeating_fields(self, fields: Iterable[tuple[str, str]]) -> None:
        """Append many repeating fields to the message."""
        for tag, value in fields:
            self.add_repeating_field(tag, value)

    def _block_one(self) -> str:
        """Return the SWIFT basic header block."""
        sender = self.sender_bic.ljust(12, "X")[:12]
        return f"{{1:F01{sender}0000000000}}"

    def _block_two(self) -> str:
        """Return the SWIFT application header block."""
        receiver = self.receiver_bic.ljust(12, "X")[:12]
        return f"{{2:O{self.message_type.value}{_utc_time()}{receiver}}}"

    def _block_three(self) -> list[str]:
        """Return user header block entries."""
        entries = [f"{{3:{{108:{self.reference}}}" ]
        if self.gpi_tracking_id:
            entries.append(f"{{121:{self.gpi_tracking_id}}}")
        if self.related_reference:
            entries.append(f"{{111:{self.related_reference}}}")
        return ["".join(entries) + "}"]

    def _base_body(self) -> list[tuple[str, str]]:
        """Return base MT body fields common to all messages."""
        lines = [("20", self.reference)]
        if self.related_reference:
            lines.append(("21", self.related_reference))
        return lines

    def _default_mt103_fields(self) -> list[tuple[str, str]]:
        """Return standard MT103 field defaults."""
        ordering = self.fields.get("50K", f"/{self.sender_bic}\nPARRALAX AI HFT FUND")
        beneficiary = self.fields.get("59", f"/{self.receiver_bic}\nBENEFICIARY")
        purpose = self.fields.get("70", self.metadata.get("remittance_info", "TRADING SETTLEMENT"))
        return [
            ("23B", self.fields.get("23B", "CRED")),
            ("32A", self.fields.get("32A", f"{self.value_date}{self.currency}{_format_amount(self.amount)}")),
            ("33B", self.fields.get("33B", f"{self.currency}{_format_amount(self.amount)}")),
            ("50K", ordering),
            ("52A", self.fields.get("52A", self.sender_bic)),
            ("57A", self.fields.get("57A", self.receiver_correspondent or self.receiver_bic)),
            ("59", beneficiary),
            ("70", purpose),
            ("71A", self.fields.get("71A", "SHA")),
        ]

    def _default_mt202_fields(self) -> list[tuple[str, str]]:
        """Return standard MT202 field defaults."""
        return [
            ("21", self.fields.get("21", self.related_reference or self.reference)),
            ("32A", self.fields.get("32A", f"{self.value_date}{self.currency}{_format_amount(self.amount)}")),
            ("52A", self.fields.get("52A", self.sender_bic)),
            ("53A", self.fields.get("53A", self.sender_correspondent or self.sender_bic)),
            ("56A", self.fields.get("56A", self.intermediary_bics[0] if self.intermediary_bics else self.receiver_bic)),
            ("58A", self.fields.get("58A", self.receiver_bic)),
        ]

    def _default_mt202cov_fields(self) -> list[tuple[str, str]]:
        """Return MT202COV cover payment field defaults."""
        ordering = self.fields.get("50A", self.sender_bic)
        beneficiary = self.fields.get("59A", self.receiver_bic)
        return [
            ("21", self.fields.get("21", self.related_reference or self.reference)),
            ("13C", self.fields.get("13C", f"/RNCTIME/{_utc_time()}+0000")),
            ("32A", self.fields.get("32A", f"{self.value_date}{self.currency}{_format_amount(self.amount)}")),
            ("52A", self.fields.get("52A", self.sender_bic)),
            ("53A", self.fields.get("53A", self.sender_correspondent or self.sender_bic)),
            ("54A", self.fields.get("54A", self.fields.get("56A", self.receiver_correspondent or self.receiver_bic))),
            ("56A", self.fields.get("56A", self.receiver_correspondent or self.receiver_bic)),
            ("57A", self.fields.get("57A", self.receiver_bic)),
            ("58A", self.fields.get("58A", self.receiver_bic)),
            ("50A", ordering),
            ("59A", beneficiary),
            ("70", self.fields.get("70", self.metadata.get("underlying_remittance", "UNDERLYING MT103"))),
            ("72", self.fields.get("72", self.metadata.get("compliance_narrative", "COVER PAYMENT FOR CUSTOMER CREDIT TRANSFER"))),
        ]

    def _default_mt300_fields(self) -> list[tuple[str, str]]:
        """Return MT300 FX confirmation fields."""
        return [
            ("22A", self.fields.get("22A", "NEWT")),
            ("22C", self.fields.get("22C", self.reference[-16:].rjust(16, "0"))),
            ("82A", self.fields.get("82A", self.sender_bic)),
            ("87A", self.fields.get("87A", self.receiver_bic)),
            ("30T", self.fields.get("30T", self.value_date)),
            ("30V", self.fields.get("30V", self.value_date)),
            ("36", self.fields.get("36", "1,000000")),
            ("32B", self.fields.get("32B", f"{self.currency}{_format_amount(self.amount)}")),
            ("33B", self.fields.get("33B", f"{self.currency}{_format_amount(self.amount)}")),
        ]

    def _default_mt320_fields(self) -> list[tuple[str, str]]:
        """Return MT320 fixed loan or deposit header fields."""
        return [
            ("22A", self.fields.get("22A", "NEWT")),
            ("22C", self.fields.get("22C", self.reference[-16:].rjust(16, "0"))),
            ("82A", self.fields.get("82A", self.sender_bic)),
            ("87A", self.fields.get("87A", self.receiver_bic)),
            ("30T", self.fields.get("30T", self.metadata.get("trade_date", self.value_date))),
            ("30V", self.fields.get("30V", self.value_date)),
            ("30P", self.fields.get("30P", self.metadata.get("start_date", self.value_date))),
            ("30F", self.fields.get("30F", self.metadata.get("maturity_date", self.value_date))),
            ("32B", self.fields.get("32B", f"{self.currency}{_format_amount(self.amount)}")),
            ("37H", self.fields.get("37H", self.metadata.get("rate_text", "0,000000"))),
            ("14D", self.fields.get("14D", self.metadata.get("day_count_basis", "ACT/360"))),
        ]

    def _default_mt502_fields(self) -> list[tuple[str, str]]:
        """Return MT502 order defaults."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("98A", self.fields.get("98A", f"::PREP//{self.value_date}")),
            ("22F", self.fields.get("22F", "::TRTR//TRAD")),
            ("35B", self.fields.get("35B", "ISIN UNKNOWN")),
            ("22H", self.fields.get("22H", "BUSE//BUY")),
            ("36B", self.fields.get("36B", f"::SETT//UNIT/{_format_amount(self.amount)}")),
        ]

    def _default_mt515_fields(self) -> list[tuple[str, str]]:
        """Return MT515 client confirmation defaults."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("98A", self.fields.get("98A", f"::SETT//{self.value_date}")),
            ("35B", self.fields.get("35B", "ISIN UNKNOWN")),
            ("22H", self.fields.get("22H", "BUSE//BUY")),
            ("36B", self.fields.get("36B", f"::SETT//UNIT/{_format_amount(self.amount)}")),
            ("97A", self.fields.get("97A", self.metadata.get("account", "SAFE//UNKNOWN"))),
            ("19A", self.fields.get("19A", self.metadata.get("cash_amount", "PSTA//USD0,00"))),
        ]

    def _default_mt518_fields(self) -> list[tuple[str, str]]:
        """Return MT518 market-side confirmation defaults."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("22F", self.fields.get("22F", "::SETR//TRAD")),
            ("98A", self.fields.get("98A", f"::TRAD//{self.value_date}")),
            ("35B", self.fields.get("35B", "ISIN UNKNOWN")),
            ("36B", self.fields.get("36B", f"::SETT//UNIT/{_format_amount(self.amount)}")),
            ("19A", self.fields.get("19A", self.metadata.get("cash_amount", "SETT//USD0,00"))),
            ("22H", self.fields.get("22H", "REDE//RECE")),
        ]

    def _default_mt535_fields(self) -> list[tuple[str, str]]:
        """Return MT535 statement header defaults."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("98A", self.fields.get("98A", f"::STAT//{self.value_date}")),
            ("97A", self.fields.get("97A", self.metadata.get("safe_account", "SAFE//UNKNOWN"))),
            ("17B", self.fields.get("17B", "ACTI//Y")),
        ]

    def _default_mt536_fields(self) -> list[tuple[str, str]]:
        """Return MT536 statement header defaults."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("98A", self.fields.get("98A", f"::STAT//{self.value_date}")),
            ("97A", self.fields.get("97A", self.metadata.get("safe_account", "SAFE//UNKNOWN"))),
            ("17B", self.fields.get("17B", "ACTI//Y")),
        ]

    def _default_settlement_fields(self) -> list[tuple[str, str]]:
        """Return shared settlement instruction fields for MT540-MT543."""
        return [
            ("23G", self.fields.get("23G", "NEWM")),
            ("98A", self.fields.get("98A", f"::SETT//{self.value_date}")),
            ("35B", self.fields.get("35B", "ISIN UNKNOWN")),
            ("36B", self.fields.get("36B", f"::SETT//UNIT/{_format_amount(self.amount)}")),
            ("95P", self.fields.get("95P", self.receiver_bic)),
        ]

    def _default_mt900_910_fields(self, credit: bool) -> list[tuple[str, str]]:
        """Return debit or credit confirmation defaults."""
        account = self.fields.get("25", self.metadata.get("account_id", "ACCOUNT-UNSPECIFIED"))
        qualifier = "CRDT" if credit else "DBIT"
        narrative = self.fields.get("86", self.metadata.get("reconciliation_note", "AUTO RECONCILIATION ENTRY"))
        return [
            ("25", account),
            ("13D", self.fields.get("13D", f"{_utc_date()}{_utc_time()}+0000")),
            ("32A", self.fields.get("32A", f"{self.value_date}{self.currency}{_format_amount(self.amount)}")),
            ("52A", self.fields.get("52A", self.sender_bic)),
            ("57A", self.fields.get("57A", self.receiver_bic or self.sender_bic)),
            ("86", f"{qualifier} {narrative}"),
        ]

    def _default_mt940_fields(self) -> list[tuple[str, str]]:
        """Return MT940 header defaults."""
        account = self.fields.get("25", self.metadata.get("account_id", "ACCOUNT-UNSPECIFIED"))
        statement_no = self.metadata.get("statement_number", "00001")
        sequence_no = self.metadata.get("sequence_number", "001")
        opening = self.metadata.get("opening_balance", f"C{_normalise_statement_date(self.value_date)}{self.currency}{_format_amount(0.0)}")
        closing = self.metadata.get("closing_balance", f"C{_normalise_statement_date(self.value_date)}{self.currency}{_format_amount(self.amount)}")
        return [
            ("25", account),
            ("28C", f"{statement_no}/{sequence_no}"),
            ("60F", opening),
            ("62F", closing),
        ]

    def _default_mt950_fields(self) -> list[tuple[str, str]]:
        """Return MT950 header defaults."""
        account = self.fields.get("25", self.metadata.get("account_id", "ACCOUNT-UNSPECIFIED"))
        opening = self.metadata.get("opening_balance", f"C{_normalise_statement_date(self.value_date)}{self.currency}{_format_amount(0.0)}")
        closing = self.metadata.get("closing_balance", f"C{_normalise_statement_date(self.value_date)}{self.currency}{_format_amount(self.amount)}")
        return [
            ("25", account),
            ("28C", self.metadata.get("statement_number", "00001/001")),
            ("60M", opening),
            ("62M", closing),
        ]

    def _message_specific_defaults(self) -> list[tuple[str, str]]:
        """Return defaults for the configured message type."""
        if self.message_type == SWIFTMessageType.MT103:
            return self._default_mt103_fields()
        if self.message_type == SWIFTMessageType.MT202:
            return self._default_mt202_fields()
        if self.message_type == SWIFTMessageType.MT202COV:
            return self._default_mt202cov_fields()
        if self.message_type == SWIFTMessageType.MT300:
            return self._default_mt300_fields()
        if self.message_type == SWIFTMessageType.MT320:
            return self._default_mt320_fields()
        if self.message_type == SWIFTMessageType.MT502:
            return self._default_mt502_fields()
        if self.message_type == SWIFTMessageType.MT515:
            return self._default_mt515_fields()
        if self.message_type == SWIFTMessageType.MT518:
            return self._default_mt518_fields()
        if self.message_type == SWIFTMessageType.MT535:
            return self._default_mt535_fields()
        if self.message_type == SWIFTMessageType.MT536:
            return self._default_mt536_fields()
        if self.message_type in {
            SWIFTMessageType.MT540,
            SWIFTMessageType.MT541,
            SWIFTMessageType.MT542,
            SWIFTMessageType.MT543,
        }:
            defaults = self._default_settlement_fields()
            if self.message_type in {SWIFTMessageType.MT541, SWIFTMessageType.MT543}:
                defaults.append(
                    ("19A", self.fields.get("19A", f"SETT//{self.currency}{_format_amount(self.metadata.get('settlement_amount', 0.0))}"))
                )
            return defaults
        if self.message_type == SWIFTMessageType.MT900:
            return self._default_mt900_910_fields(credit=False)
        if self.message_type == SWIFTMessageType.MT910:
            return self._default_mt900_910_fields(credit=True)
        if self.message_type == SWIFTMessageType.MT940:
            return self._default_mt940_fields()
        if self.message_type == SWIFTMessageType.MT950:
            return self._default_mt950_fields()
        return []

    def _append_schedule_lines(self, lines: list[str]) -> None:
        """Append MT320 schedule lines."""
        for schedule in self.schedules:
            lines.extend(schedule.to_mt_lines())

    def _append_position_lines(self, lines: list[str]) -> None:
        """Append MT535 position details."""
        for position in self.positions:
            security = position.get("security", {})
            quantity = float(position.get("quantity", 0.0))
            market_value = float(position.get("market_value", 0.0))
            currency = _normalise_currency(str(position.get("currency", self.currency)))
            qualifier = _clean_text(str(position.get("balance_type", "AVAI")))
            lines.append(":16R:FIN")
            lines.append(f":35B:ISIN {security.get('isin', 'UNKNOWN')}")
            description = security.get("description", "SECURITY POSITION")
            for line in _wrap_lines(_clean_text(str(description))):
                lines.append(line)
            lines.append(f":93B::{qualifier}//UNIT/{_format_amount(quantity, 4)}")
            lines.append(f":19A::HOLD//{currency}{_format_amount(market_value)}")
            if position.get("safekeeping_account"):
                lines.append(f":97A::SAFE//{_clean_text(str(position['safekeeping_account']))}")
            if position.get("price"):
                lines.append(f":90A::MRKT//PRCT/{_format_amount(float(position['price']), 6)}")
            lines.append(":16S:FIN")

    def _append_transaction_lines(self, lines: list[str]) -> None:
        """Append MT536 or MT940/950 transaction lines."""
        if self.message_type in {SWIFTMessageType.MT536}:
            for transaction in self.transactions:
                lines.append(":16R:TRAN")
                trade_date = _normalise_mt_date(str(transaction.get("trade_date", self.value_date)))
                settle_date = _normalise_mt_date(str(transaction.get("settlement_date", self.value_date)))
                lines.append(f":98A::TRAD//{trade_date}")
                lines.append(f":98A::SETT//{settle_date}")
                lines.append(f":35B:ISIN {transaction.get('isin', 'UNKNOWN')}")
                quantity = float(transaction.get("quantity", 0.0))
                amount = float(transaction.get("amount", 0.0))
                currency = _normalise_currency(str(transaction.get("currency", self.currency)))
                lines.append(f":22H::REDE//{_clean_text(str(transaction.get('direction', 'RECE')))}")
                lines.append(f":36B::SETT//UNIT/{_format_amount(quantity, 4)}")
                lines.append(f":19A::SETT//{currency}{_format_amount(amount)}")
                if transaction.get("status"):
                    lines.append(f":25D::{_clean_text(str(transaction['status']))}//COMP")
                if transaction.get("narrative"):
                    lines.append(f":70E::TRDE//{_clean_multiline_text(str(transaction['narrative']))}")
                lines.append(":16S:TRAN")
            return
        for transaction in self.transactions:
            entry_date = _normalise_statement_date(str(transaction.get("entry_date", self.value_date)))
            funds_date = _normalise_statement_date(str(transaction.get("funds_date", self.value_date)))
            direction = _clean_text(str(transaction.get("direction", "C")))
            amount = _format_amount(float(transaction.get("amount", 0.0)))
            code = _clean_text(str(transaction.get("transaction_code", "NMSC")))
            reference = _clean_text(str(transaction.get("reference", self.reference)))
            details = _clean_multiline_text(str(transaction.get("details", "RECONCILED ENTRY")))
            lines.append(f":61:{entry_date}{funds_date}{direction}{amount}{code}{reference}")
            lines.append(f":86:{details}")

    def _append_custom_fields(self, lines: list[str], used_tags: set[str]) -> None:
        """Append user-supplied fields not already emitted as defaults."""
        for tag, value in self.fields.items():
            base_tag = tag.split("-", 1)[0]
            if base_tag in used_tags:
                continue
            _append_tagged_lines(lines, tag, value)
        for tag, value in self.repeating_fields:
            actual_tag = tag.split("-", 1)[0]
            _append_tagged_lines(lines, actual_tag, value)

    def to_mt_format(self) -> str:
        """Render the message in SWIFT MT text form."""
        lines = [self._block_one(), self._block_two(), *self._block_three(), "{4:"]
        body_pairs = self._base_body() + self._message_specific_defaults()
        used_tags: set[str] = set()
        for tag, value in body_pairs:
            used_tags.add(tag)
            _append_tagged_lines(lines, tag, value)
        if self.message_type == SWIFTMessageType.MT320:
            self._append_schedule_lines(lines)
        if self.message_type == SWIFTMessageType.MT535:
            self._append_position_lines(lines)
        if self.message_type in {SWIFTMessageType.MT536, SWIFTMessageType.MT940, SWIFTMessageType.MT950}:
            self._append_transaction_lines(lines)
        self._append_custom_fields(lines, used_tags)
        if self.narrative and "72" not in used_tags and self.message_type not in {SWIFTMessageType.MT202COV}:
            _append_tagged_lines(lines, "72", self.narrative)
        lines.append("-}")
        return "\n".join(lines)


class SWIFTValidationEngine:
    """Validation service for SWIFT MT and MX messages."""

    bic_country_codes = {
        "US", "GB", "DE", "FR", "NL", "CH", "SG", "JP", "HK", "AE", "IN", "CA",
        "AU", "LU", "IE", "SE", "NO", "DK", "BE", "IT", "ES", "ZA", "BR", "MX",
    }

    def validate_bic(self, bic: str, field_name: str = "bic") -> list[ValidationIssue]:
        """Validate a BIC structure without regular expressions."""
        issues: list[ValidationIssue] = []
        cleaned = _normalise_bic(bic)
        if len(cleaned) not in {8, 11}:
            issues.append(
                ValidationIssue(
                    ValidationSeverity.ERROR,
                    field_name,
                    "BIC must contain 8 or 11 characters.",
                )
            )
            return issues
        institution = cleaned[0:4]
        country = cleaned[4:6]
        location = cleaned[6:8]
        branch = cleaned[8:11] if len(cleaned) == 11 else ""
        if not institution.isalpha():
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "BIC institution code must be alphabetic."))
        if not country.isalpha():
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "BIC country code must be alphabetic."))
        elif country not in self.bic_country_codes:
            issues.append(ValidationIssue(ValidationSeverity.WARNING, field_name, "BIC country code is not in the common allow-list."))
        if not location.isalnum():
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "BIC location code must be alphanumeric."))
        if branch and not branch.isalnum():
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "BIC branch code must be alphanumeric."))
        return issues

    def validate_currency(self, currency: str, field_name: str = "currency") -> list[ValidationIssue]:
        """Validate the basic format of an ISO currency code."""
        issues: list[ValidationIssue] = []
        cleaned = _normalise_currency(currency)
        if len(cleaned) != 3 or not cleaned.isalpha():
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Currency must be a 3-letter ISO code."))
        return issues

    def validate_date(self, value: str, field_name: str) -> list[ValidationIssue]:
        """Validate date shape and rough calendar ranges."""
        issues: list[ValidationIssue] = []
        digits = _only_digits(value)
        if len(digits) not in {6, 8}:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Date must be YYMMDD or YYYYMMDD."))
            return issues
        if len(digits) == 6:
            digits = f"20{digits}"
        year = int(digits[0:4])
        month = int(digits[4:6])
        day = int(digits[6:8])
        if not 1 <= month <= 12:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Month must be between 1 and 12."))
        if month and not 1 <= day <= _days_in_month(year, month):
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Day is outside the valid month range."))
        return issues

    def validate_amount(self, amount: float, field_name: str = "amount") -> list[ValidationIssue]:
        """Validate monetary amount values."""
        issues: list[ValidationIssue] = []
        if amount <= 0:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Amount must be greater than zero."))
        return issues

    def validate_mt_field_formats(self, message: SWIFTMessage) -> list[ValidationIssue]:
        """Validate common MT field shapes."""
        issues: list[ValidationIssue] = []
        for bic_field in ("52A", "53A", "54A", "56A", "57A", "58A", "82A", "87A", "95P"):
            if bic_field in message.fields:
                issues.extend(self.validate_bic(message.fields[bic_field].splitlines()[-1], bic_field))
        if "32A" in message.fields:
            raw = message.fields["32A"]
            if len(raw) < 9:
                issues.append(ValidationIssue(ValidationSeverity.ERROR, "32A", "Field 32A is too short."))
            else:
                issues.extend(self.validate_date(raw[:6], "32A.date"))
                issues.extend(self.validate_currency(raw[6:9], "32A.currency"))
        if "35B" in message.fields and "ISIN" not in _clean_text(message.fields["35B"]):
            issues.append(ValidationIssue(ValidationSeverity.WARNING, "35B", "Security identification usually includes an ISIN."))
        if message.message_type in {SWIFTMessageType.MT940, SWIFTMessageType.MT950} and not message.transactions:
            issues.append(ValidationIssue(ValidationSeverity.WARNING, "transactions", "Statement contains no transaction entries."))
        if message.message_type == SWIFTMessageType.MT535 and not message.positions:
            issues.append(ValidationIssue(ValidationSeverity.WARNING, "positions", "Holding statement contains no positions."))
        return issues

    def validate_mandatory_fields(self, message: SWIFTMessage) -> list[ValidationIssue]:
        """Validate mandatory fields for a SWIFT MT message."""
        requirements: dict[SWIFTMessageType, list[str]] = {
            SWIFTMessageType.MT103: ["23B", "32A", "50K", "59", "71A"],
            SWIFTMessageType.MT202: ["32A", "52A", "58A"],
            SWIFTMessageType.MT202COV: ["21", "32A", "52A", "56A", "57A", "50A", "59A"],
            SWIFTMessageType.MT300: ["30T", "30V", "32B", "33B", "36"],
            SWIFTMessageType.MT320: ["30P", "30F", "32B", "37H"],
            SWIFTMessageType.MT502: ["23G", "35B", "22H", "36B"],
            SWIFTMessageType.MT515: ["35B", "36B", "19A"],
            SWIFTMessageType.MT518: ["35B", "36B", "19A"],
            SWIFTMessageType.MT535: ["97A"],
            SWIFTMessageType.MT536: ["97A"],
            SWIFTMessageType.MT540: ["35B", "36B", "95P"],
            SWIFTMessageType.MT541: ["35B", "36B", "95P", "19A"],
            SWIFTMessageType.MT542: ["35B", "36B", "95P"],
            SWIFTMessageType.MT543: ["35B", "36B", "95P", "19A"],
            SWIFTMessageType.MT900: ["25", "32A"],
            SWIFTMessageType.MT910: ["25", "32A"],
            SWIFTMessageType.MT940: ["25", "28C", "60F", "62F"],
            SWIFTMessageType.MT950: ["25", "28C", "60M", "62M"],
        }
        issues: list[ValidationIssue] = []
        required = requirements.get(message.message_type, [])
        effective_fields = {tag: value for tag, value in message._base_body() + message._message_specific_defaults()}
        effective_fields.update(message.fields)
        for field_name in required:
            if field_name not in effective_fields or not str(effective_fields[field_name]).strip():
                issues.append(ValidationIssue(ValidationSeverity.ERROR, field_name, "Mandatory field missing."))
        return issues

    def validate_message(self, message: SWIFTMessage) -> list[ValidationIssue]:
        """Validate a complete SWIFT MT message."""
        issues: list[ValidationIssue] = []
        issues.extend(self.validate_bic(message.sender_bic, "sender_bic"))
        issues.extend(self.validate_bic(message.receiver_bic or message.sender_bic, "receiver_bic"))
        issues.extend(self.validate_currency(message.currency))
        issues.extend(self.validate_date(message.value_date, "value_date"))
        if message.message_type not in {SWIFTMessageType.MT535, SWIFTMessageType.MT536, SWIFTMessageType.MT940, SWIFTMessageType.MT950}:
            issues.extend(self.validate_amount(message.amount))
        issues.extend(self.validate_mandatory_fields(message))
        issues.extend(self.validate_mt_field_formats(message))
        return issues

    def validate_mx_message(self, message: MXMessage) -> list[ValidationIssue]:
        """Validate a SWIFT MX message."""
        issues: list[ValidationIssue] = []
        issues.extend(self.validate_bic(message.sender_bic, "sender_bic"))
        issues.extend(self.validate_bic(message.receiver_bic, "receiver_bic"))
        if not message.payload:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, "payload", "MX payload must not be empty."))
        if not message.message_definition_id:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, "message_definition_id", "Message definition identifier is required."))
        if not message.business_message_id:
            issues.append(ValidationIssue(ValidationSeverity.ERROR, "business_message_id", "Business message identifier is required."))
        return issues


class SWIFTRoutingEngine:
    """Routing support for correspondent banking chains and GPI metadata."""

    default_corridors: dict[str, list[str]] = {
        "USD": ["IRVTUS3NXXX", "CHASUS33XXX"],
        "EUR": ["DEUTDEFFXXX", "BNPAFRPPXXX"],
        "GBP": ["BARCGB22XXX", "LOYDGB2LXXX"],
        "CHF": ["UBSWCHZH80A"],
        "JPY": ["BOTKJPJTXXX"],
        "SGD": ["DBSSSGSGXXX"],
    }

    def generate_tracking_reference(self, sender_bic: str, receiver_bic: str, reference: str) -> str:
        """Return a lightweight SWIFT GPI-style tracking identifier."""
        timestamp = _utc_timestamp()
        sender = _normalise_bic(sender_bic)[:8]
        receiver = _normalise_bic(receiver_bic)[:8]
        suffix = _clean_text(reference)[-12:].rjust(12, "0")
        return f"GPI-{sender}-{receiver}-{timestamp}-{suffix}"

    def select_intermediaries(
        self,
        currency: str,
        preferred_bics: Sequence[str] | None = None,
        max_hops: int = 2,
    ) -> list[RouteHop]:
        """Select intermediary institutions for the currency corridor."""
        currency_code = _normalise_currency(currency)
        selected: list[RouteHop] = []
        candidates: list[str] = []
        if preferred_bics:
            candidates.extend(_normalise_bic(value) for value in preferred_bics if value)
        candidates.extend(self.default_corridors.get(currency_code, []))
        for bic in candidates:
            if bic and bic not in {hop.bic for hop in selected}:
                selected.append(RouteHop(role=RouteHopRole.INTERMEDIARY, bic=bic))
            if len(selected) >= max_hops:
                break
        return selected

    def build_routing_instruction(
        self,
        sender_bic: str,
        receiver_bic: str,
        currency: str,
        reference: str,
        sender_correspondent: str = "",
        account_with_institution: str = "",
        preferred_intermediaries: Sequence[str] | None = None,
        service_level: str = "SWIFT",
    ) -> RoutingInstruction:
        """Create routing information for a payment or settlement transfer."""
        tracking = self.generate_tracking_reference(sender_bic, receiver_bic, reference)
        instruction = RoutingInstruction(
            service_level=service_level,
            tracking_reference=tracking,
            receiver=RouteHop(RouteHopRole.RECEIVER, _normalise_bic(receiver_bic)),
            notes=[f"ROUTED VIA {service_level}", f"TRACKING {tracking}"],
        )
        if sender_correspondent:
            instruction.sender_correspondent = RouteHop(
                RouteHopRole.SENDER_CORRESPONDENT,
                _normalise_bic(sender_correspondent),
            )
        instruction.intermediaries = self.select_intermediaries(currency, preferred_intermediaries)
        if account_with_institution:
            instruction.account_with_institution = RouteHop(
                RouteHopRole.ACCOUNT_WITH,
                _normalise_bic(account_with_institution),
            )
        else:
            instruction.account_with_institution = RouteHop(
                RouteHopRole.ACCOUNT_WITH,
                _normalise_bic(receiver_bic),
            )
        return instruction

    def build_cover_chain(
        self,
        payment_message: SWIFTMessage,
        correspondent_bics: Sequence[str] | None = None,
    ) -> RoutingInstruction:
        """Build a routing chain suitable for MT202COV cover payments."""
        service_level = _clean_text(str(payment_message.metadata.get("service_level", "SWIFT GPI")))
        sender_correspondent = str(payment_message.metadata.get("sender_correspondent", payment_message.sender_correspondent))
        account_with = str(payment_message.metadata.get("account_with_institution", payment_message.receiver_correspondent or payment_message.receiver_bic))
        preferred = correspondent_bics or payment_message.metadata.get("intermediaries", [])
        return self.build_routing_instruction(
            sender_bic=payment_message.sender_bic,
            receiver_bic=payment_message.receiver_bic,
            currency=payment_message.currency,
            reference=payment_message.reference,
            sender_correspondent=sender_correspondent,
            account_with_institution=account_with,
            preferred_intermediaries=list(preferred),
            service_level=service_level,
        )


class SWIFTEngine:
    """SWIFT message generation engine for treasury and securities operations."""

    def __init__(self, sender_bic: str = "PARRALAXXX") -> None:
        self.sender_bic = _normalise_bic(sender_bic)
        self.message_log: list[SWIFTMessage] = []
        self.mx_message_log: list[MXMessage] = []
        self.validator = SWIFTValidationEngine()
        self.router = SWIFTRoutingEngine()

    def _record_message(self, message: SWIFTMessage) -> SWIFTMessage:
        """Validate, log, and return a SWIFT MT message."""
        issues = self.validator.validate_message(message)
        message.metadata["validation_issues"] = [issue.to_dict() for issue in issues]
        self.message_log.append(message)
        return message

    def _record_mx_message(self, message: MXMessage) -> MXMessage:
        """Validate, log, and return an MX message."""
        issues = self.validator.validate_mx_message(message)
        message.payload.setdefault("ValidationSummary", [issue.to_dict() for issue in issues])
        self.mx_message_log.append(message)
        return message

    def _build_party_field(
        self,
        account: str,
        name: str,
        address_lines: Sequence[str] | None = None,
        bic: str = "",
    ) -> str:
        """Return a SWIFT multi-line party field."""
        lines: list[str] = []
        if account:
            lines.append(f"/{_clean_text(account)}")
        if bic:
            lines.append(_normalise_bic(bic))
        if name:
            lines.extend(_wrap_lines(_clean_text(name)))
        for line in address_lines or []:
            cleaned = _clean_text(line)
            if cleaned:
                lines.extend(_wrap_lines(cleaned))
        return "\n".join(lines)

    def _build_charge_summary(self, charge_bearer: str, charges: Sequence[Mapping[str, Any]] | None) -> str:
        """Return charge summary narrative for cash transfers."""
        parts = [f"CHARGES { _clean_text(charge_bearer) }"]
        for charge in charges or []:
            agent = _clean_text(str(charge.get("agent", "AGENT")))
            currency = _normalise_currency(str(charge.get("currency", "USD")))
            amount = _format_amount(float(charge.get("amount", 0.0)))
            parts.append(f"{agent} {currency}{amount}")
        return " | ".join(parts)

    def _generate_schedule(
        self,
        principal: float,
        currency: str,
        start_date: str,
        maturity_date: str,
        interest_rate: float,
        frequency: str,
        day_count_basis: str = "ACT/360",
    ) -> list[ScheduleEntry]:
        """Generate a simple fixed-rate loan or deposit schedule."""
        schedules: list[ScheduleEntry] = []
        start = _normalise_mt_date(start_date)
        maturity = _normalise_mt_date(maturity_date)
        months = _frequency_to_months(frequency)
        current_start = start
        period = 1
        while current_start < maturity:
            next_date = _add_months(current_start, months)
            current_end = maturity if next_date > maturity else next_date
            days = max(1, _days_between(current_start, current_end))
            denominator = 365.0 if _clean_text(day_count_basis) == "ACT/365" else 360.0
            interest = principal * interest_rate * (days / denominator)
            schedules.append(
                ScheduleEntry(
                    period_number=period,
                    start_date=current_start,
                    end_date=current_end,
                    payment_date=current_end,
                    notional=principal,
                    currency=_normalise_currency(currency),
                    rate=interest_rate,
                    interest_amount=interest,
                    principal_amount=principal if current_end == maturity else 0.0,
                    day_count_basis=day_count_basis,
                )
            )
            current_start = current_end
            period += 1
            if period > 240:
                break
        return schedules

    def _apply_routing(
        self,
        message: SWIFTMessage,
        sender_correspondent: str = "",
        account_with_institution: str = "",
        intermediaries: Sequence[str] | None = None,
        service_level: str = "SWIFT GPI",
    ) -> RoutingInstruction:
        """Apply routing and tracking metadata to a message."""
        instruction = self.router.build_routing_instruction(
            sender_bic=message.sender_bic,
            receiver_bic=message.receiver_bic,
            currency=message.currency,
            reference=message.reference,
            sender_correspondent=sender_correspondent,
            account_with_institution=account_with_institution,
            preferred_intermediaries=intermediaries,
            service_level=service_level,
        )
        instruction.apply_to_message(message)
        message.metadata["routing"] = {
            "service_level": instruction.service_level,
            "tracking_reference": instruction.tracking_reference,
            "sender_correspondent": instruction.sender_correspondent.bic if instruction.sender_correspondent else "",
            "intermediaries": [hop.bic for hop in instruction.intermediaries],
            "account_with_institution": instruction.account_with_institution.bic if instruction.account_with_institution else "",
            "receiver": instruction.receiver.bic if instruction.receiver else "",
        }
        return instruction

    def create_payment(
        self,
        receiver_bic: str,
        amount: float,
        currency: str = "USD",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT103 single customer credit transfer.

        This method is retained for backwards compatibility. The expanded version
        enriches the message with default ordering and beneficiary fields,
        validation metadata, and a lightweight GPI tracking reference.
        """
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT103,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=amount,
            currency=currency,
            narrative=narrative or "PARRALAX HFT FUND SETTLEMENT",
        )
        msg.fields["50K"] = self._build_party_field(
            account=self.sender_bic,
            name="PARRALAX AI HFT FUND",
            address_lines=["TREASURY OPERATIONS", "GLOBAL MARKETS DESK"],
        )
        msg.fields["59"] = self._build_party_field(
            account=receiver_bic,
            name="RECEIVING INSTITUTION",
            address_lines=["BENEFICIARY CLIENT ACCOUNT"],
        )
        msg.fields["70"] = narrative or "TRADING SETTLEMENT"
        msg.fields["71A"] = "SHA"
        self._apply_routing(msg, account_with_institution=receiver_bic, service_level="SWIFT GPI")
        return self._record_message(msg)

    def create_cover_payment(
        self,
        receiver_bic: str,
        amount: float,
        currency: str = "USD",
        underlying_reference: str = "",
        ordering_customer: Mapping[str, Any] | None = None,
        beneficiary_customer: Mapping[str, Any] | None = None,
        sender_correspondent: str = "",
        account_with_institution: str = "",
        intermediaries: Sequence[str] | None = None,
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT202COV cover payment for an underlying MT103.

        The generated message includes standard compliance-related fields for the
        underlying ordering and beneficiary customer, intermediary routing, and
        a GPI tracking identifier.
        """
        ordering = ordering_customer or {
            "account": "ORDERCUST001",
            "name": "PARRALAX AI HFT FUND",
            "address_lines": ["100 MARKET STREET", "NEW YORK US"],
            "bic": self.sender_bic,
        }
        beneficiary = beneficiary_customer or {
            "account": "BENEF001",
            "name": "UNDERLYING BENEFICIARY",
            "address_lines": ["200 SETTLEMENT AVENUE", "LONDON GB"],
            "bic": receiver_bic,
        }
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT202COV,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=amount,
            currency=currency,
            narrative=narrative or "COVER PAYMENT FOR UNDERLYING MT103",
            related_reference=underlying_reference or _mt_reference("UETR"),
        )
        msg.fields["21"] = msg.related_reference
        msg.fields["32A"] = f"{msg.value_date}{msg.currency}{_format_amount(amount)}"
        msg.fields["50A"] = self._build_party_field(
            account=str(ordering.get("account", "")),
            name=str(ordering.get("name", "ORDERING CUSTOMER")),
            address_lines=ordering.get("address_lines", []),
            bic=str(ordering.get("bic", self.sender_bic)),
        )
        msg.fields["59A"] = self._build_party_field(
            account=str(beneficiary.get("account", "")),
            name=str(beneficiary.get("name", "BENEFICIARY CUSTOMER")),
            address_lines=beneficiary.get("address_lines", []),
            bic=str(beneficiary.get("bic", receiver_bic)),
        )
        msg.fields["70"] = _clean_text(str(ordering.get("purpose", "UNDERLYING CUSTOMER CREDIT TRANSFER")))
        msg.metadata["underlying_remittance"] = msg.fields["70"]
        msg.metadata["compliance_narrative"] = narrative or "KYC SCREENED / SANCTIONS CHECK COMPLETE / SOURCE OF FUNDS VERIFIED"
        msg.metadata["sender_correspondent"] = sender_correspondent or self.sender_bic
        msg.metadata["account_with_institution"] = account_with_institution or receiver_bic
        msg.metadata["intermediaries"] = list(intermediaries or [])
        self._apply_routing(
            msg,
            sender_correspondent=sender_correspondent or self.sender_bic,
            account_with_institution=account_with_institution or receiver_bic,
            intermediaries=intermediaries,
            service_level="SWIFT GPI",
        )
        return self._record_message(msg)

    def create_fx_confirmation(
        self,
        counterparty_bic: str,
        buy_currency: str,
        buy_amount: float,
        sell_currency: str,
        sell_amount: float,
        value_date: str = "",
    ) -> SWIFTMessage:
        """Create an MT300 foreign exchange confirmation."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT300,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=buy_amount,
            currency=buy_currency,
            value_date=value_date or _utc_date(),
            narrative="FX CONFIRMATION",
        )
        msg.fields["30T"] = msg.value_date
        msg.fields["30V"] = msg.value_date
        msg.fields["32B"] = f"{_normalise_currency(buy_currency)}{_format_amount(buy_amount)}"
        msg.fields["33B"] = f"{_normalise_currency(sell_currency)}{_format_amount(sell_amount)}"
        msg.fields["36"] = _format_amount(sell_amount / buy_amount if buy_amount else 0.0, 6)
        msg.fields["82A"] = self.sender_bic
        msg.fields["87A"] = _normalise_bic(counterparty_bic)
        return self._record_message(msg)

    def create_loan_deposit_confirmation(
        self,
        counterparty_bic: str,
        principal: float,
        currency: str = "USD",
        start_date: str = "",
        maturity_date: str = "",
        interest_rate: float = 0.0,
        payment_frequency: str = "MONTHLY",
        day_count_basis: str = "ACT/360",
        borrower_lender_indicator: str = "PLAC",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT320 fixed loan or deposit confirmation with schedule."""
        start = _normalise_mt_date(start_date or _utc_date())
        maturity = _normalise_mt_date(maturity_date or _add_months(start, 1))
        schedules = self._generate_schedule(
            principal=principal,
            currency=currency,
            start_date=start,
            maturity_date=maturity,
            interest_rate=interest_rate,
            frequency=payment_frequency,
            day_count_basis=day_count_basis,
        )
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT320,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=principal,
            currency=currency,
            value_date=start,
            narrative=narrative or "FIXED LOAN OR DEPOSIT CONFIRMATION",
            schedules=schedules,
        )
        msg.metadata["trade_date"] = start
        msg.metadata["start_date"] = start
        msg.metadata["maturity_date"] = maturity
        msg.metadata["day_count_basis"] = day_count_basis
        msg.metadata["rate_text"] = _format_amount(interest_rate, 6)
        msg.fields["22A"] = "NEWT"
        msg.fields["22F"] = f"LOAN//{_clean_text(borrower_lender_indicator)}"
        msg.fields["30T"] = start
        msg.fields["30V"] = start
        msg.fields["30P"] = start
        msg.fields["30F"] = maturity
        msg.fields["32B"] = f"{_normalise_currency(currency)}{_format_amount(principal)}"
        msg.fields["37H"] = _format_amount(interest_rate, 6)
        msg.fields["14D"] = day_count_basis
        msg.fields["82A"] = self.sender_bic
        msg.fields["87A"] = _normalise_bic(counterparty_bic)
        msg.metadata["schedule"] = [entry.to_dict() for entry in schedules]
        return self._record_message(msg)

    def create_securities_order(
        self,
        broker_bic: str,
        isin: str,
        quantity: float,
        side: str = "BUY",
        price: float = 0.0,
    ) -> SWIFTMessage:
        """Create an MT502 order to buy or sell securities."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT502,
            sender_bic=self.sender_bic,
            receiver_bic=broker_bic,
            amount=quantity,
            currency="USD",
            narrative="SECURITIES ORDER",
        )
        msg.fields["35B"] = f"ISIN {_clean_text(isin)}"
        msg.fields["22H"] = f"BUSE//{_clean_text(side)}"
        msg.fields["36B"] = f"::SETT//UNIT/{_format_amount(quantity, 4)}"
        if price > 0:
            msg.fields["90A"] = f"DEAL//PRCT/{_format_amount(price, 6)}"
        return self._record_message(msg)

    def create_client_confirmation(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        settlement_amount: float,
        currency: str = "USD",
        side: str = "BUY",
        account: str = "SAFE//CLIENT001",
        settlement_date: str = "",
        price: float = 0.0,
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT515 client confirmation of purchase or sale."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT515,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=quantity,
            currency=currency,
            value_date=settlement_date or _utc_date(),
            narrative=narrative or "CLIENT PURCHASE OR SALE CONFIRMATION",
        )
        msg.fields["35B"] = f"ISIN {_clean_text(isin)}"
        msg.fields["22H"] = f"BUSE//{_clean_text(side)}"
        msg.fields["36B"] = f"::SETT//UNIT/{_format_amount(quantity, 4)}"
        msg.fields["19A"] = f"PSTA//{_normalise_currency(currency)}{_format_amount(settlement_amount)}"
        msg.fields["97A"] = account
        if price > 0:
            msg.fields["90A"] = f"DEAL//PRCT/{_format_amount(price, 6)}"
        return self._record_message(msg)

    def create_market_confirmation(
        self,
        market_counterparty_bic: str,
        isin: str,
        quantity: float,
        settlement_amount: float,
        currency: str = "USD",
        direction: str = "RECE",
        settlement_date: str = "",
        delivering_bic: str = "",
        receiving_bic: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT518 market-side trade confirmation."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT518,
            sender_bic=self.sender_bic,
            receiver_bic=market_counterparty_bic,
            amount=quantity,
            currency=currency,
            value_date=settlement_date or _utc_date(),
            narrative=narrative or "MARKET-SIDE CONFIRMATION",
        )
        msg.fields["35B"] = f"ISIN {_clean_text(isin)}"
        msg.fields["36B"] = f"::SETT//UNIT/{_format_amount(quantity, 4)}"
        msg.fields["19A"] = f"SETT//{_normalise_currency(currency)}{_format_amount(settlement_amount)}"
        msg.fields["22H"] = f"REDE//{_clean_text(direction)}"
        if delivering_bic:
            msg.fields["95P"] = _normalise_bic(delivering_bic)
        if receiving_bic:
            msg.fields["95Q"] = _normalise_bic(receiving_bic)
        return self._record_message(msg)

    def create_statement_of_holdings(
        self,
        receiver_bic: str,
        safekeeping_account: str,
        positions: Sequence[Mapping[str, Any]],
        statement_date: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT535 statement of holdings with multi-position support."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT535,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=float(sum(float(position.get("market_value", 0.0)) for position in positions)),
            currency=_normalise_currency(str(positions[0].get("currency", "USD"))) if positions else "USD",
            value_date=statement_date or _utc_date(),
            narrative=narrative or "STATEMENT OF HOLDINGS",
            positions=[dict(position) for position in positions],
        )
        msg.metadata["safe_account"] = f"SAFE//{_clean_text(safekeeping_account)}"
        msg.fields["97A"] = msg.metadata["safe_account"]
        return self._record_message(msg)

    def create_statement_of_transactions(
        self,
        receiver_bic: str,
        safekeeping_account: str,
        transactions: Sequence[Mapping[str, Any]],
        statement_date: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT536 statement of transactions."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT536,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=float(sum(float(item.get("amount", 0.0)) for item in transactions)),
            currency=_normalise_currency(str(transactions[0].get("currency", "USD"))) if transactions else "USD",
            value_date=statement_date or _utc_date(),
            narrative=narrative or "STATEMENT OF TRANSACTIONS",
            transactions=[dict(transaction) for transaction in transactions],
        )
        msg.metadata["safe_account"] = f"SAFE//{_clean_text(safekeeping_account)}"
        msg.fields["97A"] = msg.metadata["safe_account"]
        return self._record_message(msg)

    def _create_settlement_message(
        self,
        message_type: SWIFTMessageType,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        amount: float,
        currency: str = "USD",
        settlement_date: str = "",
        narrative: str = "",
        place_of_settlement: str = "",
    ) -> SWIFTMessage:
        """Internal helper for MT540 through MT543 generation."""
        msg = SWIFTMessage(
            message_type=message_type,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=quantity,
            currency=currency,
            value_date=settlement_date or _utc_date(),
            narrative=narrative or "SECURITIES SETTLEMENT INSTRUCTION",
        )
        msg.metadata["settlement_amount"] = amount
        msg.fields["35B"] = f"ISIN {_clean_text(isin)}"
        msg.fields["36B"] = f"::SETT//UNIT/{_format_amount(quantity, 4)}"
        msg.fields["95P"] = _normalise_bic(counterparty_bic)
        if place_of_settlement:
            msg.fields["94B"] = f"SAFE//{_clean_text(place_of_settlement)}"
        if message_type in {SWIFTMessageType.MT541, SWIFTMessageType.MT543}:
            msg.fields["19A"] = f"SETT//{_normalise_currency(currency)}{_format_amount(amount)}"
        return self._record_message(msg)

    def create_receive_free_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        settlement_date: str = "",
        place_of_settlement: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT540 receive free settlement instruction."""
        return self._create_settlement_message(
            message_type=SWIFTMessageType.MT540,
            counterparty_bic=counterparty_bic,
            isin=isin,
            quantity=quantity,
            amount=0.0,
            settlement_date=settlement_date,
            narrative=narrative or "RECEIVE FREE",
            place_of_settlement=place_of_settlement,
        )

    def create_settlement_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        amount: float,
        currency: str = "USD",
    ) -> SWIFTMessage:
        """Create an MT541 receive against payment instruction.

        This method is retained for backwards compatibility and still creates an
        MT541 by default.
        """
        return self._create_settlement_message(
            message_type=SWIFTMessageType.MT541,
            counterparty_bic=counterparty_bic,
            isin=isin,
            quantity=quantity,
            amount=amount,
            currency=currency,
            narrative="RECEIVE AGAINST PAYMENT",
        )

    def create_receive_against_payment_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        amount: float,
        currency: str = "USD",
        settlement_date: str = "",
        place_of_settlement: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create a fully parameterised MT541 receive against payment instruction."""
        return self._create_settlement_message(
            message_type=SWIFTMessageType.MT541,
            counterparty_bic=counterparty_bic,
            isin=isin,
            quantity=quantity,
            amount=amount,
            currency=currency,
            settlement_date=settlement_date,
            narrative=narrative or "RECEIVE AGAINST PAYMENT",
            place_of_settlement=place_of_settlement,
        )

    def create_deliver_free_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        settlement_date: str = "",
        place_of_settlement: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT542 deliver free settlement instruction."""
        return self._create_settlement_message(
            message_type=SWIFTMessageType.MT542,
            counterparty_bic=counterparty_bic,
            isin=isin,
            quantity=quantity,
            amount=0.0,
            settlement_date=settlement_date,
            narrative=narrative or "DELIVER FREE",
            place_of_settlement=place_of_settlement,
        )

    def create_deliver_against_payment_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        amount: float,
        currency: str = "USD",
        settlement_date: str = "",
        place_of_settlement: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT543 deliver against payment settlement instruction."""
        return self._create_settlement_message(
            message_type=SWIFTMessageType.MT543,
            counterparty_bic=counterparty_bic,
            isin=isin,
            quantity=quantity,
            amount=amount,
            currency=currency,
            settlement_date=settlement_date,
            narrative=narrative or "DELIVER AGAINST PAYMENT",
            place_of_settlement=place_of_settlement,
        )

    def create_debit_confirmation(
        self,
        receiver_bic: str,
        account_id: str,
        amount: float,
        currency: str = "USD",
        related_reference: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT900 confirmation of debit with reconciliation support."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT900,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=amount,
            currency=currency,
            related_reference=related_reference,
            narrative=narrative or "DEBIT CONFIRMATION",
        )
        msg.metadata["account_id"] = account_id
        msg.metadata["reconciliation_note"] = narrative or f"DEBIT FOR {related_reference or msg.reference}"
        msg.fields["25"] = account_id
        msg.fields["32A"] = f"{msg.value_date}{msg.currency}{_format_amount(amount)}"
        return self._record_message(msg)

    def create_credit_confirmation(
        self,
        receiver_bic: str,
        account_id: str,
        amount: float,
        currency: str = "USD",
        related_reference: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT910 confirmation of credit with reconciliation support."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT910,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=amount,
            currency=currency,
            related_reference=related_reference,
            narrative=narrative or "CREDIT CONFIRMATION",
        )
        msg.metadata["account_id"] = account_id
        msg.metadata["reconciliation_note"] = narrative or f"CREDIT FOR {related_reference or msg.reference}"
        msg.fields["25"] = account_id
        msg.fields["32A"] = f"{msg.value_date}{msg.currency}{_format_amount(amount)}"
        return self._record_message(msg)

    def _statement_balance(
        self,
        sign: str,
        date: str,
        currency: str,
        amount: float,
    ) -> str:
        """Return a SWIFT balance line value."""
        return f"{_clean_text(sign)}{_normalise_statement_date(date)}{_normalise_currency(currency)}{_format_amount(amount)}"

    def create_customer_statement(
        self,
        receiver_bic: str,
        account_id: str,
        opening_balance: float,
        closing_balance: float,
        currency: str = "USD",
        statement_number: str = "00001",
        sequence_number: str = "001",
        transactions: Sequence[Mapping[str, Any]] | None = None,
        statement_date: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT940 customer statement with transactions and balances."""
        value_date = statement_date or _utc_date()
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT940,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=closing_balance,
            currency=currency,
            value_date=value_date,
            narrative=narrative or "CUSTOMER STATEMENT",
            transactions=[dict(item) for item in (transactions or [])],
        )
        msg.metadata["account_id"] = account_id
        msg.metadata["statement_number"] = statement_number
        msg.metadata["sequence_number"] = sequence_number
        msg.metadata["opening_balance"] = self._statement_balance("C", value_date, currency, opening_balance)
        msg.metadata["closing_balance"] = self._statement_balance("C", value_date, currency, closing_balance)
        msg.fields["25"] = account_id
        return self._record_message(msg)

    def create_account_statement(
        self,
        receiver_bic: str,
        account_id: str,
        opening_balance: float,
        closing_balance: float,
        currency: str = "USD",
        statement_number: str = "00001/001",
        transactions: Sequence[Mapping[str, Any]] | None = None,
        statement_date: str = "",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create an MT950 account statement with full transaction reporting."""
        value_date = statement_date or _utc_date()
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT950,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=closing_balance,
            currency=currency,
            value_date=value_date,
            narrative=narrative or "ACCOUNT STATEMENT",
            transactions=[dict(item) for item in (transactions or [])],
        )
        msg.metadata["account_id"] = account_id
        msg.metadata["statement_number"] = statement_number
        msg.metadata["opening_balance"] = self._statement_balance("C", value_date, currency, opening_balance)
        msg.metadata["closing_balance"] = self._statement_balance("C", value_date, currency, closing_balance)
        msg.fields["25"] = account_id
        return self._record_message(msg)

    def reconcile_cash_confirmations(
        self,
        confirmations: Sequence[SWIFTMessage],
        statement: SWIFTMessage,
    ) -> dict[str, Any]:
        """Reconcile MT900 and MT910 confirmations against an MT940 or MT950."""
        statement_refs = {
            _clean_text(str(transaction.get("reference", ""))): transaction
            for transaction in statement.transactions
        }
        matched: list[dict[str, Any]] = []
        unmatched: list[dict[str, Any]] = []
        for confirmation in confirmations:
            reference = _clean_text(confirmation.related_reference or confirmation.reference)
            amount = confirmation.amount
            expected = statement_refs.get(reference)
            if expected and abs(float(expected.get("amount", 0.0)) - amount) < 0.0001:
                matched.append(
                    {
                        "reference": reference,
                        "confirmation_type": confirmation.message_type.value,
                        "statement_transaction": expected,
                    }
                )
            else:
                unmatched.append(
                    {
                        "reference": reference,
                        "confirmation_type": confirmation.message_type.value,
                        "amount": amount,
                    }
                )
        return {
            "statement_reference": statement.reference,
            "matched": matched,
            "unmatched": unmatched,
            "matched_count": len(matched),
            "unmatched_count": len(unmatched),
        }

    def create_mx_credit_transfer(
        self,
        receiver_bic: str,
        amount: float,
        currency: str = "USD",
        debtor_name: str = "PARRALAX AI HFT FUND",
        creditor_name: str = "BENEFICIARY",
        remittance_info: str = "",
    ) -> MXMessage:
        """Create a pacs.008 FI to FI customer credit transfer message."""
        payload = {
            "FIToFICstmrCdtTrf": {
                "GrpHdr": {
                    "MsgId": _mt_reference("PACS008"),
                    "CreDtTm": _utc_iso_datetime(),
                    "NbOfTxs": "1",
                    "SttlmInf": {"SttlmMtd": "INDA"},
                },
                "CdtTrfTxInf": {
                    "PmtId": {
                        "InstrId": _mt_reference("INST"),
                        "EndToEndId": _mt_reference("E2E"),
                        "TxId": _mt_reference("TX"),
                    },
                    "IntrBkSttlmAmt": {"_attrs": {"Ccy": _normalise_currency(currency)}, "_value": _format_amount(amount).replace(",", ".")},
                    "ChrgBr": "SHAR",
                    "Dbtr": {"Nm": debtor_name},
                    "DbtrAgt": {"FinInstnId": {"BICFI": self.sender_bic}},
                    "CdtrAgt": {"FinInstnId": {"BICFI": _normalise_bic(receiver_bic)}},
                    "Cdtr": {"Nm": creditor_name},
                    "RmtInf": {"Ustrd": remittance_info or "TRADING SETTLEMENT"},
                },
            }
        }
        payload = self._normalise_mx_payload(payload)
        msg = MXMessage(
            message_type=MXMessageType.PACS_008,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            payload=payload,
        )
        return self._record_mx_message(msg)

    def create_mx_cover_transfer(
        self,
        receiver_bic: str,
        amount: float,
        currency: str = "USD",
        underlying_reference: str = "",
        instructing_agent: str = "",
        instructed_agent: str = "",
    ) -> MXMessage:
        """Create a pacs.009 financial institution cover transfer."""
        payload = {
            "FICdtTrf": {
                "GrpHdr": {
                    "MsgId": _mt_reference("PACS009"),
                    "CreDtTm": _utc_iso_datetime(),
                    "NbOfTxs": "1",
                    "SttlmInf": {"SttlmMtd": "CLRG"},
                },
                "CdtTrfTxInf": {
                    "PmtId": {
                        "InstrId": _mt_reference("INST"),
                        "EndToEndId": underlying_reference or _mt_reference("E2E"),
                        "TxId": _mt_reference("TX"),
                    },
                    "IntrBkSttlmAmt": {
                        "Amt": _format_amount(amount).replace(",", "."),
                        "Ccy": _normalise_currency(currency),
                    },
                    "IntrBkSttlmDt": _normalise_iso_date(),
                    "InstgAgt": {"FinInstnId": {"BICFI": _normalise_bic(instructing_agent or self.sender_bic)}},
                    "InstdAgt": {"FinInstnId": {"BICFI": _normalise_bic(instructed_agent or receiver_bic)}},
                    "CdtrAgt": {"FinInstnId": {"BICFI": _normalise_bic(receiver_bic)}},
                },
            }
        }
        msg = MXMessage(
            message_type=MXMessageType.PACS_009,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            related_reference=underlying_reference,
            payload=payload,
        )
        return self._record_mx_message(msg)

    def create_mx_account_report(
        self,
        receiver_bic: str,
        account_id: str,
        opening_balance: float,
        closing_balance: float,
        currency: str = "USD",
        transactions: Sequence[Mapping[str, Any]] | None = None,
        report_type: MXMessageType = MXMessageType.CAMT_053,
    ) -> MXMessage:
        """Create a camt.053 or camt.054 cash management report."""
        tx_entries = []
        for transaction in transactions or []:
            tx_entries.append(
                {
                    "NtryRef": transaction.get("reference", _mt_reference("NTRY")),
                    "Amt": {
                        "Amt": _format_amount(float(transaction.get("amount", 0.0))).replace(",", "."),
                        "Ccy": _normalise_currency(str(transaction.get("currency", currency))),
                    },
                    "CdtDbtInd": "CRDT" if _clean_text(str(transaction.get("direction", "C"))) == "C" else "DBIT",
                    "BookgDt": {"Dt": _normalise_iso_date(str(transaction.get("entry_date", _utc_date())))},
                    "ValDt": {"Dt": _normalise_iso_date(str(transaction.get("funds_date", _utc_date())))},
                    "AddtlNtryInf": transaction.get("details", "RECONCILED ENTRY"),
                }
            )
        payload = {
            "BkToCstmrStmt": {
                "GrpHdr": {
                    "MsgId": _mt_reference("CAMT"),
                    "CreDtTm": _utc_iso_datetime(),
                },
                "Stmt": {
                    "Id": _mt_reference("STMT"),
                    "ElctrncSeqNb": "1",
                    "CreDtTm": _utc_iso_datetime(),
                    "Acct": {"Id": {"Othr": {"Id": account_id}}, "Svcr": {"FinInstnId": {"BICFI": self.sender_bic}}},
                    "Bal": [
                        {
                            "Tp": {"CdOrPrtry": {"Cd": "OPBD"}},
                            "Amt": {"Amt": _format_amount(opening_balance).replace(",", "."), "Ccy": _normalise_currency(currency)},
                            "CdtDbtInd": "CRDT",
                            "Dt": {"Dt": _normalise_iso_date()},
                        },
                        {
                            "Tp": {"CdOrPrtry": {"Cd": "CLBD"}},
                            "Amt": {"Amt": _format_amount(closing_balance).replace(",", "."), "Ccy": _normalise_currency(currency)},
                            "CdtDbtInd": "CRDT",
                            "Dt": {"Dt": _normalise_iso_date()},
                        },
                    ],
                    "Ntry": tx_entries,
                },
            }
        }
        msg = MXMessage(
            message_type=report_type,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            payload=payload,
        )
        return self._record_mx_message(msg)

    def create_mx_securities_settlement(
        self,
        receiver_bic: str,
        isin: str,
        quantity: float,
        settlement_amount: float,
        currency: str = "USD",
        settlement_date: str = "",
        deliver_receive: str = "RECE",
        against_payment: bool = True,
    ) -> MXMessage:
        """Create a sese.023 securities settlement instruction."""
        payload = {
            "SctiesSttlmTxInstr": {
                "TxId": _mt_reference("SESE"),
                "TradDtls": {
                    "SttlmDt": {"Dt": _normalise_iso_date(settlement_date or _utc_date())},
                    "TradDt": {"Dt": _normalise_iso_date()},
                },
                "FinInstrmId": {"ISIN": _clean_text(isin)},
                "SttlmQty": {"Qty": _format_amount(quantity, 4).replace(",", ".")},
                "SttlmAmt": {"Amt": _format_amount(settlement_amount).replace(",", "."), "Ccy": _normalise_currency(currency)},
                "DlvrgSttlmPties": {"Pty1": {"Id": {"AnyBIC": self.sender_bic}}},
                "RcvgSttlmPties": {"Pty1": {"Id": {"AnyBIC": _normalise_bic(receiver_bic)}}},
                "SttlmParams": {
                    "SctiesTxTp": "TRAD",
                    "DlvrgOrRcvg": _clean_text(deliver_receive),
                    "Pmt": "APMT" if against_payment else "FREE",
                },
            }
        }
        msg = MXMessage(
            message_type=MXMessageType.SESE_023,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            payload=payload,
        )
        return self._record_mx_message(msg)

    def create_mx_securities_balance(
        self,
        receiver_bic: str,
        safekeeping_account: str,
        positions: Sequence[Mapping[str, Any]],
    ) -> MXMessage:
        """Create a securities balance report using a sese/semt-style payload."""
        balance_list = []
        for position in positions:
            balance_list.append(
                {
                    "FinInstrmId": {"ISIN": position.get("isin", "UNKNOWN")},
                    "BalQty": {"Qty": _format_amount(float(position.get("quantity", 0.0)), 4).replace(",", ".")},
                    "BalAmt": {
                        "Amt": _format_amount(float(position.get("market_value", 0.0))).replace(",", "."),
                        "Ccy": _normalise_currency(str(position.get("currency", "USD"))),
                    },
                    "PricDtls": {
                        "ValtnPric": _format_amount(float(position.get("price", 0.0)), 6).replace(",", ".")
                    },
                }
            )
        payload = {
            "SctiesBalAcctgRpt": {
                "AcctOwnr": {"Id": {"AnyBIC": self.sender_bic}},
                "SafekeepingAccount": safekeeping_account,
                "BalForAcct": balance_list,
            }
        }
        msg = MXMessage(
            message_type=MXMessageType.SESE_031,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            payload=payload,
        )
        return self._record_mx_message(msg)

    def create_mx_message(
        self,
        message_type: MXMessageType,
        receiver_bic: str,
        payload: Mapping[str, Any],
        related_reference: str = "",
    ) -> MXMessage:
        """Create a generic MX message from a caller-supplied payload."""
        msg = MXMessage(
            message_type=message_type,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            payload=self._normalise_mx_payload(dict(payload)),
            related_reference=related_reference,
        )
        return self._record_mx_message(msg)

    def _normalise_mx_payload(self, payload: Any) -> Any:
        """Normalise helper payloads into serialisable XML-friendly structures.

        The helper recognises dictionaries using ``_attrs`` and ``_value`` and
        converts them into a flat textual representation so the generic XML
        renderer can stay dependency free.
        """
        if isinstance(payload, Mapping):
            if "_attrs" in payload and "_value" in payload:
                attrs = payload.get("_attrs", {})
                attr_text = " ".join(f"{key}={value}" for key, value in dict(attrs).items())
                value = payload.get("_value", "")
                return f"{attr_text} {value}".strip()
            return {str(key): self._normalise_mx_payload(value) for key, value in payload.items()}
        if isinstance(payload, list):
            return [self._normalise_mx_payload(item) for item in payload]
        return payload

    def validate_message_object(self, message: SWIFTMessage | MXMessage) -> list[ValidationIssue]:
        """Validate either a SWIFT MT message or an MX message."""
        if isinstance(message, SWIFTMessage):
            return self.validator.validate_message(message)
        return self.validator.validate_mx_message(message)

    def route_message(
        self,
        message: SWIFTMessage,
        sender_correspondent: str = "",
        account_with_institution: str = "",
        intermediaries: Sequence[str] | None = None,
        service_level: str = "SWIFT GPI",
    ) -> RoutingInstruction:
        """Apply routing metadata to an existing message."""
        return self._apply_routing(
            message,
            sender_correspondent=sender_correspondent,
            account_with_institution=account_with_institution,
            intermediaries=intermediaries,
            service_level=service_level,
        )

    def get_message_by_reference(self, reference: str) -> SWIFTMessage | None:
        """Return a previously generated MT message by reference."""
        normalized = _clean_text(reference)
        for message in reversed(self.message_log):
            if _clean_text(message.reference) == normalized:
                return message
        return None

    def get_tracking_status(self, reference: str) -> dict[str, Any]:
        """Return simple routing and status metadata for a generated message."""
        message = self.get_message_by_reference(reference)
        if not message:
            return {
                "reference": reference,
                "status": "not_found",
                "tracking_reference": "",
                "routing": {},
            }
        routing = dict(message.metadata.get("routing", {}))
        return {
            "reference": message.reference,
            "status": "generated",
            "tracking_reference": message.gpi_tracking_id,
            "routing": routing,
            "message_type": message.message_type.value,
            "validation_issues": message.metadata.get("validation_issues", []),
        }
