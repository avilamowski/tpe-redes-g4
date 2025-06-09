from flask import Flask, render_template
import requests
from logging.config import dictConfig

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

app = Flask(__name__, template_folder="templates")
PUBLIC_IP = "minikube"


def get_public_ip():
    try:
        response = requests.get(
            "http://169.254.169.254/latest/meta-data/public-ipv4", timeout=5
        )
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        return "minikube" # Fallback for local development on minikube


PUBLIC_IP = get_public_ip()
app.logger.info("[INFO] IP pública detectada: %s", PUBLIC_IP)


@app.route("/frontend")
def index():
    app.logger.info("fetched frontend")
    return render_template(
        "index.html",
        ws_api_host=f"http://{PUBLIC_IP}",
        api_url=f"http://{PUBLIC_IP}/api",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001)
