import { describe, expect, it } from "vitest";
import {
  atr,
  computeDrawdown,
  macd,
  rsi,
  sharpeRatio,
} from "../intelligenceEngine";

describe("macd", () => {
  it("returns empty arrays for empty input", () => {
    const result = macd([]);
    expect(result.macdLine).toEqual([]);
    expect(result.signalLine).toEqual([]);
    expect(result.histogram).toEqual([]);
  });

  it("returns arrays of equal length to input", () => {
    const prices = Array.from({ length: 50 }, (_, i) => 100 + i * 0.5);
    const result = macd(prices);
    expect(result.macdLine).toHaveLength(50);
    expect(result.signalLine).toHaveLength(50);
    expect(result.histogram).toHaveLength(50);
  });

  it("macd line is difference of fast and slow EMA", () => {
    const prices = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    const result = macd(prices, 3, 5, 3);
    // MACD line should be positive when price is trending up
    // (fast EMA > slow EMA in uptrend)
    const lastMacd = result.macdLine[result.macdLine.length - 1]!;
    expect(lastMacd).toBeGreaterThan(0);
  });

  it("histogram is difference between macd and signal line", () => {
    const prices = Array.from({ length: 30 }, (_, i) => 100 + Math.sin(i) * 5);
    const result = macd(prices, 5, 10, 3);
    for (let i = 0; i < result.histogram.length; i++) {
      expect(result.histogram[i]).toBeCloseTo(
        result.macdLine[i]! - result.signalLine[i]!,
        10,
      );
    }
  });

  it("converges to zero for constant prices", () => {
    const prices = Array(50).fill(100);
    const result = macd(prices);
    const lastMacd = result.macdLine[result.macdLine.length - 1]!;
    expect(lastMacd).toBeCloseTo(0, 5);
  });
});

describe("rsi", () => {
  it("returns empty array for fewer than 2 prices", () => {
    expect(rsi([])).toEqual([]);
    expect(rsi([100])).toEqual([]);
  });

  it("returns 100 for purely rising prices", () => {
    const prices = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    const result = rsi(prices, 5);
    // With only gains, RSI should be 100
    for (const v of result) {
      expect(v).toBeCloseTo(100, 5);
    }
  });

  it("returns value near 0 for purely falling prices", () => {
    const prices = [100, 90, 80, 70, 60, 50, 40, 30, 20, 10];
    const result = rsi(prices, 5);
    // With only losses, RSI should be near 0
    for (const v of result) {
      expect(v).toBeCloseTo(0, 5);
    }
  });

  it("returns value near 50 for oscillating prices", () => {
    // Alternating up and down by equal amounts
    const prices = [
      50, 55, 50, 55, 50, 55, 50, 55, 50, 55, 50, 55, 50, 55, 50, 55,
    ];
    const result = rsi(prices, 14);
    // Should be roughly 50 for equal gains/losses
    const last = result[result.length - 1]!;
    expect(last).toBeGreaterThan(40);
    expect(last).toBeLessThan(60);
  });

  it("values are bounded between 0 and 100", () => {
    const prices = Array.from(
      { length: 30 },
      (_, i) => 100 + Math.sin(i * 0.5) * 20,
    );
    const result = rsi(prices, 7);
    for (const v of result) {
      expect(v).toBeGreaterThanOrEqual(0);
      expect(v).toBeLessThanOrEqual(100);
    }
  });
});

describe("atr", () => {
  it("returns empty array for fewer than 2 data points", () => {
    expect(atr([], [], [])).toEqual([]);
    expect(atr([10], [5], [7])).toEqual([]);
  });

  it("calculates true range correctly for simple case", () => {
    const highs = [10, 12, 14, 16, 18];
    const lows = [8, 9, 11, 13, 15];
    const closes = [9, 11, 13, 15, 17];
    const result = atr(highs, lows, closes, 3);
    // First ATR is average of first 3 true ranges
    // TR[0] = 10-8 = 2, TR[1] = max(12-9, |12-9|, |9-9|) = 3, TR[2] = max(14-11, |14-11|, |11-11|) = 3
    expect(result[0]).toBeCloseTo((2 + 3 + 3) / 3, 3);
  });

  it("returns positive values for valid input", () => {
    const highs = [110, 115, 112, 118, 120, 116, 119, 122, 117, 121];
    const lows = [100, 105, 102, 108, 110, 106, 109, 112, 107, 111];
    const closes = [105, 110, 107, 113, 115, 111, 114, 117, 112, 116];
    const result = atr(highs, lows, closes, 5);
    for (const v of result) {
      expect(v).toBeGreaterThan(0);
    }
  });

  it("handles mismatched array lengths", () => {
    const highs = [10, 12, 14, 16, 18, 20];
    const lows = [8, 9, 11, 13];
    const closes = [9, 11, 13, 15, 17];
    // Should use min length (4)
    const result = atr(highs, lows, closes, 3);
    expect(result.length).toBeGreaterThan(0);
  });
});

describe("sharpeRatio", () => {
  it("returns 0 for fewer than 2 returns", () => {
    expect(sharpeRatio([])).toBe(0);
    expect(sharpeRatio([0.05])).toBe(0);
  });

  it("returns 0 for zero-variance returns", () => {
    expect(sharpeRatio([0.01, 0.01, 0.01, 0.01])).toBe(0);
  });

  it("returns positive value for positive excess returns", () => {
    const returns = [0.02, 0.03, 0.01, 0.04, 0.02, 0.03];
    const result = sharpeRatio(returns, 0);
    expect(result).toBeGreaterThan(0);
  });

  it("returns negative value when mean return < risk-free rate", () => {
    const returns = [0.01, 0.02, -0.01, 0.01, 0.0, 0.01];
    const result = sharpeRatio(returns, 0.05);
    expect(result).toBeLessThan(0);
  });

  it("higher ratio for better risk-adjusted returns", () => {
    // Consistent returns → high Sharpe
    const consistent = [0.05, 0.04, 0.05, 0.06, 0.05, 0.04];
    // Volatile returns with same mean
    const volatile = [0.1, -0.02, 0.08, 0.01, 0.12, -0.01];
    expect(sharpeRatio(consistent)).toBeGreaterThan(sharpeRatio(volatile));
  });
});

describe("computeDrawdown", () => {
  it("returns zeros for empty input", () => {
    const result = computeDrawdown([]);
    expect(result.maxDrawdown).toBe(0);
    expect(result.currentDrawdown).toBe(0);
    expect(result.drawdownSeries).toEqual([]);
  });

  it("returns zero drawdown for monotonically increasing prices", () => {
    const prices = [10, 20, 30, 40, 50];
    const result = computeDrawdown(prices);
    expect(result.maxDrawdown).toBe(0);
    expect(result.currentDrawdown).toBe(0);
    for (const dd of result.drawdownSeries) {
      expect(dd).toBe(0);
    }
  });

  it("calculates correct max drawdown", () => {
    // Peak at 100, drops to 60 (40% drawdown), recovers
    const prices = [80, 100, 90, 80, 60, 70, 80, 90];
    const result = computeDrawdown(prices);
    // Max drawdown: (100 - 60) / 100 = 0.4
    expect(result.maxDrawdown).toBeCloseTo(0.4, 5);
  });

  it("tracks current drawdown correctly", () => {
    // Peak at 100, currently at 85 → 15% current drawdown
    const prices = [90, 100, 95, 90, 85];
    const result = computeDrawdown(prices);
    expect(result.currentDrawdown).toBeCloseTo(0.15, 5);
  });

  it("drawdown series has same length as input", () => {
    const prices = [10, 20, 15, 25, 20, 30];
    const result = computeDrawdown(prices);
    expect(result.drawdownSeries).toHaveLength(6);
  });

  it("drawdown values are between 0 and 1", () => {
    const prices = Array.from({ length: 20 }, (_, i) => 50 + Math.sin(i) * 20);
    const result = computeDrawdown(prices);
    for (const dd of result.drawdownSeries) {
      expect(dd).toBeGreaterThanOrEqual(0);
      expect(dd).toBeLessThanOrEqual(1);
    }
  });
});
