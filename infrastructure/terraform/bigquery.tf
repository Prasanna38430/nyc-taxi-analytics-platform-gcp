# Bronze dataset - Reference existing dataset
data "google_bigquery_dataset" "bronze" {
  dataset_id = var.bronze_dataset
  project    = var.gcp_project_id
}

# Bronze External Table: raw_trips - Reference existing table
data "google_bigquery_table" "bronze_raw_trips" {
  dataset_id = data.google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_trips"
  project    = var.gcp_project_id
}

# Silver dataset - Reference existing dataset
data "google_bigquery_dataset" "silver" {
  dataset_id = var.silver_dataset
  project    = var.gcp_project_id
}

# Silver Table: trips_enriched - Reference existing table
data "google_bigquery_table" "silver_trips_enriched" {
  dataset_id = data.google_bigquery_dataset.silver.dataset_id
  table_id   = "trips_enriched"
  project    = var.gcp_project_id
}

# Gold dataset - Reference existing dataset
data "google_bigquery_dataset" "gold" {
  dataset_id = var.gold_dataset
  project    = var.gcp_project_id
}

# Gold: Fact Table - fact_trips - Reference existing table
data "google_bigquery_table" "gold_fact_trips" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "fact_trips"
  project    = var.gcp_project_id
}

# Gold: Dimension Table - dim_vendor - Reference existing table
data "google_bigquery_table" "gold_dim_vendor" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "dim_vendor"
  project    = var.gcp_project_id
}

# Gold: Dimension Table - dim_datetime - Reference existing table
data "google_bigquery_table" "gold_dim_datetime" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "dim_datetime"
  project    = var.gcp_project_id
}

# Gold: Dimension Table - dim_location - Reference existing table
data "google_bigquery_table" "gold_dim_location" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "dim_location"
  project    = var.gcp_project_id
}

# Gold: Aggregation Table - agg_daily_summary - Reference existing table
data "google_bigquery_table" "gold_agg_daily_summary" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "agg_daily_summary"
  project    = var.gcp_project_id
}

# Gold: Aggregation Table - agg_hourly_patterns - Reference existing table
data "google_bigquery_table" "gold_agg_hourly_patterns" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "agg_hourly_patterns"
  project    = var.gcp_project_id
}

# Gold: Aggregation Table - agg_vendor_performance - Reference existing table
data "google_bigquery_table" "gold_agg_vendor_performance" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "agg_vendor_performance"
  project    = var.gcp_project_id
}

# Gold: Aggregation Table - agg_location_hotspots - Reference existing table
data "google_bigquery_table" "gold_agg_location_hotspots" {
  dataset_id = data.google_bigquery_dataset.gold.dataset_id
  table_id   = "agg_location_hotspots"
  project    = var.gcp_project_id
}

# ML dataset - Reference existing dataset
data "google_bigquery_dataset" "ml" {
  dataset_id = var.ml_dataset
  project    = var.gcp_project_id
}

# ML: Training Features Table - Reference existing table
data "google_bigquery_table" "ml_training_features" {
  dataset_id = data.google_bigquery_dataset.ml.dataset_id
  table_id   = "training_features"
  project    = var.gcp_project_id
}

# ML: Training Features Sample Table - Reference existing table
data "google_bigquery_table" "ml_training_features_sample" {
  dataset_id = data.google_bigquery_dataset.ml.dataset_id
  table_id   = "training_features_sample"
  project    = var.gcp_project_id
}
