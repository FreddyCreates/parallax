# EXECUTION_PROTOCOL.md

## PARRALAX-AIHFTFUND Execution Protocol

### Version 1.0

---

## 1. Purpose

This protocol defines the order lifecycle from signal generation through execution, fill, settlement, and receipt generation within PARRALAX-AIHFTFUND.

---

## 2. Order Lifecycle

```
SIGNAL → PROPOSAL → RISK_CHECK → APPROVED → ROUTED → FILLED → SETTLED → RECEIPTED
```

### 2.1 Signal Generation
- Source: Signal Agent (Level 3+)
- Output: Trading signal with direction, symbol, strength, strategy ID
- Requirement: Signal must include agent_id and timestamp

### 2.2 Proposal
- Signal converted to order proposal
- Includes: symbol, side, quantity, order type, price (if limit)
- Tagged with: strategy_id, signal_id, agent_id

### 2.3 Risk Check
- Order passes through all risk gates sequentially
- Gates: Size, Exposure, Loss, Velocity, Correlation, Liquidity
- Any gate failure → order rejected with reason

### 2.4 Approval
- For Level 2+ agents within limits: auto-approved
- For orders exceeding thresholds: queued for human approval
- Approval timeout: configurable (default 5 minutes)

### 2.5 Routing
- Order Router selects optimal venue
- Criteria: latency, fee, liquidity, asset class support
- Venue selection is deterministic and logged

### 2.6 Fill
- Venue confirms execution
- Fill record includes: price, quantity, fee, venue, timestamp, latency
- Partial fills tracked and aggregated

### 2.7 Settlement
- Reconcile fill with expected parameters
- Update position records
- Update capital/exposure tracking
- Flag discrepancies for review

### 2.8 Receipt
- Generate immutable ExecutionReceipt
- Includes: order_id, fill details, latency, hash
- Stored permanently in receipt ledger

---

## 3. Supported Order Types

| Type | Description | Use Case |
|------|-------------|----------|
| Market | Execute at best available price | Immediate entry/exit |
| Limit | Execute at specified price or better | Price-sensitive entries |
| Stop Loss | Triggered when price hits level | Risk management |
| Stop Limit | Stop trigger + limit price | Precise risk control |
| TWAP | Time-weighted average price | Large order execution |
| VWAP | Volume-weighted average price | Institutional execution |

---

## 4. Venue Support

| Venue | Asset Classes | Protocol |
|-------|--------------|----------|
| Alpaca | Equities, Crypto | REST + WebSocket |
| Binance | Crypto, Tokens | REST + WebSocket |
| Interactive Brokers | Equities, Forex, Commodities | FIX + TWS API |
| Uniswap | Tokens, NFTs | On-chain (Ethereum) |
| Internal | Internal Tokens | PARRALAX Protocol |

---

## 5. Latency Requirements

| Operation | Target | Maximum |
|-----------|--------|---------|
| Signal to proposal | <1ms | 5ms |
| Risk check | <1ms | 10ms |
| Order routing | <5ms | 50ms |
| Venue round-trip | Venue-dependent | 100ms (crypto), 1s (on-chain) |
| Receipt generation | <1ms | 5ms |

---

## 6. Error Handling

- All failures produce error receipts
- Failed orders are logged with full context
- Retry logic: configurable per venue (default: 3 attempts)
- Circuit breaker: venue disabled after 5 consecutive failures
