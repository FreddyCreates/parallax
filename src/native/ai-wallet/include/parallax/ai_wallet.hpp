#ifndef PARALLAX_AI_WALLET_HPP
#define PARALLAX_AI_WALLET_HPP

#include "parallax/ai_wallet.h"

#include <stdexcept>
#include <string>
#include <utility>

namespace parallax::ai_wallet {

class Error final : public std::runtime_error {
 public:
  explicit Error(parallax_aiw_result result)
      : std::runtime_error(parallax_aiw_result_name(result)), result_(result) {}

  [[nodiscard]] parallax_aiw_result result() const noexcept { return result_; }

 private:
  parallax_aiw_result result_;
};

inline void check(parallax_aiw_result result) {
  if (result != PARALLAX_AIW_OK) {
    throw Error(result);
  }
}

class Policy final {
 public:
  Policy() { parallax_aiw_default_policy(&policy_); }
  explicit Policy(parallax_aiw_policy policy) : policy_(policy) {}

  [[nodiscard]] const parallax_aiw_policy *c_ptr() const noexcept { return &policy_; }
  [[nodiscard]] parallax_aiw_policy *c_ptr() noexcept { return &policy_; }
  [[nodiscard]] const parallax_aiw_policy &get() const noexcept { return policy_; }

 private:
  parallax_aiw_policy policy_{};
};

class Command final {
 public:
  explicit Command(parallax_aiw_command command) : command_(command) {}

  [[nodiscard]] const parallax_aiw_command &get() const noexcept { return command_; }
  [[nodiscard]] const parallax_aiw_command *c_ptr() const noexcept { return &command_; }
  [[nodiscard]] std::string id() const { return command_.command_id; }
  [[nodiscard]] std::string asset() const { return command_.asset; }
  [[nodiscard]] double amount() const noexcept { return command_.amount; }

 private:
  parallax_aiw_command command_{};
};

class Evaluation final {
 public:
  explicit Evaluation(parallax_aiw_evaluation evaluation) : evaluation_(evaluation) {}

  [[nodiscard]] const parallax_aiw_evaluation &get() const noexcept { return evaluation_; }
  [[nodiscard]] const parallax_aiw_evaluation *c_ptr() const noexcept { return &evaluation_; }
  [[nodiscard]] parallax_aiw_decision decision() const noexcept { return evaluation_.decision; }
  [[nodiscard]] std::string decision_name() const { return parallax_aiw_decision_name(evaluation_.decision); }
  [[nodiscard]] bool has_reason(uint64_t reason) const noexcept {
    return parallax_aiw_has_reason(&evaluation_, reason) != 0;
  }
  [[nodiscard]] double command_notional() const noexcept { return evaluation_.command_notional; }

 private:
  parallax_aiw_evaluation evaluation_{};
};

class Receipt final {
 public:
  explicit Receipt(parallax_aiw_receipt receipt) : receipt_(receipt) {}

  [[nodiscard]] const parallax_aiw_receipt &get() const noexcept { return receipt_; }
  [[nodiscard]] std::string id() const { return receipt_.receipt_id; }
  [[nodiscard]] std::string payload_hash() const { return receipt_.payload_hash; }
  [[nodiscard]] bool links_to(const Receipt &previous) const noexcept {
    return parallax_aiw_receipt_links_to(&receipt_, &previous.receipt_) != 0;
  }

 private:
  parallax_aiw_receipt receipt_{};
};

class Wallet final {
 public:
  Wallet(std::string agent_id,
         std::string display_name,
         std::string owner_principal,
         std::string controller_principal,
         std::string created_at,
         parallax_aiw_mode mode = PARALLAX_AIW_MODE_PAPER,
         const Policy &policy = Policy()) {
    parallax_aiw_wallet_config config{};
    config.agent_id = agent_id.c_str();
    config.display_name = display_name.c_str();
    config.owner_principal = owner_principal.c_str();
    config.controller_principal = controller_principal.c_str();
    config.created_at = created_at.c_str();
    config.mode = mode;
    config.policy = policy.c_ptr();
    check(parallax_aiw_create_wallet(&config, &wallet_));
  }

  explicit Wallet(parallax_aiw_wallet wallet) : wallet_(wallet) {}

  [[nodiscard]] const parallax_aiw_wallet &get() const noexcept { return wallet_; }
  [[nodiscard]] const parallax_aiw_wallet *c_ptr() const noexcept { return &wallet_; }
  [[nodiscard]] parallax_aiw_wallet *c_ptr() noexcept { return &wallet_; }
  [[nodiscard]] std::string id() const { return wallet_.wallet_id; }
  [[nodiscard]] std::string agent_id() const { return wallet_.agent_id; }
  [[nodiscard]] std::string mode_name() const { return parallax_aiw_mode_name(wallet_.mode); }

  [[nodiscard]] Command make_command(parallax_aiw_command_kind kind,
                                     std::string asset,
                                     double amount,
                                     double price,
                                     bool has_price,
                                     std::string counterparty,
                                     std::string requested_by,
                                     std::string human_approval_id,
                                     std::string memo,
                                     std::string created_at) const {
    parallax_aiw_command command{};
    check(parallax_aiw_make_command(&wallet_, kind, asset.c_str(), amount, price, has_price ? 1 : 0,
                                    counterparty.c_str(), requested_by.c_str(), human_approval_id.c_str(),
                                    memo.c_str(), created_at.c_str(), &command));
    return Command(command);
  }

  [[nodiscard]] Command make_paper_order(std::string asset,
                                         double amount,
                                         double price,
                                         std::string requested_by,
                                         std::string human_approval_id,
                                         std::string created_at) const {
    return make_command(PARALLAX_AIW_COMMAND_ORDER, std::move(asset), amount, price, true, "paper-market",
                        std::move(requested_by), std::move(human_approval_id), "paper order", std::move(created_at));
  }

  [[nodiscard]] Evaluation evaluate(const Command &command,
                                    double daily_notional_used,
                                    std::string evaluated_at) const {
    parallax_aiw_evaluation evaluation{};
    check(parallax_aiw_evaluate_command(&wallet_, command.c_ptr(), daily_notional_used, evaluated_at.c_str(), &evaluation));
    return Evaluation(evaluation);
  }

  [[nodiscard]] Receipt make_receipt(const Command &command,
                                     const Evaluation &evaluation,
                                     std::string actor,
                                     std::string previous_receipt_id = {}) const {
    parallax_aiw_receipt receipt{};
    check(parallax_aiw_make_receipt(&wallet_, command.c_ptr(), evaluation.c_ptr(), actor.c_str(),
                                    previous_receipt_id.c_str(), &receipt));
    return Receipt(receipt);
  }

 private:
  parallax_aiw_wallet wallet_{};
};

}  // namespace parallax::ai_wallet

#endif
