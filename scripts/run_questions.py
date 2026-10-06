"""Run the business-question analyses against the built DuckDB warehouse.

Reads taxi_analytics/analyses/q*.sql, resolves dbt ref() calls to physical
schema.table names, executes each query, and writes results/*.csv plus a
results/business_answers.md summary with real numbers from the run.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANALYSES_DIR = ROOT / "taxi_analytics" / "analyses"
DUCKDB_PATH = ROOT / "taxi_analytics" / "taxi_analytics.duckdb"
RESULTS_DIR = ROOT / "results"

# physical schema per model/seed name (dbt-duckdb prefixes schemas with the
# database name, hence main_staging / main_marts)
STAGING = {"stg_yellow_tripdata": "main_staging", "taxi_zone_lookup": "main_staging"}
MARTS = {
    "dim_zones": "main_marts",
    "dim_payment_type": "main_marts",
    "fact_trips": "main_marts",
    "mart_hourly_demand": "main_marts",
    "mart_revenue_by_zone": "main_marts",
    "mart_tip_analysis": "main_marts",
}

TITLES = {
    "q1_busiest_pickup_hours": "Q1 — Busiest pickup hours (day_of_week: 0=Sun..6=Sat)",
    "q2_airport_vs_street_revenue": "Q2 — Airport vs non-airport revenue",
    "q3_tip_by_payment_type": "Q3 — Tipping by payment method",
    "q4_longest_trips_by_zone_pair": "Q4 — Longest trips by zone pair (min 500 trips)",
    "q5_weekend_vs_weekday": "Q5 — Weekend vs weekday",
    "q6_manhattan_share_by_month": "Q6 — Manhattan pickup share by month",
}


def resolve_refs(sql: str) -> str:
    def repl(m):
        name = m.group(1)
        if name in STAGING:
            return f"{STAGING[name]}.{name}"
        if name in MARTS:
            return f"{MARTS[name]}.{name}"
        raise ValueError(f"unknown ref: {name}")

    return re.sub(r"\{\{\s*ref\('([^']+)'\)\s*\}\}", repl, sql)


def to_markdown(columns, rows) -> str:
    header = "| " + " | ".join(columns) + " |"
    sep = "| " + " | ".join("---" for _ in columns) + " |"
    body = "\n".join("| " + " | ".join(str(v) for v in r) + " |" for r in rows)
    return "\n".join([header, sep, body])


def main() -> None:
    import duckdb

    if not DUCKDB_PATH.exists():
        sys.exit(f"warehouse not found: {DUCKDB_PATH} — run `dbt build` first")
    RESULTS_DIR.mkdir(exist_ok=True)
    con = duckdb.connect(str(DUCKDB_PATH), read_only=True)

    md = ["# Business answers (from `dbt build` + analyses)\n",
          "All numbers below were produced by running the SQL in "
          "`taxi_analytics/analyses/` against the built warehouse.\n"]

    for path in sorted(ANALYSES_DIR.glob("q*.sql")):
        name = path.stem
        sql = resolve_refs(path.read_text())
        # strip leading /* */ comment for cleanliness (keep it in the file)
        rows = con.execute(sql).fetchall()
        cols = [d[0] for d in con.description]
        # CSV
        import csv
        with open(RESULTS_DIR / f"{name}.csv", "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(cols)
            w.writerows(rows)
        md.append(f"## {TITLES.get(name, name)}\n")
        md.append(to_markdown(cols, rows) + "\n")

    (RESULTS_DIR / "business_answers.md").write_text("\n".join(md))
    print(f"wrote {len(list(ANALYSES_DIR.glob('q*.sql')))} result CSVs + business_answers.md")


if __name__ == "__main__":
    main()
