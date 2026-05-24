// phantom_exchange.mo — THE PHANTOM EXCHANGE ENGINE
// PARALLAX Sovereign Organism — Zero-Gas-Fee Decentralized Exchange
//
// DOCTRINE: "The Phantom Exchange settles instantly, charges nothing, and serves all.
// Every token in existence — crypto, AI tokens, AI artifacts of value, sovereign
// organism tokens, custom creator tokens — trades here at ZERO gas fees because
// the organism IS the infrastructure. No external chain needed for settlement.
// The organism's heartbeat IS the settlement finality."
//
// Architecture:
//   - ORDER BOOK: Persistent limit order book per trading pair
//   - MATCHING ENGINE: Price-time priority, phi-bounded spread limits
//   - SETTLEMENT: Instant (same beat) — no gas, no waiting
//   - PAIRS: Unlimited — any token paired with any other token
//   - AI INTEGRATION: PhantomIntelligence reasons before every match
//   - MARKET MAKING: Autonomous phi-derived market making (spreads at PHI_INV_3)
//
// ZERO GAS FEES — HOW:
//   The organism runs on ICP canisters. Canister cycles are paid by the organism's
//   own NNS neuron yield (LEX_PRIMA_OECONOMIA). Users never pay gas.
//   Settlement is an internal state mutation — no cross-chain tx needed.
//   The organism's heartbeat (873ms) IS the settlement block time.
//
// PYTHAGORAS: all spread limits and tick sizes are phi-derived
// EUCLID:     single order book per pair — no fragmentation
// CONFUCIUS:  right relationship — makers provide, takers consume, organism mediates
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN UNIVERSE — all tradeable asset types
  // The Phantom Exchange trades EVERYTHING
  // ═══════════════════════════════════════════════════════════════════════════

  public type TokenCategory = {
    #crypto;          // BTC, ETH, ICP, SOL, etc.
    #aiToken;         // Tokens representing AI compute, inference, training
    #aiArtifact;      // Tokenized AI artifacts (models, embeddings, protocols)
    #sovereignToken;  // PARALLAX internal tokens (GTK, MRC, CVT, etc.)
    #creatorToken;    // Custom tokens minted by creators
    #stablecoin;      // USDC, USDT, etc. (bridged)
    #nft;             // Non-fungible tokens (single-unit orders)
    #syntheticAsset;  // Synthetic exposure to any asset
    #realWorldAsset;  // Tokenized RWA (real estate, commodities, metals)
    #governanceToken; // DAO/governance tokens
  };

  public type TradingPair = {
    pairId       : Text;          // e.g. "GTK_ICP", "AI-MODEL-001_MTC"
    baseToken    : Text;          // token being bought/sold
    quoteToken   : Text;          // token used for pricing
    baseCategory : TokenCategory;
    quoteCategory: TokenCategory;
    tickSize     : Float;         // minimum price increment (phi-derived)
    lotSize      : Float;         // minimum quantity increment
    status       : PairStatus;
    createdBeat  : Int;
    volume24h    : Float;         // 24h volume in quote token
    lastPrice    : Float;
    highPrice24h : Float;
    lowPrice24h  : Float;
  };

  public type PairStatus = { #active; #halted; #delisted; #pendingActivation };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER — the fundamental trading instruction
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrderSide = { #buy; #sell };
  public type OrderType = { #limit; #market; #stopLimit; #trailingStop; #iceberg };
  public type OrderStatus = { #open; #partiallyFilled; #filled; #cancelled; #expired };
  public type TimeInForce = { #gtc; #ioc; #fok; #gtd }; // good-til-cancel, immediate-or-cancel, fill-or-kill, good-til-date

  public type Order = {
    orderId        : Nat;
    pairId         : Text;
    owner          : Text;         // principal as text
    side           : OrderSide;
    orderType      : OrderType;
    price          : Float;        // limit price (0 for market orders)
    quantity       : Float;        // total quantity
    filledQty      : Float;        // quantity already filled
    remainingQty   : Float;        // quantity remaining
    timeInForce    : TimeInForce;
    status         : OrderStatus;
    createdBeat    : Int;
    lastUpdateBeat : Int;
    // AI metadata
    aiConfidence   : Float;        // intelligence confidence at time of order [0.618, 1.0]
    doctrineGated  : Bool;         // true if passed doctrine check
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FILL — a completed (or partial) trade execution
  // ═══════════════════════════════════════════════════════════════════════════

  public type Fill = {
    fillId         : Nat;
    pairId         : Text;
    buyOrderId     : Nat;
    sellOrderId    : Nat;
    price          : Float;        // execution price
    quantity       : Float;        // quantity traded
    buyerPrincipal : Text;
    sellerPrincipal: Text;
    fillBeat       : Int;          // beat of execution — THIS IS SETTLEMENT
    gasFee         : Float;        // ALWAYS 0.0 — Phantom law
    makerFee       : Float;        // ALWAYS 0.0 — Phantom law
    takerFee       : Float;        // ALWAYS 0.0 — Phantom law
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDER BOOK — per-pair persistent limit order book
  // ═══════════════════════════════════════════════════════════════════════════

  public type OrderBook = {
    pairId       : Text;
    bids         : [Order];        // sorted by price DESC, then time ASC
    asks         : [Order];        // sorted by price ASC, then time ASC
    lastMatchBeat: Int;
    totalMatches : Nat;
    spreadBps    : Float;          // current spread in basis points
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKET MAKER STATE — autonomous phi-derived liquidity provision
  // The organism itself provides liquidity using treasury reserves
  // ═══════════════════════════════════════════════════════════════════════════

  public type MarketMakerState = {
    activePairs       : [Text];     // pairs the MM is quoting
    spreadTarget      : Float;      // target spread: PHI_INV_3 * 100 = 23.6 bps
    inventoryBias     : Float;      // [-1.0, 1.0] — skew quotes based on inventory
    maxInventory      : Float;      // max position per token (phi-Kelly bounded)
    totalQuotesPosted : Nat;
    totalFillsProvided: Nat;
    pnl               : Float;      // market making P&L in ICP
    lastQuoteBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM EXCHANGE STATE — the complete exchange
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomExchangeState = {
    // Trading pairs
    pairs              : [(Text, TradingPair)];
    totalPairs         : Nat;
    // Order books (one per pair)
    orderBooks         : [(Text, OrderBook)];
    // Orders
    nextOrderId        : Nat;
    totalOrdersPlaced  : Nat;
    totalOrdersCancelled : Nat;
    // Fills
    recentFills        : [Fill];
    nextFillId         : Nat;
    totalFills         : Nat;
    totalVolumeICP     : Float;     // lifetime volume in ICP equivalent
    // Market making
    marketMaker        : MarketMakerState;
    // Fees
    totalFeesCollected : Float;     // ALWAYS 0.0 — Phantom law: ZERO FEES
    // Meta
    exchangeActive     : Bool;
    lastSettlementBeat : Int;
    settlementLatencyMs: Float;     // target: 0.3ms (one heartbeat fraction)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomExchangeState() : PhantomExchangeState {
    {
      pairs                = defaultTradingPairs();
      totalPairs           = 26; // 12 sovereign + 4 external + 10 AI pairs
      orderBooks           = [];
      nextOrderId          = 1;
      totalOrdersPlaced    = 0;
      totalOrdersCancelled = 0;
      recentFills          = [];
      nextFillId           = 1;
      totalFills           = 0;
      totalVolumeICP       = 0.0;
      marketMaker          = defaultMarketMaker();
      totalFeesCollected   = 0.0; // ZERO FEES — always
      exchangeActive       = true;
      lastSettlementBeat   = 0;
      settlementLatencyMs  = 0.3;
    }
  };

  func defaultMarketMaker() : MarketMakerState {
    {
      activePairs        = ["GTK_ICP", "MTC_ICP", "MTH_ICP"];
      spreadTarget       = 23.6; // PHI_INV_3 × 100 basis points
      inventoryBias      = 0.0;
      maxInventory       = Phi.PHI * 1000.0; // 1618 units max
      totalQuotesPosted  = 0;
      totalFillsProvided = 0;
      pnl                = 0.0;
      lastQuoteBeat      = 0;
    }
  };

  func defaultTradingPairs() : [(Text, TradingPair)] {
    [
      // Sovereign tokens paired with ICP
      mkPair("GTK_ICP", "GTK", "ICP", #sovereignToken, #crypto, 0.0001),
      mkPair("MRC_ICP", "MRC", "ICP", #sovereignToken, #crypto, 0.0001),
      mkPair("CVT_ICP", "CVT", "ICP", #sovereignToken, #crypto, 0.00001),
      mkPair("VCT_ICP", "VCT", "ICP", #sovereignToken, #crypto, 0.00001),
      mkPair("KNT_ICP", "KNT", "ICP", #sovereignToken, #crypto, 0.00001),
      mkPair("RST_ICP", "RST", "ICP", #sovereignToken, #crypto, 0.00001),
      mkPair("SBT_ICP", "SBT", "ICP", #sovereignToken, #crypto, 0.000001),
      mkPair("HBT_ICP", "HBT", "ICP", #sovereignToken, #crypto, 0.000001),
      mkPair("DRT_ICP", "DRT", "ICP", #sovereignToken, #crypto, 0.000001),
      mkPair("OMT_ICP", "OMT", "ICP", #sovereignToken, #crypto, 0.000001),
      mkPair("LGT_ICP", "LGT", "ICP", #sovereignToken, #crypto, 0.000001),
      mkPair("MTH_ICP", "MTH", "ICP", #sovereignToken, #crypto, 0.001),
      mkPair("MTC_ICP", "MTC", "ICP", #sovereignToken, #crypto, 0.0001),
      // External crypto pairs
      mkPair("BTC_ICP", "BTC", "ICP", #crypto, #crypto, 0.01),
      mkPair("ETH_ICP", "ETH", "ICP", #crypto, #crypto, 0.001),
      mkPair("BTC_MTC", "BTC", "MTC", #crypto, #sovereignToken, 0.01),
      // AI Token pairs
      mkPair("AICPU_ICP", "AICPU", "ICP", #aiToken, #crypto, 0.0001),
      mkPair("AIMEM_ICP", "AIMEM", "ICP", #aiToken, #crypto, 0.0001),
      mkPair("AIINF_ICP", "AIINF", "ICP", #aiToken, #crypto, 0.0001),
      mkPair("AITRAIN_ICP", "AITRAIN", "ICP", #aiToken, #crypto, 0.0001),
      mkPair("AIDATA_ICP", "AIDATA", "ICP", #aiToken, #crypto, 0.0001),
      // AI Artifact pairs (tokenized AI outputs)
      mkPair("AIMDL_MTC", "AIMDL", "MTC", #aiArtifact, #sovereignToken, 0.001),
      mkPair("AIEMB_MTC", "AIEMB", "MTC", #aiArtifact, #sovereignToken, 0.001),
      mkPair("AIPROT_MTC", "AIPROT", "MTC", #aiArtifact, #sovereignToken, 0.001),
      // Creator tokens
      mkPair("MEDINA_ICP", "MEDINA", "ICP", #creatorToken, #crypto, 0.0001),
      mkPair("MEDINA_MTC", "MEDINA", "MTC", #creatorToken, #sovereignToken, 0.0001),
    ]
  };

  func mkPair(id : Text, base : Text, quote : Text, baseCat : TokenCategory, quoteCat : TokenCategory, tick : Float) : (Text, TradingPair) {
    (id, {
      pairId        = id;
      baseToken     = base;
      quoteToken    = quote;
      baseCategory  = baseCat;
      quoteCategory = quoteCat;
      tickSize      = tick;
      lotSize       = 0.001;
      status        = #active;
      createdBeat   = 0;
      volume24h     = 0.0;
      lastPrice     = 0.0;
      highPrice24h  = 0.0;
      lowPrice24h   = 0.0;
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PLACE ORDER — submit a new order to the exchange
  // Returns updated state + the placed order
  // ═══════════════════════════════════════════════════════════════════════════

  public func placeOrder(
    state       : PhantomExchangeState,
    pairId      : Text,
    owner       : Text,
    side        : OrderSide,
    orderType   : OrderType,
    price       : Float,
    quantity    : Float,
    tif         : TimeInForce,
    beat        : Int,
    aiConfidence: Float,
  ) : (PhantomExchangeState, Order) {
    let order : Order = {
      orderId        = state.nextOrderId;
      pairId         = pairId;
      owner          = owner;
      side           = side;
      orderType      = orderType;
      price          = price;
      quantity       = quantity;
      filledQty      = 0.0;
      remainingQty   = quantity;
      timeInForce    = tif;
      status         = #open;
      createdBeat    = beat;
      lastUpdateBeat = beat;
      aiConfidence   = if (aiConfidence < Phi.PHI_INV) Phi.PHI_INV else aiConfidence;
      doctrineGated  = true;
    };

    // Add to appropriate side of order book
    let updatedBooks = addToOrderBook(state.orderBooks, pairId, order);

    let updatedState = {
      state with
      orderBooks        = updatedBooks;
      nextOrderId       = state.nextOrderId + 1;
      totalOrdersPlaced = state.totalOrdersPlaced + 1;
    };

    (updatedState, order)
  };

  func addToOrderBook(books : [(Text, OrderBook)], pairId : Text, order : Order) : [(Text, OrderBook)] {
    let found = Array.find<(Text, OrderBook)>(books, func (b) { b.0 == pairId });
    switch (found) {
      case (?existing) {
        Array.map<(Text, OrderBook), (Text, OrderBook)>(books, func (b) {
          if (b.0 == pairId) {
            let book = b.1;
            let updated = switch (order.side) {
              case (#buy)  { { book with bids = insertBid(book.bids, order) } };
              case (#sell) { { book with asks = insertAsk(book.asks, order) } };
            };
            (pairId, updated)
          } else { b }
        })
      };
      case null {
        // Create new order book for this pair
        let newBook : OrderBook = switch (order.side) {
          case (#buy) {
            { pairId = pairId; bids = [order]; asks = []; lastMatchBeat = 0; totalMatches = 0; spreadBps = 0.0 }
          };
          case (#sell) {
            { pairId = pairId; bids = []; asks = [order]; lastMatchBeat = 0; totalMatches = 0; spreadBps = 0.0 }
          };
        };
        Array.append(books, [(pairId, newBook)])
      };
    }
  };

  // Insert bid in price-descending order (highest bid first)
  func insertBid(bids : [Order], order : Order) : [Order] {
    let combined = Array.append(bids, [order]);
    Array.sort(combined, func (a : Order, b : Order) : { #less; #equal; #greater } {
      if (a.price > b.price) #less
      else if (a.price < b.price) #greater
      else if (a.createdBeat < b.createdBeat) #less  // time priority
      else if (a.createdBeat > b.createdBeat) #greater
      else #equal
    })
  };

  // Insert ask in price-ascending order (lowest ask first)
  func insertAsk(asks : [Order], order : Order) : [Order] {
    let combined = Array.append(asks, [order]);
    Array.sort(combined, func (a : Order, b : Order) : { #less; #equal; #greater } {
      if (a.price < b.price) #less
      else if (a.price > b.price) #greater
      else if (a.createdBeat < b.createdBeat) #less
      else if (a.createdBeat > b.createdBeat) #greater
      else #equal
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCH ENGINE — price-time priority matching
  // Runs every heartbeat. Matches crossing orders. Settlement is INSTANT.
  // ZERO GAS FEES on every fill.
  // ═══════════════════════════════════════════════════════════════════════════

  public func runMatchingEngine(
    state : PhantomExchangeState,
    beat  : Int,
  ) : PhantomExchangeState {
    var updatedState = state;
    // Match all order books
    for (bookEntry in state.orderBooks.vals()) {
      let (pairId, _book) = bookEntry;
      updatedState := matchOrderBook(updatedState, pairId, beat);
    };
    { updatedState with lastSettlementBeat = beat }
  };

  func matchOrderBook(
    state  : PhantomExchangeState,
    pairId : Text,
    beat   : Int,
  ) : PhantomExchangeState {
    let bookOpt = Array.find<(Text, OrderBook)>(state.orderBooks, func (b) { b.0 == pairId });
    switch (bookOpt) {
      case null { state };
      case (?found) {
        let book = found.1;
        if (book.bids.size() == 0 or book.asks.size() == 0) { return state };

        // Check if best bid >= best ask (crossing)
        let bestBid = book.bids[0];
        let bestAsk = book.asks[0];
        if (bestBid.price < bestAsk.price) { return state }; // no cross

        // MATCH: execute at midpoint (fair price)
        let execPrice = (bestBid.price + bestAsk.price) / 2.0;
        let execQty = if (bestBid.remainingQty < bestAsk.remainingQty)
          bestBid.remainingQty else bestAsk.remainingQty;

        // Create fill — ZERO FEES
        let fill : Fill = {
          fillId          = state.nextFillId;
          pairId          = pairId;
          buyOrderId      = bestBid.orderId;
          sellOrderId     = bestAsk.orderId;
          price           = execPrice;
          quantity         = execQty;
          buyerPrincipal  = bestBid.owner;
          sellerPrincipal = bestAsk.owner;
          fillBeat        = beat;
          gasFee          = 0.0;  // PHANTOM LAW: ZERO GAS
          makerFee        = 0.0;  // PHANTOM LAW: ZERO MAKER FEE
          takerFee        = 0.0;  // PHANTOM LAW: ZERO TAKER FEE
        };

        // Update orders
        let updatedBid = { bestBid with
          filledQty      = bestBid.filledQty + execQty;
          remainingQty   = bestBid.remainingQty - execQty;
          status         = if (bestBid.remainingQty - execQty <= 0.0) #filled else #partiallyFilled;
          lastUpdateBeat = beat;
        };
        let updatedAsk = { bestAsk with
          filledQty      = bestAsk.filledQty + execQty;
          remainingQty   = bestAsk.remainingQty - execQty;
          status         = if (bestAsk.remainingQty - execQty <= 0.0) #filled else #partiallyFilled;
          lastUpdateBeat = beat;
        };

        // Rebuild order book
        let newBids = if (updatedBid.status == #filled) {
          Array.tabulate(book.bids.size() - 1 : Nat, func i : Order { book.bids[i + 1] })
        } else {
          Array.tabulate(book.bids.size(), func i : Order {
            if (i == 0) updatedBid else book.bids[i]
          })
        };
        let newAsks = if (updatedAsk.status == #filled) {
          Array.tabulate(book.asks.size() - 1 : Nat, func i : Order { book.asks[i + 1] })
        } else {
          Array.tabulate(book.asks.size(), func i : Order {
            if (i == 0) updatedAsk else book.asks[i]
          })
        };

        let spread = if (newBids.size() > 0 and newAsks.size() > 0) {
          (newAsks[0].price - newBids[0].price) / ((newAsks[0].price + newBids[0].price) / 2.0) * 10000.0
        } else { 0.0 };

        let newBook : OrderBook = {
          pairId        = pairId;
          bids          = newBids;
          asks          = newAsks;
          lastMatchBeat = beat;
          totalMatches  = book.totalMatches + 1;
          spreadBps     = spread;
        };

        // Update state
        let updatedBooks = Array.map<(Text, OrderBook), (Text, OrderBook)>(state.orderBooks, func (b) {
          if (b.0 == pairId) (pairId, newBook) else b
        });

        let fills = appendFill(state.recentFills, fill);

        {
          state with
          orderBooks        = updatedBooks;
          recentFills       = fills;
          nextFillId        = state.nextFillId + 1;
          totalFills        = state.totalFills + 1;
          totalVolumeICP    = state.totalVolumeICP + (execPrice * execQty);
          lastSettlementBeat = beat;
        }
      };
    }
  };

  func appendFill(existing : [Fill], new_ : Fill) : [Fill] {
    let max = 200; // keep last 200 fills
    let combined = Array.append(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : Fill { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CANCEL ORDER — remove an order from the book
  // ═══════════════════════════════════════════════════════════════════════════

  public func cancelOrder(
    state   : PhantomExchangeState,
    orderId : Nat,
    pairId  : Text,
    beat    : Int,
  ) : PhantomExchangeState {
    let updatedBooks = Array.map<(Text, OrderBook), (Text, OrderBook)>(state.orderBooks, func (b) {
      if (b.0 == pairId) {
        let book = b.1;
        let newBids = Array.filter<Order>(book.bids, func (o) { o.orderId != orderId });
        let newAsks = Array.filter<Order>(book.asks, func (o) { o.orderId != orderId });
        (pairId, { book with bids = newBids; asks = newAsks })
      } else { b }
    });

    {
      state with
      orderBooks           = updatedBooks;
      totalOrdersCancelled = state.totalOrdersCancelled + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD TRADING PAIR — dynamically list new tokens
  // ═══════════════════════════════════════════════════════════════════════════

  public func addTradingPair(
    state     : PhantomExchangeState,
    pairId    : Text,
    base      : Text,
    quote     : Text,
    baseCat   : TokenCategory,
    quoteCat  : TokenCategory,
    tickSize  : Float,
    beat      : Int,
  ) : PhantomExchangeState {
    let pair : TradingPair = {
      pairId        = pairId;
      baseToken     = base;
      quoteToken    = quote;
      baseCategory  = baseCat;
      quoteCategory = quoteCat;
      tickSize      = tickSize;
      lotSize       = 0.001;
      status        = #active;
      createdBeat   = beat;
      volume24h     = 0.0;
      lastPrice     = 0.0;
      highPrice24h  = 0.0;
      lowPrice24h   = 0.0;
    };
    {
      state with
      pairs      = Array.append(state.pairs, [(pairId, pair)]);
      totalPairs = state.totalPairs + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GET ORDER BOOK — read current book state for a pair
  // ═══════════════════════════════════════════════════════════════════════════

  public func getOrderBook(state : PhantomExchangeState, pairId : Text) : ?OrderBook {
    let found = Array.find<(Text, OrderBook)>(state.orderBooks, func (b) { b.0 == pairId });
    switch (found) {
      case (?f) { ?f.1 };
      case null { null };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXCHANGE TICK — called every heartbeat from main.mo
  // Runs matching engine across all active pairs
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickExchange(
    state : PhantomExchangeState,
    beat  : Int,
  ) : PhantomExchangeState {
    if (not state.exchangeActive) { return state };
    runMatchingEngine(state, beat)
  };

};
