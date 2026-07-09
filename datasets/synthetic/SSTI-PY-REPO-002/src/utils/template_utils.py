from jinja2 import Environment

_env = Environment()
_REPORT_TEMPLATE = "<h1>{{ title }}</h1><p>Report Preview</p>"


def render_report_template(title: str) -> str:
    template = _env.from_string(_REPORT_TEMPLATE)
    return template.render(title=title)
