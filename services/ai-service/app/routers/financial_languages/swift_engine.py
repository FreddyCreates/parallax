"""SWIFT Message Engine — MT/MX financial messaging.

Generates and parses SWIFT messages for settlements, payments,
and inter-bank communications.
"""

from __future__ import annotations

import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class SWIFTMessageType(str, Enum):
    """Common SWIFT MT message types."""
    MT103 = "103"  # Single Customer Credit Transfer
    MT202 = "202"  # General Financial Institution Transfer
    MT300 = "300"  # FX Confirmation
    MT320 = "320"  # Fixed Loan/Deposit Confirmation
    MT502 = "502"  # Order to Buy or Sell
    MT515 = "515"  # Client Confirmation of Purchase or Sale
    MT535 = "535"  # Statement of Holdings
    MT536 = "536"  # Statement of Transactions
    MT540 = "540"  # Receive Free
    MT541 = "541"  # Receive Against Payment
    MT542 = "542"  # Deliver Free
    MT543 = "543"  # Deliver Against Payment
    MT900 = "900"  # Confirmation of Debit
    MT910 = "910"  # Confirmation of Credit
    MT940 = "940"  # Customer Statement
    MT950 = "950"  # Statement Message


class MXMessageType(str, Enum):
    """SWIFT MX (ISO 20022) message types."""
    PACS_008 = "pacs.008"  # FI to FI Customer Credit Transfer
    PACS_009 = "pacs.009"  # FI to FI Financial Institution Credit Transfer
    CAMT_053 = "camt.053"  # Bank to Customer Statement
    CAMT_054 = "camt.054"  # Bank to Customer Debit/Credit Notification
    SESE_023 = "sese.023"  # Securities Settlement Transaction Instruction
    SETR_010 = "setr.010"  # Subscription Order


@dataclass
class SWIFTMessage:
    """SWIFT message representation."""
    message_type: SWIFTMessageType
    sender_bic: str = "PARRALAXXX"
    receiver_bic: str = ""
    reference: str = ""
    fields: dict[str, str] = field(default_factory=dict)
    amount: float = 0.0
    currency: str = "USD"
    value_date: str = ""
    narrative: str = ""

    def __post_init__(self) -> None:
        if not self.reference:
            self.reference = f"PRLX{int(time.time())}"
        if not self.value_date:
            self.value_date = time.strftime("%Y%m%d")

    def to_mt_format(self) -> str:
        """Generate MT message format."""
        lines = [
            f"{{1:F01{self.sender_bic}0000000000}}",
            f"{{2:O{self.message_type.value}{time.strftime('%H%M')}{self.receiver_bic}}}",
            "{3:{108:" + self.reference + "}}",
            "{4:",
            f":20:{self.reference}",
        ]

        if self.message_type == SWIFTMessageType.MT103:
            lines.extend([
                f":23B:CRED",
                f":32A:{self.value_date}{self.currency}{self.amount:.2f}",
                f":50K:/{self.sender_bic}",
                f"PARRALAX AI HFT FUND",
                f":59:/{self.receiver_bic}",
                f":71A:SHA",
            ])
        elif self.message_type == SWIFTMessageType.MT202:
            lines.extend([
                f":32A:{self.value_date}{self.currency}{self.amount:.2f}",
                f":52A:{self.sender_bic}",
                f":58A:{self.receiver_bic}",
            ])
        elif self.message_type == SWIFTMessageType.MT502:
            lines.extend([
                f":23G:NEWM",
                f":98A::PREP//{self.value_date}",
                f":22F::TRTR//TRAD",
                f":36B::SETT//UNIT/{self.amount:.2f}",
            ])

        # Add custom fields
        for tag, value in self.fields.items():
            lines.append(f":{tag}:{value}")

        if self.narrative:
            lines.append(f":72:{self.narrative}")

        lines.append("-}")
        return "\n".join(lines)


class SWIFTEngine:
    """SWIFT message generation engine for fund operations."""

    def __init__(self, sender_bic: str = "PARRALAXXX") -> None:
        self.sender_bic = sender_bic
        self.message_log: list[SWIFTMessage] = []

    def create_payment(
        self,
        receiver_bic: str,
        amount: float,
        currency: str = "USD",
        narrative: str = "",
    ) -> SWIFTMessage:
        """Create MT103 payment message."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT103,
            sender_bic=self.sender_bic,
            receiver_bic=receiver_bic,
            amount=amount,
            currency=currency,
            narrative=narrative or "PARRALAX HFT FUND SETTLEMENT",
        )
        self.message_log.append(msg)
        return msg

    def create_fx_confirmation(
        self,
        counterparty_bic: str,
        buy_currency: str,
        buy_amount: float,
        sell_currency: str,
        sell_amount: float,
        value_date: str = "",
    ) -> SWIFTMessage:
        """Create MT300 FX confirmation."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT300,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=buy_amount,
            currency=buy_currency,
            value_date=value_date or time.strftime("%Y%m%d"),
        )
        msg.fields["30T"] = msg.value_date  # Trade Date
        msg.fields["30V"] = msg.value_date  # Value Date
        msg.fields["32B"] = f"{buy_currency}{buy_amount:.2f}"  # Amount Bought
        msg.fields["33B"] = f"{sell_currency}{sell_amount:.2f}"  # Amount Sold
        msg.fields["36"] = f"{sell_amount / buy_amount:.6f}"  # Exchange Rate
        self.message_log.append(msg)
        return msg

    def create_securities_order(
        self,
        broker_bic: str,
        isin: str,
        quantity: float,
        side: str = "BUY",
        price: float = 0.0,
    ) -> SWIFTMessage:
        """Create MT502 order to buy/sell."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT502,
            sender_bic=self.sender_bic,
            receiver_bic=broker_bic,
            amount=quantity,
        )
        msg.fields["35B"] = f"ISIN {isin}"  # Identification of Security
        msg.fields["22H"] = f"BUSE//{side}"  # Buy/Sell Indicator
        if price > 0:
            msg.fields["90A"] = f"DEAL//PRCT/{price:.4f}"  # Deal Price
        self.message_log.append(msg)
        return msg

    def create_settlement_instruction(
        self,
        counterparty_bic: str,
        isin: str,
        quantity: float,
        amount: float,
        currency: str = "USD",
    ) -> SWIFTMessage:
        """Create MT541 Receive Against Payment."""
        msg = SWIFTMessage(
            message_type=SWIFTMessageType.MT541,
            sender_bic=self.sender_bic,
            receiver_bic=counterparty_bic,
            amount=quantity,
            currency=currency,
        )
        msg.fields["35B"] = f"ISIN {isin}"
        msg.fields["36B"] = f"SETT//UNIT/{quantity:.2f}"
        msg.fields["19A"] = f"SETT//{currency}{amount:.2f}"
        self.message_log.append(msg)
        return msg
