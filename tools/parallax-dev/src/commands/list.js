// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — List Command
// List all substrates in the organism with topology info
// ═══════════════════════════════════════════════════════════════════════════════

import { discoverSubstrates } from "../discovery.js";

/**
 * List all substrates in the organism
 */
export async function list(ctx, flags = {}) {
  const { root } = ctx;
  const substrates = await discoverSubstrates(root);

  if (flags.json) {
    console.log(JSON.stringify(substrates.map((s) => ({
      name: s.name,
      tier: s.tier,
      path: `src/${s.name}/`,
      hasMain: s.hasMain,
    })), null, 2));
    return;
  }

  console.log(`\n🌌 PARALLAX Organism — ${substrates.length} Substrates\n`);

  const tierLabels = { 1: "CORE   ", 2: "MAJOR  ", 3: "SUPPORT" };

  console.log(`  ${"Name".padEnd(24)} ${"Tier".padEnd(10)} ${"Path"}`);
  console.log(`  ${"─".repeat(24)} ${"─".repeat(10)} ${"─".repeat(20)}`);

  for (const s of substrates) {
    const tier = tierLabels[s.tier] || "UNKNOWN";
    console.log(`  ${s.name.padEnd(24)} ${tier.padEnd(10)} src/${s.name}/`);
  }

  console.log();
}
