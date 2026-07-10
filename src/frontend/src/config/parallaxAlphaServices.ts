export type ParallaxServicePlane =
  | 'user_surface'
  | 'execution'
  | 'ledger'
  | 'proof'
  | 'governance'
  | 'research'
  | 'ops';

export type ParallaxAlphaStatus = 'alpha_required' | 'alpha_optional' | 'planned';

export type ParallaxAlphaService = {
  id: string;
  name: string;
  plane: ParallaxServicePlane;
  status: ParallaxAlphaStatus;
  owner: string;
  purpose: string;
  alphaCapabilities: string[];
  contracts: string[];
  dependencies: string[];
  exposes: string[];
  mustNotDo: string[];
};

export type ParallaxAlphaGate =
  | 'no_live_money_movement'
  | 'no_live_broker_routing'
  | 'all_commands_pass_risk_policy_gate'
  | 'all_state_transitions_emit_receipts'
  | 'operator_halt_available'
  | 'testnet_and_live_modes_separated'
  | 'public_claims_match_evidence'
  | 'receipt_export_available'
  | 'service_health_visible';

export const PARALLAX_ALPHA_GATES: ParallaxAlphaGate[] = [
  'no_live_money_movement',
  'no_live_broker_routing',
  'all_commands_pass_risk_policy_gate',
  'all_state_transitions_emit_receipts',
  'operator_halt_available',
  'testnet_and_live_modes_separated',
  'public_claims_match_evidence',
  'receipt_export_available',
  'service_health_visible',
];

export const PARALLAX_ALPHA_SERVICES: ParallaxAlphaService[] = [
  {
    id: 'identity-authority',
    name: 'Identity Authority',
    plane: 'user_surface',
    status: 'alpha_required',
    owner: 'core',
    purpose: 'Authenticate users and bind principals, roles, and operator permissions.',
    alphaCapabilities: ['internet_identity_login', 'role_lookup', 'session_status'],
    contracts: ['IdentitySession', 'RoleGrant', 'OperatorProfile'],
    dependencies: [],
    exposes: ['/auth/session', '/auth/roles'],
    mustNotDo: ['custody_private_keys', 'grant_live_execution_by_default'],
  },
  {
    id: 'wallet-service',
    name: 'Wallet Service',
    plane: 'ledger',
    status: 'alpha_required',
    owner: 'wallet',
    purpose: 'Display paper/testnet balances and prepare transfer commands.',
    alphaCapabilities: ['paper_balances', 'testnet_accounts', 'transfer_intent_preview'],
    contracts: ['WalletAccount', 'BalanceSnapshot', 'WalletCommand'],
    dependencies: ['identity-authority', 'receipt-ledger'],
    exposes: ['/wallet/accounts', '/wallet/balances', '/wallet/commands'],
    mustNotDo: ['move_real_user_money', 'hide_network_mode'],
  },
  {
    id: 'pay-service',
    name: 'Pay Service',
    plane: 'ledger',
    status: 'alpha_required',
    owner: 'payments',
    purpose: 'Create paper/testnet transfers, payment requests, invoices, and remittance receipts.',
    alphaCapabilities: ['paper_transfer', 'payment_request', 'invoice_stub', 'transfer_receipt'],
    contracts: ['TransferCommand', 'PaymentRequest', 'InvoiceDraft', 'TransferReceipt'],
    dependencies: ['wallet-service', 'risk-policy-gate', 'receipt-ledger'],
    exposes: ['/pay/transfer', '/pay/request', '/pay/invoice'],
    mustNotDo: ['represent_bank_account', 'represent_money_transmitter_status'],
  },
  {
    id: 'trading-service',
    name: 'Trading Service',
    plane: 'execution',
    status: 'alpha_required',
    owner: 'trade',
    purpose: 'Accept paper/testnet order commands and route them through the risk gate.',
    alphaCapabilities: ['paper_order_entry', 'cancel_order', 'order_status', 'operator_review_required_for_ai_orders'],
    contracts: ['OrderCommand', 'CancelCommand', 'OrderState', 'ExecutionIntent'],
    dependencies: ['identity-authority', 'market-data-service', 'risk-policy-gate', 'matching-engine'],
    exposes: ['/trade/orders', '/trade/orders/{id}', '/trade/cancel'],
    mustNotDo: ['route_live_orders', 'bypass_risk_gate'],
  },
  {
    id: 'risk-policy-gate',
    name: 'Risk Policy Gate',
    plane: 'governance',
    status: 'alpha_required',
    owner: 'risk',
    purpose: 'Evaluate every order, transfer, AI signal, and operator action before execution.',
    alphaCapabilities: ['mode_check', 'role_check', 'halt_check', 'size_limit', 'reason_codes'],
    contracts: ['RiskDecision', 'PolicyRule', 'SystemMode', 'HaltState'],
    dependencies: ['identity-authority', 'governance-service'],
    exposes: ['/risk/evaluate', '/risk/policies', '/risk/reasons'],
    mustNotDo: ['silently_auto_approve', 'ignore_halt_state'],
  },
  {
    id: 'matching-engine',
    name: 'Matching Engine',
    plane: 'execution',
    status: 'alpha_required',
    owner: 'clearinghouse',
    purpose: 'Maintain paper order books and produce deterministic fill records.',
    alphaCapabilities: ['price_time_priority', 'partial_fill', 'full_fill', 'cancel_open_order'],
    contracts: ['OrderBook', 'FillReceipt', 'MatchResult', 'PriceTimePriority'],
    dependencies: ['risk-policy-gate', 'receipt-ledger'],
    exposes: ['/match/book', '/match/fills', '/match/tick'],
    mustNotDo: ['front_run', 'alter_fills_after_receipt'],
  },
  {
    id: 'clearinghouse-service',
    name: 'Clearinghouse Service',
    plane: 'ledger',
    status: 'alpha_required',
    owner: 'clearinghouse',
    purpose: 'Turn fills and transfers into ledger updates and settlement receipts.',
    alphaCapabilities: ['paper_settlement', 'netting_preview', 'balance_delta', 'settlement_receipt'],
    contracts: ['SettlementInstruction', 'SettlementReceipt', 'LedgerDelta', 'NettingBatch'],
    dependencies: ['matching-engine', 'wallet-service', 'receipt-ledger'],
    exposes: ['/clearing/settle', '/clearing/batches', '/clearing/receipts'],
    mustNotDo: ['guarantee_live_finality', 'settle_without_receipt'],
  },
  {
    id: 'receipt-ledger',
    name: 'Receipt Ledger',
    plane: 'proof',
    status: 'alpha_required',
    owner: 'proof',
    purpose: 'Append, query, paginate, and export receipts for every meaningful state transition.',
    alphaCapabilities: ['append_receipt', 'query_receipts', 'paginate_receipts', 'export_json'],
    contracts: ['ReceiptEnvelope', 'ReceiptCursor', 'MerkleDraft', 'AuditExport'],
    dependencies: [],
    exposes: ['/receipts', '/receipts/export', '/receipts/{id}'],
    mustNotDo: ['overwrite_receipts', 'omit_actor_or_mode'],
  },
  {
    id: 'ai-signal-service',
    name: 'AI Signal Service',
    plane: 'execution',
    status: 'alpha_required',
    owner: 'ai',
    purpose: 'Generate strategy signals that are explainable, logged, and blocked from direct live execution.',
    alphaCapabilities: ['signal_card', 'confidence_score', 'reason_codes', 'operator_approval_flow'],
    contracts: ['SignalCard', 'SignalSource', 'ModelConfidence', 'OperatorApproval'],
    dependencies: ['market-data-service', 'risk-policy-gate', 'receipt-ledger'],
    exposes: ['/signals', '/signals/{id}/approve-paper'],
    mustNotDo: ['execute_live_without_operator', 'hide_model_uncertainty'],
  },
  {
    id: 'research-mint-service',
    name: 'Research Mint Service',
    plane: 'research',
    status: 'alpha_required',
    owner: 'research',
    purpose: 'Register papers, charters, benchmark reports, and artifacts as receipt-backed research objects.',
    alphaCapabilities: ['artifact_metadata', 'charter_registry', 'benchmark_record', 'research_receipt'],
    contracts: ['ResearchArtifact', 'ProtocolCharter', 'BenchmarkRecord', 'ResearchArtifactReceipt'],
    dependencies: ['receipt-ledger'],
    exposes: ['/research/artifacts', '/research/charters', '/research/benchmarks'],
    mustNotDo: ['claim_peer_review_without_evidence', 'mint_live_security_token'],
  },
  {
    id: 'governance-service',
    name: 'Governance Service',
    plane: 'governance',
    status: 'alpha_required',
    owner: 'governance',
    purpose: 'Manage policies, role-gated actions, emergency halt, release gates, and upgrade posture.',
    alphaCapabilities: ['halt_pair', 'resume_pair', 'system_halt', 'release_gate'],
    contracts: ['GovernancePolicy', 'OperatorActionReceipt', 'ReleaseGate', 'UpgradePlan'],
    dependencies: ['identity-authority', 'receipt-ledger'],
    exposes: ['/governance/halt', '/governance/resume', '/governance/releases'],
    mustNotDo: ['anonymous_admin_action', 'unlogged_policy_change'],
  },
  {
    id: 'ops-control-plane',
    name: 'Ops Control Plane',
    plane: 'ops',
    status: 'alpha_required',
    owner: 'ops',
    purpose: 'Expose health, readiness, deployment posture, test receipts, and service status to operators.',
    alphaCapabilities: ['service_health', 'readiness_gate', 'test_receipt', 'deployment_manifest'],
    contracts: ['ServiceHealth', 'ReadinessGate', 'DeploymentManifest', 'TestReceipt'],
    dependencies: ['receipt-ledger', 'governance-service'],
    exposes: ['/ops/health', '/ops/readiness', '/ops/deployments'],
    mustNotDo: ['claim_prod_ready_without_checks'],
  },
];

export const getAlphaServiceById = (serviceId: string) =>
  PARALLAX_ALPHA_SERVICES.find((service) => service.id === serviceId);

export const getAlphaServicesByPlane = (plane: ParallaxServicePlane) =>
  PARALLAX_ALPHA_SERVICES.filter((service) => service.plane === plane);

export const getRequiredAlphaServices = () =>
  PARALLAX_ALPHA_SERVICES.filter((service) => service.status === 'alpha_required');

export const getAlphaReadinessSummary = () => {
  const required = getRequiredAlphaServices();
  const optional = PARALLAX_ALPHA_SERVICES.filter((service) => service.status === 'alpha_optional');
  return {
    mode: 'alpha' as const,
    publicPosture: 'paper_testnet_first' as const,
    serviceCount: PARALLAX_ALPHA_SERVICES.length,
    requiredCount: required.length,
    optionalCount: optional.length,
    gateCount: PARALLAX_ALPHA_GATES.length,
  };
};
