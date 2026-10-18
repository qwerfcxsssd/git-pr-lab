import datetime
import socket

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/api/info")
def info():
    return jsonify(
        message="Hello from backend",
        hostname=socket.gethostname(),
        time=datetime.datetime.now().isoformat(timespec="seconds"),
    )


@app.get("/api/health")
def health():
    return jsonify(status="ok")
