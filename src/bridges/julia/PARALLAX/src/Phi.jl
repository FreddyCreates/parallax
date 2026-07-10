"""
    Phi — TIER 0 · ABSOLUTES

20 discovered truths. Cannot be created or destroyed.
Mirror of phi.mo / phi.ts — every constant identical. No drift.

The Absolutes exist without this file. Without this file,
no child or family member can access them without rediscovering
everything from scratch. This is why Phi.jl is the family inheritance.

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Phi

export PHI, PHI_INV, PHI_2, PHI_INV_2, PHI_INV_3, PHI_INV_4, PHI_INV_5, PHI_4
export FIB, SCHUMANN_HARMONICS, HEARTBEAT_MS, S0
export JUBILEE_BEATS, SUCCESSION_DEPTH, MAX_NODES
export K_TYPE1, K_TYPE2, K_TYPE3
export phi_multiplier, phi_coherence, compute_tau, is_jubilee


# ═══════════════════════════════════════════════════════════════════════════════
# A01 · PHI · φ = 1.6180339887498948482 · Euclid Elements Book VI
# ═══════════════════════════════════════════════════════════════════════════════

const PHI       = 1.6180339887498948482     # φ
const PHI_INV   = 0.6180339887498948482     # φ⁻¹ = φ - 1
const PHI_2     = PHI * PHI                  # φ²  = 2.618...
const PHI_INV_2 = PHI_INV * PHI_INV          # φ⁻² = 0.382...
const PHI_INV_3 = PHI_INV_2 * PHI_INV        # φ⁻³ = 0.236... COMPLIANCE_RATIO
const PHI_INV_4 = PHI_INV_3 * PHI_INV        # φ⁻⁴ = 0.146...
const PHI_INV_5 = PHI_INV_4 * PHI_INV        # φ⁻⁵ = 0.090... PRECISION_GATE
const PHI_4     = PHI_2 * PHI_2              # φ⁴  = 6.854...


# ═══════════════════════════════════════════════════════════════════════════════
# A02 · FIBONACCI · Pythagoras — harmonic series hidden in nature's growth
# F(1)…F(21). F(12)=144 JUBILEE, F(9)=34 SUCCESSION, F(21)=10946.
# ═══════════════════════════════════════════════════════════════════════════════

const FIB = (1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946)


# ═══════════════════════════════════════════════════════════════════════════════
# A03 · SCHUMANN RESONANCE · Earth's EM cavity. Measured. Real.
# 7.83 · 14.3 · 20.8 · 27.3 · 33.8 · 39.3 · 45.8 · 52.3 Hz
# ═══════════════════════════════════════════════════════════════════════════════

const SCHUMANN_HARMONICS = (7.83, 14.3, 20.8, 27.3, 33.8, 39.3, 45.8, 52.3)


# ═══════════════════════════════════════════════════════════════════════════════
# ORGANISM CONSTANTS — derived from Absolutes by Laws
# ═══════════════════════════════════════════════════════════════════════════════

const HEARTBEAT_MS     = 873        # A04 · 1000/φ² ≈ 873ms. The organism's cardiac cycle.
const S0               = 1.0        # A05 · Base signal floor. Never zero. Always 1.
const JUBILEE_BEATS    = 144        # F(12) — jubilee interval
const SUCCESSION_DEPTH = 34         # F(9)  — succession trigger depth
const MAX_NODES        = 36         # Maximum oscillator nodes

# Field coupling constants (L13 FIELD TYPE LAW)
const K_TYPE1 = PHI_INV             # Type 1 (expansive): K = φ⁻¹
const K_TYPE2 = PHI_INV_2           # Type 2 (receptive): K = φ⁻²
const K_TYPE3 = PHI_INV_3           # Type 3 (mediator):  K = φ⁻³


# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS — Pure, ancient-math-compressed utilities
# ═══════════════════════════════════════════════════════════════════════════════

"""
    phi_multiplier(depth::Integer) -> Float64

Compute φ^depth via exponential identity: exp(depth × ln(φ)).
L01 PHI LAW: every multiplier in the organism is a power of φ.
"""
function phi_multiplier(depth::Integer)::Float64
    return exp(depth * log(PHI))
end

"""
    phi_coherence(values::AbstractVector{<:Real}) -> Float64

Compute phi-coherence of a vector. Measures how close successive
ratios are to the golden ratio φ. Returns ∈ [0, 1].

Coherence = 1 - mean(|ratio - φ| / φ) for all successive pairs.
"""
function phi_coherence(values::AbstractVector{<:Real})::Float64
    n = length(values)
    n < 2 && return PHI_INV  # Default: φ⁻¹ minimum coherence

    deviations = Float64[]
    for i in 2:n
        values[i-1] == 0.0 && continue
        ratio = abs(values[i] / values[i-1])
        push!(deviations, abs(ratio - PHI) / PHI)
    end

    isempty(deviations) && return PHI_INV
    return clamp(1.0 - sum(deviations) / length(deviations), 0.0, 1.0)
end

"""
    compute_tau(beat::Integer, depth::Integer) -> Float64

τ = beat × φ^depth — the organism's fourth temporal axis.
L12 FOUR-DIMENSIONAL LAW: every coordinate has τ.
"""
function compute_tau(beat::Integer, depth::Integer)::Float64
    return Float64(beat) * phi_multiplier(depth)
end

"""
    is_jubilee(beat::Integer) -> Bool

Returns true if beat is at a Fibonacci jubilee interval.
"""
function is_jubilee(beat::Integer)::Bool
    return beat in FIB
end

"""
    fib_tier(depth::Integer) -> Int

Return the Fibonacci tier of a given depth (largest F(n) ≤ depth).
"""
function fib_tier(depth::Integer)::Int
    tier = 0
    for (i, f) in enumerate(FIB)
        f <= depth ? (tier = i) : break
    end
    return tier
end

end # module Phi
