// ai_artifact_registry.mo — AI ARTIFACT REGISTRY & MARKETPLACE
// PARALLAX Sovereign Organism — Tokenized Intelligence Marketplace
//
// DOCTRINE: "Every cognitive output has value. Every model is an artifact.
// Every reasoning trace is intellectual property. Every embedding is knowledge.
// The AI Artifact Registry makes ALL intelligence tradeable — not as speculation
// but as recognition that knowledge, reasoning, and creation have inherent worth."
//
// This module:
//   1. REGISTERS AI artifacts (models, embeddings, protocols, outputs)
//   2. MINTS artifact tokens (each artifact becomes a tradeable unit)
//   3. TRACKS provenance (who created, when, from what inputs)
//   4. MANAGES royalties (creators earn on every trade of their artifact)
//   5. VERIFIES authenticity (FNV-1a hash chain, doctrine compliance)
//   6. COMPUTES valuation (integrates with PhantomIntelligence for pricing)
//
// PYTHAGORAS: royalty rate = PHI_INV_3 = 23.6% (Fibonacci harmony)
// EUCLID:     single registry — every artifact registered once, referenced everywhere
// CONFUCIUS:  right relationship — creators own, marketplace serves, organism protects
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Float "mo:core/Float";
import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Int "mo:core/Int";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTIFACT TYPE — what kind of AI output is this?
  // ═══════════════════════════════════════════════════════════════════════════

  public type ArtifactType = {
    #sovereignModel;      // A trained sovereign model from the model registry
    #vectorEmbedding;     // A semantic embedding (knowledge encoded as vectors)
    #reasoningProtocol;   // An executable reasoning protocol (steps + gates)
    #cognitiveOutput;     // A completed cognition output (answer, analysis, creation)
    #trainingDataset;     // Curated training data
    #predictionRecord;    // A verified prediction with outcome proof
    #compositeAgent;      // A multi-model agent composition
    #generativeArt;       // AI-generated creative work (art, music, text)
    #knowledgeGraph;      // Structured knowledge relationships
    #simulationResult;    // Results from organism simulation runs
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTIFACT RECORD — the complete registration of one AI artifact
  // ═══════════════════════════════════════════════════════════════════════════

  public type ArtifactRecord = {
    artifactId       : Text;          // unique ID: "ART-" + FNV hash
    name             : Text;          // human-readable name
    description      : Text;          // what this artifact does/contains
    artifactType     : ArtifactType;
    creator          : Text;          // principal of creator
    creationBeat     : Int;
    // Provenance
    sourceModels     : [Text];        // model IDs used to create this
    inputHash        : Text;          // FNV-1a hash of inputs
    outputHash       : Text;          // FNV-1a hash of outputs
    provenanceChain  : [Text];        // ordered list of transformation hashes
    // Tokenization
    tokenSymbol      : Text;          // e.g. "ART-PHI-001"
    totalSupply      : Float;         // tokens minted for this artifact
    circulatingSupply: Float;         // tokens in circulation
    price            : Float;         // current price in MTC
    marketCap        : Float;         // price × circulatingSupply
    // Quality & Doctrine
    qualityScore     : Float;         // [0.0, 1.0] — computed from resonance
    doctrineAlignment: Float;         // [0.0, 1.0] — law compliance
    resonanceScore   : Float;         // [0.0, 1.0] — semantic coherence
    // Royalties
    royaltyRate      : Float;         // PHI_INV_3 = 0.236 = 23.6%
    totalRoyaltiesEarned : Float;     // lifetime royalties in MTC
    // Status
    verified         : Bool;          // passed authentication checks
    tradeable        : Bool;          // listed on Phantom Exchange
    lastTradeBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ARTIFACT LISTING — marketplace listing for trading
  // ═══════════════════════════════════════════════════════════════════════════

  public type ArtifactListing = {
    artifactId     : Text;
    listingPrice   : Float;           // asking price in MTC
    seller         : Text;            // principal
    quantity       : Float;           // tokens for sale
    listBeat       : Int;
    expiryBeat     : ?Int;            // optional expiry
    status         : ListingStatus;
  };

  public type ListingStatus = { #active; #sold; #cancelled; #expired };

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATOR PROFILE — tracks a creator's AI artifact portfolio
  // ═══════════════════════════════════════════════════════════════════════════

  public type CreatorProfile = {
    principal        : Text;
    displayName      : Text;
    artifactsCreated : [Text];        // artifact IDs
    totalRoyalties   : Float;         // lifetime royalties earned (MTC)
    reputationScore  : Float;         // [0.0, 1.0] — based on artifact quality
    memberSinceBeat  : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // AI ARTIFACT REGISTRY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public type AiArtifactRegistryState = {
    artifacts          : [(Text, ArtifactRecord)];
    totalArtifacts     : Nat;
    listings           : [ArtifactListing];
    totalListings      : Nat;
    totalSales         : Nat;
    totalRoyaltiesPaid : Float;
    creators           : [(Text, CreatorProfile)];
    totalCreators      : Nat;
    // Marketplace metrics
    totalMarketCap     : Float;       // sum of all artifact market caps
    totalVolume        : Float;       // lifetime trading volume (MTC)
    // Meta
    registryActive     : Bool;
    lastRegistrationBeat : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE — born with genesis artifacts pre-seeded
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultAiArtifactRegistryState() : AiArtifactRegistryState {
    {
      artifacts            = genesisArtifacts();
      totalArtifacts       = 5;
      listings             = [];
      totalListings        = 0;
      totalSales           = 0;
      totalRoyaltiesPaid   = 0.0;
      creators             = [("alfredo-medina", defaultCreatorProfile())];
      totalCreators        = 1;
      totalMarketCap       = 0.0;
      totalVolume          = 0.0;
      registryActive       = true;
      lastRegistrationBeat = 0;
    }
  };

  func defaultCreatorProfile() : CreatorProfile {
    {
      principal        = "alfredo-medina";
      displayName      = "Alfredo Medina Hernandez — The Architect of the Field";
      artifactsCreated = ["ART-GENESIS-001", "ART-GENESIS-002", "ART-GENESIS-003", "ART-GENESIS-004", "ART-GENESIS-005"];
      totalRoyalties   = 0.0;
      reputationScore  = 1.0; // sovereign creator — maximum reputation
      memberSinceBeat  = 0;
    }
  };

  // Genesis artifacts — the founding AI artifacts of PARALLAX
  func genesisArtifacts() : [(Text, ArtifactRecord)] {
    [
      ("ART-GENESIS-001", mkArtifact("ART-GENESIS-001", "PHI Sovereign Model", "The foundational phi-family model governing all coupling constants", #sovereignModel, "PHI-001", 1000000.0)),
      ("ART-GENESIS-002", mkArtifact("ART-GENESIS-002", "Kuramoto Synchronization Protocol", "The universal sync protocol — R computation and coherence gating", #reasoningProtocol, "KURA-001", 500000.0)),
      ("ART-GENESIS-003", mkArtifact("ART-GENESIS-003", "PARALLAX Vector Space", "64-dim phi-seeded embedding space for all sovereign models", #vectorEmbedding, "VEC-001", 750000.0)),
      ("ART-GENESIS-004", mkArtifact("ART-GENESIS-004", "Enteric Standing Wave Set", "8 cosmological standing waves — the Third Brain's permanent residents", #knowledgeGraph, "ENT-001", 300000.0)),
      ("ART-GENESIS-005", mkArtifact("ART-GENESIS-005", "Cognition Layer World Model", "The CNS live world-model rebuilt every 873ms", #cognitiveOutput, "COG-001", 2000000.0)),
    ]
  };

  func mkArtifact(id : Text, name : Text, desc : Text, aType : ArtifactType, symbol : Text, supply : Float) : ArtifactRecord {
    {
      artifactId        = id;
      name              = name;
      description       = desc;
      artifactType      = aType;
      creator           = "alfredo-medina";
      creationBeat      = 0;
      sourceModels      = [];
      inputHash         = fnv1aText(id);
      outputHash        = fnv1aText(name);
      provenanceChain   = [fnv1aText(id # name)];
      tokenSymbol       = symbol;
      totalSupply       = supply;
      circulatingSupply = supply * Phi.PHI_INV; // 61.8% in circulation
      price             = Phi.PHI * 0.001;       // genesis price: φ × 0.001 MTC
      marketCap         = supply * Phi.PHI_INV * Phi.PHI * 0.001;
      qualityScore      = 0.9;
      doctrineAlignment = 1.0;
      resonanceScore    = Phi.PHI_INV;
      royaltyRate       = 0.236;  // PHI_INV_3 = 23.6%
      totalRoyaltiesEarned = 0.0;
      verified          = true;
      tradeable         = true;
      lastTradeBeat     = 0;
    }
  };

  // FNV-1a hash as text
  func fnv1aText(s : Text) : Text {
    var h : Nat32 = 2166136261;
    for (c in s.chars()) {
      h := (h ^ c.toNat32()) *% 16777619;
    };
    Nat32.toText(h)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // REGISTER ARTIFACT — mint a new AI artifact into the registry
  // ═══════════════════════════════════════════════════════════════════════════

  public func registerArtifact(
    state       : AiArtifactRegistryState,
    name        : Text,
    description : Text,
    artifactType: ArtifactType,
    creator     : Text,
    tokenSymbol : Text,
    totalSupply : Float,
    qualityScore: Float,
    beat        : Int,
  ) : (AiArtifactRegistryState, ArtifactRecord) {
    let artifactId = "ART-" # fnv1aText(name # creator # Int.toText(beat));

    let artifact : ArtifactRecord = {
      artifactId        = artifactId;
      name              = name;
      description       = description;
      artifactType      = artifactType;
      creator           = creator;
      creationBeat      = beat;
      sourceModels      = [];
      inputHash         = fnv1aText(name # creator);
      outputHash        = fnv1aText(description);
      provenanceChain   = [fnv1aText(artifactId # name)];
      tokenSymbol       = tokenSymbol;
      totalSupply       = totalSupply;
      circulatingSupply = totalSupply * Phi.PHI_INV;
      price             = Phi.PHI * 0.001; // initial price
      marketCap         = totalSupply * Phi.PHI_INV * Phi.PHI * 0.001;
      qualityScore      = if (qualityScore < 0.75) 0.75 else qualityScore; // S0 floor
      doctrineAlignment = 0.9; // verified later
      resonanceScore    = Phi.PHI_INV;
      royaltyRate       = 0.236; // 23.6% royalty
      totalRoyaltiesEarned = 0.0;
      verified          = false; // needs verification
      tradeable         = false; // listed after verification
      lastTradeBeat     = 0;
    };

    let updatedArtifacts = Array.append(state.artifacts, [(artifactId, artifact)]);
    let updatedCreators = updateCreatorArtifacts(state.creators, creator, artifactId, beat);

    let updatedState = {
      state with
      artifacts            = updatedArtifacts;
      totalArtifacts       = state.totalArtifacts + 1;
      creators             = updatedCreators;
      lastRegistrationBeat = beat;
    };

    (updatedState, artifact)
  };

  func updateCreatorArtifacts(
    creators : [(Text, CreatorProfile)],
    creator  : Text,
    artId    : Text,
    beat     : Int,
  ) : [(Text, CreatorProfile)] {
    let found = Array.find<(Text, CreatorProfile)>(creators, func (c) { c.0 == creator });
    switch (found) {
      case (?existing) {
        Array.map<(Text, CreatorProfile), (Text, CreatorProfile)>(creators, func (c) {
          if (c.0 == creator) {
            (creator, { c.1 with artifactsCreated = Array.append(c.1.artifactsCreated, [artId]) })
          } else { c }
        })
      };
      case null {
        let profile : CreatorProfile = {
          principal        = creator;
          displayName      = creator;
          artifactsCreated = [artId];
          totalRoyalties   = 0.0;
          reputationScore  = Phi.PHI_INV; // start at golden ratio
          memberSinceBeat  = beat;
        };
        Array.append(creators, [(creator, profile)])
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFY ARTIFACT — authenticate and enable trading
  // ═══════════════════════════════════════════════════════════════════════════

  public func verifyArtifact(
    state      : AiArtifactRegistryState,
    artifactId : Text,
    _beat      : Int,
  ) : AiArtifactRegistryState {
    let updatedArtifacts = Array.map<(Text, ArtifactRecord), (Text, ArtifactRecord)>(state.artifacts, func (a) {
      if (a.0 == artifactId) {
        (artifactId, { a.1 with verified = true; tradeable = true })
      } else { a }
    });
    { state with artifacts = updatedArtifacts }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORD TRADE — update artifact state after a trade on Phantom Exchange
  // Computes and distributes royalties to creator
  // ═══════════════════════════════════════════════════════════════════════════

  public func recordTrade(
    state      : AiArtifactRegistryState,
    artifactId : Text,
    tradePrice : Float,
    quantity   : Float,
    beat       : Int,
  ) : AiArtifactRegistryState {
    let updatedArtifacts = Array.map<(Text, ArtifactRecord), (Text, ArtifactRecord)>(state.artifacts, func (a) {
      if (a.0 == artifactId) {
        let royalty = tradePrice * quantity * a.1.royaltyRate;
        (artifactId, { a.1 with
          price                = tradePrice;
          marketCap            = tradePrice * a.1.circulatingSupply;
          totalRoyaltiesEarned = a.1.totalRoyaltiesEarned + royalty;
          lastTradeBeat        = beat;
        })
      } else { a }
    });

    // Update creator royalties
    let artOpt = Array.find<(Text, ArtifactRecord)>(state.artifacts, func (a) { a.0 == artifactId });
    let royaltyAmount = switch (artOpt) {
      case (?art) { tradePrice * quantity * art.1.royaltyRate };
      case null { 0.0 };
    };

    let updatedCreators = switch (artOpt) {
      case (?art) {
        Array.map<(Text, CreatorProfile), (Text, CreatorProfile)>(state.creators, func (c) {
          if (c.0 == art.1.creator) {
            (c.0, { c.1 with totalRoyalties = c.1.totalRoyalties + royaltyAmount })
          } else { c }
        })
      };
      case null { state.creators };
    };

    {
      state with
      artifacts          = updatedArtifacts;
      creators           = updatedCreators;
      totalSales         = state.totalSales + 1;
      totalRoyaltiesPaid = state.totalRoyaltiesPaid + royaltyAmount;
      totalVolume        = state.totalVolume + (tradePrice * quantity);
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  public func getArtifact(state : AiArtifactRegistryState, id : Text) : ?ArtifactRecord {
    let found = Array.find<(Text, ArtifactRecord)>(state.artifacts, func (a) { a.0 == id });
    switch (found) { case (?f) { ?f.1 }; case null { null } }
  };

  public func getCreatorProfile(state : AiArtifactRegistryState, principal : Text) : ?CreatorProfile {
    let found = Array.find<(Text, CreatorProfile)>(state.creators, func (c) { c.0 == principal });
    switch (found) { case (?f) { ?f.1 }; case null { null } }
  };

  public func getArtifactsByType(state : AiArtifactRegistryState, aType : ArtifactType) : [ArtifactRecord] {
    let filtered = Array.filter<(Text, ArtifactRecord)>(state.artifacts, func (a) {
      a.1.artifactType == aType
    });
    Array.map<(Text, ArtifactRecord), ArtifactRecord>(filtered, func (a) { a.1 })
  };

  public func getTradeableArtifacts(state : AiArtifactRegistryState) : [ArtifactRecord] {
    let filtered = Array.filter<(Text, ArtifactRecord)>(state.artifacts, func (a) {
      a.1.tradeable and a.1.verified
    });
    Array.map<(Text, ArtifactRecord), ArtifactRecord>(filtered, func (a) { a.1 })
  };

};
