"""Notification helper."""
from backend.db import execute, query

def notify(user_id: int, title: str, message: str, ntype: str = "info"):
    execute(
        "INSERT INTO notifications (user_id, title, message, type) VALUES (%s,%s,%s,%s)",
        (user_id, title, message, ntype),
    )

def for_user(user_id: int, only_unread: bool = False):
    if only_unread:
        return query(
            "SELECT * FROM notifications WHERE user_id=%s AND is_read=FALSE ORDER BY created_at DESC",
            (user_id,))
    return query(
        "SELECT * FROM notifications WHERE user_id=%s ORDER BY created_at DESC",
        (user_id,))

def mark_read(notification_id: int, user_id: int):
    execute("UPDATE notifications SET is_read=TRUE WHERE notification_id=%s AND user_id=%s",
            (notification_id, user_id))

def mark_all_read(user_id: int):
    execute("UPDATE notifications SET is_read=TRUE WHERE user_id=%s", (user_id,))