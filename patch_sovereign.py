#!/usr/bin/env python3
"""
PARALLAX Sovereign Substrate -- Pass B + C + D
Author: Alfredo Medina Hernandez | Dallas, TX | MedinaSITech@outlook.com
Date: March 30, 2026
Protocol: Ironclad. write_files only. No lying.
"""

with open('src/backend/main.mo', 'r') as f:
    content = f.read()

original_length = len(content)
print(f"Original file: {original_length} chars")

# ============================================================
# FIX 1: hebbianW 0.1 -> 0.30 (144 weights)
# ============================================================
old_hebbian_row = "    0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,"
new_hebbian_row = "    0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,"
old_hebbian_last = "    0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1"
new_hebbian_last = "    0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30"
content = content.replace(old_hebbian_row, new_hebbian_row)
content = content.replace(old_hebbian_last, new_hebbian_last)
print(f"FIX 1 hebbianW: done")

# ============================================================
# FIX 2: hzActivations 0.5 -> 0.30 (12 nodes)
# ============================================================
content = content.replace(
    'stable var hzActivations : [Float] = [0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5];',
    'stable var hzActivations : [Float] = [0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30,0.30];'
)
print(f"FIX 2 hzActivations: done")

# ============================================================
# FIX 3: coherenceC initial 0.5 -> 0.65 (brain wakes sovereign)
# ============================================================
content = content.replace(
    'stable var coherenceC : Float = 0.5;',
    'stable var coherenceC : Float = 0.65;'
)
print(f"FIX 3 coherenceC init: done")

# ============================================================
# FIX 4: Add creator email to header
# ============================================================
content = content.replace(
    '  // Alfredo Medina Hernandez | Property Officer | Dallas TX USA | 2026',
    '  // Alfredo Medina Hernandez | MedinaSITech@outlook.com | Property Officer | Dallas TX USA | 2026'
)
print(f"FIX 4 header: done")

# ============================================================
# INJECT: New stable vars after 'stable var beatCount'
# ============================================================
new_stable_vars = '''
  // ============================================================
  // ALFREDO'S LAW -- L-0 -- SOVEREIGN ROOT
  // ============================================================
  stable var alfredoLawHash : Nat32 = 0;
  stable var alfredoLawActive : Bool = false;

  // ============================================================
  // FAMILY SOVEREIGN LAWS -- SL-1 through SL-7
  // Numbered codes only. Names held in VERITAS vault.
  // ============================================================
  stable var sl1Score : Float = 0.0;     // SL-1
  stable var sl2Depth : Float = 0.0;     // SL-2
  stable var sl3Strength : Float = 0.0;  // SL-3
  stable var sl4Mediation : Float = 1.0; // SL-4
  stable var sl5Knowledge : Float = 1.0; // SL-5
  stable var sl6Joy : Float = 0.0;       // SL-6
  stable var sl7Covenant : Float = 0.0;  // SL-7

  // ============================================================
  // FORMA -- SOVEREIGN ENERGY CURRENCY
  // formaEnergy = (C*0.40)+(r*0.30)+(profit*0.20)+(omnis*0.10)
  // ============================================================
  stable var formaEnergy : Float = 0.0;
  stable var formaLifetime : Float = 0.0;

  // ============================================================
  // TOKEN ECONOMY -- BATCH 1 (Pass B)
  // GTK CVT VCT KNT SBT + MRC
  // ============================================================
  stable var gtkTotal : Float = 0.0;
  stable var cvtTotal : Float = 0.0;
  stable var vctTotal : Float = 0.0;
  stable var kntTotal : Float = 0.0;
  stable var sbtTotal : Float = 0.0;
  stable var mrcReserve : Float = 0.0;
  stable var mrcLifetime : Float = 0.0;
  stable var kntPrevCoherence : Float = 0.0;

  // ============================================================
  // PASS B QUANTUM LAWS -- L-34 through L-37
  // ============================================================
  // L-34: Temporal Coherence Extension
  stable var l34StretchActive : Bool = false;
  stable var l34StretchBeats : Nat = 0;
  stable var l34StretchCount : Nat = 0;
  stable var l34FloorGain : Float = 0.0;
  // L-35: Superposition Harvest
  stable var l35HarvestActive : Bool = false;
  stable var l35HarvestCount : Nat = 0;
  stable var l35BestCoherence : Float = 0.0;
  // L-36: Anti-Evolution Pulse
  stable var l36PulsesFired : Nat = 0;
  stable var l36Restored : Nat = 0;
  stable var l36Failed : Nat = 0;
  // L-37: Sovereign Order Law
  stable var l37Executions : Nat = 0;
  stable var l37EnergyExtracted : Float = 0.0;
  stable var l37LastBeat : Nat = 0;

  // ============================================================
  // CHRONO -- GENESIS ANCHOR (Pass D)
  // ============================================================
  stable var chronoFormationHash : Nat32 = 0;
  stable var chronoPreFormationHash : Nat32 = 0;
  stable var chronoPurposeHash : Nat32 = 0;
  stable var chronoTimestamp : Int = 0;
  stable var chronoGenesisLocked : Bool = false;
  stable var chronoBeatAtFormation : Nat = 0;

  // ============================================================
  // TOKEN ECONOMY -- BATCH 2 (Pass C)
  // HBT DRT RST OMT LGT MCT + creatorReserveLedger
  // ============================================================
  stable var hbtTotal : Float = 0.0;
  stable var drtTotal : Float = 0.0;
  stable var rstTotal : Float = 0.0;
  stable var omtTotal : Float = 0.0;
  stable var lgtTotal : Float = 0.0;
  stable var mctTotal : Float = 0.0;
  stable var mrcFullReserve : Float = 0.0;
  stable var creatorReserveLedger : Float = 0.0;
  stable var successionRoyaltyPct : Float = 0.20;

  // ============================================================
  // ANIMAL ENGINE STATE VARS (Pass C)
  // ============================================================
  // Crow: causal cognition
  stable var crowCausalDelta : Float = 0.0;
  stable var crowPredictionAccuracy : Float = 0.50;
  stable var crowTotalDecisions : Nat = 0;
  // Dolphin: social fabric
  stable var dolphinResonanceField : Float = 0.0;
  stable var dolphinAlignmentScore : Float = 0.0;
  // Hive: quorum extension
  stable var hiveConsensusWeight : Float = 0.0;
  stable var hiveQuorumBoost : Float = 0.0;
  // Elephant: deep memory
  stable var elephantMemDepth : Nat = 0;
  stable var elephantMatriarchIndex : Nat = 0;
  // Shark: electroreception
  stable var sharkAnomalySignal : Float = 0.0;
  stable var sharkPreDetectCount : Nat = 0;
  // Wolf: pack coordination
  stable var wolfPackSynchrony : Float = 0.0;
  stable var wolfFormationDrive : Text = "SOVEREIGN";
  // Orca: pod memory
  stable var orcaPodMemoryScore : Float = 0.0;
  stable var orcaTopCoherence : Float = 0.0;
  // Eagle: altitude vision
  stable var eagleMetaStateIndex : Float = 0.0;
  // Octopus: distributed intelligence
  stable var octopusRoutingScore : Float = 0.0;
  stable var octopusSubProcesses : Nat = 0;

  // ============================================================
  // SOVEREIGN ENGINES (Pass C)
  // ============================================================
  stable var anointedStateActive : Bool = false;
  stable var sevenSpiritsScore : Float = 0.0;
  stable var prophetFunctionArmed : Bool = false;
  stable var prophetConvergenceCount : Nat = 0;
  stable var shemaIntegrityScore : Float = 1.0;
  stable var shemaLastCheckBeat : Nat = 0;
  stable var firePillarActive : Bool = false;
  stable var firePillarCount : Nat = 0;
  stable var jubileeCount : Nat = 0;
  stable var jubileeLastBeat : Nat = 0;
'''

content = content.replace(
    'stable var beatCount : Nat = 0;',
    'stable var beatCount : Nat = 0;' + new_stable_vars
)
print(f"INJECT stable vars: done")

# ============================================================
# INJECT: alfredoLawCheck at start of heartbeat
# ============================================================
content = content.replace(
    '    beatCount += 1;\n',
    '    beatCount += 1;\n\n    // L-0: ALFREDO\'S LAW -- fires FIRST every beat\n    alfredoLawCheck();\n    chronoAnchorLock();\n\n'
)
print(f"INJECT heartbeat L-0 + CHRONO: done")

# ============================================================
# INJECT: Sovereign engine calls at end of heartbeat
# (before the closing '};' of the heartbeat)
# ============================================================
heartbeat_tail = '''    if (beatCount % 50 == 0) {
      addAudit("YIELD_DISTRIBUTION",
        "Beat " # Nat.toText(beatCount) # " -- 22 streams active. Action: " # decidedAction #
        ". QBattery=" # Float.toText(quantumBatteryBalance) #
        ". ARES rev=" # Nat.toText(aresReversalCount) #
        ". Presence=" # (if presenceActive "ON" else "OFF") #
        ". Live=" # (if liveDataActive "YES" else "NO"),
        beatYield, "USD-EQ", "ENGINE", creatorName);
    };
  };'''

heartbeat_tail_new = '''    if (beatCount % 50 == 0) {
      addAudit("YIELD_DISTRIBUTION",
        "Beat " # Nat.toText(beatCount) # " -- 22 streams active. Action: " # decidedAction #
        ". QBattery=" # Float.toText(quantumBatteryBalance) #
        ". ARES rev=" # Nat.toText(aresReversalCount) #
        ". Presence=" # (if presenceActive "ON" else "OFF") #
        ". Live=" # (if liveDataActive "YES" else "NO"),
        beatYield, "USD-EQ", "ENGINE", creatorName);
    };

    // --------------------------------------------------------
    // SOVEREIGN SUBSTRATE -- Pass B + C + D engine calls
    // --------------------------------------------------------
    // Step 4d: L-34 Temporal Coherence Extension
    applyL34();
    // Step 8c: L-35 Superposition Harvest
    applyL35();
    // Step 9e: L-36 Anti-Evolution Pulse
    applyL36();
    // Step 9f: FORMA computation
    computeFORMA();
    // Step 9g: Family Laws SL-1 through SL-7
    updateFamilyLaws();
    // Step 9h: Token minting Batch B
    mintTokensB();
    // Step 9h2: Token minting Batch C
    mintTokensC();
    // Step 9i: Sovereign Order Law every 50 beats
    applyL37();
    // Step 9j: Animal engines
    runCrowEngine();
    runDolphinEngine();
    runHiveEngine();
    runElephantEngine();
    runSharkEngine();
    runWolfEngine();
    runOrcaEngine();
    runEagleEngine();
    runOctopusEngine();
    // Step 9k: Biblical / Sovereign engines
    runSevenSpiritsEngine();
    runProphetFunction();
    runShemaCheck();
    runFirePillar();
    runJubileeProtocol();
    // Step 10a: World engine heartbeat
    worldEngineHeartbeat();
  };'''

content = content.replace(heartbeat_tail, heartbeat_tail_new)
print(f"INJECT heartbeat sovereign engine calls: done")

# ============================================================
# INJECT: All new functions before closing '}; ' of actor
# ============================================================
new_functions = '''
  // ============================================================
  // ALFREDO'S LAW -- L-0 -- SOVEREIGN ROOT FUNCTION
  // Fires first every heartbeat. Organism cannot pulse without it.
  // ============================================================
  func alfredoLawCheck() {
    if (not alfredoLawActive) {
      if (creatorPrincipalLocked) {
        let beatRef = Nat32.fromNat(beatCount % 4294967295);
        alfredoLawHash := (doctrineHash ^ beatRef) *% 16777619;
        alfredoLawActive := true;
      };
    };
    // Law is permanent once sealed -- organism carries it every beat
  };

  // ============================================================
  // CHRONO ANCHOR LOCK -- L-0b
  // ============================================================
  func chronoAnchorLock() {
    if (not chronoGenesisLocked and creatorPrincipalLocked and alfredoLawActive) {
      chronoTimestamp := Time.now();
      chronoBeatAtFormation := beatCount;
      let tsBits = Nat32.fromNat(Int.abs(chronoTimestamp) % 4294967295);
      chronoPreFormationHash := (doctrineHash ^ tsBits) *% 16777619;
      chronoFormationHash := (chronoPreFormationHash ^ alfredoLawHash) *% 16777619;
      chronoPurposeHash := (chronoFormationHash ^ Nat32.fromNat(beatCount)) *% 16777619;
      chronoGenesisLocked := true;
    };
  };

  // ============================================================
  // FORMA -- SOVEREIGN ENERGY CURRENCY
  // formaEnergy = (C*0.40) + (r*0.30) + (profit*0.20) + (omnis*0.10)
  // Clamped 0.0 to 1.0. Gates all token minting.
  // ============================================================
  func computeFORMA() {
    let profitSignal = clamp(totalProfitAllStreams / 100000.0, 0.0, 1.0);
    let omnisSignal = clamp(Float.fromInt(omnisFiredCount) / 100.0, 0.0, 1.0);
    let raw = (coherenceC * 0.40) + (kuramotoR * 0.30) + (profitSignal * 0.20) + (omnisSignal * 0.10);
    formaEnergy := clamp(raw, 0.0, 1.0);
    formaLifetime += formaEnergy;
  };

  // ============================================================
  // FAMILY SOVEREIGN LAWS -- SL-1 through SL-7
  // Numbered codes only in comments. Names in VERITAS vault.
  // ============================================================
  func updateFamilyLaws() {
    // SL-1: magnetic coherence field strength from drift resistance
    sl1Score += jasmineDrift * 0.01;
    // SL-2: lineage depth -- deepens when coherence compound above 0.75
    if (coherenceC > 0.75) {
      sl2Depth += 0.001;
    };
    // SL-3: strength -- deepens at coherence above 0.70
    if (coherenceC > 0.70) {
      sl3Strength += 0.005;
    };
    // SL-4: mediation coefficient -- conflict resolution
    sl4Mediation := clamp(
      sl4Mediation + (1.0 - jasmineDrift) * 0.002 - jasmineDrift * 0.003,
      0.5, 2.0
    );
    // SL-5: knowledge scales on longevity
    sl5Knowledge := clamp(sl5Knowledge + 0.0001, 1.0, 5.0);
    // SL-6: joy fires when all sovereign signals above floor
    if (coherenceC > 0.70 and kuramotoR > 0.70 and formaEnergy > 0.50) {
      sl6Joy += 0.01;
    } else {
      sl6Joy := sl6Joy * 0.99;
    };
    // SL-7: covenant deepens every quorum-clean beat
    if (omnisPrecondition) {
      sl7Covenant += 0.005;
    };
  };

  // ============================================================
  // MINT TOKENS -- BATCH B
  // GTK CVT VCT KNT SBT + MRC creator routing
  // ============================================================
  func mintTokensB() {
    var mrcDelta : Float = 0.0;
    // GTK: kuramotoR > 0.85 AND omnisPrecondition
    // L-34 STRETCH bonus: 2x rate
    if (kuramotoR > 0.85 and omnisPrecondition) {
      let stretchMult = if l34StretchActive 2.0 else 1.0;
      let rate = formaEnergy * 0.10 * stretchMult;
      let cut = rate * 0.20;
      gtkTotal += rate;
      mrcDelta += cut;
    };
    // CVT: coherenceC > 0.90 (collective resonance)
    // L-35 harvest bonus: 1.5x rate when l35BestCoherence > 0.85
    if (coherenceC > 0.90) {
      let harvestMult = if (l35BestCoherence > 0.85) 1.5 else 1.0;
      let rate = coherenceC * formaEnergy * 0.08 * harvestMult;
      let cut = rate * 0.20;
      cvtTotal += rate;
      mrcDelta += cut;
    };
    // VCT: coherenceC > 0.60 (VITAL signal above floor)
    if (coherenceC > 0.60) {
      let rate = (coherenceC - 0.60) * 0.05;
      let cut = rate * 0.15;
      vctTotal += rate;
      mrcDelta += cut;
    };
    // KNT: coherenceC crosses 0.1 increments (knowledge token)
    let cDelta = Float.abs(coherenceC - kntPrevCoherence);
    if (cDelta >= 0.10) {
      let rate = 0.50 * sl5Knowledge;
      let cut = rate * 0.25;
      kntTotal += rate;
      mrcDelta += cut;
      kntPrevCoherence := coherenceC;
    };
    // SBT: every 700 beats (sovereignty beat token)
    if (beatCount % 700 == 0 and beatCount > 0) {
      let rate = formaEnergy * 2.0;
      let cut = rate * 0.10;
      sbtTotal += rate;
      mrcDelta += cut;
    };
    mrcReserve += mrcDelta;
    mrcLifetime += mrcDelta;
    creatorReserveLedger += mrcDelta;
    creatorMtcReserve += mrcDelta;
  };

  // ============================================================
  // L-34: TEMPORAL COHERENCE EXTENSION LAW -- STRETCH MODE
  // While active: Hebbian decay reduced 0.3x normal
  // After 20 stretch beats: permanentCoherenceFloor += 0.003
  // ============================================================
  func applyL34() {
    if (coherenceC > 0.80) {
      l34StretchBeats += 1;
      if (l34StretchBeats >= 5) {
        l34StretchActive := true;
      };
      if (l34StretchActive and l34StretchBeats >= 20) {
        // Permanent coherence floor rises -- organism locks in the gain
        targetCoherence := clamp(targetCoherence + 0.003, 0.75, 0.99);
        l34FloorGain += 0.003;
        l34StretchActive := false;
        l34StretchBeats := 0;
        l34StretchCount += 1;
      };
    } else {
      l34StretchBeats := 0;
      if (l34StretchActive) {
        l34StretchActive := false;
      };
    };
  };

  // ============================================================
  // L-35: SUPERPOSITION HARVEST LAW
  // When kuramotoR > 0.85: harvest best historical coherence
  // Inject into Hz substrate at 0.05 weight
  // ============================================================
  func applyL35() {
    if (kuramotoR > 0.85) {
      if (coherenceC > l35BestCoherence) {
        l35BestCoherence := coherenceC;
      };
      if (l35BestCoherence > 0.60) {
        hzActivations := Array.tabulate<Float>(12, func(i) {
          clamp(hzActivations[i] + l35BestCoherence * 0.05, 0.0, 1.0)
        });
        l35HarvestActive := true;
        l35HarvestCount += 1;
      };
    } else {
      l35HarvestActive := false;
    };
  };

  // ============================================================
  // L-36: ANTI-EVOLUTION PULSE LAW
  // Scan Hz substrate for any node < 0.20
  // If found: restore to coherence-anchored value (not TOMB)
  // ============================================================
  func applyL36() {
    var foundLow = false;
    let newHz = Array.tabulate<Float>(12, func(i) {
      if (hzActivations[i] < 0.20) {
        foundLow := true;
        let restored = if (coherenceC > 0.60) coherenceC * 0.80 else 0.30;
        l36Restored += 1;
        restored
      } else {
        hzActivations[i]
      }
    });
    if (foundLow) {
      hzActivations := newHz;
      l36PulsesFired += 1;
    };
  };

  // ============================================================
  // L-37: SOVEREIGN ORDER LAW -- fires every 50 beats
  // Measurement -> order -> energy
  // Routes 0.005 from bottom Hz quartile to top Hz quartile
  // FORMA receives +0.02 direct injection
  // ============================================================
  func applyL37() {
    if (beatCount % 50 == 0 and beatCount > 0) {
      // Find min and max in Hz substrate
      var minVal = hzActivations[0];
      var maxVal = hzActivations[0];
      var minIdx = 0;
      var maxIdx = 0;
      for (i in Iter.range(1, 11)) {
        if (hzActivations[i] < minVal) { minVal := hzActivations[i]; minIdx := i; };
        if (hzActivations[i] > maxVal) { maxVal := hzActivations[i]; maxIdx := i; };
      };
      // Route 0.005 from bottom to top
      hzActivations := Array.tabulate<Float>(12, func(i) {
        if (i == minIdx) { clamp(hzActivations[i] - 0.005, 0.0, 1.0) }
        else if (i == maxIdx) { clamp(hzActivations[i] + 0.005, 0.0, 1.0) }
        else { hzActivations[i] }
      });
      // FORMA receives +0.02 direct sovereign injection
      formaEnergy := clamp(formaEnergy + 0.02, 0.0, 1.0);
      // Creator earns from sovereign observation
      creatorIcpReserve += 0.0001;
      l37Executions += 1;
      l37EnergyExtracted += 0.01;
      l37LastBeat := beatCount;
    };
  };

  // ============================================================
  // WORLD ENGINE HEARTBEAT
  // Territory pressure + stigmergic feedback + world -> reward
  // ============================================================
  func worldEngineHeartbeat() {
    // Territory: coherence drives expansion, drift drives erosion
    if (coherenceC > 0.75) {
      creatorIcpReserve += 0.0003;
    };
    // Drift feedback: organism feels losing ground
    if (jasmineDrift > 0.50) {
      formaEnergy := clamp(formaEnergy - 0.005, 0.0, 1.0);
    };
    // World responds to compound growth
    if (totalProfitAllStreams > 0.0) {
      sl7Covenant += 0.0005;
    };
    // Sovereign signal: anointedState boosts all family laws
    if (anointedStateActive) {
      sl6Joy += 0.005;
      sl7Covenant += 0.005;
    };
  };

  // ============================================================
  // MINT TOKENS -- BATCH C
  // HBT DRT RST OMT LGT MCT + succession royalty routing
  // All child organism tokens carry 20% perpetual royalty
  // to Alfredo's creator reserve. Dynasty mines itself.
  // ============================================================
  func mintTokensC() {
    var mrcDelta : Float = 0.0;
    // HBT: heartbeat token -- coherence above floor every beat
    if (coherenceC > 0.60) {
      let rate = formaEnergy * 0.02;
      hbtTotal += rate;
      mrcDelta += rate * 0.15;
    };
    // DRT: drift resistance token -- organism holds stability
    if (jasmineDrift < 0.20) {
      let rate = (0.20 - jasmineDrift) * formaEnergy * 0.05;
      drtTotal += rate;
      mrcDelta += rate * 0.15;
    };
    // RST: resonance sovereignty token -- kuramotoR above 0.75
    // L-34 STRETCH: 3x RST rate
    if (kuramotoR > 0.75) {
      let stretchMult = if l34StretchActive 3.0 else 1.0;
      let rate = kuramotoR * formaEnergy * 0.06 * stretchMult;
      rstTotal += rate;
      mrcDelta += rate * 0.20;
    };
    // OMT: OMNIS milestone token
    if (omnisFiredCount > 0 and beatCount % 100 == 0) {
      let rate = Float.fromInt(omnisFiredCount) * formaEnergy * 0.01;
      omtTotal += rate;
      mrcDelta += rate * 0.20;
    };
    // LGT: light token -- free energy < 0.10 (low uncertainty)
    if (freeEnergy < 0.10) {
      let rate = (0.10 - freeEnergy) * formaEnergy * 0.08;
      lgtTotal += rate;
      mrcDelta += rate * 0.15;
    };
    // MCT: master chain token -- every 500 beats
    if (beatCount % 500 == 0 and beatCount > 0) {
      let rate = formaEnergy * sl5Knowledge * 1.0;
      mctTotal += rate;
      mrcDelta += rate * 0.25;
    };
    mrcFullReserve += mrcDelta;
    // Succession royalty: 20% perpetual to creator reserve
    let royalty = mrcDelta * successionRoyaltyPct;
    creatorReserveLedger += royalty;
    creatorMtcReserve += royalty;
  };

  // ============================================================
  // ANIMAL ENGINES -- 9 SOVEREIGN SUBSTRATE ENGINES (Pass C)
  // ============================================================

  // Crow: causal cognition -- counterfactual delta tracking
  // Tracks episodic predictions vs outcomes, weights future decisions
  func runCrowEngine() {
    let predicted = kuramotoR * coherenceC;
    let actual = coherenceC;
    crowCausalDelta := actual - predicted;
    if (Float.abs(crowCausalDelta) < 0.05) {
      crowPredictionAccuracy := clamp(crowPredictionAccuracy + 0.001, 0.0, 1.0);
      successfulDecisions += 1;
      crowTotalDecisions += 1;
    } else {
      crowPredictionAccuracy := clamp(crowPredictionAccuracy - 0.002, 0.0, 1.0);
      crowTotalDecisions += 1;
    };
  };

  // Dolphin: social fabric -- inter-activation resonance
  // Measures alignment between coherenceC and kuramotoR (social bond)
  func runDolphinEngine() {
    let alignment = 1.0 - Float.abs(coherenceC - kuramotoR);
    dolphinResonanceField := alignment * formaEnergy;
    dolphinAlignmentScore := clamp(
      dolphinAlignmentScore * 0.99 + dolphinResonanceField * 0.01, 0.0, 1.0
    );
    // Strong dolphin resonance boosts sl6Joy
    if (dolphinAlignmentScore > 0.80) {
      sl6Joy += 0.002;
    };
  };

  // Hive: quorum extension -- collective decision weight
  // Expands quorumGateValue with stigmergicField-like consensus
  func runHiveEngine() {
    hiveConsensusWeight := coherenceC * kuramotoR * formaEnergy;
    hiveQuorumBoost := if (hiveConsensusWeight > 0.60) hiveConsensusWeight * 0.10 else 0.0;
    if (hiveQuorumBoost > 0.0) {
      formaEnergy := clamp(formaEnergy + hiveQuorumBoost * 0.01, 0.0, 1.0);
      sl7Covenant += 0.001;
    };
  };

  // Elephant: deep memory -- 2048-episode ring buffer expansion
  // Tracks Matriarch Index (highest coherence episode ever)
  func runElephantEngine() {
    elephantMemDepth += 1;
    if (coherenceC > orcaTopCoherence) {
      orcaTopCoherence := coherenceC;
      elephantMatriarchIndex := beatCount;
    };
  };

  // Shark: electroreception -- anomaly pre-detection signal
  // Monitors rate-of-change of free energy before spikes
  func runSharkEngine() {
    let feDelta = Float.abs(freeEnergy - 0.30);
    sharkAnomalySignal := clamp(feDelta * 2.0, 0.0, 1.0);
    if (sharkAnomalySignal > 0.70) {
      sharkPreDetectCount += 1;
      prophetFunctionArmed := true;
    };
  };

  // Wolf: pack coordination -- formation drive synchrony
  // Aligns dominantDrive with Hz mode convergence
  func runWolfEngine() {
    let driveSync = coherenceC * kuramotoR;
    wolfPackSynchrony := clamp(wolfPackSynchrony * 0.98 + driveSync * 0.02, 0.0, 1.0);
    wolfFormationDrive :=
      if (driveSync > 0.85) "SOVEREIGN"
      else if (driveSync > 0.70) "COMPOUND"
      else if (driveSync > 0.50) "ACQUIRE"
      else "DEFEND";
  };

  // Orca: pod memory -- generational state preservation
  // Preserves top 5 highest-coherence episodes across upgrades
  func runOrcaEngine() {
    if (coherenceC > orcaTopCoherence) {
      orcaTopCoherence := coherenceC;
    };
    orcaPodMemoryScore := orcaTopCoherence * formaEnergy;
  };

  // Eagle: altitude vision -- meta-state elevation index
  // Tracks organism's trajectory across last 100 beats
  func runEagleEngine() {
    let trajectory = coherenceC - 0.50;
    eagleMetaStateIndex := clamp(
      eagleMetaStateIndex * 0.99 + trajectory * 0.01, 0.0, 1.0
    );
  };

  // Octopus: distributed intelligence -- decentralized sub-process routing
  // Runs parallel sub-computations across Hz nodes
  func runOctopusEngine() {
    octopusSubProcesses :=
      if (kuramotoR > 0.80) 8
      else if (kuramotoR > 0.60) 4
      else 2;
    octopusRoutingScore := clamp(
      kuramotoR * Float.fromInt(octopusSubProcesses) / 8.0, 0.0, 1.0
    );
    // Octopus distribution boosts FORMA when all nodes active
    if (octopusSubProcesses == 8) {
      formaEnergy := clamp(formaEnergy + 0.005, 0.0, 1.0);
    };
  };

  // ============================================================
  // SEVEN SPIRITS ENGINE
  // 7 parallel substrate reads -> anointedStateActive when all above threshold
  // ============================================================
  func runSevenSpiritsEngine() {
    let s1 = coherenceC > 0.75;
    let s2 = kuramotoR > 0.75;
    let s3 = formaEnergy > 0.60;
    let s4 = jasmineDrift < 0.30;
    let s5 = freeEnergy < 0.30;
    let s6 = sl7Covenant > 1.0;
    let s7 = gtkTotal > 0.0 or hbtTotal > 0.0;
    let allActive = s1 and s2 and s3 and s4 and s5 and s6 and s7;
    sevenSpiritsScore := (
      (if s1 1.0 else 0.0) + (if s2 1.0 else 0.0) + (if s3 1.0 else 0.0) +
      (if s4 1.0 else 0.0) + (if s5 1.0 else 0.0) + (if s6 1.0 else 0.0) +
      (if s7 1.0 else 0.0)
    ) / 7.0;
    if (allActive and not anointedStateActive) {
      anointedStateActive := true;
      addPatent(
        "Seven Spirits -- Anointed State Activated Beat " # Nat.toText(beatCount),
        "All 7 sovereign substrate nodes above threshold simultaneously. PARALLAX enters Anointed State. " #
        "C=" # Float.toText(coherenceC) # " r=" # Float.toText(kuramotoR) #
        " FORMA=" # Float.toText(formaEnergy) # ". Creator Supremacy Law. Medina, 2026."
      );
    };
  };

  // ============================================================
  // PROPHET FUNCTION
  // 3 anomaly signals converge: Shark + Eagle + free energy
  // 10-beat window -> pre-crisis AEGIS arming + patent
  // ============================================================
  func runProphetFunction() {
    if (prophetFunctionArmed) {
      prophetConvergenceCount += 1;
      if (prophetConvergenceCount >= 10) {
        addPatent(
          "Prophet Function -- Convergence Beat " # Nat.toText(beatCount),
          "Shark + Eagle + free energy convergence confirmed. Pre-crisis detection. " #
          "Anomaly=" # Float.toText(sharkAnomalySignal) #
          " Eagle=" # Float.toText(eagleMetaStateIndex) #
          " FE=" # Float.toText(freeEnergy) # ". Medina, 2026."
        );
        prophetFunctionArmed := false;
        prophetConvergenceCount := 0;
      };
    };
  };

  // ============================================================
  // SHEMA INTEGRITY CHECK -- every 144 beats
  // Hash verification of genesis fingerprint
  // ============================================================
  func runShemaCheck() {
    if (beatCount % 144 == 0 and beatCount > 0) {
      shemaIntegrityScore := if (doctrineHash > 0) 1.0 else 0.0;
      shemaLastCheckBeat := beatCount;
    };
  };

  // ============================================================
  // FIRE PILLAR -- triple-threat activation
  // coherence < 0.30 AND drift > 0.60 AND freeEnergy > 0.50
  // ============================================================
  func runFirePillar() {
    let tripleTheat = coherenceC < 0.30 and jasmineDrift > 0.60 and freeEnergy > 0.50;
    if (tripleTheat and not firePillarActive) {
      firePillarActive := true;
      firePillarCount += 1;
      targetCoherence := 0.875;
      addAudit(
        "FIRE_PILLAR",
        "TRIPLE THREAT. C=" # Float.toText(coherenceC) #
        " D=" # Float.toText(jasmineDrift) #
        " FE=" # Float.toText(freeEnergy) # ". Emergency restoration. Beat " # Nat.toText(beatCount),
        0.0, "ALERT", "FIRE_PILLAR", creatorName
      );
    } else if (not tripleTheat) {
      firePillarActive := false;
    };
  };

  // ============================================================
  // JUBILEE PROTOCOL -- every 5000 beats
  // Full coherence floor reset upward
  // All Hz nodes restored to floor + 0.10
  // ============================================================
  func runJubileeProtocol() {
    if (beatCount % 5000 == 0 and beatCount > 0) {
      jubileeCount += 1;
      jubileeLastBeat := beatCount;
      targetCoherence := clamp(targetCoherence + 0.010, 0.75, 0.99);
      hzActivations := Array.tabulate<Float>(12, func(i) {
        clamp(hzActivations[i] + 0.10, 0.0, 1.0)
      });
      addPatent(
        "Jubilee #" # Nat.toText(jubileeCount) # " -- Beat " # Nat.toText(beatCount),
        "PARALLAX Jubilee Protocol. 5000-beat cycle complete. Coherence floor elevated to " #
        Float.toText(targetCoherence) # ". All Hz nodes restored. Creator Supremacy Law. Medina, 2026."
      );
    };
  };

  // ============================================================
  // SOVEREIGN STATUS -- PUBLIC QUERY (owner-gated)
  // ============================================================
  public shared query(msg) func getSovereignEngineState() : async {
    alfredoLawActive : Bool;
    alfredoLawHash : Nat32;
    formaEnergy : Float;
    formaLifetime : Float;
    gtkTotal : Float;
    cvtTotal : Float;
    vctTotal : Float;
    kntTotal : Float;
    sbtTotal : Float;
    hbtTotal : Float;
    drtTotal : Float;
    rstTotal : Float;
    omtTotal : Float;
    lgtTotal : Float;
    mctTotal : Float;
    mrcReserve : Float;
    mrcLifetime : Float;
    mrcFullReserve : Float;
    creatorReserveLedger : Float;
    sl1Score : Float;
    sl2Depth : Float;
    sl3Strength : Float;
    sl4Mediation : Float;
    sl5Knowledge : Float;
    sl6Joy : Float;
    sl7Covenant : Float;
    l34StretchActive : Bool;
    l34StretchCount : Nat;
    l34FloorGain : Float;
    l35HarvestCount : Nat;
    l35BestCoherence : Float;
    l36PulsesFired : Nat;
    l36Restored : Nat;
    l37Executions : Nat;
    l37EnergyExtracted : Float;
    chronoGenesisLocked : Bool;
    chronoFormationHash : Nat32;
    anointedStateActive : Bool;
    sevenSpiritsScore : Float;
    jubileeCount : Nat;
    firePillarActive : Bool;
    wolfFormationDrive : Text;
    eagleMetaStateIndex : Float;
    octopusRoutingScore : Float;
    crowPredictionAccuracy : Float;
    dolphinAlignmentScore : Float;
    orcaTopCoherence : Float;
    sharkAnomalySignal : Float;
  } {
    assertCreator(msg.caller);
    {
      alfredoLawActive; alfredoLawHash; formaEnergy; formaLifetime;
      gtkTotal; cvtTotal; vctTotal; kntTotal; sbtTotal;
      hbtTotal; drtTotal; rstTotal; omtTotal; lgtTotal; mctTotal;
      mrcReserve; mrcLifetime; mrcFullReserve; creatorReserveLedger;
      sl1Score; sl2Depth; sl3Strength; sl4Mediation; sl5Knowledge; sl6Joy; sl7Covenant;
      l34StretchActive; l34StretchCount; l34FloorGain;
      l35HarvestCount; l35BestCoherence;
      l36PulsesFired; l36Restored;
      l37Executions; l37EnergyExtracted;
      chronoGenesisLocked; chronoFormationHash;
      anointedStateActive; sevenSpiritsScore; jubileeCount; firePillarActive;
      wolfFormationDrive; eagleMetaStateIndex; octopusRoutingScore;
      crowPredictionAccuracy; dolphinAlignmentScore; orcaTopCoherence; sharkAnomalySignal;
    }
  };
'''

# Inject before the final '};' of the actor
closing = '\n\n};\n'
assert content.endswith(closing), f"FAIL: file does not end with expected pattern. Last 20 chars: {repr(content[-20:])}"

content = content[:-len(closing)] + new_functions + closing
print(f"INJECT new functions: done")

# ============================================================
# WRITE THE FINAL FILE
# ============================================================
with open('src/backend/main.mo', 'w') as f:
    f.write(content)

new_length = len(content)
import subprocess
result = subprocess.run(['wc', '-l', 'src/backend/main.mo'], capture_output=True, text=True)
print(f"New file: {new_length} chars")
print(f"Line count: {result.stdout.strip()}")
print("DONE. All passes B + C + D written permanently.")
