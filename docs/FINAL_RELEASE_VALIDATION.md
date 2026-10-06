# Hospital360 Final Release Validation

## Release identity

Hospital360 is a synthetic healthcare and hospital-enterprise analytics implementation using PostgreSQL, SQL, Python, and a source-controlled Power BI PBIP/PBIR/TMDL project.

All patient, claim, finance, workforce, operations, and technology records are synthetic. No real hospital or patient data is included.

## Current integrated release

- Healthcare working baseline: **5,000 synthetic patients**.
- Healthcare RAW total: **5,515,928 rows**.
- Healthcare analytical facts: **5**.
- Enterprise extension: **36 months**, **25,716 rows**, **6 facts**.
- Current Power BI report: **13 pages**, **12 Home navigation tiles**.
- Representative committed screenshots: **7**.

## Retained runtime evidence

The project documentation records the following validated runtime results from the accepted working environment:

- source-to-RAW differences: **0** for the six approved healthcare sources;
- RAW-to-STAGING differences: **0**;
- STAGING-to-fact differences: **0**;
- duplicate surrogate keys: **0**;
- duplicate fact grains: **0**;
- broken non-null dimension lookups: **0**;
- validated financial reconciliation differences: **0.00**;
- SQL regression: **47/47 queries successful**, **0 validation failures**;
- enterprise final profile: **PASS**, **25,716 fact rows**;
- enterprise DQ: **0 fatal errors**, **633 warnings**, **1,257 retained business anomalies**.

These runtime results are retained evidence from the validated local environment; repository CI does not claim to recreate the multi-gigabyte database or Power BI Desktop runtime.

## Repository quality gate

GitHub Actions now runs clone-safe checks on pushes and pull requests:

1. protect validated SQL/Python/Power BI/screenshot paths from unmarked accidental edits;
2. validate the repository presentation and structural contract;
3. confirm the saved PBIR contains 13 pages;
4. confirm the seven representative screenshots remain present;
5. run clone-safe unit tests;
6. compile Python sources.

The local RAW-manifest acceptance assertion is skipped only when the ignored generated RAW manifest is not available in a clean clone.

## Preserved analytical core

The 2026-10-06 repository hardening pass did **not** rewrite:

- SQL transformation or analytical logic;
- active Python analytical / generation logic;
- PBIP/PBIR/TMDL report and semantic-model source;
- DAX measures;
- validated screenshots;
- validated analytical results.

The only executable test change makes the existing local RAW-manifest assertion safe for clean-clone CI while preserving the assertion when that local evidence exists.

## Power BI model-hygiene item

The saved model contains a governed `analytics dim_date`, while Auto Date/Time remains enabled and generated LocalDateTable objects are present. This is documented in `architecture/POWER_BI_TIME_INTELLIGENCE_AUDIT.md`.

No destructive TMDL cleanup is claimed. Safe removal requires Power BI Desktop dependency checks, refresh, DAX regression, navigation/visual regression, and refreshed evidence.

## Scalability boundary

The 20,000-patient test successfully generated a clean source and loaded the approved RAW tables, but the full pipeline did not complete because the STAGING claims transformation exposed a prolonged I/O bottleneck. Hospital360 therefore does not present 20K as a completed analytical release.

The validated working release remains the complete 5,000-patient pipeline.

## Release conclusion

The repository presentation, documentation chronology, clone-safe testing, CI, and evidence mapping are aligned with the current integrated implementation. Known technical limitations are explicitly disclosed rather than hidden or silently rewritten.
