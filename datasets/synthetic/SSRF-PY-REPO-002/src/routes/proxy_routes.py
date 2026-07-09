from flask import Blueprint, request, jsonify
from services.proxy_service import ProxyService

proxy_bp = Blueprint('proxy', __name__)
_service = ProxyService()


@proxy_bp.route('/api/proxy/fetch')
def fetch():
    url = request.args.get('url', '')
    if not url:
        return jsonify({'error': 'url is required'}), 400

    body = _service.fetch_remote(url)
    if body is None:
        return jsonify({'error': 'fetch failed or url not allowed'}), 502

    return body, 200, {'Content-Type': 'text/plain'}
