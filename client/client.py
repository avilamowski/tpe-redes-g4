from flask import Flask, render_template
import requests

app = Flask(__name__, template_folder="templates")
PUBLIC_IP = "localhost"


def get_public_ip():
    try:
        response = requests.get(
            "http://169.254.169.254/latest/meta-data/public-ipv4", timeout=5
        )
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        # TODO: Logging
        return "localhost"


# TODO: Logging
PUBLIC_IP = get_public_ip()
print(f"[INFO] IP pública detectada: {PUBLIC_IP}")


@app.route("/frontend")
def index():
    return render_template(
        "index.html",
        ws_api_host=f"http://{PUBLIC_IP}",
        api_url=f"http://{PUBLIC_IP}/api",
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001)
