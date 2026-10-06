{{ config(materialized='table') }}

/*
Mart: revenue by pickup zone. Window functions rank zones and show
concentration: what share of total revenue comes from the top N zones
(cumulative share via a ROWS frame over the revenue-ranked ordering).
*/

with zone_revenue as (
    select
        z.borough,
        z.zone_name,
        count(*) as trips,
        sum(f.total_amount) as revenue,
        avg(f.total_amount) as avg_total_per_trip
    from {{ ref('fact_trips') }} f
    join {{ ref('dim_zones') }} z
        on z.zone_key = f.pickup_zone_key
    group by 1, 2
)

select
    borough,
    zone_name,
    trips,
    revenue,
    avg_total_per_trip,
    rank() over (order by revenue desc) as revenue_rank,
    -- each zone's share of total revenue (windowed grand total)
    revenue / sum(revenue) over () as revenue_share,
    -- cumulative share: how concentrated is revenue in the top zones?
    sum(revenue) over (
        order by revenue desc
        rows between unbounded preceding and current row
    ) / sum(revenue) over () as cumulative_revenue_share
from zone_revenue
