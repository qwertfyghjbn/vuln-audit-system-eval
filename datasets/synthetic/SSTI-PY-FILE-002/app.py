from flask import Flask, request, render_template_string

app = Flask(__name__)

_GREETING_TEMPLATE = "Hello, {{ name }}!"
_ALLOWED_NAME_RE = __import__('re').compile(r'^[A-Za-z0-9 _-]{1,64}$')


def _sanitize_name(raw: str) -> str | None:
    """Return the name only if it matches the strict allowlist pattern."""
    stripped = raw.strip()
    if _ALLOWED_NAME_RE.fullmatch(stripped):
        return stripped
    return None


@app.route('/greet')
def greet():
    raw_name = request.args.get('name', '')
    name = _sanitize_name(raw_name)
    if name is None:
        return "Invalid name", 400

    return render_template_string(_GREETING_TEMPLATE, name=name)


if __name__ == '__main__':
    app.run(debug=True)
