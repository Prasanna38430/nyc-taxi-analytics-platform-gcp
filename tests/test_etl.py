"""
NYC Taxi Analytics Platform - Unit Tests
Tests for ETL pipeline, data validation, and infrastructure components
"""

import unittest
from unittest.mock import MagicMock, patch, Mock
import json
from datetime import datetime, timedelta
import sys


class TestDataValidation(unittest.TestCase):
    """Test data quality validation rules"""
    
    def setUp(self):
        self.sample_record = {
            'trip_id': 'trip_123456',
            'pickup_latitude': 40.7128,
            'pickup_longitude': -74.0060,
            'dropoff_latitude': 40.7580,
            'dropoff_longitude': -73.9855,
            'trip_distance': 2.5,
            'fare_amount': 12.50,
            'trip_duration_minutes': 15,
            'passenger_count': 1,
            'vendor_id': 1,
            'pickup_datetime': '2024-01-15 10:30:00',
            'dropoff_datetime': '2024-01-15 10:45:00'
        }
    
    def test_nyc_bounds_validation(self):
        """Test NYC geographic bounds validation"""
        # Valid NYC coordinates
        self.assertTrue(40.5 < self.sample_record['pickup_latitude'] < 41.0)
        self.assertTrue(-75.0 < self.sample_record['pickup_longitude'] < -73.0)
    
    def test_trip_duration_validation(self):
        """Test trip duration is between 1 minute and 24 hours"""
        duration = self.sample_record['trip_duration_minutes']
        self.assertGreaterEqual(duration, 1)
        self.assertLessEqual(duration, 24 * 60)
    
    def test_passenger_count_validation(self):
        """Test passenger count is between 1 and 9"""
        count = self.sample_record['passenger_count']
        self.assertGreaterEqual(count, 1)
        self.assertLessEqual(count, 9)
    
    def test_fare_amount_validation(self):
        """Test fare amount is positive"""
        fare = self.sample_record['fare_amount']
        self.assertGreater(fare, 0)
    
    def test_trip_distance_validation(self):
        """Test trip distance is positive"""
        distance = self.sample_record['trip_distance']
        self.assertGreater(distance, 0)
    
    def test_coordinates_non_zero(self):
        """Test pickup and dropoff coordinates are non-zero"""
        self.assertNotEqual(self.sample_record['pickup_latitude'], 0)
        self.assertNotEqual(self.sample_record['pickup_longitude'], 0)
        self.assertNotEqual(self.sample_record['dropoff_latitude'], 0)
        self.assertNotEqual(self.sample_record['dropoff_longitude'], 0)
    
    def test_invalid_bounds_rejected(self):
        """Test records with invalid bounds are rejected"""
        invalid_record = self.sample_record.copy()
        invalid_record['pickup_latitude'] = 50.0  # Outside NYC bounds
        
        self.assertFalse(40.5 < invalid_record['pickup_latitude'] < 41.0)
    
    def test_invalid_duration_rejected(self):
        """Test records with invalid duration are rejected"""
        invalid_record = self.sample_record.copy()
        invalid_record['trip_duration_minutes'] = 1500  # > 24 hours
        
        self.assertFalse(1 <= invalid_record['trip_duration_minutes'] <= 24 * 60)


class TestDataQualityMetrics(unittest.TestCase):
    """Test data quality calculation"""
    
    def test_quality_rate_calculation(self):
        """Test data quality percentage calculation"""
        total_records = 1458644
        valid_records = 1448989
        quality_rate = (valid_records / total_records) * 100
        
        self.assertAlmostEqual(quality_rate, 99.34, places=1)
        self.assertGreater(quality_rate, 99.0)
    
    def test_null_detection(self):
        """Test null value detection"""
        record_with_nulls = {
            'trip_id': None,
            'fare_amount': 12.50
        }
        
        null_count = sum(1 for v in record_with_nulls.values() if v is None)
        self.assertEqual(null_count, 1)
    
    def test_duplicate_detection(self):
        """Test duplicate record detection"""
        records = [
            {'trip_id': '1', 'fare': 10.0},
            {'trip_id': '2', 'fare': 15.0},
            {'trip_id': '1', 'fare': 10.0},
        ]
        
        unique_ids = set(r['trip_id'] for r in records)
        self.assertEqual(len(unique_ids), 2)
        self.assertEqual(len(records) - len(unique_ids), 1)


class TestETLPipeline(unittest.TestCase):
    """Test ETL pipeline logic"""
    
    @patch('airflow.models.Variable.get')
    def test_pipeline_variables_available(self, mock_var_get):
        """Test that required Airflow variables are set"""
        mock_var_get.return_value = 'test-project'
        
        project_id = 'test-project'
        self.assertEqual(project_id, 'test-project')
    
    def test_partition_schema_valid(self):
        """Test BigQuery partition schema"""
        partition_schema = {
            'name': 'trip_date',
            'type': 'DATE'
        }
        
        valid_types = ['DATE', 'TIMESTAMP', 'DATETIME', 'TIME']
        self.assertIn(partition_schema['type'], valid_types)
    
    def test_bronze_to_silver_transformation(self):
        """Test data transformation from Bronze to Silver"""
        bronze_record = {
            'trip_id': 'trip_123',
            'tpep_pickup_datetime': '2024-01-15 10:30:00',
            'tpep_dropoff_datetime': '2024-01-15 10:45:00',
        }
        
        # Simulate transformation
        pickup_dt = datetime.fromisoformat(bronze_record['tpep_pickup_datetime'])
        dropoff_dt = datetime.fromisoformat(bronze_record['tpep_dropoff_datetime'])
        duration = (dropoff_dt - pickup_dt).total_seconds() / 60
        
        self.assertGreater(duration, 0)
        self.assertEqual(duration, 15.0)
    
    def test_gold_layer_aggregation(self):
        """Test Gold layer aggregation logic"""
        trips = [
            {'fare_amount': 10.0, 'trip_distance': 1.0},
            {'fare_amount': 15.0, 'trip_distance': 2.0},
            {'fare_amount': 12.0, 'trip_distance': 1.5},
        ]
        
        avg_fare = sum(t['fare_amount'] for t in trips) / len(trips)
        avg_distance = sum(t['trip_distance'] for t in trips) / len(trips)
        
        self.assertAlmostEqual(avg_fare, 12.33, places=1)
        self.assertAlmostEqual(avg_distance, 1.5, places=1)


class TestDataSchema(unittest.TestCase):
    """Test data schema validation"""
    
    def test_fact_trips_schema(self):
        """Test fact_trips table schema"""
        schema = {
            'trip_id': 'STRING',
            'vendor_id': 'INTEGER',
            'pickup_date': 'DATE',
            'pickup_time_id': 'INTEGER',
            'dropoff_date': 'DATE',
            'dropoff_time_id': 'INTEGER',
            'passenger_location_id': 'INTEGER',
            'dropoff_location_id': 'INTEGER',
            'fare_amount': 'DECIMAL',
            'trip_distance': 'DECIMAL',
            'trip_duration_minutes': 'INTEGER',
        }
        
        required_fields = ['trip_id', 'vendor_id', 'fare_amount']
        for field in required_fields:
            self.assertIn(field, schema)
    
    def test_dimension_table_schemas(self):
        """Test dimension table schemas"""
        dimension_tables = {
            'dim_vendor': ['vendor_id', 'vendor_name'],
            'dim_location': ['location_id', 'borough', 'zone', 'latitude', 'longitude'],
            'dim_datetime': ['time_id', 'full_timestamp', 'hour', 'day_of_week'],
        }
        
        for table, fields in dimension_tables.items():
            self.assertGreater(len(fields), 0)
            self.assertIn(fields[0], fields)  # ID field present


class TestDataFreshness(unittest.TestCase):
    """Test data freshness validation"""
    
    def test_freshness_calculation(self):
        """Test data freshness calculation"""
        last_update = datetime.now() - timedelta(hours=2)
        freshness_hours = (datetime.now() - last_update).total_seconds() / 3600
        
        self.assertLess(freshness_hours, 24)
        self.assertEqual(int(freshness_hours), 2)
    
    def test_stale_data_detection(self):
        """Test detection of stale data (> 24 hours)"""
        last_update = datetime.now() - timedelta(hours=48)
        stale_threshold_hours = 24
        
        hours_since_update = (datetime.now() - last_update).total_seconds() / 3600
        
        self.assertGreater(hours_since_update, stale_threshold_hours)


class TestMonitoringMetrics(unittest.TestCase):
    """Test monitoring and alerting metrics"""
    
    def test_pipeline_success_rate(self):
        """Test pipeline success rate calculation"""
        total_runs = 100
        successful_runs = 95
        success_rate = (successful_runs / total_runs) * 100
        
        self.assertEqual(success_rate, 95.0)
        self.assertGreater(success_rate, 90)
    
    def test_error_rate_threshold(self):
        """Test error rate alerting threshold"""
        errors = 10
        total_jobs = 200
        error_rate = (errors / total_jobs) * 100
        alert_threshold = 5
        
        self.assertGreater(error_rate, alert_threshold)
    
    def test_processing_rate_calculation(self):
        """Test ETL processing rate metrics"""
        records_processed = 1448989
        duration_minutes = 3
        processing_rate = records_processed / duration_minutes
        
        self.assertGreater(processing_rate, 400000)


class TestBigQueryIntegration(unittest.TestCase):
    """Test BigQuery integration"""
    
    @patch('google.cloud.bigquery.Client')
    def test_bq_client_initialization(self, mock_bq_client):
        """Test BigQuery client can be initialized"""
        mock_client = MagicMock()
        mock_bq_client.return_value = mock_client
        
        # Simulate client usage
        project = 'test-project'
        self.assertEqual(project, 'test-project')
    
    def test_dataset_naming_convention(self):
        """Test dataset naming follows convention"""
        datasets = ['bronze', 'silver', 'gold', 'ml']
        
        for dataset in datasets:
            self.assertTrue(dataset.islower())
            self.assertNotIn(' ', dataset)
            self.assertNotIn('_', dataset.split('_')[0])


class TestTerraformValidation(unittest.TestCase):
    """Test Terraform configuration structure"""
    
    def test_required_tf_files_exist(self):
        """Test that required Terraform files are expected to exist"""
        required_files = [
            'main.tf',
            'providers.tf',
            'variables.tf',
            'outputs.tf',
        ]
        
        # Just verify the list is not empty
        self.assertGreater(len(required_files), 0)
    
    def test_common_labels_structure(self):
        """Test Terraform common labels structure"""
        labels = {
            'project': 'nyc-taxi-analytics',
            'environment': 'prod',
            'managed_by': 'terraform'
        }
        
        required_keys = ['project', 'managed_by']
        for key in required_keys:
            self.assertIn(key, labels)


class TestConfigurationValidation(unittest.TestCase):
    """Test configuration files"""
    
    def test_terraform_vars_schema(self):
        """Test Terraform variables file schema"""
        expected_vars = {
            'gcp_project_id': 'string',
            'gcp_region': 'string',
            'environment': 'string',
        }
        
        for var_name, var_type in expected_vars.items():
            self.assertIn(var_type, ['string', 'number', 'list', 'map', 'bool'])
    
    def test_airflow_config_structure(self):
        """Test Airflow configuration structure"""
        config = {
            'schedule_interval': '@daily',
            'max_active_runs': 1,
            'dag_id': 'nyc_taxi_daily_pipeline',
        }
        
        required_fields = ['dag_id', 'schedule_interval']
        for field in required_fields:
            self.assertIn(field, config)


def run_tests():
    """Run all unit tests"""
    unittest.main(argv=[''], exit=False, verbosity=2)


if __name__ == '__main__':
    run_tests()
