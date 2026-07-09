// prediction_assets.mo — PREDICTION MARKET ASSET REGISTRY
// PARALLAX Sovereign Organism — 58 World Contract Asset Classes
//
// DOCTRINE: "Every predictable event in the world is a tradeable asset class.
// This registry defines the full taxonomy of world contracts — from elections
// to earthquakes, from interest rates to interstellar missions. Each asset class
// has defined resolution criteria, oracle requirements, typical duration, and
// liquidity parameters. The organism makes the world's future TRADEABLE."
//
// STRUCTURE: Each asset is defined with:
//   1. CONTRACT CODE: CT-XX unique identifier
//   2. CATEGORY: Domain classification
//   3. RESOLUTION CRITERIA: Exact conditions for YES/NO/scalar resolution
//   4. ORACLE SOURCES: Required data feeds
//   5. TYPICAL DURATION: Expected contract lifetime
//   6. LIQUIDITY TIER: Base liquidity parameter (phi-scaled)
//   7. RISK TIER: Volatility and correlation classification
//
// PYTHAGORAS: liquidity tiers follow Fibonacci sequence
// EUCLID:     single registry — all asset definitions live here
// CONFUCIUS:  right relationship — clear criteria prevent disputes
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // LIQUIDITY TIERS — Fibonacci-scaled base liquidity
  // Higher tier = deeper liquidity = tighter spreads
  // ═══════════════════════════════════════════════════════════════════════════

  public type LiquidityTier = {
    #tier1_sovereign;    // 10946 units — F(21) — highest liquidity (elections, rates)
    #tier2_major;        // 6765 units — F(20) — major world events
    #tier3_standard;     // 4181 units — F(19) — standard contracts
    #tier4_emerging;     // 2584 units — F(18) — emerging/niche markets
    #tier5_exotic;       // 1597 units — F(17) — exotic/long-tail contracts
  };

  public type RiskTier = {
    #low;       // Predictable, mean-reverting, many data sources
    #medium;    // Moderate volatility, some uncertainty in resolution
    #high;      // Binary jumps, limited oracle coverage
    #extreme;   // Black swan territory, novel events, sparse data
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ASSET CLASS DEFINITION — full specification of a prediction asset
  // ═══════════════════════════════════════════════════════════════════════════

  public type PredictionAssetClass = {
    code             : Text;           // CT-XX
    name             : Text;           // Official name
    category         : Text;           // Domain (Geopolitics, Economics, etc.)
    description      : Text;           // What this contract type covers
    resolutionCriteria : Text;         // Exact criteria for resolution
    oracleSources    : [Text];         // Required data feeds
    typicalDuration  : Text;           // Expected contract lifetime
    liquidityTier    : LiquidityTier;
    riskTier         : RiskTier;
    correlationGroup : Text;           // Correlated contracts for risk
    exampleContract  : Text;           // Example instance
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // THE 58 WORLD CONTRACT ASSET CLASSES
  // Complete registry of all tradeable prediction types
  // ═══════════════════════════════════════════════════════════════════════════

  public func getAssetRegistry() : [PredictionAssetClass] {
    [
      // ─────────────────────────────────────────────────────────────────────
      // GEOPOLITICS & GOVERNANCE (CT-01 through CT-10)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-01"; name = "Election Outcome";
        category = "Geopolitics"; 
        description = "National, state, or local election results. Binary (winner) or categorical (vote share).";
        resolutionCriteria = "Official certified election results from national electoral authority.";
        oracleSources = ["AP Election Feed", "Reuters", "Official Electoral Commission"];
        typicalDuration = "30-365 days"; liquidityTier = #tier1_sovereign; riskTier = #medium;
        correlationGroup = "POLITICS"; exampleContract = "Will Party X win 2028 US Presidential Election?";
      },
      {
        code = "CT-02"; name = "Legislation Passage";
        category = "Geopolitics";
        description = "Whether a specific bill or law will pass in a legislative body.";
        resolutionCriteria = "Official legislative record showing bill signed into law or defeated.";
        oracleSources = ["Congress.gov", "Parliamentary Records", "Official Gazette"];
        typicalDuration = "30-180 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "POLITICS"; exampleContract = "Will EU AI Act Amendment pass by Q3 2026?";
      },
      {
        code = "CT-03"; name = "Treaty Ratification";
        category = "Geopolitics";
        description = "Whether an international treaty will be ratified by specified parties.";
        resolutionCriteria = "Official UN Treaty Database or national ratification instrument deposit.";
        oracleSources = ["UN Treaty Collection", "State Department", "Foreign Ministry"];
        typicalDuration = "90-730 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "POLITICS"; exampleContract = "Will India ratify RCEP by end of 2027?";
      },
      {
        code = "CT-04"; name = "Regime Change";
        category = "Geopolitics";
        description = "Change in head of state or government through any mechanism.";
        resolutionCriteria = "New head of state/government officially sworn in or de facto control confirmed by 3+ intl news agencies.";
        oracleSources = ["Reuters", "AP", "BBC World Service", "Official State Media"];
        typicalDuration = "90-365 days"; liquidityTier = #tier3_standard; riskTier = #extreme;
        correlationGroup = "POLITICS"; exampleContract = "Will Country X have a new leader before Dec 2026?";
      },
      {
        code = "CT-05"; name = "Sanctions Imposed";
        category = "Geopolitics";
        description = "Economic or trade sanctions imposed on a nation, entity, or individual.";
        resolutionCriteria = "Official publication in Federal Register, EU Official Journal, or UN Security Council resolution.";
        oracleSources = ["OFAC SDN List", "EU Sanctions Map", "UN SC Resolutions"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "POLITICS"; exampleContract = "Will US impose new sanctions on Country Y by Q2 2026?";
      },
      {
        code = "CT-06"; name = "Territorial Dispute Resolution";
        category = "Geopolitics";
        description = "Resolution or escalation of territorial/border disputes.";
        resolutionCriteria = "ICJ ruling, bilateral agreement signed, or de facto control change confirmed by satellite imagery.";
        oracleSources = ["ICJ Decisions", "UN Cartographic", "Satellite Analytics"];
        typicalDuration = "180-1095 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "CONFLICT"; exampleContract = "Will ICJ rule on Dispute Z by 2027?";
      },
      {
        code = "CT-07"; name = "International Conflict";
        category = "Geopolitics";
        description = "Armed conflict escalation, de-escalation, or ceasefire events.";
        resolutionCriteria = "UN Security Council ceasefire resolution, or ACLED conflict intensity data crossing threshold.";
        oracleSources = ["ACLED", "Uppsala Conflict Data", "UN OCHA"];
        typicalDuration = "30-365 days"; liquidityTier = #tier2_major; riskTier = #extreme;
        correlationGroup = "CONFLICT"; exampleContract = "Will a ceasefire be declared in Conflict A by Q4 2026?";
      },
      {
        code = "CT-08"; name = "Diplomatic Recognition";
        category = "Geopolitics";
        description = "One state officially recognizing another state or entity.";
        resolutionCriteria = "Official diplomatic note or embassy establishment confirmed by both parties.";
        oracleSources = ["State Department", "Foreign Ministry Gazette", "UN Credentials Committee"];
        typicalDuration = "90-730 days"; liquidityTier = #tier4_emerging; riskTier = #high;
        correlationGroup = "POLITICS"; exampleContract = "Will Country A recognize State B by end 2027?";
      },
      {
        code = "CT-09"; name = "Trade Agreement";
        category = "Geopolitics";
        description = "Completion or collapse of bilateral/multilateral trade deals.";
        resolutionCriteria = "Official signing ceremony and text publication by all parties.";
        oracleSources = ["WTO Notifications", "USTR", "EU Trade Commissioner"];
        typicalDuration = "90-730 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "ECONOMICS"; exampleContract = "Will US-UK trade deal be signed by 2027?";
      },
      {
        code = "CT-10"; name = "Regulatory Action";
        category = "Geopolitics";
        description = "Regulatory body decisions (SEC enforcement, EU antitrust, FDA approval).";
        resolutionCriteria = "Official regulatory body publication of decision/order.";
        oracleSources = ["SEC EDGAR", "EU Competition DG", "FDA Approvals Database"];
        typicalDuration = "30-365 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "REGULATION"; exampleContract = "Will SEC approve spot ETH ETF by Q1 2026?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // ECONOMICS & FINANCE (CT-11 through CT-20)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-11"; name = "Interest Rate Decision";
        category = "Economics";
        description = "Central bank rate decisions (Fed, ECB, BoJ, BoE, PBoC).";
        resolutionCriteria = "Official central bank press release stating new rate or hold decision.";
        oracleSources = ["Federal Reserve", "ECB", "BoJ", "Bloomberg Terminal"];
        typicalDuration = "7-90 days"; liquidityTier = #tier1_sovereign; riskTier = #low;
        correlationGroup = "RATES"; exampleContract = "Will Fed cut rates at June 2026 FOMC meeting?";
      },
      {
        code = "CT-12"; name = "GDP Growth";
        category = "Economics";
        description = "Quarterly or annual GDP growth above/below specified threshold.";
        resolutionCriteria = "Official national statistics office final GDP release (not preliminary).";
        oracleSources = ["BEA", "Eurostat", "ONS", "OECD Database"];
        typicalDuration = "30-180 days"; liquidityTier = #tier1_sovereign; riskTier = #low;
        correlationGroup = "MACRO"; exampleContract = "Will US Q2 2026 GDP growth exceed 2.5%?";
      },
      {
        code = "CT-13"; name = "Inflation Rate";
        category = "Economics";
        description = "CPI or PCE inflation reading above/below target level.";
        resolutionCriteria = "Official BLS/Eurostat CPI release for the specified period.";
        oracleSources = ["BLS CPI", "Eurostat HICP", "BoJ CPI"];
        typicalDuration = "14-90 days"; liquidityTier = #tier1_sovereign; riskTier = #low;
        correlationGroup = "MACRO"; exampleContract = "Will US CPI YoY exceed 3.0% in May 2026?";
      },
      {
        code = "CT-14"; name = "Unemployment Rate";
        category = "Economics";
        description = "Employment/unemployment data hitting specified levels.";
        resolutionCriteria = "Official BLS/Eurostat employment situation release.";
        oracleSources = ["BLS Employment", "Eurostat Labour", "ILO"];
        typicalDuration = "14-90 days"; liquidityTier = #tier1_sovereign; riskTier = #low;
        correlationGroup = "MACRO"; exampleContract = "Will US unemployment exceed 4.5% in June 2026?";
      },
      {
        code = "CT-15"; name = "Stock Index Level";
        category = "Economics";
        description = "Major stock index closing above/below specified level.";
        resolutionCriteria = "Official exchange closing price on specified date.";
        oracleSources = ["NYSE", "NASDAQ", "LSE", "Bloomberg"];
        typicalDuration = "1-90 days"; liquidityTier = #tier1_sovereign; riskTier = #medium;
        correlationGroup = "EQUITIES"; exampleContract = "Will S&P 500 close above 6000 by end Q2 2026?";
      },
      {
        code = "CT-16"; name = "Commodity Price";
        category = "Economics";
        description = "Commodity (gold, oil, wheat, copper) hitting price target.";
        resolutionCriteria = "COMEX/NYMEX/LME official settlement price on specified date.";
        oracleSources = ["CME Group", "LME", "ICE Futures"];
        typicalDuration = "1-180 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "COMMODITIES"; exampleContract = "Will gold exceed $3000/oz by end 2026?";
      },
      {
        code = "CT-17"; name = "Currency Exchange Rate";
        category = "Economics";
        description = "FX pair reaching specified level or range.";
        resolutionCriteria = "WM/Refinitiv 4PM London fix on specified date.";
        oracleSources = ["Refinitiv", "Bloomberg FX", "ECB Reference Rates"];
        typicalDuration = "1-90 days"; liquidityTier = #tier1_sovereign; riskTier = #medium;
        correlationGroup = "FX"; exampleContract = "Will EUR/USD trade below 1.05 in Q3 2026?";
      },
      {
        code = "CT-18"; name = "Bond Yield";
        category = "Economics";
        description = "Sovereign bond yield hitting target level.";
        resolutionCriteria = "Official Treasury/Gilt auction result or secondary market close.";
        oracleSources = ["US Treasury", "Bundesbank", "BoE", "Bloomberg"];
        typicalDuration = "7-180 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "RATES"; exampleContract = "Will US 10Y yield exceed 5% by end 2026?";
      },
      {
        code = "CT-19"; name = "IPO Valuation";
        category = "Economics";
        description = "Company IPO pricing above/below market cap target.";
        resolutionCriteria = "Official IPO pricing from lead underwriter press release.";
        oracleSources = ["SEC S-1 Filing", "Exchange Listing Notice", "Bloomberg"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "EQUITIES"; exampleContract = "Will Company X IPO above $50B valuation?";
      },
      {
        code = "CT-20"; name = "Recession Probability";
        category = "Economics";
        description = "Whether a recession (2 consecutive negative GDP quarters) occurs.";
        resolutionCriteria = "NBER official recession dating or 2 consecutive negative real GDP quarters.";
        oracleSources = ["NBER", "BEA GDP", "CEPR Euro Area"];
        typicalDuration = "90-365 days"; liquidityTier = #tier2_major; riskTier = #high;
        correlationGroup = "MACRO"; exampleContract = "Will US enter recession before end 2027?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // TECHNOLOGY & SCIENCE (CT-21 through CT-30)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-21"; name = "AI Milestone";
        category = "Technology";
        description = "Artificial intelligence achieving specified benchmark or capability.";
        resolutionCriteria = "Peer-reviewed publication or official benchmark leaderboard update.";
        oracleSources = ["arXiv", "Papers With Code", "MLCommons", "Official Company Blog"];
        typicalDuration = "30-365 days"; liquidityTier = #tier2_major; riskTier = #high;
        correlationGroup = "TECH"; exampleContract = "Will an AI system pass ARC-AGI-2 by end 2026?";
      },
      {
        code = "CT-22"; name = "Product Launch";
        category = "Technology";
        description = "Major tech product shipping on announced date or within timeframe.";
        resolutionCriteria = "Product publicly available for purchase/download confirmed by official source.";
        oracleSources = ["Official Product Page", "App Store Listing", "Press Release"];
        typicalDuration = "30-365 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "TECH"; exampleContract = "Will Apple ship Vision Pro 2 by Q4 2026?";
      },
      {
        code = "CT-23"; name = "Scientific Discovery";
        category = "Technology";
        description = "Major scientific breakthrough verified and published.";
        resolutionCriteria = "Publication in Nature, Science, or equivalent top-tier journal with peer review.";
        oracleSources = ["Nature", "Science", "PubMed", "arXiv (for preprints)"];
        typicalDuration = "90-730 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "SCIENCE"; exampleContract = "Will room-temperature superconductor be verified by 2027?";
      },
      {
        code = "CT-24"; name = "Patent Grant";
        category = "Technology";
        description = "Specific patent application being granted or rejected.";
        resolutionCriteria = "USPTO/EPO official grant publication or final rejection notice.";
        oracleSources = ["USPTO PAIR", "EPO Register", "WIPO PatentScope"];
        typicalDuration = "90-730 days"; liquidityTier = #tier5_exotic; riskTier = #medium;
        correlationGroup = "TECH"; exampleContract = "Will Patent App X be granted by Q2 2027?";
      },
      {
        code = "CT-25"; name = "Space Mission";
        category = "Technology";
        description = "Space mission success, failure, or milestone achievement.";
        resolutionCriteria = "Official space agency press release confirming mission outcome.";
        oracleSources = ["NASA", "ESA", "SpaceX Updates", "CNSA"];
        typicalDuration = "30-730 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "SPACE"; exampleContract = "Will Artemis III land on Moon by end 2027?";
      },
      {
        code = "CT-26"; name = "Quantum Computing Milestone";
        category = "Technology";
        description = "Quantum computer achieving specified qubit count or error correction milestone.";
        resolutionCriteria = "Peer-reviewed publication or official company demonstration with verification.";
        oracleSources = ["Nature Physics", "IBM Quantum", "Google AI Blog", "arXiv"];
        typicalDuration = "90-730 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "TECH"; exampleContract = "Will a 1000+ logical qubit system be demonstrated by 2027?";
      },
      {
        code = "CT-27"; name = "Clinical Trial";
        category = "Technology";
        description = "Drug or therapy clinical trial meeting primary endpoint.";
        resolutionCriteria = "ClinicalTrials.gov results posting or FDA advisory committee vote.";
        oracleSources = ["ClinicalTrials.gov", "FDA CDER", "EMA", "Company IR"];
        typicalDuration = "90-730 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "BIOTECH"; exampleContract = "Will Drug X Phase III meet primary endpoint?";
      },
      {
        code = "CT-28"; name = "Tech Acquisition";
        category = "Technology";
        description = "Major technology M&A deal completion or failure.";
        resolutionCriteria = "Official SEC filing (8-K) confirming deal close or termination.";
        oracleSources = ["SEC EDGAR", "FTC/DOJ Announcements", "Company IR"];
        typicalDuration = "30-365 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "TECH"; exampleContract = "Will Acquisition X close by regulatory deadline?";
      },
      {
        code = "CT-29"; name = "Open Source Milestone";
        category = "Technology";
        description = "OSS project reaching specified star count, contributor count, or adoption metric.";
        resolutionCriteria = "GitHub/GitLab public repository metrics on specified date.";
        oracleSources = ["GitHub API", "npm downloads", "PyPI stats", "Docker Hub"];
        typicalDuration = "30-365 days"; liquidityTier = #tier5_exotic; riskTier = #low;
        correlationGroup = "TECH"; exampleContract = "Will Project X reach 100k GitHub stars by end 2026?";
      },
      {
        code = "CT-30"; name = "Cybersecurity Event";
        category = "Technology";
        description = "Major data breach, hack, or cyber attack exceeding specified impact.";
        resolutionCriteria = "Official breach disclosure filing or CISA advisory publication.";
        oracleSources = ["CISA Advisories", "HaveIBeenPwned", "SEC 8-K Filings"];
        typicalDuration = "30-180 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "CYBER"; exampleContract = "Will a breach affecting >100M users occur in H1 2026?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // CLIMATE & ENVIRONMENT (CT-31 through CT-38)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-31"; name = "Temperature Anomaly";
        category = "Climate";
        description = "Global or regional temperature anomaly exceeding threshold.";
        resolutionCriteria = "NASA GISS or NOAA official monthly/annual temperature anomaly report.";
        oracleSources = ["NASA GISS", "NOAA NCEI", "HadCRUT", "Copernicus C3S"];
        typicalDuration = "30-365 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "CLIMATE"; exampleContract = "Will 2026 be hottest year on record (NASA GISS)?";
      },
      {
        code = "CT-32"; name = "Natural Disaster";
        category = "Climate";
        description = "Hurricane, earthquake, volcano, or flood exceeding magnitude threshold.";
        resolutionCriteria = "USGS/NHC/NOAA official measurement of event magnitude.";
        oracleSources = ["USGS Earthquake", "NHC/NOAA", "EMDAT", "GDACS"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #extreme;
        correlationGroup = "CLIMATE"; exampleContract = "Will a Cat 5 hurricane make US landfall in 2026?";
      },
      {
        code = "CT-33"; name = "Emissions Target";
        category = "Climate";
        description = "Country or organization meeting stated emissions reduction goal.";
        resolutionCriteria = "Official UNFCCC National Inventory Report or verified third-party audit.";
        oracleSources = ["UNFCCC", "Global Carbon Project", "Climate Action Tracker"];
        typicalDuration = "180-730 days"; liquidityTier = #tier4_emerging; riskTier = #high;
        correlationGroup = "CLIMATE"; exampleContract = "Will EU meet 55% emissions reduction target by 2030?";
      },
      {
        code = "CT-34"; name = "Sea Level Rise";
        category = "Climate";
        description = "Sea level measurement at specified location exceeding threshold.";
        resolutionCriteria = "NOAA/Copernicus satellite altimetry annual mean sea level report.";
        oracleSources = ["NOAA Sea Level", "Copernicus Marine", "NASA Sea Level Portal"];
        typicalDuration = "365-1095 days"; liquidityTier = #tier5_exotic; riskTier = #low;
        correlationGroup = "CLIMATE"; exampleContract = "Will global mean sea level rise exceed 4mm/yr average?";
      },
      {
        code = "CT-35"; name = "Deforestation Rate";
        category = "Climate";
        description = "Deforestation in specified region above/below annual rate.";
        resolutionCriteria = "Global Forest Watch annual alert data or INPE PRODES report.";
        oracleSources = ["Global Forest Watch", "INPE PRODES", "FAO FRA"];
        typicalDuration = "180-365 days"; liquidityTier = #tier5_exotic; riskTier = #medium;
        correlationGroup = "CLIMATE"; exampleContract = "Will Amazon deforestation decrease YoY in 2026?";
      },
      {
        code = "CT-36"; name = "Renewable Energy Adoption";
        category = "Climate";
        description = "Renewable energy reaching percentage of total generation in a region.";
        resolutionCriteria = "IEA or official national grid operator annual generation statistics.";
        oracleSources = ["IEA", "EIA", "IRENA", "National Grid Operators"];
        typicalDuration = "180-365 days"; liquidityTier = #tier4_emerging; riskTier = #low;
        correlationGroup = "ENERGY"; exampleContract = "Will US renewables exceed 30% of generation in 2026?";
      },
      {
        code = "CT-37"; name = "Arctic Ice Extent";
        category = "Climate";
        description = "Arctic sea ice minimum extent above/below specified threshold.";
        resolutionCriteria = "NSIDC official September minimum extent announcement.";
        oracleSources = ["NSIDC", "Copernicus C3S", "JAXA Sea Ice"];
        typicalDuration = "90-365 days"; liquidityTier = #tier5_exotic; riskTier = #medium;
        correlationGroup = "CLIMATE"; exampleContract = "Will 2026 Arctic minimum drop below 3.5M km²?";
      },
      {
        code = "CT-38"; name = "Carbon Credit Price";
        category = "Climate";
        description = "EU ETS or voluntary carbon credit price hitting target level.";
        resolutionCriteria = "ICE Futures Europe EUA settlement price on specified date.";
        oracleSources = ["ICE Futures Europe", "CBL Spot", "Verra Registry"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "COMMODITIES"; exampleContract = "Will EU ETS price exceed €100/ton by end 2026?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // CRYPTO & BLOCKCHAIN (CT-39 through CT-46)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-39"; name = "Token Price Target";
        category = "Crypto";
        description = "Cryptocurrency/token hitting specified price level.";
        resolutionCriteria = "CoinGecko/CoinMarketCap 24h VWAP on specified date.";
        oracleSources = ["CoinGecko API", "CoinMarketCap", "Binance", "Coinbase"];
        typicalDuration = "1-365 days"; liquidityTier = #tier1_sovereign; riskTier = #high;
        correlationGroup = "CRYPTO"; exampleContract = "Will BTC exceed $150K by end 2026?";
      },
      {
        code = "CT-40"; name = "Network Hashrate";
        category = "Crypto";
        description = "Blockchain network hashrate hitting specified threshold.";
        resolutionCriteria = "Official blockchain explorer 7-day average hashrate reading.";
        oracleSources = ["Blockchain.com", "Mempool.space", "Etherscan"];
        typicalDuration = "30-180 days"; liquidityTier = #tier4_emerging; riskTier = #medium;
        correlationGroup = "CRYPTO"; exampleContract = "Will BTC hashrate exceed 800 EH/s in 2026?";
      },
      {
        code = "CT-41"; name = "Protocol Upgrade";
        category = "Crypto";
        description = "Blockchain protocol upgrade/hard fork activation on mainnet.";
        resolutionCriteria = "Block height at which upgrade activates, confirmed by multiple node operators.";
        oracleSources = ["Official Protocol GitHub", "Block Explorers", "Core Dev Announcements"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #medium;
        correlationGroup = "CRYPTO"; exampleContract = "Will Ethereum Pectra upgrade activate by Q3 2026?";
      },
      {
        code = "CT-42"; name = "DeFi TVL";
        category = "Crypto";
        description = "DeFi protocol or chain total value locked above/below threshold.";
        resolutionCriteria = "DefiLlama TVL reading at UTC midnight on specified date.";
        oracleSources = ["DefiLlama", "DeFi Pulse", "L2Beat"];
        typicalDuration = "30-180 days"; liquidityTier = #tier3_standard; riskTier = #high;
        correlationGroup = "CRYPTO"; exampleContract = "Will Ethereum DeFi TVL exceed $200B by end 2026?";
      },
      {
        code = "CT-43"; name = "NFT Floor Price";
        category = "Crypto";
        description = "NFT collection floor price hitting specified level.";
        resolutionCriteria = "OpenSea/Blur 24h floor price on specified date.";
        oracleSources = ["OpenSea API", "Blur", "NFTGo"];
        typicalDuration = "7-90 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "CRYPTO"; exampleContract = "Will CryptoPunks floor exceed 100 ETH in Q3 2026?";
      },
      {
        code = "CT-44"; name = "Chain TPS Milestone";
        category = "Crypto";
        description = "Blockchain achieving sustained transactions-per-second milestone.";
        resolutionCriteria = "Official block explorer showing sustained TPS over 24h period.";
        oracleSources = ["Block Explorer", "TPS Benchmark Sites", "Network Dashboard"];
        typicalDuration = "30-365 days"; liquidityTier = #tier4_emerging; riskTier = #medium;
        correlationGroup = "CRYPTO"; exampleContract = "Will Solana sustain >10K TPS for 24h in 2026?";
      },
      {
        code = "CT-45"; name = "Bridge Exploit";
        category = "Crypto";
        description = "Cross-chain bridge hack/exploit exceeding dollar threshold.";
        resolutionCriteria = "Rekt.news or official bridge post-mortem confirming loss amount.";
        oracleSources = ["Rekt.news", "DeFi Safety", "Official Bridge Announcements"];
        typicalDuration = "30-180 days"; liquidityTier = #tier4_emerging; riskTier = #extreme;
        correlationGroup = "CRYPTO"; exampleContract = "Will a bridge exploit >$100M occur in H2 2026?";
      },
      {
        code = "CT-46"; name = "Halving Price Effect";
        category = "Crypto";
        description = "Post-halving price behavior within specified timeframe.";
        resolutionCriteria = "CoinGecko closing price at specified number of days post-halving.";
        oracleSources = ["CoinGecko", "Glassnode", "On-chain Analytics"];
        typicalDuration = "90-545 days"; liquidityTier = #tier2_major; riskTier = #high;
        correlationGroup = "CRYPTO"; exampleContract = "Will BTC 18-month post-halving price exceed $200K?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // SPORTS & ENTERTAINMENT (CT-47 through CT-53)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-47"; name = "Sport Match Outcome";
        category = "Sports";
        description = "Individual game/match winner or final score range.";
        resolutionCriteria = "Official league/federation final score publication.";
        oracleSources = ["ESPN", "Official League API", "BBC Sport"];
        typicalDuration = "1-14 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "SPORTS"; exampleContract = "Will Team X win the 2026 World Cup Final?";
      },
      {
        code = "CT-48"; name = "Championship Winner";
        category = "Sports";
        description = "Season/tournament ultimate winner.";
        resolutionCriteria = "Official league/federation championship result.";
        oracleSources = ["Official League", "ESPN", "FIFA/UEFA/IOC"];
        typicalDuration = "30-365 days"; liquidityTier = #tier2_major; riskTier = #medium;
        correlationGroup = "SPORTS"; exampleContract = "Will Club Y win Champions League 2026/27?";
      },
      {
        code = "CT-49"; name = "Box Office Revenue";
        category = "Entertainment";
        description = "Film/show revenue exceeding threshold in specified timeframe.";
        resolutionCriteria = "Box Office Mojo/The Numbers official gross report.";
        oracleSources = ["Box Office Mojo", "The Numbers", "Comscore"];
        typicalDuration = "7-90 days"; liquidityTier = #tier4_emerging; riskTier = #medium;
        correlationGroup = "ENTERTAINMENT"; exampleContract = "Will Film X gross >$1B worldwide?";
      },
      {
        code = "CT-50"; name = "Awards Ceremony";
        category = "Entertainment";
        description = "Awards show category winner (Oscars, Grammys, etc.).";
        resolutionCriteria = "Official academy/organization winner announcement.";
        oracleSources = ["Official Academy", "Variety", "Hollywood Reporter"];
        typicalDuration = "30-180 days"; liquidityTier = #tier4_emerging; riskTier = #high;
        correlationGroup = "ENTERTAINMENT"; exampleContract = "Will Film Y win Best Picture at 2027 Oscars?";
      },
      {
        code = "CT-51"; name = "Streaming Milestone";
        category = "Entertainment";
        description = "Content reaching specified viewer/subscriber count.";
        resolutionCriteria = "Official platform report or verified third-party analytics.";
        oracleSources = ["Netflix Top 10", "Spotify Charts", "YouTube Analytics"];
        typicalDuration = "7-90 days"; liquidityTier = #tier5_exotic; riskTier = #medium;
        correlationGroup = "ENTERTAINMENT"; exampleContract = "Will Show X reach 100M views in first 28 days?";
      },
      {
        code = "CT-52"; name = "Esports Tournament Result";
        category = "Sports";
        description = "Esports tournament/major winner.";
        resolutionCriteria = "Official tournament organizer results page.";
        oracleSources = ["Liquipedia", "HLTV", "Official Tournament"];
        typicalDuration = "1-30 days"; liquidityTier = #tier4_emerging; riskTier = #medium;
        correlationGroup = "SPORTS"; exampleContract = "Will Team Z win TI 2026?";
      },
      {
        code = "CT-53"; name = "Athletic World Record";
        category = "Sports";
        description = "World record broken in specified sport/event within timeframe.";
        resolutionCriteria = "Official world athletics/sport federation record ratification.";
        oracleSources = ["World Athletics", "FINA", "Official Federation"];
        typicalDuration = "30-365 days"; liquidityTier = #tier5_exotic; riskTier = #extreme;
        correlationGroup = "SPORTS"; exampleContract = "Will 100m record be broken at 2026 Worlds?";
      },

      // ─────────────────────────────────────────────────────────────────────
      // DEMOGRAPHICS & SOCIETY (CT-54 through CT-58)
      // ─────────────────────────────────────────────────────────────────────
      {
        code = "CT-54"; name = "Population Milestone";
        category = "Demographics";
        description = "Country/city/world population crossing specified threshold.";
        resolutionCriteria = "UN Population Division or official national census data.";
        oracleSources = ["UN DESA", "World Bank", "National Census Bureau"];
        typicalDuration = "180-730 days"; liquidityTier = #tier5_exotic; riskTier = #low;
        correlationGroup = "DEMOGRAPHICS"; exampleContract = "Will India census 2027 show >1.5B population?";
      },
      {
        code = "CT-55"; name = "Migration Flow";
        category = "Demographics";
        description = "Migration numbers in/out of region exceeding annual threshold.";
        resolutionCriteria = "Official immigration service annual report or UNHCR data.";
        oracleSources = ["UNHCR", "IOM", "National Immigration Service"];
        typicalDuration = "180-365 days"; liquidityTier = #tier5_exotic; riskTier = #medium;
        correlationGroup = "DEMOGRAPHICS"; exampleContract = "Will US immigration exceed 2M in FY2026?";
      },
      {
        code = "CT-56"; name = "Public Health Event";
        category = "Demographics";
        description = "Pandemic/epidemic declaration or health emergency status.";
        resolutionCriteria = "WHO official PHEIC declaration or national health emergency.";
        oracleSources = ["WHO", "CDC", "ECDC", "National Health Ministries"];
        typicalDuration = "30-365 days"; liquidityTier = #tier3_standard; riskTier = #extreme;
        correlationGroup = "HEALTH"; exampleContract = "Will WHO declare new PHEIC in 2026?";
      },
      {
        code = "CT-57"; name = "Education Metric";
        category = "Demographics";
        description = "Education enrollment, literacy, or achievement milestone.";
        resolutionCriteria = "UNESCO Institute for Statistics or national education ministry report.";
        oracleSources = ["UNESCO UIS", "World Bank Education", "OECD PISA"];
        typicalDuration = "365-730 days"; liquidityTier = #tier5_exotic; riskTier = #low;
        correlationGroup = "DEMOGRAPHICS"; exampleContract = "Will global adult literacy exceed 90% by 2027?";
      },
      {
        code = "CT-58"; name = "Urbanization Rate";
        category = "Demographics";
        description = "Urban population percentage crossing threshold in specified country.";
        resolutionCriteria = "UN World Urbanization Prospects or national statistics office.";
        oracleSources = ["UN DESA", "World Bank", "National Statistics"];
        typicalDuration = "365-1095 days"; liquidityTier = #tier5_exotic; riskTier = #low;
        correlationGroup = "DEMOGRAPHICS"; exampleContract = "Will Africa urbanization exceed 50% by 2028?";
      }
    ]
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY SUMMARY COUNTS
  // ═══════════════════════════════════════════════════════════════════════════

  public let TOTAL_ASSET_CLASSES : Nat = 58;
  public let GEOPOLITICS_COUNT : Nat = 10;
  public let ECONOMICS_COUNT : Nat = 10;
  public let TECHNOLOGY_COUNT : Nat = 10;
  public let CLIMATE_COUNT : Nat = 8;
  public let CRYPTO_COUNT : Nat = 8;
  public let SPORTS_COUNT : Nat = 7;
  public let DEMOGRAPHICS_COUNT : Nat = 5;

  // Fibonacci-derived base liquidity values per tier
  public func tierLiquidity(tier : LiquidityTier) : Float {
    switch (tier) {
      case (#tier1_sovereign) { 10946.0 };  // F(21)
      case (#tier2_major)     { 6765.0 };   // F(20)
      case (#tier3_standard)  { 4181.0 };   // F(19)
      case (#tier4_emerging)  { 2584.0 };   // F(18)
      case (#tier5_exotic)    { 1597.0 };   // F(17)
    }
  };

}
