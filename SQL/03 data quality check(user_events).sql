----checking for duplicate PK---
SELECT 
	event_id,
	COUNT(*) as duplicate_count
FROM pathwise.user_events
GROUP BY event_id
HAVING COUNT(*) > 1

select * from pathwise.user_events

--Foreign Key integrity--
---Verify that every event is associated with a valid navigation session.---
SELECT COUNT(*) as orphan_session
FROM pathwise.user_events ue
LEFT JOIN pathwise.navigation_sessions ns
ON ue.session_id = ns.session_id
WHERE ns.session_id is NULL

---Verify that every event is associated with a valid user.---
SELECT COUNT(*) as orphan_session
FROM pathwise.user_events ue
LEFT JOIN pathwise.users u
ON ue.user_id = u.user_id
WHERE u.user_id IS NULL

---Identify NULL values across key columns in the user_events table.---
SELECT
	SUM(CASE WHEN event_id IS NULL THEN 1 ELSE 0 END) as missing_id,
	SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) as missing_user_id,
	SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) as missing_session_id,
	SUM(CASE WHEN event_timestamp IS NULL THEN 1 ELSE 0 END) as missing_event_timestamp,
	SUM(CASE WHEN event_type IS NULL THEN 1 ELSE 0 END) as missing_event_type
FROM pathwise.user_events

---Identify distinct event types and detect potential spelling, casing, or categorical inconsistencies.
SELECT
	event_type,
	COUNT(*) as count_events
FROM pathwise.user_events
GROUP BY event_type
ORDER BY count_events 

---Identify the earliest and latest event timestamps to detect unexpected or potentially invalid date ranges.
SELECT
    MIN(event_timestamp) AS earliest_event,
    MAX(event_timestamp) AS latest_event
FROM pathwise.user_events;

---Verify that each event is associated with the same user who owns the corresponding navigation session.
SELECT
    COUNT(*) AS inconsistent_records
FROM pathwise.user_events e
JOIN pathwise.navigation_sessions s
    ON e.session_id = s.session_id
WHERE e.user_id <> s.user_id;

---Identify sessions where a navigation_completed event exists but the corresponding session is not marked as completed.
SELECT
    COUNT(DISTINCT e.session_id) AS inconsistent_sessions
FROM pathwise.user_events e
JOIN pathwise.navigation_sessions s
    ON e.session_id = s.session_id
WHERE e.event_type = 'navigation_completed'
  AND s.navigation_completed = FALSE;

---Identify sessions marked as completed that do not have a corresponding navigation_completed event in user_events.---
SELECT
    COUNT(*) AS inconsistent_sessions
FROM pathwise.navigation_sessions s
WHERE s.navigation_completed = TRUE
  AND NOT EXISTS (
      SELECT 1
      FROM pathwise.user_events e
      WHERE e.session_id = s.session_id
        AND e.event_type = 'navigation_completed'
  );


---Identify sessions where navigation_completed occurred before navigation_started, indicating an invalid event sequence.
SELECT
    COUNT(*) AS inconsistent_sessions
FROM (
    SELECT
        session_id,
        MIN(event_timestamp) FILTER (
            WHERE event_type = 'navigation_started'
        ) AS navigation_started_time,
        
        MIN(event_timestamp) FILTER (
            WHERE event_type = 'navigation_completed'
        ) AS navigation_completed_time

    FROM pathwise.user_events
    GROUP BY session_id
) AS event_sequence
WHERE navigation_started_time IS NOT NULL
  AND navigation_completed_time IS NOT NULL
  AND navigation_completed_time < navigation_started_time;