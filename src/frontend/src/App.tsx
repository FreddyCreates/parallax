import { Toaster } from "@/components/ui/sonner";
import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import LandingPage from "./components/LandingPage";
import { useActor } from "./hooks/useActor";
import { useSchumannState } from "./hooks/useQueries";
import { AdminTab } from "./tabs/AdminTab";
import { BankTab } from "./tabs/BankTab";
import { BirthAiTab } from "./tabs/BirthAiTab";
import { BuilderTab } from "./tabs/BuilderTab";
import { CouncilTab } from "./tabs/CouncilTab";
import { ExchangeTab } from "./tabs/ExchangeTab";
import { FormaTab } from "./tabs/FormaTab";
import { LexisPrimeTab } from "./tabs/LexisPrimeTab";
import { ModelsTab } from "./tabs/ModelsTab";
import { NOVATab } from "./tabs/NOVATab";
import { NodesTab } from "./tabs/NodesTab";
import { PredictionTab } from "./tabs/PredictionTab";
import { PrometheusTab } from "./tabs/PrometheusTab";
import { ProtocolTab } from "./tabs/ProtocolTab";
import { QuantumTab } from "./tabs/QuantumTab";
import { SchoolTab } from "./tabs/SchoolTab";
import { SubstrateTab } from "./tabs/SubstrateTab";
import { ThesaurusParallaxiTab } from "./tabs/ThesaurusParallaxiTab";
import { TreasuryTab } from "./tabs/TreasuryTab";
import { VaelTab } from "./tabs/VaelTab";
import { WyomingTab } from "./tabs/WyomingTab";

type TabId =
  | "substrate"
  | "council"
  | "quantum"
  | "prediction"
  | "prometheus"
  | "lexis"
  | "vael"
  | "exchange"
  | "wallet"
  | "treasury"
  | "forma"
  | "admin"
  | "bank"
  | "nodes"
  | "wyoming"
  | "school"
  | "protocols"
  | "birth-ai"
  | "builder"
  | "models"
  | "nova";

const TABS: { id: TabId; label: string; short: string; icon: string }[] = [
  { id: "substrate", label: "SUBSTRATE", short: "SUB", icon: "\u25c8" },
  { id: "council", label: "COUNCIL", short: "CNL", icon: "\u2b21" },
  { id: "quantum", label: "QUANTUM", short: "QNT", icon: "\u27e8\u03c8\u27e9" },
  { id: "prediction", label: "PREDICTION", short: "PRD", icon: "\u25ce" },
  { id: "prometheus", label: "PROMETHEUS", short: "PRM", icon: "\u26a1" },
  { id: "lexis", label: "LEXIS PRIME", short: "LEX", icon: "\u039b" },
  { id: "vael", label: "VAEL DEFENSE", short: "VAL", icon: "\u26e8" },
  { id: "exchange", label: "EXCHANGE", short: "EXC", icon: "\u21cc" },
  { id: "wallet", label: "WALLET", short: "WLT", icon: "\u20bf" },
  { id: "treasury", label: "TREASURY", short: "TRE", icon: "\u0191" },
  { id: "forma", label: "FORMA", short: "FRM", icon: "\u03c6" },
  { id: "admin", label: "ADMIN", short: "ADM", icon: "\u2295" },
  { id: "bank", label: "BANK", short: "BNK", icon: "\u20ae" },
  { id: "nodes", label: "NODES", short: "NDS", icon: "\u2b21" },
  { id: "wyoming", label: "WYOMING", short: "WYO", icon: "\u2295" },
  { id: "school", label: "SCHOOL", short: "SCH", icon: "\u25c8" },
  { id: "protocols", label: "PROTOCOLS", short: "PRO", icon: "\u2696" },
  { id: "birth-ai", label: "BIRTH AI", short: "BIR", icon: "\u2736" },
  { id: "builder", label: "BUILDER", short: "BLD", icon: "\u2699" },
  { id: "models", label: "MODELS", short: "MDL", icon: "\u2227" },
  { id: "nova", label: "NOVA", short: "NOV", icon: "\u29bf" },
];

// ─── Types ───────────────────────────────────────────────────────────────────

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
  dominantDrive: bigint;
  lawScore: number;
  jacobRung: bigint;
  aresArmed: boolean;
  genesisActivated: boolean;
  patentCount: bigint;
  sacesiTarget: number;
  regime: string;
  mthBalance: bigint;
  gtkBalance: bigint;
  mrcBalance: bigint;
  novelty: number;
  miningOutput: number;
  novaHealth: number;
}
interface QuantumState {
  parallax: number;
  entangla: number;
  bypass: number;
  resonex: number;
  chrono: number;
  veritas: number;
  novelty: number;
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
interface AuditEntry {
  beat: bigint;
  eventType: string;
  detail: string;
  timestamp: bigint;
}

// ─── Loading Gate ────────────────────────────────────────────────────────────

function LoadingGate() {
  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center"
      style={{ background: "oklch(0.08 0.01 240)" }}
      data-ocid="auth.loading_state"
    >
      <div className="relative">
        <div
          className="w-16 h-16 border animate-beat"
          style={{
            borderColor: "oklch(0.78 0.15 85 / 0.3)",
            boxShadow: "0 0 40px oklch(0.78 0.15 85 / 0.15)",
          }}
        />
        <div
          className="absolute"
          style={{
            width: 16,
            height: 16,
            backgroundColor: "oklch(0.78 0.15 85 / 0.8)",
            boxShadow: "0 0 20px oklch(0.78 0.15 85 / 0.6)",
            top: "50%",
            left: "50%",
            transform: "translate(-50%,-50%)",
          }}
        />
      </div>
      <div
        className="font-mono text-[9px] tracking-[0.5em] mt-6"
        style={{ color: "oklch(0.55 0.02 240)" }}
      >
        SUBSTRATE INITIALIZING
      </div>
    </div>
  );
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────

function AuthGate({ onLogin }: { onLogin: () => void }) {
  return (
    <div
      className="min-h-screen flex items-center justify-center px-6"
      style={{
        background: "oklch(0.08 0.01 240)",
        backgroundImage:
          "radial-gradient(ellipse at 50% 0%, oklch(0.14 0.05 85 / 0.25) 0%, transparent 70%)",
      }}
      data-ocid="auth.dialog"
    >
      {/* Grid overlay */}
      <div
        className="fixed inset-0 pointer-events-none"
        style={{
          backgroundImage:
            "linear-gradient(oklch(0.78 0.15 85 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.15 85 / 0.02) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="relative z-10 flex flex-col items-center text-center max-w-sm w-full"
      >
        {/* Animated rings */}
        <div className="relative w-24 h-24 mb-8 flex items-center justify-center">
          <div
            className="absolute inset-0 border animate-beat"
            style={{
              borderColor: "oklch(0.78 0.15 85 / 0.35)",
              boxShadow: "0 0 40px oklch(0.78 0.15 85 / 0.12)",
            }}
          />
          <div
            className="absolute inset-3 border"
            style={{ borderColor: "oklch(0.78 0.15 85 / 0.18)" }}
          />
          <div
            className="w-8 h-8"
            style={{
              backgroundColor: "oklch(0.78 0.15 85 / 0.8)",
              boxShadow: "0 0 28px oklch(0.78 0.15 85 / 0.5)",
            }}
          />
        </div>

        <div
          className="font-display font-bold text-3xl tracking-[0.4em] mb-2"
          style={{
            color: "oklch(0.95 0.02 240)",
            textShadow: "0 0 30px oklch(0.78 0.15 85 / 0.3)",
          }}
        >
          PARALLAX
        </div>
        <div
          className="font-mono text-[9px] tracking-[0.3em] mb-2"
          style={{ color: "oklch(0.55 0.02 240)" }}
        >
          SOVEREIGN INTELLIGENCE ORGANISM
        </div>
        <div
          className="font-mono text-[8px] tracking-[0.2em] mb-8"
          style={{ color: "oklch(0.45 0.02 240)" }}
        >
          ALFREDO MEDINA HERNANDEZ · CREATOR · 2026
        </div>

        <motion.button
          type="button"
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onLogin}
          data-ocid="auth.primary_button"
          className="w-full py-3.5 font-mono text-xs tracking-[0.3em] border transition-all"
          style={{
            borderColor: "oklch(0.78 0.15 85 / 0.6)",
            color: "oklch(0.78 0.15 85)",
            background: "oklch(0.78 0.15 85 / 0.05)",
            boxShadow: "0 0 20px oklch(0.78 0.15 85 / 0.12)",
          }}
        >
          AUTHENTICATE
        </motion.button>

        <div
          className="mt-6 font-mono text-[7px] tracking-widest"
          style={{ color: "oklch(0.35 0.02 240)" }}
        >
          PARALLAX ORGANISM · CREATOR ACCESS REQUIRED
        </div>
      </motion.div>
    </div>
  );
}

// ─── Main App ────────────────────────────────────────────────────────────────

export default function App() {
  const { identity, login, isInitializing } = useInternetIdentity();
  const { actor } = useActor();
  const schumannData = useSchumannState();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();

  const [activeTab, setActiveTab] = useState<TabId>("substrate");
  const [showLanding, setShowLanding] = useState(true);
  const [loading, setLoading] = useState(true);

  // Live data state
  const [shell3State, setShell3State] = useState<Shell3State | null>(null);
  const [shell3Nodes, setShell3Nodes] = useState<number[]>([]);
  const [fullState, setFullState] = useState<FullState | null>(null);
  const [quantumState, setQuantumState] = useState<QuantumState | null>(null);
  const [axisState, setAxisState] = useState<AxisState | null>(null);
  const [brainSignals, setBrainSignals] = useState<BrainSignals | null>(null);
  const [auditLog, setAuditLog] = useState<AuditEntry[]>([]);
  const [kalmanPredictions, setKalmanPredictions] = useState<number[]>([]);

  const principalSetRef = useRef(false);

  useEffect(() => {
    if (!actor) return;

    async function fetchAll() {
      if (!actor) return;
      const a = actor as any;
      try {
        const [s3, fs, qs, bs, al] = await Promise.all([
          a.getShell3State
            ? a.getShell3State().catch(() => null)
            : Promise.resolve(null),
          a.px_getFullState
            ? a.px_getFullState().catch(() => null)
            : Promise.resolve(null),
          a.px_getQuantumState
            ? a.px_getQuantumState().catch(() => null)
            : Promise.resolve(null),
          (actor as any).getBrainSignals().catch(() => null),
          a.px_getAuditLog
            ? a.px_getAuditLog(20n).catch(() => [])
            : (actor as any).getAuditLog().catch(() => []),
        ]);
        if (s3) setShell3State(s3);
        if (fs) setFullState(fs);
        if (qs) setQuantumState(qs);
        if (bs) setBrainSignals(bs);
        if (al) setAuditLog(al as AuditEntry[]);
        setLoading(false);

        // Secondary fetches — non-critical
        const [nodes, kalman, axis] = await Promise.all([
          a.getShell3Nodes
            ? a.getShell3Nodes(0n, 64n).catch(() => [])
            : Promise.resolve([]),
          a.getKalmanPredictions
            ? a.getKalmanPredictions(0n, 64n).catch(() => [])
            : Promise.resolve([]),
          a.getAxisState
            ? a.getAxisState().catch(() => null)
            : Promise.resolve(null),
        ]);
        if ((nodes as number[]).length > 0) setShell3Nodes(nodes as number[]);
        if ((kalman as number[]).length > 0)
          setKalmanPredictions(kalman as number[]);
        if (axis) setAxisState(axis);
      } catch {
        setLoading(false);
      }
    }

    fetchAll();
    const interval = setInterval(fetchAll, 3000);
    return () => clearInterval(interval);
  }, [actor]);

  // Set creator principal once
  useEffect(() => {
    if (isAuthenticated && actor && !principalSetRef.current) {
      principalSetRef.current = true;
      (actor as any).setCreatorPrincipal().catch(() => {});
    }
  }, [isAuthenticated, actor]);

  if (isInitializing) return <LoadingGate />;
  // SCHOOL tab is publicly accessible — Bronze free tier, no login required.
  // Teacher/admin panel inside SchoolTab handles its own auth gate.
  if (!isAuthenticated && activeTab !== "school")
    return <AuthGate onLogin={login} />;
  if (showLanding && isAuthenticated)
    return <LandingPage onEnterDashboard={() => setShowLanding(false)} />;

  const beat = fullState ? Number(fullState.beat) : 0;
  const forma = fullState?.formaCapital ?? 0;

  // Accent color per tab
  const getAccentColor = (tabId: TabId) => {
    if (tabId === "exchange" || tabId === "treasury" || tabId === "wallet")
      return "oklch(0.78 0.15 85)";
    if (tabId === "forma") return "oklch(0.72 0.16 200)";
    if (tabId === "vael") return "oklch(0.55 0.22 25)";
    if (tabId === "bank") return "oklch(0.72 0.18 145)";
    if (tabId === "nodes") return "oklch(0.78 0.18 190)";
    if (tabId === "wyoming") return "oklch(0.85 0.18 85)";
    if (tabId === "school") return "oklch(0.85 0.18 195)";
    if (tabId === "protocols") return "oklch(0.78 0.15 85)";
    if (tabId === "birth-ai") return "oklch(0.65 0.20 30)";
    if (tabId === "builder") return "oklch(0.65 0.18 145)";
    if (tabId === "models") return "oklch(0.78 0.15 85)";
    if (tabId === "nova") return "oklch(0.82 0.18 75)";
    return "oklch(0.65 0.20 290)";
  };

  return (
    <div
      className="min-h-screen text-foreground flex"
      style={{
        background: "oklch(0.08 0.01 240)",
        backgroundImage:
          "radial-gradient(ellipse at 50% 0%, oklch(0.12 0.04 85 / 0.08) 0%, transparent 60%)",
      }}
    >
      {/* ── Left Rail Navigation ─────────────────────────────────────────── */}
      <nav
        className="hidden md:flex flex-col w-[200px] shrink-0 border-r"
        style={{
          background: "rgba(5,6,9,0.97)",
          backdropFilter: "blur(20px)",
          borderColor: "oklch(0.20 0.02 240)",
        }}
        aria-label="Primary navigation"
      >
        {/* Logo */}
        <div
          className="px-5 py-5 border-b"
          style={{ borderColor: "oklch(0.20 0.02 240)" }}
        >
          <div
            className="font-display font-bold text-base tracking-[0.3em]"
            style={{
              color: "oklch(0.95 0.02 240)",
              textShadow: "0 0 20px oklch(0.78 0.15 85 / 0.2)",
            }}
          >
            PARALLAX
          </div>
          <div
            className="font-mono text-[7px] tracking-[0.2em] mt-0.5"
            style={{ color: "oklch(0.40 0.02 240)" }}
          >
            SOVEREIGN ORGANISM
          </div>
        </div>

        {/* Tab items */}
        <div className="flex-1 py-3 overflow-y-auto">
          {TABS.map((tab) => {
            const active = activeTab === tab.id;
            const accentColor = getAccentColor(tab.id);
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => setActiveTab(tab.id)}
                data-ocid={`nav.${tab.id}.link`}
                className="w-full flex items-center gap-3 px-5 py-2.5 transition-all relative group"
                style={{
                  background: active
                    ? `${accentColor.replace(")", " / 0.08)")}`
                    : "transparent",
                  borderLeft: active
                    ? `2px solid ${accentColor}`
                    : "2px solid transparent",
                }}
              >
                <span
                  className="font-mono text-sm w-6 text-center shrink-0"
                  style={{
                    color: active ? accentColor : "oklch(0.30 0.02 240)",
                  }}
                >
                  {tab.icon}
                </span>
                <span
                  className="font-mono text-[9px] tracking-[0.2em]"
                  style={{
                    color: active
                      ? "oklch(0.95 0.02 240)"
                      : "oklch(0.42 0.02 240)",
                  }}
                >
                  {tab.label}
                </span>
                {active && (
                  <div
                    className="absolute right-3 w-1 h-1"
                    style={{
                      backgroundColor: accentColor,
                      boxShadow: `0 0 6px ${accentColor}`,
                    }}
                  />
                )}
              </button>
            );
          })}
        </div>

        {/* Bottom: Heartbeat + FORMA */}
        <div
          className="border-t p-4 space-y-3"
          style={{ borderColor: "oklch(0.20 0.02 240)" }}
        >
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-1"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              HEARTBEAT
            </div>
            <div className="flex items-center gap-2">
              <div
                className="w-1.5 h-1.5 animate-beat"
                style={{
                  backgroundColor: "oklch(0.78 0.15 85)",
                  boxShadow: "0 0 6px oklch(0.78 0.15 85 / 0.8)",
                }}
              />
              <span
                className="font-mono text-xs tabular-nums"
                style={{ color: "oklch(0.78 0.15 85)" }}
              >
                {beat.toLocaleString()}
              </span>
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-1"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              FORMA CAPITAL
            </div>
            <div
              className="font-mono text-xs tabular-nums"
              style={{ color: "oklch(0.65 0.18 145)" }}
            >
              &#x0191; {forma.toFixed(2)}
            </div>
          </div>
          <div
            className="font-mono text-[7px] tracking-[0.2em]"
            style={{
              color: loading
                ? "oklch(0.55 0.22 25 / 0.7)"
                : "oklch(0.65 0.18 145 / 0.8)",
            }}
          >
            {loading ? "● CONNECTING" : "● LIVE"}
          </div>
        </div>
      </nav>

      {/* ── Main Content ─────────────────────────────────────────────────── */}
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <header
          className="flex items-center justify-between px-6 py-3 border-b"
          style={{
            background: "rgba(5,6,9,0.85)",
            backdropFilter: "blur(12px)",
            borderColor: "oklch(0.20 0.02 240)",
          }}
        >
          <div className="flex items-center gap-4">
            <div
              className="md:hidden font-mono text-xs"
              style={{ color: "oklch(0.78 0.15 85)" }}
            >
              \u25c8
            </div>
            <span
              className="font-mono text-[9px] tracking-[0.3em]"
              style={{ color: "oklch(0.50 0.02 240)" }}
            >
              {TABS.find((t) => t.id === activeTab)?.label}
            </span>
          </div>
          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-1.5">
              <span
                className="font-mono text-[8px]"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                COHERENCE
              </span>
              <span
                className="font-mono text-xs tabular-nums"
                style={{
                  color: "oklch(0.78 0.15 85)",
                  textShadow: "0 0 8px oklch(0.78 0.15 85 / 0.4)",
                }}
              >
                {(fullState?.coherence ?? 0).toFixed(4)}
              </span>
            </div>
            <div className="hidden sm:flex items-center gap-1.5">
              <span
                className="font-mono text-[8px]"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                REGIME
              </span>
              <span
                className="font-mono text-[9px] px-1.5 py-0.5"
                style={{
                  color: "oklch(0.65 0.18 145)",
                  border: "1px solid oklch(0.65 0.18 145 / 0.25)",
                }}
              >
                {fullState?.regime ?? "\u2014"}
              </span>
            </div>
            <div
              className="w-1.5 h-1.5 animate-beat"
              style={{
                backgroundColor: loading
                  ? "oklch(0.55 0.22 25)"
                  : "oklch(0.65 0.18 145)",
                boxShadow: loading
                  ? "0 0 6px oklch(0.55 0.22 25 / 0.6)"
                  : "0 0 6px oklch(0.65 0.18 145 / 0.6)",
              }}
            />
          </div>
        </header>

        {/* Tab content */}
        <div className="flex-1 overflow-auto p-5">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.2 }}
            >
              {activeTab === "substrate" && (
                <SubstrateTab
                  shell3State={shell3State}
                  shell3Nodes={shell3Nodes}
                  fullState={fullState}
                  loading={loading}
                  schumannState={schumannData?.data ?? null}
                />
              )}
              {activeTab === "council" && <CouncilTab />}
              {activeTab === "quantum" && (
                <QuantumTab
                  quantumState={quantumState}
                  shell3State={shell3State}
                  axisState={axisState}
                  brainSignals={brainSignals}
                  loading={loading}
                />
              )}
              {activeTab === "prediction" && (
                <PredictionTab
                  kalmanPredictions={kalmanPredictions}
                  shell3State={shell3State}
                  loading={loading}
                />
              )}
              {activeTab === "prometheus" && (
                <PrometheusTab auditLog={auditLog} loading={loading} />
              )}
              {activeTab === "lexis" && <LexisPrimeTab />}
              {activeTab === "vael" && <VaelTab />}
              {activeTab === "exchange" && <ExchangeTab />}
              {activeTab === "wallet" && <ThesaurusParallaxiTab />}
              {activeTab === "treasury" && <TreasuryTab />}
              {activeTab === "forma" && <FormaTab />}
              {activeTab === "admin" && <AdminTab fullState={fullState} />}
              {activeTab === "bank" && <BankTab />}
              {activeTab === "nodes" && <NodesTab />}
              {activeTab === "wyoming" && <WyomingTab />}
              {activeTab === "school" && <SchoolTab />}
              {activeTab === "protocols" && <ProtocolTab />}
              {activeTab === "birth-ai" && <BirthAiTab />}
              {activeTab === "builder" && <BuilderTab />}
              {activeTab === "models" && <ModelsTab />}
              {activeTab === "nova" && <NOVATab />}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Mobile bottom nav */}
        <nav
          className="md:hidden flex border-t overflow-x-auto"
          style={{
            background: "rgba(5,6,9,0.97)",
            borderColor: "oklch(0.20 0.02 240)",
          }}
        >
          {TABS.map((tab) => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              data-ocid={`mobile.${tab.id}.link`}
              className="flex-1 min-w-[44px] py-3 flex flex-col items-center gap-0.5"
              style={{
                color:
                  activeTab === tab.id
                    ? getAccentColor(tab.id)
                    : "oklch(0.30 0.02 240)",
              }}
            >
              <span className="text-xs">{tab.icon}</span>
              <span className="font-mono text-[6px] tracking-wider">
                {tab.short}
              </span>
            </button>
          ))}
        </nav>

        {/* Footer */}
        <footer
          className="hidden md:flex border-t px-6 py-2 justify-between items-center"
          style={{ borderColor: "oklch(0.20 0.02 240)" }}
        >
          <span
            className="font-mono text-[7px] tracking-widest"
            style={{ color: "oklch(0.30 0.02 240)" }}
          >
            PARALLAX · ALFREDO MEDINA HERNANDEZ · SOVEREIGN NODE
          </span>
          <span
            className="font-mono text-[7px]"
            style={{ color: "oklch(0.25 0.01 240)" }}
          >
            &copy; {new Date().getFullYear()} &middot;{" "}
            <a
              href={`https://caffeine.ai?utm_source=caffeine-footer&utm_medium=referral&utm_content=${encodeURIComponent(window.location.hostname)}`}
              target="_blank"
              rel="noopener noreferrer"
              className="hover:opacity-70 transition-opacity"
            >
              caffeine.ai
            </a>
          </span>
        </footer>
      </main>

      <Toaster richColors position="top-right" />
    </div>
  );
}
