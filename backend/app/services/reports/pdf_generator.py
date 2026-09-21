import io
from html import escape
from typing import Any

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.schemas.domain import InspectionReportModel


def _safe(value: Any) -> str:
    return escape(str(value if value not in (None, "") else "N/A").replace("₹", "Rs "))


class PdfReportGenerator:
    @staticmethod
    def generate_pdf(report: InspectionReportModel) -> bytes:
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer, pagesize=A4, rightMargin=14 * mm, leftMargin=14 * mm,
            topMargin=14 * mm, bottomMargin=15 * mm,
            title="Legal Metrology Inspection Compliance Report",
            author="LM TRACE",
        )
        styles = getSampleStyleSheet()
        styles.add(ParagraphStyle(name="ReportTitle", parent=styles["Title"], alignment=TA_CENTER, fontSize=17, leading=21, textColor=colors.HexColor("#0F2537")))
        styles.add(ParagraphStyle(name="Small", parent=styles["BodyText"], fontSize=7.5, leading=9.5))
        styles.add(ParagraphStyle(name="Section", parent=styles["Heading2"], fontSize=11, leading=14, spaceBefore=9, spaceAfter=5, textColor=colors.HexColor("#1E40AF")))
        story = [
            Paragraph("Legal Metrology Inspection Compliance Report", styles["ReportTitle"]),
            Paragraph("LM TRACE evidence based assessment record", styles["Small"]),
            Spacer(1, 5 * mm),
        ]

        metadata = [
            ["Inspection code", _safe(report.inspection_code), "Report version", _safe(report.report_version)],
            ["Inspection date", _safe(report.inspection_date), "Generated at", _safe(report.generated_at)],
            ["Inspector", _safe(report.inspector_name), "Officer ID", _safe(report.officer_id)],
            ["Establishment", _safe(report.business_name or report.seller_name), "Location", _safe(report.location)],
            ["Product", _safe(report.product_name), "Category", _safe(report.category)],
            ["Overall status", _safe(report.overall_status), "Assessment score", f"{report.score:.1f} / 100"],
            ["PDP area", f"{report.pdp_area_cm2:.2f} sq cm" if report.pdp_area_cm2 is not None else "UNVERIFIED", "Calibration", _safe(report.calibration_status)],
        ]
        meta_table = Table(metadata, colWidths=[31 * mm, 58 * mm, 31 * mm, 58 * mm])
        meta_table.setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CBD5E1")),
            ("BACKGROUND", (0, 0), (0, -1), colors.HexColor("#F1F5F9")),
            ("BACKGROUND", (2, 0), (2, -1), colors.HexColor("#F1F5F9")),
            ("FONTNAME", (0, 0), (-1, -1), "Helvetica"), ("FONTSIZE", (0, 0), (-1, -1), 7.5),
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"), ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
            ("VALIGN", (0, 0), (-1, -1), "TOP"), ("PADDING", (0, 0), (-1, -1), 4),
        ]))
        story.extend([meta_table, Paragraph("Declaration audit", styles["Section"])])

        declaration_rows = [["Declaration", "Detected value", "Verified value", "Presence", "Correctness", "Status"]]
        for item in report.declarations:
            declaration_rows.append([
                _safe(item.get("declaration")), _safe(item.get("ai_value")), _safe(item.get("verified_value")),
                _safe(item.get("presence")), _safe(item.get("correctness")), _safe(item.get("final_check")),
            ])
        story.append(PdfReportGenerator._table(declaration_rows, [31, 39, 39, 22, 25, 24]))

        story.append(Paragraph("Compliance checks", styles["Section"]))
        check_rows = [["Rule", "Check", "Field", "Input", "Result", "Explanation"]]
        for item in report.compliance_checks:
            check_rows.append([
                _safe(item.get("rule_code")), _safe(item.get("check_type")), _safe(item.get("field_name")),
                _safe(item.get("input_value")), _safe(item.get("result")),
                _safe(item.get("explanation") or item.get("expected_condition")),
            ])
        story.append(PdfReportGenerator._table(check_rows, [25, 27, 25, 30, 24, 49]))

        story.append(PageBreak())
        story.append(Paragraph("Violation and review summary", styles["Section"]))
        finding_rows = [["Type", "Severity", "Status", "Description", "Inspector comment"]]
        for item in report.findings:
            finding_rows.append([
                _safe(item.get("type")), _safe(item.get("severity")), _safe(item.get("status")),
                _safe(item.get("ai_explanation") or item.get("explanation")), _safe(item.get("inspector_comment") or "Pending"),
            ])
        if len(finding_rows) == 1:
            finding_rows.append(["NONE", "N/A", "N/A", "No potential violation recorded", "Confirm no checks remain unverified"])
        story.append(PdfReportGenerator._table(finding_rows, [30, 22, 28, 67, 33]))
        story.extend([
            Paragraph("Inspector remarks", styles["Section"]), Paragraph(_safe(report.inspector_remarks), styles["BodyText"]),
            Paragraph("Regulatory disclaimer", styles["Section"]), Paragraph(_safe(report.disclaimer), styles["Small"]),
        ])

        def footer(canvas, document):
            canvas.saveState()
            canvas.setFont("Helvetica", 7)
            canvas.setFillColor(colors.HexColor("#64748B"))
            canvas.drawString(14 * mm, 8 * mm, f"LM TRACE | {report.inspection_code}")
            canvas.drawRightString(196 * mm, 8 * mm, f"Page {document.page}")
            canvas.restoreState()

        doc.build(story, onFirstPage=footer, onLaterPages=footer)
        return buffer.getvalue()

    @staticmethod
    def _table(rows, widths):
        body_style = ParagraphStyle("report-cell", fontName="Helvetica", fontSize=6.7, leading=8.2)
        header_style = ParagraphStyle(
            "report-header-cell", parent=body_style, fontName="Helvetica-Bold", textColor=colors.white
        )
        wrapped = [
            [Paragraph(_safe(cell), header_style if row_index == 0 else body_style) for cell in row]
            for row_index, row in enumerate(rows)
        ]
        table = Table(wrapped, colWidths=[value * mm for value in widths], repeatRows=1)
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1E3A8A")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white), ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("GRID", (0, 0), (-1, -1), 0.3, colors.HexColor("#CBD5E1")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"), ("PADDING", (0, 0), (-1, -1), 3),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
        ]))
        return table


pdf_report_generator = PdfReportGenerator()
