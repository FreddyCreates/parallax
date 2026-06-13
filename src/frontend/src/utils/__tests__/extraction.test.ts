import { describe, expect, it, vi } from "vitest";

// Mock the backend module since NodeType comes from generated canister bindings
vi.mock("../../backend", () => ({
  NodeType: {
    memory: "memory",
    concept: "concept",
  },
}));

// Import after mock
const { extractEntities } = await import("../extraction");

describe("extractEntities", () => {
  it("returns empty array for empty text", () => {
    expect(extractEntities("")).toEqual([]);
  });

  it("extracts memory entities from 'I believe' patterns", () => {
    const result = extractEntities("I believe quantum computing is the future");
    expect(result.length).toBeGreaterThan(0);
    const memoryEntities = result.filter((e) => e.type === "memory");
    expect(memoryEntities.length).toBeGreaterThan(0);
  });

  it("extracts memory entities from 'I think' patterns", () => {
    const result = extractEntities("I think machine learning works");
    const memoryEntities = result.filter((e) => e.type === "memory");
    expect(memoryEntities.length).toBeGreaterThan(0);
  });

  it("extracts memory entities from 'I want to' patterns", () => {
    const result = extractEntities("I want to build something amazing");
    const memoryEntities = result.filter((e) => e.type === "memory");
    expect(memoryEntities.length).toBeGreaterThan(0);
  });

  it("extracts memory entities from 'I need to' patterns", () => {
    const result = extractEntities("I need to learn programming quickly");
    const memoryEntities = result.filter((e) => e.type === "memory");
    expect(memoryEntities.length).toBeGreaterThan(0);
  });

  it("extracts memory entities from 'I am working on' patterns", () => {
    const result = extractEntities("I am working on a new project");
    const memoryEntities = result.filter((e) => e.type === "memory");
    expect(memoryEntities.length).toBeGreaterThan(0);
  });

  it("extracts concept entities from capitalized words not at sentence start", () => {
    const result = extractEntities(
      "This is about Parallax and Quantum protocols.",
    );
    const conceptEntities = result.filter((e) => e.type === "concept");
    expect(conceptEntities.some((e) => e.label === "Parallax")).toBe(true);
    expect(conceptEntities.some((e) => e.label === "Quantum")).toBe(true);
  });

  it("excludes common words from concept extraction", () => {
    const result = extractEntities(
      "We went There and Then came back While waiting.",
    );
    const labels = result.map((e) => e.label);
    expect(labels).not.toContain("There");
    expect(labels).not.toContain("Then");
    expect(labels).not.toContain("While");
  });

  it("deduplicates entities (case-insensitive)", () => {
    const result = extractEntities(
      "I believe quantum works. And also the Quantum approach is good.",
    );
    const quantumEntities = result.filter((e) =>
      e.label.toLowerCase().includes("quantum"),
    );
    // Should not have duplicates
    const labels = quantumEntities.map((e) => e.label.toLowerCase());
    const unique = new Set(labels);
    expect(labels.length).toBe(unique.size);
  });

  it("limits results to maximum 6 entities", () => {
    const text =
      "I believe Alpha works. I think Beta works. I want to build Gamma and Delta. " +
      "Also the Epsilon and Zeta and Theta and Iota systems are great.";
    const result = extractEntities(text);
    expect(result.length).toBeLessThanOrEqual(6);
  });

  it("filters out labels shorter than 3 characters", () => {
    const result = extractEntities("I believe it is so great");
    const labels = result.map((e) => e.label);
    for (const label of labels) {
      expect(label.length).toBeGreaterThanOrEqual(3);
    }
  });

  it("removes non-word characters from labels", () => {
    const result = extractEntities("I believe hello@world is the future");
    const labels = result.map((e) => e.label);
    for (const label of labels) {
      expect(label).toMatch(/^[\w\s-]+$/);
    }
  });
});
