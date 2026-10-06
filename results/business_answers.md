# Business answers (from `dbt build` + analyses)

All numbers below were produced by running the SQL in `taxi_analytics/analyses/` against the built warehouse.

## Q1 — Busiest pickup hours (day_of_week: 0=Sun..6=Sat)

| day_of_week | pickup_hour_of_day | trips | revenue_usd |
| --- | --- | --- | --- |
| 4 | 18 | 119107 | 3293524.62 |
| 3 | 18 | 110887 | 3030756.16 |
| 4 | 17 | 107423 | 3192712.01 |
| 3 | 17 | 103988 | 3011938.98 |
| 4 | 19 | 103756 | 2911231.6 |
| 5 | 18 | 102906 | 2826449.39 |
| 4 | 21 | 101333 | 2695636.24 |
| 2 | 18 | 99586 | 2676754.28 |
| 5 | 19 | 97641 | 2664239.28 |
| 4 | 20 | 97254 | 2620858.71 |

## Q2 — Airport vs non-airport revenue

| trip_origin | trips | revenue_usd | revenue_share |
| --- | --- | --- | --- |
| non-airport | 8997854 | 225565646.1 | 0.8691 |
| airport | 417205 | 33965574.37 | 0.1309 |

## Q3 — Tipping by payment method

| payment_method | trips | avg_tip_fraction_of_fare | tipped_trip_rate |
| --- | --- | --- | --- |
| Credit card | 7257717 | 0.27 | 0.9486 |
| Cash | 1300638 | 0.0 | 0.0 |
| Not recorded | 730502 | 0.046 | 0.2092 |
| Dispute | 82574 | 0.0011 | 0.0013 |
| No charge | 43628 | 0.0006 | 0.0037 |

## Q4 — Longest trips by zone pair (min 500 trips)

| pickup_zone | dropoff_zone | trips | avg_distance_miles | avg_total_usd |
| --- | --- | --- | --- | --- |
| JFK Airport | Riverdale/North Riverdale/Fieldston | 518 | 26.38 | 126.36 |
| JFK Airport | Spuyten Duyvil/Kingsbridge | 527 | 24.56 | 117.04 |
| Battery Park City | JFK Airport | 865 | 24.12 | 94.07 |
| JFK Airport | Sunset Park West | 740 | 23.69 | 105.65 |
| JFK Airport | Battery Park City | 2285 | 23.49 | 95.39 |
| JFK Airport | Carroll Gardens | 1267 | 23.47 | 109.48 |
| JFK Airport | World Trade Center | 2547 | 23.06 | 94.13 |
| JFK Airport | Windsor Terrace | 825 | 22.86 | 105.45 |
| East Elmhurst | Outside of NYC | 578 | 22.29 | 137.69 |
| LaGuardia Airport | Outside of NYC | 4341 | 22.27 | 139.97 |
| JFK Airport | Cobble Hill | 820 | 22.25 | 105.43 |
| JFK Airport | Inwood | 550 | 21.95 | 92.18 |
| Meatpacking/West Village West | JFK Airport | 663 | 21.95 | 95.39 |
| JFK Airport | Financial District South | 1068 | 21.94 | 93.53 |
| World Trade Center | JFK Airport | 906 | 21.79 | 91.2 |

## Q5 — Weekend vs weekday

| day_type | trips | revenue_usd | avg_total_per_trip_usd | avg_distance_miles |
| --- | --- | --- | --- | --- |
| weekday | 6744086 | 188491099.68 | 27.95 | 4.07 |
| weekend | 2670973 | 71040120.79 | 26.6 | 4.0 |

## Q6 — Manhattan pickup share by month

| month | trips | manhattan_pickup_share |
| --- | --- | --- |
| 2024-01-01 00:00:00 | 2926183 | 0.8939 |
| 2024-02-01 00:00:00 | 2965997 | 0.9023 |
| 2024-03-01 00:00:00 | 3522879 | 0.8939 |
