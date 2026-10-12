-- =====================================================================
-- PATHWISE NAVIGATION PRODUCT ANALYTICS
-- PHASE 3: DATA QUALITY ASSESSMENT
-- TABLE: users
-- TOOL: PostgreSQL
-- =====================================================================


-- =====================================================================
-- 1. ROW COUNT VALIDATION
-- =====================================================================
-- Purpose: Validate the total number of records loaded into the users
-- table and compare the database row count with the source dataset.

SELECT
    COUNT(*) AS total_users
FROM pathwise.users;

-- Result:
-- Total users = 20,000
-- Status: PASS


-- =====================================================================
-- 2. PRIMARY KEY UNIQUENESS / DUPLICATE CHECK
-- =====================================================================
-- Purpose: Identify duplicate user_id values and verify that each user
-- appears only once in the users table.

SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM pathwise.users
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Result:
-- 0 duplicate user_id values identified.
-- Status: PASS


-- =====================================================================
-- 3. MISSING VALUE ANALYSIS
-- =====================================================================
-- Purpose: Identify NULL values across all columns in the users table.

SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL)
        AS missing_user_id,

    COUNT(*) FILTER (WHERE signup_date IS NULL)
        AS missing_signup_date,

    COUNT(*) FILTER (WHERE city IS NULL)
        AS missing_city,

    COUNT(*) FILTER (WHERE country IS NULL)
        AS missing_country,

    COUNT(*) FILTER (WHERE device_type IS NULL)
        AS missing_device_type,

    COUNT(*) FILTER (WHERE user_type IS NULL)
        AS missing_user_type,

    COUNT(*) FILTER (WHERE subscription_type IS NULL)
        AS missing_subscription_type,

    COUNT(*) FILTER (WHERE preferred_route_type IS NULL)
        AS missing_preferred_route_type,

    COUNT(*) FILTER (WHERE account_age_days IS NULL)
        AS missing_account_age_days
FROM pathwise.users;

-- Result:
-- device_type       = 240 missing values
-- subscription_type = 160 missing values
-- All other checked columns = 0 missing values


-- =====================================================================
-- 4. DEVICE TYPE MISSINGNESS BY CITY
-- =====================================================================
-- Purpose: Determine whether missing device_type values are concentrated
-- within specific cities or broadly distributed across the dataset.

SELECT
    city,
    COUNT(*) AS total_users,
    COUNT(*) FILTER (
        WHERE device_type IS NULL
    ) AS missing_device_type,
    ROUND(
        COUNT(*) FILTER (WHERE device_type IS NULL) * 100.0
        / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.users
GROUP BY city
ORDER BY missing_percentage DESC;

-- Conclusion:
-- Missing device_type values are distributed across multiple cities.
-- No clear single-city concentration was identified.


-- =====================================================================
-- 5. SUBSCRIPTION TYPE MISSINGNESS BY CITY
-- =====================================================================
-- Purpose: Determine whether missing subscription_type values are
-- concentrated within specific cities.

SELECT
    city,
    COUNT(*) AS total_users,
    COUNT(*) FILTER (
        WHERE subscription_type IS NULL
    ) AS missing_subscription_type,
    ROUND(
        COUNT(*) FILTER (WHERE subscription_type IS NULL) * 100.0
        / COUNT(*),
        2
    ) AS missing_percentage
FROM pathwise.users
GROUP BY city
ORDER BY missing_percentage DESC;

-- Conclusion:
-- Missing subscription_type values are distributed across multiple cities.
-- No clear single-city concentration was identified.


-- =====================================================================
-- 6. INVALID ACCOUNT AGE CHECK
-- =====================================================================
-- Purpose: Identify impossible negative values in account_age_days.

SELECT
    COUNT(*) AS invalid_account_age_records
FROM pathwise.users
WHERE account_age_days < 0;

-- Result:
-- 0 invalid records identified.
-- Status: PASS


-- =====================================================================
-- 7. DEVICE TYPE CATEGORICAL CONSISTENCY
-- =====================================================================
-- Purpose: Review device_type categories for spelling, casing,
-- unexpected values, and NULLs.

SELECT
    device_type,
    COUNT(*) AS user_count
FROM pathwise.users
GROUP BY device_type
ORDER BY user_count DESC;

-- Observed:
-- iOS     = 10,854
-- Android = 8,906
-- NULL    = 240
--
-- Conclusion:
-- No obvious spelling or casing inconsistencies were identified.


-- =====================================================================
-- 8. SUBSCRIPTION TYPE CATEGORICAL CONSISTENCY
-- =====================================================================
-- Purpose: Review subscription_type categories for unexpected,
-- misspelled, or inconsistently formatted values.

SELECT
    subscription_type,
    COUNT(*) AS user_count
FROM pathwise.users
GROUP BY subscription_type
ORDER BY user_count DESC;

-- Observed:
-- Free    = 12,895
-- Plus    = 4,948
-- Premium = 1,997
-- NULL    = 160
--
-- Conclusion:
-- No obvious categorical inconsistencies were identified.


-- =====================================================================
-- 9. USER TYPE CATEGORICAL CONSISTENCY
-- =====================================================================
-- Purpose: Review user_type categories for unexpected or inconsistent
-- categorical values.

SELECT
    user_type,
    COUNT(*) AS user_count
FROM pathwise.users
GROUP BY user_type
ORDER BY user_count DESC;

-- Observed:
-- Returning = 19,149
-- New       = 851
--
-- Conclusion:
-- No obvious categorical inconsistencies were identified.


-- =====================================================================
-- 10. PREFERRED ROUTE TYPE CATEGORICAL CONSISTENCY
-- =====================================================================
-- Purpose: Review preferred_route_type categories for spelling,
-- casing, and unexpected categorical values.

SELECT
    preferred_route_type,
    COUNT(*) AS user_count
FROM pathwise.users
GROUP BY preferred_route_type
ORDER BY user_count DESC;

-- Observed:
-- Fastest   = 6,232
-- Balanced  = 5,234
-- Toll-Free = 3,145
-- Cheapest  = 2,993
-- Scenic    = 2,396
--
-- Conclusion:
-- No obvious spelling or categorical inconsistencies were identified.


-- =====================================================================
-- 11. SIGNUP DATE RANGE VALIDATION
-- =====================================================================
-- Purpose: Identify the earliest and latest signup dates and review
-- the observed date range for potential anomalies.

SELECT
    MIN(signup_date) AS earliest_signup_date,
    MAX(signup_date) AS latest_signup_date
FROM pathwise.users;

-- Result:
-- Earliest signup date = 2024-08-31
-- Latest signup date   = 2026-08-30


-- =====================================================================
-- 12. ACCOUNT AGE RANGE VALIDATION
-- =====================================================================
-- Purpose: Review the minimum and maximum account age values.

SELECT
    MIN(account_age_days) AS minimum_account_age,
    MAX(account_age_days) AS maximum_account_age
FROM pathwise.users;

-- Result:
-- Minimum account age = 1 day
-- Maximum account age = 730 days


-- =====================================================================
-- 13. ACCOUNT AGE CONSISTENCY USING CURRENT DATE
-- =====================================================================
-- Purpose: Compare the stored account_age_days with the account age
-- calculated using PostgreSQL CURRENT_DATE.

SELECT
    user_id,
    signup_date,
    account_age_days,
    CURRENT_DATE - signup_date AS calculated_account_age
FROM pathwise.users
LIMIT 20;

-- Finding:
-- The calculated account age based on CURRENT_DATE was consistently
-- higher than the stored account_age_days.
--
-- This suggested that account_age_days was generated relative to a
-- historical dataset snapshot rather than the current system date.


-- =====================================================================
-- 14. INFERRED SNAPSHOT DATE CONSISTENCY CHECK
-- =====================================================================
-- Purpose: Test whether account_age_days is internally consistent with
-- an inferred dataset snapshot date of August 31, 2026.
--
-- Note:
-- August 31, 2026 is an inferred snapshot date based on the observed
-- relationship between signup_date and account_age_days. It should not
-- be treated as an officially documented snapshot date unless confirmed
-- by the source documentation.

SELECT
    COUNT(*) AS inconsistent_records
FROM pathwise.users
WHERE account_age_days <> DATE '2026-08-31' - signup_date;

-- Result:
-- inconsistent_records = 0
--
-- Conclusion:
-- All 20,000 user records are internally consistent with the inferred
-- snapshot date of August 31, 2026.
-- Status: PASS


-- =====================================================================
-- USERS TABLE: DATA QUALITY SUMMARY
-- =====================================================================
-- The users table contains 20,000 records with no duplicate user_id
-- values and no invalid negative account ages.
--
-- Missing values were identified in device_type (240 records, 1.2%)
-- and subscription_type (160 records, 0.8%). Missingness was distributed
-- across multiple cities with no obvious single-city concentration.
--
-- Categorical fields showed no obvious spelling or casing inconsistencies.
-- Signup dates range from August 31, 2024 to August 30, 2026, while
-- account_age_days ranges from 1 to 730 days.
--
-- All records were internally consistent when account_age_days was
-- evaluated against the inferred snapshot date of August 31, 2026.
--
-- Missing-value treatment has not yet been performed. Cleaning decisions
-- will be made during the dedicated data-cleaning stage.
-- =====================================================================