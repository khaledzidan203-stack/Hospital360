\set ON_ERROR_STOP on

-- Hospital360 Synthea STAGING Performance V2 RAW-to-STAGING transformation.
-- V1 (003_transform_raw_to_staging.sql) remains the correctness baseline.
-- V2 separates bulk typed loading from narrow duplicate and indexed reference DQ checks.
-- Current development strategy: deterministic truncate-and-reload.
-- Rows are retained at source grain; invalid conversions become typed NULLs and
-- are exposed through dq_conversion_errors rather than hidden or discarded.

BEGIN;

TRUNCATE TABLE staging.stg_patients;
TRUNCATE TABLE staging.stg_encounters;
TRUNCATE TABLE staging.stg_claims;
TRUNCATE TABLE staging.stg_claim_transactions;
TRUNCATE TABLE staging.stg_condition_occurrences;
TRUNCATE TABLE staging.stg_procedures;

-- One staging row per raw patient row.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."Id"), '') AS "Id",
        NULLIF(btrim(r."BIRTHDATE"), '') AS "BIRTHDATE",
        NULLIF(btrim(r."DEATHDATE"), '') AS "DEATHDATE",
        NULLIF(btrim(r."SSN"), '') AS "SSN",
        NULLIF(btrim(r."DRIVERS"), '') AS "DRIVERS",
        NULLIF(btrim(r."PASSPORT"), '') AS "PASSPORT",
        NULLIF(btrim(r."PREFIX"), '') AS "PREFIX",
        NULLIF(btrim(r."FIRST"), '') AS "FIRST",
        NULLIF(btrim(r."MIDDLE"), '') AS "MIDDLE",
        NULLIF(btrim(r."LAST"), '') AS "LAST",
        NULLIF(btrim(r."SUFFIX"), '') AS "SUFFIX",
        NULLIF(btrim(r."MAIDEN"), '') AS "MAIDEN",
        NULLIF(btrim(r."MARITAL"), '') AS "MARITAL",
        NULLIF(btrim(r."RACE"), '') AS "RACE",
        NULLIF(btrim(r."ETHNICITY"), '') AS "ETHNICITY",
        NULLIF(btrim(r."GENDER"), '') AS "GENDER",
        NULLIF(btrim(r."BIRTHPLACE"), '') AS "BIRTHPLACE",
        NULLIF(btrim(r."ADDRESS"), '') AS "ADDRESS",
        NULLIF(btrim(r."CITY"), '') AS "CITY",
        NULLIF(btrim(r."STATE"), '') AS "STATE",
        NULLIF(btrim(r."COUNTY"), '') AS "COUNTY",
        NULLIF(btrim(r."FIPS"), '') AS "FIPS",
        NULLIF(btrim(r."ZIP"), '') AS "ZIP",
        NULLIF(btrim(r."LAT"), '') AS "LAT",
        NULLIF(btrim(r."LON"), '') AS "LON",
        NULLIF(btrim(r."HEALTHCARE_EXPENSES"), '') AS "HEALTHCARE_EXPENSES",
        NULLIF(btrim(r."HEALTHCARE_COVERAGE"), '') AS "HEALTHCARE_COVERAGE",
        NULLIF(btrim(r."INCOME"), '') AS "INCOME"
    FROM raw.synthea_patients r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."BIRTHDATE", 'date') AS "BIRTHDATE__date_valid",
        pg_input_is_valid(n."DEATHDATE", 'date') AS "DEATHDATE__date_valid",
        pg_input_is_valid(n."LAT", 'numeric') AS "LAT__numeric_valid",
        pg_input_is_valid(n."LON", 'numeric') AS "LON__numeric_valid",
        pg_input_is_valid(n."HEALTHCARE_EXPENSES", 'numeric') AS "HEALTHCARE_EXPENSES__numeric_valid",
        pg_input_is_valid(n."HEALTHCARE_COVERAGE", 'numeric') AS "HEALTHCARE_COVERAGE__numeric_valid",
        pg_input_is_valid(n."INCOME", 'numeric') AS "INCOME__numeric_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        r."Id" AS patient_id,
        CASE WHEN r."BIRTHDATE__date_valid" THEN r."BIRTHDATE"::date END AS birth_date,
        CASE WHEN r."DEATHDATE__date_valid" THEN r."DEATHDATE"::date END AS death_date,
        r."SSN" AS ssn,
        r."DRIVERS" AS drivers_license,
        r."PASSPORT" AS passport_number,
        r."PREFIX" AS name_prefix,
        r."FIRST" AS first_name,
        r."MIDDLE" AS middle_name,
        r."LAST" AS last_name,
        r."SUFFIX" AS name_suffix,
        r."MAIDEN" AS maiden_name,
        r."MARITAL" AS marital_status,
        r."RACE" AS race,
        r."ETHNICITY" AS ethnicity,
        r."GENDER" AS gender,
        r."BIRTHPLACE" AS birthplace,
        r."ADDRESS" AS address,
        r."CITY" AS city,
        r."STATE" AS state,
        r."COUNTY" AS county,
        r."FIPS" AS fips,
        r."ZIP" AS zip,
        CASE WHEN r."LAT__numeric_valid" THEN r."LAT"::numeric END AS latitude,
        CASE WHEN r."LON__numeric_valid" THEN r."LON"::numeric END AS longitude,
        CASE WHEN r."HEALTHCARE_EXPENSES__numeric_valid" THEN r."HEALTHCARE_EXPENSES"::numeric END AS healthcare_expenses,
        CASE WHEN r."HEALTHCARE_COVERAGE__numeric_valid" THEN r."HEALTHCARE_COVERAGE"::numeric END AS healthcare_coverage,
        CASE WHEN r."INCOME__numeric_valid" THEN r."INCOME"::numeric END AS income,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."BIRTHDATE" IS NOT NULL AND NOT r."BIRTHDATE__date_valid" THEN 'BIRTHDATE'::text END,
            CASE WHEN r."DEATHDATE" IS NOT NULL AND NOT r."DEATHDATE__date_valid" THEN 'DEATHDATE'::text END,
            CASE WHEN r."LAT" IS NOT NULL AND NOT r."LAT__numeric_valid" THEN 'LAT'::text END,
            CASE WHEN r."LON" IS NOT NULL AND NOT r."LON__numeric_valid" THEN 'LON'::text END,
            CASE WHEN r."HEALTHCARE_EXPENSES" IS NOT NULL AND NOT r."HEALTHCARE_EXPENSES__numeric_valid" THEN 'HEALTHCARE_EXPENSES'::text END,
            CASE WHEN r."HEALTHCARE_COVERAGE" IS NOT NULL AND NOT r."HEALTHCARE_COVERAGE__numeric_valid" THEN 'HEALTHCARE_COVERAGE'::text END,
            CASE WHEN r."INCOME" IS NOT NULL AND NOT r."INCOME__numeric_valid" THEN 'INCOME'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_patients (
    patient_id, birth_date, death_date, ssn, drivers_license, passport_number,
    name_prefix, first_name, middle_name, last_name, name_suffix, maiden_name,
    marital_status, race, ethnicity, gender, birthplace, address, city, state,
    county, fips, zip, latitude, longitude, healthcare_expenses,
    healthcare_coverage, income, source_system, source_table, source_row_hash,
    dq_missing_patient_id, dq_duplicate_patient_id, dq_invalid_birth_date,
    dq_invalid_death_date, dq_death_before_birth, dq_conversion_errors,
    dq_has_conversion_error
)
SELECT
    patient_id, birth_date, death_date, ssn, drivers_license, passport_number,
    name_prefix, first_name, middle_name, last_name, name_suffix, maiden_name,
    marital_status, race, ethnicity, gender, birthplace, address, city, state,
    county, fips, zip, latitude, longitude, healthcare_expenses,
    healthcare_coverage, income, 'SYNTHEA', 'raw.synthea_patients', source_row_hash,
    patient_id IS NULL,
    false,
    'BIRTHDATE' = ANY(conversion_errors),
    'DEATHDATE' = ANY(conversion_errors),
    birth_date IS NOT NULL AND death_date IS NOT NULL AND death_date < birth_date,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw encounter row.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."Id"), '') AS "Id",
        NULLIF(btrim(r."START"), '') AS "START",
        NULLIF(btrim(r."STOP"), '') AS "STOP",
        NULLIF(btrim(r."PATIENT"), '') AS "PATIENT",
        NULLIF(btrim(r."ORGANIZATION"), '') AS "ORGANIZATION",
        NULLIF(btrim(r."PROVIDER"), '') AS "PROVIDER",
        NULLIF(btrim(r."PAYER"), '') AS "PAYER",
        NULLIF(btrim(r."ENCOUNTERCLASS"), '') AS "ENCOUNTERCLASS",
        NULLIF(btrim(r."CODE"), '') AS "CODE",
        NULLIF(btrim(r."DESCRIPTION"), '') AS "DESCRIPTION",
        NULLIF(btrim(r."BASE_ENCOUNTER_COST"), '') AS "BASE_ENCOUNTER_COST",
        NULLIF(btrim(r."TOTAL_CLAIM_COST"), '') AS "TOTAL_CLAIM_COST",
        NULLIF(btrim(r."PAYER_COVERAGE"), '') AS "PAYER_COVERAGE",
        NULLIF(btrim(r."REASONCODE"), '') AS "REASONCODE",
        NULLIF(btrim(r."REASONDESCRIPTION"), '') AS "REASONDESCRIPTION"
    FROM raw.synthea_encounters r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."START", 'timestamp with time zone') AS "START__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."STOP", 'timestamp with time zone') AS "STOP__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."BASE_ENCOUNTER_COST", 'numeric') AS "BASE_ENCOUNTER_COST__numeric_valid",
        pg_input_is_valid(n."TOTAL_CLAIM_COST", 'numeric') AS "TOTAL_CLAIM_COST__numeric_valid",
        pg_input_is_valid(n."PAYER_COVERAGE", 'numeric') AS "PAYER_COVERAGE__numeric_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        r."Id" AS encounter_id,
        CASE WHEN r."START__timestamp_with_time_zone_valid" THEN r."START"::timestamptz END AS start_at,
        CASE WHEN r."STOP__timestamp_with_time_zone_valid" THEN r."STOP"::timestamptz END AS stop_at,
        r."PATIENT" AS patient_id,
        r."ORGANIZATION" AS organization_id,
        r."PROVIDER" AS provider_id,
        r."PAYER" AS payer_id,
        r."ENCOUNTERCLASS" AS encounter_class,
        r."CODE" AS encounter_code,
        r."DESCRIPTION" AS encounter_description,
        CASE WHEN r."BASE_ENCOUNTER_COST__numeric_valid" THEN r."BASE_ENCOUNTER_COST"::numeric END AS base_encounter_cost,
        CASE WHEN r."TOTAL_CLAIM_COST__numeric_valid" THEN r."TOTAL_CLAIM_COST"::numeric END AS total_claim_cost,
        CASE WHEN r."PAYER_COVERAGE__numeric_valid" THEN r."PAYER_COVERAGE"::numeric END AS payer_coverage,
        r."REASONCODE" AS reason_code,
        r."REASONDESCRIPTION" AS reason_description,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."START" IS NOT NULL AND NOT r."START__timestamp_with_time_zone_valid" THEN 'START'::text END,
            CASE WHEN r."STOP" IS NOT NULL AND NOT r."STOP__timestamp_with_time_zone_valid" THEN 'STOP'::text END,
            CASE WHEN r."BASE_ENCOUNTER_COST" IS NOT NULL AND NOT r."BASE_ENCOUNTER_COST__numeric_valid" THEN 'BASE_ENCOUNTER_COST'::text END,
            CASE WHEN r."TOTAL_CLAIM_COST" IS NOT NULL AND NOT r."TOTAL_CLAIM_COST__numeric_valid" THEN 'TOTAL_CLAIM_COST'::text END,
            CASE WHEN r."PAYER_COVERAGE" IS NOT NULL AND NOT r."PAYER_COVERAGE__numeric_valid" THEN 'PAYER_COVERAGE'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_encounters (
    encounter_id, start_at, stop_at, patient_id, organization_id, provider_id,
    payer_id, encounter_class, encounter_code, encounter_description,
    base_encounter_cost, total_claim_cost, payer_coverage, reason_code,
    reason_description, source_system, source_table, source_row_hash,
    dq_missing_encounter_id, dq_duplicate_encounter_id, dq_missing_patient_id,
    dq_patient_not_found, dq_start_after_stop, dq_negative_amount,
    dq_conversion_errors, dq_has_conversion_error
)
SELECT
    encounter_id, start_at, stop_at, patient_id, organization_id, provider_id,
    payer_id, encounter_class, encounter_code, encounter_description,
    base_encounter_cost, total_claim_cost, payer_coverage, reason_code,
    reason_description, 'SYNTHEA', 'raw.synthea_encounters', source_row_hash,
    encounter_id IS NULL,
    false,
    patient_id IS NULL,
    false,
    start_at IS NOT NULL AND stop_at IS NOT NULL AND start_at > stop_at,
    COALESCE(base_encounter_cost < 0, false) OR COALESCE(total_claim_cost < 0, false) OR COALESCE(payer_coverage < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw claim-header row.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."Id"), '') AS "Id",
        NULLIF(btrim(r."PATIENTID"), '') AS "PATIENTID",
        NULLIF(btrim(r."PROVIDERID"), '') AS "PROVIDERID",
        NULLIF(btrim(r."PRIMARYPATIENTINSURANCEID"), '') AS "PRIMARYPATIENTINSURANCEID",
        NULLIF(btrim(r."SECONDARYPATIENTINSURANCEID"), '') AS "SECONDARYPATIENTINSURANCEID",
        NULLIF(btrim(r."DEPARTMENTID"), '') AS "DEPARTMENTID",
        NULLIF(btrim(r."PATIENTDEPARTMENTID"), '') AS "PATIENTDEPARTMENTID",
        NULLIF(btrim(r."DIAGNOSIS1"), '') AS "DIAGNOSIS1",
        NULLIF(btrim(r."DIAGNOSIS2"), '') AS "DIAGNOSIS2",
        NULLIF(btrim(r."DIAGNOSIS3"), '') AS "DIAGNOSIS3",
        NULLIF(btrim(r."DIAGNOSIS4"), '') AS "DIAGNOSIS4",
        NULLIF(btrim(r."DIAGNOSIS5"), '') AS "DIAGNOSIS5",
        NULLIF(btrim(r."DIAGNOSIS6"), '') AS "DIAGNOSIS6",
        NULLIF(btrim(r."DIAGNOSIS7"), '') AS "DIAGNOSIS7",
        NULLIF(btrim(r."DIAGNOSIS8"), '') AS "DIAGNOSIS8",
        NULLIF(btrim(r."REFERRINGPROVIDERID"), '') AS "REFERRINGPROVIDERID",
        NULLIF(btrim(r."APPOINTMENTID"), '') AS "APPOINTMENTID",
        NULLIF(btrim(r."CURRENTILLNESSDATE"), '') AS "CURRENTILLNESSDATE",
        NULLIF(btrim(r."SERVICEDATE"), '') AS "SERVICEDATE",
        NULLIF(btrim(r."SUPERVISINGPROVIDERID"), '') AS "SUPERVISINGPROVIDERID",
        NULLIF(btrim(r."STATUS1"), '') AS "STATUS1",
        NULLIF(btrim(r."STATUS2"), '') AS "STATUS2",
        NULLIF(btrim(r."STATUSP"), '') AS "STATUSP",
        NULLIF(btrim(r."OUTSTANDING1"), '') AS "OUTSTANDING1",
        NULLIF(btrim(r."OUTSTANDING2"), '') AS "OUTSTANDING2",
        NULLIF(btrim(r."OUTSTANDINGP"), '') AS "OUTSTANDINGP",
        NULLIF(btrim(r."LASTBILLEDDATE1"), '') AS "LASTBILLEDDATE1",
        NULLIF(btrim(r."LASTBILLEDDATE2"), '') AS "LASTBILLEDDATE2",
        NULLIF(btrim(r."LASTBILLEDDATEP"), '') AS "LASTBILLEDDATEP",
        NULLIF(btrim(r."HEALTHCARECLAIMTYPEID1"), '') AS "HEALTHCARECLAIMTYPEID1",
        NULLIF(btrim(r."HEALTHCARECLAIMTYPEID2"), '') AS "HEALTHCARECLAIMTYPEID2"
    FROM raw.synthea_claims r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."DEPARTMENTID", 'integer') AS "DEPARTMENTID__integer_valid",
        pg_input_is_valid(n."PATIENTDEPARTMENTID", 'integer') AS "PATIENTDEPARTMENTID__integer_valid",
        pg_input_is_valid(n."CURRENTILLNESSDATE", 'timestamp with time zone') AS "CURRENTILLNESSDATE__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."SERVICEDATE", 'timestamp with time zone') AS "SERVICEDATE__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."OUTSTANDING1", 'numeric') AS "OUTSTANDING1__numeric_valid",
        pg_input_is_valid(n."OUTSTANDING2", 'numeric') AS "OUTSTANDING2__numeric_valid",
        pg_input_is_valid(n."OUTSTANDINGP", 'numeric') AS "OUTSTANDINGP__numeric_valid",
        pg_input_is_valid(n."LASTBILLEDDATE1", 'timestamp with time zone') AS "LASTBILLEDDATE1__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."LASTBILLEDDATE2", 'timestamp with time zone') AS "LASTBILLEDDATE2__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."LASTBILLEDDATEP", 'timestamp with time zone') AS "LASTBILLEDDATEP__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."HEALTHCARECLAIMTYPEID1", 'integer') AS "HEALTHCARECLAIMTYPEID1__integer_valid",
        pg_input_is_valid(n."HEALTHCARECLAIMTYPEID2", 'integer') AS "HEALTHCARECLAIMTYPEID2__integer_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        r."Id" AS claim_id,
        r."PATIENTID" AS patient_id,
        r."PROVIDERID" AS provider_id,
        r."PRIMARYPATIENTINSURANCEID" AS primary_patient_insurance_id,
        r."SECONDARYPATIENTINSURANCEID" AS secondary_patient_insurance_id,
        CASE WHEN r."DEPARTMENTID__integer_valid" THEN r."DEPARTMENTID"::integer END AS department_id,
        CASE WHEN r."PATIENTDEPARTMENTID__integer_valid" THEN r."PATIENTDEPARTMENTID"::integer END AS patient_department_id,
        r."DIAGNOSIS1" AS diagnosis_1,
        r."DIAGNOSIS2" AS diagnosis_2,
        r."DIAGNOSIS3" AS diagnosis_3,
        r."DIAGNOSIS4" AS diagnosis_4,
        r."DIAGNOSIS5" AS diagnosis_5,
        r."DIAGNOSIS6" AS diagnosis_6,
        r."DIAGNOSIS7" AS diagnosis_7,
        r."DIAGNOSIS8" AS diagnosis_8,
        r."REFERRINGPROVIDERID" AS referring_provider_id,
        r."APPOINTMENTID" AS appointment_id,
        CASE WHEN r."CURRENTILLNESSDATE__timestamp_with_time_zone_valid" THEN r."CURRENTILLNESSDATE"::timestamptz END AS current_illness_at,
        CASE WHEN r."SERVICEDATE__timestamp_with_time_zone_valid" THEN r."SERVICEDATE"::timestamptz END AS service_at,
        r."SUPERVISINGPROVIDERID" AS supervising_provider_id,
        r."STATUS1" AS status_1,
        r."STATUS2" AS status_2,
        r."STATUSP" AS status_primary,
        CASE WHEN r."OUTSTANDING1__numeric_valid" THEN r."OUTSTANDING1"::numeric END AS outstanding_1,
        CASE WHEN r."OUTSTANDING2__numeric_valid" THEN r."OUTSTANDING2"::numeric END AS outstanding_2,
        CASE WHEN r."OUTSTANDINGP__numeric_valid" THEN r."OUTSTANDINGP"::numeric END AS outstanding_primary,
        CASE WHEN r."LASTBILLEDDATE1__timestamp_with_time_zone_valid" THEN r."LASTBILLEDDATE1"::timestamptz END AS last_billed_at_1,
        CASE WHEN r."LASTBILLEDDATE2__timestamp_with_time_zone_valid" THEN r."LASTBILLEDDATE2"::timestamptz END AS last_billed_at_2,
        CASE WHEN r."LASTBILLEDDATEP__timestamp_with_time_zone_valid" THEN r."LASTBILLEDDATEP"::timestamptz END AS last_billed_at_primary,
        CASE WHEN r."HEALTHCARECLAIMTYPEID1__integer_valid" THEN r."HEALTHCARECLAIMTYPEID1"::integer END AS healthcare_claim_type_id_1,
        CASE WHEN r."HEALTHCARECLAIMTYPEID2__integer_valid" THEN r."HEALTHCARECLAIMTYPEID2"::integer END AS healthcare_claim_type_id_2,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."DEPARTMENTID" IS NOT NULL AND NOT r."DEPARTMENTID__integer_valid" THEN 'DEPARTMENTID'::text END,
            CASE WHEN r."PATIENTDEPARTMENTID" IS NOT NULL AND NOT r."PATIENTDEPARTMENTID__integer_valid" THEN 'PATIENTDEPARTMENTID'::text END,
            CASE WHEN r."CURRENTILLNESSDATE" IS NOT NULL AND NOT r."CURRENTILLNESSDATE__timestamp_with_time_zone_valid" THEN 'CURRENTILLNESSDATE'::text END,
            CASE WHEN r."SERVICEDATE" IS NOT NULL AND NOT r."SERVICEDATE__timestamp_with_time_zone_valid" THEN 'SERVICEDATE'::text END,
            CASE WHEN r."OUTSTANDING1" IS NOT NULL AND NOT r."OUTSTANDING1__numeric_valid" THEN 'OUTSTANDING1'::text END,
            CASE WHEN r."OUTSTANDING2" IS NOT NULL AND NOT r."OUTSTANDING2__numeric_valid" THEN 'OUTSTANDING2'::text END,
            CASE WHEN r."OUTSTANDINGP" IS NOT NULL AND NOT r."OUTSTANDINGP__numeric_valid" THEN 'OUTSTANDINGP'::text END,
            CASE WHEN r."LASTBILLEDDATE1" IS NOT NULL AND NOT r."LASTBILLEDDATE1__timestamp_with_time_zone_valid" THEN 'LASTBILLEDDATE1'::text END,
            CASE WHEN r."LASTBILLEDDATE2" IS NOT NULL AND NOT r."LASTBILLEDDATE2__timestamp_with_time_zone_valid" THEN 'LASTBILLEDDATE2'::text END,
            CASE WHEN r."LASTBILLEDDATEP" IS NOT NULL AND NOT r."LASTBILLEDDATEP__timestamp_with_time_zone_valid" THEN 'LASTBILLEDDATEP'::text END,
            CASE WHEN r."HEALTHCARECLAIMTYPEID1" IS NOT NULL AND NOT r."HEALTHCARECLAIMTYPEID1__integer_valid" THEN 'HEALTHCARECLAIMTYPEID1'::text END,
            CASE WHEN r."HEALTHCARECLAIMTYPEID2" IS NOT NULL AND NOT r."HEALTHCARECLAIMTYPEID2__integer_valid" THEN 'HEALTHCARECLAIMTYPEID2'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_claims (
    claim_id, patient_id, provider_id, primary_patient_insurance_id,
    secondary_patient_insurance_id, department_id, patient_department_id,
    diagnosis_1, diagnosis_2, diagnosis_3, diagnosis_4, diagnosis_5,
    diagnosis_6, diagnosis_7, diagnosis_8, referring_provider_id,
    appointment_id, current_illness_at, service_at, supervising_provider_id,
    status_1, status_2, status_primary, outstanding_1, outstanding_2,
    outstanding_primary, last_billed_at_1, last_billed_at_2,
    last_billed_at_primary, healthcare_claim_type_id_1,
    healthcare_claim_type_id_2, source_system, source_table, source_row_hash,
    dq_missing_claim_id, dq_duplicate_claim_id, dq_missing_patient_id,
    dq_patient_not_found, dq_encounter_not_found, dq_negative_amount,
    dq_conversion_errors, dq_has_conversion_error
)
SELECT
    claim_id, patient_id, provider_id, primary_patient_insurance_id,
    secondary_patient_insurance_id, department_id, patient_department_id,
    diagnosis_1, diagnosis_2, diagnosis_3, diagnosis_4, diagnosis_5,
    diagnosis_6, diagnosis_7, diagnosis_8, referring_provider_id,
    appointment_id, current_illness_at, service_at, supervising_provider_id,
    status_1, status_2, status_primary, outstanding_1, outstanding_2,
    outstanding_primary, last_billed_at_1, last_billed_at_2,
    last_billed_at_primary, healthcare_claim_type_id_1,
    healthcare_claim_type_id_2, 'SYNTHEA', 'raw.synthea_claims', source_row_hash,
    claim_id IS NULL,
    false,
    patient_id IS NULL,
    false,
    false,
    COALESCE(outstanding_1 < 0, false) OR COALESCE(outstanding_2 < 0, false) OR COALESCE(outstanding_primary < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw claim transaction/event line.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."ID"), '') AS "ID",
        NULLIF(btrim(r."CLAIMID"), '') AS "CLAIMID",
        NULLIF(btrim(r."CHARGEID"), '') AS "CHARGEID",
        NULLIF(btrim(r."PATIENTID"), '') AS "PATIENTID",
        NULLIF(btrim(r."TYPE"), '') AS "TYPE",
        NULLIF(btrim(r."AMOUNT"), '') AS "AMOUNT",
        NULLIF(btrim(r."METHOD"), '') AS "METHOD",
        NULLIF(btrim(r."FROMDATE"), '') AS "FROMDATE",
        NULLIF(btrim(r."TODATE"), '') AS "TODATE",
        NULLIF(btrim(r."PLACEOFSERVICE"), '') AS "PLACEOFSERVICE",
        NULLIF(btrim(r."PROCEDURECODE"), '') AS "PROCEDURECODE",
        NULLIF(btrim(r."MODIFIER1"), '') AS "MODIFIER1",
        NULLIF(btrim(r."MODIFIER2"), '') AS "MODIFIER2",
        NULLIF(btrim(r."DIAGNOSISREF1"), '') AS "DIAGNOSISREF1",
        NULLIF(btrim(r."DIAGNOSISREF2"), '') AS "DIAGNOSISREF2",
        NULLIF(btrim(r."DIAGNOSISREF3"), '') AS "DIAGNOSISREF3",
        NULLIF(btrim(r."DIAGNOSISREF4"), '') AS "DIAGNOSISREF4",
        NULLIF(btrim(r."UNITS"), '') AS "UNITS",
        NULLIF(btrim(r."DEPARTMENTID"), '') AS "DEPARTMENTID",
        NULLIF(btrim(r."NOTES"), '') AS "NOTES",
        NULLIF(btrim(r."UNITAMOUNT"), '') AS "UNITAMOUNT",
        NULLIF(btrim(r."TRANSFEROUTID"), '') AS "TRANSFEROUTID",
        NULLIF(btrim(r."TRANSFERTYPE"), '') AS "TRANSFERTYPE",
        NULLIF(btrim(r."PAYMENTS"), '') AS "PAYMENTS",
        NULLIF(btrim(r."ADJUSTMENTS"), '') AS "ADJUSTMENTS",
        NULLIF(btrim(r."TRANSFERS"), '') AS "TRANSFERS",
        NULLIF(btrim(r."OUTSTANDING"), '') AS "OUTSTANDING",
        NULLIF(btrim(r."APPOINTMENTID"), '') AS "APPOINTMENTID",
        NULLIF(btrim(r."LINENOTE"), '') AS "LINENOTE",
        NULLIF(btrim(r."PATIENTINSURANCEID"), '') AS "PATIENTINSURANCEID",
        NULLIF(btrim(r."FEESCHEDULEID"), '') AS "FEESCHEDULEID",
        NULLIF(btrim(r."PROVIDERID"), '') AS "PROVIDERID",
        NULLIF(btrim(r."SUPERVISINGPROVIDERID"), '') AS "SUPERVISINGPROVIDERID"
    FROM raw.synthea_claims_transactions r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."AMOUNT", 'numeric') AS "AMOUNT__numeric_valid",
        pg_input_is_valid(n."FROMDATE", 'timestamp with time zone') AS "FROMDATE__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."TODATE", 'timestamp with time zone') AS "TODATE__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."DIAGNOSISREF1", 'integer') AS "DIAGNOSISREF1__integer_valid",
        pg_input_is_valid(n."DIAGNOSISREF2", 'integer') AS "DIAGNOSISREF2__integer_valid",
        pg_input_is_valid(n."DIAGNOSISREF3", 'integer') AS "DIAGNOSISREF3__integer_valid",
        pg_input_is_valid(n."DIAGNOSISREF4", 'integer') AS "DIAGNOSISREF4__integer_valid",
        pg_input_is_valid(n."UNITS", 'numeric') AS "UNITS__numeric_valid",
        pg_input_is_valid(n."DEPARTMENTID", 'integer') AS "DEPARTMENTID__integer_valid",
        pg_input_is_valid(n."UNITAMOUNT", 'numeric') AS "UNITAMOUNT__numeric_valid",
        pg_input_is_valid(n."PAYMENTS", 'numeric') AS "PAYMENTS__numeric_valid",
        pg_input_is_valid(n."ADJUSTMENTS", 'numeric') AS "ADJUSTMENTS__numeric_valid",
        pg_input_is_valid(n."TRANSFERS", 'numeric') AS "TRANSFERS__numeric_valid",
        pg_input_is_valid(n."OUTSTANDING", 'numeric') AS "OUTSTANDING__numeric_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        r."ID" AS transaction_id,
        r."CLAIMID" AS claim_id,
        r."CHARGEID" AS charge_id,
        r."PATIENTID" AS patient_id,
        r."TYPE" AS transaction_type,
        CASE WHEN r."AMOUNT__numeric_valid" THEN r."AMOUNT"::numeric END AS amount,
        r."METHOD" AS method,
        CASE WHEN r."FROMDATE__timestamp_with_time_zone_valid" THEN r."FROMDATE"::timestamptz END AS from_at,
        CASE WHEN r."TODATE__timestamp_with_time_zone_valid" THEN r."TODATE"::timestamptz END AS to_at,
        r."PLACEOFSERVICE" AS place_of_service_id,
        r."PROCEDURECODE" AS procedure_code,
        r."MODIFIER1" AS modifier_1,
        r."MODIFIER2" AS modifier_2,
        CASE WHEN r."DIAGNOSISREF1__integer_valid" THEN r."DIAGNOSISREF1"::integer END AS diagnosis_ref_1,
        CASE WHEN r."DIAGNOSISREF2__integer_valid" THEN r."DIAGNOSISREF2"::integer END AS diagnosis_ref_2,
        CASE WHEN r."DIAGNOSISREF3__integer_valid" THEN r."DIAGNOSISREF3"::integer END AS diagnosis_ref_3,
        CASE WHEN r."DIAGNOSISREF4__integer_valid" THEN r."DIAGNOSISREF4"::integer END AS diagnosis_ref_4,
        CASE WHEN r."UNITS__numeric_valid" THEN r."UNITS"::numeric END AS units,
        CASE WHEN r."DEPARTMENTID__integer_valid" THEN r."DEPARTMENTID"::integer END AS department_id,
        r."NOTES" AS notes,
        CASE WHEN r."UNITAMOUNT__numeric_valid" THEN r."UNITAMOUNT"::numeric END AS unit_amount,
        r."TRANSFEROUTID" AS transfer_out_id,
        r."TRANSFERTYPE" AS transfer_type,
        CASE WHEN r."PAYMENTS__numeric_valid" THEN r."PAYMENTS"::numeric END AS payments,
        CASE WHEN r."ADJUSTMENTS__numeric_valid" THEN r."ADJUSTMENTS"::numeric END AS adjustments,
        CASE WHEN r."TRANSFERS__numeric_valid" THEN r."TRANSFERS"::numeric END AS transfers,
        CASE WHEN r."OUTSTANDING__numeric_valid" THEN r."OUTSTANDING"::numeric END AS outstanding,
        r."APPOINTMENTID" AS appointment_id,
        r."LINENOTE" AS line_note,
        r."PATIENTINSURANCEID" AS patient_insurance_id,
        r."FEESCHEDULEID" AS fee_schedule_id,
        r."PROVIDERID" AS provider_id,
        r."SUPERVISINGPROVIDERID" AS supervising_provider_id,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."AMOUNT" IS NOT NULL AND NOT r."AMOUNT__numeric_valid" THEN 'AMOUNT'::text END,
            CASE WHEN r."FROMDATE" IS NOT NULL AND NOT r."FROMDATE__timestamp_with_time_zone_valid" THEN 'FROMDATE'::text END,
            CASE WHEN r."TODATE" IS NOT NULL AND NOT r."TODATE__timestamp_with_time_zone_valid" THEN 'TODATE'::text END,
            CASE WHEN r."DIAGNOSISREF1" IS NOT NULL AND NOT r."DIAGNOSISREF1__integer_valid" THEN 'DIAGNOSISREF1'::text END,
            CASE WHEN r."DIAGNOSISREF2" IS NOT NULL AND NOT r."DIAGNOSISREF2__integer_valid" THEN 'DIAGNOSISREF2'::text END,
            CASE WHEN r."DIAGNOSISREF3" IS NOT NULL AND NOT r."DIAGNOSISREF3__integer_valid" THEN 'DIAGNOSISREF3'::text END,
            CASE WHEN r."DIAGNOSISREF4" IS NOT NULL AND NOT r."DIAGNOSISREF4__integer_valid" THEN 'DIAGNOSISREF4'::text END,
            CASE WHEN r."UNITS" IS NOT NULL AND NOT r."UNITS__numeric_valid" THEN 'UNITS'::text END,
            CASE WHEN r."DEPARTMENTID" IS NOT NULL AND NOT r."DEPARTMENTID__integer_valid" THEN 'DEPARTMENTID'::text END,
            CASE WHEN r."UNITAMOUNT" IS NOT NULL AND NOT r."UNITAMOUNT__numeric_valid" THEN 'UNITAMOUNT'::text END,
            CASE WHEN r."PAYMENTS" IS NOT NULL AND NOT r."PAYMENTS__numeric_valid" THEN 'PAYMENTS'::text END,
            CASE WHEN r."ADJUSTMENTS" IS NOT NULL AND NOT r."ADJUSTMENTS__numeric_valid" THEN 'ADJUSTMENTS'::text END,
            CASE WHEN r."TRANSFERS" IS NOT NULL AND NOT r."TRANSFERS__numeric_valid" THEN 'TRANSFERS'::text END,
            CASE WHEN r."OUTSTANDING" IS NOT NULL AND NOT r."OUTSTANDING__numeric_valid" THEN 'OUTSTANDING'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_claim_transactions (
    transaction_id, claim_id, charge_id, patient_id, transaction_type, amount,
    method, from_at, to_at, place_of_service_id, procedure_code, modifier_1,
    modifier_2, diagnosis_ref_1, diagnosis_ref_2, diagnosis_ref_3,
    diagnosis_ref_4, units, department_id, notes, unit_amount, transfer_out_id,
    transfer_type, payments, adjustments, transfers, outstanding,
    appointment_id, line_note, patient_insurance_id, fee_schedule_id,
    provider_id, supervising_provider_id, source_system, source_table,
    source_row_hash, dq_missing_transaction_id, dq_duplicate_transaction_id,
    dq_missing_claim_id, dq_claim_not_found, dq_missing_patient_id,
    dq_patient_not_found, dq_encounter_not_found, dq_to_before_from,
    dq_negative_amount, dq_conversion_errors, dq_has_conversion_error
)
SELECT
    transaction_id, claim_id, charge_id, patient_id, transaction_type, amount,
    method, from_at, to_at, place_of_service_id, procedure_code, modifier_1,
    modifier_2, diagnosis_ref_1, diagnosis_ref_2, diagnosis_ref_3,
    diagnosis_ref_4, units, department_id, notes, unit_amount, transfer_out_id,
    transfer_type, payments, adjustments, transfers, outstanding,
    appointment_id, line_note, patient_insurance_id, fee_schedule_id,
    provider_id, supervising_provider_id, 'SYNTHEA',
    'raw.synthea_claims_transactions', source_row_hash,
    transaction_id IS NULL,
    false,
    claim_id IS NULL,
    false,
    patient_id IS NULL,
    false,
    false,
    from_at IS NOT NULL AND to_at IS NOT NULL AND to_at < from_at,
    COALESCE(amount < 0, false) OR COALESCE(unit_amount < 0, false) OR
        COALESCE(payments < 0, false) OR COALESCE(adjustments < 0, false) OR
        COALESCE(transfers < 0, false) OR COALESCE(outstanding < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw condition occurrence/episode.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."START"), '') AS "START",
        NULLIF(btrim(r."STOP"), '') AS "STOP",
        NULLIF(btrim(r."PATIENT"), '') AS "PATIENT",
        NULLIF(btrim(r."ENCOUNTER"), '') AS "ENCOUNTER",
        NULLIF(btrim(r."SYSTEM"), '') AS "SYSTEM",
        NULLIF(btrim(r."CODE"), '') AS "CODE",
        NULLIF(btrim(r."DESCRIPTION"), '') AS "DESCRIPTION"
    FROM raw.synthea_conditions r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."START", 'date') AS "START__date_valid",
        pg_input_is_valid(n."STOP", 'date') AS "STOP__date_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        CASE WHEN r."START__date_valid" THEN r."START"::date END AS start_date,
        CASE WHEN r."STOP__date_valid" THEN r."STOP"::date END AS stop_date,
        r."PATIENT" AS patient_id,
        r."ENCOUNTER" AS encounter_id,
        r."SYSTEM" AS code_system,
        r."CODE" AS condition_code,
        r."DESCRIPTION" AS condition_description,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."START" IS NOT NULL AND NOT r."START__date_valid" THEN 'START'::text END,
            CASE WHEN r."STOP" IS NOT NULL AND NOT r."STOP__date_valid" THEN 'STOP'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_condition_occurrences (
    start_date, stop_date, patient_id, encounter_id, code_system,
    condition_code, condition_description, source_system, source_table,
    source_row_hash, dq_missing_patient_id, dq_patient_not_found,
    dq_missing_encounter_id, dq_encounter_not_found, dq_stop_before_start,
    dq_duplicate_candidate_key, dq_conversion_errors, dq_has_conversion_error
)
SELECT
    start_date, stop_date, patient_id, encounter_id, code_system,
    condition_code, condition_description, 'SYNTHEA', 'raw.synthea_conditions',
    source_row_hash,
    patient_id IS NULL,
    false,
    encounter_id IS NULL,
    false,
    start_date IS NOT NULL AND stop_date IS NOT NULL AND stop_date < start_date,
    false,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw performed procedure occurrence.
WITH normalized AS MATERIALIZED (
    SELECT
        r AS source_row,
        NULLIF(btrim(r."START"), '') AS "START",
        NULLIF(btrim(r."STOP"), '') AS "STOP",
        NULLIF(btrim(r."PATIENT"), '') AS "PATIENT",
        NULLIF(btrim(r."ENCOUNTER"), '') AS "ENCOUNTER",
        NULLIF(btrim(r."SYSTEM"), '') AS "SYSTEM",
        NULLIF(btrim(r."CODE"), '') AS "CODE",
        NULLIF(btrim(r."DESCRIPTION"), '') AS "DESCRIPTION",
        NULLIF(btrim(r."BASE_COST"), '') AS "BASE_COST",
        NULLIF(btrim(r."REASONCODE"), '') AS "REASONCODE",
        NULLIF(btrim(r."REASONDESCRIPTION"), '') AS "REASONDESCRIPTION"
    FROM raw.synthea_procedures r
),
validated AS MATERIALIZED (
    SELECT
        n.*,
        pg_input_is_valid(n."START", 'timestamp with time zone') AS "START__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."STOP", 'timestamp with time zone') AS "STOP__timestamp_with_time_zone_valid",
        pg_input_is_valid(n."BASE_COST", 'numeric') AS "BASE_COST__numeric_valid"
    FROM normalized n
),
typed AS NOT MATERIALIZED (
    SELECT
        CASE WHEN r."START__timestamp_with_time_zone_valid" THEN r."START"::timestamptz END AS start_at,
        CASE WHEN r."STOP__timestamp_with_time_zone_valid" THEN r."STOP"::timestamptz END AS stop_at,
        r."PATIENT" AS patient_id,
        r."ENCOUNTER" AS encounter_id,
        r."SYSTEM" AS code_system,
        r."CODE" AS procedure_code,
        r."DESCRIPTION" AS procedure_description,
        CASE WHEN r."BASE_COST__numeric_valid" THEN r."BASE_COST"::numeric END AS base_cost,
        r."REASONCODE" AS reason_code,
        r."REASONDESCRIPTION" AS reason_description,
        md5(row_to_json(r.source_row)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN r."START" IS NOT NULL AND NOT r."START__timestamp_with_time_zone_valid" THEN 'START'::text END,
            CASE WHEN r."STOP" IS NOT NULL AND NOT r."STOP__timestamp_with_time_zone_valid" THEN 'STOP'::text END,
            CASE WHEN r."BASE_COST" IS NOT NULL AND NOT r."BASE_COST__numeric_valid" THEN 'BASE_COST'::text END
        ], NULL) AS conversion_errors
    FROM validated r
)
INSERT INTO staging.stg_procedures (
    start_at, stop_at, patient_id, encounter_id, code_system, procedure_code,
    procedure_description, base_cost, reason_code, reason_description,
    source_system, source_table, source_row_hash, dq_missing_patient_id,
    dq_patient_not_found, dq_missing_encounter_id, dq_encounter_not_found,
    dq_stop_before_start, dq_negative_amount, dq_duplicate_candidate_key,
    dq_conversion_errors, dq_has_conversion_error
)
SELECT
    start_at, stop_at, patient_id, encounter_id, code_system, procedure_code,
    procedure_description, base_cost, reason_code, reason_description,
    'SYNTHEA', 'raw.synthea_procedures', source_row_hash,
    patient_id IS NULL,
    false,
    encounter_id IS NULL,
    false,
    start_at IS NOT NULL AND stop_at IS NOT NULL AND stop_at < start_at,
    COALESCE(base_cost < 0, false),
    false,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- Create/ensure only the indexes justified by existing V1 DQ checks.
-- The include is deliberately after bulk insertion on the first V2 run.
\ir 004_create_staging_performance_indexes.sql

-- Narrow-key duplicate detection. NULL predicates reproduce V1 semantics:
-- simple candidate identifiers never flag NULL, and composite candidates flag
-- only rows for which every V1-required component is non-NULL.
UPDATE staging.stg_patients s
SET dq_duplicate_patient_id = true
FROM (
    SELECT patient_id FROM staging.stg_patients
    WHERE patient_id IS NOT NULL
    GROUP BY patient_id HAVING count(*) > 1
) d
WHERE s.patient_id = d.patient_id;

UPDATE staging.stg_encounters s
SET dq_duplicate_encounter_id = true
FROM (
    SELECT encounter_id FROM staging.stg_encounters
    WHERE encounter_id IS NOT NULL
    GROUP BY encounter_id HAVING count(*) > 1
) d
WHERE s.encounter_id = d.encounter_id;

UPDATE staging.stg_claims s
SET dq_duplicate_claim_id = true
FROM (
    SELECT claim_id FROM staging.stg_claims
    WHERE claim_id IS NOT NULL
    GROUP BY claim_id HAVING count(*) > 1
) d
WHERE s.claim_id = d.claim_id;

UPDATE staging.stg_claim_transactions s
SET dq_duplicate_transaction_id = true
FROM (
    SELECT transaction_id FROM staging.stg_claim_transactions
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id HAVING count(*) > 1
) d
WHERE s.transaction_id = d.transaction_id;

UPDATE staging.stg_condition_occurrences s
SET dq_duplicate_candidate_key = true
FROM (
    SELECT patient_id, encounter_id, start_date, condition_code
    FROM staging.stg_condition_occurrences
    WHERE patient_id IS NOT NULL
      AND encounter_id IS NOT NULL
      AND start_date IS NOT NULL
      AND condition_code IS NOT NULL
    GROUP BY patient_id, encounter_id, start_date, condition_code
    HAVING count(*) > 1
) d
WHERE s.patient_id = d.patient_id
  AND s.encounter_id = d.encounter_id
  AND s.start_date = d.start_date
  AND s.condition_code = d.condition_code;

UPDATE staging.stg_procedures s
SET dq_duplicate_candidate_key = true
FROM (
    SELECT patient_id, encounter_id, start_at, procedure_code
    FROM staging.stg_procedures
    WHERE patient_id IS NOT NULL
      AND encounter_id IS NOT NULL
      AND start_at IS NOT NULL
      AND procedure_code IS NOT NULL
    GROUP BY patient_id, encounter_id, start_at, procedure_code
    HAVING count(*) > 1
) d
WHERE s.patient_id = d.patient_id
  AND s.encounter_id = d.encounter_id
  AND s.start_at = d.start_at
  AND s.procedure_code = d.procedure_code;

-- Indexed post-load reference validation. Each predicate is identical to V1.
UPDATE staging.stg_encounters s
SET dq_patient_not_found = true
WHERE s.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_patients p
      WHERE p.patient_id = s.patient_id
  );

UPDATE staging.stg_claims s
SET dq_patient_not_found = true
WHERE s.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_patients p
      WHERE p.patient_id = s.patient_id
  );

UPDATE staging.stg_claims s
SET dq_encounter_not_found = true
WHERE s.appointment_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_encounters e
      WHERE e.encounter_id = s.appointment_id
  );

UPDATE staging.stg_claim_transactions s
SET dq_claim_not_found = true
WHERE s.claim_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_claims c
      WHERE c.claim_id = s.claim_id
  );

UPDATE staging.stg_claim_transactions s
SET dq_patient_not_found = true
WHERE s.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_patients p
      WHERE p.patient_id = s.patient_id
  );

UPDATE staging.stg_claim_transactions s
SET dq_encounter_not_found = true
WHERE s.appointment_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_encounters e
      WHERE e.encounter_id = s.appointment_id
  );

UPDATE staging.stg_condition_occurrences s
SET dq_patient_not_found = true
WHERE s.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_patients p
      WHERE p.patient_id = s.patient_id
  );

UPDATE staging.stg_condition_occurrences s
SET dq_encounter_not_found = true
WHERE s.encounter_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_encounters e
      WHERE e.encounter_id = s.encounter_id
  );

UPDATE staging.stg_procedures s
SET dq_patient_not_found = true
WHERE s.patient_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_patients p
      WHERE p.patient_id = s.patient_id
  );

UPDATE staging.stg_procedures s
SET dq_encounter_not_found = true
WHERE s.encounter_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM staging.stg_encounters e
      WHERE e.encounter_id = s.encounter_id
  );

-- Final source-to-staging row-count reconciliation. No rows are aggregated,
-- deduplicated, rejected, or removed by V2.
WITH reconciliation AS (
    SELECT 'patients'::text AS source_name,
           (SELECT count(*) FROM raw.synthea_patients) AS raw_rows,
           (SELECT count(*) FROM staging.stg_patients) AS staging_rows
    UNION ALL
    SELECT 'encounters',
           (SELECT count(*) FROM raw.synthea_encounters),
           (SELECT count(*) FROM staging.stg_encounters)
    UNION ALL
    SELECT 'claims',
           (SELECT count(*) FROM raw.synthea_claims),
           (SELECT count(*) FROM staging.stg_claims)
    UNION ALL
    SELECT 'claim_transactions',
           (SELECT count(*) FROM raw.synthea_claims_transactions),
           (SELECT count(*) FROM staging.stg_claim_transactions)
    UNION ALL
    SELECT 'condition_occurrences',
           (SELECT count(*) FROM raw.synthea_conditions),
           (SELECT count(*) FROM staging.stg_condition_occurrences)
    UNION ALL
    SELECT 'procedures',
           (SELECT count(*) FROM raw.synthea_procedures),
           (SELECT count(*) FROM staging.stg_procedures)
)
SELECT source_name, raw_rows, staging_rows,
       staging_rows - raw_rows AS difference,
       CASE WHEN staging_rows = raw_rows THEN 'PASS' ELSE 'FAIL' END AS status
FROM reconciliation
ORDER BY source_name;

COMMIT;
