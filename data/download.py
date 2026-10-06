"""Download the raw NYC TLC data used by this project. Re-runnable: skips files that already exist."""
import urllib.request
from pathlib import Path

RAW = Path(__file__).resolve().parent / "raw"
RAW.mkdir(parents=True, exist_ok=True)

FILES = {
    # Yellow taxi trip records, Jan–Mar 2024 (~160 MB total, ~8.6M trips)
    "yellow_tripdata_2024-01.parquet": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet",
    "yellow_tripdata_2024-02.parquet": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-02.parquet",
    "yellow_tripdata_2024-03.parquet": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-03.parquet",
    # Official zone lookup (also loaded as a dbt seed)
    "taxi_zone_lookup.csv": "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv",
}


def main() -> None:
    for name, url in FILES.items():
        dest = RAW / name
        if dest.exists():
            print(f"skip (exists): {name}")
            continue
        print(f"downloading: {name} ...")
        urllib.request.urlretrieve(url, dest)
        print(f"  -> {dest} ({dest.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
