---checking for duplicate PK---
SELECT 
	experiment_id,
	COUNT(*) as duplicate_count
FROM pathwise.experiments
GROUP BY experiment_id
HAVING COUNT(*) > 1

--Foreign Key integrity--
--Verify that every experiment record is associated with a valid user.--
SELECT COUNT(*) as orphan_session
FROM pathwise.experiments e
LEFT JOIN pathwise.users u 
ON e.user_id = u.user_id
WHERE u.user_id IS NULL

-- ============================================================
-- PHASE 3: DATA QUALITY INVESTIGATION
-- TABLE: experiments
-- TOOL: PostgreSQL
-- ============================================================


-- ============================================================
-- 1. ROW COUNT VALIDATION
-- ============================================================

SELECT COUNT(*) AS total_records
FROM pathwise.experiments;

-- Result:
-- 50,000 records


-- ============================================================
-- 2. PRIMARY KEY UNIQUENESS CHECK
-- ============================================================

SELECT
    experiment_id,
    COUNT(*) AS duplicate_count
FROM pathwise.experiments
GROUP BY experiment_id
HAVING COUNT(*) > 1;

-- Result:
-- 0 duplicate experiment_id values


-- ============================================================
-- 3. FOREIGN KEY INTEGRITY CHECK
-- ============================================================
-- Purpose: Verify that every experiment user exists
-- in the users table.

SELECT COUNT(*) AS orphan_user_records
FROM pathwise.experiments e
LEFT JOIN pathwise.users u
    ON e.user_id = u.user_id
WHERE u.user_id IS NULL;

-- Result:
-- 0 orphan records


-- ============================================================
-- 4. MISSING VALUE ANALYSIS
-- ============================================================

SELECT
    COUNT(*) FILTER (WHERE experiment_id IS NULL)
        AS missing_experiment_id,

    COUNT(*) FILTER (WHERE user_id IS NULL)
        AS missing_user_id,

    COUNT(*) FILTER (WHERE experiment_group IS NULL)
        AS missing_experiment_group,

    COUNT(*) FILTER (WHERE exposure_timestamp IS NULL)
        AS missing_exposure_timestamp,

    COUNT(*) FILTER (WHERE route_acceptance IS NULL)
        AS missing_route_acceptance,

    COUNT(*) FILTER (WHERE navigation_completed IS NULL)
        AS missing_navigation_completed,

    COUNT(*) FILTER (WHERE reroute_count IS NULL)
        AS missing_reroute_count,

    COUNT(*) FILTER (WHERE session_abandoned IS NULL)
        AS missing_session_abandoned,

    COUNT(*) FILTER (WHERE retained_7d IS NULL)
        AS missing_retained_7d

FROM pathwise.experiments;

-- Result:
-- Only reroute_count has missing values.
-- Missing reroute_count = 500 records = 1.00%


-- ============================================================
-- 5. MISSING REROUTE COUNT BY EXPERIMENT GROUP
-- ============================================================

SELECT
    experiment_group,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE reroute_count IS NULL
    ) AS missing_reroute_count,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE reroute_count IS NULL
        ) / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.experiments
GROUP BY experiment_group;

-- Result:
-- Control:   24,906 total, 253 missing, 1.02%
-- Treatment: 25,094 total, 247 missing, 0.98%
-- Missingness is almost equally distributed across groups.


-- ============================================================
-- 6. EXPERIMENT GROUP CATEGORY VALIDATION
-- ============================================================

SELECT
    experiment_group,
    COUNT(*) AS record_count
FROM pathwise.experiments
GROUP BY experiment_group
ORDER BY record_count DESC;

-- Result:
-- Treatment = 25,094
-- Control   = 24,906
-- No unexpected experiment group values identified.


-- ============================================================
-- 7. FLAG COMBINATION DISTRIBUTION
-- ============================================================

SELECT
    route_acceptance,
    navigation_completed,
    session_abandoned,
    retained_7d,
    COUNT(*) AS record_count
FROM pathwise.experiments
GROUP BY
    route_acceptance,
    navigation_completed,
    session_abandoned,
    retained_7d
ORDER BY record_count DESC;

-- Purpose:
-- Review combinations of binary experiment outcome flags.


-- ============================================================
-- 8. COMPLETION VS ABANDONMENT CONSISTENCY
-- ============================================================
-- Purpose:
-- Identify logically conflicting records where navigation
-- is marked completed and abandoned at the same time.

SELECT COUNT(*) AS inconsistent_records
FROM pathwise.experiments
WHERE navigation_completed = 'TRUE'
  AND session_abandoned = 'TRUE';

-- Result:
-- 0 inconsistent records


-- ============================================================
-- 9. INVALID REROUTE COUNT CHECK
-- ============================================================

SELECT COUNT(*) AS inconsistent_reroute_count
FROM pathwise.experiments
WHERE reroute_count < 0;

-- Result:
-- 0 negative reroute_count values


-- ============================================================
-- 10. EXPOSURE TIMESTAMP RANGE VALIDATION
-- ============================================================

SELECT
    MIN(exposure_timestamp) AS earliest_exposure,
    MAX(exposure_timestamp) AS latest_exposure
FROM pathwise.experiments;

-- Result:
-- Earliest: 2024-09-05 11:00:00
-- Latest:   2026-08-30 23:00:00


-- ============================================================
-- 11. USER EXPOSURE FREQUENCY CHECK
-- ============================================================
-- Purpose:
-- Identify users appearing in multiple experiment records.

SELECT
    user_id,
    COUNT(*) AS exposure_count
FROM pathwise.experiments
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY exposure_count DESC;

-- Finding:
-- Multiple users appear in many experiment records.
-- This is not automatically a duplicate issue because the
-- experiment table grain is one row per experiment exposure.


-- ============================================================
-- 12. CROSS-GROUP ASSIGNMENT CHECK
-- ============================================================
-- Purpose:
-- Identify users assigned to both Control and Treatment groups.

SELECT
    user_id,
    COUNT(DISTINCT experiment_group) AS distinct_group_count
FROM pathwise.experiments
GROUP BY user_id
HAVING COUNT(DISTINCT experiment_group) > 1;

-- ============================================================
-- 13. COUNT USERS ASSIGNED TO BOTH GROUPS
-- ============================================================

SELECT COUNT(*) AS affected_users
FROM (
    SELECT
        user_id
    FROM pathwise.experiments
    GROUP BY user_id
    HAVING COUNT(DISTINCT experiment_group) > 1
) AS affected_users;

-- Result:
-- 7,832 users appear in both Control and Treatment groups.

-- Conclusion:
-- This is a potential experiment contamination / integrity issue
-- and must be handled carefully before A/B test analysis.


-- ============================================================
-- 14. REROUTE COUNT DISTRIBUTION
-- ============================================================
-- Current Check: Outlier Investigation

SELECT
    MIN(reroute_count) AS min_reroutes,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY reroute_count) AS p50_reroutes,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY reroute_count) AS p95_reroutes,
    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY reroute_count) AS p99_reroutes,
    MAX(reroute_count) AS max_reroutes
FROM pathwise.experiments;

-- Result:
-- Min = 0
-- P50 = 1
-- P95 = 3
-- P99 = 4
-- Max = 8


-- ============================================================
-- 15. HIGH REROUTE RECORD COUNT
-- ============================================================

SELECT
    COUNT(*) AS high_reroute_records
FROM pathwise.experiments
WHERE reroute_count > 4;

-- Result:
-- 301 records
-- Approximately 0.60% of all experiment records


-- ============================================================
-- 16. HIGH REROUTE RECORD INSPECTION
-- ============================================================

SELECT
    experiment_id,
    user_id,
    experiment_group,
    reroute_count,
    navigation_completed,
    session_abandoned,
    retained_7d
FROM pathwise.experiments
WHERE reroute_count > 4
ORDER BY reroute_count DESC;

-- Purpose:
-- Inspect unusually high reroute records rather than treating
-- them automatically as invalid.


-- ============================================================
-- 17. HIGH REROUTE COUNT DISTRIBUTION
-- ============================================================

SELECT
    reroute_count,
    COUNT(*) AS record_count
FROM pathwise.experiments
WHERE reroute_count > 4
GROUP BY reroute_count
ORDER BY reroute_count DESC;

-- Result:
-- reroute_count = 8 -> 4 records
-- reroute_count = 7 -> 16 records
-- reroute_count = 6 -> 57 records
-- reroute_count = 5 -> 224 records

-- Conclusion:
-- High reroute values are rare behavioral outliers.
-- They should not be treated as invalid without further evidence.


-- ============================================================
-- 18. COLUMN DATA TYPE VALIDATION
-- ============================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'experiments'
ORDER BY ordinal_position;

-- Result:
-- experiment_id         -> character varying
-- user_id               -> character varying
-- experiment_group      -> character varying
-- exposure_timestamp    -> timestamp without time zone
-- route_acceptance      -> character varying
-- navigation_completed  -> character varying
-- reroute_count          -> integer
-- session_abandoned     -> character varying
-- retained_7d           -> character varying

-- Finding:
-- Four logical binary indicator columns are stored as VARCHAR:
-- route_acceptance
-- navigation_completed
-- session_abandoned
-- retained_7d


-- ============================================================
-- 19. BINARY FLAG VALUE VALIDATION
-- ============================================================

SELECT DISTINCT
    route_acceptance,
    navigation_completed,
    session_abandoned,
    retained_7d
FROM pathwise.experiments
ORDER BY
    route_acceptance,
    navigation_completed,
    session_abandoned,
    retained_7d;

-- Result:
-- Only TRUE/FALSE values were found.

-- Conclusion:
-- The values are valid binary values, but these columns should
-- be converted from VARCHAR to BOOLEAN during the cleaning phase.

/*
Row count: 50,000 ✅
Duplicate experiment_id: 0 ✅
User FK violations: 0 ✅
Missing reroute_count: 500 (1%) ⚠️
Negative reroutes: 0 ✅
Completed + abandoned simultaneously: 0 ✅
Users in both Control & Treatment: 7,832 ⚠️
Reroute P99: 4
Maximum reroutes: 8
High-reroute records >4: 301 (0.60%)
Binary flag values valid, but 4 flag columns have wrong storage type (VARCHAR instead of BOOLEAN) ⚠️*/