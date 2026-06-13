# TREASURY_PROTOCOL.md

## PARRALAX-AIHFTFUND Treasury Protocol

### Version 1.0

---

## 1. Purpose

The Treasury Protocol governs all capital management, allocation, accounting, and reporting within PARRALAX-AIHFTFUND. It ensures that funds are properly tracked, allocated, and protected.

---

## 2. Treasury Structure

```
┌─────────────────────────────────────────────┐
│              MASTER TREASURY                  │
├─────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Operating │  │ Strategy │  │ Reserve  │  │
│  │  Capital  │  │  Capital │  │  Fund    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Fee     │  │  Token   │  │  Agent   │  │
│  │  Pool    │  │  Reserve │  │  Budget  │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
```

---

## 3. Capital Pools

| Pool | Purpose | Access Level |
|------|---------|-------------|
| Operating Capital | Day-to-day trading operations | Level 2+ (Executors) |
| Strategy Capital | Allocated to specific strategies | Strategy-bound agents |
| Reserve Fund | Emergency buffer, never traded | Level 0 only |
| Fee Pool | Collected trading fees | Treasury Protocol |
| Token Reserve | Backing for issued tokens | Treasury Protocol |
| Agent Budget | Compute and operation costs | Per-agent allocation |

---

## 4. Allocation Rules

- **Operating Capital**: Max 60% of total treasury
- **Strategy Capital**: Max 30% per single strategy
- **Reserve Fund**: Minimum 10% of total treasury (never deployed)
- **Agent Budget**: Max 5% of total treasury
- **Rebalancing**: Weekly automatic + manual override

---

## 5. Accounting

### Double-Entry System
Every capital movement recorded as:
- Debit entry (source account)
- Credit entry (destination account)
- Receipt reference
- Timestamp and authorizer

### Reconciliation
- Real-time balance tracking across all venues
- Daily automated reconciliation
- Discrepancy alerts for >$100 variance
- Monthly full audit export

---

## 6. Reporting

| Report | Frequency | Audience |
|--------|-----------|----------|
| P&L Summary | Daily | Founder |
| Position Report | Real-time | All agents |
| Treasury Balance | Hourly | Governor agents |
| Performance Attribution | Weekly | Founder |
| Compliance Report | Monthly | External audit |
| Tax Report | Quarterly/Annual | Compliance |

---

## 7. Controls

- All withdrawals require Level 0 approval
- Inter-pool transfers require Level 1+ approval
- Automated alerts on unusual capital movements
- Hard limit on single-day capital deployment
- Multi-signature requirement for transactions > threshold
