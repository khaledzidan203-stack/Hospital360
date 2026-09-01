# Hospital360 Setup and Run Guide

This guide describes a local Windows portfolio environment. Generated data and credentials remain outside Git.

## Prerequisites

- Python 3
- PostgreSQL 16 with `psql`
- Power BI Desktop with PBIP/PBIR support
- Git
- Java 21 only when regenerating Synthea data

## 1. Clone and enter the repository

```powershell
git clone <repository-url> Hospital360
Set-Location Hospital360
```

## 2. Create the Python environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

## 3. Configure local database credentials

```powershell
Copy-Item .env.example .env
```

Edit `.env` locally with the PostgreSQL user and password. `.env` is ignored and must never be committed.

## 4. Prepare PostgreSQL

Create a local database named `hospital360` and the schemas `raw`, `staging`, and `analytics`. See [database foundation](architecture/database_foundation.md).

The project SQL runner reads connection settings from `.env` and invokes the installed `psql` client without printing the password:

```powershell
python -m src.data_generation.enterprise.run_sql sql/ddl/001_create_raw_synthea_tables.sql
```

## 5. Obtain or regenerate synthetic sources

Large RAW datasets are not stored in Git. The accepted healthcare source is a locally generated Synthea CSV snapshot. See [portfolio scale validation](architecture/portfolio_scale_validation.md) and [Synthea mapping](architecture/synthea_v1_source_to_target_mapping.md) before regenerating it.

The deterministic enterprise snapshot can be regenerated after the healthcare analytics layer exists:

```powershell
python -m src.data_generation.enterprise.generate_enterprise --profile FINAL_36M
```

## 6. Run the healthcare SQL pipeline

Run these existing scripts in order:

```powershell
python -m src.data_generation.enterprise.run_sql `
  sql/ddl/001_create_raw_synthea_tables.sql `
  sql/staging/001_load_raw_synthea.sql `
  sql/staging/002_create_staging_synthea_tables.sql `
  sql/staging/004_create_staging_performance_indexes.sql `
  sql/staging/005_transform_raw_to_staging_v2.sql `
  sql/marts/001_create_analytics_star_schema.sql `
  sql/marts/002_load_analytics_star_schema.sql
```

Use `sql/staging/006_validate_staging_v1_v2_parity.sql` for bounded V1/V2 parity validation where applicable.

## 7. Run the enterprise SQL pipeline

```powershell
python -m src.data_generation.enterprise.run_sql `
  sql/ddl/002_create_raw_enterprise_tables.sql `
  sql/staging/007_load_raw_enterprise.sql `
  sql/staging/008_create_enterprise_staging_tables.sql `
  sql/staging/009_transform_enterprise_raw_to_staging.sql `
  sql/marts/003_create_enterprise_star_schema.sql `
  sql/marts/004_load_enterprise_star_schema.sql `
  sql/analysis/enterprise_validation.sql
```

Analysis scripts under [`sql/analysis/`](../sql/analysis/) are read-only.

## 8. Run Python EDA

```powershell
python -m src.analytics.notebook_runner notebooks/01_hospital360_eda.ipynb
python -m src.analytics.notebook_runner notebooks/02_enterprise_performance_eda.ipynb
```

The database connector accepts SELECT/WITH queries only and enables PostgreSQL read-only transaction mode.

## 9. Open the Power BI project

Open `powerbi/Hospital360.pbip` in Power BI Desktop. The PBIP/PBIR source is version controlled; PBIX binaries and local Power BI cache files are ignored.

## Validation Notes

- Run pipeline stages only after their source prerequisites exist.
- Reconcile source and target row counts before continuing.
- Do not treat Synthea claim values as hospital revenue or profit.
- Never commit `.env`, generated RAW data, PBIX files, or local database artifacts.
