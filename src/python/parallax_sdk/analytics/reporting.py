from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path
from typing import Any, Mapping

import matplotlib.image as mpimg
import matplotlib.pyplot as plt
import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.figure import Figure


@dataclass(slots=True)
class GeneratedReport:
    title: str
    created_at: datetime
    sections: dict[str, Any]
    metrics: dict[str, float] = field(default_factory=dict)
    figures: dict[str, Any] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)


class ReportGenerator:
    """Automated report assembly and export infrastructure."""

    def generate_report(
        self,
        title: str,
        analytics_payload: Mapping[str, Any],
        *,
        metrics: Mapping[str, float] | None = None,
        figures: Mapping[str, Any] | None = None,
        metadata: Mapping[str, Any] | None = None,
    ) -> GeneratedReport:
        return self.automated_report_generation(
            title,
            analytics_payload,
            metrics=metrics,
            figures=figures,
            metadata=metadata,
        )

    def automated_report_generation(
        self,
        title: str,
        analytics_payload: Mapping[str, Any],
        *,
        metrics: Mapping[str, float] | None = None,
        figures: Mapping[str, Any] | None = None,
        metadata: Mapping[str, Any] | None = None,
    ) -> GeneratedReport:
        return GeneratedReport(
            title=title,
            created_at=datetime.now(timezone.utc),
            sections=dict(analytics_payload),
            metrics=dict(metrics or {}),
            figures=dict(figures or {}),
            metadata=dict(metadata or {}),
        )

    def historical_analysis(self, history: pd.DataFrame, frequency: str = "M") -> pd.DataFrame:
        frame = history.copy()
        frame.index = pd.to_datetime(frame.index)
        frame = frame.sort_index()
        summary = frame.resample(frequency).agg(["mean", "std", "min", "max", "last"])
        summary.columns = ["_".join(column).strip("_") for column in summary.columns.to_flat_index()]
        return summary

    def real_time_metrics(self, metrics_frame: pd.DataFrame, window: int = 20) -> pd.DataFrame:
        frame = metrics_frame.copy()
        frame.index = pd.to_datetime(frame.index)
        numeric = frame.select_dtypes(include=["number"]).copy()
        if numeric.empty:
            raise ValueError("metrics_frame must contain numeric columns")
        rolling_mean = numeric.rolling(window=window, min_periods=1).mean().add_suffix("_rolling_mean")
        rolling_std = numeric.rolling(window=window, min_periods=1).std(ddof=0).fillna(0.0).add_suffix("_rolling_std")
        z_scores = ((numeric - numeric.mean()) / numeric.std(ddof=0).replace(0.0, pd.NA)).fillna(0.0).add_suffix("_zscore")
        return pd.concat([numeric, rolling_mean, rolling_std, z_scores], axis=1)

    def interactive_dashboards(self, figures: Mapping[str, Any], title: str = "PARALLAX Dashboard") -> str:
        sections = [f"<h1>{title}</h1>"]
        for name, figure in figures.items():
            sections.append(f"<h2>{name}</h2>")
            if isinstance(figure, go.Figure):
                sections.append(pio.to_html(figure, include_plotlyjs="cdn", full_html=False))
            else:
                sections.append(f"<pre>{figure}</pre>")
        return "\n".join(sections)

    def export_html(self, report: GeneratedReport, output_path: str | Path) -> Path:
        target = Path(output_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        parts = [
            "<html><head><meta charset='utf-8'><title>{}</title></head><body>".format(report.title),
            f"<h1>{report.title}</h1>",
            f"<p>Generated: {report.created_at.isoformat()}</p>",
        ]
        if report.metrics:
            parts.append("<h2>Metrics</h2><ul>")
            parts.extend([f"<li><strong>{key}</strong>: {value}</li>" for key, value in report.metrics.items()])
            parts.append("</ul>")
        for name, section in report.sections.items():
            parts.append(f"<h2>{name}</h2>")
            if isinstance(section, pd.DataFrame):
                parts.append(section.to_html(border=0))
            elif isinstance(section, pd.Series):
                parts.append(section.to_frame(name=section.name or name).to_html(border=0))
            else:
                parts.append(f"<pre>{section}</pre>")
        if report.figures:
            parts.append(self.interactive_dashboards(report.figures, title="Visualizations"))
        parts.append("</body></html>")
        target.write_text("\n".join(parts), encoding="utf-8")
        return target

    def _pdf_text_page(self, pdf: PdfPages, title: str, body: str) -> None:
        fig, ax = plt.subplots(figsize=(8.27, 11.69))
        ax.axis("off")
        ax.text(0.03, 0.97, title, va="top", ha="left", fontsize=16, fontweight="bold")
        ax.text(0.03, 0.92, body, va="top", ha="left", fontsize=10, wrap=True)
        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

    def _pdf_dataframe_page(self, pdf: PdfPages, title: str, frame: pd.DataFrame) -> None:
        fig, ax = plt.subplots(figsize=(11.69, 8.27))
        ax.axis("off")
        ax.set_title(title)
        preview = frame.head(20).round(6)
        table = ax.table(cellText=preview.values, colLabels=preview.columns, rowLabels=preview.index.astype(str), loc="center")
        table.auto_set_font_size(False)
        table.set_fontsize(8)
        table.scale(1, 1.2)
        pdf.savefig(fig, bbox_inches="tight")
        plt.close(fig)

    def _pdf_plotly_page(self, pdf: PdfPages, title: str, figure: go.Figure) -> None:
        try:
            image_bytes = figure.to_image(format="png")
            image = mpimg.imread(BytesIO(image_bytes), format="png")
            fig, ax = plt.subplots(figsize=(11.69, 8.27))
            ax.imshow(image)
            ax.axis("off")
            ax.set_title(title)
            pdf.savefig(fig, bbox_inches="tight")
            plt.close(fig)
        except Exception:
            self._pdf_text_page(pdf, title, "Plotly image export unavailable in this environment; view the HTML report for the interactive chart.")

    def export_pdf(self, report: GeneratedReport, output_path: str | Path) -> Path:
        target = Path(output_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        with PdfPages(target) as pdf:
            self._pdf_text_page(
                pdf,
                report.title,
                "Generated: {}\n\nMetrics:\n{}".format(
                    report.created_at.isoformat(),
                    "\n".join(f"- {key}: {value}" for key, value in report.metrics.items()) or "No metrics supplied.",
                ),
            )
            for name, section in report.sections.items():
                if isinstance(section, pd.DataFrame):
                    self._pdf_dataframe_page(pdf, name, section)
                elif isinstance(section, pd.Series):
                    self._pdf_dataframe_page(pdf, name, section.to_frame(name=section.name or name))
                else:
                    self._pdf_text_page(pdf, name, str(section))
            for name, figure in report.figures.items():
                if isinstance(figure, Figure):
                    pdf.savefig(figure, bbox_inches="tight")
                elif isinstance(figure, go.Figure):
                    self._pdf_plotly_page(pdf, name, figure)
                else:
                    self._pdf_text_page(pdf, name, str(figure))
        return target
