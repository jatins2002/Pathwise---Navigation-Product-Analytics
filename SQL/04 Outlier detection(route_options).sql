---ROUTE OPTION ETA AND DISTANCE RANGE---
SELECT
    MIN(eta_minutes) AS min_eta,
    MAX(eta_minutes) AS max_eta,
    MIN(distance_km) AS min_distance,
    MAX(distance_km) AS max_distance
FROM pathwise.route_options;

---Analyze ETA and distance distributions using key percentiles to identify potential outliers.---

SELECT
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY eta_minutes) AS eta_p50,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY eta_minutes) AS eta_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY eta_minutes) AS eta_p99,

    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY distance_km) AS distance_p50,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY distance_km) AS distance_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY distance_km) AS distance_p99
FROM pathwise.route_options;

---Investigate extreme ETA and distance values and evaluate their consistency using implied average travel speed.---
SELECT
    route_id,
    session_id,
    route_type,
    distance_km,
    eta_minutes,
    ROUND(
        distance_km / (eta_minutes / 60.0),
        2
    ) AS implied_speed_kmh
FROM pathwise.route_options
WHERE eta_minutes > 0
ORDER BY distance_km DESC
LIMIT 10;

---Investigate routes with the highest estimated travel times and evaluate their distance-ETA consistency.

SELECT
    route_id,
    session_id,
    route_type,
    distance_km,
    eta_minutes,
    ROUND(
        distance_km / (eta_minutes / 60.0),
        2
    ) AS implied_speed_kmh
FROM pathwise.route_options
WHERE eta_minutes > 0
ORDER BY eta_minutes DESC
LIMIT 10; 