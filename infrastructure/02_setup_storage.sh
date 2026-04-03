#!/bin/bash
# ============================================================
# Phase 2: Cloud Storage Data Lake Setup
# ============================================================
# Creates the GCS bucket with proper folder structure
# following data lake best practices.
# ============================================================

set -e

# ============================================================
# CONFIGURATION
# ============================================================
PROJECT_ID="nyc-taxi-analytics-g12"
BUCKET_NAME="nyc-taxi-data-bucket-g12"
REGION="us-central1"

echo "============================================================"
echo "Phase 2: Cloud Storage Data Lake Setup"
echo "============================================================"
echo "Bucket: gs://$BUCKET_NAME/"
echo "Region: $REGION"
echo "============================================================"

# ============================================================
# STEP 1: Create Bucket
# ============================================================
echo ""
echo "[Step 1/4] Creating Cloud Storage bucket..."

if gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
    echo "  Bucket already exists"
else
    gsutil mb -p $PROJECT_ID -l $REGION -c STANDARD gs://$BUCKET_NAME/
    echo "  Bucket created"
fi
echo "✓ Bucket ready"

# ============================================================
# STEP 2: Create Folder Structure
# ============================================================
echo ""
echo "[Step 2/4] Creating folder structure..."

# Data Lake folder structure
FOLDERS=(
    "raw/taxi_trips/"          # Bronze layer - raw data
    "temp/spark_temp/"         # Temporary processing files
    "ml/models/"               # Trained ML models
    "ml/artifacts/"            # ML artifacts & metrics
    "scripts/spark/"           # Spark job scripts
    "composer/dags/"           # Airflow DAG files
    "terraform/"               # Terraform state (if needed)
)

for folder in "${FOLDERS[@]}"; do
    echo "  Creating gs://$BUCKET_NAME/$folder"
    # Create placeholder to establish folder
    echo "# Placeholder" | gsutil cp - "gs://$BUCKET_NAME/${folder}.gitkeep" 2>/dev/null || true
done
echo "✓ Folder structure created"

# ============================================================
# STEP 3: Set Lifecycle Policy (Cost Optimization)
# ============================================================
echo ""
echo "[Step 3/4] Setting lifecycle policy..."

cat > /tmp/lifecycle.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "age": 7,
          "matchesPrefix": ["temp/"]
        }
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {
          "age": 30,
          "matchesPrefix": ["raw/"]
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set /tmp/lifecycle.json gs://$BUCKET_NAME/
rm /tmp/lifecycle.json
echo "✓ Lifecycle policy set"

# ============================================================
# STEP 4: Set Bucket Labels (Organization)
# ============================================================
echo ""
echo "[Step 4/4] Setting bucket labels..."

gsutil label ch \
    -l "project:nyc-taxi-analytics" \
    -l "environment:production" \
    -l "team:data-engineering" \
    gs://$BUCKET_NAME/
echo "✓ Labels set"

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "============================================================"
echo "Phase 2 Complete: Cloud Storage Data Lake"
echo "============================================================"
echo "Bucket: gs://$BUCKET_NAME/"
echo ""
echo "Folder Structure:"
echo "  gs://$BUCKET_NAME/"
echo "  ├── raw/"
echo "  │   └── taxi_trips/      <- Upload train.csv here"
echo "  ├── temp/"
echo "  │   └── spark_temp/      <- Spark temporary files"
echo "  ├── ml/"
echo "  │   ├── models/          <- Trained models"
echo "  │   └── artifacts/       <- ML metrics"
echo "  ├── scripts/"
echo "  │   └── spark/           <- ETL scripts"
echo "  ├── composer/"
echo "  │   └── dags/            <- Airflow DAGs"
echo "  └── terraform/           <- IaC state"
echo ""
echo "Lifecycle Rules:"
echo "  • temp/ files deleted after 7 days"
echo "  • raw/ files moved to NEARLINE after 30 days"
echo ""
echo "Next: Upload data and run Phase 3 (BigQuery setup)"
echo "============================================================"
