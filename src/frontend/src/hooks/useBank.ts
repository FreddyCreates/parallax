/**
 * useBank.ts — T2 Digital Asset Bank React Query Hooks
 * PARALLAX · Sovereign Non-Custodial Banking · US-Compliant
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useActor } from "./useActor";

// ── Type helpers ──────────────────────────────────────────────────────────────

export type BankRole = "personal" | "business" | "institutional";
export type KycStatus = "pending" | "verified" | "rejected" | "notStarted";
export type TxDirection = "in" | "out";

export interface BankTxEntry {
  txId: string;
  timestamp: number;
  amount: number;
  asset: string;
  direction: TxDirection;
  flagged: boolean;
  note: string;
}

export interface BankAccountEntry {
  accountId: string;
  ownerName: string;
  role: BankRole;
  kycStatus: KycStatus;
  delegatedSigning: boolean;
  icpBalance: number;
  ckBtcBalance: number;
  ckEthBalance: number;
  txHistory: BankTxEntry[];
  thresholdLimit: number;
  createdAt: number;
}

export interface TxMonitoringState {
  flaggedCount: number;
  totalMonitored: number;
  lastFlaggedAt: number;
  personalThreshold: number;
  businessThreshold: number;
  institutionalThreshold: number;
}

export interface BankingSsuState {
  genesisHash: string;
  beatCount: number;
  kuramotoR: number;
  aegisStatus: string;
}

export interface BankingYield {
  dailyMaturityEst: number;
  weeklyEst: number;
  neuronGroupStatus: string;
}

// ── Actor call helper ─────────────────────────────────────────────────────────

type AnyActor = Record<string, (...args: unknown[]) => Promise<unknown>>;

function actorCall(actor: unknown): AnyActor {
  return actor as AnyActor;
}

// ── Motoko variant decoders ───────────────────────────────────────────────────

export function getRoleLabel(role: unknown): BankRole {
  if (role && typeof role === "object") {
    if ("institutional" in (role as object)) return "institutional";
    if ("business" in (role as object)) return "business";
  }
  return "personal";
}

export function getKycLabel(status: unknown): KycStatus {
  if (status && typeof status === "object") {
    if ("verified" in (status as object)) return "verified";
    if ("pending" in (status as object)) return "pending";
    if ("rejected" in (status as object)) return "rejected";
  }
  return "notStarted";
}

export function getTxDirection(dir: unknown): TxDirection {
  if (dir && typeof dir === "object") {
    if ("out_" in (dir as object)) return "out";
  }
  return "in";
}

function decodeTx(raw: Record<string, unknown>): BankTxEntry {
  return {
    txId: String(raw.txId ?? ""),
    timestamp: Number(raw.timestamp ?? 0),
    amount: Number(raw.amount ?? 0),
    asset: String(raw.asset ?? "ICP"),
    direction: getTxDirection(raw.direction),
    flagged: Boolean(raw.flagged),
    note: String(raw.note ?? ""),
  };
}

function decodeAccount(raw: Record<string, unknown>): BankAccountEntry {
  const txHistory = Array.isArray(raw.txHistory)
    ? (raw.txHistory as Record<string, unknown>[]).map(decodeTx)
    : [];
  return {
    accountId: String(raw.accountId ?? ""),
    ownerName: String(raw.ownerName ?? ""),
    role: getRoleLabel(raw.role),
    kycStatus: getKycLabel(raw.kycStatus),
    delegatedSigning: Boolean(raw.delegatedSigning),
    icpBalance: Number(raw.icpBalance ?? 0),
    ckBtcBalance: Number(raw.ckBtcBalance ?? 0),
    ckEthBalance: Number(raw.ckEthBalance ?? 0),
    txHistory,
    thresholdLimit: Number(raw.thresholdLimit ?? 1000),
    createdAt: Number(raw.createdAt ?? 0),
  };
}

// ── Query Hooks ───────────────────────────────────────────────────────────────

export function useBankAccounts() {
  const { actor, isFetching } = useActor();
  return useQuery<BankAccountEntry[]>({
    queryKey: ["bankAccounts"],
    queryFn: async () => {
      if (!actor) return [];
      const raw = await actorCall(actor).listBankAccounts();
      if (!Array.isArray(raw)) return [];
      return (raw as Record<string, unknown>[]).map(decodeAccount);
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 8000,
  });
}

export function useBankAccount(id: string) {
  const { actor, isFetching } = useActor();
  return useQuery<BankAccountEntry | null>({
    queryKey: ["bankAccount", id],
    queryFn: async () => {
      if (!actor || !id) return null;
      const raw = await actorCall(actor).getBankAccount(id);
      if (!raw || (Array.isArray(raw) && raw.length === 0)) return null;
      const entry = Array.isArray(raw) ? raw[0] : raw;
      return decodeAccount(entry as Record<string, unknown>);
    },
    enabled: !!actor && !isFetching && !!id,
  });
}

export function useTxMonitoring() {
  const { actor, isFetching } = useActor();
  return useQuery<TxMonitoringState>({
    queryKey: ["txMonitoring"],
    queryFn: async () => {
      if (!actor)
        return {
          flaggedCount: 0,
          totalMonitored: 0,
          lastFlaggedAt: 0,
          personalThreshold: 1000,
          businessThreshold: 10000,
          institutionalThreshold: 100000,
        };
      const raw = (await actorCall(actor).getTxMonitoringState()) as Record<
        string,
        unknown
      >;
      return {
        flaggedCount: Number(raw?.flaggedCount ?? 0),
        totalMonitored: Number(raw?.totalMonitored ?? 0),
        lastFlaggedAt: Number(raw?.lastFlaggedAt ?? 0),
        personalThreshold: Number(raw?.personalThreshold ?? 1000),
        businessThreshold: Number(raw?.businessThreshold ?? 10000),
        institutionalThreshold: Number(raw?.institutionalThreshold ?? 100000),
      };
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 10000,
  });
}

export function useFlaggedTxs() {
  const { actor, isFetching } = useActor();
  return useQuery<BankTxEntry[]>({
    queryKey: ["flaggedTxs"],
    queryFn: async () => {
      if (!actor) return [];
      const raw = await actorCall(actor).getFlaggedTransactions();
      if (!Array.isArray(raw)) return [];
      return (raw as Record<string, unknown>[]).map(decodeTx);
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 15000,
  });
}

export function useBankingSsuState() {
  const { actor, isFetching } = useActor();
  return useQuery<BankingSsuState>({
    queryKey: ["bankingSsuState"],
    queryFn: async () => {
      if (!actor)
        return {
          genesisHash: "",
          beatCount: 0,
          kuramotoR: 0,
          aegisStatus: "INITIALIZING",
        };
      const raw = (await actorCall(actor).getBankingSsuState()) as Record<
        string,
        unknown
      >;
      return {
        genesisHash: String(raw?.genesisHash ?? ""),
        beatCount: Number(raw?.beatCount ?? 0),
        kuramotoR: Number(raw?.kuramotoR ?? 0),
        aegisStatus: String(raw?.aegisStatus ?? "UNKNOWN"),
      };
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });
}

export function useBankingYield() {
  const { actor, isFetching } = useActor();
  return useQuery<BankingYield>({
    queryKey: ["bankingYield"],
    queryFn: async () => {
      if (!actor)
        return { dailyMaturityEst: 0, weeklyEst: 0, neuronGroupStatus: "" };
      const raw = (await actorCall(actor).getBankingYield()) as Record<
        string,
        unknown
      >;
      return {
        dailyMaturityEst: Number(raw?.dailyMaturityEst ?? 0),
        weeklyEst: Number(raw?.weeklyEst ?? 0),
        neuronGroupStatus: String(raw?.neuronGroupStatus ?? ""),
      };
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30000,
  });
}

export function useKycEndpoint() {
  const { actor, isFetching } = useActor();
  return useQuery<string>({
    queryKey: ["kycEndpoint"],
    queryFn: async () => {
      if (!actor) return "";
      const raw = await actorCall(actor).getKycEndpoint();
      if (Array.isArray(raw)) return String(raw[0] ?? "");
      return String(raw ?? "");
    },
    enabled: !!actor && !isFetching,
  });
}

export function useKycStatus(id: string) {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["kycStatus", id],
    queryFn: async () => {
      if (!actor || !id) return null;
      const raw = await actorCall(actor).getKycStatus(id);
      if (!raw || (Array.isArray(raw) && raw.length === 0)) return null;
      const entry = Array.isArray(raw) ? raw[0] : raw;
      const r = entry as Record<string, unknown>;
      return {
        accountId: String(r.accountId ?? ""),
        status: getKycLabel(r.status),
        apiResponse: String(r.apiResponse ?? ""),
        lastChecked: Number(r.lastChecked ?? 0),
        retryCount: Number(r.retryCount ?? 0),
      };
    },
    enabled: !!actor && !isFetching && !!id,
  });
}

// ── Mutation Hooks ────────────────────────────────────────────────────────────

export function useCreateBankAccount() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      accountId,
      name,
      role,
    }: { accountId: string; name: string; role: BankRole }) => {
      if (!actor) throw new Error("No actor");
      const roleVariant =
        role === "institutional"
          ? { institutional: null }
          : role === "business"
            ? { business: null }
            : { personal: null };
      return actorCall(actor).createBankAccount(accountId, name, roleVariant);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["bankAccounts"] }),
  });
}

export function useInitiateKyc() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (accountId: string) => {
      if (!actor) throw new Error("No actor");
      return actorCall(actor).initiateKyc(accountId);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["bankAccounts"] });
      qc.invalidateQueries({ queryKey: ["kycStatus"] });
    },
  });
}

export function useRecordTx() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (args: {
      accountId: string;
      amount: number;
      asset: string;
      direction: TxDirection;
      note: string;
    }) => {
      if (!actor) throw new Error("No actor");
      const dir = args.direction === "out" ? { out_: null } : { in_: null };
      return actorCall(actor).recordBankTx(
        args.accountId,
        args.amount,
        args.asset,
        dir,
        args.note,
      );
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["bankAccounts"] });
      qc.invalidateQueries({ queryKey: ["txMonitoring"] });
    },
  });
}

export function useExportFinCEN() {
  const { actor } = useActor();
  return useMutation({
    mutationFn: async (format: "csv" | "json") => {
      if (!actor) throw new Error("No actor");
      const result = (await actorCall(actor).exportFinCEN(format)) as string;
      const blob = new Blob([result], {
        type: format === "csv" ? "text/csv" : "application/json",
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `parallax_fincen_export_${Date.now()}.${format}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      return result;
    },
  });
}

export function useUpdateRole() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, role }: { id: string; role: BankRole }) => {
      if (!actor) throw new Error("No actor");
      const roleVariant =
        role === "institutional"
          ? { institutional: null }
          : role === "business"
            ? { business: null }
            : { personal: null };
      return actorCall(actor).updateBankAccountRole(id, roleVariant);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["bankAccounts"] }),
  });
}

export function useToggleDelegated() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      if (!actor) throw new Error("No actor");
      return actorCall(actor).toggleDelegatedSigning(id);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["bankAccounts"] }),
  });
}

export function useSetKycEndpoint() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (url: string) => {
      if (!actor) throw new Error("No actor");
      return actorCall(actor).setKycEndpoint(url);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["kycEndpoint"] }),
  });
}
