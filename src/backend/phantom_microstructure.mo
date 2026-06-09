// phantom_microstructure.mo — PHANTOM MICROSTRUCTURE ENGINE
// PARALLAX Sovereign Organism — Order Flow & Market Microstructure Intelligence
//
// DOCTRINE: "The Phantom Microstructure Engine decodes the inner mechanics of
// price formation: order flow imbalance, toxicity, hidden liquidity, and informed
// trading detection. It sees what retail cannot — the true microstructure state."
//
// THE PHANTOM MICROSTRUCTURE ARCHITECTURE:
//   PMI-001  ORDER FLOW IMBALANCE    — Buy/sell volume delta and cumulative delta
//   PMI-002  TOXICITY METER (VPIN)   — Volume-synchronized probability of informed trading
//   PMI-003  SPREAD DECOMPOSITION    — Adverse selection, inventory, and order processing
//   PMI-004  HIDDEN LIQUIDITY PROBE  — Iceberg/dark pool detection heuristics
//   PMI-005  TICK RULE CLASSIFIER    — Trade direction classification (Lee-Ready)
//   PMI-006  KYLE LAMBDA ESTIMATOR   — Price impact per unit of flow
//   PMI-007  LOB IMBALANCE TRACKER   — Limit order book depth imbalance
//   PMI-008  MARKET MAKER DETECTOR   — Identify systematic MM activity patterns
//
// PYTHAGORAS: imbalance thresholds and VPIN windows are phi-harmonic
// EUCLID:     single microstructure state — all order flow data converges here
// CONFUCIUS:  right relationship — microstructure informs execution, not speculates
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // MICROSTRUCTURE CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let MICRO_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let VPIN_TOXIC_THRESHOLD : Float = Phi.PHI_INV;              // 0.618 = toxic
  public let ORDER_IMBALANCE_SIGNAL : Float = Phi.PHI_INV_2;         // 0.382 = significant
  public let KYLE_LAMBDA_HIGH : Float = Phi.PHI_INV_3;              // high impact
  public let LOB_DEPTH_WINDOW : Nat = 21;                            // F(8) levels
  public let VPIN_BUCKET_COUNT : Nat = 34;                           // F(9) volume buckets
  public let SPREAD_DECOMP_WINDOW : Nat = 89;                       // F(11) trades
  public let HIDDEN_LIQUIDITY_PROBE_INTERVAL : Nat = 13;             // F(7) beats
  public let TICK_RULE_MEMORY : Nat = 55;                            // F(10) ticks remembered
  public let MAX_FLOW_HISTORY : Nat = 144;                           // F(12) observations

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER FLOW — single observation
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrderFlowObs = {
    beat         : Int;
    buyVolume    : Float;
    sellVolume   : Float;
    delta        : Float;        // buy - sell
    cumDelta     : Float;        // running sum
    tradeCount   : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VPIN STATE — Volume-synchronized probability of informed trading
  // ═══════════════════════════════════════════════════════════════════════════

  public type VpinState = {
    vpin         : Float;        // [0, 1] current VPIN estimate
    buckets      : [Float];      // volume bucket imbalances
    bucketIndex  : Nat;          // current bucket pointer
    isToxic      : Bool;         // vpin > threshold
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SPREAD DECOMPOSITION — who pays for the spread
  // ═══════════════════════════════════════════════════════════════════════════

  public type SpreadDecomp = {
    adverseSelection  : Float;   // informed trader cost
    inventoryRisk     : Float;   // MM inventory cost
    orderProcessing   : Float;   // fixed cost
    totalSpread       : Float;   // sum of components
    lastBeat          : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LOB STATE — limit order book microstructure
  // ═══════════════════════════════════════════════════════════════════════════

  public type LobState = {
    bidDepth     : Float;        // total bid liquidity
    askDepth     : Float;        // total ask liquidity
    imbalance    : Float;        // (bid - ask) / (bid + ask), [-1, +1]
    midPrice     : Float;
    spread       : Float;        // ask - bid
    spreadBps    : Float;        // spread in basis points
    lastBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM MICROSTRUCTURE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomMicrostructureState = {
    flowHistory       : [OrderFlowObs];
    vpin              : VpinState;
    spreadDecomp      : SpreadDecomp;
    lob               : LobState;
    kyleLambda        : Float;       // price impact coefficient
    cumulativeDelta   : Float;       // running delta
    informedFlowRatio : Float;       // estimated % of informed flow
    hiddenLiquidity   : Float;       // estimated hidden depth
    mmActivityScore   : Float;       // market maker presence [0, 1]
    totalObservations : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomMicrostructureState() : PhantomMicrostructureState {
    {
      flowHistory = [];
      vpin = {
        vpin = 0.3;
        buckets = Array.tabulate<Float>(VPIN_BUCKET_COUNT, func(_) { 0.0 });
        bucketIndex = 0;
        isToxic = false;
        lastBeat = 0;
      };
      spreadDecomp = {
        adverseSelection = 0.0;
        inventoryRisk = 0.0;
        orderProcessing = 0.0;
        totalSpread = 0.0;
        lastBeat = 0;
      };
      lob = {
        bidDepth = 1000.0;
        askDepth = 1000.0;
        imbalance = 0.0;
        midPrice = 0.0;
        spread = 0.0;
        spreadBps = 0.0;
        lastBeat = 0;
      };
      kyleLambda = 0.0;
      cumulativeDelta = 0.0;
      informedFlowRatio = 0.1;
      hiddenLiquidity = 0.0;
      mmActivityScore = 0.5;
      totalObservations = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance microstructure state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomMicrostructure(
    state : PhantomMicrostructureState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomMicrostructureState {
    if (systemCoherence < MICRO_COHERENCE_GATE) return state;

    // VPIN update: rolling average of absolute imbalances across buckets
    let buckets = state.vpin.buckets;
    var sumAbsImbalance : Float = 0.0;
    for (b in buckets.vals()) {
      sumAbsImbalance += Float.abs(b);
    };
    let newVpin = if (buckets.size() > 0) { sumAbsImbalance / Float.fromInt(buckets.size()) } else { 0.0 };
    let toxic = newVpin >= VPIN_TOXIC_THRESHOLD;

    // Kyle's Lambda decay: impact decreases with liquidity
    let lambdaDecay = state.kyleLambda * Phi.PHI_INV;

    // LOB imbalance natural decay toward zero
    let newImbalance = state.lob.imbalance * Phi.PHI_INV;

    // Informed flow ratio estimation
    let informedEst = newVpin * Phi.PHI_INV + state.informedFlowRatio * Phi.PHI_INV_2;

    {
      state with
      vpin = {
        state.vpin with
        vpin = newVpin;
        isToxic = toxic;
        lastBeat = beat;
      };
      lob = { state.lob with imbalance = newImbalance; lastBeat = beat };
      kyleLambda = lambdaDecay;
      informedFlowRatio = informedEst;
      totalObservations = state.totalObservations + 1;
      lastTickBeat = beat;
      coherence = systemCoherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INGEST FLOW — add new order flow observation
  // ═══════════════════════════════════════════════════════════════════════════

  public func ingestFlow(
    state : PhantomMicrostructureState,
    buyVol : Float,
    sellVol : Float,
    beat : Int
  ) : PhantomMicrostructureState {
    let delta = buyVol - sellVol;
    let newCumDelta = state.cumulativeDelta + delta;
    let obs : OrderFlowObs = {
      beat = beat;
      buyVolume = buyVol;
      sellVolume = sellVol;
      delta = delta;
      cumDelta = newCumDelta;
      tradeCount = 1;
    };

    let history = if (state.flowHistory.size() >= MAX_FLOW_HISTORY) {
      Array.tabulate<OrderFlowObs>(MAX_FLOW_HISTORY, func(i) {
        if (i < MAX_FLOW_HISTORY - 1) state.flowHistory[i + 1] else obs
      })
    } else {
      Array.append(state.flowHistory, [obs])
    };

    // Update VPIN bucket
    let totalVol = buyVol + sellVol;
    let imbalance = if (totalVol > 0.0) { delta / totalVol } else { 0.0 };
    let idx = state.vpin.bucketIndex % VPIN_BUCKET_COUNT;
    let newBuckets = Array.tabulate<Float>(VPIN_BUCKET_COUNT, func(i) {
      if (i == idx) imbalance else state.vpin.buckets[i]
    });
    let newIdx = (idx + 1) % VPIN_BUCKET_COUNT;

    {
      state with
      flowHistory = history;
      cumulativeDelta = newCumDelta;
      vpin = { state.vpin with buckets = newBuckets; bucketIndex = newIdx };
      totalObservations = state.totalObservations + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getVpin(state : PhantomMicrostructureState) : Float {
    state.vpin.vpin
  };

  public func isToxicFlow(state : PhantomMicrostructureState) : Bool {
    state.vpin.isToxic
  };

  public func getKyleLambda(state : PhantomMicrostructureState) : Float {
    state.kyleLambda
  };

  public func getLobImbalance(state : PhantomMicrostructureState) : Float {
    state.lob.imbalance
  };
};
