import { useState, useEffect } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";

// ═══════════════════════════════════════════════════════════════════════════
// INTELLIGENCE CONTRACTS TAB — Domains 34-37
// Internal Intelligence Contracts: Routing, Extensions, Coupling
// PHI LAW: all displays are phi-harmonic proportioned
// ═══════════════════════════════════════════════════════════════════════════

interface ContractMetrics {
  totalContracts: bigint;
  activeContracts: bigint;
  totalExecutions: bigint;
}

interface RoutingMetrics {
  totalRoutes: bigint;
  activeRoutes: bigint;
  signalsRouted: bigint;
  signalsDropped: bigint;
}

interface ExtensionMetrics {
  totalExtensions: bigint;
  activeExtensions: bigint;
  totalCalls: bigint;
  aggregateInfluence: number;
}

interface CouplingMetrics {
  totalSystems: bigint;
  activeSystems: bigint;
  totalMessages: bigint;
  totalWriteBacks: bigint;
  globalCoherence: number;
}

interface CoupledSystem {
  systemId: string;
  name: string;
  bindingStrength: number;
}

const CATEGORIES = [
  { id: "contracts", label: "CONTRACTS", icon: "📜" },
  { id: "routing", label: "ROUTING", icon: "🔀" },
  { id: "extensions", label: "EXTENSIONS", icon: "🔌" },
  { id: "coupling", label: "COUPLING", icon: "🔗" },
];

const SKELETON_ROWS = ["sk-0", "sk-1", "sk-2", "sk-3"];

export function IntelligenceTab() {
  const { actor } = useActor();
  const [activeCategory, setActiveCategory] = useState("contracts");
  const [loading, setLoading] = useState(true);

  // Metrics state
  const [contractMetrics, setContractMetrics] = useState<ContractMetrics | null>(null);
  const [routingMetrics, setRoutingMetrics] = useState<RoutingMetrics | null>(null);
  const [extensionMetrics, setExtensionMetrics] = useState<ExtensionMetrics | null>(null);
  const [couplingMetrics, setCouplingMetrics] = useState<CouplingMetrics | null>(null);
  const [coupledSystems, setCoupledSystems] = useState<CoupledSystem[]>([]);

  useEffect(() => {
    async function fetchMetrics() {
      if (!actor) return;
      setLoading(true);
      try {
        const [contracts, routing, extensions, coupling, systems] = await Promise.all([
          (actor as any).getIntelligenceContractMetrics?.(),
          (actor as any).getRoutingMetrics?.(),
          (actor as any).getExtensionMetrics?.(),
          (actor as any).getCouplingMetrics?.(),
          (actor as any).getCoupledSystems?.(),
        ]);

        if (contracts) setContractMetrics(contracts);
        if (routing) setRoutingMetrics(routing);
        if (extensions) setExtensionMetrics(extensions);
        if (coupling) setCouplingMetrics(coupling);
        if (systems) {
          setCoupledSystems(
            systems.map(([id, name, strength]: [string, string, number]) => ({
              systemId: id,
              name,
              bindingStrength: strength,
            }))
          );
        }
      } catch (err) {
        console.error("Failed to fetch intelligence metrics:", err);
        toast.error("Failed to load intelligence metrics");
      } finally {
        setLoading(false);
      }
    }
    fetchMetrics();
    const interval = setInterval(fetchMetrics, 5000); // Refresh every 5s
    return () => clearInterval(interval);
  }, [actor]);

  return (
    <div className="space-y-6" data-ocid="intelligence.panel">
      {/* Category Selector */}
      <div className="flex gap-2 flex-wrap" data-ocid="intelligence.categories">
        {CATEGORIES.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setActiveCategory(cat.id)}
            className={`px-4 py-2 font-mono text-[10px] tracking-widest transition-all ${
              activeCategory === cat.id
                ? "bg-primary/20 text-primary border border-primary/40"
                : "bg-white/5 text-muted-foreground border border-white/10 hover:bg-white/10"
            }`}
            data-ocid={`intelligence.category.${cat.id}`}
          >
            <span className="mr-2">{cat.icon}</span>
            {cat.label}
          </button>
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {/* Left Panel - Metrics */}
        <div className="xl:col-span-2 panel-glass p-5">
          {loading ? (
            <div className="space-y-3" data-ocid="intelligence.loading">
              {SKELETON_ROWS.map((id) => (
                <div key={id} className="h-16 skeleton-dark" />
              ))}
            </div>
          ) : (
            <>
              {activeCategory === "contracts" && (
                <ContractsPanel metrics={contractMetrics} />
              )}
              {activeCategory === "routing" && (
                <RoutingPanel metrics={routingMetrics} />
              )}
              {activeCategory === "extensions" && (
                <ExtensionsPanel metrics={extensionMetrics} />
              )}
              {activeCategory === "coupling" && (
                <CouplingPanel
                  metrics={couplingMetrics}
                  systems={coupledSystems}
                />
              )}
            </>
          )}
        </div>

        {/* Right Panel - Status Overview */}
        <div className="panel-glass p-5 space-y-4">
          <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground">
            INTELLIGENCE SYSTEM STATUS
          </div>
          <StatusIndicator
            label="CONTRACTS"
            value={contractMetrics?.activeContracts ?? BigInt(0)}
            total={contractMetrics?.totalContracts ?? BigInt(0)}
            color="oklch(0.75 0.18 145)"
          />
          <StatusIndicator
            label="ROUTES"
            value={routingMetrics?.activeRoutes ?? BigInt(0)}
            total={routingMetrics?.totalRoutes ?? BigInt(0)}
            color="oklch(0.70 0.20 210)"
          />
          <StatusIndicator
            label="EXTENSIONS"
            value={extensionMetrics?.activeExtensions ?? BigInt(0)}
            total={extensionMetrics?.totalExtensions ?? BigInt(0)}
            color="oklch(0.65 0.22 280)"
          />
          <StatusIndicator
            label="COUPLED SYSTEMS"
            value={couplingMetrics?.activeSystems ?? BigInt(0)}
            total={couplingMetrics?.totalSystems ?? BigInt(0)}
            color="oklch(0.60 0.20 25)"
          />

          <div className="border-t border-white/10 pt-4 mt-4">
            <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-2">
              GLOBAL COHERENCE
            </div>
            <div className="flex items-center gap-3">
              <div className="flex-1 h-2 bg-white/5 rounded-full overflow-hidden">
                <div
                  className="h-full transition-all duration-500"
                  style={{
                    width: `${(couplingMetrics?.globalCoherence ?? 0.618) * 100}%`,
                    background:
                      (couplingMetrics?.globalCoherence ?? 0.618) >= 0.618
                        ? "oklch(0.75 0.18 145)"
                        : "oklch(0.55 0.22 25)",
                  }}
                />
              </div>
              <span className="font-mono text-[10px]">
                {((couplingMetrics?.globalCoherence ?? 0.618) * 100).toFixed(1)}%
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTRACTS PANEL
// ═══════════════════════════════════════════════════════════════════════════

function ContractsPanel({ metrics }: { metrics: ContractMetrics | null }) {
  const CONTRACT_TYPES = [
    { type: "ROUTING", desc: "Intelligence signal routing contracts", icon: "🔀" },
    { type: "REASONING", desc: "Multi-step reasoning chain contracts", icon: "🧠" },
    { type: "VALUATION", desc: "Asset and artifact valuation contracts", icon: "💎" },
    { type: "EXTENSION", desc: "AI extension capability contracts", icon: "🔌" },
    { type: "COUPLING", desc: "External AI binding contracts", icon: "🔗" },
    { type: "ORACLE", desc: "External data source contracts", icon: "🔮" },
    { type: "GUARDIAN", desc: "Security and validation contracts", icon: "🛡️" },
  ];

  return (
    <div className="space-y-4" data-ocid="intelligence.contracts">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground">
        INTELLIGENCE CONTRACTS — DOMAIN 34
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <MetricCard
          label="TOTAL"
          value={Number(metrics?.totalContracts ?? 0)}
          suffix="contracts"
        />
        <MetricCard
          label="ACTIVE"
          value={Number(metrics?.activeContracts ?? 0)}
          suffix="live"
          highlight
        />
        <MetricCard
          label="EXECUTIONS"
          value={Number(metrics?.totalExecutions ?? 0)}
          suffix="total"
        />
      </div>

      {/* Contract Types */}
      <div className="space-y-2">
        {CONTRACT_TYPES.map((ct) => (
          <div
            key={ct.type}
            className="flex items-center gap-3 p-3 bg-white/5 border border-white/10 hover:bg-white/10 transition-colors"
            data-ocid={`intelligence.contract.${ct.type.toLowerCase()}`}
          >
            <span className="text-xl">{ct.icon}</span>
            <div className="flex-1">
              <div className="font-mono text-[10px] tracking-wide">{ct.type}</div>
              <div className="font-mono text-[8px] text-muted-foreground">
                {ct.desc}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROUTING PANEL
// ═══════════════════════════════════════════════════════════════════════════

function RoutingPanel({ metrics }: { metrics: RoutingMetrics | null }) {
  const STRATEGIES = [
    { name: "PRIORITY", desc: "Route by signal priority level" },
    { name: "WEIGHTED", desc: "Route by weighted distribution" },
    { name: "COHERENCE", desc: "Route by coherence alignment" },
    { name: "CAPABILITY", desc: "Route by destination capability" },
    { name: "LATENCY", desc: "Route by lowest latency path" },
    { name: "CHAIN", desc: "Route through contract chain" },
    { name: "BROADCAST", desc: "Route to all destinations" },
    { name: "ADAPTIVE", desc: "Learn optimal route (default)" },
  ];

  return (
    <div className="space-y-4" data-ocid="intelligence.routing">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground">
        INTELLIGENCE ROUTING — DOMAIN 35
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <MetricCard
          label="TOTAL"
          value={Number(metrics?.totalRoutes ?? 0)}
          suffix="routes"
        />
        <MetricCard
          label="ACTIVE"
          value={Number(metrics?.activeRoutes ?? 0)}
          suffix="live"
          highlight
        />
        <MetricCard
          label="ROUTED"
          value={Number(metrics?.signalsRouted ?? 0)}
          suffix="signals"
        />
        <MetricCard
          label="DROPPED"
          value={Number(metrics?.signalsDropped ?? 0)}
          suffix="signals"
          warning={Number(metrics?.signalsDropped ?? 0) > 0}
        />
      </div>

      {/* Routing Strategies */}
      <div className="grid grid-cols-2 gap-2">
        {STRATEGIES.map((s) => (
          <div
            key={s.name}
            className="p-3 bg-white/5 border border-white/10"
            data-ocid={`intelligence.strategy.${s.name.toLowerCase()}`}
          >
            <div className="font-mono text-[10px] tracking-wide">{s.name}</div>
            <div className="font-mono text-[8px] text-muted-foreground">
              {s.desc}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSIONS PANEL
// ═══════════════════════════════════════════════════════════════════════════

function ExtensionsPanel({ metrics }: { metrics: ExtensionMetrics | null }) {
  const SLOTS = [
    { index: 0, name: "MODEL ADAPTER", desc: "External model integration" },
    { index: 1, name: "DATA CONNECTOR", desc: "External data sources" },
    { index: 2, name: "PROTOCOL BRIDGE", desc: "Cross-protocol integration" },
    { index: 3, name: "COMPUTE OFFLOAD", desc: "External compute resources" },
    { index: 4, name: "STORAGE EXTENDER", desc: "Extended storage capacity" },
    { index: 5, name: "INFERENCE BOOSTER", desc: "Inference acceleration" },
    { index: 6, name: "SECURITY LAYER", desc: "Security extensions" },
    { index: 7, name: "CUSTOM ENGINE", desc: "Custom cognitive engine" },
  ];

  return (
    <div className="space-y-4" data-ocid="intelligence.extensions">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground">
        INTELLIGENCE EXTENSIONS — DOMAIN 36
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <MetricCard
          label="TOTAL"
          value={Number(metrics?.totalExtensions ?? 0)}
          suffix="extensions"
        />
        <MetricCard
          label="ACTIVE"
          value={Number(metrics?.activeExtensions ?? 0)}
          suffix="live"
          highlight
        />
        <MetricCard
          label="CALLS"
          value={Number(metrics?.totalCalls ?? 0)}
          suffix="invocations"
        />
        <MetricCard
          label="INFLUENCE"
          value={(metrics?.aggregateInfluence ?? 0) * 100}
          suffix="%"
          decimal
        />
      </div>

      {/* Extension Slots (F(6) = 8 slots) */}
      <div className="font-mono text-[8px] tracking-[0.2em] text-muted-foreground mb-2">
        EXTENSION SLOTS — F(6) = 8 CAPACITY
      </div>
      <div className="grid grid-cols-2 gap-2">
        {SLOTS.map((slot) => (
          <div
            key={slot.index}
            className="p-3 bg-white/5 border border-white/10 flex items-center gap-3"
            data-ocid={`intelligence.slot.${slot.index}`}
          >
            <div className="w-6 h-6 flex items-center justify-center bg-primary/20 text-primary font-mono text-[10px]">
              {slot.index}
            </div>
            <div className="flex-1">
              <div className="font-mono text-[10px] tracking-wide">
                {slot.name}
              </div>
              <div className="font-mono text-[8px] text-muted-foreground">
                {slot.desc}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// COUPLING PANEL
// ═══════════════════════════════════════════════════════════════════════════

function CouplingPanel({
  metrics,
  systems,
}: {
  metrics: CouplingMetrics | null;
  systems: CoupledSystem[];
}) {
  return (
    <div className="space-y-4" data-ocid="intelligence.coupling">
      <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground">
        INTELLIGENCE COUPLING — DOMAIN 37
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <MetricCard
          label="SYSTEMS"
          value={Number(metrics?.totalSystems ?? 0)}
          suffix="coupled"
        />
        <MetricCard
          label="ACTIVE"
          value={Number(metrics?.activeSystems ?? 0)}
          suffix="live"
          highlight
        />
        <MetricCard
          label="MESSAGES"
          value={Number(metrics?.totalMessages ?? 0)}
          suffix="total"
        />
        <MetricCard
          label="WRITE-BACKS"
          value={Number(metrics?.totalWriteBacks ?? 0)}
          suffix="requests"
        />
      </div>

      {/* Coupled Systems */}
      <div className="font-mono text-[8px] tracking-[0.2em] text-muted-foreground mb-2">
        COUPLED AI SYSTEMS — MAX F(7) = 13
      </div>
      {systems.length === 0 ? (
        <div className="py-8 text-center bg-white/5 border border-white/10">
          <span className="font-mono text-[9px] text-muted-foreground">
            NO EXTERNAL SYSTEMS COUPLED
          </span>
        </div>
      ) : (
        <div className="space-y-2">
          {systems.map((sys) => (
            <div
              key={sys.systemId}
              className="p-3 bg-white/5 border border-white/10 flex items-center gap-3"
              data-ocid={`intelligence.system.${sys.systemId}`}
            >
              <div
                className="w-3 h-3 rounded-full"
                style={{
                  background:
                    sys.bindingStrength >= 0.618
                      ? "oklch(0.75 0.18 145)"
                      : "oklch(0.55 0.22 25)",
                }}
              />
              <div className="flex-1">
                <div className="font-mono text-[10px] tracking-wide">
                  {sys.name}
                </div>
                <div className="font-mono text-[8px] text-muted-foreground">
                  {sys.systemId}
                </div>
              </div>
              <div className="text-right">
                <div className="font-mono text-[10px]">
                  {(sys.bindingStrength * 100).toFixed(1)}%
                </div>
                <div className="font-mono text-[8px] text-muted-foreground">
                  binding
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Write-back Gate Indicator */}
      <div className="mt-4 p-3 bg-white/5 border border-white/10">
        <div className="flex items-center justify-between">
          <div>
            <div className="font-mono text-[10px] tracking-wide">
              WRITE-BACK COHERENCE GATE
            </div>
            <div className="font-mono text-[8px] text-muted-foreground">
              R ≥ φ⁻¹ (0.618) required for external write-back
            </div>
          </div>
          <div
            className="w-8 h-8 flex items-center justify-center rounded-full"
            style={{
              background:
                (metrics?.globalCoherence ?? 0) >= 0.618
                  ? "oklch(0.75 0.18 145 / 0.2)"
                  : "oklch(0.55 0.22 25 / 0.2)",
              border:
                (metrics?.globalCoherence ?? 0) >= 0.618
                  ? "2px solid oklch(0.75 0.18 145)"
                  : "2px solid oklch(0.55 0.22 25)",
            }}
          >
            {(metrics?.globalCoherence ?? 0) >= 0.618 ? "✓" : "✗"}
          </div>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

function MetricCard({
  label,
  value,
  suffix,
  highlight = false,
  warning = false,
  decimal = false,
}: {
  label: string;
  value: number;
  suffix: string;
  highlight?: boolean;
  warning?: boolean;
  decimal?: boolean;
}) {
  return (
    <div
      className="p-3 bg-white/5 border border-white/10"
      style={{
        borderColor: highlight
          ? "oklch(0.75 0.18 145 / 0.4)"
          : warning
            ? "oklch(0.55 0.22 25 / 0.4)"
            : undefined,
      }}
    >
      <div className="font-mono text-[8px] text-muted-foreground mb-1">
        {label}
      </div>
      <div
        className="font-mono text-lg"
        style={{
          color: highlight
            ? "oklch(0.75 0.18 145)"
            : warning
              ? "oklch(0.55 0.22 25)"
              : undefined,
        }}
      >
        {decimal ? value.toFixed(1) : value.toLocaleString()}
      </div>
      <div className="font-mono text-[8px] text-muted-foreground">{suffix}</div>
    </div>
  );
}

function StatusIndicator({
  label,
  value,
  total,
  color,
}: {
  label: string;
  value: bigint;
  total: bigint;
  color: string;
}) {
  const pct = Number(total) > 0 ? (Number(value) / Number(total)) * 100 : 0;
  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between">
        <span className="font-mono text-[8px] text-muted-foreground">{label}</span>
        <span className="font-mono text-[10px]">
          {value.toString()}/{total.toString()}
        </span>
      </div>
      <div className="h-1.5 bg-white/5 rounded-full overflow-hidden">
        <div
          className="h-full transition-all duration-500"
          style={{ width: `${pct}%`, background: color }}
        />
      </div>
    </div>
  );
}

export default IntelligenceTab;
