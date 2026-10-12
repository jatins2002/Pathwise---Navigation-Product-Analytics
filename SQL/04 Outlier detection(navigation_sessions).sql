---Outlier Inspection---
---Inspect extreme values before deciding whether they represent genuine trips or potential data-quality issues.---
SELECT 
	MIN(distance_km) as min_distance,
	MAX(distance_km) as max_distance,
	MIN(actual_duration_minutes) as min_duration,
	MAX(actual_duration_minutes) as max_duration
FROM pathwise.navigation_sessions

---Inspect the distance distribution using percentiles before defining potential outliers.---
SELECT
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY distance_km) AS median_distance,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY distance_km) AS p95_distance,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY distance_km) AS p99_distance
FROM pathwise.navigation_sessions;

---Count navigation sessions with trip distances above the 99th percentile.---
SELECT COUNT(*) as sessions_above_p99
FROM pathwise.navigation_sessions
WHERE distance_km > 29.16

---Inspect the navigation sessions with the highest trip distances.---
SELECT 
	session_id, 
	distance_km,
	actual_duration_minutes,
	city
FROM pathwise.navigation_sessions
ORDER BY distance_km DESC
LIMIT 10

---Calculate the implied average travel speed for the highest-distance navigation sessions.---
SELECT
    session_id,
    distance_km,
    actual_duration_minutes,
    ROUND(
        distance_km / (actual_duration_minutes / 60.0),
        2
    ) AS avg_speed_kmh,
    city
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NOT NULL
  AND actual_duration_minutes > 0
ORDER BY distance_km DESC
LIMIT 10;


---Duration Outliers---
SELECT
    PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY actual_duration_minutes) AS median_duration,

    PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY actual_duration_minutes) AS p95_duration,

    PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY actual_duration_minutes) AS p99_duration,

    MAX(actual_duration_minutes) AS max_duration
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NOT NULL;

---Count navigation sessions with trip distances above the 99th percentile.---
SELECT COUNT(*) as sessions_above_p99_duration
FROM pathwise.navigation_sessions
WHERE distance_km > 64.6

---Inspect the navigation sessions with the highest durations minutes.---
SELECT 
    session_id, 
    distance_km,
    actual_duration_minutes,
    city
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NOT NULL
ORDER BY actual_duration_minutes DESC
LIMIT 10;

---Calculate implied average speed for the longest-duration navigation sessions.---
SELECT
    session_id,
    distance_km,
    actual_duration_minutes,
    ROUND(
        distance_km / (actual_duration_minutes / 60.0),
        2
    ) AS avg_speed_kmh,
    city
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NOT NULL
  AND actual_duration_minutes > 0
ORDER BY actual_duration_minutes DESC
LIMIT 10;