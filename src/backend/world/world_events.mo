import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// WORLD EVENTS ENGINE — PARALLAX PHASE K
// 24 event types, probability distributions, event chains,
// event -> neurochemical spike, event -> territory pressure
// ============================================================
module {

  // Event type codes (numeric only, names in VERITAS)
  // WE-00: Bull breakout
  // WE-01: Bear breakdown
  // WE-02: Whale accumulation
  // WE-03: Whale distribution
  // WE-04: Protocol hack
  // WE-05: Protocol launch
  // WE-06: Regulatory crackdown
  // WE-07: Institutional adoption
  // WE-08: Macroeconomic shock
  // WE-09: Liquidity injection
  // WE-10: Halving event
  // WE-11: Fork / split
  // WE-12: Exchange listing
  // WE-13: Exchange delisting
  // WE-14: Flash crash
  // WE-15: Parabolic run
  // WE-16: Sideways consolidation
  // WE-17: DeFi TVL expansion
  // WE-18: DeFi rug / exploit
  // WE-19: Governance proposal pass
  // WE-20: Governance proposal fail
  // WE-21: Network congestion spike
  // WE-22: Black swan negative
  // WE-23: Black swan positive
  let NUM_EVENTS : Nat = 24;

  public type WorldEvent = {
    eventCode      : Nat;         // WE-00 through WE-23
    magnitude      : Float;       // Impact magnitude [1.0, 2.0]
    duration       : Nat;         // Duration in beats
    beatsRemaining : Nat;         // Beats until event clears
    dopamineSpike  : Float;       // Neurochemical injection
    cortisolSpike  : Float;
    testosteroneSpike : Float;
    adrenalineSpike   : Float;
    territoryDelta    : Float;    // Territory impact [-0.5, +0.5]
    formaDelta        : Float;    // FORMA energy delta
    mrcDelta          : Float;    // Direct MRC impact
  };

  public type WorldEventState = {
    var activeEvents     : [var ?WorldEvent]; // Up to 8 simultaneous events
    var eventSlots       : Nat;               // Current active count
    var eventProbability : [var Float];       // Per-event-type base probability
    var recentEventCodes : [var Nat];         // Last 20 events (ring)
    var recentIdx        : Nat;
    var totalEventsAll   : Nat;
    var totalPositive    : Nat;
    var totalNegative    : Nat;
    var worldMoodIndex   : Float;             // Aggregate sentiment [1.0, 2.0]
    var worldVolatility  : Float;             // EMA of event magnitudes
    var blackSwanArmed   : Bool;              // Black swan can fire
    var blackSwanCooldown: Nat;              // Beats until next black swan possible
    var eventChainCode   : Nat;              // Next chained event code (0=none)
    var eventChainBeats  : Nat;              // Beats until chain fires
    var netTerritoryImpact : Float;          // Sum of active territory deltas
    var netFormaImpact     : Float;
    var netMrcImpact       : Float;
    var cortisol           : Float;          // Current cortisol contribution
    var dopamine           : Float;          // Current dopamine contribution
  };

  public func initWorldEventState() : WorldEventState = {
    var activeEvents     = Array.init<?WorldEvent>(8, null);
    var eventSlots       = 0;
    var eventProbability = Array.init<Float>(NUM_EVENTS, 0.001);
    var recentEventCodes = Array.init<Nat>(20, 0);
    var recentIdx        = 0;
    var totalEventsAll   = 0;
    var totalPositive    = 0;
    var totalNegative    = 0;
    var worldMoodIndex   = 1.5;  // Start optimistic
    var worldVolatility  = 1.0;
    var blackSwanArmed   = true;
    var blackSwanCooldown= 0;
    var eventChainCode   = 0;
    var eventChainBeats  = 0;
    var netTerritoryImpact = 0.0;
    var netFormaImpact   = 0.0;
    var netMrcImpact     = 0.0;
    var cortisol         = 1.0;
    var dopamine         = 1.0;
  };

  // Event parameters table: (magnitude, duration, dopSpike, cortSpike, testSpike, adrenSpike, terrDelta, formaDelta, mrcDelta, isPositive)
  // Index = event code WE-00 through WE-23
  func eventParams(code: Nat) : (Float, Nat, Float, Float, Float, Float, Float, Float, Float) {
    if      (code == 0)  (1.7, 500,  0.5,  0.1,  0.4,  0.1,  0.3,  20.0, 5.0)   // WE-00 bull breakout
    else if (code == 1)  (1.6, 400,  0.0,  0.6,  0.0, -0.2, -0.3, -15.0,-3.0)   // WE-01 bear breakdown
    else if (code == 2)  (1.4, 300,  0.3,  0.0,  0.2,  0.0,  0.2,  10.0, 2.0)   // WE-02 whale accum
    else if (code == 3)  (1.5, 350,  0.0,  0.4,  0.1,  0.1, -0.2, -10.0,-2.0)   // WE-03 whale distrib
    else if (code == 4)  (1.8, 200,  0.0,  0.8,  0.0,  0.5, -0.4, -25.0,-5.0)   // WE-04 hack
    else if (code == 5)  (1.6, 600,  0.6,  0.0,  0.3,  0.2,  0.4,  30.0, 8.0)   // WE-05 protocol launch
    else if (code == 6)  (1.7, 800,  0.0,  0.7,  0.0,  0.3, -0.3, -20.0,-4.0)   // WE-06 regulatory
    else if (code == 7)  (1.9, 1000, 0.8,  0.0,  0.5,  0.2,  0.5,  50.0,12.0)   // WE-07 institutional
    else if (code == 8)  (1.8, 300,  0.0,  0.9,  0.0,  0.7, -0.4, -30.0,-7.0)   // WE-08 macro shock
    else if (code == 9)  (1.7, 500,  0.5,  0.0,  0.3,  0.1,  0.3,  25.0, 6.0)   // WE-09 liquidity
    else if (code == 10) (2.0, 2000, 0.9,  0.0,  0.7,  0.3,  0.6,  80.0,20.0)   // WE-10 halving
    else if (code == 11) (1.5, 400,  0.2,  0.4,  0.1,  0.2, -0.1, -5.0, -1.0)   // WE-11 fork
    else if (code == 12) (1.4, 200,  0.4,  0.0,  0.2,  0.1,  0.2,  8.0,  2.0)   // WE-12 listing
    else if (code == 13) (1.4, 200,  0.0,  0.3,  0.0,  0.1, -0.2, -8.0, -2.0)   // WE-13 delisting
    else if (code == 14) (1.8, 100,  0.0,  0.9,  0.0,  0.8, -0.3, -20.0,-5.0)   // WE-14 flash crash
    else if (code == 15) (2.0, 700,  0.9,  0.0,  0.8,  0.4,  0.6,  60.0,15.0)   // WE-15 parabolic
    else if (code == 16) (1.1, 1500, 0.1,  0.1,  0.0,  0.0,  0.0,  0.0,  0.0)   // WE-16 sideways
    else if (code == 17) (1.6, 800,  0.5,  0.0,  0.3,  0.1,  0.3,  20.0, 5.0)   // WE-17 DeFi TVL
    else if (code == 18) (1.7, 200,  0.0,  0.7,  0.0,  0.4, -0.3, -15.0,-4.0)   // WE-18 rug/exploit
    else if (code == 19) (1.3, 300,  0.3,  0.0,  0.2,  0.0,  0.2,  5.0,  1.0)   // WE-19 gov pass
    else if (code == 20) (1.2, 150,  0.0,  0.2,  0.0,  0.1, -0.1, -3.0, -0.5)   // WE-20 gov fail
    else if (code == 21) (1.4, 100,  0.0,  0.4,  0.0,  0.3, -0.1, -5.0, -1.0)   // WE-21 congestion
    else if (code == 22) (2.0, 500,  0.0,  1.0,  0.0,  1.0, -0.5, -50.0,-10.0)  // WE-22 black swan -
    else                 (2.0, 500,  1.0,  0.0,  1.0,  0.5,  0.5,  100.0,25.0)   // WE-23 black swan +
  };

  // Pseudo-random event trigger from beat and organism state
  // Uses FNV-1a to generate reproducible deterministic events
  func fnv1a32(beat: Nat, seed: Nat) : Nat32 {
    var h : Nat32 = 2166136261;
    let b1 : Nat32 = Nat32.fromNat(beat % 0xFFFFFFFF);
    let b2 : Nat32 = Nat32.fromNat(seed % 0xFFFFFFFF);
    h ^= b1; h *%= 16777619;
    h ^= b2; h *%= 16777619;
    h
  };

  // Event chain rules: WE-04 hack -> WE-06 regulatory (after 500 beats)
  // WE-07 institutional -> WE-00 bull breakout (after 200 beats)
  // WE-00 bull breakout -> WE-15 parabolic (after 1000 beats)
  func eventChainTarget(code: Nat) : (Nat, Nat) {
    if      (code == 4)  (6,  500)   // hack -> regulatory
    else if (code == 7)  (0,  200)   // institutional -> bull
    else if (code == 0)  (15, 1000)  // bull -> parabolic
    else if (code == 1)  (8,  300)   // bear -> macro shock
    else if (code == 15) (3,  700)   // parabolic -> whale distrib
    else                 (0,  0)     // no chain
  };

  func isPositiveEvent(code: Nat) : Bool {
    code == 0 or code == 2 or code == 5 or code == 7 or
    code == 9 or code == 10 or code == 12 or code == 15 or
    code == 17 or code == 19 or code == 23
  };

  public func updateWorldEvents(
    s          : WorldEventState,
    beatCount  : Nat,
    coherenceC : Float,
    regime     : Nat    // Overall market regime 0-3
  ) : WorldEventState {
    // Tick down active events
    var newTerr = 0.0;
    var newForma = 0.0;
    var newMrc   = 0.0;
    var newCort  = 1.0;
    var newDopa  = 1.0;
    var activeSlots = 0;

    var i = 0;
    while (i < 8) {
      switch (s.activeEvents[i]) {
        case null {};
        case (?ev) {
          if (ev.beatsRemaining > 1) {
            s.activeEvents[i] := ?{
              eventCode      = ev.eventCode;
              magnitude      = ev.magnitude;
              duration       = ev.duration;
              beatsRemaining = ev.beatsRemaining - 1;
              dopamineSpike  = ev.dopamineSpike;
              cortisolSpike  = ev.cortisolSpike;
              testosteroneSpike = ev.testosteroneSpike;
              adrenalineSpike   = ev.adrenalineSpike;
              territoryDelta    = ev.territoryDelta;
              formaDelta        = ev.formaDelta;
              mrcDelta          = ev.mrcDelta;
            };
            newTerr  += ev.territoryDelta  / Float.fromInt(ev.duration);
            newForma += ev.formaDelta      / Float.fromInt(ev.duration);
            newMrc   += ev.mrcDelta        / Float.fromInt(ev.duration);
            newCort  += ev.cortisolSpike   / Float.fromInt(ev.duration);
            newDopa  += ev.dopamineSpike   / Float.fromInt(ev.duration);
            activeSlots += 1;
          } else {
            s.activeEvents[i] := null;
          };
        };
      };
      i += 1;
    };

    // Event chain trigger
    var chainCode = s.eventChainCode;
    var chainBeats = s.eventChainBeats;
    if (chainBeats > 0) {
      chainBeats -= 1;
    };
    // Fire chained event when timer expires and slot available
    var fired = false;
    if (chainBeats == 0 and chainCode > 0 and activeSlots < 8) {
      // Find empty slot and insert
      var j = 0;
      while (j < 8 and not fired) {
        switch (s.activeEvents[j]) {
          case null {
            let (mag, dur, dsp, csp, tsp, asp, td, fd, md) = eventParams(chainCode);
            s.activeEvents[j] := ?{
              eventCode = chainCode; magnitude = mag; duration = dur;
              beatsRemaining = dur; dopamineSpike = dsp; cortisolSpike = csp;
              testosteroneSpike = tsp; adrenalineSpike = asp;
              territoryDelta = td; formaDelta = fd; mrcDelta = md;
            };
            fired := true;
          };
          case (?_) {};
        };
        j += 1;
      };
      chainCode  := 0;
      chainBeats := 0;
    };

    // Probabilistic event spawning
    let rng = fnv1a32(beatCount, Nat32.toNat(Nat32.fromNat(regime)));
    let rngNorm = Float.fromInt(Nat32.toNat(rng)) / 4294967295.0;
    // Base prob scaled by regime and coherence
    let baseProbMulti = Float.fromInt(regime + 1) * coherenceC * 0.5;
    let threshold = 0.003 * baseProbMulti; // ~0.003-0.006 per beat at bull + C=1.0

    var newTotalPos = s.totalPositive;
    var newTotalNeg = s.totalNegative;
    var newTotalAll = s.totalEventsAll;
    var rIdx = s.recentIdx;
    var newBlackSwanCD = if (s.blackSwanCooldown > 0) s.blackSwanCooldown - 1 else 0;

    if (rngNorm < threshold and activeSlots < 7) {
      // Determine which event to spawn
      let rng2  = fnv1a32(beatCount + 1, regime + 100);
      let rng2N = Nat32.toNat(rng2);
      // Weight: positive events more likely in bull regime
      let eventBase = rng2N % NUM_EVENTS;
      // Black swan: only fire if armed and CD = 0, very low prob
      let rng3 = fnv1a32(beatCount + 7, 999);
      let bsProb = Float.fromInt(Nat32.toNat(rng3)) / 4294967295.0;
      let spawnCode = if (bsProb < 0.0001 and s.blackSwanArmed and newBlackSwanCD == 0) {
        newBlackSwanCD := 100000; // 100k beat cooldown
        if (regime >= 2) 23 else 22
      } else eventBase;

      // Find empty slot
      var k = 0;
      var spawned = false;
      while (k < 8 and not spawned) {
        switch (s.activeEvents[k]) {
          case null {
            let (mag, dur, dsp, csp, tsp, asp, td, fd, md) = eventParams(spawnCode);
            s.activeEvents[k] := ?{
              eventCode = spawnCode; magnitude = mag; duration = dur;
              beatsRemaining = dur; dopamineSpike = dsp; cortisolSpike = csp;
              testosteroneSpike = tsp; adrenalineSpike = asp;
              territoryDelta = td; formaDelta = fd; mrcDelta = md;
            };
            spawned := true;
            newTotalAll += 1;
            if (isPositiveEvent(spawnCode)) newTotalPos += 1
            else newTotalNeg += 1;
            // Record
            rIdx := (rIdx + 1) % 20;
            s.recentEventCodes[rIdx] := spawnCode;
            // Set up chain
            let (chainTarget, chainDelay) = eventChainTarget(spawnCode);
            if (chainTarget > 0 and chainDelay > 0 and chainCode == 0) {
              chainCode  := chainTarget;
              chainBeats := chainDelay;
            };
          };
          case (?_) {};
        };
        k += 1;
      };
    };

    // World mood index: EMA of (positive - negative) balance
    let moodDelta = if (newTotalAll > 0)
      (Float.fromInt(newTotalPos) - Float.fromInt(newTotalNeg)) / Float.fromInt(newTotalAll)
    else 0.0;
    let newMood = Float.max(1.0, Float.min(2.0, s.worldMoodIndex * 0.9999 + (moodDelta + 1.0) * 0.0001));

    // World volatility: EMA of |territory impact|
    let wv = Float.max(1.0, s.worldVolatility * 0.99 + Float.abs(newTerr) * 0.1);

    s.eventSlots       := activeSlots;
    s.recentIdx        := rIdx;
    s.totalEventsAll   := newTotalAll;
    s.totalPositive    := newTotalPos;
    s.totalNegative    := newTotalNeg;
    s.worldMoodIndex   := newMood;
    s.worldVolatility  := wv;
    s.blackSwanCooldown := newBlackSwanCD;
    s.eventChainCode   := chainCode;
    s.eventChainBeats  := chainBeats;
    s.netTerritoryImpact := newTerr;
    s.netFormaImpact   := newForma;
    s.netMrcImpact     := newMrc;
    s.cortisol         := Float.max(1.0, newCort);
    s.dopamine         := Float.max(1.0, newDopa);
    s
  };

};
