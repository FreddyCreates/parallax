"""Agent registry — tracks all active and historical agents."""

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from ..agents.base import BaseAgent


class AgentRegistry:
    """Central registry for all PARRALAX agents."""

    def __init__(self) -> None:
        self._agents: dict[UUID, BaseAgent] = {}
        self._agent_history: list[dict[str, Any]] = []

    def register(self, agent: BaseAgent) -> UUID:
        """Register an agent in the system."""
        self._agents[agent.id] = agent
        self._agent_history.append({
            "event": "registered",
            "agent_id": str(agent.id),
            "name": agent.name,
            "role": agent.role.value,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        return agent.id

    def get(self, agent_id: UUID) -> BaseAgent | None:
        return self._agents.get(agent_id)

    def list_active(self) -> list[BaseAgent]:
        return [a for a in self._agents.values() if a.status.value in ("idle", "active")]

    def deregister(self, agent_id: UUID) -> None:
        if agent_id in self._agents:
            agent = self._agents[agent_id]
            agent.terminate()
            self._agent_history.append({
                "event": "deregistered",
                "agent_id": str(agent_id),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            })

    def kill_all(self) -> None:
        """Emergency kill switch for all agents."""
        for agent in self._agents.values():
            agent.engage_kill_switch()

    def get_registry_state(self) -> dict[str, Any]:
        return {
            "total_agents": len(self._agents),
            "active_agents": len(self.list_active()),
            "agents": [a.to_dict() for a in self._agents.values()],
        }
