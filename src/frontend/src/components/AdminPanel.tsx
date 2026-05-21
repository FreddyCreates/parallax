import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Loader2, Trash2 } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import type { GraphEdge, GraphNode } from "../hooks/useGraph";
import { useGraph } from "../hooks/useGraph";

function formatDate(ts: bigint): string {
  try {
    return new Date(Number(ts / 1_000_000n)).toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "—";
  }
}

function NodesTab({
  nodes,
  onDeleteNode,
}: {
  nodes: GraphNode[];
  onDeleteNode: (id: string) => Promise<void>;
}) {
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [clearConfirm, setClearConfirm] = useState(false);
  const [isClearing, setIsClearing] = useState(false);

  const handleDelete = async (id: string) => {
    setDeletingId(id);
    try {
      await onDeleteNode(id);
      toast.success("Node deleted");
    } catch {
      toast.error("Failed to delete node");
    } finally {
      setDeletingId(null);
    }
  };

  const handleClearAll = async () => {
    if (!clearConfirm) {
      setClearConfirm(true);
      return;
    }
    setIsClearing(true);
    setClearConfirm(false);
    try {
      await Promise.all(nodes.map((n) => onDeleteNode(n.id)));
      toast.success("All nodes cleared");
    } catch {
      toast.error("Failed to clear all nodes");
    } finally {
      setIsClearing(false);
    }
  };

  if (nodes.length === 0) {
    return (
      <div
        className="flex flex-col items-center justify-center py-16 text-center gap-2"
        data-ocid="admin.nodes.empty_state"
      >
        <p className="text-sm text-muted-foreground">
          No nodes in the graph yet.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <ScrollArea className="flex-1">
        <Table data-ocid="admin.nodes.table">
          <TableHeader>
            <TableRow>
              <TableHead>Label</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Created</TableHead>
              <TableHead className="w-10" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {nodes.map((node, i) => (
              <TableRow key={node.id} data-ocid={`admin.nodes.item.${i + 1}`}>
                <TableCell className="font-medium text-sm max-w-[140px] truncate">
                  {node.labelText}
                </TableCell>
                <TableCell className="text-xs text-muted-foreground capitalize">
                  {node.nodeType}
                </TableCell>
                <TableCell className="text-xs text-muted-foreground">
                  {formatDate(node.createdAt)}
                </TableCell>
                <TableCell>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 text-muted-foreground hover:text-destructive"
                    onClick={() => handleDelete(node.id)}
                    disabled={deletingId === node.id}
                    data-ocid={`admin.nodes.delete_button.${i + 1}`}
                  >
                    {deletingId === node.id ? (
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                    ) : (
                      <Trash2 className="w-3.5 h-3.5" />
                    )}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </ScrollArea>
      <div className="pt-3 border-t border-border shrink-0">
        <Button
          variant="destructive"
          size="sm"
          className="w-full gap-2 text-xs"
          onClick={handleClearAll}
          disabled={isClearing}
          data-ocid="admin.nodes.delete_button"
        >
          {isClearing ? (
            <Loader2 className="w-3.5 h-3.5 animate-spin" />
          ) : (
            <Trash2 className="w-3.5 h-3.5" />
          )}
          {isClearing
            ? "Clearing…"
            : clearConfirm
              ? "Confirm clear all?"
              : "Clear all nodes"}
        </Button>
      </div>
    </div>
  );
}

function EdgesTab({
  edges,
  nodes,
  onDeleteEdge,
}: {
  edges: GraphEdge[];
  nodes: GraphNode[];
  onDeleteEdge: (id: string) => Promise<void>;
}) {
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [clearConfirm, setClearConfirm] = useState(false);
  const [isClearing, setIsClearing] = useState(false);

  const nodeLabel = (id: string) =>
    nodes.find((n) => n.id === id)?.labelText ?? id.slice(0, 8);

  const handleDelete = async (id: string) => {
    setDeletingId(id);
    try {
      await onDeleteEdge(id);
      toast.success("Edge deleted");
    } catch {
      toast.error("Failed to delete edge");
    } finally {
      setDeletingId(null);
    }
  };

  const handleClearAll = async () => {
    if (!clearConfirm) {
      setClearConfirm(true);
      return;
    }
    setIsClearing(true);
    setClearConfirm(false);
    try {
      await Promise.all(edges.map((e) => onDeleteEdge(e.id)));
      toast.success("All edges cleared");
    } catch {
      toast.error("Failed to clear all edges");
    } finally {
      setIsClearing(false);
    }
  };

  if (edges.length === 0) {
    return (
      <div
        className="flex flex-col items-center justify-center py-16 text-center gap-2"
        data-ocid="admin.edges.empty_state"
      >
        <p className="text-sm text-muted-foreground">
          No edges in the graph yet.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      <ScrollArea className="flex-1">
        <Table data-ocid="admin.edges.table">
          <TableHeader>
            <TableRow>
              <TableHead>From → To</TableHead>
              <TableHead>Relationship</TableHead>
              <TableHead>Salience</TableHead>
              <TableHead>Reinforced</TableHead>
              <TableHead className="w-10" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {edges.map((edge, i) => (
              <TableRow key={edge.id} data-ocid={`admin.edges.item.${i + 1}`}>
                <TableCell className="text-xs max-w-[130px]">
                  <span className="font-medium truncate block">
                    {nodeLabel(edge.fromNodeId)}
                  </span>
                  <span className="text-muted-foreground">↓</span>
                  <span className="font-medium truncate block">
                    {nodeLabel(edge.toNodeId)}
                  </span>
                </TableCell>
                <TableCell className="text-xs text-muted-foreground capitalize">
                  {edge.relationshipType}
                </TableCell>
                <TableCell className="text-xs">
                  {(edge.salienceScore * 100).toFixed(0)}%
                </TableCell>
                <TableCell className="text-xs">
                  {edge.reinforcementCount.toString()}×
                </TableCell>
                <TableCell>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 text-muted-foreground hover:text-destructive"
                    onClick={() => handleDelete(edge.id)}
                    disabled={deletingId === edge.id}
                    data-ocid={`admin.edges.delete_button.${i + 1}`}
                  >
                    {deletingId === edge.id ? (
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                    ) : (
                      <Trash2 className="w-3.5 h-3.5" />
                    )}
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </ScrollArea>
      <div className="pt-3 border-t border-border shrink-0">
        <Button
          variant="destructive"
          size="sm"
          className="w-full gap-2 text-xs"
          onClick={handleClearAll}
          disabled={isClearing}
          data-ocid="admin.edges.delete_button"
        >
          {isClearing ? (
            <Loader2 className="w-3.5 h-3.5 animate-spin" />
          ) : (
            <Trash2 className="w-3.5 h-3.5" />
          )}
          {isClearing
            ? "Clearing…"
            : clearConfirm
              ? "Confirm clear all?"
              : "Clear all edges"}
        </Button>
      </div>
    </div>
  );
}

export function AdminPanel({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { nodes, edges, removeNode, removeEdge } = useGraph();

  return (
    <Sheet open={open} onOpenChange={(v) => !v && onClose()}>
      <SheetContent
        side="right"
        className="w-[500px] sm:w-[500px] flex flex-col p-0"
        data-ocid="admin.panel"
      >
        <SheetHeader className="px-6 pt-6 pb-4 border-b border-border shrink-0">
          <SheetTitle className="text-base">Memory Admin</SheetTitle>
          <p className="text-xs text-muted-foreground">
            View and manage all nodes and edges in your knowledge graph.
          </p>
        </SheetHeader>

        <div className="flex-1 overflow-hidden px-6 pb-6 pt-4">
          <Tabs defaultValue="nodes" className="h-full flex flex-col">
            <TabsList className="w-full shrink-0 mb-4">
              <TabsTrigger
                value="nodes"
                className="flex-1"
                data-ocid="admin.nodes.tab"
              >
                Nodes
                <span className="ml-1.5 text-xs text-muted-foreground">
                  ({nodes.length})
                </span>
              </TabsTrigger>
              <TabsTrigger
                value="edges"
                className="flex-1"
                data-ocid="admin.edges.tab"
              >
                Edges
                <span className="ml-1.5 text-xs text-muted-foreground">
                  ({edges.length})
                </span>
              </TabsTrigger>
            </TabsList>

            <TabsContent value="nodes" className="flex-1 overflow-hidden mt-0">
              <NodesTab nodes={nodes} onDeleteNode={removeNode} />
            </TabsContent>

            <TabsContent value="edges" className="flex-1 overflow-hidden mt-0">
              <EdgesTab edges={edges} nodes={nodes} onDeleteEdge={removeEdge} />
            </TabsContent>
          </Tabs>
        </div>
      </SheetContent>
    </Sheet>
  );
}
