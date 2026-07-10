export type ChainId = "icp" | `eip155:${number}` | `external:${string}`;

export type CustodyMode =
  | "non_custodial"
  | "canister_vault"
  | "adapter_escrow"
  | "observed_only";

export type SettlementState =
  | "draft"
  | "authorized"
  | "submitted"
  | "observed"
  | "finalizing"
  | "settled"
  | "rejected"
  | "quarantined"
  | "reversed";

export interface LedgerIntent {
  traceId: string;
  intentId: string;
  principal: string;
  chainId: ChainId;
  assetId: string;
  amount: string;
  from: string;
  to: string;
  idempotencyKey: string;
  stateSnapshotHash: string;
  expiresAt: string;
}

export interface AdapterCapability {
  adapterId: string;
  chainId: ChainId;
  supportedAssets: string[];
  custodyModes: CustodyMode[];
  finalityRule: string;
  canSubmit: boolean;
  canObserve: boolean;
}

export interface AdapterProvenance {
  adapterId: string;
  observedAt: string;
  proofType: string;
  proofHash?: string;
  externalTxHash?: string;
}

export interface AdapterResult {
  traceId: string;
  intentId: string;
  state: SettlementState;
  idempotencyKey: string;
  provenance: AdapterProvenance;
  errorCode?: string;
  errorMessage?: string;
}

export interface ChainAdapter {
  capability(): AdapterCapability;
  validateAddress(address: string): Promise<boolean>;
  estimateFee(intent: LedgerIntent): Promise<string>;
  prepareTransfer(intent: LedgerIntent): Promise<LedgerIntent>;
  submitTransaction(intent: LedgerIntent): Promise<AdapterResult>;
  observeTransaction(intent: LedgerIntent): Promise<AdapterResult>;
}

export function assertFreshIntent(intent: LedgerIntent, now = new Date()): void {
  if (new Date(intent.expiresAt).getTime() <= now.getTime()) {
    throw new Error("ledger intent expired");
  }
  if (intent.idempotencyKey.length < 16) {
    throw new Error("idempotency key too short");
  }
  if (intent.stateSnapshotHash.length < 16) {
    throw new Error("state snapshot hash too short");
  }
}
