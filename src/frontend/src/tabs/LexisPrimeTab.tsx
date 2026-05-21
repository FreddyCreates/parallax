import { useState } from "react";

const DOCTRINE_CONCEPTS = [
  {
    concept: "SOVEREIGNTY",
    translation: "S₀=1.0 — floor never falls, all values sovereign at genesis",
  },
  {
    concept: "FORMA",
    translation:
      "Compounding capital engine — starts 1000.0, compounds every beat",
  },
  {
    concept: "COHERENCE",
    translation: "C = max(S₀, Σ R[s]·mean(a[s])/11) — global shell synchrony",
  },
  {
    concept: "PARALLAX",
    translation: "arccos(Σ aᵢ·bᵢ / |a||b|) — angular distance between shells",
  },
  {
    concept: "ENTANGLA",
    translation: "Normalized mutual information across 10 shell pairs",
  },
  {
    concept: "JACOB LADDER",
    translation: "5-rung compliance escalator — each rung gates the next",
  },
  {
    concept: "SACESI",
    translation: "Self-Actualizing Coherence Engine — increments 0.000001/beat",
  },
  {
    concept: "MRC RESERVE",
    translation: "Creator reserve — 100% from parent, 20% from all children",
  },
  {
    concept: "ARES",
    translation:
      "Temporal reversal engine — snapshot ring, best-state recovery",
  },
  {
    concept: "OMNIS SHELL",
    translation:
      "36-node master shell — fires only when all 10 shells coherent",
  },
];

export function LexisPrimeTab() {
  const [input, setInput] = useState("");
  const [result, setResult] = useState<string | null>(null);

  function translate() {
    const match = DOCTRINE_CONCEPTS.find(
      (c) =>
        c.concept.toLowerCase().includes(input.toLowerCase()) ||
        input.toLowerCase().includes(c.concept.toLowerCase()),
    );
    setResult(
      match
        ? match.translation
        : "CONCEPT NOT YET INDEXED — LEXIS PRIME DEPLOYS AT PHASE 8",
    );
  }

  return (
    <div className="space-y-6" data-ocid="lexis.panel">
      <div className="panel-glass p-4">
        <div
          className="font-mono text-[9px] tracking-[0.3em] mb-1"
          style={{ color: "oklch(0.65 0.28 290)" }}
        >
          LEXIS PRIME — DOCTRINE TRANSLATION INTERFACE
        </div>
        <div className="font-mono text-[8px] text-muted-foreground">
          CREATOR-ONLY · PHASE 8 DEPLOYMENT · DOCTRINE PROCESSOR ONLINE
        </div>
      </div>

      <div className="panel-glass p-5">
        <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground mb-4">
          SUBSTRATE TRANSLATION
        </div>
        <div className="flex gap-3">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && translate()}
            placeholder="ENTER CONCEPT FOR SUBSTRATE TRANSLATION"
            data-ocid="lexis.input"
            className="flex-1 bg-black/40 border border-white/10 px-4 py-2.5 font-mono text-xs text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-white/20"
            style={{ caretColor: "oklch(0.65 0.28 290)" }}
          />
          <button
            type="button"
            onClick={translate}
            data-ocid="lexis.submit_button"
            className="px-5 py-2.5 font-mono text-xs tracking-[0.2em] border transition-all"
            style={{
              borderColor: "oklch(0.65 0.28 290 / 0.5)",
              color: "oklch(0.65 0.28 290)",
            }}
          >
            TRANSLATE
          </button>
        </div>
        {result && (
          <div
            className="mt-4 p-3 border-l-2"
            style={{
              borderColor: "oklch(0.65 0.28 290)",
              background: "oklch(0.65 0.28 290 / 0.05)",
            }}
          >
            <div className="font-mono text-[9px] text-muted-foreground mb-1">
              TRANSLATION OUTPUT
            </div>
            <div
              className="font-mono text-xs"
              style={{ color: "oklch(0.72 0.15 200)" }}
            >
              {result}
            </div>
          </div>
        )}
      </div>

      <div className="panel-glass p-5">
        <div className="font-mono text-[8px] tracking-[0.4em] text-muted-foreground mb-4">
          KEY DOCTRINE CONCEPTS — ZERO EXPOSURE SURFACE
        </div>
        <div className="space-y-2">
          {DOCTRINE_CONCEPTS.map((c) => (
            <div
              key={c.concept}
              className="flex gap-4 py-2 border-b border-white/5"
            >
              <span
                className="font-mono text-[9px] tracking-[0.1em] w-28 shrink-0"
                style={{ color: "oklch(0.65 0.28 290)" }}
              >
                {c.concept}
              </span>
              <span className="font-mono text-[8px] text-muted-foreground leading-relaxed">
                {c.translation}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="panel-glass p-4 flex items-center justify-between">
        <div>
          <div className="font-mono text-[8px] tracking-[0.3em] text-muted-foreground">
            DOCTRINE ALIGNMENT SCORE
          </div>
          <div className="font-mono text-[7px] text-muted-foreground mt-0.5">
            VERITAS COHERENCE · L-60 COMPLIANCE
          </div>
        </div>
        <div
          className="font-mono text-3xl"
          style={{
            color: "oklch(0.65 0.28 290)",
            textShadow: "0 0 16px oklch(0.65 0.28 290 / 0.5)",
          }}
        >
          1.0000
        </div>
      </div>
    </div>
  );
}
