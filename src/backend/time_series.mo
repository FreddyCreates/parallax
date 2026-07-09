import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import VarArray "mo:core/VarArray";

/// Comprehensive time-series analytics for PARALLAX.
///
/// The module is intentionally self-contained so it can run inside the Motoko
/// canister runtime without external native dependencies.
module {
  public type Vector = [Float];
  public type Matrix = [[Float]];
  type MutableVector = [var Float];
  type MutableMatrix = [[var Float]];

  public type InformationCriterion = { #aic; #bic };

  public type RegressionResult = {
    coefficients : Vector;
    fitted : Vector;
    residuals : Vector;
    sigma2 : Float;
  };

  public type ARModelResult = {
    intercept : Float;
    coefficients : Vector;
    residuals : Vector;
    fitted : Vector;
    sigma2 : Float;
    aic : Float;
    bic : Float;
  };

  public type MAModelResult = {
    intercept : Float;
    coefficients : Vector;
    residuals : Vector;
    fitted : Vector;
    sigma2 : Float;
    aic : Float;
    bic : Float;
    iterations : Nat;
  };

  public type ARIMAResult = {
    p : Nat;
    d : Nat;
    q : Nat;
    intercept : Float;
    ar : Vector;
    ma : Vector;
    residuals : Vector;
    fitted : Vector;
    sigma2 : Float;
    aic : Float;
    bic : Float;
    trainingSeries : Vector;
    transformedSeries : Vector;
  };

  public type SARIMAResult = {
    p : Nat;
    d : Nat;
    q : Nat;
    seasonalP : Nat;
    seasonalD : Nat;
    seasonalQ : Nat;
    seasonalPeriod : Nat;
    intercept : Float;
    ar : Vector;
    ma : Vector;
    seasonalAr : Vector;
    seasonalMa : Vector;
    residuals : Vector;
    fitted : Vector;
    sigma2 : Float;
    aic : Float;
    bic : Float;
    trainingSeries : Vector;
    transformedSeries : Vector;
  };

  public type EvaluatedModel = {
    p : Nat;
    d : Nat;
    q : Nat;
    seasonalP : Nat;
    seasonalD : Nat;
    seasonalQ : Nat;
    seasonalPeriod : Nat;
    aic : Float;
    bic : Float;
    sigma2 : Float;
  };

  public type ModelSelectionResult = {
    criterion : InformationCriterion;
    best : EvaluatedModel;
    candidates : [EvaluatedModel];
  };

  public type ForecastResult = {
    point : Vector;
    lower : Vector;
    upper : Vector;
    standardErrors : Vector;
  };

  public type EnsembleForecastResult = {
    weights : Vector;
    members : [ForecastResult];
    combined : ForecastResult;
  };

  public type StateSpaceModel = {
    transition : Matrix;
    observation : Matrix;
    transitionCovariance : Matrix;
    observationCovariance : Matrix;
    stateIntercept : Vector;
    observationIntercept : Vector;
    initialState : Vector;
    initialCovariance : Matrix;
  };

  public type KalmanStep = {
    predictedState : Vector;
    predictedCovariance : Matrix;
    filteredState : Vector;
    filteredCovariance : Matrix;
    innovation : Vector;
    innovationCovariance : Matrix;
    logLikelihood : Float;
  };

  public type KalmanFilterResult = {
    steps : [KalmanStep];
    filteredStates : [Vector];
    predictedStates : [Vector];
    logLikelihood : Float;
  };

  public type StructuralModelSpec = {
    model : StateSpaceModel;
    name : Text;
  };

  public type FrequencyPoint = {
    frequency : Float;
    real : Float;
    imaginary : Float;
    amplitude : Float;
    power : Float;
  };

  public type SpectralDensityPoint = {
    frequency : Float;
    density : Float;
  };

  public type WaveletDecomposition = {
    approximations : [Vector];
    details : [Vector];
  };

  public type CUSUMPoint = {
    index : Nat;
    statistic : Float;
    exceedsThreshold : Bool;
  };

  public type BayesianChangepointResult = {
    posterior : Vector;
    mostLikelyIndex : ?Nat;
    probability : Float;
  };

  public type StructuralBreakPoint = {
    index : Nat;
    fStatistic : Float;
    leftMean : Float;
    rightMean : Float;
  };

  let TWO_PI : Float = 6.28318530717958647692;
  let EPS : Float = 1.0e-9;

  func natToFloat(n : Nat) : Float {
    (n : Int).toFloat()
  };

  func zeroVector(n : Nat) : Vector {
    Array.tabulate<Float>(n, func(_ : Nat) : Float { 0.0 })
  };

  func natSub(x : Nat, y : Nat) : Nat {
    if (x > y) { x - y } else { 0 }
  };

  func mutableMatrix(rows : Nat, cols : Nat) : MutableMatrix {
    Array.tabulate<MutableVector>(rows, func(_ : Nat) : MutableVector {
      VarArray.repeat<Float>(0.0, cols)
    })
  };

  func freezeMatrix(m : MutableMatrix) : Matrix {
    Array.tabulate<Vector>(m.size(), func(i : Nat) : Vector { VarArray.toArray<Float>(m[i]) })
  };

  func identity(n : Nat) : Matrix {
    let out = mutableMatrix(n, n);
    var i : Nat = 0;
    while (i < n) {
      out[i][i] := 1.0;
      i += 1;
    };
    freezeMatrix(out)
  };

  func dot(a : Vector, b : Vector) : Float {
    let n = if (a.size() < b.size()) a.size() else b.size();
    var total = 0.0;
    var i : Nat = 0;
    while (i < n) {
      total += a[i] * b[i];
      i += 1;
    };
    total
  };

  func mean(series : Vector) : Float {
    if (series.size() == 0) return 0.0;
    var total = 0.0;
    var i : Nat = 0;
    while (i < series.size()) {
      total += series[i];
      i += 1;
    };
    total / natToFloat(series.size())
  };

  func variance(series : Vector) : Float {
    if (series.size() < 2) return 0.0;
    let mu = mean(series);
    var total = 0.0;
    var i : Nat = 0;
    while (i < series.size()) {
      let d = series[i] - mu;
      total += d * d;
      i += 1;
    };
    total / natToFloat(series.size() - 1)
  };

  func safeVariance(series : Vector) : Float {
    Float.max(variance(series), EPS)
  };

  func standardDeviation(series : Vector) : Float {
    Float.sqrt(safeVariance(series))
  };

  func maxLag(lags : [Nat]) : Nat {
    var best : Nat = 0;
    var i : Nat = 0;
    while (i < lags.size()) {
      if (lags[i] > best) { best := lags[i] };
      i += 1;
    };
    best
  };

  func take(series : Vector, count : Nat) : Vector {
    let n = if (count < series.size()) count else series.size();
    Array.tabulate<Float>(n, func(i : Nat) : Float { series[i] })
  };

  func rangeLags(order : Nat) : [Nat] {
    Array.tabulate<Nat>(order, func(i : Nat) : Nat { i + 1 })
  };

  func offsetLags(order : Nat, period : Nat) : [Nat] {
    Array.tabulate<Nat>(order, func(i : Nat) : Nat { (i + 1) * period })
  };

  func tail(series : Vector, count : Nat) : Vector {
    if (count == 0 or series.size() == 0) return [];
    let n = series.size();
    let outputSize = if (count < n) count else n;
    let start = natSub(n, outputSize);
    Array.tabulate<Float>(outputSize, func(i : Nat) : Float { series[start + i] })
  };

  func scalarNormalQuantile(alpha : Float) : Float {
    if (alpha <= 0.01) {
      2.5758293035489004
    } else if (alpha <= 0.05) {
      1.959963984540054
    } else if (alpha <= 0.10) {
      1.6448536269514722
    } else {
      1.2815515655446004
    }
  };

  func transpose(a : Matrix) : Matrix {
    if (a.size() == 0) return [];
    let rows = a.size();
    let cols = a[0].size();
    let out = mutableMatrix(cols, rows);
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

  func matrixVectorMultiply(a : Matrix, x : Vector) : Vector {
    Array.tabulate<Float>(a.size(), func(i : Nat) : Float {
      dot(a[i], x)
    })
  };

  func matrixMultiply(a : Matrix, b : Matrix) : Matrix {
    if (a.size() == 0 or b.size() == 0) return [];
    let bt = transpose(b);
    let out = mutableMatrix(a.size(), bt.size());
    var i : Nat = 0;
    while (i < a.size()) {
      var j : Nat = 0;
      while (j < bt.size()) {
        out[i][j] := dot(a[i], bt[j]);
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func matrixAdd(a : Matrix, b : Matrix) : Matrix {
    if (a.size() == 0) return b;
    let out = mutableMatrix(a.size(), a[0].size());
    var i : Nat = 0;
    while (i < a.size()) {
      var j : Nat = 0;
      while (j < a[0].size()) {
        out[i][j] := a[i][j] + b[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func matrixSubtract(a : Matrix, b : Matrix) : Matrix {
    if (a.size() == 0) return [];
    let out = mutableMatrix(a.size(), a[0].size());
    var i : Nat = 0;
    while (i < a.size()) {
      var j : Nat = 0;
      while (j < a[0].size()) {
        out[i][j] := a[i][j] - b[i][j];
        j += 1;
      };
      i += 1;
    };
    freezeMatrix(out)
  };

  func vectorAdd(a : Vector, b : Vector) : Vector {
    let n = if (a.size() < b.size()) a.size() else b.size();
    Array.tabulate<Float>(n, func(i : Nat) : Float { a[i] + b[i] })
  };

  func vectorSubtract(a : Vector, b : Vector) : Vector {
    let n = if (a.size() < b.size()) a.size() else b.size();
    Array.tabulate<Float>(n, func(i : Nat) : Float { a[i] - b[i] })
  };

  func solveLinearSystem(a : Matrix, b : Vector) : Vector {
    let n = a.size();
    if (n == 0) return [];
    let aug = VarArray.fromArray<MutableVector>(Array.tabulate<MutableVector>(n, func(i : Nat) : MutableVector {
      let row = VarArray.repeat<Float>(0.0, n + 1);
      var j : Nat = 0;
      while (j < n) {
        row[j] := a[i][j] + (if (i == j) EPS else 0.0);
        j += 1;
      };
      row[n] := b[i];
      row
    }));

    var pivotRow : Nat = 0;
    while (pivotRow < n) {
      var best = pivotRow;
      var bestAbs = Float.abs(aug[pivotRow][pivotRow]);
      var r : Nat = pivotRow + 1;
      while (r < n) {
        let candidate = Float.abs(aug[r][pivotRow]);
        if (candidate > bestAbs) {
          best := r;
          bestAbs := candidate;
        };
        r += 1;
      };
      if (best != pivotRow) {
        let tmp = aug[pivotRow];
        aug[pivotRow] := aug[best];
        aug[best] := tmp;
      };

      let pivot = if (Float.abs(aug[pivotRow][pivotRow]) < EPS) EPS else aug[pivotRow][pivotRow];
      var c : Nat = pivotRow;
      while (c <= n) {
        aug[pivotRow][c] := aug[pivotRow][c] / pivot;
        c += 1;
      };

      var rr : Nat = 0;
      while (rr < n) {
        if (rr != pivotRow) {
          let factor = aug[rr][pivotRow];
          var cc : Nat = pivotRow;
          while (cc <= n) {
            aug[rr][cc] := aug[rr][cc] - factor * aug[pivotRow][cc];
            cc += 1;
          };
        };
        rr += 1;
      };
      pivotRow += 1;
    };

    Array.tabulate<Float>(n, func(i : Nat) : Float { aug[i][n] })
  };

  func inverseMatrix(a : Matrix) : Matrix {
    let n = a.size();
    if (n == 0) return [];
    let aug = VarArray.fromArray<MutableVector>(Array.tabulate<MutableVector>(n, func(i : Nat) : MutableVector {
      let row = VarArray.repeat<Float>(0.0, 2 * n);
      var j : Nat = 0;
      while (j < n) {
        row[j] := a[i][j] + (if (i == j) EPS else 0.0);
        j += 1;
      };
      row[n + i] := 1.0;
      row
    }));

    var pivotRow : Nat = 0;
    while (pivotRow < n) {
      var best = pivotRow;
      var bestAbs = Float.abs(aug[pivotRow][pivotRow]);
      var r : Nat = pivotRow + 1;
      while (r < n) {
        let candidate = Float.abs(aug[r][pivotRow]);
        if (candidate > bestAbs) {
          best := r;
          bestAbs := candidate;
        };
        r += 1;
      };
      if (best != pivotRow) {
        let tmp = aug[pivotRow];
        aug[pivotRow] := aug[best];
        aug[best] := tmp;
      };

      let pivot = if (Float.abs(aug[pivotRow][pivotRow]) < EPS) EPS else aug[pivotRow][pivotRow];
      var c : Nat = 0;
      while (c < 2 * n) {
        aug[pivotRow][c] := aug[pivotRow][c] / pivot;
        c += 1;
      };

      var rr : Nat = 0;
      while (rr < n) {
        if (rr != pivotRow) {
          let factor = aug[rr][pivotRow];
          var cc : Nat = 0;
          while (cc < 2 * n) {
            aug[rr][cc] := aug[rr][cc] - factor * aug[pivotRow][cc];
            cc += 1;
          };
        };
        rr += 1;
      };
      pivotRow += 1;
    };

    Array.tabulate<Vector>(n, func(i : Nat) : Vector {
      Array.tabulate<Float>(n, func(j : Nat) : Float {
        aug[i][n + j]
      })
    })
  };

  func regression(x : Matrix, y : Vector) : RegressionResult {
    if (x.size() == 0 or y.size() == 0) {
      return {
        coefficients = [];
        fitted = [];
        residuals = [];
        sigma2 = 0.0;
      }
    };
    let xt = transpose(x);
    let xtx = matrixMultiply(xt, x);
    let xty = Array.tabulate<Float>(xt.size(), func(i : Nat) : Float { dot(xt[i], y) });
    let beta = solveLinearSystem(xtx, xty);
    let fitted = matrixVectorMultiply(x, beta);
    let residualCount = if (y.size() < fitted.size()) y.size() else fitted.size();
    let residuals = Array.tabulate<Float>(residualCount, func(i : Nat) : Float { y[i] - fitted[i] });
    let denom = Nat.max(natSub(y.size(), beta.size()), 1);
    let sigma2 = dot(residuals, residuals) / natToFloat(denom);
    {
      coefficients = beta;
      fitted = fitted;
      residuals = residuals;
      sigma2 = Float.max(sigma2, EPS);
    }
  };

  func informationCriteria(n : Nat, k : Nat, sigma2 : Float) : (Float, Float) {
    let nn = Float.max(natToFloat(n), 1.0);
    let kk = natToFloat(k);
    let logSigma = Float.log(Float.max(sigma2, EPS));
    let aic = nn * logSigma + 2.0 * kk;
    let bic = nn * logSigma + kk * Float.log(nn);
    (aic, bic)
  };

  func differenceOnce(series : Vector) : Vector {
    if (series.size() < 2) return [];
    Array.tabulate<Float>(series.size() - 1, func(i : Nat) : Float {
      series[i + 1] - series[i]
    })
  };

  func seasonalDifferenceOnce(series : Vector, period : Nat) : Vector {
    if (period == 0 or series.size() <= period) return [];
    Array.tabulate<Float>(series.size() - period, func(i : Nat) : Float {
      series[i + period] - series[i]
    })
  };

  public func differenceSeries(series : Vector, d : Nat) : Vector {
    var out = series;
    var i : Nat = 0;
    while (i < d) {
      out := differenceOnce(out);
      i += 1;
    };
    out
  };

  public func seasonalDifference(series : Vector, period : Nat, d : Nat) : Vector {
    var out = series;
    var i : Nat = 0;
    while (i < d) {
      out := seasonalDifferenceOnce(out, period);
      i += 1;
    };
    out
  };

  func inverseDifferenceOnce(history : Vector, diffs : Vector) : Vector {
    if (history.size() == 0) return diffs;
    let out = VarArray.repeat<Float>(0.0, diffs.size());
    var prev = history[history.size() - 1];
    var i : Nat = 0;
    while (i < diffs.size()) {
      let next = prev + diffs[i];
      out[i] := next;
      prev := next;
      i += 1;
    };
    VarArray.toArray<Float>(out)
  };

  func inverseSeasonalDifferenceOnce(history : Vector, diffs : Vector, period : Nat) : Vector {
    if (period == 0 or history.size() < period) return diffs;
    let augmented = VarArray.repeat<Float>(0.0, history.size() + diffs.size());
    var i : Nat = 0;
    while (i < history.size()) {
      augmented[i] := history[i];
      i += 1;
    };
    var j : Nat = 0;
    while (j < diffs.size()) {
      let idx = history.size() + j;
      augmented[idx] := diffs[j] + augmented[idx - period];
      j += 1;
    };
    Array.tabulate<Float>(diffs.size(), func(k : Nat) : Float {
      augmented[history.size() + k]
    })
  };

  func invertDifferencedForecasts(original : Vector, forecasts : Vector, d : Nat, seasonalPeriod : Nat, seasonalD : Nat) : Vector {
    var restored = forecasts;
    let baseAfterNonSeasonal = differenceSeries(original, d);

    var seasonalLevel = seasonalD;
    while (seasonalLevel > 0) {
      let history = seasonalDifference(baseAfterNonSeasonal, seasonalPeriod, seasonalLevel - 1);
      restored := inverseSeasonalDifferenceOnce(history, restored, seasonalPeriod);
      seasonalLevel -= 1;
    };

    var nonSeasonalLevel = d;
    while (nonSeasonalLevel > 0) {
      let history = differenceSeries(original, nonSeasonalLevel - 1);
      restored := inverseDifferenceOnce(history, restored);
      nonSeasonalLevel -= 1;
    };
    restored
  };

  func conditionalArma(series : Vector, arLags : [Nat], maLags : [Nat], iterations : Nat) : {
    intercept : Float;
    ar : Vector;
    ma : Vector;
    residuals : Vector;
    fitted : Vector;
    sigma2 : Float;
  } {
    let maxAr = maxLag(arLags);
    let maxMa = maxLag(maLags);
    let start = if (maxAr > maxMa) maxAr else maxMa;
    if (series.size() <= start) {
      return {
        intercept = mean(series);
        ar = zeroVector(arLags.size());
        ma = zeroVector(maLags.size());
        residuals = zeroVector(series.size());
        fitted = zeroVector(series.size());
        sigma2 = safeVariance(series);
      }
    };

    var workingResiduals = VarArray.repeat<Float>(0.0, series.size());
    var intercept = mean(series);
    var ar = zeroVector(arLags.size());
    var ma = zeroVector(maLags.size());
    var fitted = VarArray.repeat<Float>(intercept, series.size());
    let totalIterations = if (iterations == 0) 1 else iterations;
    var iter : Nat = 0;
    let rows = natSub(series.size(), start);
    while (iter < totalIterations) {
      let cols = 1 + arLags.size() + maLags.size();
      let xMutable = mutableMatrix(rows, cols);
      let yMutable = VarArray.repeat<Float>(0.0, rows);
      var r : Nat = 0;
      while (r < rows) {
        let t = start + r;
        xMutable[r][0] := 1.0;
        var c : Nat = 0;
        while (c < arLags.size()) {
          xMutable[r][1 + c] := series[t - arLags[c]];
          c += 1;
        };
        var mc : Nat = 0;
        while (mc < maLags.size()) {
          xMutable[r][1 + arLags.size() + mc] := workingResiduals[t - maLags[mc]];
          mc += 1;
        };
        yMutable[r] := series[t];
        r += 1;
      };
      let reg = regression(freezeMatrix(xMutable), VarArray.toArray<Float>(yMutable));
      if (reg.coefficients.size() > 0) {
        intercept := reg.coefficients[0];
      };
      ar := Array.tabulate<Float>(arLags.size(), func(i : Nat) : Float { reg.coefficients[1 + i] });
      ma := Array.tabulate<Float>(maLags.size(), func(i : Nat) : Float { reg.coefficients[1 + arLags.size() + i] });
      workingResiduals := VarArray.repeat<Float>(0.0, series.size());
      fitted := VarArray.repeat<Float>(intercept, series.size());
      var t : Nat = 0;
      while (t < series.size()) {
        if (t >= start) {
          var prediction = intercept;
          var ai : Nat = 0;
          while (ai < arLags.size()) {
            prediction += ar[ai] * series[t - arLags[ai]];
            ai += 1;
          };
          var mi : Nat = 0;
          while (mi < maLags.size()) {
            prediction += ma[mi] * workingResiduals[t - maLags[mi]];
            mi += 1;
          };
          fitted[t] := prediction;
          workingResiduals[t] := series[t] - prediction;
        } else {
          fitted[t] := intercept;
          workingResiduals[t] := series[t] - intercept;
        };
        t += 1;
      };
      iter += 1;
    };

    let residuals = VarArray.toArray<Float>(workingResiduals);
    let fittedVector = VarArray.toArray<Float>(fitted);
    {
      intercept = intercept;
      ar = ar;
      ma = ma;
      residuals = residuals;
      fitted = fittedVector;
      sigma2 = dot(residuals, residuals) / Float.max(natToFloat(series.size()), 1.0);
    }
  };

  public func estimateAR(series : Vector, order : Nat) : ARModelResult {
    let transformed = conditionalArma(series, rangeLags(order), [], 1);
    let (aic, bic) = informationCriteria(series.size(), 1 + order, transformed.sigma2);
    {
      intercept = transformed.intercept;
      coefficients = transformed.ar;
      residuals = transformed.residuals;
      fitted = transformed.fitted;
      sigma2 = transformed.sigma2;
      aic = aic;
      bic = bic;
    }
  };

  public func estimateMA(series : Vector, order : Nat, iterations : Nat) : MAModelResult {
    let transformed = conditionalArma(series, [], rangeLags(order), iterations);
    let (aic, bic) = informationCriteria(series.size(), 1 + order, transformed.sigma2);
    {
      intercept = transformed.intercept;
      coefficients = transformed.ma;
      residuals = transformed.residuals;
      fitted = transformed.fitted;
      sigma2 = transformed.sigma2;
      aic = aic;
      bic = bic;
      iterations = iterations;
    }
  };

  public func estimateARIMA(series : Vector, p : Nat, d : Nat, q : Nat) : ARIMAResult {
    let transformedSeries = differenceSeries(series, d);
    let fit = conditionalArma(transformedSeries, rangeLags(p), rangeLags(q), 8);
    let (aic, bic) = informationCriteria(transformedSeries.size(), 1 + p + q, fit.sigma2);
    {
      p = p;
      d = d;
      q = q;
      intercept = fit.intercept;
      ar = fit.ar;
      ma = fit.ma;
      residuals = fit.residuals;
      fitted = fit.fitted;
      sigma2 = fit.sigma2;
      aic = aic;
      bic = bic;
      trainingSeries = series;
      transformedSeries = transformedSeries;
    }
  };

  public func estimateSARIMA(series : Vector, p : Nat, d : Nat, q : Nat, seasonalP : Nat, seasonalD : Nat, seasonalQ : Nat, seasonalPeriod : Nat) : SARIMAResult {
    let differenced = differenceSeries(series, d);
    let transformedSeries = seasonalDifference(differenced, seasonalPeriod, seasonalD);
    let arLags = Array.concat<Nat>(rangeLags(p), offsetLags(seasonalP, seasonalPeriod));
    let maLags = Array.concat<Nat>(rangeLags(q), offsetLags(seasonalQ, seasonalPeriod));
    let fit = conditionalArma(transformedSeries, arLags, maLags, 10);
    let (aic, bic) = informationCriteria(transformedSeries.size(), 1 + p + q + seasonalP + seasonalQ, fit.sigma2);
    {
      p = p;
      d = d;
      q = q;
      seasonalP = seasonalP;
      seasonalD = seasonalD;
      seasonalQ = seasonalQ;
      seasonalPeriod = seasonalPeriod;
      intercept = fit.intercept;
      ar = take(fit.ar, p);
      ma = take(fit.ma, q);
      seasonalAr = if (seasonalP == 0) [] else tail(fit.ar, seasonalP);
      seasonalMa = if (seasonalQ == 0) [] else tail(fit.ma, seasonalQ);
      residuals = fit.residuals;
      fitted = fit.fitted;
      sigma2 = fit.sigma2;
      aic = aic;
      bic = bic;
      trainingSeries = series;
      transformedSeries = transformedSeries;
    }
  };

  public func selectBestARIMA(series : Vector, maxP : Nat, maxD : Nat, maxQ : Nat, criterion : InformationCriterion) : ModelSelectionResult {
    var candidates : [EvaluatedModel] = [];
    var best : ?EvaluatedModel = null;
    var p : Nat = 0;
    while (p <= maxP) {
      var d : Nat = 0;
      while (d <= maxD) {
        var q : Nat = 0;
        while (q <= maxQ) {
          let fit = estimateARIMA(series, p, d, q);
          let candidate : EvaluatedModel = {
            p = p;
            d = d;
            q = q;
            seasonalP = 0;
            seasonalD = 0;
            seasonalQ = 0;
            seasonalPeriod = 0;
            aic = fit.aic;
            bic = fit.bic;
            sigma2 = fit.sigma2;
          };
          candidates := Array.concat<EvaluatedModel>(candidates, [candidate]);
          switch (best) {
            case null { best := ?candidate };
            case (?current) {
              let currentValue = switch (criterion) {
                case (#aic) { current.aic };
                case (#bic) { current.bic };
              };
              let candidateValue = switch (criterion) {
                case (#aic) { candidate.aic };
                case (#bic) { candidate.bic };
              };
              if (candidateValue < currentValue) {
                best := ?candidate
              };
            };
          };
          q += 1;
        };
        d += 1;
      };
      p += 1;
    };
    {
      criterion = criterion;
      best = switch (best) {
        case (?value) value;
        case null {
          {
            p = 0;
            d = 0;
            q = 0;
            seasonalP = 0;
            seasonalD = 0;
            seasonalQ = 0;
            seasonalPeriod = 0;
            aic = 0.0;
            bic = 0.0;
            sigma2 = 0.0;
          }
        };
      };
      candidates = candidates;
    }
  };

  public func selectBestSARIMA(series : Vector, maxP : Nat, maxD : Nat, maxQ : Nat, maxSeasonalP : Nat, maxSeasonalD : Nat, maxSeasonalQ : Nat, seasonalPeriod : Nat, criterion : InformationCriterion) : ModelSelectionResult {
    var candidates : [EvaluatedModel] = [];
    var best : ?EvaluatedModel = null;
    var p : Nat = 0;
    while (p <= maxP) {
      var d : Nat = 0;
      while (d <= maxD) {
        var q : Nat = 0;
        while (q <= maxQ) {
          var sp : Nat = 0;
          while (sp <= maxSeasonalP) {
            var sd : Nat = 0;
            while (sd <= maxSeasonalD) {
              var sq : Nat = 0;
              while (sq <= maxSeasonalQ) {
                let fit = estimateSARIMA(series, p, d, q, sp, sd, sq, seasonalPeriod);
                let candidate : EvaluatedModel = {
                  p = p;
                  d = d;
                  q = q;
                  seasonalP = sp;
                  seasonalD = sd;
                  seasonalQ = sq;
                  seasonalPeriod = seasonalPeriod;
                  aic = fit.aic;
                  bic = fit.bic;
                  sigma2 = fit.sigma2;
                };
                candidates := Array.concat<EvaluatedModel>(candidates, [candidate]);
                switch (best) {
                  case null { best := ?candidate };
                  case (?current) {
                    let currentValue = switch (criterion) {
                      case (#aic) { current.aic };
                      case (#bic) { current.bic };
                    };
                    let candidateValue = switch (criterion) {
                      case (#aic) { candidate.aic };
                      case (#bic) { candidate.bic };
                    };
                    if (candidateValue < currentValue) {
                      best := ?candidate
                    };
                  };
                };
                sq += 1;
              };
              sd += 1;
            };
            sp += 1;
          };
          q += 1;
        };
        d += 1;
      };
      p += 1;
    };
    {
      criterion = criterion;
      best = switch (best) {
        case (?value) value;
        case null {
          {
            p = 0;
            d = 0;
            q = 0;
            seasonalP = 0;
            seasonalD = 0;
            seasonalQ = 0;
            seasonalPeriod = seasonalPeriod;
            aic = 0.0;
            bic = 0.0;
            sigma2 = 0.0;
          }
        };
      };
      candidates = candidates;
    }
  };

  func recursiveForecast(intercept : Float, arLags : [Nat], arCoefs : Vector, maLags : [Nat], maCoefs : Vector, history : Vector, residuals : Vector, horizon : Nat) : Vector {
    let values = VarArray.repeat<Float>(0.0, history.size() + horizon);
    var i : Nat = 0;
    while (i < history.size()) {
      values[i] := history[i];
      i += 1;
    };
    let errors = VarArray.repeat<Float>(0.0, residuals.size() + horizon);
    var j : Nat = 0;
    while (j < residuals.size()) {
      errors[j] := residuals[j];
      j += 1;
    };
    var h : Nat = 0;
    while (h < horizon) {
      let t = history.size() + h;
      var forecast = intercept;
      var ai : Nat = 0;
      while (ai < arLags.size()) {
        if (t >= arLags[ai]) {
          forecast += arCoefs[ai] * values[t - arLags[ai]];
        };
        ai += 1;
      };
      var mi : Nat = 0;
      while (mi < maLags.size()) {
        if (t >= maLags[mi]) {
          forecast += maCoefs[mi] * errors[t - maLags[mi]];
        };
        mi += 1;
      };
      values[t] := forecast;
      errors[t] := 0.0;
      h += 1;
    };
    Array.tabulate<Float>(horizon, func(k : Nat) : Float { values[history.size() + k] })
  };

  public func forecastARIMA(model : ARIMAResult, horizon : Nat, alpha : Float) : ForecastResult {
    let transformedForecasts = recursiveForecast(model.intercept, rangeLags(model.p), model.ar, rangeLags(model.q), model.ma, model.transformedSeries, model.residuals, horizon);
    let point = invertDifferencedForecasts(model.trainingSeries, transformedForecasts, model.d, 0, 0);
    let z = scalarNormalQuantile(alpha);
    let se = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      Float.sqrt(model.sigma2 * natToFloat(i + 1))
    });
    let lower = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] - z * se[i] });
    let upper = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] + z * se[i] });
    {
      point = point;
      lower = lower;
      upper = upper;
      standardErrors = se;
    }
  };

  public func forecastSARIMA(model : SARIMAResult, horizon : Nat, alpha : Float) : ForecastResult {
    let arLags = Array.concat<Nat>(rangeLags(model.p), offsetLags(model.seasonalP, model.seasonalPeriod));
    let arCoefs = Array.concat<Float>(model.ar, model.seasonalAr);
    let maLags = Array.concat<Nat>(rangeLags(model.q), offsetLags(model.seasonalQ, model.seasonalPeriod));
    let maCoefs = Array.concat<Float>(model.ma, model.seasonalMa);
    let transformedForecasts = recursiveForecast(model.intercept, arLags, arCoefs, maLags, maCoefs, model.transformedSeries, model.residuals, horizon);
    let point = invertDifferencedForecasts(model.trainingSeries, transformedForecasts, model.d, model.seasonalPeriod, model.seasonalD);
    let z = scalarNormalQuantile(alpha);
    let se = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      Float.sqrt(model.sigma2 * natToFloat(i + 1))
    });
    let lower = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] - z * se[i] });
    let upper = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] + z * se[i] });
    {
      point = point;
      lower = lower;
      upper = upper;
      standardErrors = se;
    }
  };

  public func ensembleForecast(forecasts : [ForecastResult], weights : ?Vector) : EnsembleForecastResult {
    if (forecasts.size() == 0) {
      let empty : ForecastResult = { point = []; lower = []; upper = []; standardErrors = [] };
      return { weights = []; members = []; combined = empty }
    };
    let horizon = forecasts[0].point.size();
    let w = switch (weights) {
      case (?provided) provided;
      case null {
        let equal = 1.0 / natToFloat(forecasts.size());
        Array.tabulate<Float>(forecasts.size(), func(_ : Nat) : Float { equal })
      };
    };
    let point = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      var total = 0.0;
      var j : Nat = 0;
      while (j < forecasts.size()) {
        total += w[j] * forecasts[j].point[i];
        j += 1;
      };
      total
    });
    let se = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      var total = 0.0;
      var j : Nat = 0;
      while (j < forecasts.size()) {
        total += w[j] * forecasts[j].standardErrors[i];
        j += 1;
      };
      total
    });
    let lower = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      var total = 0.0;
      var j : Nat = 0;
      while (j < forecasts.size()) {
        total += w[j] * forecasts[j].lower[i];
        j += 1;
      };
      total
    });
    let upper = Array.tabulate<Float>(horizon, func(i : Nat) : Float {
      var total = 0.0;
      var j : Nat = 0;
      while (j < forecasts.size()) {
        total += w[j] * forecasts[j].upper[i];
        j += 1;
      };
      total
    });
    {
      weights = w;
      members = forecasts;
      combined = {
        point = point;
        lower = lower;
        upper = upper;
        standardErrors = se;
      };
    }
  };

  public func makeStateSpaceModel(transition : Matrix, observation : Matrix, transitionCovariance : Matrix, observationCovariance : Matrix, initialState : Vector, initialCovariance : Matrix, stateIntercept : Vector, observationIntercept : Vector) : StateSpaceModel {
    {
      transition = transition;
      observation = observation;
      transitionCovariance = transitionCovariance;
      observationCovariance = observationCovariance;
      stateIntercept = stateIntercept;
      observationIntercept = observationIntercept;
      initialState = initialState;
      initialCovariance = initialCovariance;
    }
  };

  public func localLevelModel(levelVariance : Float, observationVariance : Float) : StructuralModelSpec {
    {
      name = "local_level";
      model = makeStateSpaceModel(
        [[1.0]],
        [[1.0]],
        [[Float.max(levelVariance, EPS)]],
        [[Float.max(observationVariance, EPS)]],
        [0.0],
        [[1.0]],
        [0.0],
        [0.0],
      );
    }
  };

  public func localLinearTrendModel(levelVariance : Float, slopeVariance : Float, observationVariance : Float) : StructuralModelSpec {
    {
      name = "local_linear_trend";
      model = makeStateSpaceModel(
        [[1.0, 1.0], [0.0, 1.0]],
        [[1.0, 0.0]],
        [[Float.max(levelVariance, EPS), 0.0], [0.0, Float.max(slopeVariance, EPS)]],
        [[Float.max(observationVariance, EPS)]],
        [0.0, 0.0],
        identity(2),
        [0.0, 0.0],
        [0.0],
      );
    }
  };

  public func dynamicLinearModel(transition : Matrix, observation : Matrix, processVariance : Matrix, observationVariance : Matrix, initialState : Vector) : StructuralModelSpec {
    {
      name = "dynamic_linear_model";
      model = makeStateSpaceModel(
        transition,
        observation,
        processVariance,
        observationVariance,
        initialState,
        identity(initialState.size()),
        zeroVector(initialState.size()),
        zeroVector(observation.size()),
      );
    }
  };

  public func kalmanFilter(model : StateSpaceModel, observations : Matrix) : KalmanFilterResult {
    if (observations.size() == 0) {
      return { steps = []; filteredStates = []; predictedStates = []; logLikelihood = 0.0 }
    };
    var state = model.initialState;
    var covariance = model.initialCovariance;
    var steps : [KalmanStep] = [];
    var filteredStates : [Vector] = [];
    var predictedStates : [Vector] = [];
    var totalLogLikelihood = 0.0;

    var t : Nat = 0;
    while (t < observations.size()) {
      let predictedState = vectorAdd(matrixVectorMultiply(model.transition, state), model.stateIntercept);
      let predictedCovariance = matrixAdd(matrixMultiply(matrixMultiply(model.transition, covariance), transpose(model.transition)), model.transitionCovariance);
      let projectedObservation = vectorAdd(matrixVectorMultiply(model.observation, predictedState), model.observationIntercept);
      let innovation = vectorSubtract(observations[t], projectedObservation);
      let innovationCovariance = matrixAdd(matrixMultiply(matrixMultiply(model.observation, predictedCovariance), transpose(model.observation)), model.observationCovariance);
      let gain = matrixMultiply(matrixMultiply(predictedCovariance, transpose(model.observation)), inverseMatrix(innovationCovariance));
      let filteredState = vectorAdd(predictedState, matrixVectorMultiply(gain, innovation));
      let identityState = identity(predictedCovariance.size());
      let filteredCovariance = matrixMultiply(matrixSubtract(identityState, matrixMultiply(gain, model.observation)), predictedCovariance);
      let innovationVariance = Float.max(if (innovationCovariance.size() == 0) 1.0 else innovationCovariance[0][0], EPS);
      let ll = -0.5 * (Float.log(TWO_PI * innovationVariance) + dot(innovation, innovation) / innovationVariance);
      totalLogLikelihood += ll;
      let step : KalmanStep = {
        predictedState = predictedState;
        predictedCovariance = predictedCovariance;
        filteredState = filteredState;
        filteredCovariance = filteredCovariance;
        innovation = innovation;
        innovationCovariance = innovationCovariance;
        logLikelihood = ll;
      };
      steps := Array.concat<KalmanStep>(steps, [step]);
      filteredStates := Array.concat<Vector>(filteredStates, [filteredState]);
      predictedStates := Array.concat<Vector>(predictedStates, [predictedState]);
      state := filteredState;
      covariance := filteredCovariance;
      t += 1;
    };

    {
      steps = steps;
      filteredStates = filteredStates;
      predictedStates = predictedStates;
      logLikelihood = totalLogLikelihood;
    }
  };

  public func forecastStateSpace(model : StateSpaceModel, observations : Matrix, horizon : Nat, alpha : Float) : ForecastResult {
    let filtered = kalmanFilter(model, observations);
    let lastState = if (filtered.filteredStates.size() == 0) model.initialState else filtered.filteredStates[filtered.filteredStates.size() - 1];
    let lastCov = if (filtered.steps.size() == 0) model.initialCovariance else filtered.steps[filtered.steps.size() - 1].filteredCovariance;
    let pointOut = VarArray.repeat<Float>(0.0, horizon);
    let seOut = VarArray.repeat<Float>(0.0, horizon);
    var state = lastState;
    var covariance = lastCov;
    var h : Nat = 0;
    while (h < horizon) {
      state := vectorAdd(matrixVectorMultiply(model.transition, state), model.stateIntercept);
      covariance := matrixAdd(matrixMultiply(matrixMultiply(model.transition, covariance), transpose(model.transition)), model.transitionCovariance);
      let forecastObs = vectorAdd(matrixVectorMultiply(model.observation, state), model.observationIntercept);
      let obsCov = matrixAdd(matrixMultiply(matrixMultiply(model.observation, covariance), transpose(model.observation)), model.observationCovariance);
      pointOut[h] := if (forecastObs.size() == 0) 0.0 else forecastObs[0];
      seOut[h] := Float.sqrt(Float.max(if (obsCov.size() == 0) model.observationCovariance[0][0] else obsCov[0][0], EPS));
      h += 1;
    };
    let z = scalarNormalQuantile(alpha);
    let point = VarArray.toArray<Float>(pointOut);
    let se = VarArray.toArray<Float>(seOut);
    {
      point = point;
      lower = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] - z * se[i] });
      upper = Array.tabulate<Float>(horizon, func(i : Nat) : Float { point[i] + z * se[i] });
      standardErrors = se;
    }
  };

  public func fourierTransform(series : Vector) : [FrequencyPoint] {
    if (series.size() == 0) return [];
    let n = series.size();
    Array.tabulate<FrequencyPoint>(n, func(k : Nat) : FrequencyPoint {
      var real = 0.0;
      var imaginary = 0.0;
      var t : Nat = 0;
      while (t < n) {
        let angle = -TWO_PI * natToFloat(k * t) / natToFloat(n);
        real += series[t] * Float.cos(angle);
        imaginary += series[t] * Float.sin(angle);
        t += 1;
      };
      let amplitude = Float.sqrt(real * real + imaginary * imaginary);
      {
        frequency = natToFloat(k) / natToFloat(n);
        real = real;
        imaginary = imaginary;
        amplitude = amplitude;
        power = amplitude * amplitude / natToFloat(n);
      }
    })
  };

  public func periodogram(series : Vector) : [SpectralDensityPoint] {
    let spectrum = fourierTransform(series);
    let half = spectrum.size() / 2;
    Array.tabulate<SpectralDensityPoint>(half, func(i : Nat) : SpectralDensityPoint {
      {
        frequency = spectrum[i].frequency;
        density = spectrum[i].power;
      }
    })
  };

  public func spectralDensity(series : Vector, smoothingWindow : Nat) : [SpectralDensityPoint] {
    let raw = periodogram(series);
    if (raw.size() == 0) return [];
    Array.tabulate<SpectralDensityPoint>(raw.size(), func(i : Nat) : SpectralDensityPoint {
      let left = if (i > smoothingWindow) i - smoothingWindow else 0;
      let upperBound = raw.size();
      let remaining = natSub(upperBound, i);
      let rightCandidate = if (smoothingWindow + 1 < remaining) i + smoothingWindow + 1 else upperBound;
      let right = rightCandidate;
      var total = 0.0;
      var count : Nat = 0;
      var j = left;
      while (j < right) {
        total += raw[j].density;
        count += 1;
        j += 1;
      };
      {
        frequency = raw[i].frequency;
        density = total / Float.max(natToFloat(count), 1.0);
      }
    })
  };

  func haarStep(series : Vector) : (Vector, Vector) {
    let pairs = series.size() / 2;
    let approx = VarArray.repeat<Float>(0.0, pairs);
    let detail = VarArray.repeat<Float>(0.0, pairs);
    let scale = Float.sqrt(2.0);
    var i : Nat = 0;
    while (i < pairs) {
      let a = series[2 * i];
      let b = series[2 * i + 1];
      approx[i] := (a + b) / scale;
      detail[i] := (a - b) / scale;
      i += 1;
    };
    (VarArray.toArray<Float>(approx), VarArray.toArray<Float>(detail))
  };

  public func waveletDecompose(series : Vector, levels : Nat) : WaveletDecomposition {
    var current = series;
    var approximations : [Vector] = [];
    var details : [Vector] = [];
    var level : Nat = 0;
    while (level < levels and current.size() >= 2) {
      let (approx, detail) = haarStep(current);
      approximations := Array.concat<Vector>(approximations, [approx]);
      details := Array.concat<Vector>(details, [detail]);
      current := approx;
      level += 1;
    };
    {
      approximations = approximations;
      details = details;
    }
  };

  public func cusum(series : Vector, thresholdScale : Float) : [CUSUMPoint] {
    if (series.size() == 0) return [];
    let mu = mean(series);
    let sigma = Float.max(standardDeviation(series), EPS);
    let threshold = thresholdScale * sigma * Float.sqrt(natToFloat(series.size()));
    let out = VarArray.repeat<CUSUMPoint>({ index = 0; statistic = 0.0; exceedsThreshold = false }, series.size());
    var cumulative = 0.0;
    var i : Nat = 0;
    while (i < series.size()) {
      cumulative += series[i] - mu;
      let statistic = cumulative / sigma;
      out[i] := {
        index = i;
        statistic = statistic;
        exceedsThreshold = Float.abs(cumulative) >= threshold;
      };
      i += 1;
    };
    VarArray.toArray<CUSUMPoint>(out)
  };

  public func bayesianChangepoint(series : Vector, priorStrength : Float) : BayesianChangepointResult {
    if (series.size() < 4) {
      return { posterior = []; mostLikelyIndex = null; probability = 0.0 }
    };
    let n = series.size();
    let scores = VarArray.repeat<Float>(0.0, n);
    var total = 0.0;
    var i : Nat = 2;
    while (i + 1 < n) {
      let left = Array.tabulate<Float>(i, func(j : Nat) : Float { series[j] });
      let right = Array.tabulate<Float>(n - i, func(j : Nat) : Float { series[i + j] });
      let leftMean = mean(left);
      let rightMean = mean(right);
      let leftVar = safeVariance(left);
      let rightVar = safeVariance(right);
      let shift = Float.abs(rightMean - leftMean);
      let score = Float.exp(shift / Float.sqrt(leftVar + rightVar + EPS)) * Float.max(priorStrength, EPS);
      scores[i] := score;
      total += score;
      i += 1;
    };
    let posterior = Array.tabulate<Float>(n, func(j : Nat) : Float {
      if (total <= EPS) 0.0 else scores[j] / total
    });
    var bestIdx : ?Nat = null;
    var bestProb = 0.0;
    var k : Nat = 0;
    while (k < posterior.size()) {
      if (posterior[k] > bestProb) {
        bestProb := posterior[k];
        bestIdx := ?k;
      };
      k += 1;
    };
    {
      posterior = posterior;
      mostLikelyIndex = bestIdx;
      probability = bestProb;
    }
  };

  func sseAroundMean(series : Vector) : Float {
    if (series.size() == 0) return 0.0;
    let mu = mean(series);
    var total = 0.0;
    var i : Nat = 0;
    while (i < series.size()) {
      let d = series[i] - mu;
      total += d * d;
      i += 1;
    };
    total
  };

  public func structuralBreakTests(series : Vector, minSegment : Nat) : [StructuralBreakPoint] {
    if (series.size() < 2 * minSegment + 1) return [];
    let totalSse = Float.max(sseAroundMean(series), EPS);
    var points : [StructuralBreakPoint] = [];
    var split = minSegment;
    while (split + minSegment < series.size()) {
      let left = Array.tabulate<Float>(split, func(i : Nat) : Float { series[i] });
      let right = Array.tabulate<Float>(series.size() - split, func(i : Nat) : Float { series[split + i] });
      let leftSse = sseAroundMean(left);
      let rightSse = sseAroundMean(right);
      let numerator = Float.max(totalSse - (leftSse + rightSse), 0.0);
      let denominator = Float.max((leftSse + rightSse) / Float.max(natToFloat(series.size()) - 2.0, 1.0), EPS);
      let fStatistic = numerator / denominator;
      let point : StructuralBreakPoint = {
        index = split;
        fStatistic = fStatistic;
        leftMean = mean(left);
        rightMean = mean(right);
      };
      points := Array.concat<StructuralBreakPoint>(points, [point]);
      split += 1;
    };
    points
  };
}
