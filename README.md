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
│         │                              │ BigQuery ML  │     │   Looker     │    │
│         │                              │  (Linear Reg)│     │   Studio     │    │
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
| **Visualization** | Looker Studio | Business intelligence dashboards |
| **IaC** | Terraform | Infrastructure provisioning |
| **Monitoring** | Cloud Monitoring | Observability & alerting |

## Project Structure

```
nyc-taxi-analytics-platform-gcp/
├── README.md
├── .gitignore
├── infrastructure/              # Phase 1-2: Setup scripts & Terraform
│   ├── 01_setup_project.sh
│   ├── 02_setup_storage.sh
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
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
│       └── nyc_taxi_pipeline_dag.py
├── bigquery/                    # Phase 7: ML Pipeline (BigQuery ML)
│   └── ml/
│       ├── trip_duration_model.sql
│       └── phase_7_trip_duration_model.md
├── monitoring/                  # Phase 10: Alerting
│   └── alert_policies.yaml
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
- **Automated Orchestration**: Airflow DAGs for scheduling
- **Infrastructure as Code**: Reproducible deployments with Terraform
- **Monitoring & Alerting**: Proactive issue detection

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
