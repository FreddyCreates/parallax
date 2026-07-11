import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

import Bench "Bench";
import Policy "Policy";
import Receipts "Receipts";
import Types "Types";

actor AiWalletLedger {
  stable var wallets : [Types.AiWallet] = [];
  stable var policies : [Types.AiWalletPolicy] = [Policy.defaultPolicy()];
  stable var commands : [Types.AiWalletCommand] = [];
  stable var evaluations : [Types.AiWalletPolicyEvaluation] = [];
  stable var receipts : [Types.AiWalletReceipt] = [];
  stable var dailyUsages : [Types.AiWalletDailyUsage] = [];
  stable var benchmarkReceipts : [Types.BenchmarkReceipt] = [];
  stable var sequence : Nat = 0;

  let version : Types.Version = {
    name = "parallax-ai-wallet-ledger";
    version = "0.2.0-alpha.0";
    schema = "parallax.ai_wallet_ledger.v1";
    build = "icp-motoko-production-code-no-typescript";
  };

  private func now() : Int { Time.now() };

  private func next(prefix : Text) : Text {
    sequence += 1;
    prefix # ":" # Nat.toText(sequence)
  };

  private func today(t : Int) : Text {
    Int.toText(t / 86_400_000_000_000)
  };

  private func page<T>(items : [T], cursor : ?Nat, limit : ?Nat) : Types.Page<T> {
    let start = switch (cursor) { case (?c) c; case null 0 };
    let requested = switch (limit) { case (?l) l; case null 50 };
    let capped = if (requested > 100) 100 else requested;
    let total = items.size();
    if (start >= total) return { items = []; nextCursor = null; total = total };
    var selected : [T] = [];
    var i = start;
    while (i < total and selected.size() < capped) {
      selected := Array.append<T>(selected, [items[i]]);
      i += 1;
    };
    let nextCursor = if (i < total) ?i else null;
    { items = selected; nextCursor = nextCursor; total = total }
  };

  private func findWallet(walletId : Text) : ?Types.AiWallet {
    Array.find<Types.AiWallet>(wallets, func(wallet) { wallet.walletId == walletId })
  };

  private func findPolicy(policyId : Text) : ?Types.AiWalletPolicy {
    Array.find<Types.AiWalletPolicy>(policies, func(policy) { policy.policyId == policyId })
  };

  private func findCommand(commandId : Text) : ?Types.AiWalletCommand {
    Array.find<Types.AiWalletCommand>(commands, func(command) { command.commandId == commandId })
  };

  private func latestReceiptId(walletId : Text) : ?Text {
    var latest : ?Text = null;
    for (receipt in receipts.vals()) {
      if (receipt.walletId == walletId) latest := ?receipt.receiptId;
    };
    latest
  };

  private func putWallet(updated : Types.AiWallet) {
    wallets := Array.map<Types.AiWallet, Types.AiWallet>(
      wallets,
      func(wallet) { if (wallet.walletId == updated.walletId) updated else wallet }
    );
  };

  private func putDailyUsage(updated : Types.AiWalletDailyUsage) {
    var replaced = false;
    dailyUsages := Array.map<Types.AiWalletDailyUsage, Types.AiWalletDailyUsage>(
      dailyUsages,
      func(usage) {
        if (usage.walletId == updated.walletId and usage.day == updated.day and usage.mode == updated.mode) {
          replaced := true;
          updated
        } else usage
      }
    );
    if (not replaced) dailyUsages := Array.append<Types.AiWalletDailyUsage>(dailyUsages, [updated]);
  };

  private func getUsage(walletId : Text, mode : Types.NetworkMode, day : Text) : ?Types.AiWalletDailyUsage {
    Array.find<Types.AiWalletDailyUsage>(
      dailyUsages,
      func(usage) { usage.walletId == walletId and usage.mode == mode and usage.day == day }
    )
  };

  private func appendReceipt(receipt : Types.AiWalletReceipt) : Types.AiWalletReceipt {
    receipts := Array.append<Types.AiWalletReceipt>(receipts, [receipt]);
    receipt
  };

  private func evaluateCommandInternal(command : Types.AiWalletCommand, actorPrincipal : Principal) : Types.Result<Types.AiWalletPolicyEvaluation> {
    switch (findWallet(command.walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        let policy = switch (findPolicy(wallet.policyId)) {
          case (?p) p;
          case null Policy.defaultPolicy();
        };
        let t = now();
        let day = today(t);
        let currentUsage = getUsage(wallet.walletId, command.mode, day);
        let evaluation = Policy.evaluate(wallet, policy, command, currentUsage, t);
        evaluations := Array.append<Types.AiWalletPolicyEvaluation>(evaluations, [evaluation]);

        if (evaluation.decision == #approved) {
          let prior = switch (currentUsage) {
            case (?u) u;
            case null {
              walletId = wallet.walletId;
              mode = command.mode;
              day = day;
              notionalUsedE8s = 0;
              commandCount = 0;
              updatedAt = t;
            };
          };
          putDailyUsage({
            walletId = prior.walletId;
            mode = prior.mode;
            day = prior.day;
            notionalUsedE8s = prior.notionalUsedE8s + evaluation.commandNotionalE8s;
            commandCount = prior.commandCount + 1;
            updatedAt = t;
          });
        };

        let receipt = Receipts.makeEvaluationReceipt(wallet, command, evaluation, actorPrincipal, latestReceiptId(wallet.walletId));
        ignore appendReceipt(receipt);
        #ok(evaluation)
      };
    }
  };

  public query func getVersion() : async Types.Version { version };

  public shared ({ caller }) func createAiWallet(input : Types.CreateAiWalletInput) : async Types.Result<Types.AiWallet> {
    let t = now();
    let policy = switch (input.policy) {
      case (?customPolicy) {
        policies := Array.append<Types.AiWalletPolicy>(policies, [customPolicy]);
        customPolicy
      };
      case null Policy.defaultPolicy();
    };

    if (not Policy.containsMode(policy.allowedModes, input.mode)) return #err([#mode_not_allowed]);
    switch (input.mode) {
      case (#live) return #err([#live_mode_blocked, #live_money_movement_blocked, #live_broker_routing_blocked, #autonomous_live_ai_trading_blocked]);
      case (#restricted_live) return #err([#live_mode_blocked, #live_money_movement_blocked, #live_broker_routing_blocked, #autonomous_live_ai_trading_blocked]);
      case (_) {};
    };

    let wallet : Types.AiWallet = {
      walletId = next("aiw");
      agentId = input.agentId;
      displayName = input.displayName;
      ownerPrincipal = input.ownerPrincipal;
      controllerPrincipal = input.controllerPrincipal;
      status = #active;
      mode = input.mode;
      policyId = policy.policyId;
      createdAt = t;
      updatedAt = t;
      metadata = input.metadata;
    };

    wallets := Array.append<Types.AiWallet>(wallets, [wallet]);
    ignore appendReceipt(Receipts.makeCreatedReceipt(wallet, caller, latestReceiptId(wallet.walletId), t));
    #ok(wallet)
  };

  public query func getAiWallet(walletId : Text) : async ?Types.AiWallet { findWallet(walletId) };

  public query func listAiWallets(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWallet> {
    page<Types.AiWallet>(wallets, cursor, limit)
  };

  public query func getControlTowerAiWallets(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWallet> {
    page<Types.AiWallet>(wallets, cursor, limit)
  };

  public query func listAiWalletPolicies(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletPolicy> {
    page<Types.AiWalletPolicy>(policies, cursor, limit)
  };

  public shared ({ caller }) func pauseAiWallet(walletId : Text, reason : Text) : async Types.Result<Types.AiWallet> {
    switch (findWallet(walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        let t = now();
        let updated = { wallet with status = #paused; updatedAt = t };
        putWallet(updated);
        ignore appendReceipt(Receipts.makeStatusReceipt(updated, caller, #ai_wallet_paused, reason, latestReceiptId(walletId), t));
        #ok(updated)
      };
    }
  };

  public shared ({ caller }) func resumeAiWallet(walletId : Text, reason : Text) : async Types.Result<Types.AiWallet> {
    switch (findWallet(walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        let t = now();
        let updated = { wallet with status = #active; updatedAt = t };
        putWallet(updated);
        ignore appendReceipt(Receipts.makeStatusReceipt(updated, caller, #ai_wallet_resumed, reason, latestReceiptId(walletId), t));
        #ok(updated)
      };
    }
  };

  public shared ({ caller }) func haltAiWallet(walletId : Text, reason : Text) : async Types.Result<Types.AiWallet> {
    switch (findWallet(walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        let t = now();
        let updated = { wallet with status = #halted; updatedAt = t };
        putWallet(updated);
        ignore appendReceipt(Receipts.makeStatusReceipt(updated, caller, #ai_wallet_halted, reason, latestReceiptId(walletId), t));
        #ok(updated)
      };
    }
  };

  public shared func submitAiWalletCommand(command : Types.AiWalletCommand) : async Types.Result<Types.AiWalletCommand> {
    switch (findWallet(command.walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        if (wallet.agentId != command.agentId) return #err([#not_found]);
        commands := Array.append<Types.AiWalletCommand>(commands, [command]);
        #ok(command)
      };
    }
  };

  public shared ({ caller }) func pipeAiSignalApprovalToPaperOrder(
    walletId : Text,
    signalId : Text,
    asset : Text,
    amount : Nat,
    priceE8s : Nat,
    humanApprovalId : ?Text
  ) : async Types.Result<Types.AiWalletPolicyEvaluation> {
    switch (findWallet(walletId)) {
      case null #err([#not_found]);
      case (?wallet) {
        let t = now();
        let command : Types.AiWalletCommand = {
          commandId = next("aiwcmd");
          walletId = wallet.walletId;
          agentId = wallet.agentId;
          kind = #order;
          mode = #paper;
          asset = asset;
          amount = amount;
          priceE8s = ?priceE8s;
          counterparty = ?"paper-market";
          requestedBy = caller;
          humanApprovalId = humanApprovalId;
          approvedBy = ?caller;
          memo = ?("ai-signal:" # signalId);
          createdAt = t;
        };
        commands := Array.append<Types.AiWalletCommand>(commands, [command]);
        evaluateCommandInternal(command, caller)
      };
    }
  };

  public shared ({ caller }) func evaluateAiWalletCommand(commandId : Text) : async Types.Result<Types.AiWalletPolicyEvaluation> {
    switch (findCommand(commandId)) {
      case null #err([#not_found]);
      case (?command) evaluateCommandInternal(command, caller);
    }
  };

  public query func getAiWalletCommand(commandId : Text) : async ?Types.AiWalletCommand {
    findCommand(commandId)
  };

  public query func listAiWalletCommands(walletId : Text, cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletCommand> {
    let filtered = Array.filter<Types.AiWalletCommand>(commands, func(command) { command.walletId == walletId });
    page<Types.AiWalletCommand>(filtered, cursor, limit)
  };

  public query func getAiWalletEvaluation(commandId : Text) : async ?Types.AiWalletPolicyEvaluation {
    Array.find<Types.AiWalletPolicyEvaluation>(evaluations, func(evaluation) { evaluation.commandId == commandId })
  };

  public query func listAiWalletEvaluations(walletId : Text, cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletPolicyEvaluation> {
    let filtered = Array.filter<Types.AiWalletPolicyEvaluation>(evaluations, func(evaluation) { evaluation.walletId == walletId });
    page<Types.AiWalletPolicyEvaluation>(filtered, cursor, limit)
  };

  public shared func appendAiWalletReceipt(receipt : Types.AiWalletReceipt) : async Types.AiWalletReceipt {
    appendReceipt(receipt)
  };

  public query func listAiWalletReceipts(walletId : Text, cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletReceipt> {
    let filtered = Array.filter<Types.AiWalletReceipt>(receipts, func(receipt) { receipt.walletId == walletId });
    page<Types.AiWalletReceipt>(filtered, cursor, limit)
  };

  public query func listGlobalReceipts(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletReceipt> {
    page<Types.AiWalletReceipt>(receipts, cursor, limit)
  };

  public query func getAiWalletDailyUsage(walletId : Text, mode : Types.NetworkMode, day : Text) : async ?Types.AiWalletDailyUsage {
    getUsage(walletId, mode, day)
  };

  public query func listAiWalletDailyUsage(walletId : Text, cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.AiWalletDailyUsage> {
    let filtered = Array.filter<Types.AiWalletDailyUsage>(dailyUsages, func(usage) { usage.walletId == walletId });
    page<Types.AiWalletDailyUsage>(filtered, cursor, limit)
  };

  public shared func recordBenchmark(input : Types.BenchmarkInput) : async Types.BenchmarkReceipt {
    let receipt = Bench.record(input, now());
    benchmarkReceipts := Array.append<Types.BenchmarkReceipt>(benchmarkReceipts, [receipt]);
    receipt
  };

  public query func listBenchmarks(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.BenchmarkReceipt> {
    page<Types.BenchmarkReceipt>(benchmarkReceipts, cursor, limit)
  };
}
