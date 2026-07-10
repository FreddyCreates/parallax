# 💧 LP Incentives & Agent Kit Integrations

> Earn yield by providing liquidity. Build trading agents with the PARALLAX Agent Kit.

---

## Liquidity Provision (LP)

### Why Provide Liquidity?

PARALLAX needs deep order books to offer tight spreads and low slippage. Liquidity providers (LPs) are rewarded for making markets:

| Benefit | Description |
|---------|-------------|
| **Trading fee share** | Earn a portion of all taker fees on your pairs |
| **Zero maker fees** | LPs never pay fees — only earn them |
| **LP rewards** | Additional token incentives for active market makers |
| **Priority fills** | Post-Only orders guarantee maker status |

---

### How LP Works on PARALLAX

Unlike AMM-based DEXs (Uniswap, etc.), PARALLAX uses a **Central Limit Order Book (CLOB)**. This means:

- You place **limit orders** at prices you choose
- No impermanent loss from automated curves
- Full control over your price exposure
- Tighter spreads earn more volume

### LP Reward Tiers

| Tier | Uptime | Spread | Monthly Reward |
|------|--------|--------|----------------|
| **Bronze** | > 50% | < 2% | Base rewards |
| **Silver** | > 75% | < 1% | 2× multiplier |
| **Gold** | > 90% | < 0.5% | 5× multiplier |
| **Platinum** | > 95% | < 0.2% | 10× multiplier |

**Uptime** = percentage of time you have active orders on both sides of the book.
**Spread** = average distance of your orders from mid-price.

---

### Getting Started as an LP

1. **Fund your account** with the assets you want to provide (e.g., ICP + BTC)
2. **Place limit orders** on both bid and ask sides of your chosen pair
3. **Maintain orders** — keep them refreshed as the market moves
4. **Earn fees** — every time a taker crosses your order, you earn the spread + fee share

### Example: Market Making BTC/ICP

```typescript
import { ParallaxAgent, Side, OrderType } from "@parallax/agent-kit";

async function provideLiquidity(agent: ParallaxAgent) {
  const ticker = await agent.getTicker("BTC_ICP");
  const mid = (ticker.bestBid + ticker.bestAsk) / 2;

  // Place 5 levels of bids and asks
  for (let i = 1; i <= 5; i++) {
    const offset = mid * 0.001 * i; // 0.1% per level

    await agent.placeOrder({
      pairId: "BTC_ICP",
      side: Side.Buy,
      orderType: OrderType.PostOnly,
      price: mid - offset,
      quantity: 0.05 * i, // Larger size further from mid
    });

    await agent.placeOrder({
      pairId: "BTC_ICP",
      side: Side.Sell,
      orderType: OrderType.PostOnly,
      price: mid + offset,
      quantity: 0.05 * i,
    });
  }
}
```

---

### LP Risk Management

| Risk | Mitigation |
|------|-----------|
| **Adverse selection** | Widen spread during high volatility |
| **Inventory imbalance** | Skew quotes toward the side you want to accumulate |
| **Stale orders** | Use Agent Kit to auto-refresh on price moves |
| **Sudden gaps** | Set maximum position limits per pair |

---

## Agent Kit Integrations

### What Is the Agent Kit?

The PARALLAX Agent Kit is a TypeScript/JavaScript SDK that enables:
- Automated trading strategies
- AI-powered market analysis
- Portfolio rebalancing bots
- Arbitrage detection across pairs
- Custom notification and alerting systems

### Integration Patterns

#### 1. Simple Rebalancer

Keeps your portfolio at target weights:

```typescript
import { ParallaxAgent } from "@parallax/agent-kit";

async function rebalance(agent: ParallaxAgent, targets: Record<string, number>) {
  const balances = await agent.getBalances();
  const totalValue = calculateTotalValue(balances);

  for (const [token, targetWeight] of Object.entries(targets)) {
    const currentWeight = balances[token].value / totalValue;
    const drift = currentWeight - targetWeight;

    if (Math.abs(drift) > 0.05) { // 5% threshold
      const pair = `${token}_ICP`;
      const side = drift > 0 ? Side.Sell : Side.Buy;
      const amount = Math.abs(drift) * totalValue;

      await agent.placeOrder({
        pairId: pair,
        side,
        orderType: OrderType.Market,
        quantity: amount,
      });
    }
  }
}
```

#### 2. Cross-Pair Arbitrage Agent

Detects and captures arbitrage across related pairs:

```typescript
async function detectArbitrage(agent: ParallaxAgent) {
  const [btcIcp, ethIcp, ethBtc] = await Promise.all([
    agent.getTicker("BTC_ICP"),
    agent.getTicker("ETH_ICP"),
    agent.getExternalPrice("ETH_BTC"), // External oracle
  ]);

  const impliedEthIcp = btcIcp.midPrice * ethBtc;
  const actualEthIcp = ethIcp.midPrice;
  const spread = (actualEthIcp - impliedEthIcp) / impliedEthIcp;

  if (Math.abs(spread) > 0.005) { // 0.5% arb threshold
    // Execute triangular arbitrage
    if (spread > 0) {
      // ETH overpriced on PARALLAX relative to BTC
      await agent.placeOrder({ pairId: "ETH_ICP", side: Side.Sell, ... });
      await agent.placeOrder({ pairId: "BTC_ICP", side: Side.Buy, ... });
    }
  }
}
```

#### 3. AI Sentiment Agent

Uses AI model predictions to inform trading:

```typescript
async function sentimentTrade(agent: ParallaxAgent, aiModel: any) {
  const trades = await agent.getRecentTrades("AICPU_ICP", 200);
  const book = await agent.getOrderBook("AICPU_ICP");

  // Run prediction model
  const prediction = await aiModel.predict({
    priceHistory: trades.map(t => t.price),
    volumeProfile: trades.map(t => t.quantity),
    bookImbalance: calculateImbalance(book),
  });

  if (prediction.confidence > 0.8) {
    await agent.placeOrder({
      pairId: "AICPU_ICP",
      side: prediction.direction === "up" ? Side.Buy : Side.Sell,
      orderType: OrderType.Limit,
      price: prediction.entryPrice,
      quantity: prediction.suggestedSize,
    });
  }
}
```

#### 4. Notification & Monitoring Agent

```typescript
agent.onTrade("BTC_ICP", (trade) => {
  if (trade.price > alertThreshold) {
    sendNotification(`BTC/ICP crossed ${alertThreshold}!`);
  }
});

agent.onFill((fill) => {
  logToDatabase(fill);
  updatePnL(fill);
});
```

---

## Integration with External Systems

### Connecting to Off-Chain Data

```typescript
// Price feeds from external sources
const externalPrice = await fetch("https://api.coingecko.com/...");

// On-chain governance signals
const nnsProposals = await queryNNS();

// Social sentiment
const twitterSentiment = await analyzeSentiment("$ICP");
```

### Webhook Notifications

```typescript
agent.onFill(async (fill) => {
  await fetch("https://your-webhook.com/fills", {
    method: "POST",
    body: JSON.stringify(fill),
  });
});
```

---

## Roadmap: Agent Kit v2

| Feature | Status | ETA |
|---------|--------|-----|
| Basic order management | ✅ Available | Now |
| Market data streaming | ✅ Available | Now |
| Event subscriptions | ✅ Available | Now |
| Portfolio analytics | 🔨 Building | Q3 2025 |
| Strategy backtesting | 📋 Planned | Q4 2025 |
| Multi-canister orchestration | 📋 Planned | Q1 2026 |
| Visual strategy builder | 💡 Exploring | TBD |

---

*Liquidity is the lifeblood. Agents are the future. Build both.*
