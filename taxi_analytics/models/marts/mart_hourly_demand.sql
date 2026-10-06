{{ config(materialized='table') }}

/*
Mart: hourly demand. Pickups and revenue by hour of day and day of week, with
window functions that answer "is this hour unusually busy?":
- 4-week trailing average for the same (hour, day-of-week) via a ROWS frame
- rank of each hour within its calendar day
- same-hour-last-week comparison via LAG (within an (hour, dow) partition,
  consecutive rows are exactly 7 days apart, so lag(..., 1) is last week)
*/

with hourly as (
    select
        date_trunc('hour', pickup_datetime) as pickup_hour,
        cast(dayofweek(pickup_datetime) as integer) as day_of_week,
        count(*) as trips,
        sum(total_amount) as revenue
    from {{ ref('fact_trips') }}
    group by 1, 2
)

select
    pickup_hour,
    day_of_week,
    trips,
    revenue,
    -- trailing 4-week average for this exact hour-of-week (frame clause)
    avg(trips) over (
        partition by extract(hour from pickup_hour), day_of_week
        order by pickup_hour
        rows between 3 preceding and current row
    ) as trips_4wk_avg_same_hour,
    -- how this hour ranks within its calendar day
    rank() over (
        partition by cast(pickup_hour as date)
        order by trips desc
    ) as hour_rank_in_day,
    -- same hour, previous week
    lag(trips, 1) over (
        partition by extract(hour from pickup_hour), day_of_week
        order by pickup_hour
    ) as trips_same_hour_last_week
from hourly
