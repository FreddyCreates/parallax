type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };

type GatewayResponse = {
  ok: boolean;
  requestId: string;
  service: string;
  mode: string;
  posture: string;
  data?: JsonValue;
  error?: {
    code: string;
    message: string;
  };
};

const SERVICE = 'parallax-edge-gateway';
const MUTATION_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);

const LEDGERS = [
  {
    id: 'parallax-paper-ledger',
    mode: 'paper',
    assets: ['PXUSD', 'PXICP', 'PXAI', 'PXGPU', 'PXETH', 'PXCRED'],
    liveValue: false,
  },
  {
    id: 'icp-local-ledger',
    mode: 'testnet',
    assets: ['PXICP', 'PXAI', 'PXCRED'],
    liveValue: false,
  },
  {
    id: 'ethereum-testnet-ledger',
    mode: 'testnet',
    assets: ['PXETH', 'PXUSD', 'PXGPU'],
    liveValue: false,
  },
  {
    id: 'agent-credit-ledger',
    mode: 'paper',
    assets: ['PXCRED', 'PXAI', 'PXGPU'],
    liveValue: false,
  },
];

const TOKENS = [
  { symbol: 'PXUSD', class: 'paper_stable_unit', mode: 'paper', valueClaim: 'no_real_value' },
  { symbol: 'PXICP', class: 'testnet_protocol_unit', mode: 'testnet', valueClaim: 'testnet_only' },
  { symbol: 'PXETH', class: 'evm_test_unit', mode: 'testnet', valueClaim: 'testnet_only' },
  { symbol: 'PXAI', class: 'agent_work_credit', mode: 'paper', valueClaim: 'internal_credit_only' },
  { symbol: 'PXGPU', class: 'compute_credit', mode: 'paper', valueClaim: 'internal_compute_accounting_only' },
  { symbol: 'PXCRED', class: 'receipt_credit', mode: 'paper', valueClaim: 'internal_credit_only' },
];

const AGENT_CLASSES = [
  {
    id: 'agent-operator-wallet',
    allowedLedgers: ['parallax-paper-ledger', 'icp-local-ledger'],
    requiresHumanApproval: true,
  },
  {
    id: 'agent-research-wallet',
    allowedLedgers: ['agent-credit-ledger', 'parallax-paper-ledger'],
    requiresHumanApproval: false,
    humanApprovalAbove: 500,
  },
  {
    id: 'agent-strategy-wallet',
    allowedLedgers: ['parallax-paper-ledger', 'ethereum-testnet-ledger'],
    requiresHumanApproval: true,
  },
];

const ALPHA_GATES = [
  'no_live_money_movement',
  'no_live_broker_routing',
  'no_mainnet_bridge_in_alpha',
  'all_agent_commands_policy_evaluated',
  'all_state_transitions_emit_receipts',
  'edge_gateway_auth_required_for_mutation',
  'tunnel_origin_locked_down',
  'public_claims_match_evidence',
];

const requestId = () => crypto.randomUUID();

const allowedOrigins = (env: Env) =>
  env.PARALLAX_ALLOWED_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean);

const corsHeaders = (request: Request, env: Env) => {
  const origin = request.headers.get('Origin') ?? '';
  const allowed = allowedOrigins(env);
  const allowOrigin = allowed.includes(origin) ? origin : allowed[0] ?? '*';
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Parallax-Mode,X-Parallax-Agent',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
};

const json = (request: Request, env: Env, status: number, body: GatewayResponse) =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'X-Parallax-Mode': env.PARALLAX_ENV,
      ...corsHeaders(request, env),
    },
  });

const ok = (request: Request, env: Env, id: string, data: JsonValue, status = 200) =>
  json(request, env, status, {
    ok: true,
    requestId: id,
    service: SERVICE,
    mode: env.PARALLAX_ENV,
    posture: env.PARALLAX_PUBLIC_POSTURE,
    data,
  });

const fail = (request: Request, env: Env, id: string, status: number, code: string, message: string) =>
  json(request, env, status, {
    ok: false,
    requestId: id,
    service: SERVICE,
    mode: env.PARALLAX_ENV,
    posture: env.PARALLAX_PUBLIC_POSTURE,
    error: { code, message },
  });

const isAuthorized = (request: Request, env: Env) => {
  if (env.PARALLAX_REQUIRE_AUTH_FOR_MUTATION !== 'true') return true;
  const token = env.PARALLAX_EDGE_TOKEN;
  if (!token) return false;
  const authorization = request.headers.get('Authorization') ?? '';
  return authorization === `Bearer ${token}`;
};

const assertMutationAuth = (request: Request, env: Env, id: string) => {
  if (!MUTATION_METHODS.has(request.method)) return null;
  if (isAuthorized(request, env)) return null;
  return fail(request, env, id, 401, 'EDGE_AUTH_REQUIRED', 'Mutation routes require PARALLAX_EDGE_TOKEN bearer authentication.');
};

const readJson = async <T>(request: Request): Promise<T | null> => {
  const contentType = request.headers.get('Content-Type') ?? '';
  if (!contentType.includes('application/json')) return null;
  return request.json<T>();
};

const evaluateAgentCommand = async (request: Request, env: Env, id: string) => {
  const authFailure = assertMutationAuth(request, env, id);
  if (authFailure) return authFailure;

  const input = await readJson<{
    agentClass?: string;
    ledgerId?: string;
    asset?: string;
    amount?: number;
    mode?: string;
    humanApprovalId?: string;
  }>(request);

  if (!input) return fail(request, env, id, 400, 'INVALID_JSON', 'Expected application/json request body.');

  const reasons: string[] = [];
  const mode = input.mode ?? 'paper';
  const ledger = LEDGERS.find((item) => item.id === input.ledgerId);
  const agentClass = AGENT_CLASSES.find((item) => item.id === input.agentClass);

  if (!agentClass) reasons.push('AGENT_CLASS_NOT_FOUND');
  if (!ledger) reasons.push('LEDGER_NOT_FOUND');
  if (mode === 'live' || mode === 'restricted_live') reasons.push('LIVE_MODE_BLOCKED');
  if (ledger && ledger.liveValue) reasons.push('LIVE_VALUE_BLOCKED');
  if (ledger && input.asset && !ledger.assets.includes(input.asset)) reasons.push('ASSET_NOT_ALLOWED_FOR_LEDGER');
  if (agentClass && ledger && !agentClass.allowedLedgers.includes(ledger.id)) reasons.push('LEDGER_NOT_ALLOWED_FOR_AGENT');
  if (!input.amount || input.amount <= 0) reasons.push('INVALID_AMOUNT');
  if (agentClass?.requiresHumanApproval && !input.humanApprovalId) reasons.push('HUMAN_APPROVAL_REQUIRED');
  if ((agentClass?.humanApprovalAbove ?? Number.POSITIVE_INFINITY) <= (input.amount ?? 0) && !input.humanApprovalId) {
    reasons.push('HUMAN_APPROVAL_REQUIRED');
  }

  const uniqueReasons = [...new Set(reasons)];
  const decision = uniqueReasons.length === 0 ? 'approved' : uniqueReasons.includes('HUMAN_APPROVAL_REQUIRED') && uniqueReasons.length === 1 ? 'requires_human_approval' : 'rejected';

  return ok(request, env, id, {
    decision,
    reasonCodes: uniqueReasons.length === 0 ? ['VALID'] : uniqueReasons,
    input,
    alphaBoundary: {
      noLiveMoneyMovement: true,
      noLiveBrokerRouting: true,
      noMainnetBridgeInAlpha: true,
    },
  });
};

const proxyToCore = async (request: Request, env: Env, id: string, pathname: string) => {
  const authFailure = assertMutationAuth(request, env, id);
  if (authFailure) return authFailure;

  const target = new URL(pathname.replace(/^\/v1\/proxy/, ''), env.PARALLAX_CORE_URL);
  target.search = new URL(request.url).search;

  const proxied = new Request(target.toString(), {
    method: request.method,
    headers: request.headers,
    body: MUTATION_METHODS.has(request.method) ? request.body : undefined,
  });

  const response = await fetch(proxied);
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(corsHeaders(request, env))) headers.set(key, value);
  headers.set('X-Parallax-Request-Id', id);
  headers.set('X-Parallax-Proxy-Origin', env.PARALLAX_CORE_URL);
  return new Response(response.body, { status: response.status, headers });
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const id = requestId();
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(request, env) });
    }

    if (url.pathname === '/' || url.pathname === '/health') {
      return ok(request, env, id, {
        status: 'ok',
        ledgers: LEDGERS.length,
        tokens: TOKENS.length,
        agentClasses: AGENT_CLASSES.length,
        alphaGates: ALPHA_GATES,
        tunnelExpectedHost: env.PARALLAX_TUNNEL_EXPECTED_HOST,
      });
    }

    if (url.pathname === '/v1/ledgers') return ok(request, env, id, { ledgers: LEDGERS });
    if (url.pathname === '/v1/tokens') return ok(request, env, id, { tokens: TOKENS });
    if (url.pathname === '/v1/agents/classes') return ok(request, env, id, { agentClasses: AGENT_CLASSES });
    if (url.pathname === '/v1/alpha/gates') return ok(request, env, id, { alphaGates: ALPHA_GATES });

    if (url.pathname === '/v1/agent-command/evaluate' && request.method === 'POST') {
      return evaluateAgentCommand(request, env, id);
    }

    if (url.pathname.startsWith('/v1/proxy/')) {
      return proxyToCore(request, env, id, url.pathname);
    }

    return fail(request, env, id, 404, 'NOT_FOUND', `No PARALLAX edge route for ${url.pathname}.`);
  },
};
