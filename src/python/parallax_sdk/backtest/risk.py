from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class ExposureLimits:
    max_gross_exposure: float = 1.5
    max_net_exposure: float = 1.0
    max_symbol_exposure: float = 0.25
    max_leverage: float = 1.5
    allow_short: bool = True


@dataclass(slots=True)
class ExposureSnapshot:
    timestamp: pd.Timestamp | None
    gross_exposure: float
    net_exposure: float
    leverage: float
    long_exposure: float
    short_exposure: float
    symbol_exposure: dict[str, float]


@dataclass(slots=True)
class OrderRiskDecision:
    approved: bool
    approved_quantity: float
    reason: str = ''


class RiskAnalyzer:
    """Risk analytics for portfolio and benchmark relationships."""

    def __init__(self, confidence_level: float = 0.95, periods_per_year: int = 252) -> None:
        self.confidence_level = confidence_level
        self.periods_per_year = periods_per_year

    def value_at_risk(self, returns: pd.Series) -> float:
        cleaned = returns.dropna()
        if cleaned.empty:
            return 0.0
        percentile = (1.0 - self.confidence_level) * 100.0
        return float(np.percentile(cleaned, percentile))

    def conditional_value_at_risk(self, returns: pd.Series) -> float:
        var = self.value_at_risk(returns)
        tail = returns[returns <= var]
        return float(tail.mean()) if not tail.empty else var

    def beta(self, returns: pd.Series, benchmark_returns: pd.Series) -> float:
        aligned = pd.concat([returns, benchmark_returns], axis=1).dropna()
        if aligned.empty:
            return 0.0
        covariance = np.cov(aligned.iloc[:, 0], aligned.iloc[:, 1], ddof=0)[0, 1]
        benchmark_variance = np.var(aligned.iloc[:, 1], ddof=0)
        if benchmark_variance == 0:
            return 0.0
        return float(covariance / benchmark_variance)

    def correlation(self, returns: pd.Series, benchmark_returns: pd.Series) -> float:
        aligned = pd.concat([returns, benchmark_returns], axis=1).dropna()
        if aligned.empty:
            return 0.0
        return float(aligned.iloc[:, 0].corr(aligned.iloc[:, 1]))

    def tracking_error(self, returns: pd.Series, benchmark_returns: pd.Series) -> float:
        aligned = pd.concat([returns, benchmark_returns], axis=1).dropna()
        if aligned.empty:
            return 0.0
        diff = aligned.iloc[:, 0] - aligned.iloc[:, 1]
        return float(diff.std(ddof=0) * np.sqrt(self.periods_per_year))

    def information_ratio(self, returns: pd.Series, benchmark_returns: pd.Series) -> float:
        aligned = pd.concat([returns, benchmark_returns], axis=1).dropna()
        if aligned.empty:
            return 0.0
        active = aligned.iloc[:, 0] - aligned.iloc[:, 1]
        tracking_error = active.std(ddof=0)
        if tracking_error == 0:
            return 0.0
        return float(np.sqrt(self.periods_per_year) * active.mean() / tracking_error)

    def exposure_snapshot(
        self,
        positions: dict[str, float],
        prices: dict[str, float],
        equity: float,
        timestamp: pd.Timestamp | None = None,
    ) -> ExposureSnapshot:
        exposures = {symbol: float(quantity) * float(prices.get(symbol, 0.0)) for symbol, quantity in positions.items()}
        long_exposure = sum(value for value in exposures.values() if value > 0)
        short_exposure = sum(value for value in exposures.values() if value < 0)
        gross_exposure = sum(abs(value) for value in exposures.values())
        net_exposure = sum(exposures.values())
        leverage = gross_exposure / equity if equity else 0.0
        symbol_exposure = {
            symbol: abs(value) / equity if equity else 0.0
            for symbol, value in exposures.items()
        }
        return ExposureSnapshot(
            timestamp=timestamp,
            gross_exposure=float(gross_exposure),
            net_exposure=float(net_exposure),
            leverage=float(leverage),
            long_exposure=float(long_exposure),
            short_exposure=float(short_exposure),
            symbol_exposure=symbol_exposure,
        )

    def summarize(
        self,
        returns: pd.Series,
        benchmark_returns: pd.Series | None = None,
        positions: dict[str, float] | None = None,
        prices: dict[str, float] | None = None,
        equity: float | None = None,
    ) -> dict[str, Any]:
        summary: dict[str, Any] = {
            'value_at_risk': self.value_at_risk(returns),
            'conditional_value_at_risk': self.conditional_value_at_risk(returns),
        }
        if benchmark_returns is not None:
            summary.update(
                {
                    'beta': self.beta(returns, benchmark_returns),
                    'correlation_to_benchmark': self.correlation(returns, benchmark_returns),
                    'tracking_error': self.tracking_error(returns, benchmark_returns),
                    'information_ratio': self.information_ratio(returns, benchmark_returns),
                }
            )
        if positions is not None and prices is not None and equity is not None:
            exposure = self.exposure_snapshot(positions, prices, equity)
            summary.update(
                {
                    'gross_exposure': exposure.gross_exposure,
                    'net_exposure': exposure.net_exposure,
                    'leverage': exposure.leverage,
                    'long_exposure': exposure.long_exposure,
                    'short_exposure': exposure.short_exposure,
                    'symbol_exposure': exposure.symbol_exposure,
                }
            )
        return summary


class RiskManager(RiskAnalyzer):
    """Risk manager combining portfolio limits with analytics."""

    def __init__(
        self,
        limits: ExposureLimits | None = None,
        confidence_level: float = 0.95,
        periods_per_year: int = 252,
    ) -> None:
        super().__init__(confidence_level=confidence_level, periods_per_year=periods_per_year)
        self.limits = limits or ExposureLimits()

    def check_order(
        self,
        symbol: str,
        desired_quantity: float,
        price: float,
        positions: dict[str, float],
        equity: float,
        prices: dict[str, float],
    ) -> OrderRiskDecision:
        if desired_quantity == 0:
            return OrderRiskDecision(True, 0.0, 'zero_quantity')

        current_quantity = float(positions.get(symbol, 0.0))
        proposed_quantity = current_quantity + desired_quantity
        if not self.limits.allow_short and proposed_quantity < 0:
            proposed_quantity = 0.0

        if equity <= 0 or price <= 0:
            return OrderRiskDecision(False, 0.0, 'invalid_equity_or_price')

        max_symbol_notional = self.limits.max_symbol_exposure * equity
        max_symbol_quantity = max_symbol_notional / price
        proposed_quantity = float(np.clip(proposed_quantity, -max_symbol_quantity, max_symbol_quantity))

        adjusted = proposed_quantity - current_quantity
        trial_positions = dict(positions)
        trial_positions[symbol] = proposed_quantity
        snapshot = self.exposure_snapshot(trial_positions, prices | {symbol: price}, equity)

        if snapshot.leverage > self.limits.max_leverage or snapshot.gross_exposure > self.limits.max_gross_exposure * equity:
            current_abs_exposure = sum(abs(float(qty) * float(prices.get(sym, price if sym == symbol else 0.0))) for sym, qty in positions.items())
            room = max(self.limits.max_gross_exposure * equity - current_abs_exposure, 0.0)
            adjusted_sign = np.sign(adjusted)
            adjusted = adjusted_sign * min(abs(adjusted), room / price)
            trial_positions[symbol] = current_quantity + adjusted
            snapshot = self.exposure_snapshot(trial_positions, prices | {symbol: price}, equity)

        if abs(snapshot.net_exposure) > self.limits.max_net_exposure * equity:
            allowed_net = self.limits.max_net_exposure * equity
            current_net = sum(float(qty) * float(prices.get(sym, 0.0)) for sym, qty in positions.items())
            available = max(allowed_net - abs(current_net), 0.0)
            adjusted = np.sign(adjusted) * min(abs(adjusted), available / price)

        approved = abs(adjusted) > 0 or desired_quantity == 0
        reason = 'approved' if approved else 'rejected_by_exposure_limits'
        return OrderRiskDecision(approved=approved, approved_quantity=float(adjusted), reason=reason)

    def review_signal(self, signal: Any, context: Any) -> Any:
        if signal.target_weight is not None:
            signal.target_weight = float(np.clip(signal.target_weight, -self.limits.max_symbol_exposure, self.limits.max_symbol_exposure))
            return signal
        if signal.quantity is None:
            return signal
        price = context.price(signal.symbol) or 0.0
        decision = self.check_order(
            symbol=signal.symbol,
            desired_quantity=signal.quantity,
            price=price,
            positions=context.positions,
            equity=context.equity,
            prices=context.prices,
        )
        if not decision.approved:
            return None
        signal.quantity = decision.approved_quantity
        return signal
