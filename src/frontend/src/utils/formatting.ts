/**
 * Format a bigint nanosecond timestamp as a relative time string.
 */
export function formatRelativeTime(nanoseconds: bigint): string {
  const ms = Number(nanoseconds / 1_000_000n);
  const now = Date.now();
  const diff = now - ms;

  if (diff < 0) return "just now";
  if (diff < 60_000) return "just now";
  if (diff < 3_600_000) {
    const mins = Math.floor(diff / 60_000);
    return `${mins} min ago`;
  }
  if (diff < 86_400_000) {
    const hours = Math.floor(diff / 3_600_000);
    return `${hours} hour${hours !== 1 ? "s" : ""} ago`;
  }
  if (diff < 7 * 86_400_000) {
    const days = Math.floor(diff / 86_400_000);
    return `${days} day${days !== 1 ? "s" : ""} ago`;
  }
  return new Date(ms).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

/**
 * Format a bigint nanosecond timestamp as a short time string.
 */
export function formatTime(nanoseconds: bigint): string {
  const ms = Number(nanoseconds / 1_000_000n);
  return new Date(ms).toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Truncate a string to a max length with ellipsis.
 */
export function truncate(str: string, max: number): string {
  if (str.length <= max) return str;
  return `${str.slice(0, max - 3)}...`;
}

/**
 * Format a number as a price with locale-aware separators.
 * Returns "——" for null/undefined/NaN values.
 */
export function formatPrice(
  value: number | null | undefined,
  decimals = 2,
): string {
  if (value == null || Number.isNaN(value)) return "——";
  return value.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

/**
 * Format a large number with compact notation (K, M, B).
 */
export function formatCompact(value: number | null | undefined): string {
  if (value == null || Number.isNaN(value)) return "——";
  if (Math.abs(value) >= 1_000_000_000) {
    return `${(value / 1_000_000_000).toFixed(2)}B`;
  }
  if (Math.abs(value) >= 1_000_000) {
    return `${(value / 1_000_000).toFixed(2)}M`;
  }
  if (Math.abs(value) >= 1_000) {
    return `${(value / 1_000).toFixed(2)}K`;
  }
  return value.toFixed(2);
}

/**
 * Format a number as a percentage string.
 */
export function formatPercent(
  value: number | null | undefined,
  decimals = 2,
): string {
  if (value == null || Number.isNaN(value)) return "——";
  const sign = value > 0 ? "+" : "";
  return `${sign}${value.toFixed(decimals)}%`;
}

/**
 * Format a bigint token balance with decimal places (e8s convention).
 */
export function formatTokenBalance(balance: bigint, decimals = 8): string {
  const divisor = 10 ** decimals;
  const whole = balance / BigInt(divisor);
  const fractional = balance % BigInt(divisor);
  const fracStr = fractional
    .toString()
    .padStart(decimals, "0")
    .replace(/0+$/, "");
  if (fracStr.length === 0) return whole.toLocaleString("en-US");
  return `${whole.toLocaleString("en-US")}.${fracStr}`;
}
