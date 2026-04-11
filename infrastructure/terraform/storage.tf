# GCS Bucket for all data and configurations
resource "google_storage_bucket" "data_bucket" {
  name          = var.gcs_bucket_name
  location      = var.gcp_region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = merge(
    local.common_labels,
    {
      layer = "data"
    }
  )
}

# Raw Data Folder
resource "google_storage_bucket_object_v1" "raw_folder" {
  name   = "raw/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# Raw Taxi Trips Folder
resource "google_storage_bucket_object_v1" "raw_taxi_trips_folder" {
  name   = "raw/taxi_trips/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# Composer DAGs Folder
resource "google_storage_bucket_object_v1" "composer_dags_folder" {
  name   = "composer/dags/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# Spark Scripts Folder
resource "google_storage_bucket_object_v1" "spark_scripts_folder" {
  name   = "scripts/spark/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# ML Artifacts Folder
resource "google_storage_bucket_object_v1" "ml_artifacts_folder" {
  name   = "ml/artifacts/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# ML Models Folder
resource "google_storage_bucket_object_v1" "ml_models_folder" {
  name   = "ml/models/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# Temp Spark Folder
resource "google_storage_bucket_object_v1" "temp_spark_folder" {
  name   = "temp/spark_temp/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}

# Terraform State Folder
resource "google_storage_bucket_object_v1" "terraform_folder" {
  name   = "terraform/"
  bucket = google_storage_bucket.data_bucket.name
  content = " "
}
