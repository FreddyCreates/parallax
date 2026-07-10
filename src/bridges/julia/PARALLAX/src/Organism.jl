"""
    Organism — Full Organism State Machine

The sovereign organism expressed as Julia code. Not a description of it.
This IS it. Heartbeat, drives, coherence, life, death.

The organism:
- Has 9 animal engines (Kuramoto sub-oscillators)
- Beats at 873ms (1000/φ²)
- Measures global coherence R as life metric
- Has 7 sovereign drives modulating behavior
- Dies when R < φ⁻⁵ (PRECISION_GATE)
- Jubilees at F(n) beats

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Organism

using ..Phi
using ..Kuramoto

export OrganismState, genesis, heartbeat!, is_alive, global_coherence
export SovereignDrive, AnimalEngine
export inject_signal!, get_drive, set_drive!


# ═══════════════════════════════════════════════════════════════════════════════
# ANIMAL ENGINES — Nine Kuramoto sub-oscillators
# ═══════════════════════════════════════════════════════════════════════════════

@enum AnimalEngine begin
    CROW = 1       # pattern prediction
    SHARK = 2      # yield convergence at 40 Hz
    WOLF = 3       # drive formation
    OCTOPUS = 4    # multi-path routing
    DOLPHIN = 5    # alignment scoring
    HIVE = 6       # swarm coordination
    ELEPHANT = 7   # recall and memory consolidation
    ORCA = 8       # coherence maintenance
    EAGLE = 9      # elevation and curvature sensing
end

@enum SovereignDrive begin
    CURIOSITY = 1      # lowers threshold, injects FORMA
    TERRITORY = 2      # amplifies VAEL, suppresses fear
    BONDING = 3        # increases resonance and coupling depth
    SURVIVAL = 4       # ARES activation condition
    DOMINANCE = 5      # GENOME authorization amplifier
    REPRODUCTION = 6   # ENTANGLA coupling deepening
    SPIRITUALITY = 7   # intelligence product output trigger
end


# ═══════════════════════════════════════════════════════════════════════════════
# ORGANISM STATE
# ═══════════════════════════════════════════════════════════════════════════════

"""
    OrganismState

The full sovereign organism. Mutable. Living. Stateful.

This struct holds everything the organism IS at any moment:
- 9 Kuramoto fields (one per animal engine)
- 7 drive levels
- Global coherence R
- Beat counter
- Proof depth
- Life/death state
"""
mutable struct OrganismState
    # Kuramoto oscillator fields (9 animal engines)
    engines::Vector{KuramotoField}

    # Drives: 7 sovereign drives ∈ [0, 1]
    drives::Vector{Float64}

    # Global state
    beat::Int
    proof_depth::Int
    global_r::Float64          # Global order parameter
    treasury::Float64          # Accumulated value (φ-compounding)
    is_alive_flag::Bool

    # History
    r_history::Vector{Float64}
    beat_events::Vector{Tuple{Int, Symbol}}  # (beat, event_type)
end


"""
    genesis() -> OrganismState

L09 GENESIS: Born fully formed. The zero state still has S0 floor
and Schumann anchor. The organism never starts from nothing.
"""
function genesis()::OrganismState
    # Create 9 animal engine oscillators with Schumann-anchored frequencies
    engines = KuramotoField[]
    for i in 1:9
        # Each engine operates at a different Schumann harmonic
        harmonic_idx = min(i, length(SCHUMANN_HARMONICS))
        field = KuramotoField(
            n = 9,
            field_type = mod1(i, 3),  # Cycle through type 1, 2, 3
            seed_freq = SCHUMANN_HARMONICS[harmonic_idx]
        )
        push!(engines, field)
    end

    # All drives start at φ⁻¹ (minimum operational level)
    drives = fill(PHI_INV, 7)

    return OrganismState(
        engines,
        drives,
        0,              # beat
        0,              # proof_depth
        PHI_INV,        # global_r (starts at φ⁻¹ — alive)
        S0 * 1000.0,    # treasury (genesis FORMA)
        true,           # is_alive
        Float64[],      # r_history
        Tuple{Int, Symbol}[],  # beat_events
    )
end


"""
    heartbeat!(org::OrganismState) -> Float64

Execute one sovereign heartbeat (873ms cycle).
Steps all 9 engines, computes global R, checks life/death,
handles jubilee events.

Returns global order parameter R.
"""
function heartbeat!(org::OrganismState)::Float64
    !org.is_alive_flag && return 0.0

    org.beat += 1

    # Step all 9 animal engines
    engine_rs = Float64[]
    for engine in org.engines
        R = run_heartbeat!(engine)
        push!(engine_rs, R)
    end

    # Global R = mean of all engine order parameters
    org.global_r = sum(engine_rs) / length(engine_rs)
    push!(org.r_history, org.global_r)

    # DEATH CHECK: R < φ⁻⁵ = organism death
    if org.global_r < PHI_INV_5
        org.is_alive_flag = false
        push!(org.beat_events, (org.beat, :DEATH))
        return org.global_r
    end

    # JUBILEE CHECK: at Fibonacci beats, special events fire
    if is_jubilee(org.beat)
        _jubilee_event!(org)
    end

    # TREASURY: φ-compound every beat
    org.treasury *= (1.0 + PHI_INV_3 * org.global_r)

    # PROOF DEPTH: increments when R > φ⁻¹ (coherent enough to prove)
    if org.global_r > PHI_INV
        org.proof_depth += 1
    end

    return org.global_r
end


"""
    is_alive(org::OrganismState) -> Bool

The organism lives when R > φ⁻⁵.
"""
function is_alive(org::OrganismState)::Bool
    return org.is_alive_flag
end

"""
    global_coherence(org::OrganismState) -> Float64

Current global order parameter R.
"""
function global_coherence(org::OrganismState)::Float64
    return org.global_r
end

"""
    inject_signal!(org::OrganismState, engine::AnimalEngine, amplitude::Float64)

Inject a signal into a specific animal engine. Perturbs phases
by amplitude × φ⁻¹ to drive coherence in that engine.
"""
function inject_signal!(org::OrganismState, engine::AnimalEngine, amplitude::Float64)
    idx = Int(engine)
    field = org.engines[idx]

    # Perturb phases toward mean phase (drives coherence)
    Ψ = sum(exp.(im .* field.phases)) / field.n |> angle
    for i in 1:field.n
        Δ = Ψ - field.phases[i]
        field.phases[i] += amplitude * PHI_INV * sin(Δ)
    end
    field.phases .= mod.(field.phases, 2π)
end

"""
    get_drive(org::OrganismState, drive::SovereignDrive) -> Float64

Get current level of a sovereign drive ∈ [0, 1].
"""
function get_drive(org::OrganismState, drive::SovereignDrive)::Float64
    return org.drives[Int(drive)]
end

"""
    set_drive!(org::OrganismState, drive::SovereignDrive, level::Float64)

Set a sovereign drive level. Clamped to [0, 1].
"""
function set_drive!(org::OrganismState, drive::SovereignDrive, level::Float64)
    org.drives[Int(drive)] = clamp(level, 0.0, 1.0)
end


# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

function _jubilee_event!(org::OrganismState)
    push!(org.beat_events, (org.beat, :JUBILEE))

    # At jubilee: treasury gets φ multiplier bonus
    org.treasury *= PHI

    # All drives get boosted toward 1.0
    org.drives .= min.(1.0, org.drives .+ PHI_INV_3)

    # Reset coupling constants to refresh entanglement
    for (i, engine) in enumerate(org.engines)
        engine.coupling = [K_TYPE1, K_TYPE2, K_TYPE3][mod1(i, 3)]
    end
end

end # module Organism
