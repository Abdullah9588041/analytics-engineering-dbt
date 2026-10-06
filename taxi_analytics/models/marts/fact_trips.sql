{{ config(materialized='table') }}

/*
Fact table: one row per cleaned taxi trip (grain = trip).
- Joins the zone and payment dimensions; trips with unknown zones (ids 264/265
  exist in the lookup, but any future unknown id) are kept via LEFT JOIN so the
  fact stays complete — orphans are caught by a singular test instead of
  silently dropped by an INNER JOIN.
- Derives duration, average speed, pickup hour/day-of-week, and tip fraction
  once here so every downstream mart uses identical definitions.
*/

with trips as (
    select * from {{ ref('stg_yellow_tripdata') }}
),

joined as (
    select
        t.trip_key,
        pz.zone_key as pickup_zone_key,
        dz.zone_key as dropoff_zone_key,
        t.vendor_id,
        t.pickup_datetime,
        t.dropoff_datetime,
        t.passenger_count,
        t.trip_distance,
        t.rate_code_id,
        t.store_and_fwd_flag,
        t.payment_type,
        t.fare_amount,
        t.extra,
        t.mta_tax,
        t.tip_amount,
        t.tolls_amount,
        t.improvement_surcharge,
        t.total_amount,
        t.congestion_surcharge,
        t.airport_fee,
        t.pickup_location_id,
        t.dropoff_location_id
    from trips t
    left join {{ ref('dim_zones') }} pz
        on pz.zone_id = t.pickup_location_id
    left join {{ ref('dim_zones') }} dz
        on dz.zone_id = t.dropoff_location_id
)

select
    *,
    -- trip duration in minutes (guard against zero-second trips)
    date_diff('minute', pickup_datetime, dropoff_datetime) as duration_minutes,
    -- average speed in mph; null when duration is zero (avoids div-by-zero)
    case
        when date_diff('second', pickup_datetime, dropoff_datetime) > 0
        then trip_distance / (date_diff('second', pickup_datetime, dropoff_datetime) / 3600.0)
    end as avg_speed_mph,
    date_trunc('hour', pickup_datetime) as pickup_hour,
    -- DuckDB dayofweek: 0 = Sunday, 6 = Saturday
    cast(dayofweek(pickup_datetime) as integer) as pickup_day_of_week,
    -- tip as a fraction of fare; null when fare is zero (not zero — unknown)
    case
        when fare_amount > 0 then tip_amount / fare_amount
    end as tip_fraction
from joined
