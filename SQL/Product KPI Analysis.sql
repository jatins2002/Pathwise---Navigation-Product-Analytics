/*
Measure the percentage of navigation sessions in which users selected the route recommended by PathWise.
This KPI helps evaluate user acceptance of the product's route recommendation.*/
SELECT
    COUNT(*) AS total_sessions,

    COUNT(
        CASE
            WHEN recommended_route_id = selected_route_id THEN 1
        END
    ) AS accepted_sessions,

    ROUND(
        COUNT(
            CASE
                WHEN recommended_route_id = selected_route_id THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS route_acceptance_rate

FROM pathwise.navigation_sessions;


---Compare navigation completion outcomes between sessions that accepted and rejected the recommended route.
SELECT
    CASE
        WHEN recommended_route_id = selected_route_id THEN 'Accepted'
        ELSE 'Rejected'
    END AS recommendation_status,

    COUNT(*) AS total_sessions,

    COUNT(
        CASE
            WHEN navigation_completed = TRUE THEN 1
        END
    ) AS completed_sessions,

    ROUND(
        COUNT(
            CASE
                WHEN navigation_completed = TRUE THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate

FROM pathwise.navigation_sessions

GROUP BY
    CASE
        WHEN recommended_route_id = selected_route_id THEN 'Accepted'
        ELSE 'Rejected'
    END;

---Compare session abandonment rates between sessions that accepted and rejected the recommended route.
SELECT 
	CASE 
		WHEN recommended_route_id = selected_route_id THEN 'Accepted'
		ELSE 'Rejected'
		END as recommendation_status,

		COUNT(*) as total_sessions,

		COUNT(
        CASE
            WHEN session_abandoned = TRUE THEN 1
        END
    ) AS abandoned_sessions,

    ROUND(
        COUNT(
            CASE
                WHEN session_abandoned = TRUE THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate

FROM pathwise.navigation_sessions

GROUP BY
    CASE
        WHEN recommended_route_id = selected_route_id THEN 'Accepted'
        ELSE 'Rejected'
    END;

---Compare average reroute frequency between sessions that accepted and rejected the recommended route.
SELECT 
	CASE 
		WHEN recommended_route_id = selected_route_id THEN 'Accepted'
		ELSE 'Rejected'
	END as recommedation_status,

	COUNT(*) as total_sessions,

	ROUND(
		AVG(reroute_count),2) as avg_reroute_count
FROM pathwise.navigation_sessions
GROUP BY 	
		CASE 
			WHEN recommended_route_id = selected_route_id THEN 'Accepted'
		ELSE 'Rejected'
	END;

--- Compare recommended route acceptance rates across different traffic conditions
SELECT
    traffic_level,

    COUNT(*) AS total_sessions,

    COUNT(
        CASE
            WHEN recommended_route_id = selected_route_id THEN 1
        END
    ) AS accepted_sessions,

    ROUND(
        COUNT(
            CASE
                WHEN recommended_route_id = selected_route_id THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS acceptance_rate

FROM pathwise.navigation_sessions

GROUP BY traffic_level
ORDER BY acceptance_rate DESC;


---Compare recommended route acceptance rates across different recommended route types.
SELECT 	
	recommended_route_type,
	COUNT(*) AS total_sessions,
	COUNT(
		CASE 
			WHEN recommended_route_id = selected_route_id THEN 1
			END
		) as accepted_sessions,
	ROUND(
		COUNT(
			CASE 
				WHEN recommended_route_id = selected_route_id THEN 1
			END
		) * 100.0 / COUNT(*),
		2
	) as acceptance_rate
FROM pathwise.navigation_sessions
GROUP BY recommended_route_type
ORDER BY acceptance_rate DESC;

---Compare recommended route acceptance rates across different levels of traffic uncertainty.
WITH uncertainity_groups AS(
	SELECT
		session_id,
		recommended_route_id,
		selected_route_id,
		CASE 
			WHEN traffic_uncertainty_score < 0.33 THEN 'Low'
			WHEN traffic_uncertainty_score < 0.66 THEN 'Medium'
			ELSE 'High'
			END as uncertainty_level
		FROM pathwise.navigation_sessions
)
SELECT 
	uncertainty_level,
	COUNT(*) as total_sessions,
	SUM(
        CASE
            WHEN recommended_route_id = selected_route_id THEN 1
            ELSE 0
        END
    ) AS accepted_sessions,

    ROUND(
        SUM(
            CASE
                WHEN recommended_route_id = selected_route_id THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS acceptance_rate

FROM uncertainity_groups
GROUP BY uncertainty_level
ORDER BY acceptance_rate DESC;


---Compare recommended route acceptance rates across different levels of route complexity.
SELECT
	MIN(route_complexity) as min_route_complexity,
	PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY route_complexity) as route_p50,
	PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY route_complexity) as route_p95,
	PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY route_complexity) as route_p99,
	MAX(route_complexity) as max_route_complexity
FROM pathwise.navigation_sessions;

SELECT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY route_complexity) AS p25,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY route_complexity) AS p50,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY route_complexity) AS p75

FROM pathwise.navigation_sessions;

---Compare recommended route acceptance rates across low, medium, and high route complexity segments.
WITH complexity_groups AS (
    SELECT
        session_id,
        recommended_route_id,
        selected_route_id,

        CASE
            WHEN route_complexity <= 0.282 THEN 'Low'
            WHEN route_complexity <= 0.527 THEN 'Medium'
            ELSE 'High'
        END AS complexity_level

    FROM pathwise.navigation_sessions
)

SELECT
    complexity_level,

    COUNT(*) AS total_sessions,

    SUM(
        CASE
            WHEN recommended_route_id = selected_route_id THEN 1
            ELSE 0
        END
    ) AS accepted_sessions,

    ROUND(
        SUM(
            CASE
                WHEN recommended_route_id = selected_route_id THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS acceptance_rate

FROM complexity_groups
GROUP BY complexity_level
ORDER BY acceptance_rate DESC;


---Compare recommended route acceptance rates across different cities to identify geographic variation.
SELECT	
	city,
	COUNT(*) as total_sessions,
	SUM(
		CASE 	
			WHEN recommended_route_id = selected_route_id THEN 1
			ELSE 0
		END
	) as accepted_sessions,
	ROUND(
		SUM(
			CASE 
				WHEN recommended_route_id = selected_route_id THEN 1
				ELSE 0
			END
		) * 100.0 / COUNT(*),
		2
	) as acceptance_rate
FROM pathwise.navigation_sessions
GROUP BY city
ORDER BY acceptance_rate DESC;


---Compare recommended route acceptance rates across user device types.
SELECT 
	u.device_type,
	COUNT(*) as total_sessions,
	SUM(
		CASE 	
			WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
			ELSE 0 
			END
		) as accepted_sessions,
	ROUND(	
		SUM(
			CASE	
				WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
				ELSE 0 
				END
			) * 100.0 / COUNT(*),
			2
		 ) AS accepted_rate
FROM pathwise.navigation_sessions ns
INNER JOIN pathwise.users u
	ON ns.user_id = u.user_id
GROUP BY u.device_type
ORDER BY accepted_rate DESC;


---Compare recommended route acceptance rates between new and returning users.
SELECT 
	u.user_type,
	COUNT(*) as total_sessions,
	SUM(
		CASE 	
			WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
			ELSE 0 
			END
		) as accepted_sessions,
	ROUND(	
		SUM(
			CASE	
				WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
				ELSE 0 
				END
			) * 100.0 / COUNT(*),
			2
		 ) AS accepted_rate
FROM pathwise.navigation_sessions ns
INNER JOIN pathwise.users u
	ON ns.user_id = u.user_id
GROUP BY u.user_type
ORDER BY accepted_rate DESC;


---Compare recommended route acceptance rates across different user subscription types.
SELECT 
	u.subscription_type,
	COUNT(*) as total_sessions,
	SUM(
		CASE 	
			WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
			ELSE 0 
			END
		) as accepted_sessions,
	ROUND(	
		SUM(
			CASE	
				WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
				ELSE 0 
				END
			) * 100.0 / COUNT(*),
			2
		 ) AS accepted_rate
FROM pathwise.navigation_sessions ns
INNER JOIN pathwise.users u
	ON ns.user_id = u.user_id
GROUP BY u.subscription_type
ORDER BY accepted_rate DESC;


---Compare recommended route acceptance rates between sessions where the recommended route type matches the user's preferred route type and sessions where it does not.
SELECT 
	CASE
		WHEN ns.recommended_route_type = u.preferred_route_type
		THEN 'Preference Match'
		ELSE 'Preference Not Match'
	END as preference_status,
	
	COUNT(*) as total_sessions,
	
	SUM(
		CASE 
			WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
			ELSE 0
		END) as preference_count,

	ROUND(
		SUM(
			CASE
				WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
				ELSE 0
		END) * 100.0 / COUNT(*),
		2
		) as preference_rate
FROM pathwise.navigation_sessions ns
INNER JOIN pathwise.users u
ON ns.user_id = u.user_id
GROUP BY 
	CASE
		WHEN ns.recommended_route_type = u.preferred_route_type
		THEN 'Preference Match'
		ELSE 'Preference Not Match'
	END
ORDER BY preference_rate DESC;

---Compare recommended route acceptance rates across different weather conditions.
SELECT 
	weather_condition,
	COUNT(*) as total_sessions,
	SUM(
		CASE 
			WHEN recommended_route_id = selected_route_id THEN 1
			ELSE 0
			END
		) as acceptance_sessions,

	ROUND(
		SUM(
			CASE
				WHEN recommended_route_id = selected_route_id THEN 1
				ELSE 0
			END
		) * 100.0 / COUNT(*),
		2
	) AS acceptance_rate
FROM pathwise.navigation_sessions
GROUP BY weather_condition
ORDER BY acceptance_rate DESC;

/*
Ab tak strongest descriptive patterns:

Traffic uncertainty: 21.36 pp spread
Traffic level: 15.49 pp
City: 7.84 pp
Route complexity: 7.18 pp
Weather: 6.86 pp
Route type: 3.07 pp
Subscription: 0.52 pp
User type: 0.34 pp
Device: 0.04 pp
*/
	

