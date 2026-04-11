# Bronze dataset - Reference existing dataset
data "google_bigquery_dataset" "bronze" {
  dataset_id = var.bronze_dataset
  project    = var.gcp_project_id
}

# Bronze External Table: raw_trips
resource "google_bigquery_table" "bronze_raw_trips" {
  dataset_id = data.google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_trips"

  schema = jsonencode([
    { name = "id", type = "STRING", mode = "NULLABLE" },
    { name = "vendor_id", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_datetime", type = "STRING", mode = "NULLABLE" },
    { name = "dropoff_datetime", type = "STRING", mode = "NULLABLE" },
    { name = "passenger_count", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_longitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "pickup_latitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_longitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_latitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "store_and_fwd_flag", type = "STRING", mode = "NULLABLE" },
    { name = "trip_duration", type = "INTEGER", mode = "NULLABLE" }
  ])

  labels = merge(
    local.common_labels,
    {
      table_type = "external"
    }
  )
}

# Silver dataset - Reference existing dataset
data "google_bigquery_dataset" "silver" {
  dataset_id = var.silver_dataset
  project    = var.gcp_project_id
}

# Silver Table: trips_enriched
resource "google_bigquery_table" "silver_trips_enriched" {
  dataset_id            = data.google_bigquery_dataset.silver.dataset_id
  table_id              = "trips_enriched"
  deletion_protection   = false

  time_partitioning {
    type          = "DAY"
    field         = "pickup_datetime"
    expiration_ms = null
  }

  clustering = ["vendor_id", "passenger_count"]

  schema = jsonencode([
    { name = "id", type = "STRING", mode = "NULLABLE" },
    { name = "vendor_id", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_datetime", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "dropoff_datetime", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "passenger_count", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_longitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "pickup_latitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_longitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_latitude", type = "FLOAT", mode = "NULLABLE" },
    { name = "store_and_fwd_flag", type = "STRING", mode = "NULLABLE" },
    { name = "trip_duration", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_year", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_month", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_day", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_hour", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_dayofweek", type = "INTEGER", mode = "NULLABLE" },
    { name = "pickup_day_name", type = "STRING", mode = "NULLABLE" },
    { name = "is_weekend", type = "BOOLEAN", mode = "REQUIRED" },
    { name = "time_of_day", type = "STRING", mode = "REQUIRED" },
    { name = "distance_km", type = "FLOAT", mode = "NULLABLE" },
    { name = "speed_kmh", type = "FLOAT", mode = "NULLABLE" },
    { name = "trip_duration_minutes", type = "FLOAT", mode = "NULLABLE" },
    { name = "pickup_lat_grid", type = "FLOAT", mode = "NULLABLE" },
    { name = "pickup_lon_grid", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_lat_grid", type = "FLOAT", mode = "NULLABLE" },
    { name = "dropoff_lon_grid", type = "FLOAT", mode = "NULLABLE" },
    { name = "etl_timestamp", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "etl_version", type = "STRING", mode = "REQUIRED" }
  ])

  labels = merge(
    local.common_labels,
    {
      table_type = "enriched"
    }
  )
}

# Gold dataset - Reference existing dataset
data "google_bigquery_dataset" "gold" {
  dataset_id = var.gold_dataset
  project    = var.gcp_project_id
}

# Gold: Fact Table - fact_trips
resource "google_bigquery_table" "gold_fact_trips" {
  dataset_id            = data.google_bigquery_dataset.gold.dataset_id
  table_id              = "fact_trips"
  deletion_protection   = false

  time_partitioning {
    type          = "DAY"
    field         = "pickup_datetime"
    expiration_ms = null
  }

  clustering = ["vendor_key", "pickup_location_key"]

  labels = merge(
    local.common_labels,
    {
      table_type = "fact"
    }
  )
}

# Gold: Dimension Table - dim_vendor
resource "google_bigquery_table" "gold_dim_vendor" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "dim_vendor"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "dimension"
    }
  )
}

# Gold: Dimension Table - dim_datetime
resource "google_bigquery_table" "gold_dim_datetime" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "dim_datetime"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "dimension"
    }
  )
}

# Gold: Dimension Table - dim_location
resource "google_bigquery_table" "gold_dim_location" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "dim_location"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "dimension"
    }
  )
}

# Gold: Aggregation Table - agg_daily_summary
resource "google_bigquery_table" "gold_agg_daily_summary" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "agg_daily_summary"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "aggregation"
    }
  )
}

# Gold: Aggregation Table - agg_hourly_patterns
resource "google_bigquery_table" "gold_agg_hourly_patterns" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "agg_hourly_patterns"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "aggregation"
    }
  )
}

# Gold: Aggregation Table - agg_vendor_performance
resource "google_bigquery_table" "gold_agg_vendor_performance" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "agg_vendor_performance"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "aggregation"
    }
  )
}

# Gold: Aggregation Table - agg_location_hotspots
resource "google_bigquery_table" "gold_agg_location_hotspots" {
  dataset_id          = data.google_bigquery_dataset.gold.dataset_id
  table_id            = "agg_location_hotspots"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "aggregation"
    }
  )
}

# ML dataset - Reference existing dataset
data "google_bigquery_dataset" "ml" {
  dataset_id = var.ml_dataset
  project    = var.gcp_project_id
}

# ML: Training Features Table
resource "google_bigquery_table" "ml_training_features" {
  dataset_id          = data.google_bigquery_dataset.ml.dataset_id
  table_id            = "training_features"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "training_data"
    }
  )
}

# ML: Training Features Sample Table
resource "google_bigquery_table" "ml_training_features_sample" {
  dataset_id          = data.google_bigquery_dataset.ml.dataset_id
  table_id            = "training_features_sample"
  deletion_protection = false

  labels = merge(
    local.common_labels,
    {
      table_type = "training_data"
      purpose    = "model_training"
    }
  )
}
