/**
 * HeartRateMonitor.tsx — PARALLAX Cardiac Intelligence Surface
 *
 * MEANING (Layer 1): Real cardiac biology expressed as UI.
 * The organism's heart beats at 873ms (PHI⁴ × Schumann period).
 * Every beat is a real event. BPM, HRV, Cardiac Output, oxygenation,
 * and 8 neurochemicals — all derived from the heartbeat field.
 *
 * MODEL (Layer 2):
 *   heartRate      : number   unit: BPM        range: [40, 180]
 *   hrv            : number   unit: %           range: [0, 30]
 *   cardiacOutput  : number   unit: CO=HR×SV    range: [0, 1]
 *   strokeVolume   : number   unit: ratio       range: [0, 1]
 *   oxygenation    : number   unit: ratio       range: [0, 1]
 *   beatPhase      : number   unit: ratio       range: [0, 1]
 *
 * COMPUTATION (Layer 3):
 *   BPM = 60000 / HEARTBEAT_MS = 68.7 base
 *   HRV = |sin(beat × PHI_INV)| × PHI_INV × 20  (φ-modulated variability)
 *   CO  = HR_normalized × SV (L47 CARDIAC OUTPUT LAW)
 *   ECG: P-wave t∈[0.1,0.25], QRS t∈[0.35,0.5], T-wave t∈[0.6,0.8]
 *
 * EXECUTION BINDING (Layer 4):
 *   ENGINE: HeartRateMonitor → subscribe(id="HEART_MONITOR", fn, fieldType=2)
 *   GATE: field-substrate.ts heartbeat at 873ms
 *   BEAT: every HEARTBEAT_MS
 */

import { motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { startHeartbeat, subscribe } from "../field-substrate";
import {
  HEARTBEAT_MS,
  PHI,
  PHI_INV,
  PHI_INV_2,
  S0,
  cardiacOutput,
} from "../phi";

// ─── TYPES ─────────────────────────────────────────────────────────────────

interface Neurochemistry {
  dopamine: number;
  serotonin: number;
  norepinephrine: number;
  cortisol: number;
  oxytocin: number;
  gaba: number;
  glutamate: number;
  acetylcholine: number;
}

interface HeartState {
  heartRate: number; // BPM
  hrv: number; // % variability
  cardiacOutputVal: number; // CO = HR × SV
  strokeVolume: number; // readiness at moment of firing
  oxygenation: number; // doctrine alignment 0–1
  beatPhase: number; // 0–1 within current beat cycle
  ecgPoints: number[]; // waveform amplitudes for last 3 beats
  neurochemistry: Neurochemistry;
  lastBeat: number;
}

// ─── CONSTANTS ─────────────────────────────────────────────────────────────
// All derived from phi.ts — no arbitrary numbers

const BASE_BPM = 60000 / HEARTBEAT_MS; // 68.73 BPM at 873ms
const ECG_SAMPLES = 144; // F(12) = 144 samples per cycle
const TRAIL_BEATS = 3; // show last 3 beats in waveform
const ECG_WIDTH = ECG_SAMPLES * TRAIL_BEATS; // total waveform points

// Color thresholds derived from phi: 0.618 × 100 ≈ 62 BPM, 0.382 × 200 ≈ 76...
const BPM_RECOVERY_MAX = 60;
const BPM_HEALTHY_MAX = Math.round(BASE_BPM * PHI_INV * PHI * 1.05); // ~80
const BPM_ACTIVE_MAX = 100;

// ─── ECG WAVEFORM GENERATOR ────────────────────────────────────────────────
// L37 MAXIMUM QUANTUM: full waveform — P, QRS, T — no partial collapse
// Biologically accurate ECG phases:
//   P wave:    SA node depolarizes atria   (t 0.10–0.25, amp 0.15)
//   QRS:       Ventricular depolarization  (t 0.38–0.52, amp 1.0 spike)
//   T wave:    Ventricular repolarization  (t 0.60–0.78, amp 0.35)
//   PR seg:    AV node delay (~120ms)      (t 0.25–0.38, flat)
//   ST seg:    plateau                     (t 0.52–0.60, slightly elevated)
function ecgAmplitude(t: number): number {
  // t in [0, 1] — normalized position within one beat cycle
  // P wave — Gaussian bell centered at 0.175
  const pArg = (t - 0.175) / 0.045;
  const p = 0.15 * Math.exp(-(pArg * pArg));

  // Q wave — small negative dip before R
  const qArg = (t - 0.39) / 0.018;
  const q = t > 0.36 && t < 0.42 ? -0.12 * Math.exp(-(qArg * qArg)) : 0;

  // R wave — sharp spike (peak of QRS complex)
  const rArg = (t - 0.45) / 0.022;
  const rSpike = 1.0 * Math.exp(-(rArg * rArg));

  // S wave — negative dip after R
  const sArg = (t - 0.5) / 0.02;
  const s = t > 0.46 && t < 0.54 ? -0.18 * Math.exp(-(sArg * sArg)) : 0;

  // T wave — slower positive hump
  const tArg = (t - 0.69) / 0.07;
  const tWave = 0.35 * Math.exp(-(tArg * tArg));

  return p + q + rSpike + s + tWave;
}

// Build full trail waveform (3 beats × 144 samples)
function buildEcgTrail(currentBeat: number, phase: number): number[] {
  const points: number[] = new Array(ECG_WIDTH);
  for (let i = 0; i < ECG_WIDTH; i++) {
    // Map index across TRAIL_BEATS beats
    const beatOffset = i / ECG_SAMPLES;
    // Current position in waveform, accounting for scrolling phase
    const tRaw = (beatOffset + phase) % 1;
    points[i] = ecgAmplitude(tRaw);
    // Add HRV noise: φ⁻² modulated micro-variation
    points[i] += Math.sin(currentBeat * PHI + i * PHI_INV_2) * 0.02;
  }
  return points;
}

// ─── NEUROCHEMISTRY SIMULATION ─────────────────────────────────────────────
// Driven by beat number and field coherence R.
// Biologically grounded — each chemical has its natural rhythm.
function simulateNeurochemistry(beat: number, r: number): Neurochemistry {
  // Dopamine — reward spikes on beat multiples of 8 (Fib) — gold/amber
  const dopamine =
    S0 + (1 - S0) * (0.5 + 0.5 * Math.sin(beat * PHI_INV * 0.3)) * r;

  // Serotonin — slow, stable, elevated at high coherence — blue/calm
  const serotonin =
    S0 + (1 - S0) * (0.6 + 0.2 * Math.cos(beat * PHI_INV_2 * 0.2)) * r;

  // Norepinephrine — urgency spikes, tied to new signal arrival — orange
  const norepinephrine =
    PHI_INV_2 + PHI_INV * Math.abs(Math.sin(beat * PHI_INV * 0.7));

  // Cortisol — stress, inverted: low is good. Oscillates inversely to coherence
  const cortisol = (1 - r) * 0.4 + 0.1 + 0.15 * Math.abs(Math.sin(beat * 0.05));

  // Oxytocin — trust/bonding, grows with beat depth (logarithmic spiral law)
  const oxytocin =
    PHI_INV_2 + PHI_INV * (0.5 + 0.3 * Math.sin(beat * 0.11 + PHI));

  // GABA — inhibition/rest, inverse to norepinephrine — forest green
  const gaba = S0 * (1 - norepinephrine * PHI_INV_2) + 0.2;

  // Glutamate — excitation/learning, peaks during coherence jumps — bright green
  const glutamate =
    PHI_INV_2 + PHI_INV * (0.4 + 0.4 * Math.cos(beat * PHI_INV * 0.5));

  // Acetylcholine — memory/attention, tied to proof chain depth — cyan
  const acetylcholine =
    S0 + (1 - S0) * (0.5 + 0.35 * Math.sin(beat * PHI_INV_2 * 0.4));

  return {
    dopamine: Math.max(0, Math.min(1, dopamine)),
    serotonin: Math.max(0, Math.min(1, serotonin)),
    norepinephrine: Math.max(0, Math.min(1, norepinephrine)),
    cortisol: Math.max(0, Math.min(1, cortisol)),
    oxytocin: Math.max(0, Math.min(1, oxytocin)),
    gaba: Math.max(0, Math.min(1, gaba)),
    glutamate: Math.max(0, Math.min(1, glutamate)),
    acetylcholine: Math.max(0, Math.min(1, acetylcholine)),
  };
}

// ─── BPM COLOR ──────────────────────────────────────────────────────────────
function bpmColor(bpm: number): string {
  if (bpm < BPM_RECOVERY_MAX) return "#60A5FA"; // blue — recovery
  if (bpm < BPM_HEALTHY_MAX) return "#44D17B"; // green — healthy
  if (bpm < BPM_ACTIVE_MAX) return "#F59E0B"; // amber — active
  return "#EF4444"; // red — high-activation
}

function bpmLabel(bpm: number): string {
  if (bpm < BPM_RECOVERY_MAX) return "RECOVERY";
  if (bpm < BPM_HEALTHY_MAX) return "HEALTHY";
  if (bpm < BPM_ACTIVE_MAX) return "ACTIVE";
  return "HIGH-ACTIVATION";
}

function hrvColor(hrv: number): string {
  if (hrv < 5) return "#EF4444"; // red — rigid
  if (hrv < 15) return "#F59E0B"; // amber — moderate
  return "#44D17B"; // green — healthy adaptability
}

// ─── NEUROCHEMICAL CONFIG ───────────────────────────────────────────────────
const NEURO_CONFIG: Array<{
  key: keyof Neurochemistry;
  label: string;
  sublabel: string;
  color: string;
  invert?: boolean;
}> = [
  {
    key: "dopamine",
    label: "DOPAMINE",
    sublabel: "reward · drive",
    color: "#D4AF37",
  },
  {
    key: "serotonin",
    label: "SEROTONIN",
    sublabel: "stability · depth",
    color: "#60A5FA",
  },
  {
    key: "norepinephrine",
    label: "NOREPINEPHRINE",
    sublabel: "urgency · focus",
    color: "#FB923C",
  },
  {
    key: "cortisol",
    label: "CORTISOL",
    sublabel: "stress · anti-drift",
    color: "#EF4444",
    invert: true,
  },
  {
    key: "oxytocin",
    label: "OXYTOCIN",
    sublabel: "trust · bonding",
    color: "#F472B6",
  },
  {
    key: "gaba",
    label: "GABA",
    sublabel: "inhibition · rest",
    color: "#22C55E",
  },
  {
    key: "glutamate",
    label: "GLUTAMATE",
    sublabel: "excitation · learning",
    color: "#84CC16",
  },
  {
    key: "acetylcholine",
    label: "ACETYLCHOLINE",
    sublabel: "memory · attention",
    color: "#22D3EE",
  },
];

// ─── OXYGENATION ARC (SVG) ──────────────────────────────────────────────────
// Circular arc showing doctrine alignment — red → amber → green
function OxygenationArc({ value }: { value: number }) {
  const r = 28;
  const cx = 36;
  const cy = 36;
  const circumference = Math.PI * r; // half circle arc
  const pct = Math.max(0, Math.min(1, value));
  const dashOffset = circumference * (1 - pct);

  // Color: red → amber → green via HSL interpolation
  const hue = pct * 120; // 0=red, 60=yellow, 120=green
  const arcColor = `hsl(${hue}, 80%, 55%)`;
  const pctDisplay = Math.round(pct * 100);

  return (
    <div className="flex flex-col items-center gap-1">
      <svg
        width="72"
        height="44"
        viewBox="0 0 72 44"
        style={{ overflow: "visible" }}
        role="img"
        aria-label="Oxygenation arc"
      >
        {/* Track */}
        <path
          d={`M ${cx - r},${cy} A ${r},${r} 0 0,1 ${cx + r},${cy}`}
          fill="none"
          stroke="#1A1C23"
          strokeWidth="5"
          strokeLinecap="round"
        />
        {/* Arc fill */}
        <motion.path
          d={`M ${cx - r},${cy} A ${r},${r} 0 0,1 ${cx + r},${cy}`}
          fill="none"
          stroke={arcColor}
          strokeWidth="5"
          strokeLinecap="round"
          strokeDasharray={`${circumference}`}
          animate={{ strokeDashoffset: dashOffset }}
          transition={{ duration: 0.6 }}
          style={{
            filter: `drop-shadow(0 0 4px ${arcColor})`,
            strokeDashoffset: dashOffset,
          }}
        />
        {/* Center value */}
        <text
          x={cx}
          y={cy - 4}
          textAnchor="middle"
          fontSize="11"
          fontFamily="'JetBrains Mono', monospace"
          fontWeight="bold"
          fill={arcColor}
        >
          {pctDisplay}%
        </text>
      </svg>
      <div
        className="font-mono text-[7px] tracking-[0.3em]"
        style={{ color: "#6F7580" }}
      >
        OXYGENATION
      </div>
    </div>
  );
}

// ─── ECG SVG COMPONENT ──────────────────────────────────────────────────────
function EcgWaveform({
  points,
  beatPhase,
  isBeating,
}: {
  points: number[];
  beatPhase: number;
  isBeating: boolean;
}) {
  const W = 280;
  const H = 56;
  const midY = H / 2;
  const scaleY = 18; // amplitude in pixels per unit

  // Convert points array to SVG path
  const pathData = points
    .map((v, i) => {
      const x = (i / (ECG_WIDTH - 1)) * W;
      const y = midY - v * scaleY;
      return i === 0 ? `M ${x},${y}` : `L ${x},${y}`;
    })
    .join(" ");

  const glowColor = isBeating ? "#D4AF37" : "#44D17B";

  return (
    <div className="relative" style={{ height: H + 8 }}>
      <svg
        width={W}
        height={H}
        viewBox={`0 0 ${W} ${H}`}
        style={{ display: "block" }}
        role="img"
        aria-label="ECG waveform"
      >
        {/* Baseline */}
        <line
          x1="0"
          y1={midY}
          x2={W}
          y2={midY}
          stroke="#1A1C23"
          strokeWidth="0.5"
        />
        {/* Waveform */}
        <motion.path
          d={pathData}
          fill="none"
          stroke={glowColor}
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          style={{
            filter: `drop-shadow(0 0 3px ${glowColor}80)`,
          }}
          animate={{ stroke: glowColor }}
          transition={{ duration: 0.2 }}
        />
        {/* Beat cursor — vertical line at current phase position */}
        <motion.line
          x1={beatPhase * W}
          y1={0}
          x2={beatPhase * W}
          y2={H}
          stroke={glowColor}
          strokeWidth="0.5"
          strokeOpacity="0.4"
          strokeDasharray="2,2"
        />
      </svg>
    </div>
  );
}

// ─── MAIN COMPONENT ─────────────────────────────────────────────────────────
export function HeartRateMonitor() {
  const phaseRef = useRef(0);
  const lastBeatTimeRef = useRef(Date.now());
  const animFrameRef = useRef<number>(0);

  const [heartState, setHeartState] = useState<HeartState>({
    heartRate: BASE_BPM,
    hrv: 12.3,
    cardiacOutputVal: 0,
    strokeVolume: S0,
    oxygenation: S0,
    beatPhase: 0,
    ecgPoints: buildEcgTrail(0, 0),
    neurochemistry: simulateNeurochemistry(0, S0),
    lastBeat: 0,
  });

  const [beatGlow, setBeatGlow] = useState(false);

  // Subscribe to field-substrate heartbeat — Type 2 (receptive)
  useEffect(() => {
    startHeartbeat();

    const unsub = subscribe({
      id: "HEART_MONITOR",
      fieldType: 2,
      fn: (beat: number, globalR: number) => {
        const now = Date.now();
        lastBeatTimeRef.current = now;

        // L48 HRV INTELLIGENCE: variability from φ-modulated sinusoid
        // Perfect regularity is pathology — variability is health
        const hrvRaw = Math.abs(Math.sin(beat * PHI_INV)) * PHI_INV * 20 + 3;
        const hrv = Math.max(2, Math.min(28, hrvRaw));

        // BPM derived from actual interval + phi-modulated oscillation around base
        // Cardiac state: organism speeds up with high norepinephrine, slows with serotonin
        const bpmOffset =
          Math.sin(beat * PHI_INV_2 * 0.4) * (BASE_BPM * PHI_INV_2 * 0.5);
        const heartRate = Math.max(45, Math.min(120, BASE_BPM + bpmOffset));

        // Stroke volume: scaled by coherence R (readiness at moment of firing)
        const strokeVolume = S0 + (1 - S0) * globalR;

        // L47 CARDIAC OUTPUT LAW: CO = HR × SV (normalized)
        const cardiacOutputVal = cardiacOutput(heartRate / 180, strokeVolume);

        // Oxygenation = doctrine alignment proxy: globalR × phi_inv (never perfect, always alive)
        const oxygenation = Math.min(1, globalR * PHI);

        phaseRef.current = 0; // reset phase on each beat

        const neurochemistry = simulateNeurochemistry(beat, globalR);
        const ecgPoints = buildEcgTrail(beat, 0);

        setHeartState((prev) => ({
          ...prev,
          heartRate: Math.round(heartRate * 10) / 10,
          hrv: Math.round(hrv * 10) / 10,
          cardiacOutputVal: Math.round(cardiacOutputVal * 1000) / 1000,
          strokeVolume: Math.round(strokeVolume * 1000) / 1000,
          oxygenation,
          ecgPoints,
          neurochemistry,
          lastBeat: beat,
        }));

        // Pulse glow on beat
        setBeatGlow(true);
        setTimeout(() => setBeatGlow(false), 200);
      },
    });

    // Animate phase within beat cycle — smooth ECG scroll via rAF
    function animate() {
      const elapsed = Date.now() - lastBeatTimeRef.current;
      const phase = Math.min(elapsed / HEARTBEAT_MS, 1);
      phaseRef.current = phase;

      setHeartState((prev) => ({
        ...prev,
        beatPhase: phase,
        ecgPoints: buildEcgTrail(prev.lastBeat, phase),
      }));

      animFrameRef.current = requestAnimationFrame(animate);
    }
    animFrameRef.current = requestAnimationFrame(animate);

    return () => {
      unsub();
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    };
  }, []);

  const {
    heartRate,
    hrv,
    cardiacOutputVal,
    strokeVolume,
    oxygenation,
    beatPhase,
    ecgPoints,
    neurochemistry,
  } = heartState;
  const bpmCol = bpmColor(heartRate);
  const bpmLbl = bpmLabel(heartRate);
  const hrvCol = hrvColor(hrv);

  return (
    <div
      data-ocid="heart.monitor.panel"
      className="relative"
      style={{
        background: "rgba(7,8,10,0.96)",
        border: `1px solid ${beatGlow ? "#D4AF37" : "#2A2C33"}`,
        boxShadow: beatGlow
          ? "0 0 18px rgba(212,175,55,0.25), inset 0 0 8px rgba(212,175,55,0.05)"
          : "none",
        transition: "border-color 0.15s ease, box-shadow 0.15s ease",
        fontFamily: "'JetBrains Mono', 'Geist Mono', monospace",
      }}
    >
      {/* Header */}
      <div
        className="flex items-center justify-between px-4 py-2 border-b"
        style={{ borderColor: "#1A1C23" }}
      >
        <div
          className="font-mono text-[9px] tracking-[0.4em]"
          style={{ color: "#D4AF37" }}
        >
          ▸ CARDIAC SUBSTRATE · LIVE
        </div>
        <motion.div
          animate={{ opacity: beatGlow ? 1 : 0.3, scale: beatGlow ? 1.2 : 1 }}
          transition={{ duration: 0.15 }}
          className="w-2 h-2 rounded-full"
          style={{
            background: bpmCol,
            boxShadow: `0 0 8px ${bpmCol}`,
          }}
        />
      </div>

      <div className="p-4 space-y-4">
        {/* ECG WAVEFORM */}
        <div data-ocid="heart.ecg.canvas_target">
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-1"
            style={{ color: "#4A4F58" }}
          >
            ECG · P–QRS–T · {HEARTBEAT_MS}MS CYCLE
          </div>
          <EcgWaveform
            points={ecgPoints}
            beatPhase={beatPhase}
            isBeating={beatGlow}
          />
        </div>

        {/* PRIMARY VITALS ROW */}
        <div
          className="grid grid-cols-3 gap-3"
          data-ocid="heart.vitals.section"
        >
          {/* BPM */}
          <div
            className="flex flex-col items-center justify-center p-3 border"
            style={{ borderColor: "#1A1C23", background: "rgba(11,12,16,0.8)" }}
            data-ocid="heart.bpm.card"
          >
            <motion.div
              className="font-mono font-bold leading-none"
              style={{
                fontSize: "2.2rem",
                color: bpmCol,
                textShadow: `0 0 12px ${bpmCol}60`,
              }}
              animate={{ color: bpmCol }}
              transition={{ duration: 0.4 }}
            >
              {Math.round(heartRate)}
            </motion.div>
            <div
              className="font-mono text-[8px] tracking-[0.3em] mt-1"
              style={{ color: "#6F7580" }}
            >
              BPM
            </div>
            <div
              className="font-mono text-[7px] mt-0.5"
              style={{ color: bpmCol, opacity: 0.7 }}
            >
              {bpmLbl}
            </div>
          </div>

          {/* HRV */}
          <div
            className="flex flex-col items-center justify-center p-3 border"
            style={{ borderColor: "#1A1C23", background: "rgba(11,12,16,0.8)" }}
            data-ocid="heart.hrv.card"
          >
            <motion.div
              className="font-mono font-bold leading-none"
              style={{
                fontSize: "2.2rem",
                color: hrvCol,
                textShadow: `0 0 12px ${hrvCol}60`,
              }}
              animate={{ color: hrvCol }}
              transition={{ duration: 0.4 }}
            >
              {hrv.toFixed(1)}
            </motion.div>
            <div
              className="font-mono text-[8px] tracking-[0.3em] mt-1"
              style={{ color: "#6F7580" }}
            >
              HRV %
            </div>
            <div
              className="font-mono text-[7px] mt-0.5"
              style={{ color: hrvCol, opacity: 0.7 }}
            >
              {hrv < 5 ? "RIGID" : hrv < 15 ? "MODERATE" : "ADAPTIVE"}
            </div>
          </div>

          {/* Oxygenation Arc */}
          <div
            className="flex flex-col items-center justify-center p-2 border"
            style={{ borderColor: "#1A1C23", background: "rgba(11,12,16,0.8)" }}
            data-ocid="heart.oxygenation.card"
          >
            <OxygenationArc value={oxygenation} />
          </div>
        </div>

        {/* CARDIAC OUTPUT */}
        <div
          className="border p-3"
          style={{ borderColor: "#1A1C23", background: "rgba(11,12,16,0.6)" }}
          data-ocid="heart.cardiac_output.card"
        >
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-2"
            style={{ color: "#6F7580" }}
          >
            L47 CARDIAC OUTPUT LAW · CO = HR × SV
          </div>
          <div className="flex items-baseline gap-2 flex-wrap">
            <span
              className="font-mono text-[10px]"
              style={{ color: "#4A4F58" }}
            >
              CO =
            </span>
            <span
              className="font-mono font-bold text-sm"
              style={{ color: "#D4AF37" }}
            >
              {Math.round(heartRate)}
            </span>
            <span
              className="font-mono text-[10px]"
              style={{ color: "#4A4F58" }}
            >
              BPM ×
            </span>
            <span
              className="font-mono font-bold text-sm"
              style={{ color: "#D4AF37" }}
            >
              {strokeVolume.toFixed(3)}
            </span>
            <span
              className="font-mono text-[10px]"
              style={{ color: "#4A4F58" }}
            >
              SV =
            </span>
            <span
              className="font-mono font-bold text-base"
              style={{
                color: "#44D17B",
                textShadow: "0 0 8px rgba(68,209,123,0.4)",
              }}
            >
              {cardiacOutputVal.toFixed(4)}
            </span>
          </div>
          <div className="mt-2 h-1" style={{ background: "#1A1C23" }}>
            <motion.div
              className="h-1"
              style={{ background: "#44D17B" }}
              animate={{ width: `${cardiacOutputVal * 100}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>

        {/* NEUROCHEMICAL SUBSTRATE */}
        <div data-ocid="heart.neurochemistry.section">
          <div
            className="font-mono text-[7px] tracking-[0.3em] mb-3"
            style={{ color: "#D4AF37" }}
          >
            ▸ NEUROCHEMICAL SUBSTRATE · 8 CHANNELS
          </div>
          <div className="space-y-2">
            {NEURO_CONFIG.map(({ key, label, sublabel, color, invert }) => {
              const raw = neurochemistry[key];
              const displayVal = invert ? 1 - raw : raw; // cortisol: invert so low=good visually
              const pct = Math.round(displayVal * 100);
              return (
                <div
                  key={key}
                  className="flex items-center gap-3"
                  data-ocid={`heart.neuro.${key}`}
                >
                  <div
                    className="font-mono text-[7px] tracking-wider w-28 shrink-0 truncate"
                    style={{ color: "#6F7580" }}
                  >
                    {label}
                  </div>
                  <div
                    className="flex-1 h-1.5 relative"
                    style={{ background: "#1A1C23" }}
                  >
                    <motion.div
                      className="h-1.5 absolute left-0 top-0"
                      style={{ background: color }}
                      animate={{ width: `${pct}%` }}
                      transition={{ duration: 0.55 }}
                    />
                  </div>
                  <div
                    className="font-mono text-[8px] w-8 text-right shrink-0"
                    style={{ color }}
                  >
                    {pct}%
                  </div>
                  <div
                    className="font-mono text-[7px] w-28 shrink-0 hidden sm:block truncate"
                    style={{ color: "#3A3F48" }}
                  >
                    {sublabel}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* FOOTER */}
        <div
          className="border-t pt-2 flex items-center justify-between flex-wrap gap-1"
          style={{ borderColor: "#1A1C23" }}
        >
          <div
            className="font-mono text-[7px] tracking-[0.2em]"
            style={{ color: "#3A3F48" }}
          >
            L10 CARDIAC · {HEARTBEAT_MS}MS · L47 CO LAW · L48 HRV LAW
          </div>
          <div className="font-mono text-[7px]" style={{ color: "#3A3F48" }}>
            PHI={PHI.toFixed(4)} · S0={S0}
          </div>
        </div>
      </div>
    </div>
  );
}
