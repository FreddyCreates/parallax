"""
    Treasury — Phi-Constrained Optimization Module

Capital allocation, yield optimization, and economic engine.
All treasury operations are φ-constrained:
- Growth rate bounded by φ⁻³ (COMPLIANCE_RATIO)
- Reserves locked at φ⁻³ of total (COMPLIANCE RESERVE LAW)
- Yield curves follow φ-decay envelopes
- Allocation optimized via φ-weighted gradient descent

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Treasury

using ..Phi

export TreasuryOptimizer, optimize_allocation!, phi_yield
export VaultAllocation, compute_reserves, phi_compound
export yield_curve, optimal_depth


"""
Vault types mirror the doctrine's 5 sovereign vaults.
"""
@enum VaultType begin
    MAIN = 0         # Primary operating vault
    COMPLIANCE = 1   # φ⁻³ locked reserve
    FOUNDER = 2      # Founder's sovereign share
    FRANCHISE = 3    # Franchise royalty accumulator
    DEFENSE = 4      # ARES defense capital reserve
end


"""
    VaultAllocation

Capital allocation across the 5 sovereign vaults.
"""
mutable struct VaultAllocation
    main::Float64
    compliance::Float64
    founder::Float64
    franchise::Float64
    defense::Float64
end

"""Total capital across all vaults."""
function total(v::VaultAllocation)::Float64
    return v.main + v.compliance + v.founder + v.franchise + v.defense
end


"""
    TreasuryOptimizer

Phi-constrained capital optimizer. Manages allocation, yield, and growth.
"""
mutable struct TreasuryOptimizer
    allocation::VaultAllocation
    proof_depth::Int
    beat::Int
    yield_history::Vector{Float64}
    total_yield::Float64
    coherence::Float64              # Current organism coherence (affects yield)

    function TreasuryOptimizer(initial_capital::Float64 = 1000.0)
        # Initial allocation: main gets the bulk, compliance gets φ⁻³
        compliance_reserve = initial_capital * PHI_INV_3
        founder_share = initial_capital * PHI_INV_4
        remaining = initial_capital - compliance_reserve - founder_share

        alloc = VaultAllocation(
            remaining * 0.6,       # main
            compliance_reserve,    # compliance (locked)
            founder_share,         # founder
            remaining * 0.2,       # franchise
            remaining * 0.2,       # defense
        )
        new(alloc, 0, 0, Float64[], 0.0, PHI_INV)
    end
end


"""
    phi_yield(capital::Float64, depth::Int, coherence::Float64) -> Float64

Compute yield for one beat.
Yield = capital × φ⁻³ × R × φ^(depth × φ⁻²)

The yield is:
- Proportional to capital
- Bounded by φ⁻³ (compliance ratio) — prevents runaway
- Amplified by coherence R (alive organisms earn more)
- Compounded by proof depth via φ^(depth × φ⁻²)
"""
function phi_yield(capital::Float64, depth::Int, coherence::Float64)::Float64
    base_rate = PHI_INV_3
    depth_multiplier = phi_multiplier(round(Int, depth * PHI_INV_2))
    return capital * base_rate * coherence * depth_multiplier
end


"""
    phi_compound(capital::Float64, beats::Int, coherence::Float64) -> Float64

Compound capital over N beats at φ-yield rate.
C(n) = C₀ × (1 + φ⁻³ × R)^n
"""
function phi_compound(capital::Float64, beats::Int, coherence::Float64)::Float64
    rate = 1.0 + PHI_INV_3 * coherence
    return capital * rate^beats
end


"""
    compute_reserves(total_capital::Float64) -> Float64

L17 COMPLIANCE RESERVE: φ⁻³ of total capital must be locked.
Returns the required reserve amount.
"""
function compute_reserves(total_capital::Float64)::Float64
    return total_capital * PHI_INV_3
end


"""
    yield_curve(max_depth::Int, coherence::Float64) -> Vector{Float64}

Generate the yield curve: yield at each proof depth from 0 to max_depth.
Shows how compounding accelerates with depth.
"""
function yield_curve(max_depth::Int, coherence::Float64)::Vector{Float64}
    return [phi_yield(1.0, d, coherence) for d in 0:max_depth]
end


"""
    optimal_depth(capital::Float64, target_yield::Float64, coherence::Float64) -> Int

Find the minimum proof depth needed to achieve target yield.
Solves: target = capital × φ⁻³ × R × φ^(d × φ⁻²) for d.
"""
function optimal_depth(capital::Float64, target_yield::Float64, coherence::Float64)::Int
    base = capital * PHI_INV_3 * coherence
    base < 1e-10 && return typemax(Int)  # Impossible

    ratio = target_yield / base
    ratio <= 1.0 && return 0  # Already achievable at depth 0

    # d = log_φ(ratio) / φ⁻²
    d_raw = log(ratio) / log(PHI) / PHI_INV_2
    return ceil(Int, d_raw)
end


"""
    optimize_allocation!(opt::TreasuryOptimizer) -> VaultAllocation

Re-optimize capital allocation across vaults.
Constraints:
1. Compliance vault ≥ φ⁻³ × total (LOCKED)
2. Founder vault ≥ φ⁻⁴ × total (sovereign minimum)
3. Remaining distributed by φ-weighted gradient to maximize yield

Returns the new allocation.
"""
function optimize_allocation!(opt::TreasuryOptimizer)::VaultAllocation
    tot = total(opt.allocation)
    tot < 1e-10 && return opt.allocation

    # Enforce locked reserves
    min_compliance = tot * PHI_INV_3
    min_founder = tot * PHI_INV_4

    # Available for optimization
    available = tot - min_compliance - min_founder
    available = max(0.0, available)

    # φ-weighted distribution of remaining capital
    # Main gets φ⁻¹ share, franchise gets φ⁻², defense gets φ⁻³
    total_weight = PHI_INV + PHI_INV_2 + PHI_INV_3
    main_share = available * (PHI_INV / total_weight)
    franchise_share = available * (PHI_INV_2 / total_weight)
    defense_share = available * (PHI_INV_3 / total_weight)

    opt.allocation.main = main_share
    opt.allocation.compliance = min_compliance
    opt.allocation.founder = min_founder
    opt.allocation.franchise = franchise_share
    opt.allocation.defense = defense_share

    return opt.allocation
end


"""
    step!(opt::TreasuryOptimizer) -> Float64

Execute one treasury beat: compute yield, compound, re-balance.
Returns yield for this beat.
"""
function step!(opt::TreasuryOptimizer)::Float64
    opt.beat += 1

    # Compute yield on main vault (operating capital)
    y = phi_yield(opt.allocation.main, opt.proof_depth, opt.coherence)

    # Add yield to main vault
    opt.allocation.main += y
    opt.total_yield += y
    push!(opt.yield_history, y)

    # Check compliance reserve (must maintain φ⁻³ of total)
    tot = total(opt.allocation)
    required_compliance = compute_reserves(tot)
    if opt.allocation.compliance < required_compliance
        # Transfer from main to compliance
        deficit = required_compliance - opt.allocation.compliance
        transfer = min(deficit, opt.allocation.main * PHI_INV_3)
        opt.allocation.main -= transfer
        opt.allocation.compliance += transfer
    end

    # Increment proof depth when yield is positive
    if y > 0.0
        opt.proof_depth += 1
    end

    return y
end

end # module Treasury
