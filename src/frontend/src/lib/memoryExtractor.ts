const STOP_WORDS = new Set([
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
]);

export function extractConcepts(text: string, count = 3): string[] {
  // Extract meaningful phrases (2-word) and single words
  const words = text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 3 && !STOP_WORDS.has(w));

  // Deduplicate and return top N
  const seen = new Set<string>();
  const result: string[] = [];
  for (const word of words) {
    if (!seen.has(word)) {
      seen.add(word);
      result.push(word);
    }
    if (result.length >= count) break;
  }
  return result;
}

export function conceptToLabel(concept: string): string {
  return concept
    .split(/[-_\s]+/)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}
