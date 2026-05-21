import Array "mo:base/Array";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

actor AXIS {

  // ─── Constants ────────────────────────────────────────────────────────────
  let S0     : Float = 1.0;
  let ALPHA21  : Float = 2.0 / 22.0;   // EMA-21
  let ALPHA55  : Float = 2.0 / 56.0;   // EMA-55
  let ALPHA200 : Float = 2.0 / 201.0;  // EMA-200
  let ALPHA500 : Float = 2.0 / 501.0;  // EMA-500

  // ─── Stable State ─────────────────────────────────────────────────────────
  stable var creatorPrincipal : Text  = "";
  stable var genesisSealed    : Bool  = false;
  stable var qmemCanisterId   : Text  = "";
  stable var beatCount        : Nat   = 0;

  // Eagle: multi-scale EMA over coherence
  stable var eagle_ema21      : Float = S0;
  stable var eagle_ema55      : Float = S0;
  stable var eagle_ema200     : Float = S0;
  stable var eagle_ema500     : Float = S0;
  stable var eagle_prev21     : Float = S0;
  stable var eagle_prev55     : Float = S0;
  stable var eagle_acceleration : Float = 0.0;
  stable var eagle_curvature    : Float = 0.0;
  stable var eagle_elevationIdx : Float = S0;

  // Elephant: cosine recall state
  stable var elephant_recallScore     : Float = S0;
  stable var elephant_matriarchDist   : Float = 0.0;
  stable var elephant_episodeAge      : Nat   = 0;
  stable var elephant_bestCoherence   : Float = S0;

  // Altitude map (EAGLE-EMA history for frontend)
  stable var eagle_history : [var Float] = Array.init<Float>(200, S0); // last 200 elevation readings
  stable var eagle_histHead : Nat = 0;

  // Elephant episode memory (local cache of best recalled episode)
  stable var elephant_bestEpisode : [Float] = Array.freeze(Array.init<Float>(41, S0));

  // ─── Auth ─────────────────────────────────────────────────────────────────
  func assertCreator(caller: Principal) {
    if (creatorPrincipal != "") {
      assert (Principal.toText(caller) == creatorPrincipal);
    };
  };

  public shared(msg) func sealGenesis() : async () {
    assert (not genesisSealed);
    creatorPrincipal := Principal.toText(msg.caller);
    genesisSealed    := true;
  };

  public shared(msg) func setQmemCanister(id: Text) : async () {
    assertCreator(msg.caller);
    qmemCanisterId := id;
  };

  // ─── Math ─────────────────────────────────────────────────────────────────
  func clamp(x: Float, lo: Float, hi: Float) : Float {
    if (x < lo) lo else if (x > hi) hi else x;
  };

  func cosineSim(a: [Float], b: [Float]) : Float {
    var dot = 0.0;
    var na  = 0.0;
    var nb  = 0.0;
    let n = Nat.min(a.size(), b.size());
    var i = 0;
    while (i < n) {
      dot += a[i] * b[i];
      na  += a[i] * a[i];
      nb  += b[i] * b[i];
      i   += 1;
    };
    clamp(dot / (Float.sqrt(na) * Float.sqrt(nb) + 1e-9), -1.0, 1.0);
  };

  // ─── Eagle Engine ─────────────────────────────────────────────────────────
  // Multi-scale EMA + acceleration + curvature over coherence signal
  func runEagle(coherence: Float) {
    let c = Float.max(S0, coherence);

    eagle_prev21 := eagle_ema21;
    eagle_prev55 := eagle_ema55;

    eagle_ema21  := ALPHA21  * c + (1.0 - ALPHA21)  * eagle_ema21;
    eagle_ema55  := ALPHA55  * c + (1.0 - ALPHA55)  * eagle_ema55;
    eagle_ema200 := ALPHA200 * c + (1.0 - ALPHA200) * eagle_ema200;
    eagle_ema500 := ALPHA500 * c + (1.0 - ALPHA500) * eagle_ema500;

    // Acceleration: rate of change of EMA21 relative to EMA55
    eagle_acceleration := eagle_ema21 - eagle_ema55;

    // Curvature: second derivative proxy — EMA21 - 2*EMA55 + EMA200
    eagle_curvature := eagle_ema21 - 2.0 * eagle_ema55 + eagle_ema200;

    // Elevation index: normalized composite of all 4 scales
    eagle_elevationIdx := clamp(
      (eagle_ema21 * 0.4 + eagle_ema55 * 0.3 + eagle_ema200 * 0.2 + eagle_ema500 * 0.1)
      * (1.0 + eagle_acceleration * 0.5),
      S0, 10.0
    );

    // Store in history ring
    eagle_history[eagle_histHead] := eagle_elevationIdx;
    eagle_histHead := (eagle_histHead + 1) % 200;
  };

  // ─── Elephant Engine ──────────────────────────────────────────────────────
  // Cosine similarity against best known episode from QMEM
  func runElephant(stateVec: [Float], matriarchEp: [Float]) {
    let sim = cosineSim(stateVec, matriarchEp);
    elephant_recallScore   := Float.max(S0, sim * 2.0); // scaled to sovereign floor
    elephant_matriarchDist := 1.0 - sim;
    elephant_episodeAge    += 1;

    let c = if (stateVec.size() > 0) stateVec[0] else S0;
    if (c > elephant_bestCoherence) {
      elephant_bestCoherence := c;
      elephant_bestEpisode   := stateVec;
      elephant_episodeAge    := 0;
    };
  };

  // ─── Main Tick ────────────────────────────────────────────────────────────
  // Called by backend every beat with current state vector
  public shared(msg) func tick(stateVec: [Float]) : async {
    elephantRecallScore   : Float;
    elephantMatriarchDist : Float;
    eagleElevationIdx     : Float;
    eagleAcceleration     : Float;
    eagleCurvature        : Float;
    eagleEma21            : Float;
    eagleEma55            : Float;
  } {
    beatCount += 1;
    let coherence = if (stateVec.size() > 0) stateVec[0] else S0;

    // Run Eagle locally (no QMEM call needed)
    runEagle(coherence);

    // Run Elephant — use local best episode as fallback, query QMEM periodically
    let matriarchEp : [Float] = if (qmemCanisterId != "" and beatCount % 10 == 0) {
      // Inter-canister call to QMEM for matriarch episode
      let qmem = actor(qmemCanisterId) : actor {
        getMatriarchEpisode : () -> async [Float];
      };
      let ep = await qmem.getMatriarchEpisode();
      if (ep.size() > 0) {
        elephant_bestEpisode := ep;
      };
      elephant_bestEpisode;
    } else {
      elephant_bestEpisode;
    };

    runElephant(stateVec, matriarchEp);

    {
      elephantRecallScore   = elephant_recallScore;
      elephantMatriarchDist = elephant_matriarchDist;
      eagleElevationIdx     = eagle_elevationIdx;
      eagleAcceleration     = eagle_acceleration;
      eagleCurvature        = eagle_curvature;
      eagleEma21            = eagle_ema21;
      eagleEma55            = eagle_ema55;
    };
  };

  // ─── Queries ──────────────────────────────────────────────────────────────
  public query func getAltitudeMap() : async {
    ema21        : Float;
    ema55        : Float;
    ema200       : Float;
    ema500       : Float;
    acceleration : Float;
    curvature    : Float;
    elevationIdx : Float;
  } {
    {
      ema21        = eagle_ema21;
      ema55        = eagle_ema55;
      ema200       = eagle_ema200;
      ema500       = eagle_ema500;
      acceleration = eagle_acceleration;
      curvature    = eagle_curvature;
      elevationIdx = eagle_elevationIdx;
    };
  };

  public query func getElephantState() : async {
    recallScore     : Float;
    matriarchDist   : Float;
    episodeAge      : Nat;
    bestCoherence   : Float;
  } {
    {
      recallScore   = elephant_recallScore;
      matriarchDist = elephant_matriarchDist;
      episodeAge    = elephant_episodeAge;
      bestCoherence = elephant_bestCoherence;
    };
  };

  public query func getAltitudeHistory() : async [Float] {
    Array.freeze(eagle_history);
  };

  public query func getAxisState() : async {
    beatCount           : Nat;
    eagleElevationIdx   : Float;
    eagleAcceleration   : Float;
    eagleCurvature      : Float;
    eagleEma21          : Float;
    eagleEma55          : Float;
    eagleEma200         : Float;
    eagleEma500         : Float;
    elephantRecallScore : Float;
    elephantBestCoher   : Float;
    elephantEpisodeAge  : Nat;
  } {
    {
      beatCount           = beatCount;
      eagleElevationIdx   = eagle_elevationIdx;
      eagleAcceleration   = eagle_acceleration;
      eagleCurvature      = eagle_curvature;
      eagleEma21          = eagle_ema21;
      eagleEma55          = eagle_ema55;
      eagleEma200         = eagle_ema200;
      eagleEma500         = eagle_ema500;
      elephantRecallScore = elephant_recallScore;
      elephantBestCoher   = elephant_bestCoherence;
      elephantEpisodeAge  = elephant_episodeAge;
    };
  };
};
