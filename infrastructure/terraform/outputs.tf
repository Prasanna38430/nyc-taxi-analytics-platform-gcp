# GCS outputs
output "gcs_bucket_name" {
  description = "GCS bucket name for all data"
  value       = google_storage_bucket.data_bucket.name
}

output "gcs_bucket_url" {
  description = "GCS bucket URL"
  value       = "gs://${google_storage_bucket.data_bucket.name}/"
}

# BigQuery outputs
output "bronze_dataset_id" {
  description = "Bronze dataset ID"
  value       = data.google_bigquery_dataset.bronze.dataset_id
}

output "silver_dataset_id" {
  description = "Silver dataset ID"
  value       = data.google_bigquery_dataset.silver.dataset_id
}

output "gold_dataset_id" {
  description = "Gold dataset ID"
  value       = data.google_bigquery_dataset.gold.dataset_id
}

output "ml_dataset_id" {
  description = "ML dataset ID"
  value       = data.google_bigquery_dataset.ml.dataset_id
}

# Service account outputs
output "service_account_email" {
  description = "Pipeline service account email"
  value       = data.google_service_account.pipeline_sa.email
}

output "service_account_id" {
  description = "Pipeline service account unique ID"
  value       = data.google_service_account.pipeline_sa.unique_id
}

# ====================================
# PROJECT OUTPUTS
# ====================================
output "project_id" {
  description = "GCP Project ID"
  value       = var.gcp_project_id
}

output "region" {
  description = "GCP Region"
  value       = var.gcp_region
}

output "zone" {
  description = "GCP Zone"
  value       = var.gcp_zone
}
