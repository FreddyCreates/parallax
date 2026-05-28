// phantom_consensus.mo — PHANTOM CONSENSUS MESH
// PARALLAX Sovereign Organism — Multi-Model Agreement & Decision Framework
//
// DOCTRINE: "No single model trades alone. The Phantom Consensus Mesh requires
// agreement across multiple independent AI models before any action fires.
// This is the organism's deliberative cortex — where divergent opinions converge
// into unified, high-confidence decisions through Kuramoto-style phase-locking."
//
// PHANTOM CONSENSUS ARCHITECTURE:
//   PCM-001  VOTE AGGREGATOR          — Collects model votes with confidence weights
//   PCM-002  DISAGREEMENT DETECTOR    — Identifies model divergence (entropy)
//   PCM-003  CONVICTION SCORER        — Measures agreement strength (Kuramoto R)
//   PCM-004  QUORUM ENGINE            — Enforces minimum agreement thresholds
//   PCM-005  DISSENT ANALYZER         — Learns from minority opinions
//   PCM-006  CONSENSUS HISTORY        — Tracks accuracy of past consensus decisions
//   PCM-007  ADAPTIVE WEIGHTING       — Adjusts model weights based on performance
//
// PYTHAGORAS: quorum thresholds at phi-harmonic levels
// EUCLID:     single consensus state — all agreement tracking centralized
// CONFUCIUS:  right relationship — models advise, consensus decides
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  public let CONSENSUS_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let QUORUM_THRESHOLD : Float = Phi.PHI_INV;   // 61.8% must agree
  public let SUPER_QUORUM : Float = Phi.PHI_INV + Phi.PHI_INV_3;  // 85.4%
  public let MIN_VOTERS : Nat = 5;  // Fibonacci-5 minimum models
  public let CONVICTION_DECAY : Float = Phi.PHI_INV;

  public type VoteDirection = {
    #strongBuy;
    #buy;
    #neutral;
    #sell;
    #strongSell;
  };

  public type ModelVote = {
    modelId          : Text;
    direction        : VoteDirection;
    confidence       : Float;       // [0, 1]
    reasoning        : Text;        // Brief explanation
    weight           : Float;       // Performance-adjusted weight
    castBeat         : Int;
  };

  public type ConsensusDecision = {
    decisionId       : Nat;
    asset            : Text;
    votes            : [ModelVote];
    outcome          : VoteDirection;
    conviction       : Float;       // Kuramoto R across voters
    quorumMet        : Bool;
    superQuorumMet   : Bool;
    dissentCount     : Nat;
    decidedBeat      : Int;
    wasCorrect       : ?Bool;       // Filled in retrospectively
  };

  public type PhantomConsensusState = {
    recentDecisions   : [ConsensusDecision];
    totalDecisions    : Nat;
    avgConviction     : Float;
    quorumRate        : Float;      // % of decisions that reached quorum
    accuracy          : Float;      // % of decisions that were correct
    modelWeights      : [(Text, Float)];  // Model ID → performance weight
    consensusCoherence: Float;
    lastTickBeat      : Int;
    dissentLearnings  : Nat;        // Times minority was right
  };

  public func defaultPhantomConsensusState() : PhantomConsensusState {
    {
      recentDecisions    = [];
      totalDecisions     = 0;
      avgConviction      = 0.0;
      quorumRate         = 0.0;
      accuracy           = 0.0;
      modelWeights       = [];
      consensusCoherence = Phi.S0;
      lastTickBeat       = 0;
      dissentLearnings   = 0;
    }
  };

  public func tickPhantomConsensus(state : PhantomConsensusState, beat : Int, kuramotoR : Float) : PhantomConsensusState {
    if (kuramotoR < CONSENSUS_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Decay conviction on old decisions
    let decayed = Array.map<ConsensusDecision, ConsensusDecision>(state.recentDecisions, func(d) {
      let age = beat - d.decidedBeat;
      if (age > 1000) {
        { d with conviction = d.conviction * CONVICTION_DECAY }
      } else { d }
    });

    // Keep only recent decisions (last Fibonacci-89 decisions)
    let recent = if (decayed.size() > 89) {
      Array.tabulate<ConsensusDecision>(89, func(i) { decayed[decayed.size() - 89 + i] })
    } else { decayed };

    let newCoherence = state.consensusCoherence * 0.9 + kuramotoR * 0.1;

    {
      state with
      recentDecisions    = recent;
      consensusCoherence = newCoherence;
      lastTickBeat       = beat;
    }
  };
}
