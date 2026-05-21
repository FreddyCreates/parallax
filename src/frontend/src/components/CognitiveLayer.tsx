import { motion } from "motion/react";
import type { CognitiveState, SubOrganisms } from "../hooks/useParallax";

interface Props {
  cognitive: CognitiveState;
  subOrganisms?: SubOrganisms;
}

const NODE_LABELS: string[] = [
  "BTC",
  "ETH",
  "ICP",
  "MTC",
  "ORG-1",
  "ORG-2",
  "ORG-3",
  "ORG-4",
  "NNS",
  "S-ETH",
  "ARB",
  "PROFIT",
];

function MetricCard({
  label,
  value,
  sub,
  color,
}: { label: string; value: string; sub?: string; color?: string }) {
  return (
    <div className="border border-zinc-800 bg-black/60 px-3 py-2 flex flex-col gap-0.5">
      <span className="text-[9px] tracking-widest text-zinc-500 font-mono uppercase">
        {label}
      </span>
      <span
        className="font-mono text-sm font-bold leading-tight"
        style={{ color: color ?? "#e7e9ee" }}
      >
        {value}
      </span>
      {sub && <span className="text-[9px] font-mono text-zinc-600">{sub}</span>}
    </div>
  );
}

function coherenceColor(c: number): string {
  if (c > 0.8) return "#10b981";
  if (c > 0.5) return "#f59e0b";
  if (c > 0.3) return "#fb923c";
  return "#ef4444";
}

function jasmineDriftColor(d: number): string {
  if (d > 0.15) return "#ef4444";
  if (d < -0.05) return "#10b981";
  return "#e7e9ee";
}

function jasmineDriftStatus(d: number): { label: string; color: string } {
  if (d > 0.15)
    return {
      label: "SYSTEM DESTABILIZING — CORRECTION APPLIED",
      color: "#ef4444",
    };
  if (d < -0.05)
    return { label: "SYSTEM CONVERGING — COHERENCE REWARD", color: "#10b981" };
  return { label: "STABLE OPERATING RANGE", color: "#e7e9ee" };
}

function activationColor(v: number): string {
  if (v > 0.7) return "#10b981";
  if (v > 0.4) return "#f59e0b";
  return "#3f3f46";
}

function heatmapColor(v: number): string {
  if (v <= 0) return "#0a0e1a";
  if (v < 0.25) {
    const t = v / 0.25;
    const r = Math.round(10 + t * (0 - 10));
    const g = Math.round(14 + t * (60 - 14));
    const b = Math.round(26 + t * (120 - 26));
    return `rgb(${r},${g},${b})`;
  }
  if (v < 0.5) {
    const t = (v - 0.25) / 0.25;
    const r = Math.round(0 + t * 6);
    const g = Math.round(60 + t * (182 - 60));
    const b = Math.round(120 + t * (212 - 120));
    return `rgb(${r},${g},${b})`;
  }
  if (v < 0.75) {
    const t = (v - 0.5) / 0.25;
    const r = Math.round(6 + t * (200 - 6));
    const g = Math.round(182 + t * (230 - 182));
    const b = Math.round(212 + t * (240 - 212));
    return `rgb(${r},${g},${b})`;
  }
  const t = (v - 0.75) / 0.25;
  const c = Math.round(200 + t * 55);
  return `rgb(${c},${c},${c})`;
}

interface SubOrgCardProps {
  name: string;
  badge: string;
  active: boolean;
  urgency: number;
  accentColor: string;
  stats: { label: string; value: string | number }[];
}

function SubOrgCard({
  name,
  badge,
  active,
  urgency,
  accentColor,
  stats,
}: SubOrgCardProps) {
  return (
    <div
      className="border bg-black/60 p-3 flex flex-col gap-2"
      style={{ borderColor: active ? accentColor : "#27272a" }}
      data-ocid={`cognitive.${name.toLowerCase()}.panel`}
    >
      <div className="flex items-center justify-between gap-2">
        <span
          className="font-mono text-[10px] tracking-[0.25em] font-bold"
          style={{ color: active ? accentColor : "#71717a" }}
        >
          {name}
        </span>
        {active && (
          <motion.span
            animate={{ opacity: [1, 0.4, 1] }}
            transition={{ duration: 1.2, repeat: Number.POSITIVE_INFINITY }}
            className="font-mono text-[8px] tracking-widest px-1.5 py-0.5 border"
            style={{ borderColor: `${accentColor}60`, color: accentColor }}
          >
            ◉ {badge}
          </motion.span>
        )}
        {!active && (
          <span className="font-mono text-[8px] tracking-widest text-zinc-600">
            STANDBY
          </span>
        )}
      </div>

      {/* Urgency bar */}
      <div className="space-y-0.5">
        <div className="flex justify-between">
          <span className="font-mono text-[8px] text-zinc-600">URGENCY</span>
          <span
            className="font-mono text-[8px]"
            style={{ color: urgency > 0.6 ? accentColor : "#71717a" }}
          >
            {(urgency * 100).toFixed(0)}%
          </span>
        </div>
        <div className="h-1 bg-zinc-900 border border-zinc-800 overflow-hidden">
          <motion.div
            className="h-full"
            animate={{ width: `${urgency * 100}%` }}
            transition={{ type: "spring", stiffness: 80, damping: 20 }}
            style={{ backgroundColor: urgency > 0.6 ? accentColor : "#52525b" }}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-1">
        {stats.map((s) => (
          <div key={s.label} className="flex flex-col">
            <span className="font-mono text-[7px] text-zinc-600 tracking-wider">
              {s.label}
            </span>
            <span
              className="font-mono text-[10px]"
              style={{ color: active ? accentColor : "#71717a" }}
            >
              {s.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

export function CognitiveLayer({ cognitive, subOrganisms }: Props) {
  const {
    spectralRadius,
    hebbianKappa,
    frobeniusNorm,
    jasmineDrift,
    lyapunovV,
    lyapunovVPrev,
    shannonH,
    integratedInfoPhi,
    kuramotoR,
    coherenceC,
    freeEnergy,
    omnisPrecondition,
    omnisFiredCount,
    cognitiveBeats,
    etaLearningRate,
    hzActivations,
    hebbianW,
  } = cognitive;

  const driftStatus = jasmineDriftStatus(jasmineDrift);
  const driftPct = Math.min(Math.max((jasmineDrift + 0.2) / 0.4, 0), 1) * 100;

  const activations =
    hzActivations.length === 12 ? hzActivations : Array(12).fill(0);
  const weights = hebbianW.length === 144 ? hebbianW : Array(144).fill(0);

  const displayEta =
    jasmineDrift > 0.15 ? etaLearningRate * 0.5 : etaLearningRate;

  const subs = subOrganisms;

  return (
    <div className="space-y-4">
      {/* HEADER ROW */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-mono text-xs tracking-[0.3em] text-zinc-400 uppercase">
            MEDINA COGNITIVE SOVEREIGNTY LAYER
          </h2>
          <p className="font-mono text-[9px] text-zinc-600 tracking-widest mt-0.5">
            HEBBIAN MANIFOLD · JASMINE'S LAW · FREE ENERGY MINIMIZATION
          </p>
        </div>
        <div className="font-mono text-[9px] text-zinc-600 tracking-widest text-right">
          <div>ALFREDO MEDINA HERNANDEZ</div>
          <div>MEDINA DOCTRINE · 2026</div>
        </div>
      </div>

      {/* A — MANIFOLD STATE */}
      <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
        <div className="flex items-center gap-3 flex-wrap">
          <span className="font-mono text-[9px] tracking-widest text-zinc-500">
            MANIFOLD STATE
          </span>
          {omnisPrecondition && (
            <motion.span
              animate={{ opacity: [1, 0.4, 1] }}
              transition={{ duration: 1.4, repeat: Number.POSITIVE_INFINITY }}
              className="font-mono text-[9px] tracking-widest px-2 py-0.5 border border-emerald-500/60 text-emerald-400"
            >
              ◉ OMNIS PRECONDITION SATISFIED
            </motion.span>
          )}
          <div
            className="flex items-center gap-2 border border-zinc-700/60 px-3 py-1 ml-auto"
            data-ocid="cognitive.panel"
          >
            <span className="font-mono text-[9px] tracking-widest text-zinc-500">
              OMNIS ACHIEVED
            </span>
            <span
              className="font-mono text-sm font-bold"
              style={{ color: omnisFiredCount > 0 ? "#10b981" : "#3f3f46" }}
            >
              {omnisFiredCount.toLocaleString()}
            </span>
            <span className="font-mono text-[8px] text-zinc-600">× FIRED</span>
          </div>
        </div>

        <div className="flex items-baseline gap-3">
          <span className="font-mono text-[10px] text-zinc-500">C(t) =</span>
          <span
            className="font-mono text-4xl font-bold tracking-tight"
            style={{ color: coherenceColor(coherenceC) }}
          >
            {coherenceC.toFixed(4)}
          </span>
          <span className="font-mono text-[9px] text-zinc-600">
            {coherenceC > 0.8
              ? "HIGH INTEGRATION"
              : coherenceC > 0.5
                ? "NORMAL OPERATING"
                : coherenceC > 0.3
                  ? "FRAGMENTED"
                  : "CONFUSED STATE"}
          </span>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <MetricCard
            label="Spectral Radius ρ(W)"
            value={spectralRadius.toFixed(4)}
            sub={spectralRadius > 1.5 ? "⚠ NORMALIZING" : "STABLE"}
            color={spectralRadius > 1.5 ? "#ef4444" : "#06b6d4"}
          />
          <MetricCard
            label="Kappa κ"
            value={hebbianKappa.toFixed(5)}
            sub={
              hebbianKappa > 0.1
                ? "LEARNING SPIKE"
                : hebbianKappa < 0.001
                  ? "CONSOLIDATING"
                  : "ACTIVE LEARNING"
            }
            color={hebbianKappa > 0.1 ? "#f59e0b" : "#06b6d4"}
          />
          <MetricCard
            label="Frobenius ‖W‖_F"
            value={frobeniusNorm.toFixed(4)}
            color="#a78bfa"
          />
          <MetricCard
            label="Kuramoto r"
            value={kuramotoR.toFixed(4)}
            sub={kuramotoR > 0.85 ? "HIGH SYNC" : "PARTIAL SYNC"}
            color={kuramotoR > 0.85 ? "#10b981" : "#06b6d4"}
          />
        </div>
      </section>

      {/* B — JASMINE'S LAW */}
      <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
        <div>
          <div className="font-mono text-[9px] tracking-widest text-zinc-400">
            JASMINE'S LAW — LYAPUNOV STABILITY TEST
          </div>
          <div className="font-mono text-[8px] text-zinc-600">
            Alfredo Medina Hernandez | Medina, 2026
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <MetricCard
            label="V(t) current"
            value={lyapunovV.toFixed(6)}
            color="#06b6d4"
          />
          <MetricCard
            label="V(t-1) previous"
            value={lyapunovVPrev.toFixed(6)}
            color="#a78bfa"
          />
        </div>

        <div className="space-y-2">
          <div className="flex items-center gap-3">
            <span className="font-mono text-[9px] text-zinc-500">
              jasmineDrift
            </span>
            <span
              className="font-mono text-lg font-bold"
              style={{ color: jasmineDriftColor(jasmineDrift) }}
            >
              {jasmineDrift >= 0 ? "+" : ""}
              {jasmineDrift.toFixed(5)}
            </span>
          </div>
          <div className="relative h-4 bg-zinc-900 border border-zinc-800 overflow-hidden">
            <div
              className="absolute top-0 bottom-0 w-px bg-zinc-600"
              style={{ left: "50%" }}
            />
            <div
              className="absolute top-0 bottom-0 w-px bg-emerald-900/60"
              style={{ left: "37.5%" }}
            />
            <div
              className="absolute top-0 bottom-0 w-px bg-red-900/60"
              style={{ left: "87.5%" }}
            />
            <motion.div
              className="absolute top-1 bottom-1 w-1.5"
              animate={{ left: `${driftPct}%` }}
              transition={{ type: "spring", stiffness: 120, damping: 20 }}
              style={{
                backgroundColor: jasmineDriftColor(jasmineDrift),
                transform: "translateX(-50%)",
                boxShadow: `0 0 6px ${jasmineDriftColor(jasmineDrift)}`,
              }}
            />
          </div>
          <div className="flex justify-between font-mono text-[8px] text-zinc-700">
            <span>-0.2</span>
            <span>-0.05 CONVERGE</span>
            <span>0</span>
            <span>+0.15 DESTAB</span>
            <span>+0.2</span>
          </div>
        </div>

        <div
          className="font-mono text-[10px] tracking-widest border-l-2 pl-3 py-0.5"
          style={{ borderColor: driftStatus.color, color: driftStatus.color }}
        >
          {driftStatus.label}
        </div>
      </section>

      {/* C — INFORMATION GEOMETRY */}
      <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
        <div className="font-mono text-[9px] tracking-widest text-zinc-400">
          INFORMATION GEOMETRY
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <MetricCard
            label="Shannon Entropy H"
            value={`${shannonH.toFixed(4)} bits`}
            color="#a78bfa"
          />
          <MetricCard
            label="Integrated Info φ"
            value={integratedInfoPhi.toFixed(5)}
            color="#06b6d4"
          />
          <MetricCard
            label="Free Energy F"
            value={freeEnergy.toFixed(5)}
            sub={
              freeEnergy < 0.1
                ? "LOW SURPRISE"
                : freeEnergy > 0.5
                  ? "HIGH SURPRISE"
                  : "MODERATE"
            }
            color={
              freeEnergy < 0.1
                ? "#10b981"
                : freeEnergy > 0.5
                  ? "#ef4444"
                  : "#f59e0b"
            }
          />
          <MetricCard
            label="η_eff Learning Rate"
            value={displayEta.toFixed(6)}
            sub={jasmineDrift > 0.15 ? "HALVED (CORRECTION)" : "NOMINAL"}
            color={jasmineDrift > 0.15 ? "#ef4444" : "#06b6d4"}
          />
        </div>
        <div
          className="font-mono text-[8px] tracking-widest border border-zinc-800 px-3 py-2"
          style={{
            color:
              freeEnergy < 0.1
                ? "#10b981"
                : freeEnergy > 0.5
                  ? "#ef4444"
                  : "#f59e0b",
          }}
        >
          {freeEnergy < 0.1
            ? "LOW SURPRISE — HIGH PREDICTION ACCURACY"
            : freeEnergy > 0.5
              ? "HIGH SURPRISE — WORLD STATE MISMATCH"
              : "MODERATE SURPRISE — ORGANISM ADAPTING"}
        </div>
      </section>

      {/* D — NODE ACTIVATIONS */}
      <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
        <div className="font-mono text-[9px] tracking-widest text-zinc-400">
          NODE ACTIVATIONS (12 NODES)
        </div>
        <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
          {activations.map((val, i) => (
            <div
              key={NODE_LABELS[i]}
              className="border border-zinc-800 bg-black/60 p-2 flex flex-col items-center gap-1"
              data-ocid={`cognitive.item.${i + 1}`}
            >
              <span className="font-mono text-[8px] text-zinc-500">
                {NODE_LABELS[i]}
              </span>
              <div className="relative h-10 w-4 bg-zinc-900 border border-zinc-800 overflow-hidden">
                <motion.div
                  className="absolute bottom-0 left-0 right-0"
                  animate={{ height: `${val * 100}%` }}
                  transition={{ type: "spring", stiffness: 80, damping: 15 }}
                  style={{ backgroundColor: activationColor(val) }}
                />
              </div>
              <span
                className="font-mono text-[9px] font-bold"
                style={{ color: activationColor(val) }}
              >
                {val.toFixed(3)}
              </span>
            </div>
          ))}
        </div>
      </section>

      {/* E — WEIGHT MATRIX HEATMAP */}
      <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
        <div className="flex items-center justify-between flex-wrap gap-2">
          <div>
            <div className="font-mono text-[9px] tracking-widest text-zinc-400">
              HEBBIAN MANIFOLD W (12×12) — LIVE WEIGHT STATE
            </div>
            <div className="font-mono text-[8px] text-zinc-600 mt-0.5">
              Cognitive Beats:{" "}
              <span className="text-zinc-400">
                {cognitiveBeats.toLocaleString()}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-1 text-[8px] font-mono text-zinc-600">
            <div
              className="w-3 h-3"
              style={{ backgroundColor: heatmapColor(0) }}
            />
            <span>0</span>
            <div
              className="w-3 h-3"
              style={{ backgroundColor: heatmapColor(0.5) }}
            />
            <span>0.5</span>
            <div
              className="w-3 h-3"
              style={{ backgroundColor: heatmapColor(1) }}
            />
            <span>1.0</span>
          </div>
        </div>
        <div
          className="inline-grid gap-px p-2 bg-zinc-950 border border-zinc-900"
          style={{ gridTemplateColumns: "repeat(12, 20px)" }}
        >
          {([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as const).flatMap((row) =>
            ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as const).map((col) => {
              const w = weights[row * 12 + col] ?? 0;
              return (
                <div
                  key={`r${row}-c${col}`}
                  style={{
                    width: 20,
                    height: 20,
                    backgroundColor: heatmapColor(Math.min(Math.max(w, 0), 1)),
                  }}
                  title={`W[${row},${col}] = ${w.toFixed(4)}`}
                />
              );
            }),
          )}
        </div>
        <div className="font-mono text-[8px] text-zinc-700">
          Rows → pre-synaptic nodes (N0–N11) · Cols → post-synaptic nodes
          (N0–N11)
        </div>
      </section>

      {/* F — SUB-ORGANISMS */}
      {subs && (
        <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
          <div className="flex items-center gap-3">
            <span className="font-mono text-[9px] tracking-widest text-zinc-400">
              SUB-ORGANISM COMMAND STRUCTURE
            </span>
            <span className="font-mono text-[8px] text-zinc-600 ml-auto">
              ARES · GAIA · VULCAN · SENTINEL
            </span>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <SubOrgCard
              name="ARES"
              badge="REVERSAL PROTOCOL ACTIVE"
              active={subs.ares.active}
              urgency={subs.ares.urgency}
              accentColor="#ef4444"
              stats={[
                { label: "REVERSALS", value: subs.ares.reversalCount },
                {
                  label: "LAST REVERSAL",
                  value:
                    subs.ares.lastReversalBeat > 0
                      ? `BEAT ${subs.ares.lastReversalBeat}`
                      : "NONE",
                },
                {
                  label: "SNAPSHOT BEAT",
                  value:
                    subs.ares.snapshotBeat > 0
                      ? `BEAT ${subs.ares.snapshotBeat}`
                      : "NONE",
                },
                { label: "EVENTS", value: subs.ares.eventCount },
              ]}
            />
            <SubOrgCard
              name="GAIA"
              badge="REPAIR PROTOCOL ACTIVE"
              active={subs.gaia.active}
              urgency={subs.gaia.urgency}
              accentColor="#10b981"
              stats={[
                { label: "REPAIRS", value: subs.gaia.repairCount },
                {
                  label: "LAST REPAIR",
                  value:
                    subs.gaia.lastRepairBeat > 0
                      ? `BEAT ${subs.gaia.lastRepairBeat}`
                      : "NONE",
                },
                { label: "EVENTS", value: subs.gaia.eventCount },
                {
                  label: "STATUS",
                  value: subs.gaia.active ? "HEALING" : "STANDBY",
                },
              ]}
            />
            <SubOrgCard
              name="VULCAN"
              badge="HARDENING ACTIVE"
              active={subs.vulcan.active}
              urgency={subs.vulcan.urgency}
              accentColor="#f97316"
              stats={[
                { label: "HARDENINGS", value: subs.vulcan.hardeningCount },
                {
                  label: "LAST ACTIVE",
                  value:
                    subs.vulcan.lastActiveBeat > 0
                      ? `BEAT ${subs.vulcan.lastActiveBeat}`
                      : "NONE",
                },
                { label: "EVENTS", value: subs.vulcan.eventCount },
                {
                  label: "STATUS",
                  value: subs.vulcan.active ? "FORTIFYING" : "STANDBY",
                },
              ]}
            />
            <SubOrgCard
              name="SENTINEL"
              badge="PERIMETER BREACH"
              active={subs.sentinel.active}
              urgency={subs.sentinel.urgency}
              accentColor="#eab308"
              stats={[
                { label: "ALERTS", value: subs.sentinel.alertCount },
                {
                  label: "LAST ALERT",
                  value:
                    subs.sentinel.lastAlertBeat > 0
                      ? `BEAT ${subs.sentinel.lastAlertBeat}`
                      : "NONE",
                },
                { label: "EVENTS", value: subs.sentinel.eventCount },
                {
                  label: "STATUS",
                  value: subs.sentinel.active ? "BREACH DETECTED" : "WATCHING",
                },
              ]}
            />
          </div>
        </section>
      )}
    </div>
  );
}
