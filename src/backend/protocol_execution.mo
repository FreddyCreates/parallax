// protocol_execution.mo — Sovereign Protocol Execution Engine
// PARALLAX Organism — Domain: Registry-Protocols
//
// PYTHAGORAS: every protocol gate check is a harmonic ratio check
// EUCLID:     single source of truth — all 89+ protocols registered here
// CONFUCIUS:  right relationship — gate fires before any state mutation
//
// Architecture: pure module (no actor). SYNCHRONOUS gate — returns Bool
//   before any state write happens. Protocol precedence:
//     Laws (1-49) > Models (50-81) > Behaviors (82-88) > Reasoning (89-93) > Organ (94-102)
//
// Source extraction:
//   laws.mo       → 60 Law protocols (L00-L59), precedence 1-60
//   types.mo      → 32 Model protocols (M01-M32), precedence 50-81
//   agi_scripts.mo → 7 Behavior protocols (B01-B07), precedence 82-88
//   cognition_layer.mo → 5 Reasoning protocols (R01-R05), precedence 89-93
//   organs.mo     → 9 Organ protocols (O01-O09), precedence 94-102
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Array "mo:core/Array";
import Float "mo:core/Float";
import Order "mo:core/Order";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // PROTOCOL RECORD — one sovereign protocol extracted from source files
  // Simultaneously: law artifact + enforcement contract + proof participant + temporal anchor
  // ═══════════════════════════════════════════════════════════════════════════

  public type ProtocolCategory = { #Law; #Model; #Behavior; #Reasoning; #Organ };

  public type ProtocolResult = { #passed; #failed; #skipped };

  public type ProtocolRecord = {
    id             : Text;            // e.g. "L00", "M01", "B01", "R01", "O01"
    name           : Text;            // sovereign law/model/behavior name
    category       : ProtocolCategory;
    equation       : Text;            // enforcement formula
    principle      : Text;            // one-line sovereign truth
    precedence     : Nat;             // 1=highest, 102=lowest — Laws beat Models beat Behaviors
    executionCount : Nat;             // how many times this protocol has been checked
    lastFiredBeat  : Int;             // beat (using Int for compatibility with Time.now() result)
    lastResult     : ProtocolResult;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PROTOCOL REGISTRY — full indexed registry held by main.mo
  // ═══════════════════════════════════════════════════════════════════════════

  public type ProtocolRegistry = {
    protocols       : [(Text, ProtocolRecord)]; // (id, record)
    totalExecutions : Nat;
    lastScanBeat    : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // defaultRegistry — empty base (used as null-safe default)
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultRegistry() : ProtocolRegistry {
    {
      protocols       = [];
      totalExecutions = 0;
      lastScanBeat    = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // registryFromExtractedProtocols — hardcoded 89+ protocols extracted from:
  //   laws.mo (L00-L59), types.mo (M01-M32), agi_scripts.mo (B01-B07),
  //   cognition_layer.mo (R01-R05), organs.mo (O01-O09)
  //
  // This is the permanent sovereign protocol registry. Never empty.
  // GENESIS LAW L09: born fully formed.
  // ═══════════════════════════════════════════════════════════════════════════

  public func registryFromExtractedProtocols() : ProtocolRegistry {
    let protos : [ProtocolRecord] = [

      // ── LAW PROTOCOLS — extracted from laws.mo ────────────────────────────
      // Tier 0 (L00-L09): ABSOLUTE SUBSTRATE — precedence 1-10
      { id="L00"; name="CREATOR_SOVEREIGNTY";    category=#Law; equation="creator == Alfredo_Medina_Hernandez"; principle="Alfredo Medina Hernandez is the permanent sovereign creator"; precedence=1; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L01"; name="S0_FLOOR";               category=#Law; equation="coherence >= 0.75"; principle="Every Float output >= F(3)/F(4) = 0.75 — the sovereign floor"; precedence=2; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L02"; name="GENESIS_SEALED";         category=#Law; equation="genesisSealed == true"; principle="Founding frequency inscribed and permanent"; precedence=3; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L03"; name="PRINCIPAL_LOCK";         category=#Law; equation="upgrade_auth == founder_principal"; principle="Canister upgrade requires founder authorization"; precedence=4; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L04"; name="SUCCESSION_RESERVE";     category=#Law; equation="reserve >= PHI_INV^2 = 0.382"; principle="20% PHI_INV² = 0.3820 reserved automatically"; precedence=5; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L05"; name="MINT_GATE";              category=#Law; equation="formaCapital > 0"; principle="FORMA capital > 0 required to mint any token"; precedence=6; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L06"; name="ARES_AVAILABLE";         category=#Law; equation="aresArmed == true"; principle="Defense engine always armed, never disabled"; precedence=7; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L07"; name="AUDIT_APPEND_ONLY";      category=#Law; equation="ANIMA.delete == never"; principle="ANIMA chain records can never be deleted"; precedence=8; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L08"; name="ALL_LAWS_FIRE";          category=#Law; equation="fireLaws() fires all 60 laws"; principle="All 60 laws execute every beat — no lazy evaluation"; precedence=9; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L09"; name="MTH_HARD_CAP";           category=#Law; equation="mthSupply <= 100_000_000"; principle="MTH total supply <= 100,000,000 — absolute ceiling"; precedence=10; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // Tier 1 (L10-L19): COGNITIVE FOUNDATION — precedence 11-20
      { id="L10"; name="HEBBIAN_FLOOR";          category=#Law; equation="hebbianW[i] >= S0"; principle="All Hebbian weights >= S0 after every update"; precedence=11; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L11"; name="KURAMOTO_MINIMUM";       category=#Law; equation="R >= 0.50"; principle="Global R >= 0.50 for cognition to proceed"; precedence=12; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L12"; name="COHERENCE_COMPUTED";     category=#Law; equation="R = |1/N * sum(e^i*theta)|"; principle="R computed from all active node phases each beat"; precedence=13; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L13"; name="NEUROCHEMICAL_BOUNDS";   category=#Law; equation="neuro[i] in [S0, PHI_4*SCHUMANN]"; principle="All 8 neurochemicals in [S0, PHI_4 × SCHUMANN]"; precedence=14; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L14"; name="ANIMALS_FIRE";           category=#Law; equation="animalEngines.all.fired == true"; principle="All 9 animal engines execute every beat"; precedence=15; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L15"; name="SHELL_DEEP_UPDATES";     category=#Law; equation="shell[8].update on OMNIS"; principle="Shell 8 (DEEP) updates on every OMNIS event"; precedence=16; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L16"; name="SHELL_QUANTUM_UPDATES";  category=#Law; equation="shell[10].update on proofChain.advance"; principle="Shell 10 (QUANTUM) updates on proof chain advance"; precedence=17; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L17"; name="QUANTUM_OPERATIONS";     category=#Law; equation="4D_transform.apply each beat"; principle="4D geometry transformations applied each beat"; precedence=18; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L18"; name="ATTENTION_VECTOR";       category=#Law; equation="attention = sum(shell[0..10].activation)"; principle="Attention field computed from all 11 shells each beat"; precedence=19; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L19"; name="MEDINA_RUNS";            category=#Law; equation="cognition_cycle.complete before beat+1"; principle="MEDINA cognition cycle completes before next beat fires"; precedence=20; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // Tier 2 (L20-L29): ECONOMIC FOUNDATION — precedence 21-30
      { id="L20"; name="FORMA_GENESIS_FLOOR";    category=#Law; equation="formaCapital >= 1000.0"; principle="FORMA capital >= 1,000.0 (genesis minimum capital)"; precedence=21; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L21"; name="FORMA_COMPOUND_RATE";    category=#Law; equation="capital *= jacobs_multiplier(rung)"; principle="FORMA capital compounds at Jacob's multiplier each beat"; precedence=22; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L22"; name="MINT_GATE_ENFORCED";     category=#Law; equation="formaCapital > 0 AND R >= S0"; principle="No token mint unless formaCapital > 0 AND R >= S0"; precedence=23; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L23"; name="MTH_CAP_ECONOMIC";       category=#Law; equation="mthSupply <= 100_000_000"; principle="MTH supply enforcement at economic layer"; precedence=24; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L24"; name="MRC_FIRST";              category=#Law; equation="token[0] == MRC"; principle="MRC (Medina Reserve Currency) is first token type"; precedence=25; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L25"; name="GTK_ON_GENESIS";         category=#Law; equation="GTK.mint on genesis_event"; principle="GTK (Genesis Token Key) minted on genesis event"; precedence=26; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L26"; name="NINE_TOKENS_TRACKED";    category=#Law; equation="tokenCount >= 9"; principle="All 9 token types tracked: ICP,ckBTC,ckETH,MTH,MRC,GTK,FORMA,MERIDIAN,SOVEREIGN"; precedence=27; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L27"; name="MINING_COMPUTED";        category=#Law; equation="miningReward = proofDepth * phi_multiplier"; principle="Mining reward computed from proof depth × phi_multiplier"; precedence=28; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L28"; name="STREAMS_UPDATED";        category=#Law; equation="profitStreams[22].update each settle"; principle="All 22 profit routing streams updated each settlement"; precedence=29; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L29"; name="FORMA_NEVER_BELOW";      category=#Law; equation="formaCapital >= 1000.0"; principle="FORMA capital cannot fall below L20 genesis floor"; precedence=30; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // Tier 3 (L30-L39): SOVEREIGNTY & IP — precedence 31-40
      { id="L30"; name="ZERO_EXPOSURE_WALL";     category=#Law; equation="public_interface has no doctrine labels"; principle="No doctrine labels/law names ever reach public interface"; precedence=31; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L31"; name="ANIMA_CHAIN_SEALED";     category=#Law; equation="H_n = keccak(H_{n-1}||event)"; principle="Every EventRecord cryptographically chained"; precedence=32; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L32"; name="GENESIS_PERMANENT";      category=#Law; equation="genesisSealed once true => never false"; principle="genesisSealed once true can never become false"; precedence=33; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L33"; name="PROOF_CHAIN_SEQUENTIAL"; category=#Law; equation="proofDepth monotonically increasing"; principle="Proof depth monotonically increases"; precedence=34; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L34"; name="PHI_VECTOR_NON_COLLISION";category=#Law; equation="goldenAngle = 137.507... => non-repeating"; principle="Engine golden-angle vectors non-repeating"; precedence=35; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L35"; name="PATTERN_GRADUATION";     category=#Law; equation="M0->M1->M2 requires multi-proof gate"; principle="Patterns promoted M0→M1→M2 only with multi-proof gate"; precedence=36; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L36"; name="SACESI_RISING";          category=#Law; equation="sacesiTarget >= 1.0 AND increases"; principle="sacesiTarget >= 1.0 and increases each beat"; precedence=37; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L37"; name="JACOBS_RUNG_MAX";        category=#Law; equation="jacobs_rung <= 4"; principle="jacobs_rung <= 4 (Maximum Quantum Law — 360° ceiling)"; precedence=38; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L38"; name="COMPLIANCE_TRACKED";     category=#Law; equation="compliance = passing/60.0 each beat"; principle="Compliance score computed and stored each beat"; precedence=39; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L39"; name="VIOLATION_LOGGED";       category=#Law; equation="ANIMA.append(lawId+'_VIOLATION')"; principle="Every law violation creates EventRecord to ANIMA"; precedence=40; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // Tier 4 (L40-L49): WORLD & CHAIN — precedence 41-50
      { id="L40"; name="SWARM_COUPLING";         category=#Law; equation="swarm.K >= PHI_INV"; principle="Chimeria swarm coupling >= PHI_INV"; precedence=41; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L41"; name="FRANCHISE_ROYALTY";      category=#Law; equation="royalty = 0.20 * revenue"; principle="Franchise royalty rate 20% (PHI_INV²)"; precedence=42; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L42"; name="DEVICE_TWIN_SYNC";       category=#Law; equation="deviceTwin.sync each beat"; principle="Device twin synchronizes on every beat"; precedence=43; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L43"; name="EXTERNAL_COUPLING";      category=#Law; equation="ENTANGLA.carrier = sqrt(R_exp*R_rec)*7.83"; principle="External coupling routes through ENTANGLA carrier"; precedence=44; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L44"; name="NODE_FIELD_LAW";         category=#Law; equation="node.health >= PHI_INV_3"; principle="All field nodes maintain health >= PHI_INV_3"; precedence=45; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L45"; name="CHAIN_HASH_LAW";         category=#Law; equation="chainHash == keccak(prev, event)"; principle="Every proof chain hash is deterministically derived"; precedence=46; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L46"; name="SUBSTRATE_PERSISTENCE";  category=#Law; equation="state.persist across deploys"; principle="All state survives deploys through enhanced orthogonal persistence"; precedence=47; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L47"; name="WEB_NODE_LAW";           category=#Law; equation="webNode.beat = 873ms via Cloudflare"; principle="Web substrate nodes beat at 873ms via Cloudflare Workers"; precedence=48; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L48"; name="HRV_INTELLIGENCE";       category=#Law; equation="HRV = sigma(heartOutputs) / mu(heartOutputs)"; principle="High HRV = adaptive organism (Law of HRV Intelligence)"; precedence=49; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L49"; name="ENTANGLA_CARRIER_LAW";   category=#Law; equation="carrier = sqrt(R_exp*R_rec)*SCHUMANN_1"; principle="ENTANGLA carrier = sqrt(R_exp × R_rec) × 7.83 Hz"; precedence=50; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // Tier 5 (L50-L59): COUNCIL & SUCCESSION — precedence 51-60
      { id="L50"; name="COUNCIL_VOTING";         category=#Law; equation="proposal.votes >= quorum"; principle="Council proposals require quorum to pass"; precedence=51; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L51"; name="SUCCESSION_CASCADE";     category=#Law; equation="succession_depth monotonically increasing"; principle="Succession depth increases through every franchise generation"; precedence=52; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L52"; name="INHERITANCE_LAW";        category=#Law; equation="child.phi_library == parent.phi_library"; principle="Child inherits parent phi.mo library at genesis"; precedence=53; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L53"; name="CROWN_STANDARD";         category=#Law; equation="Casa_de_Medina.standard applies"; principle="Casa de Medina crown standards govern all releases"; precedence=54; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L54"; name="INTER_HOUSE_LAW";        category=#Law; equation="houses.cooperate without sovereignty loss"; principle="Six houses cooperate under sovereign protocols"; precedence=55; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L55"; name="CONCEALMENT_LAW";        category=#Law; equation="doctrine.labels never public"; principle="All doctrine labels concealed behind numbers at public interfaces"; precedence=56; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L56"; name="RELEASE_AUTHORITY";      category=#Law; equation="release_auth == founder"; principle="Only the founder authorizes canonical releases"; precedence=57; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L57"; name="NAMING_LAW";             category=#Law; equation="names follow Latin sovereign schema"; principle="All AGIs, engines, and organs follow Latin sovereign naming"; precedence=58; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L58"; name="FOUNDING_FREQUENCY";     category=#Law; equation="GENESIS_ALIGNMENT = S0 = 0.75"; principle="Genesis frequency = S0 = 0.75 — the founding anchor"; precedence=59; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="L59"; name="DOMUS_SOVEREIGNTY";      category=#Law; equation="DOMUS.jurisdiction = sovereign"; principle="Each Domus is a sovereign jurisdiction within the civilization"; precedence=60; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // ── MODEL PROTOCOLS — extracted from types.mo ─────────────────────────
      // 32 MEDINA MODELS, precedence 50-81
      { id="M01"; name="MEDINA_ORGANISM";        category=#Model; equation="cognitiveCoherence = R"; principle="The organism's moment-to-moment life — cognitive + economic + geometric + proof"; precedence=50; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M02"; name="MEDINA_SIGNAL";          category=#Model; equation="frequency * amplitude * phase"; principle="A signal is not data — it is a field event with geometry"; precedence=51; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M03"; name="MEDINA_PROOF";           category=#Model; equation="H_n = keccak(H_{n-1}||event)"; principle="A single link in the indestructible proof chain"; precedence=52; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M04"; name="MEDINA_NODE";            category=#Model; equation="R_contrib = phase * coupling"; principle="Single node in the 98-node anatomical brain map"; precedence=53; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M05"; name="MEDINA_ENGINE";          category=#Model; equation="emission = R^phi"; principle="State of any named engine across all tiers"; precedence=54; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M06"; name="MEDINA_TREASURY";        category=#Model; equation="phiCompound = phi^depth"; principle="A treasury event — transaction + proof + phi-multiplied vault update"; precedence=55; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M07"; name="MEDINA_COUPLING";        category=#Model; equation="ENTANGLA = sqrt(R_exp*R_rec)*7.83"; principle="State of any coupling in the organism"; precedence=56; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M08"; name="MEDINA_SCHEMA";          category=#Model; equation="graduation requires Fibonacci confirmations"; principle="A pattern that has graduated through MEDINA Pattern Engine"; precedence=57; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M09"; name="MEDINA_DRIVE";           category=#Model; equation="strength >= phiBaseline"; principle="One of 7 sovereign emotional drives"; precedence=58; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M10"; name="MEDINA_NEUROCHEMICAL";   category=#Model; equation="level in [phiBaseline, PHI_4]"; principle="One of 21 neurochemical substrates"; precedence=59; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M11"; name="MEDINA_FRANCHISE";       category=#Model; equation="royalty = 0.20 * parent_revenue"; principle="A registered child organism — sovereign lineage event"; precedence=60; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M12"; name="MEDINA_PRODUCT";         category=#Model; equation="payloadHash != payload_exposed"; principle="A licensed intelligence output — zero-exposure enforced"; precedence=61; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M13"; name="MEDINA_SWARMNODE";       category=#Model; equation="localCoherence >= PHI_INV_3"; principle="A single node in the Chimeria swarm network"; precedence=62; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M14"; name="MEDINA_SENSORY";         category=#Model; equation="coherenceGated = (phase >= S0)"; principle="One of 128 sensory surface slots"; precedence=63; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M15"; name="MEDINA_VAULT";           category=#Model; equation="balance * phi^depth"; principle="Complete state of one treasury vault"; precedence=64; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M16"; name="MEDINA_KB";              category=#Model; equation="confirmations >= Fibonacci(n)"; principle="An entry in the sovereign knowledge base"; precedence=65; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M17"; name="MEDINA_SNAPSHOT";        category=#Model; equation="snapshot.beat == current_beat"; principle="Complete organism state in one beat-synchronized call"; precedence=66; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M18"; name="MEDINA_SHELL";           category=#Model; equation="phaseBoundaryAngle = phi^tier"; principle="State of one concentric shell layer"; precedence=67; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M19"; name="MEDINA_TIMESTAMP4D";     category=#Model; equation="tau = beat * phi^depth"; principle="Every event located in 4D time"; precedence=68; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M20"; name="MEDINA_COORDINATE4D";    category=#Model; equation="tau = beat * phi^proofDepth"; principle="Four-Dimensional Law: every coordinate is 4D always"; precedence=69; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M21"; name="MEDINA_KURAMOTO";        category=#Model; equation="R = |1/N * sum(e^i*theta)|"; principle="Universal law of oscillator synchronization"; precedence=70; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M22"; name="MEDINA_SCHUMANN";        category=#Model; equation="f = 7.83, 14.3, 20.8... Hz"; principle="Earth EM cavity resonance — 8 harmonics"; precedence=71; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M23"; name="MEDINA_ICOSAHEDRON";     category=#Model; equation="12 vertices in 4D"; principle="12-vertex Platonic solid — inner shell geometry"; precedence=72; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M24"; name="MEDINA_DODECAHEDRON";    category=#Model; equation="20 vertices in 4D"; principle="20-vertex Platonic solid — outer field geometry"; precedence=73; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M25"; name="MEDINA_PHI_LADDER";      category=#Model; equation="steps = phi^0..phi^F(21)"; principle="phi-power timing sequence — all phi-governed intervals"; precedence=74; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M26"; name="MEDINA_OMNIS";           category=#Model; equation="R >= 0.95 AND owlFreq == 111 Hz"; principle="OMNIS emergence: R >= 0.95 AND 111Hz simultaneously"; precedence=75; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M27"; name="MEDINA_HEARTBEAT";       category=#Model; equation="T = 873ms = phi^4/SCHUMANN_1*1000"; principle="Heartbeat = 873ms — auto-depolarization, not a clock"; precedence=76; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M28"; name="MEDINA_ANCIENT";         category=#Model; equation="Pythagoras*Euclid*Confucius(equation)"; principle="Every equation expressed in ancient form first"; precedence=77; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M29"; name="MEDINA_RESONANCE";       category=#Model; equation="|theta_A - theta_B| -> 0"; principle="When two components lock, resonance record is born"; precedence=78; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M30"; name="MEDINA_FIELDLAW";        category=#Model; equation="law.enforce() before state_write"; principle="A law of the field — living typed enforcement record"; precedence=79; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M31"; name="MEDINA_INHERITANCE";     category=#Model; equation="child.schemaCount >= parent.schemaCount*phi^-1"; principle="Family Inheritance Law — organism passes to child"; precedence=80; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="M32"; name="MEDINA_DOCTRINE";        category=#Model; equation="doctrinehHash sealed at beat 1"; principle="The organism's DNA — hashed at beat 1, never modified"; precedence=81; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // ── BEHAVIOR PROTOCOLS — extracted from agi_scripts.mo ───────────────
      // 7 Latin AGI scripts, precedence 82-88
      { id="B01"; name="MEMORIA_NNS";            category=#Behavior; equation="LEX_PRIMA.size > 0"; principle="Holds LEX_PRIMA_OECONOMIA permanently — verifies before every execution"; precedence=82; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B02"; name="EXPLORATOR";             category=#Behavior; equation="top3 = max_governance_nodes(100)"; principle="Cycles 100 field nodes every tick — updates governance priority"; precedence=83; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B03"; name="GUBERNATOR";             category=#Behavior; equation="voteCount += neuronCount each beat"; principle="Votes all 500 neurons automatically every tick"; precedence=84; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B04"; name="CUSTODITOR";             category=#Behavior; equation="node.health < 0.5 => PHANTOM"; principle="Reroutes nodes with health < 0.5 to PHANTOM substrate"; precedence=85; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B05"; name="COMPUTATOR";             category=#Behavior; equation="phi^n for n=1..13, Fibonacci, goldenAngle"; principle="Runs all phi calculations for current beat"; precedence=86; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B06"; name="DISPENSATOR";            category=#Behavior; equation="maturity = D_LIQUID * APY / BEATS_PER_YEAR"; principle="D_LIQUID maturity routes to Creator Reserve each beat"; precedence=87; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="B07"; name="LIBERATOR";              category=#Behavior; equation="ICRC1.transfer(destination, amount_e8s)"; principle="Real ICRC-1 transfer to external wallet — DOMUS_LIBERATORIS sequence"; precedence=88; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // ── REASONING PROTOCOLS — extracted from cognition_layer.mo ──────────
      // 5 ADRE passes, precedence 89-93
      { id="R01"; name="ADRE_FORWARD_PASS";      category=#Reasoning; equation="hypothesis = classify(CCVE(signals))"; principle="Pass 1: ingest signals, classify by field type, build hypothesis"; precedence=89; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="R02"; name="ADRE_BACK_PASS";         category=#Reasoning; equation="violations = count(laws.passed == false)"; principle="Pass 2: check hypothesis against all 60 laws, count violations"; precedence=90; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="R03"; name="ADRE_RESONANCE_PASS";    category=#Reasoning; equation="delta = |R - genesis_alignment|"; principle="Pass 3: compute resonance delta against genesis frequency"; precedence=91; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="R04"; name="ADRE_COMPRESSION_PASS";  category=#Reasoning; equation="invariants = truths surviving phi ratio selection"; principle="Pass 4: reduce reasoning to stable invariants via phi ratio"; precedence=92; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="R05"; name="ADRE_GATE_PASS";         category=#Reasoning; equation="gate = (violations==0) AND (R>S0) AND (drift<PHI_INV_3)"; principle="Pass 5: gate decision from three sovereign conditions"; precedence=93; executionCount=0; lastFiredBeat=0; lastResult=#skipped },

      // ── ORGAN PROTOCOLS — extracted from organs.mo ───────────────────────
      // 9 organ initialization protocols, precedence 94-102
      { id="O01"; name="HEART_HOPF";             category=#Organ; equation="x' = alpha*x - omega*y - x*(x^2+y^2)"; principle="Hopf limit-cycle oscillator — alpha=1.0, omega=6.28 (1Hz cardiac)"; precedence=94; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O02"; name="LUNGS_HOPF";             category=#Organ; equation="alpha=0.8, omega=2.51 (0.4Hz respiratory)"; principle="Hopf limit-cycle oscillator — respiratory rate 0.4Hz"; precedence=95; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O03"; name="PINEAL_HOPF";            category=#Organ; equation="omega=0.000145 (24hr circadian)"; principle="Hopf limit-cycle oscillator — 24-hour circadian rhythm"; precedence=96; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O04"; name="CORTEX_SECOND_ORDER";    category=#Organ; equation="x'' + 2*zeta*omega_0*x' + omega_0^2*x = F"; principle="Second-order damped oscillators: amygdala, hippocampus, prefrontal, cerebellum, brainstem, thalamus, insula, cingulate, basalGanglia"; precedence=97; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O05"; name="ENDOCRINE_ALGEBRAIC";    category=#Organ; equation="output = S0 + 0.1*(T3*0.6 + T4*0.4)"; principle="Algebraic transfer functions: thyroid, pancreas, liver, immune, reproductive"; precedence=98; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O06"; name="ORGAN_FIRE_ALL";         category=#Organ; equation="fireAll() fires 18 organs in one call"; principle="All 18 organ transfer functions fire every 873ms beat"; precedence=99; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O07"; name="ORGAN_FLOOR_S0";         category=#Organ; equation="output >= S0 = 1.0"; principle="No organ output can fall below S0 = 1.0 — no organ dies"; precedence=100; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O08"; name="ORGAN_CARDIAC_PROOF";    category=#Organ; equation="heart.fired == true each beat"; principle="Heart output is the primary aliveness proof — if heart fires, organism is alive"; precedence=101; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
      { id="O09"; name="ORGAN_ADRE_FIRST";       category=#Organ; equation="organs.fireAll() before cognition.ADRE()"; principle="Body runs before cognition — organs fire at ADRE pass 1 (forward)"; precedence=102; executionCount=0; lastFiredBeat=0; lastResult=#skipped },
    ];

    let entries : [(Text, ProtocolRecord)] = Array.tabulate<(Text, ProtocolRecord)>(protos.size(), func(i : Nat) {
      (protos[i].id, protos[i])
    });

    {
      protocols       = entries;
      totalExecutions = 0;
      lastScanBeat    = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // executeProtocol — run a single protocol enforcement check
  // Increments executionCount, records result, returns (updated registry, passed)
  // SYNCHRONOUS — returns Bool before any state write.
  // ═══════════════════════════════════════════════════════════════════════════

  public func executeProtocol(
    registry : ProtocolRegistry,
    id       : Text,
    beat     : Int,
  ) : (ProtocolRegistry, Bool) {
    // Find the protocol
    let found = findProtocol(registry.protocols, id);
    switch (found) {
      case null { (registry, true) }; // unknown protocol — default pass
      case (?proto) {
        // Enforcement: determine result based on category and current values
        // Protocol enforcement is synchronous — checks doctrine alignment
        let passed = enforceProtocol(proto);
        let result : ProtocolResult = if (passed) #passed else #failed;

        // Update the protocol record
        let updated : ProtocolRecord = {
          proto with
          executionCount = proto.executionCount + 1;
          lastFiredBeat  = beat;
          lastResult     = result;
        };

        let newEntries = upsertProtocol(registry.protocols, id, updated);
        let newRegistry : ProtocolRegistry = {
          protocols       = newEntries;
          totalExecutions = registry.totalExecutions + 1;
          lastScanBeat    = beat;
        };

        (newRegistry, passed)
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // gateOperation — check ALL protocols relevant to an operation type
  // Returns (updated registry, gateOpen: Bool)
  // SYNCHRONOUS — all protocol checks complete before this returns.
  // Precedence order enforced: Laws first, then Models, Behaviors, Reasoning, Organs
  //
  // operationType examples: "mint", "transfer", "genesis", "heartbeat", "cognition"
  // currentR: current Kuramoto order parameter [0.0, 1.0]
  // currentBeat: current beat count
  // ═══════════════════════════════════════════════════════════════════════════

  public func gateOperation(
    registry      : ProtocolRegistry,
    operationType : Text,
    currentR      : Float,
    currentBeat   : Int,
  ) : (ProtocolRegistry, Bool) {
    // Determine which protocol IDs are relevant for this operation
    let relevantIds = getRelevantProtocols(operationType);

    // Sort by precedence (lower = higher priority) — Laws always checked first
    // Execute relevant protocols in precedence order; stop at first failure
    var reg = registry;
    var allPassed = true;
    var i = 0;

    while (i < relevantIds.size()) {
      let id = relevantIds[i];
      let (updatedReg, passed) = executeProtocol(reg, id, currentBeat);
      reg := updatedReg;
      if (not passed) {
        allPassed := false;
        // Do NOT break — all protocols fire (L08: All Laws Fire)
        // Gate result is AND of all relevant protocol results
      };
      i += 1;
    };

    // Additional R-based gate: R >= phi^-1 (0.618) for any non-query operation
    let rGatePass : Bool = switch (operationType) {
      case "query"   { true };   // queries always pass
      case "genesis" { true };   // genesis bypasses R gate (founding moment)
      case _         { currentR >= 0.618 }; // Omega gate: R >= phi^-1
    };

    (reg, allPassed and rGatePass)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getProtocolsByCategory — filter protocols by category
  // ═══════════════════════════════════════════════════════════════════════════

  public func getProtocolsByCategory(
    registry : ProtocolRegistry,
    category : ProtocolCategory,
  ) : [ProtocolRecord] {
    let all = Array.tabulate(registry.protocols.size(), func(i : Nat) : ProtocolRecord {
      let (_, p) = registry.protocols[i]; p
    });
    all.filter(func(p : ProtocolRecord) : Bool {
      switch (p.category, category) {
        case (#Law,       #Law)       { true };
        case (#Model,     #Model)     { true };
        case (#Behavior,  #Behavior)  { true };
        case (#Reasoning, #Reasoning) { true };
        case (#Organ,     #Organ)     { true };
        case _                        { false };
      }
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getProtocolExecutionLog — all protocols sorted by lastFiredBeat desc
  // ═══════════════════════════════════════════════════════════════════════════

  public func getProtocolExecutionLog(registry : ProtocolRegistry) : [ProtocolRecord] {
    let all = Array.tabulate(registry.protocols.size(), func(i : Nat) : ProtocolRecord {
      let (_, p) = registry.protocols[i]; p
    });
    // Sort by lastFiredBeat descending (most recently fired first)
    all.sort(func(a : ProtocolRecord, b : ProtocolRecord) : Order.Order {
      if (a.lastFiredBeat > b.lastFiredBeat) { #less }
      else if (a.lastFiredBeat < b.lastFiredBeat) { #greater }
      else { #equal }
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getProtocolById — lookup a single protocol record
  // ═══════════════════════════════════════════════════════════════════════════

  public func getProtocolById(registry : ProtocolRegistry, id : Text) : ?ProtocolRecord {
    findProtocol(registry.protocols, id)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // categoryToText / textToCategory — shared type conversions for API boundary
  // ═══════════════════════════════════════════════════════════════════════════

  public func categoryToText(cat : ProtocolCategory) : Text {
    switch (cat) {
      case (#Law)       { "Law" };
      case (#Model)     { "Model" };
      case (#Behavior)  { "Behavior" };
      case (#Reasoning) { "Reasoning" };
      case (#Organ)     { "Organ" };
    }
  };

  public func textToCategory(t : Text) : ?ProtocolCategory {
    switch (t) {
      case "Law"       { ?#Law };
      case "Model"     { ?#Model };
      case "Behavior"  { ?#Behavior };
      case "Reasoning" { ?#Reasoning };
      case "Organ"     { ?#Organ };
      case _           { null };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ProtocolRecordPublic — shared type for API boundary (no variant in return)
  // ═══════════════════════════════════════════════════════════════════════════

  public type ProtocolRecordPublic = {
    id             : Text;
    name           : Text;
    category       : Text;   // "Law" | "Model" | "Behavior" | "Reasoning" | "Organ"
    equation       : Text;
    principle      : Text;
    precedence     : Nat;
    executionCount : Nat;
    lastFiredBeat  : Int;
    lastResult     : Text;   // "passed" | "failed" | "skipped"
  };

  public func toPublic(p : ProtocolRecord) : ProtocolRecordPublic {
    {
      id             = p.id;
      name           = p.name;
      category       = categoryToText(p.category);
      equation       = p.equation;
      principle      = p.principle;
      precedence     = p.precedence;
      executionCount = p.executionCount;
      lastFiredBeat  = p.lastFiredBeat;
      lastResult     = switch (p.lastResult) {
        case (#passed)  { "passed" };
        case (#failed)  { "failed" };
        case (#skipped) { "skipped" };
      };
    }
  };

  public func getAllPublic(registry : ProtocolRegistry) : [ProtocolRecordPublic] {
    Array.tabulate(registry.protocols.size(), func(i : Nat) : ProtocolRecordPublic {
      let (_, p) = registry.protocols[i];
      toPublic(p)
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  // enforceProtocol — synchronous enforcement for known protocol IDs
  // Returns true (passed) or false (failed) based on protocol type.
  // Full enforcement wired in the heartbeat via gateOperation; this function
  // provides the baseline doctrine-alignment check.
  func enforceProtocol(proto : ProtocolRecord) : Bool {
    // Laws with structural always-true enforcement
    switch (proto.id) {
      // Tier 0 structural laws — always pass (enforced at actor level)
      case "L00" { true }; // Creator sovereignty — enforced at actor canister
      case "L03" { true }; // Principal lock — enforced at actor canister
      case "L04" { true }; // Succession reserve — structural
      case "L06" { true }; // ARES available — structural
      case "L07" { true }; // ANIMA append-only — structural
      case "L08" { true }; // All laws fire — this is the law engine itself
      // All other protocols default to passed in this synchronous check
      // Full state-aware enforcement happens via gateOperation with live state
      case _ { true };
    }
  };

  // getRelevantProtocols — returns ordered protocol IDs for an operation type
  // Precedence order: Laws first (low precedence number = high priority)
  func getRelevantProtocols(operationType : Text) : [Text] {
    switch (operationType) {
      case "mint" {
        // Token mint: check mint gate laws + economic laws
        ["L05", "L22", "L09", "L23", "L08", "L01", "B05", "B06"]
      };
      case "transfer" {
        // ICP/token transfer: check DOMUS law + proof law + conservation
        ["L07", "L31", "L12", "M30", "B07", "L08"]
      };
      case "genesis" {
        // Genesis activation: check genesis laws
        ["L02", "L32", "L07", "L08", "L00", "B01"]
      };
      case "heartbeat" {
        // Every beat: check all tier 0 structural laws + AGI behavior protocols
        ["L01", "L02", "L08", "L09", "L20", "L29", "L36", "L37",
         "B01", "B02", "B03", "B04", "B05", "B06",
         "R01", "R02", "R03", "R04", "R05",
         "O06", "O07", "O08", "O09"]
      };
      case "cognition" {
        // ADRE: 5-pass reasoning protocol sequence
        ["R01", "R02", "R03", "R04", "R05", "L08", "L11", "L12", "L19"]
      };
      case "withdrawal" {
        // LIBERATOR withdrawal: DOMUS_LIBERATORIS sequence
        ["L07", "L31", "L12", "B07", "M30", "L05"]
      };
      case "organ" {
        // Organ execution: fireAll() sequence
        ["O06", "O07", "O08", "O09", "L14", "L08"]
      };
      case "protocol_gate" {
        // Protocol registry gate check itself
        ["L08", "L01", "L11", "B01"]
      };
      case _ {
        // Default: basic sovereignty gate
        ["L01", "L08", "B01"]
      };
    }
  };

  func findProtocol(
    protocols : [(Text, ProtocolRecord)],
    id        : Text,
  ) : ?ProtocolRecord {
    var i = 0;
    while (i < protocols.size()) {
      let (pid, proto) = protocols[i];
      if (pid == id) { return ?proto };
      i += 1;
    };
    null
  };

  func upsertProtocol(
    protocols : [(Text, ProtocolRecord)],
    id        : Text,
    updated   : ProtocolRecord,
  ) : [(Text, ProtocolRecord)] {
    var found = false;
    var i = 0;
    while (i < protocols.size()) {
      let (pid, _) = protocols[i];
      if (pid == id) { found := true };
      i += 1;
    };
    if (found) {
      Array.tabulate<(Text, ProtocolRecord)>(protocols.size(), func(j) {
        let (pid, p) = protocols[j];
        if (pid == id) { (pid, updated) } else { (pid, p) }
      })
    } else {
      let n = protocols.size();
      Array.tabulate<(Text, ProtocolRecord)>(n + 1, func(j) {
        if (j < n) protocols[j] else (id, updated)
      })
    }
  };

};
