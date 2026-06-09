import { describe, expect, it } from "vitest";
import {
  COMPLIANCE_RATIO,
  FIB,
  HEARTBEAT_MS,
  JUBILEE_BEATS,
  LAWS,
  PHI,
  PHI_INV,
  S0,
  applyS0,
  cardiacOutput,
  checkOmnis,
  computeComplianceLock,
  computeEmission,
  computeEntanglaHz,
  computePhaseLockDelta,
  computeTau,
  enforcePhiCoupling,
  isCoherentEnough,
  isHealthyHRV,
  isJubilee,
  isPhiDerived,
  lawByNumber,
  lawHasPenalty,
  phiMultiplier,
  phiSpiralRadius,
} from "../../phi";

describe("phi constants", () => {
  it("PHI is approximately 1.618", () => {
    expect(PHI).toBeCloseTo(1.618033988749895, 10);
  });

  it("PHI_INV is 1/PHI", () => {
    expect(PHI_INV).toBeCloseTo(1 / PHI, 10);
  });

  it("PHI * PHI_INV = 1", () => {
    expect(PHI * PHI_INV).toBeCloseTo(1.0, 10);
  });

  it("S0 is 0.75 (sovereign floor)", () => {
    expect(S0).toBe(0.75);
  });

  it("HEARTBEAT_MS is 873.0", () => {
    expect(HEARTBEAT_MS).toBe(873.0);
  });

  it("JUBILEE_BEATS is 144 (F(12))", () => {
    expect(JUBILEE_BEATS).toBe(144);
  });

  it("FIB sequence is correct", () => {
    expect(FIB[0]).toBe(1);
    expect(FIB[1]).toBe(1);
    expect(FIB[2]).toBe(2);
    expect(FIB[3]).toBe(3);
    expect(FIB[4]).toBe(5);
    expect(FIB[5]).toBe(8);
    expect(FIB[11]).toBe(144);
    // Verify fibonacci property
    for (let i = 2; i < FIB.length; i++) {
      expect(FIB[i]).toBe(FIB[i - 1]! + FIB[i - 2]!);
    }
  });

  it("COMPLIANCE_RATIO equals PHI_INV^3", () => {
    expect(COMPLIANCE_RATIO).toBeCloseTo(PHI_INV ** 3, 10);
  });
});

describe("LAWS registry", () => {
  it("contains 49 laws", () => {
    expect(LAWS.length).toBe(49);
  });

  it("laws are numbered sequentially", () => {
    for (let i = 0; i < LAWS.length; i++) {
      expect(LAWS[i]!.number).toBe(i + 1);
    }
  });

  it("all laws have required fields", () => {
    for (const law of LAWS) {
      expect(law.name).toBeTruthy();
      expect(law.principle).toBeTruthy();
      expect(law.enforcementFn).toBeTruthy();
      expect(law.absoluteAnchor).toBeGreaterThanOrEqual(1);
      expect(law.absoluteAnchor).toBeLessThanOrEqual(20);
      expect(typeof law.proofPenalty).toBe("boolean");
    }
  });
});

describe("lawByNumber", () => {
  it("returns the correct law by number", () => {
    const law = lawByNumber(1);
    expect(law?.name).toBe("PHI LAW");
  });

  it("returns undefined for invalid number", () => {
    expect(lawByNumber(0)).toBeUndefined();
    expect(lawByNumber(100)).toBeUndefined();
  });
});

describe("lawHasPenalty", () => {
  it("returns true for laws with penalties", () => {
    // L05 EXCLUSION has proofPenalty: true
    expect(lawHasPenalty(5)).toBe(true);
  });

  it("returns false for laws without penalties", () => {
    // L01 PHI LAW has proofPenalty: false
    expect(lawHasPenalty(1)).toBe(false);
  });

  it("returns false for non-existent law", () => {
    expect(lawHasPenalty(999)).toBe(false);
  });
});

describe("phiMultiplier", () => {
  it("returns 1 for depth 0", () => {
    expect(phiMultiplier(0)).toBeCloseTo(1.0, 10);
  });

  it("returns PHI for depth 1", () => {
    expect(phiMultiplier(1)).toBeCloseTo(PHI, 10);
  });

  it("returns PHI^2 for depth 2", () => {
    expect(phiMultiplier(2)).toBeCloseTo(PHI * PHI, 10);
  });

  it("returns PHI_INV for depth -1", () => {
    expect(phiMultiplier(-1)).toBeCloseTo(PHI_INV, 10);
  });

  it("handles large depths without overflow", () => {
    const result = phiMultiplier(50);
    expect(result).toBeGreaterThan(0);
    expect(Number.isFinite(result)).toBe(true);
  });
});

describe("isJubilee", () => {
  it("returns true for beat 0 (0 % 144 === 0)", () => {
    expect(isJubilee(0)).toBe(true);
  });

  it("returns true for beat 144", () => {
    expect(isJubilee(144)).toBe(true);
  });

  it("returns true for beat 288", () => {
    expect(isJubilee(288)).toBe(true);
  });

  it("returns false for non-jubilee beat", () => {
    expect(isJubilee(1)).toBe(false);
    expect(isJubilee(143)).toBe(false);
    expect(isJubilee(145)).toBe(false);
  });
});

describe("applyS0", () => {
  it("returns S0 for values below the floor", () => {
    expect(applyS0(0)).toBe(S0);
    expect(applyS0(0.5)).toBe(S0);
    expect(applyS0(-1)).toBe(S0);
  });

  it("returns the value for values above S0", () => {
    expect(applyS0(0.9)).toBe(0.9);
    expect(applyS0(1.0)).toBe(1.0);
  });

  it("returns S0 for exactly S0", () => {
    expect(applyS0(S0)).toBe(S0);
  });
});

describe("computeEmission", () => {
  it("returns 0 for zero R", () => {
    expect(computeEmission(0)).toBe(0);
  });

  it("returns 0 for negative R", () => {
    expect(computeEmission(-1)).toBe(0);
  });

  it("returns 1 for R=1 (R^PHI = 1^PHI = 1)", () => {
    expect(computeEmission(1)).toBeCloseTo(1.0, 10);
  });

  it("returns R^PHI for positive R", () => {
    const r = 0.8;
    const expected = Math.exp(PHI * Math.log(r));
    expect(computeEmission(r)).toBeCloseTo(expected, 10);
  });
});

describe("computeEntanglaHz", () => {
  it("returns geometric mean * Schumann frequency", () => {
    const result = computeEntanglaHz(1.0, 1.0);
    // sqrt(1*1) * 7.83 = 7.83
    expect(result).toBeCloseTo(7.83, 2);
  });

  it("returns 0 when one input is 0", () => {
    expect(computeEntanglaHz(0, 1.0)).toBe(0);
  });

  it("computes correctly for arbitrary values", () => {
    const result = computeEntanglaHz(4.0, 9.0);
    // sqrt(4*9) * 7.83 = 6 * 7.83 = 46.98
    expect(result).toBeCloseTo(6 * 7.83, 2);
  });
});

describe("checkOmnis", () => {
  it("returns true when both conditions are met", () => {
    expect(checkOmnis(0.95, 111.0)).toBe(true);
    expect(checkOmnis(0.99, 111.2)).toBe(true);
  });

  it("returns false when R is below threshold", () => {
    expect(checkOmnis(0.94, 111.0)).toBe(false);
  });

  it("returns false when frequency is too far from 111Hz", () => {
    expect(checkOmnis(0.95, 112.0)).toBe(false);
    expect(checkOmnis(0.95, 110.0)).toBe(false);
  });

  it("allows frequency within 0.5Hz tolerance", () => {
    expect(checkOmnis(0.95, 111.4)).toBe(true);
    expect(checkOmnis(0.95, 110.6)).toBe(true);
  });
});

describe("computePhaseLockDelta", () => {
  it("returns 1 for identical phases", () => {
    expect(computePhaseLockDelta(0, 0)).toBeCloseTo(1.0);
    expect(computePhaseLockDelta(1.0, 1.0)).toBeCloseTo(1.0);
  });

  it("returns 0 for phases PI/2 apart", () => {
    expect(computePhaseLockDelta(0, Math.PI / 2)).toBeCloseTo(0, 5);
  });

  it("returns 1 for phases PI apart (absolute cos)", () => {
    expect(computePhaseLockDelta(0, Math.PI)).toBeCloseTo(1, 5);
  });
});

describe("isCoherentEnough", () => {
  it("returns true for identical phases", () => {
    expect(isCoherentEnough(0, 0)).toBe(true);
  });

  it("returns false for phases that produce low delta", () => {
    // cos(PI/2) = 0, which is < S0
    expect(isCoherentEnough(0, Math.PI / 2)).toBe(false);
  });

  it("returns true for phases PI apart (|cos(PI)| = 1 >= 0.75)", () => {
    expect(isCoherentEnough(0, Math.PI)).toBe(true);
  });
});

describe("computeComplianceLock", () => {
  it("returns correct locked amount", () => {
    const amount = 1000;
    const expected = amount * COMPLIANCE_RATIO;
    expect(computeComplianceLock(amount)).toBeCloseTo(expected, 10);
  });

  it("returns 0 for 0 amount", () => {
    expect(computeComplianceLock(0)).toBe(0);
  });

  it("compliance ratio is approximately 23.6%", () => {
    expect(computeComplianceLock(100)).toBeCloseTo(23.6, 0);
  });
});

describe("computeTau", () => {
  it("returns 0 for beat 0", () => {
    expect(computeTau(0, 5)).toBe(0);
  });

  it("returns beat for depth 0 (phi^0 = 1)", () => {
    expect(computeTau(10, 0)).toBeCloseTo(10, 10);
  });

  it("multiplies beat by phi^depth", () => {
    const result = computeTau(100, 2);
    expect(result).toBeCloseTo(100 * PHI * PHI, 5);
  });
});

describe("isPhiDerived", () => {
  it("returns true for PHI", () => {
    expect(isPhiDerived(PHI)).toBe(true);
  });

  it("returns true for PHI_INV (phi^-1)", () => {
    expect(isPhiDerived(PHI_INV)).toBe(true);
  });

  it("returns true for 1.0 (phi^0)", () => {
    expect(isPhiDerived(1.0)).toBe(true);
  });

  it("returns true for PHI^2", () => {
    expect(isPhiDerived(PHI * PHI)).toBe(true);
  });

  it("returns false for arbitrary values", () => {
    expect(isPhiDerived(2.0)).toBe(false);
    expect(isPhiDerived(3.14)).toBe(false);
  });

  it("respects custom epsilon", () => {
    expect(isPhiDerived(PHI + 0.01, 0.02)).toBe(true);
    expect(isPhiDerived(PHI + 0.01, 0.001)).toBe(false);
  });
});

describe("enforcePhiCoupling", () => {
  it("returns PHI for field type 1 (expansive)", () => {
    expect(enforcePhiCoupling(1)).toBeCloseTo(PHI);
  });

  it("returns PHI_INV for field type 2 (receptive)", () => {
    expect(enforcePhiCoupling(2)).toBeCloseTo(PHI_INV);
  });

  it("returns 1.0 for field type 3 (mediator)", () => {
    expect(enforcePhiCoupling(3)).toBe(1.0);
  });
});

describe("cardiacOutput", () => {
  it("returns product of heart rate and stroke volume", () => {
    expect(cardiacOutput(0.5, 0.8)).toBeCloseTo(0.4);
  });

  it("returns 0 when either input is 0", () => {
    expect(cardiacOutput(0, 0.8)).toBe(0);
    expect(cardiacOutput(0.5, 0)).toBe(0);
  });
});

describe("isHealthyHRV", () => {
  it("returns true when actual is within phi-inverse tolerance", () => {
    // baseInterval=873, tolerance=873*PHI_INV ≈ 539
    // So [873-539, 873+539] = [334, 1412] is the healthy range
    expect(isHealthyHRV(873, 873)).toBe(true);
    expect(isHealthyHRV(873, 900)).toBe(true);
    expect(isHealthyHRV(873, 500)).toBe(true);
  });

  it("returns false when actual exceeds tolerance", () => {
    // 873 * PHI_INV ≈ 539.5
    // 873 + 540 = 1413 should be just at boundary
    expect(isHealthyHRV(873, 0)).toBe(false); // |0-873| = 873 > 539
  });

  it("handles symmetric bounds", () => {
    const base = 100;
    const tolerance = base * PHI_INV; // ≈ 61.8
    expect(isHealthyHRV(100, 100 + 60)).toBe(true);
    expect(isHealthyHRV(100, 100 - 60)).toBe(true);
    expect(isHealthyHRV(100, 100 + 70)).toBe(false);
    expect(isHealthyHRV(100, 100 - 70)).toBe(false);
  });
});

describe("phiSpiralRadius", () => {
  it("returns 1 for depth 0", () => {
    expect(phiSpiralRadius(0)).toBeCloseTo(1.0, 10);
  });

  it("grows exponentially with depth", () => {
    const r1 = phiSpiralRadius(1);
    const r2 = phiSpiralRadius(2);
    expect(r2).toBeGreaterThan(r1);
    // Ratio should be consistent: e^(b*1) 
    expect(r2 / r1).toBeCloseTo(r1 / 1.0, 5);
  });
});
