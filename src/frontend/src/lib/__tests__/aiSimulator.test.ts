import { describe, expect, it, vi, beforeEach } from "vitest";

// The aiSimulator.ts uses @ts-nocheck and imports Message/MessageRole from
// "../backend.d" which are not fully typed. We mock that module so tests resolve.
vi.mock("../../backend.d", () => ({
  MessageRole: { user: "user", ai: "ai" },
}));

import {
  generateAIResponse,
  extractTopics,
  THINKING_PROMPTS,
  type AIContext,
  type MemoryNode,
  type MemoryEdge,
  type SkillMode,
} from "../aiSimulator";

// ─── Test helpers ─────────────────────────────────────────────────────────────

function makeMessage(role: string, content: string) {
  return { role, content } as any;
}

function userMsg(content: string) {
  return makeMessage("user", content);
}

function aiMsg(content: string) {
  return makeMessage("ai", content);
}

function makeNode(
  id: string,
  labelText: string,
  nodeType = "concept",
  salienceScore = 0.5,
): MemoryNode {
  return { id, labelText, nodeType, salienceScore };
}

function makeEdge(
  fromNodeId: string,
  toNodeId: string,
  opts: Partial<MemoryEdge> = {},
): MemoryEdge {
  return {
    id: `${fromNodeId}-${toNodeId}`,
    fromNodeId,
    toNodeId,
    relationshipType: "related",
    confidenceScore: 0.8,
    salienceScore: opts.salienceScore ?? 0.7,
    reinforcementCount: opts.reinforcementCount ?? 3n,
    ...opts,
  };
}

function baseCtx(overrides: Partial<AIContext> = {}): AIContext {
  return {
    priorMessages: [],
    userName: "TestUser",
    memoryNodes: [],
    memoryEdges: [],
    skillMode: "general",
    ...overrides,
  };
}

// ─── extractTopics (sessionTopics) ────────────────────────────────────────────

describe("extractTopics", () => {
  it("returns an empty array when there are no messages", () => {
    expect(extractTopics([])).toEqual([]);
  });

  it("returns an empty array when messages have only stop words", () => {
    const messages = [userMsg("the and but or for is it")];
    expect(extractTopics(messages)).toEqual([]);
  });

  it("extracts top topics from user messages sorted by frequency", () => {
    const messages = [
      userMsg("quantum computing is the future of quantum technology"),
      userMsg("quantum neural network architecture"),
    ];
    const topics = extractTopics(messages);
    // "quantum" appears 3 times, should be first
    expect(topics[0]).toBe("quantum");
    expect(topics.length).toBeGreaterThan(0);
    expect(topics.length).toBeLessThanOrEqual(8);
  });

  it("limits results to 8 topics maximum", () => {
    const messages = [
      userMsg(
        "alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november",
      ),
    ];
    const topics = extractTopics(messages);
    expect(topics.length).toBeLessThanOrEqual(8);
  });

  it("only processes user messages, ignoring AI messages", () => {
    const messages = [
      userMsg("quantum computing"),
      aiMsg("blockchain technology distributed systems serverless microservices"),
    ];
    const topics = extractTopics(messages);
    // AI message words should not appear
    expect(topics).not.toContain("blockchain");
    expect(topics).not.toContain("technology");
  });

  it("filters words shorter than 4 characters", () => {
    const messages = [userMsg("the big cat ran far")];
    const topics = extractTopics(messages);
    // all words are ≤3 chars or stop words
    expect(topics).toEqual([]);
  });

  it("lowercases and deduplicates words", () => {
    const messages = [userMsg("Quantum QUANTUM quantum")];
    const topics = extractTopics(messages);
    expect(topics).toContain("quantum");
    // only one entry
    expect(topics.filter((t) => t === "quantum")).toHaveLength(1);
  });
});

// ─── THINKING_PROMPTS ─────────────────────────────────────────────────────────

describe("THINKING_PROMPTS", () => {
  it("is an array of strings", () => {
    expect(Array.isArray(THINKING_PROMPTS)).toBe(true);
    expect(THINKING_PROMPTS.length).toBeGreaterThan(0);
    for (const p of THINKING_PROMPTS) {
      expect(typeof p).toBe("string");
    }
  });
});

// ─── generateAIResponse: skill modes ──────────────────────────────────────────

describe("generateAIResponse", () => {
  describe("summarize mode", () => {
    it("returns 'Nothing to summarize' when no prior messages exist", () => {
      const ctx = baseCtx({ skillMode: "summarize" });
      const result = generateAIResponse("summarize this", ctx);
      expect(result).toContain("Nothing to summarize");
    });

    it("includes session statistics when prior user messages exist", () => {
      const ctx = baseCtx({
        skillMode: "summarize",
        priorMessages: [
          userMsg("I want to build a knowledge graph"),
          aiMsg("That sounds interesting"),
          userMsg("How should I structure the data?"),
        ],
      });
      const result = generateAIResponse("give me a summary", ctx);
      expect(result).toContain("2 inputs");
      expect(result).toContain("Session so far");
    });
  });

  describe("tasks mode", () => {
    it("returns 'no action signals' when no action words found", () => {
      const ctx = baseCtx({
        skillMode: "tasks",
        priorMessages: [userMsg("hello world")],
      });
      const result = generateAIResponse("nothing actionable here", ctx);
      expect(result).toContain("No explicit action signals");
    });

    it("extracts action items when action words are present", () => {
      const ctx = baseCtx({
        skillMode: "tasks",
        priorMessages: [userMsg("I need to build the frontend and deploy the app")],
      });
      const result = generateAIResponse("what are my tasks?", ctx);
      expect(result).toContain("Extracted action items");
      expect(result).toContain("▸");
    });

    it("limits extracted tasks to 6 maximum", () => {
      const ctx = baseCtx({
        skillMode: "tasks",
        priorMessages: [
          userMsg(
            "build create write send review finish deploy test research decide call set up fix update launch schedule",
          ),
        ],
      });
      const result = generateAIResponse("tasks", ctx);
      const items = result.split("▸").length - 1;
      expect(items).toBeLessThanOrEqual(6);
    });
  });

  describe("patterns mode", () => {
    it("shows 'no consolidated nodes' when memory is empty", () => {
      const ctx = baseCtx({ skillMode: "patterns" });
      const result = generateAIResponse("show patterns", ctx);
      expect(result).toContain("No consolidated nodes");
    });

    it("shows core labels when consolidated nodes exist", () => {
      const nodes = [
        makeNode("n1", "Machine Learning"),
        makeNode("n2", "Neural Networks"),
      ];
      const edges = [
        makeEdge("n1", "n2", { reinforcementCount: 5n, salienceScore: 0.8 }),
      ];
      const ctx = baseCtx({
        skillMode: "patterns",
        memoryNodes: nodes,
        memoryEdges: edges,
      });
      const result = generateAIResponse("show patterns", ctx);
      expect(result).toContain("consolidated core");
    });

    it("shows reinforcement count when edges are reinforced", () => {
      const nodes = [makeNode("n1", "AI"), makeNode("n2", "ML")];
      const edges = [
        makeEdge("n1", "n2", { reinforcementCount: 5n, salienceScore: 0.8 }),
      ];
      const ctx = baseCtx({
        skillMode: "patterns",
        memoryNodes: nodes,
        memoryEdges: edges,
      });
      const result = generateAIResponse("patterns", ctx);
      expect(result).toContain("edge");
      expect(result).toContain("reinforced");
    });
  });

  describe("writing mode", () => {
    it("returns writing guidance for general writing queries", () => {
      const ctx = baseCtx({ skillMode: "writing" });
      const result = generateAIResponse("help me write something", ctx);
      expect(result).toContain("writing");
    });

    it("handles rewrite requests with provided text", () => {
      const ctx = baseCtx({ skillMode: "writing" });
      const result = generateAIResponse(
        "rewrite: the quick brown fox jumps over the lazy dog and runs away",
        ctx,
      );
      expect(result).toContain("Refined version");
    });

    it("handles rewrite requests with short text gracefully", () => {
      const ctx = baseCtx({ skillMode: "writing" });
      const result = generateAIResponse("rewrite: hi", ctx);
      // Too short to rewrite, falls through to generic writing response
      expect(result).toContain("writing");
    });
  });

  describe("research mode", () => {
    it("returns research framing for queries", () => {
      const ctx = baseCtx({ skillMode: "research" });
      const result = generateAIResponse(
        "research quantum computing applications",
        ctx,
      );
      expect(result).toContain("Research frame");
      expect(result).toContain("descriptive and mechanistic");
    });

    it("references matched memory nodes when available", () => {
      const nodes = [makeNode("n1", "quantum computing")];
      const ctx = baseCtx({
        skillMode: "research",
        memoryNodes: nodes,
      });
      const result = generateAIResponse("quantum computing research", ctx);
      expect(result).toContain("Memory activated");
      expect(result).toContain("quantum computing");
    });
  });

  describe("strategy mode", () => {
    it("returns strategy framing with decision framework", () => {
      const ctx = baseCtx({ skillMode: "strategy" });
      const result = generateAIResponse("what should I do next?", ctx);
      expect(result).toContain("Strategy is a theory");
      expect(result).toContain("What would have to be false");
    });

    it("references matched labels when available", () => {
      const nodes = [makeNode("n1", "market expansion")];
      const edges = [
        makeEdge("n1", "n1", { reinforcementCount: 5n, salienceScore: 0.8 }),
      ];
      const ctx = baseCtx({
        skillMode: "strategy",
        memoryNodes: nodes,
        memoryEdges: edges,
        priorMessages: [userMsg("I want to expand the market")],
      });
      const result = generateAIResponse("market expansion strategy", ctx);
      expect(result).toContain("market expansion");
    });
  });

  describe("general mode", () => {
    it("returns introductory message on first user message", () => {
      const ctx = baseCtx({ priorMessages: [] });
      const result = generateAIResponse(
        "Hello, I am starting a new conversation today",
        ctx,
      );
      expect(result).toContain("graph");
    });

    it("responds to memory/recall signals with graph info", () => {
      const nodes = [makeNode("n1", "AI Research")];
      const edges = [
        makeEdge("n1", "n1", { reinforcementCount: 5n, salienceScore: 0.8 }),
      ];
      const ctx = baseCtx({
        priorMessages: [userMsg("earlier"), aiMsg("response")],
        memoryNodes: nodes,
        memoryEdges: edges,
      });
      const result = generateAIResponse(
        "do you remember what I said?",
        ctx,
      );
      expect(result).toContain("AI Research");
    });

    it("responds to memory signals with building message when graph is empty", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("hi"), aiMsg("hello")],
      });
      const result = generateAIResponse("remember this", ctx);
      expect(result).toContain("graph is building");
    });

    it("responds to architecture/system signals", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("prev"), aiMsg("resp")],
      });
      const result = generateAIResponse(
        "How should I architect this system?",
        ctx,
      );
      expect(result).toContain("architecture");
    });

    it("responds to pattern/cycle signals", () => {
      const ctx = baseCtx({
        priorMessages: [
          userMsg("quantum discussion"),
          aiMsg("response"),
          userMsg("more quantum topics"),
        ],
      });
      const result = generateAIResponse(
        "I notice a recurring pattern here",
        ctx,
      );
      // The response discusses patterns/threads/repetition
      expect(result.toLowerCase()).toMatch(/pattern|thread|repeat|compound/);
    });

    it("responds to strategy/decision signals", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("prev"), aiMsg("resp")],
      });
      const result = generateAIResponse(
        "I need to make a strategic decision",
        ctx,
      );
      expect(result).toContain("Strategy");
    });

    it("generates probe for short messages after first exchange", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("something"), aiMsg("response")],
      });
      // Short message (< 6 words), not first message
      const result = generateAIResponse("tell me more", ctx);
      expect(result.length).toBeGreaterThan(0);
    });

    it("generates substance for dense/question messages", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("initial"), aiMsg("response")],
      });
      const result = generateAIResponse(
        "What are the implications of using knowledge graphs for AI memory systems in production environments with high concurrency demands?",
        ctx,
      );
      expect(result.length).toBeGreaterThan(0);
    });

    it("handles learning/education topics", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("conversations about learning"), aiMsg("response")],
      });
      const result = generateAIResponse(
        "How does knowledge acquisition work and what does it mean to truly understand something deeply?",
        ctx,
      );
      expect(result).toContain("Learning");
    });

    it("handles AI/intelligence topics", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("conversations about cognition"), aiMsg("response")],
      });
      const result = generateAIResponse(
        "What separates artificial intelligence from mere computation, and how does cognition emerge from neural substrates?",
        ctx,
      );
      expect(result).toContain("intelligence");
    });

    it("handles product/startup topics", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("conversations"), aiMsg("response")],
      });
      const result = generateAIResponse(
        "As a founder I need to launch my startup product into the market and find the right audience for this creator tool",
        ctx,
      );
      expect(result).toContain("Founders");
    });

    it("handles privacy/security topics", () => {
      const ctx = baseCtx({
        priorMessages: [userMsg("conversations"), aiMsg("response")],
      });
      const result = generateAIResponse(
        "Tell me about privacy and how to encrypt and protect sensitive data in this application",
        ctx,
      );
      expect(result).toContain("Privacy");
    });

    it("references matched memory nodes in responses", () => {
      const nodes = [
        makeNode("n1", "knowledge graphs"),
        makeNode("n2", "neural networks"),
      ];
      const ctx = baseCtx({
        priorMessages: [userMsg("initial"), aiMsg("response")],
        memoryNodes: nodes,
      });
      const result = generateAIResponse(
        "Tell me about knowledge graphs and how they can be used for representing complex relationships in data systems",
        ctx,
      );
      expect(result).toContain("knowledge graphs");
    });
  });
});
