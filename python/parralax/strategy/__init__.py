"""Strategy management, allocation, and AI trading engines.

Includes:
- Alpha engine (multi-factor signal combination)
- Execution orchestrator (smart order routing)
- Signal aggregator (multi-strategy consensus)
- Financial language routing (FIX, SWIFT, FpML, ISDA, XBRL, ISO20022)
"""

from .engines import AlphaEngine, ExecutionOrchestrator, SignalAggregator

__all__ = ["AlphaEngine", "ExecutionOrchestrator", "SignalAggregator"]
