#!/bin/bash
set -e
# deploy-mainnet.sh — Deploy PARALLAX Intelligence to ICP Mainnet (Real Web)
#
# Prerequisites:
#   1. icp-cli installed (https://github.com/dfinity/icp-cli)
#   2. ICP identity configured with cycles wallet
#   3. Environment variables set:
#      - BACKEND_CANISTER_ID (or will be created)
#      - FRONTEND_CANISTER_ID (or will be created)
#
# Usage:
#   ./deploy-mainnet.sh              # Deploy both canisters
#   ./deploy-mainnet.sh frontend     # Deploy frontend only
#   ./deploy-mainnet.sh backend      # Deploy backend only

echo "═══════════════════════════════════════════════════════"
echo "  PARALLAX — DEPLOYING INTELLIGENCE TO REAL WEB"
echo "═══════════════════════════════════════════════════════"
echo ""

TARGET=${1:-all}

# Verify icp-cli is available
if ! command -v icp &> /dev/null; then
    echo "ERROR: icp-cli not found. Install from https://github.com/dfinity/icp-cli"
    exit 1
fi

# Verify identity
echo "▸ Verifying ICP identity..."
icp identity whoami || { echo "ERROR: No ICP identity configured. Run 'icp identity create' first."; exit 1; }

# Set production environment variables
export STORAGE_GATEWAY_URL=https://blob.caffeine.ai
export II_URL=https://identity.internetcomputer.org/
export DFX_NETWORK=ic

# Deploy backend
if [ "$TARGET" = "all" ] || [ "$TARGET" = "backend" ]; then
    echo ""
    echo "▸ Deploying backend canister to mainnet..."
    icp deploy --environment mainnet backend
    export BACKEND_CANISTER_ID=$(icp canister settings show --environment mainnet --id-only backend)
    echo "  Backend canister ID: $BACKEND_CANISTER_ID"
fi

# Configure frontend production env
if [ "$TARGET" = "all" ] || [ "$TARGET" = "frontend" ]; then
    # Get backend canister ID if not already set
    if [ -z "$BACKEND_CANISTER_ID" ]; then
        export BACKEND_CANISTER_ID=$(icp canister settings show --environment mainnet --id-only backend)
    fi

    FRONTEND_CANISTER_ID=$(icp canister settings show --environment mainnet --id-only frontend 2>/dev/null || echo "")

    echo ""
    echo "▸ Configuring production environment..."
    cat > src/frontend/env.json <<EOF
{
  "backend_host": "https://icp-api.io",
  "backend_canister_id": "$BACKEND_CANISTER_ID",
  "project_id": "parallax-aihftfund",
  "ii_derivation_origin": "https://${FRONTEND_CANISTER_ID}.icp0.io"
}
EOF

    echo "▸ Deploying frontend canister to mainnet..."
    icp deploy --environment mainnet frontend
    FRONTEND_CANISTER_ID=$(icp canister settings show --environment mainnet --id-only frontend)
    echo "  Frontend canister ID: $FRONTEND_CANISTER_ID"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  PARALLAX INTELLIGENCE — LIVE ON THE REAL WEB"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  🌐 Frontend:  https://${FRONTEND_CANISTER_ID}.icp0.io"
echo "  🧠 Backend:   https://${BACKEND_CANISTER_ID}.raw.icp0.io"
echo "  📡 Raw API:   https://${BACKEND_CANISTER_ID}.raw.icp0.io/api"
echo ""
echo "  Internet Identity: https://identity.internetcomputer.org/"
echo ""
echo "  The organism is now sovereign on the decentralized web."
echo "═══════════════════════════════════════════════════════"
