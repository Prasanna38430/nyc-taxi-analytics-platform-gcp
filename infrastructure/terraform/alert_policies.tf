# Alert Policies for NYC Taxi Pipeline
# These alerts monitor custom log-based metrics from Cloud Logging

# Note: Some alerts use custom metrics that may take up to 10 minutes to be available
# You can monitor metric availability at: https://console.cloud.google.com/monitoring/metrics

# Alert 1: ETL Duration Exceeded (job running longer than 2 hours)
resource "google_monitoring_alert_policy" "etl_duration_alert" {
  display_name = "WARNING: ETL Job Running Longer Than 2 Hours"
  combiner     = "OR"

  conditions {
    display_name = "ETL duration > 120 minutes"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/etl_duration_minutes\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 120

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.teams_webhook.id
  ]

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert 2: High Error Rate (errors exceed 5%)
resource "google_monitoring_alert_policy" "error_rate_alert" {
  display_name = "ALERT: Pipeline Error Rate Exceeds 5%"
  combiner     = "OR"

  conditions {
    display_name = "Error rate > 5%"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/error_rate\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.teams_webhook.id
  ]

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert 3: GCS Storage Usage (> 500 GB)
resource "google_monitoring_alert_policy" "gcs_storage_alert" {
  display_name = "WARNING: GCS Bucket Storage Exceeds 500 GB"
  combiner     = "OR"

  conditions {
    display_name = "Bucket size > 500 GB"

    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 536870912000  # 500 GB in bytes

      aggregations {
        alignment_period  = "3600s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.teams_webhook.id
  ]

  alert_strategy {
    auto_close = "7200s"
  }
}

# Note: The following alert policies use custom metrics that are not yet available
# They will be activated once metrics are available and collecting data:
# - data_freshness_alert (data_freshness_hours metric)
# - spark_job_failures (spark_job_failures metric)
# - bq_load_failures (bq_load_failures metric)
# - data_quality_failures (data_quality_checks_passed metric)
#
# After 10 minutes, uncomment these policies and run:
# terraform plan -out=tfplan_phase10 && terraform apply tfplan_phase10
