"""Event-Driven Strategy.

Trades around catalysts: earnings, macro releases, news sentiment.
"""

from __future__ import annotations

from dataclasses import dataclass
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
        self.last_state: dict[str, Any] = {}

    def register_event(self, symbol: str, event_type: EventType, meta: dict[str, Any]) -> None:
        """Register upcoming catalysts for monitoring."""
        self.event_calendar.append({"symbol": symbol, "event_type": event_type, **meta})

    def parse_sentiment(self, headlines: list[str]) -> float:
        """Parse news sentiment using a deterministic keyword lexicon."""
        positive_words = {"beat", "upgrade", "growth", "record", "strong", "bullish", "expansion"}
        negative_words = {"miss", "downgrade", "weak", "lawsuit", "cut", "bearish", "contraction"}
        score = 0.0
        total = 0
        for headline in headlines:
            tokens = [token.strip('.,:;!?"').lower() for token in headline.split()]
            score += sum(1 for token in tokens if token in positive_words)
            score -= sum(1 for token in tokens if token in negative_words)
            total += len(tokens)
        if total == 0:
            return 0.0
        return max(-1.0, min(1.0, score / max(len(headlines) * 3, 1)))

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
        avg_move = sum(abs(move) for move in historical_moves) / len(historical_moves) if historical_moves else 0.02
        hist_factor = min(2.0, avg_move / 0.02)
        surprise_mult = 1.0 + min(1.5, abs(surprise_factor) * 0.5)
        return min(1.0, base * hist_factor * surprise_mult)

    def event_bias(self, event_type: EventType, sentiment_score: float, surprise_factor: float) -> float:
        """Translate event type into directional bias."""
        if event_type == EventType.EARNINGS:
            return 0.7 * sentiment_score + 0.3 * surprise_factor
        if event_type in {EventType.MACRO_RELEASE, EventType.CENTRAL_BANK}:
            return 0.4 * sentiment_score + 0.6 * surprise_factor
        return 0.8 * sentiment_score + 0.2 * surprise_factor

    def get_risk_metrics(self) -> dict[str, Any]:
        """Return event gap-risk metrics."""
        magnitude = float(self.last_state.get("impact_score", 0.0))
        surprise = abs(float(self.last_state.get("surprise_factor", 0.0)))
        max_loss = magnitude * (1.0 + surprise)
        expected_drawdown = max_loss * 0.55
        return {
            "impact_score": magnitude,
            "surprise_factor": surprise,
            "max_loss": max_loss,
            "expected_drawdown": expected_drawdown,
        }

    def get_strategy_state(self) -> dict[str, Any]:
        """Return event-monitoring state and health."""
        impact_score = float(self.last_state.get("impact_score", 0.0))
        return {
            "healthy": not self.last_state or impact_score >= self.min_impact_score * 0.5,
            "tracked_events": len(self.event_calendar),
            "last_state": self.last_state,
        }

    def generate_signal(
        self,
        symbol: str,
        event_type: EventType,
        sentiment_score: float,
        historical_moves: list[float] | None = None,
        surprise_factor: float = 0.0,
        hours_to_event: float = 0.0,
    ) -> EventSignal:
        """Generate event-driven trading signal."""
        impact_score = self.score_event_impact(event_type, historical_moves or [], surprise_factor)
        bias = self.event_bias(event_type, sentiment_score, surprise_factor)
        impact = EventImpact.HIGH if impact_score > 0.7 else EventImpact.MEDIUM if impact_score > 0.4 else EventImpact.LOW

        if hours_to_event > 0:
            in_setup_window = hours_to_event <= self.pre_event_hours
            if in_setup_window and abs(bias) > 0.2:
                direction = "long" if bias > 0 else "short"
                pre_position = "enter_scaled"
            else:
                direction = "flat"
                pre_position = "wait"
            post_action = "hold_through" if impact == EventImpact.HIGH and abs(bias) > 0.35 else "reduce_before"
        else:
            if abs(surprise_factor) > 1.0 and abs(sentiment_score) < 0.2:
                direction = "short" if surprise_factor > 0 else "long"
                post_action = "fade"
            else:
                direction = "long" if bias > 0.15 else "short" if bias < -0.15 else "flat"
                post_action = "follow"
            pre_position = "n/a"

        confidence = min(1.0, impact_score * (0.5 + 0.5 * abs(bias)))
        if impact_score < self.min_impact_score:
            direction = "flat"
            confidence = 0.0

        self.last_state = {
            "symbol": symbol,
            "event_type": event_type.value,
            "impact_score": impact_score,
            "surprise_factor": surprise_factor,
            "hours_to_event": hours_to_event,
        }
        return EventSignal(
            symbol=symbol,
            event_type=event_type,
            impact=impact,
            direction=direction,
            magnitude=impact_score,
            pre_event_position=pre_position,
            post_event_action=post_action,
            confidence=confidence,
        )
