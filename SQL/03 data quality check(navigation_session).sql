---DATA QUALITY CHECK---
---checking for duplicate PK---
SELECT
    session_id,
    COUNT(*) AS duplicate_count
FROM pathwise.navigation_sessions
GROUP BY session_id
HAVING COUNT(*) > 1;

----Funnel Consistency ANALYSIS----
---Identify sessions where the destination was reached but navigation was not marked as completed.---
SELECT COUNT(*) as count_session
FROM pathwise.navigation_sessions
WHERE destination_reached = TRUE
AND navigation_completed  = FALSE

---Identify sessions marked as completed even though navigation was not started.---
SELECT COUNT(*) as count_session
FROM pathwise.navigation_sessions
WHERE navigation_started = FALSE
AND navigation_completed = TRUE

---Identify sessions marked as abandoned even though the destination was reached.---
SELECT COUNT(*) as count_session
FROM pathwise.navigation_sessions
WHERE destination_reached = TRUE
AND session_abandoned = TRUE

---Identify sessions marked as both abandoned and completed.---
SELECT COUNT(*) as count_session
FROM pathwise.navigation_sessions
WHERE session_abandoned = TRUE 
AND navigation_completed = TRUE

---Identify sessions where the destination was reached even though navigation was not started.---
SELECT COUNT(*) as count_session
FROM pathwise.navigation_sessions
WHERE destination_reached = TRUE
AND navigation_started = FALSE

SELECT COUNT(*) AS missing_weather
FROM pathwise.navigation_sessions
WHERE weather_condition IS NULL;

SELECT COUNT(*) AS blank_weather
FROM pathwise.navigation_sessions
WHERE TRIM(weather_condition) = '';

select * from pathwise.navigation_sessions

SELECT
    SUM(CASE WHEN weather_condition IS NULL THEN 1 ELSE 0 END) AS missing_weather,

    SUM(CASE WHEN actual_duration_minutes IS NULL THEN 1 ELSE 0 END) AS missing_duration,
	SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END) AS missing_road_quality

FROM pathwise.navigation_sessions;

SELECT
    navigation_completed,
    COUNT(*) AS session_count
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NULL
GROUP BY navigation_completed;

SELECT
    destination_reached,
    COUNT(*) AS session_count
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes IS NULL
  AND navigation_completed = TRUE
GROUP BY destination_reached;

---checking road quality----
SELECT
    city,
    COUNT(*) AS missing_road_quality
FROM pathwise.navigation_sessions
WHERE  road_quality_score IS NULL
GROUP BY city
ORDER BY missing_road_quality DESC;

SELECT
    city,
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END) AS missing_road_quality
FROM pathwise.navigation_sessions
GROUP BY city;

SELECT
    city,
    COUNT(*) AS total_sessions,

    SUM(
        CASE WHEN road_quality_score IS NULL
        THEN 1 ELSE 0 END
    ) AS missing_road_quality,

    ROUND(
        SUM(CASE WHEN road_quality_score IS NULL THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS missing_percentage

FROM pathwise.navigation_sessions
GROUP BY city
ORDER BY missing_percentage DESC;

SELECT 
	city,
	COUNT(*) AS total_sessions,
	SUM(CASE WHEN weather_condition IS NULL THEN 1 ELSE 0 END) AS missing_weather,
	ROUND(
        SUM(CASE WHEN weather_condition IS NULL THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.navigation_sessions
GROUP BY city
ORDER BY missing_percentage DESC;

--Foreign Key integrity--
---“Find sessions whose user_id does not exist in users.”---
SELECT COUNT(*) as orphan_session
FROM pathwise.navigation_sessions ns
LEFT JOIN pathwise.users  u
ON ns.user_id = u.user_id
WHERE u.user_id is NULL

---Identify logically invalid values in navigation session metrics.---
SELECT COUNT(*) as invlid_dist
FROM pathwise.navigation_sessions
WHERE distance_km < 0

---Verify that completed trip durations do not contain negative values.---
SELECT COUNT(*) invalid_time
FROM pathwise.navigation_sessions
WHERE actual_duration_minutes < 0

---Verify that reroute counts do not contain negative values.--
SELECT COUNT(*) invalid_route
FROM pathwise.navigation_sessions
WHERE reroute_count < 0

---Verify that recommended route ETA values do not contain zero or negative travel times.---
SELECT COUNT(*) invalid_time
FROM pathwise.navigation_sessions
WHERE recommended_eta_minutes <= 0

---Verify that selected route ETA values contain only positive travel times.---
SELECT COUNT(*) as invalid_time
FROM pathwise.navigation_sessions
WHERE selected_eta_minutes <= 0

---Verify that the number of turns does not contain negative values.--
SELECT COUNT(*) as invalid_turns
FROM pathwise.navigation_sessions
WHERE number_of_turns < 0

---Inspect the minimum and maximum road quality scores before validating their allowed range.---
SELECT 
	MIN(road_quality_score) as minimum_road_quality_scores,
	MAX(road_quality_score) as maximum_road_quality_scores
FROM pathwise.navigation_sessions

---Inspect the observed minimum and maximum traffic uncertainty scores.---
SELECT
	MIN(traffic_uncertainty_score) as minimum_traffic_uncertainty_scores,
	MAX(traffic_uncertainty_score) as maximum_traffic_uncertainty_scores
FROM pathwise.navigation_sessions

---Inspect the observed values of route complexity before validating the field.---
SELECT 
	MIN(route_complexity) as min_road_complexity,
	MAX(route_complexity) as max_road_complexity
FROM pathwise.navigation_sessions

---Verify whether route complexity is stored using an appropriate numeric data type.---
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'navigation_sessions'
  AND column_name = 'route_complexity';

---Verify that route complexity is stored using an appropriate numeric data type.----

  SELECT COUNT(*) AS non_numeric_route_complexity
FROM pathwise.navigation_sessions
WHERE route_complexity IS NOT NULL
  AND route_complexity !~ '^[0-9]+(\.[0-9]+)?$';

---Verify completeness and confirm whether the field is stored using an appropriate data type.---
SELECT COUNT(*) AS missing_route_complexity
FROM pathwise.navigation_sessions
WHERE route_complexity IS NULL;

---Verify that session start time is stored using an appropriate temporal data type.---
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'navigation_sessions'
  AND column_name = 'session_start_time';

---Verify that session date is stored using an appropriate date data type.---
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'navigation_sessions'
  AND column_name = 'session_date';


---Inspect the earliest and latest navigation session dates in the dataset.---
SELECT 
	MIN(session_date) as earliest_navigation_session_dates,
	MAX(session_date) as latest_navigation_session_dates
FROM pathwise.navigation_sessions