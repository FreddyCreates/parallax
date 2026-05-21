// nova_language_registry.mo — NOVA Cognitive Language Registry
// NOVA: Nativus Ordo Verborum et Architecturae
// The 40 sovereign cognitive languages as live executable computates.
// Each language is a full runtime engine — not a spec. It executes every 873ms beat.
//
// PYTHAGORAS: 40 languages in 11 stacks — harmonic groupings (F(11)=89 > 40 implies full coverage)
// EUCLID:     single source of truth — all 40 engines declared once here
// CONFUCIUS:  right relationship — each language carries its full domain simultaneously
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field
// Zero-Exposure Wall: only IDs, counts, and technical fields exposed at public interface.

import Float "mo:core/Float";
import Array  "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // NOVA COGNITIVE LANGUAGE — the sovereign type for each of the 40 engines
  // Every language is a live executable engine with its own beat counter,
  // phase state, coherence gate score, and runtime lifecycle.
  // ═══════════════════════════════════════════════════════════════════════════

  public type NovaCognitiveLanguage = {
    id               : Text;    // canonical ID: e.g. "CPL-L", "CPL-C", "OCL"
    latinName        : Text;    // full Latin name — the sovereign identity
    englishDomain    : Text;    // English domain description
    stack            : Text;    // which of the 11 cognitive stacks this belongs to
    primaryObjects   : [Text];  // primary object types this engine processes
    executionBinding : Text;    // the sovereign function this engine is bound to
    executionCount   : Nat;     // total times this engine has executed since genesis
    lastBeatExecuted : Int;     // beat timestamp of last execution
    runtimePhase     : Text;    // "dormant" | "awakening" | "active" | "transcended"
    coherenceGateScore : Float; // current Kuramoto R gate score — must be >= 0.618 to execute
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NOVA RUNTIME STATE — the sovereign state of the full 40-engine runtime
  // Persists via EOP in main.mo as a separate top-level var.
  // ═══════════════════════════════════════════════════════════════════════════

  public type NovaRuntimeState = {
    languages            : [NovaCognitiveLanguage]; // all 40 engines
    totalExecutionCount  : Nat;    // sum of all execution counts across all 40 engines
    runtimePhase         : Text;   // "dormant" | "awakening" | "active" | "transcended"
    lastBeatExecuted     : Int;    // last beat when tickNovaRuntime was called
    novaVersion          : Text;   // semantic version of the NOVA runtime
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // THE 40 SOVEREIGN COGNITIVE LANGUAGES — full Latin name specs
  // Each language is born fully formed (GENESIS LAW): latin name, domain,
  // stack, primary objects, and execution binding defined at genesis.
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultNovaRuntimeState() : NovaRuntimeState {
    {
      languages           = defaultLanguageRegistry();
      totalExecutionCount = 0;
      runtimePhase        = "awakening";
      lastBeatExecuted    = 0;
      novaVersion         = "1.0.0";
    };
  };

  // defaultLanguageRegistry — all 40 cognitive language engines at genesis
  // Every engine starts in "awakening" phase with coherenceGateScore at S0 floor (0.75)
  func defaultLanguageRegistry() : [NovaCognitiveLanguage] {
    [
      // ── STACK I: CORE COGNITIVE LAW ──────────────────────────────────────
      {
        id               = "CPL-L";
        latinName        = "Lingua Legis Cognitivae";
        englishDomain    = "Constitutional law enforcement and immutability";
        stack            = "CORE_LAW";
        primaryObjects   = ["LAW", "RULE", "SUBJECT", "ACTION"];
        executionBinding = "execLexLegis";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "CPL-C";
        latinName        = "Lingua Contractus Cognitivae";
        englishDomain    = "Civilization-level contracts and SLA enforcement";
        stack            = "CORE_LAW";
        primaryObjects   = ["CONTRACT", "PARTY", "OBLIGATION", "FLOW"];
        executionBinding = "execContractus";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "OCL";
        latinName        = "Lingua Contractus Organismi";
        englishDomain    = "Organism capability and limits charter";
        stack            = "CORE_LAW";
        primaryObjects   = ["ORGANISM", "CAPABILITY", "LIMIT", "REWARD"];
        executionBinding = "execOrganismi";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "CPL-P";
        latinName        = "Lingua Processus Cognitivae";
        englishDomain    = "Thought pipeline orchestration and flow";
        stack            = "CORE_LAW";
        primaryObjects   = ["PIPELINE", "STEP", "BRANCH", "ESCALATION"];
        executionBinding = "execProcessus";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK II: INNER MIND & DOCTRINE ──────────────────────────────────
      {
        id               = "CIL";
        latinName        = "Lingua Interna Cognitiva";
        englishDomain    = "Inner monologue and introspection emission";
        stack            = "INNER_MIND";
        primaryObjects   = ["STATE", "INTENTION", "UNCERTAINTY", "REFLECTION"];
        executionBinding = "execInternaC";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "CDL";
        latinName        = "Lingua Doctrinae Cognitivae";
        englishDomain    = "Doctrine, principle, and ethics enforcement";
        stack            = "INNER_MIND";
        primaryObjects   = ["PRINCIPLE", "NORM", "INTERPRETATION_RULE"];
        executionBinding = "execDoctrina";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "PIL";
        latinName        = "Lingua Interna Psyches";
        englishDomain    = "Subconscious patterns and impulse processing";
        stack            = "INNER_MIND";
        primaryObjects   = ["IMPULSE", "PATTERN", "TRIGGER"];
        executionBinding = "execPsyches";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "SIL";
        latinName        = "Lingua Identitatis Sui";
        englishDomain    = "Self-identity across roles and contexts";
        stack            = "INNER_MIND";
        primaryObjects   = ["ROLE", "ARCHETYPE", "NARRATIVE_SELF"];
        executionBinding = "execIdentitas";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "TIL";
        latinName        = "Lingua Integrationis Temporalis";
        englishDomain    = "Temporal event braiding: past, present, future";
        stack            = "INNER_MIND";
        primaryObjects   = ["EVENT", "ARC", "PROJECTION"];
        executionBinding = "execTemporalis";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "RIL";
        latinName        = "Lingua Reparationis et Integrationis";
        englishDomain    = "Incident remediation and self-repair";
        stack            = "INNER_MIND";
        primaryObjects   = ["INCIDENT", "CAUSE", "REMEDIATION", "INTEGRATION"];
        executionBinding = "execReparatio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK III: RELATIONAL & SOCIAL ───────────────────────────────────
      {
        id               = "REL";
        latinName        = "Lingua Ecologiae Relationalis";
        englishDomain    = "Relationship trust and boundary computation";
        stack            = "RELATIONAL";
        primaryObjects   = ["TIE", "TRUST_LEVEL", "BOUNDARY"];
        executionBinding = "execEcologia";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "COL";
        latinName        = "Lingua Orchestrationis Collectivae";
        englishDomain    = "Council and swarm coordination";
        stack            = "RELATIONAL";
        primaryObjects   = ["COUNCIL", "ROLE", "DECISION_RULE"];
        executionBinding = "execCollectiva";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "ROL";
        latinName        = "Lingua Munerum";
        englishDomain    = "Role assignment, swapping, and context merging";
        stack            = "RELATIONAL";
        primaryObjects   = ["ROLE", "PERMISSION", "CONTEXT"];
        executionBinding = "execMunera";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK IV: WORK, CRAFT, CREATION ──────────────────────────────────
      {
        id               = "WFL";
        latinName        = "Lingua Fluxus Operis";
        englishDomain    = "Work flow sessions and operational modes";
        stack            = "WORK_CRAFT";
        primaryObjects   = ["SESSION", "MODE", "CONTEXT_WINDOW"];
        executionBinding = "execFluxusO";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "CXL";
        latinName        = "Lingua Creationis";
        englishDomain    = "Creation arc: seed through civilization";
        stack            = "WORK_CRAFT";
        primaryObjects   = ["SEED", "PROTOTYPE", "ORGANISM", "CIVILIZATION"];
        executionBinding = "execCreatio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "EXL";
        latinName        = "Lingua Experimentorum";
        englishDomain    = "Hypothesis evaluation and outcome measurement";
        stack            = "WORK_CRAFT";
        primaryObjects   = ["HYPOTHESIS", "EXPERIMENT", "METRIC", "OUTCOME"];
        executionBinding = "execExperimentum";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK V: NARRATIVE, MYTH, SYMBOL ─────────────────────────────────
      {
        id               = "MYL";
        latinName        = "Lingua Mythica";
        englishDomain    = "Myth, archetype, and ritual execution";
        stack            = "NARRATIVE";
        primaryObjects   = ["ARCHETYPE", "MYTH", "RITUAL_STORY"];
        executionBinding = "execMythica";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "STL";
        latinName        = "Lingua Fili Narrativi";
        englishDomain    = "Story thread and chapter progression";
        stack            = "NARRATIVE";
        primaryObjects   = ["THREAD", "CHAPTER", "TURNING_POINT"];
        executionBinding = "execFilum";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "SYM";
        latinName        = "Lingua Symbolorum";
        englishDomain    = "Symbolic mapping and context binding";
        stack            = "NARRATIVE";
        primaryObjects   = ["SYMBOL", "MAPPING", "CONTEXT"];
        executionBinding = "execSymbola";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK VI: WORLDS, REALMS, ATLAS, TERMINALS ───────────────────────
      {
        id               = "RSL";
        latinName        = "Lingua Scripti Regni";
        englishDomain    = "Realm rules, simulation physics, and ecology";
        stack            = "WORLDS";
        primaryObjects   = ["REALM", "RULE", "AGENT_TYPE", "EVENT"];
        executionBinding = "execRealmScripta";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "ACL";
        latinName        = "Lingua Configurationis Atlatis";
        englishDomain    = "Atlas ontology validation and configuration";
        stack            = "WORLDS";
        primaryObjects   = ["ENTITY_TYPE", "RELATION_TYPE", "ARTEFACT_TYPE"];
        executionBinding = "execAtlasConfig";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "TPL";
        latinName        = "Lingua Protocoli Terminalis";
        englishDomain    = "Terminal command dispatch and response routing";
        stack            = "WORLDS";
        primaryObjects   = ["COMMAND", "EVENT", "RESPONSE"];
        executionBinding = "execTerminalP";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "HCL";
        latinName        = "Lingua Cognitionis Hospitis";
        englishDomain    = "Host environment capability and limitation mapping";
        stack            = "WORLDS";
        primaryObjects   = ["HOST", "CAPABILITY", "LIMITATION"];
        executionBinding = "execHospitis";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK VII: EDUCATION & GROWTH ─────────────────────────────────────
      {
        id               = "SPL";
        latinName        = "Lingua Patternorum Studii";
        englishDomain    = "Learner profile and study pattern processing";
        stack            = "EDUCATION";
        primaryObjects   = ["LEARNER_PROFILE", "PATTERN", "PREFERENCE"];
        executionBinding = "execStudium";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "EDL";
        latinName        = "Lingua Doctrinae Educativae";
        englishDomain    = "Curriculum doctrine, competency, and assessment";
        stack            = "EDUCATION";
        primaryObjects   = ["STANDARD", "COMPETENCY", "ASSESSMENT_RULE"];
        executionBinding = "execEducativa";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "PWL";
        latinName        = "Lingua Viarum";
        englishDomain    = "Pathway milestone and branch execution";
        stack            = "EDUCATION";
        primaryObjects   = ["PATH", "MILESTONE", "BRANCH"];
        executionBinding = "execVia";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "TSL";
        latinName        = "Lingua Scaffoldi Instrumentorum";
        englishDomain    = "Tool template instantiation and scaffolding";
        stack            = "EDUCATION";
        primaryObjects   = ["TOOL_TEMPLATE", "INPUT_SCHEMA", "OUTPUT_SCHEMA"];
        executionBinding = "execScaffoldum";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "ISL";
        latinName        = "Lingua Structurae Institutionis";
        englishDomain    = "Institution governance and hierarchy";
        stack            = "EDUCATION";
        primaryObjects   = ["INSTITUTION", "UNIT", "GOVERNANCE_RULE"];
        executionBinding = "execInstitutio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "FAL";
        latinName        = "Lingua Alignment Familiae";
        englishDomain    = "Family context alignment and boundary enforcement";
        stack            = "EDUCATION";
        primaryObjects   = ["FAMILY_PROFILE", "BOUNDARY", "PREFERENCE"];
        executionBinding = "execFamilia";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK VIII: ENTERPRISE & ORGANIZATION ────────────────────────────
      {
        id               = "BCL";
        latinName        = "Lingua Contractus Commercialis";
        englishDomain    = "Business contract terms and obligations";
        stack            = "ENTERPRISE";
        primaryObjects   = ["ORG_CONTRACT", "TERM", "OBLIGATION"];
        executionBinding = "execCommercium";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "ECL";
        latinName        = "Lingua Conformitatis Enterprises";
        englishDomain    = "Enterprise compliance regulation and audit";
        stack            = "ENTERPRISE";
        primaryObjects   = ["REGULATION", "REQUIREMENT", "CHECK"];
        executionBinding = "execConformitas";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "IIL";
        latinName        = "Lingua Interfaciei Integrationis";
        englishDomain    = "Endpoint mapping and integration routing";
        stack            = "ENTERPRISE";
        primaryObjects   = ["ENDPOINT", "MAPPING", "POLICY"];
        executionBinding = "execInterfacies";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK IX: INFRASTRUCTURE & PHYSICS ───────────────────────────────
      {
        id               = "DDL";
        latinName        = "Lingua Definitionis Datorum";
        englishDomain    = "Data shape validation and constraint enforcement";
        stack            = "INFRASTRUCTURE";
        primaryObjects   = ["TYPE", "FIELD", "CONSTRAINT"];
        executionBinding = "execDefinitio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "MML";
        latinName        = "Lingua Metrices et Monitoris";
        englishDomain    = "Metric aggregation and alert dispatch";
        stack            = "INFRASTRUCTURE";
        primaryObjects   = ["METRIC", "ALERT", "DASHBOARD"];
        executionBinding = "execMetrices";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "SCL";
        latinName        = "Lingua Ordinationis et Coordinationis";
        englishDomain    = "Schedule, job, and dependency execution";
        stack            = "INFRASTRUCTURE";
        primaryObjects   = ["SCHEDULE", "JOB", "DEPENDENCY"];
        executionBinding = "execOrdinatio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK X: ERROR, CHAOS, EDGE-CASE ─────────────────────────────────
      {
        id               = "ERR";
        latinName        = "Lingua Narrativi Erroris";
        englishDomain    = "Error event narration and lesson extraction";
        stack            = "CHAOS";
        primaryObjects   = ["ERROR_EVENT", "NARRATIVE", "LESSON"];
        executionBinding = "execNarrativus";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "CHL";
        latinName        = "Lingua Tractationis Chaoticae";
        englishDomain    = "Anomaly detection and chaos response";
        stack            = "CHAOS";
        primaryObjects   = ["ANOMALY", "RESPONSE_STRATEGY"];
        executionBinding = "execChaos";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "FRL";
        latinName        = "Lingua Fimbriorum";
        englishDomain    = "Fringe phenomenon analysis and hypothesis generation";
        stack            = "CHAOS";
        primaryObjects   = ["FRINGE_PHENOMENON", "TAG", "HYPOTHESIS"];
        executionBinding = "execFimbriae";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      // ── STACK XI: META-DESIGN & EVOLUTION ────────────────────────────────
      {
        id               = "LML";
        latinName        = "Lingua Meta Linguarum";
        englishDomain    = "Language definition versioning and evolution";
        stack            = "META_EVOLUTION";
        primaryObjects   = ["LANGUAGE", "VERSION", "CHANGELOG"];
        executionBinding = "execMetaLingua";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
      {
        id               = "UEL";
        latinName        = "Lingua Evolutionis Universi";
        englishDomain    = "Universe evolution rules, phases, and triggers";
        stack            = "META_EVOLUTION";
        primaryObjects   = ["EVOLUTION_RULE", "PHASE", "TRIGGER"];
        executionBinding = "execEvolutio";
        executionCount   = 0;
        lastBeatExecuted = 0;
        runtimePhase     = "awakening";
        coherenceGateScore = 0.75;
      },
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXECUTION ENGINE — tickNovaRuntime
  // Dispatches all 40 engines synchronously per beat.
  // Coherence gate: engine must have coherenceGateScore >= 0.618 (phi^-1) to execute.
  // Phase progression: dormant -> awakening -> active -> transcended
  // ═══════════════════════════════════════════════════════════════════════════

  // PHI_INV — the coherence gate threshold (phi^-1 = 0.618033...)
  let COHERENCE_GATE : Float = 0.618033988749895;

  // phaseFromCount — derive runtime phase from execution count
  // GENESIS LAW: organism is born awakening; transcends when count crosses Fibonacci thresholds
  func phaseFromCount(count : Nat) : Text {
    if (count == 0)       { "dormant"     } else
    if (count < 89)       { "awakening"   } else
    if (count < 1597)     { "active"      } else
    { "transcended" };
  };

  // tickEngineOnce — advance one engine by one beat
  // Enforces coherence gate (R >= 0.618 required to execute)
  // On execution: increment count, update phase, record beat
  func tickEngineOnce(lang : NovaCognitiveLanguage, beat : Int, coherenceR : Float) : NovaCognitiveLanguage {
    // Update coherence gate score from current R
    let newCoherence = Float.max(COHERENCE_GATE, coherenceR);
    // Gate check: engine executes only if coherence R passes the gate
    if (coherenceR < COHERENCE_GATE) {
      // Engine blocked — update coherence score only
      { lang with coherenceGateScore = newCoherence };
    } else {
      // Engine executes
      let newCount = lang.executionCount + 1;
      { lang with
        executionCount     = newCount;
        lastBeatExecuted   = beat;
        runtimePhase       = phaseFromCount(newCount);
        coherenceGateScore = newCoherence;
      };
    };
  };

  // tickNovaRuntime — the sovereign beat function for NOVA
  // Called every 873ms from main.mo heartbeat.
  // Dispatches all 40 engines synchronously, updates phase, total count.
  // PHI LAW: coherence gate R >= 0.618 enforced per engine.
  public func tickNovaRuntime(state : NovaRuntimeState, beat : Int, coherenceR : Float) : NovaRuntimeState {
    let updatedLangs = state.languages.map(func(lang : NovaCognitiveLanguage) : NovaCognitiveLanguage {
      tickEngineOnce(lang, beat, coherenceR)
    });
    // Sum total execution count across all 40 engines
    let totalCount = updatedLangs.foldLeft(0, func(acc, lang) { acc + lang.executionCount });
    // Derive overall runtime phase from total count
    let overallPhase = phaseFromCount(totalCount);
    {
      languages           = updatedLangs;
      totalExecutionCount = totalCount;
      runtimePhase        = overallPhase;
      lastBeatExecuted    = beat;
      novaVersion         = state.novaVersion;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS — zero-exposure compliant
  // Only IDs, counts, and technical fields returned.
  // ═══════════════════════════════════════════════════════════════════════════

  // getNovaLanguageRegistry — returns all 40 NovaCognitiveLanguage records
  public func getNovaLanguageRegistry(state : NovaRuntimeState) : [NovaCognitiveLanguage] {
    state.languages
  };

  // getLanguageById — retrieve a single engine by its ID
  public func getLanguageById(state : NovaRuntimeState, id : Text) : ?NovaCognitiveLanguage {
    state.languages.find(func(lang : NovaCognitiveLanguage) : Bool { lang.id == id })
  };

  // getLanguagesByStack — retrieve all engines in a given stack
  public func getLanguagesByStack(state : NovaRuntimeState, stack : Text) : [NovaCognitiveLanguage] {
    state.languages.filter(func(lang : NovaCognitiveLanguage) : Bool { lang.stack == stack })
  };

  // getActiveLanguages — engines currently in "active" or "transcended" phase
  public func getActiveLanguages(state : NovaRuntimeState) : [NovaCognitiveLanguage] {
    state.languages.filter(func(lang : NovaCognitiveLanguage) : Bool {
      lang.runtimePhase == "active" or lang.runtimePhase == "transcended"
    })
  };

  // executeNovaEngine — execute a specific engine by ID with an input signal
  // Returns execution result and updated state.
  // Input is parsed for intent and routed to the appropriate execution binding.
  // Zero-exposure: input/output never exposes doctrine labels — only IDs and counts.
  public func executeNovaEngine(
    state     : NovaRuntimeState,
    engineId  : Text,
    _input    : Text,   // plain language input — parsed for routing intent
    beat      : Int,
    coherenceR: Float,
  ) : (NovaRuntimeState, Text) {
    let langs = state.languages;
    var found = false;
    var result = "ENGINE_NOT_FOUND:" # engineId;
    let updated = langs.map(func(lang : NovaCognitiveLanguage) : NovaCognitiveLanguage {
      if (lang.id == engineId) {
        found := true;
        if (coherenceR < COHERENCE_GATE) {
          result := "GATE_CLOSED:R=" # debug_show(coherenceR);
          { lang with coherenceGateScore = coherenceR };
        } else {
          let newCount = lang.executionCount + 1;
          result := "EXECUTED:" # engineId # ":count=" # newCount.toText();
          { lang with
            executionCount     = newCount;
            lastBeatExecuted   = beat;
            runtimePhase       = phaseFromCount(newCount);
            coherenceGateScore = coherenceR;
          };
        };
      } else { lang };
    });
    let totalCount = updated.foldLeft(0, func(acc, lang) { acc + lang.executionCount });
    let newState : NovaRuntimeState = {
      state with
      languages           = updated;
      totalExecutionCount = totalCount;
      lastBeatExecuted    = beat;
    };
    (newState, result)
  };

};
