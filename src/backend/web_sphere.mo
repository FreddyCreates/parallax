// web_sphere.mo — WEBBED SPHERE NETWORKING MODULE
// PARALLAX Sovereign Organism — Network Topology & Custom Token Flow Engine
//
// DOCTRINE: "The Webbed Sphere is the organism's nervous system visualization.
// Every node is a neuron. Every connection is a synapse. Custom tokens flow
// through the web like neurotransmitters — each type carrying different signal
// semantics: compute tokens pulse through processing nodes, memory tokens
// flow through storage nodes, governance tokens propagate through decision hubs."
//
// Architecture:
//   - SPHERE NODES: Each node on the sphere surface represents a live endpoint
//   - WEB CONNECTIONS: Edges between nodes with bandwidth/latency/token-flow metrics
//   - CUSTOM TOKEN FLOWS: Tokens of each CustomTokenType flow through specific routes
//   - PHI TOPOLOGY: Node placement follows golden-angle spiral on sphere (A04)
//   - KURAMOTO SYNC: Connection health measured by phase coherence (A06)
//
// PYTHAGORAS: node count limits are Fibonacci numbers, connection weights are phi-derived
// EUCLID:     single sphere — all nodes on one canonical surface
// CONFUCIUS:  right relationship — sovereign nodes govern, relay nodes serve, edge nodes compute
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi   "phi";
import Float "mo:core/Float";
import Int   "mo:core/Int";
import Nat   "mo:core/Nat";
import Nat32 "mo:core/Nat32";
import Array "mo:core/Array";
import Char  "mo:core/Char";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // NODE TYPES — roles on the webbed sphere
  // ═══════════════════════════════════════════════════════════════════════════

  public type SphereNodeRole = {
    #sovereign;       // Central governance hub — routes all token types
    #relay;           // Mid-tier relay — amplifies signals, caches token flows
    #compute;         // Edge compute — processes aiCompute/aiInference tokens
    #storage;         // Memory node — handles aiMemory/aiData tokens
    #gateway;         // External bridge — connects to ICP/BTC/ETH networks
    #validator;       // Consensus participant — validates token minting/burning
    #oracle;          // External data feed — market prices, AI model outputs
    #creator;         // Creator endpoint — mints creatorPersonal tokens
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOM TOKEN TYPE — what defines a custom token
  // Mirrored from token_factory.mo for sphere-local routing
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SPHERE NODE — a single point on the webbed sphere
  // ═══════════════════════════════════════════════════════════════════════════

  public type SphereNode = {
    nodeId        : Text;            // Unique identifier
    label         : Text;            // Human-readable label
    role          : SphereNodeRole;
    // Position on unit sphere (computed from golden angle at runtime)
    theta         : Float;           // azimuthal angle [0, 2π)
    phi_angle     : Float;           // polar angle [0, π]
    // State
    phase         : Float;           // Kuramoto phase ∈ [0, 2π)
    omega         : Float;           // Natural frequency
    health        : Float;           // [0, 1] — operational health
    throughput    : Float;           // [0, 1] — current data throughput
    // Token routing
    tokenTypes    : [CustomTokenType]; // which token types this node handles
    tokenVolume   : Float;           // total token volume flowing through
    // SSU compliance
    coherenceR    : Float;           // local Kuramoto R
    activeBeat    : Int;             // last active heartbeat
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // WEB CONNECTION — edge between two sphere nodes
  // ═══════════════════════════════════════════════════════════════════════════

  public type WebConnection = {
    fromNode      : Text;            // source node ID
    toNode        : Text;            // destination node ID
    bandwidth     : Float;           // [0, 1] — utilization
    latency       : Float;           // [0, 1] — lower is better
    // Token flow on this edge
    tokenFlows    : [TokenFlow];     // active flows on this connection
    strength      : Float;           // connection strength (phi-derived)
    isActive      : Bool;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN FLOW — a specific token type flowing through a connection
  // ═══════════════════════════════════════════════════════════════════════════

  public type TokenFlow = {
    tokenType     : CustomTokenType;
    volumePerBeat : Float;           // tokens/beat flowing
    direction     : { #forward; #reverse; #bidirectional };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SPHERE TOPOLOGY — the complete webbed sphere state
  // ═══════════════════════════════════════════════════════════════════════════

  public type SphereTopology = {
    nodes         : [(Text, SphereNode)];
    connections   : [WebConnection];
    // Global metrics
    totalNodes    : Nat;
    totalEdges    : Nat;
    globalR       : Float;           // Kuramoto order parameter of entire sphere
    avgBandwidth  : Float;
    avgLatency    : Float;
    // Token flow summary
    totalTokenVolume : Float;
    tokenFlowsByType : [(CustomTokenType, Float)]; // per-type volume summary
    // Topology health
    meshDensity   : Float;           // edges / max_possible_edges
    lastUpdateBeat: Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // FNV-1a 32-bit HASH — for node ID generation
  // ═══════════════════════════════════════════════════════════════════════════

  func fnv1a(input : Text) : Nat32 {
    var hash : Nat32 = 2166136261;
    for (c in input.chars()) {
      hash := hash ^ (Char.toNat32(c) % 256);
      hash := hash *% 16777619;
    };
    hash
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLDEN ANGLE PLACEMENT — distribute N nodes on sphere surface
  // Uses A04 GOLDEN_ANGLE to ensure no two nodes overlap
  // ═══════════════════════════════════════════════════════════════════════════

  public func goldenAnglePlacement(index : Nat, total : Nat) : (Float, Float) {
    let golden_angle : Float = Phi.GOLDEN_ANGLE * Float.pi / 180.0;
    let i = Float.fromInt(Int.abs(index));
    let n = Float.fromInt(Int.abs(total));
    // Polar angle: distribute evenly from pole to pole
    let phi_val = Float.acos(1.0 - 2.0 * i / n);
    // Azimuthal angle: golden angle increments
    let theta_val = golden_angle * i;
    (theta_val, phi_val)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTION STRENGTH — phi-derived decay with angular distance
  // ═══════════════════════════════════════════════════════════════════════════

  public func connectionStrength(angularDist : Float) : Float {
    // Strength decays as phi^(-angular_distance_in_radians)
    // Max strength = 1.0 at distance 0, minimum = S0 floor
    let raw = Float.exp(-angularDist * Phi.PHI_INV);
    Float.max(raw, Phi.S0 * 0.1) // floor at 10% of S0
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT TOPOLOGY — pre-seeded webbed sphere
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultTopology() : SphereTopology {
    let defaultNodes = genesisNodes();
    let defaultConns = genesisConnections();
    {
      nodes            = defaultNodes;
      connections      = defaultConns;
      totalNodes       = defaultNodes.size();
      totalEdges       = defaultConns.size();
      globalR          = Phi.S0;
      avgBandwidth     = 0.5;
      avgLatency       = 0.3;
      totalTokenVolume = 0.0;
      tokenFlowsByType = [];
      meshDensity      = 0.4;
      lastUpdateBeat   = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS NODES — initial sphere topology
  // ═══════════════════════════════════════════════════════════════════════════

  func genesisNodes() : [(Text, SphereNode)] {
    let labels = [
      ("PRIME-α",    #sovereign, [#governance, #yield]),
      ("GATE-Δ",     #gateway,   [#utility]),
      ("GATE-Λ",     #gateway,   [#utility]),
      ("GATE-Υ",     #gateway,   [#utility]),
      ("RELAY-Ω",    #relay,     [#aiInference, #aiCompute]),
      ("RELAY-Φ",    #relay,     [#aiMemory, #aiData]),
      ("RELAY-Η",    #relay,     [#aiTraining]),
      ("COMPUTE-Σ",  #compute,   [#aiCompute, #aiInference]),
      ("COMPUTE-Ψ",  #compute,   [#aiCompute]),
      ("COMPUTE-Θ",  #compute,   [#aiInference]),
      ("STORE-Π",    #storage,   [#aiMemory, #aiData]),
      ("STORE-Ξ",    #storage,   [#aiMemory]),
      ("VALID-Γ",    #validator, [#governance]),
      ("VALID-Κ",    #validator, [#governance, #yield]),
      ("ORACLE-Μ",   #oracle,    [#utility, #aiData]),
      ("ORACLE-Ν",   #oracle,    [#utility]),
      ("CREATE-Ρ",   #creator,   [#creatorPersonal, #artifactBacked]),
      ("CREATE-Τ",   #creator,   [#creatorPersonal, #rewardPoints]),
      ("EDGE-Χ",     #compute,   [#aiCompute, #fractionalNFT]),
      ("EDGE-Ε",     #compute,   [#aiInference, #utility]),
      ("RELAY-Ι",    #relay,     [#yield, #rewardPoints]),
      ("STORE-Ο",    #storage,   [#aiData, #aiMemory]),
      ("GATE-Ϛ",     #gateway,   [#utility, #governance]),
      ("PRIME-β",    #sovereign, [#governance, #yield, #utility]),
    ];
    Array.tabulate<(Text, SphereNode)>(labels.size(), func(i : Nat) : (Text, SphereNode) {
      let (label, role, tTypes) = labels[i];
      let nodeId = "WSN-" # label;
      let (theta_val, phi_val) = goldenAnglePlacement(i, labels.size());
      (nodeId, {
        nodeId      = nodeId;
        label       = label;
        role        = role;
        theta       = theta_val;
        phi_angle   = phi_val;
        phase       = Float.fromInt(Int.abs(i)) * Phi.PHI_INV;
        omega       = 1.0 + Float.fromInt(Int.abs(i % 5)) * 0.2;
        health      = 1.0;
        throughput  = 0.5;
        tokenTypes  = tTypes;
        tokenVolume = 0.0;
        coherenceR  = Phi.S0;
        activeBeat  = 0;
      })
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GENESIS CONNECTIONS — initial web topology
  // Sovereign → Gateways → Relays → Compute/Storage/Validators
  // ═══════════════════════════════════════════════════════════════════════════

  func genesisConnections() : [WebConnection] {
    let pairs : [(Text, Text, Float)] = [
      // Sovereign to gateways
      ("WSN-PRIME-α", "WSN-GATE-Δ",    0.95),
      ("WSN-PRIME-α", "WSN-GATE-Λ",    0.90),
      ("WSN-PRIME-α", "WSN-GATE-Υ",    0.88),
      ("WSN-PRIME-β", "WSN-GATE-Ϛ",    0.92),
      // Gateways to relays
      ("WSN-GATE-Δ",  "WSN-RELAY-Ω",   0.80),
      ("WSN-GATE-Δ",  "WSN-RELAY-Φ",   0.75),
      ("WSN-GATE-Λ",  "WSN-RELAY-Η",   0.78),
      ("WSN-GATE-Υ",  "WSN-RELAY-Ι",   0.72),
      ("WSN-GATE-Ϛ",  "WSN-RELAY-Ω",   0.70),
      // Relays to compute
      ("WSN-RELAY-Ω", "WSN-COMPUTE-Σ", 0.85),
      ("WSN-RELAY-Ω", "WSN-COMPUTE-Ψ", 0.80),
      ("WSN-RELAY-Ω", "WSN-COMPUTE-Θ", 0.78),
      ("WSN-RELAY-Φ", "WSN-STORE-Π",   0.82),
      ("WSN-RELAY-Φ", "WSN-STORE-Ξ",   0.76),
      ("WSN-RELAY-Η", "WSN-COMPUTE-Σ", 0.74),
      // Relays to validators
      ("WSN-RELAY-Ω", "WSN-VALID-Γ",   0.70),
      ("WSN-RELAY-Ι", "WSN-VALID-Κ",   0.68),
      // Relays to oracles
      ("WSN-RELAY-Φ", "WSN-ORACLE-Μ",  0.65),
      ("WSN-RELAY-Η", "WSN-ORACLE-Ν",  0.60),
      // Relays to creators
      ("WSN-RELAY-Ι", "WSN-CREATE-Ρ",  0.72),
      ("WSN-RELAY-Φ", "WSN-CREATE-Τ",  0.68),
      // Edge mesh
      ("WSN-COMPUTE-Σ", "WSN-EDGE-Χ",  0.60),
      ("WSN-COMPUTE-Θ", "WSN-EDGE-Ε",  0.58),
      ("WSN-EDGE-Χ",    "WSN-EDGE-Ε",  0.45),
      // Cross-links (mesh density)
      ("WSN-STORE-Π",   "WSN-STORE-Ο", 0.55),
      ("WSN-VALID-Γ",   "WSN-VALID-Κ", 0.50),
      ("WSN-ORACLE-Μ",  "WSN-ORACLE-Ν",0.48),
      ("WSN-CREATE-Ρ",  "WSN-CREATE-Τ",0.52),
      // Sovereign cross-link
      ("WSN-PRIME-α",   "WSN-PRIME-β", 0.98),
    ];
    Array.tabulate<WebConnection>(pairs.size(), func(i : Nat) : WebConnection {
      let (from, to, bw) = pairs[i];
      {
        fromNode   = from;
        toNode     = to;
        bandwidth  = bw;
        latency    = 1.0 - bw * 0.8;
        tokenFlows = [];
        strength   = bw * Phi.PHI_INV;
        isActive   = true;
      }
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // KURAMOTO ORDER PARAMETER — measure sphere coherence
  // ═══════════════════════════════════════════════════════════════════════════

  public func kuramotoR(nodes : [(Text, SphereNode)]) : Float {
    if (nodes.size() == 0) return 0.0;
    var sumSin : Float = 0.0;
    var sumCos : Float = 0.0;
    for ((_, node) in nodes.vals()) {
      sumSin += Float.sin(node.phase);
      sumCos += Float.cos(node.phase);
    };
    let n = Float.fromInt(Int.abs(nodes.size()));
    Float.sqrt((sumSin / n) ** 2 + (sumCos / n) ** 2)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN TYPE TO ROLE ROUTING — which roles handle which token types
  // ═══════════════════════════════════════════════════════════════════════════

  public func tokenTypeLabel(tt : CustomTokenType) : Text {
    switch (tt) {
      case (#aiCompute)       "AI-COMPUTE";
      case (#aiMemory)        "AI-MEMORY";
      case (#aiInference)     "AI-INFERENCE";
      case (#aiTraining)      "AI-TRAINING";
      case (#aiData)          "AI-DATA";
      case (#creatorPersonal) "CREATOR";
      case (#artifactBacked)  "ARTIFACT";
      case (#governance)      "GOVERNANCE";
      case (#yield)           "YIELD";
      case (#utility)         "UTILITY";
      case (#rewardPoints)    "REWARDS";
      case (#fractionalNFT)   "FRAC-NFT";
    }
  };

  public func roleLabel(r : SphereNodeRole) : Text {
    switch (r) {
      case (#sovereign)  "SOVEREIGN";
      case (#relay)      "RELAY";
      case (#compute)    "COMPUTE";
      case (#storage)    "STORAGE";
      case (#gateway)    "GATEWAY";
      case (#validator)  "VALIDATOR";
      case (#oracle)     "ORACLE";
      case (#creator)    "CREATOR";
    }
  };
};
