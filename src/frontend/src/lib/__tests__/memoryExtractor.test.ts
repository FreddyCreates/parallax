import { describe, expect, it } from "vitest";
import { conceptToLabel, extractConcepts } from "../memoryExtractor";

describe("extractConcepts", () => {
  it("extracts meaningful words from text, filtering stop words", () => {
    const result = extractConcepts("I want to build a quantum computer system", 5);
    // "want" is in stop words; "build", "quantum", "computer", "system" are meaningful
    expect(result).toContain("quantum");
    expect(result).toContain("computer");
    expect(result).toContain("system");
    expect(result).toContain("build");
  });

  it("returns up to the specified count", () => {
    const result = extractConcepts(
      "quantum neural architecture blockchain protocol intelligence",
      2,
    );
    expect(result).toHaveLength(2);
  });

  it("returns default count of 3", () => {
    const result = extractConcepts(
      "quantum neural architecture blockchain protocol intelligence",
    );
    expect(result).toHaveLength(3);
  });

  it("filters words shorter than 4 characters", () => {
    const result = extractConcepts("the big red cat sat on a mat", 10);
    // "big", "red", "cat", "sat", "mat" are all 3 chars - filtered out
    expect(result).toHaveLength(0);
  });

  it("deduplicates words", () => {
    const result = extractConcepts("quantum quantum quantum quantum", 10);
    expect(result).toHaveLength(1);
    expect(result[0]).toBe("quantum");
  });

  it("removes non-alphanumeric characters", () => {
    const result = extractConcepts("hello-world! amazing@tech#stuff", 5);
    expect(result).toContain("hello-world");
    expect(result).toContain("amazing");
    expect(result).toContain("tech");
    expect(result).toContain("stuff");
  });

  it("lowercases all words", () => {
    const result = extractConcepts("QUANTUM Architecture NEURAL", 3);
    expect(result).toContain("quantum");
    expect(result).toContain("architecture");
    expect(result).toContain("neural");
  });

  it("handles empty string", () => {
    const result = extractConcepts("");
    expect(result).toHaveLength(0);
  });

  it("handles string with only stop words", () => {
    const result = extractConcepts("the and but or for");
    expect(result).toHaveLength(0);
  });
});

describe("conceptToLabel", () => {
  it("capitalizes each word in a hyphenated string", () => {
    expect(conceptToLabel("hello-world")).toBe("Hello World");
  });

  it("capitalizes each word in an underscored string", () => {
    expect(conceptToLabel("neural_network")).toBe("Neural Network");
  });

  it("capitalizes each word in a space-separated string", () => {
    expect(conceptToLabel("quantum computing")).toBe("Quantum Computing");
  });

  it("handles single word", () => {
    expect(conceptToLabel("blockchain")).toBe("Blockchain");
  });

  it("handles mixed separators", () => {
    expect(conceptToLabel("hello-world_foo bar")).toBe("Hello World Foo Bar");
  });

  it("handles already capitalized input", () => {
    expect(conceptToLabel("Hello")).toBe("Hello");
  });
});
