import type { AiWallet, AiWalletCommand, AiWalletCommandKind, AssetSymbol, NetworkMode, PrincipalText } from './types.js';
import { makeAiWalletCommandId } from './id.js';

export type CreateAiWalletCommandInput = {
  readonly wallet: AiWallet;
  readonly kind: AiWalletCommandKind;
  readonly asset: AssetSymbol;
  readonly amount: number;
  readonly price?: number;
  readonly counterparty?: string;
  readonly scopeId?: string;
  readonly requestedBy: PrincipalText;
  readonly humanApprovalId?: string;
  readonly memo?: string;
  readonly mode?: NetworkMode;
  readonly now?: string;
  readonly nonce?: string;
};

export const createAiWalletCommand = (input: CreateAiWalletCommandInput): AiWalletCommand => {
  const createdAt = input.now ?? new Date().toISOString();
  const mode = input.mode ?? input.wallet.mode;
  const commandId = makeAiWalletCommandId(input.wallet.id, input.kind, createdAt, input.nonce);

  return {
    commandId,
    walletId: input.wallet.id,
    agentId: input.wallet.agentId,
    kind: input.kind,
    mode,
    asset: input.asset,
    amount: input.amount,
    price: input.price,
    counterparty: input.counterparty,
    scopeId: input.scopeId,
    requestedBy: input.requestedBy,
    humanApprovalId: input.humanApprovalId,
    memo: input.memo,
    createdAt,
  };
};

export const createPaperOrderCommand = (input: Omit<CreateAiWalletCommandInput, 'kind' | 'counterparty'>) =>
  createAiWalletCommand({
    ...input,
    kind: 'order',
    counterparty: 'paper-market',
    scopeId: input.scopeId ?? 'paper-trade',
  });

export const createInternalTransferCommand = (
  input: Omit<CreateAiWalletCommandInput, 'kind' | 'counterparty'> & { readonly counterparty?: string },
) =>
  createAiWalletCommand({
    ...input,
    kind: 'transfer',
    counterparty: input.counterparty ?? 'internal',
    scopeId: input.scopeId ?? 'internal-pay',
  });

export const createResearchMintCommand = (input: Omit<CreateAiWalletCommandInput, 'kind' | 'counterparty'>) =>
  createAiWalletCommand({
    ...input,
    kind: 'research_mint',
    counterparty: 'research-mint',
    scopeId: input.scopeId ?? 'research-mint',
  });
