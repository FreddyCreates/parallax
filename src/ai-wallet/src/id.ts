const textEncoder = new TextEncoder();

const toHex = (bytes: Uint8Array) =>
  Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');

const fallbackHash = (input: string) => {
  let hash = 2166136261;
  for (let index = 0; index < input.length; index += 1) {
    hash ^= input.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
};

export const stableHash = async (input: unknown): Promise<string> => {
  const normalized = JSON.stringify(input, Object.keys(input as object).sort());
  if (globalThis.crypto?.subtle) {
    const digest = await globalThis.crypto.subtle.digest('SHA-256', textEncoder.encode(normalized));
    return toHex(new Uint8Array(digest));
  }
  return fallbackHash(normalized);
};

export const stableHashSync = (input: unknown): string => fallbackHash(JSON.stringify(input));

export const makeAiWalletId = (agentId: string, ownerPrincipal: string, createdAt: string) =>
  `aiw_${stableHashSync(`${agentId}:${ownerPrincipal}:${createdAt}`).slice(0, 16)}`;

export const makeAiWalletCommandId = (walletId: string, kind: string, createdAt: string, nonce = '') =>
  `aiwcmd_${stableHashSync(`${walletId}:${kind}:${createdAt}:${nonce}`).slice(0, 16)}`;

export const makeAiWalletReceiptId = (walletId: string, kind: string, createdAt: string, commandId = '') =>
  `aiwrcpt_${stableHashSync(`${walletId}:${kind}:${createdAt}:${commandId}`).slice(0, 16)}`;
