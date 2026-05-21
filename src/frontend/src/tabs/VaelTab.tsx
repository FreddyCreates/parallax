import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";

// ── Design tokens (canvas-safe literals) ────────────────────────────────────
const C = {
  gold: "oklch(0.78 0.15 85)",
  goldDim: "rgba(190,150,50,0.12)",
  green: "oklch(0.65 0.18 145)",
  red: "oklch(0.55 0.22 25)",
  redDim: "rgba(180,60,60,0.12)",
  amber: "oklch(0.72 0.16 80)",
  violet: "oklch(0.65 0.20 290)",
  cyan: "oklch(0.72 0.16 200)",
  text: "oklch(0.95 0.02 240)",
  muted: "oklch(0.55 0.02 240)",
  bg: "oklch(0.08 0.01 240)",
  bgPanel: "rgba(8,10,14,0.96)",
  bgCard: "rgba(12,15,20,0.98)",
  border: "rgba(255,255,255,0.07)",
  borderGold: "rgba(190,150,50,0.22)",
  borderRed: "rgba(180,60,60,0.30)",
};

// ── Types ────────────────────────────────────────────────────────────────────
interface VaelState {
  immuneField: number;
  reflexScore: number;
  duraCoverage: number;
  aegisLock: number;
  riftDepth: number;
  memoriaFactor: number;
  sentinelActive: boolean;
  veilFilter: number;
  combinedField: number;
  threatScore: number;
  parallaxField: number;
  veritasTruth: number;
  adversaryCount: number;
  breachCount: number;
}

interface QmemState {
  charge: number;
  fidelity: number;
  totalEpisodes: number;
  peakCoherence: number;
  head: number;
}

interface HtmState {
  predError: number;
  surpriseCount: number;
  hebbGated: boolean;
}

interface PatternState {
  libSize: number;
  schemaCount: number;
  activeSchemas: number;
  mineCycle: number;
}

type AresSlot = [number, number, number, number, number]; // [beat, coherence, formaCapital, score, idx]

// ── Utility sub-components ───────────────────────────────────────────────────
function Lbl({ children }: { children: React.ReactNode }) {
  return (
    <span
      className="font-mono text-[8px] tracking-[0.3em] uppercase"
      style={{ color: C.muted }}
    >
      {children}
    </span>
  );
}

function Val({
  children,
  color = C.text,
  size = "text-xs",
}: {
  children: React.ReactNode;
  color?: string;
  size?: string;
}) {
  return (
    <span className={`font-mono ${size} tabular-nums`} style={{ color }}>
      {children}
    </span>
  );
}

function PanelBox({
  children,
  className = "",
  style = {},
  threatFlash = false,
}: {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  threatFlash?: boolean;
}) {
  return (
    <div
      className={`border ${threatFlash ? "animate-threat-flash" : ""} ${className}`}
      style={{
        borderColor: C.border,
        background: C.bgCard,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

function SectionTitle({
  children,
  accent = C.muted,
}: { children: React.ReactNode; accent?: string }) {
  return (
    <div
      className="font-mono text-[8px] tracking-[0.5em] mb-3 pb-2 border-b flex items-center gap-2"
      style={{ color: accent, borderColor: C.border }}
    >
      {children}
    </div>
  );
}

function ScoreBar({
  value,
  max = 1,
  color,
  height = 4,
}: {
  value: number;
  max?: number;
  color: string;
  height?: number;
}) {
  const pct = Math.min(100, (value / max) * 100);
  return (
    <div
      className="w-full rounded-none"
      style={{ height, background: "rgba(255,255,255,0.05)" }}
    >
      <div
        style={{
          width: `${pct}%`,
          height: "100%",
          background: color,
          transition: "width 0.6s ease",
          boxShadow: `0 0 6px ${color}88`,
        }}
      />
    </div>
  );
}

function Dot({ color, size = 7 }: { color: string; size?: number }) {
  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        backgroundColor: color,
        boxShadow: `0 0 8px ${color}`,
        flexShrink: 0,
      }}
    />
  );
}

function StatusBadge({
  active,
  labels = ["ARMED", "STANDBY"],
}: { active: boolean; labels?: string[] }) {
  const color = active ? C.green : C.muted;
  return (
    <span
      className="font-mono text-[7px] tracking-[0.2em] px-1.5 py-0.5 border"
      style={{ color, borderColor: `${color}44`, background: `${color}10` }}
    >
      {active ? labels[0] : labels[1]}
    </span>
  );
}

// ── Entity Tile ──────────────────────────────────────────────────────────────
function EntityTile({
  name,
  value,
  description,
  armed,
  color,
  isAlert = false,
}: {
  name: string;
  value: number;
  description: string;
  armed: boolean;
  color: string;
  isAlert?: boolean;
}) {
  return (
    <div
      className={`border p-3 flex flex-col gap-2 relative overflow-hidden ${isAlert ? "animate-threat-flash" : ""}`}
      style={{
        borderColor: isAlert ? C.borderRed : `${color}33`,
        background: `${color}06`,
      }}
    >
      {/* Glow line at top */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: 1,
          background: `linear-gradient(90deg, transparent, ${color}88, transparent)`,
        }}
      />

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Dot color={armed ? color : C.muted} size={6} />
          <span
            className="font-mono text-[9px] tracking-[0.3em] font-bold"
            style={{ color: C.text }}
          >
            {name}
          </span>
        </div>
        <StatusBadge active={armed} labels={["ARMED", "IDLE"]} />
      </div>

      <div>
        <span
          className="font-mono text-lg font-bold tabular-nums"
          style={{ color, textShadow: `0 0 16px ${color}55` }}
        >
          {value.toFixed(4)}
        </span>
      </div>

      <ScoreBar value={value} max={2} color={color} height={2} />

      <span
        className="font-mono text-[8px] leading-relaxed"
        style={{ color: C.muted }}
      >
        {description}
      </span>
    </div>
  );
}

// ── Defense Chain Flow ────────────────────────────────────────────────────────
function DefenseChainFlow({ vael }: { vael: VaelState }) {
  const CHAIN = [
    { id: "VAEL", value: vael.immuneField, color: C.gold, type: "INT" },
    { id: "SENTINEL", value: vael.reflexScore, color: C.gold, type: "INT" },
    { id: "VEIL", value: vael.veilFilter, color: C.gold, type: "INT" },
    { id: "AEGIS", value: vael.aegisLock, color: C.gold, type: "INT" },
    { id: "DURA", value: vael.duraCoverage, color: C.red, type: "EXT" },
    { id: "RIFT", value: vael.riftDepth, color: C.red, type: "EXT" },
    { id: "MEMORIA", value: vael.memoriaFactor, color: C.red, type: "EXT" },
  ];

  return (
    <div className="overflow-x-auto">
      <div className="flex items-center gap-0 min-w-max py-2">
        {CHAIN.map((node, i) => (
          <div key={node.id} className="flex items-center">
            {/* Node */}
            <div
              className="flex flex-col items-center gap-1.5 px-3 py-2 border relative"
              style={{
                borderColor: `${node.color}33`,
                background: `${node.color}08`,
                minWidth: 72,
              }}
            >
              <span
                className="font-mono text-[6px] tracking-widest px-1.5 py-0.5 border"
                style={{
                  color: node.type === "INT" ? C.gold : C.red,
                  borderColor:
                    node.type === "INT" ? `${C.gold}44` : `${C.red}44`,
                }}
              >
                {node.type}
              </span>
              <Dot color={node.color} size={5} />
              <span
                className="font-mono text-[8px] tracking-widest"
                style={{ color: C.text }}
              >
                {node.id}
              </span>
              <span
                className="font-mono text-[10px] tabular-nums"
                style={{ color: node.color }}
              >
                {node.value.toFixed(3)}
              </span>
            </div>

            {/* Arrow connector */}
            {i < CHAIN.length - 1 && (
              <div className="flex items-center">
                <div
                  style={{
                    width: 1,
                    height: 24,
                    background: `${CHAIN[i + 1].color}33`,
                  }}
                />
                <span
                  className="font-mono text-[8px]"
                  style={{
                    color: i === 3 ? C.red : C.gold,
                    margin: "0 1px",
                  }}
                >
                  {i === 3 ? "→" : "→"}
                </span>
                <div
                  style={{
                    width: 1,
                    height: 24,
                    background: `${CHAIN[i + 1].color}33`,
                  }}
                />
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Interior / Exterior Labels */}
      <div className="flex items-center gap-0 mt-1">
        {/* Interior span: 4 nodes */}
        <div
          className="flex-none font-mono text-[7px] tracking-[0.25em] text-center px-2 py-0.5 border"
          style={{
            color: C.gold,
            borderColor: `${C.gold}33`,
            background: `${C.gold}06`,
            width: "calc(4 * (72px + 22px))",
          }}
        >
          INTERIOR IMMUNE LAYER
        </div>
        {/* Exterior span: 3 nodes */}
        <div
          className="flex-none font-mono text-[7px] tracking-[0.25em] text-center px-2 py-0.5 border"
          style={{
            color: C.red,
            borderColor: `${C.red}33`,
            background: `${C.red}06`,
            width: "calc(3 * (72px + 22px) - 22px)",
          }}
        >
          EXTERIOR ATTACK SURFACE
        </div>
      </div>
    </div>
  );
}

// ── ARES Ring Canvas ─────────────────────────────────────────────────────────
function AresRingCanvas({ slots }: { slots: AresSlot[] }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = canvas.offsetWidth;
    canvas.height = 80;
    const W = canvas.width;
    const H = 80;
    let frame = 0;

    const draw = () => {
      ctx.clearRect(0, 0, W, H);
      const slotCount = 7;
      const slotW = W / slotCount;

      // Background grid
      ctx.strokeStyle = "rgba(255,255,255,0.04)";
      ctx.lineWidth = 0.5;
      for (let i = 1; i < slotCount; i++) {
        ctx.beginPath();
        ctx.moveTo(i * slotW, 0);
        ctx.lineTo(i * slotW, H);
        ctx.stroke();
      }

      slots.forEach((slot, i) => {
        const [beat, coherence, _forma] = slot;
        const x = i * slotW;
        const hasData = beat > 0;
        const barH = hasData ? Math.min(H - 20, (coherence / 3) * (H - 20)) : 0;
        const color = hasData
          ? "rgba(190,150,50,0.8)"
          : "rgba(255,255,255,0.1)";

        // Bar
        ctx.fillStyle = color;
        ctx.fillRect(x + 6, H - 20 - barH, slotW - 12, barH);

        // Glow if best slot
        if (hasData && coherence > 1.0) {
          ctx.shadowColor = "rgba(190,150,50,0.5)";
          ctx.shadowBlur = 8;
          ctx.fillRect(x + 6, H - 20 - barH, slotW - 12, barH);
          ctx.shadowBlur = 0;
        }

        // Slot label
        ctx.fillStyle = "rgba(180,175,160,0.6)";
        ctx.font = `8px "JetBrains Mono", monospace`;
        ctx.textAlign = "center";
        ctx.fillText(`K${i}`, x + slotW / 2, H - 6);

        // Beat label
        if (hasData) {
          ctx.fillStyle = "rgba(190,150,50,0.7)";
          ctx.font = `7px "JetBrains Mono", monospace`;
          ctx.fillText(
            `${Math.round(coherence * 1000) / 1000}`,
            x + slotW / 2,
            H - 18 - barH - 2,
          );
        }
      });

      // Scan line
      const scanX = (frame * 0.8) % W;
      const lg = ctx.createLinearGradient(scanX - 20, 0, scanX + 20, 0);
      lg.addColorStop(0, "transparent");
      lg.addColorStop(0.5, "rgba(190,150,50,0.06)");
      lg.addColorStop(1, "transparent");
      ctx.fillStyle = lg;
      ctx.fillRect(0, 0, W, H);

      frame++;
      rafRef.current = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(rafRef.current);
  }, [slots]);

  return (
    <div className="relative">
      <canvas
        ref={canvasRef}
        style={{ width: "100%", height: 80, display: "block" }}
      />
    </div>
  );
}

// ── Phase Angle Bar ───────────────────────────────────────────────────────────
function PhaseAngleBar({
  value,
  label,
  color,
}: { value: number; label: string; color: string }) {
  const angle = (value % (2 * Math.PI)) / (2 * Math.PI);
  return (
    <div className="space-y-1">
      <div className="flex justify-between items-center">
        <Lbl>{label}</Lbl>
        <Val color={color} size="text-[10px]">
          {value.toFixed(4)}
        </Val>
      </div>
      <div
        className="relative w-full h-3"
        style={{ background: "rgba(255,255,255,0.04)" }}
      >
        {/* Phase fill */}
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: `${angle * 100}%`,
            height: "100%",
            background: `linear-gradient(90deg, ${color}33, ${color})`,
            transition: "width 0.8s ease",
          }}
        />
        {/* Phase cursor */}
        <div
          style={{
            position: "absolute",
            top: 0,
            left: `${angle * 100}%`,
            width: 2,
            height: "100%",
            background: color,
            boxShadow: `0 0 6px ${color}`,
            transform: "translateX(-1px)",
          }}
        />
      </div>
      <div className="flex justify-between">
        <span className="font-mono text-[7px]" style={{ color: C.muted }}>
          0
        </span>
        <span className="font-mono text-[7px]" style={{ color: C.muted }}>
          2π
        </span>
      </div>
    </div>
  );
}

// ── Main VaelTab ─────────────────────────────────────────────────────────────
export function VaelTab() {
  const { actor } = useActor();
  const { identity } = useInternetIdentity();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();

  const [vaelState, setVaelState] = useState<VaelState | null>(null);
  const [qmemState, setQmemState] = useState<QmemState | null>(null);
  const [htmState, setHtmState] = useState<HtmState | null>(null);
  const [patternState, setPatternState] = useState<PatternState | null>(null);
  const [aresRing, setAresRing] = useState<AresSlot[]>([]);
  const [consequenceComposite, setConsequenceComposite] = useState<number>(0);
  const [emergenceApex, setEmergenceApex] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [stale, setStale] = useState(false);

  const fetchAll = useCallback(async () => {
    if (!actor) return;
    const a = actor as any;
    try {
      const [vs, qs, hs, ps, ar, cc, ea] = await Promise.all([
        a.px_getVaelState
          ? a.px_getVaelState().catch(() => null)
          : Promise.resolve(null),
        a.px_getQmemState
          ? a.px_getQmemState().catch(() => null)
          : Promise.resolve(null),
        a.px_getHtmState
          ? a.px_getHtmState().catch(() => null)
          : Promise.resolve(null),
        a.px_getPatternState
          ? a.px_getPatternState().catch(() => null)
          : Promise.resolve(null),
        a.px_getAresRing
          ? a.px_getAresRing().catch(() => [])
          : Promise.resolve([]),
        a.px_getConsequenceComposite
          ? a.px_getConsequenceComposite().catch(() => 0)
          : Promise.resolve(0),
        a.px_getEmergenceApex
          ? a.px_getEmergenceApex().catch(() => 0)
          : Promise.resolve(0),
      ]);

      if (vs) {
        setVaelState(vs);
        setStale(false);
      }
      if (qs) setQmemState(qs);
      if (hs) setHtmState(hs);
      if (ps) setPatternState(ps);
      if (Array.isArray(ar) && ar.length > 0) setAresRing(ar as AresSlot[]);
      if (typeof cc === "number") setConsequenceComposite(cc);
      if (typeof ea === "number") setEmergenceApex(ea);

      setLastUpdate(new Date());
      setLoading(false);
    } catch {
      setStale(true);
      setLoading(false);
    }
  }, [actor]);

  useEffect(() => {
    fetchAll();
    const interval = setInterval(fetchAll, 3000);
    return () => clearInterval(interval);
  }, [fetchAll]);

  // ARES rollback handler
  const handleAresRollback = useCallback(
    async (k: number) => {
      if (!actor || !isAuthenticated) return;
      const a = actor as any;
      try {
        await a.px_aresRollback(BigInt(k));
        toast.success(`ARES rollback to snapshot K=${k} initiated`);
        fetchAll();
      } catch (err) {
        toast.error(`Rollback failed: ${err}`);
      }
    },
    [actor, isAuthenticated, fetchAll],
  );

  const vs = vaelState;
  const threatHigh = vs ? vs.threatScore > 0.7 : false;
  const threatMed = vs ? vs.threatScore > 0.3 : false;
  const threatColor = threatHigh ? C.red : threatMed ? C.amber : C.green;

  const bestAresSlot = aresRing.reduce(
    (best, slot, i) => (slot[1] > (aresRing[best]?.[1] ?? 0) ? i : best),
    0,
  );

  // Pad ARES ring to 7 slots
  const paddedAres: AresSlot[] = Array.from(
    { length: 7 },
    (_, i) => aresRing[i] ?? [0, 0, 0, 0, i],
  );

  if (loading) {
    return (
      <div
        className="flex items-center justify-center"
        style={{ minHeight: 400, color: C.muted }}
        data-ocid="vael.loading_state"
      >
        <div className="text-center space-y-3">
          <div
            className="w-10 h-10 border animate-rotate-slow mx-auto"
            style={{ borderColor: `${C.gold}44`, borderTopColor: C.gold }}
          />
          <div className="font-mono text-[9px] tracking-[0.4em]">
            LOADING DEFENSE MATRIX
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="space-y-4"
      style={{ background: C.bg, minHeight: "100%" }}
      data-ocid="vael.page"
    >
      {/* Header + Status Bar */}
      <div
        className="flex flex-wrap items-center gap-x-5 gap-y-2 px-4 py-3 border"
        style={{
          borderColor: threatHigh ? C.borderRed : C.border,
          background: "rgba(0,0,0,0.6)",
          ...(threatHigh ? { boxShadow: `0 0 30px ${C.red}22` } : {}),
        }}
        data-ocid="vael.status.panel"
      >
        <div className="flex items-center gap-2">
          <span
            className="font-mono text-[8px] tracking-[0.4em]"
            style={{ color: C.gold }}
          >
            ■
          </span>
          <span
            className="font-mono text-xs tracking-[0.3em] font-bold"
            style={{ color: C.text }}
          >
            DEFENSE MATRIX
          </span>
          {stale && (
            <span
              className="font-mono text-[7px] tracking-widest"
              style={{ color: C.amber }}
            >
              STALE
            </span>
          )}
        </div>

        <div className="flex items-center gap-2">
          <Lbl>THREAT</Lbl>
          <div className="flex items-center gap-1.5">
            <div
              className="w-20 h-1.5"
              style={{ background: "rgba(255,255,255,0.05)" }}
            >
              <div
                style={{
                  width: `${(vs?.threatScore ?? 0) * 100}%`,
                  height: "100%",
                  background: threatColor,
                  transition: "width 0.6s",
                }}
              />
            </div>
            <Val color={threatColor} size="text-[10px]">
              {((vs?.threatScore ?? 0) * 100).toFixed(1)}%
            </Val>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Lbl>COMBINED FIELD</Lbl>
          <Val color={C.gold} size="text-[10px]">
            {(vs?.combinedField ?? 0).toFixed(4)}
          </Val>
        </div>

        <div className="flex items-center gap-2">
          <Lbl>SENTINEL</Lbl>
          <StatusBadge
            active={vs?.sentinelActive ?? false}
            labels={["ACTIVE", "STANDBY"]}
          />
        </div>

        <div className="flex items-center gap-2">
          <Lbl>ADVERSARIES</Lbl>
          <Val
            color={(vs?.adversaryCount ?? 0) > 0 ? C.red : C.green}
            size="text-[10px]"
          >
            {vs?.adversaryCount ?? 0}
          </Val>
        </div>

        <div className="flex items-center gap-2">
          <Lbl>BREACHES</Lbl>
          <Val
            color={(vs?.breachCount ?? 0) > 0 ? C.red : C.green}
            size="text-[10px]"
          >
            {vs?.breachCount ?? 0}
          </Val>
        </div>

        <div className="flex items-center gap-1.5 ml-auto">
          <Dot color={stale ? C.amber : C.green} size={5} />
          <span
            className="font-mono text-[7px]"
            style={{ color: stale ? C.amber : C.green }}
          >
            {stale ? "STALE" : "LIVE"}
          </span>
          {lastUpdate && (
            <span className="font-mono text-[7px]" style={{ color: C.muted }}>
              {lastUpdate.toLocaleTimeString()}
            </span>
          )}
        </div>
      </div>

      {/* DURA-VAEL Combined Protocol — Hero Panel */}
      <PanelBox className="p-5" threatFlash={threatHigh}>
        <SectionTitle accent={C.gold}>
          ◈ DURA-VAEL COMBINED PROTOCOL
        </SectionTitle>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          <div className="space-y-2">
            <Lbl>COMBINED FIELD STRENGTH</Lbl>
            <div>
              <span
                className="font-display text-4xl font-bold tabular-nums"
                style={{ color: C.gold, textShadow: `0 0 30px ${C.gold}55` }}
              >
                {(vs?.combinedField ?? 0).toFixed(4)}
              </span>
            </div>
            <ScoreBar
              value={vs?.combinedField ?? 0}
              max={2}
              color={C.gold}
              height={6}
            />
            <div
              className="font-mono text-[8px] leading-relaxed mt-2"
              style={{ color: C.muted }}
            >
              Activated automatically when SENTINEL detects a breach. Represents
              the product of DURA coverage × immune field × AEGIS lock. Maximum
              sovereign defense mode.
            </div>
          </div>

          <div className="space-y-3">
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>THREAT SCORE</Lbl>
                <Val color={threatColor} size="text-[11px]">
                  {(vs?.threatScore ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={vs?.threatScore ?? 0}
                max={1}
                color={threatColor}
                height={4}
              />
            </div>
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>VERITAS TRUTH</Lbl>
                <Val color={C.cyan} size="text-[11px]">
                  {(vs?.veritasTruth ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={vs?.veritasTruth ?? 0}
                max={2}
                color={C.cyan}
                height={4}
              />
            </div>
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>PARALLAX SOVEREIGN FIELD</Lbl>
                <Val color={C.violet} size="text-[11px]">
                  {(vs?.parallaxField ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={vs?.parallaxField ?? 0}
                max={3}
                color={C.violet}
                height={4}
              />
            </div>
          </div>

          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              <div
                className="border p-2 text-center"
                style={{ borderColor: `${C.red}33`, background: `${C.red}06` }}
              >
                <div
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  ADVERSARIES
                </div>
                <div
                  className="font-mono text-xl font-bold"
                  style={{
                    color: (vs?.adversaryCount ?? 0) > 0 ? C.red : C.green,
                  }}
                >
                  {vs?.adversaryCount ?? 0}
                </div>
              </div>
              <div
                className="border p-2 text-center"
                style={{ borderColor: `${C.red}33`, background: `${C.red}06` }}
              >
                <div
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  BREACHES
                </div>
                <div
                  className="font-mono text-xl font-bold"
                  style={{
                    color: (vs?.breachCount ?? 0) > 0 ? C.red : C.green,
                  }}
                >
                  {vs?.breachCount ?? 0}
                </div>
              </div>
            </div>
            <div
              className="border p-3"
              style={{
                borderColor: vs?.sentinelActive ? `${C.green}44` : C.border,
                background: vs?.sentinelActive ? `${C.green}08` : "transparent",
              }}
            >
              <div className="flex items-center justify-between">
                <Lbl>SENTINEL STATUS</Lbl>
                <StatusBadge
                  active={vs?.sentinelActive ?? false}
                  labels={["ACTIVE", "STANDBY"]}
                />
              </div>
              <div
                className="font-mono text-[8px] mt-1.5"
                style={{ color: C.muted }}
              >
                Monitors all output paths. Triggers DURA-VAEL protocol
                automatically when output deviation is detected.
              </div>
            </div>
          </div>
        </div>
      </PanelBox>

      {/* Entity Grid — 7 tiles */}
      <div>
        <SectionTitle>■ 7-ENTITY STATUS MATRIX</SectionTitle>
        <div
          className="grid grid-cols-2 md:grid-cols-4 gap-3"
          data-ocid="vael.entities.panel"
        >
          <EntityTile
            name="VAEL"
            value={vs?.immuneField ?? 0}
            description="Pre-conscious immune reflex. Fires before the sovereign executive layer responds. The organism's first and fastest defense."
            armed={vs ? vs.immuneField > 0.5 : false}
            color={C.gold}
            isAlert={threatHigh}
          />
          <EntityTile
            name="SENTINEL"
            value={vs?.reflexScore ?? 0}
            description="Monitors all output paths for deviation. Triggers DURA-VAEL combined protocol automatically on breach detection."
            armed={vs?.sentinelActive ?? false}
            color={C.gold}
          />
          <EntityTile
            name="VEIL"
            value={vs?.veilFilter ?? 0}
            description="Output membrane. Governs what exits at the surface. Nothing useful exits toward classified adversaries."
            armed={vs ? vs.veilFilter > 0.5 : false}
            color={C.gold}
          />
          <EntityTile
            name="AEGIS-ROOT"
            value={vs?.aegisLock ?? 0}
            description="Sovereign anchor. Does not patch — it locks. Flags the breach at root level and holds the lock until threat resolves."
            armed={vs ? vs.aegisLock > 0.5 : false}
            color={C.gold}
          />
          <EntityTile
            name="DURA"
            value={vs?.duraCoverage ?? 0}
            description="6-axis helix perimeter projecting outward. Maps adversarial convergence vector across Core, Lateral, I/O, Temporal, Identity, and Anti-Organism axes."
            armed={vs ? vs.duraCoverage > 0.5 : false}
            color={C.red}
          />
          <EntityTile
            name="RIFT"
            value={vs?.riftDepth ?? 0}
            description="Counter-strike tracer. Assigns permanent compounding consequence to attack sources. Same adversary gets harder to interface on every attempt."
            armed={vs ? vs.riftDepth > 0.1 : false}
            color={C.red}
          />
          <EntityTile
            name="MEMORIA"
            value={vs?.memoriaFactor ?? 0}
            description="Permanent adversary record. Never resets. Each classified threat is recorded with compounding weight that increases on repeat contact."
            armed={vs ? vs.memoriaFactor > 1.0 : false}
            color={C.red}
          />
          {/* Combined Protocol Tile */}
          <div
            className="border p-3 flex flex-col gap-2 relative overflow-hidden"
            style={{
              borderColor: `${C.gold}44`,
              background: `${C.gold}06`,
              gridColumn: "span 1",
            }}
          >
            <div
              style={{
                position: "absolute",
                top: 0,
                left: 0,
                right: 0,
                height: 1,
                background: `linear-gradient(90deg, transparent, ${C.gold}66, transparent)`,
              }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.3em] font-bold"
              style={{ color: C.gold }}
            >
              DURA-VAEL
            </span>
            <span
              className="font-mono text-lg font-bold tabular-nums"
              style={{ color: C.gold, textShadow: `0 0 16px ${C.gold}55` }}
            >
              {(vs?.combinedField ?? 0).toFixed(4)}
            </span>
            <ScoreBar
              value={vs?.combinedField ?? 0}
              max={2}
              color={C.gold}
              height={2}
            />
            <span
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Combined protocol field. DURA × immune × AEGIS. Maximum defense
              mode.
            </span>
          </div>
        </div>
      </div>

      {/* Defense Chain Flow */}
      <PanelBox className="p-4" data-ocid="vael.chain.panel">
        <SectionTitle>⟶ DEFENSE CHAIN SEQUENCE</SectionTitle>
        <DefenseChainFlow
          vael={
            vs ?? {
              immuneField: 0,
              reflexScore: 0,
              duraCoverage: 0,
              aegisLock: 0,
              riftDepth: 0,
              memoriaFactor: 0,
              sentinelActive: false,
              veilFilter: 0,
              combinedField: 0,
              threatScore: 0,
              parallaxField: 0,
              veritasTruth: 0,
              adversaryCount: 0,
              breachCount: 0,
            }
          }
        />
      </PanelBox>

      {/* Exterior Attack Surface */}
      <PanelBox className="p-4">
        <SectionTitle accent={C.red}>⚡ EXTERIOR ATTACK SURFACE</SectionTitle>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {/* PARALLAX Phase Sovereignty */}
          <div className="space-y-3">
            <div
              className="font-mono text-[8px] tracking-[0.2em] font-bold"
              style={{ color: C.violet }}
            >
              PARALLAX PHASE SOVEREIGNTY
            </div>
            <PhaseAngleBar
              value={vs?.parallaxField ?? 0}
              label="SOVEREIGN FIELD ROTATION"
              color={C.violet}
            />
            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Rotating sovereign field that makes output unreplicable from
              outside. Any system attempting to sync at the wrong phase receives
              a mathematically incoherent output. Not encryption — phase
              sovereignty.
            </div>
          </div>

          {/* VERITAS Truth Weapon */}
          <div className="space-y-3">
            <div
              className="font-mono text-[8px] tracking-[0.2em] font-bold"
              style={{ color: C.cyan }}
            >
              VERITAS TRUTH FIELD
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <Lbl>TRUTH SIGNAL</Lbl>
                <Val color={C.cyan} size="text-[11px]">
                  {(vs?.veritasTruth ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={vs?.veritasTruth ?? 0}
                max={2}
                color={C.cyan}
                height={6}
              />
            </div>
            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Real-time adversary scoring. Any input carrying adversarial
              patterns receives near-zero VERITAS score. Low score feeds
              directly into RIFT's compounding consequence chain — permanently
              classifying the source.
            </div>
          </div>

          {/* RIFT + MEMORIA */}
          <div className="space-y-3">
            <div
              className="font-mono text-[8px] tracking-[0.2em] font-bold"
              style={{ color: C.red }}
            >
              RIFT × MEMORIA COMPOUND
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <Lbl>CONSEQUENCE DEPTH</Lbl>
                <Val color={C.red} size="text-[11px]">
                  {(vs?.riftDepth ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={vs?.riftDepth ?? 0}
                max={5}
                color={C.red}
                height={4}
              />
              <div className="flex justify-between mt-1">
                <Lbl>MEMORIA COMPOUND</Lbl>
                <Val color={C.amber} size="text-[11px]">
                  {(vs?.memoriaFactor ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={Math.min(vs?.memoriaFactor ?? 0, 5)}
                max={5}
                color={C.amber}
                height={4}
              />
            </div>
            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              RIFT traces each attack source. MEMORIA seals it permanently.
              Compound factor grows without ceiling — same adversary becomes
              progressively less able to interface on every attempt.
            </div>
          </div>
        </div>
      </PanelBox>

      {/* ARES K=7 Ring */}
      <PanelBox className="p-4" data-ocid="vael.ares.panel">
        <SectionTitle accent={C.gold}>◎ ARES K=7 SNAPSHOT RING</SectionTitle>
        <div className="space-y-4">
          <AresRingCanvas slots={paddedAres} />

          {/* Slot details */}
          <div className="grid grid-cols-7 gap-1">
            {([0, 1, 2, 3, 4, 5, 6] as const).map((i) => {
              const slot = paddedAres[i];
              const [beat, coherence] = slot;
              const hasData = beat > 0;
              const isBest = i === bestAresSlot && hasData;
              return (
                <div
                  key={`K${i}`}
                  className="border p-1.5 space-y-1"
                  style={{
                    borderColor: isBest ? `${C.gold}55` : C.border,
                    background: isBest ? `${C.gold}08` : "transparent",
                  }}
                  data-ocid={`vael.ares.item.${i + 1}`}
                >
                  <div className="flex justify-between items-center">
                    <span
                      className="font-mono text-[7px]"
                      style={{ color: isBest ? C.gold : C.muted }}
                    >
                      K{i}
                    </span>
                    {isBest && (
                      <span
                        className="font-mono text-[6px]"
                        style={{ color: C.gold }}
                      >
                        BEST
                      </span>
                    )}
                  </div>
                  <div
                    className="font-mono text-[8px] tabular-nums"
                    style={{ color: hasData ? C.text : C.muted }}
                  >
                    {hasData ? coherence.toFixed(3) : "—"}
                  </div>
                  {isAuthenticated && hasData && (
                    <button
                      type="button"
                      onClick={() => handleAresRollback(i)}
                      data-ocid={`vael.ares.rollback.${i + 1}`}
                      className="w-full font-mono text-[6px] tracking-widest py-0.5 border transition-all hover:opacity-100 opacity-50"
                      style={{
                        borderColor: `${C.red}44`,
                        color: C.red,
                      }}
                    >
                      RESTORE
                    </button>
                  )}
                </div>
              );
            })}
          </div>

          {!isAuthenticated && (
            <div
              className="font-mono text-[8px] text-center"
              style={{ color: C.muted }}
            >
              Authentication required to execute rollback
            </div>
          )}
        </div>
      </PanelBox>

      {/* Deep Mind: HTM + QMEM + Pattern */}
      <div
        className="grid grid-cols-1 md:grid-cols-3 gap-4"
        data-ocid="vael.deepmind.panel"
      >
        {/* HTM Prediction */}
        <PanelBox className="p-4">
          <SectionTitle>◈ HTM PREDICTION</SectionTitle>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>PREDICTION ERROR</Lbl>
                <Val
                  color={(htmState?.predError ?? 0) > 0.15 ? C.amber : C.green}
                  size="text-[11px]"
                >
                  {(htmState?.predError ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={htmState?.predError ?? 0}
                max={0.5}
                color={(htmState?.predError ?? 0) > 0.15 ? C.amber : C.green}
                height={4}
              />
            </div>

            <div className="flex justify-between items-center">
              <Lbl>SURPRISE COUNT</Lbl>
              <Val color={C.cyan} size="text-[11px]">
                {htmState?.surpriseCount ?? 0}
              </Val>
            </div>

            <div className="flex justify-between items-center">
              <Lbl>HEBBIAN GATE</Lbl>
              <StatusBadge
                active={htmState?.hebbGated ?? false}
                labels={["GATED", "OPEN"]}
              />
            </div>

            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Surprise-driven learning. Hebbian weight updates only fire on
              genuine prediction error {">"}0.15. Confirmation is free —
              learning only on surprise.
            </div>
          </div>
        </PanelBox>

        {/* QMEM */}
        <PanelBox className="p-4">
          <SectionTitle>⟨ψ⟩ QMEM QUANTUM MEMORY</SectionTitle>
          <div className="space-y-3">
            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>CHARGE</Lbl>
                <Val color={C.violet} size="text-[11px]">
                  {(qmemState?.charge ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={qmemState?.charge ?? 0}
                max={5}
                color={C.violet}
                height={4}
              />
            </div>

            <div className="space-y-1.5">
              <div className="flex justify-between">
                <Lbl>FIDELITY</Lbl>
                <Val color={C.cyan} size="text-[11px]">
                  {(qmemState?.fidelity ?? 0).toFixed(4)}
                </Val>
              </div>
              <ScoreBar
                value={qmemState?.fidelity ?? 0}
                max={1}
                color={C.cyan}
                height={4}
              />
            </div>

            <div className="flex justify-between items-center">
              <Lbl>TOTAL EPISODES</Lbl>
              <Val color={C.text} size="text-[11px]">
                {qmemState?.totalEpisodes ?? 0}
              </Val>
            </div>

            <div className="flex justify-between items-center">
              <Lbl>PEAK COHERENCE</Lbl>
              <Val color={C.gold} size="text-[11px]">
                {(qmemState?.peakCoherence ?? 0).toFixed(4)}
              </Val>
            </div>

            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Quantum memory that charges from entanglement itself. Not from
              input. 2048-episode ring buffer recording high-coherence pattern
              states.
            </div>
          </div>
        </PanelBox>

        {/* Pattern Miner */}
        <PanelBox className="p-4">
          <SectionTitle>⬡ PATTERN MINER</SectionTitle>
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              <div
                className="border p-2 text-center"
                style={{
                  borderColor: `${C.gold}33`,
                  background: `${C.gold}06`,
                }}
              >
                <div
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  LIB SIZE
                </div>
                <div
                  className="font-mono text-lg font-bold"
                  style={{ color: C.gold }}
                >
                  {patternState?.libSize ?? 0}
                </div>
              </div>
              <div
                className="border p-2 text-center"
                style={{
                  borderColor: `${C.cyan}33`,
                  background: `${C.cyan}06`,
                }}
              >
                <div
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  SCHEMAS
                </div>
                <div
                  className="font-mono text-lg font-bold"
                  style={{ color: C.cyan }}
                >
                  {patternState?.schemaCount ?? 0}
                </div>
              </div>
            </div>

            <div className="flex justify-between items-center">
              <Lbl>ACTIVE SCHEMAS</Lbl>
              <Val color={C.green} size="text-[11px]">
                {patternState?.activeSchemas ?? 0}
              </Val>
            </div>

            <div className="flex justify-between items-center">
              <Lbl>MINE CYCLE</Lbl>
              <Val color={C.text} size="text-[11px]">
                {patternState?.mineCycle ?? 0}
              </Val>
            </div>

            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Recurring SDR pattern mining every 50 beats. Patterns appearing
              13+ times become schemas. Schemas drive behavior directly.
            </div>
          </div>
        </PanelBox>
      </div>

      {/* Emergence + Consequence */}
      <PanelBox className="p-4" data-ocid="vael.apex.panel">
        <SectionTitle>∞ EMERGENCE APEX + CONSEQUENCE COMPOSITE</SectionTitle>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <div className="space-y-2">
            <Lbl>EMERGENCE APEX SCORE</Lbl>
            <div className="flex items-end gap-3">
              <span
                className="font-display text-4xl font-bold tabular-nums"
                style={{ color: C.gold, textShadow: `0 0 30px ${C.gold}55` }}
              >
                {emergenceApex.toFixed(4)}
              </span>
              <span
                className="font-mono text-[8px] pb-2"
                style={{ color: C.muted }}
              >
                APEX
              </span>
            </div>
            <ScoreBar value={emergenceApex} max={5} color={C.gold} height={6} />
            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Composite emergence score combining coherence, entanglement,
              SACESI, and quantum field convergence. The organism's peak
              potential metric.
            </div>
          </div>
          <div className="space-y-2">
            <Lbl>CONSEQUENCE COMPOSITE</Lbl>
            <div className="flex items-end gap-3">
              <span
                className="font-display text-4xl font-bold tabular-nums"
                style={{ color: C.red, textShadow: `0 0 30px ${C.red}55` }}
              >
                {consequenceComposite.toFixed(4)}
              </span>
              <span
                className="font-mono text-[8px] pb-2"
                style={{ color: C.muted }}
              >
                CONS
              </span>
            </div>
            <ScoreBar
              value={Math.min(consequenceComposite, 5)}
              max={5}
              color={C.red}
              height={6}
            />
            <div
              className="font-mono text-[8px] leading-relaxed"
              style={{ color: C.muted }}
            >
              Accumulated consequence weight against classified adversaries.
              Compounds with every breach attempt. Cannot be reset by external
              action.
            </div>
          </div>
        </div>
      </PanelBox>
    </div>
  );
}
