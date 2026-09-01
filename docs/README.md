# Hospital360 Documentation

This index links to the detailed technical and analytical documentation for the synthetic Hospital360 portfolio platform.

## Architecture

- [Architecture summary](architecture/README.md)
- [Database foundation](architecture/database_foundation.md)
- [Healthcare source-to-target mapping](architecture/synthea_v1_source_to_target_mapping.md)
- [RAW layer design](architecture/raw_layer_design.md) and [RAW ingestion](architecture/raw_ingestion.md)
- [STAGING layer design](architecture/staging_layer_design.md)
- [Healthcare analytics star schema](architecture/analytics_star_schema.md)
- [Enterprise extension implementation](architecture/enterprise_implementation.md)
- [Enterprise star schema](architecture/enterprise_star_schema.md)

## Data Model

- [Analytics columns](architecture/analytics_columns.md)
- [Analytics relationships reference](architecture/analytics_relationships_reference.md)
- [Enterprise extension design](architecture/enterprise_extension_design.md)
- [Enterprise generation rules](architecture/enterprise_generation_rules.md)

## Data Dictionaries

- [Synthea initial profile](data_dictionary/synthea_initial_profile.md)
- [Enterprise data dictionary](data_dictionary/enterprise_data_dictionary.md)

## KPI Dictionaries

- [Power BI KPI dictionary](kpi_dictionary/powerbi_kpi_dictionary.md)
- [Enterprise KPI dictionary](kpi_dictionary/enterprise_kpi_dictionary.md)

## SQL Analysis

- [SQL analysis framework](insights/sql_analysis_framework.md)
- [Validated 5K SQL findings](insights/sql_5k_findings.md)
- [Enterprise SQL findings](insights/enterprise_sql_findings.md)

## Python Analysis

- [Healthcare Python findings](insights/python_eda_findings.md)
- [Enterprise Python findings](insights/enterprise_python_findings.md)
- [Enterprise EDA notebook](../notebooks/02_enterprise_performance_eda.ipynb)

## Power BI

- [Final report inventory](architecture/powerbi_final_report_inventory.md)
- [Enterprise Power BI inventory](architecture/enterprise_powerbi_inventory.md)
- [Manual polish milestone](architecture/powerbi_manual_polish.md)
- [Screenshot checklist](screenshots/README.md)

## Data Quality

- [Initial Synthea profile](data_dictionary/synthea_initial_profile.md)
- [STAGING validation design](architecture/staging_layer_design.md)
- [Data Quality & Analytical Limitations page inventory](architecture/powerbi_final_report_inventory.md)

## Enterprise Extension

- [Implementation and validation](architecture/enterprise_implementation.md)
- [Data volume plan](architecture/enterprise_data_volume_plan.md)
- [Generation rules](architecture/enterprise_generation_rules.md)

## Validation and Scalability

- [Portfolio scale validation](architecture/portfolio_scale_validation.md)
- [Setup and run guide](SETUP.md)
