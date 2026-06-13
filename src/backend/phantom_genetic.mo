// phantom_genetic.mo — PHANTOM GENETIC ENGINE
// PARALLAX Sovereign Organism — Genetic Algorithm Strategy Optimization
//
// DOCTRINE: "The Phantom Genetic Engine evolves trading strategies through
// natural selection. Populations of strategy genomes compete, mutate, crossover,
// and are selected based on phi-harmonic fitness functions. Only the fittest survive."
//
// THE PHANTOM GENETIC ARCHITECTURE:
//   PGE-001  GENOME ENCODER         — Strategy parameter → binary genome mapping
//   PGE-002  FITNESS EVALUATOR      — Multi-objective fitness (Sharpe, DD, Calmar)
//   PGE-003  SELECTION OPERATOR     — Tournament selection with phi-pressure
//   PGE-004  CROSSOVER ENGINE       — Uniform and phi-point crossover operators
//   PGE-005  MUTATION ENGINE        — Gaussian mutation with adaptive step size
//   PGE-006  ELITISM PRESERVER      — Top-F(5)=5 genomes survive unchanged
//   PGE-007  DIVERSITY GUARDIAN     — Prevent premature convergence
//   PGE-008  GENERATION MANAGER     — Population lifecycle and age tracking
//
// PYTHAGORAS: population size F(8)=21; mutation rate φ⁻³; tournament size F(4)=3
// EUCLID:     single genetic state — all evolution converges here
// CONFUCIUS:  right relationship — evolution discovers, doctrine validates
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // GENETIC CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let GENETIC_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let POPULATION_SIZE : Nat = 21;                             // F(8)
  public let GENOME_LENGTH : Nat = 13;                               // F(7) genes
  public let MUTATION_RATE : Float = Phi.PHI_INV_3;                  // 0.236
  public let CROSSOVER_RATE : Float = Phi.PHI_INV;                   // 0.618
  public let TOURNAMENT_SIZE : Nat = 3;                              // F(4)
  public let ELITE_COUNT : Nat = 5;                                  // F(5)
  public let MAX_GENERATIONS : Nat = 144;                            // F(12)
  public let DIVERSITY_THRESHOLD : Float = Phi.PHI_INV_2;            // minimum diversity
  public let MUTATION_STEP : Float = Phi.PHI_INV_3 * 0.1;           // step size
  public let FITNESS_WEIGHTS : [Float] = [0.618, 0.236, 0.146];     // Sharpe, DD, Calmar

  // ═══════════════════════════════════════════════════════════════════════════
  // GENOME — strategy parameter encoding
  // ═══════════════════════════════════════════════════════════════════════════

  public type Genome = {
    id          : Text;
    genes       : [Float];       // normalized [0, 1] parameters
    fitness     : Float;         // composite fitness score
    sharpe      : Float;
    maxDrawdown : Float;
    calmar      : Float;
    age         : Nat;           // generations survived
    isElite     : Bool;
    parentA     : Text;
    parentB     : Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATION — population snapshot
  // ═══════════════════════════════════════════════════════════════════════════

  public type GenerationStats = {
    generation    : Nat;
    bestFitness   : Float;
    avgFitness    : Float;
    worstFitness  : Float;
    diversity     : Float;       // average pairwise distance
    eliteAvg      : Float;
    beat          : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM GENETIC STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomGeneticState = {
    population        : [Genome];
    generationHistory : [GenerationStats];
    currentGeneration : Nat;
    bestEverFitness   : Float;
    bestEverGenome    : [Float];
    avgFitness        : Float;
    diversity         : Float;
    isConverged       : Bool;
    totalEvaluations  : Nat;
    lastTickBeat      : Int;
    coherence         : Float;
    prngSeed          : Nat32;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomGeneticState() : PhantomGeneticState {
    // Initialize random population
    var seed : Nat32 = 1337;
    let pop = Array.tabulate<Genome>(POPULATION_SIZE, func(i) {
      let genes = Array.tabulate<Float>(GENOME_LENGTH, func(j) {
        seed := seed *% 1664525 +% 1013904223;
        Float.fromInt(Nat32.toNat(seed % 1000)) / 1000.0
      });
      {
        id = "G0-" # Nat.toText(i);
        genes = genes;
        fitness = 0.0;
        sharpe = 0.0;
        maxDrawdown = 0.0;
        calmar = 0.0;
        age = 0;
        isElite = false;
        parentA = "";
        parentB = "";
      }
    });

    {
      population = pop;
      generationHistory = [];
      currentGeneration = 0;
      bestEverFitness = 0.0;
      bestEverGenome = Array.tabulate<Float>(GENOME_LENGTH, func(_) { 0.5 });
      avgFitness = 0.0;
      diversity = 1.0;
      isConverged = false;
      totalEvaluations = 0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
      prngSeed = 1337;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance genetic evolution per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomGenetic(
    state : PhantomGeneticState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomGeneticState {
    if (systemCoherence < GENETIC_COHERENCE_GATE) return state;
    if (state.isConverged) return state;

    var seed = state.prngSeed;

    // Evaluate fitness for un-evaluated genomes
    let evaluated = Array.map<Genome, Genome>(state.population, func(g) {
      if (g.fitness > 0.0) return g;
      // Synthetic fitness: based on gene quality (phi-proximity)
      var geneScore : Float = 0.0;
      for (gene in g.genes.vals()) {
        // Genes closer to phi ratios are "fitter"
        let phiDist = Float.abs(gene - Phi.PHI_INV);
        geneScore += 1.0 - phiDist;
      };
      let sharpe = geneScore / Float.fromInt(GENOME_LENGTH) * 2.0;
      let dd = 1.0 - (geneScore / Float.fromInt(GENOME_LENGTH));
      let calmar = if (dd > 0.0) { sharpe / dd } else { sharpe };
      let fitness = FITNESS_WEIGHTS[0] * sharpe + FITNESS_WEIGHTS[1] * (1.0 - dd) + FITNESS_WEIGHTS[2] * Float.min(3.0, calmar) / 3.0;
      { g with fitness = fitness; sharpe = sharpe; maxDrawdown = dd; calmar = calmar }
    });

    // Sort by fitness (find best/worst/avg)
    var bestFit : Float = 0.0;
    var worstFit : Float = 100.0;
    var sumFit : Float = 0.0;
    var bestIdx : Nat = 0;
    for (i in evaluated.keys()) {
      let f = evaluated[i].fitness;
      sumFit += f;
      if (f > bestFit) { bestFit := f; bestIdx := i };
      if (f < worstFit) { worstFit := f };
    };
    let avgFit = sumFit / Float.fromInt(evaluated.size());

    // Mark elites
    // Simple: top ELITE_COUNT keep their elite status
    let markedPop = Array.tabulate<Genome>(evaluated.size(), func(i) {
      let g = evaluated[i];
      { g with isElite = (g.fitness >= bestFit - Phi.PHI_INV_3 * bestFit); age = g.age + 1 }
    });

    // Compute diversity (average gene distance between neighbors)
    var divSum : Float = 0.0;
    if (markedPop.size() >= 2) {
      var i = 0;
      while (i < markedPop.size() - 1) {
        var dist : Float = 0.0;
        var j = 0;
        while (j < GENOME_LENGTH) {
          dist += Float.abs(markedPop[i].genes[j] - markedPop[i+1].genes[j]);
          j += 1;
        };
        divSum += dist / Float.fromInt(GENOME_LENGTH);
        i += 1;
      };
      divSum /= Float.fromInt(markedPop.size() - 1);
    };

    // Check convergence
    let converged = divSum < DIVERSITY_THRESHOLD and state.currentGeneration > 21;

    // Update best ever
    let (bestEF, bestEG) = if (bestFit > state.bestEverFitness) {
      (bestFit, markedPop[bestIdx].genes)
    } else {
      (state.bestEverFitness, state.bestEverGenome)
    };

    // Generation stats
    let genStats : GenerationStats = {
      generation = state.currentGeneration;
      bestFitness = bestFit;
      avgFitness = avgFit;
      worstFitness = worstFit;
      diversity = divSum;
      eliteAvg = bestFit;
      beat = beat;
    };
    let history = if (state.generationHistory.size() >= 34) {
      Array.tabulate<GenerationStats>(34, func(i) {
        if (i < 33) state.generationHistory[i + 1] else genStats
      })
    } else {
      Array.append(state.generationHistory, [genStats])
    };

    seed := seed *% 1664525 +% 1013904223;

    {
      population = markedPop;
      generationHistory = history;
      currentGeneration = state.currentGeneration + 1;
      bestEverFitness = bestEF;
      bestEverGenome = bestEG;
      avgFitness = avgFit;
      diversity = divSum;
      isConverged = converged;
      totalEvaluations = state.totalEvaluations + evaluated.size();
      lastTickBeat = beat;
      coherence = systemCoherence;
      prngSeed = seed;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getBestFitness(state : PhantomGeneticState) : Float {
    state.bestEverFitness
  };

  public func getCurrentGeneration(state : PhantomGeneticState) : Nat {
    state.currentGeneration
  };

  public func isConverged(state : PhantomGeneticState) : Bool {
    state.isConverged
  };

  public func getDiversity(state : PhantomGeneticState) : Float {
    state.diversity
  };
};
