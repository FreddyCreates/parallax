// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev — Scaffold Command
// Create new substrate canisters with proper templates and wiring
// ═══════════════════════════════════════════════════════════════════════════════

import { mkdir, writeFile, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { existsSync } from "node:fs";

const PHI = 1.618033988749895;
const PHI_INV = 0.618033988749895;

/**
 * Scaffold a new substrate canister
 * @param {object} ctx - CLI context with root path
 * @param {string} name - substrate name (snake_case)
 * @param {object} flags - CLI flags (tier, template, etc.)
 */
export async function scaffold(ctx, name, flags = {}) {
  const { root } = ctx;
  const tier = parseInt(flags.tier || "3", 10);
  const template = flags.template || "substrate";

  // Validate name
  if (!/^[a-z][a-z0-9_]*$/.test(name)) {
    throw new Error(
      `Invalid substrate name "${name}". Use snake_case (lowercase letters, digits, underscores).`
    );
  }

  const targetDir = join(root, "src", name);

  if (existsSync(targetDir)) {
    throw new Error(`Substrate "${name}" already exists at src/${name}/`);
  }

  console.log(`\n🌌 Scaffolding substrate: ${name} (Tier ${tier})`);
  console.log(`   Template: ${template}`);
  console.log(`   Location: src/${name}/\n`);

  // Create directory
  await mkdir(targetDir, { recursive: true });
  await mkdir(join(targetDir, "system-idl"), { recursive: true });

  // Generate canister.yaml
  const canisterYaml = generateCanisterYaml(name, tier);
  await writeFile(join(targetDir, "canister.yaml"), canisterYaml);
  console.log(`   ✓ canister.yaml`);

  // Generate main.mo
  const mainMo = generateMainMo(name, tier, template);
  await writeFile(join(targetDir, "main.mo"), mainMo);
  console.log(`   ✓ main.mo`);

  // Generate types.mo for Tier 2+
  if (tier <= 2) {
    const typesMo = generateTypesMo(name);
    await writeFile(join(targetDir, "types.mo"), typesMo);
    console.log(`   ✓ types.mo`);
  }

  // Generate heartbeat module if tier 1 or 2
  if (tier <= 2) {
    const heartbeatMo = generateHeartbeatMo(name);
    await writeFile(join(targetDir, "heartbeat.mo"), heartbeatMo);
    console.log(`   ✓ heartbeat.mo`);
  }

  // Update icp.yaml to include new canister
  await updateIcpYaml(root, name);
  console.log(`   ✓ icp.yaml updated`);

  console.log(`\n✅ Substrate "${name}" scaffolded successfully!`);
  console.log(`\n   Next steps:`);
  console.log(`   1. Edit src/${name}/main.mo to add your logic`);
  console.log(`   2. Run: parallax deploy --env local`);
  console.log(`   3. Run: parallax bindgen --canister ${name}\n`);
}

function generateCanisterYaml(name, tier) {
  if (tier === 1) {
    // Full build script like backend
    return `# yaml-language-server: $schema=https://github.com/dfinity/icp-cli/raw/refs/heads/main/docs/schemas/canister-yaml-schema.json
name: ${name}
build:
  steps:
    - type: script
      commands:
        - $MOC_PATH --implicit-package core --default-persistent-actors -no-check-ir -E M0236 -E M0235 -E M0223 -E M0237 --actor-idl system-idl --package base $MOTOKO_BASE --package core $MOTOKO_CORE main.mo -o ${name}.wasm
        - mv ${name}.wasm "$ICP_WASM_OUTPUT_PATH"
`;
  }

  if (tier === 2) {
    // Same as tier 1 — these are major substrates
    return `# yaml-language-server: $schema=https://github.com/dfinity/icp-cli/raw/refs/heads/main/docs/schemas/canister-yaml-schema.json
name: ${name}
build:
  steps:
    - type: script
      commands:
        - $MOC_PATH --implicit-package core --default-persistent-actors -no-check-ir -E M0236 -E M0235 -E M0223 -E M0237 --actor-idl system-idl --package base $MOTOKO_BASE --package core $MOTOKO_CORE main.mo -o ${name}.wasm
        - mv ${name}.wasm "$ICP_WASM_OUTPUT_PATH"
`;
  }

  // Tier 3: simple config
  return `type: motoko
main: main.mo
`;
}

function generateMainMo(name, tier, template) {
  const actorName = name
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join("");

  const dateStr = new Date().toISOString().split("T")[0];

  if (tier <= 2) {
    return `// ${name}/main.mo — ${actorName} Substrate
// PARALLAX Sovereign Organism — Tier ${tier} Substrate
//
// PYTHAGORAS: all constants are phi-derived harmonics
// EUCLID:     single source of truth per domain
// CONFUCIUS:  right relationship — this substrate serves the organism
//
// Created: ${dateStr}
// ═══════════════════════════════════════════════════════════════════════════════

import Time      "mo:core/Time";
import Timer     "mo:core/Timer";
import Float     "mo:core/Float";
import Nat       "mo:core/Nat";
import Int       "mo:core/Int";
import Array     "mo:core/Array";
import Principal "mo:core/Principal";

actor ${actorName} {

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  let PHI : Float     = 1.618033988749895;
  let PHI_INV : Float = 0.618033988749895;
  let BEAT_MS : Nat   = 873;  // φ⁴ × 1000 / 7.83 Hz

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  var beat : Nat = 0;
  var coherence : Float = 0.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT — advances every 873ms
  // ═══════════════════════════════════════════════════════════════════════════

  private func heartbeat() : async () {
    beat += 1;
    // TODO: Add substrate-specific heartbeat logic
  };

  let _ = Timer.recurringTimer<system>(#nanoseconds(BEAT_MS * 1_000_000), heartbeat);

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  public query func getBeat() : async Nat { beat };

  public query func getCoherence() : async Float { coherence };

  public query func health() : async { beat : Nat; coherence : Float; name : Text } {
    { beat; coherence; name = "${name}" }
  };
};
`;
  }

  // Tier 3: minimal substrate
  return `// ${name}/main.mo — ${actorName} Substrate
// PARALLAX Sovereign Organism — Tier ${tier} Substrate
// Created: ${dateStr}
// ═══════════════════════════════════════════════════════════════════════════════

import Float     "mo:core/Float";
import Nat       "mo:core/Nat";

actor ${actorName} {

  let PHI : Float = 1.618033988749895;

  var beat : Nat = 0;

  public query func health() : async { beat : Nat; name : Text } {
    { beat; name = "${name}" }
  };
};
`;
}

function generateTypesMo(name) {
  return `// ${name}/types.mo — Type definitions for ${name} substrate
// ═══════════════════════════════════════════════════════════════════════════════

module {

  public type SubstrateHealth = {
    beat : Nat;
    coherence : Float;
    name : Text;
  };

  public type Signal = {
    source : Text;
    target : Text;
    amplitude : Float;
    frequency : Float;
    timestamp : Int;
  };
};
`;
}

function generateHeartbeatMo(name) {
  return `// ${name}/heartbeat.mo — Heartbeat logic for ${name} substrate
// ═══════════════════════════════════════════════════════════════════════════════

import Float "mo:core/Float";

module {

  let PHI : Float = 1.618033988749895;
  let PHI_INV : Float = 0.618033988749895;

  /// Compute coherence from current beat
  public func computeCoherence(beat : Nat, signals : [Float]) : Float {
    if (signals.size() == 0) return 0.0;

    var sum : Float = 0.0;
    for (s in signals.vals()) {
      sum += s;
    };
    let mean = sum / Float.fromInt(signals.size());

    // Normalize to [0, 1] via phi-gate
    if (mean >= PHI_INV) { mean } else { mean * PHI_INV }
  };
};
`;
}

async function updateIcpYaml(root, name) {
  const icpPath = join(root, "icp.yaml");
  let content = "";

  if (existsSync(icpPath)) {
    content = await readFile(icpPath, "utf-8");
  } else {
    content = `# yaml-language-server: $schema=https://github.com/dfinity/icp-cli/raw/refs/heads/main/docs/schemas/icp-yaml-schema.json
canisters:
`;
  }

  const entry = `  - src/${name}`;
  if (!content.includes(entry)) {
    content = content.trimEnd() + "\n" + entry + "\n";
    await writeFile(icpPath, content);
  }
}
