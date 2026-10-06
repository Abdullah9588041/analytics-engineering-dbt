{{ config(materialized='table') }}

/*
Dimension: payment type. The TLC codes are stable integers; this model turns
them into a readable dimension instead of leaving magic numbers in the fact.
Code 0 occurs in the raw feed (payment type not recorded) and is mapped
explicitly rather than dropped, so the fact keeps every trip.
*/

with codes (payment_type, payment_method) as (
    values
        (0, 'Not recorded'),
        (1, 'Credit card'),
        (2, 'Cash'),
        (3, 'No charge'),
        (4, 'Dispute'),
        (5, 'Unknown'),
        (6, 'Voided trip')
)

select
    {{ dbt_utils.generate_surrogate_key(['payment_type']) }} as payment_key,
    payment_type,
    payment_method
from codes
