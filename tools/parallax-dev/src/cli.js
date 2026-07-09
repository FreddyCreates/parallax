#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Dev CLI — Native ICP Development Toolchain
// Scaffolding · Bindgen · Canister Management · Multi-Substrate Orchestration
// ═══════════════════════════════════════════════════════════════════════════════

import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { scaffold } from "./commands/scaffold.js";
import { bindgen } from "./commands/bindgen.js";
import { deploy } from "./commands/deploy.js";
import { status } from "./commands/status.js";
import { list } from "./commands/list.js";
import { sync } from "./commands/sync.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, "../../../");

const HELP = `
┌────────────────────────────────────────────────────────────────────┐
│          🌌 PARALLAX Dev — Native ICP Toolchain                    │
│          Multi-Substrate Organism Development                      │
└────────────────────────────────────────────────────────────────────┘

Usage: parallax <command> [options]

Commands:
  scaffold <name> [--tier <1|2|3>]   Create a new substrate canister
  bindgen [--canister <name>]        Generate TypeScript bindings from .did files
  deploy [--env <local|ic>]          Deploy all or specific canisters
  status                             Show all canister states and health
  list                               List all substrates in the organism
  sync                               Sync icp.yaml with discovered canisters

Options:
  --help, -h      Show this help
  --version, -v   Show version

Examples:
  parallax scaffold memory_pool --tier 2
  parallax bindgen
  parallax deploy --env local
  parallax status
  parallax list
  parallax sync
`;

function parseArgs(argv) {
  const args = argv.slice(2);
  const command = args[0];
  const positional = [];
  const flags = {};

  for (let i = 1; i < args.length; i++) {
    if (args[i].startsWith("--")) {
      const key = args[i].slice(2);
      const next = args[i + 1];
      if (next && !next.startsWith("--")) {
        flags[key] = next;
        i++;
      } else {
        flags[key] = true;
      }
    } else if (args[i].startsWith("-")) {
      const key = args[i].slice(1);
      flags[key] = true;
    } else {
      positional.push(args[i]);
    }
  }

  return { command, positional, flags };
}

async function main() {
  const { command, positional, flags } = parseArgs(process.argv);

  if (!command || flags.help || flags.h || command === "--help" || command === "-h") {
    console.log(HELP);
    process.exit(0);
  }

  if (flags.version || flags.v) {
    console.log("@parallax/dev v0.1.0");
    process.exit(0);
  }

  const ctx = { root: ROOT, __dirname };

  try {
    switch (command) {
      case "scaffold":
        if (!positional[0]) {
          console.error("Error: scaffold requires a substrate name");
          console.error("Usage: parallax scaffold <name> [--tier <1|2|3>]");
          process.exit(1);
        }
        await scaffold(ctx, positional[0], flags);
        break;

      case "bindgen":
        await bindgen(ctx, flags);
        break;

      case "deploy":
        await deploy(ctx, flags);
        break;

      case "status":
        await status(ctx, flags);
        break;

      case "list":
        await list(ctx, flags);
        break;

      case "sync":
        await sync(ctx, flags);
        break;

      default:
        console.error(`Unknown command: ${command}`);
        console.log(HELP);
        process.exit(1);
    }
  } catch (err) {
    console.error(`\n❌ Error: ${err.message}`);
    if (flags.verbose) console.error(err.stack);
    process.exit(1);
  }
}

main();
