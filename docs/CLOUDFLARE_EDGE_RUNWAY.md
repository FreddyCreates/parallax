# PARALLAX Cloudflare Edge Runway

PARALLAX now has a Cloudflare edge gateway plan and repo-ready Worker package.

This is designed for the path:

```text
Cloudflare Worker
-> authenticated edge routes
-> Cloudflare Tunnel
-> local/backend PARALLAX services
-> receipt ledger / Control Tower
```

## Source files

| Artifact | Purpose |
|---|---|
| `apps/cloudflare-gateway/` | Cloudflare Worker gateway package |
| `apps/cloudflare-gateway/wrangler.toml` | Wrangler configuration |
| `apps/cloudflare-gateway/src/index.ts` | edge gateway routes |
| `infra/cloudflare/tunnel/config.example.yml` | Cloudflare Tunnel template |
| `infra/cloudflare/tunnel/docker-compose.tunnel.yml` | cloudflared container template |

## Worker routes

| Route | Method | Purpose |
|---|---:|---|
| `/health` | GET | gateway health, alpha gates, tunnel expected host |
| `/v1/ledgers` | GET | multi-ledger registry |
| `/v1/tokens` | GET | token class registry |
| `/v1/agents/classes` | GET | AI-agent wallet class registry |
| `/v1/alpha/gates` | GET | alpha safety gates |
| `/v1/agent-command/evaluate` | POST | edge-side policy precheck for agent commands |
| `/v1/proxy/*` | any | guarded proxy to PARALLAX core origin through tunnel/private origin |

## Required secrets

Set the mutation token in Cloudflare:

```bash
cd apps/cloudflare-gateway
wrangler secret put PARALLAX_EDGE_TOKEN
```

Do not commit secrets.

## Local Worker run

```bash
cd apps/cloudflare-gateway
pnpm install
pnpm dev
```

## Deploy Worker

```bash
cd apps/cloudflare-gateway
pnpm deploy
```

Before production deployment, update:

- `PARALLAX_CORE_URL`,
- `PARALLAX_TUNNEL_EXPECTED_HOST`,
- `PARALLAX_ALLOWED_ORIGINS`,
- route/custom domain,
- Cloudflare account/zone settings.

## Tunnel setup

Create tunnel in your Cloudflare account:

```bash
cloudflared tunnel login
cloudflared tunnel create parallax-alpha
cloudflared tunnel route dns parallax-alpha parallax-alpha.example.com
cloudflared tunnel route dns parallax-alpha parallax-api.example.com
```

Copy the generated tunnel id and credentials into your local/server cloudflared config location. Then copy:

```text
infra/cloudflare/tunnel/config.example.yml
```

into your real config path and replace:

- `PARALLAX_TUNNEL_ID`,
- `parallax-alpha.example.com`,
- `parallax-api.example.com`,
- service ports.

Run with cloudflared:

```bash
cloudflared tunnel --config config.yml run
```

Or with Docker:

```bash
cd infra/cloudflare/tunnel
cp config.example.yml config.yml
mkdir -p credentials
# copy real tunnel JSON credentials into ./credentials/
docker compose -f docker-compose.tunnel.yml up -d
```

## Origin lockdown checklist

- Keep backend bound to localhost or private network where possible.
- Do not expose dev ports directly to the public internet.
- Require Worker auth for mutations.
- Keep Cloudflare Access/WAF in front of operator routes.
- Keep live broker/custody routes disabled during alpha.
- Log request ids and receipt ids across Worker, backend, and receipt ledger.

## Showcase threshold

PARALLAX becomes showcase-ready when these gates are green:

1. Worker deploys to Cloudflare preview or custom route.
2. `/health`, `/v1/ledgers`, `/v1/tokens`, `/v1/agents/classes` return valid JSON.
3. `/v1/agent-command/evaluate` rejects live/restricted-live commands.
4. Mutation routes require bearer auth.
5. Tunnel routes to local/backend service without exposing raw origin.
6. Control Tower reads the Worker registry.
7. Receipt ledger records any mutating flow.
8. README language stays paper/testnet-first.

## Current status

Repo-ready. Not yet claimed deployed.

The Worker and tunnel templates are present, but real deployment requires your Cloudflare account, zone, tunnel id, credentials, secrets, and domain choices.
