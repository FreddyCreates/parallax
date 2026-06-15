#!/usr/bin/env python3
"""
QUANTITATIVE LIBRARIES BRIDGE — PARALLAX Sovereign Organism
============================================================

Python-side quantitative finance and scientific computing bridge.
Provides access to NumPy, SciPy, SymPy, pandas for advanced mathematical
operations that complement the Motoko quantitative engines.

Domains:
  - Matrix operations (NumPy)
  - Scientific computing (SciPy: optimization, integration, statistics)
  - Symbolic mathematics (SymPy: calculus, algebra, equation solving)
  - Time series analysis (pandas, statsmodels)
  - Advanced optimization (CVXPY for convex optimization)
  - Machine learning (scikit-learn for quantitative models)

Author: Alfredo Medina Hernandez — The Architect of the Field
License: PARALLAX Sovereign License
"""

import numpy as np
import pandas as pd
from scipy import optimize, integrate, stats, linalg
from scipy.special import erf, gamma as gamma_func
import sympy as sp
from typing import Dict, List, Tuple, Optional, Any
import json

# Try importing optional libraries
try:
    from statsmodels.tsa.stattools import adfuller, coint
    from statsmodels.tsa.arima.model import ARIMA
    STATSMODELS_AVAILABLE = True
except ImportError:
    STATSMODELS_AVAILABLE = False

try:
    import cvxpy as cp
    CVXPY_AVAILABLE = True
except ImportError:
    CVXPY_AVAILABLE = False

from entangala_bridge import (
    EntangalaBridge, PythonDomain, PHI, PHI_INV, PHI_INV_2,
    compute_phi_coherence, compute_doctrine_hash
)


# ═══════════════════════════════════════════════════════════════════════════
# QUANTITATIVE FINANCE LIBRARY
# ═══════════════════════════════════════════════════════════════════════════

class QuantitativeLibrary:
    """
    Python-side quantitative finance and scientific computing library.
    
    Provides methods that extend the Motoko quantitative engines with
    Python's rich numerical ecosystem (NumPy, SciPy, SymPy, pandas).
    """
    
    # ═══════════════════════════════════════════════════════════════════════
    # MATRIX OPERATIONS (NumPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def matrix_multiply(A: List[List[float]], B: List[List[float]]) -> List[List[float]]:
        """Matrix multiplication using NumPy."""
        result = np.matmul(np.array(A), np.array(B))
        return result.tolist()
    
    @staticmethod
    def matrix_inverse(A: List[List[float]]) -> Optional[List[List[float]]]:
        """Matrix inversion using NumPy."""
        try:
            inv = np.linalg.inv(np.array(A))
            return inv.tolist()
        except np.linalg.LinAlgError:
            return None
    
    @staticmethod
    def eigenvalues(A: List[List[float]]) -> Tuple[List[float], List[List[float]]]:
        """Compute eigenvalues and eigenvectors."""
        vals, vecs = np.linalg.eig(np.array(A))
        return vals.tolist(), vecs.tolist()
    
    @staticmethod
    def cholesky_decomposition(A: List[List[float]]) -> Optional[List[List[float]]]:
        """Cholesky decomposition: A = L L^T."""
        try:
            L = np.linalg.cholesky(np.array(A))
            return L.tolist()
        except np.linalg.LinAlgError:
            return None
    
    @staticmethod
    def svd(A: List[List[float]]) -> Tuple[List[List[float]], List[float], List[List[float]]]:
        """Singular Value Decomposition: A = U Σ V^T."""
        U, s, Vt = np.linalg.svd(np.array(A))
        return U.tolist(), s.tolist(), Vt.tolist()
    
    # ═══════════════════════════════════════════════════════════════════════
    # OPTIMIZATION (SciPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def minimize_function(
        objective: str,
        x0: List[float],
        bounds: Optional[List[Tuple[float, float]]] = None,
        constraints: Optional[List[Dict]] = None
    ) -> Dict[str, Any]:
        """
        Minimize an objective function using SciPy optimization.
        
        Args:
            objective: Python expression for objective function (e.g., "x[0]**2 + x[1]**2")
            x0: Initial guess
            bounds: Optional bounds for each variable
            constraints: Optional constraints
            
        Returns:
            Optimization result with solution and convergence info
        """
        # Create objective function from string
        x = sp.symbols(f'x0:{len(x0)}')
        obj_expr = sp.sympify(objective)
        obj_func = sp.lambdify(x, obj_expr, 'numpy')
        
        # Wrapper to handle array input
        def objective_wrapper(x_arr):
            return float(obj_func(*x_arr))
        
        # Run optimization
        result = optimize.minimize(
            objective_wrapper,
            x0=x0,
            bounds=bounds,
            method='SLSQP'
        )
        
        return {
            'success': bool(result.success),
            'solution': result.x.tolist() if hasattr(result.x, 'tolist') else list(result.x),
            'objective_value': float(result.fun),
            'iterations': int(result.nit) if hasattr(result, 'nit') else 0,
            'message': str(result.message),
        }
    
    @staticmethod
    def portfolio_optimization_cvxpy(
        returns: List[float],
        covariance: List[List[float]],
        target_return: Optional[float] = None,
        risk_free_rate: float = 0.0
    ) -> Dict[str, Any]:
        """
        Portfolio optimization using CVXPY (convex optimization).
        
        Solves Markowitz mean-variance optimization:
            minimize: w^T Σ w (portfolio variance)
            subject to: w^T μ ≥ target_return
                       sum(w) = 1
                       w ≥ 0 (long-only)
        """
        if not CVXPY_AVAILABLE:
            return {'error': 'CVXPY not available'}
        
        n = len(returns)
        w = cp.Variable(n)
        mu = np.array(returns)
        Sigma = np.array(covariance)
        
        # Objective: minimize portfolio variance
        objective = cp.Minimize(cp.quad_form(w, Sigma))
        
        # Constraints
        constraints = [
            cp.sum(w) == 1,  # Fully invested
            w >= 0,          # Long-only
        ]
        
        if target_return is not None:
            constraints.append(mu @ w >= target_return)
        
        # Solve
        problem = cp.Problem(objective, constraints)
        problem.solve()
        
        if problem.status != 'optimal':
            return {'error': f'Optimization failed: {problem.status}'}
        
        weights = w.value.tolist() if hasattr(w.value, 'tolist') else list(w.value)
        portfolio_return = float(np.dot(mu, w.value))
        portfolio_variance = float(cp.quad_form(w, Sigma).value)
        portfolio_vol = np.sqrt(portfolio_variance)
        sharpe = (portfolio_return - risk_free_rate) / portfolio_vol if portfolio_vol > 0 else 0.0
        
        return {
            'weights': weights,
            'expected_return': portfolio_return,
            'volatility': float(portfolio_vol),
            'sharpe_ratio': float(sharpe),
            'status': problem.status,
        }
    
    # ═══════════════════════════════════════════════════════════════════════
    # STATISTICAL TESTS (SciPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def cointegration_test(
        series1: List[float],
        series2: List[float]
    ) -> Dict[str, float]:
        """
        Engle-Granger cointegration test for pairs trading.
        
        Returns test statistic and p-value.
        """
        if not STATSMODELS_AVAILABLE:
            # Fallback: simple correlation
            corr, pval = stats.pearsonr(series1, series2)
            return {
                'test_statistic': corr,
                'p_value': pval,
                'cointegrated': abs(corr) > PHI_INV,
                'method': 'correlation_fallback'
            }
        
        # Engle-Granger test
        score, pvalue, _ = coint(series1, series2)
        
        return {
            'test_statistic': float(score),
            'p_value': float(pvalue),
            'cointegrated': pvalue < PHI_INV_2,  # 0.382 significance level
            'method': 'engle_granger'
        }
    
    @staticmethod
    def augmented_dickey_fuller(series: List[float]) -> Dict[str, Any]:
        """
        Augmented Dickey-Fuller test for stationarity.
        
        Tests null hypothesis that series has unit root (non-stationary).
        """
        if not STATSMODELS_AVAILABLE:
            return {'error': 'statsmodels not available'}
        
        result = adfuller(series)
        
        return {
            'test_statistic': float(result[0]),
            'p_value': float(result[1]),
            'lags': int(result[2]),
            'n_obs': int(result[3]),
            'critical_values': {k: float(v) for k, v in result[4].items()},
            'is_stationary': result[1] < PHI_INV_2,
        }
    
    @staticmethod
    def normality_test(data: List[float]) -> Dict[str, float]:
        """Jarque-Bera test for normality."""
        jb_stat, p_value = stats.jarque_bera(data)
        return {
            'jarque_bera_statistic': float(jb_stat),
            'p_value': float(p_value),
            'is_normal': p_value > 0.05,
        }
    
    # ═══════════════════════════════════════════════════════════════════════
    # SYMBOLIC MATHEMATICS (SymPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def symbolic_derivative(expression: str, variable: str) -> str:
        """Compute symbolic derivative."""
        x = sp.Symbol(variable)
        expr = sp.sympify(expression)
        derivative = sp.diff(expr, x)
        return str(derivative)
    
    @staticmethod
    def symbolic_integral(expression: str, variable: str) -> str:
        """Compute symbolic integral."""
        x = sp.Symbol(variable)
        expr = sp.sympify(expression)
        integral = sp.integrate(expr, x)
        return str(integral)
    
    @staticmethod
    def solve_equation(equation: str, variable: str) -> List[str]:
        """Solve symbolic equation."""
        x = sp.Symbol(variable)
        eq = sp.sympify(equation)
        solutions = sp.solve(eq, x)
        return [str(sol) for sol in solutions]
    
    @staticmethod
    def taylor_series(expression: str, variable: str, point: float, order: int) -> str:
        """Compute Taylor series expansion."""
        x = sp.Symbol(variable)
        expr = sp.sympify(expression)
        series = expr.series(x, x0=point, n=order)
        return str(series)
    
    # ═══════════════════════════════════════════════════════════════════════
    # NUMERICAL INTEGRATION (SciPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def integrate_quadrature(
        func_str: str,
        lower: float,
        upper: float
    ) -> Dict[str, float]:
        """Numerical integration using Gaussian quadrature."""
        x = sp.Symbol('x')
        expr = sp.sympify(func_str)
        func = sp.lambdify(x, expr, 'numpy')
        
        result, error = integrate.quad(func, lower, upper)
        
        return {
            'integral': float(result),
            'error': float(error),
        }
    
    @staticmethod
    def integrate_monte_carlo(
        func_str: str,
        bounds: List[Tuple[float, float]],
        n_samples: int = 10000
    ) -> Dict[str, float]:
        """Monte Carlo integration for multi-dimensional integrals."""
        # Parse function
        n_dims = len(bounds)
        vars_symbs = sp.symbols(f'x0:{n_dims}')
        expr = sp.sympify(func_str)
        func = sp.lambdify(vars_symbs, expr, 'numpy')
        
        # Generate random samples
        samples = np.random.uniform(
            low=[b[0] for b in bounds],
            high=[b[1] for b in bounds],
            size=(n_samples, n_dims)
        )
        
        # Evaluate function at samples
        values = np.array([func(*sample) for sample in samples])
        
        # Volume of integration region
        volume = np.prod([b[1] - b[0] for b in bounds])
        
        # Monte Carlo estimate
        integral = volume * np.mean(values)
        error = volume * np.std(values) / np.sqrt(n_samples)
        
        return {
            'integral': float(integral),
            'error': float(error),
            'n_samples': n_samples,
        }
    
    # ═══════════════════════════════════════════════════════════════════════
    # TIME SERIES ANALYSIS (pandas, statsmodels)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def autocorrelation(series: List[float], max_lag: int = 20) -> List[float]:
        """Compute autocorrelation function."""
        arr = np.array(series)
        mean = np.mean(arr)
        var = np.var(arr)
        
        acf = []
        for lag in range(max_lag + 1):
            if lag == 0:
                acf.append(1.0)
            else:
                cov = np.mean((arr[:-lag] - mean) * (arr[lag:] - mean))
                acf.append(float(cov / var) if var > 0 else 0.0)
        
        return acf
    
    @staticmethod
    def fit_arima(
        series: List[float],
        order: Tuple[int, int, int]
    ) -> Dict[str, Any]:
        """Fit ARIMA model to time series."""
        if not STATSMODELS_AVAILABLE:
            return {'error': 'statsmodels not available'}
        
        model = ARIMA(series, order=order)
        fitted = model.fit()
        
        return {
            'aic': float(fitted.aic),
            'bic': float(fitted.bic),
            'parameters': fitted.params.tolist(),
            'residuals': fitted.resid.tolist(),
            'forecast': fitted.forecast(steps=5).tolist(),
        }
    
    # ═══════════════════════════════════════════════════════════════════════
    # SPECIAL FUNCTIONS (SciPy)
    # ═══════════════════════════════════════════════════════════════════════
    
    @staticmethod
    def black_scholes_python(
        S: float, K: float, T: float, sigma: float, r: float, q: float = 0.0
    ) -> Dict[str, float]:
        """
        Black-Scholes option pricing (Python validation of Motoko implementation).
        
        Uses SciPy's special functions for precision.
        """
        if T <= 0 or sigma <= 0:
            return {
                'call_price': max(0.0, S - K),
                'put_price': max(0.0, K - S),
                'delta': 1.0 if S > K else 0.0,
                'gamma': 0.0,
                'vega': 0.0,
                'theta': 0.0,
                'rho': 0.0,
            }
        
        # d1 and d2
        d1 = (np.log(S / K) + (r - q + 0.5 * sigma**2) * T) / (sigma * np.sqrt(T))
        d2 = d1 - sigma * np.sqrt(T)
        
        # Normal CDF using erf
        Nd1 = 0.5 * (1 + erf(d1 / np.sqrt(2)))
        Nd2 = 0.5 * (1 + erf(d2 / np.sqrt(2)))
        N_minus_d1 = 0.5 * (1 + erf(-d1 / np.sqrt(2)))
        N_minus_d2 = 0.5 * (1 + erf(-d2 / np.sqrt(2)))
        
        # Normal PDF
        nd1 = np.exp(-0.5 * d1**2) / np.sqrt(2 * np.pi)
        
        # Discount factors
        discount = np.exp(-r * T)
        dividend_discount = np.exp(-q * T)
        
        # Option prices
        call_price = S * dividend_discount * Nd1 - K * discount * Nd2
        put_price = K * discount * N_minus_d2 - S * dividend_discount * N_minus_d1
        
        # Greeks
        delta = dividend_discount * Nd1
        gamma = (dividend_discount * nd1) / (S * sigma * np.sqrt(T))
        vega = S * dividend_discount * nd1 * np.sqrt(T) / 100.0
        theta = ((-S * dividend_discount * nd1 * sigma) / (2 * np.sqrt(T)) 
                 - r * K * discount * Nd2 
                 + q * S * dividend_discount * Nd1) / 365.25
        rho = K * T * discount * Nd2 / 100.0
        
        return {
            'call_price': float(call_price),
            'put_price': float(put_price),
            'delta': float(delta),
            'gamma': float(gamma),
            'vega': float(vega),
            'theta': float(theta),
            'rho': float(rho),
        }


# ═══════════════════════════════════════════════════════════════════════════
# BRIDGE INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

def create_quantitative_bridge(worker_id: str = "py-quant-001") -> EntangalaBridge:
    """Create and configure the quantitative library bridge."""
    
    bridge = EntangalaBridge(
        worker_id=worker_id,
        domain=PythonDomain.SCIENTIFIC_COMPUTE,
        organism_endpoint="https://parallax-backend.ic0.app",
    )
    
    quant_lib = QuantitativeLibrary()
    
    @bridge.on_dispatch
    def handle_quantitative_dispatch(payload: dict) -> dict:
        """Route quantitative computation requests."""
        operation = payload.get('operation')
        params = payload.get('params', {})
        
        result = {}
        
        try:
            if operation == 'matrix_multiply':
                result['output'] = quant_lib.matrix_multiply(params['A'], params['B'])
            elif operation == 'matrix_inverse':
                result['output'] = quant_lib.matrix_inverse(params['A'])
            elif operation == 'eigenvalues':
                vals, vecs = quant_lib.eigenvalues(params['A'])
                result['eigenvalues'] = vals
                result['eigenvectors'] = vecs
            elif operation == 'cholesky':
                result['output'] = quant_lib.cholesky_decomposition(params['A'])
            elif operation == 'svd':
                U, s, Vt = quant_lib.svd(params['A'])
                result['U'] = U
                result['singular_values'] = s
                result['Vt'] = Vt
            elif operation == 'optimize':
                result['output'] = quant_lib.minimize_function(
                    params['objective'],
                    params['x0'],
                    params.get('bounds'),
                    params.get('constraints')
                )
            elif operation == 'portfolio_cvxpy':
                result['output'] = quant_lib.portfolio_optimization_cvxpy(
                    params['returns'],
                    params['covariance'],
                    params.get('target_return'),
                    params.get('risk_free_rate', 0.0)
                )
            elif operation == 'cointegration':
                result['output'] = quant_lib.cointegration_test(
                    params['series1'],
                    params['series2']
                )
            elif operation == 'adf_test':
                result['output'] = quant_lib.augmented_dickey_fuller(params['series'])
            elif operation == 'normality_test':
                result['output'] = quant_lib.normality_test(params['data'])
            elif operation == 'derivative':
                result['output'] = quant_lib.symbolic_derivative(
                    params['expression'],
                    params['variable']
                )
            elif operation == 'integral':
                result['output'] = quant_lib.symbolic_integral(
                    params['expression'],
                    params['variable']
                )
            elif operation == 'solve':
                result['output'] = quant_lib.solve_equation(
                    params['equation'],
                    params['variable']
                )
            elif operation == 'taylor':
                result['output'] = quant_lib.taylor_series(
                    params['expression'],
                    params['variable'],
                    params['point'],
                    params['order']
                )
            elif operation == 'integrate_quad':
                result['output'] = quant_lib.integrate_quadrature(
                    params['function'],
                    params['lower'],
                    params['upper']
                )
            elif operation == 'integrate_mc':
                result['output'] = quant_lib.integrate_monte_carlo(
                    params['function'],
                    params['bounds'],
                    params.get('n_samples', 10000)
                )
            elif operation == 'autocorrelation':
                result['output'] = quant_lib.autocorrelation(
                    params['series'],
                    params.get('max_lag', 20)
                )
            elif operation == 'arima':
                result['output'] = quant_lib.fit_arima(
                    params['series'],
                    tuple(params['order'])
                )
            elif operation == 'black_scholes':
                result['output'] = quant_lib.black_scholes_python(
                    params['S'], params['K'], params['T'],
                    params['sigma'], params['r'], params.get('q', 0.0)
                )
            else:
                result['error'] = f'Unknown operation: {operation}'
            
            # Add phi coherence signature
            result['phi_coherence'] = bridge.state.entanglement
            result['success'] = 'error' not in result
            
        except Exception as e:
            result['error'] = str(e)
            result['success'] = False
        
        return result
    
    return bridge


# ═══════════════════════════════════════════════════════════════════════════
# MAIN ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("[QUANTITATIVE BRIDGE] Starting...")
    bridge = create_quantitative_bridge()
    bridge.start()
    
    # Example dispatches
    test_cases = [
        {
            'operation': 'black_scholes',
            'params': {
                'S': 100.0, 'K': 100.0, 'T': 1.0,
                'sigma': 0.2, 'r': 0.05, 'q': 0.0
            }
        },
        {
            'operation': 'matrix_inverse',
            'params': {'A': [[4, 7], [2, 6]]}
        },
        {
            'operation': 'cointegration',
            'params': {
                'series1': [1.0, 1.2, 1.1, 1.3, 1.2, 1.4],
                'series2': [2.0, 2.4, 2.2, 2.6, 2.4, 2.8]
            }
        },
    ]
    
    for i, test in enumerate(test_cases):
        print(f"\n[TEST {i+1}] {test['operation']}")
        result = bridge.dispatch(test)
        print(json.dumps(result, indent=2))
    
    print(f"\n[DIAGNOSTICS]")
    print(json.dumps(bridge.get_diagnostics(), indent=2))
    
    bridge.stop()
