// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Canister Discovery Utilities
// Shared logic for discovering and loading canister configs across the organism
// ═══════════════════════════════════════════════════════════════════════════════

import { readdir, readFile, stat } from "node:fs/promises";
import { join, basename } from "node:path";
import { existsSync, readdirSync } from "node:fs";

/**
 * Discover all substrate canisters in src/
 * A substrate is any directory with a canister.yaml
 */
export async function discoverSubstrates(root) {
  const srcDir = join(root, "src");
  const entries = await readdir(srcDir, { withFileTypes: true });
  const substrates = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const dir = join(srcDir, entry.name);
    const canisterYaml = join(dir, "canister.yaml");

    if (existsSync(canisterYaml)) {
      const config = await loadCanisterYaml(canisterYaml);
      const mainFile = join(dir, "main.mo");
      const hasMain = existsSync(mainFile);
      const didFile = findDidFile(dir);

      substrates.push({
        name: entry.name,
        path: dir,
        configPath: canisterYaml,
        config,
        hasMain,
        didFile,
        tier: inferTier(entry.name, config),
      });
    }
  }

  return substrates.sort((a, b) => a.tier - b.tier || a.name.localeCompare(b.name));
}

/**
 * Parse canister.yaml (simple YAML subset — no external deps)
 */
export async function loadCanisterYaml(path) {
  const content = await readFile(path, "utf-8");
  return parseSimpleYaml(content);
}

/**
 * Minimal YAML parser for canister.yaml files
 * Handles the key patterns used in this project
 */
function parseSimpleYaml(content) {
  const result = {};
  const lines = content.split("\n").filter((l) => !l.startsWith("#") && l.trim());

  let currentKey = null;
  for (const line of lines) {
    const match = line.match(/^(\w[\w-]*):\s*(.*)$/);
    if (match) {
      const [, key, value] = match;
      if (value) {
        result[key] = value.trim();
      } else {
        result[key] = {};
        currentKey = key;
      }
    }
  }

  // Extract type and main specifically
  if (result.type) result.type = result.type.toString();
  if (result.main) result.main = result.main.toString();
  if (result.name) result.name = result.name.toString();

  return result;
}

/**
 * Find .did file in canister dist/ directory
 */
function findDidFile(dir) {
  const distDir = join(dir, "dist");
  if (!existsSync(distDir)) return null;

  try {
    const files = readdirSync(distDir);
    const didFile = files.find((f) => f.endsWith(".did"));
    return didFile ? join(distDir, didFile) : null;
  } catch {
    return null;
  }
}

/**
 * Infer canister tier from name and config
 * Tier 1: Core (backend) — the sovereign organism
 * Tier 2: Major substrates (brain, alpha_*, bridges)
 * Tier 3: Support substrates (everything else)
 */
function inferTier(name, config) {
  if (name === "backend" || name === "frontend") return 1;
  if (["brain", "alpha_conductor", "alpha_orchestrator", "bridges"].includes(name)) return 2;
  return 3;
}

/**
 * Load the project's icp.yaml
 */
export async function loadIcpYaml(root) {
  const icpPath = join(root, "icp.yaml");
  if (!existsSync(icpPath)) return null;
  const content = await readFile(icpPath, "utf-8");
  // Extract canister list from simple format
  const canisters = [];
  const lines = content.split("\n");
  for (const line of lines) {
    const match = line.match(/^\s+-\s+(.+)$/);
    if (match) canisters.push(match[1].trim());
  }
  return { canisters };
}

/**
 * Load mops.toml dependencies
 */
export async function loadMopsConfig(root) {
  const mopsPath = join(root, "mops.toml");
  if (!existsSync(mopsPath)) return null;
  const content = await readFile(mopsPath, "utf-8");
  const deps = {};
  const depSection = content.match(/\[dependencies\]([\s\S]*?)(\[|$)/);
  if (depSection) {
    const lines = depSection[1].trim().split("\n");
    for (const line of lines) {
      const match = line.match(/^(\w+)\s*=\s*"(.+)"$/);
      if (match) deps[match[1]] = match[2];
    }
  }
  return { deps };
}
