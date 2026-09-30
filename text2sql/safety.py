"""Read-only guard. LLM-generated SQL must never modify data."""
import re

FORBIDDEN = re.compile(
    r"\b(insert|update|delete|drop|alter|truncate|create|replace|grant|revoke|call|"
    r"load_file|outfile|dumpfile|sleep|benchmark)\b", re.I)


class UnsafeSQL(ValueError):
    pass


def check_read_only(sql: str) -> str:
    s = sql.strip().rstrip(";").strip()
    s_clean = re.sub(r"'(?:[^'\\]|\\.|'')*'", "''", s)
    s_clean = re.sub(r"--[^\n]*|/\*.*?\*/", " ", s_clean, flags=re.S)
    if ";" in s_clean:
        raise UnsafeSQL("Multiple statements are not allowed")
    if not re.match(r"^\s*(select|with)\b", s_clean, re.I):
        raise UnsafeSQL("Only SELECT queries are allowed")
    m = FORBIDDEN.search(s_clean)
    if m:
        raise UnsafeSQL(f"Forbidden keyword: {m.group(1)}")
    return s
