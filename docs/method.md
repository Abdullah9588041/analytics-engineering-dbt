# Modeling method

## Why a star schema
The analytical workload is slice-and-dice over trips (by time, zone, payment
method). A star schema — one narrow fact at trip grain plus small conformed
dimensions — gives every downstream query the same join paths and the same
definitions of measures (duration, speed, tip fraction are computed once in
`fact_trips`). This is the standard Kimball dimensional-modeling pattern and
is what analytics-engineering roles expect to see.

## Grain and keys
- **Grain of `fact_trips`:** one row per cleaned taxi trip. The TLC feed has no
  trip id, so `trip_key` is an md5 surrogate over the full natural key.
- **Dimensions:** `dim_zones` (TLC zone lookup, static over the 3-month window —
  treated as a Type-1/as-is dimension, no SCD handling needed), `dim_payment_type`
  (static code mapping).
- Trips join dimensions with **LEFT JOIN**, not INNER: dropping trips with an
  unmapped zone would silently bias totals. Orphan keys are caught loudly by
  the singular test `assert_fact_trips_zones_resolve` instead.

## Staging vs marts
- **Staging** (`stg_yellow_tripdata`) is a **view**: it is cheap (predicate
  pushdown into the parquet scan) and always reflects the current raw files.
- **Marts** are **tables**: they are queried repeatedly (dashboards, analyses)
  and benefit from being materialized once per `dbt build`.

## Cleaning decisions (staging)
- Exact-duplicate rows removed with `ROW_NUMBER()` over the natural key.
- Dropped: negative fares/distances/totals, pickup ≥ dropoff timestamps, and
  any pickup outside Jan–Mar 2024 (the documented data vintage).
- Kept: zero-fare trips (real — e.g. disputes/no-charge) and zero-distance
  trips with zero fare; `tip_fraction` is NULL (not 0) when fare is 0, because
  the rate is undefined, not zero.

## Test strategy
- **Generic (schema) tests:** `not_null`/`unique` on all keys, `relationships`
  from every fact foreign key to its dimension, `accepted_values` where the
  domain is closed.
- **Singular tests:** business invariants that generic tests cannot express —
  no negative money in the fact, pickup always before dropoff, every location
  id resolves to a zone.
- `dbt test` runs the full suite; CI runs `dbt build` + `dbt test` on every push.

## `dbt docs`
Run `dbt docs generate --profiles-dir .` inside `taxi_analytics/` then
`dbt docs serve` to browse the auto-generated DAG, model/column descriptions,
and test coverage from `schema.yml`.
