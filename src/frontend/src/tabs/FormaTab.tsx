/**
 * FormaTab.tsx — FORMA Compounding Engine + Jacob's Ladder
 * The organism's compounding financial intelligence, displayed as a living dashboard.
 */

import { motion } from "motion/react";
import {
  formatPct,
  formatSovereign,
  useFormaState,
  useJacobsLadder,
} from "../hooks/useForma";

// ── Color constants ────────────────────────────────────────────────────────────
const C = {
  cyan: "oklch(0.72 0.16 200)",
  gold: "oklch(0.78 0.18 85)",
  amber: "oklch(0.75 0.18 62)",
  purple: "oklch(0.65 0.28 290)",
  green: "oklch(0.62 0.17 145)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  dim: "oklch(0.28 0.03 270)",
  bg: "rgba(0,0,0,0.40)",
  border: "rgba(255,255,255,0.06)",
};

// ── Primitive components ───────────────────────────────────────────────────────
function Lbl({ children }: { children: React.ReactNode }) {
  return (
    <span
      className="font-mono text-[8px] tracking-[0.35em]"
      style={{ color: C.muted }}
    >
      {children}
    </span>
  );
}

function Panel({
  children,
  accentColor = C.border,
  className = "",
}: {
  children: React.ReactNode;
  accentColor?: string;
  className?: string;
}) {
  return (
    <div
      className={`border p-5 ${className}`}
      style={{ borderColor: accentColor, background: C.bg }}
    >
      {children}
    </div>
  );
}

function SecTitle({
  icon,
  children,
  color = C.muted,
}: {
  icon?: string;
  children: React.ReactNode;
  color?: string;
}) {
  return (
    <div
      className="font-mono text-[8px] tracking-[0.6em] mb-4 pb-2 border-b flex items-center gap-2"
      style={{ color, borderColor: C.border }}
    >
      {icon && <span>{icon}</span>}
      {children}
    </div>
  );
}

// ── FORMA Compounding Engine Panel ────────────────────────────────────────────
function FormaEnginePanel() {
  const { data: forma, isLoading } = useFormaState();

  const capital = forma?.formaCapital ?? 0;
  const rate = forma?.compoundRatePerBeat ?? 0;
  const entropy = forma?.vonNeumannEntropy ?? 0;
  const coherence = 1 - entropy;
  const beatCount = forma?.beatCount ?? 0;

  // Formatted display strings
  const capitalSci = formatSovereign(capital, 3);
  const rateSci = formatPct(rate);

  return (
    <Panel accentColor={`${C.cyan}28`} className="">
      {/* Header */}
      <div className="flex items-center justify-between mb-5">
        <div
          className="font-mono text-[9px] tracking-[0.5em]"
          style={{ color: C.cyan }}
        >
          ƒ FORMA COMPOUNDING ENGINE
        </div>
        <div className="flex items-center gap-2">
          <motion.div
            animate={{ opacity: [1, 0.2, 1] }}
            transition={{
              duration: 0.873,
              repeat: Number.POSITIVE_INFINITY,
              ease: "easeInOut",
            }}
            className="w-1.5 h-1.5 rounded-full"
            style={{ background: C.cyan, boxShadow: `0 0 8px ${C.cyan}` }}
          />
          <span
            className="font-mono text-[7px] tracking-widest"
            style={{ color: C.cyan }}
          >
            LIVE
          </span>
        </div>
      </div>

      {/* FORMA CAPITAL — the organism's net worth */}
      <div className="mb-6">
        <Lbl>FORMA CAPITAL</Lbl>
        <motion.div
          key={String(capital)}
          animate={{ opacity: [0.6, 1] }}
          transition={{ duration: 0.3 }}
          className="mt-2"
        >
          <div
            className="font-mono font-bold leading-none"
            style={{
              fontSize: "clamp(1.4rem, 3vw, 2.25rem)",
              color: C.gold,
              textShadow: `0 0 32px ${C.gold}55`,
            }}
          >
            ƒ{" "}
            {capitalSci.includes("10^") ? (
              <>
                {capitalSci.split(" × 10^")[0]}
                <span style={{ fontSize: "0.7em" }}> × 10</span>
                <sup style={{ fontSize: "0.5em" }}>
                  {capitalSci.split("10^")[1]}
                </sup>
              </>
            ) : (
              capitalSci
            )}
          </div>
          {capital > 0 && (
            <div
              className="font-mono text-[8px] mt-1 tracking-wide opacity-50"
              style={{ color: C.gold }}
            >
              ƒ {capital.toLocaleString("en-US", { maximumFractionDigits: 6 })}
            </div>
          )}
        </motion.div>
      </div>

      {/* COMPOUND RATE + BEAT COUNT */}
      <div className="grid grid-cols-2 gap-4 mb-5">
        <div>
          <Lbl>COMPOUND RATE / BEAT</Lbl>
          <motion.div
            key={String(rate)}
            animate={{ opacity: [0.5, 1] }}
            transition={{ duration: 0.3 }}
            className="font-mono text-xs mt-1"
            style={{ color: C.green }}
          >
            {rateSci.includes("10^") ? (
              <>
                {rateSci.split(" × 10^")[0]}
                <span style={{ fontSize: "0.8em" }}> × 10</span>
                <sup style={{ fontSize: "0.65em" }}>
                  {rateSci.split("10^")[1].replace("%", "")}
                </sup>
                %
              </>
            ) : (
              rateSci
            )}
          </motion.div>
        </div>
        <div>
          <Lbl>BEAT COUNT</Lbl>
          <motion.div
            key={beatCount}
            animate={{ opacity: [0.5, 1] }}
            transition={{ duration: 0.2 }}
            className="font-mono text-xs mt-1 tabular-nums"
            style={{ color: C.cyan }}
          >
            {beatCount.toLocaleString()}
          </motion.div>
        </div>
      </div>

      {/* Entropy / Coherence split bar */}
      <div className="mb-5">
        <div className="flex justify-between mb-1.5">
          <Lbl>VON NEUMANN ENTROPY</Lbl>
          <Lbl>SPECTRAL COHERENCE</Lbl>
        </div>
        {/* Colored bar */}
        <div
          className="relative h-5 flex overflow-hidden rounded-none border"
          style={{ borderColor: C.border }}
        >
          {/* Entropy portion — amber */}
          <div
            className="h-full flex items-center justify-center"
            style={{
              width: `${entropy * 100}%`,
              background: `${C.amber}44`,
              borderRight: `1px solid ${C.amber}`,
              transition: "width 0.4s ease",
            }}
          >
            <span className="font-mono text-[7px]" style={{ color: C.amber }}>
              {entropy.toFixed(6)}
            </span>
          </div>
          {/* Coherence portion — cyan */}
          <div
            className="h-full flex items-center justify-center flex-1"
            style={{
              background: `${C.cyan}22`,
              transition: "width 0.4s ease",
            }}
          >
            <span className="font-mono text-[7px]" style={{ color: C.cyan }}>
              {coherence.toFixed(6)}
            </span>
          </div>
        </div>
        <div className="flex justify-between mt-1">
          <span className="font-mono text-[7px]" style={{ color: C.amber }}>
            ENT
          </span>
          <span className="font-mono text-[7px]" style={{ color: C.muted }}>
            ∑ = 1.000000
          </span>
          <span className="font-mono text-[7px]" style={{ color: C.cyan }}>
            COH
          </span>
        </div>
      </div>

      {/* FORMA PROJECTIONS */}
      <div>
        <Lbl>FORMA PROJECTIONS</Lbl>
        <div className="mt-2 space-y-2">
          {[
            {
              label: "+1,000 BEATS",
              proj: forma?.projPlus1k ?? Number.POSITIVE_INFINITY,
            },
            {
              label: "+10,000 BEATS",
              proj: forma?.projPlus10k ?? Number.POSITIVE_INFINITY,
            },
          ].map(({ label, proj }) => (
            <div
              key={label}
              className="flex items-center justify-between px-3 py-2 border"
              style={{ borderColor: `${C.gold}22`, background: `${C.gold}04` }}
            >
              <Lbl>{label}</Lbl>
              <span
                className="font-mono text-sm font-bold"
                style={{ color: C.gold, textShadow: `0 0 12px ${C.gold}55` }}
              >
                {Number.isFinite(proj)
                  ? `ƒ ${formatSovereign(proj, 2)}`
                  : "ƒ ∞"}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Loading state */}
      {isLoading && (
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{ background: "rgba(0,0,0,0.5)", backdropFilter: "blur(4px)" }}
          data-ocid="forma.engine.loading_state"
        >
          <span
            className="font-mono text-[9px] tracking-widest"
            style={{ color: C.muted }}
          >
            SYNCHRONIZING...
          </span>
        </div>
      )}
    </Panel>
  );
}

// ── Jacob's Ladder Panel ──────────────────────────────────────────────────────
function JacobsLadderPanel() {
  const { data: jacobs } = useJacobsLadder();

  const currentRung = jacobs?.currentRung ?? 4;
  const jVel = jacobs?.jacobVelocity ?? 1.506172;
  const sacesi = jacobs?.sacesiTarget ?? 1.00411499;
  const rungs = jacobs?.rungs ?? [];

  return (
    <Panel accentColor={`${C.amber}22`}>
      <SecTitle color={C.amber}>■ JACOB&apos;S LADDER</SecTitle>

      {/* Ladder visualization */}
      <div className="space-y-2 mb-5" data-ocid="forma.ladder.list">
        {rungs.map((rung, i) => {
          const isPast = i < currentRung;
          const isActive = i === currentRung;
          const isFuture = i > currentRung;
          const color = isPast ? C.gold : isActive ? C.amber : C.dim;

          return (
            <motion.div
              key={rung.index}
              data-ocid={`forma.ladder.item.${i + 1}`}
              animate={
                isActive
                  ? {
                      boxShadow: [
                        `0 0 8px ${C.amber}22`,
                        `0 0 20px ${C.amber}44`,
                        `0 0 8px ${C.amber}22`,
                      ],
                    }
                  : {}
              }
              transition={{ duration: 1.746, repeat: Number.POSITIVE_INFINITY }}
              className="flex items-center gap-3 px-3 py-2.5 border relative overflow-hidden"
              style={{
                borderColor: `${color}44`,
                background: isActive ? `${color}10` : "transparent",
                opacity: isFuture ? 0.35 : 1,
              }}
            >
              {/* Left: rung progress indicator */}
              <div
                className="w-1 self-stretch shrink-0"
                style={{
                  background: isPast ? C.gold : isActive ? C.amber : C.dim,
                }}
              />

              {/* Label + desc */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-mono text-[9px]" style={{ color }}>
                    {rung.label}
                  </span>
                  {isActive && (
                    <motion.span
                      animate={{ opacity: [1, 0.4, 1] }}
                      transition={{
                        duration: 0.873,
                        repeat: Number.POSITIVE_INFINITY,
                      }}
                      className="font-mono text-[6px] px-1.5 py-0.5"
                      style={{
                        color: C.amber,
                        border: `1px solid ${C.amber}55`,
                      }}
                    >
                      ◆ CURRENT
                    </motion.span>
                  )}
                  {isPast && (
                    <span
                      className="font-mono text-[6px] px-1"
                      style={{ color: `${C.gold}88` }}
                    >
                      ✓
                    </span>
                  )}
                </div>
                <span
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  {rung.desc}
                </span>
              </div>

              {/* Multiplier */}
              <div className="text-right shrink-0">
                <span
                  className="font-mono font-bold text-sm"
                  style={{
                    color,
                    textShadow: isActive ? `0 0 10px ${color}` : undefined,
                  }}
                >
                  {rung.multiplier}
                </span>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Velocity + SACESI */}
      <div
        className="grid grid-cols-2 gap-4 pt-4 border-t"
        style={{ borderColor: C.border }}
      >
        <div>
          <Lbl>JACOB VELOCITY</Lbl>
          <motion.div
            key={jVel}
            animate={{ opacity: [0.5, 1] }}
            transition={{ duration: 0.3 }}
            className="font-mono text-lg font-bold mt-1 tabular-nums"
            style={{ color: C.gold, textShadow: `0 0 16px ${C.gold}55` }}
          >
            {jVel.toFixed(6)}x
          </motion.div>
        </div>
        <div>
          <Lbl>SACESI TARGET</Lbl>
          <div
            className="font-mono text-sm mt-1 tabular-nums"
            style={{ color: C.purple }}
          >
            {sacesi.toFixed(8)}
          </div>
        </div>
      </div>
    </Panel>
  );
}

// ── Main FormaTab export ──────────────────────────────────────────────────────
export function FormaTab() {
  return (
    <div className="space-y-5" data-ocid="forma.page">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* FORMA engine — left */}
        <div className="relative">
          <FormaEnginePanel />
        </div>
        {/* Jacob's Ladder — right */}
        <JacobsLadderPanel />
      </div>
    </div>
  );
}
