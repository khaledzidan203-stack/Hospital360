# Hospital360 RAW Ingestion

## Objective

Load the six approved Synthea V1 CSV snapshots into their corresponding PostgreSQL `raw` tables while preserving the source structure and values as closely as possible.

RAW ingestion performs no business transformation.

## Sources Loaded

| Source file | SHA-256 before load | CSV data rows |
|---|---|---:|
| `patients.csv` | `E2B97FF261A76E807977346251BBC2697D95D15E1C2E07237532CEF84CC34A20` | 10 |
| `encounters.csv` | `39C34A274F47D8778FB370279786FBD6916CC13E4FFA027CFA65F239C81660D6` | 283 |
| `claims.csv` | `E7A535941E0F4584137F3E5CBF3415805AAD64F5AFDA0D325DF6AB51161278AE` | 464 |
| `claims_transactions.csv` | `A2082305E14A63F50B16A46BDE4152DD4BBE3EB2B3806AF4A5A41F306338BA47` | 5,403 |
| `conditions.csv` | `DB08D284A97D1A8A01660EDF757E5B2217556AA11B08B148AAA1DD7DD5D554FD` | 252 |
| `procedures.csv` | `C5BBF2F0D13DB24A25A653FD03E94F0712719FED9EB1D20D998E31D69FF55EC5` | 1,003 |

## Target Tables

| Source file | PostgreSQL target |
|---|---|
| `patients.csv` | `raw.synthea_patients` |
| `encounters.csv` | `raw.synthea_encounters` |
| `claims.csv` | `raw.synthea_claims` |
| `claims_transactions.csv` | `raw.synthea_claims_transactions` |
| `conditions.csv` | `raw.synthea_conditions` |
| `procedures.csv` | `raw.synthea_procedures` |

## Load Method

The psql script `sql/staging/001_load_raw_synthea.sql` uses client-side `\copy` with `FORMAT csv`, `HEADER true`, and UTF-8 encoding. Client-side loading allows the Windows psql process to read the local source paths. All target column lists are explicit and retain the exact source column names.

Although the script is stored in the project's `sql/staging` script directory, it writes only to the PostgreSQL `raw` schema. The six loads run in one transaction with `ON_ERROR_STOP` enabled so a load failure prevents a partial snapshot from being committed.

## Reload Strategy

The current development snapshot pattern is deterministic truncate-and-reload. Immediately before loading each source, the script truncates only that source's corresponding raw table and then reloads it with `\copy`. It does not drop tables or delete rows individually. Rerunning the script therefore replaces the current six-table development snapshot without accumulating duplicates.

## Row Count Reconciliation

| Source | CSV rows | PostgreSQL rows | Difference | Status |
|---|---:|---:|---:|---|
| `patients.csv` | 10 | 10 | 0 | Passed |
| `encounters.csv` | 283 | 283 | 0 | Passed |
| `claims.csv` | 464 | 464 | 0 | Passed |
| `claims_transactions.csv` | 5,403 | 5,403 | 0 | Passed |
| `conditions.csv` | 252 | 252 | 0 | Passed |
| `procedures.csv` | 1,003 | 1,003 | 0 | Passed |
| **Total** | **7,415** | **7,415** | **0** | **Passed** |

## Validation Checks

Pre-load validation confirmed that all six files existed, all target tables contained zero rows, and each ordered CSV header matched the corresponding target column structure exactly.

Post-load checks produced the following results:

- Patients: 10 rows, 10 distinct `Id` values, and 0 missing `Id` values.
- Encounters: 283 rows, 283 distinct `Id` values, 0 missing `Id` values, and 0 missing `PATIENT` values.
- Claims: 464 rows, 464 distinct `Id` values, and 0 missing `Id` values.
- Claim transactions: 5,403 rows and 0 missing `ID` values.
- Conditions: 252 rows.
- Procedures: 1,003 rows.
- No base tables were created in the `staging` or `analytics` schemas.

## Source Integrity

The six source CSV files were read without modification. SHA-256 hashes were recorded before execution and rechecked after execution; unchanged hashes demonstrate byte-for-byte source integrity for this ingestion run.

## Known Limitations

- This is a local development snapshot load, not an incremental or production ingestion process.
- PostgreSQL CSV parsing represents unquoted empty fields as null; no downstream cleaning or interpretation is performed in the raw load.
- Raw tables intentionally defer primary-key, foreign-key, typing, and business-quality enforcement to later layers.
- Row-count equality and source hashes validate load completeness and source integrity, but do not replace future field-level reconciliation and data-quality controls.

## Next Step

Design and validate the staging layer separately. No staging or analytics data tables were created by this ingestion step.
