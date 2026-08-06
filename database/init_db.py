"""Initialize the MediLink database from schema.sql."""
import os
import sys
import pymysql
from dotenv import load_dotenv

load_dotenv()

def run():
    host = os.getenv("DB_HOST", "localhost")
    port = int(os.getenv("DB_PORT", "3306"))
    user = os.getenv("DB_USER", "root")
    password = os.getenv("DB_PASSWORD", "")
    db_name = os.getenv("DB_NAME", "medilink")

    schema_path = os.path.join(os.path.dirname(__file__), "schema.sql")
    if not os.path.exists(schema_path):
        print("schema.sql not found")
        sys.exit(1)

    with open(schema_path, "r", encoding="utf-8") as f:
        sql = f.read()

    # Connect without DB to execute CREATE DATABASE
    conn = pymysql.connect(host=host, port=port, user=user, password=password,
                           charset="utf8mb4", autocommit=True)
    try:
        with conn.cursor() as cur:
            for statement in sql.split(";"):
                stmt = statement.strip()
                if stmt:
                    cur.execute(stmt)
        print(f"✓ Database '{db_name}' initialized successfully.")
    finally:
        conn.close()

if __name__ == "__main__":
    run()