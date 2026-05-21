import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// STIGMERGY DEEP ENGINE — PARALLAX PHASE K
// Full pheromone field: deposit, decay, diffusion, renewal
// Inter-organism stigmergy via NOVA network
// Feeds Shell 3 world territory nodes
// ============================================================
module {

  let FIELD_SIZE : Nat = 24; // 24-cell pheromone grid

  public type StigmergyState = {
    var field          : [var Float];  // 24-cell pheromone field
    var fieldGradient  : [var Float];  // Gradient (field[i+1] - field[i])
    var fieldMean      : Float;        // Current mean field intensity
    var fieldMax       : Float;        // Peak cell value
    var fieldEntropy   : Float;        // Shannon entropy of field distribution
    var decayRate      : Float;        // Per-beat decay multiplier
    var diffusionRate  : Float;        // Field diffusion coefficient
    var depositTotal   : Float;        // Cumulative deposits
    var depositBeat    : Float;        // This beat's deposit
    var evaporateBeat  : Float;        // This beat's evaporation
    var trailStrength  : Float;        // Dominant trail signal
    var trailCell      : Nat;          // Dominant trail cell index
    var coordSignal    : Float;        // Coordination signal (smooth gradient)
    var novaSignal     : Float;        // Inter-organism network signal
    var novaDepositRate: Float;        // NOVA network deposit per child beat
    var activeOrgs     : Nat;          // Child organisms in network
    var creatorBoost   : Float;        // Creator-cell boost multiplier
    var creatorCell    : Nat;          // Creator's fixed cell (0)
    var shell3Input    : [var Float];  // 12 Shell-3 world node inputs from field
    var totalDeposits  : Nat;          // Count of deposits
    var renewalRate    : Float;        // Autonomous renewal when field decays below floor
    var fieldFloor     : Float;        // Sovereign floor: no cell below this
  };

  public func initStigmergyState() : StigmergyState = {
    var field = Array.init<Float>(FIELD_SIZE, 1.0);
    var fieldGradient = Array.init<Float>(FIELD_SIZE - 1, 0.0);
    field[0] := 2.0; // Creator cell starts at sovereign max
    var fieldMean      = 1.0;
    var fieldMax       = 2.0;
    var fieldEntropy   = 1.0;
    var decayRate      = 0.995;
    var diffusionRate  = 0.01;
    var depositTotal   = 1.0;
    var depositBeat    = 0.0;
    var evaporateBeat  = 0.0;
    var trailStrength  = 1.0;
    var trailCell      = 0;
    var coordSignal    = 1.0;
    var novaSignal     = 1.0;
    var novaDepositRate= 0.001;
    var activeOrgs     = 0;
    var creatorBoost   = 2.0;
    var creatorCell    = 0;
    var shell3Input    = Array.init<Float>(12, 1.0);
    var totalDeposits  = 1;
    var renewalRate    = 0.001;
    var fieldFloor     = 1.0;
  };

  // Shannon entropy of field distribution
  func fieldEntropy(field: [var Float]) : Float {
    var sum = 0.0;
    for (v in field.vals()) { sum += v; };
    if (sum <= 0.0) return 1.0;
    var H = 0.0;
    for (v in field.vals()) {
      let p = v / sum;
      if (p > 0.0) H -= p * Float.log(p);
    };
    Float.max(1.0, H)
  };

  // Diffusion: each cell receives fraction of neighbor values
  func diffuse(field: [var Float], rate: Float) {
    let n = FIELD_SIZE;
    let buf = Array.init<Float>(n, 0.0);
    var i = 0;
    while (i < n) {
      let left  = if (i > 0) field[i-1] else field[n-1];
      let right = if (i < n-1) field[i+1] else field[0];
      buf[i] := field[i] * (1.0 - 2.0 * rate) + left * rate + right * rate;
      i += 1;
    };
    var j = 0;
    while (j < n) {
      field[j] := buf[j];
      j += 1;
    };
  };

  // Gradient computation
  func computeGradient(field: [var Float], gradient: [var Float]) {
    var i = 0;
    while (i < FIELD_SIZE - 1) {
      gradient[i] := field[i+1] - field[i];
      i += 1;
    };
  };

  // Coordination signal: smooth gradient mean (direction of flow)
  func coordSignalFromGradient(gradient: [var Float]) : Float {
    var sum = 0.0;
    for (g in gradient.vals()) { sum += Float.abs(g); };
    Float.max(1.0, 1.0 + sum / Float.fromInt(FIELD_SIZE - 1))
  };

  // Shell 3 inputs: sample field at 12 evenly-spaced cells
  func computeShell3Input(field: [var Float], shell3: [var Float]) {
    var i = 0;
    while (i < 12) {
      let cellIdx = (i * 2) % FIELD_SIZE; // Every other cell
      shell3[i] := Float.max(1.0, field[cellIdx]);
      i += 1;
    };
  };

  // NOVA network deposit: child organisms also leave pheromone trails
  // Each child deposits at its assigned cell
  func novaDeposit(field: [var Float], activeOrgs: Nat, depositRate: Float) {
    var i = 0;
    while (i < Nat.min(activeOrgs, FIELD_SIZE)) {
      // Child i deposits at cell (i+1) % FIELD_SIZE
      let cell = (i + 1) % FIELD_SIZE;
      field[cell] := Float.min(2.0, field[cell] + depositRate);
      i += 1;
    };
  };

  public func updateStigmergy(
    s          : StigmergyState,
    deposit    : Float,   // From organism activity this beat
    beatCount  : Nat,
    coherenceC : Float,
    activeOrgs : Nat
  ) : StigmergyState {
    // 1. Decay all cells
    var totalEvap = 0.0;
    var i = 0;
    while (i < FIELD_SIZE) {
      let prev = s.field[i];
      s.field[i] := Float.max(s.fieldFloor, prev * s.decayRate);
      totalEvap += prev - s.field[i];
      i += 1;
    };

    // 2. Deposit from organism activity (creator cell + distributed)
    let creatorDeposit = deposit * s.creatorBoost;
    s.field[s.creatorCell] := Float.min(2.0, s.field[s.creatorCell] + creatorDeposit);
    // Distribute remaining deposit proportionally to coherence
    let distDeposit = deposit * (coherenceC - 1.0) * 0.5;
    let perCell = distDeposit / Float.fromInt(FIELD_SIZE);
    var j = 0;
    while (j < FIELD_SIZE) {
      s.field[j] := Float.min(2.0, s.field[j] + perCell);
      j += 1;
    };

    // 3. NOVA network deposits
    s.activeOrgs := activeOrgs;
    novaDeposit(s.field, activeOrgs, s.novaDepositRate);

    // 4. Autonomous renewal: if mean drops below floor + 0.1, inject renewal
    var fieldSum = 0.0;
    for (v in s.field.vals()) { fieldSum += v; };
    let mean = fieldSum / Float.fromInt(FIELD_SIZE);
    if (mean < s.fieldFloor + 0.1) {
      var k = 0;
      while (k < FIELD_SIZE) {
        s.field[k] := s.field[k] + s.renewalRate;
        k += 1;
      };
    };

    // 5. Diffuse
    diffuse(s.field, s.diffusionRate);

    // 6. Recompute metrics
    computeGradient(s.field, s.fieldGradient);
    computeShell3Input(s.field, s.shell3Input);

    var maxCell = 0.0;
    var maxIdx  = 0;
    var fSum2   = 0.0;
    var m = 0;
    for (v in s.field.vals()) {
      fSum2 += v;
      if (v > maxCell) { maxCell := v; maxIdx := m; };
      m += 1;
    };
    let newMean = fSum2 / Float.fromInt(FIELD_SIZE);

    let H = fieldEntropy(s.field);
    let coord = coordSignalFromGradient(s.fieldGradient);

    // NOVA signal: geometric mean of NOVA cells
    let novaSig = Float.max(1.0,
      s.field[(1) % FIELD_SIZE] *
      s.field[(2) % FIELD_SIZE] *
      s.field[(3) % FIELD_SIZE]
    ) / 8.0; // normalize

    s.fieldMean       := newMean;
    s.fieldMax        := maxCell;
    s.fieldEntropy    := H;
    s.depositBeat     := creatorDeposit + distDeposit;
    s.evaporateBeat   := totalEvap;
    s.depositTotal    := s.depositTotal + creatorDeposit + distDeposit;
    s.trailStrength   := maxCell;
    s.trailCell       := maxIdx;
    s.coordSignal     := coord;
    s.novaSignal      := Float.max(1.0, novaSig);
    s.totalDeposits   := s.totalDeposits + 1;
    s
  };

  // Stigmergy feedback to Shell 3: returns the 12-node world input vector
  public func shell3WorldInput(s: StigmergyState) : [Float] {
    let result = Array.init<Float>(12, 1.0);
    var i = 0;
    while (i < 12) {
      result[i] := s.shell3Input[i];
      i += 1;
    };
    Array.fromVarArray(result)
  };

  // Dominant trail heading: 0=left, 1=right, 2=flat
  public func trailHeading(s: StigmergyState) : Nat {
    var posGrad = 0;
    var negGrad = 0;
    for (g in s.fieldGradient.vals()) {
      if (g > 0.01) posGrad += 1
      else if (g < -0.01) negGrad += 1;
    };
    if (posGrad > negGrad) 1
    else if (negGrad > posGrad) 0
    else 2
  };

};
