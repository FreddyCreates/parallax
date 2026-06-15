from __future__ import annotations

from dataclasses import dataclass
from importlib import metadata
from pathlib import Path
from typing import Any

import typer

from . import __version__
from .ai.router import ModelRouter
from .commands.diagnose import diagnose_command
from .commands.explain import explain_command
from .commands.generate import generate_command
from .commands.optimize import optimize_command
from .commands.query import query_model_command
from .commands.trace import trace_command
from .utils.config import ConfigManager
from .utils.formatting import console
from .utils.logging import AuditLogger, setup_logging

app = typer.Typer(
    add_completion=False,
    no_args_is_help=True,
    invoke_without_command=True,
    pretty_exceptions_show_locals=False,
)
_PLUGIN_LOADED = False


@dataclass
class AppContext:
    config: dict[str, Any]
    profile: str
    config_manager: ConfigManager
    router: ModelRouter
    paths: Any


@app.callback()
def callback(
    ctx: typer.Context,
    profile: str | None = typer.Option(None, "--profile", help="Configuration profile to use (dev or prod)."),
    config: Path | None = typer.Option(None, "--config", help="Override config file path."),
    offline: bool = typer.Option(False, "--offline", help="Force offline mode where possible."),
    verbose: bool = typer.Option(False, "--verbose", help="Enable verbose CLI logging."),
    version: bool = typer.Option(False, "--version", help="Show version and exit.", is_eager=True),
) -> None:
    if version:
        console.print(f"aicli {__version__}")
        raise typer.Exit()

    manager = ConfigManager(config)
    settings = manager.load()
    if offline:
        settings["offline_mode"] = True
    active_profile = profile or settings.get("default_profile", "dev")
    setup_logging(manager.paths.app_log, level=settings.get("logging", {}).get("level", "INFO"), verbose=verbose)
    audit_logger = AuditLogger(manager.paths.audit_log, enabled=bool(settings.get("logging", {}).get("audit_enabled", True)))
    ctx.obj = AppContext(
        config=settings,
        profile=active_profile,
        config_manager=manager,
        router=ModelRouter(settings, paths=manager.paths, audit_logger=audit_logger),
        paths=manager.paths,
    )
    _load_plugins()


def _load_plugins() -> None:
    global _PLUGIN_LOADED
    if _PLUGIN_LOADED:
        return
    try:
        entry_points = metadata.entry_points(group="aicli.plugins")
    except TypeError:
        entry_points = metadata.entry_points().get("aicli.plugins", [])
    for entry_point in entry_points:
        plugin = entry_point.load()
        if hasattr(plugin, "register"):
            plugin.register(app)
        elif isinstance(plugin, typer.Typer):
            app.add_typer(plugin, name=entry_point.name)
    _PLUGIN_LOADED = True


app.command("explain")(explain_command)
app.command("optimize")(optimize_command)
app.command("generate")(generate_command)
app.command("diagnose")(diagnose_command)
app.command("query-model")(query_model_command)
app.command("trace")(trace_command)


def main() -> None:
    app()


if __name__ == "__main__":
    main()
