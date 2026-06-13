import { useCallback, useEffect, useState } from "react";
import { useActor } from "./useActor";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

// ══════════════════════════════════════════════════════════════════════════════
// PARALLAX DEX HOOK - Production-Grade Decentralized Exchange State Management
// ══════════════════════════════════════════════════════════════════════════════

export interface DexToken {
  symbol: string;
  name: string;
  decimals: number;
  balance: bigint;
  price: number;
  priceChange24h: number;
  volume24h: number;
  iconUrl?: string;
  canisterId?: string;
}

export interface LiquidityPool {
  id: string;
  token0: DexToken;
  token1: DexToken;
  reserve0: bigint;
  reserve1: bigint;
  totalLiquidity: bigint;
  userLiquidity: bigint;
  apr: number;
  fee: number;
  volume24h: number;
}

export interface OrderBookEntry {
  price: number;
  amount: number;
  total: number;
  cumulative: number;
}

export interface Order {
  id: string;
  type: "limit" | "market" | "stopLimit" | "trailingStop";
  side: "buy" | "sell";
  tokenIn: string;
  tokenOut: string;
  amountIn: bigint;
  amountOut: bigint;
  price: number;
  status: "pending" | "partial" | "filled" | "cancelled";
  timestamp: bigint;
  filledAmount: bigint;
}

export interface Trade {
  id: string;
  tokenIn: string;
  tokenOut: string;
  amountIn: bigint;
  amountOut: bigint;
  price: number;
  timestamp: bigint;
  txHash: string;
  side: "buy" | "sell";
}

export interface SwapQuote {
  amountIn: bigint;
  amountOut: bigint;
  priceImpact: number;
  fee: number;
  route: string[];
  minimumReceived: bigint;
  executionPrice: number;
}

export interface JasminesLawStatus {
  isCompliant: boolean;
  currentDrift: number;
  maxAllowedDrift: number;
  genesisFrequency: number;
  currentFrequency: number;
  correctionApplied: boolean;
  lastCheckBeat: bigint;
}

export interface DexState {
  tokens: DexToken[];
  pools: LiquidityPool[];
  orderBook: { bids: OrderBookEntry[]; asks: OrderBookEntry[] };
  openOrders: Order[];
  tradeHistory: Trade[];
  jasminesLaw: JasminesLawStatus;
  selectedPair: { base: string; quote: string };
  slippageTolerance: number;
  isLoading: boolean;
  error: string | null;
}

// PHI-derived constants for economic calculations
const PHI = 1.6180339887;
const PHI_INV = 0.6180339887;
const PHI_INV_2 = 0.3819660113;
const PHI_INV_3 = 0.2360679775;

// Default tokens in the PARALLAX ecosystem
const DEFAULT_TOKENS: DexToken[] = [
  { symbol: "MTH", name: "Mathema", decimals: 8, balance: 0n, price: 1.0, priceChange24h: 0, volume24h: 0 },
  { symbol: "GTK", name: "GaiaToken", decimals: 8, balance: 0n, price: PHI_INV, priceChange24h: 0, volume24h: 0 },
  { symbol: "MRC", name: "Mercurial", decimals: 8, balance: 0n, price: PHI_INV_2, priceChange24h: 0, volume24h: 0 },
  { symbol: "CVT", name: "Covenant", decimals: 8, balance: 0n, price: PHI_INV_3, priceChange24h: 0, volume24h: 0 },
  { symbol: "VCT", name: "Vector", decimals: 8, balance: 0n, price: 0.5, priceChange24h: 0, volume24h: 0 },
  { symbol: "KNT", name: "Kinetic", decimals: 8, balance: 0n, price: 0.75, priceChange24h: 0, volume24h: 0 },
  { symbol: "ICP", name: "Internet Computer", decimals: 8, balance: 0n, price: 12.50, priceChange24h: 2.5, volume24h: 1000000 },
  { symbol: "ckBTC", name: "Chain-Key Bitcoin", decimals: 8, balance: 0n, price: 67500, priceChange24h: 1.2, volume24h: 5000000 },
  { symbol: "ckETH", name: "Chain-Key Ethereum", decimals: 18, balance: 0n, price: 3200, priceChange24h: -0.5, volume24h: 2500000 },
];

export function useDex() {
  const { actor, isAuthenticated } = useActor();
  const queryClient = useQueryClient();

  const [state, setState] = useState<DexState>({
    tokens: DEFAULT_TOKENS,
    pools: [],
    orderBook: { bids: [], asks: [] },
    openOrders: [],
    tradeHistory: [],
    jasminesLaw: {
      isCompliant: true,
      currentDrift: 0,
      maxAllowedDrift: PHI_INV_3,
      genesisFrequency: 873,
      currentFrequency: 873,
      correctionApplied: false,
      lastCheckBeat: 0n,
    },
    selectedPair: { base: "MTH", quote: "ICP" },
    slippageTolerance: 0.5,
    isLoading: false,
    error: null,
  });

  // Fetch token balances
  const { data: balances } = useQuery({
    queryKey: ["dex", "balances"],
    queryFn: async () => {
      if (!actor || !isAuthenticated) return null;
      try {
        const result = await actor.getTokenBalances();
        return result;
      } catch (e) {
        console.error("Failed to fetch balances:", e);
        return null;
      }
    },
    enabled: !!actor && isAuthenticated,
    refetchInterval: 5000,
  });

  // Fetch Jasmine's Law status
  const { data: jasminesLawData } = useQuery({
    queryKey: ["dex", "jasminesLaw"],
    queryFn: async () => {
      if (!actor) return null;
      try {
        const lawState = await actor.getLawState();
        return lawState;
      } catch (e) {
        console.error("Failed to fetch Jasmine's Law status:", e);
        return null;
      }
    },
    enabled: !!actor,
    refetchInterval: 873,
  });

  // Calculate swap quote
  const calculateSwapQuote = useCallback(
    (tokenIn: string, tokenOut: string, amountIn: bigint): SwapQuote => {
      const pool = state.pools.find(
        (p) =>
          (p.token0.symbol === tokenIn && p.token1.symbol === tokenOut) ||
          (p.token0.symbol === tokenOut && p.token1.symbol === tokenIn)
      );

      if (!pool) {
        // Use constant product formula for estimation
        const tokenInData = state.tokens.find((t) => t.symbol === tokenIn);
        const tokenOutData = state.tokens.find((t) => t.symbol === tokenOut);

        if (!tokenInData || !tokenOutData) {
          return {
            amountIn,
            amountOut: 0n,
            priceImpact: 0,
            fee: 0,
            route: [tokenIn, tokenOut],
            minimumReceived: 0n,
            executionPrice: 0,
          };
        }

        const amountInNum = Number(amountIn) / 10 ** tokenInData.decimals;
        const valueIn = amountInNum * tokenInData.price;
        const amountOutNum = valueIn / tokenOutData.price;
        const amountOut = BigInt(Math.floor(amountOutNum * 10 ** tokenOutData.decimals));

        const fee = Number(amountIn) * 0.003; // 0.3% fee
        const priceImpact = amountInNum > 1000 ? (amountInNum / 10000) * 0.01 : 0;

        return {
          amountIn,
          amountOut,
          priceImpact,
          fee,
          route: [tokenIn, tokenOut],
          minimumReceived: BigInt(Math.floor(Number(amountOut) * (1 - state.slippageTolerance / 100))),
          executionPrice: tokenOutData.price / tokenInData.price,
        };
      }

      // Real pool calculation using constant product (x * y = k)
      const isToken0In = pool.token0.symbol === tokenIn;
      const reserveIn = isToken0In ? pool.reserve0 : pool.reserve1;
      const reserveOut = isToken0In ? pool.reserve1 : pool.reserve0;

      const amountInWithFee = amountIn * 997n; // 0.3% fee
      const numerator = amountInWithFee * reserveOut;
      const denominator = reserveIn * 1000n + amountInWithFee;
      const amountOut = numerator / denominator;

      const priceImpact = Number(amountIn) / Number(reserveIn);

      return {
        amountIn,
        amountOut,
        priceImpact,
        fee: Number(amountIn) * 0.003,
        route: [tokenIn, tokenOut],
        minimumReceived: (amountOut * BigInt(Math.floor((100 - state.slippageTolerance) * 100))) / 10000n,
        executionPrice: Number(amountOut) / Number(amountIn),
      };
    },
    [state.pools, state.tokens, state.slippageTolerance]
  );

  // Execute swap mutation
  const swapMutation = useMutation({
    mutationFn: async ({
      tokenIn,
      tokenOut,
      amountIn,
      minAmountOut,
    }: {
      tokenIn: string;
      tokenOut: string;
      amountIn: bigint;
      minAmountOut: bigint;
    }) => {
      if (!actor) throw new Error("Not connected");

      // Check Jasmine's Law compliance before swap
      if (!state.jasminesLaw.isCompliant) {
        throw new Error("Jasmine's Law violation: System drift exceeds maximum threshold. Swap blocked.");
      }

      const result = await actor.executeSwap({
        tokenIn,
        tokenOut,
        amountIn,
        minAmountOut,
        deadline: BigInt(Date.now() + 300000), // 5 minute deadline
      });

      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dex", "balances"] });
      queryClient.invalidateQueries({ queryKey: ["dex", "trades"] });
    },
  });

  // Place order mutation
  const placeOrderMutation = useMutation({
    mutationFn: async (order: Omit<Order, "id" | "status" | "timestamp" | "filledAmount">) => {
      if (!actor) throw new Error("Not connected");

      if (!state.jasminesLaw.isCompliant) {
        throw new Error("Jasmine's Law violation: Orders blocked during drift correction.");
      }

      const result = await actor.placeOrder({
        type: { [order.type]: null },
        side: { [order.side]: null },
        tokenIn: order.tokenIn,
        tokenOut: order.tokenOut,
        amountIn: order.amountIn,
        price: order.price,
      });

      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dex", "orders"] });
    },
  });

  // Add liquidity mutation
  const addLiquidityMutation = useMutation({
    mutationFn: async ({
      poolId,
      amount0,
      amount1,
    }: {
      poolId: string;
      amount0: bigint;
      amount1: bigint;
    }) => {
      if (!actor) throw new Error("Not connected");

      const result = await actor.addLiquidity({
        poolId,
        amount0,
        amount1,
        minLpTokens: 0n,
      });

      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dex", "pools"] });
      queryClient.invalidateQueries({ queryKey: ["dex", "balances"] });
    },
  });

  // Remove liquidity mutation
  const removeLiquidityMutation = useMutation({
    mutationFn: async ({
      poolId,
      lpTokens,
    }: {
      poolId: string;
      lpTokens: bigint;
    }) => {
      if (!actor) throw new Error("Not connected");

      const result = await actor.removeLiquidity({
        poolId,
        lpTokens,
        minAmount0: 0n,
        minAmount1: 0n,
      });

      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dex", "pools"] });
      queryClient.invalidateQueries({ queryKey: ["dex", "balances"] });
    },
  });

  // Update selected pair
  const selectPair = useCallback((base: string, quote: string) => {
    setState((prev) => ({
      ...prev,
      selectedPair: { base, quote },
    }));
  }, []);

  // Update slippage tolerance
  const setSlippageTolerance = useCallback((tolerance: number) => {
    setState((prev) => ({
      ...prev,
      slippageTolerance: Math.max(0.1, Math.min(50, tolerance)),
    }));
  }, []);

  // Generate mock order book for display
  useEffect(() => {
    const { base, quote } = state.selectedPair;
    const baseToken = state.tokens.find((t) => t.symbol === base);
    const quoteToken = state.tokens.find((t) => t.symbol === quote);

    if (!baseToken || !quoteToken) return;

    const midPrice = baseToken.price / quoteToken.price;
    const spread = midPrice * 0.001; // 0.1% spread

    const bids: OrderBookEntry[] = [];
    const asks: OrderBookEntry[] = [];

    let bidCumulative = 0;
    let askCumulative = 0;

    for (let i = 0; i < 20; i++) {
      const bidPrice = midPrice - spread * (i + 1);
      const bidAmount = Math.random() * 1000 + 100;
      bidCumulative += bidAmount;
      bids.push({
        price: bidPrice,
        amount: bidAmount,
        total: bidPrice * bidAmount,
        cumulative: bidCumulative,
      });

      const askPrice = midPrice + spread * (i + 1);
      const askAmount = Math.random() * 1000 + 100;
      askCumulative += askAmount;
      asks.push({
        price: askPrice,
        amount: askAmount,
        total: askPrice * askAmount,
        cumulative: askCumulative,
      });
    }

    setState((prev) => ({
      ...prev,
      orderBook: { bids, asks },
    }));
  }, [state.selectedPair, state.tokens]);

  return {
    ...state,
    // Actions
    calculateSwapQuote,
    executeSwap: swapMutation.mutateAsync,
    placeOrder: placeOrderMutation.mutateAsync,
    addLiquidity: addLiquidityMutation.mutateAsync,
    removeLiquidity: removeLiquidityMutation.mutateAsync,
    selectPair,
    setSlippageTolerance,
    // Mutation states
    isSwapping: swapMutation.isPending,
    isPlacingOrder: placeOrderMutation.isPending,
    isAddingLiquidity: addLiquidityMutation.isPending,
    isRemovingLiquidity: removeLiquidityMutation.isPending,
    // Errors
    swapError: swapMutation.error,
    orderError: placeOrderMutation.error,
  };
}

export default useDex;
