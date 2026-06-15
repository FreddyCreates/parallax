from __future__ import annotations

from dataclasses import dataclass
from importlib.resources import files
from pathlib import Path
from typing import Any
import copy
import os

import yaml


def _deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(base)
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = _deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


@dataclass(frozen=True)
class AppPaths:
    root: Path
    config_file: Path
    cache_file: Path
    audit_log: Path
    app_log: Path
    sessions_dir: Path


class ConfigManager:
    def __init__(self, config_path: str | Path | None = None) -> None:
        path = Path(config_path).expanduser() if config_path else Path.home() / ".aicli" / "config.yaml"
        root = path.parent
        self.paths = AppPaths(
            root=root,
            config_file=path,
            cache_file=root / "cache.sqlite3",
            audit_log=root / "audit.log",
            app_log=root / "aicli.log",
            sessions_dir=root / "sessions",
        )
        self._config: dict[str, Any] | None = None

    def _default_config(self) -> dict[str, Any]:
        content = files("aicli").joinpath("config.yaml").read_text(encoding="utf-8")
        return yaml.safe_load(content) or {}

    def ensure_layout(self) -> None:
        self.paths.root.mkdir(parents=True, exist_ok=True)
        self.paths.sessions_dir.mkdir(parents=True, exist_ok=True)
        if not self.paths.config_file.exists():
            self.paths.config_file.write_text(
                yaml.safe_dump(self._default_config(), sort_keys=False),
                encoding="utf-8",
            )

    def load(self) -> dict[str, Any]:
        self.ensure_layout()
        default = self._default_config()
        if self.paths.config_file.exists():
            loaded = yaml.safe_load(self.paths.config_file.read_text(encoding="utf-8")) or {}
        else:
            loaded = {}
        config = _deep_merge(default, loaded)
        self._apply_env_overrides(config)
        self._config = config
        return config

    def save(self, config: dict[str, Any]) -> None:
        self.ensure_layout()
        self.paths.config_file.write_text(yaml.safe_dump(config, sort_keys=False), encoding="utf-8")
        self._config = config

    @property
    def config(self) -> dict[str, Any]:
        if self._config is None:
            return self.load()
        return self._config

    def active_profile(self, explicit: str | None = None) -> dict[str, Any]:
        config = self.config
        profile_name = explicit or config.get("default_profile", "dev")
        profiles = config.get("profiles", {})
        return profiles.get(profile_name, profiles.get("dev", {}))

    def _apply_env_overrides(self, config: dict[str, Any]) -> None:
        env_map = {
            "AICLI_OFFLINE_MODE": ("offline_mode", self._parse_bool),
            "PARALLAX_AI_ENDPOINT": ("backend.url", str),
            "PARALLAX_AI_PRINCIPAL": ("backend.auth.principal", str),
            "PARALLAX_AI_TOKEN": ("backend.auth.delegation_token", str),
            "AICLI_DEFAULT_PROFILE": ("default_profile", str),
            "OLLAMA_HOST": ("ollama.url", str),
            "OLLAMA_MODEL": ("ollama.model", str),
        }
        for env_key, (path, caster) in env_map.items():
            value = os.getenv(env_key)
            if value is None or value == "":
                continue
            self._set_path(config, path, caster(value))

    @staticmethod
    def _parse_bool(value: str) -> bool:
        return value.strip().lower() in {"1", "true", "yes", "on"}

    @staticmethod
    def _set_path(payload: dict[str, Any], dotted_path: str, value: Any) -> None:
        cursor = payload
        parts = dotted_path.split(".")
        for part in parts[:-1]:
            cursor = cursor.setdefault(part, {})
        cursor[parts[-1]] = value
