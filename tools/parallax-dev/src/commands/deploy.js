// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Deploy Command
// Multi-canister deployment with dependency ordering and substrate tiers
// ═══════════════════════════════════════════════════════════════════════════════

import { execFileSync, spawn } from "node:child_process";
import { join } from "node:path";
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { discoverSubstrates, loadIcpYaml } from "../discovery.js";

/**
 * Deploy canisters to local or mainnet
 * @param {object} ctx - CLI context
 * @param {object} flags - CLI flags (env, canister, skip-frontend)
 */
export async function deploy(ctx, flags = {}) {
  const { root } = ctx;
  const env = flags.env || "local";
  const targetCanister = flags.canister || null;
  const skipFrontend = flags["skip-frontend"] || false;

  console.log(`\n🚀 PARALLAX Deploy — Multi-Substrate Deployment`);
  console.log(`   Environment: ${env}`);
  console.log(`   Target: ${targetCanister || "all canisters"}\n`);

  // Verify icp CLI is available
  assertCommand("icp", "ICP CLI not found. Install: https://internetcomputer.org/docs/building-apps/install");

  const substrates = await discoverSubstrates(root);
  const icpConfig = await loadIcpYaml(root);

  // Filter targets
  let targets = substrates;
  if (targetCanister) {
    targets = substrates.filter((s) => s.name === targetCanister);
    if (targets.length === 0) {
      throw new Error(`Canister "${targetCanister}" not found`);
    }
  }
  if (skipFrontend) {
    targets = targets.filter((s) => s.name !== "frontend");
  }

  // Sort by tier (deploy core first, then major, then support)
  targets.sort((a, b) => a.tier - b.tier);

  // Start local network if local env
  if (env === "local") {
    console.log(`   ⚡ Starting local network...`);
    try {
      execFileSync("icp", ["network", "start", "-d"], { cwd: root, stdio: "pipe" });
      console.log(`   ✓ Local network started\n`);
    } catch (err) {
      // Network might already be running
      if (!err.message.includes("already")) {
        console.log(`   ⚠ Network start warning: ${err.message}\n`);
      } else {
        console.log(`   ✓ Local network already running\n`);
      }
    }
  }

  // Create canisters first
  console.log(`   📦 Creating canisters...\n`);
  for (const substrate of targets) {
    try {
      execFileSync("icp", ["canister", "create", "--environment", env, substrate.name], { cwd: root, stdio: "pipe" });
      console.log(`   ✓ Created: ${substrate.name}`);
    } catch (err) {
      // Canister might already exist
      if (err.message?.includes("already exists") || err.stderr?.toString().includes("already exists")) {
        console.log(`   ○ Exists:  ${substrate.name}`);
      } else {
        console.log(`   ⚠ Warning: ${substrate.name} — ${err.message?.split("\n")[0]}`);
      }
    }
  }

  // Export canister IDs for env vars
  console.log(`\n   🔑 Resolving canister IDs...\n`);
  const canisterIds = {};
  for (const substrate of targets) {
    try {
      const id = execFileSync(
        "icp", ["canister", "settings", "show", "--environment", env, "--id-only", substrate.name],
        { cwd: root, encoding: "utf-8", stdio: "pipe" }
      ).trim();
      canisterIds[substrate.name] = id;
      console.log(`   ${substrate.name}: ${id}`);
    } catch {
      console.log(`   ${substrate.name}: (not yet created)`);
    }
  }

  // Set env vars
  const envVars = { ...process.env };
  for (const [name, id] of Object.entries(canisterIds)) {
    envVars[`${name.toUpperCase()}_CANISTER_ID`] = id;
  }
  if (env === "local") {
    envVars.STORAGE_GATEWAY_URL = "http://localhost:6188";
    envVars.II_URL = "http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:8000";
  }

  // Deploy canisters
  console.log(`\n   🌐 Deploying substrates...\n`);
  const canisterNames = targets.map((s) => s.name);

  try {
    execFileSync("icp", ["deploy", "--environment", env, ...canisterNames], { cwd: root, env: envVars, stdio: "inherit" });
    console.log(`\n   ✅ All substrates deployed successfully!\n`);
  } catch (err) {
    throw new Error(`Deployment failed: ${err.message}`);
  }

  // Print summary
  console.log(`┌─────────────────────────────────────────────┐`);
  console.log(`│  🌌 PARALLAX Deployment Summary             │`);
  console.log(`├─────────────────────────────────────────────┤`);
  for (const substrate of targets) {
    const id = canisterIds[substrate.name] || "pending";
    const tierLabel = ["", "CORE", "MAJOR", "SUPPORT"][substrate.tier] || "OTHER";
    console.log(`│  [${tierLabel}] ${substrate.name.padEnd(20)} ${id.slice(0, 12)}...│`);
  }
  console.log(`└─────────────────────────────────────────────┘\n`);
}

function assertCommand(cmd, errorMsg) {
  try {
    execFileSync("which", [cmd], { stdio: "pipe" });
  } catch {
    throw new Error(errorMsg);
  }
}
