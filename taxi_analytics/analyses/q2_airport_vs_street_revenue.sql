/*
Q2: Airports vs street hails — what share of revenue comes from airport trips?
Airport zones identified by name (JFK, LaGuardia, Newark).
*/
with flagged as (
    select
        case
            when z.zone_name ilike '%jfk%' or z.zone_name ilike '%la guardia%'
                 or z.zone_name ilike '%newark%'
            then 'airport'
            else 'non-airport'
        end as trip_origin,
        f.total_amount
    from {{ ref('fact_trips') }} f
    join {{ ref('dim_zones') }} z on z.zone_key = f.pickup_zone_key
)
select
    trip_origin,
    count(*) as trips,
    round(sum(total_amount), 2) as revenue_usd,
    round(sum(total_amount) / sum(sum(total_amount)) over (), 4) as revenue_share
from flagged
group by 1
order by revenue_usd desc
