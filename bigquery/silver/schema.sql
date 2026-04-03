-- ============================================================
-- Phase 4: BigQuery Silver Layer Schema
-- ============================================================
-- The Silver layer is populated by the Spark ETL job.
-- This file documents the expected schema after processing.
-- ============================================================

-- Create Silver dataset
CREATE SCHEMA IF NOT EXISTS `nyc-taxi-analytics-g12.nyc_taxi_silver`
OPTIONS (
    description = 'Silver layer - Cleaned, validated, and enriched data',
    location = 'us-central1'
);

-- ============================================================
-- Silver Table Schema (Created by Spark ETL)
-- ============================================================
-- Table: nyc_taxi_silver.trips_enriched
--
-- Original Columns:
--   id                    STRING      Trip identifier
--   vendor_id             INTEGER     Vendor code
--   pickup_datetime       TIMESTAMP   Pickup time
--   dropoff_datetime      TIMESTAMP   Dropoff time
--   passenger_count       INTEGER     Number of passengers
--   pickup_longitude      FLOAT       Pickup longitude
--   pickup_latitude       FLOAT       Pickup latitude
--   dropoff_longitude     FLOAT       Dropoff longitude
--   dropoff_latitude      FLOAT       Dropoff latitude
--   store_and_fwd_flag    STRING      Store and forward flag
--   trip_duration         INTEGER     Duration in seconds
--
-- Derived Features (added by Spark):
--   pickup_year           INTEGER     Year of pickup
--   pickup_month          INTEGER     Month of pickup (1-12)
--   pickup_day            INTEGER     Day of month (1-31)
--   pickup_hour           INTEGER     Hour of day (0-23)
--   pickup_dayofweek      INTEGER     Day of week (1=Mon, 7=Sun)
--   pickup_day_name       STRING      Day name (Monday, Tuesday, etc.)
--   is_weekend            BOOLEAN     True if Saturday/Sunday
--   time_of_day           STRING      Morning/Afternoon/Evening/Night
--   distance_km           FLOAT       Haversine distance in km
--   speed_kmh             FLOAT       Average speed km/h
--   trip_duration_minutes FLOAT       Duration in minutes
--   pickup_lat_grid       FLOAT       Rounded pickup latitude
--   pickup_lon_grid       FLOAT       Rounded pickup longitude
--   dropoff_lat_grid      FLOAT       Rounded dropoff latitude
--   dropoff_lon_grid      FLOAT       Rounded dropoff longitude
--   etl_timestamp         TIMESTAMP   When record was processed
--   etl_version           STRING      ETL pipeline version
--
-- ============================================================

-- Sample query to verify Silver layer after Spark job
SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT pickup_year) as years,
    COUNT(DISTINCT time_of_day) as time_categories,
    ROUND(AVG(distance_km), 2) as avg_distance_km,
    ROUND(AVG(trip_duration_minutes), 2) as avg_duration_minutes
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`;
