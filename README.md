# Analytics Engineering with dbt + DuckDB: NYC Taxi Trips

A production-style analytics engineering project: raw NYC Taxi & Limousine
Commission trip data (Jan–Mar 2024, **9,554,778 trips**) modeled with dbt into a
tested star schema on DuckDB, then used to answer real business questions.

This project exists to demonstrate **advanced SQL**: window functions with frame
clauses, CTEs, conditional aggregation, dimensional modeling, and a full dbt
test suite — the SQL depth that 2026 data postings require (window functions
and CTEs are "non-negotiable" in interviews).

## Problem statement

Raw TLC trip records are messy: no trip id, exact-duplicate rows, negative
fares, impossible timestamps, and cryptic integer codes for zones and payment
types. The goal: turn 9.5M raw rows into a **trusted, tested dimensional model**
(a star schema) that any analyst can query, plus a set of answered business
questions with reproducible numbers.

## Methodology

- **Staging** (`stg_yellow_tripdata`, a view): reads the raw parquet files
  directly, dedupes with `ROW_NUMBER()` over the natural key, drops invalid
  trips, casts types, and emits a surrogate `trip_key`.
- **Dimensions**: `dim_zones` (official TLC lookup, version-controlled as a dbt
  seed), `dim_payment_type` (code mapping).
- **Fact** (`fact_trips`, grain = one trip): joins dimensions with `LEFT JOIN`
  (orphan keys fail loudly via a singular test instead of vanishing), and
  derives `duration_minutes`, `avg_speed_mph`, `pickup_hour`,
  `pickup_day_of_week`, and `tip_fraction` once — so every mart agrees.
- **Marts**: `mart_hourly_demand` (windowed demand context), `mart_revenue_by_zone`
  (rank + revenue concentration), `mart_tip_analysis` (conditional aggregation).
- **Testing**: 20+ generic dbt tests (`not_null`, `unique`, `relationships`,
  `accepted_values`-style) plus 3 custom singular tests for business invariants.
- Modeling rationale is documented in [`docs/method.md`](docs/method.md).

## Results

### Pipeline
- Raw trips: **9,554,778** → cleaned fact rows: **9,415,059** (139,719 exact duplicates and invalid trips removed in staging)
- dbt: **37/37 checks pass** (1 seed, 7 models, 29 data tests — 1 staging view) in ~107s
- pytest pipeline checks: **8/8 pass**

### Business answers (from `taxi_analytics/analyses/`, run against the warehouse)
- **Busiest hour:** Thursday 18:00 — 119,107 pickups; weekday 17:00–21:00 dominates the top 10.
- **Airports:** 4.4% of trips but **13.1% of revenue** ($34.0M of $259.5M) — airport runs are the highest-value segment.
- **Tipping:** credit-card trips tip on 94.9% of rides (avg 27% of fare); cash trips record 0% tips (cash tips are invisible in the data — a measurement caveat, not a behavior claim).
- **Longest trips:** JFK Airport ↔ outer-borough pairs, ~23–26 miles on average (GPS-error outliers >100 mi excluded, 0.003% of trips).
- **Weekend vs weekday:** weekdays carry 71.6% of trips at slightly higher fares ($27.95 vs $26.60 avg).
- **Manhattan:** 89–90% of all pickups, stable across Jan–Mar 2024 — the yellow-taxi business is still a Manhattan business.

See [`results/business_answers.md`](results/business_answers.md) for the full
tables with real numbers.

## Quick start (3 commands)

```bash
pip install -r requirements.txt
python data/download.py                     # fetch raw TLC parquet (~160 MB)
cd taxi_analytics && dbt deps && dbt build --profiles-dir . && cd ..
```

Then:
```bash
python scripts/run_questions.py              # answer the business questions -> results/
python -m pytest tests/ -q                   # pipeline sanity checks
cd taxi_analytics && dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .
```

## Project structure

```
analytics-engineering-dbt/
├── taxi_analytics/            # dbt project
│   ├── dbt_project.yml        # staging=views, marts=tables
│   ├── profiles.yml           # DuckDB, project-local file
│   ├── packages.yml           # dbt_utils
│   ├── seeds/                 # taxi_zone_lookup.csv (version-controlled)
│   ├── models/
│   │   ├── staging/stg_yellow_tripdata.sql
│   │   ├── marts/dim_zones.sql, dim_payment_type.sql, fact_trips.sql
│   │   ├── marts/mart_hourly_demand.sql, mart_revenue_by_zone.sql, mart_tip_analysis.sql
│   │   └── schema.yml         # docs + generic tests
│   ├── tests/                 # 3 custom singular tests (business invariants)
│   └── analyses/              # 6 business questions as SQL
├── data/download.py           # re-runnable raw data fetcher
├── data/README.md             # source URLs, vintage, row counts
├── docs/method.md             # modeling decisions
├── scripts/run_questions.py   # executes analyses -> results/
├── results/                   # real result tables (CSV + MD)
├── tests/test_pipeline.py     # pytest sanity checks on the warehouse
└── .github/workflows/ci.yml   # dbt deps -> dbt build -> dbt test -> pytest
```

## Reproducibility
- Pinned dependencies (`requirements.txt`, verified 2026-10-06, Python 3.12).
- Documented data vintage (TLC Jan–Mar 2024, URLs + access date in `data/README.md`).
- Deterministic SQL: no sampling, no randomness anywhere in the pipeline.

## Limitations & future work
- **Window is 3 months** (Jan–Mar 2024) to keep builds laptop-friendly; the
  pipeline globs `yellow_tripdata_*.parquet`, so extending it is trivial.
- **No incremental models**: the fact is rebuilt each run. At larger scale,
  `fact_trips` would become incremental on `pickup_datetime`.
- **Zones are treated as static** (true for this window); a longer horizon
  would need SCD handling in `dim_zones`.
- TLC data is administrative, not a sample — aggregates describe the fleet,
  not "all NYC travel".
- Future: dbt snapshots for zone changes, exposures for the marts, a
  Streamlit dashboard on top of the marts.

## References
- NYC TLC trip record data: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
- dbt documentation: https://docs.getdbt.com
- dbt-duckdb: https://github.com/duckdb/dbt-duckdb
- Kimball dimensional modeling (star schemas, grains, conformed dimensions)
