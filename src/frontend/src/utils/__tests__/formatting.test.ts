import { describe, expect, it } from "vitest";
import {
  formatCompact,
  formatPercent,
  formatPrice,
  formatRelativeTime,
  formatTime,
  formatTokenBalance,
  truncate,
} from "../formatting";

describe("truncate", () => {
  it("returns the string unchanged if within max length", () => {
    expect(truncate("hello", 10)).toBe("hello");
  });

  it("returns the string unchanged if exactly at max length", () => {
    expect(truncate("hello", 5)).toBe("hello");
  });

  it("truncates and adds ellipsis when string exceeds max length", () => {
    expect(truncate("hello world", 8)).toBe("hello...");
  });

  it("handles empty string", () => {
    expect(truncate("", 5)).toBe("");
  });

  it("handles max of 3 (minimum for ellipsis)", () => {
    expect(truncate("hello", 3)).toBe("...");
  });

  it("handles single character over limit", () => {
    expect(truncate("abcdef", 5)).toBe("ab...");
  });
});

describe("formatRelativeTime", () => {
  it("returns 'just now' for future timestamps", () => {
    const futureNs = BigInt(Date.now() + 60_000) * 1_000_000n;
    expect(formatRelativeTime(futureNs)).toBe("just now");
  });

  it("returns 'just now' for timestamps less than 60 seconds ago", () => {
    const recentNs = BigInt(Date.now() - 30_000) * 1_000_000n;
    expect(formatRelativeTime(recentNs)).toBe("just now");
  });

  it("returns minutes ago for timestamps within the last hour", () => {
    const fiveMinAgo = BigInt(Date.now() - 5 * 60_000) * 1_000_000n;
    expect(formatRelativeTime(fiveMinAgo)).toBe("5 min ago");
  });

  it("returns hours ago for timestamps within the last day", () => {
    const threeHoursAgo = BigInt(Date.now() - 3 * 3_600_000) * 1_000_000n;
    expect(formatRelativeTime(threeHoursAgo)).toBe("3 hours ago");
  });

  it("uses singular 'hour' for 1 hour ago", () => {
    const oneHourAgo = BigInt(Date.now() - 1 * 3_600_000) * 1_000_000n;
    expect(formatRelativeTime(oneHourAgo)).toBe("1 hour ago");
  });

  it("returns days ago for timestamps within the last week", () => {
    const twoDaysAgo = BigInt(Date.now() - 2 * 86_400_000) * 1_000_000n;
    expect(formatRelativeTime(twoDaysAgo)).toBe("2 days ago");
  });

  it("uses singular 'day' for 1 day ago", () => {
    const oneDayAgo = BigInt(Date.now() - 1 * 86_400_000) * 1_000_000n;
    expect(formatRelativeTime(oneDayAgo)).toBe("1 day ago");
  });

  it("returns a formatted date for timestamps older than a week", () => {
    const twoWeeksAgo = BigInt(Date.now() - 14 * 86_400_000) * 1_000_000n;
    const result = formatRelativeTime(twoWeeksAgo);
    // Should be a locale date string like "May 16, 2026"
    expect(result).toMatch(/\w+ \d{1,2}, \d{4}/);
  });
});

describe("formatTime", () => {
  it("formats a nanosecond timestamp as a short time string", () => {
    // Noon UTC on Jan 1 2024
    const noonNs = BigInt(new Date("2024-01-01T12:00:00Z").getTime()) * 1_000_000n;
    const result = formatTime(noonNs);
    // Should be in HH:MM format
    expect(result).toMatch(/\d{2}:\d{2}/);
  });

  it("handles zero timestamp", () => {
    const result = formatTime(0n);
    // Should still produce a time string (epoch time)
    expect(result).toMatch(/\d{2}:\d{2}/);
  });
});

describe("formatPrice", () => {
  it("returns '——' for null", () => {
    expect(formatPrice(null)).toBe("——");
  });

  it("returns '——' for undefined", () => {
    expect(formatPrice(undefined)).toBe("——");
  });

  it("returns '——' for NaN", () => {
    expect(formatPrice(NaN)).toBe("——");
  });

  it("formats a number with default 2 decimals", () => {
    expect(formatPrice(1234.5)).toBe("1,234.50");
  });

  it("formats with custom decimal places", () => {
    expect(formatPrice(1234.5678, 4)).toBe("1,234.5678");
  });

  it("formats zero correctly", () => {
    expect(formatPrice(0)).toBe("0.00");
  });
});

describe("formatCompact", () => {
  it("returns '——' for null", () => {
    expect(formatCompact(null)).toBe("——");
  });

  it("returns '——' for NaN", () => {
    expect(formatCompact(NaN)).toBe("——");
  });

  it("formats billions", () => {
    expect(formatCompact(1_500_000_000)).toBe("1.50B");
  });

  it("formats millions", () => {
    expect(formatCompact(2_300_000)).toBe("2.30M");
  });

  it("formats thousands", () => {
    expect(formatCompact(45_000)).toBe("45.00K");
  });

  it("formats small numbers directly", () => {
    expect(formatCompact(123)).toBe("123.00");
  });

  it("handles negative billions", () => {
    expect(formatCompact(-2_000_000_000)).toBe("-2.00B");
  });
});

describe("formatPercent", () => {
  it("returns '——' for null", () => {
    expect(formatPercent(null)).toBe("——");
  });

  it("adds + sign for positive values", () => {
    expect(formatPercent(5.5)).toBe("+5.50%");
  });

  it("shows negative values without extra sign", () => {
    expect(formatPercent(-3.2)).toBe("-3.20%");
  });

  it("shows zero without sign", () => {
    expect(formatPercent(0)).toBe("0.00%");
  });

  it("respects custom decimals", () => {
    expect(formatPercent(12.3456, 1)).toBe("+12.3%");
  });
});

describe("formatTokenBalance", () => {
  it("formats zero balance", () => {
    expect(formatTokenBalance(0n)).toBe("0");
  });

  it("formats whole number balance", () => {
    expect(formatTokenBalance(100_000_000n)).toBe("1");
  });

  it("formats fractional balance", () => {
    expect(formatTokenBalance(150_000_000n)).toBe("1.5");
  });

  it("formats large balance with commas", () => {
    expect(formatTokenBalance(1_000_000_000_000n)).toBe("10,000");
  });

  it("trims trailing zeros in fractional part", () => {
    expect(formatTokenBalance(123_400_000n)).toBe("1.234");
  });
});
