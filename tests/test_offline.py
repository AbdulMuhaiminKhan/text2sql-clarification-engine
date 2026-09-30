"""Offline tests: no API key needed. Run: python -m pytest tests -q  (or python tests/test_offline.py)"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import pytest
from pydantic import ValidationError

from text2sql.models import Analysis
from text2sql.safety import check_read_only, UnsafeSQL


def test_safety_allows_select_and_cte():
    assert check_read_only("SELECT * FROM Members;")
    assert check_read_only("WITH a AS (SELECT 1) SELECT * FROM a")


@pytest.mark.parametrize("bad", [
    "DROP TABLE Members", "DELETE FROM Payments", "SELECT 1; DROP TABLE Members",
    "UPDATE Members SET Status='Active'", "SELECT SLEEP(10)",
    "SELECT * FROM Members INTO OUTFILE '/tmp/x'",
])
def test_safety_blocks(bad):
    with pytest.raises(UnsafeSQL):
        check_read_only(bad)


def test_safety_ignores_keywords_inside_strings():
    assert check_read_only("SELECT * FROM Payments WHERE Description LIKE '%update%'")


def test_analysis_requires_sql_when_ready():
    with pytest.raises(ValidationError):
        Analysis(status="ready")


def test_analysis_requires_options_when_clarifying():
    with pytest.raises(ValidationError):
        Analysis(status="clarification_needed")
    a = Analysis(status="clarification_needed",
                 clarifications=[{"question": "By what?", "options": ["Revenue", "Orders"]}])
    assert a.clarifications[0].options == ["Revenue", "Orders"]


def test_gold_questions_wellformed():
    qs = json.load(open(os.path.join(os.path.dirname(__file__), "..", "eval", "questions.json")))
    assert len(qs) >= 20
    for q in qs:
        assert q["gold_sql"].lower().startswith("select")
        assert ("answer" in q) == q["ambiguous"]


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-q"]))
