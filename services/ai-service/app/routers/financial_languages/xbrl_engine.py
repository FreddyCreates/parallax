"""XBRL Engine — eXtensible Business Reporting Language.

Generates XBRL/iXBRL reports for regulatory compliance, fund NAV reporting,
and financial statement generation. Supports SEC EDGAR submissions, XBRL-JSON (OIM),
dimensional reporting, and calculation linkbase validation.
"""

from __future__ import annotations

import json
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


class XBRLFormType(str, Enum):
    FORM_10K = "10-K"
    FORM_10Q = "10-Q"
    FORM_N_CSR = "N-CSR"
    FORM_N_CEN = "N-CEN"
    FORM_N_PORT = "N-PORT"
    FORM_8K = "8-K"
    FORM_ADV = "ADV"


@dataclass
class XBRLDimension:
    """XBRL dimensional qualifier (segment/scenario)."""
    dimension_name: str
    member_name: str
    taxonomy: XBRLTaxonomy = XBRLTaxonomy.US_GAAP
    is_typed: bool = False
    typed_value: str = ""


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
    dimensions: list[XBRLDimension] = field(default_factory=list)

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
    cik: str = "0001234567"
    form_type: XBRLFormType = XBRLFormType.FORM_N_CSR
    reporting_period_start: str = ""
    reporting_period_end: str = ""
    filing_date: str = ""
    facts: list[XBRLFact] = field(default_factory=list)
    taxonomy: XBRLTaxonomy = XBRLTaxonomy.US_GAAP
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass
class XBRLFilingPackage:
    """Batch filing package containing multiple reports."""
    package_id: str
    filer_name: str
    cik: str
    form_type: XBRLFormType
    filing_date: str
    reports: list[XBRLReport] = field(default_factory=list)
    attachments: list[str] = field(default_factory=list)


# Known valid concepts per taxonomy for validation
_TAXONOMY_CONCEPTS: dict[str, set[str]] = {
    "us-gaap": {
        "Assets", "Liabilities", "Revenues", "NetIncomeLoss",
        "SharesOutstanding", "RealizedGainLossOnInvestments",
        "ManagementFeeRevenue", "IncentiveFeeRevenue", "OperatingExpenses",
        "CashAndCashEquivalents", "StockholdersEquity", "RetainedEarnings",
        "InvestmentIncomeInterest", "UnrealizedGainLossOnInvestments",
        "TotalExpenses", "GrossProfit", "OperatingIncomeLoss",
    },
    "rr": {
        "NetAssetValue", "NetAssetValuePerShare", "RiskValueAtRisk95",
        "RiskMaximumDrawdown", "RiskSharpeRatio", "RiskLeverageRatio",
        "RiskConcentrationTop5", "AnnualReturn", "ExpenseRatio",
        "ManagementFees", "PerformanceFees", "TotalReturn",
        "BenchmarkReturn", "TrackingError", "InformationRatio",
        "MaxDrawdown", "CalmarRatio", "SortinoRatio",
    },
    "dei": {
        "EntityRegistrantName", "EntityCentralIndexKey", "DocumentType",
        "DocumentPeriodEndDate", "DocumentFiscalYearFocus",
        "DocumentFiscalPeriodFocus", "AmendmentFlag",
    },
    "ifrs-full": {
        "Assets", "Liabilities", "Revenue", "ProfitLoss",
        "ComprehensiveIncome", "Equity", "CashAndCashEquivalents",
    },
}

# Calculation relationships: parent = sum of children
_CALCULATION_LINKBASE: dict[str, list[tuple[str, float]]] = {
    "us-gaap:Assets": [
        ("us-gaap:CashAndCashEquivalents", 1.0),
        ("us-gaap:Investments", 1.0),
    ],
    "us-gaap:NetIncomeLoss": [
        ("us-gaap:Revenues", 1.0),
        ("us-gaap:OperatingExpenses", -1.0),
    ],
    "rr:NetAssetValue": [
        ("us-gaap:Assets", 1.0),
        ("us-gaap:Liabilities", -1.0),
    ],
}


class XBRLEngine:
    """XBRL report generation engine for fund regulatory compliance."""

    def __init__(
        self,
        entity_name: str = "PARRALAX AI HFT FUND",
        cik: str = "0001234567",
    ) -> None:
        self.entity_name = entity_name
        self.cik = cik
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
            cik=self.cik,
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
            cik=self.cik,
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
            cik=self.cik,
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

    def create_fund_performance_report(
        self,
        annual_return: float,
        benchmark_return: float,
        expense_ratio: float,
        management_fee_rate: float,
        performance_fee_rate: float,
        tracking_error: float,
        information_ratio: float,
        max_drawdown: float,
        calmar_ratio: float,
        sortino_ratio: float,
        period_start: str = "",
        period_end: str = "",
    ) -> XBRLReport:
        """Create fund performance report with returns, benchmarks, expense ratios."""
        today = date.today()
        if not period_end:
            period_end = today.isoformat()
        if not period_start:
            period_start = date(today.year, 1, 1).isoformat()

        report = XBRLReport(
            report_id=f"PERF-{period_end}",
            entity_name=self.entity_name,
            cik=self.cik,
            form_type=XBRLFormType.FORM_N_CSR,
            reporting_period_start=period_start,
            reporting_period_end=period_end,
            taxonomy=XBRLTaxonomy.FUND,
        )

        report.facts = [
            XBRLFact(concept="rr:AnnualReturn", value=annual_return,
                     taxonomy=XBRLTaxonomy.FUND,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:BenchmarkReturn", value=benchmark_return,
                     taxonomy=XBRLTaxonomy.FUND,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:ExpenseRatio", value=expense_ratio,
                     taxonomy=XBRLTaxonomy.FUND,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:ManagementFees", value=management_fee_rate,
                     taxonomy=XBRLTaxonomy.FUND,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:PerformanceFees", value=performance_fee_rate,
                     taxonomy=XBRLTaxonomy.FUND,
                     period_type=XBRLPeriodType.DURATION,
                     period_start=period_start, period_end=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:TrackingError", value=tracking_error,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:InformationRatio", value=information_ratio,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:MaxDrawdown", value=max_drawdown,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:CalmarRatio", value=calmar_ratio,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=period_end,
                     unit="ratio", decimals=4),
            XBRLFact(concept="rr:SortinoRatio", value=sortino_ratio,
                     taxonomy=XBRLTaxonomy.FUND, instant_date=period_end,
                     unit="ratio", decimals=4),
        ]

        self.reports[report.report_id] = report
        return report

    def create_comparative_report(
        self,
        periods: list[dict[str, Any]],
    ) -> XBRLReport:
        """Create multi-period comparison report.

        Args:
            periods: List of dicts with keys: period_start, period_end, facts (list of concept/value dicts)
        """
        report = XBRLReport(
            report_id=f"COMP-{date.today().isoformat()}",
            entity_name=self.entity_name,
            cik=self.cik,
        )

        for i, period in enumerate(periods):
            p_start = period.get("period_start", "")
            p_end = period.get("period_end", date.today().isoformat())
            for fact_data in period.get("facts", []):
                fact = XBRLFact(
                    concept=fact_data["concept"],
                    value=fact_data["value"],
                    taxonomy=XBRLTaxonomy(fact_data.get("taxonomy", "us-gaap")),
                    period_type=XBRLPeriodType.DURATION if p_start else XBRLPeriodType.INSTANT,
                    period_start=p_start,
                    period_end=p_end,
                    instant_date=p_end if not p_start else "",
                    unit=fact_data.get("unit", "USD"),
                    decimals=fact_data.get("decimals", 2),
                    context_id=f"ctx-period{i}-{uuid.uuid4().hex[:6]}",
                )
                report.facts.append(fact)

        self.reports[report.report_id] = report
        return report

    def create_batch_filing(
        self,
        report_ids: list[str] | None = None,
        form_type: XBRLFormType = XBRLFormType.FORM_N_CSR,
    ) -> XBRLFilingPackage:
        """Aggregate multiple reports into a single filing package."""
        filing_date = date.today().isoformat()
        package = XBRLFilingPackage(
            package_id=f"FILING-{uuid.uuid4().hex[:12].upper()}",
            filer_name=self.entity_name,
            cik=self.cik,
            form_type=form_type,
            filing_date=filing_date,
        )

        ids = report_ids or list(self.reports.keys())
        for rid in ids:
            if rid in self.reports:
                report = self.reports[rid]
                report.filing_date = filing_date
                report.form_type = form_type
                package.reports.append(report)

        return package

    def validate_taxonomy(self, facts: list[XBRLFact]) -> list[dict[str, str]]:
        """Validate that concept names exist in registered taxonomies."""
        errors: list[dict[str, str]] = []
        for fact in facts:
            taxonomy_key = fact.taxonomy.value
            concept_local = fact.concept.split(":")[-1] if ":" in fact.concept else fact.concept
            known = _TAXONOMY_CONCEPTS.get(taxonomy_key, set())
            if known and concept_local not in known:
                errors.append({
                    "concept": fact.concept,
                    "taxonomy": taxonomy_key,
                    "error": f"Concept '{concept_local}' not found in taxonomy '{taxonomy_key}'",
                })
        return errors

    def validate_calculations(self, report: XBRLReport) -> list[dict[str, Any]]:
        """Validate mathematical relationships in calculation linkbase."""
        errors: list[dict[str, Any]] = []
        fact_values: dict[str, float] = {}
        for fact in report.facts:
            if isinstance(fact.value, (int, float)):
                fact_values[fact.concept] = float(fact.value)

        for parent, children in _CALCULATION_LINKBASE.items():
            if parent in fact_values:
                expected = sum(
                    fact_values.get(child, 0) * weight
                    for child, weight in children
                    if child in fact_values
                )
                if children and any(c in fact_values for c, _ in children):
                    actual = fact_values[parent]
                    if abs(actual - expected) > 0.01:
                        errors.append({
                            "parent": parent,
                            "expected": expected,
                            "actual": actual,
                            "difference": actual - expected,
                        })

        return errors

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

            # Dimensional qualifiers
            dim_xml = ""
            if fact.dimensions:
                segments = []
                for dim in fact.dimensions:
                    segments.append(
                        f'        <xbrldi:explicitMember dimension="{dim.taxonomy.value}:'
                        f'{dim.dimension_name}">{dim.taxonomy.value}:{dim.member_name}'
                        f'</xbrldi:explicitMember>'
                    )
                dim_xml = (
                    "\n      <xbrli:segment>\n" + "\n".join(segments) + "\n      </xbrli:segment>"
                )

            facts_xml.append(
                f'  <{fact.taxonomy.value}:{fact.concept.split(":")[-1]} '
                f'contextRef="{fact.context_id}" unitRef="{fact.unit}" '
                f'decimals="{fact.decimals}">{fact.value}'
                f'</{fact.taxonomy.value}:{fact.concept.split(":")[-1]}>'
            )

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<xbrli:xbrl xmlns:xbrli="http://www.xbrl.org/2003/instance"
            xmlns:xbrldi="http://xbrl.org/2006/xbrldi"
            xmlns:us-gaap="http://fasb.org/us-gaap/2024"
            xmlns:rr="http://xbrl.sec.gov/rr/2024"
            xmlns:dei="http://xbrl.sec.gov/dei/2024"
            xmlns:ifrs-full="http://www.ifrs.org/taxonomy/2024">
  <xbrli:context id="ctx-entity">
    <xbrli:entity>
      <xbrli:identifier scheme="http://www.sec.gov/CIK">{report.cik}</xbrli:identifier>
    </xbrli:entity>
    <xbrli:period>
      {f'<xbrli:instant>{report.reporting_period_end}</xbrli:instant>' if not report.reporting_period_start else f'<xbrli:startDate>{report.reporting_period_start}</xbrli:startDate><xbrli:endDate>{report.reporting_period_end}</xbrli:endDate>'}
    </xbrli:period>
  </xbrli:context>
  <xbrli:unit id="USD"><xbrli:measure>iso4217:USD</xbrli:measure></xbrli:unit>
  <xbrli:unit id="shares"><xbrli:measure>xbrli:shares</xbrli:measure></xbrli:unit>
  <xbrli:unit id="ratio"><xbrli:measure>xbrli:pure</xbrli:measure></xbrli:unit>
{chr(10).join(facts_xml)}
</xbrli:xbrl>"""

    def to_ixbrl_html(self, report: XBRLReport) -> str:
        """Generate iXBRL (inline XBRL) HTML document with embedded facts."""
        rows = []
        for fact in report.facts:
            concept_local = fact.concept.split(":")[-1] if ":" in fact.concept else fact.concept
            label = concept_local.replace("_", " ").title()

            if isinstance(fact.value, (int, float)):
                tag = "ix:nonFraction"
                fmt_value = f"{fact.value:,.{fact.decimals}f}"
                attrs = (
                    f'name="{fact.concept}" contextRef="{fact.context_id}" '
                    f'unitRef="{fact.unit}" decimals="{fact.decimals}" '
                    f'format="ixt:num-dot-decimal"'
                )
            else:
                tag = "ix:nonNumeric"
                fmt_value = str(fact.value)
                attrs = f'name="{fact.concept}" contextRef="{fact.context_id}"'

            rows.append(
                f'      <tr><td>{label}</td>'
                f'<td><{tag} {attrs}>{fmt_value}</{tag}></td></tr>'
            )

        return f"""<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:ix="http://www.xbrl.org/2013/inlineXBRL"
      xmlns:xbrli="http://www.xbrl.org/2003/instance"
      xmlns:us-gaap="http://fasb.org/us-gaap/2024"
      xmlns:rr="http://xbrl.sec.gov/rr/2024"
      xmlns:dei="http://xbrl.sec.gov/dei/2024">
<head><title>{report.entity_name} — {report.report_id}</title></head>
<body>
  <ix:header>
    <ix:references>
      <link:schemaRef xlink:href="https://xbrl.fasb.org/us-gaap/2024/us-gaap-2024.xsd"/>
    </ix:references>
    <ix:resources>
      <xbrli:context id="ctx-entity">
        <xbrli:entity>
          <xbrli:identifier scheme="http://www.sec.gov/CIK">{report.cik}</xbrli:identifier>
        </xbrli:entity>
        <xbrli:period>
          <xbrli:instant>{report.reporting_period_end}</xbrli:instant>
        </xbrli:period>
      </xbrli:context>
      <xbrli:unit id="USD"><xbrli:measure>iso4217:USD</xbrli:measure></xbrli:unit>
      <xbrli:unit id="ratio"><xbrli:measure>xbrli:pure</xbrli:measure></xbrli:unit>
      <xbrli:unit id="shares"><xbrli:measure>xbrli:shares</xbrli:measure></xbrli:unit>
    </ix:resources>
  </ix:header>
  <h1>{report.entity_name}</h1>
  <h2>Report: {report.report_id}</h2>
  <p>Period ending: {report.reporting_period_end}</p>
  <table border="1">
    <thead><tr><th>Concept</th><th>Value</th></tr></thead>
    <tbody>
{chr(10).join(rows)}
    </tbody>
  </table>
</body>
</html>"""

    def to_xbrl_json(self, report: XBRLReport) -> str:
        """Generate XBRL-JSON (Open Information Model) format."""
        facts_json: dict[str, Any] = {}
        for i, fact in enumerate(report.facts):
            fact_id = f"f{i}"
            fact_entry: dict[str, Any] = {
                "value": fact.value,
                "dimensions": {
                    "concept": fact.concept,
                    "entity": f"scheme:http://www.sec.gov/CIK:{report.cik}",
                    "unit": fact.unit,
                },
            }
            if fact.period_type == XBRLPeriodType.INSTANT:
                fact_entry["dimensions"]["period"] = fact.instant_date
            else:
                fact_entry["dimensions"]["period"] = f"{fact.period_start}/{fact.period_end}"

            for dim in fact.dimensions:
                fact_entry["dimensions"][f"{dim.taxonomy.value}:{dim.dimension_name}"] = (
                    f"{dim.taxonomy.value}:{dim.member_name}"
                )

            if isinstance(fact.value, (int, float)):
                fact_entry["decimals"] = fact.decimals

            facts_json[fact_id] = fact_entry

        oim = {
            "documentInfo": {
                "documentType": "https://xbrl.org/2021/xbrl-json",
                "taxonomy": [f"https://xbrl.fasb.org/us-gaap/2024/us-gaap-2024.xsd"],
            },
            "facts": facts_json,
        }

        return json.dumps(oim, indent=2)

    def to_edgar_submission(self, package: XBRLFilingPackage) -> str:
        """Generate SEC EDGAR submission header format."""
        report_files = []
        for i, report in enumerate(package.reports):
            filename = f"R{i + 1}_{report.report_id.replace('-', '_')}.xml"
            report_files.append(f"<FILENAME>{filename}")

        documents = "\n".join(report_files)

        return f"""<SUBMISSION>
<ACCESSION-NUMBER>{package.package_id}</ACCESSION-NUMBER>
<TYPE>{package.form_type.value}</TYPE>
<PUBLIC-DOCUMENT-COUNT>{len(package.reports)}</PUBLIC-DOCUMENT-COUNT>
<FILING-DATE>{package.filing_date}</FILING-DATE>
<DATE-OF-FILING-DATE-CHANGE>{package.filing_date}</DATE-OF-FILING-DATE-CHANGE>
<FILER>
<COMPANY-DATA>
<CONFORMED-NAME>{package.filer_name}</CONFORMED-NAME>
<CIK>{package.cik}</CIK>
<ASSIGNED-SIC>6726</ASSIGNED-SIC>
<IRS-NUMBER>00-0000000</IRS-NUMBER>
<STATE-OF-INCORPORATION>DE</STATE-OF-INCORPORATION>
<FISCAL-YEAR-END>1231</FISCAL-YEAR-END>
</COMPANY-DATA>
<FILING-VALUES>
<FORM-TYPE>{package.form_type.value}</FORM-TYPE>
<ACT>40</ACT>
<FILE-NUMBER>811-00000</FILE-NUMBER>
</FILING-VALUES>
</FILER>
<DOCUMENT>
<TYPE>EX-99
<SEQUENCE>1
{documents}
</DOCUMENT>
</SUBMISSION>"""
