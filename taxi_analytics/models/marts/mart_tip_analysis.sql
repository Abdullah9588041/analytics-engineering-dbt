{{ config(materialized='table') }}

/*
Mart: tipping behavior by payment type and hour of day.
Uses conditional aggregation to compute, per group:
- average tip fraction (of fare)
- tipped-trip rate: fraction of trips where any tip was left
- aggregate tip rate: total tips / total fares (dollar-weighted, so it differs
  from the simple average when big fares tip differently)
*/

select
    f.payment_type,
    p.payment_method,
    extract(hour from f.pickup_datetime) as pickup_hour,
    count(*) as trips,
    avg(f.tip_fraction) as avg_tip_fraction,
    -- conditional aggregation: share of trips with a tip > 0
    avg(case when f.tip_amount > 0 then 1.0 else 0.0 end) as tipped_trip_rate,
    -- dollar-weighted tip rate
    sum(case when f.tip_amount > 0 then f.tip_amount else 0.0 end)
        / nullif(sum(f.fare_amount), 0) as aggregate_tip_rate
from {{ ref('fact_trips') }} f
left join {{ ref('dim_payment_type') }} p
    on p.payment_type = f.payment_type
group by 1, 2, 3
