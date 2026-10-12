-------Create Schema name "pathwise"----

CREATE SCHEMA pathwise;


-- =============================================
-- PATHWISE NAVIGATION PRODUCT ANALYTICS
-- Remaining Dataset Tables
-- Schema: pathwise
-- =============================================

-- 1.  user
CREATE TABLE pathwise.users (
    user_id VARCHAR(20) PRIMARY KEY,
    signup_date DATE,
    city VARCHAR(100),
    country VARCHAR(100),
    device_type VARCHAR(50),
    user_type VARCHAR(50),
    subscription_type VARCHAR(50),
    preferred_route_type VARCHAR(50),
    account_age_days INT
);

---Quick check------
SELECT * FROM pathwise.users;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.users;

-- 2. NAVIGATION SESSIONS
CREATE TABLE pathwise.navigation_sessions (
    session_id VARCHAR(30) PRIMARY KEY,
    user_id VARCHAR(20),
    session_date DATE,
    session_start_time TIME,
    source_type VARCHAR(50),
    destination_category VARCHAR(50),
    city VARCHAR(100),
    traffic_level VARCHAR(50),
    weather_condition VARCHAR(50),
    recommended_route_id VARCHAR(30),
    selected_route_id VARCHAR(30),
    recommended_route_type VARCHAR(50),
    recommended_eta_minutes NUMERIC,
    selected_eta_minutes NUMERIC,
    actual_duration_minutes NUMERIC,
    distance_km NUMERIC,
    toll_recommended BOOLEAN,
    toll_selected BOOLEAN,
    route_complexity VARCHAR(50),
    number_of_turns INT,
    road_quality_score NUMERIC,
    traffic_uncertainty_score NUMERIC,
    reroute_count INT,
    navigation_started BOOLEAN,
    navigation_completed BOOLEAN,
    destination_reached BOOLEAN,
    session_abandoned BOOLEAN
);

---Quick check------
SELECT * FROM pathwise.navigation_sessions;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.navigation_sessions;

-- 3. ROUTE OPTIONS
CREATE TABLE pathwise.route_options (
    route_id VARCHAR(30) PRIMARY KEY,
    session_id VARCHAR(30),
    route_rank INT,
    route_type VARCHAR(50),
    eta_minutes NUMERIC,
    distance_km NUMERIC,
    toll_amount NUMERIC,
    traffic_score NUMERIC,
    road_quality_score NUMERIC,
    number_of_turns INT,
    traffic_uncertainty_score NUMERIC
);

---Quick check------
SELECT * FROM .users.route_options;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.route_options;


-- 4. USER EVENTS
CREATE TABLE pathwise.user_events (
    event_id VARCHAR(30) PRIMARY KEY,
    user_id VARCHAR(20),
    session_id VARCHAR(30),
    event_timestamp TIMESTAMP,
    event_type VARCHAR(100)
);

---Quick check------
SELECT * FROM pathwise.user_events;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.user_events;


-- 5. EXPERIMENTS
CREATE TABLE pathwise.experiments (
    experiment_id VARCHAR(30) PRIMARY KEY,
    user_id VARCHAR(20),
    experiment_group VARCHAR(50),
    exposure_timestamp TIMESTAMP,
    route_acceptance VARCHAR(6),
    navigation_completed VARCHAR(6),
    reroute_count INT,
    session_abandoned VARCHAR(6),
    retained_7d VARCHAR(6)
);

---Quick check------
SELECT * FROM pathwise.experiments;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.experiments;

-- 6. RETENTION DAILY
CREATE TABLE pathwise.retention_daily (
    user_id VARCHAR(20),
    activity_date DATE,
    active_flag BOOLEAN,
    navigation_session_count INT,
    successful_navigation_count INT
);

---Quick check------
SELECT * FROM pathwise.retention_daily;
----Count Rows-----
SELECT COUNT(*)
FROM pathwise.retention_daily;
