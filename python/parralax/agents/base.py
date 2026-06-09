"""Base agent framework with governance controls."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any
from uuid import UUID, uuid4

import structlog

logger = structlog.get_logger()


class AgentRole(str, Enum):
    OBSERVER = "observer"
    PROPOSER = "proposer"
    EXECUTOR = "executor"
    GOVERNOR = "governor"


class AgentStatus(str, Enum):
    IDLE = "idle"
    ACTIVE = "active"
    PAUSED = "paused"
    TERMINATED = "terminated"
    AWAITING_APPROVAL = "awaiting_approval"


@dataclass
class AgentCapital:
    """Capital limits for an agent."""

    max_position_size: float = 100_000.0
    max_daily_loss: float = 10_000.0
    max_notional: float = 1_000_000.0
    current_exposure: float = 0.0
    daily_pnl: float = 0.0


@dataclass
class AgentMemory:
    """Post-trade memory for learning and adaptation."""

    trades: list[dict[str, Any]] = field(default_factory=list)
    signals: list[dict[str, Any]] = field(default_factory=list)
    decisions: list[dict[str, Any]] = field(default_factory=list)
    max_history: int = 10_000

    def record_trade(self, trade: dict[str, Any]) -> None:
        self.trades.append({**trade, "timestamp": datetime.now(timezone.utc).isoformat()})
        if len(self.trades) > self.max_history:
            self.trades = self.trades[-self.max_history:]

    def record_signal(self, signal: dict[str, Any]) -> None:
        self.signals.append({**signal, "timestamp": datetime.now(timezone.utc).isoformat()})
        if len(self.signals) > self.max_history:
            self.signals = self.signals[-self.max_history:]


class BaseAgent(ABC):
    """Base class for all PARRALAX trading agents."""

    def __init__(
        self,
        name: str,
        role: AgentRole = AgentRole.OBSERVER,
        capital: AgentCapital | None = None,
    ):
        self.id: UUID = uuid4()
        self.name = name
        self.role = role
        self.status = AgentStatus.IDLE
        self.capital = capital or AgentCapital()
        self.memory = AgentMemory()
        self.created_at = datetime.now(timezone.utc)
        self.kill_switch = False
        self._logger = logger.bind(agent_id=str(self.id), agent_name=name)

    @abstractmethod
    async def tick(self, market_state: dict[str, Any]) -> list[dict[str, Any]]:
        """Process one tick of market data. Returns proposed actions."""
        ...

    @abstractmethod
    async def on_fill(self, fill: dict[str, Any]) -> None:
        """Handle a trade fill notification."""
        ...

    def activate(self) -> None:
        if self.kill_switch:
            self._logger.warning("Cannot activate — kill switch is engaged")
            return
        self.status = AgentStatus.ACTIVE
        self._logger.info("Agent activated", role=self.role.value)

    def pause(self) -> None:
        self.status = AgentStatus.PAUSED
        self._logger.info("Agent paused")

    def terminate(self) -> None:
        self.status = AgentStatus.TERMINATED
        self._logger.info("Agent terminated")

    def engage_kill_switch(self) -> None:
        self.kill_switch = True
        self.status = AgentStatus.PAUSED
        self._logger.critical("KILL SWITCH ENGAGED")

    def check_capital_limits(self, proposed_size: float) -> bool:
        """Check if proposed trade is within capital limits."""
        if self.capital.current_exposure + proposed_size > self.capital.max_notional:
            self._logger.warning(
                "Capital limit breach",
                proposed=proposed_size,
                current=self.capital.current_exposure,
                max=self.capital.max_notional,
            )
            return False
        if self.capital.daily_pnl < -self.capital.max_daily_loss:
            self._logger.warning("Daily loss limit breached", pnl=self.capital.daily_pnl)
            return False
        return True

    def promote(self, new_role: AgentRole) -> None:
        """Promote agent to a higher authority level."""
        old_role = self.role
        self.role = new_role
        self._logger.info("Agent promoted", old_role=old_role.value, new_role=new_role.value)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": str(self.id),
            "name": self.name,
            "role": self.role.value,
            "status": self.status.value,
            "capital": {
                "max_position_size": self.capital.max_position_size,
                "max_daily_loss": self.capital.max_daily_loss,
                "current_exposure": self.capital.current_exposure,
                "daily_pnl": self.capital.daily_pnl,
            },
            "created_at": self.created_at.isoformat(),
            "kill_switch": self.kill_switch,
            "trade_count": len(self.memory.trades),
        }
