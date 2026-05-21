import { useEffect, useRef } from "react";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
}

function formatTs(ns: number): string {
  if (!ns) return "--:--:--";
  const ms = ns / 1_000_000;
  const d = new Date(ms);
  return d.toLocaleTimeString("en-US", { hour12: false });
}

export function ThoughtRecord({ data }: Props) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const { thoughts, treasury } = data;

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = 0;
    }
  }, []);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between border-b border-[#2A2C33] pb-2">
        <span className="text-[10px] text-[#9AA0AA] tracking-widest uppercase">
          ENGINE THOUGHT RECORD — COGNITION LOG
        </span>
        <div className="flex items-center gap-2">
          <div className="w-1.5 h-1.5 rounded-full bg-[#44D17B] animate-pulse" />
          <span className="text-[9px] text-[#44D17B] tracking-widest">
            LIVE
          </span>
          <span className="text-[9px] text-[#6F7580] tracking-widest">
            {thoughts.length} ENTRIES
          </span>
        </div>
      </div>

      {/* Engine stats */}
      <div className="grid grid-cols-3 gap-3">
        {[
          {
            label: "ENGINE IQ",
            value: `${(treasury.engineIntelligenceScore * 10).toFixed(3)}%`,
          },
          {
            label: "COHERENCE",
            value: `${(treasury.systemCoherenceScore * 100).toFixed(2)}%`,
          },
          { label: "BEAT", value: treasury.beatCount.toLocaleString() },
        ].map((s) => (
          <div
            key={s.label}
            className="bg-[#0D1A0F] border border-[#1A3A1F] p-3 text-center"
          >
            <div className="text-[9px] text-[#44D17B]/60 tracking-widest">
              {s.label}
            </div>
            <div className="font-mono text-sm text-[#44D17B] font-bold">
              {s.value}
            </div>
          </div>
        ))}
      </div>

      {/* Log terminal */}
      <div
        ref={scrollRef}
        className="bg-[#080E09] border border-[#1A3A1F] p-4 font-mono text-[10px] text-[#44D17B] overflow-y-auto"
        style={{ height: 480, overflowY: "auto" }}
      >
        {thoughts.length === 0 ? (
          <div className="text-[#44D17B]/40 tracking-widest animate-pulse">
            WAITING FOR ENGINE... BEAT COUNT ACCUMULATING...
          </div>
        ) : (
          thoughts.map((t, i) => (
            <div
              key={t.beat}
              className={`mb-4 ${i === 0 ? "text-[#44D17B]" : "text-[#44D17B]/60"}`}
            >
              <div className="text-[#44D17B]/80 mb-0.5">
                [BEAT-{String(t.beat).padStart(6, "0")}] [
                {formatTs(t.timestamp)}]
              </div>
              <div className="ml-2">
                <span className="text-[#6B7FDB]/80">INGEST:</span> {t.ingested}
              </div>
              <div className="ml-2">
                <span className="text-[#D7B24A]/80">COMPUTE:</span> {t.computed}
              </div>
              <div className="ml-2">
                <span className="text-[#D6B36A]/80">DECIDED:</span>{" "}
                <span className="text-[#D6B36A] font-bold">{t.decided}</span>
              </div>
              <div className="ml-2">
                <span className="text-[#44D17B]/80">EXECUTED:</span>{" "}
                {t.executed}
              </div>
              <div className="ml-2">
                <span className="text-[#B23A3E]/80">YIELD:</span>{" "}
                <span className="text-[#B23A3E]">
                  ${t.yieldCaptured.toFixed(6)} USD-EQ
                </span>
              </div>
              <div className="ml-2">
                <span className="text-[#9AA0AA]/60">WATCHING:</span>{" "}
                {t.watching}
              </div>
              {i < thoughts.length - 1 && (
                <div className="border-t border-[#1A3A1F] mt-3" />
              )}
            </div>
          ))
        )}

        {/* Live cursor */}
        <div className="text-[#44D17B] animate-pulse">_</div>
      </div>
    </div>
  );
}
