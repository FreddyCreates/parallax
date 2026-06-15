# PARALLAX Infrastructure Guide

Complete development and production infrastructure for PARALLAX AI platform.

---

## Table of Contents

1. [Scripts Directory](#scripts-directory)
2. [Workflows](#github-actions-workflows)
3. [CLI Tools](#cli-tools)
4. [Quick Start](#quick-start)
5. [Advanced Usage](#advanced-usage)

---

## Scripts Directory

All operational scripts are in the `scripts/` directory. They are organized by function:

### Build & Compilation (8 scripts)

- **`build-all.sh`** — Build entire platform
  ```bash
  ./scripts/build-all.sh           # Build everything
  ./scripts/build-all.sh --clean   # Clean rebuild
  ```

- **`build-backend.sh`** — Motoko backend only
  ```bash
  ./scripts/build-backend.sh
  ```

- **`build-frontend.sh`** — React frontend only
  ```bash
  ./scripts/build-frontend.sh
  ```

- **`build-services.sh`** — Microservices (Rust, Go, Python)
  ```bash
  ./scripts/build-services.sh --service rust-engine  # Build specific service
  ```

- **`rebuild-clean.sh`** — Full clean rebuild
  ```bash
  ./scripts/rebuild-clean.sh       # Remove all artifacts, rebuild
  ```

- **`compile-motoko.sh`** — Motoko compiler wrapper
  ```bash
  ./scripts/compile-motoko.sh
  ```

- **`generate-bindings.sh`** — Generate Candid bindings
  ```bash
  ./scripts/generate-bindings.sh
  ```

- **`typecheck-all.sh`** — TypeScript + Motoko type checking
  ```bash
  ./scripts/typecheck-all.sh
  ```

### Testing & Validation (8 scripts)

- **`test-all.sh`** — Full test suite
  ```bash
  ./scripts/test-all.sh            # Run all tests
  ./scripts/test-all.sh --unit     # Unit tests only
  ./scripts/test-all.sh --coverage # With coverage report
  ```

- **`test-backend.sh`** — Backend unit tests
  ```bash
  ./scripts/test-backend.sh
  ```

- **`test-frontend.sh`** — Frontend (Vitest)
  ```bash
  ./scripts/test-frontend.sh
  ```

- **`test-integration.sh`** — Integration tests
  ```bash
  ./scripts/test-integration.sh
  ```

- **`test-security.sh`** — Security scanning
  ```bash
  ./scripts/test-security.sh       # Audit + SAST
  ./scripts/test-security.sh --fix # Auto-fix issues
  ```

- **`test-performance.sh`** — Load & performance tests
  ```bash
  ./scripts/test-performance.sh --threshold 95  # Min acceptable score
  ```

- **`coverage-report.sh`** — Coverage reports
  ```bash
  ./scripts/coverage-report.sh     # Generate HTML report
  ```

- **`validate-deployment.sh`** — Pre-deployment validation
  ```bash
  ./scripts/validate-deployment.sh --env mainnet
  ```

### Deployment & Operations (8 scripts)

- **`deploy-local.sh`** — Local deployment
  ```bash
  ./scripts/deploy-local.sh        # Deploy to local ICP
  ```

- **`deploy-mainnet.sh`** — ICP mainnet deployment
  ```bash
  ./scripts/deploy-mainnet.sh      # Deploy to production
  ./scripts/deploy-mainnet.sh backend  # Backend only
  ```

- **`deploy-staging.sh`** — Staging environment
  ```bash
  ./scripts/deploy-staging.sh
  ```

- **`deploy-canary.sh`** — Canary release
  ```bash
  ./scripts/deploy-canary.sh --percentage 10  # Deploy to 10% of traffic
  ```

- **`rollback.sh`** — Rollback deployment
  ```bash
  ./scripts/rollback.sh --env mainnet  # Rollback mainnet
  ```

- **`health-check.sh`** — Health monitoring
  ```bash
  ./scripts/health-check.sh --interval 5  # Check every 5 seconds
  ```

- **`manage-cycles.sh`** — Canister cycles management
  ```bash
  ./scripts/manage-cycles.sh --top-up 1000000000  # Add 1 billion cycles
  ./scripts/manage-cycles.sh --status             # Show status
  ```

- **`debug-canister.sh`** — Remote debugging
  ```bash
  ./scripts/debug-canister.sh --canister backend --method "getState"
  ```

### Data & Datasets (5 scripts)

- **`generate-test-data.sh`** — Create test datasets
  ```bash
  ./scripts/generate-test-data.sh --count 1000  # Generate 1000 records
  ```

- **`seed-db.sh`** — Seed development database
  ```bash
  ./scripts/seed-db.sh --environment dev
  ```

- **`export-data.sh`** — Export data (anonymized)
  ```bash
  ./scripts/export-data.sh --format json  # Export to JSON
  ```

- **`sync-datasets.sh`** — Sync remote datasets
  ```bash
  ./scripts/sync-datasets.sh --source production
  ```

- **`cleanup-old-data.sh`** — Data retention
  ```bash
  ./scripts/cleanup-old-data.sh --older-than 30d  # Remove 30+ day old data
  ```

### Development Utilities (8 scripts)

- **`setup-dev.sh`** — Environment setup
  ```bash
  ./scripts/setup-dev.sh           # One-time setup
  ```

- **`lint-all.sh`** — Linting with auto-fix
  ```bash
  ./scripts/lint-all.sh            # Check linting
  ./scripts/lint-all.sh --fix      # Auto-fix issues
  ```

- **`format-code.sh`** — Code formatting
  ```bash
  ./scripts/format-code.sh         # Format code
  ```

- **`install-tools.sh`** — Install required tools
  ```bash
  ./scripts/install-tools.sh       # Install all tools
  ```

- **`run-dev-server.sh`** — Development server
  ```bash
  ./scripts/run-dev-server.sh      # Start dev server
  ```

- **`watch-rebuild.sh`** — Watch mode
  ```bash
  ./scripts/watch-rebuild.sh       # Watch and rebuild
  ```

- **`generate-docs.sh`** — Generate documentation
  ```bash
  ./scripts/generate-docs.sh       # Build all docs
  ```

- **`create-release.sh`** — Release creation
  ```bash
  ./scripts/create-release.sh --version 1.2.0  # Create release
  ```

---

## GitHub Actions Workflows

All workflows are in `.github/workflows/` and run automatically on push/PR.

### Continuous Integration

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `test-unit.yml` | Push, PR | Unit test suite |
| `test-integration.yml` | Push to main | Integration tests |
| `test-e2e.yml` | Nightly, manual | End-to-end tests |
| `security-sast.yml` | Every push | Security scanning |
| `security-deps.yml` | Weekly, PR | Dependency checks |

### Building

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build-backend.yml` | Push to main | Build Motoko backend |
| `build-frontend.yml` | Push to main | Build React frontend |

### Deployment

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `deploy-staging.yml` | Push to main | Deploy to staging |
| `deploy-canary.yml` | Manual trigger | Canary release |

### Operations

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `release-semantic.yml` | Manual trigger | Create release |
| `docs-generation.yml` | Push to main | Build documentation |
| `monitoring-health.yml` | Every 6 hours | Canister health check |

### Notifications

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `notify-slack.yml` | Other workflows | Send Slack alerts |

---

## CLI Tools

### parallax CLI

Production-ready CLI tool for PARALLAX operations:

```bash
# Initialize new project
parallax init

# Build the platform
parallax build --backend --frontend --services
parallax build --clean --no-cache

# Deploy to environments
parallax deploy --env local
parallax deploy --env staging
parallax deploy --env mainnet --dry-run

# Run tests
parallax test --unit --coverage
parallax test --e2e --watch

# Monitor system
parallax monitor --env mainnet --interval 5

# Query canister state
parallax query --canister backend --method "getState" --output json
```

**Installation:**
```bash
cd cli/parallax
go build -o parallax
./parallax version
```

### aicli AI CLI

AI-powered assistant for code and system analysis:

```bash
# Explain code
aicli explain src/backend/main.mo --detail full

# Get optimization suggestions
aicli optimize src/backend/aloha_i.mo --target speed

# Generate boilerplate
aicli generate test --name MyTest --template unit

# Diagnose system
aicli diagnose --deep

# Query AI models
aicli query-model "Explain the ALOHA I protocol"

# Trace transaction
aicli trace --txid abc123 --canister backend
```

**Installation:**
```bash
cd cli/aicli
pip install -e .
aicli --version
```

---

## Quick Start

### First-time setup:

```bash
# 1. Install dependencies and tools
./scripts/setup-dev.sh

# 2. Build the platform
./scripts/build-all.sh

# 3. Run tests
./scripts/test-all.sh

# 4. Deploy locally
./scripts/deploy-local.sh

# 5. Start development server
./scripts/run-dev-server.sh
```

### Using the CLI tools:

```bash
# Install parallax CLI
cd cli/parallax && make install

# Use parallax for common operations
parallax build --clean
parallax test --coverage
parallax deploy --env staging

# Install aicli
cd cli/aicli && pip install -e .

# Use aicli for AI-assisted development
aicli explain src/backend/main.mo
aicli optimize src/backend/phantom_exchange.mo
```

---

## Advanced Usage

### CI/CD Pipeline

The workflows are automatically triggered:

- **On every push to main**: Run tests, build, deploy to staging
- **On pull requests**: Run unit tests and security checks
- **Nightly**: Run full E2E test suite
- **Weekly**: Check dependencies for updates
- **Every 6 hours**: Monitor canister health

### Deployment Strategies

**Blue-Green Deployment:**
```bash
./scripts/deploy-staging.sh      # Deploy to staging (green)
./scripts/health-check.sh        # Verify health
./scripts/deploy-mainnet.sh      # Promote to mainnet (blue)
```

**Canary Release:**
```bash
./scripts/deploy-canary.sh --percentage 10   # Deploy to 10%
# Monitor metrics...
./scripts/deploy-canary.sh --percentage 100  # Full rollout
```

**Rollback:**
```bash
./scripts/rollback.sh --env mainnet  # Rollback to previous version
```

### Performance Monitoring

```bash
# Run performance tests
./scripts/test-performance.sh --threshold 95

# Monitor in real-time
./scripts/health-check.sh --interval 5

# Generate reports
./scripts/coverage-report.sh
```

### Data Management

```bash
# Generate test data
./scripts/generate-test-data.sh --count 10000

# Export production data
./scripts/export-data.sh --format json --output data.json

# Clean old data
./scripts/cleanup-old-data.sh --older-than 30d
```

---

## Configuration Files

- **`.parallax.yaml`** — Project configuration
- **`~/.parallax.yaml`** — User configuration (parallax CLI)
- **`~/.aicli/config.yaml`** — AI CLI configuration

---

## Troubleshooting

### Build failures
```bash
# Clean rebuild
./scripts/rebuild-clean.sh

# Check environment
./scripts/validate-deployment.sh --env local
```

### Deployment issues
```bash
# Pre-deployment validation
./scripts/validate-deployment.sh --env mainnet

# Check canister health
./scripts/health-check.sh

# Debug canister state
./scripts/debug-canister.sh --canister backend
```

### Test failures
```bash
# Run with verbose output
./scripts/test-all.sh --verbose

# Generate coverage report
./scripts/coverage-report.sh
```

---

## Documentation

- [DEPLOY_WEB.md](../docs/DEPLOY_WEB.md) — Web deployment guide
- [Architecture](../ARCHITECTURE.md) — System architecture
- [Security](../SECURITY.md) — Security protocols

---

**Last Updated:** June 2026
