---Measure the difference between event-level reroute counts and session-level reroute counts for mismatched sessions.
WITH event_reroute AS (
SELECT
	session_id,
	COUNT(*) FILTER (WHERE event_type = 'reroute') as event_reroute_count
FROM pathwise.user_events
GROUP BY session_id
)
SELECT 
	ns.session_id,
	ns.reroute_count as session_reroute_count,
	er.event_reroute_count,
	ns.reroute_count - er.event_reroute_count as difference
FROM pathwise.navigation_sessions as ns
JOIN event_reroute as er
ON ns.session_id = er.session_id
WHERE ns.reroute_count <> er.event_reroute_count
ORDER BY difference DESC;

---Measure how frequently each reroute count difference occurs across mismatched navigation sessions.
WITH event_reroute AS (
SELECT
	session_id,
	COUNT(*) FILTER (WHERE event_type = 'reroute') as event_reroute_count
FROM pathwise.user_events
GROUP BY session_id
),
reroute_comparison as (
SELECT
	ns.session_id,
	ns.reroute_count as session_reroute_count,
	er.event_reroute_count,
	ns.reroute_count - er.event_reroute_count as difference
FROM pathwise.navigation_sessions as ns
JOIN event_reroute as er
ON ns.session_id = er.session_id
WHERE ns.reroute_count <> er.event_reroute_count
)
SELECT 
	difference,
	COUNT(*) as count_session
FROM reroute_comparison
GROUP BY difference
ORDER BY difference;
/*
Cleaning decision

Isliye safest professional decision:

❌ user_events ko UPDATE nahi karenge.
❌ Fake reroute events create nahi karenge.
❌ navigation_sessions.reroute_count overwrite nahi karenge.

Instead issue document karenge, aur later analysis mein reroute metric ka source clearly specify karenge.
*/