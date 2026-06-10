"""ISO 20022 Engine — Universal Financial Messaging Standard.

Generates ISO 20022 compliant messages for payments, securities,
trade finance, and FX operations.
"""

from __future__ import annotations

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
    FXTR_017 = "fxtr.017.001.04"  # FX Trade Status


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
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.message_id:
            self.message_id = f"PRLX{uuid.uuid4().hex[:16].upper()}"
        if not self.creation_datetime:
            self.creation_datetime = time.strftime("%Y-%m-%dT%H:%M:%S+00:00")


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

    def to_xml(self, msg: PaymentMessage) -> str:
        """Generate ISO 20022 XML message."""
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
        <EndToEndId>{msg.message_id}</EndToEndId>
      </PmtId>
      <Amt>
        <InstdAmt Ccy="{msg.currency}">{msg.amount:.2f}</InstdAmt>
      </Amt>
      <ChrgBr>{msg.charge_bearer}</ChrgBr>
      <Dbtr>
        <Nm>{msg.debtor_name}</Nm>
        <Id><OrgId><BICOrBEI>{msg.debtor_bic}</BICOrBEI></OrgId></Id>
      </Dbtr>
      <Cdtr>
        <Nm>{msg.creditor_name}</Nm>
        <Id><OrgId><BICOrBEI>{msg.creditor_bic}</BICOrBEI></OrgId></Id>
      </Cdtr>
      <RmtInf>
        <Ustrd>{msg.remittance_info}</Ustrd>
      </RmtInf>
    </CdtTrfTxInf>
  </{msg.message_type.value.split('.')[0].capitalize()}>
</Document>"""
