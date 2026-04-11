# NYC Taxi Analytics Platform

[![GCP](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-669DF6?logo=googlebigquery&logoColor=white)](https://cloud.google.com/bigquery)
[![Apache Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)

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

## Project Structure

```
nyc-taxi-analytics-platform-gcp/
├── README.md
├── .gitignore
├── infrastructure/              # Phase 1-2 & 9: Setup & Terraform IaC
│   ├── 01_setup_project.sh
│   ├── 02_setup_storage.sh
│   ├── terraform/               # Phase 9: Infrastructure as Code
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── apis.tf
│   │   ├── storage.tf
│   │   ├── iam.tf
│   │   ├── bigquery.tf
│   │   ├── firewall.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── monitoring/              # Phase 10: Alerting (pending)
│       └── alert_policies.yaml
├── bigquery/
│   ├── bronze/                  # Phase 3: External table
│   │   └── create_external_table.sql
│   ├── silver/                  # Phase 4: Enriched schema
│   │   └── schema.sql
│   └── gold/                    # Phase 5: Star schema
│       ├── dim_datetime.sql
│       ├── dim_location.sql
│       ├── dim_vendor.sql
│       ├── fact_trips.sql
│       └── aggregations.sql
├── dataproc/                    # Phase 4: Spark ETL
│   └── spark_bronze_to_silver.py
├── airflow/                     # Phase 6: Orchestration
│   └── dags/
│       ├── nyc_taxi_daily_pipeline.py
│       ├── nyc_taxi_etl_pipeline.py
│       └── nyc_taxi_ml_training.py
├── cloud_functions/             # Cloud Functions integration
│   └── trigger_dag/
│       ├── main.py
│       └── requirements.txt
├── bigquery/                    # Phase 7: ML Pipeline
│   └── ml/
│       ├── trip_duration_model.sql
│       └── phase_7_trip_duration_model.md
├── powerbi/                     # Phase 8: Power BI Dashboard
│   ├── phase_8_power_bi_dashboard.md
│   ├── NYC_Taxi_Analytics_Dashboard.pbix
│   └── screenshots/
│       ├── Executive_Summary_Dashboard.png
│       ├── Detailed_Analysis_Dashboard.png
│       └── ML_Insights_Dashboard.png
├── docs/                        # Documentation
│   └── architecture.md
└── tests/                       # Unit & integration tests
    └── test_etl.py
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
git clone https://github.com/YOUR_USERNAME/nyc-taxi-analytics-platform-gcp.git
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

**Group 12** - Big Data Analytics Course
