#!/usr/bin/env python3
"""
PARALLAX SDK — Clearinghouse Netting Engine
=============================================
Implements multi-asset bilateral and multilateral netting for the
PARALLAX Central Counterparty (CCP) model.

The clearinghouse operates on netting cycles of F(6)=8 heartbeats (~7s).
Within each cycle, all pending obligations between counterparties are
netted down to minimal settlement flows.

Netting reduces gross obligations to net positions, dramatically
reducing settlement risk and the amount of capital required.
"""

import hashlib
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

from .constants import (
    PHI_INV,
    NETTING_CYCLE_BEATS,
    HEARTBEAT_MS,
    FIBONACCI,
)


class AssetType(Enum):
    """Supported asset types in the clearinghouse."""
    ICP = "ICP"
    CKBTC = "ckBTC"
    CKETH = "ckETH"
    SNS_TOKEN = "SNS"
    AI_TOKEN = "AI_TOKEN"
    ARTIFACT = "ARTIFACT"
    STABLECOIN = "STABLE"


@dataclass
class Obligation:
    """A single obligation between two counterparties."""
    obligation_id: str
    from_party: str
    to_party: str
    asset: AssetType
    amount: float
    timestamp_ns: int = field(default_factory=time.time_ns)
    settled: bool = False


@dataclass
class NetPosition:
    """Net position of a party in a given asset after netting."""
    party: str
    asset: AssetType
    net_amount: float  # Positive = receivable, Negative = payable
    gross_receivable: float
    gross_payable: float
    netting_ratio: float  # Reduction ratio (1.0 = fully netted)


@dataclass
class NettingResult:
    """Result of a netting cycle."""
    cycle_id: str
    timestamp_ns: int
    obligations_input: int
    obligations_netted: int
    net_positions: list[NetPosition]
    gross_total: float
    net_total: float
    netting_efficiency: float  # Percentage reduction
    receipt_hash: str


class ClearinghouseEngine:
    """
    Multi-Asset Clearinghouse Netting Engine.

    Collects obligations over a netting cycle and then performs
    multilateral netting to compute minimum settlement flows.

    Usage:
        engine = ClearinghouseEngine()

        # Add trades as obligations
        engine.add_obligation("alice", "bob", AssetType.ICP, 100.0)
        engine.add_obligation("bob", "alice", AssetType.ICP, 60.0)
        engine.add_obligation("bob", "charlie", AssetType.ICP, 30.0)
        engine.add_obligation("charlie", "alice", AssetType.ICP, 20.0)

        # Run netting
        result = engine.run_netting_cycle()
        # Alice net: +60 receivable
        # Bob net: -70 payable (sent 60+30, received 100) → net -10? Recalc...
    """

    def __init__(self):
        self._obligations: list[Obligation] = []
        self._cycle_count: int = 0
        self._total_gross: float = 0.0
        self._total_net: float = 0.0

    @property
    def pending_obligations(self) -> int:
        return len(self._obligations)

    @property
    def cycle_count(self) -> int:
        return self._cycle_count

    def add_obligation(
        self,
        from_party: str,
        to_party: str,
        asset: AssetType,
        amount: float,
    ) -> Obligation:
        """
        Register a new obligation in the clearinghouse.

        Args:
            from_party: Debtor party ID.
            to_party: Creditor party ID.
            asset: Asset type.
            amount: Amount owed.

        Returns:
            The created Obligation.
        """
        if amount <= 0:
            raise ValueError("Obligation amount must be positive")
        if from_party == to_party:
            raise ValueError("Self-obligation not allowed")

        ob_id = hashlib.sha256(
            f"{from_party}:{to_party}:{asset.value}:{amount}:{time.time_ns()}".encode()
        ).hexdigest()[:12]

        obligation = Obligation(
            obligation_id=ob_id,
            from_party=from_party,
            to_party=to_party,
            asset=asset,
            amount=amount,
        )
        self._obligations.append(obligation)
        return obligation

    def run_netting_cycle(self) -> NettingResult:
        """
        Execute multilateral netting on all pending obligations.

        For each asset, computes each party's net position:
          net = Σ(receivables) - Σ(payables)

        Returns:
            NettingResult with efficiency metrics.
        """
        self._cycle_count += 1
        cycle_id = f"NET-{self._cycle_count:06d}"
        timestamp = time.time_ns()

        # Group by asset
        asset_obligations: dict[AssetType, list[Obligation]] = {}
        for ob in self._obligations:
            if ob.asset not in asset_obligations:
                asset_obligations[ob.asset] = []
            asset_obligations[ob.asset].append(ob)

        # Compute net positions per asset
        all_net_positions: list[NetPosition] = []
        gross_total = 0.0
        net_total = 0.0

        for asset, obligations in asset_obligations.items():
            # Compute gross receivables and payables per party
            parties: dict[str, dict] = {}

            for ob in obligations:
                gross_total += ob.amount

                # from_party: payable
                if ob.from_party not in parties:
                    parties[ob.from_party] = {"receivable": 0.0, "payable": 0.0}
                parties[ob.from_party]["payable"] += ob.amount

                # to_party: receivable
                if ob.to_party not in parties:
                    parties[ob.to_party] = {"receivable": 0.0, "payable": 0.0}
                parties[ob.to_party]["receivable"] += ob.amount

            # Compute net position for each party
            for party, flows in parties.items():
                net_amount = flows["receivable"] - flows["payable"]
                net_total += abs(net_amount)

                gross_exposure = flows["receivable"] + flows["payable"]
                netting_ratio = (
                    1.0 - (abs(net_amount) / gross_exposure)
                    if gross_exposure > 0 else 0.0
                )

                all_net_positions.append(NetPosition(
                    party=party,
                    asset=asset,
                    net_amount=net_amount,
                    gross_receivable=flows["receivable"],
                    gross_payable=flows["payable"],
                    netting_ratio=netting_ratio,
                ))

        # Netting efficiency
        # Net total counts each net flow once; divide by 2 for bilateral
        net_settlement = net_total / 2.0 if net_total > 0 else 0.0
        efficiency = (
            (1.0 - net_settlement / gross_total) * 100.0
            if gross_total > 0 else 100.0
        )

        # Compute receipt hash
        receipt_data = f"{cycle_id}|{timestamp}|{len(self._obligations)}|{gross_total}|{net_settlement}"
        receipt_hash = hashlib.sha256(receipt_data.encode()).hexdigest()

        # Mark obligations as settled
        for ob in self._obligations:
            ob.settled = True

        result = NettingResult(
            cycle_id=cycle_id,
            timestamp_ns=timestamp,
            obligations_input=len(self._obligations),
            obligations_netted=len(self._obligations),
            net_positions=all_net_positions,
            gross_total=gross_total,
            net_total=net_settlement,
            netting_efficiency=efficiency,
            receipt_hash=receipt_hash,
        )

        # Update totals
        self._total_gross += gross_total
        self._total_net += net_settlement

        # Clear settled obligations
        self._obligations = []

        return result

    def get_stats(self) -> dict:
        """Return clearinghouse statistics."""
        return {
            "cycle_count": self._cycle_count,
            "pending_obligations": self.pending_obligations,
            "total_gross_processed": self._total_gross,
            "total_net_settled": self._total_net,
            "lifetime_efficiency": (
                (1.0 - self._total_net / self._total_gross) * 100.0
                if self._total_gross > 0 else 0.0
            ),
            "netting_cycle_beats": NETTING_CYCLE_BEATS,
            "netting_cycle_ms": NETTING_CYCLE_BEATS * HEARTBEAT_MS,
        }
