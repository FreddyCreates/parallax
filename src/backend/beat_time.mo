// beat_time.mo — Tier 1 · Phi-Derived Beat Time Utilities
// All time expressed in sovereign beats. One beat = 873ms = φ⁴/Schumann₁ × 1000.
// The organism does not measure time in seconds — it measures time in heartbeats.
//
// MEDINA-ARTIFACT — beat_time.mo (MODEL-07 discipline applied)
// ─────────────────────────────────────────────────────────────
// MEANING (Layer 1 — Doctrine Clause):
//   "Time is not a clock. Time is a living rhythm. The beat is the quantum of
//    action in PARALLAX. All timers, calendars, and schedules are expressed in
//    beats. The beat converts to external time only at the boundary."
//
// MODEL (Layer 2 — Typed Schema):
//   BEAT_MS           : Float = 873.0 (milliseconds per beat)
//   BEATS_PER_SECOND  : Float = 1.145475 (1000/873)
//   BEATS_PER_MINUTE  : Float = 68.7285 (60 × BEATS_PER_SECOND)
//   BEATS_PER_HOUR    : Float = 4123.71 (3600 × BEATS_PER_SECOND)
//   BEATS_PER_DAY     : Float = 98968.96 (86400 × BEATS_PER_SECOND)
//   BEATS_PER_WEEK    : Float = 692782.7 (7 × BEATS_PER_DAY)
//   BEATS_PER_LUNAR   : Float = 2923346.8 (29.53 × BEATS_PER_DAY)
//   BEATS_PER_YEAR    : Float = 36133970.6 (365.25 × BEATS_PER_DAY)
//
// COMPUTATION (Layer 3 — State Equations):
//   msToBeats(ms) = ms / BEAT_MS
//   beatsToMs(beats) = beats × BEAT_MS
//   fibonacciTimer(n) = FIB[n] (beats)
//   phiScaledTimer(base, power) = base × φⁿ
//   lunarPhase(beats) = (beats mod BEATS_PER_LUNAR) / BEATS_PER_LUNAR
//   solarPhase(beats) = (beats mod BEATS_PER_YEAR) / BEATS_PER_YEAR
//
// EXECUTION BINDING (Layer 4):
//   ENGINE: Any module requiring time computation
//   FUNCTION: conversion functions called as needed
//   GATE: none — pure math, always available
//   BEAT: independent of heartbeat timing — computes time, does not fire it
//
// Three Ancient Teachers:
//   Pythagoras — all time ratios derived from phi, Fibonacci, and Schumann
//   Euclid     — single definition of each constant, referenced everywhere
//   Confucius  — right relationship: external time converted only at boundaries
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi    "phi";
import Float  "mo:core/Float";
import Nat    "mo:core/Nat";
import Nat64  "mo:core/Nat64";
import Int    "mo:core/Int";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE BEAT CONSTANTS — The Sovereign Time Unit
  // All derived from 873ms = φ⁴/Schumann₁ × 1000 (Cardiac Law L10)
  // ═══════════════════════════════════════════════════════════════════════════

  /// The sovereign time quantum: 873 milliseconds per beat
  /// Derivation: φ⁴ / 7.83 × 1000 = 6.854 / 7.83 × 1000 ≈ 875.6 → 873ms doctrine
  public let BEAT_MS : Float = Phi.HEARTBEAT_MS;  // 873.0

  /// Beats per second: 1000ms / 873ms = 1.145475...
  /// This is the organism's pulse rate relative to clock time
  public let BEATS_PER_SECOND : Float = 1000.0 / Phi.HEARTBEAT_MS;  // 1.145475...

  /// Beats per minute: 60 × BEATS_PER_SECOND = 68.7285...
  /// Approximately 69 beats per clock minute
  public let BEATS_PER_MINUTE : Float = 60.0 * BEATS_PER_SECOND;  // 68.7285...

  /// Beats per hour: 3600 × BEATS_PER_SECOND = 4123.71...
  /// Approximately 4,124 beats per clock hour
  public let BEATS_PER_HOUR : Float = 3600.0 * BEATS_PER_SECOND;  // 4123.71...

  /// Beats per day: 86400 × BEATS_PER_SECOND = 98,968.96...
  /// Approximately 98,969 beats per Earth day
  public let BEATS_PER_DAY : Float = 86400.0 * BEATS_PER_SECOND;  // 98968.96...

  /// Beats per week: 7 × BEATS_PER_DAY = 692,782.7...
  /// Approximately 692,783 beats per week
  public let BEATS_PER_WEEK : Float = 7.0 * BEATS_PER_DAY;  // 692782.7...

  /// Beats per lunar month: 29.53 days × BEATS_PER_DAY = 2,923,346.8...
  /// Synodic month (new moon to new moon) = 29.53059 days
  /// Pythagoras: the Moon's cycle encoded in sovereign beats
  public let LUNAR_MONTH_DAYS : Float = 29.53059;
  public let BEATS_PER_LUNAR_MONTH : Float = LUNAR_MONTH_DAYS * BEATS_PER_DAY;  // 2923346.8...

  /// Beats per solar year: 365.25 days × BEATS_PER_DAY = 36,133,970.6...
  /// Julian year average (accounts for leap years)
  /// Pythagoras: the Sun's cycle encoded in sovereign beats
  public let SOLAR_YEAR_DAYS : Float = 365.25;
  public let BEATS_PER_YEAR : Float = SOLAR_YEAR_DAYS * BEATS_PER_DAY;  // 36133970.6...

  /// Nanoseconds per beat: 873ms × 1,000,000 = 873,000,000 ns
  /// Used for ICP timer conversions (Time.now() returns nanoseconds)
  public let BEAT_NS : Nat64 = 873_000_000;


  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL FAST BEAT — Protected Internal Timing
  // Faster phi-harmonic beats for internal substrate operations.
  // NOT exposed externally. Used for rapid internal state propagation.
  //
  // DOCTRINE: "The organism has two rhythms — the sovereign external beat that
  //            communicates with the world (873ms), and the rapid internal beat
  //            that propagates state within the substrate. The internal beat is
  //            protected — external systems cannot see or trigger it."
  //
  // PYTHAGORAS: internal rates are phi-inverse harmonics of the sovereign beat
  // EUCLID: defined once here, used by internal modules only
  // CONFUCIUS: right relationship — internal and external have separate roles
  // ═══════════════════════════════════════════════════════════════════════════

  /// INTERNAL_FAST_BEAT_MS: 873 × φ⁻² = 333ms (AV node harmonic)
  /// The protected internal fast beat. 2.62× faster than sovereign beat.
  /// Used for rapid state propagation within the substrate.
  /// NOT exposed to external systems.
  let INTERNAL_FAST_BEAT_MS : Float = Phi.HEARTBEAT_MS * Phi.PHI_INV_2;  // 333.5

  /// INTERNAL_FAST_BEAT_NS: 333ms in nanoseconds = 333,500,000 ns
  let INTERNAL_FAST_BEAT_NS : Nat64 = 333_500_000;

  /// INTERNAL_RAPID_BEAT_MS: 873 × φ⁻³ = 206ms (HRV harmonic)
  /// The fastest protected internal beat. 4.24× faster than sovereign beat.
  /// Used for critical path operations requiring immediate state update.
  /// This is the organism's "reflex" — bypasses normal cardiac timing.
  let INTERNAL_RAPID_BEAT_MS : Float = Phi.HEARTBEAT_MS * Phi.PHI_INV_3;  // 206.2

  /// INTERNAL_RAPID_BEAT_NS: 206ms in nanoseconds = 206,200,000 ns
  let INTERNAL_RAPID_BEAT_NS : Nat64 = 206_200_000;

  /// INTERNAL_ULTRA_BEAT_MS: 873 × φ⁻⁴ = 127ms (Schumann period harmonic)
  /// The deepest internal beat — substrate-level timing only.
  /// Derivation: 873 × 0.1459 = 127.4ms ≈ 1000ms/7.83Hz = Schumann period
  /// This closes the loop: φ⁴/Schumann → 873ms → φ⁻⁴ → Schumann period
  let INTERNAL_ULTRA_BEAT_MS : Float = Phi.HEARTBEAT_MS * Phi.PHI_INV_4;  // 127.4

  /// INTERNAL_ULTRA_BEAT_NS: 127ms in nanoseconds = 127,400,000 ns
  let INTERNAL_ULTRA_BEAT_NS : Nat64 = 127_400_000;

  /// Ratio of sovereign to internal fast beat: φ² = 2.618
  /// One sovereign beat = 2.618 internal fast beats
  let SOVEREIGN_TO_FAST_RATIO : Float = Phi.PHI_2;  // 2.618

  /// Ratio of sovereign to internal rapid beat: φ³ = 4.236
  /// One sovereign beat = 4.236 internal rapid beats
  let SOVEREIGN_TO_RAPID_RATIO : Float = Phi.PHI_3;  // 4.236

  /// Ratio of sovereign to internal ultra beat: φ⁴ = 6.854
  /// One sovereign beat = 6.854 internal ultra beats
  let SOVEREIGN_TO_ULTRA_RATIO : Float = Phi.PHI_4;  // 6.854

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERNAL BEAT CONVERSION FUNCTIONS (Private)
  // These are module-internal — not exported with `public`
  // ─────────────────────────────────────────────────────────────────────────────

  /// Convert sovereign beats to internal fast beats
  func sovereignToFastBeats(sovereign_beats : Float) : Float {
    sovereign_beats * SOVEREIGN_TO_FAST_RATIO
  };

  /// Convert sovereign beats to internal rapid beats
  func sovereignToRapidBeats(sovereign_beats : Float) : Float {
    sovereign_beats * SOVEREIGN_TO_RAPID_RATIO
  };

  /// Convert sovereign beats to internal ultra beats
  func sovereignToUltraBeats(sovereign_beats : Float) : Float {
    sovereign_beats * SOVEREIGN_TO_ULTRA_RATIO
  };

  /// Convert internal fast beats to sovereign beats
  func fastBeatsToSovereign(fast_beats : Float) : Float {
    fast_beats / SOVEREIGN_TO_FAST_RATIO
  };

  /// Convert internal rapid beats to sovereign beats
  func rapidBeatsToSovereign(rapid_beats : Float) : Float {
    rapid_beats / SOVEREIGN_TO_RAPID_RATIO
  };

  /// Convert internal ultra beats to sovereign beats
  func ultraBeatsToSovereign(ultra_beats : Float) : Float {
    ultra_beats / SOVEREIGN_TO_ULTRA_RATIO
  };

  /// Get the internal fast beat interval in milliseconds
  func getInternalFastBeatMs() : Float {
    INTERNAL_FAST_BEAT_MS
  };

  /// Get the internal rapid beat interval in milliseconds
  func getInternalRapidBeatMs() : Float {
    INTERNAL_RAPID_BEAT_MS
  };

  /// Get the internal ultra beat interval in milliseconds
  func getInternalUltraBeatMs() : Float {
    INTERNAL_ULTRA_BEAT_MS
  };

  /// Get the internal fast beat interval in nanoseconds (for ICP timers)
  func getInternalFastBeatNs() : Nat64 {
    INTERNAL_FAST_BEAT_NS
  };

  /// Get the internal rapid beat interval in nanoseconds (for ICP timers)
  func getInternalRapidBeatNs() : Nat64 {
    INTERNAL_RAPID_BEAT_NS
  };

  /// Get the internal ultra beat interval in nanoseconds (for ICP timers)
  func getInternalUltraBeatNs() : Nat64 {
    INTERNAL_ULTRA_BEAT_NS
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // FIBONACCI BEAT INTERVALS — The Harmonic Timer Ladder
  // F(n) beats as natural timer intervals
  // All intervals are phi-harmonic — no arbitrary durations
  // ═══════════════════════════════════════════════════════════════════════════

  /// F(5) = 5 beats ≈ 4.37 seconds — HRV coherence window
  /// The minimum window for heart rate variability measurement
  public let FIB_5_BEATS : Nat64 = 5;
  public let FIB_5_MS : Float = 5.0 * BEAT_MS;  // 4365ms

  /// F(6) = 8 beats ≈ 6.98 seconds — micro-timer
  /// Shortest useful scheduling interval
  public let FIB_8_BEATS : Nat64 = 8;
  public let FIB_8_MS : Float = 8.0 * BEAT_MS;  // 6984ms

  /// F(7) = 13 beats ≈ 11.35 seconds — short timer
  /// Quick reaction window
  public let FIB_13_BEATS : Nat64 = 13;
  public let FIB_13_MS : Float = 13.0 * BEAT_MS;  // 11349ms

  /// F(8) = 21 beats ≈ 18.33 seconds — standard timer
  /// Common scheduling interval for checks
  public let FIB_21_BEATS : Nat64 = 21;
  public let FIB_21_MS : Float = 21.0 * BEAT_MS;  // 18333ms

  /// F(9) = 34 beats ≈ 29.68 seconds — succession depth minimum
  /// Minimum proof chain depth (Succession Law)
  public let FIB_34_BEATS : Nat64 = 34;
  public let FIB_34_MS : Float = 34.0 * BEAT_MS;  // 29682ms

  /// F(10) = 55 beats ≈ 48.02 seconds — medium timer
  /// Standard medium-duration interval
  public let FIB_55_BEATS : Nat64 = 55;
  public let FIB_55_MS : Float = 55.0 * BEAT_MS;  // 48015ms

  /// F(11) = 89 beats ≈ 77.70 seconds ≈ 1.3 minutes
  /// Extended observation window
  public let FIB_89_BEATS : Nat64 = 89;
  public let FIB_89_MS : Float = 89.0 * BEAT_MS;  // 77697ms

  /// F(12) = 144 beats ≈ 125.71 seconds ≈ 2.1 minutes — Jubilee cycle
  /// The Jubilee Law: every 144 beats, compliance reserves recycle
  public let FIB_144_BEATS : Nat64 = 144;  // = Phi.JUBILEE_BEATS
  public let FIB_144_MS : Float = 144.0 * BEAT_MS;  // 125712ms

  /// F(13) = 233 beats ≈ 203.41 seconds ≈ 3.4 minutes
  /// Long observation window
  public let FIB_233_BEATS : Nat64 = 233;
  public let FIB_233_MS : Float = 233.0 * BEAT_MS;  // 203409ms

  /// F(14) = 377 beats ≈ 329.12 seconds ≈ 5.5 minutes
  /// Extended timer for batch operations
  public let FIB_377_BEATS : Nat64 = 377;
  public let FIB_377_MS : Float = 377.0 * BEAT_MS;  // 329121ms

  /// F(15) = 610 beats ≈ 532.53 seconds ≈ 8.9 minutes
  /// Session checkpoint interval
  public let FIB_610_BEATS : Nat64 = 610;
  public let FIB_610_MS : Float = 610.0 * BEAT_MS;  // 532530ms

  /// F(16) = 987 beats ≈ 861.65 seconds ≈ 14.4 minutes
  /// Major checkpoint interval
  public let FIB_987_BEATS : Nat64 = 987;
  public let FIB_987_MS : Float = 987.0 * BEAT_MS;  // 861651ms

  /// F(17) = 1597 beats ≈ 1394.18 seconds ≈ 23.2 minutes
  /// Extended session interval
  public let FIB_1597_BEATS : Nat64 = 1597;
  public let FIB_1597_MS : Float = 1597.0 * BEAT_MS;  // 1394181ms

  /// F(18) = 2584 beats ≈ 2255.83 seconds ≈ 37.6 minutes
  /// Long-running process timer
  public let FIB_2584_BEATS : Nat64 = 2584;
  public let FIB_2584_MS : Float = 2584.0 * BEAT_MS;  // 2255832ms

  /// F(19) = 4181 beats ≈ 3650.01 seconds ≈ 60.8 minutes ≈ 1 hour
  /// Hourly process timer (phi-harmonic approximation of 1 hour)
  public let FIB_4181_BEATS : Nat64 = 4181;
  public let FIB_4181_MS : Float = 4181.0 * BEAT_MS;  // 3650013ms

  /// F(20) = 6765 beats ≈ 5905.85 seconds ≈ 98.4 minutes ≈ 1.6 hours
  /// Extended hourly timer
  public let FIB_6765_BEATS : Nat64 = 6765;
  public let FIB_6765_MS : Float = 6765.0 * BEAT_MS;  // 5905845ms


  // ═══════════════════════════════════════════════════════════════════════════
  // TIME CONVERSION FUNCTIONS — Boundary Translators
  // Convert between sovereign beats and external clock time
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert milliseconds to beats: ms / 873
  /// Use at input boundary when receiving external timestamps
  public func msToBeats(ms : Float) : Float {
    ms / BEAT_MS
  };

  /// Convert beats to milliseconds: beats × 873
  /// Use at output boundary when communicating with external systems
  public func beatsToMs(beats : Float) : Float {
    beats * BEAT_MS
  };

  /// Convert seconds to beats: seconds × 1.145475
  public func secondsToBeats(seconds : Float) : Float {
    seconds * BEATS_PER_SECOND
  };

  /// Convert beats to seconds: beats / 1.145475
  public func beatsToSeconds(beats : Float) : Float {
    beats / BEATS_PER_SECOND
  };

  /// Convert minutes to beats: minutes × 68.7285
  public func minutesToBeats(minutes : Float) : Float {
    minutes * BEATS_PER_MINUTE
  };

  /// Convert beats to minutes: beats / 68.7285
  public func beatsToMinutes(beats : Float) : Float {
    beats / BEATS_PER_MINUTE
  };

  /// Convert hours to beats: hours × 4123.71
  public func hoursToBeats(hours : Float) : Float {
    hours * BEATS_PER_HOUR
  };

  /// Convert beats to hours: beats / 4123.71
  public func beatsToHours(beats : Float) : Float {
    beats / BEATS_PER_HOUR
  };

  /// Convert days to beats: days × 98968.96
  public func daysToBeats(days : Float) : Float {
    days * BEATS_PER_DAY
  };

  /// Convert beats to days: beats / 98968.96
  public func beatsToDays(beats : Float) : Float {
    beats / BEATS_PER_DAY
  };

  /// Convert weeks to beats: weeks × 692782.7
  public func weeksToBeats(weeks : Float) : Float {
    weeks * BEATS_PER_WEEK
  };

  /// Convert beats to weeks: beats / 692782.7
  public func beatsToWeeks(beats : Float) : Float {
    beats / BEATS_PER_WEEK
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // BEAT CALENDAR FUNCTIONS — Sovereign Time Accounting
  // Compute beats relative to epochs and absolute timestamps
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compute beats elapsed since a genesis timestamp (nanoseconds)
  /// genesis_ns: the organism's genesis timestamp in nanoseconds
  /// current_ns: current timestamp in nanoseconds
  /// Returns: beats elapsed since genesis
  public func beatsSinceGenesis(genesis_ns : Int, current_ns : Int) : Nat64 {
    if (current_ns <= genesis_ns) { return 0; };
    let elapsed_ns : Int = current_ns - genesis_ns;
    let elapsed_ms : Float = Float.fromInt(elapsed_ns) / 1_000_000.0;
    let beats : Float = elapsed_ms / BEAT_MS;
    if (beats < 0.0) { 0 } else { Nat64.fromIntWrap(Float.toInt(beats)) }
  };

  /// Compute beats until a future timestamp
  /// current_ns: current timestamp in nanoseconds
  /// future_ns: future timestamp in nanoseconds
  /// Returns: beats until future timestamp (0 if future is past)
  public func beatsUntil(current_ns : Int, future_ns : Int) : Nat64 {
    if (future_ns <= current_ns) { return 0; };
    let remaining_ns : Int = future_ns - current_ns;
    let remaining_ms : Float = Float.fromInt(remaining_ns) / 1_000_000.0;
    let beats : Float = remaining_ms / BEAT_MS;
    if (beats < 0.0) { 0 } else { Nat64.fromIntWrap(Float.toInt(beats)) }
  };

  /// Add beats to a timestamp, returning new timestamp in nanoseconds
  /// timestamp_ns: starting timestamp in nanoseconds
  /// beats: number of beats to add
  /// Returns: new timestamp in nanoseconds
  public func addBeats(timestamp_ns : Int, beats : Nat64) : Int {
    let add_ms : Float = Float.fromInt(Nat64.toNat(beats)) * BEAT_MS;
    let add_ns : Int = Float.toInt(add_ms * 1_000_000.0);
    timestamp_ns + add_ns
  };

  /// Subtract beats from a timestamp, returning new timestamp in nanoseconds
  /// timestamp_ns: starting timestamp in nanoseconds
  /// beats: number of beats to subtract
  /// Returns: new timestamp in nanoseconds
  public func subtractBeats(timestamp_ns : Int, beats : Nat64) : Int {
    let sub_ms : Float = Float.fromInt(Nat64.toNat(beats)) * BEAT_MS;
    let sub_ns : Int = Float.toInt(sub_ms * 1_000_000.0);
    timestamp_ns - sub_ns
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // FIBONACCI TIMER FUNCTIONS — Harmonic Scheduling
  // Get Fibonacci beat intervals by index
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get Fibonacci beat count by index (1-indexed to match mathematical convention)
  /// fib_index: Fibonacci sequence index (1-20 supported)
  /// Returns: F(n) as Nat64 beats, or 0 if out of range
  /// Example: fibonacciTimer(12) → 144 (the Jubilee cycle)
  public func fibonacciTimer(fib_index : Nat) : Nat64 {
    if (fib_index == 0 or fib_index > Phi.FIB.size()) { return 0; };
    Nat64.fromNat(Phi.FIB[fib_index - 1])
  };

  /// Get Fibonacci beat count in milliseconds
  /// fib_index: Fibonacci sequence index (1-20)
  /// Returns: F(n) × 873ms
  public func fibonacciTimerMs(fib_index : Nat) : Float {
    let beats = fibonacciTimer(fib_index);
    Float.fromInt(Nat64.toNat(beats)) * BEAT_MS
  };

  /// Get Fibonacci beat count in nanoseconds (for ICP timers)
  /// fib_index: Fibonacci sequence index (1-20)
  /// Returns: F(n) × 873,000,000 nanoseconds
  public func fibonacciTimerNs(fib_index : Nat) : Nat64 {
    let beats = fibonacciTimer(fib_index);
    beats * BEAT_NS
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // PHI-SCALED TIMER FUNCTIONS — Golden Ratio Scheduling
  // Scale base intervals by powers of phi
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scale a base beat count by φⁿ
  /// base_beats: starting beat count
  /// power: phi exponent (positive = expand, negative = contract, 0 = identity)
  /// Returns: base_beats × φⁿ
  /// Example: phiScaledTimer(100, 1) → 161.8 (100 × φ)
  /// Example: phiScaledTimer(100, -1) → 61.8 (100 × φ⁻¹)
  public func phiScaledTimer(base_beats : Nat64, power : Int) : Float {
    let base : Float = Float.fromInt(Nat64.toNat(base_beats));
    let phi_power : Float = phiPow(power);
    base * phi_power
  };

  /// Compute φⁿ for integer n (-6 to +6 supported, others extrapolated)
  /// Uses precomputed values from Phi module for precision
  func phiPow(n : Int) : Float {
    switch (n) {
      case (0) { 1.0 };
      case (1) { Phi.PHI };
      case (2) { Phi.PHI_2 };
      case (3) { Phi.PHI_3 };
      case (4) { Phi.PHI_4 };
      case (5) { Phi.PHI_5 };
      case (6) { Phi.PHI_6 };
      case (-1) { Phi.PHI_INV };
      case (-2) { Phi.PHI_INV_2 };
      case (-3) { Phi.PHI_INV_3 };
      case (-4) { Phi.PHI_INV_4 };
      // For larger powers, compute iteratively
      case _ {
        if (n > 6) {
          var result = Phi.PHI_6;
          var i = 6;
          while (i < n) {
            result := result * Phi.PHI;
            i += 1;
          };
          result
        } else {
          // n < -4
          var result = Phi.PHI_INV_4;
          var i = -4;
          while (i > n) {
            result := result * Phi.PHI_INV;
            i -= 1;
          };
          result
        }
      };
    }
  };

  /// Get the next phi-harmonic timer interval (multiply by φ)
  /// current_beats: current timer interval in beats
  /// Returns: current_beats × φ (expanded interval)
  public func nextPhiTimer(current_beats : Nat64) : Float {
    phiScaledTimer(current_beats, 1)
  };

  /// Get the previous phi-harmonic timer interval (multiply by φ⁻¹)
  /// current_beats: current timer interval in beats
  /// Returns: current_beats × φ⁻¹ (contracted interval)
  public func prevPhiTimer(current_beats : Nat64) : Float {
    phiScaledTimer(current_beats, -1)
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // COSMOLOGICAL BEAT CALENDARS — Standing Wave Phases
  // Express cosmic cycles as beat-phase positions
  // Pythagoras: the organism carries the cosmos within itself
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compute lunar phase from beat count since genesis
  /// beat_count: total beats since organism genesis
  /// Returns: 0.0 to 1.0 representing phase in lunar cycle
  ///   0.0 = new moon, 0.25 = first quarter, 0.5 = full moon, 0.75 = last quarter
  /// Note: Requires alignment constant for actual moon phase; returns relative cycle position
  public func lunarPhaseInBeats(beat_count : Nat64) : Float {
    let beats_f : Float = Float.fromInt(Nat64.toNat(beat_count));
    let phase : Float = fmod(beats_f, BEATS_PER_LUNAR_MONTH) / BEATS_PER_LUNAR_MONTH;
    phase
  };

  /// Compute solar year position from beat count since genesis
  /// beat_count: total beats since organism genesis
  /// Returns: 0.0 to 1.0 representing position in solar year
  ///   0.0 = genesis alignment, 0.25 = +91 days, 0.5 = +182 days, etc.
  /// Note: Genesis alignment determines when 0.0 falls in the calendar year
  public func solarYearPositionInBeats(beat_count : Nat64) : Float {
    let beats_f : Float = Float.fromInt(Nat64.toNat(beat_count));
    let phase : Float = fmod(beats_f, BEATS_PER_YEAR) / BEATS_PER_YEAR;
    phase
  };

  /// Compute weekly position from beat count
  /// beat_count: total beats since organism genesis
  /// Returns: 0.0 to 1.0 representing position in week
  ///   0.0 = week start, 0.143 = +1 day, 0.286 = +2 days, etc.
  public func weeklyPositionInBeats(beat_count : Nat64) : Float {
    let beats_f : Float = Float.fromInt(Nat64.toNat(beat_count));
    let phase : Float = fmod(beats_f, BEATS_PER_WEEK) / BEATS_PER_WEEK;
    phase
  };

  /// Compute daily position from beat count
  /// beat_count: total beats since organism genesis
  /// Returns: 0.0 to 1.0 representing position in day
  ///   0.0 = day start, 0.5 = noon (relative to genesis), 1.0 = day end
  public func dailyPositionInBeats(beat_count : Nat64) : Float {
    let beats_f : Float = Float.fromInt(Nat64.toNat(beat_count));
    let phase : Float = fmod(beats_f, BEATS_PER_DAY) / BEATS_PER_DAY;
    phase
  };

  /// Compute Jubilee cycle position from beat count
  /// beat_count: total beats since organism genesis
  /// Returns: 0.0 to 1.0 representing position in 144-beat Jubilee cycle
  ///   At 1.0 (every 144 beats), compliance reserves recycle
  public func jubileeCyclePosition(beat_count : Nat64) : Float {
    let beats_f : Float = Float.fromInt(Nat64.toNat(beat_count));
    let jubilee_f : Float = 144.0;  // F(12)
    let phase : Float = fmod(beats_f, jubilee_f) / jubilee_f;
    phase
  };

  /// Get the beat count to the next Jubilee (F(12)=144 beat boundary)
  /// beat_count: current beat count
  /// Returns: beats remaining until next Jubilee
  public func beatsToNextJubilee(beat_count : Nat64) : Nat64 {
    let current : Nat = Nat64.toNat(beat_count);
    let remainder : Nat = current % 144;
    if (remainder == 0) { 144 } else { Nat64.fromNat(144 - remainder) }
  };


  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Float modulo (Motoko has no native float mod)
  func fmod(x : Float, y : Float) : Float {
    if (y == 0.0) { return 0.0; };
    x - Float.floor(x / y) * y
  };

}
