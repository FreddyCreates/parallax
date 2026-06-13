import { describe, expect, it } from "vitest";
import { formatRelativeTime, formatTime, truncate } from "../formatting";

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
