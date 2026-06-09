# RISK.md

## PARRALAX-AIHFTFUND Risk Charter

### Version 1.0

---

## 1. Purpose

This document defines the risk management framework for PARRALAX-AIHFTFUND. Every trading operation, agent action, and capital deployment is subject to these risk controls.

---

## 2. Risk Categories

### 2.1 Market Risk
- Price movement against positions
- Liquidity gaps
- Correlation breakdown
- Flash crashes

### 2.2 Execution Risk
- Order routing failures
- Partial fills
- Slippage beyond tolerance
- Venue outages

### 2.3 Agent Risk
- Rogue agent behavior
- Signal model degradation
- Feedback loop amplification
- Unauthorized promotion

### 2.4 Infrastructure Risk
- System downtime
- Data feed interruption
- Network latency spikes
- Database corruption

### 2.5 Counterparty Risk
- Exchange insolvency
- Broker default
- Settlement failure
- API key compromise

---

## 3. Risk Limits

| Parameter | Default Limit | Hard Ceiling |
|-----------|--------------|--------------|
| Max single order size | $100,000 | $500,000 |
| Max daily loss | $50,000 | $200,000 |
| Max total exposure | $5,000,000 | $20,000,000 |
| Max position concentration | 20% of portfolio | 35% |
| Max orders per second | 100 | 1,000 |
| Max drawdown before halt | 5% | 10% |

---

## 4. Risk Gates

Every order passes through sequential risk gates:

1. **Size Gate** — Reject orders exceeding position limits
2. **Exposure Gate** — Reject if total exposure would exceed ceiling
3. **Loss Gate** — Reject if daily loss limit is breached
4. **Velocity Gate** — Reject if order rate exceeds threshold
5. **Correlation Gate** — Reject if adding correlated risk beyond limit
6. **Liquidity Gate** — Reject if insufficient market depth

---

## 5. Kill Switches

### Per-Agent Kill Switch
- Halts a single agent immediately
- Cancels all pending orders from that agent
- Requires manual reactivation

### System-Wide Kill Switch
- Halts ALL agent operations
- Cancels ALL pending orders
- Flattens positions (optional, configurable)
- Requires founder authorization to restart

### Automatic Triggers
- Daily loss exceeds 80% of limit → Warning + reduce exposure
- Daily loss exceeds 100% of limit → Auto-halt new orders
- Drawdown exceeds 5% → Kill switch engaged
- System error rate > 1% → Pause all execution

---

## 6. Risk Monitoring

- Real-time exposure dashboard
- Position-level P&L tracking
- Agent performance attribution
- Correlation matrix updates
- VaR calculation (daily, weekly)
- Stress test scenarios (weekly)

---

## 7. Incident Response

1. **Detect** — Automated monitoring identifies anomaly
2. **Alert** — Notify operator via all configured channels
3. **Contain** — Engage appropriate kill switch
4. **Assess** — Determine root cause and impact
5. **Resolve** — Fix and document
6. **Review** — Post-incident analysis and protocol update
