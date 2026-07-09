import Phi "phi";
import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public let NUMERIC_TOLERANCE : Float = Phi.ETA_OJA;
  public let MIXED_EQUILIBRIUM_TOLERANCE : Float = Phi.ETA_OJA;
  public let CORRELATED_EQUILIBRIUM_TOLERANCE : Float = Phi.PHI_INV_4;
  public let STRATEGIC_STABILITY_THRESHOLD : Float = Phi.PHI_INV;
  public let DEFAULT_ITERATIONS : Nat = 233;
  public let REPLICATOR_STEP : Float = Phi.PHI_INV_3;

  public type TwoPlayerGame = {
    rowStrategies : [Text];
    columnStrategies : [Text];
    rowPayoffs : [[Float]];
    columnPayoffs : [[Float]];
  };

  public type PureStrategyEquilibrium = {
    rowIndex : Nat;
    columnIndex : Nat;
    rowStrategy : Text;
    columnStrategy : Text;
    rowPayoff : Float;
    columnPayoff : Float;
    stabilityMargin : Float;
  };

  public type MixedStrategyEquilibrium = {
    rowProbabilities : [Float];
    columnProbabilities : [Float];
    rowSupport : [Nat];
    columnSupport : [Nat];
    expectedRowPayoff : Float;
    expectedColumnPayoff : Float;
    maxRegret : Float;
    converged : Bool;
    iterations : Nat;
    method : Text;
  };

  public type NPlayerOutcome = {
    actions : [Nat];
    payoffs : [Float];
  };

  public type NPlayerGame = {
    playerStrategies : [[Text]];
    outcomes : [NPlayerOutcome];
  };

  public type NPlayerEquilibrium = {
    strategyProfile : [[Float]];
    expectedPayoffs : [Float];
    bestResponses : [Nat];
    maxRegret : Float;
    converged : Bool;
    iterations : Nat;
    method : Text;
  };

  public type SymmetricGame = {
    strategies : [Text];
    payoffs : [[Float]];
  };

  public type ESSCandidate = {
    probabilities : [Float];
    support : [Nat];
    fitness : Float;
    invasionBarrier : Float;
    isPure : Bool;
  };

  public type ESSResult = {
    candidates : [ESSCandidate];
    stablePopulation : [Float];
    stableFitness : Float;
    converged : Bool;
    iterations : Nat;
  };

  public type CorrelatedEquilibrium = {
    jointDistribution : [[Float]];
    rowIncentiveViolations : [Float];
    columnIncentiveViolations : [Float];
    maxIncentiveViolation : Float;
    converged : Bool;
    iterations : Nat;
  };

  public type Bidder = {
    bidderId : Text;
    valuation : Float;
    bid : Float;
    quantity : Nat;
  };

  public type RankedBid = {
    bidderId : Text;
    valuation : Float;
    bid : Float;
    quantity : Nat;
    rank : Nat;
  };

  public type AuctionAllocation = {
    participantId : Text;
    quantity : Nat;
    payment : Float;
    awardedBundle : [Text];
  };

  public type AuctionResult = {
    winner : ?Text;
    revenue : Float;
    clearingPrice : Float;
    utility : Float;
    allocations : [AuctionAllocation];
    rankedBids : [RankedBid];
    efficient : Bool;
  };

  public type DutchBidder = {
    bidderId : Text;
    valuation : Float;
    acceptancePrice : Float;
    quantity : Nat;
  };

  public type DutchAuctionConfig = {
    startingPrice : Float;
    decrement : Float;
    reservePrice : Float;
    maxRounds : Nat;
    bidders : [DutchBidder];
  };

  public type EnglishBidder = {
    bidderId : Text;
    valuation : Float;
    maxBid : Float;
    quantity : Nat;
  };

  public type EnglishAuctionConfig = {
    startingPrice : Float;
    increment : Float;
    reservePrice : Float;
    bidders : [EnglishBidder];
  };

  public type BundleBid = {
    bidderId : Text;
    bundle : [Text];
    value : Float;
  };

  public type CombinatorialAuctionResult = {
    winningBids : [BundleBid];
    revenue : Float;
    welfare : Float;
    allocatedItems : [Text];
    unallocatedItems : [Text];
  };

  public type DirectMechanism = {
    valuations : [Float];
    reportSpace : [Float];
    allocationProbabilities : [[Float]];
    payments : [[Float]];
    truthfulReportIndex : [Nat];
  };

  public type IncentiveCompatibilityResult = {
    truthfulUtilities : [Float];
    bestDeviationUtilities : [Float];
    bestReports : [Nat];
    violatingTypes : [Nat];
    maxDeviationGain : Float;
    dominantTruthful : Bool;
  };

  public type RevenueEquivalenceModel = {
    valuations : [Float];
    allocationProbabilities : [Float];
    typeProbabilities : [Float];
    baseUtility : Float;
    mechanismAPayments : [Float];
    mechanismBPayments : [Float];
  };

  public type RevenueEquivalenceResult = {
    theoremPayments : [Float];
    interimUtilities : [Float];
    expectedRevenueTheorem : Float;
    expectedRevenueA : Float;
    expectedRevenueB : Float;
    equivalentToTheorem : Bool;
    maxPaymentGap : Float;
  };

  public type SocialOutcome = {
    outcomeId : Text;
    participantValues : [Float];
  };

  public type VCGResult = {
    chosenOutcomeId : Text;
    totalWelfare : Float;
    participantPayments : [Float];
    participantUtilities : [Float];
    counterfactualWelfareWithout : [Float];
  };

  public type DistributionPoint = {
    value : Float;
    probability : Float;
  };

  public type ObservedBidder = {
    bidderId : Text;
    signal : Float;
  };

  public type OptimalAuctionInput = {
    bidders : [ObservedBidder];
    commonDistribution : [DistributionPoint];
  };

  public type VirtualBidder = {
    bidderId : Text;
    observedValue : Float;
    virtualValue : Float;
  };

  public type OptimalAuctionResult = {
    reservePrice : Float;
    winner : ?Text;
    payment : Float;
    virtualBids : [VirtualBidder];
    expectedRevenueFloor : Float;
    tradeExecuted : Bool;
  };

  public type DominantStrategyResult = {
    player : Nat;
    strictlyDominant : [Nat];
    weaklyDominant : [Nat];
    recommendedStrategy : ?Nat;
  };

  public type BestResponseResult = {
    player : Nat;
    bestActions : [Nat];
    actionValues : [Float];
    bestValue : Float;
  };

  public type StabilityAnalysis = {
    playerDeviationGains : [Float];
    maxDeviationGain : Float;
    stabilityScore : Float;
    isStable : Bool;
  };

  public type MarketQuote = {
    venueId : Text;
    asset : Text;
    bid : Float;
    ask : Float;
    feeBps : Float;
    availableSize : Float;
  };

  public type ArbitrageOpportunity = {
    asset : Text;
    buyVenue : Text;
    sellVenue : Text;
    quantity : Float;
    netBuyPrice : Float;
    netSellPrice : Float;
    grossEdge : Float;
    expectedProfit : Float;
    confidence : Float;
  };

  func approxEq(a : Float, b : Float) : Bool {
    Float.abs(a - b) <= NUMERIC_TOLERANCE
  };

  func clamp(x : Float, lo : Float, hi : Float) : Float {
    if (x < lo) { lo } else if (x > hi) { hi } else { x }
  };

  func safeDiv(numer : Float, denom : Float, fallback : Float) : Float {
    if (Float.abs(denom) <= NUMERIC_TOLERANCE) { fallback } else { numer / denom }
  };

  func maxFloat(a : Float, b : Float) : Float {
    if (a > b) { a } else { b }
  };

  func minFloat(a : Float, b : Float) : Float {
    if (a < b) { a } else { b }
  };

  func uniformStrategy(size : Nat) : [Float] {
    if (size == 0) {
      []
    } else {
      Array.tabulate<Float>(size, func(_) { 1.0 / Float.fromInt(size) })
    }
  };

  func zeroVector(size : Nat) : [Float] {
    Array.tabulate<Float>(size, func(_) { 0.0 })
  };

  func zeroMatrix(rows : Nat, cols : Nat) : [[Float]] {
    Array.tabulate<[Float]>(rows, func(_) { zeroVector(cols) })
  };

  func normalize(values : [Float]) : [Float] {
    if (values.size() == 0) { return [] };
    let clipped = Array.map<Float, Float>(values, func(v) { if (v > 0.0) { v } else { 0.0 } });
    var total : Float = 0.0;
    for (v in clipped.vals()) { total += v };
    if (total <= NUMERIC_TOLERANCE) {
      uniformStrategy(clipped.size())
    } else {
      Array.tabulate<Float>(clipped.size(), func(i) { clipped[i] / total })
    }
  };

  func supportOf(probabilities : [Float]) : [Nat] {
    var support : [Nat] = [];
    var i : Nat = 0;
    while (i < probabilities.size()) {
      if (probabilities[i] > NUMERIC_TOLERANCE) {
        support := Array.append<Nat>(support, [i]);
      };
      i += 1;
    };
    support
  };

  func expectedValue(probabilities : [Float], values : [Float]) : Float {
    var total : Float = 0.0;
    var i : Nat = 0;
    while (i < probabilities.size() and i < values.size()) {
      total += probabilities[i] * values[i];
      i += 1;
    };
    total
  };

  func maxIndex(values : [Float]) : Nat {
    if (values.size() == 0) { return 0 };
    var bestIndex : Nat = 0;
    var bestValue : Float = values[0];
    var i : Nat = 1;
    while (i < values.size()) {
      if (values[i] > bestValue) {
        bestValue := values[i];
        bestIndex := i;
      };
      i += 1;
    };
    bestIndex
  };

  func maxValue(values : [Float]) : Float {
    if (values.size() == 0) { return 0.0 };
    values[maxIndex(values)]
  };

  func indicesOfMax(values : [Float]) : [Nat] {
    if (values.size() == 0) { return [] };
    let best = maxValue(values);
    var out : [Nat] = [];
    var i : Nat = 0;
    while (i < values.size()) {
      if (values[i] + NUMERIC_TOLERANCE >= best) {
        out := Array.append<Nat>(out, [i]);
      };
      i += 1;
    };
    out
  };

  func rowActionPayoffs(game : TwoPlayerGame, columnMix : [Float]) : [Float] {
    Array.tabulate<Float>(game.rowStrategies.size(), func(i) {
      var payoff : Float = 0.0;
      var j : Nat = 0;
      while (j < game.columnStrategies.size() and j < columnMix.size()) {
        payoff += columnMix[j] * game.rowPayoffs[i][j];
        j += 1;
      };
      payoff
    })
  };

  func columnActionPayoffs(game : TwoPlayerGame, rowMix : [Float]) : [Float] {
    Array.tabulate<Float>(game.columnStrategies.size(), func(j) {
      var payoff : Float = 0.0;
      var i : Nat = 0;
      while (i < game.rowStrategies.size() and i < rowMix.size()) {
        payoff += rowMix[i] * game.columnPayoffs[i][j];
        i += 1;
      };
      payoff
    })
  };

  func expectedPayoffs(game : TwoPlayerGame, rowMix : [Float], columnMix : [Float]) : { row : Float; column : Float } {
    {
      row = expectedValue(rowMix, rowActionPayoffs(game, columnMix));
      column = expectedValue(columnMix, columnActionPayoffs(game, rowMix));
    }
  };

  func maxRegretTwoPlayer(game : TwoPlayerGame, rowMix : [Float], columnMix : [Float]) : Float {
    let rowValues = rowActionPayoffs(game, columnMix);
    let colValues = columnActionPayoffs(game, rowMix);
    let avg = expectedPayoffs(game, rowMix, columnMix);
    maxFloat(maxValue(rowValues) - avg.row, maxValue(colValues) - avg.column)
  };

  public func solvePureStrategyNash(game : TwoPlayerGame) : [PureStrategyEquilibrium] {
    var equilibria : [PureStrategyEquilibrium] = [];
    var i : Nat = 0;
    while (i < game.rowStrategies.size()) {
      var j : Nat = 0;
      while (j < game.columnStrategies.size()) {
        let rowPayoff = game.rowPayoffs[i][j];
        let colPayoff = game.columnPayoffs[i][j];
        var rowBest : Float = rowPayoff;
        var k : Nat = 0;
        while (k < game.rowStrategies.size()) {
          rowBest := maxFloat(rowBest, game.rowPayoffs[k][j]);
          k += 1;
        };
        var colBest : Float = colPayoff;
        var l : Nat = 0;
        while (l < game.columnStrategies.size()) {
          colBest := maxFloat(colBest, game.columnPayoffs[i][l]);
          l += 1;
        };
        if (rowPayoff + NUMERIC_TOLERANCE >= rowBest and colPayoff + NUMERIC_TOLERANCE >= colBest) {
          let stability = minFloat(rowBest - (rowBest - rowPayoff), colBest - (colBest - colPayoff));
          equilibria := Array.append<PureStrategyEquilibrium>(equilibria, [{
            rowIndex = i;
            columnIndex = j;
            rowStrategy = game.rowStrategies[i];
            columnStrategy = game.columnStrategies[j];
            rowPayoff = rowPayoff;
            columnPayoff = colPayoff;
            stabilityMargin = minFloat(rowPayoff, colPayoff);
          }]);
        };
        j += 1;
      };
      i += 1;
    };
    equilibria
  };

  func exactMixed2x2(game : TwoPlayerGame) : ?MixedStrategyEquilibrium {
    if (game.rowStrategies.size() != 2 or game.columnStrategies.size() != 2) {
      return null;
    };
    let r00 = game.rowPayoffs[0][0];
    let r01 = game.rowPayoffs[0][1];
    let r10 = game.rowPayoffs[1][0];
    let r11 = game.rowPayoffs[1][1];
    let c00 = game.columnPayoffs[0][0];
    let c01 = game.columnPayoffs[0][1];
    let c10 = game.columnPayoffs[1][0];
    let c11 = game.columnPayoffs[1][1];
    let denomRow = r00 - r01 - r10 + r11;
    let denomCol = c00 - c01 - c10 + c11;
    if (Float.abs(denomRow) <= NUMERIC_TOLERANCE or Float.abs(denomCol) <= NUMERIC_TOLERANCE) {
      return null;
    };
    let y = (r11 - r01) / denomRow;
    let x = (c11 - c10) / denomCol;
    if (x < -NUMERIC_TOLERANCE or x > 1.0 + NUMERIC_TOLERANCE or y < -NUMERIC_TOLERANCE or y > 1.0 + NUMERIC_TOLERANCE) {
      return null;
    };
    let rowMix = [clamp(x, 0.0, 1.0), 1.0 - clamp(x, 0.0, 1.0)];
    let colMix = [clamp(y, 0.0, 1.0), 1.0 - clamp(y, 0.0, 1.0)];
    let avg = expectedPayoffs(game, rowMix, colMix);
    let regret = maxRegretTwoPlayer(game, rowMix, colMix);
    ?{
      rowProbabilities = rowMix;
      columnProbabilities = colMix;
      rowSupport = supportOf(rowMix);
      columnSupport = supportOf(colMix);
      expectedRowPayoff = avg.row;
      expectedColumnPayoff = avg.column;
      maxRegret = regret;
      converged = regret <= MIXED_EQUILIBRIUM_TOLERANCE;
      iterations = 1;
      method = "closed-form-2x2";
    }
  };

  public func solveMixedStrategyNash(game : TwoPlayerGame, maxIterations : Nat) : MixedStrategyEquilibrium {
    switch (exactMixed2x2(game)) {
      case (?eq) { return eq };
      case null {};
    };

    var rowMix = uniformStrategy(game.rowStrategies.size());
    var colMix = uniformStrategy(game.columnStrategies.size());
    var iteration : Nat = 0;
    var regret : Float = 1.0;
    while (iteration < maxIterations and regret > MIXED_EQUILIBRIUM_TOLERANCE) {
      let rowValues = rowActionPayoffs(game, colMix);
      let colValues = columnActionPayoffs(game, rowMix);
      let avg = expectedPayoffs(game, rowMix, colMix);
      regret := maxFloat(maxValue(rowValues) - avg.row, maxValue(colValues) - avg.column);
      let learningRate = REPLICATOR_STEP / (1.0 + Float.fromInt(iteration));
      rowMix := normalize(Array.tabulate<Float>(rowMix.size(), func(i) {
        rowMix[i] * Float.exp(learningRate * (rowValues[i] - avg.row))
      }));
      colMix := normalize(Array.tabulate<Float>(colMix.size(), func(j) {
        colMix[j] * Float.exp(learningRate * (colValues[j] - avg.column))
      }));
      iteration += 1;
    };
    let avg = expectedPayoffs(game, rowMix, colMix);
    {
      rowProbabilities = rowMix;
      columnProbabilities = colMix;
      rowSupport = supportOf(rowMix);
      columnSupport = supportOf(colMix);
      expectedRowPayoff = avg.row;
      expectedColumnPayoff = avg.column;
      maxRegret = maxRegretTwoPlayer(game, rowMix, colMix);
      converged = maxRegretTwoPlayer(game, rowMix, colMix) <= MIXED_EQUILIBRIUM_TOLERANCE;
      iterations = iteration;
      method = "replicator-multiplicative-weights";
    }
  };

  func outcomeProbability(profile : [[Float]], actions : [Nat]) : Float {
    var probability : Float = 1.0;
    var player : Nat = 0;
    while (player < profile.size() and player < actions.size()) {
      if (actions[player] >= profile[player].size()) { return 0.0 };
      probability *= profile[player][actions[player]];
      player += 1;
    };
    probability
  };

  func outcomeProbabilityWithAction(profile : [[Float]], player : Nat, action : Nat, actions : [Nat]) : Float {
    if (player >= actions.size() or actions[player] != action) { return 0.0 };
    var probability : Float = 1.0;
    var p : Nat = 0;
    while (p < profile.size() and p < actions.size()) {
      if (p != player) {
        if (actions[p] >= profile[p].size()) { return 0.0 };
        probability *= profile[p][actions[p]];
      };
      p += 1;
    };
    probability
  };

  func expectedActionPayoffNPlayer(game : NPlayerGame, player : Nat, action : Nat, profile : [[Float]]) : Float {
    var total : Float = 0.0;
    for (outcome in game.outcomes.vals()) {
      if (player < outcome.actions.size() and player < outcome.payoffs.size()) {
        total += outcomeProbabilityWithAction(profile, player, action, outcome.actions) * outcome.payoffs[player];
      };
    };
    total
  };

  func actionPayoffsNPlayer(game : NPlayerGame, player : Nat, profile : [[Float]]) : [Float] {
    Array.tabulate<Float>(game.playerStrategies[player].size(), func(action) {
      expectedActionPayoffNPlayer(game, player, action, profile)
    })
  };

  func expectedPayoffVectorNPlayer(game : NPlayerGame, profile : [[Float]]) : [Float] {
    Array.tabulate<Float>(game.playerStrategies.size(), func(player) {
      expectedValue(profile[player], actionPayoffsNPlayer(game, player, profile))
    })
  };

  public func solveNPlayerNashLemkeHowson(game : NPlayerGame, maxIterations : Nat) : NPlayerEquilibrium {
    var profile = Array.tabulate<[Float]>(game.playerStrategies.size(), func(player) {
      uniformStrategy(game.playerStrategies[player].size())
    });
    var bestResponses = Array.tabulate<Nat>(game.playerStrategies.size(), func(_) { 0 });
    var iteration : Nat = 0;
    var regret : Float = 1.0;
    while (iteration < maxIterations and regret > MIXED_EQUILIBRIUM_TOLERANCE) {
      var nextProfile : [[Float]] = [];
      var nextBest : [Nat] = [];
      let expected = expectedPayoffVectorNPlayer(game, profile);
      regret := 0.0;
      var player : Nat = 0;
      while (player < game.playerStrategies.size()) {
        let values = actionPayoffsNPlayer(game, player, profile);
        let best = maxIndex(values);
        let bestValue = values[best];
        regret := maxFloat(regret, bestValue - expected[player]);
        nextBest := Array.append<Nat>(nextBest, [best]);
        let bestResponseMix = Array.tabulate<Float>(values.size(), func(i) {
          if (i == best) { 1.0 } else { 0.0 }
        });
        let pivot = REPLICATOR_STEP / (1.0 + Float.fromInt(iteration));
        let blended = normalize(Array.tabulate<Float>(values.size(), func(i) {
          (1.0 - pivot) * profile[player][i] + pivot * bestResponseMix[i]
        }));
        nextProfile := Array.append<[Float]>(nextProfile, [blended]);
        player += 1;
      };
      profile := nextProfile;
      bestResponses := nextBest;
      iteration += 1;
    };
    {
      strategyProfile = profile;
      expectedPayoffs = expectedPayoffVectorNPlayer(game, profile);
      bestResponses = bestResponses;
      maxRegret = Array.foldLeft<Float, Float>(Array.tabulate<Float>(game.playerStrategies.size(), func(player) {
        let values = actionPayoffsNPlayer(game, player, profile);
        maxValue(values) - expectedValue(profile[player], values)
      }), 0.0, func(acc, v) { maxFloat(acc, v) });
      converged = Array.foldLeft<Float, Float>(Array.tabulate<Float>(game.playerStrategies.size(), func(player) {
        let values = actionPayoffsNPlayer(game, player, profile);
        maxValue(values) - expectedValue(profile[player], values)
      }), 0.0, func(acc, v) { maxFloat(acc, v) }) <= MIXED_EQUILIBRIUM_TOLERANCE;
      iterations = iteration;
      method = "generalized-lemke-howson-path-following";
    }
  };

  func symmetricFitness(game : SymmetricGame, population : [Float]) : [Float] {
    Array.tabulate<Float>(game.strategies.size(), func(i) {
      var total : Float = 0.0;
      var j : Nat = 0;
      while (j < population.size()) {
        total += game.payoffs[i][j] * population[j];
        j += 1;
      };
      total
    })
  };

  func invasionBarrier(game : SymmetricGame, candidate : [Float]) : Float {
    let residentFitness = symmetricFitness(game, candidate);
    let avgResident = expectedValue(candidate, residentFitness);
    var barrier : Float = avgResident;
    var mutant : Nat = 0;
    while (mutant < game.strategies.size()) {
      let mutantFitness = residentFitness[mutant];
      barrier := minFloat(barrier, avgResident - mutantFitness);
      mutant += 1;
    };
    barrier
  };

  public func computeEvolutionaryStableStrategies(game : SymmetricGame, maxIterations : Nat) : ESSResult {
    var candidates : [ESSCandidate] = [];
    var i : Nat = 0;
    while (i < game.strategies.size()) {
      var ess = true;
      var j : Nat = 0;
      while (j < game.strategies.size()) {
        if (i != j) {
          let primary = game.payoffs[i][i];
          let challenger = game.payoffs[j][i];
          if (challenger > primary + NUMERIC_TOLERANCE) {
            ess := false;
          } else if (approxEq(primary, challenger) and game.payoffs[i][j] <= game.payoffs[j][j] + NUMERIC_TOLERANCE) {
            ess := false;
          };
        };
        j += 1;
      };
      if (ess) {
        let pure = Array.tabulate<Float>(game.strategies.size(), func(idx) {
          if (idx == i) { 1.0 } else { 0.0 }
        });
        candidates := Array.append<ESSCandidate>(candidates, [{
          probabilities = pure;
          support = [i];
          fitness = game.payoffs[i][i];
          invasionBarrier = invasionBarrier(game, pure);
          isPure = true;
        }]);
      };
      i += 1;
    };

    var population = uniformStrategy(game.strategies.size());
    var iteration : Nat = 0;
    var delta : Float = 1.0;
    while (iteration < maxIterations and delta > MIXED_EQUILIBRIUM_TOLERANCE) {
      let fitness = symmetricFitness(game, population);
      let avgFitness = expectedValue(population, fitness);
      let nextPopulation = normalize(Array.tabulate<Float>(population.size(), func(idx) {
        population[idx] * maxFloat(NUMERIC_TOLERANCE, 1.0 + REPLICATOR_STEP * (fitness[idx] - avgFitness))
      }));
      delta := 0.0;
      var idx : Nat = 0;
      while (idx < population.size()) {
        delta := maxFloat(delta, Float.abs(nextPopulation[idx] - population[idx]));
        idx += 1;
      };
      population := nextPopulation;
      iteration += 1;
    };
    let finalFitnessVector = symmetricFitness(game, population);
    let finalFitness = expectedValue(population, finalFitnessVector);
    if (population.size() > 0 and invasionBarrier(game, population) >= -MIXED_EQUILIBRIUM_TOLERANCE) {
      candidates := Array.append<ESSCandidate>(candidates, [{
        probabilities = population;
        support = supportOf(population);
        fitness = finalFitness;
        invasionBarrier = invasionBarrier(game, population);
        isPure = false;
      }]);
    };
    {
      candidates = candidates;
      stablePopulation = population;
      stableFitness = finalFitness;
      converged = delta <= MIXED_EQUILIBRIUM_TOLERANCE;
      iterations = iteration;
    }
  };

  func outerProduct(a : [Float], b : [Float]) : [[Float]] {
    Array.tabulate<[Float]>(a.size(), func(i) {
      Array.tabulate<Float>(b.size(), func(j) { a[i] * b[j] })
    })
  };

  func addMatrices(left : [[Float]], right : [[Float]]) : [[Float]] {
    Array.tabulate<[Float]>(left.size(), func(i) {
      Array.tabulate<Float>(left[i].size(), func(j) {
        left[i][j] + right[i][j]
      })
    })
  };

  func scaleMatrix(m : [[Float]], factor : Float) : [[Float]] {
    Array.tabulate<[Float]>(m.size(), func(i) {
      Array.tabulate<Float>(m[i].size(), func(j) { m[i][j] * factor })
    })
  };

  func rowConditionalViolations(game : TwoPlayerGame, distribution : [[Float]]) : [Float] {
    Array.tabulate<Float>(game.rowStrategies.size(), func(recommended) {
      var worst : Float = 0.0;
      var deviate : Nat = 0;
      while (deviate < game.rowStrategies.size()) {
        var incentive : Float = 0.0;
        var column : Nat = 0;
        while (column < game.columnStrategies.size()) {
          incentive += distribution[recommended][column] * (game.rowPayoffs[deviate][column] - game.rowPayoffs[recommended][column]);
          column += 1;
        };
        worst := maxFloat(worst, incentive);
        deviate += 1;
      };
      worst
    })
  };

  func columnConditionalViolations(game : TwoPlayerGame, distribution : [[Float]]) : [Float] {
    Array.tabulate<Float>(game.columnStrategies.size(), func(recommended) {
      var worst : Float = 0.0;
      var deviate : Nat = 0;
      while (deviate < game.columnStrategies.size()) {
        var incentive : Float = 0.0;
        var row : Nat = 0;
        while (row < game.rowStrategies.size()) {
          incentive += distribution[row][recommended] * (game.columnPayoffs[row][deviate] - game.columnPayoffs[row][recommended]);
          row += 1;
        };
        worst := maxFloat(worst, incentive);
        deviate += 1;
      };
      worst
    })
  };

  public func solveCorrelatedEquilibrium(game : TwoPlayerGame, maxIterations : Nat) : CorrelatedEquilibrium {
    var rowMix = uniformStrategy(game.rowStrategies.size());
    var colMix = uniformStrategy(game.columnStrategies.size());
    var cumulative = zeroMatrix(game.rowStrategies.size(), game.columnStrategies.size());
    var iteration : Nat = 0;
    while (iteration < maxIterations) {
      let current = outerProduct(rowMix, colMix);
      cumulative := addMatrices(cumulative, current);
      let rowValues = rowActionPayoffs(game, colMix);
      let colValues = columnActionPayoffs(game, rowMix);
      let avg = expectedPayoffs(game, rowMix, colMix);
      rowMix := normalize(Array.tabulate<Float>(rowMix.size(), func(i) {
        rowMix[i] + maxFloat(0.0, rowValues[i] - avg.row) + Phi.PHI_INV_5
      }));
      colMix := normalize(Array.tabulate<Float>(colMix.size(), func(j) {
        colMix[j] + maxFloat(0.0, colValues[j] - avg.column) + Phi.PHI_INV_5
      }));
      iteration += 1;
    };
    let averageDistribution = scaleMatrix(cumulative, safeDiv(1.0, Float.fromInt(maxIterations), 1.0));
    let rowViolations = rowConditionalViolations(game, averageDistribution);
    let columnViolations = columnConditionalViolations(game, averageDistribution);
    let maxViolation = maxFloat(maxValue(rowViolations), maxValue(columnViolations));
    {
      jointDistribution = averageDistribution;
      rowIncentiveViolations = rowViolations;
      columnIncentiveViolations = columnViolations;
      maxIncentiveViolation = maxViolation;
      converged = maxViolation <= CORRELATED_EQUILIBRIUM_TOLERANCE;
      iterations = maxIterations;
    }
  };

  func rankBids(bidders : [Bidder]) : [RankedBid] {
    let sorted = Array.sort<Bidder>(bidders, func(a, b) {
      if (a.bid > b.bid) { #less }
      else if (a.bid < b.bid) { #greater }
      else if (a.valuation > b.valuation) { #less }
      else if (a.valuation < b.valuation) { #greater }
      else { #equal }
    });
    Array.tabulate<RankedBid>(sorted.size(), func(i) {
      {
        bidderId = sorted[i].bidderId;
        valuation = sorted[i].valuation;
        bid = sorted[i].bid;
        quantity = sorted[i].quantity;
        rank = i + 1;
      }
    })
  };

  func efficientWinner(bidders : [Bidder]) : ?Text {
    if (bidders.size() == 0) { return null };
    let sorted = Array.sort<Bidder>(bidders, func(a, b) {
      if (a.valuation > b.valuation) { #less }
      else if (a.valuation < b.valuation) { #greater }
      else { #equal }
    });
    ?sorted[0].bidderId
  };

  public func runFirstPriceSealedBidAuction(bidders : [Bidder]) : AuctionResult {
    let ranked = rankBids(bidders);
    if (ranked.size() == 0) {
      return { winner = null; revenue = 0.0; clearingPrice = 0.0; utility = 0.0; allocations = []; rankedBids = []; efficient = true };
    };
    let winner = ranked[0];
    {
      winner = ?winner.bidderId;
      revenue = winner.bid;
      clearingPrice = winner.bid;
      utility = winner.valuation - winner.bid;
      allocations = [{ participantId = winner.bidderId; quantity = winner.quantity; payment = winner.bid; awardedBundle = [] }];
      rankedBids = ranked;
      efficient = switch (efficientWinner(bidders)) { case (?id) { id == winner.bidderId }; case null { true } };
    }
  };

  public func runSecondPriceAuction(bidders : [Bidder]) : AuctionResult {
    let ranked = rankBids(bidders);
    if (ranked.size() == 0) {
      return { winner = null; revenue = 0.0; clearingPrice = 0.0; utility = 0.0; allocations = []; rankedBids = []; efficient = true };
    };
    let winner = ranked[0];
    let price = if (ranked.size() > 1) { ranked[1].bid } else { 0.0 };
    {
      winner = ?winner.bidderId;
      revenue = price;
      clearingPrice = price;
      utility = winner.valuation - price;
      allocations = [{ participantId = winner.bidderId; quantity = winner.quantity; payment = price; awardedBundle = [] }];
      rankedBids = ranked;
      efficient = switch (efficientWinner(bidders)) { case (?id) { id == winner.bidderId }; case null { true } };
    }
  };

  public func runDutchAuction(config : DutchAuctionConfig) : AuctionResult {
    var round : Nat = 0;
    var winner : ?DutchBidder = null;
    var clearing : Float = config.startingPrice;
    while (round < config.maxRounds and winner == null) {
      let currentPrice = maxFloat(config.reservePrice, config.startingPrice - Float.fromInt(round) * config.decrement);
      var bestAcceptance : Float = -1.0;
      for (bidder in config.bidders.vals()) {
        if (bidder.valuation + NUMERIC_TOLERANCE >= currentPrice and bidder.acceptancePrice + NUMERIC_TOLERANCE >= currentPrice) {
          if (bidder.acceptancePrice > bestAcceptance) {
            bestAcceptance := bidder.acceptancePrice;
            winner := ?bidder;
            clearing := currentPrice;
          };
        };
      };
      round += 1;
    };
    switch (winner) {
      case null {
        { winner = null; revenue = 0.0; clearingPrice = 0.0; utility = 0.0; allocations = []; rankedBids = []; efficient = false }
      };
      case (?w) {
        {
          winner = ?w.bidderId;
          revenue = clearing;
          clearingPrice = clearing;
          utility = w.valuation - clearing;
          allocations = [{ participantId = w.bidderId; quantity = w.quantity; payment = clearing; awardedBundle = [] }];
          rankedBids = Array.map<DutchBidder, RankedBid>(config.bidders, func(b) {
            {
              bidderId = b.bidderId;
              valuation = b.valuation;
              bid = b.acceptancePrice;
              quantity = b.quantity;
              rank = 0;
            }
          });
          efficient = true;
        }
      };
    }
  };

  public func runEnglishAuction(config : EnglishAuctionConfig) : AuctionResult {
    if (config.bidders.size() == 0) {
      return { winner = null; revenue = 0.0; clearingPrice = 0.0; utility = 0.0; allocations = []; rankedBids = []; efficient = true };
    };
    let sorted = Array.sort<EnglishBidder>(config.bidders, func(a, b) {
      if (a.maxBid > b.maxBid) { #less }
      else if (a.maxBid < b.maxBid) { #greater }
      else if (a.valuation > b.valuation) { #less }
      else if (a.valuation < b.valuation) { #greater }
      else { #equal }
    });
    let winner = sorted[0];
    let second = if (sorted.size() > 1) { sorted[1].maxBid } else { config.reservePrice };
    let price = maxFloat(config.reservePrice, minFloat(winner.maxBid, second + config.increment));
    {
      winner = ?winner.bidderId;
      revenue = price;
      clearingPrice = price;
      utility = winner.valuation - price;
      allocations = [{ participantId = winner.bidderId; quantity = winner.quantity; payment = price; awardedBundle = [] }];
      rankedBids = Array.tabulate<RankedBid>(sorted.size(), func(i) {
        {
          bidderId = sorted[i].bidderId;
          valuation = sorted[i].valuation;
          bid = sorted[i].maxBid;
          quantity = sorted[i].quantity;
          rank = i + 1;
        }
      });
      efficient = true;
    }
  };

  func bundleOverlap(a : [Text], b : [Text]) : Bool {
    for (left in a.vals()) {
      for (right in b.vals()) {
        if (left == right) { return true };
      };
    };
    false
  };

  func appendDistinct(items : [Text], additions : [Text]) : [Text] {
    var result = items;
    for (item in additions.vals()) {
      var exists = false;
      for (present in result.vals()) {
        if (present == item) { exists := true };
      };
      if (not exists) {
        result := Array.append<Text>(result, [item]);
      };
    };
    result
  };

  public func runCombinatorialAuction(items : [Text], bids : [BundleBid]) : CombinatorialAuctionResult {
    func search(index : Nat, chosen : [BundleBid], used : [Text], revenue : Float) : { chosen : [BundleBid]; revenue : Float } {
      if (index >= bids.size()) {
        return { chosen = chosen; revenue = revenue };
      };
      let skip = search(index + 1, chosen, used, revenue);
      let current = bids[index];
      if (bundleOverlap(used, current.bundle)) {
        return skip;
      };
      let take = search(index + 1, Array.append<BundleBid>(chosen, [current]), appendDistinct(used, current.bundle), revenue + current.value);
      if (take.revenue > skip.revenue) { take } else { skip }
    };
    let best = search(0, [], [], 0.0);
    let allocated = Array.foldLeft<BundleBid, [Text]>(best.chosen, [], func(acc, bid) {
      appendDistinct(acc, bid.bundle)
    });
    let unallocated = Array.filter<Text>(items, func(item) {
      not Array.foldLeft<Text, Bool>(allocated, false, func(found, allocatedItem) { found or allocatedItem == item })
    });
    {
      winningBids = best.chosen;
      revenue = best.revenue;
      welfare = best.revenue;
      allocatedItems = allocated;
      unallocatedItems = unallocated;
    }
  };

  public func checkIncentiveCompatibility(mechanism : DirectMechanism) : IncentiveCompatibilityResult {
    let truthfulUtilities = Array.tabulate<Float>(mechanism.valuations.size(), func(typeIndex) {
      let truthful = mechanism.truthfulReportIndex[typeIndex];
      mechanism.valuations[typeIndex] * mechanism.allocationProbabilities[typeIndex][truthful] - mechanism.payments[typeIndex][truthful]
    });
    let bestDeviationUtilities = Array.tabulate<Float>(mechanism.valuations.size(), func(typeIndex) {
      var best : Float = -1.0e18;
      var report : Nat = 0;
      while (report < mechanism.reportSpace.size()) {
        let utility = mechanism.valuations[typeIndex] * mechanism.allocationProbabilities[typeIndex][report] - mechanism.payments[typeIndex][report];
        best := maxFloat(best, utility);
        report += 1;
      };
      best
    });
    let bestReports = Array.tabulate<Nat>(mechanism.valuations.size(), func(typeIndex) {
      var best : Float = -1.0e18;
      var bestReport : Nat = 0;
      var report : Nat = 0;
      while (report < mechanism.reportSpace.size()) {
        let utility = mechanism.valuations[typeIndex] * mechanism.allocationProbabilities[typeIndex][report] - mechanism.payments[typeIndex][report];
        if (utility > best) {
          best := utility;
          bestReport := report;
        };
        report += 1;
      };
      bestReport
    });
    var violating : [Nat] = [];
    var maxGain : Float = 0.0;
    var idx : Nat = 0;
    while (idx < mechanism.valuations.size()) {
      let deviationGain = bestDeviationUtilities[idx] - truthfulUtilities[idx];
      maxGain := maxFloat(maxGain, deviationGain);
      if (deviationGain > NUMERIC_TOLERANCE) {
        violating := Array.append<Nat>(violating, [idx]);
      };
      idx += 1;
    };
    {
      truthfulUtilities = truthfulUtilities;
      bestDeviationUtilities = bestDeviationUtilities;
      bestReports = bestReports;
      violatingTypes = violating;
      maxDeviationGain = maxGain;
      dominantTruthful = violating.size() == 0;
    }
  };

  public func implementRevenueEquivalence(model : RevenueEquivalenceModel) : RevenueEquivalenceResult {
    let utilities = Array.tabulate<Float>(model.valuations.size(), func(i) {
      if (i == 0) {
        model.baseUtility
      } else {
        0.0
      }
    });
    var interim = utilities;
    var i : Nat = 1;
    while (i < model.valuations.size()) {
      let deltaV = model.valuations[i] - model.valuations[i - 1];
      let nextU = interim[i - 1] + deltaV * model.allocationProbabilities[i - 1];
      interim := Array.tabulate<Float>(interim.size(), func(idx) {
        if (idx == i) { nextU } else { interim[idx] }
      });
      i += 1;
    };
    let theoremPayments = Array.tabulate<Float>(model.valuations.size(), func(idx) {
      model.valuations[idx] * model.allocationProbabilities[idx] - interim[idx]
    });
    let expectedTheorem = Array.foldLeft<Float, Float>(Array.tabulate<Float>(theoremPayments.size(), func(idx) {
      theoremPayments[idx] * model.typeProbabilities[idx]
    }), 0.0, func(acc, x) { acc + x });
    let expectedA = Array.foldLeft<Float, Float>(Array.tabulate<Float>(model.mechanismAPayments.size(), func(idx) {
      model.mechanismAPayments[idx] * model.typeProbabilities[idx]
    }), 0.0, func(acc, x) { acc + x });
    let expectedB = Array.foldLeft<Float, Float>(Array.tabulate<Float>(model.mechanismBPayments.size(), func(idx) {
      model.mechanismBPayments[idx] * model.typeProbabilities[idx]
    }), 0.0, func(acc, x) { acc + x });
    var maxGap : Float = 0.0;
    var j : Nat = 0;
    while (j < theoremPayments.size()) {
      maxGap := maxFloat(maxGap, Float.abs(theoremPayments[j] - model.mechanismAPayments[j]));
      maxGap := maxFloat(maxGap, Float.abs(theoremPayments[j] - model.mechanismBPayments[j]));
      j += 1;
    };
    {
      theoremPayments = theoremPayments;
      interimUtilities = interim;
      expectedRevenueTheorem = expectedTheorem;
      expectedRevenueA = expectedA;
      expectedRevenueB = expectedB;
      equivalentToTheorem = maxGap <= CORRELATED_EQUILIBRIUM_TOLERANCE;
      maxPaymentGap = maxGap;
    }
  };

  func welfareOfOutcome(outcome : SocialOutcome) : Float {
    Array.foldLeft<Float, Float>(outcome.participantValues, 0.0, func(acc, v) { acc + v })
  };

  func othersWelfare(outcome : SocialOutcome, excluded : Nat) : Float {
    Array.foldLeft<Float, Float>(Array.tabulate<Float>(outcome.participantValues.size(), func(i) {
      if (i == excluded) { 0.0 } else { outcome.participantValues[i] }
    }), 0.0, func(acc, v) { acc + v })
  };

  public func runVCGMechanism(outcomes : [SocialOutcome]) : VCGResult {
    if (outcomes.size() == 0) {
      return { chosenOutcomeId = ""; totalWelfare = 0.0; participantPayments = []; participantUtilities = []; counterfactualWelfareWithout = [] };
    };
    let sorted = Array.sort<SocialOutcome>(outcomes, func(a, b) {
      if (welfareOfOutcome(a) > welfareOfOutcome(b)) { #less }
      else if (welfareOfOutcome(a) < welfareOfOutcome(b)) { #greater }
      else { #equal }
    });
    let chosen = sorted[0];
    let participantCount = chosen.participantValues.size();
    let counterfactual = Array.tabulate<Float>(participantCount, func(player) {
      var best : Float = 0.0;
      for (outcome in outcomes.vals()) {
        best := maxFloat(best, othersWelfare(outcome, player));
      };
      best
    });
    let payments = Array.tabulate<Float>(participantCount, func(player) {
      maxFloat(0.0, counterfactual[player] - othersWelfare(chosen, player))
    });
    let utilities = Array.tabulate<Float>(participantCount, func(player) {
      chosen.participantValues[player] - payments[player]
    });
    {
      chosenOutcomeId = chosen.outcomeId;
      totalWelfare = welfareOfOutcome(chosen);
      participantPayments = payments;
      participantUtilities = utilities;
      counterfactualWelfareWithout = counterfactual;
    }
  };

  func virtualValueFor(distribution : [DistributionPoint], signal : Float) : Float {
    if (distribution.size() == 0) { return signal };
    let sorted = Array.sort<DistributionPoint>(distribution, func(a, b) {
      if (a.value < b.value) { #less }
      else if (a.value > b.value) { #greater }
      else { #equal }
    });
    var cumulative : Float = 0.0;
    var candidate = sorted[sorted.size() - 1];
    var i : Nat = 0;
    while (i < sorted.size()) {
      cumulative += sorted[i].probability;
      if (signal <= sorted[i].value + NUMERIC_TOLERANCE) {
        candidate := sorted[i];
        return candidate.value - safeDiv(1.0 - cumulative, candidate.probability, 0.0);
      };
      i += 1;
    };
    candidate.value - safeDiv(1.0 - cumulative, candidate.probability, 0.0)
  };

  func myersonReserve(distribution : [DistributionPoint]) : Float {
    if (distribution.size() == 0) { return 0.0 };
    let sorted = Array.sort<DistributionPoint>(distribution, func(a, b) {
      if (a.value < b.value) { #less }
      else if (a.value > b.value) { #greater }
      else { #equal }
    });
    var reserve = sorted[sorted.size() - 1].value;
    var i : Nat = 0;
    while (i < sorted.size()) {
      if (virtualValueFor(sorted, sorted[i].value) >= 0.0) {
        reserve := sorted[i].value;
        return reserve;
      };
      i += 1;
    };
    reserve
  };

  public func designOptimalAuction(input : OptimalAuctionInput) : OptimalAuctionResult {
    let reserve = myersonReserve(input.commonDistribution);
    let virtualBids = Array.map<ObservedBidder, VirtualBidder>(input.bidders, func(bidder) {
      {
        bidderId = bidder.bidderId;
        observedValue = bidder.signal;
        virtualValue = virtualValueFor(input.commonDistribution, bidder.signal);
      }
    });
    let sorted = Array.sort<VirtualBidder>(virtualBids, func(a, b) {
      if (a.virtualValue > b.virtualValue) { #less }
      else if (a.virtualValue < b.virtualValue) { #greater }
      else if (a.observedValue > b.observedValue) { #less }
      else if (a.observedValue < b.observedValue) { #greater }
      else { #equal }
    });
    if (sorted.size() == 0 or sorted[0].virtualValue < 0.0 or sorted[0].observedValue + NUMERIC_TOLERANCE < reserve) {
      return {
        reservePrice = reserve;
        winner = null;
        payment = 0.0;
        virtualBids = sorted;
        expectedRevenueFloor = reserve;
        tradeExecuted = false;
      };
    };
    let payment = maxFloat(reserve, if (sorted.size() > 1) { sorted[1].observedValue } else { reserve });
    {
      reservePrice = reserve;
      winner = ?sorted[0].bidderId;
      payment = payment;
      virtualBids = sorted;
      expectedRevenueFloor = reserve;
      tradeExecuted = true;
    }
  };

  func findOutcome(game : NPlayerGame, targetActions : [Nat]) : ?NPlayerOutcome {
    Array.find<NPlayerOutcome>(game.outcomes, func(outcome) {
      if (outcome.actions.size() != targetActions.size()) {
        false
      } else {
        var match = true;
        var i : Nat = 0;
        while (i < targetActions.size()) {
          if (outcome.actions[i] != targetActions[i]) {
            match := false;
          };
          i += 1;
        };
        match
      }
    })
  };

  public func detectDominantStrategies(game : NPlayerGame) : [DominantStrategyResult] {
    Array.tabulate<DominantStrategyResult>(game.playerStrategies.size(), func(player) {
      var strictStrategies : [Nat] = [];
      var weakStrategies : [Nat] = [];
      var action : Nat = 0;
      while (action < game.playerStrategies[player].size()) {
        var dominatesWeakly = true;
        var dominatesStrictly = true;
        var alt : Nat = 0;
        while (alt < game.playerStrategies[player].size()) {
          if (action != alt) {
            for (outcome in game.outcomes.vals()) {
              if (player < outcome.actions.size() and outcome.actions[player] == alt) {
                let comparedActions = Array.tabulate<Nat>(outcome.actions.size(), func(idx) {
                  if (idx == player) { action } else { outcome.actions[idx] }
                });
                switch (findOutcome(game, comparedActions)) {
                  case (?other) {
                    if (other.payoffs[player] + NUMERIC_TOLERANCE < outcome.payoffs[player]) {
                      dominatesWeakly := false;
                      dominatesStrictly := false;
                    } else if (approxEq(other.payoffs[player], outcome.payoffs[player])) {
                      dominatesStrictly := false;
                    };
                  };
                  case null {
                    dominatesWeakly := false;
                    dominatesStrictly := false;
                  };
                };
              };
            };
          };
          alt += 1;
        };
        if (dominatesStrictly) { strictStrategies := Array.append<Nat>(strictStrategies, [action]) };
        if (dominatesWeakly) { weakStrategies := Array.append<Nat>(weakStrategies, [action]) };
        action += 1;
      };
      {
        player = player;
        strictlyDominant = strictStrategies;
        weaklyDominant = weakStrategies;
        recommendedStrategy = if (strictStrategies.size() > 0) { ?strictStrategies[0] } else if (weakStrategies.size() > 0) { ?weakStrategies[0] } else { null };
      }
    })
  };

  public func calculateBestResponses(game : NPlayerGame, profile : [[Float]]) : [BestResponseResult] {
    Array.tabulate<BestResponseResult>(game.playerStrategies.size(), func(player) {
      let values = actionPayoffsNPlayer(game, player, profile);
      {
        player = player;
        bestActions = indicesOfMax(values);
        actionValues = values;
        bestValue = maxValue(values);
      }
    })
  };

  public func analyzeEquilibriumStability(game : NPlayerGame, profile : [[Float]]) : StabilityAnalysis {
    let expected = expectedPayoffVectorNPlayer(game, profile);
    let deviationGains = Array.tabulate<Float>(game.playerStrategies.size(), func(player) {
      let values = actionPayoffsNPlayer(game, player, profile);
      maxValue(values) - expected[player]
    });
    let maxGain = maxValue(deviationGains);
    let score = clamp(1.0 - safeDiv(maxGain, 1.0 + Float.abs(Array.foldLeft<Float, Float>(expected, 0.0, func(acc, x) { acc + x })), 1.0), 0.0, 1.0);
    {
      playerDeviationGains = deviationGains;
      maxDeviationGain = maxGain;
      stabilityScore = score;
      isStable = maxGain <= MIXED_EQUILIBRIUM_TOLERANCE or score >= STRATEGIC_STABILITY_THRESHOLD;
    }
  };

  public func detectStrategicArbitrage(quotes : [MarketQuote]) : [ArbitrageOpportunity] {
    var opportunities : [ArbitrageOpportunity] = [];
    var buyIndex : Nat = 0;
    while (buyIndex < quotes.size()) {
      var sellIndex : Nat = 0;
      while (sellIndex < quotes.size()) {
        let buy = quotes[buyIndex];
        let sell = quotes[sellIndex];
        if (buy.asset == sell.asset and buy.venueId != sell.venueId) {
          let buyPrice = buy.ask * (1.0 + buy.feeBps / 10_000.0);
          let sellPrice = sell.bid * (1.0 - sell.feeBps / 10_000.0);
          let edge = sellPrice - buyPrice;
          if (edge > NUMERIC_TOLERANCE) {
            let quantity = minFloat(buy.availableSize, sell.availableSize);
            let profit = edge * quantity;
            let confidence = clamp(safeDiv(edge, maxFloat(sellPrice, buyPrice), 0.0) * Phi.PHI_2, 0.0, 1.0);
            opportunities := Array.append<ArbitrageOpportunity>(opportunities, [{
              asset = buy.asset;
              buyVenue = buy.venueId;
              sellVenue = sell.venueId;
              quantity = quantity;
              netBuyPrice = buyPrice;
              netSellPrice = sellPrice;
              grossEdge = edge;
              expectedProfit = profit;
              confidence = confidence;
            }]);
          };
        };
        sellIndex += 1;
      };
      buyIndex += 1;
    };
    Array.sort<ArbitrageOpportunity>(opportunities, func(a, b) {
      if (a.expectedProfit > b.expectedProfit) { #less }
      else if (a.expectedProfit < b.expectedProfit) { #greater }
      else { #equal }
    })
  };
}
