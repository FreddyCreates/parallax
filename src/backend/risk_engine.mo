import Array "mo:core/Array";
import Float "mo:core/Float";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import Text "mo:core/Text";

module {

  public type Greeks = {
    delta : Float;
    gamma : Float;
    vega : Float;
    theta : Float;
    rho : Float;
  };

  public type PositionSnapshot = {
    principal : Text;
    tokenCode : Text;
    netPosition : Float;
    grossBought : Float;
    grossSold : Float;
    marginUsed : Float;
    lastUpdateBeat : Int;
  };

  public type ExposureSnapshot = {
    principal : Text;
    totalExposure : Float;
    netExposure : Float;
    marginRatio : Float;
    maxAllowedExposure : Float;
    isOverExposed : Bool;
    lastCheckBeat : Int;
  };

  public type GuaranteeFundSnapshot = {
    totalReserveICP : Float;
    totalReserveBTC : Float;
    totalReserveETH : Float;
    totalReserveMTC : Float;
    utilizationRatio : Float;
    coverageRatio : Float;
    lastTopUpBeat : Int;
    guaranteesIssued : Nat;
    guaranteesFailed : Nat;
  };

  public type SettlementSnapshot = {
    settlementId : Nat;
    pairId : Text;
    partyA : Text;
    partyB : Text;
    baseToken : Text;
    quoteToken : Text;
    baseAmount : Float;
    quoteAmount : Float;
    settlementBeat : Int;
  };

  public type PositionRiskMetric = {
    principal : Text;
    tokenCode : Text;
    notionalExposure : Float;
    netPosition : Float;
    concentrationRatio : Float;
    leverage : Float;
    positionLimitBreached : Bool;
    concentrationBreached : Bool;
    leverageBreached : Bool;
    notionalLimitBreached : Bool;
    greeks : Greeks;
  };

  public type CorrelationBreakdown = {
    tokenA : Text;
    tokenB : Text;
    estimatedCorrelation : Float;
    concentrationContribution : Float;
    breakdownFlag : Bool;
  };

  public type ScenarioResult = {
    scenarioName : Text;
    shockPercent : Float;
    estimatedPnLImpact : Float;
    breached : Bool;
  };

  public type SensitivityResult = {
    factor : Text;
    upShockImpact : Float;
    downShockImpact : Float;
    sensitivityScore : Float;
  };

  public type MarketRiskMetrics = {
    historicalVaR : Float;
    parametricVaR : Float;
    monteCarloVaR : Float;
    stressScenarios : [ScenarioResult];
    scenarioAnalysis : [ScenarioResult];
    sensitivityAnalysis : [SensitivityResult];
    correlationBreakdown : [CorrelationBreakdown];
  };

  public type CounterpartyRiskMetric = {
    principal : Text;
    exposure : Float;
    exposureLimit : Float;
    exposureBreached : Bool;
    creditScore : Nat;
    collateralHeld : Float;
    marginRequired : Float;
    defaultProbability : Float;
  };

  public type CreditRiskMetrics = {
    counterparties : [CounterpartyRiskMetric];
    totalCollateralHeld : Float;
    totalMarginRequired : Float;
    marginBuffer : Float;
    weightedDefaultProbability : Float;
  };

  public type MarketDepthMetric = {
    tokenCode : Text;
    depthScore : Float;
    estimatedTimeToLiquidate : Float;
    turnover : Float;
  };

  public type LiquidityRiskMetrics = {
    liquidityAdjustedVaR : Float;
    liquidityCoverageRatio : Float;
    timeToLiquidate : Float;
    marketDepth : [MarketDepthMetric];
    fundingGap : Float;
    fundingStressFlag : Bool;
  };

  public type RiskEvent = {
    eventId : Nat;
    category : Text;
    severity : Text;
    message : Text;
    beat : Int;
  };

  public type RiskAlert = {
    principal : Text;
    category : Text;
    subject : Text;
    severity : Text;
    value : Float;
    limit : Float;
    message : Text;
    beat : Int;
  };

  public type MitigationAction = {
    action : Text;
    target : Text;
    reason : Text;
    severity : Text;
    automated : Bool;
  };

  public type ExposureDashboardEntry = {
    principal : Text;
    grossExposure : Float;
    netExposure : Float;
    utilizationRatio : Float;
    marginRatio : Float;
    activeBreaches : Nat;
    livePnL : Float;
  };

  public type OperationalRiskMetrics = {
    systemFailureScenario : Bool;
    oracleFailureHandling : Bool;
    circuitBreakerActive : Bool;
    emergencyShutdownActive : Bool;
    lastEventId : Nat;
    totalRiskEvents : Nat;
  };

  public type MonitoringMetrics = {
    livePnL : Float;
    realizedPnL : Float;
    unrealizedPnL : Float;
    exposureDashboard : [ExposureDashboardEntry];
    alerts : [RiskAlert];
    automatedMitigations : [MitigationAction];
    breachCount : Nat;
    lastDashboardBeat : Int;
  };

  public type RiskConfig = {
    maxPositionNotional : Float;
    maxConcentrationRatio : Float;
    maxLeverage : Float;
    maxNotionalPerPrincipal : Float;
    maxCounterpartyExposure : Float;
    minMarginRatio : Float;
    minLiquidityCoverageRatio : Float;
    circuitBreakerVaRThreshold : Float;
    emergencyCoverageThreshold : Float;
    alertRetention : Nat;
    eventRetention : Nat;
  };

  public type RiskEngineState = {
    config : RiskConfig;
    positionRisk : [PositionRiskMetric];
    greeksByPrincipal : [(Text, Greeks)];
    marketRisk : MarketRiskMetrics;
    creditRisk : CreditRiskMetrics;
    liquidityRisk : LiquidityRiskMetrics;
    operationalRisk : OperationalRiskMetrics;
    monitoring : MonitoringMetrics;
    eventLog : [RiskEvent];
    lastUpdateBeat : Int;
    aggregateRiskScore : Float;
  };

  type OperationalBuild = {
    metrics : OperationalRiskMetrics;
    events : [RiskEvent];
    alerts : [RiskAlert];
  };

  public func defaultRiskEngineState() : RiskEngineState {
    {
      config = defaultRiskConfig();
      positionRisk = [];
      greeksByPrincipal = [];
      marketRisk = defaultMarketRiskMetrics();
      creditRisk = defaultCreditRiskMetrics();
      liquidityRisk = defaultLiquidityRiskMetrics();
      operationalRisk = {
        systemFailureScenario = false;
        oracleFailureHandling = true;
        circuitBreakerActive = false;
        emergencyShutdownActive = false;
        lastEventId = 0;
        totalRiskEvents = 0;
      };
      monitoring = {
        livePnL = 0.0;
        realizedPnL = 0.0;
        unrealizedPnL = 0.0;
        exposureDashboard = [];
        alerts = [];
        automatedMitigations = [];
        breachCount = 0;
        lastDashboardBeat = 0;
      };
      eventLog = [];
      lastUpdateBeat = 0;
      aggregateRiskScore = 0.0;
    }
  };

  public func assessRisk(
    state : RiskEngineState,
    positions : [PositionSnapshot],
    exposures : [ExposureSnapshot],
    guaranteeFund : GuaranteeFundSnapshot,
    settlements : [SettlementSnapshot],
    beat : Int,
  ) : RiskEngineState {
    let positionRisk = buildPositionRisk(state.config, positions, exposures);
    let greeksByPrincipal = aggregateGreeks(positionRisk);
    let marketRisk = buildMarketRisk(positionRisk, greeksByPrincipal, settlements, guaranteeFund);
    let creditRisk = buildCreditRisk(state.config, exposures, guaranteeFund, marketRisk);
    let liquidityRisk = buildLiquidityRisk(state.config, positions, settlements, guaranteeFund, marketRisk, creditRisk);

    let positionAlerts = buildPositionAlerts(state.config, positionRisk, exposures, beat);
    let creditAlerts = buildCreditAlerts(creditRisk.counterparties, beat);
    let liquidityAlerts = buildLiquidityAlerts(state.config, liquidityRisk, beat);

    let baseAlertCount = positionAlerts.size() + creditAlerts.size() + liquidityAlerts.size();
    let operationalBuild = buildOperationalRisk(
      state.operationalRisk,
      state.config,
      marketRisk,
      creditRisk,
      liquidityRisk,
      guaranteeFund,
      beat,
      baseAlertCount,
    );

    let allAlerts = appendAlerts(
      state.monitoring.alerts,
      Array.concat(positionAlerts, Array.concat(creditAlerts, Array.concat(liquidityAlerts, operationalBuild.alerts))),
      state.config.alertRetention,
    );
    let mitigations = buildMitigations(positionRisk, creditRisk, liquidityRisk, operationalBuild.metrics, allAlerts);
    let monitoring = buildMonitoring(exposures, marketRisk, liquidityRisk, allAlerts, mitigations, beat);

    let eventLog = appendEvents(state.eventLog, operationalBuild.events, state.config.eventRetention);
    let aggregateRiskScore = clamp(
      (normalizeRisk(marketRisk.parametricVaR, 500.0) * 0.3) +
      (normalizeRisk(liquidityRisk.liquidityAdjustedVaR, 600.0) * 0.2) +
      (normalizeRisk(creditRisk.totalMarginRequired, 400.0) * 0.15) +
      (normalizeRisk(natToFloat(monitoring.breachCount), 20.0) * 0.15) +
      (if (operationalBuild.metrics.circuitBreakerActive) 0.12 else 0.0) +
      (if (operationalBuild.metrics.emergencyShutdownActive) 0.08 else 0.0),
      0.0,
      1.0,
    );

    {
      state with
      positionRisk = positionRisk;
      greeksByPrincipal = greeksByPrincipal;
      marketRisk = marketRisk;
      creditRisk = creditRisk;
      liquidityRisk = liquidityRisk;
      operationalRisk = operationalBuild.metrics;
      monitoring = monitoring;
      eventLog = eventLog;
      lastUpdateBeat = beat;
      aggregateRiskScore = aggregateRiskScore;
    }
  };

  func defaultRiskConfig() : RiskConfig {
    {
      maxPositionNotional = 250000.0;
      maxConcentrationRatio = 0.35;
      maxLeverage = 4.0;
      maxNotionalPerPrincipal = 500000.0;
      maxCounterpartyExposure = 350000.0;
      minMarginRatio = 0.2;
      minLiquidityCoverageRatio = 1.15;
      circuitBreakerVaRThreshold = 150000.0;
      emergencyCoverageThreshold = 0.95;
      alertRetention = 128;
      eventRetention = 256;
    }
  };

  func defaultMarketRiskMetrics() : MarketRiskMetrics {
    {
      historicalVaR = 0.0;
      parametricVaR = 0.0;
      monteCarloVaR = 0.0;
      stressScenarios = [];
      scenarioAnalysis = [];
      sensitivityAnalysis = [];
      correlationBreakdown = [];
    }
  };

  func defaultCreditRiskMetrics() : CreditRiskMetrics {
    {
      counterparties = [];
      totalCollateralHeld = 0.0;
      totalMarginRequired = 0.0;
      marginBuffer = 0.0;
      weightedDefaultProbability = 0.0;
    }
  };

  func defaultLiquidityRiskMetrics() : LiquidityRiskMetrics {
    {
      liquidityAdjustedVaR = 0.0;
      liquidityCoverageRatio = 0.0;
      timeToLiquidate = 0.0;
      marketDepth = [];
      fundingGap = 0.0;
      fundingStressFlag = false;
    }
  };

  func buildPositionRisk(
    config : RiskConfig,
    positions : [PositionSnapshot],
    exposures : [ExposureSnapshot],
  ) : [PositionRiskMetric] {
    let totalNotional = Array.foldLeft<PositionSnapshot, Float>(positions, 0.0, func (acc, position) {
      acc + Float.abs(position.netPosition)
    });

    Array.map<PositionSnapshot, PositionRiskMetric>(positions, func (position) {
      let exposure = findExposure(exposures, position.principal);
      let notional = Float.abs(position.netPosition);
      let concentration = if (totalNotional > 0.0) notional / totalNotional else 0.0;
      let leverage = if (position.marginUsed > 0.0) notional / position.marginUsed else if (notional > 0.0) config.maxLeverage + 1.0 else 0.0;
      let greeks = estimateGreeks(position.tokenCode, position.netPosition, notional);
      let principalExposure = switch (exposure) {
        case (?snapshot) { snapshot.totalExposure };
        case null { notional };
      };
      {
        principal = position.principal;
        tokenCode = position.tokenCode;
        notionalExposure = notional;
        netPosition = position.netPosition;
        concentrationRatio = concentration;
        leverage = leverage;
        positionLimitBreached = notional > config.maxPositionNotional;
        concentrationBreached = concentration > config.maxConcentrationRatio;
        leverageBreached = leverage > config.maxLeverage;
        notionalLimitBreached = principalExposure > config.maxNotionalPerPrincipal;
        greeks = greeks;
      }
    })
  };

  func aggregateGreeks(positionRisk : [PositionRiskMetric]) : [(Text, Greeks)] {
    var aggregated : [(Text, Greeks)] = [];
    for (metric in positionRisk.vals()) {
      aggregated := upsertGreeks(aggregated, metric.principal, metric.greeks);
    };
    aggregated
  };

  func buildMarketRisk(
    positionRisk : [PositionRiskMetric],
    greeksByPrincipal : [(Text, Greeks)],
    settlements : [SettlementSnapshot],
    guaranteeFund : GuaranteeFundSnapshot,
  ) : MarketRiskMetrics {
    let grossExposure = Array.foldLeft<PositionRiskMetric, Float>(positionRisk, 0.0, func (acc, metric) {
      acc + metric.notionalExposure
    });
    let concentrationPenalty = Array.foldLeft<PositionRiskMetric, Float>(positionRisk, 0.0, func (acc, metric) {
      maxF(acc, metric.concentrationRatio)
    });
    let tradeTurnover = Array.foldLeft<SettlementSnapshot, Float>(settlements, 0.0, func (acc, settlement) {
      acc + settlement.quoteAmount
    });
    let realizedShock = if (settlements.size() > 0) maxF((tradeTurnover / natToFloat(settlements.size())) * 0.07, grossExposure * 0.025) else grossExposure * 0.02;
    let reserveStress = if (guaranteeFund.coverageRatio < 1.0) (1.0 - guaranteeFund.coverageRatio) * 0.1 else 0.0;
    let historicalVaR = realizedShock * (1.0 + concentrationPenalty);
    let parametricVaR = grossExposure * (0.03 + (concentrationPenalty * 0.12) + reserveStress);
    let monteCarloVaR = grossExposure * (0.035 + (concentrationPenalty * 0.15) + (volatilityFromSettlements(settlements) * 0.25));
    let stressScenarios = buildStressScenarios(grossExposure, concentrationPenalty, guaranteeFund.coverageRatio);
    let scenarioAnalysis = buildScenarioAnalysis(grossExposure, tradeTurnover, concentrationPenalty);
    let sensitivityAnalysis = buildSensitivityAnalysis(greeksByPrincipal);
    let correlationBreakdown = buildCorrelationBreakdown(positionRisk);
    {
      historicalVaR = historicalVaR;
      parametricVaR = parametricVaR;
      monteCarloVaR = monteCarloVaR;
      stressScenarios = stressScenarios;
      scenarioAnalysis = scenarioAnalysis;
      sensitivityAnalysis = sensitivityAnalysis;
      correlationBreakdown = correlationBreakdown;
    }
  };

  func buildCreditRisk(
    config : RiskConfig,
    exposures : [ExposureSnapshot],
    guaranteeFund : GuaranteeFundSnapshot,
    marketRisk : MarketRiskMetrics,
  ) : CreditRiskMetrics {
    let reserveValue = estimateReserveValue(guaranteeFund);
    let collateralPool = reserveValue * 0.45;
    let counterparties = Array.map<ExposureSnapshot, CounterpartyRiskMetric>(exposures, func (exposure) {
      let marginRequired = exposure.totalExposure * maxF(config.minMarginRatio, 0.15 + (marketRisk.parametricVaR / maxF(1.0, exposure.totalExposure * 50.0)));
      let collateralHeld = minF(collateralPool * 0.2, exposure.totalExposure * 0.65);
      let defaultProbability = clamp(0.01 + (exposure.totalExposure / maxF(1.0, config.maxCounterpartyExposure)) * 0.08 + maxF(0.0, marginRequired - collateralHeld) / maxF(1.0, exposure.totalExposure) * 0.12, 0.0, 0.95);
      {
        principal = exposure.principal;
        exposure = exposure.totalExposure;
        exposureLimit = config.maxCounterpartyExposure;
        exposureBreached = exposure.totalExposure > config.maxCounterpartyExposure;
        creditScore = defaultCreditScore(exposure.totalExposure, config.maxCounterpartyExposure, defaultProbability);
        collateralHeld = collateralHeld;
        marginRequired = marginRequired;
        defaultProbability = defaultProbability;
      }
    });
    let totalMarginRequired = Array.foldLeft<CounterpartyRiskMetric, Float>(counterparties, 0.0, func (acc, counterparty) {
      acc + counterparty.marginRequired
    });
    let totalCollateralHeld = Array.foldLeft<CounterpartyRiskMetric, Float>(counterparties, 0.0, func (acc, counterparty) {
      acc + counterparty.collateralHeld
    });
    let weightedDefaultProbability = if (counterparties.size() == 0) 0.0 else Array.foldLeft<CounterpartyRiskMetric, Float>(counterparties, 0.0, func (acc, counterparty) {
      acc + counterparty.defaultProbability
    }) / natToFloat(counterparties.size());
    {
      counterparties = counterparties;
      totalCollateralHeld = totalCollateralHeld;
      totalMarginRequired = totalMarginRequired;
      marginBuffer = totalCollateralHeld - totalMarginRequired;
      weightedDefaultProbability = weightedDefaultProbability;
    }
  };

  func buildLiquidityRisk(
    config : RiskConfig,
    positions : [PositionSnapshot],
    settlements : [SettlementSnapshot],
    guaranteeFund : GuaranteeFundSnapshot,
    marketRisk : MarketRiskMetrics,
    creditRisk : CreditRiskMetrics,
  ) : LiquidityRiskMetrics {
    let marketDepth = buildMarketDepth(positions, settlements);
    let timeToLiquidate = if (marketDepth.size() == 0) 0.0 else Array.foldLeft<MarketDepthMetric, Float>(marketDepth, 0.0, func (acc, metric) {
      acc + metric.estimatedTimeToLiquidate
    }) / natToFloat(marketDepth.size());
    let reserveValue = estimateReserveValue(guaranteeFund);
    let netOutflows = maxF(creditRisk.totalMarginRequired, marketRisk.parametricVaR + (marketRisk.monteCarloVaR * 0.35));
    let liquidityCoverageRatio = if (netOutflows > 0.0) reserveValue / netOutflows else reserveValue;
    let depthPenalty = if (marketDepth.size() == 0) 1.0 else Array.foldLeft<MarketDepthMetric, Float>(marketDepth, 0.0, func (acc, metric) {
      maxF(acc, 1.0 - metric.depthScore)
    });
    let liquidityAdjustedVaR = marketRisk.historicalVaR * (1.0 + (timeToLiquidate * 0.1) + depthPenalty);
    let fundingGap = maxF(0.0, netOutflows - reserveValue);
    {
      liquidityAdjustedVaR = liquidityAdjustedVaR;
      liquidityCoverageRatio = liquidityCoverageRatio;
      timeToLiquidate = timeToLiquidate;
      marketDepth = marketDepth;
      fundingGap = fundingGap;
      fundingStressFlag = liquidityCoverageRatio < config.minLiquidityCoverageRatio or timeToLiquidate > 5.0;
    }
  };

  func buildOperationalRisk(
    prior : OperationalRiskMetrics,
    config : RiskConfig,
    marketRisk : MarketRiskMetrics,
    creditRisk : CreditRiskMetrics,
    liquidityRisk : LiquidityRiskMetrics,
    guaranteeFund : GuaranteeFundSnapshot,
    beat : Int,
    baseAlertCount : Nat,
  ) : OperationalBuild {
    let circuitBreaker = marketRisk.monteCarloVaR > config.circuitBreakerVaRThreshold or liquidityRisk.liquidityAdjustedVaR > config.circuitBreakerVaRThreshold;
    let emergencyShutdown = circuitBreaker and (guaranteeFund.coverageRatio < config.emergencyCoverageThreshold or creditRisk.marginBuffer < 0.0);
    let systemFailureScenario = baseAlertCount >= 5 or guaranteeFund.guaranteesFailed > 0;
    let oracleFailureHandling = switch (Array.find<ScenarioResult>(marketRisk.stressScenarios, func (scenario) { scenario.scenarioName == "oracle_failure" and scenario.breached })) {
      case (?_) { false };
      case null { true };
    };

    var nextEventId = prior.lastEventId;
    var events : [RiskEvent] = [];
    var alerts : [RiskAlert] = [];

    if (circuitBreaker and not prior.circuitBreakerActive) {
      nextEventId += 1;
      let message = "Circuit breaker activated — market risk exceeded threshold";
      events := Array.concat(events, [{ eventId = nextEventId; category = "operational"; severity = "critical"; message = message; beat = beat }]);
      alerts := Array.concat(alerts, [{ principal = "SYSTEM"; category = "operational"; subject = "circuit_breaker"; severity = "critical"; value = marketRisk.monteCarloVaR; limit = config.circuitBreakerVaRThreshold; message = message; beat = beat }]);
    };

    if (emergencyShutdown and not prior.emergencyShutdownActive) {
      nextEventId += 1;
      let message = "Emergency shutdown engaged — guarantee coverage or margin buffer degraded";
      events := Array.concat(events, [{ eventId = nextEventId; category = "operational"; severity = "critical"; message = message; beat = beat }]);
      alerts := Array.concat(alerts, [{ principal = "SYSTEM"; category = "operational"; subject = "emergency_shutdown"; severity = "critical"; value = guaranteeFund.coverageRatio; limit = config.emergencyCoverageThreshold; message = message; beat = beat }]);
    };

    if (systemFailureScenario and not prior.systemFailureScenario) {
      nextEventId += 1;
      events := Array.concat(events, [{ eventId = nextEventId; category = "operational"; severity = "warning"; message = "System failure scenario watchlist activated"; beat = beat }]);
    };

    {
      metrics = {
        systemFailureScenario = systemFailureScenario;
        oracleFailureHandling = oracleFailureHandling;
        circuitBreakerActive = circuitBreaker;
        emergencyShutdownActive = emergencyShutdown;
        lastEventId = nextEventId;
        totalRiskEvents = prior.totalRiskEvents + events.size();
      };
      events = events;
      alerts = alerts;
    }
  };

  func buildMonitoring(
    exposures : [ExposureSnapshot],
    marketRisk : MarketRiskMetrics,
    liquidityRisk : LiquidityRiskMetrics,
    alerts : [RiskAlert],
    mitigations : [MitigationAction],
    beat : Int,
  ) : MonitoringMetrics {
    let realizedPnL = Array.foldLeft<ExposureSnapshot, Float>(exposures, 0.0, func (acc, exposure) {
      acc + (exposure.netExposure * 0.01)
    });
    let unrealizedPnL = -((marketRisk.parametricVaR * 0.2) + (liquidityRisk.liquidityAdjustedVaR * 0.15));
    let livePnL = realizedPnL + unrealizedPnL;
    let dashboard = Array.map<ExposureSnapshot, ExposureDashboardEntry>(exposures, func (exposure) {
      let activeBreaches = countPrincipalAlerts(alerts, exposure.principal);
      {
        principal = exposure.principal;
        grossExposure = exposure.totalExposure;
        netExposure = exposure.netExposure;
        utilizationRatio = if (exposure.maxAllowedExposure > 0.0) exposure.totalExposure / exposure.maxAllowedExposure else 0.0;
        marginRatio = exposure.marginRatio;
        activeBreaches = activeBreaches;
        livePnL = (exposure.netExposure * 0.01) - (natToFloat(activeBreaches) * 25.0);
      }
    });
    {
      livePnL = livePnL;
      realizedPnL = realizedPnL;
      unrealizedPnL = unrealizedPnL;
      exposureDashboard = dashboard;
      alerts = alerts;
      automatedMitigations = mitigations;
      breachCount = alerts.size();
      lastDashboardBeat = beat;
    }
  };

  func buildPositionAlerts(
    config : RiskConfig,
    positionRisk : [PositionRiskMetric],
    exposures : [ExposureSnapshot],
    beat : Int,
  ) : [RiskAlert] {
    var alerts : [RiskAlert] = [];
    for (metric in positionRisk.vals()) {
      if (metric.positionLimitBreached) {
        alerts := appendAlert(alerts, metric.principal, "position", metric.tokenCode, metric.notionalExposure, config.maxPositionNotional, "Position limit breached", beat);
      };
      if (metric.concentrationBreached) {
        alerts := appendAlert(alerts, metric.principal, "position", metric.tokenCode # ":concentration", metric.concentrationRatio, config.maxConcentrationRatio, "Concentration limit breached", beat);
      };
      if (metric.leverageBreached) {
        alerts := appendAlert(alerts, metric.principal, "position", metric.tokenCode # ":leverage", metric.leverage, config.maxLeverage, "Leverage limit breached", beat);
      };
      if (metric.notionalLimitBreached) {
        alerts := appendAlert(alerts, metric.principal, "position", metric.tokenCode # ":principal_notional", metric.notionalExposure, config.maxNotionalPerPrincipal, "Principal notional limit breached", beat);
      };
    };
    for (exposure in exposures.vals()) {
      if (exposure.isOverExposed) {
        alerts := appendAlert(alerts, exposure.principal, "position", "aggregate_exposure", exposure.totalExposure, exposure.maxAllowedExposure, "Aggregate exposure exceeded max allowed", beat);
      };
      if (exposure.marginRatio < config.minMarginRatio and exposure.totalExposure > 0.0) {
        alerts := appendAlert(alerts, exposure.principal, "credit", "margin_ratio", exposure.marginRatio, config.minMarginRatio, "Margin ratio below minimum", beat);
      };
    };
    alerts
  };

  func buildCreditAlerts(counterparties : [CounterpartyRiskMetric], beat : Int) : [RiskAlert] {
    var alerts : [RiskAlert] = [];
    for (counterparty in counterparties.vals()) {
      if (counterparty.exposureBreached) {
        alerts := appendAlert(alerts, counterparty.principal, "credit", "counterparty_exposure", counterparty.exposure, counterparty.exposureLimit, "Counterparty exposure limit breached", beat);
      };
      if (counterparty.defaultProbability > 0.15) {
        alerts := appendAlert(alerts, counterparty.principal, "credit", "default_probability", counterparty.defaultProbability, 0.15, "Default probability elevated", beat);
      };
    };
    alerts
  };

  func buildLiquidityAlerts(config : RiskConfig, liquidityRisk : LiquidityRiskMetrics, beat : Int) : [RiskAlert] {
    var alerts : [RiskAlert] = [];
    if (liquidityRisk.liquidityCoverageRatio < config.minLiquidityCoverageRatio) {
      alerts := appendAlert(alerts, "SYSTEM", "liquidity", "lcr", liquidityRisk.liquidityCoverageRatio, config.minLiquidityCoverageRatio, "Liquidity coverage ratio below floor", beat);
    };
    if (liquidityRisk.timeToLiquidate > 5.0) {
      alerts := appendAlert(alerts, "SYSTEM", "liquidity", "time_to_liquidate", liquidityRisk.timeToLiquidate, 5.0, "Time-to-liquidate exceeded threshold", beat);
    };
    if (liquidityRisk.fundingStressFlag) {
      alerts := appendAlert(alerts, "SYSTEM", "liquidity", "funding_gap", liquidityRisk.fundingGap, 0.0, "Funding liquidity stress detected", beat);
    };
    alerts
  };

  func buildMitigations(
    positionRisk : [PositionRiskMetric],
    creditRisk : CreditRiskMetrics,
    liquidityRisk : LiquidityRiskMetrics,
    operationalRisk : OperationalRiskMetrics,
    alerts : [RiskAlert],
  ) : [MitigationAction] {
    var mitigations : [MitigationAction] = [];

    if (operationalRisk.circuitBreakerActive) {
      mitigations := Array.concat(mitigations, [{ action = "halt_new_matching"; target = "exchange"; reason = "Circuit breaker active"; severity = "critical"; automated = true }]);
    };
    if (operationalRisk.emergencyShutdownActive) {
      mitigations := Array.concat(mitigations, [{ action = "freeze_cross_chain_settlement"; target = "clearinghouse"; reason = "Emergency shutdown active"; severity = "critical"; automated = true }]);
    };
    if (liquidityRisk.fundingStressFlag) {
      mitigations := Array.concat(mitigations, [{ action = "increase_margin_requirements"; target = "all_counterparties"; reason = "Funding liquidity stress"; severity = "warning"; automated = true }]);
    };
    for (metric in positionRisk.vals()) {
      if (metric.leverageBreached or metric.concentrationBreached) {
        mitigations := Array.concat(mitigations, [{ action = "reduce_position_limit"; target = metric.principal # ":" # metric.tokenCode; reason = "Position risk breach"; severity = "warning"; automated = true }]);
      };
    };
    for (counterparty in creditRisk.counterparties.vals()) {
      if (counterparty.defaultProbability > 0.2 or counterparty.exposureBreached) {
        mitigations := Array.concat(mitigations, [{ action = "demand_additional_collateral"; target = counterparty.principal; reason = "Credit risk escalation"; severity = severityFromRatio(counterparty.defaultProbability, 0.2); automated = true }]);
      };
    };
    if (alerts.size() == 0) {
      [{ action = "maintain_normal_operations"; target = "system"; reason = "All monitored limits within tolerance"; severity = "info"; automated = true }]
    } else {
      mitigations
    }
  };

  func buildStressScenarios(grossExposure : Float, concentrationPenalty : Float, coverageRatio : Float) : [ScenarioResult] {
    [
      scenario("historical_crash", -0.18, grossExposure * (0.18 + concentrationPenalty * 0.15), grossExposure * 0.18),
      scenario("correlation_breakdown", -0.12, grossExposure * (0.12 + concentrationPenalty * 0.2), grossExposure * 0.14),
      scenario("oracle_failure", -0.1, grossExposure * (0.1 + maxF(0.0, 1.0 - coverageRatio) * 0.25), grossExposure * 0.12),
      scenario("liquidity_run", -0.22, grossExposure * (0.22 + concentrationPenalty * 0.25), grossExposure * 0.2),
    ]
  };

  func buildScenarioAnalysis(grossExposure : Float, turnover : Float, concentrationPenalty : Float) : [ScenarioResult] {
    [
      scenario("rate_shock_up", 0.03, grossExposure * (0.04 + concentrationPenalty * 0.05), turnover * 0.05),
      scenario("rate_shock_down", -0.03, grossExposure * (0.05 + concentrationPenalty * 0.06), turnover * 0.05),
      scenario("commodity_spike", 0.08, grossExposure * 0.06, turnover * 0.04),
      scenario("stablecoin_depeg", -0.07, grossExposure * (0.08 + concentrationPenalty * 0.1), turnover * 0.06),
    ]
  };

  func buildSensitivityAnalysis(greeksByPrincipal : [(Text, Greeks)]) : [SensitivityResult] {
    let totals = Array.foldLeft<(Text, Greeks), Greeks>(greeksByPrincipal, zeroGreeks(), func (acc, entry) {
      addGreekValues(acc, entry.1)
    });
    [
      { factor = "delta"; upShockImpact = totals.delta * 0.01; downShockImpact = totals.delta * -0.01; sensitivityScore = Float.abs(totals.delta) },
      { factor = "gamma"; upShockImpact = totals.gamma * 0.02; downShockImpact = totals.gamma * -0.02; sensitivityScore = Float.abs(totals.gamma) },
      { factor = "vega"; upShockImpact = totals.vega * 0.015; downShockImpact = totals.vega * -0.015; sensitivityScore = Float.abs(totals.vega) },
      { factor = "theta"; upShockImpact = totals.theta * 0.01; downShockImpact = totals.theta * -0.01; sensitivityScore = Float.abs(totals.theta) },
      { factor = "rho"; upShockImpact = totals.rho * 0.01; downShockImpact = totals.rho * -0.01; sensitivityScore = Float.abs(totals.rho) },
    ]
  };

  func buildCorrelationBreakdown(positionRisk : [PositionRiskMetric]) : [CorrelationBreakdown] {
    let tokenExposure = aggregateTokenExposure(positionRisk);
    var breakdown : [CorrelationBreakdown] = [];
    var i : Nat = 0;
    while (i < tokenExposure.size()) {
      var j : Nat = i + 1;
      while (j < tokenExposure.size()) {
        let a = tokenExposure[i];
        let b = tokenExposure[j];
        let combined = a.1 + b.1;
        let base = maxF(1.0, totalTokenExposure(tokenExposure));
        let correlation = clamp((combined / base) * 0.9, -1.0, 1.0);
        breakdown := Array.concat(breakdown, [{
          tokenA = a.0;
          tokenB = b.0;
          estimatedCorrelation = correlation;
          concentrationContribution = combined / base;
          breakdownFlag = correlation > 0.55 and (combined / base) > 0.5;
        }]);
        j += 1;
      };
      i += 1;
    };
    breakdown
  };

  func buildMarketDepth(positions : [PositionSnapshot], settlements : [SettlementSnapshot]) : [MarketDepthMetric] {
    var tokenTurnover : [(Text, Float)] = [];
    for (settlement in settlements.vals()) {
      tokenTurnover := upsertFloat(tokenTurnover, settlement.baseToken, settlement.quoteAmount);
    };
    let _totalExposure = Array.foldLeft<PositionSnapshot, Float>(positions, 0.0, func (acc, position) {
      acc + Float.abs(position.netPosition)
    });
    Array.map<(Text, Float), MarketDepthMetric>(tokenTurnover, func (entry) {
      let exposure = totalExposureForToken(positions, entry.0);
      let depthScore = clamp(entry.1 / maxF(1.0, exposure), 0.0, 1.5);
      {
        tokenCode = entry.0;
        depthScore = depthScore;
        estimatedTimeToLiquidate = if (entry.1 > 0.0) exposure / entry.1 else if (exposure > 0.0) 10.0 else 0.0;
        turnover = entry.1;
      }
    })
  };

  func findExposure(exposures : [ExposureSnapshot], principal : Text) : ?ExposureSnapshot {
    Array.find<ExposureSnapshot>(exposures, func (exposure) { exposure.principal == principal })
  };

  func estimateGreeks(tokenCode : Text, netPosition : Float, notional : Float) : Greeks {
    if (isOption(tokenCode)) {
      {
        delta = netPosition * 0.55;
        gamma = notional * 0.08;
        vega = notional * 0.12;
        theta = -notional * 0.03;
        rho = notional * 0.02;
      }
    } else if (isDerivative(tokenCode)) {
      {
        delta = netPosition;
        gamma = notional * 0.02;
        vega = notional * 0.03;
        theta = -notional * 0.01;
        rho = notional * 0.015;
      }
    } else {
      {
        delta = netPosition;
        gamma = 0.0;
        vega = 0.0;
        theta = 0.0;
        rho = 0.0;
      }
    }
  };

  func isDerivative(tokenCode : Text) : Bool {
    Text.contains(tokenCode, #text "PERP") or Text.contains(tokenCode, #text "FUT") or Text.contains(tokenCode, #text "SWAP") or isOption(tokenCode)
  };

  func isOption(tokenCode : Text) : Bool {
    Text.contains(tokenCode, #text "OPT") or Text.contains(tokenCode, #text "CALL") or Text.contains(tokenCode, #text "PUT")
  };

  func appendAlert(
    alerts : [RiskAlert],
    principal : Text,
    category : Text,
    subject : Text,
    value : Float,
    limit : Float,
    message : Text,
    beat : Int,
  ) : [RiskAlert] {
    Array.concat(alerts, [{
      principal = principal;
      category = category;
      subject = subject;
      severity = severityFromRatio(value, limit);
      value = value;
      limit = limit;
      message = message;
      beat = beat;
    }])
  };

  func appendAlerts(existing : [RiskAlert], fresh : [RiskAlert], maxItems : Nat) : [RiskAlert] {
    let combined = Array.concat(existing, fresh);
    trimRight(combined, maxItems)
  };

  func appendEvents(existing : [RiskEvent], fresh : [RiskEvent], maxItems : Nat) : [RiskEvent] {
    let combined = Array.concat(existing, fresh);
    trimRight(combined, maxItems)
  };

  func trimRight<T>(items : [T], maxItems : Nat) : [T] {
    if (items.size() <= maxItems) {
      items
    } else {
      Array.tabulate<T>(maxItems, func (index) {
        items[items.size() - maxItems + index]
      })
    }
  };

  func countPrincipalAlerts(alerts : [RiskAlert], principal : Text) : Nat {
    Array.foldLeft<RiskAlert, Nat>(alerts, 0, func (acc, alert) {
      if (alert.principal == principal or alert.principal == "SYSTEM") { acc + 1 } else { acc }
    })
  };

  func severityFromRatio(value : Float, limit : Float) : Text {
    if (limit <= 0.0) {
      if (value > 0.0) { "critical" } else { "info" }
    } else {
      let ratio = value / limit;
      if (ratio >= 1.25) { "critical" }
      else if (ratio >= 1.0) { "warning" }
      else { "info" }
    }
  };

  func scenario(name : Text, shock : Float, impact : Float, threshold : Float) : ScenarioResult {
    {
      scenarioName = name;
      shockPercent = shock;
      estimatedPnLImpact = -Float.abs(impact);
      breached = Float.abs(impact) > threshold;
    }
  };

  func upsertGreeks(existing : [(Text, Greeks)], principal : Text, greeks : Greeks) : [(Text, Greeks)] {
    switch (Array.find<(Text, Greeks)>(existing, func (entry) { entry.0 == principal })) {
      case (?_) {
        Array.map<(Text, Greeks), (Text, Greeks)>(existing, func (entry) {
          if (entry.0 == principal) {
            (principal, addGreekValues(entry.1, greeks))
          } else {
            entry
          }
        })
      };
      case null {
        Array.concat(existing, [(principal, greeks)])
      };
    }
  };

  func aggregateTokenExposure(positionRisk : [PositionRiskMetric]) : [(Text, Float)] {
    var totals : [(Text, Float)] = [];
    for (metric in positionRisk.vals()) {
      totals := upsertFloat(totals, metric.tokenCode, metric.notionalExposure);
    };
    totals
  };

  func upsertFloat(existing : [(Text, Float)], key : Text, value : Float) : [(Text, Float)] {
    switch (Array.find<(Text, Float)>(existing, func (entry) { entry.0 == key })) {
      case (?_) {
        Array.map<(Text, Float), (Text, Float)>(existing, func (entry) {
          if (entry.0 == key) {
            (key, entry.1 + value)
          } else {
            entry
          }
        })
      };
      case null {
        Array.concat(existing, [(key, value)])
      };
    }
  };

  func totalTokenExposure(tokenExposure : [(Text, Float)]) : Float {
    Array.foldLeft<(Text, Float), Float>(tokenExposure, 0.0, func (acc, entry) {
      acc + entry.1
    })
  };

  func totalExposureForToken(positions : [PositionSnapshot], tokenCode : Text) : Float {
    Array.foldLeft<PositionSnapshot, Float>(positions, 0.0, func (acc, position) {
      if (position.tokenCode == tokenCode) { acc + Float.abs(position.netPosition) } else { acc }
    })
  };

  func addGreekValues(a : Greeks, b : Greeks) : Greeks {
    {
      delta = a.delta + b.delta;
      gamma = a.gamma + b.gamma;
      vega = a.vega + b.vega;
      theta = a.theta + b.theta;
      rho = a.rho + b.rho;
    }
  };

  func zeroGreeks() : Greeks {
    { delta = 0.0; gamma = 0.0; vega = 0.0; theta = 0.0; rho = 0.0 }
  };

  func defaultCreditScore(exposure : Float, maxExposure : Float, defaultProbability : Float) : Nat {
    let exposurePenalty = if (maxExposure > 0.0) (exposure / maxExposure) * 220.0 else 220.0;
    let pdPenalty = defaultProbability * 400.0;
    let raw = 850.0 - exposurePenalty - pdPenalty;
    clampNat(floatToNat(raw), 300, 850)
  };

  func volatilityFromSettlements(settlements : [SettlementSnapshot]) : Float {
    if (settlements.size() <= 1) { return 0.1 };
    let average = Array.foldLeft<SettlementSnapshot, Float>(settlements, 0.0, func (acc, settlement) {
      acc + settlement.quoteAmount
    }) / natToFloat(settlements.size());
    let variance = Array.foldLeft<SettlementSnapshot, Float>(settlements, 0.0, func (acc, settlement) {
      let diff = settlement.quoteAmount - average;
      acc + (diff * diff)
    }) / natToFloat(settlements.size());
    clamp(Float.sqrt(variance) / maxF(1.0, average), 0.05, 1.0)
  };

  func estimateReserveValue(guaranteeFund : GuaranteeFundSnapshot) : Float {
    guaranteeFund.totalReserveICP * 12.0 + guaranteeFund.totalReserveBTC * 65000.0 + guaranteeFund.totalReserveETH * 3200.0 + guaranteeFund.totalReserveMTC
  };

  func normalizeRisk(value : Float, scale : Float) : Float {
    clamp(value / maxF(scale, 1.0), 0.0, 1.0)
  };

  func natToFloat(value : Nat) : Float {
    value.toInt().toFloat()
  };

  func floatToNat(value : Float) : Nat {
    let rounded = Float.toInt(value);
    if (rounded <= 0) { 0 } else { rounded.toNat() }
  };

  func clampNat(value : Nat, lower : Nat, upper : Nat) : Nat {
    if (value < lower) { lower }
    else if (value > upper) { upper }
    else { value }
  };

  func clamp(value : Float, lower : Float, upper : Float) : Float {
    if (value < lower) { lower }
    else if (value > upper) { upper }
    else { value }
  };

  func minF(a : Float, b : Float) : Float {
    if (a < b) { a } else { b }
  };

  func maxF(a : Float, b : Float) : Float {
    if (a > b) { a } else { b }
  };
};