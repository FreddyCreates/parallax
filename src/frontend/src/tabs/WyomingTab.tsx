/**
 * WyomingTab.tsx — WYOMING MASTER CHARTER
 * FRNT Settlement Demo · Legislative Timeline · Partnership Grid
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useState } from "react";
import { useActor } from "../hooks/useActor";

// ── Color palette (PARALLAX OKLCH cyan 85° accent) ─────────────────────────
const C = {
  cyan: "oklch(0.85 0.18 85)",
  cyanDim: "oklch(0.85 0.18 85 / 0.6)",
  cyanFaint: "oklch(0.85 0.18 85 / 0.07)",
  cyanBorder: "oklch(0.85 0.18 85 / 0.28)",
  green: "oklch(0.68 0.17 145)",
  greenFaint: "oklch(0.68 0.17 145 / 0.08)",
  greenBorder: "oklch(0.68 0.17 145 / 0.35)",
  amber: "oklch(0.72 0.18 65)",
  amberFaint: "oklch(0.72 0.18 65 / 0.08)",
  amberBorder: "oklch(0.72 0.18 65 / 0.35)",
  red: "oklch(0.55 0.22 25)",
  redFaint: "oklch(0.55 0.22 25 / 0.08)",
  redBorder: "oklch(0.55 0.22 25 / 0.35)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  dim: "oklch(0.28 0.03 270)",
  card: "oklch(0.11 0.02 240)",
  cardBorder: "oklch(0.20 0.02 240)",
};

// ── Types ──────────────────────────────────────────────────────────────────
interface FrntDemo {
  visaSettlementMs: number;
  phantomSettlementMs: number;
  visaFeeBps: number;
  phantomFeeBps: number;
  demoActive: boolean;
  lastRunMs: number;
  visaBottleneckSolved: boolean;
}

interface MilestoneStatus {
  Pending?: null;
  InProgress?: null;
  Complete?: null;
  Critical?: null;
}

interface Milestone {
  id: string;
  title: string;
  deadlineMs: number;
  status: MilestoneStatus;
  notes: string;
}

interface LegislativeTimeline {
  milestones: Milestone[];
  hardwareDeadlineMs: number;
  billDeadlineMs: number;
  progressPct: number;
}

interface Partnership {
  name: string;
  type: string;
  contact: string;
  status: string;
  notes: string;
}

interface Facility {
  address: string;
  city: string;
  vaultGrade: boolean;
  internetBackbone: boolean;
  publicPower: boolean;
  notes: string;
}

interface GrantRecord {
  name: string;
  grantType: string;
  amountUsd: number;
  status: string;
  deadlineMs: number;
}

interface NodeProvider {
  entity: string;
  cheyenneNodes: number;
  lincolnNodes: number;
  gen3Ready: boolean;
  whitelisted: boolean;
  notes: string;
}

interface WyomingState {
  frntDemo: FrntDemo;
  nodeProvider: NodeProvider;
  legislative: LegislativeTimeline;
  partnerships: Partnership[];
  facility: Facility;
  grants: GrantRecord[];
  charterGenesisHash: string;
  lastUpdatedMs: number;
}

// ── Hardcoded fallback data ────────────────────────────────────────────────
const DEFAULT_STATE: WyomingState = {
  frntDemo: {
    visaSettlementMs: 900000,
    phantomSettlementMs: 300,
    visaFeeBps: 400,
    phantomFeeBps: 0,
    demoActive: false,
    lastRunMs: 0,
    visaBottleneckSolved: true,
  },
  nodeProvider: {
    entity: "Bad Marine LLC",
    cheyenneNodes: 0,
    lincolnNodes: 0,
    gen3Ready: true,
    whitelisted: false,
    notes: "First to Boot · Veteran-owned sovereign infrastructure",
  },
  legislative: {
    milestones: [
      {
        id: "hw-visible",
        title: "Hardware Visible at Federal Reserve Vault",
        deadlineMs: new Date("2026-11-01").getTime(),
        status: { Pending: null },
        notes: "Gen3 nodes at 134 S 13th St, Lincoln NE",
      },
      {
        id: "bill-ready",
        title: "Wyoming/Nebraska Unicameral Bill Ready",
        deadlineMs: new Date("2027-01-01").getTime(),
        status: { Pending: null },
        notes: "Full legislature blessing for state-wide adoption",
      },
      {
        id: "frnt-demo",
        title: "FRNT/ICP Liquidity Pool Demo Live",
        deadlineMs: new Date("2026-07-01").getTime(),
        status: { InProgress: null },
        notes: "Instant settlement bypassing Visa/Kraken",
      },
      {
        id: "andy-meeting",
        title: "Meeting with Andy — Wyoming SPDI Regulators",
        deadlineMs: new Date("2026-06-01").getTime(),
        status: { InProgress: null },
        notes: "Cheyenne · Demonstrate FRNT settlement speed",
      },
      {
        id: "unl-compute",
        title: "UNL Agentic AI Infrastructure Deployed",
        deadlineMs: new Date("2026-09-01").getTime(),
        status: { Pending: null },
        notes: "Sovereign Gen3 compute for UNL AI Institute",
      },
      {
        id: "nebraska-go",
        title: "Nebraska Partnership GO",
        deadlineMs: new Date("2027-01-15").getTime(),
        status: { Pending: null },
        notes: "Senators Bosn & Ballard · State agency rollout",
      },
    ],
    hardwareDeadlineMs: new Date("2026-11-01").getTime(),
    billDeadlineMs: new Date("2027-01-01").getTime(),
    progressPct: 18,
  },
  partnerships: [
    {
      name: "Wyoming SPDI — Andy Vetor",
      type: "STATE_REGULATOR",
      contact: "Cheyenne, WY",
      status: "target",
      notes: "FRNT settlement demo · SPDI banking law · direct-minting model",
    },
    {
      name: "Nebraska Digital Banking",
      type: "STATE_PARTNER",
      contact: "Senators Bosn & Ballard",
      status: "monitoring",
      notes: "Lincoln nodes · 2027 Unicameral bill · state agency adoption",
    },
    {
      name: "UNL AI Institute",
      type: "UNIVERSITY",
      contact: "Lincoln, NE",
      status: "interested",
      notes:
        "Agentic AI curriculum · sovereign Gen3 compute · Univ of Kansas joining",
    },
    {
      name: "Bad Marine LLC",
      type: "NODE_PROVIDER",
      contact: "Veteran-Owned",
      status: "active",
      notes: "First to Boot · Gen3 · Cheyenne + Lincoln vault facility",
    },
  ],
  facility: {
    address: "134 S 13th St",
    city: "Lincoln, NE 68508",
    vaultGrade: true,
    internetBackbone: true,
    publicPower: true,
    notes:
      "Federal Reserve Vault · Bank-grade security · Publicly owned electricity — cheapest in nation",
  },
  grants: [
    {
      name: "E-Rate Education Tech",
      grantType: "FEDERAL",
      amountUsd: 2500000,
      status: "eligible",
      deadlineMs: new Date("2026-09-01").getTime(),
    },
    {
      name: "Title IV Innovation",
      grantType: "FEDERAL",
      amountUsd: 1800000,
      status: "eligible",
      deadlineMs: new Date("2026-08-01").getTime(),
    },
    {
      name: "TEA Innovation Grant",
      grantType: "STATE_TX",
      amountUsd: 750000,
      status: "targeting",
      deadlineMs: new Date("2026-10-01").getTime(),
    },
    {
      name: "NSF AI Infrastructure",
      grantType: "FEDERAL",
      amountUsd: 3200000,
      status: "eligible",
      deadlineMs: new Date("2026-12-01").getTime(),
    },
    {
      name: "Nebraska OCIO Digital",
      grantType: "STATE_NE",
      amountUsd: 600000,
      status: "monitoring",
      deadlineMs: new Date("2027-01-01").getTime(),
    },
  ],
  charterGenesisHash: "WYO-CHARTER-PARALLAX-2026",
  lastUpdatedMs: Date.now(),
};

// ── Helpers ─────────────────────────────────────────────────────────────────
function fmtMs(ms: number): string {
  const d = new Date(ms);
  return d.toLocaleDateString("en-US", { month: "short", year: "numeric" });
}

function fmtAmount(usd: number): string {
  if (usd >= 1_000_000) return `$${(usd / 1_000_000).toFixed(1)}M`;
  if (usd >= 1_000) return `$${(usd / 1_000).toFixed(0)}K`;
  return `$${usd}`;
}

function timeAgo(ms: number): string {
  if (ms === 0) return "never";
  const diff = Date.now() - ms;
  const s = Math.floor(diff / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  return `${h}h ago`;
}

function daysUntil(ms: number): number {
  return Math.max(0, Math.ceil((ms - Date.now()) / 86400000));
}

function getMilestoneStatus(
  s: MilestoneStatus,
): "Pending" | "InProgress" | "Complete" | "Critical" {
  if (s.Complete != null) return "Complete";
  if (s.InProgress != null) return "InProgress";
  if (s.Critical != null) return "Critical";
  return "Pending";
}

// ── Section Header ───────────────────────────────────────────────────────────
function SectionHeader({ label, sub }: { label: string; sub?: string }) {
  return (
    <div
      className="px-5 py-4 border-b"
      style={{
        borderColor: C.cyanBorder,
        background: "oklch(0.85 0.18 85 / 0.04)",
        backgroundImage:
          "linear-gradient(oklch(0.85 0.18 85 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.85 0.18 85 / 0.02) 1px, transparent 1px)",
        backgroundSize: "24px 24px",
      }}
    >
      <div
        className="font-mono text-xs tracking-[0.4em]"
        style={{ color: C.cyan }}
      >
        {label}
      </div>
      {sub && (
        <div
          className="font-mono text-[8px] tracking-[0.2em] mt-1"
          style={{ color: C.muted }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

// ── FRNT Settlement Demo ─────────────────────────────────────────────────────
function FrntSettlementDemo({
  demo,
  onRunDemo,
}: { demo: FrntDemo; onRunDemo: () => void }) {
  const [running, setRunning] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [flowStep, setFlowStep] = useState(0);

  async function handleRun() {
    setRunning(true);
    setFlowStep(0);
    setShowSuccess(false);
    // Animate the flow steps
    for (let i = 1; i <= 3; i++) {
      await new Promise((r) => setTimeout(r, 80));
      setFlowStep(i);
    }
    onRunDemo();
    await new Promise((r) => setTimeout(r, 300));
    setShowSuccess(true);
    setRunning(false);
    setTimeout(() => setShowSuccess(false), 4000);
  }

  const visaSecs =
    demo.visaSettlementMs > 0 ? Math.floor(demo.visaSettlementMs / 1000) : 900;
  const visaMin = Math.floor(visaSecs / 60);
  const phantomMs =
    demo.phantomSettlementMs > 0 ? demo.phantomSettlementMs : 300;

  return (
    <div className="space-y-4">
      {/* Two comparison panels */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {/* VISA/KRAKEN */}
        <motion.div
          initial={{ opacity: 0, x: -12 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.05 }}
          className="relative border overflow-hidden"
          style={{ background: C.card, borderColor: C.redBorder }}
          data-ocid="wyoming.frnt.visa_panel"
        >
          <div
            className="absolute inset-0 pointer-events-none"
            style={{ background: "oklch(0.55 0.22 25 / 0.03)" }}
          />
          <div className="relative z-10 p-5">
            <div className="flex items-center gap-2 mb-4">
              <span className="font-mono text-xl" style={{ color: C.red }}>
                ⛓
              </span>
              <div>
                <div
                  className="font-mono text-[8px] tracking-[0.4em]"
                  style={{ color: C.red }}
                >
                  VISA / KRAKEN ROUTE
                </div>
                <div
                  className="font-mono text-[7px] tracking-[0.2em]"
                  style={{ color: C.muted }}
                >
                  CURRENT WYOMING FRNT INFRASTRUCTURE
                </div>
              </div>
            </div>
            <div className="space-y-3">
              <div>
                <div
                  className="font-mono text-[7px] tracking-[0.3em] mb-1"
                  style={{ color: C.muted }}
                >
                  SETTLEMENT TIME
                </div>
                <div
                  className="font-mono text-3xl font-bold tabular-nums"
                  style={{ color: C.red }}
                >
                  {visaMin}+<span className="text-sm ml-1">min</span>
                </div>
              </div>
              <div>
                <div
                  className="font-mono text-[7px] tracking-[0.3em] mb-1"
                  style={{ color: C.muted }}
                >
                  TRANSACTION FEE
                </div>
                <div
                  className="font-mono text-2xl font-bold"
                  style={{ color: C.red }}
                >
                  {(demo.visaFeeBps / 100).toFixed(0)}–5%
                </div>
              </div>
              <div className="pt-2 space-y-1">
                {[
                  "Visa backend routing",
                  "Kraken exchange hop",
                  "3-5% fee remains",
                  "Friction on every tx",
                ].map((item) => (
                  <div
                    key={item}
                    className="flex items-center gap-2 font-mono text-[8px]"
                    style={{ color: C.muted }}
                  >
                    <span style={{ color: C.red }}>✗</span> {item}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>

        {/* PHANTOM/ICP */}
        <motion.div
          initial={{ opacity: 0, x: 12 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.1 }}
          className="relative border overflow-hidden"
          style={{ background: C.card, borderColor: C.greenBorder }}
          data-ocid="wyoming.frnt.phantom_panel"
        >
          <div
            className="absolute inset-0 pointer-events-none"
            style={{ background: "oklch(0.68 0.17 145 / 0.04)" }}
          />
          <div className="relative z-10 p-5">
            <div className="flex items-center gap-2 mb-4">
              <span className="font-mono text-xl" style={{ color: C.green }}>
                ⚡
              </span>
              <div>
                <div
                  className="font-mono text-[8px] tracking-[0.4em]"
                  style={{ color: C.green }}
                >
                  PHANTOM / ICP ROUTE
                </div>
                <div
                  className="font-mono text-[7px] tracking-[0.2em]"
                  style={{ color: C.muted }}
                >
                  PARALLAX SOVEREIGN SETTLEMENT
                </div>
              </div>
            </div>
            <div className="space-y-3">
              <div>
                <div
                  className="font-mono text-[7px] tracking-[0.3em] mb-1"
                  style={{ color: C.muted }}
                >
                  SETTLEMENT TIME
                </div>
                <div
                  className="font-mono text-3xl font-bold tabular-nums"
                  style={{ color: C.green }}
                >
                  {phantomMs}
                  <span className="text-sm ml-1">ms</span>
                </div>
              </div>
              <div>
                <div
                  className="font-mono text-[7px] tracking-[0.3em] mb-1"
                  style={{ color: C.muted }}
                >
                  TRANSACTION FEE
                </div>
                <div
                  className="font-mono text-2xl font-bold"
                  style={{ color: C.green }}
                >
                  0%
                </div>
              </div>
              <div className="pt-2 space-y-1">
                {[
                  "FRNT/ICP liquidity pool direct",
                  "ICPSwap native settlement",
                  "Zero fee — Phantom model",
                  "Bypasses Visa & Kraken entirely",
                ].map((item) => (
                  <div
                    key={item}
                    className="flex items-center gap-2 font-mono text-[8px]"
                    style={{ color: C.muted }}
                  >
                    <span style={{ color: C.green }}>✓</span> {item}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Animated flow + Run Demo */}
      <div
        className="border p-5 space-y-4"
        style={{ background: C.card, borderColor: C.cyanBorder }}
        data-ocid="wyoming.frnt.flow_card"
      >
        <div
          className="font-mono text-[8px] tracking-[0.4em]"
          style={{ color: C.cyan }}
        >
          TRANSACTION FLOW — PHANTOM ROUTE
        </div>
        <div className="flex items-center gap-2 flex-wrap justify-center font-mono text-[9px]">
          {[
            { label: "FRNT TOKEN", step: 1, id: "frnt" },
            { label: "→", step: 0, id: "arr1" },
            { label: "LIQUIDITY POOL", step: 2, id: "pool" },
            { label: "→", step: 0, id: "arr2" },
            { label: "ICP WALLET", step: 3, id: "wallet" },
          ].map((node) =>
            node.step === 0 ? (
              <span
                key={node.id}
                style={{ color: running && flowStep >= 1 ? C.cyan : C.dim }}
              >
                →
              </span>
            ) : (
              <motion.span
                key={node.id}
                animate={
                  running && flowStep >= node.step
                    ? {
                        scale: [1, 1.1, 1],
                        opacity: [0.5, 1, 1],
                      }
                    : {}
                }
                transition={{ duration: 0.2 }}
                className="px-3 py-1.5 border font-mono text-[8px] tracking-widest"
                style={{
                  borderColor:
                    running && flowStep >= node.step ? C.cyan : C.cardBorder,
                  color: running && flowStep >= node.step ? C.cyan : C.muted,
                  background:
                    running && flowStep >= node.step
                      ? C.cyanFaint
                      : "transparent",
                }}
              >
                {node.label}
              </motion.span>
            ),
          )}
        </div>

        <div className="flex items-center justify-between flex-wrap gap-3">
          <div className="font-mono text-[8px]" style={{ color: C.dim }}>
            Last Run: {timeAgo(demo.lastRunMs)}
          </div>
          <button
            type="button"
            onClick={handleRun}
            disabled={running}
            className="px-5 py-2.5 border font-mono text-[9px] tracking-[0.3em] transition-all disabled:opacity-60"
            style={{
              borderColor: C.cyanBorder,
              color: C.cyan,
              backgroundColor: C.cyanFaint,
              boxShadow: running
                ? "0 0 20px oklch(0.85 0.18 85 / 0.2)"
                : "none",
            }}
            data-ocid="wyoming.frnt.run_demo_button"
          >
            {running ? "⟳ RUNNING DEMO..." : "⚡ RUN SETTLEMENT DEMO"}
          </button>
        </div>

        <AnimatePresence>
          {showSuccess && (
            <motion.div
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="px-4 py-2.5 border font-mono text-[9px]"
              style={{
                backgroundColor: C.greenFaint,
                borderColor: C.greenBorder,
                color: C.green,
              }}
              data-ocid="wyoming.frnt.success_state"
            >
              ✓ SETTLEMENT COMPLETE IN {phantomMs}ms — VISA BOTTLENECK SOLVED
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

// ── Legislative Timeline ─────────────────────────────────────────────────────
function LegislativeTimeline({
  legislative,
}: { legislative: LegislativeTimeline }) {
  const hwDeadline =
    legislative.hardwareDeadlineMs || new Date("2026-11-01").getTime();
  const totalDays = Math.ceil(
    (hwDeadline - new Date("2026-01-01").getTime()) / 86400000,
  );
  const elapsed = Math.max(
    0,
    Math.ceil((Date.now() - new Date("2026-01-01").getTime()) / 86400000),
  );
  const progressPct = Math.min(100, Math.round((elapsed / totalDays) * 100));
  const daysLeft = daysUntil(hwDeadline);

  const statusConfig: Record<
    string,
    { color: string; border: string; bg: string; icon: string }
  > = {
    Complete: {
      color: C.green,
      border: C.greenBorder,
      bg: C.greenFaint,
      icon: "✓",
    },
    InProgress: {
      color: C.cyan,
      border: C.cyanBorder,
      bg: C.cyanFaint,
      icon: "◉",
    },
    Critical: { color: C.red, border: C.redBorder, bg: C.redFaint, icon: "⚠" },
    Pending: {
      color: C.muted,
      border: C.cardBorder,
      bg: "transparent",
      icon: "○",
    },
  };

  return (
    <div className="space-y-4">
      {/* Progress bar */}
      <div className="space-y-2">
        <div className="flex justify-between items-center">
          <div
            className="font-mono text-[8px] tracking-[0.3em]"
            style={{ color: C.muted }}
          >
            DAYS UNTIL NOV 2026 HARDWARE DEADLINE
          </div>
          <div
            className="font-mono text-sm font-bold tabular-nums"
            style={{ color: C.cyan }}
          >
            {daysLeft}d
          </div>
        </div>
        <div
          className="h-2 border"
          style={{
            background: "oklch(0.13 0.01 240)",
            borderColor: C.cardBorder,
          }}
        >
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${progressPct}%` }}
            transition={{ duration: 1.2, ease: "easeOut" }}
            className="h-full"
            style={{
              background:
                "linear-gradient(to right, oklch(0.68 0.17 145), oklch(0.85 0.18 85))",
            }}
          />
        </div>
        <div
          className="flex justify-between font-mono text-[7px]"
          style={{ color: C.dim }}
        >
          <span>JAN 2026</span>
          <span style={{ color: daysLeft < 60 ? C.red : C.muted }}>
            NOV 2026 · HARDWARE VISIBLE
          </span>
          <span>JAN 2027 · BILL READY</span>
        </div>
      </div>

      {/* Milestone list */}
      <div className="space-y-2" data-ocid="wyoming.milestones.list">
        {legislative.milestones.map((m, i) => {
          const status = getMilestoneStatus(m.status);
          const conf = statusConfig[status];
          const isInProgress = status === "InProgress";
          return (
            <motion.div
              key={m.id}
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              className="flex gap-3 p-3 border"
              style={{
                background: C.card,
                borderColor: isInProgress ? conf.border : C.cardBorder,
                borderLeft: `3px solid ${conf.color}`,
              }}
              data-ocid={`wyoming.milestone.item.${i + 1}`}
            >
              <motion.div
                animate={
                  isInProgress
                    ? { scale: [1, 1.3, 1], opacity: [1, 0.6, 1] }
                    : {}
                }
                transition={{ duration: 1.5, repeat: Number.POSITIVE_INFINITY }}
                className="font-mono text-base shrink-0 w-5 text-center mt-0.5"
                style={{ color: conf.color }}
              >
                {conf.icon}
              </motion.div>
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2 flex-wrap">
                  <div
                    className="font-mono text-[9px] tracking-[0.15em]"
                    style={{ color: C.text }}
                  >
                    {m.title}
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <span
                      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
                      style={{
                        color: conf.color,
                        borderColor: conf.border,
                        backgroundColor: conf.bg,
                      }}
                    >
                      {status.toUpperCase()}
                    </span>
                    <span
                      className="font-mono text-[8px] tabular-nums"
                      style={{ color: C.muted }}
                    >
                      {fmtMs(m.deadlineMs)}
                    </span>
                  </div>
                </div>
                {m.notes && (
                  <div
                    className="font-mono text-[7px] mt-1"
                    style={{ color: C.dim }}
                  >
                    {m.notes}
                  </div>
                )}
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

// ── Partnership Grid ─────────────────────────────────────────────────────────
function PartnershipGrid({ partnerships }: { partnerships: Partnership[] }) {
  const statusConfig: Record<
    string,
    { color: string; border: string; bg: string }
  > = {
    target: { color: C.cyan, border: C.cyanBorder, bg: C.cyanFaint },
    monitoring: { color: C.amber, border: C.amberBorder, bg: C.amberFaint },
    interested: {
      color: "oklch(0.72 0.17 155)",
      border: "oklch(0.72 0.17 155 / 0.3)",
      bg: "oklch(0.72 0.17 155 / 0.06)",
    },
    active: { color: C.green, border: C.greenBorder, bg: C.greenFaint },
  };

  return (
    <div
      className="grid grid-cols-1 sm:grid-cols-2 gap-4"
      data-ocid="wyoming.partnerships.section"
    >
      {partnerships.map((p, i) => {
        const sc = statusConfig[p.status] ?? statusConfig.monitoring;
        return (
          <motion.div
            key={p.name}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.07 }}
            className="border p-5"
            style={{ background: C.card, borderColor: C.cardBorder }}
            data-ocid={`wyoming.partnership.item.${i + 1}`}
          >
            <div className="flex items-start justify-between gap-2 mb-3">
              <div
                className="font-mono text-[9px] tracking-[0.15em]"
                style={{ color: C.text }}
              >
                {p.name}
              </div>
              <span
                className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest shrink-0"
                style={{
                  color: sc.color,
                  borderColor: sc.border,
                  backgroundColor: sc.bg,
                }}
              >
                {p.status.toUpperCase()}
              </span>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <span
                  className="font-mono text-[7px] tracking-widest"
                  style={{ color: C.muted }}
                >
                  TYPE
                </span>
                <span
                  className="font-mono text-[7px] px-1.5 py-0.5 border"
                  style={{
                    color: C.cyan,
                    borderColor: C.cyanBorder,
                    background: C.cyanFaint,
                  }}
                >
                  {p.type}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span
                  className="font-mono text-[7px] tracking-widest"
                  style={{ color: C.muted }}
                >
                  CONTACT
                </span>
                <span
                  className="font-mono text-[7px]"
                  style={{ color: p.contact ? C.dim : C.dim }}
                >
                  {p.contact || "—"}
                </span>
              </div>
              {p.notes && (
                <div
                  className="font-mono text-[7px] mt-2 pt-2 border-t leading-relaxed"
                  style={{ color: C.muted, borderColor: C.cardBorder }}
                >
                  {p.notes}
                </div>
              )}
            </div>
          </motion.div>
        );
      })}
    </div>
  );
}

// ── Facility Card ────────────────────────────────────────────────────────────
function FacilityCard({ facility }: { facility: Facility }) {
  const badges = [
    { icon: "🔒", label: "VAULT GRADE", active: facility.vaultGrade },
    {
      icon: "⚡",
      label: "INTERNET BACKBONE",
      active: facility.internetBackbone,
    },
    { icon: "⚡", label: "PUBLIC POWER", active: facility.publicPower },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="border p-6"
      style={{ background: C.card, borderColor: C.cyanBorder }}
      data-ocid="wyoming.facility.card"
    >
      <div className="flex flex-col sm:flex-row sm:items-start gap-4">
        <div className="flex-1">
          <div
            className="font-mono text-[8px] tracking-[0.4em] mb-2"
            style={{ color: C.cyan }}
          >
            SOVEREIGN FACILITY — FEDERAL RESERVE VAULT
          </div>
          <div
            className="font-mono text-lg font-bold"
            style={{ color: C.text }}
          >
            {facility.address}
          </div>
          <div className="font-mono text-sm" style={{ color: C.muted }}>
            {facility.city}
          </div>
          {facility.notes && (
            <div
              className="font-mono text-[8px] mt-3 leading-relaxed"
              style={{ color: C.dim }}
            >
              {facility.notes}
            </div>
          )}
        </div>
        <div className="flex flex-row sm:flex-col gap-2">
          {badges.map((b) => (
            <div
              key={b.label}
              className="px-3 py-2 border flex items-center gap-2 font-mono text-[7px] tracking-widest"
              style={{
                borderColor: b.active ? C.cyanBorder : C.cardBorder,
                background: b.active ? C.cyanFaint : "transparent",
                color: b.active ? C.cyan : C.dim,
              }}
            >
              <span>{b.icon}</span>
              <span>{b.label}</span>
            </div>
          ))}
        </div>
      </div>
    </motion.div>
  );
}

// ── Grant Pipeline ─────────────────────────────────────────────────────────
function GrantPipeline({ grants }: { grants: GrantRecord[] }) {
  const total = grants.reduce((s, g) => s + g.amountUsd, 0);
  const statusConfig: Record<
    string,
    { color: string; border: string; bg: string }
  > = {
    eligible: { color: C.green, border: C.greenBorder, bg: C.greenFaint },
    targeting: { color: C.cyan, border: C.cyanBorder, bg: C.cyanFaint },
    monitoring: { color: C.amber, border: C.amberBorder, bg: C.amberFaint },
    applied: {
      color: "oklch(0.72 0.17 270)",
      border: "oklch(0.72 0.17 270 / 0.3)",
      bg: "oklch(0.72 0.17 270 / 0.06)",
    },
    received: { color: C.green, border: C.greenBorder, bg: C.greenFaint },
  };

  return (
    <div className="space-y-3" data-ocid="wyoming.grants.section">
      <div className="overflow-x-auto">
        <table
          className="w-full font-mono text-[9px]"
          style={{ borderCollapse: "collapse" }}
        >
          <thead>
            <tr style={{ borderBottom: `1px solid ${C.cardBorder}` }}>
              {["NAME", "TYPE", "AMOUNT", "STATUS", "DEADLINE"].map((h) => (
                <th
                  key={h}
                  className="text-left px-3 py-2.5 tracking-[0.2em] whitespace-nowrap"
                  style={{ color: C.muted }}
                >
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {grants.map((g, i) => {
              const sc = statusConfig[g.status] ?? statusConfig.monitoring;
              return (
                <motion.tr
                  key={g.name}
                  initial={{ opacity: 0, x: -6 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.04 }}
                  style={{
                    borderBottom: "1px solid oklch(0.20 0.02 240 / 0.5)",
                  }}
                  data-ocid={`wyoming.grant.item.${i + 1}`}
                >
                  <td className="px-3 py-2.5 max-w-[160px]">
                    <span className="truncate block" style={{ color: C.text }}>
                      {g.name}
                    </span>
                  </td>
                  <td className="px-3 py-2.5">
                    <span
                      className="font-mono text-[7px] px-1.5 py-0.5 border"
                      style={{
                        color: C.cyan,
                        borderColor: C.cyanBorder,
                        background: C.cyanFaint,
                      }}
                    >
                      {g.grantType}
                    </span>
                  </td>
                  <td
                    className="px-3 py-2.5 tabular-nums"
                    style={{ color: C.cyan }}
                  >
                    {fmtAmount(g.amountUsd)}
                  </td>
                  <td className="px-3 py-2.5">
                    <span
                      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
                      style={{
                        color: sc.color,
                        borderColor: sc.border,
                        backgroundColor: sc.bg,
                      }}
                    >
                      {g.status.toUpperCase()}
                    </span>
                  </td>
                  <td
                    className="px-3 py-2.5 whitespace-nowrap"
                    style={{ color: C.muted }}
                  >
                    {fmtMs(g.deadlineMs)}
                  </td>
                </motion.tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <div
        className="flex items-center justify-between px-4 py-3 border"
        style={{ background: C.cyanFaint, borderColor: C.cyanBorder }}
      >
        <div
          className="font-mono text-[8px] tracking-[0.3em]"
          style={{ color: C.muted }}
        >
          TOTAL GRANT OPPORTUNITY
        </div>
        <div
          className="font-mono text-lg font-bold tabular-nums"
          style={{ color: C.cyan }}
        >
          {fmtAmount(total)}
        </div>
      </div>
    </div>
  );
}

// ── Node Provider Card ───────────────────────────────────────────────────────
function NodeProviderCard({ provider }: { provider: NodeProvider }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="border p-5 space-y-4"
      style={{ background: C.card, borderColor: C.cyanBorder }}
      data-ocid="wyoming.node_provider.card"
    >
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div>
          <div
            className="font-mono text-[8px] tracking-[0.4em] mb-1"
            style={{ color: C.cyan }}
          >
            NODE PROVIDER
          </div>
          <div
            className="font-mono text-base font-bold"
            style={{ color: C.text }}
          >
            {provider.entity}
          </div>
          <div className="font-mono text-[8px] mt-0.5" style={{ color: C.dim }}>
            {provider.notes}
          </div>
        </div>
        <div className="flex gap-2 flex-wrap">
          <span
            className="font-mono text-[7px] px-2 py-1 border tracking-widest"
            style={{
              color: provider.gen3Ready ? C.green : C.amber,
              borderColor: provider.gen3Ready ? C.greenBorder : C.amberBorder,
              background: provider.gen3Ready ? C.greenFaint : C.amberFaint,
            }}
          >
            {provider.gen3Ready ? "GEN3 READY" : "GEN3 PENDING"}
          </span>
          <span
            className="font-mono text-[7px] px-2 py-1 border tracking-widest"
            style={{
              color: provider.whitelisted ? C.green : C.amber,
              borderColor: provider.whitelisted ? C.greenBorder : C.amberBorder,
              background: provider.whitelisted ? C.greenFaint : C.amberFaint,
            }}
          >
            {provider.whitelisted ? "WHITELISTED" : "WHITELIST PENDING"}
          </span>
          <span
            className="font-mono text-[7px] px-2 py-1 border tracking-widest"
            style={{
              color: C.cyan,
              borderColor: C.cyanBorder,
              background: C.cyanFaint,
            }}
          >
            FIRST TO BOOT
          </span>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="p-3 border" style={{ borderColor: C.cardBorder }}>
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-1"
            style={{ color: C.muted }}
          >
            CHEYENNE NODES
          </div>
          <div
            className="font-mono text-xl font-bold tabular-nums"
            style={{ color: C.cyan }}
          >
            {provider.cheyenneNodes}
          </div>
          <div className="font-mono text-[7px]" style={{ color: C.dim }}>
            WYOMING · GEN3
          </div>
        </div>
        <div className="p-3 border" style={{ borderColor: C.cardBorder }}>
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-1"
            style={{ color: C.muted }}
          >
            LINCOLN NODES
          </div>
          <div
            className="font-mono text-xl font-bold tabular-nums"
            style={{ color: C.cyan }}
          >
            {provider.lincolnNodes}
          </div>
          <div className="font-mono text-[7px]" style={{ color: C.dim }}>
            NEBRASKA · GEN3
          </div>
        </div>
      </div>
    </motion.div>
  );
}

// ── Phantom Proof Card ───────────────────────────────────────────────────────
function PhantomProofCard({ demo }: { demo: FrntDemo }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="border p-5"
      style={{ background: C.card, borderColor: C.greenBorder }}
      data-ocid="wyoming.phantom_proof.card"
    >
      <div className="flex items-center gap-3 mb-4">
        <span className="font-mono text-2xl" style={{ color: C.green }}>
          ✓
        </span>
        <div>
          <div
            className="font-mono text-[9px] tracking-[0.4em]"
            style={{ color: C.green }}
          >
            VISA BOTTLENECK: SOLVED
          </div>
          <div
            className="font-mono text-[7px] tracking-[0.2em] mt-0.5"
            style={{ color: C.muted }}
          >
            PHANTOM TECHNOLOGY · PARALLAX SOVEREIGN
          </div>
        </div>
      </div>
      <div
        className="space-y-2 font-mono text-[8px]"
        style={{ color: C.muted, lineHeight: 1.9 }}
      >
        <div>
          <span style={{ color: C.green }}>✓</span> Technology: Phantom
          settlement via FRNT/ICP liquidity pool on ICPSwap
        </div>
        <div>
          <span style={{ color: C.green }}>✓</span> Settlement:{" "}
          {demo.phantomSettlementMs}ms vs{" "}
          {Math.floor(demo.visaSettlementMs / 60000)}+ min (Visa/Kraken route)
        </div>
        <div>
          <span style={{ color: C.green }}>✓</span> Fee structure: 0% vs 3-5% —
          complete elimination of transaction friction
        </div>
        <div>
          <span style={{ color: C.green }}>✓</span> Architecture: Direct FRNT →
          ICP canister, no intermediary required
        </div>
        <div>
          <span style={{ color: C.green }}>✓</span> Wyoming interest: Switch to
          direct-minting model confirmed
        </div>
        <div>
          <span style={{ color: C.green }}>✓</span> Nebraska model: Ready to
          adopt after Wyoming proof of concept
        </div>
      </div>
    </motion.div>
  );
}

// ── Main WyomingTab ──────────────────────────────────────────────────────────
export function WyomingTab() {
  const { actor, isFetching } = useActor();
  const [state, setState] = useState<WyomingState>(DEFAULT_STATE);
  const [loading, setLoading] = useState(true);

  const fetchCharter = useCallback(async () => {
    if (!actor || isFetching) return;
    try {
      const a = actor as any;
      if (a.getWyomingCharter) {
        const data = await a.getWyomingCharter();
        if (data) setState(data as WyomingState);
      }
    } catch {
      // fallback to default state
    } finally {
      setLoading(false);
    }
  }, [actor, isFetching]);

  useEffect(() => {
    if (!actor || isFetching) return;
    fetchCharter();
  }, [actor, isFetching, fetchCharter]);

  async function handleRunDemo() {
    if (!actor) return;
    try {
      const a = actor as any;
      if (a.runFrntDemo) {
        await a.runFrntDemo();
        fetchCharter();
      }
    } catch {
      /* noop */
    }
  }

  return (
    <div className="space-y-0 pb-10" data-ocid="wyoming.page">
      {/* ── HEADER ──────────────────────────────────────────────────────────── */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="relative border-b overflow-hidden"
        style={{
          borderColor: C.cyanBorder,
          backgroundColor: "oklch(0.10 0.02 240)",
          backgroundImage:
            "linear-gradient(oklch(0.85 0.18 85 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.85 0.18 85 / 0.02) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      >
        <div className="relative z-10 px-6 py-8">
          <div className="flex items-center gap-2 mb-4">
            <motion.div
              animate={{ scale: [1, 1.3, 1], opacity: [1, 0.6, 1] }}
              transition={{ duration: 2, repeat: Number.POSITIVE_INFINITY }}
              className="w-2 h-2"
              style={{
                backgroundColor: C.cyan,
                boxShadow: "0 0 8px oklch(0.85 0.18 85)",
              }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.5em]"
              style={{ color: C.cyan }}
            >
              LIVE · WYOMING MASTER CHARTER
            </span>
            {loading && (
              <span className="font-mono text-[7px]" style={{ color: C.muted }}>
                · LOADING...
              </span>
            )}
          </div>

          <div
            className="font-display font-bold text-3xl md:text-4xl tracking-[0.25em] mb-2"
            style={{
              color: C.cyan,
              textShadow: "0 0 40px oklch(0.85 0.18 85 / 0.3)",
            }}
          >
            WYOMING CHARTER
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.25em]"
            style={{ color: C.muted }}
          >
            FRNT SETTLEMENT · LEGISLATIVE TIMELINE · SOVEREIGN INFRASTRUCTURE ·
            GRANT PIPELINE
          </div>

          {/* Key deadline banner */}
          <div className="mt-5 grid grid-cols-1 sm:grid-cols-3 gap-3">
            {[
              {
                label: "HARDWARE VISIBLE",
                value: "NOV 2026",
                note: "Lincoln, NE vault",
                color: C.cyan,
              },
              {
                label: "BILL READY",
                value: "JAN 2027",
                note: "Unicameral session",
                color: C.amber,
              },
              {
                label: "PHANTOM TECH",
                value: "DEPLOYED",
                note: "Visa bottleneck SOLVED",
                color: C.green,
              },
            ].map((stat) => (
              <div
                key={stat.label}
                className="p-3 border"
                style={{
                  background: "oklch(0.09 0.01 240)",
                  borderColor: C.cardBorder,
                }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.3em] mb-1"
                  style={{ color: C.muted }}
                >
                  {stat.label}
                </div>
                <div
                  className="font-mono text-base font-bold"
                  style={{ color: stat.color }}
                >
                  {stat.value}
                </div>
                <div
                  className="font-mono text-[7px] mt-0.5"
                  style={{ color: C.dim }}
                >
                  {stat.note}
                </div>
              </div>
            ))}
          </div>

          {/* Charter genesis hash */}
          <div className="mt-4 flex items-center gap-3">
            <span
              className="font-mono text-[7px] tracking-[0.3em]"
              style={{ color: C.muted }}
            >
              CHARTER GENESIS
            </span>
            <span className="font-mono text-[8px]" style={{ color: C.cyanDim }}>
              {state.charterGenesisHash}
            </span>
          </div>
        </div>
      </motion.div>

      {/* ── SECTION 1: FRNT SETTLEMENT DEMO ──────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ FRNT SETTLEMENT DEMO — PHANTOM TECHNOLOGY"
          sub="Visa/Kraken: 15+ min, 3-5% fee → Phantom/ICP: 0.3s, 0% fee. Wyoming is ready to switch."
        />
        <div className="p-5" data-ocid="wyoming.frnt.section">
          <FrntSettlementDemo demo={state.frntDemo} onRunDemo={handleRunDemo} />
        </div>
      </div>

      {/* ── SECTION 2: LEGISLATIVE TIMELINE ──────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ LEGISLATIVE TIMELINE — WYOMING → NEBRASKA"
          sub="Hardware visible Nov 2026 · Bill ready Jan 2027 · Senators Bosn & Ballard · Andy Vetor"
        />
        <div className="p-5" data-ocid="wyoming.legislative.section">
          <LegislativeTimeline legislative={state.legislative} />
        </div>
      </div>

      {/* ── SECTION 3: PARTNERSHIPS ──────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ PARTNERSHIP GRID"
          sub="Wyoming SPDI · Nebraska · UNL AI Institute · Bad Marine LLC"
        />
        <div className="p-5">
          <PartnershipGrid partnerships={state.partnerships} />
        </div>
      </div>

      {/* ── SECTION 4: FACILITY + NODE PROVIDER ─────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ SOVEREIGN FACILITY & NODE PROVIDER"
          sub="134 S 13th St, Lincoln NE · Federal Reserve Vault · Bad Marine LLC · First to Boot"
        />
        <div className="p-5 space-y-4">
          <FacilityCard facility={state.facility} />
          <NodeProviderCard provider={state.nodeProvider} />
        </div>
      </div>

      {/* ── SECTION 5: GRANT PIPELINE ────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ GRANT PIPELINE"
          sub="E-Rate · Title IV · TEA Innovation · NSF AI · Nebraska OCIO"
        />
        <div className="p-5">
          <GrantPipeline grants={state.grants} />
        </div>
      </div>

      {/* ── SECTION 6: PHANTOM PROOF ─────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ PHANTOM TECHNOLOGY PROOF — VISA BOTTLENECK SOLVED"
          sub="Direct-minting model · FRNT/ICP ICPSwap liquidity pool · Wyoming confirmed interest"
        />
        <div className="p-5">
          <PhantomProofCard demo={state.frntDemo} />
        </div>
      </div>
    </div>
  );
}
