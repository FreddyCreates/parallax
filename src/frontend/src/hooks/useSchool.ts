/**
 * useSchool.ts — SOVEREIGN KNOWLEDGE CANISTER React Query Hooks
 * PARALLAX · Texas TEA · TEKS Aligned · Bronze Free Tier
 * Alfredo Medina Hernandez · Creator · 2026
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useActor } from "./useActor";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface LessonTool {
  id: string;
  title: string;
  subject: string;
  teksCodes: string[];
  toolType: string;
  publicAccess: boolean;
  description: string;
}

export interface TeksStandard {
  code: string;
  grade: string;
  subject: string;
  title: string;
  description: string;
  lessonTools: LessonTool[];
}

export interface SchoolRecord {
  id: string;
  name: string;
  district: string;
  teksStandardsCodes: string[];
  canisterId: string | null | undefined;
  tier: string;
  deployed: boolean;
  grantStatus: string;
  contactEmail: string;
}

export interface GrantRecord {
  name: string;
  program: string;
  amountUsd: number;
  deadlineMs: number;
  status: string;
  notes: string;
}

// ── Public queries (no auth) ──────────────────────────────────────────────────

export function usePublicCurriculum() {
  const { actor, isFetching } = useActor();
  return useQuery<TeksStandard[]>({
    queryKey: ["school", "curriculum"],
    queryFn: async () => {
      if (!actor) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getPublicCurriculum();
      } catch {
        return SEED_STANDARDS;
      }
    },
    enabled: !isFetching,
    staleTime: 30_000,
  });
}

export function useTeksStandard(code: string) {
  const { actor, isFetching } = useActor();
  return useQuery<TeksStandard | null>({
    queryKey: ["school", "standard", code],
    queryFn: async () => {
      if (!actor || !code) return null;
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const res = await (actor as any).getTeksStandard(code);
        return res[0] ?? null;
      } catch {
        return null;
      }
    },
    enabled: !!code && !isFetching,
  });
}

export function useLessonToolsBySubject(subject: string) {
  const { actor, isFetching } = useActor();
  return useQuery<LessonTool[]>({
    queryKey: ["school", "tools", "subject", subject],
    queryFn: async () => {
      if (!actor || !subject) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getLessonToolsBySubject(subject);
      } catch {
        return [];
      }
    },
    enabled: !!subject && !isFetching,
    staleTime: 60_000,
  });
}

export function useLessonToolsByGrade(grade: string) {
  const { actor, isFetching } = useActor();
  return useQuery<LessonTool[]>({
    queryKey: ["school", "tools", "grade", grade],
    queryFn: async () => {
      if (!actor || !grade) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getLessonToolsByGrade(grade);
      } catch {
        return [];
      }
    },
    enabled: !!grade && !isFetching,
    staleTime: 60_000,
  });
}

export function useSchoolRegistry() {
  const { actor, isFetching } = useActor();
  return useQuery<SchoolRecord[]>({
    queryKey: ["school", "registry"],
    queryFn: async () => {
      if (!actor) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getSchoolRegistry();
      } catch {
        return [];
      }
    },
    enabled: !isFetching,
    staleTime: 15_000,
  });
}

export function useGrantsByStatus(status: string) {
  const { actor, isFetching } = useActor();
  return useQuery<GrantRecord[]>({
    queryKey: ["school", "grants", status],
    queryFn: async () => {
      if (!actor) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getGrantsByStatus(status);
      } catch {
        return [];
      }
    },
    enabled: !isFetching,
    staleTime: 30_000,
  });
}

// ── Creator mutations ─────────────────────────────────────────────────────────

export function useAddTeksStandard() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (std: TeksStandard) => {
      if (!actor) throw new Error("Actor not ready");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (actor as any).addTeksStandard(std);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["school", "curriculum"] });
    },
  });
}

export function useDeploySchoolCanister() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      schoolId,
      canisterId,
    }: { schoolId: string; canisterId: string }) => {
      if (!actor) throw new Error("Actor not ready");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (actor as any).deploySchoolCanister(schoolId, canisterId);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["school", "registry"] });
    },
  });
}

export function useAddLessonTool() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      teksCode,
      tool,
    }: { teksCode: string; tool: LessonTool }) => {
      if (!actor) throw new Error("Actor not ready");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (actor as any).addLessonTool(teksCode, tool);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["school", "curriculum"] });
    },
  });
}

export function useUpdateGrantStatus() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      grantName,
      status,
    }: { grantName: string; status: string }) => {
      if (!actor) throw new Error("Actor not ready");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (actor as any).updateGrantStatus(grantName, status);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["school", "grants"] });
    },
  });
}

export function useAddSchool() {
  const { actor } = useActor();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (record: SchoolRecord) => {
      if (!actor) throw new Error("Actor not ready");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (actor as any).addSchool(record);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["school", "registry"] });
    },
  });
}

// ── Seed data (fallback when backend has no data yet) ─────────────────────────

const SEED_STANDARDS: TeksStandard[] = [
  {
    code: "MATH.5.3B",
    grade: "5",
    subject: "Math",
    title: "Multiply with Decimals",
    description:
      "Multiply with fluency a three-digit number by a two-digit number using the standard algorithm.",
    lessonTools: [
      {
        id: "tool-math-5-3b-1",
        title: "Decimal Grid Interactive",
        subject: "Math",
        teksCodes: ["MATH.5.3B"],
        toolType: "interactive",
        publicAccess: true,
        description:
          "Visual grid tool for understanding decimal multiplication. Students drag grid tiles to model multiplication.",
      },
    ],
  },
  {
    code: "SCI.8.6C",
    grade: "8",
    subject: "Science",
    title: "Conservation of Energy",
    description:
      "Investigate and describe the relationship between the law of conservation of energy and the processes of photosynthesis and cellular respiration.",
    lessonTools: [
      {
        id: "tool-sci-8-6c-1",
        title: "Energy Transfer Simulation",
        subject: "Science",
        teksCodes: ["SCI.8.6C"],
        toolType: "simulation",
        publicAccess: true,
        description:
          "Simulate photosynthesis and cellular respiration cycles. Track ATP, glucose, and oxygen in real time.",
      },
    ],
  },
  {
    code: "ELA.4.RC.D",
    grade: "4",
    subject: "English",
    title: "Synthesize Information from Multiple Sources",
    description:
      "Students will synthesize information from multiple sources to create new understanding by identifying relevant information and comparing and contrasting ideas.",
    lessonTools: [
      {
        id: "tool-ela-4-rc-1",
        title: "Source Comparison Chart",
        subject: "English",
        teksCodes: ["ELA.4.RC.D"],
        toolType: "worksheet",
        publicAccess: true,
        description:
          "Guided chart for students to record and compare information from two or three sources on the same topic.",
      },
    ],
  },
  {
    code: "CS.HS.AI.1",
    grade: "High School",
    subject: "Computer Science",
    title: "Introduction to Artificial Intelligence",
    description:
      "Students explore AI concepts including machine learning, neural networks, and AI ethics. Apply computational thinking to real-world problems using AI tools.",
    lessonTools: [
      {
        id: "tool-cs-hs-ai-1",
        title: "AI Ethics Case Studies",
        subject: "Computer Science",
        teksCodes: ["CS.HS.AI.1"],
        toolType: "discussion",
        publicAccess: true,
        description:
          "Five real-world case studies exploring bias, privacy, and fairness in AI systems. Structured discussion guides included.",
      },
    ],
  },
  {
    code: "BIO.9.4A",
    grade: "9",
    subject: "Biology",
    title: "Cell Theory and Cell Structure",
    description:
      "Investigate and explain the cell theory and cellular structures and their functions, including cell wall, cell membrane, nucleus, cytoplasm, mitochondria, and chloroplasts.",
    lessonTools: [
      {
        id: "tool-bio-9-4a-1",
        title: "Cell Organelle Builder",
        subject: "Biology",
        teksCodes: ["BIO.9.4A"],
        toolType: "interactive",
        publicAccess: true,
        description:
          "Drag-and-drop cell builder tool. Students assemble plant and animal cells, label organelles, and match functions.",
      },
    ],
  },
  {
    code: "ALG1.6A",
    grade: "High School",
    subject: "Algebra",
    title: "Quadratic Functions and Equations",
    description:
      "Determine the domain and range of quadratic functions and represent the domain and range using inequalities.",
    lessonTools: [
      {
        id: "tool-alg1-6a-1",
        title: "Parabola Explorer",
        subject: "Algebra",
        teksCodes: ["ALG1.6A"],
        toolType: "graphing",
        publicAccess: true,
        description:
          "Interactive parabola graphing tool. Adjust a, b, c values and instantly see domain, range, vertex, and axis of symmetry.",
      },
    ],
  },
];
