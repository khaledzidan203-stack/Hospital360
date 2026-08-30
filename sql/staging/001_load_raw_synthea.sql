\set ON_ERROR_STOP on

-- Hospital360 Synthea V1 RAW snapshot ingestion.
-- This development load uses a deterministic truncate-and-reload strategy.
-- It loads source values as supplied and performs no business transformation.

BEGIN;

-- Load patients.csv into the source-preserving RAW patients table.
TRUNCATE TABLE raw.synthea_patients;
\copy raw.synthea_patients ("Id", "BIRTHDATE", "DEATHDATE", "SSN", "DRIVERS", "PASSPORT", "PREFIX", "FIRST", "MIDDLE", "LAST", "SUFFIX", "MAIDEN", "MARITAL", "RACE", "ETHNICITY", "GENDER", "BIRTHPLACE", "ADDRESS", "CITY", "STATE", "COUNTY", "FIPS", "ZIP", "LAT", "LON", "HEALTHCARE_EXPENSES", "HEALTHCARE_COVERAGE", "INCOME") FROM 'D:/Hospital360/data/raw/synthea/csv/patients.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Load encounters.csv into the source-preserving RAW encounters table.
TRUNCATE TABLE raw.synthea_encounters;
\copy raw.synthea_encounters ("Id", "START", "STOP", "PATIENT", "ORGANIZATION", "PROVIDER", "PAYER", "ENCOUNTERCLASS", "CODE", "DESCRIPTION", "BASE_ENCOUNTER_COST", "TOTAL_CLAIM_COST", "PAYER_COVERAGE", "REASONCODE", "REASONDESCRIPTION") FROM 'D:/Hospital360/data/raw/synthea/csv/encounters.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Load claims.csv into the source-preserving RAW claims table.
TRUNCATE TABLE raw.synthea_claims;
\copy raw.synthea_claims ("Id", "PATIENTID", "PROVIDERID", "PRIMARYPATIENTINSURANCEID", "SECONDARYPATIENTINSURANCEID", "DEPARTMENTID", "PATIENTDEPARTMENTID", "DIAGNOSIS1", "DIAGNOSIS2", "DIAGNOSIS3", "DIAGNOSIS4", "DIAGNOSIS5", "DIAGNOSIS6", "DIAGNOSIS7", "DIAGNOSIS8", "REFERRINGPROVIDERID", "APPOINTMENTID", "CURRENTILLNESSDATE", "SERVICEDATE", "SUPERVISINGPROVIDERID", "STATUS1", "STATUS2", "STATUSP", "OUTSTANDING1", "OUTSTANDING2", "OUTSTANDINGP", "LASTBILLEDDATE1", "LASTBILLEDDATE2", "LASTBILLEDDATEP", "HEALTHCARECLAIMTYPEID1", "HEALTHCARECLAIMTYPEID2") FROM 'D:/Hospital360/data/raw/synthea/csv/claims.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Load claims_transactions.csv into the source-preserving RAW claim transactions table.
TRUNCATE TABLE raw.synthea_claims_transactions;
\copy raw.synthea_claims_transactions ("ID", "CLAIMID", "CHARGEID", "PATIENTID", "TYPE", "AMOUNT", "METHOD", "FROMDATE", "TODATE", "PLACEOFSERVICE", "PROCEDURECODE", "MODIFIER1", "MODIFIER2", "DIAGNOSISREF1", "DIAGNOSISREF2", "DIAGNOSISREF3", "DIAGNOSISREF4", "UNITS", "DEPARTMENTID", "NOTES", "UNITAMOUNT", "TRANSFEROUTID", "TRANSFERTYPE", "PAYMENTS", "ADJUSTMENTS", "TRANSFERS", "OUTSTANDING", "APPOINTMENTID", "LINENOTE", "PATIENTINSURANCEID", "FEESCHEDULEID", "PROVIDERID", "SUPERVISINGPROVIDERID") FROM 'D:/Hospital360/data/raw/synthea/csv/claims_transactions.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Load conditions.csv into the source-preserving RAW conditions table.
TRUNCATE TABLE raw.synthea_conditions;
\copy raw.synthea_conditions ("START", "STOP", "PATIENT", "ENCOUNTER", "SYSTEM", "CODE", "DESCRIPTION") FROM 'D:/Hospital360/data/raw/synthea/csv/conditions.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Load procedures.csv into the source-preserving RAW procedures table.
TRUNCATE TABLE raw.synthea_procedures;
\copy raw.synthea_procedures ("START", "STOP", "PATIENT", "ENCOUNTER", "SYSTEM", "CODE", "DESCRIPTION", "BASE_COST", "REASONCODE", "REASONDESCRIPTION") FROM 'D:/Hospital360/data/raw/synthea/csv/procedures.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COMMIT;
