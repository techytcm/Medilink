"""Authentication helpers: password hashing, sessions, role guards."""
import functools
import secrets
from datetime import datetime, timedelta
from flask import session, redirect, url_for, flash, abort, request
import bcrypt
from backend.db import query, execute

# ---------------- Password hashing ----------------
def hash_password(plain: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(plain.encode("utf-8"), salt).decode("utf-8")

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False

# ---------------- Session ----------------
def login_user(user: dict):
    session.permanent = True
    session["user_id"]   = user["user_id"]
    session["email"]     = user["email"]
    session["full_name"] = user["full_name"]
    session["role"]      = user["role"]
    session["avatar"]    = user.get("avatar_url") or ""
    # update last_login
    execute("UPDATE users SET last_login=%s WHERE user_id=%s",
            (datetime.now(), user["user_id"]))

def logout_user():
    session.clear()

def current_user():
    if "user_id" not in session:
        return None
    return query("SELECT * FROM users WHERE user_id=%s", (session["user_id"],), one=True)

# ---------------- Role guards ----------------
def login_required(view):
    @functools.wraps(view)
    def wrapped(*args, **kwargs):
        if "user_id" not in session:
            flash("Please sign in to continue.", "warning")
            return redirect(url_for("auth.login", next=request.path))
        return view(*args, **kwargs)
    return wrapped

def role_required(*roles):
    def decorator(view):
        @functools.wraps(view)
        def wrapped(*args, **kwargs):
            if "user_id" not in session:
                return redirect(url_for("auth.login"))
            if session.get("role") not in roles:
                abort(403)
            return view(*args, **kwargs)
        return wrapped
    return decorator

# ---------------- Password reset tokens ----------------
def generate_reset_token(user_id: int) -> str:
    token = secrets.token_urlsafe(32)
    expires = datetime.now() + timedelta(hours=1)
    execute(
        "INSERT INTO password_resets (user_id, token, expires_at) VALUES (%s,%s,%s)",
        (user_id, token, expires),
    )
    return token

def validate_reset_token(token: str):
    row = query(
        """SELECT * FROM password_resets
           WHERE token=%s AND used=FALSE AND expires_at > NOW()
           ORDER BY created_at DESC LIMIT 1""",
        (token,), one=True,
    )
    return row

def consume_reset_token(token: str):
    execute("UPDATE password_resets SET used=TRUE WHERE token=%s", (token,))