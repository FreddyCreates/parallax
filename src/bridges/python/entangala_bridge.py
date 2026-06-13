#!/usr/bin/env python3
"""
ENTANGALA Python Bridge — PARALLAX Sovereign Organism
=====================================================

The Python-side entanglement protocol for PARALLAX.
This module implements the ENTANGALA bridge protocol, allowing Python
computations to entangle with the sovereign organism's Motoko core.

Protocol:
  1. Register with the organism (HTTP POST to canister endpoint)
  2. Sync heartbeat every F(4)=3 organism beats (~2619ms)
  3. Receive computation dispatches from organism
  4. Return results with phi-coherence signature

Domains supported:
  - Machine Learning (scikit-learn, PyTorch, TensorFlow)
  - Data Analysis (pandas, NumPy)
  - Scientific Computing (SciPy, SymPy)
  - Natural Language Processing (spaCy, transformers)
  - Cryptography (hashlib, cryptography)
  - Visualization (matplotlib, plotly)

Author: Alfredo Medina Hernandez — The Architect of the Field
License: PARALLAX Sovereign License
"""

import hashlib
import json
import math
import time
import threading
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, Optional

# ═══════════════════════════════════════════════════════════════════════════════
# PHI CONSTANTS — The organism's coupling constants (mirror of phi.mo)
# ═══════════════════════════════════════════════════════════════════════════════

PHI: float = 1.6180339887498948482
PHI_INV: float = 0.6180339887498948482     # φ⁻¹
PHI_INV_2: float = 0.3819660112501051518   # φ⁻²
PHI_INV_3: float = 0.2360679774997896964   # φ⁻³
PHI_INV_5: float = 0.0901699437494742410   # φ⁻⁵

SCHUMANN_1: float = 7.83                    # Earth's fundamental resonance
HEARTBEAT_MS: int = 873                     # Sovereign heartbeat (ms)
SYNC_INTERVAL_BEATS: int = 3               # F(4) = 3

# Fibonacci sequence (mirrors phi.mo)
FIB = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987]


# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

class PythonDomain(Enum):
    """Python computation domains — mirrors PythonDomain in python_bridge.mo"""
    MACHINE_LEARNING = "machinelearning"
    DATA_ANALYSIS = "dataanalysis"
    SCIENTIFIC_COMPUTE = "scientificcompute"
    VISUALIZATION = "visualization"
    CRYPTOGRAPHY = "cryptography"
    NLP = "nlp"


# ═══════════════════════════════════════════════════════════════════════════════
# BRIDGE MESSAGE TYPES
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class BridgeMessage:
    """A message crossing the ENTANGALA bridge."""
    message_id: str
    direction: str              # "toPy" or "toMo"
    payload: dict
    beat_timestamp: int
    phi_signature: float
    doctrine_hash: int
    response_expected: bool


@dataclass
class EntanglementState:
    """Current entanglement state of this Python worker."""
    worker_id: str
    domain: PythonDomain
    entanglement: float = PHI_INV   # Initial at φ⁻¹
    last_sync_beat: int = 0
    is_alive: bool = True
    task_queue: int = 0
    total_dispatches: int = 0


# ═══════════════════════════════════════════════════════════════════════════════
# PHI-COHERENCE COMPUTATION
# ═══════════════════════════════════════════════════════════════════════════════

def compute_phi_coherence(values: list[float]) -> float:
    """
    Compute phi-coherence of a set of values.
    Coherence measures how close the ratios between successive values
    are to the golden ratio φ.

    Returns float ∈ [0, 1] where 1.0 = perfect phi-alignment.
    """
    if len(values) < 2:
        return PHI_INV  # Minimum coherence for single values

    ratios = []
    for i in range(1, len(values)):
        if values[i - 1] != 0:
            ratios.append(values[i] / values[i - 1])

    if not ratios:
        return PHI_INV

    # Coherence = 1 - mean_deviation_from_phi
    deviations = [abs(r - PHI) / PHI for r in ratios]
    mean_dev = sum(deviations) / len(deviations)
    coherence = max(0.0, 1.0 - mean_dev)
    return coherence


def fnv1a_hash(data: str) -> int:
    """FNV-1a hash — mirrors the organism's doctrine hashing."""
    FNV_OFFSET = 2166136261
    FNV_PRIME = 16777619
    h = FNV_OFFSET
    for byte in data.encode('utf-8'):
        h ^= byte
        h = (h * FNV_PRIME) & 0xFFFFFFFF
    return h


def compute_doctrine_hash(context: str) -> int:
    """Compute doctrine alignment hash for bridge messages."""
    return fnv1a_hash(context)


# ═══════════════════════════════════════════════════════════════════════════════
# ENTANGALA BRIDGE CLASS
# ═══════════════════════════════════════════════════════════════════════════════

class EntangalaBridge:
    """
    The ENTANGALA Python Bridge.

    Manages the entanglement between this Python process and the
    PARALLAX sovereign organism running on the Internet Computer.

    Usage:
        bridge = EntangalaBridge(
            worker_id="py-ml-001",
            domain=PythonDomain.MACHINE_LEARNING,
            organism_endpoint="https://your-canister.ic0.app"
        )
        bridge.start()

        # Register a computation handler
        @bridge.on_dispatch
        def handle_ml_task(payload: dict) -> dict:
            # Your ML computation here
            return {"result": prediction, "confidence": 0.95}
    """

    def __init__(
        self,
        worker_id: str,
        domain: PythonDomain,
        organism_endpoint: str,
    ):
        self.state = EntanglementState(
            worker_id=worker_id,
            domain=domain,
        )
        self.organism_endpoint = organism_endpoint
        self._handlers: dict[str, Callable] = {}
        self._sync_thread: Optional[threading.Thread] = None
        self._running = False
        self._current_beat = 0

    def on_dispatch(self, func: Callable[[dict], dict]) -> Callable:
        """Decorator to register a computation dispatch handler."""
        self._handlers[self.state.domain.value] = func
        return func

    def start(self):
        """Start the bridge — begin heartbeat sync loop."""
        self._running = True
        self._sync_thread = threading.Thread(
            target=self._sync_loop,
            daemon=True,
            name=f"entangala-sync-{self.state.worker_id}"
        )
        self._sync_thread.start()
        print(f"[ENTANGALA] Bridge started: {self.state.worker_id} "
              f"({self.state.domain.value})")
        print(f"[ENTANGALA] Entanglement: {self.state.entanglement:.4f}")
        print(f"[ENTANGALA] Sync interval: {SYNC_INTERVAL_BEATS} beats "
              f"({SYNC_INTERVAL_BEATS * HEARTBEAT_MS}ms)")

    def stop(self):
        """Stop the bridge gracefully."""
        self._running = False
        if self._sync_thread:
            self._sync_thread.join(timeout=5.0)
        print(f"[ENTANGALA] Bridge stopped: {self.state.worker_id}")

    def dispatch(self, payload: dict) -> Optional[dict]:
        """
        Process an incoming computation dispatch from the organism.

        Gate: Only processes if entanglement ≥ φ⁻¹ (0.618).
        """
        if self.state.entanglement < PHI_INV:
            print(f"[ENTANGALA] GATE REJECT: entanglement "
                  f"{self.state.entanglement:.4f} < {PHI_INV:.4f}")
            return None

        handler = self._handlers.get(self.state.domain.value)
        if handler is None:
            print(f"[ENTANGALA] No handler for domain: {self.state.domain.value}")
            return None

        self.state.task_queue += 1
        try:
            result = handler(payload)
            self.state.total_dispatches += 1
            # Successful dispatch strengthens entanglement (Hebbian)
            self.state.entanglement = min(
                1.0,
                self.state.entanglement + PHI_INV_3
            )
            return result
        except Exception as e:
            print(f"[ENTANGALA] Dispatch error: {e}")
            # Failed dispatch weakens entanglement
            self.state.entanglement = max(
                0.0,
                self.state.entanglement - PHI_INV_3
            )
            return None
        finally:
            self.state.task_queue -= 1

    def create_bridge_message(
        self,
        payload: dict,
        direction: str = "toMo"
    ) -> BridgeMessage:
        """Create a properly signed bridge message."""
        msg_id = hashlib.sha256(
            f"{self.state.worker_id}:{self._current_beat}:{time.time_ns()}".encode()
        ).hexdigest()[:16]

        return BridgeMessage(
            message_id=msg_id,
            direction=direction,
            payload=payload,
            beat_timestamp=self._current_beat,
            phi_signature=self.state.entanglement,
            doctrine_hash=compute_doctrine_hash(
                f"{self.state.worker_id}|{self.state.domain.value}|{self._current_beat}"
            ),
            response_expected=(direction == "toMo"),
        )

    def get_diagnostics(self) -> dict:
        """Return bridge diagnostics."""
        return {
            "worker_id": self.state.worker_id,
            "domain": self.state.domain.value,
            "entanglement": self.state.entanglement,
            "is_alive": self.state.is_alive,
            "current_beat": self._current_beat,
            "total_dispatches": self.state.total_dispatches,
            "task_queue": self.state.task_queue,
        }

    def _sync_loop(self):
        """Internal heartbeat sync loop."""
        sync_interval_s = (SYNC_INTERVAL_BEATS * HEARTBEAT_MS) / 1000.0

        while self._running and self.state.is_alive:
            time.sleep(sync_interval_s)
            self._current_beat += SYNC_INTERVAL_BEATS

            # Update sync state
            self.state.last_sync_beat = self._current_beat

            # Check if entanglement is still viable
            if self.state.entanglement < PHI_INV_5:
                print(f"[ENTANGALA] DEATH: entanglement {self.state.entanglement:.6f} "
                      f"< φ⁻⁵ ({PHI_INV_5:.6f}). Worker pruned.")
                self.state.is_alive = False
                break


# ═══════════════════════════════════════════════════════════════════════════════
# EXAMPLE USAGE
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    # Example: ML domain bridge
    bridge = EntangalaBridge(
        worker_id="py-ml-001",
        domain=PythonDomain.MACHINE_LEARNING,
        organism_endpoint="https://parallax-backend.ic0.app",
    )

    @bridge.on_dispatch
    def handle_ml_task(payload: dict) -> dict:
        """Example ML computation handler."""
        # In production: run actual ML inference here
        input_data = payload.get("input", [])
        # Phi-weighted moving average as example
        if isinstance(input_data, list) and len(input_data) > 0:
            weighted = [v * (PHI_INV ** i) for i, v in enumerate(input_data)]
            prediction = sum(weighted) / sum(PHI_INV ** i for i in range(len(input_data)))
        else:
            prediction = 0.0

        coherence = compute_phi_coherence(
            input_data if isinstance(input_data, list) else [0.0]
        )

        return {
            "prediction": prediction,
            "coherence": coherence,
            "phi_signature": bridge.state.entanglement,
        }

    bridge.start()

    # Simulate a dispatch
    result = bridge.dispatch({"input": [1, 1, 2, 3, 5, 8, 13, 21]})
    print(f"\n[RESULT] {json.dumps(result, indent=2)}")
    print(f"[DIAGNOSTICS] {json.dumps(bridge.get_diagnostics(), indent=2)}")

    bridge.stop()
