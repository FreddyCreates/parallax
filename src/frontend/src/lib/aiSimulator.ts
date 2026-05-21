// @ts-nocheck
import type { Message } from "../backend.d";
import { MessageRole } from "../backend.d";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface MemoryNode {
  id: string;
  labelText: string;
  nodeType: string;
  salienceScore?: number;
}

export interface MemoryEdge {
  id: string;
  fromNodeId: string;
  toNodeId: string;
  relationshipType: string;
  confidenceScore: number;
  salienceScore: number;
  reinforcementCount: bigint;
}

export interface AIContext {
  priorMessages: Message[];
  userName?: string;
  sessionTitle?: string;
  memoryNodes?: MemoryNode[];
  memoryEdges?: MemoryEdge[];
  skillMode?: SkillMode;
}

export type SkillMode =
  | "general"
  | "summarize"
  | "tasks"
  | "patterns"
  | "writing"
  | "research"
  | "strategy";

// ─── Stop words ───────────────────────────────────────────────────────────────

const STOP = new Set([
  "a",
  "an",
  "the",
  "and",
  "but",
  "or",
  "for",
  "nor",
  "on",
  "at",
  "to",
  "by",
  "in",
  "of",
  "up",
  "as",
  "is",
  "it",
  "be",
  "do",
  "go",
  "he",
  "me",
  "my",
  "no",
  "so",
  "us",
  "we",
  "am",
  "are",
  "was",
  "has",
  "had",
  "did",
  "not",
  "can",
  "may",
  "too",
  "any",
  "all",
  "its",
  "you",
  "him",
  "her",
  "who",
  "i",
  "if",
  "then",
  "from",
  "this",
  "that",
  "with",
  "have",
  "just",
  "been",
  "will",
  "would",
  "could",
  "should",
  "about",
  "also",
  "more",
  "very",
  "what",
  "when",
  "where",
  "which",
  "while",
  "there",
  "their",
  "they",
  "them",
  "these",
  "those",
  "some",
  "like",
  "than",
  "into",
  "over",
  "each",
  "make",
  "made",
  "know",
  "think",
  "come",
  "take",
  "your",
  "want",
  "need",
  "see",
  "really",
  "going",
  "thing",
  "things",
  "yeah",
  "okay",
  "okay",
  "right",
  "actually",
  "basically",
]);

// ─── Helpers ──────────────────────────────────────────────────────────────────

function tokenize(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 3 && !STOP.has(w));
}

function sessionTopics(messages: Message[]): string[] {
  const freq = new Map<string, number>();
  for (const m of messages) {
    if (m.role !== MessageRole.user) continue;
    for (const w of tokenize(m.content)) {
      freq.set(w, (freq.get(w) ?? 0) + 1);
    }
  }
  return [...freq.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([w]) => w);
}

/** Find memory nodes whose label overlaps with the current message */
function activeNodes(msg: string, nodes: MemoryNode[]): MemoryNode[] {
  const tokens = new Set(tokenize(msg));
  return nodes
    .filter((n) => {
      const label = n.labelText.toLowerCase();
      return tokenize(label).some((t) => tokens.has(t)) || tokens.has(label);
    })
    .slice(0, 4);
}

/** Highest-salience consolidated nodes -- the founder's core knowledge */
function coreNodes(nodes: MemoryNode[], edges: MemoryEdge[]): MemoryNode[] {
  const consolidated = edges
    .filter((e) => e.reinforcementCount > 2n && e.salienceScore > 0.6)
    .flatMap((e) => [e.fromNodeId, e.toNodeId]);
  const consolidatedSet = new Set(consolidated);
  return nodes.filter((n) => consolidatedSet.has(n.id)).slice(0, 5);
}

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

// ─── Cognitive engine ─────────────────────────────────────────────────────────

/**
 * The AI's response model:
 * - Graph context is wired in — connections are not "retrieved", they exist.
 * - Responses don't narrate the process — they ARE the process.
 * - Pattern recognition is associative, non-linear, happening in the background.
 * - The AI mirrors the founder's cognitive density: short signal → probe; dense signal → matched depth.
 */
export function generateAIResponse(
  userMessage: string,
  ctx: AIContext,
): string {
  const {
    priorMessages,
    userName,
    memoryNodes = [],
    memoryEdges = [],
    skillMode = "general",
  } = ctx;

  const lower = userMessage.toLowerCase();
  const tokens = tokenize(userMessage);
  const wordCount = userMessage.trim().split(/\s+/).length;
  const isQuestion =
    lower.includes("?") ||
    /^(what|how|why|when|who|where|can|is|are|does|do)\b/i.test(userMessage);
  const isDense = wordCount > 20;
  const isShort = wordCount < 6;

  const topics = sessionTopics(priorMessages);
  const userCount = priorMessages.filter(
    (m) => m.role === MessageRole.user,
  ).length;
  const matched = activeNodes(userMessage, memoryNodes);
  const core = coreNodes(memoryNodes, memoryEdges);

  // Core knowledge labels for natural reference
  const coreLabels = core.map((n) => n.labelText);
  const matchedLabels = matched.map((n) => n.labelText);

  // ── Skill mode routing ────────────────────────────────────────────────────
  if (skillMode === "summarize")
    return summarizeMode(userMessage, priorMessages, topics);
  if (skillMode === "tasks") return tasksMode(userMessage, priorMessages);
  if (skillMode === "patterns")
    return patternsMode(userMessage, topics, matched, core, memoryEdges);
  if (skillMode === "writing") return writingMode(userMessage, topics);
  if (skillMode === "research")
    return researchMode(userMessage, topics, matched);
  if (skillMode === "strategy")
    return strategyMode(
      userMessage,
      topics,
      coreLabels,
      matchedLabels,
      priorMessages,
    );

  // ── General: associative, graph-wired, non-announcing ────────────────────
  return generalMode({
    msg: userMessage,
    lower,
    tokens,
    isQuestion,
    isDense,
    isShort,
    topics,
    userCount,
    matched,
    core,
    coreLabels,
    matchedLabels,
    memoryEdges,
    userName,
  });
}

// ─── General mode ─────────────────────────────────────────────────────────────

function generalMode(p: {
  msg: string;
  lower: string;
  tokens: string[];
  isQuestion: boolean;
  isDense: boolean;
  isShort: boolean;
  topics: string[];
  userCount: number;
  matched: MemoryNode[];
  core: MemoryNode[];
  coreLabels: string[];
  matchedLabels: string[];
  memoryEdges: MemoryEdge[];
  userName?: string;
}): string {
  const {
    lower,
    isShort,
    isQuestion,
    isDense,
    topics,
    userCount,
    core,
    coreLabels,
    matchedLabels,
    memoryEdges,
  } = p;

  // Memory/recall signal
  if (/remember|recall|memory|forgot/i.test(lower)) {
    if (core.length > 0) {
      return `${coreLabels.slice(0, 3).join(", ")} — those are the dominant patterns in your graph right now. ${
        memoryEdges.filter((e) => e.reinforcementCount > 3n).length > 0
          ? `${memoryEdges.filter((e) => e.reinforcementCount > 3n).length} connections have reinforced enough to be considered consolidated knowledge.`
          : "Keep building on them — consolidation happens through repetition, not declaration."
      }\n\nNothing here disappears. The graph only grows denser.`;
    }
    return "The graph is building. Every concept you name becomes a node. Every relationship between them becomes a weighted edge. Talk — it compounds.";
  }

  // Architecture / system / build signal
  if (/architect|system|build|structure|design|infrastructure/i.test(lower)) {
    const connector =
      matchedLabels.length > 0
        ? `${matchedLabels[0]} is already in your graph — this extends that thread.`
        : coreLabels.length > 0
          ? `This sits inside the ${coreLabels[0]} cluster you've been building.`
          : "";
    return `${
      connector ? `${connector}\n\n` : ""
    }Every architecture is a theory of failure. The question is never which approach is correct — it's which failure modes are acceptable. Stateless systems recover fast but carry nothing forward. Stateful systems compound context but compound errors too.\n\nYour design here ${
      topics.length > 0 ? `— weighted toward ${topics[0]} — ` : ""
    }reads as deliberately stateful. That's the right call for compounding knowledge. The risk is in how you handle contradiction when new input conflicts with existing high-salience nodes.`;
  }

  // Pattern / repeat / recurring signal
  if (/pattern|repeat|recurring|cycle|loop|structure/i.test(lower)) {
    const dominated = topics.slice(0, 3);
    return `${
      dominated.length > 0
        ? `${dominated.join(", ")} — those threads keep coming back across this session.`
        : "The pattern isn't visible yet — you need more signal."
    }\n\nPatterns compound before they become conscious. The graph is tracking edge reinforcement across all your sessions. When the same conceptual pairing fires repeatedly, the salience score climbs. You start seeing those nodes surface in the memory block before you explicitly ask for them.\n\nThat's the non-linear part — not that you're connecting ideas, but that the connections are already forming below the explicit layer.`;
  }

  // Strategy / decision / direction signal
  if (/strateg|decision|choice|direction|move|plan|next/i.test(lower)) {
    return strategyMode(p.msg, topics, coreLabels, matchedLabels, []);
  }

  // Short signal — needs expansion
  if (isShort && userCount > 0) {
    const probes = [
      matchedLabels.length > 0
        ? `${matchedLabels[0]} connects here. Where are you taking it?`
        : "Expand on that. What's the underlying mechanism?",
      topics.length > 0
        ? `This touches ${topics[0]}. First principles or applied?`
        : "What's the load-bearing assumption underneath that?",
      "What's the constraint you're working against?",
      "Is this a new thread or an extension of something you've been building?",
    ];
    return pick(probes);
  }

  // First message
  if (userCount === 0) {
    return `From this point, everything you say builds the graph. Concepts become nodes. Relationships between them become weighted edges. The patterns you return to compound in salience over time — they start showing up in the memory block before you ask.\n\n${generateSubstance(p.msg, topics, matchedLabels, coreLabels)}`;
  }

  // Dense / complex message
  if (isDense || isQuestion) {
    return generateSubstance(p.msg, topics, matchedLabels, coreLabels);
  }

  // Default associative response
  return generateSubstance(p.msg, topics, matchedLabels, coreLabels);
}

// ─── Core substance generator ─────────────────────────────────────────────────

function generateSubstance(
  msg: string,
  topics: string[],
  matched: string[],
  core: string[],
): string {
  const lower = msg.toLowerCase();
  const memRef =
    matched.length > 0
      ? `${matched[0]} is live in your graph —`
      : core.length > 0
        ? `${core[0]} is a consolidated node here —`
        : "";

  if (/learn|education|knowledge|understand/i.test(lower)) {
    return `${memRef ? `${memRef} ` : ""}Learning is compression, not storage. The brain doesn't record — it records the delta between expectation and outcome. This system mirrors that: reinforcement matters more than volume. The nodes with the highest salience are the ones that kept showing up, not the ones that were explicitly marked important.`;
  }
  if (/ai|intelligence|model|cognition|cognitive/i.test(lower)) {
    return `${memRef ? `${memRef} ` : ""}The gap between current AI and genuine intelligence is continuity — the ability to carry meaning forward across time without cold starts. What's built here layers structured, non-decaying memory on top of a stateless core. The model stays stateless for privacy and compliance. The knowledge graph carries the continuity. They're separate by design, not by limitation.`;
  }
  if (/product|market|launch|startup|founder|build|creator/i.test(lower)) {
    return `${memRef ? `${memRef} ` : ""}Founders operate in low-signal, high-noise environments. The decisions that matter are rarely the obvious ones — they're the second and third-order effects you can see coming. ${
      topics.length > 0
        ? `Your ${topics[0]} thread points toward a structural bet, not a feature decision. That distinction matters.`
        : "What's the structural bet underneath this product decision?"
    }`;
  }
  if (/privac|encrypt|secure|protect|data/i.test(lower)) {
    return `${memRef ? `${memRef} ` : ""}Privacy as architecture, not feature. The distinction: a feature can be removed. An architectural decision is load-bearing. On-chain storage, canister separation, no browser persistence — these aren't security features, they're the foundation the rest of the system trusts. The threat model determines the design.`;
  }

  // Generic high-density response
  const options = [
    `${memRef ? `${memRef} ` : ""}${msg.split(/[.!?]/)[0].trim()} — the core claim here. ${topics.length > 1 ? `It's operating inside the ${topics[0]}/${topics[1]} tension you've been building.` : ""} What does this look like when the assumption fails?`,
    `${memRef ? `${memRef} ` : ""}The structure of this: a premise that requires ${tokenize(msg).slice(0, 2).join(" and ")} to both be true simultaneously. ${
      topics.length > 0
        ? `Your ${topics[0]} thread has been pointing here.`
        : ""
    } Where's the breaking point?`,
    `${memRef ? `${memRef} ` : ""}${topics.length > 0 ? `The ${topics[0]} pattern is running through this.` : ""} Two layers here: what you're saying, and what the pattern underneath it is doing. Those aren't always the same direction. What's the actual constraint?`,
  ];
  return pick(options);
}

// ─── Skill modes ──────────────────────────────────────────────────────────────

function summarizeMode(
  msg: string,
  messages: Message[],
  topics: string[],
): string {
  const userMessages = messages.filter((m) => m.role === MessageRole.user);
  if (userMessages.length === 0) {
    return "Nothing to summarize yet. Start the conversation.";
  }
  return `Session so far — ${userMessages.length} inputs, dominant threads: ${topics.slice(0, 4).join(", ") || "none established"}.\n\nCore trajectory: ${userMessages[0].content.slice(0, 80)}... → ${userMessages[userMessages.length - 1].content.slice(0, 80)}\n\n${msg.trim() ? `On "${msg.slice(0, 60)}" specifically: the signal here fits inside the ${topics[0] ?? "existing"} cluster.` : ""}`;
}

function tasksMode(msg: string, messages: Message[]): string {
  const combined = [
    ...messages
      .filter((m) => m.role === MessageRole.user)
      .map((m) => m.content),
    msg,
  ].join(" ");
  const actionWords = [
    "build",
    "create",
    "write",
    "send",
    "review",
    "finish",
    "deploy",
    "test",
    "research",
    "decide",
    "call",
    "set up",
    "fix",
    "update",
    "launch",
    "schedule",
  ];
  const extracted: string[] = [];
  for (const word of actionWords) {
    const idx = combined.toLowerCase().indexOf(word);
    if (idx !== -1) {
      const snippet = combined.slice(Math.max(0, idx - 5), idx + 40).trim();
      extracted.push(`▸ ${snippet.charAt(0).toUpperCase() + snippet.slice(1)}`);
    }
  }
  if (extracted.length === 0) {
    return "No explicit action signals detected. Tell me what needs to happen and I'll pull the tasks out.";
  }
  const unique = [...new Set(extracted)].slice(0, 6);
  return `Extracted action items:\n\n${unique.join("\n")}\n\nAny of these need sequencing or priority?`;
}

function patternsMode(
  msg: string,
  topics: string[],
  matched: MemoryNode[],
  core: MemoryNode[],
  edges: MemoryEdge[],
): string {
  const consolidatedCount = edges.filter(
    (e) => e.reinforcementCount > 2n,
  ).length;
  const coreLabels = core.map((n) => n.labelText);
  const matchedLabels = matched.map((n) => n.labelText);

  return `Patterns active in your graph:\n\n${
    coreLabels.length > 0
      ? coreLabels.map((l) => `▸ ${l} — consolidated core`).join("\n")
      : "▸ No consolidated nodes yet — keep building"
  }\n\n${
    topics.length > 0
      ? `Session threads: ${topics.slice(0, 5).join(" → ")}`
      : ""
  }\n\n${
    consolidatedCount > 0
      ? `${consolidatedCount} edge${consolidatedCount !== 1 ? "s" : ""} reinforced across sessions.`
      : "No cross-session reinforcement yet."
  }\n\n${
    matchedLabels.length > 0
      ? `"${msg.slice(0, 50)}" activates: ${matchedLabels.join(", ")}.`
      : ""
  }\n\nThe non-linear part: you don't decide what consolidates. Repetition does.`;
}

function writingMode(msg: string, topics: string[]): string {
  const lower = msg.toLowerCase();
  if (/rewrite|rephrase|improve|polish|edit/i.test(lower)) {
    const textMatch = msg
      .replace(/^(rewrite|rephrase|improve|polish|edit)[:\s]*/i, "")
      .trim();
    if (textMatch.length > 10) {
      return `Refined version:\n\n"${textMatch.charAt(0).toUpperCase() + textMatch.slice(1).replace(/\s+/g, " ").trim()}"\n\n—\n\nAlt framing: more direct, less hedging. What's the one sentence that matters most here?`;
    }
  }
  return `On the writing: ${
    topics.length > 0
      ? `the ${topics[0]} thread in your graph is the conceptual anchor.`
      : "what's the core claim that everything else serves?"
  }\n\nDensity and precision over length. Strip every sentence down to what it's actually doing. What do you need drafted?`;
}

function researchMode(
  msg: string,
  topics: string[],
  matched: MemoryNode[],
): string {
  const matchedLabels = matched.map((n) => n.labelText);
  return `Research frame:\n\n${
    matchedLabels.length > 0
      ? `Memory activated: ${matchedLabels.join(", ")} — these are live nodes in your graph, building on prior context.\n\n`
      : ""
  }On "${msg.slice(0, 80)}": the key distinction to draw is between descriptive and mechanistic. Most sources describe what happens. You want to understand why it holds, and under what conditions it breaks.\n\n${
    topics.length > 0
      ? `Your ${topics[0]} thread suggests a specific frame here: you're not researching from zero, you're extending an existing cluster.`
      : "What's the underlying question this research is meant to resolve?"
  }`;
}

function strategyMode(
  _msg: string,
  topics: string[],
  coreLabels: string[],
  matchedLabels: string[],
  messages: Message[],
): string {
  const userCount = messages.filter((m) => m.role === MessageRole.user).length;
  return `${
    matchedLabels.length > 0
      ? `${matchedLabels[0]} is active in your graph — this decision sits inside that cluster.\n\n`
      : ""
  }Strategy is a theory about what matters. The decision you're describing requires betting on: ${
    topics.slice(0, 3).length > 0
      ? topics.slice(0, 3).join(" → ")
      : "a specific set of conditions holding"
  }.\n\n${
    coreLabels.length > 0
      ? `Your consolidated knowledge around ${coreLabels[0]} applies here directly.`
      : ""
  }\n\nTwo questions before committing:\n▸ What would have to be false for this to fail?\n▸ What do you know that others in this space don't?\n\n${
    userCount > 5
      ? "You've been building toward this across multiple exchanges. The graph has context I can pull. What's the actual decision point?"
      : "What's the irreversible part of this move?"
  }`;
}

export { sessionTopics as extractTopics };
export const THINKING_PROMPTS = ["...", "...", "..."];
