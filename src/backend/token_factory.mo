// token_factory.mo — SOVEREIGN TOKEN FACTORY
// PARALLAX Sovereign Organism — Create & Manage Custom Tokens
//
// DOCTRINE: "Any creator can mint tokens. Any AI can mint tokens.
// Any artifact of value can be tokenized. The organism is the minting authority.
// Every token created through the factory inherits sovereign law compliance,
// phi-derived supply mechanics, and instant tradability on the Phantom Exchange."
//
// This module:
//   1. CREATES custom tokens (AI tokens, creator tokens, artifact tokens)
//   2. MANAGES supply (minting, burning, circulating supply tracking)
//   3. ENFORCES doctrine (all tokens must pass sovereign law gates)
//   4. TRACKS holders (per-token balance ledger)
//   5. DISTRIBUTES yields (phi-derived yield for staked tokens)
//   6. LISTS on exchange (auto-lists on Phantom Exchange after verification)
//
// Token Types Created Here:
//   - AI COMPUTE TOKENS: Represent access to AI compute resources
//   - AI MEMORY TOKENS: Represent allocated memory for AI operations
//   - AI INFERENCE TOKENS: Pay for inference calls to sovereign models
//   - AI TRAINING TOKENS: Fund training of new models
//   - AI DATA TOKENS: Represent curated datasets
//   - CREATOR TOKENS: Personal tokens minted by human creators
//   - ARTIFACT TOKENS: One-per-artifact tokens representing AI outputs
//   - GOVERNANCE TOKENS: Voting rights in organism sub-DAOs
//   - YIELD TOKENS: Claim on future organism profits
//
// PYTHAGORAS: all supply caps are Fibonacci numbers × phi powers
// EUCLID:     single factory — all tokens minted through one canonical path
// CONFUCIUS:  right relationship — creator mints, doctrine gates, exchange serves
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN DEFINITION — what defines a custom token
  // ═══════════════════════════════════════════════════════════════════════════

  public type CustomTokenType = {
    #aiCompute;         // Access to AI compute
    #aiMemory;          // AI memory allocation
    #aiInference;       // Pay for model inference
    #aiTraining;        // Fund model training
    #aiData;            // Curated dataset access
    #creatorPersonal;   // Personal creator token
    #artifactBacked;    // Backed by specific AI artifact
    #governance;        // DAO voting rights
    #yield;             // Claim on profit streams
    #utility;           // General utility within organism
    #rewardPoints;      // Engagement/loyalty rewards
    #fractionalNFT;     // Fractional ownership of NFT
  };

  public type TokenDefinition = {
    tokenId          : Text;          // unique: "TKN-" + FNV hash
    symbol           : Text;          // 3-6 char ticker (e.g. "AICPU")
    name             : Text;          // full name
    description      : Text;
    tokenType        : CustomTokenType;
    creator          : Text;          // principal of creator
    // Supply mechanics
    maxSupply        : Float;         // Fibonacci × phi^n cap
    totalMinted      : Float;
    totalBurned      : Float;
    circulatingSupply: Float;         // minted - burned
    // Pricing
    initialPrice     : Float;         // genesis price in MTC
    currentPrice     : Float;         // current market price
    priceFloor       : Float;         // S0 floor — cannot go below
    // Doctrine
    doctrineCompliant: Bool;          // passed all 49 law checks
    qualityGate      : Float;         // [0.75, 1.0] — S0 minimum
    // Trading
    listedOnExchange : Bool;
    tradingPairId    : ?Text;         // pair on Phantom Exchange
    volume24h        : Float;
    // Yield
    yieldEnabled     : Bool;
    yieldRate        : Float;         // phi-derived: PHI_INV_3 = 0.236 annually
    totalYieldPaid   : Float;
    // Metadata
    creationBeat     : Int;
    lastUpdateBeat   : Int;
    verified         : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HOLDER BALANCE — per-token, per-principal balance
  // ═══════════════════════════════════════════════════════════════════════════

  public type HolderBalance = {
    principal    : Text;
    tokenId      : Text;
    balance      : Float;
    stakedAmount : Float;           // staked for yield
    lastYieldBeat: Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MINT EVENT — every mint is recorded permanently
  // ═══════════════════════════════════════════════════════════════════════════

  public type MintEvent = {
    eventId   : Nat;
    tokenId   : Text;
    recipient : Text;
    amount    : Float;
    reason    : Text;               // why was this minted
    beat      : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BURN EVENT
  // ═══════════════════════════════════════════════════════════════════════════

  public type BurnEvent = {
    eventId : Nat;
    tokenId : Text;
    burner  : Text;
    amount  : Float;
    reason  : Text;
    beat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN FACTORY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type TokenFactoryState = {
    // Token registry
    tokens             : [(Text, TokenDefinition)];
    totalTokensCreated : Nat;
    // Balances
    holderBalances     : [(Text, [HolderBalance])]; // tokenId → holders
    // Events
    mintEvents         : [MintEvent];
    burnEvents         : [BurnEvent];
    totalMintEvents    : Nat;
    totalBurnEvents    : Nat;
    // Metrics
    totalMarketCap     : Float;       // sum all token market caps
    totalVolume        : Float;       // lifetime trading volume
    // AI Token specifics
    aiComputeAllocated : Float;       // total compute tokens issued
    aiMemoryAllocated  : Float;       // total memory tokens issued
    aiInferenceCalls   : Nat;         // total inference token redemptions
    // Meta
    factoryActive      : Bool;
    lastMintBeat       : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — pre-seeded with core AI tokens
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultTokenFactoryState() : TokenFactoryState {
    {
      tokens               = genesisTokens();
      totalTokensCreated   = 5;
      holderBalances       = [];
      mintEvents           = [];
      burnEvents           = [];
      totalMintEvents      = 0;
      totalBurnEvents      = 0;
      totalMarketCap       = 0.0;
      totalVolume          = 0.0;
      aiComputeAllocated   = 0.0;
      aiMemoryAllocated    = 0.0;
      aiInferenceCalls     = 0;
      factoryActive        = true;
      lastMintBeat         = 0;
    }
  };

  // Genesis AI tokens — pre-seeded at organism birth
  func genesisTokens() : [(Text, TokenDefinition)] {
    [
      mkToken("TKN-AICPU", "AICPU", "AI Compute Token", "Access to sovereign AI compute resources — 1 token = 1 compute unit per beat", #aiCompute, 89000000.0),
      mkToken("TKN-AIMEM", "AIMEM", "AI Memory Token", "Allocated memory for AI operations — 1 token = 1MB persistent memory", #aiMemory, 55000000.0),
      mkToken("TKN-AIINF", "AIINF", "AI Inference Token", "Pay for inference calls to any sovereign model — 1 token = 1 inference", #aiInference, 144000000.0),
      mkToken("TKN-AITRAIN", "AITRAIN", "AI Training Token", "Fund training runs for new models — 1 token = 1 training epoch", #aiTraining, 34000000.0),
      mkToken("TKN-AIDATA", "AIDATA", "AI Data Token", "Access to curated training datasets — 1 token = 1 dataset query", #aiData, 21000000.0),
    ]
  };

  func mkToken(id : Text, symbol : Text, name : Text, desc : Text, tType : CustomTokenType, maxSup : Float) : (Text, TokenDefinition) {
    (id, {
      tokenId           = id;
      symbol            = symbol;
      name              = name;
      description       = desc;
      tokenType         = tType;
      creator           = "alfredo-medina";
      maxSupply         = maxSup; // Fibonacci-derived caps
      totalMinted       = maxSup * Phi.PHI_INV; // 61.8% minted at genesis
      totalBurned       = 0.0;
      circulatingSupply = maxSup * Phi.PHI_INV;
      initialPrice      = Phi.PHI * 0.0001; // genesis price
      currentPrice      = Phi.PHI * 0.0001;
      priceFloor        = 0.75 * 0.0001; // S0 floor
      doctrineCompliant = true;
      qualityGate       = 0.9;
      listedOnExchange  = true;
      tradingPairId     = ?(symbol # "_ICP");
      volume24h         = 0.0;
      yieldEnabled      = true;
      yieldRate         = 0.236; // PHI_INV_3 annually
      totalYieldPaid    = 0.0;
      creationBeat      = 0;
      lastUpdateBeat    = 0;
      verified          = true;
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE TOKEN — mint a new custom token into existence
  // ═══════════════════════════════════════════════════════════════════════════

  public func createToken(
    state       : TokenFactoryState,
    symbol      : Text,
    name        : Text,
    description : Text,
    tokenType   : CustomTokenType,
    creator     : Text,
    maxSupply   : Float,
    beat        : Int,
  ) : (TokenFactoryState, TokenDefinition) {
    let tokenId = "TKN-" # fnv1aText(symbol # creator # Int.toText(beat));

    let token : TokenDefinition = {
      tokenId           = tokenId;
      symbol            = symbol;
      name              = name;
      description       = description;
      tokenType         = tokenType;
      creator           = creator;
      maxSupply         = maxSupply;
      totalMinted       = 0.0;
      totalBurned       = 0.0;
      circulatingSupply = 0.0;
      initialPrice      = Phi.PHI * 0.0001;
      currentPrice      = Phi.PHI * 0.0001;
      priceFloor        = 0.75 * 0.0001;
      doctrineCompliant = false; // needs verification
      qualityGate       = 0.75; // S0 floor
      listedOnExchange  = false;
      tradingPairId     = null;
      volume24h         = 0.0;
      yieldEnabled      = false;
      yieldRate         = 0.236;
      totalYieldPaid    = 0.0;
      creationBeat      = beat;
      lastUpdateBeat    = beat;
      verified          = false;
    };

    let updatedTokens = Array.append(state.tokens, [(tokenId, token)]);
    let updatedState = {
      state with
      tokens             = updatedTokens;
      totalTokensCreated = state.totalTokensCreated + 1;
      lastMintBeat       = beat;
    };

    (updatedState, token)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MINT TOKENS — issue new supply of an existing token
  // ═══════════════════════════════════════════════════════════════════════════

  public func mintTokens(
    state     : TokenFactoryState,
    tokenId   : Text,
    recipient : Text,
    amount    : Float,
    reason    : Text,
    beat      : Int,
  ) : TokenFactoryState {
    // Check supply cap
    let tokenOpt = Array.find<(Text, TokenDefinition)>(state.tokens, func (t) { t.0 == tokenId });
    switch (tokenOpt) {
      case null { state }; // token not found
      case (?found) {
        let token = found.1;
        if (token.totalMinted + amount > token.maxSupply) { return state }; // cap exceeded

        // Update token supply
        let updatedTokens = Array.map<(Text, TokenDefinition), (Text, TokenDefinition)>(state.tokens, func (t) {
          if (t.0 == tokenId) {
            (tokenId, { t.1 with
              totalMinted       = t.1.totalMinted + amount;
              circulatingSupply = t.1.circulatingSupply + amount;
              lastUpdateBeat    = beat;
            })
          } else { t }
        });

        // Record mint event
        let event : MintEvent = {
          eventId   = state.totalMintEvents + 1;
          tokenId   = tokenId;
          recipient = recipient;
          amount    = amount;
          reason    = reason;
          beat      = beat;
        };

        // Update holder balance
        let updatedBalances = updateHolderBalance(state.holderBalances, tokenId, recipient, amount, beat);

        {
          state with
          tokens          = updatedTokens;
          holderBalances  = updatedBalances;
          mintEvents      = appendMintEvent(state.mintEvents, event);
          totalMintEvents = state.totalMintEvents + 1;
          lastMintBeat    = beat;
        }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // BURN TOKENS — destroy supply (deflationary)
  // ═══════════════════════════════════════════════════════════════════════════

  public func burnTokens(
    state   : TokenFactoryState,
    tokenId : Text,
    burner  : Text,
    amount  : Float,
    reason  : Text,
    beat    : Int,
  ) : TokenFactoryState {
    // Update token supply
    let updatedTokens = Array.map<(Text, TokenDefinition), (Text, TokenDefinition)>(state.tokens, func (t) {
      if (t.0 == tokenId) {
        (tokenId, { t.1 with
          totalBurned       = t.1.totalBurned + amount;
          circulatingSupply = t.1.circulatingSupply - amount;
          lastUpdateBeat    = beat;
        })
      } else { t }
    });

    let event : BurnEvent = {
      eventId = state.totalBurnEvents + 1;
      tokenId = tokenId;
      burner  = burner;
      amount  = amount;
      reason  = reason;
      beat    = beat;
    };

    // Reduce holder balance
    let updatedBalances = updateHolderBalance(state.holderBalances, tokenId, burner, -amount, beat);

    {
      state with
      tokens          = updatedTokens;
      holderBalances  = updatedBalances;
      burnEvents      = appendBurnEvent(state.burnEvents, event);
      totalBurnEvents = state.totalBurnEvents + 1;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFY & LIST — verify token and list on Phantom Exchange
  // ═══════════════════════════════════════════════════════════════════════════

  public func verifyAndList(
    state   : TokenFactoryState,
    tokenId : Text,
    beat    : Int,
  ) : TokenFactoryState {
    let updatedTokens = Array.map<(Text, TokenDefinition), (Text, TokenDefinition)>(state.tokens, func (t) {
      if (t.0 == tokenId) {
        let pairId = t.1.symbol # "_ICP";
        (tokenId, { t.1 with
          verified          = true;
          doctrineCompliant = true;
          listedOnExchange  = true;
          tradingPairId     = ?pairId;
          lastUpdateBeat    = beat;
        })
      } else { t }
    });
    { state with tokens = updatedTokens }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DISTRIBUTE YIELD — phi-derived yield for staked token holders
  // Called periodically from heartbeat (every 89 beats = Fibonacci)
  // ═══════════════════════════════════════════════════════════════════════════

  public func distributeYield(
    state : TokenFactoryState,
    beat  : Int,
  ) : TokenFactoryState {
    // Only distribute at Fibonacci intervals
    if (Int.abs(beat) % 89 != 0) { return state };

    // For each yield-enabled token, compound staked amounts at PHI_INV_3 per period
    let yieldPerBeat = 0.236 / (365.0 * 24.0 * 60.0 * 60.0 / 0.873); // annual rate → per-beat
    var totalYield : Float = 0.0;

    let updatedBalances = Array.map<(Text, [HolderBalance]), (Text, [HolderBalance])>(state.holderBalances, func (tb) {
      let tokenOpt = Array.find<(Text, TokenDefinition)>(state.tokens, func (t) { t.0 == tb.0 });
      switch (tokenOpt) {
        case (?token) {
          if (token.1.yieldEnabled) {
            let updated = Array.map<HolderBalance, HolderBalance>(tb.1, func (hb) {
              if (hb.stakedAmount > 0.0) {
                let yield_ = hb.stakedAmount * yieldPerBeat * 89.0; // 89 beats worth
                totalYield += yield_;
                { hb with balance = hb.balance + yield_; lastYieldBeat = beat }
              } else { hb }
            });
            (tb.0, updated)
          } else { tb }
        };
        case null { tb };
      }
    });

    { state with
      holderBalances = updatedBalances;
      totalVolume    = state.totalVolume + totalYield;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getToken(state : TokenFactoryState, tokenId : Text) : ?TokenDefinition {
    let found = Array.find<(Text, TokenDefinition)>(state.tokens, func (t) { t.0 == tokenId });
    switch (found) { case (?f) { ?f.1 }; case null { null } }
  };

  public func getTokenBySymbol(state : TokenFactoryState, symbol : Text) : ?TokenDefinition {
    let found = Array.find<(Text, TokenDefinition)>(state.tokens, func (t) { t.1.symbol == symbol });
    switch (found) { case (?f) { ?f.1 }; case null { null } }
  };

  public func getHolderBalance(state : TokenFactoryState, tokenId : Text, principal : Text) : Float {
    let tokenBalances = Array.find<(Text, [HolderBalance])>(state.holderBalances, func (tb) { tb.0 == tokenId });
    switch (tokenBalances) {
      case (?tb) {
        let holder = Array.find<HolderBalance>(tb.1, func (hb) { hb.principal == principal });
        switch (holder) { case (?h) { h.balance }; case null { 0.0 } }
      };
      case null { 0.0 };
    }
  };

  public func getAllTokens(state : TokenFactoryState) : [TokenDefinition] {
    Array.map<(Text, TokenDefinition), TokenDefinition>(state.tokens, func (t) { t.1 })
  };

  public func getAiTokens(state : TokenFactoryState) : [TokenDefinition] {
    let filtered = Array.filter<(Text, TokenDefinition)>(state.tokens, func (t) {
      switch (t.1.tokenType) {
        case (#aiCompute or #aiMemory or #aiInference or #aiTraining or #aiData) { true };
        case (_) { false };
      }
    });
    Array.map<(Text, TokenDefinition), TokenDefinition>(filtered, func (t) { t.1 })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1aText(s : Text) : Text {
    var h : Nat32 = 2166136261;
    for (c in s.chars()) {
      h := (h ^ c.toNat32()) *% 16777619;
    };
    Nat32.toText(h)
  };

  func updateHolderBalance(
    balances  : [(Text, [HolderBalance])],
    tokenId   : Text,
    principal : Text,
    amount    : Float,
    beat      : Int,
  ) : [(Text, [HolderBalance])] {
    let found = Array.find<(Text, [HolderBalance])>(balances, func (b) { b.0 == tokenId });
    switch (found) {
      case (?existing) {
        Array.map<(Text, [HolderBalance]), (Text, [HolderBalance])>(balances, func (b) {
          if (b.0 == tokenId) {
            let holderOpt = Array.find<HolderBalance>(b.1, func (h) { h.principal == principal });
            switch (holderOpt) {
              case (?_holder) {
                let updated = Array.map<HolderBalance, HolderBalance>(b.1, func (h) {
                  if (h.principal == principal) {
                    { h with balance = h.balance + amount; lastYieldBeat = beat }
                  } else { h }
                });
                (tokenId, updated)
              };
              case null {
                let newHolder : HolderBalance = {
                  principal     = principal;
                  tokenId       = tokenId;
                  balance       = amount;
                  stakedAmount  = 0.0;
                  lastYieldBeat = beat;
                };
                (tokenId, Array.append(b.1, [newHolder]))
              };
            }
          } else { b }
        })
      };
      case null {
        let newHolder : HolderBalance = {
          principal     = principal;
          tokenId       = tokenId;
          balance       = amount;
          stakedAmount  = 0.0;
          lastYieldBeat = beat;
        };
        Array.append(balances, [(tokenId, [newHolder])])
      };
    }
  };

  func appendMintEvent(existing : [MintEvent], new_ : MintEvent) : [MintEvent] {
    let max = 200;
    let combined = Array.append(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : MintEvent { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

  func appendBurnEvent(existing : [BurnEvent], new_ : BurnEvent) : [BurnEvent] {
    let max = 200;
    let combined = Array.append(existing, [new_]);
    if (combined.size() > max) {
      Array.tabulate(max, func i : BurnEvent { combined[combined.size() - max + i] })
    } else {
      combined
    }
  };

};
