import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { GitBranch, Loader2, Plus, RefreshCw, Search } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { type RelationshipType, useGraph } from "../hooks/useGraph";
import { NodeType } from "../hooks/useGraph";
import type { GraphEdge, GraphNode } from "../hooks/useGraph";
import { AddEdgeDialog } from "./AddEdgeDialog";
import { AddNodeDialog } from "./AddNodeDialog";
import { NodeDetail } from "./NodeDetail";

const NODE_COLORS: Record<
  NodeType,
  { fill: string; stroke: string; glow: string }
> = {
  [NodeType.concept]: {
    fill: "oklch(0.72 0.17 200 / 0.2)",
    stroke: "oklch(0.72 0.17 200)",
    glow: "oklch(0.72 0.17 200 / 0.6)",
  },
  [NodeType.memory]: {
    fill: "oklch(0.60 0.22 295 / 0.2)",
    stroke: "oklch(0.60 0.22 295)",
    glow: "oklch(0.60 0.22 295 / 0.6)",
  },
  [NodeType.knowledge]: {
    fill: "oklch(0.78 0.18 85 / 0.2)",
    stroke: "oklch(0.78 0.18 85)",
    glow: "oklch(0.78 0.18 85 / 0.6)",
  },
  [NodeType.aiSystem]: {
    fill: "oklch(0.50 0.01 252 / 0.2)",
    stroke: "oklch(0.50 0.01 252)",
    glow: "oklch(0.50 0.01 252 / 0.4)",
  },
};

const NODE_RADIUS = 22;

interface NodePos {
  id: string;
  x: number;
  y: number;
  vx: number;
  vy: number;
}

function computeLayout(
  nodes: GraphNode[],
  edges: GraphEdge[],
  width: number,
  height: number,
): Map<string, { x: number; y: number }> {
  if (nodes.length === 0) return new Map();

  const cx = width / 2;
  const cy = height / 2;
  const r = Math.min(width, height) * 0.35;

  const positions: NodePos[] = nodes.map((n, i) => {
    const angle = (i / nodes.length) * Math.PI * 2 - Math.PI / 2;
    return {
      id: n.id,
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle),
      vx: 0,
      vy: 0,
    };
  });

  const ITERATIONS = 120;
  const REPULSION = 3000;
  const SPRING_LENGTH = 130;
  const SPRING_STRENGTH = 0.04;
  const GRAVITY = 0.03;
  const DAMPING = 0.85;

  for (let iter = 0; iter < ITERATIONS; iter++) {
    const alpha = 1 - iter / ITERATIONS;
    const forces = positions.map(() => ({ fx: 0, fy: 0 }));

    for (let i = 0; i < positions.length; i++) {
      for (let j = i + 1; j < positions.length; j++) {
        const dx = positions[j].x - positions[i].x;
        const dy = positions[j].y - positions[i].y;
        const dist = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
        const force = REPULSION / (dist * dist);
        const fx = (dx / dist) * force;
        const fy = (dy / dist) * force;
        forces[i].fx -= fx;
        forces[i].fy -= fy;
        forces[j].fx += fx;
        forces[j].fy += fy;
      }
      forces[i].fx += (cx - positions[i].x) * GRAVITY;
      forces[i].fy += (cy - positions[i].y) * GRAVITY;
    }

    for (const edge of edges) {
      const si = positions.findIndex((p) => p.id === edge.fromNodeId);
      const ti = positions.findIndex((p) => p.id === edge.toNodeId);
      if (si === -1 || ti === -1) continue;
      const dx = positions[ti].x - positions[si].x;
      const dy = positions[ti].y - positions[si].y;
      const dist = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
      const force = (dist - SPRING_LENGTH) * SPRING_STRENGTH;
      const fx = (dx / dist) * force;
      const fy = (dy / dist) * force;
      forces[si].fx += fx;
      forces[si].fy += fy;
      forces[ti].fx -= fx;
      forces[ti].fy -= fy;
    }

    for (let i = 0; i < positions.length; i++) {
      positions[i].vx = (positions[i].vx + forces[i].fx) * DAMPING * alpha;
      positions[i].vy = (positions[i].vy + forces[i].fy) * DAMPING * alpha;
      positions[i].x = Math.max(
        NODE_RADIUS + 10,
        Math.min(width - NODE_RADIUS - 10, positions[i].x + positions[i].vx),
      );
      positions[i].y = Math.max(
        NODE_RADIUS + 20,
        Math.min(height - NODE_RADIUS - 20, positions[i].y + positions[i].vy),
      );
    }
  }

  return new Map(positions.map((p) => [p.id, { x: p.x, y: p.y }]));
}

export function GraphPanel() {
  const {
    nodes,
    edges,
    isLoading,
    refetch,
    addNode,
    removeNode,
    addEdge,
    removeEdge,
  } = useGraph();
  const containerRef = useRef<HTMLDivElement>(null);
  const [dimensions, setDimensions] = useState({ width: 600, height: 500 });
  const [layout, setLayout] = useState<Map<string, { x: number; y: number }>>(
    new Map(),
  );
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [showAddNode, setShowAddNode] = useState(false);
  const [showAddEdge, setShowAddEdge] = useState(false);
  const [hoveredNodeId, setHoveredNodeId] = useState<string | null>(null);
  const [nodeSearch, setNodeSearch] = useState("");

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const obs = new ResizeObserver((entries) => {
      for (const entry of entries) {
        setDimensions({
          width: entry.contentRect.width,
          height: entry.contentRect.height,
        });
      }
    });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  useEffect(() => {
    if (nodes.length === 0) {
      setLayout(new Map());
      return;
    }
    const newLayout = computeLayout(
      nodes,
      edges,
      dimensions.width,
      dimensions.height,
    );
    setLayout(newLayout);
  }, [nodes, edges, dimensions]);

  const handleNodeClick = useCallback((node: GraphNode) => {
    setSelectedNode((prev) => (prev?.id === node.id ? null : node));
  }, []);

  const handleDeleteNode = useCallback(
    async (id: string) => {
      try {
        await removeNode(id);
        setSelectedNode(null);
        toast.success("Node deleted");
      } catch {
        toast.error("Failed to delete node");
      }
    },
    [removeNode],
  );

  const handleDeleteEdge = useCallback(
    async (id: string) => {
      try {
        await removeEdge(id);
        toast.success("Edge deleted");
      } catch {
        toast.error("Failed to delete edge");
      }
    },
    [removeEdge],
  );

  const handleAddNode = useCallback(
    async (label: string, type: NodeType) => {
      try {
        await addNode(label, type);
        toast.success(`Node "${label}" added`);
      } catch {
        toast.error("Failed to add node");
      }
    },
    [addNode],
  );

  const handleAddEdge = useCallback(
    async (
      fromId: string,
      toId: string,
      type: RelationshipType,
      confidence: number,
      salience: number,
    ) => {
      try {
        await addEdge(fromId, toId, type, confidence, salience);
        toast.success("Edge added");
      } catch {
        toast.error("Failed to add edge");
      }
    },
    [addEdge],
  );

  const searchActive = nodeSearch.trim() !== "";
  const searchLower = nodeSearch.toLowerCase();

  // Compute which node IDs match the search
  const matchingNodeIds = searchActive
    ? new Set(
        nodes
          .filter((n) => n.labelText.toLowerCase().includes(searchLower))
          .map((n) => n.id),
      )
    : null;

  function renderEdge(edge: GraphEdge, idx: number) {
    const from = layout.get(edge.fromNodeId);
    const to = layout.get(edge.toNodeId);
    if (!from || !to) return null;

    const dx = to.x - from.x;
    const dy = to.y - from.y;
    const len = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
    const ex = to.x - (dx / len) * (NODE_RADIUS + 6);
    const ey = to.y - (dy / len) * (NODE_RADIUS + 6);
    const sx = from.x + (dx / len) * (NODE_RADIUS + 2);
    const sy = from.y + (dy / len) * (NODE_RADIUS + 2);
    const isHighSalience =
      edge.salienceScore > 0.8 && edge.reinforcementCount > 3n;

    // Dim edge if search is active and neither endpoint is a match
    const edgeDimmed =
      searchActive &&
      matchingNodeIds !== null &&
      !matchingNodeIds.has(edge.fromNodeId) &&
      !matchingNodeIds.has(edge.toNodeId);

    return (
      <g key={edge.id} opacity={edgeDimmed ? 0.15 : 1}>
        <line
          x1={sx}
          y1={sy}
          x2={ex}
          y2={ey}
          stroke={
            isHighSalience
              ? "oklch(0.78 0.18 85 / 0.7)"
              : "oklch(0.72 0.17 200 / 0.3)"
          }
          strokeWidth={isHighSalience ? 2 : 1.5}
          markerEnd="url(#arrowhead)"
          data-ocid={`graph.edge.item.${idx + 1}`}
        />
        <text
          x={(sx + ex) / 2}
          y={(sy + ey) / 2 - 4}
          textAnchor="middle"
          fontSize="9"
          fill="oklch(0.60 0.03 252)"
          style={{ pointerEvents: "none", userSelect: "none" }}
        >
          {edge.relationshipType}
        </text>
      </g>
    );
  }

  function renderNode(node: GraphNode, idx: number) {
    const pos = layout.get(node.id);
    if (!pos) return null;
    const colors = NODE_COLORS[node.nodeType];
    const isSelected = selectedNode?.id === node.id;
    const isHovered = hoveredNodeId === node.id;
    const label =
      node.labelText.length > 12
        ? `${node.labelText.slice(0, 12)}\u2026`
        : node.labelText;

    const nodeDimmed =
      searchActive && matchingNodeIds !== null && !matchingNodeIds.has(node.id);

    return (
      <g
        key={node.id}
        tabIndex={0}
        aria-label={`Node: ${node.labelText}`}
        style={{ cursor: "pointer" }}
        onClick={() => handleNodeClick(node)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") handleNodeClick(node);
        }}
        onMouseEnter={() => setHoveredNodeId(node.id)}
        onMouseLeave={() => setHoveredNodeId(null)}
        opacity={nodeDimmed ? 0.2 : 1}
        data-ocid={`graph.node.item.${idx + 1}`}
      >
        {(isSelected || isHovered) && (
          <circle
            cx={pos.x}
            cy={pos.y}
            r={NODE_RADIUS + 6}
            fill="none"
            stroke={colors.glow}
            strokeWidth={isSelected ? 2 : 1}
            opacity={isSelected ? 0.9 : 0.5}
            filter="url(#glow)"
          />
        )}
        <circle
          cx={pos.x}
          cy={pos.y}
          r={NODE_RADIUS}
          fill={colors.fill}
          stroke={colors.stroke}
          strokeWidth={isSelected ? 2 : 1.5}
        />
        <text
          x={pos.x}
          y={pos.y + NODE_RADIUS + 14}
          textAnchor="middle"
          fontSize="10"
          fill="oklch(0.75 0.02 252)"
          style={{ pointerEvents: "none", userSelect: "none" }}
        >
          {label}
        </text>
      </g>
    );
  }

  return (
    <div className="h-full flex flex-col bg-background">
      <div className="flex items-center justify-between px-4 py-3 border-b border-border shrink-0">
        <div className="flex items-center gap-2">
          <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
            Knowledge Graph
          </span>
          {nodes.length > 0 && (
            <span className="text-xs px-1.5 py-0.5 rounded bg-muted text-muted-foreground">
              {nodes.length} nodes · {edges.length} edges
            </span>
          )}
        </div>
        <div className="flex items-center gap-1">
          {/* Search input */}
          <div className="relative">
            <Search className="absolute left-2 top-1/2 -translate-y-1/2 w-3 h-3 text-muted-foreground pointer-events-none" />
            <Input
              value={nodeSearch}
              onChange={(e) => setNodeSearch(e.target.value)}
              placeholder="Search…"
              className="h-7 w-32 text-xs pl-6 pr-2"
              data-ocid="graph.search_input"
            />
          </div>
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 text-muted-foreground hover:text-foreground"
            onClick={refetch}
            data-ocid="graph.refresh.button"
          >
            <RefreshCw className="w-3.5 h-3.5" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-7 text-xs gap-1 text-muted-foreground hover:text-primary"
            onClick={() => setShowAddEdge(true)}
            disabled={nodes.length < 2}
            data-ocid="graph.add_edge.open_modal_button"
          >
            <GitBranch className="w-3.5 h-3.5" />
            Edge
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="h-7 text-xs gap-1 text-muted-foreground hover:text-primary"
            onClick={() => setShowAddNode(true)}
            data-ocid="graph.add_node.open_modal_button"
          >
            <Plus className="w-3.5 h-3.5" />
            Node
          </Button>
        </div>
      </div>

      <div ref={containerRef} className="flex-1 relative overflow-hidden">
        {isLoading ? (
          <div
            className="absolute inset-0 flex items-center justify-center"
            data-ocid="graph.loading_state"
          >
            <Loader2 className="w-6 h-6 animate-spin text-primary" />
          </div>
        ) : nodes.length === 0 ? (
          <div
            className="absolute inset-0 flex flex-col items-center justify-center gap-3 text-center p-8"
            data-ocid="graph.empty_state"
          >
            <div className="w-16 h-16 rounded-2xl bg-primary/10 border border-primary/20 flex items-center justify-center">
              <GitBranch className="w-8 h-8 text-primary/50" />
            </div>
            <p className="text-sm text-muted-foreground max-w-48">
              Send a message to start building your knowledge graph.
            </p>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowAddNode(true)}
              className="text-xs gap-1"
              data-ocid="graph.add_first_node.button"
            >
              <Plus className="w-3.5 h-3.5" />
              Add node manually
            </Button>
          </div>
        ) : (
          <svg
            role="img"
            aria-label="Knowledge graph visualization"
            width={dimensions.width}
            height={dimensions.height}
            className="absolute inset-0"
            data-ocid="graph.canvas_target"
          >
            <title>Knowledge Graph</title>
            <defs>
              <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="4" result="coloredBlur" />
                <feMerge>
                  <feMergeNode in="coloredBlur" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <marker
                id="arrowhead"
                markerWidth="8"
                markerHeight="6"
                refX="7"
                refY="3"
                orient="auto"
              >
                <polygon
                  points="0 0, 8 3, 0 6"
                  fill="oklch(0.72 0.17 200 / 0.5)"
                />
              </marker>
            </defs>
            <g>{edges.map((e, i) => renderEdge(e, i))}</g>
            <g>{nodes.map((n, i) => renderNode(n, i))}</g>
          </svg>
        )}

        <AnimatePresence>
          {selectedNode && (
            <motion.div
              key={selectedNode.id}
              initial={{ x: 288, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: 288, opacity: 0 }}
              transition={{ type: "spring", stiffness: 300, damping: 30 }}
              className="absolute right-0 top-0 h-full"
            >
              <NodeDetail
                node={selectedNode}
                edges={edges}
                nodes={nodes}
                onClose={() => setSelectedNode(null)}
                onDeleteNode={handleDeleteNode}
                onDeleteEdge={handleDeleteEdge}
              />
            </motion.div>
          )}
        </AnimatePresence>

        {nodes.length > 0 && (
          <div className="absolute bottom-3 left-3 flex flex-col gap-1.5 bg-card/80 backdrop-blur-sm border border-border rounded-lg p-2.5">
            {Object.entries(NODE_COLORS).map(([type, colors]) => (
              <div key={type} className="flex items-center gap-1.5">
                <svg role="img" aria-label={type} width="12" height="12">
                  <title>{type}</title>
                  <circle
                    cx="6"
                    cy="6"
                    r="5"
                    fill={colors.fill}
                    stroke={colors.stroke}
                    strokeWidth="1.5"
                  />
                </svg>
                <span className="text-xs text-muted-foreground capitalize">
                  {type}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      <AddNodeDialog
        open={showAddNode}
        onClose={() => setShowAddNode(false)}
        onAdd={handleAddNode}
      />
      <AddEdgeDialog
        open={showAddEdge}
        onClose={() => setShowAddEdge(false)}
        nodes={nodes}
        onAdd={handleAddEdge}
      />
    </div>
  );
}
