# Hospital360 STAGING Layer Design

## Purpose

The Hospital360 staging layer converts the approved Synthea V1 raw snapshot into typed, consistently named, and explicitly validated tables without changing the business grain or removing source rows.

**RAW = source-preserving**  
**STAGING = typed + normalized + validated**  
**ANALYTICS = not yet implemented**

All data is synthetic Synthea data and must not be represented as real hospital or patient performance.

## Difference Between RAW and STAGING

| Layer | Responsibility |
|---|---|
| RAW | Preserve the six source CSV structures, original column names, lexical values, nulls, and row counts. All raw columns are nullable PostgreSQL `text`. |
| STAGING | Preserve each source row while applying safe semantic types, snake_case names, surrounding-whitespace trimming, empty-to-null normalization, lineage fields, and explicit quality flags. |
| ANALYTICS | Future curated dimensional/star-schema objects and business metrics. No analytics tables are implemented by this design. |

Staging does not aggregate, deduplicate, join facts, apply KPI logic, enforce final dimensional foreign keys, or modify raw data.

## Source-to-Staging Mapping

| Raw source | Staging target | Rows validated |
|---|---|---:|
| `raw.synthea_patients` | `staging.stg_patients` | 10 |
| `raw.synthea_encounters` | `staging.stg_encounters` | 283 |
| `raw.synthea_claims` | `staging.stg_claims` | 464 |
| `raw.synthea_claims_transactions` | `staging.stg_claim_transactions` | 5,403 |
| `raw.synthea_conditions` | `staging.stg_condition_occurrences` | 252 |
| `raw.synthea_procedures` | `staging.stg_procedures` | 1,003 |

The following specifications cover every approved raw column. Every raw input is nullable `text`; target columns remain nullable so invalid or missing values do not cause row loss.

### Patients column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `Id` | `patient_id` | `text` | Source identifier; 0 null, 10 distinct. Kept as text for exact lineage and source-version compatibility. |
| `BIRTHDATE`, `DEATHDATE` | `birth_date`, `death_date` | `date` | Clinical dates. BIRTHDATE has 0 null; DEATHDATE has 10 null. |
| `SSN`, `DRIVERS`, `PASSPORT` | `ssn`, `drivers_license`, `passport_number` | `text` | Source identifiers. Null counts: 0, 3, and 4. |
| `PREFIX`, `FIRST`, `MIDDLE`, `LAST`, `SUFFIX`, `MAIDEN` | `name_prefix`, `first_name`, `middle_name`, `last_name`, `name_suffix`, `maiden_name` | `text` | Name attributes. Null counts: 3, 0, 2, 0, 10, and 9. |
| `MARITAL`, `RACE`, `ETHNICITY`, `GENDER` | `marital_status`, `race`, `ethnicity`, `gender` | `text` | Demographic attributes. Null counts: 6, 0, 0, and 0. |
| `BIRTHPLACE`, `ADDRESS`, `CITY`, `STATE`, `COUNTY` | same semantic snake_case names | `text` | Location attributes; 0 null. Internal whitespace is not collapsed. |
| `FIPS`, `ZIP` | `fips`, `zip` | `text` | Geographic codes; FIPS has 3 null and ZIP has 0. Text preserves leading zeros such as ZIP `00000`. |
| `LAT`, `LON` | `latitude`, `longitude` | `numeric` | Coordinates; 0 null and 0 invalid conversions. |
| `HEALTHCARE_EXPENSES`, `HEALTHCARE_COVERAGE`, `INCOME` | `healthcare_expenses`, `healthcare_coverage`, `income` | `numeric` | Source measures; 0 null and 0 invalid conversions. They are not treated as final additive KPIs. |

### Encounters column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `Id` | `encounter_id` | `text` | Source identifier; 0 null, 283 distinct. |
| `START`, `STOP` | `start_at`, `stop_at` | `timestamptz` | Event timestamps; 0 null and 0 invalid conversions. Source `Z` offsets preserve the instant. |
| `PATIENT`, `ORGANIZATION`, `PROVIDER`, `PAYER` | `patient_id`, `organization_id`, `provider_id`, `payer_id` | `text` | Source references; all populated. Only patient is validated against an in-scope staging table in V1. |
| `ENCOUNTERCLASS` | `encounter_class` | `text` | Reusable encounter classification attribute; 0 null. |
| `CODE`, `DESCRIPTION` | `encounter_code`, `encounter_description` | `text` | Encounter concept code and label; 0 null. Code remains text. |
| `BASE_ENCOUNTER_COST`, `TOTAL_CLAIM_COST`, `PAYER_COVERAGE` | snake_case equivalents | `numeric` | Encounter-grain measures; 0 null and 0 invalid conversions. |
| `REASONCODE`, `REASONDESCRIPTION` | `reason_code`, `reason_description` | `text` | Optional clinical reason; each has 164 null. |

### Claims column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `Id` | `claim_id` | `text` | Claim-header identifier; 0 null, 464 distinct. |
| `PATIENTID`, `PROVIDERID` | `patient_id`, `provider_id` | `text` | Source references; 0 null. |
| `PRIMARYPATIENTINSURANCEID`, `SECONDARYPATIENTINSURANCEID` | `primary_patient_insurance_id`, `secondary_patient_insurance_id` | `text` | Optional insurance references; 124 and 434 null. |
| `DEPARTMENTID`, `PATIENTDEPARTMENTID` | `department_id`, `patient_department_id` | `integer` | Observed integer administrative classifications; 0 null and 0 invalid conversions. |
| `DIAGNOSIS1` through `DIAGNOSIS8` | `diagnosis_1` through `diagnosis_8` | `text` | Diagnosis code slots. Null counts are 0, 262, 399, 449, 463, 463, 464, and 464. Codes remain text. |
| `REFERRINGPROVIDERID` | `referring_provider_id` | `text` | Optional provider reference; all 464 values are null. |
| `APPOINTMENTID` | `appointment_id` | `text` | Candidate / To Be Validated encounter reference; 464/464 values matched staged encounter IDs. |
| `CURRENTILLNESSDATE`, `SERVICEDATE` | `current_illness_at`, `service_at` | `timestamptz` | Claim timestamps; 0 null and 0 invalid conversions. |
| `SUPERVISINGPROVIDERID` | `supervising_provider_id` | `text` | Source provider reference; 0 null. |
| `STATUS1`, `STATUS2`, `STATUSP` | `status_1`, `status_2`, `status_primary` | `text` | Claim status attributes; STATUS2 has 30 null, the others 0. |
| `OUTSTANDING1`, `OUTSTANDING2`, `OUTSTANDINGP` | `outstanding_1`, `outstanding_2`, `outstanding_primary` | `numeric` | Claim-header balances; OUTSTANDING2 has 30 null, the others 0. No financial aggregation semantics are imposed. |
| `LASTBILLEDDATE1`, `LASTBILLEDDATE2`, `LASTBILLEDDATEP` | `last_billed_at_1`, `last_billed_at_2`, `last_billed_at_primary` | `timestamptz` | Billing timestamps; LASTBILLEDDATE2 has 30 null, the others 0. |
| `HEALTHCARECLAIMTYPEID1`, `HEALTHCARECLAIMTYPEID2` | `healthcare_claim_type_id_1`, `healthcare_claim_type_id_2` | `integer` | Observed integer classifications; 0 null and 0 invalid conversions. |

### Claim transactions column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `ID` | `transaction_id` | `text` | Transaction/event-line identifier; 0 null, 5,403 distinct. |
| `CLAIMID`, `PATIENTID` | `claim_id`, `patient_id` | `text` | Required observed references; 0 null and all values resolved. |
| `CHARGEID` | `charge_id` | `text` | Source line identifier. Kept as text because identifier semantics are not final. |
| `TYPE` | `transaction_type` | `text` | Observed values: CHARGE, PAYMENT, TRANSFERIN, TRANSFEROUT. No financial sign or KPI logic is applied. |
| `AMOUNT` | `amount` | `numeric` | Transaction measure; 2,767 null and 0 invalid conversions. |
| `METHOD` | `method` | `text` | Optional payment method; 3,631 null. |
| `FROMDATE`, `TODATE` | `from_at`, `to_at` | `timestamptz` | Transaction timestamps; 0 null and 0 invalid conversions. |
| `PLACEOFSERVICE` | `place_of_service_id` | `text` | Organization/place reference; 0 null. Supporting organization staging is out of scope. |
| `PROCEDURECODE` | `procedure_code` | `text` | Procedure/source code; 0 null. Text preserves values such as `03`. |
| `MODIFIER1`, `MODIFIER2` | `modifier_1`, `modifier_2` | `text` | Optional modifiers; both entirely null in this extract. |
| `DIAGNOSISREF1` through `DIAGNOSISREF4` | `diagnosis_ref_1` through `diagnosis_ref_4` | `integer` | Diagnosis-slot positions. Null counts: 0, 3,509, 4,861, and 5,286; 0 invalid conversions. |
| `UNITS` | `units` | `numeric` | Quantity measure; 0 null and 0 invalid conversions. Numeric permits future fractional units. |
| `DEPARTMENTID` | `department_id` | `integer` | Observed integer classification; 0 null and 0 invalid conversions. |
| `NOTES` | `notes` | `text` | Source description/line narrative; 0 null. No internal-text normalization is applied. |
| `UNITAMOUNT` | `unit_amount` | `numeric` | Source measure; 0 null and 0 invalid conversions. |
| `TRANSFEROUTID` | `transfer_out_id` | `text` | Optional source identifier; 4,408 null. Kept as text pending semantic validation. |
| `TRANSFERTYPE` | `transfer_type` | `text` | Optional source classification; 2,767 null and includes nonnumeric value `p`. |
| `PAYMENTS`, `ADJUSTMENTS`, `TRANSFERS`, `OUTSTANDING` | snake_case equivalents | `numeric` | Financial movement fields. TRANSFERS has 3,413 null; the others 0. All have 0 invalid conversions. |
| `APPOINTMENTID` | `appointment_id` | `text` | Candidate / To Be Validated encounter reference; all 5,403 values resolved. |
| `LINENOTE` | `line_note` | `text` | Optional source narrative; entirely null in this extract. |
| `PATIENTINSURANCEID` | `patient_insurance_id` | `text` | Optional insurance/member reference; 756 null. |
| `FEESCHEDULEID` | `fee_schedule_id` | `text` | Source identifier/classification; 0 null. Kept as text pending semantic validation. |
| `PROVIDERID`, `SUPERVISINGPROVIDERID` | `provider_id`, `supervising_provider_id` | `text` | Source provider references; 0 null. |

### Conditions column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `START`, `STOP` | `start_date`, `stop_date` | `date` | Episode dates. START has 0 null; STOP has 68 null for open/ongoing occurrences. No conversion failures. |
| `PATIENT`, `ENCOUNTER` | `patient_id`, `encounter_id` | `text` | Source references; 0 null and all values resolved. |
| `SYSTEM`, `CODE`, `DESCRIPTION` | `code_system`, `condition_code`, `condition_description` | `text` | Condition concept fields; 0 null. Codes remain text. |

### Procedures column specification

| Raw column(s) | Staging column(s) | Target type | Role and observed null behavior |
|---|---|---|---|
| `START`, `STOP` | `start_at`, `stop_at` | `timestamptz` | Procedure event timestamps; 0 null and 0 conversion failures. |
| `PATIENT`, `ENCOUNTER` | `patient_id`, `encounter_id` | `text` | Source references; 0 null and all values resolved. |
| `SYSTEM`, `CODE`, `DESCRIPTION` | `code_system`, `procedure_code`, `procedure_description` | `text` | Procedure concept fields; 0 null. Codes remain text. |
| `BASE_COST` | `base_cost` | `numeric` | Procedure-grain source measure; 0 null and 0 conversion failures. |
| `REASONCODE`, `REASONDESCRIPTION` | `reason_code`, `reason_description` | `text` | Optional reason; each has 633 null. |

No boolean-like source fields were observed. All staging Boolean columns are validation flags derived from source structure and values.

## Grain

- `staging.stg_patients`: **One row = one row from `raw.synthea_patients`, representing one synthetic patient candidate.**
- `staging.stg_encounters`: **One row = one row from `raw.synthea_encounters`, representing one encounter event.**
- `staging.stg_claims`: **One row = one row from `raw.synthea_claims`, representing one claim header.**
- `staging.stg_claim_transactions`: **One row = one row from `raw.synthea_claims_transactions`, representing one claim transaction/event line.**
- `staging.stg_condition_occurrences`: **One row = one row from `raw.synthea_conditions`, representing one recorded condition occurrence/episode.**
- `staging.stg_procedures`: **One row = one row from `raw.synthea_procedures`, representing one performed procedure occurrence.**

The transformation does not silently deduplicate. Candidate key duplication is flagged, not removed or prevented.

## Data Type Standardization

- ISO dates become PostgreSQL `date`.
- ISO timestamps with `Z` offsets become `timestamp with time zone` (`timestamptz`).
- Monetary values, coordinates, quantities, and units become unconstrained PostgreSQL `numeric` to avoid premature precision loss.
- Clearly observed integer administrative classifications and diagnosis-slot positions become `integer`.
- Source identifiers and clinical/administrative codes remain `text`, including UUID-shaped values. This preserves leading zeros and avoids imposing final identifier semantics in staging.
- Every conversion first uses PostgreSQL 16 `pg_input_is_valid`. Invalid nonblank input becomes typed null and its source column name is added to `dq_conversion_errors`.
- Profiling and executed validation found zero invalid conversions in the current 7,415-row snapshot.

## Normalization Rules

1. Apply `btrim` to remove obvious surrounding whitespace from text input.
2. Convert trimmed empty strings to null with `NULLIF`; internal whitespace and source spelling/case are retained.
3. Rename source headers to consistent snake_case staging names without changing their meaning.
4. Preserve identifiers and codes as text; do not coerce code strings to numbers.
5. Preserve every row and nullable source behavior.
6. Add `source_system`, `source_table`, and `source_row_hash` lineage fields. The MD5 row hash is a lineage fingerprint, not a security control or final business key.
7. Do not standardize clinical descriptions, claim statuses, transaction types, payer behavior, or financial signs in V1 staging.

## Data Quality Rules

- Required observed identifiers/references receive missing-value flags.
- Candidate unique identifiers receive duplicate-row flags without unique constraints.
- Patient, encounter, and claim references are checked only where an in-scope staging parent exists and profiling supports the relationship.
- `claims.APPOINTMENTID` and claim-transaction `APPOINTMENTID` are validated as **Candidate / To Be Validated** encounter references because all populated values matched the encounter source in this extract.
- Date ordering is flagged only when both typed values are present.
- Negative financial values receive flags but are not automatically classified as invalid.
- Any failed cast is visible in `dq_conversion_errors` and `dq_has_conversion_error`; the original lexical value remains in raw and can be traced with `source_row_hash`.
- No row is deleted or quarantined in V1.

## Validation Flags

| Table | Flags |
|---|---|
| `stg_patients` | Missing/duplicate patient ID, invalid birth/death date, death before birth, conversion failure. |
| `stg_encounters` | Missing/duplicate encounter ID, missing/broken patient, start after stop, negative source amount, conversion failure. |
| `stg_claims` | Missing/duplicate claim ID, missing/broken patient, unresolved candidate encounter, negative source balance, conversion failure. |
| `stg_claim_transactions` | Missing/duplicate transaction ID, missing/broken claim, missing/broken patient, unresolved candidate encounter, `to_at < from_at`, negative source amount, conversion failure. |
| `stg_condition_occurrences` | Missing/broken patient or encounter, stop before start, duplicate candidate composite key, conversion failure. |
| `stg_procedures` | Missing/broken patient or encounter, stop before start, negative base cost, duplicate candidate composite key, conversion failure. |

## Row Count Reconciliation

The transformation was executed twice successfully to validate deterministic truncate-and-reload behavior.

| Dataset | RAW rows | STAGING rows | Difference | Status |
|---|---:|---:|---:|---|
| Patients | 10 | 10 | 0 | Passed |
| Encounters | 283 | 283 | 0 | Passed |
| Claims | 464 | 464 | 0 | Passed |
| Claim transactions | 5,403 | 5,403 | 0 | Passed |
| Condition occurrences | 252 | 252 | 0 | Passed |
| Procedures | 1,003 | 1,003 | 0 | Passed |
| **Total** | **7,415** | **7,415** | **0** | **Passed** |

Validated results after the rerun:

- Missing source IDs/references: 0.
- Duplicate patient, encounter, claim, transaction, condition candidate, or procedure candidate keys: 0 flagged rows.
- Broken patient references: 0.
- Broken claim references: 0.
- Broken candidate encounter references: 0.
- Patient death-before-birth, encounter start-after-stop, condition stop-before-start, and procedure stop-before-start: 0.
- Negative financial/base-cost rows: 0.
- Conversion failures: 0.
- Claim-transaction rows with `to_at < from_at`: 796 flagged rows.
- Analytics tables created: 0.

## Claim Transaction Date Investigation

### Scope and transformation fidelity

The 796 claim-transaction rows with `TODATE < FROMDATE` were investigated read-only against raw, staging, related claims/encounters, the local CSV extract, and the local official Synthea source repository at revision `d9d07a6eef91ee5144293b42ab64224d84d124f8`.

Raw-to-staging equality was checked by transaction ID across all 5,403 rows:

| Check | Result |
|---|---:|
| Raw rows where `TODATE < FROMDATE` | 796 |
| Staging rows where `dq_to_before_from = true` | 796 |
| Raw `FROMDATE` cast differs from staging `from_at` | 0 |
| Raw `TODATE` cast differs from staging `to_at` | 0 |
| Raw date comparison differs from staging flag | 0 |

**Transformation-caused issue: No.** The transformation maps `FROMDATE` directly to `from_at` and `TODATE` directly to `to_at`; it does not reverse, replace, offset, or otherwise alter them.

### Affected population and pattern analysis

- Affected rows: 796 of 5,403 claim transactions (**14.7326%**).
- Affected source claims: 123; affected encounters: 111; affected patients: all 10 synthetic patients.
- Rows per affected claim: minimum 2, maximum 25, mean 6.47, median 4.
- Rows per affected encounter: minimum 2, maximum 25, mean 7.17, median 4.
- Every affected row has `TODATE = 1970-01-01T00:00:00Z`.
- Difference in days (`TODATE - FROMDATE`): minimum -20,689.618785; maximum -15,471.208912; median -18,774.100185.
- All 796 differences are less than -3,650 days. The large values reflect comparison with the Unix epoch, not plausible service durations.
- The 195 affected CHARGE rows map exactly to **174 immunization entries** and **21 open medication entries** in the local Synthea CSVs. No affected CHARGE row was unmatched.

| Transaction type | Flagged rows | Affected claims |
|---|---:|---:|
| PAYMENT | 243 | 123 |
| CHARGE | 195 | 123 |
| TRANSFERIN | 179 | 105 |
| TRANSFEROUT | 179 | 105 |

The pattern is not specific to one financial transaction type. Synthea creates several transaction rows for one claim entry, and every generated row inherits that entry's same start/stop values.

| Method | Flagged rows |
|---|---:|
| Null/not applicable | 553 |
| CC | 71 |
| CASH | 66 |
| CHECK | 56 |
| ECHECK | 50 |

| Transfer type | Flagged rows |
|---|---:|
| Null/not applicable | 422 |
| Patient (`p`) | 193 |
| Primary insurance (`1`) | 176 |
| Secondary insurance (`2`) | 5 |

Seven encounter payer IDs occur in the affected population:

| Encounter payer ID | Flagged rows | Claims | Encounters |
|---|---:|---:|---:|
| `d31fccc3-1767-390d-966a-22a5156f4219` | 230 | 29 | 29 |
| `734afbd6-4794-363b-9bc0-6a3981533ed5` | 208 | 26 | 22 |
| `26aab0cd-6aba-3e1b-ac5b-05c8867e762c` | 140 | 15 | 15 |
| `8fa6c185-e44e-3e34-8bd8-39be8694f4ce` | 77 | 14 | 14 |
| `b046940f-1664-3047-bca7-dfa76be352a4` | 64 | 15 | 12 |
| `a735bf55-83e9-331a-899d-a82a60b9f60c` | 39 | 6 | 5 |
| `e03e23c9-4df1-3eb6-a62d-f70f02301496` | 38 | 18 | 14 |

Claim status does not explain the pattern: 762 rows belong to claims with `STATUS1/STATUS2/STATUSP = CLOSED/CLOSED/CLOSED`; 34 have `CLOSED/null/CLOSED`.

### Representative records

Twenty rows were selected across ordered difference quantiles. The query inspected ID, claim, charge, patient, type, method, raw dates, amount, payments, adjustments, transfers, outstanding, procedure code, notes, transfer type, and transfer-out reference. Selected evidence is recorded below; all records are synthetic.

| # | ID | Claim / charge | Patient | Type / method | FROMDATE | TODATE | Difference days | Financial fields | Code / entry |
|---:|---|---|---|---|---|---|---:|---|---|
| 1 | `0c7d42a2-b127-d75a-6d78-017837a9eb91` | `c1504c3e-93bb-d60a-21bf-ee64f4c8e14f` / 6536 | `c1504c3e-93bb-d60a-9d2f-6d5d266d4d6e` | CHARGE / null | 2026-08-24T14:51:03Z | 1970-01-01T00:00:00Z | -20,689.6188 | amount 0.91 | 314076 / lisinopril |
| 2 | `9eb6c9a8-65af-2dcd-aa6e-a1b90dfbe87e` | `abd9a445-4a0b-a574-0a80-7b0ca0276e33` / 1939 | `abd9a445-4a0b-a574-cd6d-ac983ba81622` | TRANSFEROUT / null | 2026-04-27T17:05:53Z | 1970-01-01T00:00:00Z | -20,570.7124 | transfers 7.64 | 856987 / acetaminophen-hydrocodone |
| 3 | `c1bcd5b3-6e76-a0c2-f4fa-556f5a1a6e8e` | `467999ec-40b4-5349-e37a-50d6ef7ff0f8` / 2581 | `467999ec-40b4-5349-9461-72600c266bea` | CHARGE / null | 2026-02-07T13:01:52Z | 1970-01-01T00:00:00Z | -20,491.5430 | amount 136.00 | 03 / MMR |
| 4 | `8e345e15-72ba-b095-0141-2d6e0f2ac987` | `467999ec-40b4-5349-4381-dc381ad88da8` / 2512 | `467999ec-40b4-5349-9461-72600c266bea` | CHARGE / null | 2025-08-09T13:01:52Z | 1970-01-01T00:00:00Z | -20,309.5430 | amount 136.00 | 133 / pneumococcal PCV13 |
| 5 | `bca7f57b-ae6a-424b-5b51-dbd1104d2865` | `467999ec-40b4-5349-fea9-e253fd9e8603` / 2465 | `467999ec-40b4-5349-9461-72600c266bea` | PAYMENT / ECHECK | 2025-05-10T13:01:52Z | 1970-01-01T00:00:00Z | -20,218.5430 | payment 108.80 | 10 / IPV |
| 6 | `a43def0d-853a-2004-d15c-1d6f1f246d4d` | `467999ec-40b4-5349-70a2-1b7ff22527ed` / 2438 | `467999ec-40b4-5349-9461-72600c266bea` | PAYMENT / CC | 2025-03-08T13:01:52Z | 1970-01-01T00:00:00Z | -20,155.5430 | payment 27.20 | 20 / DTaP |
| 7 | `899eec0a-d12f-36bc-3950-69dde3994a61` | `d95ec747-18c9-9712-d681-782fbc535eb7` / 4258 | `d95ec747-18c9-9712-c4b5-817152fe7f0c` | CHARGE / null | 2024-09-21T09:19:55Z | 1970-01-01T00:00:00Z | -19,987.3888 | amount 136.00 | 03 / MMR |
| 8 | `7254c095-c71d-03c8-1e42-1301d47679d8` | `c1504c3e-93bb-d60a-78f0-43627135eb55` / 5561 | `c1504c3e-93bb-d60a-9d2f-6d5d266d4d6e` | CHARGE / null | 2023-05-22T14:51:03Z | 1970-01-01T00:00:00Z | -19,499.6188 | amount 136.00 | 113 / Td adult |
| 9 | `f7d00796-a786-e040-c6fc-8d1788ac613c` | `1a6f5164-fa56-7e24-e9be-dcd93c6035a6` / 402 | `1a6f5164-fa56-7e24-a97e-6c271ddc754d` | PAYMENT / CASH | 2022-06-01T11:28:56Z | 1970-01-01T00:00:00Z | -19,144.4784 | payment 27.20 | 140 / influenza |
| 10 | `b41f7910-74d8-1316-d570-128554422446` | `abd9a445-4a0b-a574-4cc3-21875c323b95` / 1667 | `abd9a445-4a0b-a574-cd6d-ac983ba81622` | CHARGE / null | 2021-11-15T17:05:53Z | 1970-01-01T00:00:00Z | -18,946.7124 | amount 136.00 | 207 / COVID-19 vaccine |
| 11 | `e5846cb4-d02e-1478-33f8-298b5888c3f6` | `18c43411-25f8-0593-baec-517bb411f0ac` / 6699 | `18c43411-25f8-0593-da21-2bc8140e01b0` | PAYMENT / ECHECK | 2021-05-27T02:24:16Z | 1970-01-01T00:00:00Z | -18,774.1002 | payment 36.46 | 207 / COVID-19 vaccine |
| 12 | `f4c42e97-1ded-a1b9-a3f2-cd7823924051` | `1611f11c-9719-b418-48bc-f07180467ec8` / 3243 | `1611f11c-9719-b418-daf1-b8450abda66e` | TRANSFERIN / null | 2021-01-08T08:00:50Z | 1970-01-01T00:00:00Z | -18,635.3339 | amount/transfers 40.80 | 207 / COVID-19 vaccine |
| 13 | `dee2f2b1-be21-e242-190e-aaef235208e4` | `d95ec747-18c9-9712-1e23-bcfcc3ae0bef` / 4094 | `d95ec747-18c9-9712-c4b5-817152fe7f0c` | TRANSFEROUT / null | 2020-06-20T09:19:55Z | 1970-01-01T00:00:00Z | -18,433.3888 | transfers 136.00 | 133 / pneumococcal PCV13 |
| 14 | `4a9b6f97-9ed9-bbc3-4615-cdf4dc9bc64f` | `1611f11c-9719-b418-1d85-9aee3d6c586f` / 3087 | `1611f11c-9719-b418-daf1-b8450abda66e` | TRANSFERIN / null | 2020-03-20T08:00:50Z | 1970-01-01T00:00:00Z | -18,341.3339 | amount/transfers 136.00 | 140 / influenza |
| 15 | `3113617e-d4d0-6b21-75e8-30d97af53f48` | `d95ec747-18c9-9712-0111-b8a1797f8019` / 3973 | `d95ec747-18c9-9712-c4b5-817152fe7f0c` | CHARGE / null | 2019-10-12T09:19:55Z | 1970-01-01T00:00:00Z | -18,181.3888 | amount 136.00 | 08 / Hep B |
| 16 | `4f6c1b55-319e-c693-8bcf-736afc342009` | `6ad54e7c-495c-208b-bc64-8413a4cd9f1b` / 2092 | `6ad54e7c-495c-208b-82d4-2bca29ab06a3` | PAYMENT / CHECK | 2019-02-06T09:28:08Z | 1970-01-01T00:00:00Z | -17,933.3945 | payment 136.00 | 140 / influenza |
| 17 | `6ccbb366-8186-4f41-741f-d9c39e57708d` | `abd9a445-4a0b-a574-f150-48e46f71b12b` / 1455 | `abd9a445-4a0b-a574-cd6d-ac983ba81622` | TRANSFERIN / null | 2018-03-12T17:05:53Z | 1970-01-01T00:00:00Z | -17,602.7124 | amount/transfers 136.00 | 140 / influenza |
| 18 | `21df0429-8dde-d4ec-0d64-76cee43b7532` | `6ad54e7c-495c-208b-1c85-754c919db293` / 2012 | `6ad54e7c-495c-208b-82d4-2bca29ab06a3` | CHARGE / null | 2018-01-31T09:28:08Z | 1970-01-01T00:00:00Z | -17,562.3945 | amount 136.00 | 140 / influenza |
| 19 | `8d84e3ab-47a7-7b4c-4af7-ac03448bdc74` | `1a6f5164-fa56-7e24-bdd1-63b622aa5712` / 36 | `1a6f5164-fa56-7e24-a97e-6c271ddc754d` | TRANSFEROUT / null | 2017-09-27T11:28:56Z | 1970-01-01T00:00:00Z | -17,436.4784 | transfers 136.00 | 10 / IPV |
| 20 | `ab7b9f7d-6a56-cd2a-b667-18f2615eec28` | `1611f11c-9719-b418-9597-1aa0dd3fae6f` / 2740 | `1611f11c-9719-b418-daf1-b8450abda66e` | PAYMENT / CHECK | 2017-03-03T08:00:50Z | 1970-01-01T00:00:00Z | -17,228.3339 | payment 136.00 | 140 / influenza |

### Related-record traces

Three representative claims were traced without aggregating financial measures across facts:

- An immunization-heavy claim had a valid 2026-02-07 encounter start/stop. Its encounter and medication-reconciliation transaction rows used that valid interval, while five immunization entry groups each emitted epoch `TODATE`; CHARGE, TRANSFEROUT, TRANSFERIN, and PAYMENT rows within each group repeated the same entry dates.
- An open acetaminophen/hydrocodone medication claim had a valid 2026-04-27 encounter interval. Its four claim-entry transaction rows all repeated the medication's start plus epoch stop.
- An open lisinopril medication claim had a valid 2026-08-24 encounter interval. Its CHARGE and PAYMENT rows both repeated the medication's start plus epoch stop.

The sequence/history therefore explains row multiplication: one source entry with an unset stop produces several financial transaction rows, not several independent date anomalies.

### Local Synthea source semantics

Primary evidence from the local official source:

1. `HealthRecord.Entry` defines `long start` and `long stop`; its constructor sets `start` but does not set `stop`. Java therefore leaves an unset stop at `0` (`HealthRecord.java`, Entry definition/constructor around lines 166-205).
2. `HealthRecord.Immunization` calls the base constructor and does not set stop (around lines 454-465). The generated extract contains 174 immunization rows, all of which account for affected CHARGE entries.
3. Open medications also use `stop == 0L`; other Synthea code explicitly interprets this as current/open, and the generated extract contains 21 such medications.
4. `CSVExporter.ClaimTransaction` copies `claimEntry.entry.start` to its `start` field and `claimEntry.entry.stop` to its `stop` field (around lines 1556-1575).
5. `ClaimTransaction.toString()` always formats both values: `FROMDATE = iso8601Timestamp(start)` and `TODATE = iso8601Timestamp(stop)` (around lines 1615-1618).
6. `ExportHelper.iso8601Timestamp(long)` formats `new Date(time)` (around lines 192-193); formatting zero yields `1970-01-01T00:00:00Z`.
7. Other CSV export paths for encounters, conditions, procedures, and medications explicitly check `stop != 0L` before emitting a stop value. The claim-transaction path lacks this guard.

Accordingly:

- **Synthea `FROMDATE` meaning:** the underlying clinical claim entry's start timestamp (`claimEntry.entry.start`), not a financial posting timestamp.
- **Synthea `TODATE` meaning:** the underlying clinical claim entry's stop timestamp (`claimEntry.entry.stop`), not a financial settlement timestamp. In this export, an unset/open stop sentinel of zero is serialized as the Unix epoch.

### Classification and recommended handling

**Classification: A. Valid / Expected Source Behavior.** More precisely, this is deterministic Synthea CSV exporter behavior for claim entries whose stop is unset (`0L`). The epoch value is a source representation of “no stop/open/not applicable,” not a real 1970 end date and not evidence that the transaction ended before it began.

Evidence supporting the classification:

- zero raw/staging timestamp or flag mismatches;
- all 796 rows use the exact Unix epoch as `TODATE`;
- all 195 affected source entries resolve to immunizations or open medications;
- all transaction types inherit the same dates from the same claim entry;
- related encounters and nonzero-stop claim entries have coherent time ordering; and
- the local official source code explains the value deterministically.

**Recommended staging handling: Keep values unchanged; retain a warning flag.** For the current implemented snapshot, preserve raw and staging values and treat `dq_to_before_from` as a source-sentinel warning, not a generic date-quality error. In a separately reviewed staging change, consider renaming/replacing it with a semantic flag such as `source_stop_is_zero_sentinel`; any conversion of epoch `to_at` to null should occur only under an explicitly approved deterministic rule while retaining raw lineage. Do not swap dates, substitute encounter stop, invent an end date, delete rows, or quarantine otherwise valid transactions.

Unresolved questions:

- Should future staging expose a separate nullable semantic end timestamp while retaining the literal source timestamp for lineage?
- Should the warning be renamed so downstream users cannot mistake it for a true chronological error?
- Does the same zero-stop serialization behavior persist across future Synthea versions and larger extracts?

## Known Issues

1. The 796 claim-transaction rows with `TODATE < FROMDATE` are documented above as expected zero-stop-sentinel exporter behavior, not a transformation error. The current warning flag remains implemented pending a separately approved semantic staging rule.
2. Claim and claim-transaction amounts occur at different grains. Direct joins can multiply claim balances, encounter costs, counts, and patient counts.
3. `AMOUNT`, `PAYMENTS`, `ADJUSTMENTS`, `TRANSFERS`, and `OUTSTANDING` are typed but their sign and aggregation semantics are not finalized.
4. Provider, organization, payer, and patient-insurance reference tables are outside the six-source staging scope, so those references are retained but not declared broken or valid here.
5. The development load has source-system/table/hash lineage but no persistent batch ID, source file hash column, source row number, or load timestamp.

## Open Questions

- **Candidate / To Be Validated:** Does `claims.APPOINTMENTID` formally represent encounter ID across Synthea versions and larger extracts?
- Should the source zero-stop sentinel remain as epoch in typed staging, be exposed as null in a separate semantic field, or be represented through a dedicated source-sentinel flag?
- Which claim-transaction types and measures contribute to future charge, payment, adjustment, transfer, and outstanding KPIs?
- Should `DEPARTMENTID`, claim-type IDs, diagnosis references, `CHARGEID`, `TRANSFEROUTID`, and `FEESCHEDULEID` remain classifications/identifiers or become reference-table keys?
- Are the condition and procedure candidate composite keys stable in larger, repeated, or multi-state extracts?
- What batch-level lineage and rejected-value workflow is required before production ingestion?
- When supporting reference sources are staged, which provider, organization, payer, and insurance relationships should become enforced quality rules?

## Next Step

Review and checkpoint this validated staging design. After approval, design the analytics/star-schema DDL and transformations separately using the approved grains and conformed relationships. No analytics objects are implemented in this step.
