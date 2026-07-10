"""Signal Aggregator — Combines signals from all strategies.

Weighted aggregation with conflict resolution and confidence scoring.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class AggregatedSignal:
    symbol: str
    direction: str  # "long", "short", "flat"
    strength: float  # 0-1
    confidence: float
    sources: list[str]
    conflicts: int
    recommended_size: float
    stop_loss_pct: float
    take_profit_pct: float


@dataclass
class SignalSource:
    name: str
    direction: str
    strength: float
    confidence: float
    weight: float = 1.0


class SignalAggregator:
    """Aggregates trading signals from multiple strategies."""

    def __init__(
        self,
        min_agreement: float = 0.5,
        min_confidence: float = 0.4,
        max_position_pct: float = 0.05,
    ) -> None:
        self.min_agreement = min_agreement
        self.min_confidence = min_confidence
        self.max_position_pct = max_position_pct

    def aggregate(
        self,
        symbol: str,
        signals: list[SignalSource],
        volatility: float = 0.02,
    ) -> AggregatedSignal:
        """Aggregate multiple signals into unified trading decision."""
        if not signals:
            return AggregatedSignal(
                symbol=symbol, direction="flat", strength=0.0,
                confidence=0.0, sources=[], conflicts=0,
                recommended_size=0.0, stop_loss_pct=0.0, take_profit_pct=0.0,
            )

        # Count directional votes
        long_weight = sum(
            s.strength * s.confidence * s.weight
            for s in signals if s.direction == "long"
        )
        short_weight = sum(
            s.strength * s.confidence * s.weight
            for s in signals if s.direction == "short"
        )
        total_weight = long_weight + short_weight

        # Conflicts = signals disagreeing on direction
        directions = set(s.direction for s in signals if s.direction != "flat")
        conflicts = len(directions) - 1 if len(directions) > 1 else 0

        # Net direction
        if total_weight == 0:
            direction = "flat"
            strength = 0.0
        elif long_weight > short_weight:
            direction = "long"
            strength = (long_weight - short_weight) / total_weight
        else:
            direction = "short"
            strength = (short_weight - long_weight) / total_weight

        # Overall confidence
        confidence = sum(s.confidence * s.weight for s in signals) / sum(s.weight for s in signals)

        # Reduce confidence if there are conflicts
        if conflicts > 0:
            confidence *= 0.7

        # Position sizing (volatility-adjusted)
        if direction != "flat" and confidence >= self.min_confidence:
            # Inverse volatility sizing
            vol_factor = 0.02 / max(0.005, volatility)
            recommended_size = min(
                self.max_position_pct,
                strength * confidence * vol_factor * 0.02,
            )
        else:
            recommended_size = 0.0
            direction = "flat"

        # Stop/TP based on volatility
        stop_loss = volatility * 2.0  # 2x daily vol
        take_profit = volatility * 3.0  # 3x daily vol (1.5:1 reward/risk)

        return AggregatedSignal(
            symbol=symbol,
            direction=direction,
            strength=strength,
            confidence=confidence,
            sources=[s.name for s in signals],
            conflicts=conflicts,
            recommended_size=recommended_size,
            stop_loss_pct=stop_loss * 100,
            take_profit_pct=take_profit * 100,
        )
