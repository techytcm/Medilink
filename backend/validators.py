"""Input validation helpers."""
import re
from email_validator import validate_email, EmailNotValidError

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PASSWORD_RE = re.compile(r"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&_\-]{8,}$")
PHONE_RE  = re.compile(r"^\+?[0-9\-\s()]{7,20}$")

def valid_email(email: str) -> bool:
    try:
        validate_email(email)
        return True
    except EmailNotValidError:
        return False

def valid_password(pw: str) -> bool:
    """Min 8 chars, at least one letter and one digit."""
    return bool(PASSWORD_RE.match(pw))

def valid_phone(phone: str) -> bool:
    return bool(PHONE_RE.match(phone or ""))

def sanitize_text(text: str, max_len: int = 1000) -> str:
    if not text:
        return ""
    text = text.strip()
    return text[:max_len]