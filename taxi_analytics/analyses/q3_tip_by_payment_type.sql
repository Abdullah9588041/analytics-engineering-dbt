/*
Q3: How does tipping differ by payment method?
*/
select
    p.payment_method,
    count(*) as trips,
    round(avg(f.tip_fraction), 4) as avg_tip_fraction_of_fare,
    round(avg(case when f.tip_amount > 0 then 1.0 else 0.0 end), 4) as tipped_trip_rate
from {{ ref('fact_trips') }} f
join {{ ref('dim_payment_type') }} p on p.payment_type = f.payment_type
group by 1
order by trips desc
