import re

from utils.template_utils import render_report_template

_ALLOWED_TITLE = re.compile(r'^[A-Za-z0-9 _,.:;!?()-]{1,128}$')


class ReportService:
    def _validate_title(self, title: str) -> str | None:
        stripped = title.strip()
        if _ALLOWED_TITLE.fullmatch(stripped):
            return stripped
        return None

    def render_preview(self, title: str) -> str | None:
        safe_title = self._validate_title(title)
        if safe_title is None:
            return None
        return render_report_template(safe_title)
