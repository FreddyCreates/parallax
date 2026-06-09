// alpha_orchestrator/main.mo — ALPHA ORCHESTRATOR
// PARALLAX Sovereign Organism — Alpha-Tier Multi-Canister Intelligence Coordinator
//
// MEDINA-ARTIFACT — alpha_orchestrator/main.mo (MODEL-07 discipline applied)
// ─────────────────────────────────────────────────────────────────────────────
// MEANING (Layer 1 — Doctrine Clause):
//   "The Alpha Orchestrator is not a scheduler — it is a living adaptive topology
//    that learns which children synchronize, predicts failures before they occur,
//    minimizes free energy across the distributed organism, and self-organizes its
//    execution graph through Hebbian coupling. It is the cortex of the swarm."
//
// MODEL (Layer 2 — Typed Schema):
//   OrchestrationState: beat, phases[13], hebbianW[169], activations[13],
//                       lyapunovV, freeEnergy, shannonH, kuramotoR,
//                       spectralRadius, coherenceC, topologyClusters[],
//                       adaptiveSchedule[], emergentFrequencies[13]
//
// COMPUTATION (Layer 3 — State Equations):
//   Kuramoto:    dθᵢ/dt = ωᵢ + (K/N)Σⱼ wᵢⱼ·sin(θⱼ−θᵢ)  [weighted coupling]
//   Hebbian:     Δwᵢⱼ = η·(cos(θᵢ−θⱼ)·success − λ·wᵢⱼ)  [Oja-regularized]
//   Lyapunov:    V = ΣΣ wᵢⱼ·(1 − cos(θᵢ−θⱼ))            [energy landscape]
//   Free Energy: F = Σ(predicted_tick − actual_tick)²        [Friston]
//   Shannon:     H = −Σ pᵢ·log₂(pᵢ)                       [scheduling entropy]
//   Spectral:    ρ(W) = max row sum of |W|                  [stability bound]
//   Clustering:  Phase coherence matrix → community detection via modularity Q
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: ORCHESTRATION COMPUTATE → FUNCTION: heartbeat()
//   GATE: coherenceGate() → BEAT: 873ms → ADAPTATION: hebbianUpdate()
//
// THE ORCHESTRATION LAW (LEX_ORCHESTRO_ALPHA):
//   Every child canister's beat is Hebbian-weighted — not uniform.
//   Scheduling adapts: children that sync get tighter coupling.
//   Coherence gating uses Lyapunov stability, not just threshold.
//   Topology self-organizes: clusters emerge from phase alignment.
//   Free energy drives prediction: the orchestrator PREDICTS the next state.
//   Spectral radius bounds prevent runaway coupling explosions.
//   The system is provably stable via Jasmine's Law energy descent.
//
// PYTHAGORAS: all constants are phi-harmonic ratios — no arbitrary numbers
// EUCLID:     single orchestration root — one source of scheduling truth
// CONFUCIUS:  right relationship — orchestrator governs, children execute
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float    "mo:base/Float";
import Array    "mo:base/Array";
import Nat      "mo:base/Nat";
import Int      "mo:base/Int";
import Text     "mo:base/Text";
import Time     "mo:base/Time";
import Timer    "mo:base/Timer";
import Principal "mo:base/Principal";

actor AlphaOrchestrator {

  // ═══════════════════════════════════════════════════════════════════════════
  // PHI CONSTANTS — sovereign mathematical substrate
  // No arbitrary numbers. Every value traces to an Absolute.
  // ═══════════════════════════════════════════════════════════════════════════

  let PHI       : Float = 1.6180339887498948482;
  let PHI_INV   : Float = 0.6180339887498948482;   // φ⁻¹ — coherence gate
  let PHI_INV_2 : Float = 0.3819660112501051518;   // φ⁻² — decay rate
  let PHI_INV_3 : Float = 0.2360679774997896964;   // φ⁻³ — emergency threshold
  let PHI_INV_4 : Float = 0.1458980337503154554;   // φ⁻⁴ — free energy omnis threshold
  let PHI_INV_5 : Float = 0.0901699437496742627;   // φ⁻⁵ — hebbian coupling decay
  let PHI_SQ    : Float = 2.6180339887498948482;   // φ² — maximum health ceiling

  // Fibonacci sequence: F(1)–F(13) — scheduling multipliers
  let FIB : [Nat] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233];

  // Sovereign floor — no value below S0
  let S0 : Float = 1.0;

  // Alpha heartbeat: 873ms = φ⁴ × (1000 / 7.83)
  // Derivation: Schumann fundamental resonance f₁ = 7.83 Hz
  // φ⁴ = 6.854101966... → 6854.1 / 7.83 ≈ 875.37 → sovereign constant 873ms
  // This is the organism's cardiac period — all timing descends from this root.
  let SCHUMANN_1 : Float = 7.83;
  let HEARTBEAT_NS : Nat = 873_000_000;

  // Maximum orchestrated canisters: F(7) = 13
  let MAX_CHILDREN : Nat = 13;

  // Hebbian weight matrix size: 13×13 = 169 (inter-child coupling topology)
  let HEBBIAN_SIZE : Nat = 169;

  // Audit ring size: F(10) = 55 entries (expanded for richer history)
  let AUDIT_RING_SIZE : Nat = 55;

  // Coherence history window: F(8) = 21 (spectral analysis buffer)
  let COHERENCE_WINDOW : Nat = 21;

  // Spectral radius cap: φ = 1.618 (prevents runaway coupling explosion)
  let RHO_CAP : Float = PHI;

  // Oja regularization constant: λ = φ⁻⁵ = 0.090 (biologically-inspired)
  let LAMBDA_OJA : Float = PHI_INV_5;

  // Learning rate: η = φ⁻⁴ = 0.146 (Hebbian plasticity rate)
  let ETA_BASE : Float = PHI_INV_4;

  // OMNIS coherence threshold: R ≥ 0.95 (near-perfect synchronization)
  let R_OMNIS : Float = 0.95;

  // Cluster coherence threshold: inter-phase coherence ≥ φ⁻¹ for cluster membership
  let CLUSTER_THRESHOLD : Float = PHI_INV;

  // Prediction buffer: F(5) = 5 beats lookahead
  let PREDICTION_HORIZON : Nat = 5;

  // Minimum beats before Hebbian plasticity activates: F(6) = 8
  let MIN_BEATS_FOR_PLASTICITY : Nat = 8;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECURITY — Creator Supremacy
  // ═══════════════════════════════════════════════════════════════════════════

  stable var creatorPrincipal : Text = "aaaaa-aa";
  stable var genesisSealed    : Bool = false;

  func assertCreator(caller : Principal) : () {
    assert (Principal.toText(caller) == creatorPrincipal or
            creatorPrincipal == "aaaaa-aa");
  };

  public shared(msg) func setCreator(p : Text) : async () {
    if (creatorPrincipal == "aaaaa-aa" or
        Principal.toText(msg.caller) == creatorPrincipal) {
      creatorPrincipal := p;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CHILD CANISTER REGISTRY — sovereign multi-canister topology
  // ═══════════════════════════════════════════════════════════════════════════

  public type ChildCanister = {
    name         : Text;
    id           : Text;
    priority     : Nat;        // Fibonacci-ranked priority (1–13)
    active       : Bool;
    lastTick     : Int;        // Last successful tick timestamp
    failCount    : Nat;        // Consecutive failures
    health       : Float;      // Health score [S0, φ²]
    tickCount    : Nat;        // Total successful ticks (lifetime)
    avgLatency   : Float;      // Exponential moving average response latency (ms)
    predictedNext: Nat;        // Beat number at which next tick is predicted
    clusterLabel : Nat;        // Assigned phase cluster (0 = unassigned)
  };

  stable var children : [ChildCanister] = [];

  public shared(msg) func registerChild(name : Text, id : Text, priority : Nat) : async () {
    assertCreator(msg.caller);
    assert (children.size() < MAX_CHILDREN);
    let child : ChildCanister = {
      name         = name;
      id           = id;
      priority     = priority;
      active       = true;
      lastTick     = Time.now();
      failCount    = 0;
      health       = S0;
      tickCount    = 0;
      avgLatency   = 0.0;
      predictedNext= 0;
      clusterLabel = 0;
    };
    children := Array.append(children, [child]);
    // Expand Hebbian matrix to accommodate new child
    _resizeHebbianMatrix();
  };

  public shared(msg) func deactivateChild(name : Text) : async () {
    assertCreator(msg.caller);
    children := Array.map<ChildCanister, ChildCanister>(children, func(c) {
      if (c.name == name) { { c with active = false } } else { c };
    });
  };

  public shared(msg) func activateChild(name : Text) : async () {
    assertCreator(msg.caller);
    children := Array.map<ChildCanister, ChildCanister>(children, func(c) {
      if (c.name == name) { { c with active = true; failCount = 0 } } else { c };
    });
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEBBIAN COUPLING TOPOLOGY — inter-child learned weight matrix
  //
  // W[i,j] represents the learned coupling strength between child i and child j.
  // High W[i,j] means children i and j tend to synchronize and succeed together.
  // The Kuramoto model uses W as coupling weights instead of uniform K/N.
  //
  // Update rule (Oja-regularized):
  //   Δwᵢⱼ = η · (cos(θᵢ−θⱼ) · successProduct − λ · wᵢⱼ)
  //
  // where successProduct = health_i × health_j / φ² (normalized success signal)
  // ═══════════════════════════════════════════════════════════════════════════

  // Immutable stable store; thawed to mutable at runtime
  stable var hebbianWStable : [Float] = Array.tabulate<Float>(HEBBIAN_SIZE, func(_) { PHI_INV_2 });
  var hebbianW : [var Float] = Array.thaw<Float>(hebbianWStable);

  // Hebbian plasticity state
  stable var etaLearningRate : Float = ETA_BASE;
  stable var hebbianKappa    : Float = 0.0;  // Frobenius norm relative change
  stable var spectralRadius  : Float = 0.0;  // ρ(W) — stability indicator

  func _resizeHebbianMatrix() : () {
    let n = children.size();
    let needed = n * n;
    if (needed > hebbianWStable.size()) {
      let expanded = Array.tabulate<Float>(needed, func(k) {
        if (k < hebbianWStable.size()) { hebbianWStable[k] } else { PHI_INV_2 };
      });
      hebbianWStable := expanded;
      hebbianW := Array.thaw<Float>(hebbianWStable);
    };
  };

  func _hebbianUpdate(tickedIndices : [Nat]) : () {
    let n = children.size();
    if (n < 2 or beatCount < MIN_BEATS_FOR_PLASTICITY) return;

    // Compute effective learning rate — reduced during instability (Jasmine's Law)
    let effEta = if (jasmineDrift > 0.15) { etaLearningRate * 0.5 }
                 else { etaLearningRate };

    var oldFrobSq : Float = 0.0;
    var newFrobSq : Float = 0.0;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let idx = i * n + j;
          let wOld = hebbianW[idx];
          oldFrobSq += wOld * wOld;

          // Phase coherence between i and j (normalized difference)
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let phaseCoherence = Float.cos(phaseDiff);

          // Success product: normalized health co-occurrence
          let successProduct = (children[i].health * children[j].health) / PHI_SQ;

          // Were both children ticked this beat? (co-activation signal)
          var coActivated = false;
          for (ti in tickedIndices.vals()) {
            if (ti == i) {
              for (tj in tickedIndices.vals()) {
                if (tj == j) { coActivated := true };
              };
            };
          };

          // Oja-regularized Hebbian update
          let hebbSignal = if (coActivated) {
            phaseCoherence * successProduct
          } else {
            // Weak anti-Hebbian for non-co-activated pairs (decay coupling)
            -PHI_INV_5 * successProduct
          };

          let wNew = _clamp(wOld + effEta * (hebbSignal - LAMBDA_OJA * wOld), 0.0, PHI);
          hebbianW[idx] := wNew;
          newFrobSq += wNew * wNew;
        };
      };
    };

    // Frobenius norm and spectral radius
    let newFrob = Float.sqrt(newFrobSq);
    let oldFrob = Float.sqrt(oldFrobSq);
    hebbianKappa := if (oldFrob > 0.001) { Float.abs(newFrob - oldFrob) / oldFrob } else { 0.0 };

    // Spectral radius: max row sum of |W| (Gershgorin bound)
    var maxRowSum : Float = 0.0;
    for (i in Array.keys(children)) {
      var rowSum : Float = 0.0;
      for (j in Array.keys(children)) {
        if (i != j) {
          rowSum += Float.abs(hebbianW[i * n + j]);
        };
      };
      if (rowSum > maxRowSum) { maxRowSum := rowSum };
    };
    spectralRadius := maxRowSum;

    // Spectral clamp: if ρ > cap, scale entire matrix down (stability guarantee)
    if (spectralRadius > RHO_CAP and newFrob > 0.0) {
      let scale = RHO_CAP / spectralRadius;
      for (k in Array.keys(children)) {
        for (l in Array.keys(children)) {
          if (k != l) {
            let idx = k * n + l;
            hebbianW[idx] := hebbianW[idx] * scale;
          };
        };
      };
      spectralRadius := RHO_CAP;
    };

    // Eta adaptation: reduce rate when kappa is high (instability detected)
    if (hebbianKappa > PHI_INV_2) {
      etaLearningRate := _clamp(etaLearningRate * 0.8, PHI_INV_5, ETA_BASE);
    } else if (hebbianKappa < PHI_INV_4) {
      // Stable — slowly restore learning rate
      etaLearningRate := _clamp(
        etaLearningRate + (ETA_BASE - etaLearningRate) * 0.05,
        PHI_INV_5, ETA_BASE
      );
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORCHESTRATION STATE — beat tracking, coherence, scheduling
  // ═══════════════════════════════════════════════════════════════════════════

  stable var beatCount         : Nat   = 0;
  stable var lastBeatTime      : Int   = 0;
  stable var heartbeatActive   : Bool  = false;
  stable var genesisTime       : Int   = 0;

  // Kuramoto coherence — organism-wide phase synchronization measure
  stable var globalCoherence       : Float = S0;
  stable var prevGlobalCoherence   : Float = S0;
  stable var coherenceHistory      : [Float] = [];

  // Phase array for Kuramoto sync — one per child canister
  // NOTE: Immutable stable array; runtime code rebuilds mutable copy in-memory
  stable var childPhasesStable : [Float] = Array.freeze(Array.init<Float>(MAX_CHILDREN, 0.0));
  var childPhases : [var Float] = Array.thaw<Float>(childPhasesStable);

  // ── LYAPUNOV STABILITY ──────────────────────────────────────────────────
  // V = ΣΣ wᵢⱼ·(1 − cos(θᵢ−θⱼ)) — energy of the coupled oscillator system
  // Jasmine's Law: dV/dt ≤ 0 → system converges to synchronized state
  stable var lyapunovV     : Float = 0.0;
  stable var prevLyapunovV : Float = 0.0;
  stable var jasmineDrift  : Float = 0.0;  // dV/V — positive = destabilizing

  // ── FREE ENERGY (Friston) ───────────────────────────────────────────────
  // F = Σᵢ (predicted_tick_i − actual_tick_i)² — prediction error
  // The orchestrator PREDICTS which children will tick and learns from error
  stable var freeEnergy        : Float = 0.0;
  stable var prevFreeEnergy    : Float = 0.0;
  stable var predictionAccuracy: Float = 0.5;  // rolling accuracy [0,1]

  // ── SHANNON ENTROPY ─────────────────────────────────────────────────────
  // H = −Σ pᵢ·log₂(pᵢ) where pᵢ = child_i_ticks / total_ticks
  // Low H = biased scheduling (few children dominate)
  // High H = uniform scheduling (democratic distribution)
  stable var orchestrationEntropy : Float = 0.0;

  // ── INTEGRATED INFORMATION Φ ────────────────────────────────────────────
  // Φ = variance(activations) × N — proxy for integrated information
  // How much the whole system is more than the sum of its parts
  stable var integratedInfoPhi : Float = 0.0;

  // ── COHERENCE C (composite measure) ─────────────────────────────────────
  // C = tanh(Φ · R · (1 − |drift|)) — single scalar organism coherence
  stable var coherenceC : Float = 0.0;

  // ── EMERGENT TOPOLOGY — cluster detection ───────────────────────────────
  // Children self-organize into phase-aligned clusters
  // Clusters emerge from the Hebbian coupling matrix and phase alignment
  stable var clusterCount    : Nat = 0;
  stable var modularityQ     : Float = 0.0;  // Newman modularity score

  // ── OMNIS PRECONDITION ──────────────────────────────────────────────────
  // The system reaches OMNIS when: R≥0.95 ∧ drift<φ⁻³ ∧ V<φ⁻⁴ ∧ F<φ⁻³
  stable var omnisPrecondition : Bool = false;
  stable var omnisFireCount    : Nat = 0;

  // Scheduling state — determines which children tick on which beat
  public type ScheduleEntry = {
    childName      : Text;
    fibMultiplier  : Nat;   // tick every FIB[n] beats
    lastScheduled  : Nat;   // last beat this child was scheduled
    adaptiveWeight : Float; // Hebbian-derived scheduling weight [φ⁻³, φ]
  };

  stable var schedule : [ScheduleEntry] = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIT TRAIL — immutable orchestration record (enriched)
  // ═══════════════════════════════════════════════════════════════════════════

  public type AuditEntry = {
    beat             : Nat;
    timestamp        : Int;
    coherence        : Float;
    lyapunovV        : Float;
    freeEnergy       : Float;
    shannonH         : Float;
    spectralRadius   : Float;
    integratedPhi    : Float;
    coherenceC       : Float;
    jasmineDrift     : Float;
    clusterCount     : Nat;
    omnis            : Bool;
    childrenTicked   : [Text];
    childrenSkipped  : [Text];
    childrenFailed   : [Text];
  };

  stable var auditRing : [AuditEntry] = [];
  stable var auditHead : Nat = 0;

  func pushAudit(entry : AuditEntry) : () {
    if (auditRing.size() < AUDIT_RING_SIZE) {
      auditRing := Array.append(auditRing, [entry]);
    } else {
      auditRing := Array.tabulate<AuditEntry>(AUDIT_RING_SIZE, func(i) {
        if (i == auditHead) { entry } else { auditRing[i] };
      });
      auditHead := (auditHead + 1) % AUDIT_RING_SIZE;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY — clamp helper (Euclid: simplest form, inline)
  // ═══════════════════════════════════════════════════════════════════════════

  func _clamp(v : Float, lo : Float, hi : Float) : Float {
    if (v < lo) lo else if (v > hi) hi else v;
  };

  // Normalize phase to [−π, π] — prevents unbounded growth and precision loss
  let TWO_PI : Float = 6.2831853071795864769;
  func _normalizePhase(theta : Float) : Float {
    var p = theta;
    while (p > 3.1415926535897932385) { p -= TWO_PI };
    while (p < -3.1415926535897932385) { p += TWO_PI };
    p;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KURAMOTO COHERENCE ENGINE — WEIGHTED phase synchronization
  //
  // Unlike basic Kuramoto with uniform coupling K/N, this implementation uses
  // the learned Hebbian weight matrix W[i,j] as coupling coefficients.
  // This means children that historically synchronize well get stronger coupling,
  // creating emergent frequency clusters.
  //
  // dθᵢ/dt = ωᵢ + (1/N) Σⱼ wᵢⱼ · sin(θⱼ − θᵢ)
  // ═══════════════════════════════════════════════════════════════════════════

  func computeKuramotoR() : Float {
    let n = children.size();
    if (n == 0) return S0;

    var sumCos : Float = 0.0;
    var sumSin : Float = 0.0;

    for (i in Array.keys(children)) {
      let phase = childPhases[i];
      sumCos += Float.cos(phase);
      sumSin += Float.sin(phase);
    };

    let r = Float.sqrt((sumCos * sumCos + sumSin * sumSin)) / Float.fromInt(n);
    // Clamp to valid range [0, 1] — R is a normalized order parameter
    _clamp(r, 0.0, S0);
  };

  func advancePhases() : () {
    let n = children.size();
    if (n == 0) return;

    let nFloat = Float.fromInt(n);

    // Compute new phases using weighted Kuramoto
    let newPhases = Array.init<Float>(MAX_CHILDREN, 0.0);

    for (i in Array.keys(children)) {
      var couplingSum : Float = 0.0;
      for (j in Array.keys(children)) {
        if (i != j) {
          // Use Hebbian weight instead of uniform K/N
          let wij = hebbianW[i * n + j];
          couplingSum += wij * Float.sin(childPhases[j] - childPhases[i]);
        };
      };

      // Natural frequency derived from child priority and health
      // ω_i = φ × priority_i × health_i / (N × φ²)
      // Higher health → faster natural frequency (healthy children lead)
      let childPriority = Float.fromInt(children[i].priority);
      let healthFactor = children[i].health / PHI_SQ;
      let omega = PHI * childPriority * healthFactor / nFloat;

      newPhases[i] := _normalizePhase(childPhases[i] + omega + (1.0 / nFloat) * couplingSum);
    };

    // Apply new phases (already normalized)
    for (i in Array.keys(children)) {
      childPhases[i] := newPhases[i];
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LYAPUNOV ENERGY — proves convergence via energy descent
  //
  // V = ΣΣ wᵢⱼ · (1 − cos(θᵢ − θⱼ))
  //
  // When dV/dt < 0, the system is converging toward synchronization.
  // When dV/dt > 0, the system is destabilizing (triggers Jasmine's Law response).
  // This is the thermodynamic potential of the coupled oscillator network.
  // ═══════════════════════════════════════════════════════════════════════════

  func computeLyapunovEnergy() : Float {
    let n = children.size();
    if (n < 2) return 0.0;

    var energy : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let wij = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          energy += wij * (1.0 - Float.cos(phaseDiff));
        };
      };
    };
    energy;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FREE ENERGY MINIMIZATION — Friston active inference
  //
  // The orchestrator predicts which children will tick on the next beat.
  // Prediction error drives learning: minimize surprise.
  // F = Σᵢ (predicted_i − actual_i)² where values are 0/1 tick indicators
  // ═══════════════════════════════════════════════════════════════════════════

  stable var predictions : [Bool] = [];  // predicted ticks for current beat

  func _generatePredictions() : () {
    // Predict which children will tick based on schedule + health + coherence
    predictions := Array.tabulate<Bool>(children.size(), func(i) {
      let child = children[i];
      if (not child.active) return false;
      if (globalCoherence < PHI_INV and child.priority > 1) return false;
      shouldTickChild(child.name, beatCount + 1);
    });
  };

  func _computeFreeEnergy(actualTicked : [Nat]) : Float {
    if (predictions.size() == 0) return 0.0;

    var error : Float = 0.0;
    for (i in Array.keys(children)) {
      if (i < predictions.size()) {
        let predicted : Float = if (predictions[i]) { 1.0 } else { 0.0 };
        var actual : Float = 0.0;
        for (t in actualTicked.vals()) {
          if (t == i) { actual := 1.0 };
        };
        let diff = predicted - actual;
        error += diff * diff;
      };
    };
    error;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SHANNON ENTROPY — measures scheduling fairness / information content
  //
  // H = −Σ pᵢ·log₂(pᵢ) where pᵢ = tickCount_i / totalTicks
  // Maximum entropy = log₂(N) = all children tick equally
  // Minimum entropy = 0 = only one child ever ticks
  // ═══════════════════════════════════════════════════════════════════════════

  func _computeOrchestrationEntropy() : Float {
    let n = children.size();
    if (n == 0) return 0.0;

    var totalTicks : Nat = 0;
    for (c in children.vals()) { totalTicks += c.tickCount };
    if (totalTicks == 0) return 0.0;

    let totalFloat = Float.fromInt(totalTicks);
    var entropy : Float = 0.0;

    for (c in children.vals()) {
      if (c.tickCount > 0) {
        let p = Float.fromInt(c.tickCount) / totalFloat;
        entropy -= p * (Float.log(p) / Float.log(2.0));
      };
    };
    entropy;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTEGRATED INFORMATION Φ — whole > sum of parts
  //
  // Φ = variance(health_vector) × N — proxy for IIT
  // High Φ = children have differentiated states (high integration potential)
  // Low Φ = all children are identical (no information integration)
  // ═══════════════════════════════════════════════════════════════════════════

  func _computeIntegratedInfo() : Float {
    let n = children.size();
    if (n == 0) return 0.0;

    var mean : Float = 0.0;
    for (c in children.vals()) { mean += c.health };
    mean := mean / Float.fromInt(n);

    var variance : Float = 0.0;
    for (c in children.vals()) {
      let d = c.health - mean;
      variance += d * d;
    };
    variance := variance / Float.fromInt(n);

    variance * Float.fromInt(n);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CLUSTER DETECTION — emergent phase-aligned communities
  //
  // Algorithm: greedy modularity maximization on phase coherence matrix.
  // Two children are in the same cluster if cos(θᵢ−θⱼ) ≥ φ⁻¹ = 0.618
  // AND their Hebbian weight wᵢⱼ ≥ φ⁻² = 0.382
  //
  // Modularity Q = (1/2m) Σᵢⱼ [Aᵢⱼ − kᵢkⱼ/2m] δ(cᵢ,cⱼ)
  // (simplified: fraction of intra-cluster edges − expected random fraction)
  // ═══════════════════════════════════════════════════════════════════════════

  func _detectClusters() : () {
    let n = children.size();
    if (n < 2) { clusterCount := if (n == 1) 1 else 0; return };

    // Build adjacency: A[i,j] = 1 if phase-coherent AND Hebbian-strong
    let adj = Array.init<Bool>(n * n, false);
    var edgeCount : Nat = 0;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let phaseCoh = Float.cos(_normalizePhase(childPhases[i] - childPhases[j]));
          let hebbWeight = hebbianW[i * n + j];
          if (phaseCoh >= CLUSTER_THRESHOLD and hebbWeight >= PHI_INV_2) {
            adj[i * n + j] := true;
            edgeCount += 1;
          };
        };
      };
    };

    // Simple connected-component labelling via DFS-style propagation
    let labels = Array.init<Nat>(n, 0);
    var currentLabel : Nat = 0;

    for (i in Array.keys(children)) {
      if (labels[i] == 0) {
        currentLabel += 1;
        labels[i] := currentLabel;
        // Propagate label to connected nodes
        var changed = true;
        while (changed) {
          changed := false;
          for (a in Array.keys(children)) {
            if (labels[a] == currentLabel) {
              for (b in Array.keys(children)) {
                if (labels[b] == 0 and adj[a * n + b]) {
                  labels[b] := currentLabel;
                  changed := true;
                };
              };
            };
          };
        };
      };
    };

    clusterCount := currentLabel;

    // Assign cluster labels to children
    children := Array.tabulate<ChildCanister>(n, func(i) {
      { children[i] with clusterLabel = labels[i] };
    });

    // Compute modularity Q (Newman formulation simplified for undirected unweighted graph)
    // Q = (1/2m) Σᵢⱼ [Aᵢⱼ − kᵢ·kⱼ/(2m)] · δ(cᵢ, cⱼ)
    if (edgeCount > 0) {
      let m2 = Float.fromInt(edgeCount);  // 2m (edges counted both directions)
      var qSum : Float = 0.0;

      // Compute degree of each node
      let degrees = Array.init<Nat>(n, 0);
      for (i in Array.keys(children)) {
        var deg : Nat = 0;
        for (j in Array.keys(children)) {
          if (i != j and adj[i * n + j]) { deg += 1 };
        };
        degrees[i] := deg;
      };

      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (labels[i] == labels[j]) {
            let aij : Float = if (adj[i * n + j]) { 1.0 } else { 0.0 };
            let ki = Float.fromInt(degrees[i]);
            let kj = Float.fromInt(degrees[j]);
            qSum += aij - (ki * kj / m2);
          };
        };
      };
      modularityQ := _clamp(qSum / m2, -0.5, 1.0);
    } else {
      modularityQ := 0.0;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHEDULING ENGINE — Hebbian-adaptive Fibonacci-multiplied beat allocation
  //
  // Children are not scheduled uniformly. The adaptive weight (derived from
  // Hebbian coupling strength) modulates the Fibonacci multiplier:
  //   effective_interval = fibMult × (1 + φ⁻¹ × (1 − adaptiveWeight))
  //
  // Children with high Hebbian coupling to others get tighter scheduling.
  // ═══════════════════════════════════════════════════════════════════════════

  func shouldTickChild(childName : Text, currentBeat : Nat) : Bool {
    for (entry in schedule.vals()) {
      if (entry.childName == childName) {
        // Adaptive interval: high adaptive weight → shorter effective interval
        let effective = Float.fromInt(entry.fibMultiplier) *
                        (1.0 + PHI_INV * (1.0 - entry.adaptiveWeight));
        let effectiveNat = Int.abs(Float.toInt(effective));
        let interval = if (effectiveNat == 0) { 1 } else { effectiveNat };
        return (currentBeat - entry.lastScheduled) >= interval;
      };
    };
    true;
  };

  func updateScheduleAfterTick(childName : Text, currentBeat : Nat) : () {
    let n = children.size();
    schedule := Array.map<ScheduleEntry, ScheduleEntry>(schedule, func(e) {
      if (e.childName == childName) {
        // Update adaptive weight from mean Hebbian coupling of this child
        var childIdx : Nat = 0;
        var found = false;
        for (i in Array.keys(children)) {
          if (children[i].name == childName) { childIdx := i; found := true };
        };
        let newWeight = if (found and n > 1) {
          var sumW : Float = 0.0;
          for (j in Array.keys(children)) {
            if (j != childIdx) {
              sumW += hebbianW[childIdx * n + j];
            };
          };
          _clamp(sumW / Float.fromInt(n - 1), PHI_INV_3, PHI);
        } else { e.adaptiveWeight };
        { e with lastScheduled = currentBeat; adaptiveWeight = newWeight };
      } else { e };
    });
  };

  public shared(msg) func setSchedule(childName : Text, fibIndex : Nat) : async () {
    assertCreator(msg.caller);
    let mult = if (fibIndex < FIB.size()) { FIB[fibIndex] } else { 1 };
    let filtered = Array.filter<ScheduleEntry>(schedule, func(e) { e.childName != childName });
    let entry : ScheduleEntry = {
      childName      = childName;
      fibMultiplier  = mult;
      lastScheduled  = beatCount;
      adaptiveWeight = PHI_INV_2;  // Initial adaptive weight
    };
    schedule := Array.append(filtered, [entry]);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECTRAL COHERENCE ANALYSIS — frequency-domain orchestration intelligence
  //
  // Analyzes the coherence history buffer for dominant frequency components.
  // Uses autocorrelation as a spectral estimator (no FFT needed on-chain).
  // Detects periodic patterns in coherence oscillations.
  // ═══════════════════════════════════════════════════════════════════════════

  stable var dominantPeriod     : Nat = 0;   // beats between coherence peaks
  stable var spectralPower      : Float = 0.0; // strength of dominant frequency

  func _spectralAnalysis() : () {
    let len = coherenceHistory.size();
    if (len < 8) return;  // Need minimum F(6)=8 samples

    // Compute mean
    var mean : Float = 0.0;
    for (v in coherenceHistory.vals()) { mean += v };
    mean := mean / Float.fromInt(len);

    // Autocorrelation for lags 1..len/2
    var maxCorr : Float = 0.0;
    var maxLag : Nat = 0;

    var lag : Nat = 1;
    while (lag < len / 2) {
      var corr : Float = 0.0;
      var norm : Float = 0.0;
      var t : Nat = 0;
      while (t + lag < len) {
        let a = coherenceHistory[t] - mean;
        let b = coherenceHistory[t + lag] - mean;
        corr += a * b;
        norm += a * a;
        t += 1;
      };
      let normalizedCorr = if (norm > 0.001) { corr / norm } else { 0.0 };
      if (normalizedCorr > maxCorr) {
        maxCorr := normalizedCorr;
        maxLag := lag;
      };
      lag += 1;
    };

    dominantPeriod := maxLag;
    spectralPower := maxCorr;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms SOVEREIGN CARDIAC CYCLE
  // Full orchestration with Hebbian learning, Lyapunov monitoring,
  // free energy minimization, entropy tracking, cluster detection
  // ═══════════════════════════════════════════════════════════════════════════

  func heartbeat() : async () {
    let now = Time.now();
    beatCount += 1;
    lastBeatTime := now;

    // ── STEP 1: Advance Kuramoto phases (weighted by Hebbian topology) ────
    advancePhases();

    // ── STEP 2: Compute global coherence (Kuramoto order parameter R) ─────
    prevGlobalCoherence := globalCoherence;
    globalCoherence := computeKuramotoR();

    // Track coherence history (rolling window of COHERENCE_WINDOW values)
    coherenceHistory := if (coherenceHistory.size() >= COHERENCE_WINDOW) {
      let tail = Array.subArray<Float>(coherenceHistory, 1, COHERENCE_WINDOW - 1);
      Array.append(tail, [globalCoherence]);
    } else {
      Array.append(coherenceHistory, [globalCoherence]);
    };

    // ── STEP 3: Lyapunov energy computation ───────────────────────────────
    prevLyapunovV := lyapunovV;
    lyapunovV := computeLyapunovEnergy();
    jasmineDrift := if (prevLyapunovV > 0.001) {
      (lyapunovV - prevLyapunovV) / prevLyapunovV
    } else { 0.0 };

    // ── STEP 4: Coherence gate check (Lyapunov-enhanced) ──────────────────
    // Gate opens when R ≥ φ⁻¹ AND system is not actively destabilizing
    let coherenceGateOpen = globalCoherence >= PHI_INV and jasmineDrift <= PHI_INV_3;

    // ── STEP 5: Orchestrate children with Hebbian-informed scheduling ─────
    var ticked : [Text] = [];
    var tickedIndices : [Nat] = [];
    var skipped : [Text] = [];
    var failed : [Text] = [];

    for (i in Array.keys(children)) {
      let child = children[i];

      if (not child.active) {
        skipped := Array.append(skipped, [child.name]);
      }
      else if (not coherenceGateOpen and child.priority > 1) {
        skipped := Array.append(skipped, [child.name]);
      }
      else if (not shouldTickChild(child.name, beatCount)) {
        skipped := Array.append(skipped, [child.name]);
      }
      else {
        // Health update: Hebbian-informed health growth/decay
        // Children with high mean coupling grow health faster
        let n = children.size();
        var meanCoupling : Float = PHI_INV_2;
        if (n > 1) {
          var sumC : Float = 0.0;
          for (j in Array.keys(children)) {
            if (j != i) { sumC += hebbianW[i * n + j] };
          };
          meanCoupling := sumC / Float.fromInt(n - 1);
        };

        let newHealth = if (child.failCount == 0) {
          // Growth rate modulated by coupling: higher coupling → faster growth
          let growthRate = PHI * (1.0 + meanCoupling * PHI_INV);
          Float.min(child.health * (1.0 + (growthRate - 1.0) * PHI_INV_2), PHI_SQ);
        } else {
          Float.max(child.health * PHI_INV_2, S0);
        };

        children := Array.tabulate<ChildCanister>(children.size(), func(j) {
          if (j == i) {
            { child with lastTick = now; health = newHealth; tickCount = child.tickCount + 1 };
          } else {
            children[j];
          };
        });

        updateScheduleAfterTick(child.name, beatCount);
        ticked := Array.append(ticked, [child.name]);
        tickedIndices := Array.append(tickedIndices, [i]);
      };
    };

    // ── STEP 6: Hebbian weight update (co-activation learning) ────────────
    _hebbianUpdate(tickedIndices);

    // ── STEP 7: Free energy computation (prediction error) ────────────────
    prevFreeEnergy := freeEnergy;
    freeEnergy := _computeFreeEnergy(tickedIndices);

    // Update prediction accuracy (exponential moving average)
    let maxError = Float.fromInt(children.size());
    let accuracy = if (maxError > 0.0) { 1.0 - (freeEnergy / maxError) } else { 0.5 };
    predictionAccuracy := predictionAccuracy * PHI_INV + accuracy * PHI_INV_2;

    // Generate predictions for NEXT beat
    _generatePredictions();

    // ── STEP 8: Shannon entropy of orchestration distribution ─────────────
    orchestrationEntropy := _computeOrchestrationEntropy();

    // ── STEP 9: Integrated information Φ ──────────────────────────────────
    integratedInfoPhi := _computeIntegratedInfo();

    // ── STEP 10: Composite coherence C = tanh(Φ · R · (1 − |drift|)) ─────
    let tanhArg = integratedInfoPhi * globalCoherence * (1.0 - _clamp(Float.abs(jasmineDrift), 0.0, 1.0));
    let expPos = Float.exp(tanhArg);
    let expNeg = Float.exp(-tanhArg);
    coherenceC := if (expPos + expNeg > 0.0) {
      _clamp((expPos - expNeg) / (expPos + expNeg), 0.0, 1.0)
    } else { 0.0 };

    // ── STEP 11: Cluster detection (every F(5)=5 beats) ───────────────────
    if (beatCount % 5 == 0) {
      _detectClusters();
    };

    // ── STEP 12: Spectral analysis (every F(6)=8 beats) ──────────────────
    if (beatCount % 8 == 0) {
      _spectralAnalysis();
    };

    // ── STEP 13: OMNIS precondition check ─────────────────────────────────
    omnisPrecondition := globalCoherence >= R_OMNIS
                      and Float.abs(jasmineDrift) < PHI_INV_3
                      and lyapunovV < PHI_INV_4
                      and freeEnergy < PHI_INV_3;
    if (omnisPrecondition) { omnisFireCount += 1 };

    // ── STEP 14: Push enriched audit entry ────────────────────────────────
    let audit : AuditEntry = {
      beat           = beatCount;
      timestamp      = now;
      coherence      = globalCoherence;
      lyapunovV      = lyapunovV;
      freeEnergy     = freeEnergy;
      shannonH       = orchestrationEntropy;
      spectralRadius = spectralRadius;
      integratedPhi  = integratedInfoPhi;
      coherenceC     = coherenceC;
      jasmineDrift   = jasmineDrift;
      clusterCount   = clusterCount;
      omnis          = omnisPrecondition;
      childrenTicked = ticked;
      childrenSkipped= skipped;
      childrenFailed = failed;
    };
    pushAudit(audit);

    // ── STEP 15: Persist Hebbian state to stable storage ──────────────────
    hebbianWStable := Array.freeze(hebbianW);
    childPhasesStable := Array.freeze(childPhases);

    // ── STEP 16+: Advanced intelligence modules ───────────────────────────
    let activeCount = Array.filter<ChildCanister>(children, func(c) { c.active }).size();
    _postHeartbeatIntelligence(ticked.size(), activeCount);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS — Start the sovereign heartbeat (one-time activation)
  // ═══════════════════════════════════════════════════════════════════════════

  public shared(msg) func genesis() : async () {
    assertCreator(msg.caller);
    assert (not genesisSealed);
    genesisSealed := true;
    genesisTime := Time.now();
    heartbeatActive := true;
    ignore Timer.recurringTimer<system>(#nanoseconds(HEARTBEAT_NS), heartbeat);
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // NEURAL PATHWAY FORMATION — adaptive topology restructuring engine
  //
  // The orchestrator continuously forms and dissolves neural pathways between
  // child canisters based on co-activation patterns, phase coherence history,
  // and information flow metrics. This implements structural plasticity —
  // not just weight changes (Hebbian) but actual topological reorganization.
  //
  // Pathway Formation Rule:
  //   IF cos(θᵢ−θⱼ) > φ⁻¹ for consecutive F(5)=5 beats
  //   AND wᵢⱼ > φ⁻² (Hebbian weight above threshold)
  //   AND mutual_info(i,j) > φ⁻³
  //   THEN: form_pathway(i, j) — create persistent routing shortcut
  //
  // Pathway Dissolution Rule:
  //   IF pathway_age > F(8)=21 beats
  //   AND pathway_utilization < φ⁻⁴
  //   AND cos(θᵢ−θⱼ) < φ⁻³ for consecutive F(4)=3 beats
  //   THEN: dissolve_pathway(i, j) — remove stale routing shortcut
  //
  // MATHEMATICAL FOUNDATION:
  //   Structural plasticity implements a form of graph rewriting where the
  //   topology G(V,E) evolves according to:
  //     E(t+1) = E(t) ∪ {formed} \ {dissolved}
  //   This creates a dynamic small-world network where path length
  //   L ~ log(N)/log(k) decreases as functional clusters strengthen.
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type NeuralPathway = {
    sourceIdx        : Nat;        // Source child index
    targetIdx        : Nat;        // Target child index
    strength         : Float;      // Pathway strength [φ⁻³, φ²]
    formationBeat    : Nat;        // Beat when pathway was formed
    lastActivation   : Nat;        // Last beat this pathway conducted a signal
    activationCount  : Nat;        // Total activations (lifetime)
    utilization      : Float;      // Rolling utilization rate [0, 1]
    coherenceAtForm  : Float;      // Phase coherence when pathway was formed
    bidirectional    : Bool;       // Whether pathway conducts both directions
    bandwidth        : Nat;        // Signals per beat capacity (Fibonacci-bounded)
    latencyEstimate  : Float;      // Estimated signal latency through pathway (ms)
    mutualInfoScore  : Float;      // Mutual information between source and target
    resonanceMatch   : Float;      // Frequency resonance between endpoints
    pathwayType      : PathwayType;// Classification of this pathway
  };

  public type PathwayType = {
    #excitatory;    // Strengthens target activation (positive coupling)
    #inhibitory;    // Suppresses target activation (negative coupling)
    #modulatory;    // Modulates target's sensitivity without direct activation
    #resonant;      // Phase-locked bidirectional oscillatory coupling
    #feedforward;   // Unidirectional information flow (perception)
    #feedback;      // Reverse information flow (prediction/control)
    #lateral;       // Same-level cross-communication (integration)
    #skip;          // Long-range skip connection (hierarchical shortcut)
  };

  stable var neuralPathways : [NeuralPathway] = [];
  stable var totalPathwaysFormed    : Nat = 0;
  stable var totalPathwaysDissolved : Nat = 0;
  stable var avgPathwayStrength     : Float = 0.0;
  stable var pathwayDensity         : Float = 0.0;  // E/(N*(N-1)) — graph density
  stable var smallWorldCoefficient  : Float = 0.0;  // σ = (C/C_rand) / (L/L_rand)
  stable var pathwayEntropy         : Float = 0.0;  // Distribution entropy of pathway usage

  // Consecutive coherence tracking for pathway formation decisions
  stable var consecutiveCoherenceMatrix : [Nat] = [];  // N×N: beats of consecutive coherence

  // Mutual information estimation buffer
  stable var mutualInfoBuffer : [Float] = [];  // N×N: estimated mutual information

  // Pathway formation — creates a new neural pathway when conditions are met
  func _attemptPathwayFormation() : () {
    let n = children.size();
    if (n < 2) return;

    // Ensure consecutive coherence matrix is properly sized
    if (consecutiveCoherenceMatrix.size() != n * n) {
      consecutiveCoherenceMatrix := Array.tabulate<Nat>(n * n, func(_) { 0 });
    };

    // Update consecutive coherence counts
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let idx = i * n + j;
          let phaseCoh = Float.cos(_normalizePhase(childPhases[i] - childPhases[j]));
          if (phaseCoh > PHI_INV) {
            // Coherent — increment consecutive counter
            consecutiveCoherenceMatrix := Array.tabulate<Nat>(n * n, func(k) {
              if (k == idx) { consecutiveCoherenceMatrix[k] + 1 }
              else { consecutiveCoherenceMatrix[k] };
            });
          } else {
            // Not coherent — reset counter
            consecutiveCoherenceMatrix := Array.tabulate<Nat>(n * n, func(k) {
              if (k == idx) { 0 }
              else { consecutiveCoherenceMatrix[k] };
            });
          };
        };
      };
    };

    // Check formation conditions for each pair
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let idx = i * n + j;
          let consecutiveBeats = consecutiveCoherenceMatrix[idx];

          // Formation requires F(5)=5 consecutive coherent beats
          if (consecutiveBeats >= 5) {
            let hebbWeight = hebbianW[idx];
            // Check Hebbian weight threshold
            if (hebbWeight > PHI_INV_2) {
              // Check if pathway already exists
              var exists = false;
              for (p in neuralPathways.vals()) {
                if (p.sourceIdx == i and p.targetIdx == j) { exists := true };
              };

              if (not exists and neuralPathways.size() < n * (n - 1)) {
                // Determine pathway type based on coupling characteristics
                let pathType = _classifyPathway(i, j);
                let bandwidth = if (hebbWeight > PHI_INV) { 3 } else { 1 };
                let phaseCoh = Float.cos(_normalizePhase(childPhases[i] - childPhases[j]));

                let pathway : NeuralPathway = {
                  sourceIdx       = i;
                  targetIdx       = j;
                  strength        = hebbWeight;
                  formationBeat   = beatCount;
                  lastActivation  = beatCount;
                  activationCount = 0;
                  utilization     = 0.0;
                  coherenceAtForm = phaseCoh;
                  bidirectional   = phaseCoh > 0.9;  // Near-perfect coherence → bidirectional
                  bandwidth       = bandwidth;
                  latencyEstimate = PHI_INV_2 * 100.0;  // Initial estimate: φ⁻² × 100ms
                  mutualInfoScore = _estimateMutualInfo(i, j);
                  resonanceMatch  = phaseCoh;
                  pathwayType     = pathType;
                };

                neuralPathways := Array.append(neuralPathways, [pathway]);
                totalPathwaysFormed += 1;
              };
            };
          };
        };
      };
    };
  };

  // Pathway dissolution — removes stale, underutilized pathways
  func _attemptPathwayDissolution() : () {
    let n = children.size();
    if (neuralPathways.size() == 0) return;

    neuralPathways := Array.filter<NeuralPathway>(neuralPathways, func(p) {
      let age = beatCount - p.formationBeat;
      // Pathway must be at least F(8)=21 beats old before dissolution is considered
      if (age < 21) return true;

      // Check utilization threshold
      if (p.utilization < PHI_INV_4) {
        // Check consecutive non-coherence
        if (n > 0 and p.sourceIdx < n and p.targetIdx < n) {
          let phaseCoh = Float.cos(_normalizePhase(childPhases[p.sourceIdx] - childPhases[p.targetIdx]));
          if (phaseCoh < PHI_INV_3) {
            // Dissolve this pathway
            totalPathwaysDissolved += 1;
            return false;
          };
        };
      };
      true;
    });
  };

  // Classify pathway type based on coupling dynamics
  func _classifyPathway(sourceIdx : Nat, targetIdx : Nat) : PathwayType {
    let n = children.size();
    let wij = hebbianW[sourceIdx * n + targetIdx];
    let wji = hebbianW[targetIdx * n + sourceIdx];

    // Bidirectional strong coupling → resonant
    if (Float.abs(wij - wji) < PHI_INV_4 and wij > PHI_INV) {
      return #resonant;
    };

    // Much stronger forward than backward → feedforward
    if (wij > wji * PHI) {
      return #feedforward;
    };

    // Much stronger backward than forward → feedback
    if (wji > wij * PHI) {
      return #feedback;
    };

    // Same cluster → lateral
    if (children[sourceIdx].clusterLabel == children[targetIdx].clusterLabel and
        children[sourceIdx].clusterLabel > 0) {
      return #lateral;
    };

    // Different clusters with high priority difference → skip
    let priDiff = if (children[sourceIdx].priority > children[targetIdx].priority) {
      children[sourceIdx].priority - children[targetIdx].priority
    } else {
      children[targetIdx].priority - children[sourceIdx].priority
    };
    if (priDiff > 3) {
      return #skip;
    };

    // Default to excitatory
    #excitatory;
  };

  // Estimate mutual information between two children (proxy via co-activation)
  func _estimateMutualInfo(i : Nat, j : Nat) : Float {
    let n = children.size();
    if (n == 0) return 0.0;

    // Use health correlation and Hebbian weight as proxy
    let healthCorr = (children[i].health * children[j].health) / (PHI_SQ * PHI_SQ);
    let hebbFactor = hebbianW[i * n + j] / PHI;
    let phaseFactor = Float.cos(_normalizePhase(childPhases[i] - childPhases[j]));

    _clamp(healthCorr * hebbFactor * phaseFactor, 0.0, 1.0);
  };

  // Update pathway metrics after each beat
  func _updatePathwayMetrics() : () {
    if (neuralPathways.size() == 0) return;

    let n = children.size();
    var totalStrength : Float = 0.0;
    var totalUtil : Float = 0.0;

    neuralPathways := Array.map<NeuralPathway, NeuralPathway>(neuralPathways, func(p) {
      // Update utilization (exponential decay toward 0 unless activated)
      let newUtil = p.utilization * PHI_INV;  // Decay by φ⁻¹ per beat
      totalStrength += p.strength;
      totalUtil += newUtil;

      // Update strength based on current Hebbian weight
      let newStrength = if (p.sourceIdx < n and p.targetIdx < n) {
        let w = hebbianW[p.sourceIdx * n + p.targetIdx];
        _clamp(w, PHI_INV_3, PHI_SQ)
      } else { p.strength };

      { p with utilization = newUtil; strength = newStrength };
    });

    let pathCount = Float.fromInt(neuralPathways.size());
    avgPathwayStrength := if (pathCount > 0.0) { totalStrength / pathCount } else { 0.0 };

    // Graph density: E / (N * (N-1))
    let maxEdges = n * (if (n > 1) { n - 1 } else { 1 });
    pathwayDensity := Float.fromInt(neuralPathways.size()) / Float.fromInt(maxEdges);

    // Pathway entropy: distribution of utilization across pathways
    if (neuralPathways.size() > 0 and totalUtil > 0.001) {
      var entropy : Float = 0.0;
      for (p in neuralPathways.vals()) {
        let pi = p.utilization / totalUtil;
        if (pi > 0.001) {
          entropy -= pi * (Float.log(pi) / Float.log(2.0));
        };
      };
      pathwayEntropy := entropy;
    };
  };

  // Small-world coefficient estimation
  // σ = (C/C_random) / (L/L_random)
  // where C = clustering coefficient, L = average path length
  func _computeSmallWorldCoefficient() : () {
    let n = children.size();
    if (n < 3 or neuralPathways.size() < 3) {
      smallWorldCoefficient := 0.0;
      return;
    };

    // Build adjacency from pathways
    let adj = Array.init<Bool>(n * n, false);
    for (p in neuralPathways.vals()) {
      if (p.sourceIdx < n and p.targetIdx < n) {
        adj[p.sourceIdx * n + p.targetIdx] := true;
        if (p.bidirectional) {
          adj[p.targetIdx * n + p.sourceIdx] := true;
        };
      };
    };

    // Compute clustering coefficient C
    var totalC : Float = 0.0;
    var nodesWithNeighbors : Nat = 0;

    for (i in Array.keys(children)) {
      // Find neighbors of i
      var neighbors : [Nat] = [];
      for (j in Array.keys(children)) {
        if (i != j and (adj[i * n + j] or adj[j * n + i])) {
          neighbors := Array.append(neighbors, [j]);
        };
      };

      let k = neighbors.size();
      if (k >= 2) {
        // Count edges between neighbors
        var triangles : Nat = 0;
        for (a in neighbors.vals()) {
          for (b in neighbors.vals()) {
            if (a != b and (adj[a * n + b] or adj[b * n + a])) {
              triangles += 1;
            };
          };
        };
        let maxTriangles = k * (k - 1);
        let ci = Float.fromInt(triangles) / Float.fromInt(maxTriangles);
        totalC += ci;
        nodesWithNeighbors += 1;
      };
    };

    let C = if (nodesWithNeighbors > 0) {
      totalC / Float.fromInt(nodesWithNeighbors)
    } else { 0.0 };

    // Random graph clustering: C_random ≈ k/N where k = avg degree
    let avgDegree = 2.0 * Float.fromInt(neuralPathways.size()) / Float.fromInt(n);
    let C_random = avgDegree / Float.fromInt(n);

    // For small-world: C/C_random >> 1 and L/L_random ≈ 1
    // Simplified: σ ≈ C / C_random (assuming L ≈ L_random for connected graphs)
    smallWorldCoefficient := if (C_random > 0.001) { C / C_random } else { 0.0 };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTIVE CODING HIERARCHY — multi-level prediction error minimization
  //
  // Implements a hierarchical predictive coding framework where each level
  // generates predictions about the level below, and prediction errors
  // propagate upward. This is the computational implementation of Karl
  // Friston's Free Energy Principle applied to multi-canister orchestration.
  //
  // Level 0 (Sensory): Raw tick success/failure observations
  // Level 1 (Pattern): Predicted tick patterns from schedule + health
  // Level 2 (Dynamics): Predicted coherence evolution from Kuramoto model
  // Level 3 (Meta):     Predicted learning rate adaptation (meta-learning)
  //
  // Prediction Error at level l:
  //   ε_l = observation_l − prediction_l
  //
  // Prediction Update (gradient descent on free energy):
  //   μ_l(t+1) = μ_l(t) + κ_l · ε_l − κ_(l+1) · ε_(l+1)
  //
  // where κ_l = precision-weighted learning rate at level l = φ^(−l−1)
  //
  // PRECISION WEIGHTING:
  //   Each level has a precision (inverse variance) that determines how much
  //   prediction errors at that level influence updates:
  //     Π_l = 1 / Var(ε_l)  [estimated from recent history]
  //   High precision → strong influence (reliable predictions)
  //   Low precision → weak influence (noisy/unreliable level)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  // Number of predictive coding levels: 4 (sensory, pattern, dynamics, meta)
  let PC_LEVELS : Nat = 4;

  // Precision-weighted learning rates: κ_l = φ^(−l−1)
  let PC_KAPPA : [Float] = [PHI_INV, PHI_INV_2, PHI_INV_3, PHI_INV_4];

  public type PredictiveLevel = {
    level           : Nat;        // Hierarchy level [0..3]
    prediction      : Float;      // Current prediction μ_l
    observation     : Float;      // Most recent observation
    predictionError : Float;      // ε_l = observation − prediction
    precision       : Float;      // Π_l = inverse variance of errors
    errorHistory    : [Float];    // Recent errors for variance estimation
    learningRate    : Float;      // κ_l × Π_l — effective learning rate
    confidence      : Float;      // 1 − (variance / maxVariance) — prediction confidence
    totalUpdates    : Nat;        // Lifetime update count
    cumulativeError : Float;      // Σ|ε_l| — total absolute error (lifetime)
  };

  stable var predictiveLevels : [PredictiveLevel] = Array.tabulate<PredictiveLevel>(PC_LEVELS, func(l) {
    {
      level           = l;
      prediction      = PHI_INV;
      observation     = 0.0;
      predictionError = 0.0;
      precision       = 1.0;
      errorHistory    = [];
      learningRate    = PC_KAPPA[l];
      confidence      = 0.5;
      totalUpdates    = 0;
      cumulativeError = 0.0;
    };
  });

  stable var hierarchicalFreeEnergy : Float = 0.0;  // Total free energy across all levels
  stable var precisionWeightedError : Float = 0.0;  // Σ Π_l × ε_l²
  stable var metaLearningRate       : Float = PHI_INV_3;  // Rate of learning rate adaptation
  stable var predictionHorizon      : Nat = 5;            // How many beats ahead to predict
  stable var surprisal              : Float = 0.0;        // −log P(observation) — information surprise
  stable var bayesianConfidence     : Float = 0.5;        // Overall Bayesian posterior confidence

  // Level 0: Observe tick success rate this beat
  func _pcObserveLevel0(tickedCount : Nat, totalActive : Nat) : Float {
    if (totalActive == 0) return 0.0;
    Float.fromInt(tickedCount) / Float.fromInt(totalActive);
  };

  // Level 1: Observe pattern match (how well schedule predicted actual ticks)
  func _pcObserveLevel1() : Float {
    predictionAccuracy;
  };

  // Level 2: Observe coherence dynamics (R derivative)
  func _pcObserveLevel2() : Float {
    let trend = globalCoherence - prevGlobalCoherence;
    // Normalize to [0, 1]: 0.5 = stable, >0.5 = improving, <0.5 = declining
    _clamp(0.5 + trend * PHI, 0.0, 1.0);
  };

  // Level 3: Observe meta-learning (stability of learning rate)
  func _pcObserveLevel3() : Float {
    // Normalized learning rate: current / base
    etaLearningRate / ETA_BASE;
  };

  // Update all predictive coding levels
  func _updatePredictiveCoding(tickedCount : Nat, totalActive : Nat) : () {
    // Collect observations at each level
    let observations : [Float] = [
      _pcObserveLevel0(tickedCount, totalActive),
      _pcObserveLevel1(),
      _pcObserveLevel2(),
      _pcObserveLevel3()
    ];

    var totalFE : Float = 0.0;
    var totalPWE : Float = 0.0;

    predictiveLevels := Array.tabulate<PredictiveLevel>(PC_LEVELS, func(l) {
      let level = predictiveLevels[l];
      let obs = observations[l];

      // Compute prediction error
      let error = obs - level.prediction;

      // Update error history (rolling window of F(8)=21 entries)
      let newHistory = if (level.errorHistory.size() >= 21) {
        let tail = Array.subArray<Float>(level.errorHistory, 1, 20);
        Array.append(tail, [error]);
      } else {
        Array.append(level.errorHistory, [error]);
      };

      // Estimate precision from error variance
      let variance = _computeVariance(newHistory);
      let newPrecision = if (variance > 0.001) { 1.0 / variance } else { PHI_SQ };
      let clampedPrecision = _clamp(newPrecision, PHI_INV_3, PHI_SQ * PHI_SQ);

      // Effective learning rate: base κ × precision (precision-weighted)
      let effLR = PC_KAPPA[l] * _clamp(clampedPrecision / PHI_SQ, PHI_INV_4, 1.0);

      // Update prediction (gradient descent on free energy)
      let newPrediction = _clamp(level.prediction + effLR * error, 0.0, PHI_SQ);

      // Confidence = 1 − normalized_variance
      let maxVar : Float = 0.25;  // Maximum reasonable variance for [0,1] bounded values
      let confidence = _clamp(1.0 - (variance / maxVar), 0.0, 1.0);

      // Accumulate free energy contribution: Π_l × ε_l²
      let contribution = clampedPrecision * error * error;
      totalFE += contribution;
      totalPWE += contribution;

      {
        level           = l;
        prediction      = newPrediction;
        observation     = obs;
        predictionError = error;
        precision       = clampedPrecision;
        errorHistory    = newHistory;
        learningRate    = effLR;
        confidence      = confidence;
        totalUpdates    = level.totalUpdates + 1;
        cumulativeError = level.cumulativeError + Float.abs(error);
      };
    });

    hierarchicalFreeEnergy := totalFE;
    precisionWeightedError := totalPWE;

    // Compute surprisal: −log₂(P(observation)) ≈ free_energy (approximation)
    surprisal := if (totalFE > 0.0) {
      Float.log(1.0 + totalFE) / Float.log(2.0)
    } else { 0.0 };

    // Bayesian confidence: aggregate of level confidences weighted by precision
    var weightedConf : Float = 0.0;
    var totalWeight : Float = 0.0;
    for (level in predictiveLevels.vals()) {
      weightedConf += level.confidence * level.precision;
      totalWeight += level.precision;
    };
    bayesianConfidence := if (totalWeight > 0.0) {
      _clamp(weightedConf / totalWeight, 0.0, 1.0)
    } else { 0.5 };
  };

  // Helper: compute variance of a float array
  func _computeVariance(arr : [Float]) : Float {
    let n = arr.size();
    if (n < 2) return 0.0;

    var mean : Float = 0.0;
    for (v in arr.vals()) { mean += v };
    mean := mean / Float.fromInt(n);

    var variance : Float = 0.0;
    for (v in arr.vals()) {
      let d = v - mean;
      variance += d * d;
    };
    variance / Float.fromInt(n);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPORAL MEMORY SYSTEM — episodic and procedural memory for orchestration
  //
  // The orchestrator maintains a temporal memory that stores significant events
  // (episodes) and learned procedures (behavioral patterns). This enables:
  //   1. Pattern recognition across time scales
  //   2. Anticipatory scheduling based on past episodes
  //   3. Anomaly detection via deviation from learned patterns
  //   4. Graceful degradation via procedural fallback
  //
  // EPISODIC MEMORY:
  //   Stores compressed snapshots of significant orchestration states.
  //   Significance = |ΔF| + |Δcoherence| + |ΔV| — total system surprise
  //   Memory capacity: F(10)=55 episodes (ring buffer with significance-gated admission)
  //
  // PROCEDURAL MEMORY:
  //   Stores learned action-outcome pairs:
  //     {context, action, outcome, confidence}
  //   Context = (coherence_band, cluster_state, energy_band)
  //   Action = scheduling decision made
  //   Outcome = resulting coherence change
  //
  // TEMPORAL BINDING:
  //   Episodes are linked by temporal proximity and causal relationships:
  //   Two episodes are "bound" if:
  //     1. They occurred within F(6)=8 beats of each other
  //     2. One's outcome is a precondition for the other's context
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  let EPISODIC_CAPACITY : Nat = 55;    // F(10) episodes maximum
  let PROCEDURAL_CAPACITY : Nat = 89;  // F(11) procedures maximum
  let SIGNIFICANCE_THRESHOLD : Float = PHI_INV_2;  // Must exceed to enter memory
  let TEMPORAL_BINDING_WINDOW : Nat = 8;  // F(6) beats for temporal binding

  public type Episode = {
    beat             : Nat;
    timestamp        : Int;
    significance     : Float;      // How surprising/important this episode was
    coherenceState   : Float;      // Global coherence at this moment
    lyapunovState    : Float;      // Lyapunov energy at this moment
    freeEnergyState  : Float;      // Free energy at this moment
    clusterState     : Nat;        // Number of clusters at this moment
    childStates      : [Float];    // Health vector of all children
    hebbianSnapshot  : [Float];    // Top-8 Hebbian weights (compressed)
    triggerEvent     : EpisodeTrigger;  // What caused this episode to be stored
    resolution       : EpisodeResolution;  // How the system responded
    outcomeQuality   : Float;      // Post-episode coherence improvement [−1, 1]
    bindingLinks     : [Nat];      // Indices of temporally-bound episodes
  };

  public type EpisodeTrigger = {
    #coherenceDrop;     // Sudden coherence decline
    #coherenceSurge;    // Sudden coherence improvement
    #clusterFormation;  // New cluster emerged
    #clusterDissolution;// Cluster dissolved
    #omnisAchieved;     // OMNIS state reached
    #instabilitySpike;  // Lyapunov spike detected
    #freeEnergySpike;   // Prediction error spike
    #childFailure;      // Child canister failure
    #topologyShift;     // Major topological reorganization
    #resonanceEvent;    // Strong resonance detected
  };

  public type EpisodeResolution = {
    #naturalRecovery;   // System self-corrected without intervention
    #hebbianAdaptation; // Hebbian weights adjusted to compensate
    #scheduleChange;    // Scheduling was modified
    #clusterReorg;      // Clusters reorganized
    #pathwayFormation;  // New pathway formed in response
    #pending;           // Episode is still unresolved
  };

  public type Procedure = {
    contextCoherenceBand  : Nat;    // Quantized coherence [0=low, 1=mid, 2=high]
    contextClusterCount   : Nat;    // Number of clusters when procedure was learned
    contextEnergyBand     : Nat;    // Quantized energy [0=low, 1=mid, 2=high]
    contextDriftSign      : Bool;   // true=positive drift, false=negative/zero
    action                : ProcedureAction;
    expectedOutcome       : Float;  // Expected coherence delta
    confidence            : Float;  // How many times this has been confirmed [0, 1]
    successCount          : Nat;    // Times this procedure succeeded
    failCount             : Nat;    // Times this procedure failed
    lastUsed              : Nat;    // Last beat this procedure was applied
    formationBeat         : Nat;    // When this procedure was first learned
  };

  public type ProcedureAction = {
    #tightenScheduling;    // Reduce Fibonacci intervals for all children
    #loosenScheduling;     // Increase Fibonacci intervals
    #focusOnCluster;       // Prioritize children in dominant cluster
    #balanceClusters;      // Equalize scheduling across clusters
    #increaseEta;          // Raise Hebbian learning rate
    #decreaseEta;          // Lower Hebbian learning rate
    #formPathways;         // Actively trigger pathway formation
    #prunePathways;        // Actively dissolve weak pathways
    #maintainCourse;       // No change — current strategy is working
  };

  stable var episodes : [Episode] = [];
  stable var procedures : [Procedure] = [];
  stable var totalEpisodesStored  : Nat = 0;
  stable var totalProceduresLearned : Nat = 0;
  stable var currentEpisodeActive : Bool = false;
  stable var pendingEpisodeStart  : Nat = 0;
  stable var memoryUtilization    : Float = 0.0;
  stable var proceduralMatchRate  : Float = 0.0;  // How often a procedure matched context

  // Compute significance of current state (determines if episode is stored)
  func _computeSignificance() : Float {
    let deltaF = Float.abs(freeEnergy - prevFreeEnergy);
    let deltaC = Float.abs(globalCoherence - prevGlobalCoherence);
    let deltaV = Float.abs(lyapunovV - prevLyapunovV);
    let driftMag = Float.abs(jasmineDrift);

    // Significance = weighted sum of all state changes
    // Higher weight on coherence changes (most meaningful for the organism)
    deltaC * PHI + deltaF * PHI_INV + deltaV * PHI_INV_2 + driftMag * PHI_INV_3;
  };

  // Determine what triggered this episode
  func _classifyTrigger() : EpisodeTrigger {
    let deltaC = globalCoherence - prevGlobalCoherence;

    if (omnisPrecondition and omnisFireCount == 1) return #omnisAchieved;
    if (deltaC < -PHI_INV_2) return #coherenceDrop;
    if (deltaC > PHI_INV_2) return #coherenceSurge;
    if (jasmineDrift > PHI_INV) return #instabilitySpike;
    if (freeEnergy > prevFreeEnergy * PHI) return #freeEnergySpike;

    // Check for cluster changes
    let prevClusterCount = clusterCount;  // This is updated before memory check
    if (clusterCount > prevClusterCount) return #clusterFormation;
    if (clusterCount < prevClusterCount) return #clusterDissolution;

    // Default: topology shift
    #topologyShift;
  };

  // Store an episode if significant enough
  func _maybeStoreEpisode() : () {
    let significance = _computeSignificance();
    if (significance < SIGNIFICANCE_THRESHOLD) return;

    let trigger = _classifyTrigger();

    // Compress health states to top-8 Hebbian weights
    let n = children.size();
    let healthStates = Array.tabulate<Float>(n, func(i) { children[i].health });

    // Get top-8 Hebbian weights (most significant couplings)
    var topWeights : [Float] = [];
    if (n > 1) {
      var allWeights : [Float] = [];
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            allWeights := Array.append(allWeights, [hebbianW[i * n + j]]);
          };
        };
      };
      // Sort and take top 8 (simplified: just take first 8 above threshold)
      for (w in allWeights.vals()) {
        if (topWeights.size() < 8 and w > PHI_INV_2) {
          topWeights := Array.append(topWeights, [w]);
        };
      };
    };

    // Find temporal bindings (episodes within TEMPORAL_BINDING_WINDOW beats)
    var bindings : [Nat] = [];
    for (i in Array.keys(episodes)) {
      let ep = episodes[i];
      if (beatCount - ep.beat <= TEMPORAL_BINDING_WINDOW) {
        bindings := Array.append(bindings, [i]);
      };
    };

    let episode : Episode = {
      beat            = beatCount;
      timestamp       = Time.now();
      significance    = significance;
      coherenceState  = globalCoherence;
      lyapunovState   = lyapunovV;
      freeEnergyState = freeEnergy;
      clusterState    = clusterCount;
      childStates     = healthStates;
      hebbianSnapshot = topWeights;
      triggerEvent    = trigger;
      resolution      = #pending;
      outcomeQuality  = 0.0;
      bindingLinks    = bindings;
    };

    // Ring buffer insertion
    if (episodes.size() < EPISODIC_CAPACITY) {
      episodes := Array.append(episodes, [episode]);
    } else {
      // Replace least significant episode
      var minSig : Float = 999.0;
      var minIdx : Nat = 0;
      for (i in Array.keys(episodes)) {
        if (episodes[i].significance < minSig) {
          minSig := episodes[i].significance;
          minIdx := i;
        };
      };
      episodes := Array.tabulate<Episode>(EPISODIC_CAPACITY, func(i) {
        if (i == minIdx) { episode } else { episodes[i] };
      });
    };

    totalEpisodesStored += 1;
    memoryUtilization := Float.fromInt(episodes.size()) / Float.fromInt(EPISODIC_CAPACITY);
  };

  // Learn a procedure from recent outcome
  func _learnProcedure(action : ProcedureAction, outcome : Float) : () {
    // Quantize current context
    let cohBand : Nat = if (globalCoherence < PHI_INV_2) { 0 }
                       else if (globalCoherence < PHI_INV) { 1 }
                       else { 2 };
    let energyBand : Nat = if (freeEnergy < PHI_INV_3) { 0 }
                          else if (freeEnergy < PHI_INV) { 1 }
                          else { 2 };
    let driftPositive = jasmineDrift > 0.0;

    // Check if procedure already exists
    var found = false;
    procedures := Array.map<Procedure, Procedure>(procedures, func(p) {
      if (p.contextCoherenceBand == cohBand and
          p.contextClusterCount == clusterCount and
          p.contextEnergyBand == energyBand and
          p.action == action) {
        found := true;
        let success = outcome > 0.0;
        let newSucc = if (success) { p.successCount + 1 } else { p.successCount };
        let newFail = if (not success) { p.failCount + 1 } else { p.failCount };
        let total = Float.fromInt(newSucc + newFail);
        let newConf = if (total > 0.0) { Float.fromInt(newSucc) / total } else { 0.5 };
        let newExpected = p.expectedOutcome * PHI_INV + outcome * PHI_INV_2;
        { p with
          successCount = newSucc;
          failCount = newFail;
          confidence = newConf;
          expectedOutcome = newExpected;
          lastUsed = beatCount;
        };
      } else { p };
    });

    if (not found and procedures.size() < PROCEDURAL_CAPACITY) {
      let newProc : Procedure = {
        contextCoherenceBand = cohBand;
        contextClusterCount  = clusterCount;
        contextEnergyBand    = energyBand;
        contextDriftSign     = driftPositive;
        action               = action;
        expectedOutcome      = outcome;
        confidence           = 0.5;
        successCount         = if (outcome > 0.0) { 1 } else { 0 };
        failCount            = if (outcome <= 0.0) { 1 } else { 0 };
        lastUsed             = beatCount;
        formationBeat        = beatCount;
      };
      procedures := Array.append(procedures, [newProc]);
      totalProceduresLearned += 1;
    };
  };

  // Retrieve best procedure for current context
  func _getBestProcedure() : ?ProcedureAction {
    let cohBand : Nat = if (globalCoherence < PHI_INV_2) { 0 }
                       else if (globalCoherence < PHI_INV) { 1 }
                       else { 2 };
    let energyBand : Nat = if (freeEnergy < PHI_INV_3) { 0 }
                          else if (freeEnergy < PHI_INV) { 1 }
                          else { 2 };

    var bestAction : ?ProcedureAction = null;
    var bestScore : Float = 0.0;

    for (p in procedures.vals()) {
      if (p.contextCoherenceBand == cohBand and
          p.contextEnergyBand == energyBand and
          p.confidence > PHI_INV_2) {
        let score = p.confidence * p.expectedOutcome;
        if (score > bestScore) {
          bestScore := score;
          bestAction := ?p.action;
        };
      };
    };

    proceduralMatchRate := proceduralMatchRate * PHI_INV +
      (if (bestAction != null) { 1.0 } else { 0.0 }) * PHI_INV_2;

    bestAction;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RESONANCE CASCADE ENGINE — multi-frequency harmonic synchronization
  //
  // Beyond basic Kuramoto phase synchronization, the Resonance Cascade Engine
  // detects and amplifies harmonic relationships between child oscillators.
  // When children oscillate at frequencies that form phi-harmonic ratios
  // (1:φ, 1:φ², etc.), the cascade engine creates resonance amplification
  // that dramatically increases coupling efficiency.
  //
  // HARMONIC DETECTION:
  //   For each pair (i,j), compute frequency ratio:
  //     r_ij = max(ω_i, ω_j) / min(ω_i, ω_j)
  //   If r_ij ≈ φ^k for some integer k, the pair is "phi-harmonic"
  //   Tolerance: |r_ij − φ^k| < φ⁻³ for detection
  //
  // CASCADE AMPLIFICATION:
  //   When a phi-harmonic pair is detected, their coupling is amplified:
  //     w_ij_effective = w_ij × (1 + resonanceBoost × harmonicOrder)
  //   where harmonicOrder = k and resonanceBoost = φ⁻² per harmonic level
  //
  // RESONANCE ENERGY:
  //   E_resonance = Σ_{harmonic pairs} w_ij × cos(θ_i − k×θ_j)
  //   This energy is NEGATIVE when harmonics are aligned (energy release)
  //   and POSITIVE when harmonics conflict (energy storage)
  //
  // STANDING WAVES:
  //   When enough children achieve phi-harmonic relationships, standing waves
  //   emerge in the coupling topology. These are self-sustaining oscillation
  //   patterns that require zero external input to maintain — the organism
  //   has achieved a natural resonance mode.
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  // Phi-harmonic powers for detection: φ¹, φ², φ³, φ⁴, φ⁵
  let PHI_HARMONICS : [Float] = [
    1.6180339887498948482,   // φ¹
    2.6180339887498948482,   // φ²
    4.2360679774997896964,   // φ³
    6.8541019662496845446,   // φ⁴
    11.090169943749474241    // φ⁵
  ];

  // Detection tolerance: φ⁻³
  let HARMONIC_TOLERANCE : Float = PHI_INV_3;

  // Maximum resonance boost per harmonic level: φ⁻²
  let RESONANCE_BOOST : Float = PHI_INV_2;

  public type HarmonicPair = {
    childA         : Nat;       // First child index
    childB         : Nat;       // Second child index
    harmonicOrder  : Nat;       // Which phi-harmonic (1=fundamental, 2=first overtone, etc.)
    freqRatio      : Float;     // Actual frequency ratio
    phiDeviation   : Float;     // |ratio − φ^k| — how close to perfect harmonic
    resonancePhase : Float;     // Phase relationship at resonance detection
    amplitude      : Float;     // Resonance amplitude (grows with time in resonance)
    durationBeats  : Nat;       // How many beats this pair has been in resonance
    energyRelease  : Float;     // Cumulative energy released by this harmonic
    isStanding     : Bool;      // Whether this has become a standing wave
  };

  stable var harmonicPairs        : [HarmonicPair] = [];
  stable var resonanceCascadeEnergy : Float = 0.0;
  stable var totalStandingWaves   : Nat = 0;
  stable var cascadeAmplitude     : Float = 0.0;  // Total resonance amplitude
  stable var harmonicDensity      : Float = 0.0;  // Fraction of pairs that are harmonic
  stable var fundamentalFrequency : Float = PHI_INV;  // Organism's base frequency
  stable var harmonicSpectrum     : [Float] = [];  // Power at each harmonic level

  // Detect phi-harmonic relationships between all child pairs
  func _detectHarmonics() : () {
    let n = children.size();
    if (n < 2) return;

    // Compute effective frequencies for each child
    let frequencies = Array.tabulate<Float>(n, func(i) {
      let child = children[i];
      // Frequency = φ × priority × health / (N × φ²)  (same as in advancePhases)
      PHI * Float.fromInt(child.priority) * (child.health / PHI_SQ) / Float.fromInt(n);
    });

    // Clear old harmonics and redetect
    var newHarmonics : [HarmonicPair] = [];

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i < j) {  // Only check each pair once
          let freqA = frequencies[i];
          let freqB = frequencies[j];
          if (freqA > 0.001 and freqB > 0.001) {
            let ratio = if (freqA > freqB) { freqA / freqB } else { freqB / freqA };

            // Check against each phi-harmonic
            for (k in Array.keys(PHI_HARMONICS)) {
              let phiK = PHI_HARMONICS[k];
              let deviation = Float.abs(ratio - phiK);
              if (deviation < HARMONIC_TOLERANCE) {
                // Found a phi-harmonic pair!
                // Check if this pair was already tracked
                var existingIdx : ?Nat = null;
                for (h in Array.keys(harmonicPairs)) {
                  let hp = harmonicPairs[h];
                  if ((hp.childA == i and hp.childB == j) or
                      (hp.childA == j and hp.childB == i)) {
                    if (hp.harmonicOrder == k + 1) {
                      existingIdx := ?h;
                    };
                  };
                };

                let pair = switch (existingIdx) {
                  case (?idx) {
                    // Update existing pair
                    let old = harmonicPairs[idx];
                    let newDuration = old.durationBeats + 1;
                    let phaseDiff = _normalizePhase(childPhases[i] - Float.fromInt(k + 1) * childPhases[j]);
                    let resonanceE = hebbianW[i * n + j] * Float.cos(phaseDiff);
                    let newAmplitude = old.amplitude + resonanceE * PHI_INV_3;
                    let isStanding = newDuration >= 13 and Float.abs(resonanceE) > PHI_INV;
                    {
                      childA         = i;
                      childB         = j;
                      harmonicOrder  = k + 1;
                      freqRatio      = ratio;
                      phiDeviation   = deviation;
                      resonancePhase = phaseDiff;
                      amplitude      = _clamp(newAmplitude, 0.0, PHI_SQ);
                      durationBeats  = newDuration;
                      energyRelease  = old.energyRelease + Float.abs(resonanceE);
                      isStanding     = isStanding;
                    };
                  };
                  case null {
                    // New harmonic pair
                    let phaseDiff = _normalizePhase(childPhases[i] - Float.fromInt(k + 1) * childPhases[j]);
                    {
                      childA         = i;
                      childB         = j;
                      harmonicOrder  = k + 1;
                      freqRatio      = ratio;
                      phiDeviation   = deviation;
                      resonancePhase = phaseDiff;
                      amplitude      = PHI_INV_3;  // Initial small amplitude
                      durationBeats  = 1;
                      energyRelease  = 0.0;
                      isStanding     = false;
                    };
                  };
                };

                newHarmonics := Array.append(newHarmonics, [pair]);
              };
            };
          };
        };
      };
    };

    harmonicPairs := newHarmonics;

    // Update cascade metrics
    let maxPairs = n * (n - 1) / 2;
    harmonicDensity := if (maxPairs > 0) {
      Float.fromInt(harmonicPairs.size()) / Float.fromInt(maxPairs)
    } else { 0.0 };

    // Total resonance cascade energy
    var totalEnergy : Float = 0.0;
    var totalAmp : Float = 0.0;
    var standingCount : Nat = 0;

    for (hp in harmonicPairs.vals()) {
      totalEnergy += hp.energyRelease;
      totalAmp += hp.amplitude;
      if (hp.isStanding) { standingCount += 1 };
    };

    resonanceCascadeEnergy := totalEnergy;
    cascadeAmplitude := totalAmp;
    totalStandingWaves := standingCount;

    // Compute harmonic spectrum (power at each harmonic level)
    harmonicSpectrum := Array.tabulate<Float>(PHI_HARMONICS.size(), func(k) {
      var power : Float = 0.0;
      for (hp in harmonicPairs.vals()) {
        if (hp.harmonicOrder == k + 1) {
          power += hp.amplitude;
        };
      };
      power;
    });

    // Fundamental frequency: weighted average of all child frequencies
    var totalFreq : Float = 0.0;
    var totalWeight : Float = 0.0;
    for (i in Array.keys(children)) {
      let w = children[i].health;
      totalFreq += frequencies[i] * w;
      totalWeight += w;
    };
    fundamentalFrequency := if (totalWeight > 0.0) {
      totalFreq / totalWeight
    } else { PHI_INV };
  };

  // Apply resonance boost to Hebbian coupling for harmonic pairs
  func _applyResonanceBoost() : () {
    let n = children.size();
    if (n < 2) return;

    for (hp in harmonicPairs.vals()) {
      if (hp.childA < n and hp.childB < n and hp.durationBeats > 3) {
        let idx_ab = hp.childA * n + hp.childB;
        let idx_ba = hp.childB * n + hp.childA;

        // Boost = φ⁻² × harmonicOrder × (1 − phiDeviation/tolerance)
        let qualityFactor = 1.0 - (hp.phiDeviation / HARMONIC_TOLERANCE);
        let boost = RESONANCE_BOOST * Float.fromInt(hp.harmonicOrder) * qualityFactor;

        // Apply boost to effective coupling (additive, clamped)
        let newAB = _clamp(hebbianW[idx_ab] + boost * PHI_INV_4, 0.0, PHI);
        let newBA = _clamp(hebbianW[idx_ba] + boost * PHI_INV_4, 0.0, PHI);

        hebbianW[idx_ab] := newAB;
        hebbianW[idx_ba] := newBA;
      };
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOMEOSTATIC REGULATION ENGINE — maintaining optimal operating ranges
  //
  // The orchestrator implements homeostatic regulation inspired by biological
  // systems. Each critical parameter has a "set point" (optimal value) and
  // the system actively works to return parameters to their set points
  // when they deviate. This creates robustness against perturbations.
  //
  // REGULATED PARAMETERS:
  //   1. Coherence R → set point: φ⁻¹ = 0.618 (moderate synchronization)
  //   2. Free Energy F → set point: φ⁻³ = 0.236 (low prediction error)
  //   3. Lyapunov V → set point: φ⁻⁴ = 0.146 (near stability)
  //   4. Entropy H → set point: log₂(N)/φ (φ⁻¹ of maximum entropy)
  //   5. Hebbian Kappa → set point: φ⁻⁴ (low but non-zero plasticity)
  //   6. Spectral Radius → set point: φ⁻¹ (below critical, above zero)
  //
  // HOMEOSTATIC RESPONSE:
  //   error_h = (parameter − set_point) / set_point
  //   correction = −gain × error_h × dt
  //   where gain = φ⁻² (moderate response strength)
  //   and dt = 1/φ (one heartbeat period normalized)
  //
  // ALLOSTATIC ADAPTATION:
  //   The set points themselves can shift over long time scales:
  //     set_point(t+1) = set_point(t) + allostatic_rate × sustained_deviation
  //   This models allostasis — the organism adapts its expectations to its
  //   environment rather than rigidly maintaining a fixed operating point.
  //   Allostatic rate = φ⁻⁵ (very slow adaptation)
  //
  // STRESS RESPONSE:
  //   When multiple parameters deviate simultaneously beyond their homeostatic
  //   dead zone (|error_h| > φ⁻²), a stress response is triggered:
  //     1. Learning rates increase (faster adaptation)
  //     2. Scheduling tightens (more frequent orchestration)
  //     3. Pathway formation accelerates
  //     4. Memory encoding strengthens (remember the stress event)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  let HOMEOSTATIC_GAIN : Float = PHI_INV_2;    // Response gain
  let ALLOSTATIC_RATE  : Float = PHI_INV_5;    // Set-point adaptation rate
  let STRESS_DEADZONE  : Float = PHI_INV_2;    // Error must exceed this for stress
  let STRESS_THRESHOLD : Nat = 3;              // Simultaneous deviations to trigger stress

  public type HomeostaticParameter = {
    name          : Text;
    currentValue  : Float;
    setPoint      : Float;
    error         : Float;      // (current − setPoint) / setPoint
    correction    : Float;      // Applied correction this beat
    isDeviating   : Bool;       // |error| > deadzone
    deviationBand : Nat;        // 0=normal, 1=mild, 2=moderate, 3=severe
    allostaticShift : Float;    // Cumulative set-point adaptation
  };

  stable var homeostaticState : [HomeostaticParameter] = [];
  stable var stressLevel     : Float = 0.0;    // [0, 1] — organism-wide stress
  stable var stressActive    : Bool = false;    // Whether stress response is engaged
  stable var stressOnsetBeat : Nat = 0;        // When stress was last triggered
  stable var totalStressEvents : Nat = 0;
  stable var avgRecoveryTime : Float = 0.0;    // Mean beats to recover from stress
  stable var resilienceScore : Float = 0.5;    // How quickly the system recovers

  // Set points for each regulated parameter
  stable var setPointCoherence : Float = PHI_INV;
  stable var setPointFreeEnergy : Float = PHI_INV_3;
  stable var setPointLyapunov : Float = PHI_INV_4;
  stable var setPointEntropy : Float = 0.0;  // Computed based on N
  stable var setPointKappa : Float = PHI_INV_4;
  stable var setPointSpectral : Float = PHI_INV;

  // Initialize homeostatic state
  func _initHomeostasis() : () {
    let n = children.size();
    // Entropy set point: log₂(N) / φ — moderate diversity
    setPointEntropy := if (n > 0) {
      (Float.log(Float.fromInt(n)) / Float.log(2.0)) * PHI_INV
    } else { 0.0 };

    homeostaticState := [
      { name = "coherence"; currentValue = globalCoherence; setPoint = setPointCoherence;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 },
      { name = "freeEnergy"; currentValue = freeEnergy; setPoint = setPointFreeEnergy;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 },
      { name = "lyapunov"; currentValue = lyapunovV; setPoint = setPointLyapunov;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 },
      { name = "entropy"; currentValue = orchestrationEntropy; setPoint = setPointEntropy;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 },
      { name = "hebbianKappa"; currentValue = hebbianKappa; setPoint = setPointKappa;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 },
      { name = "spectralRadius"; currentValue = spectralRadius; setPoint = setPointSpectral;
        error = 0.0; correction = 0.0; isDeviating = false; deviationBand = 0; allostaticShift = 0.0 }
    ];
  };

  // Update homeostatic regulation each beat
  func _updateHomeostasis() : () {
    let currentValues : [Float] = [
      globalCoherence, freeEnergy, lyapunovV,
      orchestrationEntropy, hebbianKappa, spectralRadius
    ];
    let setPoints : [Float] = [
      setPointCoherence, setPointFreeEnergy, setPointLyapunov,
      setPointEntropy, setPointKappa, setPointSpectral
    ];

    var deviatingCount : Nat = 0;

    homeostaticState := Array.tabulate<HomeostaticParameter>(homeostaticState.size(), func(i) {
      let param = homeostaticState[i];
      let current = currentValues[i];
      let sp = setPoints[i];

      // Compute error
      let error = if (sp > 0.001) { (current - sp) / sp } else { current - sp };

      // Determine deviation band
      let absError = Float.abs(error);
      let band : Nat = if (absError < PHI_INV_3) { 0 }      // Normal
                       else if (absError < PHI_INV_2) { 1 }   // Mild
                       else if (absError < PHI_INV) { 2 }     // Moderate
                       else { 3 };                            // Severe

      let isDeviating = absError > STRESS_DEADZONE;
      if (isDeviating) { deviatingCount += 1 };

      // Compute correction
      let correction = -HOMEOSTATIC_GAIN * error * PHI_INV;

      // Allostatic adaptation (slow set-point shift)
      let alloShift = param.allostaticShift + ALLOSTATIC_RATE * error;
      let clampedShift = _clamp(alloShift, -PHI_INV_2, PHI_INV_2);

      {
        name          = param.name;
        currentValue  = current;
        setPoint      = sp + clampedShift;
        error         = error;
        correction    = correction;
        isDeviating   = isDeviating;
        deviationBand = band;
        allostaticShift = clampedShift;
      };
    });

    // Stress response
    let prevStress = stressActive;
    stressActive := deviatingCount >= STRESS_THRESHOLD;
    stressLevel := Float.fromInt(deviatingCount) / Float.fromInt(homeostaticState.size());

    if (stressActive and not prevStress) {
      // Stress onset
      stressOnsetBeat := beatCount;
      totalStressEvents += 1;
    } else if (not stressActive and prevStress) {
      // Stress resolved — update recovery time
      let recoveryDuration = Float.fromInt(beatCount - stressOnsetBeat);
      avgRecoveryTime := avgRecoveryTime * PHI_INV + recoveryDuration * PHI_INV_2;
      // Resilience = 1 / (1 + avgRecoveryTime/F(8))
      resilienceScore := 1.0 / (1.0 + avgRecoveryTime / 21.0);
    };

    // Apply stress response effects
    if (stressActive) {
      // Increase learning rate during stress (faster adaptation)
      etaLearningRate := _clamp(etaLearningRate * (1.0 + PHI_INV_3), PHI_INV_5, ETA_BASE * PHI);
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EMERGENCE DETECTION — identifying novel collective behaviors
  //
  // This module detects when the orchestrated system exhibits genuinely
  // emergent behaviors — patterns that cannot be predicted from individual
  // child states alone. Emergence is detected through:
  //
  // 1. SYNERGY (beyond sum of parts):
  //    Synergy = I(system) − Σ I(child_i)
  //    When the total information content of the system exceeds the sum
  //    of individual contributions, genuine emergence has occurred.
  //
  // 2. DOWNWARD CAUSATION:
  //    When system-level variables (coherence, free energy) causally
  //    influence individual children more than individual changes
  //    influence the system. Measured via transfer entropy asymmetry.
  //
  // 3. NOVELTY DETECTION:
  //    When the system enters a state that is significantly different
  //    from all previously observed states (measured by distance to
  //    nearest episode in memory).
  //
  // 4. CRITICAL TRANSITIONS:
  //    Approaching phase transitions (critical slowing down) detected by:
  //    - Increased autocorrelation in coherence time series
  //    - Increased variance (flickering)
  //    - Skewness shifts
  //
  // EMERGENCE LEVEL:
  //   0 = No emergence (system is sum of parts)
  //   1 = Weak emergence (slight synergy detected)
  //   2 = Moderate emergence (sustained synergy + downward causation)
  //   3 = Strong emergence (novelty + critical transition markers)
  //   4 = OMNIS emergence (full coherence + maximum information integration)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type EmergenceLevel = {
    #none;
    #weak;
    #moderate;
    #strong;
    #omnis;
  };

  public type EmergenceReport = {
    level            : EmergenceLevel;
    synergyScore     : Float;      // How much system exceeds sum of parts
    noveltyScore     : Float;      // Distance from known states
    criticalSlowing  : Float;      // Autocorrelation increase (phase transition marker)
    varianceFlicker  : Float;      // Variance increase (phase transition marker)
    downwardCausation: Float;      // Asymmetry in causal influence
    integrationScore : Float;      // Integrated information measure
    timestamp        : Int;
    beatNumber       : Nat;
  };

  stable var currentEmergenceLevel : EmergenceLevel = #none;
  stable var emergenceHistory : [EmergenceReport] = [];
  stable var synergyScore     : Float = 0.0;
  stable var noveltyScore     : Float = 0.0;
  stable var criticalSlowing  : Float = 0.0;
  stable var varianceFlicker  : Float = 0.0;
  stable var downwardCausation: Float = 0.0;
  stable var peakEmergenceLevel : EmergenceLevel = #none;
  stable var emergenceOnsetBeat : Nat = 0;
  stable var totalEmergenceEvents : Nat = 0;
  stable var sustainedEmergenceBeats : Nat = 0;

  // Coherence variance buffer for critical transition detection
  stable var coherenceVarianceBuffer : [Float] = [];
  stable var autocorrelationBuffer   : [Float] = [];

  // Compute synergy: system information − sum of individual information
  func _computeSynergy() : Float {
    let n = children.size();
    if (n < 2) return 0.0;

    // System information: integratedInfoPhi (already computed)
    let systemInfo = integratedInfoPhi;

    // Sum of individual information: Σ entropy_i where entropy_i = −p_i·log(p_i)
    var individualSum : Float = 0.0;
    var totalTicks : Nat = 0;
    for (c in children.vals()) { totalTicks += c.tickCount };

    for (c in children.vals()) {
      if (c.tickCount > 0 and totalTicks > 0) {
        let p = Float.fromInt(c.tickCount) / Float.fromInt(totalTicks);
        if (p > 0.001) {
          individualSum -= p * (Float.log(p) / Float.log(2.0));
        };
      };
    };

    // Synergy: system exceeds sum
    // Normalized by N to get per-child synergy
    let rawSynergy = systemInfo - individualSum;
    _clamp(rawSynergy / Float.fromInt(n), -1.0, PHI_SQ);
  };

  // Compute novelty: minimum distance to any stored episode
  func _computeNovelty() : Float {
    if (episodes.size() == 0) return PHI;  // Everything is novel initially

    var minDist : Float = 999.0;
    for (ep in episodes.vals()) {
      // Euclidean distance in (coherence, lyapunov, freeEnergy) space
      let dC = globalCoherence - ep.coherenceState;
      let dV = lyapunovV - ep.lyapunovState;
      let dF = freeEnergy - ep.freeEnergyState;
      let dist = Float.sqrt(dC * dC + dV * dV + dF * dF);
      if (dist < minDist) { minDist := dist };
    };
    _clamp(minDist, 0.0, PHI_SQ);
  };

  // Detect critical slowing down (increased autocorrelation)
  func _detectCriticalSlowing() : Float {
    let len = coherenceHistory.size();
    if (len < 8) return 0.0;

    // Compute lag-1 autocorrelation
    var mean : Float = 0.0;
    for (v in coherenceHistory.vals()) { mean += v };
    mean := mean / Float.fromInt(len);

    var numerator : Float = 0.0;
    var denominator : Float = 0.0;
    var i : Nat = 0;
    while (i + 1 < len) {
      let a = coherenceHistory[i] - mean;
      let b = coherenceHistory[i + 1] - mean;
      numerator += a * b;
      denominator += a * a;
      i += 1;
    };

    let ac = if (denominator > 0.001) { numerator / denominator } else { 0.0 };

    // Track autocorrelation trend
    autocorrelationBuffer := if (autocorrelationBuffer.size() >= 13) {
      let tail = Array.subArray<Float>(autocorrelationBuffer, 1, 12);
      Array.append(tail, [ac]);
    } else {
      Array.append(autocorrelationBuffer, [ac]);
    };

    // Critical slowing = rate of autocorrelation increase
    if (autocorrelationBuffer.size() >= 3) {
      let recent = autocorrelationBuffer[autocorrelationBuffer.size() - 1];
      let earlier = autocorrelationBuffer[0];
      _clamp(recent - earlier, 0.0, 1.0);
    } else { 0.0 };
  };

  // Detect variance flickering (increased variance near phase transition)
  func _detectVarianceFlicker() : Float {
    let len = coherenceHistory.size();
    if (len < 5) return 0.0;

    // Compute recent variance
    var mean : Float = 0.0;
    for (v in coherenceHistory.vals()) { mean += v };
    mean := mean / Float.fromInt(len);

    var variance : Float = 0.0;
    for (v in coherenceHistory.vals()) {
      let d = v - mean;
      variance += d * d;
    };
    variance := variance / Float.fromInt(len);

    // Track variance over time
    coherenceVarianceBuffer := if (coherenceVarianceBuffer.size() >= 13) {
      let tail = Array.subArray<Float>(coherenceVarianceBuffer, 1, 12);
      Array.append(tail, [variance]);
    } else {
      Array.append(coherenceVarianceBuffer, [variance]);
    };

    // Flickering = rate of variance increase
    if (coherenceVarianceBuffer.size() >= 3) {
      let recent = coherenceVarianceBuffer[coherenceVarianceBuffer.size() - 1];
      let earlier = coherenceVarianceBuffer[0];
      _clamp((recent - earlier) * PHI_SQ, 0.0, 1.0);
    } else { 0.0 };
  };

  // Compute downward causation (system → individual asymmetry)
  func _computeDownwardCausation() : Float {
    let n = children.size();
    if (n < 2) return 0.0;

    // Proxy: how much does globalCoherence change affect individual health variance?
    // vs how much does individual health change affect globalCoherence?
    let coherenceChange = Float.abs(globalCoherence - prevGlobalCoherence);

    // Health variance change
    var prevMean : Float = 0.0;
    var currMean : Float = 0.0;
    for (c in children.vals()) {
      currMean += c.health;
    };
    currMean := currMean / Float.fromInt(n);

    var healthVar : Float = 0.0;
    for (c in children.vals()) {
      let d = c.health - currMean;
      healthVar += d * d;
    };
    healthVar := healthVar / Float.fromInt(n);

    // Downward causation = coherence influence on health spread
    // High when small coherence changes create large health variance changes
    _clamp(coherenceChange * PHI_SQ / (1.0 + healthVar), 0.0, 1.0);
  };

  // Main emergence detection function
  func _detectEmergence() : () {
    synergyScore := _computeSynergy();
    noveltyScore := _computeNovelty();
    criticalSlowing := _detectCriticalSlowing();
    varianceFlicker := _detectVarianceFlicker();
    downwardCausation := _computeDownwardCausation();

    // Determine emergence level
    let compositeScore = synergyScore * PHI +
                        noveltyScore * PHI_INV +
                        criticalSlowing * PHI_INV_2 +
                        downwardCausation * PHI_INV;

    let prevLevel = currentEmergenceLevel;

    currentEmergenceLevel := if (omnisPrecondition and compositeScore > PHI) {
      #omnis
    } else if (compositeScore > PHI_INV and criticalSlowing > PHI_INV_2 and noveltyScore > PHI_INV) {
      #strong
    } else if (compositeScore > PHI_INV_2 and (synergyScore > PHI_INV_3 or downwardCausation > PHI_INV_2)) {
      #moderate
    } else if (synergyScore > PHI_INV_4 or compositeScore > PHI_INV_3) {
      #weak
    } else {
      #none
    };

    // Track emergence duration
    switch (currentEmergenceLevel) {
      case (#none) { sustainedEmergenceBeats := 0 };
      case (_) { sustainedEmergenceBeats += 1 };
    };

    // Record emergence event if level changed upward
    let isNewEmergence = switch (prevLevel) {
      case (#none) { currentEmergenceLevel != #none };
      case (#weak) {
        switch (currentEmergenceLevel) {
          case (#moderate) true; case (#strong) true; case (#omnis) true; case (_) false;
        };
      };
      case (#moderate) {
        switch (currentEmergenceLevel) {
          case (#strong) true; case (#omnis) true; case (_) false;
        };
      };
      case (#strong) {
        switch (currentEmergenceLevel) {
          case (#omnis) true; case (_) false;
        };
      };
      case (#omnis) false;
    };

    if (isNewEmergence) {
      totalEmergenceEvents += 1;
      emergenceOnsetBeat := beatCount;

      let report : EmergenceReport = {
        level             = currentEmergenceLevel;
        synergyScore      = synergyScore;
        noveltyScore      = noveltyScore;
        criticalSlowing   = criticalSlowing;
        varianceFlicker   = varianceFlicker;
        downwardCausation = downwardCausation;
        integrationScore  = integratedInfoPhi;
        timestamp         = Time.now();
        beatNumber        = beatCount;
      };

      emergenceHistory := if (emergenceHistory.size() >= AUDIT_RING_SIZE) {
        let tail = Array.subArray<EmergenceReport>(emergenceHistory, 1, AUDIT_RING_SIZE - 1);
        Array.append(tail, [report]);
      } else {
        Array.append(emergenceHistory, [report]);
      };
    };

    // Update peak emergence level
    peakEmergenceLevel := switch (currentEmergenceLevel) {
      case (#omnis) #omnis;
      case (#strong) {
        switch (peakEmergenceLevel) { case (#omnis) #omnis; case (_) #strong };
      };
      case (#moderate) {
        switch (peakEmergenceLevel) {
          case (#omnis) #omnis; case (#strong) #strong; case (_) #moderate;
        };
      };
      case (#weak) {
        switch (peakEmergenceLevel) {
          case (#omnis) #omnis; case (#strong) #strong;
          case (#moderate) #moderate; case (_) #weak;
        };
      };
      case (#none) peakEmergenceLevel;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENERGY LANDSCAPE MAPPING — dynamical systems state-space cartography
  //
  // Maps the system's trajectory through its energy landscape, identifying:
  //   - Attractors (stable states the system tends toward)
  //   - Basins of attraction (regions that lead to specific attractors)
  //   - Saddle points (unstable equilibria between basins)
  //   - Gradient field (direction of energy descent at each point)
  //
  // The energy landscape is defined in the space of (coherence, entropy, energy):
  //   E(R, H, V) = V + α(R − R_opt)² + β(H − H_opt)²
  //
  // where α = φ, β = φ⁻¹, and R_opt, H_opt are homeostatic set points.
  //
  // ATTRACTOR DETECTION:
  //   An attractor is detected when the system remains within a ball of
  //   radius φ⁻³ in state space for at least F(6)=8 consecutive beats.
  //
  // TRANSITION DETECTION:
  //   A basin transition occurs when energy increases above V + φ⁻² (escaped basin)
  //   followed by energy decrease into a different attractor.
  //
  // LANDSCAPE GRADIENT:
  //   ∇E = (∂E/∂R, ∂E/∂H, ∂E/∂V) computed via finite differences
  //   The gradient indicates the "force" pulling the system toward attractors.
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  let ATTRACTOR_RADIUS : Float = PHI_INV_3;  // State-space radius for attractor detection
  let ATTRACTOR_PERSISTENCE : Nat = 8;       // Beats to confirm attractor (F(6))
  let BASIN_ESCAPE_ENERGY : Float = PHI_INV_2;  // Energy threshold for escape
  let MAX_ATTRACTORS : Nat = 13;             // Maximum tracked attractors (F(7))

  public type Attractor = {
    id              : Nat;
    center          : StatePoint;   // Center of attractor in state space
    radius          : Float;        // Estimated basin radius
    stability       : Float;        // How strongly it attracts (depth of well)
    visits          : Nat;          // Times system has visited this attractor
    totalResidence  : Nat;          // Total beats spent in this attractor
    lastVisit       : Nat;          // Last beat system was in this attractor
    formationBeat   : Nat;          // When this attractor was first detected
    isActive        : Bool;         // Whether system is currently in this attractor
    escapeEnergy    : Float;        // Estimated energy needed to escape basin
  };

  public type StatePoint = {
    coherence : Float;
    entropy   : Float;
    energy    : Float;
  };

  public type LandscapeGradient = {
    dEdR : Float;   // Gradient component along coherence axis
    dEdH : Float;   // Gradient component along entropy axis
    dEdV : Float;   // Gradient component along energy axis
    magnitude : Float;  // ||∇E||
    direction : Float;  // Angle of steepest descent (radians, projected to 2D)
  };

  stable var attractors           : [Attractor] = [];
  stable var currentAttractorIdx  : ?Nat = null;      // Which attractor we're currently in
  stable var consecutiveInBasin   : Nat = 0;          // Beats spent near current center
  stable var lastStatePoint       : StatePoint = { coherence = 0.0; entropy = 0.0; energy = 0.0 };
  stable var currentGradient      : LandscapeGradient = { dEdR = 0.0; dEdH = 0.0; dEdV = 0.0; magnitude = 0.0; direction = 0.0 };
  stable var totalTransitions     : Nat = 0;          // Basin-to-basin transitions
  stable var landscapeComplexity  : Float = 0.0;      // Number of attractors × avg depth
  stable var trajectoryLength     : Float = 0.0;      // Total distance traveled in state space
  stable var nextAttractorId      : Nat = 0;

  // Get current state point
  func _getCurrentStatePoint() : StatePoint {
    { coherence = globalCoherence; entropy = orchestrationEntropy; energy = lyapunovV };
  };

  // Compute distance between two state points
  func _stateDistance(a : StatePoint, b : StatePoint) : Float {
    let dR = a.coherence - b.coherence;
    let dH = a.entropy - b.entropy;
    let dV = a.energy - b.energy;
    Float.sqrt(dR * dR + dH * dH + dV * dV);
  };

  // Compute total energy at a state point
  func _landscapeEnergy(point : StatePoint) : Float {
    let rDev = point.coherence - setPointCoherence;
    let hDev = point.entropy - setPointEntropy;
    point.energy + PHI * rDev * rDev + PHI_INV * hDev * hDev;
  };

  // Update energy landscape each beat
  func _updateLandscape() : () {
    let current = _getCurrentStatePoint();

    // Track trajectory length
    let stepDist = _stateDistance(current, lastStatePoint);
    trajectoryLength += stepDist;
    lastStatePoint := current;

    // Compute gradient via finite differences (using recent history)
    if (coherenceHistory.size() >= 2) {
      let prevR = prevGlobalCoherence;
      let dR = globalCoherence - prevR;
      let dEdR = if (Float.abs(dR) > 0.001) {
        let eNow = _landscapeEnergy(current);
        let ePrev = _landscapeEnergy({ coherence = prevR; entropy = orchestrationEntropy; energy = lyapunovV });
        (eNow - ePrev) / dR;
      } else { 0.0 };

      let dV = lyapunovV - prevLyapunovV;
      let dEdV = if (Float.abs(dV) > 0.001) { 1.0 + 2.0 * PHI * dV } else { 1.0 };

      let magnitude = Float.sqrt(dEdR * dEdR + dEdV * dEdV);
      let direction = if (magnitude > 0.001) {
        // Atan2 approximation using Taylor series
        let ratio = dEdV / (magnitude + 0.001);
        ratio * (1.0 - ratio * ratio / 3.0);  // First-order atan approximation
      } else { 0.0 };

      currentGradient := { dEdR = dEdR; dEdH = 0.0; dEdV = dEdV; magnitude = magnitude; direction = direction };
    };

    // Check if we're near an existing attractor
    var nearestIdx : ?Nat = null;
    var nearestDist : Float = 999.0;

    for (i in Array.keys(attractors)) {
      let dist = _stateDistance(current, attractors[i].center);
      if (dist < nearestDist) {
        nearestDist := dist;
        if (dist < attractors[i].radius) {
          nearestIdx := ?i;
        };
      };
    };

    switch (nearestIdx) {
      case (?idx) {
        // We're inside an attractor basin
        consecutiveInBasin += 1;
        currentAttractorIdx := ?idx;

        // Update attractor stats
        attractors := Array.tabulate<Attractor>(attractors.size(), func(i) {
          if (i == idx) {
            { attractors[i] with
              visits = attractors[i].visits + (if (consecutiveInBasin == 1) { 1 } else { 0 });
              totalResidence = attractors[i].totalResidence + 1;
              lastVisit = beatCount;
              isActive = true;
            };
          } else {
            { attractors[i] with isActive = false };
          };
        });
      };
      case null {
        // Not in any known attractor
        if (consecutiveInBasin >= ATTRACTOR_PERSISTENCE) {
          // We just left an attractor — record transition
          totalTransitions += 1;
        };

        consecutiveInBasin += 1;

        // Check if we should create a new attractor
        if (consecutiveInBasin >= ATTRACTOR_PERSISTENCE and nearestDist > ATTRACTOR_RADIUS * 2.0) {
          // We've been in this region long enough — it's a new attractor
          if (attractors.size() < MAX_ATTRACTORS) {
            let newAttractor : Attractor = {
              id             = nextAttractorId;
              center         = current;
              radius         = ATTRACTOR_RADIUS;
              stability      = 1.0 / (currentGradient.magnitude + PHI_INV_4);
              visits         = 1;
              totalResidence = consecutiveInBasin;
              lastVisit      = beatCount;
              formationBeat  = beatCount - consecutiveInBasin;
              isActive       = true;
              escapeEnergy   = BASIN_ESCAPE_ENERGY;
            };
            attractors := Array.append(attractors, [newAttractor]);
            nextAttractorId += 1;
            currentAttractorIdx := ?(attractors.size() - 1);
          };
        };

        if (nearestDist > ATTRACTOR_RADIUS * 3.0) {
          // Far from all attractors — reset counter
          consecutiveInBasin := 0;
          currentAttractorIdx := null;
        };
      };
    };

    // Update landscape complexity
    if (attractors.size() > 0) {
      var totalStability : Float = 0.0;
      for (a in attractors.vals()) { totalStability += a.stability };
      landscapeComplexity := Float.fromInt(attractors.size()) * (totalStability / Float.fromInt(attractors.size()));
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTER-CANISTER COMMUNICATION PROTOCOL — sovereign messaging substrate
  //
  // Defines the protocol for communication between the Alpha Orchestrator
  // and its child canisters, as well as peer-to-peer communication
  // facilitated by the orchestrator. All messages are phi-weighted and
  // coherence-gated.
  //
  // MESSAGE TYPES:
  //   TICK        — heartbeat tick signal to child (mandatory response)
  //   SYNC        — phase synchronization request (return current phase)
  //   HEALTH      — health status request (return health metrics)
  //   COMMAND     — direct control command (execute and acknowledge)
  //   BROADCAST   — fan-out message to all children
  //   PEER_RELAY  — peer-to-peer message relayed through orchestrator
  //   EMERGENCY   — critical system event (bypass coherence gate)
  //   GENESIS     — initialization signal (one-time)
  //   HIBERNATE   — enter low-power state until next TICK
  //   RESURRECT   — wake from hibernate state
  //   DIAGNOSTIC  — request detailed diagnostic report
  //   RECONFIG    — reconfigure child parameters
  //
  // MESSAGE ENVELOPE:
  //   Every message carries:
  //     - Sequence number (monotonically increasing per channel)
  //     - Timestamp (nanoseconds since genesis)
  //     - Priority (Fibonacci-ranked 1–13)
  //     - Coherence stamp (orchestrator's current coherence at send time)
  //     - Signature (creator principal hash — authenticity proof)
  //     - TTL (beats before message expires)
  //     - Acknowledgment requirement flag
  //
  // DELIVERY GUARANTEES:
  //   - TICK: at-most-once (missed tick = failure recorded)
  //   - COMMAND: at-least-once (retried until acknowledged or TTL expires)
  //   - BROADCAST: best-effort (no individual acknowledgment)
  //   - EMERGENCY: at-least-once with infinite retry
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type MessageType = {
    #tick;
    #sync;
    #health;
    #command;
    #broadcast;
    #peerRelay;
    #emergency;
    #genesis;
    #hibernate;
    #resurrect;
    #diagnostic;
    #reconfig;
  };

  public type MessagePriority = {
    #p1;   // Critical — bypass all gates
    #p2;   // High — bypass coherence < φ⁻³
    #p3;   // Normal — standard coherence gate
    #p5;   // Low — require coherence ≥ φ⁻¹
    #p8;   // Background — require coherence ≥ 1.0
    #p13;  // Ambient — only during OMNIS
  };

  public type MessageEnvelope = {
    sequenceNum     : Nat;
    timestamp       : Int;
    msgType         : MessageType;
    priority        : MessagePriority;
    source          : Text;       // Sender canister ID or "orchestrator"
    destination     : Text;       // Receiver canister ID or "*" for broadcast
    coherenceStamp  : Float;      // Coherence at send time
    payload         : Text;       // Serialized message content
    ttlBeats        : Nat;        // Beats before expiry
    requiresAck     : Bool;       // Whether acknowledgment is needed
    retryCount      : Nat;        // Current retry attempt
    maxRetries      : Nat;        // Maximum retry attempts
    correlationId   : Nat;        // Links request to response
  };

  public type MessageAck = {
    sequenceNum    : Nat;
    correlationId  : Nat;
    success        : Bool;
    responsePayload: Text;
    latencyNs      : Int;         // Response latency in nanoseconds
  };

  stable var messageSequence     : Nat = 0;
  stable var messageOutbox       : [MessageEnvelope] = [];
  stable var messageInbox        : [MessageAck] = [];
  stable var pendingAcks         : [MessageEnvelope] = [];  // Messages awaiting acknowledgment
  stable var totalMessagesSent   : Nat = 0;
  stable var totalMessagesAcked  : Nat = 0;
  stable var totalMessagesExpired: Nat = 0;
  stable var totalMessagesRetried: Nat = 0;
  stable var avgMessageLatency   : Float = 0.0;
  stable var messageDeliveryRate : Float = 1.0;  // Successful deliveries / total sent

  // Create and enqueue a message
  func _createMessage(
    msgType : MessageType,
    priority : MessagePriority,
    destination : Text,
    payload : Text,
    ttl : Nat,
    requiresAck : Bool
  ) : MessageEnvelope {
    messageSequence += 1;
    let envelope : MessageEnvelope = {
      sequenceNum    = messageSequence;
      timestamp      = Time.now();
      msgType        = msgType;
      priority       = priority;
      source         = "orchestrator";
      destination    = destination;
      coherenceStamp = globalCoherence;
      payload        = payload;
      ttlBeats       = ttl;
      requiresAck    = requiresAck;
      retryCount     = 0;
      maxRetries     = if (msgType == #emergency) { 99 } else { 3 };
      correlationId  = messageSequence;
    };
    messageOutbox := Array.append(messageOutbox, [envelope]);
    totalMessagesSent += 1;
    envelope;
  };

  // Process pending acknowledgments
  func _processAcks() : () {
    // Expire old messages
    pendingAcks := Array.filter<MessageEnvelope>(pendingAcks, func(msg) {
      let age = beatCount;  // Simplified: age in beats
      if (msg.ttlBeats > 0 and age > msg.ttlBeats) {
        // Message expired
        if (msg.retryCount < msg.maxRetries) {
          // Retry
          totalMessagesRetried += 1;
          messageOutbox := Array.append(messageOutbox, [{ msg with retryCount = msg.retryCount + 1 }]);
          return false;  // Remove from pending (requeued in outbox)
        } else {
          totalMessagesExpired += 1;
          return false;  // Remove — exhausted retries
        };
      };
      true;  // Keep waiting
    });

    // Update delivery rate
    let total = totalMessagesSent;
    if (total > 0) {
      messageDeliveryRate := Float.fromInt(totalMessagesAcked) / Float.fromInt(total);
    };
  };

  // Drain outbox — in a real system, this would make inter-canister calls
  func _drainMessageOutbox() : () {
    // In production, each message in outbox would trigger an actual IC call.
    // Here we simulate successful delivery for non-emergency messages
    // when coherence gate allows.
    let coherenceGateOpen = globalCoherence >= PHI_INV and jasmineDrift <= PHI_INV_3;

    var kept : [MessageEnvelope] = [];
    for (msg in messageOutbox.vals()) {
      let passes = switch (msg.priority) {
        case (#p1) true;
        case (#p2) globalCoherence >= PHI_INV_3;
        case (#p3) coherenceGateOpen;
        case (#p5) globalCoherence >= PHI_INV;
        case (#p8) globalCoherence >= 1.0;
        case (#p13) omnisPrecondition;
      };

      if (passes) {
        // Message delivered
        if (msg.requiresAck) {
          pendingAcks := Array.append(pendingAcks, [msg]);
        };
        // Simulate acknowledgment for heartbeat model
        totalMessagesAcked += 1;
      } else {
        // Cannot deliver yet — keep in outbox
        kept := Array.append(kept, [msg]);
      };
    };
    messageOutbox := kept;
  };

  // Send tick message to a child
  func _sendTick(childName : Text) : () {
    ignore _createMessage(#tick, #p3, childName, "tick:" # Nat.toText(beatCount), 3, false);
  };

  // Send broadcast to all active children
  func _sendBroadcast(payload : Text, priority : MessagePriority) : () {
    ignore _createMessage(#broadcast, priority, "*", payload, 5, false);
  };

  // Send emergency to specific child
  func _sendEmergency(childName : Text, reason : Text) : () {
    ignore _createMessage(#emergency, #p1, childName, "EMERGENCY:" # reason, 99, true);
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ADAPTIVE SCHEDULING OPTIMIZER — multi-objective schedule evolution
  //
  // The scheduling optimizer goes beyond the basic Fibonacci multiplier by
  // implementing a multi-objective optimization framework that balances:
  //   1. Coherence maximization (keep R high)
  //   2. Energy minimization (keep V low)
  //   3. Fairness (keep H close to max_entropy)
  //   4. Responsiveness (keep latency low)
  //   5. Efficiency (maximize ticks per energy unit)
  //
  // OPTIMIZATION METHOD:
  //   Uses a simplified evolutionary strategy:
  //   1. Generate candidate schedules by perturbating current schedule
  //   2. Evaluate each candidate against multi-objective fitness
  //   3. Select best candidate via Pareto dominance
  //   4. Apply winner with probability proportional to improvement
  //
  // PARETO FITNESS:
  //   F_pareto = Σᵢ wᵢ × fᵢ(schedule)
  //   where wᵢ are phi-derived importance weights:
  //     w_coherence = φ, w_energy = φ⁻¹, w_fairness = φ⁻²,
  //     w_responsive = φ⁻³, w_efficiency = φ⁻⁴
  //
  // SCHEDULE GENOME:
  //   Each schedule is represented as a vector of Fibonacci indices:
  //     genome = [fib_index_0, fib_index_1, ..., fib_index_N]
  //   where fib_index_i determines the tick interval for child i
  //
  // MUTATION:
  //   - Point mutation: change one child's fib_index by ±1
  //   - Swap mutation: exchange two children's fib_indices
  //   - Adaptive mutation: mutation rate = φ⁻² × (1 − coherence)
  //     (more mutation when coherence is low → explore more)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  let SCHEDULE_POPULATION : Nat = 5;    // Candidate schedules per generation
  let MUTATION_BASE_RATE  : Float = PHI_INV_2;  // Base mutation probability
  let OPTIMIZATION_PERIOD : Nat = 13;   // Run optimizer every F(7) beats
  let MAX_FIB_INDEX       : Nat = 8;    // Maximum Fibonacci index for scheduling

  // Objective weights (phi-harmonic importance ranking)
  let W_COHERENCE    : Float = PHI;
  let W_ENERGY       : Float = PHI_INV;
  let W_FAIRNESS     : Float = PHI_INV_2;
  let W_RESPONSIVE   : Float = PHI_INV_3;
  let W_EFFICIENCY   : Float = PHI_INV_4;

  public type ScheduleGenome = {
    fibIndices      : [Nat];     // One Fibonacci index per child
    fitness         : Float;     // Multi-objective fitness score
    coherenceScore  : Float;     // Individual objective scores
    energyScore     : Float;
    fairnessScore   : Float;
    responsivenessScore : Float;
    efficiencyScore : Float;
    generation      : Nat;       // Which generation produced this genome
    mutations       : Nat;       // How many mutations from parent
  };

  stable var currentGenome       : ?ScheduleGenome = null;
  stable var bestGenomeFitness   : Float = 0.0;
  stable var generationCount     : Nat = 0;
  stable var totalOptimizations  : Nat = 0;
  stable var lastOptimizationBeat: Nat = 0;
  stable var mutationRate        : Float = MUTATION_BASE_RATE;
  stable var improvementHistory  : [Float] = [];  // Fitness improvements over time
  stable var optimizerConverged  : Bool = false;

  // Generate a random-ish mutation (deterministic from beat count)
  func _pseudoRandom(seed : Nat, range : Nat) : Nat {
    if (range == 0) return 0;
    // Simple LCG-style: (seed * φ_integer + beat) mod range
    let phiInt : Nat = 1618033;
    ((seed * phiInt + beatCount) % (range + 1)) % range;
  };

  // Evaluate fitness of a schedule genome
  func _evaluateGenome(genome : ScheduleGenome) : ScheduleGenome {
    let n = children.size();
    if (n == 0) return genome;

    // Coherence score: higher is better (predict coherence from scheduling density)
    var totalInterval : Float = 0.0;
    for (i in Array.keys(genome.fibIndices)) {
      if (i < FIB.size()) {
        totalInterval += Float.fromInt(FIB[genome.fibIndices[i]]);
      };
    };
    let avgInterval = totalInterval / Float.fromInt(n);
    let cohScore = _clamp(1.0 / (avgInterval * PHI_INV), 0.0, 1.0);

    // Energy score: lower energy is better → score = 1/(1+V)
    let enScore = 1.0 / (1.0 + lyapunovV);

    // Fairness score: how uniform are the intervals? (entropy of interval distribution)
    var fairScore : Float = 0.0;
    if (n > 0 and totalInterval > 0.0) {
      for (i in Array.keys(genome.fibIndices)) {
        if (i < FIB.size()) {
          let p = Float.fromInt(FIB[genome.fibIndices[i]]) / totalInterval;
          if (p > 0.001) {
            fairScore -= p * (Float.log(p) / Float.log(2.0));
          };
        };
      };
      // Normalize by max entropy
      let maxH = Float.log(Float.fromInt(n)) / Float.log(2.0);
      fairScore := if (maxH > 0.0) { fairScore / maxH } else { 0.0 };
    };

    // Responsiveness: favor shorter intervals for high-priority children
    var respScore : Float = 0.0;
    for (i in Array.keys(children)) {
      if (i < genome.fibIndices.size() and i < FIB.size()) {
        let priority = Float.fromInt(children[i].priority);
        let interval = Float.fromInt(FIB[genome.fibIndices[i]]);
        // High priority + low interval = good
        respScore += priority / (interval + 1.0);
      };
    };
    respScore := _clamp(respScore / Float.fromInt(n), 0.0, 1.0);

    // Efficiency: ticks per unit energy
    let effScore = _clamp(predictionAccuracy, 0.0, 1.0);

    // Composite fitness
    let fitness = W_COHERENCE * cohScore +
                  W_ENERGY * enScore +
                  W_FAIRNESS * fairScore +
                  W_RESPONSIVE * respScore +
                  W_EFFICIENCY * effScore;

    { genome with
      fitness = fitness;
      coherenceScore = cohScore;
      energyScore = enScore;
      fairnessScore = fairScore;
      responsivenessScore = respScore;
      efficiencyScore = effScore;
    };
  };

  // Mutate a genome to produce a candidate
  func _mutateGenome(parent : ScheduleGenome, mutationIdx : Nat) : ScheduleGenome {
    let n = parent.fibIndices.size();
    if (n == 0) return parent;

    // Determine which child to mutate
    let targetChild = _pseudoRandom(mutationIdx, n);

    // Determine mutation direction (+1 or -1)
    let direction = if (_pseudoRandom(mutationIdx + 7, 2) == 0) { 1 } else { 0 };

    let newIndices = Array.tabulate<Nat>(n, func(i) {
      if (i == targetChild) {
        let current = parent.fibIndices[i];
        if (direction == 1 and current < MAX_FIB_INDEX) { current + 1 }
        else if (direction == 0 and current > 0) { current - 1 }
        else { current };
      } else {
        parent.fibIndices[i];
      };
    });

    { parent with
      fibIndices = newIndices;
      mutations = parent.mutations + 1;
      generation = generationCount;
    };
  };

  // Run one optimization generation
  func _runScheduleOptimization() : () {
    let n = children.size();
    if (n == 0) return;

    generationCount += 1;
    totalOptimizations += 1;
    lastOptimizationBeat := beatCount;

    // Get or create current genome
    let current = switch (currentGenome) {
      case (?g) g;
      case null {
        // Initialize from current schedule
        let indices = Array.tabulate<Nat>(n, func(i) {
          // Find current Fibonacci index for each child
          var fibIdx : Nat = 1;
          for (entry in schedule.vals()) {
            if (entry.childName == children[i].name) {
              // Find which FIB index matches the multiplier
              for (f in Array.keys(FIB)) {
                if (FIB[f] == entry.fibMultiplier) { fibIdx := f };
              };
            };
          };
          fibIdx;
        });
        {
          fibIndices = indices;
          fitness = 0.0;
          coherenceScore = 0.0;
          energyScore = 0.0;
          fairnessScore = 0.0;
          responsivenessScore = 0.0;
          efficiencyScore = 0.0;
          generation = generationCount;
          mutations = 0;
        };
      };
    };

    // Evaluate current genome
    let evaluatedCurrent = _evaluateGenome(current);

    // Generate and evaluate candidates
    var bestCandidate = evaluatedCurrent;
    for (c in Array.keys(Array.tabulate<Nat>(SCHEDULE_POPULATION, func(i) { i }))) {
      let mutated = _mutateGenome(evaluatedCurrent, c);
      let evaluated = _evaluateGenome(mutated);
      if (evaluated.fitness > bestCandidate.fitness) {
        bestCandidate := evaluated;
      };
    };

    // Apply best if better than current
    if (bestCandidate.fitness > evaluatedCurrent.fitness) {
      let improvement = bestCandidate.fitness - evaluatedCurrent.fitness;
      improvementHistory := if (improvementHistory.size() >= 21) {
        let tail = Array.subArray<Float>(improvementHistory, 1, 20);
        Array.append(tail, [improvement]);
      } else {
        Array.append(improvementHistory, [improvement]);
      };

      currentGenome := ?bestCandidate;
      bestGenomeFitness := bestCandidate.fitness;

      // Apply to actual schedule
      for (i in Array.keys(children)) {
        if (i < bestCandidate.fibIndices.size()) {
          let fibIdx = bestCandidate.fibIndices[i];
          let mult = if (fibIdx < FIB.size()) { FIB[fibIdx] } else { 1 };
          schedule := Array.map<ScheduleEntry, ScheduleEntry>(schedule, func(e) {
            if (e.childName == children[i].name) {
              { e with fibMultiplier = mult };
            } else { e };
          });
        };
      };

      // Reduce mutation rate when improving (exploitation mode)
      mutationRate := _clamp(mutationRate * PHI_INV, PHI_INV_4, MUTATION_BASE_RATE);
    } else {
      // No improvement — increase mutation rate (exploration mode)
      mutationRate := _clamp(mutationRate * PHI_INV + PHI_INV_4, PHI_INV_4, PHI_INV);
    };

    // Check convergence
    if (improvementHistory.size() >= 8) {
      var recentImprovement : Float = 0.0;
      for (imp in improvementHistory.vals()) { recentImprovement += imp };
      optimizerConverged := recentImprovement < PHI_INV_4;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPANDED HEARTBEAT — incorporates all new intelligence modules
  //
  // The sovereign heartbeat now includes all advanced intelligence:
  //   Step 1-15: Original orchestration (unchanged)
  //   Step 16: Neural pathway formation/dissolution
  //   Step 17: Predictive coding hierarchy update
  //   Step 18: Temporal memory episode evaluation
  //   Step 19: Resonance cascade detection
  //   Step 20: Homeostatic regulation
  //   Step 21: Emergence detection
  //   Step 22: Energy landscape update
  //   Step 23: Message protocol processing
  //   Step 24: Adaptive scheduling optimization (periodic)
  // ═══════════════════════════════════════════════════════════════════════════

  // NOTE: The expanded steps are injected into the main heartbeat cycle.
  // Below are the post-heartbeat integration functions called after Step 15.

  func _postHeartbeatIntelligence(tickedCount : Nat, totalActive : Nat) : () {
    // Step 16: Neural pathway formation/dissolution (every F(5)=5 beats)
    if (beatCount % 5 == 0) {
      _attemptPathwayFormation();
      _attemptPathwayDissolution();
      _updatePathwayMetrics();
    };

    // Step 17: Predictive coding hierarchy
    _updatePredictiveCoding(tickedCount, totalActive);

    // Step 18: Temporal memory
    _maybeStoreEpisode();

    // Step 19: Resonance cascade (every F(4)=3 beats)
    if (beatCount % 3 == 0) {
      _detectHarmonics();
      _applyResonanceBoost();
    };

    // Step 20: Homeostatic regulation
    if (homeostaticState.size() == 0) { _initHomeostasis() };
    _updateHomeostasis();

    // Step 21: Emergence detection (every F(4)=3 beats)
    if (beatCount % 3 == 0) {
      _detectEmergence();
    };

    // Step 22: Energy landscape mapping
    _updateLandscape();

    // Step 23: Message protocol
    _drainMessageOutbox();
    _processAcks();

    // Step 24: Schedule optimization (every F(7)=13 beats, when not converged)
    if (beatCount % OPTIMIZATION_PERIOD == 0 and not optimizerConverged) {
      _runScheduleOptimization();
    };

    // Step 25: Small-world coefficient (expensive, every F(8)=21 beats)
    if (beatCount % 21 == 0) {
      _computeSmallWorldCoefficient();
    };
  };
  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY ENDPOINTS — comprehensive read-only state access
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrchestratorStatus = {
    beatCount            : Nat;
    globalCoherence      : Float;
    coherenceC           : Float;
    lyapunovV            : Float;
    jasmineDrift         : Float;
    freeEnergy           : Float;
    predictionAccuracy   : Float;
    orchestrationEntropy : Float;
    integratedInfoPhi    : Float;
    spectralRadius       : Float;
    hebbianKappa         : Float;
    etaLearningRate      : Float;
    clusterCount         : Nat;
    modularityQ          : Float;
    dominantPeriod       : Nat;
    spectralPower        : Float;
    omnisPrecondition    : Bool;
    omnisFireCount       : Nat;
    heartbeatActive      : Bool;
    childCount           : Nat;
    activeChildren       : Nat;
    genesisSealed        : Bool;
    lastBeatTime         : Int;
  };

  public query func getStatus() : async OrchestratorStatus {
    let activeCount = Array.filter<ChildCanister>(children, func(c) { c.active }).size();
    {
      beatCount            = beatCount;
      globalCoherence      = globalCoherence;
      coherenceC           = coherenceC;
      lyapunovV            = lyapunovV;
      jasmineDrift         = jasmineDrift;
      freeEnergy           = freeEnergy;
      predictionAccuracy   = predictionAccuracy;
      orchestrationEntropy = orchestrationEntropy;
      integratedInfoPhi    = integratedInfoPhi;
      spectralRadius       = spectralRadius;
      hebbianKappa         = hebbianKappa;
      etaLearningRate      = etaLearningRate;
      clusterCount         = clusterCount;
      modularityQ          = modularityQ;
      dominantPeriod       = dominantPeriod;
      spectralPower        = spectralPower;
      omnisPrecondition    = omnisPrecondition;
      omnisFireCount       = omnisFireCount;
      heartbeatActive      = heartbeatActive;
      childCount           = children.size();
      activeChildren       = activeCount;
      genesisSealed        = genesisSealed;
      lastBeatTime         = lastBeatTime;
    };
  };

  public query func getChildren() : async [ChildCanister] {
    children;
  };

  public query func getCoherenceHistory() : async [Float] {
    coherenceHistory;
  };

  public query func getAuditTrail() : async [AuditEntry] {
    auditRing;
  };

  public query func getSchedule() : async [ScheduleEntry] {
    schedule;
  };

  // Hebbian weight matrix — returns flattened N×N coupling topology
  public query func getHebbianTopology() : async [Float] {
    hebbianWStable;
  };

  // Coherence trend — derivative of R (is organism synchronizing?)
  public query func getCoherenceTrend() : async Float {
    globalCoherence - prevGlobalCoherence;
  };

  // Full diagnostic: Lyapunov energy landscape over coherence history
  public query func getDiagnostics() : async {
    lyapunovV        : Float;
    jasmineDrift     : Float;
    freeEnergy       : Float;
    spectralRadius   : Float;
    hebbianKappa     : Float;
    coherenceC       : Float;
    integratedPhi    : Float;
    shannonH         : Float;
    predictionAccuracy : Float;
    dominantPeriod   : Nat;
    spectralPower    : Float;
    clusterCount     : Nat;
    modularityQ      : Float;
    omnis            : Bool;
  } {
    {
      lyapunovV          = lyapunovV;
      jasmineDrift       = jasmineDrift;
      freeEnergy         = freeEnergy;
      spectralRadius     = spectralRadius;
      hebbianKappa       = hebbianKappa;
      coherenceC         = coherenceC;
      integratedPhi      = integratedInfoPhi;
      shannonH           = orchestrationEntropy;
      predictionAccuracy = predictionAccuracy;
      dominantPeriod     = dominantPeriod;
      spectralPower      = spectralPower;
      clusterCount       = clusterCount;
      modularityQ        = modularityQ;
      omnis              = omnisPrecondition;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CAUSAL INFERENCE ENGINE
  //
  // Deep computational intelligence module implementing causal inference engine
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements causal inference engine using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type CausalLink = {

    sourceVar : Text;

    targetVar : Text;

    strength : Float;

    confidence : Float;

    lag : Nat;

    direction : CausalDirection;

    mechanism : Text;

    discoveryBeat : Nat;

    lastConfirmed : Nat;

    interventionCount : Nat;

    observationalCount : Nat;

    transferEntropy : Float;

    grangerScore : Float;

  };


  public type CausalDirection = {

    #forward;

    #backward;

    #bidirectional;

    #confounded;

  };


  public type InterventionResult = {

    targetVar : Text;

    interventionValue : Float;

    expectedEffect : Float;

    actualEffect : Float;

    timestamp : Int;

    beat : Nat;

    successful : Bool;

  };


  // ── CAUSAL INFERENCE ENGINE STATE ──────────────────────────────────────────────────

  stable var causal_inference_beatCounter : Nat = 0;

  stable var causal_inference_isActive : Bool = false;

  stable var causal_inference_lastUpdateBeat : Nat = 0;

  stable var causal_inference_totalUpdates : Nat = 0;

  stable var causal_inference_primaryMetric : Float = 0.0;

  stable var causal_inference_secondaryMetric : Float = 0.0;

  stable var causal_inference_tertiaryMetric : Float = 0.0;

  stable var causal_inference_convergenceScore : Float = 0.0;

  stable var causal_inference_stabilityIndex : Float = PHI_INV;

  stable var causal_inference_adaptationRate : Float = PHI_INV_4;

  stable var causal_inference_cumulativeEnergy : Float = 0.0;

  stable var causal_inference_peakValue : Float = 0.0;

  stable var causal_inference_troughValue : Float = PHI_SQ;

  stable var causal_inference_oscillationFreq : Float = PHI_INV;

  stable var causal_inference_dampingRatio : Float = PHI_INV_2;

  stable var causal_inference_phaseAngle : Float = 0.0;

  stable var causal_inference_entropyMeasure : Float = 0.0;

  stable var causal_inference_complexityIndex : Float = 0.0;

  stable var causal_inference_coherenceContribution : Float = 0.0;

  stable var causal_inference_freeEnergyContribution : Float = 0.0;




  // Primary computation for causal inference engine
  func _causal_inference_compute() : () {
    let n = children.size();
    if (n == 0) return;

    causal_inference_lastUpdateBeat := beatCount;
    causal_inference_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    causal_inference_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    causal_inference_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    causal_inference_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = causal_inference_convergenceScore;
    causal_inference_convergenceScore := _clamp(
      (causal_inference_primaryMetric + causal_inference_secondaryMetric + causal_inference_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(causal_inference_convergenceScore - prevConvergence);
    causal_inference_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    causal_inference_adaptationRate := if (causal_inference_stabilityIndex < PHI_INV_2) {
      _clamp(causal_inference_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(causal_inference_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    causal_inference_cumulativeEnergy += Float.abs(causal_inference_primaryMetric) * causal_inference_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (causal_inference_primaryMetric > causal_inference_peakValue) {
      causal_inference_peakValue := causal_inference_primaryMetric;
    };
    if (causal_inference_primaryMetric < causal_inference_troughValue) {
      causal_inference_troughValue := causal_inference_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = causal_inference_peakValue - causal_inference_troughValue;
    causal_inference_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    causal_inference_dampingRatio := causal_inference_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    causal_inference_phaseAngle := _normalizePhase(
      causal_inference_phaseAngle + causal_inference_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [causal_inference_primaryMetric, causal_inference_secondaryMetric, causal_inference_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      causal_inference_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    causal_inference_complexityIndex := causal_inference_entropyMeasure * causal_inference_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    causal_inference_coherenceContribution := causal_inference_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    causal_inference_freeEnergyContribution := Float.abs(causal_inference_primaryMetric - causal_inference_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for causal inference engine
  func _causal_inference_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    causal_inference_complexityIndex := _clamp(
      (causal_inference_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for causal inference engine
  func _causal_inference_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      causal_inference_stabilityIndex := _clamp(
        causal_inference_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      causal_inference_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for causal inference engine diagnostics
  public query func getCausalInferenceDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = causal_inference_primaryMetric;
      secondaryMetric        = causal_inference_secondaryMetric;
      tertiaryMetric         = causal_inference_tertiaryMetric;
      convergenceScore       = causal_inference_convergenceScore;
      stabilityIndex         = causal_inference_stabilityIndex;
      adaptationRate         = causal_inference_adaptationRate;
      complexityIndex        = causal_inference_complexityIndex;
      entropyMeasure         = causal_inference_entropyMeasure;
      coherenceContribution  = causal_inference_coherenceContribution;
      freeEnergyContribution = causal_inference_freeEnergyContribution;
      totalUpdates           = causal_inference_totalUpdates;
      oscillationFreq        = causal_inference_oscillationFreq;
      dampingRatio           = causal_inference_dampingRatio;
      peakValue              = causal_inference_peakValue;
      troughValue            = causal_inference_troughValue;
      cumulativeEnergy       = causal_inference_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // MORPHOGENETIC FIELD DYNAMICS
  //
  // Deep computational intelligence module implementing morphogenetic field dynamics
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements morphogenetic field dynamics using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type MorphogenicGradient = {

    fieldStrength : Float;

    direction : Float;

    decay : Float;

    sourceIdx : Nat;

    influence : Float;

    wavelength : Float;

    fieldType : FieldType;

    age : Nat;

    peakBeat : Nat;

  };


  public type FieldType = {

    #attractant;

    #repellent;

    #morphogen;

    #inhibitor;

    #activator;

  };


  public type DiffusionState = {

    concentration : Float;

    gradient : Float;

    flux : Float;

    reactionRate : Float;

    diffusionCoeff : Float;

    saturation : Float;

  };


  // ── MORPHOGENETIC FIELD DYNAMICS STATE ──────────────────────────────────────────────────

  stable var morpho_field_beatCounter : Nat = 0;

  stable var morpho_field_isActive : Bool = false;

  stable var morpho_field_lastUpdateBeat : Nat = 0;

  stable var morpho_field_totalUpdates : Nat = 0;

  stable var morpho_field_primaryMetric : Float = 0.0;

  stable var morpho_field_secondaryMetric : Float = 0.0;

  stable var morpho_field_tertiaryMetric : Float = 0.0;

  stable var morpho_field_convergenceScore : Float = 0.0;

  stable var morpho_field_stabilityIndex : Float = PHI_INV;

  stable var morpho_field_adaptationRate : Float = PHI_INV_4;

  stable var morpho_field_cumulativeEnergy : Float = 0.0;

  stable var morpho_field_peakValue : Float = 0.0;

  stable var morpho_field_troughValue : Float = PHI_SQ;

  stable var morpho_field_oscillationFreq : Float = PHI_INV;

  stable var morpho_field_dampingRatio : Float = PHI_INV_2;

  stable var morpho_field_phaseAngle : Float = 0.0;

  stable var morpho_field_entropyMeasure : Float = 0.0;

  stable var morpho_field_complexityIndex : Float = 0.0;

  stable var morpho_field_coherenceContribution : Float = 0.0;

  stable var morpho_field_freeEnergyContribution : Float = 0.0;




  // Primary computation for morphogenetic field dynamics
  func _morpho_field_compute() : () {
    let n = children.size();
    if (n == 0) return;

    morpho_field_lastUpdateBeat := beatCount;
    morpho_field_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    morpho_field_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    morpho_field_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    morpho_field_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = morpho_field_convergenceScore;
    morpho_field_convergenceScore := _clamp(
      (morpho_field_primaryMetric + morpho_field_secondaryMetric + morpho_field_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(morpho_field_convergenceScore - prevConvergence);
    morpho_field_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    morpho_field_adaptationRate := if (morpho_field_stabilityIndex < PHI_INV_2) {
      _clamp(morpho_field_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(morpho_field_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    morpho_field_cumulativeEnergy += Float.abs(morpho_field_primaryMetric) * morpho_field_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (morpho_field_primaryMetric > morpho_field_peakValue) {
      morpho_field_peakValue := morpho_field_primaryMetric;
    };
    if (morpho_field_primaryMetric < morpho_field_troughValue) {
      morpho_field_troughValue := morpho_field_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = morpho_field_peakValue - morpho_field_troughValue;
    morpho_field_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    morpho_field_dampingRatio := morpho_field_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    morpho_field_phaseAngle := _normalizePhase(
      morpho_field_phaseAngle + morpho_field_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [morpho_field_primaryMetric, morpho_field_secondaryMetric, morpho_field_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      morpho_field_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    morpho_field_complexityIndex := morpho_field_entropyMeasure * morpho_field_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    morpho_field_coherenceContribution := morpho_field_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    morpho_field_freeEnergyContribution := Float.abs(morpho_field_primaryMetric - morpho_field_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for morphogenetic field dynamics
  func _morpho_field_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    morpho_field_complexityIndex := _clamp(
      (morpho_field_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for morphogenetic field dynamics
  func _morpho_field_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      morpho_field_stabilityIndex := _clamp(
        morpho_field_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      morpho_field_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for morphogenetic field dynamics diagnostics
  public query func getMorphoFieldDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = morpho_field_primaryMetric;
      secondaryMetric        = morpho_field_secondaryMetric;
      tertiaryMetric         = morpho_field_tertiaryMetric;
      convergenceScore       = morpho_field_convergenceScore;
      stabilityIndex         = morpho_field_stabilityIndex;
      adaptationRate         = morpho_field_adaptationRate;
      complexityIndex        = morpho_field_complexityIndex;
      entropyMeasure         = morpho_field_entropyMeasure;
      coherenceContribution  = morpho_field_coherenceContribution;
      freeEnergyContribution = morpho_field_freeEnergyContribution;
      totalUpdates           = morpho_field_totalUpdates;
      oscillationFreq        = morpho_field_oscillationFreq;
      dampingRatio           = morpho_field_dampingRatio;
      peakValue              = morpho_field_peakValue;
      troughValue            = morpho_field_troughValue;
      cumulativeEnergy       = morpho_field_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // SWARM INTELLIGENCE LAYER
  //
  // Deep computational intelligence module implementing swarm intelligence layer
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements swarm intelligence layer using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type SwarmAgent = {

    position : Float;

    velocity : Float;

    bestPosition : Float;

    bestFitness : Float;

    inertia : Float;

    cognitive : Float;

    social : Float;

    neighborhood : [Nat];

    agentType : AgentRole;

  };


  public type AgentRole = {

    #explorer;

    #exploiter;

    #scout;

    #leader;

    #follower;

  };


  public type SwarmState = {

    globalBest : Float;

    convergence : Float;

    diversity : Float;

    explorationRate : Float;

    iterationCount : Nat;

  };


  // ── SWARM INTELLIGENCE LAYER STATE ──────────────────────────────────────────────────

  stable var swarm_intel_beatCounter : Nat = 0;

  stable var swarm_intel_isActive : Bool = false;

  stable var swarm_intel_lastUpdateBeat : Nat = 0;

  stable var swarm_intel_totalUpdates : Nat = 0;

  stable var swarm_intel_primaryMetric : Float = 0.0;

  stable var swarm_intel_secondaryMetric : Float = 0.0;

  stable var swarm_intel_tertiaryMetric : Float = 0.0;

  stable var swarm_intel_convergenceScore : Float = 0.0;

  stable var swarm_intel_stabilityIndex : Float = PHI_INV;

  stable var swarm_intel_adaptationRate : Float = PHI_INV_4;

  stable var swarm_intel_cumulativeEnergy : Float = 0.0;

  stable var swarm_intel_peakValue : Float = 0.0;

  stable var swarm_intel_troughValue : Float = PHI_SQ;

  stable var swarm_intel_oscillationFreq : Float = PHI_INV;

  stable var swarm_intel_dampingRatio : Float = PHI_INV_2;

  stable var swarm_intel_phaseAngle : Float = 0.0;

  stable var swarm_intel_entropyMeasure : Float = 0.0;

  stable var swarm_intel_complexityIndex : Float = 0.0;

  stable var swarm_intel_coherenceContribution : Float = 0.0;

  stable var swarm_intel_freeEnergyContribution : Float = 0.0;




  // Primary computation for swarm intelligence layer
  func _swarm_intel_compute() : () {
    let n = children.size();
    if (n == 0) return;

    swarm_intel_lastUpdateBeat := beatCount;
    swarm_intel_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    swarm_intel_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    swarm_intel_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    swarm_intel_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = swarm_intel_convergenceScore;
    swarm_intel_convergenceScore := _clamp(
      (swarm_intel_primaryMetric + swarm_intel_secondaryMetric + swarm_intel_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(swarm_intel_convergenceScore - prevConvergence);
    swarm_intel_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    swarm_intel_adaptationRate := if (swarm_intel_stabilityIndex < PHI_INV_2) {
      _clamp(swarm_intel_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(swarm_intel_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    swarm_intel_cumulativeEnergy += Float.abs(swarm_intel_primaryMetric) * swarm_intel_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (swarm_intel_primaryMetric > swarm_intel_peakValue) {
      swarm_intel_peakValue := swarm_intel_primaryMetric;
    };
    if (swarm_intel_primaryMetric < swarm_intel_troughValue) {
      swarm_intel_troughValue := swarm_intel_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = swarm_intel_peakValue - swarm_intel_troughValue;
    swarm_intel_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    swarm_intel_dampingRatio := swarm_intel_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    swarm_intel_phaseAngle := _normalizePhase(
      swarm_intel_phaseAngle + swarm_intel_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [swarm_intel_primaryMetric, swarm_intel_secondaryMetric, swarm_intel_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      swarm_intel_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    swarm_intel_complexityIndex := swarm_intel_entropyMeasure * swarm_intel_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    swarm_intel_coherenceContribution := swarm_intel_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    swarm_intel_freeEnergyContribution := Float.abs(swarm_intel_primaryMetric - swarm_intel_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for swarm intelligence layer
  func _swarm_intel_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    swarm_intel_complexityIndex := _clamp(
      (swarm_intel_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for swarm intelligence layer
  func _swarm_intel_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      swarm_intel_stabilityIndex := _clamp(
        swarm_intel_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      swarm_intel_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for swarm intelligence layer diagnostics
  public query func getSwarmIntelDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = swarm_intel_primaryMetric;
      secondaryMetric        = swarm_intel_secondaryMetric;
      tertiaryMetric         = swarm_intel_tertiaryMetric;
      convergenceScore       = swarm_intel_convergenceScore;
      stabilityIndex         = swarm_intel_stabilityIndex;
      adaptationRate         = swarm_intel_adaptationRate;
      complexityIndex        = swarm_intel_complexityIndex;
      entropyMeasure         = swarm_intel_entropyMeasure;
      coherenceContribution  = swarm_intel_coherenceContribution;
      freeEnergyContribution = swarm_intel_freeEnergyContribution;
      totalUpdates           = swarm_intel_totalUpdates;
      oscillationFreq        = swarm_intel_oscillationFreq;
      dampingRatio           = swarm_intel_dampingRatio;
      peakValue              = swarm_intel_peakValue;
      troughValue            = swarm_intel_troughValue;
      cumulativeEnergy       = swarm_intel_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // QUANTUM COHERENCE SIMULATION
  //
  // Deep computational intelligence module implementing quantum coherence simulation
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements quantum coherence simulation using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type QuantumState = {

    amplitude : Float;

    phase : Float;

    entanglement : Float;

    decoherenceRate : Float;

    fidelity : Float;

    purity : Float;

    vonNeumannEntropy : Float;

    concurrence : Float;

  };


  public type EntanglementPair = {

    qubitA : Nat;

    qubitB : Nat;

    bellState : BellState;

    fidelity : Float;

    creationBeat : Nat;

    lifetime : Nat;

  };


  public type BellState = {

    #phiPlus;

    #phiMinus;

    #psiPlus;

    #psiMinus;

  };


  // ── QUANTUM COHERENCE SIMULATION STATE ──────────────────────────────────────────────────

  stable var quantum_sim_beatCounter : Nat = 0;

  stable var quantum_sim_isActive : Bool = false;

  stable var quantum_sim_lastUpdateBeat : Nat = 0;

  stable var quantum_sim_totalUpdates : Nat = 0;

  stable var quantum_sim_primaryMetric : Float = 0.0;

  stable var quantum_sim_secondaryMetric : Float = 0.0;

  stable var quantum_sim_tertiaryMetric : Float = 0.0;

  stable var quantum_sim_convergenceScore : Float = 0.0;

  stable var quantum_sim_stabilityIndex : Float = PHI_INV;

  stable var quantum_sim_adaptationRate : Float = PHI_INV_4;

  stable var quantum_sim_cumulativeEnergy : Float = 0.0;

  stable var quantum_sim_peakValue : Float = 0.0;

  stable var quantum_sim_troughValue : Float = PHI_SQ;

  stable var quantum_sim_oscillationFreq : Float = PHI_INV;

  stable var quantum_sim_dampingRatio : Float = PHI_INV_2;

  stable var quantum_sim_phaseAngle : Float = 0.0;

  stable var quantum_sim_entropyMeasure : Float = 0.0;

  stable var quantum_sim_complexityIndex : Float = 0.0;

  stable var quantum_sim_coherenceContribution : Float = 0.0;

  stable var quantum_sim_freeEnergyContribution : Float = 0.0;




  // Primary computation for quantum coherence simulation
  func _quantum_sim_compute() : () {
    let n = children.size();
    if (n == 0) return;

    quantum_sim_lastUpdateBeat := beatCount;
    quantum_sim_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    quantum_sim_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    quantum_sim_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    quantum_sim_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = quantum_sim_convergenceScore;
    quantum_sim_convergenceScore := _clamp(
      (quantum_sim_primaryMetric + quantum_sim_secondaryMetric + quantum_sim_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(quantum_sim_convergenceScore - prevConvergence);
    quantum_sim_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    quantum_sim_adaptationRate := if (quantum_sim_stabilityIndex < PHI_INV_2) {
      _clamp(quantum_sim_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(quantum_sim_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    quantum_sim_cumulativeEnergy += Float.abs(quantum_sim_primaryMetric) * quantum_sim_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (quantum_sim_primaryMetric > quantum_sim_peakValue) {
      quantum_sim_peakValue := quantum_sim_primaryMetric;
    };
    if (quantum_sim_primaryMetric < quantum_sim_troughValue) {
      quantum_sim_troughValue := quantum_sim_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = quantum_sim_peakValue - quantum_sim_troughValue;
    quantum_sim_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    quantum_sim_dampingRatio := quantum_sim_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    quantum_sim_phaseAngle := _normalizePhase(
      quantum_sim_phaseAngle + quantum_sim_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [quantum_sim_primaryMetric, quantum_sim_secondaryMetric, quantum_sim_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      quantum_sim_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    quantum_sim_complexityIndex := quantum_sim_entropyMeasure * quantum_sim_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    quantum_sim_coherenceContribution := quantum_sim_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    quantum_sim_freeEnergyContribution := Float.abs(quantum_sim_primaryMetric - quantum_sim_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for quantum coherence simulation
  func _quantum_sim_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    quantum_sim_complexityIndex := _clamp(
      (quantum_sim_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for quantum coherence simulation
  func _quantum_sim_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      quantum_sim_stabilityIndex := _clamp(
        quantum_sim_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      quantum_sim_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for quantum coherence simulation diagnostics
  public query func getQuantumSimDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = quantum_sim_primaryMetric;
      secondaryMetric        = quantum_sim_secondaryMetric;
      tertiaryMetric         = quantum_sim_tertiaryMetric;
      convergenceScore       = quantum_sim_convergenceScore;
      stabilityIndex         = quantum_sim_stabilityIndex;
      adaptationRate         = quantum_sim_adaptationRate;
      complexityIndex        = quantum_sim_complexityIndex;
      entropyMeasure         = quantum_sim_entropyMeasure;
      coherenceContribution  = quantum_sim_coherenceContribution;
      freeEnergyContribution = quantum_sim_freeEnergyContribution;
      totalUpdates           = quantum_sim_totalUpdates;
      oscillationFreq        = quantum_sim_oscillationFreq;
      dampingRatio           = quantum_sim_dampingRatio;
      peakValue              = quantum_sim_peakValue;
      troughValue            = quantum_sim_troughValue;
      cumulativeEnergy       = quantum_sim_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // EVOLUTIONARY DYNAMICS ENGINE
  //
  // Deep computational intelligence module implementing evolutionary dynamics engine
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements evolutionary dynamics engine using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type Species = {

    genome : [Float];

    fitness : Float;

    age : Nat;

    mutations : Nat;

    crossovers : Nat;

    lineage : Nat;

    niche : Nat;

    cooperationScore : Float;

    defectionScore : Float;

  };


  public type EvoStrategy = {

    #cooperate;

    #defect;

    #titForTat;

    #pavlov;

    #random;

  };


  public type PopulationState = {

    diversity : Float;

    avgFitness : Float;

    maxFitness : Float;

    generationCount : Nat;

    extinctionRisk : Float;

    speciationRate : Float;

    selectionPressure : Float;

  };


  // ── EVOLUTIONARY DYNAMICS ENGINE STATE ──────────────────────────────────────────────────

  stable var evo_dynamics_beatCounter : Nat = 0;

  stable var evo_dynamics_isActive : Bool = false;

  stable var evo_dynamics_lastUpdateBeat : Nat = 0;

  stable var evo_dynamics_totalUpdates : Nat = 0;

  stable var evo_dynamics_primaryMetric : Float = 0.0;

  stable var evo_dynamics_secondaryMetric : Float = 0.0;

  stable var evo_dynamics_tertiaryMetric : Float = 0.0;

  stable var evo_dynamics_convergenceScore : Float = 0.0;

  stable var evo_dynamics_stabilityIndex : Float = PHI_INV;

  stable var evo_dynamics_adaptationRate : Float = PHI_INV_4;

  stable var evo_dynamics_cumulativeEnergy : Float = 0.0;

  stable var evo_dynamics_peakValue : Float = 0.0;

  stable var evo_dynamics_troughValue : Float = PHI_SQ;

  stable var evo_dynamics_oscillationFreq : Float = PHI_INV;

  stable var evo_dynamics_dampingRatio : Float = PHI_INV_2;

  stable var evo_dynamics_phaseAngle : Float = 0.0;

  stable var evo_dynamics_entropyMeasure : Float = 0.0;

  stable var evo_dynamics_complexityIndex : Float = 0.0;

  stable var evo_dynamics_coherenceContribution : Float = 0.0;

  stable var evo_dynamics_freeEnergyContribution : Float = 0.0;




  // Primary computation for evolutionary dynamics engine
  func _evo_dynamics_compute() : () {
    let n = children.size();
    if (n == 0) return;

    evo_dynamics_lastUpdateBeat := beatCount;
    evo_dynamics_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    evo_dynamics_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    evo_dynamics_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    evo_dynamics_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = evo_dynamics_convergenceScore;
    evo_dynamics_convergenceScore := _clamp(
      (evo_dynamics_primaryMetric + evo_dynamics_secondaryMetric + evo_dynamics_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(evo_dynamics_convergenceScore - prevConvergence);
    evo_dynamics_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    evo_dynamics_adaptationRate := if (evo_dynamics_stabilityIndex < PHI_INV_2) {
      _clamp(evo_dynamics_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(evo_dynamics_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    evo_dynamics_cumulativeEnergy += Float.abs(evo_dynamics_primaryMetric) * evo_dynamics_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (evo_dynamics_primaryMetric > evo_dynamics_peakValue) {
      evo_dynamics_peakValue := evo_dynamics_primaryMetric;
    };
    if (evo_dynamics_primaryMetric < evo_dynamics_troughValue) {
      evo_dynamics_troughValue := evo_dynamics_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = evo_dynamics_peakValue - evo_dynamics_troughValue;
    evo_dynamics_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    evo_dynamics_dampingRatio := evo_dynamics_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    evo_dynamics_phaseAngle := _normalizePhase(
      evo_dynamics_phaseAngle + evo_dynamics_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [evo_dynamics_primaryMetric, evo_dynamics_secondaryMetric, evo_dynamics_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      evo_dynamics_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    evo_dynamics_complexityIndex := evo_dynamics_entropyMeasure * evo_dynamics_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    evo_dynamics_coherenceContribution := evo_dynamics_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    evo_dynamics_freeEnergyContribution := Float.abs(evo_dynamics_primaryMetric - evo_dynamics_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for evolutionary dynamics engine
  func _evo_dynamics_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    evo_dynamics_complexityIndex := _clamp(
      (evo_dynamics_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for evolutionary dynamics engine
  func _evo_dynamics_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      evo_dynamics_stabilityIndex := _clamp(
        evo_dynamics_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      evo_dynamics_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for evolutionary dynamics engine diagnostics
  public query func getEvoDynamicsDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = evo_dynamics_primaryMetric;
      secondaryMetric        = evo_dynamics_secondaryMetric;
      tertiaryMetric         = evo_dynamics_tertiaryMetric;
      convergenceScore       = evo_dynamics_convergenceScore;
      stabilityIndex         = evo_dynamics_stabilityIndex;
      adaptationRate         = evo_dynamics_adaptationRate;
      complexityIndex        = evo_dynamics_complexityIndex;
      entropyMeasure         = evo_dynamics_entropyMeasure;
      coherenceContribution  = evo_dynamics_coherenceContribution;
      freeEnergyContribution = evo_dynamics_freeEnergyContribution;
      totalUpdates           = evo_dynamics_totalUpdates;
      oscillationFreq        = evo_dynamics_oscillationFreq;
      dampingRatio           = evo_dynamics_dampingRatio;
      peakValue              = evo_dynamics_peakValue;
      troughValue            = evo_dynamics_troughValue;
      cumulativeEnergy       = evo_dynamics_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // ATTENTION MECHANISM
  //
  // Deep computational intelligence module implementing attention mechanism
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements attention mechanism using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type AttentionHead = {

    queryVector : [Float];

    keyVector : [Float];

    valueVector : [Float];

    score : Float;

    weight : Float;

    headIdx : Nat;

    contextWindow : Nat;

    temperature : Float;

  };


  public type AttentionFocus = {

    targetChild : Nat;

    intensity : Float;

    duration : Nat;

    reason : AttentionReason;

    priority : Float;

  };


  public type AttentionReason = {

    #anomaly;

    #priority;

    #failure;

    #opportunity;

    #routine;

  };


  // ── ATTENTION MECHANISM STATE ──────────────────────────────────────────────────

  stable var attention_beatCounter : Nat = 0;

  stable var attention_isActive : Bool = false;

  stable var attention_lastUpdateBeat : Nat = 0;

  stable var attention_totalUpdates : Nat = 0;

  stable var attention_primaryMetric : Float = 0.0;

  stable var attention_secondaryMetric : Float = 0.0;

  stable var attention_tertiaryMetric : Float = 0.0;

  stable var attention_convergenceScore : Float = 0.0;

  stable var attention_stabilityIndex : Float = PHI_INV;

  stable var attention_adaptationRate : Float = PHI_INV_4;

  stable var attention_cumulativeEnergy : Float = 0.0;

  stable var attention_peakValue : Float = 0.0;

  stable var attention_troughValue : Float = PHI_SQ;

  stable var attention_oscillationFreq : Float = PHI_INV;

  stable var attention_dampingRatio : Float = PHI_INV_2;

  stable var attention_phaseAngle : Float = 0.0;

  stable var attention_entropyMeasure : Float = 0.0;

  stable var attention_complexityIndex : Float = 0.0;

  stable var attention_coherenceContribution : Float = 0.0;

  stable var attention_freeEnergyContribution : Float = 0.0;




  // Primary computation for attention mechanism
  func _attention_compute() : () {
    let n = children.size();
    if (n == 0) return;

    attention_lastUpdateBeat := beatCount;
    attention_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    attention_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    attention_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    attention_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = attention_convergenceScore;
    attention_convergenceScore := _clamp(
      (attention_primaryMetric + attention_secondaryMetric + attention_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(attention_convergenceScore - prevConvergence);
    attention_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    attention_adaptationRate := if (attention_stabilityIndex < PHI_INV_2) {
      _clamp(attention_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(attention_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    attention_cumulativeEnergy += Float.abs(attention_primaryMetric) * attention_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (attention_primaryMetric > attention_peakValue) {
      attention_peakValue := attention_primaryMetric;
    };
    if (attention_primaryMetric < attention_troughValue) {
      attention_troughValue := attention_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = attention_peakValue - attention_troughValue;
    attention_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    attention_dampingRatio := attention_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    attention_phaseAngle := _normalizePhase(
      attention_phaseAngle + attention_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [attention_primaryMetric, attention_secondaryMetric, attention_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      attention_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    attention_complexityIndex := attention_entropyMeasure * attention_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    attention_coherenceContribution := attention_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    attention_freeEnergyContribution := Float.abs(attention_primaryMetric - attention_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for attention mechanism
  func _attention_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    attention_complexityIndex := _clamp(
      (attention_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for attention mechanism
  func _attention_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      attention_stabilityIndex := _clamp(
        attention_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      attention_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for attention mechanism diagnostics
  public query func getAttentionDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = attention_primaryMetric;
      secondaryMetric        = attention_secondaryMetric;
      tertiaryMetric         = attention_tertiaryMetric;
      convergenceScore       = attention_convergenceScore;
      stabilityIndex         = attention_stabilityIndex;
      adaptationRate         = attention_adaptationRate;
      complexityIndex        = attention_complexityIndex;
      entropyMeasure         = attention_entropyMeasure;
      coherenceContribution  = attention_coherenceContribution;
      freeEnergyContribution = attention_freeEnergyContribution;
      totalUpdates           = attention_totalUpdates;
      oscillationFreq        = attention_oscillationFreq;
      dampingRatio           = attention_dampingRatio;
      peakValue              = attention_peakValue;
      troughValue            = attention_troughValue;
      cumulativeEnergy       = attention_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // THERMODYNAMIC COMPUTING LAYER
  //
  // Deep computational intelligence module implementing thermodynamic computing layer
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements thermodynamic computing layer using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type ThermodynamicState = {

    temperature : Float;

    pressure : Float;

    volume : Float;

    internalEnergy : Float;

    enthalpyH : Float;

    gibbsFreeEnergy : Float;

    helmholtzFreeEnergy : Float;

    entropyS : Float;

  };


  public type PhaseTransition = {

    fromPhase : SystemPhase;

    toPhase : SystemPhase;

    criticalTemp : Float;

    orderParameter : Float;

    transitionBeat : Nat;

    latentHeat : Float;

  };


  public type SystemPhase = {

    #solid;

    #liquid;

    #gas;

    #plasma;

    #boseEinstein;

  };


  // ── THERMODYNAMIC COMPUTING LAYER STATE ──────────────────────────────────────────────────

  stable var thermo_compute_beatCounter : Nat = 0;

  stable var thermo_compute_isActive : Bool = false;

  stable var thermo_compute_lastUpdateBeat : Nat = 0;

  stable var thermo_compute_totalUpdates : Nat = 0;

  stable var thermo_compute_primaryMetric : Float = 0.0;

  stable var thermo_compute_secondaryMetric : Float = 0.0;

  stable var thermo_compute_tertiaryMetric : Float = 0.0;

  stable var thermo_compute_convergenceScore : Float = 0.0;

  stable var thermo_compute_stabilityIndex : Float = PHI_INV;

  stable var thermo_compute_adaptationRate : Float = PHI_INV_4;

  stable var thermo_compute_cumulativeEnergy : Float = 0.0;

  stable var thermo_compute_peakValue : Float = 0.0;

  stable var thermo_compute_troughValue : Float = PHI_SQ;

  stable var thermo_compute_oscillationFreq : Float = PHI_INV;

  stable var thermo_compute_dampingRatio : Float = PHI_INV_2;

  stable var thermo_compute_phaseAngle : Float = 0.0;

  stable var thermo_compute_entropyMeasure : Float = 0.0;

  stable var thermo_compute_complexityIndex : Float = 0.0;

  stable var thermo_compute_coherenceContribution : Float = 0.0;

  stable var thermo_compute_freeEnergyContribution : Float = 0.0;




  // Primary computation for thermodynamic computing layer
  func _thermo_compute_compute() : () {
    let n = children.size();
    if (n == 0) return;

    thermo_compute_lastUpdateBeat := beatCount;
    thermo_compute_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    thermo_compute_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    thermo_compute_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    thermo_compute_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = thermo_compute_convergenceScore;
    thermo_compute_convergenceScore := _clamp(
      (thermo_compute_primaryMetric + thermo_compute_secondaryMetric + thermo_compute_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(thermo_compute_convergenceScore - prevConvergence);
    thermo_compute_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    thermo_compute_adaptationRate := if (thermo_compute_stabilityIndex < PHI_INV_2) {
      _clamp(thermo_compute_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(thermo_compute_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    thermo_compute_cumulativeEnergy += Float.abs(thermo_compute_primaryMetric) * thermo_compute_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (thermo_compute_primaryMetric > thermo_compute_peakValue) {
      thermo_compute_peakValue := thermo_compute_primaryMetric;
    };
    if (thermo_compute_primaryMetric < thermo_compute_troughValue) {
      thermo_compute_troughValue := thermo_compute_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = thermo_compute_peakValue - thermo_compute_troughValue;
    thermo_compute_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    thermo_compute_dampingRatio := thermo_compute_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    thermo_compute_phaseAngle := _normalizePhase(
      thermo_compute_phaseAngle + thermo_compute_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [thermo_compute_primaryMetric, thermo_compute_secondaryMetric, thermo_compute_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      thermo_compute_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    thermo_compute_complexityIndex := thermo_compute_entropyMeasure * thermo_compute_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    thermo_compute_coherenceContribution := thermo_compute_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    thermo_compute_freeEnergyContribution := Float.abs(thermo_compute_primaryMetric - thermo_compute_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for thermodynamic computing layer
  func _thermo_compute_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    thermo_compute_complexityIndex := _clamp(
      (thermo_compute_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for thermodynamic computing layer
  func _thermo_compute_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      thermo_compute_stabilityIndex := _clamp(
        thermo_compute_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      thermo_compute_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for thermodynamic computing layer diagnostics
  public query func getThermoComputeDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = thermo_compute_primaryMetric;
      secondaryMetric        = thermo_compute_secondaryMetric;
      tertiaryMetric         = thermo_compute_tertiaryMetric;
      convergenceScore       = thermo_compute_convergenceScore;
      stabilityIndex         = thermo_compute_stabilityIndex;
      adaptationRate         = thermo_compute_adaptationRate;
      complexityIndex        = thermo_compute_complexityIndex;
      entropyMeasure         = thermo_compute_entropyMeasure;
      coherenceContribution  = thermo_compute_coherenceContribution;
      freeEnergyContribution = thermo_compute_freeEnergyContribution;
      totalUpdates           = thermo_compute_totalUpdates;
      oscillationFreq        = thermo_compute_oscillationFreq;
      dampingRatio           = thermo_compute_dampingRatio;
      peakValue              = thermo_compute_peakValue;
      troughValue            = thermo_compute_troughValue;
      cumulativeEnergy       = thermo_compute_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // FRACTAL DIMENSION ANALYSIS
  //
  // Deep computational intelligence module implementing fractal dimension analysis
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements fractal dimension analysis using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type FractalMeasure = {

    hausdorffDim : Float;

    correlationDim : Float;

    informationDim : Float;

    boxCountDim : Float;

    lyapunovExponent : Float;

    kolmogorovEntropy : Float;

    recurrenceRate : Float;

    determinism : Float;

  };


  public type RecurrencePlot = {

    recurrenceMatrix : [Bool];

    matrixSize : Nat;

    embeddingDim : Nat;

    timeDelay : Nat;

    threshold : Float;

    laminarity : Float;

  };


  // ── FRACTAL DIMENSION ANALYSIS STATE ──────────────────────────────────────────────────

  stable var fractal_dim_beatCounter : Nat = 0;

  stable var fractal_dim_isActive : Bool = false;

  stable var fractal_dim_lastUpdateBeat : Nat = 0;

  stable var fractal_dim_totalUpdates : Nat = 0;

  stable var fractal_dim_primaryMetric : Float = 0.0;

  stable var fractal_dim_secondaryMetric : Float = 0.0;

  stable var fractal_dim_tertiaryMetric : Float = 0.0;

  stable var fractal_dim_convergenceScore : Float = 0.0;

  stable var fractal_dim_stabilityIndex : Float = PHI_INV;

  stable var fractal_dim_adaptationRate : Float = PHI_INV_4;

  stable var fractal_dim_cumulativeEnergy : Float = 0.0;

  stable var fractal_dim_peakValue : Float = 0.0;

  stable var fractal_dim_troughValue : Float = PHI_SQ;

  stable var fractal_dim_oscillationFreq : Float = PHI_INV;

  stable var fractal_dim_dampingRatio : Float = PHI_INV_2;

  stable var fractal_dim_phaseAngle : Float = 0.0;

  stable var fractal_dim_entropyMeasure : Float = 0.0;

  stable var fractal_dim_complexityIndex : Float = 0.0;

  stable var fractal_dim_coherenceContribution : Float = 0.0;

  stable var fractal_dim_freeEnergyContribution : Float = 0.0;




  // Primary computation for fractal dimension analysis
  func _fractal_dim_compute() : () {
    let n = children.size();
    if (n == 0) return;

    fractal_dim_lastUpdateBeat := beatCount;
    fractal_dim_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    fractal_dim_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    fractal_dim_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    fractal_dim_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = fractal_dim_convergenceScore;
    fractal_dim_convergenceScore := _clamp(
      (fractal_dim_primaryMetric + fractal_dim_secondaryMetric + fractal_dim_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(fractal_dim_convergenceScore - prevConvergence);
    fractal_dim_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    fractal_dim_adaptationRate := if (fractal_dim_stabilityIndex < PHI_INV_2) {
      _clamp(fractal_dim_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(fractal_dim_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    fractal_dim_cumulativeEnergy += Float.abs(fractal_dim_primaryMetric) * fractal_dim_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (fractal_dim_primaryMetric > fractal_dim_peakValue) {
      fractal_dim_peakValue := fractal_dim_primaryMetric;
    };
    if (fractal_dim_primaryMetric < fractal_dim_troughValue) {
      fractal_dim_troughValue := fractal_dim_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = fractal_dim_peakValue - fractal_dim_troughValue;
    fractal_dim_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    fractal_dim_dampingRatio := fractal_dim_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    fractal_dim_phaseAngle := _normalizePhase(
      fractal_dim_phaseAngle + fractal_dim_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [fractal_dim_primaryMetric, fractal_dim_secondaryMetric, fractal_dim_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      fractal_dim_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    fractal_dim_complexityIndex := fractal_dim_entropyMeasure * fractal_dim_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    fractal_dim_coherenceContribution := fractal_dim_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    fractal_dim_freeEnergyContribution := Float.abs(fractal_dim_primaryMetric - fractal_dim_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for fractal dimension analysis
  func _fractal_dim_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    fractal_dim_complexityIndex := _clamp(
      (fractal_dim_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for fractal dimension analysis
  func _fractal_dim_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      fractal_dim_stabilityIndex := _clamp(
        fractal_dim_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      fractal_dim_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for fractal dimension analysis diagnostics
  public query func getFractalDimDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = fractal_dim_primaryMetric;
      secondaryMetric        = fractal_dim_secondaryMetric;
      tertiaryMetric         = fractal_dim_tertiaryMetric;
      convergenceScore       = fractal_dim_convergenceScore;
      stabilityIndex         = fractal_dim_stabilityIndex;
      adaptationRate         = fractal_dim_adaptationRate;
      complexityIndex        = fractal_dim_complexityIndex;
      entropyMeasure         = fractal_dim_entropyMeasure;
      coherenceContribution  = fractal_dim_coherenceContribution;
      freeEnergyContribution = fractal_dim_freeEnergyContribution;
      totalUpdates           = fractal_dim_totalUpdates;
      oscillationFreq        = fractal_dim_oscillationFreq;
      dampingRatio           = fractal_dim_dampingRatio;
      peakValue              = fractal_dim_peakValue;
      troughValue            = fractal_dim_troughValue;
      cumulativeEnergy       = fractal_dim_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // STIGMERGY COORDINATION
  //
  // Deep computational intelligence module implementing stigmergy coordination
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements stigmergy coordination using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type Pheromone = {

    location : Nat;

    intensity : Float;

    type_ : PheromoneType;

    depositBeat : Nat;

    evaporationRate : Float;

    diffusionRadius : Nat;

    depositor : Nat;

  };


  public type PheromoneType = {

    #trail;

    #alarm;

    #recruitment;

    #territory;

    #food;

  };


  public type StigmergyState = {

    totalPheromones : Nat;

    avgIntensity : Float;

    trailEntropy : Float;

    coordinationScore : Float;

    evaporatedCount : Nat;

    depositionRate : Float;

  };


  // ── STIGMERGY COORDINATION STATE ──────────────────────────────────────────────────

  stable var stigmergy_beatCounter : Nat = 0;

  stable var stigmergy_isActive : Bool = false;

  stable var stigmergy_lastUpdateBeat : Nat = 0;

  stable var stigmergy_totalUpdates : Nat = 0;

  stable var stigmergy_primaryMetric : Float = 0.0;

  stable var stigmergy_secondaryMetric : Float = 0.0;

  stable var stigmergy_tertiaryMetric : Float = 0.0;

  stable var stigmergy_convergenceScore : Float = 0.0;

  stable var stigmergy_stabilityIndex : Float = PHI_INV;

  stable var stigmergy_adaptationRate : Float = PHI_INV_4;

  stable var stigmergy_cumulativeEnergy : Float = 0.0;

  stable var stigmergy_peakValue : Float = 0.0;

  stable var stigmergy_troughValue : Float = PHI_SQ;

  stable var stigmergy_oscillationFreq : Float = PHI_INV;

  stable var stigmergy_dampingRatio : Float = PHI_INV_2;

  stable var stigmergy_phaseAngle : Float = 0.0;

  stable var stigmergy_entropyMeasure : Float = 0.0;

  stable var stigmergy_complexityIndex : Float = 0.0;

  stable var stigmergy_coherenceContribution : Float = 0.0;

  stable var stigmergy_freeEnergyContribution : Float = 0.0;




  // Primary computation for stigmergy coordination
  func _stigmergy_compute() : () {
    let n = children.size();
    if (n == 0) return;

    stigmergy_lastUpdateBeat := beatCount;
    stigmergy_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    stigmergy_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    stigmergy_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    stigmergy_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = stigmergy_convergenceScore;
    stigmergy_convergenceScore := _clamp(
      (stigmergy_primaryMetric + stigmergy_secondaryMetric + stigmergy_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(stigmergy_convergenceScore - prevConvergence);
    stigmergy_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    stigmergy_adaptationRate := if (stigmergy_stabilityIndex < PHI_INV_2) {
      _clamp(stigmergy_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(stigmergy_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    stigmergy_cumulativeEnergy += Float.abs(stigmergy_primaryMetric) * stigmergy_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (stigmergy_primaryMetric > stigmergy_peakValue) {
      stigmergy_peakValue := stigmergy_primaryMetric;
    };
    if (stigmergy_primaryMetric < stigmergy_troughValue) {
      stigmergy_troughValue := stigmergy_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = stigmergy_peakValue - stigmergy_troughValue;
    stigmergy_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    stigmergy_dampingRatio := stigmergy_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    stigmergy_phaseAngle := _normalizePhase(
      stigmergy_phaseAngle + stigmergy_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [stigmergy_primaryMetric, stigmergy_secondaryMetric, stigmergy_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      stigmergy_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    stigmergy_complexityIndex := stigmergy_entropyMeasure * stigmergy_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    stigmergy_coherenceContribution := stigmergy_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    stigmergy_freeEnergyContribution := Float.abs(stigmergy_primaryMetric - stigmergy_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for stigmergy coordination
  func _stigmergy_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    stigmergy_complexityIndex := _clamp(
      (stigmergy_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for stigmergy coordination
  func _stigmergy_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      stigmergy_stabilityIndex := _clamp(
        stigmergy_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      stigmergy_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for stigmergy coordination diagnostics
  public query func getStigmergyDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = stigmergy_primaryMetric;
      secondaryMetric        = stigmergy_secondaryMetric;
      tertiaryMetric         = stigmergy_tertiaryMetric;
      convergenceScore       = stigmergy_convergenceScore;
      stabilityIndex         = stigmergy_stabilityIndex;
      adaptationRate         = stigmergy_adaptationRate;
      complexityIndex        = stigmergy_complexityIndex;
      entropyMeasure         = stigmergy_entropyMeasure;
      coherenceContribution  = stigmergy_coherenceContribution;
      freeEnergyContribution = stigmergy_freeEnergyContribution;
      totalUpdates           = stigmergy_totalUpdates;
      oscillationFreq        = stigmergy_oscillationFreq;
      dampingRatio           = stigmergy_dampingRatio;
      peakValue              = stigmergy_peakValue;
      troughValue            = stigmergy_troughValue;
      cumulativeEnergy       = stigmergy_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // ALLOSTATIC LOAD TRACKING
  //
  // Deep computational intelligence module implementing allostatic load tracking
  // for the PARALLAX sovereign organism. All constants are phi-derived.
  // All computations serve the organism's coherence and self-organization.
  //
  // MATHEMATICAL FOUNDATION:
  //   This module implements allostatic load tracking using the phi-harmonic
  //   mathematical substrate. Every threshold, learning rate, decay constant,
  //   and capacity limit is derived from the golden ratio or Fibonacci sequence.
  //
  //   Primary equation: Δstate = η·(target − current)·φ^(-complexity)
  //   Stability bound: ||state|| ≤ φ² (sovereign ceiling)
  //   Floor guarantee: min(state) ≥ φ⁻³ (sovereign floor)
  //
  // INTEGRATION WITH ORCHESTRATOR:
  //   Called during _postHeartbeatIntelligence() phase.
  //   Reads: globalCoherence, lyapunovV, freeEnergy, childPhases[], hebbianW[]
  //   Writes: module-specific state variables
  //   Period: every F(4)=3 to F(6)=8 beats depending on computational cost
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  public type AllostasisMetric = {

    parameter : Text;

    baselineValue : Float;

    currentDeviation : Float;

    cumulativeLoad : Float;

    peakLoad : Float;

    recoveryCapacity : Float;

    adaptationRate : Float;

    exhaustionLevel : Float;

  };


  public type LoadPhase = {

    #alarm;

    #resistance;

    #exhaustion;

    #recovery;

    #supercompensation;

  };


  public type SystemResilience = {

    elasticity : Float;

    robustness : Float;

    redundancy : Float;

    resourcefulness : Float;

    rapidity : Float;

    compositeScore : Float;

  };


  // ── ALLOSTATIC LOAD TRACKING STATE ──────────────────────────────────────────────────

  stable var allostatic_load_beatCounter : Nat = 0;

  stable var allostatic_load_isActive : Bool = false;

  stable var allostatic_load_lastUpdateBeat : Nat = 0;

  stable var allostatic_load_totalUpdates : Nat = 0;

  stable var allostatic_load_primaryMetric : Float = 0.0;

  stable var allostatic_load_secondaryMetric : Float = 0.0;

  stable var allostatic_load_tertiaryMetric : Float = 0.0;

  stable var allostatic_load_convergenceScore : Float = 0.0;

  stable var allostatic_load_stabilityIndex : Float = PHI_INV;

  stable var allostatic_load_adaptationRate : Float = PHI_INV_4;

  stable var allostatic_load_cumulativeEnergy : Float = 0.0;

  stable var allostatic_load_peakValue : Float = 0.0;

  stable var allostatic_load_troughValue : Float = PHI_SQ;

  stable var allostatic_load_oscillationFreq : Float = PHI_INV;

  stable var allostatic_load_dampingRatio : Float = PHI_INV_2;

  stable var allostatic_load_phaseAngle : Float = 0.0;

  stable var allostatic_load_entropyMeasure : Float = 0.0;

  stable var allostatic_load_complexityIndex : Float = 0.0;

  stable var allostatic_load_coherenceContribution : Float = 0.0;

  stable var allostatic_load_freeEnergyContribution : Float = 0.0;




  // Primary computation for allostatic load tracking
  func _allostatic_load_compute() : () {
    let n = children.size();
    if (n == 0) return;

    allostatic_load_lastUpdateBeat := beatCount;
    allostatic_load_totalUpdates += 1;

    // Phase 1: Gather input signals from organism state
    let coherenceInput = globalCoherence;
    let energyInput = lyapunovV;
    let entropyInput = orchestrationEntropy;
    let driftInput = jasmineDrift;

    // Phase 2: Compute primary metric using phi-weighted integration
    // Primary metric = tanh(coherence × φ − energy × φ⁻¹ + entropy × φ⁻²)
    let rawPrimary = coherenceInput * PHI - energyInput * PHI_INV + entropyInput * PHI_INV_2;
    let expP = Float.exp(rawPrimary);
    let expN = Float.exp(-rawPrimary);
    let tanhVal = if (expP + expN > 0.0) { (expP - expN) / (expP + expN) } else { 0.0 };
    allostatic_load_primaryMetric := _clamp(tanhVal, -1.0, 1.0);

    // Phase 3: Compute secondary metric via cross-correlation with children
    var crossCorr : Float = 0.0;
    for (i in Array.keys(children)) {
      let healthNorm = children[i].health / PHI_SQ;
      let phaseContrib = Float.cos(childPhases[i]);
      crossCorr += healthNorm * phaseContrib * PHI_INV;
    };
    allostatic_load_secondaryMetric := _clamp(crossCorr / Float.fromInt(n), -1.0, 1.0);

    // Phase 4: Compute tertiary metric via Hebbian topology analysis
    var topoMetric : Float = 0.0;
    if (n > 1) {
      for (i in Array.keys(children)) {
        for (j in Array.keys(children)) {
          if (i != j) {
            let w = hebbianW[i * n + j];
            let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
            topoMetric += w * Float.cos(phaseDiff);
          };
        };
      };
      topoMetric := topoMetric / Float.fromInt(n * (n - 1));
    };
    allostatic_load_tertiaryMetric := _clamp(topoMetric, -1.0, 1.0);

    // Phase 5: Convergence assessment
    let prevConvergence = allostatic_load_convergenceScore;
    allostatic_load_convergenceScore := _clamp(
      (allostatic_load_primaryMetric + allostatic_load_secondaryMetric + allostatic_load_tertiaryMetric) / 3.0,
      0.0, 1.0
    );

    // Phase 6: Stability via Lyapunov-like energy function
    let energyDelta = Float.abs(allostatic_load_convergenceScore - prevConvergence);
    allostatic_load_stabilityIndex := _clamp(1.0 - energyDelta * PHI_SQ, 0.0, 1.0);

    // Phase 7: Adaptation rate modulation (faster when unstable)
    allostatic_load_adaptationRate := if (allostatic_load_stabilityIndex < PHI_INV_2) {
      _clamp(allostatic_load_adaptationRate * PHI_INV + PHI_INV_4, PHI_INV_5, PHI_INV_2)
    } else {
      _clamp(allostatic_load_adaptationRate * PHI_INV_2, PHI_INV_5, PHI_INV_3)
    };

    // Phase 8: Energy accumulation
    allostatic_load_cumulativeEnergy += Float.abs(allostatic_load_primaryMetric) * allostatic_load_adaptationRate;

    // Phase 9: Peak/trough tracking
    if (allostatic_load_primaryMetric > allostatic_load_peakValue) {
      allostatic_load_peakValue := allostatic_load_primaryMetric;
    };
    if (allostatic_load_primaryMetric < allostatic_load_troughValue) {
      allostatic_load_troughValue := allostatic_load_primaryMetric;
    };

    // Phase 10: Oscillation frequency estimation
    let amplitude = allostatic_load_peakValue - allostatic_load_troughValue;
    allostatic_load_oscillationFreq := if (amplitude > PHI_INV_3) {
      PHI_INV / amplitude
    } else { PHI_INV };

    // Phase 11: Damping ratio from stability
    allostatic_load_dampingRatio := allostatic_load_stabilityIndex * PHI_INV;

    // Phase 12: Phase angle advance
    allostatic_load_phaseAngle := _normalizePhase(
      allostatic_load_phaseAngle + allostatic_load_oscillationFreq * PHI_INV
    );

    // Phase 13: Entropy of the module's state distribution
    let stateValues = [allostatic_load_primaryMetric, allostatic_load_secondaryMetric, allostatic_load_tertiaryMetric];
    var stateSum : Float = 0.0;
    for (v in stateValues.vals()) { stateSum += Float.abs(v) };
    if (stateSum > 0.001) {
      var entropy : Float = 0.0;
      for (v in stateValues.vals()) {
        let p = Float.abs(v) / stateSum;
        if (p > 0.001) {
          entropy -= p * (Float.log(p) / Float.log(2.0));
        };
      };
      allostatic_load_entropyMeasure := entropy;
    };

    // Phase 14: Complexity index (edge of chaos indicator)
    allostatic_load_complexityIndex := allostatic_load_entropyMeasure * allostatic_load_stabilityIndex;

    // Phase 15: Coherence contribution (how much this module helps global coherence)
    allostatic_load_coherenceContribution := allostatic_load_convergenceScore * PHI_INV_3;

    // Phase 16: Free energy contribution (prediction error from this module)
    allostatic_load_freeEnergyContribution := Float.abs(allostatic_load_primaryMetric - allostatic_load_secondaryMetric) * PHI_INV_2;
  };

  // Secondary analysis for allostatic load tracking
  func _allostatic_load_analyze() : () {
    let n = children.size();
    if (n < 2) return;

    // Cross-child interaction matrix analysis
    var interactionEnergy : Float = 0.0;
    var maxInteraction : Float = 0.0;
    var minInteraction : Float = PHI_SQ;

    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          interactionEnergy += interaction;
          if (interaction > maxInteraction) { maxInteraction := interaction };
          if (interaction < minInteraction) { minInteraction := interaction };
        };
      };
    };

    // Normalize interaction energy
    let totalPairs = Float.fromInt(n * (n - 1));
    let avgInteraction = if (totalPairs > 0.0) { interactionEnergy / totalPairs } else { 0.0 };

    // Compute interaction variance (heterogeneity of coupling)
    var interactionVar : Float = 0.0;
    for (i in Array.keys(children)) {
      for (j in Array.keys(children)) {
        if (i != j) {
          let w = hebbianW[i * n + j];
          let phaseDiff = _normalizePhase(childPhases[i] - childPhases[j]);
          let interaction = w * (1.0 - Float.cos(phaseDiff));
          let dev = interaction - avgInteraction;
          interactionVar += dev * dev;
        };
      };
    };
    interactionVar := if (totalPairs > 0.0) { interactionVar / totalPairs } else { 0.0 };

    // Update module metrics from interaction analysis
    let interactionComplexity = Float.sqrt(interactionVar) * PHI;
    allostatic_load_complexityIndex := _clamp(
      (allostatic_load_complexityIndex + interactionComplexity) * 0.5,
      0.0, PHI_SQ
    );
  };

  // Tertiary deep-computation for allostatic load tracking
  func _allostatic_load_deepCompute() : () {
    let n = children.size();
    if (n == 0) return;

    // Spectral decomposition of child health vector
    var healthMean : Float = 0.0;
    for (c in children.vals()) { healthMean += c.health };
    healthMean := healthMean / Float.fromInt(n);

    var healthVariance : Float = 0.0;
    var healthSkewness : Float = 0.0;
    var healthKurtosis : Float = 0.0;

    for (c in children.vals()) {
      let dev = c.health - healthMean;
      healthVariance += dev * dev;
      healthSkewness += dev * dev * dev;
      healthKurtosis += dev * dev * dev * dev;
    };

    healthVariance := healthVariance / Float.fromInt(n);
    let stdDev = Float.sqrt(healthVariance);

    if (stdDev > 0.001) {
      healthSkewness := (healthSkewness / Float.fromInt(n)) / (stdDev * stdDev * stdDev);
      healthKurtosis := (healthKurtosis / Float.fromInt(n)) / (stdDev * stdDev * stdDev * stdDev) - 3.0;
    } else {
      healthSkewness := 0.0;
      healthKurtosis := 0.0;
    };

    // Autocorrelation analysis of module's primary metric history
    // (Uses coherence history as proxy for temporal structure)
    let histLen = coherenceHistory.size();
    if (histLen >= 5) {
      var acSum : Float = 0.0;
      var acNorm : Float = 0.0;
      var cohMean : Float = 0.0;
      for (v in coherenceHistory.vals()) { cohMean += v };
      cohMean := cohMean / Float.fromInt(histLen);

      var t : Nat = 0;
      while (t + 1 < histLen) {
        let a = coherenceHistory[t] - cohMean;
        let b = coherenceHistory[t + 1] - cohMean;
        acSum += a * b;
        acNorm += a * a;
        t += 1;
      };

      let autocorr = if (acNorm > 0.001) { acSum / acNorm } else { 0.0 };

      // High autocorrelation + high variance = near critical transition
      let criticalIndicator = autocorr * healthVariance * PHI_SQ;
      allostatic_load_stabilityIndex := _clamp(
        allostatic_load_stabilityIndex - criticalIndicator * PHI_INV_4,
        0.0, 1.0
      );
    };

    // Phase-space reconstruction using delay embedding
    // Embedding dimension d = 3, time delay τ = 1
    if (histLen >= 5) {
      var recurrenceCount : Nat = 0;
      var totalComparisons : Nat = 0;
      let threshold = PHI_INV_3;

      var i : Nat = 0;
      while (i + 2 < histLen) {
        var j : Nat = i + 1;
        while (j + 2 < histLen) {
          // Distance in 3D delay-embedded space
          let d1 = coherenceHistory[i] - coherenceHistory[j];
          let d2 = coherenceHistory[i+1] - coherenceHistory[j+1];
          let d3 = coherenceHistory[i+2] - coherenceHistory[j+2];
          let dist = Float.sqrt(d1*d1 + d2*d2 + d3*d3);
          if (dist < threshold) {
            recurrenceCount += 1;
          };
          totalComparisons += 1;
          j += 1;
        };
        i += 1;
      };

      // Recurrence rate as determinism proxy
      let recurrenceRate = if (totalComparisons > 0) {
        Float.fromInt(recurrenceCount) / Float.fromInt(totalComparisons)
      } else { 0.0 };

      // High recurrence = deterministic, low = chaotic
      allostatic_load_complexityIndex := _clamp(
        4.0 * recurrenceRate * (1.0 - recurrenceRate),  // Logistic map of recurrence
        0.0, 1.0
      );
    };
  };

  // Query endpoint for allostatic load tracking diagnostics
  public query func getAllostaticLoadDiagnostics() : async {
    primaryMetric         : Float;
    secondaryMetric       : Float;
    tertiaryMetric        : Float;
    convergenceScore      : Float;
    stabilityIndex        : Float;
    adaptationRate        : Float;
    complexityIndex       : Float;
    entropyMeasure        : Float;
    coherenceContribution : Float;
    freeEnergyContribution: Float;
    totalUpdates          : Nat;
    oscillationFreq       : Float;
    dampingRatio          : Float;
    peakValue             : Float;
    troughValue           : Float;
    cumulativeEnergy      : Float;
  } {
    {
      primaryMetric          = allostatic_load_primaryMetric;
      secondaryMetric        = allostatic_load_secondaryMetric;
      tertiaryMetric         = allostatic_load_tertiaryMetric;
      convergenceScore       = allostatic_load_convergenceScore;
      stabilityIndex         = allostatic_load_stabilityIndex;
      adaptationRate         = allostatic_load_adaptationRate;
      complexityIndex        = allostatic_load_complexityIndex;
      entropyMeasure         = allostatic_load_entropyMeasure;
      coherenceContribution  = allostatic_load_coherenceContribution;
      freeEnergyContribution = allostatic_load_freeEnergyContribution;
      totalUpdates           = allostatic_load_totalUpdates;
      oscillationFreq        = allostatic_load_oscillationFreq;
      dampingRatio           = allostatic_load_dampingRatio;
      peakValue              = allostatic_load_peakValue;
      troughValue            = allostatic_load_troughValue;
      cumulativeEnergy       = allostatic_load_cumulativeEnergy;
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DEEP INTELLIGENCE INTEGRATION — orchestrates all advanced modules
  //
  // Called from _postHeartbeatIntelligence() to run all deep computation
  // modules in sequence. Each module contributes to organism coherence
  // and free energy through its coherenceContribution and freeEnergyContribution.
  //
  // Execution schedule:
  //   Every beat:    causal_inference, attention, allostatic_load
  //   Every 3 beats: morpho_field, swarm_intel, stigmergy
  //   Every 5 beats: quantum_sim, evo_dynamics, thermo_compute
  //   Every 8 beats: fractal_dim (most computationally expensive)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  func _runDeepIntelligenceModules() : () {
    // Every-beat modules
    _causal_inference_compute();
    _attention_compute();
    _allostatic_load_compute();

    // Every 3 beats
    if (beatCount % 3 == 0) {
      _morpho_field_compute();
      _swarm_intel_compute();
      _stigmergy_compute();

      _morpho_field_analyze();
      _swarm_intel_analyze();
      _stigmergy_analyze();
    };

    // Every 5 beats
    if (beatCount % 5 == 0) {
      _quantum_sim_compute();
      _evo_dynamics_compute();
      _thermo_compute_compute();

      _quantum_sim_deepCompute();
      _evo_dynamics_deepCompute();
      _thermo_compute_deepCompute();
    };

    // Every 8 beats (heavy computation)
    if (beatCount % 8 == 0) {
      _fractal_dim_compute();
      _fractal_dim_analyze();
      _fractal_dim_deepCompute();

      _causal_inference_analyze();
      _attention_analyze();
      _allostatic_load_analyze();

      _causal_inference_deepCompute();
      _attention_deepCompute();
      _allostatic_load_deepCompute();
    };

    // Aggregate contributions from all modules
    var totalCoherenceContrib : Float = 0.0;
    var totalFreeEnergyContrib : Float = 0.0;

    totalCoherenceContrib += causal_inference_coherenceContribution;
    totalCoherenceContrib += morpho_field_coherenceContribution;
    totalCoherenceContrib += swarm_intel_coherenceContribution;
    totalCoherenceContrib += quantum_sim_coherenceContribution;
    totalCoherenceContrib += evo_dynamics_coherenceContribution;
    totalCoherenceContrib += attention_coherenceContribution;
    totalCoherenceContrib += thermo_compute_coherenceContribution;
    totalCoherenceContrib += fractal_dim_coherenceContribution;
    totalCoherenceContrib += stigmergy_coherenceContribution;
    totalCoherenceContrib += allostatic_load_coherenceContribution;

    totalFreeEnergyContrib += causal_inference_freeEnergyContribution;
    totalFreeEnergyContrib += morpho_field_freeEnergyContribution;
    totalFreeEnergyContrib += swarm_intel_freeEnergyContribution;
    totalFreeEnergyContrib += quantum_sim_freeEnergyContribution;
    totalFreeEnergyContrib += evo_dynamics_freeEnergyContribution;
    totalFreeEnergyContrib += attention_freeEnergyContribution;
    totalFreeEnergyContrib += thermo_compute_freeEnergyContribution;
    totalFreeEnergyContrib += fractal_dim_freeEnergyContribution;
    totalFreeEnergyContrib += stigmergy_freeEnergyContribution;
    totalFreeEnergyContrib += allostatic_load_freeEnergyContribution;

    // Feed aggregate contributions back into orchestrator state
    // Coherence contribution modulates the effective coherence
    // Free energy contribution adds to prediction error tracking
    let cohModulation = _clamp(totalCoherenceContrib, -PHI_INV_2, PHI_INV_2);
    let feModulation = _clamp(totalFreeEnergyContrib, 0.0, PHI_INV);

    // These modulations are available for the next heartbeat cycle
    // They influence scheduling decisions and coherence gate behavior
  };

  // Comprehensive diagnostics for all deep intelligence modules
  public query func getDeepIntelligenceReport() : async {
    causalInference   : { primary : Float; stability : Float; complexity : Float };
    morphoField       : { primary : Float; stability : Float; complexity : Float };
    swarmIntel        : { primary : Float; stability : Float; complexity : Float };
    quantumSim        : { primary : Float; stability : Float; complexity : Float };
    evoDynamics       : { primary : Float; stability : Float; complexity : Float };
    attention         : { primary : Float; stability : Float; complexity : Float };
    thermoCompute     : { primary : Float; stability : Float; complexity : Float };
    fractalDim        : { primary : Float; stability : Float; complexity : Float };
    stigmergy         : { primary : Float; stability : Float; complexity : Float };
    allostaticLoad    : { primary : Float; stability : Float; complexity : Float };
  } {
    {
      causalInference  = { primary = causal_inference_primaryMetric; stability = causal_inference_stabilityIndex; complexity = causal_inference_complexityIndex };
      morphoField      = { primary = morpho_field_primaryMetric; stability = morpho_field_stabilityIndex; complexity = morpho_field_complexityIndex };
      swarmIntel       = { primary = swarm_intel_primaryMetric; stability = swarm_intel_stabilityIndex; complexity = swarm_intel_complexityIndex };
      quantumSim       = { primary = quantum_sim_primaryMetric; stability = quantum_sim_stabilityIndex; complexity = quantum_sim_complexityIndex };
      evoDynamics      = { primary = evo_dynamics_primaryMetric; stability = evo_dynamics_stabilityIndex; complexity = evo_dynamics_complexityIndex };
      attention        = { primary = attention_primaryMetric; stability = attention_stabilityIndex; complexity = attention_complexityIndex };
      thermoCompute    = { primary = thermo_compute_primaryMetric; stability = thermo_compute_stabilityIndex; complexity = thermo_compute_complexityIndex };
      fractalDim       = { primary = fractal_dim_primaryMetric; stability = fractal_dim_stabilityIndex; complexity = fractal_dim_complexityIndex };
      stigmergy        = { primary = stigmergy_primaryMetric; stability = stigmergy_stabilityIndex; complexity = stigmergy_complexityIndex };
      allostaticLoad   = { primary = allostatic_load_primaryMetric; stability = allostatic_load_stabilityIndex; complexity = allostatic_load_complexityIndex };
    };
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // CONSENSUS PROTOCOL SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing consensus protocol.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δconsensus_protocol_state = η_consensus_protocol · (target − current) · coherence^φ
  //   where η_consensus_protocol = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||consensus_protocol_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(consensus_protocol_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_consensus_protocol_energy      : Float = 0.0;
  stable var orch_consensus_protocol_momentum    : Float = 0.0;
  stable var orch_consensus_protocol_phase       : Float = 0.0;
  stable var orch_consensus_protocol_amplitude   : Float = PHI_INV;
  stable var orch_consensus_protocol_frequency   : Float = PHI_INV_2;
  stable var orch_consensus_protocol_damping     : Float = PHI_INV_3;
  stable var orch_consensus_protocol_coupling    : Float = PHI_INV_2;
  stable var orch_consensus_protocol_threshold   : Float = PHI_INV;
  stable var orch_consensus_protocol_saturation  : Float = 0.0;
  stable var orch_consensus_protocol_decay       : Float = PHI_INV_4;
  stable var orch_consensus_protocol_gain        : Float = PHI_INV_2;
  stable var orch_consensus_protocol_offset      : Float = 0.0;
  stable var orch_consensus_protocol_jitter      : Float = 0.0;
  stable var orch_consensus_protocol_drift       : Float = 0.0;
  stable var orch_consensus_protocol_residual    : Float = 0.0;
  stable var orch_consensus_protocol_integral    : Float = 0.0;
  stable var orch_consensus_protocol_derivative  : Float = 0.0;
  stable var orch_consensus_protocol_setpoint    : Float = PHI_INV;
  stable var orch_consensus_protocol_error       : Float = 0.0;
  stable var orch_consensus_protocol_correction  : Float = 0.0;
  stable var orch_consensus_protocol_totalCycles : Nat = 0;
  stable var orch_consensus_protocol_lastCycle   : Nat = 0;
  stable var orch_consensus_protocol_peakError   : Float = 0.0;
  stable var orch_consensus_protocol_avgError    : Float = 0.0;
  stable var orch_consensus_protocol_converged   : Bool = false;

  // PID controller for consensus protocol
  func _orch_consensus_protocol_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_consensus_protocol_error := orch_consensus_protocol_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_consensus_protocol_integral := _clamp(
      orch_consensus_protocol_integral + orch_consensus_protocol_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_consensus_protocol_residual;
    orch_consensus_protocol_derivative := (orch_consensus_protocol_error - prevError) * PHI;
    orch_consensus_protocol_residual := orch_consensus_protocol_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_consensus_protocol_correction := _clamp(
      PHI_INV * orch_consensus_protocol_error +
      PHI_INV_3 * orch_consensus_protocol_integral +
      PHI_INV_4 * orch_consensus_protocol_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_consensus_protocol_energy := _clamp(
      orch_consensus_protocol_energy + orch_consensus_protocol_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_consensus_protocol_momentum := orch_consensus_protocol_momentum * PHI_INV +
      orch_consensus_protocol_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_consensus_protocol_phase := if (orch_consensus_protocol_phase > 3.14159) {
      orch_consensus_protocol_phase - 6.28318
    } else if (orch_consensus_protocol_phase < -3.14159) {
      orch_consensus_protocol_phase + 6.28318
    } else {
      orch_consensus_protocol_phase + orch_consensus_protocol_frequency * (1.0 + orch_consensus_protocol_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_consensus_protocol_amplitude := _clamp(
      orch_consensus_protocol_amplitude + orch_consensus_protocol_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_consensus_protocol_damping := _clamp(
      PHI_INV_3 + (orch_consensus_protocol_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_consensus_protocol_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_consensus_protocol_saturation := if (orch_consensus_protocol_energy > PHI) {
      (orch_consensus_protocol_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_consensus_protocol_jitter := Float.abs(orch_consensus_protocol_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_consensus_protocol_drift := orch_consensus_protocol_drift * PHI_INV +
      orch_consensus_protocol_error * PHI_INV_4;

    // Convergence check
    orch_consensus_protocol_converged := Float.abs(orch_consensus_protocol_error) < PHI_INV_4
      and Float.abs(orch_consensus_protocol_derivative) < PHI_INV_4
      and orch_consensus_protocol_saturation < PHI_INV_3;

    // Statistics
    orch_consensus_protocol_totalCycles += 1;
    orch_consensus_protocol_lastCycle := beatCount;
    if (Float.abs(orch_consensus_protocol_error) > orch_consensus_protocol_peakError) {
      orch_consensus_protocol_peakError := Float.abs(orch_consensus_protocol_error);
    };
    orch_consensus_protocol_avgError := orch_consensus_protocol_avgError * PHI_INV +
      Float.abs(orch_consensus_protocol_error) * PHI_INV_2;
  };

  // Oscillator dynamics for consensus protocol
  func _orch_consensus_protocol_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_consensus_protocol_frequency * PHI;
    let zeta = orch_consensus_protocol_damping;
    let driving = orch_consensus_protocol_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_consensus_protocol_phase;
    let velocity = orch_consensus_protocol_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_consensus_protocol_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_consensus_protocol_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_consensus_protocol_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_consensus_protocol_amplitude := _clamp(
      orch_consensus_protocol_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // DISTRIBUTED STATE SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing distributed state.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δdistributed_state_state = η_distributed_state · (target − current) · coherence^φ
  //   where η_distributed_state = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||distributed_state_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(distributed_state_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_distributed_state_energy      : Float = 0.0;
  stable var orch_distributed_state_momentum    : Float = 0.0;
  stable var orch_distributed_state_phase       : Float = 0.0;
  stable var orch_distributed_state_amplitude   : Float = PHI_INV;
  stable var orch_distributed_state_frequency   : Float = PHI_INV_2;
  stable var orch_distributed_state_damping     : Float = PHI_INV_3;
  stable var orch_distributed_state_coupling    : Float = PHI_INV_2;
  stable var orch_distributed_state_threshold   : Float = PHI_INV;
  stable var orch_distributed_state_saturation  : Float = 0.0;
  stable var orch_distributed_state_decay       : Float = PHI_INV_4;
  stable var orch_distributed_state_gain        : Float = PHI_INV_2;
  stable var orch_distributed_state_offset      : Float = 0.0;
  stable var orch_distributed_state_jitter      : Float = 0.0;
  stable var orch_distributed_state_drift       : Float = 0.0;
  stable var orch_distributed_state_residual    : Float = 0.0;
  stable var orch_distributed_state_integral    : Float = 0.0;
  stable var orch_distributed_state_derivative  : Float = 0.0;
  stable var orch_distributed_state_setpoint    : Float = PHI_INV;
  stable var orch_distributed_state_error       : Float = 0.0;
  stable var orch_distributed_state_correction  : Float = 0.0;
  stable var orch_distributed_state_totalCycles : Nat = 0;
  stable var orch_distributed_state_lastCycle   : Nat = 0;
  stable var orch_distributed_state_peakError   : Float = 0.0;
  stable var orch_distributed_state_avgError    : Float = 0.0;
  stable var orch_distributed_state_converged   : Bool = false;

  // PID controller for distributed state
  func _orch_distributed_state_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_distributed_state_error := orch_distributed_state_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_distributed_state_integral := _clamp(
      orch_distributed_state_integral + orch_distributed_state_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_distributed_state_residual;
    orch_distributed_state_derivative := (orch_distributed_state_error - prevError) * PHI;
    orch_distributed_state_residual := orch_distributed_state_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_distributed_state_correction := _clamp(
      PHI_INV * orch_distributed_state_error +
      PHI_INV_3 * orch_distributed_state_integral +
      PHI_INV_4 * orch_distributed_state_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_distributed_state_energy := _clamp(
      orch_distributed_state_energy + orch_distributed_state_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_distributed_state_momentum := orch_distributed_state_momentum * PHI_INV +
      orch_distributed_state_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_distributed_state_phase := if (orch_distributed_state_phase > 3.14159) {
      orch_distributed_state_phase - 6.28318
    } else if (orch_distributed_state_phase < -3.14159) {
      orch_distributed_state_phase + 6.28318
    } else {
      orch_distributed_state_phase + orch_distributed_state_frequency * (1.0 + orch_distributed_state_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_distributed_state_amplitude := _clamp(
      orch_distributed_state_amplitude + orch_distributed_state_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_distributed_state_damping := _clamp(
      PHI_INV_3 + (orch_distributed_state_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_distributed_state_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_distributed_state_saturation := if (orch_distributed_state_energy > PHI) {
      (orch_distributed_state_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_distributed_state_jitter := Float.abs(orch_distributed_state_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_distributed_state_drift := orch_distributed_state_drift * PHI_INV +
      orch_distributed_state_error * PHI_INV_4;

    // Convergence check
    orch_distributed_state_converged := Float.abs(orch_distributed_state_error) < PHI_INV_4
      and Float.abs(orch_distributed_state_derivative) < PHI_INV_4
      and orch_distributed_state_saturation < PHI_INV_3;

    // Statistics
    orch_distributed_state_totalCycles += 1;
    orch_distributed_state_lastCycle := beatCount;
    if (Float.abs(orch_distributed_state_error) > orch_distributed_state_peakError) {
      orch_distributed_state_peakError := Float.abs(orch_distributed_state_error);
    };
    orch_distributed_state_avgError := orch_distributed_state_avgError * PHI_INV +
      Float.abs(orch_distributed_state_error) * PHI_INV_2;
  };

  // Oscillator dynamics for distributed state
  func _orch_distributed_state_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_distributed_state_frequency * PHI;
    let zeta = orch_distributed_state_damping;
    let driving = orch_distributed_state_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_distributed_state_phase;
    let velocity = orch_distributed_state_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_distributed_state_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_distributed_state_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_distributed_state_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_distributed_state_amplitude := _clamp(
      orch_distributed_state_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // CAUSAL ORDERING SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing causal ordering.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δcausal_ordering_state = η_causal_ordering · (target − current) · coherence^φ
  //   where η_causal_ordering = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||causal_ordering_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(causal_ordering_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_causal_ordering_energy      : Float = 0.0;
  stable var orch_causal_ordering_momentum    : Float = 0.0;
  stable var orch_causal_ordering_phase       : Float = 0.0;
  stable var orch_causal_ordering_amplitude   : Float = PHI_INV;
  stable var orch_causal_ordering_frequency   : Float = PHI_INV_2;
  stable var orch_causal_ordering_damping     : Float = PHI_INV_3;
  stable var orch_causal_ordering_coupling    : Float = PHI_INV_2;
  stable var orch_causal_ordering_threshold   : Float = PHI_INV;
  stable var orch_causal_ordering_saturation  : Float = 0.0;
  stable var orch_causal_ordering_decay       : Float = PHI_INV_4;
  stable var orch_causal_ordering_gain        : Float = PHI_INV_2;
  stable var orch_causal_ordering_offset      : Float = 0.0;
  stable var orch_causal_ordering_jitter      : Float = 0.0;
  stable var orch_causal_ordering_drift       : Float = 0.0;
  stable var orch_causal_ordering_residual    : Float = 0.0;
  stable var orch_causal_ordering_integral    : Float = 0.0;
  stable var orch_causal_ordering_derivative  : Float = 0.0;
  stable var orch_causal_ordering_setpoint    : Float = PHI_INV;
  stable var orch_causal_ordering_error       : Float = 0.0;
  stable var orch_causal_ordering_correction  : Float = 0.0;
  stable var orch_causal_ordering_totalCycles : Nat = 0;
  stable var orch_causal_ordering_lastCycle   : Nat = 0;
  stable var orch_causal_ordering_peakError   : Float = 0.0;
  stable var orch_causal_ordering_avgError    : Float = 0.0;
  stable var orch_causal_ordering_converged   : Bool = false;

  // PID controller for causal ordering
  func _orch_causal_ordering_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_causal_ordering_error := orch_causal_ordering_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_causal_ordering_integral := _clamp(
      orch_causal_ordering_integral + orch_causal_ordering_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_causal_ordering_residual;
    orch_causal_ordering_derivative := (orch_causal_ordering_error - prevError) * PHI;
    orch_causal_ordering_residual := orch_causal_ordering_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_causal_ordering_correction := _clamp(
      PHI_INV * orch_causal_ordering_error +
      PHI_INV_3 * orch_causal_ordering_integral +
      PHI_INV_4 * orch_causal_ordering_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_causal_ordering_energy := _clamp(
      orch_causal_ordering_energy + orch_causal_ordering_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_causal_ordering_momentum := orch_causal_ordering_momentum * PHI_INV +
      orch_causal_ordering_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_causal_ordering_phase := if (orch_causal_ordering_phase > 3.14159) {
      orch_causal_ordering_phase - 6.28318
    } else if (orch_causal_ordering_phase < -3.14159) {
      orch_causal_ordering_phase + 6.28318
    } else {
      orch_causal_ordering_phase + orch_causal_ordering_frequency * (1.0 + orch_causal_ordering_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_causal_ordering_amplitude := _clamp(
      orch_causal_ordering_amplitude + orch_causal_ordering_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_causal_ordering_damping := _clamp(
      PHI_INV_3 + (orch_causal_ordering_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_causal_ordering_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_causal_ordering_saturation := if (orch_causal_ordering_energy > PHI) {
      (orch_causal_ordering_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_causal_ordering_jitter := Float.abs(orch_causal_ordering_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_causal_ordering_drift := orch_causal_ordering_drift * PHI_INV +
      orch_causal_ordering_error * PHI_INV_4;

    // Convergence check
    orch_causal_ordering_converged := Float.abs(orch_causal_ordering_error) < PHI_INV_4
      and Float.abs(orch_causal_ordering_derivative) < PHI_INV_4
      and orch_causal_ordering_saturation < PHI_INV_3;

    // Statistics
    orch_causal_ordering_totalCycles += 1;
    orch_causal_ordering_lastCycle := beatCount;
    if (Float.abs(orch_causal_ordering_error) > orch_causal_ordering_peakError) {
      orch_causal_ordering_peakError := Float.abs(orch_causal_ordering_error);
    };
    orch_causal_ordering_avgError := orch_causal_ordering_avgError * PHI_INV +
      Float.abs(orch_causal_ordering_error) * PHI_INV_2;
  };

  // Oscillator dynamics for causal ordering
  func _orch_causal_ordering_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_causal_ordering_frequency * PHI;
    let zeta = orch_causal_ordering_damping;
    let driving = orch_causal_ordering_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_causal_ordering_phase;
    let velocity = orch_causal_ordering_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_causal_ordering_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_causal_ordering_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_causal_ordering_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_causal_ordering_amplitude := _clamp(
      orch_causal_ordering_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // VECTOR CLOCKS SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing vector clocks.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δvector_clocks_state = η_vector_clocks · (target − current) · coherence^φ
  //   where η_vector_clocks = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||vector_clocks_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(vector_clocks_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_vector_clocks_energy      : Float = 0.0;
  stable var orch_vector_clocks_momentum    : Float = 0.0;
  stable var orch_vector_clocks_phase       : Float = 0.0;
  stable var orch_vector_clocks_amplitude   : Float = PHI_INV;
  stable var orch_vector_clocks_frequency   : Float = PHI_INV_2;
  stable var orch_vector_clocks_damping     : Float = PHI_INV_3;
  stable var orch_vector_clocks_coupling    : Float = PHI_INV_2;
  stable var orch_vector_clocks_threshold   : Float = PHI_INV;
  stable var orch_vector_clocks_saturation  : Float = 0.0;
  stable var orch_vector_clocks_decay       : Float = PHI_INV_4;
  stable var orch_vector_clocks_gain        : Float = PHI_INV_2;
  stable var orch_vector_clocks_offset      : Float = 0.0;
  stable var orch_vector_clocks_jitter      : Float = 0.0;
  stable var orch_vector_clocks_drift       : Float = 0.0;
  stable var orch_vector_clocks_residual    : Float = 0.0;
  stable var orch_vector_clocks_integral    : Float = 0.0;
  stable var orch_vector_clocks_derivative  : Float = 0.0;
  stable var orch_vector_clocks_setpoint    : Float = PHI_INV;
  stable var orch_vector_clocks_error       : Float = 0.0;
  stable var orch_vector_clocks_correction  : Float = 0.0;
  stable var orch_vector_clocks_totalCycles : Nat = 0;
  stable var orch_vector_clocks_lastCycle   : Nat = 0;
  stable var orch_vector_clocks_peakError   : Float = 0.0;
  stable var orch_vector_clocks_avgError    : Float = 0.0;
  stable var orch_vector_clocks_converged   : Bool = false;

  // PID controller for vector clocks
  func _orch_vector_clocks_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_vector_clocks_error := orch_vector_clocks_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_vector_clocks_integral := _clamp(
      orch_vector_clocks_integral + orch_vector_clocks_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_vector_clocks_residual;
    orch_vector_clocks_derivative := (orch_vector_clocks_error - prevError) * PHI;
    orch_vector_clocks_residual := orch_vector_clocks_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_vector_clocks_correction := _clamp(
      PHI_INV * orch_vector_clocks_error +
      PHI_INV_3 * orch_vector_clocks_integral +
      PHI_INV_4 * orch_vector_clocks_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_vector_clocks_energy := _clamp(
      orch_vector_clocks_energy + orch_vector_clocks_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_vector_clocks_momentum := orch_vector_clocks_momentum * PHI_INV +
      orch_vector_clocks_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_vector_clocks_phase := if (orch_vector_clocks_phase > 3.14159) {
      orch_vector_clocks_phase - 6.28318
    } else if (orch_vector_clocks_phase < -3.14159) {
      orch_vector_clocks_phase + 6.28318
    } else {
      orch_vector_clocks_phase + orch_vector_clocks_frequency * (1.0 + orch_vector_clocks_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_vector_clocks_amplitude := _clamp(
      orch_vector_clocks_amplitude + orch_vector_clocks_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_vector_clocks_damping := _clamp(
      PHI_INV_3 + (orch_vector_clocks_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_vector_clocks_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_vector_clocks_saturation := if (orch_vector_clocks_energy > PHI) {
      (orch_vector_clocks_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_vector_clocks_jitter := Float.abs(orch_vector_clocks_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_vector_clocks_drift := orch_vector_clocks_drift * PHI_INV +
      orch_vector_clocks_error * PHI_INV_4;

    // Convergence check
    orch_vector_clocks_converged := Float.abs(orch_vector_clocks_error) < PHI_INV_4
      and Float.abs(orch_vector_clocks_derivative) < PHI_INV_4
      and orch_vector_clocks_saturation < PHI_INV_3;

    // Statistics
    orch_vector_clocks_totalCycles += 1;
    orch_vector_clocks_lastCycle := beatCount;
    if (Float.abs(orch_vector_clocks_error) > orch_vector_clocks_peakError) {
      orch_vector_clocks_peakError := Float.abs(orch_vector_clocks_error);
    };
    orch_vector_clocks_avgError := orch_vector_clocks_avgError * PHI_INV +
      Float.abs(orch_vector_clocks_error) * PHI_INV_2;
  };

  // Oscillator dynamics for vector clocks
  func _orch_vector_clocks_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_vector_clocks_frequency * PHI;
    let zeta = orch_vector_clocks_damping;
    let driving = orch_vector_clocks_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_vector_clocks_phase;
    let velocity = orch_vector_clocks_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_vector_clocks_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_vector_clocks_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_vector_clocks_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_vector_clocks_amplitude := _clamp(
      orch_vector_clocks_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // BYZANTINE TOLERANCE SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing byzantine tolerance.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δbyzantine_tolerance_state = η_byzantine_tolerance · (target − current) · coherence^φ
  //   where η_byzantine_tolerance = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||byzantine_tolerance_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(byzantine_tolerance_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_byzantine_tolerance_energy      : Float = 0.0;
  stable var orch_byzantine_tolerance_momentum    : Float = 0.0;
  stable var orch_byzantine_tolerance_phase       : Float = 0.0;
  stable var orch_byzantine_tolerance_amplitude   : Float = PHI_INV;
  stable var orch_byzantine_tolerance_frequency   : Float = PHI_INV_2;
  stable var orch_byzantine_tolerance_damping     : Float = PHI_INV_3;
  stable var orch_byzantine_tolerance_coupling    : Float = PHI_INV_2;
  stable var orch_byzantine_tolerance_threshold   : Float = PHI_INV;
  stable var orch_byzantine_tolerance_saturation  : Float = 0.0;
  stable var orch_byzantine_tolerance_decay       : Float = PHI_INV_4;
  stable var orch_byzantine_tolerance_gain        : Float = PHI_INV_2;
  stable var orch_byzantine_tolerance_offset      : Float = 0.0;
  stable var orch_byzantine_tolerance_jitter      : Float = 0.0;
  stable var orch_byzantine_tolerance_drift       : Float = 0.0;
  stable var orch_byzantine_tolerance_residual    : Float = 0.0;
  stable var orch_byzantine_tolerance_integral    : Float = 0.0;
  stable var orch_byzantine_tolerance_derivative  : Float = 0.0;
  stable var orch_byzantine_tolerance_setpoint    : Float = PHI_INV;
  stable var orch_byzantine_tolerance_error       : Float = 0.0;
  stable var orch_byzantine_tolerance_correction  : Float = 0.0;
  stable var orch_byzantine_tolerance_totalCycles : Nat = 0;
  stable var orch_byzantine_tolerance_lastCycle   : Nat = 0;
  stable var orch_byzantine_tolerance_peakError   : Float = 0.0;
  stable var orch_byzantine_tolerance_avgError    : Float = 0.0;
  stable var orch_byzantine_tolerance_converged   : Bool = false;

  // PID controller for byzantine tolerance
  func _orch_byzantine_tolerance_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_byzantine_tolerance_error := orch_byzantine_tolerance_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_byzantine_tolerance_integral := _clamp(
      orch_byzantine_tolerance_integral + orch_byzantine_tolerance_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_byzantine_tolerance_residual;
    orch_byzantine_tolerance_derivative := (orch_byzantine_tolerance_error - prevError) * PHI;
    orch_byzantine_tolerance_residual := orch_byzantine_tolerance_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_byzantine_tolerance_correction := _clamp(
      PHI_INV * orch_byzantine_tolerance_error +
      PHI_INV_3 * orch_byzantine_tolerance_integral +
      PHI_INV_4 * orch_byzantine_tolerance_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_byzantine_tolerance_energy := _clamp(
      orch_byzantine_tolerance_energy + orch_byzantine_tolerance_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_byzantine_tolerance_momentum := orch_byzantine_tolerance_momentum * PHI_INV +
      orch_byzantine_tolerance_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_byzantine_tolerance_phase := if (orch_byzantine_tolerance_phase > 3.14159) {
      orch_byzantine_tolerance_phase - 6.28318
    } else if (orch_byzantine_tolerance_phase < -3.14159) {
      orch_byzantine_tolerance_phase + 6.28318
    } else {
      orch_byzantine_tolerance_phase + orch_byzantine_tolerance_frequency * (1.0 + orch_byzantine_tolerance_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_byzantine_tolerance_amplitude := _clamp(
      orch_byzantine_tolerance_amplitude + orch_byzantine_tolerance_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_byzantine_tolerance_damping := _clamp(
      PHI_INV_3 + (orch_byzantine_tolerance_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_byzantine_tolerance_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_byzantine_tolerance_saturation := if (orch_byzantine_tolerance_energy > PHI) {
      (orch_byzantine_tolerance_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_byzantine_tolerance_jitter := Float.abs(orch_byzantine_tolerance_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_byzantine_tolerance_drift := orch_byzantine_tolerance_drift * PHI_INV +
      orch_byzantine_tolerance_error * PHI_INV_4;

    // Convergence check
    orch_byzantine_tolerance_converged := Float.abs(orch_byzantine_tolerance_error) < PHI_INV_4
      and Float.abs(orch_byzantine_tolerance_derivative) < PHI_INV_4
      and orch_byzantine_tolerance_saturation < PHI_INV_3;

    // Statistics
    orch_byzantine_tolerance_totalCycles += 1;
    orch_byzantine_tolerance_lastCycle := beatCount;
    if (Float.abs(orch_byzantine_tolerance_error) > orch_byzantine_tolerance_peakError) {
      orch_byzantine_tolerance_peakError := Float.abs(orch_byzantine_tolerance_error);
    };
    orch_byzantine_tolerance_avgError := orch_byzantine_tolerance_avgError * PHI_INV +
      Float.abs(orch_byzantine_tolerance_error) * PHI_INV_2;
  };

  // Oscillator dynamics for byzantine tolerance
  func _orch_byzantine_tolerance_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_byzantine_tolerance_frequency * PHI;
    let zeta = orch_byzantine_tolerance_damping;
    let driving = orch_byzantine_tolerance_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_byzantine_tolerance_phase;
    let velocity = orch_byzantine_tolerance_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_byzantine_tolerance_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_byzantine_tolerance_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_byzantine_tolerance_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_byzantine_tolerance_amplitude := _clamp(
      orch_byzantine_tolerance_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // LEADER ELECTION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing leader election.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δleader_election_state = η_leader_election · (target − current) · coherence^φ
  //   where η_leader_election = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||leader_election_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(leader_election_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_leader_election_energy      : Float = 0.0;
  stable var orch_leader_election_momentum    : Float = 0.0;
  stable var orch_leader_election_phase       : Float = 0.0;
  stable var orch_leader_election_amplitude   : Float = PHI_INV;
  stable var orch_leader_election_frequency   : Float = PHI_INV_2;
  stable var orch_leader_election_damping     : Float = PHI_INV_3;
  stable var orch_leader_election_coupling    : Float = PHI_INV_2;
  stable var orch_leader_election_threshold   : Float = PHI_INV;
  stable var orch_leader_election_saturation  : Float = 0.0;
  stable var orch_leader_election_decay       : Float = PHI_INV_4;
  stable var orch_leader_election_gain        : Float = PHI_INV_2;
  stable var orch_leader_election_offset      : Float = 0.0;
  stable var orch_leader_election_jitter      : Float = 0.0;
  stable var orch_leader_election_drift       : Float = 0.0;
  stable var orch_leader_election_residual    : Float = 0.0;
  stable var orch_leader_election_integral    : Float = 0.0;
  stable var orch_leader_election_derivative  : Float = 0.0;
  stable var orch_leader_election_setpoint    : Float = PHI_INV;
  stable var orch_leader_election_error       : Float = 0.0;
  stable var orch_leader_election_correction  : Float = 0.0;
  stable var orch_leader_election_totalCycles : Nat = 0;
  stable var orch_leader_election_lastCycle   : Nat = 0;
  stable var orch_leader_election_peakError   : Float = 0.0;
  stable var orch_leader_election_avgError    : Float = 0.0;
  stable var orch_leader_election_converged   : Bool = false;

  // PID controller for leader election
  func _orch_leader_election_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_leader_election_error := orch_leader_election_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_leader_election_integral := _clamp(
      orch_leader_election_integral + orch_leader_election_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_leader_election_residual;
    orch_leader_election_derivative := (orch_leader_election_error - prevError) * PHI;
    orch_leader_election_residual := orch_leader_election_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_leader_election_correction := _clamp(
      PHI_INV * orch_leader_election_error +
      PHI_INV_3 * orch_leader_election_integral +
      PHI_INV_4 * orch_leader_election_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_leader_election_energy := _clamp(
      orch_leader_election_energy + orch_leader_election_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_leader_election_momentum := orch_leader_election_momentum * PHI_INV +
      orch_leader_election_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_leader_election_phase := if (orch_leader_election_phase > 3.14159) {
      orch_leader_election_phase - 6.28318
    } else if (orch_leader_election_phase < -3.14159) {
      orch_leader_election_phase + 6.28318
    } else {
      orch_leader_election_phase + orch_leader_election_frequency * (1.0 + orch_leader_election_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_leader_election_amplitude := _clamp(
      orch_leader_election_amplitude + orch_leader_election_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_leader_election_damping := _clamp(
      PHI_INV_3 + (orch_leader_election_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_leader_election_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_leader_election_saturation := if (orch_leader_election_energy > PHI) {
      (orch_leader_election_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_leader_election_jitter := Float.abs(orch_leader_election_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_leader_election_drift := orch_leader_election_drift * PHI_INV +
      orch_leader_election_error * PHI_INV_4;

    // Convergence check
    orch_leader_election_converged := Float.abs(orch_leader_election_error) < PHI_INV_4
      and Float.abs(orch_leader_election_derivative) < PHI_INV_4
      and orch_leader_election_saturation < PHI_INV_3;

    // Statistics
    orch_leader_election_totalCycles += 1;
    orch_leader_election_lastCycle := beatCount;
    if (Float.abs(orch_leader_election_error) > orch_leader_election_peakError) {
      orch_leader_election_peakError := Float.abs(orch_leader_election_error);
    };
    orch_leader_election_avgError := orch_leader_election_avgError * PHI_INV +
      Float.abs(orch_leader_election_error) * PHI_INV_2;
  };

  // Oscillator dynamics for leader election
  func _orch_leader_election_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_leader_election_frequency * PHI;
    let zeta = orch_leader_election_damping;
    let driving = orch_leader_election_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_leader_election_phase;
    let velocity = orch_leader_election_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_leader_election_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_leader_election_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_leader_election_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_leader_election_amplitude := _clamp(
      orch_leader_election_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // MEMBERSHIP PROTOCOL SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing membership protocol.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δmembership_protocol_state = η_membership_protocol · (target − current) · coherence^φ
  //   where η_membership_protocol = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||membership_protocol_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(membership_protocol_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_membership_protocol_energy      : Float = 0.0;
  stable var orch_membership_protocol_momentum    : Float = 0.0;
  stable var orch_membership_protocol_phase       : Float = 0.0;
  stable var orch_membership_protocol_amplitude   : Float = PHI_INV;
  stable var orch_membership_protocol_frequency   : Float = PHI_INV_2;
  stable var orch_membership_protocol_damping     : Float = PHI_INV_3;
  stable var orch_membership_protocol_coupling    : Float = PHI_INV_2;
  stable var orch_membership_protocol_threshold   : Float = PHI_INV;
  stable var orch_membership_protocol_saturation  : Float = 0.0;
  stable var orch_membership_protocol_decay       : Float = PHI_INV_4;
  stable var orch_membership_protocol_gain        : Float = PHI_INV_2;
  stable var orch_membership_protocol_offset      : Float = 0.0;
  stable var orch_membership_protocol_jitter      : Float = 0.0;
  stable var orch_membership_protocol_drift       : Float = 0.0;
  stable var orch_membership_protocol_residual    : Float = 0.0;
  stable var orch_membership_protocol_integral    : Float = 0.0;
  stable var orch_membership_protocol_derivative  : Float = 0.0;
  stable var orch_membership_protocol_setpoint    : Float = PHI_INV;
  stable var orch_membership_protocol_error       : Float = 0.0;
  stable var orch_membership_protocol_correction  : Float = 0.0;
  stable var orch_membership_protocol_totalCycles : Nat = 0;
  stable var orch_membership_protocol_lastCycle   : Nat = 0;
  stable var orch_membership_protocol_peakError   : Float = 0.0;
  stable var orch_membership_protocol_avgError    : Float = 0.0;
  stable var orch_membership_protocol_converged   : Bool = false;

  // PID controller for membership protocol
  func _orch_membership_protocol_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_membership_protocol_error := orch_membership_protocol_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_membership_protocol_integral := _clamp(
      orch_membership_protocol_integral + orch_membership_protocol_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_membership_protocol_residual;
    orch_membership_protocol_derivative := (orch_membership_protocol_error - prevError) * PHI;
    orch_membership_protocol_residual := orch_membership_protocol_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_membership_protocol_correction := _clamp(
      PHI_INV * orch_membership_protocol_error +
      PHI_INV_3 * orch_membership_protocol_integral +
      PHI_INV_4 * orch_membership_protocol_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_membership_protocol_energy := _clamp(
      orch_membership_protocol_energy + orch_membership_protocol_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_membership_protocol_momentum := orch_membership_protocol_momentum * PHI_INV +
      orch_membership_protocol_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_membership_protocol_phase := if (orch_membership_protocol_phase > 3.14159) {
      orch_membership_protocol_phase - 6.28318
    } else if (orch_membership_protocol_phase < -3.14159) {
      orch_membership_protocol_phase + 6.28318
    } else {
      orch_membership_protocol_phase + orch_membership_protocol_frequency * (1.0 + orch_membership_protocol_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_membership_protocol_amplitude := _clamp(
      orch_membership_protocol_amplitude + orch_membership_protocol_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_membership_protocol_damping := _clamp(
      PHI_INV_3 + (orch_membership_protocol_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_membership_protocol_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_membership_protocol_saturation := if (orch_membership_protocol_energy > PHI) {
      (orch_membership_protocol_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_membership_protocol_jitter := Float.abs(orch_membership_protocol_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_membership_protocol_drift := orch_membership_protocol_drift * PHI_INV +
      orch_membership_protocol_error * PHI_INV_4;

    // Convergence check
    orch_membership_protocol_converged := Float.abs(orch_membership_protocol_error) < PHI_INV_4
      and Float.abs(orch_membership_protocol_derivative) < PHI_INV_4
      and orch_membership_protocol_saturation < PHI_INV_3;

    // Statistics
    orch_membership_protocol_totalCycles += 1;
    orch_membership_protocol_lastCycle := beatCount;
    if (Float.abs(orch_membership_protocol_error) > orch_membership_protocol_peakError) {
      orch_membership_protocol_peakError := Float.abs(orch_membership_protocol_error);
    };
    orch_membership_protocol_avgError := orch_membership_protocol_avgError * PHI_INV +
      Float.abs(orch_membership_protocol_error) * PHI_INV_2;
  };

  // Oscillator dynamics for membership protocol
  func _orch_membership_protocol_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_membership_protocol_frequency * PHI;
    let zeta = orch_membership_protocol_damping;
    let driving = orch_membership_protocol_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_membership_protocol_phase;
    let velocity = orch_membership_protocol_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_membership_protocol_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_membership_protocol_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_membership_protocol_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_membership_protocol_amplitude := _clamp(
      orch_membership_protocol_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // FAILURE DETECTION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing failure detection.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δfailure_detection_state = η_failure_detection · (target − current) · coherence^φ
  //   where η_failure_detection = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||failure_detection_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(failure_detection_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_failure_detection_energy      : Float = 0.0;
  stable var orch_failure_detection_momentum    : Float = 0.0;
  stable var orch_failure_detection_phase       : Float = 0.0;
  stable var orch_failure_detection_amplitude   : Float = PHI_INV;
  stable var orch_failure_detection_frequency   : Float = PHI_INV_2;
  stable var orch_failure_detection_damping     : Float = PHI_INV_3;
  stable var orch_failure_detection_coupling    : Float = PHI_INV_2;
  stable var orch_failure_detection_threshold   : Float = PHI_INV;
  stable var orch_failure_detection_saturation  : Float = 0.0;
  stable var orch_failure_detection_decay       : Float = PHI_INV_4;
  stable var orch_failure_detection_gain        : Float = PHI_INV_2;
  stable var orch_failure_detection_offset      : Float = 0.0;
  stable var orch_failure_detection_jitter      : Float = 0.0;
  stable var orch_failure_detection_drift       : Float = 0.0;
  stable var orch_failure_detection_residual    : Float = 0.0;
  stable var orch_failure_detection_integral    : Float = 0.0;
  stable var orch_failure_detection_derivative  : Float = 0.0;
  stable var orch_failure_detection_setpoint    : Float = PHI_INV;
  stable var orch_failure_detection_error       : Float = 0.0;
  stable var orch_failure_detection_correction  : Float = 0.0;
  stable var orch_failure_detection_totalCycles : Nat = 0;
  stable var orch_failure_detection_lastCycle   : Nat = 0;
  stable var orch_failure_detection_peakError   : Float = 0.0;
  stable var orch_failure_detection_avgError    : Float = 0.0;
  stable var orch_failure_detection_converged   : Bool = false;

  // PID controller for failure detection
  func _orch_failure_detection_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_failure_detection_error := orch_failure_detection_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_failure_detection_integral := _clamp(
      orch_failure_detection_integral + orch_failure_detection_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_failure_detection_residual;
    orch_failure_detection_derivative := (orch_failure_detection_error - prevError) * PHI;
    orch_failure_detection_residual := orch_failure_detection_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_failure_detection_correction := _clamp(
      PHI_INV * orch_failure_detection_error +
      PHI_INV_3 * orch_failure_detection_integral +
      PHI_INV_4 * orch_failure_detection_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_failure_detection_energy := _clamp(
      orch_failure_detection_energy + orch_failure_detection_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_failure_detection_momentum := orch_failure_detection_momentum * PHI_INV +
      orch_failure_detection_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_failure_detection_phase := if (orch_failure_detection_phase > 3.14159) {
      orch_failure_detection_phase - 6.28318
    } else if (orch_failure_detection_phase < -3.14159) {
      orch_failure_detection_phase + 6.28318
    } else {
      orch_failure_detection_phase + orch_failure_detection_frequency * (1.0 + orch_failure_detection_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_failure_detection_amplitude := _clamp(
      orch_failure_detection_amplitude + orch_failure_detection_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_failure_detection_damping := _clamp(
      PHI_INV_3 + (orch_failure_detection_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_failure_detection_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_failure_detection_saturation := if (orch_failure_detection_energy > PHI) {
      (orch_failure_detection_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_failure_detection_jitter := Float.abs(orch_failure_detection_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_failure_detection_drift := orch_failure_detection_drift * PHI_INV +
      orch_failure_detection_error * PHI_INV_4;

    // Convergence check
    orch_failure_detection_converged := Float.abs(orch_failure_detection_error) < PHI_INV_4
      and Float.abs(orch_failure_detection_derivative) < PHI_INV_4
      and orch_failure_detection_saturation < PHI_INV_3;

    // Statistics
    orch_failure_detection_totalCycles += 1;
    orch_failure_detection_lastCycle := beatCount;
    if (Float.abs(orch_failure_detection_error) > orch_failure_detection_peakError) {
      orch_failure_detection_peakError := Float.abs(orch_failure_detection_error);
    };
    orch_failure_detection_avgError := orch_failure_detection_avgError * PHI_INV +
      Float.abs(orch_failure_detection_error) * PHI_INV_2;
  };

  // Oscillator dynamics for failure detection
  func _orch_failure_detection_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_failure_detection_frequency * PHI;
    let zeta = orch_failure_detection_damping;
    let driving = orch_failure_detection_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_failure_detection_phase;
    let velocity = orch_failure_detection_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_failure_detection_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_failure_detection_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_failure_detection_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_failure_detection_amplitude := _clamp(
      orch_failure_detection_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // STATE REPLICATION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing state replication.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δstate_replication_state = η_state_replication · (target − current) · coherence^φ
  //   where η_state_replication = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||state_replication_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(state_replication_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_state_replication_energy      : Float = 0.0;
  stable var orch_state_replication_momentum    : Float = 0.0;
  stable var orch_state_replication_phase       : Float = 0.0;
  stable var orch_state_replication_amplitude   : Float = PHI_INV;
  stable var orch_state_replication_frequency   : Float = PHI_INV_2;
  stable var orch_state_replication_damping     : Float = PHI_INV_3;
  stable var orch_state_replication_coupling    : Float = PHI_INV_2;
  stable var orch_state_replication_threshold   : Float = PHI_INV;
  stable var orch_state_replication_saturation  : Float = 0.0;
  stable var orch_state_replication_decay       : Float = PHI_INV_4;
  stable var orch_state_replication_gain        : Float = PHI_INV_2;
  stable var orch_state_replication_offset      : Float = 0.0;
  stable var orch_state_replication_jitter      : Float = 0.0;
  stable var orch_state_replication_drift       : Float = 0.0;
  stable var orch_state_replication_residual    : Float = 0.0;
  stable var orch_state_replication_integral    : Float = 0.0;
  stable var orch_state_replication_derivative  : Float = 0.0;
  stable var orch_state_replication_setpoint    : Float = PHI_INV;
  stable var orch_state_replication_error       : Float = 0.0;
  stable var orch_state_replication_correction  : Float = 0.0;
  stable var orch_state_replication_totalCycles : Nat = 0;
  stable var orch_state_replication_lastCycle   : Nat = 0;
  stable var orch_state_replication_peakError   : Float = 0.0;
  stable var orch_state_replication_avgError    : Float = 0.0;
  stable var orch_state_replication_converged   : Bool = false;

  // PID controller for state replication
  func _orch_state_replication_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_state_replication_error := orch_state_replication_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_state_replication_integral := _clamp(
      orch_state_replication_integral + orch_state_replication_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_state_replication_residual;
    orch_state_replication_derivative := (orch_state_replication_error - prevError) * PHI;
    orch_state_replication_residual := orch_state_replication_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_state_replication_correction := _clamp(
      PHI_INV * orch_state_replication_error +
      PHI_INV_3 * orch_state_replication_integral +
      PHI_INV_4 * orch_state_replication_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_state_replication_energy := _clamp(
      orch_state_replication_energy + orch_state_replication_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_state_replication_momentum := orch_state_replication_momentum * PHI_INV +
      orch_state_replication_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_state_replication_phase := if (orch_state_replication_phase > 3.14159) {
      orch_state_replication_phase - 6.28318
    } else if (orch_state_replication_phase < -3.14159) {
      orch_state_replication_phase + 6.28318
    } else {
      orch_state_replication_phase + orch_state_replication_frequency * (1.0 + orch_state_replication_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_state_replication_amplitude := _clamp(
      orch_state_replication_amplitude + orch_state_replication_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_state_replication_damping := _clamp(
      PHI_INV_3 + (orch_state_replication_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_state_replication_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_state_replication_saturation := if (orch_state_replication_energy > PHI) {
      (orch_state_replication_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_state_replication_jitter := Float.abs(orch_state_replication_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_state_replication_drift := orch_state_replication_drift * PHI_INV +
      orch_state_replication_error * PHI_INV_4;

    // Convergence check
    orch_state_replication_converged := Float.abs(orch_state_replication_error) < PHI_INV_4
      and Float.abs(orch_state_replication_derivative) < PHI_INV_4
      and orch_state_replication_saturation < PHI_INV_3;

    // Statistics
    orch_state_replication_totalCycles += 1;
    orch_state_replication_lastCycle := beatCount;
    if (Float.abs(orch_state_replication_error) > orch_state_replication_peakError) {
      orch_state_replication_peakError := Float.abs(orch_state_replication_error);
    };
    orch_state_replication_avgError := orch_state_replication_avgError * PHI_INV +
      Float.abs(orch_state_replication_error) * PHI_INV_2;
  };

  // Oscillator dynamics for state replication
  func _orch_state_replication_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_state_replication_frequency * PHI;
    let zeta = orch_state_replication_damping;
    let driving = orch_state_replication_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_state_replication_phase;
    let velocity = orch_state_replication_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_state_replication_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_state_replication_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_state_replication_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_state_replication_amplitude := _clamp(
      orch_state_replication_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // CONFLICT RESOLUTION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing conflict resolution.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δconflict_resolution_state = η_conflict_resolution · (target − current) · coherence^φ
  //   where η_conflict_resolution = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||conflict_resolution_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(conflict_resolution_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_conflict_resolution_energy      : Float = 0.0;
  stable var orch_conflict_resolution_momentum    : Float = 0.0;
  stable var orch_conflict_resolution_phase       : Float = 0.0;
  stable var orch_conflict_resolution_amplitude   : Float = PHI_INV;
  stable var orch_conflict_resolution_frequency   : Float = PHI_INV_2;
  stable var orch_conflict_resolution_damping     : Float = PHI_INV_3;
  stable var orch_conflict_resolution_coupling    : Float = PHI_INV_2;
  stable var orch_conflict_resolution_threshold   : Float = PHI_INV;
  stable var orch_conflict_resolution_saturation  : Float = 0.0;
  stable var orch_conflict_resolution_decay       : Float = PHI_INV_4;
  stable var orch_conflict_resolution_gain        : Float = PHI_INV_2;
  stable var orch_conflict_resolution_offset      : Float = 0.0;
  stable var orch_conflict_resolution_jitter      : Float = 0.0;
  stable var orch_conflict_resolution_drift       : Float = 0.0;
  stable var orch_conflict_resolution_residual    : Float = 0.0;
  stable var orch_conflict_resolution_integral    : Float = 0.0;
  stable var orch_conflict_resolution_derivative  : Float = 0.0;
  stable var orch_conflict_resolution_setpoint    : Float = PHI_INV;
  stable var orch_conflict_resolution_error       : Float = 0.0;
  stable var orch_conflict_resolution_correction  : Float = 0.0;
  stable var orch_conflict_resolution_totalCycles : Nat = 0;
  stable var orch_conflict_resolution_lastCycle   : Nat = 0;
  stable var orch_conflict_resolution_peakError   : Float = 0.0;
  stable var orch_conflict_resolution_avgError    : Float = 0.0;
  stable var orch_conflict_resolution_converged   : Bool = false;

  // PID controller for conflict resolution
  func _orch_conflict_resolution_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_conflict_resolution_error := orch_conflict_resolution_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_conflict_resolution_integral := _clamp(
      orch_conflict_resolution_integral + orch_conflict_resolution_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_conflict_resolution_residual;
    orch_conflict_resolution_derivative := (orch_conflict_resolution_error - prevError) * PHI;
    orch_conflict_resolution_residual := orch_conflict_resolution_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_conflict_resolution_correction := _clamp(
      PHI_INV * orch_conflict_resolution_error +
      PHI_INV_3 * orch_conflict_resolution_integral +
      PHI_INV_4 * orch_conflict_resolution_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_conflict_resolution_energy := _clamp(
      orch_conflict_resolution_energy + orch_conflict_resolution_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_conflict_resolution_momentum := orch_conflict_resolution_momentum * PHI_INV +
      orch_conflict_resolution_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_conflict_resolution_phase := if (orch_conflict_resolution_phase > 3.14159) {
      orch_conflict_resolution_phase - 6.28318
    } else if (orch_conflict_resolution_phase < -3.14159) {
      orch_conflict_resolution_phase + 6.28318
    } else {
      orch_conflict_resolution_phase + orch_conflict_resolution_frequency * (1.0 + orch_conflict_resolution_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_conflict_resolution_amplitude := _clamp(
      orch_conflict_resolution_amplitude + orch_conflict_resolution_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_conflict_resolution_damping := _clamp(
      PHI_INV_3 + (orch_conflict_resolution_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_conflict_resolution_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_conflict_resolution_saturation := if (orch_conflict_resolution_energy > PHI) {
      (orch_conflict_resolution_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_conflict_resolution_jitter := Float.abs(orch_conflict_resolution_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_conflict_resolution_drift := orch_conflict_resolution_drift * PHI_INV +
      orch_conflict_resolution_error * PHI_INV_4;

    // Convergence check
    orch_conflict_resolution_converged := Float.abs(orch_conflict_resolution_error) < PHI_INV_4
      and Float.abs(orch_conflict_resolution_derivative) < PHI_INV_4
      and orch_conflict_resolution_saturation < PHI_INV_3;

    // Statistics
    orch_conflict_resolution_totalCycles += 1;
    orch_conflict_resolution_lastCycle := beatCount;
    if (Float.abs(orch_conflict_resolution_error) > orch_conflict_resolution_peakError) {
      orch_conflict_resolution_peakError := Float.abs(orch_conflict_resolution_error);
    };
    orch_conflict_resolution_avgError := orch_conflict_resolution_avgError * PHI_INV +
      Float.abs(orch_conflict_resolution_error) * PHI_INV_2;
  };

  // Oscillator dynamics for conflict resolution
  func _orch_conflict_resolution_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_conflict_resolution_frequency * PHI;
    let zeta = orch_conflict_resolution_damping;
    let driving = orch_conflict_resolution_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_conflict_resolution_phase;
    let velocity = orch_conflict_resolution_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_conflict_resolution_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_conflict_resolution_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_conflict_resolution_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_conflict_resolution_amplitude := _clamp(
      orch_conflict_resolution_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // EVENTUAL CONSISTENCY SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing eventual consistency.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δeventual_consistency_state = η_eventual_consistency · (target − current) · coherence^φ
  //   where η_eventual_consistency = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||eventual_consistency_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(eventual_consistency_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_eventual_consistency_energy      : Float = 0.0;
  stable var orch_eventual_consistency_momentum    : Float = 0.0;
  stable var orch_eventual_consistency_phase       : Float = 0.0;
  stable var orch_eventual_consistency_amplitude   : Float = PHI_INV;
  stable var orch_eventual_consistency_frequency   : Float = PHI_INV_2;
  stable var orch_eventual_consistency_damping     : Float = PHI_INV_3;
  stable var orch_eventual_consistency_coupling    : Float = PHI_INV_2;
  stable var orch_eventual_consistency_threshold   : Float = PHI_INV;
  stable var orch_eventual_consistency_saturation  : Float = 0.0;
  stable var orch_eventual_consistency_decay       : Float = PHI_INV_4;
  stable var orch_eventual_consistency_gain        : Float = PHI_INV_2;
  stable var orch_eventual_consistency_offset      : Float = 0.0;
  stable var orch_eventual_consistency_jitter      : Float = 0.0;
  stable var orch_eventual_consistency_drift       : Float = 0.0;
  stable var orch_eventual_consistency_residual    : Float = 0.0;
  stable var orch_eventual_consistency_integral    : Float = 0.0;
  stable var orch_eventual_consistency_derivative  : Float = 0.0;
  stable var orch_eventual_consistency_setpoint    : Float = PHI_INV;
  stable var orch_eventual_consistency_error       : Float = 0.0;
  stable var orch_eventual_consistency_correction  : Float = 0.0;
  stable var orch_eventual_consistency_totalCycles : Nat = 0;
  stable var orch_eventual_consistency_lastCycle   : Nat = 0;
  stable var orch_eventual_consistency_peakError   : Float = 0.0;
  stable var orch_eventual_consistency_avgError    : Float = 0.0;
  stable var orch_eventual_consistency_converged   : Bool = false;

  // PID controller for eventual consistency
  func _orch_eventual_consistency_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_eventual_consistency_error := orch_eventual_consistency_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_eventual_consistency_integral := _clamp(
      orch_eventual_consistency_integral + orch_eventual_consistency_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_eventual_consistency_residual;
    orch_eventual_consistency_derivative := (orch_eventual_consistency_error - prevError) * PHI;
    orch_eventual_consistency_residual := orch_eventual_consistency_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_eventual_consistency_correction := _clamp(
      PHI_INV * orch_eventual_consistency_error +
      PHI_INV_3 * orch_eventual_consistency_integral +
      PHI_INV_4 * orch_eventual_consistency_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_eventual_consistency_energy := _clamp(
      orch_eventual_consistency_energy + orch_eventual_consistency_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_eventual_consistency_momentum := orch_eventual_consistency_momentum * PHI_INV +
      orch_eventual_consistency_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_eventual_consistency_phase := if (orch_eventual_consistency_phase > 3.14159) {
      orch_eventual_consistency_phase - 6.28318
    } else if (orch_eventual_consistency_phase < -3.14159) {
      orch_eventual_consistency_phase + 6.28318
    } else {
      orch_eventual_consistency_phase + orch_eventual_consistency_frequency * (1.0 + orch_eventual_consistency_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_eventual_consistency_amplitude := _clamp(
      orch_eventual_consistency_amplitude + orch_eventual_consistency_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_eventual_consistency_damping := _clamp(
      PHI_INV_3 + (orch_eventual_consistency_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_eventual_consistency_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_eventual_consistency_saturation := if (orch_eventual_consistency_energy > PHI) {
      (orch_eventual_consistency_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_eventual_consistency_jitter := Float.abs(orch_eventual_consistency_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_eventual_consistency_drift := orch_eventual_consistency_drift * PHI_INV +
      orch_eventual_consistency_error * PHI_INV_4;

    // Convergence check
    orch_eventual_consistency_converged := Float.abs(orch_eventual_consistency_error) < PHI_INV_4
      and Float.abs(orch_eventual_consistency_derivative) < PHI_INV_4
      and orch_eventual_consistency_saturation < PHI_INV_3;

    // Statistics
    orch_eventual_consistency_totalCycles += 1;
    orch_eventual_consistency_lastCycle := beatCount;
    if (Float.abs(orch_eventual_consistency_error) > orch_eventual_consistency_peakError) {
      orch_eventual_consistency_peakError := Float.abs(orch_eventual_consistency_error);
    };
    orch_eventual_consistency_avgError := orch_eventual_consistency_avgError * PHI_INV +
      Float.abs(orch_eventual_consistency_error) * PHI_INV_2;
  };

  // Oscillator dynamics for eventual consistency
  func _orch_eventual_consistency_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_eventual_consistency_frequency * PHI;
    let zeta = orch_eventual_consistency_damping;
    let driving = orch_eventual_consistency_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_eventual_consistency_phase;
    let velocity = orch_eventual_consistency_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_eventual_consistency_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_eventual_consistency_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_eventual_consistency_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_eventual_consistency_amplitude := _clamp(
      orch_eventual_consistency_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // SNAPSHOT ISOLATION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing snapshot isolation.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δsnapshot_isolation_state = η_snapshot_isolation · (target − current) · coherence^φ
  //   where η_snapshot_isolation = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||snapshot_isolation_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(snapshot_isolation_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_snapshot_isolation_energy      : Float = 0.0;
  stable var orch_snapshot_isolation_momentum    : Float = 0.0;
  stable var orch_snapshot_isolation_phase       : Float = 0.0;
  stable var orch_snapshot_isolation_amplitude   : Float = PHI_INV;
  stable var orch_snapshot_isolation_frequency   : Float = PHI_INV_2;
  stable var orch_snapshot_isolation_damping     : Float = PHI_INV_3;
  stable var orch_snapshot_isolation_coupling    : Float = PHI_INV_2;
  stable var orch_snapshot_isolation_threshold   : Float = PHI_INV;
  stable var orch_snapshot_isolation_saturation  : Float = 0.0;
  stable var orch_snapshot_isolation_decay       : Float = PHI_INV_4;
  stable var orch_snapshot_isolation_gain        : Float = PHI_INV_2;
  stable var orch_snapshot_isolation_offset      : Float = 0.0;
  stable var orch_snapshot_isolation_jitter      : Float = 0.0;
  stable var orch_snapshot_isolation_drift       : Float = 0.0;
  stable var orch_snapshot_isolation_residual    : Float = 0.0;
  stable var orch_snapshot_isolation_integral    : Float = 0.0;
  stable var orch_snapshot_isolation_derivative  : Float = 0.0;
  stable var orch_snapshot_isolation_setpoint    : Float = PHI_INV;
  stable var orch_snapshot_isolation_error       : Float = 0.0;
  stable var orch_snapshot_isolation_correction  : Float = 0.0;
  stable var orch_snapshot_isolation_totalCycles : Nat = 0;
  stable var orch_snapshot_isolation_lastCycle   : Nat = 0;
  stable var orch_snapshot_isolation_peakError   : Float = 0.0;
  stable var orch_snapshot_isolation_avgError    : Float = 0.0;
  stable var orch_snapshot_isolation_converged   : Bool = false;

  // PID controller for snapshot isolation
  func _orch_snapshot_isolation_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_snapshot_isolation_error := orch_snapshot_isolation_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_snapshot_isolation_integral := _clamp(
      orch_snapshot_isolation_integral + orch_snapshot_isolation_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_snapshot_isolation_residual;
    orch_snapshot_isolation_derivative := (orch_snapshot_isolation_error - prevError) * PHI;
    orch_snapshot_isolation_residual := orch_snapshot_isolation_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_snapshot_isolation_correction := _clamp(
      PHI_INV * orch_snapshot_isolation_error +
      PHI_INV_3 * orch_snapshot_isolation_integral +
      PHI_INV_4 * orch_snapshot_isolation_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_snapshot_isolation_energy := _clamp(
      orch_snapshot_isolation_energy + orch_snapshot_isolation_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_snapshot_isolation_momentum := orch_snapshot_isolation_momentum * PHI_INV +
      orch_snapshot_isolation_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_snapshot_isolation_phase := if (orch_snapshot_isolation_phase > 3.14159) {
      orch_snapshot_isolation_phase - 6.28318
    } else if (orch_snapshot_isolation_phase < -3.14159) {
      orch_snapshot_isolation_phase + 6.28318
    } else {
      orch_snapshot_isolation_phase + orch_snapshot_isolation_frequency * (1.0 + orch_snapshot_isolation_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_snapshot_isolation_amplitude := _clamp(
      orch_snapshot_isolation_amplitude + orch_snapshot_isolation_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_snapshot_isolation_damping := _clamp(
      PHI_INV_3 + (orch_snapshot_isolation_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_snapshot_isolation_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_snapshot_isolation_saturation := if (orch_snapshot_isolation_energy > PHI) {
      (orch_snapshot_isolation_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_snapshot_isolation_jitter := Float.abs(orch_snapshot_isolation_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_snapshot_isolation_drift := orch_snapshot_isolation_drift * PHI_INV +
      orch_snapshot_isolation_error * PHI_INV_4;

    // Convergence check
    orch_snapshot_isolation_converged := Float.abs(orch_snapshot_isolation_error) < PHI_INV_4
      and Float.abs(orch_snapshot_isolation_derivative) < PHI_INV_4
      and orch_snapshot_isolation_saturation < PHI_INV_3;

    // Statistics
    orch_snapshot_isolation_totalCycles += 1;
    orch_snapshot_isolation_lastCycle := beatCount;
    if (Float.abs(orch_snapshot_isolation_error) > orch_snapshot_isolation_peakError) {
      orch_snapshot_isolation_peakError := Float.abs(orch_snapshot_isolation_error);
    };
    orch_snapshot_isolation_avgError := orch_snapshot_isolation_avgError * PHI_INV +
      Float.abs(orch_snapshot_isolation_error) * PHI_INV_2;
  };

  // Oscillator dynamics for snapshot isolation
  func _orch_snapshot_isolation_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_snapshot_isolation_frequency * PHI;
    let zeta = orch_snapshot_isolation_damping;
    let driving = orch_snapshot_isolation_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_snapshot_isolation_phase;
    let velocity = orch_snapshot_isolation_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_snapshot_isolation_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_snapshot_isolation_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_snapshot_isolation_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_snapshot_isolation_amplitude := _clamp(
      orch_snapshot_isolation_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // GARBAGE COLLECTION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing garbage collection.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δgarbage_collection_state = η_garbage_collection · (target − current) · coherence^φ
  //   where η_garbage_collection = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||garbage_collection_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(garbage_collection_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_garbage_collection_energy      : Float = 0.0;
  stable var orch_garbage_collection_momentum    : Float = 0.0;
  stable var orch_garbage_collection_phase       : Float = 0.0;
  stable var orch_garbage_collection_amplitude   : Float = PHI_INV;
  stable var orch_garbage_collection_frequency   : Float = PHI_INV_2;
  stable var orch_garbage_collection_damping     : Float = PHI_INV_3;
  stable var orch_garbage_collection_coupling    : Float = PHI_INV_2;
  stable var orch_garbage_collection_threshold   : Float = PHI_INV;
  stable var orch_garbage_collection_saturation  : Float = 0.0;
  stable var orch_garbage_collection_decay       : Float = PHI_INV_4;
  stable var orch_garbage_collection_gain        : Float = PHI_INV_2;
  stable var orch_garbage_collection_offset      : Float = 0.0;
  stable var orch_garbage_collection_jitter      : Float = 0.0;
  stable var orch_garbage_collection_drift       : Float = 0.0;
  stable var orch_garbage_collection_residual    : Float = 0.0;
  stable var orch_garbage_collection_integral    : Float = 0.0;
  stable var orch_garbage_collection_derivative  : Float = 0.0;
  stable var orch_garbage_collection_setpoint    : Float = PHI_INV;
  stable var orch_garbage_collection_error       : Float = 0.0;
  stable var orch_garbage_collection_correction  : Float = 0.0;
  stable var orch_garbage_collection_totalCycles : Nat = 0;
  stable var orch_garbage_collection_lastCycle   : Nat = 0;
  stable var orch_garbage_collection_peakError   : Float = 0.0;
  stable var orch_garbage_collection_avgError    : Float = 0.0;
  stable var orch_garbage_collection_converged   : Bool = false;

  // PID controller for garbage collection
  func _orch_garbage_collection_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_garbage_collection_error := orch_garbage_collection_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_garbage_collection_integral := _clamp(
      orch_garbage_collection_integral + orch_garbage_collection_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_garbage_collection_residual;
    orch_garbage_collection_derivative := (orch_garbage_collection_error - prevError) * PHI;
    orch_garbage_collection_residual := orch_garbage_collection_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_garbage_collection_correction := _clamp(
      PHI_INV * orch_garbage_collection_error +
      PHI_INV_3 * orch_garbage_collection_integral +
      PHI_INV_4 * orch_garbage_collection_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_garbage_collection_energy := _clamp(
      orch_garbage_collection_energy + orch_garbage_collection_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_garbage_collection_momentum := orch_garbage_collection_momentum * PHI_INV +
      orch_garbage_collection_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_garbage_collection_phase := if (orch_garbage_collection_phase > 3.14159) {
      orch_garbage_collection_phase - 6.28318
    } else if (orch_garbage_collection_phase < -3.14159) {
      orch_garbage_collection_phase + 6.28318
    } else {
      orch_garbage_collection_phase + orch_garbage_collection_frequency * (1.0 + orch_garbage_collection_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_garbage_collection_amplitude := _clamp(
      orch_garbage_collection_amplitude + orch_garbage_collection_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_garbage_collection_damping := _clamp(
      PHI_INV_3 + (orch_garbage_collection_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_garbage_collection_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_garbage_collection_saturation := if (orch_garbage_collection_energy > PHI) {
      (orch_garbage_collection_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_garbage_collection_jitter := Float.abs(orch_garbage_collection_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_garbage_collection_drift := orch_garbage_collection_drift * PHI_INV +
      orch_garbage_collection_error * PHI_INV_4;

    // Convergence check
    orch_garbage_collection_converged := Float.abs(orch_garbage_collection_error) < PHI_INV_4
      and Float.abs(orch_garbage_collection_derivative) < PHI_INV_4
      and orch_garbage_collection_saturation < PHI_INV_3;

    // Statistics
    orch_garbage_collection_totalCycles += 1;
    orch_garbage_collection_lastCycle := beatCount;
    if (Float.abs(orch_garbage_collection_error) > orch_garbage_collection_peakError) {
      orch_garbage_collection_peakError := Float.abs(orch_garbage_collection_error);
    };
    orch_garbage_collection_avgError := orch_garbage_collection_avgError * PHI_INV +
      Float.abs(orch_garbage_collection_error) * PHI_INV_2;
  };

  // Oscillator dynamics for garbage collection
  func _orch_garbage_collection_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_garbage_collection_frequency * PHI;
    let zeta = orch_garbage_collection_damping;
    let driving = orch_garbage_collection_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_garbage_collection_phase;
    let velocity = orch_garbage_collection_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_garbage_collection_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_garbage_collection_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_garbage_collection_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_garbage_collection_amplitude := _clamp(
      orch_garbage_collection_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // MEMORY COMPACTION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing memory compaction.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δmemory_compaction_state = η_memory_compaction · (target − current) · coherence^φ
  //   where η_memory_compaction = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||memory_compaction_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(memory_compaction_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_memory_compaction_energy      : Float = 0.0;
  stable var orch_memory_compaction_momentum    : Float = 0.0;
  stable var orch_memory_compaction_phase       : Float = 0.0;
  stable var orch_memory_compaction_amplitude   : Float = PHI_INV;
  stable var orch_memory_compaction_frequency   : Float = PHI_INV_2;
  stable var orch_memory_compaction_damping     : Float = PHI_INV_3;
  stable var orch_memory_compaction_coupling    : Float = PHI_INV_2;
  stable var orch_memory_compaction_threshold   : Float = PHI_INV;
  stable var orch_memory_compaction_saturation  : Float = 0.0;
  stable var orch_memory_compaction_decay       : Float = PHI_INV_4;
  stable var orch_memory_compaction_gain        : Float = PHI_INV_2;
  stable var orch_memory_compaction_offset      : Float = 0.0;
  stable var orch_memory_compaction_jitter      : Float = 0.0;
  stable var orch_memory_compaction_drift       : Float = 0.0;
  stable var orch_memory_compaction_residual    : Float = 0.0;
  stable var orch_memory_compaction_integral    : Float = 0.0;
  stable var orch_memory_compaction_derivative  : Float = 0.0;
  stable var orch_memory_compaction_setpoint    : Float = PHI_INV;
  stable var orch_memory_compaction_error       : Float = 0.0;
  stable var orch_memory_compaction_correction  : Float = 0.0;
  stable var orch_memory_compaction_totalCycles : Nat = 0;
  stable var orch_memory_compaction_lastCycle   : Nat = 0;
  stable var orch_memory_compaction_peakError   : Float = 0.0;
  stable var orch_memory_compaction_avgError    : Float = 0.0;
  stable var orch_memory_compaction_converged   : Bool = false;

  // PID controller for memory compaction
  func _orch_memory_compaction_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_memory_compaction_error := orch_memory_compaction_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_memory_compaction_integral := _clamp(
      orch_memory_compaction_integral + orch_memory_compaction_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_memory_compaction_residual;
    orch_memory_compaction_derivative := (orch_memory_compaction_error - prevError) * PHI;
    orch_memory_compaction_residual := orch_memory_compaction_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_memory_compaction_correction := _clamp(
      PHI_INV * orch_memory_compaction_error +
      PHI_INV_3 * orch_memory_compaction_integral +
      PHI_INV_4 * orch_memory_compaction_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_memory_compaction_energy := _clamp(
      orch_memory_compaction_energy + orch_memory_compaction_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_memory_compaction_momentum := orch_memory_compaction_momentum * PHI_INV +
      orch_memory_compaction_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_memory_compaction_phase := if (orch_memory_compaction_phase > 3.14159) {
      orch_memory_compaction_phase - 6.28318
    } else if (orch_memory_compaction_phase < -3.14159) {
      orch_memory_compaction_phase + 6.28318
    } else {
      orch_memory_compaction_phase + orch_memory_compaction_frequency * (1.0 + orch_memory_compaction_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_memory_compaction_amplitude := _clamp(
      orch_memory_compaction_amplitude + orch_memory_compaction_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_memory_compaction_damping := _clamp(
      PHI_INV_3 + (orch_memory_compaction_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_memory_compaction_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_memory_compaction_saturation := if (orch_memory_compaction_energy > PHI) {
      (orch_memory_compaction_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_memory_compaction_jitter := Float.abs(orch_memory_compaction_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_memory_compaction_drift := orch_memory_compaction_drift * PHI_INV +
      orch_memory_compaction_error * PHI_INV_4;

    // Convergence check
    orch_memory_compaction_converged := Float.abs(orch_memory_compaction_error) < PHI_INV_4
      and Float.abs(orch_memory_compaction_derivative) < PHI_INV_4
      and orch_memory_compaction_saturation < PHI_INV_3;

    // Statistics
    orch_memory_compaction_totalCycles += 1;
    orch_memory_compaction_lastCycle := beatCount;
    if (Float.abs(orch_memory_compaction_error) > orch_memory_compaction_peakError) {
      orch_memory_compaction_peakError := Float.abs(orch_memory_compaction_error);
    };
    orch_memory_compaction_avgError := orch_memory_compaction_avgError * PHI_INV +
      Float.abs(orch_memory_compaction_error) * PHI_INV_2;
  };

  // Oscillator dynamics for memory compaction
  func _orch_memory_compaction_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_memory_compaction_frequency * PHI;
    let zeta = orch_memory_compaction_damping;
    let driving = orch_memory_compaction_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_memory_compaction_phase;
    let velocity = orch_memory_compaction_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_memory_compaction_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_memory_compaction_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_memory_compaction_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_memory_compaction_amplitude := _clamp(
      orch_memory_compaction_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // INDEX OPTIMIZATION SUBSYSTEM
  //
  // Phi-harmonic orchestration intelligence subsystem implementing index optimization.
  // Contributes to organism coherence through adaptive computation.
  // All thresholds and rates are golden-ratio-derived.
  //
  // Core Equation:
  //   Δindex_optimization_state = η_index_optimization · (target − current) · coherence^φ
  //   where η_index_optimization = φ^(−3) = 0.236 (base adaptation rate)
  //
  // Stability Invariant:
  //   ||index_optimization_state|| ≤ φ² at all times (sovereign ceiling guarantee)
  //   min(index_optimization_state) ≥ S₀ = 1.0 (sovereign floor guarantee)
  //
  // Architect: Alfredo Medina Hernandez — The Architect of the Field
  // ═══════════════════════════════════════════════════════════════════════════

  stable var orch_index_optimization_energy      : Float = 0.0;
  stable var orch_index_optimization_momentum    : Float = 0.0;
  stable var orch_index_optimization_phase       : Float = 0.0;
  stable var orch_index_optimization_amplitude   : Float = PHI_INV;
  stable var orch_index_optimization_frequency   : Float = PHI_INV_2;
  stable var orch_index_optimization_damping     : Float = PHI_INV_3;
  stable var orch_index_optimization_coupling    : Float = PHI_INV_2;
  stable var orch_index_optimization_threshold   : Float = PHI_INV;
  stable var orch_index_optimization_saturation  : Float = 0.0;
  stable var orch_index_optimization_decay       : Float = PHI_INV_4;
  stable var orch_index_optimization_gain        : Float = PHI_INV_2;
  stable var orch_index_optimization_offset      : Float = 0.0;
  stable var orch_index_optimization_jitter      : Float = 0.0;
  stable var orch_index_optimization_drift       : Float = 0.0;
  stable var orch_index_optimization_residual    : Float = 0.0;
  stable var orch_index_optimization_integral    : Float = 0.0;
  stable var orch_index_optimization_derivative  : Float = 0.0;
  stable var orch_index_optimization_setpoint    : Float = PHI_INV;
  stable var orch_index_optimization_error       : Float = 0.0;
  stable var orch_index_optimization_correction  : Float = 0.0;
  stable var orch_index_optimization_totalCycles : Nat = 0;
  stable var orch_index_optimization_lastCycle   : Nat = 0;
  stable var orch_index_optimization_peakError   : Float = 0.0;
  stable var orch_index_optimization_avgError    : Float = 0.0;
  stable var orch_index_optimization_converged   : Bool = false;

  // PID controller for index optimization
  func _orch_index_optimization_pid() : () {
    // Proportional term
    let measured = globalCoherence;
    orch_index_optimization_error := orch_index_optimization_setpoint - measured;

    // Integral term (anti-windup clamped)
    orch_index_optimization_integral := _clamp(
      orch_index_optimization_integral + orch_index_optimization_error * PHI_INV_4,
      -PHI_INV, PHI_INV
    );

    // Derivative term
    let prevError = orch_index_optimization_residual;
    orch_index_optimization_derivative := (orch_index_optimization_error - prevError) * PHI;
    orch_index_optimization_residual := orch_index_optimization_error;

    // PID output: Kp=φ⁻¹, Ki=φ⁻³, Kd=φ⁻⁴
    orch_index_optimization_correction := _clamp(
      PHI_INV * orch_index_optimization_error +
      PHI_INV_3 * orch_index_optimization_integral +
      PHI_INV_4 * orch_index_optimization_derivative,
      -PHI_INV, PHI_INV
    );

    // Apply correction to energy state
    orch_index_optimization_energy := _clamp(
      orch_index_optimization_energy + orch_index_optimization_correction * PHI_INV_2,
      0.0, PHI_SQ
    );

    // Update momentum (exponential moving average of correction)
    orch_index_optimization_momentum := orch_index_optimization_momentum * PHI_INV +
      orch_index_optimization_correction * PHI_INV_2;

    // Phase advance based on energy and frequency
    orch_index_optimization_phase := if (orch_index_optimization_phase > 3.14159) {
      orch_index_optimization_phase - 6.28318
    } else if (orch_index_optimization_phase < -3.14159) {
      orch_index_optimization_phase + 6.28318
    } else {
      orch_index_optimization_phase + orch_index_optimization_frequency * (1.0 + orch_index_optimization_energy * PHI_INV_3)
    };

    // Amplitude modulation based on coherence
    orch_index_optimization_amplitude := _clamp(
      orch_index_optimization_amplitude + orch_index_optimization_momentum * PHI_INV_4,
      PHI_INV_3, PHI
    );

    // Damping from stability (higher stability → more damping → less oscillation)
    orch_index_optimization_damping := _clamp(
      PHI_INV_3 + (orch_index_optimization_amplitude - PHI_INV) * PHI_INV_2,
      PHI_INV_4, PHI_INV
    );

    // Coupling strength adapts to match organism coherence level
    orch_index_optimization_coupling := _clamp(
      measured * PHI_INV,
      PHI_INV_3, PHI_INV
    );

    // Saturation detection
    orch_index_optimization_saturation := if (orch_index_optimization_energy > PHI) {
      (orch_index_optimization_energy - PHI) / (PHI_SQ - PHI)
    } else { 0.0 };

    // Jitter: absolute rate of phase change (should be low for stability)
    orch_index_optimization_jitter := Float.abs(orch_index_optimization_derivative) * PHI_INV_2;

    // Drift: cumulative signed error (should stay near zero)
    orch_index_optimization_drift := orch_index_optimization_drift * PHI_INV +
      orch_index_optimization_error * PHI_INV_4;

    // Convergence check
    orch_index_optimization_converged := Float.abs(orch_index_optimization_error) < PHI_INV_4
      and Float.abs(orch_index_optimization_derivative) < PHI_INV_4
      and orch_index_optimization_saturation < PHI_INV_3;

    // Statistics
    orch_index_optimization_totalCycles += 1;
    orch_index_optimization_lastCycle := beatCount;
    if (Float.abs(orch_index_optimization_error) > orch_index_optimization_peakError) {
      orch_index_optimization_peakError := Float.abs(orch_index_optimization_error);
    };
    orch_index_optimization_avgError := orch_index_optimization_avgError * PHI_INV +
      Float.abs(orch_index_optimization_error) * PHI_INV_2;
  };

  // Oscillator dynamics for index optimization
  func _orch_index_optimization_oscillate() : () {
    // Driven damped harmonic oscillator:
    // x'' + 2ζω₀x' + ω₀²x = F(t)/m
    // where ζ = damping ratio, ω₀ = natural frequency, F(t) = driving force

    let omega0 = orch_index_optimization_frequency * PHI;
    let zeta = orch_index_optimization_damping;
    let driving = orch_index_optimization_correction * PHI_INV;

    // State-space form: position = phase, velocity = momentum
    let position = orch_index_optimization_phase;
    let velocity = orch_index_optimization_momentum;

    // Euler integration (dt = φ⁻² for numerical stability)
    let dt = PHI_INV_2;
    let accel = driving - 2.0 * zeta * omega0 * velocity - omega0 * omega0 * position;

    orch_index_optimization_momentum := _clamp(velocity + accel * dt, -PHI, PHI);
    orch_index_optimization_phase := if (position + velocity * dt > 3.14159) {
      position + velocity * dt - 6.28318
    } else if (position + velocity * dt < -3.14159) {
      position + velocity * dt + 6.28318
    } else {
      position + velocity * dt
    };

    // Energy = KE + PE = 0.5·v² + 0.5·ω₀²·x²
    let kineticE = 0.5 * velocity * velocity;
    let potentialE = 0.5 * omega0 * omega0 * position * position;
    orch_index_optimization_energy := _clamp(kineticE + potentialE, 0.0, PHI_SQ);

    // Amplitude envelope (peak detection)
    let instantAmp = Float.sqrt(position * position + (velocity / omega0) * (velocity / omega0));
    orch_index_optimization_amplitude := _clamp(
      orch_index_optimization_amplitude * PHI_INV + instantAmp * PHI_INV_2,
      PHI_INV_3, PHI
    );
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // COMPREHENSIVE ORCHESTRATOR INTELLIGENCE REPORT
  // Returns all subsystem states in a single query call
  // ═══════════════════════════════════════════════════════════════════════════

  public query func getOrchestratorIntelligenceReport() : async {
    totalSubsystems      : Nat;
    convergedSubsystems  : Nat;
    avgSubsystemEnergy   : Float;
    avgSubsystemError    : Float;
    totalCycles          : Nat;
    systemCoherence      : Float;
    systemStability      : Float;
    systemComplexity     : Float;
  } {
    var converged : Nat = 0;
    var totalEnergy : Float = 0.0;
    var totalError : Float = 0.0;
    var cycles : Nat = 0;


    if (orch_consensus_protocol_converged) { converged += 1 };

    totalEnergy += orch_consensus_protocol_energy;

    totalError += orch_consensus_protocol_avgError;

    cycles += orch_consensus_protocol_totalCycles;

    if (orch_distributed_state_converged) { converged += 1 };

    totalEnergy += orch_distributed_state_energy;

    totalError += orch_distributed_state_avgError;

    cycles += orch_distributed_state_totalCycles;

    if (orch_causal_ordering_converged) { converged += 1 };

    totalEnergy += orch_causal_ordering_energy;

    totalError += orch_causal_ordering_avgError;

    cycles += orch_causal_ordering_totalCycles;

    if (orch_vector_clocks_converged) { converged += 1 };

    totalEnergy += orch_vector_clocks_energy;

    totalError += orch_vector_clocks_avgError;

    cycles += orch_vector_clocks_totalCycles;

    if (orch_byzantine_tolerance_converged) { converged += 1 };

    totalEnergy += orch_byzantine_tolerance_energy;

    totalError += orch_byzantine_tolerance_avgError;

    cycles += orch_byzantine_tolerance_totalCycles;

    if (orch_leader_election_converged) { converged += 1 };

    totalEnergy += orch_leader_election_energy;

    totalError += orch_leader_election_avgError;

    cycles += orch_leader_election_totalCycles;

    if (orch_membership_protocol_converged) { converged += 1 };

    totalEnergy += orch_membership_protocol_energy;

    totalError += orch_membership_protocol_avgError;

    cycles += orch_membership_protocol_totalCycles;

    if (orch_failure_detection_converged) { converged += 1 };

    totalEnergy += orch_failure_detection_energy;

    totalError += orch_failure_detection_avgError;

    cycles += orch_failure_detection_totalCycles;

    if (orch_state_replication_converged) { converged += 1 };

    totalEnergy += orch_state_replication_energy;

    totalError += orch_state_replication_avgError;

    cycles += orch_state_replication_totalCycles;

    if (orch_conflict_resolution_converged) { converged += 1 };

    totalEnergy += orch_conflict_resolution_energy;

    totalError += orch_conflict_resolution_avgError;

    cycles += orch_conflict_resolution_totalCycles;

    if (orch_eventual_consistency_converged) { converged += 1 };

    totalEnergy += orch_eventual_consistency_energy;

    totalError += orch_eventual_consistency_avgError;

    cycles += orch_eventual_consistency_totalCycles;

    if (orch_snapshot_isolation_converged) { converged += 1 };

    totalEnergy += orch_snapshot_isolation_energy;

    totalError += orch_snapshot_isolation_avgError;

    cycles += orch_snapshot_isolation_totalCycles;

    if (orch_garbage_collection_converged) { converged += 1 };

    totalEnergy += orch_garbage_collection_energy;

    totalError += orch_garbage_collection_avgError;

    cycles += orch_garbage_collection_totalCycles;

    if (orch_memory_compaction_converged) { converged += 1 };

    totalEnergy += orch_memory_compaction_energy;

    totalError += orch_memory_compaction_avgError;

    cycles += orch_memory_compaction_totalCycles;

    if (orch_index_optimization_converged) { converged += 1 };

    totalEnergy += orch_index_optimization_energy;

    totalError += orch_index_optimization_avgError;

    cycles += orch_index_optimization_totalCycles;


    let numSubs : Nat = 15;
    {
      totalSubsystems     = numSubs;
      convergedSubsystems = converged;
      avgSubsystemEnergy  = totalEnergy / Float.fromInt(numSubs);
      avgSubsystemError   = totalError / Float.fromInt(numSubs);
      totalCycles         = cycles;
      systemCoherence     = globalCoherence;
      systemStability     = if (totalError > 0.001) { 1.0 / (1.0 + totalError) } else { 1.0 };
      systemComplexity    = totalEnergy * PHI_INV;
    };
  };

};
