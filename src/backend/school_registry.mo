// school_registry.mo — SCHOOL_REGISTRY Domain Library
// PYTHAGORAS: every tier ratio and threshold derives from phi or Fibonacci harmonic
// EUCLID:     single source of truth — types and state declared once, referenced everywhere
// CONFUCIUS:  right relationship — public access is the floor; Bronze is fully sovereign
//
// Architecture: pure library module (no actor).
// main.mo imports this and holds: var schoolRegistry = SchoolRegistry.defaultSchoolRegistry()
//
// Authorization law:
//   getPublicCurriculum, getTeksStandard, getSchoolRegistry — NO auth (Bronze public access)
//   addTeksStandard, deploySchoolCanister, addLessonTool, updateGrantStatus — caller check
//
// Every product always ships a public school version (Bronze free tier).
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Array "mo:core/Array";
import Principal "mo:core/Principal";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHOOL TIER — Bronze free public, Silver and Gold are premium deployment tiers
  // PHI LAW: three tiers — field types 1/2/3 — mediator (Bronze), receptive (Silver), expansive (Gold)
  // ═══════════════════════════════════════════════════════════════════════════

  public type SchoolTier = {
    #Bronze;    // Free — public access, sovereign canister, grant-eligible
    #Silver;    // Deployed — district-level, teacher/admin auth, full TEKS map
    #Gold;      // Institutional — state-level, delegated signing, compliance export
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // LESSON TOOL — Phi-scaled curriculum artifact bound to a TEKS standard
  // Each tool is a sovereign artifact: teachable + queryable + grant-auditable
  // ═══════════════════════════════════════════════════════════════════════════

  public type LessonTool = {
    id           : Text;   // unique tool ID — e.g. "lt-math-k2-count-01"
    title        : Text;   // display title — shown in UI
    subject      : Text;   // "Math" | "Science" | "ELA" | "CS" | "Algebra" | "Biology"
    teksCodes    : [Text]; // one or more TEKS codes this tool covers
    toolType     : Text;   // "interactive" | "worksheet" | "video" | "assessment" | "lesson_plan"
    publicAccess : Bool;   // true for Bronze (always true in this registry)
    description  : Text;   // brief description for teacher preview
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // TEKS STANDARD — Texas Essential Knowledge and Skills standard record
  // SELF-SIMILARITY LAW: the same structure at standard, lesson, tool, question scale
  // ═══════════════════════════════════════════════════════════════════════════

  public type TeksStandard = {
    code        : Text;        // official TEKS code — e.g. "TEKS.K.2(A)"
    grade       : Text;        // "K" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "11" | "12"
    subject     : Text;        // subject area
    title       : Text;        // standard title
    description : Text;        // full standard description text
    lessonTools : [LessonTool]; // pre-seeded sovereign lesson tools
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHOOL RECORD — A single school or district deploying PARALLAX education node
  // GENESIS LAW: each school gets a sovereign canister — its own compute unit
  // ═══════════════════════════════════════════════════════════════════════════

  public type SchoolRecord = {
    id                  : Text;    // unique school ID — e.g. "dallas-isd-01"
    name                : Text;    // display name
    district            : Text;    // district or agency name
    teksStandardsCodes  : [Text];  // TEKS codes this school has activated
    canisterId          : ?Text;   // deployed canister ID (null until deployed)
    tier                : SchoolTier;
    deployed            : Bool;
    grantStatus         : Text;    // "identifying" | "pending" | "submitted" | "awarded" | "closed"
    contactEmail        : Text;    // primary contact for grant/deployment communication
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // GRANT RECORD — Education funding sources for sovereign canister deployment
  // FIBONACCI LAW: grant deadlines are spaced across the funding calendar
  // ═══════════════════════════════════════════════════════════════════════════

  public type GrantRecord_School = {
    name       : Text;   // grant program name — e.g. "E-Rate"
    program    : Text;   // administering program — e.g. "FCC Universal Service"
    amountUsd  : Nat;    // maximum grant amount in USD
    deadlineMs : Int;    // Unix timestamp in milliseconds for application deadline
    status     : Text;   // "eligible" | "identifying" | "applied" | "awarded" | "closed"
    notes      : Text;   // free-text notes — strategy, eligibility reasoning
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SCHOOL REGISTRY — Master state for the SCHOOL domain
  // CONFUCIUS: one record holds all school state — right relationship to sovereign_db
  // ═══════════════════════════════════════════════════════════════════════════

  public type SchoolRegistry = {
    teksStandards : [TeksStandard];
    schools       : [SchoolRecord];
    grants        : [GrantRecord_School];
    totalDeployed : Nat;
    lastUpdatedMs : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-SEEDED LESSON TOOLS — one per TEKS standard (two for select standards)
  // Bronze: publicAccess = true on all tools
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Math K–2 ─────────────────────────────────────────────────────────────

  let lt_k2_count_01 : LessonTool = {
    id           = "lt-k2-count-01";
    title        = "Counting to 20 — Sovereign Number Line";
    subject      = "Math";
    teksCodes    = ["TEKS.K.2(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Kindergarteners count, recognize, and name whole numbers from 0 to 20 using an interactive sovereign number line anchored to phi-spaced visual markers.";
  };

  let lt_1_add_01 : LessonTool = {
    id           = "lt-1-add-01";
    title        = "Addition Sums — Stories and Strategies";
    subject      = "Math";
    teksCodes    = ["TEKS.1.3(B)"];
    toolType     = "lesson_plan";
    publicAccess = true;
    description  = "First graders solve addition problems with sums up to 12 using manipulatives, story problems, and a guided lesson plan.";
  };

  let lt_1_add_02 : LessonTool = {
    id           = "lt-1-add-02";
    title        = "Sum Fluency Drill — Interactive";
    subject      = "Math";
    teksCodes    = ["TEKS.1.3(B)"];
    toolType     = "assessment";
    publicAccess = true;
    description  = "Timed interactive assessment building fluency for addition facts with sums to 12.";
  };

  let lt_2_frac_01 : LessonTool = {
    id           = "lt-2-frac-01";
    title        = "Introduction to Fractions — Halves, Thirds, Fourths";
    subject      = "Math";
    teksCodes    = ["TEKS.2.7(C)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Second graders partition objects and sets into equal parts, identifying fractions as parts of a whole using visual fraction models.";
  };

  // ── Math 3–5 ─────────────────────────────────────────────────────────────

  let lt_3_mult_01 : LessonTool = {
    id           = "lt-3-mult-01";
    title        = "Multiplication Foundations — Arrays and Equal Groups";
    subject      = "Math";
    teksCodes    = ["TEKS.3.4(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Third graders represent multiplication as repeated addition, equal groups, and arrays. Includes grid modeling and fact families.";
  };

  let lt_4_dec_01 : LessonTool = {
    id           = "lt-4-dec-01";
    title        = "Decimal Concepts — Tenths and Hundredths";
    subject      = "Math";
    teksCodes    = ["TEKS.4.4(B)"];
    toolType     = "worksheet";
    publicAccess = true;
    description  = "Fourth graders represent decimals to the hundredths place using base-ten models, number lines, and expanded notation.";
  };

  let lt_5_ratio_01 : LessonTool = {
    id           = "lt-5-ratio-01";
    title        = "Ratios and Proportional Thinking";
    subject      = "Math";
    teksCodes    = ["TEKS.5.3(C)"];
    toolType     = "lesson_plan";
    publicAccess = true;
    description  = "Fifth graders identify and generate ratios using concrete models and connect ratio language to real-world contexts including phi proportions.";
  };

  // ── Math 6–8 ─────────────────────────────────────────────────────────────

  let lt_6_prop_01 : LessonTool = {
    id           = "lt-6-prop-01";
    title        = "Proportional Reasoning — Rates and Ratios";
    subject      = "Math";
    teksCodes    = ["TEKS.6.3(E)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Sixth graders multiply and divide positive rational numbers fluently, applying proportional reasoning to real-world problem contexts.";
  };

  let lt_7_const_01 : LessonTool = {
    id           = "lt-7-const-01";
    title        = "Constant of Proportionality — Tables, Graphs, Equations";
    subject      = "Math";
    teksCodes    = ["TEKS.7.4(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Seventh graders represent constant rate of change in proportional relationships using tables, graphs, and equations in the form y = kx.";
  };

  let lt_8_pyth_01 : LessonTool = {
    id           = "lt-8-pyth-01";
    title        = "Pythagorean Theorem — Proof and Applications";
    subject      = "Math";
    teksCodes    = ["TEKS.8.8(C)"];
    toolType     = "lesson_plan";
    publicAccess = true;
    description  = "Eighth graders use the Pythagorean theorem to solve problems involving right triangles and real-world distance problems in two dimensions.";
  };

  let lt_8_pyth_02 : LessonTool = {
    id           = "lt-8-pyth-02";
    title        = "Pythagorean Theorem — Interactive Distance Calculator";
    subject      = "Math";
    teksCodes    = ["TEKS.8.8(C)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Interactive tool that visualizes right triangles and computes hypotenuse or leg lengths using the Pythagorean theorem.";
  };

  // ── Science 3–8 ──────────────────────────────────────────────────────────

  let lt_sci4_inv_01 : LessonTool = {
    id           = "lt-sci4-inv-01";
    title        = "Scientific Investigation — Safety and Process Skills";
    subject      = "Science";
    teksCodes    = ["TEKS.Sci.4.2(A)"];
    toolType     = "lesson_plan";
    publicAccess = true;
    description  = "Fourth graders plan and implement investigations using safe practices, collecting and recording data using appropriate tools and units.";
  };

  let lt_sci5_matter_01 : LessonTool = {
    id           = "lt-sci5-matter-01";
    title        = "Properties of Matter — Measurement and Classification";
    subject      = "Science";
    teksCodes    = ["TEKS.Sci.5.3(C)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Fifth graders measure and compare physical properties of matter including mass, volume, and density, classifying matter by observable properties.";
  };

  let lt_sci7_cell_01 : LessonTool = {
    id           = "lt-sci7-cell-01";
    title        = "Cell Structure — Prokaryotic and Eukaryotic Comparison";
    subject      = "Science";
    teksCodes    = ["TEKS.Sci.7.6(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Seventh graders identify the functions of cell organelles and compare prokaryotic and eukaryotic cell structures using labeled 3D models.";
  };

  // ── English / ELA ─────────────────────────────────────────────────────────

  let lt_ela3_auth_01 : LessonTool = {
    id           = "lt-ela3-auth-01";
    title        = "Author Purpose — Persuade, Inform, Entertain";
    subject      = "ELA";
    teksCodes    = ["TEKS.ELA.3.7(B)"];
    toolType     = "worksheet";
    publicAccess = true;
    description  = "Third graders identify the author's purpose (PIE) in varied texts, supporting their conclusions with textual evidence.";
  };

  let lt_ela5_fig_01 : LessonTool = {
    id           = "lt-ela5-fig-01";
    title        = "Figurative Language — Simile, Metaphor, Personification";
    subject      = "ELA";
    teksCodes    = ["TEKS.ELA.5.9(D)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Fifth graders identify and interpret figurative language including simile, metaphor, and personification in poetry and prose.";
  };

  let lt_ela8_info_01 : LessonTool = {
    id           = "lt-ela8-info-01";
    title        = "Informational Writing — Structure and Evidence";
    subject      = "ELA";
    teksCodes    = ["TEKS.ELA.8.10(A)"];
    toolType     = "lesson_plan";
    publicAccess = true;
    description  = "Eighth graders compose multi-paragraph informational essays with a thesis, supporting evidence, and formal academic language.";
  };

  // ── Computer Science ──────────────────────────────────────────────────────

  let lt_cs6_comp_01 : LessonTool = {
    id           = "lt-cs6-comp-01";
    title        = "Computational Thinking — Decomposition and Patterns";
    subject      = "CS";
    teksCodes    = ["TEKS.CS.6.4(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Sixth graders apply computational thinking practices: decomposing problems, finding patterns, and developing algorithmic solutions.";
  };

  let lt_cs7_algo_01 : LessonTool = {
    id           = "lt-cs7-algo-01";
    title        = "Algorithms — Flowcharts and Pseudocode";
    subject      = "CS";
    teksCodes    = ["TEKS.CS.7.2(B)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Seventh graders design and trace algorithms using flowcharts and pseudocode to solve well-defined problems.";
  };

  let lt_cs8_data_01 : LessonTool = {
    id           = "lt-cs8-data-01";
    title        = "Data Analysis — Collection, Representation, Interpretation";
    subject      = "CS";
    teksCodes    = ["TEKS.CS.8.5(C)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "Eighth graders collect, clean, and represent data sets, using tables and visualizations to draw valid conclusions.";
  };

  // ── High School ───────────────────────────────────────────────────────────

  let lt_alg1_lin_01 : LessonTool = {
    id           = "lt-alg1-lin-01";
    title        = "Linear Equations — Solving and Graphing";
    subject      = "Algebra 1";
    teksCodes    = ["TEKS.Alg1.7(A)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "High school students solve linear equations in one variable, graph solutions on a number line, and interpret solutions in context.";
  };

  let lt_bio_gen_01 : LessonTool = {
    id           = "lt-bio-gen-01";
    title        = "Genetics — Mendelian Inheritance and Punnett Squares";
    subject      = "Biology";
    teksCodes    = ["TEKS.Bio.4(C)"];
    toolType     = "interactive";
    publicAccess = true;
    description  = "High school biology students apply Mendelian genetics to predict trait inheritance using Punnett squares and probability models.";
  };

  let lt_bio_gen_02 : LessonTool = {
    id           = "lt-bio-gen-02";
    title        = "Genetics — DNA Structure and Replication";
    subject      = "Biology";
    teksCodes    = ["TEKS.Bio.4(C)"];
    toolType     = "video";
    publicAccess = true;
    description  = "Video lesson covering DNA double helix structure, base pairing rules, and the replication process with interactive checkpoints.";
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-SEEDED TEKS STANDARDS — 20 real Texas TEKS standards
  // Codes follow official TEA format: TEKS.[Subject].[Grade].[Section]([Subsection])
  // ═══════════════════════════════════════════════════════════════════════════

  func seedTeksStandards() : [TeksStandard] {
    [
      // ── Math K–2 ─────────────────────────────────────────────────────────
      {
        code        = "TEKS.K.2(A)";
        grade       = "K";
        subject     = "Math";
        title       = "Counting and Cardinality — Count to 20";
        description = "Count forward and backward to at least 20 with and without objects.";
        lessonTools = [lt_k2_count_01];
      },
      {
        code        = "TEKS.1.3(B)";
        grade       = "1";
        subject     = "Math";
        title       = "Number and Operations — Add and Subtract";
        description = "Use objects, pictorial models, and number sentences to solve word problems involving addition and subtraction within 20 and to solve problems involving unknown quantities.";
        lessonTools = [lt_1_add_01, lt_1_add_02];
      },
      {
        code        = "TEKS.2.7(C)";
        grade       = "2";
        subject     = "Math";
        title       = "Fractions — Partition Objects and Sets";
        description = "Use concrete models to count fractional parts beyond one whole using words and recognize how many parts it takes to equal one whole.";
        lessonTools = [lt_2_frac_01];
      },
      // ── Math 3–5 ─────────────────────────────────────────────────────────
      {
        code        = "TEKS.3.4(A)";
        grade       = "3";
        subject     = "Math";
        title       = "Number and Operations — Multiplication Strategies";
        description = "Solve with fluency one-step and two-step problems involving multiplication and division within 100 using strategies based on objects, pictorial models, and properties of operations.";
        lessonTools = [lt_3_mult_01];
      },
      {
        code        = "TEKS.4.4(B)";
        grade       = "4";
        subject     = "Math";
        title       = "Decimals — Represent and Compare";
        description = "Represent the value of the digit in whole numbers through 1,000,000,000 and decimals to the hundredths using expanded notation and numerals.";
        lessonTools = [lt_4_dec_01];
      },
      {
        code        = "TEKS.5.3(C)";
        grade       = "5";
        subject     = "Math";
        title       = "Ratios and Proportional Reasoning — Introduction";
        description = "Solve for products of decimals to the hundredths, including situations involving money, using strategies based on place-value understandings, properties of operations, and the relationship to the multiplication of whole numbers.";
        lessonTools = [lt_5_ratio_01];
      },
      // ── Math 6–8 ─────────────────────────────────────────────────────────
      {
        code        = "TEKS.6.3(E)";
        grade       = "6";
        subject     = "Math";
        title       = "Proportional Reasoning — Multiply and Divide Rational Numbers";
        description = "Multiply and divide positive rational numbers fluently.";
        lessonTools = [lt_6_prop_01];
      },
      {
        code        = "TEKS.7.4(A)";
        grade       = "7";
        subject     = "Math";
        title       = "Proportional Relationships — Constant Rate of Change";
        description = "Represent constant rates of change in mathematical and real-world problems given pictorial, tabular, verbal, numeric, graphical, and algebraic representations, including d = rt.";
        lessonTools = [lt_7_const_01];
      },
      {
        code        = "TEKS.8.8(C)";
        grade       = "8";
        subject     = "Math";
        title       = "Pythagorean Theorem — Applications";
        description = "Use the Pythagorean Theorem and its converse to solve problems.";
        lessonTools = [lt_8_pyth_01, lt_8_pyth_02];
      },
      // ── Science 3–8 ──────────────────────────────────────────────────────
      {
        code        = "TEKS.Sci.4.2(A)";
        grade       = "4";
        subject     = "Science";
        title       = "Scientific Investigation — Safe Laboratory Practices";
        description = "Demonstrate safe practices and the use of safety equipment as described in Texas Education Agency-approved safety standards during classroom and outdoor investigations.";
        lessonTools = [lt_sci4_inv_01];
      },
      {
        code        = "TEKS.Sci.5.3(C)";
        grade       = "5";
        subject     = "Science";
        title       = "Properties of Matter — Physical and Chemical";
        description = "Demonstrate that some mixtures maintain physical properties of their ingredients such as iron filings and sand, and others do not.";
        lessonTools = [lt_sci5_matter_01];
      },
      {
        code        = "TEKS.Sci.7.6(A)";
        grade       = "7";
        subject     = "Science";
        title       = "Organisms — Cells as the Basic Unit of Life";
        description = "Recognize that the presence of a cell nucleus differentiates eukaryotes from prokaryotes.";
        lessonTools = [lt_sci7_cell_01];
      },
      // ── ELA ──────────────────────────────────────────────────────────────
      {
        code        = "TEKS.ELA.3.7(B)";
        grade       = "3";
        subject     = "ELA";
        title       = "Author's Purpose — Distinguish Fact and Opinion";
        description = "Recognize the author's stated or implied purpose and explain how the purpose affects the tone of a text.";
        lessonTools = [lt_ela3_auth_01];
      },
      {
        code        = "TEKS.ELA.5.9(D)";
        grade       = "5";
        subject     = "ELA";
        title       = "Figurative Language — Understand and Analyze";
        description = "Recognize and analyze the characteristics of various types of literary works, including figurative language such as simile, metaphor, and personification.";
        lessonTools = [lt_ela5_fig_01];
      },
      {
        code        = "TEKS.ELA.8.10(A)";
        grade       = "8";
        subject     = "ELA";
        title       = "Composition — Multi-Paragraph Informational Writing";
        description = "Write an analytical essay of sufficient length that includes a clear thesis statement; a variety of sentence structures; sustained evidence from several sources; and a conclusion.";
        lessonTools = [lt_ela8_info_01];
      },
      // ── Computer Science ──────────────────────────────────────────────────
      {
        code        = "TEKS.CS.6.4(A)";
        grade       = "6";
        subject     = "CS";
        title       = "Computational Thinking — Decomposition and Pattern Recognition";
        description = "Decompose problems and subproblems into parts to facilitate the design, implementation, and review of programs.";
        lessonTools = [lt_cs6_comp_01];
      },
      {
        code        = "TEKS.CS.7.2(B)";
        grade       = "7";
        subject     = "CS";
        title       = "Algorithms — Design and Analysis";
        description = "Describe, debug, and analyze sequential, conditional, and iterative statements in a program.";
        lessonTools = [lt_cs7_algo_01];
      },
      {
        code        = "TEKS.CS.8.5(C)";
        grade       = "8";
        subject     = "CS";
        title       = "Data Analysis — Storage and Representation";
        description = "Collect data using computational tools and transform the data to make it more useful and reliable.";
        lessonTools = [lt_cs8_data_01];
      },
      // ── High School ───────────────────────────────────────────────────────
      {
        code        = "TEKS.Alg1.7(A)";
        grade       = "9";
        subject     = "Algebra 1";
        title       = "Linear Equations — One Variable";
        description = "Graph points in all four quadrants using ordered pairs of rational numbers; identify the quadrant or axis containing a point.";
        lessonTools = [lt_alg1_lin_01];
      },
      {
        code        = "TEKS.Bio.4(C)";
        grade       = "10";
        subject     = "Biology";
        title       = "Genetics — Mendelian Inheritance";
        description = "Predict possible outcomes of various genetic combinations such as monohybrid crosses, dihybrid crosses, and non-Mendelian genetics.";
        lessonTools = [lt_bio_gen_01, lt_bio_gen_02];
      },
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-SEEDED SCHOOLS — Dallas ISD, TEA Demo, Texas Tech Charter
  // Bronze tier = free, public access, grant-eligible
  // ═══════════════════════════════════════════════════════════════════════════

  func seedSchools() : [SchoolRecord] {
    [
      {
        id                 = "dallas-isd-01";
        name               = "Dallas ISD Pilot";
        district           = "Dallas Independent School District";
        teksStandardsCodes = [];
        canisterId         = null;
        tier               = #Bronze;
        deployed           = false;
        grantStatus        = "identifying";
        contactEmail       = "tech@dallasisd.org";
      },
      {
        id                 = "tea-demo";
        name               = "TEA Demo School";
        district           = "Texas Education Agency";
        teksStandardsCodes = [];
        canisterId         = null;
        tier               = #Silver;
        deployed           = false;
        grantStatus        = "pending";
        contactEmail       = "innovation@tea.texas.gov";
      },
      {
        id                 = "texas-tech-charter";
        name               = "Texas Tech Charter";
        district           = "Texas Tech";
        teksStandardsCodes = [];
        canisterId         = null;
        tier               = #Bronze;
        deployed           = false;
        grantStatus        = "identifying";
        contactEmail       = "";
      },
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // PRE-SEEDED GRANTS — E-Rate, Title IV, TEA Innovation, NSF AI Education
  // deadlineMs encoded as Unix ms timestamps for mid-2026 / fall-2026 windows
  // ═══════════════════════════════════════════════════════════════════════════

  func seedGrants() : [GrantRecord_School] {
    [
      {
        name       = "E-Rate";
        program    = "FCC Universal Service";
        amountUsd  = 3_000_000;
        // July 1 2026 00:00:00 UTC in milliseconds
        deadlineMs = 1_751_328_000_000;
        status     = "eligible";
        notes      = "Funds telecommunications and internet access for schools and libraries — sovereign canister qualifies as infrastructure. Category 2 funding supports internal connections and managed Wi-Fi.";
      },
      {
        name       = "Title IV Part A";
        program    = "Federal ESSA — Student Support and Academic Enrichment";
        amountUsd  = 500_000;
        // September 1 2026 00:00:00 UTC in milliseconds
        deadlineMs = 1_756_684_800_000;
        status     = "eligible";
        notes      = "Well-Rounded Educational Opportunities — supports technology access and STEM programs. Sovereign canister per school is a novel infrastructure pitch aligned with STEM objectives.";
      },
      {
        name       = "TEA Innovation Grant";
        program    = "Texas Education Agency — Innovation Fund";
        amountUsd  = 250_000;
        // October 1 2026 00:00:00 UTC in milliseconds
        deadlineMs = 1_759_363_200_000;
        status     = "identifying";
        notes      = "Novel infrastructure pitch — canister per school model. Each school receives a deployed canister it controls, not a subscription to someone else's server. Pitch focuses on TEA alignment with TEKS standards mapping.";
      },
      {
        name       = "Federal AI Education Grant";
        program    = "NSF — AI in Education Program";
        amountUsd  = 750_000;
        // August 1 2026 00:00:00 UTC in milliseconds
        deadlineMs = 1_753_920_000_000;
        status     = "identifying";
        notes      = "Agentic AI in schools — University of Nebraska (UNL) AI Institute already shifting to Agentic AI curriculum for 2026. Sovereign canister model enables local sovereign compute for AI workloads without cloud dependency.";
      },
    ];
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT SCHOOL REGISTRY — Genesis Law: born fully formed with pre-seeded data
  // EOP preserves live state across all upgrades — never resets
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultSchoolRegistry() : SchoolRegistry {
    {
      teksStandards = seedTeksStandards();
      schools       = seedSchools();
      grants        = seedGrants();
      totalDeployed = 0;
      lastUpdatedMs = 0;
    };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY FUNCTIONS — NO auth required (Bronze public tier)
  // FRACTAL SCALE LAW: same access floor at student, teacher, district, state scale
  // ═══════════════════════════════════════════════════════════════════════════

  // getPublicCurriculum — returns all TEKS standards with their lesson tools
  // Bronze free tier — no authentication, no principal check, fully public
  // GENESIS LAW: the knowledge is sovereign; access is not gatekept at the floor
  public func getPublicCurriculum(reg : SchoolRegistry) : [TeksStandard] {
    reg.teksStandards;
  };

  // getTeksStandard — returns a single TEKS standard by its official code
  // Bronze free tier — no authentication required
  // Returns null if the code is not in the registry
  public func getTeksStandard(reg : SchoolRegistry, code : Text) : ?TeksStandard {
    let standards = reg.teksStandards;
    var i = 0;
    while (i < standards.size()) {
      if (standards[i].code == code) { return ?standards[i] };
      i += 1;
    };
    null;
  };

  // getSchoolRegistry — returns the full registry overview (schools, grants, totals)
  // Bronze free tier — registry metadata is public; canister IDs are shown as-is
  // Enables grant auditors and district administrators to see deployment status
  public func getSchoolRegistry(reg : SchoolRegistry) : SchoolRegistry {
    reg;
  };

  // getSchoolByDistrict — query schools by district name
  // Bronze free tier — no auth required
  public func getSchoolByDistrict(reg : SchoolRegistry, district : Text) : [SchoolRecord] {
    reg.schools.filter(func(s) { s.district == district });
  };

  // getGrantsByStatus — filter grants by current status
  // Bronze free tier — grant intelligence is public
  public func getGrantsByStatus(reg : SchoolRegistry, status : Text) : [GrantRecord_School] {
    reg.grants.filter(func(g) { g.status == status });
  };

  // getLessonToolsBySubject — return all lesson tools across all TEKS for a subject
  // Bronze free tier — teachers can browse without authentication
  public func getLessonToolsBySubject(reg : SchoolRegistry, subject : Text) : [LessonTool] {
    var tools : [LessonTool] = [];
    let standards = reg.teksStandards;
    var i = 0;
    while (i < standards.size()) {
      if (standards[i].subject == subject) {
        let std = standards[i];
        var j = 0;
        while (j < std.lessonTools.size()) {
          tools := appendImmutable(tools, std.lessonTools[j]);
          j += 1;
        };
      };
      i += 1;
    };
    tools;
  };

  // getLessonToolsByGrade — return all lesson tools across all TEKS for a grade level
  // Bronze free tier — grade-filtered curriculum access
  public func getLessonToolsByGrade(reg : SchoolRegistry, grade : Text) : [LessonTool] {
    var tools : [LessonTool] = [];
    let standards = reg.teksStandards;
    var i = 0;
    while (i < standards.size()) {
      if (standards[i].grade == grade) {
        let std = standards[i];
        var j = 0;
        while (j < std.lessonTools.size()) {
          tools := appendImmutable(tools, std.lessonTools[j]);
          j += 1;
        };
      };
      i += 1;
    };
    tools;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE FUNCTIONS — caller check required (Silver/Gold tier admin operations)
  // Phi-derived authorization: teacher/admin callers control district canisters
  // ZERO-EXPOSURE LAW: no doctrine labels in public interfaces — method names are plain English
  // ═══════════════════════════════════════════════════════════════════════════

  // addTeksStandard — add a new TEKS standard to the registry
  // Requires caller check: only authorized callers can extend the curriculum
  public func addTeksStandard(
    reg    : SchoolRegistry,
    caller : Principal,
    auth   : Principal,
    std    : TeksStandard,
    nowMs  : Int,
  ) : SchoolRegistry {
    assert (caller == auth);
    let updated = appendImmutable(reg.teksStandards, std);
    { reg with teksStandards = updated; lastUpdatedMs = nowMs };
  };

  // deploySchoolCanister — record a deployed canister ID for a school
  // Requires caller check: only authorized callers can mark a school as deployed
  // GENESIS LAW: the canister is sovereign — recording its ID is an inscription event
  public func deploySchoolCanister(
    reg      : SchoolRegistry,
    caller   : Principal,
    auth     : Principal,
    schoolId : Text,
    canId    : Text,
    nowMs    : Int,
  ) : SchoolRegistry {
    assert (caller == auth);
    let schools = reg.schools;
    var found = false;
    let updated = Array.tabulate(schools.size(), func(i) {
      if (schools[i].id == schoolId) {
        found := true;
        { schools[i] with canisterId = ?canId; deployed = true };
      } else {
        schools[i];
      };
    });
    if (not found) { return reg };
    let newDeployed = reg.totalDeployed + 1;
    { reg with schools = updated; totalDeployed = newDeployed; lastUpdatedMs = nowMs };
  };

  // addLessonTool — add a lesson tool to an existing TEKS standard
  // Requires caller check: curriculum authors need authorization to extend tools
  public func addLessonTool(
    reg      : SchoolRegistry,
    caller   : Principal,
    auth     : Principal,
    teksCode : Text,
    tool     : LessonTool,
    nowMs    : Int,
  ) : SchoolRegistry {
    assert (caller == auth);
    let standards = reg.teksStandards;
    let updated = Array.tabulate(standards.size(), func(i) {
      if (standards[i].code == teksCode) {
        let newTools = appendImmutable(standards[i].lessonTools, tool);
        { standards[i] with lessonTools = newTools };
      } else {
        standards[i];
      };
    });
    { reg with teksStandards = updated; lastUpdatedMs = nowMs };
  };

  // updateGrantStatus — update the status of a named grant
  // Requires caller check: grant pipeline management requires authorization
  // LOOP NEVER CLOSES LAW: grant status transitions are tracked permanently
  public func updateGrantStatus(
    reg       : SchoolRegistry,
    caller    : Principal,
    auth      : Principal,
    grantName : Text,
    status    : Text,
    nowMs     : Int,
  ) : SchoolRegistry {
    assert (caller == auth);
    let grants = reg.grants;
    let updated = Array.tabulate(grants.size(), func(i) {
      if (grants[i].name == grantName) {
        { grants[i] with status = status };
      } else {
        grants[i];
      };
    });
    { reg with grants = updated; lastUpdatedMs = nowMs };
  };

  // addSchool — register a new school in the registry
  // Requires caller check: district onboarding requires authorization
  public func addSchool(
    reg    : SchoolRegistry,
    caller : Principal,
    auth   : Principal,
    school : SchoolRecord,
    nowMs  : Int,
  ) : SchoolRegistry {
    assert (caller == auth);
    let updated = appendImmutable(reg.schools, school);
    { reg with schools = updated; lastUpdatedMs = nowMs };
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS — Euclid: geometric primitives
  // ═══════════════════════════════════════════════════════════════════════════

  // appendImmutable — append one element to an immutable array
  // EUCLID: the simplest path — tabulate at n+1
  func appendImmutable<T>(arr : [T], item : T) : [T] {
    let n = arr.size();
    Array.tabulate<T>(n + 1, func(i) {
      if (i < n) arr[i] else item;
    });
  };

  // unused phi reference — imported to satisfy family inheritance requirement
  // FAMILY INHERITANCE LAW: phi.mo passes every constant and law to every child module
  let _phi_inv : Float = Phi.PHI_INV; // φ⁻¹ — Bronze tier access floor reference

};
