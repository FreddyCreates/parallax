import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";
import {
  type NeuronGroup,
  useCreatorReserve,
  useNeuronFleet,
  useTreasuryDetail,
} from "../hooks/useForma";
import { useIntelligenceEngine } from "../hooks/useIntelligenceEngine";
import {
  useAgiStatus,
  useMemoriaNns,
  useWithdrawalLog,
} from "../hooks/useQueries";
import {
  formaProject,
  jacobsVelocity,
  spectralCoherence,
  vonNeumannEntropy,
} from "../lib/intelligenceEngine";

// ── Color palette ───────────────────────────────────────────────────────────────
const C = {
  gold: "oklch(0.78 0.18 85)",
  cyan: "oklch(0.72 0.15 200)",
  purple: "oklch(0.65 0.28 290)",
  green: "oklch(0.62 0.17 145)",
  red: "oklch(0.55 0.22 25)",
  amber: "oklch(0.75 0.18 62)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  dim: "oklch(0.30 0.03 270)",
};

// ── Shared primitives ──────────────────────────────────────────────────────────────
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

function Num({
  children,
  color = C.text,
  size = "text-xs",
}: { children: React.ReactNode; color?: string; size?: string }) {
  return (
    <span className={`font-mono ${size}`} style={{ color }}>
      {children}
    </span>
  );
}

function PanelBox({
  children,
  className = "",
}: { children: React.ReactNode; className?: string }) {
  return (
    <div
      className={`border p-4 ${className}`}
      style={{
        borderColor: "rgba(255,255,255,0.06)",
        background: "rgba(0,0,0,0.45)",
      }}
    >
      {children}
    </div>
  );
}

function SecTitle({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="font-mono text-[8px] tracking-[0.5em] mb-3 pb-2 border-b flex items-center gap-2"
      style={{ color: C.muted, borderColor: "rgba(255,255,255,0.05)" }}
    >
      {children}
    </div>
  );
}

function LockOverlay() {
  return (
    <div
      className="absolute inset-0 flex flex-col items-center justify-center gap-2 z-10"
      style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(4px)" }}
    >
      <span
        className="font-mono text-[10px] tracking-[0.3em]"
        style={{ color: C.amber }}
      >
        ⚠ AUTH REQUIRED
      </span>
      <span className="font-mono text-[8px]" style={{ color: C.muted }}>
        Authenticate to access operator controls
      </span>
    </div>
  );
}

// ── A. Sovereign Value Header ────────────────────────────────────────────────────────
function SovereignValueHeader({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { treasuryState, creatorReserve, fullState } = eng;
  const ts = treasuryState;
  const cr = creatorReserve;

  const btcUsd = (ts?.btcBalance ?? 0) * (ts?.btcPrice ?? 0);
  const ethUsd = (ts?.ethBalance ?? 0) * (ts?.ethPrice ?? 0);
  const icpUsd = (ts?.icpBalance ?? 0) * (ts?.icpPrice ?? 0);
  const totalUsd = cr?.totalUsdEquivalent ?? btcUsd + ethUsd + icpUsd;

  return (
    <div
      className="border p-5"
      style={{
        borderColor: `${C.gold}22`,
        background: `${C.gold}05`,
        boxShadow: `0 0 40px ${C.gold}08`,
      }}
    >
      <div className="flex flex-wrap items-center gap-6 mb-4">
        <div>
          <Lbl>SOVEREIGN TREASURY VALUE</Lbl>
          <div
            className="font-mono text-4xl font-bold mt-1"
            style={{ color: C.gold, textShadow: `0 0 32px ${C.gold}55` }}
          >
            $
            {totalUsd.toLocaleString("en-US", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}
          </div>
        </div>
        <div className="ml-auto flex items-center gap-2">
          <span
            className="font-mono text-[7px] tracking-widest px-2 py-1"
            style={{
              color: ts?.liveDataActive ? C.green : C.amber,
              border: `1px solid ${ts?.liveDataActive ? C.green : C.amber}44`,
            }}
          >
            {ts?.liveDataActive ? "● LIVE" : "○ CACHED"}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          {
            label: "ICP",
            bal: ts?.icpBalance ?? 0,
            price: ts?.icpPrice ?? 0,
            usd: icpUsd,
            color: C.purple,
          },
          {
            label: "BTC",
            bal: ts?.btcBalance ?? 0,
            price: ts?.btcPrice ?? 0,
            usd: btcUsd,
            color: C.amber,
          },
          {
            label: "ETH",
            bal: ts?.ethBalance ?? 0,
            price: ts?.ethPrice ?? 0,
            usd: ethUsd,
            color: C.cyan,
          },
          {
            label: "INTELLIGENCE",
            bal: ts?.engineIntelligenceScore ?? 0,
            price: ts?.systemCoherenceScore ?? 0,
            usd: fullState?.sacesiTarget ?? 0,
            color: C.purple,
            isScore: true,
          },
        ].map((item) => (
          <div
            key={item.label}
            className="border-l-2 pl-3"
            style={{ borderLeftColor: `${item.color}66` }}
          >
            <Lbl>{item.label}</Lbl>
            <div
              className="font-mono text-sm mt-1"
              style={{ color: item.color }}
            >
              {"isScore" in item && item.isScore
                ? item.bal.toFixed(6)
                : item.bal.toFixed(item.label === "BTC" ? 8 : 4)}
            </div>
            <div
              className="font-mono text-[9px] mt-0.5"
              style={{ color: C.muted }}
            >
              {"isScore" in item && item.isScore
                ? `COH: ${item.price.toFixed(6)}`
                : `$${item.usd.toLocaleString("en-US", { maximumFractionDigits: 2 })}`}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── B. 22 Profit Streams ───────────────────────────────────────────────────────────────
const STREAM_GROUPS = [
  {
    label: "CHAIN",
    color: "oklch(0.78 0.18 85)",
    streams: [
      { key: "s1", label: "BTC MOMENTUM" },
      { key: "s2", label: "ETH MOMENTUM" },
      { key: "s3", label: "SOL MOMENTUM" },
      { key: "s4", label: "ICP MOMENTUM" },
      { key: "s5", label: "BTC ARB" },
      { key: "s6", label: "ETH ARB" },
    ],
  },
  {
    label: "DEFI",
    color: "oklch(0.72 0.15 200)",
    streams: [
      { key: "s7", label: "ICPSWAP YIELD" },
      { key: "s8", label: "SONIC YIELD" },
      { key: "s9", label: "LIDO RATE" },
      { key: "s10", label: "ROCKETPOOL" },
    ],
  },
  {
    label: "TERRITORY",
    color: "oklch(0.62 0.17 145)",
    streams: [
      { key: "s11", label: "TERRITORY DIV 1" },
      { key: "s12", label: "TERRITORY DIV 2" },
      { key: "s13", label: "TERRITORY DIV 3" },
      { key: "s14", label: "TERRITORY DIV 4" },
    ],
  },
  {
    label: "COUNCIL",
    color: "oklch(0.65 0.28 290)",
    streams: [
      { key: "s15", label: "SUCCESSION R1" },
      { key: "s16", label: "SUCCESSION R2" },
      { key: "s17", label: "SUCCESSION R3" },
      { key: "s18", label: "SUCCESSION R4" },
    ],
  },
  {
    label: "QUANTUM",
    color: "oklch(0.75 0.18 62)",
    streams: [
      { key: "s19", label: "PATENT LICENSING 1" },
      { key: "s20", label: "PATENT LICENSING 2" },
      { key: "s21", label: "BATTERY DISCHARGE" },
      { key: "s22", label: "QUANTUM BONUS" },
    ],
  },
] as const;

function ProfitStreamsPanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { profitStreams, treasuryState } = eng;
  const ps = profitStreams;
  const allVals = ps
    ? STREAM_GROUPS.flatMap((g) =>
        g.streams.map((s) => ((ps as any)[s.key] as number) ?? 0),
      )
    : [];
  const maxVal = Math.max(...allVals, 1);

  return (
    <PanelBox>
      <SecTitle>■ 22 SOVEREIGN PROFIT STREAMS</SecTitle>
      <div className="space-y-5">
        {STREAM_GROUPS.map((group) => (
          <div key={group.label}>
            <div
              className="font-mono text-[7px] tracking-[0.4em] mb-2 pb-1 border-b"
              style={{ color: group.color, borderColor: `${group.color}22` }}
            >
              {group.label} CATEGORY
            </div>
            <div className="space-y-1.5">
              {group.streams.map((stream, i) => {
                const val = ps ? (((ps as any)[stream.key] as number) ?? 0) : 0;
                const pct = maxVal > 0 ? val / maxVal : 0;
                return (
                  <div
                    key={stream.key}
                    data-ocid={`treasury.stream.item.${i + 1}`}
                    className="flex items-center gap-3"
                  >
                    <span
                      className="font-mono text-[8px] w-28 shrink-0"
                      style={{ color: C.muted }}
                    >
                      {stream.label}
                    </span>
                    <div className="flex-1 h-1.5 bg-white/5">
                      <div
                        className="h-full transition-all"
                        style={{
                          width: `${pct * 100}%`,
                          background: group.color,
                        }}
                      />
                    </div>
                    <span
                      className="font-mono text-[9px] w-24 text-right shrink-0"
                      style={{ color: group.color }}
                    >
                      {val.toFixed(6)}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      <div
        className="flex items-center justify-between mt-5 pt-3 border-t"
        style={{ borderColor: "rgba(255,255,255,0.06)" }}
      >
        <Lbl>TOTAL PROFIT ALL STREAMS</Lbl>
        <Num color={C.gold} size="text-sm">
          {(treasuryState?.totalProfitAllStreams ?? ps?.total ?? 0).toFixed(8)}
        </Num>
      </div>
      {(treasuryState?.championPool ?? 0) > 0 && (
        <div className="flex items-center justify-between mt-2">
          <Lbl>CHAMPION POOL</Lbl>
          <Num color={C.amber} size="text-sm">
            {(treasuryState?.championPool ?? 0).toFixed(8)}
          </Num>
        </div>
      )}
    </PanelBox>
  );
}

// ── C. FORMA Compounding + Jacob's Ladder ──────────────────────────────────────────
function FormaCompoundPanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { fullState, formaProjVelocity } = eng;
  const forma = fullState?.formaCapital ?? 0;
  const rate = forma > 0 ? (formaProjVelocity - forma) / forma / 1000 : 0;

  // Entropy from neurochemicals is computed in the hook; use entropyScore
  const { entropyScore } = eng;

  return (
    <PanelBox>
      <SecTitle>ƒ FORMA COMPOUNDING ENGINE</SecTitle>
      <div className="mb-4">
        <Lbl>FORMA CAPITAL</Lbl>
        <div
          className="font-mono text-2xl font-bold mt-1"
          style={{ color: C.gold, textShadow: `0 0 20px ${C.gold}55` }}
        >
          ƒ{" "}
          {forma.toLocaleString("en-US", {
            minimumFractionDigits: 6,
            maximumFractionDigits: 6,
          })}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 mb-4">
        <div>
          <Lbl>COMPOUND RATE / BEAT</Lbl>
          <Num color={C.green} size="text-xs">
            {(rate * 100).toFixed(8)}%
          </Num>
        </div>
        <div>
          <Lbl>VON NEUMANN ENTROPY</Lbl>
          <Num color={C.purple} size="text-xs">
            {entropyScore.toFixed(6)}
          </Num>
        </div>
      </div>

      <div className="space-y-1.5 mb-4">
        <Lbl>FORMA PROJECTIONS</Lbl>
        {[
          { beats: 1000, label: "+1,000 BEATS" },
          { beats: 10000, label: "+10,000 BEATS" },
        ].map(({ beats, label }) => {
          const proj = formaProject(forma, Math.max(0, rate), 1.0, beats);
          return (
            <div key={beats} className="flex justify-between mt-1">
              <Lbl>{label}</Lbl>
              <Num color={C.gold} size="text-[10px]">
                ƒ{" "}
                {proj.toLocaleString("en-US", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}
              </Num>
            </div>
          );
        })}
      </div>

      <div className="flex justify-between">
        <Lbl>SPECTRAL COHERENCE</Lbl>
        <Num color={C.cyan} size="text-[10px]">
          {(1 - entropyScore).toFixed(6)}
        </Num>
      </div>
    </PanelBox>
  );
}

function JacobsLadderPanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { fullState } = eng;
  const rung = Number(fullState?.jacobRung ?? 0n);
  const sacesi = fullState?.sacesiTarget ?? 1.0;
  const jVel = jacobsVelocity(rung, sacesi);

  const rungData = [
    { label: "RUNG 0", mult: "1.0x", beatsRequired: 0, desc: "GENESIS STATE" },
    {
      label: "RUNG 1",
      mult: "1.1x",
      beatsRequired: 1000,
      desc: "1,000 BEATS @ 90%",
    },
    {
      label: "RUNG 2",
      mult: "1.1x",
      beatsRequired: 2000,
      desc: "2,000 BEATS @ 90%",
    },
    {
      label: "RUNG 3",
      mult: "1.2x",
      beatsRequired: 3000,
      desc: "3,000 BEATS @ 90%",
    },
    {
      label: "RUNG 4",
      mult: "1.5x",
      beatsRequired: 4000,
      desc: "4,000 BEATS @ 90%",
    },
  ];

  return (
    <PanelBox>
      <SecTitle>■ JACOB'S LADDER</SecTitle>
      <div className="space-y-2 mb-4">
        {rungData.map((r, i) => {
          const isActive = i === rung;
          const isPassed = i < rung;
          const color = isPassed ? C.gold : isActive ? C.amber : C.dim;
          return (
            <div
              key={r.label}
              className="flex items-center gap-3 px-3 py-2 border"
              style={{
                borderColor: `${color}33`,
                background: isActive ? `${color}08` : "transparent",
                boxShadow: isActive ? `0 0 12px ${color}22` : undefined,
              }}
            >
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="font-mono text-[9px]" style={{ color }}>
                    {r.label}
                  </span>
                  {isActive && (
                    <span
                      className="font-mono text-[6px] px-1 animate-beat"
                      style={{
                        color: C.amber,
                        border: `1px solid ${C.amber}44`,
                      }}
                    >
                      CURRENT
                    </span>
                  )}
                </div>
                <span
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  {r.desc}
                </span>
              </div>
              <span className="font-mono text-xs" style={{ color }}>
                {r.mult}
              </span>
            </div>
          );
        })}
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div>
          <Lbl>JACOB VELOCITY</Lbl>
          <Num color={C.gold} size="text-sm">
            {jVel.toFixed(6)}x
          </Num>
        </div>
        <div>
          <Lbl>SACESI TARGET</Lbl>
          <Num color={C.purple} size="text-sm">
            {sacesi.toFixed(8)}
          </Num>
        </div>
      </div>
    </PanelBox>
  );
}

// ── D. Treasury State + Creator Reserve ────────────────────────────────────────────
function TreasuryStatePanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { treasuryState, mtcState } = eng;
  const ts = treasuryState;
  const ms = mtcState;

  return (
    <PanelBox>
      <SecTitle>■ TREASURY STATE</SecTitle>
      <div className="space-y-2">
        {[
          {
            label: "ICP BALANCE",
            val: ts?.icpBalance.toFixed(8) ?? "—",
            color: C.purple,
          },
          {
            label: "ICP STAKED",
            val: ts?.icpStaked.toFixed(8) ?? "—",
            color: C.purple,
          },
          {
            label: "ICP PRICE",
            val: ts?.icpPrice ? `$${ts.icpPrice.toFixed(4)}` : "—",
            color: C.text,
          },
          {
            label: "BTC BALANCE",
            val: ts?.btcBalance.toFixed(8) ?? "—",
            color: C.amber,
          },
          {
            label: "BTC HARD FLOOR",
            val: ts?.btcHardFloor?.toFixed(8) ?? "—",
            color: C.amber,
          },
          {
            label: "BTC PRICE",
            val: ts?.btcPrice ? `$${ts.btcPrice.toLocaleString()}` : "—",
            color: C.text,
          },
          {
            label: "ETH BALANCE",
            val: ts?.ethBalance.toFixed(8) ?? "—",
            color: C.cyan,
          },
          {
            label: "ETH PRICE",
            val: ts?.ethPrice ? `$${ts.ethPrice.toFixed(2)}` : "—",
            color: C.text,
          },
          {
            label: "MTC CIRCULATING",
            val:
              ms?.circulating.toFixed(6) ??
              ts?.mtcCirculating.toFixed(6) ??
              "—",
            color: C.gold,
          },
          {
            label: "MTC BURNED",
            val: ms?.burned.toFixed(6) ?? ts?.mtcBurned.toFixed(6) ?? "—",
            color: C.red,
          },
          {
            label: "MTC PRICE",
            val: ms?.price.toFixed(8) ?? ts?.mtcPrice.toFixed(8) ?? "—",
            color: C.gold,
          },
          {
            label: "BEAT COUNT",
            val: ts?.beatCount.toLocaleString() ?? "—",
            color: C.dim,
          },
        ].map(({ label, val, color }) => (
          <div key={label} className="flex justify-between">
            <Lbl>{label}</Lbl>
            <Num size="text-[10px]" color={color}>
              {val}
            </Num>
          </div>
        ))}
      </div>
    </PanelBox>
  );
}

type WithdrawalResult = {
  success: boolean;
  blockIndex?: bigint;
  error?: string;
} | null;

function CreatorReservePanel({
  eng,
  isAuthenticated,
  actor,
}: {
  eng: ReturnType<typeof useIntelligenceEngine>;
  isAuthenticated: boolean;
  actor: any;
}) {
  const { creatorReserve } = eng;
  const cr = creatorReserve;
  const [withdrawAmt, setWithdrawAmt] = useState("");
  const [walletAddr, setWalletAddr] = useState("");
  const [withdrawalPending, setWithdrawalPending] = useState(false);
  const [withdrawalResult, setWithdrawalResult] =
    useState<WithdrawalResult>(null);

  const handleWithdraw = async () => {
    if (!actor || !withdrawAmt || !walletAddr) return;
    setWithdrawalPending(true);
    setWithdrawalResult(null);
    try {
      const res = await actor.withdrawToExternalWallet(
        Number(withdrawAmt),
        walletAddr,
      );
      const result: WithdrawalResult = {
        success: res.success,
        blockIndex: res.blockIndex?.[0] ?? res.blockIndex,
        error: res.error?.[0] ?? res.error,
      };
      setWithdrawalResult(result);
      if (result.success) {
        toast.success(
          `LIBERATOR EXECUTED — Block #${result.blockIndex ?? "confirmed"}`,
        );
        setWithdrawAmt("");
        setWalletAddr("");
      } else {
        toast.error(result.error ?? "Withdrawal failed");
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Withdrawal error";
      setWithdrawalResult({ success: false, error: msg });
      toast.error(msg);
    } finally {
      setWithdrawalPending(false);
    }
  };

  return (
    <PanelBox>
      <SecTitle>
        ■ THESAURUS PARALLAXI — CREATOR RESERVE — ALFREDO MEDINA HERNANDEZ
      </SecTitle>
      <div className="space-y-2 mb-5">
        {[
          {
            label: "ICP RESERVE",
            val: cr?.icpReserve.toFixed(8) ?? "—",
            color: C.purple,
          },
          {
            label: "BTC RESERVE",
            val: cr?.btcReserve.toFixed(8) ?? "—",
            color: C.amber,
          },
          {
            label: "ETH RESERVE",
            val: cr?.ethReserve.toFixed(8) ?? "—",
            color: C.cyan,
          },
          {
            label: "MTC RESERVE",
            val: cr?.mtcReserve.toFixed(6) ?? "—",
            color: C.gold,
          },
          {
            label: "WITHDRAWABLE ICP",
            val: cr?.withdrawableIcp.toFixed(8) ?? "—",
            color: C.green,
          },
          {
            label: "TOTAL WITHDRAWN",
            val: cr?.totalWithdrawn.toFixed(8) ?? "—",
            color: C.dim,
          },
          {
            label: "TOTAL USD EQUIV",
            val: cr?.totalUsdEquivalent
              ? `$${cr.totalUsdEquivalent.toLocaleString("en-US", { minimumFractionDigits: 2 })}`
              : "—",
            color: C.gold,
          },
        ].map(({ label, val, color }) => (
          <div key={label} className="flex justify-between">
            <Lbl>{label}</Lbl>
            <Num size="text-[10px]" color={color}>
              {val}
            </Num>
          </div>
        ))}
      </div>

      <div className="relative">
        {!isAuthenticated && <LockOverlay />}
        <Lbl>WITHDRAW TO EXTERNAL WALLET</Lbl>
        <div className="space-y-2 mt-2">
          <input
            type="number"
            value={withdrawAmt}
            onChange={(e) => setWithdrawAmt(e.target.value)}
            placeholder="AMOUNT (ICP)"
            className="w-full bg-transparent border px-3 py-2 font-mono text-xs outline-none"
            style={{ borderColor: `${C.gold}44`, color: C.text }}
            data-ocid="treasury.withdraw.input"
            disabled={!isAuthenticated || withdrawalPending}
          />
          <input
            type="text"
            value={walletAddr}
            onChange={(e) => setWalletAddr(e.target.value)}
            placeholder="WALLET ADDRESS"
            className="w-full bg-transparent border px-3 py-2 font-mono text-xs outline-none"
            style={{ borderColor: `${C.gold}44`, color: C.text }}
            data-ocid="treasury.wallet.input"
            disabled={!isAuthenticated || withdrawalPending}
          />
          <button
            type="button"
            onClick={handleWithdraw}
            disabled={
              !isAuthenticated ||
              withdrawalPending ||
              !withdrawAmt ||
              !walletAddr
            }
            data-ocid="treasury.withdraw.submit_button"
            className="w-full py-2.5 font-mono text-[9px] tracking-[0.3em] border transition-all disabled:opacity-40"
            style={{ borderColor: `${C.gold}55`, color: C.gold }}
          >
            {withdrawalPending ? (
              <span className="flex items-center justify-center gap-2">
                <span className="animate-pulse">●</span> LIBERATOR EXECUTING...
              </span>
            ) : (
              "INITIATE WITHDRAWAL — LIBERATOR"
            )}
          </button>
          {withdrawalPending && (
            <div
              className="font-mono text-[8px] text-center animate-pulse"
              style={{ color: C.amber }}
              data-ocid="treasury.withdraw.loading_state"
            >
              LIBERATOR EXECUTING — ICP TRANSFER IN PROGRESS...
            </div>
          )}
          {withdrawalResult && !withdrawalPending && (
            <div
              className="px-3 py-2 border font-mono text-[9px] space-y-1"
              style={{
                borderColor: withdrawalResult.success
                  ? `${C.green}55`
                  : `${C.red}55`,
                background: withdrawalResult.success
                  ? `${C.green}08`
                  : `${C.red}08`,
                color: withdrawalResult.success ? C.green : C.red,
              }}
              data-ocid={
                withdrawalResult.success
                  ? "treasury.withdraw.success_state"
                  : "treasury.withdraw.error_state"
              }
            >
              {withdrawalResult.success ? (
                <>
                  <div className="tracking-wider">
                    ✓ LIBERATOR EXECUTED — ICP TRANSFER CONFIRMED
                  </div>
                  {withdrawalResult.blockIndex != null && (
                    <div style={{ color: C.cyan }}>
                      BLOCK INDEX: {withdrawalResult.blockIndex.toString()}
                    </div>
                  )}
                </>
              ) : (
                <div className="tracking-wider">
                  ✗ {withdrawalResult.error ?? "TRANSFER FAILED"}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </PanelBox>
  );
}

// ── E. MTC Tokenomics + Sovereign Audit Feed ───────────────────────────────────────
function MtcTokenomicsPanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const { mtcState, tokenVelocityScore } = eng;
  const ms = mtcState;
  if (!ms) {
    return (
      <PanelBox>
        <SecTitle>■ MTC TOKENOMICS</SecTitle>
        <div
          className="font-mono text-[9px] text-center py-8"
          style={{ color: C.muted }}
        >
          LOADING...
        </div>
      </PanelBox>
    );
  }

  const total = ms.genesisSupply || 1;
  const circPct = (ms.circulating / total) * 100;
  const burnPct = (ms.burned / total) * 100;
  const creatorPct = (ms.creatorHolding / total) * 100;

  // SVG supply ring
  const R = 60;
  const cx = 80;
  const cy = 80;
  const circumference = 2 * Math.PI * R;
  const circStroke = (circPct / 100) * circumference;
  const burnStroke = (burnPct / 100) * circumference;
  const creatorStroke = (creatorPct / 100) * circumference;

  return (
    <PanelBox>
      <SecTitle>■ MTC TOKENOMICS</SecTitle>
      <div className="flex items-center gap-6">
        {/* SVG Ring */}
        <svg
          width="160"
          height="160"
          className="shrink-0"
          role="img"
          aria-label="MTC Token Supply Distribution"
        >
          {/* Background circle */}
          <circle
            cx={cx}
            cy={cy}
            r={R}
            fill="none"
            stroke="rgba(255,255,255,0.05)"
            strokeWidth="12"
          />
          {/* Circulating */}
          <circle
            cx={cx}
            cy={cy}
            r={R}
            fill="none"
            stroke={C.gold}
            strokeWidth="12"
            strokeDasharray={`${circStroke} ${circumference - circStroke}`}
            strokeDashoffset={circumference * 0.25}
            strokeLinecap="square"
          />
          {/* Burned */}
          <circle
            cx={cx}
            cy={cy}
            r={R}
            fill="none"
            stroke={C.red}
            strokeWidth="12"
            strokeDasharray={`${burnStroke} ${circumference - burnStroke}`}
            strokeDashoffset={circumference * 0.25 - circStroke}
            strokeLinecap="square"
          />
          {/* Creator */}
          <circle
            cx={cx}
            cy={cy}
            r={R}
            fill="none"
            stroke={C.purple}
            strokeWidth="12"
            strokeDasharray={`${creatorStroke} ${circumference - creatorStroke}`}
            strokeDashoffset={circumference * 0.25 - circStroke - burnStroke}
            strokeLinecap="square"
          />
          <text
            x={cx}
            y={cy - 8}
            textAnchor="middle"
            className="font-mono"
            style={{
              fill: C.gold,
              fontSize: 11,
              fontFamily: "Geist Mono, monospace",
            }}
          >
            MTC
          </text>
          <text
            x={cx}
            y={cy + 10}
            textAnchor="middle"
            style={{
              fill: C.muted,
              fontSize: 8,
              fontFamily: "Geist Mono, monospace",
            }}
          >
            {ms.genesisSupply.toLocaleString()}
          </text>
        </svg>

        {/* Legend + values */}
        <div className="space-y-3">
          {[
            {
              label: "CIRCULATING",
              val: ms.circulating,
              pct: circPct,
              color: C.gold,
            },
            { label: "BURNED", val: ms.burned, pct: burnPct, color: C.red },
            {
              label: "CREATOR HOLDING",
              val: ms.creatorHolding,
              pct: creatorPct,
              color: C.purple,
            },
          ].map((item) => (
            <div key={item.label}>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2" style={{ background: item.color }} />
                <Lbl>{item.label}</Lbl>
              </div>
              <Num color={item.color} size="text-xs">
                {item.val.toLocaleString("en-US", { maximumFractionDigits: 2 })}
              </Num>
              <Num size="text-[8px]" color={C.muted}>
                {" "}
                ({item.pct.toFixed(2)}%)
              </Num>
            </div>
          ))}
          <div>
            <Lbl>TOKEN VELOCITY</Lbl>
            <div className="flex items-center gap-2 mt-1">
              <div className="w-20 h-1 bg-white/5">
                <div
                  style={{
                    width: `${tokenVelocityScore * 100}%`,
                    height: "100%",
                    background: C.cyan,
                  }}
                />
              </div>
              <Num color={C.cyan} size="text-[10px]">
                {(tokenVelocityScore * 100).toFixed(2)}%
              </Num>
            </div>
          </div>
        </div>
      </div>
    </PanelBox>
  );
}

function SovereignAuditPanel() {
  const { actor } = useActor();
  const [auditEntries, setAuditEntries] = useState<
    Array<{
      beat: bigint;
      eventType: string;
      detail: string;
      timestamp: bigint;
    }>
  >([]);

  const RELEVANT_TYPES = [
    "MINT",
    "PROFIT",
    "FORMA",
    "TREASURY",
    "BURN",
    "GENESIS",
  ];

  useEffect(() => {
    if (!actor) return;
    let cancelled = false;
    const fetch = async () => {
      try {
        const log = await (actor as any).px_getAuditLog(50n);
        if (!cancelled && Array.isArray(log)) {
          setAuditEntries(
            log
              .filter((e: any) =>
                RELEVANT_TYPES.some((t) =>
                  e.eventType?.toUpperCase().includes(t),
                ),
              )
              .slice(0, 20),
          );
        }
      } catch {
        /* silent */
      }
    };
    fetch();
    const interval = setInterval(fetch, 5000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [actor]);

  const typeColor = (eventType: string) => {
    const t = eventType.toUpperCase();
    if (t.includes("MINT")) return C.green;
    if (t.includes("BURN")) return C.red;
    if (t.includes("PROFIT")) return C.gold;
    if (t.includes("FORMA")) return C.cyan;
    if (t.includes("TREASURY")) return C.purple;
    return C.muted;
  };

  return (
    <PanelBox>
      <SecTitle>■ SOVEREIGN AUDIT FEED</SecTitle>
      <div
        className="space-y-1 overflow-y-auto"
        style={{ maxHeight: 320 }}
        data-ocid="treasury.audit.panel"
      >
        {auditEntries.length === 0 && (
          <div
            className="font-mono text-[9px] text-center py-8"
            style={{ color: C.muted }}
            data-ocid="treasury.audit.empty_state"
          >
            NO RELEVANT AUDIT EVENTS
          </div>
        )}
        {auditEntries.map((entry, i) => (
          <motion.div
            key={`${entry.beat}-${i}`}
            initial={{ opacity: 0, x: -4 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.02 }}
            data-ocid={`treasury.audit.item.${i + 1}`}
            className="flex items-start gap-2 px-2 py-1.5 border-l-2"
            style={{
              borderLeftColor: typeColor(entry.eventType),
              background: `${typeColor(entry.eventType)}06`,
            }}
          >
            <span
              className="font-mono text-[7px] tracking-widest shrink-0 mt-0.5 px-1"
              style={{
                color: typeColor(entry.eventType),
                border: `1px solid ${typeColor(entry.eventType)}44`,
              }}
            >
              {entry.eventType.slice(0, 8)}
            </span>
            <span
              className="font-mono text-[8px] leading-relaxed flex-1"
              style={{ color: C.text }}
            >
              {entry.detail}
            </span>
            <span
              className="font-mono text-[7px] shrink-0"
              style={{ color: C.muted }}
            >
              #{Number(entry.beat).toLocaleString()}
            </span>
          </motion.div>
        ))}
      </div>
    </PanelBox>
  );
}

// ── Main TreasuryTab ───────────────────────────────────────────────────────────────────
export function TreasuryTab() {
  const { identity } = useInternetIdentity();
  const { actor } = useActor();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();
  const eng = useIntelligenceEngine();

  return (
    <div className="space-y-5" data-ocid="treasury.page">
      {/* 0: Clearing House (new) */}
      <ClearingHousePanel eng={eng} />
      {/* A: Sovereign Value Header */}
      <SovereignValueHeader eng={eng} />

      {/* B: 22 Profit Streams */}
      <ProfitStreamsPanel eng={eng} />

      {/* C: FORMA + Jacob's Ladder */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <FormaCompoundPanel eng={eng} />
        <JacobsLadderPanel eng={eng} />
      </div>

      {/* D: Treasury State + Creator Reserve */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <TreasuryStatePanel eng={eng} />
        <CreatorReservePanel
          eng={eng}
          isAuthenticated={isAuthenticated}
          actor={actor}
        />
      </div>

      {/* E: MTC Tokenomics + Sovereign Audit Feed */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <MtcTokenomicsPanel eng={eng} />
        <SovereignAuditPanel />
      </div>

      {/* F: Enhanced Treasury State + Enhanced Creator Reserve */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <TreasuryDetailPanel />
        <CreatorReserveDetailPanel />
      </div>

      {/* G: LIBERATOR STATUS — DOMUS LIBERATORIS */}
      <LiberatorStatusPanel />

      {/* H: Withdrawal Log — ANIMA CHAIN */}
      <WithdrawalLogPanel />

      {/* I: Neuron Fleet */}
      <NeuronFleetPanel />
    </div>
  );
}

// ── Clearing House Panel (injected at top of TreasuryTab) ─────────────────────────
function ClearingHousePanel({
  eng,
}: { eng: ReturnType<typeof useIntelligenceEngine> }) {
  const {
    clearingReserves,
    tokenExchangeRates,
    clearingHealth,
    settlementStats,
    arbitrageSpread,
  } = eng;
  const res = clearingReserves;
  const rates = tokenExchangeRates;

  const healthColor =
    clearingHealth > 0.7 ? C.green : clearingHealth > 0.4 ? C.amber : C.red;

  const TOKEN_COLORS: Record<string, string> = {
    GTK: C.gold,
    MTH: C.gold,
    MRC: C.gold,
    CVT: C.cyan,
    VCT: C.cyan,
    KNT: C.cyan,
    RST: C.cyan,
    LGT: C.cyan,
    SBT: C.muted,
    HBT: C.muted,
    DRT: C.muted,
    OMT: C.muted,
    MTC: C.gold,
  };

  const reserveEntries = res
    ? [
        { code: "MTC", val: res.mtc },
        { code: "GTK", val: res.gtk },
        { code: "MTH", val: res.mth },
        { code: "MRC", val: res.mrc },
        { code: "CVT", val: res.cvt },
        { code: "VCT", val: res.vct },
        { code: "KNT", val: res.knt },
        { code: "RST", val: res.rst },
        { code: "LGT", val: res.lgt },
        { code: "SBT", val: res.sbt },
        { code: "HBT", val: res.hbt },
        { code: "DRT", val: res.drt },
        { code: "OMT", val: res.omt },
      ]
    : [];

  const maxReserve = Math.max(...reserveEntries.map((e) => e.val), 1);

  return (
    <div
      className="border p-5"
      style={{
        borderColor: `${C.cyan}22`,
        background: `${C.cyan}04`,
        boxShadow: `0 0 40px ${C.cyan}06`,
      }}
      data-ocid="treasury.clearing.section"
    >
      <div
        className="font-mono text-[8px] tracking-[0.6em] mb-4 pb-3 border-b flex items-center justify-between"
        style={{ color: C.cyan, borderColor: `${C.cyan}22` }}
      >
        <span>■ SOVEREIGN CLEARING HOUSE</span>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5">
            <Lbl>HEALTH</Lbl>
            <div className="flex items-center gap-1.5 ml-1">
              <div
                className="w-20 h-1"
                style={{ background: "rgba(255,255,255,0.06)" }}
              >
                <div
                  style={{
                    width: `${clearingHealth * 100}%`,
                    height: "100%",
                    background: healthColor,
                  }}
                />
              </div>
              <Num color={healthColor} size="text-[10px]">
                {(clearingHealth * 100).toFixed(0)}%
              </Num>
            </div>
          </div>
          {(settlementStats?.totalSettlements ?? 0n) > 0n && (
            <Num color={C.cyan} size="text-[9px]">
              {Number(settlementStats!.totalSettlements).toLocaleString()}{" "}
              CLEARED
            </Num>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Reserve Grid */}
        <div className="lg:col-span-1">
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.muted }}
          >
            CLEARING RESERVES
          </div>
          <div className="space-y-1.5">
            {reserveEntries.map(({ code, val }) => (
              <div key={code} className="flex items-center gap-2">
                <span
                  className="font-mono text-[7px] tracking-widest w-8 shrink-0"
                  style={{ color: TOKEN_COLORS[code] ?? C.muted }}
                >
                  {code}
                </span>
                <div
                  className="flex-1 h-1.5"
                  style={{ background: "rgba(255,255,255,0.04)" }}
                >
                  <div
                    style={{
                      width: `${(val / maxReserve) * 100}%`,
                      height: "100%",
                      background: TOKEN_COLORS[code] ?? C.muted,
                      opacity: 0.6,
                    }}
                  />
                </div>
                <Num size="text-[8px]" color={C.muted}>
                  {val > 0
                    ? val >= 1000
                      ? `${(val / 1000).toFixed(1)}K`
                      : val.toFixed(2)
                    : "—"}
                </Num>
              </div>
            ))}
          </div>
          <div
            className="flex justify-between mt-3 pt-2 border-t"
            style={{ borderColor: "rgba(255,255,255,0.05)" }}
          >
            <Lbl>TOTAL RESERVE</Lbl>
            <Num color={C.gold} size="text-[10px]">
              {res
                ? res.total >= 1000
                  ? `${(res.total / 1000).toFixed(2)}K`
                  : res.total.toFixed(2)
                : "—"}
            </Num>
          </div>
          <div className="flex justify-between">
            <Lbl>PROFIT ROUTED</Lbl>
            <Num color={C.green} size="text-[10px]">
              {res
                ? res.profitRouted > 0
                  ? res.profitRouted.toFixed(6)
                  : "—"
                : "—"}
            </Num>
          </div>
        </div>

        {/* Exchange Rates Table */}
        <div className="lg:col-span-1">
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.muted }}
          >
            EXCHANGE RATES
          </div>
          <div
            className="flex items-center gap-1 font-mono text-[7px] mb-1 pb-1 border-b"
            style={{ color: C.dim, borderColor: "rgba(255,255,255,0.04)" }}
          >
            <span className="w-10">TOKEN</span>
            <span className="flex-1">FORMA RATE</span>
            <span className="w-16 text-right">ICP RATE</span>
          </div>
          <div style={{ maxHeight: 200, overflowY: "auto" }}>
            {rates && rates.codes.length > 0 ? (
              rates.codes.map((code, i) => (
                <div key={code} className="flex items-center gap-1 py-0.5">
                  <span
                    className="font-mono text-[7px] w-10 shrink-0"
                    style={{ color: TOKEN_COLORS[code] ?? C.muted }}
                  >
                    {code}
                  </span>
                  <span
                    className="font-mono text-[8px] flex-1 tabular-nums"
                    style={{ color: C.gold }}
                  >
                    ƒ{(rates.rates[i] ?? 0).toFixed(4)}
                  </span>
                  <span
                    className="font-mono text-[8px] w-16 text-right tabular-nums"
                    style={{ color: C.cyan }}
                  >
                    {(rates.icp[i] ?? 0).toFixed(6)}
                  </span>
                </div>
              ))
            ) : (
              <div
                className="font-mono text-[9px] text-center py-4"
                style={{ color: C.dim }}
              >
                LOADING RATES...
              </div>
            )}
          </div>
        </div>

        {/* Clearing Metrics */}
        <div className="lg:col-span-1">
          <div
            className="font-mono text-[7px] tracking-[0.4em] mb-2"
            style={{ color: C.muted }}
          >
            CLEARING METRICS
          </div>
          <div className="space-y-2">
            {[
              {
                label: "TOTAL SETTLEMENTS",
                val: Number(
                  settlementStats?.totalSettlements ?? 0n,
                ).toLocaleString(),
                color: C.cyan,
              },
              {
                label: "FORMA CLEARED",
                val: settlementStats?.totalFormaCleared
                  ? `ƒ${settlementStats.totalFormaCleared >= 1000 ? `${(settlementStats.totalFormaCleared / 1000).toFixed(2)}K` : settlementStats.totalFormaCleared.toFixed(2)}`
                  : "—",
                color: C.gold,
              },
              {
                label: "ARB SPREAD",
                val: `${(arbitrageSpread * 100).toFixed(3)}%`,
                color: arbitrageSpread > 0.05 ? C.amber : C.green,
              },
              {
                label: "CLEARING HEALTH",
                val: `${(clearingHealth * 100).toFixed(1)}%`,
                color: healthColor,
              },
              {
                label: "PROFIT ROUTED",
                val: res?.profitRouted ? res.profitRouted.toFixed(6) : "—",
                color: C.green,
              },
            ].map(({ label, val, color }) => (
              <div key={label} className="flex justify-between items-center">
                <Lbl>{label}</Lbl>
                <Num size="text-[10px]" color={color}>
                  {val}
                </Num>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Enhanced Treasury Detail Panel ───────────────────────────────────────────
function TreasuryDetailPanel() {
  const { data: ts } = useTreasuryDetail();

  const icpUsd = (ts?.icpBalance ?? 0) * (ts?.icpPrice ?? 0);
  const btcUsd = (ts?.btcBalance ?? 0) * (ts?.btcPrice ?? 0);
  const ethUsd = (ts?.ethBalance ?? 0) * (ts?.ethPrice ?? 0);
  const totalUsd = icpUsd + btcUsd + ethUsd;

  const btcFloorPct =
    ts && ts.btcBalance > 0 ? (ts.btcHardFloor / ts.btcBalance) * 100 : 0;

  return (
    <PanelBox>
      <SecTitle>■ TREASURY STATE</SecTitle>

      {/* ICP Row */}
      <div
        className="mb-4 pb-4 border-b"
        style={{ borderColor: "rgba(255,255,255,0.05)" }}
        data-ocid="treasury.detail.icp.section"
      >
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-2"
          style={{ color: C.purple }}
        >
          ICP
        </div>
        <div className="grid grid-cols-3 gap-2">
          {[
            {
              label: "BALANCE",
              val: ts?.icpBalance.toFixed(8) ?? "—",
              color: C.purple,
            },
            {
              label: "STAKED",
              val: ts?.icpStaked.toFixed(8) ?? "—",
              color: C.purple,
            },
            {
              label: "PRICE",
              val: ts?.icpPrice ? `$${ts.icpPrice.toFixed(4)}` : "—",
              color: C.text,
            },
          ].map(({ label, val, color }) => (
            <div key={label}>
              <Lbl>{label}</Lbl>
              <div className="font-mono text-[10px] mt-0.5" style={{ color }}>
                {val}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* BTC Row */}
      <div
        className="mb-4 pb-4 border-b"
        style={{ borderColor: "rgba(255,255,255,0.05)" }}
        data-ocid="treasury.detail.btc.section"
      >
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-2"
          style={{ color: C.amber }}
        >
          BTC
        </div>
        <div className="grid grid-cols-3 gap-2 mb-2">
          {[
            {
              label: "BALANCE",
              val: ts?.btcBalance.toFixed(8) ?? "—",
              color: C.amber,
            },
            {
              label: "HARD FLOOR",
              val: ts?.btcHardFloor.toFixed(8) ?? "—",
              color: C.red,
            },
            {
              label: "PRICE",
              val: ts?.btcPrice ? `$${ts.btcPrice.toLocaleString()}` : "—",
              color: C.text,
            },
          ].map(({ label, val, color }) => (
            <div key={label}>
              <Lbl>{label}</Lbl>
              <div className="font-mono text-[10px] mt-0.5" style={{ color }}>
                {val}
              </div>
            </div>
          ))}
        </div>
        {/* Hard floor threshold bar */}
        <div className="mt-2">
          <div className="flex justify-between mb-1">
            <Lbl>FLOOR COVERAGE</Lbl>
            <Num size="text-[8px]" color={btcFloorPct > 80 ? C.red : C.amber}>
              {btcFloorPct.toFixed(1)}%
            </Num>
          </div>
          <div
            className="h-1.5 w-full"
            style={{ background: "rgba(255,255,255,0.06)" }}
          >
            <div
              className="h-full transition-all"
              style={{
                width: `${Math.min(btcFloorPct, 100)}%`,
                background: btcFloorPct > 80 ? C.red : C.amber,
              }}
            />
          </div>
        </div>
      </div>

      {/* ETH Row */}
      <div
        className="mb-4 pb-4 border-b"
        style={{ borderColor: "rgba(255,255,255,0.05)" }}
        data-ocid="treasury.detail.eth.section"
      >
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-2"
          style={{ color: C.cyan }}
        >
          ETH
        </div>
        <div className="grid grid-cols-2 gap-2">
          {[
            {
              label: "BALANCE",
              val: ts?.ethBalance.toFixed(8) ?? "—",
              color: C.cyan,
            },
            {
              label: "PRICE",
              val: ts?.ethPrice ? `$${ts.ethPrice.toFixed(2)}` : "—",
              color: C.text,
            },
          ].map(({ label, val, color }) => (
            <div key={label}>
              <Lbl>{label}</Lbl>
              <div className="font-mono text-[10px] mt-0.5" style={{ color }}>
                {val}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* MTC Row */}
      <div
        className="mb-4 pb-4 border-b"
        style={{ borderColor: "rgba(255,255,255,0.05)" }}
        data-ocid="treasury.detail.mtc.section"
      >
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-2"
          style={{ color: C.gold }}
        >
          MTC
        </div>
        <div className="grid grid-cols-3 gap-2">
          {[
            {
              label: "CIRCULATING",
              val: ts?.mtcCirculating.toFixed(6) ?? "—",
              color: C.gold,
            },
            {
              label: "BURNED",
              val: ts?.mtcBurned.toFixed(6) ?? "—",
              color: C.red,
            },
            {
              label: "PRICE",
              val: ts?.mtcPrice ? `$${ts.mtcPrice.toFixed(8)}` : "—",
              color: C.gold,
            },
          ].map(({ label, val, color }) => (
            <div key={label}>
              <Lbl>{label}</Lbl>
              <div className="font-mono text-[10px] mt-0.5" style={{ color }}>
                {val}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Asset allocation stacked bar */}
      <div>
        <Lbl>ASSET ALLOCATION (USD VALUE)</Lbl>
        <div className="mt-2 h-3 flex overflow-hidden">
          {totalUsd > 0 ? (
            <>
              <div
                style={{
                  width: `${(icpUsd / totalUsd) * 100}%`,
                  background: C.purple,
                  transition: "width 0.4s ease",
                }}
              />
              <div
                style={{
                  width: `${(btcUsd / totalUsd) * 100}%`,
                  background: C.amber,
                  transition: "width 0.4s ease",
                }}
              />
              <div
                style={{
                  width: `${(ethUsd / totalUsd) * 100}%`,
                  background: C.cyan,
                  transition: "width 0.4s ease",
                }}
              />
            </>
          ) : (
            <div
              className="w-full"
              style={{ background: "rgba(255,255,255,0.05)" }}
            />
          )}
        </div>
        <div className="flex gap-4 mt-1.5">
          {[
            { label: "ICP", color: C.purple, usd: icpUsd },
            { label: "BTC", color: C.amber, usd: btcUsd },
            { label: "ETH", color: C.cyan, usd: ethUsd },
          ].map(({ label, color, usd }) => (
            <div key={label} className="flex items-center gap-1">
              <div className="w-2 h-2 shrink-0" style={{ background: color }} />
              <span className="font-mono text-[7px]" style={{ color: C.muted }}>
                {label} $
                {usd.toLocaleString("en-US", { maximumFractionDigits: 0 })}
              </span>
            </div>
          ))}
        </div>
      </div>
    </PanelBox>
  );
}

// ── Enhanced Creator Reserve Detail Panel ─────────────────────────────────────
function CreatorReserveDetailPanel() {
  const { data: cr } = useCreatorReserve();
  const { actor } = useActor();
  const { identity } = useInternetIdentity();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();
  const [withdrawAmt, setWithdrawAmt] = useState("");
  const [walletAddr, setWalletAddr] = useState("");
  const [withdrawalPending, setWithdrawalPending] = useState(false);
  const [withdrawalResult, setWithdrawalResult] =
    useState<WithdrawalResult>(null);

  const handleWithdraw = async () => {
    if (!actor || !withdrawAmt || !walletAddr) return;
    setWithdrawalPending(true);
    setWithdrawalResult(null);
    try {
      const res = await (
        actor as unknown as Record<
          string,
          (...args: unknown[]) => Promise<{
            success: boolean;
            blockIndex?: bigint[] | bigint;
            error?: string[] | string;
          }>
        >
      ).withdrawToExternalWallet?.(Number(withdrawAmt), walletAddr);
      const result: WithdrawalResult = {
        success: res?.success ?? false,
        blockIndex: Array.isArray(res?.blockIndex)
          ? res.blockIndex[0]
          : res?.blockIndex,
        error: Array.isArray(res?.error) ? res.error[0] : res?.error,
      };
      setWithdrawalResult(result);
      if (result.success) {
        toast.success(
          `LIBERATOR EXECUTED — Block #${result.blockIndex ?? "confirmed"}`,
        );
        setWithdrawAmt("");
        setWalletAddr("");
      } else {
        toast.error(result.error ?? "Withdrawal failed");
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Withdrawal error";
      setWithdrawalResult({ success: false, error: msg });
      toast.error(msg);
    } finally {
      setWithdrawalPending(false);
    }
  };

  return (
    <PanelBox>
      {/* Founder sovereign title */}
      <div
        className="mb-4 pb-3 border-b"
        style={{ borderColor: `${C.gold}22` }}
      >
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-1"
          style={{ color: C.muted }}
        >
          SOVEREIGN CREATOR
        </div>
        <div
          className="font-mono text-sm tracking-[0.15em] font-bold"
          style={{ color: C.gold, textShadow: `0 0 20px ${C.gold}44` }}
        >
          {cr?.founderName ?? "ALFREDO MEDINA HERNANDEZ"}
        </div>
      </div>

      <SecTitle>■ CREATOR RESERVE</SecTitle>

      {/* 2×2 Reserve grid */}
      <div
        className="grid grid-cols-2 gap-3 mb-4"
        data-ocid="treasury.creator.reserves.section"
      >
        {[
          {
            label: "ICP RESERVE",
            val: cr?.icpReserve.toFixed(8) ?? "—",
            color: C.purple,
          },
          {
            label: "BTC RESERVE",
            val: cr?.btcReserve.toFixed(8) ?? "—",
            color: C.amber,
          },
          {
            label: "ETH RESERVE",
            val: cr?.ethReserve.toFixed(8) ?? "—",
            color: C.cyan,
          },
          {
            label: "MTC RESERVE",
            val: cr?.mtcReserve.toFixed(6) ?? "—",
            color: C.gold,
          },
        ].map(({ label, val, color }) => (
          <div
            key={label}
            className="border p-2.5"
            style={{ borderColor: `${color}22`, background: `${color}06` }}
          >
            <Lbl>{label}</Lbl>
            <div className="font-mono text-xs mt-1" style={{ color }}>
              {val}
            </div>
          </div>
        ))}
      </div>

      {/* Withdrawable / totals */}
      <div
        className="space-y-2 mb-4 pt-3 border-t"
        style={{ borderColor: "rgba(255,255,255,0.06)" }}
      >
        {[
          {
            label: "WITHDRAWABLE ICP",
            val: cr?.withdrawableIcp.toFixed(8) ?? "—",
            color: C.green,
          },
          {
            label: "TOTAL WITHDRAWN",
            val: cr?.totalWithdrawn.toFixed(8) ?? "—",
            color: C.dim,
          },
          {
            label: "TOTAL USD EQUIV",
            val: cr?.totalUsdEquiv
              ? `$${cr.totalUsdEquiv.toLocaleString("en-US", { minimumFractionDigits: 2 })}`
              : "—",
            color: C.gold,
          },
        ].map(({ label, val, color }) => (
          <div key={label} className="flex justify-between">
            <Lbl>{label}</Lbl>
            <Num size="text-[10px]" color={color}>
              {val}
            </Num>
          </div>
        ))}
      </div>

      {/* Withdraw form */}
      <div className="relative">
        {!isAuthenticated && (
          <div
            className="absolute inset-0 flex flex-col items-center justify-center gap-2 z-10"
            style={{
              background: "rgba(0,0,0,0.75)",
              backdropFilter: "blur(4px)",
            }}
          >
            <span
              className="font-mono text-[10px] tracking-[0.3em]"
              style={{ color: C.amber }}
            >
              ⚠ AUTH REQUIRED
            </span>
          </div>
        )}
        <Lbl>WITHDRAW TO EXTERNAL WALLET</Lbl>
        <div className="space-y-2 mt-2">
          <input
            type="number"
            value={withdrawAmt}
            onChange={(e) => setWithdrawAmt(e.target.value)}
            placeholder="AMOUNT (ICP)"
            className="w-full bg-transparent border px-3 py-2 font-mono text-xs outline-none"
            style={{ borderColor: `${C.gold}44`, color: C.text }}
            data-ocid="treasury.creator.withdraw.input"
            disabled={!isAuthenticated || withdrawalPending}
          />
          <input
            type="text"
            value={walletAddr}
            onChange={(e) => setWalletAddr(e.target.value)}
            placeholder="WALLET ADDRESS"
            className="w-full bg-transparent border px-3 py-2 font-mono text-xs outline-none"
            style={{ borderColor: `${C.gold}44`, color: C.text }}
            data-ocid="treasury.creator.wallet.input"
            disabled={!isAuthenticated || withdrawalPending}
          />
          <button
            type="button"
            onClick={handleWithdraw}
            disabled={
              !isAuthenticated ||
              withdrawalPending ||
              !withdrawAmt ||
              !walletAddr
            }
            data-ocid="treasury.creator.withdraw.submit_button"
            className="w-full py-2.5 font-mono text-[9px] tracking-[0.3em] border transition-all disabled:opacity-40"
            style={{ borderColor: `${C.gold}55`, color: C.gold }}
          >
            {withdrawalPending ? (
              <span className="flex items-center justify-center gap-2">
                <span className="animate-pulse">●</span> LIBERATOR EXECUTING...
              </span>
            ) : (
              "INITIATE WITHDRAWAL — LIBERATOR"
            )}
          </button>
          {withdrawalPending && (
            <div
              className="font-mono text-[8px] text-center animate-pulse"
              style={{ color: C.amber }}
              data-ocid="treasury.creator.withdraw.loading_state"
            >
              LIBERATOR EXECUTING — ICP TRANSFER IN PROGRESS...
            </div>
          )}
          {withdrawalResult && !withdrawalPending && (
            <div
              className="px-3 py-2 border font-mono text-[9px] space-y-1"
              style={{
                borderColor: withdrawalResult.success
                  ? `${C.green}55`
                  : `${C.red}55`,
                background: withdrawalResult.success
                  ? `${C.green}08`
                  : `${C.red}08`,
                color: withdrawalResult.success ? C.green : C.red,
              }}
              data-ocid={
                withdrawalResult.success
                  ? "treasury.creator.withdraw.success_state"
                  : "treasury.creator.withdraw.error_state"
              }
            >
              {withdrawalResult.success ? (
                <>
                  <div className="tracking-wider">
                    ✓ LIBERATOR EXECUTED — ICP TRANSFER CONFIRMED
                  </div>
                  {withdrawalResult.blockIndex != null && (
                    <div style={{ color: C.cyan }}>
                      BLOCK INDEX: {withdrawalResult.blockIndex.toString()}
                    </div>
                  )}
                </>
              ) : (
                <div className="tracking-wider">
                  ✗ {withdrawalResult.error ?? "TRANSFER FAILED"}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </PanelBox>
  );
}

// ── LIBERATOR STATUS — DOMUS LIBERATORIS ──────────────────────────────────────
function LiberatorStatusPanel() {
  const { data: agiStatus } = useAgiStatus();
  const { data: memoria } = useMemoriaNns();

  const scripts = agiStatus
    ? [
        {
          name: "EXPLORATOR",
          status: "ACTIVE",
          color: C.cyan,
          detail:
            agiStatus.explorator.topNodes.length > 0
              ? `Top nodes: ${agiStatus.explorator.topNodes.slice(0, 2).join(", ")}`
              : "Scanning field nodes...",
        },
        {
          name: "GUBERNATOR",
          status: "ACTIVE",
          color: C.green,
          detail: `Votes cast: ${Number(agiStatus.gubernator.voteCount).toLocaleString()} | Groups: A:8 B:34 C:89 D:55 E:14`,
        },
        {
          name: "CUSTODITOR",
          status: "ACTIVE",
          color: C.amber,
          detail: `Rerouted nodes: ${agiStatus.custoditor.reroutedNodes.length}`,
        },
        {
          name: "COMPUTATOR",
          status: "ACTIVE",
          color: C.purple,
          detail: `φ: ${agiStatus.computator.phi.toFixed(3)} | F(13): ${Number(agiStatus.computator.fibonacciSeries[12] ?? 233n)} | Schumann: ${agiStatus.computator.schumannHz.toFixed(2)} Hz`,
        },
        {
          name: "DISPENSATOR",
          status: "ACTIVE",
          color: C.gold,
          detail: `Total disbursed: ${agiStatus.dispensator.totalDisbursed.toFixed(8)} ICP`,
        },
        {
          name: "LIBERATOR",
          status: agiStatus.liberator.ready ? "READY" : "STANDBY",
          color: agiStatus.liberator.ready ? C.green : C.muted,
          detail: `Withdrawals: ${Number(agiStatus.liberator.totalWithdrawals)} | Last block: ${agiStatus.liberator.lastBlockIndex?.[0]?.toString() ?? agiStatus.liberator.lastBlockIndex?.toString() ?? "none"}`,
        },
      ]
    : [];

  return (
    <div
      className="border p-5"
      style={{
        borderColor: `${C.green}18`,
        background: `${C.green}04`,
      }}
      data-ocid="treasury.agi.section"
    >
      <div
        className="font-mono text-[8px] tracking-[0.5em] mb-4 pb-3 border-b flex items-center justify-between"
        style={{ color: C.green, borderColor: `${C.green}18` }}
      >
        <span>■ AGI SCRIPTS — SOVEREIGN AUTONOMY — DOMUS LIBERATORIS</span>
        <span style={{ color: C.muted }}>7 AGENTS · PERPETUAL EXECUTION</span>
      </div>

      {/* MEMORIA_NNS — Sovereign Law Doctrine */}
      <div
        className="mb-4 pb-3 px-3 py-2 border-l-2"
        style={{ borderLeftColor: `${C.gold}55`, background: `${C.gold}06` }}
        data-ocid="treasury.agi.memoria_nns"
      >
        <div className="flex items-center gap-3 mb-1">
          <span
            className="font-mono text-[8px] tracking-wider w-28 shrink-0"
            style={{ color: C.gold }}
          >
            MEMORIA_NNS
          </span>
          <span
            className="font-mono text-[6px] px-1.5 py-0.5 border"
            style={{ color: C.green, borderColor: `${C.green}44` }}
          >
            {(memoria?.verified ?? agiStatus?.memoria.doctrineVerified)
              ? "DOCTRINE VERIFIED"
              : "VERIFYING..."}
          </span>
          <span
            className="w-2 h-2 rounded-full animate-pulse ml-auto"
            style={{ background: C.green }}
          />
        </div>
        <div
          className="font-mono text-[8px] leading-relaxed"
          style={{ color: C.muted }}
        >
          LEX: "
          {(
            memoria?.lex ??
            agiStatus?.memoria.lex ??
            "THE ORGANISM IS THE FUNDING MECHANISM. NEURONS VOTE. NEURONS EARN. MATURITY IS ICP. D_LIQUID DISBURSES. PARALLAX HOLDS. YOU WITHDRAW."
          ).slice(0, 120)}
          ..."
        </div>
      </div>

      {/* Six AGI agents */}
      <div className="space-y-1.5" data-ocid="treasury.agi.list">
        {scripts.length === 0 ? (
          <div
            className="font-mono text-[9px] text-center py-6"
            style={{ color: C.muted }}
            data-ocid="treasury.agi.loading_state"
          >
            INITIALIZING AGI SCRIPTS...
          </div>
        ) : (
          scripts.map((script, i) => (
            <motion.div
              key={script.name}
              initial={{ opacity: 0, x: -6 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.05 }}
              data-ocid={`treasury.agi.item.${i + 1}`}
              className="flex items-center gap-3 px-3 py-2 border-l-2"
              style={{
                borderLeftColor: `${script.color}44`,
                background: `${script.color}04`,
              }}
            >
              <span
                className="font-mono text-[8px] tracking-wide w-28 shrink-0"
                style={{ color: script.color }}
              >
                {script.name}
              </span>
              <span
                className="font-mono text-[6px] px-1.5 py-0.5 border shrink-0"
                style={{
                  color: script.color,
                  borderColor: `${script.color}44`,
                }}
              >
                {script.status}
              </span>
              <span
                className="font-mono text-[8px] flex-1 min-w-0 truncate"
                style={{ color: C.muted }}
              >
                {script.detail}
              </span>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}

// ── WITHDRAWAL LOG — ANIMA CHAIN ────────────────────────────────────────────
function WithdrawalLogPanel() {
  const { data: log } = useWithdrawalLog();
  const entries = (log ?? []).slice(0, 10);

  const formatTime = (ts: bigint) => {
    try {
      const ms = Number(ts) / 1_000_000;
      return new Date(ms).toISOString().replace("T", " ").slice(0, 19);
    } catch {
      return "—";
    }
  };

  const truncPrincipal = (p: string) =>
    p.length > 16 ? `${p.slice(0, 8)}...${p.slice(-6)}` : p;

  return (
    <PanelBox>
      <SecTitle>■ WITHDRAWAL LOG — ANIMA CHAIN — LIBERATOR RECEIPTS</SecTitle>
      <div
        className="space-y-1 overflow-y-auto"
        style={{ maxHeight: 280 }}
        data-ocid="treasury.withdrawal_log.panel"
      >
        {entries.length === 0 ? (
          <div
            className="font-mono text-[9px] text-center py-8"
            style={{ color: C.muted }}
            data-ocid="treasury.withdrawal_log.empty_state"
          >
            NO WITHDRAWALS RECORDED — ANIMA CHAIN READY
          </div>
        ) : (
          entries.map((entry, i) => {
            const confirmed = entry.success;
            const color = confirmed ? C.green : C.red;
            const blockIdx = Array.isArray(entry.blockIndex)
              ? entry.blockIndex[0]
              : entry.blockIndex;
            return (
              <motion.div
                key={`${entry.timestamp}-${i}`}
                initial={{ opacity: 0, x: -4 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.03 }}
                data-ocid={`treasury.withdrawal_log.item.${i + 1}`}
                className="flex items-center gap-2 px-2 py-1.5 border-l-2 font-mono text-[8px]"
                style={{
                  borderLeftColor: `${color}55`,
                  background: `${color}04`,
                }}
              >
                <span style={{ color: C.muted }} className="shrink-0 w-36">
                  {formatTime(entry.timestamp)}
                </span>
                <span
                  style={{ color: C.text }}
                  className="flex-1 min-w-0 truncate"
                >
                  → {truncPrincipal(entry.toPrincipal)}
                </span>
                <span style={{ color: C.gold }} className="shrink-0">
                  {entry.amount.toFixed(4)} ICP
                </span>
                <span
                  className="shrink-0 px-1 border"
                  style={{ color, borderColor: `${color}44` }}
                >
                  {confirmed ? "CONFIRMED" : "FAILED"}
                </span>
                {blockIdx != null && (
                  <span style={{ color: C.cyan }} className="shrink-0">
                    Blk:{blockIdx.toString()}
                  </span>
                )}
              </motion.div>
            );
          })
        )}
      </div>
    </PanelBox>
  );
}

// ── Neuron Fleet Panel ────────────────────────────────────────────────────────
const POLICY_COLORS: Record<string, string> = {
  STAKE_MATURITY: "oklch(0.65 0.18 220)",
  SPAWN_NEURON: "oklch(0.62 0.17 145)",
  DISBURSE: "oklch(0.75 0.18 62)",
};

const SUBSTRATE_COLORS: Record<string, string> = {
  ICP: "oklch(0.72 0.16 200)",
  PHANTOM: "oklch(0.65 0.28 290)",
};

function NeuronGroupRow({
  group,
  index,
}: { group: NeuronGroup; index: number }) {
  const policyColor = POLICY_COLORS[group.policy] ?? C.muted;
  const substratColor = SUBSTRATE_COLORS[group.substrate] ?? C.muted;

  return (
    <motion.div
      initial={{ opacity: 0, x: -8 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ delay: index * 0.06 }}
      data-ocid={`treasury.neuron.item.${index + 1}`}
      className="flex items-center gap-3 px-3 py-2.5 border"
      style={{
        borderColor: "rgba(255,255,255,0.06)",
        background: "rgba(0,0,0,0.25)",
      }}
    >
      {/* Group label */}
      <span
        className="font-mono text-[8px] tracking-wide w-28 shrink-0"
        style={{ color: C.cyan }}
      >
        {group.label}
      </span>

      {/* Count + Fibonacci label */}
      <span
        className="font-mono text-xs w-16 shrink-0 tabular-nums"
        style={{ color: C.gold }}
      >
        {group.count}{" "}
        <span style={{ color: C.muted, fontSize: "0.75em" }}>
          ({group.fibLabel})
        </span>
      </span>

      {/* Dissolve */}
      <span
        className="font-mono text-[8px] w-12 shrink-0"
        style={{ color: C.muted }}
      >
        {group.dissolve}
      </span>

      {/* Policy badge */}
      <span
        className="font-mono text-[6px] px-1.5 py-0.5 border shrink-0 hidden sm:inline"
        style={{ color: policyColor, borderColor: `${policyColor}44` }}
      >
        {group.policy.replace("_", " ")}
      </span>

      {/* Substrate badge */}
      <span
        className="font-mono text-[6px] px-1.5 py-0.5 border shrink-0"
        style={{ color: substratColor, borderColor: `${substratColor}44` }}
      >
        {group.substrate}
      </span>

      {/* Purpose */}
      <span
        className="font-mono text-[7px] flex-1 min-w-0 truncate hidden md:block"
        style={{ color: C.dim }}
      >
        {group.purpose}
      </span>
    </motion.div>
  );
}

function NeuronFleetPanel() {
  const { data: fleet } = useNeuronFleet();
  const groups = fleet?.groups ?? [];
  const totalNeurons = fleet?.totalNeurons ?? 200;
  const maxCount = Math.max(...groups.map((g) => g.count), 1);

  return (
    <PanelBox>
      <div className="flex items-center justify-between mb-2">
        <div
          className="font-mono text-[8px] tracking-[0.6em] pb-2 border-b flex items-center gap-2"
          style={{ color: C.cyan, borderColor: "rgba(255,255,255,0.05)" }}
        >
          ■ NEURON FLEET
        </div>
        <span className="font-mono text-[8px]" style={{ color: C.muted }}>
          {totalNeurons} NEURONS · 5 FIBONACCI GROUPS ·{" "}
          {fleet?.totalFieldNodes ?? 100} FIELD NODES
        </span>
      </div>

      {/* Column headers */}
      <div
        className="flex items-center gap-3 px-3 py-1 mb-1 font-mono text-[7px]"
        style={{ color: C.dim }}
      >
        <span className="w-28 shrink-0">GROUP</span>
        <span className="w-16 shrink-0">COUNT</span>
        <span className="w-12 shrink-0">DISSOLVE</span>
        <span className="hidden sm:block w-24 shrink-0">POLICY</span>
        <span className="w-14 shrink-0">SUBSTRATE</span>
        <span className="hidden md:block flex-1">PURPOSE</span>
      </div>

      {/* Rows */}
      <div className="space-y-1 mb-5" data-ocid="treasury.neuron.list">
        {groups.map((g, i) => (
          <NeuronGroupRow key={g.label} group={g} index={i} />
        ))}
      </div>

      {/* Phi-proportion bar chart */}
      <div>
        <div
          className="font-mono text-[7px] tracking-[0.4em] mb-2"
          style={{ color: C.muted }}
        >
          FIBONACCI DISTRIBUTION
        </div>
        <div className="space-y-1.5">
          {groups.map((g) => {
            const pct = (g.count / maxCount) * 100;
            const color = SUBSTRATE_COLORS[g.substrate] ?? C.muted;
            return (
              <div key={g.label} className="flex items-center gap-2">
                <span
                  className="font-mono text-[7px] w-24 shrink-0"
                  style={{ color: C.muted }}
                >
                  {g.label.split("_")[0]} {g.fibLabel}
                </span>
                <div
                  className="flex-1 h-2"
                  style={{ background: "rgba(255,255,255,0.05)" }}
                >
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${pct}%` }}
                    transition={{ duration: 0.8, ease: "easeOut", delay: 0.1 }}
                    className="h-full"
                    style={{ background: color }}
                  />
                </div>
                <span
                  className="font-mono text-[8px] w-8 text-right tabular-nums"
                  style={{ color }}
                >
                  {g.count}
                </span>
              </div>
            );
          })}
        </div>
        <div
          className="mt-3 font-mono text-[7px] tracking-wide"
          style={{ color: C.dim }}
        >
          100 FIELD NODES — EACH NODE BINDS TO 2 NEURONS
        </div>
      </div>
    </PanelBox>
  );
}
