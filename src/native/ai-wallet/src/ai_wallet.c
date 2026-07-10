#include "parallax/ai_wallet.h"

#include <stdio.h>
#include <string.h>

#define AIW_MODE_BIT(mode) (1U << (uint32_t)(mode))
#define AIW_KIND_BIT(kind) (1U << (uint32_t)(kind))

static uint32_t fnv1a32(const char *text) {
  uint32_t hash = 2166136261u;
  if (text == NULL) return hash;
  while (*text != '\0') {
    hash ^= (uint8_t)(*text);
    hash *= 16777619u;
    text++;
  }
  return hash;
}

static void copy_text(char *dest, size_t dest_size, const char *source) {
  if (dest == NULL || dest_size == 0) return;
  if (source == NULL) source = "";
  snprintf(dest, dest_size, "%s", source);
}

static int text_is_empty(const char *text) {
  return text == NULL || text[0] == '\0';
}

static int list_contains(char list[][PARALLAX_AIW_MAX_TEXT], size_t count, const char *value) {
  if (text_is_empty(value)) return 0;
  for (size_t index = 0; index < count; index++) {
    if (strncmp(list[index], value, PARALLAX_AIW_MAX_TEXT) == 0) return 1;
  }
  return 0;
}

static void append_default_assets(parallax_aiw_policy *policy) {
  const char *assets[] = {"PXUSD", "PXICP", "PXAI", "PXGPU", "PXETH"};
  policy->allowed_asset_count = 5;
  for (size_t index = 0; index < policy->allowed_asset_count; index++) {
    copy_text(policy->allowed_assets[index], PARALLAX_AIW_MAX_TEXT, assets[index]);
  }
}

static void append_default_counterparties(parallax_aiw_policy *policy) {
  const char *counterparties[] = {"internal", "paper-market", "research-mint", "operator"};
  policy->allowed_counterparty_count = 4;
  for (size_t index = 0; index < policy->allowed_counterparty_count; index++) {
    copy_text(policy->allowed_counterparties[index], PARALLAX_AIW_MAX_TEXT, counterparties[index]);
  }
}

static parallax_aiw_decision decide(uint64_t reason_bits) {
  const uint64_t reject_bits =
      PARALLAX_AIW_REASON_WALLET_HALTED |
      PARALLAX_AIW_REASON_WALLET_PAUSED |
      PARALLAX_AIW_REASON_MODE_NOT_ALLOWED |
      PARALLAX_AIW_REASON_LIVE_MODE_BLOCKED |
      PARALLAX_AIW_REASON_COMMAND_KIND_NOT_ALLOWED |
      PARALLAX_AIW_REASON_ASSET_NOT_ALLOWED |
      PARALLAX_AIW_REASON_COUNTERPARTY_NOT_ALLOWED |
      PARALLAX_AIW_REASON_NOTIONAL_LIMIT_EXCEEDED |
      PARALLAX_AIW_REASON_DAILY_LIMIT_EXCEEDED |
      PARALLAX_AIW_REASON_MISSING_HUMAN_APPROVAL |
      PARALLAX_AIW_REASON_INVALID_AMOUNT |
      PARALLAX_AIW_REASON_INVALID_PRICE |
      PARALLAX_AIW_REASON_INVALID_ARGUMENT;
  if ((reason_bits & reject_bits) != 0ULL) return PARALLAX_AIW_DECISION_REJECTED;
  if ((reason_bits & PARALLAX_AIW_REASON_HUMAN_APPROVAL_REQUIRED) != 0ULL) {
    return PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL;
  }
  return PARALLAX_AIW_DECISION_APPROVED;
}

static double command_notional(const parallax_aiw_command *command, uint64_t *reason_bits) {
  if (command == NULL) {
    if (reason_bits != NULL) *reason_bits |= PARALLAX_AIW_REASON_INVALID_ARGUMENT;
    return 0.0;
  }
  if (command->amount <= 0.0) {
    if (reason_bits != NULL) *reason_bits |= PARALLAX_AIW_REASON_INVALID_AMOUNT;
    return 0.0;
  }
  if (command->kind == PARALLAX_AIW_COMMAND_ORDER) {
    if (!command->has_price || command->price <= 0.0) {
      if (reason_bits != NULL) *reason_bits |= PARALLAX_AIW_REASON_INVALID_PRICE;
      return 0.0;
    }
    return command->amount * command->price;
  }
  return command->amount;
}

const char *parallax_aiw_version(void) { return "0.1.0-alpha.0"; }

const char *parallax_aiw_result_name(parallax_aiw_result result) {
  switch (result) {
    case PARALLAX_AIW_OK: return "ok";
    case PARALLAX_AIW_ERROR_NULL: return "null";
    case PARALLAX_AIW_ERROR_INVALID: return "invalid";
    case PARALLAX_AIW_ERROR_BUFFER: return "buffer";
    default: return "unknown";
  }
}

const char *parallax_aiw_mode_name(parallax_aiw_mode mode) {
  switch (mode) {
    case PARALLAX_AIW_MODE_PAPER: return "paper";
    case PARALLAX_AIW_MODE_TESTNET: return "testnet";
    case PARALLAX_AIW_MODE_RESTRICTED_LIVE: return "restricted_live";
    case PARALLAX_AIW_MODE_LIVE: return "live";
    default: return "unknown";
  }
}

const char *parallax_aiw_status_name(parallax_aiw_status status) {
  switch (status) {
    case PARALLAX_AIW_STATUS_ACTIVE: return "active";
    case PARALLAX_AIW_STATUS_PAUSED: return "paused";
    case PARALLAX_AIW_STATUS_HALTED: return "halted";
    case PARALLAX_AIW_STATUS_RETIRED: return "retired";
    default: return "unknown";
  }
}

const char *parallax_aiw_command_kind_name(parallax_aiw_command_kind kind) {
  switch (kind) {
    case PARALLAX_AIW_COMMAND_TRANSFER: return "transfer";
    case PARALLAX_AIW_COMMAND_ORDER: return "order";
    case PARALLAX_AIW_COMMAND_RESEARCH_MINT: return "research_mint";
    case PARALLAX_AIW_COMMAND_APPROVE_SIGNAL: return "approve_signal";
    case PARALLAX_AIW_COMMAND_CANCEL_ORDER: return "cancel_order";
    case PARALLAX_AIW_COMMAND_OPERATOR_NOTE: return "operator_note";
    default: return "unknown";
  }
}

const char *parallax_aiw_decision_name(parallax_aiw_decision decision) {
  switch (decision) {
    case PARALLAX_AIW_DECISION_APPROVED: return "approved";
    case PARALLAX_AIW_DECISION_REJECTED: return "rejected";
    case PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL: return "requires_human_approval";
    default: return "unknown";
  }
}

void parallax_aiw_default_policy(parallax_aiw_policy *out_policy) {
  if (out_policy == NULL) return;
  memset(out_policy, 0, sizeof(*out_policy));
  copy_text(out_policy->policy_id, PARALLAX_AIW_MAX_TEXT, "parallax-ai-wallet-native-alpha-policy");
  copy_text(out_policy->version, PARALLAX_AIW_MAX_TEXT, parallax_aiw_version());
  out_policy->allowed_modes_mask = AIW_MODE_BIT(PARALLAX_AIW_MODE_PAPER) | AIW_MODE_BIT(PARALLAX_AIW_MODE_TESTNET);
  out_policy->allowed_command_kinds_mask =
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_TRANSFER) |
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_ORDER) |
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_RESEARCH_MINT) |
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_APPROVE_SIGNAL) |
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_CANCEL_ORDER) |
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_OPERATOR_NOTE);
  out_policy->require_human_approval_kinds_mask =
      AIW_KIND_BIT(PARALLAX_AIW_COMMAND_TRANSFER) | AIW_KIND_BIT(PARALLAX_AIW_COMMAND_ORDER);
  append_default_assets(out_policy);
  append_default_counterparties(out_policy);
  out_policy->max_command_notional = 10000.0;
  out_policy->daily_notional_limit = 50000.0;
  out_policy->require_human_approval_above = 2500.0;
  out_policy->live_mode_blocked = 1;
}

parallax_aiw_result parallax_aiw_create_wallet(const parallax_aiw_wallet_config *config, parallax_aiw_wallet *out_wallet) {
  if (config == NULL || out_wallet == NULL) return PARALLAX_AIW_ERROR_NULL;
  if (text_is_empty(config->agent_id) || text_is_empty(config->owner_principal) ||
      text_is_empty(config->controller_principal) || text_is_empty(config->created_at)) {
    return PARALLAX_AIW_ERROR_INVALID;
  }

  memset(out_wallet, 0, sizeof(*out_wallet));
  copy_text(out_wallet->agent_id, PARALLAX_AIW_MAX_TEXT, config->agent_id);
  copy_text(out_wallet->display_name, PARALLAX_AIW_MAX_TEXT, config->display_name);
  copy_text(out_wallet->owner_principal, PARALLAX_AIW_MAX_TEXT, config->owner_principal);
  copy_text(out_wallet->controller_principal, PARALLAX_AIW_MAX_TEXT, config->controller_principal);
  copy_text(out_wallet->created_at, PARALLAX_AIW_MAX_TEXT, config->created_at);
  copy_text(out_wallet->updated_at, PARALLAX_AIW_MAX_TEXT, config->created_at);
  out_wallet->status = PARALLAX_AIW_STATUS_ACTIVE;
  out_wallet->mode = config->mode;
  if (config->policy != NULL) {
    out_wallet->policy = *config->policy;
  } else {
    parallax_aiw_default_policy(&out_wallet->policy);
  }

  if ((out_wallet->policy.allowed_modes_mask & AIW_MODE_BIT(config->mode)) == 0U) {
    return PARALLAX_AIW_ERROR_INVALID;
  }

  char seed[PARALLAX_AIW_MAX_TEXT * 3];
  snprintf(seed, sizeof(seed), "%s:%s:%s", config->agent_id, config->owner_principal, config->created_at);
  snprintf(out_wallet->wallet_id, PARALLAX_AIW_MAX_TEXT, "aiw_%08x", fnv1a32(seed));
  return PARALLAX_AIW_OK;
}

parallax_aiw_result parallax_aiw_make_command(const parallax_aiw_wallet *wallet,
                                              parallax_aiw_command_kind kind,
                                              const char *asset,
                                              double amount,
                                              double price,
                                              int has_price,
                                              const char *counterparty,
                                              const char *requested_by,
                                              const char *human_approval_id,
                                              const char *memo,
                                              const char *created_at,
                                              parallax_aiw_command *out_command) {
  if (wallet == NULL || out_command == NULL) return PARALLAX_AIW_ERROR_NULL;
  if (text_is_empty(asset) || text_is_empty(requested_by) || text_is_empty(created_at)) {
    return PARALLAX_AIW_ERROR_INVALID;
  }
  memset(out_command, 0, sizeof(*out_command));
  copy_text(out_command->wallet_id, PARALLAX_AIW_MAX_TEXT, wallet->wallet_id);
  copy_text(out_command->agent_id, PARALLAX_AIW_MAX_TEXT, wallet->agent_id);
  copy_text(out_command->asset, PARALLAX_AIW_MAX_TEXT, asset);
  copy_text(out_command->counterparty, PARALLAX_AIW_MAX_TEXT, counterparty);
  copy_text(out_command->requested_by, PARALLAX_AIW_MAX_TEXT, requested_by);
  copy_text(out_command->human_approval_id, PARALLAX_AIW_MAX_TEXT, human_approval_id);
  copy_text(out_command->memo, PARALLAX_AIW_MAX_TEXT, memo);
  copy_text(out_command->created_at, PARALLAX_AIW_MAX_TEXT, created_at);
  out_command->kind = kind;
  out_command->mode = wallet->mode;
  out_command->amount = amount;
  out_command->price = price;
  out_command->has_price = has_price;

  char seed[PARALLAX_AIW_MAX_TEXT * 4];
  snprintf(seed, sizeof(seed), "%s:%d:%s:%s", wallet->wallet_id, (int)kind, created_at, asset);
  snprintf(out_command->command_id, PARALLAX_AIW_MAX_TEXT, "aiwcmd_%08x", fnv1a32(seed));
  return PARALLAX_AIW_OK;
}

parallax_aiw_result parallax_aiw_evaluate_command(const parallax_aiw_wallet *wallet,
                                                  const parallax_aiw_command *command,
                                                  double daily_notional_used,
                                                  const char *evaluated_at,
                                                  parallax_aiw_evaluation *out_evaluation) {
  if (wallet == NULL || command == NULL || out_evaluation == NULL) return PARALLAX_AIW_ERROR_NULL;
  memset(out_evaluation, 0, sizeof(*out_evaluation));

  uint64_t reasons = 0ULL;
  const parallax_aiw_policy *policy = &wallet->policy;
  const double notional = command_notional(command, &reasons);
  const double projected_daily = daily_notional_used + notional;

  if (wallet->status == PARALLAX_AIW_STATUS_HALTED) reasons |= PARALLAX_AIW_REASON_WALLET_HALTED;
  if (wallet->status == PARALLAX_AIW_STATUS_PAUSED) reasons |= PARALLAX_AIW_REASON_WALLET_PAUSED;
  if ((policy->allowed_modes_mask & AIW_MODE_BIT(command->mode)) == 0U) reasons |= PARALLAX_AIW_REASON_MODE_NOT_ALLOWED;
  if (policy->live_mode_blocked &&
      (command->mode == PARALLAX_AIW_MODE_LIVE || command->mode == PARALLAX_AIW_MODE_RESTRICTED_LIVE)) {
    reasons |= PARALLAX_AIW_REASON_LIVE_MODE_BLOCKED;
  }
  if ((policy->allowed_command_kinds_mask & AIW_KIND_BIT(command->kind)) == 0U) {
    reasons |= PARALLAX_AIW_REASON_COMMAND_KIND_NOT_ALLOWED;
  }
  if (!list_contains((char (*)[PARALLAX_AIW_MAX_TEXT])policy->allowed_assets, policy->allowed_asset_count, command->asset)) {
    reasons |= PARALLAX_AIW_REASON_ASSET_NOT_ALLOWED;
  }
  if (!text_is_empty(command->counterparty) &&
      !list_contains((char (*)[PARALLAX_AIW_MAX_TEXT])policy->allowed_counterparties, policy->allowed_counterparty_count, command->counterparty)) {
    reasons |= PARALLAX_AIW_REASON_COUNTERPARTY_NOT_ALLOWED;
  }
  if (notional > policy->max_command_notional) reasons |= PARALLAX_AIW_REASON_NOTIONAL_LIMIT_EXCEEDED;
  if (projected_daily > policy->daily_notional_limit) reasons |= PARALLAX_AIW_REASON_DAILY_LIMIT_EXCEEDED;

  const int kind_requires_approval = (policy->require_human_approval_kinds_mask & AIW_KIND_BIT(command->kind)) != 0U;
  const int value_requires_approval = notional >= policy->require_human_approval_above;
  if ((kind_requires_approval || value_requires_approval) && text_is_empty(command->human_approval_id)) {
    reasons |= PARALLAX_AIW_REASON_HUMAN_APPROVAL_REQUIRED;
  }
  if (reasons == 0ULL) reasons |= PARALLAX_AIW_REASON_VALID;

  out_evaluation->decision = decide(reasons);
  out_evaluation->reason_bits = reasons;
  out_evaluation->command_notional = notional;
  out_evaluation->projected_daily_notional = projected_daily;
  copy_text(out_evaluation->policy_id, PARALLAX_AIW_MAX_TEXT, policy->policy_id);
  copy_text(out_evaluation->policy_version, PARALLAX_AIW_MAX_TEXT, policy->version);
  copy_text(out_evaluation->evaluated_at, PARALLAX_AIW_MAX_TEXT, evaluated_at);
  return PARALLAX_AIW_OK;
}

parallax_aiw_result parallax_aiw_make_receipt(const parallax_aiw_wallet *wallet,
                                              const parallax_aiw_command *command,
                                              const parallax_aiw_evaluation *evaluation,
                                              const char *actor,
                                              const char *previous_receipt_id,
                                              parallax_aiw_receipt *out_receipt) {
  if (wallet == NULL || command == NULL || evaluation == NULL || out_receipt == NULL) return PARALLAX_AIW_ERROR_NULL;
  if (text_is_empty(actor)) return PARALLAX_AIW_ERROR_INVALID;
  memset(out_receipt, 0, sizeof(*out_receipt));
  copy_text(out_receipt->wallet_id, PARALLAX_AIW_MAX_TEXT, wallet->wallet_id);
  copy_text(out_receipt->agent_id, PARALLAX_AIW_MAX_TEXT, wallet->agent_id);
  copy_text(out_receipt->actor, PARALLAX_AIW_MAX_TEXT, actor);
  copy_text(out_receipt->command_id, PARALLAX_AIW_MAX_TEXT, command->command_id);
  copy_text(out_receipt->previous_receipt_id, PARALLAX_AIW_MAX_TEXT, previous_receipt_id);
  copy_text(out_receipt->created_at, PARALLAX_AIW_MAX_TEXT, evaluation->evaluated_at);
  out_receipt->mode = command->mode;
  out_receipt->decision = evaluation->decision;
  out_receipt->reason_bits = evaluation->reason_bits;

  char payload[PARALLAX_AIW_MAX_TEXT * 6];
  snprintf(payload, sizeof(payload), "%s:%s:%s:%s:%u:%0.8f", wallet->wallet_id, command->command_id,
           actor, evaluation->evaluated_at, (unsigned)evaluation->reason_bits, evaluation->command_notional);
  snprintf(out_receipt->payload_hash, PARALLAX_AIW_MAX_RECEIPT_HASH, "%08x", fnv1a32(payload));
  snprintf(out_receipt->receipt_id, PARALLAX_AIW_MAX_TEXT, "aiwrcpt_%08x", fnv1a32(out_receipt->payload_hash));
  return PARALLAX_AIW_OK;
}

int parallax_aiw_has_reason(const parallax_aiw_evaluation *evaluation, uint64_t reason_bit) {
  if (evaluation == NULL) return 0;
  return (evaluation->reason_bits & reason_bit) != 0ULL;
}

int parallax_aiw_receipt_links_to(const parallax_aiw_receipt *receipt, const parallax_aiw_receipt *previous) {
  if (receipt == NULL || previous == NULL) return 0;
  return strncmp(receipt->previous_receipt_id, previous->receipt_id, PARALLAX_AIW_MAX_TEXT) == 0;
}
