import type { Principal } from "@icp-sdk/core/principal";
export interface Some<T> {
    __kind__: "Some";
    value: T;
}
export interface None {
    __kind__: "None";
}
export type Option<T> = Some<T> | None;
export interface OrganismState {
    organisms: Array<OrganismRecord>;
    franchiseCutRate: number;
    franchiseCount: bigint;
    championPool: number;
    totalOrganismEarnings: number;
    activeCount: bigint;
    subOrganisms: Array<SubOrganismRecord>;
}
export interface WyomingState {
    charterGenesisHash: string;
    grants: Array<GrantRecord>;
    frntDemo: FrntDemo;
    nodeProvider: NodeProvider;
    lastUpdatedMs: bigint;
    legislative: LegislativeTimeline;
    partnerships: Array<Partnership>;
    facility: Facility;
}
export interface FrntDemo {
    visaFeeBps: bigint;
    demoActive: boolean;
    phantomFeeBps: bigint;
    visaBottleneckSolved: boolean;
    visaSettlementMs: bigint;
    lastRunMs: bigint;
    phantomSettlementMs: bigint;
}
export interface BuilderState {
    directives: Array<[string, BuilderDirective]>;
    totalFailed: bigint;
    totalBuilt: bigint;
}
export interface LedgerEntry {
    proofHash: string;
    beat: bigint;
    phiDepth: bigint;
    timestamp: bigint;
    category: string;
    payload: string;
}
export interface FormaState {
    spectralCoherence: number;
    projectionPlus10000: string;
    beatCount: bigint;
    projectionPlus1000: string;
    compoundRatePerBeat: number;
    capital: number;
    vonNeumannEntropy: number;
}
export interface NovaRuntimeState {
    runtimePhase: string;
    languages: Array<NovaCognitiveLanguage>;
    lastBeatExecuted: bigint;
    totalExecutionCount: bigint;
    novaVersion: string;
}
export interface KycRecord {
    status: Variant_notStarted_verified_pending_rejected;
    accountId: string;
    retryCount: bigint;
    lastChecked: bigint;
    apiResponse: string;
}
export interface ContextSlice {
    microTokenBudget: bigint;
    resonanceScore: number;
    selectedModelIds: Array<string>;
    microTokensUsed: bigint;
    beatTimestamp: bigint;
}
export interface NeuronGroup {
    dissolveYears: number;
    count: bigint;
    fibIndex: bigint;
    groupId: string;
    substrate: string;
    purpose: string;
    policy: string;
}
export interface Partnership {
    status: string;
    contact: string;
    partnerType: string;
    name: string;
    notes: string;
}
export interface ProtocolRecordPublic {
    id: string;
    principle: string;
    executionCount: bigint;
    lastFiredBeat: bigint;
    name: string;
    category: string;
    lastResult: string;
    equation: string;
    precedence: bigint;
}
export interface RegistryEntry {
    deployed: bigint;
    organType: string;
    status: Variant_active_unreachable_degraded;
    messages: bigint;
    errors: bigint;
    latencyMs: bigint;
    cycles: bigint;
    lastHeartbeat: bigint;
    healthScore: number;
    principalId?: Principal;
    canisterId: string;
}
export interface CodexEntry {
    id: string;
    meaning: string;
    name: string;
    numericalValue: number;
    enforcementAgi: string;
    ancientSource: string;
    principleOneLine: string;
    computation: string;
    category: string;
    formula: string;
}
export interface TokenEntry {
    homeCanister: string;
    circulatingSupply: number;
    mintTrigger: string;
    name: string;
    managingAgi: string;
    totalSupply: number;
    creatorReserveBalance: number;
    burnTrigger: string;
    priceIcp: number;
    symbol: string;
}
export interface CreatorReserveState {
    totalUsdEquiv: number;
    founderName: string;
    withdrawableIcp: number;
    btcReserve: number;
    totalWithdrawn: number;
    icpReserve: number;
    mtcReserve: number;
    founderAccountId: string;
    ethReserve: number;
}
export interface BuilderDirective {
    id: string;
    status: DirectiveStatus;
    rawText: string;
    parameters: Array<[string, string]>;
    parsedIntent: string;
    timestamp: bigint;
    targetType: TargetType;
    outputId?: string;
}
export interface WithdrawalLogEntry {
    error?: string;
    toPrincipal: string;
    blockIndex?: bigint;
    timestamp: bigint;
    success: boolean;
    amount: number;
}
export interface SubOrganismRecord {
    active: boolean;
    tier: bigint;
    parentId: string;
    royaltyRate: number;
    canisterId: string;
}
export interface HealthReport {
    organType: string;
    messages: bigint;
    errors: bigint;
    latencyMs: bigint;
    cycles: bigint;
    timestamp: bigint;
    healthScore: number;
}
export interface EdgeInput {
    relation: string;
    toId: string;
    fromId: string;
}
export interface NodeInput {
    labelText: string;
    nodeType: string;
}
export interface BankAccountEntry {
    kycTimestamp: bigint;
    thresholdLimit: number;
    ownerName: string;
    accountId: string;
    delegatedSigning: boolean;
    createdAt: bigint;
    role: Variant_institutional_personal_business;
    icpBalance: number;
    ckBtcBalance: number;
    kycStatus: Variant_notStarted_verified_pending_rejected;
    txHistory: Array<BankTxEntry>;
    ckEthBalance: number;
}
export interface ShellState {
    rValues: Array<number>;
    shell3Coherence: number;
    activations: Array<number>;
    shell3BeeGate: Array<number>;
}
export interface FullWalletSnapshot {
    totalUsdEquiv: number;
    creatorBtc: number;
    creatorEth: number;
    creatorIcp: number;
    creatorMtc: number;
    btcBalance: number;
    withdrawableIcp: number;
    beatCount: bigint;
    icpBalance: number;
    ethBalance: number;
    totalWithdrawn: number;
    tokenCount: bigint;
    mtcCirculating: number;
    neuronCount: bigint;
}
export interface SignalState {
    eagleSignal: number;
    orcaSignal: number;
    dolphinSignal: number;
    thyroidT3: number;
    thyroidT4: number;
    hiveSignal: number;
    crowSignal: number;
    wolfSignal: number;
    octopusSignal: number;
    respirationRate: number;
    heartRate: number;
    sharkSignal: number;
    cortisol: number;
    elephantSignal: number;
}
export interface ProtocolRegistry {
    totalExecutions: bigint;
    protocols: Array<[string, ProtocolRecord]>;
    lastScanBeat: bigint;
}
export interface JacobRung {
    multiplier: number;
    rungNumber: bigint;
    labelText: string;
    isCurrent: boolean;
}
export interface JacobsLadderState {
    velocity: number;
    currentRung: bigint;
    saceciTarget: number;
    rungs: Array<JacobRung>;
}
export interface RegistryState {
    lastUpdated: bigint;
    entries: Array<[string, RegistryEntry]>;
}
export interface GenesisState {
    sl6Emission: number;
    genesisTimestamp: bigint;
    sl2Resonance: number;
    beatCount: bigint;
    doctrineHash: string;
    sl3Coherence: number;
    creatorName: string;
    sl4Depth: number;
    creatorYear: bigint;
    alfredoLawActive: boolean;
    creatorJurisdiction: string;
    sl7Depth: number;
    alfredoLawHash: string;
    genesisLocked: boolean;
    sl5Amplitude: number;
    creatorTitle: string;
    sl1Score: number;
}
export interface UserProfile {
    principal: string;
    name: string;
}
export interface ProfitState {
    totalAllStreams: number;
    streams: Array<number>;
}
export interface LessonTool {
    id: string;
    publicAccess: boolean;
    title: string;
    subject: string;
    description: string;
    teksCodes: Array<string>;
    toolType: string;
}
export interface SovereignModel {
    id: string;
    latinName: string;
    meaning: string;
    subIntelligence: string;
    layer: string;
    lastBeatActivated: bigint;
    computation: string;
    inputTypes: Array<string>;
    microTokenId: number;
    executionBinding: string;
    maxMicroTokenOutput: bigint;
    beatActivationCount: bigint;
}
export interface NovaCognitiveLanguage {
    id: string;
    latinName: string;
    executionCount: bigint;
    coherenceGateScore: number;
    primaryObjects: Array<string>;
    englishDomain: string;
    runtimePhase: string;
    lastBeatExecuted: bigint;
    stack: string;
    executionBinding: string;
}
export interface LegislativeTimeline {
    billReadyMs: bigint;
    unicameralSession: string;
    hardwareDeadlineMs: bigint;
    milestones: Array<Milestone>;
}
export interface BankTxEntry {
    direction: Variant_in_out;
    asset: string;
    note: string;
    txId: string;
    timestamp: bigint;
    amount: number;
    flagged: boolean;
}
export interface OrganismRecord {
    active: boolean;
    proofDepth: bigint;
    beat: bigint;
    name: string;
    earnings: number;
    coherence: number;
    fieldType: bigint;
    canisterId: string;
}
export interface Node {
    id: string;
    beat: bigint;
    labelText: string;
    nodeType: string;
}
export interface Edge {
    id: string;
    relation: string;
    beat: bigint;
    toId: string;
    fromId: string;
}
export interface NodeProvider {
    entity: string;
    status: string;
    gen3Ready: boolean;
    bslWhitelisted: boolean;
    lincolnNodes: bigint;
    cheyenneNodes: bigint;
    targetRegion: string;
}
export interface EngineState {
    jubileeCount: bigint;
    qbSuperradiance: number;
    shemaLastCheckBeat: bigint;
    anointedStateActive: boolean;
    axisCanisterId: string;
    qbShell3Discharge: number;
    axisEagleElevation: number;
    qmemCanisterId: string;
    fluxCanisterId: string;
    jubileeLastBeat: bigint;
    resonexCanisterId: string;
    kalmanConfidence: number;
    axisElephantDist: number;
    firePillarCount: bigint;
    firePillarActive: boolean;
    sevenSpiritsScore: number;
    axisEagleAccel: number;
    axisEagleCurvature: number;
    shemaIntegrityScore: number;
    prophetConvergenceCount: bigint;
    axisElephantRecall: number;
    prophetFunctionArmed: boolean;
    qbSuperchargeRate: number;
}
export interface TreasuryState {
    btcHardFloor: number;
    icpStaked: number;
    icpYieldRate: number;
    creatorMtcReserve: number;
    mtcPrice: number;
    creatorEthReserve: number;
    btcBalance: number;
    tokenBalances: Array<number>;
    clearanceReserves: Array<number>;
    creatorWithdrawableIcp: number;
    ethPrice: number;
    icpBalance: number;
    btcNetworkCongestion: number;
    ethRocketPoolRate: number;
    btcMempoolFeeRate: number;
    creatorTotalUsdEquiv: number;
    ethBalance: number;
    ethYieldRate: number;
    totalWithdrawn: number;
    btcPrice: number;
    icpPrice: number;
    icpAccruedYield: number;
    ethLidoRate: number;
    creatorBtcReserve: number;
    mtcBurned: number;
    mtcGenesisSupply: number;
    mtcCirculating: number;
    creatorIcpReserve: number;
}
export interface ProtocolRecord {
    id: string;
    principle: string;
    executionCount: bigint;
    lastFiredBeat: bigint;
    name: string;
    category: ProtocolCategory;
    lastResult: ProtocolResult;
    equation: string;
    precedence: bigint;
}
export interface ModelRegistryState {
    lastActivated: string;
    totalActivations: bigint;
    totalModels: bigint;
    microTokensConsumedTotal: bigint;
}
export interface ContextRouterState {
    totalBeatRoutes: bigint;
    microTokenBudgetPerBeat: bigint;
    avgResonanceScore: number;
}
export interface BirthEntity {
    id: string;
    organType: string;
    directive: string;
    birthBeat: bigint;
    birthTimestamp: bigint;
    name: string;
    goalStack: Array<string>;
    activation: number;
    entityType: EntityType;
    messageLog: Array<string>;
    entityState: EntityState;
}
export interface SchoolRegistry {
    grants: Array<GrantRecord_School>;
    totalDeployed: bigint;
    schools: Array<SchoolRecord>;
    lastUpdatedMs: bigint;
    teksStandards: Array<TeksStandard>;
}
export interface GrantRecord_School {
    status: string;
    deadlineMs: bigint;
    name: string;
    notes: string;
    amountUsd: bigint;
    program: string;
}
export interface TxMonitoringState {
    institutionalThreshold: number;
    totalMonitored: bigint;
    flaggedCount: bigint;
    lastFlaggedAt: bigint;
    personalThreshold: number;
    businessThreshold: number;
}
export interface Facility {
    publicPower: boolean;
    stateCode: string;
    city: string;
    internetBackbone: boolean;
    address: string;
    powerCostRank: string;
    vaultGrade: boolean;
}
export interface Milestone {
    id: string;
    status: MilestoneStatus;
    title: string;
    deadlineMs: bigint;
    notes: string;
}
export interface TeksStandard {
    title: string;
    subject: string;
    code: string;
    lessonTools: Array<LessonTool>;
    description: string;
    grade: string;
}
export interface GrantRecord {
    status: string;
    grantType: string;
    deadlineMs: bigint;
    name: string;
    notes: string;
    amountUsd: bigint;
}
export interface DriveState {
    consecutiveDriveBeats: bigint;
    px_driveStrengths: Array<number>;
    dominantDriveId: bigint;
}
export interface SchoolRecord {
    id: string;
    deployed: boolean;
    grantStatus: string;
    name: string;
    tier: SchoolTier;
    district: string;
    contactEmail: string;
    teksStandardsCodes: Array<string>;
    canisterId?: string;
}
export interface BirthAiState {
    lastBirthBeat: bigint;
    totalTranscended: bigint;
    totalBorn: bigint;
    entities: Array<[string, BirthEntity]>;
}
export interface NeuronFleetState {
    groups: Array<NeuronGroup>;
    fieldNodes: bigint;
    neuronsPerNode: bigint;
    totalNeurons: bigint;
}
export interface CardiacState {
    heartbeatActive: boolean;
    omnisFiredCount: bigint;
    hrvBound: number;
    coherenceDirection: bigint;
    coherenceTarget: number;
    deoxygenationAlarms: bigint;
    lastBeatTime: bigint;
    neurochemicalLevels: Array<number>;
    oxygenationScore: number;
    heartRate: number;
    globalCoherence: number;
    kuramotoR: number;
    strokeVolume: number;
    entanglaCarrier: number;
    lastOmnisFireBeat: bigint;
}
export interface FullPxState {
    regime: string;
    jacobRung: bigint;
    beat: bigint;
    novaHealth: number;
    sacesiTarget: number;
    novelty: number;
    dominantDrive: string;
    patentCount: bigint;
    aresArmed: boolean;
    lawScore: number;
    coherence: number;
    miningOutput: number;
    genesisActivated: boolean;
    formaCapital: number;
    mthBalance: number;
    gtkBalance: number;
    mrcBalance: number;
}
export enum DirectiveStatus {
    building = "building",
    complete = "complete",
    failed = "failed",
    parsed = "parsed"
}
export enum EntityState {
    active = "active",
    transcended = "transcended",
    awakening = "awakening",
    dormant = "dormant"
}
export enum EntityType {
    internal = "internal",
    external = "external"
}
export enum MilestoneStatus {
    Complete = "Complete",
    Critical = "Critical",
    InProgress = "InProgress",
    Pending = "Pending"
}
export enum ProtocolCategory {
    Law = "Law",
    Reasoning = "Reasoning",
    Model = "Model",
    Organ = "Organ",
    Behavior = "Behavior"
}
export enum ProtocolResult {
    skipped = "skipped",
    failed = "failed",
    passed = "passed"
}
export enum SchoolTier {
    Gold = "Gold",
    Bronze = "Bronze",
    Silver = "Silver"
}
export enum TargetType {
    protocol = "protocol",
    entity = "entity",
    agent = "agent",
    canister = "canister",
    queryTarget = "queryTarget"
}
export enum Variant_active_unreachable_degraded {
    active = "active",
    unreachable = "unreachable",
    degraded = "degraded"
}
export enum Variant_in_out {
    in_ = "in",
    out = "out"
}
export enum Variant_institutional_personal_business {
    institutional = "institutional",
    personal = "personal",
    business = "business"
}
export enum Variant_notStarted_verified_pending_rejected {
    notStarted = "notStarted",
    verified = "verified",
    pending = "pending",
    rejected = "rejected"
}
export interface backendInterface {
    /**
     * / activateGenesis — inscribe the founding word permanently
     * / Calls genesis_activation.activateGenesis(), persists result in genesisInternalState.
     * / Also sets genesisLocked in SovereignDB so the activation flag mirrors in main db.
     */
    activateGenesis(foundingWord: string): Promise<string>;
    addEdge(input: EdgeInput): Promise<Edge>;
    /**
     * / addGrant — creator-only
     * / Appends a new grant record to the Wyoming charter
     */
    addGrant(grant: GrantRecord): Promise<void>;
    addLessonTool(teksCode: string, tool: LessonTool): Promise<void>;
    addMessage(text: string): Promise<LedgerEntry>;
    addNode(input: NodeInput): Promise<Node>;
    addSchool(school: SchoolRecord): Promise<void>;
    addTeksStandard(std: TeksStandard): Promise<void>;
    /**
     * / birthAI — create a sovereign entity or external agent
     * / entityType: "internal" (born into organism) | "external" (operates outside)
     * / directive: plain natural language — organ type auto-classified from keywords
     * / Returns the new entityId
     */
    birthAI(name: string, directive: string, entityType: string): Promise<string>;
    createBankAccount(accountId: string, ownerName: string, role: string): Promise<string>;
    deploySchoolCanister(schoolId: string, canisterId: string): Promise<void>;
    /**
     * / entityLearn — increase entity activation by phi^-1 per call; caps at 1.0
     * / PHI LAW: activation compounds at the golden ratio inverse — phi-derived growth
     */
    entityLearn(entityId: string, content: string): Promise<void>;
    /**
     * / entityRecall — search entity message log for past messages matching query
     */
    entityRecall(entityId: string, query: string): Promise<Array<string>>;
    /**
     * / entitySetGoal — push a goal onto the entity's goal stack (max 10)
     */
    entitySetGoal(entityId: string, goal: string): Promise<void>;
    /**
     * / entitySpeak — send a message to a sovereign entity, receive its response
     */
    entitySpeak(entityId: string, message: string): Promise<string>;
    /**
     * / executeBuilderDirective — execute a previously parsed directive
     * / If targetType is entity/agent → calls birthAI internally
     * / Returns execution result string
     */
    executeBuilderDirective(directiveId: string): Promise<string>;
    /**
     * / executeNovaEngine — dispatch a specific cognitive language engine by ID
     * / Returns execution result. Coherence gate enforced: R >= 0.618 required.
     */
    executeNovaEngine(engineId: string, input: string): Promise<string>;
    exportFinCEN(format: string): Promise<string>;
    getAgiStatus(): Promise<{
        memoria: {
            lex: string;
            doctrineVerified: boolean;
        };
        computator: {
            phi: number;
            fibonacciSeries: Array<bigint>;
            goldenAngle: number;
            schumannHz: number;
        };
        gubernator: {
            voteCount: bigint;
            neuronGroups: Array<[string, bigint]>;
        };
        custoditor: {
            reroutedNodes: Array<string>;
        };
        explorator: {
            topNodes: Array<string>;
        };
        liberator: {
            lastBlockIndex?: bigint;
            totalWithdrawals: bigint;
            ready: boolean;
        };
        dispensator: {
            totalDisbursed: number;
        };
    }>;
    /**
     * / getAllModels — return all 300 sovereign models
     */
    getAllModels(): Promise<Array<SovereignModel>>;
    /**
     * / getAllProtocols — all 89+ protocol records as public-safe array
     */
    getAllProtocols(): Promise<Array<ProtocolRecordPublic>>;
    getAuditCount(): Promise<bigint>;
    getBankAccount(accountId: string): Promise<BankAccountEntry | null>;
    getBankingSsuState(): Promise<{
        beatCount: bigint;
        kuramotoR: number;
        aegisStatus: string;
        genesisHash: string;
    }>;
    getBankingYield(): Promise<{
        weeklyEst: number;
        neuronGroupStatus: string;
        dailyMaturityEst: number;
    }>;
    getBeatCount(): Promise<bigint>;
    /**
     * / getBirthAiState — full BirthAI domain snapshot
     */
    getBirthAiState(): Promise<BirthAiState>;
    getBtcBalance(): Promise<number>;
    /**
     * / getBuilderState — full Builder SDK domain snapshot
     */
    getBuilderState(): Promise<BuilderState>;
    getCardiacState(): Promise<CardiacState>;
    getCodexById(id: string): Promise<CodexEntry | null>;
    getCodexMathematicus(): Promise<Array<CodexEntry>>;
    /**
     * / getContextRouterState — aggregate context router stats
     */
    getContextRouterState(): Promise<ContextRouterState>;
    getCreatorPrincipalLocked(): Promise<boolean>;
    getCreatorReserve(): Promise<CreatorReserveState>;
    getCreatorWithdrawableIcp(): Promise<number>;
    getDomLibStatus(): Promise<{
        verificatorChecks: bigint;
        confirmatorCount: bigint;
        auditorCount: bigint;
        protectorBlocks: bigint;
    }>;
    getDriveState(): Promise<DriveState>;
    getEdges(): Promise<Array<Edge>>;
    getEngineState(): Promise<EngineState>;
    getEthBalance(): Promise<number>;
    getFlaggedTransactions(): Promise<Array<BankTxEntry>>;
    getFormaState(): Promise<FormaState>;
    /**
     * / getFounderAccountId — returns the canonical sovereign ICP account ID permanently wired
     * / Address: 8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
     * / All D_LIQUID disbursements and LIBERATOR withdrawals route to this address by default.
     */
    getFounderAccountId(): Promise<string>;
    getFullWalletSnapshot(): Promise<FullWalletSnapshot>;
    getGenesisState(): Promise<GenesisState>;
    getGrantsByStatus(status: string): Promise<Array<GrantRecord_School>>;
    getIcpBalance(): Promise<number>;
    getJacobsLadder(): Promise<JacobsLadderState>;
    getKuramotoR(): Promise<number>;
    getKycEndpoint(): Promise<string>;
    getKycStatus(accountId: string): Promise<KycRecord | null>;
    getLessonToolsByGrade(grade: string): Promise<Array<LessonTool>>;
    getLessonToolsBySubject(subject: string): Promise<Array<LessonTool>>;
    getMemoriaNns(): Promise<{
        lex: string;
        verified: boolean;
    }>;
    getMessages(limit: bigint): Promise<Array<LedgerEntry>>;
    /**
     * / getMicroTokenBudget — returns the per-beat micro-token budget (200_000)
     */
    getMicroTokenBudget(): Promise<bigint>;
    /**
     * / getModel — retrieve a sovereign model by ID (e.g., "M-001")
     */
    getModel(id: string): Promise<SovereignModel | null>;
    /**
     * / getModelCount — always returns 300
     */
    getModelCount(): Promise<bigint>;
    /**
     * / getModelRegistryState — aggregate model registry stats
     */
    getModelRegistryState(): Promise<ModelRegistryState>;
    getMtcCirculating(): Promise<number>;
    getNeuronFleet(): Promise<NeuronFleetState>;
    getNodes(): Promise<Array<Node>>;
    /**
     * / getNovaActiveLanguages — engines currently in active or transcended phase
     */
    getNovaActiveLanguages(): Promise<Array<NovaCognitiveLanguage>>;
    /**
     * / getNovaLanguageById — retrieve one engine record by ID
     */
    getNovaLanguageById(id: string): Promise<NovaCognitiveLanguage | null>;
    /**
     * / getNovaLanguageRegistry — all 40 cognitive language engine records
     */
    getNovaLanguageRegistry(): Promise<Array<NovaCognitiveLanguage>>;
    /**
     * / getNovaLanguagesByStack — retrieve all engines in a named stack
     */
    getNovaLanguagesByStack(stack: string): Promise<Array<NovaCognitiveLanguage>>;
    /**
     * / getNovaRuntimeState — full NOVA runtime state snapshot
     */
    getNovaRuntimeState(): Promise<NovaRuntimeState>;
    /**
     * / getOrganHealth — health record for a specific organ type
     */
    getOrganHealth(organType: string): Promise<RegistryEntry | null>;
    getOrganismState(): Promise<OrganismState>;
    getProfitState(): Promise<ProfitState>;
    /**
     * / getProtocolById — lookup one protocol record by ID (e.g., "L01", "M05", "B03")
     */
    getProtocolById(id: string): Promise<ProtocolRecordPublic | null>;
    /**
     * / getProtocolLog — all protocols sorted by lastFiredBeat descending
     */
    getProtocolLog(): Promise<Array<ProtocolRecordPublic>>;
    /**
     * / getProtocolRegistry — full protocol execution registry snapshot
     */
    getProtocolRegistry(): Promise<ProtocolRegistry>;
    /**
     * / getProtocolsByCategory — all protocols of a given category
     * / category: "Law" | "Model" | "Behavior" | "Reasoning" | "Organ"
     */
    getProtocolsByCategory(category: string): Promise<Array<ProtocolRecordPublic>>;
    getPublicCurriculum(): Promise<Array<TeksStandard>>;
    getRecentAudit(n: bigint): Promise<Array<LedgerEntry>>;
    getRecentSettle(n: bigint): Promise<Array<LedgerEntry>>;
    /**
     * / getRegistryCoherence — mean healthScore across all registered organs
     */
    getRegistryCoherence(): Promise<number>;
    /**
     * / getRegistryEntries — all registered organ entries as a flat array
     */
    getRegistryEntries(): Promise<Array<RegistryEntry>>;
    /**
     * / getRegistryState — full canister registry snapshot (all 9 organs)
     */
    getRegistryState(): Promise<RegistryState>;
    getSchoolByDistrict(district: string): Promise<Array<SchoolRecord>>;
    getSchoolRegistry(): Promise<SchoolRegistry>;
    getShellState(): Promise<ShellState>;
    getSignalState(): Promise<SignalState>;
    getTeksStandard(code: string): Promise<TeksStandard | null>;
    getTokenBySymbol(symbol: string): Promise<TokenEntry | null>;
    getTokenRegistry(): Promise<Array<TokenEntry>>;
    getTotalProfit(): Promise<number>;
    getTotalWithdrawn(): Promise<number>;
    getTreasuryState(): Promise<TreasuryState>;
    getTxMonitoringState(): Promise<TxMonitoringState>;
    getUserProfile(who: Principal): Promise<UserProfile | null>;
    getWithdrawalLog(): Promise<Array<WithdrawalLogEntry>>;
    /**
     * / getWyomingCharter — public query, no auth required
     * / Returns the full sovereign Wyoming charter state
     */
    getWyomingCharter(): Promise<WyomingState>;
    initiateKyc(accountId: string): Promise<string>;
    listBankAccounts(): Promise<Array<BankAccountEntry>>;
    /**
     * / listBuilderDirectives — return all submitted directives
     */
    listBuilderDirectives(): Promise<Array<BuilderDirective>>;
    /**
     * / listEntities — return all sovereign entities (internal + external)
     */
    listEntities(): Promise<Array<BirthEntity>>;
    /**
     * / listModelsByLayer — return all models in a given layer ("MICRO" | "MESO" | "MACRO")
     */
    listModelsByLayer(layer: string): Promise<Array<SovereignModel>>;
    /**
     * / markOrganDegraded — creator-only: force organ status to #degraded
     */
    markOrganDegraded(organType: string): Promise<void>;
    /**
     * / markOrganUnreachable — creator-only: force organ status to #unreachable
     */
    markOrganUnreachable(organType: string): Promise<void>;
    /**
     * / px_getFullState — single-call sovereign organism snapshot
     * / Wired to real SovereignDB domain state — no hardcoded numbers
     */
    px_getFullState(): Promise<FullPxState>;
    /**
     * / px_getNeurochemicals — returns the 18 neurochemical Float levels from CardiacState
     * / Pads with 0.0 if fewer than 18 values exist
     */
    px_getNeurochemicals(): Promise<Array<number>>;
    /**
     * / px_isGenesisActivated — returns true when the founding word has been inscribed
     * / Reads GenesisInternalState (activation record) and falls back to genesisLocked flag
     */
    px_isGenesisActivated(): Promise<boolean>;
    recordBankTx(accountId: string, amount: number, asset: string, direction: string, note: string): Promise<string>;
    /**
     * / registerOrgan — creator-only: wire a deployed organ canister ID
     */
    registerOrgan(organType: string, canisterId: string): Promise<void>;
    /**
     * / routeBeat — route a beat signal text to top-K resonant models
     */
    routeBeat(signal: string, k: bigint): Promise<ContextSlice>;
    /**
     * / runFrntDemo — Ω_GATE: Kuramoto R must be >= 0.618 (phi^-1)
     * / Executes the FRNT settlement demo, records the run timestamp
     * / Proves: 0.3s (Phantom) vs 900s (Visa), 0% vs 4% fee
     */
    runFrntDemo(): Promise<FrntDemo>;
    setBtcBalance(v: number): Promise<void>;
    setBtcPrice(v: number): Promise<void>;
    setCreatorPrincipal(): Promise<boolean>;
    setEthBalance(v: number): Promise<void>;
    setEthPrice(v: number): Promise<void>;
    setGenesisLocked(v: boolean): Promise<void>;
    setIcpBalance(v: number): Promise<void>;
    setIcpPrice(v: number): Promise<void>;
    setKuramotoR(v: number): Promise<void>;
    setKycEndpoint(url: string): Promise<void>;
    setUserProfile(profile: UserProfile): Promise<void>;
    /**
     * / submitBuilderDirective — submit a natural language directive for parsing
     * / Returns directiveId for subsequent execution
     */
    submitBuilderDirective(rawText: string): Promise<string>;
    tickBeatManual(): Promise<bigint>;
    /**
     * / tickBeatManual with protocol gate — creator-only manual beat + gate check
     */
    tickBeatManualGated(): Promise<{
        beat: bigint;
        gateOpen: boolean;
    }>;
    toggleDelegatedSigning(accountId: string): Promise<boolean>;
    updateBankAccountRole(accountId: string, role: string): Promise<boolean>;
    updateGrantStatus(grantName: string, status: string): Promise<void>;
    /**
     * / updateMilestone — creator-only
     * / Updates milestone status and notes by milestone id
     */
    updateMilestone(id: string, status: MilestoneStatus, notes: string): Promise<void>;
    /**
     * / updateNodeProvider — creator-only
     * / Updates Bad Marine LLC node provider positioning
     */
    updateNodeProvider(np: NodeProvider): Promise<void>;
    /**
     * / updateOrganHealth — called by organ canisters on their own heartbeat
     * / Any external canister implementing reportHealth() submits here.
     */
    updateOrganHealth(report: HealthReport): Promise<void>;
    /**
     * / Withdraw ICP from Creator Reserve — creator only
     */
    withdrawCreatorIcp(amount: number): Promise<boolean>;
    /**
     * / withdrawToExternalWallet — LIBERATOR real ICRC-1 transfer
     * / Called by all three withdrawal UIs. Creator-only. Executes real transfer.
     * / If toPrincipal is "" (empty), defaults to the founder's canonical account ID:
     * /   8c047c715f630bb8824c4831a1b95ad181a4b9264c528131fd5eccc2e4c6b879
     */
    withdrawToExternalWallet(amount: number, toPrincipal: string): Promise<{
        error?: string;
        blockIndex?: bigint;
        success: boolean;
    }>;
}
