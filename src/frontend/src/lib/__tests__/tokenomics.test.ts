import { describe, expect, it } from "vitest";
import {
  computeTokenValue,
  computeCRPT,
  scoreSalienceItem,
  allocateSalienceBudget,
  computeCompressionEfficiency,
  benchmarkScore,
  benchmarkScorePerToken,
  computeTokenomicGain,
  cognitiveReturnTotal,
  TokenomicsRuntime,
  TaskClass,
  TaskRisk,
  DEFAULT_TOKEN_VALUE_WEIGHTS,
  DEFAULT_SALIENCE_WEIGHTS,
} from "../tokenomics";

describe("computeTokenValue", () => {
  it("returns positive value for high-quality token", () => {
    const result = computeTokenValue(4, 4, 3, 2, 2, 0);
    expect(result.tokenValue).toBeGreaterThan(0);
  });

  it("returns negative value for pure noise", () => {
    const result = computeTokenValue(0, 0, 0, 0, 0, 5);
    expect(result.tokenValue).toBeLessThan(0);
  });

  it("balances value vs noise correctly", () => {
    // Equal noise and decision quality with same weight should net zero
    const w = DEFAULT_TOKEN_VALUE_WEIGHTS;
    const result = computeTokenValue(3, 0, 0, 0, 0, 3);
    // wDecision * 3 - wNoise * 3 = 0 (both are PHI_INV)
    expect(result.tokenValue).toBeCloseTo(0, 10);
  });

  it("preserves input values in the result", () => {
    const result = computeTokenValue(1, 2, 3, 4, 5, 0.5);
    expect(result.decisionQuality).toBe(1);
    expect(result.actionUsefulness).toBe(2);
    expect(result.riskReduction).toBe(3);
    expect(result.compressionContribution).toBe(4);
    expect(result.memoryReuseValue).toBe(5);
    expect(result.noiseWaste).toBe(0.5);
  });
});

describe("computeCRPT", () => {
  it("computes correct CRPT for typical interaction", () => {
    const score = {
      decisionQuality: 4,
      actionability: 3,
      riskControl: 3,
      reuseValue: 2,
      learningGain: 1,
    };
    const result = computeCRPT(score, 500, 300);
    expect(result.cognitiveReturn).toBe(13);
    expect(result.totalTokens).toBe(800);
    expect(result.crpt).toBeCloseTo(13 / 800, 10);
  });

  it("returns zero CRPT when no tokens spent", () => {
    const score = {
      decisionQuality: 5,
      actionability: 5,
      riskControl: 5,
      reuseValue: 5,
      learningGain: 5,
    };
    const result = computeCRPT(score, 0, 0);
    expect(result.crpt).toBe(0);
  });

  it("higher CR with same tokens yields higher CRPT", () => {
    const low = computeCRPT(
      { decisionQuality: 1, actionability: 1, riskControl: 1, reuseValue: 1, learningGain: 1 },
      500, 500,
    );
    const high = computeCRPT(
      { decisionQuality: 5, actionability: 5, riskControl: 5, reuseValue: 5, learningGain: 5 },
      500, 500,
    );
    expect(high.crpt).toBeGreaterThan(low.crpt);
  });
});

describe("cognitiveReturnTotal", () => {
  it("sums all five categories", () => {
    const total = cognitiveReturnTotal({
      decisionQuality: 1,
      actionability: 2,
      riskControl: 3,
      reuseValue: 4,
      learningGain: 5,
    });
    expect(total).toBe(15);
  });
});

describe("scoreSalienceItem", () => {
  it("scores high-urgency high-risk item highly", () => {
    const score = scoreSalienceItem({
      itemId: "critical",
      label: "Critical alert",
      urgency: 1.0,
      risk: 1.0,
      missionRelevance: 0.8,
      timeSensitivity: 0.9,
      novelty: 0.7,
      knownContext: 0.0,
    });
    expect(score).toBeGreaterThan(1.0);
  });

  it("scores already-known low-urgency item near zero or negative", () => {
    const score = scoreSalienceItem({
      itemId: "known",
      label: "Already known info",
      urgency: 0.0,
      risk: 0.0,
      missionRelevance: 0.1,
      timeSensitivity: 0.0,
      novelty: 0.0,
      knownContext: 1.0,
    });
    expect(score).toBeLessThan(0.1);
  });
});

describe("allocateSalienceBudget", () => {
  it("returns empty for no items", () => {
    expect(allocateSalienceBudget([], 2000)).toEqual([]);
  });

  it("allocates more budget to higher-salience items", () => {
    const items = [
      {
        itemId: "high",
        label: "High priority",
        urgency: 0.9,
        risk: 0.8,
        missionRelevance: 0.7,
        timeSensitivity: 0.6,
        novelty: 0.5,
        knownContext: 0.0,
      },
      {
        itemId: "low",
        label: "Low priority",
        urgency: 0.1,
        risk: 0.1,
        missionRelevance: 0.1,
        timeSensitivity: 0.1,
        novelty: 0.1,
        knownContext: 0.5,
      },
    ];
    const results = allocateSalienceBudget(items, 2000);
    const high = results.find((r) => r.itemId === "high")!;
    const low = results.find((r) => r.itemId === "low")!;
    expect(high.allocatedBudget).toBeGreaterThan(low.allocatedBudget);
  });

  it("results are sorted by salience descending", () => {
    const items = [
      { itemId: "a", label: "A", urgency: 0.2, risk: 0.2, missionRelevance: 0.2, timeSensitivity: 0.2, novelty: 0.2, knownContext: 0.0 },
      { itemId: "b", label: "B", urgency: 0.9, risk: 0.9, missionRelevance: 0.9, timeSensitivity: 0.9, novelty: 0.9, knownContext: 0.0 },
    ];
    const results = allocateSalienceBudget(items, 1000);
    expect(results[0].itemId).toBe("b");
    expect(results[1].itemId).toBe("a");
  });
});

describe("computeCompressionEfficiency", () => {
  it("computes CEF correctly", () => {
    const result = computeCompressionEfficiency(4, 4, 4, 100);
    expect(result.cef).toBeCloseTo(12 / 100, 10);
    expect(result.ce).toBeCloseTo(4 / 100, 10);
  });

  it("returns zero for zero tokens", () => {
    const result = computeCompressionEfficiency(5, 5, 5, 0);
    expect(result.ce).toBe(0);
    expect(result.cef).toBe(0);
  });

  it("fewer tokens with same meaning = better efficiency", () => {
    const short = computeCompressionEfficiency(4, 4, 4, 50);
    const long = computeCompressionEfficiency(4, 4, 4, 200);
    expect(short.cef).toBeGreaterThan(long.cef);
  });
});

describe("benchmarkScore", () => {
  it("computes DQ + ACT + RISK + REUSE + ACCURACY - WASTE", () => {
    const score = benchmarkScore({
      taskClass: TaskClass.InvoiceExecution,
      decisionQuality: 4,
      actionability: 4,
      riskControl: 3,
      reuseValue: 2,
      accuracy: 5,
      waste: 1,
      tokensUsed: 1000,
    });
    expect(score).toBe(4 + 4 + 3 + 2 + 5 - 1);
  });
});

describe("computeTokenomicGain", () => {
  it("tokenomic system is superior with higher score per token", () => {
    const baseline = {
      taskClass: TaskClass.ResearchSynthesis,
      decisionQuality: 3,
      actionability: 3,
      riskControl: 2,
      reuseValue: 1,
      accuracy: 3,
      waste: 2,
      tokensUsed: 2000,
    };
    const tokenomic = {
      taskClass: TaskClass.ResearchSynthesis,
      decisionQuality: 4,
      actionability: 4,
      riskControl: 4,
      reuseValue: 3,
      accuracy: 4,
      waste: 1,
      tokensUsed: 1000,
    };
    const result = computeTokenomicGain(baseline, tokenomic);
    expect(result.isSuperior).toBe(true);
    expect(result.tokenomicGain).toBeGreaterThan(0);
  });

  it("baseline wins when tokenomic wastes too many tokens", () => {
    const baseline = {
      taskClass: TaskClass.Estimating,
      decisionQuality: 4,
      actionability: 4,
      riskControl: 3,
      reuseValue: 2,
      accuracy: 4,
      waste: 1,
      tokensUsed: 500,
    };
    const tokenomic = {
      taskClass: TaskClass.Estimating,
      decisionQuality: 4,
      actionability: 4,
      riskControl: 3,
      reuseValue: 2,
      accuracy: 4,
      waste: 1,
      tokensUsed: 5000,
    };
    const result = computeTokenomicGain(baseline, tokenomic);
    expect(result.isSuperior).toBe(false);
  });
});

describe("TokenomicsRuntime", () => {
  it("classifies task and adjusts budget", () => {
    const rt = new TokenomicsRuntime();
    rt.classifyTask(TaskClass.CashflowDecision, TaskRisk.Critical);
    rt.setBudget(1000);
    // Critical risk = PHI multiplier ≈ 1.618
    // Budget should be ~1618
    const results = rt.allocate();
    expect(results).toEqual([]); // no items added yet
  });

  it("runs full audit loop", () => {
    const rt = new TokenomicsRuntime();
    rt.classifyTask(TaskClass.ArchitectureDesign, TaskRisk.High);
    rt.setBudget(2000);
    rt.addSalienceItem({
      itemId: "arch",
      label: "Module design",
      urgency: 0.7,
      risk: 0.6,
      missionRelevance: 0.9,
      timeSensitivity: 0.3,
      novelty: 0.8,
      knownContext: 0.1,
    });

    const result = rt.audit({
      promptTokens: 600,
      outputTokens: 1200,
      cognitiveReturn: {
        decisionQuality: 4,
        actionability: 3,
        riskControl: 4,
        reuseValue: 3,
        learningGain: 2,
      },
      compressionScores: [4, 3.5, 4],
      wastedTokens: 100,
      reusableRules: 2,
    });

    expect(result.taskClass).toBe(TaskClass.ArchitectureDesign);
    expect(result.cognitiveReturn.crpt).toBeGreaterThan(0);
    expect(result.compression.cef).toBeGreaterThan(0);
    expect(result.wastedTokens).toBe(100);
    expect(result.reusableRulesExtracted).toBe(2);
  });

  it("tracks cumulative stats across interactions", () => {
    const rt = new TokenomicsRuntime();
    rt.classifyTask(TaskClass.InvoiceExecution, TaskRisk.Medium);
    rt.setBudget(1000);

    rt.audit({
      promptTokens: 200,
      outputTokens: 400,
      cognitiveReturn: {
        decisionQuality: 4,
        actionability: 5,
        riskControl: 3,
        reuseValue: 2,
        learningGain: 1,
      },
      compressionScores: [4, 5, 3],
      wastedTokens: 30,
      reusableRules: 1,
    });

    const stats = rt.getStats();
    expect(stats.interactions).toBe(1);
    expect(stats.avgCrpt).toBeGreaterThan(0);
    expect(stats.cumulativeWaste).toBe(30);
    expect(stats.cumulativeReuse).toBe(1);
    expect(stats.totalTokensSpent).toBe(600);
  });

  it("throws when audit called without classification", () => {
    const rt = new TokenomicsRuntime();
    expect(() =>
      rt.audit({
        promptTokens: 100,
        outputTokens: 100,
        cognitiveReturn: {
          decisionQuality: 1,
          actionability: 1,
          riskControl: 1,
          reuseValue: 1,
          learningGain: 1,
        },
        compressionScores: [1, 1, 1],
      }),
    ).toThrow("Task not classified");
  });
});
