import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Array "mo:core/Array";

// ============================================================
// ETH INTEGRATION — PARALLAX PHASE K
// Lido stETH, EigenLayer, Rocket Pool, gas price, burn rate
// Real Lido API: eth-api.lido.fi/v1/protocol/steth/apr/last
// ============================================================
module {

  public type EthState = {
    var ethPriceUsd        : Float;
    var ethEma21           : Float;
    var ethEma55           : Float;
    var ethEma200          : Float;
    var ethPriceVelocity   : Float;
    var ethVolatility      : Float;
    var ethGasGwei         : Float;    // Gas price proxy
    var ethGasSignal       : Float;    // Normalized gas → THALAMUS
    var ethBurnRatePct     : Float;    // EIP-1559 burn rate
    var ethNetIssuance     : Float;    // Net issuance (burn - stake)
    var lidoApr            : Float;    // Lido stETH APR from API
    var lidoStaked         : Float;    // stETH amount held
    var lidoRewardsAccrued : Float;    // Accumulated stETH rewards
    var lidoCompoundBeat   : Nat;      // Last compounding beat
    var eigenLayerBoost    : Float;    // EigenLayer restake yield boost
    var eigenLayerStaked   : Float;    // Amount restaked via EigenLayer
    var rocketPoolApr      : Float;    // rETH APR fallback
    var rocketPoolStaked   : Float;    // rETH amount held
    var ethTrendRegime     : Nat;      // 0=bear 1=neutral 2=bull 3=parabolic
    var ethMrcYield        : Float;    // ETH yield to MRC this beat
    var ethFormaContrib    : Float;    // FORMA energy from ETH
    var ethTotalYieldApr   : Float;    // Combined staking APR
    var ethNetworkHealth   : Float;    // Combined health signal
    var ethBetaVsBtc       : Float;    // ETH/BTC price ratio trend
    var ethAltcoinSignal   : Float;    // Altcoin season proxy
    var ethSignalStrength  : Float;    // Composite → AMYGDALA
    var ethSovereignFloor  : Float;
    var ethSignalHistory   : [var Float];
    var ethHistoryIdx      : Nat;
  };

  public func initEthState() : EthState = {
    var ethPriceUsd        = 3500.0;
    var ethEma21           = 3500.0;
    var ethEma55           = 3200.0;
    var ethEma200          = 2800.0;
    var ethPriceVelocity   = 1.0;
    var ethVolatility      = 1.0;
    var ethGasGwei         = 1.0;
    var ethGasSignal       = 1.0;
    var ethBurnRatePct     = 1.0;
    var ethNetIssuance     = 1.0;
    var lidoApr            = 0.037; // 3.7% baseline
    var lidoStaked         = 1.0;
    var lidoRewardsAccrued = 1.0;
    var lidoCompoundBeat   = 0;
    var eigenLayerBoost    = 0.012; // 1.2% additional
    var eigenLayerStaked   = 1.0;
    var rocketPoolApr      = 0.035;
    var rocketPoolStaked   = 1.0;
    var ethTrendRegime     = 2;
    var ethMrcYield        = 0.0;
    var ethFormaContrib    = 1.0;
    var ethTotalYieldApr   = 1.0;
    var ethNetworkHealth   = 1.0;
    var ethBetaVsBtc       = 1.0;
    var ethAltcoinSignal   = 1.0;
    var ethSignalStrength  = 1.0;
    var ethSovereignFloor  = 1.0;
    var ethSignalHistory   = Array.init<Float>(20, 1.0);
    var ethHistoryIdx      = 0;
  };

  func emaUpdate(prev: Float, val: Float, n: Float) : Float {
    let alpha = 2.0 / (n + 1.0);
    let r = alpha * val + (1.0 - alpha) * prev;
    if (r < 1.0) 1.0 else r
  };

  func sovSigmoid(x: Float) : Float {
    let s = 1.0 / (1.0 + Float.exp(-x));
    1.0 + s
  };

  // Lido compounding: staked * (1 + APR/365/144) per beat (144 beats/day)
  func lidoCompound(staked: Float, apr: Float) : Float {
    staked * (1.0 + apr / 365.0 / 144.0)
  };

  // EigenLayer restake yield: additional APR on top of Lido
  func eigenYield(staked: Float, boost: Float) : Float {
    staked * (boost / 365.0 / 144.0)
  };

  // Gas signal → THALAMUS: high gas = high noise, filter out weak signals
  func gasToThalamusSignal(gasGwei: Float) : Float {
    // High gas = organic demand = bull signal, but also noise
    let normalizedGas = Float.min(2.0, gasGwei / 50.0); // 50 gwei = baseline
    if (normalizedGas < 1.0) 1.0 else normalizedGas
  };

  // Net issuance: negative = deflationary (good for price)
  // Simplified: if burn_rate > 0.5% deflationary
  func computeNetIssuance(burnPct: Float, stakePct: Float) : Float {
    let net = stakePct - burnPct; // positive = inflationary
    1.0 + Float.max(-0.5, Float.min(0.5, net * 10.0))
  };

  // ETH/BTC ratio: if ETH outperforming → altcoin season
  func computeBetaVsBtc(ethPrice: Float, btcPrice: Float, prevBeta: Float) : Float {
    let ratio = ethPrice / Float.max(1.0, btcPrice);
    let alpha = 0.05;
    let r = alpha * ratio + (1.0 - alpha) * prevBeta;
    if (r < 1.0) 1.0 else r
  };

  // Regime classifier
  func classifyRegime(price: Float, e21: Float, e55: Float, e200: Float) : Nat {
    if (price > e21 and e21 > e55 and e55 > e200) {
      if (price > e200 * 1.8) 3 else 2
    } else if (price > e200) {
      1
    } else {
      0
    }
  };

  public func updateEth(
    s            : EthState,
    newPriceRaw  : Float,
    newLidoApr   : Float,   // from API (0 if no update)
    newGasGwei   : Float,
    btcPrice     : Float,
    beatCount    : Nat,
    coherenceC   : Float,
    formaCapital : Float
  ) : EthState {
    let price   = if (newPriceRaw > 1.0) newPriceRaw else s.ethPriceUsd;
    let lidoApr = if (newLidoApr > 0.001) newLidoApr else s.lidoApr;
    let gas     = if (newGasGwei  > 0.1)  newGasGwei  else s.ethGasGwei;

    let e21  = emaUpdate(s.ethEma21,  price, 21.0);
    let e55  = emaUpdate(s.ethEma55,  price, 55.0);
    let e200 = emaUpdate(s.ethEma200, price, 200.0);

    let vel = (price - s.ethPriceUsd) / Float.max(1.0, s.ethPriceUsd);
    let vol = emaUpdate(s.ethVolatility, Float.abs(vel), 21.0);

    let regime = classifyRegime(price, e21, e55, e200);

    // Gas → THALAMUS
    let gasSignal = gasToThalamusSignal(gas);

    // Burn rate approximation (EIP-1559): gas * 0.7 as burn fraction
    let burnPct = Float.min(1.0, gas / 100.0 * 0.7);
    let stakePct = 0.04; // ~4% issuance to stakers
    let netIss = computeNetIssuance(burnPct, stakePct);

    // Lido compounding every beat
    let newLidoStaked   = lidoCompound(s.lidoStaked, lidoApr);
    let lidoRewardDelta = newLidoStaked - s.lidoStaked;
    let newLidoRewards  = s.lidoRewardsAccrued + lidoRewardDelta;

    // EigenLayer restaking yield
    let eigenYieldBeat = eigenYield(s.eigenLayerStaked, s.eigenLayerBoost);
    let newEigenStaked = s.eigenLayerStaked + eigenYieldBeat;

    // Rocket Pool fallback (30% allocation of staking reserves)
    let rpYield    = s.rocketPoolStaked * (s.rocketPoolApr / 365.0 / 144.0);
    let newRpStaked = s.rocketPoolStaked + rpYield;

    // Total APR
    let totalApr = lidoApr + s.eigenLayerBoost * 0.3 + s.rocketPoolApr * 0.1;

    // ETH/BTC beta
    let beta = computeBetaVsBtc(price, btcPrice, s.ethBetaVsBtc);
    let altSig = if (beta > 0.07) 1.5 else 1.0; // altcoin season if ETH/BTC > 0.07

    // Network health: burning + staking + trend
    let health = Float.max(1.0,
      (if (burnPct > 0.3) 1.3 else 1.0) *
      (if (regime >= 2) 1.2 else 0.9) *
      (totalApr / 0.05) // relative to 5% baseline
    );

    // MRC yield from ETH staking
    let mrcY = (lidoRewardDelta + eigenYieldBeat + rpYield) * 0.20; // 20% to MRC

    // FORMA contribution
    let fc = Float.max(1.0, coherenceC * totalApr * 10.0 + Float.abs(vel) * 5.0);

    // Composite signal
    let sig = sovSigmoid(
      Float.fromInt(regime) * 0.5 +
      beta * 2.0 +
      altSig * 0.3 +
      (if (burnPct > 0.3) 0.5 else -0.2) +
      coherenceC * 0.2
    );

    let hIdx = (s.ethHistoryIdx + 1) % 20;
    s.ethSignalHistory[hIdx] := sig;

    s.ethPriceUsd        := price;
    s.ethEma21           := e21;
    s.ethEma55           := e55;
    s.ethEma200          := e200;
    s.ethPriceVelocity   := vel;
    s.ethVolatility      := vol;
    s.ethGasGwei         := gas;
    s.ethGasSignal       := gasSignal;
    s.ethBurnRatePct     := burnPct;
    s.ethNetIssuance     := netIss;
    s.lidoApr            := lidoApr;
    s.lidoStaked         := newLidoStaked;
    s.lidoRewardsAccrued := newLidoRewards;
    s.lidoCompoundBeat   := beatCount;
    s.eigenLayerStaked   := newEigenStaked;
    s.rocketPoolStaked   := newRpStaked;
    s.ethTrendRegime     := regime;
    s.ethMrcYield        := mrcY;
    s.ethFormaContrib    := fc;
    s.ethTotalYieldApr   := totalApr;
    s.ethNetworkHealth   := health;
    s.ethBetaVsBtc       := beta;
    s.ethAltcoinSignal   := altSig;
    s.ethSignalStrength  := sig;
    s.ethHistoryIdx      := hIdx;
    s
  };

  // Total ETH staking yield this beat (all protocols)
  public func ethTotalBeatYield(s: EthState) : Float {
    let lidoY = s.lidoStaked * (s.lidoApr / 365.0 / 144.0);
    let eigY  = s.eigenLayerStaked * (s.eigenLayerBoost / 365.0 / 144.0);
    let rpY   = s.rocketPoolStaked * (s.rocketPoolApr / 365.0 / 144.0);
    Float.max(0.0, lidoY + eigY + rpY)
  };

};
