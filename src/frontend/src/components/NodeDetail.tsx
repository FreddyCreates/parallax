import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Clock, GitBranch, Trash2, X } from "lucide-react";
import type { GraphEdge, GraphNode } from "../hooks/useGraph";
import { NodeType } from "../hooks/useGraph";
import { formatRelativeTime } from "../utils/formatting";

const NODE_TYPE_COLORS: Record<NodeType, string> = {
  [NodeType.concept]: "bg-cyan-500/20 text-cyan-300 border-cyan-500/30",
  [NodeType.memory]: "bg-violet-500/20 text-violet-300 border-violet-500/30",
  [NodeType.knowledge]: "bg-amber-500/20 text-amber-300 border-amber-500/30",
  [NodeType.aiSystem]: "bg-slate-500/20 text-slate-300 border-slate-500/30",
};

interface Props {
  node: GraphNode;
  edges: GraphEdge[];
  nodes: GraphNode[];
  onClose: () => void;
  onDeleteNode: (id: string) => void;
  onDeleteEdge: (id: string) => void;
}

export function NodeDetail({
  node,
  edges,
  nodes,
  onClose,
  onDeleteNode,
  onDeleteEdge,
}: Props) {
  const connectedEdges = edges.filter(
    (e) => e.fromNodeId === node.id || e.toNodeId === node.id,
  );

  function getLabel(id: string) {
    return nodes.find((n) => n.id === id)?.labelText ?? id.slice(0, 8);
  }

  return (
    <div
      className="absolute right-0 top-0 h-full w-72 bg-card border-l border-border flex flex-col shadow-2xl z-10"
      data-ocid="graph.node.panel"
    >
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-border">
        <div className="flex flex-col gap-1 min-w-0">
          <span className="font-display font-semibold text-foreground truncate">
            {node.labelText}
          </span>
          <Badge
            variant="outline"
            className={`w-fit text-xs ${NODE_TYPE_COLORS[node.nodeType]}`}
          >
            {node.nodeType}
          </Badge>
        </div>
        <Button
          variant="ghost"
          size="icon"
          onClick={onClose}
          className="shrink-0 text-muted-foreground hover:text-foreground"
          data-ocid="graph.node.close_button"
        >
          <X className="w-4 h-4" />
        </Button>
      </div>

      {/* Meta */}
      <div className="px-4 py-3 border-b border-border flex items-center gap-2 text-xs text-muted-foreground">
        <Clock className="w-3.5 h-3.5" />
        <span>Created {formatRelativeTime(node.createdAt)}</span>
      </div>

      {/* Edges */}
      <ScrollArea className="flex-1">
        <div className="p-4">
          <div className="flex items-center gap-2 mb-3">
            <GitBranch className="w-3.5 h-3.5 text-muted-foreground" />
            <span className="text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Connections ({connectedEdges.length})
            </span>
          </div>
          {connectedEdges.length === 0 ? (
            <p className="text-xs text-muted-foreground italic">
              No connections yet.
            </p>
          ) : (
            <div className="flex flex-col gap-2">
              {connectedEdges.map((edge, idx) => (
                <div
                  key={edge.id}
                  className="bg-background rounded-lg p-3 border border-border text-xs group"
                  data-ocid={`graph.edge.item.${idx + 1}`}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-mono text-muted-foreground">
                      {edge.relationshipType}
                    </span>
                    {edge.salienceScore > 0.8 &&
                      edge.reinforcementCount > 3n && (
                        <span className="text-xs px-1.5 py-0.5 rounded bg-amber-500/20 text-amber-400">
                          ⚡
                        </span>
                      )}
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-5 w-5 opacity-0 group-hover:opacity-100 text-destructive hover:text-destructive"
                      onClick={() => onDeleteEdge(edge.id)}
                      data-ocid={`graph.edge.delete_button.${idx + 1}`}
                    >
                      <X className="w-3 h-3" />
                    </Button>
                  </div>
                  <div className="font-mono text-muted-foreground/80">
                    {edge.fromNodeId === node.id ? (
                      <>
                        <span className="text-primary/80">
                          {node.labelText}
                        </span>
                        {" → "}
                        <span className="text-secondary/80">
                          {getLabel(edge.toNodeId)}
                        </span>
                      </>
                    ) : (
                      <>
                        <span className="text-secondary/80">
                          {getLabel(edge.fromNodeId)}
                        </span>
                        {" → "}
                        <span className="text-primary/80">
                          {node.labelText}
                        </span>
                      </>
                    )}
                  </div>
                  <div className="mt-1.5 flex gap-3 text-muted-foreground/60">
                    <span>conf: {edge.confidenceScore.toFixed(2)}</span>
                    <span>sal: {edge.salienceScore.toFixed(2)}</span>
                    <span>×{edge.reinforcementCount.toString()}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </ScrollArea>

      {/* Footer */}
      <div className="p-4 border-t border-border">
        <Button
          variant="destructive"
          size="sm"
          className="w-full gap-2"
          onClick={() => onDeleteNode(node.id)}
          data-ocid="graph.node.delete_button"
        >
          <Trash2 className="w-3.5 h-3.5" />
          Delete Node
        </Button>
      </div>
    </div>
  );
}
