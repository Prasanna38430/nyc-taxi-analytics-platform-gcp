# Cloud Monitoring Dashboard for NYC Taxi Pipeline

resource "google_monitoring_dashboard" "pipeline_dashboard" {
  dashboard_json = jsonencode({
    displayName = "NYC Taxi Analytics - Pipeline Dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        # Row 1: Pipeline Status
        {
          width  = 3
          height = 2
          widget = {
            title = "Total Dataproc Jobs"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"dataproc_cluster\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 3
          width  = 3
          height = 2
          widget = {
            title = "Failed Jobs"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/spark_failures\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 3
          height = 2
          widget = {
            title = "BigQuery Errors"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/job/num_failed_jobs\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 9
          width  = 3
          height = 2
          widget = {
            title = "Data Freshness (Hours)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/data_freshness_hours\""
                  }
                }
              }]
            }
          }
        },

        # Row 2: Resource Utilization
        {
          yPos   = 2
          width  = 6
          height = 2
          widget = {
            title = "Dataproc Cluster CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.label.instance_group_name=~\".*dataproc.*\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 2
          width  = 6
          height = 2
          widget = {
            title = "Dataproc Cluster Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/memory/usage\" AND resource.label.instance_group_name=~\".*dataproc.*\""
                  }
                }
              }]
            }
          }
        },

        # Row 3: BigQuery Metrics
        {
          yPos   = 4
          width  = 6
          height = 2
          widget = {
            title = "BigQuery Job Execution Time (seconds)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/job/elapsed_time\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 2
          widget = {
            title = "BigQuery Data Scanned (GB)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/job/num_bytes_scanned\""
                  }
                }
              }]
            }
          }
        },

        # Row 4: ETL Pipeline Metrics
        {
          yPos   = 6
          width  = 4
          height = 2
          widget = {
            title = "Rows Processed"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/rows_processed\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 4
          yPos   = 6
          width  = 4
          height = 2
          widget = {
            title = "ETL Duration (minutes)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/etl_duration_minutes\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 8
          yPos   = 6
          width  = 4
          height = 2
          widget = {
            title = "Error Rate (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/error_rate\""
                  }
                }
              }]
            }
          }
        },

        # Row 5: Cloud Function Metrics
        {
          yPos   = 8
          width  = 6
          height = 2
          widget = {
            title = "Cloud Function Invocations"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/invocations\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 2
          widget = {
            title = "Cloud Function Errors"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/errors\""
                  }
                }
              }]
            }
          }
        },

        # Row 6: Storage Metrics
        {
          yPos   = 10
          width  = 6
          height = 2
          widget = {
            title = "GCS Bucket Size (GB)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 10
          width  = 6
          height = 2
          widget = {
            title = "GCS Object Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gcs_bucket\" AND metric.type=\"storage.googleapis.com/storage/object_count\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
