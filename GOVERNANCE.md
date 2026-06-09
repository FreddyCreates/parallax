# GOVERNANCE.md

## PARRALAX-AIHFTFUND Governance Charter

### Version 1.0

---

## 1. Purpose

This document defines the governance structure for PARRALAX-AIHFTFUND — a sovereign AI-native financial execution infrastructure. It establishes decision-making authority, protocol for changes, agent governance, and human oversight requirements.

---

## 2. Governance Principles

1. **Trader Sovereignty** — The human operator retains ultimate authority over all system operations.
2. **Agent Accountability** — Every agent action is logged, receipted, and auditable.
3. **Protocol Supremacy** — No agent may act outside its defined protocol boundaries.
4. **Progressive Authority** — Agents earn expanded permissions through proven performance.
5. **Kill Switch Doctrine** — Any human operator can halt any agent or all operations instantly.

---

## 3. Authority Hierarchy

| Level | Role | Authority |
|-------|------|-----------|
| 0 | Founder/Operator | Full system authority, override all gates |
| 1 | Governor Agent | Risk limits, protocol enforcement, kill switches |
| 2 | Executor Agent | Order routing within approved parameters |
| 3 | Proposer Agent | Signal generation, strategy proposals (no execution) |
| 4 | Observer Agent | Data collection, monitoring only |

---

## 4. Decision Framework

### 4.1 Protocol Changes
- Require Level 0 approval
- Must be documented with rationale
- Subject to risk assessment before activation

### 4.2 Agent Promotion
- Observer → Proposer: Requires 30 days of accurate signal generation
- Proposer → Executor: Requires human approval + successful paper trading period
- Executor → Governor: Requires founder authorization only

### 4.3 Capital Allocation
- All capital allocation decisions require Level 0 or Level 1 approval
- Individual trade sizing governed by risk protocols
- Portfolio-level rebalancing requires human confirmation above threshold

---

## 5. Oversight Mechanisms

- **Audit Trail**: Every action produces a compute receipt
- **Real-time Monitoring**: Dashboard visibility into all agent operations
- **Daily Reports**: Automated performance and risk summaries
- **Kill Switches**: Per-agent and system-wide emergency halt
- **Capital Limits**: Hard-coded maximum exposure per agent and system-wide

---

## 6. Amendment Process

Changes to this governance charter require:
1. Written proposal with rationale
2. Risk assessment
3. Founder approval
4. 48-hour review period before activation
