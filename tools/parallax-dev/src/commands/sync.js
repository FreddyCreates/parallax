// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Sync Command
// Sync icp.yaml with all discovered canisters in src/
// Ensures the deployment manifest reflects the actual multi-substrate organism
// ═══════════════════════════════════════════════════════════════════════════════

import { writeFile, readFile } from "node:fs/promises";
import { join } from "node:path";
import { existsSync } from "node:fs";
import { discoverSubstrates } from "../discovery.js";

/**
 * Sync icp.yaml to include all discovered substrates
 */
export async function sync(ctx, flags = {}) {
  const { root } = ctx;

  console.log(`\n🔄 PARALLAX Sync — Updating icp.yaml\n`);

  const substrates = await discoverSubstrates(root);
  const icpPath = join(root, "icp.yaml");

  // Read existing icp.yaml
  let existingCanisters = [];
  if (existsSync(icpPath)) {
    const content = await readFile(icpPath, "utf-8");
    const lines = content.split("\n");
    for (const line of lines) {
      const match = line.match(/^\s+-\s+(.+)$/);
      if (match) existingCanisters.push(match[1].trim());
    }
  }

  // Build new canister list (ordered: frontend/backend first, then alphabetical)
  const coreNames = ["src/frontend", "src/backend"];
  const otherNames = substrates
    .filter((s) => !["frontend", "backend"].includes(s.name))
    .map((s) => `src/${s.name}`)
    .sort();

  const allCanisters = [...coreNames, ...otherNames];

  // Find additions and removals
  const added = allCanisters.filter((c) => !existingCanisters.includes(c));
  const removed = existingCanisters.filter((c) => !allCanisters.includes(c));

  if (added.length === 0 && removed.length === 0) {
    console.log(`   ✓ icp.yaml is already in sync (${allCanisters.length} canisters)\n`);
    return;
  }

  // Generate new icp.yaml
  let yaml = `# yaml-language-server: $schema=https://github.com/dfinity/icp-cli/raw/refs/heads/main/docs/schemas/icp-yaml-schema.json
# Auto-synced by PARALLAX Dev — ${substrates.length} substrates
# Run: parallax sync
canisters:
`;

  for (const canister of allCanisters) {
    yaml += `  - ${canister}\n`;
  }

  await writeFile(icpPath, yaml);

  // Report changes
  if (added.length > 0) {
    console.log(`   Added:`);
    for (const a of added) console.log(`     + ${a}`);
  }
  if (removed.length > 0) {
    console.log(`   Removed:`);
    for (const r of removed) console.log(`     - ${r}`);
  }

  console.log(`\n   ✅ icp.yaml synced (${allCanisters.length} canisters)\n`);
}
