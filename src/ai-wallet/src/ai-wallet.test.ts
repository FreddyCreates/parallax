import { describe, expect, it } from 'vitest';
import {
  createAiWallet,
  createAiWalletCreatedReceipt,
  createAiWalletEvaluationReceipt,
  createInternalTransferCommand,
  createPaperOrderCommand,
  createResearchMintCommand,
  evaluateAiWalletCommand,
  verifyAiWalletReceiptChain,
} from './index.js';

const now = '2026-07-09T00:00:00.000Z';

const wallet = createAiWallet({
  agentId: 'agent.parallax.research-01',
  displayName: 'PARALLAX Research Agent Wallet',
  ownerPrincipal: 'principal-owner',
  controllerPrincipal: 'principal-controller',
  mode: 'paper',
  now,
});

describe('AI wallet policy engine', () => {
  it('creates deterministic AI wallets in paper mode', () => {
    const another = createAiWallet({
      agentId: 'agent.parallax.research-01',
      displayName: 'PARALLAX Research Agent Wallet',
      ownerPrincipal: 'principal-owner',
      controllerPrincipal: 'principal-controller',
      mode: 'paper',
      now,
    });

    expect(wallet.id).toBe(another.id);
    expect(wallet.mode).toBe('paper');
    expect(wallet.policy.liveModeBlocked).toBe(true);
  });

  it('requires human approval for paper orders above policy threshold', () => {
    const command = createPaperOrderCommand({
      wallet,
      asset: 'PXICP',
      amount: 100,
      price: 30,
      requestedBy: 'principal-controller',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, {
      walletId: wallet.id,
      mode: 'paper',
      day: '2026-07-09',
      notionalUsed: 0,
    }, now);

    expect(evaluation.commandNotional).toBe(3000);
    expect(evaluation.decision).toBe('requires_human_approval');
    expect(evaluation.reasonCodes).toContain('HUMAN_APPROVAL_REQUIRED');
  });

  it('approves human-approved paper orders inside limits', () => {
    const command = createPaperOrderCommand({
      wallet,
      asset: 'PXICP',
      amount: 100,
      price: 30,
      requestedBy: 'principal-controller',
      humanApprovalId: 'approval-001',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, {
      walletId: wallet.id,
      mode: 'paper',
      day: '2026-07-09',
      notionalUsed: 0,
    }, now);

    expect(evaluation.decision).toBe('approved');
    expect(evaluation.reasonCodes).toContain('VALID');
  });

  it('rejects live commands during alpha', () => {
    const command = createInternalTransferCommand({
      wallet,
      mode: 'live',
      asset: 'PXUSD',
      amount: 100,
      requestedBy: 'principal-controller',
      humanApprovalId: 'approval-002',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, undefined, now);

    expect(evaluation.decision).toBe('rejected');
    expect(evaluation.reasonCodes).toContain('MODE_NOT_ALLOWED');
    expect(evaluation.reasonCodes).toContain('LIVE_MODE_BLOCKED');
  });

  it('rejects assets outside the wallet policy', () => {
    const command = createInternalTransferCommand({
      wallet,
      asset: 'DOGE',
      amount: 100,
      requestedBy: 'principal-controller',
      humanApprovalId: 'approval-003',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, undefined, now);

    expect(evaluation.decision).toBe('rejected');
    expect(evaluation.reasonCodes).toContain('ASSET_NOT_ALLOWED');
  });

  it('rejects commands that exceed daily limits', () => {
    const command = createPaperOrderCommand({
      wallet,
      asset: 'PXICP',
      amount: 100,
      price: 30,
      requestedBy: 'principal-controller',
      humanApprovalId: 'approval-004',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, {
      walletId: wallet.id,
      mode: 'paper',
      day: '2026-07-09',
      notionalUsed: 49_000,
    }, now);

    expect(evaluation.decision).toBe('rejected');
    expect(evaluation.reasonCodes).toContain('DAILY_LIMIT_EXCEEDED');
  });

  it('allows research mint commands inside the research scope', () => {
    const command = createResearchMintCommand({
      wallet,
      asset: 'PXAI',
      amount: 250,
      requestedBy: 'principal-controller',
      now,
    });

    const evaluation = evaluateAiWalletCommand(wallet, command, undefined, now);

    expect(evaluation.decision).toBe('approved');
    expect(evaluation.reasonCodes).toContain('VALID');
  });

  it('creates verifiable receipt chains', () => {
    const created = createAiWalletCreatedReceipt(wallet, 'principal-owner');
    const command = createPaperOrderCommand({
      wallet,
      asset: 'PXICP',
      amount: 1,
      price: 10,
      requestedBy: 'principal-controller',
      humanApprovalId: 'approval-005',
      now,
    });
    const evaluation = evaluateAiWalletCommand(wallet, command, undefined, now);
    const evaluated = createAiWalletEvaluationReceipt(
      wallet,
      command,
      evaluation,
      'principal-controller',
      created.receiptId,
    );

    expect(verifyAiWalletReceiptChain([created, evaluated])).toBe(true);
    expect(evaluated.previousReceiptId).toBe(created.receiptId);
  });
});
