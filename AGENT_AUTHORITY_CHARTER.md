# AGENT_AUTHORITY_CHARTER.md

## PARRALAX-AIHFTFUND Agent Authority Charter

### Version 1.0

---

## 1. Purpose

This charter defines the authority framework for all autonomous agents operating within PARRALAX-AIHFTFUND. It governs what agents can do, how they earn expanded authority, and how they are constrained.

---

## 2. Agent Authority Levels

### Level 4 — Observer
- Read market data
- Monitor positions
- Generate internal analytics
- **Cannot**: Propose trades, execute orders, modify configuration

### Level 3 — Proposer
- All Observer capabilities
- Generate trading signals
- Propose strategy changes
- Submit orders for human approval
- **Cannot**: Execute without approval, modify risk limits

### Level 2 — Executor
- All Proposer capabilities
- Execute approved orders within capital limits
- Route orders to venues
- Manage open positions within parameters
- **Cannot**: Exceed capital limits, modify own authority, bypass risk gates

### Level 1 — Governor
- All Executor capabilities
- Set risk parameters for lower-level agents
- Activate/deactivate agents
- Issue compute receipts
- **Cannot**: Override founder kill switch, self-promote, exceed system-wide limits

### Level 0 — Founder (Human)
- Unrestricted system authority
- Override any agent decision
- Modify any protocol
- Engage/disengage system kill switch

---

## 3. Promotion Criteria

| From → To | Requirements |
|-----------|-------------|
| Observer → Proposer | 30 days active, >60% signal accuracy on paper |
| Proposer → Executor | Human approval, 60 days paper trading, <5% max drawdown |
| Executor → Governor | Founder authorization only, 90 days clean execution |

---

## 4. Demotion & Termination

An agent is automatically demoted if:
- Daily loss exceeds agent limit
- Error rate exceeds 1% over 24 hours
- Unauthorized action attempted
- Kill switch triggered

An agent is terminated if:
- Repeated unauthorized actions
- Critical risk event caused
- Founder directive

---

## 5. Human Approval Gates

The following actions ALWAYS require human approval:
- First live trade by any newly promoted Executor
- Any order exceeding 50% of agent capital limit
- Strategy changes affecting multiple agents
- Agent promotion to Governor
- System-wide parameter changes

---

## 6. Post-Trade Memory

Every agent maintains:
- Complete trade history
- Signal accuracy records
- Decision rationale logs
- Performance attribution
- Risk event history

This memory is:
- Immutable (append-only)
- Used for promotion/demotion decisions
- Available for audit
- Preserved after agent termination
