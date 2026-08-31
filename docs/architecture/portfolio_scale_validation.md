# Hospital360 Portfolio Scale Validation

## Status

Validated local portfolio baseline: exactly 5,000 synthetic patients through RAW, STAGING V2, Analytics V1, and SQL regression.

## 20,000-Patient Scale Test Finding

An earlier overflow-enabled 20,000-patient generation attempt did not satisfy the exact-patient acceptance gate and was rejected. A subsequent clean generation with overflow disabled produced exactly 20,000 patients and was accepted for the scale test described below.

- Synthea successfully generated and the project accepted a clean dataset containing exactly 20,000 patient rows with overflow disabled.
- The six approved RAW sources loaded successfully at portfolio scale. The RAW load completed in 1,391.62 seconds and reconciled to the accepted source counts.
- The STAGING transformation exposed a severe scalability bottleneck while processing the claims staging insert.
- The claims staging query remained active for multiple hours and did not complete the 20,000-patient pipeline.
- PostgreSQL activity identified the query as active with `DataFileRead` I/O waits and zero blocking backends.
- The 20,000-patient pipeline therefore must not be described as completed.
- The final local-development dataset target was reduced to exactly 5,000 patients to keep the pipeline practical on the current Windows development machine.

This is a scale and performance decision, not evidence of a data-correctness failure.

## Completed Validation Gates

The clean 5,000-patient snapshot was accepted, loaded through RAW, transformed through STAGING V2, loaded into Analytics V1, and exercised by the complete SQL regression framework.

## Accepted 5,000-Patient Source Snapshot

Status: Accepted and validated through the current SQL analytics layer.

- Generation configuration: population `5000`, overflow disabled with `-o false`, patient seed `20260830`, and clinician seed `20260830`.
- Export configuration: CSV enabled; patient FHIR, CCDA, and JSON exports disabled.
- Generation result: `BUILD SUCCESSFUL`, exit code `0`, duration `851.73` seconds.
- Patient acceptance: exactly `5,000` data rows excluding the header.
- CSV file count: `18`.
- Total generated dataset size: `3,060,641,978` bytes.
- Core V1 source rows:
  - patients: `5,000`
  - encounters: `253,563`
  - claims: `435,751`
  - claim transactions: `3,966,064`
  - conditions: `159,348`
  - procedures: `696,202`

The prior generated output directories were cleared before this run, so the accepted snapshot is one clean generation and is not mixed with a prior dataset. Synthea also emitted one run-metadata file and its supplemental hospital/practitioner reference JSON files; it did not emit patient FHIR bundles.

## RAW Validation

- Source-to-RAW reconciliation difference: `0` for every Core V1 source.
- Total RAW rows: `5,515,928`.
- Core table counts: patients `5,000`; encounters `253,563`; claims `435,751`; claim transactions `3,966,064`; conditions `159,348`; procedures `696,202`.

## STAGING Performance V2

V1 was preserved unchanged. V2 retained the same typing and data-quality rules while improving execution through bulk typed loads, supporting indexes, narrow duplicate checks, and indexed reference validation.

- Controlled V1/V2 parity rows compared: `17,165`.
- Row, typed-value, DQ-flag, and row-hash differences: `0`.
- Business-logic changes: `0`.
- DQ rules removed: `0`.
- Full 5K runtime: `22:01.604`.
- Total STAGING rows: `5,515,928`.
- RAW-to-STAGING differences: `0` across all six tables.
- Conversion errors, duplicate flags, and broken required references: `0`.

## Analytics Validation

The existing Analytics V1 model loaded without redesign.

- Dimension rows including Unknown member where defined: date `40,516`; patient `5,001`; provider `976`; organization `976`; payer `11`; condition `296`; procedure `393`.
- Fact rows: encounter `253,563`; claim `435,751`; claim transaction `3,966,064`; condition occurrence `159,348`; procedure `696,202`.
- Staging-to-fact differences: `0` for all five facts.
- Duplicate surrogate keys: `0`.
- Fact-grain duplicates: `0`.
- Broken non-null dimension lookups: `0`.
- Direct fact-to-fact foreign keys: `0`.
- Dim_Date continuity gaps: `0`.
- All validated financial reconciliation differences: `0.00`.

## SQL Regression

All existing SQL analysis files were executed unchanged against the 5K analytics model.

- Analytical queries: `35`.
- Validation queries: `12`.
- Total queries: `47`.
- Successful queries: `47`.
- Failed queries: `0`.
- Validation failures: `0`.
- Amount multiplication detected: `No`.
- Fact-count changes caused by the analysis: `0`.
- Database modifications caused by the analysis: `0`.
- Measured end-to-end orchestration runtime: `242.456` seconds.

## Remaining Data-Quality Question

- Synthea sentinel transaction stop timestamps: `317,271`; their known sentinel semantics remain preserved.
- Non-sentinel transaction date-order warnings: `547`.
- The non-sentinel cases span `CHARGE`, `PAYMENT`, `TRANSFERIN`, and `TRANSFEROUT`, with observed differences from `-1` to `-6` days.
- Status: **To Be Validated**. No dates were corrected, swapped, rejected, or silently reclassified.

## Readiness

The database pipeline and SQL analytical framework are validated at the selected local portfolio scale. The project is ready to proceed to Python EDA, subject to preserving the documented synthetic-data limitations and the unresolved 547 non-sentinel transaction date-order warnings.
