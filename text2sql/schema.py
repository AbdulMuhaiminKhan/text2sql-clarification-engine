"""Schema injection: read live table info and add gym-domain hints."""
from sqlalchemy import inspect

EXCLUDE = {"PaymentAuditLog", "ActiveMemberSummary"}  # audit table + view: not query targets

# Places where this specific schema is genuinely ambiguous. Fed to the model so the
# clarification engine knows what to look for instead of guessing.
DOMAIN_NOTES = """\
Domain notes (use these to decide whether a question is ambiguous):
- "Revenue"/"income"/"sales" can come from Payments.Amount (all cash received, includes
  personal-training fees) OR Subscriptions.AmountPaid (membership fees only). Ambiguous.
- "Best/top/most valuable member" could mean total spend, class attendance, or PT sessions. Ambiguous.
- "Active member" can mean Members.Status='Active' OR having a current subscription. Ambiguous
  unless the user says which.
- "Popular class/trainer" could mean bookings, attendance, or capacity fill. Ambiguous.
- "Attendance" = ClassBookings.AttendanceStatus='Attended'. "Bookings" counts all statuses.
- Relative dates ("last month", "this year") are relative to the reference date given below.
  A relative date is NOT an ambiguity; resolve it.
- Equipment.Condition_ has a trailing underscore (Condition is reserved).
"""


def get_schema_text(engine) -> str:
    insp = inspect(engine)
    parts = []
    for table in sorted(insp.get_table_names()):
        if table in EXCLUDE:
            continue
        pk = set(insp.get_pk_constraint(table)["constrained_columns"])
        cols = []
        for c in insp.get_columns(table):
            tag = " PK" if c["name"] in pk else ""
            enums = getattr(c["type"], "enums", None)
            typ = f"ENUM({', '.join(repr(e) for e in enums)})" if enums else str(c["type"])
            cols.append(f"  {c['name']} {typ}{tag}")
        fks = [
            f"  FK {','.join(fk['constrained_columns'])} -> "
            f"{fk['referred_table']}({','.join(fk['referred_columns'])})"
            for fk in insp.get_foreign_keys(table)
        ]
        parts.append(f"TABLE {table} (\n" + "\n".join(cols + fks) + "\n)")
    return "\n\n".join(parts)
