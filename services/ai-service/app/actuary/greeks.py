"""Options Greeks Engine for HFT Portfolio Risk.

Calculates Delta, Gamma, Vega, Theta, Rho for strategy-level risk management.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


def _norm_cdf(x: float) -> float:
    """Standard normal CDF."""
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))


def _norm_pdf(x: float) -> float:
    """Standard normal PDF."""
    return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)


@dataclass
class GreeksResult:
    delta: float
    gamma: float
    vega: float
    theta: float
    rho: float
    charm: float = 0.0  # Delta decay
    vanna: float = 0.0  # Delta sensitivity to vol
    volga: float = 0.0  # Vega sensitivity to vol


class DeltaModel:
    """Delta — first-order sensitivity to underlying price."""

    def calculate(
        self, spot: float, strike: float, tau: float, r: float, sigma: float, is_call: bool = True
    ) -> float:
        if tau <= 0 or sigma <= 0:
            if is_call:
                return 1.0 if spot > strike else 0.0
            return -1.0 if spot < strike else 0.0

        d1 = (math.log(spot / strike) + (r + 0.5 * sigma**2) * tau) / (sigma * math.sqrt(tau))
        if is_call:
            return _norm_cdf(d1)
        return _norm_cdf(d1) - 1.0


class GammaModel:
    """Gamma — second-order sensitivity (convexity)."""

    def calculate(self, spot: float, strike: float, tau: float, r: float, sigma: float) -> float:
        if tau <= 0 or sigma <= 0 or spot <= 0:
            return 0.0

        d1 = (math.log(spot / strike) + (r + 0.5 * sigma**2) * tau) / (sigma * math.sqrt(tau))
        return _norm_pdf(d1) / (spot * sigma * math.sqrt(tau))


class VegaModel:
    """Vega — sensitivity to implied volatility."""

    def calculate(self, spot: float, strike: float, tau: float, r: float, sigma: float) -> float:
        if tau <= 0 or sigma <= 0:
            return 0.0

        d1 = (math.log(spot / strike) + (r + 0.5 * sigma**2) * tau) / (sigma * math.sqrt(tau))
        return spot * _norm_pdf(d1) * math.sqrt(tau) / 100  # Per 1% vol move


class ThetaModel:
    """Theta — time decay."""

    def calculate(
        self, spot: float, strike: float, tau: float, r: float, sigma: float, is_call: bool = True
    ) -> float:
        if tau <= 0 or sigma <= 0:
            return 0.0

        d1 = (math.log(spot / strike) + (r + 0.5 * sigma**2) * tau) / (sigma * math.sqrt(tau))
        d2 = d1 - sigma * math.sqrt(tau)

        term1 = -(spot * _norm_pdf(d1) * sigma) / (2 * math.sqrt(tau))
        if is_call:
            term2 = -r * strike * math.exp(-r * tau) * _norm_cdf(d2)
        else:
            term2 = r * strike * math.exp(-r * tau) * _norm_cdf(-d2)

        return (term1 + term2) / 365  # Daily theta


class GreeksEngine:
    """Complete Greeks calculation engine."""

    def __init__(self) -> None:
        self.delta_model = DeltaModel()
        self.gamma_model = GammaModel()
        self.vega_model = VegaModel()
        self.theta_model = ThetaModel()

    def calculate_all(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
    ) -> GreeksResult:
        """Calculate all Greeks for a position."""
        tau = time_to_expiry
        r = risk_free_rate
        sigma = volatility

        delta = self.delta_model.calculate(spot, strike, tau, r, sigma, is_call)
        gamma = self.gamma_model.calculate(spot, strike, tau, r, sigma)
        vega = self.vega_model.calculate(spot, strike, tau, r, sigma)
        theta = self.theta_model.calculate(spot, strike, tau, r, sigma, is_call)

        # Rho — sensitivity to interest rate
        if tau > 0 and sigma > 0:
            d2 = (
                (math.log(spot / strike) + (r + 0.5 * sigma**2) * tau) / (sigma * math.sqrt(tau))
                - sigma * math.sqrt(tau)
            )
            if is_call:
                rho = strike * tau * math.exp(-r * tau) * _norm_cdf(d2) / 100
            else:
                rho = -strike * tau * math.exp(-r * tau) * _norm_cdf(-d2) / 100
        else:
            rho = 0.0

        return GreeksResult(
            delta=delta,
            gamma=gamma,
            vega=vega,
            theta=theta,
            rho=rho,
        )

    def portfolio_greeks(self, positions: list[dict[str, Any]]) -> dict[str, float]:
        """Aggregate Greeks across a portfolio of positions."""
        totals = {"delta": 0.0, "gamma": 0.0, "vega": 0.0, "theta": 0.0, "rho": 0.0}

        for pos in positions:
            greeks = self.calculate_all(
                spot=pos["spot"],
                strike=pos["strike"],
                time_to_expiry=pos["tau"],
                risk_free_rate=pos.get("r", 0.05),
                volatility=pos.get("sigma", 0.20),
                is_call=pos.get("is_call", True),
            )
            qty = pos.get("quantity", 1.0)
            totals["delta"] += greeks.delta * qty
            totals["gamma"] += greeks.gamma * qty
            totals["vega"] += greeks.vega * qty
            totals["theta"] += greeks.theta * qty
            totals["rho"] += greeks.rho * qty

        return totals
