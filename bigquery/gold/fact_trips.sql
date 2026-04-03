-- ============================================================
-- Phase 5: Gold Layer - fact_trips (Fact Table)
-- ============================================================
-- Central fact table containing trip metrics with foreign keys
-- to all dimension tables. Partitioned and clustered for
-- optimal query performance and cost efficiency.
-- ============================================================

CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.fact_trips`
PARTITION BY DATE(pickup_datetime)
CLUSTER BY vendor_key, pickup_location_key
AS
SELECT
    -- ========================================
    -- Primary Key
    -- ========================================
    t.id AS trip_id,

    -- ========================================
    -- Foreign Keys to Dimensions
    -- ========================================
    CONCAT(
        CAST(t.pickup_year AS STRING),
        LPAD(CAST(t.pickup_month AS STRING), 2, '0'),
        LPAD(CAST(t.pickup_day AS STRING), 2, '0'),
        LPAD(CAST(t.pickup_hour AS STRING), 2, '0')
    ) AS datetime_key,
    t.vendor_id AS vendor_key,
    pl.location_key AS pickup_location_key,
    dl.location_key AS dropoff_location_key,

    -- ========================================
    -- Date Columns (for partitioning)
    -- ========================================
    t.pickup_datetime,
    t.dropoff_datetime,

    -- ========================================
    -- Measures (Facts)
    -- ========================================
    t.passenger_count,
    t.trip_duration,
    t.trip_duration_minutes,
    t.distance_km,
    t.speed_kmh,

    -- ========================================
    -- Raw Coordinates (for detailed analysis)
    -- ========================================
    t.pickup_latitude,
    t.pickup_longitude,
    t.dropoff_latitude,
    t.dropoff_longitude,

    -- ========================================
    -- Other Attributes
    -- ========================================
    t.store_and_fwd_flag

FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched` t

LEFT JOIN `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_location` pl
    ON t.pickup_lat_grid = pl.lat_grid
    AND t.pickup_lon_grid = pl.lon_grid

LEFT JOIN `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_location` dl
    ON t.dropoff_lat_grid = dl.lat_grid
    AND t.dropoff_lon_grid = dl.lon_grid;

-- Add table description
ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.fact_trips`
SET OPTIONS (
    description = 'Central fact table - trip metrics with dimension keys. Partitioned by pickup date, clustered by vendor and pickup location.'
);
