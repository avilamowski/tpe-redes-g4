from flask import Flask, request, jsonify, Blueprint
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO, emit
from datetime import datetime
import os
from flask_cors import CORS
from logging.config import dictConfig
import uuid
import threading
import time

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

app = Flask(__name__)
CORS(app)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL", "postgresql://postgres:postgres@db:5432/chatdb"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

socketio = SocketIO(app, cors_allowed_origins="*", path="/api/ws")

db = SQLAlchemy(app)

api_bp = Blueprint("api", __name__, url_prefix="/api")

random_uuid = str(uuid.uuid4())

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)


class Message(db.Model):
    __tablename__ = "messages"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    content = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship("User")


@api_bp.route("/users", methods=["POST"])
def create_user():
    data = request.json
    existing_user = User.query.filter_by(name=data["name"]).first()
    if existing_user:
        response = jsonify({"id": existing_user.id, "name": existing_user.name}), 200
    else:
        new_user = User(name=data["name"])
        db.session.add(new_user)
        db.session.commit()
        app.logger.info("new user created with id: %s, name: %s", new_user.id, new_user.name)
        response = jsonify({"id": new_user.id, "name": new_user.name}), 201
    return response


@api_bp.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    app.logger.info("fetched user %s", user.id)
    return jsonify({"id": user.id, "name": user.name})


@api_bp.route("/users", methods=["GET"])
def get_all_users():
    users = User.query.all()
    app.logger.info("fetched all users")
    return jsonify([{"id": user.id, "name": user.name} for user in users])


@api_bp.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "ok"}), 200

@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.exception("Unhandled exception: %s", e)
    return jsonify({"error": str(e)}), 500


app.register_blueprint(api_bp)


@socketio.on("send_message")
def handle_send_message(data):
    message = Message(user_id=data["user_id"], content=data["content"])
    db.session.add(message)
    db.session.commit()
    app.logger.info('user %s sent message "%s"', data["user_id"], data["content"])
    emit(
        "new_message",
        {
            "id": message.id,
            "user_id": message.user_id,
            "user_name": message.user.name,
            "content": message.content,
            "timestamp": message.timestamp.isoformat(),
        },
        broadcast=True,
    )


@socketio.on("get_messages")
def handle_get_messages():
    messages = Message.query.order_by(Message.timestamp.asc()).all()
    app.logger.info("fetched %d messages", len(messages))
    emit(
        "message_list",
        [
            {
                "id": m.id,
                "user_id": m.user_id,
                "user_name": m.user.name,
                "content": m.content,
                "timestamp": m.timestamp.isoformat(),
                "instance_uuid": random_uuid,
            }
            for m in messages
        ],
    )


# @app.before_first_request
def create_tables():
    db.create_all()


with app.app_context():
    db.create_all()


# Polling other instance messages
poll_interval = 1  

def poll_new_messages():
    last_message_id = 0

    while True:
        time.sleep(poll_interval)

        with app.app_context():
            new_messages = Message.query.filter(Message.id > last_message_id).order_by(Message.id).all()

            for message in new_messages:
                socketio.emit(
                    "new_message",
                    {
                        "id": message.id,
                        "user_id": message.user_id,
                        "user_name": message.user.name,
                        "content": message.content,
                        "timestamp": message.timestamp.isoformat(),
                    },
                )
                app.logger.info("Emitted new_message from polling for message id: %s", message.id)
                last_message_id = message.id

if __name__ == "__main__":
    socketio.start_background_task(target=poll_new_messages)
    socketio.run(app, host="0.0.0.0", port=5000)
