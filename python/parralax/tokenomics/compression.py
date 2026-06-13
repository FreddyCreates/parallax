"""Compression Efficiency Metrics (Section 15.4).

Compression is not the same as shortening. A compressed response succeeds only if it
preserves meaning, action clarity, and risk awareness.

Compression Efficiency:

    CE = MeaningPreserved / TokensUsed

Operational Compression Efficiency Factor:

    CEF = (InformationRetained + ActionClarity + RiskPreserved) / OutputTokens

Good compression reduces surface length while preserving correct action.
Bad compression merely deletes context and can increase operational risk.

A compressed output passes the tokenomic test only if the user or downstream system
can still act correctly.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CompressionScore:
    """Result of a compression efficiency evaluation.

    Attributes:
        information_retained: Preservation of important task-relevant content (0–5).
        action_clarity: Clarity of the next step or decision (0–5).
        risk_preserved: Preservation of necessary caution/uncertainty/constraints (0–5).
        output_tokens: Total output tokens used.
        original_tokens: Token count of the uncompressed version (optional, for ratio).
    """

    information_retained: float = 0.0
    action_clarity: float = 0.0
    risk_preserved: float = 0.0
    output_tokens: int = 0
    original_tokens: int = 0

    @property
    def quality_sum(self) -> float:
        """Sum of quality factors: InformationRetained + ActionClarity + RiskPreserved."""
        return self.information_retained + self.action_clarity + self.risk_preserved

    @property
    def cef(self) -> float:
        """Compression Efficiency Factor.

        CEF = (InformationRetained + ActionClarity + RiskPreserved) / OutputTokens

        Returns 0.0 if output_tokens is zero.
        """
        if self.output_tokens == 0:
            return 0.0
        return self.quality_sum / self.output_tokens

    @property
    def compression_ratio(self) -> float:
        """Ratio of original tokens to compressed tokens.

        A value > 1.0 means tokens were saved. Returns 0.0 if either count is zero.
        """
        if self.output_tokens == 0 or self.original_tokens == 0:
            return 0.0
        return self.original_tokens / self.output_tokens

    @property
    def token_savings_pct(self) -> float:
        """Percentage of tokens saved by compression.

        Returns 0.0 if original_tokens is zero.
        """
        if self.original_tokens == 0:
            return 0.0
        return (self.original_tokens - self.output_tokens) / self.original_tokens * 100.0

    @property
    def passes_tokenomic_test(self) -> bool:
        """Whether the compression preserves enough quality for correct action.

        A compressed output passes if all quality factors are ≥ 3.0 (on 0–5 scale),
        meaning sufficient meaning, action clarity, and risk are preserved.
        """
        return (
            self.information_retained >= 3.0
            and self.action_clarity >= 3.0
            and self.risk_preserved >= 3.0
        )


class CompressionAuditor:
    """Audit compression quality across multiple outputs.

    Usage::

        auditor = CompressionAuditor()
        score = auditor.evaluate(
            information_retained=4.5,
            action_clarity=5.0,
            risk_preserved=4.0,
            output_tokens=200,
            original_tokens=600,
        )
        print(score.cef)
        print(score.passes_tokenomic_test)
        print(auditor.summary())
    """

    def __init__(self) -> None:
        self._scores: list[CompressionScore] = []

    def evaluate(
        self,
        *,
        information_retained: float = 0.0,
        action_clarity: float = 0.0,
        risk_preserved: float = 0.0,
        output_tokens: int = 0,
        original_tokens: int = 0,
    ) -> CompressionScore:
        """Evaluate a single compression and record the result.

        Returns:
            A :class:`CompressionScore` with computed metrics.
        """
        score = CompressionScore(
            information_retained=information_retained,
            action_clarity=action_clarity,
            risk_preserved=risk_preserved,
            output_tokens=output_tokens,
            original_tokens=original_tokens,
        )
        self._scores.append(score)
        return score

    @property
    def scores(self) -> list[CompressionScore]:
        """All recorded compression scores."""
        return list(self._scores)

    @property
    def average_cef(self) -> float:
        """Average Compression Efficiency Factor across all evaluations."""
        if not self._scores:
            return 0.0
        return sum(s.cef for s in self._scores) / len(self._scores)

    @property
    def pass_rate(self) -> float:
        """Fraction of compressions that pass the tokenomic test (0–1)."""
        if not self._scores:
            return 0.0
        passed = sum(1 for s in self._scores if s.passes_tokenomic_test)
        return passed / len(self._scores)

    @property
    def average_compression_ratio(self) -> float:
        """Average compression ratio across evaluations with original_tokens > 0."""
        valid = [s for s in self._scores if s.original_tokens > 0]
        if not valid:
            return 0.0
        return sum(s.compression_ratio for s in valid) / len(valid)

    def summary(self) -> dict[str, float | int]:
        """Return a summary dict suitable for logging or display."""
        return {
            "evaluations": len(self._scores),
            "average_cef": round(self.average_cef, 6),
            "pass_rate": round(self.pass_rate, 4),
            "average_compression_ratio": round(self.average_compression_ratio, 4),
        }
