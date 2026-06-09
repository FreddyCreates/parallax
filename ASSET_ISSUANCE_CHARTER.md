# ASSET_ISSUANCE_CHARTER.md

## PARRALAX-AIHFTFUND Asset Issuance Charter

### Version 1.0

---

## 1. Purpose

This charter governs the creation, issuance, and management of all digital assets within the PARRALAX-AIHFTFUND ecosystem — including internal tokens, NFTs, governance tokens, and programmable ownership instruments.

---

## 2. Asset Classes

| Asset Type | Purpose | Governance |
|-----------|---------|-----------|
| Internal Token | Fund participation, compute credits | Treasury Protocol |
| NFT | Strategy ownership, performance records | NFT Protocol |
| Governance Token | Voting, protocol changes | Governance Charter |
| Compute Receipt | Proof of execution | Compute Receipt Protocol |
| Performance Bond | Agent accountability | Agent Authority Charter |

---

## 3. Issuance Requirements

Every asset issuance MUST include:

1. **Issuance Receipt** — Cryptographic proof of creation with timestamp
2. **Purpose Declaration** — Clear statement of asset's role in the system
3. **Supply Parameters** — Max supply, minting rules, burn conditions
4. **Governance Record** — Who authorized issuance and under what protocol
5. **Audit Trail** — Immutable record of all transfers and modifications

---

## 4. Issuance Authority

- **Level 0 (Founder)** — Can issue any asset type
- **Level 1 (Governor Agent)** — Can issue compute receipts and performance records
- **Level 2 (Treasury Protocol)** — Can mint tokens within pre-approved parameters
- **No agent may self-issue assets**

---

## 5. Asset Lifecycle

```
DRAFT → PROPOSED → APPROVED → MINTED → ACTIVE → [BURNED | RETIRED]
```

- Draft: Asset specification created
- Proposed: Submitted for governance approval
- Approved: Authorization granted
- Minted: Asset created on-chain or in registry
- Active: In circulation / use
- Burned/Retired: Permanently removed from circulation

---

## 6. Controls

- All issuance logged in Asset Registry
- Supply caps enforced at protocol level
- Unauthorized minting triggers system alert
- Monthly audit of outstanding assets vs. authorized supply
