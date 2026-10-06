/*
Q4: Which zone pairs have the longest trips on average? (min 500 trips for stability)
Note: 242 trips (0.003%) record physically impossible distances (up to
312k miles — GPS/meter errors, a known TLC quirk). They are excluded here so
a handful of bad rows cannot dominate the averages.
*/
select
    pz.zone_name as pickup_zone,
    dz.zone_name as dropoff_zone,
    count(*) as trips,
    round(avg(f.trip_distance), 2) as avg_distance_miles,
    round(avg(f.total_amount), 2) as avg_total_usd
from {{ ref('fact_trips') }} f
join {{ ref('dim_zones') }} pz on pz.zone_key = f.pickup_zone_key
join {{ ref('dim_zones') }} dz on dz.zone_key = f.dropoff_zone_key
where f.trip_distance < 100
group by 1, 2
having count(*) >= 500
order by avg_distance_miles desc
limit 15
