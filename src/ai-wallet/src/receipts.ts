import type {
  AiWallet,
  AiWalletCommand,
  AiWalletPolicyEvaluation,
  AiWalletReceipt,
  AiWalletReceiptKind,
  PrincipalText,
} from './types.js';
import { makeAiWalletReceiptId, stableHashSync } from './id.js';

const receiptKindForDecision = (decision: AiWalletPolicyEvaluation['decision']): AiWalletReceiptKind => {
  if (decision === 'approved') return 'AI_WALLET_COMMAND_APPROVED';
  if (decision === 'requires_human_approval') return 'AI_WALLET_HUMAN_APPROVAL_REQUIRED';
  return 'AI_WALLET_COMMAND_REJECTED';
};

export const createAiWalletCreatedReceipt = (
  wallet: AiWallet,
  actor: PrincipalText,
  previousReceiptId?: string,
): AiWalletReceipt => {
  const createdAt = wallet.createdAt;
  const payloadHash = stableHashSync({ wallet, actor, previousReceiptId });
  return {
    receiptId: makeAiWalletReceiptId(wallet.id, 'AI_WALLET_CREATED', createdAt),
    kind: 'AI_WALLET_CREATED',
    walletId: wallet.id,
    agentId: wallet.agentId,
    actor,
    mode: wallet.mode,
    reasonCodes: ['VALID'],
    payloadHash,
    previousReceiptId,
    createdAt,
  };
};

export const createAiWalletEvaluationReceipt = (
  wallet: AiWallet,
  command: AiWalletCommand,
  evaluation: AiWalletPolicyEvaluation,
  actor: PrincipalText,
  previousReceiptId?: string,
): AiWalletReceipt => {
  const kind = receiptKindForDecision(evaluation.decision);
  const payloadHash = stableHashSync({ walletId: wallet.id, command, evaluation, actor, previousReceiptId });
  return {
    receiptId: makeAiWalletReceiptId(wallet.id, kind, evaluation.evaluatedAt, command.commandId),
    kind,
    walletId: wallet.id,
    agentId: wallet.agentId,
    actor,
    mode: command.mode,
    commandId: command.commandId,
    decision: evaluation.decision,
    reasonCodes: evaluation.reasonCodes,
    payloadHash,
    previousReceiptId,
    createdAt: evaluation.evaluatedAt,
  };
};

export const verifyAiWalletReceiptChain = (receipts: readonly AiWalletReceipt[]): boolean => {
  if (receipts.length === 0) return true;
  for (let index = 1; index < receipts.length; index += 1) {
    const previous = receipts[index - 1];
    const current = receipts[index];
    if (!previous || !current) return false;
    if (current.previousReceiptId !== previous.receiptId) return false;
  }
  return true;
};
