"""Trading models and research workflow utilities.

The module covers volatility forecasting, statistical arbitrage, feature
engineering, machine-learning integration, and a lightweight vectorized
backtesting framework.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from sklearn.base import clone
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.metrics import accuracy_score, f1_score, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler


@dataclass(slots=True)
class GARCHFitResult:
    """Estimated parameters and volatility outputs for a GARCH model."""

    parameters: dict[str, float]
    conditional_volatility: pd.Series
    log_likelihood: float
    forecasts: pd.Series


@dataclass(slots=True)
class PairsTradingResult:
    """State estimates and trading signals from the Kalman pairs model."""

    states: pd.DataFrame
    signals: pd.Series


@dataclass(slots=True)
class BacktestResult:
    """Backtest outputs including equity curve and key performance metrics."""

    equity_curve: pd.Series
    strategy_returns: pd.Series
    trades: pd.DataFrame
    metrics: dict[str, float]


class GARCHModel:
    """Estimate and forecast volatility with a Gaussian GARCH(1,1) model."""

    def __init__(self) -> None:
        self.fit_result: GARCHFitResult | None = None

    @staticmethod
    def _conditional_variances(returns: np.ndarray, omega: float, alpha: float, beta: float) -> np.ndarray:
        variance = np.empty_like(returns)
        variance[0] = np.var(returns, ddof=1)
        for idx in range(1, len(returns)):
            variance[idx] = omega + alpha * returns[idx - 1] ** 2 + beta * variance[idx - 1]
        return np.clip(variance, 1e-12, None)

    def fit(self, returns: pd.Series, forecast_horizon: int = 10) -> GARCHFitResult:
        """Fit a GARCH(1,1) model by maximum likelihood."""
        series = pd.Series(returns, dtype=float).dropna()
        data = series.to_numpy()
        variance_guess = float(np.var(data, ddof=1))
        initial = np.array([0.1 * variance_guess, 0.05, 0.9], dtype=float)

        def objective(params: np.ndarray) -> float:
            omega, alpha, beta = params
            if omega <= 0 or alpha < 0 or beta < 0 or alpha + beta >= 0.999:
                return 1e10
            variance = self._conditional_variances(data, omega, alpha, beta)
            return float(0.5 * np.sum(np.log(2 * np.pi) + np.log(variance) + (data**2) / variance))

        result = minimize(
            objective,
            x0=initial,
            method="SLSQP",
            bounds=[(1e-12, None), (1e-8, 1.0), (1e-8, 1.0)],
            constraints=[{"type": "ineq", "fun": lambda x: 0.999 - x[1] - x[2]}],
        )
        omega, alpha, beta = result.x
        variance = self._conditional_variances(data, omega, alpha, beta)
        long_run = omega / max(1.0 - alpha - beta, 1e-8)
        forecast_values = []
        current = variance[-1]
        for _ in range(forecast_horizon):
            current = omega + (alpha + beta) * current
            forecast_values.append(np.sqrt(current))
        forecast_index = pd.RangeIndex(1, forecast_horizon + 1, name="step")
        fitted = GARCHFitResult(
            parameters={"omega": float(omega), "alpha": float(alpha), "beta": float(beta), "long_run_variance": float(long_run)},
            conditional_volatility=pd.Series(np.sqrt(variance), index=series.index, name="sigma"),
            log_likelihood=float(-result.fun),
            forecasts=pd.Series(forecast_values, index=forecast_index, name="forecast_sigma"),
        )
        self.fit_result = fitted
        return fitted


class KalmanPairsTradingModel:
    """Dynamic hedge-ratio estimation for pairs trading using a Kalman filter."""

    def __init__(self, observation_variance: float = 1e-3, transition_variance: float = 1e-4) -> None:
        self.observation_variance = float(observation_variance)
        self.transition_variance = float(transition_variance)

    def fit(
        self,
        y: pd.Series,
        x: pd.Series,
        zscore_window: int = 20,
        entry_threshold: float = 2.0,
        exit_threshold: float = 0.5,
    ) -> PairsTradingResult:
        """Estimate a time-varying hedge ratio and generate trading signals."""
        y_series = pd.Series(y, dtype=float).dropna()
        x_series = pd.Series(x, dtype=float).reindex(y_series.index).astype(float)
        state = np.zeros(2, dtype=float)
        covariance = np.eye(2, dtype=float)
        transition = np.eye(2, dtype=float)
        process_cov = np.eye(2, dtype=float) * self.transition_variance
        measurement_var = self.observation_variance

        records: list[dict[str, float]] = []
        for timestamp, y_t in y_series.items():
            x_t = float(x_series.loc[timestamp])
            state_pred = transition @ state
            covariance_pred = transition @ covariance @ transition.T + process_cov
            design = np.array([x_t, 1.0], dtype=float)
            innovation = y_t - design @ state_pred
            innovation_var = float(design @ covariance_pred @ design.T + measurement_var)
            kalman_gain = covariance_pred @ design / innovation_var
            state = state_pred + kalman_gain * innovation
            covariance = covariance_pred - np.outer(kalman_gain, design) @ covariance_pred
            spread = y_t - (state[0] * x_t + state[1])
            records.append({"hedge_ratio": state[0], "intercept": state[1], "spread": spread})

        states = pd.DataFrame(records, index=y_series.index)
        states["spread_mean"] = states["spread"].rolling(zscore_window).mean()
        states["spread_std"] = states["spread"].rolling(zscore_window).std(ddof=0)
        states["zscore"] = (states["spread"] - states["spread_mean"]) / states["spread_std"]

        signal = []
        current = 0
        for z in states["zscore"].fillna(0.0):
            if current == 0 and z >= entry_threshold:
                current = -1
            elif current == 0 and z <= -entry_threshold:
                current = 1
            elif current != 0 and abs(z) <= exit_threshold:
                current = 0
            signal.append(current)
        signals = pd.Series(signal, index=states.index, name="signal")
        states["signal"] = signals
        return PairsTradingResult(states=states, signals=signals)


def engineer_price_features(
    prices: pd.Series | pd.DataFrame,
    price_column: str | None = None,
    volume_column: str | None = None,
    windows: tuple[int, ...] = (5, 10, 20, 60),
) -> pd.DataFrame:
    """Create a feature matrix for price-based forecasting models."""
    if isinstance(prices, pd.Series):
        price_series = prices.astype(float)
        frame = pd.DataFrame({"price": price_series})
    else:
        frame = prices.copy()
        if price_column is None:
            price_column = "close" if "close" in frame.columns else frame.select_dtypes(include=[np.number]).columns[0]
        price_series = frame[price_column].astype(float)

    features = pd.DataFrame(index=price_series.index)
    features["return_1"] = price_series.pct_change()
    features["log_return_1"] = np.log(price_series).diff()
    for window in windows:
        rolling = price_series.rolling(window)
        features[f"momentum_{window}"] = price_series / price_series.shift(window) - 1.0
        features[f"volatility_{window}"] = features["return_1"].rolling(window).std(ddof=0) * np.sqrt(252)
        features[f"sma_gap_{window}"] = price_series / rolling.mean() - 1.0
        features[f"ema_gap_{window}"] = price_series / price_series.ewm(span=window, adjust=False).mean() - 1.0
        features[f"high_low_range_{window}"] = (rolling.max() - rolling.min()) / rolling.mean()

    delta = price_series.diff()
    gains = delta.clip(lower=0.0).rolling(14).mean()
    losses = (-delta.clip(upper=0.0)).rolling(14).mean()
    rs = gains / losses.replace(0.0, np.nan)
    features["rsi_14"] = 100.0 - (100.0 / (1.0 + rs))

    if volume_column and isinstance(prices, pd.DataFrame) and volume_column in prices.columns:
        volume = prices[volume_column].astype(float)
        features["volume_change"] = volume.pct_change()
        features["volume_zscore_20"] = (volume - volume.rolling(20).mean()) / volume.rolling(20).std(ddof=0)

    return features.replace([np.inf, -np.inf], np.nan).dropna(how="all")


class SKLearnTradingModel:
    """Wrapper for scikit-learn estimators in trading pipelines."""

    def __init__(
        self,
        estimator=None,
        task: Literal["classification", "regression"] = "classification",
        use_scaler: bool = True,
    ) -> None:
        self.task = task
        if estimator is None:
            estimator = (
                RandomForestClassifier(n_estimators=300, random_state=42)
                if task == "classification"
                else RandomForestRegressor(n_estimators=300, random_state=42)
            )
        steps = []
        if use_scaler:
            steps.append(("scaler", StandardScaler()))
        steps.append(("model", estimator))
        self.pipeline = Pipeline(steps)
        self.feature_names_: list[str] | None = None

    def fit(
        self,
        features: pd.DataFrame,
        target: pd.Series,
        test_size: float = 0.25,
        random_state: int = 42,
    ) -> dict[str, float]:
        """Fit the underlying model and return holdout metrics."""
        dataset = pd.concat([features, target.rename("target")], axis=1).dropna()
        x = dataset[features.columns]
        y = dataset["target"]
        x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=test_size, shuffle=False, random_state=random_state)
        self.pipeline = clone(self.pipeline)
        self.pipeline.fit(x_train, y_train)
        self.feature_names_ = list(x.columns)
        predictions = self.pipeline.predict(x_test)
        if self.task == "classification":
            return {
                "accuracy": float(accuracy_score(y_test, predictions)),
                "f1": float(f1_score(y_test, predictions, zero_division=0)),
            }
        return {
            "rmse": float(np.sqrt(mean_squared_error(y_test, predictions))),
            "r2": float(r2_score(y_test, predictions)),
        }

    def predict(self, features: pd.DataFrame) -> pd.Series:
        """Generate predictions for a feature matrix."""
        values = self.pipeline.predict(features)
        return pd.Series(values, index=features.index, name="prediction")


class BacktestEngine:
    """Vectorized single-asset backtesting engine."""

    def __init__(self, initial_capital: float = 100_000.0, transaction_cost: float = 5e-4) -> None:
        self.initial_capital = float(initial_capital)
        self.transaction_cost = float(transaction_cost)

    def run(
        self,
        prices: pd.Series | pd.DataFrame,
        signals: pd.Series,
        price_column: str | None = None,
        annualization: int = 252,
    ) -> BacktestResult:
        """Run a backtest and compute performance statistics."""
        if isinstance(prices, pd.Series):
            price_series = prices.astype(float)
        else:
            column = price_column or ("close" if "close" in prices.columns else prices.select_dtypes(include=[np.number]).columns[0])
            price_series = prices[column].astype(float)

        signal_series = pd.Series(signals, dtype=float).reindex(price_series.index).ffill().fillna(0.0).clip(-1.0, 1.0)
        asset_returns = price_series.pct_change().fillna(0.0)
        positions = signal_series.shift(1).fillna(0.0)
        turnover = signal_series.diff().abs().fillna(signal_series.abs())
        strategy_returns = positions * asset_returns - turnover * self.transaction_cost
        equity_curve = self.initial_capital * (1.0 + strategy_returns).cumprod()

        drawdown = equity_curve / equity_curve.cummax() - 1.0
        total_return = equity_curve.iloc[-1] / equity_curve.iloc[0] - 1.0
        annual_return = (1.0 + total_return) ** (annualization / max(len(strategy_returns), 1)) - 1.0
        annual_vol = float(strategy_returns.std(ddof=0) * np.sqrt(annualization))
        sharpe = annual_return / annual_vol if annual_vol > 1e-12 else np.nan
        downside = strategy_returns[strategy_returns < 0].std(ddof=0) * np.sqrt(annualization)
        sortino = annual_return / downside if downside and downside > 1e-12 else np.nan
        win_rate = float((strategy_returns[strategy_returns != 0] > 0).mean()) if (strategy_returns != 0).any() else 0.0
        metrics = {
            "total_return": float(total_return),
            "annual_return": float(annual_return),
            "annual_volatility": float(annual_vol),
            "sharpe_ratio": float(sharpe),
            "sortino_ratio": float(sortino),
            "max_drawdown": float(drawdown.min()),
            "win_rate": float(win_rate),
            "turnover": float(turnover.sum()),
        }

        trade_mask = signal_series.diff().fillna(signal_series).ne(0)
        trades = pd.DataFrame({
            "price": price_series[trade_mask],
            "signal": signal_series[trade_mask],
            "turnover": turnover[trade_mask],
        })
        return BacktestResult(equity_curve=equity_curve, strategy_returns=strategy_returns, trades=trades, metrics=metrics)
