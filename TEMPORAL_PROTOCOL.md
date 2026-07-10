# TEMPORAL_PROTOCOL.md

## PARRALAX-AIHFTFUND — Temporal Operations Protocol

### Version 1.0

---

## 1. Purpose

This protocol defines how PARRALAX-AIHFTFUND manages time-dependent operations, scheduling, lifecycle management, temporal coordination across agents, and time-series intelligence.

---

## 2. System Clock Architecture

### 2.1 Clock Hierarchy

```
UTC Master Clock
  ├── Market Clock (per venue)
  │     ├── Pre-Market (04:00-09:30 ET)
  │     ├── Regular Hours (09:30-16:00 ET)
  │     ├── After-Hours (16:00-20:00 ET)
  │     └── Closed
  ├── Blockchain Clock (per chain)
  │     ├── Block Time (variable)
  │     └── Epoch Time (chain-specific)
  ├── Agent Clock (per agent)
  │     ├── Heartbeat Interval
  │     ├── Decision Cycle
  │     └── Cooldown Timer
  └── Governance Clock
        ├── Review Periods
        ├── Amendment Windows
        └── Audit Schedules
```

### 2.2 Time Synchronization

- All system components synchronized to UTC via NTP
- Maximum allowed clock drift: 1ms for HFT components
- Maximum allowed clock drift: 100ms for governance components
- Timestamp resolution: nanosecond for execution, millisecond for governance

---

## 3. Temporal Decision Framework

### 3.1 Time-Horizon Strategy Mapping

| Time Horizon | Strategy Types | Decision Frequency |
|-------------|----------------|-------------------|
| Microsecond | HFT market-making, latency arbitrage | Per-tick |
| Second | Momentum scalping, quote adjustment | 1-10/sec |
| Minute | Statistical arbitrage, mean reversion | Per-minute |
| Hour | Pairs trading, vol arbitrage | Per-hour |
| Day | Event-driven, ML alpha | Daily rebalance |
| Week | Portfolio optimization, risk rebalance | Weekly cycle |
| Month | Strategy lifecycle, capital allocation | Monthly review |
| Quarter | Governance review, ethics audit | Quarterly |
| Year | Charter amendment, system evolution | Annual |

### 3.2 Temporal Priority Rules

When time-sensitive decisions conflict:
1. Safety-critical actions always execute immediately
2. Shorter time-horizon trades take execution priority
3. Longer time-horizon governance takes authority priority
4. Tie-breaking: Risk reduction takes precedence

---

## 4. Scheduling Engine

### 4.1 Scheduled Operations

| Operation | Schedule | Authority |
|-----------|----------|-----------|
| Market Open Preparation | T-15min before each venue open | Governor Agent |
| Risk Limit Reset | Daily at 00:00 UTC | Governor Agent |
| Strategy Performance Review | Daily at 21:00 UTC | Strategy Owner |
| Position Reconciliation | Every 4 hours | Executor Agent |
| Capital Reserve Check | Hourly | Governor Agent |
| Agent Health Heartbeat | Every 30 seconds | All Agents |
| Governance Report | Weekly Monday 08:00 UTC | Governor Agent |
| Ethics Compliance Scan | Daily at 06:00 UTC | Compliance Module |
| System Backup | Every 6 hours | Infrastructure |
| Model Retraining | Weekly (off-market hours) | ML Pipeline |

### 4.2 Event-Triggered Operations

| Trigger | Action | Latency SLA |
|---------|--------|-------------|
| Circuit Breaker (exchange) | Halt all orders for venue | < 1ms |
| Drawdown Threshold | Scale down positions | < 100ms |
| News Event Detected | Activate event-driven strategy | < 500ms |
| Agent Failure | Failover to backup agent | < 5s |
| Regulatory Alert | Freeze affected operations | < 1s |
| New Block (blockchain) | Update on-chain positions | Per-block |

---

## 5. Lifecycle Temporal Management

### 5.1 Strategy Lifecycle Timing

```
Phase 1: Incubation      (30-90 days)    - Backtesting, research
Phase 2: Paper Trading   (14-30 days)    - Simulated execution
Phase 3: Live Restricted (30-60 days)    - Small capital allocation
Phase 4: Live Full       (Indefinite)    - Full capital per allocation
Phase 5: Decay Detected  (Monitored)     - Reduced allocation
Phase 6: Sunset          (14-30 days)    - Graceful wind-down
Phase 7: Archive         (Permanent)     - Compute receipts preserved
```

### 5.2 Agent Lifecycle Timing

- **Promotion cooldown**: Minimum 30 days between level changes
- **Performance window**: Rolling 90-day evaluation
- **Authority timeout**: Unused elevated permissions expire after 7 days
- **Sunset notice**: 14 days before agent decommission

---

## 6. Time-Series Intelligence

### 6.1 Historical Data Management

| Data Type | Retention | Resolution |
|-----------|-----------|-----------|
| Tick Data | 5 years | Nanosecond |
| OHLCV | Indefinite | 1-minute |
| Order Book Snapshots | 1 year | 100ms |
| Agent Decisions | Indefinite | Per-event |
| Risk Metrics | Indefinite | 1-minute |
| Governance Logs | Indefinite | Per-event |

### 6.2 Temporal Pattern Recognition

The system maintains awareness of:
- Market microstructure patterns (time-of-day effects)
- Seasonal patterns (earnings cycles, rebalancing dates)
- Regime change indicators (volatility clustering, correlation breakdown)
- Calendar effects (month-end, quarter-end, options expiry)

---

## 7. Cross-Timezone Coordination

### 7.1 Multi-Market Timing

| Market Zone | Hours (Local) | UTC Offset |
|-------------|---------------|-----------|
| Asia/Pacific (Tokyo) | 09:00-15:00 JST | +9 |
| Asia/Pacific (Hong Kong) | 09:30-16:00 HKT | +8 |
| Europe (London) | 08:00-16:30 GMT | +0/+1 |
| Americas (New York) | 09:30-16:00 ET | -5/-4 |
| Crypto Markets | 24/7 | UTC |
| Blockchain (ICP) | 24/7 | UTC |

### 7.2 Timezone Governance Rules

- Strategy allocation adjusts for active market hours
- Risk limits may vary by timezone activity
- Agent handoff between timezone-specific modules
- 24/7 monitoring with reduced-autonomy overnight (non-crypto)

---

## 8. Temporal Failsafe

### 8.1 Time-Based Circuit Breakers

| Condition | Action | Recovery |
|-----------|--------|----------|
| No heartbeat for 60s | Agent marked unhealthy | Auto-restart |
| No heartbeat for 5min | Agent killed, backup activated | Manual review |
| Clock drift > 10ms | HFT strategies paused | Auto-resume on sync |
| Clock drift > 1s | All trading halted | Manual investigation |
| Scheduling engine failure | All scheduled ops frozen | Failover to backup |

### 8.2 Time Travel Prevention

- All timestamps are monotonically increasing per component
- NTP jumps > 100ms trigger reconciliation
- Historical data is immutable (append-only)
- Backfilling requires governance approval

---

## 9. Temporal Metrics

| Metric | Target | Alert Threshold |
|--------|--------|----------------|
| Order-to-Fill Latency | < 1ms (HFT) | > 5ms |
| Signal-to-Order Latency | < 10ms | > 50ms |
| Risk Check Latency | < 1ms | > 5ms |
| Heartbeat Regularity | ±1s | > 5s drift |
| Scheduling Accuracy | ±100ms | > 1s drift |
| Cross-Venue Sync | < 5ms | > 20ms |

---

*Time is the fundamental axis of all financial operations. This protocol ensures PARRALAX-AIHFTFUND operates with temporal precision and awareness.*
