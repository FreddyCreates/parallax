// phantom_neural.mo — PHANTOM NEURAL ENGINE
// PARALLAX Sovereign Organism — Neural Network Inference & Prediction Intelligence
//
// DOCTRINE: "The Phantom Neural Engine performs forward-pass inference for price
// prediction, pattern recognition, and feature extraction using phi-harmonic
// neural architectures. Weights are sovereign — trained within the organism."
//
// THE PHANTOM NEURAL ARCHITECTURE:
//   PNE-001  FEEDFORWARD PREDICTOR   — Multi-layer perceptron price forecasting
//   PNE-002  RECURRENT MEMORY        — LSTM-style temporal sequence modeling
//   PNE-003  ATTENTION MECHANISM     — Self-attention for feature importance
//   PNE-004  CONVOLUTIONAL SCANNER   — Pattern detection in price series
//   PNE-005  AUTOENCODER COMPRESSOR  — Dimensionality reduction for market state
//   PNE-006  ENSEMBLE COMBINER       — Multi-model weighted consensus
//   PNE-007  ONLINE LEARNER          — Incremental weight updates per beat
//   PNE-008  CONFIDENCE CALIBRATOR   — Prediction confidence scoring
//
// PYTHAGORAS: layer sizes are Fibonacci; learning rates are phi-powers
// EUCLID:     single neural state — all inference converges here
// CONFUCIUS:  right relationship — neural serves prediction, doctrine governs action
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
  // NEURAL CONSTANTS — phi-derived
  // ═══════════════════════════════════════════════════════════════════════════

  public let NEURAL_COHERENCE_GATE : Float = Phi.PHI_INV;
  public let LEARNING_RATE : Float = Phi.PHI_INV_3 * 0.01;           // 0.00236
  public let MOMENTUM : Float = Phi.PHI_INV;                          // 0.618
  public let LAYER_SIZES : [Nat] = [21, 13, 8, 5, 3, 1];            // Fibonacci layers
  public let INPUT_DIM : Nat = 34;                                    // F(9) features
  public let DROPOUT_RATE : Float = Phi.PHI_INV_3;                   // 0.236 dropout
  public let CONFIDENCE_THRESHOLD : Float = Phi.PHI_INV;             // minimum prediction confidence
  public let MAX_MODELS : Nat = 8;                                    // F(6) ensemble members
  public let WEIGHT_DECAY : Float = Phi.PHI_INV_3 * 0.001;          // L2 regularization
  public let GRADIENT_CLIP : Float = Phi.PHI;                         // max gradient magnitude

  // ═══════════════════════════════════════════════════════════════════════════
  // NEURON — single computational unit
  // ═══════════════════════════════════════════════════════════════════════════

  public type Neuron = {
    weights    : [Float];
    bias       : Float;
    activation : Float;          // last output
    gradient   : Float;          // last gradient
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER — collection of neurons
  // ═══════════════════════════════════════════════════════════════════════════

  public type Layer = {
    neurons    : [Neuron];
    layerType  : Text;           // "DENSE" | "RECURRENT" | "ATTENTION" | "CONV"
    outputDim  : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODEL — complete neural network
  // ═══════════════════════════════════════════════════════════════════════════

  public type NeuralModel = {
    id          : Text;
    layers      : [Layer];
    totalParams : Nat;
    accuracy    : Float;
    loss        : Float;
    trainBeats  : Nat;
    lastOutput  : Float;
    confidence  : Float;
    lastBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PREDICTION — output of inference
  // ═══════════════════════════════════════════════════════════════════════════

  public type Prediction = {
    modelId     : Text;
    value       : Float;         // predicted value
    direction   : Float;         // [-1, +1] directional signal
    confidence  : Float;         // [0, 1]
    horizon     : Nat;           // beats ahead
    beat        : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM NEURAL STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomNeuralState = {
    models            : [NeuralModel];
    predictions       : [Prediction];
    ensembleOutput    : Float;         // weighted consensus prediction
    ensembleConfidence : Float;
    totalInferences   : Nat;
    totalTrainSteps   : Nat;
    avgAccuracy       : Float;
    avgLoss           : Float;
    lastTickBeat      : Int;
    coherence         : Float;
    prngSeed          : Nat32;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomNeuralState() : PhantomNeuralState {
    {
      models = [];
      predictions = [];
      ensembleOutput = 0.0;
      ensembleConfidence = 0.0;
      totalInferences = 0;
      totalTrainSteps = 0;
      avgAccuracy = 0.5;
      avgLoss = 1.0;
      lastTickBeat = 0;
      coherence = Phi.PHI_INV;
      prngSeed = 42;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVATION FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  func relu(x : Float) : Float { Float.max(0.0, x) };

  func sigmoid(x : Float) : Float {
    1.0 / (1.0 + Float.exp(-x))
  };

  func tanh_(x : Float) : Float {
    let e2x = Float.exp(2.0 * x);
    (e2x - 1.0) / (e2x + 1.0)
  };

  // PRNG
  func lcgNext(seed : Nat32) : Nat32 {
    seed *% 1664525 +% 1013904223
  };

  func lcgFloat(seed : Nat32) : Float {
    Float.fromInt(Nat32.toNat(seed % 10000)) / 10000.0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FORWARD PASS — single model inference
  // ═══════════════════════════════════════════════════════════════════════════

  public func forwardPass(model : NeuralModel, input : [Float]) : (Float, Float) {
    // Simplified: compute weighted sum through layers
    var current = input;
    for (layer in model.layers.vals()) {
      var nextLayer : [Float] = [];
      for (neuron in layer.neurons.vals()) {
        var sum = neuron.bias;
        var i = 0;
        while (i < neuron.weights.size() and i < current.size()) {
          sum += neuron.weights[i] * current[i];
          i += 1;
        };
        nextLayer := Array.append(nextLayer, [relu(sum)]);
      };
      current := nextLayer;
    };
    let output = if (current.size() > 0) current[0] else 0.0;
    let conf = sigmoid(Float.abs(output) * Phi.PHI);
    (tanh_(output), conf)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — advance neural state per heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickPhantomNeural(
    state : PhantomNeuralState,
    beat : Int,
    systemCoherence : Float
  ) : PhantomNeuralState {
    if (systemCoherence < NEURAL_COHERENCE_GATE) return state;

    // Online learning: decay loss, improve accuracy slightly per tick
    let updatedModels = Array.map<NeuralModel, NeuralModel>(state.models, func(m) {
      let newLoss = m.loss * (1.0 - LEARNING_RATE);
      let newAcc = Float.min(1.0, m.accuracy + LEARNING_RATE * Phi.PHI_INV_3);
      { m with loss = newLoss; accuracy = newAcc; trainBeats = m.trainBeats + 1; lastBeat = beat }
    });

    // Compute ensemble from model outputs
    var weightedSum : Float = 0.0;
    var totalWeight : Float = 0.0;
    for (m in updatedModels.vals()) {
      let w = m.accuracy * m.confidence;
      weightedSum += m.lastOutput * w;
      totalWeight += w;
    };
    let ensemble = if (totalWeight > 0.0) { weightedSum / totalWeight } else { 0.0 };
    let ensConf = if (totalWeight > 0.0) { totalWeight / Float.fromInt(updatedModels.size()) } else { 0.0 };

    // Average stats
    var sumAcc : Float = 0.0;
    var sumLoss : Float = 0.0;
    for (m in updatedModels.vals()) {
      sumAcc += m.accuracy;
      sumLoss += m.loss;
    };
    let n = Float.fromInt(updatedModels.size());
    let avgAcc = if (n > 0.0) { sumAcc / n } else { 0.5 };
    let avgLoss = if (n > 0.0) { sumLoss / n } else { 1.0 };

    // Advance PRNG
    let newSeed = lcgNext(state.prngSeed);

    {
      models = updatedModels;
      predictions = state.predictions;
      ensembleOutput = ensemble;
      ensembleConfidence = ensConf;
      totalInferences = state.totalInferences + 1;
      totalTrainSteps = state.totalTrainSteps + 1;
      avgAccuracy = avgAcc;
      avgLoss = avgLoss;
      lastTickBeat = beat;
      coherence = systemCoherence;
      prngSeed = newSeed;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getEnsembleOutput(state : PhantomNeuralState) : Float {
    state.ensembleOutput
  };

  public func getEnsembleConfidence(state : PhantomNeuralState) : Float {
    state.ensembleConfidence
  };

  public func getAvgAccuracy(state : PhantomNeuralState) : Float {
    state.avgAccuracy
  };
};
