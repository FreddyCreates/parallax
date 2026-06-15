/**
 * PARALLAX Quantitative Dashboard Utilities
 * Utilities for connecting frontend to quantitative backend endpoints
 */

import type {
  OptionGreeks,
  RiskMetrics,
  NashEquilibrium,
  FundMetrics,
  OptimizationResult,
} from "./quantitative";

/**
 * Call Black-Scholes option pricing endpoint
 */
export async function priceOption(
  actor: any,
  spot: number,
  strike: number,
  rate: number,
  dividend: number,
  timeToMaturity: number,
  volatility: number,
  optionType: "call" | "put"
): Promise<OptionGreeks> {
  try {
    const result = await actor.priceOption(
      spot,
      strike,
      rate,
      dividend,
      timeToMaturity,
      volatility,
      optionType
    );
    return result;
  } catch (error) {
    console.error("Option pricing failed:", error);
    throw error;
  }
}

/**
 * Solve 2x2 Nash equilibrium game
 */
export async function solveGameTheory(
  actor: any,
  payoff1: number[][],
  payoff2: number[][]
): Promise<NashEquilibrium> {
  try {
    const result = await actor.solveTwoPlayerGame(payoff1, payoff2);
    return result;
  } catch (error) {
    console.error("Game theory solving failed:", error);
    throw error;
  }
}

/**
 * Compute risk metrics (VaR, CVaR, etc.)
 */
export async function computeRiskMetrics(
  actor: any,
  returns: number[]
): Promise<RiskMetrics> {
  try {
    const result = await actor.computeRiskMetrics(returns);
    return result;
  } catch (error) {
    console.error("Risk metrics computation failed:", error);
    throw error;
  }
}

/**
 * Calculate Kelly Criterion position sizing
 */
export async function calculateKellyFraction(
  actor: any,
  expectedReturn: number,
  variance: number
): Promise<number> {
  try {
    const result = await actor.calculateKellyFraction(expectedReturn, variance);
    return result;
  } catch (error) {
    console.error("Kelly fraction calculation failed:", error);
    throw error;
  }
}

/**
 * Get fund metrics
 */
export async function getFundMetrics(
  actor: any,
  totalValue: number,
  navHistory: number[],
  cashPosition: number,
  flowsIn24h: number,
  flowsOut24h: number
): Promise<FundMetrics> {
  try {
    const result = await actor.getFundMetrics(
      totalValue,
      navHistory,
      cashPosition,
      flowsIn24h,
      flowsOut24h
    );
    return result;
  } catch (error) {
    console.error("Fund metrics retrieval failed:", error);
    throw error;
  }
}

/**
 * Analyze market equilibrium using game theory
 */
export async function analyzeMarketEquilibrium(
  actor: any,
  buyerValuation: number,
  sellerCost: number
) {
  try {
    const result = await actor.calculateMarketEquilibrium(
      buyerValuation,
      sellerCost
    );
    return result;
  } catch (error) {
    console.error("Market equilibrium analysis failed:", error);
    throw error;
  }
}

/**
 * Calculate portfolio concentration (Herfindahl index)
 */
export async function analyzeConcentration(
  actor: any,
  weights: number[]
): Promise<number> {
  try {
    const result = await actor.analyzeConcentration(weights);
    return result;
  } catch (error) {
    console.error("Concentration analysis failed:", error);
    throw error;
  }
}

/**
 * Format percentage for display
 */
export function formatPercent(value: number, decimals: number = 2): string {
  return `${(value * 100).toFixed(decimals)}%`;
}

/**
 * Format currency for display
 */
export function formatCurrency(value: number, currency: string = "USD"): string {
  const formatter = new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return formatter.format(value);
}

/**
 * Format number with thousands separator
 */
export function formatNumber(value: number, decimals: number = 2): string {
  return value.toLocaleString("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

/**
 * Get color code based on value (red = bad, green = good)
 */
export function getValueColor(value: number): string {
  if (value > 0.1) return "text-green-600"; // Good
  if (value > 0) return "text-green-500";
  if (value > -0.1) return "text-red-500";
  return "text-red-600"; // Bad
}

/**
 * Calculate Sharpe ratio
 */
export function calculateSharpeRatio(
  returns: number[],
  riskFreeRate: number = 0.02
): number {
  const meanReturn = returns.reduce((a, b) => a + b, 0) / returns.length;
  const variance = returns.reduce(
    (sum, ret) => sum + Math.pow(ret - meanReturn, 2),
    0
  ) / returns.length;
  const stdDev = Math.sqrt(variance);
  return (meanReturn - riskFreeRate) / (stdDev + 1e-6);
}

/**
 * Calculate maximum drawdown
 */
export function calculateMaxDrawdown(prices: number[]): number {
  let maxDrawdown = 0;
  let peak = prices[0];

  for (const price of prices) {
    if (price > peak) {
      peak = price;
    } else {
      const dd = (peak - price) / peak;
      maxDrawdown = Math.max(maxDrawdown, dd);
    }
  }

  return maxDrawdown;
}

/**
 * Generate color gradient for heatmap
 */
export function getHeatmapColor(value: number, min: number, max: number): string {
  const normalized = (value - min) / (max - min);
  if (normalized < 0.33) return "rgb(255, 0, 0)";      // Red
  if (normalized < 0.66) return "rgb(255, 255, 0)";    // Yellow
  return "rgb(0, 255, 0)";                              // Green
}

/**
 * Calculate Value at Risk (VaR) from returns
 */
export function calculateVaR(returns: number[], confidence: number = 0.95): number {
  const sorted = [...returns].sort((a, b) => a - b);
  const index = Math.floor(sorted.length * (1 - confidence));
  return sorted[index];
}

/**
 * Calculate Conditional Value at Risk (CVaR)
 */
export function calculateCVaR(returns: number[], confidence: number = 0.95): number {
  const sorted = [...returns].sort((a, b) => a - b);
  const index = Math.floor(sorted.length * (1 - confidence));
  const tail = sorted.slice(0, index + 1);
  return tail.reduce((a, b) => a + b, 0) / tail.length;
}

/**
 * Simulate Monte Carlo paths
 */
export function monteCarloPaths(
  spot: number,
  mu: number,
  sigma: number,
  T: number,
  steps: number = 252,
  paths: number = 1000
): number[][] {
  const dt = T / steps;
  const sqrtDt = Math.sqrt(dt);
  const result: number[][] = [];

  for (let p = 0; p < paths; p++) {
    const path: number[] = [spot];
    let S = spot;

    for (let i = 0; i < steps; i++) {
      const Z = Math.random() + Math.random() + Math.random() + 
                Math.random() + Math.random() + Math.random() - 3; // Box-Muller approximation
      S = S * Math.exp((mu - 0.5 * sigma * sigma) * dt + sigma * sqrtDt * Z);
      path.push(S);
    }

    result.push(path);
  }

  return result;
}

/**
 * Bootstrap resample for confidence intervals
 */
export function bootstrap(
  data: number[],
  samples: number = 1000
): { mean: number; ci95: [number, number]; ci99: [number, number] } {
  const means: number[] = [];

  for (let i = 0; i < samples; i++) {
    const sample: number[] = [];
    for (let j = 0; j < data.length; j++) {
      sample.push(data[Math.floor(Math.random() * data.length)]);
    }
    const mean = sample.reduce((a, b) => a + b, 0) / sample.length;
    means.push(mean);
  }

  means.sort((a, b) => a - b);
  const mean = data.reduce((a, b) => a + b, 0) / data.length;
  const ci95 = [means[Math.floor(samples * 0.025)], means[Math.floor(samples * 0.975)]];
  const ci99 = [means[Math.floor(samples * 0.005)], means[Math.floor(samples * 0.995)]];

  return { mean, ci95: ci95 as [number, number], ci99: ci99 as [number, number] };
}

/**
 * Calculate correlation matrix
 */
export function correlationMatrix(series: number[][]): number[][] {
  const n = series.length;
  const m = series[0].length;
  const means = series.map(s => s.reduce((a, b) => a + b, 0) / m);

  const corr: number[][] = Array(n).fill(0).map(() => Array(n).fill(0));

  for (let i = 0; i < n; i++) {
    for (let j = 0; j < n; j++) {
      let cov = 0;
      for (let k = 0; k < m; k++) {
        cov += (series[i][k] - means[i]) * (series[j][k] - means[j]);
      }
      cov /= m;

      const stdi = Math.sqrt(series[i].reduce((sum, x) => sum + Math.pow(x - means[i], 2), 0) / m);
      const stdj = Math.sqrt(series[j].reduce((sum, x) => sum + Math.pow(x - means[j], 2), 0) / m);

      corr[i][j] = cov / (stdi * stdj + 1e-6);
    }
  }

  return corr;
}
