# Phase 7: BigQuery ML - Trip Duration Prediction

## Overview
Built a linear regression model using BigQuery ML to predict taxi trip duration in minutes.

## Model Details
- **Type**: Linear Regression
- **Target**: trip_duration_minutes
- **Features**: 10 input features
- **Training Data**: 5,000 labeled trips from nyc_taxi_ml.training_features_sample
- **Framework**: BigQuery ML (native SQL-based)

## Features Used
1. vendor_id - Taxi vendor identifier
2. passenger_count - Number of passengers
3. pickup_hour - Hour of pickup (0-23)
4. pickup_dayofweek - Day of week (1-7)
5. is_weekend - Binary weekend flag
6. distance_km - Trip distance in kilometers
7. pickup_latitude - Pickup location latitude
8. pickup_longitude - Pickup location longitude
9. dropoff_latitude - Dropoff location latitude
10. dropoff_longitude - Dropoff location longitude

## Model Performance
- **Mean Absolute Error (MAE)**: [To be filled after model evaluation]
- **Root Mean Squared Error (RMSE)**: [To be filled after model evaluation]
- **R² Score**: [To be filled after model evaluation]

## Key Insights
- Distance is the primary predictor of trip duration
- Time of day (pickup_hour) influences duration
- Weekend trips have different patterns than weekday trips

## Deployment & Usage
- **Model Name**: `trip_duration_model`
- **Location**: `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`
- **Status**: Trained and ready for predictions
- **Use Case**: Real-time trip duration estimation for passengers

## Sample Prediction
```sql
SELECT * FROM ML.PREDICT(
  MODEL `nyc-taxi-analytics-g12.nyc_taxi_ml.trip_duration_model`,
  (SELECT 2 as vendor_id, 1 as passenger_count, ...)
)
```

## Future Improvements
- Add more training data (10K+ trips)
- Try XGBoost or polynomial regression models
- Incorporate weather data
- Real-time model monitoring and retraining
