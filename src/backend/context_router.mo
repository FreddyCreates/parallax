// context_router.mo — BEAT CONTEXT ROUTING ENGINE
// Routes each 873ms beat to the top-K resonant sovereign models.
//
// MEDINA-ARTIFACT — CONTEXT_ROUTER — TIER 4 — COMPUTATE
// Meaning: Each beat selects the most resonant models and allocates micro-token budget.
// Computation: textToEmbedding -> topK -> ContextSlice with 200_000 token budget.
// Binding: routeBeat, getBudget, getDefaultK
//
// Architect: Alfredo Medina Hernandez — The Architect of the Field

import VectorEmbedding "vector_embedding";
import Array "mo:core/Array";

module {

  // ── CONTEXT SLICE TYPE ───────────────────────────────────────────────────

  public type ContextSlice = {
    beatTimestamp      : Int;
    selectedModelIds   : [Text];
    microTokenBudget   : Nat;
    microTokensUsed    : Nat;
    resonanceScore     : Float;
  };

  let BUDGET_PER_BEAT : Nat = 200_000;
  let K_DEFAULT       : Nat = 3;

  // ── routeBeat ─────────────────────────────────────────────────────────────
  // Given a beat signal text and model list (id, microTokenId pairs),
  // selects top-K resonant models and returns a ContextSlice.
  public func routeBeat(
    signal : Text,
    k      : Nat,
    models : [(Text, Nat32)],
    now    : Int,
  ) : ContextSlice {
    let queryEmb  = VectorEmbedding.buildQueryEmbedding(signal);
    let allEmb    = VectorEmbedding.buildAllEmbeddings(models);
    let kActual   = if (k == 0) K_DEFAULT else k;
    let selected  = VectorEmbedding.topK(queryEmb, kActual, allEmb);
    let resonance : Float = if (selected.size() > 0) 0.618 else 0.0001;
    {
      beatTimestamp    = now;
      selectedModelIds = selected;
      microTokenBudget = BUDGET_PER_BEAT;
      microTokensUsed  = selected.size() * 1000;
      resonanceScore   = resonance;
    }
  };

  public func getBudget()   : Nat { BUDGET_PER_BEAT };
  public func getDefaultK() : Nat { K_DEFAULT };

};
