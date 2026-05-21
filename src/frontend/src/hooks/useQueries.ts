// @ts-nocheck
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { MessageRole, NodeType, RelationshipType } from "../backend.d";
import { useActor } from "./useActor";

// ── Schumann State Type ────────────────────────────────────────────────────
// Mirrors the backend getSchumannState() return structure exactly.
// Real physics constants — not placeholders.
export interface SchumannState {
  fundamentalHz: number; // 7.83 Hz — Earth's ionospheric cavity fundamental
  harmonics: number[]; // [14.3, 20.8, 27.3, 33.8] Hz — 2nd through 5th harmonics
  schumannPhase: number; // radians, 0 to 2π — current phase of fundamental oscillator
  silverAnchorHz: number; // 2.75 Hz — sovereign subharmonic, always beneath the carrier
  silverAnchorPhase: number; // radians — current phase of silver anchor oscillator
  silverAnchorSubharmonicRatio: number; // 2.847... = 7.83 / 2.75 — the exact harmonic ratio
  couplingStrength: number; // K_EXT × kuramotoR, range 0 to 0.15
  kuramotoR: number; // collective phase-lock order parameter, range 0 to 1
}

export function useAllSessions() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["sessions"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.getAllSessions();
    },
    enabled: !!actor && !isFetching,
  });
}

export function useSessionMessages(sessionId: string | null) {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["messages", sessionId],
    queryFn: async () => {
      if (!actor || !sessionId) return [];
      return actor.getMessagesForSession(sessionId);
    },
    enabled: !!actor && !isFetching && !!sessionId,
  });
}

export function useFullGraph() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["graph"],
    queryFn: async () => {
      if (!actor) return { nodes: [], edges: [] };
      return actor.getFullGraph();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });
}

export function useUserProfile() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["profile"],
    queryFn: async () => {
      if (!actor) return null;
      return actor.getCallerUserProfile();
    },
    enabled: !!actor && !isFetching,
  });
}

export function useCreateSession() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ id, title }: { id: string; title: string }) => {
      if (!actor) throw new Error("No actor");
      await actor.createSession(id, title);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["sessions"] }),
  });
}

export function useDeleteSession() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      if (!actor) throw new Error("No actor");
      await actor.deleteSession(id);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["sessions"] }),
  });
}

export function useAddMessage() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      sessionId,
      role,
      content,
    }: {
      id: string;
      sessionId: string;
      role: MessageRole;
      content: string;
    }) => {
      if (!actor) throw new Error("No actor");
      await actor.addMessage(id, sessionId, role, content);
    },
    onSuccess: (_data, vars) =>
      qc.invalidateQueries({ queryKey: ["messages", vars.sessionId] }),
  });
}

export function useCreateNode() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      labelText,
      nodeType,
    }: {
      id: string;
      labelText: string;
      nodeType: NodeType;
    }) => {
      if (!actor) throw new Error("No actor");
      await actor.createNode(id, labelText, nodeType);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["graph"] }),
  });
}

export function useCreateEdge() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      fromNodeId,
      toNodeId,
      relationshipType,
      confidenceScore,
      salienceScore,
    }: {
      id: string;
      fromNodeId: string;
      toNodeId: string;
      relationshipType: RelationshipType;
      confidenceScore: number;
      salienceScore: number;
    }) => {
      if (!actor) throw new Error("No actor");
      await actor.createEdge(
        id,
        fromNodeId,
        toNodeId,
        relationshipType,
        confidenceScore,
        salienceScore,
      );
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["graph"] }),
  });
}

export function useDeleteNode() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      if (!actor) throw new Error("No actor");
      await actor.deleteNode(id);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["graph"] }),
  });
}

export function useDeleteEdge() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      if (!actor) throw new Error("No actor");
      await actor.deleteEdge(id);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["graph"] }),
  });
}

export function useIncrementEdgeReinforcement() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (id: string) => {
      if (!actor) throw new Error("No actor");
      await actor.incrementEdgeReinforcement(id);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["graph"] }),
  });
}

export function useSaveProfile() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (name: string) => {
      if (!actor) throw new Error("No actor");
      await actor.saveCallerUserProfile({ name });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["profile"] }),
  });
}

// ── Schumann Field State ───────────────────────────────────────────────────
// Polls the organism's Schumann coupling state every 3000ms.
// 3 seconds matches the organism's heartbeat tempo — not faster, not slower.
// The Schumann resonance is always running. This query reads the organism's
// current phase-lock relationship with the Earth's EM cavity.
export function useSchumannState() {
  const { actor, isFetching } = useActor();
  return useQuery<SchumannState | null>({
    queryKey: ["schumannState"],
    queryFn: async () => {
      if (!actor) return null;
      return actor.getSchumannState() as Promise<SchumannState>;
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 3000,
  });
}

// ── AGI Script Status — DOMUS LIBERATORIS ─────────────────────────────────
// Polls all seven sovereign AGI scripts: EXPLORATOR, GUBERNATOR, CUSTODITOR,
// COMPUTATOR, DISPENSATOR, LIBERATOR, MEMORIA_NNS.
// These are the autonomous agents that run the NNS generation loop.
export function useAgiStatus() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["agiStatus"],
    queryFn: async () => {
      if (!actor) return null;
      return actor.getAgiStatus();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 5000,
  });
}

// ── Withdrawal Log — ANIMA CHAIN ──────────────────────────────────────────
// Every LIBERATOR execution writes a permanent receipt here.
// The log is the proof. The proof is on-chain.
export function useWithdrawalLog() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["withdrawalLog"],
    queryFn: async () => {
      if (!actor) return [];
      return actor.getWithdrawalLog();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 10000,
  });
}

// ── MEMORIA_NNS — Sovereign Law Doctrine ─────────────────────────────────
// The permanent sovereign law: THE ORGANISM IS THE FUNDING MECHANISM.
// Never changes. Never collapses. Queried by every AGI on every beat.
export function useMemoriaNns() {
  const { actor, isFetching } = useActor();
  return useQuery({
    queryKey: ["memoriaNns"],
    queryFn: async () => {
      if (!actor) return null;
      return actor.getMemoriaNns();
    },
    enabled: !!actor && !isFetching,
    refetchInterval: 30000,
  });
}
