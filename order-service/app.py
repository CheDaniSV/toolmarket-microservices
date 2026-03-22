from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)  # автоматически добавляет /metrics

@app.route('/health')
def health():
    return {"status": "ok", "service": "order-service"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
