#!/usr/bin/env bash
# Start PARALLAX AI Engine Bridge Service

set -e

echo "=========================================="
echo "PARALLAX AI Engine Bridge Service"
echo "Production AI Engines for PARALLAX Fund"
echo "=========================================="
echo ""
echo "Engines:"
echo "  1. Neural Portfolio Optimization"
echo "  2. RL Execution Engine"
echo "  3. Quantitative Models (Black-Scholes, GARCH, Kalman, etc.)"
echo "  4. Deep Signal Processing"
echo "  5. Advanced Risk Engine (VaR, CVaR, MDD, etc.)"
echo "  6. NLP Sentiment Analysis"
echo "  7. Market Intelligence"
echo "  8. Alpha Discovery"
echo "  9. Regime Detection"
echo "  10. Engine Orchestrator (Multi-Engine Consensus)"
echo ""
echo "Starting service on http://0.0.0.0:8080"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Install dependencies if needed
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

echo "Activating virtual environment..."
source .venv/bin/activate

echo "Installing dependencies..."
pip install -q --upgrade pip
pip install -q -e ".[ml]"

echo ""
echo "Launching AI engine bridge..."
python -m parralax.bridge_service
