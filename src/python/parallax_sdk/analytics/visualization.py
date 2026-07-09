from __future__ import annotations

import math
from typing import Iterable

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import plotly.graph_objects as go


class AnalyticsVisualizer:
    """Interactive and static visualizations for analytics workflows."""

    def interactive_chart(
        self,
        data: pd.DataFrame | pd.Series,
        *,
        title: str = "Interactive Chart",
        chart_type: str = "line",
    ) -> go.Figure:
        frame = data.to_frame() if isinstance(data, pd.Series) else data.copy()
        frame.index = pd.to_datetime(frame.index)
        fig = go.Figure()
        for column in frame.columns:
            if chart_type == "bar":
                fig.add_trace(go.Bar(x=frame.index, y=frame[column], name=str(column)))
            elif chart_type == "area":
                fig.add_trace(go.Scatter(x=frame.index, y=frame[column], mode="lines", stackgroup="one", name=str(column)))
            else:
                fig.add_trace(go.Scatter(x=frame.index, y=frame[column], mode="lines", name=str(column)))
        fig.update_layout(title=title, xaxis_title="Time", yaxis_title="Value", hovermode="x unified")
        return fig

    def risk_heatmap(self, matrix: pd.DataFrame, *, interactive: bool = True):
        frame = matrix.copy().astype(float)
        if interactive:
            fig = go.Figure(
                data=go.Heatmap(
                    z=frame.to_numpy(),
                    x=list(frame.columns),
                    y=list(frame.index),
                    colorscale="RdBu",
                    zmid=0.0,
                )
            )
            fig.update_layout(title="Risk Heatmap")
            return fig
        fig, ax = plt.subplots(figsize=(8, 6))
        image = ax.imshow(frame.to_numpy(), cmap="RdBu", aspect="auto")
        ax.set_xticks(range(len(frame.columns)), frame.columns, rotation=45, ha="right")
        ax.set_yticks(range(len(frame.index)), frame.index)
        ax.set_title("Risk Heatmap")
        plt.colorbar(image, ax=ax)
        fig.tight_layout()
        return fig

    def correlation_matrix(self, data: pd.DataFrame, *, method: str = "pearson", interactive: bool = True):
        correlation = data.corr(method=method)
        return self.risk_heatmap(correlation, interactive=interactive)

    def network_graph_for_flows(self, flows: pd.DataFrame, *, interactive: bool = True):
        required = {"source", "target", "value"}
        if not required.issubset(flows.columns):
            raise ValueError("flows must contain source, target, and value columns")
        nodes = sorted(set(flows["source"]).union(set(flows["target"])))
        positions = {
            node: (
                math.cos(2 * math.pi * idx / max(len(nodes), 1)),
                math.sin(2 * math.pi * idx / max(len(nodes), 1)),
            )
            for idx, node in enumerate(nodes)
        }
        edge_x: list[float] = []
        edge_y: list[float] = []
        for row in flows.itertuples(index=False):
            x0, y0 = positions[row.source]
            x1, y1 = positions[row.target]
            edge_x.extend([x0, x1, None])
            edge_y.extend([y0, y1, None])
        node_x = [positions[node][0] for node in nodes]
        node_y = [positions[node][1] for node in nodes]
        if interactive:
            fig = go.Figure()
            fig.add_trace(go.Scatter(x=edge_x, y=edge_y, mode="lines", line=dict(width=1, color="#888"), hoverinfo="none"))
            fig.add_trace(
                go.Scatter(
                    x=node_x,
                    y=node_y,
                    mode="markers+text",
                    text=nodes,
                    textposition="top center",
                    marker=dict(size=20, color="#1f77b4"),
                    hoverinfo="text",
                )
            )
            fig.update_layout(title="Flow Network", showlegend=False, xaxis=dict(visible=False), yaxis=dict(visible=False))
            return fig
        fig, ax = plt.subplots(figsize=(8, 8))
        ax.plot(edge_x, edge_y, color="#888", linewidth=1)
        ax.scatter(node_x, node_y, s=300, c="#1f77b4")
        for node, x, y in zip(nodes, node_x, node_y):
            ax.text(x, y, node, ha="center", va="bottom")
        ax.set_title("Flow Network")
        ax.axis("off")
        fig.tight_layout()
        return fig

    def volatility_surface_3d(
        self,
        surface: pd.DataFrame,
        *,
        interactive: bool = True,
    ):
        frame = surface.copy().astype(float)
        x = np.asarray(frame.columns, dtype=float)
        y = np.asarray(frame.index, dtype=float)
        z = frame.to_numpy()
        if interactive:
            fig = go.Figure(data=[go.Surface(x=x, y=y, z=z, colorscale="Viridis")])
            fig.update_layout(title="Volatility Surface", scene=dict(xaxis_title="Tenor", yaxis_title="Moneyness", zaxis_title="Volatility"))
            return fig
        fig = plt.figure(figsize=(10, 6))
        ax = fig.add_subplot(111, projection="3d")
        xx, yy = np.meshgrid(x, y)
        ax.plot_surface(xx, yy, z, cmap="viridis")
        ax.set_title("Volatility Surface")
        ax.set_xlabel("Tenor")
        ax.set_ylabel("Moneyness")
        ax.set_zlabel("Volatility")
        fig.tight_layout()
        return fig
