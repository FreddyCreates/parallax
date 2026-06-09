"""Market data adapters for multiple venues and asset classes."""

from .base import MarketDataAdapter
from .crypto_adapter import CryptoMarketAdapter
from .equity_adapter import EquityMarketAdapter

__all__ = ["MarketDataAdapter", "CryptoMarketAdapter", "EquityMarketAdapter"]
