-- Route Acceptance by Traffic Level and Route Complexity
WITH segment_sessions AS (
SELECT 	
	traffic_level,
	CASE
		WHEN route_complexity <= 0.282 THEN 'Low Complexity'
		WHEN route_complexity <= 0.527 THEN 'Medium Complexity'
		ELSE 'High Complexity'
	END as complexity_segment,

	

		CASE 
			WHEN recommended_route_id = selected_route_id THEN 1
			ELSE 0
		END as route_accepted
		FROM pathwise.navigation_sessions
)

SELECT 
	traffic_level,
	complexity_segment,
	COUNT(*) as total_sessions,
	SUM(route_accepted) AS accepted_sessions,
	ROUND(	
		100.0 * SUM(route_accepted) / COUNT(*), 2) as acceptance_rate
FROM segment_sessions
GROUP BY 
		traffic_level,
	complexity_segment
ORDER BY 
	
    CASE traffic_level
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
    END,
    CASE complexity_segment
        WHEN 'Low Complexity' THEN 1
        WHEN 'Medium Complexity' THEN 2
        WHEN 'High Complexity' THEN 3
    END;

-- Observation:
-- Route acceptance consistently decreased as traffic level and route
-- complexity increased. Acceptance was highest for Low Traffic + Low
-- Complexity sessions (71.96%) and lowest for High Traffic + High
-- Complexity sessions (49.73%), representing a 22.23 percentage-point gap.


-- Route Acceptance by Traffic Uncertainty and Route Complexity
WITH segment_sessions AS (
SELECT 	
	CASE
		WHEN traffic_uncertainty_score <= 0.33 THEN 'Low Uncertainity'
		WHEN traffic_uncertainty_score <= 0.66 THEN 'Medium Uncertainity'
		ELSE 'High Uncertainity'
	END as Uncertainity_segment,

	CASE
		WHEN route_complexity <= 0.282 THEN 'Low Complexity'
		WHEN route_complexity <= 0.527 THEN 'Medium Complexity'
		ELSE 'High Complexity'
	END as complexity_segment,

		CASE 
			WHEN recommended_route_id = selected_route_id THEN 1
			ELSE 0
		END as route_accepted
		FROM pathwise.navigation_sessions
)

SELECT 
	Uncertainity_segment,
	complexity_segment,
	COUNT(*) as total_sessions,
	SUM(route_accepted) AS accepted_sessions,
	ROUND(	
		100.0 * SUM(route_accepted) / COUNT(*), 2) as acceptance_rate
FROM segment_sessions
GROUP BY 
		Uncertainity_segment,
	complexity_segment
ORDER BY 
	
    CASE Uncertainity_segment
        WHEN 'Low Uncertainity' THEN 1
        WHEN 'Medium Uncertainity' THEN 2
        WHEN 'High Uncertainity' THEN 3
    END,
    CASE complexity_segment
        WHEN 'Low Complexity' THEN 1
        WHEN 'Medium Complexity' THEN 2
        WHEN 'High Complexity' THEN 3
    END;

-- Observation:
-- Route acceptance consistently decreased as traffic uncertainty and route
-- complexity increased. Acceptance was highest for Low Uncertainty + Low
-- Complexity sessions (70.35%) and lowest for High Uncertainty + High
-- Complexity sessions (40.65%), representing a 29.70 percentage-point gap.
-- This indicates a strong combined association between uncertain traffic,
-- complex routes, and lower recommendation acceptance.

-- High-Uncertainty and High-Complexity Route Acceptance by City
SELECT	
	city,
	COUNT(*) as total_sessions,
	COUNT(*) FILTER (WHERE recommended_route_id = selected_route_id) as accepted_sessions,
	ROUND( 100.0 * 
		COUNT(*) FILTER (WHERE recommended_route_id = selected_route_id) / COUNT(*), 2) as accepted_sessions_rate
FROM pathwise.navigation_sessions
WHERE traffic_uncertainty_score >= 0.66 
AND route_complexity >= 0.527

GROUP BY city
ORDER BY accepted_sessions_rate ASC;

-- Observation:
-- Within the High-Uncertainty + High-Complexity segment, route acceptance
-- varied across cities. Seattle had the highest observed acceptance rate
-- (49.40%), while Toronto had the lowest (32.69%).
--
-- However, some city-level sample sizes were small, so these differences
-- should not be interpreted as reliable city rankings without further
-- statistical validation.


-- City Baseline vs High-Friction Route Acceptance
SELECT
	city,
	ROUND( 100.0 *
		COUNT(*) FILTER (WHERE recommended_route_id = selected_route_id) / COUNT(*), 
		2) as overall_acceptance_rate,

	ROUND(100.0 * 
		COUNT(*) FILTER (WHERE recommended_route_id = selected_route_id
						AND traffic_uncertainty_score >= 0.66
						AND route_complexity >= 0.527) / NULLIF(
            COUNT(*) FILTER (
                WHERE traffic_uncertainty_score >= 0.66
                  AND route_complexity > 0.527),0),
        2)as high_friction_rate,
		
		ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE recommended_route_id = selected_route_id
            ) / COUNT(*)
        )
        -
        (
            100.0 * COUNT(*) FILTER (
                WHERE recommended_route_id = selected_route_id
                  AND traffic_uncertainty_score >= 0.66
                  AND route_complexity > 0.527
            )
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE traffic_uncertainty_score >= 0.66
                      AND route_complexity > 0.527
                ),
                0
            )
        ),
        2
    ) AS acceptance_drop_pp
						
FROM pathwise.navigation_sessions

GROUP BY city

ORDER BY acceptance_drop_pp DESC;

-- Observation:
-- High-uncertainty and high-complexity sessions had lower route acceptance
-- than the overall city baseline across all analyzed cities.
--
-- The observed acceptance decline varied substantially by city, ranging
-- from approximately 10 to 29 percentage points. This suggests that the
-- high-friction pattern is not isolated to a single market, although
-- city-level differences should be interpreted cautiously because
-- high-friction sample sizes vary across cities.


-- Route Acceptance by User Preference Match
SELECT
	CASE
		WHEN ns.recommended_route_type = u.preferred_route_type THEN 'Preffered'
		ELSE 'Not Prefeered'
	END as preference_status,

	COUNT(*) as total_sessions,
	COUNT(*) FILTER(WHERE ns.recommended_route_id = ns.selected_route_id) as accepted_sessions,
	ROUND( 100.0 * 
		COUNT(*) FILTER(WHERE ns.recommended_route_id = ns.selected_route_id) / 
		COUNT(*),
		2
	) as acceptance_rate
		
FROM pathwise.navigation_sessions as ns
INNER JOIN pathwise.users as u
	ON ns.user_id = u.user_id
GROUP BY 
		CASE
		WHEN ns.recommended_route_type = u.preferred_route_type THEN 'Preffered'
		ELSE 'Not Prefeered'
	END 
ORDER BY acceptance_rate DESC;

-- Observation:
-- Route acceptance was 73.42% when the recommended route type matched
-- the user's preferred route type, compared with 54.42% when it did not,
-- representing a 19.00 percentage-point difference.
--
-- This shows a strong association between user preference alignment
-- and route acceptance.


-- Route Acceptance by User Preference Match and Traffic Uncertainty
WITH preference_sessions AS (
SELECT 	
	CASE
		WHEN ns.traffic_uncertainty_score <= 0.33 THEN 'Low Uncertainity'
		WHEN ns.traffic_uncertainty_score <= 0.66 THEN 'Medium Uncertainity'
		ELSE 'High Uncertainity'
	END as uncertainity_segment,	
	CASE
         WHEN ns.recommended_route_type = u.preferred_route_type
         THEN 'Preference Match'
         ELSE 'Preference Mismatch'
        END AS preference_status,
	CASE 
		WHEN ns.recommended_route_id = ns.selected_route_id THEN 1
		ELSE 0
	END as route_accepted
	FROM pathwise.navigation_sessions as ns
	INNER JOIN pathwise.users as u 
	ON ns.user_id = u.user_id
)
SELECT	
	uncertainity_segment,
	preference_status,
	COUNT(*) as total_sessions,
	SUM(route_accepted) as accepted_sessions,
	ROUND(
			100.0 * SUM(route_accepted) / COUNT(*),2
	) as accepted_rate
FROM preference_sessions
GROUP BY
    uncertainity_segment,
    preference_status

ORDER BY
    CASE uncertainity_segment
        WHEN 'Low Uncertainty' THEN 1
        WHEN 'Medium Uncertainty' THEN 2
        WHEN 'High Uncertainty' THEN 3
    END,
    preference_status;
-- Observation:
-- Route acceptance was consistently higher when the recommended route type
-- matched the user's preferred route type across all traffic uncertainty levels.
-- The largest observed difference occurred in High-Uncertainty sessions,
-- where acceptance was 62.29% for Preference Match compared with 40.27%
-- for Preference Mismatch, a 22.02 percentage-point difference.


-- Segmentation Analysis - Final Observations
--
-- 1. Route acceptance decreased as traffic uncertainty and route complexity increased.
--    Low Uncertainty + Low Complexity: 70.35%
--    High Uncertainty + High Complexity: 40.65%
--
-- 2. The high-friction pattern appeared across multiple cities rather than
--    being isolated to a single market.
--
-- 3. User preference alignment showed a strong relationship with route acceptance.
--    Preference Match: 73.42%
--    Preference Mismatch: 54.42%
--
-- 4. Preference alignment remained important even under high traffic uncertainty.
--    High Uncertainty + Preference Match: 62.29%
--    High Uncertainty + Preference Mismatch: 40.27%
--
-- Overall, traffic uncertainty, route complexity, and preference alignment
-- emerged as important factors associated with route acceptance.
-- These findings represent associations and should not be interpreted as causal effects.