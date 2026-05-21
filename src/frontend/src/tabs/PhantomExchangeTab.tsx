import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";

// ── Color constants ─────────────────────────────────────────────────
const C = {
  gold: "oklch(0.78 0.18 85)",
  goldDim: "rgba(200,160,60,0.12)",
  cyan: "oklch(0.72 0.15 200)",
  purple: "oklch(0.65 0.28 290)",
  green: "oklch(0.62 0.17 145)",
  red: "oklch(0.55 0.22 25)",
  amber: "oklch(0.75 0.18 62)",
  silver: "oklch(0.72 0.04 270)",
  dim: "oklch(0.35 0.05 270)",
  text: "oklch(0.92 0.02 270)",
  muted: "oklch(0.45 0.04 270)",
  bg: "oklch(0.04 0.01 270)",
  bgPanel: "rgba(4,4,8,0.92)",
  border: "rgba(255,255,255,0.06)",
  borderGold: "rgba(200,160,60,0.2)",
  phantom: "oklch(0.60 0.25 280)",
  phantomDim: "rgba(130,80,220,0.12)",
};

// ── Trading pair categories ─────────────────────────────────────────
const PAIR_CATEGORIES = [
  { id: "sovereign", label: "SOVEREIGN", color: C.gold },
  { id: "crypto", label: "CRYPTO", color: C.cyan },
  { id: "ai", label: "AI TOKENS", color: C.phantom },
  { id: "artifact", label: "AI ARTIFACTS", color: C.purple },
  { id: "creator", label: "CREATOR", color: C.amber },
];

const DEFAULT_PAIRS = [
  { pairId: "GTK_ICP", base: "GTK", quote: "ICP", category: "sovereign" },
  { pairId: "MTC_ICP", base: "MTC", quote: "ICP", category: "sovereign" },
  { pairId: "MTH_ICP", base: "MTH", quote: "ICP", category: "sovereign" },
  { pairId: "BTC_ICP", base: "BTC", quote: "ICP", category: "crypto" },
  { pairId: "ETH_ICP", base: "ETH", quote: "ICP", category: "crypto" },
  { pairId: "AICPU_ICP", base: "AICPU", quote: "ICP", category: "ai" },
  { pairId: "AIMEM_ICP", base: "AIMEM", quote: "ICP", category: "ai" },
  { pairId: "AIINF_ICP", base: "AIINF", quote: "ICP", category: "ai" },
  { pairId: "AITRAIN_ICP", base: "AITRAIN", quote: "ICP", category: "ai" },
  { pairId: "AIDATA_ICP", base: "AIDATA", quote: "ICP", category: "ai" },
  { pairId: "AIMDL_MTC", base: "AIMDL", quote: "MTC", category: "artifact" },
  { pairId: "AIEMB_MTC", base: "AIEMB", quote: "MTC", category: "artifact" },
  { pairId: "AIPROT_MTC", base: "AIPROT", quote: "MTC", category: "artifact" },
  { pairId: "MEDINA_ICP", base: "MEDINA", quote: "ICP", category: "creator" },
  { pairId: "MEDINA_MTC", base: "MEDINA", quote: "MTC", category: "creator" },
];

interface OrderEntry {
  orderId: number;
  pairId: string;
  side: "buy" | "sell";
  price: number;
  quantity: number;
  status: string;
  beat: number;
}

interface FillEntry {
  fillId: number;
  pairId: string;
  price: number;
  quantity: number;
  buyer: string;
  seller: string;
  beat: number;
}

interface IntelSignal {
  signalId: number;
  tokenPair: string;
  magnitude: number;
  confidence: number;
  sourceLayer: string;
}

// ══════════════════════════════════════════════════════════════════════
// PhantomExchangeTab — Zero-Gas-Fee Trading & AI Artifact Marketplace
// ══════════════════════════════════════════════════════════════════════

export default function PhantomExchangeTab() {
  const { actor } = useActor();
  const { identity } = useInternetIdentity();

  // State
  const [selectedCategory, setSelectedCategory] = useState("sovereign");
  const [selectedPair, setSelectedPair] = useState(DEFAULT_PAIRS[0]);
  const [orderSide, setOrderSide] = useState<"buy" | "sell">("buy");
  const [orderPrice, setOrderPrice] = useState("");
  const [orderQuantity, setOrderQuantity] = useState("");
  const [recentFills, setRecentFills] = useState<FillEntry[]>([]);
  const [exchangeStats, setExchangeStats] = useState({
    totalFills: 0,
    totalVolume: 0,
    totalPairs: 0,
    feesCollected: 0,
    gasSaved: 0,
    settlementVelocity: 0,
    intelligenceActive: true,
    coherenceGate: 0.618,
  });
  const [intelSignals, setIntelSignals] = useState<IntelSignal[]>([]);
  const [artifacts, setArtifacts] = useState<any[]>([]);
  const [customTokens, setCustomTokens] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  // Filter pairs by category
  const filteredPairs = useMemo(
    () => DEFAULT_PAIRS.filter((p) => p.category === selectedCategory),
    [selectedCategory],
  );

  // Fetch exchange state
  const fetchState = useCallback(async () => {
    if (!actor) return;
    try {
      const [exchangeState, clearingState, intelState, artState, tokenState] =
        await Promise.all([
          actor.getPhantomExchangeState().catch(() => null),
          actor.getPhantomClearinghouseState().catch(() => null),
          actor.getPhantomIntelligenceState().catch(() => null),
          actor.getTradeableArtifacts().catch(() => []),
          actor.getAllCustomTokens().catch(() => []),
        ]);

      if (exchangeState) {
        setExchangeStats((prev) => ({
          ...prev,
          totalFills: Number(exchangeState.totalFills ?? 0),
          totalVolume: Number(exchangeState.totalVolumeICP ?? 0),
          totalPairs: Number(exchangeState.totalPairs ?? 0),
          feesCollected: Number(exchangeState.totalFeesCollected ?? 0),
        }));
        if (exchangeState.recentFills) {
          setRecentFills(
            (exchangeState.recentFills as any[]).slice(-20).map((f: any) => ({
              fillId: Number(f.fillId),
              pairId: f.pairId,
              price: Number(f.price),
              quantity: Number(f.quantity),
              buyer: f.buyerPrincipal?.slice(0, 8) ?? "",
              seller: f.sellerPrincipal?.slice(0, 8) ?? "",
              beat: Number(f.fillBeat),
            })),
          );
        }
      }

      if (clearingState) {
        setExchangeStats((prev) => ({
          ...prev,
          gasSaved: Number(clearingState.totalGasFeesSaved ?? 0),
          settlementVelocity: Number(
            clearingState.settlementVelocity ?? 0,
          ),
        }));
      }

      if (intelState) {
        setExchangeStats((prev) => ({
          ...prev,
          intelligenceActive: intelState.intelligenceActive ?? true,
          coherenceGate: Number(intelState.coherenceGate ?? 0.618),
        }));
        if (intelState.activeSignals) {
          setIntelSignals(
            (intelState.activeSignals as any[]).slice(-10).map((s: any) => ({
              signalId: Number(s.signalId),
              tokenPair: s.tokenPair,
              magnitude: Number(s.magnitude),
              confidence: Number(s.confidence),
              sourceLayer: s.sourceLayer,
            })),
          );
        }
      }

      if (artState) setArtifacts(artState as any[]);
      if (tokenState) setCustomTokens(tokenState as any[]);
    } catch (e) {
      console.error("Phantom Exchange fetch error:", e);
    }
  }, [actor]);

  useEffect(() => {
    fetchState();
    const interval = setInterval(fetchState, 5000);
    return () => clearInterval(interval);
  }, [fetchState]);

  // Place order
  const handlePlaceOrder = async () => {
    if (!actor || !orderPrice || !orderQuantity) return;
    setLoading(true);
    try {
      await actor.placeOrder(
        selectedPair.pairId,
        orderSide,
        "limit",
        Number.parseFloat(orderPrice),
        Number.parseFloat(orderQuantity),
      );
      toast.success(
        `${orderSide.toUpperCase()} order placed — ${orderQuantity} ${selectedPair.base} @ ${orderPrice} ${selectedPair.quote} — ZERO GAS`,
      );
      setOrderPrice("");
      setOrderQuantity("");
      fetchState();
    } catch (e) {
      toast.error(`Order failed: ${e}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        padding: "1.5rem",
        background: C.bg,
        minHeight: "100vh",
        color: C.text,
      }}
    >
      {/* ═══ HEADER ═══ */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        style={{ marginBottom: "2rem" }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "1rem",
            marginBottom: "0.5rem",
          }}
        >
          <h1
            style={{
              fontSize: "1.75rem",
              fontWeight: 700,
              color: C.phantom,
              margin: 0,
            }}
          >
            ◈ PHANTOM EXCHANGE
          </h1>
          <span
            style={{
              fontSize: "0.7rem",
              padding: "0.2rem 0.6rem",
              background: "rgba(80,220,80,0.1)",
              color: C.green,
              borderRadius: "0.25rem",
              border: `1px solid rgba(80,220,80,0.2)`,
            }}
          >
            ZERO GAS
          </span>
          <span
            style={{
              fontSize: "0.7rem",
              padding: "0.2rem 0.6rem",
              background: C.phantomDim,
              color: C.phantom,
              borderRadius: "0.25rem",
              border: `1px solid rgba(130,80,220,0.3)`,
            }}
          >
            AI-POWERED
          </span>
        </div>
        <p style={{ color: C.muted, fontSize: "0.8rem", margin: 0 }}>
          Trade ALL tokens — crypto, AI tokens, AI artifacts, sovereign tokens,
          creator tokens — with ZERO gas fees. Intelligence-gated. Instant
          settlement.
        </p>
      </motion.div>

      {/* ═══ STATS BAR ═══ */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
          gap: "0.75rem",
          marginBottom: "1.5rem",
        }}
      >
        {[
          {
            label: "Total Volume",
            value: `${exchangeStats.totalVolume.toFixed(2)} ICP`,
            color: C.gold,
          },
          {
            label: "Total Fills",
            value: exchangeStats.totalFills.toLocaleString(),
            color: C.cyan,
          },
          {
            label: "Trading Pairs",
            value: exchangeStats.totalPairs.toString(),
            color: C.phantom,
          },
          {
            label: "Gas Fees",
            value: "0.000 ICP",
            color: C.green,
          },
          {
            label: "Gas Saved",
            value: `$${exchangeStats.gasSaved.toFixed(0)}`,
            color: C.amber,
          },
          {
            label: "Settlement",
            value: "0.3ms",
            color: C.purple,
          },
          {
            label: "AI Coherence",
            value: exchangeStats.coherenceGate.toFixed(3),
            color: exchangeStats.coherenceGate >= 0.618 ? C.green : C.red,
          },
          {
            label: "Intelligence",
            value: exchangeStats.intelligenceActive ? "ACTIVE" : "GATED",
            color: exchangeStats.intelligenceActive ? C.green : C.red,
          },
        ].map((stat) => (
          <div
            key={stat.label}
            style={{
              padding: "0.75rem",
              background: C.bgPanel,
              border: `1px solid ${C.border}`,
              borderRadius: "0.5rem",
            }}
          >
            <div
              style={{ fontSize: "0.6rem", color: C.muted, marginBottom: "0.25rem" }}
            >
              {stat.label}
            </div>
            <div style={{ fontSize: "1rem", fontWeight: 600, color: stat.color }}>
              {stat.value}
            </div>
          </div>
        ))}
      </div>

      {/* ═══ MAIN CONTENT ═══ */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 320px",
          gap: "1.5rem",
        }}
      >
        {/* ─── LEFT: Order Book & Trading ─── */}
        <div>
          {/* Category selector */}
          <div
            style={{
              display: "flex",
              gap: "0.5rem",
              marginBottom: "1rem",
              flexWrap: "wrap",
            }}
          >
            {PAIR_CATEGORIES.map((cat) => (
              <button
                type="button"
                key={cat.id}
                onClick={() => {
                  setSelectedCategory(cat.id);
                  const first = DEFAULT_PAIRS.find((p) => p.category === cat.id);
                  if (first) setSelectedPair(first);
                }}
                style={{
                  padding: "0.4rem 0.8rem",
                  fontSize: "0.7rem",
                  fontWeight: 600,
                  background:
                    selectedCategory === cat.id
                      ? `${cat.color}22`
                      : "transparent",
                  color: selectedCategory === cat.id ? cat.color : C.muted,
                  border: `1px solid ${selectedCategory === cat.id ? cat.color : C.border}`,
                  borderRadius: "0.3rem",
                  cursor: "pointer",
                }}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {/* Pair selector */}
          <div
            style={{
              display: "flex",
              gap: "0.4rem",
              marginBottom: "1rem",
              flexWrap: "wrap",
            }}
          >
            {filteredPairs.map((pair) => (
              <button
                type="button"
                key={pair.pairId}
                onClick={() => setSelectedPair(pair)}
                style={{
                  padding: "0.3rem 0.6rem",
                  fontSize: "0.65rem",
                  background:
                    selectedPair.pairId === pair.pairId ? C.goldDim : "transparent",
                  color:
                    selectedPair.pairId === pair.pairId ? C.gold : C.muted,
                  border: `1px solid ${selectedPair.pairId === pair.pairId ? C.borderGold : C.border}`,
                  borderRadius: "0.25rem",
                  cursor: "pointer",
                }}
              >
                {pair.base}/{pair.quote}
              </button>
            ))}
          </div>

          {/* Order form */}
          <div
            style={{
              padding: "1.25rem",
              background: C.bgPanel,
              border: `1px solid ${C.border}`,
              borderRadius: "0.5rem",
              marginBottom: "1.5rem",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: "1rem",
              }}
            >
              <span style={{ fontSize: "0.9rem", fontWeight: 600 }}>
                {selectedPair.base}/{selectedPair.quote}
              </span>
              <div style={{ display: "flex", gap: "0.5rem" }}>
                <button
                  type="button"
                  onClick={() => setOrderSide("buy")}
                  style={{
                    padding: "0.3rem 1rem",
                    fontSize: "0.7rem",
                    fontWeight: 600,
                    background: orderSide === "buy" ? "rgba(80,180,80,0.15)" : "transparent",
                    color: orderSide === "buy" ? C.green : C.muted,
                    border: `1px solid ${orderSide === "buy" ? "rgba(80,180,80,0.4)" : C.border}`,
                    borderRadius: "0.25rem",
                    cursor: "pointer",
                  }}
                >
                  BUY
                </button>
                <button
                  type="button"
                  onClick={() => setOrderSide("sell")}
                  style={{
                    padding: "0.3rem 1rem",
                    fontSize: "0.7rem",
                    fontWeight: 600,
                    background: orderSide === "sell" ? "rgba(220,60,60,0.15)" : "transparent",
                    color: orderSide === "sell" ? C.red : C.muted,
                    border: `1px solid ${orderSide === "sell" ? "rgba(220,60,60,0.4)" : C.border}`,
                    borderRadius: "0.25rem",
                    cursor: "pointer",
                  }}
                >
                  SELL
                </button>
              </div>
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0.75rem", marginBottom: "1rem" }}>
              <div>
                <label style={{ fontSize: "0.6rem", color: C.muted, display: "block", marginBottom: "0.25rem" }}>
                  PRICE ({selectedPair.quote})
                </label>
                <input
                  type="number"
                  value={orderPrice}
                  onChange={(e) => setOrderPrice(e.target.value)}
                  placeholder="0.0000"
                  style={{
                    width: "100%",
                    padding: "0.5rem",
                    fontSize: "0.85rem",
                    background: "rgba(255,255,255,0.03)",
                    border: `1px solid ${C.border}`,
                    borderRadius: "0.3rem",
                    color: C.text,
                    outline: "none",
                  }}
                />
              </div>
              <div>
                <label style={{ fontSize: "0.6rem", color: C.muted, display: "block", marginBottom: "0.25rem" }}>
                  QUANTITY ({selectedPair.base})
                </label>
                <input
                  type="number"
                  value={orderQuantity}
                  onChange={(e) => setOrderQuantity(e.target.value)}
                  placeholder="0.000"
                  style={{
                    width: "100%",
                    padding: "0.5rem",
                    fontSize: "0.85rem",
                    background: "rgba(255,255,255,0.03)",
                    border: `1px solid ${C.border}`,
                    borderRadius: "0.3rem",
                    color: C.text,
                    outline: "none",
                  }}
                />
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
              <span style={{ fontSize: "0.65rem", color: C.muted }}>
                TOTAL: {orderPrice && orderQuantity ? (Number.parseFloat(orderPrice) * Number.parseFloat(orderQuantity)).toFixed(4) : "0.0000"} {selectedPair.quote}
              </span>
              <span style={{ fontSize: "0.6rem", color: C.green }}>
                GAS FEE: 0.000
              </span>
            </div>

            <button
              type="button"
              onClick={handlePlaceOrder}
              disabled={loading || !orderPrice || !orderQuantity}
              style={{
                width: "100%",
                padding: "0.7rem",
                fontSize: "0.8rem",
                fontWeight: 700,
                background: orderSide === "buy" ? "rgba(80,180,80,0.2)" : "rgba(220,60,60,0.2)",
                color: orderSide === "buy" ? C.green : C.red,
                border: `1px solid ${orderSide === "buy" ? "rgba(80,180,80,0.4)" : "rgba(220,60,60,0.4)"}`,
                borderRadius: "0.3rem",
                cursor: loading ? "wait" : "pointer",
                opacity: !orderPrice || !orderQuantity ? 0.5 : 1,
              }}
            >
              {loading ? "SUBMITTING..." : `${orderSide.toUpperCase()} ${selectedPair.base} — ZERO GAS`}
            </button>
          </div>

          {/* Recent Fills */}
          <div
            style={{
              padding: "1rem",
              background: C.bgPanel,
              border: `1px solid ${C.border}`,
              borderRadius: "0.5rem",
            }}
          >
            <h3 style={{ fontSize: "0.75rem", color: C.gold, margin: "0 0 0.75rem 0" }}>
              RECENT FILLS — INSTANT SETTLEMENT
            </h3>
            {recentFills.length === 0 ? (
              <p style={{ fontSize: "0.7rem", color: C.muted }}>
                No fills yet. Place orders to start trading.
              </p>
            ) : (
              <div style={{ maxHeight: "200px", overflow: "auto" }}>
                {recentFills.map((fill) => (
                  <div
                    key={fill.fillId}
                    style={{
                      display: "grid",
                      gridTemplateColumns: "60px 1fr 1fr 1fr 60px",
                      gap: "0.5rem",
                      padding: "0.35rem 0",
                      borderBottom: `1px solid ${C.border}`,
                      fontSize: "0.65rem",
                    }}
                  >
                    <span style={{ color: C.muted }}>#{fill.fillId}</span>
                    <span style={{ color: C.cyan }}>{fill.pairId}</span>
                    <span style={{ color: C.gold }}>{fill.price.toFixed(6)}</span>
                    <span style={{ color: C.text }}>{fill.quantity.toFixed(4)}</span>
                    <span style={{ color: C.green }}>B{fill.beat}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* ─── RIGHT: Intelligence & Artifacts ─── */}
        <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
          {/* AI Intelligence Panel */}
          <div
            style={{
              padding: "1rem",
              background: C.bgPanel,
              border: `1px solid rgba(130,80,220,0.2)`,
              borderRadius: "0.5rem",
            }}
          >
            <h3 style={{ fontSize: "0.75rem", color: C.phantom, margin: "0 0 0.75rem 0" }}>
              ◈ PHANTOM INTELLIGENCE
            </h3>
            <div style={{ fontSize: "0.65rem", color: C.muted, marginBottom: "0.5rem" }}>
              AI reasoning layer — every trade is a cognitive act
            </div>
            {intelSignals.length > 0 ? (
              <div style={{ maxHeight: "150px", overflow: "auto" }}>
                {intelSignals.map((sig) => (
                  <div
                    key={sig.signalId}
                    style={{
                      padding: "0.3rem 0",
                      borderBottom: `1px solid ${C.border}`,
                      fontSize: "0.6rem",
                    }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between" }}>
                      <span style={{ color: C.cyan }}>{sig.tokenPair}</span>
                      <span style={{ color: sig.confidence >= 0.618 ? C.green : C.red }}>
                        C:{sig.confidence.toFixed(3)}
                      </span>
                    </div>
                    <div style={{ color: C.muted }}>
                      {sig.sourceLayer} | M:{sig.magnitude.toFixed(2)}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ fontSize: "0.6rem", color: C.dim }}>
                Awaiting market signals...
              </div>
            )}
          </div>

          {/* AI Artifacts Marketplace */}
          <div
            style={{
              padding: "1rem",
              background: C.bgPanel,
              border: `1px solid rgba(160,112,240,0.2)`,
              borderRadius: "0.5rem",
            }}
          >
            <h3 style={{ fontSize: "0.75rem", color: C.purple, margin: "0 0 0.75rem 0" }}>
              AI ARTIFACT MARKETPLACE
            </h3>
            <div style={{ fontSize: "0.65rem", color: C.muted, marginBottom: "0.5rem" }}>
              Tokenized AI models, embeddings, protocols — tradeable intelligence
            </div>
            {artifacts.length > 0 ? (
              <div style={{ maxHeight: "200px", overflow: "auto" }}>
                {artifacts.map((art: any, i: number) => (
                  <div
                    key={art.artifactId ?? i}
                    style={{
                      padding: "0.4rem",
                      marginBottom: "0.4rem",
                      background: "rgba(160,112,240,0.05)",
                      border: `1px solid rgba(160,112,240,0.15)`,
                      borderRadius: "0.3rem",
                      fontSize: "0.6rem",
                    }}
                  >
                    <div style={{ fontWeight: 600, color: C.purple }}>
                      {art.name ?? art.tokenSymbol}
                    </div>
                    <div style={{ color: C.muted, marginTop: "0.2rem" }}>
                      {art.tokenSymbol} | {Number(art.price ?? 0).toFixed(6)} MTC | Quality: {Number(art.qualityScore ?? 0).toFixed(2)}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ fontSize: "0.6rem", color: C.dim }}>
                Genesis artifacts loading...
              </div>
            )}
          </div>

          {/* Custom AI Tokens */}
          <div
            style={{
              padding: "1rem",
              background: C.bgPanel,
              border: `1px solid ${C.borderGold}`,
              borderRadius: "0.5rem",
            }}
          >
            <h3 style={{ fontSize: "0.75rem", color: C.amber, margin: "0 0 0.75rem 0" }}>
              AI & CUSTOM TOKENS
            </h3>
            <div style={{ fontSize: "0.65rem", color: C.muted, marginBottom: "0.5rem" }}>
              AI compute, memory, inference, training, data + creator tokens
            </div>
            {customTokens.length > 0 ? (
              <div style={{ maxHeight: "180px", overflow: "auto" }}>
                {customTokens.map((tok: any, i: number) => (
                  <div
                    key={tok.tokenId ?? i}
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      padding: "0.3rem 0",
                      borderBottom: `1px solid ${C.border}`,
                      fontSize: "0.6rem",
                    }}
                  >
                    <span style={{ color: C.amber, fontWeight: 600 }}>
                      {tok.symbol}
                    </span>
                    <span style={{ color: C.muted }}>
                      {Number(tok.circulatingSupply ?? 0).toLocaleString()}
                    </span>
                    <span style={{ color: C.green }}>
                      {Number(tok.currentPrice ?? 0).toFixed(6)}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ fontSize: "0.6rem", color: C.dim }}>
                AI tokens initializing...
              </div>
            )}
          </div>

          {/* Phantom Clearinghouse Status */}
          <div
            style={{
              padding: "1rem",
              background: C.bgPanel,
              border: `1px solid rgba(80,220,80,0.15)`,
              borderRadius: "0.5rem",
            }}
          >
            <h3 style={{ fontSize: "0.75rem", color: C.green, margin: "0 0 0.5rem 0" }}>
              CLEARINGHOUSE STATUS
            </h3>
            <div style={{ fontSize: "0.6rem", display: "grid", gap: "0.3rem" }}>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: C.muted }}>Settlement Latency</span>
                <span style={{ color: C.green }}>0.3ms</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: C.muted }}>Gas Fees Charged</span>
                <span style={{ color: C.green }}>ZERO — ALWAYS</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: C.muted }}>Gas Saved (vs ETH)</span>
                <span style={{ color: C.amber }}>${exchangeStats.gasSaved.toFixed(0)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: C.muted }}>Netting Reduction</span>
                <span style={{ color: C.cyan }}>61.8% (φ⁻¹)</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between" }}>
                <span style={{ color: C.muted }}>Coverage Ratio</span>
                <span style={{ color: C.gold }}>φ:1 (1.618:1)</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
