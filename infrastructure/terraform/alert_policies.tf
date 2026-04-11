# Critical Alert Policies for NYC Taxi Pipeline

# Alert 1: Dataproc Cluster Creation Failure
resource "google_monitoring_alert_policy" "dataproc_creation_failure" {
  display_name = "ALERT: Dataproc Cluster Creation Failed"
  combiner     = "OR"

  conditions {
    display_name = "Dataproc cluster creation errors"

    condition_threshold {
      filter          = "resource.type=\"dataproc_cluster\" AND metric.type=\"logging.googleapis.com/user/dataproc_creation_failed\""
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

# Alert 2: Spark Job Failure
resource "google_monitoring_alert_policy" "spark_job_failure" {
  display_name = "ALERT: Spark Job Failed"
  combiner     = "OR"

  conditions {
    display_name = "Spark job execution failed"

    condition_threshold {
      filter          = "resource.type=\"dataproc_cluster\" AND protoPayload.status.code=500"
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

# Alert 3: BigQuery Job Failure
resource "google_monitoring_alert_policy" "bigquery_job_failure" {
  display_name = "ALERT: BigQuery Job Failed"
  combiner     = "OR"

  conditions {
    display_name = "BigQuery job errors"

    condition_threshold {
      filter          = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/job/num_failed_jobs\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_DELTA"
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

# Alert 4: Cloud Function Failure
resource "google_monitoring_alert_policy" "cloud_function_failure" {
  display_name = "ALERT: Cloud Function Failed"
  combiner     = "OR"

  conditions {
    display_name = "Cloud function execution errors"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/errors\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_DELTA"
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

# Alert 5: Data Not Updated for 24 Hours
resource "google_monitoring_alert_policy" "data_freshness" {
  display_name = "ALERT: Data Not Updated for 24 Hours"
  combiner     = "OR"

  conditions {
    display_name = "Data freshness check"

    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/data_freshness_hours\""
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

# Alert 6: High CPU Usage (Dataproc)
resource "google_monitoring_alert_policy" "high_cpu_usage" {
  display_name = "WARNING: High CPU Usage on Dataproc Cluster"
  combiner     = "OR"

  conditions {
    display_name = "Dataproc CPU usage > 80%"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_group_name=~\".*dataproc.*\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

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

# Alert 7: High Memory Usage (Dataproc)
resource "google_monitoring_alert_policy" "high_memory_usage" {
  display_name = "WARNING: High Memory Usage on Dataproc Cluster"
  combiner     = "OR"

  conditions {
    display_name = "Dataproc memory usage > 85%"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/memory/percent_used\" AND resource.label.instance_group_name=~\".*dataproc.*\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 85

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

# Alert 8: ETL Job Taking Too Long (> 1 hour)
resource "google_monitoring_alert_policy" "etl_duration_exceeded" {
  display_name = "WARNING: ETL Job Running Longer Than 1 Hour"
  combiner     = "OR"

  conditions {
    display_name = "ETL duration > 60 minutes"

    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/etl_duration_minutes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 60

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
    auto_close = "3600s"
  }
}

# Alert 9: High Error Rate (> 5%)
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "ALERT: Error Rate Exceeds 5%"
  combiner     = "OR"

  conditions {
    display_name = "Pipeline error rate > 5%"

    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/error_rate\""
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

# Alert 10: GCS Bucket Storage Threshold (> 100 GB)
resource "google_monitoring_alert_policy" "storage_threshold" {
  display_name = "WARNING: GCS Bucket Exceeds 100 GB"
  combiner     = "OR"

  conditions {
    display_name = "Bucket size > 100 GB"

    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\" AND resource.label.bucket_name=\"nyc-taxi-data-bucket-g12\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 107374182400 # 100 GB in bytes

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
