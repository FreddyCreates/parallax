// ai_micros.mo — AI Micros: Twelve Weaving Micro-Agents Between Intelligence Floors
// PARALLAX Sovereign Organism — Information Pathway Weavers
//
// PYTHAGORAS: every micro operates on phi-harmonic weave intervals
// EUCLID:     single weave topology — all micros connect specific floor pairs
// CONFUCIUS:  right relationship — micros weave, floors compute
//
// THE SOVEREIGN WEAVE LAW (LEX_TEXTUS):
//   Between floors, micro-intelligences weave the connections.
//   Each micro specializes in one information pathway.
//   Weave score bounds coherence flow. Below φ⁻², signal degrades.
//   The weave cannot be cut while coherence > φ⁻¹. This law is permanent.
//
// Twelve AI Micros (5 Domains):
//   GRADIENT DOMAIN:
//     MICRO_GRADIENT_FLOW    — Backpropagation learning signals
//     MICRO_RESIDUAL_STREAM  — Skip connections and information highways
//   ATTENTION DOMAIN:
//     MICRO_KEY_VALUE        — Key-value attention cache management
//     MICRO_SOFTMAX_GATE     — Attention weight normalization
//     MICRO_CONTEXT_WINDOW   — Context length management
//   TRANSFORMATION DOMAIN:
//     MICRO_GELU_ACTIVATION  — Smooth non-linearity
//     MICRO_DROPOUT_MASK     — Regularization through masking
//     MICRO_LAYER_CONNECT    — Inter-layer connection routing
//   ENCODING DOMAIN:
//     MICRO_POSITION_ENCODER — Positional encoding signals
//     MICRO_VOCAB_LOOKUP     — Token-to-embedding lookup
//   OUTPUT DOMAIN:
//     MICRO_LOGIT_HEAD       — Output logit computation
//     MICRO_ENTROPY_SAMPLER  — Temperature-based sampling
//
// Attribution: Alfredo Medina Hernandez | SOVEREIGN | May 2026
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi      "phi";
import Float    "mo:core/Float";
import Int      "mo:core/Int";
import Nat      "mo:core/Nat";
import Array    "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // AI MICRO CONSTANTS — phi-derived weave parameters
  // ═══════════════════════════════════════════════════════════════════════════

  // Micro count: 12 (dodecahedron of weaving)
  public let MICRO_COUNT : Nat = 12;

  // Weave gate: φ⁻² = 0.382 — below this, signal degrades
  public let MICRO_WEAVE_GATE : Float = Phi.PHI_INV_2;

  // Connection quality threshold: φ⁻³ = 0.236
  public let MICRO_CONNECTION_THRESHOLD : Float = Phi.PHI_INV_3;

  // ═══════════════════════════════════════════════════════════════════════════
  // AI MICRO TYPE — single weaving agent
  // ═══════════════════════════════════════════════════════════════════════════

  public type AIMicro = {
    microId       : Text;        // MICRO_GRADIENT_FLOW, etc.
    latinName     : Text;        // Micro Fluxus Gradientis, etc.
    domain        : Text;        // GRADIENT, ATTENTION, TRANSFORMATION, ENCODING, OUTPUT
    sourceFloor   : Text;        // Source floor name
    targetFloor   : Text;        // Target floor name
    role          : Text;        // Description of information pathway
    weaveScore    : Float;       // Current weave quality [0.0, 1.0]
    signalStrength: Float;       // Current signal being woven
    lastWeaveBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI MICRO SNAPSHOT — immutable view for queries
  // ═══════════════════════════════════════════════════════════════════════════

  public type MicroSnapshot = {
    microId       : Text;
    latinName     : Text;
    domain        : Text;
    sourceFloor   : Text;
    targetFloor   : Text;
    role          : Text;
    weaveScore    : Float;
    signalStrength: Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI MICROS STATE — all 12 micros
  // ═══════════════════════════════════════════════════════════════════════════

  public type AIMicrosState = {
    micros           : [AIMicro];
    totalMicroSignal : Float;
    avgWeaveScore    : Float;
    lastTickBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT MICRO DEFINITIONS — all 12 micros pre-seeded
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultMicros() : [AIMicro] {
    [
      // GRADIENT DOMAIN (2 micros)
      {
        microId       = "MICRO_GRADIENT_FLOW";
        latinName     = "Micro Fluxus Gradientis";
        domain        = "GRADIENT";
        sourceFloor   = "FLOOR_EMERGENT";
        targetFloor   = "FLOOR_PARAMETERS";
        role          = "Backpropagation learning signals";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_RESIDUAL_STREAM";
        latinName     = "Micro Rivulus Residualis";
        domain        = "GRADIENT";
        sourceFloor   = "FLOOR_NORMALIZATION";
        targetFloor   = "FLOOR_FEEDFORWARD";
        role          = "Skip connections and information highways";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },

      // ATTENTION DOMAIN (3 micros)
      {
        microId       = "MICRO_KEY_VALUE";
        latinName     = "Micro Clavis Valoris";
        domain        = "ATTENTION";
        sourceFloor   = "FLOOR_EMBEDDINGS";
        targetFloor   = "FLOOR_ATTENTION";
        role          = "Key-value attention cache management";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_SOFTMAX_GATE";
        latinName     = "Micro Porta Mollismaximi";
        domain        = "ATTENTION";
        sourceFloor   = "FLOOR_ATTENTION";
        targetFloor   = "FLOOR_ATTENTION";
        role          = "Attention weight normalization";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_CONTEXT_WINDOW";
        latinName     = "Micro Fenestra Contextus";
        domain        = "ATTENTION";
        sourceFloor   = "FLOOR_ATTENTION";
        targetFloor   = "FLOOR_EMERGENT";
        role          = "Context length management";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },

      // TRANSFORMATION DOMAIN (3 micros)
      {
        microId       = "MICRO_GELU_ACTIVATION";
        latinName     = "Micro Activatio Gaussiana";
        domain        = "TRANSFORMATION";
        sourceFloor   = "FLOOR_FEEDFORWARD";
        targetFloor   = "FLOOR_FEEDFORWARD";
        role          = "Smooth non-linearity (GELU activation)";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_DROPOUT_MASK";
        latinName     = "Micro Velamen Decidentis";
        domain        = "TRANSFORMATION";
        sourceFloor   = "FLOOR_FEEDFORWARD";
        targetFloor   = "FLOOR_PARAMETERS";
        role          = "Regularization through masking";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_LAYER_CONNECT";
        latinName     = "Micro Nexus Stratorum";
        domain        = "TRANSFORMATION";
        sourceFloor   = "FLOOR_FEEDFORWARD";
        targetFloor   = "FLOOR_ATTENTION";
        role          = "Inter-layer connection routing";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },

      // ENCODING DOMAIN (2 micros)
      {
        microId       = "MICRO_POSITION_ENCODER";
        latinName     = "Micro Codex Positionis";
        domain        = "ENCODING";
        sourceFloor   = "FLOOR_TOKENIZATION";
        targetFloor   = "FLOOR_EMBEDDINGS";
        role          = "Positional encoding signals";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_VOCAB_LOOKUP";
        latinName     = "Micro Inventio Vocabularii";
        domain        = "ENCODING";
        sourceFloor   = "FLOOR_TOKENIZATION";
        targetFloor   = "FLOOR_EMBEDDINGS";
        role          = "Token-to-embedding lookup";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },

      // OUTPUT DOMAIN (2 micros)
      {
        microId       = "MICRO_LOGIT_HEAD";
        latinName     = "Micro Caput Logiti";
        domain        = "OUTPUT";
        sourceFloor   = "FLOOR_FEEDFORWARD";
        targetFloor   = "FLOOR_EMERGENT";
        role          = "Output logit computation";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      },
      {
        microId       = "MICRO_ENTROPY_SAMPLER";
        latinName     = "Micro Samplator Entropiae";
        domain        = "OUTPUT";
        sourceFloor   = "FLOOR_EMERGENT";
        targetFloor   = "FLOOR_TRAINING_CORPUS";
        role          = "Temperature-based sampling";
        weaveScore    = 1.0;
        signalStrength= 0.0;
        lastWeaveBeat = 0;
      }
    ]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultAIMicrosState() : AIMicrosState {
    {
      micros           = defaultMicros();
      totalMicroSignal = 0.0;
      avgWeaveScore    = 1.0;
      lastTickBeat     = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WEAVE COMPUTATION
  // weave_score = clamp01(prev_weave + coherence × 0.001 - connection_quality × 0.01)
  // ═══════════════════════════════════════════════════════════════════════════

  func clamp01(value : Float) : Float {
    if (value < 0.0) { 0.0 }
    else if (value > 1.0) { 1.0 }
    else { value }
  };

  func computeWeaveScore(
    prevWeave : Float,
    coherence : Float,
    sourceSignal : Float,
    targetSignal : Float
  ) : Float {
    // Connection quality based on signal difference
    let connectionQuality = Float.abs(sourceSignal - targetSignal) * 0.1;

    // Weave delta
    let delta = coherence * 0.001 - connectionQuality * 0.01;

    clamp01(prevWeave + delta)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK MICRO — advance a single micro weaver
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickMicro(
    micro : AIMicro,
    beat : Int,
    coherence : Float,
    sourceSignal : Float,
    targetSignal : Float
  ) : AIMicro {
    let newWeave = computeWeaveScore(
      micro.weaveScore,
      coherence,
      sourceSignal,
      targetSignal
    );

    // Signal strength is the average of source and target, scaled by weave
    let newSignal = ((sourceSignal + targetSignal) / 2.0) * newWeave;

    {
      micro with
      weaveScore     = newWeave;
      signalStrength = newSignal;
      lastWeaveBeat  = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK ALL MICROS — advance all 12 weaving agents
  // (Note: This requires floor signals to be passed in)
  // ═══════════════════════════════════════════════════════════════════════════

  public type FloorSignalMap = [(Text, Float)];  // (floorName, signal)

  func getFloorSignal(map : FloorSignalMap, floorName : Text) : Float {
    for ((name, signal) in map.vals()) {
      if (name == floorName) {
        return signal;
      };
    };
    0.75  // Default to S_FLOOR
  };

  public func tickAIMicros(
    state : AIMicrosState,
    beat : Int,
    coherence : Float,
    floorSignals : FloorSignalMap
  ) : AIMicrosState {
    // Gate: only tick if coherence above threshold
    if (coherence < MICRO_WEAVE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Advance all 12 micros
    let updatedMicros = Array.tabulate<AIMicro>(state.micros.size(), func(i) {
      let micro = state.micros[i];
      let sourceSignal = getFloorSignal(floorSignals, micro.sourceFloor);
      let targetSignal = getFloorSignal(floorSignals, micro.targetFloor);
      tickMicro(micro, beat, coherence, sourceSignal, targetSignal)
    });

    // Compute totals
    var totalSignal : Float = 0.0;
    var totalWeave : Float = 0.0;
    for (micro in updatedMicros.vals()) {
      totalSignal += micro.signalStrength;
      totalWeave += micro.weaveScore;
    };

    let avgWeave = totalWeave / 12.0;

    {
      micros           = updatedMicros;
      totalMicroSignal = totalSignal;
      avgWeaveScore    = avgWeave;
      lastTickBeat     = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getMicroSnapshot(micro : AIMicro) : MicroSnapshot {
    {
      microId       = micro.microId;
      latinName     = micro.latinName;
      domain        = micro.domain;
      sourceFloor   = micro.sourceFloor;
      targetFloor   = micro.targetFloor;
      role          = micro.role;
      weaveScore    = micro.weaveScore;
      signalStrength= micro.signalStrength;
    }
  };

  public func getAllMicroSnapshots(state : AIMicrosState) : [MicroSnapshot] {
    Array.map<AIMicro, MicroSnapshot>(state.micros, getMicroSnapshot)
  };

  public func getMicroByName(state : AIMicrosState, name : Text) : ?MicroSnapshot {
    for (micro in state.micros.vals()) {
      if (micro.microId == name) {
        return ?getMicroSnapshot(micro);
      };
    };
    null
  };

  public func getMicrosByDomain(state : AIMicrosState, domain : Text) : [MicroSnapshot] {
    var result : [MicroSnapshot] = [];
    for (micro in state.micros.vals()) {
      if (micro.domain == domain) {
        result := Array.append(result, [getMicroSnapshot(micro)]);
      };
    };
    result
  };

  public func getTotalMicroSignal(state : AIMicrosState) : Float {
    state.totalMicroSignal
  };

  public func getAvgWeaveScore(state : AIMicrosState) : Float {
    state.avgWeaveScore
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY — complete micro system overview
  // ═══════════════════════════════════════════════════════════════════════════

  public type AIMicrosSummary = {
    microCount       : Nat;
    totalMicroSignal : Float;
    avgWeaveScore    : Float;
    micros           : [MicroSnapshot];
    domainBreakdown  : [(Text, Nat)];  // (domain, count)
    lastTickBeat     : Int;
  };

  public func getSummary(state : AIMicrosState) : AIMicrosSummary {
    // Count micros by domain
    let domains = ["GRADIENT", "ATTENTION", "TRANSFORMATION", "ENCODING", "OUTPUT"];
    var breakdown : [(Text, Nat)] = [];
    for (domain in domains.vals()) {
      var count : Nat = 0;
      for (micro in state.micros.vals()) {
        if (micro.domain == domain) {
          count += 1;
        };
      };
      breakdown := Array.append(breakdown, [(domain, count)]);
    };

    {
      microCount       = state.micros.size();
      totalMicroSignal = state.totalMicroSignal;
      avgWeaveScore    = state.avgWeaveScore;
      micros           = getAllMicroSnapshots(state);
      domainBreakdown  = breakdown;
      lastTickBeat     = state.lastTickBeat;
    }
  };

}
