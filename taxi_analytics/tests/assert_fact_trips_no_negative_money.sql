/*
Singular test: no trip in the fact table may carry a negative money amount.
The staging layer already filters these; this test guards the fact build
against regressions (e.g. a bad join duplicating rows with sign flips).
*/

select trip_key, fare_amount, tip_amount, total_amount
from {{ ref('fact_trips') }}
where total_amount < 0 or fare_amount < 0 or tip_amount < 0
