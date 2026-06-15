"""
Test Suite for PARALLAX AI Engines
"""

import numpy as np
import pytest
from parralax.engines import (
    NeuralPortfolioEngine,
    RLExecutionEngine,
    QuantitativeEngine,
    DeepSignalProcessor,
    AdvancedRiskEngine,
    NLPSentimentEngine,
    MarketIntelligenceEngine,
    AlphaDiscoveryEngine,
    RegimeDetectionEngine,
    EngineOrchestrator,
)


def test_neural_portfolio_engine():
    """Test neural portfolio optimization"""
    engine = NeuralPortfolioEngine(num_assets=5)
    
    # Generate synthetic data
    returns = np.random.randn(100, 5) * 0.01
    cov_matrix = np.cov(returns.T)
    corr_matrix = np.corrcoef(returns.T)
    
    # Optimize
    result = engine.optimize(returns, cov_matrix, corr_matrix, epochs=10)
    
    assert result.weights.shape == (5,)
    assert np.isclose(np.sum(result.weights), 1.0, atol=0.01)
    assert result.coherence >= 0.0
    assert result.sharpe is not None


def test_quantitative_engine():
    """Test quantitative models"""
    engine = QuantitativeEngine()
    
    # Test Black-Scholes
    pricing = engine.black_scholes(
        S=100.0, K=100.0, T=1.0, r=0.05, sigma=0.2
    )
    
    assert pricing.call_price > 0
    assert pricing.put_price > 0
    assert 0 <= pricing.delta <= 1
    assert pricing.gamma > 0
    
    # Test GARCH
    returns = np.random.randn(200) * 0.02
    omega, alpha, beta, cond_vars = engine.estimate_garch(returns)
    
    assert omega > 0
    assert alpha >= 0
    assert beta >= 0
    assert alpha + beta < 1.0


def test_risk_engine():
    """Test risk calculations"""
    engine = AdvancedRiskEngine()
    
    returns = np.random.randn(500) * 0.01
    prices = 100 * np.cumprod(1 + returns)
    
    metrics = engine.compute_all_metrics(returns, prices)
    
    assert metrics.var_95 > 0
    assert metrics.cvar_95 >= metrics.var_95
    assert 0 <= metrics.max_drawdown <= 1
    assert metrics.coherence > 0


def test_signal_processor():
    """Test signal processing"""
    engine = DeepSignalProcessor()
    
    # Generate price series
    prices = 100 + np.cumsum(np.random.randn(200) * 0.5)
    
    features = engine.extract_features(prices)
    
    assert features.volatility > 0
    assert -1 <= features.mean_reversion <= 1
    assert features.coherence > 0


def test_nlp_sentiment():
    """Test NLP sentiment analysis"""
    engine = NLPSentimentEngine()
    
    positive_text = "bullish rally strong growth profit surge upgrade"
    negative_text = "bearish crash decline loss drop weak downgrade"
    
    pos_sentiment = engine.analyze_sentiment(positive_text)
    neg_sentiment = engine.analyze_sentiment(negative_text)
    
    assert pos_sentiment.compound > 0
    assert neg_sentiment.compound < 0
    assert pos_sentiment.positive > neg_sentiment.positive


def test_market_intelligence():
    """Test market intelligence"""
    engine = MarketIntelligenceEngine()
    
    imbalance = engine.compute_order_imbalance(
        bid_volume=1000, ask_volume=800,
        bid_price=100.0, ask_price=100.1
    )
    
    assert -1 <= imbalance <= 1


def test_alpha_discovery():
    """Test alpha discovery"""
    engine = AlphaDiscoveryEngine()
    
    forecasts = np.random.randn(100)
    realized = forecasts + np.random.randn(100) * 0.5
    
    ic = engine.compute_information_coefficient(forecasts, realized)
    
    assert -1 <= ic <= 1


def test_regime_detection():
    """Test regime detection"""
    engine = RegimeDetectionEngine()
    
    # Generate regime-switching returns
    returns = np.concatenate([
        np.random.randn(100) * 0.01,  # Low vol
        np.random.randn(100) * 0.03,  # High vol
    ])
    
    regime = engine.detect_regime(returns)
    
    assert regime is not None


def test_engine_orchestrator():
    """Test engine orchestrator"""
    orchestrator = EngineOrchestrator(num_assets=5)
    
    # Generate market data
    prices = np.random.randn(5) * 10 + 100
    returns = np.random.randn(100, 5) * 0.01
    volumes = np.random.rand(5) * 1000000
    
    market_data = {
        'prices': prices,
        'returns': returns,
        'volumes': volumes,
    }
    
    # Compute consensus
    consensus = orchestrator.compute_consensus(market_data)
    
    assert consensus.decision is not None
    assert 0 <= consensus.confidence <= 1
    assert 0 <= consensus.coherence <= 1
    assert consensus.regime is not None
    
    # Check orchestrator status
    summary = orchestrator.get_summary()
    assert summary['global_coherence'] > 0
    assert summary['num_engines'] == 9


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
