# Text-to-SQL Clarification Engine

[![tests](https://github.com/AbdulMuhaiminKhan/text2sql-clarification-engine/actions/workflows/tests.yml/badge.svg)](https://github.com/AbdulMuhaiminKhan/text2sql-clarification-engine/actions/workflows/tests.yml)
![Python](https://img.shields.io/badge/python-3.11-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

Ask questions about a gym database in plain English. When a question is ambiguous
("Who is our best member?"), the system **asks what you mean before writing SQL** instead of guessing.

On a 20-question benchmark, the clarification engine answered **90%** of ambiguous questions correctly,
compared with 20–50% for an LLM that always guesses, and it never asked a question when none was needed.

---

## Key features

- **Clarification engine**: the LLM decides whether a question is `ready` or `clarification_needed`,
  and if needed asks at most 2 questions with 2–4 concrete options each.
- **Live schema injection**: tables, columns, primary/foreign keys and ENUM values are read from the
  database at startup, plus domain notes listing the ambiguities in this schema.
- **Validated LLM output**: every LLM reply is parsed into a Pydantic model; invalid JSON is sent back
  to the model with the validation error (up to 2 retries).
- **Read-only SQL guard**: only a single `SELECT`/`WITH` statement runs. Writes, DDL, stacked
  statements, `SLEEP`, `BENCHMARK` and file access are rejected.
- **Bounded self-repair**: if MySQL rejects a query, the error is sent back to the LLM for a fix
  (max 2 attempts).
- **Swappable LLM provider**: Groq, Gemini or OpenAI through one OpenAI-compatible client.
- **Evaluation harness**: baseline vs. clarification engine on 20 questions with verified gold queries.

## Technologies

| Area | Tools |
|---|---|
| Language | Python 3.11 |
| LLM | Groq (`openai/gpt-oss-120b` by default), Gemini, or OpenAI via the `openai` SDK |
| Validation | Pydantic v2 |
| Database | MySQL 8, SQLAlchemy 2, PyMySQL |
| Tooling | Docker, Docker Compose, pytest, GitHub Actions |

## How it works

```
User question
     |
     v
[Schema injection] -- live tables/columns/FKs/ENUMs + domain notes + reference date
     |
     v
[LLM analysis]  --Pydantic-validated JSON-->  status = ready | clarification_needed
     |                                              |
     | ready                                        v
     v                                    Ask user 1-2 questions with 2-4 options
[Read-only SQL guard]  <-- question + answers, analyze again ------+
     |
     v
[MySQL execute] --error--> [LLM repair, max 2 tries] --> retry
     |
     v
  Results
```

Design trade-offs are documented in [DECISIONS.md](DECISIONS.md).

## Project structure

```
text2sql-clarification-engine/
├── text2sql/               # Application package
│   ├── cli.py              # Interactive command line (entry point)
│   ├── engine.py           # Analyze -> clarify -> guard -> execute -> repair
│   ├── llm.py              # LLM client + JSON output validated with Pydantic
│   ├── models.py           # Pydantic contracts for LLM output
│   ├── schema.py           # Live schema reader + domain notes
│   ├── safety.py           # Read-only SQL guard
│   ├── config.py           # Settings from environment variables
│   └── list_models.py      # Prints the models your API key can use
├── eval/
│   ├── questions.json      # 20 benchmark questions with gold SQL
│   ├── run_eval.py         # Baseline vs. clarification engine
│   ├── smoke.py            # Quick end-to-end check with the real LLM
│   └── results.json        # Per-question results of the latest run
├── sql/gym.sql             # MySQL schema + sample data (10 tables, view, trigger)
├── tests/test_offline.py   # Offline tests (no API key or database needed)
├── .vscode/tasks.json      # One-click VS Code tasks for every step below
├── Dockerfile
├── docker-compose.yml      # MySQL + app containers
├── requirements.txt
├── .env.example
├── DECISIONS.md
└── LICENSE
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (recommended), **or** Python 3.11+ and MySQL 8
- An API key from [Groq](https://console.groq.com/keys) (free tier works), Gemini or OpenAI

## Installation

```bash
git clone https://github.com/AbdulMuhaiminKhan/text2sql-clarification-engine.git
cd text2sql-clarification-engine
cp .env.example .env        # Windows PowerShell: copy .env.example .env
```

Then edit `.env` (see below).

## Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `LLM_PROVIDER` | no | `groq` | `groq`, `gemini` or `openai` |
| `LLM_API_KEY` | **yes** | – | API key for the chosen provider |
| `LLM_MODEL` | no | per provider | e.g. `openai/gpt-oss-120b` on Groq |
| `MYSQL_ROOT_PASSWORD` | yes (Docker) | `change-me` | Root password for the MySQL container |
| `DATABASE_URL` | local runs only | `mysql+pymysql://root:change-me@127.0.0.1:3307/GymManagementDB` | SQLAlchemy URL. Docker Compose sets this for you. |
| `REFERENCE_DATE` | no | `2024-05-15` in Docker, today otherwise | What "today" means for "last month" etc. The sample data is from 2024. |
| `EVAL_DELAY` | no | `4` | Seconds between evaluation questions (free-tier rate limits) |

`.env` is git-ignored. Never commit real keys.

## Running

### With Docker (recommended)

```bash
docker compose up -d --build                        # starts MySQL (loads sql/gym.sql) + app
docker exec -it gym_app python -m text2sql.cli      # interactive session
```

The first start takes a minute while MySQL loads the sample data. `docker compose down` stops everything;
add `-v` to also delete the database volume.

### Without Docker

```bash
pip install -r requirements.txt
mysql -u root -p < sql/gym.sql            # creates GymManagementDB
# set DATABASE_URL in .env to point at your MySQL server
python -m text2sql.cli
```

### In VS Code

Open the folder and use **Terminal → Run Task**: `1 Start DB + app (Docker)`, `2 Offline tests`,
`3 Smoke test (real LLM)`, `4 Evaluation`, `5 Interactive CLI`, `0 List available LLM models`, `Stop Docker`.

## Usage

Type a question at the `Ask:` prompt. If the engine needs clarification, answer with an option number
or your own text. The CLI prints the generated SQL and the result rows. `Ctrl+C` quits.

Good questions to try:

| Question | Expected behaviour |
|---|---|
| `How many members have the status Active?` | Clear, answered right away |
| `List trainers whose hourly rate is above 40.` | Clear |
| `Who is our best member?` | Asks: by spend, attendance, training sessions…? |
| `What is our total revenue?` | Asks: all payments or membership fees only? |
| `Which class is most popular?` | Asks: bookings, attendance or capacity fill? |

### Example session

Abridged from a real run (Groq, `openai/gpt-oss-120b`):

```
Ask: Who is our best member?

? What metric should be used to determine the "best" member?
  1. Highest total spend (payments + subscriptions)
  2. Most class attendance (Attended bookings)
  3. Most personal training sessions completed
  4. Most fitness goals achieved
> 1

SQL:
SELECT m.MemberID, m.FirstName, m.LastName,
       COALESCE(p.total_payments,0) + COALESCE(s.total_subscriptions,0) AS total_spend
FROM Members m
LEFT JOIN (SELECT MemberID, SUM(Amount) AS total_payments FROM Payments GROUP BY MemberID) p
       ON m.MemberID = p.MemberID
LEFT JOIN (SELECT MemberID, SUM(AmountPaid) AS total_subscriptions FROM Subscriptions GROUP BY MemberID) s
       ON m.MemberID = s.MemberID
ORDER BY total_spend DESC
LIMIT 1;

MemberID | FirstName | LastName | total_spend
3 | James | Wilson | 1049.98
(1 rows)
```

### Python API

There is no HTTP API; the engine is a Python class:

```python
from text2sql.engine import Text2SQL

t = Text2SQL()                                  # uses DATABASE_URL from the environment
res = t.run("Who is our best member?")
if res.status == "clarification_needed":
    for c in res.clarifications:
        print(c.question, c.options)
    res = t.run("Who is our best member?", [(res.clarifications[0].question, "Highest total spend")])
print(res.status, res.sql, res.columns, res.rows, res.error)
```

`Result.status` is `ready`, `clarification_needed` or `error`.

## Evaluation

`eval/questions.json` holds 20 questions: 10 clear and 10 ambiguous, each with a hand-verified gold query.
Ambiguous questions have a scripted answer that is given when the engine asks.

```bash
docker exec gym_app python -m eval.run_eval
```

A result counts as correct when its rows carry the same information as the gold query's rows (same row
count; extra columns and column names are ignored). **Asking on a clear question counts as a miss**, so
the engine cannot score well by asking about everything.

Latest run (Groq `openai/gpt-oss-120b`, temperature 0; details in [`eval/results.json`](eval/results.json)):

| Setup | Overall | Clear | Ambiguous | Asked on ambiguous | Asked on clear |
|---|---|---|---|---|---|
| Baseline (always guess) | 60% | 100% | 20% | 0/10 | 0/10 |
| With clarification engine | **95%** | 100% | **90%** | 10/10 | 0/10 |

Across four runs the baseline scored 20–50% on ambiguous questions, depending on which guesses happened to
match. The engine scored 90% in both runs that had no API errors. Its one miss (revenue) added a
`PaymentStatus='Paid'` filter the user had not asked for.

## Testing

Offline tests need no API key and no database (SQL guard, Pydantic contracts, benchmark sanity checks):

```bash
python -m pytest tests -q                          # local
docker exec gym_app python -m pytest tests -q      # in Docker
```

They also run on every push via GitHub Actions. For an end-to-end check with the real LLM and database:

```bash
docker exec gym_app python -m eval.smoke
```

## Deployment

This is a command-line tool and research prototype; there is no hosted deployment. Docker Compose is the
supported way to run it. For production use, connect with a read-only database user (the SQL guard is
defense in depth, not a replacement for database permissions).

## Limitations and future improvements

- Small sample data set; ties or tiny counts can hide wrong queries.
- Scripted clarification answers are one of several valid readings.
- No conversation memory across questions.
- Possible next steps: a web UI or HTTP API, a read-only DB user in `docker-compose.yml`, a larger
  benchmark, and a PostgreSQL port of `sql/gym.sql`.

## License

[MIT](LICENSE) © 2026 Abdul Muhaimin Khan
