import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";

const NEURO_NAMES = [
  "DOPAMINE",
  "SEROTONIN",
  "CORTISOL",
  "OXYTOCIN",
  "TESTOSTERONE",
  "ADRENALINE",
  "GABA",
  "ACETYLCHOLINE",
  "NOREPINEPHRINE",
  "ENDORPHIN",
  "MELATONIN",
  "THYROID",
  "INSULIN",
  "GLUCAGON",
  "VASOPRESSIN",
  "ALDOSTERONE",
  "ESTROGEN",
  "PROGESTERONE",
  "PROLACTIN",
  "GROWTH_H",
  "LEPTIN",
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

export function GenesisPanel() {
  const { actor, isFetching } = useActor();
  const px = actor as unknown as Record<
    string,
    (...args: unknown[]) => Promise<unknown>
  >;
  const queryClient = useQueryClient();
  const [foundingWord, setFoundingWord] = useState("PARALLAX");

  const { data: genesisActivated = false } = useQuery({
    queryKey: ["px_isGenesisActivated"],
    queryFn: async () => {
      if (!px) return false;
      return ((await px.px_isGenesisActivated?.()) as boolean) ?? false;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });

  const { data: fullState } = useQuery<FullState | null>({
    queryKey: ["px_getFullState_genesis"],
    queryFn: async () => {
      if (!px) return null;
      return ((await px.px_getFullState?.()) as FullState) ?? null;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });

  const { data: neurochemicals } = useQuery<number[]>({
    queryKey: ["px_getNeurochemicals_genesis"],
    queryFn: async () => {
      if (!px) return [];
      return ((await px.px_getNeurochemicals?.()) as number[]) ?? [];
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });

  const activateMutation = useMutation({
    mutationFn: async () => {
      if (!px) throw new Error("Actor not ready");
      return (await px.activateGenesis?.(
        foundingWord.trim() || "PARALLAX",
      )) as string;
    },
    onSuccess: (msg: string) => {
      toast.success(msg || "GENESIS ACTIVATED \u2014 ORGANISM ALIVE", {
        duration: 8000,
        style: {
          background: "#0B0C10",
          border: "1px solid #44D17B",
          color: "#44D17B",
          fontFamily: "'Geist Mono', monospace",
          fontSize: "11px",
          letterSpacing: "0.2em",
        },
      });
      queryClient.invalidateQueries({ queryKey: ["px_isGenesisActivated"] });
      queryClient.invalidateQueries({ queryKey: ["px_getFullState_genesis"] });
    },
    onError: (e: unknown) => {
      const msg = e instanceof Error ? e.message : "ACTIVATION FAILED";
      toast.error(msg, {
        style: {
          background: "#0B0C10",
          border: "1px solid #C23B55",
          color: "#C23B55",
          fontFamily: "'Geist Mono', monospace",
          fontSize: "11px",
          letterSpacing: "0.2em",
        },
      });
    },
  });

  const beat = fullState ? Number(fullState.beat) : 0;
  const coherence = fullState?.coherence ?? 0;
  const forma = fullState?.formaCapital ?? 0;
  const aresArmed = fullState?.aresArmed ?? false;

  return (
    <div className="space-y-6" data-ocid="genesis.panel">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div
            className="font-mono text-[11px] tracking-[0.4em] mb-1"
            style={{ color: "#D6B36A" }}
          >
            GENESIS PROTOCOL
          </div>
          <div className="font-mono text-[9px] tracking-[0.25em] text-[#4A4F58]">
            MEDINA DOCTRINE \u00b7 SOVEREIGN ACTIVATION SEQUENCE
          </div>
        </div>
        <AnimatePresence mode="wait">
          {genesisActivated ? (
            <motion.div
              key="alive"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex items-center gap-2"
              data-ocid="genesis.success_state"
            >
              <motion.div
                animate={{ opacity: [1, 0.3, 1] }}
                transition={{ duration: 1.4, repeat: Number.POSITIVE_INFINITY }}
                className="w-2 h-2 rounded-full"
                style={{
                  backgroundColor: "#44D17B",
                  boxShadow: "0 0 8px rgba(68,209,123,0.8)",
                }}
              />
              <span
                className="font-mono text-[10px] tracking-[0.3em]"
                style={{ color: "#44D17B" }}
              >
                ORGANISM ALIVE
              </span>
            </motion.div>
          ) : (
            <motion.div
              key="dormant"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="flex items-center gap-2"
              data-ocid="genesis.loading_state"
            >
              <div
                className="w-2 h-2"
                style={{
                  backgroundColor: "#D6A83A",
                  boxShadow: "0 0 6px rgba(214,168,58,0.5)",
                }}
              />
              <span
                className="font-mono text-[10px] tracking-[0.3em]"
                style={{ color: "#D6A83A" }}
              >
                DORMANT
              </span>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Main Genesis Activation Area */}
      <div
        className="relative border p-8 flex flex-col items-center gap-6"
        style={{
          borderColor: genesisActivated ? "#44D17B" : "#D6B36A",
          background: genesisActivated
            ? "linear-gradient(135deg, rgba(68,209,123,0.03) 0%, rgba(7,8,10,1) 60%)"
            : "linear-gradient(135deg, rgba(214,179,106,0.05) 0%, rgba(7,8,10,1) 60%)",
          boxShadow: genesisActivated
            ? "0 0 48px rgba(68,209,123,0.08), inset 0 0 32px rgba(68,209,123,0.03)"
            : "0 0 48px rgba(214,179,106,0.06), inset 0 0 32px rgba(214,179,106,0.02)",
        }}
      >
        {/* Scan-line overlay */}
        <div
          className="absolute inset-0 pointer-events-none"
          style={{
            backgroundImage:
              "repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(214,179,106,0.012) 2px, rgba(214,179,106,0.012) 4px)",
          }}
        />

        {/* Corner brackets */}
        {[
          ["top-0 left-0", "border-t border-l"],
          ["top-0 right-0", "border-t border-r"],
          ["bottom-0 left-0", "border-b border-l"],
          ["bottom-0 right-0", "border-b border-r"],
        ].map(([pos, borders]) => (
          <div
            key={pos}
            className={`absolute ${pos} w-4 h-4 ${borders}`}
            style={{
              borderColor: genesisActivated ? "#44D17B" : "#D6B36A",
              margin: "4px",
            }}
          />
        ))}

        {/* Central sigil */}
        <motion.div
          animate={genesisActivated ? { rotate: 360 } : { rotate: 0 }}
          transition={
            genesisActivated
              ? {
                  duration: 20,
                  repeat: Number.POSITIVE_INFINITY,
                  ease: "linear",
                }
              : {}
          }
          className="w-16 h-16 flex items-center justify-center border-2 relative z-10"
          style={{
            borderColor: genesisActivated ? "#44D17B" : "#D6B36A",
            boxShadow: genesisActivated
              ? "0 0 24px rgba(68,209,123,0.3)"
              : "0 0 24px rgba(214,179,106,0.15)",
          }}
        >
          <svg
            width="32"
            height="32"
            viewBox="0 0 24 24"
            fill="none"
            stroke={genesisActivated ? "#44D17B" : "#D6B36A"}
            strokeWidth="1"
            strokeLinecap="round"
            role="img"
            aria-label="Parallax organism sigil"
          >
            <title>Parallax organism sigil</title>
            <circle cx="12" cy="12" r="10" />
            <circle cx="12" cy="12" r="6" />
            <circle cx="12" cy="12" r="2" />
            <line x1="12" y1="2" x2="12" y2="6" />
            <line x1="12" y1="18" x2="12" y2="22" />
            <line x1="2" y1="12" x2="6" y2="12" />
            <line x1="18" y1="12" x2="22" y2="12" />
          </svg>
        </motion.div>

        <div className="text-center relative z-10">
          <div
            className="font-mono font-bold text-lg tracking-[0.4em] mb-1"
            style={{
              color: genesisActivated ? "#44D17B" : "#D6B36A",
              textShadow: genesisActivated
                ? "0 0 20px rgba(68,209,123,0.5)"
                : "0 0 20px rgba(214,179,106,0.3)",
            }}
          >
            PARALLAX
          </div>
          <div className="font-mono text-[9px] tracking-[0.35em] text-[#6F7580]">
            SOVEREIGN COGNITIVE ORGANISM
          </div>
        </div>

        <AnimatePresence mode="wait">
          {!genesisActivated ? (
            <motion.div
              key="activate-form"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="relative z-10 flex flex-col items-center gap-3 w-full max-w-xs"
            >
              <div className="w-full flex flex-col gap-1">
                <label
                  htmlFor="founding-word"
                  className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]"
                >
                  FOUNDING WORD
                </label>
                <input
                  id="founding-word"
                  type="text"
                  value={foundingWord}
                  onChange={(e) => setFoundingWord(e.target.value)}
                  disabled={activateMutation.isPending || !actor}
                  placeholder="PARALLAX"
                  maxLength={64}
                  data-ocid="genesis.input"
                  className="w-full bg-transparent border px-3 py-2 font-mono text-xs tracking-[0.25em] focus:outline-none disabled:opacity-50"
                  style={{
                    borderColor: "#D6B36A",
                    color: "#D6B36A",
                    caretColor: "#D6B36A",
                  }}
                />
              </div>
              <motion.button
                key="activate-btn"
                type="button"
                onClick={() => activateMutation.mutate()}
                disabled={activateMutation.isPending || !actor}
                data-ocid="genesis.primary_button"
                className="w-full px-10 py-4 font-mono font-bold text-sm tracking-[0.4em] border-2 transition-all duration-200 disabled:opacity-50"
                style={{
                  borderColor: "#D6B36A",
                  color: "#D6B36A",
                  background: "transparent",
                  boxShadow: "0 0 32px rgba(214,179,106,0.12)",
                }}
                whileHover={
                  !activateMutation.isPending
                    ? {
                        boxShadow: "0 0 48px rgba(214,179,106,0.3)",
                        background: "rgba(214,179,106,0.06)",
                      }
                    : {}
                }
                whileTap={!activateMutation.isPending ? { scale: 0.97 } : {}}
              >
                {activateMutation.isPending ? (
                  <span className="flex items-center justify-center gap-3">
                    <motion.span
                      animate={{ opacity: [1, 0.2, 1] }}
                      transition={{
                        duration: 0.8,
                        repeat: Number.POSITIVE_INFINITY,
                      }}
                    >
                      ◈
                    </motion.span>
                    ACTIVATING...
                  </span>
                ) : (
                  "⚡ GENESIS ACTIVATE"
                )}
              </motion.button>
            </motion.div>
          ) : (
            <motion.div
              key="alive-status"
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              className="relative z-10 flex flex-col items-center gap-3"
            >
              <div
                className="px-8 py-3 border font-mono text-sm tracking-[0.35em]"
                style={{
                  borderColor: "#44D17B",
                  color: "#44D17B",
                  background: "rgba(68,209,123,0.05)",
                  boxShadow: "0 0 32px rgba(68,209,123,0.15)",
                }}
              >
                \u2726 ORGANISM ALIVE
              </div>
              <div className="font-mono text-[10px] tracking-[0.3em] text-[#6F7580]">
                BEAT #{beat.toLocaleString()} \u00b7 COHERENCE{" "}
                {(coherence * 100).toFixed(1)}%
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {activateMutation.isSuccess && (
          <motion.div
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            className="relative z-10 font-mono text-[10px] tracking-[0.25em] text-center"
            style={{ color: "#44D17B" }}
            data-ocid="genesis.success_state"
          >
            {String(activateMutation.data)}
          </motion.div>
        )}
      </div>

      {/* Live Status Grid — always visible when data exists */}
      {fullState && (
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          className="grid grid-cols-2 md:grid-cols-4 gap-3"
        >
          {[
            {
              label: "FORMA CAPITAL",
              value: forma.toFixed(2),
              accent: "#D6B36A",
            },
            {
              label: "GLOBAL COHERENCE",
              value: `${(coherence * 100).toFixed(2)}%`,
              accent: "#44D17B",
            },
            {
              label: "LAW SCORE",
              value: `${(fullState.lawScore * 100).toFixed(1)}%`,
              accent: "#D6B36A",
            },
            {
              label: "ARES STATUS",
              value: aresArmed ? "ARMED" : "DISARMED",
              accent: aresArmed ? "#C23B55" : "#44D17B",
            },
          ].map(({ label, value, accent }) => (
            <div
              key={label}
              className="border p-3 flex flex-col gap-1"
              style={{
                borderColor: "#2A2C33",
                background: "rgba(11,12,16,0.8)",
              }}
            >
              <div className="font-mono text-[8px] tracking-[0.3em] text-[#6F7580]">
                {label}
              </div>
              <div
                className="font-mono text-sm font-bold"
                style={{ color: accent }}
              >
                {value}
              </div>
            </div>
          ))}
        </motion.div>
      )}

      {/* Neurochemical Readout — always visible when data exists */}
      {neurochemicals && neurochemicals.length > 0 && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="border p-4"
          style={{ borderColor: "#2A2C33" }}
        >
          <div className="font-mono text-[9px] tracking-[0.35em] text-[#6F7580] mb-3">
            NEUROCHEMICAL SUBSTRATE \u00b7 21 CHANNELS
          </div>
          <div className="grid grid-cols-3 md:grid-cols-7 gap-2">
            {neurochemicals.slice(0, 21).map((val, i) => (
              <div
                key={NEURO_NAMES[i] ?? `n${i}`}
                className="flex flex-col gap-1"
              >
                <div className="font-mono text-[7px] tracking-wider text-[#4A4F58] truncate">
                  {NEURO_NAMES[i] ?? `N${i}`}
                </div>
                <div className="h-1 w-full" style={{ background: "#1A1C23" }}>
                  <motion.div
                    className="h-1"
                    style={{
                      width: `${Math.min(100, val * 100)}%`,
                      background:
                        val > 1.5
                          ? "#C23B55"
                          : val > 1.2
                            ? "#D6B36A"
                            : "#44D17B",
                    }}
                    animate={{ width: `${Math.min(100, val * 100)}%` }}
                    transition={{ duration: 0.6 }}
                  />
                </div>
                <div className="font-mono text-[8px] text-[#6F7580]">
                  {val.toFixed(2)}
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      )}

      <div className="border-t border-[#1A1C23] pt-4">
        <div className="font-mono text-[8px] tracking-[0.25em] text-[#3A3F48] text-center">
          MEDINA DOCTRINE \u00b7 CREATOR SUPREMACY LAW \u00b7 ALFREDO MEDINA
          HERNANDEZ \u00b7 100% SOVEREIGN
        </div>
      </div>
    </div>
  );
}
