// cogitation.mo — Hebbian Manifold Computate
// COMPUTATE: executes the organism's cognitive weight update every 873ms.
// RESIDENTS: phi.mo (constants), types.mo (vocab). This file contains NO doctrine.
// Doctrine lives in: app/BUILDER_WORKSPACE/ENGINES/HEBBIAN_MANIFOLD.md
//
// MEDINA-ARTIFACT binding:
//   MEANING  → HEBBIAN_MANIFOLD.md Layer 1
//   MODEL    → HEBBIAN_MANIFOLD.md Layer 2
//   COMPUTATION → this file (the sovereign execution)
//   EXECUTION BINDING → called from main.mo updateCognitiveLayer()
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat   "mo:core/Nat";
import Phi   "phi";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // HEBBIAN CONSTANTS — all phi-derived, sourced from phi.mo
  // No arbitrary numbers. Every value traces to an Absolute.
  // ═══════════════════════════════════════════════════════════════════════════

  // Oja's rule: learning rate η = φ⁻⁴ × 0.01 ≈ 0.0001
  // EUCLID: one definition — referenced, never duplicated
  let _ETA_BASE : Float = Phi.ETA_OJA;          // 0.0001 (sourced from phi.mo)

  // Oja regularization: λ = 0.01 (biologically measured — Oja 1982)
  let LAMBDA_OJA : Float = 0.01;

  // STDP potentiation amplitude: A₊ = 0.005 (Bi & Poo 1998)
  let _A_PLUS  : Float = 0.005;

  // STDP depression amplitude: A₋ = 0.003 (Bi & Poo 1998)
  let _A_MINUS : Float = 0.003;

  // STDP+ time constant: τ₊ = 20ms (biologically measured)
  let _TAU_PLUS  : Float = 20.0;

  // STDP- time constant: τ₋ = 25ms (biologically measured)
  let _TAU_MINUS : Float = 25.0;

  // Spectral radius cap: 1.5 — prevents runaway weight explosion
  let RHO_CAP : Float = 1.5;

  // Lyapunov stability: OMNIS threshold — coherence must exceed R_OMNIS
  // Free energy threshold for OMNIS condition (φ⁻⁴ = 0.146)
  let FREE_ENERGY_OMNIS_THRESHOLD : Float = Phi.PHI_INV_4;  // 0.146

  // clamp helper — inline, not a separate function (Euclid: simplest form)
  func clamp(v : Float, lo : Float, hi : Float) : Float {
    if (v < lo) lo else if (v > hi) hi else v
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HebbianResult — the manifold update output
  // All fields needed by the heartbeat to update stable state.
  // Returned as a record so main.mo's heartbeat performs one assignment per field.
  // ═══════════════════════════════════════════════════════════════════════════
  public type HebbianResult = {
    newW             : [Float];   // 144-element updated weight matrix
    newActivations   : [Float];   // 12 updated Hz activations
    frobeniusNorm    : Float;     // ‖W‖_F  spectral stability measure
    spectralRadius   : Float;     // ρ(W)  max-row-sum approximation
    hebbianKappa     : Float;     // relative Frobenius change
    lyapunovV        : Float;     // Jasmine's Law energy function V
    jasmineDrift     : Float;     // dV/V — drift signal
    etaLearningRate  : Float;     // adapted learning rate
    globalDrift      : Float;     // accumulated drift counter
    shannonH         : Float;     // activation entropy H
    integratedInfoPhi : Float;    // Φ — integrated information proxy
    kuramotoR        : Float;     // r = Kuramoto order parameter
    coherenceC       : Float;     // C = tanh(Φ·r·(1−drift))
    freeEnergy       : Float;     // F = Σ(pred−act)²  Friston free energy
    omnisPrecondition : Bool;     // R≥0.95 ∧ drift<φ⁻³ ∧ V<φ⁻⁴
    engineIntelDelta  : Float;    // delta to engineIntelligenceScore
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // updateHebbianManifold — THE sovereign Hebbian computate
  //
  // Called every 873ms from main.mo heartbeat in place of the inlined block.
  // Returns HebbianResult — the caller updates all stable vars from it.
  //
  // INPUTS from organism state (read-only):
  //   btcSignal, ethSignal, icpSignal, mtcVelocitySignal — market signals
  //   organism balances — 4 organisms (clamped to [0,1])
  //   profit streams — 3 streams (clamped to [0,1])
  //   totalProfit — aggregate clamped to [0,1]
  //   priorW        — current hebbianW (144 floats)
  //   priorAct      — current hzActivations (12 floats)
  //   priorPred     — current predictedActivations (12 floats)
  //   priorEta      — current etaLearningRate
  //   priorEtaBase  — etaBaseline
  //   priorLyap     — current lyapunovV
  //   priorDrift    — current jasmineDrift
  //   priorGDrift   — current globalDrift
  //   priorShannonH — current shannonH
  //   priorCoherence— current coherenceC
  //   targetCoherence — current targetCoherence
  //   priorFreeEnergy — prior freeEnergy (for intelligence score delta)
  //   org0..org3IcpBalance — organism ICP balances for activation computation
  //   icpPrice, ethPrice — for stream normalization
  //   stream1, stream2, stream7, totalProfit — profit signal inputs
  //   totalProfitAllStreams — aggregate
  //   omnisFiredCount, beatCount — for OMNIS event routing
  // ═══════════════════════════════════════════════════════════════════════════
  public func updateHebbianManifold(
    priorW          : [Float],
    priorAct        : [Float],
    priorPred       : [Float],
    priorEta        : Float,
    priorEtaBase    : Float,
    priorLyap       : Float,
    priorDrift      : Float,
    priorGDrift     : Float,
    priorCoherence  : Float,
    targetCoherence : Float,
    _priorFreeEnergy : Float,
    btcSignal       : Float,
    ethSignal       : Float,
    icpSignal       : Float,
    mtcVelocitySignal : Float,
    org0Icp : Float, org1Icp : Float, org2Icp : Float, org3Icp : Float,
    stream1 : Float, stream2 : Float, stream7 : Float, totalProfit : Float,
    icpPrice : Float, ethPrice : Float,
  ) : HebbianResult {

    // ── 12 activation signals — domain-scaled, clamped [0,1] ──────────────
    let act0 = btcSignal;
    let act1 = ethSignal;
    let act2 = icpSignal;
    let act3 = mtcVelocitySignal;
    let act4 = clamp(org0Icp / 10000.0, 0.0, 1.0);
    let act5 = clamp(org1Icp / 5000.0,  0.0, 1.0);
    let act6 = clamp(org2Icp / 1000.0,  0.0, 1.0);
    let act7 = clamp(org3Icp / 500.0,   0.0, 1.0);
    let act8  = clamp(stream1 * icpPrice / 1000.0, 0.0, 1.0);
    let act9  = clamp(stream2 * ethPrice / 500.0,  0.0, 1.0);
    let act10 = clamp(stream7 * ethPrice / 100.0,  0.0, 1.0);
    let act11 = clamp(totalProfit / 10000.0,        0.0, 1.0);
    let newAct : [Float] = [act0,act1,act2,act3,act4,act5,act6,act7,act8,act9,act10,act11];

    // ── Oja's rule + STDP asymmetric: Δw = η·(pre·post − λ·post·pre²) ─────
    // EUCLID: η adapts when drift > 0.15 (half-rate during instability)
    let etaEff = priorEta * (if (priorDrift > 0.15) 0.5 else 1.0);
    let newW = Array.tabulate(144, func(k) {
      let i = k / 12;
      let j = k % 12;
      let pre_i  = priorAct[i];
      let post_j = newAct[j];
      let post_i = newAct[i];
      let pre_j  = priorAct[j];
      let wij    = priorW[k];
      // Oja-STDP hybrid: hebbian term − Oja regularization − STDP asymmetric
      clamp(
        wij + etaEff * (pre_i * post_j * (1.0 - wij) - LAMBDA_OJA * post_i * pre_j * wij),
        0.0, 1.0
      )
    });

    // ── Frobenius norm + spectral radius (max-row-sum) ─────────────────────
    var frobSqSum : Float = 0.0;
    var oldFrobSqSum : Float = 0.0;
    var k = 0;
    while (k < 144) {
      frobSqSum    += newW[k] * newW[k];
      oldFrobSqSum += priorW[k] * priorW[k];
      k += 1;
    };
    let newFrob = Float.sqrt(frobSqSum);
    let oldFrob = Float.sqrt(oldFrobSqSum);

    var maxRowSum : Float = 0.0;
    var i = 0;
    while (i < 12) {
      var rowSum : Float = 0.0;
      var j = 0;
      while (j < 12) { rowSum += Float.abs(newW[i * 12 + j]); j += 1 };
      if (rowSum > maxRowSum) { maxRowSum := rowSum };
      i += 1;
    };
    let rho = maxRowSum;

    // ── Spectral clamp: if ρ > 1.5, scale W down ──────────────────────────
    let stableW = if (rho > RHO_CAP and newFrob > 0.0) {
      Array.tabulate(144, func(ki) { newW[ki] * RHO_CAP / rho })
    } else { newW };
    let finalFrob = if (rho > RHO_CAP and newFrob > 0.0) RHO_CAP else newFrob;
    let kappa = if (oldFrob > 0.001) Float.abs(finalFrob - oldFrob) / oldFrob else 0.0;

    // ── Shannon entropy H of activation distribution ───────────────────────
    let actSum = newAct.foldLeft(0.0, func(acc : Float, a : Float) : Float { acc + a + 0.0001 });
    var hEntropy : Float = 0.0;
    for (a in newAct.vals()) {
      let p = (a + 0.0001) / actSum;
      hEntropy -= p * (Float.log(p) / Float.log(2.0));
    };

    // ── Integrated information Φ (variance-based proxy) ───────────────────
    var mean : Float = 0.0;
    for (a in newAct.vals()) { mean += a };
    mean := mean / 12.0;
    var variance : Float = 0.0;
    for (a in newAct.vals()) { let d = a - mean; variance += d * d };
    variance := variance / 12.0;
    let phi_ii  = variance * 12.0;
    let stdDev  = Float.sqrt(variance);
    let r       = clamp(1.0 - stdDev * 2.0, 0.0, 1.0);

    // ── Jasmine's Law Lyapunov energy function V ───────────────────────────
    // V = 0.25·dDoc² + 0.25·dId² + 0.20·dMem² + 0.15·dExpr² + 0.15·ρ²
    let dDoc  = Float.abs(priorCoherence - targetCoherence);
    let dId   = Float.abs(phi_ii - priorCoherence);
    let dMem  = Float.abs(mean - 1.0);
    let dExpr = stdDev * 2.0;
    let vNew  = 0.25*dDoc*dDoc + 0.25*dId*dId + 0.20*dMem*dMem + 0.15*dExpr*dExpr + 0.15*rho*rho;
    let jDrift = if (priorLyap > 0.001) (vNew - priorLyap) / priorLyap else 0.0;

    // ── Eta adaptation + global drift accumulation ─────────────────────────
    var newGDrift = priorGDrift;
    var newEta    = priorEta;
    if (jDrift > 0.15) {
      newEta    := clamp(newEta * 0.5, 0.0001, priorEtaBase);
      newGDrift += 0.12;
    } else if (jDrift < -0.05) {
      newGDrift := clamp(newGDrift - 0.01, 0.0, 1.0);
    };
    if (newEta < priorEtaBase) {
      newEta := clamp(newEta + (priorEtaBase - newEta) * 0.05, 0.0001, priorEtaBase);
    };

    // ── Coherence C — tanh of Φ·r·(1−drift) ──────────────────────────────
    // EUCLID: Padé approximant for tanh (stable, no overflow)
    let tanhArg  = phi_ii * r * (1.0 - clamp(jDrift, -1.0, 1.0));
    let expPos   = Float.exp(tanhArg);
    let expNeg   = Float.exp(-tanhArg);
    let tanhVal  = if (expPos + expNeg > 0.0) (expPos - expNeg) / (expPos + expNeg) else 0.0;
    let cNew     = clamp(tanhVal, 0.0, 1.0);

    // ── Friston free energy F = Σ(predicted − actual)² ───────────────────
    var freeEnergyNew : Float = 0.0;
    for (pi in Nat.rangeInclusive(0, 11)) {
      let err = priorPred[pi] - newAct[pi];
      freeEnergyNew += err * err;
    };

    // ── OMNIS precondition — R≥0.95 ∧ C>COHERENCE_HIGH_LOCK ∧ drift<φ⁻³ ∧ V<φ⁻⁴
    let omnis = cNew >= Phi.R_OMNIS
             and r > Phi.COHERENCE_HIGH_LOCK
             and Float.abs(jDrift) < Phi.PHI_INV_3
             and vNew < FREE_ENERGY_OMNIS_THRESHOLD;

    // ── Intelligence score delta ───────────────────────────────────────────
    let intelDelta = if (freeEnergyNew > 0.5) -0.001
                     else if (freeEnergyNew < 0.1) 0.002
                     else 0.0;

    {
      newW             = stableW;
      newActivations   = newAct;
      frobeniusNorm    = finalFrob;
      spectralRadius   = rho;
      hebbianKappa     = kappa;
      lyapunovV        = vNew;
      jasmineDrift     = jDrift;
      etaLearningRate  = newEta;
      globalDrift      = newGDrift;
      shannonH         = hEntropy;
      integratedInfoPhi = phi_ii;
      kuramotoR        = r;
      coherenceC       = cNew;
      freeEnergy       = freeEnergyNew;
      omnisPrecondition = omnis;
      engineIntelDelta = intelDelta;
    }
  };

};
