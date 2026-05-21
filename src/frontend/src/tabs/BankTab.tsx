/**
 * BankTab.tsx — T2 DIGITAL ASSET BANK
 * US-Compliant · Sovereign Non-Custodial · PARALLAX-Native
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { motion } from "motion/react";
import { useState } from "react";
import type { BankAccountEntry, BankRole } from "../hooks/useBank";
import {
  useBankAccounts,
  useBankingSsuState,
  useBankingYield,
  useCreateBankAccount,
  useExportFinCEN,
  useInitiateKyc,
  useSetKycEndpoint,
  useToggleDelegated,
  useTxMonitoring,
} from "../hooks/useBank";

// ── Color palette (matches existing dark PARALLAX aesthetic) ──────────────────
const C = {
  gold: "oklch(0.78 0.18 85)",
  goldDim: "oklch(0.78 0.18 85 / 0.6)",
  goldFaint: "oklch(0.78 0.18 85 / 0.08)",
  goldBorder: "oklch(0.78 0.18 85 / 0.25)",
  cyan: "oklch(0.72 0.15 200)",
  cyanDim: "oklch(0.72 0.15 200 / 0.6)",
  cyanFaint: "oklch(0.72 0.15 200 / 0.08)",
  cyanBorder: "oklch(0.72 0.15 200 / 0.3)",
  green: "oklch(0.62 0.17 145)",
  greenFaint: "oklch(0.62 0.17 145 / 0.08)",
  greenBorder: "oklch(0.62 0.17 145 / 0.35)",
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
  bg: "oklch(0.08 0.01 240)",
};

// ── Shared primitives ─────────────────────────────────────────────────────────

function SectionHeader({ label, sub }: { label: string; sub?: string }) {
  return (
    <div
      className="px-5 py-4 border-b"
      style={{
        borderColor: C.goldBorder,
        background: "oklch(0.78 0.18 85 / 0.04)",
        backgroundImage:
          "linear-gradient(oklch(0.78 0.18 85 / 0.025) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 85 / 0.025) 1px, transparent 1px)",
        backgroundSize: "24px 24px",
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
          className="font-mono text-[8px] tracking-[0.2em] mt-1"
          style={{ color: C.muted }}
        >
          {sub}
        </div>
      )}
    </div>
  );
}

function StatCard({
  label,
  value,
  sub,
  valueColor,
}: { label: string; value: string; sub?: string; valueColor?: string }) {
  return (
    <div
      className="p-4 border"
      style={{ background: C.card, borderColor: C.cardBorder }}
    >
      <div
        className="font-mono text-[7px] tracking-[0.35em] mb-1.5"
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
    </div>
  );
}

function RoleBadge({ role }: { role: string }) {
  const styles: Record<string, { color: string; border: string; bg: string }> =
    {
      institutional: {
        color: C.green,
        border: C.greenBorder,
        bg: C.greenFaint,
      },
      business: { color: C.cyan, border: C.cyanBorder, bg: C.cyanFaint },
      personal: { color: C.muted, border: C.cardBorder, bg: "transparent" },
    };
  const s = styles[role] ?? styles.personal;
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest uppercase"
      style={{ color: s.color, borderColor: s.border, backgroundColor: s.bg }}
    >
      {role}
    </span>
  );
}

function KycBadge({ status }: { status: string }) {
  const styles: Record<string, { color: string; border: string; bg: string }> =
    {
      verified: { color: C.green, border: C.greenBorder, bg: C.greenFaint },
      pending: { color: C.amber, border: C.amberBorder, bg: C.amberFaint },
      rejected: { color: C.red, border: C.redBorder, bg: C.redFaint },
      notStarted: { color: C.muted, border: C.cardBorder, bg: "transparent" },
    };
  const s = styles[status] ?? styles.notStarted;
  return (
    <span
      className="font-mono text-[7px] px-1.5 py-0.5 border tracking-widest uppercase"
      style={{ color: s.color, borderColor: s.border, backgroundColor: s.bg }}
    >
      {status === "notStarted" ? "NOT STARTED" : status}
    </span>
  );
}

// ── Create Account Form ───────────────────────────────────────────────────────

function CreateAccountForm({ onClose }: { onClose: () => void }) {
  const [accountId, setAccountId] = useState("");
  const [name, setName] = useState("");
  const [role, setRole] = useState<BankRole>("personal");
  const createMutation = useCreateBankAccount();

  function handleSubmit() {
    if (!accountId.trim() || !name.trim()) return;
    createMutation.mutate(
      { accountId: accountId.trim(), name: name.trim(), role },
      {
        onSuccess: () => {
          onClose();
        },
      },
    );
  }

  const inputStyle = {
    background: "oklch(0.09 0.01 240)",
    border: `1px solid ${C.cardBorder}`,
    color: C.text,
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      className="border p-5 space-y-4"
      style={{ background: C.card, borderColor: C.cyanBorder }}
      data-ocid="bank.create_account.dialog"
    >
      <div className="flex items-center justify-between">
        <div
          className="font-mono text-[9px] tracking-[0.4em]"
          style={{ color: C.cyan }}
        >
          CREATE NEW ACCOUNT
        </div>
        <button
          type="button"
          onClick={onClose}
          className="font-mono text-[8px] px-2 py-0.5 border transition-all"
          style={{ color: C.muted, borderColor: C.cardBorder }}
          data-ocid="bank.create_account.close_button"
        >
          ✕ CANCEL
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label
            htmlFor="bank-account-id"
            className="font-mono text-[7px] tracking-[0.3em] block mb-1.5"
            style={{ color: C.muted }}
          >
            ACCOUNT ID
          </label>
          <input
            id="bank-account-id"
            type="text"
            value={accountId}
            onChange={(e) => setAccountId(e.target.value)}
            placeholder="e.g. acc_001"
            className="w-full px-3 py-2 font-mono text-xs outline-none"
            style={inputStyle}
            data-ocid="bank.account_id.input"
          />
        </div>
        <div>
          <label
            htmlFor="bank-owner-name"
            className="font-mono text-[7px] tracking-[0.3em] block mb-1.5"
            style={{ color: C.muted }}
          >
            OWNER NAME
          </label>
          <input
            id="bank-owner-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Full legal name"
            className="w-full px-3 py-2 font-mono text-xs outline-none"
            style={inputStyle}
            data-ocid="bank.account_name.input"
          />
        </div>
      </div>

      <div>
        <label
          htmlFor="bank-account-role"
          className="font-mono text-[7px] tracking-[0.3em] block mb-1.5"
          style={{ color: C.muted }}
        >
          ACCOUNT ROLE
        </label>
        <select
          id="bank-account-role"
          value={role}
          onChange={(e) => setRole(e.target.value as BankRole)}
          className="w-full px-3 py-2 font-mono text-xs outline-none"
          style={inputStyle}
          data-ocid="bank.account_role.select"
        >
          <option value="personal">PERSONAL</option>
          <option value="business">BUSINESS</option>
          <option value="institutional">INSTITUTIONAL</option>
        </select>
      </div>

      <button
        type="button"
        onClick={handleSubmit}
        disabled={createMutation.isPending || !accountId.trim() || !name.trim()}
        className="w-full py-2.5 font-mono text-xs tracking-[0.3em] border transition-all disabled:opacity-40"
        style={{
          borderColor: C.cyan,
          color: C.cyan,
          backgroundColor: C.cyanFaint,
        }}
        data-ocid="bank.create_account.submit_button"
      >
        {createMutation.isPending ? "⟳ CREATING..." : "CREATE ACCOUNT"}
      </button>

      {createMutation.isError && (
        <div
          className="font-mono text-[8px]"
          style={{ color: C.red }}
          data-ocid="bank.create_account.error_state"
        >
          ✗ {createMutation.error?.message ?? "Error creating account"}
        </div>
      )}
    </motion.div>
  );
}

// ── Accounts Table ────────────────────────────────────────────────────────────

function AccountsTable({ accounts }: { accounts: BankAccountEntry[] }) {
  const initKyc = useInitiateKyc();
  const toggleDelegated = useToggleDelegated();

  return (
    <div className="overflow-x-auto" data-ocid="bank.accounts.table">
      <table
        className="w-full font-mono text-[9px]"
        style={{ borderCollapse: "collapse" }}
      >
        <thead>
          <tr style={{ borderBottom: `1px solid ${C.cardBorder}` }}>
            {[
              "ACCOUNT ID",
              "NAME",
              "ROLE",
              "KYC",
              "ICP BAL",
              "THRESHOLD",
              "DELEGATED",
              "ACTIONS",
            ].map((h) => (
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
          {accounts.map((acc, i) => (
            <motion.tr
              key={acc.accountId}
              initial={{ opacity: 0, x: -8 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.04 }}
              style={{ borderBottom: "1px solid oklch(0.20 0.02 240 / 0.5)" }}
              data-ocid={`bank.account.item.${i + 1}`}
            >
              <td className="px-3 py-2.5 max-w-[120px]">
                <span
                  className="truncate block"
                  style={{ color: C.cyan }}
                  title={acc.accountId}
                >
                  {acc.accountId.length > 14
                    ? `${acc.accountId.slice(0, 14)}…`
                    : acc.accountId}
                </span>
              </td>
              <td
                className="px-3 py-2.5 whitespace-nowrap"
                style={{ color: C.text }}
              >
                {acc.ownerName}
              </td>
              <td className="px-3 py-2.5">
                <RoleBadge role={acc.role} />
              </td>
              <td className="px-3 py-2.5">
                <KycBadge status={acc.kycStatus} />
              </td>
              <td
                className="px-3 py-2.5 tabular-nums text-right"
                style={{ color: C.gold }}
              >
                {acc.icpBalance.toFixed(4)}
              </td>
              <td
                className="px-3 py-2.5 tabular-nums text-right"
                style={{ color: C.muted }}
              >
                {acc.thresholdLimit.toLocaleString()}
              </td>
              <td className="px-3 py-2.5 text-center">
                <span style={{ color: acc.delegatedSigning ? C.green : C.dim }}>
                  {acc.delegatedSigning ? "✓" : "—"}
                </span>
              </td>
              <td className="px-3 py-2.5">
                <div className="flex items-center gap-1.5">
                  {acc.kycStatus !== "verified" && (
                    <button
                      type="button"
                      onClick={() => initKyc.mutate(acc.accountId)}
                      disabled={initKyc.isPending}
                      className="px-2 py-0.5 border font-mono text-[7px] tracking-widest transition-all disabled:opacity-40"
                      style={{
                        color: C.amber,
                        borderColor: C.amberBorder,
                        backgroundColor: C.amberFaint,
                      }}
                      data-ocid={`bank.init_kyc.button.${i + 1}`}
                    >
                      KYC
                    </button>
                  )}
                  {acc.role === "institutional" && (
                    <button
                      type="button"
                      onClick={() => toggleDelegated.mutate(acc.accountId)}
                      disabled={toggleDelegated.isPending}
                      className="px-2 py-0.5 border font-mono text-[7px] tracking-widest transition-all disabled:opacity-40"
                      style={{
                        color: C.cyan,
                        borderColor: C.cyanBorder,
                        backgroundColor: C.cyanFaint,
                      }}
                      data-ocid={`bank.toggle_delegated.button.${i + 1}`}
                    >
                      SIGN
                    </button>
                  )}
                </div>
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ── KYC Endpoint Admin ────────────────────────────────────────────────────────

function KycEndpointAdmin() {
  const setEndpoint = useSetKycEndpoint();
  const [url, setUrl] = useState("");

  return (
    <div className="flex items-center gap-3 flex-wrap">
      <input
        type="url"
        value={url}
        onChange={(e) => setUrl(e.target.value)}
        placeholder="https://kyc-provider.example.com/verify"
        className="flex-1 min-w-[200px] px-3 py-2 font-mono text-xs outline-none"
        style={{
          background: "oklch(0.09 0.01 240)",
          border: `1px solid ${C.cardBorder}`,
          color: C.text,
        }}
        data-ocid="bank.kyc_endpoint.input"
      />
      <button
        type="button"
        onClick={() => {
          if (url.trim()) setEndpoint.mutate(url.trim());
        }}
        disabled={setEndpoint.isPending || !url.trim()}
        className="px-4 py-2 border font-mono text-[8px] tracking-[0.2em] transition-all disabled:opacity-40"
        style={{
          borderColor: C.goldBorder,
          color: C.gold,
          backgroundColor: C.goldFaint,
        }}
        data-ocid="bank.kyc_endpoint.save_button"
      >
        {setEndpoint.isPending ? "⟳ SAVING..." : "SAVE ENDPOINT"}
      </button>
    </div>
  );
}

// ── Main BankTab ──────────────────────────────────────────────────────────────

export function BankTab() {
  const { data: accounts = [], isLoading: accsLoading } = useBankAccounts();
  const { data: monitoring } = useTxMonitoring();
  const { data: ssu } = useBankingSsuState();
  const { data: yieldData } = useBankingYield();
  const exportFincen = useExportFinCEN();
  const [showCreateForm, setShowCreateForm] = useState(false);

  // Aggregate balances across all accounts
  const totalIcp = accounts.reduce((s, a) => s + a.icpBalance, 0);
  const totalCkBtc = accounts.reduce((s, a) => s + a.ckBtcBalance, 0);
  const totalCkEth = accounts.reduce((s, a) => s + a.ckEthBalance, 0);

  // All transactions, newest first
  const allTxs = accounts
    .flatMap((a) =>
      a.txHistory.map((tx) => ({ ...tx, accountId: a.accountId })),
    )
    .sort((a, b) => b.timestamp - a.timestamp)
    .slice(0, 50);

  const flaggedTxs = allTxs.filter((tx) => tx.flagged);

  const monitoringData = monitoring ?? {
    flaggedCount: 0,
    totalMonitored: 0,
    lastFlaggedAt: 0,
    personalThreshold: 1000,
    businessThreshold: 10000,
    institutionalThreshold: 100000,
  };

  const ssuData = ssu ?? {
    genesisHash: "T2-GENESIS-PARALLAX",
    beatCount: 0,
    kuramotoR: 0,
    aegisStatus: "INITIALIZING",
  };

  const yieldInfo = yieldData ?? {
    dailyMaturityEst: 0,
    weeklyEst: 0,
    neuronGroupStatus: "500 NEURONS ACTIVE",
  };

  return (
    <div className="space-y-0 pb-10" data-ocid="bank.page">
      {/* ── SECTION 1: BANK HEADER ──────────────────────────────────────────── */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="relative border-b overflow-hidden"
        style={{
          borderColor: C.goldBorder,
          backgroundColor: "oklch(0.10 0.02 240)",
          backgroundImage:
            "linear-gradient(oklch(0.78 0.18 85 / 0.02) 1px, transparent 1px), linear-gradient(90deg, oklch(0.78 0.18 85 / 0.02) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      >
        <div className="relative z-10 px-6 py-8">
          {/* Live indicator */}
          <div className="flex items-center gap-2 mb-4">
            <div
              className="w-2 h-2 animate-beat"
              style={{
                backgroundColor: C.green,
                boxShadow: `0 0 8px ${C.green}`,
              }}
            />
            <span
              className="font-mono text-[8px] tracking-[0.5em]"
              style={{ color: C.green }}
            >
              LIVE · SSU BEAT {ssuData.beatCount.toLocaleString()}
            </span>
          </div>

          <div
            className="font-display font-bold text-3xl md:text-4xl tracking-[0.3em] mb-2"
            style={{
              color: C.gold,
              textShadow: "0 0 40px oklch(0.78 0.18 85 / 0.35)",
            }}
          >
            T2 DIGITAL ASSET BANK
          </div>
          <div
            className="font-mono text-[9px] tracking-[0.25em]"
            style={{ color: C.muted }}
          >
            SOVEREIGN · NON-CUSTODIAL · US-COMPLIANT · PARALLAX-NATIVE
          </div>

          {/* SSU Status row */}
          <div className="mt-5 grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div
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
                GENESIS HASH
              </div>
              <div
                className="font-mono text-[9px] truncate"
                style={{ color: C.cyanDim }}
              >
                {ssuData.genesisHash
                  ? `${ssuData.genesisHash.slice(0, 18)}…`
                  : "PENDING"}
              </div>
            </div>
            <div
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
                BEAT COUNT
              </div>
              <div
                className="font-mono text-sm tabular-nums font-bold"
                style={{ color: C.gold }}
              >
                {ssuData.beatCount.toLocaleString()}
              </div>
            </div>
            <div
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
                KURAMOTO R
              </div>
              <div
                className="font-mono text-sm tabular-nums font-bold"
                style={{
                  color: ssuData.kuramotoR >= 0.618 ? C.green : C.amber,
                }}
              >
                {ssuData.kuramotoR.toFixed(4)}
              </div>
            </div>
            <div
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
                AEGIS STATUS
              </div>
              <span
                className="font-mono text-[9px] px-2 py-0.5 border tracking-widest"
                style={{
                  color:
                    ssuData.aegisStatus === "GATE_OPEN" ? C.green : C.amber,
                  borderColor:
                    ssuData.aegisStatus === "GATE_OPEN"
                      ? C.greenBorder
                      : C.amberBorder,
                  backgroundColor:
                    ssuData.aegisStatus === "GATE_OPEN"
                      ? C.greenFaint
                      : C.amberFaint,
                }}
              >
                {ssuData.aegisStatus || "INITIALIZING"}
              </span>
            </div>
          </div>

          {/* Yield estimate */}
          <div
            className="mt-4 flex flex-wrap gap-6 px-4 py-3 border font-mono text-[9px]"
            style={{
              background: "oklch(0.62 0.17 145 / 0.04)",
              borderColor: C.greenBorder,
            }}
          >
            <div>
              <span style={{ color: C.muted }}>DAILY MATURITY EST: </span>
              <span style={{ color: C.green }}>
                {yieldInfo.dailyMaturityEst.toFixed(6)} ICP
              </span>
            </div>
            <div>
              <span style={{ color: C.muted }}>WEEKLY EST: </span>
              <span style={{ color: C.green }}>
                {yieldInfo.weeklyEst.toFixed(4)} ICP
              </span>
            </div>
            <div>
              <span style={{ color: C.muted }}>NEURONS: </span>
              <span style={{ color: C.cyan }}>
                {yieldInfo.neuronGroupStatus || "500 NEURONS ACTIVE"}
              </span>
            </div>
          </div>
        </div>
      </motion.div>

      {/* ── SECTION 2: MULTI-ASSET BALANCES ─────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ MULTI-ASSET CUSTODY"
          sub="ICP · ckBTC · ckETH — All accounts aggregated. Non-custodial by default."
        />
        <div className="p-5">
          <div
            className="grid grid-cols-1 sm:grid-cols-3 gap-4"
            data-ocid="bank.balances.section"
          >
            {/* ICP */}
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.05 }}
              className="p-5 border relative overflow-hidden"
              style={{
                background: C.card,
                borderColor: C.goldBorder,
                boxShadow: "0 0 16px oklch(0.78 0.18 85 / 0.06)",
              }}
              data-ocid="bank.icp_balance.card"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div
                    className="font-mono text-[8px] tracking-[0.4em]"
                    style={{ color: C.muted }}
                  >
                    ICP
                  </div>
                  <div
                    className="font-mono text-2xl font-bold mt-0.5"
                    style={{ color: C.cyan }}
                  >
                    ⬡
                  </div>
                </div>
                {yieldInfo.dailyMaturityEst > 0 && (
                  <span
                    className="font-mono text-[7px] px-1.5 py-0.5 border"
                    style={{
                      color: C.green,
                      borderColor: C.greenBorder,
                      backgroundColor: C.greenFaint,
                    }}
                  >
                    STAKING
                  </span>
                )}
              </div>
              <div
                className="font-mono text-2xl font-bold tabular-nums"
                style={{ color: C.cyan }}
              >
                {totalIcp.toFixed(4)}
              </div>
              <div
                className="font-mono text-[8px] mt-1"
                style={{ color: C.dim }}
              >
                ICP
              </div>
              <div
                className="font-mono text-[8px] mt-0.5"
                style={{ color: C.dim }}
              >
                ≈ $
                {(totalIcp * 8.42).toLocaleString("en-US", {
                  maximumFractionDigits: 2,
                })}{" "}
                USD est.
              </div>
            </motion.div>

            {/* ckBTC */}
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="p-5 border relative overflow-hidden"
              style={{ background: C.card, borderColor: C.amberBorder }}
              data-ocid="bank.ckbtc_balance.card"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div
                    className="font-mono text-[8px] tracking-[0.4em]"
                    style={{ color: C.muted }}
                  >
                    ckBTC
                  </div>
                  <div
                    className="font-mono text-2xl font-bold mt-0.5"
                    style={{ color: C.amber }}
                  >
                    ₿
                  </div>
                </div>
              </div>
              <div
                className="font-mono text-2xl font-bold tabular-nums"
                style={{ color: C.amber }}
              >
                {totalCkBtc.toFixed(8)}
              </div>
              <div
                className="font-mono text-[8px] mt-1"
                style={{ color: C.dim }}
              >
                ckBTC
              </div>
              <div
                className="font-mono text-[8px] mt-0.5"
                style={{ color: C.dim }}
              >
                ≈ $
                {(totalCkBtc * 67000).toLocaleString("en-US", {
                  maximumFractionDigits: 2,
                })}{" "}
                USD est.
              </div>
            </motion.div>

            {/* ckETH */}
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 }}
              className="p-5 border relative overflow-hidden"
              style={{ background: C.card, borderColor: C.cyanBorder }}
              data-ocid="bank.cketh_balance.card"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div
                    className="font-mono text-[8px] tracking-[0.4em]"
                    style={{ color: C.muted }}
                  >
                    ckETH
                  </div>
                  <div
                    className="font-mono text-2xl font-bold mt-0.5"
                    style={{ color: C.cyan }}
                  >
                    Ξ
                  </div>
                </div>
              </div>
              <div
                className="font-mono text-2xl font-bold tabular-nums"
                style={{ color: C.cyan }}
              >
                {totalCkEth.toFixed(8)}
              </div>
              <div
                className="font-mono text-[8px] mt-1"
                style={{ color: C.dim }}
              >
                ckETH
              </div>
              <div
                className="font-mono text-[8px] mt-0.5"
                style={{ color: C.dim }}
              >
                ≈ $
                {(totalCkEth * 3200).toLocaleString("en-US", {
                  maximumFractionDigits: 2,
                })}{" "}
                USD est.
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      {/* ── SECTION 3: TX MONITORING ─────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ TRANSACTION MONITORING — COMPLIANCE ENGINE"
          sub="Real-time threshold monitoring. FinCEN-BSA compliant. Auto-flag on threshold breach."
        />
        <div className="p-5 space-y-4" data-ocid="bank.monitoring.section">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <StatCard
              label="TOTAL MONITORED"
              value={monitoringData.totalMonitored.toLocaleString()}
              valueColor={C.cyan}
            />
            <StatCard
              label="FLAGGED"
              value={monitoringData.flaggedCount.toLocaleString()}
              valueColor={monitoringData.flaggedCount > 0 ? C.red : C.green}
            />
            <StatCard
              label="LAST FLAGGED"
              value={
                monitoringData.lastFlaggedAt > 0
                  ? new Date(
                      monitoringData.lastFlaggedAt / 1_000_000,
                    ).toLocaleDateString()
                  : "NONE"
              }
              valueColor={C.muted}
            />
            <StatCard
              label="ACTIVE ACCOUNTS"
              value={accounts.length.toLocaleString()}
              valueColor={C.gold}
            />
          </div>

          {/* Threshold cards */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {[
              {
                label: "PERSONAL",
                threshold: monitoringData.personalThreshold,
                color: C.muted,
                border: C.cardBorder,
              },
              {
                label: "BUSINESS",
                threshold: monitoringData.businessThreshold,
                color: C.cyan,
                border: C.cyanBorder,
              },
              {
                label: "INSTITUTIONAL",
                threshold: monitoringData.institutionalThreshold,
                color: C.green,
                border: C.greenBorder,
              },
            ].map((tier) => (
              <div
                key={tier.label}
                className="p-4 border"
                style={{ background: C.card, borderColor: tier.border }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.4em] mb-2"
                  style={{ color: tier.color }}
                >
                  {tier.label} THRESHOLD
                </div>
                <div
                  className="font-mono text-lg font-bold tabular-nums"
                  style={{ color: tier.color }}
                >
                  {tier.threshold.toLocaleString()}
                </div>
                <div
                  className="font-mono text-[7px] mt-1"
                  style={{ color: C.dim }}
                >
                  ICP — AUTO-FLAG ABOVE LIMIT
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── SECTION 4: ACCOUNTS TABLE ─────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ SOVEREIGN ACCOUNTS"
          sub="Each account is its own compute unit on ICP. Non-custodial. You control the canister."
        />
        <div className="p-5 space-y-4" data-ocid="bank.accounts.section">
          {/* Create account button / form */}
          {!showCreateForm ? (
            <div className="flex items-center justify-between">
              <div className="font-mono text-[9px]" style={{ color: C.muted }}>
                {accounts.length} ACCOUNT{accounts.length !== 1 ? "S" : ""}{" "}
                REGISTERED
              </div>
              <button
                type="button"
                onClick={() => setShowCreateForm(true)}
                className="px-4 py-2 border font-mono text-[8px] tracking-[0.25em] transition-all"
                style={{
                  borderColor: C.cyanBorder,
                  color: C.cyan,
                  backgroundColor: C.cyanFaint,
                }}
                data-ocid="bank.create_account.open_modal_button"
              >
                + CREATE ACCOUNT
              </button>
            </div>
          ) : (
            <CreateAccountForm onClose={() => setShowCreateForm(false)} />
          )}

          {/* Table or empty state */}
          {accsLoading ? (
            <div
              className="py-8 text-center font-mono text-[9px]"
              style={{ color: C.muted }}
              data-ocid="bank.accounts.loading_state"
            >
              <div
                className="inline-block w-4 h-4 border-t border-l animate-spin mb-2"
                style={{ borderColor: C.cyan }}
              />
              <div>LOADING ACCOUNTS...</div>
            </div>
          ) : accounts.length === 0 ? (
            <div
              className="py-12 text-center border"
              style={{ background: C.card, borderColor: C.cardBorder }}
              data-ocid="bank.accounts.empty_state"
            >
              <div className="font-mono text-3xl mb-3" style={{ color: C.dim }}>
                ⊡
              </div>
              <div
                className="font-mono text-[9px] tracking-[0.3em] mb-1"
                style={{ color: C.muted }}
              >
                NO ACCOUNTS YET
              </div>
              <div
                className="font-mono text-[8px] mb-4"
                style={{ color: C.dim }}
              >
                Create your first sovereign non-custodial account
              </div>
              <button
                type="button"
                onClick={() => setShowCreateForm(true)}
                className="px-5 py-2 border font-mono text-[8px] tracking-[0.25em] transition-all"
                style={{
                  borderColor: C.cyanBorder,
                  color: C.cyan,
                  backgroundColor: C.cyanFaint,
                }}
                data-ocid="bank.empty.create_button"
              >
                + CREATE ACCOUNT
              </button>
            </div>
          ) : (
            <div className="border" style={{ borderColor: C.cardBorder }}>
              <AccountsTable accounts={accounts} />
            </div>
          )}
        </div>
      </div>

      {/* ── SECTION 5: TRANSACTION HISTORY ───────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ TRANSACTION HISTORY"
          sub="All accounts · Newest first · Flagged entries highlighted"
        />
        <div className="p-5" data-ocid="bank.transactions.section">
          {allTxs.length === 0 ? (
            <div
              className="py-8 text-center border font-mono text-[9px]"
              style={{
                background: C.card,
                borderColor: C.cardBorder,
                color: C.muted,
              }}
              data-ocid="bank.transactions.empty_state"
            >
              NO TRANSACTIONS RECORDED
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table
                className="w-full font-mono text-[9px]"
                style={{ borderCollapse: "collapse" }}
              >
                <thead>
                  <tr style={{ borderBottom: `1px solid ${C.cardBorder}` }}>
                    {[
                      "TX ID",
                      "ASSET",
                      "AMOUNT",
                      "DIR",
                      "ACCOUNT",
                      "STATUS",
                      "TIMESTAMP",
                    ].map((h) => (
                      <th
                        key={h}
                        className="text-left px-3 py-2 tracking-[0.2em] whitespace-nowrap"
                        style={{ color: C.muted }}
                      >
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {allTxs.map((tx, i) => (
                    <tr
                      key={`${tx.txId}-${i}`}
                      style={{
                        borderBottom: "1px solid oklch(0.20 0.02 240 / 0.4)",
                        backgroundColor: tx.flagged
                          ? "oklch(0.55 0.22 25 / 0.04)"
                          : "transparent",
                      }}
                      data-ocid={`bank.tx.item.${i + 1}`}
                    >
                      <td className="px-3 py-2">
                        <span style={{ color: tx.flagged ? C.red : C.muted }}>
                          {tx.txId.slice(0, 12)}…
                        </span>
                      </td>
                      <td className="px-3 py-2" style={{ color: C.text }}>
                        {tx.asset}
                      </td>
                      <td
                        className="px-3 py-2 tabular-nums text-right"
                        style={{
                          color: tx.direction === "in" ? C.green : C.amber,
                        }}
                      >
                        {tx.direction === "in" ? "+" : "−"}
                        {tx.amount.toFixed(4)}
                      </td>
                      <td className="px-3 py-2 text-center">
                        <span
                          style={{
                            color: tx.direction === "in" ? C.green : C.amber,
                          }}
                        >
                          {tx.direction === "in" ? "↓" : "↑"}
                        </span>
                      </td>
                      <td className="px-3 py-2 max-w-[100px]">
                        <span
                          className="truncate block"
                          style={{ color: C.cyanDim }}
                        >
                          {tx.accountId.slice(0, 10)}…
                        </span>
                      </td>
                      <td className="px-3 py-2">
                        {tx.flagged ? (
                          <span
                            className="px-1.5 py-0.5 border font-mono text-[7px]"
                            style={{
                              color: C.red,
                              borderColor: C.redBorder,
                              backgroundColor: C.redFaint,
                            }}
                          >
                            ⚑ FLAGGED
                          </span>
                        ) : (
                          <span
                            className="font-mono text-[7px]"
                            style={{ color: C.dim }}
                          >
                            CLEAR
                          </span>
                        )}
                      </td>
                      <td
                        className="px-3 py-2 tabular-nums whitespace-nowrap"
                        style={{ color: C.dim }}
                      >
                        {tx.timestamp > 0
                          ? new Date(tx.timestamp / 1_000_000).toLocaleString(
                              "en-US",
                              {
                                month: "short",
                                day: "numeric",
                                hour: "2-digit",
                                minute: "2-digit",
                              },
                            )
                          : "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Flagged summary */}
          {flaggedTxs.length > 0 && (
            <div
              className="mt-3 px-4 py-2.5 border font-mono text-[8px]"
              style={{
                backgroundColor: C.redFaint,
                borderColor: C.redBorder,
                color: C.red,
              }}
            >
              ⚑ {flaggedTxs.length} FLAGGED TRANSACTION
              {flaggedTxs.length !== 1 ? "S" : ""} REQUIRE COMPLIANCE REVIEW
            </div>
          )}
        </div>
      </div>

      {/* ── SECTION 6: FINCEN EXPORT ─────────────────────────────────────────── */}
      <div>
        <SectionHeader
          label="■ COMPLIANCE EXPORT — FINCEN BSA FORMAT"
          sub="FinCEN-compatible audit export. All transactions. Permanently logged."
        />
        <div className="p-5 space-y-4" data-ocid="bank.fincen.section">
          <div
            className="px-4 py-3 border font-mono text-[8px] leading-relaxed"
            style={{
              backgroundColor: "oklch(0.72 0.15 200 / 0.04)",
              borderColor: C.cyanBorder,
              color: C.cyanDim,
            }}
          >
            EXPORT COVERS ALL TRANSACTIONS ACROSS ALL ACCOUNTS. INCLUDES: TX ID
            · ASSET · AMOUNT · DIRECTION · ACCOUNT · FLAG STATUS · TIMESTAMP.
            FORMAT: CSV (SPREADSHEET) OR JSON (MACHINE-READABLE). EVERY EXPORT
            IS PERMANENTLY LOGGED TO THE ANIMA CHAIN.
          </div>

          <div className="flex items-center gap-3 flex-wrap">
            <div className="font-mono text-[9px]" style={{ color: C.muted }}>
              {allTxs.length} AUDIT ENTRIES AVAILABLE
            </div>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => exportFincen.mutate("csv")}
                disabled={exportFincen.isPending}
                className="px-4 py-2 border font-mono text-[8px] tracking-[0.2em] transition-all disabled:opacity-40"
                style={{
                  borderColor: C.goldBorder,
                  color: C.gold,
                  backgroundColor: C.goldFaint,
                }}
                data-ocid="bank.export_csv.button"
              >
                {exportFincen.isPending ? "⟳ EXPORTING..." : "EXPORT CSV"}
              </button>
              <button
                type="button"
                onClick={() => exportFincen.mutate("json")}
                disabled={exportFincen.isPending}
                className="px-4 py-2 border font-mono text-[8px] tracking-[0.2em] transition-all disabled:opacity-40"
                style={{
                  borderColor: C.cyanBorder,
                  color: C.cyan,
                  backgroundColor: C.cyanFaint,
                }}
                data-ocid="bank.export_json.button"
              >
                {exportFincen.isPending ? "⟳ EXPORTING..." : "EXPORT JSON"}
              </button>
            </div>
          </div>

          {exportFincen.isSuccess && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="px-4 py-2 border font-mono text-[8px]"
              style={{
                backgroundColor: C.greenFaint,
                borderColor: C.greenBorder,
                color: C.green,
              }}
              data-ocid="bank.fincen.success_state"
            >
              ✓ EXPORT COMPLETE — FILE DOWNLOADED
            </motion.div>
          )}

          {/* KYC Endpoint Admin */}
          <div className="border-t pt-4" style={{ borderColor: C.cardBorder }}>
            <div
              className="font-mono text-[8px] tracking-[0.3em] mb-3"
              style={{ color: C.muted }}
            >
              KYC ENDPOINT — ADMIN CONFIGURABLE
            </div>
            <KycEndpointAdmin />
          </div>
        </div>
      </div>

      {/* ── SECTION 7: SOVEREIGN ARCHITECTURE CARD ───────────────────────────── */}
      <div>
        <SectionHeader
          label="■ SOVEREIGN PER-ACCOUNT CANISTER ARCHITECTURE"
          sub="Why T2 is better than Telecoin. Structurally non-custodial. No shared server. No hack surface."
        />
        <div className="p-5 space-y-5" data-ocid="bank.architecture.section">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Architecture explanation */}
            <div className="space-y-3">
              <div
                className="p-4 border"
                style={{ background: C.card, borderColor: C.cyanBorder }}
              >
                <div
                  className="font-mono text-[8px] tracking-[0.4em] mb-3"
                  style={{ color: C.cyan }}
                >
                  T2 · SOVEREIGN MODEL
                </div>
                <div
                  className="space-y-2 font-mono text-[8px]"
                  style={{ color: C.muted, lineHeight: 1.8 }}
                >
                  <div>✓ Each account is its own compute unit on ICP</div>
                  <div>✓ No user data on a shared server — ever</div>
                  <div>✓ Non-custodial by default</div>
                  <div>
                    ✓ Optional delegated signing for institutional accounts
                  </div>
                  <div>
                    ✓ PARALLAX is the network operator, not the account holder
                  </div>
                  <div>
                    ✓ You control your canister. The bank cannot be hacked at
                    the server level because there is no server.
                  </div>
                </div>
              </div>
              <div
                className="p-4 border"
                style={{ background: C.card, borderColor: C.redBorder }}
              >
                <div
                  className="font-mono text-[8px] tracking-[0.4em] mb-3"
                  style={{ color: C.red }}
                >
                  TELECOIN · CUSTODIAL MODEL
                </div>
                <div
                  className="space-y-2 font-mono text-[8px]"
                  style={{ color: C.muted, lineHeight: 1.8 }}
                >
                  <div>✗ Custodial — they hold your keys</div>
                  <div>✗ Centralized behind a corporate entity</div>
                  <div>
                    ✗ Single point of failure — one server breach = all accounts
                    exposed
                  </div>
                  <div>✗ You are their customer, not the owner</div>
                </div>
              </div>
            </div>

            {/* Architecture diagram */}
            <div
              className="p-5 border font-mono text-[8px]"
              style={{ background: C.card, borderColor: C.goldBorder }}
            >
              <div
                className="font-mono text-[8px] tracking-[0.4em] mb-4"
                style={{ color: C.gold }}
              >
                ARCHITECTURE DIAGRAM
              </div>
              <div className="space-y-2" style={{ color: C.muted }}>
                {[
                  { label: "ACCOUNT A CANISTER", color: C.cyan },
                  { label: "ACCOUNT B CANISTER", color: C.cyan },
                  { label: "ACCOUNT C CANISTER", color: C.cyan },
                ].map((node) => (
                  <div key={node.label} className="flex items-center gap-2">
                    <span
                      className="px-2 py-1 border"
                      style={{
                        color: node.color,
                        borderColor: node.color,
                        backgroundColor: "oklch(0.72 0.15 200 / 0.04)",
                      }}
                    >
                      [{node.label}]
                    </span>
                    <span style={{ color: C.dim }}>→</span>
                    <span style={{ color: C.gold }}>ICP LEDGER</span>
                    <span style={{ color: C.dim }}>|</span>
                    <span style={{ color: C.amber }}>ckBTC</span>
                    <span style={{ color: C.dim }}>|</span>
                    <span style={{ color: C.cyan }}>ckETH</span>
                  </div>
                ))}
                <div
                  className="pt-2 mt-2 border-t"
                  style={{ borderColor: C.cardBorder, color: C.dim }}
                >
                  Each canister → PARALLAX TREASURY BACKBONE → THESAURUS
                  PARALLAXI
                </div>
              </div>

              {/* Differentiator bullet */}
              <div
                className="mt-4 pt-4 border-t space-y-1.5"
                style={{ borderColor: C.goldBorder }}
              >
                <div
                  className="font-mono text-[7px] tracking-[0.4em] mb-2"
                  style={{ color: C.gold }}
                >
                  THE STRUCTURAL DIFFERENCE
                </div>
                <div
                  className="font-mono text-[8px]"
                  style={{ color: C.goldDim, lineHeight: 1.8 }}
                >
                  Telecoin = custodial + centralized + corporate entity between
                  you and your money.
                </div>
                <div
                  className="font-mono text-[8px]"
                  style={{ color: C.gold, lineHeight: 1.8 }}
                >
                  T2 = structurally non-custodial + sovereign per-account
                  canister + PARALLAX is the network operator, not the account
                  holder. Fundamentally different legal and security posture.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
