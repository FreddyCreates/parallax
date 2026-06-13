"""Tests for Evaluation Criteria (Section 15.7)."""

from parralax.tokenomics.evaluation import (
    CriterionScore,
    EvaluationCriterion,
    EvaluationResult,
    TokenomicEvaluator,
    CRITERION_DEFINITIONS,
)


class TestCriterionScore:
    def test_definition(self):
        s = CriterionScore(
            criterion=EvaluationCriterion.COGNITIVE_RETURN_PER_TOKEN, score=4.5
        )
        assert "cognition" in s.definition.lower()

    def test_all_criteria_have_definitions(self):
        for c in EvaluationCriterion:
            assert c in CRITERION_DEFINITIONS


class TestEvaluationResult:
    def test_total_and_average(self):
        result = EvaluationResult(
            system_name="test",
            scores=[
                CriterionScore(criterion=EvaluationCriterion.COGNITIVE_RETURN_PER_TOKEN, score=4),
                CriterionScore(criterion=EvaluationCriterion.COMPRESSION_FIDELITY, score=3),
            ],
        )
        assert result.total_score == 7.0
        assert result.average_score == 3.5

    def test_maturity_production(self):
        scores = [
            CriterionScore(criterion=c, score=4.5) for c in EvaluationCriterion
        ]
        result = EvaluationResult(system_name="prod", scores=scores)
        assert result.maturity_level == "production"

    def test_maturity_nascent(self):
        scores = [
            CriterionScore(criterion=c, score=1.0) for c in EvaluationCriterion
        ]
        result = EvaluationResult(system_name="nascent", scores=scores)
        assert result.maturity_level == "nascent"

    def test_by_criterion(self):
        result = EvaluationResult(
            system_name="test",
            scores=[
                CriterionScore(criterion=EvaluationCriterion.ERROR_AVOIDANCE, score=5),
            ],
        )
        found = result.by_criterion(EvaluationCriterion.ERROR_AVOIDANCE)
        assert found is not None
        assert found.score == 5
        assert result.by_criterion(EvaluationCriterion.CONTEXT_HYGIENE) is None

    def test_summary(self):
        result = EvaluationResult(
            system_name="test",
            scores=[
                CriterionScore(criterion=EvaluationCriterion.RISK_PRESERVATION, score=3.5),
            ],
        )
        s = result.summary()
        assert s["system_name"] == "test"
        assert s["criteria_scored"] == 1
        assert "maturity_level" in s

    def test_empty(self):
        result = EvaluationResult()
        assert result.average_score == 0.0
        assert result.maturity_level == "nascent"


class TestTokenomicEvaluator:
    def test_evaluate(self):
        evaluator = TokenomicEvaluator()
        result = evaluator.evaluate(
            system_name="sys-a",
            scores={
                EvaluationCriterion.COGNITIVE_RETURN_PER_TOKEN: 4.5,
                EvaluationCriterion.COMPRESSION_FIDELITY: 4.0,
            },
        )
        assert result.average_score == 4.25
        assert result.maturity_level == "production"

    def test_compare(self):
        evaluator = TokenomicEvaluator()
        evaluator.evaluate(
            system_name="tokenomic",
            scores={c: 4.0 for c in EvaluationCriterion},
        )
        evaluator.evaluate(
            system_name="baseline",
            scores={c: 2.5 for c in EvaluationCriterion},
        )
        comp = evaluator.compare("tokenomic", "baseline")
        assert comp is not None
        assert comp["winner"] == "tokenomic"
        assert comp["delta"] > 0

    def test_compare_missing(self):
        evaluator = TokenomicEvaluator()
        assert evaluator.compare("a", "b") is None

    def test_get_result(self):
        evaluator = TokenomicEvaluator()
        evaluator.evaluate(
            system_name="x",
            scores={EvaluationCriterion.ERROR_AVOIDANCE: 5.0},
        )
        assert evaluator.get_result("x") is not None
        assert evaluator.get_result("y") is None
