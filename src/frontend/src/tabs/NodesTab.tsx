/**
 * NodesTab.tsx — NEURAL EMERGENCE CORES / NODUS REGISTRY
 * Compound generator nodes: ICP nodes · Web nodes · ANIMA nodes
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { motion } from "motion/react";
import { useState } from "react";
import { useActor } from "../hooks/useActor";

// ── Types (mirrors nodus.mo) ──────────────────────────────────────────────────

interface SsuState {
  clockMs: number;
  coherenceR: number;
  aegisOk: boolean;
  pilCycle: number;
  psiHash: string;
}

interface NodusRecord {
  id: string;
  name: string;
  substrate: { ICP?: null } | { WEB?: null } | { ANIMA?: null };
  healthScore: number;
  rewardsIcp: number;
  compoundRate: number;
  ssuState: SsuState;
  beatCount: number;
  isSovereignPart: boolean;
  assignedToCompany: [] | [string];
  activatedAt: number;
}

interface NodusRegistry {
  nodes: [string, NodusRecord][];
  totalRewards: number;
  lastTick: number;
  registryGenesisHash: string;
}

// ── Color palette ─────────────────────────────────────────────────────────────
const C = {
  // Cyan = ICP nodes
  cyan: "oklch(0.78 0.18 190)",
  cyanDim: "oklch(0.78 0.18 190 / 0.6)",
  cyanFaint: "oklch(0.78 0.18 190 / 0.06)",
  cyanBorder: "oklch(0.78 0.18 190 / 0.30)",
  // Green = WEB nodes
  green: "oklch(0.68 0.20 145)",
  greenDim: "oklch(0.68 0.20 145 / 0.6)",
  greenFaint: "oklch(0.68 0.20 145 / 0.06)",
  greenBorder: "oklch(0.68 0.20 145 / 0.30)",
  // Violet = ANIMA nodes
  violet: "oklch(0.65 0.20 290)",
  violetDim: "oklch(0.65 0.20 290 / 0.6)",
  violetFaint: "oklch(0.65 0.20 290 / 0.06)",
  violetBorder: "oklch(0.65 0.20 290 / 0.30)",
  // Gold = rewards / primary
  gold: "oklch(0.78 0.15 85)",
  goldDim: "oklch(0.78 0.15 85 / 0.6)",
  goldFaint: "oklch(0.78 0.15 85 / 0.06)",
  goldBorder: "oklch(0.78 0.15 85 / 0.25)",
  // Amber = warning
  amber: "oklch(0.72 0.18 65)",
  amberFaint: "oklch(0.72 0.18 65 / 0.08)",
  amberBorder: "oklch(0.72 0.18 65 / 0.35)",
  // Red = critical
  red: "oklch(0.55 0.22 25)",
  redFaint: "oklch(0.55 0.22 25 / 0.08)",
  redBorder: "oklch(0.55 0.22 25 / 0.35)",
  // Neutrals
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  dim: "oklch(0.28 0.03 270)",
  card: "oklch(0.11 0.02 240)",
  cardBorder: "oklch(0.20 0.02 240)",
  bg: "oklch(0.08 0.01 240)",
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

function useNodusRegistry() {
  const { actor, isFetching } = useActor();
  return useQuery<NodusRegistry | null>({
    queryKey: ["nodusRegistry"],
    queryFn: async () => {
      if (!actor) return null;
      const a = actor as unknown as {
        getNodusRegistry?: () => Promise<NodusRegistry>;
      };
      if (!a.getNodusRegistry) return null;
      return a.getNodusRegistry();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });
}

function useNodeRewards() {
  const { actor, isFetching } = useActor();
  return useQuery<number>({
    queryKey: ["nodeRewards"],
    queryFn: async () => {
      if (!actor) return 0;
      const a = actor as unknown as {
        getNodeRewards?: () => Promise<number>;
      };
      if (!a.getNodeRewards) return 0;
      return a.getNodeRewards();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });
}

function useAssignNodusToCompany() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, company }: { id: string; company: string }) => {
      const a = actor as unknown as {
        assignNodusToCompany?: (id: string, c: string) => Promise<void>;
      };
      if (!a?.assignNodusToCompany) throw new Error("No actor");
      await a.assignNodusToCompany(id, company);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["nodusRegistry"] }),
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function substrateLabel(
  substrate: NodusRecord["substrate"],
): "ICP" | "WEB" | "ANIMA" {
  if ("ICP" in substrate) return "ICP";
  if ("WEB" in substrate) return "WEB";
  return "ANIMA";
}

function substrateColors(type: "ICP" | "WEB" | "ANIMA") {
  if (type === "ICP")
    return { color: C.cyan, border: C.cyanBorder, faint: C.cyanFaint };
  if (type === "WEB")
    return { color: C.green, border: C.greenBorder, faint: C.greenFaint };
  return { color: C.violet, border: C.violetBorder, faint: C.violetFaint };
}

function healthColor(score: number) {
  if (score >= 0.9) return C.green;
  if (score >= 0.618) return C.amber;
  return C.red;
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

function SkeletonCard() {
  return (
    <div
      className="p-4 border space-y-3"
      style={{ background: C.card, borderColor: C.cardBorder }}
    >
      <div className="skeleton-dark h-3 w-2/3 rounded-none" />
      <div className="skeleton-dark h-2 w-1/2 rounded-none" />
      <div className="skeleton-dark h-2 w-3/4 rounded-none" />
      <div className="skeleton-dark h-1.5 w-full rounded-none mt-2" />
    </div>
  );
}

// ── Substrate Pool Card ───────────────────────────────────────────────────────

function SubstratePoolCard({
  type,
  nodes,
  glowColor,
  borderColor,
  faintColor,
}: {
  type: "ICP" | "WEB" | "ANIMA";
  nodes: NodusRecord[];
  glowColor: string;
  borderColor: string;
  faintColor: string;
}) {
  const avgHealth =
    nodes.length > 0
      ? nodes.reduce((s, n) => s + n.healthScore, 0) / nodes.length
      : 0;
  const totalRewards = nodes.reduce((s, n) => s + n.rewardsIcp, 0);
  const lastBeat =
    nodes.length > 0 ? Math.max(...nodes.map((n) => n.beatCount)) : 0;

  const substrateIcon = type === "ICP" ? "⬡" : type === "WEB" ? "◉" : "∞";

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      className="p-5 border relative overflow-hidden"
      style={{
        background: C.card,
        borderColor,
        boxShadow: `0 0 20px ${glowColor.replace(")", " / 0.08)")}`,
      }}
      data-ocid={`nodes.substrate_${type.toLowerCase()}.card`}
    >
      {/* Background accent */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: `radial-gradient(ellipse at 80% 20%, ${faintColor} 0%, transparent 65%)`,
        }}
      />
      <div className="relative z-10">
        <div className="flex items-start justify-between mb-4">
          <div>
            <div
              className="font-mono text-[8px] tracking-[0.5em] mb-1"
              style={{ color: glowColor }}
            >
              {type} NODES
            </div>
            <div
              className="font-display font-bold text-4xl"
              style={{
                color: glowColor,
                textShadow: `0 0 30px ${glowColor.replace(")", " / 0.4)")}`,
              }}
            >
              {nodes.length}
            </div>
          </div>
          <div
            className="text-3xl opacity-30 font-mono"
            style={{ color: glowColor }}
          >
            {substrateIcon}
          </div>
        </div>

        {/* Health bar */}
        <div className="mb-3">
          <div className="flex items-center justify-between mb-1">
            <span
              className="font-mono text-[7px] tracking-[0.3em]"
              style={{ color: C.muted }}
            >
              AVG HEALTH
            </span>
            <span
              className="font-mono text-[9px] tabular-nums"
              style={{ color: healthColor(avgHealth) }}
            >
              {(avgHealth * 100).toFixed(1)}%
            </span>
          </div>
          <div
            className="h-1.5 w-full"
            style={{ background: "oklch(0.18 0.02 240)" }}
          >
            <div
              className="h-full transition-all duration-700"
              style={{
                width: `${avgHealth * 100}%`,
                background: healthColor(avgHealth),
                boxShadow: `0 0 6px ${healthColor(avgHealth)}`,
              }}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              TOTAL REWARDS
            </div>
            <div
              className="font-mono text-xs tabular-nums font-bold"
              style={{ color: C.gold }}
            >
              {totalRewards.toFixed(4)} ICP
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              LAST BEAT
            </div>
            <div
              className="font-mono text-xs tabular-nums font-bold"
              style={{ color: glowColor }}
            >
              {lastBeat.toLocaleString()}
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

// ── SSU Micro-Cards ───────────────────────────────────────────────────────────

function SsuMicroCard({
  label,
  value,
  sub,
  valueColor,
  children,
}: {
  label: string;
  value: string;
  sub?: string;
  valueColor?: string;
  children?: React.ReactNode;
}) {
  return (
    <div
      className="p-4 border"
      style={{ background: C.card, borderColor: C.cardBorder }}
    >
      <div
        className="font-mono text-[7px] tracking-[0.4em] mb-2"
        style={{ color: C.muted }}
      >
        {label}
      </div>
      <div
        className="font-mono text-sm tabular-nums font-bold"
        style={{ color: valueColor ?? C.gold }}
      >
        {value}
      </div>
      {sub && (
        <div className="font-mono text-[7px] mt-1" style={{ color: C.dim }}>
          {sub}
        </div>
      )}
      {children}
    </div>
  );
}

// ── Substrate Badge ───────────────────────────────────────────────────────────

function SubstrateBadge({ type }: { type: "ICP" | "WEB" | "ANIMA" }) {
  const sc = substrateColors(type);
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
      style={{ color: sc.color, borderColor: sc.border, background: sc.faint }}
    >
      {type}
    </span>
  );
}

// ── Health Bar (inline) ───────────────────────────────────────────────────────

function HealthBar({ score }: { score: number }) {
  const pct = Math.min(1, Math.max(0, score)) * 100;
  const col = healthColor(score);
  return (
    <div className="flex items-center gap-2 min-w-0">
      <div
        className="flex-1 h-1 min-w-[40px]"
        style={{ background: "oklch(0.18 0.02 240)" }}
      >
        <div
          className="h-full"
          style={{
            width: `${pct}%`,
            background: col,
            boxShadow: `0 0 4px ${col}`,
          }}
        />
      </div>
      <span
        className="font-mono text-[8px] tabular-nums shrink-0"
        style={{ color: col }}
      >
        {score.toFixed(3)}
      </span>
    </div>
  );
}

// ── Assign Company Modal ──────────────────────────────────────────────────────

function AssignCompanyModal({
  nodeId,
  onClose,
}: {
  nodeId: string;
  onClose: () => void;
}) {
  const [company, setCompany] = useState("");
  const assignMutation = useAssignNodusToCompany();

  function handleAssign() {
    if (!company.trim()) return;
    assignMutation.mutate(
      { id: nodeId, company: company.trim() },
      { onSuccess: onClose },
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.97 }}
      animate={{ opacity: 1, scale: 1 }}
      className="border p-4 space-y-3 mt-2"
      style={{ background: "oklch(0.10 0.01 240)", borderColor: C.cyanBorder }}
      data-ocid="nodes.assign_company.dialog"
    >
      <div className="flex items-center justify-between">
        <div
          className="font-mono text-[8px] tracking-[0.35em]"
          style={{ color: C.cyan }}
        >
          ASSIGN SOVEREIGN PART
        </div>
        <button
          type="button"
          onClick={onClose}
          className="font-mono text-[8px] px-2 py-0.5 border transition-all"
          style={{ color: C.muted, borderColor: C.cardBorder }}
          data-ocid="nodes.assign_company.close_button"
        >
          ✕
        </button>
      </div>
      <input
        type="text"
        value={company}
        onChange={(e) => setCompany(e.target.value)}
        placeholder="Company name or ID"
        className="w-full px-3 py-2 font-mono text-xs outline-none"
        style={{
          background: "oklch(0.08 0.01 240)",
          border: `1px solid ${C.cardBorder}`,
          color: C.text,
        }}
        data-ocid="nodes.assign_company.input"
      />
      <button
        type="button"
        onClick={handleAssign}
        disabled={assignMutation.isPending || !company.trim()}
        className="w-full py-2 border font-mono text-[8px] tracking-[0.25em] transition-all disabled:opacity-40"
        style={{
          borderColor: C.cyanBorder,
          color: C.cyan,
          background: C.cyanFaint,
        }}
        data-ocid="nodes.assign_company.confirm_button"
      >
        {assignMutation.isPending ? "⟳ ASSIGNING..." : "ASSIGN"}
      </button>
    </motion.div>
  );
}

// ── Node Card ─────────────────────────────────────────────────────────────────

function NodeCard({
  node,
  index,
  isCreator,
}: {
  node: NodusRecord;
  index: number;
  isCreator: boolean;
}) {
  const [showAssign, setShowAssign] = useState(false);
  const type = substrateLabel(node.substrate);
  const sc = substrateColors(type);
  const assignedCompany =
    node.assignedToCompany.length > 0 ? node.assignedToCompany[0] : null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05, duration: 0.3 }}
      className="p-4 border relative overflow-hidden"
      style={{
        background: C.card,
        borderColor: C.cardBorder,
      }}
      data-ocid={`nodes.node.item.${index + 1}`}
    >
      {/* Left accent bar */}
      <div
        className="absolute left-0 top-0 bottom-0 w-0.5"
        style={{ background: sc.color }}
      />

      <div className="pl-3 space-y-3">
        {/* Header row */}
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span
                className="font-mono text-xs font-bold truncate max-w-[140px]"
                style={{ color: C.text }}
                title={node.name}
              >
                {node.name}
              </span>
              <SubstrateBadge type={type} />
              {node.isSovereignPart && (
                <span
                  className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest"
                  style={{
                    color: C.gold,
                    borderColor: C.goldBorder,
                    background: C.goldFaint,
                  }}
                >
                  SOVEREIGN
                </span>
              )}
              {assignedCompany && (
                <span
                  className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest truncate max-w-[80px]"
                  style={{
                    color: C.violet,
                    borderColor: C.violetBorder,
                    background: C.violetFaint,
                  }}
                  title={assignedCompany}
                >
                  {assignedCompany.length > 8
                    ? `${assignedCompany.slice(0, 8)}…`
                    : assignedCompany}
                </span>
              )}
            </div>
            <div
              className="font-mono text-[7px] mt-1 tracking-wider"
              style={{ color: C.dim }}
            >
              {node.id.slice(0, 8)}…{node.id.slice(-4)} ·{" "}
              {node.ssuState.psiHash.slice(0, 8)}
            </div>
          </div>
          {/* Live indicator */}
          <div className="flex items-center gap-1.5 shrink-0">
            <div
              className="w-1.5 h-1.5 animate-beat"
              style={{
                background: sc.color,
                boxShadow: `0 0 6px ${sc.color}`,
              }}
            />
            <span className="font-mono text-[7px]" style={{ color: sc.color }}>
              LIVE
            </span>
          </div>
        </div>

        {/* Metrics grid */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-x-4 gap-y-2">
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              REWARDS
            </div>
            <div
              className="font-mono text-[10px] tabular-nums font-bold"
              style={{ color: C.gold }}
            >
              {node.rewardsIcp.toFixed(4)} ICP
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              COMPOUND
            </div>
            <div
              className="font-mono text-[10px] tabular-nums font-bold"
              style={{ color: C.green }}
            >
              {(node.compoundRate * 100).toFixed(3)}%
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              BEAT
            </div>
            <div
              className="font-mono text-[10px] tabular-nums font-bold"
              style={{ color: sc.color }}
            >
              {node.beatCount.toLocaleString()}
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              KURAMOTO R
            </div>
            <div
              className="font-mono text-[10px] tabular-nums font-bold"
              style={{
                color: node.ssuState.coherenceR >= 0.618 ? C.green : C.amber,
              }}
            >
              {node.ssuState.coherenceR.toFixed(4)}
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              AEGIS
            </div>
            <div
              className="font-mono text-[10px] font-bold"
              style={{ color: node.ssuState.aegisOk ? C.green : C.red }}
            >
              {node.ssuState.aegisOk ? "OK" : "DRIFT"}
            </div>
          </div>
          <div>
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-0.5"
              style={{ color: C.muted }}
            >
              PIL CYCLE
            </div>
            <div
              className="font-mono text-[10px] tabular-nums font-bold"
              style={{ color: C.violetDim }}
            >
              #{node.ssuState.pilCycle}
            </div>
          </div>
        </div>

        {/* Health bar */}
        <div>
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-1"
            style={{ color: C.muted }}
          >
            HEALTH SCORE
          </div>
          <HealthBar score={node.healthScore} />
        </div>

        {/* Creator assign button */}
        {isCreator && (
          <div>
            {!showAssign ? (
              <button
                type="button"
                onClick={() => setShowAssign(true)}
                className="px-3 py-1 border font-mono text-[7px] tracking-[0.25em] transition-all"
                style={{
                  color: C.cyanDim,
                  borderColor: C.cyanBorder,
                  background: C.cyanFaint,
                }}
                data-ocid={`nodes.assign.button.${index + 1}`}
              >
                ASSIGN TO COMPANY
              </button>
            ) : (
              <AssignCompanyModal
                nodeId={node.id}
                onClose={() => setShowAssign(false)}
              />
            )}
          </div>
        )}
      </div>
    </motion.div>
  );
}

// ── Section Header ────────────────────────────────────────────────────────────

function SectionHeader({ label, sub }: { label: string; sub?: string }) {
  return (
    <div
      className="px-5 py-4 border-b"
      style={{
        borderColor: C.cyanBorder,
        background: "oklch(0.78 0.18 190 / 0.03)",
        backgroundImage:
          "linear-gradient(oklch(0.78 0.18 190 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 190 / 0.02) 1px, transparent 1px)",
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
          className="font-mono text-[8px] tracking-[0.15em] mt-1"
          style={{ color: C.muted }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

// ── Empty State ───────────────────────────────────────────────────────────────

function EmptyState() {
  return (
    <div
      className="py-16 text-center border"
      style={{ background: C.card, borderColor: C.cardBorder }}
      data-ocid="nodes.empty_state"
    >
      <div
        className="font-mono text-5xl mb-4 opacity-20"
        style={{ color: C.cyan }}
      >
        ⬡
      </div>
      <div
        className="font-mono text-[9px] tracking-[0.4em] mb-2"
        style={{ color: C.muted }}
      >
        NO NODES REGISTERED
      </div>
      <div className="font-mono text-[8px]" style={{ color: C.dim }}>
        Neural emergence cores will appear here when deployed to the substrate
      </div>
    </div>
  );
}

// ── Main NodesTab ─────────────────────────────────────────────────────────────

export function NodesTab() {
  const { data: registry, isLoading } = useNodusRegistry();
  const { data: totalLiveRewards = 0 } = useNodeRewards();
  const { actor } = useActor();
  const [filterType, setFilterType] = useState<"ALL" | "ICP" | "WEB" | "ANIMA">(
    "ALL",
  );

  const isCreator = !!actor;

  // Parse nodes from registry
  const allNodes: NodusRecord[] = registry?.nodes?.map(([, n]) => n) ?? [];

  // Partition by substrate
  const icpNodes = allNodes.filter((n) => "ICP" in n.substrate);
  const webNodes = allNodes.filter((n) => "WEB" in n.substrate);
  const animaNodes = allNodes.filter((n) => "ANIMA" in n.substrate);

  // Filter for display
  const displayNodes =
    filterType === "ALL"
      ? allNodes
      : filterType === "ICP"
        ? icpNodes
        : filterType === "WEB"
          ? webNodes
          : animaNodes;

  // SSU aggregate metrics
  const avgCoherenceR =
    allNodes.length > 0
      ? allNodes.reduce((s, n) => s + n.ssuState.coherenceR, 0) /
        allNodes.length
      : 0;
  const aegisOkCount = allNodes.filter((n) => n.ssuState.aegisOk).length;
  const avgPilCycle =
    allNodes.length > 0
      ? allNodes.reduce((s, n) => s + n.ssuState.pilCycle, 0) / allNodes.length
      : 0;

  const rewardsDisplay =
    registry?.totalRewards != null ? registry.totalRewards : totalLiveRewards;

  return (
    <div className="space-y-0 pb-10" data-ocid="nodes.page">
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
            "linear-gradient(oklch(0.78 0.18 190 / 0.025) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 190 / 0.025) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      >
        <div className="relative z-10 px-6 py-8">
          <div className="flex items-center gap-2 mb-4">
            <div
              className="w-2 h-2 animate-beat"
              style={{ background: C.cyan, boxShadow: `0 0 8px ${C.cyan}` }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.5em]"
              style={{ color: C.cyan }}
            >
              LIVE · {allNodes.length} NODES ACTIVE
            </span>
          </div>
          <div
            className="font-display font-bold text-3xl md:text-4xl tracking-[0.3em] mb-2"
            style={{
              color: C.cyan,
              textShadow: `0 0 40px ${C.cyanDim}`,
            }}
          >
            NODUS REGISTRY
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.25em]"
            style={{ color: C.muted }}
          >
            ICP NODES · WEB NODES · ANIMA NODES · COMPOUND GENERATORS ·
            SOVEREIGN PARTS
          </div>

          {/* Registry hash */}
          {registry?.registryGenesisHash && (
            <div
              className="mt-4 font-mono text-[8px] tracking-wider"
              style={{ color: C.dim }}
            >
              REGISTRY Ψ {registry.registryGenesisHash.slice(0, 24)}…
            </div>
          )}
        </div>
      </motion.div>

      {/* ── SUBSTRATE POOLS ─────────────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ SUBSTRATE POOLS"
          sub="ICP · WEB · ANIMA — Three sovereign deployment layers. Each pool earns compound rewards."
        />
        <div className="p-5">
          <div
            className="grid grid-cols-1 sm:grid-cols-3 gap-4"
            data-ocid="nodes.substrate_pools.section"
          >
            {isLoading ? (
              <>
                <SkeletonCard />
                <SkeletonCard />
                <SkeletonCard />
              </>
            ) : (
              <>
                <SubstratePoolCard
                  type="ICP"
                  nodes={icpNodes}
                  glowColor={C.cyan}
                  borderColor={C.cyanBorder}
                  faintColor={C.cyanFaint}
                />
                <SubstratePoolCard
                  type="WEB"
                  nodes={webNodes}
                  glowColor={C.green}
                  borderColor={C.greenBorder}
                  faintColor={C.greenFaint}
                />
                <SubstratePoolCard
                  type="ANIMA"
                  nodes={animaNodes}
                  glowColor={C.violet}
                  borderColor={C.violetBorder}
                  faintColor={C.violetFaint}
                />
              </>
            )}
          </div>
        </div>
      </div>

      {/* ── SSU STATUS ROW ───────────────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ SSU STATUS — SOVEREIGN SUBSTRATE UNIT"
          sub="Φ_CLOCK · Ω_GATE · Δ_AEGIS · Λ_PIL — All four SSU capabilities active across the node fleet."
        />
        <div className="p-5">
          <div
            className="grid grid-cols-2 sm:grid-cols-4 gap-3"
            data-ocid="nodes.ssu_status.section"
          >
            <SsuMicroCard
              label="Φ_CLOCK — HEARTBEAT"
              value="873ms"
              sub="φ⁴ / f_Schumann × 1000ms"
              valueColor={C.gold}
            >
              <div className="flex items-center gap-1.5 mt-2">
                <div
                  className="w-1.5 h-1.5 animate-beat"
                  style={{
                    background: C.gold,
                    boxShadow: `0 0 6px ${C.gold}`,
                  }}
                />
                <span
                  className="font-mono text-[7px]"
                  style={{ color: C.goldDim }}
                >
                  UNIVERSAL TIME LAW
                </span>
              </div>
            </SsuMicroCard>

            <SsuMicroCard
              label="Ω_GATE — COHERENCE R"
              value={avgCoherenceR.toFixed(4)}
              sub="threshold: 0.618 (φ⁻¹)"
              valueColor={avgCoherenceR >= 0.618 ? C.green : C.amber}
            >
              {/* Threshold bar */}
              <div
                className="mt-2 h-1 w-full relative"
                style={{ background: "oklch(0.18 0.02 240)" }}
              >
                <div
                  className="absolute left-0 top-0 h-full transition-all duration-700"
                  style={{
                    width: `${Math.min(1, avgCoherenceR) * 100}%`,
                    background: avgCoherenceR >= 0.618 ? C.green : C.amber,
                  }}
                />
                {/* Threshold marker at 61.8% */}
                <div
                  className="absolute top-0 h-full w-0.5"
                  style={{
                    left: "61.8%",
                    background: C.goldDim,
                    opacity: 0.6,
                  }}
                />
              </div>
            </SsuMicroCard>

            <SsuMicroCard
              label="Δ_AEGIS — ANTI-DRIFT"
              value={`${aegisOkCount} / ${allNodes.length}`}
              sub="nodes coherent"
              valueColor={
                allNodes.length === 0
                  ? C.muted
                  : aegisOkCount === allNodes.length
                    ? C.green
                    : aegisOkCount / Math.max(1, allNodes.length) >= 0.618
                      ? C.amber
                      : C.red
              }
            />

            <SsuMicroCard
              label="Λ_PIL — IMPROVEMENT"
              value={`#${Math.floor(avgPilCycle)}`}
              sub="avg improvement cycle"
              valueColor={C.violet}
            />
          </div>
        </div>
      </div>

      {/* ── TOTAL REWARDS ────────────────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ REWARD ACCUMULATOR"
          sub="Total ICP earned across all nodes. Compounding every 873ms. The organism IS the funding mechanism."
        />
        <div className="p-5" data-ocid="nodes.rewards.section">
          <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            className="p-6 border relative overflow-hidden"
            style={{
              background: C.card,
              borderColor: C.goldBorder,
              boxShadow: "0 0 30px oklch(0.78 0.15 85 / 0.06)",
            }}
            data-ocid="nodes.total_rewards.card"
          >
            {/* Gold glow gradient */}
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                background:
                  "radial-gradient(ellipse at 30% 50%, oklch(0.78 0.15 85 / 0.05) 0%, transparent 60%)",
              }}
            />
            <div className="relative z-10 flex flex-col sm:flex-row sm:items-center gap-6">
              <div className="flex-1">
                <div
                  className="font-mono text-[8px] tracking-[0.5em] mb-3"
                  style={{ color: C.muted }}
                >
                  TOTAL ICP EARNED — ALL NODES
                </div>
                <div className="flex items-baseline gap-3">
                  <div
                    className="font-display font-bold text-4xl md:text-5xl tabular-nums animate-pulse-glow"
                    style={{
                      color: C.gold,
                      textShadow: "0 0 30px oklch(0.78 0.15 85 / 0.5)",
                    }}
                  >
                    {rewardsDisplay.toFixed(4)}
                  </div>
                  <div
                    className="font-mono text-lg font-bold"
                    style={{ color: C.goldDim }}
                  >
                    ICP
                  </div>
                </div>
                <div
                  className="font-mono text-[8px] mt-2"
                  style={{ color: C.dim }}
                >
                  ACCUMULATING · COMPOUNDING · SOVEREIGN
                </div>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-1 gap-3 shrink-0">
                <div
                  className="px-4 py-3 border text-center"
                  style={{
                    borderColor: C.cyanBorder,
                    background: C.cyanFaint,
                  }}
                >
                  <div
                    className="font-mono text-[7px] tracking-[0.3em] mb-1"
                    style={{ color: C.muted }}
                  >
                    ICP NODES
                  </div>
                  <div
                    className="font-mono text-sm tabular-nums font-bold"
                    style={{ color: C.cyan }}
                  >
                    {icpNodes.reduce((s, n) => s + n.rewardsIcp, 0).toFixed(4)}
                  </div>
                </div>
                <div
                  className="px-4 py-3 border text-center"
                  style={{
                    borderColor: C.greenBorder,
                    background: C.greenFaint,
                  }}
                >
                  <div
                    className="font-mono text-[7px] tracking-[0.3em] mb-1"
                    style={{ color: C.muted }}
                  >
                    WEB NODES
                  </div>
                  <div
                    className="font-mono text-sm tabular-nums font-bold"
                    style={{ color: C.green }}
                  >
                    {webNodes.reduce((s, n) => s + n.rewardsIcp, 0).toFixed(4)}
                  </div>
                </div>
                <div
                  className="px-4 py-3 border text-center"
                  style={{
                    borderColor: "oklch(0.55 0.22 290 / 0.4)",
                    background: "oklch(0.55 0.22 290 / 0.06)",
                  }}
                >
                  <div
                    className="font-mono text-[7px] tracking-[0.3em] mb-1"
                    style={{ color: C.muted }}
                  >
                    ANIMA NODES
                  </div>
                  <div
                    className="font-mono text-sm tabular-nums font-bold"
                    style={{ color: C.violet }}
                  >
                    {animaNodes
                      .reduce((s, n) => s + n.rewardsIcp, 0)
                      .toFixed(4)}
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>

      {/* ── NODE GRID ────────────────────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ NODE HEALTH DASHBOARD"
          sub="Per-node status · health · rewards · SSU coherence · compound rate"
        />
        <div className="p-5 space-y-4" data-ocid="nodes.node_grid.section">
          {/* Filter tabs */}
          <div className="flex items-center gap-2 flex-wrap">
            {(["ALL", "ICP", "WEB", "ANIMA"] as const).map((f) => {
              const counts = {
                ALL: allNodes.length,
                ICP: icpNodes.length,
                WEB: webNodes.length,
                ANIMA: animaNodes.length,
              };
              const active = filterType === f;
              const fc =
                f === "ICP"
                  ? C.cyan
                  : f === "WEB"
                    ? C.green
                    : f === "ANIMA"
                      ? C.violet
                      : C.gold;
              return (
                <button
                  key={f}
                  type="button"
                  onClick={() => setFilterType(f)}
                  className="px-3 py-1.5 border font-mono text-[8px] tracking-[0.3em] transition-all"
                  style={{
                    color: active ? fc : C.muted,
                    borderColor: active ? fc : C.cardBorder,
                    background: active
                      ? `${fc.replace(")", " / 0.08)")}`
                      : "transparent",
                  }}
                  data-ocid={`nodes.filter.${f.toLowerCase()}.tab`}
                >
                  {f} ({counts[f]})
                </button>
              );
            })}
          </div>

          {/* Grid or states */}
          {isLoading ? (
            <div
              className="grid grid-cols-1 md:grid-cols-2 gap-4"
              data-ocid="nodes.grid.loading_state"
            >
              {["sk1", "sk2", "sk3", "sk4", "sk5", "sk6"].map((k) => (
                <SkeletonCard key={k} />
              ))}
            </div>
          ) : displayNodes.length === 0 ? (
            <EmptyState />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {displayNodes.map((node, i) => (
                <NodeCard
                  key={node.id}
                  node={node}
                  index={i}
                  isCreator={isCreator}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ── REGISTRY METADATA ────────────────────────────────────────────────── */}
      {registry && (
        <div>
          <SectionHeader
            label="■ REGISTRY METADATA"
            sub="Permanent genesis proof · Last tick · Total node count"
          />
          <div className="p-5" data-ocid="nodes.registry_metadata.section">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div
                className="p-4 border"
                style={{ background: C.card, borderColor: C.cardBorder }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.4em] mb-2"
                  style={{ color: C.muted }}
                >
                  GENESIS HASH
                </div>
                <div
                  className="font-mono text-[9px] break-all"
                  style={{ color: C.cyanDim }}
                >
                  {registry.registryGenesisHash
                    ? `${registry.registryGenesisHash.slice(0, 32)}…`
                    : "PENDING"}
                </div>
              </div>
              <div
                className="p-4 border"
                style={{ background: C.card, borderColor: C.cardBorder }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.4em] mb-2"
                  style={{ color: C.muted }}
                >
                  LAST TICK
                </div>
                <div
                  className="font-mono text-xs tabular-nums font-bold"
                  style={{ color: C.gold }}
                >
                  {registry.lastTick > 0
                    ? new Date(registry.lastTick / 1_000_000).toLocaleString(
                        "en-US",
                        {
                          month: "short",
                          day: "numeric",
                          hour: "2-digit",
                          minute: "2-digit",
                          second: "2-digit",
                        },
                      )
                    : "—"}
                </div>
              </div>
              <div
                className="p-4 border"
                style={{ background: C.card, borderColor: C.cardBorder }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.4em] mb-2"
                  style={{ color: C.muted }}
                >
                  TOTAL NODES
                </div>
                <div
                  className="font-mono text-2xl font-bold tabular-nums"
                  style={{ color: C.cyan }}
                >
                  {allNodes.length}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
