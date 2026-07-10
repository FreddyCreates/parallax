#ifndef PARALLAX_AI_WALLET_H
#define PARALLAX_AI_WALLET_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PARALLAX_AIW_VERSION_MAJOR 0
#define PARALLAX_AIW_VERSION_MINOR 1
#define PARALLAX_AIW_VERSION_PATCH 0

#define PARALLAX_AIW_MAX_TEXT 128
#define PARALLAX_AIW_MAX_ASSETS 16
#define PARALLAX_AIW_MAX_COUNTERPARTIES 16
#define PARALLAX_AIW_MAX_RECEIPT_HASH 65

#define PARALLAX_AIW_REASON_VALID (1ULL << 0)
#define PARALLAX_AIW_REASON_WALLET_HALTED (1ULL << 1)
#define PARALLAX_AIW_REASON_WALLET_PAUSED (1ULL << 2)
#define PARALLAX_AIW_REASON_MODE_NOT_ALLOWED (1ULL << 3)
#define PARALLAX_AIW_REASON_LIVE_MODE_BLOCKED (1ULL << 4)
#define PARALLAX_AIW_REASON_COMMAND_KIND_NOT_ALLOWED (1ULL << 5)
#define PARALLAX_AIW_REASON_ASSET_NOT_ALLOWED (1ULL << 6)
#define PARALLAX_AIW_REASON_COUNTERPARTY_NOT_ALLOWED (1ULL << 7)
#define PARALLAX_AIW_REASON_NOTIONAL_LIMIT_EXCEEDED (1ULL << 8)
#define PARALLAX_AIW_REASON_DAILY_LIMIT_EXCEEDED (1ULL << 9)
#define PARALLAX_AIW_REASON_HUMAN_APPROVAL_REQUIRED (1ULL << 10)
#define PARALLAX_AIW_REASON_MISSING_HUMAN_APPROVAL (1ULL << 11)
#define PARALLAX_AIW_REASON_INVALID_AMOUNT (1ULL << 12)
#define PARALLAX_AIW_REASON_INVALID_PRICE (1ULL << 13)
#define PARALLAX_AIW_REASON_INVALID_ARGUMENT (1ULL << 14)

typedef enum parallax_aiw_result {
  PARALLAX_AIW_OK = 0,
  PARALLAX_AIW_ERROR_NULL = 1,
  PARALLAX_AIW_ERROR_INVALID = 2,
  PARALLAX_AIW_ERROR_BUFFER = 3
} parallax_aiw_result;

typedef enum parallax_aiw_mode {
  PARALLAX_AIW_MODE_PAPER = 0,
  PARALLAX_AIW_MODE_TESTNET = 1,
  PARALLAX_AIW_MODE_RESTRICTED_LIVE = 2,
  PARALLAX_AIW_MODE_LIVE = 3
} parallax_aiw_mode;

typedef enum parallax_aiw_status {
  PARALLAX_AIW_STATUS_ACTIVE = 0,
  PARALLAX_AIW_STATUS_PAUSED = 1,
  PARALLAX_AIW_STATUS_HALTED = 2,
  PARALLAX_AIW_STATUS_RETIRED = 3
} parallax_aiw_status;

typedef enum parallax_aiw_command_kind {
  PARALLAX_AIW_COMMAND_TRANSFER = 0,
  PARALLAX_AIW_COMMAND_ORDER = 1,
  PARALLAX_AIW_COMMAND_RESEARCH_MINT = 2,
  PARALLAX_AIW_COMMAND_APPROVE_SIGNAL = 3,
  PARALLAX_AIW_COMMAND_CANCEL_ORDER = 4,
  PARALLAX_AIW_COMMAND_OPERATOR_NOTE = 5
} parallax_aiw_command_kind;

typedef enum parallax_aiw_decision {
  PARALLAX_AIW_DECISION_APPROVED = 0,
  PARALLAX_AIW_DECISION_REJECTED = 1,
  PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL = 2
} parallax_aiw_decision;

typedef struct parallax_aiw_policy {
  char policy_id[PARALLAX_AIW_MAX_TEXT];
  char version[PARALLAX_AIW_MAX_TEXT];
  uint32_t allowed_modes_mask;
  uint32_t allowed_command_kinds_mask;
  char allowed_assets[PARALLAX_AIW_MAX_ASSETS][PARALLAX_AIW_MAX_TEXT];
  size_t allowed_asset_count;
  char allowed_counterparties[PARALLAX_AIW_MAX_COUNTERPARTIES][PARALLAX_AIW_MAX_TEXT];
  size_t allowed_counterparty_count;
  double max_command_notional;
  double daily_notional_limit;
  double require_human_approval_above;
  uint32_t require_human_approval_kinds_mask;
  int live_mode_blocked;
} parallax_aiw_policy;

typedef struct parallax_aiw_wallet_config {
  const char *agent_id;
  const char *display_name;
  const char *owner_principal;
  const char *controller_principal;
  const char *created_at;
  parallax_aiw_mode mode;
  const parallax_aiw_policy *policy;
} parallax_aiw_wallet_config;

typedef struct parallax_aiw_wallet {
  char wallet_id[PARALLAX_AIW_MAX_TEXT];
  char agent_id[PARALLAX_AIW_MAX_TEXT];
  char display_name[PARALLAX_AIW_MAX_TEXT];
  char owner_principal[PARALLAX_AIW_MAX_TEXT];
  char controller_principal[PARALLAX_AIW_MAX_TEXT];
  char created_at[PARALLAX_AIW_MAX_TEXT];
  char updated_at[PARALLAX_AIW_MAX_TEXT];
  parallax_aiw_status status;
  parallax_aiw_mode mode;
  parallax_aiw_policy policy;
} parallax_aiw_wallet;

typedef struct parallax_aiw_command {
  char command_id[PARALLAX_AIW_MAX_TEXT];
  char wallet_id[PARALLAX_AIW_MAX_TEXT];
  char agent_id[PARALLAX_AIW_MAX_TEXT];
  char asset[PARALLAX_AIW_MAX_TEXT];
  char counterparty[PARALLAX_AIW_MAX_TEXT];
  char requested_by[PARALLAX_AIW_MAX_TEXT];
  char human_approval_id[PARALLAX_AIW_MAX_TEXT];
  char memo[PARALLAX_AIW_MAX_TEXT];
  char created_at[PARALLAX_AIW_MAX_TEXT];
  parallax_aiw_command_kind kind;
  parallax_aiw_mode mode;
  double amount;
  double price;
  int has_price;
} parallax_aiw_command;

typedef struct parallax_aiw_evaluation {
  parallax_aiw_decision decision;
  uint64_t reason_bits;
  double command_notional;
  double projected_daily_notional;
  char policy_id[PARALLAX_AIW_MAX_TEXT];
  char policy_version[PARALLAX_AIW_MAX_TEXT];
  char evaluated_at[PARALLAX_AIW_MAX_TEXT];
} parallax_aiw_evaluation;

typedef struct parallax_aiw_receipt {
  char receipt_id[PARALLAX_AIW_MAX_TEXT];
  char wallet_id[PARALLAX_AIW_MAX_TEXT];
  char agent_id[PARALLAX_AIW_MAX_TEXT];
  char actor[PARALLAX_AIW_MAX_TEXT];
  char command_id[PARALLAX_AIW_MAX_TEXT];
  char payload_hash[PARALLAX_AIW_MAX_RECEIPT_HASH];
  char previous_receipt_id[PARALLAX_AIW_MAX_TEXT];
  char created_at[PARALLAX_AIW_MAX_TEXT];
  parallax_aiw_mode mode;
  parallax_aiw_decision decision;
  uint64_t reason_bits;
} parallax_aiw_receipt;

const char *parallax_aiw_version(void);
const char *parallax_aiw_result_name(parallax_aiw_result result);
const char *parallax_aiw_mode_name(parallax_aiw_mode mode);
const char *parallax_aiw_status_name(parallax_aiw_status status);
const char *parallax_aiw_command_kind_name(parallax_aiw_command_kind kind);
const char *parallax_aiw_decision_name(parallax_aiw_decision decision);

void parallax_aiw_default_policy(parallax_aiw_policy *out_policy);
parallax_aiw_result parallax_aiw_create_wallet(const parallax_aiw_wallet_config *config, parallax_aiw_wallet *out_wallet);
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
                                              parallax_aiw_command *out_command);
parallax_aiw_result parallax_aiw_evaluate_command(const parallax_aiw_wallet *wallet,
                                                  const parallax_aiw_command *command,
                                                  double daily_notional_used,
                                                  const char *evaluated_at,
                                                  parallax_aiw_evaluation *out_evaluation);
parallax_aiw_result parallax_aiw_make_receipt(const parallax_aiw_wallet *wallet,
                                              const parallax_aiw_command *command,
                                              const parallax_aiw_evaluation *evaluation,
                                              const char *actor,
                                              const char *previous_receipt_id,
                                              parallax_aiw_receipt *out_receipt);
int parallax_aiw_has_reason(const parallax_aiw_evaluation *evaluation, uint64_t reason_bit);
int parallax_aiw_receipt_links_to(const parallax_aiw_receipt *receipt, const parallax_aiw_receipt *previous);

#ifdef __cplusplus
}
#endif

#endif
