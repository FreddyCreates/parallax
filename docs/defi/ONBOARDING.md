# 🚀 Onboarding Guide

> Get started trading on PARALLAX Exchange in minutes — zero gas fees, instant settlement.

---

## Overview

PARALLAX is a decentralized exchange built on the Internet Computer Protocol (ICP). Unlike traditional DEXs, there are **no gas fees** — the protocol's canister infrastructure covers all execution costs. Settlement happens every **873ms** with cryptographic finality.

---

## Step 1: Connect Your Identity

PARALLAX uses **Internet Identity** — ICP's native authentication system. No seed phrases to manage, no MetaMask popups.

1. Navigate to the PARALLAX Exchange interface
2. Click **"Connect"** in the top navigation
3. Authenticate via Internet Identity (biometric or hardware key)
4. Your principal ID is your on-chain identity

### Supported Authentication Methods
- Internet Identity (recommended)
- NFID
- Plug Wallet (ICP)
- Cross-chain wallets via ckBTC/ckETH bridges

---

## Step 2: Fund Your Account

### Native ICP Assets
- Transfer **ICP** directly to your PARALLAX principal
- Use **ckBTC** (chain-key Bitcoin) for BTC exposure
- Use **ckETH** (chain-key Ethereum) for ETH exposure

### Cross-Chain Deposits
PARALLAX supports bridged assets from multiple chains:
- **Bitcoin** → ckBTC (trustless, threshold-signature bridge)
- **Ethereum** → ckETH (ICP native chain-key cryptography)
- **Stablecoins** → Bridged USDC/USDT (coming soon)

### Minimum Deposits
| Asset | Minimum | Notes |
|-------|---------|-------|
| ICP | 0.01 ICP | Native, instant |
| ckBTC | 0.0001 BTC | ~2 BTC confirmations |
| ckETH | 0.001 ETH | ~12 ETH confirmations |

---

## Step 3: Place Your First Trade

1. Navigate to the **EXCHANGE** tab
2. Select a trading pair (e.g., `BTC_ICP`, `AICPU_ICP`)
3. Choose **Buy** or **Sell**
4. Enter price and quantity
5. Submit — settlement in ≤873ms

### Order Types
- **Limit Order** — specify exact price; rests on the order book
- **Market Order** — immediate execution at best available price
- **Post-Only** — guaranteed maker order (no taker fees)

---

## Step 4: Explore Advanced Features

### AI Token Markets
Trade tokenized AI compute resources:
- GPU time, inference credits, training tokens
- AI agent execution tokens
- Model artifact NFTs

### Prediction Markets
Stake on future outcomes using the Prediction Engine.

### LP (Liquidity Provision)
Provide liquidity to earn trading fee share — see [LP & Agents](./LP_AND_AGENTS.md).

---

## Key Concepts

| Concept | What It Means |
|---------|---------------|
| **Zero Gas** | You never pay transaction fees — the organism covers all canister cycles |
| **873ms Settlement** | Every trade settles in under 1 second with finality |
| **Central Counterparty** | The protocol guarantees settlement — no counterparty risk |
| **Orthogonal Persistence** | Your balances and orders persist natively in ICP canister memory |
| **Principal ID** | Your unique on-chain identity (no private keys to lose) |

---

## Getting Help

- Open an [issue](https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse/issues) on GitHub
- Review the [Developer Guide](./DEVELOPER_GUIDE.md) for technical integration
- Check [Risk Disclosure](./RISK_DISCLOSURE.md) before trading

---

*Trade everything. Pay nothing. Settle instantly.*
