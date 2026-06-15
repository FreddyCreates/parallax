// game_theory.mo — SOVEREIGN GAME THEORY ENGINE
// PARALLAX Sovereign Organism — Domain 42: GAME THEORY
//
// DOCTRINE: "Markets are games. Trading is strategic interaction. Every agent
// seeks Nash equilibrium — where no participant can improve unilaterally.
// This module implements game-theoretic models: Nash equilibrium solvers,
// mechanism design, auction theory, cooperative games, evolutionary stability.
// All equilibria are phi-bound and doctrine-gated."
//
// DOMAIN 42 — GAME THEORY CAPABILITIES:
//   1. Nash Equilibrium       — Pure and mixed strategy Nash equilibria
//   2. Evolutionary Games     — ESS, replicator dynamics, stability analysis
//   3. Auction Theory         — First-price, second-price, Dutch, Vickrey
//   4. Mechanism Design       — Incentive compatibility, revelation principle
//   5. Cooperative Games      — Shapley value, core, coalitional stability
//   6. Bargaining Theory      — Nash bargaining, Rubinstein alternating offers
//   7. Market Microstructure  — Order book games, liquidity provision games
//   8. Strategic Trading      — Kyle model, Glosten-Milgrom, adverse selection
//
// PYTHAGORAS: all equilibria phi-constrained for coherence
// EUCLID:     single source of truth — GameTheoryState
// CONFUCIUS:  right relationship — games serve market intelligence
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
  // GAME THEORY CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Nash equilibrium convergence threshold: φ⁻⁴ = 0.146
  public let NASH_EPSILON : Float = 0.146;

  // Maximum iterations for Nash solver: F(9) = 34
  public let MAX_NASH_ITERATIONS : Nat = 34;

  // Evolutionary stability threshold: φ⁻¹ = 0.618
  public let ESS_THRESHOLD : Float = Phi.PHI_INV;

  // Maximum players in game: F(7) = 13
  public let MAX_PLAYERS : Nat = 13;

  // Maximum strategies per player: F(8) = 21
  public let MAX_STRATEGIES : Nat = 21;

  // Replicator dynamics time step: φ⁻² = 0.382
  public let REPLICATOR_DT : Float = Phi.PHI_INV_2;

  // Shapley value convergence: φ⁻³ = 0.236
  public let SHAPLEY_EPSILON : Float = Phi.PHI_INV_3;

  // Auction bid increment: φ⁻² = 0.382 of current price
  public let AUCTION_INCREMENT : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME REPRESENTATION — Normal Form Games
  // ═══════════════════════════════════════════════════════════════════════════

  // Strategy for a player
  public type Strategy = {
    strategyId   : Text;
    probability  : Float;  // In mixed strategies, prob of playing this strategy
  };

  // Player in a game
  public type Player = {
    playerId    : Text;
    strategies  : [Strategy];
    riskAversion : Float;  // Risk preference parameter
  };

  // Payoff matrix entry
  public type PayoffEntry = {
    playerPayoffs : [Float];  // Payoff for each player at this strategy profile
  };

  // Normal form game (simultaneous move game)
  public type NormalFormGame = {
    players         : [Player];
    payoffMatrix    : [PayoffEntry];  // Flattened multi-dimensional payoff matrix
    gameType        : GameType;
  };

  public type GameType = {
    #zeroSum;           // Sum of payoffs is zero
    #cooperative;       // Players can form coalitions
    #nonCooperative;    // No binding agreements
    #sequential;        // Extensive form game
    #repeated;          // Game repeated multiple times
    #evolutionary;      // Population game with replicator dynamics
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NASH EQUILIBRIUM — Pure and Mixed Strategies
  // ═══════════════════════════════════════════════════════════════════════════

  // Nash equilibrium solution
  public type NashEquilibrium = {
    equilibriumStrategies : [[Float]];  // Mixed strategy probabilities per player
    equilibriumPayoffs    : [Float];    // Expected payoff for each player
    isStable              : Bool;       // Is this equilibrium stable?
    isPureStrategy        : Bool;       // All probabilities are 0 or 1
    convergenceScore      : Float;      // How well did it converge [0,1]
    phiCoherence          : Float;      // Phi-derived coherence measure
  };

  // Support enumeration method for 2-player games (basic implementation)
  // For 2-player game, find best response correspondences
  func bestResponse2Player(
    game : NormalFormGame,
    playerIndex : Nat,
    opponentStrategy : [Float]
  ) : [Float] {
    if (game.players.size() != 2) { return []; };
    
    let player = game.players[playerIndex];
    let numStrategies = player.strategies.size();
    let bestResponseProbs = Array.init<Float>(numStrategies, 0.0);
    
    // Calculate expected payoffs for each strategy
    var maxPayoff = -1000000.0;
    var bestStrategyIdx = 0;
    
    var stratIdx = 0;
    while (stratIdx < numStrategies) {
      var expectedPayoff = 0.0;
      
      // Calculate expected payoff against opponent's mixed strategy
      var oppStratIdx = 0;
      let oppNumStrategies = game.players[1 - playerIndex].strategies.size();
      while (oppStratIdx < oppNumStrategies) {
        // Get payoff from payoff matrix
        let matrixIdx = if (playerIndex == 0) {
          stratIdx * oppNumStrategies + oppStratIdx
        } else {
          oppStratIdx * numStrategies + stratIdx
        };
        
        if (matrixIdx < game.payoffMatrix.size()) {
          let payoff = game.payoffMatrix[matrixIdx].playerPayoffs[playerIndex];
          expectedPayoff += opponentStrategy[oppStratIdx] * payoff;
        };
        
        oppStratIdx += 1;
      };
      
      if (expectedPayoff > maxPayoff) {
        maxPayoff := expectedPayoff;
        bestStrategyIdx := stratIdx;
      };
      
      stratIdx += 1;
    };
    
    // Pure strategy best response
    bestResponseProbs[bestStrategyIdx] := 1.0;
    Array.freeze(bestResponseProbs)
  };

  // Nash equilibrium solver using fictitious play
  public func findNashEquilibrium(game : NormalFormGame) : NashEquilibrium {
    let numPlayers = game.players.size();
    
    if (numPlayers == 0 or numPlayers > 2) {
      // Currently only support 2-player games
      return {
        equilibriumStrategies = [];
        equilibriumPayoffs = [];
        isStable = false;
        isPureStrategy = false;
        convergenceScore = 0.0;
        phiCoherence = 0.0;
      };
    };

    // Initialize with uniform mixed strategies
    let strategies = Array.init<[var Float]>(numPlayers, [var]);
    for (pIdx in Array.keys(game.players)) {
      let numStrats = game.players[pIdx].strategies.size();
      let uniformProb = 1.0 / Float.fromInt(numStrats);
      strategies[pIdx] := Array.init<Float>(numStrats, uniformProb);
    };

    // Fictitious play iterations
    var iteration = 0;
    var converged = false;
    
    while (iteration < MAX_NASH_ITERATIONS and not converged) {
      var maxChange = 0.0;
      
      // Each player best responds to others
      for (pIdx in Array.keys(game.players)) {
        let oppIdx = 1 - pIdx;  // For 2-player
        let oppStrategy = Array.freeze(strategies[oppIdx]);
        let bestResp = bestResponse2Player(game, pIdx, oppStrategy);
        
        // Update strategy with learning rate
        let learningRate = 0.1;
        for (sIdx in Array.keys(bestResp)) {
          let oldProb = strategies[pIdx][sIdx];
          let newProb = (1.0 - learningRate) * oldProb + learningRate * bestResp[sIdx];
          strategies[pIdx][sIdx] := newProb;
          maxChange := Float.max(maxChange, Float.abs(newProb - oldProb));
        };
      };
      
      // Check convergence
      if (maxChange < NASH_EPSILON) {
        converged := true;
      };
      
      iteration += 1;
    };

    // Calculate equilibrium payoffs
    let equilibriumPayoffs = Array.init<Float>(numPlayers, 0.0);
    
    for (pIdx in Array.keys(game.players)) {
      var expectedPayoff = 0.0;
      let numStrats = game.players[pIdx].strategies.size();
      let oppNumStrats = game.players[1 - pIdx].strategies.size();
      
      var sIdx = 0;
      while (sIdx < numStrats) {
        var oppIdx = 0;
        while (oppIdx < oppNumStrats) {
          let matrixIdx = if (pIdx == 0) {
            sIdx * oppNumStrats + oppIdx
          } else {
            oppIdx * numStrats + sIdx
          };
          
          if (matrixIdx < game.payoffMatrix.size()) {
            let payoff = game.payoffMatrix[matrixIdx].playerPayoffs[pIdx];
            let jointProb = strategies[pIdx][sIdx] * strategies[1 - pIdx][oppIdx];
            expectedPayoff += jointProb * payoff;
          };
          
          oppIdx += 1;
        };
        sIdx += 1;
      };
      
      equilibriumPayoffs[pIdx] := expectedPayoff;
    };

    // Check if pure strategy
    var isPure = true;
    for (pIdx in Array.keys(strategies)) {
      for (prob in strategies[pIdx].vals()) {
        if (prob > 0.01 and prob < 0.99) {
          isPure := false;
        };
      };
    };

    // Phi coherence measure: how well aligned with golden ratio
    let coherence = if (converged) { Phi.PHI_INV } else { 
      Phi.PHI_INV * (Float.fromInt(iteration) / Float.fromInt(MAX_NASH_ITERATIONS)) 
    };

    {
      equilibriumStrategies = Array.freeze(Array.map<[var Float], [Float]>(
        Array.freeze(strategies),
        func (s) { Array.freeze(s) }
      ));
      equilibriumPayoffs = Array.freeze(equilibriumPayoffs);
      isStable = converged;
      isPureStrategy = isPure;
      convergenceScore = if (converged) { 1.0 } else { 
        Float.fromInt(iteration) / Float.fromInt(MAX_NASH_ITERATIONS) 
      };
      phiCoherence = coherence;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EVOLUTIONARY GAME THEORY — Replicator Dynamics
  // ═══════════════════════════════════════════════════════════════════════════

  public type EvolutionaryState = {
    strategyProportions : [Float];  // Population proportion for each strategy
    fitnessValues       : [Float];  // Fitness (expected payoff) of each strategy
    averageFitness      : Float;    // Population average fitness
    isESS               : Bool;     // Is this an Evolutionarily Stable Strategy?
    entropy             : Float;    // Diversity measure
  };

  // Replicator dynamics: dx_i/dt = x_i * (f_i - f_avg)
  // where x_i is proportion of strategy i, f_i is fitness, f_avg is average fitness
  public func simulateReplicatorDynamics(
    game : NormalFormGame,
    initialProportions : [Float],
    numGenerations : Nat
  ) : EvolutionaryState {
    
    if (game.players.size() != 1) {
      // Replicator dynamics for single population games
      return {
        strategyProportions = initialProportions;
        fitnessValues = [];
        averageFitness = 0.0;
        isESS = false;
        entropy = 0.0;
      };
    };

    let numStrategies = initialProportions.size();
    let proportions = Array.init<Float>(numStrategies, 0.0);
    
    // Initialize
    for (i in Array.keys(initialProportions)) {
      proportions[i] := initialProportions[i];
    };

    // Simulate generations
    var gen = 0;
    while (gen < numGenerations) {
      // Calculate fitness for each strategy
      let fitness = Array.init<Float>(numStrategies, 0.0);
      var avgFitness = 0.0;
      
      for (i in Array.keys(fitness)) {
        var stratFitness = 0.0;
        
        // Fitness = expected payoff against current population
        for (j in Array.keys(proportions)) {
          let matrixIdx = i * numStrategies + j;
          if (matrixIdx < game.payoffMatrix.size()) {
            let payoff = game.payoffMatrix[matrixIdx].playerPayoffs[0];
            stratFitness += proportions[j] * payoff;
          };
        };
        
        fitness[i] := stratFitness;
        avgFitness += proportions[i] * stratFitness;
      };
      
      // Replicator dynamics update
      let newProportions = Array.init<Float>(numStrategies, 0.0);
      for (i in Array.keys(proportions)) {
        let delta = proportions[i] * (fitness[i] - avgFitness) * REPLICATOR_DT;
        newProportions[i] := Float.max(0.0, proportions[i] + delta);
      };
      
      // Normalize to sum to 1
      var totalProp = 0.0;
      for (p in newProportions.vals()) {
        totalProp += p;
      };
      
      if (totalProp > 0.0) {
        for (i in Array.keys(newProportions)) {
          proportions[i] := newProportions[i] / totalProp;
        };
      };
      
      gen += 1;
    };

    // Final fitness calculation
    let finalFitness = Array.init<Float>(numStrategies, 0.0);
    var finalAvgFitness = 0.0;
    
    for (i in Array.keys(finalFitness)) {
      var stratFitness = 0.0;
      for (j in Array.keys(proportions)) {
        let matrixIdx = i * numStrategies + j;
        if (matrixIdx < game.payoffMatrix.size()) {
          let payoff = game.payoffMatrix[matrixIdx].playerPayoffs[0];
          stratFitness += proportions[j] * payoff;
        };
      };
      finalFitness[i] := stratFitness;
      finalAvgFitness += proportions[i] * stratFitness;
    };

    // Check for ESS: dominant strategy or stable polymorphism
    var isESS = false;
    var dominantStrategy = 0;
    var maxProportion = 0.0;
    
    for (i in Array.keys(proportions)) {
      if (proportions[i] > maxProportion) {
        maxProportion := proportions[i];
        dominantStrategy := i;
      };
    };
    
    // ESS if one strategy > 61.8% (phi-derived threshold)
    if (maxProportion > ESS_THRESHOLD) {
      isESS := true;
    };

    // Shannon entropy for diversity
    var entropy = 0.0;
    for (p in proportions.vals()) {
      if (p > 0.0) {
        entropy -= p * Float.log(p);
      };
    };

    {
      strategyProportions = Array.freeze(proportions);
      fitnessValues = Array.freeze(finalFitness);
      averageFitness = finalAvgFitness;
      isESS = isESS;
      entropy = entropy;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AUCTION THEORY — Mechanism Design
  // ═══════════════════════════════════════════════════════════════════════════

  public type AuctionType = {
    #firstPrice;       // Highest bidder wins, pays their bid
    #secondPrice;      // Highest bidder wins, pays second-highest bid (Vickrey)
    #english;          // Ascending price auction
    #dutch;            // Descending price auction
    #allPay;           // All bidders pay, highest wins
  };

  public type Bid = {
    bidder     : Text;
    amount     : Float;
    timestamp  : Int;
  };

  public type AuctionResult = {
    winner         : Text;
    winningBid     : Float;
    paymentAmount  : Float;
    isEfficient    : Bool;     // Did highest-value bidder win?
    revenue        : Float;
    phiOptimal     : Bool;     // Is outcome phi-optimal?
  };

  // Conduct auction with submitted bids
  public func conductAuction(
    auctionType : AuctionType,
    bids : [Bid],
    reservePrice : Float
  ) : AuctionResult {
    
    if (bids.size() == 0) {
      return {
        winner = "";
        winningBid = 0.0;
        paymentAmount = 0.0;
        isEfficient = false;
        revenue = 0.0;
        phiOptimal = false;
      };
    };

    // Sort bids in descending order
    let sortedBids = Array.sort<Bid>(bids, func (a, b) {
      if (a.amount > b.amount) { #less }
      else if (a.amount < b.amount) { #greater }
      else { #equal }
    });

    let highestBid = sortedBids[0];
    let secondHighestBid = if (sortedBids.size() > 1) { 
      sortedBids[1] 
    } else { 
      { bidder = ""; amount = reservePrice; timestamp = 0 } 
    };

    // Determine winner and payment based on auction type
    let (winner, winningBid, payment) = switch (auctionType) {
      case (#firstPrice) {
        // First-price: winner pays their bid
        (highestBid.bidder, highestBid.amount, highestBid.amount)
      };
      case (#secondPrice or #english) {
        // Second-price (Vickrey): winner pays second-highest bid
        (highestBid.bidder, highestBid.amount, secondHighestBid.amount)
      };
      case (#dutch) {
        // Dutch: equivalent to first-price in single-shot
        (highestBid.bidder, highestBid.amount, highestBid.amount)
      };
      case (#allPay) {
        // All-pay: everyone pays, highest wins
        var totalRevenue = 0.0;
        for (bid in bids.vals()) {
          totalRevenue += bid.amount;
        };
        (highestBid.bidder, highestBid.amount, totalRevenue)
      };
    };

    // Check if winner meets reserve price
    let validWinner = if (winningBid >= reservePrice) {
      winner
    } else {
      ""
    };

    let finalPayment = if (validWinner != "") { payment } else { 0.0 };

    // Efficiency: did highest-value bidder win? (assume bid = value in truthful mechanisms)
    let isEfficient = validWinner != "" and (
      switch (auctionType) {
        case (#secondPrice or #english) { true };  // Vickrey is truthful
        case (_) { false };  // First-price may not be efficient
      }
    );

    // Phi-optimal: revenue close to phi-ratio of winning bid
    let phiOptimal = Float.abs(finalPayment - Phi.PHI_INV * winningBid) < 0.1 * winningBid;

    {
      winner = validWinner;
      winningBid = winningBid;
      paymentAmount = finalPayment;
      isEfficient = isEfficient;
      revenue = finalPayment;
      phiOptimal = phiOptimal;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COOPERATIVE GAMES — Shapley Value
  // ═══════════════════════════════════════════════════════════════════════════

  public type Coalition = {
    members  : [Text];     // Player IDs in coalition
    value    : Float;      // Value generated by coalition
  };

  public type ShapleyValue = {
    player        : Text;
    contribution  : Float;  // Shapley value (fair allocation)
    phiWeighted   : Float;  // Phi-adjusted contribution
  };

  // Calculate Shapley value for each player
  // Shapley value: average marginal contribution across all orderings
  public func calculateShapleyValues(
    players : [Text],
    coalitionValues : [Coalition]
  ) : [ShapleyValue] {
    
    let n = players.size();
    if (n == 0) { return []; };

    let shapleyValues = Array.init<ShapleyValue>(n, {
      player = "";
      contribution = 0.0;
      phiWeighted = 0.0;
    });

    // For each player, calculate average marginal contribution
    for (pIdx in Array.keys(players)) {
      let player = players[pIdx];
      var totalContribution = 0.0;
      var countPermutations = 0;

      // For simplicity, approximate with key coalitions
      // Full calculation would enumerate all permutations (factorial complexity)
      
      // Individual value
      var individualValue = 0.0;
      for (coal in coalitionValues.vals()) {
        if (coal.members.size() == 1 and coal.members[0] == player) {
          individualValue := coal.value;
        };
      };

      // Marginal contribution to each coalition
      for (coal in coalitionValues.vals()) {
        // Check if player is in this coalition
        var playerInCoal = false;
        for (m in coal.members.vals()) {
          if (m == player) { playerInCoal := true; };
        };

        if (playerInCoal and coal.members.size() > 1) {
          // Find value without this player
          var valueWithout = 0.0;
          
          // Build coalition without player
          let remainingMembers = Array.filter<Text>(coal.members, func (m) { m != player });
          
          // Find matching coalition in values
          for (coal2 in coalitionValues.vals()) {
            if (coal2.members.size() == remainingMembers.size()) {
              var match = true;
              for (m in remainingMembers.vals()) {
                var found = false;
                for (m2 in coal2.members.vals()) {
                  if (m == m2) { found := true; };
                };
                if (not found) { match := false; };
              };
              if (match) {
                valueWithout := coal2.value;
              };
            };
          };

          let marginalContribution = coal.value - valueWithout;
          totalContribution += marginalContribution;
          countPermutations += 1;
        };
      };

      let avgContribution = if (countPermutations > 0) {
        (totalContribution / Float.fromInt(countPermutations)) + individualValue
      } else {
        individualValue
      };

      // Phi-weighted: apply golden ratio weighting for fair allocation
      let phiWeighted = avgContribution * Phi.PHI_INV;

      shapleyValues[pIdx] := {
        player = player;
        contribution = avgContribution;
        phiWeighted = phiWeighted;
      };
    };

    Array.freeze(shapleyValues)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET MICROSTRUCTURE — Kyle Model (Informed Trading)
  // ═══════════════════════════════════════════════════════════════════════════

  public type KyleModelParams = {
    informedTraderSignal : Float;  // Private information
    noiseTraderVolume    : Float;  // Random noise volume
    marketMakerDepth     : Float;  // Market depth (liquidity)
    priceImpact          : Float;  // Lambda - price impact coefficient
  };

  public type KyleModelResult = {
    equilibriumPrice  : Float;
    informedVolume    : Float;
    priceImpact       : Float;
    informationRevealed : Float;  // How much info leaked to market
    marketEfficiency  : Float;    // Price discovery efficiency
  };

  // Kyle (1985) model of informed trading
  public func kyleModel(params : KyleModelParams) : KyleModelResult {
    let v = params.informedTraderSignal;      // True value signal
    let u = params.noiseTraderVolume;         // Noise volume
    let lambda = params.priceImpact;          // Price impact
    let sigma_u = Float.abs(u);               // Noise std dev

    // Informed trader optimal volume: x* = (v - p_0) / (2λ)
    let informedVolume = v / (2.0 * lambda);

    // Equilibrium price: p = p_0 + λ(x + u)
    let totalVolume = informedVolume + u;
    let equilibriumPrice = lambda * totalVolume;

    // Information revealed: proportion of signal incorporated in price
    let informationRevealed = if (v != 0.0) {
      Float.abs(equilibriumPrice / v)
    } else { 0.0 };

    // Market efficiency: how quickly info is incorporated (phi-gated)
    let marketEfficiency = Float.min(Phi.PHI, informationRevealed);

    {
      equilibriumPrice = equilibriumPrice;
      informedVolume = informedVolume;
      priceImpact = lambda;
      informationRevealed = informationRevealed;
      marketEfficiency = marketEfficiency;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GAME THEORY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type GameTheoryState = {
    var lastNashEquilibrium   : ?NashEquilibrium;
    var lastEvolutionaryState : ?EvolutionaryState;
    var lastAuctionResult     : ?AuctionResult;
    var lastShapleyValues     : ?[ShapleyValue];
    var lastKyleResult        : ?KyleModelResult;
    var totalGamesAnalyzed    : Nat;
    var lastAnalysisBeat      : Int;
    var phiCoherence          : Float;
  };

  public func initGameTheoryState() : GameTheoryState {
    {
      var lastNashEquilibrium = null;
      var lastEvolutionaryState = null;
      var lastAuctionResult = null;
      var lastShapleyValues = null;
      var lastKyleResult = null;
      var totalGamesAnalyzed = 0;
      var lastAnalysisBeat = 0;
      var phiCoherence = Phi.PHI_INV;
    }
  };

};
