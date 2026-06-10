"""XBRL Engine — eXtensible Business Reporting Language.

Generates XBRL/iXBRL reports for regulatory compliance, fund NAV reporting,
and financial statement generation.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import date
from enum import Enum
from typing import Any


class XBRLTaxonomy(str, Enum):
    US_GAAP = "us-gaap"
    IFRS = "ifrs-full"
    SEC = "dei"
    FUND = "rr"  # Risk/Return (mutual fund)
    CIK = "cik"


class XBRLPeriodType(str, Enum):
    INSTANT = "instant"
    DURATION = "duration"


@dataclass
class XBRLFact:
    """Single XBRL fact/data point."""
    concept: str
    value: str | float
    taxonomy: XBRLTaxonomy = XBRLTaxonomy.US_GAAP
    period_type: XBRLPeriodType = XBRLPeriodType.INSTANT
    period_start: str = ""
    period_end: str = ""
    instant_date: str = ""
    unit: str = "USD"
    decimals: int = 2
    context_id: str = ""

    def __post_init__(self) -> None:
        if not self.context_id:
            self.context_id = f"ctx-{uuid.uuid4().hex[:8]}"
        if self.period_type == XBRLPeriodType.INSTANT and not self.instant_date:
            self.instant_date = date.today().isoformat()


@dataclass
class XBRLReport:
    """Complete XBRL filing/report."""
    report_id: str
    entity_name: str = "PARRALAX AI HFT FUND"
    entity_id: str = "PARRALAX-001"
    reporting_period_start: str = ""
    reporting_period_end: str = ""
    facts: list[XBRLFact] = field(default_factory=list)
    taxonomy: XBRLTaxonomy = XBRLTaxonomy.US_GAAP


class XBRLEngine:
    """XBRL report generation engine for fund regulatory compliance."""

    def __init__(self, entity_name: str = "PARRALAX AI HFT FUND") -> None:
        self.entity_name = entity_name
        self.reports: dict[str, XBRLReport] = {}

    def create_nav_report(
        self,
        nav: float,
        total_assets: float,
        total_liabilities: float,
        shares_outstanding: float,
        nav_per_share: float,
        reporting_date: str = "",
    ) -> XBRLReport:
        """Create Net Asset Value report for fund."""
        report_date = reporting_date or date.today().isoformat()
        report = XBRLReport(
            report_id=f"NAV-{report_date}",
            entity_name=self.entity_name,
            reporting_period_end=report_date,
        )

        report.facts = [
            XBRLFact(concept="rr:NetAssetValue", value=nav, taxonomy=XBRLTaxonomy.FUND,
                     instant_date=report_date),
            XBRLFact(concept="us-gaap:Assets", value=total_assets,
                     instant_date=report_date),
            XBRLFact(concept="us-gaap:Liabilities", value=total_liabilities,
                     instant_date=report_date),
            XBRLFact(concept="us-gaap:SharesOutstanding", value=shares_outstanding,
                     instant_date=report_date, unit="shares", decimals=0),
            XBRLFact(concept="rr:NetAssetValuePerShare", value=nav_per_share,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, decimals=4),
        ]

        self.reports[report.report_id] = report
        return report

    def create_pnl_report(
        self,
        revenue: float,
        trading_gains: float,
        management_fees: float,
        performance_fees: float,
        expenses: float,
        net_income: float,
        period_start: str = "",
        period_end: str = "",
    ) -> XBRLReport:
        """Create P&L / Income Statement report."""
        today = date.today()
        if not period_end:
            period_end = today.isoformat()
        if not period_start:
            period_start = date(today.year, today.month, 1).isoformat()

        report = XBRLReport(
            report_id=f"PNL-{period_end}",
            entity_name=self.entity_name,
            reporting_period_start=period_start,
            reporting_period_end=period_end,
        )

        report.facts = [
            XBRLFact(concept="us-gaap:Revenues", value=revenue,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
            XBRLFact(concept="us-gaap:RealizedGainLossOnInvestments", value=trading_gains,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
            XBRLFact(concept="us-gaap:ManagementFeeRevenue", value=management_fees,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
            XBRLFact(concept="us-gaap:IncentiveFeeRevenue", value=performance_fees,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
            XBRLFact(concept="us-gaap:OperatingExpenses", value=expenses,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
            XBRLFact(concept="us-gaap:NetIncomeLoss", value=net_income,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end),
        ]

        self.reports[report.report_id] = report
        return report

    def create_risk_disclosure(
        self,
        var_95: float,
        max_drawdown: float,
        sharpe_ratio: float,
        leverage_ratio: float,
        concentration_top5: float,
    ) -> XBRLReport:
        """Create risk metrics disclosure report."""
        report_date = date.today().isoformat()
        report = XBRLReport(
            report_id=f"RISK-{report_date}",
            entity_name=self.entity_name,
            reporting_period_end=report_date,
            taxonomy=XBRLTaxonomy.FUND,
        )

        report.facts = [
            XBRLFact(concept="rr:RiskValueAtRisk95", value=var_95,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, decimals=4),
            XBRLFact(concept="rr:RiskMaximumDrawdown", value=max_drawdown,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, decimals=4),
            XBRLFact(concept="rr:RiskSharpeRatio", value=sharpe_ratio,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, unit="ratio", decimals=4),
            XBRLFact(concept="rr:RiskLeverageRatio", value=leverage_ratio,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, unit="ratio", decimals=2),
            XBRLFact(concept="rr:RiskConcentrationTop5", value=concentration_top5,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=report_date, decimals=4),
        ]

        self.reports[report.report_id] = report
        return report

    def to_xbrl_xml(self, report: XBRLReport) -> str:
        """Generate XBRL XML instance document."""
        facts_xml = []
        for fact in report.facts:
            if fact.period_type == XBRLPeriodType.INSTANT:
                period = f"<xbrli:instant>{fact.instant_date}</xbrli:instant>"
            else:
                period = (
                    f"<xbrli:startDate>{fact.period_start}</xbrli:startDate>"
                    f"<xbrli:endDate>{fact.period_end}</xbrli:endDate>"
                )

            facts_xml.append(
                f'  <{fact.taxonomy.value}:{fact.concept.split(":")[-1]} '
                f'contextRef="{fact.context_id}" unitRef="{fact.unit}" '
                f'decimals="{fact.decimals}">{fact.value}'
                f'</{fact.taxonomy.value}:{fact.concept.split(":")[-1]}>'
            )

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance"
            xmlns:us-gaap="http://fasb.org/us-gaap/2024"
            xmlns:rr="http://xbrl.sec.gov/rr/2024"
            xmlns:dei="http://xbrl.sec.gov/dei/2024">
  <xbrli:context id="ctx-entity">
    <xbrli:entity>
      <xbrli:identifier scheme="http://www.parralax.ai">{report.entity_id}</xbrli:identifier>
    </xbrli:entity>
    <xbrli:period>
      {f'<xbrli:instant>{report.reporting_period_end}</xbrli:instant>' if not report.reporting_period_start else f'<xbrli:startDate>{report.reporting_period_start}</xbrli:startDate><xbrli:endDate>{report.reporting_period_end}</xbrli:endDate>'}
    </xbrli:period>
  </xbrli:context>
  <xbrli:unit id="USD"><xbrli:measure>iso4217:USD</xbrli:measure></xbrli:unit>
  <xbrli:unit id="shares"><xbrli:measure>xbrli:shares</xbrli:measure></xbrli:unit>
  <xbrli:unit id="ratio"><xbrli:measure>xbrli:pure</xbrli:measure></xbrli:unit>
{"chr(10)".join(facts_xml)}
</xbrli:xbrl>"""
