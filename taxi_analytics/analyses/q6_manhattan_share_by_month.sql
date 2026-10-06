/*
Q6: Manhattan's share of pickups by month — is the core shrinking or stable?
*/
select
    date_trunc('month', f.pickup_datetime) as month,
    count(*) as trips,
    round(
        avg(case when z.borough = 'Manhattan' then 1.0 else 0.0 end), 4
    ) as manhattan_pickup_share
from {{ ref('fact_trips') }} f
join {{ ref('dim_zones') }} z on z.zone_key = f.pickup_zone_key
group by 1
order by 1
