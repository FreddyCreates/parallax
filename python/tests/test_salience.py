"""Tests for Salience Allocation (Section 15.3)."""

from parralax.tokenomics.salience import (
    SalienceEngine,
    SalienceItem,
    SalienceScore,
    SalienceWeights,
)


class TestSalienceItem:
    def test_defaults(self):
        item = SalienceItem()
        assert item.urgency == 0.0
        assert item.known == 0.0


class TestSalienceEngine:
    def test_score_item_basic(self):
        engine = SalienceEngine()
        item = SalienceItem(urgency=5, risk=3, mission_relevance=4)
        score = engine.score_item(item)
        assert score == 5 + 3 + 4

    def test_known_penalty(self):
        engine = SalienceEngine()
        item = SalienceItem(urgency=2, known=5)
        score = engine.score_item(item)
        assert score == 2 - 5

    def test_allocate_proportional(self):
        engine = SalienceEngine(total_budget=1000)
        items = [
            SalienceItem(label="high", urgency=5, risk=5),
            SalienceItem(label="low", urgency=1),
        ]
        scores = engine.allocate(items)
        assert len(scores) == 2
        assert scores[0].allocated_tokens > scores[1].allocated_tokens
        assert scores[0].budget_fraction > scores[1].budget_fraction

    def test_allocate_negative_salience_gets_zero(self):
        engine = SalienceEngine(total_budget=500)
        items = [
            SalienceItem(label="positive", urgency=5),
            SalienceItem(label="negative", known=5),
        ]
        scores = engine.allocate(items)
        assert scores[1].allocated_tokens == 0
        assert scores[1].budget_fraction == 0.0

    def test_allocate_empty(self):
        engine = SalienceEngine()
        assert engine.allocate([]) == []

    def test_rank_descending(self):
        engine = SalienceEngine()
        items = [
            SalienceItem(label="low", urgency=1),
            SalienceItem(label="high", urgency=5, risk=5),
            SalienceItem(label="mid", urgency=3),
        ]
        ranked = engine.rank(items)
        assert ranked[0].item.label == "high"
        assert ranked[-1].item.label == "low"

    def test_custom_weights(self):
        weights = SalienceWeights(urgency=2.0, risk=0.5)
        engine = SalienceEngine(weights=weights)
        item = SalienceItem(urgency=3, risk=4)
        score = engine.score_item(item)
        assert score == 2.0 * 3 + 0.5 * 4  # 6 + 2 = 8

    def test_all_zero_salience(self):
        engine = SalienceEngine(total_budget=100)
        items = [SalienceItem(), SalienceItem()]
        scores = engine.allocate(items)
        assert all(s.allocated_tokens == 0 for s in scores)
