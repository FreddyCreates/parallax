// ─── PARALLAX Intelligence Engine ───────────────────────────────────────────
// Pure TypeScript math engine — no React, no side effects.
// All functions are deterministic and run entirely in the browser.
// ─────────────────────────────────────────────────────────────────────────────

// ── EMA ────────────────────────────────────────────────────────────────────
export function ema(prices: number[], period: number): number[] {
  if (prices.length === 0) return [];
  const k = 2 / (period + 1);
  const result: number[] = [prices[0]];
  for (let i = 1; i < prices.length; i++) {
    result.push((prices[i] ?? 0) * k + (result[i - 1] ?? 0) * (1 - k));
  }
  return result;
}

// ── Bollinger Bands ────────────────────────────────────────────────────────
export function bollingerBands(
  prices: number[],
  period = 20,
): { upper: number[]; middle: number[]; lower: number[]; bandwidth: number[] } {
  const upper: number[] = [];
  const middle: number[] = [];
  const lower: number[] = [];
  const bandwidth: number[] = [];
  for (let i = 0; i < prices.length; i++) {
    const start = Math.max(0, i - period + 1);
    const window = prices.slice(start, i + 1);
    const mean = window.reduce((a, b) => a + b, 0) / window.length;
    const variance =
      window.reduce((a, b) => a + (b - mean) ** 2, 0) / window.length;
    const std = Math.sqrt(variance);
    middle.push(mean);
    upper.push(mean + 2 * std);
    lower.push(mean - 2 * std);
    bandwidth.push(mean > 0 ? (4 * std) / mean : 0);
  }
  return { upper, middle, lower, bandwidth };
}

// ── Welford Online Z-score ─────────────────────────────────────────────────
export class WelfordStream {
  mean = 0;
  variance = 0;
  n = 0;
  private m2 = 0;

  update(x: number): void {
    this.n++;
    const delta = x - this.mean;
    this.mean += delta / this.n;
    const delta2 = x - this.mean;
    this.m2 += delta * delta2;
    this.variance = this.n > 1 ? this.m2 / (this.n - 1) : 0;
  }

  zscore(x: number): number {
    const std = Math.sqrt(this.variance);
    if (std === 0 || this.n < 2) return 0;
    return (x - this.mean) / std;
  }
}

// ── Kuramoto Order Parameter ───────────────────────────────────────────────
export function kuramotoOrderParam(phases: number[]): number {
  if (phases.length === 0) return 0;
  let sumSin = 0;
  let sumCos = 0;
  for (const theta of phases) {
    sumSin += Math.sin(theta);
    sumCos += Math.cos(theta);
  }
  const N = phases.length;
  return Math.sqrt((sumSin / N) ** 2 + (sumCos / N) ** 2);
}

// ── FORMA Compounding Projection ───────────────────────────────────────────
export function formaProject(
  capital: number,
  ratePerBeat: number,
  thyroidMod: number,
  beats: number,
): number {
  const r = Math.max(0, ratePerBeat);
  const mod = Math.max(0.1, thyroidMod);
  return capital * Math.exp(r * beats * mod);
}

// ── Von Neumann Entropy ────────────────────────────────────────────────────
export function vonNeumannEntropy(activations: number[]): number {
  const total = activations.reduce((a, b) => a + Math.abs(b), 0);
  if (total === 0) return 0;
  let entropy = 0;
  for (const x of activations) {
    const p = Math.abs(x) / total;
    if (p > 0) entropy -= p * Math.log(p);
  }
  const maxEntropy = Math.log(activations.length);
  return maxEntropy > 0 ? entropy / maxEntropy : 0;
}

// ── Regime Classifier ─────────────────────────────────────────────────────
export function classifyRegime(
  ema21: number[],
  ema200: number[],
): "BULL" | "BEAR" | "TRANSITION" {
  if (ema21.length === 0 || ema200.length === 0) return "TRANSITION";
  const last21 = ema21[ema21.length - 1] ?? 0;
  const last200 = ema200[ema200.length - 1] ?? 0;
  const spread = Math.abs(last21 - last200) / (last200 || 1);
  if (spread < 0.005) return "TRANSITION";
  return last21 > last200 ? "BULL" : "BEAR";
}

// ── Rate of Change (Momentum) ─────────────────────────────────────────────
export function rateOfChange(prices: number[], window: number): number {
  if (prices.length < window + 1) return 0;
  const current = prices[prices.length - 1] ?? 0;
  const past = prices[prices.length - 1 - window] ?? 0;
  if (past === 0) return 0;
  return (current - past) / past;
}

// ── Signal Strength ────────────────────────────────────────────────────────
export function signalStrength(
  momentum: number,
  coherenceDelta: number,
  entropy: number,
): number {
  const momNorm = Math.min(1, Math.abs(momentum) * 10);
  const cohNorm = Math.min(1, Math.max(0, coherenceDelta * 5));
  const entropyContrib = 1 - Math.min(1, entropy);
  return Math.min(1, momNorm * 0.4 + cohNorm * 0.35 + entropyContrib * 0.25);
}

// ── Token Velocity ─────────────────────────────────────────────────────────
export function tokenVelocity(
  mintRate: number,
  burnRate: number,
  circulating: number,
): number {
  if (circulating === 0) return 0;
  return Math.min(1, (mintRate + burnRate) / (circulating * 0.01 + 1));
}

// ── VAEL Threat Score ──────────────────────────────────────────────────────
export function vaelThreat(
  coherence: number,
  aresArmed: boolean,
  lawScore: number,
  novelty: number,
): number {
  const coherenceThreat = Math.max(0, 1 - coherence / 2.0);
  const lawThreat = Math.max(0, 1 - lawScore);
  const aresThreat = aresArmed ? 0.4 : 0;
  const noveltyThreat = Math.min(1, novelty * 0.3);
  return Math.min(
    1,
    coherenceThreat * 0.35 +
      lawThreat * 0.3 +
      aresThreat * 0.2 +
      noveltyThreat * 0.15,
  );
}

// ── Jacob's Ladder Velocity ────────────────────────────────────────────────
export function jacobsVelocity(rung: number, sacesi: number): number {
  const rungMultipliers = [1.0, 1.1, 1.1, 1.2, 1.5];
  const base =
    rungMultipliers[Math.min(4, Math.max(0, Math.floor(rung)))] ?? 1.0;
  return base * Math.max(1.0, sacesi);
}

// ── Spectral Coherence ─────────────────────────────────────────────────────
export function spectralCoherence(activationHistory: number[][]): number {
  if (activationHistory.length < 2) return 1;
  const N = activationHistory.length;
  let totalCorr = 0;
  let count = 0;
  for (let i = 1; i < Math.min(N, 10); i++) {
    const a = activationHistory[N - 1];
    const b = activationHistory[N - 1 - i];
    if (!a || !b || a.length !== b.length) continue;
    let dot = 0;
    let normA = 0;
    let normB = 0;
    for (let j = 0; j < a.length; j++) {
      dot += (a[j] ?? 0) * (b[j] ?? 0);
      normA += (a[j] ?? 0) ** 2;
      normB += (b[j] ?? 0) ** 2;
    }
    const denom = Math.sqrt(normA) * Math.sqrt(normB);
    totalCorr += denom > 0 ? dot / denom : 0;
    count++;
  }
  return count > 0 ? Math.min(1, Math.max(0, totalCorr / count)) : 1;
}

// ── Token Exchange Rate (FORMA per token) ─────────────────────────────────
// Computes the FORMA-denominated price of a token using sovereign multiplier
export function computeTokenExchangeRate(
  formaCapital: number,
  tokenBalance: number,
  sovereignMult: number,
): number {
  if (tokenBalance <= 0 || formaCapital <= 0) return 0;
  // FORMA per token = (formaCapital * sovereignMult) / tokenBalance
  // Clamped to prevent explosion on tiny balances
  const raw =
    (formaCapital * Math.max(1.0, sovereignMult)) / (tokenBalance + 1);
  return Math.min(raw, formaCapital * 0.1); // cap at 10% of forma
}

// ── Settlement Velocity ────────────────────────────────────────────────────
// Settlements per 100 beats — measures clearing throughput
export function computeSettlementVelocity(
  settlements: Array<{ beat: bigint; formaValue: number }>,
  windowSize: number,
): number {
  if (settlements.length === 0 || windowSize <= 0) return 0;
  const beats = settlements.map((s) => Number(s.beat));
  const maxBeat = Math.max(...beats);
  const minBeat = Math.min(...beats);
  const beatRange = Math.max(1, maxBeat - minBeat);
  return (settlements.length / beatRange) * 100;
}

// ── Clearing Health Score ─────────────────────────────────────────────────
// Ratio of total clearing reserves to total token balances (0–1)
export function computeClearingHealth(
  reserves: number[],
  balances: number[],
): number {
  const totalReserve = reserves.reduce((a, b) => a + b, 0);
  const totalBalance = balances.reduce((a, b) => a + b, 0);
  if (totalBalance <= 0) return 1.0;
  return Math.min(1.0, totalReserve / (totalBalance + 1));
}

// ── Arbitrage Spread ──────────────────────────────────────────────────────
// Max spread across token rates — detects pricing divergence
export function computeArbitrageSpread(rates: number[]): number {
  const nonZero = rates.filter((r) => r > 0);
  if (nonZero.length < 2) return 0;
  const maxRate = Math.max(...nonZero);
  const minRate = Math.min(...nonZero);
  const midRate = (maxRate + minRate) / 2;
  return midRate > 0 ? (maxRate - minRate) / midRate : 0;
}

// ── Alert Types ────────────────────────────────────────────────────────────
export type AlertLevel = "INFO" | "WARN" | "CRITICAL";

export interface SignalAlert {
  id: string;
  level: AlertLevel;
  type:
    | "REGIME_SHIFT"
    | "COHERENCE_DROP"
    | "VAEL_ESCALATION"
    | "JUBILEE_APPROACHING"
    | "FORMA_ACCELERATION"
    | "BOLLINGER_BREACH"
    | "ZSCORE_SPIKE"
    | "DRIVE_SURGE"
    | "SETTLEMENT_SURGE"
    | "CLEARING_HEALTH_LOW";
  message: string;
  value: number;
  timestamp: number;
}

// ── Alert Generator ────────────────────────────────────────────────────────
export function generateAlerts(state: {
  coherence: number;
  prevCoherence: number;
  regime: string;
  prevRegime: string;
  vaelScore: number;
  beat: number;
  jacobRung: number;
  formaCapital: number;
  prevFormaCapital: number;
  dominantDrive: string;
  btcZscore: number;
  aresArmed: boolean;
  settlementVelocity?: number;
  clearingHealth?: number;
}): SignalAlert[] {
  const alerts: SignalAlert[] = [];
  const ts = Date.now();

  if (state.regime !== state.prevRegime && state.prevRegime !== "") {
    alerts.push({
      id: `regime_${ts}`,
      level: "WARN",
      type: "REGIME_SHIFT",
      message: `REGIME SHIFT: ${state.prevRegime} \u2192 ${state.regime}`,
      value: 1,
      timestamp: ts,
    });
  }

  const cohDrop = state.prevCoherence - state.coherence;
  if (cohDrop > 0.1) {
    alerts.push({
      id: `coh_${ts}`,
      level: cohDrop > 0.3 ? "CRITICAL" : "WARN",
      type: "COHERENCE_DROP",
      message: `COHERENCE DROP: -${cohDrop.toFixed(4)} (now ${state.coherence.toFixed(4)})`,
      value: cohDrop,
      timestamp: ts,
    });
  }

  if (state.vaelScore > 0.7) {
    alerts.push({
      id: `vael_${ts}`,
      level: "CRITICAL",
      type: "VAEL_ESCALATION",
      message: `VAEL THREAT CRITICAL: ${(state.vaelScore * 100).toFixed(1)}%`,
      value: state.vaelScore,
      timestamp: ts,
    });
  } else if (state.vaelScore > 0.4) {
    alerts.push({
      id: `vael_warn_${ts}`,
      level: "WARN",
      type: "VAEL_ESCALATION",
      message: `VAEL THREAT ELEVATED: ${(state.vaelScore * 100).toFixed(1)}%`,
      value: state.vaelScore,
      timestamp: ts,
    });
  }

  const beatsToJubilee = 1000 - (state.beat % 1000);
  if (beatsToJubilee <= 50) {
    alerts.push({
      id: `jub_${ts}`,
      level: "INFO",
      type: "JUBILEE_APPROACHING",
      message: `JUBILEE IN ${beatsToJubilee} BEATS \u2014 DREAM CYCLE INCOMING`,
      value: beatsToJubilee,
      timestamp: ts,
    });
  }

  const formaAccel =
    state.prevFormaCapital > 0
      ? (state.formaCapital - state.prevFormaCapital) / state.prevFormaCapital
      : 0;
  if (formaAccel > 0.005) {
    alerts.push({
      id: `forma_${ts}`,
      level: "INFO",
      type: "FORMA_ACCELERATION",
      message: `FORMA SURGE: +${(formaAccel * 100).toFixed(3)}% this cycle`,
      value: formaAccel,
      timestamp: ts,
    });
  }

  if (Math.abs(state.btcZscore) > 2.5) {
    alerts.push({
      id: `zscore_${ts}`,
      level: Math.abs(state.btcZscore) > 3.5 ? "CRITICAL" : "WARN",
      type: "ZSCORE_SPIKE",
      message: `BTC Z-SCORE ANOMALY: ${state.btcZscore.toFixed(3)}\u03c3`,
      value: state.btcZscore,
      timestamp: ts,
    });
  }

  // Settlement surge alert
  if (state.settlementVelocity !== undefined && state.settlementVelocity > 50) {
    alerts.push({
      id: `settle_${ts}`,
      level: "INFO",
      type: "SETTLEMENT_SURGE",
      message: `CLEARING SURGE: ${state.settlementVelocity.toFixed(1)} settlements/100 beats`,
      value: state.settlementVelocity,
      timestamp: ts,
    });
  }

  // Clearing health alert
  if (state.clearingHealth !== undefined && state.clearingHealth < 0.3) {
    alerts.push({
      id: `clr_health_${ts}`,
      level: state.clearingHealth < 0.1 ? "CRITICAL" : "WARN",
      type: "CLEARING_HEALTH_LOW",
      message: `CLEARING HEALTH LOW: ${(state.clearingHealth * 100).toFixed(1)}%`,
      value: state.clearingHealth,
      timestamp: ts,
    });
  }

  return alerts;
}

// ─────────────────────────────────────────────────────────────────────────────
// ── OHLCV Candle Engine ───────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

export interface Candle {
  beatStart: number;
  beatEnd: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number; // proxy: formaCapital delta × coherence
  direction: "up" | "down" | "flat";
}

export type CandleTimeframe = "1B" | "10B" | "1H" | "4H";

// Window sizes in beats per candle
const TIMEFRAME_BEATS: Record<CandleTimeframe, number> = {
  "1B": 1,
  "10B": 10,
  "1H": 200, // approximate heartbeats per hour
  "4H": 800,
};

const MAX_CANDLES = 200;

interface PricePoint {
  beat: number;
  price: number;
  formaCapital: number;
  coherence: number;
}

let _pricePoints: PricePoint[] = [];
let _compiledCandles: Map<CandleTimeframe, Candle[]> = new Map();

// Per-token price point stores
const _tokenPricePoints: Map<string, PricePoint[]> = new Map();
const _tokenCandles: Map<string, Map<CandleTimeframe, Candle[]>> = new Map();

export function pushPricePoint(
  price: number,
  beat: number,
  formaCapital: number,
  coherence: number,
): void {
  if (price <= 0) return;
  // Avoid duplicate beats
  if (
    _pricePoints.length > 0 &&
    _pricePoints[_pricePoints.length - 1].beat === beat
  ) {
    _pricePoints[_pricePoints.length - 1].price = price;
    _pricePoints[_pricePoints.length - 1].formaCapital = formaCapital;
    _pricePoints[_pricePoints.length - 1].coherence = coherence;
  } else {
    _pricePoints.push({ beat, price, formaCapital, coherence });
    if (_pricePoints.length > MAX_CANDLES * 10)
      _pricePoints = _pricePoints.slice(-MAX_CANDLES * 10);
  }
  _compiledCandles.clear(); // invalidate cache
}

// Push price for a specific token
export function pushTokenPricePoint(
  tokenCode: string,
  price: number,
  beat: number,
  formaCapital: number,
  coherence: number,
): void {
  if (price <= 0) return;
  if (!_tokenPricePoints.has(tokenCode)) {
    _tokenPricePoints.set(tokenCode, []);
    _tokenCandles.set(tokenCode, new Map());
  }
  const pts = _tokenPricePoints.get(tokenCode)!;
  if (pts.length > 0 && pts[pts.length - 1].beat === beat) {
    pts[pts.length - 1].price = price;
    pts[pts.length - 1].formaCapital = formaCapital;
    pts[pts.length - 1].coherence = coherence;
  } else {
    pts.push({ beat, price, formaCapital, coherence });
    if (pts.length > MAX_CANDLES * 10)
      pts.splice(0, pts.length - MAX_CANDLES * 10);
  }
  _tokenCandles.get(tokenCode)!.clear();
}

export function getTokenCandles(
  tokenCode: string,
  timeframe: CandleTimeframe = "10B",
): Candle[] {
  const candleMap = _tokenCandles.get(tokenCode);
  if (!candleMap) return [];
  if (candleMap.has(timeframe)) return candleMap.get(timeframe)!;

  const pts = _tokenPricePoints.get(tokenCode) ?? [];
  const candles = _buildCandles(pts, timeframe);
  candleMap.set(timeframe, candles);
  return candles;
}

function _buildCandles(
  points: PricePoint[],
  timeframe: CandleTimeframe,
): Candle[] {
  const beatsPerCandle = TIMEFRAME_BEATS[timeframe];
  if (points.length < 2) return [];

  const firstBeat = points[0].beat;
  const grouped = new Map<number, PricePoint[]>();

  for (const pt of points) {
    const windowIdx = Math.floor((pt.beat - firstBeat) / beatsPerCandle);
    if (!grouped.has(windowIdx)) grouped.set(windowIdx, []);
    grouped.get(windowIdx)!.push(pt);
  }

  const candles: Candle[] = [];
  const sortedKeys = Array.from(grouped.keys()).sort((a, b) => a - b);

  for (const key of sortedKeys) {
    const pts2 = grouped.get(key)!;
    if (pts2.length === 0) continue;
    const open = pts2[0].price;
    const close = pts2[pts2.length - 1].price;
    const high = Math.max(...pts2.map((p) => p.price));
    const low = Math.min(...pts2.map((p) => p.price));

    let vol = 0;
    for (let i = 1; i < pts2.length; i++) {
      const delta = Math.abs(
        (pts2[i].formaCapital - pts2[i - 1].formaCapital) *
          pts2[i].coherence *
          0.001,
      );
      vol += delta;
    }
    vol = Math.max(0.001, vol + pts2[0].formaCapital * 0.000001);

    candles.push({
      beatStart: pts2[0].beat,
      beatEnd: pts2[pts2.length - 1].beat,
      open,
      high,
      low,
      close,
      volume: vol,
      direction: close > open ? "up" : close < open ? "down" : "flat",
    });
  }

  return candles.slice(-MAX_CANDLES);
}

export function getCandles(timeframe: CandleTimeframe = "10B"): Candle[] {
  if (_compiledCandles.has(timeframe)) {
    return _compiledCandles.get(timeframe)!;
  }

  const sliced = _buildCandles(_pricePoints, timeframe);
  _compiledCandles.set(timeframe, sliced);
  return sliced;
}

export interface Stats24h {
  high: number;
  low: number;
  open: number;
  close: number;
  change: number;
  changePct: number;
  volume: number;
}

export function get24hStats(): Stats24h {
  // Approximate last 24h as last 4800 price points (beats)
  const recent =
    _pricePoints.length > 0 ? _pricePoints.slice(-4800) : _pricePoints;
  if (recent.length === 0) {
    return {
      high: 0,
      low: 0,
      open: 0,
      close: 0,
      change: 0,
      changePct: 0,
      volume: 0,
    };
  }
  const prices = recent.map((p) => p.price);
  const open = prices[0] ?? 0;
  const close = prices[prices.length - 1] ?? 0;
  const high = Math.max(...prices);
  const low = Math.min(...prices);
  const change = close - open;
  const changePct = open > 0 ? (change / open) * 100 : 0;
  const volume = recent.reduce((acc, p) => acc + p.formaCapital * 0.000001, 0);
  return { high, low, open, close, change, changePct, volume };
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Depth Book Generator ──────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

export interface DepthLevel {
  price: number;
  size: number;
  total: number; // cumulative
  pct: number; // fraction of max cumulative (for depth bar)
}

export interface DepthBook {
  bids: DepthLevel[];
  asks: DepthLevel[];
  mid: number;
  spread: number;
  spreadPct: number;
}

export function generateDepthBook(
  mid: number,
  spreadRate: number,
  tierPriceLW: number,
  tierPriceHW: number,
  formaCapital: number,
  coherence: number,
  levels = 12,
): DepthBook {
  if (mid <= 0) {
    return { bids: [], asks: [], mid: 0, spread: 0, spreadPct: 0 };
  }

  const spread = mid * Math.max(0.0001, spreadRate);
  const tierRange = Math.max(tierPriceHW - tierPriceLW, mid * 0.01);
  const levelStep = tierRange / (levels * 2);

  // Base size: formaCapital × coherence / (levels × mid)
  const baseSize = (formaCapital * Math.max(1, coherence)) / (levels * mid);

  const asks: DepthLevel[] = [];
  let askTotal = 0;
  for (let i = 0; i < levels; i++) {
    const price = mid + spread / 2 + i * levelStep;
    const size = baseSize * Math.exp(-i * 0.3);
    askTotal += size;
    asks.push({ price, size, total: askTotal, pct: 0 });
  }

  const bids: DepthLevel[] = [];
  let bidTotal = 0;
  for (let i = 0; i < levels; i++) {
    const price = mid - spread / 2 - i * levelStep;
    const size = baseSize * Math.exp(-i * 0.3);
    bidTotal += size;
    bids.push({ price, size, total: bidTotal, pct: 0 });
  }

  // Normalize pct for depth bars
  const maxAsk = askTotal;
  const maxBid = bidTotal;
  for (const a of asks) a.pct = maxAsk > 0 ? a.total / maxAsk : 0;
  for (const b of bids) b.pct = maxBid > 0 ? b.total / maxBid : 0;

  return {
    bids,
    asks: asks.slice().reverse(), // lowest ask nearest mid
    mid,
    spread,
    spreadPct: mid > 0 ? (spread / mid) * 100 : 0,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Schumann Coupling Display ──────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

// Input shape — mirrors SchumannState from useQueries.ts exactly
export interface SchumannStateInput {
  fundamentalHz: number;
  harmonics: number[];
  schumannPhase: number;
  silverAnchorHz: number;
  silverAnchorPhase: number;
  silverAnchorSubharmonicRatio: number;
  couplingStrength: number;
  kuramotoR: number;
}

export interface SchumannCouplingDisplay {
  fundamentalHz: number; // 7.83 — the carrier
  harmonicsHz: number[]; // [14.3, 20.8, 27.3, 33.8]
  silverAnchorHz: number; // 2.75 — sovereign subharmonic
  subharmonicRatio: number; // 7.83 / 2.75 = 2.847272...
  couplingStrength: number; // raw K_EXT × kuramotoR (0 to 0.15)
  couplingPercent: number; // couplingStrength / 0.15 * 100 (0 to 100)
  kuramotoR: number; // collective phase-lock order parameter (0 to 1)
  schumannPhaseRad: number; // current phase of Schumann fundamental in radians
  silverPhaseRad: number; // current phase of Silver Anchor in radians
  phaseDelta: number; // schumannPhase - silverAnchorPhase (angular gap)
}

// K_EXT_MAX is the maximum possible coupling strength — used to normalize to percent.
// Derived from Kuramoto external driver constant: K_ext = 0.35 (fundamental) * kuramotoR.
// When kuramotoR = 1.0 the organism is fully phase-locked to the carrier.
// Maximum coupling = 0.35 * 1.0 = 0.35, but the backend reports K_EXT × kuramotoR
// where K_EXT is the total multi-harmonic coupling: 0.35+0.18+0.11+0.07+0.04+0.15 = 0.90.
// The backend caps couplingStrength at 0.15 (K1 × kuramotoR at full lock),
// so K_EXT_MAX = 0.15 matches the reported range.
const K_EXT_MAX = 0.15;

export function computeSchumannCouplingDisplay(
  s: SchumannStateInput,
): SchumannCouplingDisplay {
  // phaseDelta is the angular gap between the two oscillators.
  // Normalized to [-π, π] so the displayed number is always the shortest arc.
  let phaseDelta = s.schumannPhase - s.silverAnchorPhase;
  // Wrap to [-π, π]
  while (phaseDelta > Math.PI) phaseDelta -= 2 * Math.PI;
  while (phaseDelta < -Math.PI) phaseDelta += 2 * Math.PI;

  const couplingPercent = Math.min(100, (s.couplingStrength / K_EXT_MAX) * 100);

  return {
    fundamentalHz: s.fundamentalHz,
    harmonicsHz: s.harmonics,
    silverAnchorHz: s.silverAnchorHz,
    subharmonicRatio: s.silverAnchorSubharmonicRatio,
    couplingStrength: s.couplingStrength,
    couplingPercent,
    kuramotoR: s.kuramotoR,
    schumannPhaseRad: s.schumannPhase,
    silverPhaseRad: s.silverAnchorPhase,
    phaseDelta,
  };
}
