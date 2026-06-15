"""
Alpha Discovery Engine — Real Alpha Generation
===============================================

Production alpha discovery:
- Statistical arbitrage
- Factor discovery
- Anomaly detection
- Pattern mining
- Alpha decay analysis
- Signal combination

FORMULAS:
- IC = Corr(forecast, realized)
- IR = IC × √BR (information ratio)
- Alpha decay: α(t) = α₀ × e^(-λt)
"""

import numpy as np
from scipy import stats
from typing import Dict, List, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

PHI_INV = 0.618033988749895


@dataclass
class AlphaSignal:
    """Alpha signal with metadata"""
    value: float
    confidence: float
    information_coefficient: float
    expected_return: float
    decay_rate: float


class AlphaDiscoveryEngine:
    """Alpha generation and discovery"""
    
    def __init__(self):
        logger.info("Initialized Alpha Discovery Engine")
        self.coherence = PHI_INV
    
    def compute_information_coefficient(
        self,
        forecasts: np.ndarray,
        realized: np.ndarray,
    ) -> float:
        """
        Information Coefficient = Corr(forecast, realized)
        Measures predictive power
        """
        if len(forecasts) != len(realized):
            return 0.0
        
        ic = np.corrcoef(forecasts, realized)[0, 1]
        return float(ic) if not np.isnan(ic) else 0.0
    
    def combine_alphas(
        self,
        alphas: List[float],
        weights: Optional[List[float]] = None,
    ) -> float:
        """
        Combine multiple alpha signals
        """
        if weights is None:
            # Equal weight
            weights = [1.0 / len(alphas)] * len(alphas)
        
        combined = np.dot(alphas, weights)
        return float(combined)
    
    def detect_anomaly(
        self,
        data: np.ndarray,
        threshold: float = 3.0,
    ) -> bool:
        """
        Anomaly detection using z-score
        """
        if len(data) < 2:
            return False
        
        mean = np.mean(data[:-1])
        std = np.std(data[:-1])
        z_score = abs((data[-1] - mean) / (std + 1e-10))
        
        return z_score > threshold
