export type PlatformPlaneId =
  | "wallet_identity"
  | "trading_exchange"
  | "clearinghouse_ledger"
  | "ai_execution"
  | "research_ip"
  | "defense_compliance"
  | "proof_release";

export type PlatformAuthority =
  | "motoko_canister"
  | "phantom_exchange"
  | "phantom_clearinghouse"
  | "risk_gated_adapter"
  | "token_factory_and_artifact_registry"
  | "policy_and_admin_gates"
  | "release_ledger";

export interface PlatformPlane {
  id: PlatformPlaneId;
  label: string;
  authority: PlatformAuthority;
  sourceRepository?: string;
  firstSlice: string;
  route: string;
  proofRequired: boolean;
}

export const PARALLAX_PLATFORM_PLANES: PlatformPlane[] = [
  {
    id: "wallet_identity",
    label: "Wallet",
    authority: "motoko_canister",
    firstSlice: "internet_identity_session_and_balance_view",
    route: "/wallet",
    proofRequired: true,
  },
  {
    id: "trading_exchange",
    label: "Trade",
    authority: "phantom_exchange",
    firstSlice: "paper_order_to_fill_receipt",
    route: "/trade",
    proofRequired: true,
  },
  {
    id: "clearinghouse_ledger",
    label: "Clearinghouse",
    authority: "phantom_clearinghouse",
    firstSlice: "internal_transfer_to_audit_receipt",
    route: "/clearinghouse",
    proofRequired: true,
  },
  {
    id: "ai_execution",
    label: "AI Execution",
    authority: "risk_gated_adapter",
    sourceRepository: "ItsNotAILABS/PARRALAX-AIHFTFUND",
    firstSlice: "read_only_signal_to_protected_order_intent",
    route: "/ai-execution",
    proofRequired: true,
  },
  {
    id: "research_ip",
    label: "Research Mint",
    authority: "token_factory_and_artifact_registry",
    sourceRepository: "ItsNotAILABS/cloudcolony",
    firstSlice: "research_packet_to_artifact_receipt",
    route: "/research-mint",
    proofRequired: true,
  },
  {
    id: "defense_compliance",
    label: "Compliance",
    authority: "policy_and_admin_gates",
    sourceRepository: "ItsNotAILABS/Chimeria",
    firstSlice: "adapter_pause_and_quarantine_controls",
    route: "/compliance",
    proofRequired: true,
  },
  {
    id: "proof_release",
    label: "Proof",
    authority: "release_ledger",
    sourceRepository: "ItsNotAILABS/PRODUCTION-",
    firstSlice: "claim_to_evidence_record",
    route: "/proof",
    proofRequired: true,
  },
];

export const REQUIRED_PROOF_FIELDS = [
  "trace_id",
  "intent_id",
  "idempotency_key",
  "state_snapshot_hash",
  "custody_mode",
  "risk_tier",
  "receipt_id",
] as const;
