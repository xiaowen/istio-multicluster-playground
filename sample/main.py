import flask
from flask import Flask, request, Response
import os

app = Flask(__name__)

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def index(path):
    ret = '%s on [pod: %s] in [cluster: %s]\n' % (request.url, os.uname()[1], os.environ.get('CLUSTER', '<unknown>'))
    resp = Response(ret, mimetype='text/plain')
    resp.headers['Cache-Control'] = 'private'
    return resp

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, use_debugger=False, use_reloader=False)
