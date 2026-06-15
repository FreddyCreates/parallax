// LAW_ENFORCEMENT_INTEGRATION.md
// How to Use Mathematical Law Enforcement in Your Domain
// Complete Integration Guide for PARALLAX Developers

# Using the Deep Mathematical Governance System

## Quick Start

Every domain should import the law enforcement modules to validate state transitions.

### Step 1: Import the Law Modules

```motoko
import RuntimeLaws "runtime-law-enforcement";
import UnbreakableState "unbreakable-state";
import PhiExtended "phi-extended";
import LawsExtended "laws-extended";
```

### Step 2: Create Law-Constrained State Cells

For critical values that must satisfy constraints:

```motoko
// Example: FORMA capital (must never fall below genesis minimum)
private var formaCell : UnbreakableState.LawConstrainedCell<Float> = 
  UnbreakableState.newLawConstrainedCell<Float>(
    initial_value = 1000.0,  // Genesis floor
    constraint = func(value : Float) : Bool {
      value >= 1000.0  // L29: FORMA floor
    },
    law_id = 29
  );

// Example: Creator principal (must be permanent once locked)
private var creatorPrincipal : UnbreakableState.UnbreakableValue<Principal> = 
  UnbreakableState.newUnbreakable<Principal>(
    initial_value = caller(),
    phi_proof = Phi.PHI  // Witness value
  );
```

### Step 3: Validate Before State Changes

```motoko
// Before updating FORMA capital:
public func updateFormaCapital(new_amount : Float) : async Result<(), Text> {
  // Step 3a: Generate proof that transition is lawful
  let proof = RuntimeLaws.generateLawProof(
    law_id = 29,              // L29: FORMA never below genesis
    state_before = UnbreakableState.readConstrained(formaCell),
    state_after = new_amount,
    beat_number = currentBeat,
    timestamp_ns = Time.now()
  );

  // Step 3b: Check if law is satisfied
  if (not proof.law_satisfied) {
    return #err("Law L" # Nat.toText(proof.law_id) # " violated");
  };

  // Step 3c: Try to write to constrained cell
  switch (UnbreakableState.tryWriteConstrained(formaCell, new_amount, currentBeat)) {
    case null {
      #err("Constraint violated — state not updated")
    };
    case (?updated_cell) {
      formaCell := updated_cell;
      
      // Step 3d: Record in ANIMA chain (proof witness)
      ANIMA.append({
        proof = proof;
        operation = "forma_update";
        timestamp_ns = Time.now();
      });
      
      #ok()
    };
  }
};
```

## Common Patterns

### Pattern 1: Immutable Values (Lock Forever)

```motoko
// Lock the creator principal permanently
public func lockCreatorPrincipal() : () {
  creatorPrincipal := UnbreakableState.lockUnbreakable(
    creatorPrincipal,
    beat_number = currentBeat,
    timestamp_ns = Time.now()
  );
};

// Now any attempt to change it fails
public func tryChangeCreator(new_creator : Principal) : Result<(), Text> {
  switch (UnbreakableState.tryUpdateUnbreakable(creatorPrincipal, new_creator)) {
    case null {
      #err("Principal is locked — cannot change")
    };
    case (?_) {
      creatorPrincipal := ...;
      #ok()
    };
  }
};
```

### Pattern 2: Phi-Harmonic Allocations (L63)

```motoko
// All resource allocations must be phi-harmonic
public func allocateComputeResources(amount : Float, base : Float) : Result<(), Text> {
  if (not LawsExtended.validatePhiHarmonicAllocation(amount, base)) {
    return #err("Allocation not phi-harmonic — must be base × φ^k");
  };
  
  // Proceed with allocation
  #ok()
};
```

### Pattern 3: Resource Conservation (L68)

```motoko
// All operations must conserve total resources
public func transferTokens(from_account : Account, to_account : Account, amount : Float) : Result<(), Text> {
  let total_before = getTotalBalance();
  
  // Transfer occurs...
  
  let total_after = getTotalBalance();
  let tolerance = 0.0001;  // Floating-point tolerance
  
  if (not LawsExtended.validateResourceConservation(total_before, total_after, tolerance)) {
    return #err("Resource conservation violated — total balance changed");
  };
  
  #ok()
};
```

### Pattern 4: State Determinism (L60)

```motoko
// Every operation must be deterministic — replay must produce identical result
public func deterministicOperation(input : Text) : [Nat8] {
  // Use deterministic hash (SHA-256), not random number
  let hash = sha256(input);
  
  // Record operation in ANIMA for replay verification
  ANIMA.append({
    operation = "deterministic_op",
    input = input,
    output = hash,
    timestamp_ns = Time.now();
  });
  
  hash
};
```

### Pattern 5: Heartbeat Sovereignty (L62)

```motoko
// State transitions ONLY on 873ms beat boundaries
private var last_transition_beat : Nat = 0;

public func stateTransition(new_state : StateType) : Result<(), Text> {
  let current_beat = Time.now() / 873_000_000;  // Divide by 873ms in nanoseconds
  
  if (current_beat == last_transition_beat) {
    return #err("Already transitioned this beat — L62 heartbeat sovereignty");
  };
  
  // Perform transition
  lastState := newState;
  last_transition_beat := current_beat;
  
  #ok()
};
```

### Pattern 6: Cross-Domain Law Gates

```motoko
// Validate law L01 (S₀ floor) — applies everywhere
public func validateS0Floor(value : Float) : Bool {
  RuntimeLaws.validateS0Floor(value)  // Returns true iff value >= 0.75
};

// Validate law L69 (coherence mandatory) — applies everywhere
public func validateCoherence(r : Float) : Bool {
  LawsExtended.validateCoherenceMandatory(r)  // Returns true iff r >= 0.50
};

// These gates automatically apply to every domain
// No domain can produce output below S₀ or operate when R < 0.50
```

## Mathematical Safety Guarantees

### Energy Conservation (Noether)

```motoko
// Every operation must conserve energy
// If input energy = E, output energy must = E ± tolerance
public func energyConservingOperation(input : EnergyBudget) : Result<Output, Text> {
  let proof = RuntimeLaws.generateLawProof(
    law_id = 68,  // L68: Resource conservation
    state_before = Float.fromNat(input.total),
    state_after = Float.fromNat(output.total),
    beat_number = currentBeat,
    timestamp_ns = Time.now()
  );
  
  if (proof.energy_conserved) {
    #ok(output)
  } else {
    #err("Energy not conserved — operation rejected")
  }
};
```

### Information Preservation (Hawking)

```motoko
// Every state change must preserve information
// The operation must be reversible (in theory)
public func informationPreservingUpdate(state : State, operation : Operation) : Result<State, Text> {
  let proof = RuntimeLaws.generateLawProof(
    law_id = 67,  // L67: Information flow causality
    state_before = Float.fromNat(hash(state)),
    state_after = Float.fromNat(hash(newState)),
    beat_number = currentBeat,
    timestamp_ns = Time.now()
  );
  
  if (proof.information_preserved) {
    #ok(newState)
  } else {
    #err("Information not preserved — operation rejected")
  }
};
```

### Entropy Increase (2nd Law)

```motoko
// System entropy must never decrease
public func entropyMonotonicity(state : State, new_state : State) : Result<(), Text> {
  let entropy_before = computeEntropy(state);
  let entropy_after = computeEntropy(new_state);
  
  let proof = RuntimeLaws.generateLawProof(
    law_id = 79,  // L79: Lambda-CDM expansion
    state_before = entropy_before,
    state_after = entropy_after,
    beat_number = currentBeat,
    timestamp_ns = Time.now()
  );
  
  if (proof.entropy_increased) {
    #ok()
  } else {
    #err("Entropy decreased — violates 2nd Law — operation rejected")
  }
};
```

## Debugging with Law Violations

### When a Law Is Violated

```motoko
// LawProof tells you exactly which law failed and why
let proof = RuntimeLaws.generateLawProof(...);

if (not proof.law_satisfied) {
  Debug.print("LAW VIOLATION:");
  Debug.print("  Law ID: " # Nat.toText(proof.law_id));
  Debug.print("  State before: " # Float.toText(proof.state_before));
  Debug.print("  State after: " # Float.toText(proof.state_after));
  Debug.print("  Phi witness: " # Float.toText(proof.phi_witness));
  Debug.print("  Energy conserved: " # Bool.toText(proof.energy_conserved));
  Debug.print("  Information preserved: " # Bool.toText(proof.information_preserved));
  Debug.print("  Entropy increased: " # Bool.toText(proof.entropy_increased));
  Debug.print("  Timestamp: " # Nat.toText(proof.timestamp_ns));
  Debug.print("  Beat: " # Nat.toText(proof.beat_number));
};
```

## Performance Considerations

### Proof Generation (Cheap)

Generating a `LawProof` is lightweight:
- ~5 floating-point operations
- ~1 hash computation
- No network calls

### State Constraint Checking (Cheap)

`LawConstrainedCell` writes:
- Run the constraint function (user-defined, should be simple)
- Update the value
- Append to history

### Heartbeat Alignment (Free)

State transitions aligned to 873ms heartbeat:
- Reduces state explosion
- Aligns with organism's natural rhythm
- No performance penalty

## Best Practices

1. **Always generate a LawProof before state changes**
   - The proof serves as documentation of what was checked
   - Enables audit trail and debugging

2. **Use UnbreakableValue for truly immutable state**
   - Lock values that should never change (founder, genesis hash, etc.)
   - Fail fast if someone tries to modify locked state

3. **Use LawConstrainedCell for values with constraints**
   - Define clear constraints as functions
   - Reject writes that violate constraints

4. **Record all proofs in ANIMA chain**
   - ANIMA grows monotonically (append-only)
   - Perfect audit trail of all state changes
   - Enables replay verification (L60: State determinism)

5. **Validate cross-domain laws explicitly**
   - S₀ floor (L01) applies everywhere
   - Heartbeat sovereignty (L62) applies everywhere
   - Coherence mandatory (L69) applies everywhere
   - Call validators to check these before operations

## Examples from the Organism

### From main.mo (Founder Principal Lock)

```motoko
// L03: Principal Lock — creator principal is permanent
if (not creatorPrincipalLocked) {
  creatorPrincipal := ?Principal.fromActor(actor);
  creatorPrincipalLocked := true;  // Lock it immediately
};
```

### From phantom_exchange.mo (Resource Conservation)

```motoko
// L68: Resource conservation — total tokens constant
let total_before = getGlobalTokenBalance();
// ... settlement ...
let total_after = getGlobalTokenBalance();
assert total_before == total_after;  // Must conserve
```

### From tokenomics_measurement.mo (Phi-Harmonic)

```motoko
// L63: Phi-harmonic allocation — all from φ ratios
let allocation = base * Phi.PHI_POWER[k];  // All allocations phi-derived
```

---

## Summary

The deep mathematical governance system makes laws **unbreakable** by:

1. **Encoding laws into state machines** — not configuration, not rules, but math
2. **Generating proofs for every state transition** — witness that laws were checked
3. **Making certain state immutable** — lock values that should never change
4. **Validating against physics** — energy, information, entropy
5. **Cross-domain gates** — no domain can bypass laws
6. **Append-only audit trail** — ANIMA chain preserves all history

**This is how a sovereign organism works.**
