"""
02_build_database.py
--------------------
Loads the raw CSVs and model coefficients into SQLite, runs every SQL
script in order and saves each named query to outputs/.

    python 01_train_churn_model.py   # first: writes model_coefficients.csv
    python 02_build_database.py
"""
import csv
import re
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SQL = ROOT
RAW = ROOT
OUT = ROOT / "outputs"
DB = ROOT / "revenue_analytics.db"

LOADS = [
    ("report_time_log.csv", "stg_report_time_log"),
    ("report_catalogue.csv", "stg_report_catalogue"),
    ("rms_accounts.csv", "stg_rms_accounts"),
    ("recovery_log.csv", "stg_recovery_log"),
    ("customers.csv", "stg_customers"),
    ("kpi_monthly_measures.csv", "stg_kpi_monthly_measures"),
]


def statements(path):
    """Yield (name, statement) for every SELECT in a script; comments removed."""
    text = re.sub(r"/\*.*?\*/", "", path.read_text(encoding="utf-8"), flags=re.S)
    for chunk in text.split(";"):
        body = chunk.strip()
        if re.match(r"^(--[^\n]*\n\s*)*(WITH|SELECT)\b", body, re.I):
            m = re.search(r"--\s*name:\s*(\w+)", body)
            yield (m.group(1) if m else None), body


def load(con, path, table):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))[1:]
    marks = ",".join("?" * len(rows[0]))
    con.executemany(f"INSERT INTO {table} VALUES ({marks})",
                    [[v if v != "" else None for v in r] for r in rows])
    return len(rows)


def save(cur, name):
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cols)
        w.writerows(rows)
    return rows


def main():
    coef = OUT / "model_coefficients.csv"
    if not coef.exists():
        raise SystemExit("Run 01_train_churn_model.py first.")
    DB.unlink(missing_ok=True)
    con = sqlite3.connect(DB)

    con.executescript((SQL / "01_create_tables.sql").read_text(encoding="utf-8"))
    for fn, table in LOADS:
        print(f"loaded {load(con, RAW / fn, table):>5} rows into {table}")
    load(con, coef, "model_coefficients")
    con.commit()

    con.executescript((SQL / "02_clean_transform.sql").read_text(encoding="utf-8"))
    print("ran 02_clean_transform.sql")

    print("\nData-quality checks")
    for i, (_, q) in enumerate(statements(SQL / "03_data_quality_checks.sql"), 1):
        res = con.execute(q).fetchall()
        print(f"  DQ{i}: {res[:6]}")

    for script in ("04_reporting_automation.sql", "05_revenue_leakage.sql",
                   "06_churn_model_evaluation.sql", "07_kpi_tracker.sql"):
        print(f"\n{script}")
        for name, q in statements(SQL / script):
            rows = save(con.execute(q), name)
            print(f"  {name}: {len(rows)} rows")

    save(con.execute("SELECT * FROM account_leakage ORDER BY account_id"), "account_leakage")
    save(con.execute("SELECT * FROM customer_scores ORDER BY customer_id"), "customer_scores")
    con.close()
    print(f"\nDatabase: {DB.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
