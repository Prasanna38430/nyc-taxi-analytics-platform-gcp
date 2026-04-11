# Metric-based threshold alerts
# Note: These alerts are disabled until their corresponding metrics are available

# DISABLED: Alert 11 - Success Rate Drop Below 95%
# Requires: logging.googleapis.com/user/pipeline_success_count metric
# To enable: uncomment and run terraform plan
#
# resource "google_monitoring_alert_policy" "low_success_rate" {
#   display_name = "ALERT: Pipeline Success Rate Below 95%"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "Pipeline success rate < 95%"
#
#     condition_threshold {
#       filter = join(" AND ", [
#         "metric.type=\"logging.googleapis.com/user/pipeline_success_count\"",
#         "resource.type=\"global\""
#       ])
#
#       duration   = "600s"
#       comparison = "COMPARISON_LT"
#
#       threshold_value = 0.95
#
#       aggregations {
#         alignment_period  = "60s"
#         per_series_aligner = "ALIGN_PERCENT_CHANGE"
#       }
#     }
#   }
#
#   notification_channels = [
#     google_monitoring_notification_channel.email.id,
#     google_monitoring_notification_channel.teams_webhook.id
#   ]
#
#   alert_strategy {
#     auto_close = "1800s"
#   }
# }

# DISABLED: Alert 12 - Data Quality Issues Detected
# Requires: logging.googleapis.com/user/data_quality_issues metric
# To enable: uncomment and run terraform plan
#
# resource "google_monitoring_alert_policy" "data_quality_issues" {
#   display_name = "ALERT: Data Quality Issues Detected"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "Data quality deterioration"
#
#     condition_threshold {
#       filter = join(" AND ", [
#         "metric.type=\"logging.googleapis.com/user/data_quality_issues\"",
#         "resource.type=\"global\""
#       ])
#
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0
#
#       aggregations {
#         alignment_period  = "60s"
#         per_series_aligner = "ALIGN_DELTA"
#       }
#     }
#   }
#
#   notification_channels = [
#     google_monitoring_notification_channel.email.id,
#     google_monitoring_notification_channel.teams_webhook.id
#   ]
#
#   alert_strategy {
#     auto_close = "1800s"
#   }
# }

# DISABLED: Alert 13 - API Response Time Degradation
# Requires: logging.googleapis.com/user/api_response_time_ms metric
# Invalid resource type: "api" (should be "global" or specific endpoint)
# To enable: update filter and uncomment
#
# resource "google_monitoring_alert_policy" "api_response_time_degraded" {
#   display_name = "WARNING: API Response Time Degraded (> 5 seconds)"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "API response time > 5000ms"
#
#     condition_threshold {
#       filter = join(" AND ", [
#         "metric.type=\"logging.googleapis.com/user/api_response_time_ms\"",
#         "resource.type=\"global\""
#       ])
#
#       duration        = "300s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 5000
#
#       aggregations {
#         alignment_period  = "60s"
#         per_series_aligner = "ALIGN_MEAN"
#       }
#     }
#   }
#
#   notification_channels = [
#     google_monitoring_notification_channel.email.id,
#     google_monitoring_notification_channel.teams_webhook.id
#   ]
#
#   alert_strategy {
#     auto_close = "1800s"
#   }
# }

# DISABLED: Alert 14 - Low Processing Rate
# Requires: logging.googleapis.com/user/etl_processing_rate metric
# Invalid resource type: "dataproc_cluster" (should be "global")
# To enable: update filter and uncomment
#
# resource "google_monitoring_alert_policy" "low_processing_rate" {
#   display_name = "WARNING: ETL Processing Rate Below Threshold"
#   combiner     = "OR"
#
#   conditions {
#     display_name = "Processing rate < 1000 rows/min"
#
#     condition_threshold {
#       filter = join(" AND ", [
#         "metric.type=\"logging.googleapis.com/user/etl_processing_rate\"",
#         "resource.type=\"global\""
#       ])
#
#       duration        = "600s"
#       comparison      = "COMPARISON_LT"
#       threshold_value = 1000
#
#       aggregations {
#         alignment_period  = "60s"
#         per_series_aligner = "ALIGN_MEAN"
#       }
#     }
#   }
#
#   notification_channels = [
#     google_monitoring_notification_channel.email.id,
#     google_monitoring_notification_channel.teams_webhook.id
#   ]
#
#   alert_strategy {
#     auto_close = "3600s"
#   }
# }
