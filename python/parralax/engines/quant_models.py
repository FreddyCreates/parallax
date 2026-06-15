"""
Quantitative Finance Models Engine — Real Mathematical Models
===============================================================

Production quantitative models with real formulas:
- Black-Scholes option pricing
- GARCH volatility modeling
- Kalman filtering for state estimation
- Cointegration and pairs trading
- Factor models (Fama-French, APT)
- Mean reversion and momentum models

FORMULAS:
    Black-Scholes Call: C = S₀N(d₁) - Ke^(-rT)N(d₂)
    GARCH(1,1): σ²ₜ = ω + α·ε²ₜ₋₁ + β·σ²ₜ₋₁
    Kalman Update: xₜ = xₜ₋₁ + K(yₜ - H·xₜ₋₁)
    Johansen Test: λ = -T·Σln(1-λᵢ)
    Sharpe: (μ - r_f) / σ
"""

import numpy as np
from scipy import stats, optimize
from scipy.linalg import sqrtm
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

# Golden ratio constants
PHI = 1.618033988749895
PHI_INV = 0.618033988749895
PHI_INV_2 = 0.382
PHI_INV_3 = 0.236


@dataclass
class OptionPricing:
    """Option pricing result"""
    call_price: float
    put_price: float
    delta: float
    gamma: float
    vega: float
    theta: float
    rho: float


@dataclass
class GARCHForecast:
    """GARCH volatility forecast"""
    conditional_variance: float
    conditional_volatility: float
    forecast_horizon: int
    long_run_variance: float
    persistence: float


@dataclass
class KalmanState:
    """Kalman filter state"""
    state_mean: np.ndarray
    state_covariance: np.ndarray
    innovation: float
    innovation_variance: float
    kalman_gain: np.ndarray


class QuantitativeEngine:
    """
    Production quantitative finance models
    
    Implements:
    1. Black-Scholes-Merton option pricing
    2. GARCH(1,1) volatility modeling
    3. Kalman filtering for optimal estimation
    4. Cointegration testing and pairs trading
    5. Multi-factor asset pricing models
    """
    
    def __init__(self):
        logger.info("Initialized Quantitative Finance Engine")
        self.coherence = PHI_INV
    
    # ========================================================================
    # BLACK-SCHOLES OPTION PRICING
    # ========================================================================
    
    def black_scholes(
        self,
        S: float,         # Current stock price
        K: float,         # Strike price
        T: float,         # Time to maturity (years)
        r: float,         # Risk-free rate
        sigma: float,     # Volatility
        q: float = 0.0,   # Dividend yield
    ) -> OptionPricing:
        """
        Black-Scholes-Merton option pricing model
        
        FORMULAS:
            d₁ = [ln(S/K) + (r - q + σ²/2)T] / (σ√T)
            d₂ = d₁ - σ√T
            
            Call Price: C = Se^(-qT)N(d₁) - Ke^(-rT)N(d₂)
            Put Price:  P = Ke^(-rT)N(-d₂) - Se^(-qT)N(-d₁)
            
        Greeks:
            Delta_C = e^(-qT)N(d₁)
            Gamma = e^(-qT)n(d₁) / (Sσ√T)
            Vega = Se^(-qT)n(d₁)√T
            Theta_C = -Se^(-qT)n(d₁)σ/(2√T) - rKe^(-rT)N(d₂) + qSe^(-qT)N(d₁)
            Rho_C = KTe^(-rT)N(d₂)
        
        Where N(x) is cumulative normal, n(x) is normal density
        """
        if T <= 0:
            # At expiration
            call = max(S - K, 0)
            put = max(K - S, 0)
            delta = 1.0 if S > K else 0.0
            return OptionPricing(call, put, delta, 0.0, 0.0, 0.0, 0.0)
        
        # Calculate d1 and d2
        sqrt_T = np.sqrt(T)
        d1 = (np.log(S / K) + (r - q + 0.5 * sigma ** 2) * T) / (sigma * sqrt_T)
        d2 = d1 - sigma * sqrt_T
        
        # Cumulative normal distribution
        N_d1 = stats.norm.cdf(d1)
        N_d2 = stats.norm.cdf(d2)
        N_minus_d1 = stats.norm.cdf(-d1)
        N_minus_d2 = stats.norm.cdf(-d2)
        
        # Normal density
        n_d1 = stats.norm.pdf(d1)
        
        # Discount factors
        disc_S = np.exp(-q * T)
        disc_K = np.exp(-r * T)
        
        # Option prices
        call_price = S * disc_S * N_d1 - K * disc_K * N_d2
        put_price = K * disc_K * N_minus_d2 - S * disc_S * N_minus_d1
        
        # Greeks
        delta = disc_S * N_d1
        gamma = disc_S * n_d1 / (S * sigma * sqrt_T)
        vega = S * disc_S * n_d1 * sqrt_T / 100.0  # Per 1% volatility
        theta = (
            -S * disc_S * n_d1 * sigma / (2 * sqrt_T)
            - r * K * disc_K * N_d2
            + q * S * disc_S * N_d1
        ) / 365.0  # Per day
        rho = K * T * disc_K * N_d2 / 100.0  # Per 1% rate
        
        return OptionPricing(
            call_price=float(call_price),
            put_price=float(put_price),
            delta=float(delta),
            gamma=float(gamma),
            vega=float(vega),
            theta=float(theta),
            rho=float(rho),
        )
    
    def implied_volatility(
        self,
        option_price: float,
        S: float,
        K: float,
        T: float,
        r: float,
        q: float = 0.0,
        option_type: str = 'call',
    ) -> float:
        """
        Calculate implied volatility using Newton-Raphson
        
        Iteratively solve: C(σ) - C_market = 0
        Using: σ_{n+1} = σ_n - [C(σ_n) - C_market] / vega(σ_n)
        """
        # Initial guess (phi-scaled ATM approximation)
        sigma_guess = PHI_INV * np.sqrt(2 * np.pi / T) * (option_price / S)
        
        max_iterations = 100
        tolerance = 1e-6
        
        for i in range(max_iterations):
            pricing = self.black_scholes(S, K, T, r, sigma_guess, q)
            
            if option_type == 'call':
                price_diff = pricing.call_price - option_price
            else:
                price_diff = pricing.put_price - option_price
            
            if abs(price_diff) < tolerance:
                return float(sigma_guess)
            
            # Newton-Raphson update
            if abs(pricing.vega) < 1e-10:
                break
            
            sigma_guess -= price_diff / (pricing.vega * 100.0)
            
            # Bounds
            sigma_guess = max(0.01, min(5.0, sigma_guess))
        
        logger.warning(f"Implied volatility did not converge after {max_iterations} iterations")
        return float(sigma_guess)
    
    # ========================================================================
    # GARCH VOLATILITY MODELING
    # ========================================================================
    
    def estimate_garch(
        self,
        returns: np.ndarray,
        omega_init: float = 0.01,
        alpha_init: float = 0.1,
        beta_init: float = 0.85,
    ) -> Tuple[float, float, float, np.ndarray]:
        """
        Estimate GARCH(1,1) parameters
        
        Model: σ²ₜ = ω + α·ε²ₜ₋₁ + β·σ²ₜ₋₁
        
        Where:
            ω > 0 (long-run variance component)
            α ≥ 0 (ARCH effect)
            β ≥ 0 (GARCH effect)
            α + β < 1 (stationarity)
        
        Returns:
            (omega, alpha, beta, conditional_variances)
        """
        def garch_log_likelihood(params):
            omega, alpha, beta = params
            
            # Constraints
            if omega <= 0 or alpha < 0 or beta < 0 or alpha + beta >= 1:
                return 1e10  # Large penalty
            
            # Initialize conditional variance
            var = np.var(returns)
            conditional_vars = np.zeros(len(returns))
            conditional_vars[0] = var
            
            # Recursive variance calculation
            for t in range(1, len(returns)):
                conditional_vars[t] = (
                    omega + alpha * returns[t-1]**2 + beta * conditional_vars[t-1]
                )
            
            # Log-likelihood (negative for minimization)
            log_likelihood = -0.5 * np.sum(
                np.log(2 * np.pi * conditional_vars) +
                returns**2 / conditional_vars
            )
            
            return -log_likelihood
        
        # Optimize
        result = optimize.minimize(
            garch_log_likelihood,
            x0=[omega_init, alpha_init, beta_init],
            method='L-BFGS-B',
            bounds=[(1e-6, 1.0), (0.0, 1.0), (0.0, 1.0)],
        )
        
        omega, alpha, beta = result.x
        
        # Calculate final conditional variances
        var = np.var(returns)
        conditional_vars = np.zeros(len(returns))
        conditional_vars[0] = var
        
        for t in range(1, len(returns)):
            conditional_vars[t] = (
                omega + alpha * returns[t-1]**2 + beta * conditional_vars[t-1]
            )
        
        logger.info(
            f"GARCH(1,1) estimated: ω={omega:.6f}, α={alpha:.4f}, β={beta:.4f}, "
            f"persistence={alpha+beta:.4f}"
        )
        
        return float(omega), float(alpha), float(beta), conditional_vars
    
    def forecast_garch(
        self,
        omega: float,
        alpha: float,
        beta: float,
        current_variance: float,
        current_return: float,
        horizon: int = 1,
    ) -> GARCHForecast:
        """
        Forecast future volatility using GARCH(1,1)
        
        h-step ahead forecast:
            σ²ₜ₊ₕ = ω·[Σᵢ₌₀ʰ⁻¹(α+β)ⁱ] + (α+β)ʰ·σ²ₜ
            
        As h → ∞: σ²ₜ₊ₕ → ω/(1-α-β) (long-run variance)
        """
        # Persistence
        persistence = alpha + beta
        
        # Long-run variance
        long_run_variance = omega / (1 - persistence) if persistence < 1 else np.inf
        
        # One-step ahead
        if horizon == 1:
            forecast_variance = omega + alpha * current_return**2 + beta * current_variance
        else:
            # Multi-step ahead
            if persistence >= 1.0:
                forecast_variance = long_run_variance
            else:
                geom_sum = (1 - persistence**horizon) / (1 - persistence)
                forecast_variance = (
                    omega * geom_sum +
                    persistence**horizon * current_variance
                )
        
        forecast_volatility = np.sqrt(forecast_variance)
        
        return GARCHForecast(
            conditional_variance=float(forecast_variance),
            conditional_volatility=float(forecast_volatility),
            forecast_horizon=horizon,
            long_run_variance=float(long_run_variance),
            persistence=float(persistence),
        )
    
    # ========================================================================
    # KALMAN FILTERING
    # ========================================================================
    
    def kalman_filter(
        self,
        observations: np.ndarray,
        initial_state: np.ndarray,
        initial_covariance: np.ndarray,
        transition_matrix: np.ndarray,  # F
        observation_matrix: np.ndarray,  # H
        process_noise: np.ndarray,      # Q
        observation_noise: np.ndarray,   # R
    ) -> List[KalmanState]:
        """
        Kalman filter for optimal state estimation
        
        STATE SPACE MODEL:
            xₜ = F·xₜ₋₁ + wₜ    (state equation, wₜ ~ N(0, Q))
            yₜ = H·xₜ + vₜ      (observation equation, vₜ ~ N(0, R))
        
        PREDICTION STEP:
            x̂ₜ|ₜ₋₁ = F·x̂ₜ₋₁|ₜ₋₁
            Pₜ|ₜ₋₁ = F·Pₜ₋₁|ₜ₋₁·F^T + Q
        
        UPDATE STEP:
            Kₜ = Pₜ|ₜ₋₁·H^T·(H·Pₜ|ₜ₋₁·H^T + R)⁻¹   (Kalman gain)
            x̂ₜ|ₜ = x̂ₜ|ₜ₋₁ + Kₜ·(yₜ - H·x̂ₜ|ₜ₋₁)    (state update)
            Pₜ|ₜ = (I - Kₜ·H)·Pₜ|ₜ₋₁               (covariance update)
        """
        F = transition_matrix
        H = observation_matrix
        Q = process_noise
        R = observation_noise
        
        x = initial_state.copy()
        P = initial_covariance.copy()
        
        states = []
        
        for y in observations:
            # Prediction step
            x_pred = F @ x
            P_pred = F @ P @ F.T + Q
            
            # Innovation
            innovation = y - H @ x_pred
            innovation_cov = H @ P_pred @ H.T + R
            
            # Kalman gain
            K = P_pred @ H.T @ np.linalg.inv(innovation_cov)
            
            # Update step
            x = x_pred + K @ innovation
            P = (np.eye(len(x)) - K @ H) @ P_pred
            
            states.append(KalmanState(
                state_mean=x.copy(),
                state_covariance=P.copy(),
                innovation=float(innovation),
                innovation_variance=float(innovation_cov),
                kalman_gain=K.copy(),
            ))
        
        return states
    
    # ========================================================================
    # COINTEGRATION & PAIRS TRADING
    # ========================================================================
    
    def test_cointegration(
        self,
        price_series_1: np.ndarray,
        price_series_2: np.ndarray,
        significance: float = 0.05,
    ) -> Tuple[bool, float, float]:
        """
        Engle-Granger cointegration test
        
        Steps:
        1. Regress Y on X: Yₜ = β₀ + β₁Xₜ + εₜ
        2. Test residuals for unit root (ADF test)
        3. If residuals stationary → series are cointegrated
        
        Returns:
            (is_cointegrated, hedge_ratio, p_value)
        """
        # Step 1: OLS regression
        X = np.column_stack([np.ones(len(price_series_1)), price_series_1])
        Y = price_series_2
        
        beta = np.linalg.lstsq(X, Y, rcond=None)[0]
        hedge_ratio = beta[1]
        
        # Residuals (spread)
        residuals = Y - X @ beta
        
        # Step 2: Augmented Dickey-Fuller test on residuals
        # Simplified ADF: test if residuals have unit root
        # H0: unit root (not cointegrated)
        # H1: stationary (cointegrated)
        
        # ADF regression: Δεₜ = α + γεₜ₋₁ + Σφᵢ·Δεₜ₋ᵢ + error
        lagged_resid = residuals[:-1]
        diff_resid = np.diff(residuals)
        
        X_adf = np.column_stack([np.ones(len(diff_resid)), lagged_resid])
        
        adf_params = np.linalg.lstsq(X_adf, diff_resid, rcond=None)[0]
        gamma = adf_params[1]
        
        # Standard error and t-statistic
        residuals_adf = diff_resid - X_adf @ adf_params
        se_gamma = np.sqrt(np.sum(residuals_adf**2) / (len(diff_resid) - 2)) / np.std(lagged_resid)
        t_stat = gamma / se_gamma
        
        # Critical values (Engle-Granger, approximate)
        critical_values = {
            0.01: -3.90,
            0.05: -3.34,
            0.10: -3.04,
        }
        
        critical_value = critical_values.get(significance, -3.34)
        is_cointegrated = t_stat < critical_value
        
        # Approximate p-value (very rough approximation)
        p_value = float(stats.norm.cdf(t_stat))
        
        logger.info(
            f"Cointegration test: hedge_ratio={hedge_ratio:.4f}, "
            f"t_stat={t_stat:.3f}, cointegrated={is_cointegrated}"
        )
        
        return is_cointegrated, float(hedge_ratio), p_value
    
    def pairs_trading_signal(
        self,
        spread: np.ndarray,
        entry_threshold: float = PHI_INV,     # 0.618 std
        exit_threshold: float = PHI_INV_3,    # 0.236 std
    ) -> int:
        """
        Generate pairs trading signal
        
        Normalized spread: z = (spread - μ) / σ
        
        Signals:
            z < -entry_threshold  → BUY spread (long Y, short X)
            z > +entry_threshold  → SELL spread (short Y, long X)
            |z| < exit_threshold  → EXIT position
        
        Returns:
            +1: long spread, -1: short spread, 0: flat/exit
        """
        mean_spread = np.mean(spread)
        std_spread = np.std(spread)
        
        current_spread = spread[-1]
        z_score = (current_spread - mean_spread) / std_spread if std_spread > 0 else 0.0
        
        if z_score < -entry_threshold:
            signal = 1  # Buy spread (mean reversion)
        elif z_score > entry_threshold:
            signal = -1  # Sell spread
        elif abs(z_score) < exit_threshold:
            signal = 0  # Exit
        else:
            signal = 0  # Hold current position (not implemented here)
        
        logger.debug(f"Pairs signal: z_score={z_score:.3f}, signal={signal}")
        
        return signal
    
    # ========================================================================
    # FACTOR MODELS
    # ========================================================================
    
    def fama_french_three_factor(
        self,
        returns: np.ndarray,
        market_excess_returns: np.ndarray,
        smb: np.ndarray,  # Small minus big
        hml: np.ndarray,  # High minus low
    ) -> Dict[str, float]:
        """
        Fama-French three-factor model
        
        Rᵢ - R_f = αᵢ + βᵢ(R_m - R_f) + sᵢSMB + hᵢHML + εᵢ
        
        Where:
            R_m - R_f: Market excess return
            SMB: Size factor (small cap - large cap)
            HML: Value factor (high B/M - low B/M)
        
        Returns:
            {alpha, beta_market, beta_smb, beta_hml, r_squared}
        """
        # OLS regression
        X = np.column_stack([
            np.ones(len(market_excess_returns)),
            market_excess_returns,
            smb,
            hml,
        ])
        Y = returns
        
        params = np.linalg.lstsq(X, Y, rcond=None)[0]
        
        alpha = params[0]
        beta_market = params[1]
        beta_smb = params[2]
        beta_hml = params[3]
        
        # R-squared
        y_pred = X @ params
        ss_res = np.sum((Y - y_pred)**2)
        ss_tot = np.sum((Y - np.mean(Y))**2)
        r_squared = 1 - ss_res / ss_tot if ss_tot > 0 else 0.0
        
        logger.info(
            f"Fama-French: α={alpha:.4f}, β_mkt={beta_market:.3f}, "
            f"β_SMB={beta_smb:.3f}, β_HML={beta_hml:.3f}, R²={r_squared:.3f}"
        )
        
        return {
            'alpha': float(alpha),
            'beta_market': float(beta_market),
            'beta_smb': float(beta_smb),
            'beta_hml': float(beta_hml),
            'r_squared': float(r_squared),
        }
