import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// TERRITORY DEEP ENGINE — PARALLAX PHASE K
// Multi-dimensional territory: cognitive, economic, network, world
// Stigmergic auto-pressure, expansion mechanics, TESTOSTERONE mod
// ============================================================
module {

  // 4 territory domains
  public type TerritoryDomain = {
    var score         : Float;  // Current domain score [1.0, 2.0]
    var velocity      : Float;  // Rate of change
    var pressure      : Float;  // Auto-pressure resisting loss
    var expansionRate : Float;  // Rate of expansion when conditions met
    var peakScore     : Float;  // Lifetime maximum
    var lossStreak    : Nat;    // Consecutive loss beats
    var gainStreak    : Nat;    // Consecutive gain beats
    var controlFactor : Float;  // Fraction under sovereign control
  };

  public type TerritoryState = {
    // Domain 0: Cognitive (Shell coherence, law compliance)
    var cogDomain      : TerritoryDomain;
    // Domain 1: Economic (FORMA capital, token reserves, MRC)
    var ecoDomain      : TerritoryDomain;
    // Domain 2: Network (NOVA organisms, succession chain depth)
    var netDomain      : TerritoryDomain;
    // Domain 3: World (price regimes, market dominance, DeFi)
    var wldDomain      : TerritoryDomain;
    // Composite territory score
    var compositeScore : Float;
    // Stigmergic field: EMA of territory activity
    var stigmergy      : Float;
    var stigmergyCue   : Float;   // Point-in-time pheromone deposit
    var stigmergyDecay : Float;   // Decay rate per beat
    // Testosterone modulation
    var testosteroneSignal : Float;
    // Auto-pressure wall
    var autoPressureFloor  : Float;
    // Expansion readiness
    var expansionReady     : Bool;
    var expansionTarget    : Nat;  // Which domain to expand next (0-3)
    // Territory health
    var territoryHealth    : Float;
    var totalExpansions    : Nat;
    var totalLosses        : Nat;
    // Shell 3 world-node input signal
    var shell3TerritoryInput : Float;
    // PARIETAL output
    var parietalSignal       : Float;
    // Territory history
    var historyComposite     : [var Float];
    var historyIdx           : Nat;
  };

  func initDomain(startScore: Float) : TerritoryDomain = {
    var score         = startScore;
    var velocity      = 0.0;
    var pressure      = 1.0;
    var expansionRate = 0.001;
    var peakScore     = startScore;
    var lossStreak    = 0;
    var gainStreak    = 0;
    var controlFactor = 1.0;
  };

  public func initTerritoryState() : TerritoryState = {
    var cogDomain      = initDomain(1.5);
    var ecoDomain      = initDomain(1.5);
    var netDomain      = initDomain(1.2);
    var wldDomain      = initDomain(1.3);
    var compositeScore = 1.375;
    var stigmergy      = 1.0;
    var stigmergyCue   = 0.0;
    var stigmergyDecay = 0.98;
    var testosteroneSignal = 1.0;
    var autoPressureFloor  = 1.0;
    var expansionReady     = false;
    var expansionTarget    = 0;
    var territoryHealth    = 1.0;
    var totalExpansions    = 0;
    var totalLosses        = 0;
    var shell3TerritoryInput = 1.0;
    var parietalSignal       = 1.0;
    var historyComposite     = Array.init<Float>(50, 1.375);
    var historyIdx           = 0;
  };

  // Auto-pressure: resists loss by increasing counter-force
  // pressure(t+1) = pressure(t) + lossStreak * PRESSURE_GAIN
  let PRESSURE_GAIN = 0.005;
  let PRESSURE_DECAY = 0.002;

  func updateDomain(
    d           : TerritoryDomain,
    input       : Float,   // External influence [0,1]
    coherenceC  : Float,
    testosterone: Float
  ) : TerritoryDomain {
    // Input drives score: positive input expands, negative contracts
    let delta = (input - 1.0) * 0.01 + (coherenceC - 1.0) * 0.005;
    let isGain = delta > 0.0;

    // Auto-pressure resists downward movement
    let pressureEffect = if (not isGain) d.pressure * 0.003 else 0.0;
    let netDelta = delta + pressureEffect;

    // New score: sovereign floor at 1.0
    let rawScore = d.score + netDelta;
    let newScore = Float.max(1.0, Float.min(2.0, rawScore));

    let vel = newScore - d.score;
    let peak = Float.max(d.peakScore, newScore);

    let ls = if (vel < -0.0001) d.lossStreak + 1 else 0;
    let gs = if (vel >  0.0001) d.gainStreak + 1 else 0;

    // Pressure: grows on loss streak, decays on gain streak
    let newPressure = Float.max(1.0,
      d.pressure +
      Float.fromInt(ls) * PRESSURE_GAIN -
      Float.fromInt(gs) * PRESSURE_DECAY
    );

    // Control factor: testosterone amplifies control
    let ctrlFactor = Float.max(1.0, d.controlFactor * (1.0 + (testosterone - 1.0) * 0.001));

    // Expansion rate grows with sustained gain streak
    let newExpRate = Float.max(0.001, d.expansionRate + Float.fromInt(gs) * 0.000001);

    {
      var score         = newScore;
      var velocity      = vel;
      var pressure      = newPressure;
      var expansionRate = newExpRate;
      var peakScore     = peak;
      var lossStreak    = ls;
      var gainStreak    = gs;
      var controlFactor = ctrlFactor;
    }
  };

  // Stigmergy: EMA of territory cue deposits
  // Cue deposited proportional to territory change (gains)
  func updateStigmergy(
    prevStigmergy : Float,
    cue           : Float,
    decay         : Float
  ) : Float {
    Float.max(1.0, prevStigmergy * decay + cue)
  };

  // Shell 3 territory input: log-transform composite for brain
  func shell3Input(composite: Float, stigmergy: Float) : Float {
    Float.max(1.0, Float.log(composite) * stigmergy * 2.0)
  };

  // PARIETAL organ output: territory signal to executive brain
  func parietalOutput(composite: Float, stigmergy: Float, coherenceC: Float) : Float {
    Float.max(1.0, composite * stigmergy * coherenceC * 0.5)
  };

  // Testosterone signal: amplifies on territory gain
  func testosteroneUpdate(prev: Float, totalGainStreaks: Nat, delta: Float) : Float {
    let boost = if (delta > 0.0) Float.fromInt(totalGainStreaks) * 0.0001 else -0.001;
    Float.max(1.0, Float.min(2.0, prev * 0.997 + boost))
  };

  // Composite: geometric mean of 4 domains
  func compositeScore(cog: Float, eco: Float, net: Float, wld: Float) : Float {
    Float.max(1.0, Float.exp((Float.log(cog) + Float.log(eco) + Float.log(net) + Float.log(wld)) / 4.0))
  };

  public func updateTerritory(
    s            : TerritoryState,
    cogInput     : Float,   // From coherence engine
    ecoInput     : Float,   // From FORMA/token engine
    netInput     : Float,   // From NOVA network
    wldInput     : Float,   // From world/market oracle
    coherenceC   : Float,
    beatCount    : Nat
  ) : TerritoryState {
    let testosterone = s.testosteroneSignal;

    let newCog = updateDomain(s.cogDomain, cogInput, coherenceC, testosterone);
    let newEco = updateDomain(s.ecoDomain, ecoInput, coherenceC, testosterone);
    let newNet = updateDomain(s.netDomain, netInput, coherenceC, testosterone);
    let newWld = updateDomain(s.wldDomain, wldInput, coherenceC, testosterone);

    let comp = compositeScore(newCog.score, newEco.score, newNet.score, newWld.score);

    // Total gain streaks across all domains
    let totalGS = newCog.gainStreak + newEco.gainStreak + newNet.gainStreak + newWld.gainStreak;
    let totalLS = newCog.lossStreak + newEco.lossStreak + newNet.lossStreak + newWld.lossStreak;

    // Stigmergy cue: proportional to composite velocity
    let prevComp = s.compositeScore;
    let compDelta = comp - prevComp;
    let cue = Float.max(0.0, compDelta * 100.0);
    let stigmergy = updateStigmergy(s.stigmergy, cue, s.stigmergyDecay);

    // Testosterone update
    let newTest = testosteroneUpdate(testosterone, totalGS, compDelta);

    // Expansion readiness: all domains gaining + composite > 1.5
    let ready = comp > 1.5 and totalGS > 4 and totalLS == 0;

    // Auto-pressure floor: highest single-domain pressure
    let floor = Float.max(Float.max(newCog.pressure, newEco.pressure),
                          Float.max(newNet.pressure, newWld.pressure));

    // Territory health: composite * control factors
    let health = Float.max(1.0,
      comp *
      newCog.controlFactor * 0.25 *
      newEco.controlFactor * 0.25 *
      newNet.controlFactor * 0.25 *
      newWld.controlFactor * 0.25
    );

    // Track losses and expansions
    let newLosses = s.totalLosses + (if (totalLS > 0) 1 else 0);
    let newExpansions = s.totalExpansions + (if (ready and not s.expansionReady) 1 else 0);

    // Shell 3 input and PARIETAL
    let sh3 = shell3Input(comp, stigmergy);
    let parietal = parietalOutput(comp, stigmergy, coherenceC);

    // History
    let hIdx = (s.historyIdx + 1) % 50;
    s.historyComposite[hIdx] := comp;

    s.cogDomain            := newCog;
    s.ecoDomain            := newEco;
    s.netDomain            := newNet;
    s.wldDomain            := newWld;
    s.compositeScore       := comp;
    s.stigmergy            := stigmergy;
    s.stigmergyCue         := cue;
    s.testosteroneSignal   := newTest;
    s.autoPressureFloor    := floor;
    s.expansionReady       := ready;
    s.expansionTarget      := if (newCog.score < newEco.score and newCog.score < newNet.score) 0
                              else if (newEco.score < newNet.score) 1
                              else if (newNet.score < newWld.score) 2
                              else 3;
    s.territoryHealth      := health;
    s.totalExpansions      := newExpansions;
    s.totalLosses          := newLosses;
    s.shell3TerritoryInput := sh3;
    s.parietalSignal       := parietal;
    s.historyIdx           := hIdx;
    s
  };

  // 50-beat mean for trend
  public func territoryTrend(s: TerritoryState) : Float {
    var sum = 0.0;
    for (v in s.historyComposite.vals()) { sum += v; };
    Float.max(1.0, sum / 50.0)
  };

};
