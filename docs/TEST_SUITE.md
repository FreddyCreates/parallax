# PARALLAX Test Suite & Datasets

Complete testing infrastructure and datasets for the PARALLAX AI platform.

---

## Test Architecture

```
tests/
├── unit/                    # Unit tests
│   ├── backend/            # Motoko tests
│   ├── frontend/           # React/TypeScript tests
│   └── services/           # Microservice tests
├── integration/            # Integration tests
│   ├── backend-frontend/   # Cross-system tests
│   ├── services/           # Service mesh tests
│   └── canister-calls/     # ICP canister integration
├── e2e/                    # End-to-end tests
│   ├── frontend/           # Playwright tests
│   ├── api/                # API tests
│   └── workflows/          # Complete workflow tests
├── performance/            # Performance & load tests
│   ├── benchmarks/         # Microbenchmarks
│   ├── load/               # Load testing
│   └── profiling/          # Profiling tests
├── security/               # Security tests
│   ├── sast/               # Static analysis
│   ├── dast/               # Dynamic analysis
│   └── fuzzing/            # Fuzz testing
├── fixtures/               # Test fixtures
│   ├── mocks/              # Mock data
│   └── factories/          # Factory functions
└── datasets/               # Test datasets
    ├── market-data/        # Historical prices
    ├── trading-scenarios/  # Trade test cases
    ├── ml-training/        # ML datasets
    └── benchmarks/         # Baseline metrics
```

---

## Unit Testing

### Backend (Motoko)

**Framework:** Built-in assert macros

**Test Files:**
```
tests/unit/backend/
├── test_aloha_i.mo         # ALOHA I protocols
├── test_phantom_exchange.mo # Trading engine
├── test_nova_runtime.mo    # Runtime
├── test_token_factory.mo   # Token system
├── test_web_sphere.mo      # Network topology
└── test_sovereign_db.mo    # Database
```

**Example Test:**
```motoko
import Debug "mo:base/Debug";
import Assert "mo:base/assert";

actor Tests {
  public func testALOHAIHealth() : async () {
    let alohaiState = initALOHAI();
    assert(alohaiState.coherence >= 0.0 and alohaiState.coherence <= 1.0);
    Debug.print("✅ ALOHA I health check passed");
  };
};
```

### Frontend (React/TypeScript)

**Framework:** Vitest

**Test Files:**
```
tests/unit/frontend/
├── components/             # Component tests
├── hooks/                  # Hook tests
├── utils/                  # Utility tests
└── stores/                 # Store tests
```

**Run Tests:**
```bash
pnpm test                  # Run tests
pnpm test --watch         # Watch mode
pnpm test --coverage      # With coverage
```

### Services (Rust/Go/Python)

**Frameworks:** 
- Rust: cargo test
- Go: go test
- Python: pytest

---

## Integration Testing

### Cross-System Tests

**Test Scenarios:**
1. Frontend → Backend canister communication
2. Backend canister → ICP system interaction
3. Service mesh message routing
4. Database transactions across systems
5. Authentication flow end-to-end

**Run Integration Tests:**
```bash
./scripts/test-integration.sh
```

---

## End-to-End Testing

### Frontend E2E (Playwright)

**Test Scenarios:**
```
tests/e2e/frontend/
├── landing.spec.ts         # Landing page flow
├── dashboard.spec.ts       # Dashboard interaction
├── authentication.spec.ts  # Login/logout
├── trading.spec.ts         # Trading UI
└── forms.spec.ts          # Form validation
```

**Example:**
```typescript
import { test, expect } from '@playwright/test';

test('user can login and view dashboard', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.click('text=Login with Internet Identity');
  // ... auth flow ...
  await expect(page.locator('text=Dashboard')).toBeVisible();
});
```

### API E2E

**Test Scenarios:**
```
tests/e2e/api/
├── canister-api.spec.ts    # Canister endpoints
├── http-outcalls.spec.ts   # External calls
└── state-management.spec.ts # State updates
```

**Run E2E Tests:**
```bash
./scripts/test-e2e.sh
```

---

## Performance Testing

### Benchmarks

**Scenarios:**
- Backend canister method call latency
- Frontend render performance
- Database query performance
- Network throughput
- Memory usage

**Run Benchmarks:**
```bash
./scripts/test-performance.sh --benchmark
```

### Load Testing

**Tools:** k6, locust

**Test Scenarios:**
```javascript
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up
    { duration: '5m', target: 100 },   // Steady
    { duration: '2m', target: 0 },     // Ramp down
  ],
};

export default function() {
  let response = http.get('http://localhost:3000/api/health');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 100ms': (r) => r.timings.duration < 100,
  });
}
```

**Run Load Tests:**
```bash
./scripts/test-performance.sh --load
```

---

## Security Testing

### SAST (Static Analysis)

**Tools:**
- SonarQube for code quality
- npm audit for dependencies
- cargo audit for Rust dependencies
- bandit for Python

**Run SAST:**
```bash
./scripts/test-security.sh --sast
```

### DAST (Dynamic Analysis)

**Tools:**
- OWASP ZAP for API security
- Burp Suite for webapp scanning

**Run DAST:**
```bash
./scripts/test-security.sh --dast
```

### Fuzzing

**Corpus:**
```
tests/security/fuzzing/
├── canister-args/          # Random canister arguments
├── transaction-data/       # Random transaction data
└── api-payloads/           # Random API payloads
```

**Run Fuzzing:**
```bash
./scripts/test-security.sh --fuzz --time 60
```

---

## Test Datasets

### Market Data

**File:** `tests/datasets/market-data/prices.csv`

```
timestamp,btc_price,eth_price,icp_price
2026-01-01T00:00:00Z,45000.00,2500.00,12.50
2026-01-02T00:00:00Z,45500.00,2550.00,12.75
...
```

**Usage:**
```typescript
import { loadMarketData } from '@/tests/fixtures/market-data';

const prices = loadMarketData('2026-01-01');
expect(prices.btc).toBe(45000.00);
```

### Trading Scenarios

**File:** `tests/datasets/trading-scenarios/scenarios.json`

```json
[
  {
    "name": "Bull Market",
    "duration": 3600,
    "trades": [
      {"type": "buy", "amount": 100, "price": 100},
      {"type": "sell", "amount": 100, "price": 110}
    ],
    "expected_profit": 1000
  },
  {
    "name": "Bear Market",
    "duration": 3600,
    "trades": [...],
    "expected_profit": -500
  }
]
```

**Usage:**
```typescript
import { loadScenarios } from '@/tests/fixtures/scenarios';

const scenarios = loadScenarios();
scenarios.forEach(scenario => {
  test(`scenario: ${scenario.name}`, async () => {
    // Run scenario...
    expect(profit).toBe(scenario.expected_profit);
  });
});
```

### ML Training Datasets

**Location:** `tests/datasets/ml-training/`

**Datasets:**
- Historical trading data (2GB)
- Market sentiment data (500MB)
- Economic indicators (100MB)
- Anonymized user behavior (1GB)

**Download:**
```bash
./scripts/sync-datasets.sh --dataset ml-training
```

### Performance Baselines

**File:** `tests/datasets/benchmarks/baselines.json`

```json
{
  "canister_method_latency": {
    "getState": {"p50": 10, "p95": 50, "p99": 100},
    "updateState": {"p50": 50, "p95": 200, "p99": 500}
  },
  "frontend_render": {
    "dashboard": {"p50": 100, "p95": 300, "p99": 500},
    "trading_panel": {"p50": 50, "p95": 150, "p99": 300}
  }
}
```

---

## Test Execution

### Run All Tests

```bash
./scripts/test-all.sh
```

### Run Specific Test Suite

```bash
./scripts/test-backend.sh          # Backend only
./scripts/test-frontend.sh         # Frontend only
./scripts/test-integration.sh      # Integration only
./scripts/test-e2e.sh              # E2E only
./scripts/test-security.sh         # Security only
./scripts/test-performance.sh      # Performance only
```

### Test Options

```bash
# Watch mode
./scripts/test-all.sh --watch

# Coverage report
./scripts/test-all.sh --coverage

# Specific test file
./scripts/test-backend.sh test_aloha_i.mo

# Verbose output
./scripts/test-all.sh --verbose

# Bail on first failure
./scripts/test-all.sh --bail
```

---

## Coverage Requirements

**Target Coverage:**
- Statements: 90%
- Branches: 85%
- Functions: 90%
- Lines: 90%

**Generate Coverage Report:**
```bash
./scripts/coverage-report.sh     # HTML report at coverage/
open coverage/index.html         # View report
```

---

## Continuous Testing

**GitHub Actions automatically runs:**
- Unit tests on every push
- Integration tests on push to main
- E2E tests nightly
- Security tests on every push
- Performance tests weekly

**View Test Results:**
- GitHub Actions tab → workflow run → click job
- Artifacts tab for coverage reports
- Test logs for failures

---

## Writing Tests

### Motoko Tests

```motoko
import Assert "mo:base/assert";
import { ALOHAI } = "canister:backend";

actor {
  public func testALOHAI() : async () {
    let state = await ALOHAI.getState();
    Assert.equal(state.beat > 0, true, "beat should be positive");
  };
};
```

### TypeScript Tests

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useActor } from '@/hooks/useActor';

describe('useActor', () => {
  it('should fetch actor state', async () => {
    const { result } = renderHook(() => useActor());
    
    await act(async () => {
      await result.current.fetchState();
    });
    
    expect(result.current.state).toBeDefined();
  });
});
```

### Python Tests

```python
import pytest
from app.trading import TradingEngine

@pytest.fixture
def engine():
    return TradingEngine()

def test_trading_engine(engine):
    trade = engine.execute_trade(amount=100, price=50)
    assert trade.status == "executed"
    assert trade.amount == 100
```

---

## Test Reporting

**Metrics Tracked:**
- Test count (total, passed, failed)
- Coverage percentage
- Execution time
- Performance benchmarks
- Security vulnerabilities

**Reports Generated:**
- HTML coverage reports
- JUnit XML for CI/CD
- JSON summaries for dashboards
- Markdown summaries for PRs

---

## Troubleshooting

**Tests Fail on Fresh Clone:**
```bash
./scripts/setup-dev.sh  # Install dependencies
./scripts/generate-bindings.sh  # Generate bindings
./scripts/test-all.sh
```

**Flaky Tests:**
```bash
./scripts/test-all.sh --repeat 5  # Run 5 times
```

**Performance Tests Regression:**
```bash
./scripts/test-performance.sh --compare baseline
```

---

**Last Updated:** June 2026
