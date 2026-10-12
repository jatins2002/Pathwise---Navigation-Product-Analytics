---Determine whether missing toll amounts are concentrated within specific route types.
SELECT 
    route_type,
    COUNT(*) AS total_routes,
    
    SUM(
        CASE 
            WHEN toll_amount IS NULL THEN 1 
            ELSE 0 
        END
    ) AS missing_toll,

    ROUND(
        100.0 * SUM(
            CASE 
                WHEN toll_amount IS NULL THEN 1 
                ELSE 0 
            END
        ) / COUNT(*),
        2
    ) AS missing_pct

FROM pathwise.route_options
GROUP BY route_type
ORDER BY missing_pct DESC;


---Understand the distribution of toll amounts across route types before selecting a missing-value treatment.
SELECT
    route_type,
    COUNT(toll_amount) AS non_null_toll_records,
    ROUND(AVG(toll_amount)::NUMERIC, 2) AS mean_toll,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY toll_amount)::NUMERIC,
        2
    ) AS median_toll,
    MIN(toll_amount) AS min_toll,
    MAX(toll_amount) AS max_toll
FROM pathwise.route_options
GROUP BY route_type
ORDER BY route_type;

---Replace missing toll amounts with zero only for Toll-Free routes.---
UPDATE pathwise.route_options
SET toll_amount = 0.0
WHERE route_type = 'Toll-Free'
  AND toll_amount IS NULL;

---verify---
SELECT COUNT(*) AS remaining_toll_free_nulls
FROM pathwise.route_options
WHERE route_type = 'Toll-Free'
  AND toll_amount IS NULL;

---Compare mean and median toll amounts across route types before selecting an imputation strategy.
SELECT
    route_type,
    COUNT(*) AS total_routes,
    COUNT(toll_amount) AS available_toll_values,
    COUNT(*) - COUNT(toll_amount) AS missing_toll_values,

    ROUND(
        AVG(toll_amount)::NUMERIC,
        2
    ) AS mean_toll,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY toll_amount)::NUMERIC,
        2
    ) AS median_toll

FROM pathwise.route_options
GROUP BY route_type
ORDER BY route_type;

---Examine the upper tail of toll amounts for Fastest routes before selecting an imputation method.
SELECT 
    MIN(toll_amount) AS min_toll,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY toll_amount)::NUMERIC, 2
    ) AS toll_p50,

    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY toll_amount)::NUMERIC, 2
    ) AS toll_p95,

    ROUND(
        PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY toll_amount)::NUMERIC, 2
    ) AS toll_p99,

    MAX(toll_amount) AS max_toll

FROM pathwise.route_options
WHERE route_type = 'Fastest'
  AND toll_amount IS NOT NULL;

---Replace missing toll amounts using the median toll observed within each corresponding route type.---
UPDATE pathwise.route_options AS r1
SET toll_amount = (
    SELECT
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY r2.toll_amount)
    FROM pathwise.route_options AS r2
    WHERE r2.route_type = r1.route_type
      AND r2.toll_amount IS NOT NULL
)
WHERE r1.toll_amount IS NULL;
--verify--
SELECT COUNT(*) AS remaining_toll_nulls
FROM pathwise.route_options
WHERE toll_amount IS NULL;

---Compare the mean and median road quality scores before selecting an imputation method.
SELECT
	route_type,
	ROUND(AVG(road_quality_score), 2) as mean_road_quality_score,
	ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY road_quality_score)::NUMERIC, 2) as median_road_quality_score
FROM pathwise.route_options
GROUP BY route_type;

---Replace missing road quality scores using the median observed across all available route options.
UPDATE pathwise.route_options
SET road_quality_score = (
    SELECT ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY road_quality_score)::NUMERIC,
        2
    )
    FROM pathwise.route_options
)
WHERE road_quality_score IS NULL;
---verify---
SELECT
    COUNT(*) AS total_rows,
    COUNT(road_quality_score) AS non_null_values,
    COUNT(*) - COUNT(road_quality_score) AS remaining_nulls,
    MIN(road_quality_score) AS min_score,
    MAX(road_quality_score) AS max_score
FROM pathwise.route_options;