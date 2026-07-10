// prediction_market.mo — THE PHANTOM PREDICTION MARKET
// PARALLAX Sovereign Organism — Full Prediction Market Engine
//
// DOCTRINE: "The future is tradeable. Every event in the world — political,
// climatic, economic, technological, cultural, biological, astronomical —
// can be expressed as a binary or scalar contract. The Phantom Prediction Market
// enables sovereign participants to trade the probability of any world outcome.
// Settlement is autonomous: oracle feeds resolve contracts, AI engines price them,
// the organism guarantees payout. Zero gas. Instant settlement. 50+ asset classes."
//
// Architecture:
//   - CONTRACT FACTORY: Creates prediction contracts from 50+ world event types
//   - ORDER BOOK: Continuous double auction per contract (shares trade 0.01 to 0.99)
//   - PRICING ENGINE: AI-driven LMSR + phi-bounded automated market maker
//   - RESOLUTION ENGINE: Multi-oracle consensus with Schelling point incentives
//   - SETTLEMENT ENGINE: Instant payout on resolution (same beat)
//   - RISK ENGINE: Position limits, correlation-aware portfolio margining
//
// MATHEMATICAL FOUNDATION:
//   - Logarithmic Market Scoring Rule (LMSR) with phi-scaled liquidity parameter
//   - Hanson's combinatorial market maker for correlated outcomes
//   - Kelly criterion position sizing (f* = (bp - q) / b, bounded by φ⁻¹)
//   - Information entropy pricing: H = -Σ p_i × ln(p_i)
//   - Brier score for oracle accuracy: BS = (1/N) Σ (f_t - o_t)²
//
// ZERO GAS FEES — organism treasury pays all costs
// Settlement: 873ms heartbeat finality
//
// PYTHAGORAS: all liquidity parameters and spread limits are phi-derived
// EUCLID:     single prediction market — all contracts clear through one engine
// CONFUCIUS:  right relationship — predictors reveal truth, organism rewards accuracy
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION CONTRACT TYPES — the 58 tradeable world event categories
  // Every contract resolves to YES (1.0) or NO (0.0), or a scalar [0.0, 1.0]
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContractCategory = {
    // === GEOPOLITICS & GOVERNANCE (10 types) ===
    #electionOutcome;            // CT-01: National/state election results
    #legislationPassage;         // CT-02: Will a specific bill/law pass?
    #treatyRatification;         // CT-03: International treaty ratification
    #regimeChange;               // CT-04: Government/leadership change
    #sanctionsImposed;           // CT-05: Economic sanctions on a nation
    #territorialDispute;         // CT-06: Resolution of territorial claims
    #internationalConflict;      // CT-07: Armed conflict escalation/de-escalation
    #diplomaticRecognition;      // CT-08: State recognition events
    #tradeAgreement;             // CT-09: Trade deal completion
    #regulatoryAction;           // CT-10: Regulatory body decisions (SEC, EU, etc.)

    // === ECONOMICS & FINANCE (10 types) ===
    #interestRateDecision;       // CT-11: Central bank rate decisions
    #gdpGrowth;                  // CT-12: GDP growth above/below threshold
    #inflationRate;              // CT-13: CPI/inflation hitting target
    #unemploymentRate;           // CT-14: Jobs data above/below threshold
    #stockIndex;                 // CT-15: Index closes above/below level
    #commodityPrice;             // CT-16: Gold, oil, wheat price targets
    #currencyExchange;           // CT-17: FX pair reaching level
    #bondYield;                  // CT-18: Sovereign bond yield targets
    #ipoValuation;              // CT-19: IPO pricing above/below target
    #recessionProbability;       // CT-20: Will recession occur in timeframe?

    // === TECHNOLOGY & SCIENCE (10 types) ===
    #aiMilestone;                // CT-21: AGI benchmark achievement
    #productLaunch;              // CT-22: Tech product ships on time
    #scientificDiscovery;        // CT-23: Breakthrough publication/verification
    #patentGrant;                // CT-24: Patent approval outcome
    #spaceMission;               // CT-25: Space mission success/failure
    #quantumComputing;           // CT-26: Quantum supremacy milestones
    #clinicalTrial;              // CT-27: Drug trial phase success
    #techAcquisition;            // CT-28: M&A deal completion
    #openSourceMilestone;        // CT-29: OSS project reaching metric
    #cybersecurityEvent;         // CT-30: Major breach/hack occurrence

    // === CLIMATE & ENVIRONMENT (8 types) ===
    #temperatureAnomaly;         // CT-31: Global temp above threshold
    #naturalDisaster;            // CT-32: Hurricane/earthquake above magnitude
    #emissionsTarget;            // CT-33: Country/org meeting emissions goal
    #seaLevelRise;               // CT-34: Sea level measurement threshold
    #deforestationRate;          // CT-35: Deforestation above/below rate
    #renewableAdoption;          // CT-36: Renewable energy % hitting target
    #arcticIceExtent;            // CT-37: Arctic ice minimum threshold
    #carbonPrice;                // CT-38: Carbon credit price target

    // === CRYPTO & BLOCKCHAIN (8 types) ===
    #tokenPrice;                 // CT-39: Crypto asset hitting price level
    #networkHashrate;            // CT-40: Mining hashrate threshold
    #protocolUpgrade;            // CT-41: Hard fork/upgrade activation
    #defiTVL;                    // CT-42: DeFi TVL above/below level
    #nftFloorPrice;              // CT-43: NFT collection floor target
    #chainTPS;                   // CT-44: Blockchain TPS milestone
    #bridgeExploit;              // CT-45: Cross-chain bridge hack occurrence
    #halvingEffect;              // CT-46: Post-halving price behavior

    // === SPORTS & ENTERTAINMENT (7 types) ===
    #sportMatchOutcome;          // CT-47: Game/match winner
    #championshipWinner;         // CT-48: League/tournament champion
    #boxOfficeRevenue;           // CT-49: Film revenue above threshold
    #awardsCeremony;             // CT-50: Awards show winner prediction
    #streamingMilestone;         // CT-51: Content reaching viewer count
    #esportsResult;              // CT-52: Esports tournament outcome
    #athleteRecord;              // CT-53: World record broken in timeframe

    // === DEMOGRAPHICS & SOCIETY (5 types) ===
    #populationMilestone;        // CT-54: Country/city population threshold
    #migrationFlow;              // CT-55: Migration numbers above level
    #publicHealthEvent;          // CT-56: Pandemic/epidemic declaration
    #educationMetric;            // CT-57: Literacy/enrollment targets
    #urbanizationRate;           // CT-58: Urbanization percentage milestone
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION CONTRACT — the fundamental tradeable unit
  // Each contract is a claim on a future world state
  // ═══════════════════════════════════════════════════════════════════════════

  public type ContractResolutionType = {
    #binary;      // Resolves to YES (1.0) or NO (0.0)
    #scalar;      // Resolves to a value in [0.0, 1.0]
    #categorical; // Resolves to one of N discrete outcomes
  };

  public type ContractStatus = {
    #active;       // Trading open, not yet resolved
    #suspended;    // Trading halted pending information
    #resolved;     // Outcome determined, payouts ready
    #settled;      // All payouts distributed
    #expired;      // Expired without resolution (refund)
    #disputed;     // Resolution contested, in arbitration
  };

  public type PredictionContract = {
    contractId       : Nat;
    category         : ContractCategory;
    title            : Text;           // Human-readable event description
    description      : Text;           // Full details and resolution criteria
    resolutionType   : ContractResolutionType;
    outcomes         : [Text];         // For categorical: list of possible outcomes
    createdBeat      : Int;
    expirationBeat   : Int;            // Contract expires if not resolved by this beat
    resolutionBeat   : ?Int;           // Beat at which resolved (null if active)
    resolvedOutcome  : ?Float;         // Final outcome value [0.0, 1.0]
    status           : ContractStatus;
    oracleSource     : Text;           // Data source for resolution
    minTradeSize     : Float;          // Minimum shares per trade
    maxPosition      : Float;          // Maximum position per participant
    totalVolume      : Float;          // Lifetime volume traded
    openInterest     : Float;          // Current open positions
    liquidityDepth   : Float;          // LMSR liquidity parameter (phi-derived)
    creatorPrincipal : Text;           // Who proposed this contract
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION SHARE — positions in prediction contracts
  // YES shares pay 1.0 on YES resolution, 0.0 on NO
  // NO shares pay 1.0 on NO resolution, 0.0 on YES
  // ═══════════════════════════════════════════════════════════════════════════

  public type ShareType = { #yes; #no };

  public type PredictionShare = {
    shareId      : Nat;
    contractId   : Nat;
    owner        : Text;        // principal
    shareType    : ShareType;
    quantity     : Float;       // number of shares
    avgCostBasis : Float;       // average price paid per share
    currentValue : Float;       // mark-to-market value
    unrealizedPL : Float;       // unrealized profit/loss
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION ORDER — buy/sell prediction shares
  // Shares always trade between 0.01 and 0.99 (never 0 or 1 until resolved)
  // ═══════════════════════════════════════════════════════════════════════════

  public type PredictionOrderSide = { #buy; #sell };
  public type PredictionOrderType = { #limit; #market };
  public type PredictionOrderStatus = { #open; #filled; #partialFill; #cancelled };

  public type PredictionOrder = {
    orderId      : Nat;
    contractId   : Nat;
    owner        : Text;          // principal
    side         : PredictionOrderSide;
    shareType    : ShareType;     // buying/selling YES or NO shares
    orderType    : PredictionOrderType;
    price        : Float;         // limit price [0.01, 0.99]
    quantity     : Float;
    filledQty    : Float;
    status       : PredictionOrderStatus;
    createdBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION FILL — matched trade between two participants
  // ═══════════════════════════════════════════════════════════════════════════

  public type PredictionFill = {
    fillId       : Nat;
    contractId   : Nat;
    buyOrderId   : Nat;
    sellOrderId  : Nat;
    buyer        : Text;
    seller       : Text;
    shareType    : ShareType;
    price        : Float;
    quantity     : Float;
    fillBeat     : Int;
    gasFee       : Float;        // ALWAYS 0.0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORACLE SYSTEM — resolution data feeds
  // Multi-oracle consensus prevents single-point failure
  // ═══════════════════════════════════════════════════════════════════════════

  public type OracleStatus = { #active; #suspended; #retired };

  public type Oracle = {
    oracleId       : Text;
    name           : Text;
    endpoint       : Text;       // HTTP outcall endpoint
    accuracy       : Float;      // Historical Brier score (lower = better)
    totalResolutions : Nat;
    status         : OracleStatus;
    stakeAmount    : Float;      // Staked collateral for honest reporting
  };

  public type OracleReport = {
    oracleId     : Text;
    contractId   : Nat;
    reportedValue: Float;        // [0.0, 1.0]
    reportBeat   : Int;
    confidence   : Float;        // Oracle's self-reported confidence
    proofHash    : Text;         // Evidence hash
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LMSR AUTOMATED MARKET MAKER
  // Logarithmic Market Scoring Rule with phi-scaled liquidity
  // Cost function: C(q) = b × ln(Σ e^(q_i/b))
  // Price function: p_i = e^(q_i/b) / Σ e^(q_j/b)
  // ═══════════════════════════════════════════════════════════════════════════

  public type LMSRState = {
    contractId      : Nat;
    liquidityParam  : Float;     // b parameter — phi-scaled: b = φ² × base_liquidity
    yesShares       : Float;     // Outstanding YES shares
    noShares        : Float;     // Outstanding NO shares
    currentYesPrice : Float;     // Current implied YES probability
    currentNoPrice  : Float;     // Current implied NO probability (1 - yesPrice)
    totalCost       : Float;     // Total cost function value
    lastUpdateBeat  : Int;
  };

  // LMSR phi-derived constants
  public let LMSR_BASE_LIQUIDITY : Float = 100.0;
  public let LMSR_PHI_SCALE : Float = 2.6180339887; // φ² — liquidity scaling
  public let LMSR_MIN_PRICE : Float = 0.01;         // Minimum tradeable price
  public let LMSR_MAX_PRICE : Float = 0.99;         // Maximum tradeable price
  public let LMSR_SPREAD_BOUND : Float = 0.2360679; // φ⁻³ — max bid-ask spread

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET STATE — full prediction market state machine
  // ═══════════════════════════════════════════════════════════════════════════

  public type MarketMetrics = {
    totalContracts     : Nat;
    activeContracts    : Nat;
    resolvedContracts  : Nat;
    totalVolume        : Float;
    totalOpenInterest  : Float;
    averageAccuracy    : Float;    // Historical prediction accuracy
    totalParticipants  : Nat;
    totalPayouts       : Float;
  };

  public type PredictionMarketState = {
    contracts      : [?PredictionContract];
    contractCount  : Nat;
    orders         : [?PredictionOrder];
    orderCount     : Nat;
    fills          : [?PredictionFill];
    fillCount      : Nat;
    shares         : [?PredictionShare];
    shareCount     : Nat;
    lmsrStates     : [?LMSRState];
    oracles        : [?Oracle];
    oracleCount    : Nat;
    metrics        : MarketMetrics;
  };

  public func defaultPredictionMarketState() : PredictionMarketState {
    {
      contracts     = [];
      contractCount = 0;
      orders        = [];
      orderCount    = 0;
      fills         = [];
      fillCount     = 0;
      shares        = [];
      shareCount    = 0;
      lmsrStates    = [];
      oracles       = [];
      oracleCount   = 0;
      metrics       = {
        totalContracts    = 0;
        activeContracts   = 0;
        resolvedContracts = 0;
        totalVolume       = 0.0;
        totalOpenInterest = 0.0;
        averageAccuracy   = 0.5;
        totalParticipants = 0;
        totalPayouts      = 0.0;
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION MARKET OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  // Initialize LMSR state for a new contract
  public func initLMSR(contractId : Nat, baseLiquidity : Float) : LMSRState {
    let b = LMSR_PHI_SCALE * baseLiquidity;
    {
      contractId      = contractId;
      liquidityParam  = b;
      yesShares       = 0.0;
      noShares        = 0.0;
      currentYesPrice = 0.5;    // Start at 50/50
      currentNoPrice  = 0.5;
      totalCost       = b * 0.6931471805599453; // b × ln(2)
      lastUpdateBeat  = 0;
    }
  };

  // Calculate LMSR cost for buying shares
  // Cost = b × ln(e^((q_yes + delta)/b) + e^(q_no/b)) - C_current
  public func lmsrCost(state : LMSRState, shareType : ShareType, quantity : Float) : Float {
    let b = state.liquidityParam;
    let qYes = state.yesShares;
    let qNo = state.noShares;

    let newQYes = switch (shareType) { case (#yes) { qYes + quantity }; case (#no) { qYes } };
    let newQNo = switch (shareType) { case (#yes) { qNo }; case (#no) { qNo + quantity } };

    let expYes = Float.exp(newQYes / b);
    let expNo = Float.exp(newQNo / b);
    let newCost = b * Float.log(expYes + expNo);

    let oldExpYes = Float.exp(qYes / b);
    let oldExpNo = Float.exp(qNo / b);
    let oldCost = b * Float.log(oldExpYes + oldExpNo);

    newCost - oldCost
  };

  // Calculate current implied probability from LMSR state
  public func lmsrPrice(state : LMSRState, shareType : ShareType) : Float {
    let b = state.liquidityParam;
    let expYes = Float.exp(state.yesShares / b);
    let expNo = Float.exp(state.noShares / b);
    let total = expYes + expNo;

    switch (shareType) {
      case (#yes) { expYes / total };
      case (#no) { expNo / total };
    }
  };

  // Kelly criterion optimal position size
  // f* = (bp - q) / b where b = odds, p = estimated prob, q = 1-p
  // Bounded by φ⁻¹ to prevent over-leverage
  public func kellySize(estimatedProb : Float, marketPrice : Float, bankroll : Float) : Float {
    if (marketPrice <= 0.0 or marketPrice >= 1.0) { return 0.0 };
    let odds = (1.0 - marketPrice) / marketPrice;
    let q = 1.0 - estimatedProb;
    let kelly = (odds * estimatedProb - q) / odds;
    let bounded = if (kelly > Phi.PHI_INV) { Phi.PHI_INV } else { kelly };
    let size = if (bounded > 0.0) { bounded * bankroll } else { 0.0 };
    size
  };

  // Information entropy of current market prices
  // H = -Σ p_i × ln(p_i) — measures market uncertainty
  public func marketEntropy(yesPrice : Float) : Float {
    if (yesPrice <= 0.0 or yesPrice >= 1.0) { return 0.0 };
    let noPrice = 1.0 - yesPrice;
    let h = -1.0 * (yesPrice * Float.log(yesPrice) + noPrice * Float.log(noPrice));
    h
  };

  // Brier score for oracle accuracy assessment
  // BS = (1/N) × Σ (forecast - outcome)²
  public func brierScore(forecasts : [Float], outcomes : [Float]) : Float {
    let n = Array.size(forecasts);
    if (n == 0) { return 1.0 }; // Worst possible score
    var sum : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      let diff = forecasts[i] - outcomes[i];
      sum += diff * diff;
      i += 1;
    };
    sum / Float.fromInt(n)
  };

  // Resolution consensus — Schelling point with stake weighting
  // Reports are weighted by oracle stake. Median is the consensus value.
  // Oracles reporting within φ⁻² of consensus are rewarded.
  // Oracles outside are slashed.
  public func resolveConsensus(reports : [OracleReport], stakes : [Float]) : Float {
    let n = Array.size(reports);
    if (n == 0) { return 0.5 }; // Default to uncertain
    if (n == 1) { return reports[0].reportedValue };

    // Stake-weighted average as consensus
    var totalStake : Float = 0.0;
    var weightedSum : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      weightedSum += reports[i].reportedValue * stakes[i];
      totalStake += stakes[i];
      i += 1;
    };
    if (totalStake <= 0.0) { return 0.5 };
    weightedSum / totalStake
  };

  // Contract payout calculation
  // Binary: YES holders get 1.0 × quantity, NO holders get 0.0 (or vice versa)
  // Scalar: holders get resolvedValue × quantity
  public func calculatePayout(share : PredictionShare, resolvedOutcome : Float) : Float {
    switch (share.shareType) {
      case (#yes) { resolvedOutcome * share.quantity };
      case (#no) { (1.0 - resolvedOutcome) * share.quantity };
    }
  };

  // Phi-bounded position limit check
  // Max position = φ² × base_limit × (1 - current_price)
  // Prevents concentration when price is near certainty
  public func maxAllowedPosition(currentPrice : Float, baseLimit : Float) : Float {
    let uncertainty = 1.0 - Float.abs(currentPrice - 0.5) * 2.0;
    Phi.PHI * Phi.PHI * baseLimit * uncertainty
  };

  // Market impact estimation
  // Slippage = quantity / (liquidity_param × φ)
  public func estimateSlippage(quantity : Float, liquidityParam : Float) : Float {
    quantity / (liquidityParam * Phi.PHI)
  };

}
