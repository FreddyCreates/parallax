# COMPUTE_RECEIPT_PROTOCOL.md

## PARRALAX-AIHFTFUND Compute Receipt Protocol

### Version 1.0

---

## 1. Purpose

Compute receipts are the proof layer of PARRALAX-AIHFTFUND. Every significant system action generates an immutable receipt that proves the action occurred, who authorized it, and what the outcome was.

---

## 2. Receipt Types

| Receipt Type | Triggered By | Contains |
|-------------|-------------|----------|
| Execution Receipt | Order fill | Order ID, fill price, venue, latency, hash |
| Signal Receipt | Signal generation | Agent ID, strategy, symbol, strength, timestamp |
| Risk Receipt | Risk gate evaluation | Order ID, gate results, pass/fail, reason |
| Governance Receipt | Authority change | Agent ID, old role, new role, authorizer |
| Asset Receipt | Token/NFT issuance | Asset ID, type, supply, authorizer |
| Settlement Receipt | Trade settlement | Fill ID, reconciliation status, discrepancies |

---

## 3. Receipt Structure

```json
{
  "receipt_id": "uuid-v4",
  "type": "execution|signal|risk|governance|asset|settlement",
  "timestamp": "ISO-8601",
  "agent_id": "originating-agent-uuid",
  "action": "description of action",
  "input_hash": "hash of input parameters",
  "output_hash": "hash of result",
  "latency_us": 142,
  "status": "success|failure|partial",
  "metadata": {},
  "signature": "agent-signed-hash"
}
```

---

## 4. Integrity

- Receipt hash computed from: receipt_id + timestamp + agent_id + action + input_hash + output_hash
- Receipts are append-only — never modified or deleted
- Receipt chain: each receipt references the previous receipt hash (chain integrity)
- Periodic Merkle root published for batch verification

---

## 5. Storage

- Primary: PostgreSQL with immutable append-only table
- Secondary: On-chain anchoring (periodic Merkle roots to Ethereum/Solana)
- Archive: S3-compatible cold storage for receipts > 90 days
- Retention: Indefinite (receipts are never deleted)

---

## 6. Verification

Any receipt can be independently verified by:
1. Recomputing the hash from stored fields
2. Checking the chain reference to previous receipt
3. Verifying agent signature against registered public key
4. Confirming timestamp ordering

---

## 7. Audit Access

- Founder: Full access to all receipts
- Governor agents: Access to receipts in their domain
- External auditors: Read-only access via API with time-bounded tokens
- Export: CSV, JSON, or Parquet format for compliance reporting
