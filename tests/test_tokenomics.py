"""
Tests for the PARALLAX Tokenomics Measurement & Benchmarking Engine.
"""

import sys
import os

# Ensure the SDK is importable
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src", "python"))

from parallax_sdk.tokenomics import (
    compute_token_value,
    compute_crpt,
    compute_compression_efficiency,
    compute_tokenomic_gain,
    TokenValueWeights,
    CognitiveReturnScore,
    SalienceItem,
    SalienceEngine,
    BenchmarkScore,
    TaskClass,
    TaskRisk,
    TokenomicsRuntime,
)
from parallax_sdk.constants import PHI_INV


def test_token_value_positive():
    """High-quality token should have positive value."""
    result = compute_token_value(
        decision_quality=4.0,
        action_usefulness=4.0,
        risk_reduction=3.0,
        compression_contribution=2.0,
        memory_reuse_value=2.0,
        noise_waste=0.0,
    )
    assert result.token_value > 0


def test_token_value_negative_for_noise():
    """Pure noise token should have negative value."""
    result = compute_token_value(
        decision_quality=0.0,
        action_usefulness=0.0,
        risk_reduction=0.0,
        compression_contribution=0.0,
        memory_reuse_value=0.0,
        noise_waste=5.0,
    )
    assert result.token_value < 0


def test_token_value_balanced():
    """Equal decision and noise with same weight should cancel."""
    result = compute_token_value(
        decision_quality=3.0,
        action_usefulness=0.0,
        risk_reduction=0.0,
        compression_contribution=0.0,
        memory_reuse_value=0.0,
        noise_waste=3.0,
    )
    # wDecision and wNoise are both PHI_INV by default
    assert abs(result.token_value) < 1e-10


def test_crpt_typical():
    """CRPT should compute CR / total_tokens."""
    score = CognitiveReturnScore(
        decision_quality=4.0,
        actionability=3.0,
        risk_control=3.0,
        reuse_value=2.0,
        learning_gain=1.0,
    )
    result = compute_crpt(score, prompt_tokens=500, output_tokens=300)
    assert result.cognitive_return == 13.0
    assert result.total_tokens == 800
    assert abs(result.crpt - 13.0 / 800) < 1e-10


def test_crpt_zero_tokens():
    """Zero tokens should produce zero CRPT."""
    score = CognitiveReturnScore(
        decision_quality=5.0,
        actionability=5.0,
        risk_control=5.0,
        reuse_value=5.0,
        learning_gain=5.0,
    )
    result = compute_crpt(score, prompt_tokens=0, output_tokens=0)
    assert result.crpt == 0.0


def test_salience_engine_allocates_proportionally():
    """Higher salience items should get more budget."""
    engine = SalienceEngine(total_budget=2000)
    engine.add_item(SalienceItem(
        item_id="high",
        label="Critical risk",
        urgency=0.9,
        risk=0.8,
        mission_relevance=0.7,
        time_sensitivity=0.6,
        novelty=0.5,
        known_context=0.0,
    ))
    engine.add_item(SalienceItem(
        item_id="low",
        label="Known info",
        urgency=0.1,
        risk=0.1,
        mission_relevance=0.1,
        time_sensitivity=0.1,
        novelty=0.1,
        known_context=0.7,
    ))
    results = engine.allocate()
    high = next(r for r in results if r.item_id == "high")
    low = next(r for r in results if r.item_id == "low")
    assert high.allocated_budget > low.allocated_budget


def test_salience_engine_sorted_descending():
    """Results should be sorted by salience score descending."""
    engine = SalienceEngine(total_budget=1000)
    engine.add_item(SalienceItem(
        item_id="a", label="A",
        urgency=0.2, risk=0.2, mission_relevance=0.2,
        time_sensitivity=0.2, novelty=0.2, known_context=0.0,
    ))
    engine.add_item(SalienceItem(
        item_id="b", label="B",
        urgency=0.9, risk=0.9, mission_relevance=0.9,
        time_sensitivity=0.9, novelty=0.9, known_context=0.0,
    ))
    results = engine.allocate()
    assert results[0].item_id == "b"


def test_compression_efficiency():
    """CEF = (info + clarity + risk) / tokens."""
    result = compute_compression_efficiency(
        information_retained=4.0,
        action_clarity=4.0,
        risk_preserved=4.0,
        output_tokens=100,
    )
    assert abs(result.cef - 12.0 / 100) < 1e-10
    assert abs(result.ce - 4.0 / 100) < 1e-10


def test_compression_zero_tokens():
    """Zero tokens should not divide by zero."""
    result = compute_compression_efficiency(5.0, 5.0, 5.0, output_tokens=0)
    assert result.ce == 0.0
    assert result.cef == 0.0


def test_tokenomic_gain_superior():
    """Tokenomic system with higher score/token is superior."""
    baseline = BenchmarkScore(
        task_class=TaskClass.RESEARCH_SYNTHESIS,
        decision_quality=3.0,
        actionability=3.0,
        risk_control=2.0,
        reuse_value=1.0,
        accuracy=3.0,
        waste=2.0,
        tokens_used=2000,
    )
    tokenomic = BenchmarkScore(
        task_class=TaskClass.RESEARCH_SYNTHESIS,
        decision_quality=4.0,
        actionability=4.0,
        risk_control=4.0,
        reuse_value=3.0,
        accuracy=4.0,
        waste=1.0,
        tokens_used=1000,
    )
    result = compute_tokenomic_gain(baseline, tokenomic)
    assert result.is_superior is True
    assert result.tokenomic_gain > 0


def test_tokenomic_gain_inferior():
    """Tokenomic system with same score but more tokens is inferior."""
    baseline = BenchmarkScore(
        task_class=TaskClass.ESTIMATING,
        decision_quality=4.0,
        actionability=4.0,
        risk_control=3.0,
        reuse_value=2.0,
        accuracy=4.0,
        waste=1.0,
        tokens_used=500,
    )
    tokenomic = BenchmarkScore(
        task_class=TaskClass.ESTIMATING,
        decision_quality=4.0,
        actionability=4.0,
        risk_control=3.0,
        reuse_value=2.0,
        accuracy=4.0,
        waste=1.0,
        tokens_used=5000,
    )
    result = compute_tokenomic_gain(baseline, tokenomic)
    assert result.is_superior is False


def test_runtime_full_loop():
    """Full runtime measurement loop should work end-to-end."""
    rt = TokenomicsRuntime()
    rt.classify_task(TaskClass.ARCHITECTURE_DESIGN, TaskRisk.HIGH)
    rt.set_budget(2000)
    rt.add_salience_item(SalienceItem(
        item_id="arch",
        label="Module design",
        urgency=0.7,
        risk=0.6,
        mission_relevance=0.9,
        time_sensitivity=0.3,
        novelty=0.8,
        known_context=0.1,
    ))

    result = rt.audit(
        prompt_tokens=600,
        output_tokens=1200,
        cognitive_return=CognitiveReturnScore(
            decision_quality=4.0,
            actionability=3.0,
            risk_control=4.0,
            reuse_value=3.0,
            learning_gain=2.0,
        ),
        compression_scores=(4.0, 3.5, 4.0),
        wasted_tokens=100,
        reusable_rules=2,
    )

    assert result.task_class == TaskClass.ARCHITECTURE_DESIGN
    assert result.cognitive_return.crpt > 0
    assert result.compression.cef > 0
    assert result.wasted_tokens == 100
    assert result.reusable_rules_extracted == 2


def test_runtime_stats():
    """Runtime should track cumulative statistics."""
    rt = TokenomicsRuntime()
    rt.classify_task(TaskClass.INVOICE_EXECUTION, TaskRisk.MEDIUM)
    rt.set_budget(1000)

    rt.audit(
        prompt_tokens=200,
        output_tokens=400,
        cognitive_return=CognitiveReturnScore(
            decision_quality=4.0,
            actionability=5.0,
            risk_control=3.0,
            reuse_value=2.0,
            learning_gain=1.0,
        ),
        compression_scores=(4.0, 5.0, 3.0),
        wasted_tokens=30,
        reusable_rules=1,
    )

    stats = rt.get_stats()
    assert stats["interactions"] == 1
    assert stats["avg_crpt"] > 0
    assert stats["cumulative_waste"] == 30
    assert stats["cumulative_reuse"] == 1
    assert stats["total_tokens_spent"] == 600


def test_runtime_requires_classification():
    """Audit should raise if task not classified."""
    rt = TokenomicsRuntime()
    try:
        rt.audit(
            prompt_tokens=100,
            output_tokens=100,
            cognitive_return=CognitiveReturnScore(
                decision_quality=1.0,
                actionability=1.0,
                risk_control=1.0,
                reuse_value=1.0,
                learning_gain=1.0,
            ),
            compression_scores=(1.0, 1.0, 1.0),
        )
        assert False, "Should have raised ValueError"
    except ValueError as e:
        assert "not classified" in str(e)


if __name__ == "__main__":
    test_token_value_positive()
    test_token_value_negative_for_noise()
    test_token_value_balanced()
    test_crpt_typical()
    test_crpt_zero_tokens()
    test_salience_engine_allocates_proportionally()
    test_salience_engine_sorted_descending()
    test_compression_efficiency()
    test_compression_zero_tokens()
    test_tokenomic_gain_superior()
    test_tokenomic_gain_inferior()
    test_runtime_full_loop()
    test_runtime_stats()
    test_runtime_requires_classification()
    print("All tokenomics tests passed!")
