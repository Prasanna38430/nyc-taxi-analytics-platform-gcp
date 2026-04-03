"""
Cloud Function: Trigger Airflow DAG on GCS Upload
==================================================
This function is triggered when a file is uploaded to the
raw/taxi_trips/ folder in GCS. It then triggers the
Airflow DAG in Cloud Composer.

Author: Group 12
"""

import google.auth
from google.auth.transport.requests import AuthorizedSession
import requests


def trigger_dag(event, context):
    """
    Triggered by a Cloud Storage event.
    Triggers the Airflow DAG when train.csv is uploaded.

    Args:
        event (dict): Event payload.
        context (google.cloud.functions.Context): Event context.
    """
    file_name = event['name']
    bucket = event['bucket']

    print(f"File uploaded: gs://{bucket}/{file_name}")

    # Only trigger for train.csv in the right folder
    if not file_name.endswith('train.csv'):
        print(f"Ignoring file: {file_name}")
        return

    if 'raw/taxi_trips/' not in file_name:
        print(f"File not in raw/taxi_trips/ folder, ignoring")
        return

    print("Triggering Airflow DAG...")

    # Configuration
    PROJECT_ID = "nyc-taxi-analytics-g12"
    LOCATION = "us-central1"
    COMPOSER_ENV = "nyc-taxi-composer"
    DAG_ID = "nyc_taxi_etl_pipeline"

    # Get Composer environment web server URL
    credentials, _ = google.auth.default(
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    authed_session = AuthorizedSession(credentials)

    # Get Airflow web server URL
    composer_url = (
        f"https://composer.googleapis.com/v1/projects/{PROJECT_ID}/"
        f"locations/{LOCATION}/environments/{COMPOSER_ENV}"
    )

    response = authed_session.get(composer_url)
    response.raise_for_status()

    airflow_uri = response.json()['config']['airflowUri']
    print(f"Airflow URI: {airflow_uri}")

    # Trigger the DAG
    trigger_url = f"{airflow_uri}/api/v1/dags/{DAG_ID}/dagRuns"

    trigger_response = authed_session.post(
        trigger_url,
        json={
            "conf": {
                "triggered_by": "gcs_upload",
                "file_path": f"gs://{bucket}/{file_name}",
            }
        },
        headers={"Content-Type": "application/json"},
    )

    if trigger_response.status_code == 200:
        print(f"DAG {DAG_ID} triggered successfully!")
        print(f"Response: {trigger_response.json()}")
    else:
        print(f"Failed to trigger DAG: {trigger_response.status_code}")
        print(f"Response: {trigger_response.text}")
        raise Exception(f"DAG trigger failed: {trigger_response.text}")

    return "OK"
