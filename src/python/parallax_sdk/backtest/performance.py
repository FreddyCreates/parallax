from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(slots=True)
class PerformanceReport:
    summary: dict[str, float]
    returns: pd.DataFrame
    drawdowns: pd.Series
    monthly_returns: pd.Series
    annual_returns: pd.Series
    trade_statistics: dict[str, float]
    equity_curve: pd.DataFrame


class PerformanceAnalyzer:
    """Performance analytics for backtest equity curves and trade logs."""

    def __init__(
        self,
        equity_curve: pd.DataFrame,
        trades: pd.DataFrame | None = None,
        benchmark: pd.Series | pd.DataFrame | None = None,
        risk_free_rate: float = 0.0,
        periods_per_year: int = 252,
    ) -> None:
        self.equity_curve = self._prepare_equity_curve(equity_curve)
        self.trades = trades.copy() if trades is not None else pd.DataFrame()
        self.benchmark = self._prepare_benchmark(benchmark)
        self.risk_free_rate = float(risk_free_rate)
        self.periods_per_year = periods_per_year

    @staticmethod
    def _prepare_equity_curve(equity_curve: pd.DataFrame) -> pd.DataFrame:
        curve = equity_curve.copy()
        if 'timestamp' in curve.columns:
            curve['timestamp'] = pd.to_datetime(curve['timestamp'])
            curve = curve.set_index('timestamp')
        if not isinstance(curve.index, pd.DatetimeIndex):
            curve.index = pd.to_datetime(curve.index)
        curve = curve.sort_index()
        if 'equity' not in curve.columns:
            raise ValueError('equity_curve must contain an equity column')
        curve['equity'] = curve['equity'].astype(float)
        return curve

    def _prepare_benchmark(self, benchmark: pd.Series | pd.DataFrame | None) -> pd.Series | None:
        if benchmark is None:
            return None
        if isinstance(benchmark, pd.DataFrame):
            series = benchmark.iloc[:, 0]
        else:
            series = benchmark.copy()
        series.index = pd.to_datetime(series.index)
        return series.sort_index().astype(float)

    def returns_frame(self) -> pd.DataFrame:
        equity = self.equity_curve['equity']
        returns = equity.pct_change().fillna(0.0)
        log_returns = np.log1p(returns)
        absolute_returns = equity.diff().fillna(0.0)
        frame = pd.DataFrame(
            {
                'equity': equity,
                'absolute_return': absolute_returns,
                'return': returns,
                'log_return': log_returns,
                'cumulative_return': (1.0 + returns).cumprod() - 1.0,
            },
            index=self.equity_curve.index,
        )
        if self.benchmark is not None:
            benchmark_returns = self.benchmark.reindex(frame.index).ffill().pct_change().fillna(0.0)
            frame['benchmark_return'] = benchmark_returns
            frame['excess_return'] = returns - benchmark_returns
        else:
            frame['excess_return'] = returns - (self.risk_free_rate / self.periods_per_year)
        return frame

    def drawdown_series(self) -> pd.Series:
        equity = self.equity_curve['equity']
        peaks = equity.cummax()
        return equity / peaks - 1.0

    def sharpe_ratio(self, returns: pd.Series) -> float:
        excess = returns - (self.risk_free_rate / self.periods_per_year)
        volatility = excess.std(ddof=0)
        if volatility == 0 or np.isnan(volatility):
            return 0.0
        return float(np.sqrt(self.periods_per_year) * excess.mean() / volatility)

    def sortino_ratio(self, returns: pd.Series) -> float:
        excess = returns - (self.risk_free_rate / self.periods_per_year)
        downside = excess[excess < 0]
        downside_deviation = downside.std(ddof=0)
        if downside_deviation == 0 or np.isnan(downside_deviation):
            return 0.0
        return float(np.sqrt(self.periods_per_year) * excess.mean() / downside_deviation)

    def max_drawdown(self, drawdowns: pd.Series) -> float:
        return float(drawdowns.min()) if not drawdowns.empty else 0.0

    def calmar_ratio(self, returns: pd.Series, max_drawdown: float) -> float:
        if max_drawdown == 0:
            return 0.0
        cumulative = float((1.0 + returns).prod())
        annualized = cumulative ** (self.periods_per_year / max(len(returns), 1)) - 1.0
        return float(annualized / abs(max_drawdown))

    def trade_statistics(self) -> dict[str, float]:
        if self.trades.empty or 'net_pnl' not in self.trades.columns:
            return {
                'trade_count': 0.0,
                'win_rate': 0.0,
                'profit_factor': 0.0,
                'average_trade': 0.0,
                'average_win': 0.0,
                'average_loss': 0.0,
                'expectancy': 0.0,
                'payoff_ratio': 0.0,
                'average_holding_period_days': 0.0,
            }

        trades = self.trades.copy()
        trades['net_pnl'] = trades['net_pnl'].astype(float)
        wins = trades[trades['net_pnl'] > 0]
        losses = trades[trades['net_pnl'] < 0]
        gross_profit = wins['net_pnl'].sum()
        gross_loss = losses['net_pnl'].sum()
        average_win = wins['net_pnl'].mean() if not wins.empty else 0.0
        average_loss = losses['net_pnl'].mean() if not losses.empty else 0.0
        win_rate = len(wins) / len(trades) if len(trades) else 0.0
        profit_factor = gross_profit / abs(gross_loss) if gross_loss != 0 else float('inf') if gross_profit > 0 else 0.0
        payoff_ratio = average_win / abs(average_loss) if average_loss not in {0, 0.0} else 0.0

        if {'entry_time', 'exit_time'}.issubset(trades.columns):
            holding = pd.to_datetime(trades['exit_time']) - pd.to_datetime(trades['entry_time'])
            avg_holding_days = float(holding.dt.total_seconds().mean() / 86400.0) if not holding.empty else 0.0
        else:
            avg_holding_days = 0.0

        return {
            'trade_count': float(len(trades)),
            'win_rate': float(win_rate),
            'profit_factor': float(profit_factor),
            'average_trade': float(trades['net_pnl'].mean()),
            'average_win': float(average_win),
            'average_loss': float(average_loss),
            'expectancy': float(trades['net_pnl'].mean()),
            'payoff_ratio': float(payoff_ratio),
            'average_holding_period_days': avg_holding_days,
        }

    def monthly_returns_breakdown(self, returns: pd.Series) -> pd.Series:
        return ((1.0 + returns).resample('ME').prod() - 1.0).rename('monthly_return')

    def annual_returns_breakdown(self, returns: pd.Series) -> pd.Series:
        return ((1.0 + returns).resample('YE').prod() - 1.0).rename('annual_return')

    def equity_curve_analysis(self, returns: pd.Series) -> dict[str, float]:
        equity = self.equity_curve['equity']
        total_return = equity.iloc[-1] / equity.iloc[0] - 1.0 if len(equity) > 1 else 0.0
        annualized_return = (1.0 + total_return) ** (self.periods_per_year / max(len(returns), 1)) - 1.0
        annualized_volatility = float(returns.std(ddof=0) * np.sqrt(self.periods_per_year))
        return {
            'starting_equity': float(equity.iloc[0]),
            'ending_equity': float(equity.iloc[-1]),
            'total_return': float(total_return),
            'annualized_return': float(annualized_return),
            'annualized_volatility': annualized_volatility,
            'best_period_return': float(returns.max()) if not returns.empty else 0.0,
            'worst_period_return': float(returns.min()) if not returns.empty else 0.0,
            'positive_periods': float((returns > 0).sum()),
            'negative_periods': float((returns < 0).sum()),
        }

    def summary(self) -> PerformanceReport:
        returns = self.returns_frame()
        drawdowns = self.drawdown_series()
        stats = self.trade_statistics()
        equity_stats = self.equity_curve_analysis(returns['return'])
        summary = {
            **equity_stats,
            'sharpe_ratio': self.sharpe_ratio(returns['return']),
            'sortino_ratio': self.sortino_ratio(returns['return']),
            'max_drawdown': self.max_drawdown(drawdowns),
            'calmar_ratio': self.calmar_ratio(returns['return'], self.max_drawdown(drawdowns)),
            'win_rate': stats['win_rate'],
            'profit_factor': stats['profit_factor'],
        }
        return PerformanceReport(
            summary=summary,
            returns=returns,
            drawdowns=drawdowns,
            monthly_returns=self.monthly_returns_breakdown(returns['return']),
            annual_returns=self.annual_returns_breakdown(returns['return']),
            trade_statistics=stats,
            equity_curve=self.equity_curve,
        )
