/**
 * governanceMacro.ts — PARALLAX Governance Protocols Macro
 * ═══════════════════════════════════════════════════════════════════════════
 * The macro-level governance framework that defines HOW the system operates
 * across TIME, USERS, POLICIES, ETHICS, and the CHARTER.
 *
 * This is NOT a UI module. It is a SOVEREIGN PROTOCOL DEFINITION — a pure
 * TypeScript encoding of the governance rules that bind the organism.
 *
 * Structure:
 *   I.   TIME GOVERNANCE      — how the system evolves across temporal horizons
 *   II.  USER GOVERNANCE      — how users, members, and agents interact
 *   III. POLICY GOVERNANCE    — operational policies and enforcement
 *   IV.  ETHICS GOVERNANCE    — ethical constraints and safety rails
 *   V.   CHARTER GOVERNANCE   — constitutional amendment and sovereignty
 *   VI.  MACRO PROTOCOL STATE — unified governance state machine
 *
 * The Architect of the Field: Alfredo Medina Hernandez.
 */

import {
  COMPLIANCE_RATIO,
  FIB,
  HEARTBEAT_MS,
  JUBILEE_BEATS,
  PHI,
  PHI_INV,
  PHI_INV_2,
  PHI_INV_3,
  PHI_2,
  PHI_4,
  S0,
} from "../phi";

// ═══════════════════════════════════════════════════════════════════════════════
// I. TIME GOVERNANCE — Temporal Protocol
// The organism is a living clock. Every action has a temporal context.
// ═══════════════════════════════════════════════════════════════════════════════

/** Temporal epoch — defines a governance era in the organism's lifecycle */
export type GovernanceEpoch =
  | "genesis" // Beat 0 — formation, charter sealed
  | "infancy" // Beats 1–144 (first Jubilee cycle)
  | "growth" // Beats 145–10946 (F(21) expansion phase)
  | "maturity" // Beats 10947+ — full sovereign operations
  | "succession"; // Post-founder transition phase

/** Time-bound governance parameters that evolve across epochs */
export interface TemporalGovernanceParams {
  epoch: GovernanceEpoch;
  beatNumber: bigint;
  /** How many Jubilee cycles have completed (beat / 144) */
  jubileeCycle: number;
  /** Voting window multiplier — shorter in maturity, longer in infancy */
  votingWindowMultiplier: number;
  /** Quorum relaxation factor — higher quorum in early epochs for safety */
  quorumFactor: number;
  /** Amendment lockout — how many beats before another amendment attempt */
  amendmentCooldownBeats: number;
  /** Heartbeat tolerance in ms — tighter over time */
  heartbeatToleranceMs: number;
}

/** Determine which governance epoch based on current beat */
export function resolveEpoch(beat: bigint): GovernanceEpoch {
  if (beat === 0n) return "genesis";
  if (beat <= 144n) return "infancy";
  if (beat <= 10946n) return "growth";
  return "maturity";
}

/** Compute temporal governance parameters for a given beat */
export function computeTemporalParams(beat: bigint): TemporalGovernanceParams {
  const epoch = resolveEpoch(beat);
  const jubileeCycle = Number(beat) / JUBILEE_BEATS;

  // Voting window is longer in infancy (more deliberation time)
  const votingWindowMultiplier =
    epoch === "genesis"
      ? 0
      : epoch === "infancy"
        ? PHI_2 // 2.618x — more time for early decisions
        : epoch === "growth"
          ? PHI // 1.618x — moderate
          : 1.0; // maturity — standard

  // Quorum is stricter in early epochs (safety)
  const quorumFactor =
    epoch === "genesis" || epoch === "infancy"
      ? 1.0 // Full quorum required
      : epoch === "growth"
        ? PHI_INV // 0.618 relaxation
        : PHI_INV_2; // 0.382 mature relaxation

  // Amendment cooldown (beats between amendment attempts)
  const amendmentCooldownBeats =
    epoch === "infancy"
      ? FIB[11]! // 144 — one full Jubilee cycle
      : epoch === "growth"
        ? FIB[9]! // 34 beats
        : FIB[7]!; // 13 beats in maturity

  // Heartbeat tolerance tightens over time
  const heartbeatToleranceMs =
    epoch === "infancy"
      ? HEARTBEAT_MS * PHI_INV // ±539ms tolerance
      : epoch === "growth"
        ? HEARTBEAT_MS * PHI_INV_2 // ±333ms
        : HEARTBEAT_MS * PHI_INV_3; // ±206ms (tightest)

  return {
    epoch,
    beatNumber: beat,
    jubileeCycle,
    votingWindowMultiplier,
    quorumFactor,
    amendmentCooldownBeats,
    heartbeatToleranceMs,
  };
}

/** Check if a beat is a governance checkpoint (Fibonacci-aligned) */
export function isGovernanceCheckpoint(beat: bigint): boolean {
  const n = Number(beat);
  return FIB.includes(n);
}

/** Compute temporal decay for proposal urgency (older proposals lose priority) */
export function proposalUrgencyDecay(
  createdBeat: bigint,
  currentBeat: bigint,
): number {
  const age = Number(currentBeat - createdBeat);
  if (age <= 0) return 1.0;
  // Exponential decay by phi-inverse — urgency halves every 144 beats
  return Math.exp(-PHI_INV * (age / JUBILEE_BEATS));
}

// ═══════════════════════════════════════════════════════════════════════════════
// II. USER GOVERNANCE — Principal & Membership Protocol
// Every user is a principal. Every principal has a governance role.
// ═══════════════════════════════════════════════════════════════════════════════

/** Membership tiers with phi-derived voting weights */
export type MemberTier =
  | "founder"
  | "governor"
  | "steward"
  | "member"
  | "observer";

/** Maps tier to phi-derived voting weight */
export function tierVotingWeight(tier: MemberTier): number {
  switch (tier) {
    case "founder":
      return PHI_4; // φ⁴ = 6.854 — permanent, irrevocable
    case "governor":
      return PHI_2; // φ² = 2.618 — elected leaders
    case "steward":
      return PHI; // φ  = 1.618 — appointed caretakers
    case "member":
      return 1.0; // base weight
    case "observer":
      return 0.0; // no voting power, read-only
  }
}

/** User action permission matrix — what each tier can do */
export interface TierPermissions {
  canVote: boolean;
  canPropose: boolean;
  canAmend: boolean;
  canVeto: boolean;
  canDisburse: boolean;
  canAppoint: boolean;
  canRemove: boolean;
}

export function tierPermissions(tier: MemberTier): TierPermissions {
  switch (tier) {
    case "founder":
      return {
        canVote: true,
        canPropose: true,
        canAmend: true,
        canVeto: true,
        canDisburse: true,
        canAppoint: true,
        canRemove: true,
      };
    case "governor":
      return {
        canVote: true,
        canPropose: true,
        canAmend: true,
        canVeto: false,
        canDisburse: true,
        canAppoint: true,
        canRemove: false,
      };
    case "steward":
      return {
        canVote: true,
        canPropose: true,
        canAmend: false,
        canVeto: false,
        canDisburse: false,
        canAppoint: false,
        canRemove: false,
      };
    case "member":
      return {
        canVote: true,
        canPropose: true,
        canAmend: false,
        canVeto: false,
        canDisburse: false,
        canAppoint: false,
        canRemove: false,
      };
    case "observer":
      return {
        canVote: false,
        canPropose: false,
        canAmend: false,
        canVeto: false,
        canDisburse: false,
        canAppoint: false,
        canRemove: false,
      };
  }
}

/** Delegation rules — who can delegate voting power to whom */
export function canDelegate(from: MemberTier, to: MemberTier): boolean {
  // Cannot delegate to observer (weight=0) or to oneself
  if (to === "observer") return false;
  // Founder cannot delegate (permanent responsibility)
  if (from === "founder") return false;
  // Can only delegate upward or laterally, not downward
  const hierarchy: Record<MemberTier, number> = {
    founder: 4,
    governor: 3,
    steward: 2,
    member: 1,
    observer: 0,
  };
  return hierarchy[to] >= hierarchy[from];
}

/** Compute effective voting power considering delegations */
export function effectiveVotingPower(
  baseTier: MemberTier,
  delegationsReceived: number,
): number {
  const base = tierVotingWeight(baseTier);
  // Each delegation adds 1.0 weight (standard member weight)
  return base + delegationsReceived * tierVotingWeight("member");
}

/** Membership age threshold — minimum beats before tier promotion */
export function promotionThreshold(currentTier: MemberTier): number {
  switch (currentTier) {
    case "observer":
      return FIB[7]!; // 13 beats to become member
    case "member":
      return FIB[9]!; // 34 beats to become steward
    case "steward":
      return FIB[11]!; // 144 beats to become governor
    case "governor":
      return Infinity; // Cannot be promoted to founder
    case "founder":
      return Infinity; // Already at top
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// III. POLICY GOVERNANCE — Operational Protocols
// Policies define how the system operates day-to-day.
// ═══════════════════════════════════════════════════════════════════════════════

/** Proposal categories with associated governance requirements */
export type ProposalCategory =
  | "constitutional" // Amend charter — supermajority
  | "financial" // Treasury ops — supermajority
  | "operational" // Day-to-day — simple majority
  | "membership" // Add/remove members — supermajority
  | "technical" // Protocol upgrades — supermajority
  | "emergency"; // Fast-track — founder veto

/** Quorum thresholds derived from phi */
export const QUORUM_STANDARD = PHI_INV; // 0.618 — 61.8% participation
export const QUORUM_CONSTITUTIONAL = 0.809; // φ⁻¹ + φ⁻³ — 80.9%
export const PASS_SIMPLE = 0.5; // > 50% of cast weight
export const PASS_SUPERMAJORITY = PHI_INV; // 0.618 — 61.8% of cast weight
export const PASS_DISSOLUTION = 0.9; // 90% near-unanimous

/** Voting window durations in beats */
export const VOTING_WINDOW_STANDARD = 7 * 24 * 3600_000 / HEARTBEAT_MS; // ~7 days
export const VOTING_WINDOW_EMERGENCY = 24 * 3600_000 / HEARTBEAT_MS; // ~24 hours

/** Get governance requirements for a proposal category */
export function proposalRequirements(category: ProposalCategory): {
  quorum: number;
  passThreshold: number;
  votingWindowBeats: number;
  founderVetoAllowed: boolean;
} {
  switch (category) {
    case "constitutional":
    case "financial":
    case "membership":
    case "technical":
      return {
        quorum: QUORUM_CONSTITUTIONAL,
        passThreshold: PASS_SUPERMAJORITY,
        votingWindowBeats: VOTING_WINDOW_STANDARD,
        founderVetoAllowed: false,
      };
    case "operational":
      return {
        quorum: QUORUM_STANDARD,
        passThreshold: PASS_SIMPLE,
        votingWindowBeats: VOTING_WINDOW_STANDARD,
        founderVetoAllowed: false,
      };
    case "emergency":
      return {
        quorum: QUORUM_STANDARD,
        passThreshold: PASS_SIMPLE,
        votingWindowBeats: VOTING_WINDOW_EMERGENCY,
        founderVetoAllowed: true,
      };
  }
}

/** Risk gate policy — determines if an action is safe to execute */
export function riskGatePolicy(
  coherenceR: number,
  volatility: number,
  exposureRatio: number,
): { allowed: boolean; reason: string } {
  // R must be above sovereign floor
  if (coherenceR < S0) {
    return { allowed: false, reason: "Coherence below sovereign floor (S0)" };
  }
  // Volatility must not exceed phi-scaled threshold
  if (volatility > PHI) {
    return { allowed: false, reason: "Volatility exceeds phi threshold" };
  }
  // Exposure must not exceed compliance ratio
  if (exposureRatio > COMPLIANCE_RATIO * PHI_2) {
    return { allowed: false, reason: "Exposure exceeds safe ratio" };
  }
  return { allowed: true, reason: "All risk gates passed" };
}

/** Treasury policy — maximum disbursement without supermajority */
export const MAX_STANDARD_DISBURSEMENT_BPS = 500; // 5% of treasury

/** Compute maximum disbursement amount */
export function maxDisbursement(
  treasuryBalance: number,
  category: ProposalCategory,
): number {
  if (category === "financial") {
    // Supermajority approved — up to compliance ratio of treasury
    return treasuryBalance * COMPLIANCE_RATIO;
  }
  // Standard disbursement — 5% max
  return treasuryBalance * (MAX_STANDARD_DISBURSEMENT_BPS / 10_000);
}

// ═══════════════════════════════════════════════════════════════════════════════
// IV. ETHICS GOVERNANCE — Ethical Constraints and Safety Rails
// The organism has ethical obligations encoded in code.
// ═══════════════════════════════════════════════════════════════════════════════

/** Ethical principle — an enforceable moral constraint */
export interface EthicalPrinciple {
  id: string;
  name: string;
  description: string;
  enforceable: boolean;
  violationPenalty: "warning" | "suspension" | "expulsion";
}

/** The organism's core ethical principles */
export const ETHICAL_PRINCIPLES: readonly EthicalPrinciple[] = [
  {
    id: "E01",
    name: "SOVEREIGNTY",
    description:
      "The organism preserves control over its own logic, governance, and memory",
    enforceable: true,
    violationPenalty: "expulsion",
  },
  {
    id: "E02",
    name: "TRANSPARENCY",
    description:
      "All governance actions are recorded on-chain and publicly verifiable",
    enforceable: true,
    violationPenalty: "suspension",
  },
  {
    id: "E03",
    name: "NON-HARM",
    description:
      "The system shall not knowingly facilitate actions that cause undue harm to users",
    enforceable: true,
    violationPenalty: "expulsion",
  },
  {
    id: "E04",
    name: "FAIR_ACCESS",
    description:
      "Bronze-tier access is free for education and public good (Charter P7)",
    enforceable: true,
    violationPenalty: "suspension",
  },
  {
    id: "E05",
    name: "CONSENT",
    description:
      "No user action shall be executed without explicit or delegated authorization",
    enforceable: true,
    violationPenalty: "expulsion",
  },
  {
    id: "E06",
    name: "AUDIT_TRAIL",
    description:
      "All state transitions are append-only and cryptographically chained (L07)",
    enforceable: true,
    violationPenalty: "expulsion",
  },
  {
    id: "E07",
    name: "PRIVACY",
    description:
      "User personal data is never exposed beyond the minimum needed for operation",
    enforceable: true,
    violationPenalty: "suspension",
  },
  {
    id: "E08",
    name: "PROPORTIONALITY",
    description:
      "Penalties are proportional to violations — never excessive or arbitrary",
    enforceable: true,
    violationPenalty: "warning",
  },
  {
    id: "E09",
    name: "FOUNDER_RESPONSIBILITY",
    description:
      "The Founder has permanent responsibility and cannot abdicate doctrine alignment",
    enforceable: true,
    violationPenalty: "warning",
  },
  {
    id: "E10",
    name: "SUCCESSION_RIGHTS",
    description:
      "20% succession reserve (L04) protects future participants unconditionally",
    enforceable: true,
    violationPenalty: "expulsion",
  },
] as const;

/** Check if an action violates any ethical principle */
export function ethicsCheck(action: {
  requiresConsent: boolean;
  hasConsent: boolean;
  exposesPrivateData: boolean;
  harmPotential: number; // 0.0–1.0
  isTransparent: boolean;
}): { passed: boolean; violations: string[] } {
  const violations: string[] = [];

  if (action.requiresConsent && !action.hasConsent) {
    violations.push("E05:CONSENT");
  }
  if (action.exposesPrivateData) {
    violations.push("E07:PRIVACY");
  }
  if (action.harmPotential > S0) {
    violations.push("E03:NON-HARM");
  }
  if (!action.isTransparent) {
    violations.push("E02:TRANSPARENCY");
  }

  return { passed: violations.length === 0, violations };
}

/** Compute ethical compliance score — phi-weighted across principles */
export function ethicalComplianceScore(
  principlesHonored: number,
  totalPrinciples: number,
): number {
  if (totalPrinciples === 0) return 0;
  const ratio = principlesHonored / totalPrinciples;
  // Apply S0 floor — never report below sovereign minimum
  return Math.max(S0, ratio);
}

// ═══════════════════════════════════════════════════════════════════════════════
// V. CHARTER GOVERNANCE — Constitutional Protocol
// The Charter is the supreme law. It can only evolve through consensus.
// ═══════════════════════════════════════════════════════════════════════════════

/** Charter amendment status tracking */
export type AmendmentStatus =
  | "proposed"
  | "voting"
  | "ratified"
  | "rejected"
  | "expired";

/** Charter article identifiers */
export type CharterArticle =
  | "I" // Identity & Formation
  | "II" // Purpose & Powers
  | "III" // Membership
  | "IV" // Governance & Voting
  | "V" // Treasury & Economic
  | "VI" // Offices & Roles
  | "VII" // Amendment Process
  | "VIII"; // Dissolution & Succession

/** Immutable charter provisions — articles that cannot be amended */
export const IMMUTABLE_PROVISIONS: readonly CharterArticle[] = [
  "I", // Identity cannot be changed (L00 Creator Sovereignty)
] as const;

/** Check if an article can be amended */
export function isAmendable(article: CharterArticle): boolean {
  return !IMMUTABLE_PROVISIONS.includes(article);
}

/** Compute charter integrity hash (FNV-1a simplified for frontend) */
export function computeCharterIntegrity(
  charterVersion: number,
  totalAmendments: number,
  memberCount: number,
): number {
  // FNV-1a inspired — deterministic integrity check
  let h = 2166136261;
  h = ((h ^ charterVersion) * 16777619) >>> 0;
  h = ((h ^ totalAmendments) * 16777619) >>> 0;
  h = ((h ^ memberCount) * 16777619) >>> 0;
  return h;
}

/** Minimum ratification requirements for charter changes */
export function charterAmendmentRequirements(): {
  quorum: number;
  passThreshold: number;
  cooldownBeats: number;
  founderApprovalRequired: boolean;
} {
  return {
    quorum: QUORUM_CONSTITUTIONAL, // 80.9%
    passThreshold: PASS_SUPERMAJORITY, // 61.8%
    cooldownBeats: JUBILEE_BEATS, // 144 beats between amendments
    founderApprovalRequired: true, // L00 Creator Sovereignty
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// VI. MACRO PROTOCOL STATE — Unified Governance State Machine
// The complete governance state of the organism at any point in time.
// ═══════════════════════════════════════════════════════════════════════════════

/** Complete governance protocol state */
export interface GovernanceProtocolState {
  // Time
  currentBeat: bigint;
  epoch: GovernanceEpoch;
  temporalParams: TemporalGovernanceParams;
  // Users
  totalMembers: number;
  totalVotingWeight: number;
  activeProposals: number;
  // Policy
  coherenceR: number;
  riskGateOpen: boolean;
  treasuryHealthBps: number;
  // Ethics
  ethicalComplianceScore: number;
  activePrincipleViolations: number;
  // Charter
  charterVersion: number;
  charterIntegrityHash: number;
  lastAmendmentBeat: bigint;
  isCharterLocked: boolean;
}

/** Create default governance state at genesis */
export function defaultGovernanceState(): GovernanceProtocolState {
  const temporalParams = computeTemporalParams(0n);
  return {
    currentBeat: 0n,
    epoch: "genesis",
    temporalParams,
    totalMembers: 1, // Founder
    totalVotingWeight: PHI_4, // Founder weight
    activeProposals: 0,
    coherenceR: S0,
    riskGateOpen: true,
    treasuryHealthBps: 10_000, // 100%
    ethicalComplianceScore: 1.0,
    activePrincipleViolations: 0,
    charterVersion: 1,
    charterIntegrityHash: computeCharterIntegrity(1, 0, 1),
    lastAmendmentBeat: 0n,
    isCharterLocked: false,
  };
}

/** Advance governance state by one beat — the governance heartbeat tick */
export function governanceHeartbeatTick(
  state: GovernanceProtocolState,
  newBeat: bigint,
  coherenceR: number,
): GovernanceProtocolState {
  const temporalParams = computeTemporalParams(newBeat);
  const epoch = resolveEpoch(newBeat);

  // Recompute risk gate
  const riskGateOpen = coherenceR >= S0;

  // Recompute charter lock (locked if within cooldown of last amendment)
  const beatsSinceAmendment = Number(newBeat - state.lastAmendmentBeat);
  const isCharterLocked =
    beatsSinceAmendment < temporalParams.amendmentCooldownBeats;

  return {
    ...state,
    currentBeat: newBeat,
    epoch,
    temporalParams,
    coherenceR,
    riskGateOpen,
    isCharterLocked,
  };
}

/** Validate overall governance health — returns true if organism is healthy */
export function isGovernanceHealthy(
  state: GovernanceProtocolState,
): boolean {
  return (
    state.coherenceR >= S0 &&
    state.ethicalComplianceScore >= S0 &&
    state.riskGateOpen &&
    state.treasuryHealthBps > 0
  );
}
