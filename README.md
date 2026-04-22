# NYC Taxi Analytics Platform

[![GCP](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-669DF6?logo=googlebigquery&logoColor=white)](https://cloud.google.com/bigquery)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-017CEE?logo=apacheairflow&logoColor=white)](https://airflow.apache.org/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.13-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-2088FF?logo=github&logoColor=white)](https://github.com/Prasanna38430/nyc-taxi-analytics-platform-gcp/actions)
[![Tests](https://img.shields.io/badge/Tests-28%2F28%20Passing-brightgreen)](./tests/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

An end-to-end data engineering pipeline built on **Google Cloud Platform**, implementing the **Medallion Architecture** (Bronze → Silver → Gold) with real-time industry best practices.

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                         NYC Taxi Analytics Platform                               │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │    Source    │    │    Bronze    │    │    Silver    │    │     Gold     │   │
│  │    (GCS)     │───▶│  (BigQuery)  │───▶│  (BigQuery)  │───▶│  (BigQuery)  │   │
│  │   Raw CSV    │    │   External   │    │   Enriched   │    │  Star Schema │   │
│  └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘   │
│         │                                       │                    │           │
│         │                                       ▼                    ▼           │
│         │                              ┌──────────────┐     ┌──────────────┐    │
│         │                              │ BigQuery ML  │     │   Power BI   │    │
│         │                              │  (Linear Reg)│     │  (Dashboard) │    │
│         │                              └──────────────┘     └──────────────┘    │
│         │                                                                        │
│         └────────────────────┬───────────────────────────────────────────────┐  │
│                              │                                               │  │
│                              ▼                                               │  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │  │
│  │                   Cloud Composer (Airflow)                             │  │  │
│  │                     Orchestration Layer                                │  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │  │
│                                                                              │  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │  │
│  │                        Dataproc (Spark)                                │  │  │
│  │                      ETL Processing Engine                             │  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │  │
│                                                                                   │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                           Terraform (IaC)                                  │  │
│  │                    Infrastructure as Code Layer                            │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## Data Model - Star Schema

```
                              ┌─────────────────┐
                              │  dim_datetime   │
                              │─────────────────│
                              │ datetime_key PK │
                              │ year, month     │
                              │ day, hour       │
                              │ day_name        │
                              │ is_weekend      │
                              │ is_rush_hour    │
                              │ season          │
                              └────────┬────────┘
                                       │
┌─────────────────┐         ┌──────────┴──────────┐         ┌─────────────────┐
│  dim_location   │         │     fact_trips      │         │   dim_vendor    │
│─────────────────│         │─────────────────────│         │─────────────────│
│ location_key PK │◄────────│ trip_id PK          │────────▶│ vendor_key PK   │
│ lat_grid        │         │ datetime_key FK     │         │ vendor_id       │
│ lon_grid        │         │ vendor_key FK       │         │ vendor_name     │
│ grid_id         │         │ pickup_loc_key FK   │         └─────────────────┘
│ approx_borough  │         │ dropoff_loc_key FK  │
└─────────────────┘         │ passenger_count     │
                            │ trip_duration       │
                            │ trip_duration_mins  │
                            │ distance_km         │
                            │ speed_kmh           │
                            └─────────────────────┘
```

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Data Lake** | Cloud Storage | Raw data storage (Bronze zone) |
| **Data Warehouse** | BigQuery | Silver & Gold layers, analytics |
| **ETL Processing** | Dataproc (Spark) | Data transformation & enrichment |
| **Orchestration** | Cloud Composer | Workflow scheduling & automation |
| **ML Platform** | BigQuery ML | Trip duration prediction (Linear Regression) |
| **Visualization** | Power BI | Business intelligence dashboards (3-page) |
| **IaC** | Terraform | Infrastructure provisioning |
| **Monitoring** | Cloud Monitoring | Observability & alerting |
| **CI/CD Pipeline** | GitHub Actions | Automated testing, validation, deployment |

## Project Structure

```
nyc-taxi-analytics-platform-gcp/
├── README.md
├── .gitignore
├── infrastructure/              # Phase 1-2, 9-10: Setup & IaC
│   ├── 01_setup_project.sh
│   ├── 02_setup_storage.sh
│   └── terraform/               # Phase 9-10: Infrastructure & Monitoring as Code
│       ├── main.tf              # Core infrastructure
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       ├── apis.tf
│       ├── storage.tf
│       ├── iam.tf
│       ├── bigquery.tf
│       ├── firewall.tf
│       ├── notification_channels.tf   # Phase 10: Monitoring
│       ├── alert_policies.tf
│       ├── custom_metrics.tf
│       ├── log_based_metrics.tf
│       ├── metric_based_alerts.tf
│       ├── monitoring_dashboard.tf
│       ├── README.md
│       ├── DEPLOYMENT_INSTRUCTIONS.md
│       ├── phase_10_monitoring_alerting.md
│       └── phase_11_cicd_pipeline.md
├── bigquery/                    # Phases 3-7: BigQuery schemas & ML
│   ├── bronze/                  # Phase 3: External table
│   │   └── create_external_table.sql
│   ├── silver/                  # Phase 4: Enriched schema
│   │   └── schema.sql
│   ├── gold/                    # Phase 5: Star schema
│   │   ├── dim_datetime.sql
│   │   ├── dim_location.sql
│   │   ├── dim_vendor.sql
│   │   ├── fact_trips.sql
│   │   └── aggregations.sql
│   └── ml/                      # Phase 7: ML Pipeline
│       ├── trip_duration_model.sql
│       └── phase_7_trip_duration_model.md
├── dataproc/                    # Phase 4: Spark ETL
│   └── spark_bronze_to_silver.py
├── airflow/                     # Phase 6: Orchestration
│   ├── README.md
│   ├── requirements.txt
│   └── dags/
│       ├── nyc_taxi_daily_pipeline.py
│       ├── nyc_taxi_etl_pipeline.py
│       └── nyc_taxi_ml_training.py
├── cloud_functions/             # Cloud Functions integration
│   └── trigger_dag/
│       ├── main.py
│       └── requirements.txt
├── powerbi/                     # Phase 8: Power BI Dashboard
│   ├── phase_8_power_bi_dashboard.md
│   ├── NYC_Taxi_Analytics_Dashboard.pbix
│   └── screenshots/
│       ├── Executive_Summary_Dashboard.png
│       ├── Detailed_Analysis_Dashboard.png
│       └── ML_Insights_Dashboard.png
├── docs/                        # Documentation
│   └── architecture.md
├── .github/                     # Phase 11: CI/CD Pipeline
│   └── workflows/
│       ├── terraform-validate.yml
│       ├── python-test.yml
│       ├── sql-validate.yml
│       ├── terraform-deploy.yml
│       └── pr-checks.yml
├── tests/                       # Phase 11: Unit & integration tests
│   ├── test_etl.py              # 28 comprehensive unit tests
│   └── requirements.txt          # Test dependencies
```

## Pipeline Metrics

| Metric | Value |
|--------|-------|
| **Raw Records** | 1,458,644 |
| **Validated Records** | 1,448,989 |
| **Data Quality Rate** | 99.34% |
| **Records Removed** | 9,655 (0.66%) |
| **ETL Duration** | ~3 minutes |
| **Features Engineered** | 15+ |

## Quick Start

### Prerequisites
- Google Cloud SDK installed and configured
- GCP Project with billing enabled
- Python 3.8+

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/Prasanna38430/nyc-taxi-analytics-platform-gcp.git
cd nyc-taxi-analytics-platform-gcp

# 2. Set GCP project
gcloud config set project nyc-taxi-analytics-g12

# 3. Run Phase 1: Project setup
chmod +x infrastructure/01_setup_project.sh
./infrastructure/01_setup_project.sh

# 4. Run Phase 2: Storage setup
chmod +x infrastructure/02_setup_storage.sh
./infrastructure/02_setup_storage.sh

# 5. Upload raw data
gsutil cp data/train.csv gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/

# 6. Create BigQuery datasets and run ETL
# See detailed instructions in docs/
```

## Key Features

- **Medallion Architecture**: Organized data layers (Bronze → Silver → Gold)
- **Data Quality Validation**: Business rules removing invalid records
- **Feature Engineering**: 15+ derived features for ML
- **Star Schema Design**: Optimized for analytical queries
- **Partitioning & Clustering**: Cost-optimized BigQuery tables
- **ML Pipeline**: Trip duration prediction with BigQuery ML (Linear Regression)
- **Power BI Dashboard**: Professional 3-page analytics dashboard with KPIs and insights
- **Automated Orchestration**: Airflow DAGs for scheduling
- **Infrastructure as Code**: Reproducible deployments with Terraform
- **Monitoring & Alerting**: Proactive issue detection

## Phase 1: Project Setup & Configuration

**Status**: ✅ Complete

Initial GCP project setup and configuration:
- Google Cloud Project creation
- Service account setup with minimal IAM roles
- Cloud SDK authentication and configuration
- Project variables and environment setup

See [infrastructure/01_setup_project.sh](infrastructure/01_setup_project.sh) for automated setup script.

## Phase 2: Cloud Storage Setup

**Status**: ✅ Complete

GCS bucket provisioning and folder structure:
- Cloud Storage bucket creation for data lake
- Folder structure: raw/, processed/, artifacts/, configs/
- IAM permissions for service account
- Lifecycle policies for cost optimization

See [infrastructure/02_setup_storage.sh](infrastructure/02_setup_storage.sh) for automated setup script.

## Phase 3: Bronze Layer (Raw Data)

**Status**: ✅ Complete

Raw data ingestion and storage:
- **External BigQuery Table**: Points to raw CSV in GCS
- **Data Source**: NYC Taxi trip records (train.csv)
- **Schema**: Auto-detected from CSV with 21 columns
- **Update Pattern**: Append-only (new files added regularly)

See [bigquery/bronze/create_external_table.sql](bigquery/bronze/create_external_table.sql) for implementation.

## Phase 4: Silver Layer (Cleaned & Enriched)

**Status**: ✅ Complete

Data transformation and enrichment via Spark ETL:
- **Framework**: Apache Spark (Dataproc)
- **Processing**: PySpark job for data cleaning and feature engineering
- **Data Quality**: Removes invalid records, handles nulls, deduplicates
- **Features Added**: 15+ derived features (trip_duration_mins, distance_km, speed_kmh, etc.)
- **Idempotency**: MERGE-based upserts for exactly-once semantics
- **Output**: BigQuery `nyc_taxi_silver.trips_enriched` table

See [dataproc/spark_bronze_to_silver.py](dataproc/spark_bronze_to_silver.py) and [bigquery/silver/schema.sql](bigquery/silver/schema.sql) for implementation.

## Phase 5: Gold Layer (Analytics-Ready)

**Status**: ✅ Complete

Star schema design for optimized analytics:

**Dimension Tables:**
- **dim_vendor**: Vendor information (2 vendors)
- **dim_datetime**: Time dimensions with 7 attributes (hour, day, is_weekend, etc.)
- **dim_location**: Geographic grids with borough information

**Fact Tables:**
- **fact_trips**: 23M+ trip records with foreign keys to dimensions

**Pre-computed Aggregations:**
- **agg_daily_summary**: Daily trip statistics
- **agg_hourly_patterns**: Peak hour analysis
- **agg_vendor_performance**: Vendor metrics
- **agg_location_hotspots**: Popular pickup locations

See [bigquery/gold/](bigquery/gold/) for all star schema implementations.

## Phase 6: Orchestration (Cloud Composer)

**Status**: ✅ Complete - Batch ETL Pipeline Running via Airflow

### Airflow DAG: NYC Taxi ETL Pipeline

Automated orchestration of the complete Bronze → Silver → Gold data pipeline using **Google Cloud Composer** (managed Apache Airflow):

### Pipeline Visualization

![NYC Taxi Orchestration Pipeline](airflow/phase_6_orchestration_pipeline.png)

*The Airflow DAG showing the complete ETL workflow with task dependencies and execution flow*

### DAG Configuration

| Component | Configuration |
|-----------|---------------|
| **DAG Name** | `nyc_taxi_etl_pipeline` |
| **Trigger Mode** | Event-driven (GCS upload) + Manual (on-demand) |
| **Event Trigger** | Cloud Function listens to `gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/` uploads |
| **Cluster Type** | Ephemeral Dataproc (auto spin-up/down) |
| **Machine Type** | n1-standard-2 (1 master + 2 workers) |
| **Region** | us-central1 (same as BigQuery, GCS) |
| **Spark Configuration** | 4GB executor memory, 2GB driver memory |

### Automatic Trigger via Cloud Function

When a new taxi data file is uploaded to the GCS bucket, the Cloud Function automatically detects the event and triggers the DAG without manual intervention:

```
User uploads train.csv
       ↓
gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/
       ↓
Cloud Function (event trigger)
       ↓
Airflow DAG triggered automatically
       ↓
Pipeline runs: Bronze → Silver → Gold
```

**How it works:**
1. Upload file to: `gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/train.csv`
2. Cloud Function detects the upload event
3. Function calls Airflow API to trigger `nyc_taxi_etl_pipeline` DAG
4. Pipeline automatically processes the new data

### Pipeline Tasks (Sequential Flow)

```
1. log_pipeline_start
   │
2. check_source_data
   │
3. create_dataproc_cluster
   │
4. run_bronze_to_silver_etl (Spark Job)
   │
5. delete_dataproc_cluster
   │
6. refresh_gold_aggregations ──┐
   │                           ├─→ 7. log_pipeline_complete
7. prepare_ml_features ────────┘
```

### Key Features

- **Ephemeral Cluster**: Dataproc cluster created on-demand, deleted after job completes (cost optimization)
- **Idempotent Writes**: Spark job uses MERGE statement for exactly-once semantics (no duplicates)
- **Parallel Processing**: Gold layer refresh and ML feature preparation run in parallel
- **Error Handling**: Automatic retry on failure; cluster cleanup guaranteed even on failure
- **Logging**: Full execution logs in Cloud Logging, visible in Airflow UI

### How to Run

**Option 1: Automatic (Event-Triggered)**
1. Upload a new CSV file to the GCS bucket:
```bash
gsutil cp train.csv gs://nyc-taxi-data-bucket-g12/raw/taxi_trips/
```
2. Cloud Function automatically detects the upload
3. DAG triggers and runs pipeline automatically
4. Monitor in Airflow UI

**Option 2: Manual Trigger via Airflow Web UI**
1. Open Cloud Composer Airflow UI (Cloud Composer → Environment → Airflow webserver)
2. Search for `nyc_taxi_etl_pipeline`
3. Click **"Trigger DAG"** button
4. Monitor execution in **Graph View**
5. View task logs and Spark output as pipeline runs

**Option 3: Manual Trigger via CLI**
```bash
gcloud composer environments run nyc-taxi-composer \
    --location us-central1 \
    dags trigger nyc_taxi_etl_pipeline
```

### Monitoring & Troubleshooting

**Pipeline Status:**
- Gray = Not started
- Yellow = Running
- Green = Success ✅
- Red = Failed ❌

**View Task Logs:**
1. Click on task (box in graph)
2. Click "Log" tab
3. See Spark job output, errors, and metrics

**Check Dataproc Cluster:**
```bash
gcloud dataproc clusters list --region=us-central1
```

**Verify Data in BigQuery:**
```bash
# Check Silver layer row count
bq query --nouse_legacy_sql '
SELECT COUNT(*) as total_rows 
FROM `nyc-taxi-analytics-g12.nyc_taxi_silver.trips_enriched`
'

# Check Gold layer aggregations
bq query --nouse_legacy_sql '
SELECT * FROM `nyc-taxi-analytics-g12.nyc_taxi_gold.agg_daily_summary` 
LIMIT 5
'
```

See [airflow/README.md](airflow/README.md) for complete orchestration documentation.

## Phase 7: ML Pipeline - Trip Duration Prediction

**Status**: ✅ Complete

BigQuery ML model for predicting taxi trip duration:
- **Algorithm**: Linear Regression with 8 input features
- **Target Variable**: trip_duration_minutes
- **Features**: distance_km, passenger_count, hour, is_weekend, vendor, location, day_type, speed_kmh
- **Training Data**: Historical Silver layer trips with data quality filters
- **Model Performance**: R² = 0.72 (72.2% variance explained)
- **Accuracy**: Mean Absolute Percentage Error (MAPE) ~18%

**Use Cases:**
- Driver time estimates for passengers
- Route optimization
- Demand forecasting
- Pricing adjustments

See [bigquery/ml/phase_7_trip_duration_model.md](bigquery/ml/phase_7_trip_duration_model.md) and [bigquery/ml/trip_duration_model.sql](bigquery/ml/trip_duration_model.sql) for complete ML implementation.

## Phase 8: Power BI Analytics Dashboard

**Status**: ✅ Complete

A professional Power BI dashboard with 3 pages analyzing NYC Taxi operations:

### Dashboard Pages
1. **Executive Summary** - High-level KPIs, daily trends, vendor performance, location hotspots
2. **Detailed Analysis** - Deep-dive patterns, hourly/daily heatmaps, vendor comparison, speed analytics
3. **ML Insights** - Model performance metrics (72.2% accuracy), distance vs duration scatter plot, top locations

### Data Integration
- **Data Source**: BigQuery Gold Layer (8 tables)
- **Fact Tables**: fact_trips (23M+ records)
- **Dimension Tables**: dim_vendor, dim_datetime, dim_location
- **Aggregated Tables**: agg_daily_summary, agg_hourly_patterns, agg_vendor_performance, agg_location_hotspots

### Performance
- **Load Mode**: Import (optimized for portfolio)
- **Average page load**: < 2 seconds
- **Filter response**: < 500ms
- **Daily refresh**: Scheduled

### Dashboard Workbook
- **File**: `powerbi/NYC_Taxi_Analytics_Dashboard.pbix` (84 MB)
- **Connection**: BigQuery OAuth (prasannakumar4398@gmail.com)
- **Update Frequency**: Daily refresh scheduled
- **How to Use**: Open in Power BI Desktop → Refresh → Explore interactive dashboards

See [powerbi/phase_8_power_bi_dashboard.md](powerbi/phase_8_power_bi_dashboard.md) for complete documentation and screenshots.

## Phase 9: Infrastructure as Code (Terraform)

**Status**: ✅ Complete

Production-ready Terraform configuration for GCP infrastructure deployment:

### Terraform Modules

| File | Purpose | Resources |
|------|---------|-----------|
| `main.tf` | Local variables & common labels | Standardized tagging |
| `providers.tf` | Terraform & provider version constraints | GCP provider ~> 5.0 |
| `variables.tf` | Input variables for project configuration | GCP project, region, zone, dataset names |
| `apis.tf` | Google Cloud API enablement | 25 APIs via for_each loop |
| `storage.tf` | GCS bucket & folder structure | Data bucket with 8 folders |
| `iam.tf` | Service account & IAM roles | 9 role assignments |
| `bigquery.tf` | BigQuery datasets & tables | 4 datasets, 12 tables |
| `firewall.tf` | Compute firewall rules | Dataproc internal communication |
| `outputs.tf` | Output values for reference | Bucket name, dataset IDs, service account |

### Key Features
- **Modular Design**: Organized by GCP service
- **DRY Principle**: Uses locals for common labels
- **for_each Loops**: Efficient API and resource management
- **Service Account**: Dedicated SA for pipeline with minimal required permissions
- **IAM Roles**: 9 roles including BigQuery, Dataproc, Cloud Composer, IAM User, Storage Admin
- **Partitioning & Clustering**: Optimized BigQuery tables for performance
- **Cost Optimization**: Proper resource configuration for budget control

### Deployment
```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

### Managed Resources
- **Compute**: Dataproc cluster firewall rules
- **BigQuery**: 4 datasets (Bronze, Silver, Gold, ML) with 12 tables
- **Storage**: GCS bucket with folder structure for raw data, configs, ML artifacts
- **IAM**: Service account with 9 role assignments
- **APIs**: 25 Google Cloud APIs enabled

See [infrastructure/terraform/README.md](infrastructure/terraform/README.md) for detailed documentation.

## Phase 10: Cloud Monitoring & Alerting

**Status**: ✅ Complete

Comprehensive monitoring and alerting infrastructure using Google Cloud's native services:

### Alert Policies (14 Total)

**Critical Alerts (Failures):**
- Dataproc cluster creation failures
- Spark job execution failures
- BigQuery job failures
- Cloud Function invocation errors

**Data Quality Alerts:**
- Data not updated for 24+ hours
- Pipeline success rate drops below 95%
- Data quality issues detected (nulls, duplicates)

**Performance & Resource Alerts:**
- High CPU usage (> 80%)
- High memory usage (> 85%)
- ETL jobs running > 1 hour
- API response time > 5 seconds
- ETL processing rate < 1000 rows/minute
- Error rate exceeds 5%
- GCS bucket exceeds 100 GB

### Notification Channels

- **Email**: prasannakumaradabala20@gmail.com
- **MS Teams**: Webhook integration for instant alerts

### Custom Metrics (12 Total)

| Metric | Type | Purpose |
|--------|------|---------|
| `rows_processed` | DELTA | Track ETL throughput |
| `etl_duration_minutes` | GAUGE | Monitor job duration |
| `data_freshness_hours` | GAUGE | Track data currency |
| `error_rate` | GAUGE | Monitor reliability |
| `pipeline_success_count` | DELTA | Success tracking |
| `pipeline_failure_count` | DELTA | Failure tracking |
| `etl_processing_rate` | GAUGE | Performance metric |
| `data_quality_issues` | DELTA | Quality monitoring |
| `api_response_time_ms` | GAUGE | Performance tracking |
| `bigquery_data_scanned_gb` | DELTA | Cost monitoring |
| `dataproc_creation_failed` | DELTA | Infrastructure tracking |
| `warning_count` | DELTA | Issue detection |

### Monitoring Dashboard

Real-time Cloud Monitoring dashboard with 12 tiles across 6 rows:

1. **Row 1**: Pipeline Status KPIs (Total Jobs, Failed Jobs, BigQuery Errors, Data Freshness)
2. **Row 2**: Resource Utilization (Dataproc CPU & Memory)
3. **Row 3**: BigQuery Metrics (Job Execution Time, Data Scanned)
4. **Row 4**: ETL Metrics (Rows Processed, Duration, Error Rate)
5. **Row 5**: Cloud Function Metrics (Invocations, Errors)
6. **Row 6**: Storage Metrics (Bucket Size, Object Count)

### Terraform IaC

All monitoring infrastructure defined in code:
```
infrastructure/terraform/
├── notification_channels.tf       # Email & Teams webhooks
├── alert_policies.tf              # 14 alert policies
├── custom_metrics.tf              # Custom metric definitions
├── log_based_metrics.tf           # Log-based metrics from Cloud Logging
├── metric_based_alerts.tf         # Threshold-based alerts
└── monitoring_dashboard.tf        # Cloud Monitoring dashboard
```

See [infrastructure/terraform/phase_10_monitoring_alerting.md](infrastructure/terraform/phase_10_monitoring_alerting.md) for complete monitoring guide.

## Phase 11: CI/CD Pipeline & Automated Testing

**Status**: ✅ Complete

Comprehensive GitHub Actions CI/CD pipeline automating testing, validation, and deployment:

### GitHub Actions Workflows (5 Total)

| Workflow | Trigger | Purpose | Jobs |
|----------|---------|---------|------|
| `terraform-validate.yml` | Push/PR to main/develop | Terraform syntax, format, linting | Validate, Plan (on PR) |
| `python-test.yml` | Push/PR when Python changes | Code quality, unit tests, security | Lint, Unit Tests, Security |
| `sql-validate.yml` | Push/PR when SQL changes | SQL syntax, BigQuery dry-run | SQL Lint, BigQuery Dry-Run |
| `terraform-deploy.yml` | Manual workflow_dispatch | Plan and apply Terraform changes | Plan, Approval gate, Apply, Post-deploy tests |
| `pr-checks.yml` | Pull request on main/develop | Code formatting, dependencies, docs | Formatting, Dependencies, Documentation, Summary |

### Key Features

- **Automated Validation**: All code changes automatically tested before merge
- **Terraform Plan Preview**: PR comments showing planned infrastructure changes
- **Unit Testing**: 27 comprehensive unit tests covering:
  - Data validation rules (NYC bounds, duration, passenger count)
  - Data quality calculations (99.34% expected quality rate)
  - ETL pipeline logic (Bronze→Silver→Gold transformations)
  - Schema validation (fact tables, dimension tables)
  - Monitoring metrics (success rate, error rate, processing rate)

- **Code Quality Checks**:
  - Python linting (flake8, pylint)
  - Code formatting (black, isort)
  - Security scanning (bandit, safety)
  - SQL linting (sqlfluff)
  
- **Manual Approval Gates**: Staging and prod deployments require approval
- **Cost Optimization**: Dry-run tests avoid unnecessary resource creation
- **Audit Trail**: Complete deployment history in Actions tab

### CI/CD Pipeline Flow

**On Pull Request** → Terraform Validate + Python Test + SQL Validate + PR Checks → Comment Results

**On Merge to Main** → Full Test Suite → Ready for Deployment

**Manual Deployment** → Plan → Review → Approval → Apply → Post-Deploy Verification

### Running Locally

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run all tests
pytest tests/ -v

# Terraform validation
terraform -chdir=infrastructure/terraform fmt -check
terraform -chdir=infrastructure/terraform validate

# SQL validation
sqlfluff lint bigquery/ --dialect bigquery
```

### GitHub Secrets Required

```
GCP_CREDENTIALS: GCP service account JSON key
  (roles: editor, bigquery.admin, storage.admin)
```

See [infrastructure/terraform/phase_11_cicd_pipeline.md](infrastructure/terraform/phase_11_cicd_pipeline.md) for complete CI/CD documentation.

## Data Quality Rules Applied

| Rule | Description | Records Affected |
|------|-------------|------------------|
| NYC Bounds | Latitude/Longitude within NYC | ~0.3% |
| Trip Duration | Between 1 min and 24 hours | ~0.2% |
| Passenger Count | Between 1 and 9 | ~0.1% |
| Coordinates | Non-zero pickup/dropoff | ~0.05% |

## License

This project is for educational and portfolio demonstration purposes.

## Author

NYC Taxi Analytics Platform
