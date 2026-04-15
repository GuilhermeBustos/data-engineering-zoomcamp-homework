SELECT 
    locationid,
    borough,
    zone,
    CASE
        WHEN service_zone = 'Boro Zone' THEN 'Green Zone'
        ELSE service_zone
    END AS service_zone
FROM {{ ref('taxi_zones_lookup') }}
WHERE borough != 'Unknown'