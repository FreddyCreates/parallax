# 🛠️ Developer Guide

> Build on PARALLAX — ICP canisters, Agent Kit SDK, bot integration, and extending the exchange.

---

## Overview

PARALLAX is designed for developers who want to:
- Build **trading bots** and automated strategies on ICP
- Create **AI agents** that interact with DeFi markets
- Integrate **liquidity provision** into their applications
- Extend the exchange with **new market types** or **analytics**

---

## Architecture for Developers

```
Your Application / Agent / Bot
         │
         ▼
┌─────────────────────────────┐
│     PARALLAX Agent Kit      │  ← TypeScript SDK
│     (@parallax/agent-kit)   │
└──────────────┬──────────────┘
               │ Candid calls
               ▼
┌─────────────────────────────┐
│   PARALLAX Backend Canister │  ← Motoko on ICP
│   (phantom_exchange.mo)     │
└─────────────────────────────┘
```

---

## Getting Started (Local Development)

### Prerequisites
- [DFINITY SDK (dfx)](https://internetcomputer.org/docs/current/developer-docs/setup/install) ≥ 0.15
- [Node.js](https://nodejs.org/) ≥ 18
- [pnpm](https://pnpm.io/) (package manager)
- [mops](https://mops.one/) (Motoko package manager)

### Local Setup

```bash
# Clone the repository
git clone https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse.git
cd PARALLAX-Exchange-Clearinghouse

# Install all dependencies
pnpm install
cd src/backend && mops install && cd ../..

# Start local ICP replica
dfx start --background --clean

# Deploy canisters locally
dfx deploy

# Start frontend dev server
cd src/frontend && pnpm dev
```

### Docker Development (Fastest)

```bash
docker compose up
# API at :8000, Frontend at :5173
```

---

## Canister API Reference

### Core Exchange Interface

```candid
type Side = variant { Buy; Sell };
type OrderType = variant { Limit; Market; PostOnly; IOC; FOK };

type PlaceOrderArgs = record {
  pair_id : text;
  side : Side;
  order_type : OrderType;
  price : opt float64;     // Required for Limit, PostOnly
  quantity : float64;
};

type OrderResult = variant {
  Ok : record { order_id : nat64; fills : vec Fill };
  Err : text;
};

service : {
  // Trading
  place_order : (PlaceOrderArgs) -> (OrderResult);
  cancel_order : (nat64) -> (variant { Ok; Err : text });
  cancel_all_orders : (opt text) -> (nat64);  // Returns count cancelled

  // Market Data (queries — free, instant)
  get_order_book : (text) -> (OrderBook) query;
  get_recent_trades : (text, nat32) -> (vec Trade) query;
  get_all_pairs : () -> (vec PairInfo) query;
  get_ticker : (text) -> (Ticker) query;

  // Account (queries)
  get_balances : () -> (vec TokenBalance) query;
  get_open_orders : (opt text) -> (vec Order) query;
  get_trade_history : (opt text, nat32) -> (vec Trade) query;

  // Deposits & Withdrawals
  deposit : (text, float64) -> (variant { Ok; Err : text });
  withdraw : (text, float64) -> (variant { Ok; Err : text });
}
```

### Query vs. Update Calls

| Call Type | Cost | Latency | Use For |
|-----------|------|---------|---------|
| **Query** | Free | ~100ms | Reading market data, balances, order book |
| **Update** | Free* | ~2s | Placing/cancelling orders, deposits, withdrawals |

*Free because the protocol pays canister cycles.

---

## Agent Kit SDK

### Installation

```bash
npm install @parallax/agent-kit
# or
pnpm add @parallax/agent-kit
```

### Basic Usage

```typescript
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";
import { AuthClient } from "@dfinity/auth-client";

// Initialize with Internet Identity
const authClient = await AuthClient.create();
const identity = authClient.getIdentity();

const agent = new ParallaxAgent({
  identity,
  canisterId: "your-canister-id",
  host: "https://ic0.app", // mainnet
  // host: "http://localhost:8000" // local dev
});

// Get market data
const pairs = await agent.getPairs();
const book = await agent.getOrderBook("BTC_ICP");
const trades = await agent.getRecentTrades("BTC_ICP", 50);

// Place orders
const result = await agent.placeOrder({
  pairId: "BTC_ICP",
  side: Side.Buy,
  orderType: OrderType.Limit,
  price: 4500.0,
  quantity: 0.1,
});

// Cancel orders
await agent.cancelOrder(result.orderId);
await agent.cancelAllOrders("BTC_ICP");

// Check balances
const balances = await agent.getBalances();
```

### Market Making Bot Example

```typescript
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";

async function marketMake(agent: ParallaxAgent, pairId: string) {
  const ticker = await agent.getTicker(pairId);
  const midPrice = (ticker.bestBid + ticker.bestAsk) / 2;
  const spread = 0.002; // 0.2% spread

  // Place bid and ask
  await agent.placeOrder({
    pairId,
    side: Side.Buy,
    orderType: OrderType.PostOnly,
    price: midPrice * (1 - spread),
    quantity: 1.0,
  });

  await agent.placeOrder({
    pairId,
    side: Side.Sell,
    orderType: OrderType.PostOnly,
    price: midPrice * (1 + spread),
    quantity: 1.0,
  });
}

// Run every heartbeat cycle
setInterval(() => marketMake(agent, "BTC_ICP"), 873);
```

### Event Streaming

```typescript
// Subscribe to trade events
agent.onTrade("BTC_ICP", (trade) => {
  console.log(`${trade.side} ${trade.quantity} @ ${trade.price}`);
});

// Subscribe to order book changes
agent.onOrderBookUpdate("BTC_ICP", (book) => {
  const spread = book.asks[0].price - book.bids[0].price;
  console.log(`Spread: ${spread.toFixed(4)} ICP`);
});

// Subscribe to your own fills
agent.onFill((fill) => {
  console.log(`Filled: ${fill.quantity} @ ${fill.price}`);
});
```

---

## Building Custom Agents

### AI Trading Agent Pattern

```typescript
import { ParallaxAgent } from "@parallax/agent-kit";

class AITradingAgent {
  private agent: ParallaxAgent;
  private model: any; // Your ML model

  constructor(agent: ParallaxAgent, model: any) {
    this.agent = agent;
    this.model = model;
  }

  async analyze(pairId: string) {
    const trades = await this.agent.getRecentTrades(pairId, 100);
    const book = await this.agent.getOrderBook(pairId);

    // Feed to your model
    const signal = this.model.predict({
      recentPrices: trades.map(t => t.price),
      bidDepth: book.bids.reduce((sum, b) => sum + b.quantity, 0),
      askDepth: book.asks.reduce((sum, a) => sum + a.quantity, 0),
    });

    return signal; // { direction: "buy" | "sell", confidence: 0-1 }
  }

  async execute(pairId: string, signal: any) {
    if (signal.confidence < 0.7) return; // Skip low-confidence signals

    await this.agent.placeOrder({
      pairId,
      side: signal.direction === "buy" ? Side.Buy : Side.Sell,
      orderType: OrderType.Limit,
      price: signal.targetPrice,
      quantity: signal.size,
    });
  }
}
```

---

## Extending the Platform

### Adding a New Token Type

1. Define the token in `src/backend/token_factory.mo`
2. Register the trading pair in `src/backend/phantom_exchange.mo`
3. Add frontend display in `src/frontend/src/tabs/PhantomExchangeTab.tsx`
4. Submit PR for community review

### Adding a New Production Engine

1. Define engine logic in `src/backend/production_engines.mo`
2. Register with the heartbeat system
3. Add monitoring to the admin dashboard
4. Document in this guide

---

## Testing

### Backend Tests (Motoko)

```bash
cd src/backend
mops test
```

### Frontend Tests (Vitest)

```bash
cd src/frontend
pnpm test
```

### Integration Tests

```bash
# Start local replica
dfx start --background --clean
dfx deploy

# Run integration suite
pnpm test:integration
```

---

## Deployment

### Local (Development)
```bash
dfx start --background --clean
dfx deploy
```

### Mainnet (Production)
```bash
dfx deploy --network ic
```

### Canister IDs

| Canister | Local | Mainnet |
|----------|-------|---------|
| Backend | auto-generated | TBD (post-launch) |
| Frontend | auto-generated | TBD (post-launch) |
| Internet Identity | `rdmx6-jaaaa-aaaaa-aaadq-cai` | `rdmx6-jaaaa-aaaaa-aaadq-cai` |

---

## Resources

- [ICP Developer Docs](https://internetcomputer.org/docs)
- [Motoko Language Reference](https://internetcomputer.org/docs/current/motoko/main/motoko)
- [Candid Interface Description](https://internetcomputer.org/docs/current/developer-docs/backend/candid/)
- [Agent JS Library](https://github.com/dfinity/agent-js)
- [PARALLAX Repository](https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse)

---

*Build the future of trading. We handle the infrastructure.*
