/* @bruin

name: staging.trips
type: bq.sql

depends:
  - ingestion.trips
  - ingestion.payment_lookup

materialization:
  type: table
  strategy: time_interval
  incremental_key: pickup_datetime
  time_granularity: timestamp

columns:
  - name: pickup_datetime
    type: timestamp
    description: Trip pickup datetime
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: vendor_id
    type: integer
    description: Taxi vendor identifier
  - name: taxi_type
    type: string
    description: Type of taxi (yellow or green)
  - name: passenger_count
    type: integer
    description: Number of passengers
  - name: trip_distance
    type: float
    description: Trip distance in miles
    checks:
      - name: non_negative
  - name: pu_location_id
    type: integer
    description: Pickup location ID (TLC Taxi Zone)
  - name: do_location_id
    type: integer
    description: Dropoff location ID (TLC Taxi Zone)
  - name: payment_type
    type: integer
    description: Payment type code
  - name: payment_type_name
    type: string
    description: Payment type description (from lookup)
  - name: fare_amount
    type: float
    description: Metered fare amount
    checks:
      - name: non_negative
  - name: total_amount
    type: float
    description: Total amount charged
    checks:
      - name: non_negative
  - name: extracted_at
    type: timestamp
    description: Timestamp when the record was extracted

custom_checks:
  - name: no_future_pickups
    description: No trips with pickup_datetime in the future
    query: |
      SELECT COUNT(*)
      FROM staging.trips
      WHERE pickup_datetime > CURRENT_TIMESTAMP()
    value: 0

@bruin */

-- Deduplicate, clean, and enrich ingestion.trips for the current time window.
-- ROW_NUMBER deduplicates records that may appear from multiple append runs,
-- keeping the most recently extracted copy per logical trip.
WITH deduped AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY vendor_id, pickup_datetime, pu_location_id, do_location_id
      ORDER BY extracted_at DESC
    ) AS rn
  FROM ingestion.trips
  WHERE pickup_datetime >= '{{ start_datetime }}'
    AND pickup_datetime < '{{ end_datetime }}'
    AND pickup_datetime IS NOT NULL
    AND trip_distance >= 0
    AND total_amount >= 0
)
SELECT
  t.vendor_id,
  t.pickup_datetime,
  t.dropoff_datetime,
  t.passenger_count,
  t.trip_distance,
  t.ratecode_id,
  t.store_and_fwd_flag,
  t.pu_location_id,
  t.do_location_id,
  t.payment_type,
  p.payment_type_name,
  t.fare_amount,
  t.extra,
  t.mta_tax,
  t.tip_amount,
  t.tolls_amount,
  t.improvement_surcharge,
  t.total_amount,
  t.congestion_surcharge,
  t.taxi_type,
  t.extracted_at
FROM deduped t
LEFT JOIN ingestion.payment_lookup p
  ON t.payment_type = p.payment_type_id
WHERE t.rn = 1
