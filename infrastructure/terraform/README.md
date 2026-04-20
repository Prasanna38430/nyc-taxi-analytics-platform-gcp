# Phase 9: Infrastructure as Code - Terraform

## Overview
Terraform configuration for reproducible provisioning of NYC Taxi Analytics GCP infrastructure. This is a **documentation and reference blueprint** - NOT deployed on existing infrastructure (already working perfectly).

## Architecture

### What Gets Created

#### Storage (GCS)
```
gs://nyc-taxi-data-bucket-g12/
├── raw/taxi_trips/          ← CSV data input
├── composer/dags/           ← Airflow DAGs
├── scripts/spark/           ← PySpark ETL scripts
├── ml/artifacts/            ← ML output artifacts
├── ml/models/               ← Trained models
├── temp/spark_temp/         ← Temporary data
└── terraform/               ← Terraform state
```

#### Databases (BigQuery)
```
BRONZE LAYER (Raw Data)
└── nyc_taxi_bronze
    └── raw_trips (external table from GCS)

SILVER LAYER (Cleaned Data)
└── nyc_taxi_silver
    └── trips_enriched (1.4M rows, partitioned & clustered)

GOLD LAYER (Analytics Ready)
└── nyc_taxi_gold
    ├── FACT: fact_trips (partitioned, clustered)
    ├── DIMENSIONS:
    │   ├── dim_vendor
    │   ├── dim_datetime
    │   └── dim_location
    └── AGGREGATIONS:
        ├── agg_daily_summary
        ├── agg_hourly_patterns
        ├── agg_vendor_performance
        └── agg_location_hotspots

ML LAYER (Models & Features)
└── nyc_taxi_ml
    ├── training_features
    └── training_features_sample (5,000 rows)
```

#### Security (IAM)
- Service Account: `nyc-taxi-pipeline-sa@nyc-taxi-analytics-g12.iam.gserviceaccount.com`
- Assigned Roles (9 total):
  - `roles/bigquery.dataEditor` - Read/write BigQuery tables
  - `roles/bigquery.jobUser` - Submit BigQuery jobs
  - `roles/cloudfunctions.invoker` - Invoke Cloud Functions
  - `roles/composer.worker` - Execute Airflow tasks
  - `roles/dataproc.editor` - Manage Dataproc clusters
  - `roles/eventarc.eventReceiver` - Listen to GCS events
  - `roles/iam.serviceAccountUser` - Impersonate service account
  - `roles/storage.admin` - Full GCS access
  - `roles/workflows.invoker` - Trigger workflows

#### Networking
- Default VPC network (multi-region)
- Firewall rule: `allow-dataproc-internal` (TCP/UDP/ICMP)

#### APIs (25 enabled)
- BigQuery, BigQuery Data Transfer, BigQuery Storage
- Cloud Build, Cloud Functions, Cloud Composer
- Compute Engine, Cloud Dataproc, Eventarc
- IAM, Cloud Logging, Cloud Monitoring
- Cloud Run, Cloud Storage, Workflows
- Cloud Trace, Cloud Profiler, Error Reporting

#### Monitoring & Alerting (Phase 10)
- Notification channels: Email & MS Teams webhook
- 14 alert policies for critical failures, data quality, and performance
- 12 custom metrics for ETL pipeline tracking
- Cloud Monitoring dashboard with 12 tiles
- Automatic failure detection and alerting

---

## File Structure

```
infrastructure/terraform/
├── Core Infrastructure (Phase 9)
│   ├── providers.tf            # GCP provider setup
│   ├── variables.tf            # Input variables
│   ├── main.tf                 # Common locals
│   ├── storage.tf              # GCS bucket & folders
│   ├── bigquery.tf             # 4 datasets & 12 tables
│   ├── iam.tf                  # Service account & 9 roles
│   ├── firewall.tf             # Dataproc firewall rules
│   ├── apis.tf                 # 16 enabled APIs
│   ├── outputs.tf              # Output values
│   └── terraform.tfvars        # Variable values
├── Monitoring & Alerting (Phase 10)
│   ├── notification_channels.tf     # Email & Teams webhooks
│   ├── alert_policies.tf            # 14 alert policies
│   ├── custom_metrics.tf            # Custom metric definitions
│   ├── log_based_metrics.tf         # Log-based metrics
│   ├── metric_based_alerts.tf       # Threshold-based alerts
│   └── monitoring_dashboard.tf      # Cloud Monitoring dashboard
├── Documentation
│   ├── README.md                     # This file
│   ├── phase_10_monitoring_alerting.md   # Phase 10 complete guide
│   └── DEPLOYMENT_INSTRUCTIONS.md       # Deployment steps
```

---

## If Deploying to New Environment

### Prerequisites

1. **Install Terraform** (v1.0+)
   ```bash
   # Windows (Chocolatey)
   choco install terraform

   # Or download: terraform.io/downloads
   ```

2. **Authenticate with GCP**
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_GCP_PROJECT_ID
   ```

3. **Create GCP Project** (if new)
   ```bash
   gcloud projects create your-project-id --name="Your Project"
   gcloud config set project your-project-id
   ```

### Deployment Steps

#### Step 1: Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

#### Step 2: Review Infrastructure Plan
```bash
terraform plan -out=tfplan
```
Shows all resources that will be created.

#### Step 3: Apply Configuration
```bash
terraform apply tfplan
```
Creates infrastructure in GCP (takes 5-10 minutes).

#### Step 4: Verify Deployment
```bash
terraform output
```
Shows created resource names and details.

#### Step 5: Verify in GCP Console
```bash
# Verify buckets
gsutil ls

# Verify datasets
bq ls --project_id=YOUR_PROJECT_ID

# Verify service account
gcloud iam service-accounts list
```

---

## Customization

### Change Project ID
Edit `terraform.tfvars`:
```hcl
gcp_project_id = "your-new-project-id"
```

### Change Region
Edit `terraform.tfvars`:
```hcl
gcp_region = "us-west1"
gcp_zone   = "us-west1-b"
```

### Change Bucket Name
Edit `terraform.tfvars`:
```hcl
gcs_bucket_name = "your-custom-bucket-name"
```

### Modify Dataset Names
Edit `terraform.tfvars`:
```hcl
bronze_dataset = "my_bronze"
silver_dataset = "my_silver"
gold_dataset   = "my_gold"
ml_dataset     = "my_ml"
```

---

## State Management

### Local State
Terraform saves state in local directory:
- `terraform.tfstate` - Current infrastructure state
- `terraform.tfstate.backup` - Previous state backup

[WARNING] **Never commit `.tfstate` files to Git!**

### Remote State (Team Collaboration)

Add to `providers.tf`:
```hcl
terraform {
  backend "gcs" {
    bucket = "tf-state-nyc-taxi"
    prefix = "terraform/state"
  }
}
```

Create state bucket first:
```bash
gsutil mb gs://tf-state-nyc-taxi
```

Then run:
```bash
terraform init
```

---

## Destroying Infrastructure

[WARNING] **Use with extreme caution!**

Removes ALL resources created by Terraform:
```bash
terraform destroy
```

Confirm by typing `yes` when prompted.

---

## Why This Infrastructure?

### Medallion Architecture Benefits
[OK] **Bronze**: Raw data ingestion point (easy to reload)
[OK] **Silver**: Data quality layer (deduplication, enrichment)
[OK] **Gold**: Optimized for analytics (star schema, pre-aggregations)
[OK] **ML**: Isolated models and training data

### Storage Design
[OK] **Single bucket**: Cost-effective, easier to manage
[OK] **Folder structure**: Clear separation of concerns
[OK] **Versioning**: Enabled for data recovery

### Compute Strategy
[OK] **Ephemeral Dataproc**: Spin up/down as needed (Airflow manages)
[OK] **BigQuery**: Serverless, scalable analytics
[OK] **Cloud Composer**: Orchestrates entire pipeline

### Security Model
[OK] **Service account**: Least privilege principle
[OK] **IAM roles**: Granular permissions only
[OK] **Default network**: Used for internal communication

---

## Portfolio Value

This Terraform configuration demonstrates:

[OK] **Infrastructure as Code**: Complete GCP setup in declarative code
[OK] **Best Practices**: Labels, versioning, partitioning, clustering
[OK] **Reproducibility**: Deploy identical infrastructure multiple times
[OK] **Disaster Recovery**: Rebuild infrastructure from code
[OK] **DevOps Skills**: Terraform, GCP, automation knowledge
[OK] **Team Collaboration**: Tracked in Git, code reviewed

---

## Troubleshooting

### "Project ID not found"
```bash
gcloud auth application-default login
gcloud config set project nyc-taxi-analytics-g12
```

### "Permission denied"
Ensure your GCP user has `Editor` or `Owner` role:
```bash
gcloud projects get-iam-policy nyc-taxi-analytics-g12 \
  --filter="members:YOUR_EMAIL" --format=table
```

### "API not enabled"
Terraform auto-enables APIs, but manual enable:
```bash
gcloud services enable bigquery.googleapis.com dataproc.googleapis.com
```

### "Bucket already exists"
If deploying to existing bucket, modify:
```hcl
# In terraform.tfvars
gcs_bucket_name = "unique-bucket-name-{{ timestamp }}"
```

### "Version constraints"
Update Terraform provider:
```bash
terraform init -upgrade
```

---

## Next Phases

### Phase 10: Cloud Monitoring & Alerting [OK] COMPLETE
- [OK] Notification channels (Email & Teams)
- [OK] 14 Alert policies for failures and anomalies
- [OK] Custom metrics for ETL pipeline tracking
- [OK] Log-based metrics from Cloud Logging
- [OK] Metric-based threshold alerts
- [OK] Monitoring dashboard with 12 tiles

See [phase_10_monitoring_alerting.md](phase_10_monitoring_alerting.md) for complete monitoring guide.

### Phase 11: Testing, CI/CD & Documentation
- Unit tests for Spark jobs
- Integration tests for pipeline
- Cloud Build CI/CD setup

---

## Team Onboarding

New team member setup:
1. Clone repository
2. Run `terraform init`
3. Run `terraform plan` to review
4. Run `terraform apply` to deploy to staging

No manual setup needed - all automated via Terraform!

---

## Important Notes

### Current Status: DOCUMENTATION ONLY
- Terraform files created for the **existing working infrastructure**
- NOT intended for deployment on production setup
- Ready for: New environments, testing, disaster recovery
- Kept in repo for: Team reference, portfolio demonstration

### Why Not Deployed?
- Existing infrastructure is proven and working
- Risk of disruption outweighs automation benefits
- Manual setup is already complete and tested
- Terraform valuable as **blueprint for future deployments**

---

## Resources

- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [BigQuery Terraform Resources](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset)
- [GCP Infrastructure Best Practices](https://cloud.google.com/docs/enterprise/best-practices)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)

---

**Created**: April 11, 2026
**Project**: NYC Taxi Analytics - Group 12
**Status**: [OK] Complete - Documentation & Reference Blueprint
