// @ts-nocheck
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Skeleton } from "@/components/ui/skeleton";
import { Search, Trash2, ZoomIn, ZoomOut } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { NodeType } from "../backend.d";
import type { GraphEdge, GraphNode } from "../backend.d";
import {
  useDeleteEdge,
  useDeleteNode,
  useFullGraph,
} from "../hooks/useQueries";

// Node colors by type (literal values for canvas)
const NODE_COLORS: Record<NodeType, string> = {
  [NodeType.concept]: "#06b6d4", // cyan
  [NodeType.memory]: "#a855f7", // purple
  [NodeType.knowledge]: "#22c55e", // green
  [NodeType.aiSystem]: "#6b7280", // gray
};

interface SimNode extends GraphNode {
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  selected: boolean;
}

interface SimEdge extends GraphEdge {
  source: SimNode;
  target: SimNode;
}

export function MemorySection() {
  const { data: graphData, isLoading } = useFullGraph();
  const deleteNode = useDeleteNode();
  const deleteEdge = useDeleteEdge();

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animFrameRef = useRef<number>(0);
  const nodesRef = useRef<SimNode[]>([]);
  const edgesRef = useRef<SimEdge[]>([]);
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [zoom, setZoom] = useState(1);
  const containerRef = useRef<HTMLDivElement>(null);

  // Build simulation nodes/edges from backend data
  useEffect(() => {
    if (!graphData) return;
    const { nodes, edges } = graphData;

    const existingMap = new Map(nodesRef.current.map((n) => [n.id, n]));
    nodesRef.current = nodes.map((n) => {
      const existing = existingMap.get(n.id);
      return {
        ...n,
        x: existing?.x ?? (Math.random() - 0.5) * 400,
        y: existing?.y ?? (Math.random() - 0.5) * 400,
        vx: existing?.vx ?? 0,
        vy: existing?.vy ?? 0,
        radius: 18,
        selected: n.id === selectedNodeId,
      };
    });

    const nodeMap = new Map(nodesRef.current.map((n) => [n.id, n]));
    edgesRef.current = edges
      .filter((e) => nodeMap.has(e.fromNodeId) && nodeMap.has(e.toNodeId))
      .map((e) => ({
        ...e,
        source: nodeMap.get(e.fromNodeId)!,
        target: nodeMap.get(e.toNodeId)!,
      }));
  }, [graphData, selectedNodeId]);

  const runSim = useCallback(() => {
    const nodes = nodesRef.current;
    const edges = edgesRef.current;
    if (nodes.length === 0) return;

    const alpha = 0.08;
    const repulsion = 3000;
    const linkDist = 120;
    const damping = 0.85;

    // Repulsion
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const dx = nodes[j].x - nodes[i].x;
        const dy = nodes[j].y - nodes[i].y;
        const dist = Math.sqrt(dx * dx + dy * dy) || 1;
        const force = (repulsion / (dist * dist)) * alpha;
        nodes[i].vx -= (dx / dist) * force;
        nodes[i].vy -= (dy / dist) * force;
        nodes[j].vx += (dx / dist) * force;
        nodes[j].vy += (dy / dist) * force;
      }
    }

    // Attraction along edges
    for (const e of edges) {
      const dx = e.target.x - e.source.x;
      const dy = e.target.y - e.source.y;
      const dist = Math.sqrt(dx * dx + dy * dy) || 1;
      const force = ((dist - linkDist) / linkDist) * alpha;
      e.source.vx += (dx / dist) * force;
      e.source.vy += (dy / dist) * force;
      e.target.vx -= (dx / dist) * force;
      e.target.vy -= (dy / dist) * force;
    }

    // Center gravity
    for (const n of nodes) {
      n.vx -= n.x * 0.01 * alpha;
      n.vy -= n.y * 0.01 * alpha;
      n.vx *= damping;
      n.vy *= damping;
      n.x += n.vx;
      n.y += n.vy;
    }
  }, []);

  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const w = canvas.width;
    const h = canvas.height;
    ctx.clearRect(0, 0, w, h);

    ctx.save();
    ctx.translate(w / 2, h / 2);
    ctx.scale(zoom, zoom);

    const nodes = nodesRef.current;
    const edges = edgesRef.current;

    // Edges
    for (const e of edges) {
      const isHighlighted =
        selectedNodeId === null ||
        e.source.id === selectedNodeId ||
        e.target.id === selectedNodeId;
      const reinforcement = Number(e.reinforcementCount);
      const lineWidth = 1 + Math.min(reinforcement * 0.5, 3);
      ctx.beginPath();
      ctx.moveTo(e.source.x, e.source.y);
      ctx.lineTo(e.target.x, e.target.y);
      ctx.strokeStyle = isHighlighted
        ? `rgba(6, 182, 212, ${0.3 + Math.min(reinforcement * 0.1, 0.5)})`
        : "rgba(255,255,255,0.05)";
      ctx.lineWidth = lineWidth;
      ctx.stroke();

      // Consolidation badge
      if (reinforcement >= 3) {
        const mx = (e.source.x + e.target.x) / 2;
        const my = (e.source.y + e.target.y) / 2;
        ctx.fillStyle = "rgba(6,182,212,0.15)";
        ctx.fillRect(mx - 18, my - 6, 36, 12);
        ctx.fillStyle = "#06b6d4";
        ctx.font = "7px monospace";
        ctx.textAlign = "center";
        ctx.fillText("CONSOL", mx, my + 4);
      }
    }

    // Nodes
    for (const n of nodes) {
      const color = NODE_COLORS[n.nodeType] ?? "#6b7280";
      const isSelected = n.id === selectedNodeId;
      const isConnected =
        selectedNodeId === null ||
        isSelected ||
        edges.some(
          (e) => e.source.id === selectedNodeId && e.target.id === n.id,
        ) ||
        edges.some(
          (e) => e.target.id === selectedNodeId && e.source.id === n.id,
        );

      ctx.beginPath();
      ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
      ctx.fillStyle = isConnected ? `${color}22` : "rgba(255,255,255,0.03)";
      ctx.fill();
      ctx.strokeStyle = isSelected
        ? color
        : isConnected
          ? `${color}88`
          : "rgba(255,255,255,0.1)";
      ctx.lineWidth = isSelected ? 2 : 1;
      ctx.stroke();

      // Label
      ctx.fillStyle = isConnected
        ? "rgba(255,255,255,0.85)"
        : "rgba(255,255,255,0.25)";
      ctx.font = `${isSelected ? "bold " : ""}9px monospace`;
      ctx.textAlign = "center";
      const label =
        n.labelText.length > 14 ? `${n.labelText.slice(0, 12)}..` : n.labelText;
      ctx.fillText(label, n.x, n.y + n.radius + 12);
    }

    ctx.restore();
  }, [zoom, selectedNodeId]);

  // Animation loop
  useEffect(() => {
    let frame = 0;
    const loop = () => {
      frame++;
      if (frame % 2 === 0) runSim();
      draw();
      animFrameRef.current = requestAnimationFrame(loop);
    };
    animFrameRef.current = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animFrameRef.current);
  }, [runSim, draw]);

  // Canvas resize
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const obs = new ResizeObserver(() => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      canvas.width = el.clientWidth;
      canvas.height = el.clientHeight;
    });
    obs.observe(el);
    const canvas = canvasRef.current;
    if (canvas) {
      canvas.width = el.clientWidth;
      canvas.height = el.clientHeight;
    }
    return () => obs.disconnect();
  }, []);

  // Click handler
  const handleCanvasClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const mx = (e.clientX - rect.left - canvas.width / 2) / zoom;
    const my = (e.clientY - rect.top - canvas.height / 2) / zoom;
    const clicked = nodesRef.current.find(
      (n) => Math.hypot(n.x - mx, n.y - my) <= n.radius,
    );
    setSelectedNodeId(
      clicked ? (clicked.id === selectedNodeId ? null : clicked.id) : null,
    );
  };

  const nodes = graphData?.nodes ?? [];
  const edges = graphData?.edges ?? [];
  const filteredNodes = searchQuery
    ? nodes.filter((n) =>
        n.labelText.toLowerCase().includes(searchQuery.toLowerCase()),
      )
    : nodes;

  const selectedNode = nodes.find((n) => n.id === selectedNodeId);
  const selectedEdges = selectedNode
    ? edges.filter(
        (e) => e.fromNodeId === selectedNodeId || e.toNodeId === selectedNodeId,
      )
    : [];

  return (
    <div className="flex flex-col h-full" data-ocid="memory.section">
      {/* Toolbar */}
      <div className="flex items-center gap-2 px-3 py-2 border-b border-border shrink-0">
        <Search className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
        <Input
          placeholder="Filter nodes..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="h-7 text-xs bg-muted border-0 font-mono flex-1"
          data-ocid="memory.search_input"
        />
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon"
            className="w-6 h-6 text-muted-foreground hover:text-foreground"
            onClick={() => setZoom((z) => Math.max(0.3, z - 0.1))}
            data-ocid="memory.zoom_out.button"
          >
            <ZoomOut className="w-3.5 h-3.5" />
          </Button>
          <span className="font-mono text-xs text-muted-foreground w-8 text-center">
            {Math.round(zoom * 100)}%
          </span>
          <Button
            variant="ghost"
            size="icon"
            className="w-6 h-6 text-muted-foreground hover:text-foreground"
            onClick={() => setZoom((z) => Math.min(2, z + 0.1))}
            data-ocid="memory.zoom_in.button"
          >
            <ZoomIn className="w-3.5 h-3.5" />
          </Button>
        </div>
      </div>

      <div className="flex flex-1 min-h-0">
        {/* Graph canvas */}
        <div ref={containerRef} className="flex-1 relative">
          {isLoading ? (
            <div
              className="absolute inset-0 flex items-center justify-center"
              data-ocid="memory.graph.loading_state"
            >
              <Skeleton className="w-48 h-48 rounded-full bg-muted" />
            </div>
          ) : nodes.length === 0 ? (
            <div
              className="absolute inset-0 flex flex-col items-center justify-center text-muted-foreground gap-2"
              data-ocid="memory.graph.empty_state"
            >
              <div className="font-mono text-xs tracking-widest">NO NODES</div>
              <div className="text-xs">
                Start a conversation to build memory
              </div>
            </div>
          ) : (
            <canvas
              ref={canvasRef}
              tabIndex={0}
              onKeyDown={(e) =>
                e.key === "Enter" &&
                handleCanvasClick(
                  e as unknown as React.MouseEvent<HTMLCanvasElement>,
                )
              }
              onClick={handleCanvasClick}
              className="w-full h-full cursor-crosshair"
              data-ocid="memory.canvas_target"
            />
          )}
        </div>

        {/* Side panel */}
        <div className="w-52 border-l border-border flex flex-col shrink-0">
          <div className="px-3 py-2 border-b border-border">
            <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
              {selectedNode ? "Node" : "Legend"}
            </span>
          </div>
          {selectedNode ? (
            <ScrollArea className="flex-1">
              <div className="p-3 space-y-3">
                <div>
                  <div className="text-xs text-muted-foreground mb-1">
                    Label
                  </div>
                  <div className="text-sm font-medium text-foreground">
                    {selectedNode.labelText}
                  </div>
                </div>
                <div>
                  <div className="text-xs text-muted-foreground mb-1">Type</div>
                  <Badge
                    className="text-xs font-mono"
                    style={{
                      backgroundColor: `${NODE_COLORS[selectedNode.nodeType]}22`,
                      color: NODE_COLORS[selectedNode.nodeType],
                      border: `1px solid ${NODE_COLORS[selectedNode.nodeType]}44`,
                    }}
                  >
                    {selectedNode.nodeType}
                  </Badge>
                </div>
                <div>
                  <div className="text-xs text-muted-foreground mb-1">
                    Connections ({selectedEdges.length})
                  </div>
                  <div className="space-y-1">
                    {selectedEdges.map((e) => {
                      const otherId =
                        e.fromNodeId === selectedNodeId
                          ? e.toNodeId
                          : e.fromNodeId;
                      const other = nodes.find((n) => n.id === otherId);
                      return (
                        <div
                          key={e.id}
                          className="flex items-center justify-between"
                        >
                          <span className="text-xs text-muted-foreground truncate">
                            {other?.labelText ?? "Unknown"}
                          </span>
                          <div className="flex items-center gap-1">
                            {Number(e.reinforcementCount) >= 3 && (
                              <Badge className="text-[9px] px-1 py-0 font-mono bg-primary/10 text-primary border-primary/20">
                                CONSOL
                              </Badge>
                            )}
                            <button
                              type="button"
                              onClick={() =>
                                deleteEdge
                                  .mutateAsync(e.id)
                                  .then(() => toast.success("Edge removed"))
                              }
                              className="text-muted-foreground hover:text-destructive"
                              data-ocid="memory.edge.delete_button"
                            >
                              <Trash2 className="w-3 h-3" />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full text-xs text-destructive border-destructive/30 hover:bg-destructive/10"
                  onClick={() =>
                    deleteNode.mutateAsync(selectedNode.id).then(() => {
                      setSelectedNodeId(null);
                      toast.success("Node deleted");
                    })
                  }
                  data-ocid="memory.node.delete_button"
                >
                  <Trash2 className="w-3 h-3 mr-1.5" />
                  Delete Node
                </Button>
              </div>
            </ScrollArea>
          ) : (
            <div className="p-3 space-y-2">
              {Object.entries(NODE_COLORS).map(([type, color]) => (
                <div key={type} className="flex items-center gap-2">
                  <div
                    className="w-3 h-3 rounded-full shrink-0"
                    style={{ backgroundColor: color, opacity: 0.8 }}
                  />
                  <span className="text-xs text-muted-foreground font-mono">
                    {type}
                  </span>
                </div>
              ))}
              <div className="border-t border-border pt-2 mt-2">
                <div className="font-mono text-xs text-muted-foreground">
                  {nodes.length} nodes · {edges.length} edges
                </div>
                <div className="font-mono text-xs text-muted-foreground mt-1">
                  {
                    edges.filter((e) => Number(e.reinforcementCount) >= 3)
                      .length
                  }{" "}
                  consolidated
                </div>
              </div>
              <div className="border-t border-border pt-2">
                <div className="text-xs text-muted-foreground">
                  Click node to inspect
                </div>
              </div>
            </div>
          )}

          {/* Node list */}
          {filteredNodes.length > 0 && (
            <>
              <div className="px-3 py-2 border-t border-border">
                <span className="font-mono text-xs text-muted-foreground tracking-widest uppercase">
                  Nodes
                </span>
              </div>
              <ScrollArea className="max-h-40">
                <div className="p-1.5 space-y-0.5">
                  {filteredNodes.map((n) => (
                    <button
                      type="button"
                      key={n.id}
                      onClick={() =>
                        setSelectedNodeId(n.id === selectedNodeId ? null : n.id)
                      }
                      className={`w-full text-left px-2 py-1 text-xs rounded-sm flex items-center gap-1.5 transition-colors ${
                        selectedNodeId === n.id
                          ? "bg-primary/10 text-primary"
                          : "text-muted-foreground hover:bg-muted"
                      }`}
                    >
                      <div
                        className="w-2 h-2 rounded-full shrink-0"
                        style={{ backgroundColor: NODE_COLORS[n.nodeType] }}
                      />
                      <span className="truncate">{n.labelText}</span>
                    </button>
                  ))}
                </div>
              </ScrollArea>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
