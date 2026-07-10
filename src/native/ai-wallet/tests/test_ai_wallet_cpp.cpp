#include "parallax/ai_wallet.hpp"

#include <cassert>
#include <string>

int main() {
  using namespace parallax::ai_wallet;

  const std::string now = "2026-07-09T00:00:00Z";
  Wallet wallet(
      "agent.parallax.cpp-test",
      "PARALLAX C++ Test Wallet",
      "principal-owner",
      "principal-controller",
      now);

  assert(wallet.id().rfind("aiw_", 0) == 0);
  assert(wallet.mode_name() == "paper");

  const auto approval_required_command = wallet.make_paper_order(
      "PXICP",
      100.0,
      30.0,
      "principal-controller",
      "",
      now);
  const auto approval_required = wallet.evaluate(approval_required_command, 0.0, now);
  assert(approval_required.decision() == PARALLAX_AIW_DECISION_REQUIRES_HUMAN_APPROVAL);
  assert(approval_required.has_reason(PARALLAX_AIW_REASON_HUMAN_APPROVAL_REQUIRED));

  const auto approved_command = wallet.make_paper_order(
      "PXICP",
      100.0,
      30.0,
      "principal-controller",
      "approval-001",
      "2026-07-09T00:00:01Z");
  const auto approved = wallet.evaluate(approved_command, 0.0, "2026-07-09T00:00:01Z");
  assert(approved.decision() == PARALLAX_AIW_DECISION_APPROVED);
  assert(approved.decision_name() == "approved");

  const auto receipt = wallet.make_receipt(approved_command, approved, "principal-controller");
  assert(receipt.id().rfind("aiwrcpt_", 0) == 0);

  const auto second_receipt = wallet.make_receipt(
      approved_command,
      approved,
      "principal-controller",
      receipt.id());
  assert(second_receipt.links_to(receipt));

  return 0;
}
