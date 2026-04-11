# Custom metrics for ETL pipeline tracking

# Custom metric: Rows processed
resource "google_logging_metric" "rows_processed" {
  name   = "rows_processed"
  filter = "resource.type=\"dataproc_cluster\" AND jsonPayload.rows_processed=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "By"

    labels {
      key         = "cluster_name"
      value_type  = "STRING"
      description = "Dataproc cluster name"
    }

    labels {
      key         = "job_id"
      value_type  = "STRING"
      description = "Spark job ID"
    }
  }

  label_extractors = {
    "cluster_name" = "EXTRACT(resource.labels.cluster_name)"
    "job_id"       = "EXTRACT(jsonPayload.job_id)"
  }
}

# Custom metric: ETL duration (minutes)
resource "google_logging_metric" "etl_duration_minutes" {
  name   = "etl_duration_minutes"
  filter = "resource.type=\"dataproc_cluster\" AND jsonPayload.duration_minutes=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "min"

    labels {
      key         = "stage"
      value_type  = "STRING"
      description = "ETL stage (bronze_to_silver, silver_to_gold)"
    }

    labels {
      key         = "status"
      value_type  = "STRING"
      description = "Success or failure"
    }
  }

  label_extractors = {
    "stage"  = "EXTRACT(jsonPayload.stage)"
    "status" = "EXTRACT(jsonPayload.status)"
  }
}

# Custom metric: Data freshness (hours since last update)
resource "google_logging_metric" "data_freshness_hours" {
  name   = "data_freshness_hours"
  filter = "resource.type=\"bigquery_project\" AND jsonPayload.freshness_hours=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "h"

    labels {
      key         = "dataset"
      value_type  = "STRING"
      description = "BigQuery dataset"
    }

    labels {
      key         = "table"
      value_type  = "STRING"
      description = "BigQuery table"
    }
  }

  label_extractors = {
    "dataset" = "EXTRACT(jsonPayload.dataset)"
    "table"   = "EXTRACT(jsonPayload.table)"
  }
}

# Custom metric: Error rate (percentage)
resource "google_logging_metric" "error_rate" {
  name   = "error_rate"
  filter = "severity=\"ERROR\" AND (resource.type=\"cloud_function\" OR resource.type=\"dataproc_cluster\" OR resource.type=\"bigquery_project\")"

  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "DOUBLE"
    unit        = "%"

    labels {
      key         = "service"
      value_type  = "STRING"
      description = "Service name (function, dataproc, bigquery)"
    }

    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Type of error"
    }
  }

  label_extractors = {
    "service"    = "EXTRACT(resource.type)"
    "error_type" = "EXTRACT(jsonPayload.error_type)"
  }
}

# Custom metric: Dataproc cluster creation failures
resource "google_logging_metric" "dataproc_creation_failed" {
  name   = "dataproc_creation_failed"
  filter = "resource.type=\"dataproc_cluster\" AND (jsonPayload.error_code=~\".*CREATION.*\" OR severity=\"ERROR\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "cluster_name"
      value_type  = "STRING"
      description = "Cluster name"
    }

    labels {
      key         = "error_reason"
      value_type  = "STRING"
      description = "Reason for failure"
    }
  }

  label_extractors = {
    "cluster_name" = "EXTRACT(resource.labels.cluster_name)"
    "error_reason" = "EXTRACT(jsonPayload.error_reason)"
  }
}

# Custom metric: BigQuery data scanned (GB)
resource "google_logging_metric" "bigquery_data_scanned_gb" {
  name   = "bigquery_data_scanned_gb"
  filter = "resource.type=\"bigquery_project\" AND jsonPayload.bytes_scanned=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DOUBLE"
    unit        = "GB"

    labels {
      key         = "dataset"
      value_type  = "STRING"
      description = "Dataset name"
    }

    labels {
      key         = "query_type"
      value_type  = "STRING"
      description = "Query type (SELECT, INSERT, etc)"
    }
  }

  label_extractors = {
    "dataset"    = "EXTRACT(resource.labels.dataset_id)"
    "query_type" = "EXTRACT(jsonPayload.query_type)"
  }
}
