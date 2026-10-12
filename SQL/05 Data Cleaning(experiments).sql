---Examine navigation outcomes for experiment records with missing reroute counts.
SELECT 
	experiment_group,
	navigation_completed,
	session_abandoned,
	COUNT(*) as count_record
FROM pathwise.experiments
WHERE reroute_count IS NULL
GROUP BY experiment_group,
	navigation_completed,
	session_abandoned;

---Compare typical reroute counts across navigation outcomes before selecting a missing-value treatment.
SELECT
    experiment_group,
    navigation_completed,
    session_abandoned,
    COUNT(*) AS record_count,
    ROUND(AVG(reroute_count), 2) AS avg_reroute_count,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY reroute_count) AS median_reroute_count
FROM pathwise.experiments
WHERE reroute_count IS NOT NULL
GROUP BY
    experiment_group,
    navigation_completed,
    session_abandoned
ORDER BY
    experiment_group,
    navigation_completed,
    session_abandoned;

---Replace missing reroute counts using the observed median reroute count after validating consistency across experiment groups and navigation outcomes.
UPDATE pathwise.experiments
SET reroute_count = (SELECT 
    					PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reroute_count)
						FROM pathwise.experiments
						WHERE reroute_count IS NOT NULL)
WHERE reroute_count IS NULL;
---verify---
SELECT
    COUNT(*) AS total_rows,
    COUNT(reroute_count) AS non_null_values,
    COUNT(*) - COUNT(reroute_count) AS remaining_nulls
FROM pathwise.experiments;

---Convert the route_acceptance column from VARCHAR to BOOLEAN after validating TRUE/FALSE values.
ALTER TABLE pathwise.experiments
ALTER COLUMN route_acceptance
TYPE BOOLEAN
USING route_acceptance::BOOLEAN;

---Convert validated TRUE/FALSE text columns from VARCHAR to BOOLEAN.
ALTER TABLE pathwise.experiments
ALTER COLUMN navigation_completed
TYPE BOOLEAN
USING navigation_completed::BOOLEAN,

ALTER COLUMN session_abandoned
TYPE BOOLEAN
USING session_abandoned::BOOLEAN,

ALTER COLUMN retained_7d
TYPE BOOLEAN
USING retained_7d::BOOLEAN;

---Confirm that all binary indicator columns have been successfully converted to BOOLEAN.
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'experiments'
  AND column_name IN (
      'route_acceptance',
      'navigation_completed',
      'session_abandoned',
      'retained_7d'
  )
ORDER BY column_name;

---Identify users assigned to both Control and Treatment groups and examine their experiment exposure frequency.
SELECT 
	user_id,
	COUNT(DISTINCT experiment_group) as count_group
FROM pathwise.experiments
GROUP BY user_id
HAVING COUNT(DISTINCT experiment_group) > 1;

---Examine the number of experiment exposures for users assigned to both Control and Treatment groups.
SELECT
    user_id,
    COUNT(*) AS total_exposures,
    COUNT(DISTINCT experiment_group) AS distinct_groups
FROM pathwise.experiments
GROUP BY user_id
HAVING COUNT(DISTINCT experiment_group) > 1
ORDER BY total_exposures DESC;

/*
So is issue ko document karenge:

Experiment integrity issue: 7,832 users were observed in both Control and Treatment groups across repeated experiment exposures. Records were retained without modification, and cross-group assignment will be accounted for during A/B test analysis.

Iske saath experiments table ki data cleaning complete ✅.

What does this mean for the product? Jab hum A/B test analyze karenge, simple Control-vs-Treatment comparison se pehle user crossover ko account karna zaroori hoga; otherwise experiment effect ki interpretation unreliable ho sakti hai.
*/
