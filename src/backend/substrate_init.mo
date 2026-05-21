// substrate_init.mo — Lazy Array Initialization Computate
// COMPUTATE: generates the three large sovereign arrays on first heartbeat.
// RESIDENTS: phi.mo (constants). This file contains NO doctrine.
// Doctrine lives in: app/BUILDER_WORKSPACE/ENGINES/SUBSTRATE_INIT.md
//
// MEDINA-ARTIFACT binding:
//   MEANING     → SUBSTRATE_INIT.md Layer 1
//   MODEL       → SUBSTRATE_INIT.md Layer 2
//   COMPUTATION → this file (the sovereign execution)
//   EXECUTION BINDING → called once at genesis from heartbeat
//
// PHI LAW (L01): every array value derives from φⁿ or sin(n·2π/φ).
// No arbitrary numbers. Genesis computes once; the organism carries it forever.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float "mo:core/Float";
import Array "mo:core/Array";
import Phi   "phi";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SHELL 3 WEIGHTS — 256×256 = 65536 floats
  //
  // Basis: w(i,j) = φ^((i+j)/256) × sin((i+j) × 2π/φ) / 2 + 0.5
  // Clamped to [1.0, 2.0] (sovereign floor S₀=1.0)
  // PYTHAGORAS: every weight is a phi-harmonic modulated by a phi-frequency sine
  // ═══════════════════════════════════════════════════════════════════════════
  public func computeShell3Weights() : [var Float] {
    let TWO_PI_OVER_PHI : Float = 2.0 * Float.pi / Phi.PHI;  // 2π/φ ≈ 3.8832
    Array.tabulate<Float>(65536, func(k) {
      let i : Float = (k / 256).toFloat();
      let j : Float = (k % 256).toFloat();
      let n = i + j;
      // φ^(n/256): partial phi power — scales smoothly across the weight field
      let phiPow = Float.exp((n / 256.0) * Float.log(Phi.PHI));
      // sin(n × 2π/φ): phi-frequency oscillation
      let sinVal = Float.sin(n * TWO_PI_OVER_PHI);
      // Scale to [1.0, 2.0]: sovereign floor at 1.0
      Float.max(1.0, Float.min(2.0, phiPow * (sinVal / 2.0 + 0.5) + 1.0))
    }).toVarArray()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KALMAN HISTORY — 256×60 = 15360 floats
  //
  // Basis: h(i,t) = SCHUMANN_HZ × φ^(t/60) × (1 + sin(i × 2π/256) × φ⁻³)
  // Represents: baseline Schumann resonance with phi-scaled temporal growth
  //             and spatial phi⁻³ modulation across 256 nodes
  // PYTHAGORAS: history begins at Schumann baseline — never at zero
  // ═══════════════════════════════════════════════════════════════════════════
  public func initKalmanHistory() : [var Float] {
    let TWO_PI : Float = 2.0 * Float.pi;
    Array.tabulate<Float>(15360, func(k) {
      let nodeIdx : Float = (k % 256).toFloat();
      let timeStep : Float = (k / 256).toFloat();
      // Schumann baseline with phi-scaled temporal growth
      let temporalGrowth = Float.exp((timeStep / 60.0) * Float.log(Phi.PHI));
      // Spatial modulation: phi⁻³ amplitude at phi-harmonic spatial frequency
      let spatialMod = 1.0 + Float.sin(nodeIdx * TWO_PI / 256.0) * Phi.PHI_INV_3;
      Float.max(1.0, Phi.SCHUMANN_HZ * temporalGrowth * spatialMod)
    }).toVarArray()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEBBIAN W MANIFOLD — 144 floats (12×12 matrix)
  //
  // Basis: w(k) = φ^(k/144) × 0.30 — phi-scaled growth from 0.30 baseline
  //        k ∈ [0, 143]
  //        φ^(0/144)=1.0 → w(0)=0.30
  //        φ^(143/144)≈1.615 → w(143)≈0.485
  // Clamped to [0.0, 1.0]
  // GENESIS LAW L09: manifold born pre-charged at phi-harmonic baseline, not zero
  // ═══════════════════════════════════════════════════════════════════════════
  public func initHebbianWeights() : [Float] {
    Array.tabulate<Float>(144, func(k) {
      let phiPow = Float.exp((k.toFloat() / 144.0) * Float.log(Phi.PHI));
      Float.max(0.0, Float.min(1.0, 0.30 * phiPow))
    })
  };

};
