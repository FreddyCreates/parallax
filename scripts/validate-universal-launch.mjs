import fs from 'node:fs';

const requiredFiles = [
  'config/chains/parallax.chain-registry.json',
  'config/wallets/parallax.wallet-registry.json',
  'config/assets/parallax.launch-asset-universe.json',
  'config/agents/parallax.finance-agent-world.json',
  'apps/universal-trading/index.html',
  'apps/universal-trading/app.js',
  'apps/universal-trading/styles.css',
  'docs/UNIVERSAL_TRADING_LAUNCH_PLATFORM.md',
  'receipts/universal-trading-launch-0.4.0-alpha.0.json'
];

const errors = [];
for (const file of requiredFiles) {
  if (!fs.existsSync(file)) errors.push(`missing required file: ${file}`);
}

function readJson(path) {
  return JSON.parse(fs.readFileSync(path, 'utf8'));
}

const chains = readJson('config/chains/parallax.chain-registry.json');
const wallets = readJson('config/wallets/parallax.wallet-registry.json');
const assets = readJson('config/assets/parallax.launch-asset-universe.json');
const agents = readJson('config/agents/parallax.finance-agent-world.json');
const app = fs.readFileSync('apps/universal-trading/app.js', 'utf8');
const html = fs.readFileSync('apps/universal-trading/index.html', 'utf8');

const requiredEcosystems = ['evm', 'solana', 'bitcoin', 'cosmos', 'sui', 'aptos', 'polkadot', 'tron', 'icp'];
for (const ecosystem of requiredEcosystems) {
  if (!chains.chains.some((chain) => chain.ecosystem === ecosystem)) errors.push(`missing ecosystem route: ${ecosystem}`);
}

const requiredWallets = ['metamask', 'walletconnect', 'coinbase_wallet', 'phantom', 'rabby', 'trust_wallet', 'ledger', 'keplr', 'xverse', 'plug'];
for (const wallet of requiredWallets) {
  if (!wallets.wallets.some((item) => item.id === wallet && item.enabled)) errors.push(`missing enabled wallet: ${wallet}`);
}

const allAssets = assets.asset_families.flatMap((family) => family.assets);
for (const symbol of ['BTC', 'ETH', 'SOL', 'USDC', 'USDT', 'ICP', 'AICPU', 'AIGPU', 'AIMDL', 'FET', 'TAO']) {
  if (!allAssets.includes(symbol)) errors.push(`missing asset symbol: ${symbol}`);
}

if (!assets.launch_matrix || assets.launch_matrix.mainnet_enabled !== 'disabled until gates pass') {
  errors.push('mainnet launch matrix must remain disabled until gates pass');
}

for (const phrase of ['never_request_private_keys', 'never_store_seed_phrases', 'mainnet_execution_disabled_until_operator_governance_compliance_gate']) {
  if (!wallets.rules.includes(phrase)) errors.push(`missing wallet rule: ${phrase}`);
}

for (const template of ['market_maker_agent', 'risk_sentinel_agent', 'cross_chain_research_agent', 'liquidity_router_agent']) {
  if (!agents.agent_templates.some((agent) => agent.id === template)) errors.push(`missing agent template: ${template}`);
}

for (const phrase of ['eth_requestAccounts', 'eip6963:requestProvider', 'window.phantom', 'queuePaperRoute']) {
  if (!app.includes(phrase)) errors.push(`front-end missing runtime phrase: ${phrase}`);
}

for (const id of ['status', 'connections', 'chains', 'wallets', 'assets', 'agents', 'routePreview']) {
  if (!html.includes(`id="${id}"`)) errors.push(`html missing id: ${id}`);
}

if (/privateKey|seed phrase|mnemonic/i.test(app)) {
  errors.push('front-end code must not request private keys, seed phrases, or mnemonics');
}

if (errors.length) {
  console.error('PARALLAX universal launch validation failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log('PARALLAX universal launch validation passed: chains, wallets, assets, agents, front-end, and safety gates are present.');
