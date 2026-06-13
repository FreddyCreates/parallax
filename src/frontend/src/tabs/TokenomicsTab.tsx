import { motion } from "motion/react";
import { useState } from "react";
import { useTokenomicsState } from "../hooks/useTokenomics";
import type {
  BenchmarkResult,
  EvaluationCriteria,
  HypothesisTracker,
  MeasurementLoopState,
  TokenomicsMeasurementState,
} from "../hooks/useTokenomics";

// ─── Constants ────────────────────────────────────────────────────────────────

const GOLD = "oklch(0.78 0.15 85)";
const GREEN = "oklch(0.65 0.18 145)";
const RED = "oklch(0.55 0.22 25)";
const BLUE = "oklch(0.65 0.15 240)";
const PURPLE = "oklch(0.65 0.20 290)";
const DIM = "oklch(0.40 0.02 240)";
const BORDER = "oklch(0.18 0.02 240)";
const CARD_BG = "rgba(12, 13, 18, 0.85)";

type SectionId =
  | "tvf"
  | "crpt"
  | "salience"
  | "compression"
  | "benchmark"
  | "loop"
  | "criteria"
  | "hypotheses";

const SECTIONS: { id: SectionId; label: string; num: string }[] = [
  { id: "tvf", label: "TOKEN VALUE FUNCTION", num: "15.1" },
  { id: "crpt", label: "COGNITIVE RETURN METRICS", num: "15.2" },
  { id: "salience", label: "SALIENCE ALLOCATION", num: "15.3" },
  { id: "compression", label: "COMPRESSION EFFICIENCY", num: "15.4" },
  { id: "benchmark", label: "BENCHMARK TASKS", num: "15.5" },
  { id: "loop", label: "RUNTIME LOOP", num: "15.6" },
  { id: "criteria", label: "EVALUATION CRITERIA", num: "15.7" },
  { id: "hypotheses", label: "RESEARCH HYPOTHESES", num: "15.8" },
];

// ─── Utility ──────────────────────────────────────────────────────────────────

function MetricCard({
  label,
  value,
  unit,
  color,
}: {
  label: string;
  value: string;
  unit?: string;
  color: string;
}) {
  return (
    <div
      className="p-3 border"
      style={{ borderColor: BORDER, background: CARD_BG }}
    >
      <div
        className="font-mono text-[7px] tracking-[0.3em] mb-1"
        style={{ color: DIM }}
      >
        {label}
      </div>
      <div className="flex items-baseline gap-1">
        <span
          className="font-mono text-lg tabular-nums"
          style={{ color, textShadow: `0 0 12px ${color}40` }}
        >
          {value}
        </span>
        {unit && (
          <span
            className="font-mono text-[8px] tracking-wider"
            style={{ color: DIM }}
          >
            {unit}
          </span>
        )}
      </div>
    </div>
  );
}

function ProgressBar({
  value,
  max,
  color,
}: {
  value: number;
  max: number;
  color: string;
}) {
  const pct = max > 0 ? Math.min((value / max) * 100, 100) : 0;
  return (
    <div
      className="h-1.5 w-full"
      style={{ background: `${color}15` }}
    >
      <div
        className="h-full transition-all duration-500"
        style={{
          width: `${pct}%`,
          background: color,
          boxShadow: `0 0 6px ${color}60`,
        }}
      />
    </div>
  );
}

function SectionHeader({ num, label }: { num: string; label: string }) {
  return (
    <div className="flex items-center gap-3 mb-4">
      <span
        className="font-mono text-[9px] px-2 py-0.5 border"
        style={{ borderColor: GOLD, color: GOLD }}
      >
        §{num}
      </span>
      <span
        className="font-mono text-[10px] tracking-[0.3em]"
        style={{ color: "oklch(0.85 0.02 240)" }}
      >
        {label}
      </span>
    </div>
  );
}

// ─── Section 15.1: Token Value Function ───────────────────────────────────────

function TokenValueSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const w = state.tokenValueWeights;
  const weights = [
    { label: "w_DECISION", value: w.wDecision, desc: "φ⁻¹" },
    { label: "w_ACTION", value: w.wAction, desc: "φ⁻²" },
    { label: "w_RISK", value: w.wRisk, desc: "φ⁻¹" },
    { label: "w_COMPRESSION", value: w.wCompression, desc: "φ⁻³" },
    { label: "w_MEMORY", value: w.wMemory, desc: "φ⁻²" },
    { label: "w_NOISE", value: w.wNoise, desc: "−φ⁻¹" },
  ];

  return (
    <div>
      <SectionHeader num="15.1" label="TOKEN VALUE FUNCTION" />

      {/* Equation display */}
      <div
        className="p-4 mb-4 border font-mono text-[11px]"
        style={{ borderColor: BORDER, background: "rgba(8,9,14,0.9)", color: GOLD }}
      >
        TV(t) = w<sub>d</sub>·D<sub>t</sub> + w<sub>a</sub>·A<sub>t</sub> + w
        <sub>r</sub>·R<sub>t</sub> + w<sub>c</sub>·C<sub>t</sub> + w<sub>m</sub>
        ·M<sub>t</sub> − w<sub>n</sub>·N<sub>t</sub>
      </div>

      {/* Weights table */}
      <div className="grid grid-cols-3 md:grid-cols-6 gap-2 mb-4">
        {weights.map((wt) => (
          <div
            key={wt.label}
            className="p-2 border text-center"
            style={{ borderColor: BORDER, background: CARD_BG }}
          >
            <div
              className="font-mono text-[7px] tracking-wider mb-1"
              style={{ color: DIM }}
            >
              {wt.label}
            </div>
            <div
              className="font-mono text-sm tabular-nums"
              style={{ color: wt.label === "w_NOISE" ? RED : GREEN }}
            >
              {wt.value.toFixed(4)}
            </div>
            <div
              className="font-mono text-[7px] mt-0.5"
              style={{ color: DIM }}
            >
              {wt.desc}
            </div>
          </div>
        ))}
      </div>

      {/* Average Token Value */}
      <MetricCard
        label="AVG TOKEN VALUE"
        value={state.averageTokenValue.toFixed(6)}
        unit="TV"
        color={state.averageTokenValue > 0 ? GREEN : RED}
      />

      {/* Doctrine */}
      <div
        className="mt-3 px-3 py-2 border-l-2 font-mono text-[9px]"
        style={{ borderColor: GOLD, color: DIM }}
      >
        DOCTRINE: Do not optimize for fewer tokens. Optimize for higher-value
        tokens.
      </div>
    </div>
  );
}

// ─── Section 15.2: CRPT Metrics ───────────────────────────────────────────────

function CRPTSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const crpt = state.lastCRPT;
  const bd = crpt.breakdown;
  const categories = [
    { label: "DECISION QUALITY", value: bd.decisionQuality, key: "dq" },
    { label: "ACTIONABILITY", value: bd.actionability, key: "act" },
    { label: "RISK CONTROL", value: bd.riskControl, key: "risk" },
    { label: "REUSE VALUE", value: bd.reuseValue, key: "reuse" },
    { label: "LEARNING GAIN", value: bd.learningGain, key: "learn" },
  ];

  return (
    <div>
      <SectionHeader num="15.2" label="COGNITIVE RETURN METRICS" />

      {/* Equation */}
      <div
        className="p-4 mb-4 border font-mono text-[11px]"
        style={{ borderColor: BORDER, background: "rgba(8,9,14,0.9)", color: GOLD }}
      >
        CRPT = (DQ + ACT + RISK + REUSE + LEARN) / TotalTokens
      </div>

      {/* Primary metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 mb-4">
        <MetricCard
          label="CRPT"
          value={crpt.crpt.toFixed(6)}
          color={GOLD}
        />
        <MetricCard
          label="COGNITIVE RETURN"
          value={crpt.cognitiveReturn.toFixed(2)}
          unit="/ 25"
          color={GREEN}
        />
        <MetricCard
          label="PROMPT TOKENS"
          value={Number(crpt.promptTokens).toLocaleString()}
          color={BLUE}
        />
        <MetricCard
          label="OUTPUT TOKENS"
          value={Number(crpt.outputTokens).toLocaleString()}
          color={BLUE}
        />
      </div>

      {/* Averages */}
      <div className="grid grid-cols-2 gap-2 mb-4">
        <MetricCard
          label="AVG CRPT (ALL TIME)"
          value={state.averageCRPT.toFixed(6)}
          color={GOLD}
        />
        <MetricCard
          label="TOTAL INTERACTIONS"
          value={Number(state.totalInteractions).toLocaleString()}
          color={GREEN}
        />
      </div>

      {/* Category breakdown */}
      <div className="space-y-2">
        {categories.map((cat) => (
          <div key={cat.key}>
            <div className="flex items-center justify-between mb-1">
              <span
                className="font-mono text-[8px] tracking-wider"
                style={{ color: DIM }}
              >
                {cat.label}
              </span>
              <span
                className="font-mono text-[10px] tabular-nums"
                style={{ color: GREEN }}
              >
                {cat.value.toFixed(2)} / 5.00
              </span>
            </div>
            <ProgressBar value={cat.value} max={5} color={GREEN} />
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Section 15.3: Salience Allocation ────────────────────────────────────────

function SalienceSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const sw = state.salienceWeights;
  const weights = [
    { label: "α URGENCY", value: sw.alpha, greek: "α" },
    { label: "β RISK", value: sw.beta, greek: "β" },
    { label: "γ MISSION", value: sw.gamma, greek: "γ" },
    { label: "δ TIME", value: sw.delta, greek: "δ" },
    { label: "ε NOVELTY", value: sw.epsilon, greek: "ε" },
    { label: "ζ KNOWN", value: sw.zeta, greek: "−ζ" },
  ];

  return (
    <div>
      <SectionHeader num="15.3" label="SALIENCE ALLOCATION EQUATIONS" />

      {/* Equations */}
      <div
        className="p-4 mb-2 border font-mono text-[11px] space-y-1"
        style={{ borderColor: BORDER, background: "rgba(8,9,14,0.9)", color: GOLD }}
      >
        <div>
          S<sub>i</sub> = α·U<sub>i</sub> + β·R<sub>i</sub> + γ·M<sub>i</sub>{" "}
          + δ·T<sub>i</sub> + ε·N<sub>i</sub> − ζ·K<sub>i</sub>
        </div>
        <div style={{ color: DIM }}>
          B<sub>i</sub> = B<sub>total</sub> × (S<sub>i</sub> / ΣS)
        </div>
      </div>

      {/* Weight grid */}
      <div className="grid grid-cols-3 md:grid-cols-6 gap-2 mt-4">
        {weights.map((w) => (
          <div
            key={w.label}
            className="p-2 border text-center"
            style={{ borderColor: BORDER, background: CARD_BG }}
          >
            <div
              className="font-mono text-lg mb-0.5"
              style={{ color: w.greek.startsWith("−") ? RED : PURPLE }}
            >
              {w.greek}
            </div>
            <div
              className="font-mono text-[7px] tracking-wider mb-1"
              style={{ color: DIM }}
            >
              {w.label}
            </div>
            <div
              className="font-mono text-sm tabular-nums"
              style={{ color: w.greek.startsWith("−") ? RED : GREEN }}
            >
              {w.value.toFixed(4)}
            </div>
          </div>
        ))}
      </div>

      {/* Doctrine */}
      <div
        className="mt-4 px-3 py-2 border-l-2 font-mono text-[9px]"
        style={{ borderColor: PURPLE, color: DIM }}
      >
        DOCTRINE: Spend tokens on what is urgent, risky, mission-relevant,
        time-sensitive, uncertain, and not already known.
      </div>
    </div>
  );
}

// ─── Section 15.4: Compression Efficiency ─────────────────────────────────────

function CompressionSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const cs = state.lastCompressionScore;
  const c = cs.components;

  return (
    <div>
      <SectionHeader num="15.4" label="COMPRESSION EFFICIENCY METRICS" />

      {/* Equation */}
      <div
        className="p-4 mb-4 border font-mono text-[11px]"
        style={{ borderColor: BORDER, background: "rgba(8,9,14,0.9)", color: GOLD }}
      >
        CEF = (InfoRetained + ActionClarity + RiskPreserved) / OutputTokens
      </div>

      {/* CEF metric */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 mb-4">
        <MetricCard
          label="CEF"
          value={cs.cef.toFixed(6)}
          color={GOLD}
        />
        <MetricCard
          label="AVG CEF"
          value={state.averageCEF.toFixed(6)}
          color={GREEN}
        />
        <MetricCard
          label="OUTPUT TOKENS"
          value={Number(cs.outputTokens).toLocaleString()}
          color={BLUE}
        />
        <MetricCard
          label="AUDIT STATUS"
          value={cs.passesAudit ? "PASSED" : "FAILED"}
          color={cs.passesAudit ? GREEN : RED}
        />
      </div>

      {/* Component bars */}
      {[
        { label: "INFORMATION RETAINED", value: c.informationRetained },
        { label: "ACTION CLARITY", value: c.actionClarity },
        { label: "RISK PRESERVED", value: c.riskPreserved },
      ].map((item) => (
        <div key={item.label} className="mb-2">
          <div className="flex items-center justify-between mb-1">
            <span
              className="font-mono text-[8px] tracking-wider"
              style={{ color: DIM }}
            >
              {item.label}
            </span>
            <span
              className="font-mono text-[10px] tabular-nums"
              style={{ color: item.value >= 3.0 ? GREEN : RED }}
            >
              {item.value.toFixed(2)} / 5.00
            </span>
          </div>
          <ProgressBar
            value={item.value}
            max={5}
            color={item.value >= 3.0 ? GREEN : RED}
          />
        </div>
      ))}

      <div
        className="mt-3 px-3 py-2 border-l-2 font-mono text-[9px]"
        style={{ borderColor: GREEN, color: DIM }}
      >
        AUDIT GATE: Each component must be ≥ 3.0 (φ⁻¹ × 5). A compressed output
        passes only if the user can still act correctly.
      </div>
    </div>
  );
}

// ─── Section 15.5: Benchmark Tasks ────────────────────────────────────────────

function taskClassLabel(tc: Record<string, null>): string {
  const key = Object.keys(tc)[0] ?? "unknown";
  const labels: Record<string, string> = {
    invoiceExecution: "INVOICE EXECUTION",
    estimating: "ESTIMATING",
    cashflowDecision: "CASHFLOW DECISION",
    proposalGeneration: "PROPOSAL GENERATION",
    researchSynthesis: "RESEARCH SYNTHESIS",
    architectureDesign: "ARCHITECTURE DESIGN",
    redTeamReview: "RED-TEAM REVIEW",
    memoryConsolidation: "MEMORY CONSOLIDATION",
  };
  return labels[key] ?? key.toUpperCase();
}

function BenchmarkSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const results = state.benchmarkResults;

  return (
    <div>
      <SectionHeader num="15.5" label="BENCHMARK TASKS" />

      {/* Equation */}
      <div
        className="p-4 mb-4 border font-mono text-[11px]"
        style={{ borderColor: BORDER, background: "rgba(8,9,14,0.9)", color: GOLD }}
      >
        TokenomicGain = (Score<sub>B</sub> / Tokens<sub>B</sub>) − (Score
        <sub>A</sub> / Tokens<sub>A</sub>)
      </div>

      {/* Task class badges */}
      <div className="flex flex-wrap gap-1.5 mb-4">
        {[
          "INVOICE",
          "ESTIMATING",
          "CASHFLOW",
          "PROPOSAL",
          "RESEARCH",
          "ARCHITECTURE",
          "RED-TEAM",
          "MEMORY",
        ].map((tc) => (
          <span
            key={tc}
            className="font-mono text-[7px] tracking-wider px-2 py-1 border"
            style={{ borderColor: BORDER, color: DIM }}
          >
            {tc}
          </span>
        ))}
      </div>

      {results.length === 0 ? (
        <div
          className="p-4 border text-center font-mono text-[9px]"
          style={{ borderColor: BORDER, color: DIM }}
        >
          NO BENCHMARKS RECORDED — Submit comparisons via
          recordTokenomicsBenchmark()
        </div>
      ) : (
        <div className="space-y-2">
          {results.map((r: BenchmarkResult, i: number) => (
            <div
              key={i}
              className="p-3 border"
              style={{ borderColor: BORDER, background: CARD_BG }}
            >
              <div className="flex items-center justify-between mb-2">
                <span
                  className="font-mono text-[9px] tracking-wider"
                  style={{ color: "oklch(0.85 0.02 240)" }}
                >
                  {taskClassLabel(r.taskClass)} — {r.taskLabel}
                </span>
                <span
                  className="font-mono text-[8px] px-2 py-0.5 border"
                  style={{
                    borderColor: r.superior ? GREEN : RED,
                    color: r.superior ? GREEN : RED,
                  }}
                >
                  {r.superior ? "TOKENOMIC ✓" : "BASELINE ✗"}
                </span>
              </div>
              <div className="grid grid-cols-5 gap-2 font-mono text-[8px]">
                <div>
                  <div style={{ color: DIM }}>SCORE A</div>
                  <div style={{ color: RED }}>{r.scoreA.toFixed(2)}</div>
                </div>
                <div>
                  <div style={{ color: DIM }}>SCORE B</div>
                  <div style={{ color: GREEN }}>{r.scoreB.toFixed(2)}</div>
                </div>
                <div>
                  <div style={{ color: DIM }}>EFF A</div>
                  <div style={{ color: RED }}>{r.efficiencyA.toFixed(6)}</div>
                </div>
                <div>
                  <div style={{ color: DIM }}>EFF B</div>
                  <div style={{ color: GREEN }}>{r.efficiencyB.toFixed(6)}</div>
                </div>
                <div>
                  <div style={{ color: DIM }}>GAIN</div>
                  <div
                    style={{ color: r.tokenomicGain > 0 ? GREEN : RED }}
                  >
                    {r.tokenomicGain > 0 ? "+" : ""}
                    {r.tokenomicGain.toFixed(6)}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── Section 15.6: Runtime Measurement Loop ───────────────────────────────────

const LOOP_STEPS = [
  { key: "classifyTask", label: "CLASSIFY TASK", num: 1 },
  { key: "estimateRisk", label: "ESTIMATE RISK", num: 2 },
  { key: "rankSalience", label: "RANK SALIENCE", num: 3 },
  { key: "allocateBudget", label: "ALLOCATE BUDGET", num: 4 },
  { key: "recruitModules", label: "RECRUIT MODULES", num: 5 },
  { key: "generateResponse", label: "GENERATE RESPONSE", num: 6 },
  { key: "auditCompression", label: "AUDIT COMPRESSION", num: 7 },
  { key: "scoreCognitiveReturn", label: "SCORE CRPT", num: 8 },
  { key: "detectWaste", label: "DETECT WASTE", num: 9 },
  { key: "extractReusable", label: "EXTRACT REUSABLE", num: 10 },
  { key: "updatePolicy", label: "UPDATE POLICY", num: 11 },
];

function RuntimeLoopSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const loop = state.measurementLoop;
  const currentKey = Object.keys(loop.currentStep)[0] ?? "";

  return (
    <div>
      <SectionHeader num="15.6" label="RUNTIME MEASUREMENT LOOP" />

      {/* Cycle counter */}
      <div className="grid grid-cols-2 md:grid-cols-3 gap-2 mb-4">
        <MetricCard
          label="CYCLES COMPLETED"
          value={Number(loop.cycleCount).toLocaleString()}
          color={GREEN}
        />
        <MetricCard
          label="LAST CYCLE BEAT"
          value={Number(loop.lastCycleBeat).toLocaleString()}
          color={BLUE}
        />
        <MetricCard
          label="CURRENT STEP"
          value={currentKey}
          color={GOLD}
        />
      </div>

      {/* 11-step visualization */}
      <div className="flex flex-wrap gap-1.5">
        {LOOP_STEPS.map((step) => {
          const active = step.key === currentKey;
          const done =
            LOOP_STEPS.findIndex((s) => s.key === currentKey) >
            LOOP_STEPS.findIndex((s) => s.key === step.key);
          return (
            <div
              key={step.key}
              className="flex items-center gap-1.5 px-2 py-1.5 border transition-all"
              style={{
                borderColor: active ? GOLD : done ? GREEN : BORDER,
                background: active
                  ? `${GOLD}15`
                  : done
                    ? `${GREEN}08`
                    : CARD_BG,
              }}
            >
              <span
                className="font-mono text-[8px] w-4 text-center"
                style={{
                  color: active ? GOLD : done ? GREEN : DIM,
                }}
              >
                {step.num}
              </span>
              <span
                className="font-mono text-[7px] tracking-wider"
                style={{
                  color: active
                    ? GOLD
                    : done
                      ? GREEN
                      : DIM,
                }}
              >
                {step.label}
              </span>
              {active && (
                <span
                  className="w-1 h-1 animate-pulse"
                  style={{ backgroundColor: GOLD }}
                />
              )}
            </div>
          );
        })}
      </div>

      {/* Loop outputs */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 mt-4">
        <MetricCard
          label="TASK TYPE"
          value={loop.taskClassification}
          color={BLUE}
        />
        <MetricCard
          label="RISK ESTIMATE"
          value={loop.riskEstimate.toFixed(3)}
          color={loop.riskEstimate > 0.618 ? RED : GREEN}
        />
        <MetricCard
          label="WASTE DETECTED"
          value={`${(loop.wasteDetected * 100).toFixed(1)}%`}
          color={loop.wasteDetected > 0.236 ? RED : GREEN}
        />
        <MetricCard
          label="REUSABLE EXTRACTED"
          value={Number(loop.reusableExtracted).toString()}
          color={GREEN}
        />
      </div>
    </div>
  );
}

// ─── Section 15.7: Evaluation Criteria ────────────────────────────────────────

function EvaluationSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const e: EvaluationCriteria = state.lastEvaluation;
  const criteria = [
    {
      label: "COGNITIVE RETURN PER TOKEN",
      value: e.cognitiveReturnPerToken,
      desc: "Useful cognition per token spent",
    },
    {
      label: "COMPRESSION FIDELITY",
      value: e.compressionFidelity,
      desc: "Compressed output preserves meaning",
    },
    {
      label: "ACTION CONVERSION RATE",
      value: e.actionConversionRate,
      desc: "Outputs lead to correct action",
    },
    {
      label: "RISK PRESERVATION",
      value: e.riskPreservation,
      desc: "Concise without hiding uncertainty",
    },
    {
      label: "REUSE EXTRACTION RATE",
      value: e.reuseExtractionRate,
      desc: "Interactions → reusable rules/memory",
    },
    {
      label: "CONTEXT HYGIENE",
      value: e.contextHygiene,
      desc: "Avoids polluting context",
    },
    {
      label: "ADAPTIVE DEPTH",
      value: e.adaptiveDepthAccuracy,
      desc: "Expand/compress based on stakes",
    },
    {
      label: "ERROR AVOIDANCE",
      value: e.errorAvoidance,
      desc: "Prevents math/scope/logic mistakes",
    },
  ];

  return (
    <div>
      <SectionHeader num="15.7" label="EVALUATION CRITERIA" />

      <MetricCard
        label="AGGREGATE EVAL SCORE (φ-WEIGHTED)"
        value={state.averageEvalScore.toFixed(4)}
        unit="/ 5.00"
        color={GOLD}
      />

      <div className="space-y-3 mt-4">
        {criteria.map((c) => (
          <div key={c.label}>
            <div className="flex items-center justify-between mb-1">
              <div>
                <span
                  className="font-mono text-[8px] tracking-wider"
                  style={{ color: "oklch(0.70 0.02 240)" }}
                >
                  {c.label}
                </span>
                <span
                  className="font-mono text-[7px] ml-2"
                  style={{ color: DIM }}
                >
                  {c.desc}
                </span>
              </div>
              <span
                className="font-mono text-[10px] tabular-nums"
                style={{ color: c.value >= 3.0 ? GREEN : c.value > 0 ? GOLD : DIM }}
              >
                {c.value.toFixed(2)}
              </span>
            </div>
            <ProgressBar
              value={c.value}
              max={5}
              color={c.value >= 3.0 ? GREEN : GOLD}
            />
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Section 15.8: Research Hypotheses ────────────────────────────────────────

function HypothesisSection({
  state,
}: {
  state: TokenomicsMeasurementState;
}) {
  const h: HypothesisTracker = state.hypotheses;
  const h1WinRate =
    Number(h.h1_comparisons) > 0
      ? Number(h.h1_tokenomicWins) / Number(h.h1_comparisons)
      : 0;

  return (
    <div>
      <SectionHeader num="15.8" label="RESEARCH HYPOTHESES" />

      {/* H1 */}
      <div
        className="p-4 border mb-4"
        style={{ borderColor: h.h1_supported ? GREEN : BORDER, background: CARD_BG }}
      >
        <div className="flex items-center justify-between mb-3">
          <span
            className="font-mono text-[10px] tracking-wider"
            style={{ color: "oklch(0.85 0.02 240)" }}
          >
            H1 — CRPT SUPERIORITY
          </span>
          <span
            className="font-mono text-[8px] px-2 py-0.5 border"
            style={{
              borderColor: h.h1_supported ? GREEN : RED,
              color: h.h1_supported ? GREEN : RED,
            }}
          >
            {h.h1_supported ? "SUPPORTED" : "NOT YET SUPPORTED"}
          </span>
        </div>
        <div
          className="font-mono text-[9px] mb-3"
          style={{ color: DIM }}
        >
          &quot;Tokenomic systems produce higher CRPT than non-tokenomic systems,
          especially in operational, financial, research, and multi-step
          reasoning tasks.&quot;
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          <MetricCard
            label="COMPARISONS"
            value={Number(h.h1_comparisons).toString()}
            color={BLUE}
          />
          <MetricCard
            label="TOKENOMIC WINS"
            value={Number(h.h1_tokenomicWins).toString()}
            color={GREEN}
          />
          <MetricCard
            label="WIN RATE"
            value={`${(h1WinRate * 100).toFixed(1)}%`}
            color={h1WinRate >= 0.618 ? GREEN : RED}
          />
          <MetricCard
            label="GATE (φ⁻¹)"
            value="61.8%"
            color={DIM}
          />
        </div>
      </div>

      {/* H2 */}
      <div
        className="p-4 border"
        style={{ borderColor: h.h2_supported ? GREEN : BORDER, background: CARD_BG }}
      >
        <div className="flex items-center justify-between mb-3">
          <span
            className="font-mono text-[10px] tracking-wider"
            style={{ color: "oklch(0.85 0.02 240)" }}
          >
            H2 — IMPROVEMENT OVER TIME
          </span>
          <span
            className="font-mono text-[8px] px-2 py-0.5 border"
            style={{
              borderColor: h.h2_supported ? GREEN : RED,
              color: h.h2_supported ? GREEN : RED,
            }}
          >
            {h.h2_supported ? "SUPPORTED" : "NOT YET SUPPORTED"}
          </span>
        </div>
        <div
          className="font-mono text-[9px] mb-3"
          style={{ color: DIM }}
        >
          &quot;Tokenomic systems improve over time because reuse extraction and
          memory consolidation reduce future token cost while increasing task
          accuracy.&quot;
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          <MetricCard
            label="EARLY CRPT (F(8)=21)"
            value={h.h2_earlyPhaseCRPT.toFixed(6)}
            color={BLUE}
          />
          <MetricCard
            label="LATE CRPT"
            value={h.h2_latePhaseCRPT.toFixed(6)}
            color={h.h2_latePhaseCRPT > h.h2_earlyPhaseCRPT ? GREEN : RED}
          />
          <MetricCard
            label="REUSE RULES"
            value={Number(h.h2_reuseRulesExtracted).toString()}
            color={GREEN}
          />
          <MetricCard
            label="LATE OBSERVATIONS"
            value={Number(h.h2_lateCount).toString()}
            color={BLUE}
          />
        </div>
      </div>
    </div>
  );
}

// ─── Main Tab ─────────────────────────────────────────────────────────────────

export function TokenomicsTab() {
  const { data: state, isLoading } = useTokenomicsState();
  const [activeSection, setActiveSection] = useState<SectionId>("tvf");

  if (isLoading || !state) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex items-center gap-3">
          <div
            className="w-2 h-2 animate-pulse"
            style={{ backgroundColor: GOLD }}
          />
          <span
            className="font-mono text-[9px] tracking-[0.3em]"
            style={{ color: DIM }}
          >
            LOADING TOKENOMICS ENGINE...
          </span>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1
            className="font-display text-xl tracking-wider"
            style={{ color: "oklch(0.95 0.02 240)" }}
          >
            TOKENOMICS
          </h1>
          <div
            className="font-mono text-[8px] tracking-[0.3em] mt-0.5"
            style={{ color: DIM }}
          >
            MEASUREMENT &amp; BENCHMARKING FRAMEWORK · DOMAIN 39
          </div>
        </div>
        <div className="flex items-center gap-3">
          <MetricCard
            label="TOTAL TOKENS"
            value={Number(state.totalTokensProcessed).toLocaleString()}
            color={BLUE}
          />
          <MetricCard
            label="HEARTBEAT"
            value={Number(state.lastTickBeat).toLocaleString()}
            color={GOLD}
          />
        </div>
      </div>

      {/* Top-level metrics bar */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
        <MetricCard label="AVG CRPT" value={state.averageCRPT.toFixed(6)} color={GOLD} />
        <MetricCard label="AVG TOKEN VALUE" value={state.averageTokenValue.toFixed(4)} color={GREEN} />
        <MetricCard label="AVG CEF" value={state.averageCEF.toFixed(6)} color={BLUE} />
        <MetricCard label="AVG EVAL" value={state.averageEvalScore.toFixed(4)} unit="/ 5" color={PURPLE} />
      </div>

      {/* Section navigation */}
      <div className="flex flex-wrap gap-1.5">
        {SECTIONS.map((s) => (
          <button
            key={s.id}
            type="button"
            onClick={() => setActiveSection(s.id)}
            className="font-mono text-[8px] tracking-wider px-3 py-1.5 border transition-all"
            style={{
              borderColor: activeSection === s.id ? GOLD : BORDER,
              background:
                activeSection === s.id ? `${GOLD}12` : "transparent",
              color:
                activeSection === s.id
                  ? GOLD
                  : "oklch(0.50 0.02 240)",
            }}
          >
            §{s.num} {s.label}
          </button>
        ))}
      </div>

      {/* Active section content */}
      <motion.div
        key={activeSection}
        initial={{ opacity: 0, y: 6 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.15 }}
        className="p-5 border"
        style={{ borderColor: BORDER, background: CARD_BG }}
      >
        {activeSection === "tvf" && <TokenValueSection state={state} />}
        {activeSection === "crpt" && <CRPTSection state={state} />}
        {activeSection === "salience" && <SalienceSection state={state} />}
        {activeSection === "compression" && (
          <CompressionSection state={state} />
        )}
        {activeSection === "benchmark" && (
          <BenchmarkSection state={state} />
        )}
        {activeSection === "loop" && <RuntimeLoopSection state={state} />}
        {activeSection === "criteria" && (
          <EvaluationSection state={state} />
        )}
        {activeSection === "hypotheses" && (
          <HypothesisSection state={state} />
        )}
      </motion.div>
    </motion.div>
  );
}
