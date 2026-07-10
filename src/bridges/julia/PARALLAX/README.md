# ⬡ PARALLAX Julia Model

**The sovereign organism's computation layer — written in Julia.**

This is NOT a TypeScript wrapper. This IS the model.

## Structure

```
PARALLAX/
├── Project.toml          # Julia package manifest
└── src/
    ├── PARALLAX.jl       # Main module (entry point)
    ├── Phi.jl            # Tier 0 Absolutes — constants, laws, helpers
    ├── Kuramoto.jl       # Coupled oscillator synchronization (RK4)
    ├── Organism.jl       # Full organism state machine (9 engines, 7 drives)
    ├── DiffEq.jl         # Phi-harmonic ODEs, Lotka-Volterra, treasury growth
    ├── Signals.jl        # Schumann resonance analysis, spectral φ-density
    ├── Quantum.jl        # Density matrix quantum simulation, entanglement
    ├── Treasury.jl       # φ-constrained capital optimization
    └── Swarm.jl          # 9 animal engine agents, swarm intelligence
```

## Installation

```julia
using Pkg
Pkg.develop(path="src/bridges/julia/PARALLAX")
```

Or from the Julia REPL:
```julia
] dev src/bridges/julia/PARALLAX
```

## Usage

```julia
using PARALLAX

# Create a sovereign organism at genesis
org = genesis()

# Run heartbeats
for _ in 1:100
    R = heartbeat!(org)
    println("Beat $(org.beat): R = $(round(R, digits=4))")
end

# Check if alive
println("Alive: $(is_alive(org))")
println("Proof depth: $(org.proof_depth)")
println("Treasury: $(org.treasury)")
```

### Kuramoto Oscillator Field

```julia
# Create a 9-oscillator field anchored to Schumann 7.83 Hz
field = KuramotoField(n=9, field_type=1, seed_freq=7.83)

# Run for 1000 steps
for _ in 1:1000
    R = step!(field)
end
println("Order parameter: $(order_parameter(field))")
```

### Phi-Harmonic Oscillator

```julia
# Solve d²x/dt² + φ⁻¹·dx/dt + φ·x = 0
osc = PhiOscillator()
times, states = solve_phi_ode(t_span=(0.0, 20.0), x0=[1.0, 0.0])
println("Final state: $(states[end])")
```

### Quantum Entanglement

```julia
# Create Bell state and measure
bell = create_bell_state(:phi_plus)
println("Purity: $(purity(bell))")
println("Entropy: $(von_neumann_entropy(bell))")

# Apply decoherence
for _ in 1:100
    decoherence_step!(bell, dt=0.01)
end
println("After decoherence — Purity: $(purity(bell))")
```

### Treasury Optimization

```julia
# Create optimizer with 10000 initial capital
opt = TreasuryOptimizer(10000.0)

# Run 144 beats (one jubilee cycle)
for _ in 1:144
    y = step!(opt)
end
println("Total yield: $(opt.total_yield)")
println("Proof depth: $(opt.proof_depth)")
optimize_allocation!(opt)
```

### Swarm Intelligence

```julia
# Create the 9-agent swarm
swarm = create_swarm()

# Inject stimuli and get collective responses
response = inject_stimulus!(swarm, :external, 0.8, 7.83)
println("Swarm coherence: $(swarm_coherence(swarm))")

# Collective decision
decision, confidence = collective_decision(swarm, [:attack, :defend, :observe])
println("Decision: $decision (confidence: $(round(confidence, digits=3)))")
```

## Architecture

The Julia model mirrors the organism's architecture:

| Julia Module | Organism Layer | Motoko Counterpart |
|---|---|---|
| `Phi` | Tier 0 Constants | `phi.mo` |
| `Kuramoto` | Synchronization | `quantum_ops.mo` |
| `Organism` | State Machine | `main.mo` (Brain) |
| `DiffEq` | Continuous Dynamics | — (new, Julia-native) |
| `Signals` | Sensory Input | `neuro_chem.mo` |
| `Quantum` | Entanglement Layer | `quantum_ops.mo` |
| `Treasury` | Economic Engine | `metals.mo` |
| `Swarm` | Animal Engines | `animals.mo` |

## Bridge Protocol

The Julia model communicates with the Motoko canister via `entangala_bridge.jl`:

1. Register as a worker with a domain specialization
2. Sync heartbeat every F(3)=2 organism beats (~1746ms)
3. Receive computation dispatches from the organism
4. Return results with φ-coherence signature + precision guarantee

## Requirements

- Julia 1.9+
- LinearAlgebra (stdlib)
- Statistics (stdlib)
- Random (stdlib)
- Optional: DifferentialEquations.jl, DSP.jl, Optim.jl, StaticArrays.jl

---

*The Architect of the Field: Alfredo Medina Hernandez*
