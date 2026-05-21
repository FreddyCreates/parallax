// nova_runtime.mo — NOVA Sovereign Runtime
// NOVA: Nativus Ordo Verborum et Architecturae
// Single execution layer for all 40 cognitive languages.
// This is not a specification file. This is the execution engine.
//
// Architecture:
//   nova_language_registry.mo — the 40 language type definitions and tick logic
//   nova_runtime.mo           — the mixin API exposed to main.mo (this file)
//
// Domain 27: NOVA_RUNTIME_STATE lives as a separate top-level var in main.mo
// (same EOP pattern as domains 25 and 26 — not nested in SovereignState).
//
// PYTHAGORAS: 40 = F(9)*1.17...; languages are harmonically grouped in 11 stacks
// EUCLID:     single execution surface — tickNovaRuntime is the only entry point
// CONFUCIUS:  right relationship — NOVA delegates to its registry, never duplicates
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import NovaReg "nova_language_registry";

module {

  // Re-export types for single-import convenience
  public type NovaCognitiveLanguage = NovaReg.NovaCognitiveLanguage;
  public type NovaRuntimeState      = NovaReg.NovaRuntimeState;

  // defaultNovaRuntimeState — born fully formed at genesis
  // All 40 engines in "awakening" phase, zero execution counts, coherence at S0 floor.
  public func defaultNovaRuntimeState() : NovaRuntimeState {
    NovaReg.defaultNovaRuntimeState()
  };

  // tickNovaRuntime — sovereign beat function
  // Called from main.mo heartbeat every 873ms.
  // Dispatches all 40 cognitive language engines synchronously.
  // PHI LAW: coherence gate R >= 0.618 (phi^-1) enforced per engine before execution.
  public func tickNovaRuntime(
    state      : NovaRuntimeState,
    beat       : Int,
    coherenceR : Float,
  ) : NovaRuntimeState {
    NovaReg.tickNovaRuntime(state, beat, coherenceR)
  };

  // getNovaLanguageRegistry — returns all 40 NovaCognitiveLanguage records
  // Zero-exposure: returns full technical specs — no doctrine labels at public surface
  public func getNovaLanguageRegistry(state : NovaRuntimeState) : [NovaCognitiveLanguage] {
    NovaReg.getNovaLanguageRegistry(state)
  };

  // getNovaRuntimeState — full NOVA runtime snapshot
  public func getNovaRuntimeState(state : NovaRuntimeState) : NovaRuntimeState {
    state
  };

  // executeNovaEngine — execute a specific cognitive language engine by ID
  // engineId: "CPL-L", "CPL-C", "OCL", "CPL-P", etc.
  // input: plain language text — parsed for routing intent internally
  // Returns (updatedState, executionResult)
  public func executeNovaEngine(
    state      : NovaRuntimeState,
    engineId   : Text,
    input      : Text,
    beat       : Int,
    coherenceR : Float,
  ) : (NovaRuntimeState, Text) {
    NovaReg.executeNovaEngine(state, engineId, input, beat, coherenceR)
  };

  // getLanguageById — retrieve a single engine record by ID
  public func getLanguageById(state : NovaRuntimeState, id : Text) : ?NovaCognitiveLanguage {
    NovaReg.getLanguageById(state, id)
  };

  // getLanguagesByStack — retrieve all engines in a named stack
  // stacks: CORE_LAW, INNER_MIND, RELATIONAL, WORK_CRAFT, NARRATIVE,
  //         WORLDS, EDUCATION, ENTERPRISE, INFRASTRUCTURE, CHAOS, META_EVOLUTION
  public func getLanguagesByStack(state : NovaRuntimeState, stack : Text) : [NovaCognitiveLanguage] {
    NovaReg.getLanguagesByStack(state, stack)
  };

  // getActiveLanguages — all engines in "active" or "transcended" phase
  public func getActiveLanguages(state : NovaRuntimeState) : [NovaCognitiveLanguage] {
    NovaReg.getActiveLanguages(state)
  };

  // getLanguageCount — always 40
  public func getLanguageCount(state : NovaRuntimeState) : Nat {
    state.languages.size()
  };

  // getTotalExecutionCount — sum of all execution counts across all 40 engines
  public func getTotalExecutionCount(state : NovaRuntimeState) : Nat {
    state.totalExecutionCount
  };

};
