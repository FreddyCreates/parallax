"""Tests for the Tokenomics Measurement and Benchmarking Framework."""

from parralax.tokenomics.token_value import (
    TokenValueFunction,
    TokenValueScore,
    TokenValueWeights,
)
from parralax.tokenomics.cognitive_return import (
    CognitiveReturnMetrics,
    CognitiveReturnScore,
)
from parralax.tokenomics.benchmark import TokenomicBenchmark, BenchmarkResult


# ── Token Value Function ─────────────────────────────────────────────


class TestTokenValueScore:
    def test_positive_value(self):
        s = TokenValueScore(
            decision_quality=4, actionability=3, risk_reduction=2,
            compression=1, memory_reuse=2, noise=1,
        )
        assert s.value == 4 + 3 + 2 + 1 + 2 - 1
        assert s.is_positive is True

    def test_negative_value(self):
        s = TokenValueScore(noise=5)
        assert s.value == -5.0
        assert s.is_positive is False

    def test_zero_value(self):
        s = TokenValueScore()
        assert s.value == 0.0
        assert s.is_positive is False

    def test_custom_weights(self):
        w = TokenValueWeights(decision=2.0, noise=3.0)
        s = TokenValueScore(decision_quality=5, noise=2, weights=w)
        assert s.value == 2.0 * 5 - 3.0 * 2  # 10 - 6 = 4


class TestTokenValueFunction:
    def test_score(self):
        tvf = TokenValueFunction()
        s = tvf.score(decision_quality=5, actionability=4)
        assert s.value == 9.0

    def test_score_batch(self):
        tvf = TokenValueFunction()
        results = tvf.score_batch([
            {"decision_quality": 5},
            {"noise": 3},
        ])
        assert len(results) == 2
        assert results[0].value == 5.0
        assert results[1].value == -3.0

    def test_aggregate(self):
        tvf = TokenValueFunction()
        scores = [
            tvf.score(decision_quality=4),
            tvf.score(decision_quality=6),
        ]
        assert tvf.aggregate(scores) == 5.0

    def test_aggregate_empty(self):
        tvf = TokenValueFunction()
        assert tvf.aggregate([]) == 0.0


# ── Cognitive Return Metrics ─────────────────────────────────────────


class TestCognitiveReturnScore:
    def test_cognitive_return(self):
        s = CognitiveReturnScore(
            decision_quality=5, actionability=4, risk_control=3,
            reuse_value=2, learning_gain=1,
            prompt_tokens=100, output_tokens=50,
        )
        assert s.cognitive_return == 15.0
        assert s.total_tokens == 150
        assert s.crpt == 15.0 / 150

    def test_zero_tokens_crpt(self):
        s = CognitiveReturnScore(decision_quality=5)
        assert s.crpt == 0.0


class TestCognitiveReturnMetrics:
    def test_record_and_summary(self):
        m = CognitiveReturnMetrics()
        m.record(
            decision_quality=4, actionability=5, risk_control=3,
            reuse_value=4, learning_gain=2,
            prompt_tokens=500, output_tokens=350,
        )
        assert len(m.scores) == 1
        assert m.total_cognitive_return == 18.0
        assert m.total_tokens == 850
        assert m.average_crpt == 18.0 / 850

    def test_multiple_records(self):
        m = CognitiveReturnMetrics()
        m.record(decision_quality=5, prompt_tokens=100, output_tokens=100)
        m.record(decision_quality=3, prompt_tokens=100, output_tokens=100)
        assert m.average_cognitive_return == 4.0

    def test_summary_format(self):
        m = CognitiveReturnMetrics()
        m.record(decision_quality=5, prompt_tokens=100, output_tokens=50)
        s = m.summary()
        assert "interactions" in s
        assert "average_crpt" in s
        assert s["interactions"] == 1


# ── Benchmark ────────────────────────────────────────────────────────


class TestBenchmarkResult:
    def test_crpt_improvement(self):
        r = BenchmarkResult(
            task_name="test",
            tokenomic_score=CognitiveReturnScore(
                decision_quality=5, prompt_tokens=100, output_tokens=100
            ),
            baseline_score=CognitiveReturnScore(
                decision_quality=5, prompt_tokens=100, output_tokens=400
            ),
        )
        assert r.crpt_improvement is not None
        assert r.crpt_improvement > 1.0  # tokenomic is more efficient

    def test_missing_scores(self):
        r = BenchmarkResult(task_name="test")
        assert r.crpt_improvement is None
        assert r.token_efficiency_gain is None
        assert r.cognitive_return_delta is None

    def test_token_efficiency_gain(self):
        r = BenchmarkResult(
            task_name="test",
            tokenomic_score=CognitiveReturnScore(
                prompt_tokens=100, output_tokens=100
            ),
            baseline_score=CognitiveReturnScore(
                prompt_tokens=100, output_tokens=400
            ),
        )
        assert r.token_efficiency_gain is not None
        assert r.token_efficiency_gain > 0  # tokenomic used fewer tokens


class TestTokenomicBenchmark:
    def test_compare(self):
        bench = TokenomicBenchmark()
        result = bench.compare(
            task_name="risk-assessment-001",
            task_category="financial",
            tokenomic=dict(
                decision_quality=5, actionability=4, risk_control=5,
                reuse_value=3, learning_gain=4,
                prompt_tokens=400, output_tokens=200,
            ),
            baseline=dict(
                decision_quality=3, actionability=2, risk_control=2,
                reuse_value=1, learning_gain=1,
                prompt_tokens=400, output_tokens=600,
            ),
        )
        assert result.crpt_improvement is not None
        assert result.crpt_improvement > 1.0

    def test_report(self):
        bench = TokenomicBenchmark()
        bench.compare(
            task_name="t1",
            task_category="operational",
            tokenomic=dict(
                decision_quality=5, prompt_tokens=200, output_tokens=100,
            ),
            baseline=dict(
                decision_quality=2, prompt_tokens=200, output_tokens=500,
            ),
        )
        report = bench.report()
        assert report["total_tasks"] == 1
        assert report["hypothesis_supported"] is True
        assert "per_category" in report
        assert "operational" in report["per_category"]

    def test_report_empty(self):
        bench = TokenomicBenchmark()
        report = bench.report()
        assert report["total_tasks"] == 0
        assert report["hypothesis_supported"] is None
