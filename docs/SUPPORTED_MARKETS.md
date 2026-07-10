# Supported Markets

Complete reference for tradeable pairs, asset categories, quote assets, market specifications, and planned expansions on PARALLAX Exchange.

## Market categories

| Category | Description | Quote assets |
|---|---|---|
| Sovereign | Protocol-native governance and utility tokens | ICP |
| Crypto | Major cryptocurrencies via ICP chain-key bridges | ICP |
| AI Tokens | Tokenized AI compute, inference, training, memory, data, and evaluation resources | ICP, MTC |
| AI Artifacts | Tokenized AI models, agents, datasets, protocols, and systems | MTC |
| Creator | Personal tokens, fan tokens, and creator economies | ICP, MTC |

## Sovereign markets

Protocol-native tokens powering the PARALLAX organism.

| Pair | Base | Quote | Description |
|---|---:|---:|---|
| GTK/ICP | GTK | ICP | Governance Token — protocol voting rights |
| MTC/ICP | MTC | ICP | Materia Cogitans — AI compute settlement unit |
| MTH/ICP | MTH | ICP | Methane — energy and resource pricing token |

## Crypto markets

Major cryptocurrencies accessible through ICP chain-key technology.

| Pair | Base | Quote | Bridge |
|---|---:|---:|---|
| BTC/ICP | BTC / ckBTC | ICP | Chain-Key Bitcoin |
| ETH/ICP | ETH / ckETH | ICP | Chain-Key Ethereum |

### Planned crypto expansions

| Pair | Method | Status |
|---|---|---|
| SOL/ICP | Future chain-key or bridge integration | Research |
| USDC/ICP | Bridged stablecoin | Planned |
| USDT/ICP | Bridged stablecoin | Planned |
| DOT/ICP | Cross-chain bridge | Research |
| ATOM/ICP | Cross-chain bridge | Research |

## AI token markets

Tokenized AI infrastructure resources.

### Core infrastructure tokens

| Pair | Token | Description |
|---|---:|---|
| AICPU/ICP | AICPU | General AI compute credits |
| AIMEM/ICP | AIMEM | AI memory allocation units |
| AIINF/ICP | AIINF | Inference execution credits |
| AITRAIN/ICP | AITRAIN | Training compute allocation |
| AIDATA/ICP | AIDATA | Dataset access and storage |

### Advanced resource tokens

| Pair | Token | Description |
|---|---:|---|
| AIGPU/ICP | AIGPU | GPU compute hours |
| AITPU/ICP | AITPU | TPU compute allocation |
| AIBW/ICP | AIBW | Network bandwidth credits |
| AIST/ICP | AIST | Persistent storage allocation |
| AIFT/ICP | AIFT | Fine-tuning compute credits |
| AIEMB/ICP | AIEMB | Embedding generation credits |
| AIRAG/ICP | AIRAG | RAG pipeline execution credits |
| AIAGENT/ICP | AIAGENT | Agent execution time |
| AIORCH/ICP | AIORCH | Orchestration and workflow credits |
| AICHAIN/ICP | AICHAIN | Reasoning chain execution |

### Specialized capability tokens

| Pair | Token | Description |
|---|---:|---|
| AIVIS/ICP | AIVIS | Vision model inference |
| AIAUD/ICP | AIAUD | Audio model processing |
| AICODE/ICP | AICODE | Code generation credits |
| AITRANS/ICP | AITRANS | Translation model access |
| AISENT/ICP | AISENT | Sentiment analysis |
| AIANOM/ICP | AIANOM | Anomaly detection |
| AIPRED/ICP | AIPRED | Prediction model queries |
| AIOPT/ICP | AIOPT | Optimization credits |
| AISIM/ICP | AISIM | Simulation execution |

### Governance and quality tokens

| Pair | Token | Description |
|---|---:|---|
| AIMVOTE/ICP | AIMVOTE | Model governance votes |
| AIDVOTE/ICP | AIDVOTE | Dataset governance votes |
| AISAFE/ICP | AISAFE | Safety audit credits |
| AIRED/ICP | AIRED | Red-team evaluation credits |
| AIBENCH/ICP | AIBENCH | Benchmark certification |
| AICERT/ICP | AICERT | Model certification tokens |

## AI artifact markets

Tokenized AI intellectual property traded against MTC.

| Pair | Type | Description |
|---|---|---|
| AIMDL/MTC | Models | Foundation models, fine-tuned models, LoRA adapters, merged models, and quantized models |
| AIEMB/MTC | Embeddings | Embedding models and vector representations |
| AIPROT/MTC | Protocols | AI alignment, safety, governance, and evaluation protocols |
| AIAGENT/MTC | Autonomous agents | Agent systems with tools, memory, workflows, orchestrators, evaluators, and persona definitions |
| AIRAG/MTC | RAG and knowledge systems | RAG pipelines, vector databases, rerankers, knowledge bases, and chunking strategies |
| AIDATA/MTC | Training and dataset artifacts | Synthetic, labeled, preference, instruction-tuning, code, multilingual, and domain corpora |

## Creator markets

Creator, community, and personal-token markets are supported through governance-approved listings.

| Pair form | Description | Quotes |
|---|---|---|
| CREATOR/ICP | Creator token priced in ICP | ICP |
| CREATOR/MTC | Creator token priced in AI compute settlement units | MTC |

## Market specifications

| Parameter | Value | Notes |
|---|---:|---|
| Tick size | 0.0001 | Minimum price increment |
| Minimum order | 0.001 | Minimum order quantity |
| Settlement cadence | 873 ms | φ-aligned heartbeat settlement target |
| Max open orders | 100 | Per principal, per pair |
| Maker fee | 0.00% | Zero fee target for liquidity providers |
| Taker fee | 0.05% | Minimal execution fee target |

## Order book mechanics

PARALLAX markets use price-time priority. Orders at the same price fill in FIFO order. The exchange design supports bilateral netting, multilateral netting, and central-counterparty-style protocol settlement semantics before external settlement adapters are activated.

## Trading hours

PARALLAX is designed for 24/7/365 operation on ICP canister infrastructure.

## Cross-chain compatibility

| Chain | Method | Deposit latency | Trading latency |
|---|---|---:|---:|
| ICP | Native | Instant | Instant |
| Bitcoin | ckBTC / chain-key | Approximately 20 minutes | Instant after credit |
| Ethereum | ckETH / chain-key | Approximately 5 minutes | Instant after credit |

## Planned integrations

| Chain | Method | Status |
|---|---|---|
| Solana | Bridge / future chain-key path | Research |
| Cosmos | IBC via bridge | Research |
| Polkadot | XCM adapter | Planned |

## Adding new markets

New trading pairs are activated through governance review:

1. Submit a market addition proposal through the Council.
2. Review liquidity, demand, bridge/custody risk, oracle risk, and settlement risk.
3. Vote on inclusion criteria and risk parameters.
4. Activate the pair with initial tick size, min order, max open orders, quote asset, and fee schedule.
5. Publish market-maker incentives and monitoring requirements.

## Boundary

This document is a market registry and developer-facing specification. Listings marked planned or research are not live markets until implemented, tested, governed, and activated on the deployed canister set.
