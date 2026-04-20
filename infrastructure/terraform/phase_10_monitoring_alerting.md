# Phase 10: Cloud Monitoring & Alerting - Complete Guide

## Overview

Comprehensive monitoring and alerting system for NYC Taxi Analytics pipeline. Automatically detects failures, performance degradation, and data quality issues across:
- [OK] Dataproc clusters (Spark jobs)
- [OK] BigQuery transformations
- [OK] Cloud Functions (event triggers)
- [OK] GCS storage operations
- [OK] Custom ETL metrics

**Alert Destinations:**
- Email: prasannakumaradabala20@gmail.com
- MS Teams: Webhook integration

---

## Architecture

```
GCP Infrastructure
    ↓
Cloud Logging (auto-collects all events)
    ├─ Dataproc cluster logs
    ├─ BigQuery job logs
    ├─ Cloud Function logs
    ├─ GCS operation logs
    └─ Custom application logs
    ↓
Cloud Monitoring (processes logs)
    ├─ Log-based metrics extraction
    ├─ Custom metrics calculation
    └─ Threshold evaluation
    ↓
Alert Policies (evaluates conditions)
    ├─ Critical alerts (failures)
    ├─ Warning alerts (performance)
    └─ Info alerts (milestones)
    ↓
Notification Channels
    ├─ Email notifications
    └─ MS Teams webhooks
    ↓
Monitoring Dashboard
    └─ Real-time visualization
```

---

## What Gets Monitored

### 1. Pipeline Failures (Critical)
| Failure Type | Alert | Threshold |
|--------------|-------|-----------|
| Dataproc cluster creation fails | CRITICAL | Any failure |
| Spark job fails | CRITICAL | Any failure |
| BigQuery job fails | CRITICAL | Any failure |
| Cloud Function error | CRITICAL | Any error |

### 2. Data Quality (Critical)
| Issue | Alert | Threshold |
|-------|-------|-----------|
| Data not updated | CRITICAL | > 24 hours |
| Success rate drops | ALERT | < 95% |
| Data quality issues | ALERT | Any detected |

### 3. Performance (Warning)
| Metric | Alert | Threshold |
|--------|-------|-----------|
| CPU usage high | WARNING | > 80% |
| Memory usage high | WARNING | > 85% |
| ETL takes too long | WARNING | > 60 minutes |
| API slow | WARNING | > 5 seconds |
| Processing rate low | WARNING | < 1000 rows/min |

### 4. Resources (Warning)
| Metric | Alert | Threshold |
|--------|-------|-----------|
| Storage exceeds limit | WARNING | > 100 GB |
| Error rate high | WARNING | > 5% |

---

## Alerts Summary

### 14 Total Alert Policies

**Critical (Failures):**
1. Dataproc Cluster Creation Failed
2. Spark Job Failed
3. BigQuery Job Failed
4. Cloud Function Failed

**Data Quality:**
5. Data Not Updated for 24 Hours
6. Pipeline Success Rate Below 95%
7. Data Quality Issues Detected

**Performance Warnings:**
8. High CPU Usage (> 80%)
9. High Memory Usage (> 85%)
10. ETL Duration Exceeded (> 60 min)
11. API Response Time Degraded (> 5 sec)
12. Low Processing Rate (< 1000 rows/min)

**Resource Warnings:**
13. GCS Bucket Exceeds 100 GB
14. High Error Rate (> 5%)

---

## Custom Metrics Extracted

From Cloud Logging, these metrics are automatically extracted:

| Metric | Type | Unit | Use Case |
|--------|------|------|----------|
| `rows_processed` | DELTA | count | Track ETL throughput |
| `etl_duration_minutes` | GAUGE | minutes | Monitor job duration |
| `data_freshness_hours` | GAUGE | hours | Check data currency |
| `error_rate` | GAUGE | % | Monitor reliability |
| `dataproc_creation_failed` | DELTA | count | Track infrastructure |
| `bigquery_data_scanned_gb` | DELTA | GB | Monitor costs |
| `pipeline_success_count` | DELTA | count | Success tracking |
| `pipeline_failure_count` | DELTA | count | Failure tracking |
| `etl_processing_rate` | GAUGE | rows/min | Performance tracking |
| `data_quality_issues` | DELTA | count | Quality monitoring |
| `api_response_time_ms` | GAUGE | ms | Performance monitoring |
| `warning_count` | DELTA | count | Issue tracking |

---

## Monitoring Dashboard

Real-time dashboard displays:

**Row 1: Pipeline Status (KPIs)**
- Total Dataproc Jobs
- Failed Jobs Count
- BigQuery Errors
- Data Freshness (hours)

**Row 2: Resource Utilization**
- Dataproc Cluster CPU Usage (%)
- Dataproc Cluster Memory Usage (%)

**Row 3: BigQuery Metrics**
- BigQuery Job Execution Time (seconds)
- BigQuery Data Scanned (GB)

**Row 4: ETL Pipeline Metrics**
- Rows Processed
- ETL Duration (minutes)
- Error Rate (%)

**Row 5: Cloud Function Metrics**
- Cloud Function Invocations
- Cloud Function Errors

**Row 6: Storage Metrics**
- GCS Bucket Size (GB)
- GCS Object Count

---

## Notification Channels

### Email Notifications
- **Recipient:** prasannakumaradabala20@gmail.com
- **Format:** HTML email with alert details
- **Triggers:** All alert policies

### MS Teams Notifications
- **Channel:** Via Incoming Webhook
- **Format:** Formatted card with severity, description, remediation
- **Triggers:** Critical and warning alerts

**Alert Message Example:**
```
[ALERT] CRITICAL: Spark Job Failed
Component: Dataproc Cluster
Timestamp: 2026-04-11 14:30:00
Details: Job execution failed with OutOfMemory error
Action: Check Dataproc cluster logs and increase memory if needed
```

---

## File Structure

```
infrastructure/terraform/
├── notification_channels.tf    # Email + Teams webhooks
├── monitoring_dashboard.tf     # Dashboard configuration
├── alert_policies.tf           # 10 critical/warning alerts
├── custom_metrics.tf           # 6 custom ETL metrics
├── log_based_metrics.tf        # 7 log-based metrics
├── metric_based_alerts.tf      # 4 threshold-based alerts
└── phase_10_monitoring_alerting.md
```

---

## How Alerts Are Triggered

### Example: Spark Job Failure

```
1. User/Phase 6 submits Spark job
   └─ gcloud dataproc jobs submit spark ...

2. Job fails (OutOfMemory, timeout, etc)
   └─ GCP logs error: "Job j-ABC123 FAILED"

3. Cloud Logging captures error
   └─ Log entry stored with severity=ERROR

4. Cloud Monitoring queries logs
   └─ Finds: resource.type="dataproc_cluster" AND severity="ERROR"

5. Alert policy "Spark Job Failed" matches
   └─ Threshold: > 0 errors
   └─ Duration: 5 minutes
   └─ Condition: MET

6. Notifications sent
   └─ Email to: prasannakumaradabala20@gmail.com
   └─ Teams webhook posts message
```

---

## Alert Response Examples

### When Dataproc Cluster Creation Fails
**Alert:** "ALERT: Dataproc Cluster Creation Failed"
**Action:**
1. Check Cloud Logging: `gcloud logging read "resource.type=dataproc_cluster AND severity=ERROR"`
2. Check quota: `gcloud compute project-info describe --project=PROJECT_ID`
3. Resolve: Increase quota, use different zone, reduce cluster size

### When Spark Job Fails
**Alert:** "ALERT: Spark Job Failed"
**Action:**
1. Check job logs: `gcloud dataproc jobs describe JOB_ID --cluster=CLUSTER_NAME`
2. Check Spark logs: View on Dataproc console
3. Resolve: Fix code, increase memory, check data format

### When Data Not Updated for 24 Hours
**Alert:** "ALERT: Data Not Updated for 24 Hours"
**Action:**
1. Check last ETL run: `bq query "SELECT MAX(etl_timestamp) FROM gold.fact_trips"`
2. Check Cloud Composer DAG status
3. Resolve: Manually trigger DAG or investigate Phase 6

### When Success Rate Below 95%
**Alert:** "ALERT: Pipeline Success Rate Below 95%"
**Action:**
1. Check recent job executions
2. Identify pattern (all dataproc? all bigquery?)
3. Investigate root cause

---

## Testing Alerts

### Trigger Email Alert (Manual)
```bash
# Write error log that matches alert condition
gcloud logging write nyc-taxi-logs "Spark job failed" \
  --severity=ERROR \
  --resource=dataproc_cluster
```

### Verify Alert Policy
```bash
gcloud alpha monitoring policies list \
  --filter="displayName:'Spark Job Failed'"
```

### Check Notification Channels
```bash
gcloud alpha monitoring channels list \
  --filter="displayName:'NYC Taxi Pipeline'"
```

---

## Customization

### Change Alert Thresholds

Edit alert policies:
```hcl
# In alert_policies.tf
threshold_value = 0.8  # Change CPU threshold from 80% to 70%
```

### Add New Metrics

Create custom metric in `custom_metrics.tf`:
```hcl
resource "google_logging_metric" "your_metric" {
  name   = "your_metric_name"
  filter = "your_log_filter"
  # ... metric details
}
```

### Add New Alert

Create alert in `alert_policies.tf`:
```hcl
resource "google_monitoring_alert_policy" "your_alert" {
  display_name = "YOUR ALERT NAME"
  # ... alert policy details
}
```

### Change Notification Channel

Edit `notification_channels.tf`:
```hcl
resource "google_monitoring_notification_channel" "new_channel" {
  display_name = "New Recipient"
  type         = "email"
  labels = {
    email_address = "new-email@example.com"
  }
}
```

---

## Monitoring Best Practices

[OK] **DO:**
- Review dashboard daily during pipeline runs
- Acknowledge alerts in Teams when received
- Track recurring alert patterns
- Update alert thresholds based on history
- Archive old notifications for audit
- Test alerts monthly

[NOT OK] **DON'T:**
- Ignore "WARNING" alerts (early sign of problems)
- Set thresholds too high (miss real issues)
- Leave notifications unchecked
- Delete alerts without understanding impact
- Increase alert frequency to "every minute" (alert fatigue)

---

## Troubleshooting

### Alerts Not Triggering

**Problem:** Set up alerts but not receiving notifications

**Check:**
1. Notification channels created: `gcloud alpha monitoring channels list`
2. Alert policies created: `gcloud alpha monitoring policies list`
3. Notification channel verified: Check GCP Console
4. Log entries exist: `gcloud logging read "resource.type=dataproc_cluster"`

**Fix:**
```bash
# Verify notification channel
gcloud alpha monitoring channels describe CHANNEL_ID

# Verify alert policy
gcloud alpha monitoring policies describe POLICY_ID

# Test notification manually
gcloud alpha monitoring policies delete POLICY_ID  # (unsafe - testing only)
```

### Too Many False Alerts

**Problem:** Alerts firing on non-critical events

**Solutions:**
1. Increase alert duration: `duration = "600s"` (10 min instead of 5 min)
2. Increase threshold: `threshold_value = 0.9` (90% instead of 80%)
3. Filter logs more specifically: Add more conditions to `filter`

### Alerts Not Appearing in Teams

**Problem:** Email alerts work but Teams webhook fails

**Check:**
1. Webhook URL correct: Verify in Teams channel
2. Teams webhook enabled: Check `enabled = true`
3. Message format valid: JSON structure correct

**Fix:**
```bash
# Re-create Teams notification channel with correct webhook
terraform destroy -target=google_monitoring_notification_channel.teams_webhook
terraform apply
```

---

## Monitoring Cost Implications

### What's Free
- [OK] Cloud Logging (first 50 GB/month)
- [OK] Basic metric ingestion
- [OK] Alert policies (up to 5 free)

### What Costs
- [NOT OK] Log analysis beyond 50 GB
- [NOT OK] Custom metrics (ingestion)
- [NOT OK] Advanced Monitoring features

**Estimated Monthly Cost:** $10-50 (depending on log volume)

---

## Integration with Phase 6 (Orchestration)

**How They Work Together:**

```
Phase 6: Cloud Composer DAG runs
    ↓
    Creates Dataproc cluster
    ↓
    Submits Spark job
    ↓
    ← Phase 10 monitors execution
    ↓
    Job succeeds or fails
    ↓
    ← Phase 10 sends alert if failed
    ↓
    Cluster deleted
```

**No DAG changes needed!** Phase 10 automatically monitors Phase 6 without code modifications.

---

## Next Steps

1. **Deploy Phase 10** (this section)
2. **Return to Phase 6** for orchestration testing
3. **Verify alerts** during Phase 6 execution
4. **Phase 11:** Testing & CI/CD

---

## Resources

- [Google Cloud Monitoring](https://cloud.google.com/stackdriver/docs)
- [Alert Policies](https://cloud.google.com/monitoring/alerts)
- [Log-based Metrics](https://cloud.google.com/logging/docs/logs-based-metrics)
- [Notification Channels](https://cloud.google.com/monitoring/support/notification-options)
- [Terraform Google Monitoring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy)

---

**Created:** April 11, 2026
**Project:** NYC Taxi Analytics - Group 12
**Status:** [OK] Complete - Ready for Deployment
