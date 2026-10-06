/*
Singular test: pickup must always precede dropoff in the fact table.
Staging filters impossible timestamps; this pins that invariant downstream.
*/

select trip_key, pickup_datetime, dropoff_datetime
from {{ ref('fact_trips') }}
where pickup_datetime >= dropoff_datetime
