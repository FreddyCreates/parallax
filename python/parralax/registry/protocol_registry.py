"""Protocol registry — central registry for all system protocols."""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any
from uuid import UUID, uuid4


class ProtocolStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    DEPRECATED = "deprecated"
    SUSPENDED = "suspended"


@dataclass
class Protocol:
    """A registered protocol in the PARRALAX system."""

    id: UUID
    name: str
    version: str
    domain: str
    status: ProtocolStatus
    description: str
    author: str
    created_at: datetime
    updated_at: datetime
    config: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": str(self.id),
            "name": self.name,
            "version": self.version,
            "domain": self.domain,
            "status": self.status.value,
            "description": self.description,
            "author": self.author,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }


class ProtocolRegistry:
    """Central registry for all PARRALAX protocols."""

    def __init__(self) -> None:
        self._protocols: dict[UUID, Protocol] = {}
        self._by_name: dict[str, UUID] = {}

    def register(
        self,
        name: str,
        version: str,
        domain: str,
        description: str,
        author: str = "system",
        config: dict[str, Any] | None = None,
    ) -> Protocol:
        """Register a new protocol."""
        now = datetime.now(timezone.utc)
        protocol = Protocol(
            id=uuid4(),
            name=name,
            version=version,
            domain=domain,
            status=ProtocolStatus.DRAFT,
            description=description,
            author=author,
            created_at=now,
            updated_at=now,
            config=config or {},
        )
        self._protocols[protocol.id] = protocol
        self._by_name[name] = protocol.id
        return protocol

    def activate(self, protocol_id: UUID) -> None:
        if protocol_id in self._protocols:
            self._protocols[protocol_id].status = ProtocolStatus.ACTIVE
            self._protocols[protocol_id].updated_at = datetime.now(timezone.utc)

    def get(self, name: str) -> Protocol | None:
        pid = self._by_name.get(name)
        return self._protocols.get(pid) if pid else None

    def list_all(self) -> list[Protocol]:
        return list(self._protocols.values())

    def list_by_domain(self, domain: str) -> list[Protocol]:
        return [p for p in self._protocols.values() if p.domain == domain]

    def initialize_core_protocols(self) -> None:
        """Register all core PARRALAX protocols."""
        core = [
            ("execution", "1.0.0", "trading", "Order execution and routing protocol"),
            ("risk_gate", "1.0.0", "risk", "Pre-trade risk validation protocol"),
            ("compute_receipt", "1.0.0", "audit", "Proof-of-execution receipt protocol"),
            ("token_issuance", "1.0.0", "assets", "Internal token creation protocol"),
            ("nft_issuance", "1.0.0", "assets", "NFT and digital asset protocol"),
            ("agent_authority", "1.0.0", "governance", "Agent permission and promotion protocol"),
            ("treasury", "1.0.0", "finance", "Treasury management protocol"),
            ("market_data", "1.0.0", "data", "Market data ingestion protocol"),
            ("signal", "1.0.0", "trading", "Trading signal generation protocol"),
            ("settlement", "1.0.0", "trading", "Trade settlement and reconciliation protocol"),
        ]
        for name, version, domain, desc in core:
            p = self.register(name, version, domain, desc)
            self.activate(p.id)
