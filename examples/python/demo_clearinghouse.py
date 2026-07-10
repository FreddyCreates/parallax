#!/usr/bin/env python3
"""
PARALLAX SDK Demo — Full Clearinghouse Workflow
=================================================
Demonstrates the complete PARALLAX Python SDK:
  1. Constants & Fibonacci
  2. Kuramoto Coherence Gating
  3. Clearinghouse Netting
  4. Provenance Chain Sealing
  5. AI Artifact Tokenization

Run: python examples/python/demo_clearinghouse.py
"""

import json
import sys
import os

# Add SDK to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'src', 'python'))

from parallax_sdk import (
    # Constants
    PHI, PHI_INV, HEARTBEAT_MS, FIBONACCI,
    SCHUMANN_FUNDAMENTAL, fibonacci_sequence,
    # Coherence
    KuramotoCoherenceGate,
    # Clearinghouse
    ClearinghouseEngine, AssetType,
    # Provenance
    ProvenanceChain,
    # Tokenizer
    ArtifactTokenizer, ArtifactCategory,
    # Utilities
    derive_heartbeat,
)


def separator(title: str):
    print(f"\n{'═' * 60}")
    print(f"  {title}")
    print(f"{'═' * 60}\n")


def main():
    print("🌌 PARALLAX Exchange Clearinghouse — Python SDK Demo")
    print(f"   Zenodo: https://zenodo.org/records/20370721")
    print(f"   Version: 0.2.0")

    # ─────────────────────────────────────────────────────────────
    # 1. CONSTANTS & MATHEMATICAL SUBSTRATE
    # ─────────────────────────────────────────────────────────────
    separator("1. MATHEMATICAL SUBSTRATE")

    print(f"  φ (Golden Ratio)      = {PHI}")
    print(f"  φ⁻¹ (Coherence Gate)  = {PHI_INV:.16f}")
    print(f"  Schumann Fundamental  = {SCHUMANN_FUNDAMENTAL} Hz")
    print(f"  Heartbeat Interval    = {HEARTBEAT_MS} ms")
    print(f"  Heartbeat Derivation  = {derive_heartbeat():.2f} ms (φ⁴×1000/7.83)")
    print(f"  Fibonacci(16)         = {fibonacci_sequence(16)}")

    # ─────────────────────────────────────────────────────────────
    # 2. KURAMOTO COHERENCE GATE
    # ─────────────────────────────────────────────────────────────
    separator("2. KURAMOTO COHERENCE GATE")

    gate = KuramotoCoherenceGate()

    # Add oscillators with slight phase offsets (near-synchronized)
    import math
    for i in range(8):
        phase = 0.1 * i  # Small spread
        gate.add_oscillator(phase=phase, freq=SCHUMANN_FUNDAMENTAL, label=f"osc-{i}")

    result = gate.measure()
    print(f"  Oscillators:    {result.oscillator_count}")
    print(f"  Order Param R:  {result.R:.4f}")
    print(f"  Mean Phase ψ:   {result.psi:.4f} rad")
    print(f"  Gate Passed:    {'✅ YES' if result.passed_gate else '❌ NO'}")
    print(f"  Phase Variance: {result.phase_variance:.4f}")

    # Evolve for a few steps
    print(f"\n  Evolving 5 heartbeats...")
    history = gate.evolve(5)
    for i, r in enumerate(history):
        print(f"    Beat {i+1}: R={r.R:.4f} {'✅' if r.passed_gate else '❌'}")

    # ─────────────────────────────────────────────────────────────
    # 3. CLEARINGHOUSE NETTING
    # ─────────────────────────────────────────────────────────────
    separator("3. CLEARINGHOUSE NETTING")

    engine = ClearinghouseEngine()

    # Simulate a trading day
    engine.add_obligation("Alice", "Bob", AssetType.ICP, 100.0)
    engine.add_obligation("Bob", "Alice", AssetType.ICP, 60.0)
    engine.add_obligation("Bob", "Charlie", AssetType.ICP, 45.0)
    engine.add_obligation("Charlie", "Alice", AssetType.ICP, 30.0)
    engine.add_obligation("Alice", "Charlie", AssetType.CKBTC, 2.5)
    engine.add_obligation("Charlie", "Bob", AssetType.CKBTC, 1.0)

    print(f"  Pending obligations: {engine.pending_obligations}")
    print(f"  Running netting cycle...")

    result = engine.run_netting_cycle()

    print(f"\n  Cycle ID:           {result.cycle_id}")
    print(f"  Obligations netted: {result.obligations_netted}")
    print(f"  Gross total:        {result.gross_total:.2f}")
    print(f"  Net settlement:     {result.net_total:.2f}")
    print(f"  Netting efficiency: {result.netting_efficiency:.1f}%")
    print(f"  Receipt hash:       {result.receipt_hash[:32]}...")

    print(f"\n  Net Positions:")
    for pos in result.net_positions:
        direction = "▲ receive" if pos.net_amount >= 0 else "▼ pay"
        print(f"    {pos.party:10s} | {pos.asset.value:8s} | "
              f"{direction} {abs(pos.net_amount):8.2f} | "
              f"netting: {pos.netting_ratio:.1%}")

    # ─────────────────────────────────────────────────────────────
    # 4. PROVENANCE CHAIN
    # ─────────────────────────────────────────────────────────────
    separator("4. PROVENANCE CHAIN")

    chain = ProvenanceChain(engine_id="engine-alpha-001")

    # Seal some computations
    r1 = chain.seal(
        input_data={"query": "predict ICP/USD", "window": 24},
        output_data={"prediction": 12.45, "confidence": 0.87},
        worker_id="py-ml-001",
        computation_type="price_prediction",
    )
    print(f"  Receipt 1: {r1.receipt_id}")

    r2 = chain.seal(
        input_data={"model": "phi-harmonic-v2", "epochs": 100},
        output_data={"accuracy": 0.923, "loss": 0.045},
        worker_id="py-ml-001",
        computation_type="model_training",
    )
    print(f"  Receipt 2: {r2.receipt_id}")

    r3 = chain.seal(
        input_data={"assets": ["ICP", "ckBTC", "ckETH"], "method": "kuramoto"},
        output_data={"coherence": 0.78, "risk_score": 0.12},
        worker_id="py-risk-001",
        computation_type="risk_analysis",
    )
    print(f"  Receipt 3: {r3.receipt_id}")

    # Verify chain
    is_valid = chain.verify()
    print(f"\n  Chain length: {chain.length}")
    print(f"  Chain valid:  {'✅ VERIFIED' if is_valid else '❌ TAMPERED'}")
    print(f"  Last hash:    {chain.last_hash[:32]}...")

    # ─────────────────────────────────────────────────────────────
    # 5. AI ARTIFACT TOKENIZATION
    # ─────────────────────────────────────────────────────────────
    separator("5. AI ARTIFACT TOKENIZATION")

    tokenizer = ArtifactTokenizer()

    # Create a mock AI artifact (simulated model weights)
    artifact_data = bytes(
        [int((math.sin(i * PHI) + 1) * 127) % 256 for i in range(1024)]
    )

    token = tokenizer.tokenize(
        name="Phi-Harmonic Price Predictor v2",
        description="Neural price prediction using golden-ratio harmonic analysis",
        category=ArtifactCategory.MODEL,
        creator="py-ml-001",
        artifact_data=artifact_data,
        utility_score=0.85,
        provenance_depth=13,
    )

    if token:
        print(f"  ✅ Token Minted!")
        print(f"  Token ID:     {token.token_id}")
        print(f"  Name:         {token.name}")
        print(f"  Category:     {token.category.value}")
        print(f"  Supply:       {token.initial_supply} tokens")
        print(f"\n  Resonance Score:")
        print(f"    φ-coherence:  {token.resonance_score.phi_coherence:.4f}")
        print(f"    Utility:      {token.resonance_score.utility:.4f}")
        print(f"    Novelty:      {token.resonance_score.novelty:.4f}")
        print(f"    Provenance:   {token.resonance_score.provenance_depth:.4f}")
        print(f"    Composite:    {token.resonance_score.composite:.4f}")
        print(f"    Gate:         {'✅ PASSED' if token.resonance_score.passed_threshold else '❌ FAILED'}")
    else:
        print(f"  ❌ Token rejected — resonance below threshold")

    # ─────────────────────────────────────────────────────────────
    separator("DEMO COMPLETE")
    print("  PARALLAX Exchange Clearinghouse — sovereign computation demonstrated.")
    print(f"  📄 Zenodo: https://zenodo.org/records/20370721")
    print(f"  📊 37 views · 144 downloads")
    print()


if __name__ == "__main__":
    main()
