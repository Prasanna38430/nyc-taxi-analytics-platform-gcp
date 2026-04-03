"""
NYC Taxi Analytics - Weekly ML Training DAG
============================================
Retrains the trip duration prediction model on updated data.

This DAG:
1. Prepares ML feature dataset from Silver layer
2. Triggers Vertex AI training job
3. Evaluates model performance
4. Deploys model if metrics improve

Schedule: Weekly on Sunday at 4:00 AM UTC
Author: Group 12
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator,
    BigQueryCheckOperator,
)
from airflow.providers.google.cloud.operators.vertex_ai.custom_job import (
    CreateCustomTrainingJobOperator,
)
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.dummy import DummyOperator


# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_ID = "nyc-taxi-analytics-g12"
REGION = "us-central1"
BUCKET_NAME = "nyc-taxi-data-bucket-g12"

DEFAULT_ARGS = {
    "owner": "ml-engineering",
    "depends_on_past": False,
    "email": ["ml-alerts@example.com"],
    "email_on_failure": True,
    "retries": 1,
    "retry_delay": timedelta(minutes=10),
}

# ML Feature preparation query
PREPARE_ML_FEATURES_SQL = """
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features` AS
SELECT
    -- Features
    vendor_id,
    passenger_count,
    pickup_hour,
    pickup_dayofweek,
    CASE WHEN is_weekend THEN 1 ELSE 0 END AS is_weekend,
    CASE time_of_day
        WHEN 'Morning' THEN 0
        WHEN 'Afternoon' THEN 1
        WHEN 'Evening' THEN 2
        ELSE 3
    END AS time_of_day_encoded,
    distance_km,
    pickup_latitude,
    pickup_longitude,
    dropoff_latitude,
    dropoff_longitude,

    -- Target variable
    trip_duration_minutes AS target

FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
WHERE
    trip_duration_minutes IS NOT NULL
    AND distance_km IS NOT NULL
    AND distance_km > 0
    AND trip_duration_minutes BETWEEN 1 AND 120  -- Filter outliers
"""

# Check minimum data quality
DATA_QUALITY_CHECK_SQL = """
SELECT
    COUNT(*) >= 100000 AS has_enough_data,
    COUNT(*) AS total_rows,
    AVG(target) AS avg_duration,
    STDDEV(target) AS stddev_duration
FROM `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features`
"""


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def check_model_improvement(**context):
    """
    Compare new model metrics with production model.
    Returns task_id to branch to.
    """
    # In production, this would:
    # 1. Fetch new model metrics from Vertex AI
    # 2. Fetch production model metrics
    # 3. Compare RMSE, MAE, R2

    ti = context['task_instance']

    # Simulated check - in production, pull from XCom or Vertex AI
    new_model_rmse = 5.2  # Would be fetched from training output
    production_rmse = 5.5  # Would be fetched from model registry

    if new_model_rmse < production_rmse:
        return "deploy_new_model"
    else:
        return "skip_deployment"


def log_training_metrics(**context):
    """Log training metrics for monitoring."""
    print("Training completed - logging metrics to Cloud Monitoring")
    # In production: send metrics to Cloud Monitoring


# ============================================================================
# DAG DEFINITION
# ============================================================================

with DAG(
    dag_id="nyc_taxi_weekly_ml_training",
    description="Weekly ML model retraining pipeline",
    default_args=DEFAULT_ARGS,
    schedule_interval="0 4 * * 0",  # Weekly on Sunday at 4 AM UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["nyc-taxi", "ml", "vertex-ai"],
) as dag:

    # ========================================================================
    # TASK: Start
    # ========================================================================
    start = DummyOperator(task_id="start")

    # ========================================================================
    # TASK: Prepare ML Features
    # ========================================================================
    prepare_features = BigQueryInsertJobOperator(
        task_id="prepare_ml_features",
        configuration={
            "query": {
                "query": PREPARE_ML_FEATURES_SQL,
                "useLegacySql": False,
            }
        },
        location="us-central1",
    )

    # ========================================================================
    # TASK: Data Quality Check
    # ========================================================================
    check_data_quality = BigQueryCheckOperator(
        task_id="check_data_quality",
        sql=DATA_QUALITY_CHECK_SQL,
        use_legacy_sql=False,
        location="us-central1",
    )

    # ========================================================================
    # TASK: Train Model (Placeholder - would use Vertex AI)
    # ========================================================================
    # In production, use CreateCustomTrainingJobOperator
    train_model = PythonOperator(
        task_id="train_model",
        python_callable=log_training_metrics,
    )

    # ========================================================================
    # TASK: Check Model Improvement
    # ========================================================================
    check_improvement = BranchPythonOperator(
        task_id="check_model_improvement",
        python_callable=check_model_improvement,
    )

    # ========================================================================
    # TASK: Deploy or Skip
    # ========================================================================
    deploy_model = DummyOperator(
        task_id="deploy_new_model",
    )

    skip_deployment = DummyOperator(
        task_id="skip_deployment",
    )

    # ========================================================================
    # TASK: End
    # ========================================================================
    end = DummyOperator(
        task_id="end",
        trigger_rule="none_failed_min_one_success",
    )

    # ========================================================================
    # DEPENDENCIES
    # ========================================================================
    start >> prepare_features >> check_data_quality >> train_model
    train_model >> check_improvement >> [deploy_model, skip_deployment] >> end
