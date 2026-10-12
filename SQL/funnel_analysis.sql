/*
Analyze user progression through the navigation funnel,
measure stage-level conversion rates, and identify where
users drop off before successfully reaching a destination.
*/

---Calculate the number of unique navigation sessions that reached each stage of the product funnel.
SELECT 
	event_type,
	COUNT(DISTINCT session_id) as count_session
FROM pathwise.user_events
GROUP BY event_type;

---Calculate conversion and drop-off rates between consecutive stages of the navigation funnel.
SELECT
    event_type,
    COUNT(DISTINCT session_id) AS count_session,

    CASE
        WHEN event_type = 'destination_search' THEN 1
        WHEN event_type = 'route_recommendation_view' THEN 2
        WHEN event_type = 'route_selected' THEN 3
        WHEN event_type = 'navigation_started' THEN 4
        WHEN event_type = 'navigation_completed' THEN 5
        WHEN event_type = 'destination_reached' THEN 6
    END AS stage_order

FROM pathwise.user_events

WHERE event_type IN (
    'destination_search',
    'route_recommendation_view',
    'route_selected',
    'navigation_started',
    'navigation_completed',
    'destination_reached'
)

GROUP BY event_type
ORDER BY stage_order;

---Measure the percentage of sessions progressing between consecutive funnel stages and identify where users
-- drop off during the navigation journey.
WITH funnel_counts AS (
	SELECT
	    event_type,
	    COUNT(DISTINCT session_id) AS count_session,
	
	    CASE
	        WHEN event_type = 'destination_search' THEN 1
	        WHEN event_type = 'route_recommendation_view' THEN 2
	        WHEN event_type = 'route_selected' THEN 3
	        WHEN event_type = 'navigation_started' THEN 4
	        WHEN event_type = 'navigation_completed' THEN 5
	        WHEN event_type = 'destination_reached' THEN 6
	    END AS stage_order

	FROM pathwise.user_events

	WHERE event_type IN (
    'destination_search',
    'route_recommendation_view',
    'route_selected',
    'navigation_started',
    'navigation_completed',
    'destination_reached'
	)

	GROUP BY event_type
),
funnel_with_previous AS(
	SELECT
		event_type,
		count_session,
		stage_order,
		LAG(count_session) OVER (ORDER BY stage_order) as prev_stage_sessions
	FROM funnel_counts
)
SELECT 
	event_type,
	count_session,
	ROUND((100.0 * count_session / prev_stage_sessions), 2) as conversion_rate,
	ROUND((100 - (100.0 * count_session / prev_stage_sessions)), 2) as drop_off_rate
FROM funnel_with_previous
ORDER BY stage_order;

--- Measure the percentage of sessions that progressed from destination search to successfully reaching a destination.
SELECT 
    COUNT(DISTINCT CASE 
        WHEN event_type = 'destination_search' THEN session_id 
    END) AS funnel_start_sessions,

    COUNT(DISTINCT CASE 
        WHEN event_type = 'destination_reached' THEN session_id 
    END) AS funnel_reached_sessions,

    ROUND(
        COUNT(DISTINCT CASE 
            WHEN event_type = 'destination_reached' THEN session_id 
        END) * 100.0
        /
        COUNT(DISTINCT CASE 
            WHEN event_type = 'destination_search' THEN session_id 
        END),
        2
    ) AS conversion_rate

FROM pathwise.user_events;

---Compare navigation completion rates across cities to identify geographic differences in post-start funnel performance.
SELECT 
	city,
	COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END) as funnel_navigation_started,
	COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END) as funnel_navigation_completed,
	ROUND(
		COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END
		)*100.0 / 
		COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END), 
		2) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY city
ORDER BY conversion_rate;


---Compare navigation completion rates across traffic conditions to investigate whether post-start funnel performance varies with traffic intensity.
SELECT 
	traffic_level,
	COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END) as funnel_navigation_started,
	COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END) as funnel_navigation_completed,
	ROUND(
		COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END
		)*100.0 / 
		COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END), 
		2) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY traffic_level
ORDER BY conversion_rate;


---Compare navigation completion rates across reroute counts to investigate the relationship between rerouting frequency and post-start funnel performance.
SELECT 
	reroute_count,
	COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END) as funnel_navigation_started,
	COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END) as funnel_navigation_completed,
	ROUND(
		COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END
		)*100.0 / 
		COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END), 
		2) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY reroute_count
ORDER BY conversion_rate;


---Compare navigation completion rates across traffic conditions and reroute behavior to investigate overlapping patterns associated with post-start funnel performance.
SELECT 
    traffic_level,

    CASE
        WHEN reroute_count = 0 THEN '0 Reroutes'
        WHEN reroute_count = 1 THEN '1 Reroute'
        ELSE '2+ Reroutes'
    END AS reroute_group,

    COUNT(DISTINCT CASE 
        WHEN navigation_started = TRUE THEN session_id 
    END) AS funnel_navigation_started,

    COUNT(DISTINCT CASE 
        WHEN navigation_completed = TRUE THEN session_id 
    END) AS funnel_navigation_completed,

    ROUND(
        COUNT(DISTINCT CASE 
            WHEN navigation_completed = TRUE THEN session_id 
        END) * 100.0 /
        COUNT(DISTINCT CASE 
            WHEN navigation_started = TRUE THEN session_id 
        END),
        2
    ) AS conversion_rate

FROM pathwise.navigation_sessions

GROUP BY 
    traffic_level,
    CASE
        WHEN reroute_count = 0 THEN '0 Reroutes'
        WHEN reroute_count = 1 THEN '1 Reroute'
        ELSE '2+ Reroutes'
    END

ORDER BY traffic_level, reroute_group;

---Examine the distribution of route complexity before creating meaningful complexity segments for funnel analysis.
SELECT 
	MIN(route_complexity) as min_route_complexity,
	AVG(route_complexity) as avg_route_complexity,
	PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY route_complexity) as median_route_complexity,
	MAX(route_complexity) as max_route_complexity
FROM pathwise.navigation_sessions;


---Compare navigation completion rates across route complexity levels to investigate whether route complexity is associated with post-start funnel performance.
SELECT 
    CASE 
        WHEN route_complexity <= 0.30 THEN 'Low Complexity'
        WHEN route_complexity <= 0.60 THEN 'Medium Complexity'
        ELSE 'High Complexity'
    END AS complexity_group,

    COUNT(DISTINCT CASE WHEN navigation_started = TRUE THEN session_id END) as funnel_navigation_started,
	COUNT(DISTINCT CASE WHEN navigation_completed = TRUE THEN session_id END) as funnel_navigation_completed,
	ROUND(
        COUNT(DISTINCT CASE 
            WHEN navigation_completed = TRUE THEN session_id 
        END) * 100.0 /
        COUNT(DISTINCT CASE 
            WHEN navigation_started = TRUE THEN session_id 
        END),
        2
    ) AS conversion_rate
FROM pathwise.navigation_sessions

GROUP BY
    CASE 
        WHEN route_complexity <= 0.30 THEN 'Low Complexity'
        WHEN route_complexity <= 0.60 THEN 'Medium Complexity'
        ELSE 'High Complexity'
    END;

/*
Safe portfolio insight:

Navigation completion declined across higher route-complexity segments, 
from 75.76% for low-complexity routes to 67.82% for high-complexity routes, 
indicating an association between route complexity and post-start funnel performance.
*/
---INTERVIEW---
/*
Simple interview version:

“I found that navigation completion decreased from 75.76% for low-complexity routes to 67.82% for high-complexity routes. 
This shows an association between route complexity and completion, 
but I would investigate other factors before making a causal conclusion.”
*/


---Compare navigation completion rates across device types to investigate whether post-start funnel performance varies by user device.
SELECT 
    u.device_type,

    COUNT(DISTINCT CASE 
        WHEN ns.navigation_started = TRUE THEN ns.session_id 
    END) AS navigation_started_sessions,

    COUNT(DISTINCT CASE 
        WHEN ns.navigation_completed = TRUE THEN ns.session_id 
    END) AS navigation_completed_sessions,

    ROUND(
        COUNT(DISTINCT CASE 
            WHEN ns.navigation_completed = TRUE THEN ns.session_id 
        END) * 100.0 /
        COUNT(DISTINCT CASE 
            WHEN ns.navigation_started = TRUE THEN ns.session_id 
        END),
        2
    ) AS completion_rate

FROM pathwise.navigation_sessions ns

INNER JOIN pathwise.users u
    ON ns.user_id = u.user_id

GROUP BY u.device_type
ORDER BY completion_rate;

/*
So safe portfolio insight:
Navigation completion rates were nearly identical across iOS and Android users (72.49% vs. 72.55%), 
suggesting that device type does not appear to explain the observed post-start funnel drop-off at this aggregate level.
*/


---Compare navigation completion rates between new and returning users to investigate whether post-start funnel performance varies by user experience level.
SELECT 
	u.user_type,
	COUNT(DISTINCT CASE 
		WHEN ns.navigation_started = TRUE THEN ns.session_id 
	END) as count_navigation_started,
	COUNT(DISTINCT CASE 
		WHEN ns.navigation_completed = TRUE THEN ns.session_id 
	END) as count_navigation_completed,
	ROUND(
	COUNT(DISTINCT CASE 
		WHEN ns.navigation_completed = TRUE THEN ns.session_id 
	END) * 100.0 /
	COUNT(DISTINCT CASE 
		WHEN ns.navigation_started = TRUE THEN ns.session_id 
	END), 
	2
	) as conversion_rate
FROM pathwise.navigation_sessions ns
INNER JOIN pathwise.users u
	ON ns.user_id = u.user_id
GROUP BY u.user_type
ORDER BY conversion_rate;
/*
Safe portfolio insight:
Navigation completion rates were similar for new and returning users (72.20% vs. 72.53%), 
suggesting that user type does not appear to explain 
the observed post-start funnel drop-off at the aggregate level.
*/

---Compare navigation completion rates across recommended route types to investigate whether post-start funnel performance varies by the type of route recommendation.
SELECT 
	recommended_route_type,
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END) as count_navigation_started,
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) as count_navigation_completed,
	ROUND(
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) * 100.0 /
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END), 
	2
	) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY recommended_route_type
ORDER BY conversion_rate;
/*
Safe portfolio insight:
Navigation completion rates were relatively consistent across recommended route types, 
ranging from 72.27% for Cheapest routes to 73.13% for Scenic routes, 
with a difference of only 0.86 percentage points.
*/

---Compare navigation completion rates across weather conditions to investigate whether post-start funnel performance varies under different weather conditions.
SELECT 
	weather_condition,
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END) as count_navigation_started,
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) as count_navigation_completed,
	ROUND(
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) * 100.0 /
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END), 
	2
	) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY weather_condition
ORDER BY conversion_rate;
/*
Safe portfolio insight:
Navigation completion varied across observed weather conditions. 
Snow sessions had the lowest completion rate at 66.97%, compared with 73.65% during clear conditions, 
indicating an association between adverse weather conditions and lower post-start funnel performance.
*/

---Compare navigation completion rates across traffic and weather conditions to investigate whether their observed relationships with post-start funnel performance overlap.
SELECT 
	traffic_level,
	weather_condition,
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END) as count_navigation_started,
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) as count_navigation_completed,
	ROUND(
	COUNT(DISTINCT CASE 
		WHEN navigation_completed = TRUE THEN session_id 
	END) * 100.0 /
	COUNT(DISTINCT CASE 
		WHEN navigation_started = TRUE THEN session_id 
	END), 
	2
	) as conversion_rate
FROM pathwise.navigation_sessions
GROUP BY traffic_level, weather_condition;
/*
Portfolio insight:
Navigation completion was lowest when difficult weather and traffic conditions occurred together. 
High-traffic snow sessions had a 61.92% completion rate, compared with 82.77% for low-traffic clear sessions. 
The pattern suggests that traffic and weather are jointly associated with post-start funnel performance, 
although this analysis does not establish causality.
*/

/*
🎯 Our current product story

If an interviewer asks “What have you discovered so far?”, you can say:

“The PathWise funnel analysis showed an overall destination-reach conversion of 66.32%, 
with the largest stage-level drop-off occurring between navigation start and navigation completion at 27.48%. 
Segment analysis showed that lower completion was particularly associated with high traffic, 
repeated rerouting, higher route complexity, and adverse weather conditions. 
In contrast, device type, user type, and recommended route type showed relatively small aggregate differences. 
These findings identify post-start navigation under difficult route conditions as the main area for deeper investigation, 
but they do not establish causality.”

🧠 Most important thing

We cannot yet conclude:

“Traffic/rerouting is the reason users don't complete navigation.”

We can conclude:

The major problem occurs after navigation starts, and traffic, rerouting, route complexity, 
and weather are the strongest observed signals worth investigating further.
*/