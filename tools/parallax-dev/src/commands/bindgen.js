// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Bindgen Command
// Generate TypeScript bindings from Motoko .did files for all canisters
// ═══════════════════════════════════════════════════════════════════════════════

import { readdir, readFile, writeFile, mkdir } from "node:fs/promises";
import { join, basename, isAbsolute } from "node:path";
import { existsSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { discoverSubstrates } from "../discovery.js";

/**
 * Generate TypeScript bindings from .did interface files
 * @param {object} ctx - CLI context
 * @param {object} flags - CLI flags (canister, outDir)
 */
export async function bindgen(ctx, flags = {}) {
  const { root } = ctx;
  const targetCanister = flags.canister || null;
  const outDir = flags["out-dir"] || join(root, "src", "frontend", "src", "declarations");

  console.log(`\n🔗 PARALLAX Bindgen — TypeScript Interface Generation\n`);

  const substrates = await discoverSubstrates(root);

  // Filter to specific canister if requested
  const targets = targetCanister
    ? substrates.filter((s) => s.name === targetCanister)
    : substrates.filter((s) => s.name !== "frontend");

  if (targetCanister && targets.length === 0) {
    throw new Error(`Canister "${targetCanister}" not found`);
  }

  let generated = 0;
  let skipped = 0;

  for (const substrate of targets) {
    const didFile = findDid(substrate);

    if (!didFile) {
      console.log(`   ⏭  ${substrate.name} — no .did file (build first)`);
      skipped++;
      continue;
    }

    const canisterOutDir = join(outDir, substrate.name);
    await mkdir(canisterOutDir, { recursive: true });

    // Try using didc (Candid compiler) if available
    const useDidc = isCommandAvailable("didc");

    if (useDidc) {
      await generateWithDidc(didFile, canisterOutDir, substrate.name);
    } else {
      // Fallback: generate typed wrapper from .did file
      await generateFallbackBindings(didFile, canisterOutDir, substrate.name);
    }

    console.log(`   ✓ ${substrate.name} → declarations/${substrate.name}/`);
    generated++;
  }

  // Generate barrel index file
  await generateBarrelIndex(outDir, targets.filter((s) => findDid(s)));

  console.log(`\n✅ Bindgen complete: ${generated} generated, ${skipped} skipped\n`);
}

/**
 * Find .did file for a substrate (check dist/ and root)
 */
function findDid(substrate) {
  const distDid = join(substrate.path, "dist", `${substrate.name}.did`);
  if (existsSync(distDid)) return distDid;

  const rootDid = join(substrate.path, `${substrate.name}.did`);
  if (existsSync(rootDid)) return rootDid;

  // Check for any .did file in dist/
  const distDir = join(substrate.path, "dist");
  if (existsSync(distDir)) {
    try {
      const files = readdirSync(distDir);
      const didFile = files.find((f) => f.endsWith(".did"));
      if (didFile) return join(distDir, didFile);
    } catch {}
  }

  return null;
}

/**
 * Generate bindings using didc (official Candid compiler)
 */
async function generateWithDidc(didFile, outDir, name) {
  // Validate didFile path to prevent injection
  if (!isAbsolute(didFile) || !existsSync(didFile)) {
    throw new Error(`Invalid .did file path: ${didFile}`);
  }

  try {
    // Generate JS bindings using execFileSync (no shell injection possible)
    const jsOutput = execFileSync("didc", ["bind", didFile, "--target", "js"], { encoding: "utf-8" });
    await writeFile(join(outDir, `${name}.idl.js`), jsOutput);

    // Generate TS declarations
    const tsOutput = execFileSync("didc", ["bind", didFile, "--target", "ts"], { encoding: "utf-8" });
    await writeFile(join(outDir, `${name}.d.ts`), tsOutput);

    // Generate index
    await writeFile(
      join(outDir, "index.ts"),
      generateIndexTs(name)
    );
  } catch (err) {
    throw new Error(`didc failed for ${name}: ${err.message}`);
  }
}

/**
 * Generate fallback bindings without didc — creates typed wrapper
 */
async function generateFallbackBindings(didFile, outDir, name) {
  const didContent = await readFile(didFile, "utf-8");

  // Parse service methods from .did
  const methods = parseDid(didContent);

  // Generate TypeScript interface
  const tsContent = generateTypeScriptInterface(name, methods, didContent);
  await writeFile(join(outDir, `${name}.d.ts`), tsContent);

  // Generate actor factory
  const factoryContent = generateActorFactory(name);
  await writeFile(join(outDir, "index.ts"), factoryContent);

  // Copy .did file
  await writeFile(join(outDir, `${name}.did`), didContent);
}

/**
 * Simple .did parser — extracts method signatures
 */
function parseDid(content) {
  const methods = [];
  const serviceMatch = content.match(/service\s*[^{]*\{([\s\S]*?)\}/);
  if (!serviceMatch) return methods;

  const body = serviceMatch[1];
  const lines = body.split(";").map((l) => l.trim()).filter(Boolean);

  for (const line of lines) {
    const match = line.match(/(\w+)\s*:\s*\((.*?)\)\s*->\s*\((.*?)\)(\s*query)?/);
    if (match) {
      methods.push({
        name: match[1],
        params: match[2].trim(),
        returnType: match[3].trim(),
        isQuery: !!match[4],
      });
    }
  }

  return methods;
}

/**
 * Map Candid types to TypeScript
 */
function candidToTs(candidType) {
  const map = {
    nat: "bigint",
    nat8: "number",
    nat16: "number",
    nat32: "number",
    nat64: "bigint",
    int: "bigint",
    int8: "number",
    int16: "number",
    int32: "number",
    int64: "bigint",
    float32: "number",
    float64: "number",
    bool: "boolean",
    text: "string",
    principal: "Principal",
    blob: "Uint8Array",
    null: "null",
    "": "void",
  };
  const trimmed = candidType.trim();
  return map[trimmed] || trimmed || "void";
}

function generateTypeScriptInterface(name, methods, didContent) {
  const actorName = name
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join("");

  let ts = `// Auto-generated by PARALLAX Dev bindgen
// Source: ${name}.did
// Do not edit manually — regenerate with: parallax bindgen --canister ${name}

import type { Principal } from "@dfinity/principal";
import type { ActorMethod } from "@dfinity/agent";

`;

  // Generate interface
  ts += `export interface _SERVICE {\n`;
  for (const method of methods) {
    const params = method.params
      ? method.params.split(",").map((p) => candidToTs(p.trim())).join(", ")
      : "";
    const ret = candidToTs(method.returnType);
    ts += `  ${method.name}: ActorMethod<[${params}], ${ret}>;\n`;
  }
  ts += `}\n\n`;

  ts += `export declare const idlFactory: any;\n`;
  ts += `export declare const canisterId: string;\n`;

  return ts;
}

function generateActorFactory(name) {
  return `// Auto-generated by PARALLAX Dev bindgen
// Actor factory for ${name} canister

import { Actor, HttpAgent } from "@dfinity/agent";
import type { _SERVICE } from "./${name}.d.ts";

export const canisterId = process.env.${name.toUpperCase()}_CANISTER_ID || "";

export function create${name.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join("")}Actor(agent: HttpAgent) {
  return Actor.createActor<_SERVICE>(idlFactory, {
    agent,
    canisterId,
  });
}

// Re-export types
export type { _SERVICE } from "./${name}.d.ts";
`;
}

function generateIndexTs(name) {
  return `// Auto-generated by PARALLAX Dev bindgen
export { idlFactory } from "./${name}.idl.js";
export type { _SERVICE } from "./${name}.d.ts";
export const canisterId = process.env.${name.toUpperCase()}_CANISTER_ID || "";
`;
}

async function generateBarrelIndex(outDir, substrates) {
  if (!existsSync(outDir)) return;

  let content = `// Auto-generated by PARALLAX Dev bindgen — barrel index\n`;
  content += `// Re-exports all canister declarations\n\n`;

  for (const s of substrates) {
    content += `export * as ${s.name} from "./${s.name}/index.ts";\n`;
  }

  await writeFile(join(outDir, "index.ts"), content);
}

function isCommandAvailable(cmd) {
  try {
    execFileSync("which", [cmd], { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}
