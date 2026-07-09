# 🌌 PARALLAX Dev — Native ICP Development Toolchain

> Multi-substrate organism development: scaffolding, bindgen, and canister management.

## Quick Start

```bash
# List all substrates in the organism
pnpm parallax list

# Show substrate health and status
pnpm parallax status

# Scaffold a new substrate canister
pnpm parallax scaffold memory_pool --tier 2

# Sync icp.yaml with discovered canisters
pnpm parallax sync

# Generate TypeScript bindings
pnpm parallax bindgen

# Deploy all substrates
pnpm parallax deploy --env local
```

## Commands

### `parallax scaffold <name> [--tier <1|2|3>]`

Create a new substrate canister with proper templates and wiring.

| Tier | Description | What it generates |
|------|-------------|-------------------|
| 1 | Core | Full build script, heartbeat, types, system-idl |
| 2 | Major substrate | Full build script, heartbeat, types, system-idl |
| 3 | Support (default) | Simple canister.yaml, minimal actor |

The scaffold command:
- Creates `src/<name>/` directory with `main.mo` and `canister.yaml`
- Generates phi-derived heartbeat logic for Tier 1/2
- Creates `types.mo` and `heartbeat.mo` modules for Tier 1/2
- Automatically updates `icp.yaml` to include the new canister

**Naming**: Use `snake_case` (e.g., `memory_pool`, `signal_router`, `quantum_cache`).

### `parallax bindgen [--canister <name>]`

Generate TypeScript bindings from `.did` interface files.

- Uses `didc` (official Candid compiler) if available
- Falls back to a built-in parser that generates typed wrappers
- Outputs to `src/frontend/src/declarations/<canister>/`
- Generates barrel `index.ts` for easy imports

### `parallax deploy [--env <local|ic>] [--canister <name>]`

Deploy all or specific canisters with dependency ordering.

- Starts local network automatically (for `--env local`)
- Creates canisters if they don't exist
- Resolves and exports canister IDs as env vars
- Deploys in tier order: Core → Major → Support

### `parallax status`

Show the health of all substrates:
- File counts, build state, IDL presence
- Grouped by tier
- Network status (if ICP CLI available)

### `parallax list [--json]`

List all substrates with tier classification.

### `parallax sync`

Sync `icp.yaml` with all discovered canisters in `src/`:
- Auto-discovers substrates by finding `canister.yaml` files
- Orders: frontend/backend first, then alphabetical
- Reports additions and removals

## Architecture

```
tools/parallax-dev/
├── src/
│   ├── cli.js              # Entry point, argument parsing
│   ├── discovery.js        # Canister discovery & YAML parsing
│   └── commands/
│       ├── scaffold.js     # Create new substrates
│       ├── bindgen.js      # TypeScript binding generation
│       ├── deploy.js       # Multi-canister deployment
│       ├── status.js       # Organism health check
│       ├── list.js         # Substrate listing
│       └── sync.js         # icp.yaml synchronization
├── templates/
│   ├── tier2_substrate.mo  # Template for major substrates
│   ├── tier3_substrate.mo  # Template for support substrates
│   └── canister.yaml.tier2 # Template canister.yaml
└── package.json
```

## Substrate Tiers

The PARALLAX organism organizes canisters into tiers:

| Tier | Role | Examples |
|------|------|----------|
| **1 — Core** | The sovereign organism itself | `backend`, `frontend` |
| **2 — Major** | Essential cognitive substrates | `brain`, `alpha_conductor`, `alpha_orchestrator`, `bridges` |
| **3 — Support** | Domain-specific services | `chrono`, `flux`, `qmem`, `resonex`, `veritas`, `axis` |

## Integration with Existing Tools

- **Caffeine**: The toolchain complements `caffeine.toml` — it manages the multi-canister aspects that caffeine doesn't cover natively.
- **Mops**: Package deps in `mops.toml` are respected. Scaffolded canisters import from `mo:core/` and `mo:base/`.
- **ICP CLI**: Deploy uses `icp` CLI under the hood for canister creation and deployment.
- **pnpm**: The toolchain is a workspace package, runnable via `pnpm parallax <command>`.

## NPM Script Shortcuts

```json
{
  "parallax": "node tools/parallax-dev/src/cli.js",
  "scaffold": "node tools/parallax-dev/src/cli.js scaffold",
  "substrate:bindgen": "node tools/parallax-dev/src/cli.js bindgen",
  "substrate:deploy": "node tools/parallax-dev/src/cli.js deploy",
  "substrate:status": "node tools/parallax-dev/src/cli.js status",
  "substrate:list": "node tools/parallax-dev/src/cli.js list",
  "substrate:sync": "node tools/parallax-dev/src/cli.js sync"
}
```

## Why Native?

The PARALLAX organism always needs **multi-substrate** architecture. External tools like `dfx` or `caffeine` handle single-canister workflows well, but don't natively understand:

1. **Tier-based deployment ordering** — Core must deploy before Major before Support
2. **Phi-derived scaffolding** — New substrates need heartbeat, coherence, and organism conventions baked in
3. **Multi-canister bindgen** — Generate TS bindings for ALL substrates at once
4. **Organism topology** — Understanding the relationship between substrates
5. **Auto-discovery** — Finding all canisters without manual manifest maintenance

This toolchain fills that gap.
