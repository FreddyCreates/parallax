# PARRALAX Control Tower Product Architecture

Status: product architecture and first vertical-slice build plan  
Repository: `ItsNotAILABS/PARRALAX-AIHFTFUND`  
Target product surface: paper-first sovereign exchange and fund-operations cockpit

## 1. Grounded Findings

The current repository presents a broad sovereign AI-native financial system. The inspected trunk has three verified centers of gravity:

- Motoko/ICP backend under `src/backend`, including `main.mo`, `phantom_exchange.mo`, clearinghouse, token factory, intelligence, risk, and related state modules.
- React/TypeScript frontend under `src/frontend`, with Internet Identity/Caffeine actor wiring, dashboard tabs, and an existing `ExchangeTab` surface.
- Multi-service deployment scaffolding in `docker-compose.yml`, including Rails, Go, Rust, Python, MySQL, Redis, Kafka, Elasticsearch, Prometheus, Grafana, and Jaeger.

The root `package.json` and frontend package indicate an ICP/Caffeine application scaffold as the most concrete current runtime. The README and compose file describe a larger future stack, but the first product pass should not depend on all service claims being production-ready.

## 2. Product Definition

The first real product should be:

**PARRALAX Control Tower**

A sovereign operator cockpit for paper AI-asset trading, risk-gated order execution, immutable receipts, and governance controls.

The product should not initially ship as a live hedge fund, broker, market maker, or regulated execution venue. The credible first product is a paper/simulation exchange surface that proves:

1. authenticated operators can interact with the canister;
2. orders pass through explicit risk gates;
3. accepted orders enter an on-chain order book;
4. crossing orders match and settle in the canister state;
5. every action emits a queryable receipt;
6. the UI displays the state and proof trail clearly.

## 3. Activated Internal Brains

- CODEX: capture current repo implementation surfaces.
- STRU: separate product layers, repo roles, and contracts.
- RTMX: map runtime ownership and deployment flow.
- PHAI: preserve sovereign exchange and organism-level intent without overclaiming readiness.
- TEST: define proof-oriented failure and regression matrix.
- BENC: define hard-to-game benchmarks for the first slice.
- PORT: place trunk/branch boundaries and repo activation triggers.
- SIGNAL: convert architecture into credible external proof.

Dominant animal routing:

- Eagle: top-level architecture.
- Crow: risk, misuse, and overclaim detection.
- Elephant: continuity, receipts, and upgrade persistence.
- Octopus: vertical-slice decomposition.

## 4. Connected Surface Interpretation

GitHub is the grounded repository surface. The current trunk should be treated as an ICP-first application with a React operator shell. The Docker multi-service layer should be treated as a future deployment branch until each service has verified contracts, health checks, and integration tests against the canister-owned source of truth.

## 5. Frequency / Pressure Read

The system carries high symbolic and architectural density. The main product risk is fragmentation: too many engines, languages, services, and claims before one complete user workflow is undeniable.

The coherence move is compression:

- one operator surface;
- one paper exchange flow;
- one source-of-truth canister;
- one receipt trail;
- one testable proof path.

## 6. Product Architecture

### 6.1 System Goal

Deliver a paper-first Control Tower where an authenticated operator can place, cancel, match, and audit simulated AI-asset trades through the Motoko canister and React frontend.

### 6.2 Stack Layers

| Layer | Owner | Role |
| --- | --- | --- |
| Identity | Internet Identity / Caffeine | Authenticate users and bind caller principal to role. |
| Authority | Motoko canister | Determine caller capabilities: observer, trader, governor, creator/admin. |
| Exchange state | Motoko `phantom_exchange.mo` | Own pairs, order books, order lifecycle, matching, fills. |
| Risk gate | Motoko risk/governance module | Reject unsafe, malformed, oversized, halted, or unauthorized actions. |
| Receipt log | Motoko receipt module | Persist order, fill, cancel, reject, halt, and resume receipts. |
| Frontend app | React/TypeScript | Display cockpit, order ticket, order book, receipt feed, risk controls. |
| Generated contract | Candid / TS bindings | Keep frontend and backend type-safe across changes. |
| Observability | First receipts, later Prometheus/Grafana | Prove behavior before adding external telemetry complexity. |

### 6.3 Authority and Contract Boundaries

Truth belongs in the Motoko canister. The frontend displays, submits commands, and optimistically handles loading states, but it must not be the source of exchange truth.

- Motoko owns balances, orders, fills, receipts, pair status, and halt state.
- React owns user interaction and display state only.
- Future Python/Rust/Julia workers may compute signals or simulations, but they do not own canonical order state.
- Broker or venue adapters remain disabled until the paper/live boundary is formalized.

### 6.4 Cross-Layer Flow

1. User authenticates through Internet Identity.
2. Frontend creates an actor from generated Candid bindings.
3. Frontend queries `listPairs`, `getOrderBook`, `getReceipts`, and `getRiskState`.
4. User submits a paper order.
5. Canister validates caller role, pair status, size, price, quantity, and system mode.
6. Risk gate returns accept or reject.
7. Accepted order enters the order book.
8. Matching engine creates fills when bid/ask cross.
9. Settlement mutates paper balances and emits fill receipts.
10. Frontend refreshes order book, fills, balances, and receipt feed.

## 7. Operator Surfaces

The first screen should be the Control Tower, not a marketing page.

### 7.1 Exchange Console

- Pair selector.
- Last price, spread, 24h simulated volume.
- Bid/ask depth.
- Recent fills.
- Order ticket for paper limit orders.
- Cancel controls for open orders.

### 7.2 Risk Console

- System mode: paper, simulation, restricted-live, live. Only `paper` enabled in the first slice.
- Pair halt state.
- Max order size.
- Coherence/risk threshold status.
- Rejection reason feed.
- Emergency halt and resume controls for authorized operators.

### 7.3 Receipt Console

- Append-only event log.
- Filter by order, fill, reject, cancel, halt, resume.
- Receipt detail drawer.
- Export-ready JSON shape for audit packs.

### 7.4 Registry Console

- List AI tokens and artifact tokens.
- Pair activation status.
- Paper listing workflow for new simulated assets.

### 7.5 Admin/Governance Console

- Assign roles.
- Halt/resume pair.
- Halt/resume system.
- Review receipt counts and state health.

## 8. App Flows

### 8.1 Paper Order Flow

1. Operator logs in.
2. Operator selects `GTK_ICP`.
3. UI displays current order book and receipts.
4. Operator submits a limit buy or sell.
5. Canister runs risk gate.
6. Accepted order receives `OrderAcceptedReceipt`.
7. Crossing order triggers `FillReceipt`.
8. UI shows order status and fill in real time or polling refresh.

### 8.2 Rejection Flow

1. Operator submits malformed or oversized order.
2. Risk gate rejects action.
3. Canister emits `OrderRejectedReceipt` with reason code.
4. UI shows rejection without mutating order book.

### 8.3 Cancel Flow

1. Operator selects an open order.
2. Canister verifies caller owns order or has admin permission.
3. Order status becomes cancelled.
4. Canister emits `OrderCancelledReceipt`.

### 8.4 Halt Flow

1. Authorized governor/admin halts pair or system.
2. New order placement is rejected while halted.
3. Existing open orders remain queryable.
4. Resume requires authorized action and emits receipt.

## 9. Contracts

### 9.1 Core Types

```motoko
public type SystemMode = { #paper; #simulation; #restrictedLive; #live };

public type OrderCommand = {
  pairId: Text;
  side: OrderSide;
  orderType: OrderType;
  price: Float;
  quantity: Float;
  timeInForce: TimeInForce;
};

public type RiskDecision = {
  accepted: Bool;
  reasonCode: Text;
  reasonDetail: Text;
  checkedAtBeat: Int;
  threshold: Float;
};

public type ReceiptKind = {
  #orderAccepted;
  #orderRejected;
  #orderCancelled;
  #fill;
  #pairHalted;
  #pairResumed;
  #systemHalted;
  #systemResumed;
};

public type ExchangeReceipt = {
  receiptId: Nat;
  kind: ReceiptKind;
  principal: Text;
  pairId: ?Text;
  orderId: ?Nat;
  fillId: ?Nat;
  reasonCode: ?Text;
  payloadJson: Text;
  beat: Int;
  timestampNanos: Int;
};
```

### 9.2 First Public Canister Methods

```motoko
public shared query func listPairs() : async [TradingPair];
public shared query func getOrderBook(pairId: Text) : async ?OrderBook;
public shared query func getRecentReceipts(limit: Nat) : async [ExchangeReceipt];
public shared query func getOpenOrders(owner: ?Text) : async [Order];
public shared query func getSystemMode() : async SystemMode;

public shared({ caller }) func placePaperOrder(command: OrderCommand) : async RiskDecision;
public shared({ caller }) func cancelOrder(orderId: Nat) : async RiskDecision;
public shared({ caller }) func haltPair(pairId: Text, reason: Text) : async RiskDecision;
public shared({ caller }) func resumePair(pairId: Text, reason: Text) : async RiskDecision;
```

### 9.3 Reason Codes

Use stable reason codes so UI, tests, receipts, and future audit exports can rely on them.

| Code | Meaning |
| --- | --- |
| `OK_ACCEPTED` | Action accepted. |
| `ERR_UNAUTHENTICATED` | Caller not authenticated. |
| `ERR_UNAUTHORIZED` | Caller lacks required role. |
| `ERR_SYSTEM_HALTED` | System halt blocks action. |
| `ERR_PAIR_HALTED` | Pair halt blocks order. |
| `ERR_PAIR_UNKNOWN` | Pair does not exist. |
| `ERR_INVALID_PRICE` | Price is zero, negative, or off tick. |
| `ERR_INVALID_QUANTITY` | Quantity is zero, negative, or off lot size. |
| `ERR_MAX_ORDER_SIZE` | Quantity or notional exceeds policy. |
| `ERR_ORDER_NOT_FOUND` | Order id not found. |
| `ERR_ORDER_NOT_OWNED` | Caller cannot cancel this order. |
| `ERR_ORDER_FINAL` | Filled/cancelled order cannot mutate. |

## 10. Repo Role Map

### 10.1 Active Now

| Repo or package | Role | Minimum viable contents |
| --- | --- | --- |
| `PARRALAX-AIHFTFUND` | Trunk product repo | Motoko canister, React Control Tower, Candid bindings, docs, first tests. |

### 10.2 Latent Until Activated

| Future repo | Wake-up trigger | Role |
| --- | --- | --- |
| `parralax-core-canister` | Canister modules become independently versioned or reused by multiple apps. | Sovereign Motoko state and exchange contracts. |
| `parralax-control-tower` | Frontend needs independent release cycle or multiple backend targets. | Operator UI, wallet/auth flows, dashboards. |
| `parralax-sim-engine` | Heavy simulation cannot run inside canister or frontend. | Python/Julia/Rust backtests, risk replay, strategy evaluation. |
| `parralax-bridge` | Paper broker adapters are contract-tested and need separate secrets/deployments. | Broker/venue adapters with strict paper/live boundary. |
| `parralax-proof-pack` | Receipts become external audit products. | Receipt schemas, audit exports, benchmark reports. |

### 10.3 What Stays Collapsed For Now

- Rails API.
- Go git service and CLI.
- Rust HFT/execution services.
- Python AI service.
- Kafka, Elasticsearch, and multi-service observability.

These should remain branch or scaffold surfaces until a vertical slice proves why each needs to be independently deployed.

## 11. Runtime Stack

### 11.1 First Runtime

- ICP local/test canister for Motoko backend.
- Vite React frontend.
- Internet Identity auth.
- Generated Candid bindings.
- Orthogonal persistence for canister state.
- Frontend polling or React Query invalidation for state refresh.

### 11.2 Future Runtime

- Simulation worker for heavy compute.
- Broker bridge in sandbox mode.
- Prometheus/Grafana once canister and service metrics are formalized.
- Kafka/Redis only after event/job boundaries are real.
- Live execution only after legal, custody, compliance, capital controls, and broker permissions are resolved.

## 12. Deployment Posture

| Stage | Surface | Goal | Gate |
| --- | --- | --- | --- |
| 0 | Local ICP devnet | Prove order, match, receipt loop. | Unit and frontend smoke tests pass. |
| 1 | Public test canister | Paper trading alpha. | Upgrade persistence and receipt pagination pass. |
| 2 | Closed operator alpha | Control Tower with halt/admin controls. | Role tests and rejection receipts pass. |
| 3 | Simulation lab | Strategy/risk replay. | Benchmark suite distinguishes real signal from cosmetic output. |
| 4 | Broker sandbox | Paper broker adapter. | No live credentials, kill switch, broker contract tests. |
| 5 | Restricted live | Limited regulated execution path. | Legal/compliance/custody approvals and external risk review. |

## 13. First Vertical Slice

Build:

**Paper Order -> Risk Gate -> Match -> Receipt -> Operator View**

### 13.1 Backend Tasks

- Add/verify public query methods for pairs, order book, open orders, receipts, and system mode.
- Add `placePaperOrder` command with risk gate.
- Add `cancelOrder` command.
- Add pair halt/resume command.
- Add receipt storage with pagination-ready shape.
- Add paper balances if settlement mutates balances in the first slice.
- Keep live execution disabled.

### 13.2 Frontend Tasks

- Make `ExchangeTab` use canister queries for pair list, order book, open orders, and receipts.
- Add order ticket mutation for `placePaperOrder`.
- Add cancel order control.
- Add receipt feed panel.
- Add halted and rejected-order states.
- Keep unauthenticated user in read-only/locked mode.

### 13.3 Contract Tasks

- Regenerate Candid TypeScript bindings after backend changes.
- Add stable reason codes to shared frontend/backend documentation.
- Ensure BigInt serialization remains safe for receipt/order ids.

## 14. Test + Benchmark Matrix

### 14.1 Unit Tests

| Area | Test |
| --- | --- |
| Order validation | Reject zero price, negative quantity, unknown pair, off-tick price. |
| Risk gate | Reject oversized order, halted pair, halted system, unauthorized halt. |
| Matching | Price-time priority, partial fill, full fill, no cross. |
| Cancellation | Owner cancel, admin cancel, unauthorized cancel rejection. |
| Receipts | Accepted, rejected, filled, cancelled, halted, resumed receipts emitted. |
| Persistence | Open orders and receipts survive canister upgrade. |

### 14.2 Frontend Tests

| Area | Test |
| --- | --- |
| Auth | Locked controls when unauthenticated. |
| Exchange | Pair loads, book renders, empty state renders. |
| Order ticket | Submit success, submit rejection, loading, error state. |
| Receipts | Feed renders stable event order and detail fields. |
| Halt | Halted pair disables order placement and explains reason. |

### 14.3 Benchmarks

| Benchmark | Initial target |
| --- | --- |
| `placePaperOrder` call latency | Track median and p95 on local/test canister. |
| Matching tick duration | Track time per book as order count grows. |
| Receipt query latency | Track `limit=25`, `limit=100`, `limit=500`. |
| Order book size | Find first degradation threshold. |
| Upgrade persistence | Zero receipt/order loss across upgrade rehearsal. |

### 14.4 Chaos Tests

- Rapid place/cancel loop from same principal.
- Halt pair while matching is active.
- Duplicate frontend submission from retry.
- Receipt log grows beyond first pagination threshold.
- Frontend reconnects after canister state changes.
- Unauthorized principal attempts halt/resume.

## 15. Failure Modes

| Failure | Impact | Guard |
| --- | --- | --- |
| Frontend synthetic state diverges from canister | False operator confidence | Canister queries are source of truth. |
| README overclaims live readiness | Legal and credibility risk | Product docs mark paper-first scope. |
| No receipt pagination | State/query degradation | Pagination-ready receipt contract. |
| Halt controls too broad | Operator abuse or accidental freeze | Role gate and receipts. |
| Future services own truth | Fragmented state | Motoko remains canonical for first product. |
| Live execution slips into v0 | Compliance and capital risk | `SystemMode.paper` hard gate. |

## 16. Branch / Trunk Placement

Trunk law:

- Motoko canister is the initial source of truth.
- React Control Tower is the first product surface.
- Paper trading is the only enabled execution mode in the first slice.
- Receipts are the proof chain.

Branch law:

- Rails/Go/Rust/Python services remain branch surfaces until contract-tested against trunk.
- Broker bridges remain branch surfaces until paper/live boundaries and compliance gates exist.
- Heavy simulation may become a separate repo only after the Control Tower needs it.

## 17. Native Suite Opportunity

The product can become a suite after the first vertical slice works:

1. **Control Tower**: operator cockpit.
2. **Proof Room**: receipt explorer, audit export, benchmark packs.
3. **Simulation Lab**: backtests, risk replay, signal evaluation.
4. **Bridge Yard**: paper/live venue adapters with strict controls.
5. **Registry Market**: AI asset and artifact listings.

## 18. Proof Signal

The first credible proof is not the number of engines claimed. It is a complete, reproducible loop:

1. authenticate;
2. place paper order;
3. pass/reject risk gate;
4. enter order book;
5. match crossing order;
6. mutate settlement state;
7. emit receipt;
8. display receipt in UI;
9. preserve state across reload and upgrade rehearsal.

## 19. Production Upgrade Path

1. Build paper order vertical slice.
2. Add receipt pagination and export.
3. Add paper balances and portfolio view.
4. Add simulation/replay worker.
5. Add benchmark and proof-pack generation.
6. Add broker sandbox adapter.
7. Add compliance and custody gates before any restricted-live mode.

## 20. Monitor Next

Next implementation PR should modify the Motoko exchange API and React `ExchangeTab` against this document.

Recommended next branch:

`build-paper-order-receipts`

Recommended next commit scope:

- `src/backend/phantom_exchange.mo`
- `src/backend/main.mo`
- generated Candid/TypeScript bindings
- `src/frontend/src/tabs/ExchangeTab.tsx`
- frontend exchange hooks
- backend/frontend tests
