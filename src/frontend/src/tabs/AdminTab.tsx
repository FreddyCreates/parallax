import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import type { ContextRouterState, ModelRegistryState } from "../backend";
import { GenesisPanel } from "../components/GenesisPanel";
import { useActor } from "../hooks/useActor";

interface FullState {
  beat: bigint;
  coherence: number;
  formaCapital: number;
  mrcBalance: bigint;
  genesisActivated: boolean;
}

interface AdminTabProps {
  fullState: FullState | null;
}

function WireField({
  label,
  placeholder,
  onWire,
}: {
  label: string;
  placeholder: string;
  onWire: (val: string) => Promise<void>;
}) {
  const [val, setVal] = useState("");
  const [loading, setLoading] = useState(false);

  async function handle() {
    if (!val.trim()) return;
    setLoading(true);
    try {
      await onWire(val.trim());
      toast.success(`${label} WIRED`);
      setVal("");
    } catch {
      toast.error(`FAILED TO WIRE ${label}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex gap-2">
      <div className="flex-1">
        <div className="font-mono text-[8px] tracking-[0.2em] text-muted-foreground mb-1">
          {label}
        </div>
        <input
          type="text"
          value={val}
          onChange={(e) => setVal(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handle()}
          placeholder={placeholder}
          className="w-full bg-black/40 border border-white/10 px-3 py-2 font-mono text-[9px] text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-white/20"
          data-ocid="admin.input"
        />
      </div>
      <button
        type="button"
        onClick={handle}
        disabled={loading || !val.trim()}
        data-ocid="admin.primary_button"
        className="self-end px-4 py-2 font-mono text-[9px] tracking-[0.2em] border transition-all disabled:opacity-40"
        style={{
          borderColor: "oklch(0.65 0.28 290 / 0.5)",
          color: "oklch(0.65 0.28 290)",
        }}
      >
        {loading ? "WIRING..." : "WIRE"}
      </button>
    </div>
  );
}

// ─── Context Router Panel ─────────────────────────────────────────────────────

function ContextRouterPanel({ actor }: { actor: any }) {
  const [routerState, setRouterState] = useState<ContextRouterState | null>(
    null,
  );
  const [registryState, setRegistryState] = useState<ModelRegistryState | null>(
    null,
  );
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetch = useCallback(async () => {
    if (!actor) return;
    try {
      const [router, registry] = await Promise.all([
        actor.getContextRouterState?.()?.catch(() => null) ??
          Promise.resolve(null),
        actor.getModelRegistryState?.()?.catch(() => null) ??
          Promise.resolve(null),
      ]);
      if (router) setRouterState(router as ContextRouterState);
      if (registry) setRegistryState(registry as ModelRegistryState);
    } catch {
      // silent
    }
  }, [actor]);

  useEffect(() => {
    fetch();
    intervalRef.current = setInterval(fetch, 5000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetch]);

  const resonance = routerState?.avgResonanceScore ?? 0;

  return (
    <div className="panel-glass p-5" data-ocid="admin.context_router.panel">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-5">
        CONTEXT ROUTER — μTOKEN METRICS
      </div>

      <div className="grid grid-cols-2 gap-3 mb-5">
        {[
          {
            label: "μTOKEN BUDGET / BEAT",
            value: routerState
              ? Number(routerState.microTokenBudgetPerBeat).toLocaleString()
              : "200,000",
            color: "oklch(0.78 0.15 85)",
          },
          {
            label: "TOTAL BEAT ROUTES",
            value: routerState
              ? Number(routerState.totalBeatRoutes).toLocaleString()
              : "—",
            color: "oklch(0.65 0.28 290)",
          },
          {
            label: "TOTAL μTKN CONSUMED",
            value: registryState
              ? Number(registryState.microTokensConsumedTotal).toLocaleString()
              : "—",
            color: "oklch(0.65 0.20 290)",
          },
          {
            label: "TOTAL ACTIVATIONS",
            value: registryState
              ? Number(registryState.totalActivations).toLocaleString()
              : "—",
            color: "oklch(0.65 0.18 145)",
          },
        ].map((stat) => (
          <div
            key={stat.label}
            className="bg-black/30 border border-white/5 p-3"
          >
            <div
              className="font-mono text-[6px] tracking-widest mb-1.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              {stat.label}
            </div>
            <div
              className="font-mono text-base tabular-nums"
              style={{ color: stat.color }}
            >
              {stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* Avg resonance bar */}
      <div className="mb-4">
        <div className="flex justify-between items-center mb-1.5">
          <span
            className="font-mono text-[7px] tracking-widest"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            AVG RESONANCE SCORE
          </span>
          <span
            className="font-mono text-[9px] tabular-nums"
            style={{ color: "oklch(0.78 0.15 85)" }}
          >
            {resonance.toFixed(4)}
          </span>
        </div>
        <div
          className="h-1.5 w-full"
          style={{ background: "oklch(0.15 0.01 240)" }}
        >
          <div
            className="h-full transition-all"
            style={{
              width: `${Math.min(resonance * 100, 100)}%`,
              background: "oklch(0.78 0.15 85)",
              boxShadow: "0 0 8px oklch(0.78 0.15 85 / 0.4)",
            }}
          />
        </div>
      </div>

      {/* Last activated */}
      <div className="border-t border-white/5 pt-3">
        <div
          className="font-mono text-[7px] tracking-widest mb-1"
          style={{ color: "oklch(0.38 0.02 240)" }}
        >
          LAST ACTIVATED MODEL
        </div>
        <div
          className="font-mono text-[9px]"
          style={{ color: "oklch(0.72 0.15 85)" }}
        >
          {registryState?.lastActivated || "—"}
        </div>
      </div>

      <div className="flex items-center gap-2 mt-4">
        <div
          className="w-1.5 h-1.5 animate-beat"
          style={{
            backgroundColor: "oklch(0.78 0.15 85)",
            boxShadow: "0 0 6px oklch(0.78 0.15 85 / 0.6)",
          }}
        />
        <span
          className="font-mono text-[7px] tracking-widest"
          style={{ color: "oklch(0.35 0.02 240)" }}
        >
          POLLING EVERY 5s
        </span>
      </div>
    </div>
  );
}

// ─── AdminTab ─────────────────────────────────────────────────────────────────

export function AdminTab({ fullState }: AdminTabProps) {
  const { actor } = useActor();
  const { identity } = useInternetIdentity();

  return (
    <div className="space-y-6" data-ocid="admin.panel">
      {/* Header */}
      <div
        className="panel-glass p-4"
        style={{ borderLeft: "3px solid oklch(0.65 0.28 290 / 0.6)" }}
      >
        <div
          className="font-mono text-sm tracking-[0.3em]"
          style={{ color: "oklch(0.65 0.28 290)" }}
        >
          MERIDIAN PRIME — ADMIN SURFACE
        </div>
        <div className="font-mono text-[8px] text-muted-foreground mt-1">
          CREATOR-ONLY · ALL COMMANDS GATED BY CREATOR PRINCIPAL
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Genesis Activate */}
        <div className="panel-glass p-5">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
            GENESIS ACTIVATION
          </div>
          <GenesisPanel />
        </div>

        {/* Principal Info */}
        <div className="panel-glass p-5">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
            SOVEREIGN IDENTITY
          </div>
          <div className="space-y-3">
            <div>
              <div className="font-mono text-[8px] text-muted-foreground mb-1">
                CREATOR PRINCIPAL
              </div>
              <div
                className="font-mono text-[9px] break-all"
                style={{ color: "oklch(0.72 0.15 200)" }}
              >
                {identity?.getPrincipal().toString() ?? "NOT AUTHENTICATED"}
              </div>
            </div>
            <div className="border-t border-white/5 pt-3">
              <div className="font-mono text-[8px] text-muted-foreground mb-1">
                MRC RESERVE
              </div>
              <div
                className="font-mono text-lg"
                style={{
                  color: "oklch(0.65 0.28 290)",
                  textShadow: "0 0 8px oklch(0.65 0.28 290 / 0.4)",
                }}
              >
                {fullState ? String(fullState.mrcBalance) : "—"} MRC
              </div>
            </div>
            <div className="border-t border-white/5 pt-3">
              <div className="font-mono text-[8px] text-muted-foreground mb-1">
                GENESIS STATUS
              </div>
              <div
                className="font-mono text-[9px] tracking-widest"
                style={{
                  color: fullState?.genesisActivated
                    ? "oklch(0.62 0.17 145)"
                    : "oklch(0.55 0.22 25)",
                }}
              >
                {fullState?.genesisActivated ? "ACTIVATED" : "PENDING"}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Phase Canister Wiring */}
      <div className="panel-glass p-5">
        <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-5">
          PHASE CANISTER WIRING — PRINCIPAL IDs
        </div>
        <div className="space-y-4">
          <WireField
            label="FLUX CANISTER"
            placeholder="CANISTER PRINCIPAL ID"
            onWire={async (v) => {
              // setFluxCanister exists on actor if available
              const a = actor as any;
              if (a?.setFluxCanister) await a.setFluxCanister(v);
            }}
          />
          <WireField
            label="RESONEX CANISTER"
            placeholder="CANISTER PRINCIPAL ID"
            onWire={async (v) => {
              const a = actor as any;
              if (a?.setResonexCanister) await a.setResonexCanister(v);
            }}
          />
          <WireField
            label="QMEM CANISTER"
            placeholder="CANISTER PRINCIPAL ID"
            onWire={async (v) => {
              await (actor as any)?.setQmemCanister(v);
            }}
          />
          <WireField
            label="AXIS CANISTER"
            placeholder="CANISTER PRINCIPAL ID"
            onWire={async (v) => {
              await (actor as any)?.setAxisCanister(v);
            }}
          />
        </div>
      </div>

      {/* Emergency Controls */}
      <div className="panel-glass p-5">
        <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
          EMERGENCY CONTROLS
        </div>
        <EmergencyRollback actor={actor} />
      </div>

      {/* Organ Registry */}
      <OrganRegistry actor={actor} />

      {/* Context Router */}
      <ContextRouterPanel actor={actor} />
    </div>
  );
}

function EmergencyRollback({ actor }: { actor: any }) {
  const [confirmed, setConfirmed] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handle() {
    if (!confirmed) {
      setConfirmed(true);
      toast.warning("CONFIRM — click again to execute ARES rollback");
      setTimeout(() => setConfirmed(false), 5000);
      return;
    }
    setLoading(true);
    setConfirmed(false);
    try {
      await actor?.px_emergencyRollback();
      toast.success("ARES ROLLBACK EXECUTED");
    } catch {
      toast.error("ROLLBACK FAILED");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-2">
      <button
        type="button"
        onClick={handle}
        disabled={loading}
        data-ocid="admin.delete_button"
        className="w-full py-3 font-mono text-xs tracking-[0.25em] border transition-all"
        style={{
          borderColor: confirmed
            ? "oklch(0.55 0.22 25)"
            : "oklch(0.55 0.22 25 / 0.4)",
          color: confirmed ? "oklch(0.85 0.22 25)" : "oklch(0.65 0.22 25)",
          background: confirmed ? "oklch(0.55 0.22 25 / 0.1)" : "transparent",
          boxShadow: confirmed
            ? "0 0 20px oklch(0.55 0.22 25 / 0.3)"
            : undefined,
        }}
      >
        {loading
          ? "EXECUTING ROLLBACK..."
          : confirmed
            ? "CONFIRM EMERGENCY ROLLBACK"
            : "ARES EMERGENCY ROLLBACK"}
      </button>
      <div className="font-mono text-[7px] text-muted-foreground">
        Restores organism to best snapshot · Requires creator principal
      </div>
    </div>
  );
}

// ─── Organ Registry ───────────────────────────────────────────────────────────

const PHI_INV = 0.618;

const ORGAN_SLOTS = [
  "ANIMUS",
  "CORPUS",
  "SENSUS",
  "MEMORIA",
  "PULSUS",
  "GUBERNATIO",
  "INTELLIGENTIA",
  "DOMUS_CURA",
  "DOMUS_CIVITAS",
];

interface RegistryEntry {
  organType: string;
  status: string; // "active" | "degraded" | "unreachable"
  healthScore: number;
  cyclesUsed: bigint;
  messagesProcessed: bigint;
  errors: bigint;
  latencyMs: number;
  lastHeartbeatBeat: bigint;
}

function healthColor(score: number): string {
  if (score >= PHI_INV) return "oklch(0.72 0.18 145)";
  if (score >= 0.3) return "oklch(0.65 0.20 30)";
  return "oklch(0.55 0.22 25)";
}

function statusColor(status: string): string {
  if (status === "active") return "oklch(0.72 0.18 145)";
  if (status === "degraded") return "oklch(0.65 0.20 30)";
  return "oklch(0.55 0.22 25)";
}

function statusLabel(status: string): string {
  if (status === "active") return "ACTIVE";
  if (status === "degraded") return "DEGRADED";
  return "UNREACHABLE";
}

function OrganRegistry({ actor }: { actor: any }) {
  const [entries, setEntries] = useState<RegistryEntry[]>([]);
  const [coherence, setCoherence] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchRegistry = useCallback(async () => {
    if (!actor) return;
    try {
      const [rawEntries, rawCoherence] = await Promise.all([
        actor.getRegistryEntries?.()?.catch(() => []) ?? Promise.resolve([]),
        actor.getRegistryCoherence?.()?.catch(() => 0) ?? Promise.resolve(0),
      ]);
      if (Array.isArray(rawEntries)) setEntries(rawEntries as RegistryEntry[]);
      if (typeof rawCoherence === "number") setCoherence(rawCoherence);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, [actor]);

  useEffect(() => {
    fetchRegistry();
    intervalRef.current = setInterval(fetchRegistry, 3000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchRegistry]);

  const entryMap = new Map(entries.map((e) => [e.organType, e]));
  const activeCount = entries.filter((e) => e.status === "active").length;
  const degradedCount = entries.filter(
    (e) => e.status === "degraded" || e.status === "unreachable",
  ).length;

  return (
    <div className="panel-glass p-5" data-ocid="admin.organ_registry.panel">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-5">
        ORGAN REGISTRY — SOVEREIGN CANISTER HEALTH
      </div>

      {/* Overview stats */}
      <div className="grid grid-cols-3 gap-3 mb-5">
        {[
          {
            label: "TOTAL ORGANS",
            value: entries.length || "—",
            color: "oklch(0.65 0.28 290)",
          },
          {
            label: "ACTIVE",
            value: loading ? "—" : activeCount,
            color: "oklch(0.72 0.18 145)",
          },
          {
            label: "DEGRADED",
            value: loading ? "—" : degradedCount,
            color:
              degradedCount > 0
                ? "oklch(0.65 0.20 30)"
                : "oklch(0.40 0.02 240)",
          },
        ].map((stat) => (
          <div
            key={stat.label}
            className="bg-black/30 border border-white/5 p-3"
          >
            <div
              className="font-mono text-[6px] tracking-widest mb-1.5"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              {stat.label}
            </div>
            <div
              className="font-mono text-lg tabular-nums"
              style={{ color: stat.color }}
            >
              {stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* Coherence R */}
      <div className="mb-5">
        <div className="flex justify-between items-center mb-1.5">
          <span
            className="font-mono text-[7px] tracking-widest"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            OVERALL COHERENCE R
          </span>
          <span
            className="font-mono text-[9px] tabular-nums"
            style={{ color: healthColor(coherence) }}
          >
            {coherence.toFixed(4)}
          </span>
        </div>
        <div
          className="h-1.5 w-full rounded-none"
          style={{ background: "oklch(0.15 0.01 240)" }}
        >
          <div
            className="h-full transition-all"
            style={{
              width: `${Math.min(coherence * 100, 100)}%`,
              background: healthColor(coherence),
              boxShadow: `0 0 8px ${healthColor(coherence)} / 0.5`,
            }}
          />
        </div>
        {/* φ⁻¹ threshold line marker */}
        <div className="relative h-0">
          <div
            className="absolute top-0 w-px h-3"
            style={{
              left: `${PHI_INV * 100}%`,
              background: "oklch(0.78 0.15 85 / 0.5)",
              transform: "translateY(-100%)",
            }}
          />
        </div>
        <div
          className="font-mono text-[6px] mt-1"
          style={{ color: "oklch(0.35 0.02 240)" }}
        >
          φ⁻¹ = 0.618 threshold
        </div>
      </div>

      {/* Per-organ rows */}
      <div className="space-y-2" data-ocid="admin.organ_registry.list">
        {ORGAN_SLOTS.map((organType, idx) => {
          const entry = entryMap.get(organType);
          if (!entry) {
            return (
              <div
                key={organType}
                className="flex items-center justify-between px-3 py-2.5 border border-white/5"
                data-ocid={`admin.organ_registry.item.${idx + 1}`}
              >
                <div
                  className="font-mono text-[8px] tracking-[0.15em]"
                  style={{ color: "oklch(0.35 0.02 240)" }}
                >
                  {organType}
                </div>
                <span
                  className="font-mono text-[7px] tracking-widest px-2 py-0.5 border"
                  style={{
                    color: "oklch(0.35 0.02 240)",
                    borderColor: "oklch(0.20 0.01 240)",
                  }}
                >
                  NOT YET DEPLOYED
                </span>
              </div>
            );
          }

          const sColor = statusColor(entry.status);
          const hColor = healthColor(entry.healthScore);
          const lastBeatDiff =
            entry.lastHeartbeatBeat > 0n
              ? `${Number(entry.lastHeartbeatBeat)} beats ago`
              : "—";

          return (
            <div
              key={organType}
              className="border border-white/5 p-3 space-y-2"
              data-ocid={`admin.organ_registry.item.${idx + 1}`}
            >
              <div className="flex items-center justify-between gap-2">
                <div
                  className="font-mono text-[8px] tracking-[0.15em]"
                  style={{ color: "oklch(0.85 0.03 240)" }}
                >
                  {organType}
                </div>
                <span
                  className="font-mono text-[7px] tracking-widest px-1.5 py-0.5"
                  style={{
                    color: sColor,
                    border: `1px solid ${sColor}50`,
                    background: `${sColor}10`,
                  }}
                >
                  {statusLabel(entry.status)}
                </span>
              </div>

              {/* Health score bar */}
              <div>
                <div className="flex justify-between mb-0.5">
                  <span
                    className="font-mono text-[6px] tracking-widest"
                    style={{ color: "oklch(0.35 0.02 240)" }}
                  >
                    HEALTH
                  </span>
                  <span
                    className="font-mono text-[7px] tabular-nums"
                    style={{ color: hColor }}
                  >
                    {entry.healthScore.toFixed(3)}
                  </span>
                </div>
                <div
                  className="h-1 w-full"
                  style={{ background: "oklch(0.15 0.01 240)" }}
                >
                  <div
                    className="h-full transition-all"
                    style={{
                      width: `${Math.min(entry.healthScore * 100, 100)}%`,
                      background: hColor,
                    }}
                  />
                </div>
              </div>

              {/* Metrics row */}
              <div className="grid grid-cols-4 gap-2 pt-1">
                {[
                  {
                    label: "CYCLES",
                    value: Number(entry.cyclesUsed).toLocaleString(),
                  },
                  {
                    label: "MESSAGES",
                    value: Number(entry.messagesProcessed).toLocaleString(),
                  },
                  {
                    label: "ERRORS",
                    value: String(Number(entry.errors)),
                  },
                  { label: "LATENCY", value: `${entry.latencyMs}ms` },
                ].map((m) => (
                  <div key={m.label}>
                    <div
                      className="font-mono text-[5px] tracking-widest mb-0.5"
                      style={{ color: "oklch(0.30 0.02 240)" }}
                    >
                      {m.label}
                    </div>
                    <div
                      className="font-mono text-[8px] tabular-nums"
                      style={{ color: "oklch(0.60 0.03 240)" }}
                    >
                      {m.value}
                    </div>
                  </div>
                ))}
              </div>

              <div
                className="font-mono text-[6px]"
                style={{ color: "oklch(0.35 0.02 240)" }}
              >
                LAST HEARTBEAT · {lastBeatDiff}
              </div>
            </div>
          );
        })}
      </div>

      {/* Live indicator */}
      <div className="flex items-center gap-2 mt-4">
        <div
          className="w-1.5 h-1.5 animate-beat"
          style={{
            backgroundColor: "oklch(0.65 0.28 290)",
            boxShadow: "0 0 6px oklch(0.65 0.28 290 / 0.6)",
          }}
        />
        <span
          className="font-mono text-[7px] tracking-widest"
          style={{ color: "oklch(0.35 0.02 240)" }}
        >
          POLLING EVERY 3s
        </span>
      </div>
    </div>
  );
}
