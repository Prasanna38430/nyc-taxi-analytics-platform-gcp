# Alert Policies for NYC Taxi Pipeline
# These alerts monitor custom log-based metrics from Cloud Logging

# Alert 1: Data Freshness Exceeded (data older than 24 hours)
resource "google_monitoring_alert_policy" "data_freshness_alert" {
  display_name = "ALERT: Data Not Updated for 24+ Hours"
  combiner     = "OR"

  conditions {
    display_name = "Data freshness exceeded 24 hours"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/data_freshness_hours\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 24

      aggregations {
        alignment_period  = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.teams_webhook.id
  ]

  alert_strategy {
    auto_close = "3600s"
  }
}

# Alert 2: ETL Duration Exceeded (job running longer than 2 hours)
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

# Alert 3: High Error Rate (errors exceed 5%)
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

# Alert 4: Spark Job Failures
resource "google_monitoring_alert_policy" "spark_job_failures" {
  display_name = "ALERT: Spark Job Failures Detected"
  combiner     = "OR"

  conditions {
    display_name = "Spark job failures > 0"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/spark_job_failures\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_RATE"
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

# Alert 5: BigQuery Load Failures
resource "google_monitoring_alert_policy" "bq_load_failures" {
  display_name = "ALERT: BigQuery Load Failures Detected"
  combiner     = "OR"

  conditions {
    display_name = "BigQuery load failures > 0"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/bq_load_failures\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_RATE"
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

# Alert 6: Data Quality Check Failures
resource "google_monitoring_alert_policy" "data_quality_failures" {
  display_name = "WARNING: Data Quality Checks Failing"
  combiner     = "OR"

  conditions {
    display_name = "Data quality checks passed < expected"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/data_quality_checks_passed\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 100

      aggregations {
        alignment_period  = "300s"
        per_series_aligner = "ALIGN_MIN"
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id,
    google_monitoring_notification_channel.teams_webhook.id
  ]

  alert_strategy {
    auto_close = "3600s"
  }
}

# Alert 7: GCS Storage Usage (> 500 GB)
resource "google_monitoring_alert_policy" "gcs_storage_alert" {
  display_name = "WARNING: GCS Bucket Storage Exceeds 500 GB"
  combiner     = "OR"

  conditions {
    display_name = "Bucket size > 500 GB"

    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\" AND resource.label.bucket_name=\"nyc-taxi-data-bucket-g12\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
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
