"""
Bronze to Silver ETL Pipeline for NYC Taxi Trip Data using PySpark.

Processes raw taxi trip data from GCS and loads enriched data into BigQuery.
Version: 1.0
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType, StructField, StringType, IntegerType, FloatType
)
import logging
import sys
from datetime import datetime

# Configuration

CONFIG = {
    "project_id": "nyc-taxi-analytics-g12",
    "input_path": "gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/train.csv",
    "output_table": "nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched",
    "staging_table": "nyc-taxi-analytics-g12.nyc_taxi_silver.trips_staging",
    "temp_gcs_bucket": "nyc-taxi-data-bucket-g12",
    "write_mode": "merge",  # Options: "overwrite", "append", "merge"
    "primary_key": "id"     # Column for deduplication
}

# NYC bounding box for coordinate validation
NYC_BOUNDS = {
    "lat_min": 40.5,
    "lat_max": 41.0,
    "lon_min": -74.3,
    "lon_max": -73.7
}

# Logging Setup

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Schema Definition

RAW_SCHEMA = StructType([
    StructField("id", StringType(), True),
    StructField("vendor_id", IntegerType(), True),
    StructField("pickup_datetime", StringType(), True),
    StructField("dropoff_datetime", StringType(), True),
    StructField("passenger_count", IntegerType(), True),
    StructField("pickup_longitude", FloatType(), True),
    StructField("pickup_latitude", FloatType(), True),
    StructField("dropoff_longitude", FloatType(), True),
    StructField("dropoff_latitude", FloatType(), True),
    StructField("store_and_fwd_flag", StringType(), True),
    StructField("trip_duration", IntegerType(), True)
])


# Spark Session

def create_spark_session():
    """
    Create and configure Spark session optimized for GCP.

    Enables adaptive query execution for better performance
    with varying data distributions.
    """
    logger.info("Creating Spark session...")

    spark = SparkSession.builder \
        .appName("NYC-Taxi-Bronze-to-Silver-ETL") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")
    logger.info(f"Spark version: {spark.version}")

    return spark


# Data Reading

def read_bronze_data(spark, input_path):
    """
    Read raw CSV data from GCS Bronze layer.

    Uses explicit schema to avoid costly schema inference
    and ensure consistent data types across runs.
    """
    logger.info(f"Reading data from: {input_path}")

    df = spark.read \
        .option("header", "true") \
        .schema(RAW_SCHEMA) \
        .csv(input_path)

    row_count = df.count()
    logger.info(f"Rows read from Bronze: {row_count:,}")

    return df


# Data Quality

def log_data_quality_metrics(df, stage_name):
    """
    Log data quality metrics for monitoring and debugging.

    Captures row counts and null distributions at each
    pipeline stage for observability.
    """
    total_rows = df.count()

    null_counts = {}
    for col in df.columns:
        null_count = df.filter(F.col(col).isNull()).count()
        if null_count > 0:
            null_counts[col] = null_count

    logger.info(f"=== Data Quality Report: {stage_name} ===")
    logger.info(f"Total rows: {total_rows:,}")

    if null_counts:
        logger.info(f"Null counts: {null_counts}")
    else:
        logger.info("No null values found")

    return total_rows


def validate_data(df):
    """
    Apply business rules to filter invalid records.

    Removes trips outside NYC bounds, unrealistic durations,
    and invalid passenger counts to ensure data quality.
    """
    logger.info("Applying data validation rules...")
    initial_count = df.count()

    df_valid = df.filter(
        # Coordinates must be within NYC
        (F.col("pickup_latitude").between(NYC_BOUNDS["lat_min"], NYC_BOUNDS["lat_max"])) &
        (F.col("pickup_longitude").between(NYC_BOUNDS["lon_min"], NYC_BOUNDS["lon_max"])) &
        (F.col("dropoff_latitude").between(NYC_BOUNDS["lat_min"], NYC_BOUNDS["lat_max"])) &
        (F.col("dropoff_longitude").between(NYC_BOUNDS["lon_min"], NYC_BOUNDS["lon_max"])) &
        # Duration between 1 minute and 24 hours
        (F.col("trip_duration") > 60) &
        (F.col("trip_duration") < 86400) &
        # Valid passenger count
        (F.col("passenger_count") > 0) &
        (F.col("passenger_count") <= 9) &
        # Required fields present
        F.col("id").isNotNull() &
        F.col("pickup_datetime").isNotNull() &
        F.col("dropoff_datetime").isNotNull()
    )

    final_count = df_valid.count()
    removed = initial_count - final_count
    pct = (removed / initial_count) * 100

    logger.info(f"Rows removed by validation: {removed:,} ({pct:.2f}%)")
    logger.info(f"Rows remaining: {final_count:,}")

    return df_valid


# Feature Engineering

def add_features(df):
    """
    Engineer features for analytics and ML model training.

    Creates time-based, distance-based, and categorical features
    that capture patterns in taxi trip data.
    """
    logger.info("Adding derived features...")

    # Parse timestamps
    df = df.withColumn(
        "pickup_datetime",
        F.to_timestamp("pickup_datetime", "yyyy-MM-dd HH:mm:ss")
    ).withColumn(
        "dropoff_datetime",
        F.to_timestamp("dropoff_datetime", "yyyy-MM-dd HH:mm:ss")
    )

    # Time-based features for temporal analysis
    df = df.withColumn("pickup_year", F.year("pickup_datetime")) \
           .withColumn("pickup_month", F.month("pickup_datetime")) \
           .withColumn("pickup_day", F.dayofmonth("pickup_datetime")) \
           .withColumn("pickup_hour", F.hour("pickup_datetime")) \
           .withColumn("pickup_dayofweek", F.dayofweek("pickup_datetime")) \
           .withColumn("pickup_day_name", F.date_format("pickup_datetime", "EEEE"))

    # Weekend flag for demand pattern analysis
    df = df.withColumn(
        "is_weekend",
        F.when(F.col("pickup_dayofweek").isin([1, 7]), True).otherwise(False)
    )

    # Time of day categories
    df = df.withColumn(
        "time_of_day",
        F.when(F.col("pickup_hour").between(6, 11), "Morning")
         .when(F.col("pickup_hour").between(12, 16), "Afternoon")
         .when(F.col("pickup_hour").between(17, 20), "Evening")
         .otherwise("Night")
    )

    # Haversine distance in kilometers
    df = df.withColumn(
        "distance_km",
        F.round(
            F.lit(6371) * F.acos(
                F.least(F.lit(1), F.greatest(F.lit(-1),
                    F.cos(F.radians("pickup_latitude")) *
                    F.cos(F.radians("dropoff_latitude")) *
                    F.cos(F.radians("dropoff_longitude") - F.radians("pickup_longitude")) +
                    F.sin(F.radians("pickup_latitude")) *
                    F.sin(F.radians("dropoff_latitude"))
                ))
            ), 3
        )
    )

    # Average speed with sanity bounds
    df = df.withColumn(
        "speed_kmh",
        F.round(F.col("distance_km") / (F.col("trip_duration") / 3600.0), 2)
    )
    df = df.withColumn(
        "speed_kmh",
        F.when(
            (F.col("speed_kmh").isNull()) | (F.col("speed_kmh") > 200) | (F.col("speed_kmh") < 0),
            F.lit(None)
        ).otherwise(F.col("speed_kmh"))
    )

    # Duration in minutes for readability
    df = df.withColumn(
        "trip_duration_minutes",
        F.round(F.col("trip_duration") / 60.0, 2)
    )

    # Location grids for zone-based analysis
    df = df.withColumn("pickup_lat_grid", F.round("pickup_latitude", 2)) \
           .withColumn("pickup_lon_grid", F.round("pickup_longitude", 2)) \
           .withColumn("dropoff_lat_grid", F.round("dropoff_latitude", 2)) \
           .withColumn("dropoff_lon_grid", F.round("dropoff_longitude", 2))

    # ETL metadata for lineage
    df = df.withColumn("etl_timestamp", F.current_timestamp()) \
           .withColumn("etl_version", F.lit("1.0"))

    logger.info(f"Features added. Total columns: {len(df.columns)}")
    return df


# Data Writing

def write_to_bigquery(df, output_table, temp_bucket, write_mode):
    """
    Write enriched data to BigQuery Silver layer.

    Configures partitioning and clustering for query performance
    and cost optimization on large analytical workloads.
    """
    logger.info(f"Writing to BigQuery: {output_table}")
    logger.info(f"Write mode: {write_mode}")

    df = df.repartition(10)

    df.write \
        .format("bigquery") \
        .option("table", output_table) \
        .option("temporaryGcsBucket", temp_bucket) \
        .option("partitionField", "pickup_datetime") \
        .option("partitionType", "DAY") \
        .option("clusteredFields", "vendor_id,passenger_count") \
        .mode("overwrite") \
        .save()

    logger.info("Write to BigQuery completed successfully!")


def write_with_merge(spark, df, config):
    """
    Write data using MERGE for exactly-once idempotency.

    This approach:
    1. Writes new data to a staging table
    2. Executes MERGE to upsert into target table
    3. Cleans up staging table

    Guarantees no duplicates even if pipeline is re-run.
    """
    from google.cloud import bigquery

    logger.info("Using MERGE strategy for exactly-once semantics")

    staging_table = config["staging_table"]
    target_table = config["output_table"]
    primary_key = config["primary_key"]
    temp_bucket = config["temp_gcs_bucket"]

    # Step 1: Write to staging table (overwrite)
    logger.info(f"Writing to staging table: {staging_table}")
    df.repartition(10).write \
        .format("bigquery") \
        .option("table", staging_table) \
        .option("temporaryGcsBucket", temp_bucket) \
        .mode("overwrite") \
        .save()

    # Step 2: Execute MERGE statement
    logger.info("Executing MERGE into target table...")
    client = bigquery.Client(project=config["project_id"])

    # Get column list for MERGE (exclude primary key for UPDATE)
    columns = [c for c in df.columns if c != primary_key]
    update_clause = ", ".join([f"T.{c} = S.{c}" for c in columns])
    insert_columns = ", ".join(df.columns)
    insert_values = ", ".join([f"S.{c}" for c in df.columns])

    merge_sql = f"""
    MERGE `{target_table}` T
    USING `{staging_table}` S
    ON T.{primary_key} = S.{primary_key}
    WHEN MATCHED THEN
        UPDATE SET {update_clause}
    WHEN NOT MATCHED THEN
        INSERT ({insert_columns})
        VALUES ({insert_values})
    """

    # Execute MERGE
    job = client.query(merge_sql)
    job.result()  # Wait for completion

    logger.info(f"MERGE completed: {job.num_dml_affected_rows} rows affected")

    # Step 3: Clean up staging table
    logger.info("Cleaning up staging table...")
    client.delete_table(staging_table, not_found_ok=True)

    logger.info("MERGE write completed successfully!")


# Main Pipeline

def main():
    """
    Orchestrate the Bronze to Silver ETL pipeline.

    Executes each transformation step in sequence with
    comprehensive logging for observability.
    """
    start_time = datetime.now()
    logger.info("Starting NYC Taxi Bronze to Silver ETL Pipeline")
    logger.info(f"Start time: {start_time}")

    try:
        # Initialize
        spark = create_spark_session()

        # Step 1: Ingest
        logger.info("Reading Bronze Data")
        df_bronze = read_bronze_data(spark, CONFIG["input_path"])
        log_data_quality_metrics(df_bronze, "Bronze (Raw)")

        # Step 2: Validate
        logger.info("\n--- STEP 2: Data Validation ---")
        df_validated = validate_data(df_bronze)
        log_data_quality_metrics(df_validated, "After Validation")

        # Step 3: Transform
        logger.info("\n--- STEP 3: Feature Engineering ---")
        df_enriched = add_features(df_validated)
        log_data_quality_metrics(df_enriched, "Silver (Enriched)")

        # Step 4: Load
        logger.info("\n--- STEP 4: Writing to BigQuery Silver ---")

        if CONFIG["write_mode"] == "merge":
            # Use MERGE for exactly-once idempotency
            write_with_merge(spark, df_enriched, CONFIG)
        else:
            # Use standard write (overwrite or append)
            write_to_bigquery(
                df_enriched,
                CONFIG["output_table"],
                CONFIG["temp_gcs_bucket"],
                CONFIG["write_mode"]
            )

        # Complete
        end_time = datetime.now()
        duration = end_time - start_time

        logger.info("Pipeline execution completed successfully!")
        logger.info(f"End time: {end_time}")
        logger.info(f"Total duration: {duration}")

        spark.stop()
        return 0

    except Exception as e:
        logger.error(f"Pipeline failed with error: {str(e)}")
        logger.exception("Full traceback:")
        return 1


# Entry Point

if __name__ == "__main__":
    sys.exit(main())
