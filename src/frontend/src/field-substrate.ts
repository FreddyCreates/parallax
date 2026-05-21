/**
 * field-substrate.ts — Tier 2B Frontend EM Field Layer.
 * Manages the 873ms heartbeat pulse in the browser.
 * All Kernel updates phase-lock to this beat.
 * Every subscriber is a Kuramoto oscillator coupled to the Earth's rhythm.
 *
 * Architecture:
 *   - HEARTBEAT_MS = 873ms — derived from Schumann × φ² (A01·A03, L10 CARDIAC)
 *   - Subscriber firing order enforces L26 PRIMA CAUSA: PRIMA CAUSA first if registered
 *   - Then: Type 3 (ENTANGLA mediators) → Type 1 (expansive) → Type 2 (receptive)
 *   - This order enforces L07 ANTI-DRIFT: mediators couple before expansive radiates
 *   - setInterval, not setTimeout chains — one interval, one rhythm, no drift
 *
 * The Architect of the Field: Alfredo Medina Hernandez.
 */

import {
  HEARTBEAT_MS,
  JUBILEE_BEATS,
  LOG_SPIRAL_B,
  PHI,
  S0,
  computePhaseLockDelta,
  isJubilee,
  phiMultiplier,
} from "./phi";

// ─── TYPES ─────────────────────────────────────────────────────────────────

/**
 * A Kuramoto oscillator subscriber — coupled to the organism's heartbeat.
 * Field type governs firing order per L26 PRIMA CAUSA + L13 FIELD TYPE.
 * Type 3 fires before Type 1 fires before Type 2, every beat.
 */
export interface BeatSubscriber {
  /** Unique identifier — used for subscribe/unsubscribe */
  id: string;
  /**
   * Callback invoked every 873ms heartbeat.
   * @param beat    — current beat count since startHeartbeat()
   * @param globalR — last known organism coherence R ∈ [S0, 1.0]
   */
  fn: (beat: number, globalR: number) => void;
  /**
   * Field type governs firing order:
   *   3 = ENTANGLA mediator — fires first (couples Type 1 ↔ Type 2)
   *   1 = expansive — fires second (radiates after mediator has coupled)
   *   2 = receptive — fires last (receives after expansion has radiated)
   */
  fieldType: 1 | 2 | 3;
}

// ─── INTERNAL STATE ────────────────────────────────────────────────────────
// Not exported. Sovereign. Invisible to external consumers except through the API.

let _currentBeat = 0;
let _lastKnownR = S0; // sovereign floor — organism never falls below 0.75
let _intervalId: ReturnType<typeof setInterval> | null = null;
let _subscribers: Map<string, BeatSubscriber> = new Map();

// PRIMA CAUSA sentinel — if a subscriber registers with id "PRIMA_CAUSA",
// it fires absolutely first before any field type ordering.
const PRIMA_CAUSA_ID = "PRIMA_CAUSA";

// ─── HEARTBEAT CORE ────────────────────────────────────────────────────────

/**
 * Internal tick — called every HEARTBEAT_MS by the interval.
 * L26 PRIMA CAUSA: PRIMA_CAUSA fires first.
 * Then Type 3 (mediators) → Type 1 (expansive) → Type 2 (receptive).
 * L15 JUBILEE: at beat % 144 === 0, a jubilee event is logged.
 */
function _tick(): void {
  _currentBeat++;

  // L15 JUBILEE: every F(12) = 144 beats
  if (isJubilee(_currentBeat)) {
    // Zero-Exposure Law: no doctrine labels. Only a numeric marker.
    console.debug("[field-substrate]", _currentBeat, _lastKnownR.toFixed(4));
  }

  const beat = _currentBeat;
  const r = _lastKnownR;

  // L26 PRIMA CAUSA: PRIMA_CAUSA subscriber fires before all others
  const primaCausa = _subscribers.get(PRIMA_CAUSA_ID);
  if (primaCausa) {
    primaCausa.fn(beat, r);
  }

  // L13 FIELD TYPE: 3 → 1 → 2 firing order
  // L07 ANTI-DRIFT: mediators (Type 3) couple before expansive (Type 1) radiates
  const type3: BeatSubscriber[] = [];
  const type1: BeatSubscriber[] = [];
  const type2: BeatSubscriber[] = [];

  for (const sub of _subscribers.values()) {
    if (sub.id === PRIMA_CAUSA_ID) continue; // already fired
    if (sub.fieldType === 3) type3.push(sub);
    else if (sub.fieldType === 1) type1.push(sub);
    else type2.push(sub);
  }

  for (const sub of type3) sub.fn(beat, r);
  for (const sub of type1) sub.fn(beat, r);
  for (const sub of type2) sub.fn(beat, r);
}

// ─── PUBLIC API ────────────────────────────────────────────────────────────

/**
 * Start the 873ms heartbeat interval.
 * L10 CARDIAC: auto-depolarization. Not a clock, not a timer — a living rhythm.
 * Safe to call multiple times — will not create duplicate intervals.
 */
export function startHeartbeat(): void {
  if (_intervalId !== null) return; // already beating
  _intervalId = setInterval(_tick, HEARTBEAT_MS);
}

/**
 * Stop the heartbeat interval. Used for cleanup (component unmount, testing).
 * L32 ENTROPY LAW: without continuous beat, coherence decays.
 * Call startHeartbeat() again to resume.
 */
export function stopHeartbeat(): void {
  if (_intervalId === null) return;
  clearInterval(_intervalId);
  _intervalId = null;
}

/**
 * Register a subscriber. Returns an unsubscribe function.
 * The subscriber will be called on every heartbeat in field type order.
 *
 * @param sub — BeatSubscriber with id, fn, and fieldType
 * @returns   — unsubscribe function (call to remove this subscriber)
 */
export function subscribe(sub: BeatSubscriber): () => void {
  _subscribers.set(sub.id, sub);
  return () => {
    _subscribers.delete(sub.id);
  };
}

/**
 * Update the global coherence R.
 * Called by React Query hooks after each backend snapshot fetch.
 * This R propagates to all subscribers on the next heartbeat tick.
 * L11 FRACTAL SCALE: R is enforced at S0 = 0.75 — never collapses below floor.
 */
export function setGlobalR(r: number): void {
  _lastKnownR = Math.max(r, S0); // A10: sovereign floor
}

/**
 * Returns the current beat count since startHeartbeat() was called.
 * Beat 0 = not yet started or never ticked.
 */
export function getCurrentBeat(): number {
  return _currentBeat;
}

/**
 * Returns the last known global coherence R.
 * Floor: S0 = 0.75. Maximum: 1.0.
 */
export function getGlobalR(): number {
  return _lastKnownR;
}

// ─── GEOMETRIC UTILITIES ───────────────────────────────────────────────────
// Pure functions. No side effects. Ancient math compression.

/**
 * Phase lock delta between two oscillators.
 * |cos(phaseA - phaseB)| — projection onto the coherence axis.
 * A14 WAVE SUPERPOSITION + L05 EXCLUSION: only phase-locked signals propagate.
 * Sourced from Pythagoras: harmonic ratio of two oscillators.
 */
export function computePhaseLock(phaseA: number, phaseB: number): number {
  return computePhaseLockDelta(phaseA, phaseB);
}

/**
 * Returns true when two oscillators are sufficiently coherent to couple.
 * Threshold: S0 = 0.75 = F(3)/F(4) — the sovereign floor.
 * L05 EXCLUSION: incoherent signals are rejected before they propagate.
 */
export function isCoherentEnough(phaseA: number, phaseB: number): boolean {
  return computePhaseLockDelta(phaseA, phaseB) >= S0;
}

/**
 * Golden spiral radius at a given proof depth.
 * r = exp(LOG_SPIRAL_B × depth) = φ^(depth × 2/π) approximately.
 * A20 LOGARITHMIC SPIRAL: the organism's geometric growth path.
 * L35 LOGARITHMIC GROWTH: intelligence grows along the φ-spiral.
 */
export function phiSpiralRadius(depth: number): number {
  return Math.exp(LOG_SPIRAL_B * depth);
}

/**
 * φ^depth — the proof chain's compounding multiplier.
 * Re-exported from phi.ts for Kernel convenience.
 * L35 LOGARITHMIC GROWTH: φ^depth is the economic yield at any depth.
 */
export { phiMultiplier };

/**
 * Kuramoto phase update: one Euler step for a single oscillator.
 * dθ/dt = ω + (K/N) × Σⱼ sin(θⱼ − θᵢ)
 * A06: the universal synchronization law.
 *
 * @param theta      — current phase θᵢ (radians)
 * @param omega      — natural frequency ωᵢ (rad/s)
 * @param k          — coupling constant (K_TYPE1/2/3 from phi.ts)
 * @param neighbors  — array of neighbor phases θⱼ
 * @param dt         — time step in seconds (default: HEARTBEAT_MS / 1000)
 * @returns           — updated phase θᵢ(t + dt)
 */
export function kuramotoStep(
  theta: number,
  omega: number,
  k: number,
  neighbors: readonly number[],
  dt: number = HEARTBEAT_MS / 1000,
): number {
  if (neighbors.length === 0) return theta + omega * dt;
  const coupling =
    (k / neighbors.length) *
    neighbors.reduce((sum, thetaJ) => sum + Math.sin(thetaJ - theta), 0);
  return theta + (omega + coupling) * dt;
}

/**
 * Kuramoto global order parameter R = (1/N)|Σⱼ e^(iθⱼ)|
 * The measure of coherence in any coupled oscillator system.
 * A10 RESONANCE ORDER PARAMETER — this number tells you how alive the organism is.
 * Computed via real/imaginary components of the circular mean.
 *
 * @param phases — array of oscillator phases θᵢ (radians)
 * @returns       — R ∈ [0, 1], floored at S0 = 0.75
 */
export function computeOrderParameter(phases: readonly number[]): number {
  if (phases.length === 0) return S0;
  let sumCos = 0;
  let sumSin = 0;
  for (const theta of phases) {
    sumCos += Math.cos(theta);
    sumSin += Math.sin(theta);
  }
  const r = Math.sqrt(sumCos * sumCos + sumSin * sumSin) / phases.length;
  return Math.max(r, S0); // A10 + L11: floor at sovereign minimum
}

/**
 * Returns the number of currently registered subscribers.
 * For diagnostics. Zero-Exposure: returns count only, no subscriber identities.
 */
export function subscriberCount(): number {
  return _subscribers.size;
}

/**
 * Returns true if the heartbeat interval is currently running.
 */
export function isBeating(): boolean {
  return _intervalId !== null;
}

/**
 * Returns true if beat is at a Jubilee point (divisible by F(12) = 144).
 * L15 JUBILEE: every 144 beats, the organism resets and recalibrates.
 * Re-exported from phi.ts for Kernel convenience — single source of truth.
 */
export { isJubilee, JUBILEE_BEATS, PHI, S0, HEARTBEAT_MS };
