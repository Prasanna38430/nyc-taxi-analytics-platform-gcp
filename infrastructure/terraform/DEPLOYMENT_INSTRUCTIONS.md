# Phase 10: Deployment Instructions (Console & CLI)

Complete step-by-step guide for deploying monitoring and alerts using **GCP Console** or **gcloud CLI**.

---

## OPTION 1: DEPLOY USING CLI (Recommended)

### Prerequisites

1. **Terraform installed** (v1.0+)
   ```bash
   terraform --version
   ```

2. **gcloud CLI installed and authenticated**
   ```bash
   gcloud auth application-default login
   gcloud config list
   ```

3. **Go to Terraform directory**
   ```bash
   cd c:\Users\Admin\OneDrive\Desktop\SEM_2\Big_Data\nyc-taxi-analytics-platform-gcp\infrastructure\terraform
   ```

---

### Step 1: Initialize Terraform

```bash
terraform init
```

**Output:**
```
Initializing the backend...
Initializing modules...
Initializing provider plugins...
...
Terraform has been successfully configured!
```

---

### Step 2: Review Plan

```bash
terraform plan -out=tfplan_phase10
```

**Output shows:**
- Notification channels (email, Teams webhook)
- Alert policies (14 total)
- Custom metrics (12 total)
- Monitoring dashboard

**Example output:**
```
Plan: 28 to add, 0 to change, 0 to destroy.
Saved to: tfplan_phase10
```

---

### Step 3: Deploy Phase 10

```bash
terraform apply tfplan_phase10
```

**Output:**
```
google_monitoring_notification_channel.email: Creating...
google_monitoring_notification_channel.teams_webhook: Creating...
google_monitoring_alert_policy.dataproc_creation_failure: Creating...
...
Apply complete! Resources created: 28
```

**This creates:**
- [OK] 2 notification channels (email + Teams)
- [OK] 14 alert policies
- [OK] 7 custom metrics
- [OK] 1 monitoring dashboard

---

### Step 4: Verify Deployment

#### List Notification Channels
```bash
gcloud alpha monitoring channels list
```

**Output:**
```
NAME: projects/nyc-taxi-analytics-g12/notificationChannels/123456789
DISPLAY_NAME: NYC Taxi Pipeline - Email Notifications
TYPE: email

NAME: projects/nyc-taxi-analytics-g12/notificationChannels/987654321
DISPLAY_NAME: NYC Taxi Pipeline - Teams Webhook
TYPE: webhook_basic
```

#### List Alert Policies
```bash
gcloud alpha monitoring policies list
```

**Output:**
```
NAME: projects/nyc-taxi-analytics-g12/alertPolicies/1
DISPLAY_NAME: ALERT: Dataproc Cluster Creation Failed

NAME: projects/nyc-taxi-analytics-g12/alertPolicies/2
DISPLAY_NAME: ALERT: Spark Job Failed

... (14 total)
```

#### View Dashboard
```bash
gcloud monitoring dashboards list
```

**Output:**
```
NAME: projects/nyc-taxi-analytics-g12/dashboards/abc123def456
DISPLAY_NAME: NYC Taxi Analytics - Pipeline Dashboard
```

---

### Step 5: Access Monitoring Console

Open GCP Console:
```
https://console.cloud.google.com/monitoring/dashboards
```

1. Select project: `nyc-taxi-analytics-g12`
2. Click **Dashboards**
3. Click **NYC Taxi Analytics - Pipeline Dashboard**
4. View real-time metrics

---

## OPTION 2: DEPLOY USING GCP CONSOLE

If you prefer GUI instead of CLI:

### Step 1: Create Notification Channel (Email)

1. Open [Cloud Monitoring](https://console.cloud.google.com/monitoring)
2. Click **Alerting** → **Notification Channels**
3. Click **Create Channel**
4. Select **Email**
5. Enter email: `prasannakumaradabala20@gmail.com`
6. Click **Create**

### Step 2: Create Notification Channel (MS Teams)

1. In **Notification Channels**, click **Create Channel**
2. Select **Webhooks, generic**
3. Name: `NYC Taxi Pipeline - Teams Webhook`
4. URL: `https://epitafr.webhook.office.com/webhookb2/74a8ef7d-9051-4d8a-a467-9d35266e278c@3534b3d7-316c-4bc9-9ede-605c860f49d2/IncomingWebhook/4914e7ff558e44c49cd5c891dd942be0/5901e7ec-ed9d-4b7a-8f38-03530b1dfe0a/V2FLXD8kbqWhuGpI9kwmUgZMQUFIe7aadL3z5_VYMCKqY1`
5. Click **Create**

### Step 3: Create Alert Policy (Spark Job Failure)

1. Click **Alerting** → **Policies**
2. Click **Create Policy**
3. Configure condition:
   - **Resource:** Dataproc Cluster
   - **Metric:** Job Status
   - **Condition:** Equals "FAILED"
4. Click **Continue**
5. Select notification channels: Email + Teams
6. Name: `ALERT: Spark Job Failed`
7. Click **Create**

### Step 4: Create More Alert Policies

Repeat Step 3 for each alert:
- Dataproc Cluster Creation Failed
- BigQuery Job Failed
- Cloud Function Failed
- Data Not Updated for 24 Hours
- High CPU Usage
- High Memory Usage
- ETL Duration Exceeded
- Error Rate High
- Storage Limit Exceeded
- (etc. - 14 total)

### Step 5: Create Monitoring Dashboard

1. Click **Dashboards** → **Create Dashboard**
2. Name: `NYC Taxi Analytics - Pipeline Dashboard`
3. Add widgets:
   - Dataproc CPU usage (line chart)
   - BigQuery query time (bar chart)
   - ETL success rate (gauge)
   - Error rate (metric card)
4. Click **Save**

---

## MANUAL CLI COMMANDS (Alternative to Terraform)

If you prefer creating resources individually without Terraform:

### Create Email Notification Channel

```bash
gcloud alpha monitoring channels create \
  --display-name="NYC Taxi Pipeline - Email" \
  --type=email \
  --channel-labels=email_address=prasannakumaradabala20@gmail.com
```

### Create Teams Webhook Channel

```bash
gcloud alpha monitoring channels create \
  --display-name="NYC Taxi Pipeline - Teams Webhook" \
  --type=webhook_basic \
  --channel-labels=url='https://epitafr.webhook.office.com/...'
```

### Create Alert Policy (JSON)

Create `alert_policy.json`:
```json
{
  "displayName": "ALERT: Spark Job Failed",
  "conditions": [{
    "displayName": "Spark job execution failed",
    "conditionThreshold": {
      "filter": "resource.type=\"dataproc_cluster\" AND protoPayload.status.code=500",
      "comparison": "COMPARISON_GT",
      "thresholdValue": 0,
      "duration": "300s",
      "aggregations": [{
        "alignmentPeriod": "60s",
        "perSeriesAligner": "ALIGN_RATE"
      }]
    }
  }],
  "notificationChannels": [
    "projects/nyc-taxi-analytics-g12/notificationChannels/EMAIL_CHANNEL_ID",
    "projects/nyc-taxi-analytics-g12/notificationChannels/TEAMS_CHANNEL_ID"
  ]
}
```

Deploy:
```bash
gcloud alpha monitoring policies create --policy-from-file=alert_policy.json
```

---

## VERIFICATION CHECKLIST

After deployment, verify everything works:

### [OK] Notification Channels
```bash
# Should show 2 channels
gcloud alpha monitoring channels list | grep "NYC Taxi"
```

### [OK] Alert Policies
```bash
# Should show 14 policies
gcloud alpha monitoring policies list | grep "NYC Taxi"
```

### [OK] Custom Metrics
```bash
# Check if custom metrics exist (may take 5 minutes)
gcloud logging metrics list | grep "rows_processed\|etl_duration"
```

### [OK] Dashboard
```bash
# Should show dashboard
gcloud monitoring dashboards list | grep "Pipeline Dashboard"
```

### [OK] Email Notification

You should receive a **verification email** from Google Cloud.

**Action:** Click link to verify email address

### [OK] MS Teams Webhook

Test by manually triggering a log entry:
```bash
gcloud logging write nyc-taxi-logs "TEST: Monitoring setup complete" \
  --severity=INFO
```

Check your Teams channel for message.

---

## TESTING ALERTS

### Test Spark Job Failure Alert

Manually create a failure log:
```bash
gcloud logging write nyc-taxi-logs \
  '{"status":"FAILED","job_id":"test-job-001"}' \
  --severity=ERROR \
  --resource=dataproc_cluster
```

**Expected:** Receive email & Teams message within 5 minutes

### Test High CPU Alert

```bash
gcloud logging write nyc-taxi-logs \
  '{"cpu_usage":0.85}' \
  --severity=WARNING \
  --resource=gce_instance
```

**Expected:** Warning alert triggered

### Test Data Freshness Alert

```bash
gcloud logging write nyc-taxi-logs \
  '{"freshness_hours":25,"table":"fact_trips"}' \
  --severity=WARNING
```

**Expected:** Data freshness alert triggered

---

## CONSOLE ACCESS

### View Monitoring Dashboard
```
https://console.cloud.google.com/monitoring/dashboards
→ NYC Taxi Analytics - Pipeline Dashboard
```

### View Alert Policies
```
https://console.cloud.google.com/monitoring/alerting/policies
→ Filter: "NYC Taxi"
```

### View Notification Channels
```
https://console.cloud.google.com/monitoring/alerting/notificationchannels
→ NYC Taxi Pipeline channels
```

### View Logs
```
https://console.cloud.google.com/logs/query
→ resource.type="dataproc_cluster" AND severity="ERROR"
```

---

## TROUBLESHOOTING

### Problem: "Insufficient permissions"

**Solution:**
```bash
gcloud projects add-iam-policy-binding nyc-taxi-analytics-g12 \
  --member=user:YOUR_EMAIL \
  --role=roles/monitoring.admin
```

### Problem: Alerts not triggering

**Check:**
1. Notification channels verified?
   ```bash
   gcloud alpha monitoring channels list
   ```

2. Log entries matching filter?
   ```bash
   gcloud logging read "resource.type=dataproc_cluster" --limit=10
   ```

3. Alert policy enabled?
   ```bash
   gcloud alpha monitoring policies describe POLICY_ID
   ```

### Problem: Custom metrics not showing

**Note:** Custom metrics take 5-10 minutes to appear.

**Check metrics created:**
```bash
gcloud logging metrics list | grep "rows_processed"
```

**If missing:**
```bash
terraform apply -target=google_logging_metric.rows_processed
```

---

## CLEANUP (If Needed)

### Destroy Phase 10 Resources

```bash
terraform destroy
```

**Confirm by typing: `yes`**

### Keep Specific Resources

```bash
# Keep email notification channel
terraform destroy -target=google_monitoring_alert_policy.dataproc_creation_failure
```

---

## COST ESTIMATION

**Monthly Cost After Phase 10:**

| Component | Cost |
|-----------|------|
| Cloud Logging (first 50 GB free) | $0 |
| Basic metrics | $0 |
| Alert policies (first 5 free) | $0 |
| Custom metrics (12 × $0.25) | ~$3 |
| Notifications | $0 |
| **Total** | **~$3/month** |

---

## NEXT STEPS

1. [OK] Verify all alerts are working
2. [OK] Run Phase 6 (orchestration) to test monitoring
3. [OK] Check alerts in email + Teams during execution
4. [OK] Move to Phase 11 (Testing & CI/CD)

---

## REFERENCE COMMANDS

### Quick Verification
```bash
# Check all Phase 10 resources
terraform state list | grep monitoring
terraform state list | grep alert
terraform state list | grep notification
```

### Export Configuration
```bash
# Export current monitoring config
gcloud monitoring policies list --format=json > alert_policies_backup.json

# Export dashboards
gcloud monitoring dashboards list --format=json > dashboards_backup.json
```

### Monitor in Real-time
```bash
# Watch logs in real-time
gcloud logging read \
  --limit 100 \
  --follow \
  --format json | jq '.message'
```

---

**Created:** April 11, 2026
**Project:** NYC Taxi Analytics
**Deployment Time:** ~5 minutes (CLI) | ~30 minutes (Console)
