"""Pipeline sanity checks on the built DuckDB warehouse.

These complement `dbt test` (which is the primary test suite): they verify the
warehouse file itself is healthy and that key business invariants hold on the
materialized tables.
"""
import os
import yaml
from pathlib import Path

import duckdb
import pytest

ROOT = Path(__file__).resolve().parents[1]
DUCKDB_PATH = ROOT / "taxi_analytics" / "taxi_analytics.duckdb"

EXPECTED_TABLES = {
    # dbt-duckdb prefixes schemas with the database name
    "main_staging": ["stg_yellow_tripdata", "taxi_zone_lookup"],
    "main_marts": [
        "dim_zones", "dim_payment_type", "fact_trips",
        "mart_hourly_demand", "mart_revenue_by_zone", "mart_tip_analysis",
    ],
}


@pytest.fixture(scope="module")
def con():
    assert DUCKDB_PATH.exists(), "warehouse missing — run `dbt build` first"
    # The staging view reads raw parquet via a path relative to taxi_analytics/
    # (the directory dbt runs from), so queries must run from there too.
    os.chdir(ROOT / "taxi_analytics")
    c = duckdb.connect(str(DUCKDB_PATH), read_only=True)
    yield c
    c.close()


def test_all_models_materialized(con):
    for schema, tables in EXPECTED_TABLES.items():
        for t in tables:
            n = con.execute(
                f"select count(*) from {schema}.{t}"
            ).fetchone()[0]
            assert n > 0, f"{schema}.{t} is empty"


def test_fact_has_substantial_volume(con):
    n = con.execute("select count(*) from main_marts.fact_trips").fetchone()[0]
    assert n > 5_000_000, f"expected >5M cleaned trips, got {n}"


def test_no_negative_money(con):
    n = con.execute(
        "select count(*) from main_marts.fact_trips "
        "where total_amount < 0 or fare_amount < 0 or tip_amount < 0"
    ).fetchone()[0]
    assert n == 0


def test_pickup_before_dropoff(con):
    n = con.execute(
        "select count(*) from main_marts.fact_trips "
        "where pickup_datetime >= dropoff_datetime"
    ).fetchone()[0]
    assert n == 0


def test_trip_key_unique(con):
    n, distinct = con.execute(
        "select count(*), count(distinct trip_key) from main_marts.fact_trips"
    ).fetchone()
    assert n == distinct


def test_zone_relationships_hold(con):
    orphans = con.execute(
        """select count(*) from main_marts.fact_trips f
           left join main_marts.dim_zones pz on pz.zone_key = f.pickup_zone_key
           left join main_marts.dim_zones dz on dz.zone_key = f.dropoff_zone_key
           where pz.zone_key is null or dz.zone_key is null"""
    ).fetchone()[0]
    assert orphans == 0


def test_data_vintage_is_q1_2024(con):
    mn, mx = con.execute(
        "select min(pickup_datetime), max(pickup_datetime) from main_marts.fact_trips"
    ).fetchone()
    assert str(mn) >= "2024-01-01" and str(mx) < "2024-04-01"


def test_schema_yml_defines_tests():
    schema = yaml.safe_load(
        (ROOT / "taxi_analytics" / "models" / "schema.yml").read_text()
    )
    models = {m["name"]: m for m in schema["models"]}
    assert "fact_trips" in models
    cols = {c["name"]: c for c in models["fact_trips"]["columns"]}
    assert "tests" in cols["trip_key"], "trip_key should have generic tests"
