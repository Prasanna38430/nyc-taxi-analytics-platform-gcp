-- ============================================================
-- Phase 5: Gold Layer - dim_datetime (Time Dimension)
-- ============================================================
-- Creates the datetime dimension table for the star schema.
-- Contains all time-related attributes for analytical queries.
-- ============================================================

CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_datetime` AS
SELECT DISTINCT
    -- Surrogate key (YYYYMMDDHH format)
    CONCAT(
        CAST(pickup_year AS STRING),
        LPAD(CAST(pickup_month AS STRING), 2, '0'),
        LPAD(CAST(pickup_day AS STRING), 2, '0'),
        LPAD(CAST(pickup_hour AS STRING), 2, '0')
    ) AS datetime_key,

    -- Date hierarchy
    pickup_year AS year,
    pickup_month AS month,
    pickup_day AS day,
    pickup_hour AS hour,

    -- Day attributes
    pickup_dayofweek AS day_of_week,
    pickup_day_name AS day_name,

    -- Derived time attributes
    is_weekend,
    time_of_day,

    -- Season (Northern Hemisphere)
    CASE
        WHEN pickup_month IN (12, 1, 2) THEN 'Winter'
        WHEN pickup_month IN (3, 4, 5) THEN 'Spring'
        WHEN pickup_month IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season,

    -- Rush hour indicator
    CASE
        WHEN pickup_hour BETWEEN 7 AND 9 THEN TRUE
        WHEN pickup_hour BETWEEN 17 AND 19 THEN TRUE
        ELSE FALSE
    END AS is_rush_hour

FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`;

-- Add table description
ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_datetime`
SET OPTIONS (
    description = 'Time dimension table - contains all temporal attributes for trip analysis'
);
