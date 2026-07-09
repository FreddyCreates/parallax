#!/usr/bin/env python3
"""
PARALLAX SDK — Constants Module
================================
Golden Ratio constants, Fibonacci sequences, Schumann resonance parameters,
and heartbeat timing derived from the sovereign organism's mathematical substrate.

All constants mirror the Motoko core (src/backend/main.mo → phi.mo).
"""

import math

# ═══════════════════════════════════════════════════════════════════════════════
# PHI — THE GOLDEN RATIO AND ITS POWERS
# ═══════════════════════════════════════════════════════════════════════════════

PHI: float = 1.6180339887498948482
"""The Golden Ratio φ = (1 + √5) / 2"""

PHI_SQ: float = PHI ** 2  # 2.6180339887498948482
"""φ² = φ + 1"""

PHI_CUBE: float = PHI ** 3  # 4.2360679774997896964
"""φ³ = 2φ + 1"""

PHI_4: float = PHI ** 4  # 6.8541019662496845446
"""φ⁴ = 3φ + 2"""

PHI_INV: float = 1.0 / PHI  # 0.6180339887498948482
"""φ⁻¹ = φ - 1 = 1/φ"""

PHI_INV_2: float = PHI_INV ** 2  # 0.3819660112501051518
"""φ⁻²"""

PHI_INV_3: float = PHI_INV ** 3  # 0.2360679774997896964
"""φ⁻³"""

PHI_INV_5: float = PHI_INV ** 5  # 0.0901699437494742410
"""φ⁻⁵ — death threshold for entanglement"""

# ═══════════════════════════════════════════════════════════════════════════════
# FIBONACCI SEQUENCE
# ═══════════════════════════════════════════════════════════════════════════════

FIBONACCI: list[int] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987]
"""First 16 Fibonacci numbers — used for structural scaling throughout the organism."""


def fibonacci(n: int) -> int:
    """Compute the nth Fibonacci number (0-indexed: fib(0)=0, fib(1)=1, fib(2)=1...)."""
    if n <= 0:
        return 0
    a, b = 0, 1
    for _ in range(n - 1):
        a, b = b, a + b
    return b


def fibonacci_sequence(length: int) -> list[int]:
    """Generate a Fibonacci sequence of given length."""
    if length <= 0:
        return []
    seq = [1]
    if length == 1:
        return seq
    seq.append(1)
    for i in range(2, length):
        seq.append(seq[i - 1] + seq[i - 2])
    return seq


# ═══════════════════════════════════════════════════════════════════════════════
# SCHUMANN RESONANCE — EARTH'S HEARTBEAT
# ═══════════════════════════════════════════════════════════════════════════════

SCHUMANN_FUNDAMENTAL: float = 7.83
"""Schumann resonance fundamental frequency (Hz) — Earth's electromagnetic heartbeat."""

SCHUMANN_HARMONICS: list[float] = [7.83, 14.3, 20.8, 27.3, 33.8]
"""First 5 Schumann resonance modes (Hz)."""

# ═══════════════════════════════════════════════════════════════════════════════
# HEARTBEAT TIMING
# ═══════════════════════════════════════════════════════════════════════════════

HEARTBEAT_MS: int = 873
"""Sovereign heartbeat interval in milliseconds.
Derivation: φ⁴ × 1000ms / 7.83Hz ≈ 873ms"""

HEARTBEAT_S: float = HEARTBEAT_MS / 1000.0
"""Heartbeat interval in seconds."""

HEARTBEAT_HZ: float = 1000.0 / HEARTBEAT_MS
"""Heartbeat frequency in Hz (~1.145 Hz)."""

SYNC_INTERVAL_BEATS: int = 3
"""F(4) = 3 — bridge sync every 3 heartbeats."""

SYNC_INTERVAL_MS: int = SYNC_INTERVAL_BEATS * HEARTBEAT_MS
"""Bridge sync interval in milliseconds (2619ms)."""

# ═══════════════════════════════════════════════════════════════════════════════
# COHERENCE THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

COHERENCE_GATE: float = PHI_INV  # 0.618
"""Minimum Kuramoto coherence (R) required to pass the organism's gate."""

ENTANGLEMENT_DEATH: float = PHI_INV_5  # 0.0901...
"""Below this threshold, a worker is pruned from the organism."""

ENTANGLEMENT_INIT: float = PHI_INV  # 0.618
"""Initial entanglement for new workers."""

HEBBIAN_REWARD: float = PHI_INV_3  # 0.236
"""Entanglement gain on successful computation (Hebbian strengthening)."""

HEBBIAN_PENALTY: float = PHI_INV_3  # 0.236
"""Entanglement loss on failed computation."""

# ═══════════════════════════════════════════════════════════════════════════════
# SETTLEMENT PARAMETERS
# ═══════════════════════════════════════════════════════════════════════════════

MAX_ENGINES: int = 144
"""Maximum production engines in the organism (F(12) = 144)."""

NETTING_CYCLE_BEATS: int = 8
"""F(6) = 8 — clearinghouse netting runs every 8 heartbeats."""

NETTING_CYCLE_MS: int = NETTING_CYCLE_BEATS * HEARTBEAT_MS
"""Netting cycle in milliseconds (6984ms ≈ 7s)."""
