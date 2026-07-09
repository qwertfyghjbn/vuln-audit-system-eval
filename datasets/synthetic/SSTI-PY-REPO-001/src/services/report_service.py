from utils.template_utils import render_report_template


class ReportService:
    def render_preview(self, title: str) -> str:
        return render_report_template(title)
