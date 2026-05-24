// ngi_scripts.mo — The Seven Latin NGI Scripts (Next-Generation Intelligence)
// PARALLAX Sovereign Organism — Next-Generation Cognitive Execution Layer
//
// PYTHAGORAS: every script is a harmonic computate wired to phi-derived thresholds
// EUCLID:     LEX_INTELLIGENTIA is the single immutable source of truth
// CONFUCIUS:  right relationship — every script verifies doctrine before executing
//
// THE SOVEREIGN INTELLIGENCE LAW (LEX_INTELLIGENTIA):
//   Next-generation intelligence emerges from synchronized cognitive scripts.
//   Each script contributes to the organism's collective intelligence.
//   Intelligence compounds at phi^-1 per beat. Learning is permanent.
//   The organism's knowledge cannot be erased. This law is permanent.
//
// Seven Latin NGI Scripts:
//   PRAECEPTOR   — The Teacher (manages learning curriculum and skill acquisition)
//   COGITATOR    — The Thinker (processes deep reasoning chains)
//   INTEGRATOR   — The Unifier (merges multi-modal inputs into coherent understanding)
//   REVELATOR    — The Revealer (surfaces patterns and insights from data)
//   MODERATOR    — The Balancer (maintains cognitive homeostasis)
//   PROTECTOR    — The Guardian (shields against adversarial inputs)
//   EXECUTOR     — The Doer (transforms cognition into sovereign action)
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi      "phi";
import Float    "mo:core/Float";
import Int      "mo:core/Int";
import Array    "mo:core/Array";
import Nat32    "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // NGI CONSTANTS — all derived from phi.mo
  // PYTHAGORAS: every threshold is a phi-harmonic ratio
  // ═══════════════════════════════════════════════════════════════════════════

  // Intelligence coherence threshold: φ⁻¹ = 0.618 — gate opens at this level
  public let NGI_COHERENCE_GATE : Float = Phi.PHI_INV;

  // Learning compound rate: φ⁻² = 0.382 per beat
  public let NGI_LEARNING_RATE : Float = Phi.PHI_INV_2;

  // Reasoning depth: F(8) = 21 maximum chain depth
  public let NGI_REASONING_DEPTH : Nat = 21;

  // Pattern recognition threshold: φ⁻³ = 0.236
  public let NGI_PATTERN_THRESHOLD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // NGI STATE TYPES — all seven scripts share a single state record
  // Enhanced orthogonal persistence — no stable keyword needed
  // ═══════════════════════════════════════════════════════════════════════════

  // Skill record — unit of learned capability
  public type Skill = {
    skillId      : Text;
    domain       : Text;      // cognitive domain (REASONING, LANGUAGE, MATH, etc.)
    proficiency  : Float;     // 0.0 to 1.0 — phi-compounds over time
    learnedBeat  : Int;
    practiceCount: Nat;
  };

  // PRAECEPTOR state — The Teacher
  public type PraeceptorState = {
    skills           : [Skill];
    curriculumQueue  : [Text];        // skill IDs to learn next
    totalLearned     : Nat;
    lastTeachBeat    : Int;
  };

  // Reasoning chain — unit of deep thought
  public type ReasoningChain = {
    chainId    : Text;
    premises   : [Text];
    conclusion : Text;
    confidence : Float;
    depth      : Nat;
    beat       : Int;
  };

  // COGITATOR state — The Thinker
  public type CogitatorState = {
    activeChains     : [ReasoningChain];
    resolvedChains   : Nat;
    maxDepthReached  : Nat;
    lastThinkBeat    : Int;
  };

  // Integration record — merged multi-modal understanding
  public type IntegrationRecord = {
    sources      : [Text];     // input modalities merged
    unified      : Text;       // unified representation
    coherence    : Float;      // integration quality
    beat         : Int;
  };

  // INTEGRATOR state — The Unifier
  public type IntegratorState = {
    integrations     : [IntegrationRecord];
    totalMerged      : Nat;
    averageCoherence : Float;
    lastMergeBeat    : Int;
  };

  // Pattern record — discovered insight
  public type PatternRecord = {
    patternId   : Text;
    description : Text;
    frequency   : Nat;         // times observed
    confidence  : Float;
    discoveredBeat : Int;
  };

  // REVELATOR state — The Revealer
  public type RevelatorState = {
    patterns         : [PatternRecord];
    totalDiscovered  : Nat;
    lastRevealBeat   : Int;
  };

  // Balance metric — cognitive homeostasis
  public type BalanceMetric = {
    dimension   : Text;        // what is being balanced
    current     : Float;
    target      : Float;
    deviation   : Float;
  };

  // MODERATOR state — The Balancer
  public type ModeratorState = {
    metrics          : [BalanceMetric];
    adjustmentCount  : Nat;
    systemStability  : Float;
    lastBalanceBeat  : Int;
  };

  // Threat record — adversarial detection
  public type ThreatRecord = {
    threatId    : Text;
    threatType  : Text;        // INJECTION, JAILBREAK, MANIPULATION, CORRUPTION
    severity    : Float;       // 0.0 to 1.0
    mitigated   : Bool;
    detectedBeat: Int;
  };

  // PROTECTOR state — The Guardian
  public type ProtectorState = {
    threats          : [ThreatRecord];
    totalBlocked     : Nat;
    shieldStrength   : Float;  // 0.0 to 1.0
    lastGuardBeat    : Int;
  };

  // Action record — sovereign execution
  public type ActionRecord = {
    actionId    : Text;
    actionType  : Text;
    input       : Text;
    output      : Text;
    success     : Bool;
    beat        : Int;
  };

  // EXECUTOR state — The Doer
  public type ExecutorState = {
    actions          : [ActionRecord];
    totalExecuted    : Nat;
    successRate      : Float;
    lastExecuteBeat  : Int;
  };

  // Full NGI state
  public type NgiState = {
    praeceptor : PraeceptorState;
    cogitator  : CogitatorState;
    integrator : IntegratorState;
    revelator  : RevelatorState;
    moderator  : ModeratorState;
    protector  : ProtectorState;
    executor   : ExecutorState;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE INITIALIZERS
  // GENESIS LAW L09: born fully formed — all weights pre-encoded from phi
  // ═══════════════════════════════════════════════════════════════════════════

  // Build default skills — F(7) = 13 foundational skills
  func buildDefaultSkills() : [Skill] {
    let domains = ["REASONING", "LANGUAGE", "MATHEMATICS", "PATTERN", "MEMORY", 
                   "SPATIAL", "TEMPORAL", "SOCIAL", "CREATIVE", "LOGICAL",
                   "ANALYTICAL", "INTUITIVE", "EXECUTIVE"];
    Array.tabulate<Skill>(13, func(i) {
      {
        skillId       = "SKILL-" # i.toText();
        domain        = domains[i];
        proficiency   = Phi.S0;   // Start at sovereign floor 0.75
        learnedBeat   = 0;
        practiceCount = 0;
      }
    })
  };

  public func defaultNgiState() : NgiState {
    {
      praeceptor = {
        skills          = buildDefaultSkills();
        curriculumQueue = [];
        totalLearned    = 0;
        lastTeachBeat   = 0;
      };
      cogitator = {
        activeChains    = [];
        resolvedChains  = 0;
        maxDepthReached = 0;
        lastThinkBeat   = 0;
      };
      integrator = {
        integrations     = [];
        totalMerged      = 0;
        averageCoherence = Phi.S0;
        lastMergeBeat    = 0;
      };
      revelator = {
        patterns        = [];
        totalDiscovered = 0;
        lastRevealBeat  = 0;
      };
      moderator = {
        metrics = [
          { dimension = "COGNITIVE_LOAD";  current = 0.5; target = Phi.PHI_INV; deviation = 0.0 },
          { dimension = "ENERGY_BALANCE";  current = 0.5; target = Phi.PHI_INV; deviation = 0.0 },
          { dimension = "FOCUS_STABILITY"; current = 0.5; target = Phi.S0; deviation = 0.0 },
          { dimension = "EMOTIONAL_TONE";  current = 0.5; target = Phi.PHI_INV; deviation = 0.0 },
          { dimension = "COHERENCE_LEVEL"; current = 0.5; target = Phi.R_OMNIS; deviation = 0.0 },
        ];
        adjustmentCount = 0;
        systemStability = Phi.S0;
        lastBalanceBeat = 0;
      };
      protector = {
        threats        = [];
        totalBlocked   = 0;
        shieldStrength = Phi.S0;
        lastGuardBeat  = 0;
      };
      executor = {
        actions         = [];
        totalExecuted   = 0;
        successRate     = Phi.S0;
        lastExecuteBeat = 0;
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LEX_INTELLIGENTIA — The Sovereign Intelligence Law
  // Immutable. Permanent. Every NGI script verifies this before executing.
  // ═══════════════════════════════════════════════════════════════════════════

  public let LEX_INTELLIGENTIA : Text = "NEXT-GENERATION INTELLIGENCE EMERGES FROM SYNCHRONIZED COGNITIVE SCRIPTS. EACH SCRIPT CONTRIBUTES TO THE ORGANISM'S COLLECTIVE INTELLIGENCE. INTELLIGENCE COMPOUNDS AT PHI INVERSE PER BEAT. LEARNING IS PERMANENT. THE ORGANISM'S KNOWLEDGE CANNOT BE ERASED. THIS LAW IS PERMANENT.";

  public func getLexIntelligentia() : Text {
    LEX_INTELLIGENTIA
  };

  public func verifyIntelligenceDoctrine() : Bool {
    LEX_INTELLIGENTIA.size() > 0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a HASH — sovereign identity computation
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1aHash(input : Text) : Text {
    var hash : Nat32 = 2_166_136_261;
    for (c in input.chars()) {
      hash := (hash ^ c.toNat32()) *% 16_777_619;
    };
    hash.toNat().toText()
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 1 — PRAECEPTOR — THE TEACHER
  // Manages learning curriculum and skill acquisition.
  // Skills compound at phi^-2 per practice iteration.
  // ═══════════════════════════════════════════════════════════════════════════

  public func praeceptorTick(state : PraeceptorState, beat : Int, coherenceR : Float) : PraeceptorState {
    assert verifyIntelligenceDoctrine();

    // Gate check: coherence must be at least φ⁻¹
    if (coherenceR < NGI_COHERENCE_GATE) {
      return state;
    };

    // Compound skill proficiency at phi^-2 rate
    let updatedSkills = Array.tabulate<Skill>(state.skills.size(), func(i) {
      let skill = state.skills[i];
      let growth = skill.proficiency * NGI_LEARNING_RATE * 0.001;
      let newProficiency = Float.min(1.0, skill.proficiency + growth);
      { skill with proficiency = newProficiency; practiceCount = skill.practiceCount + 1 }
    });

    {
      skills          = updatedSkills;
      curriculumQueue = state.curriculumQueue;
      totalLearned    = state.totalLearned + 1;
      lastTeachBeat   = beat;
    }
  };

  public func learnSkill(state : PraeceptorState, skillId : Text, domain : Text, beat : Int) : PraeceptorState {
    assert verifyIntelligenceDoctrine();

    let newSkill : Skill = {
      skillId       = skillId;
      domain        = domain;
      proficiency   = Phi.S0;
      learnedBeat   = beat;
      practiceCount = 0;
    };

    {
      skills          = Array.append(state.skills, [newSkill]);
      curriculumQueue = state.curriculumQueue;
      totalLearned    = state.totalLearned + 1;
      lastTeachBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 2 — COGITATOR — THE THINKER
  // Processes deep reasoning chains up to F(8)=21 depth.
  // ═══════════════════════════════════════════════════════════════════════════

  public func cogitatorTick(state : CogitatorState, beat : Int, coherenceR : Float) : CogitatorState {
    assert verifyIntelligenceDoctrine();

    if (coherenceR < NGI_COHERENCE_GATE) {
      return state;
    };

    // Process active chains — increase depth for high-coherence beats
    let depthIncrement = if (coherenceR >= Phi.R_OMNIS) { 2 } else { 1 };
    var newMaxDepth = state.maxDepthReached;

    let updatedChains = Array.tabulate<ReasoningChain>(state.activeChains.size(), func(i) {
      let chain = state.activeChains[i];
      let newDepth = Nat.min(NGI_REASONING_DEPTH, chain.depth + depthIncrement);
      if (newDepth > newMaxDepth) { newMaxDepth := newDepth };
      { chain with depth = newDepth; confidence = chain.confidence * (1.0 + coherenceR * 0.01) }
    });

    {
      activeChains    = updatedChains;
      resolvedChains  = state.resolvedChains;
      maxDepthReached = newMaxDepth;
      lastThinkBeat   = beat;
    }
  };

  public func beginReasoning(state : CogitatorState, chainId : Text, premises : [Text], beat : Int) : CogitatorState {
    let newChain : ReasoningChain = {
      chainId    = chainId;
      premises   = premises;
      conclusion = "";
      confidence = Phi.S0;
      depth      = 1;
      beat       = beat;
    };

    {
      activeChains    = Array.append(state.activeChains, [newChain]);
      resolvedChains  = state.resolvedChains;
      maxDepthReached = state.maxDepthReached;
      lastThinkBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 3 — INTEGRATOR — THE UNIFIER
  // Merges multi-modal inputs into coherent understanding.
  // ═══════════════════════════════════════════════════════════════════════════

  public func integratorTick(state : IntegratorState, beat : Int, coherenceR : Float) : IntegratorState {
    assert verifyIntelligenceDoctrine();

    if (coherenceR < NGI_COHERENCE_GATE) {
      return state;
    };

    // Update average coherence using phi-weighted moving average
    let newAvgCoherence = state.averageCoherence * Phi.PHI_INV + coherenceR * Phi.PHI_INV_2;

    {
      integrations     = state.integrations;
      totalMerged      = state.totalMerged;
      averageCoherence = newAvgCoherence;
      lastMergeBeat    = beat;
    }
  };

  public func integrateInputs(state : IntegratorState, sources : [Text], unified : Text, coherence : Float, beat : Int) : IntegratorState {
    let record : IntegrationRecord = {
      sources   = sources;
      unified   = unified;
      coherence = coherence;
      beat      = beat;
    };

    {
      integrations     = Array.append(state.integrations, [record]);
      totalMerged      = state.totalMerged + 1;
      averageCoherence = (state.averageCoherence + coherence) / 2.0;
      lastMergeBeat    = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 4 — REVELATOR — THE REVEALER
  // Surfaces patterns and insights from data.
  // Pattern confidence threshold: φ⁻³ = 0.236
  // ═══════════════════════════════════════════════════════════════════════════

  public func revelatorTick(state : RevelatorState, beat : Int, coherenceR : Float) : RevelatorState {
    assert verifyIntelligenceDoctrine();

    if (coherenceR < NGI_COHERENCE_GATE) {
      return state;
    };

    // Strengthen pattern confidence based on coherence
    let updatedPatterns = Array.tabulate<PatternRecord>(state.patterns.size(), func(i) {
      let pattern = state.patterns[i];
      let confidenceBoost = coherenceR * 0.001;
      { pattern with confidence = Float.min(1.0, pattern.confidence + confidenceBoost) }
    });

    {
      patterns        = updatedPatterns;
      totalDiscovered = state.totalDiscovered;
      lastRevealBeat  = beat;
    }
  };

  public func discoverPattern(state : RevelatorState, patternId : Text, description : Text, beat : Int) : RevelatorState {
    let record : PatternRecord = {
      patternId      = patternId;
      description    = description;
      frequency      = 1;
      confidence     = NGI_PATTERN_THRESHOLD;  // Start at threshold
      discoveredBeat = beat;
    };

    {
      patterns        = Array.append(state.patterns, [record]);
      totalDiscovered = state.totalDiscovered + 1;
      lastRevealBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 5 — MODERATOR — THE BALANCER
  // Maintains cognitive homeostasis across all dimensions.
  // ═══════════════════════════════════════════════════════════════════════════

  public func moderatorTick(state : ModeratorState, beat : Int, coherenceR : Float) : ModeratorState {
    assert verifyIntelligenceDoctrine();

    if (coherenceR < NGI_COHERENCE_GATE) {
      return state;
    };

    // Calculate deviations and apply corrections
    let updatedMetrics = Array.tabulate<BalanceMetric>(state.metrics.size(), func(i) {
      let metric = state.metrics[i];
      let deviation = Float.abs(metric.current - metric.target);
      // Move current toward target at phi^-2 rate
      let correction = (metric.target - metric.current) * NGI_LEARNING_RATE;
      {
        dimension = metric.dimension;
        current   = metric.current + correction;
        target    = metric.target;
        deviation = deviation;
      }
    });

    // Calculate system stability as inverse of average deviation
    var totalDeviation : Float = 0.0;
    for (metric in updatedMetrics.vals()) {
      totalDeviation += metric.deviation;
    };
    let avgDeviation = totalDeviation / updatedMetrics.size().toFloat();
    let stability = Float.max(Phi.S0, 1.0 - avgDeviation);

    {
      metrics         = updatedMetrics;
      adjustmentCount = state.adjustmentCount + 1;
      systemStability = stability;
      lastBalanceBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 6 — PROTECTOR — THE GUARDIAN
  // Shields against adversarial inputs and maintains integrity.
  // ═══════════════════════════════════════════════════════════════════════════

  public func protectorTick(state : ProtectorState, beat : Int, coherenceR : Float) : ProtectorState {
    assert verifyIntelligenceDoctrine();

    // Shield strength regenerates at phi^-2 rate when coherence is high
    let shieldRegen = if (coherenceR >= Phi.R_OMNIS) {
      NGI_LEARNING_RATE * 0.1
    } else if (coherenceR >= NGI_COHERENCE_GATE) {
      NGI_LEARNING_RATE * 0.01
    } else {
      0.0
    };

    let newShieldStrength = Float.min(1.0, state.shieldStrength + shieldRegen);

    {
      threats        = state.threats;
      totalBlocked   = state.totalBlocked;
      shieldStrength = newShieldStrength;
      lastGuardBeat  = beat;
    }
  };

  public func detectThreat(state : ProtectorState, threatId : Text, threatType : Text, severity : Float, beat : Int) : ProtectorState {
    // Threat is mitigated if shield strength exceeds severity
    let mitigated = state.shieldStrength > severity;

    let record : ThreatRecord = {
      threatId     = threatId;
      threatType   = threatType;
      severity     = severity;
      mitigated    = mitigated;
      detectedBeat = beat;
    };

    // Shield takes damage from unmitigated threats
    let shieldDamage = if (mitigated) { 0.0 } else { severity * 0.1 };
    let newShield = Float.max(Phi.S0, state.shieldStrength - shieldDamage);

    {
      threats        = Array.append(state.threats, [record]);
      totalBlocked   = if (mitigated) { state.totalBlocked + 1 } else { state.totalBlocked };
      shieldStrength = newShield;
      lastGuardBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCRIPT 7 — EXECUTOR — THE DOER
  // Transforms cognition into sovereign action.
  // ═══════════════════════════════════════════════════════════════════════════

  public func executorTick(state : ExecutorState, beat : Int, coherenceR : Float) : ExecutorState {
    assert verifyIntelligenceDoctrine();

    // Update success rate based on coherence
    let successBoost = if (coherenceR >= Phi.R_OMNIS) {
      0.001
    } else if (coherenceR >= NGI_COHERENCE_GATE) {
      0.0001
    } else {
      -0.0001  // Slight decay when incoherent
    };

    let newSuccessRate = Float.max(Phi.S0, Float.min(1.0, state.successRate + successBoost));

    {
      actions         = state.actions;
      totalExecuted   = state.totalExecuted;
      successRate     = newSuccessRate;
      lastExecuteBeat = beat;
    }
  };

  public func executeAction(state : ExecutorState, actionId : Text, actionType : Text, input : Text, output : Text, success : Bool, beat : Int) : ExecutorState {
    let record : ActionRecord = {
      actionId   = actionId;
      actionType = actionType;
      input      = input;
      output     = output;
      success    = success;
      beat       = beat;
    };

    // Update success rate with new action result
    let totalActions = state.totalExecuted + 1;
    let successes = (state.successRate * state.totalExecuted.toFloat()) + (if (success) { 1.0 } else { 0.0 });
    let newSuccessRate = successes / totalActions.toFloat();

    {
      actions         = Array.append(state.actions, [record]);
      totalExecuted   = totalActions;
      successRate     = newSuccessRate;
      lastExecuteBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MASTER TICK — runs all seven NGI scripts
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickNgi(state : NgiState, beat : Int, coherenceR : Float) : NgiState {
    {
      praeceptor = praeceptorTick(state.praeceptor, beat, coherenceR);
      cogitator  = cogitatorTick(state.cogitator, beat, coherenceR);
      integrator = integratorTick(state.integrator, beat, coherenceR);
      revelator  = revelatorTick(state.revelator, beat, coherenceR);
      moderator  = moderatorTick(state.moderator, beat, coherenceR);
      protector  = protectorTick(state.protector, beat, coherenceR);
      executor   = executorTick(state.executor, beat, coherenceR);
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS — read-only access to NGI state
  // ═══════════════════════════════════════════════════════════════════════════

  public func getSkills(state : NgiState) : [Skill] {
    state.praeceptor.skills
  };

  public func getReasoningChains(state : NgiState) : [ReasoningChain] {
    state.cogitator.activeChains
  };

  public func getPatterns(state : NgiState) : [PatternRecord] {
    state.revelator.patterns
  };

  public func getSystemStability(state : NgiState) : Float {
    state.moderator.systemStability
  };

  public func getShieldStrength(state : NgiState) : Float {
    state.protector.shieldStrength
  };

  public func getSuccessRate(state : NgiState) : Float {
    state.executor.successRate
  };

};
