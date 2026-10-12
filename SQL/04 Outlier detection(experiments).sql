---Inspect experiment records with unusually high reroute_count values above the observed 99th percentile.
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

---Examine the frequency distribution of unusually high reroute_count values above the observed 99th percentile.
SELECT
    reroute_count,
    COUNT(*) AS record_count
FROM pathwise.experiments
WHERE reroute_count > 4
GROUP BY reroute_count
ORDER BY reroute_count DESC;

---DATA TYPE VALIDATION---
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'pathwise'
  AND table_name = 'experiments'
ORDER BY ordinal_position;

---Validate that VARCHAR-based binary flag columns contain only expected TRUE/FALSE values.---
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


/*
Final findings jo humne actually discover kiye:

---50,000 records, duplicate experiment_id = 0 ✅
user_id orphan records = 0 ✅
reroute_count mein 500 NULLs (1%) ⚠️
Missing reroutes Control/Treatment mein almost equally distributed.
Negative reroute_count = 0 ✅
navigation_completed = TRUE + session_abandoned = TRUE = 0 ✅
7,832 users Control aur Treatment dono groups mein aaye ⚠️ — important experiment-integrity issue.
Outlier investigation: P99 reroutes = 4, max = 8; 301 records > 4. Inhe abhi invalid nahi maanenge.
route_acceptance, navigation_completed, session_abandoned, retained_7d sirf TRUE/FALSE values contain karte hain, but PostgreSQL mein VARCHAR stored hain instead of BOOLEAN ⚠️.
Exposure period observed: 2024-09-05 to 2026-08-30.
*/