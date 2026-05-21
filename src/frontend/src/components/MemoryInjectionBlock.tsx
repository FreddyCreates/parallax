import { Brain, ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";
import type { GraphEdge, GraphNode } from "../hooks/useGraph";

interface Props {
  topEdges: GraphEdge[];
  nodes: GraphNode[];
}

function getNodeLabel(nodes: GraphNode[], id: string): string {
  return nodes.find((n) => n.id === id)?.labelText ?? id.slice(0, 8);
}

export function MemoryInjectionBlock({ topEdges, nodes }: Props) {
  const [expanded, setExpanded] = useState(true);

  if (topEdges.length === 0) return null;

  return (
    <div
      className="mb-4 rounded-lg border border-primary/20 bg-primary/5 overflow-hidden"
      data-ocid="memory.panel"
    >
      <button
        type="button"
        className="w-full flex items-center justify-between px-3 py-2 hover:bg-primary/10 transition-colors"
        onClick={() => setExpanded((v) => !v)}
        data-ocid="memory.toggle"
      >
        <div className="flex items-center gap-2">
          <Brain className="w-3.5 h-3.5 text-primary" />
          <span className="text-xs font-medium text-primary tracking-wide uppercase">
            Retrieved Memories
          </span>
          <span className="text-xs text-muted-foreground">
            ({topEdges.length})
          </span>
        </div>
        {expanded ? (
          <ChevronUp className="w-3.5 h-3.5 text-muted-foreground" />
        ) : (
          <ChevronDown className="w-3.5 h-3.5 text-muted-foreground" />
        )}
      </button>
      {expanded && (
        <div className="px-3 pb-3 flex flex-col gap-1">
          {topEdges.map((edge) => (
            <div
              key={edge.id}
              className="font-mono text-xs text-muted-foreground bg-background/50 rounded px-2 py-1 flex items-center gap-1 flex-wrap"
            >
              <span className="text-primary/80">
                {getNodeLabel(nodes, edge.fromNodeId)}
              </span>
              <span className="text-muted-foreground/60">
                --{edge.relationshipType}--&gt;
              </span>
              <span className="text-secondary/80">
                {getNodeLabel(nodes, edge.toNodeId)}
              </span>
              <span className="ml-auto text-muted-foreground/50 shrink-0">
                conf: {edge.confidenceScore.toFixed(2)} · sal:
                {edge.salienceScore.toFixed(2)}
              </span>
              {edge.salienceScore > 0.8 && edge.reinforcementCount > 3n && (
                <span className="ml-1 text-xs px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400 font-sans">
                  ⚡ consolidated
                </span>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
