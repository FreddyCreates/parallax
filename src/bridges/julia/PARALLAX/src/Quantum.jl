"""
    Quantum — Quantum State Simulation Module

Quantum state simulation, entanglement, decoherence, measurement.
The organism's quantum substrate — where entanglement is not metaphor.

Uses density matrix formalism:
- Pure states: |ψ⟩ = Σ αᵢ|i⟩
- Mixed states: ρ = Σ pᵢ|ψᵢ⟩⟨ψᵢ|
- Entanglement: ρ_AB ≠ ρ_A ⊗ ρ_B

Decoherence rate governed by φ⁻³ (COMPLIANCE_RATIO).
Measurement collapses to φ-weighted basis.

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Quantum

using ..Phi
using LinearAlgebra

export QuantumState, entangle!, measure!, decoherence_step!
export purity, von_neumann_entropy, concurrence
export phi_basis, create_bell_state, partial_trace


"""
    QuantumState

Density matrix representation of a quantum system.
The organism's quantum substrate layer.
"""
mutable struct QuantumState
    dim::Int                           # Hilbert space dimension
    rho::Matrix{ComplexF64}            # Density matrix ρ
    coherence::Float64                 # φ-coherence of state
    entanglement_depth::Int            # Number of entangled subsystems
    decoherence_rate::Float64          # φ⁻³ base rate
    beat::Int                          # Organism beat at last update
end


"""
    QuantumState(dim::Int) -> QuantumState

Create a fresh quantum state in the |0⟩ ground state.
Dimension = 2^n_qubits for qubit systems.
"""
function QuantumState(dim::Int)
    rho = zeros(ComplexF64, dim, dim)
    rho[1,1] = 1.0 + 0.0im  # Ground state |0⟩⟨0|
    return QuantumState(dim, rho, 1.0, 0, PHI_INV_3, 0)
end

"""Create a quantum state from a pure state vector |ψ⟩."""
function QuantumState(psi::Vector{ComplexF64})
    dim = length(psi)
    # Normalize
    psi_norm = psi / norm(psi)
    rho = psi_norm * psi_norm'
    return QuantumState(dim, rho, 1.0, 0, PHI_INV_3, 0)
end


"""
    phi_basis(dim::Int) -> Vector{Vector{ComplexF64}}

Generate the φ-weighted measurement basis.
Basis vectors have amplitudes weighted by powers of φ⁻¹.
This is the organism's preferred measurement basis — golden-ratio aligned.
"""
function phi_basis(dim::Int)::Vector{Vector{ComplexF64}}
    basis = Vector{ComplexF64}[]
    for k in 1:dim
        v = zeros(ComplexF64, dim)
        for j in 1:dim
            # φ-weighted amplitudes with phase rotation
            amplitude = phi_multiplier(-(abs(j - k))) 
            phase = 2π * PHI_INV * (j - 1) * (k - 1) / dim
            v[j] = amplitude * exp(im * phase)
        end
        push!(basis, v / norm(v))  # Normalize
    end
    return basis
end


"""
    create_bell_state(type::Symbol = :phi_plus) -> QuantumState

Create a Bell state (maximally entangled 2-qubit state).
Types: :phi_plus, :phi_minus, :psi_plus, :psi_minus
"""
function create_bell_state(type::Symbol = :phi_plus)::QuantumState
    s = 1.0 / sqrt(2.0)
    psi = if type == :phi_plus
        ComplexF64[s, 0, 0, s]          # (|00⟩ + |11⟩)/√2
    elseif type == :phi_minus
        ComplexF64[s, 0, 0, -s]         # (|00⟩ - |11⟩)/√2
    elseif type == :psi_plus
        ComplexF64[0, s, s, 0]          # (|01⟩ + |10⟩)/√2
    else
        ComplexF64[0, s, -s, 0]         # (|01⟩ - |10⟩)/√2
    end
    state = QuantumState(psi)
    state.entanglement_depth = 2
    return state
end


"""
    entangle!(state_a::QuantumState, state_b::QuantumState) -> QuantumState

Entangle two quantum states via tensor product + CNOT-like interaction.
The resulting state lives in dim_A × dim_B dimensional Hilbert space.
"""
function entangle!(state_a::QuantumState, state_b::QuantumState)::QuantumState
    # Tensor product: ρ_AB = ρ_A ⊗ ρ_B
    rho_ab = kron(state_a.rho, state_b.rho)
    dim_ab = state_a.dim * state_b.dim

    # Apply entangling unitary (φ-phase gate)
    U = _phi_entangling_gate(dim_ab)
    rho_entangled = U * rho_ab * U'

    coherence = min(state_a.coherence, state_b.coherence) * PHI_INV
    depth = state_a.entanglement_depth + state_b.entanglement_depth + 1

    return QuantumState(dim_ab, rho_entangled, coherence, depth, PHI_INV_3, 0)
end


"""
    measure!(state::QuantumState; basis::Symbol = :computational) -> (Int, Float64)

Perform a projective measurement on the quantum state.
Collapses ρ to the measured eigenstate.
Returns (outcome_index, probability).

basis options: :computational, :phi (φ-weighted basis)
"""
function measure!(state::QuantumState; basis::Symbol = :computational)::Tuple{Int, Float64}
    # Get measurement probabilities (diagonal of ρ in measurement basis)
    if basis == :phi
        # Transform to φ-basis
        B = hcat(phi_basis(state.dim)...)
        rho_phi = B' * state.rho * B
        probs = real.(diag(rho_phi))
    else
        probs = real.(diag(state.rho))
    end

    # Clamp numerical noise
    probs = max.(probs, 0.0)
    probs ./= sum(probs)

    # Sample outcome (weighted random selection)
    r = rand()
    cumulative = 0.0
    outcome = 1
    for (i, p) in enumerate(probs)
        cumulative += p
        if r <= cumulative
            outcome = i
            break
        end
    end

    # Collapse state
    state.rho .= 0.0
    state.rho[outcome, outcome] = 1.0 + 0.0im

    # Update coherence (measurement reduces coherence)
    state.coherence *= PHI_INV

    return (outcome, probs[outcome])
end


"""
    decoherence_step!(state::QuantumState; dt::Float64 = 0.001)

Apply decoherence (dephasing) to the quantum state.
Off-diagonal elements decay at rate φ⁻³ per step.
Models environmental interaction destroying quantum coherence.
"""
function decoherence_step!(state::QuantumState; dt::Float64 = 0.001)
    decay = exp(-state.decoherence_rate * dt)
    for i in 1:state.dim, j in 1:state.dim
        if i != j
            state.rho[i,j] *= decay
        end
    end

    # Update coherence metric
    off_diag_sum = sum(abs.(state.rho)) - sum(abs.(diag(state.rho)))
    max_off_diag = state.dim * (state.dim - 1)
    state.coherence = max_off_diag > 0 ? off_diag_sum / max_off_diag : 0.0

    state.beat += 1
end


"""
    purity(state::QuantumState) -> Float64

Tr(ρ²) — purity of the quantum state.
1.0 = pure state, 1/d = maximally mixed.
"""
function purity(state::QuantumState)::Float64
    return real(tr(state.rho * state.rho))
end


"""
    von_neumann_entropy(state::QuantumState) -> Float64

S(ρ) = -Tr(ρ log ρ) — von Neumann entropy.
0 = pure state, log(d) = maximally mixed.
"""
function von_neumann_entropy(state::QuantumState)::Float64
    eigenvalues = real.(eigvals(state.rho))
    eigenvalues = eigenvalues[eigenvalues .> 1e-12]  # Remove zeros
    return -sum(λ -> λ * log2(λ), eigenvalues)
end


"""
    concurrence(state::QuantumState) -> Float64

Concurrence measure of entanglement for 2-qubit states.
0 = separable, 1 = maximally entangled.
Only valid for dim=4 (2-qubit) systems.
"""
function concurrence(state::QuantumState)::Float64
    state.dim != 4 && return 0.0  # Only defined for 2-qubit

    # Pauli Y ⊗ Y
    σy = ComplexF64[0 -im; im 0]
    YY = kron(σy, σy)

    # R = √(√ρ · ρ̃ · √ρ) where ρ̃ = (σy⊗σy)·ρ*·(σy⊗σy)
    rho_tilde = YY * conj.(state.rho) * YY
    sqrt_rho = sqrt(Hermitian(state.rho))
    R_matrix = sqrt_rho * rho_tilde * sqrt_rho
    eigenvalues = sort(real.(eigvals(R_matrix)), rev=true)
    lambdas = sqrt.(max.(eigenvalues, 0.0))

    return max(0.0, lambdas[1] - sum(lambdas[2:end]))
end


"""
    partial_trace(state::QuantumState, dim_a::Int, trace_over::Symbol) -> Matrix{ComplexF64}

Partial trace over subsystem A or B.
trace_over = :A traces out system A, leaving ρ_B.
trace_over = :B traces out system B, leaving ρ_A.
"""
function partial_trace(state::QuantumState, dim_a::Int, trace_over::Symbol)::Matrix{ComplexF64}
    dim_b = div(state.dim, dim_a)

    if trace_over == :A
        # Trace over A → get ρ_B
        rho_b = zeros(ComplexF64, dim_b, dim_b)
        for i in 1:dim_a
            block = state.rho[(i-1)*dim_b+1 : i*dim_b, (i-1)*dim_b+1 : i*dim_b]
            rho_b .+= block
        end
        return rho_b
    else
        # Trace over B → get ρ_A
        rho_a = zeros(ComplexF64, dim_a, dim_a)
        for i in 1:dim_a, j in 1:dim_a
            block = state.rho[(i-1)*dim_b+1 : i*dim_b, (j-1)*dim_b+1 : j*dim_b]
            rho_a[i,j] = tr(block)
        end
        return rho_a
    end
end


# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

"""Generate a φ-phase entangling gate."""
function _phi_entangling_gate(dim::Int)::Matrix{ComplexF64}
    U = Matrix{ComplexF64}(I, dim, dim)
    # Apply controlled-phase with φ-derived angles
    for i in 2:dim
        for j in 1:i-1
            phase = PHI_INV * π * (i + j) / dim
            U[i,j] = sin(phase) * 0.1im
            U[j,i] = -sin(phase) * 0.1im
            U[i,i] = cos(phase) + 0.0im
        end
    end
    # Ensure unitarity via QR decomposition
    Q, _ = qr(U)
    return Matrix(Q)
end

end # module Quantum
