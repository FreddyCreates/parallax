import { useCallback, useEffect, useRef, useState } from "react";
import {
  type Candle,
  type CandleTimeframe,
  type DepthBook,
  type SignalAlert,
  type Stats24h,
  WelfordStream,
  bollingerBands,
  classifyRegime,
  computeArbitrageSpread,
  computeClearingHealth,
  computeSettlementVelocity,
  ema,
  formaProject,
  generateAlerts,
  generateDepthBook,
  get24hStats,
  getCandles,
  jacobsVelocity,
  kuramotoOrderParam,
  pushPricePoint,
  pushTokenPricePoint,
  rateOfChange,
  signalStrength,
  spectralCoherence,
  tokenVelocity,
  vaelThreat,
  vonNeumannEntropy,
} from "../lib/intelligenceEngine";
import { useActor } from "./useActor";

// ── Types ───────────────────────────────────────────────────────────────────────
export interface FullState {
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

export interface MarketData {
  btcPrice: number;
  ethPrice: number;
  ema21btc: number;
  ema200btc: number;
  regime: string;
}

export interface TokenBalances {
  mth: bigint;
  mrc: bigint;
  gtk: bigint;
  cvt: bigint;
  vct: bigint;
  knt: bigint;
  sbt: bigint;
  hbt: bigint;
  drt: bigint;
  rst: bigint;
  omt: bigint;
  lgt: bigint;
}

export interface ExternalFeeds {
  btcPrice: number;
  btcMempoolFeeRate: number;
  btcNetworkCongestion: number;
  ethPrice: number;
  ethLidoRate: number;
  ethRocketPoolRate: number;
  ethGasPrice: number;
  ethLidoLive: boolean;
  icpPrice: number;
  liveDataActive: boolean;
  lastFetchBeat: number;
  slot5: { name: string; active: boolean; price: number };
  slot6: { name: string; active: boolean; price: number };
  slot7: { name: string; active: boolean; price: number };
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

export interface QuantumBatteryState {
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

export interface SovereignSignals {
  fearLevel: number;
  courageScore: number;
  groundedScore: number;
  missionLockActive: boolean;
  missionPersistenceScore: number;
  surrenderFloor: number;
  permanentCoherenceFloor: number;
  streakMultiplier: number;
  animalEngineScore: number;
  identityScore: number;
}

export interface SettlementEvent {
  beat: bigint;
  tokenCode: string;
  amount: bigint;
  sType: string;
  formaValue: number;
  coherence: number;
  rate: number;
}

export interface SettlementStats {
  totalSettlements: bigint;
  totalVelocity: bigint;
  totalFormaCleared: number;
  profitRouted: number;
}

export interface TokenExchangeRates {
  codes: string[];
  rates: number[];
  icp: number[];
  clrRes: number[];
}

export interface ClearingReserves {
  gtk: number;
  mrc: number;
  cvt: number;
  vct: number;
  knt: number;
  sbt: number;
  hbt: number;
  drt: number;
  rst: number;
  omt: number;
  lgt: number;
  mth: number;
  mtc: number;
  total: number;
  profitRouted: number;
}

export interface TransferRecord {
  beat: bigint;
  tokenCode: string;
  amount: bigint;
  toAddress: string;
  formaValue: number;
}

export interface IntelligenceEngineResult {
  fullState: FullState | null;
  marketData: MarketData | null;
  tokenBalances: TokenBalances | null;
  feeds: ExternalFeeds | null;
  mtcState: MtcState | null;
  profitStreams: ProfitStreams | null;
  treasuryState: TreasuryState | null;
  creatorReserve: CreatorReserve | null;
  quantumBattery: QuantumBatteryState | null;
  sovereignSignals: SovereignSignals | null;
  // Settlement / Clearing
  settlementFeed: SettlementEvent[];
  settlementStats: SettlementStats | null;
  tokenExchangeRates: TokenExchangeRates | null;
  clearingReserves: ClearingReserves | null;
  settlementVelocity: number;
  clearingHealth: number;
  arbitrageSpread: number;
  // Derived
  regime: "BULL" | "BEAR" | "TRANSITION";
  btcEma21: number;
  btcEma200: number;
  btcBollinger: {
    upper: number;
    middle: number;
    lower: number;
    bandwidth: number;
  };
  btcZscore: number;
  btcMomentum: number;
  ethMomentum: number;
  kuramotoR: number;
  formaProjVelocity: number;
  entropyScore: number;
  vaelThreat: number;
  jacobsVelocity: number;
  signalScore: number;
  tokenVelocityScore: number;
  vaelCombinedField: number;
  veritasTruth: number;
  emergenceApex: number;
  consequenceComposite: number;
  activeAlerts: SignalAlert[];
  loading: boolean;
  lastBeat: number;
  pollCount: number;
  // OHLCV / Depth
  candles: Candle[];
  candleTimeframe: CandleTimeframe;
  setCandleTimeframe: (tf: CandleTimeframe) => void;
  stats24h: Stats24h;
  depthBook: DepthBook;
  auditTrades: AuditTrade[];
}

export interface AuditTrade {
  beat: number;
  side: "BUY" | "SELL";
  amount: string;
  price: number;
  timestamp: number;
  status: "FILLED";
}

const MAX_HISTORY = 200;

export function useIntelligenceEngine(): IntelligenceEngineResult {
  const { actor } = useActor();

  const [fullState, setFullState] = useState<FullState | null>(null);
  const [marketData, setMarketData] = useState<MarketData | null>(null);
  const [tokenBalances, setTokenBalances] = useState<TokenBalances | null>(
    null,
  );
  const [feeds, setFeeds] = useState<ExternalFeeds | null>(null);
  const [mtcState, setMtcState] = useState<MtcState | null>(null);
  const [profitStreams, setProfitStreams] = useState<ProfitStreams | null>(
    null,
  );
  const [treasuryState, setTreasuryState] = useState<TreasuryState | null>(
    null,
  );
  const [creatorReserve, setCreatorReserve] = useState<CreatorReserve | null>(
    null,
  );
  const [quantumBattery, setQuantumBattery] =
    useState<QuantumBatteryState | null>(null);
  const [sovereignSignals, setSovereignSignals] =
    useState<SovereignSignals | null>(null);

  // Settlement / Clearing state
  const [settlementFeed, setSettlementFeed] = useState<SettlementEvent[]>([]);
  const [settlementStats, setSettlementStats] =
    useState<SettlementStats | null>(null);
  const [tokenExchangeRates, setTokenExchangeRates] =
    useState<TokenExchangeRates | null>(null);
  const [clearingReserves, setClearingReserves] =
    useState<ClearingReserves | null>(null);
  const [settlementVelocity, setSettlementVelocity] = useState(0);
  const [clearingHealth, setClearingHealth] = useState(1);
  const [arbitrageSpread, setArbitrageSpread] = useState(0);

  const [loading, setLoading] = useState(true);
  const [pollCount, setPollCount] = useState(0);

  const [regime, setRegime] = useState<"BULL" | "BEAR" | "TRANSITION">(
    "TRANSITION",
  );
  const [btcEma21, setBtcEma21] = useState(0);
  const [btcEma200, setBtcEma200] = useState(0);
  const [btcBollinger, setBtcBollinger] = useState({
    upper: 0,
    middle: 0,
    lower: 0,
    bandwidth: 0,
  });
  const [btcZscore, setBtcZscore] = useState(0);
  const [btcMomentum, setBtcMomentum] = useState(0);
  const [ethMomentum, setEthMomentum] = useState(0);
  const [kuramotoR, setKuramotoR] = useState(0);
  const [formaProjVelocity, setFormaProjVelocity] = useState(0);
  const [entropyScore, setEntropyScore] = useState(0);
  const [vaelThreatScore, setVaelThreatScore] = useState(0);
  const [jacobsVel, setJacobsVel] = useState(1.0);
  const [signalScore, setSignalScore] = useState(0);
  const [tokenVelocityScore, setTokenVelocityScore] = useState(0);
  const [vaelCombinedField, setVaelCombinedField] = useState(0);
  const [veritasTruth, setVeritasTruth] = useState(0);
  const [emergenceApex, setEmergenceApex] = useState(0);
  const [consequenceComposite, setConsequenceComposite] = useState(0);
  const [activeAlerts, setActiveAlerts] = useState<SignalAlert[]>([]);

  // OHLCV / Depth state
  const [candles, setCandles] = useState<Candle[]>([]);
  const [candleTimeframe, setCandleTimeframe] =
    useState<CandleTimeframe>("10B");
  const [stats24h, setStats24h] = useState<Stats24h>({
    high: 0,
    low: 0,
    open: 0,
    close: 0,
    change: 0,
    changePct: 0,
    volume: 0,
  });
  const [depthBook, setDepthBook] = useState<DepthBook>({
    bids: [],
    asks: [],
    mid: 0,
    spread: 0,
    spreadPct: 0,
  });
  const [auditTrades, setAuditTrades] = useState<AuditTrade[]>([]);

  const btcPricesRef = useRef<number[]>([]);
  const ethPricesRef = useRef<number[]>([]);
  const formaHistRef = useRef<number[]>([]);
  const shellActHistRef = useRef<number[][]>([]);
  const regimeRef = useRef<string>("");
  const coherenceRef = useRef<number>(0);
  const welfordBtcRef = useRef<WelfordStream>(new WelfordStream());
  const entropyRef = useRef<number>(0);
  const candleTimeframeRef = useRef<CandleTimeframe>("10B");
  const sovereignSignalsRef = useRef<SovereignSignals | null>(null);

  // Keep timeframe ref in sync
  useEffect(() => {
    candleTimeframeRef.current = candleTimeframe;
  }, [candleTimeframe]);

  const pushHistory = useCallback(
    (ref: React.MutableRefObject<number[]>, val: number) => {
      ref.current.push(val);
      if (ref.current.length > MAX_HISTORY) ref.current.shift();
    },
    [],
  );

  // Main 3s poll — core state
  useEffect(() => {
    if (!actor) return;

    let cancelled = false;

    const poll = async () => {
      try {
        const [
          fs,
          md,
          tb,
          fe,
          ms,
          ps,
          ts,
          cr,
          qs,
          neuro,
          al,
          vaelRaw,
          eaRaw,
          ccRaw,
          sovRaw,
          settleFeed,
          tokenRates,
        ] = await Promise.all([
          (actor as any).px_getFullState().catch(() => null),
          (actor as any).px_getMarketData().catch(() => null),
          (actor as any).px_getTokenBalances().catch(() => null),
          (actor as any).getExternalFeeds().catch(() => null),
          (actor as any).getMtcState().catch(() => null),
          (actor as any).getAllProfitStreams().catch(() => null),
          (actor as any).getTreasuryState().catch(() => null),
          (actor as any).getCreatorReserve().catch(() => null),
          (actor as any).getQuantumState().catch(() => null),
          (actor as any).px_getNeurochemicals().catch(() => null),
          (actor as any).px_getAuditLog(50n).catch(() => []),
          (actor as any).px_getVaelState
            ? (actor as any).px_getVaelState().catch(() => null)
            : Promise.resolve(null),
          (actor as any).px_getEmergenceApex
            ? (actor as any).px_getEmergenceApex().catch(() => 0)
            : Promise.resolve(0),
          (actor as any).px_getConsequenceComposite
            ? (actor as any).px_getConsequenceComposite().catch(() => 0)
            : Promise.resolve(0),
          (actor as any).px_getSovereignSignals
            ? (actor as any).px_getSovereignSignals().catch(() => null)
            : Promise.resolve(null),
          (actor as any).getSettlementFeed
            ? (actor as any).getSettlementFeed(50n).catch(() => [])
            : Promise.resolve([]),
          (actor as any).getTokenExchangeRates
            ? (actor as any).getTokenExchangeRates().catch(() => null)
            : Promise.resolve(null),
        ]);

        if (cancelled) return;

        if (fs) setFullState(fs as FullState);
        if (md) setMarketData(md as MarketData);
        if (tb) setTokenBalances(tb as TokenBalances);
        if (fe) setFeeds(fe as ExternalFeeds);
        if (ms) setMtcState(ms as MtcState);
        if (ps) setProfitStreams(ps as ProfitStreams);
        if (ts) setTreasuryState(ts as TreasuryState);
        if (cr) setCreatorReserve(cr as CreatorReserve);
        if (qs) setQuantumBattery(qs as QuantumBatteryState);

        // Sovereignty signals
        if (sovRaw && typeof sovRaw === "object") {
          setSovereignSignals(sovRaw as SovereignSignals);
          sovereignSignalsRef.current = sovRaw as SovereignSignals;
        }

        // VAEL defense signals
        if (vaelRaw && typeof vaelRaw === "object") {
          const vr = vaelRaw as any;
          setVaelCombinedField(
            typeof vr.combinedField === "number" ? vr.combinedField : 0,
          );
          setVeritasTruth(
            typeof vr.veritasTruth === "number" ? vr.veritasTruth : 0,
          );
        }
        if (typeof eaRaw === "number") setEmergenceApex(eaRaw);
        if (typeof ccRaw === "number") setConsequenceComposite(ccRaw);

        // Settlement feed
        if (settleFeed && Array.isArray(settleFeed)) {
          setSettlementFeed(settleFeed as SettlementEvent[]);
          const velocity = computeSettlementVelocity(
            settleFeed as SettlementEvent[],
            100,
          );
          setSettlementVelocity(velocity);

          // Push token price points from settlement rates
          const beat = Number((fs as FullState | null)?.beat ?? 0n);
          const forma = (fs as FullState | null)?.formaCapital ?? 0;
          const coherence = (fs as FullState | null)?.coherence ?? 1;
          for (const evt of settleFeed as SettlementEvent[]) {
            if (evt.rate > 0 && evt.tokenCode) {
              pushTokenPricePoint(
                evt.tokenCode,
                evt.rate,
                beat,
                forma,
                coherence,
              );
            }
          }
        }

        // Token exchange rates + arbitrage spread
        if (tokenRates && typeof tokenRates === "object") {
          setTokenExchangeRates(tokenRates as TokenExchangeRates);
          const rates = (tokenRates as TokenExchangeRates).rates ?? [];
          setArbitrageSpread(computeArbitrageSpread(rates));
        }

        setLoading(false);
        setPollCount((p) => p + 1);

        const btcP =
          (fe as ExternalFeeds | null)?.btcPrice ??
          (md as MarketData | null)?.btcPrice ??
          0;
        const ethP =
          (fe as ExternalFeeds | null)?.ethPrice ??
          (md as MarketData | null)?.ethPrice ??
          0;
        const forma = (fs as FullState | null)?.formaCapital ?? 0;
        const beat = Number((fs as FullState | null)?.beat ?? 0n);
        const coherence = (fs as FullState | null)?.coherence ?? 1;

        if (btcP > 0) {
          pushHistory(btcPricesRef, btcP);
          welfordBtcRef.current.update(btcP);
        }
        if (ethP > 0) pushHistory(ethPricesRef, ethP);
        if (forma > 0) pushHistory(formaHistRef, forma);

        // Update OHLCV candle buffer using MTC price as the primary price
        const msTyped = ms as MtcState | null;
        const mtcPrice = msTyped?.price ?? 0;
        if (mtcPrice > 0 && beat > 0) {
          pushPricePoint(mtcPrice, beat, forma, coherence);
          setCandles(getCandles(candleTimeframeRef.current));
          setStats24h(get24hStats());
        }

        // Update depth book
        if (msTyped && msTyped.price > 0) {
          const db = generateDepthBook(
            msTyped.price,
            msTyped.spreadRate,
            msTyped.tierPriceLW,
            msTyped.tierPriceHW,
            forma,
            coherence,
          );
          setDepthBook(db);
        }

        // Parse audit trades
        if (al && Array.isArray(al)) {
          const trades: AuditTrade[] = (al as any[])
            .filter(
              (e: any) => e.eventType === "MINT" || e.eventType === "BURN",
            )
            .slice(0, 20)
            .map((e: any) => ({
              beat: Number(e.beat),
              side:
                e.eventType === "MINT" ? ("BUY" as const) : ("SELL" as const),
              amount: e.detail ?? "0",
              price: msTyped?.price ?? 0,
              timestamp: Number(e.timestamp),
              status: "FILLED" as const,
            }));
          setAuditTrades(trades);
        }

        const btcArr = btcPricesRef.current;
        const ethArr = ethPricesRef.current;
        const formaArr = formaHistRef.current;
        const fsTyped = fs as FullState | null;

        if (btcArr.length >= 2) {
          const e21 = ema(btcArr, 21);
          const e200 = ema(btcArr, 200);
          const lastE21 = e21[e21.length - 1] ?? 0;
          const lastE200 = e200[e200.length - 1] ?? 0;
          setBtcEma21(lastE21);
          setBtcEma200(lastE200);
          const newRegime = classifyRegime(e21, e200);
          setRegime(newRegime);

          const boll = bollingerBands(btcArr, Math.min(20, btcArr.length));
          const lastIdx = boll.upper.length - 1;
          setBtcBollinger({
            upper: boll.upper[lastIdx] ?? 0,
            middle: boll.middle[lastIdx] ?? 0,
            lower: boll.lower[lastIdx] ?? 0,
            bandwidth: boll.bandwidth[lastIdx] ?? 0,
          });

          const zs = welfordBtcRef.current.zscore(btcP);
          setBtcZscore(zs);
          setBtcMomentum(rateOfChange(btcArr, Math.min(10, btcArr.length - 1)));
        }

        if (ethArr.length >= 2) {
          setEthMomentum(rateOfChange(ethArr, Math.min(10, ethArr.length - 1)));
        }

        const neuroArr = (neuro as number[] | null) ?? [];
        let currentEntropy = entropyRef.current;
        if (neuroArr.length > 0) {
          const phases = neuroArr.map(
            (v, i) => v * Math.PI * 2 * ((i % 7) + 1) * 0.1,
          );
          setKuramotoR(kuramotoOrderParam(phases));
          const entropy = vonNeumannEntropy(neuroArr);
          setEntropyScore(entropy);
          entropyRef.current = entropy;
          currentEntropy = entropy;

          shellActHistRef.current.push([...neuroArr]);
          if (shellActHistRef.current.length > MAX_HISTORY)
            shellActHistRef.current.shift();
        }

        if (formaArr.length >= 2 && forma > 0) {
          const prevForma = formaArr[formaArr.length - 2] ?? forma;
          const rate = forma > 0 ? (forma - prevForma) / forma : 0;
          const thyroid = neuroArr[13] ?? 1.0;
          const proj = formaProject(
            forma,
            Math.max(0, rate),
            Math.max(0.1, thyroid),
            1000,
          );
          setFormaProjVelocity(proj);
        }

        if (fsTyped) {
          const threat = vaelThreat(
            fsTyped.coherence,
            fsTyped.aresArmed,
            fsTyped.lawScore,
            fsTyped.novelty,
          );
          const fearBoost = sovereignSignalsRef.current?.fearLevel ?? 0;
          setVaelThreatScore(Math.min(1, threat + fearBoost * 0.3));

          const jVel = jacobsVelocity(
            Number(fsTyped.jacobRung),
            fsTyped.sacesiTarget,
          );
          setJacobsVel(jVel);

          const btcMom =
            btcArr.length >= 2
              ? rateOfChange(btcArr, Math.min(10, btcArr.length - 1))
              : 0;
          const sig = signalStrength(
            btcMom,
            fsTyped.coherence - coherenceRef.current,
            currentEntropy,
          );
          setSignalScore(sig);

          coherenceRef.current = fsTyped.coherence;
        }

        if (msTyped) {
          const tv = tokenVelocity(
            msTyped.yieldRate,
            msTyped.burnRate,
            msTyped.circulating,
          );
          setTokenVelocityScore(tv);
        }

        if (shellActHistRef.current.length >= 2) {
          spectralCoherence(shellActHistRef.current);
        }

        if (fsTyped) {
          const btcArr2 = btcPricesRef.current;
          const prevRegimeVal = regimeRef.current;
          const currentRegime =
            btcArr2.length >= 2
              ? classifyRegime(ema(btcArr2, 21), ema(btcArr2, 200))
              : "TRANSITION";
          const prevFormaVal =
            formaHistRef.current.length >= 2
              ? (formaHistRef.current[formaHistRef.current.length - 2] ?? 0)
              : 0;
          const btcZ = welfordBtcRef.current.zscore(btcP);

          const newAlerts = generateAlerts({
            coherence: fsTyped.coherence,
            prevCoherence: coherenceRef.current,
            regime: currentRegime,
            prevRegime: prevRegimeVal,
            vaelScore: vaelThreat(
              fsTyped.coherence,
              fsTyped.aresArmed,
              fsTyped.lawScore,
              fsTyped.novelty,
            ),
            beat: Number(fsTyped.beat),
            jacobRung: Number(fsTyped.jacobRung),
            formaCapital: forma,
            prevFormaCapital: prevFormaVal,
            dominantDrive: String(fsTyped.dominantDrive),
            btcZscore: btcZ,
            aresArmed: fsTyped.aresArmed,
            settlementVelocity: settlementVelocity,
            clearingHealth: clearingHealth,
          });

          if (newAlerts.length > 0) {
            setActiveAlerts((prev) => [...newAlerts, ...prev].slice(0, 20));
          }

          regimeRef.current = currentRegime;
        }
      } catch {
        if (!cancelled) setLoading(false);
      }
    };

    poll();
    const interval = setInterval(poll, 3000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [actor, pushHistory, settlementVelocity, clearingHealth]);

  // Slower poll for settlement stats + clearing reserves (every 5s)
  useEffect(() => {
    if (!actor) return;
    let cancelled = false;

    const pollSlow = async () => {
      try {
        const [stats, reserves] = await Promise.all([
          (actor as any).getSettlementStats
            ? (actor as any).getSettlementStats().catch(() => null)
            : Promise.resolve(null),
          (actor as any).getClearingReserves
            ? (actor as any).getClearingReserves().catch(() => null)
            : Promise.resolve(null),
        ]);

        if (cancelled) return;

        if (stats) setSettlementStats(stats as SettlementStats);

        if (reserves && typeof reserves === "object") {
          const r = reserves as ClearingReserves;
          setClearingReserves(r);
          // Compute clearing health: reserves vs balances
          const resArr = [
            r.gtk,
            r.mrc,
            r.cvt,
            r.vct,
            r.knt,
            r.sbt,
            r.hbt,
            r.drt,
            r.rst,
            r.omt,
            r.lgt,
            r.mth,
            r.mtc,
          ];
          const health = computeClearingHealth(
            resArr,
            resArr.map((v) => v * 1.2),
          );
          setClearingHealth(health);
        }
      } catch {
        /* silent */
      }
    };

    pollSlow();
    const interval = setInterval(pollSlow, 5000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [actor]);

  // Update candles when timeframe changes
  useEffect(() => {
    setCandles(getCandles(candleTimeframe));
  }, [candleTimeframe]);

  return {
    fullState,
    marketData,
    tokenBalances,
    feeds,
    mtcState,
    profitStreams,
    treasuryState,
    creatorReserve,
    quantumBattery,
    sovereignSignals,
    settlementFeed,
    settlementStats,
    tokenExchangeRates,
    clearingReserves,
    settlementVelocity,
    clearingHealth,
    arbitrageSpread,
    regime,
    btcEma21,
    btcEma200,
    btcBollinger,
    btcZscore,
    btcMomentum,
    ethMomentum,
    kuramotoR,
    formaProjVelocity,
    entropyScore,
    vaelThreat: vaelThreatScore,
    jacobsVelocity: jacobsVel,
    signalScore,
    tokenVelocityScore,
    vaelCombinedField,
    veritasTruth,
    emergenceApex,
    consequenceComposite,
    activeAlerts,
    loading,
    lastBeat: Number(fullState?.beat ?? 0n),
    pollCount,
    candles,
    candleTimeframe,
    setCandleTimeframe,
    stats24h,
    depthBook,
    auditTrades,
  };
}
