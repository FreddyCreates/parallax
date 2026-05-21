import { motion } from "motion/react";

interface QuantumState {
  parallax: number;
  entangla: number;
  bypass: number;
  resonex: number;
  chrono: number;
  veritas: number;
  novelty: number;
}
interface Shell3State {
  coherence: number;
  superradiance: number;
  kalmanConf: number;
  nodeCount: number;
}
interface AxisState {
  eagleElevation: number;
  eagleAccel: number;
  eagleCurvature: number;
  elephantRecall: number;
  elephantDist: number;
}
interface BrainSignals {
  btcSignal: number;
  ethSignal: number;
  icpSignal: number;
  mtcVelocitySignal: number;
  systemCoherenceScore: number;
  engineIntelligenceScore: number;
}

interface QuantumTabProps {
  quantumState: QuantumState | null;
  shell3State: Shell3State | null;
  axisState: AxisState | null;
  brainSignals: BrainSignals | null;
  loading: boolean;
}

const OPERATORS: { key: keyof QuantumState; label: string; desc: string }[] = [
  { key: "parallax", label: "PARALLAX ANGLE", desc: "ARCCOS CROSS-SHELL" },
  { key: "entangla", label: "ENTANGLA INDEX", desc: "MUTUAL INFORMATION" },
  { key: "bypass", label: "BYPASS GATE", desc: "3-PATH SUPERPOSITION" },
  { key: "resonex", label: "RESONEX FIELD", desc: "FREQ² WEIGHTED" },
  { key: "chrono", label: "CHRONO DILATION", desc: "TEMPORAL OPERATOR" },
  { key: "veritas", label: "VERITAS COHERENCE", desc: "TIER-WEIGHTED LAW" },
  { key: "novelty", label: "NOVELTY INDEX", desc: "Z-SCORE CROW" },
];

function QuantumBar({ value, max = 5 }: { value: number; max?: number }) {
  const pct = Math.min(Math.max(value / max, 0), 1) * 100;
  return (
    <div className="w-full h-1 bg-white/5 mt-1">
      <div
        className="h-full transition-all duration-500"
        style={{
          width: `${pct}%`,
          background: `oklch(${0.4 + pct / 200} 0.28 290)`,
          boxShadow: "0 0 6px oklch(0.65 0.28 290 / 0.4)",
        }}
      />
    </div>
  );
}

export function QuantumTab({
  quantumState,
  shell3State,
  axisState,
  brainSignals,
  loading,
}: QuantumTabProps) {
  return (
    <div className="space-y-6" data-ocid="quantum.panel">
      <div className="panel-glass p-5">
        <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-5">
          QUANTUM OPERATOR INDICES
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {OPERATORS.map((op, i) => {
            const val = quantumState?.[op.key] ?? 0;
            return (
              <motion.div
                key={op.key}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: i * 0.06 }}
                className="p-3 border border-white/5"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <div
                      className="font-mono text-[9px] tracking-[0.2em] mb-0.5"
                      style={{ color: "oklch(0.65 0.28 290)" }}
                    >
                      {op.label}
                    </div>
                    <div className="font-mono text-[7px] text-muted-foreground tracking-widest">
                      {op.desc}
                    </div>
                  </div>
                  <div
                    className="font-mono text-sm"
                    style={{ color: "oklch(0.72 0.15 200)" }}
                  >
                    {loading ? "—" : val.toFixed(4)}
                  </div>
                </div>
                <QuantumBar value={val} />
              </motion.div>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div className="panel-glass p-5">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
            QUANTUM BATTERY
          </div>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="font-mono text-[9px] text-muted-foreground">
                CHARGE LEVEL
              </span>
              <span
                className="font-mono text-xs"
                style={{ color: "oklch(0.65 0.28 290)" }}
              >
                {loading ? "—" : (shell3State?.superradiance ?? 0).toFixed(4)}
              </span>
            </div>
            <div className="w-full h-2 bg-white/5">
              <div
                className="h-full transition-all duration-700 animate-pulse-glow"
                style={{
                  width: `${Math.min(((shell3State?.superradiance ?? 0) / 5) * 100, 100)}%`,
                  background: "oklch(0.65 0.28 290)",
                  boxShadow: "0 0 12px oklch(0.65 0.28 290 / 0.5)",
                }}
              />
            </div>
            <div className="flex justify-between">
              <span className="font-mono text-[9px] text-muted-foreground">
                SUPERRADIANCE
              </span>
              <span
                className="font-mono text-xs"
                style={{ color: "oklch(0.72 0.15 200)" }}
              >
                {loading ? "—" : (shell3State?.superradiance ?? 0).toFixed(6)}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="font-mono text-[9px] text-muted-foreground">
                FREE ENERGY F
              </span>
              <span
                className="font-mono text-xs"
                style={{ color: "oklch(0.72 0.15 200)" }}
              >
                {brainSignals?.systemCoherenceScore?.toFixed(4) ?? "—"}
              </span>
            </div>
          </div>
        </div>

        <div className="panel-glass p-5">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
            AXIS ENGINE — EAGLE / ELEPHANT
          </div>
          <div className="space-y-3">
            {[
              {
                label: "EAGLE ELEVATION",
                value: axisState?.eagleElevation?.toFixed(6),
              },
              {
                label: "EAGLE ACCEL",
                value: axisState?.eagleAccel?.toFixed(6),
              },
              {
                label: "EAGLE CURVATURE",
                value: axisState?.eagleCurvature?.toFixed(6),
              },
              {
                label: "ELEPHANT RECALL",
                value: axisState?.elephantRecall?.toFixed(6),
              },
              {
                label: "ELEPHANT DIST",
                value: axisState?.elephantDist?.toFixed(6),
              },
            ].map((m) => (
              <div
                key={m.label}
                className="flex justify-between border-b border-white/5 pb-1.5"
              >
                <span className="font-mono text-[9px] text-muted-foreground">
                  {m.label}
                </span>
                <span
                  className="font-mono text-xs"
                  style={{ color: "oklch(0.72 0.15 200)" }}
                >
                  {loading ? "—" : (m.value ?? "—")}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
