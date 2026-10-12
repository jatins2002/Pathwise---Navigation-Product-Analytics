
SELECT 'users' AS table_name, COUNT(*) AS row_count
FROM pathwise.users

UNION ALL

SELECT 'navigation_sessions', COUNT(*)
FROM pathwise.navigation_sessions

UNION ALL

SELECT 'route_options', COUNT(*)
FROM pathwise.route_options

UNION ALL

SELECT 'user_events', COUNT(*)
FROM pathwise.user_events

UNION ALL

SELECT 'experiments', COUNT(*)
FROM pathwise.experiments

UNION ALL

SELECT 'retention_daily', COUNT(*)
FROM pathwise.retention_daily;
