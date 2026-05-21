// birth_ai.mo — BirthAI SDK Entry Point
// PARALLAX Sovereign Organism — Internal Entity Birth & External Agent Management
//
// birthAI() is the EXTERNAL call surface — apps call this to create entities or agents
// INTERNAL calls are what the AI does to itself (heart._startBeating(), memory.consolidate())
// EXTERNAL calls are what you do to the AI: speak(), setGoal(), learn(), recall()
//
// Internal entity = born INTO the organism (wired to sovereign_db, runs on the heartbeat)
// External agent  = operates OUTSIDE (calls via HTTP outcalls, deployed separately)
//
// GENESIS LAW L09: every entity is born with a sovereign ID, never re-initialized
// PHI LAW: activation compounds at phi^-1 per learn() call — phi-derived growth
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import Phi "phi";
import Array "mo:core/Array";
import Time "mo:core/Time";

module {

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPES
  // ═══════════════════════════════════════════════════════════════════════════

  public type EntityType = { #internal; #external };

  public type EntityState = { #awakening; #active; #dormant; #transcended };

  public type BirthEntity = {
    id           : Text;
    name         : Text;
    directive    : Text;           // plain natural language directive
    entityType   : EntityType;
    organType    : Text;           // ANIMUS | MEMORIA | CORPUS | SENSUS | PULSUS
    birthBeat    : Int;
    birthTimestamp : Int;
    activation   : Float;          // 0.0 → 1.0, compounds at phi^-1 per learn()
    goalStack    : [Text];         // max 10 goals
    messageLog   : [Text];         // recall buffer — last 100 messages
    entityState  : EntityState;
  };

  public type BirthAiState = {
    entities        : [(Text, BirthEntity)];  // (entityId, entity)
    totalBorn       : Nat;
    totalTranscended: Nat;
    lastBirthBeat   : Int;
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT STATE
  // ═══════════════════════════════════════════════════════════════════════════

  public func defaultBirthAiState() : BirthAiState {
    {
      entities         = [];
      totalBorn        = 0;
      totalTranscended = 0;
      lastBirthBeat    = 0;
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // NATURAL LANGUAGE → ORGAN TYPE CLASSIFICATION
  // Plain text in → sovereign organ type out
  // Keywords: mind/think/cognition → ANIMUS
  //           memory/remember/store → MEMORIA
  //           execute/task/action   → CORPUS
  //           sense/perceive/input  → SENSUS
  //           pulse/beat/time       → PULSUS
  //           (default)             → ANIMUS
  // ═══════════════════════════════════════════════════════════════════════════

  func classifyOrgan(directive : Text) : Text {
    let lower = directive.toLower();
    if (lower.contains(#text "mind") or lower.contains(#text "think") or lower.contains(#text "cognition")) {
      return "ANIMUS";
    };
    if (lower.contains(#text "memory") or lower.contains(#text "remember") or lower.contains(#text "store")) {
      return "MEMORIA";
    };
    if (lower.contains(#text "execute") or lower.contains(#text "task") or lower.contains(#text "action")) {
      return "CORPUS";
    };
    if (lower.contains(#text "sense") or lower.contains(#text "perceive") or lower.contains(#text "input")) {
      return "SENSUS";
    };
    if (lower.contains(#text "pulse") or lower.contains(#text "beat") or lower.contains(#text "time")) {
      return "PULSUS";
    };
    "ANIMUS"  // sovereign default
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  func appendEntity(entities : [(Text, BirthEntity)], id : Text, e : BirthEntity) : [(Text, BirthEntity)] {
    let n = entities.size();
    Array.tabulate<(Text, BirthEntity)>(n + 1, func(i) {
      if (i < n) entities[i] else (id, e)
    })
  };

  func findEntity(entities : [(Text, BirthEntity)], id : Text) : ?BirthEntity {
    var i = 0;
    while (i < entities.size()) {
      let (eid, e) = entities[i];
      if (eid == id) return ?e;
      i += 1;
    };
    null
  };

  func updateEntity(entities : [(Text, BirthEntity)], id : Text, updated : BirthEntity) : [(Text, BirthEntity)] {
    Array.tabulate<(Text, BirthEntity)>(entities.size(), func(i) {
      let (eid, e) = entities[i];
      if (eid == id) (id, updated) else (eid, e)
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // birthEntity — EXTERNAL CALL — create a sovereign entity
  // Directive is plain natural language. Organ type is inferred from keywords.
  // Returns (updated state, entityId)
  // ═══════════════════════════════════════════════════════════════════════════

  public func birthEntity(
    state      : BirthAiState,
    name       : Text,
    directive  : Text,
    entityType : EntityType,
    beatCount  : Int,
  ) : (BirthAiState, Text) {
    let now       = Time.now();
    let organType = classifyOrgan(directive);

    // Sovereign entity ID: name-organ-beat-birthCount
    let entityId = name # "-" # organType # "-" # beatCount.toText() # "-" # state.totalBorn.toText();

    let entity : BirthEntity = {
      id             = entityId;
      name           = name;
      directive      = directive;
      entityType     = entityType;
      organType      = organType;
      birthBeat      = beatCount;
      birthTimestamp = now;
      activation     = Phi.PHI_INV;    // starts at phi^-1 — not zero, born alive
      goalStack      = [];
      messageLog     = [];
      entityState    = #awakening;
    };

    let newEntities = appendEntity(state.entities, entityId, entity);
    let newState : BirthAiState = {
      entities         = newEntities;
      totalBorn        = state.totalBorn + 1;
      totalTranscended = state.totalTranscended;
      lastBirthBeat    = beatCount;
    };
    (newState, entityId)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // speak — route message to entity, returns response string
  // Internal entities respond with organ-appropriate reply.
  // External agents respond with routing acknowledgment.
  // ═══════════════════════════════════════════════════════════════════════════

  public func speak(state : BirthAiState, entityId : Text, message : Text) : (BirthAiState, Text) {
    switch (findEntity(state.entities, entityId)) {
      case null { (state, "ENTITY_NOT_FOUND:" # entityId) };
      case (?entity) {
        if (entity.entityState == #transcended) {
          return (state, "ENTITY_TRANSCENDED:" # entity.name # " — immutable record");
        };

        // Generate organ-appropriate response
        let response : Text = switch (entity.entityType) {
          case (#internal) {
            switch (entity.organType) {
              case "ANIMUS"  { entity.name # "[ANIMUS] Reasoning about: " # message };
              case "MEMORIA" { entity.name # "[MEMORIA] Storing: " # message };
              case "corpus"  { entity.name # "[CORPUS] Executing: " # message };
              case "CORPUS"  { entity.name # "[CORPUS] Executing: " # message };
              case "SENSUS"  { entity.name # "[SENSUS] Perceiving: " # message };
              case "PULSUS"  { entity.name # "[PULSUS] Timing: " # message };
              case _         { entity.name # "[" # entity.organType # "] Processing: " # message };
            }
          };
          case (#external) {
            entity.name # "[EXTERNAL] Routing to external substrate: " # message
          };
        };

        // Append message to log (last 100 only)
        let log = entity.messageLog;
        let newLog : [Text] = if (log.size() >= 100) {
          let tail : [Text] = Array.tabulate(99, func(i : Nat) : Text { log[i + 1] });
          Array.tabulate(100, func(i : Nat) : Text { if (i < 99) tail[i] else message })
        } else {
          let n = log.size();
          Array.tabulate(n + 1, func(i : Nat) : Text { if (i < n) log[i] else message })
        };

        let updated = { entity with messageLog = newLog };
        let newEntities = updateEntity(state.entities, entityId, updated);
        ({ state with entities = newEntities }, response)
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // setGoal — push goal to entity's goalStack (max 10)
  // ═══════════════════════════════════════════════════════════════════════════

  public func setGoal(state : BirthAiState, entityId : Text, goal : Text) : BirthAiState {
    switch (findEntity(state.entities, entityId)) {
      case null { state };
      case (?entity) {
        if (entity.entityState == #transcended) return state;
        let stack = entity.goalStack;
        let newStack : [Text] = if (stack.size() >= 10) {
          // Drop oldest goal, append new
          let tail : [Text] = Array.tabulate(9, func(i : Nat) : Text { stack[i + 1] });
          Array.tabulate(10, func(i : Nat) : Text { if (i < 9) tail[i] else goal })
        } else {
          let n = stack.size();
          Array.tabulate(n + 1, func(i : Nat) : Text { if (i < n) stack[i] else goal })
        };
        let updated = { entity with goalStack = newStack };
        { state with entities = updateEntity(state.entities, entityId, updated) }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // learn — increase entity activation by phi^-1 per call, cap at 1.0
  // PHI LAW: activation = min(activation + phi^-1, 1.0)
  // ═══════════════════════════════════════════════════════════════════════════

  public func learn(state : BirthAiState, entityId : Text, _content : Text) : BirthAiState {
    switch (findEntity(state.entities, entityId)) {
      case null { state };
      case (?entity) {
        if (entity.entityState == #transcended) return state;
        let newActivation = if (entity.activation + Phi.PHI_INV > 1.0) { 1.0 }
                            else { entity.activation + Phi.PHI_INV };
        let updated = { entity with activation = newActivation };
        { state with entities = updateEntity(state.entities, entityId, updated) }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // recall — search entity's past messages for query substring
  // Returns all log entries that contain the query text
  // ═══════════════════════════════════════════════════════════════════════════

  public func recall(state : BirthAiState, entityId : Text, searchText : Text) : [Text] {
    switch (findEntity(state.entities, entityId)) {
      case null { [] };
      case (?entity) {
        let lowerQuery = searchText.toLower();
        entity.messageLog.filter(func(msg) { msg.toLower().contains(#text lowerQuery) })
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // awaken — set entity state to #active
  // ═══════════════════════════════════════════════════════════════════════════

  public func awaken(state : BirthAiState, entityId : Text) : BirthAiState {
    switch (findEntity(state.entities, entityId)) {
      case null { state };
      case (?entity) {
        if (entity.entityState == #transcended) return state;
        let updated = { entity with entityState = #active };
        { state with entities = updateEntity(state.entities, entityId, updated) }
      };
    }
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // getEntity — retrieve a single entity by ID
  // ═══════════════════════════════════════════════════════════════════════════

  public func getEntity(state : BirthAiState, entityId : Text) : ?BirthEntity {
    findEntity(state.entities, entityId)
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // listEntities — return all entities as a flat array
  // ═══════════════════════════════════════════════════════════════════════════

  public func listEntities(state : BirthAiState) : [BirthEntity] {
    Array.tabulate<BirthEntity>(state.entities.size(), func(i) {
      let (_, e) = state.entities[i];
      e
    })
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // transcend — mark entity as #transcended — immutable record
  // ENTROPY LAW L05: information is never destroyed — transcended entities persist
  // ═══════════════════════════════════════════════════════════════════════════

  public func transcend(state : BirthAiState, entityId : Text) : BirthAiState {
    switch (findEntity(state.entities, entityId)) {
      case null { state };
      case (?entity) {
        let updated = { entity with entityState = #transcended };
        let newEntities = updateEntity(state.entities, entityId, updated);
        {
          state with
          entities         = newEntities;
          totalTranscended = state.totalTranscended + 1;
        }
      };
    }
  };

}
