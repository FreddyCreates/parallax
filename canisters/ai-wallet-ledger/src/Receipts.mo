import Char "mo:base/Char";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Types "Types";

module {
  public func hashText(input : Text) : Text {
    var hash : Nat = 2166136261;
    for (char in input.chars()) {
      hash := (hash + Nat32.toNat(Char.toNat32(char))) * 16777619;
      hash := hash % 4_294_967_296;
    };
    Nat.toText(hash);
  };

  public func receiptKindForDecision(decision : Types.Decision) : Types.ReceiptKind {
    switch (decision) {
      case (#approved) #ai_wallet_command_approved;
      case (#rejected) #ai_wallet_command_rejected;
      case (#requires_human_approval) #ai_wallet_human_approval_required;
    }
  };

  public func makeCreatedReceipt(
    wallet : Types.AiWallet,
    actor : Principal,
    previousReceiptId : ?Text,
    now : Int,
  ) : Types.AiWalletReceipt {
    let payload = wallet.walletId # ":created:" # Principal.toText(actor) # ":" # Int.toText(now);
    let payloadHash = hashText(payload);
    {
      receiptId = "rcpt:" # wallet.walletId # ":created:" # Int.toText(now);
      kind = #ai_wallet_created;
      walletId = wallet.walletId;
      agentId = wallet.agentId;
      actor = actor;
      mode = wallet.mode;
      commandId = null;
      decision = null;
      reasonCodes = [#valid];
      payloadHash = payloadHash;
      previousReceiptId = previousReceiptId;
      createdAt = now;
    }
  };

  public func makeEvaluationReceipt(
    wallet : Types.AiWallet,
    command : Types.AiWalletCommand,
    evaluation : Types.AiWalletPolicyEvaluation,
    actor : Principal,
    previousReceiptId : ?Text,
  ) : Types.AiWalletReceipt {
    let payload = wallet.walletId # ":" # command.commandId # ":" # Principal.toText(actor) # ":" # Int.toText(evaluation.evaluatedAt) # ":" # Nat.toText(evaluation.commandNotionalE8s);
    let payloadHash = hashText(payload);
    {
      receiptId = "rcpt:" # wallet.walletId # ":" # command.commandId # ":" # Int.toText(evaluation.evaluatedAt);
      kind = receiptKindForDecision(evaluation.decision);
      walletId = wallet.walletId;
      agentId = wallet.agentId;
      actor = actor;
      mode = command.mode;
      commandId = ?command.commandId;
      decision = ?evaluation.decision;
      reasonCodes = evaluation.reasonCodes;
      payloadHash = payloadHash;
      previousReceiptId = previousReceiptId;
      createdAt = evaluation.evaluatedAt;
    }
  };

  public func makeStatusReceipt(
    wallet : Types.AiWallet,
    actor : Principal,
    kind : Types.ReceiptKind,
    reason : Text,
    previousReceiptId : ?Text,
    now : Int,
  ) : Types.AiWalletReceipt {
    let payload = wallet.walletId # ":status:" # Principal.toText(actor) # ":" # reason # ":" # Int.toText(now);
    let payloadHash = hashText(payload);
    {
      receiptId = "rcpt:" # wallet.walletId # ":status:" # Int.toText(now);
      kind = kind;
      walletId = wallet.walletId;
      agentId = wallet.agentId;
      actor = actor;
      mode = wallet.mode;
      commandId = null;
      decision = null;
      reasonCodes = [#valid];
      payloadHash = payloadHash;
      previousReceiptId = previousReceiptId;
      createdAt = now;
    }
  };

  public func chainLinks(current : Types.AiWalletReceipt, previous : Types.AiWalletReceipt) : Bool {
    switch (current.previousReceiptId) {
      case (?id) id == previous.receiptId;
      case null false;
    }
  };
}
