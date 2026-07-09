"""
    Swarm — Agent-Based Modeling Module

Animal engines as agents. Swarm intelligence. Collective coherence.
The 9 animal engines are not just oscillators — they are autonomous agents
with behaviors, drives, and emergent coordination.

Uses Julia's multiple dispatch to define per-engine behavior:
- Each AnimalEngine dispatches differently to stimuli
- Swarm coherence emerges from local interactions
- Global intelligence is the emergent product

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Swarm

using ..Phi
using ..Kuramoto

export SwarmEngine, Agent, dispatch_agents!, swarm_coherence
export create_swarm, inject_stimulus!, collective_decision
export AgentState, Stimulus


"""
    Stimulus

An input stimulus to the swarm. Could be signal, data, or event.
"""
struct Stimulus
    source::Symbol              # :external, :internal, :schumann
    amplitude::Float64          # Strength ∈ [0, 1]
    frequency::Float64          # Hz (for oscillatory stimuli)
    payload::Dict{String, Any}  # Arbitrary data
end


"""
    AgentState

Internal state of a single agent (animal engine instance).
"""
mutable struct AgentState
    engine::Symbol              # :crow, :shark, :wolf, etc.
    position::Vector{Float64}   # Position in abstract state space
    velocity::Vector{Float64}   # Velocity (rate of change)
    energy::Float64             # Available energy ∈ [0, 1]
    coherence::Float64          # Local coherence with neighbors
    memory::Vector{Float64}     # Short-term memory buffer
    dispatch_count::Int         # How many times this agent has been dispatched
end


"""
    Agent

A full agent: state + behavior function + coupling to Kuramoto field.
"""
mutable struct Agent
    state::AgentState
    field::KuramotoField        # This agent's oscillator field
    behavior::Function          # (agent, stimulus) -> response
    neighbors::Vector{Int}      # Indices of neighboring agents
end


"""
    SwarmEngine

The 9-agent swarm. This IS the organism's intelligence substrate.
"""
mutable struct SwarmEngine
    agents::Vector{Agent}
    global_coherence::Float64
    beat::Int
    stimulus_history::Vector{Stimulus}
    decision_log::Vector{Tuple{Int, Symbol, Float64}}  # (beat, decision, confidence)
end


"""
    create_swarm() -> SwarmEngine

Create the 9-agent swarm with doctrine-compliant initialization.
Each agent gets its animal engine behavior and Kuramoto field.
"""
function create_swarm()::SwarmEngine
    engine_names = [:crow, :shark, :wolf, :octopus, :dolphin, :hive, :elephant, :orca, :eagle]

    agents = Agent[]
    for (i, name) in enumerate(engine_names)
        state = AgentState(
            name,
            randn(3) .* PHI_INV,       # Random position scaled by φ⁻¹
            zeros(3),                    # Zero initial velocity
            PHI_INV,                     # Energy at φ⁻¹
            PHI_INV,                     # Coherence at φ⁻¹
            zeros(FIB[8]),               # Memory buffer size F(8) = 21
            0,
        )

        field = KuramotoField(
            n = 9,
            field_type = mod1(i, 3),
            seed_freq = SCHUMANN_HARMONICS[min(i, length(SCHUMANN_HARMONICS))]
        )

        behavior = _get_engine_behavior(name)

        # Ring topology: each agent connects to neighbors
        neighbors = [mod1(i-1, 9), mod1(i+1, 9)]

        push!(agents, Agent(state, field, behavior, neighbors))
    end

    return SwarmEngine(agents, PHI_INV, 0, Stimulus[], Tuple{Int, Symbol, Float64}[])
end


"""
    dispatch_agents!(swarm::SwarmEngine, stimulus::Stimulus) -> Dict{Symbol, Any}

Dispatch a stimulus to all agents. Each agent processes via its
behavior function (multiple dispatch by engine type).
Returns aggregated swarm response.
"""
function dispatch_agents!(swarm::SwarmEngine, stimulus::Stimulus)::Dict{Symbol, Any}
    swarm.beat += 1
    push!(swarm.stimulus_history, stimulus)

    responses = Dict{Symbol, Any}()

    for agent in swarm.agents
        # Gate: only dispatch if agent has energy
        agent.state.energy < PHI_INV_5 && continue

        # Call agent's behavior function
        response = agent.behavior(agent, stimulus)
        responses[agent.state.engine] = response

        # Energy cost of processing
        agent.state.energy -= PHI_INV_4
        agent.state.energy = max(0.0, agent.state.energy)
        agent.state.dispatch_count += 1

        # Step the agent's Kuramoto field
        run_heartbeat!(agent.field)
    end

    # Update global coherence
    swarm.global_coherence = swarm_coherence(swarm)

    # Replenish energy (φ⁻³ per beat, scaled by coherence)
    for agent in swarm.agents
        agent.state.energy = min(1.0, agent.state.energy + PHI_INV_3 * swarm.global_coherence)
    end

    return responses
end


"""
    swarm_coherence(swarm::SwarmEngine) -> Float64

Compute global swarm coherence: mean of all agent order parameters.
"""
function swarm_coherence(swarm::SwarmEngine)::Float64
    rs = [order_parameter(agent.field) for agent in swarm.agents]
    return sum(rs) / length(rs)
end


"""
    inject_stimulus!(swarm::SwarmEngine, source::Symbol, amplitude::Float64, freq::Float64)

Convenience function to inject a stimulus into the swarm.
"""
function inject_stimulus!(swarm::SwarmEngine, source::Symbol, amplitude::Float64, freq::Float64)
    stim = Stimulus(source, amplitude, freq, Dict{String,Any}())
    return dispatch_agents!(swarm, stim)
end


"""
    collective_decision(swarm::SwarmEngine, options::Vector{Symbol}) -> (Symbol, Float64)

The swarm makes a collective decision from options.
Each agent "votes" based on its coherence and energy.
Returns (chosen_option, confidence).
"""
function collective_decision(swarm::SwarmEngine, options::Vector{Symbol})::Tuple{Symbol, Float64}
    isempty(options) && return (:none, 0.0)

    # Each agent votes with weight = coherence × energy
    votes = Dict(opt => 0.0 for opt in options)

    for (i, agent) in enumerate(swarm.agents)
        weight = agent.state.coherence * agent.state.energy
        # Agent's choice: based on hash of state + option
        preferred_idx = mod1(agent.state.dispatch_count + i, length(options))
        votes[options[preferred_idx]] += weight
    end

    # Winner takes all
    best_option = options[1]
    best_score = 0.0
    total_weight = sum(values(votes))

    for (opt, score) in votes
        if score > best_score
            best_score = score
            best_option = opt
        end
    end

    confidence = total_weight > 0 ? best_score / total_weight : 0.0
    push!(swarm.decision_log, (swarm.beat, best_option, confidence))

    return (best_option, confidence)
end


# ═══════════════════════════════════════════════════════════════════════════════
# ENGINE BEHAVIORS — Multiple dispatch by animal type
# ═══════════════════════════════════════════════════════════════════════════════

function _get_engine_behavior(engine::Symbol)::Function
    behaviors = Dict(
        :crow => _crow_behavior,
        :shark => _shark_behavior,
        :wolf => _wolf_behavior,
        :octopus => _octopus_behavior,
        :dolphin => _dolphin_behavior,
        :hive => _hive_behavior,
        :elephant => _elephant_behavior,
        :orca => _orca_behavior,
        :eagle => _eagle_behavior,
    )
    return get(behaviors, engine, _default_behavior)
end

# CROW: Pattern prediction — looks for φ-ratios in stimulus
function _crow_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    # Crow predicts: is the stimulus φ-coherent?
    prediction = abs(stim.amplitude - PHI_INV) < PHI_INV_3
    agent.state.coherence = prediction ? min(1.0, agent.state.coherence + PHI_INV_3) : agent.state.coherence * 0.95
    return Dict("prediction" => prediction, "coherence" => agent.state.coherence)
end

# SHARK: Yield convergence — finds optimal frequency lock at 40 Hz
function _shark_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    target_freq = 40.0  # Gamma band
    freq_error = abs(stim.frequency - target_freq)
    convergence = exp(-freq_error * PHI_INV)
    agent.state.coherence = 0.8 * agent.state.coherence + 0.2 * convergence
    return Dict("convergence" => convergence, "freq_error" => freq_error)
end

# WOLF: Drive formation — amplifies strong stimuli
function _wolf_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    drive = stim.amplitude^PHI_INV  # Power-law amplification
    agent.state.velocity .+= randn(3) .* drive .* PHI_INV
    agent.state.position .+= agent.state.velocity .* PHI_INV_3
    return Dict("drive" => drive, "position" => copy(agent.state.position))
end

# OCTOPUS: Multi-path routing — explores multiple responses simultaneously
function _octopus_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    paths = 8  # Octopus has 8 arms
    path_scores = [stim.amplitude * phi_multiplier(-i) for i in 1:paths]
    best_path = argmax(path_scores)
    return Dict("paths_explored" => paths, "best_path" => best_path, "scores" => path_scores)
end

# DOLPHIN: Alignment scoring — measures how aligned stimulus is with swarm
function _dolphin_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    R = order_parameter(agent.field)
    alignment = R * stim.amplitude
    agent.state.coherence = 0.7 * agent.state.coherence + 0.3 * alignment
    return Dict("alignment" => alignment, "order_param" => R)
end

# HIVE: Swarm coordination — updates position toward swarm center
function _hive_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    # Move toward origin (swarm center approximation)
    center_pull = -agent.state.position .* PHI_INV_2
    agent.state.velocity .= 0.9 .* agent.state.velocity .+ center_pull
    agent.state.position .+= agent.state.velocity .* PHI_INV_3
    coordination = 1.0 / (1.0 + norm_l2(agent.state.position))
    return Dict("coordination" => coordination, "distance_to_center" => norm_l2(agent.state.position))
end

# ELEPHANT: Memory consolidation — stores stimulus in memory buffer
function _elephant_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    # Shift memory buffer and insert new value
    agent.state.memory[2:end] .= agent.state.memory[1:end-1]
    agent.state.memory[1] = stim.amplitude
    # Recall strength = φ-coherence of memory
    recall = phi_coherence(filter(!=(0.0), agent.state.memory))
    return Dict("recall_strength" => recall, "memory_fill" => count(!=(0.0), agent.state.memory))
end

# ORCA: Coherence maintenance — actively drives field toward sync
function _orca_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    # Orca injects coherence into its field
    R_before = order_parameter(agent.field)
    # Push all phases toward mean phase
    Ψ = angle(sum(exp.(im .* agent.field.phases)) / agent.field.n)
    for i in 1:agent.field.n
        Δ = Ψ - agent.field.phases[i]
        agent.field.phases[i] += stim.amplitude * PHI_INV * sin(Δ)
    end
    agent.field.phases .= mod.(agent.field.phases, 2π)
    R_after = order_parameter(agent.field)
    return Dict("R_before" => R_before, "R_after" => R_after, "improvement" => R_after - R_before)
end

# EAGLE: Elevation sensing — observes from above, detects curvature
function _eagle_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    # Eagle measures "height" (abstraction level) and "curvature" (rate of change)
    elevation = phi_multiplier(round(Int, stim.amplitude * 5))
    curvature = stim.frequency > 0 ? stim.amplitude / stim.frequency : 0.0
    return Dict("elevation" => elevation, "curvature" => curvature)
end

function _default_behavior(agent::Agent, stim::Stimulus)::Dict{String, Any}
    return Dict("status" => "no_behavior_defined")
end

# Simple L2 norm (avoid LinearAlgebra dependency in this module)
function norm_l2(v::Vector{Float64})::Float64
    return sqrt(sum(v.^2))
end

end # module Swarm
