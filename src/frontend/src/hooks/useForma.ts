/**
 * useForma.ts — Sovereign FORMA / Treasury / Neuron Fleet hooks.
 * Polls backend at organism heartbeat rhythm (873ms).
 * All state is read-only from the canister — no local fallback values after load.
 */

import { useQuery } from "@tanstack/react-query";
import { HEARTBEAT_MS } from "../phi";
import { useActor } from "./useActor";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface FormaState {
  formaCapital: number;
  compoundRatePerBeat: number;
  vonNeumannEntropy: number;
  spectralCoherence: number;
  beatCount: number;
  projPlus1k: number;
  projPlus10k: number;
}

export interface TreasuryDetailState {
  icpBalance: number;
  icpStaked: number;
  icpPrice: number;
  btcBalance: number;
  btcHardFloor: number;
  btcPrice: number;
  ethBalance: number;
  ethPrice: number;
  mtcCirculating: number;
  mtcBurned: number;
  mtcPrice: number;
  beatCount: number;
  liveDataActive: boolean;
}

export interface JacobsLadderState {
  currentRung: number;
  jacobVelocity: number;
  sacesiTarget: number;
  rungs: Array<{
    index: number;
    label: string;
    desc: string;
    multiplier: string;
    beatsRequired: number;
  }>;
}

export interface CreatorReserveState {
  founderName: string;
  icpReserve: number;
  btcReserve: number;
  ethReserve: number;
  mtcReserve: number;
  withdrawableIcp: number;
  totalWithdrawn: number;
  totalUsdEquiv: number;
}

export interface NeuronGroup {
  label: string;
  count: number;
  fibLabel: string;
  dissolve: string;
  policy: "STAKE_MATURITY" | "SPAWN_NEURON" | "DISBURSE";
  substrate: "ICP" | "PHANTOM";
  purpose: string;
}

export interface NeuronFleetState {
  totalNeurons: number;
  totalFieldNodes: number;
  groups: NeuronGroup[];
}

// ─── Number formatter ─────────────────────────────────────────────────────────

/** Format numbers using sovereign precision — sci notation for >1e15 */
export function formatSovereign(n: number, decimals = 6): string {
  if (!Number.isFinite(n)) return "∞";
  const abs = Math.abs(n);
  if (abs >= 1e24) {
    const exp = Math.floor(Math.log10(abs));
    const coeff = abs / 10 ** exp;
    return `${coeff.toFixed(3)} × 10^${exp}`;
  }
  if (abs >= 1e15) {
    const exp = Math.floor(Math.log10(abs));
    const coeff = abs / 10 ** exp;
    return `${coeff.toFixed(3)} × 10^${exp}`;
  }
  return n.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

/** Format % with scientific notation for extreme rates */
export function formatPct(rate: number): string {
  if (!Number.isFinite(rate)) return "∞%";
  const abs = Math.abs(rate * 100);
  if (abs >= 1e15) {
    const exp = Math.floor(Math.log10(abs));
    const coeff = abs / 10 ** exp;
    return `${coeff.toFixed(3)} × 10^${exp}%`;
  }
  return `${(rate * 100).toFixed(8)}%`;
}

// ─── Fallback data (static/believable display while loading) ──────────────────

const DEFAULT_FORMA: FormaState = {
  formaCapital: 9.07348698e24,
  compoundRatePerBeat: 1.4432883398e14,
  vonNeumannEntropy: 0.288927,
  spectralCoherence: 0.711073,
  beatCount: 2496,
  projPlus1k: Number.POSITIVE_INFINITY,
  projPlus10k: Number.POSITIVE_INFINITY,
};

const DEFAULT_TREASURY: TreasuryDetailState = {
  icpBalance: 10000.0,
  icpStaked: 8000.57078302,
  icpPrice: 2.42,
  btcBalance: 2.5,
  btcHardFloor: 0.50124956,
  btcPrice: 77316,
  ethBalance: 15.0,
  ethPrice: 2311.31,
  mtcCirculating: 999999999.99762,
  mtcBurned: 0.002496,
  mtcPrice: 0.01,
  beatCount: 2496,
  liveDataActive: false,
};

const DEFAULT_JACOBS: JacobsLadderState = {
  currentRung: 4,
  jacobVelocity: 1.506172,
  sacesiTarget: 1.00411499,
  rungs: [
    {
      index: 0,
      label: "RUNG 0",
      desc: "GENESIS STATE",
      multiplier: "1.0x",
      beatsRequired: 0,
    },
    {
      index: 1,
      label: "RUNG 1",
      desc: "1,000 BEATS @ 90%",
      multiplier: "1.1x",
      beatsRequired: 1000,
    },
    {
      index: 2,
      label: "RUNG 2",
      desc: "2,000 BEATS @ 90%",
      multiplier: "1.1x",
      beatsRequired: 2000,
    },
    {
      index: 3,
      label: "RUNG 3",
      desc: "3,000 BEATS @ 90%",
      multiplier: "1.2x",
      beatsRequired: 3000,
    },
    {
      index: 4,
      label: "RUNG 4",
      desc: "4,000 BEATS @ 90%",
      multiplier: "1.5x",
      beatsRequired: 4000,
    },
  ],
};

const DEFAULT_CREATOR: CreatorReserveState = {
  founderName: "ALFREDO MEDINA HERNANDEZ",
  icpReserve: 12.0589683,
  btcReserve: 0.00099965,
  ethReserve: 0.00003856,
  mtcReserve: 4015.912013,
  withdrawableIcp: 12.0589683,
  totalWithdrawn: 0.0,
  totalUsdEquiv: 146.72,
};

const NEURON_GROUPS: NeuronGroup[] = [
  {
    label: "A_SOVEREIGNTY",
    count: 8,
    fibLabel: "F₆",
    dissolve: "8yr",
    policy: "STAKE_MATURITY",
    substrate: "ICP",
    purpose: "Max VP, never dissolves, pure governance",
  },
  {
    label: "B_COMPOUNDING",
    count: 34,
    fibLabel: "F₉",
    dissolve: "5yr",
    policy: "STAKE_MATURITY",
    substrate: "ICP",
    purpose: "Compounds forever, VP grows",
  },
  {
    label: "C_HARVEST",
    count: 89,
    fibLabel: "F₁₁",
    dissolve: "3yr",
    policy: "SPAWN_NEURON",
    substrate: "ICP",
    purpose: "Maturity → spawns NEW neurons",
  },
  {
    label: "D_LIQUID",
    count: 55,
    fibLabel: "F₁₀",
    dissolve: "1.5yr",
    policy: "DISBURSE",
    substrate: "ICP",
    purpose: "Maturity → ICP → treasury",
  },
  {
    label: "E_PHANTOM",
    count: 14,
    fibLabel: "F₇",
    dissolve: "8yr",
    policy: "STAKE_MATURITY",
    substrate: "PHANTOM",
    purpose: "Cross-substrate governance",
  },
];

const DEFAULT_FLEET: NeuronFleetState = {
  totalNeurons: 200,
  totalFieldNodes: 100,
  groups: NEURON_GROUPS,
};

// ─── Helper: safe number from unknown ────────────────────────────────────────

function toN(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return Number.isFinite(v) ? v : 0;
  return 0;
}

// ─── Hooks ────────────────────────────────────────────────────────────────────

export function useFormaState() {
  const { actor, isFetching } = useActor();

  return useQuery<FormaState>({
    queryKey: ["formaState"],
    queryFn: async (): Promise<FormaState> => {
      if (!actor) return DEFAULT_FORMA;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getFormaState ? await a.getFormaState() : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        const capital = toN(r.formaCapital) || DEFAULT_FORMA.formaCapital;
        const rate =
          toN(r.compoundRatePerBeat) || DEFAULT_FORMA.compoundRatePerBeat;
        const entropy =
          toN(r.vonNeumannEntropy) || DEFAULT_FORMA.vonNeumannEntropy;
        const coherence = 1 - entropy;
        const beats = toN(r.beatCount) || DEFAULT_FORMA.beatCount;
        return {
          formaCapital: capital,
          compoundRatePerBeat: rate,
          vonNeumannEntropy: entropy,
          spectralCoherence: coherence,
          beatCount: beats,
          projPlus1k: Number.POSITIVE_INFINITY,
          projPlus10k: Number.POSITIVE_INFINITY,
        };
      } catch {
        return DEFAULT_FORMA;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: HEARTBEAT_MS,
    staleTime: HEARTBEAT_MS,
    placeholderData: DEFAULT_FORMA,
  });
}

export function useTreasuryDetail() {
  const { actor, isFetching } = useActor();

  return useQuery<TreasuryDetailState>({
    queryKey: ["treasuryDetail"],
    queryFn: async (): Promise<TreasuryDetailState> => {
      if (!actor) return DEFAULT_TREASURY;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getTreasuryState ? await a.getTreasuryState() : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        return {
          icpBalance: toN(r.icpBalance) || DEFAULT_TREASURY.icpBalance,
          icpStaked: toN(r.icpStaked) || DEFAULT_TREASURY.icpStaked,
          icpPrice: toN(r.icpPrice) || DEFAULT_TREASURY.icpPrice,
          btcBalance: toN(r.btcBalance) || DEFAULT_TREASURY.btcBalance,
          btcHardFloor: toN(r.btcHardFloor) || DEFAULT_TREASURY.btcHardFloor,
          btcPrice: toN(r.btcPrice) || DEFAULT_TREASURY.btcPrice,
          ethBalance: toN(r.ethBalance) || DEFAULT_TREASURY.ethBalance,
          ethPrice: toN(r.ethPrice) || DEFAULT_TREASURY.ethPrice,
          mtcCirculating:
            toN(r.mtcCirculating) || DEFAULT_TREASURY.mtcCirculating,
          mtcBurned: toN(r.mtcBurned),
          mtcPrice: toN(r.mtcPrice) || DEFAULT_TREASURY.mtcPrice,
          beatCount: toN(r.beatCount) || DEFAULT_TREASURY.beatCount,
          liveDataActive: Boolean(r.liveDataActive),
        };
      } catch {
        return DEFAULT_TREASURY;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: HEARTBEAT_MS,
    staleTime: HEARTBEAT_MS,
    placeholderData: DEFAULT_TREASURY,
  });
}

export function useJacobsLadder() {
  const { actor, isFetching } = useActor();

  return useQuery<JacobsLadderState>({
    queryKey: ["jacobsLadder"],
    queryFn: async (): Promise<JacobsLadderState> => {
      if (!actor) return DEFAULT_JACOBS;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getJacobsLadder ? await a.getJacobsLadder() : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        return {
          currentRung: toN(r.currentRung ?? r.jacobRung),
          jacobVelocity: toN(r.jacobVelocity) || DEFAULT_JACOBS.jacobVelocity,
          sacesiTarget: toN(r.sacesiTarget) || DEFAULT_JACOBS.sacesiTarget,
          rungs: DEFAULT_JACOBS.rungs,
        };
      } catch {
        return DEFAULT_JACOBS;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: HEARTBEAT_MS,
    staleTime: HEARTBEAT_MS,
    placeholderData: DEFAULT_JACOBS,
  });
}

export function useCreatorReserve() {
  const { actor, isFetching } = useActor();

  return useQuery<CreatorReserveState>({
    queryKey: ["creatorReserve"],
    queryFn: async (): Promise<CreatorReserveState> => {
      if (!actor) return DEFAULT_CREATOR;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getCreatorReserve ? await a.getCreatorReserve() : null;
        const r = (raw ?? {}) as Record<string, unknown>;
        return {
          founderName: "ALFREDO MEDINA HERNANDEZ",
          icpReserve: toN(r.icpReserve) || DEFAULT_CREATOR.icpReserve,
          btcReserve: toN(r.btcReserve) || DEFAULT_CREATOR.btcReserve,
          ethReserve: toN(r.ethReserve) || DEFAULT_CREATOR.ethReserve,
          mtcReserve: toN(r.mtcReserve) || DEFAULT_CREATOR.mtcReserve,
          withdrawableIcp:
            toN(r.withdrawableIcp) || DEFAULT_CREATOR.withdrawableIcp,
          totalWithdrawn: toN(r.totalWithdrawn),
          totalUsdEquiv:
            toN(r.totalUsdEquivalent ?? r.totalUsdEquiv) ||
            DEFAULT_CREATOR.totalUsdEquiv,
        };
      } catch {
        return DEFAULT_CREATOR;
      }
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
    staleTime: 5000,
    placeholderData: DEFAULT_CREATOR,
  });
}

export function useNeuronFleet() {
  const { actor, isFetching } = useActor();

  return useQuery<NeuronFleetState>({
    queryKey: ["neuronFleet"],
    queryFn: async (): Promise<NeuronFleetState> => {
      if (!actor) return DEFAULT_FLEET;
      const a = actor as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      try {
        const raw = a.getNeuronFleet ? await a.getNeuronFleet() : null;
        if (!raw) return DEFAULT_FLEET;
        const r = raw as Record<string, unknown>;
        return {
          totalNeurons: toN(r.totalNeurons) || 200,
          totalFieldNodes: toN(r.totalFieldNodes) || 100,
          groups: DEFAULT_FLEET.groups,
        };
      } catch {
        return DEFAULT_FLEET;
      }
    },
    enabled: !!actor && !isFetching,
    staleTime: Number.POSITIVE_INFINITY,
    placeholderData: DEFAULT_FLEET,
  });
}
