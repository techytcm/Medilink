"""Audit logging service."""
from backend.db import execute
from flask import request

def log(user_id, action, entity=None, entity_id=None):
    try:
        execute(
            """INSERT INTO audit_logs (user_id, action, entity, entity_id, ip_address, user_agent)
               VALUES (%s,%s,%s,%s,%s,%s)""",
            (user_id, action, entity, entity_id,
             request.remote_addr if request else None,
             request.headers.get("User-Agent") if request else None),
        )
    except Exception:
        pass  # audit should never break the request flow