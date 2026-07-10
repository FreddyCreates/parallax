#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const errors = [];

const readJson = (relativePath) => {
  const fullPath = path.join(root, relativePath);
  if (!fs.existsSync(fullPath)) {
    errors.push(`Missing ${relativePath}`);
    return null;
  }
  try {
    return JSON.parse(fs.readFileSync(fullPath, 'utf8'));
  } catch (error) {
    errors.push(`Invalid JSON ${relativePath}: ${error.message}`);
    return null;
  }
};

const requireArray = (object, key, label) => {
  if (!Array.isArray(object?.[key]) || object[key].length === 0) {
    errors.push(`${label}.${key} must be a non-empty array`);
    return [];
  }
  return object[key];
};

const requireFile = (relativePath) => {
  if (!fs.existsSync(path.join(root, relativePath))) errors.push(`Missing ${relativePath}`);
};

const multiLedger = readJson('config/ledgers/parallax.multiledger.ecosystem.json');
const tokenomics = readJson('config/tokenomics/parallax.agent-tokenomics.json');

if (multiLedger) {
  if (multiLedger.schema !== 'parallax.multiledger.ecosystem.v1') errors.push('Unexpected multi-ledger schema');
  if (multiLedger.public_posture !== 'paper_testnet_first') errors.push('Multi-ledger posture must remain paper_testnet_first');
  const ledgers = requireArray(multiLedger, 'ledgers', 'multiLedger');
  const gates = requireArray(multiLedger, 'global_alpha_gates', 'multiLedger');
  const requiredLedgers = ['parallax-paper-ledger', 'icp-local-ledger', 'ethereum-testnet-ledger', 'agent-credit-ledger'];
  for (const id of requiredLedgers) {
    if (!ledgers.some((ledger) => ledger.id === id)) errors.push(`Missing required ledger ${id}`);
  }
  for (const gate of ['no_live_money_movement', 'no_live_broker_routing', 'no_mainnet_bridge_in_alpha', 'tunnel_origin_locked_down']) {
    if (!gates.includes(gate)) errors.push(`Missing alpha gate ${gate}`);
  }
  for (const ledger of ledgers) {
    if (ledger.mode === 'live' || ledger.mode === 'restricted_live') errors.push(`Ledger ${ledger.id} cannot be live-enabled in alpha`);
    if (!Array.isArray(ledger.must_not_do) || ledger.must_not_do.length === 0) errors.push(`Ledger ${ledger.id} missing must_not_do boundaries`);
  }
}

if (tokenomics) {
  if (tokenomics.schema !== 'parallax.agent.tokenomics.v1') errors.push('Unexpected tokenomics schema');
  const tokenClasses = requireArray(tokenomics, 'token_classes', 'tokenomics');
  for (const symbol of ['PXUSD', 'PXICP', 'PXETH', 'PXAI', 'PXGPU', 'PXCRED']) {
    if (!tokenClasses.some((token) => token.symbol === symbol)) errors.push(`Missing token ${symbol}`);
  }
  for (const token of tokenClasses) {
    if (!['paper', 'testnet'].includes(token.mode)) errors.push(`Token ${token.symbol} is not alpha-safe mode`);
    if (!Array.isArray(token.must_not_do) || token.must_not_do.length === 0) errors.push(`Token ${token.symbol} missing must_not_do boundaries`);
    if (String(token.value_claim).toLowerCase().includes('real')) errors.push(`Token ${token.symbol} has unsafe value claim ${token.value_claim}`);
  }
}

requireFile('apps/cloudflare-gateway/wrangler.toml');
requireFile('apps/cloudflare-gateway/src/index.ts');
requireFile('apps/cloudflare-gateway/worker-configuration.d.ts');
requireFile('infra/cloudflare/tunnel/config.example.yml');
requireFile('infra/cloudflare/tunnel/docker-compose.tunnel.yml');
requireFile('docs/CLOUDFLARE_EDGE_RUNWAY.md');
requireFile('docs/MULTI_LEDGER_ECOSYSTEM.md');
requireFile('docs/AGENT_TOKEN_ECONOMICS.md');

const workerSourcePath = path.join(root, 'apps/cloudflare-gateway/src/index.ts');
if (fs.existsSync(workerSourcePath)) {
  const workerSource = fs.readFileSync(workerSourcePath, 'utf8');
  for (const route of ['/health', '/v1/ledgers', '/v1/tokens', '/v1/agents/classes', '/v1/alpha/gates', '/v1/agent-command/evaluate']) {
    if (!workerSource.includes(route)) errors.push(`Worker missing route ${route}`);
  }
  for (const boundary of ['LIVE_MODE_BLOCKED', 'EDGE_AUTH_REQUIRED', 'noLiveMoneyMovement', 'noMainnetBridgeInAlpha']) {
    if (!workerSource.includes(boundary)) errors.push(`Worker missing boundary ${boundary}`);
  }
}

if (errors.length > 0) {
  console.error('PARALLAX product validation failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log('PARALLAX product validation passed: multi-ledger ecosystem, tokenomics, Cloudflare gateway, tunnel templates, and docs are present.');
