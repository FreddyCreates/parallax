// ─── PARALLAX Tokenomics Engine ─────────────────────────────────────────────
// Implements the Measurement & Benchmarking Framework (Section 15) in TypeScript.
// Pure math engine — no React, no side effects, fully deterministic.
//
// Components:
//   1. Token Value Function (TV)
//   2. Cognitive Return Per Token (CRPT)
//   3. Salience Allocation Engine
//   4. Compression Efficiency Metrics (CE / CEF)
//   5. Benchmark Scoring (Tokenomic vs Non-Tokenomic)
//   6. Runtime Measurement Loop
// ─────────────────────────────────────────────────────────────────────────────

// ── Constants (phi-derived, mirroring phi.ts) ─────────────────────────────────
const PHI = 1.6180339887498948;
const PHI_INV = 1.0 / PHI; // 0.618
const PHI_INV_2 = PHI_INV * PHI_INV; // 0.382
const PHI_INV_3 = PHI_INV * PHI_INV * PHI_INV; // 0.236

// ── Enums ─────────────────────────────────────────────────────────────────────

export enum TaskClass {
  InvoiceExecution = "invoice_execution",
  Estimating = "estimating",
  CashflowDecision = "cashflow_decision",
  ProposalGeneration = "proposal_generation",
  ResearchSynthesis = "research_synthesis",
  ArchitectureDesign = "architecture_design",
  RedTeamReview = "red_team_review",
  MemoryConsolidation = "memory_consolidation",
}

export enum TaskRisk {
  Low = "low",
  Medium = "medium",
  High = "high",
  Critical = "critical",
}

// ── Interfaces ────────────────────────────────────────────────────────────────

export interface TokenValueWeights {
  wDecision: number;
  wAction: number;
  wRisk: number;
  wCompression: number;
  wMemory: number;
  wNoise: number;
}

export interface TokenValueScore {
  decisionQuality: number;
  actionUsefulness: number;
  riskReduction: number;
  compressionContribution: number;
  memoryReuseValue: number;
  noiseWaste: number;
  tokenValue: number;
  weights: TokenValueWeights;
}

export interface CognitiveReturnScore {
  decisionQuality: number;
  actionability: number;
  riskControl: number;
  reuseValue: number;
  learningGain: number;
}

export interface CRPTResult {
  cognitiveReturn: number;
  promptTokens: number;
  outputTokens: number;
  totalTokens: number;
  crpt: number;
}

export interface SalienceItem {
  itemId: string;
  label: string;
  urgency: number;
  risk: number;
  missionRelevance: number;
  timeSensitivity: number;
  novelty: number;
  knownContext: number;
}

export interface SalienceWeights {
  alpha: number;
  beta: number;
  gamma: number;
  delta: number;
  epsilon: number;
  zeta: number;
}

export interface SalienceResult {
  itemId: string;
  label: string;
  salienceScore: number;
  allocatedBudget: number;
}

export interface CompressionResult {
  informationRetained: number;
  actionClarity: number;
  riskPreserved: number;
  outputTokens: number;
  ce: number;
  cef: number;
}

export interface BenchmarkScoreInput {
  taskClass: TaskClass;
  decisionQuality: number;
  actionability: number;
  riskControl: number;
  reuseValue: number;
  accuracy: number;
  waste: number;
  tokensUsed: number;
}

export interface TokenomicGainResult {
  scoreA: number;
  tokensA: number;
  scoreB: number;
  tokensB: number;
  sptA: number;
  sptB: number;
  tokenomicGain: number;
  isSuperior: boolean;
}

export interface MeasurementLoopResult {
  taskClass: TaskClass;
  riskLevel: TaskRisk;
  salienceResults: SalienceResult[];
  totalBudget: number;
  cognitiveReturn: CRPTResult;
  compression: CompressionResult;
  wastedTokens: number;
  reusableRulesExtracted: number;
  timestampMs: number;
}

export interface RuntimeStats {
  interactions: number;
  avgCrpt: number;
  avgCef: number;
  cumulativeWaste: number;
  cumulativeReuse: number;
  budgetAdjustment: number;
  totalTokensSpent: number;
}

// ── Default Weights ───────────────────────────────────────────────────────────

export const DEFAULT_TOKEN_VALUE_WEIGHTS: TokenValueWeights = {
  wDecision: PHI_INV,
  wAction: PHI_INV,
  wRisk: PHI_INV_2,
  wCompression: PHI_INV_3,
  wMemory: PHI_INV_3,
  wNoise: PHI_INV,
};

export const DEFAULT_SALIENCE_WEIGHTS: SalienceWeights = {
  alpha: PHI_INV,
  beta: PHI_INV,
  gamma: PHI_INV_2,
  delta: PHI_INV_2,
  epsilon: PHI_INV_3,
  zeta: PHI_INV,
};

// ═══════════════════════════════════════════════════════════════════════════════
// 15.1 TOKEN VALUE FUNCTION
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Compute Token Value: TV(t) = w_d*D + w_a*A + w_r*R + w_c*C + w_m*M - w_n*N
 *
 * Each input scored [0, 5]. Positive TV = value contribution; negative = waste.
 */
export function computeTokenValue(
  decisionQuality: number,
  actionUsefulness: number,
  riskReduction: number,
  compressionContribution: number,
  memoryReuseValue: number,
  noiseWaste: number,
  weights: TokenValueWeights = DEFAULT_TOKEN_VALUE_WEIGHTS,
): TokenValueScore {
  const tv =
    weights.wDecision * decisionQuality +
    weights.wAction * actionUsefulness +
    weights.wRisk * riskReduction +
    weights.wCompression * compressionContribution +
    weights.wMemory * memoryReuseValue -
    weights.wNoise * noiseWaste;

  return {
    decisionQuality,
    actionUsefulness,
    riskReduction,
    compressionContribution,
    memoryReuseValue,
    noiseWaste,
    tokenValue: tv,
    weights,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 15.2 COGNITIVE RETURN PER TOKEN
// ═══════════════════════════════════════════════════════════════════════════════

/** Total cognitive return from a score. */
export function cognitiveReturnTotal(score: CognitiveReturnScore): number {
  return (
    score.decisionQuality +
    score.actionability +
    score.riskControl +
    score.reuseValue +
    score.learningGain
  );
}

/**
 * Compute CRPT = CognitiveReturn / (PromptTokens + OutputTokens)
 */
export function computeCRPT(
  score: CognitiveReturnScore,
  promptTokens: number,
  outputTokens: number,
): CRPTResult {
  const totalTokens = promptTokens + outputTokens;
  const cr = cognitiveReturnTotal(score);
  const crpt = totalTokens > 0 ? cr / totalTokens : 0;

  return {
    cognitiveReturn: cr,
    promptTokens,
    outputTokens,
    totalTokens,
    crpt,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 15.3 SALIENCE ALLOCATION ENGINE
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Score a single salience item.
 * S_i = α*U + β*R + γ*M + δ*T + ε*N - ζ*K
 */
export function scoreSalienceItem(
  item: SalienceItem,
  weights: SalienceWeights = DEFAULT_SALIENCE_WEIGHTS,
): number {
  return (
    weights.alpha * item.urgency +
    weights.beta * item.risk +
    weights.gamma * item.missionRelevance +
    weights.delta * item.timeSensitivity +
    weights.epsilon * item.novelty -
    weights.zeta * item.knownContext
  );
}

/**
 * Allocate token budget across items proportional to salience.
 * B_i = B_total * (S_i / ΣS)
 */
export function allocateSalienceBudget(
  items: SalienceItem[],
  totalBudget: number,
  weights: SalienceWeights = DEFAULT_SALIENCE_WEIGHTS,
): SalienceResult[] {
  if (items.length === 0) return [];

  const scored = items.map((item) => ({
    item,
    score: Math.max(0, scoreSalienceItem(item, weights)),
  }));

  const totalSalience = scored.reduce((sum, s) => sum + s.score, 0);

  const results: SalienceResult[] = scored.map(({ item, score }) => ({
    itemId: item.itemId,
    label: item.label,
    salienceScore: score,
    allocatedBudget:
      totalSalience > 0 ? Math.floor(totalBudget * (score / totalSalience)) : 0,
  }));

  // Sort descending by salience
  results.sort((a, b) => b.salienceScore - a.salienceScore);
  return results;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 15.4 COMPRESSION EFFICIENCY METRICS
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Compute Compression Efficiency.
 * CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
 */
export function computeCompressionEfficiency(
  informationRetained: number,
  actionClarity: number,
  riskPreserved: number,
  outputTokens: number,
): CompressionResult {
  const meaningPreserved = (informationRetained + actionClarity + riskPreserved) / 3.0;
  const ce = outputTokens > 0 ? meaningPreserved / outputTokens : 0;
  const cef =
    outputTokens > 0
      ? (informationRetained + actionClarity + riskPreserved) / outputTokens
      : 0;

  return {
    informationRetained,
    actionClarity,
    riskPreserved,
    outputTokens,
    ce,
    cef,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 15.5 BENCHMARK SCORING
// ═══════════════════════════════════════════════════════════════════════════════

/** Compute benchmark score: DQ + ACT + RISK + REUSE + ACCURACY - WASTE */
export function benchmarkScore(input: BenchmarkScoreInput): number {
  return (
    input.decisionQuality +
    input.actionability +
    input.riskControl +
    input.reuseValue +
    input.accuracy -
    input.waste
  );
}

/** Score per token for a benchmark result. */
export function benchmarkScorePerToken(input: BenchmarkScoreInput): number {
  if (input.tokensUsed === 0) return 0;
  return benchmarkScore(input) / input.tokensUsed;
}

/**
 * Compute Tokenomic Gain: SPT_B - SPT_A
 * System B is superior when gain > 0.
 */
export function computeTokenomicGain(
  scoreA: BenchmarkScoreInput,
  scoreB: BenchmarkScoreInput,
): TokenomicGainResult {
  const sptA = benchmarkScorePerToken(scoreA);
  const sptB = benchmarkScorePerToken(scoreB);
  const gain = sptB - sptA;

  return {
    scoreA: benchmarkScore(scoreA),
    tokensA: scoreA.tokensUsed,
    scoreB: benchmarkScore(scoreB),
    tokensB: scoreB.tokensUsed,
    sptA,
    sptB,
    tokenomicGain: gain,
    isSuperior: gain > 0,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// 15.6 RUNTIME MEASUREMENT LOOP
// ═══════════════════════════════════════════════════════════════════════════════

const RISK_MULTIPLIERS: Record<TaskRisk, number> = {
  [TaskRisk.Low]: PHI_INV_3,
  [TaskRisk.Medium]: PHI_INV,
  [TaskRisk.High]: 1.0,
  [TaskRisk.Critical]: PHI,
};

/**
 * TokenomicsRuntime — Deployable measurement loop for browser/frontend use.
 *
 * Tracks interactions, adapts budget allocation over time, and produces
 * cumulative stats for the UI dashboard.
 */
export class TokenomicsRuntime {
  private taskClass: TaskClass | null = null;
  private riskLevel: TaskRisk = TaskRisk.Medium;
  private salienceItems: SalienceItem[] = [];
  private salienceWeights: SalienceWeights = DEFAULT_SALIENCE_WEIGHTS;
  private totalBudget = 2000;
  private history: MeasurementLoopResult[] = [];
  private cumulativeWaste = 0;
  private cumulativeReuse = 0;
  private _budgetAdjustment = 1.0;

  get budgetAdjustment(): number {
    return this._budgetAdjustment;
  }

  get historyCount(): number {
    return this.history.length;
  }

  /** Step 1-2: Classify task and set risk. */
  classifyTask(taskClass: TaskClass, risk: TaskRisk): void {
    this.taskClass = taskClass;
    this.riskLevel = risk;
    this._budgetAdjustment = RISK_MULTIPLIERS[risk];
  }

  /** Step 4: Set total token budget (will be risk-adjusted). */
  setBudget(tokens: number): void {
    this.totalBudget = Math.floor(tokens * this._budgetAdjustment);
  }

  /** Step 3: Add items for salience ranking. */
  addSalienceItem(item: SalienceItem): void {
    this.salienceItems.push(item);
  }

  /** Step 3-4: Rank and allocate. */
  allocate(): SalienceResult[] {
    return allocateSalienceBudget(this.salienceItems, this.totalBudget, this.salienceWeights);
  }

  /**
   * Steps 7-11: Full audit after response generation.
   */
  audit(params: {
    promptTokens: number;
    outputTokens: number;
    cognitiveReturn: CognitiveReturnScore;
    compressionScores: [number, number, number];
    wastedTokens?: number;
    reusableRules?: number;
  }): MeasurementLoopResult {
    if (!this.taskClass) {
      throw new Error("Task not classified. Call classifyTask() first.");
    }

    const { promptTokens, outputTokens, cognitiveReturn, compressionScores } = params;
    const wastedTokens = params.wastedTokens ?? 0;
    const reusableRules = params.reusableRules ?? 0;

    // Step 7: Compression audit
    const compression = computeCompressionEfficiency(
      compressionScores[0],
      compressionScores[1],
      compressionScores[2],
      outputTokens,
    );

    // Step 8: CRPT
    const crpt = computeCRPT(cognitiveReturn, promptTokens, outputTokens);

    // Step 9: Waste detection
    this.cumulativeWaste += wastedTokens;

    // Step 10: Reuse extraction
    this.cumulativeReuse += reusableRules;

    // Step 11: Adaptive policy update (phi-dampened)
    if (crpt.crpt > 0) {
      const wasteRatio = wastedTokens / Math.max(1, outputTokens);
      this._budgetAdjustment *= 1.0 - wasteRatio * PHI_INV_3;
      if (reusableRules > 0) {
        this._budgetAdjustment *= 1.0 + reusableRules * PHI_INV_3 * 0.1;
      }
    }

    const salienceResults = this.allocate();

    const result: MeasurementLoopResult = {
      taskClass: this.taskClass,
      riskLevel: this.riskLevel,
      salienceResults,
      totalBudget: this.totalBudget,
      cognitiveReturn: crpt,
      compression,
      wastedTokens,
      reusableRulesExtracted: reusableRules,
      timestampMs: Date.now(),
    };

    this.history.push(result);
    return result;
  }

  /** Reset for new task (preserves history). */
  reset(): void {
    this.taskClass = null;
    this.riskLevel = TaskRisk.Medium;
    this.salienceItems = [];
  }

  /** Cumulative statistics for dashboard display. */
  getStats(): RuntimeStats {
    if (this.history.length === 0) {
      return {
        interactions: 0,
        avgCrpt: 0,
        avgCef: 0,
        cumulativeWaste: 0,
        cumulativeReuse: 0,
        budgetAdjustment: this._budgetAdjustment,
        totalTokensSpent: 0,
      };
    }

    const avgCrpt =
      this.history.reduce((sum, h) => sum + h.cognitiveReturn.crpt, 0) /
      this.history.length;
    const avgCef =
      this.history.reduce((sum, h) => sum + h.compression.cef, 0) / this.history.length;
    const totalTokensSpent = this.history.reduce(
      (sum, h) => sum + h.cognitiveReturn.totalTokens,
      0,
    );

    return {
      interactions: this.history.length,
      avgCrpt,
      avgCef,
      cumulativeWaste: this.cumulativeWaste,
      cumulativeReuse: this.cumulativeReuse,
      budgetAdjustment: this._budgetAdjustment,
      totalTokensSpent,
    };
  }
}
