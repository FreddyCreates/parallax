# ⚡ Trading Execution Platform

> Full architecture overview of the PARALLAX trading execution platform — ready for developers on ICP and traders across all chains.

---

## Platform Overview

PARALLAX is a **production-ready trading execution platform** built natively on the Internet Computer. It combines:

- **Institutional-grade matching engine** — deterministic, MEV-resistant, sub-second
- **Real-time clearinghouse** — bilateral & multilateral netting every 873ms
- **Multi-asset support** — crypto, AI tokens, artifacts, creator tokens, RWAs
- **Zero-cost execution** — no gas fees, ever
- **Cross-chain access** — ICP native + ckBTC + ckETH + future bridges

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     PARALLAX TRADING PLATFORM                            │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────┐                 │
│  │  FRONTEND   │   │   AGENT KIT  │   │  DIRECT API  │                 │
│  │  (React/TS) │   │  (Bot SDK)   │   │  (Candid)    │                 │
│  └──────┬──────┘   └──────┬───────┘   └──────┬───────┘                 │
│         │                  │                   │                          │
│  ───────┴──────────────────┴───────────────────┴─────── Canister API ── │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                    PHANTOM EXCHANGE                           │       │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐   │       │
│  │  │ Order Book  │  │   Matching   │  │  Price Discovery  │   │       │
│  │  │  (per pair) │  │   Engine     │  │  (CLOB + AMM)     │   │       │
│  │  └─────────────┘  └──────────────┘  └───────────────────┘   │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                              │                                           │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                  PHANTOM CLEARINGHOUSE                        │       │
│  │  ┌──────────────┐  ┌─────────────┐  ┌───────────────────┐   │       │
│  │  │  Settlement  │  │   Netting   │  │  CCP Guarantee    │   │       │
│  │  │  (873ms)     │  │  (multi)    │  │  (risk engine)    │   │       │
│  │  └──────────────┘  └─────────────┘  └───────────────────┘   │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                              │                                           │
│  ┌──────────────────────────────────────────────────────────────┐       │
│  │                    ASSET LAYER                                │       │
│  │  ┌──────────────┐  ┌─────────────┐  ┌───────────────────┐   │       │
│  │  │ Token Factory│  │  AI Artifact │  │  Bridge Gateway   │   │       │
│  │  │ (37 types)   │  │  Registry    │  │  (ckBTC/ckETH)    │   │       │
│  │  └──────────────┘  └─────────────┘  └───────────────────┘   │       │
│  └──────────────────────────────────────────────────────────────┘       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Matching Engine

### Design Principles
- **Price-Time Priority (FIFO)** — best price fills first; ties broken by arrival time
- **Deterministic** — same input sequence always produces identical output
- **MEV-Resistant** — no mempool, no reordering by validators
- **Continuous** — processes orders as they arrive (no batch auctions)

### Order Types

| Type | Behavior |
|------|----------|
| **Limit** | Rests on book at specified price until filled or cancelled |
| **Market** | Sweeps the book at best available prices immediately |
| **Post-Only** | Rejected if would immediately match (guarantees maker status) |
| **IOC** (Immediate-or-Cancel) | Fills what's available, cancels remainder |
| **FOK** (Fill-or-Kill) | Fills entirely or not at all |

### Performance Characteristics

| Metric | Value |
|--------|-------|
| Order processing | < 50ms per order |
| Match latency | < 10ms |
| Settlement finality | 873ms (1 heartbeat) |
| Throughput | Limited by ICP subnet (~1000 updates/sec) |
| Max order book depth | Unlimited (canister memory) |

---

## Settlement Engine (Clearinghouse)

### How Settlement Works

1. **Every 873ms**, the clearinghouse heartbeat fires
2. All matched trades since last beat are collected
3. **Bilateral netting** reduces offsetting obligations between pairs
4. **Multilateral netting** further reduces across the full set
5. Net positions are settled — balances updated atomically
6. Settlement proof (cryptographic hash) is emitted

### Central Counterparty (CCP) Guarantee

The protocol acts as counterparty to every trade:
- **Buyer and seller** transact against the protocol, not each other
- **No counterparty risk** — if one side defaults, protocol covers
- **Risk engine** monitors exposure and position limits continuously

---

## Trading UX

### Frontend Interface

The PARALLAX frontend provides a professional trading experience:

| Feature | Description |
|---------|-------------|
| **Multi-pair view** | Monitor multiple markets simultaneously |
| **Real-time order book** | Live depth visualization per pair |
| **Trade history** | Scrolling ticker of recent fills |
| **Position management** | Open orders, fills, and balance overview |
| **Category filtering** | Sovereign / Crypto / AI / Artifact / Creator tabs |
| **One-click trading** | Quick buy/sell at market with a single action |

### Interface Sections

```
┌──────────────────────────────────────────────────┐
│  [SOVEREIGN] [CRYPTO] [AI TOKENS] [ARTIFACTS]    │  ← Category tabs
├──────────────────────────────────────────────────┤
│  PAIR: BTC/ICP          LAST: 4,521.30 ICP      │  ← Active pair
├──────────────┬───────────────────────────────────┤
│  ORDER BOOK  │  CHART / DEPTH VISUALIZATION      │
│  ───────────── │                                   │
│  ASKS (red)  │                                   │
│  ─── spread ─│                                   │
│  BIDS (green)│                                   │
├──────────────┼───────────────────────────────────┤
│  ORDER FORM  │  RECENT TRADES                    │
│  [BUY][SELL] │  time | price | qty | side        │
│  Price: ___  │                                   │
│  Qty:   ___  │                                   │
│  [SUBMIT]    │                                   │
├──────────────┴───────────────────────────────────┤
│  MY OPEN ORDERS | MY FILLS | BALANCES            │  ← Account section
└──────────────────────────────────────────────────┘
```

---

## Multi-Chain Access

### How Traders From Other Chains Use PARALLAX

| Source Chain | Path to PARALLAX | Assets Available |
|--------------|-----------------|------------------|
| **ICP** | Native — direct canister calls | All pairs |
| **Bitcoin** | Deposit BTC → ckBTC via NNS bridge | BTC/ICP pairs |
| **Ethereum** | Deposit ETH → ckETH via NNS bridge | ETH/ICP pairs |
| **Any EVM** | Bridge to ETH → ckETH → PARALLAX | ETH/ICP pairs |
| **Solana** | (Planned) Direct bridge | SOL/ICP pairs |

### For ICP-Native Users
- Connect with Internet Identity
- Zero-step onboarding — trade immediately
- All pairs accessible with ICP or MTC

### For Cross-Chain Users
- Bridge assets via official ckBTC/ckETH minting
- Once on ICP, trade with zero gas
- Withdraw back to origin chain at any time

---

## API Access (For Developers & Bots)

### Candid Interface

All exchange functions are exposed via Candid (ICP's IDL):

```candid
service : {
  // Order management
  place_order : (PairId, Side, Price, Quantity) -> (OrderResult);
  cancel_order : (OrderId) -> (CancelResult);
  get_open_orders : () -> (vec Order) query;

  // Market data
  get_order_book : (PairId) -> (OrderBook) query;
  get_recent_trades : (PairId, nat) -> (vec Trade) query;
  get_pairs : () -> (vec PairInfo) query;

  // Account
  get_balances : () -> (vec Balance) query;
  deposit : (TokenId, Amount) -> (DepositResult);
  withdraw : (TokenId, Amount) -> (WithdrawResult);
}
```

### Agent Kit Integration

PARALLAX provides a TypeScript/JavaScript SDK for building trading agents:

```typescript
import { ParallaxAgent } from "@parallax/agent-kit";

const agent = new ParallaxAgent({
  identity: myInternetIdentity,
  canisterId: "xxxxx-xxxxx-xxxxx-xxxxx-cai",
});

// Place a limit buy
await agent.placeLimitBuy("BTC_ICP", {
  price: 4500,
  quantity: 0.1,
});

// Stream order book updates
agent.onOrderBookUpdate("BTC_ICP", (book) => {
  console.log("Best bid:", book.bids[0]);
  console.log("Best ask:", book.asks[0]);
});
```

See [Developer Guide](./DEVELOPER_GUIDE.md) for full SDK documentation.

---

## Production Engines (24 Active)

Behind the trading interface, 24 specialized AI production engines operate continuously:

| Engine | Function |
|--------|----------|
| Oeconomia.Machina Pretium | Dynamic pricing & fair value estimation |
| Arbitrium.Nexus | Cross-market arbitrage detection |
| Portio.Optima | Phi-weighted portfolio optimization |
| Custos.Vigilans | Risk monitoring & position limits |
| Liquiditas.Profunda | Liquidity depth analysis |
| Momentum.Fluxus | Trend & momentum detection |
| Volatilitas.Metrics | Volatility surface computation |
| Correlatio.Matrix | Cross-asset correlation tracking |

---

## Why PARALLAX for Traders

| vs. Traditional DEXs | PARALLAX Advantage |
|----------------------|-------------------|
| Gas fees on every trade | Zero fees — protocol pays all costs |
| 12-60 second finality | 873ms settlement |
| MEV extraction | No mempool — structural MEV protection |
| Fragmented liquidity | Unified order book across all pairs |
| Wallet signing per tx | Single auth, then trade freely |

| vs. CEXs | PARALLAX Advantage |
|-----------|-------------------|
| Custodial risk | Self-custody — your keys, your coins |
| Opaque matching | Open-source, deterministic matching |
| Geographic restrictions | Permissionless — no KYC required |
| Withdrawal delays | Instant — withdraw anytime |
| Single point of failure | Decentralized ICP subnet consensus |

---

*The fastest, cheapest, most transparent way to trade on-chain.*
