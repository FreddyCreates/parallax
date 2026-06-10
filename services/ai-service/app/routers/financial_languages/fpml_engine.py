"""FpML Engine — Financial products Markup Language.

Handles OTC derivative trade representations, confirmations,
and lifecycle events per FpML 5.x standards.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import date, datetime
from enum import Enum
from typing import Any


class ProductType(str, Enum):
    INTEREST_RATE_SWAP = "ird:swap"
    FX_FORWARD = "fx:forward"
    FX_OPTION = "fx:option"
    CREDIT_DEFAULT_SWAP = "cd:swap"
    EQUITY_OPTION = "eq:option"
    EQUITY_SWAP = "eq:swap"
    COMMODITY_SWAP = "com:swap"
    TOTAL_RETURN_SWAP = "eq:totalReturnSwap"
    VARIANCE_SWAP = "eq:varianceSwap"
    SWAPTION = "ird:swaption"


class DayCountFraction(str, Enum):
    ACT_360 = "ACT/360"
    ACT_365 = "ACT/365.FIXED"
    THIRTY_360 = "30/360"
    ACT_ACT = "ACT/ACT.ISDA"


@dataclass
class FpMLParty:
    party_id: str
    party_name: str
    role: str = "party"  # party, broker, clearer


@dataclass
class FpMLTrade:
    """FpML trade representation."""
    trade_id: str = ""
    product_type: ProductType = ProductType.INTEREST_RATE_SWAP
    trade_date: str = ""
    effective_date: str = ""
    termination_date: str = ""
    notional: float = 0.0
    currency: str = "USD"
    parties: list[FpMLParty] = field(default_factory=list)
    fixed_rate: float = 0.0
    floating_index: str = "USD-SOFR"
    day_count: DayCountFraction = DayCountFraction.ACT_360
    payment_frequency: str = "3M"
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if not self.trade_id:
            self.trade_id = f"PARRALAX-{uuid.uuid4().hex[:12].upper()}"
        if not self.trade_date:
            self.trade_date = date.today().isoformat()


class FpMLEngine:
    """FpML message generation and parsing engine."""

    def __init__(self) -> None:
        self.trades: dict[str, FpMLTrade] = {}
        self.namespace = "http://www.fpml.org/FpML-5/confirmation"

    def create_irs(
        self,
        notional: float,
        fixed_rate: float,
        floating_index: str = "USD-SOFR",
        tenor_years: int = 5,
        currency: str = "USD",
        payer: str = "PARRALAX",
        receiver: str = "COUNTERPARTY",
    ) -> FpMLTrade:
        """Create Interest Rate Swap trade."""
        today = date.today()
        trade = FpMLTrade(
            product_type=ProductType.INTEREST_RATE_SWAP,
            trade_date=today.isoformat(),
            effective_date=today.isoformat(),
            termination_date=date(today.year + tenor_years, today.month, today.day).isoformat(),
            notional=notional,
            currency=currency,
            fixed_rate=fixed_rate,
            floating_index=floating_index,
            parties=[
                FpMLParty(party_id=payer, party_name=payer, role="payer"),
                FpMLParty(party_id=receiver, party_name=receiver, role="receiver"),
            ],
        )
        self.trades[trade.trade_id] = trade
        return trade

    def create_cds(
        self,
        reference_entity: str,
        notional: float,
        spread_bps: float,
        tenor_years: int = 5,
        currency: str = "USD",
    ) -> FpMLTrade:
        """Create Credit Default Swap."""
        today = date.today()
        trade = FpMLTrade(
            product_type=ProductType.CREDIT_DEFAULT_SWAP,
            trade_date=today.isoformat(),
            effective_date=today.isoformat(),
            termination_date=date(today.year + tenor_years, today.month, today.day).isoformat(),
            notional=notional,
            currency=currency,
            fixed_rate=spread_bps / 10000.0,
            metadata={"reference_entity": reference_entity, "spread_bps": spread_bps},
        )
        self.trades[trade.trade_id] = trade
        return trade

    def create_fx_forward(
        self,
        buy_currency: str,
        sell_currency: str,
        buy_amount: float,
        forward_rate: float,
        value_date: str,
    ) -> FpMLTrade:
        """Create FX Forward trade."""
        trade = FpMLTrade(
            product_type=ProductType.FX_FORWARD,
            effective_date=value_date,
            termination_date=value_date,
            notional=buy_amount,
            currency=buy_currency,
            metadata={
                "sell_currency": sell_currency,
                "sell_amount": buy_amount * forward_rate,
                "forward_rate": forward_rate,
            },
        )
        self.trades[trade.trade_id] = trade
        return trade

    def create_variance_swap(
        self,
        underlying: str,
        notional_vega: float,
        strike_vol: float,
        observation_days: int = 252,
    ) -> FpMLTrade:
        """Create Variance Swap for volatility trading."""
        trade = FpMLTrade(
            product_type=ProductType.VARIANCE_SWAP,
            notional=notional_vega,
            metadata={
                "underlying": underlying,
                "strike_volatility": strike_vol,
                "variance_strike": strike_vol**2,
                "observation_days": observation_days,
                "vega_notional": notional_vega,
            },
        )
        self.trades[trade.trade_id] = trade
        return trade

    def to_xml(self, trade: FpMLTrade) -> str:
        """Generate FpML XML representation."""
        parties_xml = "\n".join(
            f'    <party id="{p.party_id}"><partyName>{p.party_name}</partyName></party>'
            for p in trade.parties
        )

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<FpML xmlns="{self.namespace}" version="5.12">
  <trade>
    <tradeHeader>
      <tradeIdentifier>
        <tradeId>{trade.trade_id}</tradeId>
      </tradeIdentifier>
      <tradeDate>{trade.trade_date}</tradeDate>
    </tradeHeader>
    <product type="{trade.product_type.value}">
      <notional>
        <currency>{trade.currency}</currency>
        <amount>{trade.notional}</amount>
      </notional>
      <effectiveDate>{trade.effective_date}</effectiveDate>
      <terminationDate>{trade.termination_date}</terminationDate>
      <fixedRate>{trade.fixed_rate}</fixedRate>
      <floatingRateIndex>{trade.floating_index}</floatingRateIndex>
      <dayCountFraction>{trade.day_count.value}</dayCountFraction>
    </product>
  </trade>
{parties_xml}
</FpML>"""
