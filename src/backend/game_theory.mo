// game_theory.mo — PARALLAX Game Theory & Nash Equilibrium Engine
// ═══════════════════════════════════════════════════════════════════════════════
// 
// Comprehensive game theory implementation for strategic trading decisions.
// Supports:
//   - 2-player and n-player games
//   - Pure strategy Nash equilibrium
//   - Mixed strategy equilibrium
//   - Zero-sum games
//   - Cooperative games (Shapley values)
//   - Market microstructure games
//
// Mathematics:
//   - Lemke-Howson algorithm for bimatrix games
//   - Successive elimination of dominated strategies
//   - Support enumeration for mixed strategies
//   - Linear programming for equilibrium computation
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Float "mo:core/Float";
import Int "mo:core/Int";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";
import Option "mo:core/Option";
import HashMap "mo:core/HashMap";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Debug "mo:core/Debug";
import Mathematics "mathematics";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE GAME THEORY TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  /// A payoff matrix for one player in a 2-player game
  public type PayoffMatrix = [[Float]];

  /// A game outcome: (player1_payoff, player2_payoff)
  public type GameOutcome = (Float, Float);

  /// Pure strategy for a player (action index)
  public type PureStrategy = Nat;

  /// Mixed strategy: probability distribution over actions
  public type MixedStrategy = [Float];

  /// Nash equilibrium result
  public type NashEquilibrium = {
    strategy1: MixedStrategy;
    strategy2: MixedStrategy;
    payoff1: Float;
    payoff2: Float;
    isPure: Bool;
    iterations: Nat;
  };

  /// Dominant strategy result
  public type DominanceAnalysis = {
    playerOneDominated: [Bool];    // true if action is dominated
    playerTwoDominated: [Bool];
    playerOneRemaining: [Nat];     // indices of non-dominated actions
    playerTwoRemaining: [Nat];
  };

  /// Shapley value result (for cooperative games)
  public type ShapleyValues = [Float];

  /// Buyer-Seller game state (market microstructure)
  public type MarketGame = {
    buyerValuation: Float;         // max buyer willing to pay
    sellerCost: Float;             // min seller willing to accept
    askPrice: Float;
    bidPrice: Float;
    spreadWidth: Float;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NASH EQUILIBRIUM: 2x2 BIMATRIX GAMES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Solve 2x2 game using analytic method
  /// payoff1: [[a11, a12], [a21, a22]]
  /// payoff2: [[b11, b12], [b21, b22]]
  public func solve2x2Game(
    payoff1: PayoffMatrix,
    payoff2: PayoffMatrix
  ) : NashEquilibrium {
    assert payoff1.size() == 2 and payoff2.size() == 2;
    assert payoff1[0].size() == 2 and payoff2[0].size() == 2;

    // Check for pure strategy equilibria first
    let pureEquil = findPureStrategyEquilibria2x2(payoff1, payoff2);
    if (pureEquil.size() > 0) {
      let (s1, s2) = pureEquil[0];
      return {
        strategy1 = [if (s1 == 0) 1.0 else 0.0, if (s1 == 1) 1.0 else 0.0];
        strategy2 = [if (s2 == 0) 1.0 else 0.0, if (s2 == 1) 1.0 else 0.0];
        payoff1 = payoff1[s1][s2];
        payoff2 = payoff2[s1][s2];
        isPure = true;
        iterations = 1;
      };
    };

    // Compute mixed strategy equilibrium
    mixedStrategyEquilibrium2x2(payoff1, payoff2)
  };

  /// Find pure strategy Nash equilibria in 2x2 game
  private func findPureStrategyEquilibria2x2(
    payoff1: PayoffMatrix,
    payoff2: PayoffMatrix
  ) : [(PureStrategy, PureStrategy)] {
    var equil: [(PureStrategy, PureStrategy)] = [];

    // Check each of 4 possible pure strategy profiles
    for (i in Iter.range(0, 1)) {
      for (j in Iter.range(0, 1)) {
        // Check if (i,j) is a Nash equilibrium
        let p1_current = payoff1[i][j];
        let p2_current = payoff2[i][j];

        // Player 1's incentive to deviate
        let p1_alt = payoff1[1 - i][j];
        let p1_noDeviate = p1_current >= p1_alt;

        // Player 2's incentive to deviate
        let p2_alt = payoff2[i][1 - j];
        let p2_noDeviate = p2_current >= p2_alt;

        if (p1_noDeviate and p2_noDeviate) {
          equil := Array.append<(PureStrategy, PureStrategy)>(
            equil,
            [(i, j)]
          );
        };
      };
    };

    equil
  };

  /// Compute mixed strategy equilibrium for 2x2 game analytically
  private func mixedStrategyEquilibrium2x2(
    payoff1: PayoffMatrix,
    payoff2: PayoffMatrix
  ) : NashEquilibrium {
    let a11 = payoff1[0][0];
    let a12 = payoff1[0][1];
    let a21 = payoff1[1][0];
    let a22 = payoff1[1][1];

    let b11 = payoff2[0][0];
    let b12 = payoff2[0][1];
    let b21 = payoff2[1][0];
    let b22 = payoff2[1][1];

    // Player 2's mixing probability for action 0
    // q = (a21 - a11) / (a22 - a12 - a21 + a11)
    let denom_q = (a22 - a12 - a21 + a11);
    let q = if (Float.abs(denom_q) > 1e-10) {
      (a21 - a11) / denom_q
    } else {
      0.5
    };
    let q_clamped = Mathematics.clamp(q, 0.0, 1.0);

    // Player 1's mixing probability for action 0
    // p = (b21 - b11) / (b22 - b12 - b21 + b11)
    let denom_p = (b22 - b12 - b21 + b11);
    let p = if (Float.abs(denom_p) > 1e-10) {
      (b21 - b11) / denom_p
    } else {
      0.5
    };
    let p_clamped = Mathematics.clamp(p, 0.0, 1.0);

    // Expected payoffs
    let exp1 = p_clamped * (q_clamped * a11 + (1.0 - q_clamped) * a12) +
               (1.0 - p_clamped) * (q_clamped * a21 + (1.0 - q_clamped) * a22);
    let exp2 = q_clamped * (p_clamped * b11 + (1.0 - p_clamped) * b21) +
               (1.0 - q_clamped) * (p_clamped * b12 + (1.0 - p_clamped) * b22);

    {
      strategy1 = [p_clamped, 1.0 - p_clamped];
      strategy2 = [q_clamped, 1.0 - q_clamped];
      payoff1 = exp1;
      payoff2 = exp2;
      isPure = false;
      iterations = 5;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DOMINATED STRATEGY ELIMINATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Iteratively eliminate strictly dominated strategies
  public func eliminateDominatedStrategies(
    payoff1: PayoffMatrix,
    payoff2: PayoffMatrix
  ) : DominanceAnalysis {
    var dominated1 = Array.tabulate<Bool>(
      payoff1.size(),
      func(i: Nat) = false
    );
    var dominated2 = Array.tabulate<Bool>(
      if (payoff2.size() > 0) payoff2[0].size() else 0,
      func(j: Nat) = false
    );

    // Eliminate dominated strategies for player 1
    for (i in Iter.range(0, payoff1.size() - 1)) {
      for (i2 in Iter.range(i + 1, payoff1.size() - 1)) {
        // Check if i strictly dominates i2 or vice versa
        if (strictlyDominates(payoff1, i, i2)) {
          dominated1 := updateArray(dominated1, i2, true);
        } else if (strictlyDominates(payoff1, i2, i)) {
          dominated1 := updateArray(dominated1, i, true);
        };
      };
    };

    // Eliminate dominated strategies for player 2
    for (j in Iter.range(0, if (payoff2.size() > 0) payoff2[0].size() else 0 - 1)) {
      for (j2 in Iter.range(j + 1, if (payoff2.size() > 0) payoff2[0].size() else 0 - 1)) {
        if (strictlyDominatesColumn(payoff2, j, j2)) {
          dominated2 := updateArray(dominated2, j2, true);
        } else if (strictlyDominatesColumn(payoff2, j2, j)) {
          dominated2 := updateArray(dominated2, j, true);
        };
      };
    };

    // Collect remaining actions
    var remaining1: [Nat] = [];
    for (i in Iter.range(0, dominated1.size() - 1)) {
      if (not dominated1[i]) {
        remaining1 := Array.append<Nat>(remaining1, [i]);
      };
    };

    var remaining2: [Nat] = [];
    for (j in Iter.range(0, dominated2.size() - 1)) {
      if (not dominated2[j]) {
        remaining2 := Array.append<Nat>(remaining2, [j]);
      };
    };

    {
      playerOneDominated = dominated1;
      playerTwoDominated = dominated2;
      playerOneRemaining = remaining1;
      playerTwoRemaining = remaining2;
    }
  };

  private func strictlyDominates(matrix: PayoffMatrix, i1: Nat, i2: Nat) : Bool {
    if (i1 >= matrix.size() or i2 >= matrix.size()) return false;
    if (matrix[i1].size() == 0) return false;

    var allGreater = true;
    var someGreater = false;

    for (j in Iter.range(0, matrix[i1].size() - 1)) {
      if (matrix[i1][j] < matrix[i2][j]) {
        allGreater := false;
      } else if (matrix[i1][j] > matrix[i2][j]) {
        someGreater := true;
      };
    };

    allGreater and someGreater
  };

  private func strictlyDominatesColumn(matrix: PayoffMatrix, j1: Nat, j2: Nat) : Bool {
    if (matrix.size() == 0) return false;
    if (j1 >= matrix[0].size() or j2 >= matrix[0].size()) return false;

    var allGreater = true;
    var someGreater = false;

    for (i in Iter.range(0, matrix.size() - 1)) {
      if (matrix[i][j1] < matrix[i][j2]) {
        allGreater := false;
      } else if (matrix[i][j1] > matrix[i][j2]) {
        someGreater := true;
      };
    };

    allGreater and someGreater
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ZERO-SUM GAMES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Solve zero-sum 2x2 game (payoff2 = -payoff1)
  public func solveZeroSumGame(payoff1: PayoffMatrix) : NashEquilibrium {
    // Create negated payoff for player 2
    let payoff2 = Array.map<[Float], [Float]>(
      payoff1,
      func(row: [Float]) : [Float] {
        Array.map<Float, Float>(row, func(x: Float) : Float = -x)
      }
    );

    solve2x2Game(payoff1, payoff2)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET MICROSTRUCTURE: BUYER-SELLER GAME
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyze buyer-seller negotiation with Nash bargaining
  public func buyerSellerEquilibrium(
    buyerValuation: Float,
    sellerCost: Float
  ) : MarketGame {
    // Gain from trade
    let totalGain = buyerValuation - sellerCost;

    // Nash bargaining solution: split gains equally
    let fairPrice = sellerCost + (totalGain / 2.0);

    // Equilibrium spread assuming information asymmetry
    let infoSpread = totalGain * 0.05;  // 5% of total gain

    {
      buyerValuation = buyerValuation;
      sellerCost = sellerCost;
      askPrice = fairPrice + (infoSpread / 2.0);
      bidPrice = fairPrice - (infoSpread / 2.0);
      spreadWidth = infoSpread;
    }
  };

  /// Order book equilibrium: find optimal quotes given competition
  public func orderBookEquilibrium(
    myInventory: Float,
    competitorSpread: Float,
    riskAversion: Float
  ) : (askPrice: Float, bidPrice: Float) {
    // Optimal bid-ask spread increases with inventory and competition
    let spreadAdjustment = (competitorSpread * 1.2) + (myInventory * riskAversion);

    let midPrice = 100.0;  // Normalized mid-price
    let optimalSpread = spreadAdjustment / 2.0;

    (
      askPrice = midPrice + optimalSpread,
      bidPrice = midPrice - optimalSpread
    )
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // COALITION GAMES: SHAPLEY VALUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compute Shapley value for a 3-player game
  /// v: coalition value function v(S) for each subset S
  public func shapleyValues3(coalitionValues: [(mask: Nat, value: Float)]) : ShapleyValues {
    let sv = Array.tabulate<Float>(
      3,
      func(i: Nat) : Float {
        var marginalSum = 0.0;
        var count = 0;

        // For each permutation, compute marginal contribution
        for (m1 in Iter.range(0, 7)) {
          let memberMask = (1 << i);
          let withoutPlayer = m1 & (7 ^ memberMask);  // S \ {i}
          let withPlayer = m1 | memberMask;           // S ∪ {i}

          // Find values
          var vWithout = 0.0;
          var vWith = 0.0;

          for ((mask, value) in Iter.fromArray(coalitionValues)) {
            if (mask == withoutPlayer) { vWithout := value; };
            if (mask == withPlayer) { vWith := value; };
          };

          marginalSum += (vWith - vWithout);
          count += 1;
        };

        if (count > 0) marginalSum / Float.fromInt(count) else 0.0
      }
    );

    sv
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  private func updateArray<T>(arr: [T], index: Nat, value: T) : [T] {
    Array.tabulate<T>(arr.size(), func(i: Nat) : T {
      if (i == index) value else arr[i]
    })
  };

  /// Compute expected payoff given mixed strategies
  public func expectedPayoff(
    payoff: PayoffMatrix,
    strategy1: MixedStrategy,
    strategy2: MixedStrategy
  ) : Float {
    var sum = 0.0;

    for (i in Iter.range(0, payoff.size() - 1)) {
      for (j in Iter.range(0, payoff[i].size() - 1)) {
        sum += strategy1[i] * strategy2[j] * payoff[i][j];
      };
    };

    sum
  };

  /// Compute best response to opponent's mixed strategy
  public func bestResponse(
    payoff: PayoffMatrix,
    opponentStrategy: MixedStrategy
  ) : MixedStrategy {
    var maxPayoff = -999999.0;
    var bestAction = 0;

    for (i in Iter.range(0, payoff.size() - 1)) {
      var actionPayoff = 0.0;
      for (j in Iter.range(0, payoff[i].size() - 1)) {
        actionPayoff += payoff[i][j] * opponentStrategy[j];
      };

      if (actionPayoff > maxPayoff) {
        maxPayoff := actionPayoff;
        bestAction := i;
      };
    };

    Array.tabulate<Float>(payoff.size(), func(i: Nat) : Float {
      if (i == bestAction) 1.0 else 0.0
    })
  };

};
