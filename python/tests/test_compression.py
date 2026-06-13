"""Tests for Compression Efficiency Metrics (Section 15.4)."""

from parralax.tokenomics.compression import CompressionAuditor, CompressionScore


class TestCompressionScore:
    def test_cef_basic(self):
        s = CompressionScore(
            information_retained=4, action_clarity=5, risk_preserved=4,
            output_tokens=100,
        )
        assert s.quality_sum == 13.0
        assert s.cef == 13.0 / 100

    def test_cef_zero_tokens(self):
        s = CompressionScore(information_retained=5)
        assert s.cef == 0.0

    def test_compression_ratio(self):
        s = CompressionScore(output_tokens=100, original_tokens=400)
        assert s.compression_ratio == 4.0

    def test_compression_ratio_zero(self):
        s = CompressionScore(output_tokens=0, original_tokens=400)
        assert s.compression_ratio == 0.0

    def test_token_savings_pct(self):
        s = CompressionScore(output_tokens=200, original_tokens=500)
        assert s.token_savings_pct == 60.0

    def test_token_savings_pct_zero_original(self):
        s = CompressionScore(output_tokens=200, original_tokens=0)
        assert s.token_savings_pct == 0.0

    def test_passes_tokenomic_test_true(self):
        s = CompressionScore(
            information_retained=4, action_clarity=3, risk_preserved=3,
            output_tokens=50,
        )
        assert s.passes_tokenomic_test is True

    def test_passes_tokenomic_test_false(self):
        s = CompressionScore(
            information_retained=4, action_clarity=2, risk_preserved=4,
            output_tokens=50,
        )
        assert s.passes_tokenomic_test is False


class TestCompressionAuditor:
    def test_evaluate_and_summary(self):
        auditor = CompressionAuditor()
        score = auditor.evaluate(
            information_retained=4, action_clarity=5, risk_preserved=4,
            output_tokens=200, original_tokens=600,
        )
        assert score.passes_tokenomic_test is True
        assert len(auditor.scores) == 1

        summary = auditor.summary()
        assert summary["evaluations"] == 1
        assert summary["pass_rate"] == 1.0

    def test_pass_rate(self):
        auditor = CompressionAuditor()
        auditor.evaluate(information_retained=4, action_clarity=4, risk_preserved=4, output_tokens=100)
        auditor.evaluate(information_retained=1, action_clarity=1, risk_preserved=1, output_tokens=100)
        assert auditor.pass_rate == 0.5

    def test_average_cef(self):
        auditor = CompressionAuditor()
        auditor.evaluate(information_retained=3, action_clarity=3, risk_preserved=3, output_tokens=90)
        auditor.evaluate(information_retained=3, action_clarity=3, risk_preserved=3, output_tokens=90)
        # Each CEF = 9/90 = 0.1
        assert abs(auditor.average_cef - 0.1) < 1e-9

    def test_average_compression_ratio(self):
        auditor = CompressionAuditor()
        auditor.evaluate(output_tokens=100, original_tokens=200)
        auditor.evaluate(output_tokens=100, original_tokens=400)
        # Ratios: 2.0 and 4.0, average = 3.0
        assert auditor.average_compression_ratio == 3.0

    def test_empty(self):
        auditor = CompressionAuditor()
        assert auditor.average_cef == 0.0
        assert auditor.pass_rate == 0.0
