# aicli

`aicli` is a production-oriented AI command line tool for the PARRALAX ecosystem. It routes analysis and generation tasks to configured PARALLAX AI backends, falls back to local Ollama models when needed, and preserves auditability with caching, profiles, logging, and structured exports.

## Features

- Typer + Rich powered CLI UX
- PARALLAX backend model routing with local Ollama fallback
- Thought compression and adaptive prompting
- Confidence scoring and reasoning metadata
- Streaming responses and progress indicators
- Audit logging and local cache for repeated queries
- Internet Identity-aware auth headers via config or environment
- Batch-ready JSON/CSV output paths and offline heuristics
- Plugin entry-point architecture (`aicli.plugins`)

## Installation

```bash
cd cli/aicli
pip install -e .
# or
pip install .
```

## Configuration

The CLI stores runtime configuration in `~/.aicli/config.yaml`.

Key settings:

- `default_profile`: active profile (`dev` or `prod`)
- `backend.url`: PARALLAX AI endpoint
- `backend.auth`: Internet Identity principal and delegation token
- `ollama.url`: local Ollama server
- `offline_mode`: disable remote calls where possible

## Commands

```bash
aicli explain path/to/file.py --detail full --output markdown
aicli optimize src/backend --target speed
aicli generate test --name test_router --dry-run
aicli diagnose --deep --output json
aicli query-model "Explain this stack trace" --session debug-1
aicli trace 0xdeadbeef --canister ledger --depth 4
```

## Plugin Architecture

Third parties can extend `aicli` via the `aicli.plugins` entry-point group.
A plugin may either:

- expose a `Typer` app, or
- expose a `register(app: typer.Typer)` function.

## Notes

- Query activity is logged to `~/.aicli/audit.log`.
- Cached responses are stored in `~/.aicli/cache.sqlite3`.
- Conversation state is stored in `~/.aicli/sessions/`.
