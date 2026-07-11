export class WalletAdapterRegistry {
  constructor(win = window) {
    this.win = win;
    this.evmProviders = [];
    this.connections = new Map();
    this.installEip6963();
  }

  installEip6963() {
    this.win.addEventListener('eip6963:announceProvider', (event) => {
      const detail = event.detail || {};
      const uuid = detail.info?.uuid || detail.info?.rdns || detail.info?.name;
      if (!uuid || this.evmProviders.some((item) => (item.info?.uuid || item.info?.rdns || item.info?.name) === uuid)) return;
      this.evmProviders.push(detail);
    });
    this.win.dispatchEvent(new Event('eip6963:requestProvider'));
  }

  detect() {
    return {
      evm: this.evmProviders.length > 0 || Boolean(this.win.ethereum),
      solana: Boolean(this.win.phantom?.solana || this.win.solana),
      cosmos: Boolean(this.win.keplr || this.win.leap),
      bitcoin: Boolean(this.win.unisat || this.win.okxwallet?.bitcoin),
      icp: Boolean(this.win.ic?.plug)
    };
  }

  async connectEvm(providerIndex = 0) {
    const provider = this.evmProviders[providerIndex]?.provider || this.win.ethereum;
    if (!provider?.request) throw new Error('No EVM provider detected.');
    const accounts = await provider.request({ method: 'eth_requestAccounts' });
    const chainId = await provider.request({ method: 'eth_chainId' });
    const connection = { ecosystem: 'evm', address: accounts?.[0] || null, chainId, provider };
    this.connections.set('evm', connection);
    return this.publicConnection(connection);
  }

  async connectSolana() {
    const provider = this.win.phantom?.solana || this.win.solana;
    if (!provider?.connect) throw new Error('No Solana provider detected.');
    const result = await provider.connect({ onlyIfTrusted: false });
    const connection = {
      ecosystem: 'solana',
      address: result.publicKey?.toString?.() || String(result.publicKey),
      chainId: 'solana-mainnet',
      provider
    };
    this.connections.set('solana', connection);
    return this.publicConnection(connection);
  }

  async connectCosmos(chainId = 'cosmoshub-4') {
    const provider = this.win.keplr || this.win.leap;
    if (!provider?.enable || !provider?.getKey) throw new Error('No Cosmos wallet detected.');
    await provider.enable(chainId);
    const key = await provider.getKey(chainId);
    const connection = { ecosystem: 'cosmos', address: key.bech32Address, chainId, provider };
    this.connections.set('cosmos', connection);
    return this.publicConnection(connection);
  }

  async connectBitcoin() {
    const provider = this.win.unisat || this.win.okxwallet?.bitcoin;
    if (!provider?.requestAccounts) throw new Error('No Bitcoin wallet detected.');
    const accounts = await provider.requestAccounts();
    const connection = { ecosystem: 'bitcoin', address: accounts?.[0] || null, chainId: 'bitcoin-mainnet', provider };
    this.connections.set('bitcoin', connection);
    return this.publicConnection(connection);
  }

  async connectIcpPlug(whitelist = []) {
    const provider = this.win.ic?.plug;
    if (!provider?.requestConnect) throw new Error('Plug wallet not detected.');
    const approved = await provider.requestConnect({ whitelist });
    if (!approved) throw new Error('ICP wallet connection declined.');
    const principal = provider.agent ? await provider.agent.getPrincipal() : null;
    const connection = { ecosystem: 'icp', address: principal?.toText?.() || null, chainId: 'icp', provider };
    this.connections.set('icp', connection);
    return this.publicConnection(connection);
  }

  publicConnection(connection) {
    return {
      ecosystem: connection.ecosystem,
      address: connection.address,
      chainId: connection.chainId,
      custody: false,
      privateKeysAccessible: false
    };
  }

  requireConnection(ecosystem) {
    const connection = this.connections.get(ecosystem);
    if (!connection) throw new Error(`Wallet connection required for ${ecosystem}.`);
    return connection;
  }

  async signMessage(ecosystem, message) {
    const connection = this.requireConnection(ecosystem);
    if (ecosystem === 'evm') {
      return connection.provider.request({ method: 'personal_sign', params: [message, connection.address] });
    }
    if (ecosystem === 'solana') {
      const bytes = new TextEncoder().encode(message);
      const signed = await connection.provider.signMessage(bytes, 'utf8');
      return Array.from(signed.signature || []);
    }
    throw new Error(`Message signing adapter not enabled for ${ecosystem}.`);
  }
}
