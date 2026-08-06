"""Reset or create the admin user with a known password and optional email/full name.

Usage:
    python scripts/reset_admin_password.py \
        --current-email admin@medilink.health \
        --email techytcm@medilink.health \
        --full-name techytcm \
        --password 'tonmoy05.com'

Reads DB creds from .env in project root.
"""
import os
import argparse
from dotenv import load_dotenv
import pymysql
import bcrypt

load_dotenv()


def get_db_conn():
    host = os.getenv("DB_HOST", "localhost")
    port = int(os.getenv("DB_PORT", "3306"))
    user = os.getenv("DB_USER", "root")
    password = os.getenv("DB_PASSWORD", "")
    db = os.getenv("DB_NAME", "medilink")
    return pymysql.connect(host=host, port=port, user=user, password=password, db=db, charset="utf8mb4", autocommit=True)


def ensure_admin(password: str, email: str, full_name: str, current_email: str = 'admin@medilink.health'):
    pw_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=12)).decode('utf-8')
    conn = get_db_conn()
    try:
        with conn.cursor() as cur:
            # Try to find existing admin by current_email first
            cur.execute("SELECT user_id FROM users WHERE email=%s", (current_email,))
            row = cur.fetchone()
            if row:
                cur.execute(
                    "UPDATE users SET password_hash=%s, role='admin', email=%s, full_name=%s WHERE user_id=%s",
                    (pw_hash, email, full_name, row[0]),
                )
                print(f"Updated existing admin (id={row[0]}) to email={email}, name={full_name}.")
            else:
                # If not found by current_email, try to find by desired email
                cur.execute("SELECT user_id FROM users WHERE email=%s", (email,))
                row2 = cur.fetchone()
                if row2:
                    cur.execute("UPDATE users SET password_hash=%s, role='admin', full_name=%s WHERE user_id=%s",
                                (pw_hash, full_name, row2[0]))
                    print(f"Updated existing user (id={row2[0]}) to admin with name={full_name}.")
                else:
                    cur.execute(
                        "INSERT INTO users (full_name, email, phone, password_hash, role) VALUES (%s,%s,%s,%s,%s)",
                        (full_name, email, "+10000000000", pw_hash, "admin"),
                    )
                    print(f"Created admin user ({email}).")
    finally:
        conn.close()


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--password', '-p', required=True, help='Password to set for admin')
    p.add_argument('--email', required=True, help='Email to set for admin (e.g. techytcm@medilink.health)')
    p.add_argument('--full-name', dest='full_name', required=True, help='Display/full name for admin')
    p.add_argument('--current-email', dest='current_email', default='admin@medilink.health', help='Current admin email to look up')
    args = p.parse_args()
    try:
        ensure_admin(args.password, args.email, args.full_name, args.current_email)
    except Exception as e:
        print("ERROR:", e)
        raise
