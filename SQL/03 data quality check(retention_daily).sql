----checking for duplicate user_id + activity_date----
SELECT 
	user_id,
	activity_date,
	COUNT(*) as duplicate_count
FROM pathwise.retention_daily
GROUP BY user_id, activity_date
HAVING COUNT(*) > 1

--Foreign Key integrity--
---Verify that every daily retention record is associated with a valid user.---
SELECT COUNT(*) as orphan_session
FROM pathwise.retention_daily re
LEFT JOIN pathwise.users u 
ON re.user_id = u.user_id
WHERE u.user_id IS NULL

---Identify missing values across all columns before performing retention analysis.---
SELECT
	COUNT(*) FILTER (WHERE user_id IS NULL) as missing_user_id,
	COUNT(*) FILTER (WHERE activity_date IS NULL) as missing_activity_date,
	COUNT(*) FILTER (WHERE active_flag IS NULL) as missing_active_flag,
	COUNT(*) FILTER (WHERE navigation_session_count IS NULL) as missing_navigation_session_count,
	COUNT(*) FILTER (WHERE successful_navigation_count IS NULL) as missing_successful_navigation_count
FROM pathwise.retention_daily

---Identify negative navigation and successful navigation counts.
SELECT
    COUNT(*) FILTER (
        WHERE navigation_session_count < 0
    ) AS inconsistent_navigation_session_count,

    COUNT(*) FILTER (
        WHERE successful_navigation_count < 0
    ) AS inconsistent_successful_navigation_count

FROM pathwise.retention_daily;

---Identify records where successful navigation count exceeds total navigation session count.---
SELECT
	COUNT(*) as inconsistent_count
FROM pathwise.retention_daily
WHERE successful_navigation_count > navigation_session_count;

---Identify records marked as inactive despite having recorded navigation sessions.---
SELECT
	COUNT(*) as inconsistent_records
FROM pathwise.retention_daily
WHERE navigation_session_count < 0
AND active_flag = FALSE

---Identify active records with zero navigation sessions for further investigation.---
SELECT
	COUNT(*) as inconsistent_records
FROM pathwise.retention_daily
WHERE active_flag = TRUE
AND navigation_session_count = 0

---Identify the earliest and latest activity dates available in the retention dataset.---
SELECT
	MIN(activity_date) as min_activity_date,
	MAX(activity_date) as max_activity_date
FROM pathwise.retention_daily

---Verify that active_flag contains only expected binary values.---
SELECT
	active_flag,
	COUNT(*) as binary_flag
FROM pathwise.retention_daily
GROUP BY active_flag

---Inspect the actual PostgreSQL data types of retention columns and identify inappropriate storage types.---
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'retention_daily'
ORDER BY ordinal_position;