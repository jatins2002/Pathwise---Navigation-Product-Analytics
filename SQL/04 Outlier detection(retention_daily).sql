---Understand the distribution of daily navigation session counts and identify unusually high activity records.---
SELECT 
	MIN(navigation_session_count) as min_navigation_session_count,
	PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY navigation_session_count) as session_p50,
	PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY navigation_session_count) as session_p95,
	PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY navigation_session_count) as session_p99,
	MAX(navigation_session_count) as max_navigation_session_count
FROM pathwise.retention_daily

---Inspect records with unusually high daily navigation session counts and determine whether they appear plausible.
SELECT 
	COUNT(*) as session_count
FROM pathwise.retention_daily
WHERE navigation_session_count > 1

---Examine the frequency distribution of navigation session counts above the 99th percentile.
SELECT
    navigation_session_count,
    COUNT(*) AS record_count
FROM pathwise.retention_daily
WHERE navigation_session_count > 1
GROUP BY navigation_session_count
ORDER BY navigation_session_count;

---Inspect the highest daily navigation session counts together with successful navigation counts to assess whether the extreme records appear internally plausible.---
SELECT
	user_id,
	activity_date,
	active_flag,
	navigation_session_count,
	successful_navigation_count
FROM pathwise.retention_daily
ORDER BY navigation_session_count DESC
LIMIT 10;

---Examine the distribution of daily successfu navigation counts and identify unusually high values.
SELECT 
	MIN(successful_navigation_count) as min_successful_navigation_count,
	PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY successful_navigation_count) as session_p50,
	PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY successful_navigation_count) as session_p95,
	PERCENTILE_CONT(0.99) WITHIN GROUP(ORDER BY successful_navigation_count) as session_p99,
	MAX(successful_navigation_count) as max_successful_navigation_count
FROM pathwise.retention_daily;

---Examine the frequency distribution of successful navigation counts above the 99th percentile.---
SELECT
	COUNT(*) as total_counts
FROM pathwise.retention_daily
WHERE successful_navigation_count > 1;

---Examine how successful navigation counts above the 99th percentile are distributed across higher values.---
SELECT
    successful_navigation_count,
    COUNT(*) AS record_count
FROM pathwise.retention_daily
WHERE successful_navigation_count > 1
GROUP BY successful_navigation_count
ORDER BY successful_navigation_count;