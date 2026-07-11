import Array "mo:base/Array";
import Types "Types";

module {
  public func defaultPolicy() : Types.AiWalletPolicy {
    {
      policyId = "parallax-ai-wallet-icp-alpha-policy";
      version = "0.2.0-alpha.0";
      allowedModes = [#paper, #testnet];
      allowedCommandKinds = [#transfer, #order, #research_mint, #approve_signal, #cancel_order, #operator_note];
      allowedAssets = ["PXUSD", "PXICP", "PXAI", "PXGPU", "PXETH", "PXCRED"];
      allowedCounterparties = ["internal", "paper-market", "research-mint", "operator", "agent-credit-ledger"];
      maxCommandNotional = 1_000_000_000_000;
      dailyNotionalLimit = 5_000_000_000_000;
      requireHumanApprovalAbove = 250_000_000_000;
      requireHumanApprovalFor = [#transfer, #order];
      scopes = [
        {
          id = "paper-trade";
          description = "Paper-market order flow only.";
          allowedCommandKinds = [#order, #cancel_order, #approve_signal];
          allowedAssets = ["PXUSD", "PXICP", "PXAI", "PXGPU", "PXETH"];
          maxCommandNotional = 1_000_000_000_000;
          dailyNotionalLimit = 5_000_000_000_000;
          requireHumanApprovalAbove = 250_000_000_000;
        },
        {
          id = "research-mint";
          description = "Research artifact receipt creation only.";
          allowedCommandKinds = [#research_mint, #operator_note];
          allowedAssets = ["PXAI", "PXCRED"];
          maxCommandNotional = 100_000_000_000;
          dailyNotionalLimit = 1_000_000_000_000;
          requireHumanApprovalAbove = 50_000_000_000;
        },
        {
          id = "internal-pay";
          description = "Internal paper/testnet transfer workflows only.";
          allowedCommandKinds = [#transfer];
          allowedAssets = ["PXUSD", "PXICP", "PXCRED"];
          maxCommandNotional = 500_000_000_000;
          dailyNotionalLimit = 2_500_000_000_000;
          requireHumanApprovalAbove = 100_000_000_000;
        }
      ];
      liveModeBlocked = true;
      liveMoneyMovementBlocked = true;
      liveBrokerRoutingBlocked = true;
      custodyPrivateKeysBlocked = true;
      autonomousLiveAiTradingBlocked = true;
      aiSelfApprovalAboveThresholdBlocked = true;
    }
  };

  public func containsMode(xs : [Types.NetworkMode], x : Types.NetworkMode) : Bool {
    switch (Array.find<Types.NetworkMode>(xs, func(item) { item == x })) {
      case (?_) true;
      case null false;
    }
  };

  public func containsKind(xs : [Types.CommandKind], x : Types.CommandKind) : Bool {
    switch (Array.find<Types.CommandKind>(xs, func(item) { item == x })) {
      case (?_) true;
      case null false;
    }
  };

  public func containsText(xs : [Text], x : Text) : Bool {
    switch (Array.find<Text>(xs, func(item) { item == x })) {
      case (?_) true;
      case null false;
    }
  };

  public func notionalE8s(command : Types.AiWalletCommand) : Types.Result<Nat> {
    if (command.amount == 0) return #err([#invalid_amount]);
    switch (command.kind, command.priceE8s) {
      case (#order, null) #err([#invalid_price]);
      case (#order, ?price) {
        if (price == 0) #err([#invalid_price]) else #ok(command.amount * price / 100_000_000);
      };
      case (_, _) #ok(command.amount);
    }
  };

  private func pushUnique(xs : [Types.ReasonCode], x : Types.ReasonCode) : [Types.ReasonCode] {
    switch (Array.find<Types.ReasonCode>(xs, func(item) { item == x })) {
      case (?_) xs;
      case null Array.append<Types.ReasonCode>(xs, [x]);
    }
  };

  private func isRejectReason(reason : Types.ReasonCode) : Bool {
    switch (reason) {
      case (#wallet_halted) true;
      case (#wallet_paused) true;
      case (#mode_not_allowed) true;
      case (#live_mode_blocked) true;
      case (#command_kind_not_allowed) true;
      case (#asset_not_allowed) true;
      case (#counterparty_not_allowed) true;
      case (#notional_limit_exceeded) true;
      case (#daily_limit_exceeded) true;
      case (#missing_human_approval) true;
      case (#invalid_amount) true;
      case (#invalid_price) true;
      case (#ai_self_approval_blocked) true;
      case (#live_money_movement_blocked) true;
      case (#live_broker_routing_blocked) true;
      case (#custody_private_keys_blocked) true;
      case (#autonomous_live_ai_trading_blocked) true;
      case (#not_found) true;
      case (_) false;
    }
  };

  private func decide(reasons : [Types.ReasonCode]) : Types.Decision {
    switch (Array.find<Types.ReasonCode>(reasons, isRejectReason)) {
      case (?_) #rejected;
      case null {
        switch (Array.find<Types.ReasonCode>(reasons, func(reason) { reason == #human_approval_required })) {
          case (?_) #requires_human_approval;
          case null #approved;
        }
      };
    }
  };

  public func evaluate(
    wallet : Types.AiWallet,
    policy : Types.AiWalletPolicy,
    command : Types.AiWalletCommand,
    dailyUsage : ?Types.AiWalletDailyUsage,
    now : Int,
  ) : Types.AiWalletPolicyEvaluation {
    var reasons : [Types.ReasonCode] = [];
    var commandNotional : Nat = 0;

    switch (wallet.status) {
      case (#halted) reasons := pushUnique(reasons, #wallet_halted);
      case (#paused) reasons := pushUnique(reasons, #wallet_paused);
      case (_) {};
    };

    if (not containsMode(policy.allowedModes, command.mode)) reasons := pushUnique(reasons, #mode_not_allowed);

    switch (command.mode) {
      case (#live) {
        if (policy.liveModeBlocked) reasons := pushUnique(reasons, #live_mode_blocked);
        if (policy.liveMoneyMovementBlocked) reasons := pushUnique(reasons, #live_money_movement_blocked);
        if (policy.liveBrokerRoutingBlocked) reasons := pushUnique(reasons, #live_broker_routing_blocked);
        if (policy.autonomousLiveAiTradingBlocked) reasons := pushUnique(reasons, #autonomous_live_ai_trading_blocked);
      };
      case (#restricted_live) {
        if (policy.liveModeBlocked) reasons := pushUnique(reasons, #live_mode_blocked);
        if (policy.liveMoneyMovementBlocked) reasons := pushUnique(reasons, #live_money_movement_blocked);
        if (policy.liveBrokerRoutingBlocked) reasons := pushUnique(reasons, #live_broker_routing_blocked);
        if (policy.autonomousLiveAiTradingBlocked) reasons := pushUnique(reasons, #autonomous_live_ai_trading_blocked);
      };
      case (_) {};
    };

    if (not containsKind(policy.allowedCommandKinds, command.kind)) reasons := pushUnique(reasons, #command_kind_not_allowed);
    if (not containsText(policy.allowedAssets, command.asset)) reasons := pushUnique(reasons, #asset_not_allowed);

    switch (command.counterparty) {
      case (?counterparty) {
        if (not containsText(policy.allowedCounterparties, counterparty)) reasons := pushUnique(reasons, #counterparty_not_allowed);
      };
      case null {};
    };

    switch (notionalE8s(command)) {
      case (#ok(n)) { commandNotional := n };
      case (#err(errs)) {
        for (err in errs.vals()) { reasons := pushUnique(reasons, err) };
      };
    };

    if (commandNotional > policy.maxCommandNotional) reasons := pushUnique(reasons, #notional_limit_exceeded);

    let used = switch (dailyUsage) { case (?usage) usage.notionalUsedE8s; case null 0 };
    let projected = used + commandNotional;
    if (projected > policy.dailyNotionalLimit) reasons := pushUnique(reasons, #daily_limit_exceeded);

    let approvalRequiredByKind = containsKind(policy.requireHumanApprovalFor, command.kind);
    let approvalRequiredByAmount = commandNotional >= policy.requireHumanApprovalAbove;
    if (approvalRequiredByKind or approvalRequiredByAmount) {
      switch (command.humanApprovalId, command.approvedBy) {
        case (?approvalId, ?approver) {
          if (approvalId == "") reasons := pushUnique(reasons, #missing_human_approval);
          if (policy.aiSelfApprovalAboveThresholdBlocked and approver == command.requestedBy and approvalRequiredByAmount) {
            reasons := pushUnique(reasons, #ai_self_approval_blocked);
          };
        };
        case (_) reasons := pushUnique(reasons, #human_approval_required);
      };
    };

    if (reasons.size() == 0) reasons := [#valid];

    {
      evaluationId = "eval:" # command.commandId;
      commandId = command.commandId;
      walletId = command.walletId;
      decision = decide(reasons);
      reasonCodes = reasons;
      commandNotionalE8s = commandNotional;
      projectedDailyNotionalE8s = projected;
      policyId = policy.policyId;
      policyVersion = policy.version;
      evaluatedAt = now;
    }
  };
}
