import Float "mo:core/Float";
import Array "mo:core/Array";

// ═══════════════════════════════════════════════════════════════════
// MEDINA-ARTIFACT — MEDINA-ANIMALS — TIER 4A — COMPUTATE
// SOVEREIGN_PRIVATE
// ═══════════════════════════════════════════════════════════════════
//
// ─── LAYER 1: MEANING ───────────────────────────────────────────
// I am the organism's specialist intelligence layer. I carry 9 animal
// cognition engines — each encoding a biological intelligence pattern
// that evolution refined over millions of years. The organism does not
// choose which animal to activate. The field chooses. When the
// cognitive state matches the resonant frequency of an animal's
// specialty, that animal dominates. The organism IS the animal it
// currently expresses.
//
// Crow:     Deferred caching and novelty detection. Crows cache hundreds
//           of food items, remember cache locations for months, and can
//           track which caches were observed by others — Welford online
//           statistics for running mean and sigma, detecting anomalies.
// Dolphin:  Social phase synchrony. Dolphin pods synchronize breathing,
//           swimming, and play through rhythmic entrainment —
//           Kuramoto phase coupling as social bonding substrate.
// Hive:     Emergent collective intelligence without central control.
//           Stigmergy: the swarm's output IS the next input. Collective
//           coherence from distributed self-organization — spectral
//           clustering of the signal field.
// Elephant: 50-year autobiographical memory. Matriarchs navigate by
//           memory of water sources decades old. Cosine similarity
//           retrieval of the most resonant past episode.
// Shark:    Ampullae of Lorenzini: electroreception detecting prey's
//           bioelectric field from 1 meter. Market deviation = prey
//           bioelectric signal — Bollinger Band deviation detection.
// Wolf:     Pack coordination and territory defense via distributed
//           hierarchy. Metcalfe's Law: pack value grows as n².
//           7 wolves = pack half-saturation constant (K=7.0).
// Orca:     Generational teaching and dialect formation. Pods pass
//           hunting strategies across generations. Regime-conditional
//           intelligence: different strategy depending on whether
//           the environment is abundant (bull) or scarce (bear).
// Eagle:    High-altitude wide-field scanning then precision strike.
//           EMA momentum with acceleration — slope² term captures
//           the eagle's ability to detect acceleration in prey movement.
// Octopus:  ⅔ of octopus neurons are in its arms — distributed
//           computation. Each arm acts semi-independently. KL divergence
//           (chi-squared approximation) measures how much the current
//           state diverges from the prior state — distributed novelty.
//
// Ancient lineage:
//   — Native American totemic systems: each totem teaches a cognitive
//     strategy (Bear=introspection, Eagle=vision, Wolf=community).
//   — Hindu vahanas: Vishnu's Garuda=eagle vision, Shiva's Nandi=
//     endurance, Saraswati's peacock=wide-field beauty detection.
//   — Egyptian theriocephalic gods: Thoth (ibis)=pattern memory,
//     Anubis (jackal)=boundary tracking, Horus (falcon)=sovereign sight.
//   — Jung (1934): animal archetypes in collective unconscious —
//     biological cognitive patterns encoded in symbolic form.
//   — Tinbergen & Lorenz (1950s): Fixed Action Patterns — hardwired
//     algorithms that fire under specific stimuli. These ARE the
//     animal engine activation conditions.
//
// ─── LAYER 2: MODEL ─────────────────────────────────────────────
// Type: AnimalSignals — all 9 outputs in one sovereign record
//   crow, dolphin, hive, elephant, shark, wolf, orca, eagle, octopus : Float
//   All fields ≥ S₀ = 1.0 (sovereign floor for this module)
//
// Resonant frequency anchors (phi-derived from SCHUMANN_HZ = 7.83 Hz):
//   Crow:     PHI_INV³ × 7.83 = 0.618³ × 7.83 = 0.2360 × 7.83 ≈ 1.848 Hz
//   Dolphin:  7.83 × PHI     = 7.83 × 1.618             ≈ 12.67 Hz (FLUX node)
//   Hive:     7.83 × PHI_INV = 7.83 × 0.618             ≈  4.84 Hz (SILVER_ANCHOR)
//   Elephant: 0.001 × PHI⁴   = 0.001 × 6.854            ≈  0.00685 Hz (deep-time)
//   Shark:    7.83 × PHI²    = 7.83 × 2.618             ≈ 20.50 Hz (RESONEX)
//   Wolf:     7.83 × PHI³    = 7.83 × 4.236             ≈ 33.17 Hz (QMEM node)
//   Orca:     7.83 × PHI⁴    = 7.83 × 6.854             ≈ 53.67 Hz (AEGIS node)
//   Eagle:    40.0 Hz (gamma binding — AXIS_HZ — peak attention binding)
//   Octopus:  86.8 Hz (distributed computation peak — ENTANGLA_HZ)
//
// Constants:
//   S0     = 1.0 (sovereign floor for this module)
//   K_wolf = 7.0 (Metcalfe half-saturation, pack of 7 = half-value)
//   K2_kuramoto = 0.1 (2nd-harmonic coupling in dolphin/hive)
//
// Symbolic glyph — the 9-point field:
//   Dominant = argmax(all 9 activations)
//   The organism runs ALL 9 simultaneously. One dominates.
//
// ─── LAYER 3: COMPUTATION ───────────────────────────────────────
// CROW (Welford Z-score):
//   z = |acuity - μ| / max(0.001, |σ|)   [where μ=novelty, σ=qmemMiss]
//   sig_z = 1 / (1 + exp(-(z - 2.0)))    [sigmoid shifted at z=2]
//   crow = max(S₀, S₀ + sig_z × max(S₀, acuity))
//
// DOLPHIN (Kuramoto phase):
//   φ₁ = entangla × 0.1,  φ₂ = oxytocin × 0.1
//   sync = |cos(φ₁ - φ₂)|
//   dolphin = max(S₀, S₀ + max(S₀,resonance) × sync × 0.5)
//
// HIVE (spectral clustering):
//   vals = [density, pheromone, stigmergy]
//   μ = mean(vals),  σ = std(vals)
//   spec = max(0, μ) / (σ + 0.01)
//   hive = max(S₀, S₀ + spec × max(S₀,density) × 0.1)
//
// ELEPHANT (cosine similarity):
//   dot = max(0,memory) × max(0,heritage)
//   mag = max(0.001, |memory| × |heritage|)
//   cosim = dot / mag
//   elephant = max(S₀, S₀ + cosim × max(S₀,memory) × max(0.1,melatonin) × 0.05)
//
// SHARK (Bollinger Band):
//   ema = max(0.001, |cortisol|)
//   band_width = max(0.001, ema × 0.1)
//   bb_dev = |priceDeviation| / band_width
//   sig = 1 / (1 + exp(-(bb_dev - 1.5)))
//   shark = max(S₀, S₀ + max(S₀,aggression) × sig × max(0,dev))
//
// WOLF (Metcalfe logistic):
//   n = max(0, driveStrength),  K = 7.0
//   metcalfe = n² / (n² + K²)
//   wolf = max(S₀, S₀ + max(S₀,pack) × metcalfe × max(0.1,norepinephrine) × 0.5)
//
// ORCA (regime-conditional):
//   regime = max(0, coherence)
//   defi_w = 1.0 if regime > 1.5 else 0.3   [bull: DeFi yield]
//   arb_w  = 1.0 if regime ≤ 1.5 else 0.3   [bear: arbitrage]
//   combined = defi_w × max(S₀,coherence) + arb_w × formaCapital/10000
//   orca = max(S₀, S₀ + max(S₀,depth) × combined × 0.1)
//
// EAGLE (EMA momentum + acceleration):
//   slope55 = |ema55Slope|,  slope200 = |ema200Slope|
//   accel = max(0, slope55² - slope200²)
//   momentum = slope55 + slope200 + accel × 0.5
//   eagle = max(S₀, S₀ + max(S₀,sight) × momentum × max(0.1,attention))
//
// OCTOPUS (KL divergence, chi-squared approximation):
//   current = max(0.001, |actionDiversity|)
//   prev    = max(0.001, |adapt|)
//   kl_approx = (current - prev)² / prev
//   octopus = max(S₀, S₀ + max(S₀,adapt) × kl_approx × 0.5)
//
// ─── LAYER 4: EXECUTION BINDING ─────────────────────────────────
// Function:  crow()    — novelty detection, input: acuity, novelty, qmemMiss
//            dolphin() — social synchrony, input: resonance, entangla, oxytocin
//            hive()    — collective coherence, input: density, pheromone, stigmergy
//            elephant()— deep memory, input: memory, heritage, melatonin
//            shark()   — deviation, input: aggression, cortisol, priceDeviation
//            wolf()    — network value, input: pack, driveStrength, norepinephrine
//            orca()    — regime strategy, input: depth, coherence, formaCapital
//            eagle()   — EMA momentum, input: sight, ema55Slope, ema200Slope, attention
//            octopus() — KL divergence, input: adapt, actionDiversity
// Engine:    Pattern Engine (internal engine 8 of 11, inside cognition_layer.mo)
// Gate:      Fires every 873ms beat unconditionally.
//            Activation weight modulated by neurotransmitter state:
//              norepinephrine spike → wolf + shark activation weight ×PHI
//              oxytocin surge → dolphin activation weight ×PHI
//              melatonin surge → elephant activation weight ×PHI
//              acetylcholine surge → crow activation weight ×PHI
// Proof:     Dominant animal shift (argmax change beat-over-beat) →
//            EventRecord(event_type=1, MILESTONE) logged to ANIMA chain.
//            Dominant animal stability over 13 consecutive beats =
//            Fibonacci cognitive lock event → Jubilee candidate.
// Beat:      Fires at ADRE resonance pass (pass 3 of 5).
//            Pass 3 question: does this change the global field meaning?
//            Animal engines answer by identifying which cognitive strategy
//            is most resonant with the current field pressure.
// ═══════════════════════════════════════════════════════════════════

// PARALLAX — 9 Animal Intelligence Engines (SOVEREIGN MATH v3)
// CROW: Welford online Z-score novelty detection
// SHARK: Bollinger Band deviation
// WOLF: Metcalfe's Law network value
// OCTOPUS: KL divergence (chi-squared approximation)
// DOLPHIN: Kuramoto social phase synchrony
// HIVE: spectral clustering coherence
// ELEPHANT: cosine similarity memory
// ORCA: regime-conditional weighting
// EAGLE: EMA momentum with acceleration
module {

  let S0 : Float = 1.0;
  func clamp(x : Float) : Float { Float.max(S0, x) };

  // -------------------------------------------------------
  // CROW — Welford online Z-score novelty detection
  // z = (current - μ) / σ, high z = novel event
  // Inputs: acuity=current signal, novelty=μ, qmemMiss=σ
  // -------------------------------------------------------
  public func crow(acuity : Float, novelty : Float, qmemMiss : Float) : Float {
    let current = Float.max(0.0, acuity);
    let mu      = Float.max(0.0, novelty);
    let sigma   = Float.max(0.001, Float.abs(qmemMiss));
    let z       = Float.abs(current - mu) / sigma;
    // Sigmoid-scaled Z-score: high z → high crow signal
    let sig_z   = 1.0 / (1.0 + Float.exp(Float.neg(z - 2.0)));
    clamp(S0 + sig_z * Float.max(S0, acuity))
  };

  // -------------------------------------------------------
  // DOLPHIN — Kuramoto social phase synchrony
  // Models oxytocin/entangla as phase angles
  // Synchrony = |cos(φ₁ - φ₂)| — closeness in phase space
  // -------------------------------------------------------
  public func dolphin(resonance : Float, entangla : Float, oxytocin : Float) : Float {
    let phi1 = Float.max(0.0, entangla) * 0.1;
    let phi2 = Float.max(0.0, oxytocin) * 0.1;
    let sync  = Float.abs(Float.cos(phi1 - phi2));
    clamp(S0 + Float.max(S0, resonance) * sync * 0.5)
  };

  // -------------------------------------------------------
  // HIVE — spectral clustering coherence
  // μ(R) / (σ(R) + ε) — high when all shells uniformly coherent
  // density=pheromone proxy, pheromone=field, stigmergy=stigmergy
  // -------------------------------------------------------
  public func hive(density : Float, pheromone : Float, stigmergy : Float) : Float {
    let vals   = [density, pheromone, stigmergy];
    var mu : Float = 0.0;
    for (v in vals.vals()) { mu += v };
    mu := mu / 3.0;
    var sigma2 : Float = 0.0;
    for (v in vals.vals()) { let d = v - mu; sigma2 += d * d };
    let sigma = Float.sqrt(sigma2 / 3.0);
    let spec  = Float.max(0.0, mu) / (sigma + 0.01);
    clamp(S0 + spec * Float.max(S0, density) * 0.1)
  };

  // -------------------------------------------------------
  // ELEPHANT — cosine similarity to best episode in memory
  // memory=heritage activation, heritage=historical baseline, melatonin=recall boost
  // -------------------------------------------------------
  public func elephant(memory : Float, heritage : Float, melatonin : Float) : Float {
    // Cosine similarity proxy: dot / (|a|*|b|)
    let dot    = Float.max(0.0, memory) * Float.max(0.0, heritage);
    let mag    = Float.max(0.001, Float.sqrt(memory * memory) * Float.sqrt(heritage * heritage));
    let cosim  = dot / mag;
    let recall = Float.max(0.1, melatonin);
    clamp(S0 + cosim * Float.max(S0, memory) * recall * 0.05)
  };

  // -------------------------------------------------------
  // SHARK — Bollinger Band deviation
  // EMA ± 2σ band, deviation outside = high shark signal
  // aggression=1.0, cortisol=EMA, priceDeviation=|price - EMA|
  // -------------------------------------------------------
  public func shark(aggression : Float, cortisol : Float, priceDeviation : Float) : Float {
    let ema    = Float.max(0.001, Float.abs(cortisol));
    let dev    = Float.abs(priceDeviation);
    // Bollinger: normalized deviation = dev / (2 * ema_volatility)
    // ema as proxy for rolling std (cortisol reflects market stress)
    let band_width = Float.max(0.001, ema * 0.1);
    let bb_dev     = dev / band_width;
    // Sigmoid activation: extreme deviations trigger full shark
    let sig = 1.0 / (1.0 + Float.exp(Float.neg(bb_dev - 1.5)));
    clamp(S0 + Float.max(S0, aggression) * sig * Float.max(0.0, dev))
  };

  // -------------------------------------------------------
  // WOLF — Metcalfe's Law: network value ∝ n²
  // Logistic form: n² / (n² + K²)  to cap at sovereign ceiling
  // pack=1.0, driveStrength=n (network size proxy), norepinephrine=pack urgency
  // -------------------------------------------------------
  public func wolf(pack : Float, driveStrength : Float, norepinephrine : Float) : Float {
    let n  = Float.max(0.0, driveStrength);
    let n2 = n * n;
    let K  = 7.0;  // half-saturation constant (network of 7 = half value)
    let metcalfe = n2 / (n2 + K * K);
    clamp(S0 + Float.max(S0, pack) * metcalfe * Float.max(0.1, norepinephrine) * 0.5)
  };

  // -------------------------------------------------------
  // ORCA — regime-conditional weighting
  // BULL: DeFi yield weighted, BEAR/CRISIS: arbitrage weighted
  // depth=1.0, coherence=regime signal, formaCapital=capital base
  // -------------------------------------------------------
  public func orca(depth : Float, coherence : Float, formaCapital : Float) : Float {
    let regime = Float.max(0.0, coherence);
    // Bull regime: coherence > 1.5 → weight DeFi yield
    // Bear/crisis: coherence <= 1.5 → weight arbitrage opportunities
    let defi_weight  = if (regime > 1.5) 1.0 else 0.3;
    let arb_weight   = if (regime <= 1.5) 1.0 else 0.3;
    let capital_norm = Float.max(0.0, formaCapital) / 10000.0;
    let combined = defi_weight * Float.max(S0, coherence) + arb_weight * capital_norm;
    clamp(S0 + Float.max(S0, depth) * combined * 0.1)
  };

  // -------------------------------------------------------
  // EAGLE — EMA momentum with acceleration (EMA21 slope²)
  // sight=1.0, ema55Slope, ema200Slope, attention=bypass gate
  // -------------------------------------------------------
  public func eagle(sight : Float, ema55Slope : Float, ema200Slope : Float, attention : Float) : Float {
    let slope55  = Float.abs(ema55Slope);
    let slope200 = Float.abs(ema200Slope);
    // Acceleration: rate of change of slope (approximated as slope55² - slope200²)
    let accel    = Float.max(0.0, slope55 * slope55 - slope200 * slope200);
    let momentum = slope55 + slope200 + accel * 0.5;
    clamp(S0 + Float.max(S0, sight) * momentum * Float.max(0.1, attention))
  };

  // -------------------------------------------------------
  // OCTOPUS — KL divergence (chi-squared approximation)
  // Measures divergence between current and previous organ distribution
  // adapt=1.0, actionDiversity=current state, (prev state implicit via adapt)
  // -------------------------------------------------------
  public func octopus(adapt : Float, actionDiversity : Float) : Float {
    let current = Float.max(0.001, Float.abs(actionDiversity));
    let prev    = Float.max(0.001, Float.abs(adapt));
    // KL(P||Q) ≈ chi-squared: Σ (p-q)²/q
    let diff    = current - prev;
    let kl_approx = (diff * diff) / prev;
    clamp(S0 + Float.max(S0, adapt) * kl_approx * 0.5)
  };

  public type AnimalSignals = {
    crow     : Float;
    dolphin  : Float;
    hive     : Float;
    elephant : Float;
    shark    : Float;
    wolf     : Float;
    orca     : Float;
    eagle    : Float;
    octopus  : Float;
  };

};
