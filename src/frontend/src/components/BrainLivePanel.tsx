import { useQuery } from "@tanstack/react-query";
import { motion } from "motion/react";
import { useEffect, useState } from "react";
import { startHeartbeat, subscribe } from "../field-substrate";
import { useActor } from "../hooks/useActor";
import { PHI_INV, PHI_INV_2, S0 } from "../phi";

const DRIVE_NAMES = [
  "SURVIVAL",
  "DOMINANCE",
  "REPRODUCTION",
  "BONDING",
  "CURIOSITY",
  "CREATION",
  "TRANSCENDENCE",
];

const SHELL_NAMES = [
  "ALPHA",
  "BETA",
  "GAMMA",
  "DELTA",
  "THETA",
  "SIGMA",
  "LAMBDA",
  "EPSILON",
  "DEEP",
  "HERITAGE",
  "OMNIS",
];

const ANIMAL_NAMES = [
  "CROW",
  "DOLPHIN",
  "HIVE",
  "ELEPHANT",
  "SHARK",
  "WOLF",
  "ORCA",
  "EAGLE",
  "OCTOPUS",
];

const NEURO_NAMES = [
  "DOPAMINE",
  "SEROTONIN",
  "NOREPINEPHRINE",
  "GABA",
  "GLUTAMATE",
  "ACETYLCHOLINE",
  "CORTISOL",
  "BDNF",
  "OXYTOCIN",
  "ENDORPHIN",
  "SUBSTANCE_P",
  "ANANDAMIDE",
  "MELATONIN",
  "THYROXINE",
  "INSULIN",
  "GLUCAGON",
  "ADRENALINE",
  "TESTOSTERONE",
  "ESTROGEN",
  "NITRIC_OXIDE",
  "VASOPRESSIN",
];

type FullState = {
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
};

type TokenBalances = {
  mth: bigint;
  gtk: bigint;
  mrc: bigint;
  cvt: bigint;
  vct: bigint;
  knt: bigint;
  sbt: bigint;
  hbt: bigint;
  drt: bigint;
  rst: bigint;
  omt: bigint;
  lgt: bigint;
};

type QuantumState = {
  parallaxAngle: number;
  entanglaIndex: number;
  bypassGate: number;
  resonexField: number;
  chronoDilation: number;
  veritasCoherence: number;
  noveltyScore: number;
};

type Territory = {
  score: number;
  stigmergy: number;
  pheromone: number;
};

// ─── Sub-components ──────────────────────────────────────────────────────────

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="font-mono text-[9px] tracking-[0.4em] mb-3"
      style={{ color: "#D6B36A" }}
    >
      {children}
    </div>
  );
}

function StatChip({
  label,
  value,
  accent = "#D6B36A",
}: {
  label: string;
  value: string | number;
  accent?: string;
}) {
  return (
    <div
      className="border px-3 py-2 flex flex-col gap-0.5 min-w-0"
      style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.9)" }}
    >
      <div className="font-mono text-[7px] tracking-[0.3em] text-[#6F7580] truncate">
        {label}
      </div>
      <div
        className="font-mono text-xs font-bold truncate"
        style={{ color: accent }}
      >
        {value}
      </div>
    </div>
  );
}

function MiniBar({
  value,
  max = 2,
  color,
  label,
  subLabel,
}: {
  value: number;
  max?: number;
  color: string;
  label: string;
  subLabel?: string;
}) {
  const pct = Math.min(100, (value / max) * 100);
  return (
    <div className="flex flex-col gap-1">
      <div
        className="font-mono text-[7px] tracking-wider truncate"
        style={{ color: "#6F7580" }}
      >
        {label}
      </div>
      <div
        className="h-1 w-full rounded-none"
        style={{ background: "#1A1C23" }}
      >
        <motion.div
          className="h-1"
          style={{ width: `${pct}%`, background: color }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.5 }}
        />
      </div>
      {subLabel && (
        <div className="font-mono text-[7px] text-[#4A4F58]">{subLabel}</div>
      )}
    </div>
  );
}

function DualBar({
  activation,
  sync,
  name,
}: {
  activation: number;
  sync: number;
  name: string;
}) {
  return (
    <div className="flex flex-col gap-0.5">
      <div className="font-mono text-[7px] tracking-wider text-[#6F7580] truncate">
        {name}
      </div>
      <div className="flex flex-col gap-0.5">
        <div className="h-1 w-full" style={{ background: "#1A1C23" }}>
          <motion.div
            className="h-1"
            style={{
              width: `${Math.min(100, activation * 100)}%`,
              background: "#D6B36A",
            }}
            animate={{ width: `${Math.min(100, activation * 100)}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
        <div className="h-1 w-full" style={{ background: "#1A1C23" }}>
          <motion.div
            className="h-1"
            style={{
              width: `${Math.min(100, sync * 100)}%`,
              background: "#2DD4BF",
            }}
            animate={{ width: `${Math.min(100, sync * 100)}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>
      </div>
      <div className="font-mono text-[7px] text-[#4A4F58]">
        A:{activation.toFixed(2)} R:{sync.toFixed(2)}
      </div>
    </div>
  );
}

function LoadingOrb() {
  return (
    <div
      className="flex flex-col items-center justify-center py-20 gap-4"
      data-ocid="brain.loading_state"
    >
      <motion.div
        animate={{ opacity: [0.2, 1, 0.2], scale: [0.95, 1.05, 0.95] }}
        transition={{ duration: 1.6, repeat: Number.POSITIVE_INFINITY }}
        className="w-3 h-3 rounded-full"
        style={{
          background: "#D6B36A",
          boxShadow: "0 0 16px rgba(214,179,106,0.6)",
        }}
      />
      <span
        className="font-mono text-[10px] tracking-[0.4em]"
        style={{ color: "#D6B36A" }}
      >
        AWAITING SOVEREIGN LINK...
      </span>
    </div>
  );
}

// ─── BRAIN MAP TYPES + CONFIG ─────────────────────────────────────────────

interface BrainRegionActivation {
  prefrontal: number; // OMNIS consensus — executive function
  amygdala: number; // cortisol/threat — urgency
  hippocampus: number; // Memory Temple — consolidation
  cerebellum: number; // pipeline timing — coordination
  basalGanglia: number; // Hebbian weights — habit
  acc: number; // AEGIS monitoring — error correction
  insula: number; // substrate self-model — interoception
  dmn: number; // autonomous background reasoning
  broca: number; // voice/language generation
  visualCortex: number; // pattern field activation
}

const BRAIN_REGIONS: Array<{
  key: keyof BrainRegionActivation;
  label: string;
  sublabel: string;
  fieldType: 1 | 2 | 3;
}> = [
  {
    key: "prefrontal",
    label: "PREFRONTAL CORTEX",
    sublabel: "OMNIS consensus · executive",
    fieldType: 1,
  },
  {
    key: "amygdala",
    label: "AMYGDALA",
    sublabel: "cortisol · threat detection",
    fieldType: 2,
  },
  {
    key: "hippocampus",
    label: "HIPPOCAMPUS",
    sublabel: "Memory Temple · consolidation",
    fieldType: 1,
  },
  {
    key: "cerebellum",
    label: "CEREBELLUM",
    sublabel: "pipeline timing · coordination",
    fieldType: 3,
  },
  {
    key: "basalGanglia",
    label: "BASAL GANGLIA",
    sublabel: "Hebbian weights · habit",
    fieldType: 1,
  },
  {
    key: "acc",
    label: "ACC",
    sublabel: "AEGIS monitoring · error corr",
    fieldType: 3,
  },
  {
    key: "insula",
    label: "INSULA",
    sublabel: "substrate self-model · intero",
    fieldType: 2,
  },
  {
    key: "dmn",
    label: "DMN",
    sublabel: "autonomous background reason",
    fieldType: 2,
  },
  {
    key: "broca",
    label: "BROCA'S AREA",
    sublabel: "voice · language generation",
    fieldType: 1,
  },
  {
    key: "visualCortex",
    label: "VISUAL CORTEX",
    sublabel: "pattern field activation",
    fieldType: 1,
  },
];

// Activation color: dark blue (low) → cyan (mid) → gold (high) → red (max)
function regionColor(activation: number): string {
  if (activation < 0.25) return "#1E3A5F"; // dark blue — dormant
  if (activation < 0.5) return "#22D3EE"; // cyan — awakening
  if (activation < 0.75) return "#D4AF37"; // gold — active
  if (activation < 0.9) return "#F59E0B"; // amber — high
  return "#EF4444"; // red — maximum
}

function regionTextColor(activation: number): string {
  if (activation < 0.25) return "#2563EB";
  if (activation < 0.5) return "#22D3EE";
  if (activation < 0.75) return "#D4AF37";
  if (activation < 0.9) return "#F59E0B";
  return "#EF4444";
}

// Simulate brain region activations from beat number + globalR
// Each region has its own phi-derived frequency — no arbitrary oscillations
function simulateBrainActivations(
  beat: number,
  r: number,
): BrainRegionActivation {
  return {
    // Prefrontal: tied to coherence — highest when organism is coherent
    prefrontal:
      S0 + (1 - S0) * r * (0.7 + 0.3 * Math.sin(beat * PHI_INV * 0.15)),
    // Amygdala: threat detector — inverse of coherence, peaks on anomaly
    amygdala:
      (1 - r) * 0.6 + 0.1 + 0.15 * Math.abs(Math.sin(beat * PHI_INV * 0.8)),
    // Hippocampus: memory — grows logarithmically with beat count (L35)
    hippocampus: Math.min(1, S0 + Math.log(1 + beat * 0.001) * PHI_INV_2),
    // Cerebellum: timing precision — oscillates fast, tied to pipeline rhythm
    cerebellum: S0 + (1 - S0) * (0.5 + 0.4 * Math.cos(beat * PHI_INV * 0.6)),
    // Basal Ganglia: habit strength — builds over time (Hebbian)
    basalGanglia: Math.min(0.95, S0 + beat * PHI_INV_2 * 0.002),
    // ACC: error monitoring — spikes when coherence drops
    acc:
      PHI_INV_2 +
      PHI_INV * (1 - r) * (0.5 + 0.5 * Math.abs(Math.sin(beat * 0.09))),
    // Insula: self-awareness — tied to substrate self-model depth
    insula: S0 * r + (1 - S0) * (0.4 + 0.3 * Math.sin(beat * PHI_INV_2 * 0.3)),
    // DMN: background — highest during low external load
    dmn: 0.3 + (1 - r) * 0.4 + 0.15 * Math.sin(beat * PHI_INV * 0.12),
    // Broca: language production — active when organism is generating output
    broca: PHI_INV_2 + PHI_INV * (0.4 + 0.4 * Math.cos(beat * PHI_INV * 0.35)),
    // Visual Cortex: pattern detection — active on every beat
    visualCortex:
      S0 + (1 - S0) * (0.5 + 0.45 * Math.abs(Math.sin(beat * PHI_INV * 0.55))),
  };
}

// ─── BRAIN MAP PANEL (appended sub-component) ─────────────────────────────

function BrainMapSection() {
  const [activations, setActivations] = useState<BrainRegionActivation>(
    simulateBrainActivations(0, S0),
  );

  useEffect(() => {
    startHeartbeat();
    const unsub = subscribe({
      id: "BRAIN_MAP_PANEL",
      fieldType: 2,
      fn: (beat: number, globalR: number) => {
        setActivations(simulateBrainActivations(beat, globalR));
      },
    });
    return () => {
      unsub();
    };
  }, []);

  return (
    <section
      className="relative z-10 border p-4"
      style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      data-ocid="brain.map.section"
    >
      <div
        className="font-mono text-[9px] tracking-[0.4em] mb-4"
        style={{ color: "#D6B36A" }}
      >
        ▸ BRAIN MAP · 10 REGION ACTIVATION HEATMAP
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
        {BRAIN_REGIONS.map(({ key, label, sublabel }, idx) => {
          const activation = activations[key];
          const pct = Math.round(activation * 100);
          const col = regionColor(activation);
          const textCol = regionTextColor(activation);

          return (
            <motion.div
              key={key}
              className="flex flex-col gap-2 p-3 border"
              style={{
                borderColor: activation > 0.75 ? col : "#1E2026",
                background:
                  activation > 0.75
                    ? activation > 0.9
                      ? "rgba(239,68,68,0.04)"
                      : "rgba(212,175,55,0.04)"
                    : "rgba(7,8,10,0.8)",
                boxShadow:
                  activation > 0.9
                    ? "0 0 12px rgba(239,68,68,0.15)"
                    : activation > 0.75
                      ? "0 0 8px rgba(212,175,55,0.1)"
                      : "none",
              }}
              animate={{
                borderColor: activation > 0.75 ? col : "#1E2026",
              }}
              transition={{ duration: 0.4 }}
              data-ocid={`brain.map.region.${idx + 1}`}
            >
              {/* Region label */}
              <div className="flex items-center justify-between gap-1">
                <div
                  className="font-mono text-[7px] tracking-wider truncate"
                  style={{ color: textCol }}
                >
                  {label}
                </div>
                <motion.div
                  className="font-mono text-[9px] font-bold shrink-0"
                  style={{ color: textCol }}
                  animate={{ color: textCol }}
                  transition={{ duration: 0.3 }}
                >
                  {pct}%
                </motion.div>
              </div>

              {/* Activation bar */}
              <div
                className="w-full relative"
                style={{ height: "6px", background: "#1A1C23" }}
              >
                <motion.div
                  className="absolute left-0 top-0 h-full"
                  style={{ background: col }}
                  animate={{ width: `${pct}%`, background: col }}
                  transition={{ duration: 0.5 }}
                />
                {/* Glow at tip when high */}
                {activation > 0.75 && (
                  <motion.div
                    className="absolute top-0 h-full w-1"
                    style={{
                      left: `${Math.max(0, pct - 1)}%`,
                      background: col,
                      filter: "blur(2px) brightness(2)",
                    }}
                    animate={{ left: `${Math.max(0, pct - 1)}%` }}
                    transition={{ duration: 0.5 }}
                  />
                )}
              </div>

              {/* Sublabel */}
              <div
                className="font-mono text-[6px] tracking-wide leading-tight"
                style={{ color: "#3A3F48" }}
              >
                {sublabel}
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Legend */}
      <div className="flex gap-4 mt-4 flex-wrap">
        {[
          { color: "#1E3A5F", label: "DORMANT < 25%" },
          { color: "#22D3EE", label: "AWAKENING 25–50%" },
          { color: "#D4AF37", label: "ACTIVE 50–75%" },
          { color: "#F59E0B", label: "HIGH 75–90%" },
          { color: "#EF4444", label: "MAX > 90%" },
        ].map(({ color, label }) => (
          <div key={label} className="flex items-center gap-1.5">
            <div className="w-3 h-1.5" style={{ background: color }} />
            <span
              className="font-mono text-[7px] tracking-wider"
              style={{ color: "#6F7580" }}
            >
              {label}
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}

export function BrainLivePanel() {
  const { actor, isFetching } = useActor();
  const px = actor as unknown as Record<
    string,
    (...args: unknown[]) => Promise<unknown>
  >;
  const enabled = !!actor && !isFetching;

  const { data: fullState } = useQuery<FullState | null>({
    queryKey: ["brain_fullState"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getFullState?.()) as FullState) ?? null;
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: shellActivations } = useQuery<number[]>({
    queryKey: ["brain_shellActivations"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getShellActivations?.()) as number[]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: shellR } = useQuery<number[]>({
    queryKey: ["brain_shellR"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getShellR?.()) as number[]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: animalSignals } = useQuery<number[]>({
    queryKey: ["brain_animalSignals"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getAnimalSignals?.()) as number[]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: drives } = useQuery<[string, number][]>({
    queryKey: ["brain_drives"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getDrives?.()) as [string, number][]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: tokenBalances } = useQuery<TokenBalances | null>({
    queryKey: ["brain_tokenBalances"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getTokenBalances?.()) as TokenBalances) ?? null;
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: quantumState } = useQuery<QuantumState | null>({
    queryKey: ["brain_quantumState"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getQuantumState?.()) as QuantumState) ?? null;
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: territory } = useQuery<Territory | null>({
    queryKey: ["brain_territory"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getTerritory?.()) as Territory) ?? null;
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: neurochemicals } = useQuery<number[]>({
    queryKey: ["brain_neurochemicals"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getNeurochemicals?.()) as number[]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  const { data: profitTotals } = useQuery<number[]>({
    queryKey: ["brain_profitTotals"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getProfitTotals?.()) as number[]) ?? [];
    },
    enabled,
    refetchInterval: 3000,
  });

  if (!actor || isFetching) return <LoadingOrb />;

  const beat = fullState ? Number(fullState.beat) : 0;
  const coherence = fullState?.coherence ?? 0;
  const forma = fullState?.formaCapital ?? 0;
  const dominantIdx = fullState ? Number(fullState.dominantDrive) : 0;
  const dominantName = DRIVE_NAMES[dominantIdx] ?? "UNKNOWN";
  const regime = fullState?.regime ?? "—";
  const lawScore = fullState?.lawScore ?? 0;
  const aresArmed = fullState?.aresArmed ?? false;
  const novaHealth = fullState?.novaHealth ?? 0;

  const maxDriveStrength =
    drives && drives.length > 0 ? Math.max(...drives.map((d) => d[1])) : 1;

  const maxProfit =
    profitTotals && profitTotals.length > 0 ? Math.max(...profitTotals, 1) : 1;

  return (
    <div
      className="space-y-6"
      data-ocid="brain.panel"
      style={{ fontFamily: "'JetBrains Mono', 'Geist Mono', monospace" }}
    >
      {/* Grid overlay background */}
      <div
        className="fixed inset-0 pointer-events-none opacity-30"
        style={{
          backgroundImage:
            "linear-gradient(rgba(214,179,106,0.025) 1px, transparent 1px), linear-gradient(90deg, rgba(214,179,106,0.025) 1px, transparent 1px)",
          backgroundSize: "32px 32px",
          zIndex: 0,
        }}
      />

      {/* A. ORGANISM STATUS BAR */}
      <section className="relative z-10">
        <SectionLabel>▸ ORGANISM STATUS · LIVE FEED</SectionLabel>
        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-2">
          <StatChip
            label="BEAT"
            value={beat.toLocaleString()}
            accent="#D6B36A"
          />
          <StatChip
            label="COHERENCE"
            value={`${(coherence * 100).toFixed(2)}%`}
            accent="#44D17B"
          />
          <StatChip label="FORMA" value={forma.toFixed(2)} accent="#D6B36A" />
          <StatChip label="DRIVE" value={dominantName} accent="#A78BFA" />
          <StatChip
            label="REGIME"
            value={regime}
            accent={
              regime === "BULL"
                ? "#44D17B"
                : regime === "BEAR"
                  ? "#C23B55"
                  : "#D6A83A"
            }
          />
          <StatChip
            label="LAW SCORE"
            value={`${(lawScore * 100).toFixed(1)}%`}
            accent="#D6B36A"
          />
          <StatChip
            label="ARES"
            value={aresArmed ? "ARMED" : "SAFE"}
            accent={aresArmed ? "#C23B55" : "#44D17B"}
          />
          <StatChip
            label="NOVA HEALTH"
            value={`${(novaHealth * 100).toFixed(1)}%`}
            accent="#44D17B"
          />
        </div>
      </section>

      {/* B. NEURAL SHELLS */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
        data-ocid="brain.section"
      >
        <SectionLabel>▸ NEURAL SHELLS · ACTIVATION + KURAMOTO R</SectionLabel>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
          {SHELL_NAMES.map((name, i) => (
            <DualBar
              key={name}
              name={name}
              activation={shellActivations?.[i] ?? 0}
              sync={shellR?.[i] ?? 0}
            />
          ))}
        </div>
        <div className="flex gap-4 mt-3">
          <div className="flex items-center gap-1.5">
            <div className="w-3 h-1" style={{ background: "#D6B36A" }} />
            <span className="font-mono text-[7px] text-[#6F7580] tracking-wider">
              ACTIVATION
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <div className="w-3 h-1" style={{ background: "#2DD4BF" }} />
            <span className="font-mono text-[7px] text-[#6F7580] tracking-wider">
              SYNCHRONY R
            </span>
          </div>
        </div>
      </section>

      {/* C. ANIMAL ENGINES */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ ANIMAL ENGINES · 9 SIGNAL CHANNELS</SectionLabel>
        <div className="grid grid-cols-3 md:grid-cols-5 lg:grid-cols-9 gap-3">
          {ANIMAL_NAMES.map((name, i) => {
            const val = animalSignals?.[i] ?? 0;
            const color =
              val > 1.5 ? "#C23B55" : val > 1.0 ? "#D6B36A" : "#44D17B";
            return (
              <MiniBar
                key={name}
                label={name}
                value={val}
                max={2}
                color={color}
                subLabel={val.toFixed(2)}
              />
            );
          })}
        </div>
      </section>

      {/* D. SOVEREIGN DRIVES */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ SOVEREIGN DRIVES · COMPETITION ENGINE</SectionLabel>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {(drives && drives.length > 0
            ? drives
            : DRIVE_NAMES.map((n) => [n, 0] as [string, number])
          ).map(([name, strength], i) => {
            const isDominant = i === dominantIdx;
            const pct = Math.min(
              100,
              (strength / Math.max(maxDriveStrength, 1)) * 100,
            );
            return (
              <div
                key={name}
                className="flex flex-col gap-1 p-2 border"
                style={{
                  borderColor: isDominant ? "#A78BFA" : "#1E2026",
                  background: isDominant
                    ? "rgba(167,139,250,0.04)"
                    : "transparent",
                }}
              >
                <div
                  className="font-mono text-[8px] tracking-wider"
                  style={{ color: isDominant ? "#A78BFA" : "#6F7580" }}
                >
                  {name}
                  {isDominant && " ◆"}
                </div>
                <div className="h-1" style={{ background: "#1A1C23" }}>
                  <motion.div
                    className="h-1"
                    style={{
                      width: `${pct}%`,
                      background: isDominant ? "#A78BFA" : "#6F7580",
                    }}
                    animate={{ width: `${pct}%` }}
                    transition={{ duration: 0.5 }}
                  />
                </div>
                <div className="font-mono text-[8px] text-[#4A4F58]">
                  {typeof strength === "number" ? strength.toFixed(3) : "—"}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* E. TOKEN BALANCES */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ TOKEN BALANCES · 12 ICRC-1 SOVEREIGNS</SectionLabel>
        {tokenBalances ? (
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-12 gap-2">
            {(Object.entries(tokenBalances) as [string, bigint][]).map(
              ([name, bal]) => (
                <div
                  key={name}
                  className="border p-2 flex flex-col gap-0.5"
                  style={{
                    borderColor: "#2A2C33",
                    background: "rgba(7,8,10,0.8)",
                  }}
                >
                  <div className="font-mono text-[7px] tracking-[0.2em] text-[#6F7580]">
                    {name.toUpperCase()}
                  </div>
                  <div
                    className="font-mono text-[10px] font-bold"
                    style={{ color: "#D6B36A" }}
                  >
                    {Number(bal).toLocaleString()}
                  </div>
                </div>
              ),
            )}
          </div>
        ) : (
          <div className="font-mono text-[9px] text-[#4A4F58] tracking-widest">
            NO TOKEN DATA
          </div>
        )}
      </section>

      {/* F. QUANTUM STATE */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ QUANTUM OPERATORS · 7 ACTIVE FIELDS</SectionLabel>
        {quantumState ? (
          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-2">
            {(
              [
                ["PARALLAX Φ", quantumState.parallaxAngle],
                ["ENTANGLA E", quantumState.entanglaIndex],
                ["BYPASS β", quantumState.bypassGate],
                ["RESONEX Ψ", quantumState.resonexField],
                ["CHRONO τ", quantumState.chronoDilation],
                ["VERITAS V", quantumState.veritasCoherence],
                ["NOVELTY Z", quantumState.noveltyScore],
              ] as [string, number][]
            ).map(([label, val]) => (
              <div
                key={label}
                className="border p-2 flex flex-col gap-1"
                style={{
                  borderColor: "#2A2C33",
                  background: "rgba(7,8,10,0.8)",
                }}
              >
                <div className="font-mono text-[7px] tracking-wider text-[#6F7580]">
                  {label}
                </div>
                <div
                  className="font-mono text-xs font-bold"
                  style={{
                    color:
                      val > 1.5 ? "#C23B55" : val > 1.0 ? "#D6B36A" : "#44D17B",
                  }}
                >
                  {val.toFixed(4)}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="font-mono text-[9px] text-[#4A4F58] tracking-widest">
            NO QUANTUM DATA
          </div>
        )}
      </section>

      {/* G. TERRITORY */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ TERRITORY ENGINE</SectionLabel>
        {territory ? (
          <div className="grid grid-cols-3 gap-3">
            {(
              [
                ["SCORE", territory.score],
                ["STIGMERGY", territory.stigmergy],
                ["PHEROMONE", territory.pheromone],
              ] as [string, number][]
            ).map(([label, val]) => (
              <div
                key={label}
                className="border p-3 flex flex-col gap-1"
                style={{
                  borderColor: "#2A2C33",
                  background: "rgba(7,8,10,0.8)",
                }}
              >
                <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
                  {label}
                </div>
                <div
                  className="font-mono text-sm font-bold"
                  style={{ color: "#44D17B" }}
                >
                  {val.toFixed(4)}
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="font-mono text-[9px] text-[#4A4F58] tracking-widest">
            NO TERRITORY DATA
          </div>
        )}
      </section>

      {/* H. NEUROCHEMICALS */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ NEUROCHEMICAL SUBSTRATE · 21 CHANNELS</SectionLabel>
        <div className="grid grid-cols-3 sm:grid-cols-5 md:grid-cols-7 gap-2">
          {NEURO_NAMES.map((name, i) => {
            const val = neurochemicals?.[i] ?? 0;
            const color =
              val > 1.8 ? "#C23B55" : val > 1.2 ? "#D6B36A" : "#44D17B";
            return (
              <div key={name} className="flex flex-col gap-0.5">
                <div
                  className="font-mono text-[6px] tracking-wider truncate"
                  style={{ color: "#4A4F58" }}
                >
                  {name}
                </div>
                <div className="h-1" style={{ background: "#1A1C23" }}>
                  <motion.div
                    className="h-1"
                    style={{
                      width: `${Math.min(100, (val / 2) * 100)}%`,
                      background: color,
                    }}
                    animate={{ width: `${Math.min(100, (val / 2) * 100)}%` }}
                    transition={{ duration: 0.5 }}
                  />
                </div>
                <div className="font-mono text-[7px]" style={{ color }}>
                  {val.toFixed(2)}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* I. PROFIT TOTALS */}
      <section
        className="relative z-10 border p-4"
        style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.7)" }}
      >
        <SectionLabel>▸ PROFIT STREAMS · S1–S22</SectionLabel>
        <div className="grid grid-cols-4 sm:grid-cols-7 md:grid-cols-11 lg:grid-cols-22 gap-2">
          {Array.from({ length: 22 }, (_, i) => {
            const val = profitTotals?.[i] ?? 0;
            const pct = Math.min(100, (val / maxProfit) * 100);
            const color = val > 0 ? "#44D17B" : "#2A2C33";
            return (
              <div
                key={`s${i + 1}`}
                className="flex flex-col items-center gap-1"
              >
                <div
                  className="w-full"
                  style={{
                    height: "40px",
                    background: "#1A1C23",
                    position: "relative",
                  }}
                >
                  <motion.div
                    style={{
                      position: "absolute",
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: `${pct}%`,
                      background: color,
                    }}
                    animate={{ height: `${pct}%` }}
                    transition={{ duration: 0.5 }}
                  />
                </div>
                <div className="font-mono text-[6px] text-[#4A4F58]">
                  S{i + 1}
                </div>
                <div
                  className="font-mono text-[6px]"
                  style={{ color: val > 0 ? "#44D17B" : "#2A2C33" }}
                >
                  {val.toFixed(1)}
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Footer */}
      <div className="border-t border-[#1A1C23] pt-4 relative z-10">
        <div className="font-mono text-[8px] tracking-[0.25em] text-[#3A3F48] text-center">
          BRAIN LIVE · REFETCH INTERVAL 3S · MEDINA DOCTRINE · ALFREDO MEDINA
          HERNANDEZ
        </div>
      </div>

      {/* J. BRAIN MAP — 10 Region Activation Heatmap */}
      <BrainMapSection />
    </div>
  );
}
