from flask import Flask
from flask import request
from flask import jsonify
from counts import counts

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello World from Flask in a uWSGI Nginx Docker container with \
     Python 3.8 (from the example template)"

@app.route('/counts', methods=['POST'])
def calc_counts():
    content = request.get_json(silent=True)

    cs = counts(content, 30)
    
    return jsonify(cs.tolist())

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True, port=80)
