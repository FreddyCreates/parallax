# TOKEN_PROTOCOL.md

## PARRALAX-AIHFTFUND Token Protocol

### Version 1.0

---

## 1. Purpose

This protocol governs the creation, management, and use of internal tokens within PARRALAX-AIHFTFUND. Tokens serve as programmable units of value, participation, and governance.

---

## 2. Token Types

| Token | Symbol | Purpose | Supply Model |
|-------|--------|---------|--------------|
| PARRALAX Fund Token | PFT | Fund participation and value tracking | Fixed cap |
| Compute Credit | PCC | Payment for compute/execution services | Minted on demand |
| Strategy Share | PSS | Ownership stake in specific strategies | Per-strategy cap |
| Governance Vote | PGV | Protocol governance voting | 1:1 with PFT |

---

## 3. Issuance Rules

### PFT (Fund Token)
- Max supply: Defined at fund creation
- Minting: Only via Treasury Protocol with founder approval
- Burning: On redemption or fund restructuring
- Transferable: Between approved participants

### PCC (Compute Credit)
- No max supply (inflationary by design)
- Minted: When compute resources are allocated
- Burned: When compute receipts are generated
- Non-transferable: Locked to issuing agent

### PSS (Strategy Share)
- Supply: Fixed per strategy at strategy creation
- Minted: When strategy is activated
- Burned: When strategy is retired
- Transferable: With governance approval

### PGV (Governance Vote)
- 1:1 mapping to PFT holdings
- Non-transferable independently
- Voting power: Linear with holdings
- Used for: Protocol changes, agent promotions, parameter updates

---

## 4. Token Operations

| Operation | Authorization Required | Receipt Generated |
|-----------|----------------------|-------------------|
| Mint | Treasury Protocol + Founder | Asset Receipt |
| Transfer | Sender + compliance check | Transfer Receipt |
| Burn | Holder or protocol trigger | Burn Receipt |
| Lock | Holder or governance | Lock Receipt |
| Unlock | Time expiry or governor | Unlock Receipt |

---

## 5. Compliance

- All token operations produce compute receipts
- KYC/AML checks for external transfers (when applicable)
- Holdings tracked in real-time in Asset Registry
- Quarterly token supply audit
- No token may represent external securities without compliance review

---

## 6. Technical Implementation

- Internal ledger: PostgreSQL with double-entry bookkeeping
- On-chain representation: Optional bridge to Ethereum ERC-20 or Solana SPL
- API: RESTful token operations with authentication
- Events: Real-time token events via WebSocket
