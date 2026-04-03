"""
NYC Taxi Analytics - Daily ETL Pipeline DAG
============================================
Orchestrates the complete data pipeline from Bronze to Gold layer.

This DAG:
1. Creates an ephemeral Dataproc cluster (cost optimization)
2. Runs the Spark ETL job (Bronze → Silver)
3. Deletes the cluster after job completion
4. Refreshes BigQuery Gold layer aggregations
5. Sends notification on completion/failure

Schedule: Daily at 2:00 AM UTC
Author: Group 12
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


# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_ID = "nyc-taxi-analytics-g12"
REGION = "us-central1"
ZONE = "us-central1-a"
BUCKET_NAME = "nyc-taxi-data-bucket-g12"

# Cluster configuration
CLUSTER_NAME = "nyc-taxi-etl-cluster-{{ ds_nodash }}"
CLUSTER_CONFIG = {
    "master_config": {
        "num_instances": 1,
        "machine_type_uri": "n1-standard-4",
        "disk_config": {
            "boot_disk_type": "pd-standard",
            "boot_disk_size_gb": 100,
        },
    },
    "worker_config": {
        "num_instances": 2,
        "machine_type_uri": "n1-standard-4",
        "disk_config": {
            "boot_disk_type": "pd-standard",
            "boot_disk_size_gb": 100,
        },
    },
    "software_config": {
        "image_version": "2.1-debian11",
    },
}

# Spark job configuration
SPARK_JOB = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": CLUSTER_NAME},
    "pyspark_job": {
        "main_python_file_uri": f"gs://{BUCKET_NAME}/scripts/spark/spark_bronze_to_silver.py",
        "properties": {
            "spark.executor.memory": "4g",
            "spark.driver.memory": "2g",
            "spark.sql.adaptive.enabled": "true",
        },
    },
}

# Default DAG arguments
DEFAULT_ARGS = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "email": ["alerts@example.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=2),
}


# ============================================================================
# SQL QUERIES FOR GOLD LAYER REFRESH
# ============================================================================

REFRESH_DAILY_SUMMARY_SQL = """
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
ORDER BY trip_date
"""

REFRESH_HOURLY_PATTERNS_SQL = """
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
"""

REFRESH_VENDOR_PERFORMANCE_SQL = """
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
GROUP BY v.vendor_name
"""


# ============================================================================
# CALLBACK FUNCTIONS
# ============================================================================

def on_success_callback(context):
    """Log success message - can be extended to send Slack/Teams notification."""
    dag_id = context['dag'].dag_id
    execution_date = context['execution_date']
    print(f"DAG {dag_id} completed successfully for {execution_date}")


def on_failure_callback(context):
    """Log failure message - can be extended to send PagerDuty alert."""
    dag_id = context['dag'].dag_id
    task_id = context['task_instance'].task_id
    execution_date = context['execution_date']
    print(f"DAG {dag_id} failed at task {task_id} for {execution_date}")


# ============================================================================
# DAG DEFINITION
# ============================================================================

with DAG(
    dag_id="nyc_taxi_daily_etl_pipeline",
    description="Daily ETL pipeline: Bronze → Silver → Gold",
    default_args=DEFAULT_ARGS,
    schedule_interval="0 2 * * *",  # Daily at 2 AM UTC
    start_date=datetime(2024, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["nyc-taxi", "etl", "production"],
    on_success_callback=on_success_callback,
    on_failure_callback=on_failure_callback,
) as dag:

    # ========================================================================
    # TASK: Start Pipeline
    # ========================================================================
    start = DummyOperator(
        task_id="start_pipeline",
    )

    # ========================================================================
    # TASK: Check if Source Data Exists
    # ========================================================================
    check_source_data = GCSObjectExistenceSensor(
        task_id="check_source_data_exists",
        bucket=BUCKET_NAME,
        object="raw/taxi_trips/train.csv",
        timeout=300,
        poke_interval=30,
    )

    # ========================================================================
    # TASK: Create Dataproc Cluster
    # ========================================================================
    create_cluster = DataprocCreateClusterOperator(
        task_id="create_dataproc_cluster",
        project_id=PROJECT_ID,
        cluster_name=CLUSTER_NAME,
        region=REGION,
        cluster_config=CLUSTER_CONFIG,
    )

    # ========================================================================
    # TASK: Run Spark ETL Job
    # ========================================================================
    run_spark_etl = DataprocSubmitJobOperator(
        task_id="run_spark_bronze_to_silver",
        project_id=PROJECT_ID,
        region=REGION,
        job=SPARK_JOB,
    )

    # ========================================================================
    # TASK: Delete Dataproc Cluster (runs even if ETL fails)
    # ========================================================================
    delete_cluster = DataprocDeleteClusterOperator(
        task_id="delete_dataproc_cluster",
        project_id=PROJECT_ID,
        cluster_name=CLUSTER_NAME,
        region=REGION,
        trigger_rule=TriggerRule.ALL_DONE,  # Always run (cleanup)
    )

    # ========================================================================
    # TASK: Refresh Gold Layer Aggregations
    # ========================================================================
    refresh_daily_summary = BigQueryInsertJobOperator(
        task_id="refresh_daily_summary",
        configuration={
            "query": {
                "query": REFRESH_DAILY_SUMMARY_SQL,
                "useLegacySql": False,
            }
        },
        location="us-central1",
    )

    refresh_hourly_patterns = BigQueryInsertJobOperator(
        task_id="refresh_hourly_patterns",
        configuration={
            "query": {
                "query": REFRESH_HOURLY_PATTERNS_SQL,
                "useLegacySql": False,
            }
        },
        location="us-central1",
    )

    refresh_vendor_performance = BigQueryInsertJobOperator(
        task_id="refresh_vendor_performance",
        configuration={
            "query": {
                "query": REFRESH_VENDOR_PERFORMANCE_SQL,
                "useLegacySql": False,
            }
        },
        location="us-central1",
    )

    # ========================================================================
    # TASK: End Pipeline
    # ========================================================================
    end = DummyOperator(
        task_id="end_pipeline",
        trigger_rule=TriggerRule.ALL_SUCCESS,
    )

    # ========================================================================
    # TASK DEPENDENCIES
    # ========================================================================
    # fmt: off
    (
        start
        >> check_source_data
        >> create_cluster
        >> run_spark_etl
        >> delete_cluster
        >> [refresh_daily_summary, refresh_hourly_patterns, refresh_vendor_performance]
        >> end
    )
    # fmt: on
