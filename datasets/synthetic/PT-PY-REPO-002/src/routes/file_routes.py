from flask import Blueprint, request, jsonify
from services.file_service import FileService

file_bp = Blueprint('file', __name__)
_service = FileService()


@file_bp.route('/api/files/download')
def download():
    filename = request.args.get('filename', '')
    if not filename:
        return jsonify({'error': 'filename is required'}), 400

    content = _service.get_file_content(filename)
    if content is None:
        return jsonify({'error': 'file not found'}), 404

    return content, 200, {'Content-Type': 'application/octet-stream'}
