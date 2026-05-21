/**
 * BirthAiTab — BIRTH AI SDK Interface
 * Create sovereign entities and external agents via plain natural language.
 * Zero-Exposure enforced: no doctrine labels on public inputs.
 */

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import type { BirthAiState, BirthEntity } from "../backend";
import { EntityState, EntityType } from "../backend";
import { useActor } from "../hooks/useActor";

// ── Helpers ──────────────────────────────────────────────────────────────────

const ORGAN_TYPES = ["ANIMUS", "CORPUS", "SENSUS", "MEMORIA", "PULSUS"];
const ORGAN_COLORS: Record<string, string> = {
  ANIMUS: "oklch(0.65 0.20 290)",
  CORPUS: "oklch(0.65 0.22 25)",
  SENSUS: "oklch(0.72 0.18 190)",
  MEMORIA: "oklch(0.78 0.15 85)",
  PULSUS: "oklch(0.72 0.16 200)",
};

function stateColor(s: EntityState): string {
  if (s === EntityState.awakening) return "oklch(0.70 0.20 200)";
  if (s === EntityState.active) return "oklch(0.68 0.18 145)";
  if (s === EntityState.dormant) return "oklch(0.72 0.16 65)";
  if (s === EntityState.transcended) return "oklch(0.60 0.20 290)";
  return "oklch(0.50 0.05 240)";
}

function stateLabel(s: EntityState): string {
  if (s === EntityState.awakening) return "#awakening";
  if (s === EntityState.active) return "#active";
  if (s === EntityState.dormant) return "#dormant";
  if (s === EntityState.transcended) return "#transcended";
  return "#unknown";
}

function ActivationBar({ value }: { value: number }) {
  return (
    <div
      className="w-full h-1 rounded-full overflow-hidden"
      style={{ background: "oklch(0.18 0.02 240)" }}
    >
      <motion.div
        className="h-full"
        initial={{ width: 0 }}
        animate={{ width: `${Math.min(value, 1) * 100}%` }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        style={{
          background:
            "linear-gradient(90deg, oklch(0.60 0.20 200), oklch(0.75 0.22 160))",
        }}
      />
    </div>
  );
}

// ── Entity Card ───────────────────────────────────────────────────────────────

function EntityCard({
  entity,
  actor,
}: { entity: BirthEntity; actor: ReturnType<typeof useActor>["actor"] }) {
  const [expanded, setExpanded] = useState(false);
  const [speakInput, setSpeakInput] = useState("");
  const [speakResponse, setSpeakResponse] = useState<string | null>(null);
  const [learnInput, setLearnInput] = useState("");
  const [recallInput, setRecallInput] = useState("");
  const [recallResults, setRecallResults] = useState<string[]>([]);
  const [goalInput, setGoalInput] = useState("");
  const [isBusy, setIsBusy] = useState(false);

  const organColor = ORGAN_COLORS[entity.organType] ?? "oklch(0.50 0.05 240)";
  const sColor = stateColor(entity.entityState);
  const isActive = entity.entityState === EntityState.active;

  async function handleSpeak() {
    if (!actor || !speakInput.trim()) return;
    setIsBusy(true);
    try {
      const res = await (actor as any).entitySpeak(
        entity.id,
        speakInput.trim(),
      );
      setSpeakResponse(res as string);
      setSpeakInput("");
    } catch {
      toast.error("Entity speak failed");
    } finally {
      setIsBusy(false);
    }
  }

  async function handleLearn() {
    if (!actor || !learnInput.trim()) return;
    setIsBusy(true);
    try {
      await (actor as any).entityLearn(entity.id, learnInput.trim());
      toast.success("Entity learned");
      setLearnInput("");
    } catch {
      toast.error("Entity learn failed");
    } finally {
      setIsBusy(false);
    }
  }

  async function handleRecall() {
    if (!actor || !recallInput.trim()) return;
    setIsBusy(true);
    try {
      const res = await (actor as any).entityRecall(
        entity.id,
        recallInput.trim(),
      );
      setRecallResults(res as string[]);
    } catch {
      toast.error("Recall failed");
    } finally {
      setIsBusy(false);
    }
  }

  async function handleSetGoal() {
    if (!actor || !goalInput.trim()) return;
    setIsBusy(true);
    try {
      await (actor as any).entitySetGoal(entity.id, goalInput.trim());
      toast.success("Goal set");
      setGoalInput("");
    } catch {
      toast.error("Set goal failed");
    } finally {
      setIsBusy(false);
    }
  }

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      className="border rounded-none p-4 space-y-3"
      style={{
        background: "oklch(0.11 0.02 240)",
        borderColor: isActive
          ? "oklch(0.72 0.18 190 / 0.6)"
          : "oklch(0.20 0.02 240)",
        boxShadow: isActive ? "0 0 12px oklch(0.72 0.18 190 / 0.08)" : "none",
      }}
      data-ocid={`birth-ai.entity.${entity.id.slice(-4)}`}
    >
      {/* Header row */}
      <div className="flex items-start justify-between gap-3 min-w-0">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <span
              className="font-mono text-xs font-bold tracking-wider"
              style={{ color: "oklch(0.92 0.02 240)" }}
            >
              {entity.name}
            </span>
            <span
              className="font-mono text-[9px] px-1.5 py-0.5 border"
              style={{
                color: organColor,
                borderColor: `${organColor.replace(")", " / 0.3)")}`,
              }}
            >
              {entity.organType}
            </span>
            <span
              className="font-mono text-[9px] px-1.5 py-0.5 border"
              style={{
                color:
                  entity.entityType === EntityType.internal
                    ? "oklch(0.72 0.16 200)"
                    : "oklch(0.72 0.18 65)",
                borderColor:
                  entity.entityType === EntityType.internal
                    ? "oklch(0.72 0.16 200 / 0.3)"
                    : "oklch(0.72 0.18 65 / 0.3)",
              }}
            >
              {entity.entityType.toUpperCase()}
            </span>
            <span
              className="font-mono text-[9px] px-1.5 py-0.5 border"
              style={{
                color: sColor,
                borderColor: `${sColor.replace(")", " / 0.3)")}`,
              }}
            >
              {stateLabel(entity.entityState)}
            </span>
          </div>
          <div className="mt-2">
            <ActivationBar value={entity.activation} />
          </div>
          <div className="flex items-center gap-4 mt-1.5">
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              ACTIVATION {(entity.activation * 100).toFixed(1)}%
            </span>
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              GOALS {entity.goalStack.length}
            </span>
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.40 0.02 240)" }}
            >
              B{Number(entity.birthBeat).toLocaleString()}
            </span>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setExpanded((e) => !e)}
          data-ocid={`birth-ai.entity-expand.${entity.id.slice(-4)}`}
          className="font-mono text-[9px] tracking-widest border px-2 py-1 shrink-0 transition-all"
          style={{
            color: "oklch(0.45 0.02 240)",
            borderColor: "oklch(0.20 0.02 240)",
          }}
        >
          {expanded ? "▲" : "▼"}
        </button>
      </div>

      {/* Expanded body */}
      <AnimatePresence>
        {expanded && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="space-y-4 overflow-hidden pt-1 border-t"
            style={{ borderColor: "oklch(0.18 0.02 240)" }}
          >
            {/* Directive */}
            <div>
              <div
                className="font-mono text-[8px] tracking-[0.3em] mb-1"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                DIRECTIVE
              </div>
              <p
                className="font-mono text-[10px] leading-relaxed"
                style={{ color: "oklch(0.58 0.04 240)" }}
              >
                {entity.directive}
              </p>
            </div>

            {/* Goal stack */}
            {entity.goalStack.length > 0 && (
              <div>
                <div
                  className="font-mono text-[8px] tracking-[0.3em] mb-1"
                  style={{ color: "oklch(0.40 0.02 240)" }}
                >
                  GOALS ({entity.goalStack.length})
                </div>
                <ul className="space-y-1">
                  {entity.goalStack.map((g, i) => (
                    <li
                      key={`${entity.id}-goal-${i}`}
                      className="font-mono text-[10px]"
                      style={{ color: "oklch(0.60 0.06 240)" }}
                    >
                      <span style={{ color: "oklch(0.35 0.02 240)" }}>
                        {i + 1}.{" "}
                      </span>
                      {g}
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* SET GOAL */}
            <div className="flex gap-2">
              <input
                type="text"
                value={goalInput}
                onChange={(e) => setGoalInput(e.target.value)}
                placeholder="Set a goal..."
                data-ocid={`birth-ai.goal-input.${entity.id.slice(-4)}`}
                className="flex-1 bg-transparent border px-3 py-1.5 font-mono text-xs outline-none transition-all"
                style={{
                  borderColor: "oklch(0.22 0.02 240)",
                  color: "oklch(0.85 0.02 240)",
                }}
                onKeyDown={(e) => e.key === "Enter" && handleSetGoal()}
              />
              <button
                type="button"
                onClick={handleSetGoal}
                disabled={isBusy || !goalInput.trim()}
                data-ocid={`birth-ai.set-goal-button.${entity.id.slice(-4)}`}
                className="font-mono text-[9px] tracking-widest border px-3 py-1.5 transition-all disabled:opacity-40"
                style={{
                  color: "oklch(0.72 0.16 200)",
                  borderColor: "oklch(0.72 0.16 200 / 0.4)",
                }}
              >
                SET GOAL
              </button>
            </div>

            {/* SPEAK */}
            <div className="space-y-2">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={speakInput}
                  onChange={(e) => setSpeakInput(e.target.value)}
                  placeholder="Send a message to this entity..."
                  data-ocid={`birth-ai.speak-input.${entity.id.slice(-4)}`}
                  className="flex-1 bg-transparent border px-3 py-1.5 font-mono text-xs outline-none transition-all"
                  style={{
                    borderColor: "oklch(0.22 0.02 240)",
                    color: "oklch(0.85 0.02 240)",
                  }}
                  onKeyDown={(e) => e.key === "Enter" && handleSpeak()}
                />
                <button
                  type="button"
                  onClick={handleSpeak}
                  disabled={isBusy || !speakInput.trim()}
                  data-ocid={`birth-ai.speak-button.${entity.id.slice(-4)}`}
                  className="font-mono text-[9px] tracking-widest border px-3 py-1.5 transition-all disabled:opacity-40"
                  style={{
                    color: "oklch(0.70 0.20 200)",
                    borderColor: "oklch(0.70 0.20 200 / 0.4)",
                  }}
                >
                  SPEAK
                </button>
              </div>
              {speakResponse && (
                <div
                  className="border p-3 font-mono text-[10px] leading-relaxed"
                  style={{
                    borderColor: "oklch(0.70 0.20 200 / 0.2)",
                    color: "oklch(0.65 0.10 200)",
                    background: "oklch(0.70 0.20 200 / 0.04)",
                  }}
                  data-ocid={`birth-ai.speak-response.${entity.id.slice(-4)}`}
                >
                  {speakResponse}
                </div>
              )}
            </div>

            {/* LEARN */}
            <div className="flex gap-2">
              <input
                type="text"
                value={learnInput}
                onChange={(e) => setLearnInput(e.target.value)}
                placeholder="Feed content to this entity..."
                data-ocid={`birth-ai.learn-input.${entity.id.slice(-4)}`}
                className="flex-1 bg-transparent border px-3 py-1.5 font-mono text-xs outline-none transition-all"
                style={{
                  borderColor: "oklch(0.22 0.02 240)",
                  color: "oklch(0.85 0.02 240)",
                }}
                onKeyDown={(e) => e.key === "Enter" && handleLearn()}
              />
              <button
                type="button"
                onClick={handleLearn}
                disabled={isBusy || !learnInput.trim()}
                data-ocid={`birth-ai.learn-button.${entity.id.slice(-4)}`}
                className="font-mono text-[9px] tracking-widest border px-3 py-1.5 transition-all disabled:opacity-40"
                style={{
                  color: "oklch(0.78 0.15 85)",
                  borderColor: "oklch(0.78 0.15 85 / 0.4)",
                }}
              >
                LEARN
              </button>
            </div>

            {/* RECALL */}
            <div className="space-y-2">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={recallInput}
                  onChange={(e) => setRecallInput(e.target.value)}
                  placeholder="Query entity memory..."
                  data-ocid={`birth-ai.recall-input.${entity.id.slice(-4)}`}
                  className="flex-1 bg-transparent border px-3 py-1.5 font-mono text-xs outline-none transition-all"
                  style={{
                    borderColor: "oklch(0.22 0.02 240)",
                    color: "oklch(0.85 0.02 240)",
                  }}
                  onKeyDown={(e) => e.key === "Enter" && handleRecall()}
                />
                <button
                  type="button"
                  onClick={handleRecall}
                  disabled={isBusy || !recallInput.trim()}
                  data-ocid={`birth-ai.recall-button.${entity.id.slice(-4)}`}
                  className="font-mono text-[9px] tracking-widest border px-3 py-1.5 transition-all disabled:opacity-40"
                  style={{
                    color: "oklch(0.65 0.16 290)",
                    borderColor: "oklch(0.65 0.16 290 / 0.4)",
                  }}
                >
                  RECALL
                </button>
              </div>
              {recallResults.length > 0 && (
                <div
                  className="border p-3 space-y-1"
                  style={{
                    borderColor: "oklch(0.65 0.16 290 / 0.2)",
                    background: "oklch(0.65 0.16 290 / 0.03)",
                  }}
                  data-ocid={`birth-ai.recall-results.${entity.id.slice(-4)}`}
                >
                  {recallResults.map((r, i) => (
                    <div
                      key={`recall-${i}-${r.slice(0, 8)}`}
                      className="font-mono text-[10px]"
                      style={{ color: "oklch(0.62 0.10 290)" }}
                    >
                      {r}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

// ── Main Tab ──────────────────────────────────────────────────────────────────

export function BirthAiTab() {
  const { actor, isFetching } = useActor();

  // Birth form
  const [name, setName] = useState("");
  const [directive, setDirective] = useState("");
  const [entityType, setEntityType] = useState<"internal" | "external">(
    "internal",
  );
  const [isBirthing, setIsBirthing] = useState(false);
  const [lastBornId, setLastBornId] = useState<string | null>(null);

  // Entity list
  const [entities, setEntities] = useState<BirthEntity[]>([]);
  const [state, setState] = useState<BirthAiState | null>(null);
  const [loadingEntities, setLoadingEntities] = useState(true);

  const fetchEntities = useCallback(async () => {
    if (!actor) return;
    try {
      const [ents, st] = await Promise.all([
        (actor as any).listEntities() as Promise<BirthEntity[]>,
        (actor as any).getBirthAiState() as Promise<BirthAiState>,
      ]);
      setEntities(ents);
      setState(st);
      setLoadingEntities(false);
    } catch {
      setLoadingEntities(false);
    }
  }, [actor]);

  useEffect(() => {
    if (!actor || isFetching) return;
    fetchEntities();
    const interval = setInterval(fetchEntities, 3000);
    return () => clearInterval(interval);
  }, [actor, isFetching, fetchEntities]);

  async function handleBirth() {
    if (!actor || !name.trim() || !directive.trim()) return;
    setIsBirthing(true);
    try {
      const id = (await (actor as any).birthAI(
        name.trim(),
        directive.trim(),
        entityType,
      )) as string;
      setLastBornId(id);
      setName("");
      setDirective("");
      toast.success(`Entity born: ${id.slice(0, 8)}...`);
      await fetchEntities();
    } catch {
      toast.error("Birth failed");
    } finally {
      setIsBirthing(false);
    }
  }

  return (
    <div className="max-w-7xl mx-auto" data-ocid="birth-ai.page">
      {/* Page header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <span
            className="font-mono text-lg"
            style={{ color: "oklch(0.65 0.20 30)" }}
          >
            ✦
          </span>
          <h1
            className="font-display font-bold text-xl tracking-[0.3em]"
            style={{ color: "oklch(0.92 0.02 240)" }}
          >
            BIRTH AI
          </h1>
          <span
            className="font-mono text-[8px] tracking-[0.3em] px-2 py-0.5 border"
            style={{
              color: "oklch(0.65 0.20 30)",
              borderColor: "oklch(0.65 0.20 30 / 0.3)",
            }}
          >
            SDK
          </span>
        </div>
        <p
          className="font-mono text-[10px] tracking-wider"
          style={{ color: "oklch(0.42 0.02 240)" }}
        >
          Sovereign entity creation via plain natural language directive
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ── Left: Birth Form ─────────────────────────────────────── */}
        <div
          className="border p-6 space-y-5"
          style={{
            background: "oklch(0.10 0.02 240)",
            borderColor: "oklch(0.65 0.20 30 / 0.25)",
          }}
          data-ocid="birth-ai.birth-panel"
        >
          <div>
            <div
              className="font-mono text-[9px] tracking-[0.4em] mb-4"
              style={{ color: "oklch(0.65 0.20 30)" }}
            >
              BIRTH ENTITY
            </div>

            {/* Name */}
            <div className="space-y-1.5 mb-4">
              <label
                htmlFor="birth-name"
                className="font-mono text-[8px] tracking-[0.3em]"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                ENTITY NAME
              </label>
              <input
                id="birth-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. ANIMUS-PRIME"
                data-ocid="birth-ai.name-input"
                className="w-full bg-transparent border px-3 py-2 font-mono text-sm outline-none transition-all"
                style={{
                  borderColor: "oklch(0.24 0.02 240)",
                  color: "oklch(0.88 0.02 240)",
                }}
              />
            </div>

            {/* Directive */}
            <div className="space-y-1.5 mb-4">
              <label
                htmlFor="birth-directive"
                className="font-mono text-[8px] tracking-[0.3em]"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                DIRECTIVE
              </label>
              <textarea
                id="birth-directive"
                value={directive}
                onChange={(e) => setDirective(e.target.value)}
                placeholder="Describe what you want to create in plain language..."
                data-ocid="birth-ai.directive-textarea"
                rows={6}
                className="w-full bg-transparent border px-3 py-2 font-mono text-xs resize-none outline-none transition-all leading-relaxed"
                style={{
                  borderColor: "oklch(0.24 0.02 240)",
                  color: "oklch(0.80 0.02 240)",
                }}
              />
            </div>

            {/* Entity Type Toggle */}
            <div className="space-y-1.5 mb-5">
              <div
                className="font-mono text-[8px] tracking-[0.3em]"
                style={{ color: "oklch(0.40 0.02 240)" }}
              >
                ENTITY TYPE
              </div>
              <div className="flex gap-2">
                {(["internal", "external"] as const).map((type) => (
                  <button
                    key={type}
                    type="button"
                    onClick={() => setEntityType(type)}
                    data-ocid={`birth-ai.type-toggle.${type}`}
                    className="flex-1 py-2 font-mono text-[9px] tracking-[0.25em] border transition-all"
                    style={{
                      background:
                        entityType === type
                          ? type === "internal"
                            ? "oklch(0.72 0.16 200 / 0.12)"
                            : "oklch(0.72 0.18 65 / 0.12)"
                          : "transparent",
                      borderColor:
                        entityType === type
                          ? type === "internal"
                            ? "oklch(0.72 0.16 200 / 0.6)"
                            : "oklch(0.72 0.18 65 / 0.6)"
                          : "oklch(0.22 0.02 240)",
                      color:
                        entityType === type
                          ? type === "internal"
                            ? "oklch(0.72 0.16 200)"
                            : "oklch(0.72 0.18 65)"
                          : "oklch(0.42 0.02 240)",
                    }}
                  >
                    {type === "internal" ? "INTERNAL" : "EXTERNAL"}
                  </button>
                ))}
              </div>
              <p
                className="font-mono text-[8px]"
                style={{ color: "oklch(0.35 0.02 240)" }}
              >
                {entityType === "internal"
                  ? "Lives and executes inside the organism"
                  : "Deploys as an autonomous external agent"}
              </p>
            </div>

            {/* Birth button */}
            <motion.button
              type="button"
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.98 }}
              onClick={handleBirth}
              disabled={isBirthing || !name.trim() || !directive.trim()}
              data-ocid="birth-ai.birth-button"
              className="w-full py-3 font-mono text-xs tracking-[0.4em] border transition-all disabled:opacity-40"
              style={{
                background: isBirthing
                  ? "oklch(0.65 0.20 30 / 0.15)"
                  : "oklch(0.65 0.20 30 / 0.08)",
                borderColor: "oklch(0.65 0.20 30 / 0.7)",
                color: "oklch(0.65 0.20 30)",
                boxShadow: "0 0 16px oklch(0.65 0.20 30 / 0.08)",
              }}
            >
              {isBirthing ? "BIRTHING..." : "✦ BIRTH"}
            </motion.button>

            {/* Success state */}
            {lastBornId && (
              <motion.div
                initial={{ opacity: 0, y: 4 }}
                animate={{ opacity: 1, y: 0 }}
                className="border p-3 mt-3 space-y-1"
                style={{
                  borderColor: "oklch(0.68 0.18 145 / 0.3)",
                  background: "oklch(0.68 0.18 145 / 0.05)",
                }}
                data-ocid="birth-ai.success_state"
              >
                <div
                  className="font-mono text-[8px] tracking-[0.3em]"
                  style={{ color: "oklch(0.68 0.18 145)" }}
                >
                  ENTITY BORN
                </div>
                <div
                  className="font-mono text-[10px] break-all"
                  style={{ color: "oklch(0.55 0.03 240)" }}
                >
                  {lastBornId}
                </div>
                <div
                  className="font-mono text-[9px] px-2 py-0.5 inline-block border"
                  style={{
                    color: "oklch(0.70 0.20 200)",
                    borderColor: "oklch(0.70 0.20 200 / 0.3)",
                  }}
                >
                  #awakening
                </div>
              </motion.div>
            )}
          </div>
        </div>

        {/* ── Right: Active Entities ───────────────────────────────── */}
        <div className="space-y-4">
          {/* Totals bar */}
          {state && (
            <div
              className="border p-4 grid grid-cols-3 gap-4"
              style={{
                background: "oklch(0.10 0.02 240)",
                borderColor: "oklch(0.20 0.02 240)",
              }}
              data-ocid="birth-ai.totals-bar"
            >
              {[
                { label: "TOTAL BORN", value: Number(state.totalBorn) },
                { label: "TRANSCENDED", value: Number(state.totalTranscended) },
                {
                  label: "LAST BIRTH",
                  value: `B${Number(state.lastBirthBeat).toLocaleString()}`,
                },
              ].map(({ label, value }) => (
                <div key={label} className="text-center">
                  <div
                    className="font-mono text-[7px] tracking-[0.3em] mb-1"
                    style={{ color: "oklch(0.38 0.02 240)" }}
                  >
                    {label}
                  </div>
                  <div
                    className="font-mono text-sm tabular-nums"
                    style={{ color: "oklch(0.78 0.15 85)" }}
                  >
                    {value}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* ORGAN TYPES legend */}
          <div className="flex gap-2 flex-wrap">
            {ORGAN_TYPES.map((t) => (
              <span
                key={t}
                className="font-mono text-[8px] px-2 py-0.5 border"
                style={{
                  color: ORGAN_COLORS[t],
                  borderColor: `${ORGAN_COLORS[t].replace(")", " / 0.25)")}`,
                }}
              >
                {t}
              </span>
            ))}
          </div>

          {/* Entity list */}
          <div
            className="space-y-3 max-h-[600px] overflow-y-auto pr-1"
            data-ocid="birth-ai.entity-list"
          >
            {loadingEntities && (
              <div
                className="border p-8 text-center"
                style={{ borderColor: "oklch(0.18 0.02 240)" }}
                data-ocid="birth-ai.loading_state"
              >
                <div
                  className="font-mono text-[9px] tracking-[0.3em]"
                  style={{ color: "oklch(0.38 0.02 240)" }}
                >
                  LOADING ENTITIES...
                </div>
              </div>
            )}

            {!loadingEntities && entities.length === 0 && (
              <div
                className="border p-10 text-center"
                style={{
                  borderColor: "oklch(0.18 0.02 240)",
                  background: "oklch(0.09 0.01 240)",
                }}
                data-ocid="birth-ai.empty_state"
              >
                <div
                  className="font-mono text-2xl mb-3"
                  style={{ color: "oklch(0.30 0.02 240)" }}
                >
                  ✦
                </div>
                <div
                  className="font-mono text-[9px] tracking-[0.3em] mb-2"
                  style={{ color: "oklch(0.38 0.02 240)" }}
                >
                  NO ENTITIES BORN YET
                </div>
                <p
                  className="font-mono text-[8px]"
                  style={{ color: "oklch(0.28 0.02 240)" }}
                >
                  Use the Birth form to create your first sovereign entity
                </p>
              </div>
            )}

            {entities.map((e) => (
              <EntityCard key={e.id} entity={e} actor={actor} />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
