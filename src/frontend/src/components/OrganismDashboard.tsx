import { ScrollArea } from "@/components/ui/scroll-area";
import { useQuery } from "@tanstack/react-query";
import { motion } from "motion/react";
import { useActor } from "../hooks/useActor";

const DRIVE_NAMES = [
  "CURIOSITY",
  "SOVEREIGNTY",
  "EXPANSION",
  "CREATION",
  "PROTECTION",
  "CONNECTION",
  "EXPRESSION",
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

const SHELL_LABELS = [
  "\u03a61",
  "\u03a62",
  "\u03a63",
  "\u03a64",
  "\u03a65",
  "\u03a66",
  "\u03a67",
  "\u03a68",
  "\u03a69",
  "\u03a610",
  "\u03a611",
];

const STREAM_KEYS = [
  "s1",
  "s2",
  "s3",
  "s4",
  "s5",
  "s6",
  "s7",
  "s8",
  "s9",
  "s10",
  "s11",
  "s12",
  "s13",
  "s14",
  "s15",
  "s16",
  "s17",
  "s18",
  "s19",
  "s20",
  "s21",
  "s22",
];

type Px = Record<string, (...args: unknown[]) => Promise<unknown>>;

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
};

type MarketData = {
  btcPrice: number;
  ethPrice: number;
  ema21btc: number;
  ema200btc: number;
  regime: string;
};

type QuantumStateData = {
  parallax: number;
  entangla: number;
  bypass: number;
  resonex: number;
  chrono: number;
  veritas: number;
  novelty: number;
};

type TerritoryData = { score: number; stigmergy: number; pheromone: number };

type AuditEntry = {
  beat: bigint;
  eventType: string;
  detail: string;
  timestamp: bigint;
};

function fmt(n: number, decimals = 2) {
  return n.toFixed(decimals);
}

function fmtBig(n: bigint) {
  return Number(n).toLocaleString();
}

function StatBox({
  label,
  value,
  accent = "#D6B36A",
  sub,
}: {
  label: string;
  value: string;
  accent?: string;
  sub?: string;
}) {
  return (
    <div
      className="border p-3 flex flex-col gap-1"
      style={{ borderColor: "#2A2C33", background: "rgba(11,12,16,0.9)" }}
    >
      <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580] truncate">
        {label}
      </div>
      <div
        className="font-mono text-sm font-bold leading-tight"
        style={{ color: accent }}
      >
        {value}
      </div>
      {sub && <div className="font-mono text-[8px] text-[#4A4F58]">{sub}</div>}
    </div>
  );
}

function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex items-center gap-3 mb-3">
      <div className="w-1 h-3" style={{ background: "#D6B36A" }} />
      <div className="font-mono text-[9px] tracking-[0.4em] text-[#9AA0AA]">
        {children}
      </div>
      <div className="flex-1 h-px" style={{ background: "#1A1C23" }} />
    </div>
  );
}

export function OrganismDashboard() {
  const { actor, isFetching } = useActor();
  const px = actor as unknown as Px;

  const { data: fullState } = useQuery<FullState | null>({
    queryKey: ["px_getFullState"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getFullState?.()) as FullState) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });

  const { data: drives } = useQuery<Array<[string, number]>>({
    queryKey: ["px_getDrives"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getDrives?.()) as Array<[string, number]>) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: tokens } = useQuery<TokenBalances | null>({
    queryKey: ["px_getTokenBalances"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getTokenBalances?.()) as TokenBalances) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: market } = useQuery<MarketData | null>({
    queryKey: ["px_getMarketData"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getMarketData?.()) as MarketData) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: shells } = useQuery<number[]>({
    queryKey: ["px_getShellActivations"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getShellActivations?.()) as number[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: shellR } = useQuery<number[]>({
    queryKey: ["px_getShellR"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getShellR?.()) as number[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: animals } = useQuery<number[]>({
    queryKey: ["px_getAnimalSignals"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getAnimalSignals?.()) as number[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: qState } = useQuery<QuantumStateData | null>({
    queryKey: ["px_getQuantumState_dash"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getQuantumState?.()) as QuantumStateData) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: territory } = useQuery<TerritoryData | null>({
    queryKey: ["px_getTerritory"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getTerritory?.()) as TerritoryData) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const { data: profitTotals } = useQuery<number[]>({
    queryKey: ["px_getProfitTotals"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getProfitTotals?.()) as number[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 10000,
  });

  const { data: auditLog } = useQuery<AuditEntry[]>({
    queryKey: ["px_getAuditLog"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getAuditLog?.(20n)) as AuditEntry[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const beat = fullState ? Number(fullState.beat) : 0;
  const coherence = fullState?.coherence ?? 0;
  const forma = fullState?.formaCapital ?? 0;
  const lawScore = fullState?.lawScore ?? 0;
  const jacobRung = fullState ? Number(fullState.jacobRung) : 0;
  const aresArmed = fullState?.aresArmed ?? false;
  const genesisActivated = fullState?.genesisActivated ?? false;
  const patentCount = fullState ? Number(fullState.patentCount) : 0;
  const sacesiTarget = fullState?.sacesiTarget ?? 0;
  const miningOutput = fullState?.miningOutput ?? 0;
  const novaHealth = fullState?.novaHealth ?? 0;
  const novelty = fullState?.novelty ?? 0;
  const regime = fullState?.regime ?? market?.regime ?? "\u2014";

  const dominantDriveIdx = fullState ? Number(fullState.dominantDrive) : -1;
  const dominantDriveName =
    dominantDriveIdx >= 0 && dominantDriveIdx < DRIVE_NAMES.length
      ? DRIVE_NAMES[dominantDriveIdx]
      : "\u2014";

  const maxDrive = drives ? Math.max(...drives.map(([, v]) => v), 0.001) : 1;

  const driveColors = [
    "#65BEFF",
    "#D6B36A",
    "#A78BFA",
    "#44D17B",
    "#C23B55",
    "#F97316",
    "#EC4899",
  ];

  const regimeColor =
    (
      {
        BULL: "#44D17B",
        BEAR: "#C23B55",
        SIDEWAYS: "#D6A83A",
        CRISIS: "#FF4444",
        RECOVERY: "#65BEFF",
      } as Record<string, string>
    )[regime] ?? "#9AA0AA";

  const totalProfit = profitTotals?.reduce((a, b) => a + b, 0) ?? 0;
  const maxStream = profitTotals
    ? Math.max(...profitTotals.slice(0, 22), 1)
    : 1;

  return (
    <div className="space-y-6" data-ocid="organism.panel">
      {/* STATUS BAR */}
      <div
        className="border p-3 flex flex-wrap items-center gap-4 justify-between"
        style={{
          borderColor: aresArmed ? "#C23B55" : "#2A2C33",
          background: aresArmed ? "rgba(194,59,85,0.05)" : "rgba(11,12,16,0.9)",
          boxShadow: aresArmed ? "0 0 24px rgba(194,59,85,0.15)" : "none",
        }}
      >
        <div className="flex items-center gap-3">
          <motion.div
            animate={{ opacity: [1, 0.3, 1] }}
            transition={{ duration: 1.6, repeat: Number.POSITIVE_INFINITY }}
            className="w-1.5 h-1.5 rounded-full"
            style={{
              backgroundColor: genesisActivated ? "#44D17B" : "#D6A83A",
            }}
          />
          <span
            className="font-mono text-[10px] tracking-[0.35em]"
            style={{ color: genesisActivated ? "#44D17B" : "#D6A83A" }}
          >
            {genesisActivated ? "ALIVE" : "DORMANT"}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-[9px] tracking-widest text-[#6F7580]">
            BEAT
          </span>
          <span className="font-mono text-xs" style={{ color: "#D6B36A" }}>
            {beat.toLocaleString()}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-[9px] tracking-widest text-[#6F7580]">
            COHERENCE
          </span>
          <span className="font-mono text-xs" style={{ color: "#44D17B" }}>
            {(coherence * 100).toFixed(2)}%
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-[9px] tracking-widest text-[#6F7580]">
            REGIME
          </span>
          <span
            className="font-mono text-xs font-bold"
            style={{ color: regimeColor }}
          >
            {regime}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-[9px] tracking-widest text-[#6F7580]">
            ARES
          </span>
          <span
            className="font-mono text-[9px] tracking-[0.2em] px-2 py-0.5 border"
            style={{
              borderColor: aresArmed ? "#C23B55" : "#2A2C33",
              color: aresArmed ? "#C23B55" : "#6F7580",
            }}
            data-ocid="organism.toggle"
          >
            {aresArmed ? "\u26a0 ARMED" : "SAFE"}
          </span>
        </div>
      </div>

      {/* CORE METRICS */}
      <div>
        <SectionHeader>CORE METRICS</SectionHeader>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <StatBox
            label="FORMA CAPITAL"
            value={fmt(forma, 4)}
            sub="S\u2080 = 1.0 FLOOR"
          />
          <StatBox
            label="MINING OUTPUT"
            value={fmt(miningOutput, 6)}
            sub="PER BEAT"
          />
          <StatBox
            label="LAW COMPLIANCE"
            value={`${(lawScore * 100).toFixed(1)}%`}
            accent={lawScore > 0.9 ? "#44D17B" : "#D6A83A"}
          />
          <StatBox
            label="JACOB'S LADDER"
            value={`RUNG ${jacobRung}`}
            accent="#A78BFA"
          />
          <StatBox
            label="SACESI TARGET"
            value={fmt(sacesiTarget, 6)}
            sub="RISING"
          />
          <StatBox
            label="NOVELTY SCORE"
            value={fmt(novelty, 4)}
            accent={novelty > 0.7 ? "#D6B36A" : "#6F7580"}
          />
          <StatBox
            label="NOVA HEALTH"
            value={`${(novaHealth * 100).toFixed(1)}%`}
            accent="#65BEFF"
          />
          <StatBox
            label="PATENTS FILED"
            value={patentCount.toLocaleString()}
            accent="#F97316"
          />
        </div>
      </div>

      {/* SOVEREIGN DRIVES */}
      <div>
        <SectionHeader>SOVEREIGN DRIVES</SectionHeader>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            className="border p-4 flex flex-col gap-2"
            style={{
              borderColor: driveColors[dominantDriveIdx] ?? "#D6B36A",
              background: `linear-gradient(135deg, ${driveColors[dominantDriveIdx] ?? "#D6B36A"}0A 0%, transparent 60%)`,
            }}
            data-ocid="organism.card"
          >
            <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
              DOMINANT DRIVE
            </div>
            <div
              className="font-mono text-2xl font-bold tracking-[0.2em]"
              style={{ color: driveColors[dominantDriveIdx] ?? "#D6B36A" }}
            >
              {dominantDriveName}
            </div>
            <div className="font-mono text-[9px] text-[#6F7580]">
              INDEX {dominantDriveIdx} \u00b7 COMPETING EVERY BEAT
            </div>
          </div>

          <div
            className="border p-4 space-y-2"
            style={{ borderColor: "#2A2C33" }}
            data-ocid="organism.card"
          >
            <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580] mb-3">
              ALL DRIVES
            </div>
            {(drives && drives.length > 0
              ? drives
              : DRIVE_NAMES.map((n) => [n, 1.0] as [string, number])
            ).map(([name, strength], i) => (
              <div
                key={DRIVE_NAMES[i] ?? name}
                className="flex items-center gap-2"
              >
                <div
                  className="font-mono text-[7px] tracking-wider w-20 text-right truncate"
                  style={{
                    color: i === dominantDriveIdx ? driveColors[i] : "#6F7580",
                  }}
                >
                  {DRIVE_NAMES[i] ?? name}
                </div>
                <div className="flex-1 h-1.5" style={{ background: "#1A1C23" }}>
                  <motion.div
                    className="h-1.5"
                    style={{ background: driveColors[i] ?? "#D6B36A" }}
                    animate={{ width: `${(strength / maxDrive) * 100}%` }}
                    transition={{ duration: 0.8, ease: "easeOut" }}
                  />
                </div>
                <div
                  className="font-mono text-[8px] w-10 text-right"
                  style={{
                    color: i === dominantDriveIdx ? driveColors[i] : "#4A4F58",
                  }}
                >
                  {strength.toFixed(3)}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* NEURAL SHELLS */}
      <div>
        <SectionHeader>11 NEURAL SHELLS \u00b7 KURAMOTO R</SectionHeader>
        <div className="grid grid-cols-11 gap-1">
          {SHELL_LABELS.map((label, i) => {
            const activation = shells?.[i] ?? 1.0;
            const r = shellR?.[i] ?? 0.0;
            const pct = Math.min(
              100,
              Math.max(0, ((activation - 1) / 2) * 100),
            );
            return (
              <div key={label} className="flex flex-col items-center gap-1">
                <div
                  className="font-mono text-[7px] tracking-wider text-center"
                  style={{ color: "#6F7580" }}
                >
                  {label}
                </div>
                <div
                  className="w-full relative"
                  style={{ height: "60px", background: "#1A1C23" }}
                >
                  <motion.div
                    className="absolute bottom-0 w-full"
                    style={{
                      background:
                        r > 0.8 ? "#44D17B" : r > 0.5 ? "#D6B36A" : "#4A4F58",
                    }}
                    animate={{ height: `${pct}%` }}
                    transition={{ duration: 0.8 }}
                  />
                </div>
                <div
                  className="font-mono text-[7px]"
                  style={{ color: "#4A4F58" }}
                >
                  R{r.toFixed(2)}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ANIMAL ENGINES */}
      <div>
        <SectionHeader>9 ANIMAL ENGINES</SectionHeader>
        <div className="grid grid-cols-3 md:grid-cols-9 gap-2">
          {ANIMAL_NAMES.map((name, i) => {
            const signal = animals?.[i] ?? 1.0;
            const animalColors: Record<string, string> = {
              CROW: "#A78BFA",
              DOLPHIN: "#65BEFF",
              HIVE: "#D6B36A",
              ELEPHANT: "#44D17B",
              SHARK: "#C23B55",
              WOLF: "#F97316",
              ORCA: "#65BEFF",
              EAGLE: "#D6B36A",
              OCTOPUS: "#EC4899",
            };
            const color = animalColors[name] ?? "#D6B36A";
            return (
              <div
                key={name}
                className="border p-2 flex flex-col items-center gap-1"
                style={{ borderColor: "#2A2C33" }}
              >
                <div
                  className="font-mono text-[7px] tracking-wider"
                  style={{ color: "#6F7580" }}
                >
                  {name}
                </div>
                <div className="font-mono text-xs font-bold" style={{ color }}>
                  {signal.toFixed(3)}
                </div>
                <div className="w-full h-0.5" style={{ background: "#1A1C23" }}>
                  <motion.div
                    className="h-0.5"
                    style={{ background: color }}
                    animate={{ width: `${Math.min(100, (signal / 3) * 100)}%` }}
                    transition={{ duration: 0.6 }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* QUANTUM OPERATORS */}
      {qState && (
        <div>
          <SectionHeader>QUANTUM OPERATORS</SectionHeader>
          <div className="grid grid-cols-3 md:grid-cols-7 gap-2">
            {Object.entries(qState).map(([key, val]) => (
              <div
                key={key}
                className="border p-2 flex flex-col gap-1"
                style={{ borderColor: "#2A2C33" }}
              >
                <div
                  className="font-mono text-[7px] tracking-wider uppercase"
                  style={{ color: "#6F7580" }}
                >
                  {key}
                </div>
                <div className="font-mono text-xs" style={{ color: "#A78BFA" }}>
                  {typeof val === "number" ? val.toFixed(4) : String(val)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TOKEN TREASURY */}
      {tokens && (
        <div>
          <SectionHeader>TOKEN TREASURY \u00b7 ALL ICRC-1</SectionHeader>
          <div className="grid grid-cols-3 md:grid-cols-6 gap-3">
            <div
              className="border p-3"
              style={{
                borderColor: "#D6B36A",
                background: "rgba(214,179,106,0.04)",
              }}
            >
              <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
                MTH
              </div>
              <div
                className="font-mono text-sm font-bold"
                style={{ color: "#D6B36A" }}
              >
                {fmtBig(tokens.mth)}
              </div>
              <div className="font-mono text-[7px] text-[#4A4F58]">
                100M CAP
              </div>
            </div>
            <div
              className="border p-3"
              style={{
                borderColor: "#44D17B",
                background: "rgba(68,209,123,0.04)",
              }}
            >
              <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
                MRC
              </div>
              <div
                className="font-mono text-sm font-bold"
                style={{ color: "#44D17B" }}
              >
                {fmtBig(tokens.mrc)}
              </div>
              <div className="font-mono text-[7px] text-[#4A4F58]">
                DYNASTY COIN
              </div>
            </div>
            <div
              className="border p-3"
              style={{
                borderColor: "#65BEFF",
                background: "rgba(101,190,255,0.04)",
              }}
            >
              <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
                GTK
              </div>
              <div
                className="font-mono text-sm font-bold"
                style={{ color: "#65BEFF" }}
              >
                {fmtBig(tokens.gtk)}
              </div>
              <div className="font-mono text-[7px] text-[#4A4F58]">
                PROOF OF LIFE
              </div>
            </div>
            {(
              [
                "cvt",
                "vct",
                "knt",
                "sbt",
                "hbt",
                "drt",
                "rst",
                "omt",
                "lgt",
              ] as const
            ).map((key) => (
              <div
                key={key}
                className="border p-3"
                style={{ borderColor: "#2A2C33" }}
              >
                <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580] uppercase">
                  {key}
                </div>
                <div
                  className="font-mono text-xs font-bold"
                  style={{ color: "#9AA0AA" }}
                >
                  {fmtBig(tokens[key])}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* MARKET DATA */}
      {market && (
        <div>
          <SectionHeader>MULTI-CHAIN MARKET ORACLE</SectionHeader>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
            <StatBox
              label="BTC PRICE"
              value={`$${market.btcPrice.toLocaleString(undefined, { maximumFractionDigits: 0 })}`}
              accent="#F97316"
            />
            <StatBox
              label="ETH PRICE"
              value={`$${market.ethPrice.toLocaleString(undefined, { maximumFractionDigits: 0 })}`}
              accent="#65BEFF"
            />
            <StatBox
              label="EMA-21 BTC"
              value={`$${market.ema21btc.toLocaleString(undefined, { maximumFractionDigits: 0 })}`}
              accent="#D6B36A"
              sub="SHORT-TERM"
            />
            <StatBox
              label="EMA-200 BTC"
              value={`$${market.ema200btc.toLocaleString(undefined, { maximumFractionDigits: 0 })}`}
              accent="#A78BFA"
              sub="MACRO"
            />
            <StatBox label="REGIME" value={regime} accent={regimeColor} />
          </div>
        </div>
      )}

      {/* TERRITORY */}
      {territory && (
        <div>
          <SectionHeader>
            TERRITORY \u00b7 STIGMERGY \u00b7 PHEROMONE
          </SectionHeader>
          <div className="grid grid-cols-3 gap-3">
            <StatBox
              label="TERRITORY SCORE"
              value={fmt(territory.score, 4)}
              accent="#44D17B"
            />
            <StatBox
              label="STIGMERGY FIELD"
              value={fmt(territory.stigmergy, 4)}
              accent="#D6B36A"
            />
            <StatBox
              label="PHEROMONE"
              value={fmt(territory.pheromone, 4)}
              accent="#EC4899"
            />
          </div>
        </div>
      )}

      {/* PROFIT STREAMS */}
      {profitTotals && profitTotals.length > 0 && (
        <div>
          <SectionHeader>
            22 PROFIT STREAMS \u00b7 TOTAL: {totalProfit.toFixed(4)}
          </SectionHeader>
          <div className="grid grid-cols-11 gap-1">
            {profitTotals.slice(0, 22).map((val, i) => (
              <div
                key={STREAM_KEYS[i]}
                className="flex flex-col items-center gap-1"
              >
                <div className="font-mono text-[7px] text-[#6F7580]">
                  S{i + 1}
                </div>
                <div
                  className="w-full relative"
                  style={{ height: "40px", background: "#1A1C23" }}
                >
                  <motion.div
                    className="absolute bottom-0 w-full"
                    style={{
                      background:
                        val > 100 ? "#44D17B" : val > 0 ? "#D6B36A" : "#2A2C33",
                    }}
                    animate={{
                      height: `${Math.min(100, (val / maxStream) * 100)}%`,
                    }}
                    transition={{ duration: 0.8 }}
                  />
                </div>
                <div className="font-mono text-[6px] text-[#4A4F58]">
                  {val.toFixed(1)}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* AUDIT LOG */}
      <div data-ocid="organism.table">
        <SectionHeader>AUDIT LOG FEED \u00b7 LAST 20 EVENTS</SectionHeader>
        <ScrollArea className="h-64 border" style={{ borderColor: "#2A2C33" }}>
          <div className="p-2 space-y-1">
            {!auditLog || auditLog.length === 0 ? (
              <div
                className="flex items-center justify-center h-16 font-mono text-[10px] tracking-widest text-[#4A4F58]"
                data-ocid="organism.empty_state"
              >
                NO AUDIT EVENTS YET
              </div>
            ) : (
              auditLog.slice(0, 10).map((entry, idx) => (
                <motion.div
                  key={`${String(entry.beat)}-${entry.eventType}-${idx}`}
                  initial={{ opacity: 0, x: -4 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: idx * 0.03 }}
                  className="flex items-start gap-3 py-1.5 border-b"
                  style={{ borderColor: "#1A1C23" }}
                  data-ocid={`organism.row.${idx + 1}`}
                >
                  <span
                    className="font-mono text-[8px] tracking-widest w-16 shrink-0"
                    style={{ color: "#D6B36A" }}
                  >
                    B#{Number(entry.beat)}
                  </span>
                  <span
                    className="font-mono text-[8px] tracking-wider w-24 shrink-0 uppercase"
                    style={{ color: "#9AA0AA" }}
                  >
                    {entry.eventType}
                  </span>
                  <span className="font-mono text-[8px] text-[#6F7580] leading-relaxed truncate">
                    {entry.detail}
                  </span>
                </motion.div>
              ))
            )}
          </div>
        </ScrollArea>
      </div>
    </div>
  );
}
