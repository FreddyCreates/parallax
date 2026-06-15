/**
 * PARALLAX Quantitative Trading Types
 * TypeScript interfaces for game theory, options pricing, and fund management
 */

// ═══════════════════════════════════════════════════════════════════════════
// GAME THEORY TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface NashEquilibrium {
  strategy1: number[];
  strategy2: number[];
  payoff1: number;
  payoff2: number;
  isPure: boolean;
  iterations: number;
}

export interface GameTheoryResult {
  equilibrium: NashEquilibrium;
  dominatedStrategies: {
    player1: boolean[];
    player2: boolean[];
  };
  paretoEfficient: boolean;
  timestamp: number;
}

export interface MarketGame {
  buyerValuation: number;
  sellerCost: number;
  askPrice: number;
  bidPrice: number;
  spreadWidth: number;
  equilibrium: "bid" | "ask" | "mid";
}

// ═══════════════════════════════════════════════════════════════════════════
// OPTIONS PRICING TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface OptionGreeks {
  price: number;      // Option price
  delta: number;      // ∂price/∂spot (directional sensitivity)
  gamma: number;      // ∂delta/∂spot (convexity)
  vega: number;       // ∂price/∂volatility (vol sensitivity, per 1%)
  theta: number;      // ∂price/∂time (daily decay)
  rho: number;        // ∂price/∂rate (interest rate sensitivity)
}

export interface OptionPricingInput {
  spot: number;
  strike: number;
  riskFreeRate: number;
  dividendYield: number;
  timeToMaturity: number;
  volatility: number;
  optionType: "call" | "put";
}

export interface OptionStrategy {
  name: string;
  legs: {
    type: "call" | "put";
    strike: number;
    quantity: number;
    action: "buy" | "sell";
    price: number;
  }[];
  maxProfit: number;
  maxLoss: number;
  breakeven: number[];
}

// ═══════════════════════════════════════════════════════════════════════════
// RISK METRICS TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface RiskMetrics {
  var95: number;          // Value at Risk (95% confidence)
  var99: number;          // Value at Risk (99% confidence)
  cvar95: number;         // Conditional VaR (95%)
  cvar99: number;         // Conditional VaR (99%)
  expectedShortfall: number;
  maxDrawdown: number;
  sharpeRatio: number;
  sortinoRatio: number;
  calmarRatio: number;
}

export interface DrawdownAnalysis {
  currentDrawdown: number;
  maxHistoricalDrawdown: number;
  recoveryTime: number;  // days
  drawdownEvents: {
    start: Date;
    end: Date;
    magnitude: number;
  }[];
}

// ═══════════════════════════════════════════════════════════════════════════
// PORTFOLIO OPTIMIZATION TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface PortfolioWeights {
  assetId: string;
  ticker: string;
  weight: number;
  targetWeight: number;
  rebalanceNeeded: boolean;
}

export interface OptimizationResult {
  weights: PortfolioWeights[];
  expectedReturn: number;
  volatility: number;
  sharpeRatio: number;
  efficient: boolean;
}

export interface EfficientFrontier {
  points: {
    volatility: number;
    return: number;
    sharpeRatio: number;
    weights: number[];
  }[];
  cml: {
    slope: number;
    intercept: number;
  };
  optimalPortfolio: {
    weights: number[];
    return: number;
    volatility: number;
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// FUND MANAGEMENT TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface AssetPosition {
  assetId: string;
  ticker: string;
  quantity: number;
  currentPrice: number;
  value: number;
  weight: number;
  targetWeight: number;
  rebalanceNeeded: boolean;
  performanceHour: number;
  performanceDay: number;
}

export interface FundMetrics {
  fundId: string;
  totalValue: number;
  nav: number;          // Net Asset Value per share
  cashPosition: number;
  hourlyReturn: number;
  dailyReturn: number;
  monthlyReturn: number;
  flowVelocity: number; // Net flows as % of AUM
  inflows24h: number;
  outflows24h: number;
}

export interface FundPerformance {
  timestamp: number;
  nav: number;
  totalReturn: number;
  benchmarkReturn: number;
  outperformance: number;
  allocEffect: number;     // Brinson-Fachler attribution
  selectionEffect: number;
  interactionEffect: number;
}

export interface RebalanceOrder {
  assetId: string;
  currentWeight: number;
  targetWeight: number;
  action: "buy" | "sell";
  quantity: number;
  estimatedValue: number;
  priority: number;  // 1=high, 3=low
}

// ═══════════════════════════════════════════════════════════════════════════
// FACTOR MODEL TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface FactorExposure {
  factorName: string;
  beta: number;
  contribution: number;  // Contribution to total return
  rSquared: number;
}

export interface FamaFrenchFactors {
  marketRiskPremium: number;
  smbFactor: number;     // Small-Minus-Big (size factor)
  hmlFactor: number;     // High-Minus-Low (value factor)
  rf: number;            // Risk-free rate
  alpha: number;
  rSquared: number;
}

export interface FactorRegression {
  alpha: number;
  betaMarket: number;
  betaSize: number;
  betaValue: number;
  rSquared: number;
  adjustedRSquared: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// VOLATILITY & CORRELATION TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface VolatilityForecast {
  period: "1d" | "5d" | "30d";
  volatilities: number[];
  confidence: number;
  model: "garch" | "realized" | "historical";
}

export interface CorrelationMatrix {
  assets: string[];
  correlations: number[][];
  eigenvalues: number[];
  principalComponents: number[][];
}

export interface VolatilitySmile {
  strikes: number[];
  impliedVols: number[];
  curvature: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// TRADING SIGNALS & ANALYSIS TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface TradeSignal {
  timestamp: number;
  asset: string;
  signal: "buy" | "sell" | "hold";
  strength: number;  // 0-1
  sources: {
    gameTheory: number;
    momentum: number;
    meanReversion: number;
    arbitrage: number;
    sentiment: number;
  };
  targetPrice: number;
  stopLoss: number;
  takeProfit: number;
}

export interface ArbitrageOpportunity {
  assetA: string;
  assetB: string;
  mispricing: number;
  expectedReturn: number;
  riskAdjustedReturn: number;
  timeWindow: number;  // seconds
  confidence: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// MONTE CARLO & SCENARIO ANALYSIS TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface MonteCarloResult {
  paths: number[][];
  timeGrid: number[];
  statistics: {
    mean: number[];
    stdDev: number[];
    percentile5: number[];
    percentile95: number[];
  };
  confidenceInterval: [number, number];
}

export interface ScenarioAnalysis {
  scenarios: {
    name: string;
    probability: number;
    assumptions: Record<string, number>;
    outcomes: {
      portfolioReturn: number;
      portfolioVolatility: number;
      assetReturns: number[];
    };
  }[];
}

// ═══════════════════════════════════════════════════════════════════════════
// API RESPONSE TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface QuantAnalysisResponse<T> {
  success: boolean;
  data: T;
  timestamp: number;
  computationTimeMs: number;
  confidence: number;
  warnings: string[];
}

export interface DashboardState {
  selectedAssets: string[];
  timeHorizon: number;
  riskProfile: "conservative" | "moderate" | "aggressive";
  benchmark: string;
  rebalanceThreshold: number;
}
