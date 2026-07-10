export type NetworkMode = 'paper' | 'testnet' | 'restricted_live' | 'live';

export type AiWalletStatus = 'active' | 'paused' | 'halted' | 'retired';

export type AiWalletCommandKind =
  | 'transfer'
  | 'order'
  | 'research_mint'
  | 'approve_signal'
  | 'cancel_order'
  | 'operator_note';

export type AiWalletDecision = 'approved' | 'rejected' | 'requires_human_approval';

export type AiWalletReasonCode =
  | 'WALLET_HALTED'
  | 'WALLET_PAUSED'
  | 'MODE_NOT_ALLOWED'
  | 'LIVE_MODE_BLOCKED'
  | 'COMMAND_KIND_NOT_ALLOWED'
  | 'ASSET_NOT_ALLOWED'
  | 'COUNTERPARTY_NOT_ALLOWED'
  | 'NOTIONAL_LIMIT_EXCEEDED'
  | 'DAILY_LIMIT_EXCEEDED'
  | 'HUMAN_APPROVAL_REQUIRED'
  | 'MISSING_HUMAN_APPROVAL'
  | 'INVALID_AMOUNT'
  | 'INVALID_PRICE'
  | 'VALID';

export type AssetSymbol = string;
export type PrincipalText = string;
export type IsoTimestamp = string;

export type AiWalletScope = {
  readonly id: string;
  readonly description: string;
  readonly allowedCommandKinds: readonly AiWalletCommandKind[];
  readonly allowedAssets: readonly AssetSymbol[];
  readonly maxCommandNotional: number;
  readonly dailyNotionalLimit: number;
  readonly requireHumanApprovalAbove: number;
};

export type AiWalletPolicy = {
  readonly policyId: string;
  readonly version: string;
  readonly allowedModes: readonly NetworkMode[];
  readonly allowedCommandKinds: readonly AiWalletCommandKind[];
  readonly allowedAssets: readonly AssetSymbol[];
  readonly allowedCounterparties: readonly string[];
  readonly maxCommandNotional: number;
  readonly dailyNotionalLimit: number;
  readonly requireHumanApprovalAbove: number;
  readonly requireHumanApprovalFor: readonly AiWalletCommandKind[];
  readonly scopes: readonly AiWalletScope[];
  readonly liveModeBlocked: boolean;
};

export type AiWalletBalance = {
  readonly asset: AssetSymbol;
  readonly available: number;
  readonly locked: number;
  readonly mode: NetworkMode;
  readonly updatedAt: IsoTimestamp;
};

export type AiWallet = {
  readonly id: string;
  readonly agentId: string;
  readonly displayName: string;
  readonly ownerPrincipal: PrincipalText;
  readonly controllerPrincipal: PrincipalText;
  readonly status: AiWalletStatus;
  readonly mode: NetworkMode;
  readonly policy: AiWalletPolicy;
  readonly balances: readonly AiWalletBalance[];
  readonly createdAt: IsoTimestamp;
  readonly updatedAt: IsoTimestamp;
  readonly metadata: Readonly<Record<string, string>>;
};

export type AiWalletCommand = {
  readonly commandId: string;
  readonly walletId: string;
  readonly agentId: string;
  readonly kind: AiWalletCommandKind;
  readonly mode: NetworkMode;
  readonly asset: AssetSymbol;
  readonly amount: number;
  readonly price?: number;
  readonly counterparty?: string;
  readonly scopeId?: string;
  readonly requestedBy: PrincipalText;
  readonly humanApprovalId?: string;
  readonly memo?: string;
  readonly createdAt: IsoTimestamp;
};

export type AiWalletPolicyEvaluation = {
  readonly decision: AiWalletDecision;
  readonly reasonCodes: readonly AiWalletReasonCode[];
  readonly commandNotional: number;
  readonly projectedDailyNotional: number;
  readonly policyId: string;
  readonly policyVersion: string;
  readonly evaluatedAt: IsoTimestamp;
};

export type AiWalletReceiptKind =
  | 'AI_WALLET_CREATED'
  | 'AI_WALLET_POLICY_EVALUATED'
  | 'AI_WALLET_COMMAND_APPROVED'
  | 'AI_WALLET_COMMAND_REJECTED'
  | 'AI_WALLET_HUMAN_APPROVAL_REQUIRED'
  | 'AI_WALLET_PAUSED'
  | 'AI_WALLET_HALTED';

export type AiWalletReceipt = {
  readonly receiptId: string;
  readonly kind: AiWalletReceiptKind;
  readonly walletId: string;
  readonly agentId: string;
  readonly actor: PrincipalText;
  readonly mode: NetworkMode;
  readonly commandId?: string;
  readonly decision?: AiWalletDecision;
  readonly reasonCodes: readonly AiWalletReasonCode[];
  readonly payloadHash: string;
  readonly previousReceiptId?: string;
  readonly createdAt: IsoTimestamp;
};

export type AiWalletDailyUsage = {
  readonly walletId: string;
  readonly mode: NetworkMode;
  readonly day: string;
  readonly notionalUsed: number;
};

export type CreateAiWalletInput = {
  readonly agentId: string;
  readonly displayName: string;
  readonly ownerPrincipal: PrincipalText;
  readonly controllerPrincipal: PrincipalText;
  readonly mode?: NetworkMode;
  readonly policy?: Partial<AiWalletPolicy>;
  readonly balances?: readonly AiWalletBalance[];
  readonly metadata?: Readonly<Record<string, string>>;
  readonly now?: IsoTimestamp;
};
