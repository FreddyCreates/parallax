# Developer Guide

Build on PARALLAX: ICP canisters, Agent Kit SDK patterns, bot integration, market making, event streaming, and exchange extension contracts.

## Overview

PARALLAX is designed for developers who want to:

- Build trading bots and automated strategies on ICP.
- Create AI agents that interact with DeFi markets.
- Integrate liquidity provision into applications.
- Extend the exchange with new market types, analytics, production engines, and agent workflows.

## Architecture

```text
Your Application / Agent / Bot
         |
         v
+-----------------------------+
|     PARALLAX Agent Kit      |  TypeScript SDK
|     (@parallax/agent-kit)   |
+-------------+---------------+
              | Candid calls
              v
+-----------------------------+
|   PARALLAX Backend Canister |  Motoko on ICP
|   phantom_exchange.mo       |
+-----------------------------+
```

## Local development

### Prerequisites

- DFINITY SDK `dfx` version 0.15 or later.
- Node.js 18 or later.
- pnpm.
- mops for Motoko package management.

### Setup

```bash
git clone https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse.git
cd PARALLAX-Exchange-Clearinghouse
pnpm install
cd src/backend && mops install && cd ../..
dfx start --background --clean
dfx deploy
cd src/frontend && pnpm dev
```

### Docker development

```bash
docker compose up
```

Default development surfaces:

| Surface | Port |
|---|---:|
| API / local replica gateway | 8000 |
| Frontend dev server | 5173 |

## Canister API reference

### Core exchange types

```motoko
type Side = variant { Buy; Sell };
type OrderType = variant { Limit; Market; PostOnly; IOC; FOK };

type PlaceOrderArgs = record {
  pair_id : text;
  side : Side;
  order_type : OrderType;
  price : opt float64;
  quantity : float64;
};

type OrderResult = variant {
  Ok : record { order_id : nat64; fills : vec Fill };
  Err : text;
};
```

### Service surface

```motoko
service : {
  place_order : (PlaceOrderArgs) -> (OrderResult);
  cancel_order : (nat64) -> (variant { Ok; Err : text });
  cancel_all_orders : (opt text) -> (nat64);

  get_order_book : (text) -> (OrderBook) query;
  get_recent_trades : (text, nat32) -> (vec Trade) query;
  get_all_pairs : () -> (vec PairInfo) query;
  get_ticker : (text) -> (Ticker) query;

  get_balances : () -> (vec TokenBalance) query;
  get_open_orders : (opt text) -> (vec Order) query;
  get_trade_history : (opt text, nat32) -> (vec Trade) query;

  deposit : (text, float64) -> (variant { Ok; Err : text });
  withdraw : (text, float64) -> (variant { Ok; Err : text });
}
```

## Query vs update calls

| Call type | Cost model | Latency target | Use for |
|---|---|---:|---|
| Query | No user fee; canister reads | Approximately 100 ms | Market data, balances, order book, account reads |
| Update | Protocol/canister cycles | Approximately 2 s | Orders, cancellation, deposits, withdrawals, settlement state changes |

## Agent Kit SDK

### Installation

```bash
npm install @parallax/agent-kit
# or
pnpm add @parallax/agent-kit
```

### Basic usage

```ts
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";
import { AuthClient } from "@dfinity/auth-client";

const authClient = await AuthClient.create();
const identity = authClient.getIdentity();

const agent = new ParallaxAgent({
  identity,
  canisterId: "your-canister-id",
  host: "https://ic0.app"
});

const pairs = await agent.getPairs();
const book = await agent.getOrderBook("BTC_ICP");
const trades = await agent.getRecentTrades("BTC_ICP", 50);

const result = await agent.placeOrder({
  pairId: "BTC_ICP",
  side: Side.Buy,
  orderType: OrderType.Limit,
  price: 4500.0,
  quantity: 0.1
});

await agent.cancelOrder(result.orderId);
await agent.cancelAllOrders("BTC_ICP");

const balances = await agent.getBalances();
```

## Market making bot example

```ts
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";

async function marketMake(agent: ParallaxAgent, pairId: string) {
  const ticker = await agent.getTicker(pairId);
  const midPrice = (ticker.bestBid + ticker.bestAsk) / 2;
  const spread = 0.002;

  await agent.placeOrder({
    pairId,
    side: Side.Buy,
    orderType: OrderType.PostOnly,
    price: midPrice * (1 - spread),
    quantity: 1.0
  });

  await agent.placeOrder({
    pairId,
    side: Side.Sell,
    orderType: OrderType.PostOnly,
    price: midPrice * (1 + spread),
    quantity: 1.0
  });
}

setInterval(() => marketMake(agent, "BTC_ICP"), 873);
```

## Event streaming patterns

```ts
agent.onTrade("BTC_ICP", (trade) => {
  console.log(`${trade.side} ${trade.quantity} @ ${trade.price}`);
});

agent.onOrderBookUpdate("BTC_ICP", (book) => {
  const spread = book.asks[0].price - book.bids[0].price;
  console.log(`Spread: ${spread.toFixed(4)} ICP`);
});

agent.onFill((fill) => {
  console.log(`Filled: ${fill.quantity} @ ${fill.price}`);
});
```

## AI trading agent pattern

```ts
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";

class AITradingAgent {
  private agent: ParallaxAgent;
  private model: { predict(input: unknown): any };

  constructor(agent: ParallaxAgent, model: { predict(input: unknown): any }) {
    this.agent = agent;
    this.model = model;
  }

  async analyze(pairId: string) {
    const trades = await this.agent.getRecentTrades(pairId, 100);
    const book = await this.agent.getOrderBook(pairId);

    return this.model.predict({
      recentPrices: trades.map((t) => t.price),
      bidDepth: book.bids.reduce((sum, b) => sum + b.quantity, 0),
      askDepth: book.asks.reduce((sum, a) => sum + a.quantity, 0)
    });
  }

  async execute(pairId: string, signal: any) {
    if (signal.confidence < 0.7) return;

    await this.agent.placeOrder({
      pairId,
      side: signal.direction === "buy" ? Side.Buy : Side.Sell,
      orderType: OrderType.Limit,
      price: signal.targetPrice,
      quantity: signal.size
    });
  }
}
```

## Extending the platform

### Adding a token type

1. Define the token in `src/backend/token_factory.mo`.
2. Register the trading pair in `src/backend/phantom_exchange.mo`.
3. Add frontend display in `src/frontend/src/tabs/PhantomExchangeTab.tsx`.
4. Add or update market metadata in `market-registry/parallax_markets.json`.
5. Submit a PR for review.

### Adding a production engine

1. Define engine logic in `src/backend/production_engines.mo`.
2. Register the engine with the heartbeat system.
3. Add monitoring to the admin dashboard.
4. Add tests and receipts.
5. Document the engine in this guide.

## Testing

### Backend tests

```bash
cd src/backend
mops test
```

### Frontend tests

```bash
cd src/frontend
pnpm test
```

### Integration tests

```bash
dfx start --background --clean
dfx deploy
pnpm test:integration
```

## Deployment

### Local

```bash
dfx start --background --clean
dfx deploy
```

### Mainnet

```bash
dfx deploy --network ic
```

## Canister IDs

| Canister | Local | Mainnet |
|---|---|---|
| Backend | Auto-generated | TBD post-launch |
| Frontend | Auto-generated | TBD post-launch |
| Internet Identity | rdmx6-jaaaa-aaaaa-aaadq-cai | rdmx6-jaaaa-aaaaa-aaadq-cai |

## Build boundary

This guide documents developer integration surfaces and intended exchange behavior. It does not assert that every planned market, bridge, agent event stream, or SDK package is live on mainnet. Mainnet activation requires deployed canister IDs, tests, governance activation, risk controls, and release receipts.
