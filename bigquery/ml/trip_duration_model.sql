-- BigQuery ML - Trip Duration Prediction Model
-- Linear regression model to predict NYC taxi trip duration.
-- Training, evaluation, and prediction queries.

-- 1. Create Training Dataset
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features_sample` AS
SELECT
    vendor_id,
    passenger_count,
    pickup_hour,
    pickup_dayofweek,
    CASE WHEN is_weekend THEN 1 ELSE 0 END AS is_weekend,
    distance_km,
    pickup_latitude,
    pickup_longitude,
    dropoff_latitude,
    dropoff_longitude,
    trip_duration_minutes AS target
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
WHERE trip_duration_minutes BETWEEN 1 AND 120
  AND distance_km > 0
LIMIT 5000;  -- Sample for faster training


-- 2. Create ML Model - Linear Regression
CREATE OR REPLACE MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['target'],
  max_iterations=50
) AS
SELECT
  vendor_id,
  passenger_count,
  pickup_hour,
  pickup_dayofweek,
  is_weekend,
  distance_km,
  pickup_latitude,
  pickup_longitude,
  dropoff_latitude,
  dropoff_longitude,
  target
FROM `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features_sample`
WHERE target IS NOT NULL;


-- 3. Evaluate Model Performance
SELECT
  mean_absolute_error,
  mean_squared_error,
  root_mean_squared_error,
  r2_score,
  explained_variance
FROM
  ML.EVALUATE(MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`);


-- 4. Get Feature Importance
SELECT
  feature,
  importance_weight,
  importance_weight / SUM(importance_weight) OVER () AS importance_percentage
FROM
  ML.FEATURE_IMPORTANCE(MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`)
ORDER BY
  importance_weight DESC;

-- 5. Make Predictions - Sample Trip
SELECT
  predicted_target AS predicted_duration_minutes,
  ROUND(predicted_target, 2) AS predicted_duration_rounded
FROM
  ML.PREDICT(MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`,
  (
    SELECT
      2 AS vendor_id,
      1 AS passenger_count,
      14 AS pickup_hour,
      3 AS pickup_dayofweek,
      0 AS is_weekend,
      3.5 AS distance_km,
      40.7580 AS pickup_latitude,
      -73.9855 AS pickup_longitude,
      40.7128 AS dropoff_latitude,
      -74.0060 AS dropoff_longitude
  ));

-- 6. Batch Predictions - On Full Test Set
SELECT
  trip_id,
  actual_duration,
  predicted_duration,
  ABS(actual_duration - predicted_duration) AS error_minutes
FROM (
  SELECT
    ROW_NUMBER() OVER () AS trip_id,
    target AS actual_duration,
    predicted_target AS predicted_duration
  FROM
    ML.PREDICT(MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`,
    (
      SELECT * FROM `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features_sample`
      WHERE target IS NOT NULL
      LIMIT 100
    ))
)
ORDER BY error_minutes DESC
LIMIT 20;

-- 7. Model Statistics
SELECT
  *
FROM
  ML.TRAINING_INFO(MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`);
