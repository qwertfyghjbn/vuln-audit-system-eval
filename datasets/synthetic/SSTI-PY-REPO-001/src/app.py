from flask import Flask
from routes.report_routes import report_bp

app = Flask(__name__)
app.register_blueprint(report_bp)

if __name__ == '__main__':
    app.run(debug=True)
