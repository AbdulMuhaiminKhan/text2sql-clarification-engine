import os
from datetime import date
from dotenv import load_dotenv

load_dotenv()

PROVIDERS = {
    "groq": ("https://api.groq.com/openai/v1", "openai/gpt-oss-120b"),
    "gemini": ("https://generativelanguage.googleapis.com/v1beta/openai/", "gemini-2.0-flash"),
    "openai": (None, "gpt-4o-mini"),
}

PROVIDER = (os.getenv("LLM_PROVIDER") or "groq").lower()
if PROVIDER not in PROVIDERS:
    raise ValueError(f"LLM_PROVIDER must be one of {sorted(PROVIDERS)}, got {PROVIDER!r}")
API_KEY = os.getenv("LLM_API_KEY", "")
BASE_URL, _default_model = PROVIDERS[PROVIDER]
MODEL = os.getenv("LLM_MODEL") or _default_model
DATABASE_URL = os.getenv(
    "DATABASE_URL", "mysql+pymysql://root:change-me@127.0.0.1:3307/GymManagementDB"
)
MAX_REPAIR_ATTEMPTS = 2
MAX_ROWS = 200


def reference_date() -> str:
    return os.getenv("REFERENCE_DATE") or date.today().isoformat()
