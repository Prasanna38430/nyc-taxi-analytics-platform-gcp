# Phase 8: Power BI Dashboard - Professional Analytics Dashboard

## Project Overview
Professional Power BI dashboard for NYC Taxi Trip Analytics built on BigQuery Gold Layer with 8 tables (4 fact/dimension + 4 aggregated).

## Data Architecture

### Data Source
- **Platform**: Google BigQuery
- **Dataset**: nyc_taxi_gold
- **Connection Type**: OAuth via prasannakumar4398@gmail.com
- **Load Mode**: Import (optimized for portfolio demo)
- **Refresh Schedule**: Daily

### Tables Used

#### Fact & Dimension Tables
- **fact_trips**: 23M+ trip records with measures (duration, distance, fare)
- **dim_vendor**: Vendor reference (Yellow/Green cab)
- **dim_datetime**: Date/time dimensions with hierarchies
- **dim_location**: Geographic location data (borough, grid, coordinates)

#### Aggregated Tables (Pre-computed)
- **agg_daily_summary**: Daily metrics (trips, passengers, duration, distance, speed)
- **agg_hourly_patterns**: Hourly breakdown by day-of-week
- **agg_vendor_performance**: Vendor comparison metrics
- **agg_location_hotspots**: Geographic hotspots with location metrics

## Dashboard Structure

### PAGE 1: EXECUTIVE SUMMARY
**Purpose**: High-level KPIs for stakeholders

**Visuals**:
- KPI Cards (4):
  - Latest Day Total Trips
  - Latest Day Passengers
  - Latest Day Avg Duration
  - Peak Operating Hour
- Line Chart: Daily trip trends
- Horizontal Bar Chart: Trips by vendor
- Pie Chart: Daily distribution by day-of-week
- Map: Pickup location hotspots

**Key Insights**: Quick snapshot of recent activity, peak hours, vendor performance

### PAGE 2: DETAILED ANALYSIS
**Purpose**: Deep-dive operational analytics

**Visuals**:
- Date range slicer for custom filtering
- Area Chart: Passenger trends
- Matrix/Heatmap: Hour × Day activity (conditional color formatting)
- Column Chart: Average speed by vendor
- Column Chart: Average distance by hour
- Clustered Bar Chart: Average passengers per trip

**Key Insights**: Identify patterns, trends, seasonality, vendor differences

### PAGE 3: ML INSIGHTS
**Purpose**: Machine Learning model performance & insights

**Visuals**:
- Text boxes: Model metadata (type, accuracy, features)
- Scatter Plot: Distance vs Duration (feature relationship)
- Table: Top 10 pickup locations with metrics
- Gauge: Model accuracy percentage (72.2%)

**ML Model Details**:
- Type: Linear Regression (BigQuery ML)
- Target: Trip duration prediction
- Training data: 5,000 samples
- MAE: 3.67 minutes
- RMSE: 4.92 minutes
- R²: 0.722 (72.2% accuracy)

## DAX Measures

| Measure | Purpose |
|---------|---------|
| Latest Day Trips | Latest day KPI |
| Latest Day Passengers | Passenger volume |
| Latest Day Avg Duration | Average trip time |
| Top Vendor | Highest-performing vendor |
| Avg Speed KMH | Fleet average speed |
| Active Locations | Operating area |
| Peak Hour | Busiest hour |
| Busiest Day | Busiest day of week |

## Performance Optimization

### Import Mode Benefits
- ✅ **Fast interactions**: No network latency, instant filtering
- ✅ **Responsive dashboard**: Smooth drill-through experience
- ✅ **Professional presentation**: No loading spinners
- ✅ **Portfolio quality**: Screenshots capture data instantly

### Aggregation Strategy
- Pre-computed aggregated tables reduce Power BI computation
- Direct use of agg_* tables vs. raw fact_trips
- Materialized summaries enable instant dashboard load

### Query Performance
- Average page load: < 2 seconds
- Filter response: < 500ms
- Drill-through: Instant

## Professional Design Elements

### Theme
- **Color Scheme**: Executive (Dark blue, white, gray)
- **Typography**: Segoe UI, 11pt body, 12pt titles
- **Layout**: 3-column grid per page
- **Branding**: Company header, date stamp

### User Experience
- Consistent formatting across all pages
- Intuitive navigation bookmarks
- Contextual use of aggregations
- Color-coded heatmaps for patterns

## Business Value

### Executive Insights
- Daily operational metrics for management reporting
- Vendor performance comparison for contract evaluation
- Hourly patterns for resource planning
- Geographic hotspots for service coverage

### Operational Benefits
- Quickly identify demand patterns
- Monitor vendor performance
- Optimize vehicle deployment
- Support pricing strategies

### Technical Achievement
- Demonstrates data warehouse to BI orchestration
- Shows dimensional modeling best practices
- Implements aggregation strategy
- Exhibits professional dashboard design

## Dashboard Files

- **NYC_Taxi_Analytics_Dashboard.pbix** - Main Power BI workbook
- **screenshots/Executive_Summary_Dashboard.png** - Page 1: Executive Summary
- **screenshots/Detailed_Analysis_Dashboard.png** - Page 2: Detailed Analysis
- **screenshots/ML_Insights_Dashboard.png** - Page 3: ML Model Insights

## Author
Group 12 - NYC Taxi Analytics Portfolio Project
Date: April 11, 2026
