{{ config(materialized='table') }}

/*
Dimension: taxi zones. Built from the official TLC zone lookup (loaded as a
dbt seed so the mapping is version-controlled). Treated as a static dimension:
zone boundaries did not change during the 3-month window, so no SCD handling.
*/

select
    {{ dbt_utils.generate_surrogate_key(['locationid']) }} as zone_key,
    cast(locationid as integer) as zone_id,
    borough,
    zone as zone_name,
    service_zone
from {{ ref('taxi_zone_lookup') }}
