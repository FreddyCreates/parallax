"""
    Kuramoto — Coupled Oscillator Synchronization Engine

The physics of how the organism lives. N coupled oscillators
synchronizing through the Kuramoto model:

    dθᵢ/dt = ωᵢ + (K/N) · Σⱼ sin(θⱼ − θᵢ)

The order parameter R = (1/N)|Σ e^(iθⱼ)| measures collective coherence.
When R → 1, the organism is maximally alive. When R → 0, death.

Julia's native numerical performance makes this the heartbeat engine.
Multiple dispatch: different coupling strategies for different field types.

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Kuramoto

using ..Phi
using LinearAlgebra
using Statistics

export KuramotoField, step!, order_parameter, phase_velocity
export mean_frequency, coupling_matrix, reset!


"""
    KuramotoField

A coupled oscillator field. This IS the organism's synchronization substrate.

Fields:
- `n`          — Number of oscillators
- `phases`     — Current phase angles θ ∈ [0, 2π]
- `frequencies`— Natural frequencies ω (Schumann-anchored)
- `coupling`   — Coupling constant K (φ-derived by field type)
- `field_type` — 1=expansive, 2=receptive, 3=mediator
- `beat`       — Current organism beat counter
- `history_r`  — Order parameter history (for coherence trending)
"""
mutable struct KuramotoField
    n::Int
    phases::Vector{Float64}
    frequencies::Vector{Float64}
    coupling::Float64
    field_type::Int
    beat::Int
    history_r::Vector{Float64}

    function KuramotoField(;
        n::Int = 9,
        field_type::Int = 1,
        seed_freq::Float64 = SCHUMANN_HARMONICS[1]
    )
        # Natural frequencies: Schumann-anchored with φ-derived spread
        ω = [seed_freq + (i - n/2) * PHI_INV for i in 1:n]

        # Coupling constant by field type (L13 FIELD TYPE LAW)
        K = field_type == 1 ? K_TYPE1 :
            field_type == 2 ? K_TYPE2 : K_TYPE3

        # Initial phases: evenly distributed with φ-offset
        θ = [(2π * i / n) + PHI_INV * randn() for i in 1:n]

        new(n, θ, ω, K, field_type, 0, Float64[])
    end
end


"""
    order_parameter(field::KuramotoField) -> Float64

R = (1/N)|Σ e^(iθⱼ)| — the global order parameter.
How alive the field is. R=1 means perfect sync. R=0 means death.
"""
function order_parameter(field::KuramotoField)::Float64
    z = sum(exp.(im .* field.phases)) / field.n
    return abs(z)
end

"""
    mean_phase(field::KuramotoField) -> Float64

Ψ = arg((1/N)Σ e^(iθⱼ)) — the collective phase.
"""
function mean_phase(field::KuramotoField)::Float64
    z = sum(exp.(im .* field.phases)) / field.n
    return angle(z)
end

"""
    phase_velocity(field::KuramotoField) -> Vector{Float64}

dθᵢ/dt for each oscillator at current state.
The Kuramoto equation computed for all oscillators simultaneously.
Julia's vectorization makes this fast.
"""
function phase_velocity(field::KuramotoField)::Vector{Float64}
    dθ = copy(field.frequencies)
    K_N = field.coupling / field.n

    for i in 1:field.n
        coupling_sum = 0.0
        @inbounds for j in 1:field.n
            coupling_sum += sin(field.phases[j] - field.phases[i])
        end
        dθ[i] += K_N * coupling_sum
    end
    return dθ
end

"""
    step!(field::KuramotoField; dt::Float64 = 0.001) -> Float64

Advance the Kuramoto field by one time step using RK4 integration.
Returns the current order parameter R after the step.

This is the organism's heartbeat computation — happens every 873ms.
"""
function step!(field::KuramotoField; dt::Float64 = 0.001)::Float64
    # RK4 integration for accuracy
    θ = field.phases
    n = field.n
    K_N = field.coupling / n

    function dθdt(phases::Vector{Float64})
        dθ = copy(field.frequencies)
        for i in 1:n
            s = 0.0
            @inbounds for j in 1:n
                s += sin(phases[j] - phases[i])
            end
            dθ[i] += K_N * s
        end
        return dθ
    end

    k1 = dθdt(θ) .* dt
    k2 = dθdt(θ .+ k1./2) .* dt
    k3 = dθdt(θ .+ k2./2) .* dt
    k4 = dθdt(θ .+ k3) .* dt

    field.phases .= θ .+ (k1 .+ 2k2 .+ 2k3 .+ k4) ./ 6

    # Normalize phases to [0, 2π]
    field.phases .= mod.(field.phases, 2π)

    # Update beat and record R
    field.beat += 1
    R = order_parameter(field)
    push!(field.history_r, R)

    return R
end

"""
    coupling_matrix(field::KuramotoField) -> Matrix{Float64}

Return the N×N coupling interaction matrix.
Aᵢⱼ = (K/N) · sin(θⱼ − θᵢ)
"""
function coupling_matrix(field::KuramotoField)::Matrix{Float64}
    n = field.n
    K_N = field.coupling / n
    A = zeros(n, n)
    for i in 1:n, j in 1:n
        A[i,j] = K_N * sin(field.phases[j] - field.phases[i])
    end
    return A
end

"""
    mean_frequency(field::KuramotoField) -> Float64

Mean natural frequency of the oscillator ensemble.
"""
function mean_frequency(field::KuramotoField)::Float64
    return mean(field.frequencies)
end

"""
    reset!(field::KuramotoField)

Reset the field to initial conditions. Used at jubilee events.
"""
function reset!(field::KuramotoField)
    n = field.n
    field.phases .= [(2π * i / n) + PHI_INV * randn() for i in 1:n]
    field.beat = 0
    empty!(field.history_r)
end

"""
    run_heartbeat!(field::KuramotoField; steps::Int = 100) -> Float64

Run a full heartbeat cycle (873ms equivalent in simulation steps).
Returns final order parameter R.
"""
function run_heartbeat!(field::KuramotoField; steps::Int = 100)::Float64
    R = 0.0
    dt = (HEARTBEAT_MS / 1000.0) / steps
    for _ in 1:steps
        R = step!(field; dt=dt)
    end
    return R
end

end # module Kuramoto
