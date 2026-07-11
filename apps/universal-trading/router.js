const PARALLAX_ROUTE_VERSION = '0.5.0-alpha.0';

export class RouteEngine {
  constructor({ providers, fetchImpl = fetch, now = () => Date.now() }) {
    this.providers = providers;
    this.fetch = fetchImpl;
    this.now = now;
  }

  normalizeRequest(input) {
    const request = {
      requestId: input.requestId || crypto.randomUUID(),
      mode: input.mode || 'paper',
      ecosystem: String(input.ecosystem || '').toLowerCase(),
      chainId: String(input.chainId || ''),
      sellAsset: String(input.sellAsset || '').toUpperCase(),
      buyAsset: String(input.buyAsset || '').toUpperCase(),
      sellAmount: String(input.sellAmount || ''),
      walletAddress: input.walletAddress || null,
      slippageBps: Number(input.slippageBps ?? 50),
      requestedAt: this.now()
    };

    const errors = [];
    if (!request.ecosystem) errors.push('ecosystem_required');
    if (!request.chainId) errors.push('chain_id_required');
    if (!request.sellAsset || !request.buyAsset) errors.push('asset_pair_required');
    if (!/^\d+(\.\d+)?$/.test(request.sellAmount) || Number(request.sellAmount) <= 0) errors.push('valid_sell_amount_required');
    if (!Number.isInteger(request.slippageBps) || request.slippageBps < 1 || request.slippageBps > 500) errors.push('slippage_out_of_bounds');
    if (!['paper', 'testnet'].includes(request.mode)) errors.push('mainnet_execution_blocked');
    return { request, errors };
  }

  eligibleProviders(request) {
    return this.providers.providers.filter((provider) =>
      provider.enabled && provider.ecosystems.includes(request.ecosystem)
    );
  }

  async quote(input) {
    const { request, errors } = this.normalizeRequest(input);
    if (errors.length) return { ok: false, request, errors, routes: [] };

    const providers = this.eligibleProviders(request);
    const routes = providers.map((provider, index) => this.simulatedRoute(provider, request, index));
    routes.sort((a, b) => Number(b.buyAmount) - Number(a.buyAmount));

    return {
      ok: routes.length > 0,
      version: PARALLAX_ROUTE_VERSION,
      request,
      routes,
      selectedRouteId: routes[0]?.routeId || null,
      receipt: this.makeReceipt(request, routes)
    };
  }

  simulatedRoute(provider, request, index) {
    const base = Number(request.sellAmount);
    const frictionBps = 8 + index * 4;
    const buyAmount = base * (1 - frictionBps / 10_000);
    return {
      routeId: `${request.requestId}:${provider.id}`,
      providerId: provider.id,
      providerName: provider.name,
      ecosystem: request.ecosystem,
      chainId: request.chainId,
      sellAsset: request.sellAsset,
      buyAsset: request.buyAsset,
      sellAmount: request.sellAmount,
      buyAmount: buyAmount.toFixed(8),
      estimatedPriceImpactBps: frictionBps,
      expiresAt: this.now() + 30_000,
      execution: 'simulation_only',
      transactionPayload: null,
      requiresWalletSignature: true
    };
  }

  makeReceipt(request, routes) {
    const body = JSON.stringify({ request, routes, version: PARALLAX_ROUTE_VERSION });
    let hash = 2166136261;
    for (let index = 0; index < body.length; index += 1) {
      hash ^= body.charCodeAt(index);
      hash = Math.imul(hash, 16777619);
    }
    return {
      receiptId: `route:${request.requestId}:${(hash >>> 0).toString(16)}`,
      kind: 'quote_simulation',
      createdAt: this.now(),
      routeCount: routes.length,
      mainnetExecution: false,
      payloadFingerprint: (hash >>> 0).toString(16)
    };
  }
}
