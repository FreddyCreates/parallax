import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// PROFIT STREAMS ENGINE — PARALLAX PHASE K
// All 22 sovereign profit streams, fully wired to FORMA + MRC
// Stream codes PS-01 through PS-22 (numeric only in code)
// All names mapped in VERITAS vault (owner-only)
// ============================================================
module {

  let NUM_STREAMS : Nat = 22;

  public type ProfitStream = {
    var active       : Bool;
    var allocation   : Float;   // Capital allocation
    var baseRate     : Float;   // Base yield rate per beat
    var actualRate   : Float;   // Realized rate (modulated)
    var yieldBeat    : Float;   // Yield this beat
    var yieldLife    : Float;   // Lifetime yield
    var mrcCut       : Float;   // MRC fraction (always 0.20)
    var formaCut     : Float;   // FORMA energy fraction
    var multiplier   : Float;   // Coherence/organism multiplier
    var gateMin      : Float;   // Minimum FORMA required to activate
    var lastActive   : Nat;     // Beat last active
    var streak       : Nat;     // Consecutive active beats
  };

  public type ProfitStreamsState = {
    var streams         : [var ProfitStream];
    var totalYieldBeat  : Float;
    var totalMrcBeat    : Float;
    var totalFormaBeat  : Float;
    var totalYieldLife  : Float;
    var activeStreamCount : Nat;
    var streamHealthIndex : Float; // Fraction of streams active * yield quality
    var diversityScore    : Float; // How many streams contributing
    var projectedDaily    : Float; // Projected daily yield at current rate
    var projectedMonthly  : Float;
    var projectedAnnual   : Float;
    var sovereignYield    : Float; // Net yield after MRC to creator
    var dominantStream    : Nat;   // Highest-yielding stream index
    var compoundFactor    : Float; // Reinvestment multiplier
  };

  // Stream initialization parameters (baseRate per beat, gateMin)
  // PS-01: Organic heartbeat minting
  // PS-02: Succession royalties (child orgs)
  // PS-03: Model licensing / store
  // PS-04: NOVA network compounding
  // PS-05: Lido ETH staking
  // PS-06: EigenLayer restaking
  // PS-07: Marinade SOL staking
  // PS-08: Jito MEV staking
  // PS-09: NNS neuron rewards
  // PS-10: BTC DeFi yield
  // PS-11: Cross-chain arbitrage
  // PS-12: Maxwell's Demon yield (entropy reduction)
  // PS-13: Quantum battery discharge
  // PS-14: MEDINA patent events
  // PS-15: Territory expansion royalties
  // PS-16: Temporal dilation FORMA
  // PS-17: Superposition collapse yield
  // PS-18: ARES rollback savings (prevented losses)
  // PS-19: Governance participation rewards
  // PS-20: MCT prestige minting
  // PS-21: RST reserve token appreciation
  // PS-22: DRT doctrine royalties
  func initStream(baseRate: Float, gateMin: Float, alloc: Float) : ProfitStream = {
    var active       = true;
    var allocation   = alloc;
    var baseRate     = baseRate;
    var actualRate   = baseRate;
    var yieldBeat    = 0.0;
    var yieldLife    = 0.0;
    var mrcCut       = 0.20;
    var formaCut     = 0.10;
    var multiplier   = 1.0;
    var gateMin      = gateMin;
    var lastActive   = 0;
    var streak       = 0;
  };

  public func initProfitStreamsState() : ProfitStreamsState = {
    var streams = [
      var initStream(0.000100, 10.0,   100.0),   // PS-01 organic minting
          initStream(0.000050, 50.0,   50.0),    // PS-02 succession royalties
          initStream(0.000020, 100.0,  200.0),   // PS-03 model licensing
          initStream(0.000030, 80.0,   150.0),   // PS-04 NOVA network
          initStream(0.000026, 30.0,   300.0),   // PS-05 Lido ETH
          initStream(0.000034, 50.0,   200.0),   // PS-06 EigenLayer
          initStream(0.000052, 40.0,   200.0),   // PS-07 Marinade SOL
          initStream(0.000059, 60.0,   100.0),   // PS-08 Jito MEV
          initStream(0.000125, 20.0,   100.0),   // PS-09 NNS neurons
          initStream(0.000015, 150.0,  100.0),   // PS-10 BTC DeFi
          initStream(0.000040, 200.0,  50.0),    // PS-11 arbitrage
          initStream(0.000200, 0.0,    0.0),     // PS-12 Maxwell's Demon
          initStream(0.000150, 0.0,    0.0),     // PS-13 quantum battery
          initStream(0.000500, 0.0,    0.0),     // PS-14 patent events
          initStream(0.000080, 100.0,  0.0),     // PS-15 territory royalties
          initStream(0.000100, 0.0,    0.0),     // PS-16 temporal dilation
          initStream(0.000200, 0.0,    0.0),     // PS-17 superposition
          initStream(0.000300, 0.0,    0.0),     // PS-18 ARES savings
          initStream(0.000010, 10.0,   0.0),     // PS-19 governance
          initStream(0.001000, 500.0,  0.0),     // PS-20 MCT prestige
          initStream(0.000050, 200.0,  50.0),    // PS-21 RST appreciation
          initStream(0.000030, 150.0,  0.0)      // PS-22 DRT doctrine
    ];
    var totalYieldBeat    = 0.0;
    var totalMrcBeat      = 0.0;
    var totalFormaBeat    = 0.0;
    var totalYieldLife    = 0.0;
    var activeStreamCount = 22;
    var streamHealthIndex = 1.0;
    var diversityScore    = 1.0;
    var projectedDaily    = 0.0;
    var projectedMonthly  = 0.0;
    var projectedAnnual   = 0.0;
    var sovereignYield    = 0.0;
    var dominantStream    = 0;
    var compoundFactor    = 1.0;
  };

  // Per-stream multiplier based on coherence and stream type
  func streamMultiplier(
    streamIdx  : Nat,
    coherenceC : Float,
    formaCapital: Float,
    deltaH     : Float,   // MEDINA entropy reduction
    beatCount  : Nat
  ) : Float {
    let cBase = coherenceC - 1.0; // [0, 1)
    if (streamIdx == 0) {
      // PS-01: scales with coherence squared
      1.0 + cBase * cBase * 2.0
    } else if (streamIdx == 1) {
      // PS-02: scales with NOVA network size (use formaCapital proxy)
      1.0 + Float.min(1.0, formaCapital / 10000.0)
    } else if (streamIdx == 2) {
      // PS-03: licensing scales with beat count (reputation)
      1.0 + Float.min(0.5, Float.fromInt(beatCount) / 1000000.0)
    } else if (streamIdx == 3) {
      // PS-04: NOVA geometric mean (use coherence proxy)
      1.0 + cBase * 1.5
    } else if (streamIdx <= 9) {
      // PS-05 through PS-10: staking/DeFi, scale with coherence linearly
      1.0 + cBase * 0.8
    } else if (streamIdx == 10) {
      // PS-11: arbitrage, scales with market volatility (inverse coherence)
      1.0 + (1.0 - cBase) * 0.5
    } else if (streamIdx == 11) {
      // PS-12: Maxwell's Demon = deltaH * 10
      Float.max(1.0, 1.0 + deltaH * 10.0)
    } else if (streamIdx == 12) {
      // PS-13: quantum battery = coherence squared
      1.0 + cBase * cBase * 3.0
    } else if (streamIdx == 13) {
      // PS-14: patent events, rare high-value
      if (deltaH > 0.25) 5.0 else 1.0 + deltaH * 4.0
    } else if (streamIdx == 15) {
      // PS-16: temporal dilation = dilation count proxy
      1.0 + cBase * 2.0
    } else if (streamIdx == 16) {
      // PS-17: superposition collapse
      1.0 + cBase * cBase * 4.0
    } else if (streamIdx == 17) {
      // PS-18: ARES savings = cortisol proxy (use coherence deviation)
      1.0 + Float.max(0.0, 1.0 - coherenceC) * 3.0
    } else if (streamIdx == 19) {
      // PS-20: MCT prestige = very high coherence
      if (coherenceC > 1.8) 10.0
      else if (coherenceC > 1.5) 3.0
      else 1.0
    } else {
      1.0 + cBase * 0.5
    }
  };

  public func updateProfitStreams(
    s            : ProfitStreamsState,
    coherenceC   : Float,
    formaCapital : Float,
    deltaH       : Float,
    beatCount    : Nat
  ) : ProfitStreamsState {
    var totalYield = 0.0;
    var totalMrc   = 0.0;
    var totalForma = 0.0;
    var activeCount = 0;
    var bestYield = 0.0;
    var bestIdx   = 0;
    var i = 0;

    for (p in s.streams.vals()) {
      // Gate check: FORMA must be above gate minimum
      let gated = formaCapital >= p.gateMin;

      if (gated and p.active) {
        // Compute multiplier
        let mult = streamMultiplier(i, coherenceC, formaCapital, deltaH, beatCount);
        p.multiplier := mult;

        // Actual rate = base * multiplier
        let rate = p.baseRate * mult;
        p.actualRate := rate;

        // Yield = allocation * rate (for allocation-based streams)
        // For allocation=0 streams, yield comes from rate directly
        let rawYield = if (p.allocation > 0.0) p.allocation * rate else rate * formaCapital * 0.001;
        p.yieldBeat  := rawYield;
        p.yieldLife  := p.yieldLife + rawYield;
        p.streak     := p.streak + 1;
        p.lastActive := beatCount;

        let mrcY   = rawYield * p.mrcCut;
        let formaY = rawYield * p.formaCut;

        totalYield += rawYield;
        totalMrc   += mrcY;
        totalForma += formaY;
        activeCount += 1;

        if (rawYield > bestYield) { bestYield := rawYield; bestIdx := i; };

        // Allocation grows via compounding (allocation-based only)
        if (p.allocation > 0.0) {
          p.allocation := p.allocation + rawYield * (1.0 - p.mrcCut - p.formaCut);
        };
      } else {
        p.yieldBeat := 0.0;
        p.streak    := 0;
      };
      i += 1;
    };

    // Stream health index: (active/total) * yield quality
    let health = Float.max(1.0,
      (Float.fromInt(activeCount) / Float.fromInt(NUM_STREAMS)) +
      Float.min(1.0, totalYield / 10.0)
    );

    // Diversity: Herfindahl on yields
    var hhi = 0.0;
    for (p in s.streams.vals()) {
      let w = if (totalYield > 0.0) p.yieldBeat / totalYield else 0.0;
      hhi += w * w;
    };
    let div = Float.max(1.0, 1.0 + (1.0 - Float.min(1.0, hhi)));

    // Projections (144 beats/day)
    let daily   = totalYield * 144.0;
    let monthly = daily * 30.0;
    let annual  = daily * 365.0;

    // Sovereign yield: net after MRC
    let sovYield = totalYield - totalMrc;

    // Compound factor: cumulative reinvestment
    let newCF = s.compoundFactor * (1.0 + totalYield / Float.max(1.0, formaCapital) * 0.01);

    s.totalYieldBeat    := totalYield;
    s.totalMrcBeat      := totalMrc;
    s.totalFormaBeat    := totalForma;
    s.totalYieldLife    := s.totalYieldLife + totalYield;
    s.activeStreamCount := activeCount;
    s.streamHealthIndex := health;
    s.diversityScore    := div;
    s.projectedDaily    := daily;
    s.projectedMonthly  := monthly;
    s.projectedAnnual   := annual;
    s.sovereignYield    := sovYield;
    s.dominantStream    := bestIdx;
    s.compoundFactor    := Float.min(1000.0, newCF);
    s
  };

  // Get stream yield by index
  public func streamYield(s: ProfitStreamsState, idx: Nat) : Float {
    if (idx >= NUM_STREAMS) 0.0
    else s.streams[idx].yieldBeat
  };

  // Total lifetime sovereign yield
  public func lifetimeSovereign(s: ProfitStreamsState) : Float {
    s.totalYieldLife * (1.0 - 0.20) // After 20% MRC
  };

};
