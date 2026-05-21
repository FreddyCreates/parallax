import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

// PARALLAX — FORMA Compounding Currency + 12-Token Economy
module {

  // Compound FORMA capital each beat
  public func compoundForma(
    capital    : Float,
    thyroid    : Float,
    t3         : Float,
    dilation   : Float,
    jacobMult  : Float
  ) : Float {
    let rate = Float.max(1.0, thyroid) * Float.max(1.0, t3) * Float.max(1.0, dilation) * Float.max(1.0, jacobMult) * 0.00001;
    Float.max(1000.0, capital + capital * rate)
  };

  // 4-Level Mining Engine
  public func miningL1(capital : Float, _beats : Nat) : Float {
    capital * 0.000001
  };

  public func miningL2(l1 : Float, dopamine : Float, coherence : Float) : Float {
    l1 * Float.max(0.1, dopamine) * (1.0 + Float.max(1.0, coherence) * 0.1)
  };

  public func miningL3(l2 : Float, jacobMult : Float, resonex : Float) : Float {
    l2 * Float.max(1.0, jacobMult) * Float.max(1.0, resonex)
  };

  public func miningL4(l3 : Float, testosterone : Float, territory : Float) : Float {
    l3 * Float.max(0.1, testosterone) * (1.0 + Float.max(0.0, territory) * 0.01)
  };

  // Determine if minting is allowed
  public func shouldMint(capital : Float, threshold : Float, aresArmed : Bool) : Bool {
    capital > threshold and not aresArmed
  };

  public type MintCondState = {
    coherence           : Float;
    sacesiTarget        : Float;
    eagleSignal         : Float;
    regime              : Text;
    patentCount         : Nat;
    compliance          : Float;
    shellHeritageCoh    : Float;
    consecutiveDrive    : Nat;
    allShellRAbove08    : Bool;
    beat                : Nat;
    jacobRung           : Nat;
    capital             : Float;
  };

  // Returns 12 booleans: [MTH, MRC, GTK, CVT, VCT, KNT, SBT, HBT, DRT, RST, OMT, LGT]
  public func checkMintConditions(s : MintCondState) : [Bool] {
    let genesisState = s.coherence * s.compliance > s.sacesiTarget * 1.618033988749895;
    let bullAndEagle = s.eagleSignal > 3.0 and s.regime == "BULL";
    let patentMilestone = s.patentCount > 0 and s.patentCount % 10 == 0;
    [
      false,             // MTH: genesis only, never auto-minted
      s.compliance >= 0.9 and s.capital > 10000.0,  // MRC
      genesisState,      // GTK
      false,             // CVT: caller checks sacesiExceededBeats
      bullAndEagle,      // VCT
      patentMilestone,   // KNT
      s.compliance >= 1.0,                           // SBT
      s.shellHeritageCoh > 2.5,                      // HBT
      s.consecutiveDrive >= 50,                      // DRT
      s.allShellRAbove08,                            // RST
      false,             // OMT: caller checks beat milestones
      false              // LGT: caller checks rung advancement
    ]
  };

};
