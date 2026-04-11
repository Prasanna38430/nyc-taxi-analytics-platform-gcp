# GCP Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "nyc-taxi-analytics-g12"
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-east1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-east1-b"
}

# GCS Configuration
variable "gcs_bucket_name" {
  description = "GCS bucket name for all data"
  type        = string
  default     = "nyc-taxi-data-bucket-g12"
}

# BigQuery Datasets
variable "bronze_dataset" {
  description = "BigQuery Bronze dataset name"
  type        = string
  default     = "nyc_taxi_bronze"
}

variable "silver_dataset" {
  description = "BigQuery Silver dataset name"
  type        = string
  default     = "nyc_taxi_silver"
}

variable "gold_dataset" {
  description = "BigQuery Gold dataset name"
  type        = string
  default     = "nyc_taxi_gold"
}

variable "ml_dataset" {
  description = "BigQuery ML dataset name"
  type        = string
  default     = "nyc_taxi_ml"
}

# Service Account
variable "service_account_name" {
  description = "Service account name"
  type        = string
  default     = "nyc-taxi-pipeline-sa"
}

# Environment Tags
variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "NYC Taxi Analytics"
}
