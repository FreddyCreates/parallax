from __future__ import annotations

from typing import Any

import matplotlib.pyplot as plt
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from .performance import PerformanceAnalyzer, PerformanceReport


class BacktestVisualizer:
    """Visualization and tearsheet generation for backtests."""

    def __init__(self, style: str = 'seaborn-v0_8-darkgrid') -> None:
        self.style = style

    def _performance_report(self, result: Any) -> PerformanceReport:
        if hasattr(result, 'performance') and isinstance(result.performance, PerformanceReport):
            return result.performance
        return PerformanceAnalyzer(result.equity_curve, result.trades, getattr(result, 'benchmark', None)).summary()

    def plot_equity_curve(self, result: Any, benchmark: pd.Series | None = None, interactive: bool = False):
        report = self._performance_report(result)
        frame = report.returns.copy()
        if interactive:
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=frame.index, y=frame['equity'], name='Equity'))
            if benchmark is not None:
                benchmark_curve = benchmark.reindex(frame.index).ffill()
                fig.add_trace(go.Scatter(x=benchmark_curve.index, y=benchmark_curve, name='Benchmark'))
            fig.update_layout(title='Equity Curve', xaxis_title='Date', yaxis_title='Equity')
            return fig

        plt.style.use(self.style)
        fig, ax = plt.subplots(figsize=(12, 5))
        ax.plot(frame.index, frame['equity'], label='Equity', linewidth=2)
        if benchmark is not None:
            benchmark_curve = benchmark.reindex(frame.index).ffill()
            ax.plot(benchmark_curve.index, benchmark_curve, label='Benchmark', alpha=0.8)
        ax.set_title('Equity Curve')
        ax.set_xlabel('Date')
        ax.set_ylabel('Equity')
        ax.legend()
        fig.tight_layout()
        return fig

    def plot_drawdown(self, result: Any, interactive: bool = False):
        report = self._performance_report(result)
        drawdowns = report.drawdowns
        if interactive:
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=drawdowns.index, y=drawdowns, fill='tozeroy', name='Drawdown'))
            fig.update_layout(title='Drawdown', xaxis_title='Date', yaxis_title='Drawdown')
            return fig

        plt.style.use(self.style)
        fig, ax = plt.subplots(figsize=(12, 4))
        ax.fill_between(drawdowns.index, drawdowns.values, 0.0, color='crimson', alpha=0.35)
        ax.set_title('Drawdown')
        ax.set_xlabel('Date')
        ax.set_ylabel('Drawdown')
        fig.tight_layout()
        return fig

    def plot_returns_distribution(self, result: Any, interactive: bool = False):
        report = self._performance_report(result)
        returns = report.returns['return']
        if interactive:
            fig = go.Figure(data=[go.Histogram(x=returns, nbinsx=40, name='Returns')])
            fig.update_layout(title='Returns Distribution', xaxis_title='Return', yaxis_title='Frequency')
            return fig

        plt.style.use(self.style)
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.hist(returns, bins=40, color='steelblue', alpha=0.85)
        ax.set_title('Returns Distribution')
        ax.set_xlabel('Return')
        ax.set_ylabel('Frequency')
        fig.tight_layout()
        return fig

    def plot_trade_analysis(self, result: Any, interactive: bool = False):
        trades = result.trades.copy()
        if trades.empty:
            raise ValueError('Trade analysis requires a non-empty trades DataFrame')
        trades['exit_time'] = pd.to_datetime(trades['exit_time'])
        if interactive:
            fig = make_subplots(rows=2, cols=1, shared_xaxes=True, subplot_titles=('Net PnL by Trade', 'Holding Period (days)'))
            fig.add_trace(go.Bar(x=trades['exit_time'], y=trades['net_pnl'], name='Net PnL'), row=1, col=1)
            if 'holding_period_days' in trades.columns:
                fig.add_trace(go.Scatter(x=trades['exit_time'], y=trades['holding_period_days'], mode='lines+markers', name='Holding Days'), row=2, col=1)
            fig.update_layout(height=700, title='Trade Analysis')
            return fig

        plt.style.use(self.style)
        fig, axes = plt.subplots(2, 1, figsize=(12, 7), sharex=True)
        axes[0].bar(trades['exit_time'], trades['net_pnl'], color='teal', alpha=0.8)
        axes[0].set_title('Net PnL by Trade')
        axes[0].set_ylabel('PnL')
        if 'holding_period_days' in trades.columns:
            axes[1].plot(trades['exit_time'], trades['holding_period_days'], marker='o')
        axes[1].set_title('Holding Period (days)')
        axes[1].set_ylabel('Days')
        axes[1].set_xlabel('Exit Time')
        fig.tight_layout()
        return fig

    def generate_tearsheet(self, result: Any, benchmark: pd.Series | None = None, interactive: bool = False) -> dict[str, Any]:
        report = self._performance_report(result)
        tearsheet = {
            'performance_summary': report.summary,
            'trade_statistics': report.trade_statistics,
            'monthly_returns': report.monthly_returns,
            'annual_returns': report.annual_returns,
            'equity_curve': self.plot_equity_curve(result, benchmark=benchmark, interactive=interactive),
            'drawdown': self.plot_drawdown(result, interactive=interactive),
            'returns_distribution': self.plot_returns_distribution(result, interactive=interactive),
        }
        if not result.trades.empty:
            tearsheet['trade_analysis'] = self.plot_trade_analysis(result, interactive=interactive)
        return tearsheet
