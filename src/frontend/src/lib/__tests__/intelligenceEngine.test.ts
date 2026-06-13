import { describe, expect, it } from "vitest";
import {
  bollingerBands,
  classifyRegime,
  computeArbitrageSpread,
  computeClearingHealth,
  computeSettlementVelocity,
  computeTokenExchangeRate,
  ema,
  formaProject,
  jacobsVelocity,
  kuramotoOrderParam,
  rateOfChange,
  signalStrength,
  spectralCoherence,
  tokenVelocity,
  vaelThreat,
  vonNeumannEntropy,
  WelfordStream,
} from "../intelligenceEngine";

describe("ema", () => {
  it("returns empty array for empty input", () => {
    expect(ema([], 10)).toEqual([]);
  });

  it("returns the input value for single-element array", () => {
    expect(ema([42], 10)).toEqual([42]);
  });

  it("converges toward constant input", () => {
    const constant = Array(20).fill(100);
    const result = ema(constant, 10);
    // All values should be 100 since input is constant
    for (const v of result) {
      expect(v).toBeCloseTo(100, 5);
    }
  });

  it("smooths noisy data", () => {
    const prices = [10, 12, 11, 13, 12, 14, 13, 15, 14, 16];
    const result = ema(prices, 5);
    expect(result).toHaveLength(10);
    // EMA should be smoother than raw prices
    expect(result[0]).toBe(10); // First value equals first price
    // Last EMA should be between min and max of prices
    const last = result[result.length - 1]!;
    expect(last).toBeGreaterThan(10);
    expect(last).toBeLessThan(16);
  });

  it("applies correct EMA formula", () => {
    const prices = [10, 20];
    const period = 9;
    const k = 2 / (period + 1); // 0.2
    const result = ema(prices, period);
    expect(result[0]).toBe(10);
    expect(result[1]).toBeCloseTo(10 * (1 - k) + 20 * k);
  });
});

describe("bollingerBands", () => {
  it("returns empty arrays for empty input", () => {
    const { upper, middle, lower, bandwidth } = bollingerBands([]);
    expect(upper).toEqual([]);
    expect(middle).toEqual([]);
    expect(lower).toEqual([]);
    expect(bandwidth).toEqual([]);
  });

  it("middle band equals mean of window", () => {
    const prices = [10, 20, 30, 40, 50];
    const { middle } = bollingerBands(prices, 3);
    // Last middle value should be mean of last 3: (30+40+50)/3 = 40
    expect(middle[4]).toBeCloseTo(40, 5);
  });

  it("upper is above middle and lower is below middle", () => {
    const prices = [10, 12, 11, 13, 12, 14, 13, 15, 14, 16];
    const { upper, middle, lower } = bollingerBands(prices, 5);
    for (let i = 0; i < prices.length; i++) {
      expect(upper[i]).toBeGreaterThanOrEqual(middle[i]!);
      expect(lower[i]).toBeLessThanOrEqual(middle[i]!);
    }
  });

  it("bands converge for constant prices", () => {
    const prices = Array(20).fill(50);
    const { upper, middle, lower } = bollingerBands(prices, 5);
    const last = prices.length - 1;
    expect(upper[last]).toBeCloseTo(50);
    expect(middle[last]).toBeCloseTo(50);
    expect(lower[last]).toBeCloseTo(50);
  });
});

describe("WelfordStream", () => {
  it("computes correct mean for sequence", () => {
    const w = new WelfordStream();
    w.update(10);
    w.update(20);
    w.update(30);
    expect(w.mean).toBeCloseTo(20, 5);
  });

  it("computes correct variance for sequence", () => {
    const w = new WelfordStream();
    w.update(10);
    w.update(20);
    w.update(30);
    // Sample variance of [10,20,30] = 100
    expect(w.variance).toBeCloseTo(100, 5);
  });

  it("returns zscore 0 for fewer than 2 samples", () => {
    const w = new WelfordStream();
    w.update(10);
    expect(w.zscore(15)).toBe(0);
  });

  it("returns zscore 0 when all values are the same", () => {
    const w = new WelfordStream();
    w.update(5);
    w.update(5);
    w.update(5);
    expect(w.zscore(5)).toBe(0);
  });

  it("returns correct z-score for known data", () => {
    const w = new WelfordStream();
    w.update(10);
    w.update(20);
    w.update(30);
    // mean=20, std=10, zscore(30) = (30-20)/10 = 1.0
    expect(w.zscore(30)).toBeCloseTo(1.0, 5);
    expect(w.zscore(10)).toBeCloseTo(-1.0, 5);
  });

  it("tracks count correctly", () => {
    const w = new WelfordStream();
    expect(w.n).toBe(0);
    w.update(1);
    w.update(2);
    expect(w.n).toBe(2);
  });
});

describe("kuramotoOrderParam", () => {
  it("returns 0 for empty array", () => {
    expect(kuramotoOrderParam([])).toBe(0);
  });

  it("returns 1 for all-identical phases", () => {
    const phases = [0, 0, 0, 0, 0];
    expect(kuramotoOrderParam(phases)).toBeCloseTo(1.0, 5);
  });

  it("returns near 0 for uniformly distributed phases", () => {
    // Phases equally spaced around the circle
    const N = 100;
    const phases = Array.from({ length: N }, (_, i) => (2 * Math.PI * i) / N);
    expect(kuramotoOrderParam(phases)).toBeCloseTo(0, 1);
  });

  it("returns 1 for single phase", () => {
    expect(kuramotoOrderParam([1.5])).toBeCloseTo(1.0, 5);
  });

  it("returns intermediate value for partially coherent phases", () => {
    // Two groups of synchronized oscillators
    const phases = [0, 0, 0, Math.PI, Math.PI, Math.PI];
    // Should be 0 (two anti-phase groups cancel)
    expect(kuramotoOrderParam(phases)).toBeCloseTo(0, 1);
  });
});

describe("formaProject", () => {
  it("returns capital unchanged for zero rate", () => {
    expect(formaProject(1000, 0, 1, 10)).toBe(1000);
  });

  it("compounds capital over beats", () => {
    const result = formaProject(1000, 0.01, 1.0, 100);
    // exp(0.01 * 100 * 1.0) = exp(1) ≈ 2.718
    expect(result).toBeCloseTo(1000 * Math.E, 1);
  });

  it("clamps negative rate to zero", () => {
    const result = formaProject(1000, -0.05, 1.0, 100);
    // Rate is clamped to 0, so result = capital * exp(0) = capital
    expect(result).toBe(1000);
  });

  it("clamps thyroid mod to minimum 0.1", () => {
    const result = formaProject(1000, 0.01, 0.0, 100);
    // thyroidMod clamped to 0.1: exp(0.01 * 100 * 0.1) = exp(0.1)
    expect(result).toBeCloseTo(1000 * Math.exp(0.1), 1);
  });
});

describe("vonNeumannEntropy", () => {
  it("returns 0 for empty array", () => {
    expect(vonNeumannEntropy([])).toBe(0);
  });

  it("returns 0 for all-zero activations", () => {
    expect(vonNeumannEntropy([0, 0, 0])).toBe(0);
  });

  it("returns 1 for uniform activations (max entropy)", () => {
    const result = vonNeumannEntropy([1, 1, 1, 1]);
    expect(result).toBeCloseTo(1.0, 5);
  });

  it("returns 0 for single non-zero activation (concentrated)", () => {
    const result = vonNeumannEntropy([1, 0, 0, 0]);
    expect(result).toBeCloseTo(0, 5);
  });

  it("handles negative activations (uses absolute value)", () => {
    const result = vonNeumannEntropy([-1, -1, -1, -1]);
    expect(result).toBeCloseTo(1.0, 5);
  });
});

describe("classifyRegime", () => {
  it("returns TRANSITION for empty arrays", () => {
    expect(classifyRegime([], [])).toBe("TRANSITION");
  });

  it("returns BULL when ema21 > ema200 with spread", () => {
    const ema21 = [100, 105, 110];
    const ema200 = [90, 92, 95];
    expect(classifyRegime(ema21, ema200)).toBe("BULL");
  });

  it("returns BEAR when ema21 < ema200 with spread", () => {
    const ema21 = [90, 88, 85];
    const ema200 = [100, 99, 98];
    expect(classifyRegime(ema21, ema200)).toBe("BEAR");
  });

  it("returns TRANSITION when spread is very small", () => {
    const ema21 = [100.0];
    const ema200 = [100.1];
    expect(classifyRegime(ema21, ema200)).toBe("TRANSITION");
  });
});

describe("rateOfChange", () => {
  it("returns 0 when not enough data", () => {
    expect(rateOfChange([10, 20], 5)).toBe(0);
  });

  it("calculates correct rate of change", () => {
    const prices = [100, 110, 120, 130, 140, 150];
    const result = rateOfChange(prices, 3);
    // (150 - 120) / 120 = 0.25
    expect(result).toBeCloseTo(0.25, 5);
  });

  it("returns 0 when past price is 0", () => {
    const prices = [0, 10, 20, 30, 40];
    expect(rateOfChange(prices, 4)).toBe(0);
  });

  it("handles negative changes", () => {
    const prices = [100, 90, 80, 70, 60, 50];
    const result = rateOfChange(prices, 3);
    // (50 - 80) / 80 = -0.375
    expect(result).toBeCloseTo(-0.375, 5);
  });
});

describe("signalStrength", () => {
  it("returns 0 for zero inputs", () => {
    expect(signalStrength(0, 0, 1)).toBe(0);
  });

  it("returns high value for strong momentum and coherence", () => {
    const result = signalStrength(0.5, 0.5, 0.0);
    expect(result).toBeGreaterThan(0.5);
  });

  it("is clamped to [0, 1]", () => {
    const result = signalStrength(10, 10, 0);
    expect(result).toBeLessThanOrEqual(1);
  });

  it("entropy contributes inversely (high entropy reduces signal)", () => {
    const lowEntropy = signalStrength(0.1, 0.1, 0.0);
    const highEntropy = signalStrength(0.1, 0.1, 1.0);
    expect(lowEntropy).toBeGreaterThan(highEntropy);
  });
});

describe("tokenVelocity", () => {
  it("returns 0 for zero circulating supply", () => {
    expect(tokenVelocity(100, 100, 0)).toBe(0);
  });

  it("returns value between 0 and 1", () => {
    const result = tokenVelocity(10, 5, 1000);
    expect(result).toBeGreaterThanOrEqual(0);
    expect(result).toBeLessThanOrEqual(1);
  });

  it("increases with higher mint/burn rates", () => {
    const low = tokenVelocity(1, 1, 1000);
    const high = tokenVelocity(100, 100, 1000);
    expect(high).toBeGreaterThan(low);
  });
});

describe("vaelThreat", () => {
  it("returns 0 for perfect coherence and law score without ares", () => {
    const result = vaelThreat(2.0, false, 1.0, 0.0);
    expect(result).toBeCloseTo(0, 5);
  });

  it("increases when ares is armed", () => {
    const unarmed = vaelThreat(1.0, false, 1.0, 0.0);
    const armed = vaelThreat(1.0, true, 1.0, 0.0);
    expect(armed).toBeGreaterThan(unarmed);
  });

  it("increases with low coherence", () => {
    const high = vaelThreat(2.0, false, 1.0, 0.0);
    const low = vaelThreat(0.1, false, 1.0, 0.0);
    expect(low).toBeGreaterThan(high);
  });

  it("is clamped to [0, 1]", () => {
    const result = vaelThreat(0, true, 0, 1);
    expect(result).toBeLessThanOrEqual(1);
    expect(result).toBeGreaterThanOrEqual(0);
  });
});

describe("jacobsVelocity", () => {
  it("returns base multiplier times sacesi", () => {
    // rung 0 → multiplier 1.0, sacesi 2.0 → 1.0 * 2.0 = 2.0
    expect(jacobsVelocity(0, 2.0)).toBeCloseTo(2.0);
  });

  it("clamps rung to valid range", () => {
    // rung 10 should be clamped to 4
    const result = jacobsVelocity(10, 1.5);
    expect(result).toBeCloseTo(1.5 * 1.5); // rung 4 mult is 1.5
  });

  it("uses at least 1.0 for sacesi", () => {
    const result = jacobsVelocity(0, 0.5);
    expect(result).toBeCloseTo(1.0); // max(1.0, 0.5) = 1.0 * 1.0
  });
});

describe("spectralCoherence", () => {
  it("returns 1 for fewer than 2 entries", () => {
    expect(spectralCoherence([[1, 2, 3]])).toBe(1);
    expect(spectralCoherence([])).toBe(1);
  });

  it("returns 1 for identical activation patterns", () => {
    const history = [
      [1, 0, 0],
      [1, 0, 0],
      [1, 0, 0],
    ];
    expect(spectralCoherence(history)).toBeCloseTo(1.0, 3);
  });

  it("returns lower value for uncorrelated patterns", () => {
    const history = [
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
    ];
    const result = spectralCoherence(history);
    expect(result).toBeLessThan(1.0);
  });
});

describe("computeTokenExchangeRate", () => {
  it("returns 0 for zero token balance", () => {
    expect(computeTokenExchangeRate(1000, 0, 2.0)).toBe(0);
  });

  it("returns 0 for zero forma capital", () => {
    expect(computeTokenExchangeRate(0, 1000, 2.0)).toBe(0);
  });

  it("calculates rate with formula and cap", () => {
    const result = computeTokenExchangeRate(1000, 100, 2.0);
    // raw = (1000 * max(1,2)) / (100+1) = 2000/101 ≈ 19.8
    // cap = 1000 * 0.1 = 100
    // min(19.8, 100) = 19.8
    expect(result).toBeCloseTo(2000 / 101, 1);
  });

  it("caps at 10% of forma capital", () => {
    // Very small token balance → rate would explode
    const result = computeTokenExchangeRate(1000, 1, 100.0);
    expect(result).toBeLessThanOrEqual(100); // 1000 * 0.1
  });
});

describe("computeSettlementVelocity", () => {
  it("returns 0 for empty settlements", () => {
    expect(computeSettlementVelocity([], 10)).toBe(0);
  });

  it("returns 0 for zero window size", () => {
    expect(
      computeSettlementVelocity([{ beat: 1n, formaValue: 100 }], 0),
    ).toBe(0);
  });

  it("calculates settlements per 100 beats", () => {
    const settlements = [
      { beat: 10n, formaValue: 100 },
      { beat: 20n, formaValue: 200 },
      { beat: 30n, formaValue: 150 },
    ];
    const result = computeSettlementVelocity(settlements, 20);
    // 3 settlements over 20 beats → (3/20)*100 = 15
    expect(result).toBeCloseTo(15, 1);
  });
});

describe("computeClearingHealth", () => {
  it("returns 1.0 for zero total balance", () => {
    expect(computeClearingHealth([100, 200], [0, 0])).toBe(1.0);
  });

  it("returns clamped ratio of reserves to balances", () => {
    const result = computeClearingHealth([50, 50], [100, 100]);
    // totalReserve=100, totalBalance=200 → 100/(200+1) ≈ 0.498
    expect(result).toBeCloseTo(100 / 201, 3);
  });

  it("caps at 1.0", () => {
    const result = computeClearingHealth([1000], [10]);
    expect(result).toBeLessThanOrEqual(1.0);
  });
});

describe("computeArbitrageSpread", () => {
  it("returns 0 for fewer than 2 non-zero rates", () => {
    expect(computeArbitrageSpread([0, 0, 5])).toBe(0);
    expect(computeArbitrageSpread([])).toBe(0);
  });

  it("returns 0 for identical rates", () => {
    expect(computeArbitrageSpread([10, 10, 10])).toBe(0);
  });

  it("calculates spread correctly", () => {
    const result = computeArbitrageSpread([10, 20]);
    // max=20, min=10, mid=15, spread = (20-10)/15 = 0.6667
    expect(result).toBeCloseTo(10 / 15, 3);
  });

  it("filters out zero rates", () => {
    const result = computeArbitrageSpread([0, 10, 20, 0]);
    expect(result).toBeCloseTo(10 / 15, 3);
  });
});
