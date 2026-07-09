from flask import Flask, request
import requests

app = Flask(__name__)


@app.route('/fetch')
def fetch_url():
    url = request.args.get('url', '')
    if not url:
        return "No URL provided", 400

    try:
        resp = requests.get(url, timeout=5)
        return resp.text, resp.status_code
    except requests.RequestException as e:
        return str(e), 500


if __name__ == '__main__':
    app.run(debug=True)
