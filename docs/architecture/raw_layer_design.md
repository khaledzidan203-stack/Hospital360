# Hospital360 RAW Layer Design

## Purpose

The Hospital360 raw layer is a **source-preserving landing layer**. It captures approved source fields with their original names and lexical values so every later cleaning, typing, validation, and business transformation can be audited against the source.

Raw tables are not cleaned, standardized, deduplicated, aggregated, or analytics-ready.

## Design Principles

1. One raw table represents one approved source CSV.
2. Source headers are preserved exactly, including case, through quoted PostgreSQL identifiers.
3. All source columns are nullable to avoid rejecting valid source rows before data-quality assessment.
4. Source values are stored as `text`; semantic typing belongs in staging.
5. No business transformations, standardization, aggregation, or deduplication occur in raw.
6. Candidate keys are retained as ordinary columns and are not enforced.
7. No analytical foreign keys, check constraints, or source-domain constraints are enforced.
8. The DDL creates structures only; ingestion is a later, separately validated step.

## Source-to-Raw Mapping

| Source CSV | Raw PostgreSQL table | Source rows profiled | Source columns |
|---|---|---:|---:|
| `patients.csv` | `raw.synthea_patients` | 10 | 28 |
| `encounters.csv` | `raw.synthea_encounters` | 283 | 15 |
| `claims.csv` | `raw.synthea_claims` | 464 | 31 |
| `claims_transactions.csv` | `raw.synthea_claims_transactions` | 5,403 | 33 |
| `conditions.csv` | `raw.synthea_conditions` | 252 | 7 |
| `procedures.csv` | `raw.synthea_procedures` | 1,003 | 10 |

## Table Definitions

### `raw.synthea_patients`

- Source grain: **Candidate / To Be Validated** — one synthetic patient.
- Identifier/text fields: Id, SSN, DRIVERS, PASSPORT, PREFIX, FIRST, MIDDLE, LAST, SUFFIX, MAIDEN, MARITAL, RACE, ETHNICITY, GENDER, BIRTHPLACE, ADDRESS, CITY, STATE, COUNTY, FIPS, ZIP.
- Apparent date fields: BIRTHDATE, DEATHDATE.
- Apparent numeric fields: LAT, LON, HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE, INCOME.
- Observed nullable fields include DEATHDATE, DRIVERS, PASSPORT, PREFIX, MIDDLE, SUFFIX, MAIDEN, MARITAL, and FIPS.

### `raw.synthea_encounters`

- Source grain: **Candidate / To Be Validated** — one encounter event.
- Identifier/reference/text fields: Id, PATIENT, ORGANIZATION, PROVIDER, PAYER, ENCOUNTERCLASS, CODE, DESCRIPTION, REASONCODE, REASONDESCRIPTION.
- Apparent timestamp fields: START, STOP.
- Apparent numeric fields: BASE_ENCOUNTER_COST, TOTAL_CLAIM_COST, PAYER_COVERAGE.
- REASONCODE and REASONDESCRIPTION are nullable in the profiled extract.

### `raw.synthea_claims`

- Source grain: **Candidate / To Be Validated** — one claim header.
- Identifier/reference/text fields: Id, PATIENTID, PROVIDERID, PRIMARYPATIENTINSURANCEID, SECONDARYPATIENTINSURANCEID, DEPARTMENTID, PATIENTDEPARTMENTID, DIAGNOSIS1-DIAGNOSIS8, REFERRINGPROVIDERID, APPOINTMENTID, SUPERVISINGPROVIDERID, STATUS1, STATUS2, STATUSP, HEALTHCARECLAIMTYPEID1, HEALTHCARECLAIMTYPEID2.
- Apparent timestamp fields: CURRENTILLNESSDATE, SERVICEDATE, LASTBILLEDDATE1, LASTBILLEDDATE2, LASTBILLEDDATEP.
- Apparent numeric fields: OUTSTANDING1, OUTSTANDING2, OUTSTANDINGP.
- Optional references, diagnosis slots, secondary status/balance values, and secondary billed dates are nullable.

### `raw.synthea_claims_transactions`

- Source grain: **Candidate / To Be Validated** — one claim financial transaction/event line.
- Identifier/reference/text fields: ID, CLAIMID, CHARGEID, PATIENTID, TYPE, METHOD, PLACEOFSERVICE, PROCEDURECODE, MODIFIER1, MODIFIER2, DIAGNOSISREF1-DIAGNOSISREF4, DEPARTMENTID, NOTES, TRANSFEROUTID, TRANSFERTYPE, APPOINTMENTID, LINENOTE, PATIENTINSURANCEID, FEESCHEDULEID, PROVIDERID, SUPERVISINGPROVIDERID.
- Apparent timestamp fields: FROMDATE, TODATE.
- Apparent numeric fields: AMOUNT, UNITS, UNITAMOUNT, PAYMENTS, ADJUSTMENTS, TRANSFERS, OUTSTANDING.
- AMOUNT, METHOD, modifiers, later diagnosis references, transfer fields, line notes, and patient insurance references can be nullable depending on transaction type.

### `raw.synthea_conditions`

- Source grain: **Candidate / To Be Validated** — one condition occurrence/episode.
- Identifier/reference/text fields: PATIENT, ENCOUNTER, SYSTEM, CODE, DESCRIPTION.
- Apparent date fields: START, STOP.
- STOP is nullable for unresolved/active condition episodes in the profiled extract.

### `raw.synthea_procedures`

- Source grain: **Candidate / To Be Validated** — one performed procedure occurrence.
- Identifier/reference/text fields: PATIENT, ENCOUNTER, SYSTEM, CODE, DESCRIPTION, REASONCODE, REASONDESCRIPTION.
- Apparent timestamp fields: START, STOP.
- Apparent numeric field: BASE_COST.
- REASONCODE and REASONDESCRIPTION are nullable in the profiled extract.

Every listed source field is implemented as nullable PostgreSQL `text` in the raw tables.

## Candidate Keys

Candidate keys are documented for profiling and lineage only; the raw layer does not enforce them.

| Raw table | Candidate key | Smoke-test evidence |
|---|---|---|
| `raw.synthea_patients` | Id | 10/10 distinct |
| `raw.synthea_encounters` | Id | 283/283 distinct |
| `raw.synthea_claims` | Id | 464/464 distinct |
| `raw.synthea_claims_transactions` | ID | 5,403/5,403 distinct |
| `raw.synthea_conditions` | PATIENT + ENCOUNTER + START + CODE | 252/252 distinct; larger extracts still require validation |
| `raw.synthea_procedures` | PATIENT + ENCOUNTER + START + CODE | 1,003/1,003 distinct; larger extracts still require validation |

## Data Type Decisions

Profiling found that the observed date, timestamp, and numeric values are compatible with their apparent semantic types. The raw DDL nevertheless uses `text` for all source columns because:

- raw must preserve source lexical values before normalization;
- future source versions may contain values that need quarantine or investigation rather than rejected ingestion;
- identifiers and codes must preserve formatting and leading zeros;
- PostgreSQL date, timestamp-with-time-zone, numeric, UUID, and other semantic conversions belong in staging;
- nullable source behavior should be evaluated explicitly during ingestion and staging validation.

The staging design will define safe casts, rejected-value handling, typed null rules, and UTC/date semantics.

## Constraints Strategy

- No primary keys or unique constraints are created.
- No `NOT NULL` constraints are created.
- No check constraints or enumerated domains are created.
- No default values are introduced.
- No duplicate rows are removed or prevented.
- Table comments record source lineage and the intentionally unenforced candidate key.

This permissive strategy is deliberate for a source-preserving layer and is not an endorsement of source quality.

## Why Foreign Keys Are Deferred

The profile supports several candidate relationships, but enforcing them in raw could reject valid out-of-order loads, incomplete extracts, nullable references, or future source variations. Referential validation will occur in staging after each source is loaded and typed. Analytics foreign keys will be introduced only in the curated layer after conformed key resolution.

## Known Risks

- Text columns defer malformed date, timestamp, and numeric detection until staging.
- Quoted source column names are case-sensitive and must be handled consistently by ingestion SQL.
- Empty CSV fields require an explicit loader policy so missing values remain distinguishable and auditable.
- Candidate source keys may not remain unique in larger or repeated-generation extracts.
- Claims and transactions have different grains; direct joins can multiply claim and encounter measures.
- Raw tables initially contain no ingestion metadata. Load ID, file hash, source row number, and ingestion timestamp must be designed before production ingestion.
- Synthea is synthetic; raw values must not be represented as real patient or hospital performance data.

## Next Step

Design and validate a controlled CSV ingestion process for these six tables, including file/header checks, load metadata, row-count reconciliation, empty-field handling, and reject reporting. No data should be loaded until that ingestion design is approved.
