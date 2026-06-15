# parallax

`parallax` is a production-focused Go CLI for initializing, building, deploying, testing, monitoring, and querying PARALLAX projects.

## Features

- Cobra-based multi-command CLI
- Viper configuration with `~/.parallax.yaml`, `.parallax.yaml`, and `PARALLAX_*` environment overrides
- Colored terminal output with JSON mode for automation
- Build/test/deploy workflows driven by project scripts with sensible fallbacks
- Real-time canister monitoring and direct ICP canister queries
- Bash/Zsh/Fish/PowerShell completion generation

## Install

```bash
cd cli/parallax
go install .
```

## Commands

```bash
parallax init
parallax build --backend --clean
parallax deploy --env staging --dry-run
parallax test --unit --coverage
parallax monitor --env mainnet --interval 10s
parallax query --canister-id <id> --method status --output json
```

## Configuration

Global defaults live in `~/.parallax.yaml`.
Project-specific settings live in `.parallax.yaml` at the repository root.
Environment variables override config values using the `PARALLAX_` prefix.

Example:

```yaml
project:
  name: parallax-aihftfund
  id: parallax-aihftfund
  network: local

scripts:
  dir: scripts

environments:
  local:
    network: local
    identity: default
  staging:
    network: staging
    identity: staging
  mainnet:
    network: mainnet
    identity: prod

monitor:
  default_interval: 5s
  canisters:
    - backend
    - frontend
```

## Script conventions

The CLI prefers script-driven workflows:

- `scripts/build-backend.sh`
- `scripts/build-frontend.sh`
- `scripts/build-<service>.sh`
- `scripts/test-unit.sh`
- `scripts/test-integration.sh`
- `scripts/test-e2e.sh`
- `scripts/deploy-local.sh`
- `scripts/deploy-staging.sh`
- `scripts/deploy-mainnet.sh`
- `scripts/rollback-<env>.sh`

When scripts are missing, the CLI falls back to common PARALLAX commands where possible.

## Completion

```bash
parallax completion bash > ~/.bash_completion.d/parallax
parallax completion zsh > "${fpath[1]}/_parallax"
```

## Makefile targets

- `make build`
- `make install`
- `make test`
- `make completion`
