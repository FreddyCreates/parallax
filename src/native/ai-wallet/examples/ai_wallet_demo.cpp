#include "parallax/ai_wallet.hpp"

#include <iostream>

int main() {
  using namespace parallax::ai_wallet;

  const std::string now = "2026-07-09T00:00:00Z";
  Wallet wallet(
      "agent.parallax.native-01",
      "PARALLAX Native AI Wallet",
      "principal-owner",
      "principal-controller",
      now);

  const auto command = wallet.make_paper_order(
      "PXICP",
      100.0,
      30.0,
      "principal-controller",
      "approval-001",
      now);

  const auto evaluation = wallet.evaluate(command, 0.0, now);
  const auto receipt = wallet.make_receipt(command, evaluation, "principal-controller");

  std::cout << "PARALLAX AI Wallet native demo\n";
  std::cout << "wallet_id=" << wallet.id() << "\n";
  std::cout << "mode=" << wallet.mode_name() << "\n";
  std::cout << "command_id=" << command.id() << "\n";
  std::cout << "decision=" << evaluation.decision_name() << "\n";
  std::cout << "notional=" << evaluation.command_notional() << "\n";
  std::cout << "receipt_id=" << receipt.id() << "\n";
  std::cout << "payload_hash=" << receipt.payload_hash() << "\n";

  return evaluation.decision() == PARALLAX_AIW_DECISION_APPROVED ? 0 : 1;
}
