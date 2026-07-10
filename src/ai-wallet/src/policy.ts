import type {
  AiWallet,
  AiWalletCommand,
  AiWalletDecision,
  AiWalletPolicy,
  AiWalletPolicyEvaluation,
  AiWalletReasonCode,
  AiWalletDailyUsage,
  CreateAiWalletInput,
  NetworkMode,
} from './types.js';
import { makeAiWalletId } from './id.js';

export const ALPHA_ALLOWED_MODES: readonly NetworkMode[] = ['paper', 'testnet'];

export const DEFAULT_AI_WALLET_POLICY: AiWalletPolicy = {
  policyId: 'parallax-ai-wallet-alpha-policy',
  version: '0.1.0-alpha.0',
  allowedModes: ALPHA_ALLOWED_MODES,
  allowedCommandKinds: ['transfer', 'order', 'research_mint', 'approve_signal', 'cancel_order', 'operator_note'],
  allowedAssets: ['PXUSD', 'PXICP', 'PXAI', 'PXGPU', 'PXETH'],
  allowedCounterparties: ['internal', 'paper-market', 'research-mint', 'operator'],
  maxCommandNotional: 10_000,
  dailyNotionalLimit: 50_000,
  requireHumanApprovalAbove: 2_500,
  requireHumanApprovalFor: ['order', 'transfer'],
  scopes: [
    {
      id: 'paper-trade',
      description: 'Paper-market order flow only.',
      allowedCommandKinds: ['order', 'cancel_order', 'approve_signal'],
      allowedAssets: ['PXUSD', 'PXICP', 'PXAI', 'PXGPU', 'PXETH'],
      maxCommandNotional: 10_000,
      dailyNotionalLimit: 50_000,
      requireHumanApprovalAbove: 2_500,
    },
    {
      id: 'research-mint',
      description: 'Research artifact receipt creation only.',
      allowedCommandKinds: ['research_mint', 'operator_note'],
      allowedAssets: ['PXAI'],
      maxCommandNotional: 1_000,
      dailyNotionalLimit: 10_000,
      requireHumanApprovalAbove: 500,
    },
    {
      id: 'internal-pay',
      description: 'Internal paper/testnet transfer workflows only.',
      allowedCommandKinds: ['transfer'],
      allowedAssets: ['PXUSD', 'PXICP'],
      maxCommandNotional: 5_000,
      dailyNotionalLimit: 25_000,
      requireHumanApprovalAbove: 1_000,
    },
  ],
  liveModeBlocked: true,
};

const unique = <T>(items: readonly T[]): T[] => [...new Set(items)];

export const createAiWallet = (input: CreateAiWalletInput): AiWallet => {
  const now = input.now ?? new Date().toISOString();
  const policy: AiWalletPolicy = {
    ...DEFAULT_AI_WALLET_POLICY,
    ...input.policy,
    allowedModes: input.policy?.allowedModes ?? DEFAULT_AI_WALLET_POLICY.allowedModes,
    allowedCommandKinds: input.policy?.allowedCommandKinds ?? DEFAULT_AI_WALLET_POLICY.allowedCommandKinds,
    allowedAssets: input.policy?.allowedAssets ?? DEFAULT_AI_WALLET_POLICY.allowedAssets,
    allowedCounterparties: input.policy?.allowedCounterparties ?? DEFAULT_AI_WALLET_POLICY.allowedCounterparties,
    requireHumanApprovalFor:
      input.policy?.requireHumanApprovalFor ?? DEFAULT_AI_WALLET_POLICY.requireHumanApprovalFor,
    scopes: input.policy?.scopes ?? DEFAULT_AI_WALLET_POLICY.scopes,
    liveModeBlocked: input.policy?.liveModeBlocked ?? DEFAULT_AI_WALLET_POLICY.liveModeBlocked,
  };

  const mode = input.mode ?? 'paper';
  if (!policy.allowedModes.includes(mode)) {
    throw new Error(`AI wallet mode ${mode} is not allowed by policy ${policy.policyId}`);
  }

  return {
    id: makeAiWalletId(input.agentId, input.ownerPrincipal, now),
    agentId: input.agentId,
    displayName: input.displayName,
    ownerPrincipal: input.ownerPrincipal,
    controllerPrincipal: input.controllerPrincipal,
    status: 'active',
    mode,
    policy,
    balances: input.balances ?? [],
    createdAt: now,
    updatedAt: now,
    metadata: input.metadata ?? {},
  };
};

const commandNotional = (command: AiWalletCommand): number => {
  if (command.amount <= 0) return Number.NaN;
  if (command.kind === 'order') {
    if (command.price === undefined || command.price <= 0) return Number.NaN;
    return command.amount * command.price;
  }
  return command.amount;
};

const decide = (reasonCodes: AiWalletReasonCode[]): AiWalletDecision => {
  const hardRejects: AiWalletReasonCode[] = [
    'WALLET_HALTED',
    'WALLET_PAUSED',
    'MODE_NOT_ALLOWED',
    'LIVE_MODE_BLOCKED',
    'COMMAND_KIND_NOT_ALLOWED',
    'ASSET_NOT_ALLOWED',
    'COUNTERPARTY_NOT_ALLOWED',
    'NOTIONAL_LIMIT_EXCEEDED',
    'DAILY_LIMIT_EXCEEDED',
    'MISSING_HUMAN_APPROVAL',
    'INVALID_AMOUNT',
    'INVALID_PRICE',
  ];
  if (reasonCodes.some((code) => hardRejects.includes(code))) return 'rejected';
  if (reasonCodes.includes('HUMAN_APPROVAL_REQUIRED')) return 'requires_human_approval';
  return 'approved';
};

export const evaluateAiWalletCommand = (
  wallet: AiWallet,
  command: AiWalletCommand,
  dailyUsage?: AiWalletDailyUsage,
  evaluatedAt = new Date().toISOString(),
): AiWalletPolicyEvaluation => {
  const policy = wallet.policy;
  const reasonCodes: AiWalletReasonCode[] = [];
  const notional = commandNotional(command);

  if (wallet.status === 'halted') reasonCodes.push('WALLET_HALTED');
  if (wallet.status === 'paused') reasonCodes.push('WALLET_PAUSED');
  if (!policy.allowedModes.includes(command.mode)) reasonCodes.push('MODE_NOT_ALLOWED');
  if (policy.liveModeBlocked && (command.mode === 'live' || command.mode === 'restricted_live')) {
    reasonCodes.push('LIVE_MODE_BLOCKED');
  }
  if (!policy.allowedCommandKinds.includes(command.kind)) reasonCodes.push('COMMAND_KIND_NOT_ALLOWED');
  if (!policy.allowedAssets.includes(command.asset)) reasonCodes.push('ASSET_NOT_ALLOWED');

  if (command.counterparty && !policy.allowedCounterparties.includes(command.counterparty)) {
    reasonCodes.push('COUNTERPARTY_NOT_ALLOWED');
  }

  if (Number.isNaN(notional) || command.amount <= 0) reasonCodes.push('INVALID_AMOUNT');
  if (command.kind === 'order' && (command.price === undefined || command.price <= 0)) {
    reasonCodes.push('INVALID_PRICE');
  }

  const scope = command.scopeId ? policy.scopes.find((item) => item.id === command.scopeId) : undefined;
  const maxCommandNotional = Math.min(policy.maxCommandNotional, scope?.maxCommandNotional ?? Infinity);
  const dailyNotionalLimit = Math.min(policy.dailyNotionalLimit, scope?.dailyNotionalLimit ?? Infinity);
  const requireHumanApprovalAbove = Math.min(
    policy.requireHumanApprovalAbove,
    scope?.requireHumanApprovalAbove ?? Infinity,
  );

  if (scope) {
    if (!scope.allowedCommandKinds.includes(command.kind)) reasonCodes.push('COMMAND_KIND_NOT_ALLOWED');
    if (!scope.allowedAssets.includes(command.asset)) reasonCodes.push('ASSET_NOT_ALLOWED');
  }

  if (!Number.isNaN(notional) && notional > maxCommandNotional) reasonCodes.push('NOTIONAL_LIMIT_EXCEEDED');

  const projectedDailyNotional = (dailyUsage?.notionalUsed ?? 0) + (Number.isNaN(notional) ? 0 : notional);
  if (projectedDailyNotional > dailyNotionalLimit) reasonCodes.push('DAILY_LIMIT_EXCEEDED');

  const approvalRequired =
    policy.requireHumanApprovalFor.includes(command.kind) ||
    (!Number.isNaN(notional) && notional >= requireHumanApprovalAbove);

  if (approvalRequired && !command.humanApprovalId) reasonCodes.push('HUMAN_APPROVAL_REQUIRED');
  if (approvalRequired && command.humanApprovalId === '') reasonCodes.push('MISSING_HUMAN_APPROVAL');

  if (reasonCodes.length === 0) reasonCodes.push('VALID');

  return {
    decision: decide(unique(reasonCodes)),
    reasonCodes: unique(reasonCodes),
    commandNotional: Number.isNaN(notional) ? 0 : notional,
    projectedDailyNotional,
    policyId: policy.policyId,
    policyVersion: policy.version,
    evaluatedAt,
  };
};
