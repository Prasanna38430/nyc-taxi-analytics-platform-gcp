# Architecture Documentation

## Overview

This document describes the architecture of the NYC Taxi Analytics Platform built on Google Cloud Platform (GCP).

## Medallion Architecture

We implement the **Medallion Architecture** (also known as multi-hop architecture), which organizes data into three distinct layers:

### Bronze Layer (Raw)
- **Storage**: Google Cloud Storage (GCS)
- **Format**: Raw CSV files as-is from source
- **Access**: BigQuery External Table (schema-on-read)
- **Purpose**: Preserve original data without transformation

### Silver Layer (Curated)
- **Storage**: BigQuery
- **Processing**: Dataproc Spark
- **Transformations**:
  - Data validation (NYC bounds, duration limits)
  - Data type casting
  - Feature engineering (15+ derived features)
- **Purpose**: Clean, validated, enriched data

### Gold Layer (Business)
- **Storage**: BigQuery
- **Design**: Star Schema
- **Tables**:
  - `dim_datetime` - Time dimension
  - `dim_location` - Location dimension
  - `dim_vendor` - Vendor dimension
  - `fact_trips` - Central fact table
  - `agg_*` - Pre-aggregated tables
- **Purpose**: Business-ready, analytics-optimized

## Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Source    │     │   Bronze    │     │   Silver    │     │    Gold     │
│   (CSV)     │────▶│   (GCS)     │────▶│ (BigQuery)  │────▶│ (BigQuery)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │                   │
                    External Table      Spark ETL on         SQL Trans-
                    (schema-on-read)    Dataproc Cluster     formations
```

## GCP Services Used

| Service | Purpose | Configuration |
|---------|---------|---------------|
| Cloud Storage | Data Lake (Bronze) | Standard storage, us-central1 |
| BigQuery | Data Warehouse (Silver/Gold) | On-demand pricing, partitioned tables |
| Dataproc | Spark ETL Processing | Ephemeral clusters, auto-scaling |
| Cloud Composer | Workflow Orchestration | Airflow 2.x |
| Vertex AI | ML Model Training | AutoML / Custom training |
| Looker Studio | Business Intelligence | Connected to Gold layer |
| Cloud Monitoring | Observability | Custom metrics & alerts |
| Terraform | Infrastructure as Code | State in GCS |

## Star Schema Design

### Dimension Tables

**dim_datetime**
- Grain: Hour
- Attributes: year, month, day, hour, day_name, is_weekend, is_rush_hour, season

**dim_location**
- Grain: 0.01° lat/lon grid (approx. 1km)
- Attributes: lat_grid, lon_grid, approximate_borough

**dim_vendor**
- Grain: Vendor
- Attributes: vendor_id, vendor_name

### Fact Table

**fact_trips**
- Grain: Individual trip
- Measures: passenger_count, trip_duration, distance_km, speed_kmh
- Foreign Keys: datetime_key, vendor_key, pickup_location_key, dropoff_location_key
- Partitioned by: pickup_datetime (DAY)
- Clustered by: vendor_key, pickup_location_key

## Data Quality Rules

| Rule | Description | Impact |
|------|-------------|--------|
| NYC Bounds | Lat 40.5-41.0, Lon -74.3 to -73.7 | ~0.3% removed |
| Duration | Between 1 min and 24 hours | ~0.2% removed |
| Passengers | Between 1 and 9 | ~0.1% removed |
| Required Fields | Non-null id, timestamps | ~0.05% removed |

## Feature Engineering

### Time Features
- pickup_year, pickup_month, pickup_day, pickup_hour
- pickup_dayofweek, pickup_day_name
- is_weekend, time_of_day

### Distance Features
- distance_km (Haversine formula)
- speed_kmh
- trip_duration_minutes

### Location Features
- pickup_lat_grid, pickup_lon_grid
- dropoff_lat_grid, dropoff_lon_grid

### Metadata
- etl_timestamp
- etl_version

## Cost Optimization

1. **Partitioning**: Tables partitioned by date reduce query costs
2. **Clustering**: Frequently filtered columns clustered for efficient scans
3. **External Tables**: Bronze layer doesn't duplicate storage costs
4. **Ephemeral Clusters**: Dataproc clusters created on-demand and deleted after use
5. **Lifecycle Policies**: Temp files auto-deleted after 7 days

## Security

1. **Service Accounts**: Dedicated SA for pipeline operations
2. **IAM Roles**: Principle of least privilege
3. **VPC**: Private IP access for Dataproc
4. **No Credentials in Code**: All auth via service accounts
