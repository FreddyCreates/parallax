"""Statsmodels-backed time series analysis for PARALLAX."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, Sequence

import numpy as np
import pandas as pd

Criterion = Literal["aic", "bic"]

try:  # pragma: no cover - optional runtime dependency
    from statsmodels.tsa.arima.model import ARIMA
    from statsmodels.tsa.statespace.sarimax import SARIMAX
    from statsmodels.tsa.statespace.structural import UnobservedComponents
except Exception:  # pragma: no cover - graceful fallback when statsmodels is absent
    ARIMA = None
    SARIMAX = None
    UnobservedComponents = None


@dataclass(slots=True)
class ForecastResult:
    mean: pd.Series
    lower: pd.Series
    upper: pd.Series
    standard_error: pd.Series


@dataclass(slots=True)
class FittedTimeSeriesModel:
    model_family: str
    order: tuple[int, int, int]
    seasonal_order: tuple[int, int, int, int] | None
    criterion: str
    score: float
    result: Any

    @property
    def residuals(self) -> pd.Series:
        resid = getattr(self.result, "resid", None)
        return _to_series(resid, name=f"{self.model_family}_resid")


@dataclass(slots=True)
class ModelSelectionResult:
    best_model: FittedTimeSeriesModel
    candidates: list[FittedTimeSeriesModel]


@dataclass(slots=True)
class StateSpaceResult:
    specification: str
    fitted: FittedTimeSeriesModel
    filtered_state: pd.DataFrame
    smoothed_state: pd.DataFrame | None


@dataclass(slots=True)
class FrequencyDomainResult:
    spectrum: pd.DataFrame
    spectral_density: pd.DataFrame
    dominant_frequency: float
    dominant_period: float | None


@dataclass(slots=True)
class WaveletResult:
    approximations: list[np.ndarray]
    details: list[np.ndarray]


@dataclass(slots=True)
class ChangepointResult:
    changepoints: list[int]
    scores: pd.Series
    threshold: float


@dataclass(slots=True)
class StructuralBreakResult:
    break_index: int | None
    break_statistic: float
    table: pd.DataFrame


class MissingStatsmodelsError(ImportError):
    """Raised when statsmodels-backed functionality is requested without statsmodels."""


def _require_statsmodels() -> None:
    if ARIMA is None or SARIMAX is None or UnobservedComponents is None:
        raise MissingStatsmodelsError(
            "statsmodels is required for parallax_sdk.timeseries statsmodels integration"
        )


def _to_series(values: Any, name: str = "value") -> pd.Series:
    if isinstance(values, pd.Series):
        return values.rename(name)
    if isinstance(values, pd.DataFrame):
        if values.shape[1] != 1:
            raise ValueError("expected a 1D series-like input")
        return values.iloc[:, 0].rename(name)
    array = np.asarray(values, dtype=float).reshape(-1)
    return pd.Series(array, name=name)


def _criterion_value(result: Any, criterion: Criterion) -> float:
    value = getattr(result, criterion)
    return float(value if np.isfinite(value) else np.inf)


def fit_arima(
    series: Sequence[float] | pd.Series,
    order: tuple[int, int, int],
    *,
    trend: str | None = None,
    enforce_stationarity: bool = False,
    enforce_invertibility: bool = False,
) -> FittedTimeSeriesModel:
    _require_statsmodels()
    endog = _to_series(series, name="y")
    resolved_trend = trend
    if resolved_trend is None:
        resolved_trend = "n" if order[1] > 0 else "c"
    elif order[1] > 0 and resolved_trend == "c":
        resolved_trend = "n"
    result = ARIMA(
        endog,
        order=order,
        trend=resolved_trend,
        enforce_stationarity=enforce_stationarity,
        enforce_invertibility=enforce_invertibility,
    ).fit()
    return FittedTimeSeriesModel(
        model_family="ARIMA",
        order=order,
        seasonal_order=None,
        criterion="aic",
        score=float(result.aic),
        result=result,
    )


def fit_sarima(
    series: Sequence[float] | pd.Series,
    order: tuple[int, int, int],
    seasonal_order: tuple[int, int, int, int],
    *,
    trend: str | None = None,
    enforce_stationarity: bool = False,
    enforce_invertibility: bool = False,
) -> FittedTimeSeriesModel:
    _require_statsmodels()
    endog = _to_series(series, name="y")
    resolved_trend = trend
    if resolved_trend is None:
        resolved_trend = "n" if (order[1] > 0 or seasonal_order[1] > 0) else "c"
    elif (order[1] > 0 or seasonal_order[1] > 0) and resolved_trend == "c":
        resolved_trend = "n"
    result = SARIMAX(
        endog,
        order=order,
        seasonal_order=seasonal_order,
        trend=resolved_trend,
        enforce_stationarity=enforce_stationarity,
        enforce_invertibility=enforce_invertibility,
    ).fit(disp=False)
    return FittedTimeSeriesModel(
        model_family="SARIMA",
        order=order,
        seasonal_order=seasonal_order,
        criterion="aic",
        score=float(result.aic),
        result=result,
    )


def select_arima_model(
    series: Sequence[float] | pd.Series,
    *,
    max_order: tuple[int, int, int] = (3, 2, 3),
    criterion: Criterion = "aic",
) -> ModelSelectionResult:
    _require_statsmodels()
    candidates: list[FittedTimeSeriesModel] = []
    best: FittedTimeSeriesModel | None = None
    for p in range(max_order[0] + 1):
        for d in range(max_order[1] + 1):
            for q in range(max_order[2] + 1):
                try:
                    fitted = fit_arima(series, (p, d, q))
                except Exception:
                    continue
                fitted.criterion = criterion
                fitted.score = _criterion_value(fitted.result, criterion)
                candidates.append(fitted)
                if best is None or fitted.score < best.score:
                    best = fitted
    if best is None:
        raise ValueError("no ARIMA specification converged")
    return ModelSelectionResult(best_model=best, candidates=candidates)


def select_sarima_model(
    series: Sequence[float] | pd.Series,
    *,
    seasonal_period: int,
    max_order: tuple[int, int, int] = (2, 1, 2),
    max_seasonal_order: tuple[int, int, int] = (1, 1, 1),
    criterion: Criterion = "aic",
) -> ModelSelectionResult:
    _require_statsmodels()
    candidates: list[FittedTimeSeriesModel] = []
    best: FittedTimeSeriesModel | None = None
    for p in range(max_order[0] + 1):
        for d in range(max_order[1] + 1):
            for q in range(max_order[2] + 1):
                for P in range(max_seasonal_order[0] + 1):
                    for D in range(max_seasonal_order[1] + 1):
                        for Q in range(max_seasonal_order[2] + 1):
                            try:
                                fitted = fit_sarima(series, (p, d, q), (P, D, Q, seasonal_period))
                            except Exception:
                                continue
                            fitted.criterion = criterion
                            fitted.score = _criterion_value(fitted.result, criterion)
                            candidates.append(fitted)
                            if best is None or fitted.score < best.score:
                                best = fitted
    if best is None:
        raise ValueError("no SARIMA specification converged")
    return ModelSelectionResult(best_model=best, candidates=candidates)


def forecast(model: FittedTimeSeriesModel, steps: int, alpha: float = 0.05) -> ForecastResult:
    prediction = model.result.get_forecast(steps=steps)
    interval = prediction.conf_int(alpha=alpha)
    if isinstance(interval, pd.DataFrame):
        lower = interval.iloc[:, 0]
        upper = interval.iloc[:, 1]
    else:
        interval = np.asarray(interval, dtype=float)
        lower = pd.Series(interval[:, 0])
        upper = pd.Series(interval[:, 1])
    mean = _to_series(prediction.predicted_mean, name="forecast")
    se = _to_series(getattr(prediction, "se_mean", np.sqrt(np.maximum(model.result.scale, 1e-9))), name="standard_error")
    lower.index = mean.index
    upper.index = mean.index
    se.index = mean.index
    return ForecastResult(mean=mean, lower=lower.rename("lower"), upper=upper.rename("upper"), standard_error=se)


def ensemble_forecast(
    models: Sequence[FittedTimeSeriesModel],
    steps: int,
    *,
    alpha: float = 0.05,
    weights: Sequence[float] | None = None,
) -> ForecastResult:
    if not models:
        raise ValueError("at least one model is required")
    member_forecasts = [forecast(model, steps=steps, alpha=alpha) for model in models]
    if weights is None:
        weights_array = np.full(len(models), 1.0 / len(models), dtype=float)
    else:
        weights_array = np.asarray(weights, dtype=float)
        if weights_array.shape != (len(models),):
            raise ValueError("weights must align with models")
        total = weights_array.sum()
        if total == 0:
            raise ValueError("weights must not sum to zero")
        weights_array = weights_array / total
    mean = sum(weight * result.mean for weight, result in zip(weights_array, member_forecasts, strict=True))
    lower = sum(weight * result.lower for weight, result in zip(weights_array, member_forecasts, strict=True))
    upper = sum(weight * result.upper for weight, result in zip(weights_array, member_forecasts, strict=True))
    se = sum(weight * result.standard_error for weight, result in zip(weights_array, member_forecasts, strict=True))
    return ForecastResult(mean=mean.rename("forecast"), lower=lower.rename("lower"), upper=upper.rename("upper"), standard_error=se.rename("standard_error"))


def fit_structural_time_series(
    series: Sequence[float] | pd.Series,
    *,
    level: Literal["local level", "fixed intercept", "deterministic constant"] = "local level",
    trend: bool = False,
    seasonal: int | None = None,
    cycle: bool = False,
) -> StateSpaceResult:
    _require_statsmodels()
    endog = _to_series(series, name="y")
    model = UnobservedComponents(endog, level=level, trend=trend, seasonal=seasonal, cycle=cycle)
    result = model.fit(disp=False)
    filtered = pd.DataFrame(result.filtered_state.T)
    smoothed = None if result.smoothed_state is None else pd.DataFrame(result.smoothed_state.T)
    fitted = FittedTimeSeriesModel(
        model_family="StructuralTimeSeries",
        order=(0, 0, 0),
        seasonal_order=None,
        criterion="aic",
        score=float(result.aic),
        result=result,
    )
    return StateSpaceResult(
        specification=f"level={level}, trend={trend}, seasonal={seasonal}, cycle={cycle}",
        fitted=fitted,
        filtered_state=filtered,
        smoothed_state=smoothed,
    )


def fit_dynamic_linear_model(
    series: Sequence[float] | pd.Series,
    *,
    exog: pd.DataFrame | np.ndarray | None = None,
    order: tuple[int, int, int] = (1, 0, 0),
    seasonal_order: tuple[int, int, int, int] = (0, 0, 0, 0),
) -> StateSpaceResult:
    _require_statsmodels()
    endog = _to_series(series, name="y")
    result = SARIMAX(endog, exog=exog, order=order, seasonal_order=seasonal_order, trend="c").fit(disp=False)
    filtered = pd.DataFrame(result.filtered_state.T)
    smoothed = None if result.smoothed_state is None else pd.DataFrame(result.smoothed_state.T)
    fitted = FittedTimeSeriesModel(
        model_family="DynamicLinearModel",
        order=order,
        seasonal_order=seasonal_order,
        criterion="aic",
        score=float(result.aic),
        result=result,
    )
    return StateSpaceResult(
        specification=f"order={order}, seasonal_order={seasonal_order}, exog={exog is not None}",
        fitted=fitted,
        filtered_state=filtered,
        smoothed_state=smoothed,
    )


def frequency_domain_analysis(series: Sequence[float] | pd.Series, sample_spacing: float = 1.0, smoothing_window: int = 5) -> FrequencyDomainResult:
    values = _to_series(series, name="y").to_numpy(dtype=float)
    centered = values - values.mean()
    fft = np.fft.rfft(centered)
    freqs = np.fft.rfftfreq(centered.size, d=sample_spacing)
    power = np.abs(fft) ** 2 / max(centered.size, 1)
    spectrum = pd.DataFrame({
        "frequency": freqs,
        "real": fft.real,
        "imaginary": fft.imag,
        "power": power,
        "amplitude": np.abs(fft),
    })
    kernel = np.ones(max(smoothing_window, 1), dtype=float)
    kernel /= kernel.sum()
    smoothed = np.convolve(power, kernel, mode="same")
    spectral_density = pd.DataFrame({"frequency": freqs, "density": smoothed})
    dominant_index = int(np.argmax(power[1:]) + 1) if power.size > 1 else 0
    dominant_frequency = float(freqs[dominant_index]) if freqs.size else 0.0
    dominant_period = None if dominant_frequency == 0 else float(1.0 / dominant_frequency)
    return FrequencyDomainResult(
        spectrum=spectrum,
        spectral_density=spectral_density,
        dominant_frequency=dominant_frequency,
        dominant_period=dominant_period,
    )


def haar_wavelet_decomposition(series: Sequence[float] | pd.Series, levels: int = 3) -> WaveletResult:
    current = _to_series(series, name="y").to_numpy(dtype=float)
    approximations: list[np.ndarray] = []
    details: list[np.ndarray] = []
    for _ in range(max(levels, 0)):
        if current.size < 2:
            break
        usable = current[: current.size - (current.size % 2)]
        pairs = usable.reshape(-1, 2)
        approximation = (pairs[:, 0] + pairs[:, 1]) / np.sqrt(2.0)
        detail = (pairs[:, 0] - pairs[:, 1]) / np.sqrt(2.0)
        approximations.append(approximation)
        details.append(detail)
        current = approximation
    return WaveletResult(approximations=approximations, details=details)


def detect_cusum_changepoints(
    series: Sequence[float] | pd.Series,
    *,
    threshold: float = 5.0,
    drift: float = 0.0,
) -> ChangepointResult:
    values = _to_series(series, name="y").to_numpy(dtype=float)
    mean = values.mean()
    std = max(values.std(ddof=1), 1e-9)
    centered = (values - mean) / std
    positive = np.zeros_like(centered)
    negative = np.zeros_like(centered)
    changepoints: list[int] = []
    for i, value in enumerate(centered):
        positive[i] = max(0.0, (positive[i - 1] if i else 0.0) + value - drift)
        negative[i] = min(0.0, (negative[i - 1] if i else 0.0) + value + drift)
        if positive[i] > threshold or abs(negative[i]) > threshold:
            changepoints.append(i)
            positive[i] = 0.0
            negative[i] = 0.0
    score = pd.Series(np.maximum(positive, np.abs(negative)), name="cusum_score")
    return ChangepointResult(changepoints=changepoints, scores=score, threshold=threshold)


def bayesian_changepoint_scores(series: Sequence[float] | pd.Series, prior_scale: float = 1.0) -> pd.Series:
    values = _to_series(series, name="y").to_numpy(dtype=float)
    if values.size < 4:
        return pd.Series(dtype=float, name="posterior")
    scores = np.zeros(values.size, dtype=float)
    for split in range(2, values.size - 1):
        left = values[:split]
        right = values[split:]
        scale = np.sqrt(max(left.var(ddof=1), 1e-9) + max(right.var(ddof=1), 1e-9))
        shift = abs(right.mean() - left.mean())
        scores[split] = np.exp(shift / scale) * max(prior_scale, 1e-9)
    total = scores.sum()
    posterior = scores / total if total else scores
    return pd.Series(posterior, name="posterior")


def structural_break_test(series: Sequence[float] | pd.Series, min_segment: int = 20) -> StructuralBreakResult:
    values = _to_series(series, name="y").to_numpy(dtype=float)
    if values.size < 2 * min_segment + 1:
        return StructuralBreakResult(break_index=None, break_statistic=0.0, table=pd.DataFrame(columns=["break_index", "f_statistic", "left_mean", "right_mean"]))
    total_mean = values.mean()
    total_sse = float(np.sum((values - total_mean) ** 2))
    rows: list[dict[str, float]] = []
    for split in range(min_segment, values.size - min_segment):
        left = values[:split]
        right = values[split:]
        left_sse = float(np.sum((left - left.mean()) ** 2))
        right_sse = float(np.sum((right - right.mean()) ** 2))
        pooled = max((left_sse + right_sse) / max(values.size - 2, 1), 1e-9)
        f_statistic = max(total_sse - (left_sse + right_sse), 0.0) / pooled
        rows.append({
            "break_index": float(split),
            "f_statistic": float(f_statistic),
            "left_mean": float(left.mean()),
            "right_mean": float(right.mean()),
        })
    table = pd.DataFrame(rows)
    if table.empty:
        return StructuralBreakResult(break_index=None, break_statistic=0.0, table=table)
    best_row = table.loc[table["f_statistic"].idxmax()]
    return StructuralBreakResult(
        break_index=int(best_row["break_index"]),
        break_statistic=float(best_row["f_statistic"]),
        table=table,
    )
