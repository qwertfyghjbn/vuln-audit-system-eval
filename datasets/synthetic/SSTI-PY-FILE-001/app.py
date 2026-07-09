from flask import Flask, request
from jinja2 import Environment

app = Flask(__name__)
jinja_env = Environment()


@app.route('/greet')
def greet():
    name = request.args.get('name', 'world')
    template_str = "Hello, " + name + "!"
    template = jinja_env.from_string(template_str)
    return template.render()


if __name__ == '__main__':
    app.run(debug=True)
