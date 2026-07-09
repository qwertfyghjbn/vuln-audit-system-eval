from flask import Blueprint, request, jsonify
from services.report_service import ReportService

report_bp = Blueprint('report', __name__)
_service = ReportService()


@report_bp.route('/api/reports/preview')
def preview():
    title = request.args.get('title', '')
    if not title:
        return jsonify({'error': 'title is required'}), 400

    html = _service.render_preview(title)
    return html, 200, {'Content-Type': 'text/html'}
