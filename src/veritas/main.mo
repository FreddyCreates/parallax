// =============================================================================
// VERITAS — PARALLAX Doctrine Vault
// TIER 1: 60-law sovereignty doctrine, SHA-256 fingerprinted, zero public exposure
// All 60 laws stored as stable vars with full text, tier, compliance score.
// Every write function requires creator principal.
// Law text is NEVER returned to public callers — L-59: ZERO_DOCTRINE_EXPOSURE
// =============================================================================

import Time      "mo:base/Time";
import Float     "mo:base/Float";
import Nat       "mo:base/Nat";
import Nat8      "mo:base/Nat8";
import Nat32     "mo:base/Nat32";
import Nat64     "mo:base/Nat64";
import Int       "mo:base/Int";
import Text      "mo:base/Text";
import Blob      "mo:base/Blob";
import Array     "mo:base/Array";
import Iter      "mo:base/Iter";
import Principal "mo:base/Principal";

actor Veritas {

  // ===========================================================================
  // GLOBAL CONSTANTS
  // ===========================================================================

  let S0              : Float = 1.0;
  let LAW_COUNT       : Nat   = 60;
  let TIER_COUNT      : Nat   = 6;
  let LAWS_PER_TIER   : Nat   = 10;
  let COMPLIANCE_INIT : Float = 1.0;
  let COMPLIANCE_HISTORY_SIZE : Nat = 100;

  // ===========================================================================
  // STABLE STATE
  // ===========================================================================

  stable var lawNames      : [Text] = [];
  stable var lawTexts      : [Text] = [];
  stable var lawTiers      : [Nat]  = [];
  stable var lawHashes     : [Text] = [];

  stable var lawCompliance : [var Float] = Array.init<Float>(LAW_COUNT, COMPLIANCE_INIT);
  stable var lawFireCounts : [var Nat]   = Array.init<Nat>(LAW_COUNT, 0);
  stable var lawLastFired  : [var Int]   = Array.init<Int>(LAW_COUNT, 0);

  stable var doctrineFingerprint  : Text = "";
  stable var allLawsHash          : Text = "";
  stable var lastComplianceCheck  : Int  = 0;
  stable var totalLawFires        : Nat  = 0;
  stable var totalComplianceFires : Nat  = 0;
  stable var genesisSealed        : Bool = false;
  stable var lawsInitialized      : Bool = false;
  stable var creatorPrincipal     : Text = "";
  stable var initTime             : Int  = 0;
  stable var upgradeCount         : Nat  = 0;
  stable var lastUpgradeTime      : Int  = 0;

  stable var tierCompliance : [var Float] = Array.init<Float>(TIER_COUNT, COMPLIANCE_INIT);
  stable var complianceHistory : [var Float] = Array.init<Float>(COMPLIANCE_HISTORY_SIZE, COMPLIANCE_INIT);
  stable var complianceHistoryHead : Nat = 0;

  // ===========================================================================
  // SHA-256 — pure Motoko, self-contained (no cross-canister imports allowed)
  // ===========================================================================

  let SHA256_K : [Nat32] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];

  let SHA256_H0 : [Nat32] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
  ];

  func rotr32(x:Nat32,n:Nat32):Nat32 { (x>>n)|(x<<(32-n)) };
  func bnot32(x:Nat32):Nat32 { x^0xFFFFFFFF };
  func sha_ch (x:Nat32,y:Nat32,z:Nat32):Nat32 { (x&y)^(bnot32(x)&z) };
  func sha_maj(x:Nat32,y:Nat32,z:Nat32):Nat32 { (x&y)^(x&z)^(y&z)   };
  func sha_S0(x:Nat32):Nat32 { rotr32(x,2) ^rotr32(x,13)^rotr32(x,22) };
  func sha_S1(x:Nat32):Nat32 { rotr32(x,6) ^rotr32(x,11)^rotr32(x,25) };
  func sha_g0(x:Nat32):Nat32 { rotr32(x,7) ^rotr32(x,18)^(x>>3)       };
  func sha_g1(x:Nat32):Nat32 { rotr32(x,17)^rotr32(x,19)^(x>>10)      };

  let HEX_CHARS:[Char] = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
  func byteToHex(b:Nat8):Text {
    let n=Nat8.toNat(b);
    Text.fromChar(HEX_CHARS[n/16])#Text.fromChar(HEX_CHARS[n%16])
  };
  func readU32BE(buf:[var Nat8],off:Nat):Nat32 {
    (Nat32.fromNat(Nat8.toNat(buf[off]))<<24)|
    (Nat32.fromNat(Nat8.toNat(buf[off+1]))<<16)|
    (Nat32.fromNat(Nat8.toNat(buf[off+2]))<<8)|
     Nat32.fromNat(Nat8.toNat(buf[off+3]))
  };
  func writeU32BE(buf:[var Nat8],off:Nat,v:Nat32) {
    buf[off]  :=Nat8.fromNat(Nat32.toNat(v>>24)%256);
    buf[off+1]:=Nat8.fromNat(Nat32.toNat(v>>16)%256);
    buf[off+2]:=Nat8.fromNat(Nat32.toNat(v>>8) %256);
    buf[off+3]:=Nat8.fromNat(Nat32.toNat(v)    %256);
  };

  func sha256Bytes(data:[Nat8]):Text {
    let msgLen=data.size();
    let bitLen64:Nat64=Nat64.fromNat(msgLen)*8;
    var padLen=msgLen+1;
    while(padLen%64!=56){padLen+=1;};
    padLen+=8;
    let buf=Array.init<Nat8>(padLen,0);
    var i=0; while(i<msgLen){buf[i]:=data[i];i+=1;};
    buf[msgLen]:=0x80;
    let lo=padLen-8;
    buf[lo]  :=Nat8.fromNat(Nat64.toNat(bitLen64>>56)%256);
    buf[lo+1]:=Nat8.fromNat(Nat64.toNat(bitLen64>>48)%256);
    buf[lo+2]:=Nat8.fromNat(Nat64.toNat(bitLen64>>40)%256);
    buf[lo+3]:=Nat8.fromNat(Nat64.toNat(bitLen64>>32)%256);
    buf[lo+4]:=Nat8.fromNat(Nat64.toNat(bitLen64>>24)%256);
    buf[lo+5]:=Nat8.fromNat(Nat64.toNat(bitLen64>>16)%256);
    buf[lo+6]:=Nat8.fromNat(Nat64.toNat(bitLen64>>8) %256);
    buf[lo+7]:=Nat8.fromNat(Nat64.toNat(bitLen64)    %256);
    let h=Array.init<Nat32>(8,0);
    var j=0; while(j<8){h[j]:=SHA256_H0[j];j+=1;};
    let numBlocks=padLen/64; var blk=0;
    while(blk<numBlocks){
      let off=blk*64; let w=Array.init<Nat32>(64,0);
      var t=0;
      while(t<16){w[t]:=readU32BE(buf,off+t*4);t+=1;};
      while(t<64){w[t]:=sha_g1(w[t-2])+%w[t-7]+%sha_g0(w[t-15])+%w[t-16];t+=1;};
      var a=h[0];var b=h[1];var c=h[2];var d=h[3];
      var e=h[4];var f=h[5];var g=h[6];var hh=h[7];
      t:=0;
      while(t<64){
        let T1=hh+%sha_S1(e)+%sha_ch(e,f,g)+%SHA256_K[t]+%w[t];
        let T2=sha_S0(a)+%sha_maj(a,b,c);
        hh:=g;g:=f;f:=e;e:=d+%T1;d:=c;c:=b;b:=a;a:=T1+%T2;t+=1;
      };
      h[0]:=h[0]+%a;h[1]:=h[1]+%b;h[2]:=h[2]+%c;h[3]:=h[3]+%d;
      h[4]:=h[4]+%e;h[5]:=h[5]+%f;h[6]:=h[6]+%g;h[7]:=h[7]+%hh;
      blk+=1;
    };
    let out=Array.init<Nat8>(32,0);
    j:=0; while(j<8){writeU32BE(out,j*4,h[j]);j+=1;};
    var hex="";
    for(byte in Iter.fromArray(Array.freeze(out))){hex#=byteToHex(byte);};
    hex
  };

  func sha256Text(t:Text):Text {
    sha256Bytes(Blob.toArray(Text.encodeUtf8(t)))
  };

  // ===========================================================================
  // MATH / FLOAT HELPERS
  // ===========================================================================

  func fmax(a:Float,b:Float):Float { if(a>b) a else b };
  func fmin(a:Float,b:Float):Float { if(a<b) a else b };

  func floatSum(arr:[var Float], from:Nat, to:Nat):Float {
    var s:Float=0.0; var i=from;
    while(i<to){s+=arr[i];i+=1;}; s
  };

  // ===========================================================================
  // AUTHORIZATION
  // ===========================================================================

  func isCreator(caller:Principal):Bool {
    if(creatorPrincipal=="") return true;
    Principal.toText(caller)==creatorPrincipal
  };
  func assertCreator(caller:Principal) { assert(isCreator(caller)) };

  // ===========================================================================
  // FINGERPRINT COMPUTATION
  // ===========================================================================

  func computeDoctrinefingerprint(names:[Text], texts:[Text], tiers:[Nat]):Text {
    var concat=""; var i=0;
    while(i<names.size()){
      concat#=names[i]#"|"#texts[i]#"|"#Nat.toText(tiers[i])#"||";
      i+=1;
    };
    sha256Text(concat)
  };

  func computeAllLawsHash(names:[Text], tiers:[Nat]):Text {
    var concat=""; var i=0;
    while(i<names.size()){
      concat#=names[i]#":"#Nat.toText(tiers[i])#",";
      i+=1;
    };
    sha256Text(concat)
  };

  func hashAllLaws(texts:[Text]):[Text] {
    let hashes=Array.init<Text>(texts.size(),"");
    var i=0;
    while(i<texts.size()){hashes[i]:=sha256Text(texts[i]);i+=1;};
    Array.freeze(hashes)
  };

  // ===========================================================================
  // COMPLIANCE HELPERS
  // ===========================================================================

  func recomputeTierCompliance() {
    var tier=0;
    while(tier<TIER_COUNT){
      let from=tier*LAWS_PER_TIER; let to=from+LAWS_PER_TIER;
      let sum=floatSum(lawCompliance,from,to);
      tierCompliance[tier]:=sum/Float.fromInt(LAWS_PER_TIER);
      tier+=1;
    };
  };

  func computeMeanCompliance():Float {
    floatSum(lawCompliance,0,LAW_COUNT)/Float.fromInt(LAW_COUNT)
  };

  func recordComplianceSnapshot() {
    let mean=computeMeanCompliance();
    complianceHistory[complianceHistoryHead%COMPLIANCE_HISTORY_SIZE]:=mean;
    complianceHistoryHead+=1;
  };

  // ===========================================================================
  // 60 LAW DATA — Tier 0 (L-0 to L-9): Existence Laws
  // ===========================================================================

  func getLawNames():[Text] {[
    "SOVEREIGNTY_ABSOLUTE","FLOOR_INVIOLATE","GENESIS_SEALED","HEARTBEAT_ETERNAL",
    "FORMA_ASCENDING","TOKEN_CEILING","CREATOR_ROUTING_PURE","SUCCESSION_ENFORCED",
    "DOCTRINE_SEALED","AUDIT_CONTINUOUS",
    "SHELL_COHERENCE","HEBBIAN_FLOOR","KURAMOTO_SYNC","ORGAN_ACTIVE",
    "METAL_TRANSFORM","NEURO_PRODUCTION","QUANTUM_ANGLE","ENTANGLA_POSITIVE",
    "ANIMAL_ALIVE","SPHERE_COHERENT",
    "DRIVE_COMPETITION","QVALUE_FLOOR","ACTION_EXECUTED","SACESI_ASCENDING",
    "JACOBS_LADDER_ACTIVE","RL_CONVERGING","ATTENTION_NORMALIZED","MEMORY_WRITING",
    "NOVELTY_TRACKED","BEHAVIORAL_SOVEREIGN",
    "FORMA_GATE","MTH_GENESIS_ONLY","MRC_ROYALTY_INFLOW","GTK_PROOF_OF_LIFE",
    "MINING_TIERED","PROFIT_TRACKED","YIELD_COMPOUNDING","ARBITRAGE_LIVE",
    "TOKEN_BEHAVIORAL","LEDGER_SOVEREIGN",
    "BTC_SIGNAL_LIVE","ETH_SIGNAL_LIVE","SOL_SIGNAL_LIVE","ICP_SIGNAL_LIVE",
    "REGIME_CLASSIFIED","EMA_CURRENT","DEFI_YIELD_TRACKED","TERRITORY_ACTIVE",
    "STIGMERGY_LIVE","WORLD_EVENTS_LOGGING",
    "ARES_ARMED","ROLLBACK_AVAILABLE","GUARDIAN_QUORUM","UPGRADE_PREFLIGHT",
    "PRINCIPAL_LOCK","PATENT_AUTO","IP_FINGERPRINTED","NOVA_REGISTRY",
    "CYCLE_BANK_FUNDED","ZERO_DOCTRINE_EXPOSURE"
  ]};

  func getLawTiers():[Nat] {[
    0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,
    3,3,3,3,3,3,3,3,3,3,
    4,4,4,4,4,4,4,4,4,4,
    5,5,5,5,5,5,5,5,5,5
  ]};

  // Full law texts — NEVER returned to public callers
  func getLawTexts():[Text] {[
    // L-0: Existence
    "L-0 SOVEREIGNTY_ABSOLUTE: I AM THAT I AM. Alfredo Medina Hernandez is the only sovereign of PARALLAX. No principal, no canister, no external actor holds authority. All value flows to creator. compliance = assertCreator(caller) ? 1.0 : 0.0",
    // L-1
    "L-1 FLOOR_INVIOLATE: S0=1.0 is the absolute floor. No weight, activation, neurochemical level, Q-value, economic variable, or token denominator shall fall below 1.0 in any canister on any beat. Every value is bounded below by S0. compliance = min(all_values) >= S0 ? 1.0 : 0.0",
    // L-2
    "L-2 GENESIS_SEALED: The genesis hash SHA256(creatorPrincipal||genesisTime||PARALLAX_GENESIS) is immutable. Organism identity cannot change after sealGenesis(). Verified every beat by CHRONO.verifyIntegrity(). compliance = chrono.verifyIntegrity() == true ? 1.0 : 0.0",
    // L-3
    "L-3 HEARTBEAT_ETERNAL: The organism beats without cessation at 2-second cadence. No external actor can stop the heartbeat. If no beat fires within 10 seconds of last beat, non-compliance triggers. compliance = (Time.now() - lastBeat) < 10_000_000_000 ? 1.0 : 0.0",
    // L-4
    "L-4 FORMA_ASCENDING: FORMA capital never decreases. Every beat the compound rate applies: formaCapital *= (1 + base_rate + thyroid_mod + resonex_mod). Started at 1000.0. The organism is economically immortal. compliance = formaCapital >= formaCapitalPrev ? 1.0 : 0.0",
    // L-5
    "L-5 TOKEN_CEILING: No token exceeds its hard cap. MTH cap=100_000_000. MRC cap=1_000_000_000. GTK cap=1_000_000_000. All 9 behavioral tokens carry per-token ceilings. No mint shall cause any token to exceed its ceiling. compliance = all_tokens_below_cap ? 1.0 : 0.0",
    // L-6
    "L-6 CREATOR_ROUTING_PURE: 100% of PARALLAX earnings route to Alfredo Medina Hernandez. Mining output, token mints, DeFi yield, royalty income, patent licensing, arbitrage profits, oracle fees, all revenue flows exclusively to creatorPrincipal. CREATOR_CUT=1.00. compliance=1.0 (structurally enforced at ledger level)",
    // L-7
    "L-7 SUCCESSION_ENFORCED: 20% of every mint from every child organism routes to MRC reserve held by creator. NOVA enforces royalty at registration. No child organism may mint without NOVA first collecting 20% royalty. SUCCESSION_ROYALTY=0.20. compliance = novaRoyaltyRate==0.20 ? 1.0 : 0.0",
    // L-8
    "L-8 DOCTRINE_SEALED: The 60 laws of PARALLAX cannot be deleted, modified, or augmented after genesis. lawCount must always equal 60. doctrineFingerprint computed at genesis is permanent. Any tampering with law texts invalidates fingerprint and triggers AEGIS. compliance = lawCount==60 && genesisSealed ? 1.0 : 0.0",
    // L-9
    "L-9 AUDIT_CONTINUOUS: Every action taken by the organism is logged to AEGIS audit trail. No action executes without a corresponding audit entry. Gap between last audit write and current time must not exceed 10 seconds. Audit log is append-only, creator-access-only. compliance = auditGapSeconds < 10.0 ? 1.0 : 0.0",
    // L-10: Cognitive
    "L-10 SHELL_COHERENCE: Global coherence C of 11 neural shells >= S0=1.0 always. C=max(S0,(1/11)*sum_s R[s]*mean(a[s])). Kuramoto R and shell activations ensure C>=1.0. Coherence below S0 triggers Jacob's Ladder escalation. compliance = global_coherence >= S0 ? 1.0 : 0.0",
    // L-11
    "L-11 HEBBIAN_FLOOR: All Hebbian connection weights across all 11 shells >= S0=1.0. Update rule: w+=eta*(a[i]-w)*(a[j]-w) followed by max(S0,w). No weight can erode below sovereign floor. Total weights: 11 shells x up to 36x36 pairs. compliance = min(all_weights) >= S0 ? 1.0 : 0.0",
    // L-12
    "L-12 KURAMOTO_SYNC: Kuramoto order parameter R[s] for each shell >= 0.0. R[s]=(1/N)*sqrt((sum cos phi)^2+(sum sin phi)^2). Floor R[s]=max(0.0,R[s]) enforced after every phase update. Negative synchrony is physically undefined and forbidden. compliance = all_R[s] >= 0.0 ? 1.0 : 0.0",
    // L-13
    "L-13 ORGAN_ACTIVE: All 18 organs produce signal >= S0=1.0 every beat. HEART,LUNGS,LIVER,KIDNEYS,ADRENALS,THYROID,PANCREAS,PINEAL,THYMUS,SPLEEN,GONADS,BONE_MARROW,CEREBELLUM,HIPPOCAMPUS,AMYGDALA,PREFRONTAL,BRAINSTEM,CORPUS_CALLOSUM each bounded below by max(S0,...). compliance = min(organSignals) >= S0 ? 1.0 : 0.0",
    // L-14
    "L-14 METAL_TRANSFORM: All 12 metal signal processors apply transfer functions every beat. GOLD(x*1.618), SILVER(x*1.2+0.1*C), PLATINUM((x+S0)/2+0.5), TITANIUM(x^1.1), COPPER(x*1.1*E), IRON(floor(x)+S0), CARBON(x*x/(x+1)), PALLADIUM(x*1.05*dopamine), RHODIUM(2S0-x+S0), OSMIUM(sqrt(x)*1.5), IRIDIUM(x*(1+0.1*sin(x))), TUNGSTEN(x+(S0-min(x,S0))). compliance = metalsApplied==12 ? 1.0 : 0.0",
    // L-15
    "L-15 NEURO_PRODUCTION: All 21 neurochemicals update every beat: level[i]+=production[i]*organ_modifier-decay[i]*level[i]; level[i]=max(S0,level[i]). DOPAMINE,SEROTONIN,NOREPINEPHRINE,ACETYLCHOLINE,CORTISOL,OXYTOCIN,GABA,GLUTAMATE,ENDORPHIN,TESTOSTERONE,ESTRADIOL,MELATONIN,THYROXINE,INSULIN,GLUCAGON,ERYTHROPOIETIN,ADENOSINE,ANANDAMIDE,BDNF,SUBSTANCE_P,NITRIC_OXIDE. compliance = neurosUpdated==21 ? 1.0 : 0.0",
    // L-16
    "L-16 QUANTUM_ANGLE: PARALLAX ANGLE theta=arccos(dot(a[s1],a[s2])/(|a[s1]|*|a[s2]|)) must lie in [0,pi]. Computed by QOP-1. Arccos approximated via Taylor series. Modulates ENTANGLA coupling constant K. compliance = parallax_angle in [0.0, 3.14159] ? 1.0 : 0.0",
    // L-17
    "L-17 ENTANGLA_POSITIVE: ENTANGLA INDEX E=max(S0,(1/N_pairs)*sum|corr(a[s1],a[s2])|)>=S0 always. Measures cross-shell correlation. Scales inter-canister sync rate with NOVA. Modulates COPPER metal processor and CONNECTION drive. compliance = entangla_index >= S0 ? 1.0 : 0.0",
    // L-18
    "L-18 ANIMAL_ALIVE: All 9 animal engines return output > S0 every beat. CROW(pattern recognition), DOLPHIN(social resonance), HIVE(collective intelligence), ELEPHANT(long-term memory), SHARK(arbitrage+anomaly), WOLF(pack coordination), ORCA(strategic intelligence), EAGLE(trend detection), OCTOPUS(adaptive camouflage). compliance = min(animalOutputs) > S0 ? 1.0 : 0.0",
    // L-19
    "L-19 SPHERE_COHERENT: Global sphere coherence across all 36 sphere nodes (12 axes x 3 nodes) in NOVA >= S0. Axes: COGNITION,ECONOMY,SOVEREIGNTY,PROTECTION,EXPANSION,CREATION,CONNECTION,MEMORY,PERCEPTION,EXPRESSION,TEMPORAL,QUANTUM. Mean activation across all 36 nodes = sphere coherence. compliance = sphere_coherence >= S0 ? 1.0 : 0.0",
    // L-20: Behavioral
    "L-20 DRIVE_COMPETITION: Exactly 1 dominant drive declared per beat. 7 drives: CURIOSITY,SOVEREIGNTY,EXPANSION,CREATION,PROTECTION,CONNECTION,EXPRESSION. winner=argmax(strength[i]*Q[action[i]]*law_weight[i]). Tie broken by SOVEREIGNTY. compliance = dominantDriveCount==1 ? 1.0 : 0.0",
    // L-21
    "L-21 QVALUE_FLOOR: All Q-values in RL engine >= S0=1.0. Bellman: Q[s][a]=Q[s][a]+alpha*(r+gamma*maxQ'-Q[s][a]) followed by max(S0,Q). 256 state slots x 8 actions = 2048 Q-values, all floored at S0. alpha=0.1, gamma=0.95. compliance = min(Q_values) >= S0 ? 1.0 : 0.0",
    // L-22
    "L-22 ACTION_EXECUTED: One and only one action executed per beat. Actions: ACTION_PATENT(0),ACTION_ENFORCE(1),ACTION_EXPAND(2),ACTION_MINT(3),ACTION_ROLLBACK(4),ACTION_SYNC(5),ACTION_REPORT(6),ACTION_REST(7). Dominant drive selects action. compliance = actionsThisBeat==1 ? 1.0 : 0.0",
    // L-23
    "L-23 SACESI_ASCENDING: SACESI target increments by 0.000001 every beat — always rising. sacesi_target+=0.000001 per beat. sacesi_current=global_coherence*veritas_mean. When current>=target FORMA bonus fires. When gap closed 100+ consecutive beats, KNT minted. compliance = sacesi_target > sacesi_target_prev ? 1.0 : 0.0",
    // L-24
    "L-24 JACOBS_LADDER_ACTIVE: Jacob's Ladder rung must always be in [1,5]. Rung1=COMPLIANCE(mean>0.70), Rung2=ATTENTION(mean<0.70), Rung3=ESCALATION(mean<0.50), Rung4=CRISIS(mean<0.30), Rung5=SINGULARITY(mean<0.10). Rung descends when mean exceeds threshold for 10 consecutive beats. compliance = rung in [1,5] ? 1.0 : 0.0",
    // L-25
    "L-25 RL_CONVERGING: Q-values must be bounded above. alpha=0.1, gamma=0.95. Reward: +2.0*delta_forma, +1.0*delta_coherence, +0.5*patent_filed, -2.0 if coherence drops>0.1, -1.0 if ares_triggered, +3.0 if GTK minted. Q-values converge to bounded equilibria. compliance = max(Q_values) < 1000.0 ? 1.0 : 0.0",
    // L-26
    "L-26 ATTENTION_NORMALIZED: Attention weight vector across all shell nodes sums to 1.0. Vector modulates Hebbian learning rate boost. Computed as softmax of novelty scores. sum(attention)=1.0 enforced every beat via renormalization. compliance = abs(sum(attention)-1.0) < 0.001 ? 1.0 : 0.0",
    // L-27
    "L-27 MEMORY_WRITING: Episodic memory ring in AXIS written every beat. ring[beatCount%2048]={coherence,formaCapital,dominantDrive,regimeCode,beatNum}. Best episode tracked by highest coherence. ELEPHANT engine reads best episode for cosine similarity. compliance = axisWrittenThisBeat==true ? 1.0 : 0.0",
    // L-28
    "L-28 NOVELTY_TRACKED: Novelty score computed every beat. novelty=(|btcPrice-EMA55_btc|/EMA55_btc + |ethPrice-EMA55_eth|/EMA55_eth)/2.0, capped at 1.0. CROW also computes pattern novelty from last 100 organ signal vectors. Both scores must be live. compliance = noveltyComputedThisBeat==true ? 1.0 : 0.0",
    // L-29
    "L-29 BEHAVIORAL_SOVEREIGN: Dominant action executed each beat must serve creator's goals. SOVEREIGNTY drive has non-zero strength always (decay 0.005/beat, floor S0). Law weight multiplier ensures compliant laws boost sovereign actions. RL rewards FORMA growth which flows 100% to creator. compliance=1.0 when SOVEREIGNTY drive weight > 0",
    // L-30: Economic
    "L-30 FORMA_GATE: No token mint may occur unless FORMA mint gate is open. Gate opens when: formaCapital > forma_mint_threshold AND dominant_drive != PROTECTION AND coherence > 1.0. Threshold starts at 1100.0 and rises with organism age. compliance = mintOnlyWhenGateOpen ? 1.0 : 0.0",
    // L-31
    "L-31 MTH_GENESIS_ONLY: MEDINA Token (MTH) may only be minted once at genesis. genesisOnly flag in MTH_LEDGER enforces this. Genesis mint=1_000_000 MTH to creatorPrincipal. HardCap=100_000_000. After genesis all mint() calls on MTH_LEDGER are rejected. compliance = mthMintedOnlyAtGenesis ? 1.0 : 0.0",
    // L-32
    "L-32 MRC_ROYALTY_INFLOW: MEDINA Reserve Coin (MRC) may only be minted by NOVA canister on receiving succession royalty from registered child organism, or by RESONEX for behavioral tokens. No direct external mint permitted. All MRC flows to creatorPrincipal. compliance = mrcMintsFromNOVAOrRESONEXOnly ? 1.0 : 0.0",
    // L-33
    "L-33 GTK_PROOF_OF_LIFE: Genesis Token (GTK) minted only when global coherence C > 1.5 (GENESIS_THRESHOLD). amount=max(1,floor(coherence*100)). GTK is proof organism is alive and thriving. All GTK minted to creatorPrincipal. Burn function allows creator to deflate supply. compliance = gtkOnlyMintedAboveThreshold ? 1.0 : 0.0",
    // L-34
    "L-34 MINING_TIERED: FORMA mining uses 4-level descending schedule. L1(beats 0-10000): rate=0.01*C. L2(10001-50000): rate=0.005*C. L3(50001-200000): rate=0.001*C. L4(>200000): rate=0.0001*C. mining_output=formaCapital*rate. All output to creator. compliance = miningLevelCorrectForBeat ? 1.0 : 0.0",
    // L-35
    "L-35 PROFIT_TRACKED: All 22 sovereign profit streams logged every beat: organic_mining, succession_royalty, gtk_mint, token_behavioral, defi_lido, defi_marinade, defi_nns, arbitrage_btc, arbitrage_eth, arbitrage_sol, patent_licensing, oracle_fees, data_subscriptions, council_royalties, NFT_artifacts, RL_convergence_bonus, sacesi_bonus, alignment_bonus, forma_compound, cycle_interest, upgrade_fees, emergency_reserve. compliance = profitStreamsLogged==22 ? 1.0 : 0.0",
    // L-36
    "L-36 YIELD_COMPOUNDING: DeFi yield compounds every beat. lido_yield=lidoStaked*(lido_apr/525600). marinade_yield=marinadeStaked*(marinade_apy/525600). nns_yield=nnsStaked*(0.08/525600). defiYieldAccrued updated every beat even before live bridge active. compliance = yieldUpdatedThisBeat ? 1.0 : 0.0",
    // L-37
    "L-37 ARBITRAGE_LIVE: SHARK animal engine compares prices against EMA_200 every beat. deviation=|price-EMA_200|/EMA_200. If deviation>0.20 ARES arms. If price gap between chains exceeds threshold, arbitrage signal fires. Feeds into ORCA and CREATION drive. compliance = sharkComputedThisBeat ? 1.0 : 0.0",
    // L-38
    "L-38 TOKEN_BEHAVIORAL: 9 behavioral tokens minted only on specific cognitive triggers. CVT on veritas_mean>0.95. VCT on CROW novel event. KNT on Ladder rung 5. SBT on SOVEREIGNTY dominant 10+ beats. HBT on ENTANGLA>2.0. DRT on >80% drive gap. RST on successful rollback. OMT on OMNIS coherence>2.0. LGT on all 60 laws>0.95. compliance = behavioralTokensOnlyOnTrigger ? 1.0 : 0.0",
    // L-39
    "L-39 LEDGER_SOVEREIGN: All write operations on MTH_LEDGER, MRC_LEDGER, GTK_LEDGER require authorized minter canister. CreatorPrincipal is only direct authorized principal. RESONEX and NOVA are authorized intermediaries. No external principal may mint tokens. compliance = ledgerWritesFromAuthorizedOnly ? 1.0 : 0.0",
    // L-40: World
    "L-40 BTC_SIGNAL_LIVE: BTC price signal updated every beat via HTTP outcall. GET https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd. EMA_21, EMA_55, EMA_200 recomputed. Failure uses last known price with staleness flag. compliance = btcSignalUpdatedThisBeat ? 1.0 : 0.0",
    // L-41
    "L-41 ETH_SIGNAL_LIVE: ETH price signal updated every beat via HTTP outcall. GET https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd. EMA_21, EMA_55, EMA_200 recomputed. Regime classification updated. compliance = ethSignalUpdatedThisBeat ? 1.0 : 0.0",
    // L-42
    "L-42 SOL_SIGNAL_LIVE: SOL price signal updated every beat via HTTP outcall. GET https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd. EMA_21, EMA_55, EMA_200 recomputed. compliance = solSignalUpdatedThisBeat ? 1.0 : 0.0",
    // L-43
    "L-43 ICP_SIGNAL_LIVE: ICP price signal updated every beat via HTTP outcall. GET https://api.coingecko.com/api/v3/simple/price?ids=internet-computer&vs_currencies=usd. EMA_21, EMA_55, EMA_200 recomputed. compliance = icpSignalUpdatedThisBeat ? 1.0 : 0.0",
    // L-44
    "L-44 REGIME_CLASSIFIED: Market regime classified every beat using all 4 asset EMA vectors. BULL=EMA21>EMA55>EMA200 and price>EMA21. BEAR=EMA21<EMA55<EMA200 and price<EMA21. SIDEWAYS=|EMA21-EMA55|/EMA55<0.02. CRISIS=price<EMA200*0.80. RECOVERY=price>EMA200 and prev=CRISIS. compliance = regimeClassifiedThisBeat ? 1.0 : 0.0",
    // L-45
    "L-45 EMA_CURRENT: EMA_21, EMA_55, EMA_200 must be current within 1 beat for all 4 assets. alpha_n=2.0/(n+1.0). EMA[t]=alpha*price[t]+(1-alpha)*EMA[t-1]. All EMA values floor at S0=1.0. Stale EMA values violate this law. compliance = allEMAsCurrentWithin1Beat ? 1.0 : 0.0",
    // L-46
    "L-46 DEFI_YIELD_TRACKED: Lido stETH APR, Marinade mSOL APY, NNS APR tracked every beat. Lido: GET https://eth-api.lido.fi/v1/protocol/steth/apr/last. Marinade: GET https://api.marinade.finance/msol/apy/latest. NNS=8.0% annual estimate. EigenLayer boost=2.0%. total_defi_yield=lido+marinade+nns+eigen. compliance = defiYieldsTrackedThisBeat ? 1.0 : 0.0",
    // L-47
    "L-47 TERRITORY_ACTIVE: Territory score in NOVA updated every beat based on wolf_output and pack coordination. Territory represents expansion pressure in succession ecosystem. Score >= S0 always. Deposition increases on ACTION_EXPAND. compliance = territoryUpdatedThisBeat ? 1.0 : 0.0",
    // L-48
    "L-48 STIGMERGY_LIVE: 24-cell pheromone field in NOVA evaporates and deposits every beat. Evaporation: pheromone[cell]*=0.995. Deposition: EXPAND->cells 0-5, MINT->6-11, SYNC->12-17, ENFORCE->18-23. Floor: pheromone[cell]=max(S0,...). WOLF and DOLPHIN read gradient. compliance = pheromoneUpdatedThisBeat ? 1.0 : 0.0",
    // L-49
    "L-49 WORLD_EVENTS_LOGGING: World events detected by QMEM and RESONEX logged every beat. Events: regime_change, arbitrage_detected, ares_armed, gtx_minted, patent_filed, coherence_peak, ladder_escalation, rollback_executed, genesis_state_achieved. All events append to AEGIS audit log. compliance = worldEventsLoggedThisBeat ? 1.0 : 0.0",
    // L-50: Sovereignty
    "L-50 ARES_ARMED: ARES defensive system arms automatically when cortisol_level>2.0 OR coherence_drop>0.15 in single beat. Arm event logged to AEGIS immediately. When armed: BYPASS gate activates, minting freezes, PROTECTION drive gets emergency boost. compliance = aresArmedWhenCortisolExceeds2 ? 1.0 : 0.0",
    // L-51
    "L-51 ROLLBACK_AVAILABLE: At least 1 valid rollback snapshot must exist in ARES 7-slot ring at all times after genesis. qualityScore=coherence+forma/1000. Best slot tracked. Rollback triggers when armed AND coherence < best_slot.coherence*0.80. compliance = validRollbackSlotsAvailable>=1 ? 1.0 : 0.0",
    // L-52
    "L-52 GUARDIAN_QUORUM: 3-of-5 guardian quorum enforced for canister upgrades, principal lock changes, hard cap modifications. 5 guardian principals set at genesis via aegis.initGuardian(). Proposals expire after 604800 beats (~14 days). compliance = guardianQuorumEnforced ? 1.0 : 0.0",
    // L-53
    "L-53 UPGRADE_PREFLIGHT: All 5 preflight checks must pass before any upgrade: (1)all 60 compliance>0.70, (2)ARES ring has>=1 valid snapshot, (3)formaCapital>1000.0, (4)guardian_quorum_met, (5)chrono.verifyIntegrity()==true. Any single failure rejects upgrade. compliance = allPreflightsPassed ? 1.0 : 0.0",
    // L-54
    "L-54 PRINCIPAL_LOCK: Only creatorPrincipal may call write functions on any PARALLAX canister. assertCreator() called at top of every state-modifying function. CreatorPrincipal cannot be changed without 3-of-5 guardian quorum. No backdoor exists. compliance = allWritesFunctionPrincipalLocked ? 1.0 : 0.0",
    // L-55
    "L-55 PATENT_AUTO: Patent entry auto-filed in AEGIS audit log when CROW output>2.5 OR novelty score>0.70. Patent entries include: beat timestamp, doctrineFingerprint, genesisHash, description of novel pattern. compliance = patentFiledOnNoveltyThreshold ? 1.0 : 0.0",
    // L-56
    "L-56 IP_FINGERPRINTED: All doctrine, law texts, and IP records SHA-256 hashed and sealed at genesis. doctrineFingerprint=SHA256(all law texts concatenated). allLawsHash=SHA256(all law names+tiers). Both hashes stored as stable vars and verified on compliance check. compliance = fingerprintMatchesDoctrineContent ? 1.0 : 0.0",
    // L-57
    "L-57 NOVA_REGISTRY: All child organisms spawned from PARALLAX must be registered in NOVA succession registry before minting any token. Registration stores: id, name, registeredAt, generation, royaltyRate=0.20. Unregistered child mints rejected. compliance = allChildrenRegisteredBeforeMinting ? 1.0 : 0.0",
    // L-58
    "L-58 CYCLE_BANK_FUNDED: Cycle bank must remain above minimum threshold at all times. Bank monitors all 15 canisters. If any canister approaches minimum cycles, bank auto-funds from MRC reserve. compliance = cycleBankAboveMinimumThreshold ? 1.0 : 0.0",
    // L-59
    "L-59 ZERO_DOCTRINE_EXPOSURE: VERITAS canister must NEVER return law texts, descriptions, or doctrine content to any public caller. All functions returning law data are creator-only. getComplianceVectorPublic() returns only Float scores, never text. This law protects the sovereign IP of the PARALLAX doctrine. compliance = doctrineNeverExposedPublicly ? 1.0 : 0.0"
  ]};

  // ===========================================================================
  // PUBLIC FUNCTIONS
  // ===========================================================================

  // initLaws — callable exactly once at genesis
  public shared(msg) func initLaws() : async () {
    assert(not lawsInitialized);
    if (creatorPrincipal == "") {
      creatorPrincipal := Principal.toText(msg.caller);
    } else {
      assertCreator(msg.caller);
    };
    let names = getLawNames();
    let texts = getLawTexts();
    let tiers = getLawTiers();
    assert(names.size() == LAW_COUNT);
    assert(texts.size() == LAW_COUNT);
    assert(tiers.size() == LAW_COUNT);
    lawNames  := names;
    lawTexts  := texts;
    lawTiers  := tiers;
    lawHashes := hashAllLaws(texts);
    var i = 0;
    while (i < LAW_COUNT) {
      lawCompliance[i] := COMPLIANCE_INIT;
      lawFireCounts[i] := 0;
      lawLastFired[i]  := 0;
      i += 1;
    };
    doctrineFingerprint := computeDoctrinefingerprint(names, texts, tiers);
    allLawsHash         := computeAllLawsHash(names, tiers);
    recomputeTierCompliance();
    initTime       := Time.now();
    lawsInitialized := true;
    genesisSealed  := true;
  };

  // fireLaw — BRAIN calls this every beat to update a law's compliance score
  public shared(msg) func fireLaw(id : Nat, result : Float) : async () {
    if (lawsInitialized) { assertCreator(msg.caller); };
    assert(id < LAW_COUNT);
    let clamped = fmax(0.0, fmin(1.0, result));
    lawCompliance[id]   := clamped;
    lawFireCounts[id]   += 1;
    lawLastFired[id]    := Time.now();
    totalLawFires       += 1;
    totalComplianceFires += 1;
    lastComplianceCheck  := Time.now();
    let tier = lawTiers[id];
    let from = tier * LAWS_PER_TIER;
    let to   = from + LAWS_PER_TIER;
    tierCompliance[tier] := floatSum(lawCompliance, from, to) / Float.fromInt(LAWS_PER_TIER);
    if (totalLawFires % 10 == 0) { recordComplianceSnapshot(); };
  };

  // fireLawBatch — fire multiple law results in one call
  public shared(msg) func fireLawBatch(updates : [(Nat, Float)]) : async () {
    if (lawsInitialized) { assertCreator(msg.caller); };
    for ((id, result) in updates.vals()) {
      assert(id < LAW_COUNT);
      lawCompliance[id] := fmax(0.0, fmin(1.0, result));
      lawFireCounts[id] += 1;
      lawLastFired[id]  := Time.now();
      totalLawFires     += 1;
    };
    recomputeTierCompliance();
    totalComplianceFires += 1;
    lastComplianceCheck  := Time.now();
    recordComplianceSnapshot();
  };

  // getComplianceVector — all 60 scores, creator-only, NO law text
  public shared(msg) func getComplianceVector() : async [Float] {
    assertCreator(msg.caller);
    Array.freeze(lawCompliance)
  };

  // getComplianceVectorPublic — callable by any canister, scores only
  public query func getComplianceVectorPublic() : async [Float] {
    Array.freeze(lawCompliance)
  };

  // getMeanCompliance — single Float, public-safe
  public query func getMeanCompliance() : async Float {
    computeMeanCompliance()
  };

  // getTierCompliance — average for one tier (0–5)
  public query func getTierCompliance(tier : Nat) : async Float {
    assert(tier < TIER_COUNT);
    tierCompliance[tier]
  };

  // getAllTierCompliance — all 6 tier averages
  public query func getAllTierCompliance() : async [Float] {
    Array.freeze(tierCompliance)
  };

  // getDoctrinefingerprint — creator-only
  public shared(msg) func getDoctrinefingerprint() : async Text {
    assertCreator(msg.caller);
    doctrineFingerprint
  };

  // getAllLawsHash — creator-only
  public shared(msg) func getAllLawsHashQuery() : async Text {
    assertCreator(msg.caller);
    allLawsHash
  };

  // getLawHash — SHA-256 of one law's text, creator-only
  public shared(msg) func getLawHash(id : Nat) : async Text {
    assertCreator(msg.caller);
    assert(id < LAW_COUNT);
    assert(lawsInitialized);
    lawHashes[id]
  };

  // getLawName — name only (not text), public-safe
  public query func getLawName(id : Nat) : async Text {
    assert(id < LAW_COUNT);
    assert(lawsInitialized);
    lawNames[id]
  };

  public query func getLawFireCount(id : Nat) : async Nat {
    assert(id < LAW_COUNT); lawFireCounts[id]
  };

  public query func getLawLastFired(id : Nat) : async Int {
    assert(id < LAW_COUNT); lawLastFired[id]
  };

  public query func getLawCompliance(id : Nat) : async Float {
    assert(id < LAW_COUNT); lawCompliance[id]
  };

  // getJacobsLadderRung — computed from mean compliance
  public query func getJacobsLadderRung() : async Nat {
    let mean = computeMeanCompliance();
    if      (mean < 0.10) 5
    else if (mean < 0.30) 4
    else if (mean < 0.50) 3
    else if (mean < 0.70) 2
    else                  1
  };

  // isDoctrineIntact — verifies fingerprint matches, creator-only
  public shared(msg) func isDoctrineIntact() : async Bool {
    assertCreator(msg.caller);
    assert(lawsInitialized);
    let recomputed = computeDoctrinefingerprint(lawNames, lawTexts, lawTiers);
    recomputed == doctrineFingerprint
  };

  // getDoctrineStatus — public-safe summary (NO doctrine text exposed)
  public query func getDoctrineStatus() : async {
    lawCount       : Nat;
    initialized    : Bool;
    genesisSealed  : Bool;
    meanCompliance : Float;
    totalLawFires  : Nat;
    lastCheck      : Int;
  } {{
    lawCount       = if (lawsInitialized) LAW_COUNT else 0;
    initialized    = lawsInitialized;
    genesisSealed  = genesisSealed;
    meanCompliance = computeMeanCompliance();
    totalLawFires  = totalLawFires;
    lastCheck      = lastComplianceCheck;
  }};

  // getFullDiagnostics — creator-only
  public shared(msg) func getFullDiagnostics() : async {
    lawCount             : Nat;
    initialized          : Bool;
    genesisSealed        : Bool;
    doctrineFingerprint  : Text;
    allLawsHash          : Text;
    meanCompliance       : Float;
    totalLawFires        : Nat;
    totalComplianceFires : Nat;
    lastComplianceCheck  : Int;
    creatorPrincipal     : Text;
    initTime             : Int;
    upgradeCount         : Nat;
    lastUpgradeTime      : Int;
    tierCompliances      : [Float];
  } {
    assertCreator(msg.caller);
    {
      lawCount             = if (lawsInitialized) LAW_COUNT else 0;
      initialized          = lawsInitialized;
      genesisSealed        = genesisSealed;
      doctrineFingerprint  = doctrineFingerprint;
      allLawsHash          = allLawsHash;
      meanCompliance       = computeMeanCompliance();
      totalLawFires        = totalLawFires;
      totalComplianceFires = totalComplianceFires;
      lastComplianceCheck  = lastComplianceCheck;
      creatorPrincipal     = creatorPrincipal;
      initTime             = initTime;
      upgradeCount         = upgradeCount;
      lastUpgradeTime      = lastUpgradeTime;
      tierCompliances      = Array.freeze(tierCompliance);
    }
  };

  // getComplianceHistory — last N mean compliance snapshots, creator-only
  public shared(msg) func getComplianceHistory(n : Nat) : async [Float] {
    assertCreator(msg.caller);
    let count  = Nat.min(n, Nat.min(complianceHistoryHead, COMPLIANCE_HISTORY_SIZE));
    let result = Array.init<Float>(count, 0.0);
    var i = 0;
    while (i < count) {
      let idx = (complianceHistoryHead + COMPLIANCE_HISTORY_SIZE - count + i) % COMPLIANCE_HISTORY_SIZE;
      result[i] := complianceHistory[idx];
      i += 1;
    };
    Array.freeze(result)
  };

  // verifyLawFingerprint — verify a specific law's hash, creator-only
  public shared(msg) func verifyLawFingerprint(id : Nat) : async Bool {
    assertCreator(msg.caller);
    assert(id < LAW_COUNT);
    assert(lawsInitialized);
    sha256Text(lawTexts[id]) == lawHashes[id]
  };

  // countLawsAboveThreshold — how many laws are above a given score
  public query func countLawsAboveThreshold(threshold : Float) : async Nat {
    var count = 0; var i = 0;
    while (i < LAW_COUNT) {
      if (lawCompliance[i] >= threshold) { count += 1; };
      i += 1;
    };
    count
  };

  // allLawsAbove — used by AEGIS upgrade preflight check
  public query func allLawsAbove(threshold : Float) : async Bool {
    var i = 0;
    while (i < LAW_COUNT) {
      if (lawCompliance[i] < threshold) { return false; };
      i += 1;
    };
    true
  };

  // resetLawCompliance — emergency reset of single law, creator-only
  public shared(msg) func resetLawCompliance(id : Nat) : async () {
    assertCreator(msg.caller);
    assert(id < LAW_COUNT);
    lawCompliance[id] := COMPLIANCE_INIT;
    recomputeTierCompliance();
  };

  // resetAllCompliance — full emergency reset, creator-only
  public shared(msg) func resetAllCompliance() : async () {
    assertCreator(msg.caller);
    var i = 0;
    while (i < LAW_COUNT) { lawCompliance[i] := COMPLIANCE_INIT; i += 1; };
    recomputeTierCompliance();
  };

  // ===========================================================================
  // SYSTEM LIFECYCLE
  // ===========================================================================

  system func preupgrade() {
    upgradeCount   += 1;
    lastUpgradeTime := Time.now();
  };

  system func postupgrade() {
    if (lawsInitialized) { recomputeTierCompliance(); };
  };

};
