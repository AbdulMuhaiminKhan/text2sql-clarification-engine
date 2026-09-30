# Design Decisions

**MySQL instead of PostgreSQL.** The project reuses an existing MySQL 8 schema and data set,
so I kept its dialect. SQLAlchemy is the only DB layer, so moving to PostgreSQL means porting
`sql/gym.sql` and changing `DATABASE_URL`; the dialect name is injected into the prompt.

**Pydantic for every LLM output.** The engine branches on `status`, so a malformed reply must
never reach it. `Analysis` rejects `ready` without SQL and `clarification_needed` without
options. On failure the validation error is fed back to the model for up to 2 retries.

**Clarification is decided by the model, guided by domain notes.** A rule list would miss
phrasings; a bare LLM tends to over-ask or under-ask. The prompt lists the real ambiguities in
this schema (revenue from `Payments` vs `Subscriptions`, what "active" means, what "best" means)
and says relative dates are not ambiguous. Limit: 2 questions, 2-4 options each, so it stays quick.

**Schema read live, with ENUM values.** Column values like `'No-Show'` and `'Credit Card'` are
in the prompt, which avoids the most common wrong-filter errors. Audit table and view are hidden.

**Read-only guard before execution.** The LLM output is untrusted: single `SELECT`/`WITH`
statement only, forbidden keywords blocked (string literals ignored). A read-only DB user is
still the right production setup; this is defense in depth.

**Bounded self-repair.** A failing query is sent back with the DB error, max 2 attempts, so a
bad query cannot loop. Unsafe SQL is never repaired, only rejected.

**Evaluation counts over-asking as a failure.** Otherwise the engine could "win" by asking about
everything. Results are compared by information content, not exact SQL, since many queries are correct.

**Known limits.** Small data set (ties and tiny counts can hide errors); scripted clarification
answers are one of several valid readings; no conversation memory across questions.
