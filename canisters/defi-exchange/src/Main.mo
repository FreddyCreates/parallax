import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import Bench "Bench";
import Markets "Markets";
import Receipts "Receipts";
import Types "Types";

actor DeFiExchange {
  stable var pairs : [Types.PairInfo] = Markets.seedPairs();
  stable var orders : [Types.Order] = [];
  stable var fills : [Types.Fill] = [];
  stable var receipts : [Types.ExchangeReceipt] = [];
  stable var benchmarks : [Types.BenchmarkReceipt] = [];
  stable var orderSeq : Nat = 0;
  stable var fillSeq : Nat = 0;

  let version : Types.Version = {
    name = "parallax-defi-exchange";
    version = "0.3.0-alpha.0";
    schema = "parallax.defi_exchange.v1";
    build = "icp-motoko-production-code-no-typescript";
  };

  private func now() : Int { Time.now() };

  private func page<T>(items : [T], cursor : ?Nat, limit : ?Nat) : Types.Page<T> {
    let start = switch (cursor) { case (?c) c; case null 0 };
    let requested = switch (limit) { case (?l) l; case null 50 };
    let capped = if (requested > 100) 100 else requested;
    let total = items.size();
    if (start >= total) return { items = []; nextCursor = null; total = total };
    var selected : [T] = [];
    var i = start;
    while (i < total and selected.size() < capped) {
      selected := Array.append<T>(selected, [items[i]]);
      i += 1;
    };
    { items = selected; nextCursor = if (i < total) ?i else null; total = total }
  };

  private func latestReceiptId() : ?Text {
    if (receipts.size() == 0) null else ?receipts[receipts.size() - 1].receiptId
  };

  private func appendReceipt(receipt : Types.ExchangeReceipt) : Text {
    receipts := Array.append<Types.ExchangeReceipt>(receipts, [receipt]);
    receipt.receiptId
  };

  private func findPair(pairId : Text) : ?Types.PairInfo {
    Array.find<Types.PairInfo>(pairs, func(pair) { pair.pairId == pairId })
  };

  private func isOpen(order : Types.Order) : Bool {
    order.status == #open or order.status == #partially_filled
  };

  private func samePairOpen(order : Types.Order, pairId : Text) : Bool {
    order.pairId == pairId and isOpen(order)
  };

  private func crosses(taker : Types.PlaceOrderArgs, resting : Types.Order) : Bool {
    switch (taker.side, taker.priceE8s, resting.priceE8s) {
      case (#buy, ?buyPrice, ?askPrice) buyPrice >= askPrice;
      case (#sell, ?sellPrice, ?bidPrice) sellPrice <= bidPrice;
      case (#buy, null, ?_) true;
      case (#sell, null, ?_) true;
      case (_, _, _) false;
    }
  };

  private func openOrderCount(owner : Principal, pairId : Text) : Nat {
    var count = 0;
    for (order in orders.vals()) {
      if (order.owner == owner and order.pairId == pairId and isOpen(order)) count += 1;
    };
    count
  };

  private func validateOrder(caller : Principal, pair : Types.PairInfo, args : Types.PlaceOrderArgs) : [Types.OrderError] {
    var errors : [Types.OrderError] = [];
    if (pair.status == #disabled) errors := Array.append<Types.OrderError>(errors, [#market_disabled]);
    if (pair.status == #halted) errors := Array.append<Types.OrderError>(errors, [#market_halted]);
    if (args.quantityE8s == 0) errors := Array.append<Types.OrderError>(errors, [#invalid_quantity]);
    if (args.quantityE8s < pair.minOrderE8s) errors := Array.append<Types.OrderError>(errors, [#min_order_violation]);
    switch (args.orderType, args.priceE8s) {
      case (#market, _) {};
      case (_, null) errors := Array.append<Types.OrderError>(errors, [#invalid_price]);
      case (_, ?price) {
        if (price == 0) errors := Array.append<Types.OrderError>(errors, [#invalid_price]);
        if (price % pair.tickSizeE8s != 0) errors := Array.append<Types.OrderError>(errors, [#tick_size_violation]);
      };
    };
    if (openOrderCount(caller, pair.pairId) >= pair.maxOpenOrdersPerPrincipal) {
      errors := Array.append<Types.OrderError>(errors, [#max_open_orders_exceeded]);
    };
    errors
  };

  private func updateOrder(updated : Types.Order) {
    orders := Array.map<Types.Order, Types.Order>(
      orders,
      func(order) { if (order.orderId == updated.orderId) updated else order }
    );
  };

  private func bestOpposite(pairId : Text, side : Types.Side, args : Types.PlaceOrderArgs) : ?Types.Order {
    var best : ?Types.Order = null;
    for (order in orders.vals()) {
      if (samePairOpen(order, pairId) and order.side != side and crosses(args, order)) {
        switch (best) {
          case null { best := ?order };
          case (?current) {
            switch (side, order.priceE8s, current.priceE8s) {
              case (#buy, ?p, ?cp) { if (p < cp) best := ?order };
              case (#sell, ?p, ?cp) { if (p > cp) best := ?order };
              case (_, _, _) {};
            };
          };
        };
      };
    };
    best
  };

  private func addLevel(levels : [Types.OrderBookLevel], price : Nat, quantity : Nat) : [Types.OrderBookLevel] {
    var found = false;
    let mapped = Array.map<Types.OrderBookLevel, Types.OrderBookLevel>(
      levels,
      func(level) {
        if (level.priceE8s == price) {
          found := true;
          { priceE8s = price; quantityE8s = level.quantityE8s + quantity; orderCount = level.orderCount + 1 }
        } else level
      }
    );
    if (found) mapped else Array.append<Types.OrderBookLevel>(mapped, [{ priceE8s = price; quantityE8s = quantity; orderCount = 1 }])
  };

  public query func getVersion() : async Types.Version { version };

  public query func get_all_pairs() : async [Types.PairInfo] { pairs };

  public query func list_pairs(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.PairInfo> {
    page<Types.PairInfo>(pairs, cursor, limit)
  };

  public query func get_pair(pairId : Text) : async ?Types.PairInfo {
    findPair(pairId)
  };

  public shared ({ caller }) func place_order(args : Types.PlaceOrderArgs) : async Types.OrderResult {
    switch (findPair(args.pairId)) {
      case null #err([#market_not_found]);
      case (?pair) {
        let errors = validateOrder(caller, pair, args);
        if (errors.size() > 0) {
          let receipt = Receipts.makeReceipt(#order_rejected, ?args.pairId, null, null, caller, latestReceiptId(), now());
          ignore appendReceipt(receipt);
          return #err(errors);
        };

        if (args.orderType == #post_only) {
          switch (bestOpposite(args.pairId, args.side, args)) {
            case (?_) {
              let receipt = Receipts.makeReceipt(#order_rejected, ?args.pairId, null, null, caller, latestReceiptId(), now());
              ignore appendReceipt(receipt);
              return #err([#post_only_would_cross]);
            };
            case null {};
          };
        };

        orderSeq += 1;
        let createdAt = now();
        var activeOrder : Types.Order = {
          orderId = orderSeq;
          owner = caller;
          pairId = args.pairId;
          side = args.side;
          orderType = args.orderType;
          priceE8s = args.priceE8s;
          quantityE8s = args.quantityE8s;
          remainingE8s = args.quantityE8s;
          status = #open;
          createdAt = createdAt;
          updatedAt = createdAt;
          clientOrderId = args.clientOrderId;
          memo = args.memo;
        };

        var localFills : [Types.Fill] = [];
        var continueMatching = true;
        while (activeOrder.remainingE8s > 0 and continueMatching) {
          switch (bestOpposite(args.pairId, args.side, args)) {
            case null { continueMatching := false };
            case (?resting) {
              let fillQty = if (activeOrder.remainingE8s < resting.remainingE8s) activeOrder.remainingE8s else resting.remainingE8s;
              let fillPrice = switch (resting.priceE8s, activeOrder.priceE8s) { case (?p, _) p; case (null, ?p) p; case (null, null) 0 };
              fillSeq += 1;
              let fill : Types.Fill = {
                fillId = fillSeq;
                pairId = args.pairId;
                buyOrderId = if (args.side == #buy) activeOrder.orderId else resting.orderId;
                sellOrderId = if (args.side == #sell) activeOrder.orderId else resting.orderId;
                buyer = if (args.side == #buy) caller else resting.owner;
                seller = if (args.side == #sell) caller else resting.owner;
                priceE8s = fillPrice;
                quantityE8s = fillQty;
                takerSide = args.side;
                createdAt = now();
              };
              fills := Array.append<Types.Fill>(fills, [fill]);
              localFills := Array.append<Types.Fill>(localFills, [fill]);
              ignore appendReceipt(Receipts.makeReceipt(#fill_recorded, ?args.pairId, ?activeOrder.orderId, ?fill.fillId, caller, latestReceiptId(), now()));

              activeOrder := { activeOrder with remainingE8s = activeOrder.remainingE8s - fillQty; status = if (activeOrder.remainingE8s == fillQty) #filled else #partially_filled; updatedAt = now() };
              let updatedResting = { resting with remainingE8s = resting.remainingE8s - fillQty; status = if (resting.remainingE8s == fillQty) #filled else #partially_filled; updatedAt = now() };
              updateOrder(updatedResting);
            };
          };
        };

        if (activeOrder.remainingE8s > 0 and args.orderType != #market and args.orderType != #ioc and args.orderType != #fok) {
          orders := Array.append<Types.Order>(orders, [activeOrder]);
        };

        if (args.orderType == #fok and activeOrder.remainingE8s > 0) {
          let receipt = Receipts.makeReceipt(#order_rejected, ?args.pairId, ?activeOrder.orderId, null, caller, latestReceiptId(), now());
          ignore appendReceipt(receipt);
          return #err([#insufficient_balance]);
        };

        let accepted = Receipts.makeReceipt(#order_accepted, ?args.pairId, ?activeOrder.orderId, null, caller, latestReceiptId(), now());
        let receiptId = appendReceipt(accepted);
        #ok({ orderId = activeOrder.orderId; fills = localFills; receiptId = receiptId })
      };
    }
  };

  public shared ({ caller }) func cancel_order(orderId : Nat) : async Types.CancelResult {
    switch (Array.find<Types.Order>(orders, func(order) { order.orderId == orderId })) {
      case null #err([#not_found]);
      case (?order) {
        if (order.owner != caller) return #err([#not_found]);
        if (not isOpen(order)) return #err([#not_found]);
        let updated = { order with status = #cancelled; remainingE8s = 0; updatedAt = now() };
        updateOrder(updated);
        let receiptId = appendReceipt(Receipts.makeReceipt(#order_cancelled, ?order.pairId, ?order.orderId, null, caller, latestReceiptId(), now()));
        #ok({ orderId = order.orderId; cancelledQuantityE8s = order.remainingE8s; receiptId = receiptId })
      };
    }
  };

  public shared ({ caller }) func cancel_all_orders(pairId : ?Text) : async Nat {
    var cancelled = 0;
    for (order in orders.vals()) {
      let pairMatches = switch (pairId) { case (?p) order.pairId == p; case null true };
      if (order.owner == caller and pairMatches and isOpen(order)) {
        let updated = { order with status = #cancelled; remainingE8s = 0; updatedAt = now() };
        updateOrder(updated);
        ignore appendReceipt(Receipts.makeReceipt(#order_cancelled, ?order.pairId, ?order.orderId, null, caller, latestReceiptId(), now()));
        cancelled += 1;
      };
    };
    cancelled
  };

  public query func get_order_book(pairId : Text) : async Types.OrderBook {
    var bids : [Types.OrderBookLevel] = [];
    var asks : [Types.OrderBookLevel] = [];
    for (order in orders.vals()) {
      if (samePairOpen(order, pairId)) {
        switch (order.priceE8s) {
          case (?price) {
            if (order.side == #buy) bids := addLevel(bids, price, order.remainingE8s) else asks := addLevel(asks, price, order.remainingE8s);
          };
          case null {};
        };
      };
    };
    { pairId = pairId; bids = bids; asks = asks; updatedAt = now() }
  };

  public query func get_recent_trades(pairId : Text, limit : Nat) : async [Types.Trade] {
    let filtered = Array.filter<Types.Trade>(fills, func(fill) { fill.pairId == pairId });
    let capped = if (limit > 100) 100 else limit;
    if (filtered.size() <= capped) return filtered;
    var out : [Types.Trade] = [];
    var i = filtered.size() - capped;
    while (i < filtered.size()) {
      out := Array.append<Types.Trade>(out, [filtered[i]]);
      i += 1;
    };
    out
  };

  public query func get_ticker(pairId : Text) : async Types.Ticker {
    let recent = Array.filter<Types.Trade>(fills, func(fill) { fill.pairId == pairId });
    let lastPrice = if (recent.size() == 0) null else ?recent[recent.size() - 1].priceE8s;
    var bestBid : ?Nat = null;
    var bestAsk : ?Nat = null;
    for (order in orders.vals()) {
      if (samePairOpen(order, pairId)) {
        switch (order.side, order.priceE8s) {
          case (#buy, ?price) {
            switch (bestBid) {
              case null { bestBid := ?price };
              case (?p) { if (price > p) bestBid := ?price };
            };
          };
          case (#sell, ?price) {
            switch (bestAsk) {
              case null { bestAsk := ?price };
              case (?p) { if (price < p) bestAsk := ?price };
            };
          };
          case (_, null) {};
        };
      };
    };
    var volume : Nat = 0;
    for (fill in recent.vals()) { volume += fill.quantityE8s };
    { pairId = pairId; lastPriceE8s = lastPrice; bestBidE8s = bestBid; bestAskE8s = bestAsk; volume24hE8s = volume; updatedAt = now() }
  };

  public query func get_open_orders(pairId : ?Text) : async [Types.Order] {
    Array.filter<Types.Order>(orders, func(order) {
      let pairMatches = switch (pairId) { case (?p) order.pairId == p; case null true };
      pairMatches and isOpen(order)
    })
  };

  public query func get_trade_history(pairId : ?Text, limit : Nat) : async [Types.Trade] {
    let filtered = Array.filter<Types.Trade>(fills, func(fill) {
      switch (pairId) { case (?p) fill.pairId == p; case null true }
    });
    let capped = if (limit > 100) 100 else limit;
    if (filtered.size() <= capped) filtered else Array.tabulate<Types.Trade>(capped, func(i) { filtered[filtered.size() - capped + i] })
  };

  public query func list_receipts(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.ExchangeReceipt> {
    page<Types.ExchangeReceipt>(receipts, cursor, limit)
  };

  public shared ({ caller }) func record_benchmark(input : Types.BenchmarkInput) : async Types.BenchmarkReceipt {
    let receipt = Bench.record(input, now());
    benchmarks := Array.append<Types.BenchmarkReceipt>(benchmarks, [receipt]);
    ignore appendReceipt(Receipts.makeReceipt(#benchmark_recorded, null, null, null, caller, latestReceiptId(), now()));
    receipt
  };

  public query func list_benchmarks(cursor : ?Nat, limit : ?Nat) : async Types.Page<Types.BenchmarkReceipt> {
    page<Types.BenchmarkReceipt>(benchmarks, cursor, limit)
  };
}
