import { useCallback, useEffect, useRef, useState } from "react";
import { useActor } from "../hooks/useActor";

// ─── Types ────────────────────────────────────────────────────────────────────

type ProtocolCategory =
  | "ALL"
  | "LAW"
  | "MODEL"
  | "BEHAVIOR"
  | "REASONING"
  | "ORGAN";

interface ProtocolRecord {
  name: string;
  equation: string;
  category: string;
  precedence: number;
  executionCount: bigint;
  lastFiredBeat: bigint;
  lastResult: string; // "#passed" | "#failed" | "#skipped"
}

// ─── Constants ────────────────────────────────────────────────────────────────

const CATEGORY_COLORS: Record<string, string> = {
  LAW: "oklch(0.65 0.20 30)",
  MODEL: "oklch(0.65 0.18 145)",
  BEHAVIOR: "oklch(0.65 0.15 240)",
  REASONING: "oklch(0.78 0.15 85)",
  ORGAN: "oklch(0.72 0.15 170)",
};

const CATEGORY_BG: Record<string, string> = {
  LAW: "oklch(0.65 0.20 30 / 0.12)",
  MODEL: "oklch(0.65 0.18 145 / 0.12)",
  BEHAVIOR: "oklch(0.65 0.15 240 / 0.12)",
  REASONING: "oklch(0.78 0.15 85 / 0.12)",
  ORGAN: "oklch(0.72 0.15 170 / 0.12)",
};

const RESULT_COLORS: Record<string, string> = {
  "#passed": "oklch(0.72 0.18 145)",
  "#failed": "oklch(0.55 0.22 25)",
  "#skipped": "oklch(0.50 0.02 240)",
};

const FILTERS: ProtocolCategory[] = [
  "ALL",
  "LAW",
  "MODEL",
  "BEHAVIOR",
  "REASONING",
  "ORGAN",
];

// ─── Sub-components ───────────────────────────────────────────────────────────

function CategoryBadge({ category }: { category: string }) {
  const color = CATEGORY_COLORS[category] ?? "oklch(0.50 0.02 240)";
  const bg = CATEGORY_BG[category] ?? "oklch(0.50 0.02 240 / 0.12)";
  return (
    <span
      className="font-mono text-[7px] tracking-[0.2em] px-1.5 py-0.5 shrink-0"
      style={{ color, background: bg, border: `1px solid ${color}` }}
    >
      {category}
    </span>
  );
}

function ResultBadge({ result }: { result: string }) {
  const label =
    result === "#passed"
      ? "PASSED"
      : result === "#failed"
        ? "FAILED"
        : "SKIPPED";
  const color = RESULT_COLORS[result] ?? "oklch(0.50 0.02 240)";
  return (
    <span
      className="font-mono text-[7px] tracking-widest px-1.5 py-0.5 shrink-0"
      style={{ color, border: `1px solid ${color}40` }}
    >
      {label}
    </span>
  );
}

function ProtocolCard({
  protocol,
  index,
}: {
  protocol: ProtocolRecord;
  index: number;
}) {
  const accentColor =
    CATEGORY_COLORS[protocol.category] ?? "oklch(0.50 0.02 240)";
  const truncatedEq =
    protocol.equation.length > 80
      ? `${protocol.equation.slice(0, 80)}…`
      : protocol.equation;
  const execCount = Number(protocol.executionCount);
  const lastBeat = Number(protocol.lastFiredBeat);

  return (
    <div
      className="panel-glass p-4 flex flex-col gap-3 hover:brightness-110 transition-all"
      style={{ borderLeft: `2px solid ${accentColor}40` }}
      data-ocid={`protocols.item.${index + 1}`}
    >
      {/* Header row */}
      <div className="flex items-start justify-between gap-2">
        <div
          className="font-mono text-[10px] tracking-[0.2em] leading-tight min-w-0"
          style={{ color: "oklch(0.90 0.02 240)" }}
        >
          {protocol.name}
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          <CategoryBadge category={protocol.category} />
        </div>
      </div>

      {/* Equation */}
      <div
        className="font-mono text-[8px] leading-relaxed break-all"
        style={{ color: "oklch(0.48 0.05 240)" }}
      >
        {truncatedEq}
      </div>

      {/* Footer metrics */}
      <div className="flex items-center justify-between gap-2 pt-1 border-t border-white/5">
        <div className="flex items-center gap-3">
          <div>
            <div
              className="font-mono text-[6px] tracking-widest mb-0.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              PRECEDENCE
            </div>
            <div
              className="font-mono text-[9px] tabular-nums"
              style={{ color: accentColor }}
            >
              P{protocol.precedence}
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[6px] tracking-widest mb-0.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              EXECUTIONS
            </div>
            <div
              className="font-mono text-[9px] tabular-nums"
              style={{ color: "oklch(0.72 0.05 240)" }}
            >
              {execCount.toLocaleString()}
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[6px] tracking-widest mb-0.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              LAST BEAT
            </div>
            <div
              className="font-mono text-[9px] tabular-nums"
              style={{ color: "oklch(0.60 0.04 240)" }}
            >
              B{lastBeat > 0 ? lastBeat.toLocaleString() : "—"}
            </div>
          </div>
        </div>
        <ResultBadge result={protocol.lastResult} />
      </div>
    </div>
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

export function ProtocolTab() {
  const { actor } = useActor();
  const [protocols, setProtocols] = useState<ProtocolRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState<ProtocolCategory>("ALL");
  const [search, setSearch] = useState("");
  const [lastScanBeat, setLastScanBeat] = useState<number>(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchProtocols = useCallback(async () => {
    if (!actor) return;
    try {
      const raw = await (actor as any).getAllProtocols?.();
      if (Array.isArray(raw)) {
        setProtocols(raw as ProtocolRecord[]);
        const maxBeat = raw.reduce(
          (m: number, p: ProtocolRecord) =>
            Math.max(m, Number(p.lastFiredBeat)),
          0,
        );
        setLastScanBeat(maxBeat);
      }
    } catch {
      // silent — backend may not have protocols yet
    } finally {
      setLoading(false);
    }
  }, [actor]);

  useEffect(() => {
    fetchProtocols();
    intervalRef.current = setInterval(fetchProtocols, 3000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchProtocols]);

  // Derived stats
  const totalExecutions = protocols.reduce(
    (s, p) => s + Number(p.executionCount),
    0,
  );

  // Filtered list
  const filtered = protocols.filter((p) => {
    const matchCat = activeFilter === "ALL" || p.category === activeFilter;
    const matchSearch =
      !search || p.name.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  // Category counts for filter tabs
  const catCounts = FILTERS.reduce<Record<string, number>>((acc, cat) => {
    acc[cat] =
      cat === "ALL"
        ? protocols.length
        : protocols.filter((p) => p.category === cat).length;
    return acc;
  }, {});

  return (
    <div className="space-y-5" data-ocid="protocols.panel">
      {/* Header */}
      <div
        className="panel-glass p-4"
        style={{ borderLeft: "3px solid oklch(0.78 0.15 85 / 0.6)" }}
      >
        <div
          className="font-mono text-sm tracking-[0.3em]"
          style={{ color: "oklch(0.78 0.15 85)" }}
        >
          PROTOCOL REGISTRY
        </div>
        <div className="font-mono text-[8px] text-muted-foreground mt-1">
          SOVEREIGN EXECUTION RECORD · ZERO-EXPOSURE COMPLIANT
        </div>
      </div>

      {/* Count banner */}
      <div className="grid grid-cols-3 gap-3">
        {[
          {
            label: "PROTOCOLS",
            value: protocols.length,
            color: "oklch(0.78 0.15 85)",
          },
          {
            label: "TOTAL EXECUTIONS",
            value: totalExecutions.toLocaleString(),
            color: "oklch(0.65 0.18 145)",
          },
          {
            label: "LAST SCAN BEAT",
            value: lastScanBeat > 0 ? `B${lastScanBeat.toLocaleString()}` : "—",
            color: "oklch(0.72 0.15 170)",
          },
        ].map((stat) => (
          <div key={stat.label} className="panel-glass p-4">
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-2"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              {stat.label}
            </div>
            <div
              className="font-mono text-xl tabular-nums"
              style={{
                color: stat.color,
                textShadow: `0 0 12px ${stat.color} / 0.3`,
              }}
            >
              {loading ? "—" : stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* Search + category filter */}
      <div className="flex flex-col sm:flex-row gap-3">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="SEARCH PROTOCOL NAME…"
          className="flex-1 bg-black/40 border border-white/10 px-3 py-2 font-mono text-[9px] text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-white/20"
          data-ocid="protocols.search_input"
        />
        <div
          className="flex flex-wrap gap-1.5"
          data-ocid="protocols.filter.tab"
        >
          {FILTERS.map((cat) => {
            const active = activeFilter === cat;
            const color =
              cat === "ALL"
                ? "oklch(0.78 0.15 85)"
                : (CATEGORY_COLORS[cat] ?? "oklch(0.55 0.02 240)");
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setActiveFilter(cat)}
                data-ocid={`protocols.filter.${cat.toLowerCase()}`}
                className="px-3 py-1.5 font-mono text-[8px] tracking-[0.2em] border transition-all"
                style={{
                  borderColor: active ? color : `${color}40`,
                  color: active ? color : "oklch(0.45 0.02 240)",
                  background: active
                    ? `${color.replace(")", " / 0.10)")}`
                    : "transparent",
                }}
              >
                {cat}
                <span className="ml-1.5 opacity-60">{catCounts[cat] ?? 0}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Protocol grid */}
      {loading ? (
        <div
          className="panel-glass p-8 text-center font-mono text-[9px] tracking-widest"
          style={{ color: "oklch(0.40 0.02 240)" }}
          data-ocid="protocols.loading_state"
        >
          <div
            className="w-4 h-4 border-t animate-spin mx-auto mb-4"
            style={{ borderColor: "oklch(0.78 0.15 85)" }}
          />
          POLLING PROTOCOL REGISTRY…
        </div>
      ) : filtered.length === 0 ? (
        <div
          className="panel-glass p-10 text-center"
          data-ocid="protocols.empty_state"
        >
          <div
            className="font-mono text-2xl mb-3"
            style={{ color: "oklch(0.30 0.02 240)" }}
          >
            ⚖
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.3em]"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            {search || activeFilter !== "ALL"
              ? "NO PROTOCOLS MATCH FILTER"
              : "PROTOCOL REGISTRY INITIALIZING"}
          </div>
          {(search || activeFilter !== "ALL") && (
            <button
              type="button"
              onClick={() => {
                setSearch("");
                setActiveFilter("ALL");
              }}
              className="mt-4 font-mono text-[8px] tracking-widest underline"
              style={{ color: "oklch(0.55 0.02 240)" }}
            >
              CLEAR FILTER
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {filtered.map((protocol, idx) => (
            <ProtocolCard
              key={`${protocol.name}-${idx}`}
              protocol={protocol}
              index={idx}
            />
          ))}
        </div>
      )}

      {/* Live pulse */}
      <div className="flex items-center gap-2 pt-1">
        <div
          className="w-1.5 h-1.5 animate-beat"
          style={{
            backgroundColor: "oklch(0.78 0.15 85)",
            boxShadow: "0 0 6px oklch(0.78 0.15 85 / 0.8)",
          }}
        />
        <span
          className="font-mono text-[7px] tracking-widest"
          style={{ color: "oklch(0.35 0.02 240)" }}
        >
          POLLING EVERY 3s · {filtered.length} OF {protocols.length} SHOWN
        </span>
      </div>
    </div>
  );
}
