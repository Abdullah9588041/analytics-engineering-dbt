/*
Q5: Weekend vs weekday demand and revenue.
*/
select
    case when pickup_day_of_week in (0, 6) then 'weekend' else 'weekday' end as day_type,
    count(*) as trips,
    round(sum(total_amount), 2) as revenue_usd,
    round(avg(total_amount), 2) as avg_total_per_trip_usd,
    round(avg(trip_distance), 2) as avg_distance_miles
from {{ ref('fact_trips') }}
group by 1
order by trips desc
