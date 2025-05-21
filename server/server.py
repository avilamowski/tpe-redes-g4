from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO, emit
from datetime import datetime
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL", "postgresql://postgres:postgres@db:5432/chatdb"
)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

socketio = SocketIO(app, cors_allowed_origins="*")

db = SQLAlchemy(app)


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


@app.route("/users", methods=["POST"])
def create_user():
    data = request.json
    new_user = User(name=data["name"])
    db.session.add(new_user)
    db.session.commit()
    response = jsonify({"id": new_user.id, "name": new_user.name}), 201
    return response


@app.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify({"id": user.id, "name": user.name})


@app.route("/users", methods=["GET"])
def get_all_users():
    users = User.query.all()
    return jsonify([{"id": user.id, "name": user.name} for user in users])


@socketio.on("send_message")
def handle_send_message(data):
    message = Message(user_id=data["user_id"], content=data["content"])
    db.session.add(message)
    db.session.commit()
    emit(
        "new_message",
        {
            "id": message.id,
            "user_id": message.user_id,
            "content": message.content,
            "timestamp": message.timestamp.isoformat(),
        },
        broadcast=True,
    )


@socketio.on("get_messages")
def handle_get_messages():
    messages = Message.query.order_by(Message.timestamp.asc()).all()
    emit(
        "message_list",
        [
            {
                "id": m.id,
                "user_id": m.user_id,
                "content": m.content,
                "timestamp": m.timestamp.isoformat(),
            }
            for m in messages
        ],
    )


# @app.before_first_request
def create_tables():
    db.create_all()


with app.app_context():
    db.create_all()

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000)
