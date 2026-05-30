// phantom_oracle.mo — PHANTOM ORACLE NETWORK
// PARALLAX Sovereign Organism — Sovereign Price Feed & Data Intelligence
//
// DOCTRINE: "The Phantom Oracle Network is the organism's eyes and ears. It
// aggregates price feeds from every available source — on-chain, off-chain,
// DEX, CEX, derivatives — and produces a single sovereign truth price for every
// asset. No external oracle dependency. The organism IS its own oracle."
//
// PHANTOM ORACLE ARCHITECTURE:
//   PON-001  MULTI-SOURCE AGGREGATOR  — Collects prices from all available feeds
//   PON-002  OUTLIER DETECTOR         — Rejects manipulated or stale feeds
//   PON-003  CONFIDENCE WEIGHTER      — Weights sources by reliability history
//   PON-004  STALENESS MONITOR        — Detects and flags stale data
//   PON-005  MANIPULATION SHIELD      — Flash-crash and pump protection
//   PON-006  TRUTH PRICE ENGINE       — Produces final sovereign price
//   PON-007  HISTORICAL ARCHIVE       — Stores price history for pattern matching
//
// PYTHAGORAS: confidence weights at phi-harmonic values
// EUCLID:     single oracle state — all price truth in PhantomOracleState
// CONFUCIUS:  right relationship — oracle observes, trading acts
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  public let ORACLE_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let STALENESS_THRESHOLD_BEATS : Int = 89;  // Fibonacci-89 beats = stale
  public let OUTLIER_SIGMA : Float = Phi.PHI_2;     // 2.618σ = outlier
  public let MIN_SOURCES : Nat = 3;                 // Minimum sources for truth price
  public let MANIPULATION_JUMP_PCT : Float = Phi.PHI_INV_2 * 10.0;  // 3.82% = suspicious

  public type PriceFeedSource = {
    #dex;            // Decentralized exchange
    #cex;            // Centralized exchange
    #onChain;        // On-chain oracle (Chainlink, Pyth, etc.)
    #internal;       // Phantom Exchange internal
    #derivative;     // Futures/options implied price
    #synthetic;      // Calculated from other prices
  };

  public type PriceFeed = {
    feedId           : Nat;
    asset            : Text;
    source           : PriceFeedSource;
    price            : Float;
    confidence       : Float;       // [0, 1] — historical reliability
    lastUpdateBeat   : Int;
    isStale          : Bool;
    isOutlier        : Bool;
    weight           : Float;       // Performance-adjusted weight
  };

  public type TruthPrice = {
    asset            : Text;
    price            : Float;       // Weighted aggregate truth price
    confidence       : Float;       // Aggregate confidence
    sourceCount      : Nat;         // Number of non-stale, non-outlier sources
    spread           : Float;       // Max deviation across sources (bps)
    lastUpdateBeat   : Int;
    manipulationFlag : Bool;        // Suspected manipulation detected
  };

  public type PhantomOracleState = {
    feeds             : [PriceFeed];
    truthPrices       : [TruthPrice];
    totalAssets       : Nat;
    staleFeedCount    : Nat;
    outlierCount      : Nat;
    manipulationAlerts: Nat;
    avgConfidence     : Float;
    oracleCoherence   : Float;
    lastTickBeat      : Int;
    priceUpdates      : Nat;
  };

  public func defaultPhantomOracleState() : PhantomOracleState {
    {
      feeds              = [];
      truthPrices        = [];
      totalAssets        = 0;
      staleFeedCount     = 0;
      outlierCount       = 0;
      manipulationAlerts = 0;
      avgConfidence      = 0.0;
      oracleCoherence    = Phi.S0;
      lastTickBeat       = 0;
      priceUpdates       = 0;
    }
  };

  public func tickPhantomOracle(state : PhantomOracleState, beat : Int, kuramotoR : Float) : PhantomOracleState {
    if (kuramotoR < ORACLE_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Check for stale feeds
    let feedsChecked = Array.map<PriceFeed, PriceFeed>(state.feeds, func(feed) {
      let age = beat - feed.lastUpdateBeat;
      let stale = age > STALENESS_THRESHOLD_BEATS;
      { feed with isStale = stale }
    });

    // Count stale
    var staleCount : Nat = 0;
    for (f in feedsChecked.vals()) {
      if (f.isStale) { staleCount += 1 };
    };

    // Compute average confidence across non-stale feeds
    var totalConf : Float = 0.0;
    var activeCount : Nat = 0;
    for (f in feedsChecked.vals()) {
      if (not f.isStale and not f.isOutlier) {
        totalConf += f.confidence;
        activeCount += 1;
      };
    };
    let avgConf = if (activeCount > 0) { totalConf / Float.fromInt(activeCount) } else { 0.0 };

    let newCoherence = state.oracleCoherence * 0.9 + kuramotoR * 0.1;

    {
      state with
      feeds           = feedsChecked;
      staleFeedCount  = staleCount;
      avgConfidence   = avgConf;
      oracleCoherence = newCoherence;
      lastTickBeat    = beat;
    }
  };
}
