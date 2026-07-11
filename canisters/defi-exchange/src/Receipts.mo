import Char "mo:base/Char";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Types "Types";

module {
  public func hashText(input : Text) : Text {
    var hash : Nat = 2166136261;
    for (char in input.chars()) {
      hash := (hash + Nat32.toNat(Char.toNat32(char))) * 16777619;
      hash := hash % 4_294_967_296;
    };
    Nat.toText(hash)
  };

  public func makeReceipt(
    kind : Types.ExchangeReceiptKind,
    pairId : ?Text,
    orderId : ?Nat,
    fillId : ?Nat,
    actor : Principal,
    previousReceiptId : ?Text,
    now : Int,
  ) : Types.ExchangeReceipt {
    let pairText = switch (pairId) { case (?p) p; case null "none" };
    let orderText = switch (orderId) { case (?id) Nat.toText(id); case null "none" };
    let fillText = switch (fillId) { case (?id) Nat.toText(id); case null "none" };
    let payload = pairText # ":" # orderText # ":" # fillText # ":" # Principal.toText(actor) # ":" # Int.toText(now);
    {
      receiptId = "defi-rcpt:" # hashText(payload) # ":" # Int.toText(now);
      kind = kind;
      pairId = pairId;
      orderId = orderId;
      fillId = fillId;
      actor = actor;
      payloadHash = hashText(payload);
      previousReceiptId = previousReceiptId;
      createdAt = now;
    }
  };
}
