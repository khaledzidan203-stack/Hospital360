# Hospital360 Documentation

This index separates the current integrated release from historical healthcare-baseline records and links the evidence needed to understand, reproduce, and validate the project.

## Start here

- [Project index](PROJECT_INDEX.md)
- [Case study](CASE_STUDY.md)
- [Technical walkthrough](TECHNICAL_WALKTHROUGH.md)
- [Project evidence map](PROJECT_EVIDENCE_MAP.md)
- [Setup and run guide](SETUP.md)
- [Environment baseline](ENVIRONMENT_BASELINE.md)
- [Repository structure notes](REPOSITORY_STRUCTURE_NOTES.md)

## Architecture

- [Architecture summary](architecture/README.md)
- [Database foundation](architecture/database_foundation.md)
- [Healthcare source-to-target mapping](architecture/synthea_v1_source_to_target_mapping.md)
- [RAW layer design](architecture/raw_layer_design.md) and [RAW ingestion](architecture/raw_ingestion.md)
- [STAGING layer design](architecture/staging_layer_design.md)
- [Healthcare analytics star schema](architecture/analytics_star_schema.md)
- [Enterprise extension implementation](architecture/enterprise_implementation.md)
- [Enterprise star schema](architecture/enterprise_star_schema.md)
- [Power BI time-intelligence audit](architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md)

## Data model and dictionaries

- [Analytics columns](architecture/analytics_columns.md)
- [Analytics relationships reference](architecture/analytics_relationships_reference.md)
- [Enterprise extension design](architecture/enterprise_extension_design.md)
- [Enterprise generation rules](architecture/enterprise_generation_rules.md)
- [Synthea initial profile](data_dictionary/synthea_initial_profile.md)
- [Enterprise data dictionary](data_dictionary/enterprise_data_dictionary.md)

## KPI contracts

- [Healthcare / Power BI KPI dictionary](kpi_dictionary/powerbi_kpi_dictionary.md)
- [Enterprise KPI dictionary](kpi_dictionary/enterprise_kpi_dictionary.md)

## SQL and Python analysis

- [SQL analysis framework](insights/sql_analysis_framework.md)
- [Validated 5K SQL findings](insights/sql_5k_findings.md)
- [Enterprise SQL findings](insights/enterprise_sql_findings.md)
- [Healthcare Python findings](insights/python_eda_findings.md)
- [Enterprise Python findings](insights/enterprise_python_findings.md)
- [Enterprise EDA notebook](../notebooks/02_enterprise_performance_eda.ipynb)

## Power BI current release and history

- **Current integrated release:** 13 pages / 12 Home tiles — see [Enterprise Power BI inventory](architecture/enterprise_powerbi_inventory.md) and saved PBIR source.
- **Historical healthcare baseline:** 9 pages / 8 Home tiles — [Healthcare baseline report inventory](architecture/powerbi_final_report_inventory.md).
- [Manual polish milestone](architecture/powerbi_manual_polish.md)
- [Representative screenshot gallery](screenshots/README.md)

The nine-page inventory is intentionally retained as the pre-enterprise healthcare baseline; it should not be read as the current total page count.

## Data quality, validation, and scalability

- [STAGING validation design](architecture/staging_layer_design.md)
- [Enterprise implementation and DQ results](architecture/enterprise_implementation.md)
- [5K validation and 20K scale-test boundary](architecture/portfolio_scale_validation.md)
- [Repository-safe vs local acceptance tests](../tests/README.md)

## Presentation assets

- [Presentation asset policy](assets/README.md)

Presentation assets summarize the system visually but are not primary validation evidence.
