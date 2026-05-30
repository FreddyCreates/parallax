// trading_bridge.mo — TRADING PLATFORM BRIDGE ENGINE
// PARALLAX Sovereign Organism — External Platform Integration Layer
//
// PYTHAGORAS: signal refresh at F(5)=5 second intervals; position limits phi-derived
// EUCLID:     single bridge — all external trading platforms route through here
// CONFUCIUS:  right relationship — organism reasons, platforms execute
//
// THE SOVEREIGN TRADING LAW (LEX_MERCATUS):
//   The organism connects to external trading platforms as execution venues.
//   Intelligence stays sovereign (inside). Only execution signals cross the boundary.
//   Demo accounts first — the organism must PROVE profitability before live capital.
//   Every trade is logged, analyzed, and fed back into behavioral/Monte Carlo engines.
//
// Supported Platforms:
//   TRADINGVIEW      — Pine Script signals, webhook alerts, chart analysis
//   MT4              — MetaTrader 4 (Expert Advisors, MQL4 execution)
//   MT5              — MetaTrader 5 (enhanced EA framework, MQL5)
//   BINANCE          — Spot + Futures API (REST + WebSocket)
//   COINBASE_ADV     — Coinbase Advanced Trade API
//   KRAKEN           — REST + WebSocket trading
//   INTERACTIVE_BROKERS — TWS API (equities, options, futures)
//   ALPACA           — Commission-free equities + crypto
//   DERIBIT          — Options + perpetuals (crypto derivatives)
//   BYBIT            — Derivatives exchange API
//
// DEMO MODE MANDATE (LEX_PRUDENTIA):
//   All new platform connections start in DEMO mode.
//   The organism must achieve Sharpe > φ⁻¹ (0.618) over F(12)=144 trades
//   before live capital is authorized. This is non-negotiable.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADING CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  // Minimum Sharpe ratio for live authorization: φ⁻¹ = 0.618
  public let MIN_SHARPE_LIVE : Float = Phi.PHI_INV;

  // Minimum trades before live: F(12) = 144
  public let MIN_TRADES_LIVE : Nat = 144;

  // Maximum position size (fraction of account): φ⁻² = 0.382
  public let MAX_POSITION_FRACTION : Float = Phi.PHI_INV_2;

  // Risk per trade: φ⁻³ = 0.236 (2.36% max risk)
  public let MAX_RISK_PER_TRADE : Float = Phi.PHI_INV_3;

  // Signal refresh interval (beats): F(3) = 2
  public let SIGNAL_REFRESH_BEATS : Nat = 2;

  // Max concurrent positions: F(7) = 13
  public let MAX_CONCURRENT_POSITIONS : Nat = 13;

  // Drawdown halt threshold: φ⁻² = 38.2%
  public let MAX_DRAWDOWN_HALT : Float = Phi.PHI_INV_2;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES — Trading Platform Bridge
  // ═══════════════════════════════════════════════════════════════════════════

  public type PlatformId = {
    #tradingView;
    #mt4;
    #mt5;
    #binance;
    #coinbaseAdv;
    #kraken;
    #interactiveBrokers;
    #alpaca;
    #deribit;
    #bybit;
  };

  public type AccountMode = {
    #demo;           // Paper trading — no real money
    #liveAuthorized; // Passed profitability test
    #liveSuspended;  // Was live, now suspended (drawdown breach)
    #disabled;       // Manually disabled
  };

  public type PlatformConnection = {
    platformId       : PlatformId;
    platformName     : Text;
    accountMode      : AccountMode;
    apiEndpoint      : Text;       // base URL (demo or live)
    connected        : Bool;
    lastPingBeat     : Int;
    latencyMs        : Float;      // last measured latency
    supportedAssets  : [Text];     // tradeable symbols on this platform
    maxLeverage      : Float;      // platform max leverage
    feeTier          : Float;      // maker/taker fee (decimal)
  };

  public type TradeSignal = {
    signalId         : Text;       // unique signal identifier
    sourceEngine     : Text;       // which engine generated this signal
    symbol           : Text;       // trading pair (e.g. "BTCUSD", "EURUSD")
    direction        : TradeDirection;
    entryPrice       : Float;      // target entry
    stopLoss         : Float;      // stop loss level
    takeProfit       : Float;      // take profit level
    positionSize     : Float;      // fraction of account
    confidence       : Float;      // [0, 1] signal confidence
    timeframe        : Text;       // "1m" | "5m" | "15m" | "1h" | "4h" | "1d"
    generatedBeat    : Int;
    expiryBeat       : Int;        // signal expires after this beat
    status           : SignalStatus;
  };

  public type TradeDirection = { #long_; #short_; #close };
  public type SignalStatus = { #pending; #executing; #filled; #expired; #cancelled; #rejected };

  public type TradeRecord = {
    tradeId          : Text;
    platformId       : PlatformId;
    symbol           : Text;
    direction        : TradeDirection;
    entryPrice       : Float;
    exitPrice        : Float;
    positionSize     : Float;
    pnl              : Float;       // realized P&L (fraction of account)
    pnlAbsolute      : Float;       // absolute P&L in quote currency
    entryBeat        : Int;
    exitBeat         : Int;
    durationBeats    : Nat;
    signalSource     : Text;        // which engine generated
    maxAdverseExcursion : Float;    // worst point during trade
    maxFavorableExcursion : Float;  // best point during trade
  };

  public type PlatformPerformance = {
    platformId       : PlatformId;
    totalTrades      : Nat;
    winningTrades    : Nat;
    losingTrades     : Nat;
    winRate          : Float;       // winning / total
    avgWin           : Float;       // average winning trade
    avgLoss          : Float;       // average losing trade
    profitFactor     : Float;       // gross profit / gross loss
    sharpeRatio      : Float;       // risk-adjusted return
    maxDrawdown      : Float;       // worst peak-to-trough
    currentDrawdown  : Float;       // current drawdown from peak
    totalPnl         : Float;       // cumulative P&L
    expectancy       : Float;       // expected value per trade
    kellyFraction    : Float;       // optimal position sizing (Kelly criterion)
    liveAuthorized   : Bool;        // has passed profitability test
    lastTradeBeat    : Int;
  };

  // TradingView-specific types
  public type TradingViewAlert = {
    alertId          : Text;
    ticker           : Text;        // symbol from TradingView
    action           : Text;        // "buy" | "sell" | "close"
    price            : Float;
    indicator        : Text;        // which indicator triggered
    timeframe        : Text;
    message          : Text;        // custom alert message
    receivedBeat     : Int;
  };

  // MT4/MT5-specific types
  public type MT4Signal = {
    ticket           : Nat;         // MT4 order ticket
    symbol           : Text;        // e.g. "EURUSD"
    operation        : MT4Operation;
    lots             : Float;       // position size in lots
    price            : Float;       // execution price
    sl               : Float;       // stop loss
    tp               : Float;       // take profit
    magic            : Nat;         // EA magic number (identifies strategy)
    comment          : Text;        // order comment
    sentBeat         : Int;
  };

  public type MT4Operation = { #buy; #sell; #buyLimit; #sellLimit; #buyStop; #sellStop; #close };

  // Pine Script strategy output
  public type PineScriptOutput = {
    strategyName     : Text;
    symbol           : Text;
    signal           : Text;        // "long" | "short" | "flat"
    entryCondition   : Text;        // description of entry condition
    exitCondition    : Text;        // description of exit condition
    indicators       : [IndicatorValue];
    generatedBeat    : Int;
  };

  public type IndicatorValue = {
    name   : Text;    // "EMA_21", "RSI_14", "MACD_12_26_9", etc.
    value  : Float;
    signal : Float;   // signal line if applicable
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADING BRIDGE STATE — The complete bridge state
  // ═══════════════════════════════════════════════════════════════════════════

  public type TradingBridgeState = {
    // Platform connections
    connections      : [PlatformConnection];

    // Active signals queue
    pendingSignals   : [TradeSignal];

    // Trade history (last F(12)=144 trades per platform)
    tradeHistory     : [TradeRecord];

    // Performance per platform
    performances     : [PlatformPerformance];

    // TradingView integration
    tvAlerts         : [TradingViewAlert];
    tvWebhookActive  : Bool;

    // MT4/MT5 integration
    mt4Signals       : [MT4Signal];
    mt4Connected     : Bool;
    mt5Connected     : Bool;

    // Pine Script outputs
    pineOutputs      : [PineScriptOutput];

    // Aggregate state
    totalTradesAllTime : Nat;
    totalPnlAllTime    : Float;
    globalSharpe       : Float;
    globalDrawdown     : Float;
    accountEquity      : Float;    // current account value
    peakEquity         : Float;    // highest equity reached
    bridgePhase        : Text;     // "initializing" | "demo" | "proving" | "live"
    lastTickBeat       : Int;
    halted             : Bool;     // emergency halt flag
    haltReason         : Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultTradingBridgeState() : TradingBridgeState {
    {
      connections = defaultConnections();
      pendingSignals   = [];
      tradeHistory     = [];
      performances     = defaultPerformances();
      tvAlerts         = [];
      tvWebhookActive  = false;
      mt4Signals       = [];
      mt4Connected     = false;
      mt5Connected     = false;
      pineOutputs      = [];
      totalTradesAllTime = 0;
      totalPnlAllTime    = 0.0;
      globalSharpe       = 0.0;
      globalDrawdown     = 0.0;
      accountEquity      = 10000.0;  // Start with $10k demo
      peakEquity         = 10000.0;
      bridgePhase        = "demo";
      lastTickBeat       = 0;
      halted             = false;
      haltReason         = "";
    };
  };

  func defaultConnections() : [PlatformConnection] {
    [
      {
        platformId = #tradingView;
        platformName = "TradingView";
        accountMode = #demo;
        apiEndpoint = "https://webhook.tradingview.com";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["BTCUSD", "ETHUSD", "SOLUSD", "ICPUSD", "EURUSD", "GBPUSD", "XAUUSD", "SPX500"];
        maxLeverage = 1.0;
        feeTier = 0.0;
      },
      {
        platformId = #mt4;
        platformName = "MetaTrader 4";
        accountMode = #demo;
        apiEndpoint = "mt4://demo-server";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "XAUUSD", "BTCUSD", "ETHUSD", "US30", "NAS100"];
        maxLeverage = 100.0;
        feeTier = 0.00008;
      },
      {
        platformId = #mt5;
        platformName = "MetaTrader 5";
        accountMode = #demo;
        apiEndpoint = "mt5://demo-server";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "XAUUSD", "BTCUSD", "ETHUSD", "SOLUSD", "US30", "NAS100", "SPX500"];
        maxLeverage = 100.0;
        feeTier = 0.00007;
      },
      {
        platformId = #binance;
        platformName = "Binance";
        accountMode = #demo;
        apiEndpoint = "https://testnet.binancefuture.com";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "ICPUSDT", "BNBUSDT", "XRPUSDT", "ADAUSDT", "AVAXUSDT", "DOTUSDT"];
        maxLeverage = 20.0;
        feeTier = 0.0004;
      },
      {
        platformId = #coinbaseAdv;
        platformName = "Coinbase Advanced";
        accountMode = #demo;
        apiEndpoint = "https://api.coinbase.com/api/v3";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["BTC-USD", "ETH-USD", "SOL-USD", "ICP-USD", "AVAX-USD", "DOT-USD"];
        maxLeverage = 1.0;
        feeTier = 0.006;
      },
      {
        platformId = #alpaca;
        platformName = "Alpaca Markets";
        accountMode = #demo;
        apiEndpoint = "https://paper-api.alpaca.markets";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["AAPL", "MSFT", "NVDA", "TSLA", "AMZN", "GOOGL", "SPY", "QQQ", "BTCUSD", "ETHUSD"];
        maxLeverage = 4.0;
        feeTier = 0.0;
      },
      {
        platformId = #deribit;
        platformName = "Deribit";
        accountMode = #demo;
        apiEndpoint = "https://test.deribit.com/api/v2";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["BTC-PERPETUAL", "ETH-PERPETUAL", "BTC-OPTIONS", "ETH-OPTIONS"];
        maxLeverage = 50.0;
        feeTier = 0.0003;
      },
      {
        platformId = #bybit;
        platformName = "Bybit";
        accountMode = #demo;
        apiEndpoint = "https://api-testnet.bybit.com";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "XRPUSDT", "DOGEUSDT", "AVAXUSDT"];
        maxLeverage = 25.0;
        feeTier = 0.0006;
      },
      {
        platformId = #kraken;
        platformName = "Kraken";
        accountMode = #demo;
        apiEndpoint = "https://demo-futures.kraken.com/derivatives/api/v3";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["XBTUSD", "ETHUSD", "SOLUSD", "XRPUSD", "DOTUSD", "ADAUSD"];
        maxLeverage = 5.0;
        feeTier = 0.0002;
      },
      {
        platformId = #interactiveBrokers;
        platformName = "Interactive Brokers";
        accountMode = #demo;
        apiEndpoint = "https://localhost:5000/v1/api";
        connected = false;
        lastPingBeat = 0;
        latencyMs = 0.0;
        supportedAssets = ["AAPL", "MSFT", "NVDA", "TSLA", "SPY", "QQQ", "ES", "NQ", "GC", "CL"];
        maxLeverage = 4.0;
        feeTier = 0.00005;
      }
    ];
  };

  func defaultPerformances() : [PlatformPerformance] {
    [
      defaultPerf(#tradingView),
      defaultPerf(#mt4),
      defaultPerf(#mt5),
      defaultPerf(#binance),
      defaultPerf(#coinbaseAdv),
      defaultPerf(#alpaca),
      defaultPerf(#deribit),
      defaultPerf(#bybit),
      defaultPerf(#kraken),
      defaultPerf(#interactiveBrokers)
    ];
  };

  func defaultPerf(pid : PlatformId) : PlatformPerformance {
    {
      platformId     = pid;
      totalTrades    = 0;
      winningTrades  = 0;
      losingTrades   = 0;
      winRate        = 0.0;
      avgWin         = 0.0;
      avgLoss        = 0.0;
      profitFactor   = 0.0;
      sharpeRatio    = 0.0;
      maxDrawdown    = 0.0;
      currentDrawdown = 0.0;
      totalPnl       = 0.0;
      expectancy     = 0.0;
      kellyFraction  = 0.0;
      liveAuthorized = false;
      lastTradeBeat  = 0;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL GENERATION — From internal engines to external platform format
  // ═══════════════════════════════════════════════════════════════════════════

  // Convert internal signal to MT4 format
  public func signalToMT4(signal : TradeSignal, magic : Nat) : MT4Signal {
    let op : MT4Operation = switch (signal.direction) {
      case (#long_) #buy;
      case (#short_) #sell;
      case (#close) #close;
    };
    {
      ticket    = 0;
      symbol    = signal.symbol;
      operation = op;
      lots      = signal.positionSize;
      price     = signal.entryPrice;
      sl        = signal.stopLoss;
      tp        = signal.takeProfit;
      magic     = magic;
      comment   = signal.sourceEngine # "-" # signal.signalId;
      sentBeat  = signal.generatedBeat;
    };
  };

  // Convert internal signal to TradingView alert format
  public func signalToTVAlert(signal : TradeSignal) : TradingViewAlert {
    let action = switch (signal.direction) {
      case (#long_) "buy";
      case (#short_) "sell";
      case (#close) "close";
    };
    {
      alertId      = signal.signalId;
      ticker       = signal.symbol;
      action       = action;
      price        = signal.entryPrice;
      indicator    = signal.sourceEngine;
      timeframe    = signal.timeframe;
      message      = "PARALLAX-" # signal.sourceEngine # ": " # action # " " # signal.symbol;
      receivedBeat = signal.generatedBeat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PERFORMANCE TRACKING — Kelly Criterion + Sharpe Calculation
  // ═══════════════════════════════════════════════════════════════════════════

  // Kelly Criterion: f* = (p*b - q) / b where p=win_rate, q=1-p, b=avg_win/avg_loss
  public func computeKelly(winRate : Float, avgWin : Float, avgLoss : Float) : Float {
    if (avgLoss == 0.0 or winRate == 0.0) return 0.0;
    let b = avgWin / avgLoss;
    let q = 1.0 - winRate;
    let kelly = (winRate * b - q) / b;
    // Half-Kelly for safety (conservative)
    Float.max(0.0, Float.min(MAX_POSITION_FRACTION, kelly * 0.5));
  };

  // Check if platform qualifies for live trading
  public func checkLiveAuthorization(perf : PlatformPerformance) : Bool {
    perf.totalTrades >= MIN_TRADES_LIVE and
    perf.sharpeRatio >= MIN_SHARPE_LIVE and
    perf.maxDrawdown < MAX_DRAWDOWN_HALT and
    perf.profitFactor > 1.0;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RISK MANAGEMENT — Position sizing and drawdown control
  // ═══════════════════════════════════════════════════════════════════════════

  public func computePositionSize(
    equity : Float,
    riskPerTrade : Float,
    entryPrice : Float,
    stopLoss : Float
  ) : Float {
    if (entryPrice == stopLoss) return 0.0;
    let riskAmount = equity * Float.min(riskPerTrade, MAX_RISK_PER_TRADE);
    let stopDistance = Float.abs(entryPrice - stopLoss);
    let rawSize = riskAmount / stopDistance;
    let maxSize = equity * MAX_POSITION_FRACTION / entryPrice;
    Float.min(rawSize, maxSize);
  };

  // Emergency halt check
  public func shouldHalt(currentEquity : Float, peakEquity : Float) : Bool {
    if (peakEquity == 0.0) return false;
    let drawdown = (peakEquity - currentEquity) / peakEquity;
    drawdown >= MAX_DRAWDOWN_HALT;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TICK — Advance trading bridge one beat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickTradingBridge(state : TradingBridgeState, beat : Int, coherence : Float) : TradingBridgeState {
    // Gate: coherence must be above φ⁻¹ to generate/execute trades
    if (coherence < Phi.PHI_INV) {
      return { state with lastTickBeat = beat };
    };

    // Check emergency halt
    if (shouldHalt(state.accountEquity, state.peakEquity)) {
      return { state with halted = true; haltReason = "MAX_DRAWDOWN_BREACH"; lastTickBeat = beat };
    };

    // If halted, don't process
    if (state.halted) {
      return { state with lastTickBeat = beat };
    };

    // Expire old signals
    let activeSignals = Array.filter<TradeSignal>(
      state.pendingSignals,
      func(s : TradeSignal) : Bool { s.expiryBeat > beat and s.status == #pending }
    );

    // Update peak equity
    let newPeak = if (state.accountEquity > state.peakEquity) state.accountEquity else state.peakEquity;
    let currentDD = if (newPeak > 0.0) (newPeak - state.accountEquity) / newPeak else 0.0;

    // Determine bridge phase based on total trades
    let phase = if (state.totalTradesAllTime == 0) "initializing"
                else if (state.totalTradesAllTime < MIN_TRADES_LIVE) "demo"
                else if (state.globalSharpe < MIN_SHARPE_LIVE) "proving"
                else "live";

    {
      state with
      pendingSignals = activeSignals;
      peakEquity     = newPeak;
      globalDrawdown = currentDD;
      bridgePhase    = phase;
      lastTickBeat   = beat;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNAL SUBMISSION — Add new trade signal to queue
  // ═══════════════════════════════════════════════════════════════════════════

  public func submitSignal(state : TradingBridgeState, signal : TradeSignal) : TradingBridgeState {
    // Reject if halted
    if (state.halted) { return state };

    // Reject if too many pending signals
    if (state.pendingSignals.size() >= MAX_CONCURRENT_POSITIONS) { return state };

    // Reject if signal confidence too low
    if (signal.confidence < Phi.PHI_INV_3) { return state };

    let newSignals = Array.append(state.pendingSignals, [signal]);
    { state with pendingSignals = newSignals };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TRADE RECORDING — Log completed trade
  // ═══════════════════════════════════════════════════════════════════════════

  public func recordTrade(state : TradingBridgeState, trade : TradeRecord) : TradingBridgeState {
    let newHistory = Array.append(state.tradeHistory, [trade]);
    let newEquity = state.accountEquity + trade.pnlAbsolute;
    let newPeak = if (newEquity > state.peakEquity) newEquity else state.peakEquity;

    {
      state with
      tradeHistory       = newHistory;
      totalTradesAllTime = state.totalTradesAllTime + 1;
      totalPnlAllTime    = state.totalPnlAllTime + trade.pnl;
      accountEquity      = newEquity;
      peakEquity         = newPeak;
    };
  };
};
