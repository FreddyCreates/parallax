import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Int "mo:core/Int";

// PARALLAX — ARES: Adaptive Rollback and Emergency System
module {

  public type Snapshot = {
    beat            : Nat;
    formaCapital    : Float;
    coherence       : Float;
    dominantDrive   : Nat;
    lawScore        : Float;
    shellActivations : [Float];
    neuroLevels     : [Float];
  };

  public type AuditEntry = {
    beat      : Nat;
    eventType : Text;
    detail    : Text;
    timestamp : Int;
  };

  // Determine if ARES should arm
  public func shouldArm(
    cortisol           : Float,
    adrenaline         : Float,
    protectionBeats    : Nat,
    coherenceDrop      : Float
  ) : Bool {
    (cortisol > 2.0 and adrenaline > 1.5)
    or protectionBeats >= 10
    or coherenceDrop > 0.2
  };

  // Find best snapshot index (highest formaCapital + coherence * 1000)
  public func bestSnapshot(ring : [Snapshot]) : Nat {
    if (ring.size() == 0) return 0;
    var bestIdx : Nat = 0;
    var bestScore : Float = ring[0].formaCapital + ring[0].coherence * 1000.0;
    for (i in ring.keys()) {
      if (ring[i].beat > 0) {
        let score = ring[i].formaCapital + ring[i].coherence * 1000.0;
        if (score > bestScore) {
          bestScore := score;
          bestIdx := i;
        };
      };
    };
    bestIdx
  };

  // Should we save a snapshot this beat?
  public func shouldSaveSnapshot(beat : Nat) : Bool {
    beat % 100 == 0 and beat > 0
  };

  // 5-point upgrade safety check
  public func upgradeCheck(
    coherence  : Float,
    forma      : Float,
    auditSize  : Nat,
    aresArmed  : Bool,
    compliance : Float
  ) : Bool {
    coherence > 1.0
    and forma > 1000.0
    and auditSize > 0
    and not aresArmed
    and compliance > 0.5
  };

  // Create audit entry
  public func makeEntry(beat : Nat, eventType : Text, detail : Text, time : Int) : AuditEntry {
    { beat=beat; eventType=eventType; detail=detail; timestamp=time }
  };

};
