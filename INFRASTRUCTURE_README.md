# PARALLAX Infrastructure & Automation Suite

Complete development, testing, and production infrastructure for the PARALLAX sovereign AI platform.

## 🚀 Quick Start

```bash
# Setup development environment
./scripts/setup-dev.sh

# Build the platform
./scripts/build-all.sh

# Run full test suite
./scripts/test-all.sh

# Deploy locally
./scripts/deploy-local.sh

# Monitor system
parallax monitor --env local
```

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md) | Complete scripts & workflows guide |
| [TEST_SUITE.md](docs/TEST_SUITE.md) | Testing architecture and datasets |
| [AI_COMPONENTS_LANGUAGES.md](docs/AI_COMPONENTS_LANGUAGES.md) | Multi-AI and language protocols |
| [DEPLOY_WEB.md](docs/DEPLOY_WEB.md) | Production web deployment |

## 📦 What's Included

### Scripts (37 total)

**Build & Compilation (8 scripts)**
- `build-all.sh` — Full platform build
- `build-backend.sh` — Motoko backend
- `build-frontend.sh` — React frontend
- `build-services.sh` — Microservices
- `rebuild-clean.sh` — Clean rebuild
- `compile-motoko.sh` — Motoko compiler
- `generate-bindings.sh` — Candid bindings
- `typecheck-all.sh` — Type checking

**Testing & Validation (8 scripts)**
- `test-all.sh` — Full test suite
- `test-backend.sh` — Backend tests
- `test-frontend.sh` — Frontend tests
- `test-integration.sh` — Integration tests
- `test-security.sh` — Security scanning
- `test-performance.sh` — Performance tests
- `coverage-report.sh` — Coverage reports
- `validate-deployment.sh` — Pre-deployment checks

**Deployment & Operations (8 scripts)**
- `deploy-local.sh` — Local deployment
- `deploy-mainnet.sh` — Production deployment
- `deploy-staging.sh` — Staging environment
- `deploy-canary.sh` — Canary release
- `rollback.sh` — Rollback last deployment
- `health-check.sh` — System monitoring
- `manage-cycles.sh` — Canister cycles
- `debug-canister.sh` — Remote debugging

**Data & Datasets (5 scripts)**
- `generate-test-data.sh` — Test data generation
- `seed-db.sh` — Database seeding
- `export-data.sh` — Data export
- `sync-datasets.sh` — Dataset sync
- `cleanup-old-data.sh` — Data retention

**Development Utilities (8 scripts)**
- `setup-dev.sh` — Environment setup
- `lint-all.sh` — Linting
- `format-code.sh` — Code formatting
- `install-tools.sh` — Tool installation
- `run-dev-server.sh` — Dev server
- `watch-rebuild.sh` — Watch mode
- `generate-docs.sh` — Doc generation
- `create-release.sh` — Release creation

### GitHub Actions Workflows (12-15)

**Continuous Integration**
- Unit tests (push, PR)
- Integration tests (push to main)
- E2E tests (nightly, manual)
- Security scanning (every push)
- Dependency checks (weekly, PR)

**Building & Deployment**
- Backend build (push to main)
- Frontend build (push to main)
- Staging deployment (push to main)
- Canary release (manual)
- Production release (manual)

**Operations & Monitoring**
- Semantic versioning (manual)
- Documentation generation (push to main)
- Canister health monitoring (every 6h)
- Slack notifications (on workflow events)

### CLI Tools

#### `parallax` CLI (Go)

Production CLI for PARALLAX operations:

```bash
parallax init                              # Initialize project
parallax build --backend --frontend        # Build platform
parallax deploy --env mainnet --dry-run   # Deploy (preview)
parallax test --unit --coverage           # Run tests
parallax monitor --env mainnet            # Monitor system
parallax query --canister backend         # Query canister
```

**Installation:**
```bash
cd cli/parallax
make install
parallax --version
```

#### `aicli` AI CLI (Python)

AI-powered development assistant:

```bash
aicli explain src/backend/main.mo         # Explain code
aicli optimize src/backend/aloha_i.mo    # Optimization suggestions
aicli generate test --name MyTest         # Generate boilerplate
aicli diagnose --deep                     # System diagnostics
aicli query-model "Explain ALOHA I"      # Query AI models
aicli trace --txid abc123                 # Trace transaction
```

**Installation:**
```bash
cd cli/aicli
pip install -e .
aicli --version
```

## 🧪 Testing

### Test Framework

- **Unit**: Vitest (frontend), assert (backend)
- **Integration**: Custom harness
- **E2E**: Playwright
- **Performance**: k6, locust
- **Security**: SonarQube, npm audit, cargo audit

### Run Tests

```bash
./scripts/test-all.sh              # All tests
./scripts/test-all.sh --watch      # Watch mode
./scripts/test-all.sh --coverage   # With coverage
./scripts/test-backend.sh          # Backend only
./scripts/test-frontend.sh         # Frontend only
./scripts/test-integration.sh      # Integration only
```

### Coverage Requirements

- Statements: 90%
- Branches: 85%
- Functions: 90%
- Lines: 90%

**Generate Coverage Report:**
```bash
./scripts/coverage-report.sh
open coverage/index.html
```

## 🚢 Deployment

### Local Development

```bash
./scripts/deploy-local.sh
```

### Staging (ICP)

```bash
./scripts/deploy-staging.sh
```

### Production (ICP Mainnet)

```bash
./scripts/deploy-mainnet.sh
```

### Canary Release

```bash
./scripts/deploy-canary.sh --percentage 10  # Deploy to 10%
# Monitor metrics...
./scripts/deploy-canary.sh --percentage 100 # Full rollout
```

### Rollback

```bash
./scripts/rollback.sh --env mainnet
```

## 🤖 Multi-AI Components

**Thought Compression** — Compress multi-step reasoning into tokens
**Model Routing** — Route requests to optimal AI models
**Chain-of-Thought** — Multi-step reasoning with caching
**Few-Shot Generation** — Dynamic prompt engineering
**Confidence Scoring** — Calibrated uncertainty estimates
**Adaptive Planning** — AI adjusts strategy based on context

## 🔤 Language Protocols

- **Nova-Lang** — ML-optimized reasoning language
- **Motoko-Ext** — Extended Motoko for AI primitives
- **WebSphere-Protocol** — Network topology description
- **Oracle-Query-Language** — Declarative data fetching
- **Strategy-DSL** — Trading strategy language

## 📊 Monitoring & Observability

### Health Checks

```bash
./scripts/health-check.sh --interval 5
```

### Metrics

- Canister method latency
- Frontend render performance
- Database query performance
- Memory usage
- Cycles consumption
- Error rates

### Dashboards

Built-in Grafana dashboards for:
- System health
- Performance metrics
- Deployment status
- Test coverage
- Security posture

## 🔐 Security

**Automated Scanning:**
- SAST (SonarQube)
- DAST (OWASP ZAP)
- Dependency scanning (npm, cargo, pip)
- Secret scanning (TruffleHog)
- Container scanning (Trivy)

**Run Security Tests:**
```bash
./scripts/test-security.sh
./scripts/test-security.sh --fix  # Auto-fix issues
```

## 📈 Performance

**Performance Benchmarking:**
```bash
./scripts/test-performance.sh --benchmark
```

**Load Testing:**
```bash
./scripts/test-performance.sh --load
```

**Profiling:**
```bash
./scripts/test-performance.sh --profile
```

## 🛠️ Development Workflow

### Daily Development

```bash
# Start development server
./scripts/run-dev-server.sh

# Watch for changes
./scripts/watch-rebuild.sh

# Run tests on save
./scripts/test-all.sh --watch

# Format code before commit
./scripts/format-code.sh

# Create release
./scripts/create-release.sh --version 1.2.0
```

### Pre-Commit Checks

```bash
./scripts/lint-all.sh --fix     # Auto-fix linting
./scripts/typecheck-all.sh      # Type checking
./scripts/test-all.sh           # Run tests
```

## 📋 Configuration

**Project Configuration:** `.parallax.yaml`
**User CLI Config:** `~/.parallax.yaml`
**AI CLI Config:** `~/.aicli/config.yaml`

## 🔄 CI/CD Pipeline

All workflows run automatically:

| Trigger | Workflows |
|---------|-----------|
| Push to main | Tests, builds, deploy to staging |
| Pull request | Unit tests, security checks |
| Nightly | Full E2E test suite |
| Weekly | Dependency updates, full scan |
| Every 6h | Canister health checks |
| Manual | Canary release, production deploy |

## 📦 Artifacts

Built artifacts are stored in GitHub:
- Test reports (JUnit XML)
- Coverage reports (HTML)
- Performance benchmarks (JSON)
- Build artifacts (WASM, dist/)
- Docker images (ghcr.io)

## 🆘 Troubleshooting

### Build Failures

```bash
./scripts/rebuild-clean.sh  # Clean rebuild
./scripts/validate-deployment.sh --env local
```

### Test Failures

```bash
./scripts/test-all.sh --verbose  # Verbose output
./scripts/coverage-report.sh     # Coverage report
```

### Deployment Issues

```bash
./scripts/validate-deployment.sh --env mainnet
./scripts/health-check.sh
./scripts/debug-canister.sh --canister backend
```

## 📚 Additional Resources

- [ICP Documentation](https://internetcomputer.org/docs/)
- [Motoko Docs](https://internetcomputer.org/docs/current/developer-docs/build/languages/motoko/)
- [React Documentation](https://react.dev/)
- [Go Documentation](https://golang.org/doc/)
- [Python Documentation](https://docs.python.org/)

## 🤝 Contributing

All infrastructure scripts follow these conventions:
- Error handling with clear messages
- Color-coded output (✅, ❌, ▸)
- Dry-run mode where applicable
- Detailed usage documentation
- Production-ready quality

## 📝 License

This infrastructure is part of PARALLAX, which is licensed under the Same License as the main project.

---

**Last Updated:** June 2026

**Infrastructure Version:** 1.0.0

**Status:** Complete with full automation ✅

---

## 🎯 Next Steps

1. **Run Setup:** `./scripts/setup-dev.sh`
2. **Build Platform:** `./scripts/build-all.sh`
3. **Run Tests:** `./scripts/test-all.sh`
4. **Deploy Locally:** `./scripts/deploy-local.sh`
5. **Install CLI Tools:** `make install` (cli/parallax and cli/aicli)
6. **Read Documentation:** Start with [INFRASTRUCTURE.md](docs/INFRASTRUCTURE.md)

---

**Questions?** Check the troubleshooting section or refer to individual script usage docs.
