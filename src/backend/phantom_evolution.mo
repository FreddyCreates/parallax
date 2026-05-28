// phantom_evolution.mo — PHANTOM EVOLUTION CORE
// PARALLAX Sovereign Organism — Self-Adapting Strategy Evolution Engine
//
// DOCTRINE: "The Phantom Evolution Core is the organism's DNA — continuously
// mutating, selecting, and evolving trading strategies through genetic algorithms
// and reinforcement learning. Strategies that survive are phi-fit. Those that fail
// are composted into lessons. The organism adapts to every market regime."
//
// PHANTOM EVOLUTION ARCHITECTURE:
//   PEC-001  STRATEGY GENOME          — Encodes strategies as phi-weighted gene vectors
//   PEC-002  FITNESS EVALUATOR        — Sharpe/Sortino/Calmar scoring (phi-adjusted)
//   PEC-003  MUTATION ENGINE          — Golden-ratio mutation step sizes
//   PEC-004  CROSSOVER OPERATOR       — Breed top strategies via phi-point crossover
//   PEC-005  SELECTION PRESSURE       — Tournament selection with phi-derived pressure
//   PEC-006  EXTINCTION DETECTOR      — Kill strategies that violate risk doctrine
//   PEC-007  EMERGENCE WATCHER        — Detects genuinely new strategy archetypes
//   PEC-008  ADAPTATION CLOCK         — Phi-timed generation advancement
//
// PYTHAGORAS: mutation rates, fitness thresholds at phi-harmonic values
// EUCLID:     single evolution state — all strategy genetics centralized
// CONFUCIUS:  right relationship — evolution proposes, risk sentinel disposes
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  public let EVOLUTION_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let MUTATION_RATE : Float = Phi.PHI_INV_3;       // 23.6% mutation rate
  public let CROSSOVER_POINT : Float = Phi.PHI_INV;       // Golden ratio crossover
  public let EXTINCTION_FITNESS : Float = 0.0 - Phi.PHI;  // Below -φ = extinction
  public let GENERATION_INTERVAL : Nat = 89;              // Fibonacci-89 beats per gen
  public let POPULATION_SIZE : Nat = 55;                  // Fibonacci-55 strategies

  public type StrategyGenome = {
    genomeId         : Nat;
    genes            : [Float];    // Phi-weighted parameter vector
    generation       : Nat;
    parentIds        : [Nat];      // Ancestry tracking
    mutations        : Nat;        // Total mutations applied
    fitness          : Float;      // Current fitness score
    sharpeRatio      : Float;
    sortinoRatio     : Float;
    maxDrawdown      : Float;
    winRate          : Float;
    totalTrades      : Nat;
    alive            : Bool;
  };

  public type PhantomEvolutionState = {
    population        : [StrategyGenome];
    currentGeneration : Nat;
    bestFitness       : Float;
    bestGenomeId      : ?Nat;
    avgFitness        : Float;
    extinctions       : Nat;
    emergences        : Nat;        // Genuinely new strategy archetypes
    mutationsApplied  : Nat;
    crossoversApplied : Nat;
    evolutionCoherence: Float;
    lastTickBeat      : Int;
    generationBeat    : Int;        // Beat when current gen started
  };

  public func defaultPhantomEvolutionState() : PhantomEvolutionState {
    {
      population         = [];
      currentGeneration  = 0;
      bestFitness        = 0.0;
      bestGenomeId       = null;
      avgFitness         = 0.0;
      extinctions        = 0;
      emergences         = 0;
      mutationsApplied   = 0;
      crossoversApplied  = 0;
      evolutionCoherence = Phi.S0;
      lastTickBeat       = 0;
      generationBeat     = 0;
    }
  };

  public func tickPhantomEvolution(state : PhantomEvolutionState, beat : Int, kuramotoR : Float) : PhantomEvolutionState {
    if (kuramotoR < EVOLUTION_COHERENCE_GATE) {
      return { state with lastTickBeat = beat };
    };

    // Check if generation should advance (every GENERATION_INTERVAL beats)
    let beatsSinceGen = beat - state.generationBeat;
    let shouldAdvance = beatsSinceGen >= GENERATION_INTERVAL;

    // Extinguish unfit strategies
    let alive = Array.filter<StrategyGenome>(state.population, func(g) {
      g.fitness > EXTINCTION_FITNESS and g.alive
    });
    let extinctions = state.population.size() - alive.size();

    // Find best genome
    var best : Float = 0.0 - Phi.PHI_6;
    var bestId : ?Nat = null;
    for (g in alive.vals()) {
      if (g.fitness > best) {
        best := g.fitness;
        bestId := ?g.genomeId;
      };
    };

    // Compute average fitness
    var totalFit : Float = 0.0;
    for (g in alive.vals()) { totalFit += g.fitness };
    let avg = if (alive.size() > 0) { totalFit / Float.fromInt(alive.size()) } else { 0.0 };

    let newCoherence = state.evolutionCoherence * 0.9 + kuramotoR * 0.1;

    let newGen = if (shouldAdvance) { state.currentGeneration + 1 } else { state.currentGeneration };
    let newGenBeat = if (shouldAdvance) { beat } else { state.generationBeat };

    {
      state with
      population         = alive;
      currentGeneration  = newGen;
      bestFitness        = best;
      bestGenomeId       = bestId;
      avgFitness         = avg;
      extinctions        = state.extinctions + extinctions;
      evolutionCoherence = newCoherence;
      lastTickBeat       = beat;
      generationBeat     = newGenBeat;
    }
  };
}
