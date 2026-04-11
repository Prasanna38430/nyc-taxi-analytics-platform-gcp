# Bronze dataset - Reference existing dataset
data "google_bigquery_dataset" "bronze" {
  dataset_id = var.bronze_dataset
  project    = var.gcp_project_id
}

# Silver dataset - Reference existing dataset
data "google_bigquery_dataset" "silver" {
  dataset_id = var.silver_dataset
  project    = var.gcp_project_id
}

# Gold dataset - Reference existing dataset
data "google_bigquery_dataset" "gold" {
  dataset_id = var.gold_dataset
  project    = var.gcp_project_id
}

# ML dataset - Reference existing dataset
data "google_bigquery_dataset" "ml" {
  dataset_id = var.ml_dataset
  project    = var.gcp_project_id
}
