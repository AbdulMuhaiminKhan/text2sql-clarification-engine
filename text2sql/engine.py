from dataclasses import dataclass, field
from typing import Optional
from sqlalchemy import create_engine, text

from . import config, llm
from .models import Analysis, SQLFix
from .safety import check_read_only, UnsafeSQL
from .schema import get_schema_text, DOMAIN_NOTES

SYSTEM = """You are a careful Text-to-SQL assistant for a gym database ({dialect}).

{schema}

{notes}
Reference date (treat as "today"): {today}

Task: decide whether the user's question is specific enough to write ONE correct SQL query.
- If specific enough: status="ready" and put the query in "sql" (SELECT only, {dialect} syntax).
- If there are real ambiguities that would change the result: status="clarification_needed"
  with at most 2 clarifications, each with 2-4 concrete options. Do NOT write sql.
- Do not ask about things you can resolve from the schema or notes. Do not ask more than needed.
- If the user already answered clarifications (given below), treat those as settled and return "ready".
"""

BASELINE_SYSTEM = """You are a Text-to-SQL assistant for a gym database ({dialect}).

{schema}

Reference date (treat as "today"): {today}
Always return status="ready" with a single SELECT query. Never ask for clarification;
make your best guess."""

FIX_SYSTEM = """Fix the failing {dialect} query. Return JSON {{"sql": "..."}} only.

{schema}"""


@dataclass
class Result:
    status: str  # ready | clarification_needed | error
    sql: Optional[str] = None
    columns: list = field(default_factory=list)
    rows: list = field(default_factory=list)
    clarifications: list = field(default_factory=list)
    repairs: int = 0
    error: Optional[str] = None


class Text2SQL:
    def __init__(self, database_url: str = config.DATABASE_URL):
        self.db = create_engine(database_url)
        self.dialect = self.db.dialect.name
        self.schema = get_schema_text(self.db)

    def _ctx(self, tmpl: str) -> str:
        return tmpl.format(dialect=self.dialect, schema=self.schema,
                           notes=DOMAIN_NOTES, today=config.reference_date())

    def analyze(self, question: str, answers=None, clarify: bool = True) -> Analysis:
        user = f"Question: {question}"
        if answers:
            user += "\n\nUser clarifications:\n" + "\n".join(f"- {q} -> {a}" for q, a in answers)
        system = self._ctx(SYSTEM if clarify else BASELINE_SYSTEM)
        return llm.structured(system, user, Analysis)

    def execute(self, sql: str):
        safe = check_read_only(sql)
        with self.db.connect() as conn:
            res = conn.execute(text(safe))
            rows = [list(r) for r in res.fetchmany(config.MAX_ROWS)]
            return list(res.keys()), rows

    def run(self, question: str, answers=None, clarify: bool = True) -> Result:
        a = self.analyze(question, answers, clarify)
        if a.status == "clarification_needed":
            return Result("clarification_needed", clarifications=a.clarifications)
        return self.execute_with_repair(question, a.sql)

    def execute_with_repair(self, question: str, sql: str) -> Result:
        repairs = 0
        while True:
            try:
                cols, rows = self.execute(sql)
                return Result("ready", sql=sql, columns=cols, rows=rows, repairs=repairs)
            except UnsafeSQL as e:
                return Result("error", sql=sql, error=str(e), repairs=repairs)
            except Exception as e:
                if repairs >= config.MAX_REPAIR_ATTEMPTS:
                    return Result("error", sql=sql, error=str(e), repairs=repairs)
                repairs += 1
                fix = llm.structured(
                    self._ctx(FIX_SYSTEM),
                    f"Question: {question}\nFailing SQL:\n{sql}\nError: {e}", SQLFix)
                sql = fix.sql
