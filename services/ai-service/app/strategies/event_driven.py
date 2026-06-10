"""Event-Driven Strategy.

Trades around catalysts: earnings, macro releases, news sentiment.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class EventType(str, Enum):
    EARNINGS = "earnings"
    MACRO_RELEASE = "macro_release"
    CENTRAL_BANK = "central_bank"
    GEOPOLITICAL = "geopolitical"
    CORPORATE_ACTION = "corporate_action"
    REGULATORY = "regulatory"
    SENTIMENT_SHIFT = "sentiment_shift"


class EventImpact(str, Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


@dataclass
class EventSignal:
    symbol: str
    event_type: EventType
    impact: EventImpact
    direction: str
    magnitude: float
    pre_event_position: str
    post_event_action: str
    confidence: float


class EventDrivenStrategy:
    """Event-driven trading around catalysts."""

    def __init__(
        self,
        min_impact_score: float = 0.5,
        pre_event_hours: int = 4,
        post_event_hours: int = 2,
    ) -> None:
        self.min_impact_score = min_impact_score
        self.pre_event_hours = pre_event_hours
        self.post_event_hours = post_event_hours
        self.event_calendar: list[dict[str, Any]] = []

    def score_event_impact(
        self,
        event_type: EventType,
        historical_moves: list[float],
        surprise_factor: float = 0.0,
    ) -> float:
        """Score expected market impact of an event."""
        base_impacts = {
            EventType.EARNINGS: 0.7,
            EventType.CENTRAL_BANK: 0.9,
            EventType.MACRO_RELEASE: 0.6,
            EventType.GEOPOLITICAL: 0.8,
            EventType.CORPORATE_ACTION: 0.5,
            EventType.REGULATORY: 0.6,
            EventType.SENTIMENT_SHIFT: 0.4,
        }

        base = base_impacts.get(event_type, 0.5)

        # Historical volatility around events
        if historical_moves:
            avg_move = sum(abs(m) for m in historical_moves) / len(historical_moves)
            hist_factor = min(2.0, avg_move / 0.02)  # Normalize to 2% baseline
        else:
            hist_factor = 1.0

        # Surprise amplification
        surprise_mult = 1.0 + abs(surprise_factor) * 0.5

        return min(1.0, base * hist_factor * surprise_mult)

    def generate_signal(
        self,
        symbol: str,
        event_type: EventType,
        sentiment_score: float,  # -1 to 1
        historical_moves: list[float] | None = None,
        surprise_factor: float = 0.0,
        hours_to_event: float = 0.0,
    ) -> EventSignal:
        """Generate event-driven trading signal."""
        impact_score = self.score_event_impact(
            event_type, historical_moves or [], surprise_factor
        )

        impact = (
            EventImpact.HIGH if impact_score > 0.7
            else EventImpact.MEDIUM if impact_score > 0.4
            else EventImpact.LOW
        )

        # Pre-event: position based on expected direction
        if hours_to_event > 0:
            if abs(sentiment_score) > 0.5:
                direction = "long" if sentiment_score > 0 else "short"
                pre_position = "enter"
            else:
                direction = "flat"
                pre_position = "wait"
            post_action = "hold_through" if impact == EventImpact.HIGH else "exit_before"
        else:
            # Post-event: trade the reaction
            direction = "long" if sentiment_score > 0.3 else "short" if sentiment_score < -0.3 else "flat"
            pre_position = "n/a"
            post_action = "fade" if abs(surprise_factor) > 1.0 else "follow"

        confidence = impact_score * abs(sentiment_score)

        return EventSignal(
            symbol=symbol,
            event_type=event_type,
            impact=impact,
            direction=direction,
            magnitude=impact_score,
            pre_event_position=pre_position,
            post_event_action=post_action,
            confidence=min(1.0, confidence),
        )
