// ═══════════════════════════════════════════════════════════════════════════════
// PARALLAX Substrate Template — Tier 2 (Major Substrate)
// Copy this as a starting point for new Tier 2 substrates
// ═══════════════════════════════════════════════════════════════════════════════
//
// INSTRUCTIONS:
//   1. Copy this file to src/<your_name>/main.mo
//   2. Rename the actor to your substrate's PascalCase name
//   3. Add your domain-specific logic in the heartbeat and public API
//   4. Import additional modules as needed
//
// Or better — use: parallax scaffold <name> --tier 2
// ═══════════════════════════════════════════════════════════════════════════════

import Time      "mo:core/Time";
import Timer     "mo:core/Timer";
import Float     "mo:core/Float";
import Nat       "mo:core/Nat";
import Int       "mo:core/Int";
import Array     "mo:core/Array";
import Principal "mo:core/Principal";

actor MySubstrate {

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  let PHI : Float     = 1.618033988749895;
  let PHI_INV : Float = 0.618033988749895;
  let BEAT_MS : Nat   = 873;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE — all persistent across upgrades
  // ═══════════════════════════════════════════════════════════════════════════

  var beat : Nat = 0;
  var coherence : Float = 0.0;
  var creatorPrincipal : ?Principal = null;

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATOR LOCK — set once, permanent
  // ═══════════════════════════════════════════════════════════════════════════

  public shared(msg) func lockCreator() : async Bool {
    switch (creatorPrincipal) {
      case (?_) { false };
      case null {
        creatorPrincipal := ?msg.caller;
        true
      };
    }
  };

  func isCreator(caller : Principal) : Bool {
    switch (creatorPrincipal) {
      case (?p) { p == caller };
      case null { false };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT — advances every 873ms
  // ═══════════════════════════════════════════════════════════════════════════

  private func heartbeat() : async () {
    beat += 1;
    // TODO: Domain-specific heartbeat logic
    // Example: update coherence, process queues, emit signals
  };

  let _ = Timer.recurringTimer<system>(#nanoseconds(BEAT_MS * 1_000_000), heartbeat);

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — query endpoints
  // ═══════════════════════════════════════════════════════════════════════════

  public query func getBeat() : async Nat { beat };

  public query func getCoherence() : async Float { coherence };

  public query func health() : async { beat : Nat; coherence : Float; name : Text } {
    { beat; coherence; name = "my_substrate" }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API — update endpoints (creator-gated)
  // ═══════════════════════════════════════════════════════════════════════════

  public shared(msg) func setCoherence(value : Float) : async Bool {
    if (not isCreator(msg.caller)) return false;
    coherence := value;
    true
  };
};
