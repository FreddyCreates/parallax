const state = {
  chains: null,
  wallets: null,
  assets: null,
  agents: null,
  evmProviders: [],
  connected: []
};

const $ = (id) => document.getElementById(id);
const esc = (value) => String(value ?? '').replace(/[&<>'"]/g, (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[char]));

async function loadJson(path) {
  const response = await fetch(path, { cache: 'no-store' });
  if (!response.ok) throw new Error(`Failed to load ${path}: ${response.status}`);
  return response.json();
}

async function boot() {
  [state.chains, state.wallets, state.assets, state.agents] = await Promise.all([
    loadJson('../../config/chains/parallax.chain-registry.json'),
    loadJson('../../config/wallets/parallax.wallet-registry.json'),
    loadJson('../../config/assets/parallax.launch-asset-universe.json'),
    loadJson('../../config/agents/parallax.finance-agent-world.json')
  ]);
  installEip6963Listener();
  renderStatus();
  renderChains();
  renderWallets();
  renderAssets();
  renderAgents();
}

function installEip6963Listener() {
  window.addEventListener('eip6963:announceProvider', (event) => {
    const detail = event.detail || {};
    if (!state.evmProviders.find((item) => item.info?.uuid === detail.info?.uuid)) {
      state.evmProviders.push(detail);
      renderWallets();
    }
  });
  window.dispatchEvent(new Event('eip6963:requestProvider'));
}

function detectWallet(wallet) {
  if (wallet.id === 'metamask') return Boolean(window.ethereum?.isMetaMask || state.evmProviders.find((p) => /metamask/i.test(p.info?.name || '')));
  if (wallet.id === 'phantom') return Boolean(window.phantom?.solana?.isPhantom || window.solana?.isPhantom);
  if (wallet.id === 'coinbase_wallet') return Boolean(window.ethereum?.isCoinbaseWallet || state.evmProviders.find((p) => /coinbase/i.test(p.info?.name || '')));
  if (wallet.id === 'rabby') return Boolean(window.ethereum?.isRabby || state.evmProviders.find((p) => /rabby/i.test(p.info?.name || '')));
  if (wallet.id === 'trust_wallet') return Boolean(window.ethereum?.isTrust || state.evmProviders.find((p) => /trust/i.test(p.info?.name || '')));
  if (wallet.id === 'okx_wallet') return Boolean(window.okxwallet || state.evmProviders.find((p) => /okx/i.test(p.info?.name || '')));
  if (wallet.id === 'keplr') return Boolean(window.keplr);
  if (wallet.id === 'leap') return Boolean(window.leap);
  if (wallet.id === 'unisat') return Boolean(window.unisat);
  if (wallet.id === 'plug') return Boolean(window.ic?.plug);
  return false;
}

async function connectEvm() {
  const provider = state.evmProviders[0]?.provider || window.ethereum;
  if (!provider?.request) throw new Error('No EVM provider detected.');
  const accounts = await provider.request({ method: 'eth_requestAccounts' });
  const chainId = await provider.request({ method: 'eth_chainId' });
  state.connected.push({ ecosystem: 'evm', wallet: 'Injected EVM', address: accounts?.[0], chainId });
  renderStatus();
  renderConnections();
}

async function connectSolana() {
  const provider = window.phantom?.solana || window.solana;
  if (!provider?.connect) throw new Error('No Solana provider detected.');
  const result = await provider.connect({ onlyIfTrusted: false });
  state.connected.push({ ecosystem: 'solana', wallet: 'Phantom/Solana provider', address: result.publicKey?.toString?.() || String(result.publicKey) });
  renderStatus();
  renderConnections();
}

async function connectIcpPlug() {
  if (!window.ic?.plug?.requestConnect) throw new Error('Plug wallet not detected.');
  const ok = await window.ic.plug.requestConnect({ whitelist: [] });
  const principal = ok && window.ic.plug.agent ? await window.ic.plug.agent.getPrincipal() : null;
  state.connected.push({ ecosystem: 'icp', wallet: 'Plug', address: principal?.toText?.() || 'connected' });
  renderStatus();
  renderConnections();
}

function renderStatus() {
  $('status').innerHTML = `
    <div><strong>${state.chains?.chains?.length || 0}</strong><span>chains/routes</span></div>
    <div><strong>${state.wallets?.wallets?.length || 0}</strong><span>wallet integrations</span></div>
    <div><strong>${state.assets?.asset_families?.reduce((sum, f) => sum + f.assets.length, 0) || 0}</strong><span>asset symbols</span></div>
    <div><strong>${state.agents?.agent_templates?.length || 0}</strong><span>agent templates</span></div>`;
}

function renderConnections() {
  $('connections').innerHTML = state.connected.length
    ? state.connected.map((conn) => `<article class="card small"><strong>${esc(conn.wallet)}</strong><span>${esc(conn.ecosystem)} · ${esc(conn.address)} ${conn.chainId ? `· ${esc(conn.chainId)}` : ''}</span></article>`).join('')
    : '<article class="card small muted">No wallets connected yet. PARALLAX never asks for seed phrases or private keys.</article>';
}

function renderChains() {
  $('chains').innerHTML = state.chains.chains.map((chain) => `
    <article class="card">
      <div class="pill">${esc(chain.ecosystem)}</div>
      <h3>${esc(chain.name)}</h3>
      <p>${esc(chain.status)} · ${esc(chain.route_mode)}</p>
      <small>${esc((chain.assets || []).join(', '))}</small>
    </article>`).join('');
}

function renderWallets() {
  $('wallets').innerHTML = state.wallets.wallets.map((wallet) => {
    const detected = detectWallet(wallet);
    return `<article class="card wallet ${detected ? 'detected' : ''}">
      <h3>${esc(wallet.name)}</h3>
      <p>${esc(wallet.ecosystems.join(' · '))}</p>
      <small>${detected ? 'Detected in browser' : 'Not detected / available through QR, mobile, or adapter'}</small>
    </article>`;
  }).join('');
}

function renderAssets() {
  $('assets').innerHTML = state.assets.asset_families.map((family) => `
    <article class="card wide">
      <h3>${esc(family.id)}</h3>
      <p>${esc(family.description)}</p>
      <div class="tokens">${family.assets.map((asset) => `<span>${esc(asset)}</span>`).join('')}</div>
    </article>`).join('');
}

function renderAgents() {
  $('agents').innerHTML = state.agents.agent_templates.map((agent) => `
    <article class="card">
      <div class="pill">${esc(agent.risk_lane)}</div>
      <h3>${esc(agent.name)}</h3>
      <p>${esc(agent.description)}</p>
      <small>Requires: ${esc(agent.requires.join(', '))}</small>
    </article>`).join('');
}

function queuePaperRoute() {
  const payload = {
    mode: 'paper',
    route: 'universal-market-router',
    status: 'queued_for_policy_gate',
    note: 'No live execution. Route must pass wallet policy, market policy, compliance, liquidity, and receipt gates.'
  };
  $('routePreview').textContent = JSON.stringify(payload, null, 2);
}

window.connectEvm = () => connectEvm().catch((err) => alert(err.message));
window.connectSolana = () => connectSolana().catch((err) => alert(err.message));
window.connectIcpPlug = () => connectIcpPlug().catch((err) => alert(err.message));
window.queuePaperRoute = queuePaperRoute;

boot().catch((error) => {
  console.error(error);
  document.body.innerHTML = `<main class="shell"><h1>PARALLAX launch app failed to boot</h1><pre>${esc(error.message)}</pre></main>`;
});
