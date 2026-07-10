#!/usr/bin/env python3
"""
PARALLAX SDK — AI Artifact Tokenizer
======================================
Models the tokenization of AI-generated artifacts (models, datasets,
computations, research outputs) into tradeable tokens on the PARALLAX
exchange.

Each AI artifact receives a cognitive resonance score based on:
  1. Phi-coherence of its internal structure
  2. Utility score (usage frequency, citation count)
  3. Novelty factor (information entropy)
  4. Provenance depth (chain length of computation history)

The token value is derived from these factors using golden-ratio
weighted combination.
"""

import hashlib
import math
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional

from .constants import (
    PHI,
    PHI_INV,
    PHI_INV_2,
    PHI_INV_3,
    FIBONACCI,
)


_BYTE_ENTROPY_BITS: float = 8.0
"""Maximum Shannon entropy for a byte stream (log2(256) = 8 bits)."""

_CHUNK_DIVISOR: int = 16
"""Number of chunks to divide artifact data into for phi-coherence analysis."""

_MAX_FIBONACCI_INDEX: int = 15
"""Maximum index into FIBONACCI sequence for supply scaling."""


class ArtifactCategory(Enum):
    """Categories of AI artifacts that can be tokenized."""
    MODEL = "model"
    DATASET = "dataset"
    COMPUTATION = "computation"
    RESEARCH = "research"
    AGENT_OUTPUT = "agent_output"
    EMBEDDING = "embedding"
    PROOF = "proof"


@dataclass
class CognitiveResonanceScore:
    """Composite resonance score for an AI artifact."""
    phi_coherence: float  # [0, 1] — structural golden-ratio alignment
    utility: float  # [0, 1] — practical usefulness
    novelty: float  # [0, 1] — information entropy / uniqueness
    provenance_depth: float  # [0, 1] — normalized chain depth
    composite: float  # Weighted combination
    passed_threshold: bool  # Whether composite ≥ φ⁻¹


@dataclass
class AIToken:
    """A tokenized AI artifact."""
    token_id: str
    artifact_hash: str
    category: ArtifactCategory
    creator: str
    name: str
    description: str
    resonance_score: CognitiveResonanceScore
    initial_supply: int
    created_at_ns: int
    metadata: dict = field(default_factory=dict)


def compute_phi_coherence(values: list[float]) -> float:
    """
    Compute phi-coherence: how closely successive ratios
    approximate the golden ratio.

    Returns float ∈ [0, 1] where 1.0 = perfect phi-alignment.
    """
    if len(values) < 2:
        return PHI_INV

    ratios = []
    for i in range(1, len(values)):
        if values[i - 1] != 0:
            ratios.append(values[i] / values[i - 1])

    if not ratios:
        return PHI_INV

    deviations = [abs(r - PHI) / PHI for r in ratios]
    mean_dev = sum(deviations) / len(deviations)
    return max(0.0, min(1.0, 1.0 - mean_dev))


def compute_novelty(data: bytes) -> float:
    """
    Compute novelty as normalized Shannon entropy of the data.

    Returns float ∈ [0, 1] where 1.0 = maximum entropy.
    """
    if not data:
        return 0.0

    # Byte frequency distribution
    freq = [0] * 256
    for byte in data:
        freq[byte] += 1

    length = len(data)
    entropy = 0.0
    for count in freq:
        if count > 0:
            p = count / length
            entropy -= p * math.log2(p)

    # Normalize to [0, 1] (max entropy for bytes = 8 bits)
    return entropy / _BYTE_ENTROPY_BITS


def compute_resonance_score(
    phi_coherence: float,
    utility: float,
    novelty: float,
    provenance_depth: int,
    max_provenance: int = 144,
) -> CognitiveResonanceScore:
    """
    Compute the cognitive resonance score for an artifact.

    Weights (golden-ratio derived):
      - phi_coherence: φ⁻¹ = 0.618
      - utility: φ⁻² = 0.382
      - novelty: φ⁻³ = 0.236
      - provenance: φ⁻³ = 0.236

    The composite is normalized to [0, 1].
    """
    # Normalize provenance depth
    prov_norm = min(1.0, provenance_depth / max_provenance) if max_provenance > 0 else 0.0

    # Golden-ratio weighted combination
    weights = [PHI_INV, PHI_INV_2, PHI_INV_3, PHI_INV_3]
    values = [phi_coherence, utility, novelty, prov_norm]

    total_weight = sum(weights)
    composite = sum(w * v for w, v in zip(weights, values)) / total_weight

    return CognitiveResonanceScore(
        phi_coherence=phi_coherence,
        utility=utility,
        novelty=novelty,
        provenance_depth=prov_norm,
        composite=composite,
        passed_threshold=(composite >= PHI_INV),
    )


class ArtifactTokenizer:
    """
    AI Artifact Tokenizer.

    Evaluates AI artifacts and mints tokens representing their value
    on the PARALLAX exchange.

    Usage:
        tokenizer = ArtifactTokenizer()

        token = tokenizer.tokenize(
            name="GPT-Phi Predictor v2",
            description="Price prediction model using phi-harmonic analysis",
            category=ArtifactCategory.MODEL,
            creator="py-ml-001",
            artifact_data=model_bytes,
            utility_score=0.85,
            provenance_depth=13,
        )

        if token:
            print(f"Token minted: {token.token_id}")
            print(f"Resonance: {token.resonance_score.composite:.4f}")
    """

    def __init__(self, min_resonance: float = PHI_INV):
        self._min_resonance = min_resonance
        self._tokens: list[AIToken] = []

    @property
    def token_count(self) -> int:
        return len(self._tokens)

    def tokenize(
        self,
        name: str,
        description: str,
        category: ArtifactCategory,
        creator: str,
        artifact_data: bytes,
        utility_score: float = 0.5,
        provenance_depth: int = 0,
        supply: Optional[int] = None,
        metadata: Optional[dict] = None,
    ) -> Optional[AIToken]:
        """
        Evaluate and tokenize an AI artifact.

        The artifact must pass the resonance gate (composite ≥ φ⁻¹)
        to be tokenized. Artifacts below threshold are rejected.

        Args:
            name: Human-readable artifact name.
            description: Description of the artifact.
            category: Artifact category.
            creator: Creator/worker ID.
            artifact_data: Raw bytes of the artifact.
            utility_score: Externally assessed utility [0, 1].
            provenance_depth: Number of provenance receipts.
            supply: Initial token supply (default: Fibonacci-derived).
            metadata: Optional additional metadata.

        Returns:
            AIToken if resonance gate passes, None otherwise.
        """
        # Compute artifact hash
        artifact_hash = hashlib.sha256(artifact_data).hexdigest()

        # Compute phi-coherence from byte distribution
        # Use sliding windows of the data to find structural patterns
        chunk_size = max(1, len(artifact_data) // _CHUNK_DIVISOR)
        chunk_sums = []
        for i in range(0, len(artifact_data), chunk_size):
            chunk = artifact_data[i:i + chunk_size]
            chunk_sums.append(float(sum(chunk)))

        phi_coherence = compute_phi_coherence(chunk_sums) if chunk_sums else PHI_INV

        # Compute novelty
        novelty = compute_novelty(artifact_data)

        # Compute resonance score
        score = compute_resonance_score(
            phi_coherence=phi_coherence,
            utility=utility_score,
            novelty=novelty,
            provenance_depth=provenance_depth,
        )

        # Gate check
        if score.composite < self._min_resonance:
            return None

        # Determine supply using Fibonacci scaling
        if supply is None:
            # Scale supply by resonance: higher resonance = rarer token
            fib_index = min(_MAX_FIBONACCI_INDEX, int(score.composite * _MAX_FIBONACCI_INDEX))
            supply = FIBONACCI[fib_index]

        # Generate token ID
        token_id = hashlib.sha256(
            f"{artifact_hash}|{creator}|{time.time_ns()}".encode()
        ).hexdigest()[:16]

        token = AIToken(
            token_id=token_id,
            artifact_hash=artifact_hash,
            category=category,
            creator=creator,
            name=name,
            description=description,
            resonance_score=score,
            initial_supply=supply,
            created_at_ns=time.time_ns(),
            metadata=metadata or {},
        )

        self._tokens.append(token)
        return token

    def get_token(self, token_id: str) -> Optional[AIToken]:
        """Look up a token by ID."""
        for token in self._tokens:
            if token.token_id == token_id:
                return token
        return None

    def list_tokens(self) -> list[dict]:
        """List all minted tokens with summary info."""
        return [
            {
                "token_id": t.token_id,
                "name": t.name,
                "category": t.category.value,
                "creator": t.creator,
                "resonance": t.resonance_score.composite,
                "supply": t.initial_supply,
            }
            for t in self._tokens
        ]

    def get_stats(self) -> dict:
        """Return tokenizer statistics."""
        if not self._tokens:
            return {"token_count": 0, "avg_resonance": 0.0}
        avg_resonance = sum(t.resonance_score.composite for t in self._tokens) / len(self._tokens)
        return {
            "token_count": self.token_count,
            "avg_resonance": avg_resonance,
            "min_resonance_threshold": self._min_resonance,
            "categories": list(set(t.category.value for t in self._tokens)),
        }
