"""
Event-Triggered ETL Pipeline DAG for NYC Taxi Analytics.

Triggered automatically when new data is uploaded to GCS.
Can also be triggered manually for testing.
Runs Bronze to Silver ETL, refreshes aggregations, and prepares ML features.
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocCreateClusterOperator,
    DataprocDeleteClusterOperator,
    DataprocSubmitJobOperator,
)
from airflow.providers.google.cloud.operators.bigquery import (
    BigQueryInsertJobOperator,
)
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor
from airflow.operators.python import PythonOperator
from airflow.operators.dummy import DummyOperator
from airflow.utils.trigger_rule import TriggerRule
import logging


# Configuration

PROJECT_ID = "nyc-taxi-analytics-g12"
REGION = "us-central1"
BUCKET_NAME = "nyc-taxi-data-bucket-g12"
SPARK_SCRIPT_PATH = f"gs://{BUCKET_NAME}/scripts/spark/spark_bronze_to_silver.py"

# Dynamic cluster name with execution date
CLUSTER_NAME = "taxi-etl-{{ ds_nodash }}"

CLUSTER_CONFIG = {
    "config_bucket": "nyc-taxi-data-bucket-g12",
    "master_config": {
        "num_instances": 1,
        "machine_type_uri": "n1-standard-1",  # Reduced from n1-standard-2
        "disk_config": {"boot_disk_size_gb": 50},  # Reduced from 100
    },
    "worker_config": {
        "num_instances": 2,  # Minimum required by Dataproc
        "machine_type_uri": "n1-standard-1",  # Reduced from n1-standard-2
        "disk_config": {"boot_disk_size_gb": 50},  # Reduced from 100
    },
    "software_config": {
        "image_version": "2.1-debian11",
    },
}

PYSPARK_JOB = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": CLUSTER_NAME},
    "pyspark_job": {
        "main_python_file_uri": SPARK_SCRIPT_PATH,
        "properties": {
            "spark.executor.memory": "4g",
            "spark.driver.memory": "2g",
        },
    },
}

DEFAULT_ARGS = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}


# SQL Queries

REFRESH_GOLD_TABLES_SQL = """
-- Refresh all Gold layer aggregations in a single transaction
BEGIN TRANSACTION;

-- Daily Summary
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_daily_summary` AS
SELECT
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS total_trips,
    SUM(passenger_count) AS total_passengers,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(distance_km), 2) AS avg_distance_km,
    ROUND(AVG(speed_kmh), 2) AS avg_speed_kmh
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
GROUP BY trip_date;

-- Hourly Patterns
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_hourly_patterns` AS
SELECT
    pickup_hour AS hour,
    pickup_day_name AS day_name,
    is_weekend,
    time_of_day,
    COUNT(*) AS total_trips,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(distance_km), 2) AS avg_distance_km
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
GROUP BY pickup_hour, pickup_day_name, is_weekend, time_of_day;

-- Vendor Performance
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_vendor_performance` AS
SELECT
    v.vendor_name,
    COUNT(*) AS total_trips,
    ROUND(AVG(f.trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(AVG(f.distance_km), 2) AS avg_distance_km
FROM `nyc-taxi-analytics-g12.nyc_taxi_gold.fact_trips` f
JOIN `nyc-taxi-analytics-g12.nyc_taxi_gold.dim_vendor` v ON f.vendor_key = v.vendor_key
GROUP BY v.vendor_name;

COMMIT TRANSACTION;
"""

PREPARE_ML_FEATURES_SQL = """
CREATE OR REPLACE TABLE `nyc-taxi-analytics-g12.nyc_taxi_ml.training_features` AS
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
"""


# Callback Functions

def log_pipeline_start(**context):
    """Log pipeline start with metadata."""
    logging.info("=" * 60)
    logging.info("NYC TAXI ETL PIPELINE STARTED")
    logging.info(f"Execution Date: {context['execution_date']}")
    logging.info(f"DAG Run ID: {context['run_id']}")
    logging.info("=" * 60)


def log_pipeline_complete(**context):
    """Log pipeline completion with summary."""
    logging.info("=" * 60)
    logging.info("NYC TAXI ETL PIPELINE COMPLETED SUCCESSFULLY!")
    logging.info(f"Duration: Check Airflow UI for details")
    logging.info("=" * 60)


# DAG Definition

with DAG(
    dag_id="nyc_taxi_etl_pipeline",
    description="Event-triggered ETL: Bronze → Silver → Gold → ML Features",
    default_args=DEFAULT_ARGS,
    # Can be triggered manually or by Cloud Function
    schedule_interval=None,  # No schedule - triggered on demand
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["nyc-taxi", "etl", "event-driven", "production"],
) as dag:

    # Initialization

    start = PythonOperator(
        task_id="log_pipeline_start",
        python_callable=log_pipeline_start,
    )

    check_data_exists = GCSObjectExistenceSensor(
        task_id="check_source_data",
        bucket=BUCKET_NAME,
        object="raw/taxi_trips/train.csv",
        timeout=60,
        poke_interval=10,
    )

    # ========================================================================
    # STAGE 2: SPARK ETL (BRONZE → SILVER)
    # ========================================================================

    create_cluster = DataprocCreateClusterOperator(
        task_id="create_dataproc_cluster",
        project_id=PROJECT_ID,
        cluster_name=CLUSTER_NAME,
        region=REGION,
        cluster_config=CLUSTER_CONFIG,
    )

    run_etl = DataprocSubmitJobOperator(
        task_id="run_bronze_to_silver_etl",
        project_id=PROJECT_ID,
        region=REGION,
        job=PYSPARK_JOB,
    )

    delete_cluster = DataprocDeleteClusterOperator(
        task_id="delete_dataproc_cluster",
        project_id=PROJECT_ID,
        cluster_name=CLUSTER_NAME,
        region=REGION,
        trigger_rule=TriggerRule.ALL_DONE,  # Always cleanup
    )

    # ========================================================================
    # STAGE 3: GOLD LAYER REFRESH
    # ========================================================================

    refresh_gold = BigQueryInsertJobOperator(
        task_id="refresh_gold_aggregations",
        configuration={
            "query": {
                "query": REFRESH_GOLD_TABLES_SQL,
                "useLegacySql": False,
            }
        },
        location="us-central1",
    )

    # ========================================================================
    # STAGE 4: ML FEATURE PREPARATION
    # ========================================================================

    prepare_ml = BigQueryInsertJobOperator(
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
    # STAGE 5: COMPLETION
    # ========================================================================

    complete = PythonOperator(
        task_id="log_pipeline_complete",
        python_callable=log_pipeline_complete,
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # ========================================================================
    # DEPENDENCIES
    # ========================================================================

    (
        start
        >> check_data_exists
        >> create_cluster
        >> run_etl
        >> delete_cluster
        >> refresh_gold
        >> prepare_ml
        >> complete
    )
