// phantom_signal.mo — PHANTOM SIGNAL MATRIX
// PARALLAX Sovereign Organism — Multi-Source Signal Processing Framework
//
// DOCTRINE: "Every market movement is a signal. Every signal has a frequency,
// amplitude, phase, and decay. The Phantom Signal Matrix captures ALL signals —
// price, volume, order flow, sentiment, on-chain, social — and transforms them
// into actionable intelligence through phi-harmonic filtering."
//
// PHANTOM SIGNAL ARCHITECTURE:
//   PSM-001  PRICE SIGNAL EXTRACTOR     — Tick-by-tick price decomposition
//   PSM-002  VOLUME PROFILE ENGINE      — Volume-at-price analysis
//   PSM-003  ORDER FLOW DECODER         — Buy/sell pressure decomposition
//   PSM-004  SENTIMENT ANTENNA          — Multi-source sentiment aggregation
//   PSM-005  ON-CHAIN SIGNAL READER     — Blockchain activity signals
//   PSM-006  CROSS-SIGNAL CORRELATOR    — Inter-signal correlation detection
//   PSM-007  SIGNAL DECAY MANAGER       — Phi-derived signal lifetime management
//   PSM-008  CONFIDENCE AGGREGATOR      — Multi-signal confidence scoring
//
// PYTHAGORAS: signal filtering at phi-harmonic frequencies
// EUCLID:     single signal state — all sources unified in PhantomSignalState
// CONFUCIUS:  right relationship — signals inform, intelligence decides
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  public let SIGNAL_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let SIGNAL_DECAY_RATE : Float = Phi.PHI_INV;    // Decay by φ⁻¹ per beat
  public let MIN_SIGNAL_CONFIDENCE : Float = Phi.PHI_INV_2;  // 0.382 minimum
  public let MAX_ACTIVE_SIGNALS : Nat = 144;  // Fibonacci-144

  public type SignalSource = {
    #price;
    #volume;
    #orderFlow;
    #sentiment;
    #onChain;
    #social;
    #fundamental;
    #technical;
  };

  public type SignalStrength = {
    #weak;          // Below PHI_INV_3
    #moderate;      // PHI_INV_3 to PHI_INV_2
    #strong;        // PHI_INV_2 to PHI_INV
    #dominant;      // Above PHI_INV
  };

  public type PhantomSignal = {
    signalId         : Nat;
    source           : SignalSource;
    asset            : Text;
    direction        : Float;      // [-1, 1] — bearish to bullish
    magnitude        : Float;      // [0, PHI_4]
    confidence       : Float;      // [0, 1]
    frequency        : Float;      // Hz — signal oscillation frequency
    phase            : Float;      // [0, 2π]
    createdBeat      : Int;
    decayedMagnitude : Float;      // Current magnitude after decay
    strength         : SignalStrength;
  };

  public type PhantomSignalState = {
    activeSignals     : [PhantomSignal];
    totalSignalsEver  : Nat;
    compositeDirection: Float;      // Net directional signal [-1, 1]
    compositeConfidence: Float;     // Aggregate confidence [0, 1]
    dominantSource    : SignalSource;
    signalEntropy     : Float;      // Information entropy of signals
    crossCorrelation  : Float;      // Inter-signal correlation
    signalCoherence   : Float;      // Kuramoto R across signals
    lastTickBeat      : Int;
    signalsExpired    : Nat;
  };

  public func defaultPhantomSignalState() : PhantomSignalState {
    {
      activeSignals      = [];
      totalSignalsEver   = 0;
      compositeDirection = 0.0;
      compositeConfidence= 0.0;
      dominantSource     = #price;
      signalEntropy      = 0.0;
      crossCorrelation   = 0.0;
      signalCoherence    = Phi.S0;
      lastTickBeat       = 0;
      signalsExpired     = 0;
    }
  };

  public func tickPhantomSignal(state : PhantomSignalState, beat : Int, kuramotoR : Float) : PhantomSignalState {
    if (kuramotoR < SIGNAL_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Decay all active signals
    let decayed = Array.map<PhantomSignal, PhantomSignal>(state.activeSignals, func(sig) {
      let newMag = sig.decayedMagnitude * SIGNAL_DECAY_RATE;
      { sig with decayedMagnitude = newMag }
    });

    // Filter expired (below minimum confidence threshold)
    let alive = Array.filter<PhantomSignal>(decayed, func(sig) {
      sig.decayedMagnitude >= MIN_SIGNAL_CONFIDENCE * Phi.PHI_INV_3
    });

    let expired = decayed.size() - alive.size();

    // Compute composite direction (magnitude-weighted average)
    var totalMag : Float = 0.0;
    var weightedDir : Float = 0.0;
    for (sig in alive.vals()) {
      totalMag += sig.decayedMagnitude;
      weightedDir += sig.direction * sig.decayedMagnitude;
    };
    let compositeDir = if (totalMag > 0.0) { weightedDir / totalMag } else { 0.0 };

    let newCoherence = state.signalCoherence * 0.9 + kuramotoR * 0.1;

    {
      state with
      activeSignals       = alive;
      compositeDirection  = compositeDir;
      signalCoherence     = newCoherence;
      lastTickBeat        = beat;
      signalsExpired      = state.signalsExpired + expired;
    }
  };
}
