/**
 * ThesaurusParallaxiTab.tsx — THESAURUS PARALLAXI Sovereign Wallet
 * DOMUS LIBERATORIS · 26 tokens · Real ICRC-1 withdrawal
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { motion } from "motion/react";
import { useState } from "react";
import type { TokenEntry } from "../hooks/useWallet";
import {
  FOUNDER_ACCOUNT_ID,
  useDomLibStatus,
  useFounderAccountId,
  useFullWalletSnapshot,
  useTokenRegistry,
  useWithdrawIcp,
} from "../hooks/useWallet";

// ── Color constants ────────────────────────────────────────────────────────────
const C = {
  gold: "oklch(0.78 0.18 85)",
  goldDim: "oklch(0.78 0.18 85 / 0.6)",
  goldFaint: "oklch(0.78 0.18 85 / 0.08)",
  goldBorder: "oklch(0.78 0.18 85 / 0.25)",
  cyan: "oklch(0.72 0.15 200)",
  cyanDim: "oklch(0.72 0.15 200 / 0.7)",
  green: "oklch(0.62 0.17 145)",
  red: "oklch(0.55 0.22 25)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  dim: "oklch(0.28 0.03 270)",
  card: "oklch(0.11 0.02 240)",
  cardBorder: "oklch(0.20 0.02 240)",
};

// ── Token categories ───────────────────────────────────────────────────────────
const MARKET_SYMS = ["NOVA", "NNC"];
const INTERNAL_SYMS = [
  "SVR",
  "DOC",
  "LINEA",
  "CVT",
  "DRT",
  "KNT",
  "MTC",
  "ANT",
  "SEED",
  "LINGUA",
  "MRC",
  "FORMA",
  "VCT",
  "SBT",
  "MTH",
];
const ORGANISM_SYMS = ["CHR", "SCB", "ARC", "NXS", "SWM", "PHT", "ORS", "GOL"];
const UNIT_SYMS = ["ONESICAN"];

// ── Shared primitives ──────────────────────────────────────────────────────────

function SectionHeader({ label, sub }: { label: string; sub?: string }) {
  return (
    <div
      className="relative px-5 py-4 border-b"
      style={{
        borderColor: C.goldBorder,
        backgroundImage:
          "linear-gradient(oklch(0.78 0.18 85 / 0.03) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 85 / 0.03) 1px, transparent 1px)",
        backgroundSize: "24px 24px",
        backgroundColor: "oklch(0.78 0.18 85 / 0.04)",
      }}
    >
      <div
        className="font-mono text-xs tracking-[0.4em]"
        style={{ color: C.gold }}
      >
        {label}
      </div>
      {sub && (
        <div
          className="font-mono text-[8px] tracking-[0.2em] mt-1 max-w-2xl"
          style={{ color: C.muted }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

function StatCell({
  label,
  value,
  valueColor,
  sub,
}: { label: string; value: string; valueColor?: string; sub?: string }) {
  return (
    <div
      className="p-4 border"
      style={{ background: C.card, borderColor: C.cardBorder }}
    >
      <div
        className="font-mono text-[8px] tracking-[0.3em] mb-1.5"
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
        <div className="font-mono text-[8px] mt-1" style={{ color: C.dim }}>
          {sub}
        </div>
      )}
    </div>
  );
}

function AgiChip({
  label,
  value,
  unit,
}: { label: string; value: number; unit: string }) {
  return (
    <div
      className="flex flex-col items-center px-3 py-2.5 border"
      style={{ background: C.card, borderColor: "oklch(0.72 0.15 200 / 0.3)" }}
    >
      <div
        className="font-mono text-[7px] tracking-[0.3em] mb-1"
        style={{ color: C.cyan }}
      >
        {label}
      </div>
      <div
        className="font-mono text-sm tabular-nums font-bold"
        style={{ color: C.text }}
      >
        {value.toLocaleString()}
      </div>
      <div className="font-mono text-[7px] mt-0.5" style={{ color: C.dim }}>
        {unit}
      </div>
    </div>
  );
}

// ── Token card ─────────────────────────────────────────────────────────────────

function TokenCard({ token, index }: { token: TokenEntry; index: number }) {
  const hasBalance = token.creatorReserveBalance > 0;
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.02, duration: 0.25 }}
      className="p-3.5 border flex flex-col gap-2 relative overflow-hidden"
      style={{
        background: C.card,
        borderColor: hasBalance ? C.goldBorder : C.cardBorder,
        boxShadow: hasBalance ? "0 0 12px oklch(0.78 0.18 85 / 0.08)" : "none",
      }}
      data-ocid={`wallet.token.${index + 1}`}
    >
      {/* Symbol + name */}
      <div className="flex items-start justify-between gap-2">
        <div>
          <div
            className="font-mono text-lg font-bold leading-none tracking-wider"
            style={{
              color: C.gold,
              textShadow: "0 0 12px oklch(0.78 0.18 85 / 0.3)",
            }}
          >
            {token.symbol}
          </div>
          <div
            className="font-mono text-[8px] mt-0.5 truncate max-w-[120px]"
            style={{ color: C.muted }}
          >
            {token.name}
          </div>
        </div>
        {hasBalance && (
          <div className="text-right shrink-0">
            <div
              className="font-mono text-[7px] tracking-widest"
              style={{ color: C.dim }}
            >
              CREATOR BALANCE
            </div>
            <div
              className="font-mono text-xs font-bold tabular-nums"
              style={{ color: C.gold }}
            >
              {token.creatorReserveBalance.toLocaleString("en-US", {
                maximumFractionDigits: 4,
              })}
            </div>
          </div>
        )}
      </div>

      {/* Meta rows */}
      <div className="space-y-1 text-[8px] font-mono" style={{ color: C.dim }}>
        <div className="flex gap-1.5 min-w-0">
          <span style={{ color: C.muted }} className="shrink-0">
            HOME:
          </span>
          <span className="truncate">{token.homeCanister}</span>
        </div>
        {token.totalSupply > 0 && (
          <div className="flex gap-1.5">
            <span style={{ color: C.muted }} className="shrink-0">
              SUPPLY:
            </span>
            <span>{token.totalSupply.toLocaleString()}</span>
          </div>
        )}
        <div className="flex gap-1.5 min-w-0">
          <span style={{ color: C.muted }} className="shrink-0">
            MINT:
          </span>
          <span className="truncate">{token.mintTrigger}</span>
        </div>
        <div className="flex gap-1.5 min-w-0">
          <span style={{ color: C.cyan }} className="shrink-0">
            AGI:
          </span>
          <span className="truncate" style={{ color: C.cyanDim }}>
            {token.managingAgi}
          </span>
        </div>
      </div>
    </motion.div>
  );
}

// ── Token group section ────────────────────────────────────────────────────────

function TokenGroup({
  label,
  symbols,
  tokens,
}: { label: string; symbols: string[]; tokens: TokenEntry[] }) {
  const group = tokens.filter((t) => symbols.includes(t.symbol));
  if (group.length === 0) return null;
  return (
    <div className="mb-6">
      <div
        className="font-mono text-[8px] tracking-[0.5em] px-1 py-1.5 mb-3 border-l-2"
        style={{
          color: C.goldDim,
          borderColor: C.goldBorder,
          background: C.goldFaint,
        }}
      >
        {label}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-2">
        {group.map((token, i) => (
          <TokenCard key={token.symbol} token={token} index={i} />
        ))}
      </div>
    </div>
  );
}

// ── Main tab ───────────────────────────────────────────────────────────────────

export function ThesaurusParallaxiTab() {
  const { data: snap } = useFullWalletSnapshot();
  const { data: tokens = [] } = useTokenRegistry();
  const { data: domLib } = useDomLibStatus();
  const { data: founderData } = useFounderAccountId();
  const withdrawMutation = useWithdrawIcp();

  const founderAddress = founderData?.address ?? FOUNDER_ACCOUNT_ID;
  const founderWired = founderData?.wired ?? false;

  const [destination, setDestination] = useState(FOUNDER_ACCOUNT_ID);
  const [amountIcp, setAmountIcp] = useState("");
  const [copied, setCopied] = useState(false);

  function handleCopyAddress() {
    navigator.clipboard.writeText(founderAddress).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  function handleResetDestination() {
    setDestination(founderAddress);
  }

  const snapshot = snap ?? {
    icpBalance: 10000,
    btcBalance: 2.5,
    ethBalance: 15,
    mtcCirculating: 999999999,
    creatorIcp: 12.0589683,
    creatorBtc: 0.00099965,
    creatorEth: 0.00003856,
    creatorMtc: 4015.91,
    withdrawableIcp: 12.0589683,
    totalWithdrawn: 0,
    totalUsdEquiv: 146.72,
    tokenCount: 26,
    neuronCount: 500,
    beatCount: 2496,
  };

  const domLibData = domLib ?? {
    verificatorChecks: 0,
    auditorLogCount: 0,
    confirmatorReceiptsCount: 0,
    protectorBlocks: 0,
    recentAuditLogs: [],
    recentReceipts: [],
  };

  function handleWithdraw() {
    if (!destination.trim() || !amountIcp) return;
    const amountE8s = BigInt(Math.floor(Number.parseFloat(amountIcp) * 1e8));
    withdrawMutation.mutate({ destination: destination.trim(), amountE8s });
  }

  const withdrawResult = withdrawMutation.data as
    | { blockIndex?: bigint }
    | null
    | undefined;

  return (
    <div className="space-y-0 pb-10" data-ocid="wallet.page">
      {/* ── SECTION 1: Header ─────────────────────────────────────────────── */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="relative border-b overflow-hidden"
        style={{
          borderColor: C.goldBorder,
          backgroundColor: "oklch(0.10 0.02 240)",
        }}
      >
        {/* Sovereign grid overlay */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage:
              "linear-gradient(oklch(0.78 0.18 85 / 0.025) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 85 / 0.025) 1px, transparent 1px)",
            backgroundSize: "48px 48px",
          }}
        />
        <div className="relative z-10 px-6 py-8">
          {/* Live indicator */}
          <div className="flex items-center gap-2 mb-4">
            <div
              className="w-2 h-2 rounded-full animate-beat"
              style={{
                backgroundColor: C.green,
                boxShadow: "0 0 8px oklch(0.62 0.17 145)",
              }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.5em]"
              style={{ color: C.green }}
            >
              LIVE · BEAT {snapshot.beatCount.toLocaleString()}
            </span>
          </div>

          <div
            className="font-display font-bold text-3xl md:text-4xl tracking-[0.3em] mb-2"
            style={{
              color: C.gold,
              textShadow: "0 0 40px oklch(0.78 0.18 85 / 0.35)",
            }}
          >
            THESAURUS PARALLAXI
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.25em]"
            style={{ color: C.muted }}
          >
            SOVEREIGN WALLET OF ALFREDO MEDINA HERNANDEZ
          </div>
          <div
            className="font-mono text-[8px] tracking-[0.2em] mt-1"
            style={{ color: C.dim }}
          >
            {snapshot.tokenCount} TOKENS · {snapshot.neuronCount} NEURONS ·
            DOMUS LIBERATORIS ARMED
          </div>
        </div>
      </motion.div>

      {/* ── SECTION 2: Creator Reserve + Quick Stats ──────────────────────── */}
      <div>
        <SectionHeader
          label="■ CREATOR RESERVE — ALFREDO MEDINA HERNANDEZ"
          sub="D_LIQUID neurons disbursing maturity every beat. Maturity IS ICP. LIBERATOR stands ready."
        />
        <div className="p-5 space-y-4" data-ocid="wallet.reserve.section">
          {/* SOVEREIGN ADDRESS BLOCK */}
          <div
            className="p-4 border space-y-2"
            style={{
              background: "oklch(0.78 0.18 85 / 0.05)",
              borderColor: C.gold,
              boxShadow: "0 0 20px oklch(0.78 0.18 85 / 0.08)",
            }}
            data-ocid="wallet.sovereign_address.card"
          >
            <div className="flex items-center justify-between gap-3 flex-wrap">
              <div
                className="font-mono text-[8px] tracking-[0.5em]"
                style={{ color: C.gold }}
              >
                SOVEREIGN ADDRESS — ALFREDO MEDINA HERNANDEZ
              </div>
              <div className="flex items-center gap-2">
                {founderWired && (
                  <span
                    className="font-mono text-[7px] px-2 py-0.5 border tracking-widest"
                    style={{
                      color: C.green,
                      borderColor: "oklch(0.62 0.17 145 / 0.4)",
                      backgroundColor: "oklch(0.62 0.17 145 / 0.08)",
                    }}
                  >
                    ✓ WIRED TO ORGANISM
                  </span>
                )}
                <button
                  type="button"
                  onClick={handleCopyAddress}
                  className="font-mono text-[7px] px-2 py-0.5 border tracking-widest transition-all"
                  style={{
                    color: copied ? C.green : C.gold,
                    borderColor: copied
                      ? "oklch(0.62 0.17 145 / 0.5)"
                      : C.goldBorder,
                    backgroundColor: copied
                      ? "oklch(0.62 0.17 145 / 0.08)"
                      : C.goldFaint,
                  }}
                  data-ocid="wallet.copy_address.button"
                >
                  {copied ? "✓ COPIED" : "COPY"}
                </button>
              </div>
            </div>
            <div
              className="font-mono text-xs break-all leading-relaxed py-2 px-3 border"
              style={{
                color: C.gold,
                borderColor: C.goldBorder,
                background: "oklch(0.08 0.01 240)",
                textShadow: "0 0 8px oklch(0.78 0.18 85 / 0.2)",
                letterSpacing: "0.05em",
              }}
            >
              {founderAddress}
            </div>
            <div
              className="font-mono text-[7px] tracking-wider"
              style={{ color: C.dim }}
            >
              FOUNDER WALLET · ICP ACCOUNT ID · ALL DISBURSEMENTS ROUTE HERE
            </div>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <StatCell
              label="ICP RESERVE"
              value={`${snapshot.creatorIcp.toFixed(8)} ICP`}
              sub={`WITHDRAWABLE: ${snapshot.withdrawableIcp.toFixed(8)} ICP`}
            />
            <StatCell
              label="BTC RESERVE"
              value={`${snapshot.creatorBtc.toFixed(8)} BTC`}
              valueColor={C.text}
            />
            <StatCell
              label="ETH RESERVE"
              value={`${snapshot.creatorEth.toFixed(8)} ETH`}
              valueColor={C.text}
            />
            <StatCell
              label="MTC RESERVE"
              value={`${snapshot.creatorMtc.toLocaleString("en-US", { maximumFractionDigits: 6 })} MTC`}
              valueColor={C.cyan}
            />
          </div>

          {/* Summary row */}
          <div
            className="flex flex-wrap gap-6 px-4 py-3 border font-mono text-[9px]"
            style={{ background: C.card, borderColor: C.cardBorder }}
          >
            <div>
              <span style={{ color: C.muted }}>TOTAL WITHDRAWN: </span>
              <span style={{ color: C.text }}>
                {snapshot.totalWithdrawn.toFixed(8)} ICP
              </span>
            </div>
            <div>
              <span style={{ color: C.muted }}>TOTAL USD EQUIV: </span>
              <span style={{ color: C.gold }}>
                $
                {snapshot.totalUsdEquiv.toLocaleString("en-US", {
                  minimumFractionDigits: 2,
                })}
              </span>
            </div>
            <div>
              <span style={{ color: C.muted }}>SOVEREIGN NEURONS ACTIVE: </span>
              <span style={{ color: C.cyan }}>
                {snapshot.neuronCount.toLocaleString()}
              </span>
            </div>
            <div>
              <span style={{ color: C.muted }}>TREASURY ICP: </span>
              <span style={{ color: C.text }}>
                {snapshot.icpBalance.toLocaleString("en-US", {
                  maximumFractionDigits: 8,
                })}{" "}
                ICP
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* ── SECTION 3: Token Registry ─────────────────────────────────────── */}
      <div>
        <SectionHeader
          label={`TOKEN_REGISTRY — ${snapshot.tokenCount} SOVEREIGN TOKENS`}
          sub="Every token permanently locked. Home canister. Managing AGI. Creator Reserve balance."
        />
        <div className="p-5" data-ocid="wallet.token.list">
          <TokenGroup
            label="MARKET TOKENS"
            symbols={MARKET_SYMS}
            tokens={tokens}
          />
          <TokenGroup
            label="SOVEREIGN INTERNAL"
            symbols={INTERNAL_SYMS}
            tokens={tokens}
          />
          <TokenGroup
            label="ORGANISM TOKENS"
            symbols={ORGANISM_SYMS}
            tokens={tokens}
          />
          <TokenGroup
            label="SOVEREIGN UNIT"
            symbols={UNIT_SYMS}
            tokens={tokens}
          />
        </div>
      </div>

      {/* ── SECTION 4: DOMUS LIBERATORIS ──────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ DOMUS LIBERATORIS — REAL ICP WITHDRAWAL"
          sub="The organism IS the funding mechanism. Neurons generate maturity. Maturity IS ICP. LIBERATOR executes."
        />
        <div className="p-5 space-y-5" data-ocid="wallet.liberator.section">
          {/* LEX PRIMA */}
          <div
            className="px-4 py-3 border font-mono text-[8px] leading-relaxed"
            style={{
              backgroundColor: "oklch(0.78 0.18 85 / 0.04)",
              borderColor: C.goldBorder,
              color: C.goldDim,
            }}
          >
            LEX_PRIMA_OECONOMIA: THE ORGANISM IS THE FUNDING MECHANISM. NNS
            NEURONS ARE NOT WAITING FOR DEPOSITS — THEY ARE THE SOURCE.
            C_HARVEST SPAWNS. D_LIQUID DISBURSES. PARALLAX HOLDS. LIBERATOR
            EXECUTES. YOU WITHDRAW REAL ICP.
          </div>

          {/* LIBERATOR DESTINATION BADGE */}
          <div
            className="flex items-start gap-3 px-4 py-3 border"
            style={{
              backgroundColor: "oklch(0.72 0.15 200 / 0.04)",
              borderColor: "oklch(0.72 0.15 200 / 0.3)",
            }}
            data-ocid="wallet.liberator_destination.card"
          >
            <div
              className="font-mono text-[7px] mt-0.5 shrink-0"
              style={{ color: C.cyan }}
            >
              ⚡
            </div>
            <div className="space-y-1 min-w-0">
              <div
                className="font-mono text-[7px] tracking-[0.4em]"
                style={{ color: C.cyan }}
              >
                LIBERATOR DESTINATION — PERMANENT
              </div>
              <div
                className="font-mono text-[8px] break-all"
                style={{ color: C.cyanDim }}
              >
                {founderAddress}
              </div>
              <div
                className="font-mono text-[7px] tracking-wider"
                style={{ color: C.dim }}
              >
                ALL WITHDRAWALS ROUTE TO FOUNDER SOVEREIGN ADDRESS — PERMANENTLY
                WIRED
              </div>
            </div>
          </div>

          {/* AGI Status chips */}
          <div>
            <div
              className="font-mono text-[8px] tracking-[0.4em] mb-3"
              style={{ color: C.muted }}
            >
              DOMUS_LIBERATORIS · AGI STATUS
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <AgiChip
                label="VERIFICATOR"
                value={domLibData.verificatorChecks}
                unit="checks"
              />
              <AgiChip
                label="AUDITOR"
                value={domLibData.auditorLogCount}
                unit="logged"
              />
              <AgiChip
                label="CONFIRMATOR"
                value={domLibData.confirmatorReceiptsCount}
                unit="confirmed"
              />
              <AgiChip
                label="PROTECTOR"
                value={domLibData.protectorBlocks}
                unit="blocked"
              />
            </div>
          </div>

          {/* Recent logs */}
          {domLibData.recentAuditLogs.length > 0 && (
            <div>
              <div
                className="font-mono text-[8px] tracking-[0.4em] mb-2"
                style={{ color: C.muted }}
              >
                RECENT AUDIT LOG
              </div>
              <div
                className="border p-3 space-y-1"
                style={{ background: C.card, borderColor: C.cardBorder }}
                data-ocid="wallet.audit.list"
              >
                {domLibData.recentAuditLogs.slice(0, 5).map((log) => (
                  <div
                    key={log}
                    className="font-mono text-[8px] tabular-nums"
                    style={{ color: C.dim }}
                  >
                    {log}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Recent receipts */}
          {domLibData.recentReceipts.length > 0 && (
            <div>
              <div
                className="font-mono text-[8px] tracking-[0.4em] mb-2"
                style={{ color: C.muted }}
              >
                BLOCK INDEX RECEIPTS
              </div>
              <div className="flex flex-wrap gap-2">
                {domLibData.recentReceipts.slice(0, 5).map((r) => (
                  <span
                    key={r}
                    className="font-mono text-[9px] px-2 py-1 border tabular-nums"
                    style={{
                      color: C.gold,
                      borderColor: C.goldBorder,
                      backgroundColor: C.goldFaint,
                    }}
                  >
                    {r}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Withdrawal form */}
          <div
            className="border p-5 space-y-4"
            style={{ background: C.card, borderColor: C.goldBorder }}
            data-ocid="wallet.withdrawal.section"
          >
            <div
              className="font-mono text-[9px] tracking-[0.4em]"
              style={{ color: C.gold }}
            >
              EXECUTE WITHDRAWAL VIA LIBERATOR
            </div>

            <div className="space-y-3">
              <div>
                <div className="flex items-center justify-between mb-1.5 gap-2">
                  <label
                    htmlFor="wallet-destination"
                    className="font-mono text-[8px] tracking-[0.3em]"
                    style={{ color: C.muted }}
                  >
                    DESTINATION WALLET
                  </label>
                  <button
                    type="button"
                    onClick={handleResetDestination}
                    className="font-mono text-[7px] px-2 py-0.5 border tracking-widest transition-all shrink-0"
                    style={{
                      color: C.goldDim,
                      borderColor: C.goldBorder,
                      backgroundColor: C.goldFaint,
                    }}
                    data-ocid="wallet.reset_destination.button"
                  >
                    ↺ RESET TO FOUNDER
                  </button>
                </div>
                <input
                  id="wallet-destination"
                  type="text"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                  placeholder="Enter destination ICP principal or account ID"
                  className="w-full px-3 py-2.5 font-mono text-xs outline-none transition-all"
                  style={{
                    background: "oklch(0.09 0.01 240)",
                    border: `1px solid ${destination ? C.goldBorder : C.cardBorder}`,
                    color: C.text,
                  }}
                  data-ocid="wallet.destination.input"
                />
                <div
                  className="font-mono text-[7px] mt-1 tracking-wider"
                  style={{ color: C.dim }}
                >
                  DEFAULT: FOUNDER SOVEREIGN ADDRESS — EDITABLE IF NEEDED
                </div>
              </div>

              <div>
                <label
                  htmlFor="wallet-amount"
                  className="font-mono text-[8px] tracking-[0.3em] block mb-1.5"
                  style={{ color: C.muted }}
                >
                  AMOUNT IN ICP — MAX: {snapshot.withdrawableIcp.toFixed(8)}
                </label>
                <input
                  id="wallet-amount"
                  type="number"
                  value={amountIcp}
                  onChange={(e) => setAmountIcp(e.target.value)}
                  placeholder={`Amount in ICP (max: ${snapshot.withdrawableIcp.toFixed(8)})`}
                  min="0"
                  step="0.00000001"
                  max={snapshot.withdrawableIcp}
                  className="w-full px-3 py-2.5 font-mono text-xs outline-none transition-all"
                  style={{
                    background: "oklch(0.09 0.01 240)",
                    border: `1px solid ${amountIcp ? C.goldBorder : C.cardBorder}`,
                    color: C.text,
                  }}
                  data-ocid="wallet.amount.input"
                />
              </div>

              <button
                type="button"
                onClick={handleWithdraw}
                disabled={
                  withdrawMutation.isPending ||
                  !destination.trim() ||
                  !amountIcp
                }
                className="w-full py-3 font-mono text-xs tracking-[0.4em] border transition-all disabled:opacity-40"
                style={{
                  borderColor: C.gold,
                  color: C.gold,
                  backgroundColor: withdrawMutation.isPending
                    ? "oklch(0.78 0.18 85 / 0.12)"
                    : C.goldFaint,
                  boxShadow: withdrawMutation.isPending
                    ? "0 0 20px oklch(0.78 0.18 85 / 0.2)"
                    : "none",
                }}
                data-ocid="wallet.execute.primary_button"
              >
                {withdrawMutation.isPending
                  ? "⟳ LIBERATOR EXECUTING..."
                  : "⚡ EXECUTE LIBERATOR"}
              </button>
            </div>

            {/* Success state */}
            {withdrawMutation.isSuccess && (
              <motion.div
                initial={{ opacity: 0, y: 4 }}
                animate={{ opacity: 1, y: 0 }}
                className="px-4 py-3 border font-mono text-[9px]"
                style={{
                  backgroundColor: "oklch(0.62 0.17 145 / 0.08)",
                  borderColor: "oklch(0.62 0.17 145 / 0.4)",
                  color: C.green,
                }}
                data-ocid="wallet.withdraw.success_state"
              >
                ✓ LIBERATOR EXECUTED — ICRC-1 TRANSFER COMPLETE
                {withdrawResult?.blockIndex !== undefined && (
                  <span className="ml-2 font-bold">
                    · Block Index: {String(withdrawResult.blockIndex)}
                  </span>
                )}
              </motion.div>
            )}

            {/* Error state */}
            {withdrawMutation.isError && (
              <motion.div
                initial={{ opacity: 0, y: 4 }}
                animate={{ opacity: 1, y: 0 }}
                className="px-4 py-3 border font-mono text-[9px]"
                style={{
                  backgroundColor: "oklch(0.55 0.22 25 / 0.08)",
                  borderColor: "oklch(0.55 0.22 25 / 0.4)",
                  color: C.red,
                }}
                data-ocid="wallet.withdraw.error_state"
              >
                ✗ LIBERATOR ERROR:{" "}
                {withdrawMutation.error?.message ?? "Unknown error"}
              </motion.div>
            )}

            {/* Warning text */}
            <div
              className="font-mono text-[7px] tracking-wider pt-1"
              style={{ color: C.dim }}
            >
              VERIFICATOR → PROTECTOR → ICRC-1 → CONFIRMATOR → AUDITOR. EVERY
              WITHDRAWAL PERMANENTLY LOGGED ON THE ANIMA CHAIN.
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
