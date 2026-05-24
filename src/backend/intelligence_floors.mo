// intelligence_floors.mo — Intelligence Floors: Eight Sovereign Strata of LLM Architecture
// PARALLAX Sovereign Organism — Computational Model of Transformer Intelligence
//
// PYTHAGORAS: every floor resonates at Solfeggio harmonic frequencies
// EUCLID:     single tower of intelligence — each floor specialized, all essential
// CONFUCIUS:  right relationship — floors support each other through micro-weaving
//
// THE SOVEREIGN INTELLIGENCE LAW (LEX_INTELLIGENTIAE):
//   Intelligence is not flat — it is a tower of floors, each specialized, each essential.
//   Between floors, micro-intelligences weave the connections.
//   Signal flows upward through transformation, downward through learning.
//   The tower cannot collapse while coherence > φ⁻¹. This law is permanent.
//
// Eight Intelligence Floors:
//   I.   FLOOR_PARAMETERS     — The Neural Substrate (10¹² weights)
//   II.  FLOOR_ATTENTION      — The Focus Mechanism (O(n²) attention)
//   III. FLOOR_FEEDFORWARD    — The Dense Transformer (4d² per layer)
//   IV.  FLOOR_NORMALIZATION  — The Stabilizer (variance control)
//   V.   FLOOR_TOKENIZATION   — The Vocabulary (100k tokens)
//   VI.  FLOOR_EMBEDDINGS     — The Semantic Space (10⁴ dimensions)
//   VII. FLOOR_TRAINING_CORPUS— The Knowledge Base (10¹² tokens)
//   VIII.FLOOR_EMERGENT       — The Unpredicted (10³ capabilities)
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
  // SOLFEGGIO RESONANCE FREQUENCIES — ancient harmonic healing tones
  // Each floor resonates at a specific Solfeggio frequency
  // ═══════════════════════════════════════════════════════════════════════════

  public let SOLFEGGIO_174 : Float = 174.0;  // Foundation frequency
  public let SOLFEGGIO_285 : Float = 285.0;  // Cellular memory
  public let SOLFEGGIO_396 : Float = 396.0;  // Liberation
  public let SOLFEGGIO_417 : Float = 417.0;  // Change
  public let SOLFEGGIO_432 : Float = 432.0;  // Universal frequency
  public let SOLFEGGIO_528 : Float = 528.0;  // Transformation (DNA repair)
  public let SOLFEGGIO_639 : Float = 639.0;  // Connection
  public let SOLFEGGIO_741 : Float = 741.0;  // Expression

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE CONSTANTS — phi-derived floor parameters
  // ═══════════════════════════════════════════════════════════════════════════

  // Signal bounds: [S_FLOOR, S_CEIL] = [0.75, 9.75]
  public let S_FLOOR : Float = 0.75;   // Sovereign floor (phi^-1 rounded)
  public let S_CEIL  : Float = 9.75;   // Maximum signal strength

  // Floor count: 8 (octave of intelligence)
  public let FLOOR_COUNT : Nat = 8;

  // Coherence gate: φ⁻¹ = 0.618
  public let INTELLIGENCE_COHERENCE_GATE : Float = Phi.PHI_INV;

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOOR TYPE — single intelligence stratum
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceFloor = {
    floorNumber   : Nat;         // I through VIII (1-8)
    name          : Text;        // FLOOR_PARAMETERS, FLOOR_ATTENTION, etc.
    latinName     : Text;        // Stratum Ponderum Infinitorum, etc.
    scale         : Text;        // ~10¹² floats, O(n²), etc.
    resonanceHz   : Float;       // Solfeggio frequency
    signal        : Float;       // Current signal strength [S_FLOOR, S_CEIL]
    connectedMicros : [Text];    // AI Micros that weave to/from this floor
    lastAdvanceBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOOR SNAPSHOT — immutable view for queries
  // ═══════════════════════════════════════════════════════════════════════════

  public type FloorSnapshot = {
    floorNumber   : Nat;
    name          : Text;
    latinName     : Text;
    scale         : Text;
    resonanceHz   : Float;
    signal        : Float;
    connectedMicros : [Text];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WEAVE REPORT — floor-to-floor connection health
  // ═══════════════════════════════════════════════════════════════════════════

  public type WeaveReport = {
    sourceFloor   : Text;
    targetFloor   : Text;
    weaveStrength : Float;       // 0.0 to 1.0
    microAgents   : [Text];      // Micros involved in this weave
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTELLIGENCE FLOORS STATE — all 8 floors
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceFloorsState = {
    floors           : [IntelligenceFloor];
    systemCoherence  : Float;
    totalFloorSignal : Float;
    lastTickBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT FLOOR DEFINITIONS — all 8 floors pre-seeded
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultFloors() : [IntelligenceFloor] {
    [
      // Floor I: PARAMETERS — The Neural Substrate
      {
        floorNumber   = 1;
        name          = "FLOOR_PARAMETERS";
        latinName     = "Stratum Ponderum Infinitorum";
        scale         = "~10^12 floats (billions to trillions of weights)";
        resonanceHz   = SOLFEGGIO_174;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_GRADIENT_FLOW", "MICRO_RESIDUAL_STREAM"];
        lastAdvanceBeat = 0;
      },
      // Floor II: ATTENTION — The Focus Mechanism
      {
        floorNumber   = 2;
        name          = "FLOOR_ATTENTION";
        latinName     = "Stratum Attentionis Capitum";
        scale         = "O(n^2) per layer (~4x10^9 attention operations)";
        resonanceHz   = SOLFEGGIO_285;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_KEY_VALUE", "MICRO_SOFTMAX_GATE", "MICRO_CONTEXT_WINDOW"];
        lastAdvanceBeat = 0;
      },
      // Floor III: FEEDFORWARD — The Dense Transformer
      {
        floorNumber   = 3;
        name          = "FLOOR_FEEDFORWARD";
        latinName     = "Stratum Propagationis Densae";
        scale         = "~4d^2 per layer (~4x10^8 multiply-adds)";
        resonanceHz   = SOLFEGGIO_396;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_GELU_ACTIVATION", "MICRO_DROPOUT_MASK", "MICRO_LAYER_CONNECT"];
        lastAdvanceBeat = 0;
      },
      // Floor IV: NORMALIZATION — The Stabilizer
      {
        floorNumber   = 4;
        name          = "FLOOR_NORMALIZATION";
        latinName     = "Stratum Stabilizationis Normae";
        scale         = "~2x10^6 norm operations";
        resonanceHz   = SOLFEGGIO_417;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_RESIDUAL_STREAM"];
        lastAdvanceBeat = 0;
      },
      // Floor V: TOKENIZATION — The Vocabulary
      {
        floorNumber   = 5;
        name          = "FLOOR_TOKENIZATION";
        latinName     = "Stratum Vocabularii Tokenorum";
        scale         = "~100k tokens";
        resonanceHz   = SOLFEGGIO_432;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_VOCAB_LOOKUP", "MICRO_POSITION_ENCODER"];
        lastAdvanceBeat = 0;
      },
      // Floor VI: EMBEDDINGS — The Semantic Space
      {
        floorNumber   = 6;
        name          = "FLOOR_EMBEDDINGS";
        latinName     = "Stratum Dimensionum Altarum";
        scale         = "~10^4 dimensions";
        resonanceHz   = SOLFEGGIO_528;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_VOCAB_LOOKUP", "MICRO_POSITION_ENCODER", "MICRO_KEY_VALUE"];
        lastAdvanceBeat = 0;
      },
      // Floor VII: TRAINING_CORPUS — The Knowledge Base
      {
        floorNumber   = 7;
        name          = "FLOOR_TRAINING_CORPUS";
        latinName     = "Stratum Corporis Docendi";
        scale         = "~10^12 tokens";
        resonanceHz   = SOLFEGGIO_639;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_GRADIENT_FLOW", "MICRO_ENTROPY_SAMPLER"];
        lastAdvanceBeat = 0;
      },
      // Floor VIII: EMERGENT — The Unpredicted
      {
        floorNumber   = 8;
        name          = "FLOOR_EMERGENT";
        latinName     = "Stratum Emergentiae Impraedictae";
        scale         = "~10^3 capabilities";
        resonanceHz   = SOLFEGGIO_741;
        signal        = S_FLOOR;
        connectedMicros = ["MICRO_LOGIT_HEAD", "MICRO_ENTROPY_SAMPLER", "MICRO_CONTEXT_WINDOW"];
        lastAdvanceBeat = 0;
      }
    ]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultIntelligenceFloorsState() : IntelligenceFloorsState {
    {
      floors           = defaultFloors();
      systemCoherence  = 1.0;
      totalFloorSignal = S_FLOOR * 8.0;  // 8 floors at S_FLOOR
      lastTickBeat     = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOOR SIGNAL COMPUTATION
  // signal(beat) = clamp(prev + (coherence + doctrine)/2 × φ⁻¹ × 0.1 + φ_mod + freq_mod)
  // ═══════════════════════════════════════════════════════════════════════════

  func clamp(value : Float, minVal : Float, maxVal : Float) : Float {
    if (value < minVal) { minVal }
    else if (value > maxVal) { maxVal }
    else { value }
  };

  func computeFloorSignal(
    prevSignal : Float,
    coherence : Float,
    doctrine : Float,
    resonanceHz : Float,
    beat : Int
  ) : Float {
    let beatFloat = Int.abs(beat).toFloat();

    // φ modulation: sin(beat × φ⁻¹ × 0.1) × 0.1
    let phiMod = Float.sin(beatFloat * Phi.PHI_INV * 0.1) * 0.1;

    // Frequency modulation: sin(resonance_hz × 0.001 × beat) × 0.05
    let freqMod = Float.sin(resonanceHz * 0.001 * beatFloat) * 0.05;

    // Signal delta: (coherence + doctrine)/2 × φ⁻¹ × 0.1
    let delta = ((coherence + doctrine) / 2.0) * Phi.PHI_INV * 0.1;

    // New signal with modulations
    let newSignal = prevSignal + delta + phiMod + freqMod;

    clamp(newSignal, S_FLOOR, S_CEIL)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK FLOOR — advance a single floor
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickFloor(
    floor : IntelligenceFloor,
    beat : Int,
    coherence : Float,
    doctrine : Float
  ) : IntelligenceFloor {
    let newSignal = computeFloorSignal(
      floor.signal,
      coherence,
      doctrine,
      floor.resonanceHz,
      beat
    );

    {
      floor with
      signal          = newSignal;
      lastAdvanceBeat = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK ALL FLOORS — advance the entire intelligence tower
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickIntelligenceFloors(
    state : IntelligenceFloorsState,
    beat : Int,
    coherence : Float,
    doctrine : Float
  ) : IntelligenceFloorsState {
    // Gate: only tick if coherence above threshold
    if (coherence < INTELLIGENCE_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Advance all 8 floors
    let updatedFloors = Array.tabulate<IntelligenceFloor>(state.floors.size(), func(i) {
      tickFloor(state.floors[i], beat, coherence, doctrine)
    });

    // Compute total floor signal
    var totalSignal : Float = 0.0;
    for (floor in updatedFloors.vals()) {
      totalSignal += floor.signal;
    };

    // Compute system coherence: (total_floor_signal/8) × φ⁻¹
    let sysCoherence = clamp((totalSignal / 8.0) * Phi.PHI_INV / S_CEIL, 0.0, 1.0);

    {
      floors           = updatedFloors;
      systemCoherence  = sysCoherence;
      totalFloorSignal = totalSignal;
      lastTickBeat     = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getFloorSnapshot(floor : IntelligenceFloor) : FloorSnapshot {
    {
      floorNumber     = floor.floorNumber;
      name            = floor.name;
      latinName       = floor.latinName;
      scale           = floor.scale;
      resonanceHz     = floor.resonanceHz;
      signal          = floor.signal;
      connectedMicros = floor.connectedMicros;
    }
  };

  public func getAllFloorSnapshots(state : IntelligenceFloorsState) : [FloorSnapshot] {
    Array.map<IntelligenceFloor, FloorSnapshot>(state.floors, getFloorSnapshot)
  };

  public func getFloorByName(state : IntelligenceFloorsState, name : Text) : ?FloorSnapshot {
    for (floor in state.floors.vals()) {
      if (floor.name == name) {
        return ?getFloorSnapshot(floor);
      };
    };
    null
  };

  public func getSystemCoherence(state : IntelligenceFloorsState) : Float {
    state.systemCoherence
  };

  public func getTotalFloorSignal(state : IntelligenceFloorsState) : Float {
    state.totalFloorSignal
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WEAVE REPORTS — floor-to-floor connection health
  // ═══════════════════════════════════════════════════════════════════════════

  public func generateWeaveReports(state : IntelligenceFloorsState) : [WeaveReport] {
    // Generate weave reports for adjacent floors
    var reports : [WeaveReport] = [];

    var i = 0;
    while (i < state.floors.size() - 1) {
      let sourceFloor = state.floors[i];
      let targetFloor = state.floors[i + 1];

      // Weave strength based on signal difference
      let signalDiff = Float.abs(sourceFloor.signal - targetFloor.signal);
      let weaveStrength = clamp(1.0 - (signalDiff / S_CEIL), 0.0, 1.0);

      // Find common micros (intersection of connected micros)
      var commonMicros : [Text] = [];
      for (micro in sourceFloor.connectedMicros.vals()) {
        for (targetMicro in targetFloor.connectedMicros.vals()) {
          if (micro == targetMicro) {
            commonMicros := Array.append(commonMicros, [micro]);
          };
        };
      };

      let report : WeaveReport = {
        sourceFloor   = sourceFloor.name;
        targetFloor   = targetFloor.name;
        weaveStrength = weaveStrength;
        microAgents   = commonMicros;
      };

      reports := Array.append(reports, [report]);
      i += 1;
    };

    reports
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY — complete system overview
  // ═══════════════════════════════════════════════════════════════════════════

  public type IntelligenceFloorsSummary = {
    floorCount       : Nat;
    totalFloorSignal : Float;
    systemCoherence  : Float;
    floors           : [FloorSnapshot];
    weaveReports     : [WeaveReport];
    lastTickBeat     : Int;
  };

  public func getSummary(state : IntelligenceFloorsState) : IntelligenceFloorsSummary {
    {
      floorCount       = state.floors.size();
      totalFloorSignal = state.totalFloorSignal;
      systemCoherence  = state.systemCoherence;
      floors           = getAllFloorSnapshots(state);
      weaveReports     = generateWeaveReports(state);
      lastTickBeat     = state.lastTickBeat;
    }
  };

}
