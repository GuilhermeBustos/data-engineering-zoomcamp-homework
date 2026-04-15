WITH green_tripdata AS (
    SELECT *,
    'Green' AS service_type
    FROM {{ ref('stg_green_tripdata') }}
),
yellow_tripdata AS (
    SELECT *,
    'Yellow' AS service_type
    FROM {{ ref('stg_yellow_tripdata') }}
),
trips_unioned AS (
    SELECT * FROM green_tripdata
    UNION ALL
    SELECT * FROM yellow_tripdata
),
dim_zones as (
    SELECT * FROM {{ ref('dim_zones') }}
)

SELECT
    -- Trip identifiers
    trips_unioned.trip_id,
    trips_unioned.vendor_id,
    trips_unioned.service_type,
    trips_unioned.rate_code_id,

    -- Location details (enriched with human-readable zone names from dimension)
    trips_unioned.pickup_location_id,
    pickup_zones.borough as pickup_borough,
    pickup_zones.zone as pickup_zone,
    trips_unioned.dropoff_location_id,
    dropoff_zones.borough as dropoff_borough,
    dropoff_zones.zone as dropoff_zone,

    -- Trip timing
    trips_unioned.pickup_datetime,
    trips_unioned.dropoff_datetime,
    trips_unioned.store_and_fwd_flag,

    -- Trip metrics
    trips_unioned.passenger_count,
    trips_unioned.trip_distance,
    {{ get_trip_duration_minutes('trips_unioned.pickup_datetime', 'trips_unioned.dropoff_datetime') }} as trip_duration_minutes,

    -- Payment breakdown
    trips_unioned.fare_amount,
    trips_unioned.extra,
    trips_unioned.mta_tax,
    trips_unioned.tip_amount,
    trips_unioned.tolls_amount,
    trips_unioned.improvement_surcharge,
    trips_unioned.total_amount,
    trips_unioned.payment_type,
    trips_unioned.payment_type_description
FROM trips_unioned
INNER JOIN dim_zones AS pickup_zones
    ON trips_unioned.pickup_location_id = pickup_zones.locationid
INNER JOIN dim_zones AS dropoff_zones
    ON trips_unioned.dropoff_location_id = dropoff_zones.locationid