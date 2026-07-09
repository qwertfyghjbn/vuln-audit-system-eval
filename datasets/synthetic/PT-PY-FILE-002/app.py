from flask import Flask, request, abort
import os

app = Flask(__name__)
BASE_DIR = "/var/www/files"


def _resolve_safe_path(base_dir, user_input):
    """Resolve user-supplied path and verify it stays within base_dir."""
    clean = os.path.normpath(user_input)
    if os.path.isabs(clean):
        raise ValueError("absolute path rejected")
    joined = os.path.join(base_dir, clean)
    resolved = os.path.realpath(joined)
    real_base = os.path.realpath(base_dir)
    if not resolved.startswith(real_base + os.sep):
        raise ValueError("path escape detected")
    return resolved


@app.route('/download')
def download_file():
    filename = request.args.get('filename', '')
    if not filename:
        return "No filename provided", 400

    try:
        safe_path = _resolve_safe_path(BASE_DIR, filename)
    except ValueError:
        abort(403)

    with open(safe_path, 'rb') as f:
        return f.read()


if __name__ == '__main__':
    app.run(debug=True)
