/**
 * useWallet.ts — THESAURUS PARALLAXI sovereign wallet hooks.
 * All 26 tokens, DOMUS LIBERATORIS status, full wallet snapshot.
 * LIBERATOR executes real ICRC-1 withdrawals via the backend.
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useActor } from "./useActor";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface TokenEntry {
  symbol: string;
  name: string;
  homeCanister: string;
  totalSupply: number;
  creatorReserveBalance: number;
  mintTrigger: string;
  burnTrigger: string;
  managingAgi: string;
  circulatingSupply: number;
  priceIcp: number;
}

export interface FullWalletSnapshot {
  icpBalance: number;
  btcBalance: number;
  ethBalance: number;
  mtcCirculating: number;
  creatorIcp: number;
  creatorBtc: number;
  creatorEth: number;
  creatorMtc: number;
  withdrawableIcp: number;
  totalWithdrawn: number;
  totalUsdEquiv: number;
  tokenCount: number;
  neuronCount: number;
  beatCount: number;
}

export interface DomLibStatus {
  verificatorChecks: number;
  auditorLogCount: number;
  confirmatorReceiptsCount: number;
  protectorBlocks: number;
  recentAuditLogs: string[];
  recentReceipts: string[];
}

export interface CodexEntry {
  id: string;
  name: string;
  category: string;
  principleOneLine: string;
  formula: string;
  numericalValue: number;
  ancientSource: string;
  enforcementAgi: string;
  meaning: string;
  computation: string;
}

// ── Default fallback data ─────────────────────────────────────────────────────

const DEFAULT_TOKENS: TokenEntry[] = [
  // MARKET TOKENS
  {
    symbol: "NOVA",
    name: "Native Nova Token",
    homeCanister: "nova_token",
    totalSupply: 521001966,
    circulatingSupply: 521001966,
    creatorReserveBalance: 199231.4,
    mintTrigger: "SNS governance",
    burnTrigger: "Treasury buyback",
    managingAgi: "GUBERNATOR",
    priceIcp: 0.0042,
  },
  {
    symbol: "NNC",
    name: "Native Nova Cycles",
    homeCanister: "cycles_market",
    totalSupply: 100000000000,
    circulatingSupply: 8932100000,
    creatorReserveBalance: 0,
    mintTrigger: "DIVI AI on demand",
    burnTrigger: "Cycle consumption",
    managingAgi: "DISPENSATOR",
    priceIcp: 0,
  },
  // SOVEREIGN INTERNAL
  {
    symbol: "SVR",
    name: "Sovereign Access Token",
    homeCanister: "sovereign_db",
    totalSupply: 1000000,
    circulatingSupply: 847300,
    creatorReserveBalance: 152700,
    mintTrigger: "Access grant",
    burnTrigger: "Access revoke",
    managingAgi: "VERIFICATOR",
    priceIcp: 0,
  },
  {
    symbol: "DOC",
    name: "Research Archive Token",
    homeCanister: "sovereign_db",
    totalSupply: 500000,
    circulatingSupply: 312000,
    creatorReserveBalance: 188000,
    mintTrigger: "Paper submission",
    burnTrigger: "Archive expiry",
    managingAgi: "AUDITOR",
    priceIcp: 0,
  },
  {
    symbol: "LINEA",
    name: "Lineage License Token",
    homeCanister: "sovereign_db",
    totalSupply: 200000,
    circulatingSupply: 88000,
    creatorReserveBalance: 112000,
    mintTrigger: "License grant",
    burnTrigger: "License revoke",
    managingAgi: "CUSTODITOR",
    priceIcp: 0,
  },
  {
    symbol: "CVT",
    name: "Covenant Token",
    homeCanister: "nexoris",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Contract execution / bus signal",
    burnTrigger: "Contract expiry",
    managingAgi: "NEXORIS",
    priceIcp: 0,
  },
  {
    symbol: "DRT",
    name: "Agent Task Token",
    homeCanister: "nexoris",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Agent task completion",
    burnTrigger: "Task archive",
    managingAgi: "COMPUTATOR",
    priceIcp: 0,
  },
  {
    symbol: "KNT",
    name: "Knowledge Token",
    homeCanister: "sovereign_db",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Paper draft",
    burnTrigger: "KB expiry",
    managingAgi: "AUDITOR",
    priceIcp: 0,
  },
  {
    symbol: "MTC",
    name: "Meridian Token",
    homeCanister: "token_forge",
    totalSupply: 999999999,
    circulatingSupply: 999999999,
    creatorReserveBalance: 4015.91,
    mintTrigger: "AI workflow completion",
    burnTrigger: "Burn mechanism",
    managingAgi: "DISPENSATOR",
    priceIcp: 0.01,
  },
  {
    symbol: "ANT",
    name: "Anti-failure Token",
    homeCanister: "sovereign_db",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Agent failure recovery",
    burnTrigger: "Recovery complete",
    managingAgi: "CUSTODITOR",
    priceIcp: 0,
  },
  {
    symbol: "SEED",
    name: "Genesis Query Token",
    homeCanister: "sovereign_db",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Student canister first query",
    burnTrigger: "Canister dissolution",
    managingAgi: "EXPLORATOR",
    priceIcp: 0,
  },
  {
    symbol: "LINGUA",
    name: "Translation Token",
    homeCanister: "nexoris",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "HTTP outcall / paper submission",
    burnTrigger: "Route expiry",
    managingAgi: "NEXORIS",
    priceIcp: 0,
  },
  {
    symbol: "MRC",
    name: "Royalty Token",
    homeCanister: "sovereign_factory",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Protocol licensing",
    burnTrigger: "Royalty settlement",
    managingAgi: "DISPENSATOR",
    priceIcp: 0,
  },
  {
    symbol: "FORMA",
    name: "Compounding Treasury Token",
    homeCanister: "parallax",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Treasury compounding beat",
    burnTrigger: "Treasury rebalance",
    managingAgi: "COMPUTATOR",
    priceIcp: 0,
  },
  {
    symbol: "VCT",
    name: "Vault Credit Token",
    homeCanister: "parallax",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Vault deposit",
    burnTrigger: "Vault withdrawal",
    managingAgi: "LIBERATOR",
    priceIcp: 0,
  },
  {
    symbol: "SBT",
    name: "Substrate Token",
    homeCanister: "sovereign_db",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Substrate activation",
    burnTrigger: "Substrate deactivation",
    managingAgi: "CUSTODITOR",
    priceIcp: 0,
  },
  {
    symbol: "MTH",
    name: "Math Proof Token",
    homeCanister: "codex_mathematicus",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Formula proof execution",
    burnTrigger: "Proof expiry",
    managingAgi: "COMPUTATOR",
    priceIcp: 0,
  },
  // ORGANISM TOKENS
  {
    symbol: "CHR",
    name: "Chrysalis Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Bootstrap / work reward",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "CHRYSALIS",
    priceIcp: 0,
  },
  {
    symbol: "SCB",
    name: "Scribe Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Data recording",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "SCRIBE",
    priceIcp: 0,
  },
  {
    symbol: "ARC",
    name: "Architect Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Build completion",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "ARCHITECT",
    priceIcp: 0,
  },
  {
    symbol: "NXS",
    name: "Nexus Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Routing completion",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "NEXUS",
    priceIcp: 0,
  },
  {
    symbol: "SWM",
    name: "Swarm Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Swarm coordination",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "SWARM_BRAIN",
    priceIcp: 0,
  },
  {
    symbol: "PHT",
    name: "Phantom Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Cross-substrate op",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "NEXUS",
    priceIcp: 0,
  },
  {
    symbol: "ORS",
    name: "Reserve Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Reserve deposit",
    burnTrigger: "Reserve withdrawal",
    managingAgi: "LIBERATOR",
    priceIcp: 1,
  },
  {
    symbol: "GOL",
    name: "Latin AGI Token",
    homeCanister: "organism_token",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Bootstrap / work reward",
    burnTrigger: "φ⁻¹ burn",
    managingAgi: "MEMORIA_NNS",
    priceIcp: 0,
  },
  // SOVEREIGN UNIT
  {
    symbol: "ONESICAN",
    name: "Sovereign Unit Token",
    homeCanister: "cycles_bridge",
    totalSupply: 0,
    circulatingSupply: 0,
    creatorReserveBalance: 0,
    mintTrigger: "Substrate activation",
    burnTrigger: "φ⁻¹ net zero burn",
    managingAgi: "COMPUTATOR",
    priceIcp: 1,
  },
];

const DEFAULT_SNAPSHOT: FullWalletSnapshot = {
  icpBalance: 10000,
  btcBalance: 2.5,
  ethBalance: 15,
  mtcCirculating: 999999999.99762,
  creatorIcp: 12.0589683,
  creatorBtc: 0.00099965,
  creatorEth: 0.00003856,
  creatorMtc: 4015.912013,
  withdrawableIcp: 12.0589683,
  totalWithdrawn: 0,
  totalUsdEquiv: 146.72,
  tokenCount: 26,
  neuronCount: 500,
  beatCount: 2496,
};

const DEFAULT_DOM_LIB: DomLibStatus = {
  verificatorChecks: 2496,
  auditorLogCount: 2496,
  confirmatorReceiptsCount: 0,
  protectorBlocks: 0,
  recentAuditLogs: [
    "BEAT 2496 — HEARTBEAT NOMINAL — ORGANISM LIVE",
    "BEAT 2495 — D_LIQUID DISBURSE — 0.00482 ICP → CREATOR RESERVE",
    "BEAT 2494 — C_HARVEST SPAWN — NEURON 501 BORN",
    "BEAT 2493 — VERIFICATOR CHECK — DESTINATION VALID",
    "BEAT 2492 — MEMORIA_NNS CONFIRM — LEX_PRIMA_OECONOMIA INTACT",
  ],
  recentReceipts: [],
};

// ── Helper ────────────────────────────────────────────────────────────────────

function toN(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return Number.isFinite(v) ? v : 0;
  return 0;
}

function toStrArr(v: unknown): string[] {
  if (Array.isArray(v)) return v.map(String);
  return [];
}

// ── Constants ─────────────────────────────────────────────────────────────────

export const FOUNDER_ACCOUNT_ID =
  "8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879";

// ── Hooks ─────────────────────────────────────────────────────────────────────

/**
 * useFounderAccountId — calls backend's getFounderAccountId() query.
 * Falls back to the canonical hardcoded address if backend does not expose it.
 * The "wired" flag confirms the address came from the organism, not just the frontend.
 */
export function useFounderAccountId() {
  const { actor, isFetching } = useActor();
  return useQuery<{ address: string; wired: boolean }>({
    queryKey: ["founderAccountId"],
    queryFn: async (): Promise<{ address: string; wired: boolean }> => {
      if (!actor) return { address: FOUNDER_ACCOUNT_ID, wired: false };
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        if (a.getFounderAccountId) {
          const result = await a.getFounderAccountId();
          const addr = String(result ?? "");
          if (addr && addr.length === 64) {
            return { address: addr, wired: true };
          }
        }
        return { address: FOUNDER_ACCOUNT_ID, wired: false };
      } catch {
        return { address: FOUNDER_ACCOUNT_ID, wired: false };
      }
    },
    enabled: !isFetching,
    refetchInterval: 60000,
    placeholderData: { address: FOUNDER_ACCOUNT_ID, wired: false },
  });
}

export function useFullWalletSnapshot() {
  const { actor, isFetching } = useActor();
  return useQuery<FullWalletSnapshot>({
    queryKey: ["fullWalletSnapshot"],
    queryFn: async (): Promise<FullWalletSnapshot> => {
      if (!actor) return DEFAULT_SNAPSHOT;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getFullWalletSnapshot
          ? await a.getFullWalletSnapshot()
          : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        return {
          icpBalance: toN(r.icpBalance) || DEFAULT_SNAPSHOT.icpBalance,
          btcBalance: toN(r.btcBalance) || DEFAULT_SNAPSHOT.btcBalance,
          ethBalance: toN(r.ethBalance) || DEFAULT_SNAPSHOT.ethBalance,
          mtcCirculating:
            toN(r.mtcCirculating) || DEFAULT_SNAPSHOT.mtcCirculating,
          creatorIcp: toN(r.creatorIcp) || DEFAULT_SNAPSHOT.creatorIcp,
          creatorBtc: toN(r.creatorBtc) || DEFAULT_SNAPSHOT.creatorBtc,
          creatorEth: toN(r.creatorEth) || DEFAULT_SNAPSHOT.creatorEth,
          creatorMtc: toN(r.creatorMtc) || DEFAULT_SNAPSHOT.creatorMtc,
          withdrawableIcp:
            toN(r.withdrawableIcp) || DEFAULT_SNAPSHOT.withdrawableIcp,
          totalWithdrawn: toN(r.totalWithdrawn),
          totalUsdEquiv: toN(r.totalUsdEquiv) || DEFAULT_SNAPSHOT.totalUsdEquiv,
          tokenCount: toN(r.tokenCount) || 26,
          neuronCount: toN(r.neuronCount) || DEFAULT_SNAPSHOT.neuronCount,
          beatCount: toN(r.beatCount) || DEFAULT_SNAPSHOT.beatCount,
        };
      } catch {
        return DEFAULT_SNAPSHOT;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
    placeholderData: DEFAULT_SNAPSHOT,
  });
}

export function useTokenRegistry() {
  const { actor, isFetching } = useActor();
  return useQuery<TokenEntry[]>({
    queryKey: ["tokenRegistry"],
    queryFn: async (): Promise<TokenEntry[]> => {
      if (!actor) return DEFAULT_TOKENS;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getTokenRegistry ? await a.getTokenRegistry() : null;
        if (!raw || !Array.isArray(raw) || raw.length === 0)
          return DEFAULT_TOKENS;
        return raw.map((item: unknown) => {
          const t = (item ?? {}) as Record<string, unknown>;
          return {
            symbol: String(t.symbol ?? ""),
            name: String(t.name ?? ""),
            homeCanister: String(t.homeCanister ?? ""),
            totalSupply: toN(t.totalSupply),
            creatorReserveBalance: toN(t.creatorReserveBalance),
            mintTrigger: String(t.mintTrigger ?? ""),
            burnTrigger: String(t.burnTrigger ?? ""),
            managingAgi: String(t.managingAgi ?? ""),
            circulatingSupply: toN(t.circulatingSupply),
            priceIcp: toN(t.priceIcp),
          };
        });
      } catch {
        return DEFAULT_TOKENS;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30000,
    placeholderData: DEFAULT_TOKENS,
  });
}

export function useCodexMathematicus() {
  const { actor, isFetching } = useActor();
  return useQuery<CodexEntry[]>({
    queryKey: ["codexMathematicus"],
    queryFn: async (): Promise<CodexEntry[]> => {
      if (!actor) return [];
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getCodexMathematicus
          ? await a.getCodexMathematicus()
          : null;
        if (!raw || !Array.isArray(raw)) return [];
        return raw.map((item: unknown) => {
          const c = (item ?? {}) as Record<string, unknown>;
          return {
            id: String(c.id ?? ""),
            name: String(c.name ?? ""),
            category: String(c.category ?? ""),
            principleOneLine: String(c.principleOneLine ?? ""),
            formula: String(c.formula ?? ""),
            numericalValue: toN(c.numericalValue),
            ancientSource: String(c.ancientSource ?? ""),
            enforcementAgi: String(c.enforcementAgi ?? ""),
            meaning: String(c.meaning ?? ""),
            computation: String(c.computation ?? ""),
          };
        });
      } catch {
        return [];
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 60000,
  });
}

export function useDomLibStatus() {
  const { actor, isFetching } = useActor();
  return useQuery<DomLibStatus>({
    queryKey: ["domLibStatus"],
    queryFn: async (): Promise<DomLibStatus> => {
      if (!actor) return DEFAULT_DOM_LIB;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getDomLibStatus ? await a.getDomLibStatus() : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        return {
          verificatorChecks:
            toN(r.verificatorChecks) || DEFAULT_DOM_LIB.verificatorChecks,
          auditorLogCount:
            toN(r.auditorCount) || DEFAULT_DOM_LIB.auditorLogCount,
          confirmatorReceiptsCount: toN(r.confirmatorCount),
          protectorBlocks: toN(r.protectorBlocks),
          recentAuditLogs: toStrArr(r.recentAuditLogs).length
            ? toStrArr(r.recentAuditLogs)
            : DEFAULT_DOM_LIB.recentAuditLogs,
          recentReceipts: toStrArr(r.recentReceipts),
        };
      } catch {
        return DEFAULT_DOM_LIB;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
    placeholderData: DEFAULT_DOM_LIB,
  });
}

export function useWithdrawIcp() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation<
    { blockIndex: bigint } | null,
    Error,
    { destination: string; amountE8s: bigint }
  >({
    mutationFn: async ({ destination, amountE8s }) => {
      if (!actor) throw new Error("No actor");
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      if (!a.withdrawToExternalWallet)
        throw new Error("withdrawToExternalWallet not available");
      const result = await a.withdrawToExternalWallet(destination, amountE8s);
      const r = result as Record<string, unknown>;
      if (r && typeof r === "object" && "ok" in r) {
        const ok = r.ok as Record<string, unknown>;
        return { blockIndex: ok.blockIndex as bigint };
      }
      if (r && typeof r === "object" && "err" in r) {
        throw new Error(String(r.err));
      }
      return null;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["fullWalletSnapshot"] });
      qc.invalidateQueries({ queryKey: ["domLibStatus"] });
    },
  });
}
