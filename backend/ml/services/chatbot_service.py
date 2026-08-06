"""Chatbot service: session + message persistence."""
from backend.db import query, execute
from backend.ml.symptom_engine import chatbot_reply

def handle_message(user_id: int, message: str) -> str:
    session = query("SELECT session_id FROM chat_sessions WHERE user_id=%s ORDER BY started_at DESC LIMIT 1",
                    (user_id,), one=True)
    if not session:
        sid, _ = execute("INSERT INTO chat_sessions (user_id) VALUES (%s)", (user_id,))
    else:
        # Reuse the latest session if recent; otherwise create new
        sid = session["session_id"]
    execute("INSERT INTO chat_messages (session_id, sender, message) VALUES (%s,'user',%s)",
            (sid, message))
    reply = chatbot_reply(message)
    execute("INSERT INTO chat_messages (session_id, sender, message) VALUES (%s,'bot',%s)",
            (sid, reply))
    return reply

def history(user_id: int, limit: int = 100):
    rows = query(
        """SELECT m.* FROM chat_messages m
           JOIN chat_sessions s ON m.session_id = s.session_id
           WHERE s.user_id=%s ORDER BY m.created_at ASC LIMIT %s""",
        (user_id, limit),
    )
    return rows