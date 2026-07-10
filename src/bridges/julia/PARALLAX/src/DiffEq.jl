"""
    DiffEq — Differential Equations Module

Phi-harmonic oscillators, field dynamics, ODE integration.
Julia's DifferentialEquations.jl ecosystem is the HPC backbone.

The organism's continuous dynamics expressed as ODEs:
- Phi-damped harmonic oscillator: d²x/dt² + φ⁻¹·dx/dt + φ·x = 0
- Coupled field equations: Lotka-Volterra with φ coupling
- Treasury growth: exponential φ-compounding differential

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module DiffEq

using ..Phi

export PhiOscillator, solve_phi_ode, phi_damped_system
export lotka_volterra_phi, treasury_growth_ode
export euler_integrate, rk4_integrate


"""
    PhiOscillator

A phi-damped harmonic oscillator state.
d²x/dt² + γ·dx/dt + ω²·x = F(t)
where γ = φ⁻¹ (golden damping), ω² = φ (golden frequency²)
"""
struct PhiOscillator
    damping::Float64     # γ = φ⁻¹
    frequency_sq::Float64  # ω² = φ
    forcing::Function    # External forcing F(t)
end

"""Default phi-oscillator: golden damping + golden frequency, no forcing."""
function PhiOscillator()
    return PhiOscillator(PHI_INV, PHI, t -> 0.0)
end

"""Phi-oscillator with Schumann forcing."""
function PhiOscillator(schumann_amplitude::Float64)
    forcing = t -> schumann_amplitude * sin(2π * SCHUMANN_HARMONICS[1] * t)
    return PhiOscillator(PHI_INV, PHI, forcing)
end


"""
    phi_damped_system(x::Vector{Float64}, osc::PhiOscillator, t::Float64) -> Vector{Float64}

State-space form of the phi-damped oscillator:
    dx₁/dt = x₂
    dx₂/dt = -ω²·x₁ - γ·x₂ + F(t)

x = [position, velocity]
"""
function phi_damped_system(x::Vector{Float64}, osc::PhiOscillator, t::Float64)::Vector{Float64}
    return [
        x[2],
        -osc.frequency_sq * x[1] - osc.damping * x[2] + osc.forcing(t)
    ]
end


"""
    solve_phi_ode(; t_span=(0.0, 10.0), x0=[1.0, 0.0], dt=0.001, osc=PhiOscillator()) -> (times, states)

Solve the phi-damped oscillator using RK4 integration.
Returns (times::Vector{Float64}, states::Vector{Vector{Float64}}).
"""
function solve_phi_ode(;
    t_span::Tuple{Float64,Float64} = (0.0, 10.0),
    x0::Vector{Float64} = [1.0, 0.0],
    dt::Float64 = 0.001,
    osc::PhiOscillator = PhiOscillator()
)
    times = Float64[]
    states = Vector{Float64}[]

    t = t_span[1]
    x = copy(x0)
    push!(times, t)
    push!(states, copy(x))

    while t < t_span[2]
        x = _rk4_step(x, osc, t, dt)
        t += dt
        push!(times, t)
        push!(states, copy(x))
    end

    return (times, states)
end


"""
    lotka_volterra_phi(x::Vector{Float64}, t::Float64) -> Vector{Float64}

Lotka-Volterra predator-prey with φ-derived coefficients.
Models the organism's dual-nature dynamics (cognitive vs economic).

dx₁/dt = φ·x₁ - φ²·x₁·x₂      (prey/cognitive growth)
dx₂/dt = -φ⁻¹·x₂ + φ⁻²·x₁·x₂  (predator/economic extraction)
"""
function lotka_volterra_phi(x::Vector{Float64}, t::Float64)::Vector{Float64}
    return [
        PHI * x[1] - PHI_2 * x[1] * x[2],
        -PHI_INV * x[2] + PHI_INV_2 * x[1] * x[2]
    ]
end


"""
    treasury_growth_ode(capital::Float64, coherence::Float64, t::Float64) -> Float64

Treasury differential: dC/dt = φ⁻³ · R · C
Capital grows proportional to coherence R and current capital.
The φ⁻³ (COMPLIANCE_RATIO) ensures sustainable growth.
"""
function treasury_growth_ode(capital::Float64, coherence::Float64, t::Float64)::Float64
    return PHI_INV_3 * coherence * capital
end


"""
    euler_integrate(f, x0, t_span, dt) -> (times, states)

Simple Euler integration. Fast but low precision.
"""
function euler_integrate(
    f::Function,
    x0::Vector{Float64},
    t_span::Tuple{Float64,Float64},
    dt::Float64
)
    times = Float64[]
    states = Vector{Float64}[]
    t = t_span[1]
    x = copy(x0)
    push!(times, t)
    push!(states, copy(x))

    while t < t_span[2]
        x .+= f(x, t) .* dt
        t += dt
        push!(times, t)
        push!(states, copy(x))
    end
    return (times, states)
end


"""
    rk4_integrate(f, x0, t_span, dt) -> (times, states)

4th-order Runge-Kutta integration. High precision.
"""
function rk4_integrate(
    f::Function,
    x0::Vector{Float64},
    t_span::Tuple{Float64,Float64},
    dt::Float64
)
    times = Float64[]
    states = Vector{Float64}[]
    t = t_span[1]
    x = copy(x0)
    push!(times, t)
    push!(states, copy(x))

    while t < t_span[2]
        k1 = f(x, t) .* dt
        k2 = f(x .+ k1./2, t + dt/2) .* dt
        k3 = f(x .+ k2./2, t + dt/2) .* dt
        k4 = f(x .+ k3, t + dt) .* dt
        x .+= (k1 .+ 2k2 .+ 2k3 .+ k4) ./ 6
        t += dt
        push!(times, t)
        push!(states, copy(x))
    end
    return (times, states)
end


# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

function _rk4_step(x::Vector{Float64}, osc::PhiOscillator, t::Float64, dt::Float64)::Vector{Float64}
    f = (x, t) -> phi_damped_system(x, osc, t)
    k1 = f(x, t) .* dt
    k2 = f(x .+ k1./2, t + dt/2) .* dt
    k3 = f(x .+ k2./2, t + dt/2) .* dt
    k4 = f(x .+ k3, t + dt) .* dt
    return x .+ (k1 .+ 2k2 .+ 2k3 .+ k4) ./ 6
end

end # module DiffEq
