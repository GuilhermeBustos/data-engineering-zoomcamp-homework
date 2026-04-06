## Answers to module 1 questions

### For the trips in November 2025 (lpep_pickup_datetime between '2025-11-01' and '2025-12-01', exclusive of the upper bound), how many trips had a trip_distance of less than or equal to 1 mile?

8,007

```sql
SELECT *
FROM public.green_taxi_data gtd
WHERE gtd."lpep_pickup_datetime" between '2025-11-01' and '2025-12-01'
AND gtd."trip_distance" <= 1;
```

### Which was the pick up day with the longest trip distance? Only consider trips with trip_distance less than 100 miles (to exclude data errors). Use the pick up time for your calculations.

2025-11-14

```sql
SELECT
	gtd."lpep_pickup_datetime"
FROM public.green_taxi_data gtd
WHERE gtd."trip_distance" = (SELECT MAX(gtd."trip_distance") FROM public.green_taxi_data gtd WHERE gtd."trip_distance" <= 100);
```

### Which was the pickup zone with the largest total_amount (sum of all trips) on November 18th, 2025?

East Harlem North

```sql
SELECT
	z."Zone" as pickup_zone,
	SUM(gtd."total_amount") AS sum_total_amount
FROM public.green_taxi_data gtd
INNER JOIN public.zones z
	ON gtd."PULocationID" = z."LocationID"
WHERE DATE(gtd."lpep_pickup_datetime") = '2025-11-18'
GROUP BY
	z."Zone"
ORDER BY
	sum_total_amount DESC;
```

### For the passengers picked up in the zone named "East Harlem North" in November 2025, which was the drop off zone that had the largest tip?

Yorkville West

```sql
WITH pickup_zone AS (
	SELECT *
	FROM public.green_taxi_data gtd
	INNER JOIN public.zones puz
		ON gtd."PULocationID" = puz."LocationID"
	WHERE puz."Zone" = 'East Harlem North'
	AND DATE(gtd.lpep_pickup_datetime) BETWEEN '2025-11-01' AND '2025-11-30'
)
SELECT
	z."Zone" AS dropoff_zone,
	MAX(pz."tip_amount") AS max_tip_amount
FROM pickup_zone pz
INNER JOIN public.zones z
	ON pz."DOLocationID" = z."LocationID"
GROUP BY
	z."Zone"
ORDER BY
	max_tip_amount DESC;
```
