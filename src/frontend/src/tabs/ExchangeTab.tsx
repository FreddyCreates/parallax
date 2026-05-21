import { useInternetIdentity } from "@caffeineai/core-infrastructure";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "sonner";
import { useActor } from "../hooks/useActor";
import {
  type AuditTrade,
  type IntelligenceEngineResult,
  type SettlementEvent,
  useIntelligenceEngine,
} from "../hooks/useIntelligenceEngine";
import type {
  Candle,
  CandleTimeframe,
  DepthBook,
} from "../lib/intelligenceEngine";
import { bollingerBands, ema } from "../lib/intelligenceEngine";

// ── Color constants ────────────────────────────────────────────────
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
};

const CANVAS_GOLD = "#c8a03c";
const CANVAS_GOLD_DIM = "rgba(200,160,60,0.08)";
const CANVAS_PURPLE = "#a070f0";
const CANVAS_GREEN = "#4aaa6a";
const CANVAS_RED = "#cc4444";
const CANVAS_BG = "#050508";
const CANVAS_GRID = "rgba(255,255,255,0.04)";
const CANVAS_MUTED = "rgba(140,140,160,0.5)";
const CANVAS_TEXT = "rgba(200,200,220,0.7)";

// ── Token definitions ───────────────────────────────────────────────────
const ALL_TOKENS = [
  { code: "GTK", tier: "gold" },
  { code: "MTH", tier: "gold" },
  { code: "MRC", tier: "gold" },
  { code: "CVT", tier: "silver" },
  { code: "VCT", tier: "silver" },
  { code: "KNT", tier: "silver" },
  { code: "RST", tier: "silver" },
  { code: "LGT", tier: "silver" },
  { code: "SBT", tier: "base" },
  { code: "HBT", tier: "base" },
  { code: "DRT", tier: "base" },
  { code: "OMT", tier: "base" },
  { code: "MTC", tier: "gold" },
] as const;

type TokenCode = (typeof ALL_TOKENS)[number]["code"];

function tierColor(tier: string): string {
  if (tier === "gold") return C.gold;
  if (tier === "silver") return C.silver;
  return C.dim;
}

function tokenTier(code: string): string {
  return ALL_TOKENS.find((t) => t.code === code)?.tier ?? "base";
}

// ── Utility sub-components ───────────────────────────────────────────────
function Lbl({ children }: { children: React.ReactNode }) {
  return (
    <span
      className="font-mono text-[8px] tracking-[0.3em] uppercase"
      style={{ color: C.muted }}
    >
      {children}
    </span>
  );
}

function Val({
  children,
  color = C.text,
  size = "text-xs",
}: { children: React.ReactNode; color?: string; size?: string }) {
  return (
    <span className={`font-mono ${size}`} style={{ color }}>
      {children}
    </span>
  );
}

function PanelBox({
  children,
  className = "",
  style = {},
}: {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
}) {
  return (
    <div
      className={`border ${className}`}
      style={{ borderColor: C.border, background: C.bgPanel, ...style }}
    >
      {children}
    </div>
  );
}

function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <div
      className="font-mono text-[8px] tracking-[0.5em] mb-3 pb-2 border-b flex items-center gap-2"
      style={{ color: C.muted, borderColor: C.border }}
    >
      {children}
    </div>
  );
}

function Dot({ color }: { color: string }) {
  return (
    <span
      className="inline-block w-1.5 h-1.5 rounded-full animate-pulse"
      style={{ backgroundColor: color, boxShadow: `0 0 6px ${color}` }}
    />
  );
}

function LockOverlay() {
  return (
    <div
      className="absolute inset-0 flex flex-col items-center justify-center gap-2 z-10"
      style={{ background: "rgba(0,0,0,0.75)", backdropFilter: "blur(4px)" }}
    >
      <span
        className="font-mono text-[10px] tracking-[0.3em]"
        style={{ color: C.amber }}
      >
        ⚠ AUTH REQUIRED
      </span>
      <span className="font-mono text-[8px]" style={{ color: C.muted }}>
        Authenticate to access operator controls
      </span>
    </div>
  );
}

function fmt(n: number, dec = 6): string {
  return n.toLocaleString("en-US", {
    minimumFractionDigits: dec,
    maximumFractionDigits: dec,
  });
}

function fmtShort(n: number, dec = 2): string {
  return n.toLocaleString("en-US", {
    minimumFractionDigits: dec,
    maximumFractionDigits: dec,
  });
}

function fmtCompact(n: number): string {
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(2)}M`;
  if (n >= 1_000) return `${(n / 1_000).toFixed(2)}K`;
  return fmtShort(n, 4);
}

// Token badge colored by tier
function TokenBadge({ code }: { code: string }) {
  const color = tierColor(tokenTier(code));
  return (
    <span
      className="font-mono text-[8px] tracking-widest px-1.5 py-0.5"
      style={{
        color,
        border: `1px solid ${color}33`,
        background: `${color}10`,
      }}
    >
      {code}
    </span>
  );
}

// ── A. Exchange Top Bar ───────────────────────────────────────────────────────
function ExchangeTopBar({
  eng,
  pair,
  onPairChange,
}: {
  eng: IntelligenceEngineResult;
  pair: TokenCode;
  onPairChange: (p: TokenCode) => void;
}) {
  const { mtcState, feeds, regime, stats24h, settlementStats } = eng;
  const price = mtcState?.price ?? 0;
  const prevPriceRef = useRef(price);
  const [priceDir, setPriceDir] = useState<"up" | "down" | "same">("same");

  useEffect(() => {
    if (price > 0 && prevPriceRef.current > 0) {
      setPriceDir(
        price > prevPriceRef.current
          ? "up"
          : price < prevPriceRef.current
            ? "down"
            : "same",
      );
    }
    prevPriceRef.current = price;
  }, [price]);

  const priceColor =
    priceDir === "up" ? C.gold : priceDir === "down" ? C.red : C.text;
  const regimeColor =
    regime === "BULL" ? C.green : regime === "BEAR" ? C.red : C.amber;
  const live = feeds?.liveDataActive ?? false;
  const settlements = Number(settlementStats?.totalSettlements ?? 0n);

  return (
    <div
      className="flex items-center gap-3 px-4 py-2.5 border-b flex-wrap"
      style={{
        borderColor: C.border,
        background: "rgba(2,2,6,0.98)",
        minHeight: 52,
      }}
    >
      {/* Pair Selector */}
      <div
        className="flex items-center gap-0.5 overflow-x-auto"
        style={{ maxWidth: 340 }}
      >
        {ALL_TOKENS.slice(0, 6).map((t) => (
          <button
            key={t.code}
            type="button"
            onClick={() => onPairChange(t.code)}
            data-ocid="exchange.pair.tab"
            className="font-mono text-[9px] tracking-widest px-2 py-1 border transition-all shrink-0"
            style={{
              borderColor:
                pair === t.code ? `${tierColor(t.tier)}44` : C.border,
              background:
                pair === t.code ? `${tierColor(t.tier)}12` : "transparent",
              color: pair === t.code ? tierColor(t.tier) : C.muted,
            }}
          >
            {t.code}
          </button>
        ))}
        <select
          value={ALL_TOKENS.slice(6).find((t) => t.code === pair) ? pair : ""}
          onChange={(e) =>
            e.target.value && onPairChange(e.target.value as TokenCode)
          }
          data-ocid="exchange.pair.select"
          className="font-mono text-[9px] bg-transparent border px-1.5 py-1 outline-none cursor-pointer"
          style={{ borderColor: C.border, color: C.muted }}
        >
          <option value="">MORE▾</option>
          {ALL_TOKENS.slice(6).map((t) => (
            <option
              key={t.code}
              value={t.code}
              style={{ background: "#050508" }}
            >
              {t.code}
            </option>
          ))}
        </select>
      </div>

      <div className="w-px h-5" style={{ background: C.border }} />

      {/* Last Price */}
      <div className="flex flex-col">
        <span
          className="font-mono text-lg font-bold leading-tight transition-colors duration-300"
          style={{ color: priceColor, textShadow: `0 0 16px ${priceColor}55` }}
        >
          {price > 0 ? fmt(price, 8) : "—"}
        </span>
        <span className="font-mono text-[8px]" style={{ color: C.muted }}>
          ICP
        </span>
      </div>

      <div className="w-px h-5" style={{ background: C.border }} />

      {/* 24h stats */}
      <div className="flex items-center gap-3">
        <div className="flex flex-col items-center">
          <Lbl>24H</Lbl>
          <span
            className="font-mono text-xs font-bold"
            style={{ color: (stats24h?.changePct ?? 0) >= 0 ? C.green : C.red }}
          >
            {(stats24h?.changePct ?? 0) >= 0 ? "+" : ""}
            {fmtShort(stats24h?.changePct ?? 0, 2)}%
          </span>
        </div>
        <div className="flex flex-col items-center">
          <Lbl>HIGH</Lbl>
          <Val color={C.gold} size="text-[10px]">
            {stats24h?.high > 0 ? fmt(stats24h.high, 6) : "—"}
          </Val>
        </div>
        <div className="flex flex-col items-center">
          <Lbl>LOW</Lbl>
          <Val color={C.red} size="text-[10px]">
            {stats24h?.low > 0 ? fmt(stats24h.low, 6) : "—"}
          </Val>
        </div>
      </div>

      {/* Settlement count */}
      {settlements > 0 && (
        <div
          className="font-mono text-[8px] px-2 py-0.5 border"
          style={{
            color: C.cyan,
            borderColor: `${C.cyan}33`,
            background: `${C.cyan}08`,
          }}
        >
          {settlements.toLocaleString()} CLEARED
        </div>
      )}

      {/* Regime */}
      <div className="flex items-center gap-1.5">
        <span
          className="font-mono text-[9px] tracking-[0.25em] px-2 py-0.5 border"
          style={{
            color: regimeColor,
            borderColor: `${regimeColor}44`,
            background: `${regimeColor}10`,
          }}
        >
          {regime}
        </span>
      </div>

      {/* Live dot */}
      <div className="flex items-center gap-1.5 ml-auto">
        <Dot color={live ? C.green : C.amber} />
        <span
          className="font-mono text-[8px]"
          style={{ color: live ? C.green : C.amber }}
        >
          {live ? "LIVE" : "SYNCING"}
        </span>
      </div>
    </div>
  );
}

// ── B. Settlement Feed ─────────────────────────────────────────────────────────
function SettlementFeed({
  feed,
  stats,
}: {
  feed: SettlementEvent[];
  stats: IntelligenceEngineResult["settlementStats"];
}) {
  const prevFeedRef = useRef<string>("");
  const [flashSet, setFlashSet] = useState<Set<number>>(new Set());

  useEffect(() => {
    const key = feed.map((e) => `${Number(e.beat)}-${e.tokenCode}`).join(",");
    if (key !== prevFeedRef.current && feed.length > 0) {
      // Flash the newest entries
      const newFlash = new Set<number>();
      for (let i = 0; i < Math.min(3, feed.length); i++) newFlash.add(i);
      setFlashSet(newFlash);
      setTimeout(() => setFlashSet(new Set()), 800);
      prevFeedRef.current = key;
    }
  }, [feed]);

  const typeColor = (t: string) => {
    if (t === "MINT") return C.gold;
    if (t === "SWAP") return C.cyan;
    if (t === "TRANSFER") return C.purple;
    if (t === "PROFIT") return C.green;
    return C.muted;
  };

  const totalForma = stats?.totalFormaCleared ?? 0;

  return (
    <PanelBox className="flex flex-col h-full" style={{ minWidth: 0 }}>
      <div
        className="px-3 py-2 border-b flex items-center justify-between shrink-0"
        style={{ borderColor: C.border }}
      >
        <span
          className="font-mono text-[8px] tracking-[0.4em]"
          style={{ color: C.muted }}
        >
          SETTLEMENT FEED
        </span>
        <Dot color={C.green} />
      </div>

      <div
        className="flex-1 overflow-y-auto"
        style={{ maxHeight: "100%" }}
        data-ocid="exchange.settlement.panel"
      >
        {feed.length === 0 ? (
          <div
            className="flex items-center justify-center h-full font-mono text-[9px]"
            style={{ color: C.dim }}
            data-ocid="exchange.settlement.empty_state"
          >
            NO SETTLEMENTS YET
          </div>
        ) : (
          feed.map((evt, i) => (
            <motion.div
              key={`settle-${Number(evt.beat)}-${i}`}
              initial={{ opacity: 0, x: -4 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.2 }}
              data-ocid={`exchange.settlement.item.${i + 1}`}
              className="flex items-center gap-2 px-2.5 py-1.5 border-b transition-all"
              style={{
                borderColor: C.border,
                background: flashSet.has(i)
                  ? `${typeColor(evt.sType)}08`
                  : "transparent",
                boxShadow: flashSet.has(i)
                  ? `inset 2px 0 0 ${typeColor(evt.sType)}`
                  : undefined,
              }}
            >
              <TokenBadge code={evt.tokenCode} />
              <span
                className="font-mono text-[9px] flex-1 tabular-nums"
                style={{ color: C.text }}
              >
                {fmtCompact(Number(evt.amount))}
              </span>
              <span
                className="font-mono text-[7px] tracking-widest px-1 py-0.5"
                style={{
                  color: typeColor(evt.sType),
                  border: `1px solid ${typeColor(evt.sType)}33`,
                }}
              >
                {evt.sType}
              </span>
              <span className="font-mono text-[8px]" style={{ color: C.gold }}>
                ƒ{fmtCompact(evt.formaValue)}
              </span>
              <span className="font-mono text-[7px]" style={{ color: C.dim }}>
                #{Number(evt.beat)}
              </span>
            </motion.div>
          ))
        )}
      </div>

      {/* Total cleared */}
      <div
        className="px-3 py-2 border-t flex items-center justify-between shrink-0"
        style={{ borderColor: `${C.gold}22`, background: `${C.gold}04` }}
      >
        <Lbl>TOTAL CLEARED</Lbl>
        <Val color={C.gold} size="text-[10px]">
          ƒ{totalForma > 0 ? fmtCompact(totalForma) : "—"}
        </Val>
      </div>
    </PanelBox>
  );
}

// ── C. Candlestick Chart ─────────────────────────────────────────────────────────
function CandlestickChart({
  candles,
  timeframe,
  onTimeframeChange,
  selectedPair,
}: {
  candles: Candle[];
  timeframe: CandleTimeframe;
  onTimeframeChange: (tf: CandleTimeframe) => void;
  selectedPair: string;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const rafRef = useRef<number>(0);
  const mouseRef = useRef<{ x: number; y: number } | null>(null);
  const [tooltip, setTooltip] = useState<{
    x: number;
    y: number;
    candle: Candle;
  } | null>(null);

  const TIMEFRAMES: CandleTimeframe[] = ["1B", "10B", "1H", "4H"];
  const VOLUME_HEIGHT_PCT = 0.18;
  const PADDING = { top: 12, right: 64, bottom: 36, left: 8 };

  const drawChart = useCallback(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = container.clientWidth;
    const W = canvas.width;
    canvas.height = container.clientHeight;
    const H = canvas.height;
    if (W === 0 || H === 0) return;

    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = CANVAS_BG;
    ctx.fillRect(0, 0, W, H);

    const chartH = H - PADDING.top - PADDING.bottom;
    const chartW = W - PADDING.left - PADDING.right;
    const mainH = chartH * (1 - VOLUME_HEIGHT_PCT);
    const volH = chartH * VOLUME_HEIGHT_PCT;
    const volY = PADDING.top + mainH + 4;

    if (candles.length < 2) {
      ctx.font = "11px 'Courier New', monospace";
      ctx.fillStyle = CANVAS_MUTED;
      ctx.textAlign = "center";
      ctx.fillText("BUILDING CHART DATA...", W / 2, H / 2);
      return;
    }

    const visible = candles.slice(-60);
    const prices = visible.flatMap((c) => [c.high, c.low]);
    const priceMin = Math.min(...prices) * 0.9999;
    const priceMax = Math.max(...prices) * 1.0001;
    const priceRange = priceMax - priceMin || 1;

    const volumes = visible.map((c) => c.volume);
    const volMax = Math.max(...volumes, 0.001);

    const candleW = Math.max(2, Math.floor((chartW / visible.length) * 0.7));
    const gap = Math.floor((chartW / visible.length) * 0.3);

    const toY = (price: number) =>
      PADDING.top + mainH - ((price - priceMin) / priceRange) * mainH;
    const toX = (i: number) => PADDING.left + i * (candleW + gap) + candleW / 2;

    // Grid lines
    ctx.strokeStyle = CANVAS_GRID;
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
      const y = PADDING.top + (mainH / 4) * i;
      ctx.beginPath();
      ctx.moveTo(PADDING.left, y);
      ctx.lineTo(W - PADDING.right, y);
      ctx.stroke();
      const price = priceMax - (priceRange / 4) * i;
      ctx.font = "8px 'Courier New', monospace";
      ctx.fillStyle = CANVAS_TEXT;
      ctx.textAlign = "left";
      ctx.fillText(fmt(price, 6), W - PADDING.right + 4, y + 3);
    }

    // Bollinger bands
    const closes = visible.map((c) => c.close);
    if (closes.length >= 4) {
      const boll = bollingerBands(closes, Math.min(20, closes.length));
      ctx.beginPath();
      for (let i = 0; i < visible.length; i++) {
        const x = toX(i);
        const y = toY(boll.upper[i] ?? priceMax);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      for (let i = visible.length - 1; i >= 0; i--) {
        const x = toX(i);
        const y = toY(boll.lower[i] ?? priceMin);
        ctx.lineTo(x, y);
      }
      ctx.closePath();
      ctx.fillStyle = CANVAS_GOLD_DIM;
      ctx.fill();

      ctx.beginPath();
      for (let i = 0; i < visible.length; i++) {
        const x = toX(i);
        const yu = toY(boll.upper[i] ?? priceMax);
        if (i === 0) ctx.moveTo(x, yu);
        else ctx.lineTo(x, yu);
      }
      ctx.strokeStyle = "rgba(200,160,60,0.18)";
      ctx.lineWidth = 0.8;
      ctx.stroke();

      ctx.beginPath();
      for (let i = 0; i < visible.length; i++) {
        const x = toX(i);
        const yl = toY(boll.lower[i] ?? priceMin);
        if (i === 0) ctx.moveTo(x, yl);
        else ctx.lineTo(x, yl);
      }
      ctx.strokeStyle = "rgba(200,160,60,0.18)";
      ctx.lineWidth = 0.8;
      ctx.stroke();
    }

    // EMA-21 (gold)
    if (closes.length >= 4) {
      const e21 = ema(closes, 21);
      ctx.beginPath();
      for (let i = 0; i < visible.length; i++) {
        const x = toX(i);
        const y = toY(e21[i] ?? 0);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = CANVAS_GOLD;
      ctx.lineWidth = 1.5;
      ctx.stroke();
    }

    // EMA-200 (purple, dashed)
    if (closes.length >= 8) {
      const e200 = ema(closes, 200);
      ctx.beginPath();
      ctx.setLineDash([4, 4]);
      for (let i = 0; i < visible.length; i++) {
        const x = toX(i);
        const y = toY(e200[i] ?? 0);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = CANVAS_PURPLE;
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Candles
    for (let i = 0; i < visible.length; i++) {
      const c = visible[i];
      if (!c) continue;
      const x = toX(i);
      const openY = toY(c.open);
      const closeY = toY(c.close);
      const highY = toY(c.high);
      const lowY = toY(c.low);
      const isUp = c.direction !== "down";
      const color = isUp ? CANVAS_GREEN : CANVAS_RED;

      ctx.beginPath();
      ctx.moveTo(x, highY);
      ctx.lineTo(x, lowY);
      ctx.strokeStyle = color;
      ctx.lineWidth = 1;
      ctx.stroke();

      const bodyTop = Math.min(openY, closeY);
      const bodyH = Math.max(1, Math.abs(closeY - openY));
      ctx.fillStyle = isUp ? `${CANVAS_GREEN}cc` : `${CANVAS_RED}cc`;
      ctx.fillRect(x - candleW / 2, bodyTop, candleW, bodyH);
    }

    // Volume histogram
    for (let i = 0; i < visible.length; i++) {
      const c = visible[i];
      if (!c) continue;
      const x = toX(i);
      const vPct = c.volume / volMax;
      const vBarH = Math.max(1, vPct * volH);
      const vBarY = volY + volH - vBarH;
      ctx.fillStyle =
        c.direction !== "down" ? "rgba(74,170,106,0.4)" : "rgba(204,68,68,0.4)";
      ctx.fillRect(x - candleW / 2, vBarY, candleW, vBarH);
    }

    // X-axis beat labels
    ctx.font = "8px 'Courier New', monospace";
    ctx.fillStyle = CANVAS_MUTED;
    ctx.textAlign = "center";
    for (let i = 0; i < visible.length; i += Math.ceil(visible.length / 8)) {
      const c = visible[i];
      if (!c) continue;
      const x = toX(i);
      ctx.fillText(String(c.beatStart), x, H - PADDING.bottom + 14);
    }

    // Crosshair
    const mouse = mouseRef.current;
    if (mouse) {
      ctx.strokeStyle = "rgba(255,255,255,0.15)";
      ctx.lineWidth = 0.5;
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(mouse.x, PADDING.top);
      ctx.lineTo(mouse.x, PADDING.top + mainH);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(PADDING.left, mouse.y);
      ctx.lineTo(W - PADDING.right, mouse.y);
      ctx.stroke();
      ctx.setLineDash([]);

      const mousePrice =
        priceMax - ((mouse.y - PADDING.top) / mainH) * priceRange;
      ctx.font = "8px 'Courier New', monospace";
      ctx.fillStyle = CANVAS_GOLD;
      ctx.textAlign = "left";
      ctx.fillText(fmt(mousePrice, 6), W - PADDING.right + 4, mouse.y + 3);
    }
  }, [candles]);

  useEffect(() => {
    const draw = () => {
      drawChart();
      rafRef.current = requestAnimationFrame(draw);
    };
    rafRef.current = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(rafRef.current);
  }, [drawChart]);

  const handleMouseMove = useCallback(
    (e: React.MouseEvent<HTMLCanvasElement>) => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      mouseRef.current = { x, y };
      if (candles.length < 2) return;
      const visible = candles.slice(-60);
      const chartW = canvas.width - 8 - 64;
      const candleW = Math.max(2, Math.floor((chartW / visible.length) * 0.7));
      const gap = Math.floor((chartW / visible.length) * 0.3);
      const slot = candleW + gap;
      const idx = Math.round((x - 8 - candleW / 2) / slot);
      const c = visible[Math.max(0, Math.min(visible.length - 1, idx))];
      if (c) setTooltip({ x, y, candle: c });
    },
    [candles],
  );

  const handleMouseLeave = useCallback(() => {
    mouseRef.current = null;
    setTooltip(null);
  }, []);

  return (
    <div className="flex flex-col h-full" style={{ background: CANVAS_BG }}>
      <div
        className="flex items-center justify-between px-3 py-1.5 border-b"
        style={{ borderColor: C.border }}
      >
        <div className="flex gap-1">
          {TIMEFRAMES.map((tf) => (
            <button
              key={tf}
              type="button"
              onClick={() => onTimeframeChange(tf)}
              data-ocid="exchange.chart.tab"
              className="font-mono text-[8px] tracking-widest px-2 py-0.5 border transition-all"
              style={{
                borderColor: timeframe === tf ? C.goldDim : C.border,
                background: timeframe === tf ? C.goldDim : "transparent",
                color: timeframe === tf ? C.gold : C.muted,
              }}
            >
              {tf}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          <span className="font-mono text-[8px]" style={{ color: C.muted }}>
            {selectedPair} / FORMA
          </span>
          <div className="flex items-center gap-1.5">
            <div className="w-3 h-0.5" style={{ background: CANVAS_GOLD }} />
            <span className="font-mono text-[7px]" style={{ color: C.muted }}>
              EMA-21
            </span>
          </div>
          <div className="flex items-center gap-1.5">
            <div className="w-3 h-0.5" style={{ background: CANVAS_PURPLE }} />
            <span className="font-mono text-[7px]" style={{ color: C.muted }}>
              EMA-200
            </span>
          </div>
        </div>
      </div>

      <div ref={containerRef} className="relative flex-1">
        <canvas
          ref={canvasRef}
          className="absolute inset-0 w-full h-full"
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseLeave}
          style={{ cursor: "crosshair" }}
        />
        <AnimatePresence>
          {tooltip?.candle && (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              className="absolute pointer-events-none border z-20 text-[9px] font-mono px-2.5 py-2"
              style={{
                left: tooltip!.x + 12,
                top: Math.max(4, tooltip!.y - 80),
                background: "rgba(2,2,6,0.96)",
                borderColor: C.borderGold,
                minWidth: 150,
              }}
            >
              <div className="space-y-0.5">
                {[
                  ["BEAT", String(tooltip.candle.beatStart), C.text],
                  ["OPEN", fmt(tooltip.candle.open, 6), C.text],
                  ["HIGH", fmt(tooltip.candle.high, 6), C.green],
                  ["LOW", fmt(tooltip.candle.low, 6), C.red],
                  [
                    "CLOSE",
                    fmt(tooltip.candle.close, 6),
                    tooltip.candle.direction !== "down" ? C.green : C.red,
                  ],
                  ["VOL", fmtShort(tooltip.candle.volume, 4), C.cyan],
                ].map(([label, val, color]) => (
                  <div key={label} className="flex justify-between gap-4">
                    <span style={{ color: C.muted }}>{label}</span>
                    <span style={{ color: color as string }}>{val}</span>
                  </div>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}

// ── D. Clearing Operations (right column — 3 stacked panels) ──────────────────
function TokenSwapPanel({
  eng,
  isAuthenticated,
  actor,
}: {
  eng: IntelligenceEngineResult;
  isAuthenticated: boolean;
  actor: any;
}) {
  const { tokenExchangeRates } = eng;
  const [fromToken, setFromToken] = useState<TokenCode>("MTC");
  const [toToken, setToToken] = useState<TokenCode>("GTK");
  const [amount, setAmount] = useState("");
  const [pending, setPending] = useState(false);
  const [lastResult, setLastResult] = useState<{
    received: string;
    rate: number;
  } | null>(null);

  const rates = tokenExchangeRates;
  const fromIdx = rates?.codes.indexOf(fromToken) ?? -1;
  const toIdx = rates?.codes.indexOf(toToken) ?? -1;
  const fromRate = fromIdx >= 0 ? (rates?.rates[fromIdx] ?? 0) : 0;
  const toRate = toIdx >= 0 ? (rates?.rates[toIdx] ?? 0) : 0;
  const effectiveRate = toRate > 0 && fromRate > 0 ? fromRate / toRate : 0;
  const numAmount = Number.parseFloat(amount) || 0;
  const formaPreview = numAmount * fromRate;
  const toAmount = effectiveRate > 0 ? numAmount * effectiveRate : 0;

  const handleSwap = async () => {
    if (!actor || numAmount <= 0) return;
    setPending(true);
    try {
      const result = await actor.swapTokens(
        fromToken,
        toToken,
        BigInt(Math.floor(numAmount)),
      );
      if (result?.success) {
        toast.success(
          `SWAP: ${numAmount} ${fromToken} → ${Number(result.received)} ${toToken}`,
        );
        setLastResult({
          received: String(Number(result.received)),
          rate: result.rate,
        });
        setAmount("");
      } else {
        toast.error("Swap failed — check gate conditions");
      }
    } catch {
      toast.error("Swap execution error");
    } finally {
      setPending(false);
    }
  };

  return (
    <PanelBox className="p-3">
      <SectionTitle>⇄ TOKEN SWAP ENGINE</SectionTitle>
      <div className="space-y-2">
        <div className="grid grid-cols-2 gap-2">
          <div>
            <Lbl>FROM</Lbl>
            <select
              value={fromToken}
              onChange={(e) => setFromToken(e.target.value as TokenCode)}
              data-ocid="exchange.swap.from_select"
              className="w-full mt-0.5 bg-transparent border px-2 py-1 font-mono text-[10px] outline-none"
              style={{ borderColor: C.border, color: C.gold }}
            >
              {ALL_TOKENS.map((t) => (
                <option
                  key={t.code}
                  value={t.code}
                  style={{ background: "#050508" }}
                >
                  {t.code}
                </option>
              ))}
            </select>
          </div>
          <div>
            <Lbl>TO</Lbl>
            <select
              value={toToken}
              onChange={(e) => setToToken(e.target.value as TokenCode)}
              data-ocid="exchange.swap.to_select"
              className="w-full mt-0.5 bg-transparent border px-2 py-1 font-mono text-[10px] outline-none"
              style={{ borderColor: C.border, color: C.cyan }}
            >
              {ALL_TOKENS.filter((t) => t.code !== fromToken).map((t) => (
                <option
                  key={t.code}
                  value={t.code}
                  style={{ background: "#050508" }}
                >
                  {t.code}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div>
          <Lbl>AMOUNT ({fromToken})</Lbl>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0"
            className="w-full mt-0.5 bg-transparent border px-2 py-1.5 font-mono text-xs outline-none"
            style={{ borderColor: `${C.gold}44`, color: C.text }}
            data-ocid="exchange.swap.amount_input"
          />
        </div>

        {numAmount > 0 && (
          <div
            className="space-y-0.5 p-2 border"
            style={{ borderColor: C.border }}
          >
            <div className="flex justify-between">
              <Lbl>RATE</Lbl>
              <Val size="text-[9px]" color={C.silver}>
                {effectiveRate > 0 ? effectiveRate.toFixed(6) : "—"}
              </Val>
            </div>
            <div className="flex justify-between">
              <Lbl>RECEIVE ({toToken})</Lbl>
              <Val size="text-[9px]" color={C.cyan}>
                {toAmount > 0 ? fmtCompact(toAmount) : "—"}
              </Val>
            </div>
            <div className="flex justify-between">
              <Lbl>ƒ VALUE</Lbl>
              <Val size="text-[9px]" color={C.gold}>
                ƒ{fmtCompact(formaPreview)}
              </Val>
            </div>
          </div>
        )}

        <div className="relative">
          {!isAuthenticated && <LockOverlay />}
          <button
            type="button"
            onClick={handleSwap}
            disabled={!isAuthenticated || pending || numAmount <= 0}
            data-ocid="exchange.swap.submit_button"
            className="w-full py-2 font-mono text-[9px] tracking-[0.3em] border transition-all disabled:opacity-40"
            style={{
              borderColor: `${C.cyan}55`,
              color: C.cyan,
              background: `${C.cyan}08`,
            }}
          >
            {pending ? "PROCESSING..." : "EXECUTE SWAP"}
          </button>
        </div>

        {lastResult && (
          <div
            className="font-mono text-[8px] p-1.5 border"
            style={{
              borderColor: `${C.green}33`,
              color: C.green,
              background: `${C.green}06`,
            }}
            data-ocid="exchange.swap.success_state"
          >
            FILLED: {lastResult.received} {toToken} @{" "}
            {lastResult.rate.toFixed(6)}
          </div>
        )}
      </div>
    </PanelBox>
  );
}

function ReserveStatusPanel({ eng }: { eng: IntelligenceEngineResult }) {
  const { clearingReserves, clearingHealth } = eng;
  const res = clearingReserves;

  const topTokens = useMemo(() => {
    if (!res) return [];
    return [
      { code: "MTC", val: res.mtc },
      { code: "GTK", val: res.gtk },
      { code: "MTH", val: res.mth },
      { code: "MRC", val: res.mrc },
      { code: "CVT", val: res.cvt },
      { code: "RST", val: res.rst },
    ]
      .sort((a, b) => b.val - a.val)
      .slice(0, 6);
  }, [res]);

  const maxVal =
    topTokens.length > 0 ? Math.max(...topTokens.map((t) => t.val), 1) : 1;
  const healthColor =
    clearingHealth > 0.7 ? C.green : clearingHealth > 0.4 ? C.amber : C.red;

  return (
    <PanelBox className="p-3">
      <SectionTitle>■ RESERVE STATUS</SectionTitle>
      <div className="space-y-1.5">
        <div className="flex items-center justify-between mb-2">
          <Lbl>CLEARING HEALTH</Lbl>
          <div className="flex items-center gap-2">
            <div
              className="w-16 h-1"
              style={{ background: "rgba(255,255,255,0.06)" }}
            >
              <div
                style={{
                  width: `${clearingHealth * 100}%`,
                  height: "100%",
                  background: healthColor,
                }}
              />
            </div>
            <Val size="text-[10px]" color={healthColor}>
              {(clearingHealth * 100).toFixed(0)}%
            </Val>
          </div>
        </div>

        {topTokens.map((t) => (
          <div key={t.code} className="flex items-center gap-2">
            <TokenBadge code={t.code} />
            <div
              className="flex-1 h-1"
              style={{ background: "rgba(255,255,255,0.04)" }}
            >
              <div
                style={{
                  width: `${(t.val / maxVal) * 100}%`,
                  height: "100%",
                  background: tierColor(tokenTier(t.code)),
                }}
              />
            </div>
            <Val size="text-[9px]" color={C.muted}>
              {fmtCompact(t.val)}
            </Val>
          </div>
        ))}

        <div
          className="flex justify-between pt-1 border-t"
          style={{ borderColor: C.border }}
        >
          <Lbl>TOTAL RESERVE</Lbl>
          <Val color={C.gold} size="text-[10px]">
            {res ? fmtCompact(res.total) : "—"}
          </Val>
        </div>
        <div className="flex justify-between">
          <Lbl>PROFIT ROUTED</Lbl>
          <Val color={C.green} size="text-[10px]">
            {res ? fmtCompact(res.profitRouted) : "—"}
          </Val>
        </div>
      </div>
    </PanelBox>
  );
}

function OrderEntryPanel({
  eng,
  pair,
  isAuthenticated,
  actor,
}: {
  eng: IntelligenceEngineResult;
  pair: TokenCode;
  isAuthenticated: boolean;
  actor: any;
}) {
  const { mtcState, fullState, auditTrades } = eng;
  const [side, setSide] = useState<"BUY" | "SELL">("BUY");
  const [orderType, setOrderType] = useState<"LIMIT" | "MARKET">("LIMIT");
  const [price, setPrice] = useState("");
  const [amount, setAmount] = useState("");
  const [pending, setPending] = useState(false);

  const midPrice = mtcState?.price ?? 0;
  const circulating = mtcState?.circulating ?? 0;
  const maxAmount = circulating > 0 ? circulating / 1000 : 100;

  useEffect(() => {
    if (orderType === "LIMIT" && midPrice > 0 && !price) {
      setPrice(fmt(midPrice, 8));
    }
  }, [midPrice, orderType, price]);

  const numPrice = Number.parseFloat(price) || 0;
  const numAmount = Number.parseFloat(amount) || 0;
  const total = numPrice * numAmount;

  const genesis = fullState?.genesisActivated ?? false;
  const coherence = fullState?.coherence ?? 0;
  const gatesPass = genesis && coherence >= 1.0;

  const handleExecute = async () => {
    if (!actor || !numAmount) return;
    setPending(true);
    try {
      if (side === "BUY") {
        const result = await actor.mintMtc(numAmount);
        if (result) toast.success(`BUY FILLED: ${fmtShort(numAmount, 4)} MTC`);
        else toast.error("Order failed");
      } else {
        const result = await actor.burnMtc(numAmount);
        if (result) toast.success(`SELL FILLED: ${fmtShort(numAmount, 4)} MTC`);
        else toast.error("Order failed");
      }
      setAmount("");
    } catch {
      toast.error("Order execution error");
    } finally {
      setPending(false);
    }
  };

  return (
    <PanelBox className="flex flex-col">
      {/* BUY / SELL toggle */}
      <div className="flex">
        <button
          type="button"
          onClick={() => setSide("BUY")}
          data-ocid="exchange.order.buy_button"
          className="flex-1 py-2.5 font-mono text-[10px] tracking-[0.3em] font-bold transition-all"
          style={{
            background: side === "BUY" ? C.goldDim : "transparent",
            borderBottom: `2px solid ${side === "BUY" ? C.gold : C.border}`,
            color: side === "BUY" ? C.gold : C.muted,
          }}
        >
          BUY
        </button>
        <button
          type="button"
          onClick={() => setSide("SELL")}
          data-ocid="exchange.order.sell_button"
          className="flex-1 py-2.5 font-mono text-[10px] tracking-[0.3em] font-bold transition-all"
          style={{
            background:
              side === "SELL" ? "rgba(180,60,60,0.15)" : "transparent",
            borderBottom: `2px solid ${side === "SELL" ? C.red : C.border}`,
            color: side === "SELL" ? C.red : C.muted,
          }}
        >
          SELL
        </button>
      </div>

      <div className="p-3 space-y-2.5">
        <div className="flex gap-1">
          {(["LIMIT", "MARKET"] as const).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setOrderType(t)}
              data-ocid="exchange.order.type_toggle"
              className="flex-1 py-1 font-mono text-[8px] tracking-widest border transition-all"
              style={{
                borderColor: orderType === t ? `${C.gold}66` : C.border,
                color: orderType === t ? C.gold : C.muted,
                background: orderType === t ? C.goldDim : "transparent",
              }}
            >
              {t}
            </button>
          ))}
        </div>

        <div className="flex justify-between">
          <Lbl>PAIR</Lbl>
          <Val color={C.gold} size="text-[10px]">
            {pair}/ICP
          </Val>
        </div>

        <div>
          <Lbl>PRICE (ICP)</Lbl>
          {orderType === "MARKET" ? (
            <div
              className="font-mono text-[10px] mt-0.5 px-2 py-1 border"
              style={{ borderColor: C.border, color: C.muted }}
            >
              MARKET PRICE
            </div>
          ) : (
            <input
              type="number"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="0.00000000"
              className="w-full bg-transparent border px-2 py-1.5 font-mono text-xs outline-none mt-0.5"
              style={{
                borderColor: `${side === "BUY" ? C.gold : C.red}44`,
                color: C.text,
              }}
              data-ocid="exchange.order.price_input"
            />
          )}
        </div>

        <div>
          <Lbl>AMOUNT</Lbl>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.0000"
            className="w-full bg-transparent border px-2 py-1.5 font-mono text-xs outline-none mt-0.5"
            style={{
              borderColor: `${side === "BUY" ? C.gold : C.red}44`,
              color: C.text,
            }}
            data-ocid="exchange.order.amount_input"
          />
          <div className="flex gap-1 mt-1">
            {[0.25, 0.5, 1.0].map((pct) => (
              <button
                key={pct}
                type="button"
                onClick={() => setAmount(fmtShort(maxAmount * pct, 4))}
                className="flex-1 font-mono text-[7px] py-0.5 border"
                style={{ borderColor: C.border, color: C.muted }}
              >
                {pct === 1.0 ? "MAX" : `${pct * 100}%`}
              </button>
            ))}
          </div>
        </div>

        <div
          className="flex justify-between border-t pt-2"
          style={{ borderColor: C.border }}
        >
          <Lbl>TOTAL (ICP)</Lbl>
          <Val color={C.gold} size="text-[10px]">
            {total > 0 ? fmt(total, 6) : "—"}
          </Val>
        </div>

        <div className="relative">
          {!isAuthenticated && <LockOverlay />}
          <button
            type="button"
            onClick={handleExecute}
            disabled={!isAuthenticated || pending || !numAmount || !gatesPass}
            data-ocid="exchange.order.submit_button"
            className="w-full py-2.5 font-mono text-[9px] tracking-[0.3em] font-bold border transition-all disabled:opacity-40"
            style={{
              borderColor: side === "BUY" ? `${C.gold}88` : `${C.red}88`,
              color: side === "BUY" ? C.gold : C.red,
              background: side === "BUY" ? C.goldDim : "rgba(180,60,60,0.15)",
            }}
          >
            {pending ? "PROCESSING..." : `EXECUTE ${side}`}
          </button>
        </div>

        {auditTrades.slice(0, 2).length > 0 && (
          <div>
            <Lbl>RECENT FILLS</Lbl>
            <div className="space-y-0.5 mt-1">
              {auditTrades.slice(0, 2).map((t, i) => (
                <div
                  key={`fill-${t.beat}-${i}`}
                  className="flex items-center justify-between py-0.5"
                >
                  <span
                    className="font-mono text-[7px] px-1"
                    style={{
                      color: t.side === "BUY" ? C.green : C.red,
                      border: `1px solid ${t.side === "BUY" ? C.green : C.red}44`,
                    }}
                  >
                    {t.side}
                  </span>
                  <span
                    className="font-mono text-[7px]"
                    style={{ color: C.muted }}
                  >
                    BEAT {t.beat}
                  </span>
                  <span
                    className="font-mono text-[7px]"
                    style={{ color: C.green }}
                  >
                    FILLED
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </PanelBox>
  );
}

// ── E. Settlement History Strip ─────────────────────────────────────────────────
function SettlementHistoryStrip({
  feed,
  stats,
}: {
  feed: SettlementEvent[];
  stats: IntelligenceEngineResult["settlementStats"];
}) {
  return (
    <PanelBox style={{ borderColor: C.border }}>
      <div
        className="flex items-center justify-between px-3 py-2 border-b"
        style={{ borderColor: C.border }}
      >
        <span
          className="font-mono text-[8px] tracking-[0.4em]"
          style={{ color: C.muted }}
        >
          SETTLEMENT HISTORY
        </span>
        <span className="font-mono text-[8px]" style={{ color: C.muted }}>
          {feed.length} RECORDS
        </span>
      </div>
      <div className="overflow-x-auto">
        <div
          className="flex items-center px-3 py-1 border-b text-[7px] font-mono"
          style={{ borderColor: C.border, color: C.dim, minWidth: 560 }}
        >
          <span className="w-16">BEAT</span>
          <span className="w-20">TOKEN</span>
          <span className="w-24">AMOUNT</span>
          <span className="w-20">TYPE</span>
          <span className="w-20">RATE</span>
          <span className="flex-1 text-right">ƒ VALUE</span>
        </div>
        <div
          style={{ maxHeight: 120, overflowY: "auto" }}
          data-ocid="exchange.history.table"
        >
          {feed.length === 0 ? (
            <div
              className="text-center py-4 font-mono text-[9px]"
              style={{ color: C.muted }}
              data-ocid="exchange.history.empty_state"
            >
              NO SETTLEMENTS RECORDED YET
            </div>
          ) : (
            feed.map((evt, i) => (
              <motion.div
                key={`hist-${Number(evt.beat)}-${i}`}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                data-ocid={`exchange.history.item.${i + 1}`}
                className="flex items-center px-3 py-1 border-b text-[9px] font-mono hover:bg-white/[0.02]"
                style={{ borderColor: C.border, minWidth: 560 }}
              >
                <span className="w-16" style={{ color: C.muted }}>
                  {Number(evt.beat)}
                </span>
                <span className="w-20">
                  <TokenBadge code={evt.tokenCode} />
                </span>
                <span className="w-24" style={{ color: C.text }}>
                  {fmtCompact(Number(evt.amount))}
                </span>
                <span
                  className="w-20"
                  style={{
                    color:
                      evt.sType === "MINT"
                        ? C.gold
                        : evt.sType === "SWAP"
                          ? C.cyan
                          : C.muted,
                  }}
                >
                  {evt.sType}
                </span>
                <span className="w-20" style={{ color: C.silver }}>
                  {evt.rate > 0 ? evt.rate.toFixed(6) : "—"}
                </span>
                <span className="flex-1 text-right" style={{ color: C.gold }}>
                  ƒ{fmtCompact(evt.formaValue)}
                </span>
              </motion.div>
            ))
          )}
        </div>
        {(stats?.totalFormaCleared ?? 0) > 0 && (
          <div
            className="flex items-center justify-end px-3 py-1.5 border-t"
            style={{ borderColor: `${C.gold}22`, background: `${C.gold}04` }}
          >
            <Lbl>TOTAL CLEARED</Lbl>
            <span
              className="font-mono text-[10px] ml-3"
              style={{ color: C.gold }}
            >
              ƒ{fmtCompact(stats!.totalFormaCleared)}
            </span>
          </div>
        )}
      </div>
    </PanelBox>
  );
}

// ── F. Transfer Tab ─────────────────────────────────────────────────────────────
function TransferTab({
  isAuthenticated,
  actor,
}: { isAuthenticated: boolean; actor: any }) {
  const [tokenCode, setTokenCode] = useState<TokenCode>("MTC");
  const [toAddress, setToAddress] = useState("");
  const [amount, setAmount] = useState("");
  const [pending, setPending] = useState(false);
  const [history, setHistory] = useState<
    Array<{
      beat: bigint;
      tokenCode: string;
      amount: bigint;
      toAddress: string;
      formaValue: number;
    }>
  >([]);
  const [lastResult, setLastResult] = useState<{
    success: boolean;
    newBalance: bigint;
  } | null>(null);

  // Load transfer history
  useEffect(() => {
    if (!actor) return;
    let cancelled = false;
    const load = async () => {
      try {
        const hist = await actor.getTransferHistory?.(20n).catch(() => []);
        if (!cancelled && Array.isArray(hist)) setHistory(hist);
      } catch {
        /* silent */
      }
    };
    load();
    const id = setInterval(load, 5000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [actor]);

  const numAmount = Number.parseFloat(amount) || 0;

  const handleTransfer = async () => {
    if (!actor || numAmount <= 0 || !toAddress) return;
    setPending(true);
    try {
      const result = await actor.px_transferToken(
        tokenCode,
        toAddress,
        BigInt(Math.floor(numAmount)),
      );
      if (result?.success) {
        toast.success(
          `TRANSFER: ${numAmount} ${tokenCode} → ${toAddress.slice(0, 12)}…`,
        );
        setLastResult(result);
        setAmount("");
      } else {
        toast.error("Transfer failed");
      }
    } catch {
      toast.error("Transfer error");
    } finally {
      setPending(false);
    }
  };

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <PanelBox className="p-4">
        <SectionTitle>→ TOKEN TRANSFER</SectionTitle>
        <div className="space-y-3">
          <div>
            <Lbl>TOKEN</Lbl>
            <select
              value={tokenCode}
              onChange={(e) => setTokenCode(e.target.value as TokenCode)}
              data-ocid="exchange.transfer.select"
              className="w-full mt-0.5 bg-transparent border px-2 py-1.5 font-mono text-xs outline-none"
              style={{ borderColor: C.border, color: C.gold }}
            >
              {ALL_TOKENS.map((t) => (
                <option
                  key={t.code}
                  value={t.code}
                  style={{ background: "#050508" }}
                >
                  {t.code}
                </option>
              ))}
            </select>
          </div>
          <div>
            <Lbl>TO ADDRESS</Lbl>
            <input
              type="text"
              value={toAddress}
              onChange={(e) => setToAddress(e.target.value)}
              placeholder="Principal or account ID"
              className="w-full mt-0.5 bg-transparent border px-2 py-1.5 font-mono text-xs outline-none"
              style={{ borderColor: `${C.cyan}44`, color: C.text }}
              data-ocid="exchange.transfer.address_input"
            />
          </div>
          <div>
            <Lbl>AMOUNT</Lbl>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0"
              className="w-full mt-0.5 bg-transparent border px-2 py-1.5 font-mono text-xs outline-none"
              style={{ borderColor: `${C.cyan}44`, color: C.text }}
              data-ocid="exchange.transfer.amount_input"
            />
          </div>

          <div className="relative">
            {!isAuthenticated && <LockOverlay />}
            <button
              type="button"
              onClick={handleTransfer}
              disabled={
                !isAuthenticated || pending || numAmount <= 0 || !toAddress
              }
              data-ocid="exchange.transfer.submit_button"
              className="w-full py-2.5 font-mono text-[9px] tracking-[0.3em] border transition-all disabled:opacity-40"
              style={{ borderColor: `${C.cyan}55`, color: C.cyan }}
            >
              {pending ? "PROCESSING..." : "INITIATE TRANSFER"}
            </button>
          </div>

          {lastResult && (
            <div
              className="font-mono text-[8px] p-2 border"
              style={{
                borderColor: lastResult.success ? `${C.green}33` : `${C.red}33`,
                color: lastResult.success ? C.green : C.red,
              }}
              data-ocid={
                lastResult.success
                  ? "exchange.transfer.success_state"
                  : "exchange.transfer.error_state"
              }
            >
              {lastResult.success
                ? `NEW BALANCE: ${Number(lastResult.newBalance)}`
                : "TRANSFER REJECTED"}
            </div>
          )}
        </div>
      </PanelBox>

      <PanelBox className="p-4">
        <SectionTitle>⦿ TRANSFER HISTORY</SectionTitle>
        <div style={{ maxHeight: 360, overflowY: "auto" }}>
          {history.length === 0 ? (
            <div
              className="font-mono text-[9px] text-center py-8"
              style={{ color: C.muted }}
              data-ocid="exchange.transfer.empty_state"
            >
              NO TRANSFERS YET
            </div>
          ) : (
            history.map((r, i) => (
              <div
                key={`txr-${Number(r.beat)}-${i}`}
                data-ocid={`exchange.transfer.item.${i + 1}`}
                className="flex items-center gap-2 py-1.5 border-b text-[9px] font-mono"
                style={{ borderColor: C.border }}
              >
                <TokenBadge code={r.tokenCode} />
                <span className="flex-1" style={{ color: C.text }}>
                  {fmtCompact(Number(r.amount))}
                </span>
                <span
                  className="font-mono text-[7px]"
                  style={{ color: C.muted }}
                >
                  {r.toAddress.slice(0, 12)}…
                </span>
                <span style={{ color: C.gold }}>
                  ƒ{fmtCompact(r.formaValue)}
                </span>
                <span style={{ color: C.dim }}>#{Number(r.beat)}</span>
              </div>
            ))
          )}
        </div>
      </PanelBox>
    </div>
  );
}

// ── G. Sovereign tab (existing panels preserved) ────────────────────────────────
const TOKEN_LIST = [
  { key: "gtk", symbol: "GTK", tier: "gold" },
  { key: "mth", symbol: "MTH", tier: "gold" },
  { key: "mrc", symbol: "MRC", tier: "gold" },
  { key: "cvt", symbol: "CVT", tier: "silver" },
  { key: "vct", symbol: "VCT", tier: "silver" },
  { key: "knt", symbol: "KNT", tier: "silver" },
  { key: "sbt", symbol: "SBT", tier: "base" },
  { key: "hbt", symbol: "HBT", tier: "base" },
  { key: "drt", symbol: "DRT", tier: "base" },
  { key: "rst", symbol: "RST", tier: "base" },
  { key: "omt", symbol: "OMT", tier: "base" },
  { key: "lgt", symbol: "LGT", tier: "base" },
] as const;

function SovereignTabContent({
  eng,
  isAuthenticated,
  actor,
}: {
  eng: IntelligenceEngineResult;
  isAuthenticated: boolean;
  actor: any;
}) {
  const { fullState, formaProjVelocity, tokenBalances, quantumBattery } = eng;
  const forma = fullState?.formaCapital ?? 0;
  const rung = Number(fullState?.jacobRung ?? 0n);

  const mining = fullState?.miningOutput ?? 0;

  const [battPending, setBattPending] = useState(false);

  const tcColor = (tier: string) =>
    tier === "gold" ? C.gold : tier === "silver" ? C.cyan : C.dim;

  const balances: Record<string, bigint> = {
    gtk: tokenBalances?.gtk ?? 0n,
    mth: tokenBalances?.mth ?? 0n,
    mrc: tokenBalances?.mrc ?? 0n,
    cvt: tokenBalances?.cvt ?? 0n,
    vct: tokenBalances?.vct ?? 0n,
    knt: tokenBalances?.knt ?? 0n,
    sbt: tokenBalances?.sbt ?? 0n,
    hbt: tokenBalances?.hbt ?? 0n,
    drt: tokenBalances?.drt ?? 0n,
    rst: tokenBalances?.rst ?? 0n,
    omt: tokenBalances?.omt ?? 0n,
    lgt: tokenBalances?.lgt ?? 0n,
  };

  const maxBal = Math.max(
    ...TOKEN_LIST.map((t) => Number(balances[t.key] ?? 0n)),
    1,
  );
  const rungLabels = ["R0", "R1", "R2", "R3", "R4"];
  const rungMult = ["1.0x", "1.1x", "1.1x", "1.2x", "1.5x"];
  const pct = Math.min(100, (quantumBattery?.batteryBalance ?? 0) * 10);

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* FORMA Engine */}
        <PanelBox className="p-4">
          <SectionTitle>ƒ FORMA COMPOUNDING ENGINE</SectionTitle>
          <div className="mb-3">
            <Lbl>FORMA CAPITAL</Lbl>
            <div
              className="font-mono text-2xl font-bold mt-1"
              style={{ color: C.gold, textShadow: `0 0 20px ${C.gold}55` }}
            >
              ƒ{" "}
              {forma.toLocaleString("en-US", {
                minimumFractionDigits: 6,
                maximumFractionDigits: 6,
              })}
            </div>
          </div>
          <div className="mb-3">
            <div className="flex items-center justify-between mb-1.5">
              <Lbl>JACOB'S LADDER</Lbl>
              <Val color={C.gold}>{rungMult[rung] ?? "1.0x"}</Val>
            </div>
            <div className="flex gap-0.5">
              {rungLabels.map((r, i) => (
                <div
                  key={r}
                  className="flex-1 h-2 flex items-center justify-center"
                  style={{
                    background: i <= rung ? C.gold : "rgba(255,255,255,0.05)",
                    boxShadow: i === rung ? `0 0 8px ${C.gold}55` : undefined,
                  }}
                >
                  <span
                    className="font-mono text-[6px]"
                    style={{ color: i <= rung ? "#000" : C.dim }}
                  >
                    {r}
                  </span>
                </div>
              ))}
            </div>
          </div>
          {[
            { beats: 100, label: "+100 BEATS" },
            { beats: 1000, label: "+1K BEATS" },
            { beats: 10000, label: "+10K BEATS" },
          ].map(({ beats, label }) => {
            const rate =
              forma > 0 ? (formaProjVelocity - forma) / forma / 1000 : 0;
            const proj = forma * Math.exp(Math.max(0, rate) * beats);
            return (
              <div key={beats} className="flex justify-between">
                <Lbl>{label}</Lbl>
                <Val size="text-[10px]" color={C.gold}>
                  ƒ{" "}
                  {proj.toLocaleString("en-US", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}
                </Val>
              </div>
            );
          })}
          <div className="flex justify-between mt-2">
            <Lbl>MINING OUTPUT</Lbl>
            <Val color={C.amber}>{mining.toFixed(8)}</Val>
          </div>
        </PanelBox>

        {/* Token Grid */}
        <PanelBox className="p-4">
          <SectionTitle>■ 12-TOKEN SOVEREIGN GRID</SectionTitle>
          <div className="space-y-1.5">
            {TOKEN_LIST.map((t) => {
              const bal = Number(balances[t.key] ?? 0n);
              const barPct = maxBal > 0 ? (bal / maxBal) * 100 : 0;
              return (
                <div key={t.key} className="flex items-center gap-2">
                  <span
                    className="font-mono text-[8px] w-8 shrink-0"
                    style={{ color: tcColor(t.tier) }}
                  >
                    {t.symbol}
                  </span>
                  <div
                    className="flex-1 h-1.5"
                    style={{ background: "rgba(255,255,255,0.04)" }}
                  >
                    <div
                      style={{
                        width: `${barPct}%`,
                        height: "100%",
                        background: tcColor(t.tier),
                        opacity: 0.7,
                      }}
                    />
                  </div>
                  <span
                    className="font-mono text-[8px] w-16 text-right tabular-nums"
                    style={{ color: tcColor(t.tier) }}
                  >
                    {bal.toLocaleString()}
                  </span>
                </div>
              );
            })}
          </div>
        </PanelBox>
      </div>

      {/* Quantum Battery */}
      {quantumBattery && (
        <PanelBox className="p-4">
          <SectionTitle>⚡ QUANTUM BATTERY</SectionTitle>
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <div className="flex justify-between mb-1">
                <Lbl>CHARGE</Lbl>
                <Val color={C.cyan}>{pct.toFixed(1)}%</Val>
              </div>
              <div
                className="w-full h-2"
                style={{ background: "rgba(255,255,255,0.06)" }}
              >
                <div
                  style={{
                    width: `${pct}%`,
                    height: "100%",
                    background: C.cyan,
                    boxShadow: `0 0 8px ${C.cyan}44`,
                  }}
                />
              </div>
            </div>
            <div className="relative shrink-0">
              {!isAuthenticated && <LockOverlay />}
              <button
                type="button"
                onClick={async () => {
                  if (!actor) return;
                  setBattPending(true);
                  try {
                    const yield_ = await actor.dischargeQuantumBattery();
                    toast.success(`DISCHARGE: ${yield_.toFixed(6)} ICP yield`);
                  } catch {
                    toast.error("Discharge failed");
                  } finally {
                    setBattPending(false);
                  }
                }}
                disabled={
                  !isAuthenticated ||
                  battPending ||
                  quantumBattery.batteryLocked
                }
                data-ocid="exchange.battery.discharge_button"
                className="px-4 py-2 font-mono text-[9px] tracking-widest border transition-all disabled:opacity-40"
                style={{ borderColor: `${C.cyan}55`, color: C.cyan }}
              >
                {battPending ? "DISCHARGING..." : "DISCHARGE"}
              </button>
            </div>
          </div>
        </PanelBox>
      )}
    </div>
  );
}

// ── H. Multi-Chain Tab ───────────────────────────────────────────────────────────
function MultiChainTab({ eng }: { eng: IntelligenceEngineResult }) {
  const {
    feeds,
    btcEma21,
    btcEma200,
    btcZscore,
    btcMomentum,
    ethMomentum,
    regime,
    activeAlerts,
    arbitrageSpread,
  } = eng;
  const btc = feeds?.btcPrice ?? 0;
  const eth = feeds?.ethPrice ?? 0;
  const icp = feeds?.icpPrice ?? 0;

  const emaSignal =
    btcEma21 > btcEma200 ? "BULL" : btcEma21 < btcEma200 ? "BEAR" : "FLAT";
  const emaColor =
    emaSignal === "BULL" ? C.green : emaSignal === "BEAR" ? C.red : C.amber;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: "BTC/USD", val: btc, mom: btcMomentum },
          { label: "ETH/USD", val: eth, mom: ethMomentum },
          { label: "ICP/USD", val: icp, mom: 0 },
        ].map(({ label, val, mom }) => (
          <PanelBox key={label} className="p-4">
            <Lbl>{label}</Lbl>
            <div
              className="font-mono text-xl font-bold mt-1"
              style={{ color: C.gold }}
            >
              ${val > 0 ? fmtShort(val, 2) : "—"}
            </div>
            {mom !== 0 && (
              <span
                className="font-mono text-[9px]"
                style={{ color: mom > 0 ? C.green : C.red }}
              >
                {mom > 0 ? "+" : ""}
                {(mom * 100).toFixed(3)}%
              </span>
            )}
          </PanelBox>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <PanelBox className="p-4">
          <SectionTitle>≈ INTELLIGENCE MATRIX</SectionTitle>
          <div className="space-y-2">
            {[
              { label: "BTC EMA SIGNAL", val: emaSignal, color: emaColor },
              {
                label: "REGIME",
                val: regime,
                color:
                  regime === "BULL"
                    ? C.green
                    : regime === "BEAR"
                      ? C.red
                      : C.amber,
              },
              {
                label: "BTC Z-SCORE",
                val: `${btcZscore.toFixed(3)}σ`,
                color: Math.abs(btcZscore) > 2 ? C.red : C.text,
              },
              {
                label: "ARB SPREAD",
                val: `${(arbitrageSpread * 100).toFixed(2)}%`,
                color: arbitrageSpread > 0.1 ? C.amber : C.green,
              },
            ].map(({ label, val, color }) => (
              <div key={label} className="flex justify-between">
                <Lbl>{label}</Lbl>
                <Val size="text-[10px]" color={color}>
                  {val}
                </Val>
              </div>
            ))}
          </div>
        </PanelBox>

        <PanelBox className="p-4">
          <SectionTitle>⚠ ALERT FEED</SectionTitle>
          <div style={{ maxHeight: 240, overflowY: "auto" }}>
            {activeAlerts.length === 0 ? (
              <div
                className="font-mono text-[9px] text-center py-6"
                style={{ color: C.dim }}
                data-ocid="exchange.alerts.empty_state"
              >
                NO ACTIVE ALERTS
              </div>
            ) : (
              activeAlerts.slice(0, 10).map((alert, i) => (
                <div
                  key={alert.id}
                  data-ocid={`exchange.alerts.item.${i + 1}`}
                  className="flex items-start gap-2 py-1.5 border-b text-[8px] font-mono"
                  style={{ borderColor: C.border }}
                >
                  <span
                    className="shrink-0 px-1 py-0.5"
                    style={{
                      color:
                        alert.level === "CRITICAL"
                          ? C.red
                          : alert.level === "WARN"
                            ? C.amber
                            : C.cyan,
                      border: `1px solid ${alert.level === "CRITICAL" ? C.red : alert.level === "WARN" ? C.amber : C.cyan}44`,
                    }}
                  >
                    {alert.level}
                  </span>
                  <span className="flex-1" style={{ color: C.text }}>
                    {alert.message}
                  </span>
                </div>
              ))
            )}
          </div>
        </PanelBox>
      </div>
    </div>
  );
}

// ── MAIN ExchangeTab ───────────────────────────────────────────────────────────────
export function ExchangeTab() {
  const { identity } = useInternetIdentity();
  const { actor } = useActor();
  const isAuthenticated =
    identity != null && !identity.getPrincipal().isAnonymous();
  const eng = useIntelligenceEngine();
  const [selectedPair, setSelectedPair] = useState<TokenCode>("MTC");
  const [subTab, setSubTab] = useState<
    "SPOT" | "SOVEREIGN" | "MULTI-CHAIN" | "TRANSFER"
  >("SPOT");

  const {
    candles,
    candleTimeframe,
    setCandleTimeframe,
    settlementFeed,
    settlementStats,
  } = eng;

  const subTabs = ["SPOT", "SOVEREIGN", "MULTI-CHAIN", "TRANSFER"] as const;

  return (
    <div
      className="flex flex-col"
      style={{ background: C.bg, minHeight: "100vh" }}
      data-ocid="exchange.page"
    >
      {/* Top Bar */}
      <ExchangeTopBar
        eng={eng}
        pair={selectedPair}
        onPairChange={setSelectedPair}
      />

      {/* Sub-tab nav */}
      <div
        className="flex items-center gap-0 border-b"
        style={{ borderColor: C.border }}
      >
        {subTabs.map((t) => (
          <button
            key={t}
            type="button"
            onClick={() => setSubTab(t)}
            data-ocid={`exchange.${t.toLowerCase().replace("-", "_")}.tab`}
            className="font-mono text-[9px] tracking-[0.3em] px-4 py-2.5 border-r transition-all"
            style={{
              borderColor: C.border,
              color: subTab === t ? C.gold : C.muted,
              borderBottom:
                subTab === t ? `2px solid ${C.gold}` : "2px solid transparent",
              background: subTab === t ? `${C.gold}06` : "transparent",
            }}
          >
            {t}
          </button>
        ))}
      </div>

      {/* SPOT tab — main trading terminal */}
      {subTab === "SPOT" && (
        <div className="flex flex-col" style={{ flex: 1 }}>
          {/* 3-column main layout */}
          <div
            className="grid gap-0"
            style={{ gridTemplateColumns: "220px 1fr 240px", height: "520px" }}
          >
            {/* LEFT: Settlement Feed */}
            <div
              style={{
                borderRight: `1px solid ${C.border}`,
                overflow: "hidden",
              }}
            >
              <SettlementFeed feed={settlementFeed} stats={settlementStats} />
            </div>

            {/* CENTER: Candlestick chart */}
            <div style={{ borderRight: `1px solid ${C.border}` }}>
              <CandlestickChart
                candles={candles}
                timeframe={candleTimeframe}
                onTimeframeChange={setCandleTimeframe}
                selectedPair={selectedPair}
              />
            </div>

            {/* RIGHT: Clearing Operations (stacked) */}
            <div className="flex flex-col overflow-y-auto">
              <TokenSwapPanel
                eng={eng}
                isAuthenticated={isAuthenticated}
                actor={actor}
              />
              <div style={{ borderTop: `1px solid ${C.border}` }}>
                <ReserveStatusPanel eng={eng} />
              </div>
              <div style={{ borderTop: `1px solid ${C.border}` }}>
                <OrderEntryPanel
                  eng={eng}
                  pair={selectedPair}
                  isAuthenticated={isAuthenticated}
                  actor={actor}
                />
              </div>
            </div>
          </div>

          {/* Bottom: Settlement History */}
          <div style={{ borderTop: `1px solid ${C.border}` }}>
            <SettlementHistoryStrip
              feed={settlementFeed}
              stats={settlementStats}
            />
          </div>
        </div>
      )}

      {/* SOVEREIGN tab */}
      {subTab === "SOVEREIGN" && (
        <div className="p-4">
          <SovereignTabContent
            eng={eng}
            isAuthenticated={isAuthenticated}
            actor={actor}
          />
        </div>
      )}

      {/* MULTI-CHAIN tab */}
      {subTab === "MULTI-CHAIN" && (
        <div className="p-4">
          <MultiChainTab eng={eng} />
        </div>
      )}

      {/* TRANSFER tab */}
      {subTab === "TRANSFER" && (
        <div className="p-4">
          <TransferTab isAuthenticated={isAuthenticated} actor={actor} />
        </div>
      )}
    </div>
  );
}
