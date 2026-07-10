"""Stochastic calculus and derivatives tooling.

This module implements a compact quantitative toolkit centered on
risk-neutral pricing. It includes analytic Black-Scholes pricing with
Greeks, Heston stochastic-volatility calibration, jump-diffusion path
simulation, and a Monte Carlo engine with common variance-reduction
techniques.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

import numpy as np
from numpy.typing import ArrayLike
from scipy.integrate import quad
from scipy.optimize import least_squares
from scipy.stats import norm

OptionType = Literal["call", "put"]


@dataclass(slots=True)
class BlackScholesResult:
    """Container for Black-Scholes pricing outputs.

    Attributes:
        price: Option present value.
        delta: Sensitivity to spot moves.
        gamma: Curvature with respect to spot.
        vega: Sensitivity to volatility changes.
        theta: Time decay expressed per year.
        rho: Sensitivity to risk-free rate changes.
    """

    price: float
    delta: float
    gamma: float
    vega: float
    theta: float
    rho: float


@dataclass(slots=True)
class HestonParameters:
    """Parameterization of the Heston stochastic-volatility model."""

    kappa: float
    theta: float
    sigma: float
    rho: float
    v0: float


@dataclass(slots=True)
class HestonCalibrationResult:
    """Result returned by :func:`calibrate_heston_model`."""

    parameters: HestonParameters
    rmse: float
    model_prices: np.ndarray
    residuals: np.ndarray
    success: bool
    message: str
    iterations: int


@dataclass(slots=True)
class MonteCarloResult:
    """Pricing output from the Monte Carlo engine."""

    price: float
    standard_error: float
    confidence_interval: tuple[float, float]
    discounted_payoffs: np.ndarray


class VarianceReduction:
    """Collection of common variance-reduction techniques.

    The methods are exposed separately so they can be reused both inside the
    provided Monte Carlo engine and in custom simulation workflows.
    """

    @staticmethod
    def antithetic_normal_draws(
        n_paths: int,
        n_steps: int,
        random_state: int | np.random.Generator | None = None,
    ) -> np.ndarray:
        """Generate antithetic Gaussian innovations."""
        rng = np.random.default_rng(random_state)
        half = (n_paths + 1) // 2
        base = rng.standard_normal((n_steps, half))
        draws = np.concatenate([base, -base], axis=1)
        return draws[:, :n_paths]

    @staticmethod
    def stratified_normal_draws(
        n_paths: int,
        n_steps: int,
        random_state: int | np.random.Generator | None = None,
    ) -> np.ndarray:
        """Approximate inverse-CDF stratification for Gaussian shocks."""
        rng = np.random.default_rng(random_state)
        uniforms = np.empty((n_steps, n_paths), dtype=float)
        grid = np.arange(n_paths, dtype=float)
        for step in range(n_steps):
            uniforms[step] = (grid + rng.random(n_paths)) / n_paths
            rng.shuffle(uniforms[step])
        return norm.ppf(np.clip(uniforms, 1e-10, 1.0 - 1e-10))

    @staticmethod
    def control_variate_adjustment(
        samples: ArrayLike,
        control: ArrayLike,
        expected_control: float,
    ) -> np.ndarray:
        """Apply a linear control-variate correction."""
        x = np.asarray(samples, dtype=float)
        y = np.asarray(control, dtype=float)
        if x.shape != y.shape:
            raise ValueError("samples and control must share the same shape")
        variance = float(np.var(y, ddof=1))
        if variance <= 1e-16:
            return x.copy()
        covariance = float(np.cov(x, y, ddof=1)[0, 1])
        beta = covariance / variance
        return x - beta * (y - expected_control)


def _validate_option_inputs(
    spot: float,
    strike: float,
    maturity: float,
    volatility: float,
) -> None:
    if spot <= 0 or strike <= 0:
        raise ValueError("spot and strike must be positive")
    if maturity < 0:
        raise ValueError("maturity must be non-negative")
    if volatility < 0:
        raise ValueError("volatility must be non-negative")


def _normalised_option_type(option_type: str) -> OptionType:
    option = option_type.lower()
    if option not in {"call", "put"}:
        raise ValueError("option_type must be 'call' or 'put'")
    return option  # type: ignore[return-value]


def black_scholes_price(
    spot: float,
    strike: float,
    maturity: float,
    risk_free_rate: float,
    volatility: float,
    dividend_yield: float = 0.0,
    option_type: str = "call",
) -> float:
    """Price a European option under the Black-Scholes model."""
    _validate_option_inputs(spot, strike, maturity, volatility)
    option = _normalised_option_type(option_type)
    if maturity == 0 or volatility == 0:
        intrinsic = max(spot - strike, 0.0) if option == "call" else max(strike - spot, 0.0)
        return float(intrinsic)

    sigma_sqrt_t = volatility * np.sqrt(maturity)
    d1 = (
        np.log(spot / strike)
        + (risk_free_rate - dividend_yield + 0.5 * volatility**2) * maturity
    ) / sigma_sqrt_t
    d2 = d1 - sigma_sqrt_t
    discount_r = np.exp(-risk_free_rate * maturity)
    discount_q = np.exp(-dividend_yield * maturity)
    if option == "call":
        return float(spot * discount_q * norm.cdf(d1) - strike * discount_r * norm.cdf(d2))
    return float(strike * discount_r * norm.cdf(-d2) - spot * discount_q * norm.cdf(-d1))


def black_scholes_with_greeks(
    spot: float,
    strike: float,
    maturity: float,
    risk_free_rate: float,
    volatility: float,
    dividend_yield: float = 0.0,
    option_type: str = "call",
) -> BlackScholesResult:
    """Price a European option and compute the standard Greeks."""
    _validate_option_inputs(spot, strike, maturity, volatility)
    option = _normalised_option_type(option_type)
    price = black_scholes_price(
        spot=spot,
        strike=strike,
        maturity=maturity,
        risk_free_rate=risk_free_rate,
        volatility=volatility,
        dividend_yield=dividend_yield,
        option_type=option,
    )
    if maturity == 0 or volatility == 0:
        delta = 1.0 if option == "call" and spot > strike else 0.0
        if option == "put":
            delta = -1.0 if strike > spot else 0.0
        return BlackScholesResult(price=price, delta=delta, gamma=0.0, vega=0.0, theta=0.0, rho=0.0)

    sigma_sqrt_t = volatility * np.sqrt(maturity)
    d1 = (
        np.log(spot / strike)
        + (risk_free_rate - dividend_yield + 0.5 * volatility**2) * maturity
    ) / sigma_sqrt_t
    d2 = d1 - sigma_sqrt_t
    discount_r = np.exp(-risk_free_rate * maturity)
    discount_q = np.exp(-dividend_yield * maturity)
    pdf_d1 = norm.pdf(d1)

    if option == "call":
        delta = discount_q * norm.cdf(d1)
        theta = (
            -(spot * discount_q * pdf_d1 * volatility) / (2 * np.sqrt(maturity))
            - risk_free_rate * strike * discount_r * norm.cdf(d2)
            + dividend_yield * spot * discount_q * norm.cdf(d1)
        )
        rho = strike * maturity * discount_r * norm.cdf(d2)
    else:
        delta = discount_q * (norm.cdf(d1) - 1.0)
        theta = (
            -(spot * discount_q * pdf_d1 * volatility) / (2 * np.sqrt(maturity))
            + risk_free_rate * strike * discount_r * norm.cdf(-d2)
            - dividend_yield * spot * discount_q * norm.cdf(-d1)
        )
        rho = -strike * maturity * discount_r * norm.cdf(-d2)

    gamma = discount_q * pdf_d1 / (spot * sigma_sqrt_t)
    vega = spot * discount_q * pdf_d1 * np.sqrt(maturity)
    return BlackScholesResult(
        price=float(price),
        delta=float(delta),
        gamma=float(gamma),
        vega=float(vega),
        theta=float(theta),
        rho=float(rho),
    )


def heston_characteristic(
    u: complex | np.ndarray,
    spot: float,
    maturity: float,
    risk_free_rate: float,
    params: HestonParameters,
    dividend_yield: float = 0.0,
) -> complex | np.ndarray:
    """Evaluate the Heston characteristic function of log spot."""
    x0 = np.log(spot)
    if maturity == 0:
        return np.exp(1j * u * x0)
    if params.sigma <= 0:
        vol = np.sqrt(max(params.v0, params.theta, 1e-12))
        drift = x0 + (risk_free_rate - dividend_yield - 0.5 * vol**2) * maturity
        variance = vol**2 * maturity
        return np.exp(1j * u * drift - 0.5 * variance * u**2)

    a = params.kappa * params.theta
    b = params.kappa - params.rho * params.sigma * 1j * u
    d = np.sqrt(b**2 + params.sigma**2 * (u**2 + 1j * u))
    g = (b - d) / (b + d)
    exp_dt = np.exp(-d * maturity)
    c_term = (
        (risk_free_rate - dividend_yield) * 1j * u * maturity
        + (a / params.sigma**2)
        * ((b - d) * maturity - 2.0 * np.log((1.0 - g * exp_dt) / (1.0 - g)))
    )
    d_term = ((b - d) / params.sigma**2) * ((1.0 - exp_dt) / (1.0 - g * exp_dt))
    return np.exp(c_term + d_term * params.v0 + 1j * u * x0)


def heston_price(
    spot: float,
    strike: float,
    maturity: float,
    risk_free_rate: float,
    params: HestonParameters,
    dividend_yield: float = 0.0,
    option_type: str = "call",
    integration_limit: float = 150.0,
) -> float:
    """Price a European option under the Heston model via Fourier inversion."""
    option = _normalised_option_type(option_type)
    if maturity == 0:
        intrinsic = max(spot - strike, 0.0) if option == "call" else max(strike - spot, 0.0)
        return float(intrinsic)

    log_moneyness = np.log(strike / spot)

    def integrand(u: float) -> float:
        shifted = u - 0.5j
        value = np.exp(-1j * u * log_moneyness) * heston_characteristic(
            shifted,
            spot=spot,
            maturity=maturity,
            risk_free_rate=risk_free_rate,
            params=params,
            dividend_yield=dividend_yield,
        )
        return float(np.real(value / (u * u + 0.25)))

    integral, _ = quad(integrand, 0.0, integration_limit, limit=200)
    call_price = (
        spot * np.exp(-dividend_yield * maturity)
        - np.sqrt(spot * strike) * np.exp(-risk_free_rate * maturity) * integral / np.pi
    )
    call_price = max(float(call_price), 0.0)
    if option == "call":
        return call_price
    parity = strike * np.exp(-risk_free_rate * maturity) - spot * np.exp(-dividend_yield * maturity)
    return max(call_price + parity, 0.0)


def calibrate_heston_model(
    spot: float,
    strikes: ArrayLike,
    maturities: ArrayLike,
    market_prices: ArrayLike,
    risk_free_rate: float,
    dividend_yield: float = 0.0,
    initial_guess: HestonParameters | None = None,
    bounds: tuple[tuple[float, ...], tuple[float, ...]] | None = None,
) -> HestonCalibrationResult:
    """Calibrate Heston parameters to market option prices."""
    strikes_arr = np.asarray(strikes, dtype=float)
    maturities_arr = np.asarray(maturities, dtype=float)
    prices_arr = np.asarray(market_prices, dtype=float)
    if not (len(strikes_arr) == len(maturities_arr) == len(prices_arr)):
        raise ValueError("strikes, maturities, and market_prices must have equal length")

    guess = initial_guess or HestonParameters(kappa=2.0, theta=0.04, sigma=0.5, rho=-0.6, v0=0.04)
    lower = np.array([1e-4, 1e-4, 1e-4, -0.999, 1e-4], dtype=float)
    upper = np.array([25.0, 5.0, 5.0, 0.999, 5.0], dtype=float)
    if bounds is not None:
        lower = np.asarray(bounds[0], dtype=float)
        upper = np.asarray(bounds[1], dtype=float)

    def residual_function(raw: np.ndarray) -> np.ndarray:
        params = HestonParameters(*raw.tolist())
        model = np.array([
            heston_price(
                spot=spot,
                strike=float(k),
                maturity=float(t),
                risk_free_rate=risk_free_rate,
                params=params,
                dividend_yield=dividend_yield,
            )
            for k, t in zip(strikes_arr, maturities_arr)
        ])
        scale = np.maximum(prices_arr, 1.0)
        return (model - prices_arr) / scale

    result = least_squares(
        residual_function,
        x0=np.array([guess.kappa, guess.theta, guess.sigma, guess.rho, guess.v0], dtype=float),
        bounds=(lower, upper),
        max_nfev=400,
    )
    fitted = HestonParameters(*result.x.tolist())
    model_prices = np.array([
        heston_price(
            spot=spot,
            strike=float(k),
            maturity=float(t),
            risk_free_rate=risk_free_rate,
            params=fitted,
            dividend_yield=dividend_yield,
        )
        for k, t in zip(strikes_arr, maturities_arr)
    ])
    residuals = model_prices - prices_arr
    rmse = float(np.sqrt(np.mean(residuals**2)))
    return HestonCalibrationResult(
        parameters=fitted,
        rmse=rmse,
        model_prices=model_prices,
        residuals=residuals,
        success=bool(result.success),
        message=str(result.message),
        iterations=int(result.nfev),
    )


def simulate_jump_diffusion_paths(
    spot: float,
    maturity: float,
    risk_free_rate: float,
    volatility: float,
    jump_intensity: float,
    jump_mean: float,
    jump_std: float,
    n_steps: int,
    n_paths: int,
    dividend_yield: float = 0.0,
    random_state: int | np.random.Generator | None = None,
) -> np.ndarray:
    """Simulate Merton jump-diffusion paths under the risk-neutral measure."""
    _validate_option_inputs(spot, spot, maturity, volatility)
    if n_steps <= 0 or n_paths <= 0:
        raise ValueError("n_steps and n_paths must be positive")
    rng = np.random.default_rng(random_state)
    dt = maturity / n_steps
    diffusion = rng.standard_normal((n_steps, n_paths))
    jump_counts = rng.poisson(jump_intensity * dt, size=(n_steps, n_paths))
    jump_sizes = rng.normal(jump_mean, jump_std, size=(n_steps, n_paths))
    compensator = np.exp(jump_mean + 0.5 * jump_std**2) - 1.0
    drift = risk_free_rate - dividend_yield - jump_intensity * compensator - 0.5 * volatility**2
    increments = drift * dt + volatility * np.sqrt(dt) * diffusion + jump_sizes * jump_counts
    log_paths = np.vstack([np.zeros((1, n_paths)), np.cumsum(increments, axis=0)])
    return spot * np.exp(log_paths)


class MonteCarloPricer:
    """Monte Carlo pricing engine with built-in variance reduction."""

    def __init__(
        self,
        n_paths: int = 50_000,
        n_steps: int = 252,
        variance_reduction: Literal["antithetic", "stratified", "none"] = "antithetic",
        random_state: int | np.random.Generator | None = None,
    ) -> None:
        self.n_paths = int(n_paths)
        self.n_steps = int(n_steps)
        self.variance_reduction = variance_reduction
        self.random_state = random_state

    def _normal_draws(self) -> np.ndarray:
        if self.variance_reduction == "antithetic":
            return VarianceReduction.antithetic_normal_draws(self.n_paths, self.n_steps, self.random_state)
        if self.variance_reduction == "stratified":
            return VarianceReduction.stratified_normal_draws(self.n_paths, self.n_steps, self.random_state)
        return np.random.default_rng(self.random_state).standard_normal((self.n_steps, self.n_paths))

    def simulate_gbm_paths(
        self,
        spot: float,
        maturity: float,
        risk_free_rate: float,
        volatility: float,
        dividend_yield: float = 0.0,
    ) -> np.ndarray:
        """Simulate geometric-Brownian-motion paths."""
        dt = maturity / self.n_steps
        draws = self._normal_draws()
        drift = (risk_free_rate - dividend_yield - 0.5 * volatility**2) * dt
        diffusion = volatility * np.sqrt(dt) * draws
        log_paths = np.vstack([np.zeros((1, self.n_paths)), np.cumsum(drift + diffusion, axis=0)])
        return spot * np.exp(log_paths)

    def price_european_option(
        self,
        spot: float,
        strike: float,
        maturity: float,
        risk_free_rate: float,
        volatility: float,
        dividend_yield: float = 0.0,
        option_type: str = "call",
        jump_params: dict[str, float] | None = None,
        use_control_variate: bool = True,
    ) -> MonteCarloResult:
        """Price a European option from simulated terminal payoffs."""
        option = _normalised_option_type(option_type)
        if jump_params:
            paths = simulate_jump_diffusion_paths(
                spot=spot,
                maturity=maturity,
                risk_free_rate=risk_free_rate,
                volatility=volatility,
                jump_intensity=float(jump_params["jump_intensity"]),
                jump_mean=float(jump_params["jump_mean"]),
                jump_std=float(jump_params["jump_std"]),
                n_steps=self.n_steps,
                n_paths=self.n_paths,
                dividend_yield=dividend_yield,
                random_state=self.random_state,
            )
        else:
            paths = self.simulate_gbm_paths(spot, maturity, risk_free_rate, volatility, dividend_yield)

        terminal = paths[-1]
        payoffs = np.maximum(terminal - strike, 0.0) if option == "call" else np.maximum(strike - terminal, 0.0)
        discount = np.exp(-risk_free_rate * maturity)
        discounted = discount * payoffs
        if use_control_variate:
            discounted_terminal = discount * terminal
            expected_control = spot * np.exp(-dividend_yield * maturity)
            discounted = VarianceReduction.control_variate_adjustment(discounted, discounted_terminal, expected_control)

        price = float(np.mean(discounted))
        std_error = float(np.std(discounted, ddof=1) / np.sqrt(len(discounted)))
        ci = (price - 1.96 * std_error, price + 1.96 * std_error)
        return MonteCarloResult(price=price, standard_error=std_error, confidence_interval=ci, discounted_payoffs=discounted)
