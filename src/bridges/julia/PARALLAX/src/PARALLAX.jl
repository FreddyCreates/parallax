"""
    PARALLAX — The Julia Model

PARALLAX sovereign organism computation layer written in Julia.
This is NOT a TypeScript wrapper. This IS the model.

Julia's multiple dispatch IS the organism's multiple-path coherence.
Julia's type system IS the organism's type sovereignty.

Modules:
- `Phi`          — The 20 Absolutes. Constants. Laws. Zero drift.
- `Kuramoto`     — Coupled oscillator synchronization engine
- `Organism`     — Full organism state machine (heartbeat, drives, coherence)
- `DiffEq`       — Differential equations: phi-harmonic oscillators, field dynamics
- `Signals`      — Signal processing: Schumann resonance, frequency analysis
- `Quantum`      — Quantum state simulation: entanglement, decoherence, measurement
- `Treasury`     — Phi-constrained optimization: capital allocation, yield
- `Swarm`        — Agent-based modeling: animal engines, swarm intelligence

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module PARALLAX

include("Phi.jl")
include("Kuramoto.jl")
include("Organism.jl")
include("DiffEq.jl")
include("Signals.jl")
include("Quantum.jl")
include("Treasury.jl")
include("Swarm.jl")

using .Phi
using .Kuramoto
using .Organism
using .DiffEq
using .Signals
using .Quantum
using .Treasury
using .Swarm

# Re-export key types and functions
export PHI, PHI_INV, PHI_INV_2, PHI_INV_3, PHI_INV_5
export FIB, SCHUMANN_HARMONICS, HEARTBEAT_MS, S0
export phi_coherence, phi_multiplier, compute_tau

export KuramotoField, step!, order_parameter, phase_velocity
export OrganismState, heartbeat!, genesis, is_alive, global_coherence

export PhiOscillator, solve_phi_ode, phi_damped_system
export SchumannAnalyzer, analyze_coherence, spectral_phi_density
export QuantumState, entangle!, measure!, decoherence_step!
export TreasuryOptimizer, optimize_allocation!, phi_yield
export SwarmEngine, dispatch_agents!, swarm_coherence

end # module PARALLAX
