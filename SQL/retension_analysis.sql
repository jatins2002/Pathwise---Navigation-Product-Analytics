-- Route Acceptance vs 7-Day Future Retention

SELECT
    CASE
        WHEN s.recommended_route_id = s.selected_route_id
        THEN 'Accepted'
        ELSE 'Rejected'
    END AS route_status,

    COUNT(*) AS total_sessions,

    COUNT(*) FILTER (
        WHERE r.active_flag = TRUE
    ) AS d7_active_sessions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.active_flag = TRUE
        ) / COUNT(*),
        2
    ) AS d7_retention_rate

FROM pathwise.navigation_sessions AS s

INNER JOIN pathwise.retention_daily AS r
    ON s.user_id = r.user_id
    AND r.activity_date = s.session_date + 7

GROUP BY
    CASE
        WHEN s.recommended_route_id = s.selected_route_id
        THEN 'Accepted'
        ELSE 'Rejected'
    END

ORDER BY route_status;

/*
Route acceptance showed very little difference in 7-day future retention (22.59% vs 23.03%).
*/

-- Navigation Completion vs 7-Day Future Retention
SELECT
    CASE
        WHEN ns.navigation_completed = TRUE
        THEN 'Completed'
        ELSE 'Not Completed'
    END AS route_status,

    COUNT(*) AS total_sessions,

    COUNT(*) FILTER (
        WHERE r.active_flag = TRUE
    ) AS d7_active_sessions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.active_flag = TRUE
        ) / COUNT(*),
        2
    ) AS d7_retention_rate

FROM pathwise.navigation_sessions AS ns

INNER JOIN pathwise.retention_daily AS r
    ON ns.user_id = r.user_id
    AND r.activity_date = ns.session_date + 7

GROUP BY
    CASE
        WHEN ns.navigation_completed = TRUE
        THEN 'Completed'
        ELSE 'Not Completed'
    END

ORDER BY route_status;

-- Session Abandonment vs 7-Day Future Retention
SELECT
    CASE
        WHEN ns.session_abandoned = TRUE
        THEN 'Abandent'
        ELSE 'Not Abandent'
    END AS route_status,

    COUNT(*) AS total_sessions,

    COUNT(*) FILTER (
        WHERE r.active_flag = TRUE
    ) AS d7_active_sessions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.active_flag = TRUE
        ) / COUNT(*),
        2
    ) AS d7_retention_rate

FROM pathwise.navigation_sessions AS ns

INNER JOIN pathwise.retention_daily AS r
    ON ns.user_id = r.user_id
    AND r.activity_date = ns.session_date + 7

GROUP BY
    CASE
        WHEN ns.session_abandoned = TRUE
        THEN 'Abandent'
        ELSE 'Not Abandent'
    END 

ORDER BY route_status;

-- Rerouting vs 7-Day Future Retention
SELECT
    CASE
        WHEN ns.reroute_count > 0
        THEN 'ReRoute'
        ELSE 'No ReRoute'
    END AS route_status,

    COUNT(*) AS total_sessions,

    COUNT(*) FILTER (
        WHERE r.active_flag = TRUE
    ) AS d7_active_sessions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE r.active_flag = TRUE
        ) / COUNT(*),
        2
    ) AS d7_retention_rate

FROM pathwise.navigation_sessions AS ns

INNER JOIN pathwise.retention_daily AS r
    ON ns.user_id = r.user_id
    AND r.activity_date = ns.session_date + 7

GROUP BY
    CASE
        WHEN ns.reroute_count > 0
        THEN 'ReRoute'
        ELSE 'No ReRoute'
    END

ORDER BY route_status;