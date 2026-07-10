#!/usr/bin/env python3
"""
PARALLAX SDK — Compute Provenance & Receipt Hashing
=====================================================
Implements hash-based compute receipts for provenance tracking.

Every computation in the PARALLAX organism produces a sealed receipt:
  1. Input hash (what went in)
  2. Output hash (what came out)
  3. Execution context (who, when, which engine)
  4. Chain hash (links to previous receipt)

This creates an immutable chain of computational provenance that
can be verified by any party — human, AI agent, or auditor.
"""

import hashlib
import json
import time
from dataclasses import dataclass, field
from typing import Any, Optional


@dataclass
class ComputeReceipt:
    """An immutable receipt for a single computation."""
    receipt_id: str
    input_hash: str
    output_hash: str
    context_hash: str
    chain_hash: str  # Hash of previous receipt (or genesis hash)
    seal_hash: str  # Hash of all above fields combined
    timestamp_ns: int
    engine_id: str
    worker_id: str
    computation_type: str
    metadata: dict = field(default_factory=dict)


def _sha256(data: str) -> str:
    """Compute SHA-256 hex digest."""
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def _hash_any(obj: Any) -> str:
    """Hash any JSON-serializable object."""
    serialized = json.dumps(obj, sort_keys=True, default=str)
    return _sha256(serialized)


_FNV1A_32_OFFSET_BASIS: int = 2166136261
"""FNV-1a 32-bit offset basis."""

_FNV1A_32_PRIME: int = 16777619
"""FNV-1a 32-bit prime."""

_FNV1A_32_MASK: int = 0xFFFFFFFF
"""32-bit unsigned mask."""


def fnv1a(data: str) -> int:
    """FNV-1a hash — fast non-cryptographic hash for doctrine alignment."""
    h = _FNV1A_32_OFFSET_BASIS
    for byte in data.encode("utf-8"):
        h ^= byte
        h = (h * _FNV1A_32_PRIME) & _FNV1A_32_MASK
    return h


GENESIS_HASH = _sha256("PARALLAX:GENESIS:PHI:1.6180339887498948482")
"""The genesis chain hash — root of all provenance chains."""


class ProvenanceChain:
    """
    Provenance Chain — Sealed Compute Receipt Ledger.

    Maintains an ordered chain of compute receipts where each receipt
    cryptographically references the previous one, creating an
    immutable audit trail.

    Usage:
        chain = ProvenanceChain(engine_id="engine-alpha-001")

        receipt = chain.seal(
            input_data={"query": "predict BTC/ICP"},
            output_data={"prediction": 0.00234, "confidence": 0.87},
            worker_id="py-ml-001",
            computation_type="price_prediction",
        )

        # Verify chain integrity
        assert chain.verify()
    """

    def __init__(self, engine_id: str):
        self._engine_id = engine_id
        self._chain: list[ComputeReceipt] = []
        self._last_hash: str = GENESIS_HASH

    @property
    def length(self) -> int:
        return len(self._chain)

    @property
    def last_hash(self) -> str:
        return self._last_hash

    @property
    def engine_id(self) -> str:
        return self._engine_id

    def seal(
        self,
        input_data: Any,
        output_data: Any,
        worker_id: str,
        computation_type: str,
        metadata: Optional[dict] = None,
    ) -> ComputeReceipt:
        """
        Seal a new computation into the provenance chain.

        Args:
            input_data: The computation input (any JSON-serializable object).
            output_data: The computation output.
            worker_id: ID of the worker that performed the computation.
            computation_type: Type/category of computation.
            metadata: Optional additional metadata.

        Returns:
            The sealed ComputeReceipt.
        """
        timestamp = time.time_ns()

        # Compute individual hashes
        input_hash = _hash_any(input_data)
        output_hash = _hash_any(output_data)
        context_hash = _sha256(
            f"{self._engine_id}|{worker_id}|{computation_type}|{timestamp}"
        )
        chain_hash = self._last_hash

        # Compute receipt ID
        receipt_id = _sha256(
            f"{input_hash}|{output_hash}|{context_hash}|{chain_hash}|{timestamp}"
        )[:16]

        # Compute seal hash (integrity of entire receipt)
        seal_hash = _sha256(
            f"{receipt_id}|{input_hash}|{output_hash}|{context_hash}|{chain_hash}"
        )

        receipt = ComputeReceipt(
            receipt_id=receipt_id,
            input_hash=input_hash,
            output_hash=output_hash,
            context_hash=context_hash,
            chain_hash=chain_hash,
            seal_hash=seal_hash,
            timestamp_ns=timestamp,
            engine_id=self._engine_id,
            worker_id=worker_id,
            computation_type=computation_type,
            metadata=metadata or {},
        )

        self._chain.append(receipt)
        self._last_hash = seal_hash

        return receipt

    def verify(self) -> bool:
        """
        Verify the integrity of the entire provenance chain.

        Checks that each receipt's chain_hash correctly references
        the seal_hash of the preceding receipt.

        Returns:
            True if chain is valid, False if tampered.
        """
        if not self._chain:
            return True

        # First receipt should reference genesis
        if self._chain[0].chain_hash != GENESIS_HASH:
            return False

        # Each subsequent receipt references previous seal_hash
        for i in range(1, len(self._chain)):
            if self._chain[i].chain_hash != self._chain[i - 1].seal_hash:
                return False

        # Verify each seal hash is correctly computed
        for receipt in self._chain:
            expected_seal = _sha256(
                f"{receipt.receipt_id}|{receipt.input_hash}|{receipt.output_hash}"
                f"|{receipt.context_hash}|{receipt.chain_hash}"
            )
            if receipt.seal_hash != expected_seal:
                return False

        return True

    def get_receipt(self, index: int) -> Optional[ComputeReceipt]:
        """Get a receipt by index."""
        if 0 <= index < len(self._chain):
            return self._chain[index]
        return None

    def get_receipt_by_id(self, receipt_id: str) -> Optional[ComputeReceipt]:
        """Find a receipt by its ID."""
        for receipt in self._chain:
            if receipt.receipt_id == receipt_id:
                return receipt
        return None

    def export_chain(self) -> list[dict]:
        """Export the entire chain as JSON-serializable list."""
        return [
            {
                "receipt_id": r.receipt_id,
                "input_hash": r.input_hash,
                "output_hash": r.output_hash,
                "context_hash": r.context_hash,
                "chain_hash": r.chain_hash,
                "seal_hash": r.seal_hash,
                "timestamp_ns": r.timestamp_ns,
                "engine_id": r.engine_id,
                "worker_id": r.worker_id,
                "computation_type": r.computation_type,
                "metadata": r.metadata,
            }
            for r in self._chain
        ]

    def get_stats(self) -> dict:
        """Return provenance chain statistics."""
        return {
            "engine_id": self._engine_id,
            "chain_length": self.length,
            "last_hash": self._last_hash,
            "is_valid": self.verify(),
            "genesis_hash": GENESIS_HASH,
        }
