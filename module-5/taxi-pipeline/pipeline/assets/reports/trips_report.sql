/* @bruin

name: reports.trips_report
type: bq.sql

depends:
  - staging.trips

materialization:
  type: table
  strategy: time_interval
  incremental_key: pickup_date
  time_granularity: date

columns:
  - name: taxi_type
    type: string
    description: Type of taxi (yellow or green)
    primary_key: true
  - name: pickup_date
    type: date
    description: Date of pickup
    primary_key: true
  - name: trip_count
    type: integer
    description: Number of trips on this date
    checks:
      - name: non_negative
  - name: total_revenue
    type: float
    description: Total revenue from all trips on this date
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: float
    description: Average trip distance in miles
    checks:
      - name: non_negative

@bruin */

SELECT
  taxi_type,
  DATE(pickup_datetime) AS pickup_date,
  COUNT(*)              AS trip_count,
  SUM(total_amount)     AS total_revenue,
  AVG(trip_distance)    AS avg_trip_distance
FROM staging.trips
WHERE pickup_datetime >= '{{ start_datetime }}'
  AND pickup_datetime < '{{ end_datetime }}'
GROUP BY 1, 2
