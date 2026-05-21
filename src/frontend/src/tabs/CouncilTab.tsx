import { ScrollArea } from "@/components/ui/scroll-area";
// @ts-nocheck
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { useActor } from "../hooks/useActor";
import { useIntelligenceEngine } from "../hooks/useIntelligenceEngine";

// ── Agent Color Palette ───────────────────────────────────────────────────────
const AGENT_COLORS = {
  NEXUS: {
    primary: "oklch(0.65 0.20 290)",
    dim: "oklch(0.65 0.20 290 / 0.15)",
    border: "oklch(0.65 0.20 290 / 0.3)",
    badge: "oklch(0.65 0.20 290 / 0.2)",
    text: "oklch(0.75 0.18 290)",
  },
  COGNUS: {
    primary: "oklch(0.65 0.20 260)",
    dim: "oklch(0.65 0.20 260 / 0.15)",
    border: "oklch(0.65 0.20 260 / 0.3)",
    badge: "oklch(0.65 0.20 260 / 0.2)",
    text: "oklch(0.75 0.18 260)",
  },
  AURUM: {
    primary: "oklch(0.78 0.15 85)",
    dim: "oklch(0.78 0.15 85 / 0.15)",
    border: "oklch(0.78 0.15 85 / 0.3)",
    badge: "oklch(0.78 0.15 85 / 0.2)",
    text: "oklch(0.82 0.14 85)",
  },
  LEXIS: {
    primary: "oklch(0.72 0.16 80)",
    dim: "oklch(0.72 0.16 80 / 0.15)",
    border: "oklch(0.72 0.16 80 / 0.3)",
    badge: "oklch(0.72 0.16 80 / 0.2)",
    text: "oklch(0.80 0.14 80)",
  },
  SOLUS: {
    primary: "oklch(0.55 0.22 25)",
    dim: "oklch(0.55 0.22 25 / 0.15)",
    border: "oklch(0.55 0.22 25 / 0.3)",
    badge: "oklch(0.55 0.22 25 / 0.2)",
    text: "oklch(0.70 0.18 25)",
  },
  VERITAS: {
    primary: "oklch(0.60 0.22 30)",
    dim: "oklch(0.60 0.22 30 / 0.15)",
    border: "oklch(0.60 0.22 30 / 0.3)",
    badge: "oklch(0.60 0.22 30 / 0.2)",
    text: "oklch(0.72 0.18 30)",
  },
};

// ── Report Parser ─────────────────────────────────────────────────────────────
// Parses format: "B=1440 C=1.234 SA=0.567 CSC=0.89 [FINDING TEXT]"
function parseReport(raw: string): {
  beat: number | null;
  metrics: Array<{ key: string; value: string }>;
  finding: string | null;
  raw: string;
} {
  if (!raw || typeof raw !== "string") {
    return { beat: null, metrics: [], finding: null, raw: "" };
  }

  const result = {
    beat: null as number | null,
    metrics: [] as Array<{ key: string; value: string }>,
    finding: null as string | null,
    raw,
  };

  // Extract bracketed finding
  const bracketMatch = raw.match(/\[([^\]]+)\]/);
  if (bracketMatch) {
    result.finding = bracketMatch[1].trim();
  }

  // Extract all key=value pairs (before brackets)
  const withoutBrackets = raw.replace(/\[[^\]]*\]/g, "").trim();
  const kvPairs = withoutBrackets.match(/([A-Z_][A-Z0-9_]*)=([^\s]+)/g) ?? [];

  const labelMap: Record<string, string> = {
    B: "BEAT",
    C: "COHERENCE",
    SA: "SACESI",
    CSC: "CONSISTENCY",
    F: "FEAR",
    CR: "COURAGE",
    GS: "GROUNDED",
    MS: "MISSION",
    ID: "IDENTITY",
    DW: "DRAWDOWN",
    PY: "PEAK_YIELD",
    MV: "MINT_VEL",
    FL: "FEAR_LVL",
    ML: "MISSION_LK",
    CM: "COH_MEAN",
    SC: "SHARK_COR",
    FC: "FEAR_COR",
    AF: "ANOMALY_FLG",
    MP: "MISSION_PS",
    CP: "COH_PEAK",
    PC: "PATENT_CT",
    SP: "SACESI_PK",
    IS: "ID_SCORE",
    ID_DELTA: "ID_DELTA",
    MM: "MISMATCH",
    CV: "COH_VALID",
    KV: "KURT_VALID",
    TS: "TRUST",
  };

  for (const pair of kvPairs) {
    const eqIdx = pair.indexOf("=");
    const k = pair.slice(0, eqIdx);
    const v = pair.slice(eqIdx + 1);
    const label = labelMap[k] ?? k;
    if (k === "B") {
      result.beat = Number.parseInt(v, 10) || null;
    }
    result.metrics.push({ key: label, value: v });
  }

  return result;
}

// ── Feed Entry ────────────────────────────────────────────────────────────────
interface FeedEntry {
  id: string;
  timestamp: number;
  beat: number | null;
  metrics: Array<{ key: string; value: string }>;
  finding: string | null;
  raw: string;
}

function buildFeedEntry(raw: string): FeedEntry {
  const parsed = parseReport(raw);
  return {
    id: `${Date.now()}-${Math.random()}`,
    timestamp: Date.now(),
    ...parsed,
  };
}

// ── Feed Entry Card ───────────────────────────────────────────────────────────
function FeedEntryCard({
  entry,
  agentColor,
  index,
}: { entry: FeedEntry; agentColor: typeof AGENT_COLORS.NEXUS; index: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
      className="border-b"
      style={{ borderColor: "oklch(0.18 0.01 240)" }}
      data-ocid={`council.item.${index + 1}`}
    >
      <div className="px-3 py-2.5">
        {/* Header row: beat + timestamp */}
        <div className="flex items-center justify-between mb-1.5">
          <div className="flex items-center gap-2">
            {entry.beat !== null && (
              <span
                className="font-mono text-[8px] tracking-[0.25em] px-1.5 py-0.5"
                style={{
                  background: agentColor.badge,
                  color: agentColor.text,
                  border: `1px solid ${agentColor.border}`,
                }}
              >
                B·{entry.beat.toLocaleString()}
              </span>
            )}
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.35 0.01 240)" }}
            >
              {new Date(entry.timestamp).toLocaleTimeString([], {
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
                hour12: false,
              })}
            </span>
          </div>
          <span
            className="font-mono text-[7px] tracking-[0.3em] px-1 py-0.5"
            style={{
              background: "oklch(0.12 0.01 240)",
              color: "oklch(0.45 0.01 240)",
            }}
          >
            SACESI·STAMPED
          </span>
        </div>

        {/* Metrics grid */}
        {entry.metrics.length > 0 && (
          <div className="grid grid-cols-3 gap-x-4 mb-2">
            {entry.metrics.slice(0, 9).map((m) => (
              <div key={m.key} className="flex justify-between items-center">
                <span
                  className="font-mono text-[8px]"
                  style={{ color: "oklch(0.40 0.01 240)" }}
                >
                  {m.key}
                </span>
                <span
                  className="font-mono text-[9px]"
                  style={{ color: agentColor.text }}
                >
                  {m.value}
                </span>
              </div>
            ))}
          </div>
        )}

        {/* Finding highlight */}
        {entry.finding && (
          <div
            className="px-2 py-1.5 mt-1"
            style={{
              background: agentColor.dim,
              borderLeft: `2px solid ${agentColor.primary}`,
            }}
          >
            <span
              className="font-mono text-[10px] leading-relaxed"
              style={{ color: agentColor.text }}
            >
              ▸ {entry.finding}
            </span>
          </div>
        )}

        {/* Fallback: show raw string if no structured data */}
        {!entry.finding && entry.metrics.length === 0 && entry.raw && (
          <div
            className="px-2 py-1.5 mt-1"
            style={{
              background: "oklch(0.10 0.01 240)",
              borderLeft: "1px solid oklch(0.20 0.01 240)",
            }}
          >
            <span
              className="font-mono text-[9px] leading-relaxed"
              style={{ color: "oklch(0.45 0.01 240)" }}
            >
              {entry.raw.slice(0, 200)}
            </span>
          </div>
        )}
      </div>
    </motion.div>
  );
}

// ── Agent Panel ───────────────────────────────────────────────────────────────
interface AgentConfig {
  id: string;
  name: string;
  role: string;
  pollFn: string;
  metrics: Array<{
    label: string;
    field: string;
    format?: (v: unknown) => string;
  }>;
  categoryBadge: string;
}

const AGENTS: AgentConfig[] = [
  {
    id: "NEXUS",
    name: "NEXUS",
    role: "SIGNAL CORRELATION ENGINE — Detects coupling events across organism state",
    pollFn: "px_getNexusReport",
    metrics: [
      {
        label: "SHARK COR",
        field: "sharkCorrelation",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "FEAR COR",
        field: "fearCorrelation",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "COH MEAN",
        field: "coherenceMean",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "HYPOTHESES",
        field: "hypothesisCount",
        format: (v) => (typeof v === "number" ? String(v) : "—"),
      },
    ],
    categoryBadge: "RESEARCH·DIRECTOR",
  },
  {
    id: "COGNUS",
    name: "COGNUS",
    role: "ROLLING ANALYTICS — Computes momentum and anomaly flags on 100-beat windows",
    pollFn: "px_getCognusReport",
    metrics: [
      {
        label: "COH MOM",
        field: "coherenceMomentum",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "ANOMALY CT",
        field: "anomalyCount",
        format: (v) => (typeof v === "number" ? String(v) : "—"),
      },
      {
        label: "MISSION PS",
        field: "missionPersistence",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "WINDOW",
        field: "windowSize",
        format: (v) => (typeof v === "number" ? `${v}B` : "100B"),
      },
    ],
    categoryBadge: "ANALYTICS·ENGINE",
  },
  {
    id: "AURUM",
    name: "AURUM",
    role: "TREASURY INTELLIGENCE — Yield trend, drawdown, and fear-suppression analysis",
    pollFn: "px_getAurumReport",
    metrics: [
      {
        label: "DRAWDOWN",
        field: "drawdown",
        format: (v) =>
          typeof v === "number" ? `${(v * 100).toFixed(2)}%` : "—",
      },
      {
        label: "PEAK YIELD",
        field: "peakYield",
        format: (v) => (typeof v === "number" ? v.toFixed(6) : "—"),
      },
      {
        label: "MINT VEL",
        field: "mintVelocity",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "FEAR LVL",
        field: "fearLevel",
        format: (v) =>
          typeof v === "number" ? `${(v * 100).toFixed(1)}%` : "—",
      },
    ],
    categoryBadge: "TREASURY·INTEL",
  },
  {
    id: "LEXIS",
    name: "LEXIS",
    role: "SOVEREIGN DOCUMENTATION — Auto-generates patent claims at coherence peaks",
    pollFn: "px_getLexisReport",
    metrics: [
      {
        label: "PATENT CT",
        field: "patentCount",
        format: (v) => (typeof v === "number" ? String(v) : "—"),
      },
      {
        label: "COH PEAK",
        field: "coherencePeak",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "SACESI PK",
        field: "sacesiAtPeak",
        format: (v) => (typeof v === "number" ? v.toFixed(6) : "—"),
      },
      {
        label: "FILED AT",
        field: "lastFileBeat",
        format: (v) => (typeof v === "number" ? `B·${v}` : "—"),
      },
    ],
    categoryBadge: "DOCUMENTATION·ENGINE",
  },
  {
    id: "SOLUS",
    name: "SOLUS",
    role: "IDENTITY INTEGRITY — Tracks doctrine deviation and sovereignty drift",
    pollFn: "px_getSolusReport",
    metrics: [
      {
        label: "ID SCORE",
        field: "identityScore",
        format: (v) => (typeof v === "number" ? v.toFixed(4) : "—"),
      },
      {
        label: "ID DELTA",
        field: "identityDelta",
        format: (v) =>
          typeof v === "number"
            ? v >= 0
              ? `+${v.toFixed(5)}`
              : v.toFixed(5)
            : "—",
      },
      {
        label: "GROUNDED",
        field: "groundedScore",
        format: (v) =>
          typeof v === "number" ? `${(v * 100).toFixed(1)}%` : "—",
      },
      {
        label: "MISSION LK",
        field: "missionLock",
        format: (v) => (v === true ? "LOCKED" : v === false ? "OPEN" : "—"),
      },
    ],
    categoryBadge: "SOVEREIGN·IDENTITY",
  },
  {
    id: "VERITAS",
    name: "VERITAS",
    role: "SIGNAL VALIDATION — Cross-references all signals against SACESI chain for consistency",
    pollFn: "px_getVeritasReport",
    metrics: [
      {
        label: "TRUST",
        field: "trustScore",
        format: (v) =>
          typeof v === "number" ? `${(v * 100).toFixed(2)}%` : "—",
      },
      {
        label: "MISMATCHES",
        field: "mismatchCount",
        format: (v) => (typeof v === "number" ? String(v) : "—"),
      },
      {
        label: "COH VALID",
        field: "coherenceValid",
        format: (v) => (v === true ? "✓" : v === false ? "✗" : "—"),
      },
      {
        label: "KURT VALID",
        field: "kuramotoValid",
        format: (v) => (v === true ? "✓" : v === false ? "✗" : "—"),
      },
    ],
    categoryBadge: "VALIDATION·ENGINE",
  },
];

const MAX_FEED_ENTRIES = 30;

function AgentPanel({
  agent,
  isActive,
}: { agent: AgentConfig; isActive: boolean }) {
  const { actor } = useActor();
  const colors = AGENT_COLORS[agent.id as keyof typeof AGENT_COLORS];
  const [feed, setFeed] = useState<FeedEntry[]>([]);
  const [latestMetrics, setLatestMetrics] = useState<Record<string, unknown>>(
    {},
  );
  const [lastBeat, setLastBeat] = useState<number | null>(null);
  const [status, setStatus] = useState<"INITIALIZING" | "PRODUCING">(
    "INITIALIZING",
  );
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (!actor || !isActive) return;

    const poll = async () => {
      try {
        const result = await (actor as any)[agent.pollFn]().catch(() => null);
        if (!result) return;

        // If result is a string, parse it
        if (typeof result === "string") {
          const entry = buildFeedEntry(result);
          if (entry.beat !== null) {
            setLastBeat(entry.beat);
            setStatus("PRODUCING");
          }
          setFeed((prev) => [entry, ...prev].slice(0, MAX_FEED_ENTRIES));
        } else if (typeof result === "object" && result !== null) {
          // Structured object response
          const obj = result as Record<string, unknown>;
          setLatestMetrics(obj);

          // Build a synthetic report string from the object
          const parts: string[] = [];
          if (typeof obj.beat === "number" || typeof obj.beat === "bigint") {
            const b = Number(obj.beat);
            parts.push(`B=${b}`);
            setLastBeat(b);
            setStatus("PRODUCING");
          }
          if (typeof obj.coherence === "number")
            parts.push(`C=${obj.coherence.toFixed(4)}`);
          if (typeof obj.sacesiTarget === "number")
            parts.push(`SA=${obj.sacesiTarget.toFixed(6)}`);

          // Build finding from any description/finding/insight field
          const findingFields = [
            "finding",
            "insight",
            "recommendation",
            "description",
            "alert",
            "hypothesis",
            "claim",
          ];
          let findingText: string | null = null;
          for (const f of findingFields) {
            if (typeof obj[f] === "string" && (obj[f] as string).length > 0) {
              findingText = obj[f] as string;
              break;
            }
          }

          // Add all numeric fields to parts
          for (const [k, v] of Object.entries(obj)) {
            if (typeof v === "number" && k !== "beat") {
              const shortKey = k
                .replace(/([A-Z])/g, "$1")
                .slice(0, 6)
                .toUpperCase();
              parts.push(`${shortKey}=${v.toFixed(4)}`);
            } else if (typeof v === "boolean") {
              parts.push(`${k.slice(0, 4).toUpperCase()}=${v ? "T" : "F"}`);
            }
          }

          const synthetic =
            parts.join(" ") + (findingText ? ` [${findingText}]` : "");
          const entry = buildFeedEntry(synthetic);

          // Override metrics from actual object fields
          entry.metrics = [];
          for (const [k, v] of Object.entries(obj)) {
            if (
              typeof v === "number" ||
              typeof v === "boolean" ||
              typeof v === "string"
            ) {
              const labelMap: Record<string, string> = {
                beat: "BEAT",
                coherence: "COHERENCE",
                sacesiTarget: "SACESI",
                fearLevel: "FEAR_LVL",
                courageScore: "COURAGE",
                groundedScore: "GROUNDED",
                missionLock: "MISSION_LK",
                missionLockActive: "MISSION_LK",
                identityScore: "ID_SCORE",
                identityDelta: "ID_DELTA",
                trustScore: "TRUST",
                mismatchCount: "MISMATCHES",
                coherenceValid: "COH_VALID",
                kuramotoValid: "KURT_VALID",
                consistencyScore: "CONSISTENCY",
                sharkCorrelation: "SHARK_COR",
                fearCorrelation: "FEAR_COR",
                coherenceMean: "COH_MEAN",
                hypothesisCount: "HYPOTHESES",
                coherenceMomentum: "COH_MOM",
                anomalyCount: "ANOMALY_CT",
                missionPersistence: "MISSION_PS",
                drawdown: "DRAWDOWN",
                peakYield: "PEAK_YIELD",
                mintVelocity: "MINT_VEL",
                patentCount: "PATENT_CT",
                coherencePeak: "COH_PEAK",
                sacesiAtPeak: "SACESI_PK",
                lastFileBeat: "FILED_AT",
                windowSize: "WINDOW",
                anomalyFlags: "ANOMALY_CT",
              };
              const label = labelMap[k] ?? k.slice(0, 10).toUpperCase();
              let displayVal = "—";
              if (typeof v === "number") displayVal = v.toFixed(4);
              else if (typeof v === "boolean")
                displayVal = v ? "TRUE" : "FALSE";
              else if (typeof v === "string") displayVal = v.slice(0, 12);
              entry.metrics.push({ key: label, value: displayVal });
            }
          }

          if (findingText) entry.finding = findingText;

          setFeed((prev) => [entry, ...prev].slice(0, MAX_FEED_ENTRIES));
        }
      } catch {
        // Silent fail — backend function may not exist yet
      }
    };

    poll();
    intervalRef.current = setInterval(poll, 5000);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [actor, agent.pollFn, isActive]);

  // Resolve metric values from latestMetrics
  function resolveMetric(m: AgentConfig["metrics"][0]): string {
    const v = latestMetrics[m.field];
    if (v === undefined || v === null) return "—";
    return m.format ? m.format(v) : String(v);
  }

  // Status color
  const statusColor =
    status === "PRODUCING" ? "oklch(0.65 0.18 145)" : "oklch(0.45 0.01 240)";

  return (
    <div className="flex flex-col h-full">
      {/* Agent header */}
      <div
        className="px-4 py-3 border-b flex items-start justify-between shrink-0"
        style={{ borderColor: colors.border, background: colors.dim }}
      >
        <div className="flex-1 min-w-0 pr-4">
          <div className="flex items-center gap-3 mb-1">
            <span
              className="font-mono text-sm tracking-[0.3em] font-bold"
              style={{ color: colors.primary }}
            >
              {agent.name}
            </span>
            <span
              className="font-mono text-[7px] tracking-[0.3em] px-2 py-0.5"
              style={{
                background: colors.badge,
                color: colors.text,
                border: `1px solid ${colors.border}`,
              }}
            >
              {agent.categoryBadge}
            </span>
          </div>
          <p
            className="font-mono text-[8px] tracking-[0.1em] leading-relaxed"
            style={{ color: "oklch(0.50 0.02 240)" }}
          >
            {agent.role}
          </p>
        </div>
        <div className="flex flex-col items-end gap-1 shrink-0">
          <div className="flex items-center gap-1.5">
            <div
              className="w-1.5 h-1.5 rounded-full"
              style={{ background: statusColor }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.2em]"
              style={{ color: statusColor }}
            >
              {status}
            </span>
          </div>
          {lastBeat !== null && (
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.40 0.01 240)" }}
            >
              LAST·B·{lastBeat.toLocaleString()}
            </span>
          )}
        </div>
      </div>

      {/* Key metrics strip */}
      <div
        className="grid grid-cols-4 px-4 py-2 border-b shrink-0"
        style={{ borderColor: "oklch(0.15 0.01 240)" }}
      >
        {agent.metrics.map((m) => (
          <div key={m.label} className="flex flex-col gap-0.5">
            <span
              className="font-mono text-[8px] tracking-[0.2em]"
              style={{ color: "oklch(0.42 0.01 240)" }}
            >
              {m.label}
            </span>
            <span
              className="font-mono text-[11px] tracking-tight"
              style={{ color: colors.primary }}
            >
              {resolveMetric(m)}
            </span>
          </div>
        ))}
      </div>

      {/* Production feed */}
      <div className="flex-1 overflow-hidden relative">
        {feed.length === 0 ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-3">
            <div
              className="w-8 h-8 border-2 border-t-transparent rounded-full animate-spin"
              style={{
                borderColor: colors.border,
                borderTopColor: "transparent",
              }}
            />
            <span
              className="font-mono text-[9px] tracking-[0.3em]"
              style={{ color: "oklch(0.35 0.01 240)" }}
              data-ocid="council.empty_state"
            >
              AWAITING FIRST PRODUCTION CYCLE
            </span>
          </div>
        ) : (
          <ScrollArea className="h-full">
            <div data-ocid="council.list">
              <AnimatePresence initial={false}>
                {feed.map((entry, i) => (
                  <FeedEntryCard
                    key={entry.id}
                    entry={entry}
                    agentColor={colors}
                    index={i}
                  />
                ))}
              </AnimatePresence>
            </div>
          </ScrollArea>
        )}
      </div>
    </div>
  );
}

// ── Sovereignty Signal Bar ────────────────────────────────────────────────────
function SovereigntyBar({
  sovereignSignals,
}: {
  sovereignSignals:
    | import("../hooks/useIntelligenceEngine").SovereignSignals
    | null;
}) {
  const fmt = (v: number | undefined, pct = false): string => {
    if (v === undefined || v === null) return "—";
    return pct ? `${(v * 100).toFixed(1)}%` : v.toFixed(3);
  };

  const signals = [
    {
      label: "FEAR",
      value: fmt(sovereignSignals?.fearLevel, true),
      raw: sovereignSignals?.fearLevel ?? 0,
      color: "oklch(0.65 0.22 25)",
      barColor: "oklch(0.55 0.22 25)",
      desc: "Suppresses economic output when elevated",
    },
    {
      label: "COURAGE",
      value: fmt(sovereignSignals?.courageScore, true),
      raw: sovereignSignals?.courageScore ?? 0,
      color: "oklch(0.65 0.18 145)",
      barColor: "oklch(0.55 0.18 145)",
      desc: "Boosts minting when active + mission locked",
    },
    {
      label: "GROUNDED",
      value: fmt(sovereignSignals?.groundedScore, true),
      raw: sovereignSignals?.groundedScore ?? 0,
      color: "oklch(0.65 0.18 200)",
      barColor: "oklch(0.55 0.15 200)",
      desc: "Gates OMNIS emergence threshold",
    },
    {
      label: "STREAK",
      value:
        sovereignSignals?.streakMultiplier !== undefined
          ? `${sovereignSignals.streakMultiplier.toFixed(2)}×`
          : "—",
      raw: Math.min(1, (sovereignSignals?.streakMultiplier ?? 1) / 3),
      color: "oklch(0.78 0.15 85)",
      barColor: "oklch(0.68 0.15 85)",
      desc: "Economic velocity multiplier (max 3.0 w/ mission lock)",
    },
    {
      label: "SURRENDER FLOOR",
      value: fmt(sovereignSignals?.surrenderFloor),
      raw: Math.min(1, (sovereignSignals?.surrenderFloor ?? 1) / 2),
      color: "oklch(0.72 0.16 80)",
      barColor: "oklch(0.62 0.14 80)",
      desc: "Permanent coherence floor — rises every 444 beats",
    },
  ];

  const missionLock = sovereignSignals?.missionLockActive;

  return (
    <div
      className="panel-glass px-4 py-3 mb-0 shrink-0"
      style={{
        borderBottom: "1px solid oklch(0.18 0.02 240)",
        background: "oklch(0.09 0.01 240)",
      }}
      data-ocid="council.panel"
    >
      <div className="flex items-center justify-between mb-2">
        <span
          className="font-mono text-[9px] tracking-[0.4em]"
          style={{ color: "oklch(0.45 0.02 240)" }}
        >
          SOVEREIGNTY SIGNAL SUBSTRATE
        </span>
        <div
          className="flex items-center gap-1.5 px-2 py-0.5"
          style={{
            background: missionLock
              ? "oklch(0.65 0.20 290 / 0.15)"
              : "oklch(0.14 0.01 240)",
            border: `1px solid ${missionLock ? "oklch(0.65 0.20 290 / 0.4)" : "oklch(0.20 0.01 240)"}`,
          }}
        >
          <div
            className="w-1.5 h-1.5 rounded-full"
            style={{
              background: missionLock
                ? "oklch(0.65 0.20 290)"
                : "oklch(0.30 0.01 240)",
            }}
          />
          <span
            className="font-mono text-[8px] tracking-[0.3em]"
            style={{
              color: missionLock
                ? "oklch(0.75 0.18 290)"
                : "oklch(0.40 0.01 240)",
            }}
          >
            MISSION LOCK{" "}
            {missionLock === undefined ? "—" : missionLock ? "ACTIVE" : "OPEN"}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-5 gap-3">
        {signals.map((sig) => (
          <div key={sig.label} className="flex flex-col gap-1">
            <div className="flex items-center justify-between">
              <span
                className="font-mono text-[8px] tracking-[0.15em]"
                style={{ color: "oklch(0.42 0.01 240)" }}
              >
                {sig.label}
              </span>
              <span
                className="font-mono text-[10px] tracking-tight"
                style={{ color: sig.color }}
              >
                {sig.value}
              </span>
            </div>
            {/* Bar */}
            <div
              className="h-0.5 w-full"
              style={{ background: "oklch(0.16 0.01 240)" }}
            >
              <div
                className="h-full transition-all duration-700"
                style={{
                  width: `${Math.min(100, (sig.raw ?? 0) * 100)}%`,
                  background: sig.barColor,
                }}
              />
            </div>
            <span
              className="font-mono text-[7px] leading-tight"
              style={{ color: "oklch(0.32 0.01 240)" }}
            >
              {sig.desc}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Main CouncilTab ───────────────────────────────────────────────────────────
export function CouncilTab() {
  const [activeAgent, setActiveAgent] = useState<string>("NEXUS");
  const { sovereignSignals } = useIntelligenceEngine();

  return (
    <div
      className="flex flex-col h-full"
      style={{ minHeight: "600px" }}
      data-ocid="council.panel"
    >
      {/* Sovereignty Signal Bar — always at top */}
      <SovereigntyBar sovereignSignals={sovereignSignals} />

      {/* Agent selector tab bar */}
      <div
        className="flex items-stretch border-b shrink-0 overflow-x-auto"
        style={{ borderColor: "oklch(0.16 0.01 240)" }}
        role="tablist"
      >
        {AGENTS.map((agent) => {
          const colors = AGENT_COLORS[agent.id as keyof typeof AGENT_COLORS];
          const isActive = activeAgent === agent.id;
          return (
            <button
              type="button"
              key={agent.id}
              role="tab"
              aria-selected={isActive}
              onClick={() => setActiveAgent(agent.id)}
              className="relative px-5 py-3 font-mono text-[9px] tracking-[0.3em] whitespace-nowrap transition-all"
              style={{
                color: isActive ? colors.primary : "oklch(0.40 0.01 240)",
                background: isActive ? colors.dim : "transparent",
                borderBottom: isActive
                  ? `2px solid ${colors.primary}`
                  : "2px solid transparent",
              }}
              data-ocid="council.tab"
            >
              {agent.name}
            </button>
          );
        })}
      </div>

      {/* Active agent panel */}
      <div className="flex-1 overflow-hidden">
        <AnimatePresence mode="wait">
          {AGENTS.map((agent) =>
            activeAgent === agent.id ? (
              <motion.div
                key={agent.id}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.15 }}
                className="h-full"
              >
                <AgentPanel agent={agent} isActive />
              </motion.div>
            ) : null,
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
