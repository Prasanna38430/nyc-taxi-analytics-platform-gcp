# Log-based metrics extracted from Cloud Logging

# Metric: Success count (from logs)
resource "google_logging_metric" "pipeline_success_count" {
  name   = "pipeline_success_count"
  filter = "jsonPayload.status=\"SUCCESS\" AND (resource.type=\"dataproc_cluster\" OR resource.type=\"bigquery_project\" OR resource.type=\"cloud_function\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "component"
      value_type  = "STRING"
      description = "Pipeline component"
    }

    labels {
      key         = "stage"
      value_type  = "STRING"
      description = "Pipeline stage"
    }
  }

  label_extractors = {
    "component" = "EXTRACT(resource.type)"
    "stage"     = "EXTRACT(jsonPayload.stage)"
  }
}

# Metric: Failure count (from logs)
resource "google_logging_metric" "pipeline_failure_count" {
  name   = "pipeline_failure_count"
  filter = "severity=\"ERROR\" AND (resource.type=\"dataproc_cluster\" OR resource.type=\"bigquery_project\" OR resource.type=\"cloud_function\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "component"
      value_type  = "STRING"
      description = "Component where failure occurred"
    }

    labels {
      key         = "error_category"
      value_type  = "STRING"
      description = "Error category"
    }
  }

  label_extractors = {
    "component"      = "EXTRACT(resource.type)"
    "error_category" = "EXTRACT(jsonPayload.error_category)"
  }
}

# Metric: ETL processing rate (rows per minute)
resource "google_logging_metric" "etl_processing_rate" {
  name   = "etl_processing_rate"
  filter = "resource.type=\"dataproc_cluster\" AND jsonPayload.rows_processed=~\"[0-9]+\" AND jsonPayload.processing_time_seconds=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "DOUBLE"
    unit        = "1/min"

    labels {
      key         = "job_id"
      value_type  = "STRING"
      description = "Spark job ID"
    }

    labels {
      key         = "stage"
      value_type  = "STRING"
      description = "Transformation stage"
    }
  }

  label_extractors = {
    "job_id" = "EXTRACT(jsonPayload.job_id)"
    "stage"  = "EXTRACT(jsonPayload.stage)"
  }
}

# Metric: Data quality issues (null values, duplicates, etc)
resource "google_logging_metric" "data_quality_issues" {
  name   = "data_quality_issues"
  filter = "resource.type=\"global\" AND (jsonPayload.null_count=~\"[0-9]+\" OR jsonPayload.duplicate_count=~\"[0-9]+\" OR jsonPayload.invalid_count=~\"[0-9]+\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "issue_type"
      value_type  = "STRING"
      description = "Type of data quality issue"
    }

    labels {
      key         = "table_name"
      value_type  = "STRING"
      description = "BigQuery table"
    }
  }

  label_extractors = {
    "issue_type"  = "EXTRACT(jsonPayload.issue_type)"
    "table_name"  = "EXTRACT(jsonPayload.table_name)"
  }
}

# Metric: API response time (milliseconds)
resource "google_logging_metric" "api_response_time_ms" {
  name   = "api_response_time_ms"
  filter = "resource.type=\"api\" AND jsonPayload.response_time_ms=~\"[0-9]+\""

  metric_descriptor {
    metric_kind = "GAUGE"
    value_type  = "INT64"
    unit        = "ms"

    labels {
      key         = "api_name"
      value_type  = "STRING"
      description = "API name (dataproc, bigquery, storage)"
    }

    labels {
      key         = "operation"
      value_type  = "STRING"
      description = "API operation"
    }
  }

  label_extractors = {
    "api_name" = "EXTRACT(jsonPayload.api_name)"
    "operation" = "EXTRACT(jsonPayload.operation)"
  }
}

# Metric: Warning count (non-critical issues)
resource "google_logging_metric" "warning_count" {
  name   = "warning_count"
  filter = "severity=\"WARNING\" AND (resource.type=\"dataproc_cluster\" OR resource.type=\"bigquery_project\" OR resource.type=\"cloud_function\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "component"
      value_type  = "STRING"
      description = "Component"
    }

    labels {
      key         = "warning_type"
      value_type  = "STRING"
      description = "Type of warning"
    }
  }

  label_extractors = {
    "component"    = "EXTRACT(resource.type)"
    "warning_type" = "EXTRACT(jsonPayload.warning_type)"
  }
}
