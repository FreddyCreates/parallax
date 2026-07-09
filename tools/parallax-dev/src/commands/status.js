// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Status Command
// Show all canister states, health, and substrate topology
// ═══════════════════════════════════════════════════════════════════════════════

import { execFileSync } from "node:child_process";
import { join } from "node:path";
import { existsSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import { discoverSubstrates } from "../discovery.js";

/**
 * Show status of all substrates in the organism
 */
export async function status(ctx, flags = {}) {
  const { root } = ctx;

  console.log(`\n🌌 PARALLAX Organism Status\n`);

  const substrates = await discoverSubstrates(root);

  // Group by tier
  const tiers = { 1: [], 2: [], 3: [] };
  for (const s of substrates) {
    tiers[s.tier] = tiers[s.tier] || [];
    tiers[s.tier].push(s);
  }

  const tierNames = { 1: "CORE", 2: "MAJOR SUBSTRATES", 3: "SUPPORT SUBSTRATES" };

  for (const [tier, items] of Object.entries(tiers)) {
    if (items.length === 0) continue;
    console.log(`  ── ${tierNames[tier]} (Tier ${tier}) ──────────────────────`);
    console.log();

    for (const substrate of items) {
      const moFiles = await countMoFiles(substrate.path);
      const hasSystemIdl = existsSync(join(substrate.path, "system-idl"));
      const hasDist = existsSync(join(substrate.path, "dist"));
      const configType = substrate.config.type || "script-build";

      const statusIcon = hasDist ? "🟢" : "⚪";
      console.log(`    ${statusIcon} ${substrate.name}`);
      console.log(`       Path:    src/${substrate.name}/`);
      console.log(`       Type:    ${configType}`);
      console.log(`       Files:   ${moFiles} .mo files`);
      console.log(`       IDL:     ${hasSystemIdl ? "✓" : "—"}`);
      console.log(`       Built:   ${hasDist ? "✓" : "—"}`);
      console.log();
    }
  }

  // Summary
  console.log(`  ── SUMMARY ─────────────────────────────────────`);
  console.log(`    Total substrates: ${substrates.length}`);
  console.log(`    Tier 1 (Core):    ${tiers[1]?.length || 0}`);
  console.log(`    Tier 2 (Major):   ${tiers[2]?.length || 0}`);
  console.log(`    Tier 3 (Support): ${tiers[3]?.length || 0}`);

  // Check if ICP CLI is available for live status
  if (isCommandAvailable("icp")) {
    console.log(`\n  ── NETWORK STATUS ──────────────────────────────`);
    try {
      const networkStatus = execFileSync("icp", ["network", "status"], {
        cwd: root,
        encoding: "utf-8",
        stdio: "pipe",
      });
      console.log(`    ${networkStatus.trim()}`);
    } catch {
      console.log(`    Network: not running (start with: parallax deploy --env local)`);
    }
  }

  console.log();
}

async function countMoFiles(dir) {
  try {
    const entries = await readdir(dir);
    return entries.filter((f) => f.endsWith(".mo")).length;
  } catch {
    return 0;
  }
}

function isCommandAvailable(cmd) {
  try {
    execFileSync("which", [cmd], { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}
