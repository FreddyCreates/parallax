// @ts-nocheck
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useState } from "react";
import { MessageRole } from "../backend";
import type { GraphEdge, GraphNode, Message, Session } from "../backend";
import { type NodeType, RelationshipType } from "../backend";
import { extractEntities } from "../utils/extraction";
import { useActor } from "./useActor";

export type { Session, Message };

type GraphCacheData = { nodes: GraphNode[]; edges: GraphEdge[] };

function buildContextualReply(
  userMessage: string,
  nodes: GraphNode[],
  edges: GraphEdge[],
): string {
  const lowerMsg = userMessage.toLowerCase();

  // Find nodes whose labels appear in the user's message
  const mentionedNodes = nodes.filter((n) =>
    lowerMsg.includes(n.labelText.toLowerCase()),
  );

  // If no direct mention, pick the 3 most recently created nodes
  const relevantNodes =
    mentionedNodes.length > 0
      ? mentionedNodes.slice(0, 3)
      : nodes.slice(-3).reverse();

  // Find edges between relevant nodes
  const relevantNodeIds = new Set(relevantNodes.map((n) => n.id));
  const relevantEdges = edges.filter(
    (e) => relevantNodeIds.has(e.fromNodeId) && relevantNodeIds.has(e.toNodeId),
  );

  if (nodes.length === 0) {
    return "I've processed your message and updated my memory structure. No prior concepts exist yet — this forms the foundation of my knowledge graph.";
  }

  if (relevantEdges.length > 0) {
    const edge = relevantEdges[0];
    const fromNode = nodes.find((n) => n.id === edge.fromNodeId);
    const toNode = nodes.find((n) => n.id === edge.toNodeId);
    if (fromNode && toNode) {
      const extra =
        relevantNodes.length > 2
          ? ` I also see ${relevantNodes
              .slice(2)
              .map((n) => n.labelText)
              .join(", ")} nearby in my graph.`
          : "";
      return `My memory graph shows \"${fromNode.labelText}\" and \"${toNode.labelText}\" are connected via ${edge.relationshipType}. Your message builds directly on that context.${extra}`;
    }
  }

  if (relevantNodes.length >= 2) {
    const [a, b] = relevantNodes;
    const edgeCount = edges.length;
    return `I've linked what you said about \"${a.labelText}\" to the existing \"${b.labelText}\" concept in my memory graph. That association is now reinforced. My graph currently holds ${nodes.length} nodes across ${edgeCount} relationship${edgeCount !== 1 ? "s" : ""}.`;
  }

  if (relevantNodes.length === 1) {
    const [node] = relevantNodes;
    const connectedEdges = edges.filter(
      (e) => e.fromNodeId === node.id || e.toNodeId === node.id,
    );
    return `Your mention of \"${node.labelText}\" has been recorded. I've added it to my knowledge graph with ${connectedEdges.length} connection${connectedEdges.length !== 1 ? "s" : ""} so far.`;
  }

  const newest = nodes[nodes.length - 1];
  return `I've processed your message and updated my memory structure. The concept \"${newest.labelText}\" is now part of my knowledge graph alongside ${nodes.length - 1} other node${nodes.length - 1 !== 1 ? "s" : ""}.`;
}

export function useChat() {
  const { actor, isFetching } = useActor();
  const queryClient = useQueryClient();
  const [currentSessionId, setCurrentSessionId] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);

  const sessionsQuery = useQuery<Session[]>({
    queryKey: ["sessions"],
    queryFn: async () => {
      if (!actor) return [];
      const sessions = await actor.getAllSessions();
      return sessions.sort((a, b) => (a.createdAt > b.createdAt ? -1 : 1));
    },
    enabled: !!actor && !isFetching,
  });

  const messagesQuery = useQuery<Message[]>({
    queryKey: ["messages", currentSessionId],
    queryFn: async () => {
      if (!actor || !currentSessionId) return [];
      const msgs = await actor.getMessagesForSession(currentSessionId);
      return msgs.sort((a, b) => (a.timestamp > b.timestamp ? 1 : -1));
    },
    enabled: !!actor && !isFetching && !!currentSessionId,
  });

  const createSession = useCallback(
    async (title?: string) => {
      if (!actor) return;
      const id = crypto.randomUUID();
      const sessionTitle =
        title ||
        `Chat ${new Date().toLocaleDateString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}`;
      await actor.createSession(id, sessionTitle);
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      setCurrentSessionId(id);
      return id;
    },
    [actor, queryClient],
  );

  const deleteSession = useCallback(
    async (id: string) => {
      if (!actor) return;
      await actor.deleteSession(id);
      queryClient.invalidateQueries({ queryKey: ["sessions"] });
      if (currentSessionId === id) {
        setCurrentSessionId(null);
      }
    },
    [actor, queryClient, currentSessionId],
  );

  const sendMessage = useCallback(
    async (content: string) => {
      if (!actor || !currentSessionId || !content.trim() || isSending) return;

      setIsSending(true);
      try {
        // 1. Save user message
        const userMsgId = crypto.randomUUID();
        await actor.addMessage(
          userMsgId,
          currentSessionId,
          MessageRole.user,
          content.trim(),
        );

        // 2. Extract entities
        const entities = extractEntities(content);

        if (entities.length > 0) {
          // 3. Get existing nodes for deduplication
          const cachedGraph = queryClient.getQueryData<GraphCacheData>([
            "graph",
          ]);
          const existingNodes = cachedGraph?.nodes ?? [];

          const nodeIds: string[] = [];
          for (const entity of entities) {
            const existing = existingNodes.find(
              (n) => n.labelText.toLowerCase() === entity.label.toLowerCase(),
            );
            if (existing) {
              nodeIds.push(existing.id);
            } else {
              const nodeId = crypto.randomUUID();
              await actor.createNode(
                nodeId,
                entity.label,
                entity.type as NodeType,
              );
              nodeIds.push(nodeId);
            }
          }

          // 4. Create edges between consecutive nodes
          for (let i = 0; i < nodeIds.length - 1; i++) {
            const edgeId = crypto.randomUUID();
            await actor.createEdge(
              edgeId,
              nodeIds[i],
              nodeIds[i + 1],
              RelationshipType.association,
              0.7,
              0.5,
            );
          }
        }

        // 5. Fetch fresh graph for context-aware reply
        let graphNodes: GraphNode[] = [];
        let graphEdges: GraphEdge[] = [];
        try {
          const freshGraph = await actor.getFullGraph();
          graphNodes = freshGraph.nodes;
          graphEdges = freshGraph.edges;
          // Update cache
          queryClient.setQueryData(["graph"], freshGraph);
        } catch {
          const cached = queryClient.getQueryData<GraphCacheData>(["graph"]);
          graphNodes = cached?.nodes ?? [];
          graphEdges = cached?.edges ?? [];
        }

        // 6. Build context-aware AI reply
        const reply = buildContextualReply(content, graphNodes, graphEdges);
        const aiMsgId = crypto.randomUUID();
        await actor.addMessage(
          aiMsgId,
          currentSessionId,
          MessageRole.ai,
          reply,
        );

        // 7. Invalidate all relevant queries
        queryClient.invalidateQueries({
          queryKey: ["messages", currentSessionId],
        });
        queryClient.invalidateQueries({ queryKey: ["graph"] });
        queryClient.invalidateQueries({ queryKey: ["topEdges"] });
      } finally {
        setIsSending(false);
      }
    },
    [actor, currentSessionId, isSending, queryClient],
  );

  return {
    sessions: sessionsQuery.data ?? [],
    messages: messagesQuery.data ?? [],
    isLoadingSessions: sessionsQuery.isLoading,
    isLoadingMessages: messagesQuery.isLoading,
    currentSessionId,
    setCurrentSessionId,
    isSending,
    createSession,
    deleteSession,
    sendMessage,
  };
}
