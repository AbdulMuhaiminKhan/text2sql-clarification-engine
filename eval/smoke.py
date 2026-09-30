"""Quick end-to-end check with the real LLM: python -m eval.smoke"""
from text2sql.engine import Text2SQL


def main():
    t = Text2SQL()
    print("DB OK, dialect:", t.dialect)
    r = t.run("How many members have the status Active?")
    print("\n[clear]", r.status, "|", r.sql, "|", r.rows, "|", r.error)
    r = t.run("Who is our best member?")
    print("\n[ambiguous]", r.status)
    for c in r.clarifications:
        print("  ?", c.question, c.options)
    if r.status == "clarification_needed":
        ans = [(c.question, c.options[0]) for c in r.clarifications]
        r = t.run("Who is our best member?", ans)
        print("  answered ->", r.status, "|", r.sql, "|", r.rows, "|", r.error)
    print("\nSMOKE TEST DONE")


if __name__ == "__main__":
    main()
