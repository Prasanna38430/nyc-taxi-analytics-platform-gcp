# Service Account for ETL Pipeline
resource "google_service_account" "pipeline_sa" {
  account_id   = var.service_account_name
  display_name = "NYC Taxi Analytics Pipeline"
  description  = "Service account for ETL pipeline, Dataproc, Cloud Functions, and BigQuery"
}

# IAM roles
# BigQuery Data Editor
resource "google_project_iam_member" "bq_data_editor" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# BigQuery Job User
resource "google_project_iam_member" "bq_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Cloud Functions Invoker
resource "google_project_iam_member" "cloud_functions_invoker" {
  project = var.gcp_project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Composer Worker
resource "google_project_iam_member" "composer_worker" {
  project = var.gcp_project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Dataproc Editor
resource "google_project_iam_member" "dataproc_editor" {
  project = var.gcp_project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Eventarc Event Receiver
resource "google_project_iam_member" "eventarc_receiver" {
  project = var.gcp_project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# IAM Service Account User
resource "google_project_iam_member" "iam_sa_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Storage Admin
resource "google_project_iam_member" "storage_admin" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# Workflows Invoker
resource "google_project_iam_member" "workflows_invoker" {
  project = var.gcp_project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}
