{{ config(materialized='view') }}

/*
Staging model for NYC Yellow Taxi trip data (Jan–Mar 2024).

- Reads the raw TLC parquet files directly with read_parquet (no ingestion step;
  the data vintage is documented in data/README.md).
- The TLC feed has no trip id and contains exact-duplicate rows: dedupe with
  ROW_NUMBER() partitioned over the full natural key.
- Drops physically impossible records: negative fares/distances/totals and
  pickup timestamps at/after dropoff.
- Casts everything to stable types and emits a surrogate trip_key for the
  fact table to join on.
*/

with raw as (
    select * from read_parquet('{{ var("raw_tripdata_glob") }}')
),

typed as (
    select
        cast(vendorid as integer)              as vendor_id,
        cast(tpep_pickup_datetime as timestamp)  as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
        cast(passenger_count as integer)       as passenger_count,
        cast(trip_distance as double)          as trip_distance,
        cast(ratecodeid as integer)            as rate_code_id,
        cast(store_and_fwd_flag as varchar)   as store_and_fwd_flag,
        cast(pulocationid as integer)          as pickup_location_id,
        cast(dolocationid as integer)          as dropoff_location_id,
        cast(payment_type as integer)          as payment_type,
        cast(fare_amount as double)            as fare_amount,
        cast(extra as double)                  as extra,
        cast(mta_tax as double)                as mta_tax,
        cast(tip_amount as double)             as tip_amount,
        cast(tolls_amount as double)           as tolls_amount,
        cast(improvement_surcharge as double)  as improvement_surcharge,
        cast(total_amount as double)           as total_amount,
        cast(congestion_surcharge as double)   as congestion_surcharge,
        cast(airport_fee as double)            as airport_fee
    from raw
),

deduped as (
    select *,
        row_number() over (
            partition by
                vendor_id, pickup_datetime, dropoff_datetime, passenger_count,
                trip_distance, pickup_location_id, dropoff_location_id,
                payment_type, fare_amount, tip_amount, total_amount
        ) as _dup_rank
    from typed
),

cleaned as (
    select * exclude (_dup_rank)
    from deduped
    where _dup_rank = 1
      and fare_amount >= 0                 -- negative fares are data errors
      and trip_distance >= 0
      and total_amount >= 0
      and pickup_datetime < dropoff_datetime  -- impossible timestamps
      and pickup_datetime >= timestamp '2024-01-01'
      and pickup_datetime <  timestamp '2024-04-01'
)

select
    {{ dbt_utils.generate_surrogate_key([
        'vendor_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count',
        'trip_distance', 'pickup_location_id', 'dropoff_location_id',
        'payment_type', 'fare_amount', 'tip_amount', 'total_amount'
    ]) }} as trip_key,
    *
from cleaned
