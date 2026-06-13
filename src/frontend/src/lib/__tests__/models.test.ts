import { describe, expect, it } from "vitest";
import {
  type CoreSnapshot,
  defaultCoreSnapshot,
  fibTierOfBigInt,
  formatBeatBigInt,
  isJubileeDepth,
  phiMultiplierBigInt,
} from "../../models";

describe("defaultCoreSnapshot", () => {
  it("returns correct default values", () => {
    const snapshot: CoreSnapshot = defaultCoreSnapshot();
    expect(snapshot.globalR).toBe(0.75); // S0
    expect(snapshot.beat).toBe(0n);
    expect(snapshot.omnisFired).toBe(false);
  });
});

describe("phiMultiplierBigInt", () => {
  it("returns 1 for depth 0n", () => {
    expect(phiMultiplierBigInt(0n)).toBeCloseTo(1.0);
  });

  it("returns PHI for depth 1n", () => {
    expect(phiMultiplierBigInt(1n)).toBeCloseTo(1.618, 2);
  });

  it("returns PHI^2 for depth 2n", () => {
    expect(phiMultiplierBigInt(2n)).toBeCloseTo(1.618 * 1.618, 1);
  });
});

describe("isJubileeDepth", () => {
  it("returns true for Fibonacci numbers in the FIB array", () => {
    expect(isJubileeDepth(1n)).toBe(true);
    expect(isJubileeDepth(2n)).toBe(true);
    expect(isJubileeDepth(3n)).toBe(true);
    expect(isJubileeDepth(5n)).toBe(true);
    expect(isJubileeDepth(8n)).toBe(true);
    expect(isJubileeDepth(13n)).toBe(true);
    expect(isJubileeDepth(144n)).toBe(true);
  });

  it("returns false for non-Fibonacci numbers", () => {
    expect(isJubileeDepth(4n)).toBe(false);
    expect(isJubileeDepth(6n)).toBe(false);
    expect(isJubileeDepth(7n)).toBe(false);
    expect(isJubileeDepth(10n)).toBe(false);
  });
});

describe("formatBeatBigInt", () => {
  it("formats beat with hexagon prefix", () => {
    const result = formatBeatBigInt(0n);
    expect(result).toBe("⬡ 0");
  });

  it("formats large beats with locale string", () => {
    const result = formatBeatBigInt(1000n);
    // toLocaleString may vary by locale, but should contain "1" and "000"
    expect(result).toContain("⬡");
    expect(result).toContain("1");
  });
});

describe("fibTierOfBigInt", () => {
  it("returns 0 for depth 0", () => {
    expect(fibTierOfBigInt(0n)).toBe(0);
  });

  it("returns tier based on highest FIB value <= depth", () => {
    // FIB = [1,1,2,3,5,8,13,21,34,55,89,144,...]
    // depth 5 → FIB[4]=5 → tier 4
    expect(fibTierOfBigInt(5n)).toBe(4);
  });

  it("returns tier for depth between fibonacci numbers", () => {
    // depth 10: FIB[5]=8 ≤ 10, FIB[6]=13 > 10 → tier 5
    expect(fibTierOfBigInt(10n)).toBe(5);
  });

  it("returns highest tier for very large depth", () => {
    // FIB[20]=10946 → tier 20 for depth >= 10946
    expect(fibTierOfBigInt(100000n)).toBe(20);
  });

  it("returns correct tier for exact fibonacci boundary", () => {
    // depth 144 = FIB[11] → tier 11
    expect(fibTierOfBigInt(144n)).toBe(11);
  });
});
