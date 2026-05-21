// =============================================================================
// CHRONO — PARALLAX Temporal Root
// TIER 1: Immutable genesis anchor, beat counter, temporal dilation
// Every stateful value is a stable var. Cannot be meaningfully upgraded after
// genesis seal because the genesis hash would change.
// =============================================================================

import Time    "mo:base/Time";
import Float   "mo:base/Float";
import Nat     "mo:base/Nat";
import Nat8    "mo:base/Nat8";
import Nat32   "mo:base/Nat32";
import Nat64   "mo:base/Nat64";
import Int     "mo:base/Int";
import Text    "mo:base/Text";
import Blob    "mo:base/Blob";
import Array   "mo:base/Array";
import Principal "mo:base/Principal";
import Iter    "mo:base/Iter";
import Debug   "mo:base/Debug";

actor Chrono {

  // ===========================================================================
  // GLOBAL CONSTANTS
  // ===========================================================================

  let S0              : Float = 1.0;
  let HEARTBEAT_NS    : Nat   = 2_000_000_000;   // 2 seconds in nanoseconds
  let BEATS_PER_DAY   : Float = 43200.0;          // 86400s / 2s per beat
  let LOG_WARMUP      : Float = 10000.0;          // dilation log denominator
  let GENESIS_LABEL   : Text  = "PARALLAX_GENESIS";
  let MAX_DRIFT_LOG   : Nat   = 1000;             // ring buffer for drift history

  // ===========================================================================
  // STABLE STATE
  // ===========================================================================

  stable var beatCount            : Nat   = 0;
  stable var genesisTime          : Int   = 0;
  stable var genesisSealed        : Bool  = false;
  stable var genesisHash          : Text  = "";
  stable var creatorPrincipal     : Text  = "";
  stable var organismAge          : Float = 0.0;
  stable var temporalDilation     : Float = 1.0;  // sovereign floor S0
  stable var integrityCalls       : Nat   = 0;
  stable var lastBeatTime         : Int   = 0;
  stable var beatDrift            : Float = 0.0;
  stable var totalIntegrityPasses : Nat   = 0;
  stable var totalIntegrityFails  : Nat   = 0;
  stable var upgradeCount         : Nat   = 0;
  stable var lastUpgradeTime      : Int   = 0;
  stable var genesisBlock         : Nat   = 0;
  stable var totalBeats           : Nat   = 0;    // alias kept for external callers
  stable var lastDilationUpdate   : Int   = 0;
  stable var peakDrift            : Float = 0.0;
  stable var driftLogHead         : Nat   = 0;
  stable var driftLog             : [var Float] = Array.init<Float>(MAX_DRIFT_LOG, 0.0);
  stable var cumulativeDrift      : Float = 0.0;
  stable var beatsSinceGenesis    : Nat   = 0;
  stable var lastVerifierPrincipal : Text = "";

  // ===========================================================================
  // SHA-256 IMPLEMENTATION — Pure Motoko, no external crypto dependency
  // Implements FIPS PUB 180-4 SHA-256 on byte arrays, returns 64-char hex.
  // ===========================================================================

  // Round constants: first 32 bits of fractional parts of cube roots of first 64 primes
  let SHA256_K : [Nat32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];

  // Initial hash values: first 32 bits of fractional parts of sqrt of first 8 primes
  let SHA256_H0 : [Nat32] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ];

  // Rotate right 32-bit
  func rotr32(x : Nat32, n : Nat32) : Nat32 {
    (x >> n) | (x << (32 - n))
  };

  // Bitwise NOT for Nat32 (Motoko has no native ~ for Nat32)
  func bnot32(x : Nat32) : Nat32 {
    x ^ 0xFFFFFFFF
  };

  // SHA-256 logical functions
  func sha_ch(x : Nat32, y : Nat32, z : Nat32) : Nat32 {
    (x & y) ^ (bnot32(x) & z)
  };

  func sha_maj(x : Nat32, y : Nat32, z : Nat32) : Nat32 {
    (x & y) ^ (x & z) ^ (y & z)
  };

  func sha_sigma0(x : Nat32) : Nat32 {
    rotr32(x, 2) ^ rotr32(x, 13) ^ rotr32(x, 22)
  };

  func sha_sigma1(x : Nat32) : Nat32 {
    rotr32(x, 6) ^ rotr32(x, 11) ^ rotr32(x, 25)
  };

  func sha_gamma0(x : Nat32) : Nat32 {
    rotr32(x, 7) ^ rotr32(x, 18) ^ (x >> 3)
  };

  func sha_gamma1(x : Nat32) : Nat32 {
    rotr32(x, 17) ^ rotr32(x, 19) ^ (x >> 10)
  };

  // Read 4 bytes big-endian as Nat32
  func readNat32BE(buf : [var Nat8], offset : Nat) : Nat32 {
    (Nat32.fromNat(Nat8.toNat(buf[offset]))     << 24) |
    (Nat32.fromNat(Nat8.toNat(buf[offset + 1])) << 16) |
    (Nat32.fromNat(Nat8.toNat(buf[offset + 2])) <<  8) |
     Nat32.fromNat(Nat8.toNat(buf[offset + 3]))
  };

  // Write Nat32 big-endian into mutable byte buffer at offset
  func writeNat32BE(buf : [var Nat8], offset : Nat, v : Nat32) {
    buf[offset]     := Nat8.fromNat(Nat32.toNat(v >> 24) % 256);
    buf[offset + 1] := Nat8.fromNat(Nat32.toNat(v >> 16) % 256);
    buf[offset + 2] := Nat8.fromNat(Nat32.toNat(v >>  8) % 256);
    buf[offset + 3] := Nat8.fromNat(Nat32.toNat(v)       % 256);
  };

  // Hex encoding helpers
  let HEX_CHARS : [Char] = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];

  func byteToHex(b : Nat8) : Text {
    let n = Nat8.toNat(b);
    Text.fromChar(HEX_CHARS[n / 16]) # Text.fromChar(HEX_CHARS[n % 16])
  };

  // Core SHA-256: hash a byte array, return 64-char lowercase hex
  func sha256Bytes(data : [Nat8]) : Text {
    let msgLen   = data.size();
    let bitLen64 : Nat64 = Nat64.fromNat(msgLen) * 8;

    // Compute padded length: msg + 0x80 + zero-pad until len ≡ 56 (mod 64) + 8 bytes
    var padLen = msgLen + 1;
    while (padLen % 64 != 56) { padLen += 1; };
    padLen += 8;

    // Build padded buffer
    let buf = Array.init<Nat8>(padLen, 0);
    var i = 0;
    while (i < msgLen) { buf[i] := data[i]; i += 1; };
    buf[msgLen] := 0x80;

    // Append 64-bit big-endian bit length
    let lo = padLen - 8;
    buf[lo]     := Nat8.fromNat(Nat64.toNat(bitLen64 >> 56) % 256);
    buf[lo + 1] := Nat8.fromNat(Nat64.toNat(bitLen64 >> 48) % 256);
    buf[lo + 2] := Nat8.fromNat(Nat64.toNat(bitLen64 >> 40) % 256);
    buf[lo + 3] := Nat8.fromNat(Nat64.toNat(bitLen64 >> 32) % 256);
    buf[lo + 4] := Nat8.fromNat(Nat64.toNat(bitLen64 >> 24) % 256);
    buf[lo + 5] := Nat8.fromNat(Nat64.toNat(bitLen64 >> 16) % 256);
    buf[lo + 6] := Nat8.fromNat(Nat64.toNat(bitLen64 >>  8) % 256);
    buf[lo + 7] := Nat8.fromNat(Nat64.toNat(bitLen64)       % 256);

    // Working hash state
    let h = Array.init<Nat32>(8, 0);
    var j = 0;
    while (j < 8) { h[j] := SHA256_H0[j]; j += 1; };

    // Process 512-bit blocks
    let numBlocks = padLen / 64;
    var blk = 0;
    while (blk < numBlocks) {
      let off = blk * 64;
      let w   = Array.init<Nat32>(64, 0);

      // Load message schedule words 0..15
      var t = 0;
      while (t < 16) {
        w[t] := readNat32BE(buf, off + t * 4);
        t += 1;
      };
      // Expand message schedule words 16..63
      while (t < 64) {
        w[t] := sha_gamma1(w[t-2]) +% w[t-7] +% sha_gamma0(w[t-15]) +% w[t-16];
        t += 1;
      };

      // Initialize compression variables
      var a = h[0]; var b = h[1]; var c = h[2]; var d = h[3];
      var e = h[4]; var f = h[5]; var g = h[6]; var hh = h[7];

      // 64 compression rounds
      t := 0;
      while (t < 64) {
        let T1 = hh +% sha_sigma1(e) +% sha_ch(e,f,g)  +% SHA256_K[t] +% w[t];
        let T2 =      sha_sigma0(a)  +% sha_maj(a,b,c);
        hh := g;  g := f;  f := e;  e := d +% T1;
        d  := c;  c := b;  b := a;  a := T1 +% T2;
        t += 1;
      };

      // Add back into hash state
      h[0] := h[0] +% a;  h[1] := h[1] +% b;
      h[2] := h[2] +% c;  h[3] := h[3] +% d;
      h[4] := h[4] +% e;  h[5] := h[5] +% f;
      h[6] := h[6] +% g;  h[7] := h[7] +% hh;
      blk += 1;
    };

    // Serialize 8 x Nat32 → 32 bytes → 64 hex chars
    let out = Array.init<Nat8>(32, 0);
    j := 0;
    while (j < 8) { writeNat32BE(out, j * 4, h[j]); j += 1; };

    var hex = "";
    for (byte in Iter.fromArray(Array.freeze(out))) {
      hex #= byteToHex(byte);
    };
    hex
  };

  // Encode a Text as UTF-8 bytes and hash
  func sha256Text(t : Text) : Text {
    sha256Bytes(Blob.toArray(Text.encodeUtf8(t)))
  };

  // ===========================================================================
  // MATH HELPERS
  // ===========================================================================

  // Float max (Motoko has no Float.max in older SDK)
  func fmax(a : Float, b : Float) : Float { if (a > b) a else b };
  func fmin(a : Float, b : Float) : Float { if (a < b) a else b };
  func fabs(a : Float) : Float            { if (a < 0.0) -a else a };

  // Natural log approximation via Padé-like Householder iteration.
  // Uses the identity: ln(x) = 2 * arctanh((x-1)/(x+1))
  // arctanh(z) = z + z^3/3 + z^5/5 + ... converges for |z| < 1
  // Good to ~7 decimal places for x in (0.1, 10)
  func lnApprox(x : Float) : Float {
    if (x <= 0.0) return 0.0;
    if (x == 1.0) return 0.0;
    // Reduce: bring x into range [0.5, 1.5] by multiplying by powers of 2
    var val   = x;
    var shift : Float = 0.0;
    let ln2   : Float = 0.6931471805599453;
    while (val > 1.5) { val := val / 2.0; shift += ln2; };
    while (val < 0.5) { val := val * 2.0; shift -= ln2; };
    // Now val in [0.5, 1.5], compute ln(val) via series
    let z  = (val - 1.0) / (val + 1.0);
    let z2 = z * z;
    var term = z;
    var sum  = z;
    var n    : Float = 3.0;
    var i    = 0;
    while (i < 24) {
      term := term * z2;
      sum  += term / n;
      n    += 2.0;
      i    += 1;
    };
    shift + 2.0 * sum
  };

  // tanh approximation: x / (1 + |x|)  — used in shell activation (BRAIN uses this)
  func tanhApprox(x : Float) : Float {
    x / (1.0 + fabs(x))
  };

  // sin approximation via 9-term Taylor series around 0
  // Folds input into [-pi, pi] first
  func sinApprox(x : Float) : Float {
    let pi  : Float = 3.141592653589793;
    let pi2 : Float = 6.283185307179586;
    // Reduce to [-pi, pi]
    var v = x;
    while (v >  pi) { v -= pi2; };
    while (v < -pi) { v += pi2; };
    // Taylor: x - x^3/6 + x^5/120 - x^7/5040 + x^9/362880
    let v2 = v * v;
    v - (v*v2)/6.0 + (v*v2*v2)/120.0 - (v*v2*v2*v2)/5040.0 + (v*v2*v2*v2*v2)/362880.0
  };

  // cos approximation via sin
  func cosApprox(x : Float) : Float {
    sinApprox(x + 1.5707963267948966)
  };

  // ===========================================================================
  // TEMPORAL DILATION
  // Dilation: τ = max(S0, 1.0 + ln(1 + beat / LOG_WARMUP))
  // Grows logarithmically. At beat 10000 = 1.69, beat 100000 = 2.40, etc.
  // Effect: all decay rates divided by τ (organism ages slower proportionally)
  // ===========================================================================

  func computeTemporalDilation(beat : Nat) : Float {
    let beatF = Float.fromInt(beat);
    fmax(S0, 1.0 + lnApprox(1.0 + beatF / LOG_WARMUP))
  };

  // Organism age in days: each beat = 2 seconds
  func computeOrganismAge(beat : Nat) : Float {
    Float.fromInt(beat) * 2.0 / 86400.0
  };

  // ===========================================================================
  // GENESIS HASH COMPUTATION
  // Input: creatorText || Int.toText(genesisTime) || GENESIS_LABEL
  // ===========================================================================

  func computeGenesisHash(creator : Text, t : Int) : Text {
    let preimage = creator # Int.toText(t) # GENESIS_LABEL;
    sha256Text(preimage)
  };

  // ===========================================================================
  // PRINCIPAL / AUTHORIZATION
  // Before genesis seal, all callers are allowed (bootstrap mode).
  // After seal, only creatorPrincipal may call write functions.
  // ===========================================================================

  func isCreator(caller : Principal) : Bool {
    if (creatorPrincipal == "") return true;  // bootstrap
    Principal.toText(caller) == creatorPrincipal
  };

  func assertCreator(caller : Principal) {
    assert(isCreator(caller))
  };

  // ===========================================================================
  // DRIFT TRACKING HELPERS
  // ===========================================================================

  func recordDrift(d : Float) {
    driftLog[driftLogHead % MAX_DRIFT_LOG] := d;
    driftLogHead += 1;
    cumulativeDrift += d;
    if (d > peakDrift) { peakDrift := d; };
  };

  func averageDrift() : Float {
    let count = Nat.min(driftLogHead, MAX_DRIFT_LOG);
    if (count == 0) return 0.0;
    cumulativeDrift / Float.fromInt(count)
  };

  // ===========================================================================
  // PUBLIC FUNCTIONS
  // ===========================================================================

  // -------------------------------------------------------------------------
  // sealGenesis — callable exactly once, by anyone (typically the deployer)
  // Records the creator principal, computes the immutable genesis hash.
  // After this call the hash is set and verified every beat.
  // -------------------------------------------------------------------------
  public shared(msg) func sealGenesis(creator : Principal) : async Text {
    assert(not genesisSealed);
    let now            = Time.now();
    creatorPrincipal  := Principal.toText(creator);
    genesisTime       := now;
    lastBeatTime      := now;
    genesisHash       := computeGenesisHash(creatorPrincipal, genesisTime);
    genesisSealed     := true;
    genesisBlock      := beatCount;
    beatsSinceGenesis := 0;
    genesisHash
  };

  // -------------------------------------------------------------------------
  // tick — called every heartbeat by BRAIN
  // Increments beat counter, updates age and dilation, tracks drift.
  // -------------------------------------------------------------------------
  public shared func tick() : async Nat {
    let now = Time.now();

    // Compute real-time drift against expected 2-second cadence
    if (lastBeatTime > 0) {
      let elapsed    : Int  = now - lastBeatTime;
      let expected   : Int  = HEARTBEAT_NS;
      let diff       : Int  = if (elapsed > expected) elapsed - expected else expected - elapsed;
      let driftRatio : Float = Float.fromInt(diff) / Float.fromInt(expected);
      beatDrift    := driftRatio;
      recordDrift(driftRatio);
    };

    lastBeatTime      := now;
    beatCount         += 1;
    totalBeats        := beatCount;
    beatsSinceGenesis += 1;
    lastDilationUpdate := now;

    // Update derived temporal values
    organismAge      := computeOrganismAge(beatCount);
    temporalDilation := computeTemporalDilation(beatCount);

    beatCount
  };

  // -------------------------------------------------------------------------
  // verifyIntegrity — called by AEGIS every beat
  // Recomputes genesis hash and compares to stored value.
  // Any mismatch indicates tampering and returns false.
  // -------------------------------------------------------------------------
  public shared(msg) func verifyIntegrity() : async Bool {
    integrityCalls += 1;
    lastVerifierPrincipal := Principal.toText(msg.caller);

    // Pre-genesis: nothing to verify
    if (not genesisSealed) {
      totalIntegrityPasses += 1;
      return true;
    };

    let recomputed = computeGenesisHash(creatorPrincipal, genesisTime);
    let valid      = recomputed == genesisHash;

    if (valid) { totalIntegrityPasses += 1; }
    else       { totalIntegrityFails  += 1; };

    valid
  };

  // -------------------------------------------------------------------------
  // getState — public query, safe to expose
  // -------------------------------------------------------------------------
  public query func getState() : async {
    beat        : Nat;
    age         : Float;
    dilation    : Float;
    sealed      : Bool;
  } {{
    beat     = beatCount;
    age      = organismAge;
    dilation = temporalDilation;
    sealed   = genesisSealed;
  }};

  // -------------------------------------------------------------------------
  // Individual field queries — called by other canisters
  // -------------------------------------------------------------------------
  public query func getBeatCount()        : async Nat   { beatCount        };
  public query func getOrganismAge()      : async Float { organismAge      };
  public query func getTemporalDilation() : async Float { temporalDilation };
  public query func isSealed()            : async Bool  { genesisSealed    };
  public query func getGenesisHash()      : async Text  { genesisHash      };
  public query func getGenesisTime()      : async Int   { genesisTime      };
  public query func getBeatDrift()        : async Float { beatDrift        };
  public query func getPeakDrift()        : async Float { peakDrift        };
  public query func getAverageDrift()     : async Float { averageDrift()   };
  public query func getBeatsSinceGenesis(): async Nat   { beatsSinceGenesis };

  // -------------------------------------------------------------------------
  // getIntegrityStats — called by AEGIS for law L-2 monitoring
  // -------------------------------------------------------------------------
  public query func getIntegrityStats() : async {
    calls  : Nat;
    passes : Nat;
    fails  : Nat;
  } {{
    calls  = integrityCalls;
    passes = totalIntegrityPasses;
    fails  = totalIntegrityFails;
  }};

  // -------------------------------------------------------------------------
  // getFullState — creator-only deep diagnostic
  // -------------------------------------------------------------------------
  public shared(msg) func getFullState() : async {
    beatCount            : Nat;
    genesisTime          : Int;
    genesisSealed        : Bool;
    genesisHash          : Text;
    creatorPrincipal     : Text;
    organismAge          : Float;
    temporalDilation     : Float;
    integrityCalls       : Nat;
    lastBeatTime         : Int;
    beatDrift            : Float;
    peakDrift            : Float;
    averageDrift         : Float;
    totalIntegrityPasses : Nat;
    totalIntegrityFails  : Nat;
    upgradeCount         : Nat;
    lastUpgradeTime      : Int;
    genesisBlock         : Nat;
    beatsSinceGenesis    : Nat;
    lastVerifierPrincipal : Text;
  } {
    assertCreator(msg.caller);
    {
      beatCount            = beatCount;
      genesisTime          = genesisTime;
      genesisSealed        = genesisSealed;
      genesisHash          = genesisHash;
      creatorPrincipal     = creatorPrincipal;
      organismAge          = organismAge;
      temporalDilation     = temporalDilation;
      integrityCalls       = integrityCalls;
      lastBeatTime         = lastBeatTime;
      beatDrift            = beatDrift;
      peakDrift            = peakDrift;
      averageDrift         = averageDrift();
      totalIntegrityPasses = totalIntegrityPasses;
      totalIntegrityFails  = totalIntegrityFails;
      upgradeCount         = upgradeCount;
      lastUpgradeTime      = lastUpgradeTime;
      genesisBlock         = genesisBlock;
      beatsSinceGenesis    = beatsSinceGenesis;
      lastVerifierPrincipal = lastVerifierPrincipal;
    }
  };

  // -------------------------------------------------------------------------
  // hashText — utility for testing the SHA-256 impl, creator only
  // -------------------------------------------------------------------------
  public shared(msg) func hashText(input : Text) : async Text {
    assertCreator(msg.caller);
    sha256Text(input)
  };

  // -------------------------------------------------------------------------
  // hashBytes — hash raw bytes, creator only
  // -------------------------------------------------------------------------
  public shared(msg) func hashBlob(data : Blob) : async Text {
    assertCreator(msg.caller);
    sha256Bytes(Blob.toArray(data))
  };

  // -------------------------------------------------------------------------
  // recomputeTemporalValues — force recalculation after upgrade
  // -------------------------------------------------------------------------
  public shared(msg) func recomputeTemporalValues() : async () {
    assertCreator(msg.caller);
    organismAge      := computeOrganismAge(beatCount);
    temporalDilation := computeTemporalDilation(beatCount);
  };

  // -------------------------------------------------------------------------
  // verifyHashConsistency — returns the expected hash so callers can cross-check
  // -------------------------------------------------------------------------
  public shared(msg) func verifyHashConsistency() : async {
    stored   : Text;
    computed : Text;
    match    : Bool;
  } {
    assertCreator(msg.caller);
    let computed = computeGenesisHash(creatorPrincipal, genesisTime);
    {
      stored   = genesisHash;
      computed = computed;
      match    = computed == genesisHash;
    }
  };

  // -------------------------------------------------------------------------
  // computeProjectedAge — given a future beat count, what will the age be?
  // Used by NOVA to project child organism lifespans
  // -------------------------------------------------------------------------
  public query func computeProjectedAge(futureBeat : Nat) : async Float {
    computeOrganismAge(futureBeat)
  };

  // -------------------------------------------------------------------------
  // computeProjectedDilation — temporal dilation at any future beat
  // -------------------------------------------------------------------------
  public query func computeProjectedDilation(futureBeat : Nat) : async Float {
    computeTemporalDilation(futureBeat)
  };

  // -------------------------------------------------------------------------
  // getDriftWindow — return last N drift values from ring buffer
  // -------------------------------------------------------------------------
  public shared(msg) func getDriftWindow(n : Nat) : async [Float] {
    assertCreator(msg.caller);
    let count  = Nat.min(n, Nat.min(driftLogHead, MAX_DRIFT_LOG));
    let result = Array.init<Float>(count, 0.0);
    var i = 0;
    while (i < count) {
      let idx = (driftLogHead + MAX_DRIFT_LOG - count + i) % MAX_DRIFT_LOG;
      result[i] := driftLog[idx];
      i += 1;
    };
    Array.freeze(result)
  };

  // ===========================================================================
  // SYSTEM LIFECYCLE HOOKS
  // ===========================================================================

  system func preupgrade() {
    upgradeCount   += 1;
    lastUpgradeTime := Time.now();
  };

  system func postupgrade() {
    // Recompute derived temporal values so they are consistent after upgrade
    if (beatCount > 0) {
      organismAge      := computeOrganismAge(beatCount);
      temporalDilation := computeTemporalDilation(beatCount);
    };
  };

};
