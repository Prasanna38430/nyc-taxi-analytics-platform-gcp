-- Gold Layer - Aggregated Tables
-- Pre-computed aggregations for common analytical queries.
-- Improves dashboard performance and reduces costs.

-- 1. Daily Summary Aggregation
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_daily_summary` AS
SELECT
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS total_trips,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(speed_kmh), 2) AS avg_speed_kmh,
    ROUND(STDDEV(trip_duration_minutes), 2) AS stddev_duration,
    MIN(trip_duration_minutes) AS min_duration,
    MAX(trip_duration_minutes) AS max_duration
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
GROUP BY trip_date
ORDER BY trip_date;

-- 2. Hourly Patterns Aggregation
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_hourly_patterns` AS
SELECT
    pickup_hour AS hour,
    pickup_day_name AS day_name,
    is_weekend,
    time_of_day,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(passenger_count), 2) AS avg_passengers
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
GROUP BY pickup_hour, pickup_day_name, is_weekend, time_of_day
ORDER BY
    CASE pickup_day_name
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        ELSE 7
    END,
    pickup_hour;

-- 3. Vendor Performance Aggregation
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_vendor_performance` AS
SELECT
    v.vendor_name,
    COUNT(*) AS total_trips,
    ROUND(AVG(f.trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(f.distance_km), 2) AS avg_distance_km,
    ROUND(AVG(f.speed_kmh), 2) AS avg_speed_kmh,
    ROUND(AVG(f.passenger_count), 2) AS avg_passengers,
    SUM(f.passenger_count) AS total_passengers
FROM `nyc-taxi-analytics-g12.nyc_taxi_gold.fact_trips` f
JOIN `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_vendor` v
    ON f.vendor_key = v.vendor_key
GROUP BY v.vendor_name;

-- 4. Location Hotspots Aggregation
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_location_hotspots` AS
SELECT
    l.approximate_borough,
    l.grid_id,
    l.lat_grid,
    l.lon_grid,
    COUNT(*) AS pickup_count,
    ROUND(AVG(f.trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(f.distance_km), 2) AS avg_distance_km
FROM `nyc-taxi-analytics-g12.nyc_taxi_gold.fact_trips` f
JOIN `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_location` l
    ON f.pickup_location_key = l.location_key
GROUP BY l.approximate_borough, l.grid_id, l.lat_grid, l.lon_grid
ORDER BY pickup_count DESC;

-- Add Table Descriptions
ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_daily_summary`
SET OPTIONS (description = 'Daily aggregated trip statistics');

ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_hourly_patterns`
SET OPTIONS (description = 'Hourly trip patterns by day of week');

ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_vendor_performance`
SET OPTIONS (description = 'Vendor performance metrics');

ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_location_hotspots`
SET OPTIONS (description = 'Pickup location hotspots with metrics');
