// builder_sdk.mo — Builder SDK
// PARALLAX Sovereign Organism — Natural Language → Sovereign Artifact Pipeline
//
// BUILDER SDK sits on top of birthAI — receives a natural language paragraph,
// dissects it, determines what to build, and calls the right function.
//
// Pattern:
//   raw text in → parseDirective() → parsedIntent + parameters
//   submitDirective() → directiveId
//   executeDirective(directiveId, birthAiState) → (updated states, result text)
//
// Target types: entity | agent | canister | protocol | query
// Keywords:
//   build/create/make     → entity/agent
//   query/find/search     → query
//   deploy/launch         → canister
//   protocol/law/enforce  → protocol
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import BirthAi "birth_ai";
import Array "mo:core/Array";
import Time "mo:core/Time";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type TargetType = { #entity; #agent; #canister; #protocol; #queryTarget };

  public type DirectiveStatus = { #parsed; #building; #complete; #failed };

  public type BuilderDirective = {
    id           : Text;
    rawText      : Text;
    parsedIntent : Text;
    targetType   : TargetType;
    parameters   : [(Text, Text)];    // key-value extracted parameters
    status       : DirectiveStatus;
    outputId     : ?Text;             // entity/canister/protocol ID produced
    timestamp    : Int;
  };

  public type BuilderState = {
    directives   : [(Text, BuilderDirective)];  // (directiveId, directive)
    totalBuilt   : Nat;
    totalFailed  : Nat;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultBuilderState() : BuilderState {
    {
      directives  = [];
      totalBuilt  = 0;
      totalFailed = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // parseDirective — natural language → (parsedIntent, parameters)
  //
  // Intent detection by keyword presence:
  //   build/create/make     → "build"
  //   query/find/search     → "query"
  //   deploy/launch         → "canister"
  //   protocol/law/enforce  → "protocol"
  //   (default)             → "build"
  //
  // Named entity extraction:
  //   words after "named" or "called" → ("name", value)
  //
  // Target system extraction:
  //   words after "for" or "in" → ("target", value)
  //
  // Entity type extraction:
  //   "internal" → ("entityType", "internal")
  //   "external" / "agent" → ("entityType", "external")
  // ═══════════════════════════════════════════════════════════════════════════

  public func parseDirective(rawText : Text) : (Text, [(Text, Text)]) {
    let lower = rawText.toLower();

    // Intent detection
    let intent : Text = if (lower.contains(#text "build") or lower.contains(#text "create") or lower.contains(#text "make")) {
      "build"
    } else if (lower.contains(#text "query") or lower.contains(#text "find") or lower.contains(#text "search")) {
      "query"
    } else if (lower.contains(#text "deploy") or lower.contains(#text "launch")) {
      "canister"
    } else if (lower.contains(#text "protocol") or lower.contains(#text "law") or lower.contains(#text "enforce")) {
      "protocol"
    } else {
      "build"
    };

    // Extract parameters via keyword scanning
    var params : [(Text, Text)] = [];

    // Entity type
    let entityTypeVal : Text = if (lower.contains(#text "external") or lower.contains(#text "agent")) {
      "external"
    } else {
      "internal"
    };
    params := appendParam(params, ("entityType", entityTypeVal));

    // Extract name — word after "named" or "called"
    let nameVal = extractWordAfter(rawText, "named");
    let nameVal2 = if (nameVal == "") extractWordAfter(rawText, "called") else nameVal;
    if (nameVal2 != "") {
      params := appendParam(params, ("name", nameVal2));
    };

    // Extract target — word after "for" or "in"
    let targetVal = extractWordAfter(rawText, "for");
    let targetVal2 = if (targetVal == "") extractWordAfter(rawText, " in ") else targetVal;
    if (targetVal2 != "") {
      params := appendParam(params, ("target", targetVal2));
    };

    // Store the raw text as directive parameter for execution
    params := appendParam(params, ("rawDirective", rawText));

    (intent, params)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // submitDirective — parse text, create directive, return directiveId
  // ═══════════════════════════════════════════════════════════════════════════

  public func submitDirective(state : BuilderState, rawText : Text) : (BuilderState, Text) {
    let now              = Time.now();
    let (intent, params) = parseDirective(rawText);

    // Determine targetType from intent
    let targetType : TargetType = switch (intent) {
      case "query"    { #queryTarget };
      case "canister" { #canister };
      case "protocol" { #protocol };
      case _          {
        // Check if entityType param is "external" → #agent, else #entity
        let isExternal = paramGet(params, "entityType") == "external";
        if (isExternal) #agent else #entity
      };
    };

    let directiveId = "DIR-" # state.totalBuilt.toText() # "-" # now.toText();

    let directive : BuilderDirective = {
      id           = directiveId;
      rawText      = rawText;
      parsedIntent = intent;
      targetType   = targetType;
      parameters   = params;
      status       = #parsed;
      outputId     = null;
      timestamp    = now;
    };

    let newDirs = appendDirective(state.directives, directiveId, directive);
    ({ state with directives = newDirs }, directiveId)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // executeDirective — execute a parsed directive
  // - entity/agent → calls BirthAi.birthEntity
  // - query        → returns matching entity list as JSON summary
  // - canister     → records canister intent
  // - protocol     → records protocol intent
  // Returns (updated BuilderState, updated BirthAiState, result text)
  // ═══════════════════════════════════════════════════════════════════════════

  public func executeDirective(
    state        : BuilderState,
    directiveId  : Text,
    birthAiState : BirthAi.BirthAiState,
    beatCount    : Int,
  ) : (BuilderState, BirthAi.BirthAiState, Text) {
    switch (findDirective(state.directives, directiveId)) {
      case null {
        (state, birthAiState, "DIRECTIVE_NOT_FOUND:" # directiveId)
      };
      case (?directive) {
        if (directive.status == #complete or directive.status == #failed) {
          return (state, birthAiState, "DIRECTIVE_ALREADY_DONE:" # directiveId);
        };

        // Mark as building
        let building = { directive with status = #building };
        let updatedDirs0 = setDirective(state.directives, directiveId, building);

        switch (directive.targetType) {
          case (#entity) {
            // Build an internal entity
            let entityName = paramGet(directive.parameters, "name");
            let nameToUse  = if (entityName == "") directive.parsedIntent # "-entity" else entityName;
            let (newBirthState, entityId) = BirthAi.birthEntity(
              birthAiState, nameToUse, directive.rawText, #internal, beatCount
            );
            // Awaken immediately
            let awakenedState = BirthAi.awaken(newBirthState, entityId);

            let done = { building with status = #complete; outputId = ?entityId };
            let finalDirs = setDirective(updatedDirs0, directiveId, done);
            (
              { state with directives = finalDirs; totalBuilt = state.totalBuilt + 1 },
              awakenedState,
              "ENTITY_BORN:" # entityId
            )
          };

          case (#agent) {
            // Build an external agent
            let agentName = paramGet(directive.parameters, "name");
            let nameToUse = if (agentName == "") directive.parsedIntent # "-agent" else agentName;
            let (newBirthState, agentId) = BirthAi.birthEntity(
              birthAiState, nameToUse, directive.rawText, #external, beatCount
            );
            let awakenedState = BirthAi.awaken(newBirthState, agentId);

            let done = { building with status = #complete; outputId = ?agentId };
            let finalDirs = setDirective(updatedDirs0, directiveId, done);
            (
              { state with directives = finalDirs; totalBuilt = state.totalBuilt + 1 },
              awakenedState,
              "AGENT_BORN:" # agentId
            )
          };

          case (#queryTarget) {
            // Return matching entities as summary
            let queryTerm = paramGet(directive.parameters, "name");
            let allEntities = BirthAi.listEntities(birthAiState);
            let matching = if (queryTerm == "") {
              allEntities
            } else {
              let lq = queryTerm.toLower();
              allEntities.filter(func(e : BirthAi.BirthEntity) : Bool {
                e.name.toLower().contains(#text lq)
                or e.directive.toLower().contains(#text lq)
              })
            };
            let resultText = "QUERY_RESULT:count=" # matching.size().toText();

            let done = { building with status = #complete; outputId = ?resultText };
            let finalDirs = setDirective(updatedDirs0, directiveId, done);
            (
              { state with directives = finalDirs; totalBuilt = state.totalBuilt + 1 },
              birthAiState,
              resultText
            )
          };

          case (#canister) {
            let target = paramGet(directive.parameters, "target");
            let canisterId = "CANISTER-INTENT-" # directiveId;

            let done = { building with status = #complete; outputId = ?canisterId };
            let finalDirs = setDirective(updatedDirs0, directiveId, done);
            (
              { state with directives = finalDirs; totalBuilt = state.totalBuilt + 1 },
              birthAiState,
              "CANISTER_INTENT_RECORDED:target=" # target # ":id=" # canisterId
            )
          };

          case (#protocol) {
            let target = paramGet(directive.parameters, "target");
            let protocolId = "PROTOCOL-INTENT-" # directiveId;

            let done = { building with status = #complete; outputId = ?protocolId };
            let finalDirs = setDirective(updatedDirs0, directiveId, done);
            (
              { state with directives = finalDirs; totalBuilt = state.totalBuilt + 1 },
              birthAiState,
              "PROTOCOL_INTENT_RECORDED:target=" # target # ":id=" # protocolId
            )
          };
        }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getDirective — retrieve single directive by ID
  // ═══════════════════════════════════════════════════════════════════════════

  public func getDirective(state : BuilderState, id : Text) : ?BuilderDirective {
    findDirective(state.directives, id)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // listDirectives — return all directives as a flat array
  // ═══════════════════════════════════════════════════════════════════════════

  public func listDirectives(state : BuilderState) : [BuilderDirective] {
    Array.tabulate<BuilderDirective>(state.directives.size(), func(i) {
      let (_, d) = state.directives[i];
      d
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func appendParam(params : [(Text, Text)], p : (Text, Text)) : [(Text, Text)] {
    let n = params.size();
    Array.tabulate<(Text, Text)>(n + 1, func(i) { if (i < n) params[i] else p })
  };

  func paramGet(params : [(Text, Text)], key : Text) : Text {
    var i = 0;
    while (i < params.size()) {
      let (k, v) = params[i];
      if (k == key) return v;
      i += 1;
    };
    ""
  };

  // extractWordAfter — returns the next whitespace-delimited token after `keyword`
  // e.g. "build an agent named SENTINEL for governance" + "named" → "SENTINEL"
  func extractWordAfter(text : Text, keyword : Text) : Text {
    let lower = text.toLower();
    let kwLower = keyword.toLower();
    if (not lower.contains(#text kwLower)) return "";

    // Split on whitespace, find keyword token, return next token
    let tokens = text.split(#char ' ');
    var found = false;
    for (token in tokens) {
      if (found) return token;
      if (token.toLower() == kwLower) found := true;
    };
    ""
  };

  func appendDirective(
    dirs : [(Text, BuilderDirective)],
    id   : Text,
    d    : BuilderDirective,
  ) : [(Text, BuilderDirective)] {
    let n = dirs.size();
    Array.tabulate<(Text, BuilderDirective)>(n + 1, func(i) {
      if (i < n) dirs[i] else (id, d)
    })
  };

  func findDirective(dirs : [(Text, BuilderDirective)], id : Text) : ?BuilderDirective {
    var i = 0;
    while (i < dirs.size()) {
      let (did, d) = dirs[i];
      if (did == id) return ?d;
      i += 1;
    };
    null
  };

  func setDirective(
    dirs : [(Text, BuilderDirective)],
    id   : Text,
    d    : BuilderDirective,
  ) : [(Text, BuilderDirective)] {
    Array.tabulate<(Text, BuilderDirective)>(dirs.size(), func(i) {
      let (did, old) = dirs[i];
      if (did == id) (id, d) else (did, old)
    })
  };

}
