-- BigQuery Bronze Layer - External Table
-- Creates an external table pointing to raw CSV data in GCS.
-- Schema-on-read approach for the Bronze layer.

-- Create Bronze dataset if not exists
CREATE SCHEMA IF NOT EXISTS `nyc-taxi-analytics-g12.nyc_taxi_bronze`
OPTIONS (
    description = 'Bronze layer - Raw data with minimal transformation',
    location = 'us-central1'
);

-- Create external table pointing to GCS
CREATE OR REPLACE EXTERNAL TABLE `nyc-taxi-analytics-g12.nyc_taxi_bronze.raw_trips`
OPTIONS (
    format = 'CSV',
    uris = ['gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/train.csv'],
    skip_leading_rows = 1,
    description = 'Raw NYC taxi trip data - external table pointing to GCS'
);

-- Verify the external table
SELECT
    COUNT(*) as total_rows,
    MIN(pickup_datetime) as min_pickup,
    MAX(pickup_datetime) as max_pickup
FROM `nyc-taxi-analytics-g12.nyc_taxi_bronze.raw_trips`;
