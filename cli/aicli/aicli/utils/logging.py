from __future__ import annotations

from datetime import datetime, timezone
import json
import logging
from pathlib import Path
from typing import Any


def setup_logging(log_file: Path, level: str = "INFO", verbose: bool = False) -> logging.Logger:
    logger = logging.getLogger("aicli")
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))
    logger.handlers.clear()

    formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(name)s | %(message)s")
    file_handler = logging.FileHandler(log_file, encoding="utf-8")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    if verbose:
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

    logger.propagate = False
    return logger


class AuditLogger:
    def __init__(self, audit_log: Path, enabled: bool = True) -> None:
        self.audit_log = audit_log
        self.enabled = enabled

    def log(self, event_type: str, payload: dict[str, Any]) -> None:
        if not self.enabled:
            return
        record = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "event_type": event_type,
            "payload": payload,
        }
        with self.audit_log.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, default=str) + "
")
