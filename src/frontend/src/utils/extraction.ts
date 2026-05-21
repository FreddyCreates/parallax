// @ts-nocheck
import { NodeType } from "../backend";

export interface ExtractedEntity {
  label: string;
  type: NodeType;
}

const MEMORY_TRIGGERS = [
  /i believe\s+([\w\s]{3,30})/gi,
  /i think\s+([\w\s]{3,30})/gi,
  /i'm working on\s+([\w\s]{3,30})/gi,
  /i am working on\s+([\w\s]{3,30})/gi,
  /my project\s+(?:is\s+)?([\w\s]{3,20})/gi,
  /my goal\s+(?:is\s+)?([\w\s]{3,20})/gi,
  /i want to\s+([\w\s]{3,25})/gi,
  /i need to\s+([\w\s]{3,25})/gi,
];

/**
 * Extract entities from a message text.
 * Returns an array of { label, type } objects.
 */
export function extractEntities(text: string): ExtractedEntity[] {
  const entities: ExtractedEntity[] = [];
  const seen = new Set<string>();

  function addEntity(label: string, type: NodeType) {
    const clean = label
      .trim()
      .replace(/[^\w\s-]/g, "")
      .trim();
    if (clean.length < 3) return;
    const key = clean.toLowerCase();
    if (seen.has(key)) return;
    seen.add(key);
    entities.push({ label: clean, type });
  }

  // Extract memory-type entities from trigger phrases
  for (const regex of MEMORY_TRIGGERS) {
    regex.lastIndex = 0;
    let match = regex.exec(text);
    while (match !== null) {
      const captured = match[1]?.trim();
      if (captured && captured.length >= 3) {
        const trimmed = captured.split(/\s+/).slice(0, 3).join(" ");
        addEntity(trimmed, NodeType.memory);
      }
      match = regex.exec(text);
    }
  }

  // Extract concept-type entities: capitalized words > 3 chars, not first word of sentence
  const sentences = text.split(/[.!?]+/);
  for (const sentence of sentences) {
    const words = sentence.trim().split(/\s+/);
    for (let i = 1; i < words.length; i++) {
      const word = words[i];
      if (
        word.length > 3 &&
        /^[A-Z][a-zA-Z-]+$/.test(word) &&
        !/^(This|That|These|Those|They|Their|There|When|Then|Also|From|With|Have|Been|Will|Would|Could|Should|Must|Does|Into|About|After|Before|During|While|Since|Until|Though|Although|Because|Therefore|However|Moreover|Furthermore|Nevertheless|Nonetheless)$/.test(
          word,
        )
      ) {
        addEntity(word, NodeType.concept);
      }
    }
  }

  return entities.slice(0, 6);
}
