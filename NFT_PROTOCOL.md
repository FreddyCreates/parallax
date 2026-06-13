# NFT_PROTOCOL.md

## PARRALAX-AIHFTFUND NFT Protocol

### Version 1.0

---

## 1. Purpose

NFTs within PARRALAX-AIHFTFUND represent unique, non-fungible digital assets tied to system operations — including strategy performance records, agent certifications, governance milestones, and execution achievements.

---

## 2. NFT Categories

| Category | Description | Minting Trigger |
|----------|-------------|----------------|
| Strategy Record | Performance history of a trading strategy | Strategy retirement or milestone |
| Agent Certificate | Proof of agent promotion/achievement | Agent level change |
| Execution Milestone | Notable execution achievements | Threshold crossing |
| Governance Record | Protocol change documentation | Governance vote completion |
| Audit Proof | Immutable audit snapshot | Scheduled audit cycle |

---

## 3. NFT Structure

```json
{
  "token_id": "uuid-v4",
  "category": "strategy_record|agent_certificate|...",
  "name": "Human-readable name",
  "description": "What this NFT represents",
  "metadata": {
    "created_at": "ISO-8601",
    "creator_agent": "agent-uuid",
    "domain": "trading|governance|audit",
    "data_hash": "hash of associated data",
    "version": "1.0"
  },
  "attributes": [],
  "immutable": true,
  "transferable": false
}
```

---

## 4. Minting Rules

- Only Level 0 (Founder) and Level 1 (Governor) can mint NFTs
- Every mint produces an Asset Receipt
- NFT data hash must reference verifiable source data
- No NFT may be minted without associated compute receipt chain

---

## 5. Use Cases

### Strategy Performance NFT
- Minted when a strategy completes a defined period
- Contains: Total return, max drawdown, Sharpe ratio, trade count
- Serves as: Immutable performance record for audit and attribution

### Agent Certificate NFT
- Minted on agent promotion
- Contains: Promotion date, previous level, new level, performance metrics
- Serves as: Proof of agent capability and authorization history

### Governance Record NFT
- Minted when protocol changes are ratified
- Contains: Change description, vote results, effective date
- Serves as: Immutable governance history

---

## 6. Storage

- Metadata: Internal registry (PostgreSQL)
- On-chain: Optional anchoring to Ethereum ERC-721 or Solana Metaplex
- IPFS: Large metadata payloads stored off-chain with hash reference
- Retention: Permanent (NFTs are never deleted)
