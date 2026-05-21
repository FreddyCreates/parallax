import { useCallback, useEffect, useRef, useState } from "react";
import type {
  ContextRouterState,
  ContextSlice,
  ModelRegistryState,
  SovereignModel,
} from "../backend";
import { useActor } from "../hooks/useActor";

// ─── Types ────────────────────────────────────────────────────────────────────

type LayerFilter = "ALL" | "MICRO" | "MESO" | "MACRO";

// ─── Constants ────────────────────────────────────────────────────────────────

const LAYER_COLORS: Record<string, string> = {
  MICRO: "oklch(0.65 0.18 230)",
  MESO: "oklch(0.72 0.16 75)",
  MACRO: "oklch(0.62 0.22 20)",
};

const LAYER_BG: Record<string, string> = {
  MICRO: "oklch(0.65 0.18 230 / 0.12)",
  MESO: "oklch(0.72 0.16 75 / 0.12)",
  MACRO: "oklch(0.62 0.22 20 / 0.12)",
};

const PHI_GOLD = "oklch(0.78 0.15 85)";
const LAYERS: LayerFilter[] = ["ALL", "MICRO", "MESO", "MACRO"];

// ─── Stats Bar ────────────────────────────────────────────────────────────────

interface StatsBarProps {
  registryState: ModelRegistryState | null;
  routerState: ContextRouterState | null;
  microCounts: Record<string, number>;
}

function StatsBar({ registryState, routerState, microCounts }: StatsBarProps) {
  const stats = [
    {
      label: "TOTAL MODELS",
      value: registryState
        ? Number(registryState.totalModels).toLocaleString()
        : "300",
      color: PHI_GOLD,
    },
    {
      label: "MICRO",
      value: microCounts.MICRO ?? "—",
      color: LAYER_COLORS.MICRO,
    },
    {
      label: "MESO",
      value: microCounts.MESO ?? "—",
      color: LAYER_COLORS.MESO,
    },
    {
      label: "MACRO",
      value: microCounts.MACRO ?? "—",
      color: LAYER_COLORS.MACRO,
    },
    {
      label: "ACTIVATIONS",
      value: registryState
        ? Number(registryState.totalActivations).toLocaleString()
        : "—",
      color: "oklch(0.65 0.18 145)",
    },
    {
      label: "μTOKEN BUDGET",
      value: routerState
        ? Number(routerState.microTokenBudgetPerBeat).toLocaleString()
        : "200,000",
      color: "oklch(0.65 0.20 290)",
    },
    {
      label: "AVG RESONANCE",
      value: routerState ? routerState.avgResonanceScore.toFixed(4) : "—",
      color: PHI_GOLD,
    },
  ];

  return (
    <div
      className="grid grid-cols-4 xl:grid-cols-7 gap-px mb-5"
      style={{ background: "oklch(0.18 0.01 240)" }}
      data-ocid="models.stats.panel"
    >
      {stats.map((s) => (
        <div
          key={s.label}
          className="flex flex-col gap-1 px-4 py-3"
          style={{ background: "oklch(0.10 0.01 240)" }}
        >
          <span
            className="font-mono text-[6px] tracking-[0.3em]"
            style={{ color: "oklch(0.38 0.02 240)" }}
          >
            {s.label}
          </span>
          <span
            className="font-mono text-base tabular-nums"
            style={{ color: s.color }}
          >
            {s.value}
          </span>
        </div>
      ))}
    </div>
  );
}

// ─── Layer Chip ───────────────────────────────────────────────────────────────

function LayerChip({ layer }: { layer: string }) {
  const color = LAYER_COLORS[layer] ?? "oklch(0.50 0.02 240)";
  const bg = LAYER_BG[layer] ?? "oklch(0.50 0.02 240 / 0.08)";
  return (
    <span
      className="font-mono text-[6px] tracking-widest px-1.5 py-0.5"
      style={{ color, background: bg, border: `1px solid ${color}40` }}
    >
      {layer}
    </span>
  );
}

// ─── Model Row ────────────────────────────────────────────────────────────────

function ModelRow({
  model,
  selected,
  onSelect,
  index,
}: {
  model: SovereignModel;
  selected: boolean;
  onSelect: () => void;
  index: number;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      data-ocid={`models.list.item.${index + 1}`}
      className="w-full flex items-center gap-3 px-3 py-2.5 border-b text-left transition-all"
      style={{
        borderColor: "oklch(0.16 0.01 240)",
        background: selected
          ? `${PHI_GOLD.replace(")", " / 0.06)")}`
          : "transparent",
        borderLeft: selected
          ? `2px solid ${PHI_GOLD}`
          : "2px solid transparent",
      }}
    >
      {/* ID badge */}
      <span
        className="font-mono text-[8px] tabular-nums shrink-0 px-1.5 py-0.5 border"
        style={{
          color: PHI_GOLD,
          borderColor: `${PHI_GOLD}40`,
          background: `${PHI_GOLD}08`,
          minWidth: 42,
          textAlign: "center",
        }}
      >
        {model.id}
      </span>

      {/* Latin name */}
      <span
        className="font-mono text-[9px] tracking-[0.1em] flex-1 truncate min-w-0"
        style={{
          color: selected ? "oklch(0.95 0.02 240)" : "oklch(0.72 0.03 240)",
        }}
      >
        {model.latinName}
      </span>

      {/* Layer + sub-group */}
      <div className="flex items-center gap-2 shrink-0">
        <LayerChip layer={model.layer} />
        <span
          className="hidden lg:block font-mono text-[7px] tracking-widest"
          style={{ color: "oklch(0.40 0.02 240)" }}
        >
          {model.subIntelligence}
        </span>
      </div>
    </button>
  );
}

// ─── Model Detail Panel ───────────────────────────────────────────────────────

function ModelDetail({ model }: { model: SovereignModel }) {
  const layers = [
    {
      num: "01",
      label: "MEANING",
      content: model.meaning,
      color: PHI_GOLD,
    },
    {
      num: "02",
      label: "MODEL",
      content: `Typed sovereign structure · Layer 2\nInput types: ${model.inputTypes.length > 0 ? model.inputTypes.join(", ") : "universal"}`,
      color: LAYER_COLORS.MICRO,
    },
    {
      num: "03",
      label: "COMPUTATION",
      content: model.computation,
      color: LAYER_COLORS.MESO,
      mono: true,
    },
    {
      num: "04",
      label: "BINDING",
      content: model.executionBinding,
      color: LAYER_COLORS.MACRO,
      badge:
        model.maxMicroTokenOutput > 0n
          ? `${Number(model.maxMicroTokenOutput).toLocaleString()} μTKN MAX`
          : null,
    },
  ];

  return (
    <div
      className="border p-4 space-y-4"
      style={{
        borderColor: `${PHI_GOLD}30`,
        background: `${PHI_GOLD}04`,
      }}
      data-ocid="models.detail.panel"
    >
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span
              className="font-mono text-sm tabular-nums"
              style={{ color: PHI_GOLD }}
            >
              {model.id}
            </span>
            <LayerChip layer={model.layer} />
          </div>
          <div
            className="font-mono text-xs tracking-[0.15em]"
            style={{ color: "oklch(0.88 0.04 240)" }}
          >
            {model.latinName}
          </div>
          <div
            className="font-mono text-[7px] tracking-[0.2em] mt-0.5"
            style={{ color: "oklch(0.42 0.02 240)" }}
          >
            {model.subIntelligence}
          </div>
        </div>
        <div className="text-right shrink-0">
          <div
            className="font-mono text-[6px] tracking-widest mb-0.5"
            style={{ color: "oklch(0.35 0.02 240)" }}
          >
            μTOKEN ID
          </div>
          <div
            className="font-mono text-[9px] tabular-nums"
            style={{ color: "oklch(0.55 0.15 290)" }}
          >
            0x{model.microTokenId.toString(16).toUpperCase().padStart(4, "0")}
          </div>
          {model.beatActivationCount > 0n && (
            <div
              className="font-mono text-[6px] tabular-nums mt-0.5"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              {Number(model.beatActivationCount).toLocaleString()} activations
            </div>
          )}
        </div>
      </div>

      {/* 4-layer display */}
      <div className="space-y-2">
        {layers.map((lyr) => (
          <div
            key={lyr.num}
            className="border-l-2 pl-3 py-1"
            style={{ borderColor: `${lyr.color}60` }}
          >
            <div className="flex items-center gap-2 mb-1">
              <span
                className="font-mono text-[6px] tabular-nums"
                style={{ color: `${lyr.color}80` }}
              >
                {lyr.num}
              </span>
              <span
                className="font-mono text-[7px] tracking-[0.25em]"
                style={{ color: lyr.color }}
              >
                {lyr.label}
              </span>
              {lyr.badge && (
                <span
                  className="font-mono text-[6px] px-1.5 py-0.5 border"
                  style={{
                    color: lyr.color,
                    borderColor: `${lyr.color}40`,
                    background: `${lyr.color}08`,
                  }}
                >
                  {lyr.badge}
                </span>
              )}
            </div>
            <p
              className={`text-[8px] leading-relaxed whitespace-pre-line ${lyr.mono ? "font-mono" : "font-body"}`}
              style={{ color: "oklch(0.65 0.02 240)" }}
            >
              {lyr.content}
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─── Context Router ───────────────────────────────────────────────────────────

function ContextRouter({
  actor,
}: { actor: ReturnType<typeof useActor>["actor"] }) {
  const [signal, setSignal] = useState("");
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<ContextSlice | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleRoute() {
    if (!actor || !signal.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const res = await (actor as any).routeBeat(signal.trim(), BigInt(3));
      setResult(res as ContextSlice);
    } catch {
      setError("ROUTE FAILED — check actor connection");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      className="panel-glass p-4 mt-4"
      data-ocid="models.context_router.panel"
    >
      <div
        className="font-mono text-[8px] tracking-[0.4em] mb-4"
        style={{ color: "oklch(0.42 0.02 240)" }}
      >
        CONTEXT ROUTER — ROUTE BEAT SIGNAL
      </div>

      {/* Input */}
      <div className="flex gap-2 mb-4">
        <input
          type="text"
          value={signal}
          onChange={(e) => setSignal(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && !loading && handleRoute()}
          placeholder="Enter a beat signal text..."
          className="flex-1 bg-black/40 border px-3 py-2 font-mono text-[9px] focus:outline-none"
          style={{
            borderColor: "oklch(0.22 0.02 240)",
            color: "oklch(0.80 0.02 240)",
          }}
          data-ocid="models.context_router.input"
        />
        <button
          type="button"
          onClick={handleRoute}
          disabled={loading || !signal.trim() || !actor}
          data-ocid="models.context_router.submit_button"
          className="px-5 py-2 font-mono text-[9px] tracking-[0.25em] border transition-all disabled:opacity-40"
          style={{
            borderColor: `${PHI_GOLD}60`,
            color: PHI_GOLD,
            background: loading ? `${PHI_GOLD}08` : "transparent",
          }}
        >
          {loading ? "ROUTING..." : "ROUTE"}
        </button>
      </div>

      {/* Error */}
      {error && (
        <div
          className="font-mono text-[8px] px-3 py-2 border mb-4"
          style={{
            color: "oklch(0.65 0.22 25)",
            borderColor: "oklch(0.55 0.22 25 / 0.3)",
          }}
          data-ocid="models.context_router.error_state"
        >
          {error}
        </div>
      )}

      {/* Result */}
      {result && (
        <div
          className="space-y-3"
          data-ocid="models.context_router.success_state"
        >
          {/* Stats row */}
          <div className="grid grid-cols-3 gap-2">
            {[
              {
                label: "RESONANCE SCORE",
                value: result.resonanceScore.toFixed(4),
                color: PHI_GOLD,
              },
              {
                label: "μTOKENS USED",
                value: Number(result.microTokensUsed).toLocaleString(),
                color: "oklch(0.65 0.20 290)",
              },
              {
                label: "BUDGET",
                value: Number(result.microTokenBudget).toLocaleString(),
                color: "oklch(0.50 0.02 240)",
              },
            ].map((s) => (
              <div
                key={s.label}
                className="px-3 py-2 border"
                style={{ borderColor: "oklch(0.18 0.01 240)" }}
              >
                <div
                  className="font-mono text-[6px] tracking-widest mb-1"
                  style={{ color: "oklch(0.35 0.02 240)" }}
                >
                  {s.label}
                </div>
                <div
                  className="font-mono text-sm tabular-nums"
                  style={{ color: s.color }}
                >
                  {s.value}
                </div>
              </div>
            ))}
          </div>

          {/* Selected models */}
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-2"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              SELECTED MODEL IDs
            </div>
            <div className="flex gap-2 flex-wrap">
              {result.selectedModelIds.length > 0 ? (
                result.selectedModelIds.map((id) => (
                  <span
                    key={id}
                    className="font-mono text-[9px] px-2.5 py-1 border"
                    style={{
                      color: PHI_GOLD,
                      borderColor: `${PHI_GOLD}40`,
                      background: `${PHI_GOLD}08`,
                    }}
                    data-ocid="models.context_router.selected.item"
                  >
                    {id}
                  </span>
                ))
              ) : (
                <span
                  className="font-mono text-[8px]"
                  style={{ color: "oklch(0.40 0.02 240)" }}
                >
                  No models matched — backend returning empty array
                </span>
              )}
            </div>
          </div>

          {/* Timestamp */}
          <div
            className="font-mono text-[7px]"
            style={{ color: "oklch(0.32 0.02 240)" }}
          >
            BEAT TS · {Number(result.beatTimestamp).toLocaleString()}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Main ModelsTab ───────────────────────────────────────────────────────────

export function ModelsTab() {
  const { actor } = useActor();

  const [models, setModels] = useState<SovereignModel[]>([]);
  const [registryState, setRegistryState] = useState<ModelRegistryState | null>(
    null,
  );
  const [routerState, setRouterState] = useState<ContextRouterState | null>(
    null,
  );
  const [loading, setLoading] = useState(true);

  const [layerFilter, setLayerFilter] = useState<LayerFilter>("ALL");
  const [search, setSearch] = useState("");
  const [selectedModel, setSelectedModel] = useState<SovereignModel | null>(
    null,
  );

  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Load models once on mount
  const loadModels = useCallback(async () => {
    if (!actor) return;
    const a = actor as any;
    try {
      const raw = (await a.getAllModels?.()?.catch(() => [])) ?? [];
      if (Array.isArray(raw) && raw.length > 0)
        setModels(raw as SovereignModel[]);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, [actor]);

  // Stats polling at 5s
  const loadStats = useCallback(async () => {
    if (!actor) return;
    const a = actor as any;
    try {
      const [reg, router] = await Promise.all([
        a.getModelRegistryState?.()?.catch(() => null) ?? Promise.resolve(null),
        a.getContextRouterState?.()?.catch(() => null) ?? Promise.resolve(null),
      ]);
      if (reg) setRegistryState(reg as ModelRegistryState);
      if (router) setRouterState(router as ContextRouterState);
    } catch {
      // silent
    }
  }, [actor]);

  useEffect(() => {
    loadModels();
    loadStats();
    intervalRef.current = setInterval(loadStats, 5000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [loadModels, loadStats]);

  // Filter logic
  const filtered = models.filter((m) => {
    if (layerFilter !== "ALL" && m.layer !== layerFilter) return false;
    if (search.trim()) {
      const q = search.toLowerCase();
      return (
        m.id.toLowerCase().includes(q) ||
        m.latinName.toLowerCase().includes(q) ||
        m.subIntelligence.toLowerCase().includes(q)
      );
    }
    return true;
  });

  // Layer counts
  const microCounts: Record<string, number> = {
    MICRO: models.filter((m) => m.layer === "MICRO").length,
    MESO: models.filter((m) => m.layer === "MESO").length,
    MACRO: models.filter((m) => m.layer === "MACRO").length,
  };

  return (
    <div className="space-y-4" data-ocid="models.page">
      {/* Header */}
      <div
        className="panel-glass p-4"
        style={{ borderLeft: `3px solid ${PHI_GOLD}60` }}
      >
        <div className="flex items-center justify-between">
          <div>
            <div
              className="font-mono text-sm tracking-[0.3em]"
              style={{ color: PHI_GOLD }}
            >
              SOVEREIGN MODEL REGISTRY
            </div>
            <div className="font-mono text-[8px] text-muted-foreground mt-0.5">
              300 SOVEREIGN MODELS · MICRO / MESO / MACRO LAYERS · CONTEXT
              ROUTER ACTIVE
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div
              className="w-1.5 h-1.5 animate-beat"
              style={{
                backgroundColor: PHI_GOLD,
                boxShadow: `0 0 6px ${PHI_GOLD}80`,
              }}
            />
            {loading && (
              <span
                className="font-mono text-[7px] tracking-widest"
                style={{ color: "oklch(0.45 0.02 240)" }}
                data-ocid="models.loading_state"
              >
                LOADING...
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Stats Bar */}
      <StatsBar
        registryState={registryState}
        routerState={routerState}
        microCounts={microCounts}
      />

      {/* Main two-panel layout */}
      <div className="grid grid-cols-1 xl:grid-cols-[320px_1fr] gap-4">
        {/* ── Left Sidebar ─────────────────────────────────────────────────── */}
        <div className="space-y-3" data-ocid="models.sidebar.panel">
          {/* Layer Filter */}
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-2 px-1"
              style={{ color: "oklch(0.38 0.02 240)" }}
            >
              LAYER FILTER
            </div>
            <div
              className="grid grid-cols-4 gap-1"
              data-ocid="models.layer.tab"
            >
              {LAYERS.map((l) => {
                const active = layerFilter === l;
                const color =
                  l === "ALL" ? PHI_GOLD : (LAYER_COLORS[l] ?? PHI_GOLD);
                return (
                  <button
                    key={l}
                    type="button"
                    onClick={() => setLayerFilter(l)}
                    data-ocid={`models.layer.${l.toLowerCase()}.toggle`}
                    className="py-1.5 font-mono text-[7px] tracking-[0.2em] transition-all border"
                    style={{
                      borderColor: active ? color : "oklch(0.20 0.01 240)",
                      color: active ? color : "oklch(0.40 0.02 240)",
                      background: active ? `${color}10` : "transparent",
                    }}
                  >
                    {l}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Search */}
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-1 px-1"
              style={{ color: "oklch(0.38 0.02 240)" }}
            >
              SEARCH
            </div>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="ID, name, sub-group..."
              className="w-full bg-black/40 border px-3 py-2 font-mono text-[9px] focus:outline-none"
              style={{
                borderColor: "oklch(0.20 0.02 240)",
                color: "oklch(0.80 0.02 240)",
              }}
              data-ocid="models.search_input"
            />
          </div>

          {/* Count */}
          <div
            className="font-mono text-[7px] px-1"
            style={{ color: "oklch(0.35 0.02 240)" }}
          >
            {filtered.length.toLocaleString()} of{" "}
            {models.length.toLocaleString()} models
          </div>

          {/* Model List */}
          <div
            className="border overflow-y-auto"
            style={{
              borderColor: "oklch(0.18 0.01 240)",
              maxHeight: "50vh",
            }}
            data-ocid="models.list"
          >
            {loading && models.length === 0 ? (
              <div
                className="px-4 py-8 font-mono text-[8px] text-center"
                style={{ color: "oklch(0.38 0.02 240)" }}
                data-ocid="models.list.loading_state"
              >
                LOADING 300 MODELS...
              </div>
            ) : filtered.length === 0 ? (
              <div
                className="px-4 py-8 font-mono text-[8px] text-center"
                style={{ color: "oklch(0.38 0.02 240)" }}
                data-ocid="models.list.empty_state"
              >
                NO MODELS MATCH FILTER
              </div>
            ) : (
              filtered.map((model, i) => (
                <ModelRow
                  key={model.id}
                  model={model}
                  selected={selectedModel?.id === model.id}
                  onSelect={() =>
                    setSelectedModel(
                      selectedModel?.id === model.id ? null : model,
                    )
                  }
                  index={i}
                />
              ))
            )}
          </div>
        </div>

        {/* ── Right Content ─────────────────────────────────────────────────── */}
        <div className="space-y-4" data-ocid="models.content.panel">
          {/* Detail panel */}
          {selectedModel ? (
            <ModelDetail model={selectedModel} />
          ) : (
            <div
              className="border p-8 flex flex-col items-center justify-center"
              style={{
                borderColor: "oklch(0.16 0.01 240)",
                minHeight: 200,
              }}
              data-ocid="models.detail.empty_state"
            >
              <div
                className="font-mono text-[8px] tracking-[0.3em] mb-2"
                style={{ color: "oklch(0.35 0.02 240)" }}
              >
                NO MODEL SELECTED
              </div>
              <div
                className="font-mono text-[7px]"
                style={{ color: "oklch(0.28 0.02 240)" }}
              >
                Select a model from the list to view its 4-layer artifact
              </div>
            </div>
          )}

          {/* Context Router section */}
          <ContextRouter actor={actor} />
        </div>
      </div>
    </div>
  );
}
