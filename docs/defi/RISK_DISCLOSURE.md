# ⚠️ Risk Disclosure

> Important risks, disclaimers, and user responsibilities when using PARALLAX Exchange.

---

## General Disclaimer

PARALLAX Exchange Clearinghouse is experimental decentralized finance (DeFi) software. By using this protocol, you acknowledge and accept the risks described below. **This is not financial advice.** You are solely responsible for your trading decisions and any resulting gains or losses.

---

## Categories of Risk

### 1. Smart Contract / Canister Risk

| Risk | Description | Severity |
|------|-------------|----------|
| Code bugs | Undiscovered vulnerabilities in Motoko canister code | High |
| Logic errors | Matching or settlement logic may behave unexpectedly in edge cases | Medium |
| Upgrade risk | Canister upgrades could introduce regressions | Medium |
| State migration | Data loss possible during major canister upgrades | Low-Medium |

**Mitigation**: All code is open-source. Community audits are planned. Start with small amounts.

---

### 2. Protocol & Infrastructure Risk

| Risk | Description | Severity |
|------|-------------|----------|
| ICP subnet outage | If the hosting subnet goes offline, trading halts | Low |
| Consensus failure | Theoretical >1/3 Byzantine node scenario | Very Low |
| Cycle exhaustion | If canister runs out of cycles, it freezes | Low |
| NNS governance | NNS decisions could affect underlying infrastructure | Low |

**Mitigation**: ICP has 99.9%+ uptime historically. Protocol maintains cycle reserves.

---

### 3. Bridge & Cross-Chain Risk

| Risk | Description | Severity |
|------|-------------|----------|
| ckBTC bridge failure | Threshold signature compromise or liveness failure | Low |
| ckETH bridge failure | Chain-key crypto vulnerability or Ethereum reorg | Low |
| Deposit delay | Bridge deposits may take longer than expected | Medium |
| Bridge upgrade | NNS-governed bridge changes could affect deposits | Low |

**Mitigation**: Use only officially supported bridges. Monitor bridge status.

---

### 4. Market & Trading Risk

| Risk | Description | Severity |
|------|-------------|----------|
| Price volatility | All traded assets can experience extreme price swings | High |
| Low liquidity | Some pairs may have thin order books, causing slippage | High |
| Impermanent loss | LP providers face IL risk in volatile markets | Medium |
| New token risk | AI tokens and artifacts may have no established value | High |
| Correlation risk | AI token categories may move together in downturns | Medium |

**Mitigation**: Use limit orders. Size positions appropriately. Diversify across pairs.

---

### 5. Custody & Access Risk

| Risk | Description | Severity |
|------|-------------|----------|
| Identity loss | Losing Internet Identity access means losing funds | Critical |
| Principal migration | No way to transfer between principals | High |
| No recovery | No "forgot password" — blockchain is irreversible | Critical |
| Frontend unavailability | If frontend goes down, direct canister calls still work | Low |

**Mitigation**: Secure your Internet Identity with multiple devices/recovery phrases. Understand that this is self-custody.

---

### 6. Regulatory Risk

| Risk | Description | Severity |
|------|-------------|----------|
| Jurisdictional | DeFi regulation varies by jurisdiction and is evolving | Medium |
| Token classification | Some tokens may be classified as securities in your jurisdiction | Medium |
| Reporting | You may have tax reporting obligations on trades | Medium |
| Sanctions | Users from sanctioned regions must not use the protocol | High |

**Mitigation**: Consult local legal counsel. Understand your jurisdiction's DeFi regulations. Maintain your own trading records for tax purposes.

---

### 7. Governance & Centralization Risk (Current Phase)

| Risk | Description | Severity |
|------|-------------|----------|
| Team control | Protocol team currently holds canister upgrade keys | Medium |
| Single team | Small team means single point of organizational failure | Medium |
| Roadmap changes | Plans (including SNS) may change based on circumstances | Low |
| Token distribution | Initial token distribution may concentrate governance power | Medium |

**Mitigation**: All code is public. Transition to SNS governance is planned. See [Roadmap](./ROADMAP.md).

---

## What PARALLAX Does NOT Guarantee

- ❌ Profit or returns on any trade or LP position
- ❌ Token price stability or appreciation
- ❌ Uninterrupted service (maintenance, subnet issues possible)
- ❌ Recovery of funds from lost Internet Identity access
- ❌ Protection from your own trading decisions
- ❌ Regulatory compliance in all jurisdictions
- ❌ Bug-free software (all software has risks)

---

## What PARALLAX DOES Provide

- ✅ Open-source, auditable canister code
- ✅ Deterministic, MEV-resistant order matching
- ✅ Zero gas fees for all users
- ✅ Sub-second settlement with cryptographic finality
- ✅ Central counterparty guarantee for matched trades
- ✅ Permissionless withdrawal at any time
- ✅ No KYC data collection (self-sovereign identity)

---

## User Responsibilities

By using PARALLAX Exchange, you agree that:

1. **You understand DeFi risks** — including total loss of deposited assets
2. **You are responsible for your identity** — securing your Internet Identity is your duty
3. **You comply with local laws** — including tax, securities, and sanctions regulations
4. **You trade at your own risk** — no party will compensate you for trading losses
5. **You have done your own research** — on any token or artifact you trade
6. **You understand this is experimental** — software in active development

---

## Maximum Loss

Your maximum possible loss is **100% of all assets deposited** into the PARALLAX Exchange canisters. Never deposit more than you can afford to lose entirely.

---

## Reporting Issues

If you discover a security vulnerability:
- **DO NOT** disclose publicly
- Open a private security advisory on [GitHub](https://github.com/ItsNotAILABS/PARALLAX-Exchange-Clearinghouse/security)
- Responsible disclosure is appreciated and may be rewarded

---

*DeFi is powerful but carries real risk. Understand before you trade.*
