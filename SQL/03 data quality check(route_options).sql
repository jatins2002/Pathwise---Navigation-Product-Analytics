----checking for duplicate PK---
SELECT 
	route_id,
	COUNT(*) as duplicate_count
FROM pathwise.users
GROUP BY route_id
HAVING COUNT(*) > 1

--Foreign Key integrity--
---Is there any route option whose session_id does not exist in navigation_sessions?---
SELECT COUNT(*) as orphan_session
FROM pathwise.route_options ro
LEFT JOIN pathwise.navigation_sessions ns
ON ro.session_id = ns.session_id
WHERE ns.session_id is NULL

---DATA quality check-----
SELECT
    SUM(CASE WHEN route_id IS NULL THEN 1 ELSE 0 END) AS missing_route_id,
    SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) AS missing_session_id,
    SUM(CASE WHEN route_rank IS NULL THEN 1 ELSE 0 END) AS missing_route_rank,
    SUM(CASE WHEN route_type IS NULL THEN 1 ELSE 0 END) AS missing_route_type,
    SUM(CASE WHEN eta_minutes IS NULL THEN 1 ELSE 0 END) AS missing_eta_minutes,
    SUM(CASE WHEN distance_km IS NULL THEN 1 ELSE 0 END) AS missing_distance_km,
    SUM(CASE WHEN toll_amount IS NULL THEN 1 ELSE 0 END) AS missing_toll_amount,
    SUM(CASE WHEN traffic_score IS NULL THEN 1 ELSE 0 END) AS missing_traffic_score,
    SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END) AS missing_road_quality_score,
    SUM(CASE WHEN number_of_turns IS NULL THEN 1 ELSE 0 END) AS missing_number_of_turns,
    SUM(CASE WHEN traffic_uncertainty_score IS NULL THEN 1 ELSE 0 END) AS missing_traffic_uncertainty_score
FROM pathwise.route_options;

---Determine whether missing toll amount values are concentrated within specific route types.---
SELECT
    route_type,
    COUNT(*) AS total_routes,
    SUM(CASE WHEN toll_amount IS NULL THEN 1 ELSE 0 END) AS missing_toll_amount,
    ROUND(
        100.0 * SUM(CASE WHEN toll_amount IS NULL THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.route_options
GROUP BY route_type
ORDER BY missing_percentage DESC;

---Determine whether missing road quality scores are concentrated within specific route types.---
SELECT
    route_type,
    COUNT(*) AS total_routes,
    SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END)
        AS missing_road_quality_score,
    ROUND(
        100.0 * SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.route_options
GROUP BY route_type
ORDER BY missing_percentage DESC;

---Identify impossible or invalid numeric values in route option attributes.---

SELECT
    SUM(CASE WHEN eta_minutes <= 0 THEN 1 ELSE 0 END) AS invalid_eta,
    SUM(CASE WHEN distance_km < 0 THEN 1 ELSE 0 END) AS negative_distance,
    SUM(CASE WHEN toll_amount < 0 THEN 1 ELSE 0 END) AS negative_toll,
    SUM(CASE WHEN number_of_turns < 0 THEN 1 ELSE 0 END) AS negative_turns
FROM pathwise.route_options;


---Inspect the observed minimum and maximum values of route-level score attributes.---
SELECT
    MIN(traffic_score) AS min_traffic_score,
    MAX(traffic_score) AS max_traffic_score,

    MIN(road_quality_score) AS min_road_quality_score,
    MAX(road_quality_score) AS max_road_quality_score,

    MIN(traffic_uncertainty_score) AS min_uncertainty_score,
    MAX(traffic_uncertainty_score) AS max_uncertainty_score
FROM pathwise.route_options;

---ROUTE RANK VALIDATION---
SELECT
    route_rank,
    COUNT(*) AS route_count
FROM pathwise.route_options
GROUP BY route_rank
ORDER BY route_rank;

---Verify whether every navigation session contains exactly three route options.---
SELECT
    session_id,
    COUNT(*) AS route_count
FROM pathwise.route_options
GROUP BY session_id
HAVING COUNT(*) <> 3;

---Check whether route type values are consistent and free from spelling/case issues.---
SELECT
    route_type,
    COUNT(*) AS route_count
FROM pathwise.route_options
GROUP BY route_type
ORDER BY route_count DESC;