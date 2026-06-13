"""Strategy Router — AI-driven strategy orchestration and allocation.

Routes capital and signals across all strategies based on market regime,
risk budgets, performance analytics, correlation monitoring, and
ML-enhanced regime detection with multi-timeframe analysis.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class MarketRegime(str, Enum):
    TRENDING = "trending"
    MEAN_REVERTING = "mean_reverting"
    HIGH_VOLATILITY = "high_volatility"
    LOW_VOLATILITY = "low_volatility"
    CRISIS = "crisis"
    NORMAL = "normal"
    MOMENTUM_BREAKOUT = "momentum_breakout"
    COMPRESSION = "compression"
    DISPERSION = "dispersion"
    TRANSITION = "transition"


class StrategyType(str, Enum):
    STAT_ARB = "statistical_arbitrage"
    MARKET_MAKING = "market_making"
    MOMENTUM = "momentum"
    MEAN_REVERSION = "mean_reversion"
    PAIRS = "pairs_trading"
    VOL_ARB = "volatility_arbitrage"
    LIQUIDITY = "liquidity_provision"
    CROSS_ASSET = "cross_asset_arbitrage"
    EVENT_DRIVEN = "event_driven"
    ML_ALPHA = "ml_alpha"


class TimeFrame(str, Enum):
    INTRADAY = "intraday"
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class RiskLimitStatus(str, Enum):
    NORMAL = "normal"
    WARNING = "warning"
    BREACH = "breach"
    CRITICAL = "critical"


@dataclass
class StrategyAllocation:
    strategy_type: StrategyType
    weight: float
    risk_budget: float
    capital_allocated: float
    is_active: bool = True
    max_position: float = 0.0
    current_pnl: float = 0.0


@dataclass
class RoutingDecision:
    regime: MarketRegime
    allocations: list[StrategyAllocation]
    total_capital_deployed: float
    reserve_capital: float
    active_strategies: int
    regime_confidence: float


@dataclass
class StrategyPerformance:
    """Performance metrics for a single strategy."""
    strategy_type: StrategyType
    rolling_sharpe: float = 0.0
    rolling_sortino: float = 0.0
    information_ratio: float = 0.0
    tracking_error: float = 0.0
    alpha: float = 0.0
    beta: float = 0.0
    max_drawdown: float = 0.0
    current_drawdown: float = 0.0
    win_rate: float = 0.0
    profit_factor: float = 0.0
    avg_trade_pnl: float = 0.0
    calmar_ratio: float = 0.0


@dataclass
class CorrelationState:
    """Correlation monitoring state."""
    current_matrix: dict[tuple[str, str], float] = field(default_factory=dict)
    avg_correlation: float = 0.0
    max_correlation: float = 0.0
    dispersion: float = 0.0
    breakdown_detected: bool = False
    regime_shift_signal: float = 0.0


@dataclass
class RiskLimit:
    """Risk limit definition."""
    strategy_type: StrategyType
    max_drawdown: float = 0.05
    max_var_99: float = 0.03
    max_position_pct: float = 0.20
    max_concentration: float = 0.30
    daily_loss_limit: float = 0.02
    current_utilization: float = 0.0
    status: RiskLimitStatus = RiskLimitStatus.NORMAL


@dataclass
class ExecutionQualityMetrics:
    """Execution quality tracking per strategy."""
    strategy_type: StrategyType
    avg_slippage_bps: float = 0.0
    fill_rate: float = 0.0
    avg_latency_ms: float = 0.0
    cost_per_trade: float = 0.0
    implementation_shortfall: float = 0.0
    total_orders: int = 0
    total_notional: float = 0.0


@dataclass
class RegimeFeatures:
    """Features used for regime detection."""
    realized_vol: float = 0.0
    vol_of_vol: float = 0.0
    trend_strength: float = 0.0
    mean_reversion_speed: float = 0.0
    autocorrelation: float = 0.0
    skewness: float = 0.0
    kurtosis: float = 0.0
    hurst_exponent: float = 0.0
    avg_correlation: float = 0.0
    vix_level: float = 0.0
    credit_spread: float = 0.0
    momentum_breadth: float = 0.0


class RegimeDetector:
    """ML-enhanced market regime detection with multi-timeframe analysis."""

    def __init__(self) -> None:
        self.regime_history: list[tuple[MarketRegime, float, str]] = []
        self.feature_history: list[RegimeFeatures] = []

    def extract_features(self, returns: list[float], lookback: int = 60) -> RegimeFeatures:
        """Extract features for regime classification."""
        if not returns:
            return RegimeFeatures()

        recent = returns[-lookback:] if len(returns) > lookback else returns
        n = len(recent)
        mean = sum(recent) / n
        var = sum((r - mean) ** 2 for r in recent) / n
        vol = math.sqrt(var) * math.sqrt(252)

        # Vol of vol
        if n > 20:
            rolling_vols = []
            for i in range(10, n):
                window = recent[i - 10:i]
                wvar = sum(r**2 for r in window) / 10
                rolling_vols.append(math.sqrt(wvar))
            vol_mean = sum(rolling_vols) / len(rolling_vols) if rolling_vols else 0
            vov = math.sqrt(sum((v - vol_mean) ** 2 for v in rolling_vols) / len(rolling_vols)) if rolling_vols else 0
        else:
            vov = 0.0

        # Trend strength (absolute cumulative return / sum of absolute returns)
        abs_sum = sum(abs(r) for r in recent)
        cum_return = sum(recent)
        trend = abs(cum_return) / abs_sum if abs_sum > 0 else 0.0

        # Autocorrelation (lag-1)
        if n > 2:
            ac_num = sum(recent[i] * recent[i - 1] for i in range(1, n))
            ac_den = sum(r**2 for r in recent)
            autocorr = ac_num / ac_den if ac_den > 0 else 0.0
        else:
            autocorr = 0.0

        # Skewness and kurtosis
        if var > 0 and n > 3:
            std = math.sqrt(var)
            skew = sum((r - mean) ** 3 for r in recent) / (n * std**3)
            kurt = sum((r - mean) ** 4 for r in recent) / (n * std**4)
        else:
            skew = 0.0
            kurt = 3.0

        # Hurst exponent approximation (R/S method simplified)
        if n > 20:
            half = n // 2
            first_half = recent[:half]
            second_half = recent[half:]
            r1 = max(first_half) - min(first_half) if first_half else 0
            r2 = max(second_half) - min(second_half) if second_half else 0
            s1 = math.sqrt(sum(x**2 for x in first_half) / half) if half > 0 else 1
            s2 = math.sqrt(sum(x**2 for x in second_half) / (n - half)) if (n - half) > 0 else 1
            rs_ratio = ((r1 / s1 + r2 / s2) / 2) if s1 > 0 and s2 > 0 else 1
            hurst = math.log(max(rs_ratio, 0.01)) / math.log(max(n / 2, 2)) if rs_ratio > 0 else 0.5
            hurst = max(0.0, min(1.0, hurst))
        else:
            hurst = 0.5

        # Mean reversion speed (OU parameter estimate)
        if autocorr < 0:
            mr_speed = -math.log(max(abs(autocorr), 0.01))
        else:
            mr_speed = 0.0

        features = RegimeFeatures(
            realized_vol=vol,
            vol_of_vol=vov,
            trend_strength=trend,
            mean_reversion_speed=mr_speed,
            autocorrelation=autocorr,
            skewness=skew,
            kurtosis=kurt,
            hurst_exponent=hurst,
        )
        self.feature_history.append(features)
        return features

    def classify_regime(self, features: RegimeFeatures) -> tuple[MarketRegime, float]:
        """Classify market regime from features."""
        scores: dict[MarketRegime, float] = {}

        # Crisis detection
        crisis_score = 0.0
        if features.realized_vol > 0.40:
            crisis_score += 0.4
        if features.skewness < -1.0:
            crisis_score += 0.3
        if features.kurtosis > 6.0:
            crisis_score += 0.2
        if features.vol_of_vol > 0.5:
            crisis_score += 0.1
        scores[MarketRegime.CRISIS] = crisis_score

        # High vol
        hv_score = min(1.0, features.realized_vol / 0.35) * 0.6
        if features.vol_of_vol > 0.3:
            hv_score += 0.2
        scores[MarketRegime.HIGH_VOLATILITY] = hv_score

        # Low vol
        lv_score = max(0, 1.0 - features.realized_vol / 0.12) * 0.6
        if features.vol_of_vol < 0.1:
            lv_score += 0.2
        scores[MarketRegime.LOW_VOLATILITY] = lv_score

        # Trending
        trend_score = features.trend_strength * 0.4
        if features.hurst_exponent > 0.55:
            trend_score += 0.3
        if features.autocorrelation > 0.1:
            trend_score += 0.2
        scores[MarketRegime.TRENDING] = trend_score

        # Mean reverting
        mr_score = 0.0
        if features.autocorrelation < -0.1:
            mr_score += 0.4
        if features.hurst_exponent < 0.45:
            mr_score += 0.3
        if features.mean_reversion_speed > 1.0:
            mr_score += 0.2
        scores[MarketRegime.MEAN_REVERTING] = mr_score

        # Momentum breakout
        mb_score = 0.0
        if features.trend_strength > 0.5 and features.realized_vol > 0.20:
            mb_score = 0.6
        if features.kurtosis > 4.0 and features.trend_strength > 0.4:
            mb_score += 0.2
        scores[MarketRegime.MOMENTUM_BREAKOUT] = mb_score

        # Dispersion
        disp_score = 0.0
        if features.avg_correlation < 0.2:
            disp_score = 0.5
        scores[MarketRegime.DISPERSION] = disp_score

        # Normal
        scores[MarketRegime.NORMAL] = 0.3  # baseline

        # Select highest scoring regime
        best_regime = max(scores, key=lambda k: scores[k])
        confidence = scores[best_regime]

        self.regime_history.append((best_regime, confidence, ""))
        return best_regime, min(1.0, confidence)

    def multi_timeframe_regime(
        self,
        intraday_returns: list[float],
        daily_returns: list[float],
        weekly_returns: list[float] | None = None,
    ) -> dict[str, Any]:
        """Detect regime across multiple timeframes."""
        intraday_features = self.extract_features(intraday_returns, 100)
        daily_features = self.extract_features(daily_returns, 60)

        intraday_regime, intraday_conf = self.classify_regime(intraday_features)
        daily_regime, daily_conf = self.classify_regime(daily_features)

        weekly_regime = MarketRegime.NORMAL
        weekly_conf = 0.5
        if weekly_returns:
            weekly_features = self.extract_features(weekly_returns, 26)
            weekly_regime, weekly_conf = self.classify_regime(weekly_features)

        # Agreement score
        regimes = [intraday_regime, daily_regime, weekly_regime]
        agreement = len(set(regimes))
        agreement_score = 1.0 if agreement == 1 else (0.6 if agreement == 2 else 0.3)

        # Dominant regime (weighted by confidence and timeframe importance)
        weighted: dict[MarketRegime, float] = {}
        for regime, conf, weight in [
            (intraday_regime, intraday_conf, 0.3),
            (daily_regime, daily_conf, 0.5),
            (weekly_regime, weekly_conf, 0.2),
        ]:
            weighted[regime] = weighted.get(regime, 0) + conf * weight

        dominant = max(weighted, key=lambda k: weighted[k])

        return {
            "dominant_regime": dominant.value,
            "confidence": weighted[dominant],
            "agreement_score": agreement_score,
            "intraday": {"regime": intraday_regime.value, "confidence": intraday_conf},
            "daily": {"regime": daily_regime.value, "confidence": daily_conf},
            "weekly": {"regime": weekly_regime.value, "confidence": weekly_conf},
        }


class PerformanceTracker:
    """Track and analyze strategy performance."""

    def __init__(self) -> None:
        self.returns_history: dict[StrategyType, list[float]] = {s: [] for s in StrategyType}
        self.trade_history: dict[StrategyType, list[float]] = {s: [] for s in StrategyType}

    def record_return(self, strategy: StrategyType, daily_return: float) -> None:
        """Record daily return for a strategy."""
        self.returns_history[strategy].append(daily_return)

    def record_trade(self, strategy: StrategyType, trade_pnl: float) -> None:
        """Record individual trade P&L."""
        self.trade_history[strategy].append(trade_pnl)

    def get_performance(self, strategy: StrategyType, lookback: int = 60) -> StrategyPerformance:
        """Calculate performance metrics for a strategy."""
        returns = self.returns_history[strategy][-lookback:]
        if not returns:
            return StrategyPerformance(strategy_type=strategy)

        n = len(returns)
        mean = sum(returns) / n
        var = sum((r - mean) ** 2 for r in returns) / n
        std = math.sqrt(var) if var > 0 else 0.001

        # Sharpe
        ann_factor = math.sqrt(252)
        sharpe = mean / std * ann_factor

        # Sortino
        downside = [r for r in returns if r < 0]
        downside_std = math.sqrt(sum(r**2 for r in downside) / len(downside)) if downside else 0.001
        sortino = mean / downside_std * ann_factor

        # Drawdown
        cumulative = 0.0
        peak = 0.0
        max_dd = 0.0
        current_dd = 0.0
        for r in returns:
            cumulative += r
            peak = max(peak, cumulative)
            dd = cumulative - peak
            max_dd = min(max_dd, dd)
        current_dd = cumulative - peak

        # Win rate and profit factor
        trades = self.trade_history[strategy][-100:]
        wins = [t for t in trades if t > 0]
        losses = [t for t in trades if t < 0]
        win_rate = len(wins) / len(trades) if trades else 0.0
        profit_factor = (sum(wins) / abs(sum(losses))) if losses and sum(losses) != 0 else 0.0

        # Calmar
        calmar = (mean * 252) / abs(max_dd) if max_dd != 0 else 0.0

        return StrategyPerformance(
            strategy_type=strategy,
            rolling_sharpe=sharpe,
            rolling_sortino=sortino,
            max_drawdown=max_dd,
            current_drawdown=current_dd,
            win_rate=win_rate,
            profit_factor=profit_factor,
            avg_trade_pnl=sum(trades) / len(trades) if trades else 0.0,
            calmar_ratio=calmar,
        )

    def get_all_performance(self) -> dict[str, StrategyPerformance]:
        """Get performance for all strategies."""
        return {s.value: self.get_performance(s) for s in StrategyType}


class CorrelationMonitor:
    """Monitor inter-strategy correlations for diversification."""

    def __init__(self) -> None:
        self.correlation_history: list[CorrelationState] = []

    def compute_correlations(
        self, strategy_returns: dict[StrategyType, list[float]], lookback: int = 60
    ) -> CorrelationState:
        """Compute pairwise correlations between strategies."""
        strategies = [s for s in strategy_returns if len(strategy_returns[s]) >= lookback]
        if len(strategies) < 2:
            return CorrelationState()

        matrix: dict[tuple[str, str], float] = {}
        correlations: list[float] = []

        for i, s1 in enumerate(strategies):
            for s2 in strategies[i + 1:]:
                r1 = strategy_returns[s1][-lookback:]
                r2 = strategy_returns[s2][-lookback:]
                n = min(len(r1), len(r2))
                if n < 10:
                    continue
                m1 = sum(r1[:n]) / n
                m2 = sum(r2[:n]) / n
                cov = sum((r1[j] - m1) * (r2[j] - m2) for j in range(n)) / n
                std1 = math.sqrt(sum((r - m1) ** 2 for r in r1[:n]) / n)
                std2 = math.sqrt(sum((r - m2) ** 2 for r in r2[:n]) / n)
                corr = cov / (std1 * std2) if std1 > 0 and std2 > 0 else 0.0
                matrix[(s1.value, s2.value)] = corr
                correlations.append(corr)

        avg_corr = sum(correlations) / len(correlations) if correlations else 0.0
        max_corr = max(correlations) if correlations else 0.0
        dispersion = math.sqrt(sum((c - avg_corr) ** 2 for c in correlations) / len(correlations)) if correlations else 0.0

        # Breakdown detection: correlation spike
        breakdown = avg_corr > 0.6 or max_corr > 0.85

        state = CorrelationState(
            current_matrix=matrix,
            avg_correlation=avg_corr,
            max_correlation=max_corr,
            dispersion=dispersion,
            breakdown_detected=breakdown,
        )
        self.correlation_history.append(state)
        return state


class RiskLimitManager:
    """Per-strategy and aggregate risk limit management."""

    def __init__(self) -> None:
        self.limits: dict[StrategyType, RiskLimit] = {}
        self.breach_history: list[dict[str, Any]] = []

    def set_limit(self, strategy: StrategyType, limit: RiskLimit) -> None:
        """Set risk limit for a strategy."""
        self.limits[strategy] = limit

    def check_limits(
        self, strategy: StrategyType, current_drawdown: float, daily_pnl: float, position_pct: float
    ) -> RiskLimitStatus:
        """Check if strategy is within risk limits."""
        limit = self.limits.get(strategy)
        if not limit:
            return RiskLimitStatus.NORMAL

        # Check drawdown
        if abs(current_drawdown) > limit.max_drawdown:
            limit.status = RiskLimitStatus.BREACH
            self.breach_history.append({
                "strategy": strategy.value, "type": "drawdown",
                "value": current_drawdown, "limit": limit.max_drawdown,
            })
            return RiskLimitStatus.BREACH

        # Check daily loss
        if daily_pnl < -limit.daily_loss_limit:
            limit.status = RiskLimitStatus.BREACH
            self.breach_history.append({
                "strategy": strategy.value, "type": "daily_loss",
                "value": daily_pnl, "limit": limit.daily_loss_limit,
            })
            return RiskLimitStatus.BREACH

        # Warning levels
        if abs(current_drawdown) > limit.max_drawdown * 0.7:
            limit.status = RiskLimitStatus.WARNING
            return RiskLimitStatus.WARNING

        limit.status = RiskLimitStatus.NORMAL
        return RiskLimitStatus.NORMAL

    def get_aggregate_status(self) -> dict[str, Any]:
        """Get aggregate risk limit status."""
        breached = [s.value for s, l in self.limits.items() if l.status == RiskLimitStatus.BREACH]
        warning = [s.value for s, l in self.limits.items() if l.status == RiskLimitStatus.WARNING]
        return {
            "breached_strategies": breached,
            "warning_strategies": warning,
            "n_breached": len(breached),
            "n_warning": len(warning),
            "overall_status": (
                RiskLimitStatus.CRITICAL.value if len(breached) > 2
                else RiskLimitStatus.BREACH.value if breached
                else RiskLimitStatus.WARNING.value if warning
                else RiskLimitStatus.NORMAL.value
            ),
        }


class CapitalRecycler:
    """Capital recycling and intraday optimization."""

    def __init__(self, total_capital: float = 10_000_000.0) -> None:
        self.total_capital = total_capital
        self.freed_capital: float = 0.0
        self.recycling_history: list[dict[str, Any]] = []

    def release_capital(self, strategy: StrategyType, amount: float, reason: str = "") -> None:
        """Release capital from a strategy back to pool."""
        self.freed_capital += amount
        self.recycling_history.append({
            "action": "release",
            "strategy": strategy.value,
            "amount": amount,
            "reason": reason,
        })

    def reallocate(self, target_strategy: StrategyType, amount: float) -> float:
        """Reallocate freed capital to a strategy."""
        actual = min(amount, self.freed_capital)
        if actual > 0:
            self.freed_capital -= actual
            self.recycling_history.append({
                "action": "reallocate",
                "strategy": target_strategy.value,
                "amount": actual,
            })
        return actual

    def get_available_capital(self) -> float:
        """Get currently available freed capital."""
        return self.freed_capital


class StrategyRouter:
    """AI Strategy Router — orchestrates all trading strategies.

    Determines market regime and dynamically allocates capital
    across strategies for optimal risk-adjusted returns.
    """

    def __init__(self, total_capital: float = 10_000_000.0) -> None:
        self.total_capital = total_capital
        self.reserve_pct = 0.15
        self.current_regime = MarketRegime.NORMAL
        self.allocations: dict[StrategyType, StrategyAllocation] = {}
        self.regime_detector = RegimeDetector()
        self.performance_tracker = PerformanceTracker()
        self.correlation_monitor = CorrelationMonitor()
        self.risk_limit_manager = RiskLimitManager()
        self.capital_recycler = CapitalRecycler(total_capital)

        # Initialize default risk limits
        for st in StrategyType:
            self.risk_limit_manager.set_limit(st, RiskLimit(strategy_type=st))

        # Regime-specific allocation templates
        self.regime_templates: dict[MarketRegime, dict[StrategyType, float]] = {
            MarketRegime.TRENDING: {
                StrategyType.MOMENTUM: 0.30,
                StrategyType.ML_ALPHA: 0.20,
                StrategyType.EVENT_DRIVEN: 0.15,
                StrategyType.CROSS_ASSET: 0.15,
                StrategyType.MARKET_MAKING: 0.10,
                StrategyType.LIQUIDITY: 0.10,
            },
            MarketRegime.MEAN_REVERTING: {
                StrategyType.STAT_ARB: 0.25,
                StrategyType.MEAN_REVERSION: 0.25,
                StrategyType.PAIRS: 0.20,
                StrategyType.MARKET_MAKING: 0.15,
                StrategyType.LIQUIDITY: 0.10,
                StrategyType.ML_ALPHA: 0.05,
            },
            MarketRegime.HIGH_VOLATILITY: {
                StrategyType.VOL_ARB: 0.25,
                StrategyType.EVENT_DRIVEN: 0.20,
                StrategyType.MARKET_MAKING: 0.05,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.ML_ALPHA: 0.20,
                StrategyType.MOMENTUM: 0.15,
            },
            MarketRegime.LOW_VOLATILITY: {
                StrategyType.MARKET_MAKING: 0.30,
                StrategyType.LIQUIDITY: 0.25,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.PAIRS: 0.15,
                StrategyType.MEAN_REVERSION: 0.10,
                StrategyType.ML_ALPHA: 0.05,
            },
            MarketRegime.CRISIS: {
                StrategyType.VOL_ARB: 0.30,
                StrategyType.EVENT_DRIVEN: 0.25,
                StrategyType.MOMENTUM: 0.20,
                StrategyType.ML_ALPHA: 0.15,
                StrategyType.CROSS_ASSET: 0.10,
            },
            MarketRegime.NORMAL: {
                StrategyType.STAT_ARB: 0.15,
                StrategyType.MARKET_MAKING: 0.15,
                StrategyType.MOMENTUM: 0.12,
                StrategyType.MEAN_REVERSION: 0.12,
                StrategyType.PAIRS: 0.10,
                StrategyType.VOL_ARB: 0.10,
                StrategyType.ML_ALPHA: 0.10,
                StrategyType.LIQUIDITY: 0.08,
                StrategyType.CROSS_ASSET: 0.05,
                StrategyType.EVENT_DRIVEN: 0.03,
            },
            MarketRegime.MOMENTUM_BREAKOUT: {
                StrategyType.MOMENTUM: 0.35,
                StrategyType.ML_ALPHA: 0.20,
                StrategyType.CROSS_ASSET: 0.15,
                StrategyType.EVENT_DRIVEN: 0.15,
                StrategyType.VOL_ARB: 0.10,
                StrategyType.STAT_ARB: 0.05,
            },
            MarketRegime.DISPERSION: {
                StrategyType.STAT_ARB: 0.25,
                StrategyType.PAIRS: 0.20,
                StrategyType.CROSS_ASSET: 0.20,
                StrategyType.ML_ALPHA: 0.15,
                StrategyType.MEAN_REVERSION: 0.10,
                StrategyType.VOL_ARB: 0.10,
            },
            MarketRegime.COMPRESSION: {
                StrategyType.MARKET_MAKING: 0.30,
                StrategyType.LIQUIDITY: 0.25,
                StrategyType.MEAN_REVERSION: 0.20,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.PAIRS: 0.10,
            },
            MarketRegime.TRANSITION: {
                StrategyType.ML_ALPHA: 0.25,
                StrategyType.VOL_ARB: 0.20,
                StrategyType.EVENT_DRIVEN: 0.15,
                StrategyType.STAT_ARB: 0.15,
                StrategyType.MARKET_MAKING: 0.10,
                StrategyType.MOMENTUM: 0.10,
                StrategyType.LIQUIDITY: 0.05,
            },
        }

    def detect_regime(
        self,
        returns: list[float],
        volatility: float,
        trend_strength: float,
        correlation_breakdown: bool = False,
    ) -> tuple[MarketRegime, float]:
        """Detect current market regime from market data."""
        if correlation_breakdown or (volatility > 0.40 and any(r < -0.05 for r in returns[-5:])):
            return MarketRegime.CRISIS, 0.9

        if volatility > 0.25:
            return MarketRegime.HIGH_VOLATILITY, min(1.0, volatility / 0.40)

        if volatility < 0.10:
            return MarketRegime.LOW_VOLATILITY, min(1.0, (0.15 - volatility) / 0.10)

        if trend_strength > 0.6:
            return MarketRegime.TRENDING, trend_strength

        if trend_strength < 0.3:
            return MarketRegime.MEAN_REVERTING, 1.0 - trend_strength

        return MarketRegime.NORMAL, 0.5

    def detect_regime_ml(self, returns: list[float]) -> tuple[MarketRegime, float]:
        """ML-enhanced regime detection using feature extraction."""
        features = self.regime_detector.extract_features(returns)
        return self.regime_detector.classify_regime(features)

    def allocate(
        self,
        regime: MarketRegime,
        strategy_performance: dict[StrategyType, float] | None = None,
    ) -> RoutingDecision:
        """Allocate capital across strategies based on regime."""
        self.current_regime = regime
        deployable = self.total_capital * (1 - self.reserve_pct)

        template = self.regime_templates.get(regime, self.regime_templates[MarketRegime.NORMAL])

        # Adjust weights by performance if available
        weights = dict(template)
        if strategy_performance:
            total_perf = sum(max(0, p) for p in strategy_performance.values()) or 1
            for st, perf in strategy_performance.items():
                if st in weights and perf > 0:
                    weights[st] *= 1 + (perf / total_perf) * 0.3

            # Renormalize
            total_weight = sum(weights.values())
            weights = {k: v / total_weight for k, v in weights.items()}

        # Apply risk limit adjustments
        for st in list(weights.keys()):
            limit = self.risk_limit_manager.limits.get(st)
            if limit and limit.status == RiskLimitStatus.BREACH:
                weights[st] *= 0.25  # Reduce allocation for breached strategies
            elif limit and limit.status == RiskLimitStatus.WARNING:
                weights[st] *= 0.7

        # Renormalize after risk adjustments
        total_weight = sum(weights.values()) or 1.0
        weights = {k: v / total_weight for k, v in weights.items()}

        allocations = []
        for strategy_type, weight in weights.items():
            capital = deployable * weight
            alloc = StrategyAllocation(
                strategy_type=strategy_type,
                weight=weight,
                risk_budget=capital * 0.02,
                capital_allocated=capital,
                is_active=weight > 0.01,
                max_position=capital * 0.5,
            )
            self.allocations[strategy_type] = alloc
            allocations.append(alloc)

        regime_confidence = 0.7

        return RoutingDecision(
            regime=regime,
            allocations=allocations,
            total_capital_deployed=deployable,
            reserve_capital=self.total_capital * self.reserve_pct,
            active_strategies=sum(1 for a in allocations if a.is_active),
            regime_confidence=regime_confidence,
        )

    def kelly_criterion_sizing(
        self, strategy: StrategyType, win_rate: float, avg_win: float, avg_loss: float
    ) -> float:
        """Kelly criterion-based position sizing."""
        if avg_loss == 0:
            return 0.0
        b = avg_win / abs(avg_loss)
        f = (b * win_rate - (1 - win_rate)) / b
        # Half-Kelly for safety
        return max(0, min(0.25, f * 0.5))

    def black_litterman_weights(
        self, market_weights: dict[StrategyType, float], views: dict[StrategyType, float], tau: float = 0.05
    ) -> dict[StrategyType, float]:
        """Simplified Black-Litterman adjusted weights."""
        adjusted = {}
        for st in market_weights:
            market_w = market_weights[st]
            view = views.get(st, 0)
            # Blend market weight with view
            adjusted[st] = market_w * (1 - tau) + (market_w + view * 0.1) * tau
        # Normalize
        total = sum(max(0, v) for v in adjusted.values()) or 1.0
        return {k: max(0, v) / total for k, v in adjusted.items()}

    def get_routing_state(self) -> dict[str, Any]:
        """Get current routing state."""
        return {
            "regime": self.current_regime.value,
            "total_capital": self.total_capital,
            "deployable": self.total_capital * (1 - self.reserve_pct),
            "reserve": self.total_capital * self.reserve_pct,
            "allocations": {
                st.value: {
                    "weight": alloc.weight,
                    "capital": alloc.capital_allocated,
                    "risk_budget": alloc.risk_budget,
                    "active": alloc.is_active,
                    "pnl": alloc.current_pnl,
                }
                for st, alloc in self.allocations.items()
            },
            "active_count": sum(1 for a in self.allocations.values() if a.is_active),
            "risk_status": self.risk_limit_manager.get_aggregate_status(),
            "correlation": {
                "avg": self.correlation_monitor.correlation_history[-1].avg_correlation
                if self.correlation_monitor.correlation_history else 0.0,
            },
            "freed_capital": self.capital_recycler.get_available_capital(),
        }

    def emergency_deleverage(self, target_pct: float = 0.50) -> dict[str, Any]:
        """Emergency deleveraging — reduce all positions."""
        actions = []
        for st, alloc in self.allocations.items():
            if alloc.is_active:
                reduction = alloc.capital_allocated * (1 - target_pct)
                alloc.capital_allocated *= target_pct
                alloc.max_position *= target_pct
                actions.append({
                    "strategy": st.value,
                    "action": "reduce",
                    "reduction_amount": reduction,
                    "new_allocation": alloc.capital_allocated,
                })

        return {
            "action": "emergency_deleverage",
            "target_pct": target_pct,
            "strategies_affected": len(actions),
            "details": actions,
        }

    def gradual_deleverage(self, drawdown_pct: float) -> dict[str, Any]:
        """Gradual deleveraging based on portfolio drawdown."""
        if drawdown_pct < 0.03:
            return {"action": "none", "reason": "drawdown within normal bounds"}

        # Scale reduction with drawdown
        if drawdown_pct < 0.05:
            reduction = 0.10
        elif drawdown_pct < 0.08:
            reduction = 0.25
        elif drawdown_pct < 0.12:
            reduction = 0.50
        else:
            return self.emergency_deleverage(0.25)

        actions = []
        for st, alloc in self.allocations.items():
            if alloc.is_active:
                alloc.capital_allocated *= (1 - reduction)
                alloc.max_position *= (1 - reduction)
                actions.append({"strategy": st.value, "reduction_pct": reduction * 100})

        return {
            "action": "gradual_deleverage",
            "drawdown_pct": drawdown_pct,
            "reduction_pct": reduction * 100,
            "strategies_affected": len(actions),
        }

    def recovery_mode(self, days_in_drawdown: int) -> dict[str, Any]:
        """Transition to recovery mode after drawdown."""
        if days_in_drawdown < 5:
            return {"mode": "normal", "reason": "short drawdown duration"}

        # Shift to conservative strategies
        conservative = {
            StrategyType.MARKET_MAKING: 0.30,
            StrategyType.LIQUIDITY: 0.25,
            StrategyType.STAT_ARB: 0.20,
            StrategyType.MEAN_REVERSION: 0.15,
            StrategyType.PAIRS: 0.10,
        }

        # Reduce overall exposure
        exposure_reduction = min(0.5, days_in_drawdown * 0.05)
        deployable = self.total_capital * (1 - self.reserve_pct) * (1 - exposure_reduction)

        for st, weight in conservative.items():
            if st in self.allocations:
                self.allocations[st].weight = weight
                self.allocations[st].capital_allocated = deployable * weight

        return {
            "mode": "recovery",
            "days_in_drawdown": days_in_drawdown,
            "exposure_reduction_pct": exposure_reduction * 100,
            "deployable_capital": deployable,
            "strategy_shift": {s.value: w for s, w in conservative.items()},
        }

    def get_comprehensive_state(self) -> dict[str, Any]:
        """Get comprehensive system state for monitoring."""
        perf_summary = {}
        for st in StrategyType:
            perf = self.performance_tracker.get_performance(st)
            perf_summary[st.value] = {
                "sharpe": perf.rolling_sharpe,
                "max_dd": perf.max_drawdown,
                "win_rate": perf.win_rate,
            }

        return {
            "regime": self.current_regime.value,
            "routing_state": self.get_routing_state(),
            "performance": perf_summary,
            "risk_limits": self.risk_limit_manager.get_aggregate_status(),
            "total_capital": self.total_capital,
        }
