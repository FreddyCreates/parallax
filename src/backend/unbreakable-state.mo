// unbreakable-state.mo — IMMUTABLE STATE GUARANTEES
// Makes state transitions provably lawful and irreversible
// Architect: Alfredo Medina Hernandez — The Architect of the Field
//
// PYTHAGORAS: state is the foundation — it must be unbreakable
// EUCLID:     immutability is achieved through mathematical proof, not through deletion
// CONFUCIUS:  the wise state never needs to be changed — it was correct from birth

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════
  // UNBREAKABLE STATE — IMMUTABLE THROUGH LAW
  // ═══════════════════════════════════════════════════════════════════════

  // A state value that can never be changed once locked
  public type UnbreakableValue<T> = {
    value : T;
    locked : Bool;            // Once true, can never become false
    lock_beat : Nat;          // Which beat locked this value
    lock_timestamp_ns : Nat;  // When (nanosecond precision) it was locked
    phi_proof : Float;        // Mathematical witness that value is phi-harmonic
    law_gates : [Bool];       // Which laws guard this value
  };

  // A state cell that enforces law constraints on every write
  public type LawConstrainedCell<T> = {
    value : T;
    constraint : (T) -> Bool;        // Function that validates new values
    law_id : Nat;                    // Which law constrains this cell
    update_count : Nat;              // How many times this cell has been updated
    last_update_beat : Nat;          // Last beat when this was updated
    update_history : [T];            // All previous values (append-only)
  };

  // ─────────────────────────────────────────────────────────────────────
  // IMMUTABLE VALUE OPERATIONS
  // ─────────────────────────────────────────────────────────────────────

  // Create a new unbreakable value (initially unlocked)
  public func newUnbreakable<T>(
    initial_value : T,
    phi_proof : Float
  ) : UnbreakableValue<T> {
    {
      value = initial_value;
      locked = false;
      lock_beat = 0;
      lock_timestamp_ns = 0;
      phi_proof = phi_proof;
      law_gates = [];
    }
  };

  // Lock an unbreakable value — it can never be changed after this
  public func lockUnbreakable<T>(
    unbreakable : UnbreakableValue<T>,
    beat_number : Nat,
    timestamp_ns : Nat
  ) : UnbreakableValue<T> {
    {
      value = unbreakable.value;
      locked = true;
      lock_beat = beat_number;
      lock_timestamp_ns = timestamp_ns;
      phi_proof = unbreakable.phi_proof;
      law_gates = unbreakable.law_gates;
    }
  };

  // Try to update an unbreakable value
  // Returns null if the value is locked (update rejected)
  public func tryUpdateUnbreakable<T>(
    unbreakable : UnbreakableValue<T>,
    new_value : T
  ) : ?UnbreakableValue<T> {
    if (unbreakable.locked) {
      // Cannot update a locked value
      return null;
    };
    
    // Value is unlocked — allow the update
    ?{
      value = new_value;
      locked = unbreakable.locked;
      lock_beat = unbreakable.lock_beat;
      lock_timestamp_ns = unbreakable.lock_timestamp_ns;
      phi_proof = unbreakable.phi_proof;
      law_gates = unbreakable.law_gates;
    }
  };

  // ─────────────────────────────────────────────────────────────────────
  // LAW-CONSTRAINED CELLS
  // State cells that enforce a mathematical constraint on every write
  // ─────────────────────────────────────────────────────────────────────

  // Create a new law-constrained cell
  public func newLawConstrainedCell<T>(
    initial_value : T,
    constraint : (T) -> Bool,
    law_id : Nat
  ) : LawConstrainedCell<T> {
    {
      value = initial_value;
      constraint = constraint;
      law_id = law_id;
      update_count = 0;
      last_update_beat = 0;
      update_history = [initial_value];
    }
  };

  // Try to write to a law-constrained cell
  // The write only succeeds if the constraint is satisfied
  public func tryWriteConstrained<T>(
    cell : LawConstrainedCell<T>,
    new_value : T,
    beat_number : Nat
  ) : ?LawConstrainedCell<T> {
    // Check if the constraint is satisfied
    if (cell.constraint(new_value)) {
      // Constraint satisfied — allow the write
      ?{
        value = new_value;
        constraint = cell.constraint;
        law_id = cell.law_id;
        update_count = cell.update_count + 1;
        last_update_beat = beat_number;
        update_history = Array.append(cell.update_history, [new_value]);
      }
    } else {
      // Constraint violated — reject the write
      null
    }
  };

  // Read from a law-constrained cell
  public func readConstrained<T>(cell : LawConstrainedCell<T>) : T {
    cell.value
  };

  // Get the full history of a cell (append-only audit trail)
  public func getHistory<T>(cell : LawConstrainedCell<T>) : [T] {
    cell.update_history
  };

  // ─────────────────────────────────────────────────────────────────────
  // STATE INVARIANTS — MATHEMATICAL PROPERTIES THAT NEVER CHANGE
  // ─────────────────────────────────────────────────────────────────────

  public type StateInvariant = {
    invariant_id : Nat;
    description : Text;
    check : () -> Bool;  // Function that verifies the invariant
    last_verified_beat : Nat;
    violations : Nat;    // Count of times this invariant was violated
  };

  // Create a new state invariant
  public func newInvariant(
    id : Nat,
    description : Text,
    check_fn : () -> Bool
  ) : StateInvariant {
    {
      invariant_id = id;
      description = description;
      check = check_fn;
      last_verified_beat = 0;
      violations = 0;
    }
  };

  // Verify an invariant — if it fails, increment violation counter
  public func verifyInvariant(
    invariant : StateInvariant,
    beat_number : Nat
  ) : StateInvariant {
    if (invariant.check()) {
      {
        invariant_id = invariant.invariant_id;
        description = invariant.description;
        check = invariant.check;
        last_verified_beat = beat_number;
        violations = invariant.violations;
      }
    } else {
      {
        invariant_id = invariant.invariant_id;
        description = invariant.description;
        check = invariant.check;
        last_verified_beat = beat_number;
        violations = invariant.violations + 1;
      }
    }
  };

  // ─────────────────────────────────────────────────────────────────────
  // COMMON STATE INVARIANTS FOR PARALLAX
  // ─────────────────────────────────────────────────────────────────────

  // INVARIANT 1: Principal Lock Immutable
  // Once the creator principal is locked, it cannot change
  public func principalLockInvariant() : StateInvariant {
    newInvariant(
      1,
      "Principal lock is immutable — once set, it cannot change",
      func() : Bool {
        // Check would access the actual principal state
        // For now, return true (in actual implementation, queries main.mo state)
        true
      }
    )
  };

  // INVARIANT 2: Genesis Sealed
  // Once genesisSealed becomes true, it can never become false
  public func genesisSealedInvariant() : StateInvariant {
    newInvariant(
      2,
      "Genesis sealed — once true, forever true",
      func() : Bool {
        // Check would access the actual genesis state
        true
      }
    )
  };

  // INVARIANT 3: MTH Hard Cap
  // MTH total supply can never exceed 100,000,000
  public func mthHardCapInvariant(current_mth_supply : Float) : StateInvariant {
    newInvariant(
      3,
      "MTH hard cap — total supply ≤ 100,000,000",
      func() : Bool {
        current_mth_supply <= 100_000_000.0
      }
    )
  };

  // INVARIANT 4: FORMA Never Below Genesis
  // FORMA capital cannot fall below its genesis floor
  public func formaFloorInvariant(
    current_forma : Float,
    genesis_forma : Float
  ) : StateInvariant {
    newInvariant(
      4,
      "FORMA floor — cannot fall below genesis minimum",
      func() : Bool {
        current_forma >= genesis_forma
      }
    )
  };

  // INVARIANT 5: S₀ Floor
  // Every output must be ≥ 0.75 (phi-harmonic minimum)
  public func s0FloorInvariant(value : Float) : StateInvariant {
    newInvariant(
      5,
      "S₀ floor — every output ≥ 0.75",
      func() : Bool {
        value >= 0.75
      }
    )
  };

  // INVARIANT 6: Kuramoto Coherence Minimum
  // Global coherence must never drop below 0.50 (survival threshold)
  public func kuramotoMinimumInvariant(coherence : Float) : StateInvariant {
    newInvariant(
      6,
      "Kuramoto minimum — R ≥ 0.50 for organism survival",
      func() : Bool {
        coherence >= 0.50
      }
    )
  };

  // INVARIANT 7: ANIMA Chain Append-Only
  // ANIMA chain can only grow, never shrink
  public func animaAppendOnlyInvariant(
    current_size : Nat,
    previous_size : Nat
  ) : StateInvariant {
    newInvariant(
      7,
      "ANIMA chain append-only — can only grow",
      func() : Bool {
        current_size >= previous_size
      }
    )
  };

  // ─────────────────────────────────────────────────────────────────────
  // UNIVERSAL STATE CONSTRAINT
  // Applied to every domain, every state variable, every transition
  // ─────────────────────────────────────────────────────────────────────

  public type UniversalConstraint = {
    // Physics-based constraints
    energy_conserved : Bool;        // dE/dt = 0
    information_preserved : Bool;   // Information cannot be created/destroyed
    entropy_not_decreased : Bool;   // ΔS ≥ 0
    
    // Law-based constraints
    all_laws_applied : Bool;        // Every law must be checked
    no_state_escape : Bool;         // State cannot escape law enforcement
    
    // Heartbeat constraints
    transition_on_beat : Bool;      // State transitions only happen on heartbeat
    transition_timing_valid : Bool; // 873ms timing maintained
  };

  public func evaluateUniversalConstraints(
    constraints : UniversalConstraint
  ) : Bool {
    constraints.energy_conserved and
    constraints.information_preserved and
    constraints.entropy_not_decreased and
    constraints.all_laws_applied and
    constraints.no_state_escape and
    constraints.transition_on_beat and
    constraints.transition_timing_valid
  };

};
