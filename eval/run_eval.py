"""Compare the naive baseline (always guess) with the clarification engine.

    python -m eval.run_eval

Correctness = the returned rows contain the same information as the gold query's rows
(extra columns and column names are ignored; row count must match).
Clarification answers for ambiguous questions are scripted in questions.json.
"""
import json
import os
import sys
import time
from decimal import Decimal
from pathlib import Path

from sqlalchemy import text

from text2sql.engine import Text2SQL

QUESTIONS = Path(__file__).parent / "questions.json"
DELAY = float(os.getenv("EVAL_DELAY", "4"))  # seconds between questions (free-tier rate limits)


def norm(v):
    if isinstance(v, (Decimal, float, int)) and not isinstance(v, bool):
        return round(float(v), 2)
    return str(v).strip().lower()


def same_info(gold_rows, got_rows) -> bool:
    if len(gold_rows) != len(got_rows):
        return False
    pool = [[norm(v) for v in r] for r in got_rows]
    for g in gold_rows:
        g = [norm(v) for v in g]
        hit = next((i for i, r in enumerate(pool) if all(x in r for x in g)), None)
        if hit is None:
            return False
        pool.pop(hit)
    return True


def gold(t: Text2SQL, sql: str):
    with t.db.connect() as c:
        return [list(r) for r in c.execute(text(sql)).fetchall()]


def run_mode(t: Text2SQL, questions, use_engine: bool):
    rows_out = []
    for q in questions:
        time.sleep(DELAY)
        expected = gold(t, q["gold_sql"])
        asked = False
        try:
            res = t.run(q["question"], clarify=use_engine)
            if res.status == "clarification_needed":
                asked = True
                if q["ambiguous"]:
                    ans = [(c.question, q["answer"]) for c in res.clarifications]
                    res = t.run(q["question"], ans, clarify=True)
                else:
                    res = None  # over-asking on a clear question counts as a miss
            ok = bool(res) and res.status == "ready" and same_info(expected, res.rows)
            sql = res.sql if res else None
        except Exception as e:  # noqa: BLE001
            ok, sql = False, f"EXCEPTION: {e}"
        rows_out.append({"id": q["id"], "ambiguous": q["ambiguous"], "asked": asked,
                         "correct": ok, "sql": sql})
    return rows_out


def summarize(name, rows):
    def acc(sel):
        sel = list(sel)
        return 100 * sum(r["correct"] for r in sel) / len(sel) if sel else float("nan")
    amb = [r for r in rows if r["ambiguous"]]
    clear = [r for r in rows if not r["ambiguous"]]
    print(f"{name:<22} overall {acc(rows):5.1f}%   clear {acc(clear):5.1f}%   "
          f"ambiguous {acc(amb):5.1f}%   asked on {sum(r['asked'] for r in amb)}/{len(amb)} ambiguous, "
          f"{sum(r['asked'] for r in clear)}/{len(clear)} clear")


def main():
    questions = json.loads(QUESTIONS.read_text())
    t = Text2SQL()
    base = run_mode(t, questions, use_engine=False)
    eng = run_mode(t, questions, use_engine=True)
    print()
    summarize("Baseline (no clarify)", base)
    summarize("With clarification", eng)
    Path(__file__).with_name("results.json").write_text(
        json.dumps({"baseline": base, "engine": eng}, indent=2))
    print("\nPer-question details: eval/results.json")


if __name__ == "__main__":
    sys.exit(main())
