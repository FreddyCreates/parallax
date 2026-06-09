"""
ENTANGALA Python Bridge — PARALLAX Sovereign Organism
"""
__version__ = "0.1.0"
__author__ = "Alfredo Medina Hernandez"

from .entangala_bridge import (
    EntangalaBridge,
    PythonDomain,
    BridgeMessage,
    EntanglementState,
    PHI,
    PHI_INV,
    PHI_INV_3,
    PHI_INV_5,
    HEARTBEAT_MS,
    compute_phi_coherence,
    compute_doctrine_hash,
    fnv1a_hash,
)

__all__ = [
    "EntangalaBridge",
    "PythonDomain",
    "BridgeMessage",
    "EntanglementState",
    "PHI",
    "PHI_INV",
    "PHI_INV_3",
    "PHI_INV_5",
    "HEARTBEAT_MS",
    "compute_phi_coherence",
    "compute_doctrine_hash",
    "fnv1a_hash",
]
