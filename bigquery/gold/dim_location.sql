-- Gold Layer - dim_location (Location Dimension Table)
-- Creates the location dimension using grid-based aggregation.
-- Enables efficient spatial analysis.

CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_location` AS

WITH pickup_locations AS (
    SELECT DISTINCT
        pickup_lat_grid AS lat_grid,
        pickup_lon_grid AS lon_grid
    FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
),

dropoff_locations AS (
    SELECT DISTINCT
        dropoff_lat_grid AS lat_grid,
        dropoff_lon_grid AS lon_grid
    FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
),

all_locations AS (
    SELECT * FROM pickup_locations
    UNION DISTINCT
    SELECT * FROM dropoff_locations
)

SELECT
    -- Surrogate key
    ROW_NUMBER() OVER (ORDER BY lat_grid, lon_grid) AS location_key,

    -- Grid coordinates
    lat_grid,
    lon_grid,

    -- Grid identifier
    CONCAT(CAST(lat_grid AS STRING), ',', CAST(lon_grid AS STRING)) AS grid_id,

    -- Approximate borough classification
    CASE
        WHEN lat_grid >= 40.75 AND lon_grid >= -74.0 THEN 'Manhattan-Upper'
        WHEN lat_grid >= 40.70 AND lat_grid < 40.75 AND lon_grid >= -74.02 THEN 'Manhattan-Lower'
        WHEN lat_grid >= 40.65 AND lon_grid <= -73.95 THEN 'Brooklyn'
        WHEN lat_grid >= 40.75 AND lon_grid <= -73.90 THEN 'Queens'
        WHEN lat_grid >= 40.80 THEN 'Bronx'
        ELSE 'Other'
    END AS approximate_borough

FROM all_locations;

-- Add table description
ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_location`
SET OPTIONS (
    description = 'Location dimension table - grid-based locations with borough approximation'
);
