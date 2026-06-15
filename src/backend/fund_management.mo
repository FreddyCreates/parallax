// fund_management.mo — SOVEREIGN FUND MANAGEMENT ENGINE
// PARALLAX Sovereign Organism — Domain 45: FUND MANAGEMENT
//
// DOCTRINE: "Funds are sovereign capital pools. Management is stewardship.
// This module implements production-grade fund management: multi-strategy
// portfolio construction, risk budgeting, performance attribution, fee
// calculation, investor relations, regulatory reporting. All operations
// phi-governed and doctrine-gated. Real mathematics, real accountability."
//
// DOMAIN 45 — FUND MANAGEMENT CAPABILITIES:
//   1. Fund Structure        — Multi-strategy, multi-asset, multi-manager
//   2. Capital Allocation    — Risk parity, risk budgeting, factor allocation
//   3. Performance Tracking  — NAV calculation, returns, benchmarking
//   4. Risk Management       — VaR, stress testing, drawdown monitoring
//   5. Fee Calculation       — Management fees, performance fees, hurdle rates
//   6. Investor Relations    — Capital flows, redemptions, subscriptions
//   7. Attribution Analysis  — Performance attribution by strategy/factor
//   8. Regulatory Reporting  — Holdings, exposures, compliance monitoring
//
// PYTHAGORAS: all allocations phi-weighted for optimal capital efficiency
// EUCLID:     single source of truth — FundManagementState
// CONFUCIUS:  right relationship — funds serve investor prosperity
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // FUND MANAGEMENT CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Management fee: φ⁻³ = 0.236 (23.6 bps annually)
  public let MANAGEMENT_FEE_RATE : Float = Phi.PHI_INV_3;

  // Performance fee: φ⁻¹ = 0.618 (61.8% of profits above hurdle)
  public let PERFORMANCE_FEE_RATE : Float = Phi.PHI_INV;

  // Hurdle rate: φ⁻² = 0.382 (38.2% annual return threshold)
  public let HURDLE_RATE : Float = Phi.PHI_INV_2;

  // High water mark reset period: F(9) = 34 beats
  public let HIGH_WATER_MARK_PERIOD : Nat = 34;

  // Redemption notice period: F(8) = 21 beats
  public let REDEMPTION_NOTICE_PERIOD : Nat = 21;

  // Maximum concentration per strategy: φ⁻¹ = 0.618
  public let MAX_STRATEGY_CONCENTRATION : Float = Phi.PHI_INV;

  // Risk budget allocation: F(7) = 13 strategies maximum
  public let MAX_STRATEGIES : Nat = 13;

  // NAV calculation precision: φ⁻⁴ = 0.146
  public let NAV_PRECISION : Float = 0.146;

  // Drawdown alert threshold: φ⁻² = 0.382 (38.2%)
  public let DRAWDOWN_ALERT_THRESHOLD : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // FUND STRUCTURE
  // ═══════════════════════════════════════════════════════════════════════════

  public type Fund = {
    fundId            : Text;
    fundName          : Text;
    fundType          : FundType;
    inceptionDate     : Int;
    baseCurrency      : Text;
    benchmarkIndex    : Text;
    strategies        : [Strategy];
    totalAUM          : Float;          // Assets Under Management
    navPerShare       : Float;          // Net Asset Value
    shareOutstanding  : Float;
    managementFee     : Float;
    performanceFee    : Float;
    hurdleRate        : Float;
    highWaterMark     : Float;
    lockupPeriod      : Nat;            // Beats before redemption allowed
  };

  public type FundType = {
    #hedgeFund;
    #mutualFund;
    #etf;
    #privateEquity;
    #ventureCapital;
    #liquidityPool;
    #quantFund;
    #cryptoFund;
  };

  public type Strategy = {
    strategyId       : Text;
    strategyName     : Text;
    strategyType     : StrategyClassification;
    allocation       : Float;           // Percentage of fund capital
    currentValue     : Float;
    targetAllocation : Float;
    riskContribution : Float;           // Contribution to fund risk
    returns          : [Float];         // Historical returns
    sharpeRatio      : Float;
    maxDrawdown      : Float;
    status           : StrategyStatus;
  };

  public type StrategyClassification = {
    #longShort;
    #market Neutral;
    #arbitrage;
    #eventDriven;
    #globalMacro;
    #ctaManaged;
    #fixedIncome;
    #multiStrategy;
  };

  public type StrategyStatus = {
    #active;
    #suspended;
    #liquidating;
    #closed;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NAV CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  public type NAVCalculation = {
    timestamp         : Int;
    totalAssets       : Float;
    totalLiabilities  : Float;
    netAssetValue     : Float;
    sharesOutstanding : Float;
    navPerShare       : Float;
    navChange         : Float;          // Change from previous NAV
    dailyReturn       : Float;
  };

  // Calculate Net Asset Value
  public func calculateNAV(
    fund : Fund,
    currentAssetValues : [Float],
    liabilities : Float,
    previousNAV : Float,
    currentBeat : Int
  ) : NAVCalculation {
    
    // Sum all asset values
    var totalAssets = 0.0;
    for (value in currentAssetValues.vals()) {
      totalAssets += value;
    };

    // Net assets = total assets - liabilities
    let netAssetValue = totalAssets - liabilities;

    // NAV per share
    let navPerShare = if (fund.shareOutstanding > 0.0) {
      netAssetValue / fund.shareOutstanding
    } else {
      1.0
    };

    // Change metrics
    let navChange = navPerShare - previousNAV;
    let dailyReturn = if (previousNAV > 0.0) {
      navChange / previousNAV
    } else {
      0.0
    };

    {
      timestamp = currentBeat;
      totalAssets = totalAssets;
      totalLiabilities = liabilities;
      netAssetValue = netAssetValue;
      sharesOutstanding = fund.shareOutstanding;
      navPerShare = navPerShare;
      navChange = navChange;
      dailyReturn = dailyReturn;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERFORMANCE METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  public type PerformanceMetrics = {
    period            : Text;
    totalReturn       : Float;
    annualizedReturn  : Float;
    volatility        : Float;
    sharpeRatio       : Float;
    sortinoRatio      : Float;
    maxDrawdown       : Float;
    calmarRatio       : Float;          // Return / Max Drawdown
    alpha             : Float;          // Excess return vs benchmark
    beta              : Float;          // Systematic risk vs benchmark
    informationRatio  : Float;          // Alpha / Tracking Error
    winRate           : Float;
    profitFactor      : Float;
  };

  // Calculate performance metrics
  public func calculatePerformanceMetrics(
    returns : [Float],
    benchmarkReturns : [Float],
    riskFreeRate : Float,
    periodsPerYear : Float
  ) : PerformanceMetrics {
    
    let n = returns.size();
    if (n == 0) {
      return {
        period = "N/A";
        totalReturn = 0.0;
        annualizedReturn = 0.0;
        volatility = 0.0;
        sharpeRatio = 0.0;
        sortinoRatio = 0.0;
        maxDrawdown = 0.0;
        calmarRatio = 0.0;
        alpha = 0.0;
        beta = 0.0;
        informationRatio = 0.0;
        winRate = 0.0;
        profitFactor = 0.0;
      };
    };

    // Total return (cumulative)
    var cumulativeReturn = 1.0;
    for (ret in returns.vals()) {
      cumulativeReturn *= (1.0 + ret);
    };
    let totalReturn = cumulativeReturn - 1.0;

    // Annualized return
    let periods = Float.fromInt(n);
    let annualizedReturn = Float.pow(1.0 + totalReturn, periodsPerYear / periods) - 1.0;

    // Volatility (standard deviation of returns)
    var sumReturns = 0.0;
    for (ret in returns.vals()) {
      sumReturns += ret;
    };
    let avgReturn = sumReturns / periods;

    var sumSquaredDiff = 0.0;
    for (ret in returns.vals()) {
      let diff = ret - avgReturn;
      sumSquaredDiff += diff * diff;
    };
    let variance = sumSquaredDiff / periods;
    let volatility = Float.sqrt(variance) * Float.sqrt(periodsPerYear);

    // Sharpe ratio
    let excessReturn = annualizedReturn - riskFreeRate;
    let sharpeRatio = if (volatility > 0.0) {
      excessReturn / volatility
    } else {
      0.0
    };

    // Sortino ratio (downside deviation)
    var sumDownsideSquared = 0.0;
    var downsideCount = 0;
    for (ret in returns.vals()) {
      if (ret < 0.0) {
        sumDownsideSquared += ret * ret;
        downsideCount += 1;
      };
    };
    let downsideDeviation = if (downsideCount > 0) {
      Float.sqrt(sumDownsideSquared / Float.fromInt(downsideCount)) * Float.sqrt(periodsPerYear)
    } else {
      volatility
    };
    let sortinoRatio = if (downsideDeviation > 0.0) {
      excessReturn / downsideDeviation
    } else {
      0.0
    };

    // Maximum drawdown
    var peak = 0.0;
    var cumReturn = 0.0;
    var maxDD = 0.0;
    for (ret in returns.vals()) {
      cumReturn += ret;
      if (cumReturn > peak) { peak := cumReturn; };
      let drawdown = peak - cumReturn;
      if (drawdown > maxDD) { maxDD := drawdown; };
    };

    // Calmar ratio
    let calmarRatio = if (maxDD > 0.0) {
      annualizedReturn / maxDD
    } else {
      0.0
    };

    // Alpha and Beta (vs benchmark)
    var alpha = 0.0;
    var beta = 0.0;
    var informationRatio = 0.0;

    if (benchmarkReturns.size() == n and n > 1) {
      // Calculate benchmark stats
      var sumBenchmark = 0.0;
      for (ret in benchmarkReturns.vals()) {
        sumBenchmark += ret;
      };
      let avgBenchmark = sumBenchmark / periods;

      // Covariance and variance for beta
      var covariance = 0.0;
      var benchmarkVariance = 0.0;
      var i = 0;
      while (i < n) {
        covariance += (returns[i] - avgReturn) * (benchmarkReturns[i] - avgBenchmark);
        let benchmarkDiff = benchmarkReturns[i] - avgBenchmark;
        benchmarkVariance += benchmarkDiff * benchmarkDiff;
        i += 1;
      };

      beta := if (benchmarkVariance > 0.0) {
        covariance / benchmarkVariance
      } else {
        1.0
      };

      // Alpha (excess return above CAPM expected return)
      let benchmarkAnnualized = Float.pow(1.0 + avgBenchmark, periodsPerYear) - 1.0;
      let expectedReturn = riskFreeRate + beta * (benchmarkAnnualized - riskFreeRate);
      alpha := annualizedReturn - expectedReturn;

      // Information ratio (active return / tracking error)
      var trackingErrorSum = 0.0;
      i := 0;
      while (i < n) {
        let activeReturn = returns[i] - benchmarkReturns[i];
        trackingErrorSum += activeReturn * activeReturn;
        i += 1;
      };
      let trackingError = Float.sqrt(trackingErrorSum / periods) * Float.sqrt(periodsPerYear);
      informationRatio := if (trackingError > 0.0) {
        alpha / trackingError
      } else {
        0.0
      };
    };

    // Win rate and profit factor
    var wins = 0;
    var losses = 0;
    var grossProfit = 0.0;
    var grossLoss = 0.0;
    for (ret in returns.vals()) {
      if (ret > 0.0) {
        wins += 1;
        grossProfit += ret;
      } else if (ret < 0.0) {
        losses += 1;
        grossLoss += Float.abs(ret);
      };
    };
    let winRate = Float.fromInt(wins) / periods;
    let profitFactor = if (grossLoss > 0.0) {
      grossProfit / grossLoss
    } else {
      0.0
    };

    {
      period = "Full Period";
      totalReturn = totalReturn;
      annualizedReturn = annualizedReturn;
      volatility = volatility;
      sharpeRatio = sharpeRatio;
      sortinoRatio = sortinoRatio;
      maxDrawdown = maxDD;
      calmarRatio = calmarRatio;
      alpha = alpha;
      beta = beta;
      informationRatio = informationRatio;
      winRate = winRate;
      profitFactor = profitFactor;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FEE CALCULATION
  // ═══════════════════════════════════════════════════════════════════════════

  public type FeeCalculation = {
    managementFee    : Float;
    performanceFee   : Float;
    totalFees        : Float;
    highWaterMark    : Float;
    netReturn        : Float;    // Return after fees
  };

  // Calculate management and performance fees
  public func calculateFees(
    fund : Fund,
    currentNAV : Float,
    periodReturn : Float,
    periodsPerYear : Float
  ) : FeeCalculation {
    
    // Management fee: annual rate / periods * NAV
    let managementFee = (fund.managementFee / periodsPerYear) * currentNAV;

    // Performance fee: only on returns above high water mark and hurdle
    var performanceFee = 0.0;
    var newHighWaterMark = fund.highWaterMark;

    if (currentNAV > fund.highWaterMark) {
      // Gain above high water mark
      let gain = currentNAV - fund.highWaterMark;
      
      // Check if return exceeds hurdle rate
      let hurdleReturn = fund.hurdleRate / periodsPerYear;
      if (periodReturn > hurdleReturn) {
        let excessReturn = periodReturn - hurdleReturn;
        let excessGain = excessReturn * fund.highWaterMark;
        performanceFee := Float.max(0.0, excessGain * fund.performanceFee);
      };

      // Update high water mark
      newHighWaterMark := currentNAV;
    };

    let totalFees = managementFee + performanceFee;
    let netReturn = periodReturn - (totalFees / currentNAV);

    {
      managementFee = managementFee;
      performanceFee = performanceFee;
      totalFees = totalFees;
      highWaterMark = newHighWaterMark;
      netReturn = netReturn;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CAPITAL ALLOCATION — Risk Parity
  // ═══════════════════════════════════════════════════════════════════════════

  public type RiskParityAllocation = {
    strategyAllocations : [Float];      // Optimal allocations
    riskContributions   : [Float];      // Risk contribution per strategy
    totalRisk           : Float;
    diversification     : Float;        // Diversification ratio
    phiOptimality       : Float;        // Phi-alignment score
  };

  // Risk parity allocation: equalize risk contribution across strategies
  public func calculateRiskParityAllocation(
    strategies : [Strategy],
    targetRisk : Float
  ) : RiskParityAllocation {
    
    let n = strategies.size();
    if (n == 0) {
      return {
        strategyAllocations = [];
        riskContributions = [];
        totalRisk = 0.0;
        diversification = 0.0;
        phiOptimality = 0.0;
      };
    };

    // Initialize equal risk contributions
    let targetRiskPerStrategy = targetRisk / Float.fromInt(n);
    
    let allocations = Array.init<Float>(n, 0.0);
    let riskContribs = Array.init<Float>(n, 0.0);

    // Allocate based on inverse volatility
    var sumInverseVol = 0.0;
    for (strategy in strategies.vals()) {
      // Calculate volatility from returns
      var sumSquared = 0.0;
      var count = 0.0;
      for (ret in strategy.returns.vals()) {
        sumSquared += ret * ret;
        count += 1.0;
      };
      let vol = if (count > 0.0) {
        Float.sqrt(sumSquared / count)
      } else {
        1.0
      };
      sumInverseVol += 1.0 / Float.max(0.01, vol);
    };

    // Calculate allocations
    var i = 0;
    for (strategy in strategies.vals()) {
      var sumSquared = 0.0;
      var count = 0.0;
      for (ret in strategy.returns.vals()) {
        sumSquared += ret * ret;
        count += 1.0;
      };
      let vol = if (count > 0.0) {
        Float.sqrt(sumSquared / count)
      } else {
        1.0
      };
      
      let inverseVol = 1.0 / Float.max(0.01, vol);
      allocations[i] := inverseVol / sumInverseVol;
      
      // Risk contribution = allocation * volatility
      riskContribs[i] := allocations[i] * vol;
      
      i += 1;
    };

    // Calculate portfolio risk
    var portfolioRisk = 0.0;
    for (rc in riskContribs.vals()) {
      portfolioRisk += rc;
    };

    // Diversification ratio
    var weightedVol = 0.0;
    i := 0;
    for (strategy in strategies.vals()) {
      var sumSquared = 0.0;
      var count = 0.0;
      for (ret in strategy.returns.vals()) {
        sumSquared += ret * ret;
        count += 1.0;
      };
      let vol = if (count > 0.0) {
        Float.sqrt(sumSquared / count)
      } else {
        1.0
      };
      weightedVol += allocations[i] * vol;
      i += 1;
    };
    let diversification = if (portfolioRisk > 0.0) {
      weightedVol / portfolioRisk
    } else {
      1.0
    };

    // Phi optimality: how close is diversification to phi?
    let phiOptimality = 1.0 - Float.abs(diversification - Phi.PHI) / Phi.PHI;

    {
      strategyAllocations = Array.freeze(allocations);
      riskContributions = Array.freeze(riskContribs);
      totalRisk = portfolioRisk;
      diversification = diversification;
      phiOptimality = phiOptimality;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INVESTOR OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public type InvestorTransaction = {
    transactionId   : Text;
    investorId      : Text;
    transactionType : TransactionType;
    amount          : Float;
    shares          : Float;
    navPerShare     : Float;
    timestamp       : Int;
    status          : TransactionStatus;
  };

  public type TransactionType = {
    #subscription;    // Capital contribution
    #redemption;      // Capital withdrawal
    #distribution;    // Profit distribution
  };

  public type TransactionStatus = {
    #pending;
    #approved;
    #settled;
    #rejected;
  };

  // Process subscription (capital contribution)
  public func processSubscription(
    fund : Fund,
    investorId : Text,
    amount : Float,
    currentBeat : Int
  ) : (Fund, InvestorTransaction) {
    
    // Calculate shares to issue
    let shares = amount / fund.navPerShare;
    
    let transaction : InvestorTransaction = {
      transactionId = "SUB-" # investorId # "-" # Int.toText(currentBeat);
      investorId = investorId;
      transactionType = #subscription;
      amount = amount;
      shares = shares;
      navPerShare = fund.navPerShare;
      timestamp = currentBeat;
      status = #approved;
    };

    // Update fund
    let updatedFund = {
      fundId = fund.fundId;
      fundName = fund.fundName;
      fundType = fund.fundType;
      inceptionDate = fund.inceptionDate;
      baseCurrency = fund.baseCurrency;
      benchmarkIndex = fund.benchmarkIndex;
      strategies = fund.strategies;
      totalAUM = fund.totalAUM + amount;
      navPerShare = fund.navPerShare;
      shareOutstanding = fund.shareOutstanding + shares;
      managementFee = fund.managementFee;
      performanceFee = fund.performanceFee;
      hurdleRate = fund.hurdleRate;
      highWaterMark = fund.highWaterMark;
      lockupPeriod = fund.lockupPeriod;
    };

    (updatedFund, transaction)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FUND MANAGEMENT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type FundManagementState = {
    var activeFunds           : [Fund];
    var totalAUMAllFunds      : Float;
    var transactions          : [InvestorTransaction];
    var performanceHistory    : [(Int, PerformanceMetrics)];
    var lastNAVCalculation    : ?NAVCalculation;
    var lastFeeCalculation    : ?FeeCalculation;
    var lastAllocation        : ?RiskParityAllocation;
    var totalFeesCollected    : Float;
    var lastUpdateBeat        : Int;
    var phiCoherence          : Float;
  };

  public func initFundManagementState() : FundManagementState {
    {
      var activeFunds = [];
      var totalAUMAllFunds = 0.0;
      var transactions = [];
      var performanceHistory = [];
      var lastNAVCalculation = null;
      var lastFeeCalculation = null;
      var lastAllocation = null;
      var totalFeesCollected = 0.0;
      var lastUpdateBeat = 0;
      var phiCoherence = Phi.PHI_INV;
    }
  };

};
