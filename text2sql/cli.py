"""Interactive command line: python -m text2sql.cli"""
from .engine import Text2SQL

MAX_CLARIFICATION_ROUNDS = 2


def show(res):
    if res.status == "clarification_needed":
        print("\nStill ambiguous after clarification. Try rephrasing the question.")
        return
    print(f"\nSQL:\n{res.sql}\n")
    if res.repairs:
        print(f"(auto-corrected {res.repairs}x)")
    if res.error:
        print("Error:", res.error)
        return
    print(" | ".join(res.columns))
    for r in res.rows:
        print(" | ".join(str(x) for x in r))
    print(f"({len(res.rows)} rows)")


def ask_clarifications(clars):
    """Show each clarification question; accept an option number or free text."""
    answers = []
    for c in clars:
        print(f"\n? {c.question}")
        for i, o in enumerate(c.options, 1):
            print(f"  {i}. {o}")
        raw = input("> ").strip()
        ok = raw.isdigit() and 1 <= int(raw) <= len(c.options)
        answers.append((c.question, c.options[int(raw) - 1] if ok else raw))
    return answers


def main():
    t = Text2SQL()
    print("Gym Text-to-SQL. Ctrl-C to quit.")
    while True:
        try:
            q = input("\nAsk: ").strip()
        except (KeyboardInterrupt, EOFError):
            break
        if not q:
            continue
        try:
            res = t.run(q)
            answers = []
            for _ in range(MAX_CLARIFICATION_ROUNDS):
                if res.status != "clarification_needed":
                    break
                answers += ask_clarifications(res.clarifications)
                res = t.run(q, answers)
            show(res)
        except (KeyboardInterrupt, EOFError):
            break
        except Exception as e:  # noqa: BLE001 - keep the session alive on LLM/network errors
            print(f"\nError: {e}")


if __name__ == "__main__":
    main()
