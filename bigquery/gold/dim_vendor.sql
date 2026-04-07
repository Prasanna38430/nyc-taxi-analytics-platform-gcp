-- Gold Layer - dim_vendor (Vendor Dimension Table)
-- Creates the vendor dimension mapping vendor IDs to business names.

CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_vendor` AS
SELECT DISTINCT
    -- Natural key as surrogate (vendor IDs are stable)
    vendor_id AS vendor_key,
    vendor_id,

    -- Vendor name mapping
    CASE vendor_id
        WHEN 1 THEN 'Creative Mobile Technologies'
        WHEN 2 THEN 'VeriFone Inc'
        ELSE 'Unknown'
    END AS vendor_name

FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
WHERE vendor_id IS NOT NULL;

-- Add table description
ALTER TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_vendor`
SET OPTIONS (
    description = 'Vendor dimension table - taxi technology providers'
);
