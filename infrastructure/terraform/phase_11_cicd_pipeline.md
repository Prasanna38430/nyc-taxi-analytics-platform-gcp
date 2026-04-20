# Phase 11: CI/CD Pipeline & Automated Testing

**Objective**: Implement GitHub Actions CI/CD for automated testing, validation, and deployment of the entire platform.

**Date Completed**: April 20, 2026

---

## Overview

Phase 11 establishes a comprehensive CI/CD pipeline that automates:
- **Code Quality**: Linting, formatting, and security scanning
- **Testing**: Unit tests, integration tests, and coverage reporting
- **Infrastructure**: Terraform validation and dry-run deployments
- **Data Validation**: SQL validation and BigQuery dry-run tests
- **Deployment**: Automated and manual deployment workflows

---

## GitHub Actions Workflows

### 1. **Terraform Validation** (`terraform-validate.yml`)

**Triggers**: `push` or `pull_request` on `main`/`develop` when Terraform files change

**Jobs**:
- **Validate**: Terraform syntax and format checks
  - `terraform fmt -check`
  - `terraform init -backend=false`
  - `terraform validate`
  - TFLint rule validation
  
- **Plan**: Dry-run plan with GCP authentication
  - Requires `GCP_CREDENTIALS` secret
  - Generates `tfplan` and `tfplan.json`
  - Posts plan summary to PR

**Outputs**: 
- Plan artifacts for review
- Change summary (adds/updates/deletes)

---

### 2. **Python Testing** (`python-test.yml`)

**Triggers**: `push` or `pull_request` when Python files change

**Jobs**:
- **Lint**: Code quality checks
  - Black (code formatter check)
  - isort (import organization)
  - Flake8 (style enforcement)
  - Pylint (code analysis)

- **Unit Tests**: Test suite execution
  - pytest with coverage reporting
  - Coverage report generation
  - Test artifacts upload
  
- **Security**: Vulnerability scanning
  - Bandit (Python security)
  - Safety (dependency scanning)

**Coverage**: 
- Airflow DAGs
- Dataproc ETL code
- Cloud Functions
- Unit tests

**Artifacts**:
- `test-results.xml` (xUnit format)
- `htmlcov/` (coverage HTML report)

---

### 3. **SQL Validation** (`sql-validate.yml`)

**Triggers**: `push` or `pull_request` when SQL files change

**Jobs**:
- **SQL Lint**: SQL code quality
  - SQLFluff linting
  - SQL syntax validation
  - Custom rule checking
  
- **BigQuery Dry Run**: Query validation
  - Requires `GCP_CREDENTIALS` secret
  - Dry-run each .sql file
  - Validates against BigQuery dialect
  - Reports errors and warnings

**Validates**:
- Bronze table creation
- Silver transformation queries
- Gold aggregation queries
- ML model queries

---

### 4. **Terraform Deploy** (`terraform-deploy.yml`)

**Triggers**: `workflow_dispatch` (manual trigger)

**Parameters**:
- `environment`: dev, staging, or prod
- `auto_approve`: Skip approval for dev

**Jobs**:
- **Plan**: Create Terraform plan
  - Initialize backend
  - Generate plan with artifacts
  - Store plan JSON for analysis

- **Approval**: Manual approval gate
  - Required for staging/prod
  - Skipped for dev (optional)
  - Prevents unintended deployments

- **Apply**: Execute Terraform changes
  - Download stored plan
  - Apply infrastructure changes
  - Verify deployment success

- **Post-Deploy Tests**: Verification
  - Check GCS bucket
  - Verify BigQuery datasets
  - Confirm alert policies
  - Generate deployment report

---

### 5. **PR Checks** (`pr-checks.yml`)

**Triggers**: `pull_request` on `main`/`develop`

**Jobs**:
- **Formatting**: YAML and Markdown checks
  - YAML syntax validation
  - Markdown formatting review

- **Dependencies**: Package auditing
  - Dependency vulnerability scan
  - requirement.txt validation

- **Documentation**: Documentation checks
  - README update detection
  - File header/docstring checking

- **Summary**: Creates PR comment with check results

---

## Configuration & Secrets

### Required GitHub Secrets

```yaml
GCP_CREDENTIALS:
  Description: GCP service account JSON key
  Type: JSON
  Usage: Terraform apply, BigQuery validation
  
# How to set up:
# 1. Create GCP service account with roles:
#    - roles/editor (for Terraform)
#    - roles/bigquery.admin (for BigQuery)
#    - roles/storage.admin (for GCS)
# 2. Create JSON key
# 3. Add to GitHub Secrets as GCP_CREDENTIALS
```

### Environment Variables

**Available in workflows**:
```bash
TERRAFORM_VERSION=1.5.0
GCP_PROJECT_ID=<from gcloud config>
```

---

## Running Tests Locally

### Setup Test Environment

```bash
# Install test dependencies
pip install -r tests/requirements.txt

# Run all tests
pytest tests/ -v --cov=airflow --cov=dataproc --cov=cloud_functions

# Run specific test suite
pytest tests/test_etl.py -v

# Generate coverage report
pytest tests/ --cov=. --cov-report=html
# Open htmlcov/index.html in browser
```

### Terraform Validation

```bash
# Format check
terraform -chdir=infrastructure/terraform fmt -check -recursive

# Validate
terraform -chdir=infrastructure/terraform init -backend=false
terraform -chdir=infrastructure/terraform validate

# Plan
terraform -chdir=infrastructure/terraform plan
```

### SQL Validation

```bash
# Using SQLFluff
sqlfluff lint bigquery/ --dialect bigquery

# Using BigQuery client
gsutil config set project <PROJECT_ID>
bq query --use_legacy_sql=false --dry_run < bigquery/gold/fact_trips.sql
```

---

## Test Coverage

### Unit Tests (`tests/test_etl.py`)

**Data Validation Tests** (27 tests):
```
✓ NYC bounds validation (lat/long within NYC)
✓ Trip duration validation (1 min - 24 hours)
✓ Passenger count validation (1-9 passengers)
✓ Fare amount validation (positive)
✓ Trip distance validation (positive)
✓ Coordinates non-zero validation
```

**Data Quality Tests**:
```
✓ Quality rate calculation (99.34% expected)
✓ Null value detection
✓ Duplicate detection
```

**ETL Pipeline Tests**:
```
✓ Airflow variables availability
✓ BigQuery partition schema validation
✓ Bronze→Silver transformation
✓ Gold layer aggregation
```

**Schema Tests**:
```
✓ Fact table schema (fact_trips)
✓ Dimension table schemas (vendor, location, datetime)
```

**Monitoring Tests**:
```
✓ Pipeline success rate calculation
✓ Error rate threshold checking
✓ Processing rate metrics
```

**Integration Tests**:
```
✓ BigQuery client initialization
✓ Dataset naming conventions
✓ Terraform file structure
✓ Configuration validation
```

---

## CI/CD Pipeline Flow

### On Pull Request

```
PR created/updated
    ↓
[Parallel]
├─ Terraform Validate (syntax, fmt, lint)
├─ Python Test (lint, unit tests, security)
├─ SQL Validate (sqlfluff, syntax)
├─ PR Checks (formatting, deps, docs)
    ↓
[If all pass]
├─ Post summary comment
└─ Allow merge

[If any fails]
└─ Block merge, show errors
```

### On Merge to Main

```
Code merged to main
    ↓
Terraform Validate (full run)
    ↓
Python Test (full run)
    ↓
SQL Validate (full run)
    ↓
All tests pass
    ↓
Ready for deployment
```

### Manual Deployment

```
Trigger terraform-deploy.yml manually
    ↓
Select environment (dev/staging/prod)
    ↓
Plan phase:
├─ Terraform init
├─ Terraform plan
└─ Save plan artifact
    ↓
[If staging/prod]
└─ Await manual approval
    ↓
Apply phase:
├─ Download plan
├─ Terraform apply
└─ Post-deploy verification
```

---

## Best Practices

### 1. Code Review Before Merge

- All PR checks must pass
- Terraform plan must be reviewed
- At least one approval required (recommended)

### 2. Incremental Deployments

- Deploy to dev first
- Validate in dev environment
- Promote to staging with approval
- Final prod deployment is manual

### 3. Testing Strategy

- Run tests locally before pushing
- Fix linting issues before PR
- Add tests for new features
- Maintain > 80% code coverage

### 4. Secrets Management

- Never commit credentials
- Use GitHub Secrets for tokens
- Rotate GCP service account keys regularly
- Monitor audit logs

### 5. Monitoring CI/CD

- Check workflow runs in Actions tab
- Review deployment reports
- Monitor alert policies
- Set up Slack notifications (optional)

---

## Troubleshooting

### Terraform Plan Fails

**Issue**: `backend not configured`
**Solution**: Workflows use `-backend=false` for validation, backend set during apply

**Issue**: `Credentials not found`
**Solution**: Ensure `GCP_CREDENTIALS` secret is set in repo settings

### Python Tests Fail

**Issue**: `ModuleNotFoundError`
**Solution**: Install dependencies: `pip install -r tests/requirements.txt`

**Issue**: `pytest: command not found`
**Solution**: Install pytest: `pip install pytest pytest-cov pytest-mock`

### SQL Validation Errors

**Issue**: `Invalid BigQuery dialect`
**Solution**: Use `--dialect bigquery` flag in sqlfluff

**Issue**: `Table not found` in dry-run
**Solution**: Queries should reference dataset structures only

---

## Future Enhancements

### Phase 11+ Roadmap

1. **Docker Build Pipeline**
   - Container image builds for Cloud Functions
   - Push to Artifact Registry

2. **Integration Tests**
   - End-to-end pipeline testing
   - GCP integration tests
   - Power BI refresh testing

3. **Performance Testing**
   - ETL performance benchmarks
   - Query optimization testing
   - Load testing for production

4. **Notifications**
   - Slack workflow notifications
   - Email alerts on failures
   - Deployment status updates

5. **Infrastructure Testing**
   - Pulumi/Terratest testing
   - Policy validation
   - Cost estimation

---

## Files Modified

```
.github/
├── workflows/
│   ├── terraform-validate.yml      # ✓ Created
│   ├── python-test.yml             # ✓ Created
│   ├── sql-validate.yml            # ✓ Created
│   ├── terraform-deploy.yml        # ✓ Created
│   └── pr-checks.yml               # ✓ Created

tests/
├── test_etl.py                     # ✓ Enhanced (27 tests)
└── requirements.txt                # ✓ Created

phase_11_cicd_pipeline.md           # ✓ This file
```

---

## Quick Links

- **GitHub Actions**: https://github.com/<owner>/<repo>/actions
- **Workflow Runs**: https://github.com/<owner>/<repo>/actions
- **PR Checks**: View in PR #
- **Deployment Runs**: Actions → Terraform Deploy

---

## Summary

Phase 11 transforms the NYC Taxi Analytics Platform into a production-grade system with:

✅ **Automated Validation**: All code changes automatically tested
✅ **Infrastructure as Code**: Terraform changes reviewed and applied safely
✅ **Continuous Testing**: Unit tests, linting, security scanning
✅ **Controlled Deployments**: Manual approval gates for prod
✅ **Quality Assurance**: 27+ unit tests covering core functionality
✅ **Documentation**: Self-documenting through code comments

The platform is now ready for team collaboration, regular updates, and production operation with full audit trails and rollback capabilities.
