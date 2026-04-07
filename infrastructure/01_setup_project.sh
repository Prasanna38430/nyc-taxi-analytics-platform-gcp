#!/bin/bash
# GCP Project Setup and Configuration
# Initializes the project with required APIs, service accounts, and network configuration.

set -e

# Configuration
PROJECT_ID="nyc-taxi-analytics-g12"
REGION="us-central1"
ZONE="us-central1-a"
SA_NAME="nyc-taxi-pipeline-sa"

echo "Starting GCP Project Setup"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

# Step 1: Set Project Configuration
echo ""
echo "[Step 1/4] Setting GCP project configuration..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo "✓ Project configuration set"

# Step 2: Enable Required APIs
echo ""
echo "[Step 2/4] Enabling required APIs..."

APIS=(
    "bigquery.googleapis.com"
    "storage.googleapis.com"
    "dataproc.googleapis.com"
    "composer.googleapis.com"
    "aiplatform.googleapis.com"
    "compute.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "  Enabling $api..."
    gcloud services enable $api --quiet
done
echo "✓ All APIs enabled"

# Step 3: Create Service Account with Required Roles
echo ""
echo "[Step 3/4] Creating service account..."
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account exists
if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    echo "  Service account already exists"
else
    gcloud iam service-accounts create $SA_NAME \
        --display-name="NYC Taxi Pipeline Service Account" \
        --description="Service account for NYC Taxi data pipeline operations"
    echo "  Service account created"
fi

# Grant required roles
ROLES=(
    "roles/bigquery.admin"
    "roles/storage.admin"
    "roles/dataproc.editor"
    "roles/composer.worker"
    "roles/aiplatform.user"
    "roles/monitoring.editor"
)

echo "  Granting IAM roles..."
for role in "${ROLES[@]}"; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role" \
        --quiet
done
echo "✓ Service account configured"

# Step 4: Configure Network for Dataproc
echo ""
echo "[Step 4/4] Configuring network..."

# Enable Private Google Access
gcloud compute networks subnets update default \
    --region=$REGION \
    --enable-private-ip-google-access \
    --quiet 2>/dev/null || echo "  Private IP access already enabled"

# Create firewall rule for Dataproc
if gcloud compute firewall-rules describe allow-dataproc-internal &>/dev/null; then
    echo "  Firewall rule already exists"
else
    gcloud compute firewall-rules create allow-dataproc-internal \
        --network=default \
        --allow=tcp,udp,icmp \
        --source-ranges=10.128.0.0/9 \
        --description="Allow internal Dataproc cluster communication" \
        --quiet
    echo "  Firewall rule created"
fi
echo "✓ Network configured"

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "============================================================"
echo "Phase 1 Complete: GCP Project Setup"
echo "============================================================"
echo "Project ID:       $PROJECT_ID"
echo "Region:           $REGION"
echo "Zone:             $ZONE"
echo "Service Account:  $SA_EMAIL"
echo ""
echo "APIs Enabled:"
for api in "${APIS[@]}"; do
    echo "  ✓ $api"
done
echo ""
echo "Next: Run 02_setup_storage.sh for Phase 2"
echo "============================================================"
