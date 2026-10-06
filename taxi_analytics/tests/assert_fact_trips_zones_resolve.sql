/*
Singular test: every trip's pickup/dropoff location ids must resolve to a zone.
The fact uses LEFT JOINs (so no trip is silently dropped); this test fails
loudly if a location id has no dimension row.
*/

select f.trip_key, f.pickup_location_id, f.dropoff_location_id
from {{ ref('fact_trips') }} f
left join {{ ref('dim_zones') }} pz on pz.zone_id = f.pickup_location_id
left join {{ ref('dim_zones') }} dz on dz.zone_id = f.dropoff_location_id
where pz.zone_id is null or dz.zone_id is null
