// ml_integration.mo — Production ML orchestration for PARALLAX.
// Provides a model registry, feature engineering utilities, online learning
// governance, and HTTP-outcall payload generation for Python inference.

import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Outcall "http-outcalls/outcall";

module {
  public let CONFIDENCE_GATE : Float = 0.6180339887;
  public let DRIFT_GATE : Float = 0.2360679774;
  public let RETRAINING_GATE : Float = 0.3819660112;

  public type ModelType = {
    #pricePrediction;
    #volatilityForecasting;
    #sentimentAnalysis;
    #anomalyDetection;
    #arbitrageDetection;
  };

  public type LifecycleStage = {
    #draft;
    #shadow;
    #active;
    #degraded;
    #retired;
    #archived;
  };

  public type AggregationStrategy = {
    #weightedAverage;
    #confidenceWeighted;
    #majorityVote;
    #maxConfidence;
  };

  public type ModelMetadata = {
    architecture : Text;
    parameters : Nat;
    accuracy : Float;
    trainingWindow : Text;
    featureSchema : [Text];
    tags : [Text];
    createdAt : Int;
    updatedAt : Int;
  };

  public type RegisteredModel = {
    modelId : Text;
    version : Nat;
    modelType : ModelType;
    stage : LifecycleStage;
    endpoint : Text;
    metadata : ModelMetadata;
    ensembleMembers : [Text];
    supportsBatch : Bool;
    supportsStreaming : Bool;
  };

  public type PerformanceSnapshot = {
    modelId : Text;
    version : Nat;
    accuracy : Float;
    calibrationError : Float;
    latencyMs : Nat;
    throughputPerSecond : Nat;
    observedAt : Int;
  };

  public type DriftAssessment = {
    modelId : Text;
    version : Nat;
    featureShift : Float;
    targetShift : Float;
    accuracyDecay : Float;
    isDrifting : Bool;
    severity : Text;
    observedAt : Int;
  };

  public type RetrainingTrigger = {
    triggerId : Text;
    modelId : Text;
    version : Nat;
    reason : Text;
    priority : Text;
    createdAt : Int;
  };

  public type OnlineUpdate = {
    updateId : Text;
    modelId : Text;
    version : Nat;
    gradientPayload : Text;
    sampleCount : Nat;
    receivedAt : Int;
    applied : Bool;
  };

  public type ModelRegistryState = {
    models : [RegisteredModel];
    performance : [PerformanceSnapshot];
    driftAssessments : [DriftAssessment];
    updateQueue : [OnlineUpdate];
    retrainingTriggers : [RetrainingTrigger];
  };

  public type PriceObservation = {
    closePrices : [Float];
    peerPrices : [Float];
  };

  public type OrderBookObservation = {
    bidDepth : [Float];
    askDepth : [Float];
    bestBid : Float;
    bestAsk : Float;
  };

  public type FeatureVector = {
    returns : Float;
    realizedVolatility : Float;
    momentum : Float;
    spread : Float;
    bidDepth : Float;
    askDepth : Float;
    imbalance : Float;
    lag1 : Float;
    lag5 : Float;
    lag20 : Float;
    rollingMean : Float;
    rollingStd : Float;
    crossAssetCorrelation : Float;
    priceRatio : Float;
    relativeStrength : Float;
  };

  public type InferenceRequest = {
    requestId : Text;
    modelId : Text;
    version : ?Nat;
    modelType : ModelType;
    featureVector : FeatureVector;
    horizonMs : Nat;
    requestedAt : Int;
    strategy : AggregationStrategy;
  };

  public type InferencePrediction = {
    modelId : Text;
    version : Nat;
    label : Text;
    value : Float;
    probability : Float;
    confidence : Float;
    latencyMs : Nat;
    explanation : Text;
  };

  public type EnsembleAggregate = {
    label : Text;
    value : Float;
    confidence : Float;
    memberCount : Nat;
    dispersion : Float;
    supportingModels : [Text];
  };

  public type StreamEnvelope = {
    channel : Text;
    cursor : Nat;
    payload : Text;
    heartbeatMs : Nat;
  };

  public func emptyRegistry() : ModelRegistryState {
    {
      models = [];
      performance = [];
      driftAssessments = [];
      updateQueue = [];
      retrainingTriggers = [];
    }
  };

  func absFloat(value : Float) : Float {
    if (value < 0.0) { -value } else { value }
  };

  func natToFloat(value : Nat) : Float {
    Float.fromInt(Nat.toInt(value))
  };

  func mean(values : [Float]) : Float {
    if (values.size() == 0) {
      return 0.0;
    };
    Array.foldLeft<Float, Float>(values, 0.0, func(acc : Float, value : Float) : Float {
      acc + value
    }) / natToFloat(values.size())
  };

  func variance(values : [Float], avg : Float) : Float {
    if (values.size() == 0) {
      return 0.0;
    };
    Array.foldLeft<Float, Float>(values, 0.0, func(acc : Float, value : Float) : Float {
      let delta = value - avg;
      acc + (delta * delta)
    }) / natToFloat(values.size())
  };

  func stdDev(values : [Float]) : Float {
    let avg = mean(values);
    Float.sqrt(variance(values, avg))
  };

  func latestValue(values : [Float]) : Float {
    if (values.size() == 0) { 0.0 } else { values[values.size() - 1] }
  };

  func lagValue(values : [Float], lag : Nat) : Float {
    if (values.size() <= lag) {
      0.0
    } else {
      let anchor = values[values.size() - 1 - lag];
      let current = latestValue(values);
      if (anchor == 0.0) { 0.0 } else { (current - anchor) / anchor }
    }
  };

  func safeDivide(left : Float, right : Float) : Float {
    if (right == 0.0) { 0.0 } else { left / right }
  };

  func sum(values : [Float]) : Float {
    Array.foldLeft<Float, Float>(values, 0.0, func(acc : Float, value : Float) : Float {
      acc + value
    })
  };

  func modelTypeText(modelType : ModelType) : Text {
    switch (modelType) {
      case (#pricePrediction) { "price_prediction" };
      case (#volatilityForecasting) { "volatility_forecasting" };
      case (#sentimentAnalysis) { "sentiment_analysis" };
      case (#anomalyDetection) { "anomaly_detection" };
      case (#arbitrageDetection) { "arbitrage_detection" };
    }
  };

  func stageText(stage : LifecycleStage) : Text {
    switch (stage) {
      case (#draft) { "draft" };
      case (#shadow) { "shadow" };
      case (#active) { "active" };
      case (#degraded) { "degraded" };
      case (#retired) { "retired" };
      case (#archived) { "archived" };
    }
  };

  func strategyText(strategy : AggregationStrategy) : Text {
    switch (strategy) {
      case (#weightedAverage) { "weighted_average" };
      case (#confidenceWeighted) { "confidence_weighted" };
      case (#majorityVote) { "majority_vote" };
      case (#maxConfidence) { "max_confidence" };
    }
  };

  func joinTexts(values : [Text], separator : Text) : Text {
    Array.foldLeft<Text, Text>(values, "", func(acc : Text, value : Text) : Text {
      if (acc == "") { value } else { acc # separator # value }
    })
  };

  func quoteTexts(values : [Text]) : [Text] {
    Array.map<Text, Text>(values, func(value : Text) : Text { "\"" # value # "\"" })
  };

  public func latestVersion(state : ModelRegistryState, modelId : Text) : ?Nat {
    Array.foldLeft<RegisteredModel, ?Nat>(
      state.models,
      null,
      func(acc : ?Nat, model : RegisteredModel) : ?Nat {
        if (model.modelId != modelId) {
          acc
        } else {
          switch (acc) {
            case null { ?model.version };
            case (?current) {
              if (model.version > current) { ?model.version } else { ?current }
            };
          }
        }
      },
    )
  };

  public func registerModel(
    state : ModelRegistryState,
    modelId : Text,
    modelType : ModelType,
    endpoint : Text,
    stage : LifecycleStage,
    metadata : ModelMetadata,
    supportsBatch : Bool,
    supportsStreaming : Bool,
    ensembleMembers : [Text],
  ) : ModelRegistryState {
    let version = switch (latestVersion(state, modelId)) {
      case null { 1 };
      case (?current) { current + 1 };
    };
    let model : RegisteredModel = {
      modelId = modelId;
      version = version;
      modelType = modelType;
      stage = stage;
      endpoint = endpoint;
      metadata = metadata;
      ensembleMembers = ensembleMembers;
      supportsBatch = supportsBatch;
      supportsStreaming = supportsStreaming;
    };
    {
      models = Array.append(state.models, [model]);
      performance = state.performance;
      driftAssessments = state.driftAssessments;
      updateQueue = state.updateQueue;
      retrainingTriggers = state.retrainingTriggers;
    }
  };

  public func listModelsByType(state : ModelRegistryState, modelType : ModelType) : [RegisteredModel] {
    Array.filter<RegisteredModel>(state.models, func(model : RegisteredModel) : Bool {
      model.modelType == modelType
    })
  };

  public func getActiveModels(state : ModelRegistryState) : [RegisteredModel] {
    Array.filter<RegisteredModel>(state.models, func(model : RegisteredModel) : Bool {
      model.stage == #active or model.stage == #shadow
    })
  };

  public func transitionLifecycle(
    state : ModelRegistryState,
    modelId : Text,
    version : Nat,
    nextStage : LifecycleStage,
  ) : ModelRegistryState {
    let models = Array.map<RegisteredModel, RegisteredModel>(state.models, func(model : RegisteredModel) : RegisteredModel {
      if (model.modelId == modelId and model.version == version) {
        {
          modelId = model.modelId;
          version = model.version;
          modelType = model.modelType;
          stage = nextStage;
          endpoint = model.endpoint;
          metadata = model.metadata;
          ensembleMembers = model.ensembleMembers;
          supportsBatch = model.supportsBatch;
          supportsStreaming = model.supportsStreaming;
        }
      } else {
        model
      }
    });
    {
      models = models;
      performance = state.performance;
      driftAssessments = state.driftAssessments;
      updateQueue = state.updateQueue;
      retrainingTriggers = state.retrainingTriggers;
    }
  };

  public func engineerFeatures(prices : PriceObservation, orderBook : OrderBookObservation) : FeatureVector {
    let currentPrice = latestValue(prices.closePrices);
    let priorPrice = if (prices.closePrices.size() >= 2) { prices.closePrices[prices.closePrices.size() - 2] } else { currentPrice };
    let returns = if (priorPrice == 0.0) { 0.0 } else { (currentPrice - priorPrice) / priorPrice };
    let realizedVolatility = stdDev(prices.closePrices);
    let momentum = lagValue(prices.closePrices, 5);
    let bidDepth = sum(orderBook.bidDepth);
    let askDepth = sum(orderBook.askDepth);
    let imbalance = safeDivide(bidDepth - askDepth, bidDepth + askDepth);
    let rollingMean = mean(prices.closePrices);
    let rollingStd = stdDev(prices.closePrices);
    let peerMean = mean(prices.peerPrices);
    let peerStd = stdDev(prices.peerPrices);
    let priceStd = stdDev(prices.closePrices);
    let crossAssetCorrelation = if (priceStd == 0.0 or peerStd == 0.0) {
      0.0
    } else {
      safeDivide((currentPrice - rollingMean) * (latestValue(prices.peerPrices) - peerMean), priceStd * peerStd)
    };
    {
      returns = returns;
      realizedVolatility = realizedVolatility;
      momentum = momentum;
      spread = orderBook.bestAsk - orderBook.bestBid;
      bidDepth = bidDepth;
      askDepth = askDepth;
      imbalance = imbalance;
      lag1 = lagValue(prices.closePrices, 1);
      lag5 = lagValue(prices.closePrices, 5);
      lag20 = lagValue(prices.closePrices, 20);
      rollingMean = rollingMean;
      rollingStd = rollingStd;
      crossAssetCorrelation = crossAssetCorrelation;
      priceRatio = safeDivide(currentPrice, latestValue(prices.peerPrices));
      relativeStrength = if (peerMean == 0.0) { 0.0 } else { safeDivide(currentPrice - rollingMean, peerMean) };
    }
  };

  public func queueOnlineUpdate(state : ModelRegistryState, update : OnlineUpdate) : ModelRegistryState {
    {
      models = state.models;
      performance = state.performance;
      driftAssessments = state.driftAssessments;
      updateQueue = Array.append(state.updateQueue, [update]);
      retrainingTriggers = state.retrainingTriggers;
    }
  };

  public func markOnlineUpdateApplied(state : ModelRegistryState, updateId : Text) : ModelRegistryState {
    let updates = Array.map<OnlineUpdate, OnlineUpdate>(state.updateQueue, func(update : OnlineUpdate) : OnlineUpdate {
      if (update.updateId == updateId) {
        {
          updateId = update.updateId;
          modelId = update.modelId;
          version = update.version;
          gradientPayload = update.gradientPayload;
          sampleCount = update.sampleCount;
          receivedAt = update.receivedAt;
          applied = true;
        }
      } else {
        update
      }
    });
    {
      models = state.models;
      performance = state.performance;
      driftAssessments = state.driftAssessments;
      updateQueue = updates;
      retrainingTriggers = state.retrainingTriggers;
    }
  };

  public func recordPerformance(state : ModelRegistryState, snapshot : PerformanceSnapshot) : ModelRegistryState {
    {
      models = state.models;
      performance = Array.append(state.performance, [snapshot]);
      driftAssessments = state.driftAssessments;
      updateQueue = state.updateQueue;
      retrainingTriggers = state.retrainingTriggers;
    }
  };

  public func detectDrift(
    modelId : Text,
    version : Nat,
    baseline : PerformanceSnapshot,
    candidate : PerformanceSnapshot,
  ) : DriftAssessment {
    let featureShift = absFloat(candidate.calibrationError - baseline.calibrationError);
    let targetShift = absFloat(natToFloat(candidate.latencyMs) - natToFloat(baseline.latencyMs)) / 1000.0;
    let accuracyDecay = absFloat(baseline.accuracy - candidate.accuracy);
    let driftMagnitude = featureShift + targetShift + accuracyDecay;
    {
      modelId = modelId;
      version = version;
      featureShift = featureShift;
      targetShift = targetShift;
      accuracyDecay = accuracyDecay;
      isDrifting = driftMagnitude >= DRIFT_GATE or accuracyDecay >= RETRAINING_GATE;
      severity = if (driftMagnitude >= RETRAINING_GATE) { "high" } else if (driftMagnitude >= DRIFT_GATE) { "medium" } else { "low" };
      observedAt = candidate.observedAt;
    }
  };

  public func registerDriftAssessment(state : ModelRegistryState, assessment : DriftAssessment) : ModelRegistryState {
    let trigger = if (assessment.isDrifting) {
      [{
        triggerId = assessment.modelId # "-" # Nat.toText(assessment.version) # "-" # Int.toText(assessment.observedAt);
        modelId = assessment.modelId;
        version = assessment.version;
        reason = "drift_detected";
        priority = assessment.severity;
        createdAt = assessment.observedAt;
      }]
    } else {
      []
    };
    {
      models = state.models;
      performance = state.performance;
      driftAssessments = Array.append(state.driftAssessments, [assessment]);
      updateQueue = state.updateQueue;
      retrainingTriggers = Array.append(state.retrainingTriggers, trigger);
    }
  };

  public func shouldRetrain(assessment : DriftAssessment) : Bool {
    assessment.isDrifting and (assessment.accuracyDecay >= RETRAINING_GATE or assessment.featureShift >= DRIFT_GATE)
  };

  public func confidenceScore(predictions : [InferencePrediction]) : Float {
    if (predictions.size() == 0) {
      return 0.0;
    };
    let confidences = Array.map<InferencePrediction, Float>(predictions, func(prediction : InferencePrediction) : Float {
      prediction.confidence
    });
    let values = Array.map<InferencePrediction, Float>(predictions, func(prediction : InferencePrediction) : Float {
      prediction.value
    });
    let meanConfidence = mean(confidences);
    let dispersionPenalty = Float.min(1.0, stdDev(values));
    Float.max(0.0, meanConfidence * (1.0 - dispersionPenalty))
  };

  public func aggregateEnsemble(
    predictions : [InferencePrediction],
    strategy : AggregationStrategy,
  ) : EnsembleAggregate {
    if (predictions.size() == 0) {
      return {
        label = "no_prediction";
        value = 0.0;
        confidence = 0.0;
        memberCount = 0;
        dispersion = 0.0;
        supportingModels = [];
      };
    };
    let values = Array.map<InferencePrediction, Float>(predictions, func(prediction : InferencePrediction) : Float {
      prediction.value
    });
    let meanValue = mean(values);
    let dispersion = stdDev(values);
    let weighted = switch (strategy) {
      case (#weightedAverage) { meanValue };
      case (#confidenceWeighted) {
        let numerator = Array.foldLeft<InferencePrediction, Float>(predictions, 0.0, func(acc : Float, prediction : InferencePrediction) : Float {
          acc + (prediction.value * prediction.confidence)
        });
        let denominator = Array.foldLeft<InferencePrediction, Float>(predictions, 0.0, func(acc : Float, prediction : InferencePrediction) : Float {
          acc + prediction.confidence
        });
        safeDivide(numerator, denominator)
      };
      case (#majorityVote) {
        let positives = Array.filter<InferencePrediction>(predictions, func(prediction : InferencePrediction) : Bool {
          prediction.value >= 0.0
        });
        if (positives.size() * 2 >= predictions.size()) { 1.0 } else { -1.0 }
      };
      case (#maxConfidence) {
        let winner = Array.foldLeft<InferencePrediction, InferencePrediction>(predictions, predictions[0], func(best : InferencePrediction, next : InferencePrediction) : InferencePrediction {
          if (next.confidence > best.confidence) { next } else { best }
        });
        winner.value
      };
    };
    let winner = Array.foldLeft<InferencePrediction, InferencePrediction>(predictions, predictions[0], func(best : InferencePrediction, next : InferencePrediction) : InferencePrediction {
      if (next.confidence > best.confidence) { next } else { best }
    });
    {
      label = winner.label;
      value = weighted;
      confidence = confidenceScore(predictions);
      memberCount = predictions.size();
      dispersion = dispersion;
      supportingModels = Array.map<InferencePrediction, Text>(predictions, func(prediction : InferencePrediction) : Text {
        prediction.modelId # ":" # Nat.toText(prediction.version)
      });
    }
  };

  func featureJson(featureVector : FeatureVector) : Text {
    "{" #
    "\"returns\":" # Float.toText(featureVector.returns) # "," #
    "\"realized_volatility\":" # Float.toText(featureVector.realizedVolatility) # "," #
    "\"momentum\":" # Float.toText(featureVector.momentum) # "," #
    "\"spread\":" # Float.toText(featureVector.spread) # "," #
    "\"bid_depth\":" # Float.toText(featureVector.bidDepth) # "," #
    "\"ask_depth\":" # Float.toText(featureVector.askDepth) # "," #
    "\"imbalance\":" # Float.toText(featureVector.imbalance) # "," #
    "\"lag1\":" # Float.toText(featureVector.lag1) # "," #
    "\"lag5\":" # Float.toText(featureVector.lag5) # "," #
    "\"lag20\":" # Float.toText(featureVector.lag20) # "," #
    "\"rolling_mean\":" # Float.toText(featureVector.rollingMean) # "," #
    "\"rolling_std\":" # Float.toText(featureVector.rollingStd) # "," #
    "\"cross_asset_correlation\":" # Float.toText(featureVector.crossAssetCorrelation) # "," #
    "\"price_ratio\":" # Float.toText(featureVector.priceRatio) # "," #
    "\"relative_strength\":" # Float.toText(featureVector.relativeStrength) #
    "}"
  };

  public func encodeInferenceRequest(request : InferenceRequest) : Text {
    let versionText = switch (request.version) {
      case null { "null" };
      case (?version) { Nat.toText(version) };
    };
    "{" #
    "\"request_id\":\"" # request.requestId # "\"," #
    "\"model_id\":\"" # request.modelId # "\"," #
    "\"version\":" # versionText # "," #
    "\"model_type\":\"" # modelTypeText(request.modelType) # "\"," #
    "\"horizon_ms\":" # Nat.toText(request.horizonMs) # "," #
    "\"requested_at\":" # Int.toText(request.requestedAt) # "," #
    "\"aggregation\":\"" # strategyText(request.strategy) # "\"," #
    "\"features\":" # featureJson(request.featureVector) #
    "}"
  };

  public func encodeBatchRequest(requests : [InferenceRequest]) : Text {
    let payloads = Array.map<InferenceRequest, Text>(requests, encodeInferenceRequest);
    "{" #
    "\"batch_size\":" # Nat.toText(requests.size()) # "," #
    "\"requests\":[" # joinTexts(payloads, ",") # "]" #
    "}"
  };

  public func streamEnvelope(channel : Text, cursor : Nat, request : InferenceRequest) : StreamEnvelope {
    {
      channel = channel;
      cursor = cursor;
      payload = encodeInferenceRequest(request);
      heartbeatMs = 873;
    }
  };

  public func registrySummary(state : ModelRegistryState) : Text {
    let activeModels = getActiveModels(state);
    let triggerTexts = Array.map<RetrainingTrigger, Text>(state.retrainingTriggers, func(trigger : RetrainingTrigger) : Text {
      trigger.modelId # "@" # Nat.toText(trigger.version) # ":" # trigger.priority
    });
    "{" #
    "\"models\":" # Nat.toText(state.models.size()) # "," #
    "\"active_models\":" # Nat.toText(activeModels.size()) # "," #
    "\"pending_updates\":" # Nat.toText(state.updateQueue.size()) # "," #
    "\"retraining_triggers\":[" # joinTexts(quoteTexts(triggerTexts), ",") # "]" #
    "}"
  };

  public func inferenceHeaders(apiKey : Text) : [Outcall.Header] {
    [
      { name = "Content-Type"; value = "application/json" },
      { name = "Authorization"; value = "Bearer " # apiKey },
    ]
  };

  public func invokePythonInference(endpoint : Text, apiKey : Text, request : InferenceRequest) : async Text {
    await Outcall.httpPostRequest(endpoint, inferenceHeaders(apiKey), encodeInferenceRequest(request), Outcall.transform)
  };

  public func invokeBatchInference(endpoint : Text, apiKey : Text, requests : [InferenceRequest]) : async Text {
    await Outcall.httpPostRequest(endpoint, inferenceHeaders(apiKey), encodeBatchRequest(requests), Outcall.transform)
  };
}
