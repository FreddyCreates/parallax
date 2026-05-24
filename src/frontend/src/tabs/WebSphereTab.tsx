/**
 * WebSphereTab.tsx — WEBBED SPHERE NETWORKING
 * Interactive 3D webbed sphere visualization of the PARALLAX network topology.
 * Nodes on a golden-angle sphere, connected by web edges carrying custom token flows.
 *
 * Architecture:
 *   - Golden angle spiral distributes nodes on sphere (mirrors phi.mo A04)
 *   - Kuramoto R displayed for global sphere coherence (A06)
 *   - Nodes pulse with phase-coupled animation
 *   - Web connections arc between nodes with token-flow coloring
 *   - Custom token types annotate edges and nodes
 *   - Mouse drag rotates the sphere; click selects a node
 *
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { motion } from "motion/react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { GOLDEN_ANGLE, PHI_INV, S0 } from "../phi";

// ─── Custom Token Types (mirrors token_factory.mo / web_sphere.mo) ─────────

// Pre-computed golden angle in radians (avoids per-frame conversion)
const GOLDEN_ANGLE_RAD = (GOLDEN_ANGLE * Math.PI) / 180;

type CustomTokenType =
  | "aiCompute"
  | "aiMemory"
  | "aiInference"
  | "aiTraining"
  | "aiData"
  | "creatorPersonal"
  | "artifactBacked"
  | "governance"
  | "yield"
  | "utility"
  | "rewardPoints"
  | "fractionalNFT";

const TOKEN_COLORS: Record<CustomTokenType, string> = {
  aiCompute: "#6B9FDB",
  aiMemory: "#9B6BDB",
  aiInference: "#DB6B8F",
  aiTraining: "#DBA06B",
  aiData: "#6BDBA0",
  creatorPersonal: "#D6B36A",
  artifactBacked: "#DB6B6B",
  governance: "#6BDBDB",
  yield: "#44D17B",
  utility: "#9AA0AA",
  rewardPoints: "#D7B24A",
  fractionalNFT: "#B26BDB",
};

const TOKEN_LABELS: Record<CustomTokenType, string> = {
  aiCompute: "AI COMPUTE",
  aiMemory: "AI MEMORY",
  aiInference: "AI INFERENCE",
  aiTraining: "AI TRAINING",
  aiData: "AI DATA",
  creatorPersonal: "CREATOR",
  artifactBacked: "ARTIFACT",
  governance: "GOVERNANCE",
  yield: "YIELD",
  utility: "UTILITY",
  rewardPoints: "REWARDS",
  fractionalNFT: "FRAC-NFT",
};

// ─── Node Types ─────────────────────────────────────────────────────────────

type SphereNodeRole =
  | "sovereign"
  | "relay"
  | "compute"
  | "storage"
  | "gateway"
  | "validator"
  | "oracle"
  | "creator";

const ROLE_COLORS: Record<SphereNodeRole, string> = {
  sovereign: "#D6B36A",
  relay: "#6B9FDB",
  compute: "#DB6B8F",
  storage: "#9B6BDB",
  gateway: "#44D17B",
  validator: "#DBA06B",
  oracle: "#6BDBDB",
  creator: "#D7B24A",
};

const ROLE_SIZES: Record<SphereNodeRole, number> = {
  sovereign: 8,
  gateway: 6,
  relay: 5,
  compute: 5,
  storage: 5,
  validator: 4,
  oracle: 4,
  creator: 4,
};

// ─── Network Data ───────────────────────────────────────────────────────────

interface SphereNode {
  id: string;
  label: string;
  role: SphereNodeRole;
  phase: number;
  omega: number;
  health: number;
  throughput: number;
  tokenTypes: CustomTokenType[];
  tokenVolume: number;
}

interface WebConnection {
  from: string;
  to: string;
  bandwidth: number;
  latency: number;
  tokenFlows: { type: CustomTokenType; volume: number }[];
  strength: number;
}

// ─── 3D Math ────────────────────────────────────────────────────────────────

interface Vec3 {
  x: number;
  y: number;
  z: number;
}

function goldenSphere(index: number, total: number): Vec3 {
  const phi_val = Math.acos(1 - (2 * index) / (total || 1));
  const theta = GOLDEN_ANGLE_RAD * index;
  return {
    x: Math.sin(phi_val) * Math.cos(theta),
    y: Math.cos(phi_val),
    z: Math.sin(phi_val) * Math.sin(theta),
  };
}

function rotY(v: Vec3, a: number): Vec3 {
  const c = Math.cos(a);
  const s = Math.sin(a);
  return { x: v.x * c + v.z * s, y: v.y, z: -v.x * s + v.z * c };
}

function rotX(v: Vec3, a: number): Vec3 {
  const c = Math.cos(a);
  const s = Math.sin(a);
  return { x: v.x, y: v.y * c - v.z * s, z: v.y * s + v.z * c };
}

function proj(
  v: Vec3,
  cx: number,
  cy: number,
  R: number,
  fov: number,
): { x: number; y: number; s: number } {
  const d = v.z + fov;
  const s = fov / d;
  return { x: cx + v.x * R * s, y: cy + v.y * R * s, s };
}

// ─── Mock Network (simulates live topology) ─────────────────────────────────

function buildNetwork(beat: number): {
  nodes: SphereNode[];
  connections: WebConnection[];
} {
  const defs: [string, SphereNodeRole, CustomTokenType[]][] = [
    ["PRIME-α", "sovereign", ["governance", "yield"]],
    ["GATE-Δ", "gateway", ["utility"]],
    ["GATE-Λ", "gateway", ["utility"]],
    ["GATE-Υ", "gateway", ["utility"]],
    ["RELAY-Ω", "relay", ["aiInference", "aiCompute"]],
    ["RELAY-Φ", "relay", ["aiMemory", "aiData"]],
    ["RELAY-Η", "relay", ["aiTraining"]],
    ["COMPUTE-Σ", "compute", ["aiCompute", "aiInference"]],
    ["COMPUTE-Ψ", "compute", ["aiCompute"]],
    ["COMPUTE-Θ", "compute", ["aiInference"]],
    ["STORE-Π", "storage", ["aiMemory", "aiData"]],
    ["STORE-Ξ", "storage", ["aiMemory"]],
    ["VALID-Γ", "validator", ["governance"]],
    ["VALID-Κ", "validator", ["governance", "yield"]],
    ["ORACLE-Μ", "oracle", ["utility", "aiData"]],
    ["ORACLE-Ν", "oracle", ["utility"]],
    ["CREATE-Ρ", "creator", ["creatorPersonal", "artifactBacked"]],
    ["CREATE-Τ", "creator", ["creatorPersonal", "rewardPoints"]],
    ["EDGE-Χ", "compute", ["aiCompute", "fractionalNFT"]],
    ["EDGE-Ε", "compute", ["aiInference", "utility"]],
    ["RELAY-Ι", "relay", ["yield", "rewardPoints"]],
    ["STORE-Ο", "storage", ["aiData", "aiMemory"]],
    ["GATE-Ϛ", "gateway", ["utility", "governance"]],
    ["PRIME-β", "sovereign", ["governance", "yield", "utility"]],
  ];

  const nodes: SphereNode[] = defs.map(([label, role, tTypes], i) => ({
    id: `WSN-${label}`,
    label,
    role,
    phase:
      ((i * GOLDEN_ANGLE * Math.PI) / 180 +
        beat * 0.008 * ((i % 3) + 1) * PHI_INV) %
      (Math.PI * 2),
    omega: 1 + (i % 5) * 0.2,
    health: Math.max(
      0.4,
      Math.min(1, 0.75 + Math.sin(beat * 0.04 + i * 1.3) * 0.25),
    ),
    throughput: Math.max(
      0.1,
      Math.min(1, 0.5 + Math.sin(beat * 0.025 + i * 0.9) * 0.4),
    ),
    tokenTypes: tTypes,
    tokenVolume:
      Math.max(0, 100 + Math.sin(beat * 0.02 + i) * 80) * (1 + i * 0.1),
  }));

  const edgeDefs: [number, number, number, CustomTokenType[]][] = [
    [0, 1, 0.95, ["governance"]],
    [0, 2, 0.9, ["governance"]],
    [0, 3, 0.88, ["governance"]],
    [23, 22, 0.92, ["governance", "utility"]],
    [1, 4, 0.8, ["aiInference", "aiCompute"]],
    [1, 5, 0.75, ["aiMemory", "aiData"]],
    [2, 6, 0.78, ["aiTraining"]],
    [3, 20, 0.72, ["yield", "rewardPoints"]],
    [22, 4, 0.7, ["aiCompute"]],
    [4, 7, 0.85, ["aiCompute", "aiInference"]],
    [4, 8, 0.8, ["aiCompute"]],
    [4, 9, 0.78, ["aiInference"]],
    [5, 10, 0.82, ["aiMemory", "aiData"]],
    [5, 11, 0.76, ["aiMemory"]],
    [6, 7, 0.74, ["aiCompute"]],
    [4, 12, 0.7, ["governance"]],
    [20, 13, 0.68, ["governance", "yield"]],
    [5, 14, 0.65, ["aiData"]],
    [6, 15, 0.6, ["utility"]],
    [20, 16, 0.72, ["creatorPersonal", "artifactBacked"]],
    [5, 17, 0.68, ["creatorPersonal", "rewardPoints"]],
    [7, 18, 0.6, ["aiCompute", "fractionalNFT"]],
    [9, 19, 0.58, ["aiInference", "utility"]],
    [18, 19, 0.45, ["utility"]],
    [10, 21, 0.55, ["aiData", "aiMemory"]],
    [12, 13, 0.5, ["governance"]],
    [14, 15, 0.48, ["utility"]],
    [16, 17, 0.52, ["creatorPersonal"]],
    [0, 23, 0.98, ["governance", "yield"]],
  ];

  const connections: WebConnection[] = edgeDefs.map(
    ([fi, ti, bw, tTypes]) => ({
      from: nodes[fi].id,
      to: nodes[ti].id,
      bandwidth: bw + Math.sin(beat * 0.015 + fi) * 0.05,
      latency: Math.max(0.05, 1 - bw * 0.8 + Math.sin(beat * 0.01) * 0.05),
      tokenFlows: tTypes.map((t) => ({
        type: t,
        volume: bw * 50 + Math.sin(beat * 0.02 + fi + ti) * 20,
      })),
      strength: bw * PHI_INV,
    }),
  );

  return { nodes, connections };
}

// ─── Kuramoto R ─────────────────────────────────────────────────────────────

function kuramotoR(nodes: SphereNode[]): number {
  if (nodes.length === 0) return 0;
  let ss = 0;
  let sc = 0;
  for (const n of nodes) {
    ss += Math.sin(n.phase);
    sc += Math.cos(n.phase);
  }
  const N = nodes.length;
  return Math.sqrt((ss / N) ** 2 + (sc / N) ** 2);
}

// ═════════════════════════════════════════════════════════════════════════════
// COMPONENT
// ═════════════════════════════════════════════════════════════════════════════

export function WebSphereTab() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animRef = useRef(0);
  const rotRef = useRef({ yaw: 0, pitch: 0.35 });
  const dragRef = useRef({ active: false, lx: 0, ly: 0 });
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [beat, setBeat] = useState(0);
  const beatRef = useRef(0);

  // Heartbeat driver — 873ms matches the organism's sovereign heartbeat
  // (phi-derived: 1000/φ ≈ 618ms rounded to 873ms = 1000×φ⁻¹×√φ)
  useEffect(() => {
    const iv = setInterval(() => {
      beatRef.current += 1;
      setBeat(beatRef.current);
    }, 873);
    return () => clearInterval(iv);
  }, []);

  const { nodes, connections } = useMemo(() => buildNetwork(beat), [beat]);
  const globalR = useMemo(() => kuramotoR(nodes), [nodes]);

  const selectedData = useMemo(() => {
    if (!selectedNode) return null;
    const n = nodes.find((nd) => nd.id === selectedNode);
    if (!n) return null;
    const conns = connections.filter(
      (c) => c.from === selectedNode || c.to === selectedNode,
    );
    return { node: n, connections: conns };
  }, [selectedNode, nodes, connections]);

  // ── Stats ───────────────────────────────────────────────────────────────

  const stats = useMemo(() => {
    const avgBw =
      connections.reduce((s, c) => s + c.bandwidth, 0) /
      (connections.length || 1);
    const avgLat =
      connections.reduce((s, c) => s + c.latency, 0) /
      (connections.length || 1);
    const totalVol = nodes.reduce((s, n) => s + n.tokenVolume, 0);
    const density =
      connections.length / ((nodes.length * (nodes.length - 1)) / 2 || 1);
    return { avgBw, avgLat, totalVol, density };
  }, [nodes, connections]);

  // ── Token type breakdown ────────────────────────────────────────────────

  const tokenBreakdown = useMemo(() => {
    const map = new Map<CustomTokenType, number>();
    for (const c of connections) {
      for (const f of c.tokenFlows) {
        map.set(f.type, (map.get(f.type) ?? 0) + Math.max(0, f.volume));
      }
    }
    return Array.from(map.entries()).sort((a, b) => b[1] - a[1]);
  }, [connections]);

  // ═══════════════════════════════════════════════════════════════════════════
  // CANVAS DRAW LOOP
  // ═══════════════════════════════════════════════════════════════════════════

  const draw = useCallback(
    (t: number) => {
      const cvs = canvasRef.current;
      if (!cvs) return;
      const ctx = cvs.getContext("2d");
      if (!ctx) return;

      const dpr = window.devicePixelRatio || 1;
      const W = cvs.offsetWidth;
      const H = cvs.offsetHeight;
      if (cvs.width !== W * dpr || cvs.height !== H * dpr) {
        cvs.width = W * dpr;
        cvs.height = H * dpr;
        ctx.scale(dpr, dpr);
      }

      const cx = W / 2;
      const cy = H / 2;
      const R = Math.min(W, H) * 0.36;
      const fov = 3.5;

      // Auto-rotate
      if (!dragRef.current.active) {
        rotRef.current.yaw += 0.0025;
      }
      const { yaw, pitch } = rotRef.current;

      ctx.clearRect(0, 0, W, H);

      // Background latitude rings
      ctx.strokeStyle = `rgba(107,159,219,${0.03 + globalR * 0.02})`;
      ctx.lineWidth = 0.5;
      for (let lat = -3; lat <= 3; lat++) {
        const yOff = (lat / 4) * R;
        const rr = Math.sqrt(Math.max(0, R * R - yOff * yOff));
        if (rr > 5) {
          ctx.beginPath();
          ctx.ellipse(cx, cy + yOff * 0.6, rr, rr * 0.28, 0, 0, Math.PI * 2);
          ctx.stroke();
        }
      }

      // Project all nodes
      const projected = nodes.map((node, i) => {
        let p = goldenSphere(i, nodes.length);
        p = rotY(p, yaw);
        p = rotX(p, pitch);
        const pr = proj(p, cx, cy, R, fov);
        return { node, x: pr.x, y: pr.y, s: pr.s, z: p.z };
      });

      // Sort back-to-front
      projected.sort((a, b) => a.z - b.z);

      // Build lookup
      const posMap = new Map(projected.map((p) => [p.node.id, p]));

      // ── Draw web connections ─────────────────────────────────────────
      for (const conn of connections) {
        const fp = posMap.get(conn.from);
        const tp = posMap.get(conn.to);
        if (!fp || !tp) continue;

        const avgZ = (fp.z + tp.z) / 2;
        const depthA = Math.max(0.05, Math.min(0.6, (avgZ + 1) / 2));
        const pulse =
          0.5 + 0.5 * Math.sin(t * 0.002 * conn.bandwidth + conn.latency * 8);

        // Color from dominant token flow
        const domFlow = conn.tokenFlows[0];
        const flowColor = domFlow
          ? TOKEN_COLORS[domFlow.type]
          : "rgb(159,160,170)";

        ctx.strokeStyle = flowColor;
        ctx.globalAlpha = depthA * pulse * Math.min(1, conn.bandwidth + 0.2);
        ctx.lineWidth = Math.max(0.4, conn.bandwidth * 2.5 * fp.s);

        // Curved arc toward center for depth
        const mx = (fp.x + tp.x) / 2 + (cx - (fp.x + tp.x) / 2) * 0.12;
        const my = (fp.y + tp.y) / 2 + (cy - (fp.y + tp.y) / 2) * 0.12;
        ctx.beginPath();
        ctx.moveTo(fp.x, fp.y);
        ctx.quadraticCurveTo(mx, my, tp.x, tp.y);
        ctx.stroke();
        ctx.globalAlpha = 1;
      }

      // ── Draw nodes ───────────────────────────────────────────────────
      for (const { node, x, y, s, z } of projected) {
        const depthA = Math.max(0.25, Math.min(1, (z + 1.5) / 2.5));
        const color = ROLE_COLORS[node.role];
        const baseR = ROLE_SIZES[node.role];
        const pulse =
          1 +
          Math.sin(t * 0.004 * node.omega + node.phase) * 0.18 * node.health;
        const r = baseR * s * pulse;
        const isSelected = node.id === selectedNode;

        // Glow
        const grd = ctx.createRadialGradient(x, y, 0, x, y, r * 4);
        grd.addColorStop(0, `${color}50`);
        grd.addColorStop(1, `${color}00`);
        ctx.globalAlpha = depthA * node.throughput;
        ctx.fillStyle = grd;
        ctx.beginPath();
        ctx.arc(x, y, r * 4, 0, Math.PI * 2);
        ctx.fill();

        // Core
        ctx.globalAlpha = depthA;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();

        // Highlight spec
        ctx.fillStyle = "rgba(255,255,255,0.28)";
        ctx.beginPath();
        ctx.arc(x - r * 0.25, y - r * 0.25, r * 0.35, 0, Math.PI * 2);
        ctx.fill();

        // Selection ring
        if (isSelected) {
          ctx.globalAlpha = depthA;
          ctx.strokeStyle = "#fff";
          ctx.lineWidth = 1.5;
          ctx.beginPath();
          ctx.arc(x, y, r + 5, 0, Math.PI * 2);
          ctx.stroke();
        }

        // Health ring (front nodes only)
        if (z > -0.3 && node.health < 0.8) {
          ctx.globalAlpha = depthA * 0.7;
          ctx.strokeStyle = node.health < 0.4 ? "#DB6B3A" : "#D7B24A";
          ctx.lineWidth = 1.2;
          ctx.beginPath();
          ctx.arc(x, y, r + 3, 0, Math.PI * 2 * node.health);
          ctx.stroke();
        }

        // Label (front-facing)
        if (z > 0.1 && s > 0.65) {
          ctx.globalAlpha = depthA * 0.85;
          ctx.fillStyle = "#E7E9EE";
          ctx.font = `${Math.max(7, 9 * s)}px monospace`;
          ctx.textAlign = "center";
          ctx.fillText(node.label, x, y + r + 13);

          // Token type badges
          if (z > 0.4 && s > 0.8 && node.tokenTypes.length > 0) {
            ctx.font = `${Math.max(5, 6 * s)}px monospace`;
            ctx.globalAlpha = depthA * 0.5;
            const badge = node.tokenTypes
              .slice(0, 2)
              .map((tt) => TOKEN_LABELS[tt])
              .join(" · ");
            ctx.fillStyle = "#9AA0AA";
            ctx.fillText(badge, x, y + r + 22);
          }
        }

        ctx.globalAlpha = 1;
      }

      // ── HUD overlay ──────────────────────────────────────────────────
      ctx.fillStyle =
        globalR > S0 ? "#44D17B" : globalR > 0.5 ? "#D7B24A" : "#DB6B3A";
      ctx.font = "bold 10px monospace";
      ctx.textAlign = "left";
      ctx.fillText(`R = ${globalR.toFixed(4)}`, 12, 18);
      ctx.fillStyle = "#6F7580";
      ctx.font = "9px monospace";
      ctx.fillText(`${nodes.length} NODES · ${connections.length} WEBS`, 12, 30);
      ctx.fillText(`BEAT ${beat}`, 12, 42);

      animRef.current = requestAnimationFrame(draw);
    },
    [nodes, connections, globalR, selectedNode, beat],
  );

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  useEffect(() => {
    animRef.current = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(animRef.current);
  }, [draw]);

  // ─── Interaction ──────────────────────────────────────────────────────────

  const onDown = (e: React.MouseEvent) => {
    dragRef.current = { active: true, lx: e.clientX, ly: e.clientY };
  };
  const onMove = (e: React.MouseEvent) => {
    if (!dragRef.current.active) return;
    const dx = e.clientX - dragRef.current.lx;
    const dy = e.clientY - dragRef.current.ly;
    rotRef.current.yaw += dx * 0.005;
    rotRef.current.pitch = Math.max(
      -1.2,
      Math.min(1.2, rotRef.current.pitch + dy * 0.005),
    );
    dragRef.current.lx = e.clientX;
    dragRef.current.ly = e.clientY;
  };
  const onUp = () => {
    dragRef.current.active = false;
  };
  const onClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const cvs = canvasRef.current;
    if (!cvs) return;
    const rect = cvs.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    const W = cvs.offsetWidth;
    const H = cvs.offsetHeight;
    const cx2 = W / 2;
    const cy2 = H / 2;
    const R = Math.min(W, H) * 0.36;
    const fov = 3.5;
    const { yaw, pitch } = rotRef.current;

    for (let i = 0; i < nodes.length; i++) {
      let p = goldenSphere(i, nodes.length);
      p = rotY(p, yaw);
      p = rotX(p, pitch);
      const pr = proj(p, cx2, cy2, R, fov);
      if (Math.sqrt((mx - pr.x) ** 2 + (my - pr.y) ** 2) < 14) {
        setSelectedNode((prev) =>
          prev === nodes[i].id ? null : nodes[i].id,
        );
        return;
      }
    }
    setSelectedNode(null);
  };

  // ═════════════════════════════════════════════════════════════════════════
  // RENDER
  // ═════════════════════════════════════════════════════════════════════════

  return (
    <div className="space-y-4">
      {/* ── Stats Bar ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {[
          { l: "NODES", v: `${nodes.length}`, c: "#6B9FDB" },
          { l: "WEB LINKS", v: `${connections.length}`, c: "#44D17B" },
          {
            l: "COHERENCE R",
            v: `${(globalR * 100).toFixed(1)}%`,
            c: globalR > S0 ? "#44D17B" : "#DB6B3A",
          },
          {
            l: "AVG BANDWIDTH",
            v: `${(stats.avgBw * 100).toFixed(0)}%`,
            c: "#D6B36A",
          },
          {
            l: "MESH DENSITY",
            v: `${(stats.density * 100).toFixed(1)}%`,
            c: "#9B6BDB",
          },
          {
            l: "TOKEN VOLUME",
            v: `${(stats.totalVol / 1000).toFixed(1)}K`,
            c: "#D7B24A",
          },
        ].map((s) => (
          <motion.div
            key={s.l}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-[#15161A] border border-[#2A2C33] p-3"
          >
            <div className="text-[9px] text-[#9AA0AA] tracking-widest mb-1">
              {s.l}
            </div>
            <div className="font-mono text-sm font-bold" style={{ color: s.c }}>
              {s.v}
            </div>
          </motion.div>
        ))}
      </div>

      {/* ── Main Sphere + Side Panel ──────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4">
        {/* Sphere Canvas */}
        <div className="lg:col-span-3 bg-[#15161A] border border-[#2A2C33] p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest uppercase">
              WEBBED SPHERE · NETWORK TOPOLOGY
            </div>
            <div className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 rounded-full bg-[#44D17B] animate-pulse" />
              <span className="text-[9px] text-[#6F7580] tracking-widest">
                LIVE · BEAT {beat}
              </span>
            </div>
          </div>

          <canvas
            ref={canvasRef}
            className="w-full cursor-grab active:cursor-grabbing"
            style={{ height: 500 }}
            onMouseDown={onDown}
            onMouseMove={onMove}
            onMouseUp={onUp}
            onMouseLeave={onUp}
            onClick={onClick}
            tabIndex={0}
            role="img"
            aria-label="Webbed sphere network topology visualization — drag to rotate, click to select nodes"
          />

          {/* Role Legend */}
          <div className="mt-3 flex flex-wrap items-center gap-4 text-[9px] text-[#6F7580]">
            {(Object.keys(ROLE_COLORS) as SphereNodeRole[]).map((role) => (
              <span key={role} className="flex items-center gap-1">
                <span
                  className="w-2 h-2 rounded-full"
                  style={{ backgroundColor: ROLE_COLORS[role] }}
                />
                {role.toUpperCase()}
              </span>
            ))}
          </div>
        </div>

        {/* Side Panel */}
        <div className="space-y-3">
          {/* Node Detail */}
          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              {selectedData ? "NODE DETAIL" : "SELECT A NODE"}
            </div>
            {selectedData ? (
              <div className="space-y-2">
                <div
                  className="font-mono text-sm font-bold"
                  style={{ color: ROLE_COLORS[selectedData.node.role] }}
                >
                  {selectedData.node.label}
                </div>
                <div className="space-y-1.5 text-[9px]">
                  {[
                    {
                      k: "ROLE",
                      v: selectedData.node.role.toUpperCase(),
                    },
                    {
                      k: "HEALTH",
                      v: `${(selectedData.node.health * 100).toFixed(1)}%`,
                    },
                    {
                      k: "THROUGHPUT",
                      v: `${(selectedData.node.throughput * 100).toFixed(0)}%`,
                    },
                    {
                      k: "CONNECTIONS",
                      v: selectedData.connections.length.toString(),
                    },
                    {
                      k: "TOKEN VOL",
                      v: `${selectedData.node.tokenVolume.toFixed(0)}`,
                    },
                    {
                      k: "PHASE",
                      v: `${selectedData.node.phase.toFixed(3)} rad`,
                    },
                  ].map((r) => (
                    <div key={r.k} className="flex justify-between">
                      <span className="text-[#6F7580] tracking-widest">
                        {r.k}
                      </span>
                      <span className="font-mono text-[#E7E9EE]">{r.v}</span>
                    </div>
                  ))}
                </div>
                {/* Token types */}
                <div className="pt-2 border-t border-[#2A2C33]">
                  <div className="text-[9px] text-[#6F7580] tracking-widest mb-1.5">
                    TOKEN TYPES
                  </div>
                  <div className="flex flex-wrap gap-1">
                    {selectedData.node.tokenTypes.map((tt) => (
                      <span
                        key={tt}
                        className="font-mono text-[8px] px-1.5 py-0.5 rounded"
                        style={{
                          backgroundColor: `${TOKEN_COLORS[tt]}15`,
                          color: TOKEN_COLORS[tt],
                          border: `1px solid ${TOKEN_COLORS[tt]}30`,
                        }}
                      >
                        {TOKEN_LABELS[tt]}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-[9px] text-[#6F7580]">
                Click a node on the sphere to inspect its role, health, and
                token flows.
              </div>
            )}
          </div>

          {/* Network Health */}
          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              NETWORK HEALTH
            </div>
            <div className="space-y-2">
              {[
                {
                  l: "KURAMOTO R",
                  v: globalR,
                  t: S0,
                },
                {
                  l: "AVG HEALTH",
                  v: nodes.reduce((s, n) => s + n.health, 0) / nodes.length,
                  t: 0.7,
                },
                {
                  l: "BANDWIDTH",
                  v: stats.avgBw,
                  t: 0.5,
                },
                {
                  l: "MESH DENSITY",
                  v: stats.density,
                  t: 0.15,
                },
              ].map((m) => (
                <div key={m.l}>
                  <div className="flex justify-between mb-1">
                    <span className="text-[9px] text-[#6F7580] tracking-widest">
                      {m.l}
                    </span>
                    <span
                      className="font-mono text-[9px]"
                      style={{
                        color: m.v >= m.t ? "#44D17B" : "#DB6B3A",
                      }}
                    >
                      {(m.v * 100).toFixed(1)}%
                    </span>
                  </div>
                  <div className="h-0.5 bg-[#2A2C33] rounded">
                    <div
                      className="h-full rounded transition-all duration-500"
                      style={{
                        width: `${Math.min(100, m.v * 100)}%`,
                        backgroundColor: m.v >= m.t ? "#44D17B" : "#DB6B3A",
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Token Flow Breakdown */}
          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              TOKEN FLOWS BY TYPE
            </div>
            <div className="space-y-1.5">
              {tokenBreakdown.slice(0, 8).map(([tt, vol]) => (
                <div key={tt} className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <span
                      className="w-2 h-2 rounded-full"
                      style={{ backgroundColor: TOKEN_COLORS[tt] }}
                    />
                    <span className="text-[9px] text-[#9AA0AA] tracking-widest">
                      {TOKEN_LABELS[tt]}
                    </span>
                  </span>
                  <span className="font-mono text-[9px] text-[#E7E9EE]">
                    {vol.toFixed(0)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Node Distribution */}
          <div className="bg-[#15161A] border border-[#2A2C33] p-4">
            <div className="text-[10px] text-[#9AA0AA] tracking-widest mb-3">
              NODE DISTRIBUTION
            </div>
            <div className="space-y-1.5">
              {(Object.keys(ROLE_COLORS) as SphereNodeRole[]).map((role) => {
                const count = nodes.filter((n) => n.role === role).length;
                if (count === 0) return null;
                return (
                  <div key={role} className="flex items-center justify-between">
                    <span className="flex items-center gap-1.5">
                      <span
                        className="w-2 h-2 rounded-full"
                        style={{ backgroundColor: ROLE_COLORS[role] }}
                      />
                      <span className="text-[9px] text-[#9AA0AA] tracking-widest uppercase">
                        {role}
                      </span>
                    </span>
                    <span className="font-mono text-[9px] text-[#E7E9EE]">
                      {count}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
