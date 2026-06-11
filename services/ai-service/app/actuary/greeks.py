"""Expanded options Greeks engine for strategy and portfolio risk.

The module remains backwards compatible with the original implementation while
adding a substantially broader risk toolkit:

* Vanilla Black-Scholes Greeks with higher-order sensitivities.
* Charm, vanna, volga, speed, color, zomma, and ultima.
* Barrier, Asian, and digital option Greeks using stable approximations.
* Volatility surface interpolation plus local-vol, Heston-style, and SABR-style
  Greeks.
* Portfolio aggregation, stress testing, P&L attribution, pin-risk analysis,
  and practical hedge construction.
* Real-time incremental recalculation helpers and Greeks sensitivity ladders.

Only standard-library primitives are used so the engine can run in constrained
service environments without scientific dependencies.
"""

import math
from dataclasses import dataclass
from enum import Enum
from typing import Any, Callable, Mapping, Sequence

_EPSILON = 1e-12
_ONE_DAY = 1.0 / 365.0
_ONE_PERCENT = 0.01


def _norm_cdf(x: float) -> float:
    """Return the standard normal cumulative distribution value."""
    return 0.5 * (1.0 + math.erf(x / math.sqrt(2.0)))


def _norm_pdf(x: float) -> float:
    """Return the standard normal probability density."""
    return math.exp(-0.5 * x * x) / math.sqrt(2.0 * math.pi)


def _clamp(value: float, low: float, high: float) -> float:
    """Clamp a numeric value into the closed interval ``[low, high]``."""
    return max(low, min(high, value))


def _positive(value: float, floor: float = _EPSILON) -> float:
    """Return a strictly positive value suitable for logs and divisions."""
    return max(value, floor)


def _sign(value: float) -> float:
    """Return the sign of ``value`` with ``0.0`` preserved."""
    if value > 0.0:
        return 1.0
    if value < 0.0:
        return -1.0
    return 0.0


def _central_first(func: Callable[[float], float], x: float, step: float) -> float:
    """Compute a first derivative using a central finite-difference stencil."""
    actual_step = max(abs(step), _EPSILON)
    return (func(x + actual_step) - func(x - actual_step)) / (2.0 * actual_step)


def _central_second(func: Callable[[float], float], x: float, step: float) -> float:
    """Compute a second derivative using a central finite-difference stencil."""
    actual_step = max(abs(step), _EPSILON)
    return (
        func(x + actual_step) - 2.0 * func(x) + func(x - actual_step)
    ) / (actual_step * actual_step)


def _central_cross(
    func: Callable[[float, float], float],
    x: float,
    y: float,
    step_x: float,
    step_y: float,
) -> float:
    """Compute a cross-partial derivative using a symmetric four-point stencil."""
    actual_step_x = max(abs(step_x), _EPSILON)
    actual_step_y = max(abs(step_y), _EPSILON)
    return (
        func(x + actual_step_x, y + actual_step_y)
        - func(x + actual_step_x, y - actual_step_y)
        - func(x - actual_step_x, y + actual_step_y)
        + func(x - actual_step_x, y - actual_step_y)
    ) / (4.0 * actual_step_x * actual_step_y)


def _central_third(func: Callable[[float], float], x: float, step: float) -> float:
    """Compute a third derivative with a five-point central approximation."""
    actual_step = max(abs(step), _EPSILON)
    return (
        func(x + 2.0 * actual_step)
        - 2.0 * func(x + actual_step)
        + 2.0 * func(x - actual_step)
        - func(x - 2.0 * actual_step)
    ) / (2.0 * actual_step**3)


def _time_decay(
    func: Callable[[float], float],
    tau: float,
    day_step: float = _ONE_DAY,
) -> float:
    """Return the change caused by one day of calendar time passing."""
    if tau <= 0.0:
        return 0.0
    actual_step = min(day_step, max(tau * 0.5, _EPSILON))
    return func(max(tau - actual_step, 0.0)) - func(tau)


def _moneyness_scale(spot: float, strike: float) -> float:
    """Return a bounded log-moneyness measure used in approximations."""
    return math.log(_positive(spot) / _positive(strike))


@dataclass(slots=True)
class GreeksResult:
    """Container for primary, higher-order, and portfolio-level Greek outputs."""

    delta: float
    gamma: float
    vega: float
    theta: float
    rho: float
    charm: float = 0.0
    vanna: float = 0.0
    volga: float = 0.0
    speed: float = 0.0
    color: float = 0.0
    ultima: float = 0.0
    zomma: float = 0.0
    cross_gamma: float = 0.0
    cega: float = 0.0
    dividend_sensitivity: float = 0.0
    dollar_gamma: float = 0.0
    gamma_scalping_pnl: float = 0.0
    theta_gamma_ratio: float = 0.0
    pin_risk: float = 0.0
    local_vol: float = 0.0
    price: float = 0.0
    model: str = "vanilla"

    def scaled(self, scale: float) -> "GreeksResult":
        """Return a quantity-scaled copy of the result."""
        return GreeksResult(
            delta=self.delta * scale,
            gamma=self.gamma * scale,
            vega=self.vega * scale,
            theta=self.theta * scale,
            rho=self.rho * scale,
            charm=self.charm * scale,
            vanna=self.vanna * scale,
            volga=self.volga * scale,
            speed=self.speed * scale,
            color=self.color * scale,
            ultima=self.ultima * scale,
            zomma=self.zomma * scale,
            cross_gamma=self.cross_gamma * scale,
            cega=self.cega * scale,
            dividend_sensitivity=self.dividend_sensitivity * scale,
            dollar_gamma=self.dollar_gamma * scale,
            gamma_scalping_pnl=self.gamma_scalping_pnl * scale,
            theta_gamma_ratio=self.theta_gamma_ratio,
            pin_risk=self.pin_risk * scale,
            local_vol=self.local_vol,
            price=self.price * scale,
            model=self.model,
        )

    def add(self, other: "GreeksResult") -> "GreeksResult":
        """Return the sum of two Greek vectors."""
        return GreeksResult(
            delta=self.delta + other.delta,
            gamma=self.gamma + other.gamma,
            vega=self.vega + other.vega,
            theta=self.theta + other.theta,
            rho=self.rho + other.rho,
            charm=self.charm + other.charm,
            vanna=self.vanna + other.vanna,
            volga=self.volga + other.volga,
            speed=self.speed + other.speed,
            color=self.color + other.color,
            ultima=self.ultima + other.ultima,
            zomma=self.zomma + other.zomma,
            cross_gamma=self.cross_gamma + other.cross_gamma,
            cega=self.cega + other.cega,
            dividend_sensitivity=self.dividend_sensitivity + other.dividend_sensitivity,
            dollar_gamma=self.dollar_gamma + other.dollar_gamma,
            gamma_scalping_pnl=self.gamma_scalping_pnl + other.gamma_scalping_pnl,
            theta_gamma_ratio=0.0,
            pin_risk=self.pin_risk + other.pin_risk,
            local_vol=self.local_vol or other.local_vol,
            price=self.price + other.price,
            model=self.model,
        )

    def to_dict(self) -> dict[str, float | str]:
        """Convert the result into a JSON-serialisable mapping."""
        return {
            "delta": self.delta,
            "gamma": self.gamma,
            "vega": self.vega,
            "theta": self.theta,
            "rho": self.rho,
            "charm": self.charm,
            "vanna": self.vanna,
            "volga": self.volga,
            "speed": self.speed,
            "color": self.color,
            "ultima": self.ultima,
            "zomma": self.zomma,
            "cross_gamma": self.cross_gamma,
            "cega": self.cega,
            "dividend_sensitivity": self.dividend_sensitivity,
            "dollar_gamma": self.dollar_gamma,
            "gamma_scalping_pnl": self.gamma_scalping_pnl,
            "theta_gamma_ratio": self.theta_gamma_ratio,
            "pin_risk": self.pin_risk,
            "local_vol": self.local_vol,
            "price": self.price,
            "model": self.model,
        }


@dataclass(slots=True)
class OptionContract:
    """Normalised option description used across analytical and heuristic models."""

    spot: float
    strike: float
    time_to_expiry: float
    risk_free_rate: float
    volatility: float
    is_call: bool = True
    dividend_yield: float = 0.0


class BarrierType(Enum):
    """Supported barrier structures for the barrier Greek approximator."""

    UP_AND_OUT = "up-and-out"
    DOWN_AND_IN = "down-and-in"


@dataclass(slots=True)
class BarrierSpecification:
    """Configuration for a simple single-barrier option."""

    barrier: float
    barrier_type: BarrierType = BarrierType.UP_AND_OUT
    rebate: float = 0.0


@dataclass(slots=True)
class VolatilityPoint:
    """A strike-expiry node on an implied-volatility surface."""

    strike: float
    expiry: float
    volatility: float


@dataclass(slots=True)
class HestonParameters:
    """Compact Heston parameter bundle used for effective-vol approximations."""

    kappa: float
    theta: float
    xi: float
    rho: float
    v0: float


@dataclass(slots=True)
class SABRParameters:
    """SABR model parameters used in Hagan-style implied-vol calculations."""

    alpha: float
    beta: float
    rho: float
    nu: float


@dataclass(slots=True)
class StressScenario:
    """Relative or absolute shocks used by scenario-analysis helpers."""

    name: str
    spot_shock: float = 0.0
    vol_shock: float = 0.0
    rate_shock: float = 0.0
    dividend_shock: float = 0.0
    elapsed_days: float = 0.0


@dataclass(slots=True)
class HedgeInstrument:
    """Greek profile of a liquid hedge instrument used in portfolio neutralisation."""

    name: str
    delta: float = 0.0
    gamma: float = 0.0
    vega: float = 0.0
    theta: float = 0.0
    price: float = 0.0


@dataclass(slots=True)
class CacheEntry:
    """Cached Greek vector with lightweight metadata for refresh decisions."""

    key: tuple[Any, ...]
    result: GreeksResult
    hits: int = 0


class DeltaModel:
    """Delta — first-order sensitivity of value to spot price changes."""

    def calculate(
        self,
        spot: float,
        strike: float,
        tau: float,
        r: float,
        sigma: float,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> float:
        contract = OptionContract(spot, strike, tau, r, sigma, is_call, dividend_yield)
        if tau <= 0.0 or sigma <= 0.0:
            intrinsic_sign = 1.0 if is_call else -1.0
            if is_call:
                return intrinsic_sign if spot > strike else 0.0
            return intrinsic_sign if spot < strike else 0.0
        d1, _ = _black_scholes_d1_d2(contract)
        discount = math.exp(-dividend_yield * tau)
        if is_call:
            return discount * _norm_cdf(d1)
        return discount * (_norm_cdf(d1) - 1.0)


class GammaModel:
    """Gamma — convexity of option value with respect to the underlying price."""

    def calculate(
        self,
        spot: float,
        strike: float,
        tau: float,
        r: float,
        sigma: float,
        dividend_yield: float = 0.0,
    ) -> float:
        if tau <= 0.0 or sigma <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return 0.0
        contract = OptionContract(spot, strike, tau, r, sigma, True, dividend_yield)
        d1, _ = _black_scholes_d1_d2(contract)
        return (
            math.exp(-dividend_yield * tau)
            * _norm_pdf(d1)
            / (_positive(spot) * sigma * math.sqrt(tau))
        )


class VegaModel:
    """Vega — sensitivity to a one-percentage-point move in implied volatility."""

    def calculate(
        self,
        spot: float,
        strike: float,
        tau: float,
        r: float,
        sigma: float,
        dividend_yield: float = 0.0,
    ) -> float:
        if tau <= 0.0 or sigma <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return 0.0
        contract = OptionContract(spot, strike, tau, r, sigma, True, dividend_yield)
        d1, _ = _black_scholes_d1_d2(contract)
        return spot * math.exp(-dividend_yield * tau) * _norm_pdf(d1) * math.sqrt(tau) * _ONE_PERCENT


class ThetaModel:
    """Theta — daily value decay from one day of calendar time passing."""

    def calculate(
        self,
        spot: float,
        strike: float,
        tau: float,
        r: float,
        sigma: float,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> float:
        if tau <= 0.0 or sigma <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return 0.0
        contract = OptionContract(spot, strike, tau, r, sigma, is_call, dividend_yield)
        d1, d2 = _black_scholes_d1_d2(contract)
        front = -(
            spot
            * math.exp(-dividend_yield * tau)
            * _norm_pdf(d1)
            * sigma
            / (2.0 * math.sqrt(tau))
        )
        if is_call:
            carry = dividend_yield * spot * math.exp(-dividend_yield * tau) * _norm_cdf(d1)
            financing = -r * strike * math.exp(-r * tau) * _norm_cdf(d2)
        else:
            carry = -dividend_yield * spot * math.exp(-dividend_yield * tau) * _norm_cdf(-d1)
            financing = r * strike * math.exp(-r * tau) * _norm_cdf(-d2)
        return (front + carry + financing) / 365.0


class RhoModel:
    """Rho — sensitivity to a one-percentage-point move in the risk-free rate."""

    def calculate(
        self,
        spot: float,
        strike: float,
        tau: float,
        r: float,
        sigma: float,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> float:
        if tau <= 0.0 or sigma <= 0.0 or spot <= 0.0 or strike <= 0.0:
            return 0.0
        contract = OptionContract(spot, strike, tau, r, sigma, is_call, dividend_yield)
        _, d2 = _black_scholes_d1_d2(contract)
        discount = strike * tau * math.exp(-r * tau) * _ONE_PERCENT
        if is_call:
            return discount * _norm_cdf(d2)
        return -discount * _norm_cdf(-d2)


class CharmModel:
    """Charm — daily delta decay as expiry approaches."""

    def __init__(self, delta_model: DeltaModel) -> None:
        self.delta_model = delta_model

    def calculate(self, contract: OptionContract) -> float:
        if contract.time_to_expiry <= 0.0:
            return 0.0

        def delta_at(tau: float) -> float:
            return self.delta_model.calculate(
                contract.spot,
                contract.strike,
                tau,
                contract.risk_free_rate,
                contract.volatility,
                contract.is_call,
                contract.dividend_yield,
            )

        return _time_decay(delta_at, contract.time_to_expiry)


class VannaModel:
    """Vanna — delta sensitivity to volatility and cross spot/vol curvature."""

    def calculate(self, pricer: Callable[[OptionContract], float], contract: OptionContract) -> float:
        spot_step = max(contract.spot * 0.01, 0.01)
        vol_step = max(contract.volatility * 0.05, 0.0005)

        def price_at(spot: float, sigma: float) -> float:
            shifted = OptionContract(
                spot=spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=max(sigma, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        return _central_cross(price_at, contract.spot, contract.volatility, spot_step, vol_step) * _ONE_PERCENT


class VolgaModel:
    """Volga — convexity of value to volatility moves."""

    def calculate(self, pricer: Callable[[OptionContract], float], contract: OptionContract) -> float:
        vol_step = max(contract.volatility * 0.05, 0.0005)

        def value(sigma: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=max(sigma, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        return _central_second(value, contract.volatility, vol_step) * (_ONE_PERCENT**2)


class HigherOrderGreeksModel:
    """Higher-order Greek estimators built from stable finite-difference schemes."""

    def calculate_speed(self, gamma_func: Callable[[float], float], spot: float, step: float) -> float:
        return _central_first(gamma_func, spot, step)

    def calculate_color(self, gamma_func: Callable[[float], float], tau: float) -> float:
        return _time_decay(gamma_func, tau)

    def calculate_zomma(self, gamma_sigma_func: Callable[[float], float], sigma: float, step: float) -> float:
        return _central_first(gamma_sigma_func, sigma, step) * _ONE_PERCENT

    def calculate_ultima(self, volga_sigma_func: Callable[[float], float], sigma: float, step: float) -> float:
        return _central_first(volga_sigma_func, sigma, step) * _ONE_PERCENT


class VanillaOptionPricer:
    """Black-Scholes vanilla pricer supporting continuous dividend yield."""

    def price(self, contract: OptionContract) -> float:
        return _black_scholes_price(contract)


class DigitalOptionPricer:
    """Cash-or-nothing digital pricer under Black-Scholes assumptions."""

    def price(self, contract: OptionContract, payout: float = 1.0) -> float:
        if contract.time_to_expiry <= 0.0 or contract.volatility <= 0.0:
            if contract.is_call:
                return payout if contract.spot > contract.strike else 0.0
            return payout if contract.spot < contract.strike else 0.0
        _, d2 = _black_scholes_d1_d2(contract)
        discount = math.exp(-contract.risk_free_rate * contract.time_to_expiry)
        if contract.is_call:
            return payout * discount * _norm_cdf(d2)
        return payout * discount * _norm_cdf(-d2)


class AsianOptionPricer:
    """Geometric-average Asian proxy with arithmetic-style volatility damping."""

    def price(self, contract: OptionContract) -> float:
        if contract.time_to_expiry <= 0.0:
            intrinsic = max(contract.spot - contract.strike, 0.0)
            if not contract.is_call:
                intrinsic = max(contract.strike - contract.spot, 0.0)
            return intrinsic

        effective_tau = max(contract.time_to_expiry, _ONE_DAY)
        carry = contract.risk_free_rate - contract.dividend_yield
        if abs(carry) < _EPSILON:
            average_spot = contract.spot
        else:
            average_spot = contract.spot * (math.exp(carry * effective_tau) - 1.0) / (carry * effective_tau)
        adjusted = OptionContract(
            spot=max(average_spot, 0.01),
            strike=contract.strike,
            time_to_expiry=effective_tau,
            risk_free_rate=contract.risk_free_rate,
            volatility=max(contract.volatility / math.sqrt(3.0), 0.0001),
            is_call=contract.is_call,
            dividend_yield=contract.dividend_yield,
        )
        return _black_scholes_price(adjusted)


class BarrierOptionPricer:
    """Single-barrier heuristic pricer for monitoring barrier Greek behaviour.

    The implementation is intentionally lightweight. It blends a vanilla price
    with a barrier hit probability derived from a drift-adjusted normal bridge.
    This makes it suitable for risk dashboards and scenario analysis where a
    stable and dependency-free approximation is preferable to a full lattice.
    """

    def price(self, contract: OptionContract, specification: BarrierSpecification) -> float:
        vanilla = _black_scholes_price(contract)
        hit_probability = self._barrier_hit_probability(contract, specification.barrier)
        rebate_pv = specification.rebate * math.exp(-contract.risk_free_rate * contract.time_to_expiry)
        if specification.barrier_type is BarrierType.UP_AND_OUT:
            if contract.spot >= specification.barrier:
                return rebate_pv
            survival = 1.0 - hit_probability
            return vanilla * survival + rebate_pv * hit_probability
        if contract.spot <= specification.barrier:
            return vanilla + rebate_pv
        return vanilla * hit_probability + rebate_pv * (1.0 - hit_probability)

    def _barrier_hit_probability(self, contract: OptionContract, barrier: float) -> float:
        if contract.time_to_expiry <= 0.0 or contract.volatility <= 0.0:
            return 0.0
        sigma_root_t = contract.volatility * math.sqrt(contract.time_to_expiry)
        drift = contract.risk_free_rate - contract.dividend_yield - 0.5 * contract.volatility**2
        bridge_z = (math.log(_positive(barrier) / _positive(contract.spot)) - drift * contract.time_to_expiry) / _positive(sigma_root_t)
        if barrier >= contract.spot:
            return _clamp(1.0 - _norm_cdf(bridge_z), 0.0, 1.0)
        return _clamp(_norm_cdf(bridge_z), 0.0, 1.0)


class VolatilitySurfaceEngine:
    """Interpolation and model-adjusted volatility helpers.

    The engine supports direct smile interpolation, a Dupire-style local-vol
    proxy, SABR implied volatilities, and a compact Heston effective-volatility
    approximation that is stable enough for scenario analysis and real-time
    dashboards.
    """

    def interpolate_smile(
        self,
        strike: float,
        expiry: float,
        surface: Sequence[VolatilityPoint],
    ) -> float:
        if not surface:
            return 0.20
        weighted_sum = 0.0
        total_weight = 0.0
        for point in surface:
            distance = abs(point.strike - strike) / _positive(strike) + abs(point.expiry - expiry)
            weight = 1.0 / max(distance, 0.01)
            weighted_sum += weight * point.volatility
            total_weight += weight
        return weighted_sum / _positive(total_weight)

    def local_vol(
        self,
        spot: float,
        strike: float,
        expiry: float,
        surface: Sequence[VolatilityPoint],
    ) -> float:
        base = self.interpolate_smile(strike, expiry, surface)
        nearby = [p for p in surface if abs(p.expiry - expiry) <= max(expiry * 0.25, 0.25)]
        if len(nearby) < 2:
            return max(base, 0.0001)
        sorted_nearby = sorted(nearby, key=lambda point: point.strike)
        left = sorted_nearby[0]
        right = sorted_nearby[-1]
        if len(sorted_nearby) > 2:
            for index, point in enumerate(sorted_nearby[:-1]):
                next_point = sorted_nearby[index + 1]
                if point.strike <= strike <= next_point.strike:
                    left = point
                    right = next_point
                    break
        skew = (right.volatility - left.volatility) / _positive(right.strike - left.strike)
        curvature = 0.5 * (right.volatility + left.volatility) - base
        moneyness = _moneyness_scale(spot, strike)
        adjusted = base + skew * (spot - strike) * 0.5 + curvature * moneyness * moneyness
        return max(adjusted, 0.0001)

    def heston_effective_vol(
        self,
        contract: OptionContract,
        parameters: HestonParameters,
    ) -> float:
        tau = max(contract.time_to_expiry, _ONE_DAY)
        expected_variance = (
            parameters.theta
            + (parameters.v0 - parameters.theta) * math.exp(-parameters.kappa * tau)
            + 0.25 * parameters.xi * parameters.xi * tau
        )
        skew_adjustment = 1.0 - 0.35 * parameters.rho * _moneyness_scale(contract.spot, contract.strike)
        return max(math.sqrt(_positive(expected_variance)) * max(skew_adjustment, 0.5), 0.0001)

    def sabr_implied_vol(
        self,
        forward: float,
        strike: float,
        expiry: float,
        parameters: SABRParameters,
    ) -> float:
        if forward <= 0.0 or strike <= 0.0:
            return max(parameters.alpha, 0.0001)
        beta = _clamp(parameters.beta, 0.0, 1.0)
        if abs(forward - strike) < 1e-8:
            fk_beta = forward ** (1.0 - beta)
            term1 = parameters.alpha / _positive(fk_beta)
            term2 = (
                ((1.0 - beta) ** 2 / 24.0) * (parameters.alpha**2) / _positive(forward ** (2.0 - 2.0 * beta))
                + 0.25 * parameters.rho * beta * parameters.nu * parameters.alpha / _positive(forward ** (1.0 - beta))
                + (2.0 - 3.0 * parameters.rho**2) * parameters.nu**2 / 24.0
            ) * expiry
            return max(term1 * (1.0 + term2), 0.0001)

        log_fk = math.log(forward / strike)
        fk_beta = (forward * strike) ** ((1.0 - beta) / 2.0)
        z = parameters.nu * fk_beta * log_fk / _positive(parameters.alpha)
        x_z_numerator = math.sqrt(1.0 - 2.0 * parameters.rho * z + z * z) + z - parameters.rho
        x_z_denominator = 1.0 - parameters.rho
        x_z = math.log(_positive(x_z_numerator) / _positive(x_z_denominator))
        denominator = fk_beta * (
            1.0
            + ((1.0 - beta) ** 2 / 24.0) * log_fk * log_fk
            + ((1.0 - beta) ** 4 / 1920.0) * log_fk**4
        )
        correction = (
            ((1.0 - beta) ** 2 / 24.0) * parameters.alpha**2 / _positive((forward * strike) ** (1.0 - beta))
            + 0.25 * parameters.rho * beta * parameters.nu * parameters.alpha / _positive((forward * strike) ** ((1.0 - beta) / 2.0))
            + (2.0 - 3.0 * parameters.rho**2) * parameters.nu**2 / 24.0
        ) * expiry
        implied = parameters.alpha * z / _positive(x_z) / _positive(denominator) * (1.0 + correction)
        return max(implied, 0.0001)


class PortfolioRiskEngine:
    """Aggregation and portfolio-level secondary Greek analytics."""

    def aggregate(self, contributions: Sequence[GreeksResult]) -> GreeksResult:
        total = GreeksResult(0.0, 0.0, 0.0, 0.0, 0.0)
        for item in contributions:
            total = total.add(item)
        if abs(total.gamma) > _EPSILON:
            total.theta_gamma_ratio = total.theta / (abs(total.gamma) + _EPSILON)
        return total

    def dollar_gamma(self, spot: float, gamma: float) -> float:
        return gamma * spot * spot * _ONE_PERCENT

    def gamma_scalping_pnl(self, spot: float, gamma: float, realized_move: float, theta: float = 0.0) -> float:
        dollar_move = realized_move * spot
        return 0.5 * gamma * dollar_move * dollar_move + theta

    def theta_gamma_ratio(self, theta: float, gamma: float, spot: float) -> float:
        denominator = max(abs(gamma) * max(spot * spot, 1.0), _EPSILON)
        return theta / denominator

    def vega_weighted_analysis(
        self,
        positions: Sequence[Mapping[str, Any]],
        calculator: Callable[[Mapping[str, Any]], GreeksResult],
    ) -> dict[str, Any]:
        results: list[dict[str, Any]] = []
        total_abs_vega = 0.0
        for position in positions:
            greeks = calculator(position)
            total_abs_vega += abs(greeks.vega)
            results.append(
                {
                    "name": position.get("name", position.get("symbol", "position")),
                    "vega": greeks.vega,
                    "volga": greeks.volga,
                    "local_vol": greeks.local_vol,
                }
            )
        for item in results:
            item["vega_weight"] = item["vega"] / _positive(total_abs_vega)
        dominant = max(results, key=lambda item: abs(float(item["vega"])), default=None)
        return {
            "total_abs_vega": total_abs_vega,
            "dominant_vega": dominant,
            "positions": results,
        }


class ScenarioAnalysisEngine:
    """Stress testing and Greek-based P&L attribution tools."""

    def run(
        self,
        contract: OptionContract,
        scenarios: Sequence[StressScenario],
        calculator: Callable[[OptionContract], GreeksResult],
    ) -> list[dict[str, Any]]:
        base = calculator(contract)
        outputs: list[dict[str, Any]] = []
        for scenario in scenarios:
            shocked = OptionContract(
                spot=max(contract.spot * (1.0 + scenario.spot_shock), 0.01),
                strike=contract.strike,
                time_to_expiry=max(contract.time_to_expiry - scenario.elapsed_days * _ONE_DAY, 0.0),
                risk_free_rate=contract.risk_free_rate + scenario.rate_shock,
                volatility=max(contract.volatility + scenario.vol_shock, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield + scenario.dividend_shock,
            )
            shocked_result = calculator(shocked)
            outputs.append(
                {
                    "name": scenario.name,
                    "spot": shocked.spot,
                    "volatility": shocked.volatility,
                    "rate": shocked.risk_free_rate,
                    "delta": shocked_result.delta,
                    "gamma": shocked_result.gamma,
                    "vega": shocked_result.vega,
                    "theta": shocked_result.theta,
                    "rho": shocked_result.rho,
                    "price_change": shocked_result.price - base.price,
                }
            )
        return outputs

    def pnl_attribution(
        self,
        greeks: GreeksResult,
        spot_change: float,
        vol_change: float,
        rate_change: float,
        elapsed_days: float,
        dividend_change: float = 0.0,
        cross_move: float = 0.0,
        correlation_change: float = 0.0,
    ) -> dict[str, float]:
        delta_pnl = greeks.delta * spot_change
        gamma_pnl = 0.5 * greeks.gamma * spot_change * spot_change
        vega_pnl = greeks.vega * (vol_change / _ONE_PERCENT)
        volga_pnl = 0.5 * greeks.volga * (vol_change / _ONE_PERCENT) ** 2
        vanna_pnl = greeks.vanna * spot_change * (vol_change / _ONE_PERCENT)
        theta_pnl = greeks.theta * elapsed_days
        rho_pnl = greeks.rho * (rate_change / _ONE_PERCENT)
        dividend_pnl = greeks.dividend_sensitivity * (dividend_change / _ONE_PERCENT)
        cross_gamma_pnl = 0.5 * greeks.cross_gamma * cross_move * cross_move
        cega_pnl = greeks.cega * correlation_change
        total = (
            delta_pnl
            + gamma_pnl
            + vega_pnl
            + volga_pnl
            + vanna_pnl
            + theta_pnl
            + rho_pnl
            + dividend_pnl
            + cross_gamma_pnl
            + cega_pnl
        )
        return {
            "delta": delta_pnl,
            "gamma": gamma_pnl,
            "vega": vega_pnl,
            "volga": volga_pnl,
            "vanna": vanna_pnl,
            "theta": theta_pnl,
            "rho": rho_pnl,
            "dividend": dividend_pnl,
            "cross_gamma": cross_gamma_pnl,
            "cega": cega_pnl,
            "total": total,
        }


class CrossGreeksEngine:
    """Cross-asset and non-price sensitivity approximations."""

    def cross_gamma(self, gamma_a: float, gamma_b: float, correlation: float) -> float:
        signed_scale = _sign(gamma_a) * _sign(gamma_b)
        return signed_scale * math.sqrt(abs(gamma_a * gamma_b)) * correlation

    def cega(self, total_vega: float, average_vol_of_vol: float, correlation: float) -> float:
        return total_vega * average_vol_of_vol * correlation

    def dividend_sensitivity(
        self,
        contract: OptionContract,
        pricer: Callable[[OptionContract], float],
    ) -> float:
        step = 0.0025

        def value(dividend_yield: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=max(dividend_yield, -0.50),
            )
            return pricer(shifted)

        return _central_first(value, contract.dividend_yield, step) * _ONE_PERCENT


class PinRiskAnalyzer:
    """Near-expiry diagnostics for strike pinning and gamma blow-up behaviour."""

    def pin_risk_quantification(
        self,
        contract: OptionContract,
        gamma: float,
        position_size: float = 1.0,
    ) -> float:
        time_factor = 1.0 / max(math.sqrt(max(contract.time_to_expiry, _ONE_DAY)), 1.0)
        proximity = math.exp(-abs(contract.spot - contract.strike) / max(contract.spot * 0.02, 0.01))
        return abs(gamma) * position_size * proximity * time_factor * contract.spot

    def gamma_explosion(self, contract: OptionContract, gamma: float) -> dict[str, float]:
        distance = abs(contract.spot - contract.strike)
        normalized_distance = distance / max(contract.spot, 0.01)
        explosion = abs(gamma) / max(math.sqrt(max(contract.time_to_expiry, _ONE_DAY)), 0.1)
        return {
            "distance_to_strike": distance,
            "normalized_distance": normalized_distance,
            "gamma_explosion_score": explosion,
        }

    def near_expiry_profile(
        self,
        contract: OptionContract,
        calculator: Callable[[OptionContract], GreeksResult],
        days: Sequence[int] = (10, 5, 3, 2, 1),
    ) -> list[dict[str, float]]:
        profile: list[dict[str, float]] = []
        for day in days:
            tau = max(day * _ONE_DAY, 0.0)
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=tau,
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            greeks = calculator(shifted)
            profile.append(
                {
                    "days_to_expiry": float(day),
                    "delta": greeks.delta,
                    "gamma": greeks.gamma,
                    "theta": greeks.theta,
                    "pin_risk": self.pin_risk_quantification(shifted, greeks.gamma),
                }
            )
        return profile


class HedgingEngine:
    """Construct simple delta, gamma, and vega neutral hedge overlays."""

    def delta_neutral(self, target_delta: float, hedge_delta: float = 1.0) -> dict[str, float]:
        if abs(hedge_delta) <= _EPSILON:
            return {"units": 0.0, "residual_delta": target_delta}
        units = -target_delta / hedge_delta
        return {"units": units, "residual_delta": target_delta + units * hedge_delta}

    def gamma_neutral(
        self,
        target_delta: float,
        target_gamma: float,
        instruments: Sequence[HedgeInstrument],
    ) -> dict[str, Any]:
        best = next((item for item in instruments if abs(item.gamma) > _EPSILON), None)
        if best is None:
            return {
                "units": {},
                "residual_delta": target_delta,
                "residual_gamma": target_gamma,
            }
        units = -target_gamma / best.gamma
        residual_delta = target_delta + units * best.delta
        residual_gamma = target_gamma + units * best.gamma
        return {
            "units": {best.name: units},
            "residual_delta": residual_delta,
            "residual_gamma": residual_gamma,
        }

    def vega_hedge(self, target_vega: float, hedge_vega: float, instrument_name: str = "vol-future") -> dict[str, Any]:
        if abs(hedge_vega) <= _EPSILON:
            return {"units": {}, "residual_vega": target_vega}
        units = -target_vega / hedge_vega
        return {
            "units": {instrument_name: units},
            "residual_vega": target_vega + units * hedge_vega,
        }


class RealTimeGreeksEngine:
    """Cache, incremental refresh, and ladder generation helpers."""

    def __init__(self) -> None:
        self._cache: dict[tuple[Any, ...], CacheEntry] = {}

    def make_key(self, label: str, contract: OptionContract, extra: tuple[Any, ...] = ()) -> tuple[Any, ...]:
        return (
            label,
            round(contract.spot, 8),
            round(contract.strike, 8),
            round(contract.time_to_expiry, 8),
            round(contract.risk_free_rate, 8),
            round(contract.volatility, 8),
            contract.is_call,
            round(contract.dividend_yield, 8),
            *extra,
        )

    def get(self, key: tuple[Any, ...]) -> GreeksResult | None:
        entry = self._cache.get(key)
        if entry is None:
            return None
        entry.hits += 1
        return entry.result

    def put(self, key: tuple[Any, ...], result: GreeksResult) -> GreeksResult:
        self._cache[key] = CacheEntry(key=key, result=result)
        return result

    def invalidate(self, prefix: str | None = None) -> None:
        if prefix is None:
            self._cache.clear()
            return
        keys = [key for key in self._cache if key and key[0] == prefix]
        for key in keys:
            del self._cache[key]

    def incremental_recalculation(
        self,
        previous: GreeksResult,
        contract: OptionContract,
        updates: Mapping[str, float],
        full_recalc: Callable[[OptionContract], GreeksResult],
    ) -> dict[str, Any]:
        if not updates:
            return {"mode": "cached", "result": previous.to_dict()}

        small_spot_move = abs(updates.get("spot", 0.0)) <= contract.spot * 0.01
        small_vol_move = abs(updates.get("volatility", 0.0)) <= 0.02
        small_rate_move = abs(updates.get("risk_free_rate", 0.0)) <= 0.01
        small_time_move = abs(updates.get("elapsed_days", 0.0)) <= 1.0

        if small_spot_move and small_vol_move and small_rate_move and small_time_move:
            d_spot = updates.get("spot", 0.0)
            d_vol = updates.get("volatility", 0.0)
            d_rate = updates.get("risk_free_rate", 0.0)
            elapsed_days = updates.get("elapsed_days", 0.0)
            estimated_price = previous.price
            estimated_price += previous.delta * d_spot
            estimated_price += 0.5 * previous.gamma * d_spot * d_spot
            estimated_price += previous.vega * (d_vol / _ONE_PERCENT)
            estimated_price += previous.rho * (d_rate / _ONE_PERCENT)
            estimated_price += previous.theta * elapsed_days
            return {
                "mode": "incremental",
                "result": {
                    **previous.to_dict(),
                    "price": estimated_price,
                },
            }

        shifted = OptionContract(
            spot=max(contract.spot + updates.get("spot", 0.0), 0.01),
            strike=contract.strike,
            time_to_expiry=max(contract.time_to_expiry - updates.get("elapsed_days", 0.0) * _ONE_DAY, 0.0),
            risk_free_rate=contract.risk_free_rate + updates.get("risk_free_rate", 0.0),
            volatility=max(contract.volatility + updates.get("volatility", 0.0), 0.0001),
            is_call=contract.is_call,
            dividend_yield=contract.dividend_yield + updates.get("dividend_yield", 0.0),
        )
        return {"mode": "full", "result": full_recalc(shifted).to_dict()}

    def sensitivity_ladder(
        self,
        contract: OptionContract,
        calculator: Callable[[OptionContract], GreeksResult],
        spot_shifts: Sequence[float] = (-0.10, -0.05, -0.02, 0.0, 0.02, 0.05, 0.10),
        vol_shifts: Sequence[float] = (-0.05, -0.02, 0.0, 0.02, 0.05),
    ) -> dict[str, list[dict[str, float]]]:
        spot_ladder: list[dict[str, float]] = []
        for shift in spot_shifts:
            shifted = OptionContract(
                spot=max(contract.spot * (1.0 + shift), 0.01),
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            result = calculator(shifted)
            spot_ladder.append(
                {
                    "shift": shift,
                    "price": result.price,
                    "delta": result.delta,
                    "gamma": result.gamma,
                }
            )

        vol_ladder: list[dict[str, float]] = []
        for shift in vol_shifts:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=max(contract.volatility + shift, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            result = calculator(shifted)
            vol_ladder.append(
                {
                    "shift": shift,
                    "price": result.price,
                    "vega": result.vega,
                    "volga": result.volga,
                }
            )

        return {"spot": spot_ladder, "vol": vol_ladder}

    def stats(self) -> dict[str, float]:
        total_hits = sum(entry.hits for entry in self._cache.values())
        return {"entries": float(len(self._cache)), "hits": float(total_hits)}


def _black_scholes_d1_d2(contract: OptionContract) -> tuple[float, float]:
    """Return the Black-Scholes ``d1`` and ``d2`` terms for a contract."""
    tau = max(contract.time_to_expiry, _EPSILON)
    sigma = max(contract.volatility, _EPSILON)
    numerator = math.log(_positive(contract.spot) / _positive(contract.strike))
    numerator += (contract.risk_free_rate - contract.dividend_yield + 0.5 * sigma * sigma) * tau
    denominator = sigma * math.sqrt(tau)
    d1 = numerator / _positive(denominator)
    return d1, d1 - sigma * math.sqrt(tau)


def _black_scholes_price(contract: OptionContract) -> float:
    """Return Black-Scholes value with a continuous dividend yield."""
    if contract.time_to_expiry <= 0.0 or contract.volatility <= 0.0:
        intrinsic = max(contract.spot - contract.strike, 0.0)
        if not contract.is_call:
            intrinsic = max(contract.strike - contract.spot, 0.0)
        return intrinsic
    d1, d2 = _black_scholes_d1_d2(contract)
    discounted_spot = contract.spot * math.exp(-contract.dividend_yield * contract.time_to_expiry)
    discounted_strike = contract.strike * math.exp(-contract.risk_free_rate * contract.time_to_expiry)
    if contract.is_call:
        return discounted_spot * _norm_cdf(d1) - discounted_strike * _norm_cdf(d2)
    return discounted_strike * _norm_cdf(-d2) - discounted_spot * _norm_cdf(-d1)


class GreeksEngine:
    """Complete Greeks calculation and risk orchestration engine.

    The original public surface is preserved:

    * ``DeltaModel.calculate``
    * ``GammaModel.calculate``
    * ``VegaModel.calculate``
    * ``ThetaModel.calculate``
    * ``GreeksEngine.calculate_all``
    * ``GreeksEngine.portfolio_greeks``

    Additional helpers extend the module into a broader production-grade risk
    utility for option analytics, volatility modelling, hedging, and stress
    testing.
    """

    def __init__(self) -> None:
        self.delta_model = DeltaModel()
        self.gamma_model = GammaModel()
        self.vega_model = VegaModel()
        self.theta_model = ThetaModel()
        self.rho_model = RhoModel()
        self.charm_model = CharmModel(self.delta_model)
        self.vanna_model = VannaModel()
        self.volga_model = VolgaModel()
        self.higher_order_model = HigherOrderGreeksModel()
        self.vanilla_pricer = VanillaOptionPricer()
        self.digital_pricer = DigitalOptionPricer()
        self.asian_pricer = AsianOptionPricer()
        self.barrier_pricer = BarrierOptionPricer()
        self.surface_engine = VolatilitySurfaceEngine()
        self.portfolio_engine = PortfolioRiskEngine()
        self.scenario_engine = ScenarioAnalysisEngine()
        self.cross_engine = CrossGreeksEngine()
        self.pin_risk_analyzer = PinRiskAnalyzer()
        self.hedging_engine = HedgingEngine()
        self.real_time_engine = RealTimeGreeksEngine()

    def calculate_all(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
        use_cache: bool = False,
    ) -> GreeksResult:
        """Calculate a broad vanilla option Greek set.

        Args:
            spot: Current underlying price.
            strike: Option strike.
            time_to_expiry: Remaining life in years.
            risk_free_rate: Continuously-compounded funding rate.
            volatility: Implied volatility in decimal terms.
            is_call: ``True`` for calls, ``False`` for puts.
            dividend_yield: Continuous dividend yield.
            use_cache: When ``True``, reuse cached Greek vectors.
        """
        contract = OptionContract(
            spot=spot,
            strike=strike,
            time_to_expiry=time_to_expiry,
            risk_free_rate=risk_free_rate,
            volatility=volatility,
            is_call=is_call,
            dividend_yield=dividend_yield,
        )
        key = self.real_time_engine.make_key("vanilla", contract)
        if use_cache:
            cached = self.real_time_engine.get(key)
            if cached is not None:
                return cached
        result = self._compute_vanilla_result(contract)
        return self.real_time_engine.put(key, result) if use_cache else result

    def portfolio_greeks(self, positions: list[dict[str, Any]]) -> dict[str, float]:
        """Aggregate Greeks across a portfolio of positions.

        The original base fields are preserved while additional exposure metrics
        are appended for richer downstream use.
        """
        contributions: list[GreeksResult] = []

        def calculate_position(position: Mapping[str, Any]) -> GreeksResult:
            style = str(position.get("style", "vanilla")).lower()
            quantity = float(position.get("quantity", 1.0))
            contract = self._contract_from_mapping(position)
            if style == "digital":
                result = self.calculate_digital_greeks(
                    contract.spot,
                    contract.strike,
                    contract.time_to_expiry,
                    contract.risk_free_rate,
                    contract.volatility,
                    contract.is_call,
                    float(position.get("payout", 1.0)),
                    contract.dividend_yield,
                )
            elif style == "asian":
                result = self.calculate_asian_greeks(
                    contract.spot,
                    contract.strike,
                    contract.time_to_expiry,
                    contract.risk_free_rate,
                    contract.volatility,
                    contract.is_call,
                    contract.dividend_yield,
                )
            elif style == "barrier":
                barrier_type = self._parse_barrier_type(position.get("barrier_type", "up-and-out"))
                result = self.calculate_barrier_greeks(
                    contract.spot,
                    contract.strike,
                    contract.time_to_expiry,
                    float(position.get("barrier", contract.spot)),
                    barrier_type,
                    contract.risk_free_rate,
                    contract.volatility,
                    contract.is_call,
                    float(position.get("rebate", 0.0)),
                    contract.dividend_yield,
                )
            else:
                result = self.calculate_all(
                    contract.spot,
                    contract.strike,
                    contract.time_to_expiry,
                    contract.risk_free_rate,
                    contract.volatility,
                    contract.is_call,
                    contract.dividend_yield,
                )
            return result.scaled(quantity)

        for position in positions:
            contributions.append(calculate_position(position))

        total = self.portfolio_engine.aggregate(contributions)
        return {
            key: float(value)
            for key, value in total.to_dict().items()
            if isinstance(value, (int, float))
        }

    def calculate_digital_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        payout: float = 1.0,
        dividend_yield: float = 0.0,
        use_cache: bool = False,
    ) -> GreeksResult:
        """Calculate digital option Greeks using a cash-or-nothing payoff."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        key = self.real_time_engine.make_key("digital", contract, (round(payout, 8),))
        if use_cache:
            cached = self.real_time_engine.get(key)
            if cached is not None:
                return cached
        result = self._compute_from_pricer(
            contract,
            lambda current: self.digital_pricer.price(current, payout=payout),
            model="digital",
        )
        return self.real_time_engine.put(key, result) if use_cache else result

    def calculate_asian_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
        use_cache: bool = False,
    ) -> GreeksResult:
        """Calculate Greek approximations for an Asian option."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        key = self.real_time_engine.make_key("asian", contract)
        if use_cache:
            cached = self.real_time_engine.get(key)
            if cached is not None:
                return cached
        result = self._compute_from_pricer(contract, self.asian_pricer.price, model="asian")
        return self.real_time_engine.put(key, result) if use_cache else result

    def calculate_barrier_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        barrier: float,
        barrier_type: BarrierType | str = BarrierType.UP_AND_OUT,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        rebate: float = 0.0,
        dividend_yield: float = 0.0,
        use_cache: bool = False,
    ) -> GreeksResult:
        """Calculate barrier option Greeks for up-and-out and down-and-in styles."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        parsed_type = self._parse_barrier_type(barrier_type)
        specification = BarrierSpecification(barrier=barrier, barrier_type=parsed_type, rebate=rebate)
        key = self.real_time_engine.make_key(
            "barrier",
            contract,
            (round(barrier, 8), parsed_type.value, round(rebate, 8)),
        )
        if use_cache:
            cached = self.real_time_engine.get(key)
            if cached is not None:
                return cached
        result = self._compute_from_pricer(
            contract,
            lambda current: self.barrier_pricer.price(current, specification),
            model=f"barrier:{parsed_type.value}",
        )
        return self.real_time_engine.put(key, result) if use_cache else result

    def interpolate_vol_smile(
        self,
        strike: float,
        expiry: float,
        surface: Sequence[Mapping[str, float] | VolatilityPoint],
    ) -> float:
        """Interpolate an implied volatility from a sparse smile or surface."""
        points = self._surface_points(surface)
        return self.surface_engine.interpolate_smile(strike, expiry, points)

    def calculate_local_vol_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        surface: Sequence[Mapping[str, float] | VolatilityPoint],
        risk_free_rate: float = 0.05,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> GreeksResult:
        """Calculate Greeks using a local-volatility surface proxy."""
        points = self._surface_points(surface)
        local_vol = self.surface_engine.local_vol(spot, strike, time_to_expiry, points)
        result = self.calculate_all(
            spot,
            strike,
            time_to_expiry,
            risk_free_rate,
            local_vol,
            is_call,
            dividend_yield,
        )
        result.local_vol = local_vol
        result.model = "local-vol"
        return result

    def calculate_heston_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        parameters: HestonParameters,
        risk_free_rate: float = 0.05,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> GreeksResult:
        """Calculate Greeks under a Heston-style effective volatility."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, 0.20, is_call, dividend_yield)
        heston_vol = self.surface_engine.heston_effective_vol(contract, parameters)
        result = self.calculate_all(
            spot,
            strike,
            time_to_expiry,
            risk_free_rate,
            heston_vol,
            is_call,
            dividend_yield,
        )
        result.local_vol = heston_vol
        result.model = "heston"
        return result

    def calculate_sabr_greeks(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        parameters: SABRParameters,
        risk_free_rate: float = 0.05,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> GreeksResult:
        """Calculate Greeks using SABR-implied volatility from Hagan's formula."""
        forward = spot * math.exp((risk_free_rate - dividend_yield) * max(time_to_expiry, 0.0))
        sabr_vol = self.surface_engine.sabr_implied_vol(forward, strike, max(time_to_expiry, _ONE_DAY), parameters)
        result = self.calculate_all(
            spot,
            strike,
            time_to_expiry,
            risk_free_rate,
            sabr_vol,
            is_call,
            dividend_yield,
        )
        result.local_vol = sabr_vol
        result.model = "sabr"
        return result

    def portfolio_risk_report(self, positions: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
        """Return portfolio Greeks plus higher-level risk diagnostics."""
        aggregate = self.portfolio_greeks(list(positions))
        vega_weighted = self.portfolio_engine.vega_weighted_analysis(positions, self._greeks_from_position)
        return {
            "aggregate": aggregate,
            "vega_weighted": vega_weighted,
        }

    def scenario_analysis(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        scenarios: Sequence[StressScenario] | None = None,
        dividend_yield: float = 0.0,
    ) -> list[dict[str, Any]]:
        """Run shock scenarios across spot, volatility, rates, and carry."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        if scenarios is None:
            scenarios = (
                StressScenario("spot_down_10", spot_shock=-0.10),
                StressScenario("spot_up_10", spot_shock=0.10),
                StressScenario("vol_up_5pt", vol_shock=0.05),
                StressScenario("rate_up_100bp", rate_shock=0.01),
            )
        return self.scenario_engine.run(contract, scenarios, self._compute_vanilla_result)

    def greek_pnl_attribution(
        self,
        greeks: GreeksResult,
        spot_change: float,
        vol_change: float,
        rate_change: float,
        elapsed_days: float,
        dividend_change: float = 0.0,
        cross_move: float = 0.0,
        correlation_change: float = 0.0,
    ) -> dict[str, float]:
        """Attribute P&L to first- and higher-order Greeks."""
        return self.scenario_engine.pnl_attribution(
            greeks,
            spot_change,
            vol_change,
            rate_change,
            elapsed_days,
            dividend_change,
            cross_move,
            correlation_change,
        )

    def cross_gamma(self, gamma_a: float, gamma_b: float, correlation: float) -> float:
        """Approximate cross-gamma between two correlated option books."""
        return self.cross_engine.cross_gamma(gamma_a, gamma_b, correlation)

    def correlation_sensitivity(self, total_vega: float, average_vol_of_vol: float, correlation: float) -> float:
        """Approximate cega, the sensitivity to correlation changes."""
        return self.cross_engine.cega(total_vega, average_vol_of_vol, correlation)

    def dividend_sensitivity(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
    ) -> float:
        """Calculate price sensitivity to dividend-yield moves."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        return self.cross_engine.dividend_sensitivity(contract, self.vanilla_pricer.price)

    def pin_risk_analysis(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
        position_size: float = 1.0,
    ) -> dict[str, Any]:
        """Quantify near-expiry pinning and gamma explosion risk."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        greeks = self.calculate_all(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        return {
            "pin_risk": self.pin_risk_analyzer.pin_risk_quantification(contract, greeks.gamma, position_size),
            "gamma_explosion": self.pin_risk_analyzer.gamma_explosion(contract, greeks.gamma),
            "near_expiry_profile": self.pin_risk_analyzer.near_expiry_profile(contract, self._compute_vanilla_result),
        }

    def construct_delta_neutral_portfolio(self, target_delta: float, hedge_delta: float = 1.0) -> dict[str, float]:
        """Return the hedge size required for delta neutrality."""
        return self.hedging_engine.delta_neutral(target_delta, hedge_delta)

    def construct_gamma_neutral_portfolio(
        self,
        target_delta: float,
        target_gamma: float,
        instruments: Sequence[HedgeInstrument],
    ) -> dict[str, Any]:
        """Return a simple gamma-neutral hedge solution."""
        return self.hedging_engine.gamma_neutral(target_delta, target_gamma, instruments)

    def vega_hedge_with_vol_instruments(
        self,
        target_vega: float,
        hedge_vega: float,
        instrument_name: str = "variance-swap",
    ) -> dict[str, Any]:
        """Return hedge units needed to neutralise vega."""
        return self.hedging_engine.vega_hedge(target_vega, hedge_vega, instrument_name)

    def incremental_recalculation(
        self,
        previous: GreeksResult,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
        updates: Mapping[str, float] | None = None,
    ) -> dict[str, Any]:
        """Refresh Greeks incrementally when market updates are small."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        return self.real_time_engine.incremental_recalculation(
            previous,
            contract,
            updates or {},
            self._compute_vanilla_result,
        )

    def sensitivity_ladder(
        self,
        spot: float,
        strike: float,
        time_to_expiry: float,
        risk_free_rate: float = 0.05,
        volatility: float = 0.20,
        is_call: bool = True,
        dividend_yield: float = 0.0,
        spot_shifts: Sequence[float] = (-0.10, -0.05, -0.02, 0.0, 0.02, 0.05, 0.10),
        vol_shifts: Sequence[float] = (-0.05, -0.02, 0.0, 0.02, 0.05),
    ) -> dict[str, list[dict[str, float]]]:
        """Generate spot and volatility ladders for live risk monitoring."""
        contract = OptionContract(spot, strike, time_to_expiry, risk_free_rate, volatility, is_call, dividend_yield)
        return self.real_time_engine.sensitivity_ladder(contract, self._compute_vanilla_result, spot_shifts, vol_shifts)

    def cache_stats(self) -> dict[str, float]:
        """Return cache occupancy and hit statistics."""
        return self.real_time_engine.stats()

    def _compute_vanilla_result(self, contract: OptionContract) -> GreeksResult:
        price = self.vanilla_pricer.price(contract)
        delta = self.delta_model.calculate(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.is_call,
            contract.dividend_yield,
        )
        gamma = self.gamma_model.calculate(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.dividend_yield,
        )
        vega = self.vega_model.calculate(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.dividend_yield,
        )
        theta = self.theta_model.calculate(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.is_call,
            contract.dividend_yield,
        )
        rho = self.rho_model.calculate(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.is_call,
            contract.dividend_yield,
        )
        charm = self.charm_model.calculate(contract)
        vanna = self.vanna_model.calculate(self.vanilla_pricer.price, contract)
        volga = self.volga_model.calculate(self.vanilla_pricer.price, contract)

        spot_step = max(contract.spot * 0.01, 0.01)
        vol_step = max(contract.volatility * 0.05, 0.0005)

        def gamma_at_spot(spot_value: float) -> float:
            return self.gamma_model.calculate(
                spot_value,
                contract.strike,
                contract.time_to_expiry,
                contract.risk_free_rate,
                contract.volatility,
                contract.dividend_yield,
            )

        def gamma_at_tau(tau_value: float) -> float:
            return self.gamma_model.calculate(
                contract.spot,
                contract.strike,
                tau_value,
                contract.risk_free_rate,
                contract.volatility,
                contract.dividend_yield,
            )

        def gamma_at_sigma(sigma_value: float) -> float:
            return self.gamma_model.calculate(
                contract.spot,
                contract.strike,
                contract.time_to_expiry,
                contract.risk_free_rate,
                max(sigma_value, 0.0001),
                contract.dividend_yield,
            )

        def volga_at_sigma(sigma_value: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=max(sigma_value, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return self.volga_model.calculate(self.vanilla_pricer.price, shifted)

        speed = self.higher_order_model.calculate_speed(gamma_at_spot, contract.spot, spot_step)
        color = self.higher_order_model.calculate_color(gamma_at_tau, contract.time_to_expiry)
        zomma = self.higher_order_model.calculate_zomma(gamma_at_sigma, contract.volatility, vol_step)
        ultima = self.higher_order_model.calculate_ultima(volga_at_sigma, contract.volatility, vol_step)
        dividend_sensitivity = self.cross_engine.dividend_sensitivity(contract, self.vanilla_pricer.price)
        dollar_gamma = self.portfolio_engine.dollar_gamma(contract.spot, gamma)
        gamma_scalping = self.portfolio_engine.gamma_scalping_pnl(contract.spot, gamma, 0.01, theta)
        theta_gamma_ratio = self.portfolio_engine.theta_gamma_ratio(theta, gamma, contract.spot)
        pin_risk = self.pin_risk_analyzer.pin_risk_quantification(contract, gamma)
        cega = self.cross_engine.cega(vega, max(contract.volatility * 0.5, 0.05), 0.25)
        return GreeksResult(
            delta=delta,
            gamma=gamma,
            vega=vega,
            theta=theta,
            rho=rho,
            charm=charm,
            vanna=vanna,
            volga=volga,
            speed=speed,
            color=color,
            ultima=ultima,
            zomma=zomma,
            cross_gamma=0.0,
            cega=cega,
            dividend_sensitivity=dividend_sensitivity,
            dollar_gamma=dollar_gamma,
            gamma_scalping_pnl=gamma_scalping,
            theta_gamma_ratio=theta_gamma_ratio,
            pin_risk=pin_risk,
            local_vol=contract.volatility,
            price=price,
            model="vanilla",
        )

    def _compute_from_pricer(
        self,
        contract: OptionContract,
        pricer: Callable[[OptionContract], float],
        model: str,
    ) -> GreeksResult:
        price = pricer(contract)
        spot_step = max(contract.spot * 0.01, 0.01)
        vol_step = max(contract.volatility * 0.05, 0.0005)
        rate_step = 0.0025

        def price_spot(spot_value: float) -> float:
            shifted = OptionContract(
                spot=max(spot_value, 0.01),
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        def price_vol(vol_value: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=contract.risk_free_rate,
                volatility=max(vol_value, 0.0001),
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        def price_rate(rate_value: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=contract.time_to_expiry,
                risk_free_rate=rate_value,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        def price_time(tau_value: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=max(tau_value, 0.0),
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            return pricer(shifted)

        delta = _central_first(price_spot, contract.spot, spot_step)
        gamma = _central_second(price_spot, contract.spot, spot_step)
        vega = _central_first(price_vol, contract.volatility, vol_step) * _ONE_PERCENT
        theta = _time_decay(price_time, contract.time_to_expiry)
        rho = _central_first(price_rate, contract.risk_free_rate, rate_step) * _ONE_PERCENT
        vanna = _central_cross(
            lambda spot_value, vol_value: pricer(
                OptionContract(
                    spot=max(spot_value, 0.01),
                    strike=contract.strike,
                    time_to_expiry=contract.time_to_expiry,
                    risk_free_rate=contract.risk_free_rate,
                    volatility=max(vol_value, 0.0001),
                    is_call=contract.is_call,
                    dividend_yield=contract.dividend_yield,
                )
            ),
            contract.spot,
            contract.volatility,
            spot_step,
            vol_step,
        ) * _ONE_PERCENT
        volga = _central_second(price_vol, contract.volatility, vol_step) * (_ONE_PERCENT**2)

        def delta_time(tau_value: float) -> float:
            shifted = OptionContract(
                spot=contract.spot,
                strike=contract.strike,
                time_to_expiry=max(tau_value, 0.0),
                risk_free_rate=contract.risk_free_rate,
                volatility=contract.volatility,
                is_call=contract.is_call,
                dividend_yield=contract.dividend_yield,
            )
            tau_spot_step = max(shifted.spot * 0.01, 0.01)

            def local_price(spot_value: float) -> float:
                inner = OptionContract(
                    spot=max(spot_value, 0.01),
                    strike=shifted.strike,
                    time_to_expiry=shifted.time_to_expiry,
                    risk_free_rate=shifted.risk_free_rate,
                    volatility=shifted.volatility,
                    is_call=shifted.is_call,
                    dividend_yield=shifted.dividend_yield,
                )
                return pricer(inner)

            return _central_first(local_price, shifted.spot, tau_spot_step)

        charm = _time_decay(delta_time, contract.time_to_expiry)
        speed = _central_first(
            lambda spot_value: _central_second(price_spot, spot_value, spot_step),
            contract.spot,
            spot_step,
        )
        color = _time_decay(
            lambda tau_value: _central_second(
                lambda spot_value: pricer(
                    OptionContract(
                        spot=max(spot_value, 0.01),
                        strike=contract.strike,
                        time_to_expiry=max(tau_value, 0.0),
                        risk_free_rate=contract.risk_free_rate,
                        volatility=contract.volatility,
                        is_call=contract.is_call,
                        dividend_yield=contract.dividend_yield,
                    )
                ),
                contract.spot,
                spot_step,
            ),
            contract.time_to_expiry,
        )

        def gamma_from_sigma(sigma_value: float) -> float:
            return _central_second(
                lambda spot_value: pricer(
                    OptionContract(
                        spot=max(spot_value, 0.01),
                        strike=contract.strike,
                        time_to_expiry=contract.time_to_expiry,
                        risk_free_rate=contract.risk_free_rate,
                        volatility=max(sigma_value, 0.0001),
                        is_call=contract.is_call,
                        dividend_yield=contract.dividend_yield,
                    )
                ),
                contract.spot,
                spot_step,
            )

        zomma = _central_first(gamma_from_sigma, contract.volatility, vol_step) * _ONE_PERCENT
        ultima = _central_third(price_vol, contract.volatility, vol_step) * (_ONE_PERCENT**3)
        dividend_sensitivity = self.cross_engine.dividend_sensitivity(contract, pricer)
        dollar_gamma = self.portfolio_engine.dollar_gamma(contract.spot, gamma)
        gamma_scalping = self.portfolio_engine.gamma_scalping_pnl(contract.spot, gamma, 0.01, theta)
        theta_gamma_ratio = self.portfolio_engine.theta_gamma_ratio(theta, gamma, contract.spot)
        pin_risk = self.pin_risk_analyzer.pin_risk_quantification(contract, gamma)
        cega = self.cross_engine.cega(vega, max(contract.volatility * 0.5, 0.05), 0.25)
        return GreeksResult(
            delta=delta,
            gamma=gamma,
            vega=vega,
            theta=theta,
            rho=rho,
            charm=charm,
            vanna=vanna,
            volga=volga,
            speed=speed,
            color=color,
            ultima=ultima,
            zomma=zomma,
            cross_gamma=0.0,
            cega=cega,
            dividend_sensitivity=dividend_sensitivity,
            dollar_gamma=dollar_gamma,
            gamma_scalping_pnl=gamma_scalping,
            theta_gamma_ratio=theta_gamma_ratio,
            pin_risk=pin_risk,
            local_vol=contract.volatility,
            price=price,
            model=model,
        )

    def _parse_barrier_type(self, value: BarrierType | str) -> BarrierType:
        if isinstance(value, BarrierType):
            return value
        normalized = value.strip().lower()
        if normalized == BarrierType.DOWN_AND_IN.value:
            return BarrierType.DOWN_AND_IN
        return BarrierType.UP_AND_OUT

    def _surface_points(
        self,
        surface: Sequence[Mapping[str, float] | VolatilityPoint],
    ) -> list[VolatilityPoint]:
        points: list[VolatilityPoint] = []
        for item in surface:
            if isinstance(item, VolatilityPoint):
                points.append(item)
                continue
            points.append(
                VolatilityPoint(
                    strike=float(item["strike"]),
                    expiry=float(item["expiry"]),
                    volatility=float(item["volatility"]),
                )
            )
        return points

    def _contract_from_mapping(self, position: Mapping[str, Any]) -> OptionContract:
        return OptionContract(
            spot=float(position["spot"]),
            strike=float(position["strike"]),
            time_to_expiry=float(position.get("tau", position.get("time_to_expiry", 0.0))),
            risk_free_rate=float(position.get("r", position.get("risk_free_rate", 0.05))),
            volatility=float(position.get("sigma", position.get("volatility", 0.20))),
            is_call=bool(position.get("is_call", True)),
            dividend_yield=float(position.get("q", position.get("dividend_yield", 0.0))),
        )

    def _greeks_from_position(self, position: Mapping[str, Any]) -> GreeksResult:
        contract = self._contract_from_mapping(position)
        return self.calculate_all(
            contract.spot,
            contract.strike,
            contract.time_to_expiry,
            contract.risk_free_rate,
            contract.volatility,
            contract.is_call,
            contract.dividend_yield,
        )


__all__ = [
    "AsianOptionPricer",
    "BarrierOptionPricer",
    "BarrierSpecification",
    "BarrierType",
    "CacheEntry",
    "CharmModel",
    "CrossGreeksEngine",
    "DeltaModel",
    "DigitalOptionPricer",
    "GammaModel",
    "GreeksEngine",
    "GreeksResult",
    "HedgeInstrument",
    "HedgingEngine",
    "HestonParameters",
    "HigherOrderGreeksModel",
    "OptionContract",
    "PinRiskAnalyzer",
    "PortfolioRiskEngine",
    "RealTimeGreeksEngine",
    "RhoModel",
    "SABRParameters",
    "ScenarioAnalysisEngine",
    "StressScenario",
    "ThetaModel",
    "VanillaOptionPricer",
    "VannaModel",
    "VegaModel",
    "VolatilityPoint",
    "VolatilitySurfaceEngine",
    "VolgaModel",
]
