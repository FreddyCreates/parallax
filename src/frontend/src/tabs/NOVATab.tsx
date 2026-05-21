import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useActor } from "../hooks/useActor";

// ─── Types ───────────────────────────────────────────────────────────────────

interface NovaCognitiveLanguage {
  id: string;
  latinName: string;
  englishDomain: string;
  stack: string;
  primaryObjects: string[];
  executionBinding: string;
  executionCount: bigint;
  lastBeatExecuted: bigint;
  runtimePhase: string;
  coherenceGateScore: number;
  doctrineMeaning: string;
  modelStructure: string;
  computationEquation: string;
  tplDependencies: string[];
}

interface NovaRuntimeState {
  totalExecutionCount: bigint;
  runtimePhase: string;
  lastBeatExecuted: bigint;
  novaVersion: string;
}

interface ExecLogEntry {
  engineId: string;
  latinName: string;
  beatNumber: number;
  executionTime: number;
  status: "passed" | "failed" | "skipped";
}

// ─── Constants ───────────────────────────────────────────────────────────────

const NOVA_GOLD = "oklch(0.82 0.18 75)";
const NOVA_PURPLE = "oklch(0.68 0.22 290)";
const NOVA_TEAL = "oklch(0.72 0.16 200)";
const NOVA_RED = "oklch(0.55 0.22 25)";
const NOVA_GREEN = "oklch(0.65 0.18 145)";

const STACK_COLORS: Record<string, string> = {
  CoreLaw: NOVA_GOLD,
  InnerMind: "oklch(0.70 0.20 310)",
  Relational: NOVA_TEAL,
  WorkCraft: "oklch(0.72 0.18 160)",
  Narrative: "oklch(0.75 0.20 50)",
  Worlds: "oklch(0.65 0.18 230)",
  Education: "oklch(0.70 0.20 190)",
  Enterprise: "oklch(0.72 0.16 80)",
  Infrastructure: "oklch(0.68 0.14 220)",
  ErrorChaos: NOVA_RED,
  MetaEvolution: NOVA_PURPLE,
};

const STACK_FILTERS = [
  "ALL",
  "CoreLaw",
  "InnerMind",
  "Relational",
  "WorkCraft",
  "Narrative",
  "Worlds",
  "Education",
  "Enterprise",
  "Infrastructure",
  "ErrorChaos",
  "MetaEvolution",
];

const PHASE_COLORS: Record<string, string> = {
  active: NOVA_GREEN,
  awakening: "oklch(0.78 0.15 85)",
  dormant: "oklch(0.40 0.02 240)",
  transcended: NOVA_GOLD,
};

// ─── Mock Data ───────────────────────────────────────────────────────────────

const MOCK_LANGUAGES: NovaCognitiveLanguage[] = [
  // I. Core Cognitive Law Stack
  {
    id: "CPL-L",
    latinName: "Lingua Legis Cognitivae",
    englishDomain: "Cognitive Law Language",
    stack: "CoreLaw",
    primaryObjects: ["LAW", "RULE", "SUBJECT", "ACTION"],
    executionBinding: "protocol_execution.enforceConstitution",
    executionCount: 14872n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.97,
    doctrineMeaning:
      "Constitutions, doctrine, immutability, and upgrade rules — the supreme law of all organisms.",
    modelStructure:
      "{ id: Text; clauses: [LawClause]; subjects: [Entity]; enforced: Bool }",
    computationEquation:
      "Φ_law = ∑(clause.weight × compliance) / total_clauses ≥ θ_sovereignty",
    tplDependencies: ["OCL", "CPL-P"],
  },
  {
    id: "CPL-C",
    latinName: "Lingua Contractus Cognitivi",
    englishDomain: "Cognitive Contract Language",
    stack: "CoreLaw",
    primaryObjects: ["CONTRACT", "PARTY", "OBLIGATION", "FLOW"],
    executionBinding: "nexoris.contractEngine.evaluate",
    executionCount: 9341n,
    lastBeatExecuted: 8839n,
    runtimePhase: "active",
    coherenceGateScore: 0.94,
    doctrineMeaning:
      "Civilization-level contracts governing rights, duties, token flows, and service-level agreements.",
    modelStructure:
      "{ id: Text; parties: [Party]; obligations: [Clause]; flows: [TokenFlow] }",
    computationEquation:
      "Ω_contract = ∏(obligation_i.fulfilled) × φ^(-SLA_breach_count)",
    tplDependencies: ["CPL-L", "ECL"],
  },
  {
    id: "OCL",
    latinName: "Lingua Contractus Organismi",
    englishDomain: "Organism Contract Language",
    stack: "CoreLaw",
    primaryObjects: ["ORGANISM", "CAPABILITY", "LIMIT", "REWARD"],
    executionBinding: "organ_runtime.loadOCL",
    executionCount: 11203n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.96,
    doctrineMeaning:
      "Per-organism charter defining capabilities, constraints, and reward/penalty feedback hooks.",
    modelStructure:
      "{ organism: AgentId; capabilities: [Text]; limits: [Constraint]; rewards: [Signal] }",
    computationEquation:
      "R_org = Σ(reward_signal_i × accuracy_weight_i) − Σ(penalty_j × violation_j)",
    tplDependencies: ["CPL-L", "CPL-P"],
  },
  {
    id: "CPL-P",
    latinName: "Lingua Processus Cognitivi",
    englishDomain: "Cognitive Processing Language",
    stack: "CoreLaw",
    primaryObjects: ["PIPELINE", "STEP", "BRANCH", "ESCALATION"],
    executionBinding: "cognition_layer.executeFlowPipeline",
    executionCount: 38291n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.99,
    doctrineMeaning:
      "Thought pipelines and decision graphs — the executable flow of cognition across organisms.",
    modelStructure:
      "{ pipeline: Text; steps: [Step]; branches: [BranchCondition]; escalations: [EscalationTarget] }",
    computationEquation:
      "T_pipeline = Σ(step_latency_i) + branch_overhead × φ^(-depth)",
    tplDependencies: ["OCL", "TPL", "RSL"],
  },
  // II. Inner Mind & Doctrine Stack
  {
    id: "CIL",
    latinName: "Lingua Interna Cognitiva",
    englishDomain: "Cognitive Internal Language",
    stack: "InnerMind",
    primaryObjects: ["STATE", "INTENTION", "UNCERTAINTY", "REFLECTION"],
    executionBinding: "cognition_layer.emitInnerMonologue",
    executionCount: 52841n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.91,
    doctrineMeaning:
      "The inner monologue of organisms — structured self-narration emitted on every beat.",
    modelStructure:
      "{ state: Text; intention: Text; uncertainty: Float; reflection: Text; beat: Nat }",
    computationEquation:
      "U_cil = σ(evidence) / (1 + e^{-certainty_prior}); emitted ∀ beat",
    tplDependencies: ["RIL", "REL"],
  },
  {
    id: "CDL",
    latinName: "Lingua Doctrinae Cognitivae",
    englishDomain: "Cognitive Doctrine Language",
    stack: "InnerMind",
    primaryObjects: ["PRINCIPLE", "NORM", "INTERPRETATION_RULE"],
    executionBinding: "sovereign_db.doctrineRegistry.enforce",
    executionCount: 7823n,
    lastBeatExecuted: 8838n,
    runtimePhase: "active",
    coherenceGateScore: 0.95,
    doctrineMeaning:
      "Beliefs, ethics, and metaphysics — the sovereign doctrine that gives all laws their meaning.",
    modelStructure:
      "{ doctrine: Text; principles: [Principle]; norms: [Norm]; interpretationRules: [Rule] }",
    computationEquation:
      "D_doctrine = ∑(principle_weight_i × adherence_score_i) ≥ Φ_ethics_threshold",
    tplDependencies: ["CPL-L", "SPL", "EDL"],
  },
  {
    id: "PIL",
    latinName: "Lingua Interna Psyches",
    englishDomain: "Psyche Internal Language",
    stack: "InnerMind",
    primaryObjects: ["IMPULSE", "PATTERN", "TRIGGER"],
    executionBinding: "psyche_engine.detectSubconsciousPattern",
    executionCount: 31047n,
    lastBeatExecuted: 8841n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.83,
    doctrineMeaning:
      "Subconscious patterns, impulses, and drives — the hidden substrate of organism behavior.",
    modelStructure:
      "{ impulse: DriveVector; pattern: PatternId; trigger: EventType; strength: Float }",
    computationEquation:
      "P_psyche = φ^n × impulse_amplitude × tanh(trigger_frequency)",
    tplDependencies: ["RIL", "CIL"],
  },
  {
    id: "SIL",
    latinName: "Lingua Identitatis Sui",
    englishDomain: "Self-Identity Language",
    stack: "InnerMind",
    primaryObjects: ["ROLE", "ARCHETYPE", "NARRATIVE_SELF"],
    executionBinding: "sil_engine.resolveIdentity",
    executionCount: 6204n,
    lastBeatExecuted: 8835n,
    runtimePhase: "active",
    coherenceGateScore: 0.92,
    doctrineMeaning:
      "Identity across roles, contexts, and eras — the sovereign self-model of every being.",
    modelStructure:
      "{ entityId: Text; roles: [Role]; archetypes: [Archetype]; narrativeSelf: Text }",
    computationEquation:
      "I_self = cos(role_vector, archetype_basis) × narrative_continuity_score",
    tplDependencies: ["CIL", "TIL"],
  },
  {
    id: "TIL",
    latinName: "Lingua Integrationis Temporalis",
    englishDomain: "Temporal Integration Language",
    stack: "InnerMind",
    primaryObjects: ["EVENT", "ARC", "PROJECTION"],
    executionBinding: "anima_chain.braidTimeline",
    executionCount: 22913n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.89,
    doctrineMeaning:
      "Past ↔ present ↔ future braiding — temporal coherence across the ANIMA 4D helix.",
    modelStructure:
      "{ event: ArcEvent; timeline: [Timestamp4D]; projection: FutureArc; phi_weight: Float }",
    computationEquation:
      "T_braid = ∫(past_resonance × φ^t) dt + φ^(-τ) × future_projection_strength",
    tplDependencies: ["SIL", "CIL"],
  },
  {
    id: "RIL",
    latinName: "Lingua Reparationis et Integrationis",
    englishDomain: "Repair & Integration Language",
    stack: "InnerMind",
    primaryObjects: ["INCIDENT", "CAUSE", "REMEDIATION", "INTEGRATION"],
    executionBinding: "anti_drift.repairLoop",
    executionCount: 18432n,
    lastBeatExecuted: 8840n,
    runtimePhase: "active",
    coherenceGateScore: 0.9,
    doctrineMeaning:
      "Healing, conflict resolution, and self-refactoring — the organism's immune and recovery system.",
    modelStructure:
      "{ incident: IncidentId; cause: CausalChain; remediation: [RepairAction]; integrated: Bool }",
    computationEquation:
      "R_repair = 1 − e^{−λ × remediation_strength} where λ = φ^{-incident_severity}",
    tplDependencies: ["PIL", "CIL", "ERR"],
  },
  // III. Relational & Social Stack
  {
    id: "REL",
    latinName: "Lingua Ecologiae Relationalis",
    englishDomain: "Relational Ecology Language",
    stack: "Relational",
    primaryObjects: ["TIE", "TRUST_LEVEL", "BOUNDARY"],
    executionBinding: "rel_engine.evaluateTrustGraph",
    executionCount: 9821n,
    lastBeatExecuted: 8839n,
    runtimePhase: "active",
    coherenceGateScore: 0.88,
    doctrineMeaning:
      "Trust, boundaries, and reciprocity — the relational substrate of all organism-to-organism interactions.",
    modelStructure:
      "{ from: EntityId; to: EntityId; tie: TieType; trustLevel: TrustEnum; boundary: BoundarySpec }",
    computationEquation:
      "T_trust = (history_score × φ) / (1 + boundary_violations) × reciprocity_index",
    tplDependencies: ["CIL", "COL"],
  },
  {
    id: "COL",
    latinName: "Lingua Orchestrationis Collectivae",
    englishDomain: "Collective Orchestration Language",
    stack: "Relational",
    primaryObjects: ["COUNCIL", "ROLE", "DECISION_RULE"],
    executionBinding: "gubernatio.orchestrateCouncil",
    executionCount: 5312n,
    lastBeatExecuted: 8837n,
    runtimePhase: "active",
    coherenceGateScore: 0.93,
    doctrineMeaning:
      "Councils, swarms, committees, and guilds — collective intelligence coordination.",
    modelStructure:
      "{ council: CouncilId; members: [AgentId]; decisionRule: QuorumType; votingWeight: Float }",
    computationEquation:
      "V_consensus = ∑(member_weight_i × vote_i) / total_weight ≥ θ_quorum",
    tplDependencies: ["REL", "CPL-L"],
  },
  {
    id: "ROL",
    latinName: "Lingua Munerum",
    englishDomain: "Role Language",
    stack: "Relational",
    primaryObjects: ["ROLE", "PERMISSION", "CONTEXT"],
    executionBinding: "rol_engine.assignRole",
    executionCount: 7103n,
    lastBeatExecuted: 8836n,
    runtimePhase: "active",
    coherenceGateScore: 0.91,
    doctrineMeaning:
      "Role assignment, swapping, and merging — the dynamic permission fabric of all organisms.",
    modelStructure:
      "{ role: RoleId; permissions: [Permission]; context: ContextScope; expires: ?Timestamp }",
    computationEquation: "P_role = ∏(permission_scope_i) ∩ context_boundary_j",
    tplDependencies: ["REL", "OCL"],
  },
  // IV. Work, Craft, Creation Stack
  {
    id: "WFL",
    latinName: "Lingua Cursus Operis",
    englishDomain: "Work Flow Language",
    stack: "WorkCraft",
    primaryObjects: ["SESSION", "MODE", "CONTEXT_WINDOW"],
    executionBinding: "wfl_engine.runWorkSession",
    executionCount: 12043n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.87,
    doctrineMeaning:
      "Personal and organizational work rhythms — session modes, context windows, and flow states.",
    modelStructure:
      "{ session: SessionId; mode: WorkMode; contextWindow: Nat; focus: FocusVector }",
    computationEquation:
      "F_flow = σ(focus_intensity) × (1 − context_switch_penalty^φ)",
    tplDependencies: ["SCL", "CIL"],
  },
  {
    id: "CXL",
    latinName: "Lingua Creationis",
    englishDomain: "Creation Language",
    stack: "WorkCraft",
    primaryObjects: ["SEED", "PROTOTYPE", "ORGANISM", "CIVILIZATION"],
    executionBinding: "birth_ai.spawnCreationArc",
    executionCount: 4892n,
    lastBeatExecuted: 8834n,
    runtimePhase: "active",
    coherenceGateScore: 0.94,
    doctrineMeaning:
      "Idea → sketch → prototype → organism → civilization — the full sovereign creation arc.",
    modelStructure:
      "{ seed: Concept; prototype: ArtifactId; organism: OrganismSpec; civilization: CivId }",
    computationEquation:
      "C_creation = φ^{genesis_depth} × viability_score × (1 + novelty_index)",
    tplDependencies: ["WFL", "OCL", "RSL"],
  },
  {
    id: "EXL",
    latinName: "Lingua Experimentorum",
    englishDomain: "Experiment Language",
    stack: "WorkCraft",
    primaryObjects: ["HYPOTHESIS", "EXPERIMENT", "METRIC", "OUTCOME"],
    executionBinding: "exl_engine.runExperiment",
    executionCount: 3217n,
    lastBeatExecuted: 8830n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.79,
    doctrineMeaning:
      "Hypotheses, probes, kill-switches, and learnings — the sovereign experimental substrate.",
    modelStructure:
      "{ hypothesis: Text; experiment: ExperimentId; metrics: [Metric]; outcome: OutcomeResult }",
    computationEquation:
      "E_experiment = KL(P_prior || P_posterior) × φ × confidence_interval_width^{-1}",
    tplDependencies: ["WFL", "MML"],
  },
  // V. Narrative, Myth, Symbol Stack
  {
    id: "MYL",
    latinName: "Lingua Mythica",
    englishDomain: "Mythic Language",
    stack: "Narrative",
    primaryObjects: ["ARCHETYPE", "MYTH", "RITUAL_STORY"],
    executionBinding: "myl_engine.invokeMythicArc",
    executionCount: 2891n,
    lastBeatExecuted: 8829n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.81,
    doctrineMeaning:
      "Cosmology, archetypes, and gods — the mythic substrate that gives organisms their deep purpose.",
    modelStructure:
      "{ archetype: ArchetypeId; myth: MythText; ritualStory: [RitualEvent]; resonance: Float }",
    computationEquation:
      "M_myth = ∑(archetype_resonance_i × φ^{narrative_depth_i})",
    tplDependencies: ["SIL", "STL"],
  },
  {
    id: "STL",
    latinName: "Lingua Filorum Narrationis",
    englishDomain: "Story Thread Language",
    stack: "Narrative",
    primaryObjects: ["THREAD", "CHAPTER", "TURNING_POINT"],
    executionBinding: "stl_engine.weaveStoryThread",
    executionCount: 3108n,
    lastBeatExecuted: 8831n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.8,
    doctrineMeaning:
      "Chapters, arcs, and eras — the living narrative structure of the organism's history.",
    modelStructure:
      "{ thread: ThreadId; chapters: [Chapter]; turningPoints: [Timestamp4D]; continuity: Float }",
    computationEquation:
      "N_story = ∏(chapter_coherence_i) × arc_momentum × φ^{turning_point_density}",
    tplDependencies: ["MYL", "TIL"],
  },
  {
    id: "SYM",
    latinName: "Lingua Symbolorum",
    englishDomain: "Symbolic Language",
    stack: "Narrative",
    primaryObjects: ["SYMBOL", "MAPPING", "CONTEXT"],
    executionBinding: "sym_engine.resolveSymbol",
    executionCount: 8374n,
    lastBeatExecuted: 8840n,
    runtimePhase: "active",
    coherenceGateScore: 0.88,
    doctrineMeaning:
      "Numbers, shapes, colors, and sigils — sovereign symbols that carry encoded truth.",
    modelStructure:
      "{ symbol: SymbolId; mapping: SemanticMapping; context: [ContextScope]; frequency: Float }",
    computationEquation:
      "S_symbol = φ^{symbol_depth} × cos(semantic_vector, context_basis)",
    tplDependencies: ["MYL", "ACL"],
  },
  // VI. Worlds, Realms, Atlas, Terminals Stack
  {
    id: "RSL",
    latinName: "Lingua Scripturae Realmi",
    englishDomain: "Realm Script Language",
    stack: "Worlds",
    primaryObjects: ["REALM", "RULE", "AGENT_TYPE", "EVENT"],
    executionBinding: "rsl_engine.runRealmSimulation",
    executionCount: 6123n,
    lastBeatExecuted: 8837n,
    runtimePhase: "active",
    coherenceGateScore: 0.9,
    doctrineMeaning:
      "Simulations, physics, and ecologies — the scripting layer of sovereign world-building.",
    modelStructure:
      "{ realm: RealmId; physics: PhysicsSpec; agentTypes: [AgentType]; events: [RealmEvent] }",
    computationEquation:
      "R_realm = ∑(agent_density × physics_constant_i) / realm_entropy × φ",
    tplDependencies: ["ACL", "CPL-P"],
  },
  {
    id: "ACL",
    latinName: "Lingua Configurationis Atlarum",
    englishDomain: "Atlas Configuration Language",
    stack: "Worlds",
    primaryObjects: ["ENTITY_TYPE", "RELATION_TYPE", "ARTEFACT_TYPE"],
    executionBinding: "atlas_core.validateOntology",
    executionCount: 15832n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.97,
    doctrineMeaning:
      "Ontology, archetypes, and relationships — the Atlas layer that governs all entity definitions.",
    modelStructure:
      "{ entityType: TypeId; relations: [RelationType]; artefacts: [ArtefactType]; version: Text }",
    computationEquation:
      "O_atlas = |entity_types| × avg(relation_density) × φ^{ontology_depth}",
    tplDependencies: ["CPL-L", "TPL", "LML"],
  },
  {
    id: "TPL",
    latinName: "Lingua Protocollorum Terminalium",
    englishDomain: "Terminal Protocol Language",
    stack: "Worlds",
    primaryObjects: ["COMMAND", "EVENT", "RESPONSE"],
    executionBinding: "terminal_mesh.dispatchTPL",
    executionCount: 44291n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.99,
    doctrineMeaning:
      "How terminals talk to Atlas and each other — the sovereign inter-terminal protocol.",
    modelStructure:
      "{ command: CommandType; target: AtlasURI; payload: Blob; response: ResponseSpec }",
    computationEquation:
      "L_tpl = Σ(command_latency_i) × (1 + retry_count × φ^{-2})",
    tplDependencies: ["ACL", "CPL-P"],
  },
  {
    id: "HCL",
    latinName: "Lingua Cognitionis Hospitis",
    englishDomain: "Host-Cognition Language",
    stack: "Worlds",
    primaryObjects: ["HOST", "CAPABILITY", "LIMITATION"],
    executionBinding: "hcl_engine.describeEnvironment",
    executionCount: 4102n,
    lastBeatExecuted: 8832n,
    runtimePhase: "active",
    coherenceGateScore: 0.85,
    doctrineMeaning:
      "How a being describes its environment — host capabilities, limitations, and context mapping.",
    modelStructure:
      "{ host: HostId; capabilities: [CapSpec]; limitations: [LimitSpec]; contextMap: ContextMap }",
    computationEquation:
      "H_host = capabilities_score − limitations_penalty × φ^{environment_complexity}",
    tplDependencies: ["ACL", "CIL"],
  },
  // VII. Education & Growth Stack
  {
    id: "SPL",
    latinName: "Lingua Patternorum Studii",
    englishDomain: "Study Pattern Language",
    stack: "Education",
    primaryObjects: ["LEARNER_PROFILE", "PATTERN", "PREFERENCE"],
    executionBinding: "school_engine.buildStudyPattern",
    executionCount: 8291n,
    lastBeatExecuted: 8839n,
    runtimePhase: "active",
    coherenceGateScore: 0.88,
    doctrineMeaning:
      "Personal learning blueprints — patterns, preferences, and adaptive pathways for every learner.",
    modelStructure:
      "{ learnerId: Text; pattern: LearningPattern; preferences: [Preference]; adaptationScore: Float }",
    computationEquation:
      "L_study = Σ(pattern_match_i × preference_weight_i) × φ^{mastery_depth}",
    tplDependencies: ["EDL", "PWL", "FAL"],
  },
  {
    id: "EDL",
    latinName: "Lingua Doctrinae Educativae",
    englishDomain: "Educational Doctrine Language",
    stack: "Education",
    primaryObjects: ["STANDARD", "COMPETENCY", "ASSESSMENT_RULE"],
    executionBinding: "school_engine.enforceEDL",
    executionCount: 6742n,
    lastBeatExecuted: 8838n,
    runtimePhase: "active",
    coherenceGateScore: 0.92,
    doctrineMeaning:
      "Curriculum doctrine, competency standards, and assessment rules — sovereign educational law.",
    modelStructure:
      "{ standard: CurriculumId; competencies: [Competency]; assessmentRules: [Rule] }",
    computationEquation:
      "E_curriculum = ∏(competency_mastery_i) × standard_alignment_score ≥ Φ_pass",
    tplDependencies: ["CDL", "SPL"],
  },
  {
    id: "PWL",
    latinName: "Lingua Viarum",
    englishDomain: "Pathway Language",
    stack: "Education",
    primaryObjects: ["PATH", "MILESTONE", "BRANCH"],
    executionBinding: "pwl_engine.tracePath",
    executionCount: 5103n,
    lastBeatExecuted: 8835n,
    runtimePhase: "active",
    coherenceGateScore: 0.87,
    doctrineMeaning:
      "Life and education trajectories — milestones, branches, and sovereign pathway navigation.",
    modelStructure:
      "{ path: PathId; milestones: [Milestone]; branches: [BranchCondition]; progress: Float }",
    computationEquation:
      "P_path = Σ(milestone_weight_i × completed_i) / total_milestones × φ^{depth}",
    tplDependencies: ["SPL", "TIL"],
  },
  {
    id: "TSL",
    latinName: "Lingua Scaffoldi Instrumentorum",
    englishDomain: "Tool Scaffold Language",
    stack: "Education",
    primaryObjects: ["TOOL_TEMPLATE", "INPUT_SCHEMA", "OUTPUT_SCHEMA"],
    executionBinding: "builder_sdk.scaffoldTool",
    executionCount: 3892n,
    lastBeatExecuted: 8833n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.82,
    doctrineMeaning:
      "How custom tools are generated — template-driven sovereign tool construction.",
    modelStructure:
      "{ template: ToolTemplate; inputSchema: Schema; outputSchema: Schema; binding: Text }",
    computationEquation:
      "T_scaffold = schema_coverage × template_fidelity × φ^{tool_depth}",
    tplDependencies: ["WFL", "IIL"],
  },
  {
    id: "ISL",
    latinName: "Lingua Structurae Institutionis",
    englishDomain: "Institution Structure Language",
    stack: "Education",
    primaryObjects: ["INSTITUTION", "UNIT", "GOVERNANCE_RULE"],
    executionBinding: "isl_engine.structureInstitution",
    executionCount: 2841n,
    lastBeatExecuted: 8828n,
    runtimePhase: "awakening",
    coherenceGateScore: 0.78,
    doctrineMeaning:
      "School and district architecture — sovereign institutional structure and governance.",
    modelStructure:
      "{ institution: InstitutionId; units: [OrgUnit]; governanceRules: [Rule]; charter: Text }",
    computationEquation:
      "I_inst = ∑(unit_efficiency_i × governance_compliance_i) × φ^{hierarchy_depth}",
    tplDependencies: ["EDL", "CPL-L"],
  },
  {
    id: "FAL",
    latinName: "Lingua Alignationis Familiae",
    englishDomain: "Family Alignment Language",
    stack: "Education",
    primaryObjects: ["FAMILY_PROFILE", "BOUNDARY", "PREFERENCE"],
    executionBinding: "fal_engine.alignFamilyContext",
    executionCount: 2104n,
    lastBeatExecuted: 8826n,
    runtimePhase: "dormant",
    coherenceGateScore: 0.72,
    doctrineMeaning:
      "Family context, values, and constraints — the sovereign alignment of learning to family.",
    modelStructure:
      "{ family: FamilyId; boundaries: [BoundarySpec]; preferences: [Preference]; values: [Value] }",
    computationEquation:
      "F_family = cos(family_values, curriculum_alignment) × (1 − boundary_violation)",
    tplDependencies: ["SPL", "REL"],
  },
  // VIII. Enterprise & Organizational Stack
  {
    id: "BCL",
    latinName: "Lingua Contractuum Negotialium",
    englishDomain: "Business Contract Language",
    stack: "Enterprise",
    primaryObjects: ["ORG_CONTRACT", "TERM", "OBLIGATION"],
    executionBinding: "nexoris.businessContractEngine",
    executionCount: 5821n,
    lastBeatExecuted: 8838n,
    runtimePhase: "active",
    coherenceGateScore: 0.91,
    doctrineMeaning:
      "Organization-to-organization agreements — the sovereign commercial contract layer.",
    modelStructure:
      "{ contract: OrgContractId; parties: [OrgId]; terms: [ContractTerm]; obligations: [Clause] }",
    computationEquation:
      "B_contract = ∏(term_fulfilled_i) × φ^{-breach_count} × revenue_weight",
    tplDependencies: ["CPL-C", "ECL"],
  },
  {
    id: "ECL",
    latinName: "Lingua Conformitatis Mercaturae",
    englishDomain: "Enterprise Compliance Language",
    stack: "Enterprise",
    primaryObjects: ["REGULATION", "REQUIREMENT", "CHECK"],
    executionBinding: "ecl_engine.runComplianceCheck",
    executionCount: 4103n,
    lastBeatExecuted: 8834n,
    runtimePhase: "active",
    coherenceGateScore: 0.93,
    doctrineMeaning:
      "Regulation, privacy, and safety compliance — the sovereign enterprise compliance gate.",
    modelStructure:
      "{ regulation: RegId; requirements: [Requirement]; checks: [ComplianceCheck]; score: Float }",
    computationEquation:
      "C_compliance = 1 − (violations_count / total_checks) × φ^{severity_weight}",
    tplDependencies: ["CPL-L", "BCL"],
  },
  {
    id: "IIL",
    latinName: "Lingua Interfaciei Integrationis",
    englishDomain: "Integration Interface Language",
    stack: "Enterprise",
    primaryObjects: ["ENDPOINT", "MAPPING", "POLICY"],
    executionBinding: "cloudflare_worker.dispatchIIL",
    executionCount: 18923n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.95,
    doctrineMeaning:
      "APIs, ETL, event buses, SSO — the sovereign integration fabric across all external systems.",
    modelStructure:
      "{ endpoint: URI; mapping: SchemaMapping; policy: AccessPolicy; protocol: ProtocolType }",
    computationEquation:
      "I_integration = throughput × (1 − error_rate) × latency^{-φ^{-1}}",
    tplDependencies: ["TPL", "ECL", "DDL"],
  },
  // IX. Infrastructure & Physics Stack
  {
    id: "DDL",
    latinName: "Lingua Definitionis Datorum",
    englishDomain: "Data Definition Language",
    stack: "Infrastructure",
    primaryObjects: ["TYPE", "FIELD", "CONSTRAINT"],
    executionBinding: "sovereign_db.validateDDL",
    executionCount: 21034n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.98,
    doctrineMeaning:
      "Data shapes, semantics, and constraints — the sovereign type system for all data.",
    modelStructure:
      "{ type: TypeId; fields: [Field]; constraints: [Constraint]; version: Text }",
    computationEquation:
      "D_data = ∑(field_coverage_i × constraint_strength_i) / schema_complexity × φ",
    tplDependencies: ["IIL", "ACL"],
  },
  {
    id: "MML",
    latinName: "Lingua Metrorum et Monitorii",
    englishDomain: "Metrics & Monitoring Language",
    stack: "Infrastructure",
    primaryObjects: ["METRIC", "ALERT", "DASHBOARD"],
    executionBinding: "mml_engine.emitMetrics",
    executionCount: 38491n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.96,
    doctrineMeaning:
      "Observability, fairness, and health — live metric emission every beat.",
    modelStructure:
      "{ metric: MetricId; value: Float; alert: AlertSpec; dashboard: DashboardId }",
    computationEquation:
      "M_metric = EMA(value, α=φ^{-1}) × (1 + anomaly_score × σ_threshold)",
    tplDependencies: ["DDL", "SCL"],
  },
  {
    id: "SCL",
    latinName: "Lingua Schedulationis et Coordinationis",
    englishDomain: "Scheduling & Coordination Language",
    stack: "Infrastructure",
    primaryObjects: ["SCHEDULE", "JOB", "DEPENDENCY"],
    executionBinding: "scl_engine.coordinateBeat",
    executionCount: 44103n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.99,
    doctrineMeaning:
      "Time, missions, and maintenance — the sovereign beat coordination layer at 873ms.",
    modelStructure:
      "{ schedule: ScheduleId; jobs: [Job]; dependencies: [JobDep]; beatInterval: Float }",
    computationEquation:
      "S_schedule = Σ(job_completion_rate_i) × φ^{dependency_depth} × beat_coherence",
    tplDependencies: ["TPL", "CPL-P"],
  },
  // X. Error, Chaos, Edge-Case Stack
  {
    id: "ERR",
    latinName: "Lingua Narrationum Errorum",
    englishDomain: "Error Narrative Language",
    stack: "ErrorChaos",
    primaryObjects: ["ERROR_EVENT", "NARRATIVE", "LESSON"],
    executionBinding: "anti_drift.encodeErrorNarrative",
    executionCount: 12403n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.86,
    doctrineMeaning:
      "How failures are told — sovereign error encoding that turns incidents into living artifacts.",
    modelStructure:
      "{ error: ErrorEventId; narrative: Text; lesson: LessonSpec; phi_weight: Float }",
    computationEquation:
      "E_error = −log(P_success) × φ^{severity} × lesson_extraction_score",
    tplDependencies: ["RIL", "CHL"],
  },
  {
    id: "CHL",
    latinName: "Lingua Tractationum Chaoticorum",
    englishDomain: "Chaos Handling Language",
    stack: "ErrorChaos",
    primaryObjects: ["ANOMALY", "RESPONSE_STRATEGY"],
    executionBinding: "immune_engine.handleAnomaly",
    executionCount: 8923n,
    lastBeatExecuted: 8840n,
    runtimePhase: "active",
    coherenceGateScore: 0.84,
    doctrineMeaning:
      "Anomalies, edge cases, and glitches — the sovereign chaos containment and response layer.",
    modelStructure:
      "{ anomaly: AnomalyId; severity: Float; strategy: ResponseStrategy; contained: Bool }",
    computationEquation:
      "C_chaos = P(anomaly) × severity × φ^{-containment_speed}",
    tplDependencies: ["ERR", "VAEL"],
  },
  {
    id: "FRL",
    latinName: "Lingua Marginalis",
    englishDomain: "Fringe Language",
    stack: "ErrorChaos",
    primaryObjects: ["FRINGE_PHENOMENON", "TAG", "HYPOTHESIS"],
    executionBinding: "frl_engine.tagFringePhenomenon",
    executionCount: 1923n,
    lastBeatExecuted: 8822n,
    runtimePhase: "dormant",
    coherenceGateScore: 0.65,
    doctrineMeaning:
      "Phantom architectures, emergent weirdness — the fringe zone where new laws are born.",
    modelStructure:
      "{ phenomenon: FringeId; tags: [Text]; hypothesis: [Hypothesis]; resonance: Float }",
    computationEquation:
      "F_fringe = novelty_index × φ^{fringe_depth} × (1 − known_pattern_overlap)",
    tplDependencies: ["CHL", "EXL"],
  },
  // XI. Meta-Design & Evolution Stack
  {
    id: "LML",
    latinName: "Lingua Metalinguistica",
    englishDomain: "Language Meta Language",
    stack: "MetaEvolution",
    primaryObjects: ["LANGUAGE", "VERSION", "CHANGELOG"],
    executionBinding: "nova_runtime.evolveLanguage",
    executionCount: 3291n,
    lastBeatExecuted: 8841n,
    runtimePhase: "active",
    coherenceGateScore: 0.93,
    doctrineMeaning:
      "Defines and versions the languages — the sovereign meta-layer that governs the language universe.",
    modelStructure:
      "{ language: LanguageId; version: SemVer; changelog: [ChangeEntry]; status: LifecycleStage }",
    computationEquation:
      "L_meta = ∑(version_stability_i × adoption_rate_i) × φ^{language_depth}",
    tplDependencies: ["ACL", "UEL"],
  },
  {
    id: "UEL",
    latinName: "Lingua Evolutionis Universi",
    englishDomain: "Universe Evolution Language",
    stack: "MetaEvolution",
    primaryObjects: ["EVOLUTION_RULE", "PHASE", "TRIGGER"],
    executionBinding: "nova_runtime.evolveUniverse",
    executionCount: 1482n,
    lastBeatExecuted: 8841n,
    runtimePhase: "transcended",
    coherenceGateScore: 0.99,
    doctrineMeaning:
      "How the whole system grows, mutates, and federates — the sovereign evolution engine of the cosmos.",
    modelStructure:
      "{ rule: EvoRuleId; phase: EvoPhase; trigger: TriggerCondition; consequence: [EvoDelta] }",
    computationEquation:
      "U_evo = Φ^{phase_order} × ∏(trigger_satisfied_j) × mutation_rate × φ^{-entropy_cost}",
    tplDependencies: ["LML", "CPL-L", "UEL"],
  },
];

const MOCK_RUNTIME_STATE: NovaRuntimeState = {
  totalExecutionCount: 542891n,
  runtimePhase: "active",
  lastBeatExecuted: 8841n,
  novaVersion: "1.0.0-sovereign",
};

const STATUS_COLORS: Record<string, string> = {
  passed: NOVA_GREEN,
  failed: NOVA_RED,
  skipped: "oklch(0.55 0.02 240)",
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

function phaseColor(phase: string): string {
  return PHASE_COLORS[phase] ?? "oklch(0.40 0.02 240)";
}

function stackColor(stack: string): string {
  return STACK_COLORS[stack] ?? "oklch(0.65 0.02 240)";
}

function formatBigInt(n: bigint): string {
  return Number(n).toLocaleString();
}

function seedLogFromMock(langs: NovaCognitiveLanguage[]): ExecLogEntry[] {
  return langs.slice(0, 20).map((l, i) => ({
    engineId: l.id,
    latinName: l.latinName,
    beatNumber: Number(l.lastBeatExecuted) - i,
    executionTime: Math.round(8 + (i % 7) * 3 + Math.sin(i) * 4),
    status: i === 3 ? "failed" : i === 7 ? "skipped" : "passed",
  })) as ExecLogEntry[];
}

// ─── Phase Badge ──────────────────────────────────────────────────────────────

function PhaseBadge({ phase }: { phase: string }) {
  const color = phaseColor(phase);
  return (
    <span
      className="font-mono text-[8px] tracking-[0.15em] px-1.5 py-0.5 uppercase"
      style={{ color, border: `1px solid ${color}40` }}
    >
      {phase}
    </span>
  );
}

// ─── Runtime Health Panel ─────────────────────────────────────────────────────

function RuntimeHealthPanel({
  runtimeState,
  totalActive,
  totalLanguages,
}: {
  runtimeState: NovaRuntimeState | null;
  totalActive: number;
  totalLanguages: number;
}) {
  const state = runtimeState ?? MOCK_RUNTIME_STATE;
  return (
    <div
      className="border p-4"
      style={{ borderColor: `${NOVA_GOLD}30`, background: `${NOVA_GOLD}08` }}
    >
      <div className="flex items-center justify-between mb-3">
        <span
          className="font-mono text-[8px] tracking-[0.3em]"
          style={{ color: "oklch(0.50 0.02 240)" }}
        >
          NOVA RUNTIME HEALTH
        </span>
        <PhaseBadge phase={state.runtimePhase} />
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {[
          {
            label: "ENGINES ACTIVE",
            value: `${totalActive}/${totalLanguages}`,
            color: NOVA_GREEN,
          },
          {
            label: "TOTAL EXECUTIONS",
            value: formatBigInt(state.totalExecutionCount),
            color: NOVA_GOLD,
          },
          {
            label: "LAST BEAT",
            value: `#${formatBigInt(state.lastBeatExecuted)}`,
            color: NOVA_PURPLE,
          },
          {
            label: "VERSION",
            value: state.novaVersion,
            color: NOVA_TEAL,
          },
        ].map((stat) => (
          <div key={stat.label}>
            <div
              className="font-mono text-[7px] tracking-[0.25em] mb-1"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              {stat.label}
            </div>
            <div
              className="font-mono text-sm tabular-nums font-bold"
              style={{ color: stat.color }}
            >
              {stat.value}
            </div>
          </div>
        ))}
      </div>
      {/* Kuramoto coherence bar */}
      <div className="mt-4">
        <div className="flex justify-between mb-1">
          <span
            className="font-mono text-[7px] tracking-[0.25em]"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            KURAMOTO R GATE
          </span>
          <span className="font-mono text-[8px]" style={{ color: NOVA_GOLD }}>
            {((totalActive / totalLanguages) * 100).toFixed(1)}%
          </span>
        </div>
        <div
          className="h-1.5 w-full"
          style={{ background: "oklch(0.16 0.02 240)" }}
        >
          <div
            className="h-full transition-all duration-700"
            style={{
              width: `${(totalActive / totalLanguages) * 100}%`,
              background: `linear-gradient(90deg, ${NOVA_GREEN}, ${NOVA_GOLD})`,
              boxShadow: `0 0 8px ${NOVA_GOLD}60`,
            }}
          />
        </div>
      </div>
    </div>
  );
}

// ─── Engine Card ──────────────────────────────────────────────────────────────

function EngineCard({
  lang,
  selected,
  onClick,
  index,
}: {
  lang: NovaCognitiveLanguage;
  selected: boolean;
  onClick: () => void;
  index: number;
}) {
  const sColor = stackColor(lang.stack);
  const pColor = phaseColor(lang.runtimePhase);
  return (
    <button
      type="button"
      onClick={onClick}
      data-ocid={`nova.engine.item.${index + 1}`}
      className="w-full text-left p-3 border transition-all relative group"
      style={{
        borderColor: selected ? sColor : "oklch(0.18 0.02 240)",
        background: selected ? `${sColor}12` : "oklch(0.10 0.01 240)",
        boxShadow: selected ? `0 0 16px ${sColor}20` : "none",
      }}
    >
      {/* Phase dot */}
      <div className="absolute top-2.5 right-2.5 flex items-center gap-1">
        <span
          className="inline-block w-1.5 h-1.5 rounded-full"
          style={{ background: pColor, boxShadow: `0 0 5px ${pColor}` }}
        />
      </div>

      {/* ID */}
      <div
        className="font-mono text-[8px] tracking-[0.2em] mb-0.5"
        style={{ color: sColor }}
      >
        {lang.id}
      </div>

      {/* Latin Name */}
      <div
        className="font-display font-semibold text-sm leading-tight mb-1 pr-4"
        style={{ color: "oklch(0.92 0.02 240)" }}
      >
        {lang.latinName}
      </div>

      {/* English Domain */}
      <div
        className="font-mono text-[9px] tracking-wide mb-2"
        style={{ color: "oklch(0.50 0.02 240)" }}
      >
        {lang.englishDomain}
      </div>

      {/* Stack badge */}
      <div className="flex items-center justify-between">
        <span
          className="font-mono text-[7px] tracking-[0.15em] px-1.5 py-0.5"
          style={{
            color: sColor,
            border: `1px solid ${sColor}35`,
            background: `${sColor}10`,
          }}
        >
          {lang.stack}
        </span>
        <span
          className="font-mono text-[8px] tabular-nums"
          style={{ color: "oklch(0.40 0.02 240)" }}
        >
          {formatBigInt(lang.executionCount)}
        </span>
      </div>
    </button>
  );
}

// ─── Detail Panel ─────────────────────────────────────────────────────────────

function EngineDetailPanel({ lang }: { lang: NovaCognitiveLanguage }) {
  const sColor = stackColor(lang.stack);
  const layers = [
    {
      label: "MEANING — DOCTRINE CLAUSE",
      content: lang.doctrineMeaning,
      color: NOVA_GOLD,
    },
    {
      label: "MODEL — TYPED STRUCTURE",
      content: lang.modelStructure,
      color: NOVA_TEAL,
    },
    {
      label: "COMPUTATION — EQUATION",
      content: lang.computationEquation,
      color: NOVA_PURPLE,
    },
    {
      label: "EXECUTION BINDING",
      content: lang.executionBinding,
      color: NOVA_GREEN,
    },
  ];
  return (
    <div
      className="border p-4 space-y-4"
      style={{ borderColor: `${sColor}30`, background: `${sColor}06` }}
      data-ocid="nova.detail.panel"
    >
      {/* Header */}
      <div className="flex items-start justify-between gap-2">
        <div>
          <div
            className="font-mono text-[8px] tracking-[0.2em] mb-0.5"
            style={{ color: sColor }}
          >
            {lang.id} · {lang.stack}
          </div>
          <div
            className="font-display font-bold text-lg leading-tight"
            style={{ color: "oklch(0.95 0.02 240)" }}
          >
            {lang.latinName}
          </div>
          <div
            className="font-mono text-xs mt-0.5"
            style={{ color: "oklch(0.55 0.02 240)" }}
          >
            {lang.englishDomain}
          </div>
        </div>
        <div className="flex flex-col items-end gap-1 shrink-0">
          <PhaseBadge phase={lang.runtimePhase} />
          <span
            className="font-mono text-[8px]"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            CGS: {lang.coherenceGateScore.toFixed(2)}
          </span>
        </div>
      </div>

      {/* Coherence gate bar */}
      <div>
        <div className="flex justify-between mb-1">
          <span
            className="font-mono text-[7px] tracking-[0.2em]"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            COHERENCE GATE SCORE
          </span>
          <span className="font-mono text-[8px]" style={{ color: sColor }}>
            {(lang.coherenceGateScore * 100).toFixed(0)}%
          </span>
        </div>
        <div className="h-1" style={{ background: "oklch(0.16 0.02 240)" }}>
          <div
            className="h-full"
            style={{
              width: `${lang.coherenceGateScore * 100}%`,
              background: sColor,
              boxShadow: `0 0 6px ${sColor}60`,
            }}
          />
        </div>
      </div>

      {/* 4-Layer MEDINA Artifact */}
      <div className="space-y-2">
        {layers.map((layer) => (
          <div
            key={layer.label}
            className="p-2.5 border"
            style={{
              borderColor: `${layer.color}25`,
              background: `${layer.color}06`,
            }}
          >
            <div
              className="font-mono text-[7px] tracking-[0.2em] mb-1"
              style={{ color: layer.color }}
            >
              {layer.label}
            </div>
            <p
              className="font-mono text-[10px] leading-relaxed"
              style={{ color: "oklch(0.72 0.02 240)" }}
            >
              {layer.content}
            </p>
          </div>
        ))}
      </div>

      {/* Primary Objects */}
      <div>
        <div
          className="font-mono text-[7px] tracking-[0.25em] mb-1.5"
          style={{ color: "oklch(0.40 0.02 240)" }}
        >
          PRIMARY OBJECTS
        </div>
        <div className="flex flex-wrap gap-1">
          {lang.primaryObjects.map((obj) => (
            <span
              key={obj}
              className="font-mono text-[8px] px-1.5 py-0.5"
              style={{
                color: sColor,
                border: `1px solid ${sColor}35`,
                background: `${sColor}10`,
              }}
            >
              {obj}
            </span>
          ))}
        </div>
      </div>

      {/* TPL Dependencies */}
      {lang.tplDependencies.length > 0 && (
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.25em] mb-1.5"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            TPL DEPENDENCIES
          </div>
          <div className="flex flex-wrap gap-1">
            {lang.tplDependencies.map((dep) => (
              <span
                key={dep}
                className="font-mono text-[8px] px-1.5 py-0.5"
                style={{
                  color: NOVA_TEAL,
                  border: `1px solid ${NOVA_TEAL}35`,
                  background: `${NOVA_TEAL}10`,
                }}
              >
                {dep}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.2em] mb-0.5"
            style={{ color: "oklch(0.35 0.02 240)" }}
          >
            EXECUTIONS
          </div>
          <div
            className="font-mono text-xs tabular-nums"
            style={{ color: sColor }}
          >
            {formatBigInt(lang.executionCount)}
          </div>
        </div>
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.2em] mb-0.5"
            style={{ color: "oklch(0.35 0.02 240)" }}
          >
            LAST BEAT
          </div>
          <div
            className="font-mono text-xs tabular-nums"
            style={{ color: "oklch(0.55 0.02 240)" }}
          >
            #{formatBigInt(lang.lastBeatExecuted)}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Execution Log ────────────────────────────────────────────────────────────

function ExecutionLog({ entries }: { entries: ExecLogEntry[] }) {
  return (
    <div data-ocid="nova.execlog.panel">
      <div
        className="font-mono text-[8px] tracking-[0.3em] mb-2"
        style={{ color: "oklch(0.40 0.02 240)" }}
      >
        EXECUTION LOG — LAST {entries.length} DISPATCHES
      </div>
      <div className="border" style={{ borderColor: "oklch(0.18 0.02 240)" }}>
        {entries.map((entry, i) => {
          const sColor = STATUS_COLORS[entry.status];
          return (
            <div
              key={`${entry.engineId}-${i}`}
              className="flex items-center gap-3 px-3 py-2 border-b last:border-0"
              style={{ borderColor: "oklch(0.14 0.01 240)" }}
            >
              <span
                className="w-1.5 h-1.5 shrink-0 rounded-full"
                style={{ background: sColor, boxShadow: `0 0 4px ${sColor}` }}
              />
              <span
                className="font-mono text-[8px] w-12 shrink-0"
                style={{
                  color:
                    stackColor(
                      MOCK_LANGUAGES.find((l) => l.id === entry.engineId)
                        ?.stack ?? "",
                    ) || "oklch(0.55 0.02 240)",
                }}
              >
                {entry.engineId}
              </span>
              <span
                className="font-mono text-[9px] flex-1 min-w-0 truncate"
                style={{ color: "oklch(0.65 0.02 240)" }}
              >
                {entry.latinName}
              </span>
              <span
                className="font-mono text-[8px] tabular-nums shrink-0"
                style={{ color: "oklch(0.35 0.02 240)" }}
              >
                #{entry.beatNumber}
              </span>
              <span
                className="font-mono text-[8px] tabular-nums w-12 text-right shrink-0"
                style={{ color: "oklch(0.45 0.02 240)" }}
              >
                {entry.executionTime}ms
              </span>
              <span
                className="font-mono text-[7px] tracking-wide w-12 text-right shrink-0 uppercase"
                style={{ color: sColor }}
              >
                {entry.status}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Ecosystem SVG Map ────────────────────────────────────────────────────────

const STACK_GROUP_POSITIONS: Record<string, { x: number; y: number }> = {
  CoreLaw: { x: 400, y: 100 },
  InnerMind: { x: 180, y: 210 },
  Relational: { x: 620, y: 210 },
  WorkCraft: { x: 100, y: 340 },
  Narrative: { x: 300, y: 370 },
  Worlds: { x: 500, y: 370 },
  Education: { x: 700, y: 340 },
  Enterprise: { x: 130, y: 480 },
  Infrastructure: { x: 400, y: 500 },
  ErrorChaos: { x: 670, y: 480 },
  MetaEvolution: { x: 400, y: 600 },
};

function EcosystemMap({ languages }: { languages: NovaCognitiveLanguage[] }) {
  const byStack = useMemo(() => {
    const map: Record<string, NovaCognitiveLanguage[]> = {};
    for (const l of languages) {
      if (!map[l.stack]) map[l.stack] = [];
      map[l.stack].push(l);
    }
    return map;
  }, [languages]);

  // Build TPL dependency lines
  const depLines = useMemo(() => {
    const lines: {
      x1: number;
      y1: number;
      x2: number;
      y2: number;
      color: string;
    }[] = [];
    for (const lang of languages) {
      const fromPos = STACK_GROUP_POSITIONS[lang.stack];
      if (!fromPos) continue;
      for (const dep of lang.tplDependencies) {
        const depLang = languages.find((l) => l.id === dep);
        if (!depLang) continue;
        const toPos = STACK_GROUP_POSITIONS[depLang.stack];
        if (!toPos || (fromPos.x === toPos.x && fromPos.y === toPos.y))
          continue;
        lines.push({
          x1: fromPos.x,
          y1: fromPos.y,
          x2: toPos.x,
          y2: toPos.y,
          color: stackColor(lang.stack),
        });
      }
    }
    // Deduplicate
    const seen = new Set<string>();
    return lines.filter((l) => {
      const key = `${Math.min(l.x1, l.x2)}_${Math.min(l.y1, l.y2)}_${Math.max(l.x1, l.x2)}_${Math.max(l.y1, l.y2)}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }, [languages]);

  return (
    <div data-ocid="nova.ecosystem.map">
      <div
        className="font-mono text-[8px] tracking-[0.3em] mb-3"
        style={{ color: "oklch(0.40 0.02 240)" }}
      >
        LANGUAGE ECOSYSTEM DEPENDENCY MAP
      </div>
      <div
        className="border overflow-x-auto"
        style={{
          borderColor: "oklch(0.18 0.02 240)",
          background: "oklch(0.07 0.01 240)",
        }}
      >
        <svg
          viewBox="0 0 800 700"
          width="100%"
          style={{ minWidth: 420, maxHeight: 500 }}
          role="img"
          aria-label="Language ecosystem dependency map"
        >
          <title>Language ecosystem dependency map</title>
          {/* Grid */}
          <defs>
            <pattern
              id="nova-grid"
              width="40"
              height="40"
              patternUnits="userSpaceOnUse"
            >
              <path
                d="M 40 0 L 0 0 0 40"
                fill="none"
                stroke="oklch(0.14 0.02 240)"
                strokeWidth="0.5"
              />
            </pattern>
          </defs>
          <rect width="800" height="700" fill="url(#nova-grid)" />

          {/* Dependency lines */}
          {depLines.map((line, i) => (
            <line
              key={`dep-${line.x1}-${line.y1}-${line.x2}-${line.y2}-${i}`}
              x1={line.x1}
              y1={line.y1}
              x2={line.x2}
              y2={line.y2}
              stroke={`${line.color}40`}
              strokeWidth="1"
              strokeDasharray="4 4"
            />
          ))}

          {/* Stack group nodes */}
          {Object.entries(byStack).map(([stack, langs]) => {
            const pos = STACK_GROUP_POSITIONS[stack];
            if (!pos) return null;
            const sColor = stackColor(stack);
            const activeCount = langs.filter(
              (l) =>
                l.runtimePhase === "active" || l.runtimePhase === "transcended",
            ).length;
            return (
              <g key={stack}>
                {/* Outer ring */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={36}
                  fill={`${sColor}08`}
                  stroke={`${sColor}40`}
                  strokeWidth="1"
                />
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={22}
                  fill={`${sColor}14`}
                  stroke={`${sColor}60`}
                  strokeWidth="1.5"
                />
                {/* Center dot */}
                <circle
                  cx={pos.x}
                  cy={pos.y}
                  r={6}
                  fill={sColor}
                  opacity="0.85"
                />
                {/* Stack label */}
                <text
                  x={pos.x}
                  y={pos.y + 52}
                  textAnchor="middle"
                  fill={sColor}
                  fontSize="9"
                  fontFamily="monospace"
                  letterSpacing="1"
                >
                  {stack.toUpperCase()}
                </text>
                {/* Count */}
                <text
                  x={pos.x}
                  y={pos.y - 42}
                  textAnchor="middle"
                  fill={`${sColor}99`}
                  fontSize="8"
                  fontFamily="monospace"
                >
                  {activeCount}/{langs.length}
                </text>
              </g>
            );
          })}
        </svg>
      </div>
    </div>
  );
}

// ─── Main NOVATab ─────────────────────────────────────────────────────────────

export function NOVATab() {
  const { actor } = useActor();
  const [languages, setLanguages] =
    useState<NovaCognitiveLanguage[]>(MOCK_LANGUAGES);
  const [runtimeState, setRuntimeState] =
    useState<NovaRuntimeState>(MOCK_RUNTIME_STATE);
  const [execLog, _setExecLog] = useState<ExecLogEntry[]>(() =>
    seedLogFromMock(MOCK_LANGUAGES),
  );
  const [selectedId, setSelectedId] = useState<string | null>("CPL-L");
  const [search, setSearch] = useState("");
  const [stackFilter, setStackFilter] = useState("ALL");
  const [activeView, setActiveView] = useState<"grid" | "map">("grid");
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchData = useCallback(async () => {
    if (!actor) return;
    const a = actor as unknown as Record<
      string,
      (...args: unknown[]) => Promise<unknown>
    >;
    try {
      const [registry, state] = await Promise.all([
        a.getNovaLanguageRegistry
          ? a.getNovaLanguageRegistry()
          : Promise.resolve(null),
        a.getNovaRuntimeState ? a.getNovaRuntimeState() : Promise.resolve(null),
      ]);
      if (registry && Array.isArray(registry))
        setLanguages(registry as NovaCognitiveLanguage[]);
      if (state) setRuntimeState(state as NovaRuntimeState);
    } catch {
      // Silently keep mock data
    }
  }, [actor]);

  useEffect(() => {
    fetchData();
    intervalRef.current = setInterval(fetchData, 3000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchData]);

  const filteredLanguages = useMemo(() => {
    return languages.filter((l) => {
      const matchStack = stackFilter === "ALL" || l.stack === stackFilter;
      const q = search.toLowerCase();
      const matchSearch =
        !q ||
        l.latinName.toLowerCase().includes(q) ||
        l.englishDomain.toLowerCase().includes(q) ||
        l.id.toLowerCase().includes(q);
      return matchStack && matchSearch;
    });
  }, [languages, search, stackFilter]);

  const selectedLang = useMemo(
    () => languages.find((l) => l.id === selectedId) ?? null,
    [languages, selectedId],
  );

  const totalActive = useMemo(
    () =>
      languages.filter(
        (l) => l.runtimePhase === "active" || l.runtimePhase === "transcended",
      ).length,
    [languages],
  );

  return (
    <div className="space-y-5" data-ocid="nova.page">
      {/* ── Header ───────────────────────────────────────────────────── */}
      <div
        className="border p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
        style={{ borderColor: `${NOVA_GOLD}30`, background: `${NOVA_GOLD}06` }}
        data-ocid="nova.header.panel"
      >
        <div>
          <div className="flex items-center gap-3 mb-1">
            <span
              className="font-display font-bold text-2xl tracking-[0.3em]"
              style={{
                color: NOVA_GOLD,
                textShadow: `0 0 24px ${NOVA_GOLD}50`,
              }}
            >
              NOVA
            </span>
            <span
              className="font-mono text-[8px] tracking-[0.2em] px-2 py-1 border"
              style={{
                color: NOVA_GOLD,
                borderColor: `${NOVA_GOLD}40`,
                background: `${NOVA_GOLD}10`,
              }}
            >
              v{runtimeState.novaVersion}
            </span>
            <PhaseBadge phase={runtimeState.runtimePhase} />
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.2em]"
            style={{ color: "oklch(0.50 0.02 240)" }}
          >
            SOVEREIGN COGNITIVE RUNTIME · 40 LANGUAGE ENGINES
          </div>
        </div>
        <div className="flex items-center gap-5">
          <div className="text-right">
            <div
              className="font-mono text-[7px] tracking-[0.25em] mb-0.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              TOTAL EXECUTIONS
            </div>
            <div
              className="font-mono text-base tabular-nums font-bold"
              style={{ color: NOVA_GOLD }}
            >
              {formatBigInt(runtimeState.totalExecutionCount)}
            </div>
          </div>
          <div
            className="w-px h-8 self-stretch"
            style={{ background: "oklch(0.22 0.02 240)" }}
          />
          <div className="text-right">
            <div
              className="font-mono text-[7px] tracking-[0.25em] mb-0.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              ACTIVE
            </div>
            <div
              className="font-mono text-base tabular-nums font-bold"
              style={{ color: NOVA_GREEN }}
            >
              {totalActive}/{languages.length}
            </div>
          </div>
        </div>
      </div>

      {/* ── Runtime Health ───────────────────────────────────────────── */}
      <RuntimeHealthPanel
        runtimeState={runtimeState}
        totalActive={totalActive}
        totalLanguages={languages.length}
      />

      {/* ── View Toggle ──────────────────────────────────────────────── */}
      <div className="flex items-center gap-2">
        {(["grid", "map"] as const).map((v) => (
          <button
            key={v}
            type="button"
            onClick={() => setActiveView(v)}
            data-ocid={`nova.view.${v}.tab`}
            className="font-mono text-[8px] tracking-[0.2em] px-3 py-1.5 border transition-all uppercase"
            style={{
              borderColor:
                activeView === v ? `${NOVA_PURPLE}70` : "oklch(0.18 0.02 240)",
              color: activeView === v ? NOVA_PURPLE : "oklch(0.40 0.02 240)",
              background: activeView === v ? `${NOVA_PURPLE}12` : "transparent",
            }}
          >
            {v === "grid" ? "ENGINE GRID" : "ECOSYSTEM MAP"}
          </button>
        ))}
      </div>

      {activeView === "grid" && (
        <>
          {/* ── Search + Filter ────────────────────────────────────────── */}
          <div
            className="flex flex-col sm:flex-row gap-2"
            data-ocid="nova.filter.panel"
          >
            <input
              type="text"
              placeholder="Search engines..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              data-ocid="nova.search_input"
              className="flex-1 font-mono text-xs px-3 py-2 border outline-none transition-all"
              style={{
                background: "oklch(0.10 0.01 240)",
                borderColor: search
                  ? `${NOVA_PURPLE}60`
                  : "oklch(0.18 0.02 240)",
                color: "oklch(0.85 0.02 240)",
              }}
            />
            <div className="flex gap-1.5 flex-wrap">
              {STACK_FILTERS.map((sf) => (
                <button
                  key={sf}
                  type="button"
                  onClick={() => setStackFilter(sf)}
                  data-ocid={`nova.filter.${sf.toLowerCase()}.tab`}
                  className="font-mono text-[7px] tracking-[0.15em] px-2 py-1.5 border transition-all"
                  style={{
                    borderColor:
                      stackFilter === sf
                        ? `${stackColor(sf) || NOVA_PURPLE}70`
                        : "oklch(0.16 0.01 240)",
                    color:
                      stackFilter === sf
                        ? stackColor(sf) || NOVA_PURPLE
                        : "oklch(0.38 0.02 240)",
                    background:
                      stackFilter === sf
                        ? `${stackColor(sf) || NOVA_PURPLE}12`
                        : "transparent",
                  }}
                >
                  {sf}
                </button>
              ))}
            </div>
          </div>

          {/* ── Main Grid + Detail ─────────────────────────────────────── */}
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-4">
            {/* Engine grid */}
            <div>
              <div
                className="font-mono text-[8px] tracking-[0.3em] mb-2"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                {filteredLanguages.length} ENGINE
                {filteredLanguages.length !== 1 ? "S" : ""} · NOVA REGISTRY
              </div>
              <div
                className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-2"
                data-ocid="nova.engine.list"
              >
                {filteredLanguages.map((lang, i) => (
                  <EngineCard
                    key={lang.id}
                    lang={lang}
                    selected={selectedId === lang.id}
                    onClick={() => setSelectedId(lang.id)}
                    index={i}
                  />
                ))}
                {filteredLanguages.length === 0 && (
                  <div
                    className="col-span-full text-center py-12"
                    style={{ color: "oklch(0.35 0.02 240)" }}
                    data-ocid="nova.empty_state"
                  >
                    <div className="font-mono text-[8px] tracking-[0.3em]">
                      NO ENGINES MATCH FILTER
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Detail panel + execution log */}
            <div className="space-y-4">
              {selectedLang ? (
                <EngineDetailPanel lang={selectedLang} />
              ) : (
                <div
                  className="border p-6 text-center"
                  style={{
                    borderColor: "oklch(0.16 0.01 240)",
                    color: "oklch(0.35 0.02 240)",
                  }}
                >
                  <div className="font-mono text-[8px] tracking-[0.2em]">
                    SELECT AN ENGINE TO INSPECT
                  </div>
                </div>
              )}
              <ExecutionLog entries={execLog} />
            </div>
          </div>
        </>
      )}

      {activeView === "map" && <EcosystemMap languages={languages} />}
    </div>
  );
}
