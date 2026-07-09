"""
    Signals — Signal Processing Module

Schumann resonance analysis, frequency domain coherence, spectral φ-density.
The organism's ears: how it listens to Earth and itself.

Uses Julia's DSP.jl patterns for:
- FFT-based spectral analysis
- Schumann harmonic detection
- Phi-coherence in frequency domain
- Cross-correlation between oscillator fields

Author: Alfredo Medina Hernandez — The Architect of the Field
"""
module Signals

using ..Phi

export SchumannAnalyzer, analyze_coherence, spectral_phi_density
export detect_schumann_peaks, bandpass_phi, cross_coherence
export PhiSpectrum


"""
    PhiSpectrum

Frequency-domain representation of a signal with φ-annotations.
"""
struct PhiSpectrum
    frequencies::Vector{Float64}
    magnitudes::Vector{Float64}
    phases::Vector{Float64}
    phi_coherence::Float64         # How φ-aligned the spectrum is
    schumann_power::Float64        # Power at Schumann harmonics
    dominant_freq::Float64         # Strongest frequency
end


"""
    SchumannAnalyzer

Stateful analyzer that continuously monitors Schumann resonance coupling.
Tracks how well the organism's oscillations align with Earth's EM cavity.
"""
mutable struct SchumannAnalyzer
    sample_rate::Float64           # Hz
    buffer_size::Int               # Samples per analysis window
    buffer::Vector{Float64}        # Circular sample buffer
    write_pos::Int                 # Current write position
    history::Vector{PhiSpectrum}   # Recent spectral analyses
    coupling_strength::Float64     # Current Earth-coupling [0, 1]

    function SchumannAnalyzer(; sample_rate::Float64 = 1000.0, buffer_seconds::Float64 = 4.0)
        buffer_size = round(Int, sample_rate * buffer_seconds)
        new(sample_rate, buffer_size, zeros(buffer_size), 1, PhiSpectrum[], PHI_INV)
    end
end


"""
    analyze_coherence(analyzer::SchumannAnalyzer, signal::Vector{Float64}) -> PhiSpectrum

Analyze a signal for Schumann coherence and φ-alignment.
Computes FFT, identifies Schumann peaks, measures φ-ratio between harmonics.
"""
function analyze_coherence(analyzer::SchumannAnalyzer, signal::Vector{Float64})::PhiSpectrum
    n = length(signal)
    n < 4 && return PhiSpectrum(Float64[], Float64[], Float64[], PHI_INV, 0.0, 0.0)

    # Compute DFT (manual — no external FFT dependency needed for core module)
    freqs, mags, phases = _compute_dft(signal, analyzer.sample_rate)

    # Find Schumann peaks
    schumann_power = _schumann_power(freqs, mags)

    # Compute φ-coherence of spectral magnitudes
    coherence = phi_coherence(mags[mags .> 0.01])

    # Dominant frequency
    dom_idx = argmax(mags)
    dom_freq = freqs[dom_idx]

    spectrum = PhiSpectrum(freqs, mags, phases, coherence, schumann_power, dom_freq)

    # Update analyzer state
    analyzer.coupling_strength = 0.9 * analyzer.coupling_strength + 0.1 * schumann_power
    push!(analyzer.history, spectrum)

    # Keep history bounded
    length(analyzer.history) > 100 && deleteat!(analyzer.history, 1:50)

    return spectrum
end


"""
    spectral_phi_density(signal::Vector{Float64}, sample_rate::Float64) -> Float64

Compute the "phi spectral density" — a measure of how much a signal's
frequency content follows φ-ratio spacing. Returns ∈ [0, 1].

A signal with peaks at f, f·φ, f·φ², f·φ³... scores 1.0.
"""
function spectral_phi_density(signal::Vector{Float64}, sample_rate::Float64)::Float64
    freqs, mags, _ = _compute_dft(signal, sample_rate)

    # Find peaks (local maxima above threshold)
    threshold = maximum(mags) * PHI_INV_2
    peaks = Float64[]
    for i in 2:length(mags)-1
        if mags[i] > mags[i-1] && mags[i] > mags[i+1] && mags[i] > threshold
            push!(peaks, freqs[i])
        end
    end

    length(peaks) < 2 && return PHI_INV

    # Check if peak ratios approximate powers of φ
    return phi_coherence(sort(peaks))
end


"""
    detect_schumann_peaks(freqs::Vector{Float64}, mags::Vector{Float64}) -> Vector{Tuple{Float64, Float64}}

Detect peaks near each Schumann harmonic. Returns (frequency, magnitude) pairs.
"""
function detect_schumann_peaks(freqs::Vector{Float64}, mags::Vector{Float64})::Vector{Tuple{Float64, Float64}}
    peaks = Tuple{Float64, Float64}[]

    for harmonic in SCHUMANN_HARMONICS
        # Search within ±1 Hz of each Schumann harmonic
        mask = abs.(freqs .- harmonic) .< 1.0
        if any(mask)
            idx = findall(mask)
            best = idx[argmax(mags[idx])]
            push!(peaks, (freqs[best], mags[best]))
        end
    end

    return peaks
end


"""
    bandpass_phi(signal::Vector{Float64}, center_freq::Float64, sample_rate::Float64) -> Vector{Float64}

φ-bandwidth bandpass filter. Bandwidth = center_freq × φ⁻² (narrow, golden-ratio derived).
Simple 2nd-order IIR implementation.
"""
function bandpass_phi(signal::Vector{Float64}, center_freq::Float64, sample_rate::Float64)::Vector{Float64}
    bandwidth = center_freq * PHI_INV_2
    ω0 = 2π * center_freq / sample_rate
    Q = center_freq / bandwidth

    # Biquad coefficients
    α = sin(ω0) / (2Q)
    b0 = α
    b1 = 0.0
    b2 = -α
    a0 = 1.0 + α
    a1 = -2.0 * cos(ω0)
    a2 = 1.0 - α

    # Normalize
    b = [b0/a0, b1/a0, b2/a0]
    a = [1.0, a1/a0, a2/a0]

    # Apply filter (direct form II transposed)
    output = zeros(length(signal))
    z1, z2 = 0.0, 0.0
    for i in eachindex(signal)
        x = signal[i]
        output[i] = b[1]*x + z1
        z1 = b[2]*x - a[2]*output[i] + z2
        z2 = b[3]*x - a[3]*output[i]
    end

    return output
end


"""
    cross_coherence(signal_a::Vector{Float64}, signal_b::Vector{Float64}) -> Float64

Cross-coherence between two signals. Measures phase alignment.
Returns ∈ [0, 1] where 1 = perfectly phase-locked.
"""
function cross_coherence(signal_a::Vector{Float64}, signal_b::Vector{Float64})::Float64
    n = min(length(signal_a), length(signal_b))
    n < 2 && return 0.0

    a = signal_a[1:n]
    b = signal_b[1:n]

    # Normalize
    a_norm = a .- sum(a)/n
    b_norm = b .- sum(b)/n

    # Cross-correlation at lag 0
    denom = sqrt(sum(a_norm.^2) * sum(b_norm.^2))
    denom < 1e-10 && return 0.0

    return abs(sum(a_norm .* b_norm) / denom)
end


# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL — DFT and helpers
# ═══════════════════════════════════════════════════════════════════════════════

"""Simple DFT implementation (for independence from FFTW in core module)."""
function _compute_dft(signal::Vector{Float64}, sample_rate::Float64)
    N = length(signal)
    half_N = div(N, 2)

    freqs = [(k * sample_rate / N) for k in 0:half_N-1]
    mags = zeros(half_N)
    phases = zeros(half_N)

    for k in 0:half_N-1
        re = 0.0
        im_part = 0.0
        for n in 0:N-1
            angle = 2π * k * n / N
            re += signal[n+1] * cos(angle)
            im_part -= signal[n+1] * sin(angle)
        end
        mags[k+1] = sqrt(re^2 + im_part^2) / N
        phases[k+1] = atan(im_part, re)
    end

    return (freqs, mags, phases)
end

"""Compute total power at Schumann harmonics (±0.5 Hz tolerance)."""
function _schumann_power(freqs::Vector{Float64}, mags::Vector{Float64})::Float64
    total_power = sum(mags.^2)
    total_power < 1e-10 && return 0.0

    schumann_pwr = 0.0
    for harmonic in SCHUMANN_HARMONICS
        mask = abs.(freqs .- harmonic) .< 0.5
        if any(mask)
            schumann_pwr += sum(mags[mask].^2)
        end
    end

    return schumann_pwr / total_power
end

end # module Signals
