import { motion } from "motion/react";
import { useState } from "react";
import { toast } from "sonner";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
  callWrite: (fn: string, ...args: unknown[]) => Promise<unknown>;
}

function QSection({
  title,
  children,
}: { title: string; children: React.ReactNode }) {
  return (
    <section className="border border-zinc-800 bg-black/80 p-4 space-y-3">
      <div className="font-mono text-[9px] tracking-[0.3em] text-zinc-400 border-b border-zinc-800/60 pb-2">
        {title}
      </div>
      {children}
    </section>
  );
}

function StatRow({
  label,
  value,
  color,
  sub,
}: { label: string; value: string; color?: string; sub?: string }) {
  return (
    <div className="flex items-center justify-between gap-2">
      <span className="font-mono text-[9px] text-zinc-500 tracking-wider">
        {label}
      </span>
      <div className="text-right">
        <span
          className="font-mono text-xs font-bold"
          style={{ color: color ?? "#e7e9ee" }}
        >
          {value}
        </span>
        {sub && <div className="font-mono text-[8px] text-zinc-600">{sub}</div>}
      </div>
    </div>
  );
}

export function QuantumPanel({ data, callWrite }: Props) {
  const { quantum, treasury } = data;
  const [pingLoading, setPingLoading] = useState(false);
  const [dischargeLoading, setDischargeLoading] = useState(false);
  const [lastDischargeAmount, setLastDischargeAmount] = useState<number | null>(
    null,
  );

  const handlePingPresence = async () => {
    setPingLoading(true);
    try {
      await callWrite("pingPresence");
      toast.success("Presence activated — quantum battery charging at 2×");
    } catch {
      toast.error("Presence ping failed");
    } finally {
      setPingLoading(false);
    }
  };

  const handleDischarge = async () => {
    if (quantum.batteryLocked || quantum.batteryBalance <= 0) return;
    setDischargeLoading(true);
    setLastDischargeAmount(null);
    try {
      const result = await callWrite("dischargeQuantumBattery");
      const amount = typeof result === "number" ? result : 0;
      setLastDischargeAmount(amount);
      toast.success(
        `Quantum battery discharged — ${amount.toFixed(6)} ICP-eq swept to reserve`,
      );
    } catch {
      toast.error("Discharge failed");
    } finally {
      setDischargeLoading(false);
    }
  };

  const chargePercent = Math.min(
    (quantum.batteryBalance / Math.max(quantum.stream21Total || 1, 0.0001)) *
      100,
    100,
  );
  const presenceBeatsLeft = quantum.presenceActive
    ? Math.max(0, quantum.presenceExpiresBeat - treasury.beatCount)
    : 0;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-mono text-xs tracking-[0.3em] text-zinc-400 uppercase">
            QUANTUM INTELLIGENCE LAYER
          </h2>
          <p className="font-mono text-[9px] text-zinc-600 tracking-widest mt-0.5">
            QUANTUM BATTERY · MAXWELL'S DEMON · MTC COHERENCE INDEX
          </p>
        </div>
        <div className="font-mono text-[9px] text-zinc-600 text-right">
          <div>MEDINA DOCTRINE · 2026</div>
          <div>STREAMS 21 & 22 ACTIVE</div>
        </div>
      </div>

      {/* QUANTUM BATTERY */}
      <QSection title="QUANTUM BATTERY — STREAM 21">
        {/* Big balance */}
        <div className="flex items-baseline gap-3">
          <span className="font-mono text-[10px] text-zinc-500">RESERVE =</span>
          <span
            className="font-mono text-4xl font-bold tracking-tight"
            style={{ color: quantum.batteryLocked ? "#52525b" : "#D6B36A" }}
            data-ocid="quantum.panel"
          >
            {quantum.batteryBalance.toFixed(8)}
          </span>
          <span className="font-mono text-[9px] text-zinc-600">ICP-EQ</span>
        </div>

        {/* Battery level bar */}
        <div className="space-y-1">
          <div className="flex justify-between">
            <span className="font-mono text-[8px] text-zinc-600">
              CHARGE LEVEL
            </span>
            <span
              className="font-mono text-[8px]"
              style={{ color: quantum.batteryLocked ? "#52525b" : "#D6B36A" }}
            >
              {chargePercent.toFixed(1)}%
            </span>
          </div>
          <div className="h-2 bg-zinc-900 border border-zinc-800 overflow-hidden">
            <motion.div
              className="h-full"
              animate={{ width: `${chargePercent}%` }}
              transition={{ type: "spring", stiffness: 60, damping: 20 }}
              style={{
                background: quantum.batteryLocked
                  ? "#374151"
                  : "linear-gradient(90deg, #92400e, #D6B36A, #fde68a)",
                boxShadow: quantum.batteryLocked
                  ? "none"
                  : "0 0 8px rgba(214,179,106,0.4)",
              }}
            />
          </div>
        </div>

        {/* Status badge */}
        <div className="flex items-center gap-2">
          {quantum.batteryLocked ? (
            <span className="font-mono text-[9px] tracking-widest px-2 py-1 border border-zinc-700 text-zinc-500">
              ⊘ LOCKED — COHERENCE TOO LOW
            </span>
          ) : quantum.batteryBalance > 0 ? (
            <motion.span
              animate={{ opacity: [1, 0.6, 1] }}
              transition={{ duration: 2, repeat: Number.POSITIVE_INFINITY }}
              className="font-mono text-[9px] tracking-widest px-2 py-1 border"
              style={{ borderColor: "#D6B36A60", color: "#D6B36A" }}
            >
              ◉ READY TO DISCHARGE
            </motion.span>
          ) : (
            <span className="font-mono text-[9px] tracking-widest px-2 py-1 border border-amber-900/40 text-amber-700">
              ⬆ CHARGING
            </span>
          )}
          <span className="font-mono text-[8px] text-zinc-600">
            +{quantum.chargeRate.toFixed(8)}/beat
          </span>
        </div>

        <div className="grid grid-cols-1 gap-2">
          <StatRow
            label="DISCHARGE COUNT"
            value={quantum.dischargeCount.toString()}
            color="#D6B36A"
          />
          <StatRow
            label="STREAM 21 TOTAL"
            value={`${quantum.stream21Total.toFixed(8)} ICP-EQ`}
            color="#D6B36A"
            sub="QUANTUM COHERENCE RESERVE — ALL TIME"
          />
        </div>

        {/* Presence control */}
        <div className="border border-zinc-800 p-3 space-y-2">
          <div className="flex items-center justify-between">
            <div>
              <div className="font-mono text-[9px] text-zinc-400 tracking-wider">
                CREATOR PRESENCE
              </div>
              <div className="font-mono text-[8px] text-zinc-600">
                Activates 2× battery charging for 300 beats
              </div>
            </div>
            {quantum.presenceActive && (
              <motion.div
                animate={{ opacity: [1, 0.5, 1] }}
                transition={{ duration: 1.5, repeat: Number.POSITIVE_INFINITY }}
                className="flex items-center gap-1.5"
              >
                <div
                  className="w-1.5 h-1.5 rounded-full bg-amber-400"
                  style={{ boxShadow: "0 0 6px rgba(251,191,36,0.8)" }}
                />
                <span className="font-mono text-[8px] text-amber-400 tracking-widest">
                  ACTIVE — {presenceBeatsLeft} BEATS LEFT
                </span>
              </motion.div>
            )}
          </div>
          {quantum.presenceActive ? (
            <div
              className="font-mono text-[9px] tracking-widest px-3 py-2 border border-amber-500/30 text-amber-400 bg-amber-950/20"
              data-ocid="quantum.success_state"
            >
              ◉ PRESENCE ACTIVE — 2× CHARGE RATE IN EFFECT
            </div>
          ) : (
            <button
              type="button"
              onClick={handlePingPresence}
              disabled={pingLoading}
              data-ocid="quantum.primary_button"
              className="w-full py-2 font-mono text-[9px] tracking-widest border transition-all duration-150 disabled:opacity-40"
              style={{ borderColor: "#D6B36A60", color: "#D6B36A" }}
            >
              {pingLoading
                ? "PINGING..."
                : "⚡ PING PRESENCE — ACTIVATE 2× CHARGE"}
            </button>
          )}
        </div>

        {/* Discharge */}
        <div className="border border-zinc-800 p-3 space-y-2">
          <div>
            <div className="font-mono text-[9px] text-zinc-400 tracking-wider">
              BATTERY DISCHARGE
            </div>
            <div className="font-mono text-[8px] text-zinc-600">
              Full balance swept to withdrawal ledger in one event
            </div>
          </div>
          {lastDischargeAmount !== null && (
            <div
              className="font-mono text-[9px] text-amber-400 tracking-widest border border-amber-900/40 px-3 py-1"
              data-ocid="quantum.toast"
            >
              LAST DISCHARGE: {lastDischargeAmount.toFixed(8)} ICP-EQ
            </div>
          )}
          <button
            type="button"
            onClick={handleDischarge}
            disabled={
              dischargeLoading ||
              quantum.batteryLocked ||
              quantum.batteryBalance <= 0
            }
            data-ocid="quantum.delete_button"
            className="w-full py-2 font-mono text-[9px] tracking-widest border transition-all duration-150 disabled:opacity-30 disabled:cursor-not-allowed"
            style={{
              borderColor:
                quantum.batteryLocked || quantum.batteryBalance <= 0
                  ? "#374151"
                  : "#D6B36A",
              color:
                quantum.batteryLocked || quantum.batteryBalance <= 0
                  ? "#52525b"
                  : "#D6B36A",
              backgroundColor:
                quantum.batteryLocked || quantum.batteryBalance <= 0
                  ? "transparent"
                  : "rgba(214,179,106,0.05)",
            }}
          >
            {dischargeLoading
              ? "DISCHARGING..."
              : quantum.batteryLocked
                ? "DISCHARGE LOCKED"
                : "⬇ DISCHARGE FULL BATTERY"}
          </button>
        </div>
      </QSection>

      {/* MAXWELL'S DEMON */}
      <QSection title="MAXWELL'S DEMON — STREAM 22">
        <div className="flex items-baseline gap-3">
          <span className="font-mono text-[10px] text-zinc-500">
            OBSERVATION YIELD =
          </span>
          <span className="font-mono text-3xl font-bold tracking-tight text-emerald-400">
            {quantum.stream22Total.toFixed(8)}
          </span>
          <span className="font-mono text-[9px] text-zinc-600">ICP-EQ</span>
        </div>
        <div className="font-mono text-[9px] text-zinc-500 border-l-2 border-emerald-800/60 pl-3 leading-relaxed">
          ORGANISM EARNS FROM BEING RIGHT.
          <br />
          EVERY EXTERNAL DATA FETCH REDUCES ENTROPY H.
          <br />
          ΔH = YIELD. INTELLIGENCE COMPOUNDS INTO MONEY.
        </div>
        <StatRow
          label="STREAM 22 TOTAL"
          value={`${quantum.stream22Total.toFixed(8)} ICP-EQ`}
          color="#10b981"
          sub="MAXWELL'S DEMON — OBSERVATION-TO-YIELD"
        />
        <div className="font-mono text-[8px] text-zinc-700 border border-zinc-800 px-3 py-2">
          FORMULA: observationYield = k × (H_before - H_after) | RUNS ON EVERY
          HTTP OUTCALL
        </div>
      </QSection>

      {/* MTC COHERENCE INDEX */}
      <QSection title="MTC COHERENCE INDEX">
        <div className="flex items-baseline gap-3">
          <span className="font-mono text-[10px] text-zinc-500">
            MTC INDEX =
          </span>
          <span
            className="font-mono text-3xl font-bold tracking-tight"
            style={{ color: "#D6B36A" }}
          >
            ${quantum.mtcCoherenceIndex.toFixed(6)}
          </span>
        </div>
        <div className="font-mono text-[9px] text-zinc-500 border-l-2 border-amber-800/60 pl-3 leading-relaxed">
          MTC COHERENCE TRACKS ORGANISM INTELLIGENCE.
          <br />
          WHEN OMNIS FIRES, MTC INDEX RISES +10%.
          <br />
          EXTERNAL WORLD CAN OBSERVE ORGANISM PERFORMANCE.
        </div>
        <StatRow
          label="COHERENCE C"
          value={data.cognitive.coherenceC.toFixed(4)}
          color={
            data.cognitive.coherenceC > 0.8
              ? "#10b981"
              : data.cognitive.coherenceC > 0.5
                ? "#f59e0b"
                : "#ef4444"
          }
          sub="CURRENT COGNITIVE COHERENCE"
        />
        <StatRow
          label="OMNIS FIRED"
          value={data.cognitive.omnisFiredCount.toString()}
          color={data.cognitive.omnisFiredCount > 0 ? "#10b981" : "#52525b"}
          sub="MTC BOOST EVENTS"
        />
        <div className="font-mono text-[8px] text-zinc-700 border border-zinc-800 px-3 py-2">
          FORMULA: mtcIndex = mtcBasePrice × (1 + coherenceC × 0.5) | OMNIS
          EVENT: +10% BOOST
        </div>
      </QSection>

      {/* STREAM 21 / 22 SUMMARY */}
      <QSection title="QUANTUM STREAM TOTALS">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <div className="border border-amber-900/30 bg-amber-950/10 p-3">
            <div className="font-mono text-[8px] text-zinc-500 tracking-widest mb-1">
              STREAM 21
            </div>
            <div
              className="font-mono text-lg font-bold"
              style={{ color: "#D6B36A" }}
            >
              {quantum.stream21Total.toFixed(8)}
            </div>
            <div className="font-mono text-[8px] text-zinc-600">
              QUANTUM COHERENCE RESERVE
            </div>
            <div className="font-mono text-[7px] text-zinc-700 mt-1">
              CHARGES AT: baseRate × coherenceC²
            </div>
          </div>
          <div className="border border-emerald-900/30 bg-emerald-950/10 p-3">
            <div className="font-mono text-[8px] text-zinc-500 tracking-widest mb-1">
              STREAM 22
            </div>
            <div className="font-mono text-lg font-bold text-emerald-400">
              {quantum.stream22Total.toFixed(8)}
            </div>
            <div className="font-mono text-[8px] text-zinc-600">
              MAXWELL'S DEMON YIELD
            </div>
            <div className="font-mono text-[7px] text-zinc-700 mt-1">
              EARNS PER OBSERVATION: k × ΔH
            </div>
          </div>
        </div>
      </QSection>
    </div>
  );
}
