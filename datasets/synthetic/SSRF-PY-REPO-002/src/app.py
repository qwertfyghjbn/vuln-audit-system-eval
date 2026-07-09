from flask import Flask
from routes.proxy_routes import proxy_bp

app = Flask(__name__)
app.register_blueprint(proxy_bp)

if __name__ == '__main__':
    app.run(debug=True)
