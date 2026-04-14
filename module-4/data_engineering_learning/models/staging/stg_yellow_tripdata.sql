WITH source AS (
    SELECT * FROM {{ source('staging', 'yellow_tripdata') }}
),

renamed AS (
    SELECT
        -- identifiers (standardized naming for consistency across yellow/green)
        {{ dbt_utils.generate_surrogate_key(['vendorid', 'tpep_pickup_datetime', 'trip_distance', 'pulocationid', 'dolocationid']) }} AS trip_id,
        CAST(vendorid AS INTEGER) AS vendor_id,
        CAST(ratecodeid AS INTEGER) AS rate_code_id,
        CAST(pulocationid AS INTEGER) AS pickup_location_id,
        CAST(dolocationid AS INTEGER) AS dropoff_location_id,
        -- timestamps (standardized naming)
        CAST(tpep_pickup_datetime AS TIMESTAMP) AS pickup_datetime,  -- tpep = Taxicab Passenger Enhancement Program (yellow taxis)
        CAST(tpep_dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,
        -- trip info
        CAST(store_and_fwd_flag AS STRING) AS store_and_fwd_flag,
        CAST(passenger_count AS INTEGER) AS passenger_count,
        CAST(trip_distance AS NUMERIC) AS trip_distance,
        -- payment info
        CAST(fare_amount AS NUMERIC) AS fare_amount,
        CAST(extra AS NUMERIC) AS extra,
        CAST(mta_tax AS NUMERIC) AS mta_tax,
        CAST(tip_amount AS NUMERIC) AS tip_amount,
        CAST(tolls_amount AS NUMERIC) AS tolls_amount,
        CAST(improvement_surcharge AS NUMERIC) AS improvement_surcharge,
        CAST(total_amount AS NUMERIC) AS total_amount,
        {{ safe_cast('payment_type', 'integer') }} AS payment_type,
        {{ get_payment_type_description('payment_type') }} AS payment_type_description

    FROM source
    WHERE vendorid IS NOT NULL
)

SELECT * FROM renamed

-- Sample records for dev environment using deterministic date filter
{% if target.name == 'dev' %}
WHERE pickup_datetime >= '2019-01-01' AND pickup_datetime < '2019-02-01'
{% endif %}