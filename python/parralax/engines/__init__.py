"""
PARALLAX AI ENGINES — Real Production Intelligence Systems
============================================================

Multiple AI reasoning engines for the PARALLAX fund:
- Neural network portfolio optimization
- Reinforcement learning execution
- Deep learning signal processing
- Quantitative finance modeling
- Risk calculation engines
- Sentiment analysis and NLP
- Market microstructure intelligence
"""

from .neural_portfolio import NeuralPortfolioEngine
from .rl_execution import RLExecutionEngine
from .signal_processor import DeepSignalProcessor
from .quant_models import QuantitativeEngine
from .risk_engine import AdvancedRiskEngine
from .nlp_sentiment import NLPSentimentEngine
from .market_intelligence import MarketIntelligenceEngine
from .alpha_discovery import AlphaDiscoveryEngine
from .regime_detector import RegimeDetectionEngine
from .orchestrator import EngineOrchestrator

__all__ = [
    "NeuralPortfolioEngine",
    "RLExecutionEngine",
    "DeepSignalProcessor",
    "QuantitativeEngine",
    "AdvancedRiskEngine",
    "NLPSentimentEngine",
    "MarketIntelligenceEngine",
    "AlphaDiscoveryEngine",
    "RegimeDetectionEngine",
    "EngineOrchestrator",
]
