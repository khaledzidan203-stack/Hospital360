-- Hospital360 RAW layer: approved Synthea V1 core sources.
-- Source-preserving design: source fields remain nullable text and are typed later in staging.
-- This script intentionally contains no data loading, primary keys, foreign keys, or business transformations.

BEGIN;

CREATE TABLE IF NOT EXISTS raw.synthea_patients (
    "Id" text,
    "BIRTHDATE" text,
    "DEATHDATE" text,
    "SSN" text,
    "DRIVERS" text,
    "PASSPORT" text,
    "PREFIX" text,
    "FIRST" text,
    "MIDDLE" text,
    "LAST" text,
    "SUFFIX" text,
    "MAIDEN" text,
    "MARITAL" text,
    "RACE" text,
    "ETHNICITY" text,
    "GENDER" text,
    "BIRTHPLACE" text,
    "ADDRESS" text,
    "CITY" text,
    "STATE" text,
    "COUNTY" text,
    "FIPS" text,
    "ZIP" text,
    "LAT" text,
    "LON" text,
    "HEALTHCARE_EXPENSES" text,
    "HEALTHCARE_COVERAGE" text,
    "INCOME" text
);

COMMENT ON TABLE raw.synthea_patients IS
    'Source-preserving landing table for data/raw/synthea/csv/patients.csv. Candidate key Id is intentionally not enforced.';

CREATE TABLE IF NOT EXISTS raw.synthea_encounters (
    "Id" text,
    "START" text,
    "STOP" text,
    "PATIENT" text,
    "ORGANIZATION" text,
    "PROVIDER" text,
    "PAYER" text,
    "ENCOUNTERCLASS" text,
    "CODE" text,
    "DESCRIPTION" text,
    "BASE_ENCOUNTER_COST" text,
    "TOTAL_CLAIM_COST" text,
    "PAYER_COVERAGE" text,
    "REASONCODE" text,
    "REASONDESCRIPTION" text
);

COMMENT ON TABLE raw.synthea_encounters IS
    'Source-preserving landing table for data/raw/synthea/csv/encounters.csv. Candidate key Id is intentionally not enforced.';

CREATE TABLE IF NOT EXISTS raw.synthea_claims (
    "Id" text,
    "PATIENTID" text,
    "PROVIDERID" text,
    "PRIMARYPATIENTINSURANCEID" text,
    "SECONDARYPATIENTINSURANCEID" text,
    "DEPARTMENTID" text,
    "PATIENTDEPARTMENTID" text,
    "DIAGNOSIS1" text,
    "DIAGNOSIS2" text,
    "DIAGNOSIS3" text,
    "DIAGNOSIS4" text,
    "DIAGNOSIS5" text,
    "DIAGNOSIS6" text,
    "DIAGNOSIS7" text,
    "DIAGNOSIS8" text,
    "REFERRINGPROVIDERID" text,
    "APPOINTMENTID" text,
    "CURRENTILLNESSDATE" text,
    "SERVICEDATE" text,
    "SUPERVISINGPROVIDERID" text,
    "STATUS1" text,
    "STATUS2" text,
    "STATUSP" text,
    "OUTSTANDING1" text,
    "OUTSTANDING2" text,
    "OUTSTANDINGP" text,
    "LASTBILLEDDATE1" text,
    "LASTBILLEDDATE2" text,
    "LASTBILLEDDATEP" text,
    "HEALTHCARECLAIMTYPEID1" text,
    "HEALTHCARECLAIMTYPEID2" text
);

COMMENT ON TABLE raw.synthea_claims IS
    'Source-preserving landing table for data/raw/synthea/csv/claims.csv. Candidate key Id is intentionally not enforced.';

CREATE TABLE IF NOT EXISTS raw.synthea_claims_transactions (
    "ID" text,
    "CLAIMID" text,
    "CHARGEID" text,
    "PATIENTID" text,
    "TYPE" text,
    "AMOUNT" text,
    "METHOD" text,
    "FROMDATE" text,
    "TODATE" text,
    "PLACEOFSERVICE" text,
    "PROCEDURECODE" text,
    "MODIFIER1" text,
    "MODIFIER2" text,
    "DIAGNOSISREF1" text,
    "DIAGNOSISREF2" text,
    "DIAGNOSISREF3" text,
    "DIAGNOSISREF4" text,
    "UNITS" text,
    "DEPARTMENTID" text,
    "NOTES" text,
    "UNITAMOUNT" text,
    "TRANSFEROUTID" text,
    "TRANSFERTYPE" text,
    "PAYMENTS" text,
    "ADJUSTMENTS" text,
    "TRANSFERS" text,
    "OUTSTANDING" text,
    "APPOINTMENTID" text,
    "LINENOTE" text,
    "PATIENTINSURANCEID" text,
    "FEESCHEDULEID" text,
    "PROVIDERID" text,
    "SUPERVISINGPROVIDERID" text
);

COMMENT ON TABLE raw.synthea_claims_transactions IS
    'Source-preserving landing table for data/raw/synthea/csv/claims_transactions.csv. Candidate key ID is intentionally not enforced.';

CREATE TABLE IF NOT EXISTS raw.synthea_conditions (
    "START" text,
    "STOP" text,
    "PATIENT" text,
    "ENCOUNTER" text,
    "SYSTEM" text,
    "CODE" text,
    "DESCRIPTION" text
);

COMMENT ON TABLE raw.synthea_conditions IS
    'Source-preserving landing table for data/raw/synthea/csv/conditions.csv. Candidate composite key is intentionally not enforced.';

CREATE TABLE IF NOT EXISTS raw.synthea_procedures (
    "START" text,
    "STOP" text,
    "PATIENT" text,
    "ENCOUNTER" text,
    "SYSTEM" text,
    "CODE" text,
    "DESCRIPTION" text,
    "BASE_COST" text,
    "REASONCODE" text,
    "REASONDESCRIPTION" text
);

COMMENT ON TABLE raw.synthea_procedures IS
    'Source-preserving landing table for data/raw/synthea/csv/procedures.csv. Candidate composite key is intentionally not enforced.';

COMMIT;
