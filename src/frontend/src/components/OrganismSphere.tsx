import { useEffect, useRef } from "react";
import type { ParallaxData } from "../hooks/useParallax";

interface Props {
  data: ParallaxData;
}

const TIER_COLORS: Record<string, string> = {
  CHAMPION: "#D6B36A",
  HEAVYWEIGHT: "#B23A3E",
  MIDDLEWEIGHT: "#D7B24A",
  LIGHTWEIGHT: "#6F7580",
};

const DEFAULT_ORGANISMS = [
  {
    id: 1,
    name: "PARALLAX-PRIME",
    tier: "CHAMPION",
    status: "EARNING",
    totalEarned: 0,
    yieldMultiplier: 2.0,
  },
  {
    id: 2,
    name: "NOVA-7",
    tier: "HEAVYWEIGHT",
    status: "EARNING",
    totalEarned: 0,
    yieldMultiplier: 1.5,
  },
  {
    id: 3,
    name: "SIGNAL-ECHO",
    tier: "MIDDLEWEIGHT",
    status: "ACTIVE",
    totalEarned: 0,
    yieldMultiplier: 1.25,
  },
  {
    id: 4,
    name: "VECTOR-ALPHA",
    tier: "LIGHTWEIGHT",
    status: "ACTIVE",
    totalEarned: 0,
    yieldMultiplier: 1.0,
  },
];

export function OrganismSphere({ data }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animRef = useRef<number>(0);

  const organisms =
    data.organisms.length > 0 ? data.organisms : DEFAULT_ORGANISMS;

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;
    const W = canvas.width;
    const H = canvas.height;
    const cx = W / 2;
    const cy = H / 2;
    const R = Math.min(W, H) * 0.32;

    const nodes = organisms.map((o, i) => {
      const angle = (i / organisms.length) * Math.PI * 2;
      return {
        ...o,
        baseAngle: angle,
        r: o.tier === "CHAMPION" ? 14 : o.tier === "HEAVYWEIGHT" ? 10 : 8,
      };
    });

    function draw(t: number) {
      if (!ctx) return;
      ctx.clearRect(0, 0, W, H);

      const positions = nodes.map((n, i) => {
        const a = n.baseAngle + t * 0.0003 * (i % 2 === 0 ? 1 : -0.7);
        const lift = n.tier === "CHAMPION" ? -30 : 0;
        return {
          x: cx + Math.cos(a) * R,
          y: cy + Math.sin(a) * R * 0.55 + lift,
          node: n,
        };
      });

      // Lines between nodes
      ctx.lineWidth = 0.5;
      for (let i = 0; i < positions.length; i++) {
        for (let j = i + 1; j < positions.length; j++) {
          const nodeA = positions[i];
          const nodeB = positions[j];
          if (!nodeA || !nodeB) continue;
          const grad = ctx.createLinearGradient(
            nodeA.x,
            nodeA.y,
            nodeB.x,
            nodeB.y,
          );
          grad.addColorStop(
            0,
            `${TIER_COLORS[nodeA.node.tier] ?? "#6F7580"}40`,
          );
          grad.addColorStop(
            1,
            `${TIER_COLORS[nodeB.node.tier] ?? "#6F7580"}40`,
          );
          ctx.strokeStyle = grad;
          ctx.beginPath();
          ctx.moveTo(nodeA.x, nodeA.y);
          ctx.lineTo(nodeB.x, nodeB.y);
          ctx.stroke();
        }
      }

      // Draw nodes
      for (const { x, y, node } of positions) {
        const color = TIER_COLORS[node.tier] ?? "#6F7580";
        const pulse = 1 + Math.sin(t * 0.003 + node.id) * 0.15;
        const r = node.r * pulse;

        const grd = ctx.createRadialGradient(x, y, 0, x, y, r * 3);
        grd.addColorStop(0, `${color}60`);
        grd.addColorStop(1, `${color}00`);
        ctx.fillStyle = grd;
        ctx.beginPath();
        ctx.arc(x, y, r * 3, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = "rgba(255,255,255,0.3)";
        ctx.beginPath();
        ctx.arc(x - r * 0.25, y - r * 0.25, r * 0.4, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = "#E7E9EE";
        ctx.font = `bold ${node.tier === "CHAMPION" ? 10 : 8}px monospace`;
        ctx.textAlign = "center";
        ctx.fillText(node.name, x, y + r + 14);

        ctx.fillStyle = node.status === "EARNING" ? "#44D17B" : "#9AA0AA";
        ctx.font = "7px monospace";
        ctx.fillText(node.status, x, y + r + 24);

        ctx.fillStyle = `${color}AA`;
        ctx.font = "7px monospace";
        ctx.fillText(node.tier, x, y - r - 6);
      }

      const champion = positions.find((p) => p.node.tier === "CHAMPION");
      if (champion) {
        ctx.fillStyle = "#D6B36A";
        ctx.font = "bold 12px monospace";
        ctx.textAlign = "center";
        ctx.fillText("♛", champion.x, champion.y - champion.node.r - 16);
      }

      animRef.current = requestAnimationFrame(draw);
    }

    animRef.current = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(animRef.current);
  }, [organisms]);

  const { treasury, creator, signals } = data;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          {
            label: "TOTAL PROFIT",
            value: `$${treasury.totalProfitAllStreams.toFixed(2)}`,
            accent: true,
          },
          {
            label: "CREATOR RESERVE",
            value: `${creator.icpReserve.toFixed(4)} ICP`,
            accent: true,
          },
          {
            label: "ENGINE IQ",
            value: `${(treasury.engineIntelligenceScore * 10).toFixed(2)}%`,
            accent: false,
          },
          {
            label: "COHERENCE",
            value: `${(treasury.systemCoherenceScore * 100).toFixed(1)}%`,
            accent: false,
          },
        ].map((s) => (
          <div
            key={s.label}
            className="bg-[#15161A] border border-[#2A2C33] p-3"
          >
            <div className="text-[9px] text-[#9AA0AA] tracking-widest mb-1">
              {s.label}
            </div>
            <div
              className={`font-mono text-sm font-bold ${s.accent ? "text-[#D6B36A]" : "text-[#E7E9EE]"}`}
            >
              {s.value}
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3 uppercase">
            VISUAL ORGANISM SPHERE
          </div>
          <canvas ref={canvasRef} className="w-full" style={{ height: 320 }} />
        </div>

        <div className="space-y-3">
          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              BRAIN SIGNALS
            </div>
            {[
              { label: "BTC", val: signals.btcSignal, color: "#D7B24A" },
              { label: "ETH", val: signals.ethSignal, color: "#6B7FDB" },
              { label: "ICP", val: signals.icpSignal, color: "#D6B36A" },
              {
                label: "MTC",
                val: signals.mtcVelocitySignal,
                color: "#44D17B",
              },
            ].map((s) => (
              <div key={s.label} className="mb-2">
                <div className="flex justify-between mb-1">
                  <span className="text-[9px] text-[#6F7580] tracking-widest">
                    {s.label} COHERENCE
                  </span>
                  <span
                    className="font-mono text-[9px]"
                    style={{ color: s.color }}
                  >
                    {(s.val * 100).toFixed(1)}%
                  </span>
                </div>
                <div className="h-0.5 bg-[#2A2C33] rounded">
                  <div
                    className="h-full rounded transition-all duration-500"
                    style={{
                      width: `${s.val * 100}%`,
                      backgroundColor: s.color,
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              CHAMPION POOL
            </div>
            <div className="font-mono text-lg font-bold text-[#D6B36A]">
              {treasury.championPool.toFixed(6)}
            </div>
            <div className="text-[9px] text-[#6F7580] mt-1">
              GROWS EVERY BEAT FROM FLOOR PROTECTION
            </div>
          </div>

          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              CREATOR SUPREMACY
            </div>
            <div className="space-y-1">
              <div className="font-mono text-[10px] text-[#D6B36A]">
                {data.attribution.name}
              </div>
              <div className="text-[9px] text-[#6F7580]">
                {data.attribution.title}
              </div>
              <div className="text-[9px] text-[#6F7580]">
                {data.attribution.jurisdiction}
              </div>
              <div className="mt-2 flex items-center gap-2">
                <div
                  className={`w-1.5 h-1.5 rounded-full ${data.attribution.genesisLocked ? "bg-[#44D17B]" : "bg-[#6F7580]"}`}
                />
                <span className="text-[9px] tracking-widest text-[#9AA0AA]">
                  {data.attribution.genesisLocked
                    ? "GENESIS LOCKED"
                    : "LOCKING..."}
                </span>
              </div>
              {data.attribution.doctrineHash > 0 && (
                <div className="font-mono text-[8px] text-[#6F7580] mt-1">
                  0x
                  {(data.attribution.doctrineHash >>> 0)
                    .toString(16)
                    .toUpperCase()
                    .padStart(8, "0")}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {data.thoughts.length > 0 && (
        <div className="bg-[#0D1A0F] border border-[#1A3A1F] p-4">
          <div className="text-[10px] text-[#44D17B]/70 tracking-widest mb-2">
            LAST ENGINE DECISION
          </div>
          <div className="font-mono text-[10px] text-[#44D17B]">
            [BEAT-{data.thoughts[0].beat}] {data.thoughts[0].decided} → YIELD: $
            {data.thoughts[0].yieldCaptured.toFixed(4)}
          </div>
          <div className="font-mono text-[9px] text-[#44D17B]/60 mt-1">
            {data.thoughts[0].watching}
          </div>
        </div>
      )}
    </div>
  );
}
