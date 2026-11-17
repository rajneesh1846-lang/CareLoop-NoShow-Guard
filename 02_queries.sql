-- CareLoop Clinics — No-Show Guard
-- Part 2: SQL queries (SQLiteOnline-compatible)
-- Run against the existing database after loading load_data.sql.
-- In MySQL 8, create/select the database first using:
-- CREATE DATABASE noshowguard;
-- USE noshowguard;

-- TASK 2.1: CREATE TABLES (run once on a new database)
CREATE TABLE IF NOT EXISTS clinics (
    clinic_id VARCHAR(5) PRIMARY KEY,
    clinic_name VARCHAR(40) NOT NULL,
    city VARCHAR(20) NOT NULL,
    tier VARCHAR(10),
    latitude DECIMAL(8,4),
    longitude DECIMAL(8,4),
    temp_c DECIMAL(5,1)
);

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id VARCHAR(8) PRIMARY KEY,
    patient_id VARCHAR(8) NOT NULL,
    clinic_id VARCHAR(5) NOT NULL,
    booked_on DATE,
    appt_date DATE,
    age INT,
    gender VARCHAR(1),
    distance_km DECIMAL(5,1),
    fee_inr INT,
    booking_channel VARCHAR(10),
    visit_type VARCHAR(12),
    reminder_sent VARCHAR(3),
    prior_no_shows INT,
    status VARCHAR(10),
    lead_days INT,
    no_show INT,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);

-- Next, execute load_data.sql ONCE to populate the tables.
-- Verification: expected clinics = 8, appointments = 990, no-shows = 218.
SELECT COUNT(*) AS total_clinics FROM clinics;
SELECT COUNT(*) AS total_appointments, SUM(no_show) AS total_no_shows
FROM appointments;

-- Duplicate-key test, carried out separately (do NOT run in the whole script):
-- INSERT INTO appointments SELECT * FROM appointments WHERE appointment_id = 'A0001';
-- Observed SQLiteOnline error:
-- SQLITE_CONSTRAINT_PRIMARYKEY: sqlite3 result code 1555:
-- UNIQUE constraint failed: appointments.appointment_id
-- This confirms appointment_id is protected by the primary key.

-- TASK 2.2: NO-SHOW RATES BY CLINIC (at least 95 appointments)
SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;

-- TASK 2.2: ALL EIGHT CLINICS (HAVING removed)
SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c ON a.clinic_id = c.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
ORDER BY no_show_pct DESC;

-- Python cross-check in 01_ingest_clean.ipynb: groupby clinic_id for
-- appointments=count(appointment_id), no_shows=sum(no_show); counts matched.

-- TASK 2.3: LEAD-TIME BANDS (upper bounds inclusive)
SELECT
    CASE
        WHEN lead_days <= 7 THEN '1-7'
        WHEN lead_days <= 14 THEN '8-14'
        WHEN lead_days <= 30 THEN '15-30'
        ELSE '31+'
    END AS lead_time_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY lead_time_band
ORDER BY MIN(lead_days);

-- TASK 2.4: MONTH-BY-MONTH RATES AND CHANGE IN PERCENTAGE POINTS
WITH monthly AS (
    SELECT
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT
    month,
    appointments,
    no_show_pct,
    ROUND(no_show_pct - LAG(no_show_pct) OVER (ORDER BY month), 1) AS change_pp
FROM monthly
ORDER BY month;

-- TASK 2.5: RANK CLINICS WITHIN EACH CITY VS OVERALL RATE
WITH clinic_rates AS (
    SELECT
        c.clinic_name,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments a
    JOIN clinics c ON a.clinic_id = c.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
)
SELECT
    clinic_name,
    city,
    no_show_pct,
    RANK() OVER (PARTITION BY city ORDER BY no_show_pct DESC) AS rank_in_city,
    CASE
        WHEN no_show_pct > (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'above'
        WHEN no_show_pct < (SELECT 100.0 * SUM(no_show) / COUNT(*) FROM appointments) THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY city, rank_in_city;
