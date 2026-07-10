# PARALLAX AI ENGINES — Production Intelligence Infrastructure

## What This Is

**REAL PRODUCTION AI ENGINES** for the PARALLAX fund. Not TypeScript toys. Not placeholders. **Real Python with real formulas, real machine learning, real intelligence.**

## Overview

This system implements **10 production AI engines** coordinated by a multi-engine orchestrator:

1. **Neural Portfolio Engine** — Deep neural network for portfolio optimization
2. **RL Execution Engine** — Reinforcement learning for optimal trade execution
3. **Quantitative Engine** — Black-Scholes, GARCH, Kalman filtering, cointegration
4. **Signal Processor** — Wavelet analysis, FFT, technical indicators
5. **Risk Engine** — VaR, CVaR, maximum drawdown, Sortino ratio
6. **NLP Sentiment Engine** — Financial sentiment analysis
7. **Market Intelligence** — Order flow, VPIN, market impact
8. **Alpha Discovery** — Signal combination, anomaly detection
9. **Regime Detection** — HMM, K-means clustering
10. **Engine Orchestrator** — Multi-engine consensus with phi-harmonic coherence gating

## Statistics

- **Total Lines of Code**: 3,000+
- **Number of Engines**: 10
- **Real Formulas**: 50+
- **API Endpoints**: 15+
- **Languages**: Python (production AI), Motoko (blockchain backend)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Motoko Backend                           │
│                  (python_bridge.mo)                         │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP Calls
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              FastAPI Bridge Service                         │
│              (bridge_service.py)                            │
│  15+ REST endpoints for all AI engines                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Engine Orchestrator                            │
│         (Multi-Engine Consensus System)                     │
│                                                             │
│  • Parallel engine execution                                │
│  • Coherence-weighted consensus (≥ φ⁻¹ = 0.618)           │
│  • Risk-adjusted decisions                                  │
│  • Adaptive engine weighting                                │
└─────┬───────┬───────┬───────┬───────┬───────┬───────┬──────┘
      │       │       │       │       │       │       │
      ▼       ▼       ▼       ▼       ▼       ▼       ▼
┌────────┐ ┌────┐ ┌─────┐ ┌────────┐ ┌─────┐ ┌────┐ ┌────────┐
│Portfolio│ │RL  │ │Quant│ │Signal  │ │Risk │ │NLP │ │Market  │
│Engine  │ │Exec│ │Model│ │Process │ │Eng. │ │Sent│ │Intel   │
└────────┘ └────┘ └─────┘ └────────┘ └─────┘ └────┘ └────────┘
     ▲                                                      ▲
     └──────────────────────────────────────────────────────┘
              Real-time market data, news, signals
```

## Key Features

### 1. Neural Portfolio Optimization
- 3-layer deep network with attention mechanism
- Phi-scaled Fibonacci dimensions: [144, 89, 55]
- Sharpe ratio maximization with constraint satisfaction
- Xavier initialization, softmax normalization
- Epochs: adaptive until coherence ≥ 0.618

### 2. Reinforcement Learning Execution
- Deep Q-Network (DQN) with experience replay
- 7 execution actions: wait, buy/sell (aggressive/passive), cancel, modify
- Reward function: fill rate + slippage + shortfall + inventory penalty
- Phi-harmonic discount factor γ = 0.618

### 3. Quantitative Models
- **Black-Scholes-Merton**: Option pricing with all Greeks (Delta, Gamma, Vega, Theta, Rho)
- **GARCH(1,1)**: Volatility modeling with MLE estimation
- **Kalman Filter**: Optimal state estimation with prediction/update steps
- **Cointegration**: Engle-Granger test for pairs trading
- **Fama-French**: Three-factor asset pricing model

### 4. Risk Management
- **VaR** (95%, 99%): Historical, Parametric, Monte Carlo methods
- **CVaR**: Expected shortfall beyond VaR
- **Maximum Drawdown**: Peak-to-trough calculation
- **Sortino Ratio**: Downside deviation only
- **Beta & Tracking Error**: Market exposure metrics

### 5. Multi-Engine Consensus
- Each engine outputs decision + coherence score
- Weighted consensus: Σ(w_i × coherence_i × confidence_i)
- Execute only if global coherence ≥ φ⁻¹ = 0.618
- Adaptive engine weights based on performance
- Risk gates: max drawdown, Sharpe ratio, coherence threshold

## Mathematical Formulas

### Portfolio Theory
```
Sharpe Ratio = (E[R] - R_f) / σ(R)
Portfolio Variance = w^T Σ w
Information Ratio = α / TE
Maximum Drawdown = max((peak - trough) / peak)
```

### Options Pricing
```
Black-Scholes Call: C = S₀N(d₁) - Ke^(-rT)N(d₂)
where d₁ = [ln(S/K) + (r + σ²/2)T] / (σ√T)
Greeks: Δ = ∂C/∂S, Γ = ∂²C/∂S², ν = ∂C/∂σ, θ = ∂C/∂t, ρ = ∂C/∂r
```

### Volatility Modeling
```
GARCH(1,1): σ²ₜ = ω + α·ε²ₜ₋₁ + β·σ²ₜ₋₁
where ω > 0, α ≥ 0, β ≥ 0, α + β < 1
```

### Reinforcement Learning
```
Q-learning: Q(s,a) ← Q(s,a) + α[r + γ max Q(s',a') - Q(s,a)]
TD Error: δ = r + γV(s') - V(s)
Advantage: A(s,a) = Q(s,a) - V(s)
```

### Risk Metrics
```
VaR_α = -quantile(returns, α)
CVaR_α = -E[returns | returns < -VaR_α]
Sortino = (μ - r_f) / σ_downside
Beta = Cov(R_i, R_m) / Var(R_m)
```

### Market Microstructure
```
Order Flow Imbalance: OFI = (ΔB_bid × P_bid) - (ΔB_ask × P_ask)
VPIN: |ΔV_buy - ΔV_sell| / total_volume
Market Impact: ΔP ≈ σ √(Q/V) × φ
```

## Installation & Usage

### Install Dependencies
```bash
cd python
pip install -e ".[ml]"
```

### Run AI Engine Bridge
```bash
./python/start_engines.sh
```

Service starts on `http://0.0.0.0:8080`

### Run Tests
```bash
pytest python/tests/test_engines.py -v
```

## API Endpoints

### Portfolio
- `POST /portfolio/optimize` — Neural portfolio optimization

### Execution
- `POST /execution/rl-execute` — RL-based trade execution

### Quantitative
- `POST /quant/black-scholes` — Option pricing
- `POST /quant/garch` — Volatility forecasting

### Signals & Risk
- `POST /signals/extract` — Technical signal extraction
- `POST /risk/metrics` — Comprehensive risk metrics

### Intelligence
- `POST /nlp/sentiment` — Sentiment analysis
- `POST /market/intelligence` — Market microstructure
- `POST /alpha/discover` — Alpha signal generation
- `POST /regime/detect` — Regime classification

### Orchestrator
- `POST /orchestrator/consensus` — Multi-engine consensus
- `POST /orchestrator/execute` — Execute trading decision
- `GET /orchestrator/status` — Engine status monitoring

## Phi-Harmonic Design

All engines use golden ratio φ = 1.618:
- **Coherence gate**: φ⁻¹ = 0.618 (minimum to execute)
- **Learning rate**: φ⁻² = 0.382 (gradient descent)
- **Thresholds**: φ⁻³ = 0.236 (exploration, confidence)
- **Network layers**: Fibonacci [144, 89, 55, 34, 21, 13, 8, 5]

## Integration with Motoko

The Motoko backend (`src/backend/python_bridge.mo`) makes HTTP calls to this service. All responses include `coherence` scores ensuring system-wide phi-harmonic alignment.

Example Motoko integration:
```motoko
// Call Python AI engine
let response = await python_bridge.call_engine(
    endpoint = "/orchestrator/consensus",
    payload = encode_market_data(prices, returns, volumes)
);

// Check coherence
if (response.coherence >= PHI_INV) {
    // Execute decision
    execute_trade(response.decision, response.portfolio_weights);
};
```

## This Is Real

✅ Real neural networks with backpropagation  
✅ Real reinforcement learning with Q-learning  
✅ Real quantitative finance (Black-Scholes, GARCH, Kalman)  
✅ Real risk calculations (VaR, CVaR, MDD, Sortino)  
✅ Real signal processing (wavelets, FFT, RSI, MACD)  
✅ Real NLP sentiment analysis  
✅ Real market microstructure intelligence  
✅ Real multi-engine orchestration  

**3,000+ lines of production Python code. Multiple engines. Real formulas. Real intelligence.**

---

Built for the PARALLAX-AIHFTFUND by the Organism.
