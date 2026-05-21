/**
 * BuilderTab — Builder SDK Interface
 * Submit plain natural language directives. The Builder interprets, dissects, and builds.
 * Zero-Exposure enforced.
 */

import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import type { BuilderDirective, BuilderState } from "../backend";
import { DirectiveStatus, TargetType } from "../backend";
import { useActor } from "../hooks/useActor";

// ── Helpers ──────────────────────────────────────────────────────────────────

function statusColor(s: DirectiveStatus): string {
  if (s === DirectiveStatus.complete) return "oklch(0.68 0.18 145)";
  if (s === DirectiveStatus.failed) return "oklch(0.55 0.22 25)";
  if (s === DirectiveStatus.building) return "oklch(0.72 0.18 190)";
  return "oklch(0.65 0.14 65)"; // parsed
}

function statusLabel(s: DirectiveStatus): string {
  if (s === DirectiveStatus.complete) return "#complete";
  if (s === DirectiveStatus.failed) return "#failed";
  if (s === DirectiveStatus.building) return "#building";
  return "#parsed";
}

function targetColor(t: TargetType): string {
  if (t === TargetType.entity) return "oklch(0.65 0.20 290)";
  if (t === TargetType.agent) return "oklch(0.70 0.20 200)";
  if (t === TargetType.canister) return "oklch(0.72 0.16 65)";
  if (t === TargetType.protocol) return "oklch(0.72 0.18 190)";
  return "oklch(0.50 0.04 240)";
}

function formatTs(ts: bigint): string {
  const ms = Number(ts);
  if (!ms) return "—";
  return new Date(ms).toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

// ── Directive Card ────────────────────────────────────────────────────────────

function DirectiveCard({ d }: { d: BuilderDirective }) {
  const [expanded, setExpanded] = useState(false);
  const sc = statusColor(d.status);
  const tc = targetColor(d.targetType);

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      className="border p-4 space-y-2"
      style={{
        background: "oklch(0.11 0.02 240)",
        borderColor:
          d.status === DirectiveStatus.complete
            ? "oklch(0.68 0.18 145 / 0.3)"
            : d.status === DirectiveStatus.failed
              ? "oklch(0.55 0.22 25 / 0.3)"
              : "oklch(0.20 0.02 240)",
      }}
      data-ocid={`builder.directive.${d.id.slice(-4)}`}
    >
      <div className="flex items-start justify-between gap-3 min-w-0">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              {d.id.slice(0, 8)}
            </span>
            <span
              className="font-mono text-[9px] px-1.5 py-0.5 border"
              style={{
                color: sc,
                borderColor: `${sc.replace(")", " / 0.3)")}`,
              }}
            >
              {statusLabel(d.status)}
            </span>
            <span
              className="font-mono text-[9px] px-1.5 py-0.5 border"
              style={{
                color: tc,
                borderColor: `${tc.replace(")", " / 0.3)")}`,
              }}
            >
              {d.targetType.toUpperCase()}
            </span>
            <span
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              {formatTs(d.timestamp)}
            </span>
          </div>
          <p
            className="font-mono text-[10px] truncate"
            style={{ color: "oklch(0.58 0.04 240)" }}
            title={d.rawText}
          >
            {d.rawText.slice(0, 80)}
            {d.rawText.length > 80 ? "..." : ""}
          </p>
          {d.parsedIntent && (
            <p
              className="font-mono text-[9px] mt-0.5"
              style={{ color: "oklch(0.48 0.08 240)" }}
            >
              → {d.parsedIntent}
            </p>
          )}
          {d.outputId && (
            <div
              className="font-mono text-[8px] mt-1"
              style={{ color: "oklch(0.50 0.10 145)" }}
            >
              OUTPUT: {d.outputId.slice(0, 16)}...
            </div>
          )}
        </div>
        {d.parameters.length > 0 && (
          <button
            type="button"
            onClick={() => setExpanded((e) => !e)}
            data-ocid={`builder.directive-expand.${d.id.slice(-4)}`}
            className="font-mono text-[9px] border px-2 py-1 shrink-0 transition-all"
            style={{
              color: "oklch(0.40 0.02 240)",
              borderColor: "oklch(0.20 0.02 240)",
            }}
          >
            {expanded ? "▲" : "▼"}
          </button>
        )}
      </div>

      <AnimatePresence>
        {expanded && d.parameters.length > 0 && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.15 }}
            className="overflow-hidden border-t pt-2 space-y-1"
            style={{ borderColor: "oklch(0.17 0.02 240)" }}
          >
            <div
              className="font-mono text-[7px] tracking-[0.3em] mb-1"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              EXTRACTED PARAMETERS
            </div>
            {d.parameters.map(([k, v]) => (
              <div key={k} className="flex gap-2 font-mono text-[9px]">
                <span style={{ color: "oklch(0.50 0.10 240)" }}>{k}:</span>
                <span style={{ color: "oklch(0.62 0.06 240)" }}>{v}</span>
              </div>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

// ── Main Tab ──────────────────────────────────────────────────────────────────

export function BuilderTab() {
  const { actor, isFetching } = useActor();

  // Input
  const [rawText, setRawText] = useState("");
  const [isParsing, setIsParsing] = useState(false);
  const [isExecuting, setIsExecuting] = useState(false);
  const [parsePreview, setParsePreview] = useState<BuilderDirective | null>(
    null,
  );
  const [execResult, setExecResult] = useState<string | null>(null);

  // History
  const [directives, setDirectives] = useState<BuilderDirective[]>([]);
  const [builderState, setBuilderState] = useState<BuilderState | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchDirectives = useCallback(async () => {
    if (!actor) return;
    try {
      const [dirs, st] = await Promise.all([
        (actor as any).listBuilderDirectives() as Promise<BuilderDirective[]>,
        (actor as any).getBuilderState() as Promise<BuilderState>,
      ]);
      // Sort by timestamp desc
      const sorted = [...dirs].sort(
        (a, b) => Number(b.timestamp) - Number(a.timestamp),
      );
      setDirectives(sorted);
      setBuilderState(st);
      setLoading(false);
    } catch {
      setLoading(false);
    }
  }, [actor]);

  useEffect(() => {
    if (!actor || isFetching) return;
    fetchDirectives();
    const interval = setInterval(fetchDirectives, 3000);
    return () => clearInterval(interval);
  }, [actor, isFetching, fetchDirectives]);

  async function handleParseBuild() {
    if (!actor || !rawText.trim()) return;
    setIsParsing(true);
    setParsePreview(null);
    setExecResult(null);
    try {
      const directiveId = (await (actor as any).submitBuilderDirective(
        rawText.trim(),
      )) as string;

      // Find the parsed directive in state for preview
      const dirs = (await (
        actor as any
      ).listBuilderDirectives()) as BuilderDirective[];
      const found =
        dirs.find((d: BuilderDirective) => d.id === directiveId) ?? null;
      setParsePreview(found);

      // Auto-execute
      setIsExecuting(true);
      const result = (await (actor as any).executeBuilderDirective(
        directiveId,
      )) as string;
      setExecResult(result);
      toast.success("Builder executed directive");
      setRawText("");
      await fetchDirectives();
    } catch {
      toast.error("Builder failed");
    } finally {
      setIsParsing(false);
      setIsExecuting(false);
    }
  }

  const isWorking = isParsing || isExecuting;
  const workingLabel = isExecuting
    ? "EXECUTING..."
    : isParsing
      ? "PARSING..."
      : "PARSE + BUILD";

  return (
    <div className="max-w-5xl mx-auto" data-ocid="builder.page">
      {/* Page header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-1">
          <span
            className="font-mono text-lg"
            style={{ color: "oklch(0.65 0.18 145)" }}
          >
            ⚙
          </span>
          <h1
            className="font-display font-bold text-xl tracking-[0.3em]"
            style={{ color: "oklch(0.92 0.02 240)" }}
          >
            BUILDER SDK
          </h1>
          <span
            className="font-mono text-[8px] tracking-[0.3em] px-2 py-0.5 border"
            style={{
              color: "oklch(0.65 0.18 145)",
              borderColor: "oklch(0.65 0.18 145 / 0.3)",
            }}
          >
            NL INPUT
          </span>
        </div>
        <p
          className="font-mono text-[10px] tracking-wider"
          style={{ color: "oklch(0.42 0.02 240)" }}
        >
          Submit directives in plain language. The Builder interprets, dissects,
          and builds.
        </p>
      </div>

      {/* ── Directive Input ────────────────────────────────────────── */}
      <div
        className="border p-6 mb-6 space-y-4"
        style={{
          background: "oklch(0.10 0.02 240)",
          borderColor: "oklch(0.65 0.18 145 / 0.22)",
        }}
        data-ocid="builder.input-panel"
      >
        <div
          className="font-mono text-[9px] tracking-[0.4em]"
          style={{ color: "oklch(0.65 0.18 145)" }}
        >
          DIRECTIVE INPUT
        </div>

        <textarea
          value={rawText}
          onChange={(e) => setRawText(e.target.value)}
          placeholder="Type any directive in plain language. The Builder will interpret it, dissect the structure, and build what is needed."
          data-ocid="builder.directive-textarea"
          rows={7}
          className="w-full bg-transparent border px-4 py-3 font-mono text-sm resize-none outline-none transition-all leading-relaxed"
          style={{
            borderColor: "oklch(0.24 0.02 240)",
            color: "oklch(0.82 0.02 240)",
          }}
        />

        <motion.button
          type="button"
          whileHover={{ scale: 1.005 }}
          whileTap={{ scale: 0.995 }}
          onClick={handleParseBuild}
          disabled={isWorking || !rawText.trim()}
          data-ocid="builder.parse-build-button"
          className="w-full py-3 font-mono text-xs tracking-[0.4em] border transition-all disabled:opacity-40"
          style={{
            background: isWorking
              ? "oklch(0.65 0.18 145 / 0.18)"
              : "oklch(0.65 0.18 145 / 0.08)",
            borderColor: "oklch(0.65 0.18 145 / 0.65)",
            color: "oklch(0.65 0.18 145)",
            boxShadow: "0 0 16px oklch(0.65 0.18 145 / 0.08)",
          }}
        >
          {workingLabel}
        </motion.button>

        {/* Parse preview */}
        <AnimatePresence>
          {parsePreview && (
            <motion.div
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="border p-4 space-y-2"
              style={{
                borderColor: "oklch(0.65 0.14 65 / 0.3)",
                background: "oklch(0.65 0.14 65 / 0.04)",
              }}
              data-ocid="builder.parse-preview"
            >
              <div
                className="font-mono text-[8px] tracking-[0.3em]"
                style={{ color: "oklch(0.65 0.14 65)" }}
              >
                PARSE PREVIEW
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <div
                    className="font-mono text-[7px] tracking-widest mb-0.5"
                    style={{ color: "oklch(0.38 0.02 240)" }}
                  >
                    INTENT
                  </div>
                  <div
                    className="font-mono text-[10px]"
                    style={{ color: "oklch(0.65 0.08 240)" }}
                  >
                    {parsePreview.parsedIntent || "—"}
                  </div>
                </div>
                <div>
                  <div
                    className="font-mono text-[7px] tracking-widest mb-0.5"
                    style={{ color: "oklch(0.38 0.02 240)" }}
                  >
                    TARGET
                  </div>
                  <div
                    className="font-mono text-[10px]"
                    style={{ color: targetColor(parsePreview.targetType) }}
                  >
                    {parsePreview.targetType.toUpperCase()}
                  </div>
                </div>
              </div>
              {parsePreview.parameters.length > 0 && (
                <div>
                  <div
                    className="font-mono text-[7px] tracking-widest mb-1"
                    style={{ color: "oklch(0.38 0.02 240)" }}
                  >
                    PARAMETERS
                  </div>
                  <div className="grid grid-cols-2 gap-1">
                    {parsePreview.parameters.map(([k, v]) => (
                      <div key={k} className="font-mono text-[9px]">
                        <span style={{ color: "oklch(0.48 0.10 240)" }}>
                          {k}:{" "}
                        </span>
                        <span style={{ color: "oklch(0.60 0.06 240)" }}>
                          {v}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </motion.div>
          )}
        </AnimatePresence>

        {/* Execution result */}
        <AnimatePresence>
          {execResult && (
            <motion.div
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="border p-4"
              style={{
                borderColor: "oklch(0.68 0.18 145 / 0.35)",
                background: "oklch(0.68 0.18 145 / 0.05)",
              }}
              data-ocid="builder.exec-result.success_state"
            >
              <div
                className="font-mono text-[8px] tracking-[0.3em] mb-1"
                style={{ color: "oklch(0.68 0.18 145)" }}
              >
                EXECUTION RESULT
              </div>
              <div
                className="font-mono text-[10px]"
                style={{ color: "oklch(0.58 0.06 240)" }}
              >
                {execResult}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* ── Directive History ──────────────────────────────────────── */}
      <div
        className="border p-6 space-y-4"
        style={{
          background: "oklch(0.09 0.01 240)",
          borderColor: "oklch(0.20 0.02 240)",
        }}
        data-ocid="builder.history-panel"
      >
        <div className="flex items-center justify-between">
          <div
            className="font-mono text-[9px] tracking-[0.4em]"
            style={{ color: "oklch(0.42 0.02 240)" }}
          >
            DIRECTIVE HISTORY
          </div>
          {builderState && (
            <div className="flex items-center gap-4">
              <div className="text-right">
                <span
                  className="font-mono text-[8px]"
                  style={{ color: "oklch(0.38 0.02 240)" }}
                >
                  BUILT{" "}
                </span>
                <span
                  className="font-mono text-[10px] tabular-nums"
                  style={{ color: "oklch(0.68 0.18 145)" }}
                >
                  {Number(builderState.totalBuilt)}
                </span>
              </div>
              <div>
                <span
                  className="font-mono text-[8px]"
                  style={{ color: "oklch(0.38 0.02 240)" }}
                >
                  FAILED{" "}
                </span>
                <span
                  className="font-mono text-[10px] tabular-nums"
                  style={{ color: "oklch(0.55 0.22 25)" }}
                >
                  {Number(builderState.totalFailed)}
                </span>
              </div>
            </div>
          )}
        </div>

        {loading && (
          <div className="py-10 text-center" data-ocid="builder.loading_state">
            <div
              className="font-mono text-[9px] tracking-[0.3em]"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              LOADING DIRECTIVES...
            </div>
          </div>
        )}

        {!loading && directives.length === 0 && (
          <div
            className="py-12 text-center border"
            style={{
              borderColor: "oklch(0.16 0.02 240)",
              background: "oklch(0.085 0.01 240)",
            }}
            data-ocid="builder.empty_state"
          >
            <div
              className="font-mono text-xl mb-2"
              style={{ color: "oklch(0.28 0.02 240)" }}
            >
              ⚙
            </div>
            <div
              className="font-mono text-[9px] tracking-[0.3em] mb-1"
              style={{ color: "oklch(0.35 0.02 240)" }}
            >
              NO DIRECTIVES YET
            </div>
            <p
              className="font-mono text-[8px]"
              style={{ color: "oklch(0.28 0.02 240)" }}
            >
              Type a directive above to start building
            </p>
          </div>
        )}

        {!loading && directives.length > 0 && (
          <div className="space-y-3 max-h-[500px] overflow-y-auto pr-1">
            {directives.map((d) => (
              <DirectiveCard key={d.id} d={d} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
