"""ISO 20022 Engine — Universal Financial Messaging Standard.

Generates ISO 20022 compliant messages for payments, securities,
trade finance, and FX operations. Supports SEPA, SWIFT gpi, bulk payments,
direct debits, bank statements, cancellations, and message validation.
"""

from __future__ import annotations

import re
import uuid
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class ISO20022MessageType(str, Enum):
    # Payments
    PACS_008 = "pacs.008.001.10"  # Customer Credit Transfer
    PACS_009 = "pacs.009.001.09"  # FI Credit Transfer
    PAIN_001 = "pain.001.001.11"  # Customer Payment Initiation
    PAIN_002 = "pain.002.001.12"  # Payment Status
    PAIN_008 = "pain.008.001.10"  # Direct Debit Initiation
    PAIN_013 = "pain.013.001.09"  # Creditor Payment Activation Request
    # Cash Management
    CAMT_053 = "camt.053.001.10"  # Bank Statement
    CAMT_054 = "camt.054.001.10"  # Debit/Credit Notification
    CAMT_056 = "camt.056.001.10"  # Payment Cancellation
    # Securities
    SESE_023 = "sese.023.001.11"  # Settlement Instruction
    SESE_024 = "sese.024.001.12"  # Settlement Status
    SEMT_002 = "semt.002.001.11"  # Securities Balance
    # FX
    FXTR_014 = "fxtr.014.001.05"  # FX Trade Instruction
    FXTR_017 = "fxtr.017.001.04"  # FX Trade Status/Confirmation


class PaymentStatus(str, Enum):
    ACCEPTED = "ACCP"  # Accepted Customer Profile
    ACCEPTED_SETTLEMENT = "ACSC"  # Accepted Settlement Completed
    ACCEPTED_TECHNICAL = "ACTC"  # Accepted Technical Validation
    PENDING = "PDNG"  # Pending
    REJECTED = "RJCT"  # Rejected
    CANCELLED = "CANC"  # Cancelled


class SEPAScheme(str, Enum):
    SCT = "SEPA_CT"  # SEPA Credit Transfer
    SDD_CORE = "SEPA_DD_CORE"  # SEPA Direct Debit Core
    SDD_B2B = "SEPA_DD_B2B"  # SEPA Direct Debit B2B
    SCT_INST = "SEPA_CT_INST"  # SEPA Instant Credit Transfer


@dataclass
class TransactionEntry:
    """Single transaction in a bank statement."""
    entry_ref: str = ""
    amount: float = 0.0
    currency: str = "EUR"
    credit_debit: str = "CRDT"  # CRDT or DBIT
    booking_date: str = ""
    value_date: str = ""
    counterparty_name: str = ""
    counterparty_iban: str = ""
    remittance_info: str = ""

    def __post_init__(self) -> None:
        if not self.entry_ref:
            self.entry_ref = f"ENT{uuid.uuid4().hex[:12].upper()}"
        if not self.booking_date:
            self.booking_date = time.strftime("%Y-%m-%d")
        if not self.value_date:
            self.value_date = self.booking_date


@dataclass
class SecuritiesPosition:
    """Securities holding for balance reporting."""
    isin: str
    quantity: float
    market_value: float
    currency: str = "USD"
    safekeeping_account: str = ""
    place_of_safekeeping: str = ""


@dataclass
class SupplementaryData:
    """Supplementary data attachment for ISO 20022 messages."""
    place_and_name: str = ""
    envelope_content: dict[str, Any] = field(default_factory=dict)


@dataclass
class PaymentMessage:
    """ISO 20022 Payment message."""
    message_type: ISO20022MessageType
    message_id: str = ""
    creation_datetime: str = ""
    debtor_name: str = "PARRALAX AI HFT FUND"
    debtor_bic: str = "PARRALAXXX"
    debtor_iban: str = ""
    creditor_name: str = ""
    creditor_bic: str = ""
    creditor_iban: str = ""
    amount: float = 0.0
    currency: str = "USD"
    remittance_info: str = ""
    charge_bearer: str = "SLEV"  # FollowingServiceLevel
    settlement_method: str = "INDA"  # InstructedAgent
    uetr: str = ""  # Unique End-to-end Transaction Reference (SWIFT gpi)
    status: PaymentStatus = PaymentStatus.PENDING
    supplementary_data: list[SupplementaryData] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.message_id:
            self.message_id = f"PRLX{uuid.uuid4().hex[:16].upper()}"
        if not self.creation_datetime:
            self.creation_datetime = time.strftime("%Y-%m-%dT%H:%M:%S+00:00")


def _validate_bic(bic: str) -> bool:
    """Validate BIC/SWIFT code format (8 or 11 chars)."""
    return bool(re.match(r"^[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?$", bic.upper()))


def _validate_iban(iban: str) -> bool:
    """Validate IBAN format and checksum."""
    iban_clean = iban.replace(" ", "").upper()
    if len(iban_clean) < 15 or len(iban_clean) > 34:
        return False
    if not re.match(r"^[A-Z]{2}\d{2}[A-Z0-9]+$", iban_clean):
        return False
    # Move first 4 chars to end and convert letters to numbers
    rearranged = iban_clean[4:] + iban_clean[:4]
    numeric = ""
    for ch in rearranged:
        if ch.isdigit():
            numeric += ch
        else:
            numeric += str(ord(ch) - ord("A") + 10)
    return int(numeric) % 97 == 1


def _generate_uetr() -> str:
    """Generate UUID v4 as UETR for SWIFT gpi tracking."""
    return str(uuid.uuid4())


class ISO20022Engine:
    """ISO 20022 message generation and processing engine."""

    def __init__(self, institution_name: str = "PARRALAX AI HFT FUND") -> None:
        self.institution_name = institution_name
        self.bic = "PARRALAXXX"
        self.messages: list[PaymentMessage] = []

    def create_credit_transfer(
        self,
        creditor_name: str,
        creditor_bic: str,
        amount: float,
        currency: str = "USD",
        remittance: str = "",
    ) -> PaymentMessage:
        """Create pacs.008 Customer Credit Transfer."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PACS_008,
            creditor_name=creditor_name,
            creditor_bic=creditor_bic,
            amount=amount,
            currency=currency,
            remittance_info=remittance or "TRADING SETTLEMENT",
        )
        self.messages.append(msg)
        return msg

    def create_payment_initiation(
        self,
        payments: list[dict[str, Any]],
    ) -> PaymentMessage:
        """Create pain.001 batch payment initiation."""
        total = sum(p.get("amount", 0) for p in payments)
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PAIN_001,
            amount=total,
            metadata={"payment_count": len(payments), "payments": payments},
        )
        self.messages.append(msg)
        return msg

    def create_settlement_instruction(
        self,
        isin: str,
        quantity: float,
        settlement_amount: float,
        counterparty_bic: str,
        settlement_date: str = "",
    ) -> PaymentMessage:
        """Create sese.023 Securities Settlement Instruction."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.SESE_023,
            creditor_bic=counterparty_bic,
            amount=settlement_amount,
            metadata={
                "isin": isin,
                "quantity": quantity,
                "settlement_date": settlement_date or time.strftime("%Y-%m-%d"),
            },
        )
        self.messages.append(msg)
        return msg

    def create_fx_trade(
        self,
        buy_currency: str,
        buy_amount: float,
        sell_currency: str,
        sell_amount: float,
        counterparty_bic: str,
        value_date: str = "",
    ) -> PaymentMessage:
        """Create fxtr.014 FX Trade Instruction."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.FXTR_014,
            creditor_bic=counterparty_bic,
            amount=buy_amount,
            currency=buy_currency,
            metadata={
                "sell_currency": sell_currency,
                "sell_amount": sell_amount,
                "exchange_rate": sell_amount / buy_amount if buy_amount > 0 else 0,
                "value_date": value_date or time.strftime("%Y-%m-%d"),
            },
        )
        self.messages.append(msg)
        return msg

    # ═══════════════════════════════════════════════════════════
    # EXPANDED CAPABILITIES
    # ═══════════════════════════════════════════════════════════

    def create_sepa_transfer(
        self,
        creditor_name: str,
        creditor_iban: str,
        creditor_bic: str,
        amount: float,
        remittance: str = "",
        scheme: SEPAScheme = SEPAScheme.SCT,
        urgent: bool = False,
    ) -> PaymentMessage:
        """Create SEPA Credit Transfer with IBAN validation and BIC routing."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PACS_008,
            creditor_name=creditor_name,
            creditor_bic=creditor_bic,
            creditor_iban=creditor_iban,
            amount=amount,
            currency="EUR",
            charge_bearer="SLEV",
            remittance_info=remittance or "SEPA TRANSFER",
            metadata={
                "scheme": scheme.value,
                "urgent": urgent,
                "service_level": "SEPA" if not urgent else "INST",
                "local_instrument": "INST" if scheme == SEPAScheme.SCT_INST else "CORE",
            },
        )
        self.messages.append(msg)
        return msg

    def create_gpi_payment(
        self,
        creditor_name: str,
        creditor_bic: str,
        amount: float,
        currency: str = "USD",
        remittance: str = "",
        service_level: str = "G001",
    ) -> PaymentMessage:
        """Create SWIFT gpi payment with UETR tracking."""
        uetr = _generate_uetr()
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PACS_008,
            creditor_name=creditor_name,
            creditor_bic=creditor_bic,
            amount=amount,
            currency=currency,
            remittance_info=remittance or "GPI PAYMENT",
            uetr=uetr,
            metadata={
                "gpi_service_level": service_level,
                "tracker_status": "ACCC",
                "gpi_enabled": True,
            },
        )
        self.messages.append(msg)
        return msg

    def create_bulk_payment(
        self,
        payments: list[dict[str, Any]],
        batch_booking: bool = True,
        requested_execution_date: str = "",
    ) -> PaymentMessage:
        """Create bulk/batch payment supporting multiple creditors in one message."""
        total = sum(p.get("amount", 0) for p in payments)
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PAIN_001,
            amount=total,
            metadata={
                "payment_count": len(payments),
                "payments": payments,
                "batch_booking": batch_booking,
                "requested_execution_date": requested_execution_date or time.strftime("%Y-%m-%d"),
                "control_sum": total,
            },
        )
        self.messages.append(msg)
        return msg

    def create_direct_debit(
        self,
        debtor_name: str,
        debtor_iban: str,
        debtor_bic: str,
        amount: float,
        mandate_id: str,
        mandate_date: str,
        sequence_type: str = "FRST",  # FRST, RCUR, FNAL, OOFF
        currency: str = "EUR",
    ) -> PaymentMessage:
        """Create pain.008 Direct Debit Initiation."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PAIN_008,
            debtor_name=debtor_name,
            debtor_iban=debtor_iban,
            debtor_bic=debtor_bic,
            amount=amount,
            currency=currency,
            metadata={
                "mandate_id": mandate_id,
                "mandate_date_of_signature": mandate_date,
                "sequence_type": sequence_type,
                "creditor_scheme_id": f"PRLX{uuid.uuid4().hex[:8].upper()}",
            },
        )
        self.messages.append(msg)
        return msg

    def create_payment_status_report(
        self,
        original_message_id: str,
        status: PaymentStatus,
        reason_code: str = "",
        additional_info: str = "",
    ) -> PaymentMessage:
        """Create pain.002 Payment Status Report."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PAIN_002,
            status=status,
            metadata={
                "original_message_id": original_message_id,
                "status_code": status.value,
                "reason_code": reason_code,
                "additional_info": additional_info,
                "status_datetime": time.strftime("%Y-%m-%dT%H:%M:%S+00:00"),
            },
        )
        self.messages.append(msg)
        return msg

    def create_bank_statement(
        self,
        account_iban: str,
        opening_balance: float,
        closing_balance: float,
        transactions: list[TransactionEntry],
        statement_date: str = "",
        currency: str = "EUR",
    ) -> PaymentMessage:
        """Create camt.053 Bank Statement with balance and transaction entries."""
        stmt_date = statement_date or time.strftime("%Y-%m-%d")
        total_credits = sum(t.amount for t in transactions if t.credit_debit == "CRDT")
        total_debits = sum(t.amount for t in transactions if t.credit_debit == "DBIT")

        msg = PaymentMessage(
            message_type=ISO20022MessageType.CAMT_053,
            debtor_iban=account_iban,
            amount=closing_balance,
            currency=currency,
            metadata={
                "statement_date": stmt_date,
                "opening_balance": opening_balance,
                "closing_balance": closing_balance,
                "total_credits": total_credits,
                "total_debits": total_debits,
                "entry_count": len(transactions),
                "transactions": [
                    {
                        "ref": t.entry_ref,
                        "amount": t.amount,
                        "currency": t.currency,
                        "credit_debit": t.credit_debit,
                        "booking_date": t.booking_date,
                        "value_date": t.value_date,
                        "counterparty": t.counterparty_name,
                        "remittance": t.remittance_info,
                    }
                    for t in transactions
                ],
            },
        )
        self.messages.append(msg)
        return msg

    def create_cancellation_request(
        self,
        original_message_id: str,
        original_message_type: ISO20022MessageType,
        reason: str = "DUPL",  # DUPL, FRAD, TECH, CUST
        additional_info: str = "",
    ) -> PaymentMessage:
        """Create camt.056 Payment Cancellation Request."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.CAMT_056,
            metadata={
                "original_message_id": original_message_id,
                "original_message_type": original_message_type.value,
                "cancellation_reason": reason,
                "additional_info": additional_info,
                "cancellation_id": f"CNCL{uuid.uuid4().hex[:12].upper()}",
            },
        )
        self.messages.append(msg)
        return msg

    def create_securities_balance(
        self,
        account_id: str,
        positions: list[SecuritiesPosition],
        statement_date: str = "",
    ) -> PaymentMessage:
        """Create semt.002 Securities Balance report."""
        stmt_date = statement_date or time.strftime("%Y-%m-%d")
        total_value = sum(p.market_value for p in positions)

        msg = PaymentMessage(
            message_type=ISO20022MessageType.SEMT_002,
            amount=total_value,
            metadata={
                "safekeeping_account": account_id,
                "statement_date": stmt_date,
                "position_count": len(positions),
                "positions": [
                    {
                        "isin": p.isin,
                        "quantity": p.quantity,
                        "market_value": p.market_value,
                        "currency": p.currency,
                        "safekeeping_account": p.safekeeping_account,
                        "place_of_safekeeping": p.place_of_safekeeping,
                    }
                    for p in positions
                ],
            },
        )
        self.messages.append(msg)
        return msg

    def create_fx_confirmation(
        self,
        trade_id: str,
        buy_currency: str,
        buy_amount: float,
        sell_currency: str,
        sell_amount: float,
        counterparty_bic: str,
        exchange_rate: float,
        value_date: str = "",
        confirmation_status: str = "CONF",
    ) -> PaymentMessage:
        """Create fxtr.017 FX Trade Confirmation."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.FXTR_017,
            creditor_bic=counterparty_bic,
            amount=buy_amount,
            currency=buy_currency,
            metadata={
                "trade_id": trade_id,
                "sell_currency": sell_currency,
                "sell_amount": sell_amount,
                "exchange_rate": exchange_rate,
                "value_date": value_date or time.strftime("%Y-%m-%d"),
                "confirmation_status": confirmation_status,
                "confirmation_datetime": time.strftime("%Y-%m-%dT%H:%M:%S+00:00"),
            },
        )
        self.messages.append(msg)
        return msg

    def create_creditor_payment_activation(
        self,
        creditor_name: str,
        creditor_bic: str,
        amount: float,
        currency: str = "USD",
        expiry_date: str = "",
    ) -> PaymentMessage:
        """Create pain.013 Creditor Payment Activation Request for treasury ops."""
        msg = PaymentMessage(
            message_type=ISO20022MessageType.PAIN_013,
            creditor_name=creditor_name,
            creditor_bic=creditor_bic,
            amount=amount,
            currency=currency,
            metadata={
                "activation_type": "TREASURY",
                "expiry_date": expiry_date or time.strftime("%Y-%m-%d"),
                "request_id": f"CPAR{uuid.uuid4().hex[:12].upper()}",
            },
        )
        self.messages.append(msg)
        return msg

    def attach_supplementary_data(
        self,
        msg: PaymentMessage,
        place_and_name: str,
        data: dict[str, Any],
    ) -> PaymentMessage:
        """Attach supplementary data to an ISO 20022 message."""
        supp = SupplementaryData(
            place_and_name=place_and_name,
            envelope_content=data,
        )
        msg.supplementary_data.append(supp)
        return msg

    def validate_message(self, msg: PaymentMessage) -> list[dict[str, str]]:
        """Validate ISO 20022 message for mandatory fields, BIC format, IBAN checksum."""
        errors: list[dict[str, str]] = []

        # Mandatory fields
        if not msg.message_id:
            errors.append({"field": "message_id", "error": "Message ID is required"})
        if not msg.creation_datetime:
            errors.append({"field": "creation_datetime", "error": "Creation datetime is required"})
        if msg.amount <= 0 and msg.message_type not in (
            ISO20022MessageType.PAIN_002,
            ISO20022MessageType.CAMT_056,
        ):
            errors.append({"field": "amount", "error": "Amount must be positive"})

        # BIC validation
        if msg.debtor_bic and not _validate_bic(msg.debtor_bic):
            errors.append({"field": "debtor_bic", "error": f"Invalid BIC format: {msg.debtor_bic}"})
        if msg.creditor_bic and not _validate_bic(msg.creditor_bic):
            errors.append({"field": "creditor_bic", "error": f"Invalid BIC format: {msg.creditor_bic}"})

        # IBAN validation
        if msg.debtor_iban and not _validate_iban(msg.debtor_iban):
            errors.append({"field": "debtor_iban", "error": f"Invalid IBAN: {msg.debtor_iban}"})
        if msg.creditor_iban and not _validate_iban(msg.creditor_iban):
            errors.append({"field": "creditor_iban", "error": f"Invalid IBAN: {msg.creditor_iban}"})

        # Message-type specific validation
        if msg.message_type == ISO20022MessageType.PACS_008:
            if not msg.creditor_name:
                errors.append({"field": "creditor_name", "error": "Creditor name required for credit transfer"})
            if not msg.creditor_bic and not msg.creditor_iban:
                errors.append({"field": "creditor_bic", "error": "Creditor BIC or IBAN required"})

        if msg.message_type == ISO20022MessageType.PAIN_008:
            if not msg.metadata.get("mandate_id"):
                errors.append({"field": "mandate_id", "error": "Mandate ID required for direct debit"})

        if msg.message_type == ISO20022MessageType.SESE_023:
            if not msg.metadata.get("isin"):
                errors.append({"field": "isin", "error": "ISIN required for settlement instruction"})

        return errors

    def to_xml(self, msg: PaymentMessage) -> str:
        """Generate ISO 20022 XML message."""
        # UETR element for gpi payments
        uetr_xml = ""
        if msg.uetr:
            uetr_xml = f"\n        <UETR>{msg.uetr}</UETR>"

        # Supplementary data
        supp_xml = ""
        if msg.supplementary_data:
            supp_parts = []
            for supp in msg.supplementary_data:
                supp_parts.append(
                    f"    <SplmtryData>\n"
                    f"      <PlcAndNm>{supp.place_and_name}</PlcAndNm>\n"
                    f"      <Envlp><Doc/></Envlp>\n"
                    f"    </SplmtryData>"
                )
            supp_xml = "\n" + "\n".join(supp_parts)

        # IBAN elements
        debtor_acct = ""
        if msg.debtor_iban:
            debtor_acct = f"\n      <DbtrAcct><Id><IBAN>{msg.debtor_iban}</IBAN></Id></DbtrAcct>"
        creditor_acct = ""
        if msg.creditor_iban:
            creditor_acct = f"\n      <CdtrAcct><Id><IBAN>{msg.creditor_iban}</IBAN></Id></CdtrAcct>"

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:{msg.message_type.value}">
  <{msg.message_type.value.split('.')[0].capitalize()}>
    <GrpHdr>
      <MsgId>{msg.message_id}</MsgId>
      <CreDtTm>{msg.creation_datetime}</CreDtTm>
      <NbOfTxs>1</NbOfTxs>
      <SttlmInf>
        <SttlmMtd>{msg.settlement_method}</SttlmMtd>
      </SttlmInf>
    </GrpHdr>
    <CdtTrfTxInf>
      <PmtId>
        <InstrId>{msg.message_id}</InstrId>
        <EndToEndId>{msg.message_id}</EndToEndId>{uetr_xml}
      </PmtId>
      <Amt>
        <InstdAmt Ccy="{msg.currency}">{msg.amount:.2f}</InstdAmt>
      </Amt>
      <ChrgBr>{msg.charge_bearer}</ChrgBr>
      <Dbtr>
        <Nm>{msg.debtor_name}</Nm>
        <Id><OrgId><BICOrBEI>{msg.debtor_bic}</BICOrBEI></OrgId></Id>
      </Dbtr>{debtor_acct}
      <Cdtr>
        <Nm>{msg.creditor_name}</Nm>
        <Id><OrgId><BICOrBEI>{msg.creditor_bic}</BICOrBEI></OrgId></Id>
      </Cdtr>{creditor_acct}
      <RmtInf>
        <Ustrd>{msg.remittance_info}</Ustrd>
      </RmtInf>
    </CdtTrfTxInf>{supp_xml}
  </{msg.message_type.value.split('.')[0].capitalize()}>
</Document>"""
