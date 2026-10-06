# Data

## Source
NYC Taxi & Limousine Commission (TLC) trip record data — public, no authentication required.

| File | Source URL | Rows |
|---|---|---|
| `yellow_tripdata_2024-01.parquet` | https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet | 2,964,624 |
| `yellow_tripdata_2024-02.parquet` | https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet | 3,007,526 |
| `yellow_tripdata_2024-03.parquet` | https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-03.parquet | 3,582,628 |
| `taxi_zone_lookup.csv` | https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv | 265 zones |

**Total raw trips: 9,554,778.** Accessed 2026-10-06.

## Why 3 months
Jan–Mar 2024 keeps the warehouse build under a few minutes on a laptop while
still covering ~9.5M trips — plenty for stable zone/hour-level aggregates.
The pipeline reads `yellow_tripdata_*.parquet`, so extending the window is a
one-line change (download more months, rerun `dbt build`).

## Reproducing
```bash
python data/download.py   # re-downloads any missing files into data/raw/
```

Raw files are git-ignored (see `.gitignore`); the zone lookup is additionally
committed as a dbt seed (`taxi_analytics/seeds/taxi_zone_lookup.csv`) so the
dimension mapping is version-controlled.

## License note
TLC trip data is published by the NYC Taxi & Limousine Commission for public use.
