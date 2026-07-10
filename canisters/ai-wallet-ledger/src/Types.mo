module {
  public type Version = {
    name : Text;
    version : Text;
    schema : Text;
    build : Text;
  };

  public type NetworkMode = {
    #paper;
    #testnet;
    #restricted_live;
    #live;
  };

  public type WalletStatus = {
    #active;
    #paused;
    #halted;
    #retired;
  };

  public type CommandKind = {
    #transfer;
    #order;
    #research_mint;
    #approve_signal;
    #cancel_order;
    #operator_note;
  };

  public type Decision = {
    #approved;
    #rejected;
    #requires_human_approval;
  };

  public type ReasonCode = {
    #valid;
    #wallet_halted;
    #wallet_paused;
    #mode_not_allowed;
    #live_mode_blocked;
    #command_kind_not_allowed;
    #asset_not_allowed;
    #counterparty_not_allowed;
    #notional_limit_exceeded;
    #daily_limit_exceeded;
    #human_approval_required;
    #missing_human_approval;
    #invalid_amount;
    #invalid_price;
    #ai_self_approval_blocked;
    #live_money_movement_blocked;
    #live_broker_routing_blocked;
    #custody_private_keys_blocked;
    #autonomous_live_ai_trading_blocked;
    #not_found;
  };

  public type Scope = {
    id : Text;
    description : Text;
    allowedCommandKinds : [CommandKind];
    allowedAssets : [Text];
    maxCommandNotional : Nat;
    dailyNotionalLimit : Nat;
    requireHumanApprovalAbove : Nat;
  };

  public type AiWalletPolicy = {
    policyId : Text;
    version : Text;
    allowedModes : [NetworkMode];
    allowedCommandKinds : [CommandKind];
    allowedAssets : [Text];
    allowedCounterparties : [Text];
    maxCommandNotional : Nat;
    dailyNotionalLimit : Nat;
    requireHumanApprovalAbove : Nat;
    requireHumanApprovalFor : [CommandKind];
    scopes : [Scope];
    liveModeBlocked : Bool;
    liveMoneyMovementBlocked : Bool;
    liveBrokerRoutingBlocked : Bool;
    custodyPrivateKeysBlocked : Bool;
    autonomousLiveAiTradingBlocked : Bool;
    aiSelfApprovalAboveThresholdBlocked : Bool;
  };

  public type AiWallet = {
    walletId : Text;
    agentId : Text;
    displayName : Text;
    ownerPrincipal : Principal;
    controllerPrincipal : Principal;
    status : WalletStatus;
    mode : NetworkMode;
    policyId : Text;
    createdAt : Int;
    updatedAt : Int;
    metadata : [(Text, Text)];
  };

  public type CreateAiWalletInput = {
    agentId : Text;
    displayName : Text;
    ownerPrincipal : Principal;
    controllerPrincipal : Principal;
    mode : NetworkMode;
    policy : ?AiWalletPolicy;
    metadata : [(Text, Text)];
  };

  public type AiWalletCommand = {
    commandId : Text;
    walletId : Text;
    agentId : Text;
    kind : CommandKind;
    mode : NetworkMode;
    asset : Text;
    amount : Nat;
    priceE8s : ?Nat;
    counterparty : ?Text;
    requestedBy : Principal;
    humanApprovalId : ?Text;
    approvedBy : ?Principal;
    memo : ?Text;
    createdAt : Int;
  };

  public type AiWalletPolicyEvaluation = {
    evaluationId : Text;
    commandId : Text;
    walletId : Text;
    decision : Decision;
    reasonCodes : [ReasonCode];
    commandNotionalE8s : Nat;
    projectedDailyNotionalE8s : Nat;
    policyId : Text;
    policyVersion : Text;
    evaluatedAt : Int;
  };

  public type ReceiptKind = {
    #ai_wallet_created;
    #ai_wallet_policy_evaluated;
    #ai_wallet_command_approved;
    #ai_wallet_command_rejected;
    #ai_wallet_human_approval_required;
    #ai_wallet_paused;
    #ai_wallet_resumed;
    #ai_wallet_halted;
    #benchmark_recorded;
  };

  public type AiWalletReceipt = {
    receiptId : Text;
    kind : ReceiptKind;
    walletId : Text;
    agentId : Text;
    actor : Principal;
    mode : NetworkMode;
    commandId : ?Text;
    decision : ?Decision;
    reasonCodes : [ReasonCode];
    payloadHash : Text;
    previousReceiptId : ?Text;
    createdAt : Int;
  };

  public type AiWalletDailyUsage = {
    walletId : Text;
    mode : NetworkMode;
    day : Text;
    notionalUsedE8s : Nat;
    commandCount : Nat;
    updatedAt : Int;
  };

  public type BenchmarkInput = {
    name : Text;
    suite : Text;
    iterations : Nat;
    totalLatencyNanos : Nat;
    maxLatencyNanos : Nat;
    minLatencyNanos : Nat;
    notes : Text;
  };

  public type BenchmarkReceipt = {
    benchmarkId : Text;
    name : Text;
    suite : Text;
    iterations : Nat;
    averageLatencyNanos : Nat;
    maxLatencyNanos : Nat;
    minLatencyNanos : Nat;
    recordedAt : Int;
    notes : Text;
  };

  public type Page<T> = {
    items : [T];
    nextCursor : ?Nat;
    total : Nat;
  };

  public type Result<T> = {
    #ok : T;
    #err : [ReasonCode];
  };
}
