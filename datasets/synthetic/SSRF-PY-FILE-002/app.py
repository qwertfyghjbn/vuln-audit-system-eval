from flask import Flask, request
from urllib.parse import urlparse
import requests
import ipaddress

app = Flask(__name__)

ALLOWED_SCHEMES = {"https"}
ALLOWED_DOMAINS = {"api.example.com", "cdn.example.com"}


def _is_safe_url(url: str) -> bool:
    """
    Validate that the URL uses an allowed scheme, resolves to a permitted
    domain, and does not target private/loopback address ranges.
    """
    try:
        parsed = urlparse(url)
    except ValueError:
        return False

    if parsed.scheme not in ALLOWED_SCHEMES:
        return False

    hostname = parsed.hostname
    if hostname is None:
        return False

    if hostname not in ALLOWED_DOMAINS:
        return False

    try:
        addr = ipaddress.ip_address(hostname)
        if addr.is_private or addr.is_loopback or addr.is_link_local:
            return False
    except ValueError:
        pass

    return True


@app.route('/fetch')
def fetch_url():
    url = request.args.get('url', '')
    if not url:
        return "No URL provided", 400

    if not _is_safe_url(url):
        return "URL not allowed", 403

    try:
        resp = requests.get(url, timeout=5, allow_redirects=False)
        return resp.text, resp.status_code
    except requests.RequestException as e:
        return str(e), 500


if __name__ == '__main__':
    app.run(debug=True)
