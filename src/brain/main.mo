// =============================================================================
// BRAIN — PARALLAX Cognitive Substrate  (v2 — expanded math)
// TIER 2: Master cognitive canister. Imports 6 local modules.
// Runs the 25-step sovereign heartbeat every 2 seconds.
// All stateful values are stable vars — persisted across upgrades.
// All write functions require creator principal assertion.
// =============================================================================

import Time      "mo:base/Time";
import Float     "mo:base/Float";
import Nat       "mo:base/Nat";
import Int       "mo:base/Int";
import Text      "mo:base/Text";
import Bool      "mo:base/Bool";
import Array     "mo:base/Array";
import Principal "mo:base/Principal";
import Timer     "mo:base/Timer";

import Shells     "./shells";
import Organs     "./organs";
import Metals     "./metals";
import NeuroChem  "./neuro_chem";
import QuantumOps "./quantum_ops";
import Animals    "./animals";

actor Brain {

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  let S0              : Float = 1.0;
  let HEARTBEAT_NS    : Nat   = 2_000_000_000;
  let SHELL_COUNT     : Nat   = 11;
  let MAX_NODES       : Nat   = 36;
  let NEURO_SIZE      : Nat   = 21;
  let ORGAN_COUNT     : Nat   = 18;
  let AUDIT_RING_SIZE : Nat   = 1000;
  let FORMA_GENESIS   : Float = 1000.0;

  // ===========================================================================
  // SECURITY
  // ===========================================================================

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

  // ===========================================================================
  // EXTERNAL CANISTER IDs
  // ===========================================================================

  stable var chronoCanisterId   : ?Text = null;
  stable var veritasCanisterId  : ?Text = null;
  stable var fluxCanisterId     : ?Text = null;
  stable var resonexCanisterId  : ?Text = null;
  stable var axisCanisterId     : ?Text = null;
  stable var aegisCanisterId    : ?Text = null;
  stable var entanglaCanisterId : ?Text = null;
  stable var walletCanisterId   : ?Text = null;
  stable var novaCanisterId     : ?Text = null;
  stable var meridianCanisterId : ?Text = null;

  public shared(msg) func setCanisterId(name : Text, id : Text) : async () {
    assertCreator(msg.caller);
    switch (name) {
      case ("chrono")      { chronoCanisterId      := ?id; };
      case ("veritas")     { veritasCanisterId     := ?id; };
      case ("flux")        { fluxCanisterId        := ?id; };
      case ("resonex")     { resonexCanisterId     := ?id; };
      case ("axis")        { axisCanisterId        := ?id; };
      case ("aegis")       { aegisCanisterId       := ?id; };
      case ("entangla")    { entanglaCanisterId    := ?id; };
      case ("wallet")      { walletCanisterId      := ?id; };
      case ("nova")        { novaCanisterId        := ?id; };
      case ("meridian")    { meridianCanisterId    := ?id; };
      case (_)             { /* ignore */ };
    };
  };

  // ===========================================================================
  // STABLE STATE — BEAT
  // ===========================================================================

  stable var beatCount        : Nat   = 0;
  stable var lastBeatTime     : Int   = 0;
  stable var heartbeatActive  : Bool  = false;
  stable var totalBeats       : Nat   = 0;

  // ===========================================================================
  // STABLE STATE — NEURAL SHELLS
  // Weights: 11 shells * 36*36 = 14,256 values each
  // Activations: 11 * 36
  // Phases (Kuramoto): 11 * 36
  // ===========================================================================

  stable var shellWeights_0  : [var Float] = Shells.init_weights();
  stable var shellWeights_1  : [var Float] = Shells.init_weights();
  stable var shellWeights_2  : [var Float] = Shells.init_weights();
  stable var shellWeights_3  : [var Float] = Shells.init_weights();
  stable var shellWeights_4  : [var Float] = Shells.init_weights();
  stable var shellWeights_5  : [var Float] = Shells.init_weights();
  stable var shellWeights_6  : [var Float] = Shells.init_weights();
  stable var shellWeights_7  : [var Float] = Shells.init_weights();
  stable var shellWeights_8  : [var Float] = Shells.init_weights();
  stable var shellWeights_9  : [var Float] = Shells.init_weights();
  stable var shellWeights_10 : [var Float] = Shells.init_weights();

  stable var shellActs_0  : [var Float] = Shells.init_activations();
  stable var shellActs_1  : [var Float] = Shells.init_activations();
  stable var shellActs_2  : [var Float] = Shells.init_activations();
  stable var shellActs_3  : [var Float] = Shells.init_activations();
  stable var shellActs_4  : [var Float] = Shells.init_activations();
  stable var shellActs_5  : [var Float] = Shells.init_activations();
  stable var shellActs_6  : [var Float] = Shells.init_activations();
  stable var shellActs_7  : [var Float] = Shells.init_activations();
  stable var shellActs_8  : [var Float] = Shells.init_activations();
  stable var shellActs_9  : [var Float] = Shells.init_activations();
  stable var shellActs_10 : [var Float] = Shells.init_activations();

  stable var shellPhases_0  : [var Float] = Shells.init_phases();
  stable var shellPhases_1  : [var Float] = Shells.init_phases();
  stable var shellPhases_2  : [var Float] = Shells.init_phases();
  stable var shellPhases_3  : [var Float] = Shells.init_phases();
  stable var shellPhases_4  : [var Float] = Shells.init_phases();
  stable var shellPhases_5  : [var Float] = Shells.init_phases();
  stable var shellPhases_6  : [var Float] = Shells.init_phases();
  stable var shellPhases_7  : [var Float] = Shells.init_phases();
  stable var shellPhases_8  : [var Float] = Shells.init_phases();
  stable var shellPhases_9  : [var Float] = Shells.init_phases();
  stable var shellPhases_10 : [var Float] = Shells.init_phases();

  stable var kuramotoR   : [var Float] = Array.init<Float>(SHELL_COUNT, 0.0);
  stable var meanActs    : [var Float] = Array.init<Float>(SHELL_COUNT, S0);
  stable var spectralCoh : [var Float] = Shells.init_spectral_coh();

  stable var globalCoherence     : Float = S0;
  stable var prevGlobalCoherence : Float = S0;

  // ===========================================================================
  // STABLE STATE — NEUROCHEMICALS
  // ===========================================================================

  stable var neuroLevels     : [var Float] = NeuroChem.init_levels();
  stable var neuroDecayRates : [var Float] = NeuroChem.init_decay();

  // ===========================================================================
  // STABLE STATE — ORGANS (with Hopf oscillators + velocity)
  // ===========================================================================

  stable var organSignals      : [var Float] = Array.init<Float>(ORGAN_COUNT, S0);
  stable var metalSignals      : [var Float] = Array.init<Float>(ORGAN_COUNT, S0);
  stable var prevOrganSignals  : [var Float] = Array.init<Float>(ORGAN_COUNT, S0);
  stable var organVelocities   : [var Float] = Organs.init_velocities();
  stable var hopfX             : [var Float] = Organs.init_hopf_x();
  stable var hopfY             : [var Float] = Organs.init_hopf_y();

  // Welford online stats for CROW z-score
  stable var organMean  : [var Float] = Animals.init_organ_mean();
  stable var organM2    : [var Float] = Array.init<Float>(ORGAN_COUNT, 0.01);

  // ===========================================================================
  // STABLE STATE — QUANTUM OPS
  // ===========================================================================

  stable var qmemRing        : [var Float] = QuantumOps.init_qmem_ring();
  stable var parallaxAngle   : Float = 0.0;
  stable var entanglaIndex   : Float = S0;
  stable var bypassActive    : Bool  = false;
  stable var bypassOutput    : Float = S0;
  stable var resonexField    : Float = S0;
  stable var qmemCoherence   : Float = S0;
  stable var vnEntropy       : Float = 0.0;
  stable var temporalDilation : Float = S0;
  stable var veritasCoh      : Float = S0;
  stable var entanglaEntropy : Float = 0.0;

  // ===========================================================================
  // STABLE STATE — ANIMALS
  // ===========================================================================

  stable var crowOutput     : Float = S0;
  stable var dolphinOutput  : Float = S0;
  stable var hiveOutput     : Float = S0;
  stable var elephantOutput : Float = S0;
  stable var sharkOutput    : Float = S0;
  stable var wolfOutput     : Float = S0;
  stable var orcaOutput     : Float = S0;
  stable var eagleOutput    : Float = S0;
  stable var octopusOutput  : Float = S0;
  stable var adaptRate      : Float = 0.0;

  // Previous EMA21 for Eagle momentum
  stable var prevEma21 : [var Float] = Array.init<Float>(4, S0);

  // ===========================================================================
  // STABLE STATE — MARKET
  // ===========================================================================

  stable var btcPrice     : Float = S0;
  stable var ethPrice     : Float = S0;
  stable var solPrice     : Float = S0;
  stable var icpPrice     : Float = S0;
  stable var btcEma21     : Float = S0;
  stable var btcEma55     : Float = S0;
  stable var btcEma200    : Float = S0;
  stable var ethEma21     : Float = S0;
  stable var ethEma55     : Float = S0;
  stable var ethEma200    : Float = S0;
  stable var solEma21     : Float = S0;
  stable var solEma55     : Float = S0;
  stable var solEma200    : Float = S0;
  stable var icpEma21     : Float = S0;
  stable var icpEma55     : Float = S0;
  stable var icpEma200    : Float = S0;
  stable var defiYield    : Float = 0.0;
  stable var arbSignal    : Float = 0.0;
  stable var regimeClarity : Float = S0;
  stable var regimeCode   : Nat = 0;  // 0=BULL,1=BEAR,2=SIDEWAYS,3=CRISIS,4=RECOVERY
  stable var novaChildCount : Nat = 0;

  // ===========================================================================
  // STABLE STATE — EPISODIC MEMORY (for ELEPHANT engine)
  // ===========================================================================

  stable var bestEpisodeCoherence : Float = S0;
  stable var bestEpisodeForma     : Float = FORMA_GENESIS;
  stable var bestEpisodeDrive     : Float = 0.0;
  stable var bestEpisodeRegime    : Float = 0.0;

  // ===========================================================================
  // STABLE STATE — COMPLIANCE (from VERITAS)
  // ===========================================================================

  stable var complianceVec  : [Float] = Array.tabulate<Float>(60, func(_) { S0 });
  stable var complianceMean : Float = S0;
  stable var jacobsRung     : Nat = 1;

  // ===========================================================================
  // STABLE STATE — AUDIT RING
  // ===========================================================================

  stable var auditLog   : [var Text] = Array.init<Text>(AUDIT_RING_SIZE, "");
  stable var auditHead  : Nat = 0;
  stable var auditCount : Nat = 0;

  func writeAudit(entry : Text) : () {
    auditLog[auditHead % AUDIT_RING_SIZE] := entry;
    auditHead += 1;
    if (auditCount < AUDIT_RING_SIZE) { auditCount += 1; };
  };

  // ===========================================================================
  // SHELL DISPATCH HELPERS
  // ===========================================================================

  func getShellWeights(s : Nat) : [var Float] {
    switch (s) {
      case 0  { shellWeights_0  }; case 1  { shellWeights_1  };
      case 2  { shellWeights_2  }; case 3  { shellWeights_3  };
      case 4  { shellWeights_4  }; case 5  { shellWeights_5  };
      case 6  { shellWeights_6  }; case 7  { shellWeights_7  };
      case 8  { shellWeights_8  }; case 9  { shellWeights_9  };
      case 10 { shellWeights_10 };
      case _  { shellWeights_0  };
    }
  };

  func getShellActs(s : Nat) : [var Float] {
    switch (s) {
      case 0  { shellActs_0  }; case 1  { shellActs_1  };
      case 2  { shellActs_2  }; case 3  { shellActs_3  };
      case 4  { shellActs_4  }; case 5  { shellActs_5  };
      case 6  { shellActs_6  }; case 7  { shellActs_7  };
      case 8  { shellActs_8  }; case 9  { shellActs_9  };
      case 10 { shellActs_10 };
      case _  { shellActs_0  };
    }
  };

  func getShellPhases(s : Nat) : [var Float] {
    switch (s) {
      case 0  { shellPhases_0  }; case 1  { shellPhases_1  };
      case 2  { shellPhases_2  }; case 3  { shellPhases_3  };
      case 4  { shellPhases_4  }; case 5  { shellPhases_5  };
      case 6  { shellPhases_6  }; case 7  { shellPhases_7  };
      case 8  { shellPhases_8  }; case 9  { shellPhases_9  };
      case 10 { shellPhases_10 };
      case _  { shellPhases_0  };
    }
  };

  func buildFlatActivations() : [Float] {
    let buf = Array.init<Float>(SHELL_COUNT * MAX_NODES, S0);
    var s = 0;
    while (s < SHELL_COUNT) {
      let acts = getShellActs(s);
      var i = 0;
      while (i < MAX_NODES) {
        buf[s * MAX_NODES + i] := acts[i];
        i += 1;
      };
      s += 1;
    };
    Array.freeze(buf)
  };

  // ===========================================================================
  // EXTERNAL CANISTER INTERFACES
  // ===========================================================================

  type ChronoActor = actor {
    tick            : () -> async Nat;
    getState        : query () -> async { beat: Nat; age: Float; dilation: Float; sealed: Bool };
  };

  type VeritasActor = actor {
    getComplianceVectorPublic : query () -> async [Float];
  };

  // ===========================================================================
  // 25-STEP SOVEREIGN HEARTBEAT
  // ===========================================================================

  func heartbeat() : async () {
    let startTime = Time.now();
    beatCount += 1;
    totalBeats += 1;

    // -----------------------------------------------------------------------
    // STEP 1: CHRONO tick
    // -----------------------------------------------------------------------
    switch (chronoCanisterId) {
      case (?cid) {
        try {
          let chrono = actor(cid) : ChronoActor;
          let state = await chrono.getState();
          temporalDilation := if (state.dilation < S0) S0 else state.dilation;
          ignore await chrono.tick();
        } catch (_) {
          temporalDilation := 1.0 + Float.log(1.0 + Float.fromInt(beatCount) / 10000.0);
          if (temporalDilation < S0) { temporalDilation := S0; };
        };
      };
      case null {
        temporalDilation := 1.0 + Float.log(1.0 + Float.fromInt(beatCount) / 10000.0);
        if (temporalDilation < S0) { temporalDilation := S0; };
      };
    };

    // -----------------------------------------------------------------------
    // STEP 3: Update neurochemicals
    // -----------------------------------------------------------------------
    let amygdalaOut   = if (14 < ORGAN_COUNT) organSignals[14] else S0;
    let prefrontalOut = if (15 < ORGAN_COUNT) organSignals[15] else S0;

    NeuroChem.update(
      neuroLevels,
      neuroDecayRates,
      amygdalaOut,
      prefrontalOut,
      temporalDilation
    );

    // -----------------------------------------------------------------------
    // STEP 4: Fire organs (with Hopf oscillators + second-order dynamics)
    // -----------------------------------------------------------------------
    var oi = 0;
    while (oi < ORGAN_COUNT) {
      prevOrganSignals[oi] := organSignals[oi];
      oi += 1;
    };

    let neuroImm     = NeuroChem.as_immutable(neuroLevels);
    let newOrganSigs = Organs.fire(
      neuroImm,
      organVelocities,
      hopfX,
      hopfY,
      globalCoherence,
      beatCount
    );
    oi := 0;
    while (oi < ORGAN_COUNT) {
      organSignals[oi] := newOrganSigs[oi];
      oi += 1;
    };

    // Update Welford stats for CROW
    Animals.update_organ_stats(organMean, organM2, newOrganSigs, beatCount);

    // -----------------------------------------------------------------------
    // STEP 5: Apply metals
    // -----------------------------------------------------------------------
    let dopamine     = NeuroChem.get(neuroLevels, 0);
    let newMetalSigs = Metals.apply(
      Array.freeze(organSignals),
      globalCoherence,
      entanglaIndex,
      dopamine
    );
    oi := 0;
    while (oi < ORGAN_COUNT) {
      metalSignals[oi] := newMetalSigs[oi];
      oi += 1;
    };

    // -----------------------------------------------------------------------
    // STEP 6 + 7: Hebbian + Kuramoto for all 11 shells
    // -----------------------------------------------------------------------
    let nodeCounts  = Shells.NODE_COUNTS;
    let frequencies = Shells.FREQUENCIES;
    let bdnfBoost   = NeuroChem.bdnf_eta_boost(neuroLevels);
    let neuroMod    = NeuroChem.general_neuro_mod(neuroLevels);
    let nitricOx    = NeuroChem.nitric_oxide_boost(neuroLevels);

    var s = 0;
    while (s < SHELL_COUNT) {
      let w   = getShellWeights(s);
      let acts = getShellActs(s);
      let ph  = getShellPhases(s);
      let nc  = nodeCounts[s];
      let freq = frequencies[s];

      let organInputSlice = Array.tabulate<Float>(nc, func(i) {
        metalSignals[i % ORGAN_COUNT]
      });

      var metalSum = 0.0;
      var mi = 0;
      while (mi < ORGAN_COUNT) { metalSum := metalSum + metalSignals[mi]; mi += 1; };
      let metalBias = metalSum / Float.fromInt(ORGAN_COUNT);

      Shells.hebbian_update(w, acts, nc, organInputSlice, metalBias, bdnfBoost, neuroMod);

      let r = Shells.kuramoto_update(ph, nc, freq);
      kuramotoR[s] := r;
      meanActs[s]  := Shells.mean_activation(acts, nc);
      spectralCoh[s] := Shells.spectral_coherence(acts, nc);

      s += 1;
    };

    // -----------------------------------------------------------------------
    // STEP 8: Global coherence (expanded with spectral coh + nitric oxide)
    // -----------------------------------------------------------------------
    prevGlobalCoherence := globalCoherence;
    globalCoherence := Shells.compute_global_coherence(
      Array.freeze(kuramotoR),
      Array.freeze(meanActs),
      Array.freeze(spectralCoh),
      nitricOx
    );

    // -----------------------------------------------------------------------
    // STEP 9: Quantum operator update
    // -----------------------------------------------------------------------
    let flatActs  = buildFlatActivations();
    let cortisol  = NeuroChem.get(neuroLevels, 4);
    let oxytocin  = NeuroChem.get(neuroLevels, 5);

    let qState = QuantumOps.update(
      flatActs,
      Array.freeze(kuramotoR),
      Array.freeze(meanActs),
      frequencies,
      neuroImm,
      qmemRing,
      beatCount,
      cortisol,
      temporalDilation,
      complianceVec,
      MAX_NODES,
      SHELL_COUNT,
      globalCoherence
    );

    parallaxAngle  := qState.parallax_angle;
    entanglaIndex  := qState.entangla_index;
    bypassActive   := qState.bypass_active;
    bypassOutput   := qState.bypass_output;
    resonexField   := qState.resonex_field;
    qmemCoherence  := qState.qmem_coherence;
    vnEntropy      := qState.vn_entropy;
    veritasCoh     := qState.veritas_coh;
    entanglaEntropy := qState.entangla_entropy;

    // -----------------------------------------------------------------------
    // STEP 10: Fire animal engines
    // -----------------------------------------------------------------------
    adaptRate := Animals.compute_adapt_rate(
      prevOrganSignals,
      Array.freeze(organSignals)
    );

    let organStd = Animals.get_organ_std(organM2, beatCount);

    let currentState : [Float] = [
      globalCoherence,
      FORMA_GENESIS,
      0.0,
      Float.fromInt(regimeCode)
    ];
    let bestEpisode : [Float] = [
      bestEpisodeCoherence,
      bestEpisodeForma,
      bestEpisodeDrive,
      bestEpisodeRegime
    ];
    let emaVec : [Float] = [
      btcEma21, btcEma55, btcEma200,
      ethEma21, ethEma55, ethEma200,
      solEma21, solEma55, solEma200,
      icpEma21, icpEma55, icpEma200
    ];
    let prevEmaVec : [Float] = Array.freeze(prevEma21);

    let animalSigs = Animals.fire(
      Array.freeze(organSignals),
      Array.freeze(organMean),
      organStd,
      Array.freeze(prevOrganSignals),
      Array.freeze(kuramotoR),
      entanglaIndex,
      oxytocin,
      dopamine,
      beatCount,
      novaChildCount,
      currentState,
      bestEpisode,
      btcPrice,
      btcEma21,
      btcEma55,
      btcEma200,
      defiYield,
      arbSignal,
      regimeClarity,
      regimeCode,
      emaVec,
      prevEmaVec
    );

    crowOutput    := animalSigs.crow;
    dolphinOutput := animalSigs.dolphin;
    hiveOutput    := animalSigs.hive;
    elephantOutput := animalSigs.elephant;
    sharkOutput   := animalSigs.shark;
    wolfOutput    := animalSigs.wolf;
    orcaOutput    := animalSigs.orca;
    eagleOutput   := animalSigs.eagle;
    octopusOutput := animalSigs.octopus;

    // Save EMA21 for next beat Eagle momentum
    prevEma21[0] := btcEma21;
    prevEma21[1] := ethEma21;
    prevEma21[2] := solEma21;
    prevEma21[3] := icpEma21;

    if (globalCoherence > bestEpisodeCoherence) {
      bestEpisodeCoherence := globalCoherence;
    };

    // -----------------------------------------------------------------------
    // STEP 15: VERITAS compliance vector
    // -----------------------------------------------------------------------
    switch (veritasCanisterId) {
      case (?cid) {
        try {
          let veritas = actor(cid) : VeritasActor;
          let vec = await veritas.getComplianceVectorPublic();
          complianceVec := vec;
          var total = 0.0; var ci = 0;
          while (ci < vec.size()) { total := total + vec[ci]; ci += 1; };
          complianceMean := if (vec.size() == 0) S0 else total / Float.fromInt(vec.size());
        } catch (_) { /* retain last */ };
      };
      case null { };
    };

    // -----------------------------------------------------------------------
    // STEP 22: Audit entry
    // -----------------------------------------------------------------------
    let entry = "BEAT:" # Nat.toText(beatCount) #
                "|COH:" # Float.toText(globalCoherence) #
                "|ENT:" # Float.toText(entanglaIndex) #
                "|VNE:" # Float.toText(vnEntropy) #
                "|CROW:" # Float.toText(crowOutput) #
                "|SHARK:" # Float.toText(sharkOutput) #
                "|HIVE:" # Float.toText(hiveOutput);
    writeAudit(entry);
    lastBeatTime := startTime;
  };

  // ===========================================================================
  // HEARTBEAT TIMER
  // ===========================================================================

  public shared(msg) func startHeartbeat() : async () {
    assertCreator(msg.caller);
    if (not heartbeatActive) {
      heartbeatActive := true;
      ignore Timer.recurringTimer<system>(#nanoseconds(HEARTBEAT_NS), heartbeat);
    };
  };

  public shared(msg) func manualBeat() : async () {
    assertCreator(msg.caller);
    await heartbeat();
  };

  // ===========================================================================
  // QUERY FUNCTIONS
  // ===========================================================================

  public query func getGlobalCoherence() : async Float { globalCoherence };
  public query func getBeatCount()        : async Nat   { beatCount };
  public query func getTemporalDilation() : async Float { temporalDilation };
  public query func getNeuroVec()         : async [Float] { Array.freeze(neuroLevels) };
  public query func getOrganSignals()     : async [Float] { Array.freeze(organSignals) };
  public query func getMetalSignals()     : async [Float] { Array.freeze(metalSignals) };
  public query func getKuramotoR()        : async [Float] { Array.freeze(kuramotoR) };
  public query func getMeanActs()         : async [Float] { Array.freeze(meanActs) };
  public query func getSpectralCoh()      : async [Float] { Array.freeze(spectralCoh) };

  public query func getAnimalSignals() : async {
    crow : Float; dolphin : Float; hive : Float; elephant : Float;
    shark : Float; wolf : Float; orca : Float; eagle : Float; octopus : Float;
  } {
    { crow = crowOutput; dolphin = dolphinOutput; hive = hiveOutput;
      elephant = elephantOutput; shark = sharkOutput; wolf = wolfOutput;
      orca = orcaOutput; eagle = eagleOutput; octopus = octopusOutput; }
  };

  public query func getQuantumState() : async {
    parallax_angle : Float; entangla_index : Float; bypass_active : Bool;
    bypass_output : Float; resonex_field : Float; qmem_coherence : Float;
    vn_entropy : Float; chrono_dilation : Float; veritas_coh : Float;
    entangla_entropy : Float;
  } {
    { parallax_angle   = parallaxAngle;
      entangla_index   = entanglaIndex;
      bypass_active    = bypassActive;
      bypass_output    = bypassOutput;
      resonex_field    = resonexField;
      qmem_coherence   = qmemCoherence;
      vn_entropy       = vnEntropy;
      chrono_dilation  = temporalDilation;
      veritas_coh      = veritasCoh;
      entangla_entropy = entanglaEntropy; }
  };

  public query func getFullBrainState() : async {
    beat : Nat; coherence : Float; dilation : Float; entangla : Float;
    complianceMean : Float; cortisol : Float; dopamine : Float;
    crowNovelty : Float; sharkAnomaly : Float; wolfPack : Float;
    bypassArmed : Bool; vnEntropy : Float; resonexField : Float;
  } {
    { beat           = beatCount;
      coherence      = globalCoherence;
      dilation       = temporalDilation;
      entangla       = entanglaIndex;
      complianceMean = complianceMean;
      cortisol       = NeuroChem.get(neuroLevels, 4);
      dopamine       = NeuroChem.get(neuroLevels, 0);
      crowNovelty    = crowOutput;
      sharkAnomaly   = sharkOutput;
      wolfPack       = wolfOutput;
      bypassArmed    = bypassActive;
      vnEntropy      = vnEntropy;
      resonexField   = resonexField; }
  };

  public query func getShellState(s : Nat) : async {
    activations : [Float]; kuramoto_r : Float; mean_act : Float; spectral_coh : Float;
  } {
    let si = if (s < SHELL_COUNT) s else 0;
    let acts = getShellActs(si);
    { activations  = Array.freeze(acts);
      kuramoto_r   = kuramotoR[si];
      mean_act     = meanActs[si];
      spectral_coh = spectralCoh[si]; }
  };

  public query func getAuditTail(n : Nat) : async [Text] {
    let count = if (n > auditCount) auditCount else n;
    let start = if (auditHead >= count) auditHead - count else 0;
    Array.tabulate<Text>(count, func(i) {
      auditLog[(start + i) % AUDIT_RING_SIZE]
    })
  };

  // ===========================================================================
  // MARKET SIGNAL INJECTION
  // ===========================================================================

  public shared(msg) func injectMarketSignals(
    _btcPrice : Float; _ethPrice : Float;
    _solPrice : Float; _icpPrice : Float;
    _btcEma21 : Float; _btcEma55 : Float; _btcEma200 : Float;
    _ethEma21 : Float; _ethEma55 : Float; _ethEma200 : Float;
    _solEma21 : Float; _solEma55 : Float; _solEma200 : Float;
    _icpEma21 : Float; _icpEma55 : Float; _icpEma200 : Float;
    _defiYield : Float; _arbSignal : Float; _regimeClarity : Float;
    _regimeCode : Nat;
  ) : async () {
    assertCreator(msg.caller);
    btcPrice := if (_btcPrice < S0) S0 else _btcPrice;
    ethPrice := if (_ethPrice < S0) S0 else _ethPrice;
    solPrice := if (_solPrice < S0) S0 else _solPrice;
    icpPrice := if (_icpPrice < S0) S0 else _icpPrice;
    btcEma21  := if (_btcEma21  < S0) S0 else _btcEma21;
    btcEma55  := if (_btcEma55  < S0) S0 else _btcEma55;
    btcEma200 := if (_btcEma200 < S0) S0 else _btcEma200;
    ethEma21  := if (_ethEma21  < S0) S0 else _ethEma21;
    ethEma55  := if (_ethEma55  < S0) S0 else _ethEma55;
    ethEma200 := if (_ethEma200 < S0) S0 else _ethEma200;
    solEma21  := if (_solEma21  < S0) S0 else _solEma21;
    solEma55  := if (_solEma55  < S0) S0 else _solEma55;
    solEma200 := if (_solEma200 < S0) S0 else _solEma200;
    icpEma21  := if (_icpEma21  < S0) S0 else _icpEma21;
    icpEma55  := if (_icpEma55  < S0) S0 else _icpEma55;
    icpEma200 := if (_icpEma200 < S0) S0 else _icpEma200;
    defiYield    := _defiYield;
    arbSignal    := _arbSignal;
    regimeClarity := if (_regimeClarity < S0) S0 else _regimeClarity;
    regimeCode   := _regimeCode;
  };

  public shared(msg) func setNovaChildCount(n : Nat) : async () {
    assertCreator(msg.caller);
    novaChildCount := n;
  };

  // ===========================================================================
  // GENESIS SEAL
  // ===========================================================================

  public shared(msg) func sealGenesis() : async Bool {
    assertCreator(msg.caller);
    if (genesisSealed) { return false; };
    genesisSealed := true;
    if (not heartbeatActive) {
      heartbeatActive := true;
      ignore Timer.recurringTimer<system>(#nanoseconds(HEARTBEAT_NS), heartbeat);
    };
    writeAudit("GENESIS_SEALED|beat:0|creator:" # creatorPrincipal);
    true
  };

  public query func isGenesisSealed() : async Bool { genesisSealed };

}
