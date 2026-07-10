#include "parallax/ai_wallet.h"

#include <assert.h>
#include <string.h>

static parallax_aiw_wallet make_wallet(void) {
  parallax_aiw_wallet wallet;
  parallax_aiw_wallet_config config;
  memset(&config, 0, sizeof(config));
  config.agent_id = "agent.parallax.c-test";
  config.display_name = "PARALLAX C Test Wallet";
  config.owner_principal = "principal-owner";
  config.controller_principal = "principal-controller";
  config.created_at = "2026-07-09T00:00:00Z";
  config.mode = PARALLAX_AIW_MODE_PAPER;
  config.policy = NULL;
  assert(parallax_aiw_create_wallet(&config, &wallet) == PARALLAX_AIW_OK);
  return wallet;
}

int main(void) {
  parallax_aiw_wallet wallet = make_wallet();
  assert(strncmp(wallet.wallet_id, "aiw_", 4) == 0);
  assert(wallet.status == PARALLAX_AIW_STATUS_ACTIVE);

  parallax_aiw_command command;
  assert(parallax_aiw_make_command(&wallet,
                                   PARALLAX_AIW_COMMAND_ORDER,
                                   "PXICP",
                                   100.0,
                                   30.0,
                                   1,
                                   "paper-market",
                                   "principal-controller",
                                   "",
                                   "paper order",
                                   "2026-07-09T00:00:00Z",
                                   &command) == PARALLAX_AIW_OK);

  parallax_aiw_evaluation evaluation;
  assert(parallax_aiw_evaluate_command(&wallet, &command, 0.0, "2026-07-09T00:00:00Z", &evaluation) == PARALLAX_AIW_OK);
  assert(evaluation.decision == PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL);
  assert(parallax_aiw_has_reason(&evaluation, PARALLAX_AIW_REASON_HUMAN_APPROVAL_REQUIRED));

  assert(parallax_aiw_make_command(&wallet,
                                   PARALLAX_AIW_COMMAND_ORDER,
                                   "PXICP",
                                   100.0,
                                   30.0,
                                   1,
                                   "paper-market",
                                   "principal-controller",
                                   "approval-001",
                                   "paper order",
                                   "2026-07-09T00:00:01Z",
                                   &command) == PARALLAX_AIW_OK);
  assert(parallax_aiw_evaluate_command(&wallet, &command, 0.0, "2026-07-09T00:00:01Z", &evaluation) == PARALLAX_AIW_OK);
  assert(evaluation.decision == PARALLAX_AIW_DECISION_APPROVED);
  assert(parallax_aiw_has_reason(&evaluation, PARALLAX_AIW_REASON_VALID));

  parallax_aiw_receipt receipt;
  assert(parallax_aiw_make_receipt(&wallet, &command, &evaluation, "principal-controller", "", &receipt) == PARALLAX_AIW_OK);
  assert(strncmp(receipt.receipt_id, "aiwrcpt_", 8) == 0);

  parallax_aiw_wallet live_wallet = wallet;
  live_wallet.mode = PARALLAX_AIW_MODE_LIVE;
  assert(parallax_aiw_make_command(&live_wallet,
                                   PARALLAX_AIW_COMMAND_TRANSFER,
                                   "PXUSD",
                                   100.0,
                                   0.0,
                                   0,
                                   "internal",
                                   "principal-controller",
                                   "approval-002",
                                   "live transfer blocked",
                                   "2026-07-09T00:00:02Z",
                                   &command) == PARALLAX_AIW_OK);
  assert(parallax_aiw_evaluate_command(&live_wallet, &command, 0.0, "2026-07-09T00:00:02Z", &evaluation) == PARALLAX_AIW_OK);
  assert(evaluation.decision == PARALLAX_AIW_DECISION_REJECTED);
  assert(parallax_aiw_has_reason(&evaluation, PARALLAX_AIW_REASON_MODE_NOT_ALLOWED));
  assert(parallax_aiw_has_reason(&evaluation, PARALLAX_AIW_REASON_LIVE_MODE_BLOCKED));

  return 0;
}
