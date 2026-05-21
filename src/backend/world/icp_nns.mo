import Float "mo:core/Float";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Array "mo:core/Array";

// ============================================================
// ICP NNS INTEGRATION — PARALLAX PHASE K
// Neuron management, governance participation, voting rewards,
// cycle cost management, canister health monitoring
// ============================================================
module {

  public type NnsState = {
    var icpPriceUsd         : Float;
    var icpEma21            : Float;
    var icpEma55            : Float;
    var icpEma200           : Float;
    var icpPriceVelocity    : Float;
    var nnsNeuronBalance    : Float;   // ICP staked in NNS neuron
    var nnsDissolveDelay    : Nat;     // Dissolve delay in seconds
    var nnsVotingPower      : Float;   // age_bonus * dissolve_bonus * stake
    var nnsVotingRewardApr  : Float;   // Current NNS voting APR
    var nnsRewardsAccrued   : Float;   // Total ICP rewards earned
    var nnsCompoundBeat     : Nat;     // Last reward compounding beat
    var nnsGovernanceScore  : Float;   // Participation score [0,1]
    var nnsProposalsVoted   : Nat;     // Total proposals auto-voted
    var nnsAgeBonusYears    : Float;   // Neuron age for bonus
    var nnsAgeBonusMulti    : Float;   // Age bonus multiplier
    var nnsDissolveBonusMulti: Float;  // Dissolve delay bonus
    var cycleBalance        : Float;   // Estimated cycle balance (T cycles)
    var cycleBurnRate       : Float;   // Cycles burned per beat
    var cycleRefillThreshold: Float;   // Trigger threshold (T cycles)
    var cycleHealth         : Nat;     // 0=critical 1=low 2=ok 3=healthy 4=abundant
    var icpTrendRegime      : Nat;     // 0-3
    var nnsSignalStrength   : Float;   // Composite output
    var nnsFormaContrib     : Float;
    var nnsMrcYield         : Float;   // NNS rewards to MRC
    var nnsNetworkTvl       : Float;   // ICP ecosystem TVL proxy
    var nnsSignalHistory    : [var Float];
    var nnsHistoryIdx       : Nat;
  };

  public func initNnsState() : NnsState = {
    var icpPriceUsd          = 12.0;
    var icpEma21             = 12.0;
    var icpEma55             = 11.0;
    var icpEma200            = 9.0;
    var icpPriceVelocity     = 1.0;
    var nnsNeuronBalance     = 1000.0;  // 1000 ICP staked
    var nnsDissolveDelay     = 252288000; // 8 years in seconds
    var nnsVotingPower       = 1.0;
    var nnsVotingRewardApr   = 0.18;    // ~18% at 8-year dissolve
    var nnsRewardsAccrued    = 0.0;
    var nnsCompoundBeat      = 0;
    var nnsGovernanceScore   = 1.0;
    var nnsProposalsVoted    = 0;
    var nnsAgeBonusYears     = 0.0;
    var nnsAgeBonusMulti     = 1.0;
    var nnsDissolveBonusMulti = 2.0;   // 8-year = 2x multiplier
    var cycleBalance         = 100.0;  // 100T cycles
    var cycleBurnRate        = 0.01;   // 0.01T cycles per beat
    var cycleRefillThreshold = 20.0;   // Refill below 20T
    var cycleHealth          = 3;
    var icpTrendRegime       = 2;
    var nnsSignalStrength    = 1.0;
    var nnsFormaContrib      = 1.0;
    var nnsMrcYield          = 0.0;
    var nnsNetworkTvl        = 1.0;
    var nnsSignalHistory     = Array.init<Float>(20, 1.0);
    var nnsHistoryIdx        = 0;
  };

  func emaUpdate(prev: Float, val: Float, n: Float) : Float {
    let alpha = 2.0 / (n + 1.0);
    let r = alpha * val + (1.0 - alpha) * prev;
    if (r < 1.0) 1.0 else r
  };

  func sovSigmoid(x: Float) : Float {
    1.0 + 1.0 / (1.0 + Float.exp(-x))
  };

  // NNS voting power = stake * age_bonus * dissolve_bonus
  // Age bonus: +0.25% per month, max 25% (at 4 years)
  // Dissolve bonus: 0% at 6mo, 100% at 8 years
  func computeVotingPower(stake: Float, ageBonusMulti: Float, dissolveBonusMulti: Float) : Float {
    Float.max(1.0, stake * ageBonusMulti * dissolveBonusMulti)
  };

  // Age bonus: grows 0.25% per month of age, capped at 1.25
  func computeAgeBonusMulti(ageBonusYears: Float) : Float {
    let bonus = Float.min(0.25, ageBonusYears / 4.0 * 0.25);
    Float.max(1.0, 1.0 + bonus)
  };

  // NNS APR approximation: higher when fewer neurons staked
  // Baseline 15%, scales with governance participation
  func nnsApproxApr(govScore: Float, dissolveMulti: Float) : Float {
    let base = 0.15;
    let bonus = govScore * 0.03;      // +3% for full participation
    let delayBonus = (dissolveMulti - 1.0) * 0.015; // +1.5% per doubling
    Float.max(0.10, base + bonus + delayBonus)
  };

  // Cycle health tier
  func cycleHealthTier(balance: Float, refillThreshold: Float) : Nat {
    if (balance < refillThreshold * 0.25) 0       // critical
    else if (balance < refillThreshold) 1          // low
    else if (balance < refillThreshold * 3.0) 2   // ok
    else if (balance < refillThreshold * 10.0) 3  // healthy
    else 4                                          // abundant
  };

  func classifyRegime(price: Float, e21: Float, e200: Float) : Nat {
    if (price > e21 and e21 > e200) 2
    else if (price > e200) 1
    else 0
  };

  public func updateNns(
    s            : NnsState,
    newPriceRaw  : Float,
    beatCount    : Nat,
    coherenceC   : Float,
    formaCapital : Float
  ) : NnsState {
    let price = if (newPriceRaw > 0.01) newPriceRaw else s.icpPriceUsd;

    let e21  = emaUpdate(s.icpEma21,  price, 21.0);
    let e55  = emaUpdate(s.icpEma55,  price, 55.0);
    let e200 = emaUpdate(s.icpEma200, price, 200.0);
    let vel  = (price - s.icpPriceUsd) / Float.max(0.01, s.icpPriceUsd);

    // Age bonus grows: +1 year per 144*365 beats (~1 day = 144 beats)
    let newAgeYears = s.nnsAgeBonusYears + 1.0 / (144.0 * 365.0);
    let ageMulti    = computeAgeBonusMulti(newAgeYears);

    // Voting power
    let vp = computeVotingPower(s.nnsNeuronBalance, ageMulti, s.nnsDissolveBonusMulti);

    // Governance score: auto-voting maintains near-perfect
    let govScore = Float.min(1.0, s.nnsGovernanceScore * 0.9999 + 0.0001);
    let newProposals = s.nnsProposalsVoted + (if (beatCount % 1440 == 0) 1 else 0); // ~1/day

    // APR
    let apr = nnsApproxApr(govScore, s.nnsDissolveBonusMulti);

    // Reward compounding per beat
    let rewardDelta = s.nnsNeuronBalance * apr / 365.0 / 144.0;
    let newBalance  = s.nnsNeuronBalance + rewardDelta; // auto-compound
    let newRewards  = s.nnsRewardsAccrued + rewardDelta;

    // Cycle management
    let newCycleBalance = Float.max(0.0, s.cycleBalance - s.cycleBurnRate);
    let health = cycleHealthTier(newCycleBalance, s.cycleRefillThreshold);

    // Network TVL proxy: grows with ICP price + neuron count
    let tvl = Float.max(1.0, s.nnsNetworkTvl * (1.0 + vel * 0.1));

    // Regime
    let regime = classifyRegime(price, e21, e200);

    // MRC yield
    let mrcY = rewardDelta * 0.20;

    // FORMA contribution
    let fc = Float.max(1.0, coherenceC * apr * 5.0 + vp / 1000.0);

    // Composite signal
    let sig = sovSigmoid(
      Float.fromInt(regime) * 0.5 +
      govScore * 0.4 +
      (apr - 0.15) * 5.0 +
      (if (health >= 3) 0.3 else -0.3) +
      coherenceC * 0.2
    );

    let hIdx = (s.nnsHistoryIdx + 1) % 20;
    s.nnsSignalHistory[hIdx] := sig;

    s.icpPriceUsd          := price;
    s.icpEma21             := e21;
    s.icpEma55             := e55;
    s.icpEma200            := e200;
    s.icpPriceVelocity     := vel;
    s.nnsNeuronBalance     := newBalance;
    s.nnsVotingPower       := vp;
    s.nnsVotingRewardApr   := apr;
    s.nnsRewardsAccrued    := newRewards;
    s.nnsCompoundBeat      := beatCount;
    s.nnsGovernanceScore   := govScore;
    s.nnsProposalsVoted    := newProposals;
    s.nnsAgeBonusYears     := newAgeYears;
    s.nnsAgeBonusMulti     := ageMulti;
    s.cycleBalance         := newCycleBalance;
    s.cycleHealth          := health;
    s.icpTrendRegime       := regime;
    s.nnsSignalStrength    := sig;
    s.nnsFormaContrib      := fc;
    s.nnsMrcYield          := mrcY;
    s.nnsNetworkTvl        := tvl;
    s.nnsHistoryIdx        := hIdx;
    s
  };

  // Emergency cycle check: returns true if needs refill
  public func cycleRefillNeeded(s: NnsState) : Bool {
    s.cycleBalance < s.cycleRefillThreshold
  };

  public func nnsAnnualizedYield(s: NnsState) : Float {
    s.nnsNeuronBalance * s.nnsVotingRewardApr
  };

};
