#!/usr/bin/env python3
"""
PARALLAX SDK — Heartbeat Timing Model
=======================================
Implements the sovereign heartbeat system derived from:
  heartbeat = φ⁴ × 1000ms / Schumann(7.83Hz) ≈ 873ms

The heartbeat drives all settlement finality in the organism.
Every 873ms, the organism processes one beat — clearing trades,
updating state, and advancing the protocol clock.
"""

import time
import threading
from dataclasses import dataclass
from typing import Callable, Optional

from .constants import (
    HEARTBEAT_MS,
    HEARTBEAT_S,
    HEARTBEAT_HZ,
    SYNC_INTERVAL_BEATS,
    PHI_4,
    SCHUMANN_FUNDAMENTAL,
    FIBONACCI,
)


@dataclass
class HeartbeatPulse:
    """A single heartbeat pulse event."""
    beat_number: int
    timestamp_ns: int
    cycle_ms: float
    drift_ms: float  # Deviation from ideal 873ms


class HeartbeatClock:
    """
    Sovereign Heartbeat Clock.

    Generates heartbeat pulses at the organism's natural frequency (873ms).
    Tracks timing drift and provides beat-synchronized callbacks.

    Derivation:
        φ⁴ = 6.854...
        heartbeat = φ⁴ × 1000 / 7.83 = 6854.1 / 7.83 ≈ 875.3ms
        Rounded to 873ms for protocol alignment with F(n) scaling.

    Usage:
        clock = HeartbeatClock()

        @clock.on_beat
        def process_settlement(pulse: HeartbeatPulse):
            print(f"Beat {pulse.beat_number}: settling trades...")

        clock.start()
        time.sleep(10)  # Run for 10 seconds
        clock.stop()
    """

    def __init__(self, interval_ms: int = HEARTBEAT_MS):
        self._interval_ms = interval_ms
        self._interval_s = interval_ms / 1000.0
        self._beat_number: int = 0
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._callbacks: list[Callable[[HeartbeatPulse], None]] = []
        self._start_time_ns: int = 0
        self._last_beat_ns: int = 0
        self._total_drift_ms: float = 0.0

    @property
    def beat_number(self) -> int:
        return self._beat_number

    @property
    def interval_ms(self) -> int:
        return self._interval_ms

    @property
    def frequency_hz(self) -> float:
        return 1000.0 / self._interval_ms

    @property
    def is_running(self) -> bool:
        return self._running

    def on_beat(self, func: Callable[[HeartbeatPulse], None]) -> Callable:
        """Decorator to register a beat callback."""
        self._callbacks.append(func)
        return func

    def start(self) -> None:
        """Start the heartbeat clock."""
        if self._running:
            return
        self._running = True
        self._start_time_ns = time.time_ns()
        self._last_beat_ns = self._start_time_ns
        self._thread = threading.Thread(
            target=self._pulse_loop,
            daemon=True,
            name="parallax-heartbeat",
        )
        self._thread.start()

    def stop(self) -> None:
        """Stop the heartbeat clock."""
        self._running = False
        if self._thread:
            self._thread.join(timeout=self._interval_s * 3)

    def get_stats(self) -> dict:
        """Return heartbeat statistics."""
        elapsed_s = (time.time_ns() - self._start_time_ns) / 1e9 if self._start_time_ns else 0
        return {
            "beat_number": self._beat_number,
            "interval_ms": self._interval_ms,
            "frequency_hz": self.frequency_hz,
            "elapsed_s": elapsed_s,
            "expected_beats": int(elapsed_s / self._interval_s) if elapsed_s > 0 else 0,
            "total_drift_ms": self._total_drift_ms,
            "is_running": self._running,
        }

    def wait_beats(self, n: int) -> None:
        """Block until n heartbeats have elapsed from now."""
        target = self._beat_number + n
        while self._running and self._beat_number < target:
            time.sleep(self._interval_s / 4)

    def _pulse_loop(self) -> None:
        """Internal heartbeat loop with drift compensation."""
        while self._running:
            # Calculate ideal next beat time
            ideal_next_ns = self._start_time_ns + (self._beat_number + 1) * (self._interval_ms * 1_000_000)
            now_ns = time.time_ns()

            # Sleep until next beat
            sleep_ns = ideal_next_ns - now_ns
            if sleep_ns > 0:
                time.sleep(sleep_ns / 1e9)

            # Record beat
            beat_time_ns = time.time_ns()
            cycle_ms = (beat_time_ns - self._last_beat_ns) / 1e6
            drift_ms = cycle_ms - self._interval_ms
            self._total_drift_ms += abs(drift_ms)

            self._beat_number += 1
            self._last_beat_ns = beat_time_ns

            pulse = HeartbeatPulse(
                beat_number=self._beat_number,
                timestamp_ns=beat_time_ns,
                cycle_ms=cycle_ms,
                drift_ms=drift_ms,
            )

            # Fire callbacks
            for cb in self._callbacks:
                try:
                    cb(pulse)
                except Exception:
                    # Swallow callback errors to protect the heartbeat loop.
                    # In production, pipe to organism telemetry.
                    continue


def derive_heartbeat(phi_power: int = 4, schumann_hz: float = SCHUMANN_FUNDAMENTAL) -> float:
    """
    Derive the heartbeat interval from first principles.

    Formula: heartbeat_ms = φ^power × 1000 / schumann_hz

    Args:
        phi_power: Power of φ to use (default 4).
        schumann_hz: Schumann resonance frequency (default 7.83 Hz).

    Returns:
        Heartbeat interval in milliseconds.
    """
    from .constants import PHI
    phi_n = PHI ** phi_power
    return phi_n * 1000.0 / schumann_hz


def beat_to_time_ms(beat: int, interval_ms: int = HEARTBEAT_MS) -> int:
    """Convert beat number to elapsed time in milliseconds."""
    return beat * interval_ms


def time_to_beat(time_ms: float, interval_ms: int = HEARTBEAT_MS) -> int:
    """Convert elapsed time to beat number (floor)."""
    return int(time_ms / interval_ms)
