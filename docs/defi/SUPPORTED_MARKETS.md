# 📊 Supported Markets

> Complete reference of all tradeable pairs, asset categories, and market specifications on PARALLAX Exchange.

---

## Market Categories

PARALLAX supports five primary market categories:

| Category | Description | Quote Assets |
|----------|-------------|--------------|
| **Sovereign** | Protocol-native governance & utility tokens | ICP |
| **Crypto** | Major cryptocurrencies via chain-key bridges | ICP |
| **AI Tokens** | Tokenized AI compute, inference, and training resources | ICP, MTC |
| **AI Artifacts** | Tokenized AI models, agents, datasets, and systems | MTC |
| **Creator** | Personal tokens, fan tokens, and creator economies | ICP, MTC |

---

## Sovereign Markets

Protocol-native tokens powering the PARALLAX organism:

| Pair | Base | Quote | Description |
|------|------|-------|-------------|
| GTK/ICP | GTK | ICP | Governance Token — protocol voting rights |
| MTC/ICP | MTC | ICP | Materia Cogitans — AI compute settlement unit |
| MTH/ICP | MTH | ICP | Methane — energy & resource pricing token |

---

## Crypto Markets

Major cryptocurrencies accessible via ICP chain-key technology:

| Pair | Base | Quote | Bridge |
|------|------|-------|--------|
| BTC/ICP | BTC (ckBTC) | ICP | Chain-Key Bitcoin |
| ETH/ICP | ETH (ckETH) | ICP | Chain-Key Ethereum |

### Planned Crypto Expansions
- SOL/ICP (via future chain-key integration)
- USDC/ICP and USDT/ICP (bridged stablecoins)
- DOT/ICP, ATOM/ICP (cross-chain bridges)

---

## AI Token Markets (37 Token Types)

Tokenized AI infrastructure resources:

### Core Infrastructure Tokens
| Pair | Token | Description |
|------|-------|-------------|
| AICPU/ICP | AICPU | General AI compute credits |
| AIMEM/ICP | AIMEM | AI memory allocation units |
| AIINF/ICP | AIINF | Inference execution credits |
| AITRAIN/ICP | AITRAIN | Training compute allocation |
| AIDATA/ICP | AIDATA | Dataset access & storage |

### Advanced Resource Tokens
| Pair | Token | Description |
|------|-------|-------------|
| AIGPU/ICP | AIGPU | GPU compute hours |
| AITPU/ICP | AITPU | TPU compute allocation |
| AIBW/ICP | AIBW | Network bandwidth credits |
| AIST/ICP | AIST | Persistent storage allocation |
| AIFT/ICP | AIFT | Fine-tuning compute credits |
| AIEMB/ICP | AIEMB | Embedding generation credits |
| AIRAG/ICP | AIRAG | RAG pipeline execution credits |
| AIAGENT/ICP | AIAGENT | Agent execution time |
| AIORCH/ICP | AIORCH | Orchestration & workflow credits |
| AICHAIN/ICP | AICHAIN | Reasoning chain execution |

### Specialized Capability Tokens
| Pair | Token | Description |
|------|-------|-------------|
| AIVIS/ICP | AIVIS | Vision model inference |
| AIAUD/ICP | AIAUD | Audio model processing |
| AICODE/ICP | AICODE | Code generation credits |
| AITRANS/ICP | AITRANS | Translation model access |
| AISENT/ICP | AISENT | Sentiment analysis |
| AIANOM/ICP | AIANOM | Anomaly detection |
| AIPRED/ICP | AIPRED | Prediction model queries |
| AIOPT/ICP | AIOPT | Optimization credits |
| AISIM/ICP | AISIM | Simulation execution |

### Governance & Quality Tokens
| Pair | Token | Description |
|------|-------|-------------|
| AIMVOTE/ICP | AIMVOTE | Model governance votes |
| AIDVOTE/ICP | AIDVOTE | Dataset governance votes |
| AISAFE/ICP | AISAFE | Safety audit credits |
| AIRED/ICP | AIRED | Red-team evaluation credits |
| AIBENCH/ICP | AIBENCH | Benchmark certification |
| AICERT/ICP | AICERT | Model certification tokens |

---

## AI Artifact Markets (55 Artifact Types)

Tokenized AI intellectual property traded against MTC:

### Foundation & Advanced Models
| Pair | Type | Description |
|------|------|-------------|
| AIMDL/MTC | Models | Foundation models, fine-tuned, LoRA, merged, quantized |
| AIEMB/MTC | Embeddings | Embedding models and vector representations |
| AIPROT/MTC | Protocols | AI alignment and safety protocols |

### Autonomous Agent Artifacts
- Agent systems with tools, memory, and workflows
- Orchestrators, evaluators, and persona definitions
- Multi-agent workflow templates

### RAG & Knowledge Systems
- RAG pipelines and vector databases
- Embedding models and rerankers
- Knowledge bases and chunking strategies

### Training & Dataset Artifacts
- Synthetic, labeled, and preference datasets
- Instruction-tuning and code datasets
- Multilingual and domain-specific corpora

---

## Market Specifications

### Trading Parameters

| Parameter | Value | Derivation |
|-----------|-------|------------|
| Tick Size | 0.0001 | Minimum price increment |
| Min Order | 0.001 | Minimum order quantity |
| Settlement | 873ms | φ⁴ × (1000ms / 7.83Hz) |
| Max Open Orders | 100 | Per principal, per pair |
| Maker Fee | 0.00% | Zero fees for liquidity providers |
| Taker Fee | 0.05% | Minimal execution fee |

### Order Book Mechanics
- **Price-Time Priority** — orders at same price fill in FIFO order
- **Bilateral Netting** — offsetting positions net before settlement
- **Multilateral Netting** — cross-pair netting reduces settlement volume
- **Central Counterparty** — protocol guarantees all matched trades

### Trading Hours
PARALLAX operates **24/7/365** — no downtime, no maintenance windows. The ICP canister infrastructure provides continuous availability.

---

## Cross-Chain Compatibility

### Currently Supported
| Chain | Method | Latency |
|-------|--------|---------|
| Bitcoin | ckBTC (chain-key) | ~20 min deposit, instant trading |
| Ethereum | ckETH (chain-key) | ~5 min deposit, instant trading |
| ICP | Native | Instant |

### Planned Integrations
| Chain | Method | Status |
|-------|--------|--------|
| Solana | Bridge (TBD) | Research |
| Cosmos | IBC via bridge | Research |
| Polkadot | XCM adapter | Planned |

---

## Adding New Markets

New trading pairs can be proposed through the governance process:
1. Submit a market addition proposal via the Council
2. Community votes on inclusion criteria (liquidity, demand, risk)
3. If approved, pair is activated with initial parameters
4. Market makers are incentivized via LP rewards

See [LP & Agents](./LP_AND_AGENTS.md) for liquidity provision details.
