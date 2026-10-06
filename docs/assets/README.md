# Presentation Assets

This directory contains presentation-only visual assets for Hospital360.

## Intended use

The primary project overview image stored here is used by the repository README to explain the end-to-end analytical architecture at a glance.

Recommended filename for the current overview:

`hospital360_healthcare_analytics_infographic.png`

The overview should represent only repository-supported claims, including:

- synthetic healthcare and enterprise data only;
- Synthea healthcare sources plus the deterministic enterprise generator;
- RAW → STAGING / Data Quality → analytics star schemas;
- PostgreSQL, SQL, Python analytics, and Power BI;
- validated 5,000-patient working dataset;
- documented 20,000-patient scalability test boundary;
- healthcare and enterprise analytical domains;
- release validation and reconciliation evidence.

## Evidence boundary

Assets in this directory are presentation summaries only. They are not analytical source data, database evidence, Power BI screenshots, or replacements for governed documentation.

Authoritative project claims remain defined by the repository source code, SQL, Power BI PBIP/PBIR/TMDL files, validated screenshots, architecture documents, data-quality evidence, and reproducibility records.
