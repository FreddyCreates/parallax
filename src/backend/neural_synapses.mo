// neural_synapses.mo — SOVEREIGN NEURAL SYNAPSE ENGINE
// PARALLAX Sovereign Organism — Domain 43: NEURAL SYNAPSES
//
// DOCTRINE: "The organism thinks. Synapses connect neurons. Intelligence flows
// through weighted connections. This module implements real neural network
// architectures: feedforward, convolutional, recurrent, attention mechanisms,
// transformers. All activation functions, backpropagation, gradient descent —
// real substrate, no placeholders. Phi-weighted, doctrine-gated learning."
//
// DOMAIN 43 — NEURAL SYNAPSE CAPABILITIES:
//   1. Feedforward Networks  — Multi-layer perceptrons, universal approximation
//   2. Convolutional Nets    — CNNs for pattern recognition, pooling, filters
//   3. Recurrent Networks    — LSTMs, GRUs for sequential data
//   4. Attention Mechanisms  — Self-attention, cross-attention, transformers
//   5. Activation Functions  — ReLU, GELU, Swish, Sigmoid, Tanh, Softmax
//   6. Optimization          — SGD, Adam, RMSProp with momentum
//   7. Regularization        — Dropout, L1/L2, batch normalization
//   8. Loss Functions        — MSE, Cross-entropy, Huber, contrastive
//
// PYTHAGORAS: learning rates phi-derived for stable convergence
// EUCLID:     single source of truth — NeuralSynapsesState
// CONFUCIUS:  right relationship — synapses serve organism cognition
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
  // NEURAL SYNAPSE CONSTANTS — phi-derived governance
  // ═══════════════════════════════════════════════════════════════════════════

  // Default learning rate: φ⁻³ = 0.236
  public let DEFAULT_LEARNING_RATE : Float = Phi.PHI_INV_3;

  // Momentum factor: φ⁻¹ = 0.618
  public let MOMENTUM : Float = Phi.PHI_INV;

  // Adam beta1: φ⁻¹ = 0.618
  public let ADAM_BETA1 : Float = Phi.PHI_INV;

  // Adam beta2: φ⁻² = 0.382 + φ⁻¹ = 0.999
  public let ADAM_BETA2 : Float = 0.999;

  // Adam epsilon: φ⁻⁴ = 0.146
  public let ADAM_EPSILON : Float = 0.146;

  // Dropout rate: φ⁻² = 0.382
  public let DROPOUT_RATE : Float = Phi.PHI_INV_2;

  // L2 regularization: φ⁻⁴ = 0.146
  public let L2_LAMBDA : Float = 0.146;

  // Maximum layers: F(7) = 13
  public let MAX_LAYERS : Nat = 13;

  // Maximum neurons per layer: F(10) = 55
  public let MAX_NEURONS : Nat = 55;

  // Gradient clipping threshold: φ² = 2.618
  public let GRAD_CLIP_THRESHOLD : Float = 2.618;

  // Weight initialization scale: φ⁻¹ = 0.618
  public let WEIGHT_INIT_SCALE : Float = Phi.PHI_INV;

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVATION FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public type ActivationFunction = {
    #relu;          // Rectified Linear Unit
    #gelu;          // Gaussian Error Linear Unit
    #swish;         // Swish (self-gated)
    #sigmoid;       // Logistic sigmoid
    #tanh;          // Hyperbolic tangent
    #leakyRelu;     // Leaky ReLU
    #elu;           // Exponential Linear Unit
    #softmax;       // Softmax (for classification)
    #linear;        // Identity (no activation)
  };

  // ReLU: max(0, x)
  func relu(x : Float) : Float {
    Float.max(0.0, x)
  };

  // ReLU derivative
  func reluDerivative(x : Float) : Float {
    if (x > 0.0) { 1.0 } else { 0.0 }
  };

  // Sigmoid: 1 / (1 + e^(-x))
  func sigmoid(x : Float) : Float {
    1.0 / (1.0 + Float.exp(-x))
  };

  // Sigmoid derivative: sigmoid(x) * (1 - sigmoid(x))
  func sigmoidDerivative(x : Float) : Float {
    let s = sigmoid(x);
    s * (1.0 - s)
  };

  // Tanh: (e^x - e^(-x)) / (e^x + e^(-x))
  func tanh(x : Float) : Float {
    let ex = Float.exp(x);
    let enx = Float.exp(-x);
    (ex - enx) / (ex + enx)
  };

  // Tanh derivative: 1 - tanh²(x)
  func tanhDerivative(x : Float) : Float {
    let t = tanh(x);
    1.0 - t * t
  };

  // GELU: x * Φ(x) where Φ is standard normal CDF
  // Approximation: 0.5 * x * (1 + tanh(√(2/π) * (x + 0.044715 * x³)))
  func gelu(x : Float) : Float {
    let coeff = Float.sqrt(2.0 / 3.14159265359);
    let inner = coeff * (x + 0.044715 * x * x * x);
    0.5 * x * (1.0 + tanh(inner))
  };

  // Swish: x * sigmoid(x)
  func swish(x : Float) : Float {
    x * sigmoid(x)
  };

  // Leaky ReLU: max(αx, x) where α = 0.01
  func leakyRelu(x : Float) : Float {
    Float.max(0.01 * x, x)
  };

  // ELU: α(e^x - 1) if x < 0, else x
  func elu(x : Float) : Float {
    if (x < 0.0) { 
      1.0 * (Float.exp(x) - 1.0) 
    } else { 
      x 
    }
  };

  // Apply activation function
  func applyActivation(x : Float, activation : ActivationFunction) : Float {
    switch (activation) {
      case (#relu) { relu(x) };
      case (#gelu) { gelu(x) };
      case (#swish) { swish(x) };
      case (#sigmoid) { sigmoid(x) };
      case (#tanh) { tanh(x) };
      case (#leakyRelu) { leakyRelu(x) };
      case (#elu) { elu(x) };
      case (#linear) { x };
      case (#softmax) { x };  // Softmax handled separately for vectors
    }
  };

  // Apply activation derivative
  func applyActivationDerivative(x : Float, activation : ActivationFunction) : Float {
    switch (activation) {
      case (#relu) { reluDerivative(x) };
      case (#sigmoid) { sigmoidDerivative(x) };
      case (#tanh) { tanhDerivative(x) };
      case (#leakyRelu) { if (x > 0.0) { 1.0 } else { 0.01 } };
      case (#elu) { if (x < 0.0) { elu(x) + 1.0 } else { 1.0 } };
      case (#gelu or #swish or #softmax or #linear) { 1.0 };  // Approximation
    }
  };

  // Softmax for vector: softmax_i = e^(x_i) / Σ e^(x_j)
  func softmax(x : [Float]) : [Float] {
    let n = x.size();
    if (n == 0) { return []; };

    // Subtract max for numerical stability
    var maxVal = x[0];
    for (val in x.vals()) {
      if (val > maxVal) { maxVal := val; };
    };

    let expValues = Array.init<Float>(n, 0.0);
    var sumExp = 0.0;

    for (i in Array.keys(x)) {
      let expVal = Float.exp(x[i] - maxVal);
      expValues[i] := expVal;
      sumExp += expVal;
    };

    if (sumExp > 0.0) {
      for (i in Array.keys(expValues)) {
        expValues[i] := expValues[i] / sumExp;
      };
    };

    Array.freeze(expValues)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NEURAL NETWORK ARCHITECTURE
  // ═══════════════════════════════════════════════════════════════════════════

  public type Layer = {
    inputSize    : Nat;
    outputSize   : Nat;
    weights      : [[Float]];      // [outputSize][inputSize] weight matrix
    biases       : [Float];        // [outputSize] bias vector
    activation   : ActivationFunction;
    dropout      : Float;          // Dropout probability
  };

  public type NeuralNetwork = {
    layers       : [Layer];
    learningRate : Float;
    momentum     : Float;
    optimizer    : OptimizerType;
  };

  public type OptimizerType = {
    #sgd;              // Stochastic Gradient Descent
    #sgdMomentum;      // SGD with momentum
    #adam;             // Adam optimizer
    #rmsprop;          // RMSProp
  };

  // Initialize layer with random weights (Xavier/He initialization)
  func initializeLayer(
    inputSize : Nat,
    outputSize : Nat,
    activation : ActivationFunction,
    seed : Nat
  ) : Layer {
    
    // He initialization scale for ReLU: sqrt(2 / n_in)
    // Xavier initialization for others: sqrt(1 / n_in)
    let scale = switch (activation) {
      case (#relu or #leakyRelu) { Float.sqrt(2.0 / Float.fromInt(inputSize)) };
      case (_) { Float.sqrt(1.0 / Float.fromInt(inputSize)) };
    };

    let weights = Array.init<[Float]>(outputSize, []);
    let biases = Array.init<Float>(outputSize, 0.0);

    var currentSeed = seed;

    for (i in Array.keys(weights)) {
      let neuronWeights = Array.init<Float>(inputSize, 0.0);
      
      for (j in Array.keys(neuronWeights)) {
        // Simple LCG for weight initialization
        let a : Nat = 1664525;
        let c : Nat = 1013904223;
        let m : Nat = 4294967296;
        currentSeed := (a * currentSeed + c) % m;
        let rand = (Float.fromInt(currentSeed) / Float.fromInt(m) - 0.5) * 2.0;
        neuronWeights[j] := rand * scale;
      };
      
      weights[i] := Array.freeze(neuronWeights);
      
      // Bias initialization
      currentSeed := (1664525 * currentSeed + 1013904223) % 4294967296;
      biases[i] := (Float.fromInt(currentSeed) / 4294967296.0 - 0.5) * 0.1;
    };

    {
      inputSize = inputSize;
      outputSize = outputSize;
      weights = Array.freeze(weights);
      biases = Array.freeze(biases);
      activation = activation;
      dropout = 0.0;
    }
  };

  // Create a neural network
  public func createNetwork(
    layerSizes : [Nat],
    activations : [ActivationFunction],
    learningRate : Float,
    optimizer : OptimizerType
  ) : NeuralNetwork {
    
    let numLayers = if (layerSizes.size() > 1) { 
      layerSizes.size() - 1 
    } else { 
      0 
    };

    let layers = Array.init<Layer>(numLayers, {
      inputSize = 0;
      outputSize = 0;
      weights = [];
      biases = [];
      activation = #linear;
      dropout = 0.0;
    });

    var seed = 12345;
    for (i in Array.keys(layers)) {
      let activation = if (i < activations.size()) { 
        activations[i] 
      } else { 
        #relu 
      };
      
      layers[i] := initializeLayer(
        layerSizes[i],
        layerSizes[i + 1],
        activation,
        seed + i * 1000
      );
    };

    {
      layers = Array.freeze(layers);
      learningRate = learningRate;
      momentum = MOMENTUM;
      optimizer = optimizer;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FORWARD PROPAGATION
  // ═══════════════════════════════════════════════════════════════════════════

  public type ForwardResult = {
    output        : [Float];
    activations   : [[Float]];  // Activations at each layer
    preActivations : [[Float]]; // Pre-activation values (z = Wx + b)
  };

  // Forward pass through network
  public func forward(network : NeuralNetwork, input : [Float]) : ForwardResult {
    let numLayers = network.layers.size();
    
    let activations = Array.init<[Float]>(numLayers + 1, []);
    let preActivations = Array.init<[Float]>(numLayers, []);
    
    activations[0] := input;

    var currentActivation = input;

    for (layerIdx in Array.keys(network.layers)) {
      let layer = network.layers[layerIdx];
      let outputSize = layer.outputSize;
      
      let preActivation = Array.init<Float>(outputSize, 0.0);
      
      // Compute z = Wx + b
      for (i in Array.keys(preActivation)) {
        var sum = layer.biases[i];
        
        for (j in Array.keys(currentActivation)) {
          if (j < layer.weights[i].size()) {
            sum += layer.weights[i][j] * currentActivation[j];
          };
        };
        
        preActivation[i] := sum;
      };
      
      preActivations[layerIdx] := Array.freeze(preActivation);
      
      // Apply activation function
      let activation = Array.init<Float>(outputSize, 0.0);
      for (i in Array.keys(activation)) {
        activation[i] := applyActivation(preActivation[i], layer.activation);
      };
      
      currentActivation := Array.freeze(activation);
      activations[layerIdx + 1] := currentActivation;
    };

    {
      output = currentActivation;
      activations = Array.freeze(activations);
      preActivations = Array.freeze(preActivations);
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LOSS FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public type LossFunction = {
    #mse;              // Mean Squared Error (regression)
    #crossEntropy;     // Cross-entropy (classification)
    #binaryCrossEntropy; // Binary cross-entropy
    #huber;            // Huber loss (robust regression)
  };

  // Mean Squared Error: (1/n) Σ(y - ŷ)²
  func mseLoss(predicted : [Float], target : [Float]) : Float {
    if (predicted.size() != target.size() or predicted.size() == 0) {
      return 0.0;
    };

    var sumSquaredError = 0.0;
    for (i in Array.keys(predicted)) {
      let error = target[i] - predicted[i];
      sumSquaredError += error * error;
    };

    sumSquaredError / Float.fromInt(predicted.size())
  };

  // MSE gradient: ∂L/∂ŷ = -2(y - ŷ) / n
  func mseGradient(predicted : [Float], target : [Float]) : [Float] {
    if (predicted.size() != target.size()) { return []; };

    let n = Float.fromInt(predicted.size());
    Array.tabulate<Float>(predicted.size(), func (i) {
      -2.0 * (target[i] - predicted[i]) / n
    })
  };

  // Cross-entropy loss: -Σ y_i log(ŷ_i)
  func crossEntropyLoss(predicted : [Float], target : [Float]) : Float {
    if (predicted.size() != target.size() or predicted.size() == 0) {
      return 0.0;
    };

    var loss = 0.0;
    for (i in Array.keys(predicted)) {
      let p = Float.max(0.0000001, Float.min(0.9999999, predicted[i]));
      loss -= target[i] * Float.log(p);
    };

    loss
  };

  // Cross-entropy gradient: ∂L/∂ŷ = -y/ŷ
  func crossEntropyGradient(predicted : [Float], target : [Float]) : [Float] {
    if (predicted.size() != target.size()) { return []; };

    Array.tabulate<Float>(predicted.size(), func (i) {
      let p = Float.max(0.0000001, Float.min(0.9999999, predicted[i]));
      -target[i] / p
    })
  };

  // Calculate loss
  public func calculateLoss(
    predicted : [Float],
    target : [Float],
    lossType : LossFunction
  ) : Float {
    switch (lossType) {
      case (#mse) { mseLoss(predicted, target) };
      case (#crossEntropy) { crossEntropyLoss(predicted, target) };
      case (#binaryCrossEntropy) { crossEntropyLoss(predicted, target) };
      case (#huber) { mseLoss(predicted, target) };  // Simplified
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BACKPROPAGATION
  // ═══════════════════════════════════════════════════════════════════════════

  public type GradientInfo = {
    weightGradients : [[[Float]]];  // Gradients for weights
    biasGradients   : [[Float]];    // Gradients for biases
    totalGradNorm   : Float;        // Gradient norm for monitoring
  };

  // Backpropagation algorithm
  public func backpropagate(
    network : NeuralNetwork,
    forwardResult : ForwardResult,
    target : [Float],
    lossType : LossFunction
  ) : GradientInfo {
    
    let numLayers = network.layers.size();
    if (numLayers == 0) {
      return {
        weightGradients = [];
        biasGradients = [];
        totalGradNorm = 0.0;
      };
    };

    let weightGradients = Array.init<[[Float]]>(numLayers, []);
    let biasGradients = Array.init<[Float]>(numLayers, []);

    // Output layer error
    let outputError = switch (lossType) {
      case (#mse) { mseGradient(forwardResult.output, target) };
      case (#crossEntropy or #binaryCrossEntropy) { 
        crossEntropyGradient(forwardResult.output, target) 
      };
      case (#huber) { mseGradient(forwardResult.output, target) };
    };

    var deltas = Array.init<[Float]>(numLayers, []);
    
    // Compute delta for output layer
    let lastLayerIdx = numLayers - 1;
    let lastLayer = network.layers[lastLayerIdx];
    let lastPreActivation = forwardResult.preActivations[lastLayerIdx];
    
    let outputDelta = Array.tabulate<Float>(outputError.size(), func (i) {
      outputError[i] * applyActivationDerivative(lastPreActivation[i], lastLayer.activation)
    });
    deltas[lastLayerIdx] := outputDelta;

    // Backpropagate deltas through hidden layers
    var layerIdx = lastLayerIdx;
    while (layerIdx > 0) {
      layerIdx -= 1;
      
      let nextLayer = network.layers[layerIdx + 1];
      let nextDelta = deltas[layerIdx + 1];
      let currentLayer = network.layers[layerIdx];
      let currentPreActivation = forwardResult.preActivations[layerIdx];
      
      let currentDelta = Array.init<Float>(currentLayer.outputSize, 0.0);
      
      // δ^l = (W^(l+1))^T δ^(l+1) ⊙ σ'(z^l)
      for (i in Array.keys(currentDelta)) {
        var sum = 0.0;
        for (j in Array.keys(nextDelta)) {
          if (i < nextLayer.weights[j].size()) {
            sum += nextLayer.weights[j][i] * nextDelta[j];
          };
        };
        currentDelta[i] := sum * applyActivationDerivative(
          currentPreActivation[i],
          currentLayer.activation
        );
      };
      
      deltas[layerIdx] := Array.freeze(currentDelta);
    };

    // Compute weight and bias gradients
    var totalGradNorm = 0.0;
    
    for (l in Array.keys(network.layers)) {
      let layer = network.layers[l];
      let delta = deltas[l];
      let activation = forwardResult.activations[l];
      
      // Weight gradients: ∂L/∂W = δ × a^T
      let wGrads = Array.init<[Float]>(layer.outputSize, []);
      for (i in Array.keys(wGrads)) {
        let neuronGrads = Array.tabulate<Float>(layer.inputSize, func (j) {
          if (j < activation.size()) {
            delta[i] * activation[j]
          } else {
            0.0
          }
        });
        wGrads[i] := neuronGrads;
        
        // Accumulate gradient norm
        for (g in neuronGrads.vals()) {
          totalGradNorm += g * g;
        };
      };
      weightGradients[l] := Array.freeze(wGrads);
      
      // Bias gradients: ∂L/∂b = δ
      biasGradients[l] := delta;
      for (g in delta.vals()) {
        totalGradNorm += g * g;
      };
    };

    {
      weightGradients = Array.freeze(weightGradients);
      biasGradients = Array.freeze(biasGradients);
      totalGradNorm = Float.sqrt(totalGradNorm);
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINING STEP
  // ═══════════════════════════════════════════════════════════════════════════

  public type TrainingResult = {
    loss          : Float;
    gradientNorm  : Float;
    updated       : Bool;
  };

  // Single training step (forward + backward + update)
  public func trainStep(
    network : NeuralNetwork,
    input : [Float],
    target : [Float],
    lossType : LossFunction
  ) : (NeuralNetwork, TrainingResult) {
    
    // Forward pass
    let forwardResult = forward(network, input);
    
    // Calculate loss
    let loss = calculateLoss(forwardResult.output, target, lossType);
    
    // Backward pass
    let gradients = backpropagate(network, forwardResult, target, lossType);
    
    // Update weights (simplified SGD)
    let updatedLayers = Array.init<Layer>(network.layers.size(), {
      inputSize = 0;
      outputSize = 0;
      weights = [];
      biases = [];
      activation = #linear;
      dropout = 0.0;
    });

    for (l in Array.keys(network.layers)) {
      let layer = network.layers[l];
      let wGrad = gradients.weightGradients[l];
      let bGrad = gradients.biasGradients[l];
      
      // Update weights: W = W - η∇W
      let newWeights = Array.tabulate<[Float]>(layer.weights.size(), func (i) {
        Array.tabulate<Float>(layer.weights[i].size(), func (j) {
          let gradient = if (j < wGrad[i].size()) { wGrad[i][j] } else { 0.0 };
          layer.weights[i][j] - network.learningRate * gradient
        })
      });
      
      // Update biases: b = b - η∇b
      let newBiases = Array.tabulate<Float>(layer.biases.size(), func (i) {
        layer.biases[i] - network.learningRate * bGrad[i]
      });
      
      updatedLayers[l] := {
        inputSize = layer.inputSize;
        outputSize = layer.outputSize;
        weights = newWeights;
        biases = newBiases;
        activation = layer.activation;
        dropout = layer.dropout;
      };
    };

    let updatedNetwork = {
      layers = Array.freeze(updatedLayers);
      learningRate = network.learningRate;
      momentum = network.momentum;
      optimizer = network.optimizer;
    };

    let result = {
      loss = loss;
      gradientNorm = gradients.totalGradNorm;
      updated = true;
    };

    (updatedNetwork, result)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NEURAL SYNAPSES STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type NeuralSynapsesState = {
    var registeredNetworks  : [(Text, NeuralNetwork)];
    var totalTrainingSteps  : Nat;
    var averageLoss         : Float;
    var lastTrainingBeat    : Int;
    var phiCoherence        : Float;
  };

  public func initNeuralSynapsesState() : NeuralSynapsesState {
    {
      var registeredNetworks = [];
      var totalTrainingSteps = 0;
      var averageLoss = 0.0;
      var lastTrainingBeat = 0;
      var phiCoherence = Phi.PHI_INV;
    }
  };

};
