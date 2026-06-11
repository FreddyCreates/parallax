# HTTP_SERVICES_PROTOCOL.md

## PARRALAX-AIHFTFUND — HTTP Services Protocol & Endpoint Registry

### Version 1.0

---

## 1. Purpose

This document defines all working HTTP services within PARRALAX-AIHFTFUND, their endpoints, contracts, authentication requirements, rate limits, and operational governance.

---

## 2. Service Architecture

```
                    ┌─────────────────────┐
                    │   API Gateway       │
                    │   (Port 8080)       │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────┴───────┐   ┌────────┴────────┐   ┌───────┴───────┐
│  AI Service   │   │  Rails API      │   │  Rust Engine  │
│  (Port 8084)  │   │  (Port 3000)    │   │  (Port 8090)  │
└───────────────┘   └─────────────────┘   └───────────────┘
```

---

## 3. AI Service — FastAPI (Port 8084)

### 3.1 Health & Monitoring

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Service health check |
| GET | `/metrics` | Prometheus metrics endpoint |

### 3.2 LLM Routing Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/completions` | Text completion via LLM |
| POST | `/api/v1/chat` | Chat-based LLM interaction |
| POST | `/api/v1/embeddings` | Vector embeddings generation |
| POST | `/api/v1/review` | Code/strategy review via LLM |

### 3.3 Actuary Suite Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/actuary/risk-assessment` | Full actuarial risk assessment (VaR, CVaR, Sharpe, tail risk) |
| POST | `/api/v1/actuary/greeks` | Calculate all options Greeks |
| POST | `/api/v1/actuary/portfolio-greeks` | Aggregate Greeks across portfolio |
| POST | `/api/v1/actuary/insurance` | Portfolio insurance analysis (CPPI, OBPI) |
| POST | `/api/v1/actuary/lifecycle/register` | Register strategy for lifecycle tracking |
| GET | `/api/v1/actuary/lifecycle/{strategy_id}` | Get strategy lifecycle metrics |
| GET | `/api/v1/actuary/lifecycle/replacement-schedule` | Strategy replacement schedule |
| POST | `/api/v1/actuary/reserves` | Calculate capital reserves |
| POST | `/api/v1/actuary/risk-budget` | Risk budget allocation |

### 3.4 Trading Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/trading/signal` | Generate trading signal |
| POST | `/api/v1/trading/execute` | Execute trade |
| GET | `/api/v1/trading/positions` | Current positions |
| GET | `/api/v1/trading/orders` | Order history |

### 3.5 Financial Languages Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/financial/fix/order` | Create FIX order message |
| POST | `/api/v1/financial/fpml/trade` | Create FpML trade document |
| POST | `/api/v1/financial/swift/payment` | Generate SWIFT payment message |
| POST | `/api/v1/financial/isda/trade` | Create ISDA CDM trade event |
| POST | `/api/v1/financial/xbrl/report` | Generate XBRL regulatory report |
| POST | `/api/v1/financial/iso20022/transfer` | ISO 20022 credit transfer |

---

## 4. Rails API — Ruby on Rails (Port 3000)

### 4.1 Fund Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/funds` | List all funds |
| GET | `/api/v1/funds/:id` | Fund details |
| POST | `/api/v1/funds` | Create fund |
| PUT | `/api/v1/funds/:id` | Update fund |
| GET | `/api/v1/funds/:id/nav` | Fund NAV history |
| GET | `/api/v1/funds/:id/performance` | Performance metrics |

### 4.2 User & Auth

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | User authentication |
| POST | `/api/v1/auth/refresh` | Token refresh |
| GET | `/api/v1/users/me` | Current user profile |
| GET | `/api/v1/users/:id/permissions` | User permissions |

### 4.3 Governance

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/governance/proposals` | List governance proposals |
| POST | `/api/v1/governance/proposals` | Submit proposal |
| PUT | `/api/v1/governance/proposals/:id/vote` | Vote on proposal |
| GET | `/api/v1/governance/audit-log` | Audit trail |

### 4.4 Strategy Registry

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/strategies` | List registered strategies |
| POST | `/api/v1/strategies` | Register new strategy |
| GET | `/api/v1/strategies/:id/performance` | Strategy performance |
| PUT | `/api/v1/strategies/:id/status` | Update strategy status |

---

## 5. Rust Engine — High-Performance Execution (Port 8090)

### 5.1 Order Execution

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/orders` | Submit order for execution |
| DELETE | `/api/v1/orders/:id` | Cancel order |
| GET | `/api/v1/orders/:id/status` | Order status |
| GET | `/api/v1/orders/active` | Active orders |

### 5.2 Market Data

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/market/quote/:symbol` | Real-time quote |
| GET | `/api/v1/market/depth/:symbol` | Order book depth |
| GET | `/api/v1/market/trades/:symbol` | Recent trades |
| WS | `/ws/market/stream` | WebSocket market data stream |

### 5.3 Risk Engine

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/risk/check` | Pre-trade risk check |
| GET | `/api/v1/risk/limits` | Current risk limits |
| GET | `/api/v1/risk/exposure` | Current exposure |
| POST | `/api/v1/risk/kill-switch` | Emergency halt |

---

## 6. ICP Canister HTTP Outcalls

### 6.1 Backend Canister Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/canister/heartbeat` | Trigger heartbeat cycle |
| GET | `/api/v1/canister/state` | Current canister state |
| POST | `/api/v1/canister/aloha/coherence` | ALOHA I coherence check |
| POST | `/api/v1/canister/token/mint` | Token minting operation |
| POST | `/api/v1/canister/receipt/create` | Create compute receipt |
| GET | `/api/v1/canister/registry/agents` | Registered agents |

---

## 7. Authentication & Security

### 7.1 Auth Methods

| Service | Auth Method | Token Type |
|---------|------------|-----------|
| AI Service | JWT ****** RS256 |
| Rails API | JWT ****** RS256 |
| Rust Engine | API Key + JWT | HMAC-SHA256 |
| ICP Canister | Internet Identity | Ed25519 |

### 7.2 Rate Limits

| Service | Rate Limit | Burst |
|---------|-----------|-------|
| AI Service (LLM) | 100 req/min | 20 |
| AI Service (Trading) | 1000 req/min | 100 |
| Rails API | 500 req/min | 50 |
| Rust Engine (Orders) | 10000 req/min | 1000 |
| Rust Engine (Market Data) | 50000 req/min | 5000 |

### 7.3 Security Headers

All services require:
```
X-Request-ID: <uuid>
X-Agent-ID: <agent_identifier>
X-Timestamp: <ISO8601>
X-Signature: <HMAC of request body>
```

---

## 8. Service Discovery

### 8.1 Docker Compose Services

```yaml
services:
  ai-service:
    port: 8084
    health: /health
    replicas: 2
  rails-api:
    port: 3000
    health: /health
    replicas: 2
  rust-engine:
    port: 8090
    health: /health
    replicas: 4
  redis:
    port: 6379
  postgres:
    port: 5432
  prometheus:
    port: 9090
  grafana:
    port: 3001
```

### 8.2 Kubernetes Services

All services are deployable via the `/k8s` directory manifests with:
- Horizontal pod autoscaling
- Health check probes (liveness + readiness)
- Resource limits and requests
- Network policies for inter-service communication

---

## 9. Error Handling

### 9.1 Standard Error Response

```json
{
  "error": {
    "code": "RISK_LIMIT_EXCEEDED",
    "message": "Order exceeds maximum position size",
    "details": {
      "current_position": 1000,
      "requested_quantity": 500,
      "max_allowed": 1200
    },
    "request_id": "uuid",
    "timestamp": "ISO8601"
  }
}
```

### 9.2 Error Code Categories

| Range | Category |
|-------|----------|
| 1000-1999 | Authentication/Authorization |
| 2000-2999 | Validation errors |
| 3000-3999 | Risk/Compliance rejections |
| 4000-4999 | Execution failures |
| 5000-5999 | System/Infrastructure errors |

---

## 10. Monitoring & Observability

### 10.1 Metrics

All services expose Prometheus metrics at `/metrics`:
- Request latency (p50, p95, p99)
- Request count by endpoint and status code
- Active connections
- Error rate
- Business metrics (orders/sec, signals generated, risk checks)

### 10.2 Logging

Structured JSON logging via:
- AI Service: `structlog`
- Rails API: `Rails.logger` (JSON format)
- Rust Engine: `tracing` crate

### 10.3 Tracing

Distributed tracing via OpenTelemetry:
- Trace propagation across all services
- Span-level detail for order lifecycle
- Correlation IDs for cross-service requests

---

*All HTTP services operate under the governance framework defined in GOVERNANCE_MACRO_PROTOCOL.md. Service changes require protocol review.*
