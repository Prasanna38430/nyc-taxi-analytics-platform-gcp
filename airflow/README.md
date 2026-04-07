# Airflow DAGs - NYC Taxi Analytics

This folder contains Apache Airflow DAGs for orchestrating the NYC Taxi Analytics pipeline.

## DAGs Overview

### 1. `nyc_taxi_daily_pipeline.py` - Daily ETL Pipeline

**Schedule:** Daily at 2:00 AM UTC (`0 2 * * *`)

**Tasks Flow:**
```
start_pipeline
    │
    ▼
check_source_data_exists (GCS Sensor)
    │
    ▼
create_dataproc_cluster
    │
    ▼
run_spark_bronze_to_silver
    │
    ▼
delete_dataproc_cluster (always runs - cleanup)
    │
    ▼
┌───────────────────┬────────────────────┬─────────────────────────┐
│                   │                    │                         │
▼                   ▼                    ▼                         │
refresh_daily    refresh_hourly    refresh_vendor                  │
_summary         _patterns         _performance                    │
│                   │                    │                         │
└───────────────────┴────────────────────┴─────────────────────────┘
                              │
                              ▼
                        end_pipeline
```

**Key Features:**
- Creates ephemeral Dataproc cluster (cost optimization)
- Deletes cluster even if job fails (trigger_rule=ALL_DONE)
- Refreshes all Gold layer aggregations in parallel
- Email notifications on failure

### 2. `nyc_taxi_ml_training.py` - Weekly ML Training

**Schedule:** Weekly on Sunday at 4:00 AM UTC (`0 4 * * 0`)

**Tasks Flow:**
```
start
    │
    ▼
prepare_ml_features (BigQuery)
    │
    ▼
check_data_quality
    │
    ▼
train_model (BigQuery ML)
    │
    ▼
check_model_improvement
    │
    ├──────────────────┐
    ▼                  ▼
deploy_new_model   skip_deployment
    │                  │
    └────────┬─────────┘
             ▼
            end
```

**Key Features:**
- Prepares ML features from Silver layer
- Data quality gate before training
- Conditional deployment based on model improvement
- Branching logic for deploy/skip decision

## Deployment to Cloud Composer

### Option 1: Upload via Console
1. Go to Cloud Composer → Environments → Your Environment
2. Click on "DAGs" folder link
3. Upload Python files to the DAGs folder

### Option 2: Upload via CLI
```bash
# Set environment variables
COMPOSER_ENV="nyc-taxi-composer"
LOCATION="us-central1"

# Upload DAGs
gcloud composer environments storage dags import \
    --environment=$COMPOSER_ENV \
    --location=$LOCATION \
    --source=dags/nyc_taxi_daily_pipeline.py

gcloud composer environments storage dags import \
    --environment=$COMPOSER_ENV \
    --location=$LOCATION \
    --source=dags/nyc_taxi_ml_training.py
```

### Option 3: Sync from GCS
```bash
# Copy to GCS bucket
gsutil cp dags/*.py gs://nyc-taxi-data-bucket-g12/composer/dags/

# Then configure Composer to sync from this location
```

## Local Testing

```bash
# Install Airflow locally
pip install apache-airflow==2.7.0
pip install -r requirements.txt

# Validate DAG syntax
python -c "from dags.nyc_taxi_daily_pipeline import dag; print('DAG valid!')"

# Run Airflow standalone
airflow standalone
# Access UI at http://localhost:8080
```

## Configuration

All configuration is at the top of each DAG file:
- `PROJECT_ID`: GCP project
- `REGION`: Compute region
- `BUCKET_NAME`: GCS bucket
- `CLUSTER_CONFIG`: Dataproc cluster specs

## Monitoring

- **Airflow UI**: View DAG runs, task logs, and history
- **Cloud Monitoring**: Custom metrics from callbacks
- **Email Alerts**: Configured in `default_args`
