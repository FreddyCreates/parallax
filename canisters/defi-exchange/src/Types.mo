module {
  public type Version = {
    name : Text;
    version : Text;
    schema : Text;
    build : Text;
  };

  public type MarketCategory = {
    #sovereign;
    #crypto;
    #ai_tokens;
    #ai_artifacts;
    #creator;
  };

  public type MarketStatus = {
    #enabled;
    #disabled;
    #halted;
  };

  public type Side = {
    #buy;
    #sell;
  };

  public type OrderType = {
    #limit;
    #market;
    #post_only;
    #ioc;
    #fok;
  };

  public type OrderStatus = {
    #open;
    #partially_filled;
    #filled;
    #cancelled;
    #rejected;
  };

  public type PairInfo = {
    pairId : Text;
    display : Text;
    base : Text;
    quote : Text;
    category : MarketCategory;
    status : MarketStatus;
    description : Text;
    tickSizeE8s : Nat;
    minOrderE8s : Nat;
    makerFeeBps : Nat;
    takerFeeBps : Nat;
    maxOpenOrdersPerPrincipal : Nat;
    settlementIntervalMs : Nat;
  };

  public type PlaceOrderArgs = {
    pairId : Text;
    side : Side;
    orderType : OrderType;
    priceE8s : ?Nat;
    quantityE8s : Nat;
    clientOrderId : ?Text;
    memo : ?Text;
  };

  public type Order = {
    orderId : Nat;
    owner : Principal;
    pairId : Text;
    side : Side;
    orderType : OrderType;
    priceE8s : ?Nat;
    quantityE8s : Nat;
    remainingE8s : Nat;
    status : OrderStatus;
    createdAt : Int;
    updatedAt : Int;
    clientOrderId : ?Text;
    memo : ?Text;
  };

  public type Fill = {
    fillId : Nat;
    pairId : Text;
    buyOrderId : Nat;
    sellOrderId : Nat;
    buyer : Principal;
    seller : Principal;
    priceE8s : Nat;
    quantityE8s : Nat;
    takerSide : Side;
    createdAt : Int;
  };

  public type Trade = Fill;

  public type OrderBookLevel = {
    priceE8s : Nat;
    quantityE8s : Nat;
    orderCount : Nat;
  };

  public type OrderBook = {
    pairId : Text;
    bids : [OrderBookLevel];
    asks : [OrderBookLevel];
    updatedAt : Int;
  };

  public type Ticker = {
    pairId : Text;
    lastPriceE8s : ?Nat;
    bestBidE8s : ?Nat;
    bestAskE8s : ?Nat;
    volume24hE8s : Nat;
    updatedAt : Int;
  };

  public type TokenBalance = {
    owner : Principal;
    token : Text;
    availableE8s : Nat;
    lockedE8s : Nat;
    updatedAt : Int;
  };

  public type ExchangeReceiptKind = {
    #order_accepted;
    #order_rejected;
    #order_cancelled;
    #fill_recorded;
    #market_halted;
    #market_resumed;
    #benchmark_recorded;
  };

  public type ExchangeReceipt = {
    receiptId : Text;
    kind : ExchangeReceiptKind;
    pairId : ?Text;
    orderId : ?Nat;
    fillId : ?Nat;
    actor : Principal;
    payloadHash : Text;
    previousReceiptId : ?Text;
    createdAt : Int;
  };

  public type OrderError = {
    #market_not_found;
    #market_disabled;
    #market_halted;
    #invalid_quantity;
    #invalid_price;
    #tick_size_violation;
    #min_order_violation;
    #max_open_orders_exceeded;
    #post_only_would_cross;
    #insufficient_balance;
    #live_money_movement_blocked;
    #live_broker_routing_blocked;
    #custody_private_keys_blocked;
    #not_found;
  };

  public type OrderResult = {
    #ok : { orderId : Nat; fills : [Fill]; receiptId : Text };
    #err : [OrderError];
  };

  public type CancelResult = {
    #ok : { orderId : Nat; cancelledQuantityE8s : Nat; receiptId : Text };
    #err : [OrderError];
  };

  public type BenchmarkInput = {
    name : Text;
    suite : Text;
    iterations : Nat;
    totalLatencyNanos : Nat;
    maxLatencyNanos : Nat;
    minLatencyNanos : Nat;
    notes : Text;
  };

  public type BenchmarkReceipt = {
    benchmarkId : Text;
    name : Text;
    suite : Text;
    iterations : Nat;
    averageLatencyNanos : Nat;
    maxLatencyNanos : Nat;
    minLatencyNanos : Nat;
    recordedAt : Int;
    notes : Text;
  };

  public type Page<T> = {
    items : [T];
    nextCursor : ?Nat;
    total : Nat;
  };
}
