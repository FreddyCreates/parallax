# PARALLAX Intelligence — Web Deployment Guide

## Deploying to the Real Web (ICP Mainnet)

PARALLAX deploys as a fully on-chain application on the Internet Computer (ICP), making the intelligence system accessible at a permanent, censorship-resistant URL with no traditional hosting required.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET COMPUTER (ICP)                    │
│                                                              │
│  ┌──────────────────┐       ┌──────────────────────────┐    │
│  │  Frontend Canister│       │    Backend Canister       │    │
│  │  (Asset Canister) │◄─────►│    (Motoko Actor)        │    │
│  │                   │       │                          │    │
│  │  React + Vite     │       │  • Sovereign Intelligence│    │
│  │  Served at:       │       │  • ALOHA I Protocols     │    │
│  │  *.icp0.io        │       │  • Phantom Exchange      │    │
│  └──────────────────┘       │  • Nova Runtime          │    │
│                              │  • Trading Bridge        │    │
│                              │  Served at:              │    │
│                              │  *.raw.icp0.io           │    │
│                              └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Deploy (Manual)

```bash
# 1. Ensure icp-cli is installed
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/dfinity/icp-cli/releases/download/v0.1.0-beta.3/icp-cli-installer.sh | sh

# 2. Create or import your ICP identity
icp identity create parallax-deployer

# 3. Ensure you have cycles (ICP's gas equivalent)
# Transfer ICP to your identity and convert to cycles

# 4. Deploy to mainnet
./deploy-mainnet.sh
```

---

## CI/CD Deployment (GitHub Actions)

The workflow at `.github/workflows/deploy-icp-mainnet.yml` automates deployment on every push to `main`.

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ICP_IDENTITY_PEM` | PEM-encoded ICP identity private key for deployment |
| `BACKEND_CANISTER_ID` | Backend canister ID (after first manual deploy) |
| `FRONTEND_CANISTER_ID` | Frontend canister ID (after first manual deploy) |
| `ICP_PROJECT_ID` | Project identifier for the deployment |

### First-Time Setup

1. **Create canisters on mainnet:**
   ```bash
   icp canister create --environment mainnet frontend
   icp canister create --environment mainnet backend
   ```

2. **Note the canister IDs** and add them as GitHub Secrets.

3. **Export your deployer identity:**
   ```bash
   icp identity export parallax-deployer > identity.pem
   ```
   Add the contents as `ICP_IDENTITY_PEM` secret.

4. **Push to main** — the workflow handles the rest.

---

## Live URLs (After Deployment)

| Service | URL Pattern |
|---------|-------------|
| **Frontend (Dashboard)** | `https://<FRONTEND_CANISTER_ID>.icp0.io` |
| **Backend (Raw API)** | `https://<BACKEND_CANISTER_ID>.raw.icp0.io` |
| **Internet Identity** | `https://identity.internetcomputer.org/` |

---

## Environment Configuration

The frontend `env.json` is generated at build time:

```json
{
  "backend_host": "https://icp-api.io",
  "backend_canister_id": "<YOUR_BACKEND_CANISTER_ID>",
  "project_id": "parallax-aihftfund",
  "ii_derivation_origin": "https://<FRONTEND_CANISTER_ID>.icp0.io"
}
```

---

## What Gets Deployed

- **Backend Canister**: The entire PARALLAX intelligence system — all 80+ Motoko modules including:
  - Sovereign intelligence engine
  - ALOHA I protocols (10 multi-models)
  - Phantom Exchange suite
  - Nova Runtime
  - Trading Bridge & Resident Trader
  - Monte Carlo simulations
  - Behavioral Economics engine
  - Blockchain Languages bridge
  - Web Sphere networking

- **Frontend Canister**: React dashboard with:
  - 21 operational tabs (Substrate, Quantum, Prometheus, NOVA, etc.)
  - Real-time intelligence visualization
  - WebSphere network topology
  - Internet Identity authentication
  - 3D quantum field visualization

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Out of cycles" | Top up cycles: `icp canister deposit-cycles <amount> <canister-id>` |
| "Canister not found" | Run `icp canister create --environment mainnet <name>` first |
| "Identity not found" | Run `icp identity create <name>` or import PEM |
| Frontend shows "undefined" | Check `env.json` has correct canister IDs |
| Build fails on Motoko | Ensure `MOC_PATH`, `MOTOKO_CORE`, `MOTOKO_BASE` are set |
