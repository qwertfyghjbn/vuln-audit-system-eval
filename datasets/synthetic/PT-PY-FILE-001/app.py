from flask import Flask, request
import os

app = Flask(__name__)
BASE_DIR = "/var/www/files"


@app.route('/download')
def download_file():
    filename = request.args.get('filename', '')
    if not filename:
        return "No filename provided", 400

    file_path = os.path.join(BASE_DIR, filename)

    try:
        with open(file_path, 'rb') as f:
            return f.read()
    except FileNotFoundError:
        return "File not found", 404


if __name__ == '__main__':
    app.run(debug=True)
