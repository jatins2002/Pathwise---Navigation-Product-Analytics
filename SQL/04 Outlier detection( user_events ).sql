---Identify sessions with unusually high event counts that may indicate abnormal user behavior or logging issues.
WITH session_event_counts AS (
    SELECT
        session_id,
        COUNT(*) AS event_count
    FROM pathwise.user_events
    GROUP BY session_id
)

SELECT
    MIN(event_count) AS min_events,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY event_count) AS p50,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY event_count) AS p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY event_count) AS p99,
    MAX(event_count) AS max_events
FROM session_event_counts;

---Inspect sessions with the highest event counts and identify which event types contribute to unusually high activity.
SELECT
    session_id,
    COUNT(*) AS total_events,
    COUNT(*) FILTER (WHERE event_type = 'reroute') AS reroute_events
FROM pathwise.user_events
GROUP BY session_id
ORDER BY total_events DESC
LIMIT 10;

--- Verify that the number of reroute events recorded for each session matches the reroute_count stored in navigation_sessions.
WITH event_reroutes AS (
    SELECT
        session_id,
        COUNT(*) FILTER (
            WHERE event_type = 'reroute'
        ) AS event_reroute_count
    FROM pathwise.user_events
    GROUP BY session_id
)

SELECT
    COUNT(*) AS inconsistent_sessions
FROM event_reroutes e
JOIN pathwise.navigation_sessions s
    ON e.session_id = s.session_id
WHERE e.event_reroute_count <> s.reroute_count;

---Inspect sessions where the number of reroute events does not match the reroute_count stored in navigation_sessions.
WITH event_reroutes AS (
    SELECT
        session_id,
        COUNT(*) FILTER (
            WHERE event_type = 'reroute'
        ) AS event_reroute_count
    FROM pathwise.user_events
    GROUP BY session_id
)

SELECT
    e.session_id,
    e.event_reroute_count,
    s.reroute_count,
    e.event_reroute_count - s.reroute_count AS difference
FROM event_reroutes e
JOIN pathwise.navigation_sessions s
    ON e.session_id = s.session_id
WHERE e.event_reroute_count <> s.reroute_count
ORDER BY ABS(e.event_reroute_count - s.reroute_count) DESC
LIMIT 20;

---Determine whether reroute mismatches are primarily caused by missing reroute events or excess reroute events.
WITH event_reroutes AS (
    SELECT
        session_id,
        COUNT(*) FILTER (
            WHERE event_type = 'reroute'
        ) AS event_reroute_count
    FROM pathwise.user_events
    GROUP BY session_id
)

SELECT
    CASE
        WHEN e.event_reroute_count < s.reroute_count
            THEN 'Events Lower Than Session Count'
        WHEN e.event_reroute_count > s.reroute_count
            THEN 'Events Higher Than Session Count'
    END AS mismatch_type,
    COUNT(*) AS session_count
FROM event_reroutes e
JOIN pathwise.navigation_sessions s
    ON e.session_id = s.session_id
WHERE e.event_reroute_count <> s.reroute_count
GROUP BY 1
ORDER BY session_count DESC;

---Calculate the percentage of navigation sessions where reroute event counts do not match the session-level reroute count.

WITH event_reroutes AS (
    SELECT
        session_id,
        COUNT(*) FILTER (
            WHERE event_type = 'reroute'
        ) AS event_reroute_count
    FROM pathwise.user_events
    GROUP BY session_id
),

mismatches AS (
    SELECT
        COUNT(*) AS mismatch_count
    FROM event_reroutes e
    JOIN pathwise.navigation_sessions s
        ON e.session_id = s.session_id
    WHERE e.event_reroute_count <> s.reroute_count
)

SELECT
    mismatch_count,
    COUNT(*) AS total_sessions,
    ROUND(
        mismatch_count * 100.0 / COUNT(*),
        2
    ) AS mismatch_percentage
FROM pathwise.navigation_sessions
CROSS JOIN mismatches
GROUP BY mismatch_count;