# GOVERNANCE_MACRO_PROTOCOL.md

## PARRALAX-AIHFTFUND — Macro Governance Protocol

### Version 2.0

---

## 1. Purpose

This document defines the **macro governance protocol** — the system-wide framework that governs how PARRALAX-AIHFTFUND operates across time, users, policies, ethics, agent lifecycles, capital flows, regulatory boundaries, and institutional coordination.

It is the canonical reference for how all system components interact, evolve, and remain accountable across their full operational lifespan.

---

## 2. Temporal Governance Model

### 2.1 Time Horizons

The system operates across five concurrent time horizons:

| Horizon | Duration | Scope |
|---------|----------|-------|
| Micro | < 1 second | HFT execution, tick-level decisions |
| Short | 1 second – 1 hour | Intraday strategies, signal generation |
| Medium | 1 hour – 30 days | Position management, risk rebalancing |
| Long | 30 days – 1 year | Strategy lifecycle, alpha decay, fund operations |
| Epoch | > 1 year | System evolution, charter amendments, institutional partnerships |

### 2.2 Temporal Authority Rules

- **Micro decisions**: Fully autonomous within pre-approved parameters
- **Short decisions**: Agent-driven with real-time risk gate enforcement
- **Medium decisions**: Require Governor Agent oversight
- **Long decisions**: Require Level 0 (Founder) review
- **Epoch decisions**: Require formal charter amendment process

### 2.3 Time-Based Escalation

If any agent detects conditions outside its temporal authority:
1. Immediate freeze of affected operations
2. Escalation to next governance tier
3. Audit trail generated with full context
4. Resolution within defined SLA per tier

---

## 3. Multi-User Governance

### 3.1 User Roles

| Role | Access Level | Authority |
|------|-------------|-----------|
| Founder | Full | All system operations, charter amendments |
| Fund Operator | Capital | Portfolio management, strategy deployment |
| Strategy Developer | Build | Strategy creation, backtesting, paper trading |
| Compliance Officer | Audit | Read-only access to all logs, override authority on compliance issues |
| Observer | View | Dashboard access, performance monitoring |
| External Auditor | Audit | Periodic access for regulatory review |

### 3.2 Multi-Tenancy Rules

- Each user operates within a sandboxed authority boundary
- Cross-user operations require explicit authorization chains
- Shared resources (compute, data feeds, risk limits) managed by Governor Agent
- User actions are always attributed and receipted

### 3.3 Conflict Resolution

When multiple users issue conflicting directives:
1. Higher authority level takes precedence
2. Equal authority: First-in-time unless overridden
3. Safety-critical conflicts: System defaults to most conservative action
4. All conflicts logged for governance review

---

## 4. Policy Framework

### 4.1 Policy Hierarchy

```
CHARTER (Immutable Core)
  └── GOVERNANCE (Amendment Process)
       └── PROTOCOLS (Operational Rules)
            └── POLICIES (Runtime Configuration)
                 └── PARAMETERS (Agent-Level Settings)
```

### 4.2 Policy Categories

| Category | Scope | Amendment Authority |
|----------|-------|-------------------|
| Constitutional | System identity and mission | Founder only, requires 30-day notice |
| Structural | Architecture and component boundaries | Founder + 48-hour review |
| Operational | Day-to-day execution rules | Governor Agent within limits |
| Tactical | Strategy-specific parameters | Strategy owner with risk gate approval |
| Ephemeral | Session-specific overrides | Any authorized user, auto-expires |

### 4.3 Policy Enforcement

- All policies are machine-readable and enforceable
- Policy violations trigger immediate halt + escalation
- Policy changes are versioned and auditable
- Rollback capability for any policy change within 24 hours

---

## 5. Ethics Protocol

### 5.1 Ethical Principles

1. **Market Integrity** — The system shall not manipulate markets, spoof orders, or engage in deceptive trading practices
2. **Fairness** — No strategy shall exploit information asymmetries obtained through unauthorized means
3. **Transparency** — All system actions are auditable and explainable
4. **Harm Minimization** — System shall not amplify systemic risk or cause undue market disruption
5. **Accountability** — Every decision has an identifiable responsible party (human or agent with human oversight)

### 5.2 Prohibited Activities

- Market manipulation (spoofing, layering, wash trading)
- Insider trading or use of material non-public information
- Front-running of client orders
- Artificial inflation/deflation of asset prices
- Exploitation of system vulnerabilities in external markets
- Trading that intentionally harms retail participants

### 5.3 Ethical Review Process

- Quarterly ethics audit by Compliance Officer
- Annual external ethics review
- Real-time ethical boundary monitoring by Governor Agent
- Whistleblower mechanism for ethics concerns

### 5.4 AI Ethics Specific

- Agent decisions must be explainable within 5 levels of reasoning
- No "black box" strategies without human-interpretable risk bounds
- Agent learning updates reviewed before deployment
- Bias detection and mitigation in all ML models
- Regular fairness audits across asset classes and market participants

---

## 6. Risk Governance

### 6.1 Risk Authority Levels

| Risk Type | Authority | Escalation Trigger |
|-----------|-----------|-------------------|
| Position Risk | Executor Agent | > 2% portfolio loss |
| Portfolio Risk | Governor Agent | > 5% drawdown |
| Systemic Risk | Founder | Market-wide conditions |
| Operational Risk | Governor Agent | System anomaly detected |
| Model Risk | Strategy Owner | Alpha decay > 50% |
| Counterparty Risk | Governor Agent | Credit event detected |

### 6.2 Kill Switch Hierarchy

```
Level 3: Individual Position Kill  (Executor Agent)
Level 2: Strategy Kill             (Governor Agent)
Level 1: Asset Class Kill          (Governor Agent + Founder)
Level 0: Full System Halt          (Founder or any Level 1)
```

### 6.3 Risk Budget Allocation

- Total system risk budget set at Epoch level
- Distributed across strategies based on Sharpe-weighted allocation
- Rebalanced monthly or on risk event
- Reserve buffer maintained at 15% minimum

---

## 7. Compliance Boundaries

### 7.1 Regulatory Frameworks

The system is designed to operate within:
- SEC regulations (US equities)
- CFTC regulations (US futures/commodities)
- MiFID II (European markets)
- MAS regulations (Singapore)
- Wyoming DAO/DUNA frameworks (blockchain assets)
- FATF guidelines (AML/KYC)

### 7.2 Compliance Monitoring

- Real-time transaction monitoring for regulatory thresholds
- Automated reporting generation (Form PF, AIFMD, etc.)
- Position limit monitoring across all venues
- Cross-border transaction flagging

### 7.3 Regulatory Change Management

- Regulatory change detection via automated monitoring
- Impact assessment within 72 hours of new regulation
- Implementation plan within 14 days
- Compliance certification before system changes go live

---

## 8. System Evolution Protocol

### 8.1 Version Control

- All system changes follow semantic versioning
- Breaking changes require charter amendment
- Non-breaking enhancements follow standard PR process
- Emergency patches allowed with post-hoc review

### 8.2 Agent Evolution

Agents evolve through defined stages:
```
INCUBATION → TESTING → PAPER_TRADING → LIVE_RESTRICTED → LIVE_FULL → MATURE → SUNSET
```

### 8.3 Strategy Lifecycle

- **Birth**: Strategy concept validated through backtesting
- **Youth**: Paper trading with performance benchmarks
- **Maturity**: Live trading with full capital allocation
- **Decline**: Alpha decay detected, capital reduced
- **Sunset**: Strategy retired, compute receipts archived

### 8.4 System Health Metrics

| Metric | Threshold | Action |
|--------|-----------|--------|
| System Coherence | < 0.7 | Alert + investigation |
| Agent Agreement | < 0.6 | Reduce autonomous authority |
| Risk Utilization | > 0.85 | Scale back new positions |
| Latency P99 | > 100ms | Performance investigation |
| Error Rate | > 0.1% | Immediate escalation |

---

## 9. Institutional Coordination

### 9.1 External Interfaces

- Prime brokerage connections (FIX protocol)
- Exchange connectivity (co-location, DMA)
- Blockchain node infrastructure
- Data vendor integrations
- Regulatory reporting endpoints

### 9.2 Partnership Governance

- All external partnerships require Founder approval
- Data sharing agreements reviewed quarterly
- SLA monitoring for all external dependencies
- Contingency plans for vendor failure

---

## 10. Amendment Process

Changes to this macro governance protocol require:
1. Written proposal with full impact assessment
2. 30-day community review period
3. Risk assessment by Governor Agent
4. Ethics review by Compliance Officer
5. Founder approval with documented rationale
6. 48-hour implementation cool-down
7. Post-implementation monitoring for 30 days

---

## 11. Protocol References

| Protocol | Document | Purpose |
|----------|----------|---------|
| Execution | EXECUTION_PROTOCOL.md | Order lifecycle |
| Risk | RISK.md | Risk management framework |
| Token | TOKEN_PROTOCOL.md | Token issuance and management |
| Treasury | TREASURY_PROTOCOL.md | Capital management |
| NFT | NFT_PROTOCOL.md | Digital asset operations |
| Compute Receipt | COMPUTE_RECEIPT_PROTOCOL.md | Proof of computation |
| Agent Authority | AGENT_AUTHORITY_CHARTER.md | Agent permission framework |
| Asset Issuance | ASSET_ISSUANCE_CHARTER.md | Asset creation rules |
| Compliance | COMPLIANCE_BOUNDARY.md | Regulatory boundaries |
| HTTP Services | HTTP_SERVICES_PROTOCOL.md | Service endpoint governance |
| Ethics | ETHICS_PROTOCOL.md | Ethical AI trading |
| Temporal | TEMPORAL_PROTOCOL.md | Time-based operations |

---

*This document is the supreme governance reference for PARRALAX-AIHFTFUND macro operations. All other protocols operate subordinate to this framework.*
