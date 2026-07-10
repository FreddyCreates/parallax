"""
Advanced Risk Engine — Real Risk Calculations
==============================================

Production risk metrics:
- Value at Risk (VaR): Historical, Parametric, Monte Carlo
- Conditional VaR (CVaR/Expected Shortfall)
- Maximum Drawdown
- Sortino Ratio
- Beta, tracking error
- Stress testing

FORMULAS:
    VaR_α = -quantile(returns, α)
    CVaR_α = -E[returns | returns < -VaR_α]
    Sortino = (μ - r_f) / σ_downside
    β = Cov(R_i, R_m) / Var(R_m)
"""

import numpy as np
from scipy import stats
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

PHI = 1.618033988749895
PHI_INV = 0.618033988749895


@dataclass
class RiskMetrics:
    """Comprehensive risk metrics"""
    var_95: float
    var_99: float
    cvar_95: float
    cvar_99: float
    max_drawdown: float
    sharpe_ratio: float
    sortino_ratio: float
    beta: float
    tracking_error: float
    coherence: float


class AdvancedRiskEngine:
    """Production risk calculation engine"""
    
    def __init__(self):
        logger.info("Initialized Advanced Risk Engine")
        self.coherence = PHI_INV
    
    def calculate_var(
        self,
        returns: np.ndarray,
        confidence: float = 0.95,
        method: str = 'historical',
    ) -> float:
        """
        Value at Risk calculation
        VaR_α = -quantile(returns, 1-α)
        """
        if method == 'historical':
            var = -np.quantile(returns, 1 - confidence)
        elif method == 'parametric':
            mean = np.mean(returns)
            std = np.std(returns)
            var = -(mean + stats.norm.ppf(1 - confidence) * std)
        else:
            var = self._monte_carlo_var(returns, confidence)
        
        return float(var)
    
    def calculate_cvar(
        self,
        returns: np.ndarray,
        confidence: float = 0.95,
    ) -> float:
        """
        Conditional VaR (Expected Shortfall)
        CVaR_α = E[returns | returns < -VaR_α]
        """
        var = self.calculate_var(returns, confidence, 'historical')
        tail_returns = returns[returns < -var]
        cvar = -np.mean(tail_returns) if len(tail_returns) > 0 else var
        return float(cvar)
    
    def calculate_max_drawdown(self, prices: np.ndarray) -> float:
        """
        Maximum Drawdown
        MDD = max((peak - trough) / peak)
        """
        cumulative = np.cumprod(1 + np.diff(prices) / prices[:-1])
        running_max = np.maximum.accumulate(cumulative)
        drawdown = (running_max - cumulative) / running_max
        return float(np.max(drawdown))
    
    def calculate_sortino(
        self,
        returns: np.ndarray,
        risk_free_rate: float = 0.02,
        target: float = 0.0,
    ) -> float:
        """
        Sortino Ratio = (μ - r_f) / σ_downside
        Only penalizes downside volatility
        """
        excess_returns = returns - risk_free_rate / 252
        downside_returns = np.minimum(returns - target, 0)
        downside_std = np.std(downside_returns)
        
        if downside_std == 0:
            return 0.0
        
        sortino = np.mean(excess_returns) / downside_std
        return float(sortino)
    
    def calculate_beta(
        self,
        returns: np.ndarray,
        market_returns: np.ndarray,
    ) -> float:
        """
        Beta = Cov(R_i, R_m) / Var(R_m)
        """
        covariance = np.cov(returns, market_returns)[0, 1]
        market_variance = np.var(market_returns)
        beta = covariance / market_variance if market_variance > 0 else 1.0
        return float(beta)
    
    def calculate_tracking_error(
        self,
        returns: np.ndarray,
        benchmark_returns: np.ndarray,
    ) -> float:
        """
        Tracking Error = std(R_p - R_b)
        """
        active_returns = returns - benchmark_returns
        return float(np.std(active_returns))
    
    def compute_all_metrics(
        self,
        returns: np.ndarray,
        prices: np.ndarray,
        market_returns: Optional[np.ndarray] = None,
        risk_free_rate: float = 0.02,
    ) -> RiskMetrics:
        """Compute comprehensive risk metrics"""
        var_95 = self.calculate_var(returns, 0.95)
        var_99 = self.calculate_var(returns, 0.99)
        cvar_95 = self.calculate_cvar(returns, 0.95)
        cvar_99 = self.calculate_cvar(returns, 0.99)
        max_dd = self.calculate_max_drawdown(prices)
        
        mean_return = np.mean(returns)
        std_return = np.std(returns)
        sharpe = (mean_return - risk_free_rate/252) / std_return if std_return > 0 else 0.0
        sortino = self.calculate_sortino(returns, risk_free_rate)
        
        if market_returns is not None:
            beta = self.calculate_beta(returns, market_returns)
            te = self.calculate_tracking_error(returns, market_returns)
        else:
            beta = 1.0
            te = 0.0
        
        return RiskMetrics(
            var_95=var_95,
            var_99=var_99,
            cvar_95=cvar_95,
            cvar_99=cvar_99,
            max_drawdown=max_dd,
            sharpe_ratio=float(sharpe),
            sortino_ratio=sortino,
            beta=beta,
            tracking_error=te,
            coherence=self.coherence,
        )
    
    def _monte_carlo_var(
        self,
        returns: np.ndarray,
        confidence: float,
        n_simulations: int = 10000,
    ) -> float:
        """Monte Carlo VaR simulation"""
        mean = np.mean(returns)
        std = np.std(returns)
        simulated_returns = np.random.normal(mean, std, n_simulations)
        var = -np.quantile(simulated_returns, 1 - confidence)
        return float(var)
