"""Tests for Runtime Measurement Loop (Section 15.6)."""

from parralax.tokenomics.runtime_loop import (
    RuntimeMeasurementLoop,
    TaskClass,
    TaskContext,
)
from parralax.tokenomics.salience import SalienceItem


class TestTaskContext:
    def test_defaults(self):
        ctx = TaskContext()
        assert ctx.task_class == TaskClass.GENERAL
        assert ctx.risk_level == 0.0
        assert ctx.total_budget == 1000


class TestRuntimeMeasurementLoop:
    def test_execute_basic(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(
            task_class=TaskClass.CASHFLOW_DECISION,
            risk_level=4,
            complexity=3,
            salience_items=[
                SalienceItem(label="cash-position", urgency=5, risk=4),
                SalienceItem(label="background", known=4),
            ],
            total_budget=800,
        )
        result = loop.execute(
            ctx,
            cognitive_scores=dict(
                decision_quality=4, actionability=5, risk_control=3,
                reuse_value=2, learning_gain=1,
                prompt_tokens=300, output_tokens=200,
            ),
            compression_scores=dict(
                information_retained=4, action_clarity=5, risk_preserved=4,
                output_tokens=200, original_tokens=500,
            ),
            wasted_tokens=20,
            extracted_rules=["Always check clearing date before scheduling"],
        )
        assert result.cognitive_return_score is not None
        assert result.cognitive_return_score.crpt > 0
        assert result.compression_score is not None
        assert result.compression_score.passes_tokenomic_test is True
        assert result.wasted_tokens == 20
        assert len(result.extracted_rules) == 1
        assert len(result.salience_scores) == 2

    def test_policy_tightens_on_waste(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(total_budget=500)
        loop.execute(
            ctx,
            cognitive_scores=dict(
                decision_quality=2, prompt_tokens=100, output_tokens=100,
            ),
            wasted_tokens=80,  # 80/200 = 0.4 > 0.3 threshold
        )
        assert loop.policy["budget_multiplier"] < 1.0

    def test_policy_expands_on_good_crpt(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(total_budget=500)
        loop.execute(
            ctx,
            cognitive_scores=dict(
                decision_quality=5, actionability=5, risk_control=5,
                reuse_value=5, learning_gain=5,
                prompt_tokens=100, output_tokens=100,
            ),
            wasted_tokens=0,
        )
        assert loop.policy["budget_multiplier"] > 1.0

    def test_module_recruitment(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(
            risk_level=5,
            complexity=5,
            modules_available=["mod_a", "mod_b", "mod_c", "mod_d"],
        )
        result = loop.execute(ctx)
        # High risk+complexity should recruit all modules
        assert len(result.recruited_modules) == 4

    def test_module_recruitment_low_complexity(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext(
            risk_level=1,
            complexity=1,
            modules_available=["mod_a", "mod_b", "mod_c", "mod_d", "mod_e"],
        )
        result = loop.execute(ctx)
        # Low risk+complexity should recruit minimal modules
        assert len(result.recruited_modules) == 1

    def test_extracted_rules_accumulate(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext()
        loop.execute(ctx, extracted_rules=["Rule A"])
        loop.execute(ctx, extracted_rules=["Rule B", "Rule C"])
        assert loop.extracted_rules == ["Rule A", "Rule B", "Rule C"]

    def test_summary(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext()
        loop.execute(
            ctx,
            cognitive_scores=dict(decision_quality=3, prompt_tokens=50, output_tokens=50),
        )
        s = loop.summary()
        assert s["total_iterations"] == 1
        assert "policy" in s
        assert "cognitive_metrics" in s

    def test_efficiency_score(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext()
        result = loop.execute(
            ctx,
            cognitive_scores=dict(
                decision_quality=5, prompt_tokens=100, output_tokens=100,
            ),
            wasted_tokens=50,
        )
        # CRPT = 5/200 = 0.025, waste_fraction = 50/200 = 0.25
        # efficiency = 0.025 * (1 - 0.25) = 0.01875
        assert abs(result.efficiency_score - 0.01875) < 1e-9

    def test_no_cognitive_scores(self):
        loop = RuntimeMeasurementLoop()
        ctx = TaskContext()
        result = loop.execute(ctx)
        assert result.cognitive_return_score is None
        assert result.efficiency_score == 0.0
