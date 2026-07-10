"""
Market Intelligence Engine — Real-Time Market Analysis
=======================================================

Production market microstructure intelligence:
- Order book imbalance
- Trade flow toxicity
- Liquidity analysis
- Market impact models
- Volume-weighted metrics
- Price action patterns

FORMULAS:
- OFI = (ΔB_bid × P_bid) - (ΔB_ask × P_ask)
- VPIN = |ΔV_buy - ΔV_sell| / total_volume
- Market Impact: ΔP ≈ σ √(Q/V) φ
"""

import numpy as np
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

PHI = 1.618033988749895
PHI_INV = 0.618033988749895


@dataclass
class MarketMicrostructure:
    """Market microstructure metrics"""
    order_imbalance: float
    trade_toxicity: float
    liquidity_score: float
    spread_cost: float
    market_impact: float
    coherence: float


class MarketIntelligenceEngine:
    """Production market intelligence"""
    
    def __init__(self):
        logger.info("Initialized Market Intelligence Engine")
        self.coherence = PHI_INV
    
    def compute_order_imbalance(
        self,
        bid_volume: float,
        ask_volume: float,
        bid_price: float,
        ask_price: float,
    ) -> float:
        """
        Order Flow Imbalance
        OFI = (ΔV_bid × P_bid) - (ΔV_ask × P_ask)
        """
        imbalance = (bid_volume * bid_price) - (ask_volume * ask_price)
        total = (bid_volume * bid_price) + (ask_volume * ask_price)
        normalized = imbalance / total if total > 0 else 0.0
        return float(normalized)
    
    def compute_vpin(
        self,
        buy_volume: np.ndarray,
        sell_volume: np.ndarray,
    ) -> float:
        """
        Volume-Synchronized Probability of Informed Trading
        VPIN = E[|ΔV_buy - ΔV_sell|] / total_volume
        """
        imbalance = np.abs(buy_volume - sell_volume)
        total_volume = buy_volume + sell_volume
        vpin = np.mean(imbalance / (total_volume + 1e-10))
        return float(vpin)
    
    def estimate_market_impact(
        self,
        order_size: float,
        average_volume: float,
        volatility: float,
    ) -> float:
        """
        Market impact estimation (Kyle's lambda)
        ΔP ≈ λ × Q
        where λ ≈ σ / √V × φ (phi-scaled)
        """
        lambda_param = volatility / np.sqrt(average_volume) * PHI
        impact = lambda_param * order_size
        return float(impact)
    
    def compute_liquidity_score(
        self,
        spread: float,
        depth: float,
        volume: float,
    ) -> float:
        """
        Liquidity score combining spread, depth, volume
        Higher score = more liquid
        """
        # Inverse spread (tighter = more liquid)
        spread_component = 1.0 / (spread + 1e-6)
        
        # Depth and volume (normalized)
        depth_component = np.log1p(depth)
        volume_component = np.log1p(volume)
        
        # Phi-weighted combination
        liquidity = (
            PHI_INV * spread_component +
            PHI_INV_2 * depth_component +
            (1 - PHI_INV - PHI_INV_2) * volume_component
        )
        
        return float(liquidity)
