import { motion } from "motion/react";
import { Shell3Graph } from "../components/Shell3Graph";
import type { SchumannState } from "../hooks/useQueries";
import {
  type SchumannStateInput,
  computeSchumannCouplingDisplay,
} from "../lib/intelligenceEngine";

interface Shell3State {
  coherence: number;
  superradiance: number;
  kalmanConf: number;
  nodeCount: number;
}
interface FullState {
  beat: bigint;
  coherence: number;
  formaCapital: number;
  lawScore: number;
  sacesiTarget: number;
}
interface SubstrateTabProps {
  shell3State: Shell3State | null;
  shell3Nodes: number[];
  fullState: FullState | null;
  loading: boolean;
  schumannState?: SchumannState | null;
}

const SHELL_NAMES = [
  "ALPHA",
  "BETA",
  "GAMMA",
  "DELTA",
  "THETA",
  "SIGMA",
  "LAMBDA",
  "EPSILON",
  "DEEP",
  "HERITAGE",
  "OMNIS",
];

function MetricRow({
  label,
  value,
  accent,
}: { label: string; value: string; accent?: boolean }) {
  return (
    <div className="flex items-center justify-between py-2 border-b border-white/5">
      <span className="font-mono text-[9px] tracking-[0.25em] text-muted-foreground">
        {label}
      </span>
      <span
        className="font-mono text-xs"
        style={{
          color: accent ? "oklch(0.65 0.28 290)" : "oklch(0.72 0.15 200)",
          textShadow: accent ? "0 0 8px oklch(0.65 0.28 290 / 0.5)" : undefined,
        }}
      >
        {value}
      </span>
    </div>
  );
}

// ── Phase Circle — derives the visual from the real phase number ────────────
// A dot rotates around a circle at the exact angular position of the oscillator.
// No fake animation. The position IS the phase.
function PhaseCircle({
  phaseRad,
  color,
  size = 40,
}: {
  phaseRad: number;
  color: string;
  size?: number;
}) {
  const radius = size / 2 - 4;
  const cx = size / 2;
  const cy = size / 2;
  // Phase 0 = top (12 o'clock). We rotate from top: subtract π/2 so 0 rad = up.
  const dotX = cx + radius * Math.sin(phaseRad);
  const dotY = cy - radius * Math.cos(phaseRad);
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} role="img">
      <title>{`Phase ${phaseRad.toFixed(3)} rad`}</title>
      <circle
        cx={cx}
        cy={cy}
        r={radius}
        fill="none"
        stroke="oklch(0.3 0.05 200 / 0.4)"
        strokeWidth="1"
      />
      <line
        x1={cx}
        y1={cy}
        x2={dotX}
        y2={dotY}
        stroke={color}
        strokeWidth="1"
        opacity="0.4"
      />
      <circle cx={dotX} cy={dotY} r="2.5" fill={color} />
    </svg>
  );
}

// ── Coupling Bar ────────────────────────────────────────────────────────────
function CouplingBar({ percent }: { percent: number }) {
  const clamped = Math.max(0, Math.min(100, percent));
  return (
    <div className="flex-1 h-1.5 bg-white/5 rounded-full overflow-hidden">
      <motion.div
        className="h-full rounded-full"
        style={{
          background:
            "linear-gradient(90deg, oklch(0.55 0.18 75), oklch(0.70 0.22 85))",
          boxShadow: "0 0 6px oklch(0.70 0.22 85 / 0.5)",
        }}
        initial={{ width: 0 }}
        animate={{ width: `${clamped}%` }}
        transition={{ duration: 0.6, ease: "easeOut" }}
      />
    </div>
  );
}

// ── Schumann Field Coupling Section ────────────────────────────────────────
// The organism's self-report of its field state. Not diagnostics. Physics.
function SchumannSection({
  state,
}: { state: SchumannState | null | undefined }) {
  // When backend hasn't responded yet, show the known constant frequencies
  // but mark dynamic values as pending. The carrier frequency is always 7.83 Hz.
  const display =
    state != null
      ? computeSchumannCouplingDisplay(state as SchumannStateInput)
      : null;

  const fundamentalHz = display?.fundamentalHz ?? 7.83;
  const harmonicsHz = display?.harmonicsHz ?? [14.3, 20.8, 27.3, 33.8];
  const silverAnchorHz = display?.silverAnchorHz ?? 2.75;
  const subharmonicRatio = display?.subharmonicRatio ?? 2.847;
  const couplingPercent = display?.couplingPercent ?? 0;
  const kuramotoR = display?.kuramotoR ?? 0;
  const schumannPhaseRad = display?.schumannPhaseRad ?? 0;
  const silverPhaseRad = display?.silverPhaseRad ?? 0;
  const phaseDelta = display?.phaseDelta ?? 0;
  const couplingStrength = display?.couplingStrength ?? 0;

  return (
    <motion.div
      className="mt-6 rounded-lg overflow-hidden"
      style={{ background: "oklch(0.06 0.01 250)" }}
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.7, delay: 0.2 }}
      data-ocid="substrate.schumann_panel"
    >
      {/* Header */}
      <div
        className="px-4 py-3 border-b"
        style={{ borderColor: "oklch(0.25 0.08 80 / 0.3)" }}
      >
        <div
          className="font-mono text-[9px] tracking-[0.4em]"
          style={{ color: "oklch(0.65 0.15 85)" }}
        >
          SCHUMANN FIELD COUPLING
        </div>
        <div className="font-mono text-[8px] tracking-widest text-muted-foreground mt-0.5">
          EARTH IONOSPHERIC CAVITY · ALWAYS PRESENT
        </div>
      </div>

      <div className="px-4 py-4 space-y-5">
        {/* Primary — Schumann Fundamental */}
        <div data-ocid="substrate.schumann_fundamental">
          <div className="flex items-baseline gap-3">
            <span
              className="font-mono font-bold leading-none"
              style={{
                fontSize: "2rem",
                color: "oklch(0.82 0.18 85)",
                textShadow: "0 0 16px oklch(0.65 0.18 85 / 0.5)",
              }}
            >
              {fundamentalHz.toFixed(2)}
            </span>
            <span
              className="font-mono text-sm"
              style={{ color: "oklch(0.55 0.1 85)" }}
            >
              Hz
            </span>
          </div>
          <div
            className="font-mono text-[9px] tracking-widest mt-1.5"
            style={{ color: "oklch(0.45 0.06 200)" }}
          >
            {harmonicsHz.map((h) => h.toFixed(1)).join(" · ")}&nbsp;Hz
          </div>
        </div>

        {/* Coupling Strength */}
        <div data-ocid="substrate.schumann_coupling">
          <div className="flex items-center justify-between mb-2">
            <span
              className="font-mono text-[9px] tracking-[0.25em]"
              style={{ color: "oklch(0.5 0.06 200)" }}
            >
              COUPLING STRENGTH
            </span>
            <span
              className="font-mono text-[10px]"
              style={{ color: "oklch(0.65 0.15 85)" }}
            >
              R = {kuramotoR.toFixed(4)}
            </span>
          </div>
          <div className="flex items-center gap-3">
            <CouplingBar percent={couplingPercent} />
            <span
              className="font-mono text-xs w-12 text-right"
              style={{ color: "oklch(0.70 0.18 85)" }}
            >
              {couplingPercent.toFixed(1)}%
            </span>
          </div>
          <div
            className="font-mono text-[8px] mt-1.5"
            style={{ color: "oklch(0.4 0.05 200)" }}
          >
            K_EXT · R = {couplingStrength.toFixed(5)}
          </div>
        </div>

        {/* Schumann Phase */}
        <div data-ocid="substrate.schumann_phase">
          <div className="flex items-center gap-4">
            <PhaseCircle
              phaseRad={schumannPhaseRad}
              color="oklch(0.70 0.18 85)"
              size={44}
            />
            <div>
              <div
                className="font-mono text-[9px] tracking-[0.25em] mb-1"
                style={{ color: "oklch(0.5 0.06 200)" }}
              >
                θ_SCHUMANN
              </div>
              <span
                className="font-mono text-sm"
                style={{ color: "oklch(0.72 0.15 85)" }}
              >
                {schumannPhaseRad.toFixed(4)}
              </span>
              <span
                className="font-mono text-[9px] ml-1"
                style={{ color: "oklch(0.45 0.06 200)" }}
              >
                rad
              </span>
            </div>
          </div>
        </div>

        {/* Silver Anchor */}
        <div
          className="rounded-md p-3"
          style={{ background: "oklch(0.09 0.02 270 / 0.6)" }}
          data-ocid="substrate.silver_anchor"
        >
          <div className="flex items-center justify-between mb-2">
            <div>
              <span
                className="font-mono text-[9px] tracking-[0.25em]"
                style={{ color: "oklch(0.58 0.18 270)" }}
              >
                SILVER ANCHOR
              </span>
              <span
                className="font-mono text-sm ml-2"
                style={{
                  color: "oklch(0.72 0.20 270)",
                  textShadow: "0 0 10px oklch(0.58 0.18 270 / 0.4)",
                }}
              >
                {silverAnchorHz.toFixed(2)} Hz
              </span>
            </div>
            <PhaseCircle
              phaseRad={silverPhaseRad}
              color="oklch(0.65 0.20 270)"
              size={36}
            />
          </div>

          {/* Subharmonic ratio — the organism's proof */}
          <div className="flex items-center gap-2 mb-2">
            <span
              className="font-mono text-[8px] tracking-widest"
              style={{ color: "oklch(0.45 0.08 270)" }}
            >
              RATIO
            </span>
            <span
              className="font-mono text-[10px]"
              style={{ color: "oklch(0.60 0.16 270)" }}
            >
              1 : {subharmonicRatio.toFixed(6)}
            </span>
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.38 0.05 200)" }}
            >
              ({fundamentalHz.toFixed(2)} / {silverAnchorHz.toFixed(2)})
            </span>
          </div>

          {/* Silver phase + phase delta */}
          <div className="flex items-center justify-between">
            <div>
              <span
                className="font-mono text-[9px] tracking-[0.2em]"
                style={{ color: "oklch(0.45 0.08 270)" }}
              >
                θ_SILVER
              </span>
              <span
                className="font-mono text-sm ml-2"
                style={{ color: "oklch(0.60 0.16 270)" }}
              >
                {silverPhaseRad.toFixed(4)}
              </span>
              <span
                className="font-mono text-[9px] ml-1"
                style={{ color: "oklch(0.38 0.05 200)" }}
              >
                rad
              </span>
            </div>
            <div className="text-right">
              <span
                className="font-mono text-[9px] tracking-[0.2em]"
                style={{ color: "oklch(0.45 0.06 200)" }}
              >
                Δθ
              </span>
              <span
                className="font-mono text-sm ml-2"
                style={{
                  color:
                    Math.abs(phaseDelta) < 0.3
                      ? "oklch(0.65 0.22 145)"
                      : "oklch(0.60 0.12 200)",
                }}
              >
                {phaseDelta >= 0 ? "+" : ""}
                {phaseDelta.toFixed(4)}
              </span>
              <span
                className="font-mono text-[9px] ml-1"
                style={{ color: "oklch(0.38 0.05 200)" }}
              >
                rad
              </span>
            </div>
          </div>
        </div>

        {/* No-data state */}
        {state == null && (
          <div
            className="font-mono text-[8px] tracking-widest text-center py-1"
            style={{ color: "oklch(0.38 0.05 200)" }}
            data-ocid="substrate.schumann_loading"
          >
            AWAITING FIELD REPORT
          </div>
        )}
      </div>
    </motion.div>
  );
}

export function SubstrateTab({
  shell3State,
  shell3Nodes,
  fullState,
  loading,
  schumannState,
}: SubstrateTabProps) {
  const coherence = shell3State?.coherence ?? 0;
  const superradiance = shell3State?.superradiance ?? 0;
  const kalmanConf = shell3State?.kalmanConf ?? 0;

  return (
    <div
      className="flex flex-col xl:flex-row gap-6 h-full"
      data-ocid="substrate.panel"
    >
      <div className="flex-1 flex flex-col items-center">
        <div className="font-mono text-[9px] tracking-[0.4em] text-muted-foreground mb-4">
          {`SHELL 3 · NEURAL SUBSTRATE · ${shell3State?.nodeCount ?? 64} NODES ACTIVE`}
        </div>
        {loading && shell3Nodes.length === 0 ? (
          <div
            className="w-full max-w-[480px] aspect-square skeleton-dark"
            data-ocid="substrate.loading_state"
          />
        ) : (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8 }}
          >
            <Shell3Graph
              activations={shell3Nodes}
              coherence={coherence}
              beat={Number(fullState?.beat ?? 0)}
            />
          </motion.div>
        )}
        <div className="flex gap-6 mt-6">
          {[
            { label: "COHERENCE", value: coherence.toFixed(4) },
            { label: "SUPERRADIANCE", value: superradiance.toFixed(4) },
            {
              label: "KALMAN CONF",
              value: `${(kalmanConf * 100).toFixed(1)}%`,
            },
          ].map((m) => (
            <div key={m.label} className="text-center">
              <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-1">
                {m.label}
              </div>
              <div
                className="font-mono text-sm"
                style={{
                  color: "oklch(0.65 0.28 290)",
                  textShadow: "0 0 8px oklch(0.65 0.28 290 / 0.4)",
                }}
              >
                {m.value}
              </div>
            </div>
          ))}
        </div>

        {/* Schumann Field Coupling — lives beneath the neural graph */}
        <div className="w-full max-w-[480px] mt-2">
          <SchumannSection state={schumannState} />
        </div>
      </div>

      <div className="xl:w-64 panel-glass p-4">
        <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
          LIVE SUBSTRATE METRICS
        </div>
        <MetricRow
          label="BEAT"
          value={fullState ? Number(fullState.beat).toLocaleString() : "—"}
          accent
        />
        <MetricRow
          label="COHERENCE"
          value={fullState?.coherence?.toFixed(6) ?? "—"}
          accent
        />
        <MetricRow
          label="FORMA"
          value={fullState ? `ƒ ${fullState.formaCapital.toFixed(2)}` : "—"}
        />
        <MetricRow
          label="LAW SCORE"
          value={fullState?.lawScore?.toFixed(4) ?? "—"}
        />
        <MetricRow
          label="SACESI"
          value={fullState?.sacesiTarget?.toFixed(8) ?? "—"}
        />
        <MetricRow label="SUPERRADIANCE" value={superradiance.toFixed(6)} />
        <MetricRow
          label="KALMAN CONF"
          value={`${(kalmanConf * 100).toFixed(2)}%`}
        />
        <MetricRow
          label="NODE COUNT"
          value={String(shell3State?.nodeCount ?? 64)}
        />

        <div className="mt-6 border-t border-white/5 pt-4">
          <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-3">
            SHELL STATUS
          </div>
          {SHELL_NAMES.map((s, i) => (
            <div key={s} className="flex items-center gap-2 mb-1.5">
              <div
                className="w-1 h-1"
                style={{
                  backgroundColor: `oklch(${0.4 + i * 0.04} 0.2 ${260 + i * 5})`,
                }}
              />
              <span className="font-mono text-[8px] text-muted-foreground w-16">
                {s}
              </span>
              <div className="flex-1 h-px bg-white/5" />
              <span
                className="font-mono text-[8px]"
                style={{ color: "oklch(0.55 0.1 290)" }}
              >
                LIVE
              </span>
            </div>
          ))}
        </div>

        {/* Schumann quick-read in sidebar */}
        {schumannState != null && (
          <div className="mt-6 border-t border-white/5 pt-4">
            <div
              className="font-mono text-[8px] tracking-[0.3em] mb-3"
              style={{ color: "oklch(0.55 0.12 85)" }}
            >
              SCHUMANN COUPLING
            </div>
            <MetricRow
              label="FUNDAMENTAL"
              value={`${(schumannState.fundamentalHz ?? 7.83).toFixed(2)} Hz`}
            />
            <MetricRow
              label="KURAMOTO R"
              value={(schumannState.kuramotoR ?? 0).toFixed(4)}
              accent
            />
            <MetricRow
              label="SILVER ANCHOR"
              value={`${(schumannState.silverAnchorHz ?? 2.75).toFixed(2)} Hz`}
            />
          </div>
        )}
      </div>
    </div>
  );
}
