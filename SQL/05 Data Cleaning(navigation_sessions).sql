---Replace NULL values with 'Unknown' to preserve records without assuming a weather condition.---
UPDATE pathwise.navigation_sessions
SET weather_condition = 'Unknown'
WHERE weather_condition IS NULL
--verify--
SELECT 
	weather_condition, 
	COUNT(*) AS user_count
FROM pathwise.navigation_sessions
GROUP BY weather_condition
ORDER BY user_count DESC;


---Compare the mean and median road quality scores before selecting an appropriate imputation method for missing values.---
SELECT
    ROUND(AVG(road_quality_score)::NUMERIC, 4) AS mean_road_quality,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY road_quality_score)::NUMERIC,
        4
    ) AS median_road_quality
FROM pathwise.navigation_sessions;

---Impute missing values using the mean road quality score because the mean and median are nearly identical.
UPDATE pathwise.navigation_sessions
SET road_quality_score = (
    SELECT AVG(road_quality_score)
    FROM pathwise.navigation_sessions
    WHERE road_quality_score IS NOT NULL
)
WHERE road_quality_score IS NULL;
---verify---
SELECT COUNT(*) AS remaining_nulls
FROM pathwise.navigation_sessions
WHERE road_quality_score IS NULL;

---Compare the mean and median actual duration minutes before selecting an appropriate imputation method for missing values.---
SELECT
    ROUND(AVG(actual_duration_minutes)::NUMERIC, 4) AS mean_actual_duration_minutes,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY actual_duration_minutes)::NUMERIC,
        4
    ) AS median_actual_duration_minutes
FROM pathwise.navigation_sessions;

---Determine whether selected ETA is available for completed and destination-reached sessions with missing actual duration values.
SELECT
    COUNT(*) AS missing_selected_eta
FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NULL
  AND selected_eta_minutes IS NULL;

---Evaluate how closely selected ETA represents actual trip duration before using ETA for duration imputation.---
SELECT
	ROUND(AVG(actual_duration_minutes)::NUMERIC, 4) as mean_actual_duration_minutes,
	ROUND(AVG(selected_eta_minutes)::NUMERIC, 4) as mean_selected_eta_minutes
FROM pathwise.navigation_sessions;

---Measure the relationship between selected ETA and actual trip duration before using ETA for imputation.
SELECT
	(CORR(actual_duration_minutes, selected_eta_minutes)) as corre
FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE AND
destination_reached = TRUE AND
actual_duration_minutes IS NOT NULL

---Calculate the slope and intercept of the relationship between selected ETA and actual trip duration for successful navigation sessions.
SELECT
    REGR_SLOPE(
        actual_duration_minutes,
        selected_eta_minutes
    ) AS slope,

    REGR_INTERCEPT(
        actual_duration_minutes,
        selected_eta_minutes
    ) AS intercept

FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NOT NULL
  AND selected_eta_minutes IS NOT NULL;

---Preview ETA-based estimated actual durations for completed and destination-reached sessions before updating missing actual duration values.
SELECT
    session_id,
    selected_eta_minutes,
    ROUND(
        (
            -0.043030234462095515
            + (1.217757781487285 * selected_eta_minutes)
        )::NUMERIC,
        2
    ) AS estimated_actual_duration
FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NULL
  AND selected_eta_minutes IS NOT NULL
ORDER BY selected_eta_minutes DESC
LIMIT 20;

---Measure the average absolute prediction error before using the regression model to impute missing actual durations.
SELECT
    ROUND(
        AVG(
            ABS(
                actual_duration_minutes -
                (
                    -0.043030234462095515
                    + 1.217757781487285 * selected_eta_minutes
                )
            )
        )::NUMERIC,
        2
    ) AS mean_absolute_error
FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NOT NULL
  AND selected_eta_minutes IS NOT NULL;

---Impute missing durations using an ETA-based linear regression model. The model showed a strong correlation (0.9466) and a mean absolute error of approximately 1.33 minutes. Incomplete sessions will retain NULL actual durations.
UPDATE pathwise.navigation_sessions
SET actual_duration_minutes =
    -0.043030234462095515
    + (1.217757781487285 * selected_eta_minutes)
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NULL
  AND selected_eta_minutes IS NOT NULL;

--verify--
SELECT
    COUNT(*) AS remaining_completed_reached_nulls
FROM pathwise.navigation_sessions
WHERE navigation_completed = TRUE
  AND destination_reached = TRUE
  AND actual_duration_minutes IS NULL;

---verify--
SELECT
    COUNT(*) AS incomplete_session_nulls
FROM pathwise.navigation_sessions
WHERE navigation_completed = FALSE
  AND actual_duration_minutes IS NULL;

---Convert route_complexity from VARCHAR to NUMERIC to support quantitative analysis and aggregation.
ALTER TABLE pathwise.navigation_sessions
ALTER COLUMN route_complexity
TYPE NUMERIC
USING route_complexity::NUMERIC;

----- Verify the updated data type
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'navigation_sessions'
  AND column_name = 'route_complexity';

