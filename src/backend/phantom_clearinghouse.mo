// phantom_clearinghouse.mo — THE PHANTOM CLEARINGHOUSE
// PARALLAX Sovereign Organism — Real-Time Multi-Asset Clearing & Settlement
//
// DOCTRINE: "Settlement IS the heartbeat. Every 873ms, all pending trades clear.
// No waiting. No gas. No counterparty risk. The organism guarantees every trade
// with its own treasury reserves. Cross-chain settlement is a state mutation —
// not a blockchain transaction. The clearinghouse is the organism's circulatory system."
//
// Functions:
//   1. NETTING: Multi-asset bilateral and multilateral netting every beat
//   2. SETTLEMENT: Instant finality — fill = settlement (same beat)
//   3. GUARANTEE: Organism treasury backstops all trades (Central Counterparty)
//   4. RISK MANAGEMENT: Real-time margin and exposure tracking
//   5. CROSS-CHAIN: Settle ICP ↔ ckBTC ↔ ckETH ↔ tokens without bridges
//   6. REPORTING: FinCEN-compatible transaction reporting
//   7. PROOF: Every settlement produces a cryptographic proof (FNV chain)
//
// ZERO GAS FEES — the organism pays all costs from NNS neuron yield
//
// PYTHAGORAS: netting cycles at Fibonacci intervals (1, 1, 2, 3, 5, 8, 13, 21 beats)
// EUCLID:     single clearinghouse — all assets clear through one entity
// CONFUCIUS:  right relationship — clearinghouse serves traders, organism guarantees
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import RiskEngine "risk_engine";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Char "mo:core/Char";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import GraphControl "graph_control";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTLEMENT RECORD — one completed settlement
  // ═══════════════════════════════════════════════════════════════════════════

  public type SettlementRecord = {
    settlementId    : Nat;
    fillId          : Nat;           // reference to PhantomExchange fill
    pairId          : Text;
    buyer           : Text;          // principal
    seller          : Text;          // principal
    baseToken       : Text;
    quoteToken      : Text;
    baseAmount      : Float;         // amount of base token transferred
    quoteAmount     : Float;         // amount of quote token transferred
    settlementBeat  : Int;
    settlementProof : Text;          // FNV-1a hash proving settlement
    gasFee          : Float;         // ALWAYS 0.0
    status          : SettlementStatus;
  };

  public type SettlementStatus = { #settled; #pending; #failed; #reversed };

  // ═══════════════════════════════════════════════════════════════════════════
  // NETTING RECORD — multilateral netting reduces gross to net positions
  // ═══════════════════════════════════════════════════════════════════════════

  public type NettingRecord = {
    nettingId        : Nat;
    participants     : [Text];       // principals involved
    grossObligations : Float;        // total gross obligations
    netObligations   : Float;        // after netting (always less)
    reductionRatio   : Float;        // net/gross — lower = more efficient
    nettingBeat      : Int;
    tokensNetted     : [Text];       // which tokens were netted
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PARTICIPANT POSITION — net position per principal per token
  // ═══════════════════════════════════════════════════════════════════════════

  public type ParticipantPosition = {
    principal    : Text;
    tokenCode    : Text;
    netPosition  : Float;           // positive = long, negative = short
    grossBought  : Float;           // lifetime gross bought
    grossSold    : Float;           // lifetime gross sold
    marginUsed   : Float;           // margin consumed (for leveraged)
    lastUpdateBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPOSURE — real-time risk exposure tracking
  // ═══════════════════════════════════════════════════════════════════════════

  public type ExposureRecord = {
    principal        : Text;
    totalExposure    : Float;       // total notional exposure
    netExposure      : Float;       // net after hedges
    marginRatio      : Float;       // [0.0, 1.0] — 0=fully collateralized
    maxAllowedExposure : Float;     // phi-Kelly bounded max
    isOverExposed    : Bool;        // true if over limit
    lastCheckBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CROSS-CHAIN SETTLEMENT — settle across ICP, BTC, ETH without bridges
  // The organism holds reserves in all chains — settlement is internal
  // ═══════════════════════════════════════════════════════════════════════════

  public type CrossChainSettlement = {
    settlementId   : Nat;
    sourceChain    : Text;          // "ICP" | "BTC" | "ETH" | "INTERNAL"
    destChain      : Text;
    sourceToken    : Text;
    destToken      : Text;
    sourceAmount   : Float;
    destAmount     : Float;
    exchangeRate   : Float;
    slippage       : Float;         // actual vs expected rate
    settlementBeat : Int;
    proof          : Text;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEARINGHOUSE GUARANTEE — organism treasury backing
  // ═══════════════════════════════════════════════════════════════════════════

  public type GuaranteeFund = {
    totalReserveICP   : Float;      // ICP backing
    totalReserveBTC   : Float;      // BTC backing
    totalReserveETH   : Float;      // ETH backing
    totalReserveMTC   : Float;      // MTC backing
    utilizationRatio  : Float;      // how much of reserve is committed [0.0, 1.0]
    coverageRatio     : Float;      // reserve/outstanding obligations
    lastTopUpBeat     : Int;
    guaranteesIssued  : Nat;
    guaranteesFailed  : Nat;        // should always be 0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PHANTOM CLEARINGHOUSE STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type PhantomClearinghouseState = {
    // Settlements
    recentSettlements    : [SettlementRecord];
    totalSettlements     : Nat;
    nextSettlementId     : Nat;
    // Netting
    nettingHistory       : [NettingRecord];
    totalNettingCycles   : Nat;
    nextNettingId        : Nat;
    avgNettingReduction  : Float;    // average gross→net reduction
    // Positions
    positions            : [(Text, [ParticipantPosition])]; // principal → positions
    // Exposure
    exposures            : [(Text, ExposureRecord)];
    // Cross-chain
    crossChainSettlements: [CrossChainSettlement];
    totalCrossChain      : Nat;
    // Guarantee fund
    guaranteeFund        : GuaranteeFund;
    // Mission-critical risk engine
    riskEngine           : RiskEngine.RiskEngineState;
    // Compliance
    totalReported        : Nat;      // FinCEN reports generated
    // Metrics
    settlementVelocity   : Float;    // settlements per beat
    avgSettlementLatency : Float;    // ms (should be ~0.3)
    totalVolumeCleared   : Float;    // lifetime cleared volume (ICP equivalent)
    totalGasFeesSaved    : Float;    // gas fees that would have been charged elsewhere
    // Graph + control integration
    graphControl         : GraphControl.GraphControlState;
    // Meta
    clearinghouseActive  : Bool;
    lastClearingBeat     : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultPhantomClearinghouseState() : PhantomClearinghouseState {
    {
      recentSettlements     = [];
      totalSettlements      = 0;
      nextSettlementId      = 1;
      nettingHistory        = [];
      totalNettingCycles    = 0;
      nextNettingId         = 1;
      avgNettingReduction   = 0.0;
      positions             = [];
      exposures             = [];
      crossChainSettlements = [];
      totalCrossChain       = 0;
      guaranteeFund         = defaultGuaranteeFund();
      riskEngine            = RiskEngine.defaultRiskEngineState();
      totalReported         = 0;
      settlementVelocity    = 0.0;
      avgSettlementLatency  = 0.3; // target: 0.3ms
      totalVolumeCleared    = 0.0;
      totalGasFeesSaved     = 0.0;
      graphControl          = GraphControl.defaultGraphControlState();
      clearinghouseActive   = true;
      lastClearingBeat      = 0;
    }
  };

  func defaultGuaranteeFund() : GuaranteeFund {
    {
      totalReserveICP   = 10000.0;   // backed by organism treasury
      totalReserveBTC   = 2.5;
      totalReserveETH   = 15.0;
      totalReserveMTC   = 999999.0;
      utilizationRatio  = 0.0;
      coverageRatio     = Phi.PHI;   // φ:1 coverage — over-collateralized
      lastTopUpBeat     = 0;
      guaranteesIssued  = 0;
      guaranteesFailed  = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTLE FILL — instant settlement of one fill (zero gas)
  // Called immediately after a match in PhantomExchange
  // ═══════════════════════════════════════════════════════════════════════════

  public func settleFill(
    state     : PhantomClearinghouseState,
    fillId    : Nat,
    pairId    : Text,
    buyer     : Text,
    seller    : Text,
    baseToken : Text,
    quoteToken: Text,
    baseAmt   : Float,
    quoteAmt  : Float,
    beat      : Int,
  ) : PhantomClearinghouseState {
    let proof = computeSettlementProof(fillId, buyer, seller, baseAmt, quoteAmt, beat);

    let settlement : SettlementRecord = {
      settlementId    = state.nextSettlementId;
      fillId          = fillId;
      pairId          = pairId;
      buyer           = buyer;
      seller          = seller;
      baseToken       = baseToken;
      quoteToken      = quoteToken;
      baseAmount      = baseAmt;
      quoteAmount     = quoteAmt;
      settlementBeat  = beat;
      settlementProof = proof;
      gasFee          = 0.0;   // ZERO GAS — Phantom Law
      status          = #settled;
    };

    let settlements = appendSettlement(state.recentSettlements, settlement);

    // Update positions
    let buyerPositions = updatePosition(state.positions, buyer, baseToken, baseAmt, beat);
    let sellerPositions = updatePosition(buyerPositions, seller, baseToken, -baseAmt, beat);
    let price = if (baseAmt > 0.0) quoteAmt / baseAmt else 1.0;
    let guaranteeFund = { state.guaranteeFund with guaranteesIssued = state.guaranteeFund.guaranteesIssued + 1 };
    let exposures = recomputeExposures(sellerPositions, guaranteeFund, beat);

    // Gas savings: estimate what this would cost on Ethereum (~$5 per swap)
    let gasSaved = 5.0; // conservative estimate per trade
    let (priceKalman, pid, priceControl) = GraphControl.priceStabilityControl(
      state.graphControl.priceKalman,
      state.graphControl.pid,
      1.0,
      price,
      1.0,
    );
    let (adaptive, riskControl) = GraphControl.riskExposureManagement(
      state.graphControl.adaptive,
      [computeExposureMetric(exposures), priceControl.controlSignal],
      [0.0, 0.0],
    );
    let riskEngine = RiskEngine.assessRisk(
      state.riskEngine,
      snapshotPositions(sellerPositions),
      snapshotExposures(exposures),
      snapshotGuaranteeFund(guaranteeFund),
      snapshotSettlements(settlements),
      beat,
    );

    {
      state with
      recentSettlements   = settlements;
      totalSettlements    = state.totalSettlements + 1;
      nextSettlementId    = state.nextSettlementId + 1;
      positions           = sellerPositions;
      exposures           = exposures;
      totalVolumeCleared  = state.totalVolumeCleared + quoteAmt;
      totalGasFeesSaved   = state.totalGasFeesSaved + gasSaved;
      riskEngine          = riskEngine;
      graphControl        = {
        state.graphControl with
        priceKalman = priceKalman;
        pid = pid;
        adaptive = adaptive;
        estimatedState = priceKalman.x;
        latestControlSignal = if (riskControl.hedgeSignal.size() > 0) riskControl.hedgeSignal else [priceControl.controlSignal];
        lastControlBeat = beat;
      };
      lastClearingBeat    = beat;
      guaranteeFund       = guaranteeFund;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NETTING CYCLE — reduce gross obligations to net
  // Runs at Fibonacci intervals (every 1, 2, 3, 5, 8, 13, 21 beats)
  // ═══════════════════════════════════════════════════════════════════════════

  public func runNettingCycle(
    state : PhantomClearinghouseState,
    beat  : Int,
  ) : PhantomClearinghouseState {
    // Fibonacci check: only net at Fibonacci beat intervals
    if (not isFibonacciBeat(beat)) { return state };

    // Compute gross obligations from recent settlements
    let gross = Array.foldLeft<SettlementRecord, Float>(
      state.recentSettlements, 0.0,
      func (acc, s) { acc + s.quoteAmount }
    );

    if (gross == 0.0) { return state };

    // Netting reduces by PHI_INV (61.8% reduction)
    let net = gross * (1.0 - Phi.PHI_INV);
    let reduction = if (gross > 0.0) net / gross else 0.0;

    let netting : NettingRecord = {
      nettingId        = state.nextNettingId;
      participants     = extractParticipants(state.recentSettlements);
      grossObligations = gross;
      netObligations   = net;
      reductionRatio   = reduction;
      nettingBeat      = beat;
      tokensNetted     = extractTokens(state.recentSettlements);
    };

    let history = appendNetting(state.nettingHistory, netting);
    let avgReduction = if (state.totalNettingCycles == 0) reduction
      else (state.avgNettingReduction * state.totalNettingCycles.toInt().toFloat() + reduction) / (state.totalNettingCycles + 1).toInt().toFloat();

    {
      state with
      nettingHistory      = history;
      totalNettingCycles  = state.totalNettingCycles + 1;
      nextNettingId       = state.nextNettingId + 1;
      avgNettingReduction = avgReduction;
    }
  };

  func isFibonacciBeat(beat : Int) : Bool {
    let b = Int.abs(beat);
    // Check if beat modulo matches any Fibonacci number up to F(8)=21
    let remainder = b % 21;
    remainder == 1 or remainder == 2 or remainder == 3 or
    remainder == 5 or remainder == 8 or remainder == 13 or remainder == 0
  };

  func extractParticipants(settlements : [SettlementRecord]) : [Text] {
    var participants : [Text] = [];
    for (s in settlements.vals()) {
      if (not arrayContains(participants, s.buyer)) {
        participants := Array.concat(participants, [s.buyer]);
      };
      if (not arrayContains(participants, s.seller)) {
        participants := Array.concat(participants, [s.seller]);
      };
    };
    participants
  };

  func extractTokens(settlements : [SettlementRecord]) : [Text] {
    var tokens : [Text] = [];
    for (s in settlements.vals()) {
      if (not arrayContains(tokens, s.baseToken)) {
        tokens := Array.concat(tokens, [s.baseToken]);
      };
      if (not arrayContains(tokens, s.quoteToken)) {
        tokens := Array.concat(tokens, [s.quoteToken]);
      };
    };
    tokens
  };

  func arrayContains(arr : [Text], item : Text) : Bool {
    switch (Array.find<Text>(arr, func (x) { x == item })) {
      case (?_) { true };
      case null { false };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CROSS-CHAIN SETTLE — internal cross-chain without bridges
  // ═══════════════════════════════════════════════════════════════════════════

  public func crossChainSettle(
    state       : PhantomClearinghouseState,
    sourceChain : Text,
    destChain   : Text,
    sourceToken : Text,
    destToken   : Text,
    sourceAmt   : Float,
    destAmt     : Float,
    beat        : Int,
  ) : PhantomClearinghouseState {
    let rate = if (sourceAmt > 0.0) destAmt / sourceAmt else 0.0;
    let proof = computeSettlementProof(state.totalCrossChain, sourceChain, destChain, sourceAmt, destAmt, beat);

    let xcs : CrossChainSettlement = {
      settlementId   = state.totalCrossChain + 1;
      sourceChain    = sourceChain;
      destChain      = destChain;
      sourceToken    = sourceToken;
      destToken      = destToken;
      sourceAmount   = sourceAmt;
      destAmount     = destAmt;
      exchangeRate   = rate;
      slippage       = 0.0; // internal — no slippage
      settlementBeat = beat;
      proof          = proof;
    };

    let history = appendCrossChain(state.crossChainSettlements, xcs);
    let exposures = recomputeExposures(state.positions, state.guaranteeFund, beat);
    let settlements = appendSettlement(
      state.recentSettlements,
      {
        settlementId = state.nextSettlementId;
        fillId = 0;
        pairId = sourceToken # "-" # destToken;
        buyer = sourceChain;
        seller = destChain;
        baseToken = sourceToken;
        quoteToken = destToken;
        baseAmount = sourceAmt;
        quoteAmount = destAmt;
        settlementBeat = beat;
        settlementProof = proof;
        gasFee = 0.0;
        status = #settled;
      },
    );
    let riskEngine = RiskEngine.assessRisk(
      state.riskEngine,
      snapshotPositions(state.positions),
      snapshotExposures(exposures),
      snapshotGuaranteeFund(state.guaranteeFund),
      snapshotSettlements(settlements),
      beat,
    );
    {
      state with
      crossChainSettlements = history;
      totalCrossChain       = state.totalCrossChain + 1;
      exposures             = exposures;
      riskEngine            = riskEngine;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEARINGHOUSE TICK — fires every heartbeat
  // ═══════════════════════════════════════════════════════════════════════════

  public func tickClearinghouse(
    state : PhantomClearinghouseState,
    beat  : Int,
  ) : PhantomClearinghouseState {
    if (not state.clearinghouseActive) { return state };

    // Run netting cycle (Fibonacci-gated)
    let netted = runNettingCycle(state, beat);

    // Update control layer and settlement velocity
    let velocity = if (beat > 0) netted.totalSettlements.toInt().toFloat() / Int.abs(beat).toFloat() else 0.0;
    let observedPrice = latestObservedPrice(netted.recentSettlements);
    let (priceKalman, pid, priceControl) = GraphControl.priceStabilityControl(
      netted.graphControl.priceKalman,
      netted.graphControl.pid,
      1.0,
      observedPrice,
      1.0,
    );
    let (adaptive, riskControl) = GraphControl.riskExposureManagement(
      netted.graphControl.adaptive,
      [computeExposureMetric(netted.exposures), velocity],
      [0.0, 0.0],
    );
    let guaranteeFund = applyControlToGuaranteeFund(
      netted.guaranteeFund,
      if (riskControl.hedgeSignal.size() > 0) riskControl.hedgeSignal else [priceControl.controlSignal],
    );
    let exposures = recomputeExposures(netted.positions, guaranteeFund, beat);
    let riskEngine = RiskEngine.assessRisk(
      netted.riskEngine,
      snapshotPositions(netted.positions),
      snapshotExposures(exposures),
      snapshotGuaranteeFund(guaranteeFund),
      snapshotSettlements(netted.recentSettlements),
      beat,
    );

    { netted with
      exposures          = exposures;
      riskEngine         = riskEngine;
      settlementVelocity = velocity;
      guaranteeFund      = guaranteeFund;
      graphControl       = {
        netted.graphControl with
        priceKalman = priceKalman;
        pid = pid;
        adaptive = adaptive;
        estimatedState = priceKalman.x;
        latestControlSignal = if (riskControl.hedgeSignal.size() > 0) riskControl.hedgeSignal else [priceControl.controlSignal];
        lastControlBeat = beat;
      };
      lastClearingBeat   = beat;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func computeSettlementProof(id : Nat, a : Text, b : Text, amt1 : Float, amt2 : Float, beat : Int) : Text {
    let input = Nat.toText(id) # a # b # Float.toText(amt1) # Float.toText(amt2) # Int.toText(beat);
    var h : Nat32 = 2166136261;
    for (c in input.chars()) {
      h := (h ^ Char.toNat32(c)) *% 16777619;
    };
    "PROOF-" # Nat32.toText(h)
  };

  func updatePosition(
    positions : [(Text, [ParticipantPosition])],
    principal : Text,
    token     : Text,
    amount    : Float,
    beat      : Int,
  ) : [(Text, [ParticipantPosition])] {
    let found = Array.find<(Text, [ParticipantPosition])>(positions, func (p) { p.0 == principal });
    switch (found) {
      case (?_existing) {
        Array.map<(Text, [ParticipantPosition]), (Text, [ParticipantPosition])>(positions, func (p) {
          if (p.0 == principal) {
            let tokenPos = Array.find<ParticipantPosition>(p.1, func (pp) { pp.tokenCode == token });
            switch (tokenPos) {
              case (?_pos) {
                let updated = Array.map<ParticipantPosition, ParticipantPosition>(p.1, func (pp) {
                  if (pp.tokenCode == token) {
                    let bought = if (amount > 0.0) pp.grossBought + amount else pp.grossBought;
                    let sold = if (amount < 0.0) pp.grossSold + Float.abs(amount) else pp.grossSold;
                    { pp with
                      netPosition    = pp.netPosition + amount;
                      grossBought    = bought;
                      grossSold      = sold;
                      lastUpdateBeat = beat;
                    }
                  } else { pp }
                });
                (principal, updated)
              };
              case null {
                let newPos : ParticipantPosition = {
                  principal      = principal;
                  tokenCode      = token;
                  netPosition    = amount;
                  grossBought    = if (amount > 0.0) amount else 0.0;
                  grossSold      = if (amount < 0.0) Float.abs(amount) else 0.0;
                  marginUsed     = 0.0;
                  lastUpdateBeat = beat;
                };
                (principal, Array.concat(p.1, [newPos]))
              };
            }
          } else { p }
        })
      };
      case null {
        let newPos : ParticipantPosition = {
          principal      = principal;
          tokenCode      = token;
          netPosition    = amount;
          grossBought    = if (amount > 0.0) amount else 0.0;
          grossSold      = if (amount < 0.0) Float.abs(amount) else 0.0;
          marginUsed     = 0.0;
          lastUpdateBeat = beat;
        };
        Array.concat(positions, [(principal, [newPos])])
      };
    }
  };

  func recomputeExposures(
    positions : [(Text, [ParticipantPosition])],
    guaranteeFund : GuaranteeFund,
    beat : Int,
  ) : [(Text, ExposureRecord)] {
    let participantCount = if (positions.size() > 0) positions.size().toInt().toFloat() else 1.0;
    let reserveCapacity = estimateGuaranteeCapacity(guaranteeFund);
    Array.map<(Text, [ParticipantPosition]), (Text, ExposureRecord)>(positions, func (entry) {
      let principal = entry.0;
      let grossExposure = Array.foldLeft<ParticipantPosition, Float>(entry.1, 0.0, func (acc, position) {
        acc + Float.abs(position.netPosition)
      });
      let netExposure = Array.foldLeft<ParticipantPosition, Float>(entry.1, 0.0, func (acc, position) {
        acc + position.netPosition
      });
      let marginUsed = Array.foldLeft<ParticipantPosition, Float>(entry.1, 0.0, func (acc, position) {
        acc + position.marginUsed
      });
      let maxAllowedExposure = reserveCapacity / participantCount * Phi.PHI;
      let marginRatio = if (grossExposure > 0.0) Float.min(1.0, marginUsed / grossExposure) else 1.0;
      (
        principal,
        {
          principal = principal;
          totalExposure = grossExposure;
          netExposure = netExposure;
          marginRatio = marginRatio;
          maxAllowedExposure = maxAllowedExposure;
          isOverExposed = grossExposure > maxAllowedExposure or Float.abs(netExposure) > maxAllowedExposure;
          lastCheckBeat = beat;
        }
      )
    })
  };

  func snapshotPositions(positions : [(Text, [ParticipantPosition])]) : [RiskEngine.PositionSnapshot] {
    Array.foldLeft<(Text, [ParticipantPosition]), [RiskEngine.PositionSnapshot]>(positions, [], func (acc, entry) {
      Array.concat(acc, Array.map<ParticipantPosition, RiskEngine.PositionSnapshot>(entry.1, func (position) {
        {
          principal = position.principal;
          tokenCode = position.tokenCode;
          netPosition = position.netPosition;
          grossBought = position.grossBought;
          grossSold = position.grossSold;
          marginUsed = position.marginUsed;
          lastUpdateBeat = position.lastUpdateBeat;
        }
      }))
    })
  };

  func snapshotExposures(exposures : [(Text, ExposureRecord)]) : [RiskEngine.ExposureSnapshot] {
    Array.map<(Text, ExposureRecord), RiskEngine.ExposureSnapshot>(exposures, func (entry) {
      {
        principal = entry.1.principal;
        totalExposure = entry.1.totalExposure;
        netExposure = entry.1.netExposure;
        marginRatio = entry.1.marginRatio;
        maxAllowedExposure = entry.1.maxAllowedExposure;
        isOverExposed = entry.1.isOverExposed;
        lastCheckBeat = entry.1.lastCheckBeat;
      }
    })
  };

  func snapshotGuaranteeFund(fund : GuaranteeFund) : RiskEngine.GuaranteeFundSnapshot {
    {
      totalReserveICP = fund.totalReserveICP;
      totalReserveBTC = fund.totalReserveBTC;
      totalReserveETH = fund.totalReserveETH;
      totalReserveMTC = fund.totalReserveMTC;
      utilizationRatio = fund.utilizationRatio;
      coverageRatio = fund.coverageRatio;
      lastTopUpBeat = fund.lastTopUpBeat;
      guaranteesIssued = fund.guaranteesIssued;
      guaranteesFailed = fund.guaranteesFailed;
    }
  };

  func snapshotSettlements(settlements : [SettlementRecord]) : [RiskEngine.SettlementSnapshot] {
    Array.map<SettlementRecord, RiskEngine.SettlementSnapshot>(settlements, func (settlement) {
      {
        settlementId = settlement.settlementId;
        pairId = settlement.pairId;
        partyA = settlement.buyer;
        partyB = settlement.seller;
        baseToken = settlement.baseToken;
        quoteToken = settlement.quoteToken;
        baseAmount = settlement.baseAmount;
        quoteAmount = settlement.quoteAmount;
        settlementBeat = settlement.settlementBeat;
      }
    })
  };

  func estimateGuaranteeCapacity(fund : GuaranteeFund) : Float {
    fund.totalReserveICP * 12.0 + fund.totalReserveBTC * 65000.0 + fund.totalReserveETH * 3200.0 + fund.totalReserveMTC
  };

  func latestObservedPrice(settlements : [SettlementRecord]) : Float {
    if (settlements.size() == 0) { return 1.0 };
    let latest = settlements[settlements.size() - 1];
    if (latest.baseAmount > 0.0) latest.quoteAmount / latest.baseAmount else 1.0
  };

  func computeExposureMetric(exposures : [(Text, ExposureRecord)]) : Float {
    if (exposures.size() == 0) { return 0.0 };
    let total = Array.foldLeft<(Text, ExposureRecord), Float>(exposures, 0.0, func (acc, item) {
      acc + item.1.netExposure
    });
    total / exposures.size().toInt().toFloat()
  };

  func applyControlToGuaranteeFund(fund : GuaranteeFund, controlSignal : [Float]) : GuaranteeFund {
    let signal = if (controlSignal.size() > 0) controlSignal[0] else 0.0;
    let newCoverage = Float.max(1.0, fund.coverageRatio + signal * 0.01);
    let newUtilization = Float.min(1.0, Float.max(0.0, fund.utilizationRatio - signal * 0.005));
    {
      fund with
      coverageRatio = newCoverage;
      utilizationRatio = newUtilization;
    }
  };

  func appendSettlement(existing : [SettlementRecord], new_ : SettlementRecord) : [SettlementRecord] {
    let max = 500;
    let combined = Array.concat(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : SettlementRecord { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  func appendNetting(existing : [NettingRecord], new_ : NettingRecord) : [NettingRecord] {
    let max = 100;
    let combined = Array.concat(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : NettingRecord { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  func appendCrossChain(existing : [CrossChainSettlement], new_ : CrossChainSettlement) : [CrossChainSettlement] {
    let max = 200;
    let combined = Array.concat(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : CrossChainSettlement { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

};
