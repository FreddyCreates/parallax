import { useQuery } from "@tanstack/react-query";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  type CoreSnapshot,
  HEARTBEAT_MS,
  defaultCoreSnapshot,
} from "../models";
import { useActor } from "./useActor";

export interface TreasuryState {
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
  engineIntelligenceScore: number;
  systemCoherenceScore: number;
  totalProfitAllStreams: number;
  championPool: number;
  liveDataActive: boolean;
}

export interface CreatorReserve {
  icpReserve: number;
  btcReserve: number;
  ethReserve: number;
  mtcReserve: number;
  withdrawableIcp: number;
  totalWithdrawn: number;
  totalUsdEquivalent: number;
}

export interface ProfitStreams {
  s1: number;
  s2: number;
  s3: number;
  s4: number;
  s5: number;
  s6: number;
  s7: number;
  s8: number;
  s9: number;
  s10: number;
  s11: number;
  s12: number;
  s13: number;
  s14: number;
  s15: number;
  s16: number;
  s17: number;
  s18: number;
  s19: number;
  s20: number;
  s21: number;
  s22: number;
  total: number;
}

export interface OrganismData {
  id: number;
  name: string;
  tier: string;
  status: string;
  icpBalance: number;
  btcBalance: number;
  ethBalance: number;
  mtcBalance: number;
  totalEarned: number;
  franchiseCutPaid: number;
  yieldMultiplier: number;
  creatorSignature: string;
  doctrineHash: number;
}

export interface ThoughtEntry {
  beat: number;
  timestamp: number;
  ingested: string;
  computed: string;
  decided: string;
  executed: string;
  yieldCaptured: number;
  watching: string;
}

export interface IntelEntry {
  timestamp: number;
  category: string;
  title: string;
  content: string;
  actionable: boolean;
  yieldImpact: number;
}

export interface BrainSignals {
  btcSignal: number;
  ethSignal: number;
  icpSignal: number;
  mtcVelocitySignal: number;
  systemCoherenceScore: number;
  engineIntelligenceScore: number;
}

export interface MtcState {
  genesisSupply: number;
  circulating: number;
  burned: number;
  creatorHolding: number;
  hardFloor: number;
  price: number;
  spreadRate: number;
  burnRate: number;
  yieldRate: number;
  tierPriceLW: number;
  tierPriceMW: number;
  tierPriceHW: number;
}

export interface AuditEntry {
  id: number;
  timestamp: number;
  beat: number;
  eventType: string;
  description: string;
  amount: number;
  currency: string;
  fromEntity: string;
  toEntity: string;
  doctrineHash: number;
}

export interface PatentEntry {
  id: number;
  timestamp: number;
  mechanismName: string;
  description: string;
  creatorAttribution: string;
  doctrineHash: number;
}

export interface ExternalFeeds {
  btcPrice: number;
  btcMempoolFeeRate: number;
  btcNetworkCongestion: number;
  ethPrice: number;
  ethLidoRate: number;
  ethRocketPoolRate: number;
  ethGasPrice: number;
  icpPrice: number;
  slot5: { name: string; active: boolean; price: number };
  slot6: { name: string; active: boolean; price: number };
  slot7: { name: string; active: boolean; price: number };
  liveDataActive: boolean;
  ethLidoLive: boolean;
  lastFetchBeat: number;
}

export interface Attribution {
  name: string;
  title: string;
  jurisdiction: string;
  year: number;
  doctrineHash: number;
  genesisLocked: boolean;
  genesisTimestamp: number;
}

export interface CognitiveState {
  spectralRadius: number;
  hebbianKappa: number;
  frobeniusNorm: number;
  jasmineDrift: number;
  lyapunovV: number;
  lyapunovVPrev: number;
  globalDrift: number;
  shannonH: number;
  integratedInfoPhi: number;
  kuramotoR: number;
  coherenceC: number;
  freeEnergy: number;
  omnisPrecondition: boolean;
  omnisFiredCount: number;
  cognitiveBeats: number;
  etaLearningRate: number;
  targetCoherence: number;
  hzActivations: number[];
  hebbianW: number[];
}

export interface SubOrganismRecord {
  active: boolean;
  urgency: number;
  eventCount: number;
  lastEventBeat: number;
  snapshotBeat?: number; // ARES only
}

export interface SubOrganisms {
  ares: SubOrganismRecord & {
    reversalCount: number;
    lastReversalBeat: number;
    snapshotBeat: number;
  };
  gaia: SubOrganismRecord & { repairCount: number; lastRepairBeat: number };
  vulcan: SubOrganismRecord & {
    hardeningCount: number;
    lastActiveBeat: number;
  };
  sentinel: SubOrganismRecord & { alertCount: number; lastAlertBeat: number };
}

export interface QuantumState {
  batteryBalance: number;
  batteryLocked: boolean;
  chargeRate: number;
  presenceActive: boolean;
  presenceExpiresBeat: number;
  dischargeCount: number;
  mtcCoherenceIndex: number;
  stream21Total: number;
  stream22Total: number;
}

export interface ParallaxData {
  treasury: TreasuryState;
  creator: CreatorReserve;
  streams: ProfitStreams;
  organisms: OrganismData[];
  thoughts: ThoughtEntry[];
  intel: IntelEntry[];
  signals: BrainSignals;
  mtc: MtcState;
  audit: AuditEntry[];
  patents: PatentEntry[];
  feeds: ExternalFeeds;
  attribution: Attribution;
  cognitive: CognitiveState;
  subOrganisms: SubOrganisms;
  quantum: QuantumState;
}

function toNum(v: unknown): number {
  if (typeof v === "bigint") return Number(v);
  if (typeof v === "number") return v;
  return 0;
}

function mapOrganism(o: Record<string, unknown>): OrganismData {
  return {
    id: toNum(o.id),
    name: String(o.name ?? ""),
    tier: String(o.tier ?? ""),
    status: String(o.status ?? ""),
    icpBalance: toNum(o.icpBalance),
    btcBalance: toNum(o.btcBalance),
    ethBalance: toNum(o.ethBalance),
    mtcBalance: toNum(o.mtcBalance),
    totalEarned: toNum(o.totalEarned),
    franchiseCutPaid: toNum(o.franchiseCutPaid),
    yieldMultiplier: toNum(o.yieldMultiplier),
    creatorSignature: String(o.creatorSignature ?? ""),
    doctrineHash: toNum(o.doctrineHash),
  };
}

function mapThought(t: Record<string, unknown>): ThoughtEntry {
  return {
    beat: toNum(t.beat),
    timestamp: toNum(t.timestamp),
    ingested: String(t.ingested ?? ""),
    computed: String(t.computed ?? ""),
    decided: String(t.decided ?? ""),
    executed: String(t.executed ?? ""),
    yieldCaptured: toNum(t.yieldCaptured),
    watching: String(t.watching ?? ""),
  };
}

function defaultCognitive(): CognitiveState {
  return {
    spectralRadius: 0,
    hebbianKappa: 0,
    frobeniusNorm: 0,
    jasmineDrift: 0,
    lyapunovV: 0,
    lyapunovVPrev: 0,
    globalDrift: 0,
    shannonH: 0,
    integratedInfoPhi: 0,
    kuramotoR: 0,
    coherenceC: 0,
    freeEnergy: 0,
    omnisPrecondition: false,
    omnisFiredCount: 0,
    cognitiveBeats: 0,
    etaLearningRate: 0,
    targetCoherence: 0,
    hzActivations: Array(12).fill(0),
    hebbianW: Array(144).fill(0),
  };
}

function defaultSubOrganisms(): SubOrganisms {
  return {
    ares: {
      active: false,
      urgency: 0,
      eventCount: 0,
      lastEventBeat: 0,
      reversalCount: 0,
      lastReversalBeat: 0,
      snapshotBeat: 0,
    },
    gaia: {
      active: false,
      urgency: 0,
      eventCount: 0,
      lastEventBeat: 0,
      repairCount: 0,
      lastRepairBeat: 0,
    },
    vulcan: {
      active: false,
      urgency: 0,
      eventCount: 0,
      lastEventBeat: 0,
      hardeningCount: 0,
      lastActiveBeat: 0,
    },
    sentinel: {
      active: false,
      urgency: 0,
      eventCount: 0,
      lastEventBeat: 0,
      alertCount: 0,
      lastAlertBeat: 0,
    },
  };
}

function defaultQuantum(): QuantumState {
  return {
    batteryBalance: 0,
    batteryLocked: true,
    chargeRate: 0,
    presenceActive: false,
    presenceExpiresBeat: 0,
    dischargeCount: 0,
    mtcCoherenceIndex: 0.01,
    stream21Total: 0,
    stream22Total: 0,
  };
}

function defaultData(): ParallaxData {
  return {
    treasury: {
      icpBalance: 10000,
      icpStaked: 8000,
      icpPrice: 8.42,
      btcBalance: 2.5,
      btcHardFloor: 0.5,
      btcPrice: 97500,
      ethBalance: 15,
      ethPrice: 3420,
      mtcCirculating: 1e9,
      mtcBurned: 0,
      mtcPrice: 0.01,
      beatCount: 0,
      engineIntelligenceScore: 1.0,
      systemCoherenceScore: 0.0,
      totalProfitAllStreams: 0,
      championPool: 0,
      liveDataActive: false,
    },
    creator: {
      icpReserve: 0,
      btcReserve: 0,
      ethReserve: 0,
      mtcReserve: 0,
      withdrawableIcp: 0,
      totalWithdrawn: 0,
      totalUsdEquivalent: 0,
    },
    streams: {
      s1: 0,
      s2: 0,
      s3: 0,
      s4: 0,
      s5: 0,
      s6: 0,
      s7: 0,
      s8: 0,
      s9: 0,
      s10: 0,
      s11: 0,
      s12: 0,
      s13: 0,
      s14: 0,
      s15: 0,
      s16: 0,
      s17: 0,
      s18: 0,
      s19: 0,
      s20: 0,
      s21: 0,
      s22: 0,
      total: 0,
    },
    organisms: [],
    thoughts: [],
    intel: [],
    signals: {
      btcSignal: 0,
      ethSignal: 0,
      icpSignal: 0,
      mtcVelocitySignal: 0,
      systemCoherenceScore: 0,
      engineIntelligenceScore: 1,
    },
    mtc: {
      genesisSupply: 1e9,
      circulating: 1e9,
      burned: 0,
      creatorHolding: 1e9,
      hardFloor: 1e6,
      price: 0.01,
      spreadRate: 0.005,
      burnRate: 0.001,
      yieldRate: 0.08,
      tierPriceLW: 100,
      tierPriceMW: 1000,
      tierPriceHW: 10000,
    },
    audit: [],
    patents: [],
    feeds: {
      btcPrice: 97500,
      btcMempoolFeeRate: 25,
      btcNetworkCongestion: 0.4,
      ethPrice: 3420,
      ethLidoRate: 0.039,
      ethRocketPoolRate: 0.041,
      ethGasPrice: 18,
      icpPrice: 8.42,
      slot5: { name: "", active: false, price: 0 },
      slot6: { name: "", active: false, price: 0 },
      slot7: { name: "", active: false, price: 0 },
      liveDataActive: false,
      ethLidoLive: false,
      lastFetchBeat: 0,
    },
    attribution: {
      name: "Alfredo Medina Hernandez",
      title: "Property Officer",
      jurisdiction: "Dallas, Texas, USA",
      year: 2026,
      doctrineHash: 0,
      genesisLocked: false,
      genesisTimestamp: 0,
    },
    cognitive: defaultCognitive(),
    subOrganisms: defaultSubOrganisms(),
    quantum: defaultQuantum(),
  };
}

export function useParallax() {
  const { actor } = useActor();
  const [data, setData] = useState<ParallaxData>(defaultData());
  const [loading, setLoading] = useState(true);
  const actorRef = useRef(actor);
  actorRef.current = actor;

  const fetchAll = useCallback(async () => {
    const a = actorRef.current as unknown as Record<
      string,
      (...args: unknown[]) => Promise<unknown>
    >;
    if (!a) return;
    try {
      const [
        treasury,
        creator,
        streams,
        organisms,
        thoughts,
        intel,
        signals,
        mtc,
        audit,
        patents,
        feeds,
        attribution,
        cognitive,
        subOrganismsRaw,
        quantumRaw,
      ] = await Promise.all([
        a.getTreasuryState?.(),
        a.getCreatorReserve?.(),
        a.getAllProfitStreams?.(),
        a.getOrganisms?.(),
        a.getThoughtLog?.(),
        a.getIntelBrief?.(),
        a.getBrainSignals?.(),
        a.getMtcState?.(),
        a.getAuditLog?.(),
        a.getPatentLog?.(),
        a.getExternalFeeds?.(),
        a.getCreatorAttribution?.(),
        a.getCognitiveState?.(),
        a.getSubOrganisms?.(),
        a.getQuantumState?.(),
      ]);

      const mapNum = (obj: Record<string, unknown>) => {
        const result: Record<string, number> = {};
        for (const [k, v] of Object.entries(obj)) result[k] = toNum(v);
        return result;
      };

      const mapCognitive = (raw: unknown): CognitiveState => {
        if (!raw || typeof raw !== "object") return defaultCognitive();
        const c = raw as Record<string, unknown>;
        return {
          spectralRadius: toNum(c.spectralRadius),
          hebbianKappa: toNum(c.hebbianKappa),
          frobeniusNorm: toNum(c.frobeniusNorm),
          jasmineDrift: toNum(c.jasmineDrift),
          lyapunovV: toNum(c.lyapunovV),
          lyapunovVPrev: toNum(c.lyapunovVPrev),
          globalDrift: toNum(c.globalDrift),
          shannonH: toNum(c.shannonH),
          integratedInfoPhi: toNum(c.integratedInfoPhi),
          kuramotoR: toNum(c.kuramotoR),
          coherenceC: toNum(c.coherenceC),
          freeEnergy: toNum(c.freeEnergy),
          omnisPrecondition: Boolean(c.omnisPrecondition),
          omnisFiredCount: toNum(c.omnisFiredCount),
          cognitiveBeats: toNum(c.cognitiveBeats),
          etaLearningRate: toNum(c.etaLearningRate),
          targetCoherence: toNum(c.targetCoherence),
          hzActivations: Array.isArray(c.hzActivations)
            ? (c.hzActivations as unknown[]).map(toNum)
            : Array(12).fill(0),
          hebbianW: Array.isArray(c.hebbianW)
            ? (c.hebbianW as unknown[]).map(toNum)
            : Array(144).fill(0),
        };
      };

      const mapSubOrganisms = (raw: unknown): SubOrganisms => {
        if (!raw || typeof raw !== "object") return defaultSubOrganisms();
        const r = raw as Record<string, unknown>;
        const mapSub = (s: unknown) => {
          const d = (s as Record<string, unknown>) ?? {};
          return {
            active: Boolean(d.active),
            urgency: toNum(d.urgency),
            eventCount: toNum(d.eventCount),
            lastEventBeat: toNum(d.lastEventBeat),
          };
        };
        return {
          ares: {
            ...mapSub(r.ares),
            reversalCount: toNum(
              (r.ares as Record<string, unknown>)?.reversalCount,
            ),
            lastReversalBeat: toNum(
              (r.ares as Record<string, unknown>)?.lastReversalBeat,
            ),
            snapshotBeat: toNum(
              (r.ares as Record<string, unknown>)?.snapshotBeat,
            ),
          },
          gaia: {
            ...mapSub(r.gaia),
            repairCount: toNum(
              (r.gaia as Record<string, unknown>)?.repairCount,
            ),
            lastRepairBeat: toNum(
              (r.gaia as Record<string, unknown>)?.lastRepairBeat,
            ),
          },
          vulcan: {
            ...mapSub(r.vulcan),
            hardeningCount: toNum(
              (r.vulcan as Record<string, unknown>)?.hardeningCount,
            ),
            lastActiveBeat: toNum(
              (r.vulcan as Record<string, unknown>)?.lastActiveBeat,
            ),
          },
          sentinel: {
            ...mapSub(r.sentinel),
            alertCount: toNum(
              (r.sentinel as Record<string, unknown>)?.alertCount,
            ),
            lastAlertBeat: toNum(
              (r.sentinel as Record<string, unknown>)?.lastAlertBeat,
            ),
          },
        };
      };

      const mapQuantum = (raw: unknown): QuantumState => {
        if (!raw || typeof raw !== "object") return defaultQuantum();
        const q = raw as Record<string, unknown>;
        return {
          batteryBalance: toNum(q.batteryBalance),
          batteryLocked: Boolean(q.batteryLocked),
          chargeRate: toNum(q.chargeRate),
          presenceActive: Boolean(q.presenceActive),
          presenceExpiresBeat: toNum(q.presenceExpiresBeat),
          dischargeCount: toNum(q.dischargeCount),
          mtcCoherenceIndex: toNum(q.mtcCoherenceIndex),
          stream21Total: toNum(q.stream21Total),
          stream22Total: toNum(q.stream22Total),
        };
      };

      // Treasury — map numbers then fix booleans
      const treasuryRaw = treasury as Record<string, unknown>;
      const treasuryMapped = mapNum(treasuryRaw) as unknown as TreasuryState;
      treasuryMapped.liveDataActive = Boolean(treasuryRaw.liveDataActive);

      // Feeds — map numbers then fix booleans
      const feedsRaw = feeds as Record<string, unknown>;
      const slotOf = (s: unknown) => {
        const sl = s as Record<string, unknown>;
        return {
          name: String(sl?.name ?? ""),
          active: Boolean(sl?.active),
          price: toNum(sl?.price),
        };
      };
      const feedsMapped: ExternalFeeds = {
        btcPrice: toNum(feedsRaw.btcPrice),
        btcMempoolFeeRate: toNum(feedsRaw.btcMempoolFeeRate),
        btcNetworkCongestion: toNum(feedsRaw.btcNetworkCongestion),
        ethPrice: toNum(feedsRaw.ethPrice),
        ethLidoRate: toNum(feedsRaw.ethLidoRate),
        ethRocketPoolRate: toNum(feedsRaw.ethRocketPoolRate),
        ethGasPrice: toNum(feedsRaw.ethGasPrice),
        icpPrice: toNum(feedsRaw.icpPrice),
        slot5: slotOf(feedsRaw.slot5),
        slot6: slotOf(feedsRaw.slot6),
        slot7: slotOf(feedsRaw.slot7),
        liveDataActive: Boolean(feedsRaw.liveDataActive),
        ethLidoLive: Boolean(feedsRaw.ethLidoLive),
        lastFetchBeat: toNum(feedsRaw.lastFetchBeat),
      };

      // Streams — include s21 and s22
      const streamsRaw = streams as Record<string, unknown>;
      const streamsMapped: ProfitStreams = {
        s1: toNum(streamsRaw.s1),
        s2: toNum(streamsRaw.s2),
        s3: toNum(streamsRaw.s3),
        s4: toNum(streamsRaw.s4),
        s5: toNum(streamsRaw.s5),
        s6: toNum(streamsRaw.s6),
        s7: toNum(streamsRaw.s7),
        s8: toNum(streamsRaw.s8),
        s9: toNum(streamsRaw.s9),
        s10: toNum(streamsRaw.s10),
        s11: toNum(streamsRaw.s11),
        s12: toNum(streamsRaw.s12),
        s13: toNum(streamsRaw.s13),
        s14: toNum(streamsRaw.s14),
        s15: toNum(streamsRaw.s15),
        s16: toNum(streamsRaw.s16),
        s17: toNum(streamsRaw.s17),
        s18: toNum(streamsRaw.s18),
        s19: toNum(streamsRaw.s19),
        s20: toNum(streamsRaw.s20),
        s21: toNum(streamsRaw.s21),
        s22: toNum(streamsRaw.s22),
        total: toNum(streamsRaw.total),
      };

      setData({
        treasury: treasuryMapped,
        creator: mapNum(
          creator as Record<string, unknown>,
        ) as unknown as CreatorReserve,
        streams: streamsMapped,
        organisms: ((organisms as unknown[]) ?? []).map((o) =>
          mapOrganism(o as Record<string, unknown>),
        ),
        thoughts: ((thoughts as unknown[]) ?? []).map((t) =>
          mapThought(t as Record<string, unknown>),
        ),
        intel: ((intel as unknown[]) ?? []).map((i) => {
          const ie = i as Record<string, unknown>;
          return {
            timestamp: toNum(ie.timestamp),
            category: String(ie.category),
            title: String(ie.title),
            content: String(ie.content),
            actionable: Boolean(ie.actionable),
            yieldImpact: toNum(ie.yieldImpact),
          };
        }),
        signals: mapNum(
          signals as Record<string, unknown>,
        ) as unknown as BrainSignals,
        mtc: mapNum(mtc as Record<string, unknown>) as unknown as MtcState,
        audit: ((audit as unknown[]) ?? []).map((ae) => {
          const e = ae as Record<string, unknown>;
          return {
            id: toNum(e.id),
            timestamp: toNum(e.timestamp),
            beat: toNum(e.beat),
            eventType: String(e.eventType),
            description: String(e.description),
            amount: toNum(e.amount),
            currency: String(e.currency),
            fromEntity: String(e.fromEntity),
            toEntity: String(e.toEntity),
            doctrineHash: toNum(e.doctrineHash),
          };
        }),
        patents: ((patents as unknown[]) ?? []).map((pe) => {
          const p = pe as Record<string, unknown>;
          return {
            id: toNum(p.id),
            timestamp: toNum(p.timestamp),
            mechanismName: String(p.mechanismName),
            description: String(p.description),
            creatorAttribution: String(p.creatorAttribution),
            doctrineHash: toNum(p.doctrineHash),
          };
        }),
        feeds: feedsMapped,
        attribution: (() => {
          const at = attribution as Record<string, unknown>;
          return {
            name: String(at.name),
            title: String(at.title),
            jurisdiction: String(at.jurisdiction),
            year: toNum(at.year),
            doctrineHash: toNum(at.doctrineHash),
            genesisLocked: Boolean(at.genesisLocked),
            genesisTimestamp: toNum(at.genesisTimestamp),
          };
        })(),
        cognitive: mapCognitive(cognitive),
        subOrganisms: mapSubOrganisms(subOrganismsRaw),
        quantum: mapQuantum(quantumRaw),
      });
    } catch (e) {
      console.error("Parallax fetch error:", e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();
    const interval = setInterval(fetchAll, 3000);
    return () => clearInterval(interval);
  }, [fetchAll]);

  const callWrite = useCallback(
    async (fn: string, ...args: unknown[]) => {
      const a = actorRef.current as unknown as Record<
        string,
        (...args: unknown[]) => Promise<unknown>
      >;
      if (!a?.[fn]) return false;
      const result = await a[fn](...args);
      await fetchAll();
      return result;
    },
    [fetchAll],
  );

  return { data, loading, refetch: fetchAll, callWrite };
}

// ─── useCoreSnapshot ─────────────────────────────────────────────────────────
// Polls getCoreSnapshot() every HEARTBEAT_MS (873ms = φ-ladder cardiac period).
// getCoreSnapshot() is the single query that returns the full organism vocabulary:
//   core vitals, signals, events, 98 nodes, engines, treasury entries, proof chain,
//   and all active coupling states — in one call, one beat.
//
// The frontend is a sensory surface. It receives the organism's state every beat.
// It does not fetch when it wants — it receives at the organism's rhythm.
export function useCoreSnapshot() {
  const { actor, isFetching } = useActor();

  return useQuery<CoreSnapshot>({
    queryKey: ["coreSnapshot"],
    queryFn: async (): Promise<CoreSnapshot> => {
      if (!actor) return defaultCoreSnapshot();

      // getCoreSnapshot no longer exists — query individual fields instead
      const [kuramotoR, beatCount] = await Promise.all([
        actor.getKuramotoR(),
        actor.getBeatCount(),
      ]);
      return {
        globalR: kuramotoR,
        beat: beatCount,
        omnisFired: false,
      };
    },
    enabled: !!actor && !isFetching,
    // HEARTBEAT_MS = 873 — φ-ladder cardiac period
    // The organism beats. The frontend listens at the same rhythm.
    refetchInterval: HEARTBEAT_MS, // 873ms — F(7+6)/phi-ladder timing
    staleTime: HEARTBEAT_MS, // data is fresh for exactly one heartbeat
    placeholderData: defaultCoreSnapshot,
  });
}
