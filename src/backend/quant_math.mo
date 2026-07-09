import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Phi "phi";

/// quant_math.mo
///
/// A quantitative mathematics foundation library for PARALLAX.
///
/// The module provides:
/// - Stochastic calculus primitives and option pricing models.
/// - Linear algebra routines for matrix computation and decomposition.
/// - Optimization algorithms for smooth and convex programs.
/// - Numerical methods for integration, root finding, Monte Carlo, and PDEs.
///
/// Integration with the PARALLAX Phi library:
/// - Phi.PHI is used as the default ADMM penalty scale.
/// - Phi.PHI_INV and Phi.PHI_INV_5 define stable damping / tolerance floors.
/// - Phi.EULER_E is used in jump compensators and exponential diagnostics.
module {
  public type Vector = [Float];
  public type Matrix = [[Float]];
  type MutableVector = [var Float];
  type MutableMatrix = [[var Float]];

  public type OptionKind = { #call; #put };

  public type BlackScholesResult = {
    price : Float;
    delta : Float;
    gamma : Float;
    vega : Float;
    theta : Float;
    rho : Float;
    d1 : Float;
    d2 : Float;
  };

  public type GBMParams = {
    spot : Float;
    drift : Float;
    volatility : Float;
    maturity : Float;
    steps : Nat;
    seed : Nat;
  };

  public type PathSimulation = {
    times : Vector;
    values : Vector;
    average : Float;
    variance : Float;
    terminal : Float;
  };

  public type HestonParams = {
    spot : Float;
    variance0 : Float;
    drift : Float;
    meanReversion : Float;
    longVariance : Float;
    volOfVol : Float;
    correlation : Float;
    maturity : Float;
    steps : Nat;
    seed : Nat;
  };

  public type HestonPathSimulation = {
    times : Vector;
    spots : Vector;
    variances : Vector;
    terminalSpot : Float;
    averageVariance : Float;
  };

  public type MonteCarloPriceResult = {
    price : Float;
    standardError : Float;
    sampleMean : Float;
    sampleVariance : Float;
  };

  public type MertonParams = {
    spot : Float;
    drift : Float;
    volatility : Float;
    jumpIntensity : Float;
    jumpMean : Float;
    jumpVolatility : Float;
    maturity : Float;
    steps : Nat;
    seed : Nat;
  };

  public type MertonPathSimulation = {
    times : Vector;
    values : Vector;
    jumpsPerStep : [Nat];
    totalJumps : Nat;
    terminal : Float;
  };

  public type ItoInput = {
    timeDerivative : Float;
    stateDrift : Float;
    stateDiffusion : Float;
    firstSpatial : Float;
    secondSpatial : Float;
  };

  public type ItoResult = {
    drift : Float;
    diffusion : Float;
  };

  public type LUResult = {
    l : Matrix;
    u : Matrix;
    p : Matrix;
    pivotSign : Float;
  };

  public type QRResult = {
    q : Matrix;
    r : Matrix;
  };

  public type EigenResult = {
    values : Vector;
    vectors : Matrix;
    iterations : Nat;
  };

  public type SVDResult = {
    u : Matrix;
    singularValues : Vector;
    vt : Matrix;
  };

  public type OptimizationResult = {
    point : Vector;
    value : Float;
    iterations : Nat;
    converged : Bool;
    gradientNorm : Float;
  };

  public type ConjugateGradientResult = {
    solution : Vector;
    iterations : Nat;
    converged : Bool;
    residualNorm : Float;
  };

  public type ADMMResult = {
    solution : Vector;
    iterations : Nat;
    converged : Bool;
    primalResidual : Float;
    dualResidual : Float;
    objective : Float;
  };

  public type BoxConstraints = {
    lower : Vector;
    upper : Vector;
  };

  public type MonteCarloResult = {
    estimate : Float;
    variance : Float;
    standardError : Float;
  };

  public type FiniteDifferenceDerivative = {
    forward : Float;
    backward : Float;
    central : Float;
    second : Float;
  };

  public type FiniteDifferenceBlackScholesResult = {
    assetPrices : Vector;
    timeLevels : Vector;
    grid : Matrix;
    price : Float;
  };

  public type RootResult = {
    root : Float;
    iterations : Nat;
    converged : Bool;
    residual : Float;
  };

  public let PI : Float = 3.14159265358979323846;
  public let TWO_PI : Float = 6.28318530717958647692;
  public let GOLDEN_TOLERANCE : Float = Phi.PHI_INV_5 * 0.0001;
  public let DEFAULT_ADMM_RHO : Float = Phi.PHI;
  public let DEFAULT_RELAXATION : Float = Phi.PHI_INV;
  public let MIN_VARIANCE_FLOOR : Float = Phi.PHI_INV_5 * 0.000001;

  func tol(x : Float) : Float {
    if (x > 0.0) x else GOLDEN_TOLERANCE
  };

  func natToFloat(n : Nat) : Float {
    (n : Int).toFloat()
  };

  func absMax(a : Float, b : Float) : Float {
    if (Float.abs(a) > Float.abs(b)) a else b
  };

  func clamp(x : Float, lo : Float, hi : Float) : Float {
    Float.max(lo, Float.min(hi, x))
  };

  func safeSqrt(x : Float) : Float {
    Float.sqrt(Float.max(0.0, x))
  };

  func safeLog(x : Float) : Float {
    Float.log(Float.max(1.0e-12, x))
  };

  func rectangularCols(a : Matrix) : Nat {
    if (a.size() == 0) {
      0
    } else {
      let cols = a[0].size();
      var i : Nat = 1;
      while (i < a.size()) {
        assert (a[i].size() == cols);
        i += 1;
      };
      cols
    }
  };

  func copyVectorMutable(v : Vector) : MutableVector {
    let out = Array.init<Float>(v.size(), 0.0);
    var i : Nat = 0;
    while (i < v.size()) {
      out[i] := v[i];
      i += 1;
    };
    out
  };

  func freezeVector(v : MutableVector) : Vector {
    Array.tabulate<Float>(v.size(), func(i : Nat) : Float { v[i] })
  };

  func zeroMatrix(rows : Nat, cols : Nat) : MutableMatrix {
    Array.tabulate<MutableVector>(rows, func(_ : Nat) : MutableVector {
      Array.init<Float>(cols, 0.0)
    })
  };

  func copyMatrixMutable(a : Matrix) : MutableMatrix {
    let cols = rectangularCols(a);
    Array.tabulate<MutableVector>(a.size(), func(i : Nat) : MutableVector {
      let row = Array.init<Float>(cols, 0.0);
      var j : Nat = 0;
      while (j < cols) {
        row[j] := a[i][j];
        j += 1;
      };
      row
    })
  };

  func freezeMatrix(a : MutableMatrix) : Matrix {
    Array.tabulate<Vector>(a.size(), func(i : Nat) : Vector {
      freezeVector(a[i])
    })
  };

  func identityMatrix(n : Nat) : Matrix {
    let out = zeroMatrix(n, n);
    var i : Nat = 0;
    while (i < n) {
      out[i][i] := 1.0;
      i += 1;
    };
    freezeMatrix(out)
  };

  func swapRows(a : MutableMatrix, i : Nat, j : Nat) {
    if (i == j) return;
    let cols = a[i].size();
    var k : Nat = 0;
    while (k < cols) {
      let tmp = a[i][k];
      a[i][k] := a[j][k];
      a[j][k] := tmp;
      k += 1;
    }
  };

  func swapCols(a : MutableMatrix, i : Nat, j : Nat) {
    if (i == j) return;
    var r : Nat = 0;
    while (r < a.size()) {
      let tmp = a[r][i];
      a[r][i] := a[r][j];
      a[r][j] := tmp;
      r += 1;
    }
  };

  func dot(a : Vector, b : Vector) : Float {
    assert (a.size() == b.size());
    var s : Float = 0.0;
    var i : Nat = 0;
    while (i < a.size()) {
      s += a[i] * b[i];
      i += 1;
    };
    s
  };

  func vectorNorm2(a : Vector) : Float {
    safeSqrt(dot(a, a))
  };

  func vectorNormInf(a : Vector) : Float {
    var m : Float = 0.0;
    for (x in a.vals()) {
      m := Float.max(m, Float.abs(x));
    };
    m
  };

  func vectorAdd(a : Vector, b : Vector) : Vector {
    assert (a.size() == b.size());
    Array.tabulate<Float>(a.size(), func(i : Nat) : Float {
      a[i] + b[i]
    })
  };

  func vectorSub(a : Vector, b : Vector) : Vector {
    assert (a.size() == b.size());
    Array.tabulate<Float>(a.size(), func(i : Nat) : Float {
      a[i] - b[i]
    })
  };

  func vectorScale(alpha : Float, a : Vector) : Vector {
    Array.tabulate<Float>(a.size(), func(i : Nat) : Float { alpha * a[i] })
  };

  func matrixAdd(a : Matrix, b : Matrix) : Matrix {
    let rows = a.size();
    let cols = rectangularCols(a);
    assert (rows == b.size());
    assert (cols == rectangularCols(b));
    let out = zeroMatrix(rows, cols);
    var i : Nat = 0;
    while (i < rows) {
      var j : Nat = 0;
      while (j < cols) {
        out[i][j] := a[i][j] + b[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func matrixSub(a : Matrix, b : Matrix) : Matrix {
    let rows = a.size();
    let cols = rectangularCols(a);
    assert (rows == b.size());
    assert (cols == rectangularCols(b));
    let out = zeroMatrix(rows, cols);
    var i : Nat = 0;
    while (i < rows) {
      var j : Nat = 0;
      while (j < cols) {
        out[i][j] := a[i][j] - b[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func matrixScale(alpha : Float, a : Matrix) : Matrix {
    let rows = a.size();
    let cols = rectangularCols(a);
    let out = zeroMatrix(rows, cols);
    var i : Nat = 0;
    while (i < rows) {
      var j : Nat = 0;
      while (j < cols) {
        out[i][j] := alpha * a[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func column(a : Matrix, j : Nat) : Vector {
    Array.tabulate<Float>(a.size(), func(i : Nat) : Float { a[i][j] })
  };

  func mutableColumnDot(a : MutableMatrix, colIndex : Nat, v : MutableVector) : Float {
    var s : Float = 0.0;
    var i : Nat = 0;
    while (i < a.size()) {
      s += a[i][colIndex] * v[i];
      i += 1;
    };
    s
  };

  func mutableColumnNorm(a : MutableMatrix, colIndex : Nat) : Float {
    var s : Float = 0.0;
    var i : Nat = 0;
    while (i < a.size()) {
      s += a[i][colIndex] * a[i][colIndex];
      i += 1;
    };
    safeSqrt(s)
  };

  func orthonormalizeColumns(a : MutableMatrix, cols : Nat) {
    let rows = a.size();
    var j : Nat = 0;
    while (j < cols) {
      var i : Nat = 0;
      while (i < j) {
        var proj : Float = 0.0;
        var r : Nat = 0;
        while (r < rows) {
          proj += a[r][i] * a[r][j];
          r += 1;
        };
        r := 0;
        while (r < rows) {
          a[r][j] := a[r][j] - proj * a[r][i];
          r += 1;
        };
        i += 1;
      };
      let nrm = mutableColumnNorm(a, j);
      if (nrm > GOLDEN_TOLERANCE) {
        var r2 : Nat = 0;
        while (r2 < rows) {
          a[r2][j] := a[r2][j] / nrm;
          r2 += 1;
        }
      };
      j += 1;
    }
  };

  func offDiagonalNorm(a : Matrix) : Float {
    let n = a.size();
    var s : Float = 0.0;
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j < rectangularCols(a)) {
        if (i != j) {
          s += a[i][j] * a[i][j];
        };
        j += 1;
      };
      i += 1;
    };
    safeSqrt(s)
  };

  func lcgNext(state : Nat) : Nat {
    ((state * 1_103_515_245) + 12_345) % 2_147_483_647
  };

  func uniform01(state : Nat) : (Nat, Float) {
    let next = lcgNext(state + 1);
    (next, Float.max(1.0e-12, natToFloat(next) / 2_147_483_647.0))
  };

  func standardNormal(state : Nat) : (Nat, Float) {
    let (s1, u1Raw) = uniform01(state);
    let (s2, u2) = uniform01(s1);
    let u1 = Float.max(1.0e-12, u1Raw);
    let radius = safeSqrt(-2.0 * safeLog(u1));
    let angle = TWO_PI * u2;
    (s2, radius * Float.cos(angle))
  };

  func correlatedNormals(state : Nat, rho : Float) : (Nat, Float, Float) {
    let boundedRho = clamp(rho, -0.999999, 0.999999);
    let (s1, z1) = standardNormal(state);
    let (s2, z2) = standardNormal(s1);
    let zCorr = boundedRho * z1 + safeSqrt(1.0 - boundedRho * boundedRho) * z2;
    (s2, z1, zCorr)
  };

  func samplePoisson(state : Nat, lambda : Float) : (Nat, Nat) {
    if (lambda <= 0.0) {
      return (state, 0);
    };
    let limit = Float.exp(-lambda);
    var s = state;
    var product : Float = 1.0;
    var k : Nat = 0;
    loop {
      let (sn, u) = uniform01(s);
      s := sn;
      product *= u;
      if (product <= limit) {
        return (s, k);
      };
      k += 1;
    }
  };

  func normalPdf(x : Float) : Float {
    Float.exp(-0.5 * x * x) / safeSqrt(TWO_PI)
  };

  func normalCdf(x : Float) : Float {
    let ax = Float.abs(x);
    let k = 1.0 / (1.0 + 0.2316419 * ax);
    let poly = k * (0.319381530 + k * (-0.356563782 + k * (1.781477937 + k * (-1.821255978 + 1.330274429 * k))));
    let approx = 1.0 - normalPdf(ax) * poly;
    if (x >= 0.0) approx else 1.0 - approx
  };

  func payoff(kind : OptionKind, spot : Float, strike : Float) : Float {
    switch (kind) {
      case (#call) Float.max(spot - strike, 0.0);
      case (#put) Float.max(strike - spot, 0.0);
    }
  };

  /// Full Black-Scholes pricing with major Greeks for European calls and puts.
  public func blackScholes(
    kind : OptionKind,
    spot : Float,
    strike : Float,
    rate : Float,
    volatility : Float,
    maturity : Float
  ) : BlackScholesResult {
    let sigma = Float.max(Float.abs(volatility), MIN_VARIANCE_FLOOR);
    let t = Float.max(maturity, GOLDEN_TOLERANCE);
    let sqrtT = safeSqrt(t);
    let d1 = (safeLog(spot / strike) + (rate + 0.5 * sigma * sigma) * t) / (sigma * sqrtT);
    let d2 = d1 - sigma * sqrtT;
    let disc = Float.exp(-rate * t);
    let nd1 = normalCdf(d1);
    let nd2 = normalCdf(d2);
    let pdfd1 = normalPdf(d1);

    switch (kind) {
      case (#call) {
        {
          price = spot * nd1 - strike * disc * nd2;
          delta = nd1;
          gamma = pdfd1 / Float.max(spot * sigma * sqrtT, GOLDEN_TOLERANCE);
          vega = spot * pdfd1 * sqrtT;
          theta = -(spot * pdfd1 * sigma) / (2.0 * sqrtT) - rate * strike * disc * nd2;
          rho = strike * t * disc * nd2;
          d1 = d1;
          d2 = d2;
        }
      };
      case (#put) {
        {
          price = strike * disc * normalCdf(-d2) - spot * normalCdf(-d1);
          delta = nd1 - 1.0;
          gamma = pdfd1 / Float.max(spot * sigma * sqrtT, GOLDEN_TOLERANCE);
          vega = spot * pdfd1 * sqrtT;
          theta = -(spot * pdfd1 * sigma) / (2.0 * sqrtT) + rate * strike * disc * normalCdf(-d2);
          rho = -strike * t * disc * normalCdf(-d2);
          d1 = d1;
          d2 = d2;
        }
      };
    }
  };

  /// Simulates a geometric Brownian motion path using the exact log-Euler update.
  public func simulateGeometricBrownianMotion(params : GBMParams) : PathSimulation {
    let steps = Nat.max(params.steps, 1);
    let dt = params.maturity / natToFloat(steps);
    let sqrtDt = safeSqrt(dt);
    let times = Array.init<Float>(steps + 1, 0.0);
    let values = Array.init<Float>(steps + 1, 0.0);
    values[0] := params.spot;
    var state = Nat.max(params.seed, 1);
    var sum : Float = params.spot;
    var sumSq : Float = params.spot * params.spot;
    var i : Nat = 1;
    while (i <= steps) {
      let (s1, z) = standardNormal(state);
      state := s1;
      let increment = (params.drift - 0.5 * params.volatility * params.volatility) * dt + params.volatility * sqrtDt * z;
      times[i] := natToFloat(i) * dt;
      values[i] := values[i - 1] * Float.exp(increment);
      sum += values[i];
      sumSq += values[i] * values[i];
      i += 1;
    };
    let nObs = natToFloat(steps + 1);
    let avg = sum / nObs;
    {
      times = freezeVector(times);
      values = freezeVector(values);
      average = avg;
      variance = Float.max(0.0, sumSq / nObs - avg * avg);
      terminal = values[steps];
    }
  };

  /// Generic Ito lemma evaluator for scalar diffusions dX = mu dt + sigma dW.
  public func itoLemma(input : ItoInput) : ItoResult {
    {
      drift = input.timeDerivative
        + input.stateDrift * input.firstSpatial
        + 0.5 * input.stateDiffusion * input.stateDiffusion * input.secondSpatial;
      diffusion = input.stateDiffusion * input.firstSpatial;
    }
  };

  /// Ito application for log(S_t) under geometric Brownian motion.
  public func itoLogGBM(spot : Float, drift : Float, volatility : Float) : ItoResult {
    let s = Float.max(spot, GOLDEN_TOLERANCE);
    itoLemma({
      timeDerivative = 0.0;
      stateDrift = drift * s;
      stateDiffusion = volatility * s;
      firstSpatial = 1.0 / s;
      secondSpatial = -1.0 / (s * s);
    })
  };

  /// Ito application for f(S) = S^power under geometric Brownian motion.
  public func itoPowerGBM(power : Float, spot : Float, drift : Float, volatility : Float) : ItoResult {
    let s = Float.max(spot, GOLDEN_TOLERANCE);
    let sPow = Float.pow(s, power);
    itoLemma({
      timeDerivative = 0.0;
      stateDrift = drift * s;
      stateDiffusion = volatility * s;
      firstSpatial = power * sPow / s;
      secondSpatial = power * (power - 1.0) * sPow / (s * s);
    })
  };

  /// Heston path simulation with full-truncation Euler updates.
  public func simulateHestonPath(params : HestonParams) : HestonPathSimulation {
    let steps = Nat.max(params.steps, 1);
    let dt = params.maturity / natToFloat(steps);
    let sqrtDt = safeSqrt(dt);
    let times = Array.init<Float>(steps + 1, 0.0);
    let spots = Array.init<Float>(steps + 1, 0.0);
    let variances = Array.init<Float>(steps + 1, 0.0);
    spots[0] := params.spot;
    variances[0] := Float.max(params.variance0, MIN_VARIANCE_FLOOR);
    var variance = variances[0];
    var state = Nat.max(params.seed, 1);
    var varianceSum : Float = variance;
    var i : Nat = 1;
    while (i <= steps) {
      let (s1, z1, z2) = correlatedNormals(state, params.correlation);
      state := s1;
      let vPos = Float.max(variance, 0.0);
      let vol = safeSqrt(vPos);
      let logStep = (params.drift - 0.5 * vPos) * dt + vol * sqrtDt * z1;
      spots[i] := Float.max(GOLDEN_TOLERANCE, spots[i - 1] * Float.exp(logStep));
      let nextVariance = variance
        + params.meanReversion * (params.longVariance - vPos) * dt
        + params.volOfVol * vol * sqrtDt * z2;
      variance := Float.max(nextVariance, MIN_VARIANCE_FLOOR);
      variances[i] := variance;
      times[i] := natToFloat(i) * dt;
      varianceSum += variance;
      i += 1;
    };
    {
      times = freezeVector(times);
      spots = freezeVector(spots);
      variances = freezeVector(variances);
      terminalSpot = spots[steps];
      averageVariance = varianceSum / natToFloat(steps + 1);
    }
  };

  /// Monte Carlo European pricing under the Heston stochastic-volatility model.
  public func hestonEuropeanPrice(
    kind : OptionKind,
    model : HestonParams,
    strike : Float,
    rate : Float,
    paths : Nat
  ) : MonteCarloPriceResult {
    let nPaths = Nat.max(paths, 1);
    var sum : Float = 0.0;
    var sumSq : Float = 0.0;
    var i : Nat = 0;
    while (i < nPaths) {
      let path = simulateHestonPath({
        spot = model.spot;
        variance0 = model.variance0;
        drift = rate;
        meanReversion = model.meanReversion;
        longVariance = model.longVariance;
        volOfVol = model.volOfVol;
        correlation = model.correlation;
        maturity = model.maturity;
        steps = model.steps;
        seed = model.seed + i * 7 + 1;
      });
      let discounted = Float.exp(-rate * model.maturity) * payoff(kind, path.terminalSpot, strike);
      sum += discounted;
      sumSq += discounted * discounted;
      i += 1;
    };
    let nF = natToFloat(nPaths);
    let mean = sum / nF;
    let variance = Float.max(0.0, sumSq / nF - mean * mean);
    {
      price = mean;
      standardError = safeSqrt(variance / nF);
      sampleMean = mean;
      sampleVariance = variance;
    }
  };

  /// Merton jump-diffusion path simulation with lognormal jumps.
  public func simulateMertonJumpDiffusion(params : MertonParams) : MertonPathSimulation {
    let steps = Nat.max(params.steps, 1);
    let dt = params.maturity / natToFloat(steps);
    let sqrtDt = safeSqrt(dt);
    let times = Array.init<Float>(steps + 1, 0.0);
    let values = Array.init<Float>(steps + 1, 0.0);
    let jumps = Array.init<Nat>(steps + 1, 0);
    values[0] := params.spot;
    let kappa = Float.exp(params.jumpMean + 0.5 * params.jumpVolatility * params.jumpVolatility) - 1.0;
    var state = Nat.max(params.seed, 1);
    var totalJumps : Nat = 0;
    var i : Nat = 1;
    while (i <= steps) {
      let (s1, z) = standardNormal(state);
      let (s2, jumpCount) = samplePoisson(s1, params.jumpIntensity * dt);
      state := s2;
      var jumpSum : Float = 0.0;
      var j : Nat = 0;
      while (j < jumpCount) {
        let (sn, zj) = standardNormal(state);
        state := sn;
        jumpSum += params.jumpMean + params.jumpVolatility * zj;
        j += 1;
      };
      let driftAdj = params.drift - params.jumpIntensity * kappa - 0.5 * params.volatility * params.volatility;
      let logMove = driftAdj * dt + params.volatility * sqrtDt * z + jumpSum;
      values[i] := Float.max(GOLDEN_TOLERANCE, values[i - 1] * Float.exp(logMove));
      jumps[i] := jumpCount;
      times[i] := natToFloat(i) * dt;
      totalJumps += jumpCount;
      i += 1;
    };
    {
      times = freezeVector(times);
      values = freezeVector(values);
      jumpsPerStep = Array.tabulate<Nat>(jumps.size(), func(k : Nat) : Nat { jumps[k] });
      totalJumps = totalJumps;
      terminal = values[steps];
    }
  };

  /// Monte Carlo European pricing under the Merton jump-diffusion model.
  public func mertonEuropeanPrice(
    kind : OptionKind,
    model : MertonParams,
    strike : Float,
    rate : Float,
    paths : Nat
  ) : MonteCarloPriceResult {
    let nPaths = Nat.max(paths, 1);
    var sum : Float = 0.0;
    var sumSq : Float = 0.0;
    var i : Nat = 0;
    while (i < nPaths) {
      let path = simulateMertonJumpDiffusion({
        spot = model.spot;
        drift = rate;
        volatility = model.volatility;
        jumpIntensity = model.jumpIntensity;
        jumpMean = model.jumpMean;
        jumpVolatility = model.jumpVolatility;
        maturity = model.maturity;
        steps = model.steps;
        seed = model.seed + i * 11 + 3;
      });
      let discounted = Float.exp(-rate * model.maturity) * payoff(kind, path.terminal, strike);
      sum += discounted;
      sumSq += discounted * discounted;
      i += 1;
    };
    let nF = natToFloat(nPaths);
    let mean = sum / nF;
    let variance = Float.max(0.0, sumSq / nF - mean * mean);
    {
      price = mean;
      standardError = safeSqrt(variance / nF);
      sampleMean = mean;
      sampleVariance = variance;
    }
  };

  /// Matrix multiplication A * B.
  public func matrixMultiply(a : Matrix, b : Matrix) : Matrix {
    let rowsA = a.size();
    let colsA = rectangularCols(a);
    let rowsB = b.size();
    let colsB = rectangularCols(b);
    assert (colsA == rowsB);
    let out = zeroMatrix(rowsA, colsB);
    var i : Nat = 0;
    while (i < rowsA) {
      var k : Nat = 0;
      while (k < colsA) {
        let aik = a[i][k];
        var j : Nat = 0;
        while (j < colsB) {
          out[i][j] := out[i][j] + aik * b[k][j];
          j += 1;
        };
        k += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  /// Matrix-vector product A * x.
  public func matrixVectorMultiply(a : Matrix, x : Vector) : Vector {
    let rows = a.size();
    let cols = rectangularCols(a);
    assert (cols == x.size());
    Array.tabulate<Float>(rows, func(i : Nat) : Float {
      var s : Float = 0.0;
      var j : Nat = 0;
      while (j < cols) {
        s += a[i][j] * x[j];
        j += 1;
      };
      s
    })
  };

  /// Matrix transpose.
  public func transpose(a : Matrix) : Matrix {
    let rows = a.size();
    let cols = rectangularCols(a);
    let out = zeroMatrix(cols, rows);
    var i : Nat = 0;
    while (i < rows) {
      var j : Nat = 0;
      while (j < cols) {
        out[j][i] := a[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  /// LU decomposition with partial pivoting (Doolittle form).
  public func luDecomposition(a : Matrix) : LUResult {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    let u = copyMatrixMutable(a);
    let l = zeroMatrix(n, n);
    let p = zeroMatrix(n, n);
    var i : Nat = 0;
    while (i < n) {
      l[i][i] := 1.0;
      p[i][i] := 1.0;
      i += 1;
    };
    var pivotSign : Float = 1.0;
    var k : Nat = 0;
    while (k < n) {
      var pivot = k;
      var maxVal = Float.abs(u[k][k]);
      var r : Nat = k + 1;
      while (r < n) {
        let cand = Float.abs(u[r][k]);
        if (cand > maxVal) {
          maxVal := cand;
          pivot := r;
        };
        r += 1;
      };
      assert (maxVal > GOLDEN_TOLERANCE);
      if (pivot != k) {
        swapRows(u, k, pivot);
        swapRows(p, k, pivot);
        var c : Nat = 0;
        while (c < k) {
          let tmp = l[k][c];
          l[k][c] := l[pivot][c];
          l[pivot][c] := tmp;
          c += 1;
        };
        pivotSign := -pivotSign;
      };
      r := k + 1;
      while (r < n) {
        let factor = u[r][k] / u[k][k];
        l[r][k] := factor;
        var c2 : Nat = k;
        while (c2 < n) {
          u[r][c2] := u[r][c2] - factor * u[k][c2];
          c2 += 1;
        };
        r += 1;
      };
      k += 1;
    };
    {
      l = freezeMatrix(l);
      u = freezeMatrix(u);
      p = freezeMatrix(p);
      pivotSign = pivotSign;
    }
  };

  /// Matrix inverse via Gauss-Jordan elimination with partial pivoting.
  public func matrixInverse(a : Matrix) : Matrix {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    let aug = zeroMatrix(n, 2 * n);
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j < n) {
        aug[i][j] := a[i][j];
        aug[i][n + j] := if (i == j) 1.0 else 0.0;
        j += 1;
      };
      i += 1;
    };
    var col : Nat = 0;
    while (col < n) {
      var pivot = col;
      var maxVal = Float.abs(aug[col][col]);
      var r : Nat = col + 1;
      while (r < n) {
        let cand = Float.abs(aug[r][col]);
        if (cand > maxVal) {
          maxVal := cand;
          pivot := r;
        };
        r += 1;
      };
      assert (maxVal > GOLDEN_TOLERANCE);
      swapRows(aug, col, pivot);
      let pivotVal = aug[col][col];
      var j2 : Nat = 0;
      while (j2 < 2 * n) {
        aug[col][j2] := aug[col][j2] / pivotVal;
        j2 += 1;
      };
      r := 0;
      while (r < n) {
        if (r != col) {
          let factor = aug[r][col];
          var c : Nat = 0;
          while (c < 2 * n) {
            aug[r][c] := aug[r][c] - factor * aug[col][c];
            c += 1;
          }
        };
        r += 1;
      };
      col += 1;
    };
    let inv = zeroMatrix(n, n);
    i := 0;
    while (i < n) {
      var j3 : Nat = 0;
      while (j3 < n) {
        inv[i][j3] := aug[i][n + j3];
        j3 += 1;
      };
      i += 1;
    };
    freezeMatrix(inv)
  };

  /// Cholesky decomposition A = L * L^T for symmetric positive definite matrices.
  public func choleskyDecomposition(a : Matrix) : Matrix {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    let l = zeroMatrix(n, n);
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j <= i) {
        var sum = a[i][j];
        var k : Nat = 0;
        while (k < j) {
          sum -= l[i][k] * l[j][k];
          k += 1;
        };
        if (i == j) {
          assert (sum > 0.0);
          l[i][j] := safeSqrt(sum);
        } else {
          l[i][j] := sum / l[j][j];
        };
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(l)
  };

  /// QR decomposition using modified Gram-Schmidt orthogonalization.
  public func qrDecomposition(a : Matrix) : QRResult {
    let m = a.size();
    let n = rectangularCols(a);
    let q = zeroMatrix(m, n);
    let r = zeroMatrix(n, n);
    var j : Nat = 0;
    while (j < n) {
      let v = Array.init<Float>(m, 0.0);
      var row : Nat = 0;
      while (row < m) {
        v[row] := a[row][j];
        row += 1;
      };
      var i : Nat = 0;
      while (i < j) {
        let rij = mutableColumnDot(q, i, v);
        r[i][j] := rij;
        row := 0;
        while (row < m) {
          v[row] := v[row] - rij * q[row][i];
          row += 1;
        };
        i += 1;
      };
      var normV : Float = 0.0;
      row := 0;
      while (row < m) {
        normV += v[row] * v[row];
        row += 1;
      };
      normV := safeSqrt(normV);
      r[j][j] := normV;
      if (normV > GOLDEN_TOLERANCE) {
        row := 0;
        while (row < m) {
          q[row][j] := v[row] / normV;
          row += 1;
        }
      };
      j += 1;
    };
    {
      q = freezeMatrix(q);
      r = freezeMatrix(r);
    }
  };

  /// Symmetric eigenvalue/eigenvector computation using the Jacobi rotation method.
  public func symmetricEigenDecomposition(a : Matrix, tolerance : Float, maxIterations : Nat) : EigenResult {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    let work = copyMatrixMutable(a);
    let v = copyMatrixMutable(identityMatrix(n));
    let eps = tol(tolerance);
    var iter : Nat = 0;
    label l while (iter < maxIterations) {
      var p : Nat = 0;
      var q : Nat = 1;
      var maxOff : Float = 0.0;
      var i : Nat = 0;
      while (i < n) {
        var j : Nat = i + 1;
        while (j < n) {
          let magnitude = Float.abs(work[i][j]);
          if (magnitude > maxOff) {
            maxOff := magnitude;
            p := i;
            q := j;
          };
          j += 1;
        };
        i += 1;
      };
      if (maxOff < eps) {
        break l;
      };
      let app = work[p][p];
      let aqq = work[q][q];
      let apq = work[p][q];
      let tau = (aqq - app) / (2.0 * apq);
      let t = if (tau >= 0.0) {
        1.0 / (tau + safeSqrt(1.0 + tau * tau))
      } else {
        -1.0 / (-tau + safeSqrt(1.0 + tau * tau))
      };
      let c = 1.0 / safeSqrt(1.0 + t * t);
      let s = t * c;

      var k : Nat = 0;
      while (k < n) {
        if (k != p and k != q) {
          let aik = work[k][p];
          let akq = work[k][q];
          work[k][p] := c * aik - s * akq;
          work[p][k] := work[k][p];
          work[k][q] := s * aik + c * akq;
          work[q][k] := work[k][q];
        };
        k += 1;
      };
      work[p][p] := c * c * app - 2.0 * s * c * apq + s * s * aqq;
      work[q][q] := s * s * app + 2.0 * s * c * apq + c * c * aqq;
      work[p][q] := 0.0;
      work[q][p] := 0.0;

      k := 0;
      while (k < n) {
        let vkp = v[k][p];
        let vkq = v[k][q];
        v[k][p] := c * vkp - s * vkq;
        v[k][q] := s * vkp + c * vkq;
        k += 1;
      };
      iter += 1;
    };
    {
      values = Array.tabulate<Float>(n, func(i : Nat) : Float { work[i][i] });
      vectors = freezeMatrix(v);
      iterations = iter;
    }
  };

  /// General real eigenvalue/eigenvector approximation via shifted QR iteration.
  public func eigenDecomposition(a : Matrix, tolerance : Float, maxIterations : Nat) : EigenResult {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    let eps = tol(tolerance);
    var current = a;
    var eigenvectors = identityMatrix(n);
    var iter : Nat = 0;
    label l while (iter < maxIterations) {
      if (offDiagonalNorm(current) < eps) {
        break l;
      };
      let shift = current[n - 1][n - 1];
      let shifted = matrixSub(current, matrixScale(shift, identityMatrix(n)));
      let qr = qrDecomposition(shifted);
      current := matrixAdd(matrixMultiply(qr.r, qr.q), matrixScale(shift, identityMatrix(n)));
      eigenvectors := matrixMultiply(eigenvectors, qr.q);
      iter += 1;
    };
    {
      values = Array.tabulate<Float>(n, func(i : Nat) : Float { current[i][i] });
      vectors = eigenvectors;
      iterations = iter;
    }
  };

  /// Thin SVD A = U * diag(s) * V^T using eigen-analysis of A^T A.
  public func singularValueDecomposition(a : Matrix, tolerance : Float, maxIterations : Nat) : SVDResult {
    let m = a.size();
    let n = rectangularCols(a);
    let k = Nat.min(m, n);
    let at = transpose(a);
    let ata = matrixMultiply(at, a);
    let eig = symmetricEigenDecomposition(ata, tolerance, maxIterations);
    let values = copyVectorMutable(eig.values);
    let vecs = copyMatrixMutable(eig.vectors);

    var i : Nat = 0;
    while (i < n) {
      if (values[i] < 0.0 and Float.abs(values[i]) < 10.0 * tol(tolerance)) {
        values[i] := 0.0;
      };
      i += 1;
    };

    i := 0;
    while (i < n) {
      var best = i;
      var j : Nat = i + 1;
      while (j < n) {
        if (values[j] > values[best]) {
          best := j;
        };
        j += 1;
      };
      if (best != i) {
        let tmp = values[i];
        values[i] := values[best];
        values[best] := tmp;
        swapCols(vecs, i, best);
      };
      i += 1;
    };

    let singularValuesVar = Array.init<Float>(k, 0.0);
    let vt = zeroMatrix(k, n);
    let u = zeroMatrix(m, k);
    i := 0;
    while (i < k) {
      let sigma = safeSqrt(Float.max(values[i], 0.0));
      singularValuesVar[i] := sigma;
      var row : Nat = 0;
      while (row < n) {
        vt[i][row] := vecs[row][i];
        row += 1;
      };
      if (sigma > tol(tolerance)) {
        let vCol = Array.tabulate<Float>(n, func(idx : Nat) : Float { vecs[idx][i] });
        let av = matrixVectorMultiply(a, vCol);
        row := 0;
        while (row < m) {
          u[row][i] := av[row] / sigma;
          row += 1;
        }
      };
      i += 1;
    };
    orthonormalizeColumns(u, k);
    {
      u = freezeMatrix(u);
      singularValues = freezeVector(singularValuesVar);
      vt = freezeMatrix(vt);
    }
  };

  func solveLinearSystem(a : Matrix, b : Vector) : Vector {
    let n = a.size();
    let cols = rectangularCols(a);
    assert (n == cols);
    assert (b.size() == n);
    let aug = zeroMatrix(n, n + 1);
    var i : Nat = 0;
    while (i < n) {
      var j : Nat = 0;
      while (j < n) {
        aug[i][j] := a[i][j];
        j += 1;
      };
      aug[i][n] := b[i];
      i += 1;
    };
    var col : Nat = 0;
    while (col < n) {
      var pivot = col;
      var maxVal = Float.abs(aug[col][col]);
      var r : Nat = col + 1;
      while (r < n) {
        let cand = Float.abs(aug[r][col]);
        if (cand > maxVal) {
          maxVal := cand;
          pivot := r;
        };
        r += 1;
      };
      assert (maxVal > GOLDEN_TOLERANCE);
      swapRows(aug, col, pivot);
      let pivotVal = aug[col][col];
      var c : Nat = col;
      while (c <= n) {
        aug[col][c] := aug[col][c] / pivotVal;
        c += 1;
      };
      r := 0;
      while (r < n) {
        if (r != col) {
          let factor = aug[r][col];
          c := col;
          while (c <= n) {
            aug[r][c] := aug[r][c] - factor * aug[col][c];
            c += 1;
          }
        };
        r += 1;
      };
      col += 1;
    };
    Array.tabulate<Float>(n, func(idx : Nat) : Float { aug[idx][n] })
  };

  func quadraticObjective(q : Matrix, c : Vector, x : Vector) : Float {
    0.5 * dot(x, matrixVectorMultiply(q, x)) + dot(c, x)
  };

  /// Standard gradient descent for smooth objective minimization.
  public func gradientDescent(
    initial : Vector,
    objective : (Vector) -> Float,
    gradient : (Vector) -> Vector,
    learningRate : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : OptimizationResult {
    var x = initial;
    let alpha = Float.max(learningRate, Phi.PHI_INV_5 * 0.01);
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var gradNorm = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let g = gradient(x);
      gradNorm := vectorNorm2(g);
      if (gradNorm < eps) {
        converged := true;
        break l;
      };
      x := vectorSub(x, vectorScale(alpha, g));
      iter += 1;
    };
    {
      point = x;
      value = objective(x);
      iterations = iter;
      converged = converged;
      gradientNorm = gradNorm;
    }
  };

  /// Momentum gradient descent using velocity accumulation.
  public func momentumGradientDescent(
    initial : Vector,
    objective : (Vector) -> Float,
    gradient : (Vector) -> Vector,
    learningRate : Float,
    momentum : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : OptimizationResult {
    var x = initial;
    var v = Array.tabulate<Float>(initial.size(), func(_ : Nat) : Float { 0.0 });
    let alpha = Float.max(learningRate, Phi.PHI_INV_5 * 0.01);
    let beta = clamp(momentum, 0.0, 0.999);
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var gradNorm = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let g = gradient(x);
      gradNorm := vectorNorm2(g);
      if (gradNorm < eps) {
        converged := true;
        break l;
      };
      v := Array.tabulate<Float>(v.size(), func(i : Nat) : Float {
        beta * v[i] + alpha * g[i]
      });
      x := vectorSub(x, v);
      iter += 1;
    };
    {
      point = x;
      value = objective(x);
      iterations = iter;
      converged = converged;
      gradientNorm = gradNorm;
    }
  };

  /// Adam optimizer with bias correction.
  public func adam(
    initial : Vector,
    objective : (Vector) -> Float,
    gradient : (Vector) -> Vector,
    learningRate : Float,
    beta1 : Float,
    beta2 : Float,
    epsilon : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : OptimizationResult {
    var x = initial;
    var m = Array.tabulate<Float>(initial.size(), func(_ : Nat) : Float { 0.0 });
    var v = Array.tabulate<Float>(initial.size(), func(_ : Nat) : Float { 0.0 });
    let alpha = Float.max(learningRate, Phi.PHI_INV_5 * 0.01);
    let b1 = clamp(beta1, 0.0, 0.9999);
    let b2 = clamp(beta2, 0.0, 0.999999);
    let epsNumerical = Float.max(epsilon, 1.0e-12);
    let stopTol = tol(tolerance);
    var iter : Nat = 0;
    var gradNorm = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let g = gradient(x);
      gradNorm := vectorNorm2(g);
      if (gradNorm < stopTol) {
        converged := true;
        break l;
      };
      let t = natToFloat(iter + 1);
      m := Array.tabulate<Float>(m.size(), func(i : Nat) : Float {
        b1 * m[i] + (1.0 - b1) * g[i]
      });
      v := Array.tabulate<Float>(v.size(), func(i : Nat) : Float {
        b2 * v[i] + (1.0 - b2) * g[i] * g[i]
      });
      x := Array.tabulate<Float>(x.size(), func(i : Nat) : Float {
        let mHat = m[i] / (1.0 - Float.pow(b1, t));
        let vHat = v[i] / (1.0 - Float.pow(b2, t));
        x[i] - alpha * mHat / (safeSqrt(vHat) + epsNumerical)
      });
      iter += 1;
    };
    {
      point = x;
      value = objective(x);
      iterations = iter;
      converged = converged;
      gradientNorm = gradNorm;
    }
  };

  /// Newton optimization for multivariate smooth objectives.
  public func newtonOptimize(
    initial : Vector,
    objective : (Vector) -> Float,
    gradient : (Vector) -> Vector,
    hessian : (Vector) -> Matrix,
    maxIterations : Nat,
    tolerance : Float
  ) : OptimizationResult {
    var x = initial;
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var gradNorm = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let g = gradient(x);
      gradNorm := vectorNorm2(g);
      if (gradNorm < eps) {
        converged := true;
        break l;
      };
      let h = hessian(x);
      let step = solveLinearSystem(h, g);
      x := vectorSub(x, step);
      iter += 1;
    };
    {
      point = x;
      value = objective(x);
      iterations = iter;
      converged = converged;
      gradientNorm = gradNorm;
    }
  };

  /// Conjugate gradient solver for symmetric positive definite linear systems.
  public func conjugateGradient(
    a : Matrix,
    b : Vector,
    initial : Vector,
    maxIterations : Nat,
    tolerance : Float
  ) : ConjugateGradientResult {
    var x = initial;
    var r = vectorSub(b, matrixVectorMultiply(a, x));
    var p = r;
    var rsOld = dot(r, r);
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var converged = false;
    while (iter < maxIterations) {
      let ap = matrixVectorMultiply(a, p);
      let denom = Float.max(dot(p, ap), GOLDEN_TOLERANCE);
      let alpha = rsOld / denom;
      x := vectorAdd(x, vectorScale(alpha, p));
      r := vectorSub(r, vectorScale(alpha, ap));
      let rsNew = dot(r, r);
      if (safeSqrt(rsNew) < eps) {
        rsOld := rsNew;
        converged := true;
        iter += 1;
        break;
      };
      let beta = rsNew / Float.max(rsOld, GOLDEN_TOLERANCE);
      p := vectorAdd(r, vectorScale(beta, p));
      rsOld := rsNew;
      iter += 1;
    };
    {
      solution = x;
      iterations = iter;
      converged = converged;
      residualNorm = safeSqrt(rsOld);
    }
  };

  func softThreshold(x : Float, kappa : Float) : Float {
    if (x > kappa) {
      x - kappa
    } else if (x < -kappa) {
      x + kappa
    } else {
      0.0
    }
  };

  func l1Norm(x : Vector) : Float {
    var s : Float = 0.0;
    for (xi in x.vals()) {
      s += Float.abs(xi);
    };
    s
  };

  /// ADMM solver for LASSO: 0.5||Ax-b||^2 + lambda ||x||_1.
  public func admmLasso(
    a : Matrix,
    b : Vector,
    lambda : Float,
    rhoInput : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : ADMMResult {
    let n = rectangularCols(a);
    let at = transpose(a);
    let ata = matrixMultiply(at, a);
    let atb = matrixVectorMultiply(at, b);
    let rho = if (rhoInput > 0.0) rhoInput else DEFAULT_ADMM_RHO;
    let linearSystem = matrixAdd(ata, matrixScale(rho, identityMatrix(n)));
    var x = Array.tabulate<Float>(n, func(_ : Nat) : Float { 0.0 });
    var z = Array.tabulate<Float>(n, func(_ : Nat) : Float { 0.0 });
    var u = Array.tabulate<Float>(n, func(_ : Nat) : Float { 0.0 });
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var primalResidual = 0.0;
    var dualResidual = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let rhs = vectorAdd(atb, vectorScale(rho, vectorSub(z, u)));
      x := solveLinearSystem(linearSystem, rhs);
      let xHat = Array.tabulate<Float>(n, func(i : Nat) : Float {
        DEFAULT_RELAXATION * x[i] + (1.0 - DEFAULT_RELAXATION) * z[i]
      });
      let zPrev = z;
      z := Array.tabulate<Float>(n, func(i : Nat) : Float {
        softThreshold(xHat[i] + u[i], lambda / rho)
      });
      u := Array.tabulate<Float>(n, func(i : Nat) : Float {
        u[i] + xHat[i] - z[i]
      });
      primalResidual := vectorNorm2(vectorSub(x, z));
      dualResidual := vectorNorm2(vectorScale(rho, vectorSub(z, zPrev)));
      if (primalResidual < eps and dualResidual < eps) {
        converged := true;
        iter += 1;
        break l;
      };
      iter += 1;
    };
    let residual = vectorSub(matrixVectorMultiply(a, x), b);
    {
      solution = x;
      iterations = iter;
      converged = converged;
      primalResidual = primalResidual;
      dualResidual = dualResidual;
      objective = 0.5 * dot(residual, residual) + lambda * l1Norm(x);
    }
  };

  func projectBox(x : Vector, constraints : BoxConstraints) : Vector {
    assert (x.size() == constraints.lower.size());
    assert (x.size() == constraints.upper.size());
    Array.tabulate<Float>(x.size(), func(i : Nat) : Float {
      clamp(x[i], constraints.lower[i], constraints.upper[i])
    })
  };

  /// Convex quadratic solver under box constraints using projected gradient descent.
  public func convexQuadraticSolve(
    q : Matrix,
    c : Vector,
    constraints : BoxConstraints,
    initial : Vector,
    learningRate : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : OptimizationResult {
    var x = projectBox(initial, constraints);
    let alpha = Float.max(learningRate, Phi.PHI_INV_5 * 0.01);
    let eps = tol(tolerance);
    var iter : Nat = 0;
    var gradNorm = 0.0;
    var converged = false;
    label l while (iter < maxIterations) {
      let g = vectorAdd(matrixVectorMultiply(q, x), c);
      gradNorm := vectorNorm2(g);
      if (gradNorm < eps) {
        converged := true;
        break l;
      };
      let candidate = vectorSub(x, vectorScale(alpha, g));
      let projected = projectBox(candidate, constraints);
      let stepNorm = vectorNorm2(vectorSub(projected, x));
      x := projected;
      if (stepNorm < eps) {
        converged := true;
        iter += 1;
        break l;
      };
      iter += 1;
    };
    {
      point = x;
      value = quadraticObjective(q, c, x);
      iterations = iter;
      converged = converged;
      gradientNorm = gradNorm;
    }
  };

  /// Generic Monte Carlo integration over an axis-aligned hyper-rectangle.
  public func monteCarloIntegrate(
    seed : Nat,
    lower : Vector,
    upper : Vector,
    samples : Nat,
    integrand : (Vector) -> Float
  ) : MonteCarloResult {
    assert (lower.size() == upper.size());
    let dim = lower.size();
    let nSamples = Nat.max(samples, 1);
    var volume : Float = 1.0;
    var d : Nat = 0;
    while (d < dim) {
      volume *= (upper[d] - lower[d]);
      d += 1;
    };
    var state = Nat.max(seed, 1);
    var mean : Float = 0.0;
    var m2 : Float = 0.0;
    var n : Nat = 0;
    while (n < nSamples) {
      let x = Array.init<Float>(dim, 0.0);
      var j : Nat = 0;
      while (j < dim) {
        let (sn, u) = uniform01(state);
        state := sn;
        x[j] := lower[j] + (upper[j] - lower[j]) * u;
        j += 1;
      };
      let fx = integrand(freezeVector(x));
      let count = natToFloat(n + 1);
      let delta = fx - mean;
      mean += delta / count;
      let delta2 = fx - mean;
      m2 += delta * delta2;
      n += 1;
    };
    let sampleVariance = if (nSamples > 1) m2 / natToFloat(nSamples - 1) else 0.0;
    {
      estimate = volume * mean;
      variance = volume * volume * sampleVariance;
      standardError = volume * safeSqrt(sampleVariance / natToFloat(nSamples));
    }
  };

  /// First- and second-order finite-difference derivative estimates.
  public func finiteDifferenceDerivative(f : (Float) -> Float, x : Float, h : Float) : FiniteDifferenceDerivative {
    let step = Float.max(Float.abs(h), 1.0e-6);
    let fx = f(x);
    let fPlus = f(x + step);
    let fMinus = f(x - step);
    {
      forward = (fPlus - fx) / step;
      backward = (fx - fMinus) / step;
      central = (fPlus - fMinus) / (2.0 * step);
      second = (fPlus - 2.0 * fx + fMinus) / (step * step);
    }
  };

  /// Explicit finite-difference solver for the Black-Scholes PDE.
  public func finiteDifferenceBlackScholes(
    kind : OptionKind,
    spot : Float,
    strike : Float,
    rate : Float,
    volatility : Float,
    maturity : Float,
    assetSteps : Nat,
    timeSteps : Nat,
    maxAsset : Float
  ) : FiniteDifferenceBlackScholesResult {
    let m = Nat.max(assetSteps, 3);
    let n = Nat.max(timeSteps, 1);
    let sMax = Float.max(maxAsset, 2.0 * strike);
    let ds = sMax / natToFloat(m);
    let dt = maturity / natToFloat(n);
    let grid = zeroMatrix(n + 1, m + 1);
    let assets = Array.init<Float>(m + 1, 0.0);
    let times = Array.init<Float>(n + 1, 0.0);

    var i : Nat = 0;
    while (i <= m) {
      assets[i] := natToFloat(i) * ds;
      grid[n][i] := payoff(kind, assets[i], strike);
      i += 1;
    };

    var tIdx : Nat = 0;
    while (tIdx <= n) {
      times[tIdx] := natToFloat(tIdx) * dt;
      tIdx += 1;
    };

    var step : Nat = n;
    while (step > 0) {
      let current = natToFloat(step - 1) * dt;
      switch (kind) {
        case (#call) {
          grid[step - 1][0] := 0.0;
          grid[step - 1][m] := sMax - strike * Float.exp(-rate * (maturity - current));
        };
        case (#put) {
          grid[step - 1][0] := strike * Float.exp(-rate * (maturity - current));
          grid[step - 1][m] := 0.0;
        };
      };
      i := 1;
      while (i < m) {
        let idx = natToFloat(i);
        let sigma2 = volatility * volatility;
        let a = 0.5 * dt * (sigma2 * idx * idx - rate * idx);
        let b = 1.0 - dt * (sigma2 * idx * idx + rate);
        let c = 0.5 * dt * (sigma2 * idx * idx + rate * idx);
        grid[step - 1][i] := a * grid[step][i - 1] + b * grid[step][i] + c * grid[step][i + 1];
        i += 1;
      };
      step -= 1;
    };

    let rawSpotIndex = Int.abs(Float.toInt(Float.max(0.0, spot / ds)));
    var spotIndex = Nat.min(m - 1, rawSpotIndex);
    if (spotIndex >= m) { spotIndex := m - 1 };
    let sLo = assets[spotIndex];
    let sHi = assets[spotIndex + 1];
    let vLo = grid[0][spotIndex];
    let vHi = grid[0][spotIndex + 1];
    let interp = if (sHi > sLo) vLo + (spot - sLo) / (sHi - sLo) * (vHi - vLo) else vLo;

    {
      assetPrices = freezeVector(assets);
      timeLevels = freezeVector(times);
      grid = freezeMatrix(grid);
      price = interp;
    }
  };

  /// Newton-Raphson scalar root finder.
  public func newtonRaphson(
    f : (Float) -> Float,
    df : (Float) -> Float,
    initial : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : RootResult {
    let eps = tol(tolerance);
    var x = initial;
    var iter : Nat = 0;
    var converged = false;
    while (iter < maxIterations) {
      let fx = f(x);
      let dfx = df(x);
      if (Float.abs(fx) < eps) {
        converged := true;
        break;
      };
      assert (Float.abs(dfx) > GOLDEN_TOLERANCE);
      let next = x - fx / dfx;
      if (Float.abs(next - x) < eps) {
        x := next;
        converged := true;
        iter += 1;
        break;
      };
      x := next;
      iter += 1;
    };
    {
      root = x;
      iterations = iter;
      converged = converged;
      residual = Float.abs(f(x));
    }
  };

  /// Bisection scalar root finder for sign-changing brackets.
  public func bisection(
    f : (Float) -> Float,
    lower : Float,
    upper : Float,
    maxIterations : Nat,
    tolerance : Float
  ) : RootResult {
    let eps = tol(tolerance);
    var lo = lower;
    var hi = upper;
    var flo = f(lo);
    var fhi = f(hi);
    assert (flo == 0.0 or fhi == 0.0 or flo * fhi <= 0.0);
    var mid = 0.5 * (lo + hi);
    var iter : Nat = 0;
    var converged = false;
    while (iter < maxIterations) {
      mid := 0.5 * (lo + hi);
      let fmid = f(mid);
      if (Float.abs(fmid) < eps or 0.5 * Float.abs(hi - lo) < eps) {
        converged := true;
        break;
      };
      if (flo * fmid <= 0.0) {
        hi := mid;
        fhi := fmid;
      } else {
        lo := mid;
        flo := fmid;
      };
      iter += 1;
    };
    {
      root = mid;
      iterations = iter;
      converged = converged;
      residual = Float.abs(f(mid));
    }
  };

  /// Composite trapezoidal rule integration.
  public func trapezoidalIntegral(f : (Float) -> Float, a : Float, b : Float, intervals : Nat) : Float {
    let n = Nat.max(intervals, 1);
    let h = (b - a) / natToFloat(n);
    var sum = 0.5 * (f(a) + f(b));
    var i : Nat = 1;
    while (i < n) {
      sum += f(a + natToFloat(i) * h);
      i += 1;
    };
    h * sum
  };

  /// Composite Simpson's rule integration.
  public func simpsonIntegral(f : (Float) -> Float, a : Float, b : Float, intervals : Nat) : Float {
    let n = if (intervals % 2 == 0) Nat.max(intervals, 2) else Nat.max(intervals + 1, 2);
    let h = (b - a) / natToFloat(n);
    var oddSum : Float = 0.0;
    var evenSum : Float = 0.0;
    var i : Nat = 1;
    while (i < n) {
      let xi = a + natToFloat(i) * h;
      if (i % 2 == 0) {
        evenSum += f(xi);
      } else {
        oddSum += f(xi);
      };
      i += 1;
    };
    h / 3.0 * (f(a) + f(b) + 4.0 * oddSum + 2.0 * evenSum)
  };

  /// Utility for Merton's compensator using the existing Phi/Euler constants.
  public func mertonJumpCompensator(jumpMean : Float, jumpVolatility : Float) : Float {
    Float.pow(Phi.EULER_E, jumpMean + 0.5 * jumpVolatility * jumpVolatility) - 1.0
  };

  /// Convenience helper for quadratic forms x^T A x.
  public func quadraticForm(a : Matrix, x : Vector) : Float {
    dot(x, matrixVectorMultiply(a, x))
  };
};
