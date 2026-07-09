import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Order "mo:core/Order";
import Nat "mo:core/Nat";

module {
  public type Matrix = [[Float]];

  public type OptimizationConstraints = {
    riskAversion : Float;
    allowShorting : Bool;
    minWeight : ?Float;
    maxWeight : ?Float;
    targetReturn : ?Float;
  };

  public type MarkowitzResult = {
    weights : [Float];
    expectedReturn : Float;
    variance : Float;
    volatility : Float;
    sharpe : Float;
    utility : Float;
  };

  public type EfficientFrontierPoint = {
    targetReturn : Float;
    expectedReturn : Float;
    variance : Float;
    volatility : Float;
    sharpe : Float;
    weights : [Float];
  };

  public type BlackLittermanView = {
    pickVector : [Float];
    expectedReturn : Float;
    confidence : Float;
  };

  public type BlackLittermanResult = {
    priorReturns : [Float];
    posteriorReturns : [Float];
    posteriorCovariance : Matrix;
    optimalWeights : [Float];
  };

  public type VaRResult = {
    historical : Float;
    parametric : Float;
    monteCarlo : Float;
    confidence : Float;
    horizon : Float;
  };

  public type CVaRResult = {
    historical : Float;
    parametric : Float;
    monteCarlo : Float;
    confidence : Float;
  };

  public type TailRiskMeasures = {
    downsideDeviation : Float;
    tailRatio : Float;
    skewness : Float;
    excessKurtosis : Float;
    expectedShortfall : Float;
  };

  public type RiskReport = {
    varResult : VaRResult;
    cvarResult : CVaRResult;
    maxDrawdown : Float;
    correlationMatrix : Matrix;
    tailRisk : TailRiskMeasures;
  };

  public type OptionInput = {
    spot : Float;
    strike : Float;
    rate : Float;
    volatility : Float;
    timeToMaturity : Float;
    isCall : Bool;
  };

  public type Greeks = {
    delta : Float;
    gamma : Float;
    vega : Float;
    theta : Float;
    rho : Float;
    d1 : Float;
    d2 : Float;
  };

  public type DeltaHedge = {
    optionDelta : Float;
    hedgeUnits : Float;
    residualDelta : Float;
  };

  public type GammaHedge = {
    hedgeOptionUnits : Float;
    underlyingUnits : Float;
    residualDelta : Float;
    residualGamma : Float;
  };

  public type VegaHedge = {
    firstOptionUnits : Float;
    secondOptionUnits : Float;
    underlyingUnits : Float;
    residualDelta : Float;
    residualGamma : Float;
    residualVega : Float;
  };

  public type DynamicRebalancePlan = {
    currentWeights : [Float];
    targetWeights : [Float];
    tradeWeights : [Float];
    turnover : Float;
    rebalanceNow : Bool;
    threshold : Float;
  };

  public type FactorRegressionResult = {
    alpha : Float;
    betas : [Float];
    residualVariance : Float;
    rSquared : Float;
    fittedReturns : [Float];
    residuals : [Float];
  };

  public type FamaFrenchFactors = {
    marketExcess : [Float];
    smb : [Float];
    hml : [Float];
    riskFree : [Float];
  };

  public type CarhartFactors = {
    marketExcess : [Float];
    smb : [Float];
    hml : [Float];
    momentum : [Float];
    riskFree : [Float];
  };

  public type PCAResult = {
    eigenvalues : [Float];
    eigenvectors : Matrix;
    explainedVariance : [Float];
    factorScores : Matrix;
  };

  public type FactorDecomposition = {
    systematicRisk : Float;
    idiosyncraticRisk : Float;
    factorContributions : [Float];
    marginalContributions : [Float];
  };

  public type PortfolioOptimizationBundle = {
    meanVariance : MarkowitzResult;
    sharpeMaximum : MarkowitzResult;
    riskParity : [Float];
    phiWeighted : [Float];
    blackLitterman : BlackLittermanResult;
    efficientFrontier : [EfficientFrontierPoint];
    riskReport : RiskReport;
  };

  let EPS : Float = 0.000000001;
  let SQRT_TWO : Float = 1.4142135623730951;
  let SQRT_TWO_PI : Float = 2.5066282746310002;

  public func defaultOptimizationConstraints() : OptimizationConstraints {
    {
      riskAversion = Phi.PHI;
      allowShorting = false;
      minWeight = null;
      maxWeight = ?Phi.PHI_INV;
      targetReturn = null;
    }
  };

  func minFloat(a : Float, b : Float) : Float { if (a < b) { a } else { b } };
  func maxFloat(a : Float, b : Float) : Float { if (a > b) { a } else { b } };
  func absFloat(x : Float) : Float { Float.abs(x) };
  func clamp(x : Float, low : Float, high : Float) : Float { maxFloat(low, minFloat(high, x)) };

  func positiveOr(x : Float, fallback : Float) : Float {
    if (x > EPS) { x } else { fallback }
  };

  func sum(xs : [Float]) : Float {
    var total = 0.0;
    for (x in xs.vals()) { total += x };
    total
  };

  func mean(xs : [Float]) : Float {
    if (xs.size() == 0) { 0.0 } else { sum(xs) / xs.size().toFloat() }
  };

  func _zeroVector(n : Nat) : [Float] {
    Array.tabulate<Float>(n, func(_) { 0.0 })
  };

  func ones(n : Nat) : [Float] {
    Array.tabulate<Float>(n, func(_) { 1.0 })
  };

  func identity(n : Nat) : Matrix {
    Array.tabulate<[Float]>(n, func(i) {
      Array.tabulate<Float>(n, func(j) { if (i == j) { 1.0 } else { 0.0 } })
    })
  };

  func normalizeWeights(weights : [Float]) : [Float] {
    if (weights.size() == 0) { return [] };
    let total = sum(weights);
    if (absFloat(total) <= EPS) {
      let equalWeight = 1.0 / weights.size().toFloat();
      return Array.tabulate<Float>(weights.size(), func(_) { equalWeight });
    };
    Array.tabulate<Float>(weights.size(), func(i) { weights[i] / total })
  };

  func dot(a : [Float], b : [Float]) : Float {
    let n = if (a.size() < b.size()) { a.size() } else { b.size() };
    var total = 0.0;
    var i = 0;
    while (i < n) {
      total += a[i] * b[i];
      i += 1;
    };
    total
  };

  func vectorSubtract(a : [Float], b : [Float]) : [Float] {
    let n = if (a.size() < b.size()) { a.size() } else { b.size() };
    Array.tabulate<Float>(n, func(i) { a[i] - b[i] })
  };

  func vectorAdd(a : [Float], b : [Float]) : [Float] {
    let n = if (a.size() < b.size()) { a.size() } else { b.size() };
    Array.tabulate<Float>(n, func(i) { a[i] + b[i] })
  };

  func scaleVector(a : [Float], scalar : Float) : [Float] {
    Array.tabulate<Float>(a.size(), func(i) { a[i] * scalar })
  };

  func vectorNorm(a : [Float]) : Float {
    Float.sqrt(maxFloat(dot(a, a), 0.0))
  };

  func transpose(matrix : Matrix) : Matrix {
    if (matrix.size() == 0) { return [] };
    let rows = matrix.size();
    let cols = matrix[0].size();
    Array.tabulate<[Float]>(cols, func(j) {
      Array.tabulate<Float>(rows, func(i) { matrix[i][j] })
    })
  };

  func matrixVectorMultiply(matrix : Matrix, vector : [Float]) : [Float] {
    Array.tabulate<Float>(matrix.size(), func(i) { dot(matrix[i], vector) })
  };

  func matrixMultiply(a : Matrix, b : Matrix) : Matrix {
    if (a.size() == 0 or b.size() == 0) { return [] };
    let bT = transpose(b);
    Array.tabulate<[Float]>(a.size(), func(i) {
      Array.tabulate<Float>(bT.size(), func(j) { dot(a[i], bT[j]) })
    })
  };

  func addMatrix(a : Matrix, b : Matrix) : Matrix {
    let rows = if (a.size() < b.size()) { a.size() } else { b.size() };
    Array.tabulate<[Float]>(rows, func(i) { vectorAdd(a[i], b[i]) })
  };

  func subtractMatrix(a : Matrix, b : Matrix) : Matrix {
    let rows = if (a.size() < b.size()) { a.size() } else { b.size() };
    Array.tabulate<[Float]>(rows, func(i) { vectorSubtract(a[i], b[i]) })
  };

  func scaleMatrix(matrix : Matrix, scalar : Float) : Matrix {
    Array.tabulate<[Float]>(matrix.size(), func(i) { scaleVector(matrix[i], scalar) })
  };

  func outerProduct(a : [Float], b : [Float]) : Matrix {
    Array.tabulate<[Float]>(a.size(), func(i) {
      Array.tabulate<Float>(b.size(), func(j) { a[i] * b[j] })
    })
  };

  func regularize(matrix : Matrix, ridge : Float) : Matrix {
    Array.tabulate<[Float]>(matrix.size(), func(i) {
      Array.tabulate<Float>(matrix[i].size(), func(j) {
        if (i == j) { matrix[i][j] + ridge } else { matrix[i][j] }
      })
    })
  };

  func inverse(matrix : Matrix) : Matrix {
    let n = matrix.size();
    if (n == 0) { return [] };
    let cols = 2 * n;
    let aug = Array.toVarArray(Array.repeat<Float>(0.0, n * cols));

    var i = 0;
    while (i < n) {
      var j = 0;
      while (j < n) {
        aug[i * cols + j] := matrix[i][j];
        j += 1;
      };
      aug[i * cols + n + i] := 1.0;
      i += 1;
    };

    var pivotIdx = 0;
    while (pivotIdx < n) {
      var bestRow = pivotIdx;
      var bestValue = absFloat(aug[pivotIdx * cols + pivotIdx]);
      var scan = pivotIdx + 1;
      while (scan < n) {
        let candidate = absFloat(aug[scan * cols + pivotIdx]);
        if (candidate > bestValue) {
          bestValue := candidate;
          bestRow := scan;
        };
        scan += 1;
      };

      if (bestValue <= EPS) {
        return identity(n);
      };

      if (bestRow != pivotIdx) {
        var c = 0;
        while (c < cols) {
          let tmp = aug[pivotIdx * cols + c];
          aug[pivotIdx * cols + c] := aug[bestRow * cols + c];
          aug[bestRow * cols + c] := tmp;
          c += 1;
        };
      };

      let pivot = aug[pivotIdx * cols + pivotIdx];
      var cNorm = 0;
      while (cNorm < cols) {
        aug[pivotIdx * cols + cNorm] := aug[pivotIdx * cols + cNorm] / pivot;
        cNorm += 1;
      };

      var r = 0;
      while (r < n) {
        if (r != pivotIdx) {
          let factor = aug[r * cols + pivotIdx];
          var cElim = 0;
          while (cElim < cols) {
            aug[r * cols + cElim] := aug[r * cols + cElim] - factor * aug[pivotIdx * cols + cElim];
            cElim += 1;
          };
        };
        r += 1;
      };
      pivotIdx += 1;
    };

    Array.tabulate<[Float]>(n, func(r) {
      Array.tabulate<Float>(n, func(c) { aug[r * cols + n + c] })
    })
  };

  func solveLinearSystem(a : Matrix, b : [Float]) : [Float] {
    let inv = inverse(regularize(a, EPS));
    matrixVectorMultiply(inv, b)
  };

  func diagonal(matrix : Matrix) : [Float] {
    Array.tabulate<Float>(matrix.size(), func(i) {
      if (i < matrix[i].size()) { matrix[i][i] } else { 0.0 }
    })
  };

  func variance(series : [Float]) : Float {
    if (series.size() <= 1) { return 0.0 };
    let avg = mean(series);
    var total = 0.0;
    for (x in series.vals()) {
      let diff = x - avg;
      total += diff * diff;
    };
    total / (series.size() - 1).toFloat()
  };

  func covarianceSeries(a : [Float], b : [Float]) : Float {
    let n = if (a.size() < b.size()) { a.size() } else { b.size() };
    if (n <= 1) { return 0.0 };
    let trimmedA = Array.tabulate<Float>(n, func(i) { a[i] });
    let trimmedB = Array.tabulate<Float>(n, func(i) { b[i] });
    let meanA = mean(trimmedA);
    let meanB = mean(trimmedB);
    var total = 0.0;
    var i = 0;
    while (i < n) {
      total += (trimmedA[i] - meanA) * (trimmedB[i] - meanB);
      i += 1;
    };
    total / (n - 1).toFloat()
  };

  public func estimateCovarianceMatrix(assetReturns : Matrix) : Matrix {
    let n = assetReturns.size();
    Array.tabulate<[Float]>(n, func(i) {
      Array.tabulate<Float>(n, func(j) { covarianceSeries(assetReturns[i], assetReturns[j]) })
    })
  };

  public func estimateCorrelationMatrix(assetReturns : Matrix) : Matrix {
    let covariance = estimateCovarianceMatrix(assetReturns);
    let vols = Array.tabulate<Float>(covariance.size(), func(i) {
      Float.sqrt(maxFloat(if (i < covariance[i].size()) { covariance[i][i] } else { 0.0 }, 0.0))
    });
    Array.tabulate<[Float]>(covariance.size(), func(i) {
      Array.tabulate<Float>(covariance[i].size(), func(j) {
        let denom = vols[i] * vols[j];
        if (i == j) { 1.0 }
        else if (denom <= EPS) { 0.0 }
        else { covariance[i][j] / denom }
      })
    })
  };

  func projectSimplex(weights : [Float]) : [Float] {
    if (weights.size() == 0) { return [] };
    let sorted = Array.sort<Float>(weights, func(a, b) : Order.Order {
      if (a > b) { #less } else if (a < b) { #greater } else { #equal }
    });

    var cumulative = 0.0;
    var theta = 0.0;
    var rho : Nat = 0;
    var i = 0;
    while (i < sorted.size()) {
      cumulative += sorted[i];
      let threshold = (cumulative - 1.0) / (i + 1).toFloat();
      if (sorted[i] - threshold > 0.0) {
        rho := i + 1;
        theta := threshold;
      };
      i += 1;
    };

    if (rho == 0) {
      let equalWeight = 1.0 / weights.size().toFloat();
      return Array.tabulate<Float>(weights.size(), func(_) { equalWeight });
    };

    normalizeWeights(Array.tabulate<Float>(weights.size(), func(idx) {
      maxFloat(0.0, weights[idx] - theta)
    }))
  };

  func applyBounds(weights : [Float], constraints : OptimizationConstraints) : [Float] {
    if (weights.size() == 0) { return [] };

    let minWeight = switch (constraints.minWeight) {
      case (?w) { w };
      case null {
        if (constraints.allowShorting) { -Phi.PHI_4 } else { 0.0 }
      };
    };
    let maxWeight = switch (constraints.maxWeight) {
      case (?w) { w };
      case null { Phi.PHI_4 };
    };

    var adjusted = Array.tabulate<Float>(weights.size(), func(i) {
      clamp(weights[i], minWeight, maxWeight)
    });

    var iteration = 0;
    while (iteration < 12) {
      let total = sum(adjusted);
      let diff = 1.0 - total;
      if (absFloat(diff) <= 0.000001) {
        iteration := 12;
      } else {
        var freeCount : Nat = 0;
        var i = 0;
        while (i < adjusted.size()) {
          let atLower = adjusted[i] <= minWeight + 0.000001;
          let atUpper = adjusted[i] >= maxWeight - 0.000001;
          if ((diff > 0.0 and not atUpper) or (diff < 0.0 and not atLower)) {
            freeCount += 1;
          };
          i += 1;
        };
        if (freeCount == 0) {
          iteration := 12;
        } else {
          let step = diff / freeCount.toFloat();
          adjusted := Array.tabulate<Float>(adjusted.size(), func(idx) {
            let atLower = adjusted[idx] <= minWeight + 0.000001;
            let atUpper = adjusted[idx] >= maxWeight - 0.000001;
            if ((diff > 0.0 and atUpper) or (diff < 0.0 and atLower)) {
              adjusted[idx]
            } else {
              clamp(adjusted[idx] + step, minWeight, maxWeight)
            }
          });
          iteration += 1;
        };
      };
    };

    if (constraints.allowShorting) { normalizeWeights(adjusted) } else { projectSimplex(adjusted) }
  };

  public func portfolioReturn(weights : [Float], expectedReturns : [Float]) : Float {
    dot(weights, expectedReturns)
  };

  public func portfolioVariance(weights : [Float], covariance : Matrix) : Float {
    maxFloat(dot(weights, matrixVectorMultiply(covariance, weights)), 0.0)
  };

  func computeMarkowitzMetrics(weights : [Float], expectedReturns : [Float], covariance : Matrix, riskFreeRate : Float, riskAversion : Float) : MarkowitzResult {
    let expected = portfolioReturn(weights, expectedReturns);
    let varianceValue = portfolioVariance(weights, covariance);
    let volatility = Float.sqrt(maxFloat(varianceValue, 0.0));
    let sharpe = if (volatility <= EPS) { 0.0 } else { (expected - riskFreeRate) / volatility };
    {
      weights = weights;
      expectedReturn = expected;
      variance = varianceValue;
      volatility = volatility;
      sharpe = sharpe;
      utility = expected - 0.5 * maxFloat(riskAversion, EPS) * varianceValue;
    }
  };

  func efficientWeightsForTarget(expectedReturns : [Float], covariance : Matrix, targetReturn : Float, constraints : OptimizationConstraints) : [Float] {
    let n = expectedReturns.size();
    if (n == 0) { return [] };
    let invCov = inverse(regularize(covariance, EPS));
    let one = ones(n);
    let invOne = matrixVectorMultiply(invCov, one);
    let invMu = matrixVectorMultiply(invCov, expectedReturns);
    let a = dot(one, invOne);
    let b = dot(one, invMu);
    let c = dot(expectedReturns, invMu);
    let determinant = maxFloat(a * c - b * b, EPS);
    let lambda = (c - b * targetReturn) / determinant;
    let gamma = (a * targetReturn - b) / determinant;
    applyBounds(vectorAdd(scaleVector(invOne, lambda), scaleVector(invMu, gamma)), constraints)
  };

  public func meanVarianceOptimize(expectedReturns : [Float], covariance : Matrix, riskFreeRate : Float, constraints : OptimizationConstraints) : MarkowitzResult {
    let n = expectedReturns.size();
    if (n == 0) {
      return {
        weights = [];
        expectedReturn = 0.0;
        variance = 0.0;
        volatility = 0.0;
        sharpe = 0.0;
        utility = 0.0;
      };
    };

    let weights = switch (constraints.targetReturn) {
      case (?target) { efficientWeightsForTarget(expectedReturns, covariance, target, constraints) };
      case null {
        let invCov = inverse(regularize(covariance, EPS));
        let one = ones(n);
        let invOne = matrixVectorMultiply(invCov, one);
        let invMu = matrixVectorMultiply(invCov, expectedReturns);
        let riskAversion = positiveOr(constraints.riskAversion, Phi.PHI);
        let a = maxFloat(dot(one, invOne), EPS);
        let b = dot(one, invMu);
        let nu = (b - riskAversion) / a;
        let raw = scaleVector(matrixVectorMultiply(invCov, vectorSubtract(expectedReturns, scaleVector(one, nu))), 1.0 / riskAversion);
        applyBounds(raw, constraints)
      };
    };

    computeMarkowitzMetrics(weights, expectedReturns, covariance, riskFreeRate, constraints.riskAversion)
  };

  public func efficientFrontier(expectedReturns : [Float], covariance : Matrix, riskFreeRate : Float, points : Nat, constraints : OptimizationConstraints) : [EfficientFrontierPoint] {
    if (expectedReturns.size() == 0 or points == 0) { return [] };
    let minReturn = Array.foldLeft<Float, Float>(expectedReturns, expectedReturns[0], func(acc, x) { minFloat(acc, x) });
    let maxReturn = Array.foldLeft<Float, Float>(expectedReturns, expectedReturns[0], func(acc, x) { maxFloat(acc, x) });
    let steps = if (points <= 1) { 1.0 } else { (points - 1).toFloat() };
    Array.tabulate<EfficientFrontierPoint>(points, func(i) {
      let target = minReturn + (maxReturn - minReturn) * i.toFloat() / steps;
      let result = meanVarianceOptimize(expectedReturns, covariance, riskFreeRate, {
        riskAversion = constraints.riskAversion;
        allowShorting = constraints.allowShorting;
        minWeight = constraints.minWeight;
        maxWeight = constraints.maxWeight;
        targetReturn = ?target;
      });
      {
        targetReturn = target;
        expectedReturn = result.expectedReturn;
        variance = result.variance;
        volatility = result.volatility;
        sharpe = result.sharpe;
        weights = result.weights;
      }
    })
  };

  public func maximizeSharpeRatio(expectedReturns : [Float], covariance : Matrix, riskFreeRate : Float, constraints : OptimizationConstraints) : MarkowitzResult {
    let n = expectedReturns.size();
    if (n == 0) {
      return meanVarianceOptimize(expectedReturns, covariance, riskFreeRate, constraints);
    };
    let invCov = inverse(regularize(covariance, EPS));
    let excess = vectorSubtract(expectedReturns, scaleVector(ones(n), riskFreeRate));
    let raw = matrixVectorMultiply(invCov, excess);
    let weights = applyBounds(raw, constraints);
    computeMarkowitzMetrics(weights, expectedReturns, covariance, riskFreeRate, constraints.riskAversion)
  };

  public func riskParityAllocation(covariance : Matrix, iterations : Nat, tolerance : Float) : [Float] {
    let n = covariance.size();
    if (n == 0) { return [] };
    var weights = Array.tabulate<Float>(n, func(_) { 1.0 / n.toFloat() });
    let target = 1.0 / n.toFloat();
    let maxIterations = if (iterations == 0) { 200 } else { iterations };
    let tol = if (tolerance <= 0.0) { 0.000001 } else { tolerance };

    var iter = 0;
    while (iter < maxIterations) {
      let marginal = matrixVectorMultiply(covariance, weights);
      let varianceValue = maxFloat(dot(weights, marginal), EPS);
      let riskContrib = Array.tabulate<Float>(n, func(i) { weights[i] * marginal[i] / varianceValue });
      var maxGap = 0.0;
      weights := Array.tabulate<Float>(n, func(i) {
        let gap = absFloat(riskContrib[i] - target);
        if (gap > maxGap) { maxGap := gap };
        let scale = Float.sqrt(target / maxFloat(riskContrib[i], EPS));
        maxFloat(EPS, weights[i] * scale)
      });
      weights := normalizeWeights(weights);
      if (maxGap <= tol) { iter := maxIterations } else { iter += 1 };
    };
    projectSimplex(weights)
  };

  public func phiWeightedAllocation(expectedReturns : [Float], covariance : Matrix, riskFreeRate : Float, constraints : OptimizationConstraints) : [Float] {
    let variances = diagonal(covariance);
    let scores = Array.tabulate<Float>(expectedReturns.size(), func(i) {
      let sigma = Float.sqrt(maxFloat(if (i < variances.size()) { variances[i] } else { 0.0 }, EPS));
      let sharpe = (expectedReturns[i] - riskFreeRate) / sigma;
      let kelly = (expectedReturns[i] - riskFreeRate) / maxFloat(sigma * sigma, EPS);
      let growth = maxFloat(EPS, expectedReturns[i] + Phi.PHI_INV * sharpe + Phi.PHI_INV_2 * maxFloat(kelly, 0.0));
      Float.pow(growth, Phi.PHI)
    });
    applyBounds(scores, constraints)
  };

  public func calculatePriorEquilibriumReturns(covariance : Matrix, marketWeights : [Float], riskAversion : Float) : [Float] {
    scaleVector(matrixVectorMultiply(covariance, marketWeights), maxFloat(riskAversion, EPS))
  };

  public func posteriorDistribution(covariance : Matrix, priorReturns : [Float], tau : Float, views : [BlackLittermanView]) : { mean : [Float]; covariance : Matrix } {
    if (views.size() == 0) {
      return { mean = priorReturns; covariance = covariance };
    };

    let p = Array.tabulate<[Float]>(views.size(), func(i) { views[i].pickVector });
    let q = Array.tabulate<Float>(views.size(), func(i) { views[i].expectedReturn });
    let tauCov = scaleMatrix(covariance, maxFloat(tau, EPS));
    let omegaDiagonal = Array.tabulate<Float>(views.size(), func(i) {
      let pick = views[i].pickVector;
      let impliedVar = dot(pick, matrixVectorMultiply(tauCov, pick));
      impliedVar / clamp(views[i].confidence, 0.05, 1.0)
    });
    let omegaInv = Array.tabulate<[Float]>(views.size(), func(i) {
      Array.tabulate<Float>(views.size(), func(j) {
        if (i == j) { 1.0 / maxFloat(omegaDiagonal[i], EPS) } else { 0.0 }
      })
    });

    let tauInv = inverse(regularize(tauCov, EPS));
    let pT = transpose(p);
    let precision = addMatrix(tauInv, matrixMultiply(matrixMultiply(pT, omegaInv), p));
    let rhs = vectorAdd(matrixVectorMultiply(tauInv, priorReturns), matrixVectorMultiply(matrixMultiply(pT, omegaInv), q));
    let posteriorMean = solveLinearSystem(precision, rhs);
    let posteriorCovariance = addMatrix(covariance, inverse(regularize(precision, EPS)));
    { mean = posteriorMean; covariance = posteriorCovariance }
  };

  public func blackLitterman(covariance : Matrix, marketWeights : [Float], riskAversion : Float, tau : Float, views : [BlackLittermanView], riskFreeRate : Float, constraints : OptimizationConstraints) : BlackLittermanResult {
    let priorReturns = calculatePriorEquilibriumReturns(covariance, marketWeights, riskAversion);
    let posterior = posteriorDistribution(covariance, priorReturns, tau, views);
    let optimal = maximizeSharpeRatio(posterior.mean, posterior.covariance, riskFreeRate, constraints);
    {
      priorReturns = priorReturns;
      posteriorReturns = posterior.mean;
      posteriorCovariance = posterior.covariance;
      optimalWeights = optimal.weights;
    }
  };

  func sortedCopy(values : [Float]) : [Float] {
    Array.sort<Float>(values, func(a, b) : Order.Order {
      if (a < b) { #less } else if (a > b) { #greater } else { #equal }
    })
  };

  func quantile(sortedValues : [Float], probability : Float) : Float {
    if (sortedValues.size() == 0) { return 0.0 };
    let p = clamp(probability, 0.0, 1.0);
    let rawIndex = p * (sortedValues.size() - 1).toFloat();
    let lower = Float.floor(rawIndex);
    let upper = Float.ceil(rawIndex);
    let lowerIdx = Int.abs(Float.toInt(lower));
    let upperIdx = Int.abs(Float.toInt(upper));
    if (lowerIdx == upperIdx) {
      sortedValues[lowerIdx]
    } else {
      let weight = rawIndex - lower;
      sortedValues[lowerIdx] * (1.0 - weight) + sortedValues[upperIdx] * weight
    }
  };

  func erfApprox(x : Float) : Float {
    let sign = if (x < 0.0) { -1.0 } else { 1.0 };
    let ax = absFloat(x);
    let t = 1.0 / (1.0 + 0.3275911 * ax);
    let y = 1.0 - (((((1.061405429 * t - 1.453152027) * t + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t) * Float.exp(-ax * ax);
    sign * y
  };

  func normalCdf(x : Float) : Float {
    0.5 * (1.0 + erfApprox(x / SQRT_TWO))
  };

  func normalPdf(x : Float) : Float {
    Float.exp(-0.5 * x * x) / SQRT_TWO_PI
  };

  func inverseNormalCdf(pInput : Float) : Float {
    let p = clamp(pInput, EPS, 1.0 - EPS);
    let a1 = -39.69683028665376;
    let a2 = 220.9460984245205;
    let a3 = -275.9285104469687;
    let a4 = 138.3577518672690;
    let a5 = -30.66479806614716;
    let a6 = 2.506628277459239;
    let b1 = -54.47609879822406;
    let b2 = 161.5858368580409;
    let b3 = -155.6989798598866;
    let b4 = 66.80131188771972;
    let b5 = -13.28068155288572;
    let c1 = -0.007784894002430293;
    let c2 = -0.3223964580411365;
    let c3 = -2.400758277161838;
    let c4 = -2.549732539343734;
    let c5 = 4.374664141464968;
    let c6 = 2.938163982698783;
    let d1 = 0.007784695709041462;
    let d2 = 0.3224671290700398;
    let d3 = 2.445134137142996;
    let d4 = 3.754408661907416;
    let pLow = 0.02425;
    let pHigh = 1.0 - pLow;

    if (p < pLow) {
      let q = Float.sqrt(-2.0 * Float.log(p));
      (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
    } else if (p <= pHigh) {
      let q = p - 0.5;
      let r = q * q;
      (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
      (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0)
    } else {
      let q = Float.sqrt(-2.0 * Float.log(1.0 - p));
      -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
      ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
    }
  };

  func sampleMoments(returns : [Float]) : { avg : Float; sigma : Float } {
    let avg = mean(returns);
    let sigma = Float.sqrt(maxFloat(variance(returns), EPS));
    { avg = avg; sigma = sigma }
  };

  func uniformStep(seed : Nat) : { seed : Nat; value : Float } {
    let modulus : Nat = 2_147_483_647;
    let nextSeed = (1_103_515_245 * seed + 12_345) % modulus;
    { seed = nextSeed; value = nextSeed.toFloat() / modulus.toFloat() }
  };

  func standardNormals(count : Nat, seedStart : Nat) : [Float] {
    let samples = Array.toVarArray(Array.repeat<Float>(0.0, count));
    var seed = if (seedStart == 0) { 1 } else { seedStart };
    var i = 0;
    while (i < count) {
      let first = uniformStep(seed);
      let second = uniformStep(first.seed);
      seed := second.seed;
      let u1 = clamp(first.value, EPS, 1.0 - EPS);
      let u2 = clamp(second.value, EPS, 1.0 - EPS);
      let radius = Float.sqrt(-2.0 * Float.log(u1));
      let angle = 2.0 * Float.pi * u2;
      samples[i] := radius * Float.cos(angle);
      if (i + 1 < count) {
        samples[i + 1] := radius * Float.sin(angle);
      };
      i += 2;
    };
    Array.tabulate<Float>(count, func(idx) { samples[idx] })
  };

  func scaledLosses(returns : [Float], horizon : Float, portfolioValue : Float) : [Float] {
    let scale = Float.sqrt(maxFloat(horizon, 1.0));
    Array.tabulate<Float>(returns.size(), func(i) { -returns[i] * scale * portfolioValue })
  };

  public func historicalVaR(returns : [Float], confidence : Float, horizon : Float, portfolioValue : Float) : Float {
    let losses = sortedCopy(scaledLosses(returns, horizon, portfolioValue));
    maxFloat(quantile(losses, confidence), 0.0)
  };

  public func parametricVaR(meanReturn : Float, volatility : Float, confidence : Float, horizon : Float, portfolioValue : Float) : Float {
    let z = inverseNormalCdf(1.0 - clamp(confidence, 0.5, 0.9999));
    let horizonMean = meanReturn * maxFloat(horizon, 1.0);
    let horizonSigma = volatility * Float.sqrt(maxFloat(horizon, 1.0));
    maxFloat(-(horizonMean + horizonSigma * z) * portfolioValue, 0.0)
  };

  public func monteCarloVaR(meanReturn : Float, volatility : Float, confidence : Float, horizon : Float, portfolioValue : Float, simulations : Nat, seed : Nat) : Float {
    let simCount = if (simulations == 0) { 1_000 } else { simulations };
    let normals = standardNormals(simCount, seed);
    let losses = Array.tabulate<Float>(simCount, func(i) {
      let simulatedReturn = meanReturn * maxFloat(horizon, 1.0) + volatility * Float.sqrt(maxFloat(horizon, 1.0)) * normals[i];
      -simulatedReturn * portfolioValue
    });
    maxFloat(quantile(sortedCopy(losses), confidence), 0.0)
  };

  func averageTail(losses : [Float], threshold : Float) : Float {
    if (losses.size() == 0) { return 0.0 };
    var total = 0.0;
    var count : Nat = 0;
    for (loss in losses.vals()) {
      if (loss >= threshold) {
        total += loss;
        count += 1;
      };
    };
    if (count == 0) { threshold } else { total / count.toFloat() }
  };

  public func historicalCVaR(returns : [Float], confidence : Float, horizon : Float, portfolioValue : Float) : Float {
    let losses = scaledLosses(returns, horizon, portfolioValue);
    let varLevel = historicalVaR(returns, confidence, horizon, portfolioValue);
    averageTail(losses, varLevel)
  };

  public func parametricCVaR(meanReturn : Float, volatility : Float, confidence : Float, horizon : Float, portfolioValue : Float) : Float {
    let alpha = 1.0 - clamp(confidence, 0.5, 0.9999);
    let z = inverseNormalCdf(alpha);
    let sigmaH = volatility * Float.sqrt(maxFloat(horizon, 1.0));
    let muH = meanReturn * maxFloat(horizon, 1.0);
    let shortfall = sigmaH * normalPdf(z) / maxFloat(alpha, EPS) - muH;
    maxFloat(shortfall * portfolioValue, 0.0)
  };

  public func monteCarloCVaR(meanReturn : Float, volatility : Float, confidence : Float, horizon : Float, portfolioValue : Float, simulations : Nat, seed : Nat) : Float {
    let simCount = if (simulations == 0) { 1_000 } else { simulations };
    let normals = standardNormals(simCount, seed + 17);
    let losses = Array.tabulate<Float>(simCount, func(i) {
      let simulatedReturn = meanReturn * maxFloat(horizon, 1.0) + volatility * Float.sqrt(maxFloat(horizon, 1.0)) * normals[i];
      -simulatedReturn * portfolioValue
    });
    let threshold = maxFloat(quantile(sortedCopy(losses), confidence), 0.0);
    averageTail(losses, threshold)
  };

  public func maximumDrawdown(equityCurve : [Float]) : Float {
    if (equityCurve.size() == 0) { return 0.0 };
    var peak = equityCurve[0];
    var maxDd = 0.0;
    for (value in equityCurve.vals()) {
      if (value > peak) { peak := value };
      let drawdown = if (peak <= EPS) { 0.0 } else { (peak - value) / peak };
      if (drawdown > maxDd) { maxDd := drawdown };
    };
    maxDd
  };

  func equityCurveFromReturns(returns : [Float], initialValue : Float) : [Float] {
    let levels = Array.toVarArray(Array.repeat<Float>(0.0, returns.size() + 1));
    levels[0] := initialValue;
    var i = 0;
    while (i < returns.size()) {
      levels[i + 1] := levels[i] * (1.0 + returns[i]);
      i += 1;
    };
    Array.tabulate<Float>(returns.size() + 1, func(idx) { levels[idx] })
  };

  public func tailRiskMeasures(returns : [Float], confidence : Float) : TailRiskMeasures {
    if (returns.size() == 0) {
      return {
        downsideDeviation = 0.0;
        tailRatio = 0.0;
        skewness = 0.0;
        excessKurtosis = 0.0;
        expectedShortfall = 0.0;
      };
    };

    let avg = mean(returns);
    let sigma = Float.sqrt(maxFloat(variance(returns), EPS));
    var downsideSum = 0.0;
    var downsideCount : Nat = 0;
    var skewAcc = 0.0;
    var kurtAcc = 0.0;
    for (r in returns.vals()) {
      let centered = r - avg;
      if (r < 0.0) {
        downsideSum += r * r;
        downsideCount += 1;
      };
      let z = centered / sigma;
      skewAcc += z * z * z;
      kurtAcc += z * z * z * z;
    };

    let sortedReturns = sortedCopy(returns);
    let upper = quantile(sortedReturns, 0.95);
    let lower = quantile(sortedReturns, 0.05);
    let expectedShortfall = historicalCVaR(returns, confidence, 1.0, 1.0);
    {
      downsideDeviation = if (downsideCount == 0) { 0.0 } else { Float.sqrt(downsideSum / downsideCount.toFloat()) };
      tailRatio = if (absFloat(lower) <= EPS) { 0.0 } else { upper / absFloat(lower) };
      skewness = skewAcc / returns.size().toFloat();
      excessKurtosis = kurtAcc / returns.size().toFloat() - 3.0;
      expectedShortfall = expectedShortfall;
    }
  };

  public func buildRiskReport(portfolioReturns : [Float], assetReturns : Matrix, confidence : Float, horizon : Float, portfolioValue : Float, simulations : Nat, seed : Nat) : RiskReport {
    let moments = sampleMoments(portfolioReturns);
    let varHist = historicalVaR(portfolioReturns, confidence, horizon, portfolioValue);
    let varParam = parametricVaR(moments.avg, moments.sigma, confidence, horizon, portfolioValue);
    let varMc = monteCarloVaR(moments.avg, moments.sigma, confidence, horizon, portfolioValue, simulations, seed);
    let cvarHist = historicalCVaR(portfolioReturns, confidence, horizon, portfolioValue);
    let cvarParam = parametricCVaR(moments.avg, moments.sigma, confidence, horizon, portfolioValue);
    let cvarMc = monteCarloCVaR(moments.avg, moments.sigma, confidence, horizon, portfolioValue, simulations, seed);
    {
      varResult = {
        historical = varHist;
        parametric = varParam;
        monteCarlo = varMc;
        confidence = confidence;
        horizon = horizon;
      };
      cvarResult = {
        historical = cvarHist;
        parametric = cvarParam;
        monteCarlo = cvarMc;
        confidence = confidence;
      };
      maxDrawdown = maximumDrawdown(equityCurveFromReturns(portfolioReturns, portfolioValue));
      correlationMatrix = estimateCorrelationMatrix(assetReturns);
      tailRisk = tailRiskMeasures(portfolioReturns, confidence);
    }
  };

  public func blackScholesGreeks(option : OptionInput) : Greeks {
    let sigmaT = option.volatility * Float.sqrt(maxFloat(option.timeToMaturity, EPS));
    let d1 = if (sigmaT <= EPS) {
      0.0
    } else {
      (Float.log(option.spot / option.strike) + (option.rate + 0.5 * option.volatility * option.volatility) * option.timeToMaturity) / sigmaT
    };
    let d2 = d1 - sigmaT;
    let pdf = normalPdf(d1);
    let cdfD1 = normalCdf(d1);
    let cdfD2 = normalCdf(d2);
    let delta = if (option.isCall) { cdfD1 } else { cdfD1 - 1.0 };
    let gamma = pdf / maxFloat(option.spot * sigmaT, EPS);
    let vega = option.spot * pdf * Float.sqrt(maxFloat(option.timeToMaturity, EPS));
    let thetaCore = -(option.spot * pdf * option.volatility) / (2.0 * Float.sqrt(maxFloat(option.timeToMaturity, EPS)));
    let theta = if (option.isCall) {
      thetaCore - option.rate * option.strike * Float.exp(-option.rate * option.timeToMaturity) * cdfD2
    } else {
      thetaCore + option.rate * option.strike * Float.exp(-option.rate * option.timeToMaturity) * normalCdf(-d2)
    };
    let rho = if (option.isCall) {
      option.strike * option.timeToMaturity * Float.exp(-option.rate * option.timeToMaturity) * cdfD2
    } else {
      -option.strike * option.timeToMaturity * Float.exp(-option.rate * option.timeToMaturity) * normalCdf(-d2)
    };
    { delta = delta; gamma = gamma; vega = vega; theta = theta; rho = rho; d1 = d1; d2 = d2 }
  };

  public func deltaHedge(option : OptionInput, optionPosition : Float, underlyingDelta : Float) : DeltaHedge {
    let greeks = blackScholesGreeks(option);
    let hedgeUnits = -(optionPosition * greeks.delta) / maxFloat(underlyingDelta, EPS);
    {
      optionDelta = optionPosition * greeks.delta;
      hedgeUnits = hedgeUnits;
      residualDelta = optionPosition * greeks.delta + hedgeUnits * underlyingDelta;
    }
  };

  public func gammaHedge(portfolioDelta : Float, portfolioGamma : Float, hedgeOption : Greeks, underlyingDelta : Float) : GammaHedge {
    let hedgeOptionUnits = -portfolioGamma / maxFloat(hedgeOption.gamma, EPS);
    let underlyingUnits = -(portfolioDelta + hedgeOptionUnits * hedgeOption.delta) / maxFloat(underlyingDelta, EPS);
    {
      hedgeOptionUnits = hedgeOptionUnits;
      underlyingUnits = underlyingUnits;
      residualDelta = portfolioDelta + hedgeOptionUnits * hedgeOption.delta + underlyingUnits * underlyingDelta;
      residualGamma = portfolioGamma + hedgeOptionUnits * hedgeOption.gamma;
    }
  };

  public func vegaHedge(portfolioDelta : Float, portfolioGamma : Float, portfolioVega : Float, firstHedge : Greeks, secondHedge : Greeks, underlyingDelta : Float) : VegaHedge {
    let hedgeSystem = [
      [firstHedge.gamma, secondHedge.gamma],
      [firstHedge.vega, secondHedge.vega],
    ];
    let rhs = [-portfolioGamma, -portfolioVega];
    let solution = solveLinearSystem(hedgeSystem, rhs);
    let firstUnits = if (solution.size() > 0) { solution[0] } else { 0.0 };
    let secondUnits = if (solution.size() > 1) { solution[1] } else { 0.0 };
    let underlyingUnits = -(portfolioDelta + firstUnits * firstHedge.delta + secondUnits * secondHedge.delta) / maxFloat(underlyingDelta, EPS);
    {
      firstOptionUnits = firstUnits;
      secondOptionUnits = secondUnits;
      underlyingUnits = underlyingUnits;
      residualDelta = portfolioDelta + firstUnits * firstHedge.delta + secondUnits * secondHedge.delta + underlyingUnits * underlyingDelta;
      residualGamma = portfolioGamma + firstUnits * firstHedge.gamma + secondUnits * secondHedge.gamma;
      residualVega = portfolioVega + firstUnits * firstHedge.vega + secondUnits * secondHedge.vega;
    }
  };

  public func dynamicRebalancing(currentWeights : [Float], targetWeights : [Float], threshold : Float) : DynamicRebalancePlan {
    let n = if (currentWeights.size() < targetWeights.size()) { currentWeights.size() } else { targetWeights.size() };
    let trades = Array.tabulate<Float>(n, func(i) { targetWeights[i] - currentWeights[i] });
    var turnover = 0.0;
    var rebalanceNow = false;
    var i = 0;
    while (i < n) {
      turnover += absFloat(trades[i]);
      if (absFloat(trades[i]) > threshold) { rebalanceNow := true };
      i += 1;
    };
    {
      currentWeights = Array.tabulate<Float>(n, func(idx) { currentWeights[idx] });
      targetWeights = Array.tabulate<Float>(n, func(idx) { targetWeights[idx] });
      tradeWeights = trades;
      turnover = turnover;
      rebalanceNow = rebalanceNow;
      threshold = threshold;
    }
  };

  public func kellyCriterion(expectedExcessReturn : Float, varianceEstimate : Float) : Float {
    clamp(expectedExcessReturn / maxFloat(varianceEstimate, EPS), -Phi.PHI, Phi.PHI)
  };

  public func binaryKelly(probabilityWin : Float, payoffOdds : Float) : Float {
    let p = clamp(probabilityWin, EPS, 1.0 - EPS);
    clamp((payoffOdds * p - (1.0 - p)) / maxFloat(payoffOdds, EPS), -1.0, 1.0)
  };

  func trimSeries(series : [Float], n : Nat) : [Float] {
    Array.tabulate<Float>(n, func(i) { series[i] })
  };

  func commonLength(base : [Float], others : Matrix) : Nat {
    var n = base.size();
    for (series in others.vals()) {
      if (series.size() < n) { n := series.size() };
    };
    n
  };

  func olsRegression(y : [Float], factorSeries : Matrix) : FactorRegressionResult {
    let n = commonLength(y, factorSeries);
    if (n == 0) {
      return { alpha = 0.0; betas = []; residualVariance = 0.0; rSquared = 0.0; fittedReturns = []; residuals = [] };
    };
    let k = factorSeries.size();
    let trimmedY = trimSeries(y, n);
    let x = Array.tabulate<[Float]>(n, func(t) {
      Array.tabulate<Float>(k + 1, func(j) {
        if (j == 0) { 1.0 } else { factorSeries[j - 1][t] }
      })
    });
    let xT = transpose(x);
    let betaAll = solveLinearSystem(addMatrix(matrixMultiply(xT, x), scaleMatrix(identity(k + 1), EPS)), matrixVectorMultiply(xT, trimmedY));
    let fitted = Array.tabulate<Float>(n, func(i) { dot(x[i], betaAll) });
    let residuals = Array.tabulate<Float>(n, func(i) { trimmedY[i] - fitted[i] });
    let meanY = mean(trimmedY);
    var ssTot = 0.0;
    var ssRes = 0.0;
    var i = 0;
    while (i < n) {
      let totalDiff = trimmedY[i] - meanY;
      ssTot += totalDiff * totalDiff;
      ssRes += residuals[i] * residuals[i];
      i += 1;
    };
    {
      alpha = if (betaAll.size() > 0) { betaAll[0] } else { 0.0 };
      betas = if (k == 0) { [] } else { Array.tabulate<Float>(k, func(idx) { betaAll[idx + 1] }) };
      residualVariance = if (n > k + 1) { ssRes / (n - k - 1).toFloat() } else { 0.0 };
      rSquared = if (ssTot <= EPS) { 0.0 } else { 1.0 - ssRes / ssTot };
      fittedReturns = fitted;
      residuals = residuals;
    }
  };

  public func fitFamaFrench3(returns : [Float], factors : FamaFrenchFactors) : FactorRegressionResult {
    let n = commonLength(returns, [factors.marketExcess, factors.smb, factors.hml, factors.riskFree]);
    let excess = Array.tabulate<Float>(n, func(i) { returns[i] - factors.riskFree[i] });
    olsRegression(excess, [trimSeries(factors.marketExcess, n), trimSeries(factors.smb, n), trimSeries(factors.hml, n)])
  };

  public func fitCarhart4(returns : [Float], factors : CarhartFactors) : FactorRegressionResult {
    let n = commonLength(returns, [factors.marketExcess, factors.smb, factors.hml, factors.momentum, factors.riskFree]);
    let excess = Array.tabulate<Float>(n, func(i) { returns[i] - factors.riskFree[i] });
    olsRegression(excess, [
      trimSeries(factors.marketExcess, n),
      trimSeries(factors.smb, n),
      trimSeries(factors.hml, n),
      trimSeries(factors.momentum, n),
    ])
  };

  func centerColumns(observations : Matrix) : { centered : Matrix; means : [Float] } {
    if (observations.size() == 0) {
      return { centered = []; means = [] };
    };
    let cols = observations[0].size();
    let means = Array.tabulate<Float>(cols, func(col) {
      var total = 0.0;
      var row = 0;
      while (row < observations.size()) {
        total += observations[row][col];
        row += 1;
      };
      total / observations.size().toFloat()
    });
    {
      centered = Array.tabulate<[Float]>(observations.size(), func(row) {
        Array.tabulate<Float>(cols, func(col) { observations[row][col] - means[col] })
      });
      means = means;
    }
  };

  func covarianceFromObservations(observations : Matrix) : Matrix {
    if (observations.size() == 0) { return [] };
    let centered = centerColumns(observations).centered;
    let obsCount = observations.size();
    let cols = observations[0].size();
    let centeredT = transpose(centered);
    Array.tabulate<[Float]>(cols, func(i) {
      Array.tabulate<Float>(cols, func(j) {
        dot(centeredT[i], centeredT[j]) / maxFloat((obsCount - 1).toFloat(), 1.0)
      })
    })
  };

  func powerIteration(matrix : Matrix, iterations : Nat) : [Float] {
    let n = matrix.size();
    if (n == 0) { return [] };
    var vector = Array.tabulate<Float>(n, func(_) { 1.0 / n.toFloat() });
    var iter = 0;
    let maxIterations = if (iterations == 0) { 50 } else { iterations };
    while (iter < maxIterations) {
      let next = matrixVectorMultiply(matrix, vector);
      let norm = vectorNorm(next);
      vector := if (norm <= EPS) { vector } else { scaleVector(next, 1.0 / norm) };
      iter += 1;
    };
    vector
  };

  public func principalComponentFactors(observations : Matrix, componentCount : Nat) : PCAResult {
    if (observations.size() == 0) {
      return { eigenvalues = []; eigenvectors = []; explainedVariance = []; factorScores = [] };
    };
    let centeredInfo = centerColumns(observations);
    let centered = centeredInfo.centered;
    let baseCov = covarianceFromObservations(observations);
    let maxComponents = Float.toInt(minFloat(componentCount.toFloat(), baseCov.size().toFloat()));
    let k = if (maxComponents < 0) { 0 } else { Int.abs(maxComponents) };
    let eigenvalues = Array.toVarArray(Array.repeat<Float>(0.0, k));
    let eigenvectors = Array.toVarArray(Array.repeat<[Float]>([], k));
    var working = baseCov;
    var idx = 0;
    while (idx < k) {
      let vec = powerIteration(working, 75);
      let lambda = maxFloat(dot(vec, matrixVectorMultiply(working, vec)), 0.0);
      eigenvalues[idx] := lambda;
      eigenvectors[idx] := vec;
      working := subtractMatrix(working, scaleMatrix(outerProduct(vec, vec), lambda));
      idx += 1;
    };
    let eigenvalueArr = Array.tabulate<Float>(k, func(i) { eigenvalues[i] });
    let totalVariance = maxFloat(sum(diagonal(baseCov)), EPS);
    let eigenvectorArr = Array.tabulate<[Float]>(k, func(i) { eigenvectors[i] });
    let scores = Array.tabulate<[Float]>(centered.size(), func(row) {
      Array.tabulate<Float>(k, func(col) { dot(centered[row], eigenvectorArr[col]) })
    });
    {
      eigenvalues = eigenvalueArr;
      eigenvectors = eigenvectorArr;
      explainedVariance = Array.tabulate<Float>(k, func(i) { eigenvalueArr[i] / totalVariance });
      factorScores = scores;
    }
  };

  public func riskFactorDecomposition(betas : [Float], factorCovariance : Matrix, residualVariance : Float) : FactorDecomposition {
    let marginal = matrixVectorMultiply(factorCovariance, betas);
    let contributions = Array.tabulate<Float>(betas.size(), func(i) { betas[i] * marginal[i] });
    let systematic = maxFloat(dot(betas, marginal), 0.0);
    {
      systematicRisk = systematic;
      idiosyncraticRisk = maxFloat(residualVariance, 0.0);
      factorContributions = contributions;
      marginalContributions = marginal;
    }
  };

  public func buildPortfolioOptimizationBundle(expectedReturns : [Float], covariance : Matrix, marketWeights : [Float], views : [BlackLittermanView], riskFreeRate : Float, portfolioReturns : [Float], assetReturns : Matrix, confidence : Float, horizon : Float, portfolioValue : Float, frontierPoints : Nat, simulations : Nat, seed : Nat, constraints : OptimizationConstraints) : PortfolioOptimizationBundle {
    {
      meanVariance = meanVarianceOptimize(expectedReturns, covariance, riskFreeRate, constraints);
      sharpeMaximum = maximizeSharpeRatio(expectedReturns, covariance, riskFreeRate, constraints);
      riskParity = riskParityAllocation(covariance, 200, 0.000001);
      phiWeighted = phiWeightedAllocation(expectedReturns, covariance, riskFreeRate, constraints);
      blackLitterman = blackLitterman(covariance, marketWeights, constraints.riskAversion, Phi.PHI_INV_2, views, riskFreeRate, constraints);
      efficientFrontier = efficientFrontier(expectedReturns, covariance, riskFreeRate, frontierPoints, constraints);
      riskReport = buildRiskReport(portfolioReturns, assetReturns, confidence, horizon, portfolioValue, simulations, seed);
    }
  };
}
