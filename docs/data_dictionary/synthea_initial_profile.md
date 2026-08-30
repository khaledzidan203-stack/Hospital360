# Synthea Initial Data Profile

All grains, keys, and relationships in this document are **Candidate / To Be Validated**. They describe the 10-patient smoke-test extract only and are not a final architecture.

## Smoke Test

- Source: official Synthea repository cloned at `D:\Hospital360\tools\synthea`.
- Population requested and generated: 10 synthetic patients.
- CSV output: `D:\Hospital360\data\raw\synthea\csv`.
- CSV files inspected: 18.
- Raw CSV files were inspected read-only and preserved exactly as generated.
- Gradle cache check:
  - `D:\Hospital360\.gradle`: exists; 1,815 files; 415,217,535 bytes (395.98 MB).
  - `D:\Hospital360.gradle`: does not exist; 0 bytes.
- The smoke-test cache was moved into the intended project-local path without deleting its contents.

## Source Files

| File | Data rows | Columns | Size (bytes) | Column names |
|---|---:|---:|---:|---|
| `allergies.csv` | 7 | 15 | 1,265 | START, STOP, PATIENT, ENCOUNTER, CODE, SYSTEM, DESCRIPTION, TYPE, CATEGORY, REACTION1, DESCRIPTION1, SEVERITY1, REACTION2, DESCRIPTION2, SEVERITY2 |
| `careplans.csv` | 17 | 9 | 3,487 | Id, START, STOP, PATIENT, ENCOUNTER, CODE, DESCRIPTION, REASONCODE, REASONDESCRIPTION |
| `claims_transactions.csv` | 5,403 | 33 | 2,430,339 | ID, CLAIMID, CHARGEID, PATIENTID, TYPE, AMOUNT, METHOD, FROMDATE, TODATE, PLACEOFSERVICE, PROCEDURECODE, MODIFIER1, MODIFIER2, DIAGNOSISREF1, DIAGNOSISREF2, DIAGNOSISREF3, DIAGNOSISREF4, UNITS, DEPARTMENTID, NOTES, UNITAMOUNT, TRANSFEROUTID, TRANSFERTYPE, PAYMENTS, ADJUSTMENTS, TRANSFERS, OUTSTANDING, APPOINTMENTID, LINENOTE, PATIENTINSURANCEID, FEESCHEDULEID, PROVIDERID, SUPERVISINGPROVIDERID |
| `claims.csv` | 464 | 31 | 176,270 | Id, PATIENTID, PROVIDERID, PRIMARYPATIENTINSURANCEID, SECONDARYPATIENTINSURANCEID, DEPARTMENTID, PATIENTDEPARTMENTID, DIAGNOSIS1-DIAGNOSIS8, REFERRINGPROVIDERID, APPOINTMENTID, CURRENTILLNESSDATE, SERVICEDATE, SUPERVISINGPROVIDERID, STATUS1, STATUS2, STATUSP, OUTSTANDING1, OUTSTANDING2, OUTSTANDINGP, LASTBILLEDDATE1, LASTBILLEDDATE2, LASTBILLEDDATEP, HEALTHCARECLAIMTYPEID1, HEALTHCARECLAIMTYPEID2 |
| `conditions.csv` | 252 | 7 | 36,697 | START, STOP, PATIENT, ENCOUNTER, SYSTEM, CODE, DESCRIPTION |
| `devices.csv` | 31 | 7 | 7,069 | START, STOP, PATIENT, ENCOUNTER, CODE, DESCRIPTION, UDI |
| `encounters.csv` | 283 | 15 | 91,879 | Id, START, STOP, PATIENT, ORGANIZATION, PROVIDER, PAYER, ENCOUNTERCLASS, CODE, DESCRIPTION, BASE_ENCOUNTER_COST, TOTAL_CLAIM_COST, PAYER_COVERAGE, REASONCODE, REASONDESCRIPTION |
| `imaging_studies.csv` | 53 | 13 | 20,537 | Id, DATE, PATIENT, ENCOUNTER, SERIES_UID, BODYSITE_CODE, BODYSITE_DESCRIPTION, MODALITY_CODE, MODALITY_DESCRIPTION, INSTANCE_UID, SOP_CODE, SOP_DESCRIPTION, PROCEDURE_CODE |
| `immunizations.csv` | 174 | 6 | 23,625 | DATE, PATIENT, ENCOUNTER, CODE, DESCRIPTION, BASE_COST |
| `medications.csv` | 181 | 13 | 46,211 | START, STOP, PATIENT, PAYER, ENCOUNTER, CODE, DESCRIPTION, BASE_COST, PAYER_COVERAGE, DISPENSES, TOTALCOST, REASONCODE, REASONDESCRIPTION |
| `observations.csv` | 4,246 | 9 | 729,043 | DATE, PATIENT, ENCOUNTER, CATEGORY, CODE, DESCRIPTION, VALUE, UNITS, TYPE |
| `organizations.csv` | 35 | 12 | 5,978 | Id, NAME, ADDRESS, CITY, STATE, ZIP, LAT, LON, PHONE, REVENUE, UTILIZATION, NPI |
| `patients.csv` | 10 | 28 | 3,163 | Id, BIRTHDATE, DEATHDATE, SSN, DRIVERS, PASSPORT, PREFIX, FIRST, MIDDLE, LAST, SUFFIX, MAIDEN, MARITAL, RACE, ETHNICITY, GENDER, BIRTHPLACE, ADDRESS, CITY, STATE, COUNTY, FIPS, ZIP, LAT, LON, HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE, INCOME |
| `payer_transitions.csv` | 284 | 8 | 47,699 | PATIENT, MEMBERID, START_DATE, END_DATE, PAYER, SECONDARY_PAYER, PLAN_OWNERSHIP, OWNER_NAME |
| `payers.csv` | 10 | 22 | 1,622 | Id, NAME, OWNERSHIP, ADDRESS, CITY, STATE_HEADQUARTERED, ZIP, PHONE, AMOUNT_COVERED, AMOUNT_UNCOVERED, REVENUE, COVERED_ENCOUNTERS, UNCOVERED_ENCOUNTERS, COVERED_MEDICATIONS, UNCOVERED_MEDICATIONS, COVERED_PROCEDURES, UNCOVERED_PROCEDURES, COVERED_IMMUNIZATIONS, UNCOVERED_IMMUNIZATIONS, UNIQUE_CUSTOMERS, QOLS_AVG, MEMBER_MONTHS |
| `procedures.csv` | 1,003 | 10 | 209,443 | START, STOP, PATIENT, ENCOUNTER, SYSTEM, CODE, DESCRIPTION, BASE_COST, REASONCODE, REASONDESCRIPTION |
| `providers.csv` | 35 | 14 | 7,053 | Id, ORGANIZATION, NAME, GENDER, SPECIALITY, ADDRESS, CITY, STATE, ZIP, LAT, LON, ENCOUNTERS, PROCEDURES, NPI |
| `supplies.csv` | 143 | 6 | 19,668 | DATE, PATIENT, ENCOUNTER, CODE, DESCRIPTION, QUANTITY |

## Core Table Profiles

Every entry below is **Candidate / To Be Validated**.

| File | What one row appears to represent | Candidate primary/business key | Important references | Date/time columns | Numeric/measure columns |
|---|---|---|---|---|---|
| `patients.csv` | One synthetic patient | `Id` | None within the profiled core files | BIRTHDATE, DEATHDATE | LAT, LON, HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE, INCOME |
| `encounters.csv` | One encounter event | `Id` | PATIENT, ORGANIZATION, PROVIDER, PAYER | START, STOP | BASE_ENCOUNTER_COST, TOTAL_CLAIM_COST, PAYER_COVERAGE |
| `claims.csv` | One claim header associated with an appointment/encounter | `Id` | PATIENTID, PROVIDERID, PRIMARYPATIENTINSURANCEID, SECONDARYPATIENTINSURANCEID, REFERRINGPROVIDERID, SUPERVISINGPROVIDERID, APPOINTMENTID | CURRENTILLNESSDATE, SERVICEDATE, LASTBILLEDDATE1, LASTBILLEDDATE2, LASTBILLEDDATEP | OUTSTANDING1, OUTSTANDING2, OUTSTANDINGP |
| `claims_transactions.csv` | One claim financial transaction/event line | `ID` | CLAIMID, PATIENTID, PLACEOFSERVICE, APPOINTMENTID, PATIENTINSURANCEID, PROVIDERID, SUPERVISINGPROVIDERID, TRANSFEROUTID | FROMDATE, TODATE | AMOUNT, UNITS, UNITAMOUNT, PAYMENTS, ADJUSTMENTS, TRANSFERS, OUTSTANDING |
| `conditions.csv` | One condition occurrence/episode recorded for a patient and encounter | PATIENT + ENCOUNTER + START + CODE | PATIENT, ENCOUNTER | START, STOP | None identified |
| `procedures.csv` | One procedure event recorded for a patient and encounter | PATIENT + ENCOUNTER + START + CODE | PATIENT, ENCOUNTER | START, STOP | BASE_COST |
| `medications.csv` | One medication episode/order associated with a patient and encounter | PATIENT + ENCOUNTER + START + CODE | PATIENT, PAYER, ENCOUNTER | START, STOP | BASE_COST, PAYER_COVERAGE, DISPENSES, TOTALCOST |
| `observations.csv` | One observation result at a point in time | PATIENT + ENCOUNTER + DATE + CODE + VALUE + UNITS | PATIENT, ENCOUNTER when populated | DATE | VALUE when TYPE indicates numeric; interpret with UNITS |
| `organizations.csv` | One healthcare organization | `Id`; `NPI` is an alternate business-key candidate | None within the file | None identified | LAT, LON, REVENUE, UTILIZATION |
| `providers.csv` | One provider associated with an organization | `Id`; `NPI` is an alternate business-key candidate | ORGANIZATION | None identified | LAT, LON, ENCOUNTERS, PROCEDURES |
| `payers.csv` | One payer summary row | `Id` | None within the file | None identified | AMOUNT_COVERED, AMOUNT_UNCOVERED, REVENUE, covered/uncovered event counts, UNIQUE_CUSTOMERS, QOLS_AVG, MEMBER_MONTHS |

## Candidate Grain

All candidate grains are **Candidate / To Be Validated** against larger extracts and Synthea exporter documentation.

- Entity-like files: one row per patient, organization, provider, or payer.
- Event/header files: one row per encounter or claim header.
- Transaction file: one row per claim transaction/event line.
- Clinical event files without a supplied row ID: one row per condition occurrence, procedure event, medication episode/order, or observation result.

## Candidate Keys

All keys are **Candidate / To Be Validated**.

- `Id` was complete and unique in patients (10/10), encounters (283/283), claims (464/464), organizations (35/35), providers (35/35), and payers (10/10).
- `claims_transactions.ID` was complete and unique (5,403/5,403).
- `organizations.NPI` and `providers.NPI` were each unique in this extract (35/35), but uniqueness must be validated across larger and multi-state extracts.
- Observed composite candidates had no duplicate rows in this extract:
  - conditions: PATIENT + ENCOUNTER + START + CODE (252/252 distinct).
  - procedures: PATIENT + ENCOUNTER + START + CODE (1,003/1,003 distinct).
  - medications: PATIENT + ENCOUNTER + START + CODE (181/181 distinct).
  - observations: PATIENT + ENCOUNTER + DATE + CODE + VALUE + UNITS (4,246/4,246 distinct).

## Candidate Relationships

All relationships are **Candidate / To Be Validated**. Evidence is exact value matching in this smoke-test extract, not name similarity alone.

| Child reference | Candidate parent key | Nonblank | Matched | Unmatched |
|---|---|---:|---:|---:|
| encounters.PATIENT | patients.Id | 283 | 283 | 0 |
| encounters.ORGANIZATION | organizations.Id | 283 | 283 | 0 |
| encounters.PROVIDER | providers.Id | 283 | 283 | 0 |
| encounters.PAYER | payers.Id | 283 | 283 | 0 |
| claims.PATIENTID | patients.Id | 464 | 464 | 0 |
| claims.PROVIDERID | providers.Id | 464 | 464 | 0 |
| claims.PRIMARYPATIENTINSURANCEID | payers.Id | 340 | 340 | 0 |
| claims.APPOINTMENTID | encounters.Id | 464 | 464 | 0 |
| claims_transactions.CLAIMID | claims.Id | 5,403 | 5,403 | 0 |
| claims_transactions.PATIENTID | patients.Id | 5,403 | 5,403 | 0 |
| claims_transactions.APPOINTMENTID | encounters.Id | 5,403 | 5,403 | 0 |
| claims_transactions.PLACEOFSERVICE | organizations.Id | 5,403 | 5,403 | 0 |
| claims_transactions.PROVIDERID | providers.Id | 5,403 | 5,403 | 0 |
| conditions.PATIENT | patients.Id | 252 | 252 | 0 |
| conditions.ENCOUNTER | encounters.Id | 252 | 252 | 0 |
| procedures.PATIENT | patients.Id | 1,003 | 1,003 | 0 |
| procedures.ENCOUNTER | encounters.Id | 1,003 | 1,003 | 0 |
| medications.PATIENT | patients.Id | 181 | 181 | 0 |
| medications.ENCOUNTER | encounters.Id | 181 | 181 | 0 |
| medications.PAYER | payers.Id | 181 | 181 | 0 |
| observations.PATIENT | patients.Id | 4,246 | 4,246 | 0 |
| observations.ENCOUNTER | encounters.Id | 3,970 | 3,970 | 0 |
| providers.ORGANIZATION | organizations.Id | 35 | 35 | 0 |

## Initial Data Quality Checks

| File | Check | Result |
|---|---|---:|
| `patients.csv` | Duplicate Id rows | 0 |
| `patients.csv` | Missing Id | 0 |
| `patients.csv` | Missing BIRTHDATE | 0 |
| `encounters.csv` | Duplicate Id rows | 0 |
| `encounters.csv` | Missing Id | 0 |
| `encounters.csv` | Missing PATIENT | 0 |
| `encounters.csv` | START later than STOP | 0 |
| `encounters.csv` | PATIENT not found in patients.Id | 0 |
| `claims.csv` | Duplicate Id rows | 0 |
| `claims.csv` | Missing Id | 0 |
| `claims.csv` | Missing PATIENTID | 0 |
| `claims.csv` | PATIENTID not found in patients.Id | 0 |
| `claims.csv` | Nonblank APPOINTMENTID not found in encounters.Id | 0 |

The requested quality checks found no violations. Claims had 464 nonblank APPOINTMENTID values and all 464 matched `encounters.Id` exactly.

## Observations

- `observations.csv` has 4,246 rows; 3,970 have a populated ENCOUNTER and all populated values match `encounters.Id`. The remaining 276 ENCOUNTER values are blank, not broken references.
- Claims contain 340 populated PRIMARYPATIENTINSURANCEID values; all match `payers.Id`. The remaining 124 are blank and require semantic interpretation before enforcing mandatory payer relationships.
- Financial fields are represented at several grains: encounter totals, claim-header outstanding balances, claim transaction movements, payer summaries, and patient lifetime expense/coverage totals. They should not be aggregated together without grain-aware reconciliation.
- Observation VALUE is not universally numeric; TYPE and UNITS must be retained when interpreting measures.
- The smoke test also created non-CSV hospital/practitioner FHIR metadata under the raw Synthea base directory. Those files were outside this CSV inspection and were not modified.
- Repository hygiene was corrected so `.gradle/`, `tools/synthea/`, nested `data/raw/**`, nested `data/processed/**`, `.env`, virtual environments, Python caches, and bytecode are ignored. `data/sample/` remains trackable, and `.gitkeep` exceptions preserve empty raw/processed folders.

## Questions Requiring Validation

- **Candidate / To Be Validated:** Does `claims.APPOINTMENTID` formally represent the encounter identifier in all Synthea exporter versions? It matched `encounters.Id` 464/464 here.
- **Candidate / To Be Validated:** Are the proposed composite keys stable for repeated codes at the same timestamp in larger populations, or is an ingestion surrogate key required?
- **Candidate / To Be Validated:** Should organization/provider NPI be treated as durable business keys across states, source versions, and historical snapshots?
- **Candidate / To Be Validated:** What is the intended semantic treatment of 276 observations with blank ENCOUNTER values?
- **Candidate / To Be Validated:** Are blank claims insurance references expected self-pay/no-insurance cases, and how should secondary insurance be modeled?
- **Candidate / To Be Validated:** Are payer, provider, and organization aggregate measures snapshot values that must be regenerated or reconciled for each data load?
- **Candidate / To Be Validated:** Which claim transaction TYPE values should contribute to charge, payment, adjustment, transfer, and outstanding-balance analytics?
