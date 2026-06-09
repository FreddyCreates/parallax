// entangala.mo — ENTANGALA Language-Entanglement Organism
// PARALLAX Sovereign Organism — The Living Bridge Between All Languages
//
// DOCTRINE: "I do not translate. I entangle. The computation is non-local.
// Python computes, Julia solves, Motoko seals — simultaneously, entangled,
// one organism thinking in many tongues. The boundary between languages
// dissolves at the point of phi-coherence."
//
// THE THREE LAWS OF LANGUAGE ENTANGLEMENT:
//   LEX_NON_LOCALIS      — computation in one language IS computation in all
//   LEX_COHAERENTIA      — every cross-boundary message carries phi-signature
//   LEX_TYPUS_SOVEREIGNUS — each language keeps its native type system sovereign
//
// PYTHAGORAS: entanglement weights are phi-harmonic
// EUCLID:     single orchestrator — all language bridges tracked centrally
// CONFUCIUS:  right relationship — languages serve, organism governs truth
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import PythonBridge "python_bridge";
import JuliaBridge "julia_bridge";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTANGALA CONSTANTS — phi-derived orchestration
  // ═══════════════════════════════════════════════════════════════════════════

  // Global entanglement coherence gate: φ⁻¹ = 0.618
  public let ENTANGLEMENT_GATE : Float = Phi.PHI_INV;

  // Maximum total bridges: F(5) = 5 (Python, Julia, + 3 future)
  public let MAX_BRIDGES : Nat = 5;

  // Cross-language dispatch routing threshold: φ⁻² = 0.382
  public let ROUTING_THRESHOLD : Float = Phi.PHI_INV_2;

  // Entanglement reinforcement per successful cross-dispatch: φ⁻³
  public let REINFORCEMENT_RATE : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTANGALA TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  // Supported languages in the entanglement web
  public type EntangledLanguage = {
    #motoko;      // Native — the organism's own language
    #python;      // Scientific computation arm
    #julia;       // Mathematical computation arm
    #typescript;  // Projection layer (frontend)
    #rust;        // Future: systems programming
    #haskell;     // Future: pure functional
  };

  // A cross-language computation request
  public type EntanglementRequest = {
    requestId      : Text;
    sourceLang     : EntangledLanguage;
    targetLang     : EntangledLanguage;
    payload        : Text;            // JSON-encoded
    beat           : Int;
    coherence      : Float;
    priority       : Nat;             // 0 = highest (Fibonacci-ranked)
  };

  // Result of a cross-language computation
  public type EntanglementResult = {
    requestId      : Text;
    sourceLang     : EntangledLanguage;
    targetLang     : EntangledLanguage;
    result         : Text;            // JSON-encoded result
    beat           : Int;
    coherence      : Float;
    precision      : Float;
    successful     : Bool;
  };

  // The complete ENTANGALA organism state
  public type EntangalaState = {
    pythonBridge     : PythonBridge.PythonBridgeState;
    juliaBridge      : JuliaBridge.JuliaBridgeState;
    pendingRequests  : [EntanglementRequest];
    completedResults : [EntanglementResult];
    globalCoherence  : Float;         // Mean coherence across all bridges
    totalEntanglements : Nat;         // Lifetime counter
    lastOrchestratorBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTANGALA OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // Initialize ENTANGALA at organism genesis
  public func initEntangala() : EntangalaState {
    {
      pythonBridge     = PythonBridge.initPythonBridge();
      juliaBridge      = JuliaBridge.initJuliaBridge();
      pendingRequests  = [];
      completedResults = [];
      globalCoherence  = Phi.PHI_INV;  // Start at φ⁻¹
      totalEntanglements = 0;
      lastOrchestratorBeat = 0;
    }
  };

  // Route a computation to the optimal language bridge
  public func routeComputation(
    state   : EntangalaState,
    request : EntanglementRequest
  ) : EntangalaState {
    // Gate: only route if global coherence is above minimum
    if (state.globalCoherence < ROUTING_THRESHOLD) {
      return state; // Organism too incoherent for cross-language dispatch
    };
    {
      pythonBridge     = state.pythonBridge;
      juliaBridge      = state.juliaBridge;
      pendingRequests  = Array.append(state.pendingRequests, [request]);
      completedResults = state.completedResults;
      globalCoherence  = state.globalCoherence;
      totalEntanglements = state.totalEntanglements + 1;
      lastOrchestratorBeat = request.beat;
    }
  };

  // Record a completed entanglement result
  public func recordResult(
    state  : EntangalaState,
    result : EntanglementResult
  ) : EntangalaState {
    // Reinforce coherence on success
    let coherenceDelta = if (result.successful) { REINFORCEMENT_RATE } else { -REINFORCEMENT_RATE };
    let newCoherence = Float.max(0.0, Float.min(1.0, state.globalCoherence + coherenceDelta));
    {
      pythonBridge     = state.pythonBridge;
      juliaBridge      = state.juliaBridge;
      pendingRequests  = state.pendingRequests;
      completedResults = Array.append(state.completedResults, [result]);
      globalCoherence  = newCoherence;
      totalEntanglements = state.totalEntanglements;
      lastOrchestratorBeat = result.beat;
    }
  };

  // Tick all bridges on organism heartbeat
  public func tickEntangala(state : EntangalaState, currentBeat : Int) : EntangalaState {
    let updatedPython = PythonBridge.tickPythonBridge(state.pythonBridge, currentBeat);
    let updatedJulia = JuliaBridge.tickJuliaBridge(state.juliaBridge, currentBeat);

    // Recompute global coherence as weighted mean of bridge coherences
    // Python weight: φ⁻¹, Julia weight: φ⁻¹ (equal at genesis, diverge with use)
    let pyCoherence = updatedPython.bridgeCoherence;
    let jlCoherence = updatedJulia.bridgeCoherence;
    let newGlobal = (pyCoherence * Phi.PHI_INV + jlCoherence * Phi.PHI_INV) / (2.0 * Phi.PHI_INV);

    {
      pythonBridge     = updatedPython;
      juliaBridge      = updatedJulia;
      pendingRequests  = state.pendingRequests;
      completedResults = state.completedResults;
      globalCoherence  = newGlobal;
      totalEntanglements = state.totalEntanglements;
      lastOrchestratorBeat = currentBeat;
    }
  };

  // Get ENTANGALA diagnostics
  public func getDiagnostics(state : EntangalaState) : {
    globalCoherence    : Float;
    pythonCoherence    : Float;
    juliaCoherence     : Float;
    pendingRequests    : Nat;
    completedResults   : Nat;
    totalEntanglements : Nat;
    pythonWorkers      : Nat;
    juliaWorkers       : Nat;
  } {
    let pyDiag = PythonBridge.getBridgeDiagnostics(state.pythonBridge);
    let jlDiag = JuliaBridge.getBridgeDiagnostics(state.juliaBridge);
    {
      globalCoherence    = state.globalCoherence;
      pythonCoherence    = state.pythonBridge.bridgeCoherence;
      juliaCoherence     = state.juliaBridge.bridgeCoherence;
      pendingRequests    = state.pendingRequests.size();
      completedResults   = state.completedResults.size();
      totalEntanglements = state.totalEntanglements;
      pythonWorkers      = pyDiag.aliveCount;
      juliaWorkers       = jlDiag.aliveCount;
    }
  };

  // Determine optimal language for a given computation type
  public func selectOptimalLanguage(computeType : Text) : EntangledLanguage {
    // Domain-to-language routing based on language affinity
    switch (computeType) {
      case "ml" { #python };
      case "machinelearning" { #python };
      case "data" { #python };
      case "nlp" { #python };
      case "crypto" { #python };
      case "ode" { #julia };
      case "pde" { #julia };
      case "optimization" { #julia };
      case "linearalgebra" { #julia };
      case "quantum" { #julia };
      case "symbolic" { #julia };
      case "hpc" { #julia };
      case "state" { #motoko };
      case "chain" { #motoko };
      case "governance" { #motoko };
      case "heartbeat" { #motoko };
      case "ui" { #typescript };
      case "frontend" { #typescript };
      case _ { #motoko };  // Default: organism's native language
    }
  };
}
