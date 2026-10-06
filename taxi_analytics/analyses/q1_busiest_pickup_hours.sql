/*
Q1: When is demand highest? Top 10 busiest (day-of-week, hour-of-day)
combinations, aggregated across all weeks in the window.
day_of_week: 0 = Sunday ... 6 = Saturday (DuckDB convention).
*/
select
    day_of_week,
    extract(hour from pickup_hour) as pickup_hour_of_day,
    sum(trips) as trips,
    round(sum(revenue), 2) as revenue_usd
from {{ ref('mart_hourly_demand') }}
group by 1, 2
order by trips desc
limit 10
