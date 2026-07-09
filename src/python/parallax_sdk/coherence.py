#!/usr/bin/env python3
"""
PARALLAX SDK — Kuramoto Coherence Gate
========================================
Implements the Kuramoto order parameter for phase synchronization.
The organism uses coherence gating to ensure only synchronized
computations proceed — R ≥ φ⁻¹ (0.618) required.

Based on the Kuramoto model of coupled oscillators:
  R(t) = |1/N Σ exp(iθⱼ(t))|

Reference: Kuramoto, Y. (1984). Chemical Oscillations, Waves, and Turbulence.
"""

import math
from dataclasses import dataclass, field
from typing import Optional

from .constants import (
    PHI,
    PHI_INV,
    PHI_INV_2,
    COHERENCE_GATE,
    SCHUMANN_FUNDAMENTAL,
    HEARTBEAT_S,
)


@dataclass
class Oscillator:
    """A single coupled oscillator in the Kuramoto ensemble."""
    phase: float  # θ ∈ [0, 2π)
    natural_freq: float  # ω (natural frequency in rad/s)
    coupling: float = PHI_INV  # K (coupling strength)
    label: str = ""


@dataclass
class CoherenceResult:
    """Result of a coherence measurement."""
    R: float  # Order parameter magnitude [0, 1]
    psi: float  # Mean phase angle
    passed_gate: bool  # Whether R ≥ COHERENCE_GATE
    oscillator_count: int
    phase_variance: float


class KuramotoCoherenceGate:
    """
    Kuramoto Coherence Gate for PARALLAX.

    The gate allows operations to proceed only when the ensemble
    of oscillators achieves sufficient phase synchronization (R ≥ 0.618).

    Usage:
        gate = KuramotoCoherenceGate()
        gate.add_oscillator(phase=0.0, freq=7.83)
        gate.add_oscillator(phase=0.1, freq=7.83)
        gate.add_oscillator(phase=0.05, freq=7.83)

        result = gate.measure()
        if result.passed_gate:
            # Proceed with operation
            ...
    """

    def __init__(self, threshold: float = COHERENCE_GATE):
        self._oscillators: list[Oscillator] = []
        self._threshold = threshold
        self._time: float = 0.0

    @property
    def threshold(self) -> float:
        return self._threshold

    @property
    def oscillator_count(self) -> int:
        return len(self._oscillators)

    def add_oscillator(
        self,
        phase: float,
        freq: float = SCHUMANN_FUNDAMENTAL,
        coupling: float = PHI_INV,
        label: str = "",
    ) -> None:
        """Add an oscillator to the ensemble."""
        # Normalize phase to [0, 2π)
        phase = phase % (2.0 * math.pi)
        self._oscillators.append(
            Oscillator(
                phase=phase,
                natural_freq=freq * 2.0 * math.pi,  # Convert Hz to rad/s
                coupling=coupling,
                label=label,
            )
        )

    def remove_oscillator(self, index: int) -> None:
        """Remove oscillator by index."""
        if 0 <= index < len(self._oscillators):
            self._oscillators.pop(index)

    def measure(self) -> CoherenceResult:
        """
        Compute the Kuramoto order parameter R.

        R = |1/N Σⱼ exp(iθⱼ)|

        Returns CoherenceResult with gate pass/fail.
        """
        N = len(self._oscillators)
        if N == 0:
            return CoherenceResult(
                R=0.0, psi=0.0, passed_gate=False,
                oscillator_count=0, phase_variance=0.0,
            )

        # Compute complex order parameter
        sum_cos = sum(math.cos(osc.phase) for osc in self._oscillators)
        sum_sin = sum(math.sin(osc.phase) for osc in self._oscillators)

        R = math.sqrt(sum_cos**2 + sum_sin**2) / N
        psi = math.atan2(sum_sin, sum_cos)

        # Phase variance (circular variance)
        phase_var = 1.0 - R

        return CoherenceResult(
            R=R,
            psi=psi,
            passed_gate=(R >= self._threshold),
            oscillator_count=N,
            phase_variance=phase_var,
        )

    def step(self, dt: Optional[float] = None) -> CoherenceResult:
        """
        Advance the Kuramoto system by one timestep.

        Uses the standard Kuramoto coupling:
          dθᵢ/dt = ωᵢ + (K/N) Σⱼ sin(θⱼ - θᵢ)

        Args:
            dt: Time step in seconds. Defaults to one heartbeat (0.873s).

        Returns:
            CoherenceResult after the step.
        """
        if dt is None:
            dt = HEARTBEAT_S

        N = len(self._oscillators)
        if N == 0:
            return self.measure()

        # Compute phase updates
        new_phases: list[float] = []
        for i, osc_i in enumerate(self._oscillators):
            # Sum coupling interactions
            coupling_sum = 0.0
            for j, osc_j in enumerate(self._oscillators):
                if i != j:
                    coupling_sum += math.sin(osc_j.phase - osc_i.phase)

            # Kuramoto equation
            dtheta = osc_i.natural_freq + (osc_i.coupling / N) * coupling_sum
            new_phase = (osc_i.phase + dtheta * dt) % (2.0 * math.pi)
            new_phases.append(new_phase)

        # Apply updates
        for i, osc in enumerate(self._oscillators):
            osc.phase = new_phases[i]

        self._time += dt
        return self.measure()

    def evolve(self, steps: int, dt: Optional[float] = None) -> list[CoherenceResult]:
        """
        Evolve the system for multiple steps, returning coherence at each step.
        """
        results = []
        for _ in range(steps):
            results.append(self.step(dt))
        return results

    def reset_phases(self, spread: float = math.pi) -> None:
        """
        Reset all oscillator phases with random spread around 0.

        Args:
            spread: Maximum phase deviation from 0 (in radians).
        """
        import random
        for osc in self._oscillators:
            osc.phase = random.uniform(-spread, spread) % (2.0 * math.pi)

    def get_phases(self) -> list[float]:
        """Return current phases of all oscillators."""
        return [osc.phase for osc in self._oscillators]

    def get_diagnostics(self) -> dict:
        """Return full diagnostic state."""
        result = self.measure()
        return {
            "R": result.R,
            "psi": result.psi,
            "passed_gate": result.passed_gate,
            "threshold": self._threshold,
            "oscillator_count": result.oscillator_count,
            "phase_variance": result.phase_variance,
            "time": self._time,
            "phases": self.get_phases(),
        }
