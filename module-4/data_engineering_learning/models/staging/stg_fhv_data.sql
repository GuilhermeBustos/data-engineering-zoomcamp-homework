WITH source AS (
    SELECT *
    FROM {{ source('staging', 'fhv_tripdata') }}
)
SELECT 
    dispatching_base_num,
    CAST(pickup_datetime AS TIMESTAMP) AS pickup_datetime,
    CAST(dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,
    CAST(PUlocationID AS INTEGER) AS pickup_location_id,
    CAST(DOlocationID AS INTEGER) AS dropoff_location_id,
    CAST(SR_Flag AS INTEGER) AS sr_flag,
    affiliated_base_number
FROM source
WHERE dispatching_base_num IS NOT NULL