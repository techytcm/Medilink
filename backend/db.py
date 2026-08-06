# backend/db.py
"""Database connection helper using PyMySQL for serverless (Vercel)."""
import pymysql
from pymysql.cursors import DictCursor
from config import Config

def get_conn():
    """Creates a new, short-lived database connection."""
    return pymysql.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
        connect_timeout=10,
        read_timeout=10,
        write_timeout=10
    )

def query(sql, args=None, one=False):
    """Execute a SELECT query and return rows (dict)."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, args or ())
            rows = cur.fetchall() or []
        return (rows[0] if one and rows else None) if one else rows
    finally:
        conn.close()

def execute(sql, args=None):
    """Execute INSERT/UPDATE/DELETE. Returns lastrowid and affected count."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            count = cur.execute(sql, args or ())
            conn.commit()
            return cur.lastrowid, count
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()