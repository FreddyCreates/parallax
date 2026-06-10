"""Portfolio Insurance Models.

Implements CPPI (Constant Proportion Portfolio Insurance) and
OBPI (Option-Based Portfolio Insurance) for HFT fund protection.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Any


@dataclass
class InsuranceState:
    floor_value: float
    cushion: float
    risky_allocation: float
    safe_allocation: float
    portfolio_value: float
    multiplier: float
    breach_count: int = 0


class CPPIModel:
    """Constant Proportion Portfolio Insurance.

    Dynamically adjusts between risky (strategies) and safe (cash/bonds) assets
    to maintain a guaranteed floor value.
    """

    def __init__(
        self,
        floor_pct: float = 0.80,
        multiplier: float = 5.0,
        rebalance_threshold: float = 0.05,
    ) -> None:
        self.floor_pct = floor_pct
        self.multiplier = multiplier
        self.rebalance_threshold = rebalance_threshold

    def initialize(self, portfolio_value: float) -> InsuranceState:
        """Initialize CPPI state."""
        floor = portfolio_value * self.floor_pct
        cushion = portfolio_value - floor
        risky = min(cushion * self.multiplier, portfolio_value)
        safe = portfolio_value - risky

        return InsuranceState(
            floor_value=floor,
            cushion=cushion,
            risky_allocation=risky,
            safe_allocation=safe,
            portfolio_value=portfolio_value,
            multiplier=self.multiplier,
        )

    def rebalance(self, state: InsuranceState, new_portfolio_value: float) -> InsuranceState:
        """Rebalance allocations based on new portfolio value."""
        state.portfolio_value = new_portfolio_value
        state.cushion = max(0, new_portfolio_value - state.floor_value)
        risky_target = min(state.cushion * self.multiplier, new_portfolio_value)

        # Only rebalance if drift exceeds threshold
        drift = abs(risky_target - state.risky_allocation) / max(state.portfolio_value, 1)
        if drift > self.rebalance_threshold:
            state.risky_allocation = risky_target
            state.safe_allocation = new_portfolio_value - risky_target

        # Check floor breach
        if new_portfolio_value < state.floor_value:
            state.breach_count += 1
            state.risky_allocation = 0.0
            state.safe_allocation = new_portfolio_value

        return state


class OBPIModel:
    """Option-Based Portfolio Insurance using synthetic put protection."""

    def __init__(self, strike_pct: float = 0.95, volatility: float = 0.20) -> None:
        self.strike_pct = strike_pct
        self.volatility = volatility

    def black_scholes_put(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
    ) -> float:
        """Calculate put option price using Black-Scholes."""
        if time_to_expiry <= 0 or spot <= 0 or strike <= 0:
            return max(0, strike - spot)

        d1 = (
            math.log(spot / strike)
            + (risk_free_rate + 0.5 * self.volatility**2) * time_to_expiry
        ) / (self.volatility * math.sqrt(time_to_expiry))
        d2 = d1 - self.volatility * math.sqrt(time_to_expiry)

        # Standard normal CDF approximation
        def norm_cdf(x: float) -> float:
            return 0.5 * (1 + math.erf(x / math.sqrt(2)))

        put_price = (
            strike * math.exp(-risk_free_rate * time_to_expiry) * norm_cdf(-d2)
            - spot * norm_cdf(-d1)
        )
        return max(0, put_price)

    def protection_cost(
        self, portfolio_value: float, protection_period_days: int = 30
    ) -> dict[str, float]:
        """Calculate cost of portfolio protection."""
        strike = portfolio_value * self.strike_pct
        time_to_expiry = protection_period_days / 365.0
        put_cost = self.black_scholes_put(portfolio_value, strike, time_to_expiry)

        return {
            "put_cost": put_cost,
            "cost_pct": put_cost / portfolio_value * 100,
            "protected_floor": strike,
            "max_loss_pct": (1 - self.strike_pct) * 100 + put_cost / portfolio_value * 100,
            "break_even_return": put_cost / portfolio_value * 100,
        }


class PortfolioInsuranceEngine:
    """Unified portfolio insurance combining CPPI and OBPI strategies."""

    def __init__(self) -> None:
        self.cppi = CPPIModel()
        self.obpi = OBPIModel()
        self.active_insurance: dict[str, InsuranceState] = {}

    def activate_cppi(self, portfolio_id: str, value: float, **kwargs: Any) -> InsuranceState:
        """Activate CPPI protection for a portfolio."""
        model = CPPIModel(**kwargs) if kwargs else self.cppi
        state = model.initialize(value)
        self.active_insurance[portfolio_id] = state
        return state

    def get_protection_report(self, portfolio_value: float) -> dict[str, Any]:
        """Full protection analysis combining CPPI and OBPI."""
        cppi_state = self.cppi.initialize(portfolio_value)
        obpi_cost = self.obpi.protection_cost(portfolio_value)

        return {
            "portfolio_value": portfolio_value,
            "cppi": {
                "floor": cppi_state.floor_value,
                "cushion": cppi_state.cushion,
                "risky_pct": cppi_state.risky_allocation / portfolio_value * 100,
                "safe_pct": cppi_state.safe_allocation / portfolio_value * 100,
            },
            "obpi": obpi_cost,
            "recommendation": (
                "CPPI" if obpi_cost["cost_pct"] > 3.0 else "OBPI"
            ),
        }
