import { motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useActor } from "../hooks/useActor";

interface LandingPageProps {
  onEnterDashboard: () => void;
}

// ── Backend types ──────────────────────────────────────────────────────────────
interface ExternalFeeds {
  btcPrice: number;
  ethPrice: number;
  icpPrice: number;
  liveDataActive: boolean;
}
interface BrainSignals {
  systemCoherenceScore: number;
  engineIntelligenceScore: number;
}
interface FullStateLanding {
  beat: bigint;
  formaCapital: number;
  regime: string;
}
interface MtcStateLanding {
  price: number;
  circulating: number;
  burned: number;
}

// ── Helpers ───────────────────────────────────────────────────────────────────────────
function fmtPrice(n: number | null, dec = 0): string {
  if (!n) return "——";
  return n.toLocaleString("en-US", {
    minimumFractionDigits: dec,
    maximumFractionDigits: dec,
  });
}

// ── Quantum Field Canvas (preserved from original) ──────────────────────────────
function QuantumFieldCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const NUM_PARTICLES = 90;
    type Particle = {
      x: number;
      y: number;
      vx: number;
      vy: number;
      size: number;
    };
    let particles: Particle[] = [];
    let W = 0;
    let H = 0;

    const resize = () => {
      W = canvas.width = canvas.offsetWidth;
      H = canvas.height = canvas.offsetHeight;
      particles = Array.from({ length: NUM_PARTICLES }, () => ({
        x: Math.random() * W,
        y: Math.random() * H,
        vx: (Math.random() - 0.5) * 0.55,
        vy: (Math.random() - 0.5) * 0.55,
        size: 0.8 + Math.random() * 2.2,
      }));
    };

    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(canvas);

    const rings = [
      {
        a: 0.38,
        b: 0.22,
        rot: 0,
        speed: 0.00018,
        color: "0.78 0.18 85",
        alpha: 0.18,
      },
      {
        a: 0.46,
        b: 0.28,
        rot: 0.8,
        speed: -0.00013,
        color: "0.78 0.18 85",
        alpha: 0.12,
      },
      {
        a: 0.55,
        b: 0.34,
        rot: 1.6,
        speed: 0.00009,
        color: "0.55 0.20 290",
        alpha: 0.1,
      },
      {
        a: 0.62,
        b: 0.4,
        rot: 2.4,
        speed: -0.00007,
        color: "0.55 0.20 290",
        alpha: 0.08,
      },
      {
        a: 0.7,
        b: 0.46,
        rot: 3.2,
        speed: 0.00005,
        color: "0.78 0.18 85",
        alpha: 0.06,
      },
    ];

    const draw = () => {
      ctx.clearRect(0, 0, W, H);
      const grd = ctx.createRadialGradient(
        W / 2,
        H / 2,
        0,
        W / 2,
        H / 2,
        Math.min(W, H) * 0.45,
      );
      grd.addColorStop(0, "oklch(0.55 0.20 290 / 0.14)");
      grd.addColorStop(0.5, "oklch(0.55 0.20 290 / 0.04)");
      grd.addColorStop(1, "transparent");
      ctx.fillStyle = grd;
      ctx.fillRect(0, 0, W, H);

      for (const r of rings) {
        r.rot += r.speed;
        ctx.save();
        ctx.translate(W / 2, H / 2);
        ctx.rotate(r.rot);
        ctx.beginPath();
        ctx.ellipse(0, 0, W * r.a, H * r.b, 0, 0, Math.PI * 2);
        ctx.strokeStyle = `oklch(${r.color} / ${r.alpha})`;
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.restore();
      }

      for (const p of particles) {
        p.x += p.vx;
        p.y += p.vy;
        if (p.x < 0) p.x = W;
        if (p.x > W) p.x = 0;
        if (p.y < 0) p.y = H;
        if (p.y > H) p.y = 0;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = "oklch(0.78 0.18 85 / 0.5)";
        ctx.fill();
      }

      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 140) {
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `oklch(0.78 0.15 85 / ${((1 - dist / 140) * 0.28).toFixed(3)})`;
            ctx.lineWidth = 0.6;
            ctx.stroke();
          }
        }
      }

      rafRef.current = requestAnimationFrame(draw);
    };

    rafRef.current = requestAnimationFrame(draw);
    return () => {
      cancelAnimationFrame(rafRef.current);
      ro.disconnect();
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        display: "block",
      }}
    />
  );
}

// ── Mini Candlestick (for hero widget) ──────────────────────────────────────────────
function MiniCandleChart({ price }: { price: number }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const priceHistRef = useRef<number[]>([]);
  const rafRef = useRef<number>(0);

  useEffect(() => {
    if (price > 0) {
      priceHistRef.current.push(price + (Math.random() - 0.5) * price * 0.002);
      if (priceHistRef.current.length > 40) priceHistRef.current.shift();
    }
  }, [price]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const draw = () => {
      const W = canvas.width;
      const H = canvas.height;
      ctx.clearRect(0, 0, W, H);
      ctx.fillStyle = "rgba(0,0,0,0)";
      ctx.fillRect(0, 0, W, H);

      const prices = priceHistRef.current;
      if (prices.length < 3) {
        ctx.font = "9px monospace";
        ctx.fillStyle = "rgba(200,160,60,0.4)";
        ctx.textAlign = "center";
        ctx.fillText("LOADING...", W / 2, H / 2);
        rafRef.current = requestAnimationFrame(draw);
        return;
      }

      const minP = Math.min(...prices) * 0.999;
      const maxP = Math.max(...prices) * 1.001;
      const range = maxP - minP || 1;
      const slotW = W / prices.length;
      const barW = Math.max(2, slotW * 0.6);

      for (let i = 1; i < prices.length; i++) {
        const prev = prices[i - 1] ?? prices[i];
        const cur = prices[i];
        const x = i * slotW + slotW / 2;
        const openY = H - ((prev - minP) / range) * H;
        const closeY = H - ((cur - minP) / range) * H;
        const isUp = cur >= prev;
        const bodyTop = Math.min(openY, closeY);
        const bodyH = Math.max(1, Math.abs(closeY - openY));
        ctx.fillStyle = isUp ? "rgba(74,170,106,0.85)" : "rgba(204,68,68,0.85)";
        ctx.fillRect(x - barW / 2, bodyTop, barW, bodyH);
      }

      // Price line
      ctx.beginPath();
      for (let i = 0; i < prices.length; i++) {
        const x = i * slotW + slotW / 2;
        const y = H - ((prices[i] - minP) / range) * H;
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "rgba(200,160,60,0.5)";
      ctx.lineWidth = 1;
      ctx.stroke();

      rafRef.current = requestAnimationFrame(draw);
    };

    rafRef.current = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(rafRef.current);
  }, []);

  return (
    <canvas
      ref={canvasRef}
      width={260}
      height={60}
      style={{ width: "100%", height: 60 }}
    />
  );
}

// ── Enter Button ─────────────────────────────────────────────────────────────────────────
function EnterButton({
  onClick,
  size = "lg",
  label,
}: {
  onClick: () => void;
  size?: "lg" | "sm";
  label?: string;
}) {
  const [hovered, setHovered] = useState(false);
  const isLg = size === "lg";
  return (
    <button
      type="button"
      data-ocid="landing.primary_button"
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered ? "oklch(0.84 0.18 85)" : "oklch(0.78 0.18 85)",
        color: "oklch(0.05 0 0)",
        border: "none",
        padding: isLg ? "16px 48px" : "10px 28px",
        fontSize: isLg ? "13px" : "11px",
        fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
        fontWeight: 800,
        letterSpacing: "0.22em",
        cursor: "pointer",
        boxShadow: hovered
          ? "0 0 60px oklch(0.78 0.18 85 / 0.55), 0 0 120px oklch(0.78 0.18 85 / 0.22)"
          : "0 0 40px oklch(0.78 0.18 85 / 0.35)",
        transition: "all 0.2s ease",
        position: "relative" as const,
        zIndex: 10,
        textTransform: "uppercase" as const,
        whiteSpace: "nowrap" as const,
      }}
    >
      {label ?? (isLg ? "ENTER THE EXCHANGE" : "ENTER →")}
    </button>
  );
}

// ── Live Proof Strip ────────────────────────────────────────────────────────────────────
function LiveProofStrip({
  brain,
  fullState,
  regime,
  formaCapital,
}: {
  brain: BrainSignals | null;
  fullState: FullStateLanding | null;
  regime: string;
  formaCapital: number;
}) {
  const intel = brain
    ? Math.min(
        100,
        Math.max(
          0,
          ((brain.systemCoherenceScore + brain.engineIntelligenceScore) / 2) *
            100,
        ),
      )
    : null;
  const beat = fullState ? Number(fullState.beat) : null;
  const regimeColor =
    regime === "BULL"
      ? "oklch(0.62 0.17 145)"
      : regime === "BEAR"
        ? "oklch(0.55 0.22 25)"
        : "oklch(0.75 0.18 62)";

  const metrics = [
    {
      label: "INTELLIGENCE SCORE",
      value: intel !== null ? intel.toFixed(1) : "——",
      color: "oklch(0.78 0.18 85)",
    },
    {
      label: "BEATS PROCESSED",
      value: beat !== null ? beat.toLocaleString() : "——",
      color: "oklch(0.72 0.15 200)",
    },
    {
      label: "MARKET REGIME",
      value: regime || "——",
      color: regimeColor,
    },
    {
      label: "CAPITAL COMPOUNDING",
      value:
        formaCapital > 0
          ? `\u0192 ${formaCapital.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
          : "——",
      color: "oklch(0.78 0.18 85)",
    },
  ];

  return (
    <section
      style={{
        background: "oklch(0.06 0.01 240)",
        borderTop: "1px solid rgba(255,255,255,0.04)",
        borderBottom: "1px solid rgba(255,255,255,0.04)",
        padding: "20px clamp(16px, 5vw, 80px)",
      }}
    >
      <div style={{ maxWidth: 1280, margin: "0 auto" }}>
        <div
          style={{
            display: "flex",
            flexWrap: "wrap" as const,
            alignItems: "center",
            justifyContent: "space-between",
            gap: 24,
          }}
        >
          {metrics.map((m) => (
            <div
              key={m.label}
              style={{
                display: "flex",
                flexDirection: "column" as const,
                gap: 4,
              }}
            >
              <span
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 9,
                  letterSpacing: "0.28em",
                  color: "oklch(0.42 0.04 270)",
                  textTransform: "uppercase" as const,
                }}
              >
                {m.label}
              </span>
              <span
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 15,
                  fontWeight: 700,
                  color: m.color,
                  letterSpacing: "0.04em",
                }}
              >
                {m.value}
              </span>
            </div>
          ))}
          <div
            style={{
              fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
              fontSize: 9,
              letterSpacing: "0.2em",
              color: "oklch(0.38 0.04 270)",
              display: "flex",
              alignItems: "center",
              gap: 6,
            }}
          >
            <span
              style={{
                width: 5,
                height: 5,
                borderRadius: "50%",
                background: "oklch(0.62 0.17 145)",
                display: "inline-block",
                animation: "beat-pulse 2s ease-in-out infinite",
              }}
            />
            LIVE FROM THE ORGANISM· UPDATES EVERY 3 SECONDS
          </div>
        </div>
      </div>
    </section>
  );
}

// ── Main Component ───────────────────────────────────────────────────────────────────────
export default function LandingPage({ onEnterDashboard }: LandingPageProps) {
  const { actor } = useActor();
  const [feeds, setFeeds] = useState<ExternalFeeds | null>(null);
  const [brain, setBrain] = useState<BrainSignals | null>(null);
  const [fullState, setFullState] = useState<FullStateLanding | null>(null);
  const [mtcState, setMtcState] = useState<MtcStateLanding | null>(null);
  const [accessSubmitted, setAccessSubmitted] = useState(false);
  const [accessForm, setAccessForm] = useState({
    name: "",
    email: "",
    intent: "Trading",
  });

  const pollData = useCallback(async () => {
    if (!actor) return;
    const [f, b, fs, ms] = await Promise.all([
      (actor as any).getExternalFeeds().catch(() => null),
      (actor as any).getBrainSignals().catch(() => null),
      (actor as any).px_getFullState().catch(() => null),
      (actor as any).getMtcState().catch(() => null),
    ]);
    if (f) setFeeds(f as ExternalFeeds);
    if (b) setBrain(b as BrainSignals);
    if (fs) setFullState(fs as FullStateLanding);
    if (ms) setMtcState(ms as MtcStateLanding);
  }, [actor]);

  useEffect(() => {
    pollData();
    const id = setInterval(pollData, 3000);
    return () => clearInterval(id);
  }, [pollData]);

  const live = feeds?.liveDataActive ?? false;
  const regime = fullState?.regime ?? "";
  const formaCapital = fullState?.formaCapital ?? 0;
  const mtcPrice = mtcState?.price ?? 0;

  const revealProps = (delay = 0) => ({
    initial: { opacity: 0, y: 24 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true, margin: "-50px" },
    transition: { duration: 0.65, ease: "easeOut" as const, delay },
  });

  const handleAccessSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Open mailto with form data
    const subject = encodeURIComponent(
      `PARALLAX Access Request — ${accessForm.intent}`,
    );
    const body = encodeURIComponent(
      `Name: ${accessForm.name}\nEmail: ${accessForm.email}\nIntent: ${accessForm.intent}`,
    );
    window.location.href = `mailto:MedinaSITech@outlook.com?subject=${subject}&body=${body}`;
    setAccessSubmitted(true);
  };

  return (
    <div
      style={{
        background: "oklch(0.08 0.01 240)",
        minHeight: "100vh",
        overflowX: "hidden",
        color: "oklch(0.95 0.02 240)",
        fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
      }}
    >
      {/* ── SECTION 1: HERO ──────────────────────────────────────────────────────── */}
      <section
        style={{
          position: "relative",
          width: "100vw",
          height: "100vh",
          minHeight: 640,
          overflow: "hidden",
          display: "flex",
          flexDirection: "column" as const,
        }}
      >
        <QuantumFieldCanvas />
        {/* Gradient overlay */}
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, oklch(0.08 0.01 240 / 0.45) 0%, oklch(0.08 0.01 240 / 0.20) 40%, oklch(0.08 0.01 240 / 0.95) 100%)",
            zIndex: 1,
          }}
        />

        {/* Hero content: two-column layout */}
        <div
          style={{
            position: "relative",
            zIndex: 2,
            flex: 1,
            display: "flex",
            alignItems: "center",
            padding: "0 clamp(20px, 6vw, 100px)",
            maxWidth: 1380,
            margin: "0 auto",
            width: "100%",
            gap: "clamp(32px, 5vw, 80px)",
          }}
        >
          {/* Left column */}
          <div style={{ flex: "0 0 auto", maxWidth: 600 }}>
            {/* Live badge */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.55, delay: 0.1 }}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 8,
                border: "1px solid oklch(0.62 0.17 145 / 0.4)",
                padding: "5px 14px",
                marginBottom: 32,
                fontSize: 10,
                letterSpacing: "0.28em",
                color: "oklch(0.62 0.17 145)",
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
              }}
            >
              <span
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: "50%",
                  background: live
                    ? "oklch(0.62 0.17 145)"
                    : "oklch(0.78 0.18 85)",
                  display: "inline-block",
                  animation: "beat-pulse 2s ease-in-out infinite",
                }}
              />
              LIVE ON INTERNET COMPUTER
            </motion.div>

            {/* Wordmark */}
            <motion.h1
              initial={{ opacity: 0, y: 28 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{
                duration: 0.85,
                delay: 0.2,
                ease: "easeOut" as const,
              }}
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(64px, 10vw, 136px)",
                letterSpacing: "-0.02em",
                lineHeight: 1,
                color: "oklch(0.97 0.02 85)",
                margin: 0,
                marginBottom: 8,
                textShadow: "0 0 80px oklch(0.78 0.18 85 / 0.3)",
              }}
            >
              PARALLAX
            </motion.h1>

            {/* Tagline */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.35 }}
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: "clamp(10px, 1.3vw, 13px)",
                letterSpacing: "0.38em",
                color: "oklch(0.78 0.18 85 / 0.65)",
                textTransform: "uppercase" as const,
                marginBottom: 28,
              }}
            >
              THE SOVEREIGN EXCHANGE
            </motion.div>

            {/* Body */}
            <motion.p
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.45 }}
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: "clamp(12px, 1.5vw, 15px)",
                color: "oklch(0.60 0.04 270)",
                lineHeight: 1.75,
                margin: "0 0 36px",
                maxWidth: 480,
              }}
            >
              An intelligence engine that prices every trade.
              <br />
              Compounds every heartbeat.
              <br />
              Routes every dollar — without intermediaries.
            </motion.p>

            {/* CTA */}
            <motion.div
              initial={{ opacity: 0, scale: 0.94 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.55, delay: 0.58 }}
              style={{
                display: "flex",
                flexDirection: "column" as const,
                alignItems: "flex-start",
                gap: 12,
              }}
            >
              <EnterButton onClick={onEnterDashboard} size="lg" />
              <span
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 9,
                  color: "oklch(0.38 0.04 270)",
                  letterSpacing: "0.2em",
                }}
              >
                → ACCESS CONTROLLED· REQUEST BELOW
              </span>
            </motion.div>
          </div>

          {/* Right column: live mini-exchange widget (desktop only) */}
          <motion.div
            initial={{ opacity: 0, x: 24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.7, delay: 0.55 }}
            className="hidden lg:block"
            style={{
              flex: 1,
              maxWidth: 380,
              border: "1px solid rgba(255,255,255,0.07)",
              background: "rgba(0,0,0,0.55)",
              backdropFilter: "blur(12px)",
              padding: 20,
            }}
          >
            {/* Widget header */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 16,
              }}
            >
              <div>
                <div
                  style={{
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 11,
                    color: "oklch(0.78 0.18 85)",
                    fontWeight: 700,
                    letterSpacing: "0.15em",
                  }}
                >
                  MTC / ICP
                </div>
                <div
                  style={{
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 9,
                    color: "oklch(0.42 0.04 270)",
                    letterSpacing: "0.2em",
                    marginTop: 2,
                  }}
                >
                  SOVEREIGN PAIR
                </div>
              </div>
              <div
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 18,
                  fontWeight: 700,
                  color: "oklch(0.78 0.18 85)",
                  letterSpacing: "0.02em",
                }}
              >
                {mtcPrice > 0
                  ? mtcPrice.toLocaleString("en-US", {
                      minimumFractionDigits: 6,
                      maximumFractionDigits: 6,
                    })
                  : "———"}
              </div>
            </div>

            {/* Mini chart */}
            <div
              style={{
                border: "1px solid rgba(255,255,255,0.05)",
                background: "rgba(0,0,0,0.3)",
                marginBottom: 16,
                overflow: "hidden",
              }}
            >
              <MiniCandleChart price={mtcPrice} />
            </div>

            {/* Price row */}
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                marginBottom: 14,
                gap: 8,
              }}
            >
              {[
                {
                  label: "BTC",
                  value: feeds?.btcPrice ? `$${fmtPrice(feeds.btcPrice)}` : "—",
                },
                {
                  label: "ETH",
                  value: feeds?.ethPrice ? `$${fmtPrice(feeds.ethPrice)}` : "—",
                },
                {
                  label: "ICP",
                  value: feeds?.icpPrice
                    ? `$${fmtPrice(feeds.icpPrice, 2)}`
                    : "—",
                },
              ].map((item) => (
                <div key={item.label} style={{ textAlign: "center" as const }}>
                  <div
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 8,
                      color: "oklch(0.42 0.04 270)",
                      letterSpacing: "0.2em",
                    }}
                  >
                    {item.label}
                  </div>
                  <div
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 11,
                      color: "oklch(0.78 0.18 85)",
                      fontWeight: 700,
                      marginTop: 2,
                    }}
                  >
                    {item.value}
                  </div>
                </div>
              ))}
            </div>

            {/* Regime badge */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <span
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 9,
                  color: "oklch(0.42 0.04 270)",
                  letterSpacing: "0.2em",
                }}
              >
                REGIME
              </span>
              <span
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 10,
                  fontWeight: 700,
                  letterSpacing: "0.25em",
                  padding: "3px 10px",
                  border: `1px solid ${regime === "BULL" ? "rgba(74,170,106,0.5)" : regime === "BEAR" ? "rgba(204,68,68,0.5)" : "rgba(200,160,60,0.5)"}`,
                  color:
                    regime === "BULL"
                      ? "oklch(0.62 0.17 145)"
                      : regime === "BEAR"
                        ? "oklch(0.55 0.22 25)"
                        : "oklch(0.75 0.18 62)",
                  background:
                    regime === "BULL"
                      ? "rgba(74,170,106,0.08)"
                      : regime === "BEAR"
                        ? "rgba(204,68,68,0.08)"
                        : "rgba(200,160,60,0.08)",
                }}
              >
                {regime || "TRANSITION"}
              </span>
            </div>
          </motion.div>
        </div>

        {/* Scroll indicator */}
        <div
          style={{
            position: "absolute",
            bottom: 28,
            left: "50%",
            transform: "translateX(-50%)",
            zIndex: 2,
            display: "flex",
            flexDirection: "column" as const,
            alignItems: "center",
            gap: 5,
          }}
        >
          <span
            style={{
              fontSize: 8,
              letterSpacing: "0.3em",
              color: "oklch(0.78 0.18 85 / 0.35)",
              fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
            }}
          >
            SCROLL
          </span>
          <div
            style={{
              width: 1,
              height: 26,
              background: "oklch(0.78 0.18 85 / 0.3)",
            }}
          />
        </div>
      </section>

      {/* ── SECTION 2: LIVE PROOF STRIP ───────────────────────────────────────────── */}
      <LiveProofStrip
        brain={brain}
        fullState={fullState}
        regime={regime}
        formaCapital={formaCapital}
      />

      {/* ── SECTION 3: WHAT IS PARALLAX ──────────────────────────────────────────── */}
      <section
        style={{
          padding: "100px clamp(20px, 6vw, 100px)",
          background: "oklch(0.10 0.01 240)",
        }}
      >
        <div
          style={{
            maxWidth: 1280,
            margin: "0 auto",
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: "clamp(32px, 5vw, 80px)",
            alignItems: "start",
          }}
          className="grid-cols-1 md:grid-cols-2"
        >
          {/* Left: headline */}
          <motion.div {...revealProps()}>
            <h2
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(28px, 4vw, 48px)",
                lineHeight: 1.1,
                color: "oklch(0.97 0.02 85)",
                margin: "0 0 24px",
                letterSpacing: "-0.01em",
              }}
            >
              Not an exchange.
              <br />A sovereign intelligence.
            </h2>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: "clamp(12px, 1.4vw, 14px)",
                color: "oklch(0.52 0.04 270)",
                lineHeight: 1.85,
                margin: 0,
              }}
            >
              Other exchanges match orders. PARALLAX prices every trade from
              live market intelligence — Bitcoin, Ethereum, ICP feeding a
              pricing engine that reads the market in real time, every 3
              seconds.
            </p>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: "clamp(13px, 1.4vw, 14px)",
                color: "oklch(0.52 0.04 270)",
                lineHeight: 1.9,
                margin: "16px 0 0",
              }}
            >
              The intelligence layer is not a formula with fixed parameters. It
              reads live macro signals from four blockchain networks,
              incorporates a sovereignty score derived from the organism's own
              cognitive state, and uses all of it to set spread width, liquidity
              depth, and token mint eligibility — dynamically, without human
              intervention.
            </p>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: "clamp(13px, 1.4vw, 14px)",
                color: "oklch(0.52 0.04 270)",
                lineHeight: 1.9,
                margin: "16px 0 0",
              }}
            >
              This is not a platform built on top of a blockchain. It is a
              living financial organism running inside one — compounding every
              heartbeat, routing every dollar, and defending its own sovereignty
              without any external dependency.
            </p>
          </motion.div>

          {/* Right: 3 capability cards */}
          <div
            style={{
              display: "flex",
              flexDirection: "column" as const,
              gap: 2,
            }}
          >
            {[
              {
                icon: "◈",
                title: "Intelligence-Priced Liquidity",
                body: "Every spread is priced from a live intelligence score — Bitcoin, Ethereum, and ICP price feeds combine with internal coherence signals to set bid/ask depth dynamically. There are no static fee tables. There are no third-party price oracles. The organism is the oracle. When the market is coherent and trending, spreads tighten. When volatility spikes, the engine adapts in real time — automatically, every heartbeat.",
                delay: 0.1,
              },
              {
                icon: "⊕",
                title: "Autonomous Revenue Routing",
                body: "Most exchanges extract fees and hold them idle. PARALLAX routes every dollar of revenue back into a compounding capital engine. This engine compounds on a mathematical schedule every heartbeat — approximately every 3 seconds. After 1,000 consecutive beats at high compliance, the compound rate steps up by 10%. After 4,000 beats, it reaches maximum sovereign velocity at 1.5×. The exchange doesn't just earn. It compounds what it earns, forever.",
                delay: 0.2,
              },
              {
                icon: "ƒ",
                title: "Multi-Chain Native",
                body: "Pricing intelligence is sourced directly from Bitcoin, Ethereum, Solana, and ICP price feeds — all four chains feeding the engine simultaneously via on-chain outcalls. No bridges. No wrapped tokens. No counterparty intermediaries. The organism reads the world in real time and incorporates live macro signals into every pricing decision. Sovereign market access without sovereign risk.",
                delay: 0.3,
              },
            ].map((card) => (
              <motion.div
                key={card.title}
                {...revealProps(card.delay)}
                style={{
                  display: "flex",
                  gap: 18,
                  alignItems: "flex-start",
                  background: "rgba(255,255,255,0.02)",
                  border: "1px solid rgba(255,255,255,0.04)",
                  borderLeft: "2px solid oklch(0.78 0.18 85 / 0.4)",
                  padding: "28px 24px 28px 22px",
                }}
              >
                <span
                  style={{
                    fontSize: 22,
                    color: "oklch(0.78 0.18 85)",
                    fontFamily: "monospace",
                    flexShrink: 0,
                    lineHeight: 1.2,
                    marginTop: 2,
                  }}
                >
                  {card.icon}
                </span>
                <div>
                  <div
                    style={{
                      fontFamily:
                        "'Bricolage Grotesque', 'Satoshi', sans-serif",
                      fontWeight: 700,
                      fontSize: "clamp(14px, 1.3vw, 16px)",
                      color: "oklch(0.95 0.03 85)",
                      marginBottom: 10,
                    }}
                  >
                    {card.title}
                  </div>
                  <p
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 13,
                      color: "oklch(0.52 0.04 270)",
                      lineHeight: 1.9,
                      margin: 0,
                    }}
                  >
                    {card.body}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── SECTION 4: THE EXCHANGE DIFFERENCE ───────────────────────────────────── */}
      <section
        style={{
          padding: "100px clamp(20px, 6vw, 100px)",
          background: "oklch(0.05 0.01 270)",
        }}
      >
        <div style={{ maxWidth: 1280, margin: "0 auto" }}>
          <motion.div
            {...revealProps()}
            style={{ textAlign: "center" as const, marginBottom: 56 }}
          >
            <h2
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(28px, 4vw, 44px)",
                letterSpacing: "-0.01em",
                color: "oklch(0.97 0.02 85)",
                margin: "0 0 12px",
              }}
            >
              WHY PARALLAX
            </h2>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 11,
                letterSpacing: "0.22em",
                color: "oklch(0.42 0.04 270)",
              }}
            >
              COMPARE WHAT YOU’RE CHOOSING.
            </p>
          </motion.div>

          {/* Three-column comparison */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1.1fr 1fr",
              gap: 2,
            }}
            className="grid-cols-1 md:grid-cols-3"
          >
            {/* Standard Exchange (muted) */}
            <motion.div
              {...revealProps(0)}
              style={{
                background: "rgba(255,255,255,0.02)",
                border: "1px solid rgba(255,255,255,0.04)",
                borderTop: "2px solid rgba(255,255,255,0.08)",
                padding: "32px 28px",
                opacity: 0.65,
              }}
            >
              <div
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 9,
                  letterSpacing: "0.28em",
                  color: "oklch(0.42 0.04 270)",
                  marginBottom: 20,
                }}
              >
                STANDARD EXCHANGE
              </div>
              {[
                "Order matching engine",
                "Third-party price feeds",
                "Manual fee routing",
                "Static spreads",
                "Infrastructure risk",
              ].map((item) => (
                <div
                  key={item}
                  style={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: 10,
                    marginBottom: 12,
                  }}
                >
                  <span
                    style={{
                      color: "rgba(255,255,255,0.2)",
                      fontSize: 12,
                      flexShrink: 0,
                    }}
                  >
                    –
                  </span>
                  <span
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 11,
                      color: "oklch(0.40 0.04 270)",
                      lineHeight: 1.5,
                    }}
                  >
                    {item}
                  </span>
                </div>
              ))}
            </motion.div>

            {/* PARALLAX (elevated) */}
            <motion.div
              {...revealProps(0.1)}
              style={{
                background: "rgba(200,160,60,0.04)",
                border: "1px solid rgba(200,160,60,0.18)",
                borderTop: "2px solid oklch(0.78 0.18 85)",
                padding: "32px 28px",
                boxShadow: "0 0 60px oklch(0.78 0.18 85 / 0.06)",
                position: "relative" as const,
              }}
            >
              <div
                style={{
                  fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                  fontWeight: 800,
                  fontSize: 13,
                  letterSpacing: "0.32em",
                  color: "oklch(0.78 0.18 85)",
                  textAlign: "center" as const,
                  marginBottom: 20,
                  textShadow: "0 0 20px oklch(0.78 0.18 85 / 0.4)",
                }}
              >
                PARALLAX
              </div>
              {[
                "Intelligence-priced liquidity",
                "Sovereign market making",
                "Autonomous revenue routing",
                "Adaptive spreads",
                "Always compounding",
              ].map((item) => (
                <div
                  key={item}
                  style={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: 10,
                    marginBottom: 12,
                  }}
                >
                  <span
                    style={{
                      color: "oklch(0.78 0.18 85)",
                      fontSize: 12,
                      flexShrink: 0,
                    }}
                  >
                    ▸
                  </span>
                  <span
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 11,
                      color: "oklch(0.85 0.03 85)",
                      lineHeight: 1.5,
                      fontWeight: 500,
                    }}
                  >
                    {item}
                  </span>
                </div>
              ))}
            </motion.div>

            {/* DeFi AMM (muted) */}
            <motion.div
              {...revealProps(0.2)}
              style={{
                background: "rgba(255,255,255,0.02)",
                border: "1px solid rgba(255,255,255,0.04)",
                borderTop: "2px solid rgba(255,255,255,0.08)",
                padding: "32px 28px",
                opacity: 0.65,
              }}
            >
              <div
                style={{
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 9,
                  letterSpacing: "0.28em",
                  color: "oklch(0.42 0.04 270)",
                  marginBottom: 20,
                }}
              >
                DEFI AMM
              </div>
              {[
                "Impermanent loss risk",
                "Liquidity fragmentation",
                "Gas dependency",
                "Bot arbitrage exposure",
                "Protocol risk",
              ].map((item) => (
                <div
                  key={item}
                  style={{
                    display: "flex",
                    alignItems: "flex-start",
                    gap: 10,
                    marginBottom: 12,
                  }}
                >
                  <span
                    style={{
                      color: "rgba(255,255,255,0.2)",
                      fontSize: 12,
                      flexShrink: 0,
                    }}
                  >
                    –
                  </span>
                  <span
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 11,
                      color: "oklch(0.40 0.04 270)",
                      lineHeight: 1.5,
                    }}
                  >
                    {item}
                  </span>
                </div>
              ))}
            </motion.div>
          </div>

          {/* HOW IT WORKS — 4 always-expanded explanation blocks */}
          <motion.div {...revealProps(0.3)} style={{ marginTop: 72 }}>
            <div
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 9,
                letterSpacing: "0.38em",
                color: "oklch(0.42 0.04 270)",
                textAlign: "center" as const,
                marginBottom: 8,
              }}
            >
              UNDER THE SURFACE
            </div>
            <h3
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(22px, 3vw, 34px)",
                letterSpacing: "-0.01em",
                color: "oklch(0.97 0.02 85)",
                textAlign: "center" as const,
                margin: "0 0 48px",
              }}
            >
              HOW IT WORKS
            </h3>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(2, 1fr)",
                gap: 2,
              }}
              className="grid-cols-1 md:grid-cols-2"
            >
              {[
                {
                  heading: "The Intelligence Engine",
                  body: "The pricing engine is not a formula with fixed parameters. It reads 4 live market feeds, 26 phase-coupled brain nodes, and a compliance score every 3 seconds. These signals combine into a single coherence measure that directly determines spread width, liquidity depth, and token mint eligibility. When the organism is in high coherence, the exchange is at maximum efficiency. When coherence drops, the engine automatically reduces exposure — no human required.",
                  accent: "oklch(0.78 0.18 85)",
                },
                {
                  heading: "Compounding Capital",
                  body: "Unlike exchanges that hold reserves in static wallets, PARALLAX runs a sovereign capital engine that starts at a genesis floor and compounds mathematically every heartbeat using a multi-factor rate that includes market signals, a temporal dilation factor, a 5-rung compliance ladder, and a momentum signal. No human triggers the compounding. No governance vote is required. The math runs itself — every 3 seconds, without interruption.",
                  accent: "oklch(0.72 0.15 200)",
                },
                {
                  heading: "The Sovereign Token Ecosystem",
                  body: "The 12 tokens are not arbitrary. Each tier serves a different function in the sovereign capital stack. GENESIS tier tokens are the foundational layer — they gate the economy and determine creator reserve flow. VELOCITY tier tokens are the exchange medium — they carry trade velocity and route profit signals. FOUNDATION tier tokens provide the substrate that keeps the organism running: reserves, heritage, dreams, resonance, emergence, and legacy. All are ICP-native ICRC-1 tokens.",
                  accent: "oklch(0.78 0.18 85)",
                },
                {
                  heading: "Autonomous Defense",
                  body: "The exchange runs a layered immune system. The primary immune reflex fires pre-consciously — before the sovereign layer even registers a threat. The perimeter detection system maps attack vectors across 6 axes simultaneously, rotating continuously with no blind spot. The consequence tracer assigns permanent compounding penalty to every adversarial source — the same source gets harder to interface with on every subsequent attempt. The output monitor watches every data path for deviation. The exchange cannot be replicated, front-run by a flagged adversary, or manipulated at the pattern level.",
                  accent: "oklch(0.72 0.15 200)",
                },
              ].map((block, i) => (
                <motion.div
                  key={block.heading}
                  {...revealProps(i * 0.08)}
                  style={{
                    background: "rgba(255,255,255,0.018)",
                    border: "1px solid rgba(255,255,255,0.06)",
                    borderTop: `2px solid ${block.accent}`,
                    padding: "32px 28px",
                  }}
                >
                  <div
                    style={{
                      fontFamily:
                        "'Bricolage Grotesque', 'Satoshi', sans-serif",
                      fontWeight: 700,
                      fontSize: "clamp(15px, 1.5vw, 18px)",
                      color: "oklch(0.95 0.03 85)",
                      marginBottom: 14,
                      letterSpacing: "-0.005em",
                    }}
                  >
                    {block.heading}
                  </div>
                  <p
                    style={{
                      fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                      fontSize: 13,
                      color: "oklch(0.52 0.04 270)",
                      lineHeight: 1.9,
                      margin: 0,
                    }}
                  >
                    {block.body}
                  </p>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* ── SECTION 5: ASSET UNIVERSE ───────────────────────────────────────────────── */}
      <section
        style={{
          padding: "100px clamp(20px, 6vw, 100px)",
          background: "oklch(0.10 0.01 240)",
        }}
      >
        <div style={{ maxWidth: 1280, margin: "0 auto" }}>
          <motion.div
            {...revealProps()}
            style={{ textAlign: "center" as const, marginBottom: 48 }}
          >
            <h2
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(28px, 4vw, 44px)",
                letterSpacing: "-0.01em",
                color: "oklch(0.97 0.02 85)",
                margin: "0 0 12px",
              }}
            >
              ASSET UNIVERSE
            </h2>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 12,
                letterSpacing: "0.22em",
                color: "oklch(0.42 0.04 270)",
                marginBottom: 12,
              }}
            >
              12 SOVEREIGN TOKENS. 3 TIERS. ALL ICP-NATIVE.
            </p>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 13,
                color: "oklch(0.48 0.04 270)",
                lineHeight: 1.9,
                maxWidth: 680,
                margin: "0 auto",
              }}
            >
              Each token has a specific role in the sovereign capital stack.
              Genesis tier tokens gate the economy. Velocity tier tokens carry
              trade momentum. Foundation tier tokens sustain the organism's
              cognitive and temporal substrate. All 12 are ICP-native ICRC-1
              tokens — no bridges, no wrappers, no external dependency.
            </p>
          </motion.div>

          {/* GENESIS TIER */}
          <motion.div {...revealProps(0.1)} style={{ marginBottom: 40 }}>
            <div
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 9,
                letterSpacing: "0.3em",
                color: "oklch(0.78 0.18 85 / 0.6)",
                marginBottom: 14,
              }}
            >
              GENESIS TIER
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, 1fr)",
                gap: 8,
              }}
            >
              {["GTK", "MTH", "MRC"].map((sym, i) => (
                <TokenCard key={sym} symbol={sym} tier="gold" index={i} />
              ))}
            </div>
          </motion.div>

          {/* VELOCITY TIER */}
          <motion.div {...revealProps(0.15)} style={{ marginBottom: 40 }}>
            <div
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 9,
                letterSpacing: "0.3em",
                color: "oklch(0.72 0.15 200 / 0.6)",
                marginBottom: 14,
              }}
            >
              VELOCITY TIER
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, 1fr)",
                gap: 8,
              }}
            >
              {["CVT", "VCT", "KNT"].map((sym, i) => (
                <TokenCard key={sym} symbol={sym} tier="cyan" index={i + 3} />
              ))}
            </div>
          </motion.div>

          {/* FOUNDATION TIER */}
          <motion.div {...revealProps(0.2)}>
            <div
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 9,
                letterSpacing: "0.3em",
                color: "rgba(255,255,255,0.25)",
                marginBottom: 12,
              }}
            >
              FOUNDATION TIER
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, 1fr)",
                gap: 8,
              }}
            >
              {["SBT", "HBT", "DRT", "RST", "OMT", "LGT"].map((sym, i) => (
                <TokenCard key={sym} symbol={sym} tier="base" index={i + 6} />
              ))}
            </div>
          </motion.div>
        </div>
      </section>

      {/* ── SECTION 6: REQUEST ACCESS ──────────────────────────────────────────────── */}
      <section
        id="request-access"
        style={{
          padding: "100px clamp(20px, 6vw, 100px)",
          background: "oklch(0.04 0.01 270)",
        }}
      >
        <div
          style={{
            maxWidth: 520,
            margin: "0 auto",
            textAlign: "center" as const,
          }}
        >
          <motion.div {...revealProps()}>
            <h2
              style={{
                fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
                fontWeight: 800,
                fontSize: "clamp(28px, 4vw, 44px)",
                letterSpacing: "-0.01em",
                color: "oklch(0.97 0.02 85)",
                margin: "0 0 12px",
              }}
            >
              REQUEST ACCESS
            </h2>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 12,
                color: "oklch(0.42 0.04 270)",
                letterSpacing: "0.15em",
                marginBottom: 28,
              }}
            >
              PARALLAX IS IN SOVEREIGN PILOT. ACCESS IS BY INVITATION.
            </p>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 13,
                color: "oklch(0.52 0.04 270)",
                lineHeight: 1.9,
                marginBottom: 12,
                textAlign: "left" as const,
              }}
            >
              PARALLAX is currently in sovereign pilot — the first live instance
              of an intelligence-priced exchange engine on the Internet
              Computer. The organism is running now, compounding every
              heartbeat, pricing every trade from live market intelligence.
            </p>
            <p
              style={{
                fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                fontSize: 13,
                color: "oklch(0.52 0.04 270)",
                lineHeight: 1.9,
                marginBottom: 32,
                textAlign: "left" as const,
              }}
            >
              Access tiers are: Operator (full dashboard, all controls, requires
              authentication), Market (exchange trading interface, enabled in
              public phase), and Council (reserved). During the pilot phase, all
              access requests are reviewed personally by the creator. Use the
              form below to introduce yourself and state your intent.
            </p>

            {accessSubmitted ? (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                style={{
                  border: "1px solid oklch(0.62 0.17 145 / 0.4)",
                  background: "oklch(0.62 0.17 145 / 0.06)",
                  padding: "32px",
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 13,
                  letterSpacing: "0.15em",
                  color: "oklch(0.62 0.17 145)",
                }}
                data-ocid="landing.access.success_state"
              >
                REQUEST RECEIVED. YOU WILL BE CONTACTED.
              </motion.div>
            ) : (
              <form
                onSubmit={handleAccessSubmit}
                style={{
                  display: "flex",
                  flexDirection: "column" as const,
                  gap: 12,
                }}
                data-ocid="landing.access.modal"
              >
                <input
                  type="text"
                  placeholder="YOUR NAME"
                  value={accessForm.name}
                  onChange={(e) =>
                    setAccessForm((f) => ({ ...f, name: e.target.value }))
                  }
                  required
                  data-ocid="landing.access.input"
                  style={{
                    background: "transparent",
                    border: "1px solid rgba(255,255,255,0.1)",
                    padding: "14px 16px",
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 12,
                    color: "oklch(0.92 0.02 270)",
                    letterSpacing: "0.15em",
                    outline: "none",
                    width: "100%",
                    boxSizing: "border-box" as const,
                    transition: "border-color 0.2s",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "oklch(0.78 0.18 85 / 0.5)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "rgba(255,255,255,0.1)";
                  }}
                />
                <input
                  type="email"
                  placeholder="YOUR EMAIL"
                  value={accessForm.email}
                  onChange={(e) =>
                    setAccessForm((f) => ({ ...f, email: e.target.value }))
                  }
                  required
                  data-ocid="landing.access.input"
                  style={{
                    background: "transparent",
                    border: "1px solid rgba(255,255,255,0.1)",
                    padding: "14px 16px",
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 12,
                    color: "oklch(0.92 0.02 270)",
                    letterSpacing: "0.15em",
                    outline: "none",
                    width: "100%",
                    boxSizing: "border-box" as const,
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "oklch(0.78 0.18 85 / 0.5)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "rgba(255,255,255,0.1)";
                  }}
                />
                <select
                  value={accessForm.intent}
                  onChange={(e) =>
                    setAccessForm((f) => ({ ...f, intent: e.target.value }))
                  }
                  data-ocid="landing.access.select"
                  style={{
                    background: "oklch(0.06 0.01 270)",
                    border: "1px solid rgba(255,255,255,0.1)",
                    padding: "14px 16px",
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 12,
                    color: "oklch(0.92 0.02 270)",
                    letterSpacing: "0.15em",
                    outline: "none",
                    width: "100%",
                    boxSizing: "border-box" as const,
                    cursor: "pointer",
                  }}
                >
                  {["Trading", "Institutional", "Integration", "Research"].map(
                    (o) => (
                      <option key={o} value={o}>
                        {o.toUpperCase()}
                      </option>
                    ),
                  )}
                </select>
                <button
                  type="submit"
                  data-ocid="landing.access.submit_button"
                  style={{
                    background: "transparent",
                    border: "1px solid oklch(0.78 0.18 85 / 0.6)",
                    padding: "16px",
                    fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                    fontSize: 11,
                    letterSpacing: "0.32em",
                    color: "oklch(0.78 0.18 85)",
                    cursor: "pointer",
                    width: "100%",
                    transition: "all 0.2s",
                    textTransform: "uppercase" as const,
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.background =
                      "oklch(0.78 0.18 85 / 0.08)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.background = "transparent";
                  }}
                >
                  REQUEST ACCESS
                </button>
              </form>
            )}

            <div style={{ marginTop: 28 }}>
              <button
                type="button"
                onClick={onEnterDashboard}
                data-ocid="landing.enter.link"
                style={{
                  background: "transparent",
                  border: "none",
                  fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
                  fontSize: 10,
                  color: "oklch(0.45 0.04 270)",
                  letterSpacing: "0.2em",
                  cursor: "pointer",
                  transition: "color 0.2s",
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.color = "oklch(0.78 0.18 85)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.color = "oklch(0.45 0.04 270)";
                }}
              >
                Already have access? → ENTER THE EXCHANGE
              </button>
            </div>
          </motion.div>
        </div>
      </section>

      {/* ── SECTION 7: FOOTER ──────────────────────────────────────────────────────────── */}
      <footer
        style={{
          background: "oklch(0.04 0.01 270)",
          borderTop: "1px solid oklch(0.78 0.18 85 / 0.1)",
          padding: "28px clamp(20px, 6vw, 80px)",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap" as const,
          gap: 20,
        }}
      >
        {/* Wordmark */}
        <div
          style={{
            fontFamily: "'Bricolage Grotesque', 'Satoshi', sans-serif",
            fontWeight: 800,
            fontSize: 18,
            letterSpacing: "-0.01em",
            color: "oklch(0.78 0.18 85 / 0.65)",
          }}
        >
          PARALLAX
        </div>

        {/* Live indicator */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
            fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
            fontSize: 10,
            letterSpacing: "0.28em",
            color: "oklch(0.78 0.18 85)",
          }}
        >
          <span
            style={{
              width: 6,
              height: 6,
              borderRadius: "50%",
              background: live ? "oklch(0.62 0.17 145)" : "oklch(0.78 0.18 85)",
              display: "inline-block",
              animation: "beat-pulse 2s ease-in-out infinite",
            }}
          />
          THE EXCHANGE IS LIVE
        </div>

        <EnterButton onClick={onEnterDashboard} size="sm" />
      </footer>

      {/* Attribution */}
      <div
        style={{
          background: "oklch(0.04 0.01 270)",
          borderTop: "1px solid rgba(255,255,255,0.03)",
          padding: "14px clamp(20px, 6vw, 80px)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap" as const,
          gap: 8,
        }}
      >
        <span
          style={{
            fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
            fontSize: 9,
            letterSpacing: "0.2em",
            color: "oklch(0.28 0.03 270)",
          }}
        >
          ALFREDO MEDINA HERNANDEZ · DALLAS, TEXAS · {new Date().getFullYear()}
        </span>
        <span
          style={{
            fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
            fontSize: 9,
            color: "oklch(0.28 0.03 270)",
          }}
        >
          © {new Date().getFullYear()} ·{" "}
          <a
            href={`https://caffeine.ai?utm_source=caffeine-footer&utm_medium=referral&utm_content=${encodeURIComponent(window.location.hostname)}`}
            target="_blank"
            rel="noopener noreferrer"
            style={{ color: "inherit", textDecoration: "none" }}
            onMouseEnter={(e) => {
              (e.target as HTMLAnchorElement).style.color =
                "oklch(0.45 0.04 270)";
            }}
            onMouseLeave={(e) => {
              (e.target as HTMLAnchorElement).style.color =
                "oklch(0.28 0.03 270)";
            }}
          >
            Built with love using caffeine.ai
          </a>
        </span>
      </div>
    </div>
  );
}

// ── Token Card sub-component ────────────────────────────────────────────────────────────
const TOKEN_META: Record<string, { name: string; desc: string }> = {
  GTK: {
    name: "Genesis Token",
    desc: "The founding value store. GTK mints when coherence and compliance cross the sovereign threshold, gating the entire economy. Its issuance is the organism's most fundamental signal of health.",
  },
  MTH: {
    name: "Methuselah",
    desc: "The heritage reserve. Capped at 100 million units, forever. MTH is the organism's long-term store of sovereign value — it does not inflate, and it does not decay.",
  },
  MRC: {
    name: "Meridian Creator Reserve",
    desc: "Mints first, before all others. MRC routes directly to the creator on every qualifying cycle. It is the organism's primary creator value channel and the first token the economy serves.",
  },
  CVT: {
    name: "Conversion Token",
    desc: "The exchange medium. CVT routes trade velocity signals through the sovereign pricing engine, carrying the conversion layer between sovereign and external value flows.",
  },
  VCT: {
    name: "Velocity Token",
    desc: "Measures and carries the organism's economic momentum. VCT signals when the system is in forward compounding — its mint rate is a direct readout of how fast the engine is accelerating.",
  },
  KNT: {
    name: "Kinetic Token",
    desc: "Kinetic energy of the sovereign field. KNT fires when drive competition inside the organism produces a winning behavior output — it is the token of decisive action.",
  },
  SBT: {
    name: "Substrate Token",
    desc: "The cognitive substrate reserve. SBT supports the core identity circuit and its 12 foundational nodes, ensuring the organism's base layer never runs below minimum capacity.",
  },
  HBT: {
    name: "Heritage Token",
    desc: "Anchors the organism's 7 heritage nodes, compounding toward sovereign identity on every beat. HBT is the living memory of the organism's own history.",
  },
  DRT: {
    name: "Dream Reserve Token",
    desc: "Minted at every JUBILEE cycle — every 1,000 beats, approximately once per hour. DRT represents the organism's consolidated memory state after each dream cycle completes.",
  },
  RST: {
    name: "Resonance Token",
    desc: "Fires from the cross-shell synchrony operator. RST measures cross-shell coupling and heritage integration — it mints when the organism's layers are in resonance with each other.",
  },
  OMT: {
    name: "OMNIS Token",
    desc: "The rarest mint. OMT fires only when emergence, coherence, and identity all cross sovereign threshold simultaneously — a convergence event that may happen once every millions of beats.",
  },
  LGT: {
    name: "Legacy Token",
    desc: "The long-horizon store. LGT feeds the heritage compounding chain and the organism's deep temporal memory, carrying value forward across the full arc of the organism's lifespan.",
  },
};

function TokenCard({
  symbol,
  tier,
  index,
}: { symbol: string; tier: "gold" | "cyan" | "base"; index: number }) {
  const tierColor =
    tier === "gold"
      ? "oklch(0.78 0.18 85)"
      : tier === "cyan"
        ? "oklch(0.72 0.15 200)"
        : "rgba(255,255,255,0.28)";
  const tierLabel =
    tier === "gold"
      ? "GENESIS TIER"
      : tier === "cyan"
        ? "VELOCITY TIER"
        : "FOUNDATION TIER";
  const tierBorderColor =
    tier === "gold"
      ? "rgba(200,160,60,0.3)"
      : tier === "cyan"
        ? "rgba(100,180,220,0.25)"
        : "rgba(255,255,255,0.07)";

  const meta = TOKEN_META[symbol];

  return (
    <div
      data-ocid={`landing.token.item.${index + 1}`}
      style={{
        background: "rgba(255,255,255,0.02)",
        border: `1px solid ${tierBorderColor}`,
        borderTop: `2px solid ${tierColor}`,
        padding: "22px 20px 20px",
        display: "flex",
        flexDirection: "column" as const,
        gap: 10,
      }}
    >
      {/* Header row: symbol + status */}
      <div
        style={{
          display: "flex",
          alignItems: "flex-start",
          justifyContent: "space-between",
        }}
      >
        <div>
          <div
            style={{
              fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
              fontWeight: 700,
              fontSize: 18,
              color: tierColor,
              letterSpacing: "0.06em",
              lineHeight: 1,
              marginBottom: 4,
            }}
          >
            {symbol}
          </div>
          <div
            style={{
              fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
              fontSize: 9,
              letterSpacing: "0.18em",
              color: "oklch(0.55 0.04 270)",
              lineHeight: 1,
            }}
          >
            {meta?.name ?? tierLabel}
          </div>
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 5,
            paddingTop: 2,
          }}
        >
          <span
            style={{
              width: 6,
              height: 6,
              borderRadius: "50%",
              background: "oklch(0.62 0.17 145)",
              display: "inline-block",
              boxShadow: "0 0 6px oklch(0.62 0.17 145 / 0.6)",
              flexShrink: 0,
            }}
          />
          <span
            style={{
              fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
              fontSize: 8,
              color: "oklch(0.62 0.17 145)",
              letterSpacing: "0.2em",
            }}
          >
            ACTIVE
          </span>
        </div>
      </div>

      {/* Description */}
      {meta && (
        <p
          style={{
            fontFamily: "'JetBrains Mono', 'Satoshi', monospace",
            fontSize: 12,
            color: "oklch(0.48 0.04 270)",
            lineHeight: 1.85,
            margin: 0,
            borderTop: `1px solid ${tier === "gold" ? "rgba(200,160,60,0.12)" : tier === "cyan" ? "rgba(100,180,220,0.1)" : "rgba(255,255,255,0.04)"}`,
            paddingTop: 10,
          }}
        >
          {meta.desc}
        </p>
      )}
    </div>
  );
}
