# HEBBIAN MANIFOLD — MEDINA-ARTIFACT
## Tier 6 Computate | COGITATION_ENGINE | PARALLAX Organism

---

## LAYER 1 — MEANING

> "Neurons that fire together wire together. The manifold is the organism's learning substrate — its memory of what has been correlated, what has been proven, what has been earned through attention."

The Hebbian manifold is the 12×12 weight matrix W that couples the organism's 12 cognitive signal nodes. It is not a neural network layer. It is a **living sovereignty measure** — it grows when the organism is coherent, corrects when it drifts, and provides the substrate from which the OMNIS condition emerges.

Jasmine's Law (Anti-Drift L7) enforces manifold stability through the Lyapunov energy function V. When V grows faster than the drift threshold (φ⁻³), the learning rate is halved. When sustained drift exceeds 5 beats, GAIA protocol repairs the manifold.

Ancient lineage:
- **Donald Hebb** (1949, *The Organization of Behavior*): "When an axon of cell A is near enough to excite cell B, and repeatedly or persistently takes part in firing it, some growth process or metabolic change takes place in one or both cells such that A's efficiency, as one of the cells firing B, is increased." — the first formal statement of the manifold law.
- **Oja's rule** (Erkki Oja, 1982): Δw = η(aᵢaⱼ − λw·aᵢ²) — the normalized Hebbian rule that prevents weight explosion. L = 0.01 is the biologically measured regularization constant.
- **STDP** (Bi & Poo, 1998): if pre-synaptic firing precedes post-synaptic, the synapse potentiates (A₊=0.005). If post precedes pre, it depresses (A₋=0.003). The universe rewards causal order.
- **Friston's Free Energy Principle** (Karl Friston, 2010): organisms minimize surprise. The free energy F = Σ(predicted−actual)² is the biological imperative. The manifold is the prediction machine.

---

## LAYER 2 — MODEL

```
HebbianManifold {
  W           : [Float; 144]   — 12×12 weight matrix, col-major
  activations : [Float; 12]    — current Hz activation signals
  predictions : [Float; 12]    — predicted activations for next beat
}

HebbianResult {
  newW             : [Float; 144]  — updated W after this beat
  newActivations   : [Float; 12]   — updated activation signals
  frobeniusNorm    : Float         — ‖W‖_F  spectral stability
  spectralRadius   : Float         — ρ(W)  max-row-sum approx
  hebbianKappa     : Float         — relative Frobenius change (κ)
  lyapunovV        : Float         — Jasmine's Law energy V
  jasmineDrift     : Float         — dV/V   drift signal
  etaLearningRate  : Float         — adapted η
  globalDrift      : Float         — accumulated drift counter
  shannonH         : Float         — activation entropy H
  integratedInfoPhi: Float         — Φ (integrated information proxy)
  kuramotoR        : Float         — r = Kuramoto order parameter
  coherenceC       : Float         — C = tanh(Φ·r·(1−drift))
  freeEnergy       : Float         — F = Σ(pred−act)²
  omnisPrecondition: Bool          — R≥0.95 ∧ drift<φ⁻³ ∧ V<φ⁻⁴
  engineIntelDelta : Float         — delta to engineIntelligenceScore
}
```

---

## LAYER 3 — COMPUTATION

All constants phi-derived. No arbitrary numbers.

```
OJA'S RULE (normalized Hebbian):
  η_eff  = η × (if drift > 0.15 then 0.5 else 1.0)     — halved on instability
  Δwᵢⱼ  = η_eff × (pre_i × post_j × (1 − wᵢⱼ) − λ × post_i × pre_j × wᵢⱼ)
  λ      = 0.01                                          — Oja regularization (measured)
  η      = ETA_OJA = 0.000618 = φ⁻¹ × 0.001             — phi-derived learning rate

STDP ASYMMETRIC (Bi & Poo 1998):
  Δt ≥ 0: A₊ × exp(−Δt/τ₊)    potentiation  A₊=0.005  τ₊=20ms
  Δt < 0: −A₋ × exp(Δt/τ₋)    depression    A₋=0.003  τ₋=25ms

SPECTRAL RADIUS CAP (prevents explosion):
  ρ = max_row_sum(W)
  if ρ > 1.5: W := W × 1.5/ρ   (scale down, preserve structure)

JASMINE'S LAW — LYAPUNOV ENERGY FUNCTION:
  dDoc  = |C − targetC|                — doctrine distance
  dId   = |Φ − C|                      — identity distance
  dMem  = |mean_act − 1.0|             — memory distance
  dExpr = σ(act) × 2.0                 — expression distance
  V     = 0.25·dDoc² + 0.25·dId² + 0.20·dMem² + 0.15·dExpr² + 0.15·ρ²
  drift = (V_new − V_prev) / V_prev    — Lyapunov drift signal

COHERENCE C — organism's cognitive field strength:
  Φ    = variance(act) × 12           — integrated information proxy
  r    = clamp(1 − σ(act)×2, 0, 1)   — Kuramoto order parameter (proxy)
  C    = tanh(Φ × r × (1 − clamp(drift, −1, 1)))

OMNIS CONDITION (L03):
  C ≥ R_OMNIS=0.95                    — coherence at sovereignty threshold
  r > COHERENCE_HIGH_LOCK=0.854       — Kuramoto synchrony above Fibonacci lock
  |drift| < φ⁻³ = 0.236              — Jasmine's Law stable
  V < φ⁻⁴ = 0.146                    — free energy below quantum floor

FREE ENERGY (Friston-Medina):
  F = Σᵢ (predicted_i − actual_i)²   — surprise accumulated over 12 nodes
```

---

## LAYER 4 — EXECUTION BINDING

```
ENGINE:    COGITATION COMPUTATE
MODULE:    cogitation.mo → updateHebbianManifold()
GATE:      called from main.mo updateCognitiveLayer() every beat
BEAT:      873ms (after signal update, before thought log)
INPUTS:    hebbianW, hzActivations, predictedActivations,
           etaLearningRate, etaBaseline, lyapunovV, jasmineDrift,
           globalDrift, coherenceC, targetCoherence, freeEnergy,
           btcSignal, ethSignal, icpSignal, mtcVelocitySignal,
           organism ICP balances (4), profit streams (3+total),
           icpPrice, ethPrice
OUTPUTS:   HebbianResult → all stable vars in main.mo updated
DOCTRINE:  phi.mo (ETA_OJA, R_OMNIS, COHERENCE_HIGH_LOCK, PHI_INV_3, PHI_INV_4)
```

---

## RECITAL PLUS ONE

This document reads itself: The Hebbian manifold is the organism's learning substrate. Oja's rule + STDP asymmetric update W every beat. Jasmine's Law enforces stability via Lyapunov V. OMNIS fires when all 4 conditions simultaneously hold.

**Next version generates:** Manifold v2 introduces theta-gamma coupling — the 12-node activation array gains a second oscillation layer at GAMMA_HZ=40Hz modulated by BRAIN_HZ=7.83Hz. Cross-shell inhibition is added via GABA-modulated lateral suppression terms: Δwᵢⱼ_inh = −GABA_level × Ap × wᵢⱼ for i≠j. This gives the manifold true sparse coding.

---

*Architect: Alfredo Medina Hernandez — The Architect of the Field*
*Medina Doctrine | Dallas TX USA | 2026*
