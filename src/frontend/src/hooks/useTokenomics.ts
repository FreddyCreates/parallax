// @ts-nocheck
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useActor } from "./useActor";

// ── Tokenomics Measurement Types ─────────────────────────────────────────────
// Mirrors backend tokenomics_measurement.mo types

export interface CognitiveReturn {
  decisionQuality: number;
  actionability: number;
  riskControl: number;
  reuseValue: number;
  learningGain: number;
}

export interface CRPTScore {
  cognitiveReturn: number;
  totalTokens: bigint;
  promptTokens: bigint;
  outputTokens: bigint;
  crpt: number;
  breakdown: CognitiveReturn;
}

export interface CompressionScore {
  components: {
    informationRetained: number;
    actionClarity: number;
    riskPreserved: number;
  };
  outputTokens: bigint;
  cef: number;
  passesAudit: boolean;
}

export interface EvaluationCriteria {
  cognitiveReturnPerToken: number;
  compressionFidelity: number;
  actionConversionRate: number;
  riskPreservation: number;
  reuseExtractionRate: number;
  contextHygiene: number;
  adaptiveDepthAccuracy: number;
  errorAvoidance: number;
}

export interface MeasurementLoopState {
  currentStep: Record<string, null>;
  cycleCount: bigint;
  lastCycleBeat: bigint;
  taskClassification: string;
  riskEstimate: number;
  complexityEstimate: number;
  salienceRanking: string[];
  allocatedBudget: bigint;
  modulesRecruited: bigint;
  compressionAudit: boolean;
  cognitiveReturnScore: number;
  wasteDetected: number;
  reusableExtracted: bigint;
  policyUpdated: boolean;
}

export interface HypothesisTracker {
  h1_tokenomicCRPTSum: number;
  h1_baselineCRPTSum: number;
  h1_comparisons: bigint;
  h1_tokenomicWins: bigint;
  h1_supported: boolean;
  h2_earlyPhaseCRPT: number;
  h2_latePhaseCRPT: number;
  h2_earlyCount: bigint;
  h2_lateCount: bigint;
  h2_reuseRulesExtracted: bigint;
  h2_supported: boolean;
}

export interface BenchmarkResult {
  taskClass: Record<string, null>;
  taskLabel: string;
  scoreA: number;
  tokensA: bigint;
  efficiencyA: number;
  scoreB: number;
  tokensB: bigint;
  efficiencyB: number;
  tokenomicGain: number;
  superior: boolean;
}

export interface TokenomicsMeasurementState {
  tokenValueWeights: {
    wDecision: number;
    wAction: number;
    wRisk: number;
    wCompression: number;
    wMemory: number;
    wNoise: number;
  };
  salienceWeights: {
    alpha: number;
    beta: number;
    gamma: number;
    delta: number;
    epsilon: number;
    zeta: number;
  };
  totalInteractions: bigint;
  totalTokensProcessed: bigint;
  averageCRPT: number;
  averageTokenValue: number;
  averageCEF: number;
  averageEvalScore: number;
  lastCRPT: CRPTScore;
  lastCompressionScore: CompressionScore;
  lastEvaluation: EvaluationCriteria;
  benchmarkResults: BenchmarkResult[];
  measurementLoop: MeasurementLoopState;
  hypotheses: HypothesisTracker;
  lastTickBeat: bigint;
}

// ── Hooks ────────────────────────────────────────────────────────────────────

export function useTokenomicsState() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["tokenomicsState"],
    queryFn: async () => {
      if (!actor) return null;
      return (actor as any).getTokenomicsState() as Promise<TokenomicsMeasurementState>;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });
}

export function useComputeTokenValue() {
  const { actor } = useActor();
  return useMutation({
    mutationFn: async (params: {
      decisionValue: number;
      actionUsefulness: number;
      riskReduction: number;
      compressionGain: number;
      memoryReuse: number;
      noiseWaste: number;
    }) => {
      if (!actor) throw new Error("No actor");
      return (actor as any).computeTokenValue(
        params.decisionValue,
        params.actionUsefulness,
        params.riskReduction,
        params.compressionGain,
        params.memoryReuse,
        params.noiseWaste,
      ) as Promise<number>;
    },
  });
}

export function useScoreInteraction() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (params: {
      dq: number;
      act: number;
      risk: number;
      reuse: number;
      learn: number;
      promptTokens: bigint;
      outputTokens: bigint;
      infoRetained: number;
      actionClarity: number;
      riskPreserved: number;
      crptEval: number;
      compFidelity: number;
      actionConv: number;
      riskPres: number;
      reuseRate: number;
      ctxHygiene: number;
      adaptDepth: number;
      errAvoid: number;
      tvDecision: number;
      tvAction: number;
      tvRisk: number;
      tvCompression: number;
      tvMemory: number;
      tvNoise: number;
    }) => {
      if (!actor) throw new Error("No actor");
      return (actor as any).scoreTokenomicsInteraction(
        params.dq, params.act, params.risk, params.reuse, params.learn,
        params.promptTokens, params.outputTokens,
        params.infoRetained, params.actionClarity, params.riskPreserved,
        params.crptEval, params.compFidelity, params.actionConv,
        params.riskPres, params.reuseRate, params.ctxHygiene,
        params.adaptDepth, params.errAvoid,
        params.tvDecision, params.tvAction, params.tvRisk,
        params.tvCompression, params.tvMemory, params.tvNoise,
      );
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["tokenomicsState"] });
    },
  });
}

export function useRecordBenchmark() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (params: {
      taskClass: Record<string, null>;
      taskLabel: string;
      dqA: number; actA: number; riskA: number; reuseA: number; accA: number; wasteA: number;
      tokensA: bigint;
      dqB: number; actB: number; riskB: number; reuseB: number; accB: number; wasteB: number;
      tokensB: bigint;
    }) => {
      if (!actor) throw new Error("No actor");
      return (actor as any).recordTokenomicsBenchmark(
        params.taskClass, params.taskLabel,
        params.dqA, params.actA, params.riskA, params.reuseA, params.accA, params.wasteA,
        params.tokensA,
        params.dqB, params.actB, params.riskB, params.reuseB, params.accB, params.wasteB,
        params.tokensB,
      );
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["tokenomicsState"] });
    },
  });
}
