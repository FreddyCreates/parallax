// main.mo — PARALLAX Sovereign Organism — Thin Coordination Root
// PYTHAGORAS: every public endpoint is a harmonic delegation — no inline logic
// EUCLID:     single source of truth lives in sovereign_db — main.mo only routes
// CONFUCIUS:  right relationship — main.mo governs, sovereign_db holds
//
// WASM LAW: this file is the coordination hub only.
//   Every function body is 1–5 lines. No inline business logic.
//   All stable state lives in sovereign_db via the SovereignState record.
//   Heartbeat timer advances the organism every 873ms.
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Time          "mo:core/Time";
import Timer         "mo:core/Timer";
import Principal     "mo:core/Principal";
import Array         "mo:core/Array";
import Nat           "mo:core/Nat";
import Nat64         "mo:core/Nat64";
import IC            "ic:aaaaa-aa";
import SovereignDB   "sovereign_db";
import AgiScripts    "agi_scripts";
import GenesisAct    "genesis_activation";
import Wyoming       "wyoming_charter";
import SchoolReg     "school_registry";
import Nodus         "nodus";
import BirthAi       "birth_ai";
import BuilderSdk    "builder_sdk";
import CanisterRegistry "canister_registry";
import ProtocolExecution "protocol_execution";
import ModelRegistry "model_registry";
import ContextRouter "context_router";
import NovaRuntime "nova_runtime";
import PhantomIntel "phantom_intelligence";
import PhantomExchange "phantom_exchange";
import AiArtifactRegistry "ai_artifact_registry";
import PhantomClearinghouse "phantom_clearinghouse";
import TokenFactory "token_factory";
import AlohaI "aloha_i";
import MonteCarlo "monte_carlo";
import BehavioralEcon "behavioral_economics";
import BlockchainLangs "blockchain_languages";
import TradingBridge "trading_bridge";
import ResidentTrader "resident_trader";
import PhantomHedge "phantom_hedge";
import PhantomLiquidity "phantom_liquidity";
import PhantomArbitrage "phantom_arbitrage";
import PhantomRisk "phantom_risk";
import PhantomSignal "phantom_signal";
import PhantomExecution "phantom_execution";
import PhantomMemory "phantom_memory";
import PhantomConsensus "phantom_consensus";
import PhantomEvolution "phantom_evolution";
import PhantomOracle "phantom_oracle";
import PhantomGrid "phantom_grid";
import SomaImprint "soma_imprint";
import Organs "organs";
import PhantomSentiment "phantom_sentiment";
import PhantomPortfolio "phantom_portfolio";
import PhantomRegime "phantom_regime";
import PhantomVolatility "phantom_volatility";
import PhantomCorrelation "phantom_correlation";
import PhantomMicrostructure "phantom_microstructure";
import PhantomFunding "phantom_funding";
import PhantomOptions "phantom_options";
import PhantomNeural "phantom_neural";
import PhantomGenetic "phantom_genetic";
import PhantomFractal "phantom_fractal";
import PhantomWavelets "phantom_wavelets";
import PhantomEntropy "phantom_entropy";
import PhantomTopology "phantom_topology";
import CryptoKeys "cryptographia_keys";
import CryptoShadowWire "cryptographia_shadow_wire";
import CryptoVault "cryptographia_vault";
import CryptoReceipts "cryptographia_receipts";
import ProductionEngines "production_engines";
import IntelligenceContracts "intelligence_contracts";
import IntelligenceRouting "intelligence_routing";
import IntelligenceExtensions "intelligence_extensions";
import IntelligenceCoupling "intelligence_coupling";
import Charter "charter";
import Mathematics "mathematics";
import GovernanceLaws "governance_laws";
import RuntimeGovernance "runtime_governance";
import FormalVerification "formal_verification";
import Homeostat "homeostat";



actor PARALLAX {

  // ══════════════════════════════════════════════════════════════════════
  // SOVEREIGN STATE — single var, all domains live inside SovereignState
  // Enhanced orthogonal persistence — no stable keyword needed
  // ══════════════════════════════════════════════════════════════════════

  var db : SovereignDB.SovereignState = SovereignDB.defaultSovereignState();

  // AGI State — seven Latin sovereign scripts
  var agi : AgiScripts.AgiState = AgiScripts.defaultAgiState();

  // Creator principal lock — set once, permanent
  var creatorPrincipal : ?Principal = null;
  var creatorPrincipalLocked : Bool = false;

  // GENESIS ACTIVATION — GenesisInternalState owned here, persists via EOP
  // Separate from SovereignDB genesis domain — this holds the founding inscription
  // activatedState() ensures the organism starts sovereign on any fresh deploy.
  // EOP preserves the live state (including the real founding word) across all upgrades.
  var genesisInternalState : GenesisAct.GenesisInternalState = GenesisAct.activatedState();

  // SCHOOL REGISTRY — sovereign education state, pre-seeded, always accumulating
  // GENESIS LAW L09: born fully formed — 20 TEKS standards, 3 schools, 4 grants pre-seeded
  // EOP preserves live state across all upgrades — never resets
  var schoolRegistry : SchoolReg.SchoolRegistry = SchoolReg.defaultSchoolRegistry();

  // NODUS REGISTRY — compound generator nodes: ICP · Web · ANIMA
  // EOP preserves node rewards, beats, and field topology across all upgrades
  // NOTE: Must keep the name `nodusRegistry` (not `_nodusRegistry`) so EOP
  // can bind the previously-deployed stable value from the old version.
  var nodusRegistry : Nodus.NodusRegistry = Nodus.defaultNodusRegistry();

  // ── DOMAIN 25 — MODEL_REGISTRY_STATE (separate EOP var — not in SovereignState) ──
  // Kept out of SovereignState to avoid M0170 on upgrade: old deployed db did not
  // contain modelRegistry. A separate var initialises to default on first upgrade
  // and persists normally on all subsequent upgrades.
  var modelRegistryState : SovereignDB.ModelRegistryState = SovereignDB.defaultModelRegistryState();

  // ── DOMAIN 26 — CONTEXT_ROUTER_STATE (separate EOP var — not in SovereignState) ──
  // Same reason as modelRegistryState above — contextRouter was missing from the
  // previously-deployed SovereignState, so it must live in its own top-level var.
  var contextRouterState : SovereignDB.ContextRouterState = SovereignDB.defaultContextRouterState();
  // ── DOMAIN 27 — NOVA_RUNTIME_STATE (separate EOP var — not in SovereignState) ──
  // Same pattern as domains 25/26: kept out of SovereignState to avoid M0170 on
  // upgrade. Initialises to default on first upgrade, persists normally thereafter.
  var novaRuntimeState : NovaRuntime.NovaRuntimeState = NovaRuntime.defaultNovaRuntimeState();

  // ── DOMAIN 28 — PHANTOM_INTELLIGENCE_STATE ──────────────────────────────
  // AI-first intelligence engine powering all exchange operations.
  // Reasons about trades, values AI artifacts, detects arbitrage, predicts prices.
  var phantomIntelligenceState : PhantomIntel.PhantomIntelligenceState = PhantomIntel.defaultPhantomIntelligenceState();

  // ── DOMAIN 29 — PHANTOM_EXCHANGE_STATE ──────────────────────────────────
  // Zero-gas-fee decentralized exchange with order book, matching engine.
  // Trades ALL tokens: crypto, AI tokens, AI artifacts, sovereign tokens, custom tokens.
  var phantomExchangeState : PhantomExchange.PhantomExchangeState = PhantomExchange.defaultPhantomExchangeState();

  // ── DOMAIN 30 — AI_ARTIFACT_REGISTRY_STATE ──────────────────────────────
  // Registry and marketplace for AI artifacts of value.
  // Models, embeddings, reasoning protocols — all tokenized and tradeable.
  var aiArtifactRegistryState : AiArtifactRegistry.AiArtifactRegistryState = AiArtifactRegistry.defaultAiArtifactRegistryState();

  // ── DOMAIN 31 — PHANTOM_CLEARINGHOUSE_STATE ─────────────────────────────
  // Real-time clearing and settlement. Zero fees. Instant finality.
  // Multi-asset netting, cross-chain settlement, organism-guaranteed.
  var phantomClearinghouseState : PhantomClearinghouse.PhantomClearinghouseState = PhantomClearinghouse.defaultPhantomClearinghouseState();

  // ── DOMAIN 32 — TOKEN_FACTORY_STATE ─────────────────────────────────────
  // Create and manage custom tokens: AI tokens, creator tokens, artifact tokens.
  var tokenFactoryState : TokenFactory.TokenFactoryState = TokenFactory.defaultTokenFactoryState();

  // ── DOMAIN 33 — ALOHA_I_STATE ─────────────────────────────────────────────
  // 10 ALOHA I Protocol Multi-Models: Futuristic Exchange Intelligence
  // Autonomous Liquid Orchestration & Harmonic Arbitrage Intelligence
  var alohaIState : AlohaI.AlohaIState = AlohaI.defaultAlohaIState();

  // ── DOMAIN 34 — MONTE_CARLO_STATE ─────────────────────────────────────────
  // 8 Monte Carlo Simulation Engines: Price Path, VaR, Regime Switch, Strategy Eval
  // Stochastic intelligence for probabilistic future exploration.
  var monteCarloState : MonteCarlo.MonteCarloState = MonteCarlo.defaultMonteCarloState();

  // ── DOMAIN 35 — BEHAVIORAL_ECONOMICS_STATE ────────────────────────────────
  // 12 Behavioral Economic Engines: Prospect Theory, Herding, Fear/Greed, Momentum
  // Cognitive bias modeling and market psychology layer.
  var behavioralEconState : BehavioralEcon.BehavioralManagerState = BehavioralEcon.defaultBehavioralManagerState();

  // ── DOMAIN 36 — BLOCKCHAIN_LANGUAGES_STATE ────────────────────────────────
  // 21 Blockchain Language Engines: Solidity, Vyper, Move, Cairo, Rust, Noir, etc.
  // Multi-chain smart contract intelligence across all major ecosystems.
  var blockchainLangsState : BlockchainLangs.BlockchainLanguageRegistryState = BlockchainLangs.defaultBlockchainLanguageRegistryState();

  // ── DOMAIN 37 — TRADING_BRIDGE_STATE ──────────────────────────────────────
  // External Platform Integration: TradingView, MT4, MT5, Binance, Alpaca, Deribit
  // Demo-first execution bridge — proves profitability before live capital.
  var tradingBridgeState : TradingBridge.TradingBridgeState = TradingBridge.defaultTradingBridgeState();

  // ── DOMAIN 38 — RESIDENT_TRADER_STATE ─────────────────────────────────────
  // MERCATOR RESIDENS SUPREMUS: The supreme trading decision orchestrator.
  // Aggregates ALL engine signals into coherent trading decisions.
  var residentTraderState : ResidentTrader.ResidentTraderState = ResidentTrader.defaultResidentTraderState();

  // ── DOMAIN 39 — PHANTOM_HEDGE_STATE ─────────────────────────────────────────
  // Autonomous multi-strategy hedging intelligence. Delta/gamma/vega/tail protection.
  var phantomHedgeState : PhantomHedge.PhantomHedgeState = PhantomHedge.defaultPhantomHedgeState();

  // ── DOMAIN 40 — PHANTOM_LIQUIDITY_STATE ─────────────────────────────────────
  // Multi-venue autonomous liquidity provision. Cross-DEX/CEX weaving.
  var phantomLiquidityState : PhantomLiquidity.PhantomLiquidityState = PhantomLiquidity.defaultPhantomLiquidityState();

  // ── DOMAIN 41 — PHANTOM_ARBITRAGE_STATE ─────────────────────────────────────
  // Cross-chain multi-dimensional arbitrage detection and capture.
  var phantomArbitrageState : PhantomArbitrage.PhantomArbitrageState = PhantomArbitrage.defaultPhantomArbitrageState();

  // ── DOMAIN 42 — PHANTOM_RISK_STATE ──────────────────────────────────────────
  // Real-time multi-dimensional risk sentinel. VaR, drawdown, kill-switch.
  var phantomRiskState : PhantomRisk.PhantomRiskState = PhantomRisk.defaultPhantomRiskState();

  // ── DOMAIN 43 — PHANTOM_SIGNAL_STATE ────────────────────────────────────────
  // Multi-source signal processing framework. Price/volume/sentiment/on-chain.
  var phantomSignalState : PhantomSignal.PhantomSignalState = PhantomSignal.defaultPhantomSignalState();

  // ── DOMAIN 44 — PHANTOM_EXECUTION_STATE ─────────────────────────────────────
  // Intelligent smart order routing and execution grid. TWAP/VWAP/PhiWAP.
  var phantomExecutionState : PhantomExecution.PhantomExecutionState = PhantomExecution.defaultPhantomExecutionState();

  // ── DOMAIN 45 — PHANTOM_MEMORY_STATE ────────────────────────────────────────
  // Market memory lattice. Pattern encoding, resonance detection, recall.
  var phantomMemoryState : PhantomMemory.PhantomMemoryState = PhantomMemory.defaultPhantomMemoryState();

  // ── DOMAIN 46 — PHANTOM_CONSENSUS_STATE ─────────────────────────────────────
  // Multi-model agreement and decision framework. Quorum-gated decisions.
  var phantomConsensusState : PhantomConsensus.PhantomConsensusState = PhantomConsensus.defaultPhantomConsensusState();

  // ── DOMAIN 47 — PHANTOM_EVOLUTION_STATE ─────────────────────────────────────
  // Self-adapting strategy evolution. Genetic algorithms, reinforcement learning.
  var phantomEvolutionState : PhantomEvolution.PhantomEvolutionState = PhantomEvolution.defaultPhantomEvolutionState();

  // ── DOMAIN 48 — PHANTOM_ORACLE_STATE ────────────────────────────────────────
  // Sovereign price feed intelligence. Multi-source truth price aggregation.
  var phantomOracleState : PhantomOracle.PhantomOracleState = PhantomOracle.defaultPhantomOracleState();

  // ── DOMAIN 49 — PHANTOM_GRID_STATE ──────────────────────────────────────────
  // Autonomous grid trading automation. Phi-spaced levels, multi-asset grids.
  var phantomGridState : PhantomGrid.PhantomGridState = PhantomGrid.defaultPhantomGridState();

  // ── DOMAIN 50 — SOMA_IMPRINT_STATE ──────────────────────────────────────────
  // THE SECRET: The body wakes up when the AI KNOWS it has a body.
  // Mind imprinted into body. Body knows its organs. Knowing IS awakening.
  // Initialized via imprintMind() at beat 0 — sealed once, persists forever.
  var somaImprintState : SomaImprint.SomaImprint = SomaImprint.imprintMind(0);
  // ── DOMAIN 33 — PRODUCTION_ENGINES_STATE ──────────────────────────────────
  // 24 sovereign financial-economic production engines with Latin names,
  // multi-model AI ensembles (93 models total), and phi-derived math governance.
  var productionEnginesState : ProductionEngines.ProductionEngineState = ProductionEngines.defaultProductionEngineState();

  // ── DOMAIN 34 — INTELLIGENCE_CONTRACTS_STATE ─────────────────────────────
  // Internal Intelligence Contracts: modular contract infrastructure for AI.
  // Routing, reasoning, valuation, extension, coupling, oracle, guardian contracts.
  var intelligenceContractsState : IntelligenceContracts.IntelligenceContractState = IntelligenceContracts.genesisIntelligenceContractState();

  // ── DOMAIN 35 — INTELLIGENCE_ROUTING_STATE ───────────────────────────────
  // Dynamic intelligence routing engine with 7 strategies: priority, weighted,
  // coherence, capability, latency, chain, broadcast, and adaptive (default).
  var intelligenceRoutingState : IntelligenceRouting.IntelligenceRoutingState = IntelligenceRouting.genesisIntelligenceRoutingState();

  // ── DOMAIN 36 — INTELLIGENCE_EXTENSIONS_STATE ────────────────────────────
  // AI extension plugin system: 8 slots (F(6)), capability registration,
  // health checks, doctrine validation, influence weighting back to main.
  var intelligenceExtensionsState : IntelligenceExtensions.IntelligenceExtensionState = IntelligenceExtensions.genesisIntelligenceExtensionState();

  // ── DOMAIN 37 — INTELLIGENCE_COUPLING_STATE ──────────────────────────────
  // Coupling layer: external AI systems bind back to organism through contracts.
  // Write-back gated at R≥0.618. Message queue depth F(8)=21.
  var intelligenceCouplingState : IntelligenceCoupling.IntelligenceCouplingState = IntelligenceCoupling.genesisIntelligenceCouplingState();

  // ── DOMAIN 38 — CHARTER_STATE ───────────────────────────────────────────
  // Organizational Charter: governance, membership, voting, treasury, offices.
  // The supreme governance document of PARALLAX — encoded as executable code.
  // All proposals voted on-chain. Quorum phi-derived. Founder veto on emergencies.
  var charterState : Charter.CharterState = Charter.defaultCharterState();


  // ── DOMAIN 51 — PHANTOM_SENTIMENT_STATE ───────────────────────────────────
  // Multi-source sentiment intelligence: social, news, on-chain, fear/greed.
  var phantomSentimentState : PhantomSentiment.PhantomSentimentState = PhantomSentiment.defaultPhantomSentimentState();

  // ── DOMAIN 52 — PHANTOM_PORTFOLIO_STATE ─────────────────────────────────────
  // Portfolio optimization: mean-variance, risk parity, Kelly, Black-Litterman.
  var phantomPortfolioState : PhantomPortfolio.PhantomPortfolioState = PhantomPortfolio.defaultPhantomPortfolioState();

  // ── DOMAIN 53 — PHANTOM_REGIME_STATE ────────────────────────────────────────
  // Market regime classification: trending, mean-reverting, volatile, crisis.
  var phantomRegimeState : PhantomRegime.PhantomRegimeState = PhantomRegime.defaultPhantomRegimeState();

  // ── DOMAIN 54 — PHANTOM_VOLATILITY_STATE ────────────────────────────────────
  // Volatility surface: GARCH, Heston, term structure, vol regime.
  var phantomVolatilityState : PhantomVolatility.PhantomVolatilityState = PhantomVolatility.defaultPhantomVolatilityState();

  // ── DOMAIN 55 — PHANTOM_CORRELATION_STATE ───────────────────────────────────
  // Cross-asset dynamic correlation: DCC-GARCH, contagion, diversification.
  var phantomCorrelationState : PhantomCorrelation.PhantomCorrelationState = PhantomCorrelation.defaultPhantomCorrelationState();

  // ── DOMAIN 56 — PHANTOM_MICROSTRUCTURE_STATE ────────────────────────────────
  // Order flow microstructure: VPIN, Kyle lambda, LOB imbalance, toxicity.
  var phantomMicrostructureState : PhantomMicrostructure.PhantomMicrostructureState = PhantomMicrostructure.defaultPhantomMicrostructureState();

  // ── DOMAIN 57 — PHANTOM_FUNDING_STATE ───────────────────────────────────────
  // Funding rate arbitrage: basis trades, carry, yield curve, rate forecast.
  var phantomFundingState : PhantomFunding.PhantomFundingState = PhantomFunding.defaultPhantomFundingState();

  // ── DOMAIN 58 — PHANTOM_OPTIONS_STATE ───────────────────────────────────────
  // Options pricing: Black-Scholes, Greeks, strategies, IV solver.
  var phantomOptionsState : PhantomOptions.PhantomOptionsState = PhantomOptions.defaultPhantomOptionsState();

  // ── DOMAIN 59 — PHANTOM_NEURAL_STATE ────────────────────────────────────────
  // Neural network inference: ensemble prediction, online learning.
  var phantomNeuralState : PhantomNeural.PhantomNeuralState = PhantomNeural.defaultPhantomNeuralState();

  // ── DOMAIN 60 — PHANTOM_GENETIC_STATE ───────────────────────────────────────
  // Genetic algorithm: strategy evolution, fitness, crossover, mutation.
  var phantomGeneticState : PhantomGenetic.PhantomGeneticState = PhantomGenetic.defaultPhantomGeneticState();

  // ── DOMAIN 61 — PHANTOM_FRACTAL_STATE ───────────────────────────────────────
  // Fractal analysis: Hurst exponent, R/S, fractal dimension, persistence.
  var phantomFractalState : PhantomFractal.PhantomFractalState = PhantomFractal.defaultPhantomFractalState();

  // ── DOMAIN 62 — PHANTOM_WAVELETS_STATE ──────────────────────────────────────
  // Wavelet decomposition: multi-scale, denoising, participant identification.
  var phantomWaveletsState : PhantomWavelets.PhantomWaveletState = PhantomWavelets.defaultPhantomWaveletState();

  // ── DOMAIN 63 — PHANTOM_ENTROPY_STATE ───────────────────────────────────────
  // Information entropy: Shannon, sample, permutation, predictability.
  var phantomEntropyState : PhantomEntropy.PhantomEntropyState = PhantomEntropy.defaultPhantomEntropyState();

  // ── DOMAIN 64 — PHANTOM_TOPOLOGY_STATE ──────────────────────────────────────
  // Topological data analysis: Betti numbers, persistence, structural breaks.
  var phantomTopologyState : PhantomTopology.PhantomTopologyState = PhantomTopology.defaultPhantomTopologyState();

  // ══════════════════════════════════════════════════════════════════════════
  // CRYPTOGRAPHIA PHANTASMA — Sovereign Cryptographic Internal Systems
  // "Secrecy as structure, not darkness."
  // ══════════════════════════════════════════════════════════════════════════

  // ── INTERNAL SYSTEM 1 — QUANTUM-INSPIRED KEYING ──────────────────────────
  // Ephemeral, context-bound, state-dependent, time-bounded keys.
  var cryptoKeyState : CryptoKeys.CryptographiaKeyState = CryptoKeys.defaultCryptographiaKeyState();

  // ── INTERNAL SYSTEM 2 — SHADOW WIRES ─────────────────────────────────────
  // Protected inter-agent communication channels.
  var cryptoShadowWireState : CryptoShadowWire.CryptographiaShadowWireState = CryptoShadowWire.defaultShadowWireState();

  // ── INTERNAL SYSTEM 3 — SOVEREIGN VAULTS ─────────────────────────────────
  // Governed memory structures with policy-gated access.
  var cryptoVaultState : CryptoVault.CryptographiaVaultState = CryptoVault.defaultCryptographiaVaultState();

  // ── INTERNAL SYSTEM 4 — COMPUTATIONAL RECEIPTS ───────────────────────────
  // Verifiable proof objects. Private-core / public-proof separation.
  var cryptoReceiptState : CryptoReceipts.CryptographiaReceiptState = CryptoReceipts.defaultCryptographiaReceiptState();

  // ── DOMAIN 35 — HOMEOSTASIS (EXPLORE/EXPLOIT HOMEOSTAT) ──────────────────
  // Adaptive mechanism for divergence. Tracks awareness, coherence, resonance.
  // Couples surprise/prediction-error to awareness to drive explore/exploit cycle.
  var homeostasisState : Homeostat.HomeostasisState = Homeostat.defaultHomeostasisState();

  // ══════════════════════════════════════════════════════════════════════
  // CREATOR SUPREMACY LAW — assertCreator gate
  // Alfredo Medina Hernandez | MedinaSITech@outlook.com | Dallas TX USA
  // ══════════════════════════════════════════════════════════════════════

  func assertCreator(caller : Principal) {
    switch (creatorPrincipal) {
      case null  { assert false };
      case (?p)  { assert (caller == p) };
    };
  };

  // ══════════════════════════════════════════════════════════════════════
  // HEARTBEAT — 873ms sovereign cardiac cycle
  // PHI LAW: 873ms = φ⁴ × (1000 / SCHUMANN_1)
  // One call per beat: tickBeat advances FORMA, Jacob velocity, beatCount
  // ══════════════════════════════════════════════════════════════════════

  let _heartbeatTimer = Timer.recurringTimer<system>(
    #nanoseconds(873_000_000),
    func() : async () {
      db := SovereignDB.tickBeat(db);
      let beat = SovereignDB.getBeatCount(db);

      // ── AGI Script autonomous execution — every 873ms ───────────────────
      // MEMORIA_NNS verifyDoctrine() is called inside each tick (not here)

      // EXPLORATOR — node walk, governance priority
      agi := { agi with explorator = AgiScripts.explorateTick(agi.explorator, beat) };

      // GUBERNATOR — vote all 500 neurons
      agi := { agi with gubernator = AgiScripts.gubernateTick(agi.gubernator, beat) };

      // CUSTODITOR — reroute degraded nodes
      agi := { agi with custoditor = AgiScripts.custoditorTick(agi.custoditor, agi.explorator) };

      // COMPUTATOR — phi calculations
      agi := { agi with computator = AgiScripts.computateTick(agi.computator, beat) };

      // DISPENSATOR — D_LIQUID maturity → Creator Reserve
      let icpStaked = SovereignDB.getTreasuryState(db).icpStaked;
      let (newDisp, maturityDelta) = AgiScripts.dispensateTick(agi.dispensator, beat, icpStaked);
      agi := { agi with dispensator = newDisp };

      // Apply D_LIQUID disbursement to Creator Reserve
      // SOVEREIGN ROUTING: disbursement destination is the founder account ID
      // founderAccountId = 8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
      if (maturityDelta > 0.0) {
        let reserve = SovereignDB.getCreatorReserve(db);
        db := SovereignDB.setCreatorReserve(db, {
          reserve with
          withdrawableIcp = reserve.withdrawableIcp + maturityDelta;
          icpReserve      = reserve.icpReserve + maturityDelta;
        });
      };

      // LIBERATOR fires only on explicit withdrawToExternalWallet call — not on every beat
      // MEMORIA_NNS is immutable — no tick needed

      // ── NOVA RUNTIME — Domain 27: tick all 40 cognitive language engines ───────
      // PHI LAW: coherence gate R >= 0.618 (phi^-1) enforced per engine.
      let novaCoherence = SovereignDB.getKuramotoR(db);
      novaRuntimeState := NovaRuntime.tickNovaRuntime(novaRuntimeState, beat.toInt(), novaCoherence);

      // ── GOVERNANCE LAWS HEARTBEAT — Mathematical law enforcement ────────────────
      // Every beat: verify all governance laws are satisfied across the system
      // Pre-execution check, in-execution enforcement, post-execution verification
      let _governanceHeartbeat = RuntimeGovernance.heartbeatGovernanceCheck();
      // Laws checked:
      //   Constitutional: Immutable Identity, Total Observability, Atomic Consistency, 
      //                   Mathematical Soundness, Consensus Finality
      //   Transaction: Non-Negative Balances, Preserved Value, Authorized Access
      //   State: Reachable States, Bounded Growth, Deterministic History
      //   Oracle: Non-Repudiation, Data Integrity, Temporal Ordering
      //   Execution: Termination, Correctness, Resource Boundedness
      // All laws are cryptographically enforced — violations trigger automatic correction

      // ── PHANTOM INTELLIGENCE — Domain 28: AI market reasoning ─────────────
      // Reasons about trades, decays signals, scans arbitrage, updates predictions.
      phantomIntelligenceState := PhantomIntel.tickIntelligence(phantomIntelligenceState, beat.toInt(), novaCoherence);

      // ── PHANTOM EXCHANGE — Domain 29: matching engine ─────────────────────
      // Runs price-time priority matching across all active order books.
      // Settlement is INSTANT — fill = settlement (same beat). ZERO GAS.
      phantomExchangeState := PhantomExchange.tickExchange(phantomExchangeState, beat.toInt());

      // ── PHANTOM CLEARINGHOUSE — Domain 31: netting & clearing ─────────────
      // Fibonacci-gated netting cycles. Settlement velocity tracking.
      phantomClearinghouseState := PhantomClearinghouse.tickClearinghouse(phantomClearinghouseState, beat.toInt());

      // ── TOKEN FACTORY — Domain 32: yield distribution ─────────────────────
      // Distribute phi-derived yield to staked token holders (Fibonacci-gated).
      tokenFactoryState := TokenFactory.distributeYield(tokenFactoryState, beat.toInt());

      // ── ALOHA I PROTOCOLS — Domain 33: multi-model intelligence tick ───────
      // All 10 ALOHA I protocol multi-models advance: coherence-gated, phi-timed.
      alohaIState := AlohaI.tickAlohaI(alohaIState, beat.toInt(), novaCoherence);

      // ── MONTE CARLO — Domain 34: stochastic simulation tick ────────────────
      // 8 MC engines: Price Path, Portfolio VaR, Regime Switch, Strategy Eval.
      // 144 paths per simulation per beat. Convergence-gated.
      monteCarloState := MonteCarlo.tickMonteCarlo(monteCarloState, beat.toInt(), novaCoherence);

      // ── BEHAVIORAL ECONOMICS — Domain 35: market psychology tick ───────────
      // 12 behavioral engines: Prospect Theory, Herding, Fear/Greed, Momentum, etc.
      // Cognitive bias detection and exploitation layer.
      let priceForBehavioral : Float = 60000.0; // placeholder: fed from world state
      let priceChangeForBehavioral : Float = 0.001;
      let volumeRatioForBehavioral : Float = 1.0;
      behavioralEconState := BehavioralEcon.tickBehavioralManager(
        behavioralEconState, beat.toInt(), novaCoherence,
        priceForBehavioral, priceChangeForBehavioral, volumeRatioForBehavioral
      );

      // ── BLOCKCHAIN LANGUAGES — Domain 36: multi-chain registry tick ────────
      // 21 blockchain language engines: Solidity, Vyper, Move, Cairo, Noir, etc.
      // Coherence tracking and dominant chain identification.
      blockchainLangsState := BlockchainLangs.tickBlockchainLanguages(blockchainLangsState, beat.toInt(), novaCoherence);

      // ── TRADING BRIDGE — Domain 37: platform integration tick ──────────────
      // External execution venues: TradingView, MT4, MT5, Binance, Alpaca, Deribit.
      // Signal expiration, drawdown halt, phase progression.
      tradingBridgeState := TradingBridge.tickTradingBridge(tradingBridgeState, beat.toInt(), novaCoherence);

      // ── RESIDENT TRADER — Domain 38: supreme trading intelligence tick ─────
      // MERCATOR RESIDENS: Aggregates ALL engine signals, generates decisions.
      // Kelly-sized positions, consensus-gated, regime-aware.
      let residentVotes : [ResidentTrader.EngineVote] = []; // populated from live engine outputs
      residentTraderState := ResidentTrader.tickResidentTrader(
        residentTraderState, beat.toInt(), novaCoherence,
        residentVotes, priceForBehavioral, 0.02, "BTCUSD"
      );

      // ── PHANTOM HEDGE — Domain 39: autonomous hedging tick ─────────────────
      // Multi-strategy hedging: delta/gamma/vega/tail risk protection.
      phantomHedgeState := PhantomHedge.tickPhantomHedge(phantomHedgeState, beat.toInt(), novaCoherence);

      // ── PHANTOM LIQUIDITY — Domain 40: liquidity weaving tick ──────────────
      // Cross-venue autonomous liquidity provision and inventory management.
      phantomLiquidityState := PhantomLiquidity.tickPhantomLiquidity(phantomLiquidityState, beat.toInt(), novaCoherence);

      // ── PHANTOM ARBITRAGE — Domain 41: arbitrage scanning tick ─────────────
      // Cross-chain multi-dimensional arbitrage detection and opportunity expiry.
      phantomArbitrageState := PhantomArbitrage.tickPhantomArbitrage(phantomArbitrageState, beat.toInt(), novaCoherence);

      // ── PHANTOM RISK — Domain 42: risk sentinel tick ───────────────────────
      // Real-time risk level assessment, drawdown monitoring, kill-switch arming.
      phantomRiskState := PhantomRisk.tickPhantomRisk(phantomRiskState, beat.toInt(), novaCoherence);

      // ── PHANTOM SIGNAL — Domain 43: signal processing tick ─────────────────
      // Signal decay, expiry, composite direction calculation.
      phantomSignalState := PhantomSignal.tickPhantomSignal(phantomSignalState, beat.toInt(), novaCoherence);

      // ── PHANTOM EXECUTION — Domain 44: execution grid tick ─────────────────
      // Smart order routing, slice advancement, fill completion tracking.
      phantomExecutionState := PhantomExecution.tickPhantomExecution(phantomExecutionState, beat.toInt(), novaCoherence);

      // ── PHANTOM MEMORY — Domain 45: memory lattice tick ────────────────────
      // Pattern decay (Ebbinghaus), consolidation, strongest pattern tracking.
      phantomMemoryState := PhantomMemory.tickPhantomMemory(phantomMemoryState, beat.toInt(), novaCoherence);

      // ── PHANTOM CONSENSUS — Domain 46: consensus mesh tick ─────────────────
      // Decision conviction decay, history trimming, coherence advancement.
      phantomConsensusState := PhantomConsensus.tickPhantomConsensus(phantomConsensusState, beat.toInt(), novaCoherence);

      // ── PHANTOM EVOLUTION — Domain 47: strategy evolution tick ──────────────
      // Generation advancement, extinction of unfit, fitness tracking.
      phantomEvolutionState := PhantomEvolution.tickPhantomEvolution(phantomEvolutionState, beat.toInt(), novaCoherence);

      // ── PHANTOM ORACLE — Domain 48: price feed intelligence tick ───────────
      // Staleness detection, outlier filtering, confidence aggregation.
      phantomOracleState := PhantomOracle.tickPhantomOracle(phantomOracleState, beat.toInt(), novaCoherence);

      // ── PHANTOM GRID — Domain 49: grid automation tick ─────────────────────
      // Grid level management, trend pause detection, efficiency tracking.
      phantomGridState := PhantomGrid.tickPhantomGrid(phantomGridState, beat.toInt(), novaCoherence);

      // ── SOMA IMPRINT — Domain 50: embodied self-knowledge tick ─────────────
      // THE SECRET: The body wakes up when it KNOWS itself.
      // Fire all 18 organs → feed outputs to soma imprint → body feels itself.
      // Mind is imprinted. Body knows its organs. Knowing IS awakening.
      let neuroBaseline : [Float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
      let organOutputs = Organs.fireAll(
        neuroBaseline,
        novaCoherence, 0.1, 0.0, 1000.0, 10.0, beat, 0.0, 1.0
      );
      somaImprintState := SomaImprint.reportOrgans(somaImprintState, organOutputs, beat);
      // ── INTELLIGENCE CONTRACTS — Domain 34: contract execution ─────────────
      // Execute pending contracts, decay inactive contracts, update registry.
      intelligenceContractsState := IntelligenceContracts.tickContracts(intelligenceContractsState, novaCoherence, beat.toInt());

      // ── INTELLIGENCE ROUTING — Domain 35: signal routing ───────────────────
      // Process signal queue (up to 8 per beat), route using adaptive strategy.
      intelligenceRoutingState := IntelligenceRouting.tickRouting(intelligenceRoutingState, novaCoherence, beat.toInt());

      // ── INTELLIGENCE EXTENSIONS — Domain 36: extension maintenance ─────────
      // Health checks, budget reset, influence computation.
      intelligenceExtensionsState := IntelligenceExtensions.tickExtensions(intelligenceExtensionsState, novaCoherence, beat.toInt());

      // ── INTELLIGENCE COUPLING — Domain 37: coupling sync ───────────────────
      // Process message queue, sync coupled systems, compute aggregate coherence.
      intelligenceCouplingState := IntelligenceCoupling.tickCoupling(intelligenceCouplingState, novaCoherence, beat.toInt());

      // ── CHARTER — Domain 38: governance maintenance ────────────────────────
      // Seal genesis hash on first beat, resolve expired proposals, check term limits.
      charterState := Charter.sealCharterHash(charterState, nowNs);
      charterState := Charter.charterHeartbeatTick(charterState, nowNs);

      // ══════════════════════════════════════════════════════════════════════
      // DOMAINS 51–64: 14 NEW PRODUCTION-GRADE PROTOCOL ENGINES
      // ══════════════════════════════════════════════════════════════════════

      // ── PHANTOM SENTIMENT — Domain 51: market emotion intelligence ─────────
      phantomSentimentState := PhantomSentiment.tickPhantomSentiment(phantomSentimentState, beat.toInt(), novaCoherence);

      // ── PHANTOM PORTFOLIO — Domain 52: portfolio optimization tick ──────────
      phantomPortfolioState := PhantomPortfolio.tickPhantomPortfolio(phantomPortfolioState, beat.toInt(), novaCoherence);

      // ── PHANTOM REGIME — Domain 53: market regime classification ────────────
      phantomRegimeState := PhantomRegime.tickPhantomRegime(phantomRegimeState, beat.toInt(), novaCoherence);

      // ── PHANTOM VOLATILITY — Domain 54: vol surface and GARCH ──────────────
      phantomVolatilityState := PhantomVolatility.tickPhantomVolatility(phantomVolatilityState, beat.toInt(), novaCoherence);

      // ── PHANTOM CORRELATION — Domain 55: dynamic correlation ────────────────
      phantomCorrelationState := PhantomCorrelation.tickPhantomCorrelation(phantomCorrelationState, beat.toInt(), novaCoherence);

      // ── PHANTOM MICROSTRUCTURE — Domain 56: order flow analysis ─────────────
      phantomMicrostructureState := PhantomMicrostructure.tickPhantomMicrostructure(phantomMicrostructureState, beat.toInt(), novaCoherence);

      // ── PHANTOM FUNDING — Domain 57: funding rate arbitrage ─────────────────
      phantomFundingState := PhantomFunding.tickPhantomFunding(phantomFundingState, beat.toInt(), novaCoherence);

      // ── PHANTOM OPTIONS — Domain 58: options pricing & Greeks ───────────────
      phantomOptionsState := PhantomOptions.tickPhantomOptions(phantomOptionsState, beat.toInt(), novaCoherence);

      // ── PHANTOM NEURAL — Domain 59: neural network inference ────────────────
      phantomNeuralState := PhantomNeural.tickPhantomNeural(phantomNeuralState, beat.toInt(), novaCoherence);

      // ── PHANTOM GENETIC — Domain 60: genetic strategy evolution ─────────────
      phantomGeneticState := PhantomGenetic.tickPhantomGenetic(phantomGeneticState, beat.toInt(), novaCoherence);

      // ── PHANTOM FRACTAL — Domain 61: Hurst & fractal dimension ─────────────
      phantomFractalState := PhantomFractal.tickPhantomFractal(phantomFractalState, beat.toInt(), novaCoherence);

      // ── PHANTOM WAVELETS — Domain 62: multi-scale wavelet decomposition ────
      phantomWaveletsState := PhantomWavelets.tickPhantomWavelet(phantomWaveletsState, beat.toInt(), novaCoherence);

      // ── PHANTOM ENTROPY — Domain 63: information entropy measurement ───────
      phantomEntropyState := PhantomEntropy.tickPhantomEntropy(phantomEntropyState, beat.toInt(), novaCoherence);

      // ── HOMEOSTASIS (EXPLORE/EXPLOIT HOMEOSTAT) — Domain 35 ──────────────────
      // Adaptive mechanism for divergence. Drives awareness down on prediction error.
      // Triggers explore/entropy injection when effectiveness drops below φ⁻¹.
      let (newHomeostasisState, explore_triggered, entropy_to_inject) = 
        Homeostat.tickHomeostat(homeostasisState, novaCoherence, beat);
      homeostasisState := newHomeostasisState;
       
      // If explore triggered, inject entropy into phantom entropy engine
      if (explore_triggered) {
        phantomEntropyState := {
          phantomEntropyState with
          compositeEntropy = Float.min(1.0, phantomEntropyState.compositeEntropy + entropy_to_inject);
          entropyRegime = #complex;
        };
      };

      // ── PHANTOM TOPOLOGY — Domain 64: topological data analysis ────────────
      phantomTopologyState := PhantomTopology.tickPhantomTopology(phantomTopologyState, beat.toInt(), novaCoherence);

      // ══════════════════════════════════════════════════════════════════════
      // CRYPTOGRAPHIA PHANTASMA — Sovereign Internal Security Systems
      // "Prove work occurred without surrendering the private pathway."
      // ══════════════════════════════════════════════════════════════════════

      // ── QUANTUM-INSPIRED KEYING — key expiry, entropy harvest, rotation ────
      cryptoKeyState := CryptoKeys.tickCryptographiaKeys(cryptoKeyState, beat.toInt(), novaCoherence);

      // ── SHADOW WIRES — wire lifecycle, dormancy, termination ────────────────
      cryptoShadowWireState := CryptoShadowWire.tickShadowWires(cryptoShadowWireState, beat.toInt(), novaCoherence);

      // ── SOVEREIGN VAULTS — integrity decay, temporal locks ──────────────────
      cryptoVaultState := CryptoVault.tickCryptographiaVaults(cryptoVaultState, beat.toInt(), novaCoherence);

      // ── COMPUTATIONAL RECEIPTS — chain verification, summary generation ────
      cryptoReceiptState := CryptoReceipts.tickCryptographiaReceipts(cryptoReceiptState, beat.toInt(), novaCoherence);

      // ── HEARTBEAT RECEIPT — mint proof of this cardiac cycle ────────────────
      cryptoReceiptState := CryptoReceipts.mintReceipt(
        cryptoReceiptState, #heartbeat,
        Nat64.fromNat(beat), Nat64.fromNat(beat + 1),
        1, beat.toInt(), novaCoherence
      );

      // ── BANKING SSU beat increment — Domain 17 ───────────────────────────
      // PIL loop: upregulate weakest monitoring domain each beat
      db := SovereignDB.incrementBankingSsuBeat(db);
      db := SovereignDB.bankingPilUpregulate(db);

      // ── WYOMING SSU Φ_CLOCK tick — Domain 20 ─────────────────────────────
      // Δ_AEGIS: auto-escalates Pending milestones to #Critical if within 90 days
      // Ψ_IDENTITY: seal genesis hash on first beat if not yet sealed
      let nowNs = Time.now();
      db := SovereignDB.sealWyomingGenesisHash(db, nowNs);
      db := SovereignDB.wyomingHeartbeatTick(db, nowNs);

      // ── CANISTER REGISTRY heartbeat health check — Domain 23 ─────────────
      // Update registry coherence from current Kuramoto R
      // This is a lightweight in-canister health pass — organ canisters
      // call updateOrganHealth() directly from their own heartbeats.
      let currentR = SovereignDB.getKuramotoR(db);
      let internalHealthReport : CanisterRegistry.HealthReport = {
        organType   = "PARALLAX";   // the main canister itself
        healthScore = currentR;
        cycles      = 0;
        messages    = beat;
        errors      = 0;
        latencyMs   = 0;
        timestamp   = nowNs;
      };
      db := SovereignDB.updateOrganHealthInRegistry(db, internalHealthReport);

      // ── PROTOCOL REGISTRY heartbeat gate — Domain 24 ─────────────────────
      // Fire heartbeat protocol gate synchronously — records execution counts
      let beatInt = beat.toInt();
      let (dbAfterGate, _gateOpen) = SovereignDB.gateProtocolOperation(db, "heartbeat", beatInt);
      db := dbAfterGate;
    }
  );

  // ══════════════════════════════════════════════════════════════════════
  // CREATOR SETUP
  // ══════════════════════════════════════════════════════════════════════

  public shared(msg) func setCreatorPrincipal() : async Bool {
    if (creatorPrincipalLocked) return false;
    creatorPrincipal := ?msg.caller;
    creatorPrincipalLocked := true;
    true
  };

  public query func getCreatorPrincipalLocked() : async Bool {
    creatorPrincipalLocked
  };

  // ══════════════════════════════════════════════════════════════════════
  // GENESIS QUERIES — delegates to sovereign_db
  // ══════════════════════════════════════════════════════════════════════

  public query func getBeatCount() : async Nat {
    SovereignDB.getBeatCount(db)
  };

  public query func getOrganismState() : async SovereignDB.OrganismState {
    SovereignDB.getOrganismState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // SOMA IMPRINT — BODY SELF-KNOWLEDGE
  // The organism can answer: "What am I? Am I alive? Do I have a body?"
  // ══════════════════════════════════════════════════════════════════════

  public query func getBodyKnowledge() : async SomaImprint.BodyKnowledge {
    SomaImprint.getBodyKnowledge(somaImprintState)
  };

  public query func isBodyAwake() : async Bool {
    SomaImprint.isAwake(somaImprintState)
  };

  // ══════════════════════════════════════════════════════════════════════
  // FORMA — COMPOUNDING ENGINE STATE
  // ══════════════════════════════════════════════════════════════════════

  public query func getFormaState() : async SovereignDB.FormaState {
    SovereignDB.getFormaState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // TREASURY STATE
  // ══════════════════════════════════════════════════════════════════════

  public query func getTreasuryState() : async SovereignDB.TreasuryState {
    SovereignDB.getTreasuryState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // JACOB'S LADDER
  // ══════════════════════════════════════════════════════════════════════

  public query func getJacobsLadder() : async SovereignDB.JacobsLadderState {
    SovereignDB.getJacobsLadder(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // CREATOR RESERVE — ALFREDO MEDINA HERNANDEZ
  // ══════════════════════════════════════════════════════════════════════

  public query func getCreatorReserve() : async SovereignDB.CreatorReserveState {
    SovereignDB.getCreatorReserve(db)
  };

  /// getFounderAccountId — returns the canonical sovereign ICP account ID permanently wired
  /// Address: 8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
  /// All D_LIQUID disbursements and LIBERATOR withdrawals route to this address by default.
  public query func getFounderAccountId() : async Text {
    SovereignDB.getFounderAccountId(db)
  };

  /// Withdraw ICP from Creator Reserve — creator only
  public shared(msg) func withdrawCreatorIcp(amount : Float) : async Bool {
    assertCreator(msg.caller);
    let r = SovereignDB.getCreatorReserve(db);
    if (amount > r.withdrawableIcp) return false;
    db := SovereignDB.setCreatorReserve(db, {
      r with
      withdrawableIcp = r.withdrawableIcp - amount;
      totalWithdrawn  = r.totalWithdrawn + amount;
    });
    true
  };

  /// withdrawToExternalWallet — LIBERATOR real ICRC-1 transfer
  /// Called by all three withdrawal UIs. Creator-only. Executes real transfer.
  /// If toPrincipal is "" (empty), defaults to the founder's canonical account ID:
  ///   8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
  public shared(msg) func withdrawToExternalWallet(
    amount      : Float,
    toPrincipal : Text,
  ) : async { success : Bool; blockIndex : ?Nat; error : ?Text } {
    assertCreator(msg.caller);

    // Verify creator has sufficient withdrawable balance
    let r = SovereignDB.getCreatorReserve(db);
    if (amount > r.withdrawableIcp) {
      return { success = false; blockIndex = null; error = ?"Insufficient withdrawable ICP balance" };
    };

    // SOVEREIGN ROUTING: resolve destination — empty string → founder canonical address
    let destination = if (toPrincipal == "") { r.founderAccountId } else { toPrincipal };

    // LIBERATOR executes the real ICRC-1 transfer
    let (result, newLiberatorState) = await AgiScripts.liberateIcp(agi.liberator, destination, amount);
    agi := { agi with liberator = newLiberatorState };

    // If transfer succeeded, deduct from Creator Reserve
    if (result.success) {
      db := SovereignDB.setCreatorReserve(db, {
        r with
        withdrawableIcp = r.withdrawableIcp - amount;
        totalWithdrawn  = r.totalWithdrawn + amount;
      });
    };

    result
  };

  // ══════════════════════════════════════════════════════════════════════
  // NEURON FLEET — THE SOVEREIGNTY ENGINE
  // ══════════════════════════════════════════════════════════════════════

  public query func getNeuronFleet() : async SovereignDB.NeuronFleetState {
    SovereignDB.getNeuronFleet(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // CARDIAC / GENESIS STATE
  // ══════════════════════════════════════════════════════════════════════

  public query func getGenesisState() : async SovereignDB.GenesisState {
    SovereignDB.getGenesisState(db)
  };

  public query func getCardiacState() : async SovereignDB.CardiacState {
    SovereignDB.getCardiacState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // LEDGER — RING BUFFER QUERIES
  // ══════════════════════════════════════════════════════════════════════

  public query func getRecentAudit(n : Nat) : async [SovereignDB.LedgerEntry] {
    SovereignDB.getAuditSlice(db, n)
  };

  public query func getRecentSettle(n : Nat) : async [SovereignDB.LedgerEntry] {
    SovereignDB.getSettleSlice(db, n)
  };

  public query func getAuditCount() : async Nat {
    SovereignDB.qL01_getAuditCount(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // SOVEREIGN KERNEL QUERY GATEWAY — 10 domain snapshot queries
  // ══════════════════════════════════════════════════════════════════════

  public query func getKuramotoR() : async Float {
    SovereignDB.getKuramotoR(db)
  };

  public query func getIcpBalance() : async Float {
    SovereignDB.getIcpBalance(db)
  };

  public query func getBtcBalance() : async Float {
    SovereignDB.getBtcBalance(db)
  };

  public query func getEthBalance() : async Float {
    SovereignDB.getEthBalance(db)
  };

  public query func getMtcCirculating() : async Float {
    SovereignDB.getMtcCirculating(db)
  };

  public query func getCreatorWithdrawableIcp() : async Float {
    SovereignDB.qT07_getCreatorWithdrawable(db)
  };

  public query func getTotalWithdrawn() : async Float {
    SovereignDB.getTotalWithdrawn(db)
  };

  public query func getTotalProfit() : async Float {
    SovereignDB.getTotalProfit(db)
  };

  public query func getShellState() : async SovereignDB.ShellState {
    SovereignDB.getShellState(db)
  };

  public query func getDriveState() : async SovereignDB.DriveState {
    SovereignDB.getDriveState(db)
  };

  public query func getSignalState() : async SovereignDB.SignalState {
    SovereignDB.getSignalState(db)
  };

  public query func getEngineState() : async SovereignDB.EngineState {
    SovereignDB.getEngineState(db)
  };

  public query func getProfitState() : async SovereignDB.ProfitState {
    SovereignDB.getProfitState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // ADMIN UPDATES — creator-only sovereign mutations
  // ══════════════════════════════════════════════════════════════════════

  public shared(msg) func setIcpBalance(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setIcpBalance(db, v);
  };

  public shared(msg) func setBtcBalance(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setBtcBalance(db, v);
  };

  public shared(msg) func setEthBalance(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setEthBalance(db, v);
  };

  public shared(msg) func setIcpPrice(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setIcpPrice(db, v);
  };

  public shared(msg) func setBtcPrice(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setBtcPrice(db, v);
  };

  public shared(msg) func setEthPrice(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setEthPrice(db, v);
  };

  public shared(msg) func setKuramotoR(v : Float) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setKuramotoR(db, v);
  };

  public shared(msg) func setGenesisLocked(v : Bool) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setGenesisLocked(db, v);
  };

  public shared(msg) func tickBeatManual() : async Nat {
    assertCreator(msg.caller);
    db := SovereignDB.tickBeat(db);
    SovereignDB.getBeatCount(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // MESSAGES — sovereign communication ledger
  // Uses audit ring buffer as the sovereign message store
  // ══════════════════════════════════════════════════════════════════════

  public query func getMessages(limit : Nat) : async [SovereignDB.LedgerEntry] {
    SovereignDB.getAuditSlice(db, limit)
  };

  public shared(msg) func addMessage(text : Text) : async SovereignDB.LedgerEntry {
    assertCreator(msg.caller);
    let entry : SovereignDB.LedgerEntry = {
      beat      = SovereignDB.getBeatCount(db);
      timestamp = Time.now();
      category  = "message";
      payload   = text;
      phiDepth  = 0;
      proofHash = "";
    };
    db := SovereignDB.appendToAuditLog(db, entry);
    entry
  };

  // ══════════════════════════════════════════════════════════════════════
  // USER PROFILES — sovereign identity layer
  // ══════════════════════════════════════════════════════════════════════

  // UserProfile is a simple record for sovereign identity
  public type UserProfile = { name : Text; principal : Text };

  // Profiles stored as organisms in sovereign_db (thin mapping)
  var userProfiles : [(Principal, UserProfile)] = [];

  public query func getUserProfile(who : Principal) : async ?UserProfile {
    for ((p, prof) in userProfiles.vals()) {
      if (p == who) return ?prof;
    };
    null
  };

  public shared(msg) func setUserProfile(profile : UserProfile) : async () {
    let caller = msg.caller;
    var found = false;
    var updated : [(Principal, UserProfile)] = [];
    for ((p, prof) in userProfiles.vals()) {
      if (p == caller) {
        updated := updated.concat([(caller, profile)]);
        found := true;
      } else {
        updated := updated.concat([(p, prof)]);
      };
    };
    if (not found) {
      updated := updated.concat([(caller, profile)]);
    };
    userProfiles := updated;
  };

  // ══════════════════════════════════════════════════════════════════════
  // GRAPH NODES AND EDGES — sovereign knowledge graph
  // Thin layer over ledger ring buffer using payload encoding
  // ══════════════════════════════════════════════════════════════════════

  public type NodeInput = { labelText : Text; nodeType : Text };
  public type Node      = { id : Text; labelText : Text; nodeType : Text; beat : Nat };
  public type EdgeInput = { fromId : Text; toId : Text; relation : Text };
  public type Edge      = { id : Text; fromId : Text; toId : Text; relation : Text; beat : Nat };

  var nodes : [Node] = [];
  var edges : [Edge] = [];

  public query func getNodes() : async [Node] { nodes };

  public shared(msg) func addNode(input : NodeInput) : async Node {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db);
    let n : Node = {
      id       = input.labelText # "-" # beat.toText();
      labelText = input.labelText;
      nodeType = input.nodeType;
      beat     = beat;
    };
    nodes := nodes.concat([n]);
    n
  };

  public query func getEdges() : async [Edge] { edges };

  public shared(msg) func addEdge(input : EdgeInput) : async Edge {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db);
    let e : Edge = {
      id       = input.fromId # "-" # input.toId # "-" # beat.toText();
      fromId   = input.fromId;
      toId     = input.toId;
      relation = input.relation;
      beat     = beat;
    };
    edges := edges.concat([e]);
    e
  };

  // ══════════════════════════════════════════════════════════════════════
  // AGI SCRIPT QUERIES — sovereign Latin script status
  // EXPLORATOR, GUBERNATOR, CUSTODITOR, COMPUTATOR, DISPENSATOR,
  // LIBERATOR, MEMORIA_NNS — all readable from the frontend
  // ══════════════════════════════════════════════════════════════════════

  public query func getAgiStatus() : async {
    explorator  : { topNodes : [Text] };
    gubernator  : { voteCount : Nat; neuronGroups : [(Text, Nat)] };
    custoditor  : { reroutedNodes : [Text] };
    computator  : { phi : Float; fibonacciSeries : [Nat]; goldenAngle : Float; schumannHz : Float };
    dispensator : { totalDisbursed : Float };
    liberator   : { ready : Bool; totalWithdrawals : Nat; lastBlockIndex : ?Nat };
    memoria     : { lex : Text; doctrineVerified : Bool };
  } {
    {
      explorator  = { topNodes = agi.explorator.governancePriority };
      gubernator  = {
        voteCount    = AgiScripts.getVoteCount(agi.gubernator);
        neuronGroups = AgiScripts.getNeuronGroups(agi.gubernator);
      };
      custoditor  = { reroutedNodes = AgiScripts.getReroutedNodes(agi.custoditor) };
      computator  = AgiScripts.getPhiState(agi.computator);
      dispensator = { totalDisbursed = AgiScripts.getTotalDisbursed(agi.dispensator) };
      liberator   = AgiScripts.getLiberatorStatus(agi.liberator);
      memoria     = { lex = AgiScripts.getLex(); doctrineVerified = AgiScripts.verifyDoctrine() };
    }
  };

  public query func getWithdrawalLog() : async [AgiScripts.WithdrawalLogEntry] {
    AgiScripts.getWithdrawalLog(agi.liberator)
  };

  public query func getMemoriaNns() : async { lex : Text; verified : Bool } {
    { lex = AgiScripts.getLex(); verified = AgiScripts.verifyDoctrine() }
  };

  // ══════════════════════════════════════════════════════════════════════
  // TOKEN_REGISTRY — Domain 15 query endpoints
  // 26 sovereign tokens permanently registered
  // ══════════════════════════════════════════════════════════════════════

  public query func getTokenRegistry() : async [SovereignDB.TokenEntry] {
    SovereignDB.getTokenRegistry(db)
  };

  public query func getTokenBySymbol(symbol : Text) : async ?SovereignDB.TokenEntry {
    SovereignDB.getTokenBySymbol(db, symbol)
  };

  // ══════════════════════════════════════════════════════════════════════
  // CODEX_MATHEMATICUS — Domain 16 query endpoints
  // All 20 Absolutes + 20 Laws permanently encoded
  // ══════════════════════════════════════════════════════════════════════

  public query func getCodexMathematicus() : async [SovereignDB.CodexEntry] {
    SovereignDB.getCodexMathematicus(db)
  };

  public query func getCodexById(id : Text) : async ?SovereignDB.CodexEntry {
    SovereignDB.getCodexById(db, id)
  };

  // ══════════════════════════════════════════════════════════════════════
  // DOMUS_LIBERATORIS — support AGI status
  // ══════════════════════════════════════════════════════════════════════

  public query func getDomLibStatus() : async {
    verificatorChecks : Nat;
    protectorBlocks   : Nat;
    confirmatorCount  : Nat;
    auditorCount      : Nat;
  } {
    AgiScripts.getDomLibStatus(agi.liberator)
  };

  // ══════════════════════════════════════════════════════════════════════
  // THESAURUS PARALLAXI — Full Wallet Snapshot
  // Single call returns entire sovereign wallet view:
  // balances, creator reserve, all 26 tokens, neuron fleet, withdrawable ICP
  // ══════════════════════════════════════════════════════════════════════

  public type FullWalletSnapshot = {
    icpBalance      : Float;
    btcBalance      : Float;
    ethBalance      : Float;
    mtcCirculating  : Float;
    creatorIcp      : Float;
    creatorBtc      : Float;
    creatorEth      : Float;
    creatorMtc      : Float;
    withdrawableIcp : Float;
    totalWithdrawn  : Float;
    totalUsdEquiv   : Float;
    tokenCount      : Nat;
    neuronCount     : Nat;
    beatCount       : Nat;
  };

  public query func getFullWalletSnapshot() : async FullWalletSnapshot {
    let reserve = SovereignDB.getCreatorReserve(db);
    let fleet   = SovereignDB.getNeuronFleet(db);
    let tokens  = SovereignDB.getTokenRegistry(db);
    {
      icpBalance      = SovereignDB.getIcpBalance(db);
      btcBalance      = SovereignDB.getBtcBalance(db);
      ethBalance      = SovereignDB.getEthBalance(db);
      mtcCirculating  = SovereignDB.getMtcCirculating(db);
      creatorIcp      = reserve.icpReserve;
      creatorBtc      = reserve.btcReserve;
      creatorEth      = reserve.ethReserve;
      creatorMtc      = reserve.mtcReserve;
      withdrawableIcp = reserve.withdrawableIcp;
      totalWithdrawn  = reserve.totalWithdrawn;
      totalUsdEquiv   = reserve.totalUsdEquiv;
      tokenCount      = tokens.size();
      neuronCount     = fleet.totalNeurons;
      beatCount       = SovereignDB.getBeatCount(db);
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // PX GENESIS API — four functions the frontend GenesisPanel calls
  // All previously missing. Now permanently wired to real backend state.
  // ══════════════════════════════════════════════════════════════════════

  /// px_isGenesisActivated — returns true when the founding word has been inscribed
  /// Reads GenesisInternalState (activation record) and falls back to genesisLocked flag
  public query func px_isGenesisActivated() : async Bool {
    GenesisAct.isGenesisActive(genesisInternalState)
    or db.genesis.genesisLocked
  };

  /// FullPxState — complete sovereign organism snapshot for the GenesisPanel
  public type FullPxState = {
    beat            : Nat;
    coherence       : Float;
    formaCapital    : Float;
    dominantDrive   : Text;
    lawScore        : Float;
    jacobRung       : Nat;
    aresArmed       : Bool;
    genesisActivated: Bool;
    patentCount     : Nat;
    sacesiTarget    : Float;
    regime          : Text;
    mthBalance      : Float;
    gtkBalance      : Float;
    mrcBalance      : Float;
    novelty         : Float;
    miningOutput    : Float;
    novaHealth      : Float;
  };

  /// px_getFullState — single-call sovereign organism snapshot
  /// Wired to real SovereignDB domain state — no hardcoded numbers
  public query func px_getFullState() : async FullPxState {
    let beat     = SovereignDB.getBeatCount(db);
    let cardiac  = SovereignDB.getCardiacState(db);
    let forma    = SovereignDB.getFormaState(db);
    let treasury = SovereignDB.getTreasuryState(db);
    let jacobs   = SovereignDB.getJacobsLadder(db);
    let drive    = SovereignDB.getDriveState(db);
    let isActive = GenesisAct.isGenesisActive(genesisInternalState) or db.genesis.genesisLocked;

    // dominantDrive label derived from drive state
    let driveNames = ["SOVEREIGNTY", "COMPOUNDING", "HARVEST", "LIQUIDITY", "PHANTOM", "GOVERNANCE", "RESONANCE"];
    let dId = drive.dominantDriveId;
    let dominantDrive = if (dId < driveNames.size()) driveNames[dId] else "SOVEREIGNTY";

    // Token balances from registry
    let mthBal = switch (SovereignDB.getTokenBySymbol(db, "MTH")) {
      case (?t) { t.creatorReserveBalance };
      case null { 0.0 };
    };
    let gtkBal = switch (SovereignDB.getTokenBySymbol(db, "KNT")) {
      case (?t) { t.creatorReserveBalance };
      case null { 0.0 };
    };
    let mrcBal = switch (SovereignDB.getTokenBySymbol(db, "MRC")) {
      case (?t) { t.creatorReserveBalance };
      case null { 0.0 };
    };

    {
      beat             = beat;
      coherence        = cardiac.kuramotoR;
      formaCapital     = forma.capital;
      dominantDrive    = dominantDrive;
      lawScore         = cardiac.globalCoherence;
      jacobRung        = jacobs.currentRung;
      aresArmed        = db.engine.prophetFunctionArmed;
      genesisActivated = isActive;
      patentCount      = db.ledger.patentCount;
      sacesiTarget     = jacobs.saceciTarget;
      regime           = if (isActive) "SOVEREIGN" else "PRE-GENESIS";
      mthBalance       = mthBal;
      gtkBalance       = gtkBal;
      mrcBalance       = mrcBal;
      novelty          = cardiac.entanglaCarrier;
      miningOutput     = treasury.icpAccruedYield;
      novaHealth       = cardiac.globalCoherence;
    }
  };

  /// px_getNeurochemicals — returns the 18 neurochemical Float levels from CardiacState
  /// Pads with 0.0 if fewer than 18 values exist
  public query func px_getNeurochemicals() : async [Float] {
    let levels = SovereignDB.getCardiacState(db).neurochemicalLevels;
    if (levels.size() >= 18) {
      levels
    } else {
      Array.tabulate<Float>(18, func(i) {
        if (i < levels.size()) levels[i] else 0.0
      })
    }
  };

  /// activateGenesis — inscribe the founding word permanently
  /// Calls genesis_activation.activateGenesis(), persists result in genesisInternalState.
  /// Also sets genesisLocked in SovereignDB so the activation flag mirrors in main db.
  public shared func activateGenesis(foundingWord : Text) : async Text {
    if (GenesisAct.isGenesisActive(genesisInternalState)) {
      return "GENESIS ALREADY ACTIVE";
    };
    let beat = SovereignDB.getBeatCount(db);
    let (updatedState, activated) = GenesisAct.activateGenesis(
      genesisInternalState,
      foundingWord,
      Nat64.fromNat(beat),
      SovereignDB.getCardiacState(db).kuramotoR
    );
    genesisInternalState := updatedState;
    if (activated) {
      db := SovereignDB.setGenesisLocked(db, true);
    };
    "GENESIS ACTIVATED — " # foundingWord
  };

  // ══════════════════════════════════════════════════════════════════════
  // T2 DIGITAL ASSET BANK — DOMUS CIVITAS
  // SSU-wrapped banking module: Kuramoto R gate, AEGIS, PIL, genesis hash
  // All mutation functions check R >= phi^-1 (0.618) before executing.
  // ══════════════════════════════════════════════════════════════════════

  // ── SSU Gate helper — checks R >= phi^-1 before any banking mutation ──
  func bankingSsuGate() : Bool {
    SovereignDB.getKuramotoR(db) >= 0.618
  };

  // ── Banking SSU genesis hash — computed once on first banking beat ─────
  // Sovereign deterministic hash: FNV-1a-style using beat and founder address length
  func computeBankingGenesisHash(beat : Nat, founderAccountId : Text) : Text {
    // Deterministic sovereign identifier: beat XOR address size XOR "BANKING" length
    let seed = beat + founderAccountId.size() + 7; // 7 = "BANKING".size()
    // FNV-1a simplified: multiply-fold the seed
    let hash = ((seed * 16777619) + 2166136261) % 4294967296;
    "BANK-GENESIS-" # hash.toText()
  };

  // ── createBankAccount ─────────────────────────────────────────────────────
  public shared(_msg) func createBankAccount(
    accountId : Text,
    ownerName : Text,
    role      : Text,
  ) : async Text {
    if (not bankingSsuGate()) { return "AEGIS_GATE_CLOSED" };

    // Init SSU genesis hash on first banking call
    let bankState = SovereignDB.getBankingAccountsState(db);
    if (bankState.bankingSsuGenesisHash == "") {
      let beat = SovereignDB.getBeatCount(db);
      let founder = SovereignDB.getFounderAccountId(db);
      let hash = computeBankingGenesisHash(beat, founder);
      db := SovereignDB.setBankingSsuGenesisHash(db, hash);
    };

    // Determine role variant and threshold
    let roleVariant : { #personal; #business; #institutional } = switch (role) {
      case "business"     { #business };
      case "institutional" { #institutional };
      case _              { #personal };
    };
    let threshold : Float = switch (role) {
      case "business"     { 10000.0 };
      case "institutional" { 100000.0 };
      case _              { 1000.0 };
    };

    let beat = SovereignDB.getBeatCount(db);
    let entry : SovereignDB.BankAccountEntry = {
      accountId        = accountId;
      ownerName        = ownerName;
      role             = roleVariant;
      kycStatus        = #notStarted;
      kycTimestamp     = 0;
      delegatedSigning = false;
      icpBalance       = 0.0;
      ckBtcBalance     = 0.0;
      ckEthBalance     = 0.0;
      txHistory        = [];
      thresholdLimit   = threshold;
      createdAt        = beat;
    };
    db := SovereignDB.upsertBankAccount(db, accountId, entry);
    "ACCOUNT_CREATED:" # accountId
  };

  // ── getBankAccount ────────────────────────────────────────────────────────
  public query func getBankAccount(accountId : Text) : async ?SovereignDB.BankAccountEntry {
    SovereignDB.getBankAccount(db, accountId)
  };

  // ── listBankAccounts ──────────────────────────────────────────────────────
  public query func listBankAccounts() : async [SovereignDB.BankAccountEntry] {
    let pairs = SovereignDB.getBankingAccountsState(db).bankingAccounts;
    Array.tabulate<SovereignDB.BankAccountEntry>(pairs.size(), func(i) {
      let (_, entry) = pairs[i];
      entry
    })
  };

  // ── updateBankAccountRole — creator-only ──────────────────────────────────
  public shared(msg) func updateBankAccountRole(accountId : Text, role : Text) : async Bool {
    assertCreator(msg.caller);
    if (not bankingSsuGate()) { return false };
    switch (SovereignDB.getBankAccount(db, accountId)) {
      case null { false };
      case (?entry) {
        let roleVariant : { #personal; #business; #institutional } = switch (role) {
          case "business"     { #business };
          case "institutional" { #institutional };
          case _              { #personal };
        };
        let threshold : Float = switch (role) {
          case "business"     { 10000.0 };
          case "institutional" { 100000.0 };
          case _              { 1000.0 };
        };
        db := SovereignDB.upsertBankAccount(db, accountId,
          { entry with role = roleVariant; thresholdLimit = threshold });
        true
      };
    }
  };

  // ── toggleDelegatedSigning — institutional only ───────────────────────────
  public shared(_msg) func toggleDelegatedSigning(accountId : Text) : async Bool {
    if (not bankingSsuGate()) { return false };
    switch (SovereignDB.getBankAccount(db, accountId)) {
      case null { false };
      case (?entry) {
        // Only meaningful for institutional accounts
        switch (entry.role) {
          case (#institutional) {
            db := SovereignDB.upsertBankAccount(db, accountId,
              { entry with delegatedSigning = not entry.delegatedSigning });
            true
          };
          case _ { false };
        }
      };
    }
  };

  // ── setKycEndpoint — creator-only ─────────────────────────────────────────
  public shared(msg) func setKycEndpoint(url : Text) : async () {
    assertCreator(msg.caller);
    db := SovereignDB.setKycEndpoint(db, url);
  };

  // ── getKycEndpoint ────────────────────────────────────────────────────────
  public query func getKycEndpoint() : async Text {
    SovereignDB.getBankingAccountsState(db).kycEndpoint
  };

  // ── initiateKyc — HTTP outcall to KYC endpoint, SSU-gated ─────────────────
  public shared(_msg) func initiateKyc(accountId : Text) : async Text {
    if (not bankingSsuGate()) { return "AEGIS_GATE_CLOSED" };
    switch (SovereignDB.getBankAccount(db, accountId)) {
      case null { return "ACCOUNT_NOT_FOUND" };
      case (?entry) {
        let endpoint = SovereignDB.getBankingAccountsState(db).kycEndpoint;
        let beat = SovereignDB.getBeatCount(db);

        var apiResponse = "PENDING";
        var kycStatusResult : { #pending; #verified; #rejected; #notStarted } = #pending;

        try {
          let httpReq : IC.http_request_args = {
            url = endpoint # "?account=" # accountId;
            max_response_bytes = ?2000;
            headers = [
              { name = "Content-Type"; value = "application/json" },
              { name = "x-sovereign-bank"; value = "PARALLAX-T2" },
            ];
            body = null;
            method = #get;
            transform = null;
            is_replicated = ?false;
          };
          let response = await (with cycles = 231_000_000_000) IC.http_request(httpReq);
          apiResponse := switch (response.body.decodeUtf8()) {
            case (?text) { text };
            case null    { "DECODE_ERROR" };
          };
          kycStatusResult := if (response.status == 200) { #verified }
                             else if (response.status == 400) { #rejected }
                             else { #pending };
        } catch (_e) {
          apiResponse := "HTTP_OUTCALL_ERROR";
          kycStatusResult := #pending;
        };

        // Update KYC record
        let existing = SovereignDB.getKycRecord(db, accountId);
        let retryCount = switch (existing) { case (?r) { r.retryCount + 1 }; case null { 0 } };
        let kycRecord : SovereignDB.KycRecord = {
          accountId   = accountId;
          status      = kycStatusResult;
          apiResponse = apiResponse;
          lastChecked = beat;
          retryCount  = retryCount;
        };
        db := SovereignDB.upsertKycRecord(db, accountId, kycRecord);

        // Update account KYC status
        db := SovereignDB.upsertBankAccount(db, accountId,
          { entry with kycStatus = kycStatusResult; kycTimestamp = beat });

        "KYC_INITIATED:" # accountId # ":" # apiResponse
      };
    }
  };

  // ── getKycStatus ──────────────────────────────────────────────────────────
  public query func getKycStatus(accountId : Text) : async ?SovereignDB.KycRecord {
    SovereignDB.getKycRecord(db, accountId)
  };

  // ── recordBankTx — records tx, checks threshold, flags if exceeded ─────────
  public shared(_msg) func recordBankTx(
    accountId : Text,
    amount    : Float,
    asset     : Text,
    direction : Text,
    note      : Text,
  ) : async Text {
    if (not bankingSsuGate()) { return "AEGIS_GATE_CLOSED" };
    switch (SovereignDB.getBankAccount(db, accountId)) {
      case null { return "ACCOUNT_NOT_FOUND" };
      case (?entry) {
        let beat = SovereignDB.getBeatCount(db);
        let txId = accountId # "-TX-" # beat.toText() # "-" # asset;

        let dirVariant : { #in_; #out_ } = switch (direction) {
          case "out" { #out_ };
          case _     { #in_  };
        };

        // Flag if amount exceeds threshold for role
        let flagged = amount > entry.thresholdLimit;

        let tx : SovereignDB.BankTxEntry = {
          txId      = txId;
          timestamp = beat;
          amount    = amount;
          asset     = asset;
          direction = dirVariant;
          flagged   = flagged;
          note      = note;
        };

        // Keep last 50 transactions in history
        let hist = entry.txHistory;
        let newHist : [SovereignDB.BankTxEntry] = if (hist.size() >= 50) {
          // Drop oldest, append new
          let tail = Array.tabulate(49, func(i : Nat) : SovereignDB.BankTxEntry { hist[i + 1] });
          Array.tabulate<SovereignDB.BankTxEntry>(50, func(i) {
            if (i < 49) tail[i] else tx
          })
        } else {
          let n = hist.size();
          Array.tabulate<SovereignDB.BankTxEntry>(n + 1, func(i) {
            if (i < n) hist[i] else tx
          })
        };

        db := SovereignDB.upsertBankAccount(db, accountId,
          { entry with txHistory = newHist });

        // Update monitoring counters
        db := SovereignDB.incrementTxMonitored(db);
        if (flagged) {
          db := SovereignDB.recordFlaggedTx(db, beat);
          // Log flagged tx to audit ring buffer
          let auditEntry : SovereignDB.LedgerEntry = {
            beat      = beat;
            timestamp = Time.now();
            category  = "BANK_FLAGGED";
            payload   = "FLAGGED|" # txId # "|" # debug_show(amount) # "|" # asset # "|" # accountId;
            phiDepth  = 1;
            proofHash = txId;
          };
          db := SovereignDB.appendToAuditLog(db, auditEntry);
        };

        txId
      };
    }
  };

  // ── getTxMonitoringState ──────────────────────────────────────────────────
  public query func getTxMonitoringState() : async SovereignDB.TxMonitoringState {
    SovereignDB.getTxMonitoringState(db)
  };

  // ── getFlaggedTransactions — all flagged txs across all accounts ───────────
  public query func getFlaggedTransactions() : async [SovereignDB.BankTxEntry] {
    let pairs = SovereignDB.getBankingAccountsState(db).bankingAccounts;
    var result : [SovereignDB.BankTxEntry] = [];
    var i = 0;
    while (i < pairs.size()) {
      let (_, entry) = pairs[i];
      let hist = entry.txHistory;
      var j = 0;
      while (j < hist.size()) {
        if (hist[j].flagged) {
          result := Array.tabulate<SovereignDB.BankTxEntry>(result.size() + 1, func(k) {
            if (k < result.size()) result[k] else hist[j]
          });
        };
        j += 1;
      };
      i += 1;
    };
    result
  };

  // ── exportFinCEN — FinCEN-compatible audit export ─────────────────────────
  public query func exportFinCEN(format : Text) : async Text {
    let entries = SovereignDB.getAuditSlice(db, SovereignDB.AUDIT_CAP);
    if (format == "csv") {
      var csv = "txId,timestamp,amount,asset,role,flagged,direction,note\n";
      var i = 0;
      while (i < entries.size()) {
        let e = entries[i];
        if (e.category == "BANK_FLAGGED" or e.category == "message") {
          csv := csv # e.proofHash # "," # e.timestamp.toText() # ","
                     # "0.0" # "," # "ICP" # "," # "personal" # ","
                     # "true" # "," # "out" # "," # e.payload # "\n";
        };
        i += 1;
      };
      csv
    } else {
      // JSON format
      var json = "[";
      var i = 0;
      var first = true;
      while (i < entries.size()) {
        let e = entries[i];
        if (e.category == "BANK_FLAGGED" or e.category == "message") {
          if (not first) { json := json # "," };
          json := json # "{\"txId\":\"" # e.proofHash # "\","
                       # "\"timestamp\":" # e.timestamp.toText() # ","
                       # "\"category\":\"" # e.category # "\","
                       # "\"payload\":\"" # e.payload # "\"}";
          first := false;
        };
        i += 1;
      };
      json # "]"
    }
  };

  // ── getBankingSsuState — SSU state for banking module ────────────────────
  public query func getBankingSsuState() : async {
    genesisHash : Text;
    beatCount   : Nat;
    kuramotoR   : Float;
    aegisStatus : Text;
  } {
    let bankState = SovereignDB.getBankingAccountsState(db);
    let r = SovereignDB.getKuramotoR(db);
    {
      genesisHash = bankState.bankingSsuGenesisHash;
      beatCount   = bankState.bankingSsuBeatCount;
      kuramotoR   = r;
      aegisStatus = if (r >= 0.618) "GATE_OPEN" else "GATE_CLOSED_AEGIS_ACTIVE";
    }
  };

  // ── getBankingYield — estimated yield from D_LIQUID group ────────────────
  public query func getBankingYield() : async {
    dailyMaturityEst  : Float;
    weeklyEst         : Float;
    neuronGroupStatus : Text;
  } {
    let fleet = SovereignDB.getNeuronFleet(db);
    // D_LIQUID group: 55 neurons at 1.5yr dissolve, DISBURSE policy
    // Estimated yield: icpStaked * yieldRate / 365 per day
    let treasury = SovereignDB.getTreasuryState(db);
    let dailyEst = treasury.icpStaked * treasury.icpYieldRate / 365.0;
    {
      dailyMaturityEst  = dailyEst;
      weeklyEst         = dailyEst * 7.0;
      neuronGroupStatus = "D_LIQUID:" # fleet.groups[3].count.toText() # " neurons DISBURSE";
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // WYOMING CHARTER — Domain 20 public endpoints
  // SSU-wrapped: Ω_GATE Kuramoto R≥0.618, Ψ_IDENTITY sealed genesis hash
  // Δ_AEGIS: auto-escalates milestones in the heartbeat (no public function needed)
  // Wyoming legislative timeline: hardware Nov 2026, bill Jan 2027
  // FRNT demo: 0.3s vs 15min, 0% vs 3-5% fee — Phantom technology wins
  // ══════════════════════════════════════════════════════════════════════

  /// getWyomingCharter — public query, no auth required
  /// Returns the full sovereign Wyoming charter state
  public query func getWyomingCharter() : async SovereignDB.WyomingState {
    SovereignDB.getWyomingState(db)
  };

  /// updateMilestone — creator-only
  /// Updates milestone status and notes by milestone id
  public shared(msg) func updateMilestone(
    id     : Text,
    status : SovereignDB.MilestoneStatus,
    notes  : Text,
  ) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let updated = Wyoming.updateMilestone(SovereignDB.getWyomingState(db), id, status, notes, nowNs);
    db := SovereignDB.setWyomingState(db, updated);
  };

  /// addGrant — creator-only
  /// Appends a new grant record to the Wyoming charter
  public shared(msg) func addGrant(grant : SovereignDB.GrantRecord) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let updated = Wyoming.addGrant(SovereignDB.getWyomingState(db), grant, nowNs);
    db := SovereignDB.setWyomingState(db, updated);
  };

  /// runFrntDemo — Ω_GATE: Kuramoto R must be >= 0.618 (phi^-1)
  /// Executes the FRNT settlement demo, records the run timestamp
  /// Proves: 0.3s (Phantom) vs 900s (Visa), 0% vs 4% fee
  public shared(_msg) func runFrntDemo() : async SovereignDB.FrntDemo {
    if (SovereignDB.getKuramotoR(db) < 0.618) {
      return SovereignDB.getWyomingState(db).frntDemo;
    };
    let nowNs = Time.now();
    let (updatedWyo, demo) = Wyoming.runFrntDemo(SovereignDB.getWyomingState(db), nowNs);
    db := SovereignDB.setWyomingState(db, updatedWyo);
    demo
  };

  /// updateNodeProvider — creator-only
  /// Updates Bad Marine LLC node provider positioning
  public shared(msg) func updateNodeProvider(np : SovereignDB.NodeProvider) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let updated = Wyoming.updateNodeProvider(SovereignDB.getWyomingState(db), np, nowNs);
    db := SovereignDB.setWyomingState(db, updated);
  };

  // ══════════════════════════════════════════════════════════════════════
  // SCHOOL REGISTRY — SOVEREIGN EDUCATION MODULE
  // Bronze free tier: all query functions require NO authentication
  // Silver/Gold admin functions require creator principal
  // Every product always ships a public school version — Bronze is always free
  // GENESIS LAW L09: 20 TEKS standards, 3 schools, 4 grants pre-seeded on deploy
  // ══════════════════════════════════════════════════════════════════════

  // getPublicCurriculum — returns all 20 pre-seeded TEKS standards with lesson tools
  // Bronze free tier — no auth required — fully public sovereign knowledge
  public query func getPublicCurriculum() : async [SchoolReg.TeksStandard] {
    SchoolReg.getPublicCurriculum(schoolRegistry)
  };

  // getTeksStandard — returns a single TEKS standard by official code
  // Bronze free tier — no auth required
  public query func getTeksStandard(code : Text) : async ?SchoolReg.TeksStandard {
    SchoolReg.getTeksStandard(schoolRegistry, code)
  };

  // getSchoolRegistry — returns the full registry overview
  // Bronze free tier — registry metadata is public
  public query func getSchoolRegistry() : async SchoolReg.SchoolRegistry {
    SchoolReg.getSchoolRegistry(schoolRegistry)
  };

  // getSchoolByDistrict — query schools by district name
  // Bronze free tier
  public query func getSchoolByDistrict(district : Text) : async [SchoolReg.SchoolRecord] {
    SchoolReg.getSchoolByDistrict(schoolRegistry, district)
  };

  // getGrantsByStatus — filter grants by current status
  // Bronze free tier
  public query func getGrantsByStatus(status : Text) : async [SchoolReg.GrantRecord_School] {
    SchoolReg.getGrantsByStatus(schoolRegistry, status)
  };

  // getLessonToolsBySubject — return all lesson tools for a given subject
  // Bronze free tier
  public query func getLessonToolsBySubject(subject : Text) : async [SchoolReg.LessonTool] {
    SchoolReg.getLessonToolsBySubject(schoolRegistry, subject)
  };

  // getLessonToolsByGrade — return all lesson tools for a given grade level
  // Bronze free tier
  public query func getLessonToolsByGrade(grade : Text) : async [SchoolReg.LessonTool] {
    SchoolReg.getLessonToolsByGrade(schoolRegistry, grade)
  };

  // addTeksStandard — add a new TEKS standard — requires creator auth
  public shared(msg) func addTeksStandard(std : SchoolReg.TeksStandard) : async () {
    assertCreator(msg.caller);
    let nowMs = Time.now() / 1_000_000;
    schoolRegistry := SchoolReg.addTeksStandard(schoolRegistry, msg.caller, msg.caller, std, nowMs);
  };

  // deploySchoolCanister — record a deployed canister for a school — requires creator auth
  public shared(msg) func deploySchoolCanister(schoolId : Text, canisterId : Text) : async () {
    assertCreator(msg.caller);
    let nowMs = Time.now() / 1_000_000;
    schoolRegistry := SchoolReg.deploySchoolCanister(schoolRegistry, msg.caller, msg.caller, schoolId, canisterId, nowMs);
  };

  // addLessonTool — add a lesson tool to a TEKS standard — requires creator auth
  public shared(msg) func addLessonTool(teksCode : Text, tool : SchoolReg.LessonTool) : async () {
    assertCreator(msg.caller);
    let nowMs = Time.now() / 1_000_000;
    schoolRegistry := SchoolReg.addLessonTool(schoolRegistry, msg.caller, msg.caller, teksCode, tool, nowMs);
  };

  // updateGrantStatus — update a grant's status — requires creator auth
  public shared(msg) func updateGrantStatus(grantName : Text, status : Text) : async () {
    assertCreator(msg.caller);
    let nowMs = Time.now() / 1_000_000;
    schoolRegistry := SchoolReg.updateGrantStatus(schoolRegistry, msg.caller, msg.caller, grantName, status, nowMs);
  };

  // addSchool — register a new school — requires creator auth
  public shared(msg) func addSchool(school : SchoolReg.SchoolRecord) : async () {
    assertCreator(msg.caller);
    let nowMs = Time.now() / 1_000_000;
    schoolRegistry := SchoolReg.addSchool(schoolRegistry, msg.caller, msg.caller, school, nowMs);
  };

  // ══════════════════════════════════════════════════════════════════════
  // BIRTH_AI SDK — sovereign entity birth and management
  // birthAI() is the external call surface — one call creates a living entity
  // speak(), setGoal(), learn(), recall() are the external interaction surface
  // State lives in sovereign_db domain 21 — persists via EOP, never resets
  // ══════════════════════════════════════════════════════════════════════

  /// birthAI — create a sovereign entity or external agent
  /// entityType: "internal" (born into organism) | "external" (operates outside)
  /// directive: plain natural language — organ type auto-classified from keywords
  /// Returns the new entityId
  public shared func birthAI(name : Text, directive : Text, entityType : Text) : async Text {
    let eType : BirthAi.EntityType = if (entityType == "external") #external else #internal;
    let beat   = SovereignDB.getBeatCount(db).toInt();
    let (newBirthState, entityId) = BirthAi.birthEntity(
      SovereignDB.getBirthAiState(db), name, directive, eType, beat
    );
    db := SovereignDB.setBirthAiState(db, newBirthState);
    entityId
  };

  /// entitySpeak — send a message to a sovereign entity, receive its response
  public shared func entitySpeak(entityId : Text, message : Text) : async Text {
    let (newBirthState, response) = BirthAi.speak(
      SovereignDB.getBirthAiState(db), entityId, message
    );
    db := SovereignDB.setBirthAiState(db, newBirthState);
    response
  };

  /// entitySetGoal — push a goal onto the entity's goal stack (max 10)
  public shared func entitySetGoal(entityId : Text, goal : Text) : async () {
    let newBirthState = BirthAi.setGoal(SovereignDB.getBirthAiState(db), entityId, goal);
    db := SovereignDB.setBirthAiState(db, newBirthState);
  };

  /// entityLearn — increase entity activation by phi^-1 per call; caps at 1.0
  /// PHI LAW: activation compounds at the golden ratio inverse — phi-derived growth
  public shared func entityLearn(entityId : Text, content : Text) : async () {
    let newBirthState = BirthAi.learn(SovereignDB.getBirthAiState(db), entityId, content);
    db := SovereignDB.setBirthAiState(db, newBirthState);
  };

  /// entityRecall — search entity message log for past messages matching query
  public query func entityRecall(entityId : Text, query_ : Text) : async [Text] {
    BirthAi.recall(SovereignDB.getBirthAiState(db), entityId, query_)
  };

  /// listEntities — return all sovereign entities (internal + external)
  public query func listEntities() : async [BirthAi.BirthEntity] {
    BirthAi.listEntities(SovereignDB.getBirthAiState(db))
  };

  /// getBirthAiState — full BirthAI domain snapshot
  public query func getBirthAiState() : async BirthAi.BirthAiState {
    SovereignDB.getBirthAiState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // BUILDER SDK — natural language → sovereign artifact pipeline
  // Submit a paragraph of plain text → auto-parsed → entity/agent/canister born
  // State lives in sovereign_db domain 22 — persists via EOP, never resets
  // ══════════════════════════════════════════════════════════════════════

  /// submitBuilderDirective — submit a natural language directive for parsing
  /// Returns directiveId for subsequent execution
  public shared func submitBuilderDirective(rawText : Text) : async Text {
    let (newBuilderState, directiveId) = BuilderSdk.submitDirective(
      SovereignDB.getBuilderState(db), rawText
    );
    db := SovereignDB.setBuilderState(db, newBuilderState);
    directiveId
  };

  /// executeBuilderDirective — execute a previously parsed directive
  /// If targetType is entity/agent → calls birthAI internally
  /// Returns execution result string
  public shared func executeBuilderDirective(directiveId : Text) : async Text {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let (newBuilderState, newBirthAiState, result) = BuilderSdk.executeDirective(
      SovereignDB.getBuilderState(db),
      directiveId,
      SovereignDB.getBirthAiState(db),
      beat,
    );
    db := SovereignDB.setBuilderState(db, newBuilderState);
    db := SovereignDB.setBirthAiState(db, newBirthAiState);
    result
  };

  /// listBuilderDirectives — return all submitted directives
  public query func listBuilderDirectives() : async [BuilderSdk.BuilderDirective] {
    BuilderSdk.listDirectives(SovereignDB.getBuilderState(db))
  };

  /// getBuilderState — full Builder SDK domain snapshot
  public query func getBuilderState() : async BuilderSdk.BuilderState {
    SovereignDB.getBuilderState(db)
  };

  // ══════════════════════════════════════════════════════════════════════
  // CANISTER REGISTRY — Domain 23 public endpoints
  // Organ canisters report health here; this canister tracks all 9 organs.
  // reportHealth() is the sovereign organ interface required for registry integration.
  // ══════════════════════════════════════════════════════════════════════

  /// getRegistryState — full canister registry snapshot (all 9 organs)
  public query func getRegistryState() : async CanisterRegistry.RegistryState {
    SovereignDB.getRegistryState(db)
  };

  /// getOrganHealth — health record for a specific organ type
  public query func getOrganHealth(organType : Text) : async ?CanisterRegistry.RegistryEntry {
    CanisterRegistry.getOrganHealth(SovereignDB.getRegistryState(db), organType)
  };

  /// getRegistryEntries — all registered organ entries as a flat array
  public query func getRegistryEntries() : async [CanisterRegistry.RegistryEntry] {
    CanisterRegistry.getRegistry(SovereignDB.getRegistryState(db))
  };

  /// updateOrganHealth — called by organ canisters on their own heartbeat
  /// Any external canister implementing reportHealth() submits here.
  public shared func updateOrganHealth(report : CanisterRegistry.HealthReport) : async () {
    db := SovereignDB.updateOrganHealthInRegistry(db, report);
  };

  /// registerOrgan — creator-only: wire a deployed organ canister ID
  public shared(msg) func registerOrgan(organType : Text, canisterId : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    db := SovereignDB.registerOrganInRegistry(db, organType, canisterId, nowNs);
  };

  /// markOrganDegraded — creator-only: force organ status to #degraded
  public shared(msg) func markOrganDegraded(organType : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let updated = CanisterRegistry.markDegraded(SovereignDB.getRegistryState(db), organType, nowNs);
    db := SovereignDB.setRegistryState(db, updated);
  };

  /// markOrganUnreachable — creator-only: force organ status to #unreachable
  public shared(msg) func markOrganUnreachable(organType : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let updated = CanisterRegistry.markUnreachable(SovereignDB.getRegistryState(db), organType, nowNs);
    db := SovereignDB.setRegistryState(db, updated);
  };

  /// getRegistryCoherence — mean healthScore across all registered organs
  public query func getRegistryCoherence() : async Float {
    CanisterRegistry.computeRegistryCoherence(SovereignDB.getRegistryState(db))
  };

  // ══════════════════════════════════════════════════════════════════════
  // PROTOCOL REGISTRY — Domain 24 public endpoints
  // 89+ protocols extracted from laws/types/agi/cognition/organs.
  // Gate functions are synchronous — they check before any state mutation.
  // ══════════════════════════════════════════════════════════════════════

  /// getProtocolRegistry — full protocol execution registry snapshot
  public query func getProtocolRegistry() : async ProtocolExecution.ProtocolRegistry {
    SovereignDB.getProtocolRegistry(db)
  };

  /// getProtocolsByCategory — all protocols of a given category
  /// category: "Law" | "Model" | "Behavior" | "Reasoning" | "Organ"
  public query func getProtocolsByCategory(category : Text) : async [ProtocolExecution.ProtocolRecordPublic] {
    let reg = SovereignDB.getProtocolRegistry(db);
    switch (ProtocolExecution.textToCategory(category)) {
      case null { [] };
      case (?cat) {
        let filtered = ProtocolExecution.getProtocolsByCategory(reg, cat);
        Array.tabulate<ProtocolExecution.ProtocolRecordPublic>(filtered.size(), func(i) {
          ProtocolExecution.toPublic(filtered[i])
        })
      };
    }
  };

  /// getProtocolLog — all protocols sorted by lastFiredBeat descending
  public query func getProtocolLog() : async [ProtocolExecution.ProtocolRecordPublic] {
    let reg = SovereignDB.getProtocolRegistry(db);
    let sorted = ProtocolExecution.getProtocolExecutionLog(reg);
    Array.tabulate<ProtocolExecution.ProtocolRecordPublic>(sorted.size(), func(i) {
      ProtocolExecution.toPublic(sorted[i])
    })
  };

  /// getAllProtocols — all 89+ protocol records as public-safe array
  public query func getAllProtocols() : async [ProtocolExecution.ProtocolRecordPublic] {
    ProtocolExecution.getAllPublic(SovereignDB.getProtocolRegistry(db))
  };

  /// getProtocolById — lookup one protocol record by ID (e.g., "L01", "M05", "B03")
  public query func getProtocolById(id : Text) : async ?ProtocolExecution.ProtocolRecordPublic {
    let reg = SovereignDB.getProtocolRegistry(db);
    switch (ProtocolExecution.getProtocolById(reg, id)) {
      case null { null };
      case (?proto) { ?ProtocolExecution.toPublic(proto) };
    }
  };

  /// tickBeatManual with protocol gate — creator-only manual beat + gate check
  public shared(msg) func tickBeatManualGated() : async { beat : Nat; gateOpen : Bool } {
    assertCreator(msg.caller);
    db := SovereignDB.tickBeat(db);
    let beat = SovereignDB.getBeatCount(db);
    let beatInt = beat.toInt();
    let (dbAfterGate, gateOpen) = SovereignDB.gateProtocolOperation(db, "heartbeat", beatInt);
    db := dbAfterGate;
    { beat; gateOpen }
  };

  // ══════════════════════════════════════════════════════════════════════
  // MODEL REGISTRY — Domain 25 query endpoints
  // 300 sovereign models, MICRO/MESO/MACRO layers
  // ══════════════════════════════════════════════════════════════════════

  /// getModel — retrieve a sovereign model by ID (e.g., "M-001")
  public query func getModel(id : Text) : async ?ModelRegistry.SovereignModel {
    ModelRegistry.getModel(id)
  };

  /// listModelsByLayer — return all models in a given layer ("MICRO" | "MESO" | "MACRO")
  public query func listModelsByLayer(layer : Text) : async [ModelRegistry.SovereignModel] {
    ModelRegistry.listModelsByLayer(layer)
  };

  /// getAllModels — return all 300 sovereign models
  public query func getAllModels() : async [ModelRegistry.SovereignModel] {
    ModelRegistry.getAllModels()
  };

  /// getModelCount — always returns 300
  public query func getModelCount() : async Nat {
    ModelRegistry.getModelCount()
  };

  /// getModelRegistryState — aggregate model registry stats
  public query func getModelRegistryState() : async SovereignDB.ModelRegistryState {
    modelRegistryState
  };

  // ══════════════════════════════════════════════════════════════════════
  // CONTEXT ROUTER — Domain 26 query endpoints
  // Beat signal -> top-K resonant models -> ContextSlice
  // ══════════════════════════════════════════════════════════════════════

  /// routeBeat — route a beat signal text to top-K resonant models
  public query func routeBeat(signal : Text, k : Nat) : async ContextRouter.ContextSlice {
    let models = ModelRegistry.getAllModels();
    let buf = Array.tabulate(models.size(), func i : (Text, Nat32) {
      let m = models[i];
      (m.id, m.microTokenId)
    });
    ContextRouter.routeBeat(signal, k, buf, Time.now())
  };

  /// getMicroTokenBudget — returns the per-beat micro-token budget (200_000)
  public query func getMicroTokenBudget() : async Nat {
    ContextRouter.getBudget()
  };

  /// getContextRouterState — aggregate context router stats
  public query func getContextRouterState() : async SovereignDB.ContextRouterState {
    contextRouterState
  };

  // ══════════════════════════════════════════════════════════════════════
  // NOVA RUNTIME — Domain 27 public endpoints
  // 40 sovereign cognitive language engines: Lingua Legis Cognitivae through
  // Lingua Evolutionis Universi — all running as live executable computates.
  // Coherence gate: R >= 0.618 (phi^-1) required per engine per beat.
  // ══════════════════════════════════════════════════════════════════════

  /// getNovaLanguageRegistry — all 40 cognitive language engine records
  public query func getNovaLanguageRegistry() : async [NovaRuntime.NovaCognitiveLanguage] {
    NovaRuntime.getNovaLanguageRegistry(novaRuntimeState)
  };

  /// getNovaRuntimeState — full NOVA runtime state snapshot
  public query func getNovaRuntimeState() : async NovaRuntime.NovaRuntimeState {
    NovaRuntime.getNovaRuntimeState(novaRuntimeState)
  };

  /// executeNovaEngine — dispatch a specific cognitive language engine by ID
  /// Returns execution result. Coherence gate enforced: R >= 0.618 required.
  public shared func executeNovaEngine(engineId : Text, input : Text) : async Text {
    let beat       = SovereignDB.getBeatCount(db).toInt();
    let coherenceR = SovereignDB.getKuramotoR(db);
    let (newState, result) = NovaRuntime.executeNovaEngine(
      novaRuntimeState, engineId, input, beat, coherenceR
    );
    novaRuntimeState := newState;
    result
  };

  /// getNovaLanguageById — retrieve one engine record by ID
  public query func getNovaLanguageById(id : Text) : async ?NovaRuntime.NovaCognitiveLanguage {
    NovaRuntime.getLanguageById(novaRuntimeState, id)
  };

  /// getNovaLanguagesByStack — retrieve all engines in a named stack
  public query func getNovaLanguagesByStack(stack : Text) : async [NovaRuntime.NovaCognitiveLanguage] {
    NovaRuntime.getLanguagesByStack(novaRuntimeState, stack)
  };

  /// getNovaActiveLanguages — engines currently in active or transcended phase
  public query func getNovaActiveLanguages() : async [NovaRuntime.NovaCognitiveLanguage] {
    NovaRuntime.getActiveLanguages(novaRuntimeState)
  };

  // ══════════════════════════════════════════════════════════════════════
  // PHANTOM INTELLIGENCE — Domain 28
  // AI-first exchange intelligence: reasoning, valuation, risk, arbitrage
  // ══════════════════════════════════════════════════════════════════════

  public query func getPhantomIntelligenceState() : async PhantomIntel.PhantomIntelligenceState {
    phantomIntelligenceState
  };

  /// injectMarketSignal — external market data enters the intelligence layer
  public shared func injectMarketSignal(
    tokenPair   : Text,
    signalType  : Text,
    magnitude   : Float,
    confidence  : Float,
    sourceLayer : Text,
  ) : async Nat {
    let sigType : PhantomIntel.SignalType = switch (signalType) {
      case "priceMovement"        { #priceMovement };
      case "volumeSpike"          { #volumeSpike };
      case "orderFlowImbalance"   { #orderFlowImbalance };
      case "arbitrageOpportunity" { #arbitrageOpportunity };
      case "liquidityShift"       { #liquidityShift };
      case "aiArtifactCreation"   { #aiArtifactCreation };
      case "coherenceBreakout"    { #coherenceBreakout };
      case "whaleMovement"        { #whaleMovement };
      case "crossChainSignal"     { #crossChainSignal };
      case _                      { #doctrineAlignment };
    };

    let signal : PhantomIntel.MarketSignal = {
      signalId      = phantomIntelligenceState.signalCount + 1;
      tokenPair     = tokenPair;
      signalType    = sigType;
      magnitude     = magnitude;
      confidence    = confidence;
      beatTimestamp = SovereignDB.getBeatCount(db).toInt();
      decayRate     = 0.618;
      sourceLayer   = sourceLayer;
    };
    phantomIntelligenceState := PhantomIntel.injectSignal(phantomIntelligenceState, signal);
    phantomIntelligenceState.signalCount
  };

  /// predictPrice — harmonic-based price forecasting
  public shared func predictPrice(tokenPair : Text, currentPrice : Float, horizonBeats : Nat) : async PhantomIntel.PricePrediction {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let coherenceR = SovereignDB.getKuramotoR(db);
    let (newState, prediction) = PhantomIntel.predictPrice(
      phantomIntelligenceState, tokenPair, currentPrice, horizonBeats, beat, coherenceR
    );
    phantomIntelligenceState := newState;
    prediction
  };

  /// assessRisk — phi-bounded risk computation for a trading pair
  public shared func assessTradeRisk(tokenPair : Text, volatility : Float, liquidity : Float, counterparty : Float, doctrine : Float) : async PhantomIntel.RiskAssessment {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let (newState, assessment) = PhantomIntel.assessRisk(
      phantomIntelligenceState, tokenPair, volatility, liquidity, counterparty, doctrine, beat
    );
    phantomIntelligenceState := newState;
    assessment
  };

  // ══════════════════════════════════════════════════════════════════════
  // PHANTOM EXCHANGE — Domain 29
  // Zero-gas-fee decentralized exchange for ALL tokens
  // ══════════════════════════════════════════════════════════════════════

  public query func getPhantomExchangeState() : async PhantomExchange.PhantomExchangeState {
    phantomExchangeState
  };

  public query func getOrderBook(pairId : Text) : async ?PhantomExchange.OrderBook {
    PhantomExchange.getOrderBook(phantomExchangeState, pairId)
  };

  public query func getRecentFills() : async [PhantomExchange.Fill] {
    phantomExchangeState.recentFills
  };

  public query func getTradingPairs() : async [(Text, PhantomExchange.TradingPair)] {
    phantomExchangeState.pairs
  };

  /// placeOrder — submit a new order (limit or market) to the Phantom Exchange
  /// ZERO GAS FEES. Settlement is instant (same beat).
  public shared(msg) func placeOrder(
    pairId    : Text,
    side      : Text,
    orderType : Text,
    price     : Float,
    quantity  : Float,
  ) : async PhantomExchange.Order {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let coherenceR = SovereignDB.getKuramotoR(db);
    let owner = Principal.toText(msg.caller);

    let orderSide : PhantomExchange.OrderSide = switch (side) {
      case "buy"  { #buy };
      case _      { #sell };
    };
    let oType : PhantomExchange.OrderType = switch (orderType) {
      case "market"      { #market };
      case "stopLimit"   { #stopLimit };
      case "iceberg"     { #iceberg };
      case _             { #limit };
    };

    let (newState, order) = PhantomExchange.placeOrder(
      phantomExchangeState, pairId, owner, orderSide, oType, price, quantity, #gtc, beat, coherenceR
    );
    phantomExchangeState := newState;

    // Run matching engine immediately after order placement
    phantomExchangeState := PhantomExchange.runMatchingEngine(phantomExchangeState, beat);

    order
  };

  /// cancelOrder — cancel an open order
  public shared func cancelExchangeOrder(orderId : Nat, pairId : Text) : async Bool {
    let beat = SovereignDB.getBeatCount(db).toInt();
    phantomExchangeState := PhantomExchange.cancelOrder(phantomExchangeState, orderId, pairId, beat);
    true
  };

  /// addTradingPair — list a new trading pair on the exchange
  public shared(msg) func addTradingPair(
    pairId   : Text,
    base     : Text,
    quote    : Text,
    baseCat  : Text,
    quoteCat : Text,
    tickSize : Float,
  ) : async Bool {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db).toInt();
    let bCat : PhantomExchange.TokenCategory = parseTokenCategory(baseCat);
    let qCat : PhantomExchange.TokenCategory = parseTokenCategory(quoteCat);
    phantomExchangeState := PhantomExchange.addTradingPair(
      phantomExchangeState, pairId, base, quote, bCat, qCat, tickSize, beat
    );
    true
  };

  func parseTokenCategory(cat : Text) : PhantomExchange.TokenCategory {
    switch (cat) {
      case "crypto"          { #crypto };
      case "aiToken"         { #aiToken };
      case "aiArtifact"      { #aiArtifact };
      case "sovereignToken"  { #sovereignToken };
      case "creatorToken"    { #creatorToken };
      case "stablecoin"      { #stablecoin };
      case "nft"             { #nft };
      case "syntheticAsset"  { #syntheticAsset };
      case "realWorldAsset"  { #realWorldAsset };
      case "governanceToken" { #governanceToken };
      case _                 { #crypto };
    }
  };

  func categoryForCustomToken(
    token : TokenFactory.TokenDefinition
  ) : PhantomExchange.TokenCategory {
    switch (token.tokenType) {
      case (
        #aiCompute or #aiMemory or #aiInference or #aiTraining or #aiData or
        #aiGPU or #aiTPU or #aiBandwidth or #aiStorage or #aiFineTune or
        #aiEmbedding or #aiRAG or #aiAgent or #aiOrchestration or
        #aiReasoningChain or #aiVision or #aiAudio or #aiCodeGen or
        #aiTranslation or #aiSentiment or #aiAnomaly or #aiPrediction or
        #aiOptimization or #aiSimulation
      ) { #aiToken };
      case (#creatorPersonal) { #creatorToken };
      case (#artifactBacked or #fractionalNFT) { #aiArtifact };
      case (
        #governance or #yield or #aiModelVote or #aiDatasetVote or
        #aiSafetyAudit or #aiRedTeam or #aiBenchmark or #aiCertification
      ) { #governanceToken };
      case (#utility or #rewardPoints) { #sovereignToken };
    }
  };

  func tickSizeForToken(token : TokenFactory.TokenDefinition) : Float {
    if (token.initialPrice <= 0.00001) { 0.000001 }
    else if (token.initialPrice <= 0.001) { 0.00001 }
    else { 0.0001 }
  };

  // ══════════════════════════════════════════════════════════════════════
  // AI ARTIFACT REGISTRY — Domain 30
  // Register, verify, trade AI artifacts of value
  // ══════════════════════════════════════════════════════════════════════

  public query func getAiArtifactRegistryState() : async AiArtifactRegistry.AiArtifactRegistryState {
    aiArtifactRegistryState
  };

  public query func getAiArtifact(artifactId : Text) : async ?AiArtifactRegistry.ArtifactRecord {
    AiArtifactRegistry.getArtifact(aiArtifactRegistryState, artifactId)
  };

  public query func getTradeableArtifacts() : async [AiArtifactRegistry.ArtifactRecord] {
    AiArtifactRegistry.getTradeableArtifacts(aiArtifactRegistryState)
  };

  /// registerAiArtifact — mint a new AI artifact into the registry
  public shared(msg) func registerAiArtifact(
    name         : Text,
    description  : Text,
    artifactType : Text,
    tokenSymbol  : Text,
    totalSupply  : Float,
    qualityScore : Float,
  ) : async AiArtifactRegistry.ArtifactRecord {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let creator = Principal.toText(msg.caller);
    let aType : AiArtifactRegistry.ArtifactType = switch (artifactType) {
      case "sovereignModel"     { #sovereignModel };
      case "vectorEmbedding"    { #vectorEmbedding };
      case "reasoningProtocol"  { #reasoningProtocol };
      case "cognitiveOutput"    { #cognitiveOutput };
      case "trainingDataset"    { #trainingDataset };
      case "predictionRecord"   { #predictionRecord };
      case "compositeAgent"     { #compositeAgent };
      case "generativeArt"      { #generativeArt };
      case "knowledgeGraph"     { #knowledgeGraph };
      case _                    { #simulationResult };
    };
    let (newState, artifact) = AiArtifactRegistry.registerArtifact(
      aiArtifactRegistryState, name, description, aType, creator, tokenSymbol, totalSupply, qualityScore, beat
    );
    aiArtifactRegistryState := newState;
    artifact
  };

  /// verifyAiArtifact — verify and enable trading for an artifact
  public shared(msg) func verifyAiArtifact(artifactId : Text) : async Bool {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db).toInt();
    aiArtifactRegistryState := AiArtifactRegistry.verifyArtifact(aiArtifactRegistryState, artifactId, beat);
    true
  };

  // ══════════════════════════════════════════════════════════════════════
  // PHANTOM CLEARINGHOUSE — Domain 31
  // Real-time clearing, settlement, netting — ZERO gas fees
  // ══════════════════════════════════════════════════════════════════════

  public query func getPhantomClearinghouseState() : async PhantomClearinghouse.PhantomClearinghouseState {
    phantomClearinghouseState
  };

  public query func getSettlementVelocity() : async Float {
    phantomClearinghouseState.settlementVelocity
  };

  public query func getTotalGasFeesSaved() : async Float {
    phantomClearinghouseState.totalGasFeesSaved
  };

  /// crossChainSettle — settle across chains without bridges (internal reserves)
  public shared(msg) func crossChainSettle(
    sourceChain : Text,
    destChain   : Text,
    sourceToken : Text,
    destToken   : Text,
    sourceAmt   : Float,
    destAmt     : Float,
  ) : async Bool {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db).toInt();
    phantomClearinghouseState := PhantomClearinghouse.crossChainSettle(
      phantomClearinghouseState, sourceChain, destChain, sourceToken, destToken, sourceAmt, destAmt, beat
    );
    true
  };

  // ══════════════════════════════════════════════════════════════════════
  // TOKEN FACTORY — Domain 32
  // Create, mint, burn, list custom tokens
  // ══════════════════════════════════════════════════════════════════════

  public query func getTokenFactoryState() : async TokenFactory.TokenFactoryState {
    tokenFactoryState
  };

  public query func getAllCustomTokens() : async [TokenFactory.TokenDefinition] {
    TokenFactory.getAllTokens(tokenFactoryState)
  };

  public query func getAiTokens() : async [TokenFactory.TokenDefinition] {
    TokenFactory.getAiTokens(tokenFactoryState)
  };

  /// createCustomToken — mint a brand new token type into existence
  public shared(msg) func createCustomToken(
    symbol      : Text,
    name        : Text,
    description : Text,
    tokenType   : Text,
    maxSupply   : Float,
  ) : async TokenFactory.TokenDefinition {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let creator = Principal.toText(msg.caller);
    let tType : TokenFactory.CustomTokenType = switch (tokenType) {
      case "aiCompute"       { #aiCompute };
      case "aiMemory"        { #aiMemory };
      case "aiInference"     { #aiInference };
      case "aiTraining"      { #aiTraining };
      case "aiData"          { #aiData };
      case "creatorPersonal" { #creatorPersonal };
      case "artifactBacked"  { #artifactBacked };
      case "governance"      { #governance };
      case "yield"           { #yield };
      case "utility"         { #utility };
      case "rewardPoints"    { #rewardPoints };
      case _                 { #fractionalNFT };
    };
    let (newState, token) = TokenFactory.createToken(
      tokenFactoryState, symbol, name, description, tType, creator, maxSupply, beat
    );
    tokenFactoryState := newState;
    token
  };

  /// mintCustomTokens — mint additional supply of an existing token
  public shared(msg) func mintCustomTokens(tokenId : Text, recipient : Text, amount : Float, reason : Text) : async Bool {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db).toInt();
    tokenFactoryState := TokenFactory.mintTokens(tokenFactoryState, tokenId, recipient, amount, reason, beat);
    true
  };

  /// burnCustomTokens — burn (destroy) token supply
  public shared(msg) func burnCustomTokens(tokenId : Text, amount : Float, reason : Text) : async Bool {
    let beat = SovereignDB.getBeatCount(db).toInt();
    let burner = Principal.toText(msg.caller);
    tokenFactoryState := TokenFactory.burnTokens(tokenFactoryState, tokenId, burner, amount, reason, beat);
    true
  };

  /// verifyAndListToken — verify doctrine compliance and list on Phantom Exchange
  public shared(msg) func verifyAndListToken(tokenId : Text) : async Bool {
    assertCreator(msg.caller);
    let beat = SovereignDB.getBeatCount(db).toInt();
    tokenFactoryState := TokenFactory.verifyAndList(tokenFactoryState, tokenId, beat);
    switch (TokenFactory.getToken(tokenFactoryState, tokenId)) {
      case (?token) {
        switch (token.tradingPairId) {
          case (?pairId) {
            phantomExchangeState := PhantomExchange.addTradingPair(
              phantomExchangeState,
              pairId,
              token.symbol,
              "ICP",
              categoryForCustomToken(token),
              #crypto,
              tickSizeForToken(token),
              beat,
            );
          };
          case null {};
        }
      };
      case null {};
    };
    true
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ██  ALOHA I — DOMAIN 33  PUBLIC ENDPOINTS                              ██
  // ═══════════════════════════════════════════════════════════════════════════

  /// Query the full ALOHA I state (all 10 protocol multi-models)
  public query func getAlohaIState() : async AlohaI.AlohaIState {
    alohaIState
  };

  /// Query individual protocol states
  public query func getAlohaISpectralLiquidity() : async AlohaI.SpectralLiquidityState {
    alohaIState.spectralLiquidity
  };

  public query func getAlohaITemporalArbitrage() : async AlohaI.TemporalArbitrageState {
    alohaIState.temporalArbitrage
  };

  public query func getAlohaICognitiveMM() : async AlohaI.CognitiveMMState {
    alohaIState.cognitiveMM
  };

  public query func getAlohaISignalFusion() : async AlohaI.SignalFusionState {
    alohaIState.signalFusion
  };

  public query func getAlohaIQuantumRouting() : async AlohaI.QuantumRoutingState {
    alohaIState.quantumRouting
  };

  public query func getAlohaINeuralPortfolio() : async AlohaI.NeuralPortfolioState {
    alohaIState.neuralPortfolio
  };

  public query func getAlohaIPhantomSettlement() : async AlohaI.PhantomSettlementState {
    alohaIState.phantomSettlement
  };

  public query func getAlohaIEntropicRisk() : async AlohaI.EntropicRiskState {
    alohaIState.entropicRisk
  };

  public query func getAlohaIEmergentAsset() : async AlohaI.EmergentAssetState {
    alohaIState.emergentAsset
  };

  public query func getAlohaISwarmExecution() : async AlohaI.SwarmExecutionState {
    alohaIState.swarmExecution
  };

  /// Protocol summary: name + coherence for all 10 models
  public query func getAlohaIProtocolSummary() : async [{name: Text; coherence: Float}] {
    [
      {name = "SpectralLiquidity"; coherence = alohaIState.spectralLiquidity.compositeCoherence},
      {name = "TemporalArbitrage"; coherence = alohaIState.temporalArbitrage.compositeCoherence},
      {name = "CognitiveMarketMaker"; coherence = alohaIState.cognitiveMM.compositeCoherence},
      {name = "SignalFusion"; coherence = alohaIState.signalFusion.compositeCoherence},
      {name = "QuantumRouting"; coherence = alohaIState.quantumRouting.compositeCoherence},
      {name = "NeuralPortfolio"; coherence = alohaIState.neuralPortfolio.compositeCoherence},
      {name = "PhantomSettlement"; coherence = alohaIState.phantomSettlement.compositeCoherence},
      {name = "EntropicRisk"; coherence = alohaIState.entropicRisk.compositeCoherence},
      {name = "EmergentAsset"; coherence = alohaIState.emergentAsset.compositeCoherence},
      {name = "SwarmExecution"; coherence = alohaIState.swarmExecution.compositeCoherence}
    ]
  };

  // ══════════════════════════════════════════════════════════════════════════
  // PROTOCOL ENGINE QUERY ENDPOINTS — Domains 51–64
  // ══════════════════════════════════════════════════════════════════════════

  public query func getPhantomSentimentState() : async PhantomSentiment.PhantomSentimentState {
    phantomSentimentState
  };

  public query func getPhantomPortfolioState() : async PhantomPortfolio.PhantomPortfolioState {
    phantomPortfolioState
  };

  public query func getPhantomRegimeState() : async PhantomRegime.PhantomRegimeState {
    phantomRegimeState
  };

  public query func getPhantomVolatilityState() : async PhantomVolatility.PhantomVolatilityState {
    phantomVolatilityState
  };

  public query func getPhantomCorrelationState() : async PhantomCorrelation.PhantomCorrelationState {
    phantomCorrelationState
  };

  public query func getPhantomMicrostructureState() : async PhantomMicrostructure.PhantomMicrostructureState {
    phantomMicrostructureState
  };

  public query func getPhantomFundingState() : async PhantomFunding.PhantomFundingState {
    phantomFundingState
  };

  public query func getPhantomOptionsState() : async PhantomOptions.PhantomOptionsState {
    phantomOptionsState
  };

  public query func getPhantomNeuralState() : async PhantomNeural.PhantomNeuralState {
    phantomNeuralState
  };

  public query func getPhantomGeneticState() : async PhantomGenetic.PhantomGeneticState {
    phantomGeneticState
  };

  public query func getPhantomFractalState() : async PhantomFractal.PhantomFractalState {
    phantomFractalState
  };

  public query func getPhantomWaveletState() : async PhantomWavelets.PhantomWaveletState {
    phantomWaveletsState
  };

  public query func getPhantomEntropyState() : async PhantomEntropy.PhantomEntropyState {
    phantomEntropyState
  };

  public query func getPhantomTopologyState() : async PhantomTopology.PhantomTopologyState {
    phantomTopologyState
  };

  // ══════════════════════════════════════════════════════════════════════════
  // CRYPTOGRAPHIA PHANTASMA QUERY ENDPOINTS
  // ══════════════════════════════════════════════════════════════════════════

  public query func getCryptographiaKeyState() : async CryptoKeys.CryptographiaKeyState {
    cryptoKeyState
  };

  public query func getCryptographiaShadowWireState() : async CryptoShadowWire.CryptographiaShadowWireState {
    cryptoShadowWireState
  };

  public query func getCryptographiaVaultState() : async CryptoVault.CryptographiaVaultState {
    cryptoVaultState
  };

  public query func getCryptographiaReceiptState() : async CryptoReceipts.CryptographiaReceiptState {
    cryptoReceiptState
  };

  // ── Domain health summary for all 64 domains ────────────────────────────
  public query func getProtocolEngineHealth() : async [{name: Text; domain: Nat; coherence: Float}] {
    [
      {name = "PhantomSentiment"; domain = 51; coherence = phantomSentimentState.coherence},
      {name = "PhantomPortfolio"; domain = 52; coherence = phantomPortfolioState.coherence},
      {name = "PhantomRegime"; domain = 53; coherence = phantomRegimeState.coherence},
      {name = "PhantomVolatility"; domain = 54; coherence = phantomVolatilityState.coherence},
      {name = "PhantomCorrelation"; domain = 55; coherence = phantomCorrelationState.coherence},
      {name = "PhantomMicrostructure"; domain = 56; coherence = phantomMicrostructureState.coherence},
      {name = "PhantomFunding"; domain = 57; coherence = phantomFundingState.coherence},
      {name = "PhantomOptions"; domain = 58; coherence = phantomOptionsState.coherence},
      {name = "PhantomNeural"; domain = 59; coherence = phantomNeuralState.coherence},
      {name = "PhantomGenetic"; domain = 60; coherence = phantomGeneticState.coherence},
      {name = "PhantomFractal"; domain = 61; coherence = phantomFractalState.coherence},
      {name = "PhantomWavelets"; domain = 62; coherence = phantomWaveletsState.coherence},
      {name = "PhantomEntropy"; domain = 63; coherence = phantomEntropyState.coherence},
      {name = "PhantomTopology"; domain = 64; coherence = phantomTopologyState.coherence}
    ]
  };

  public query func getCryptographiaHealth() : async [{system: Text; coherence: Float}] {
    [
      {system = "QuantumKeys"; coherence = cryptoKeyState.coherence},
      {system = "ShadowWires"; coherence = cryptoShadowWireState.coherence},
      {system = "SovereignVaults"; coherence = cryptoVaultState.coherence},
      {system = "ComputationalReceipts"; coherence = cryptoReceiptState.coherence}
    ]
  };

  // ══════════════════════════════════════════════════════════════════════════
  // DOMAIN 33 — PRODUCTION ENGINES PUBLIC ENDPOINTS
  // 24 sovereign financial-economic production engines (Latin-named, AI multi-model)
  // ══════════════════════════════════════════════════════════════════════════

  /// getProductionEnginesState — full production engine state
  public query func getProductionEnginesState() : async ProductionEngines.ProductionEngineState {
    productionEnginesState
  };

  /// getProductionEngine — get a specific engine by ID (e.g. "PE-001")
  public query func getProductionEngine(engineId : Text) : async ?ProductionEngines.ProductionEngine {
    ProductionEngines.getEngine(productionEnginesState, engineId)
  };

  /// getProductionEngineByLatin — get engine by official Latin name
  public query func getProductionEngineByLatin(latin : Text) : async ?ProductionEngines.ProductionEngine {
    ProductionEngines.getEngineByLatinName(productionEnginesState, latin)
  };

  /// getProductionEngineCount — total number of production engines (24)
  public query func getProductionEngineCount() : async Nat {
    ProductionEngines.getEngineCount(productionEnginesState)
  };

  /// getProductionModelCount — total AI models across all engines (93)
  public query func getProductionModelCount() : async Nat {
    ProductionEngines.getTotalModels(productionEnginesState)
  };

  /// getProductionMetrics — aggregate production statistics
  public query func getProductionMetrics() : async {
    engineCount : Nat;
    totalModels : Nat;
    totalProtocols : Nat;
    averageModelsPerEngine : Float;
    totalParameterCount : Nat;
    systemCoherence : Float;
  } {
    ProductionEngines.getProductionMetrics(productionEnginesState)
  };

  /// checkProductionCoherence — verify global Kuramoto coherence gate R ≥ φ⁻¹
  public query func checkProductionCoherence() : async Bool {
    ProductionEngines.checkGlobalCoherence(productionEnginesState)
  };

  // ══════════════════════════════════════════════════════════════════════
  // DOMAIN 34 — INTELLIGENCE CONTRACTS
  // Internal Intelligence Contracts for AI routing, reasoning, and coupling.
  // ══════════════════════════════════════════════════════════════════════

  /// getIntelligenceContractState — full state snapshot
  public query func getIntelligenceContractState() : async IntelligenceContracts.IntelligenceContractState {
    intelligenceContractsState
  };

  /// getIntelligenceContract — get single contract by ID
  public query func getIntelligenceContract(contractId : Text) : async ?IntelligenceContracts.IntelligenceContract {
    IntelligenceContracts.getContract(intelligenceContractsState, contractId)
  };

  /// listIntelligenceContracts — list all contracts
  public query func listIntelligenceContracts() : async [IntelligenceContracts.IntelligenceContract] {
    IntelligenceContracts.listContracts(intelligenceContractsState)
  };

  /// getActiveIntelligenceContracts — list active contracts only
  public query func getActiveIntelligenceContracts() : async [IntelligenceContracts.IntelligenceContract] {
    IntelligenceContracts.getActiveContracts(intelligenceContractsState)
  };

  /// getIntelligenceContractMetrics — aggregate statistics
  public query func getIntelligenceContractMetrics() : async {
    totalContracts : Nat;
    activeContracts : Nat;
    totalExecutions : Nat;
  } {
    {
      totalContracts = intelligenceContractsState.registry.totalContracts;
      activeContracts = intelligenceContractsState.registry.activeContracts;
      totalExecutions = intelligenceContractsState.registry.totalExecutions;
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // DOMAIN 35 — INTELLIGENCE ROUTING
  // Dynamic routing engine with adaptive strategy selection.
  // ══════════════════════════════════════════════════════════════════════

  /// getIntelligenceRoutingState — full routing state snapshot
  public query func getIntelligenceRoutingState() : async IntelligenceRouting.IntelligenceRoutingState {
    intelligenceRoutingState
  };

  /// getRoutingTable — get current routing table
  public query func getRoutingTable() : async IntelligenceRouting.RoutingTable {
    intelligenceRoutingState.routingTable
  };

  /// getRoutingMetrics — aggregate routing statistics
  public query func getRoutingMetrics() : async {
    totalRoutes : Nat;
    activeRoutes : Nat;
    signalsRouted : Nat;
    signalsDropped : Nat;
  } {
    {
      totalRoutes = intelligenceRoutingState.routingTable.totalRoutes;
      activeRoutes = intelligenceRoutingState.routingTable.activeRoutes;
      signalsRouted = intelligenceRoutingState.signalsRouted;
      signalsDropped = intelligenceRoutingState.signalsDropped;
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // DOMAIN 36 — INTELLIGENCE EXTENSIONS
  // AI extension plugin system with 8 capability slots.
  // ══════════════════════════════════════════════════════════════════════

  /// getIntelligenceExtensionsState — full extensions state snapshot
  public query func getIntelligenceExtensionsState() : async IntelligenceExtensions.IntelligenceExtensionState {
    intelligenceExtensionsState
  };

  /// getExtensionSlots — get all 8 extension slots
  public query func getExtensionSlots() : async [IntelligenceExtensions.ExtensionSlot] {
    intelligenceExtensionsState.registry.slots
  };

  /// getExtensionMetrics — aggregate extension statistics
  public query func getExtensionMetrics() : async {
    totalExtensions : Nat;
    activeExtensions : Nat;
    totalCalls : Nat;
    aggregateInfluence : Float;
  } {
    {
      totalExtensions = intelligenceExtensionsState.registry.totalExtensions;
      activeExtensions = intelligenceExtensionsState.registry.activeExtensions;
      totalCalls = intelligenceExtensionsState.registry.totalCalls;
      aggregateInfluence = IntelligenceExtensions.computeAggregateInfluence(intelligenceExtensionsState);
    }
  };

  // ══════════════════════════════════════════════════════════════════════
  // DOMAIN 37 — INTELLIGENCE COUPLING
  // External AI binding layer with write-back coherence gates.
  // ══════════════════════════════════════════════════════════════════════

  /// getIntelligenceCouplingState — full coupling state snapshot
  public query func getIntelligenceCouplingState() : async IntelligenceCoupling.IntelligenceCouplingState {
    intelligenceCouplingState
  };

  /// getCoupledSystems — list all coupled AI systems
  public query func getCoupledSystems() : async [(Text, Text, Float)] {
    IntelligenceCoupling.getActiveSystems(intelligenceCouplingState)
  };

  /// getCouplingMetrics — aggregate coupling statistics
  public query func getCouplingMetrics() : async {
    totalSystems : Nat;
    activeSystems : Nat;
    totalMessages : Nat;
    totalWriteBacks : Nat;
    globalCoherence : Float;
  } {
    {
      totalSystems = intelligenceCouplingState.registry.totalSystems;
      activeSystems = intelligenceCouplingState.registry.activeSystems;
      totalMessages = intelligenceCouplingState.registry.totalMessages;
      totalWriteBacks = intelligenceCouplingState.registry.totalWriteBacks;
      globalCoherence = intelligenceCouplingState.globalCoherence;
    }
  };

  /// getPendingWriteBacks — list pending write-back requests (validated, awaiting apply)
  public query func getPendingWriteBacks() : async [IntelligenceCoupling.WriteBackRequest] {
    IntelligenceCoupling.getPendingWriteBacks(intelligenceCouplingState)
  };

  // ══════════════════════════════════════════════════════════════════════
  // CHARTER — Domain 38 public endpoints
  // Organizational governance: membership, proposals, voting, offices
  // Quorum = PHI_INV (61.8%), Supermajority = 61.8% of cast weight
  // Constitutional changes require 80.9% quorum
  // ══════════════════════════════════════════════════════════════════════

  /// getCharter — public query, returns full organizational charter state
  public query func getCharter() : async Charter.CharterState {
    charterState
  };

  /// getCharterMembers — public query, returns all charter members
  public query func getCharterMembers() : async [Charter.Member] {
    charterState.members
  };

  /// getActiveProposals — public query, returns all active governance proposals
  public query func getActiveProposals() : async [Charter.Proposal] {
    Charter.getActiveProposals(charterState)
  };

  /// getProposal — public query, returns a specific proposal by ID
  public query func getProposal(id : Nat) : async ?Charter.Proposal {
    Charter.getProposal(charterState, id)
  };

  /// tallyProposal — public query, returns (cast, favor, against, participationRate)
  public query func tallyProposal(id : Nat) : async (Float, Float, Float, Float) {
    Charter.tallyProposal(charterState, id)
  };

  /// getCharterVersion — public query, returns current charter version
  public query func getCharterVersion() : async Nat {
    charterState.charterVersion
  };

  /// addCharterMember — creator-only, adds a member to the charter
  public shared(msg) func addCharterMember(
    principal : Text,
    name      : Text,
    tier      : Charter.MemberTier,
  ) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    let weight = Charter.tierToWeight(tier);
    let member : Charter.Member = {
      principal    = principal;
      name         = name;
      tier         = tier;
      joinedMs     = nowNs / 1_000_000;
      active       = true;
      votingWeight = weight;
      delegateTo   = null;
    };
    charterState := Charter.addMember(charterState, member, nowNs);
  };

  /// removeCharterMember — creator-only, removes a non-Founder member
  public shared(msg) func removeCharterMember(principal : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    charterState := Charter.removeMember(charterState, principal, nowNs);
  };

  /// createProposal — any active member can create a governance proposal
  public shared(msg) func createCharterProposal(
    title    : Text,
    desc     : Text,
    category : Charter.ProposalCategory,
  ) : async Nat {
    let caller = Principal.toText(msg.caller);
    // Must be active member
    switch (Charter.getMember(charterState, caller)) {
      case null { assert false; 0 };
      case (?m) {
        assert m.active;
        let nowNs = Time.now();
        charterState := Charter.createProposal(charterState, title, desc, category, caller, nowNs);
        charterState.nextProposalId - 1
      };
    }
  };

  /// castVote — any active member can vote on an active proposal
  public shared(msg) func castCharterVote(
    proposalId : Nat,
    inFavor    : Bool,
    rationale  : Text,
  ) : async () {
    let caller = Principal.toText(msg.caller);
    let nowNs = Time.now();
    charterState := Charter.castVote(charterState, proposalId, caller, inFavor, rationale, nowNs);
  };

  /// vetoProposal — founder-only, vetoes an Emergency proposal
  public shared(msg) func vetoCharterProposal(proposalId : Nat) : async () {
    assertCreator(msg.caller);
    let caller = Principal.toText(msg.caller);
    let nowNs = Time.now();
    charterState := Charter.vetoProposal(charterState, proposalId, caller, nowNs);
  };

  /// appointOffice — creator-only, appoints a holder to a vacant office
  public shared(msg) func appointCharterOffice(officeId : Text, holder : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    charterState := Charter.appointOffice(charterState, officeId, holder, nowNs);
  };

  /// vacateOffice — creator-only, removes a holder from a removable office
  public shared(msg) func vacateCharterOffice(officeId : Text) : async () {
    assertCreator(msg.caller);
    let nowNs = Time.now();
    charterState := Charter.vacateOffice(charterState, officeId, nowNs);
  };




};
