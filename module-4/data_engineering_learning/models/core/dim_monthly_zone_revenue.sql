with trips_data as (
    SELECT * FROM {{ ref("fact_trips") }}
)
SELECT
    pickup_zone,
    CAST(DATE_TRUNC(pickup_datetime, month) AS DATE) AS revenue_month,
    service_type,
    SUM(fare_amount) AS revenue_monthly_fare,
    SUM(extra) AS revenue_monthly_extra,
    SUM(mta_tax) AS revenue_monthly_mta_tax,
    SUM(tip_amount) AS revenue_monthly_tip_amount,
    SUM(tolls_amount) AS revenue_monthly_tolls_amount,
    SUM(improvement_surcharge) AS revenue_monthly_improvement_surcharge,
    SUM(total_amount) AS revenue_monthly_total_amount,
    COUNT(trip_id) AS total_monthly_trips,
    AVG(passenger_count) AS avg_monthly_passenger_count,
    AVG(trip_distance) AS avg_monthly_trip_distance
FROM trips_data
GROUP BY
    1,2,3