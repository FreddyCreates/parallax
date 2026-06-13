import { describe, expect, it } from "vitest";
import {
  ETHICAL_PRINCIPLES,
  IMMUTABLE_PROVISIONS,
  MAX_STANDARD_DISBURSEMENT_BPS,
  PASS_DISSOLUTION,
  PASS_SIMPLE,
  PASS_SUPERMAJORITY,
  QUORUM_CONSTITUTIONAL,
  QUORUM_STANDARD,
  VOTING_WINDOW_EMERGENCY,
  VOTING_WINDOW_STANDARD,
  canDelegate,
  charterAmendmentRequirements,
  computeCharterIntegrity,
  computeTemporalParams,
  defaultGovernanceState,
  effectiveVotingPower,
  ethicalComplianceScore,
  ethicsCheck,
  governanceHeartbeatTick,
  isAmendable,
  isGovernanceCheckpoint,
  isGovernanceHealthy,
  maxDisbursement,
  promotionThreshold,
  proposalRequirements,
  proposalUrgencyDecay,
  resolveEpoch,
  riskGatePolicy,
  tierPermissions,
  tierVotingWeight,
} from "../governanceMacro";
import {
  COMPLIANCE_RATIO,
  FIB,
  HEARTBEAT_MS,
  JUBILEE_BEATS,
  PHI,
  PHI_2,
  PHI_4,
  PHI_INV,
  PHI_INV_2,
  PHI_INV_3,
  S0,
} from "../../phi";

// ═══════════════════════════════════════════════════════════════════════════════
// I. TIME GOVERNANCE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("Time Governance — resolveEpoch", () => {
  it("returns genesis for beat 0", () => {
    expect(resolveEpoch(0n)).toBe("genesis");
  });

  it("returns infancy for beat 1", () => {
    expect(resolveEpoch(1n)).toBe("infancy");
  });

  it("returns infancy for beat 144 (boundary)", () => {
    expect(resolveEpoch(144n)).toBe("infancy");
  });

  it("returns growth for beat 145", () => {
    expect(resolveEpoch(145n)).toBe("growth");
  });

  it("returns growth for beat 10946 (F(21) boundary)", () => {
    expect(resolveEpoch(10946n)).toBe("growth");
  });

  it("returns maturity for beat 10947", () => {
    expect(resolveEpoch(10947n)).toBe("maturity");
  });

  it("returns maturity for very large beat", () => {
    expect(resolveEpoch(1_000_000n)).toBe("maturity");
  });
});

describe("Time Governance — computeTemporalParams", () => {
  it("genesis has zero voting window multiplier", () => {
    const params = computeTemporalParams(0n);
    expect(params.votingWindowMultiplier).toBe(0);
    expect(params.epoch).toBe("genesis");
  });

  it("infancy has phi-squared voting window multiplier", () => {
    const params = computeTemporalParams(10n);
    expect(params.votingWindowMultiplier).toBeCloseTo(PHI_2, 5);
  });

  it("growth has phi voting window multiplier", () => {
    const params = computeTemporalParams(200n);
    expect(params.votingWindowMultiplier).toBeCloseTo(PHI, 5);
  });

  it("maturity has 1.0 voting window multiplier", () => {
    const params = computeTemporalParams(20000n);
    expect(params.votingWindowMultiplier).toBe(1.0);
  });

  it("infancy has full quorum factor (1.0)", () => {
    const params = computeTemporalParams(50n);
    expect(params.quorumFactor).toBe(1.0);
  });

  it("growth has phi-inverse quorum factor", () => {
    const params = computeTemporalParams(500n);
    expect(params.quorumFactor).toBeCloseTo(PHI_INV, 5);
  });

  it("maturity has phi-inverse-squared quorum factor", () => {
    const params = computeTemporalParams(50000n);
    expect(params.quorumFactor).toBeCloseTo(PHI_INV_2, 5);
  });

  it("infancy amendment cooldown is 144 beats (Jubilee)", () => {
    const params = computeTemporalParams(10n);
    expect(params.amendmentCooldownBeats).toBe(144);
  });

  it("growth amendment cooldown is 55 beats (F(9))", () => {
    const params = computeTemporalParams(500n);
    expect(params.amendmentCooldownBeats).toBe(55);
  });

  it("maturity amendment cooldown is 21 beats (F(7))", () => {
    const params = computeTemporalParams(50000n);
    expect(params.amendmentCooldownBeats).toBe(21);
  });

  it("heartbeat tolerance tightens over time", () => {
    const infancy = computeTemporalParams(10n);
    const growth = computeTemporalParams(500n);
    const maturity = computeTemporalParams(50000n);
    expect(infancy.heartbeatToleranceMs).toBeGreaterThan(
      growth.heartbeatToleranceMs,
    );
    expect(growth.heartbeatToleranceMs).toBeGreaterThan(
      maturity.heartbeatToleranceMs,
    );
  });

  it("computes correct jubilee cycle", () => {
    const params = computeTemporalParams(288n);
    expect(params.jubileeCycle).toBe(288 / JUBILEE_BEATS);
  });
});

describe("Time Governance — isGovernanceCheckpoint", () => {
  it("returns true for Fibonacci numbers", () => {
    expect(isGovernanceCheckpoint(1n)).toBe(true);
    expect(isGovernanceCheckpoint(2n)).toBe(true);
    expect(isGovernanceCheckpoint(3n)).toBe(true);
    expect(isGovernanceCheckpoint(5n)).toBe(true);
    expect(isGovernanceCheckpoint(8n)).toBe(true);
    expect(isGovernanceCheckpoint(13n)).toBe(true);
    expect(isGovernanceCheckpoint(21n)).toBe(true);
    expect(isGovernanceCheckpoint(144n)).toBe(true);
  });

  it("returns false for non-Fibonacci numbers", () => {
    expect(isGovernanceCheckpoint(4n)).toBe(false);
    expect(isGovernanceCheckpoint(6n)).toBe(false);
    expect(isGovernanceCheckpoint(7n)).toBe(false);
    expect(isGovernanceCheckpoint(9n)).toBe(false);
    expect(isGovernanceCheckpoint(10n)).toBe(false);
    expect(isGovernanceCheckpoint(100n)).toBe(false);
  });
});

describe("Time Governance — proposalUrgencyDecay", () => {
  it("returns 1.0 for same beat (no decay)", () => {
    expect(proposalUrgencyDecay(100n, 100n)).toBeCloseTo(1.0);
  });

  it("decays over time", () => {
    const urgency = proposalUrgencyDecay(0n, 144n);
    expect(urgency).toBeLessThan(1.0);
    expect(urgency).toBeGreaterThan(0.0);
  });

  it("decays more for older proposals", () => {
    const recent = proposalUrgencyDecay(0n, 50n);
    const old = proposalUrgencyDecay(0n, 500n);
    expect(recent).toBeGreaterThan(old);
  });

  it("approaches zero for very old proposals", () => {
    const veryOld = proposalUrgencyDecay(0n, 100000n);
    expect(veryOld).toBeLessThan(0.01);
  });

  it("uses phi-inverse decay constant", () => {
    // At 144 beats (1 Jubilee), decay = e^(-PHI_INV * 1)
    const expected = Math.exp(-PHI_INV);
    const actual = proposalUrgencyDecay(0n, 144n);
    expect(actual).toBeCloseTo(expected, 5);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// II. USER GOVERNANCE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("User Governance — tierVotingWeight", () => {
  it("founder has phi^4 weight", () => {
    expect(tierVotingWeight("founder")).toBeCloseTo(PHI_4, 2);
  });

  it("governor has phi^2 weight", () => {
    expect(tierVotingWeight("governor")).toBeCloseTo(PHI_2, 2);
  });

  it("steward has phi weight", () => {
    expect(tierVotingWeight("steward")).toBeCloseTo(PHI, 2);
  });

  it("member has weight 1.0", () => {
    expect(tierVotingWeight("member")).toBe(1.0);
  });

  it("observer has weight 0.0", () => {
    expect(tierVotingWeight("observer")).toBe(0.0);
  });

  it("weights are strictly ordered", () => {
    expect(tierVotingWeight("founder")).toBeGreaterThan(
      tierVotingWeight("governor"),
    );
    expect(tierVotingWeight("governor")).toBeGreaterThan(
      tierVotingWeight("steward"),
    );
    expect(tierVotingWeight("steward")).toBeGreaterThan(
      tierVotingWeight("member"),
    );
    expect(tierVotingWeight("member")).toBeGreaterThan(
      tierVotingWeight("observer"),
    );
  });
});

describe("User Governance — tierPermissions", () => {
  it("founder has all permissions", () => {
    const perms = tierPermissions("founder");
    expect(perms.canVote).toBe(true);
    expect(perms.canPropose).toBe(true);
    expect(perms.canAmend).toBe(true);
    expect(perms.canVeto).toBe(true);
    expect(perms.canDisburse).toBe(true);
    expect(perms.canAppoint).toBe(true);
    expect(perms.canRemove).toBe(true);
  });

  it("governor cannot veto or remove", () => {
    const perms = tierPermissions("governor");
    expect(perms.canVote).toBe(true);
    expect(perms.canVeto).toBe(false);
    expect(perms.canRemove).toBe(false);
  });

  it("steward can vote and propose only", () => {
    const perms = tierPermissions("steward");
    expect(perms.canVote).toBe(true);
    expect(perms.canPropose).toBe(true);
    expect(perms.canAmend).toBe(false);
    expect(perms.canDisburse).toBe(false);
  });

  it("member can vote and propose only", () => {
    const perms = tierPermissions("member");
    expect(perms.canVote).toBe(true);
    expect(perms.canPropose).toBe(true);
    expect(perms.canAmend).toBe(false);
  });

  it("observer has no permissions", () => {
    const perms = tierPermissions("observer");
    expect(perms.canVote).toBe(false);
    expect(perms.canPropose).toBe(false);
    expect(perms.canAmend).toBe(false);
    expect(perms.canVeto).toBe(false);
    expect(perms.canDisburse).toBe(false);
    expect(perms.canAppoint).toBe(false);
    expect(perms.canRemove).toBe(false);
  });
});

describe("User Governance — canDelegate", () => {
  it("founder cannot delegate (permanent responsibility)", () => {
    expect(canDelegate("founder", "governor")).toBe(false);
    expect(canDelegate("founder", "member")).toBe(false);
  });

  it("cannot delegate to observer", () => {
    expect(canDelegate("member", "observer")).toBe(false);
    expect(canDelegate("steward", "observer")).toBe(false);
  });

  it("member can delegate upward to steward", () => {
    expect(canDelegate("member", "steward")).toBe(true);
  });

  it("member can delegate upward to governor", () => {
    expect(canDelegate("member", "governor")).toBe(true);
  });

  it("member can delegate laterally to member", () => {
    expect(canDelegate("member", "member")).toBe(true);
  });

  it("governor cannot delegate downward to member", () => {
    expect(canDelegate("governor", "member")).toBe(false);
  });

  it("steward can delegate to governor", () => {
    expect(canDelegate("steward", "governor")).toBe(true);
  });

  it("steward can delegate to steward (lateral)", () => {
    expect(canDelegate("steward", "steward")).toBe(true);
  });
});

describe("User Governance — effectiveVotingPower", () => {
  it("base power with zero delegations equals tier weight", () => {
    expect(effectiveVotingPower("founder", 0)).toBeCloseTo(PHI_4, 2);
    expect(effectiveVotingPower("member", 0)).toBe(1.0);
  });

  it("each delegation adds 1.0 weight", () => {
    expect(effectiveVotingPower("steward", 3)).toBeCloseTo(PHI + 3.0, 2);
  });

  it("observer with delegations still has zero base", () => {
    expect(effectiveVotingPower("observer", 5)).toBe(5.0);
  });
});

describe("User Governance — promotionThreshold", () => {
  it("observer needs 21 beats for promotion (F(7))", () => {
    expect(promotionThreshold("observer")).toBe(21);
  });

  it("member needs 55 beats for promotion (F(9))", () => {
    expect(promotionThreshold("member")).toBe(55);
  });

  it("steward needs 144 beats for promotion", () => {
    expect(promotionThreshold("steward")).toBe(144);
  });

  it("governor cannot be promoted further", () => {
    expect(promotionThreshold("governor")).toBe(Infinity);
  });

  it("founder cannot be promoted further", () => {
    expect(promotionThreshold("founder")).toBe(Infinity);
  });

  it("promotion thresholds are Fibonacci numbers", () => {
    expect(FIB).toContain(promotionThreshold("observer"));
    expect(FIB).toContain(promotionThreshold("member"));
    expect(FIB).toContain(promotionThreshold("steward"));
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// III. POLICY GOVERNANCE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("Policy Governance — quorum constants", () => {
  it("standard quorum is phi-inverse (0.618)", () => {
    expect(QUORUM_STANDARD).toBeCloseTo(PHI_INV, 5);
  });

  it("constitutional quorum is 0.809", () => {
    expect(QUORUM_CONSTITUTIONAL).toBeCloseTo(0.809, 3);
  });

  it("simple pass threshold is 0.5", () => {
    expect(PASS_SIMPLE).toBe(0.5);
  });

  it("supermajority pass threshold is phi-inverse", () => {
    expect(PASS_SUPERMAJORITY).toBeCloseTo(PHI_INV, 5);
  });

  it("dissolution threshold is 0.9", () => {
    expect(PASS_DISSOLUTION).toBe(0.9);
  });

  it("constitutional quorum exceeds standard quorum", () => {
    expect(QUORUM_CONSTITUTIONAL).toBeGreaterThan(QUORUM_STANDARD);
  });
});

describe("Policy Governance — proposalRequirements", () => {
  it("constitutional requires supermajority quorum", () => {
    const req = proposalRequirements("constitutional");
    expect(req.quorum).toBe(QUORUM_CONSTITUTIONAL);
    expect(req.passThreshold).toBe(PASS_SUPERMAJORITY);
  });

  it("financial requires supermajority", () => {
    const req = proposalRequirements("financial");
    expect(req.quorum).toBe(QUORUM_CONSTITUTIONAL);
    expect(req.passThreshold).toBe(PASS_SUPERMAJORITY);
  });

  it("operational requires simple majority", () => {
    const req = proposalRequirements("operational");
    expect(req.quorum).toBe(QUORUM_STANDARD);
    expect(req.passThreshold).toBe(PASS_SIMPLE);
  });

  it("emergency allows founder veto", () => {
    const req = proposalRequirements("emergency");
    expect(req.founderVetoAllowed).toBe(true);
  });

  it("non-emergency categories disallow founder veto", () => {
    expect(proposalRequirements("constitutional").founderVetoAllowed).toBe(
      false,
    );
    expect(proposalRequirements("operational").founderVetoAllowed).toBe(false);
  });

  it("emergency has shorter voting window", () => {
    const emergency = proposalRequirements("emergency");
    const standard = proposalRequirements("operational");
    expect(emergency.votingWindowBeats).toBeLessThan(
      standard.votingWindowBeats,
    );
  });

  it("membership requires supermajority", () => {
    const req = proposalRequirements("membership");
    expect(req.quorum).toBe(QUORUM_CONSTITUTIONAL);
    expect(req.passThreshold).toBe(PASS_SUPERMAJORITY);
  });

  it("technical requires supermajority", () => {
    const req = proposalRequirements("technical");
    expect(req.quorum).toBe(QUORUM_CONSTITUTIONAL);
  });
});

describe("Policy Governance — riskGatePolicy", () => {
  it("allows action when all conditions are met", () => {
    const result = riskGatePolicy(0.9, 0.5, 0.1);
    expect(result.allowed).toBe(true);
  });

  it("blocks when coherence is below S0", () => {
    const result = riskGatePolicy(0.5, 0.5, 0.1);
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("Coherence");
  });

  it("blocks when volatility exceeds phi", () => {
    const result = riskGatePolicy(0.9, 2.0, 0.1);
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("Volatility");
  });

  it("blocks when exposure exceeds safe ratio", () => {
    const maxExposure = COMPLIANCE_RATIO * PHI_2;
    const result = riskGatePolicy(0.9, 0.5, maxExposure + 0.1);
    expect(result.allowed).toBe(false);
    expect(result.reason).toContain("Exposure");
  });

  it("passes at exact S0 boundary", () => {
    const result = riskGatePolicy(S0, 0.5, 0.1);
    expect(result.allowed).toBe(true);
  });

  it("passes at exact phi volatility boundary", () => {
    const result = riskGatePolicy(0.9, PHI, 0.1);
    expect(result.allowed).toBe(true);
  });
});

describe("Policy Governance — maxDisbursement", () => {
  it("financial category uses compliance ratio", () => {
    const amount = maxDisbursement(100_000, "financial");
    expect(amount).toBeCloseTo(100_000 * COMPLIANCE_RATIO, 0);
  });

  it("operational category uses 5% max", () => {
    const amount = maxDisbursement(100_000, "operational");
    expect(amount).toBe(100_000 * 0.05);
  });

  it("emergency uses 5% max (not supermajority)", () => {
    const amount = maxDisbursement(100_000, "emergency");
    expect(amount).toBe(5000);
  });

  it("returns 0 for zero treasury", () => {
    expect(maxDisbursement(0, "financial")).toBe(0);
    expect(maxDisbursement(0, "operational")).toBe(0);
  });

  it("financial disbursement exceeds operational limit", () => {
    const financial = maxDisbursement(100_000, "financial");
    const operational = maxDisbursement(100_000, "operational");
    expect(financial).toBeGreaterThan(operational);
  });
});

describe("Policy Governance — voting windows", () => {
  it("standard window approximates 7 days in beats", () => {
    const sevenDaysMs = 7 * 24 * 3600_000;
    const expectedBeats = sevenDaysMs / HEARTBEAT_MS;
    expect(VOTING_WINDOW_STANDARD).toBeCloseTo(expectedBeats, 0);
  });

  it("emergency window approximates 24 hours in beats", () => {
    const oneDayMs = 24 * 3600_000;
    const expectedBeats = oneDayMs / HEARTBEAT_MS;
    expect(VOTING_WINDOW_EMERGENCY).toBeCloseTo(expectedBeats, 0);
  });

  it("standard window is 7x emergency window", () => {
    expect(VOTING_WINDOW_STANDARD / VOTING_WINDOW_EMERGENCY).toBeCloseTo(
      7,
      0,
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// IV. ETHICS GOVERNANCE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("Ethics Governance — ETHICAL_PRINCIPLES", () => {
  it("contains exactly 10 principles", () => {
    expect(ETHICAL_PRINCIPLES).toHaveLength(10);
  });

  it("all principles are enforceable", () => {
    for (const p of ETHICAL_PRINCIPLES) {
      expect(p.enforceable).toBe(true);
    }
  });

  it("principle IDs are sequential (E01–E10)", () => {
    for (let i = 0; i < ETHICAL_PRINCIPLES.length; i++) {
      const expected = `E${String(i + 1).padStart(2, "0")}`;
      expect(ETHICAL_PRINCIPLES[i]!.id).toBe(expected);
    }
  });

  it("includes SOVEREIGNTY as first principle", () => {
    expect(ETHICAL_PRINCIPLES[0]!.name).toBe("SOVEREIGNTY");
  });

  it("includes NON-HARM principle", () => {
    const nonHarm = ETHICAL_PRINCIPLES.find((p) => p.name === "NON-HARM");
    expect(nonHarm).toBeDefined();
    expect(nonHarm!.violationPenalty).toBe("expulsion");
  });

  it("includes CONSENT principle", () => {
    const consent = ETHICAL_PRINCIPLES.find((p) => p.name === "CONSENT");
    expect(consent).toBeDefined();
    expect(consent!.violationPenalty).toBe("expulsion");
  });

  it("includes TRANSPARENCY principle", () => {
    const transparency = ETHICAL_PRINCIPLES.find(
      (p) => p.name === "TRANSPARENCY",
    );
    expect(transparency).toBeDefined();
  });

  it("PROPORTIONALITY has warning penalty (least severe)", () => {
    const prop = ETHICAL_PRINCIPLES.find(
      (p) => p.name === "PROPORTIONALITY",
    );
    expect(prop!.violationPenalty).toBe("warning");
  });

  it("SUCCESSION_RIGHTS has expulsion penalty (most severe)", () => {
    const succ = ETHICAL_PRINCIPLES.find(
      (p) => p.name === "SUCCESSION_RIGHTS",
    );
    expect(succ!.violationPenalty).toBe("expulsion");
  });
});

describe("Ethics Governance — ethicsCheck", () => {
  it("passes when all conditions are met", () => {
    const result = ethicsCheck({
      requiresConsent: true,
      hasConsent: true,
      exposesPrivateData: false,
      harmPotential: 0.0,
      isTransparent: true,
    });
    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });

  it("fails on missing consent", () => {
    const result = ethicsCheck({
      requiresConsent: true,
      hasConsent: false,
      exposesPrivateData: false,
      harmPotential: 0.0,
      isTransparent: true,
    });
    expect(result.passed).toBe(false);
    expect(result.violations).toContain("E05:CONSENT");
  });

  it("fails on privacy violation", () => {
    const result = ethicsCheck({
      requiresConsent: false,
      hasConsent: false,
      exposesPrivateData: true,
      harmPotential: 0.0,
      isTransparent: true,
    });
    expect(result.passed).toBe(false);
    expect(result.violations).toContain("E07:PRIVACY");
  });

  it("fails on high harm potential (above S0)", () => {
    const result = ethicsCheck({
      requiresConsent: false,
      hasConsent: false,
      exposesPrivateData: false,
      harmPotential: 0.8,
      isTransparent: true,
    });
    expect(result.passed).toBe(false);
    expect(result.violations).toContain("E03:NON-HARM");
  });

  it("passes when harm potential is exactly at S0 boundary (not exceeded)", () => {
    const result = ethicsCheck({
      requiresConsent: false,
      hasConsent: false,
      exposesPrivateData: false,
      harmPotential: S0,
      isTransparent: true,
    });
    // harmPotential > S0 is false when equal, so it passes
    expect(result.passed).toBe(true);
  });

  it("fails on lack of transparency", () => {
    const result = ethicsCheck({
      requiresConsent: false,
      hasConsent: false,
      exposesPrivateData: false,
      harmPotential: 0.0,
      isTransparent: false,
    });
    expect(result.passed).toBe(false);
    expect(result.violations).toContain("E02:TRANSPARENCY");
  });

  it("accumulates multiple violations", () => {
    const result = ethicsCheck({
      requiresConsent: true,
      hasConsent: false,
      exposesPrivateData: true,
      harmPotential: 1.0,
      isTransparent: false,
    });
    expect(result.passed).toBe(false);
    expect(result.violations).toHaveLength(4);
  });

  it("passes when consent not required and no consent provided", () => {
    const result = ethicsCheck({
      requiresConsent: false,
      hasConsent: false,
      exposesPrivateData: false,
      harmPotential: 0.0,
      isTransparent: true,
    });
    expect(result.passed).toBe(true);
  });
});

describe("Ethics Governance — ethicalComplianceScore", () => {
  it("returns 1.0 for perfect compliance", () => {
    expect(ethicalComplianceScore(10, 10)).toBe(1.0);
  });

  it("returns S0 floor for zero compliance", () => {
    expect(ethicalComplianceScore(0, 10)).toBe(S0);
  });

  it("returns S0 for compliance below sovereign floor", () => {
    expect(ethicalComplianceScore(5, 10)).toBe(S0);
  });

  it("returns actual ratio when above S0", () => {
    expect(ethicalComplianceScore(9, 10)).toBe(0.9);
  });

  it("returns 0 when total principles is 0", () => {
    expect(ethicalComplianceScore(0, 0)).toBe(0);
  });

  it("never returns below S0 for nonzero total", () => {
    for (let honored = 0; honored <= 10; honored++) {
      const score = ethicalComplianceScore(honored, 10);
      expect(score).toBeGreaterThanOrEqual(S0);
    }
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// V. CHARTER GOVERNANCE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("Charter Governance — isAmendable", () => {
  it("Article I (Identity) is NOT amendable", () => {
    expect(isAmendable("I")).toBe(false);
  });

  it("Article II (Purpose) IS amendable", () => {
    expect(isAmendable("II")).toBe(true);
  });

  it("Article III (Membership) IS amendable", () => {
    expect(isAmendable("III")).toBe(true);
  });

  it("Article IV (Governance) IS amendable", () => {
    expect(isAmendable("IV")).toBe(true);
  });

  it("Article V (Treasury) IS amendable", () => {
    expect(isAmendable("V")).toBe(true);
  });

  it("Article VI (Offices) IS amendable", () => {
    expect(isAmendable("VI")).toBe(true);
  });

  it("Article VII (Amendment) IS amendable", () => {
    expect(isAmendable("VII")).toBe(true);
  });

  it("Article VIII (Dissolution) IS amendable", () => {
    expect(isAmendable("VIII")).toBe(true);
  });
});

describe("Charter Governance — IMMUTABLE_PROVISIONS", () => {
  it("only Article I is immutable", () => {
    expect(IMMUTABLE_PROVISIONS).toHaveLength(1);
    expect(IMMUTABLE_PROVISIONS[0]).toBe("I");
  });
});

describe("Charter Governance — computeCharterIntegrity", () => {
  it("returns a number", () => {
    const hash = computeCharterIntegrity(1, 0, 1);
    expect(typeof hash).toBe("number");
  });

  it("is deterministic", () => {
    const h1 = computeCharterIntegrity(1, 0, 5);
    const h2 = computeCharterIntegrity(1, 0, 5);
    expect(h1).toBe(h2);
  });

  it("changes with version", () => {
    const h1 = computeCharterIntegrity(1, 0, 5);
    const h2 = computeCharterIntegrity(2, 0, 5);
    expect(h1).not.toBe(h2);
  });

  it("changes with amendment count", () => {
    const h1 = computeCharterIntegrity(1, 0, 5);
    const h2 = computeCharterIntegrity(1, 1, 5);
    expect(h1).not.toBe(h2);
  });

  it("changes with member count", () => {
    const h1 = computeCharterIntegrity(1, 0, 5);
    const h2 = computeCharterIntegrity(1, 0, 10);
    expect(h1).not.toBe(h2);
  });

  it("produces unsigned 32-bit integer", () => {
    const hash = computeCharterIntegrity(100, 50, 200);
    expect(hash).toBeGreaterThanOrEqual(0);
    expect(hash).toBeLessThanOrEqual(4294967295);
  });
});

describe("Charter Governance — charterAmendmentRequirements", () => {
  it("requires constitutional quorum (0.809)", () => {
    const req = charterAmendmentRequirements();
    expect(req.quorum).toBe(QUORUM_CONSTITUTIONAL);
  });

  it("requires supermajority pass threshold (0.618)", () => {
    const req = charterAmendmentRequirements();
    expect(req.passThreshold).toBeCloseTo(PHI_INV, 5);
  });

  it("has 144-beat cooldown (Jubilee)", () => {
    const req = charterAmendmentRequirements();
    expect(req.cooldownBeats).toBe(JUBILEE_BEATS);
  });

  it("requires founder approval", () => {
    const req = charterAmendmentRequirements();
    expect(req.founderApprovalRequired).toBe(true);
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// VI. MACRO PROTOCOL STATE TESTS
// ═══════════════════════════════════════════════════════════════════════════════

describe("Macro State — defaultGovernanceState", () => {
  it("starts at beat 0", () => {
    const state = defaultGovernanceState();
    expect(state.currentBeat).toBe(0n);
  });

  it("starts in genesis epoch", () => {
    const state = defaultGovernanceState();
    expect(state.epoch).toBe("genesis");
  });

  it("has 1 member (Founder)", () => {
    const state = defaultGovernanceState();
    expect(state.totalMembers).toBe(1);
  });

  it("has founder voting weight (phi^4)", () => {
    const state = defaultGovernanceState();
    expect(state.totalVotingWeight).toBeCloseTo(PHI_4, 2);
  });

  it("has no active proposals", () => {
    const state = defaultGovernanceState();
    expect(state.activeProposals).toBe(0);
  });

  it("starts with coherence at S0", () => {
    const state = defaultGovernanceState();
    expect(state.coherenceR).toBe(S0);
  });

  it("risk gate is open initially", () => {
    const state = defaultGovernanceState();
    expect(state.riskGateOpen).toBe(true);
  });

  it("treasury is at 100%", () => {
    const state = defaultGovernanceState();
    expect(state.treasuryHealthBps).toBe(10_000);
  });

  it("ethical compliance is perfect", () => {
    const state = defaultGovernanceState();
    expect(state.ethicalComplianceScore).toBe(1.0);
  });

  it("no principle violations", () => {
    const state = defaultGovernanceState();
    expect(state.activePrincipleViolations).toBe(0);
  });

  it("charter version is 1", () => {
    const state = defaultGovernanceState();
    expect(state.charterVersion).toBe(1);
  });

  it("charter is not locked", () => {
    const state = defaultGovernanceState();
    expect(state.isCharterLocked).toBe(false);
  });

  it("has a valid integrity hash", () => {
    const state = defaultGovernanceState();
    expect(state.charterIntegrityHash).toBeGreaterThan(0);
  });
});

describe("Macro State — governanceHeartbeatTick", () => {
  it("advances to new beat", () => {
    const state = defaultGovernanceState();
    const next = governanceHeartbeatTick(state, 1n, 0.9);
    expect(next.currentBeat).toBe(1n);
  });

  it("transitions to infancy epoch", () => {
    const state = defaultGovernanceState();
    const next = governanceHeartbeatTick(state, 1n, 0.9);
    expect(next.epoch).toBe("infancy");
  });

  it("updates coherence", () => {
    const state = defaultGovernanceState();
    const next = governanceHeartbeatTick(state, 1n, 0.95);
    expect(next.coherenceR).toBe(0.95);
  });

  it("closes risk gate when coherence drops below S0", () => {
    const state = defaultGovernanceState();
    const next = governanceHeartbeatTick(state, 1n, 0.5);
    expect(next.riskGateOpen).toBe(false);
  });

  it("keeps risk gate open at S0 boundary", () => {
    const state = defaultGovernanceState();
    const next = governanceHeartbeatTick(state, 1n, S0);
    expect(next.riskGateOpen).toBe(true);
  });

  it("locks charter during cooldown period", () => {
    const state = { ...defaultGovernanceState(), lastAmendmentBeat: 0n };
    // In infancy, cooldown is 144 beats
    const next = governanceHeartbeatTick(state, 10n, 0.9);
    expect(next.isCharterLocked).toBe(true); // 10 < 144
  });

  it("unlocks charter after cooldown expires", () => {
    const state = { ...defaultGovernanceState(), lastAmendmentBeat: 0n };
    const next = governanceHeartbeatTick(state, 200n, 0.9);
    // In growth epoch (>144), cooldown is 34 beats, 200 > 34
    expect(next.isCharterLocked).toBe(false);
  });

  it("preserves other state fields", () => {
    const state = {
      ...defaultGovernanceState(),
      totalMembers: 5,
      activeProposals: 3,
    };
    const next = governanceHeartbeatTick(state, 10n, 0.9);
    expect(next.totalMembers).toBe(5);
    expect(next.activeProposals).toBe(3);
  });
});

describe("Macro State — isGovernanceHealthy", () => {
  it("returns true for default state", () => {
    const state = defaultGovernanceState();
    expect(isGovernanceHealthy(state)).toBe(true);
  });

  it("returns false when coherence is below S0", () => {
    const state = { ...defaultGovernanceState(), coherenceR: 0.5 };
    expect(isGovernanceHealthy(state)).toBe(false);
  });

  it("returns false when ethical compliance is below S0", () => {
    const state = {
      ...defaultGovernanceState(),
      ethicalComplianceScore: 0.5,
    };
    expect(isGovernanceHealthy(state)).toBe(false);
  });

  it("returns false when risk gate is closed", () => {
    const state = { ...defaultGovernanceState(), riskGateOpen: false };
    expect(isGovernanceHealthy(state)).toBe(false);
  });

  it("returns false when treasury is depleted", () => {
    const state = { ...defaultGovernanceState(), treasuryHealthBps: 0 };
    expect(isGovernanceHealthy(state)).toBe(false);
  });

  it("returns true at boundary conditions (all at S0)", () => {
    const state = {
      ...defaultGovernanceState(),
      coherenceR: S0,
      ethicalComplianceScore: S0,
      riskGateOpen: true,
      treasuryHealthBps: 1,
    };
    expect(isGovernanceHealthy(state)).toBe(true);
  });
});
