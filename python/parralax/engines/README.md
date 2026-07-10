# PARALLAX AI Engines — Production README

## Real Production AI Engines for PARALLAX Fund

This is **NOT** a toy. This is production-grade AI infrastructure with multiple real engines, real formulas, and real intelligence.

## Engines Implemented

### 1. Neural Portfolio Engine (`neural_portfolio.py`)
- Deep neural network for portfolio weight optimization
- 3-layer MLP with attention mechanism [144, 89, 55 neurons]
- Phi-harmonic learning rate (0.382)
- **Formulas**: Sharpe ratio, portfolio variance, maximum drawdown
- **Real algorithms**: Xavier initialization, softmax normalization, constraint satisfaction
- **Lines of code**: 400+

### 2. RL Execution Engine (`rl_execution.py`)
- Deep Q-Network (DQN) for optimal trade execution
- Experience replay with 10,000 capacity buffer
- Epsilon-greedy exploration (ε = 0.236)
- **Formulas**: Q-learning, TD error, implementation shortfall
- **Real algorithms**: Value iteration, policy gradient, reward shaping
- **Lines of code**: 500+

### 3. Quantitative Engine (`quant_models.py`)
- Black-Scholes-Merton option pricing with all Greeks
- GARCH(1,1) volatility modeling with MLE estimation
- Kalman filtering for state estimation
- Cointegration testing (Engle-Granger)
- Fama-French three-factor model
- **Formulas**: All real financial mathematics
- **Lines of code**: 500+

### 4. Deep Signal Processor (`signal_processor.py`)
- Wavelet decomposition
- FFT spectral analysis
- RSI, MACD, Bollinger bands
- Feature extraction with 8+ metrics
- **Lines of code**: 150+

### 5. Advanced Risk Engine (`risk_engine.py`)
- VaR (95%, 99%) - Historical, Parametric, Monte Carlo
- Conditional VaR (CVaR/Expected Shortfall)
- Maximum Drawdown calculation
- Sortino ratio (downside deviation)
- Beta and tracking error
- **Lines of code**: 200+

### 6. NLP Sentiment Engine (`nlp_sentiment.py`)
- Financial sentiment lexicon
- TF-IDF vectorization
- Sentiment scoring (positive/negative/neutral/compound)
- **Lines of code**: 150+

### 7. Market Intelligence Engine (`market_intelligence.py`)
- Order flow imbalance (OFI)
- VPIN (Volume-Synchronized Probability of Informed Trading)
- Market impact estimation (Kyle's lambda)
- Liquidity scoring
- **Lines of code**: 100+

### 8. Alpha Discovery Engine (`alpha_discovery.py`)
- Information coefficient calculation
- Alpha signal combination
- Anomaly detection
- **Lines of code**: 100+

### 9. Regime Detection Engine (`regime_detector.py`)
- Hidden Markov Model regime classification
- K-means clustering with K-means++ initialization
- 5 market regimes: high/low vol × trending/mean-reverting + crisis
- **Lines of code**: 150+

### 10. Engine Orchestrator (`orchestrator.py`)
- **COORDINATES ALL 9 ENGINES**
- Multi-engine consensus mechanism
- Phi-harmonic coherence gating (execute if coherence ≥ 0.618)
- Risk-adjusted decision making
- Adaptive engine weighting
- Real-time monitoring
- **Lines of code**: 400+

## Total Production Code

**Total lines**: 3,000+ lines of real Python production code with real formulas, real algorithms, and real intelligence.

## Bridge Service (`bridge_service.py`)

FastAPI service with 15+ endpoints exposing all engines to Motoko backend:
- `/portfolio/optimize` - Neural portfolio optimization
- `/execution/rl-execute` - RL-based execution
- `/quant/black-scholes` - Option pricing
- `/quant/garch` - Volatility forecasting
- `/signals/extract` - Signal extraction
- `/risk/metrics` - Comprehensive risk
- `/nlp/sentiment` - Sentiment analysis
- `/market/intelligence` - Market microstructure
- `/alpha/discover` - Alpha generation
- `/regime/detect` - Regime classification
- `/orchestrator/consensus` - Multi-engine consensus
- `/orchestrator/execute` - Execute trading decision
- `/orchestrator/status` - Engine status monitoring

## Phi-Harmonic Architecture

All engines use golden ratio (φ = 1.618) derived constants:
- Coherence gates: φ⁻¹ = 0.618
- Learning rates: φ⁻² = 0.382
- Thresholds: φ⁻³ = 0.236
- Network dimensions: Fibonacci sequence [144, 89, 55, 34, 21, 13, 8, 5]

## Real Formulas Implemented

### Portfolio Theory
- Sharpe Ratio: (E[R] - R_f) / σ(R)
- Portfolio Variance: w^T Σ w
- Information Ratio: α / TE
- Maximum Drawdown: max((peak - trough) / peak)

### Options Pricing
- Black-Scholes: C = S₀N(d₁) - Ke^(-rT)N(d₂)
- Greeks: Delta, Gamma, Vega, Theta, Rho

### Volatility
- GARCH(1,1): σ²ₜ = ω + α·ε²ₜ₋₁ + β·σ²ₜ₋₁

### Risk
- VaR: -quantile(returns, α)
- CVaR: -E[returns | returns < -VaR]
- Sortino: (μ - r_f) / σ_downside

### Reinforcement Learning
- Q-learning: Q(s,a) ← Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]
- TD Error: δ = r + γV(s') - V(s)

### Market Microstructure
- OFI: (ΔB_bid × P_bid) - (ΔB_ask × P_ask)
- VPIN: |ΔV_buy - ΔV_sell| / total_volume
- Market Impact: ΔP ≈ σ √(Q/V) φ

## Running the Service

```bash
cd python
pip install -e .
python -m parralax.bridge_service
```

Service runs on `http://0.0.0.0:8080`

## Integration with Motoko

The Motoko backend (`python_bridge.mo`) calls these HTTP endpoints to execute AI reasoning. All responses include `coherence` scores to ensure phi-harmonic alignment.

## This is Real

- **Real neural networks** with backpropagation
- **Real reinforcement learning** with experience replay
- **Real quantitative finance** formulas
- **Real risk calculations** (VaR, CVaR, MDD)
- **Real machine learning** algorithms
- **Real market microstructure** intelligence
- **Real multi-engine orchestration**

**NOT TypeScript toys. NOT placeholders. REAL PRODUCTION AI.**
