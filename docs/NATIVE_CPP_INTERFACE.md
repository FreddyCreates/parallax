# PARALLAX Native C/C++ Interface

This document defines the native interface for PARALLAX AI Wallet alpha.

The native layer exists so C and C++ systems can create AI wallets, build commands, evaluate policy, and emit receipts without depending on Node.js or the TypeScript runtime.

## Location

```text
src/native/ai-wallet/
```

## What it provides

| Layer | Artifact | Purpose |
|---|---|---|
| C ABI | `include/parallax/ai_wallet.h` | stable C interface for wallets, commands, evaluations, receipts |
| C implementation | `src/ai_wallet.c` | no-runtime policy engine and receipt helper |
| C++ wrapper | `include/parallax/ai_wallet.hpp` | modern C++17 wrapper around the C ABI |
| Build | `CMakeLists.txt` | standalone native build and install target |
| Tests | `tests/` | C and C++ tests for policy gates and receipt behavior |
| Demo | `examples/ai_wallet_demo.cpp` | working CLI/demo executable |

## Build

From the repo root:

```bash
pnpm native:configure
pnpm native:build
pnpm native:test
```

Or directly:

```bash
cmake -S src/native/ai-wallet -B build/native/ai-wallet
cmake --build build/native/ai-wallet
ctest --test-dir build/native/ai-wallet --output-on-failure
```

## C usage

```c
#include "parallax/ai_wallet.h"

parallax_aiw_wallet wallet;
parallax_aiw_wallet_config config = {0};
config.agent_id = "agent.parallax.native-01";
config.display_name = "Native AI Wallet";
config.owner_principal = "principal-owner";
config.controller_principal = "principal-controller";
config.created_at = "2026-07-09T00:00:00Z";
config.mode = PARALLAX_AIW_MODE_PAPER;

parallax_aiw_create_wallet(&config, &wallet);
```

## C++ usage

```cpp
#include "parallax/ai_wallet.hpp"

using namespace parallax::ai_wallet;

Wallet wallet(
    "agent.parallax.native-01",
    "PARALLAX Native AI Wallet",
    "principal-owner",
    "principal-controller",
    "2026-07-09T00:00:00Z");

const auto command = wallet.make_paper_order(
    "PXICP",
    100.0,
    30.0,
    "principal-controller",
    "approval-001",
    "2026-07-09T00:00:00Z");

const auto evaluation = wallet.evaluate(command, 0.0, "2026-07-09T00:00:00Z");
const auto receipt = wallet.make_receipt(command, evaluation, "principal-controller");
```

## Alpha policy defaults

| Rule | Default |
|---|---|
| allowed modes | paper, testnet |
| blocked modes | restricted_live, live |
| allowed assets | PXUSD, PXICP, PXAI, PXGPU, PXETH |
| allowed counterparties | internal, paper-market, research-mint, operator |
| max command notional | 10,000 |
| daily notional limit | 50,000 |
| human approval threshold | 2,500 |
| commands requiring approval | transfer, order |

## Decisions

The native policy engine returns one of:

- `PARALLAX_AIW_DECISION_APPROVED`
- `PARALLAX_AIW_DECISION_REJECTED`
- `PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL`

Reason bits are explicit and can be checked with:

```c
parallax_aiw_has_reason(&evaluation, PARALLAX_AIW_REASON_LIVE_MODE_BLOCKED);
```

## Production boundary

This interface is production-shaped and buildable, but it preserves the alpha boundary:

- no live money movement,
- no live broker routing,
- no private key custody,
- no AI self-approval above threshold,
- no skipped receipts,
- no hidden live-mode switch.

## Next integration gates

1. Bind this native interface into strategy workers.
2. Add a shared receipt sink that writes native receipts to the global receipt ledger.
3. Add a native strategy simulation executable.
4. Add GitHub Actions matrix builds for Linux/macOS/Windows.
5. Expose native health in Alpha Ops Control Tower.
