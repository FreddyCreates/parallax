// @ts-nocheck
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";
import { NodeType, RelationshipType } from "../backend";
import type { GraphEdge, GraphNode } from "../backend";
import { useActor } from "./useActor";

export type { GraphNode, GraphEdge };
export { NodeType, RelationshipType };

export function useGraph() {
  const { actor, isFetching } = useActor();
  const queryClient = useQueryClient();

  const graphQuery = useQuery<{ nodes: GraphNode[]; edges: GraphEdge[] }>({
    queryKey: ["graph"],
    queryFn: async () => {
      if (!actor) return { nodes: [], edges: [] };
      return actor.getFullGraph();
    },
    enabled: !!actor && !isFetching,
    staleTime: 5_000,
  });

  const topEdgesQuery = useQuery<GraphEdge[]>({
    queryKey: ["topEdges"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.getTopEdgesBySalience(5n);
    },
    enabled: !!actor && !isFetching,
    staleTime: 5_000,
  });

  const invalidateGraph = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ["graph"] });
    queryClient.invalidateQueries({ queryKey: ["topEdges"] });
  }, [queryClient]);

  const addNode = useCallback(
    async (labelText: string, nodeType: NodeType) => {
      if (!actor) return;
      const id = crypto.randomUUID();
      await actor.createNode(id, labelText, nodeType);
      invalidateGraph();
      return id;
    },
    [actor, invalidateGraph],
  );

  const removeNode = useCallback(
    async (id: string) => {
      if (!actor) return;
      await actor.deleteNode(id);
      invalidateGraph();
    },
    [actor, invalidateGraph],
  );

  const addEdge = useCallback(
    async (
      fromNodeId: string,
      toNodeId: string,
      relationshipType: RelationshipType,
      confidenceScore: number,
      salienceScore: number,
    ) => {
      if (!actor) return;
      const id = crypto.randomUUID();
      await actor.createEdge(
        id,
        fromNodeId,
        toNodeId,
        relationshipType,
        confidenceScore,
        salienceScore,
      );
      invalidateGraph();
      return id;
    },
    [actor, invalidateGraph],
  );

  const removeEdge = useCallback(
    async (id: string) => {
      if (!actor) return;
      await actor.deleteEdge(id);
      invalidateGraph();
    },
    [actor, invalidateGraph],
  );

  return {
    nodes: graphQuery.data?.nodes ?? [],
    edges: graphQuery.data?.edges ?? [],
    topEdges: topEdgesQuery.data ?? [],
    isLoading: graphQuery.isLoading,
    refetch: invalidateGraph,
    addNode,
    removeNode,
    addEdge,
    removeEdge,
  };
}
