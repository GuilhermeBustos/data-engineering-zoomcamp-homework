WITH trips AS (
    SELECT * FROM {{ ref("fact_trips") }}
),
vendors AS (
    SELECT
    DISTINCT
        vendor_id,
        {{ get_vendor_data('vendor_id') }} AS vendor_name
    FROM {{ ref("fact_trips") }}
)
SELECT *
FROM vendors