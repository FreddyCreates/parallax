from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import re


@dataclass
class CompressionResult:
    original_tokens: int
    compressed_tokens: int
    summary: str
    digest: str

    @property
    def ratio(self) -> float:
        if self.compressed_tokens == 0:
            return 0.0
        return self.original_tokens / self.compressed_tokens


class ThoughtCompressor:
    """Lightweight context compression for repeated prompts and batch execution."""

    def estimate_tokens(self, text: str) -> int:
        return max(1, len(re.findall(r"\S+", text))) if text else 0

    def compress_text(self, text: str, *, max_lines: int = 24, max_chars: int = 3000) -> CompressionResult:
        clean_lines: list[str] = []
        seen: set[str] = set()
        for line in text.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            if stripped in seen:
                continue
            seen.add(stripped)
            clean_lines.append(line[:240])
            if len(clean_lines) >= max_lines:
                break
        summary = "
".join(clean_lines)
        summary = summary[:max_chars]
        return CompressionResult(
            original_tokens=self.estimate_tokens(text),
            compressed_tokens=self.estimate_tokens(summary),
            summary=summary,
            digest=sha256(summary.encode("utf-8")).hexdigest()[:16],
        )

    def compress_context(self, context: dict[str, object]) -> CompressionResult:
        flattened = []
        for key, value in context.items():
            flattened.append(f"[{key}] {value}")
        return self.compress_text("
".join(flattened))
