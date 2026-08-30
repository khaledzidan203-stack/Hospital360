\set ON_ERROR_STOP on

-- Hospital360 Synthea V1 RAW-to-STAGING transformation.
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
WITH typed AS (
    SELECT
        NULLIF(btrim(r."Id"), '') AS patient_id,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."BIRTHDATE"), ''), 'date') THEN btrim(r."BIRTHDATE")::date END AS birth_date,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DEATHDATE"), ''), 'date') THEN btrim(r."DEATHDATE")::date END AS death_date,
        NULLIF(btrim(r."SSN"), '') AS ssn,
        NULLIF(btrim(r."DRIVERS"), '') AS drivers_license,
        NULLIF(btrim(r."PASSPORT"), '') AS passport_number,
        NULLIF(btrim(r."PREFIX"), '') AS name_prefix,
        NULLIF(btrim(r."FIRST"), '') AS first_name,
        NULLIF(btrim(r."MIDDLE"), '') AS middle_name,
        NULLIF(btrim(r."LAST"), '') AS last_name,
        NULLIF(btrim(r."SUFFIX"), '') AS name_suffix,
        NULLIF(btrim(r."MAIDEN"), '') AS maiden_name,
        NULLIF(btrim(r."MARITAL"), '') AS marital_status,
        NULLIF(btrim(r."RACE"), '') AS race,
        NULLIF(btrim(r."ETHNICITY"), '') AS ethnicity,
        NULLIF(btrim(r."GENDER"), '') AS gender,
        NULLIF(btrim(r."BIRTHPLACE"), '') AS birthplace,
        NULLIF(btrim(r."ADDRESS"), '') AS address,
        NULLIF(btrim(r."CITY"), '') AS city,
        NULLIF(btrim(r."STATE"), '') AS state,
        NULLIF(btrim(r."COUNTY"), '') AS county,
        NULLIF(btrim(r."FIPS"), '') AS fips,
        NULLIF(btrim(r."ZIP"), '') AS zip,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."LAT"), ''), 'numeric') THEN btrim(r."LAT")::numeric END AS latitude,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."LON"), ''), 'numeric') THEN btrim(r."LON")::numeric END AS longitude,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."HEALTHCARE_EXPENSES"), ''), 'numeric') THEN btrim(r."HEALTHCARE_EXPENSES")::numeric END AS healthcare_expenses,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."HEALTHCARE_COVERAGE"), ''), 'numeric') THEN btrim(r."HEALTHCARE_COVERAGE")::numeric END AS healthcare_coverage,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."INCOME"), ''), 'numeric') THEN btrim(r."INCOME")::numeric END AS income,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."BIRTHDATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."BIRTHDATE"), 'date') THEN 'BIRTHDATE'::text END,
            CASE WHEN NULLIF(btrim(r."DEATHDATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DEATHDATE"), 'date') THEN 'DEATHDATE'::text END,
            CASE WHEN NULLIF(btrim(r."LAT"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."LAT"), 'numeric') THEN 'LAT'::text END,
            CASE WHEN NULLIF(btrim(r."LON"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."LON"), 'numeric') THEN 'LON'::text END,
            CASE WHEN NULLIF(btrim(r."HEALTHCARE_EXPENSES"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."HEALTHCARE_EXPENSES"), 'numeric') THEN 'HEALTHCARE_EXPENSES'::text END,
            CASE WHEN NULLIF(btrim(r."HEALTHCARE_COVERAGE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."HEALTHCARE_COVERAGE"), 'numeric') THEN 'HEALTHCARE_COVERAGE'::text END,
            CASE WHEN NULLIF(btrim(r."INCOME"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."INCOME"), 'numeric') THEN 'INCOME'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_patients r
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
    patient_id IS NOT NULL AND count(*) OVER (PARTITION BY patient_id) > 1,
    'BIRTHDATE' = ANY(conversion_errors),
    'DEATHDATE' = ANY(conversion_errors),
    birth_date IS NOT NULL AND death_date IS NOT NULL AND death_date < birth_date,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw encounter row.
WITH typed AS (
    SELECT
        NULLIF(btrim(r."Id"), '') AS encounter_id,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."START"), ''), 'timestamp with time zone') THEN btrim(r."START")::timestamptz END AS start_at,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."STOP"), ''), 'timestamp with time zone') THEN btrim(r."STOP")::timestamptz END AS stop_at,
        NULLIF(btrim(r."PATIENT"), '') AS patient_id,
        NULLIF(btrim(r."ORGANIZATION"), '') AS organization_id,
        NULLIF(btrim(r."PROVIDER"), '') AS provider_id,
        NULLIF(btrim(r."PAYER"), '') AS payer_id,
        NULLIF(btrim(r."ENCOUNTERCLASS"), '') AS encounter_class,
        NULLIF(btrim(r."CODE"), '') AS encounter_code,
        NULLIF(btrim(r."DESCRIPTION"), '') AS encounter_description,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."BASE_ENCOUNTER_COST"), ''), 'numeric') THEN btrim(r."BASE_ENCOUNTER_COST")::numeric END AS base_encounter_cost,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."TOTAL_CLAIM_COST"), ''), 'numeric') THEN btrim(r."TOTAL_CLAIM_COST")::numeric END AS total_claim_cost,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."PAYER_COVERAGE"), ''), 'numeric') THEN btrim(r."PAYER_COVERAGE")::numeric END AS payer_coverage,
        NULLIF(btrim(r."REASONCODE"), '') AS reason_code,
        NULLIF(btrim(r."REASONDESCRIPTION"), '') AS reason_description,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."START"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."START"), 'timestamp with time zone') THEN 'START'::text END,
            CASE WHEN NULLIF(btrim(r."STOP"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."STOP"), 'timestamp with time zone') THEN 'STOP'::text END,
            CASE WHEN NULLIF(btrim(r."BASE_ENCOUNTER_COST"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."BASE_ENCOUNTER_COST"), 'numeric') THEN 'BASE_ENCOUNTER_COST'::text END,
            CASE WHEN NULLIF(btrim(r."TOTAL_CLAIM_COST"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."TOTAL_CLAIM_COST"), 'numeric') THEN 'TOTAL_CLAIM_COST'::text END,
            CASE WHEN NULLIF(btrim(r."PAYER_COVERAGE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."PAYER_COVERAGE"), 'numeric') THEN 'PAYER_COVERAGE'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_encounters r
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
    encounter_id IS NOT NULL AND count(*) OVER (PARTITION BY encounter_id) > 1,
    patient_id IS NULL,
    patient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_patients p WHERE p.patient_id = typed.patient_id),
    start_at IS NOT NULL AND stop_at IS NOT NULL AND start_at > stop_at,
    COALESCE(base_encounter_cost < 0, false) OR COALESCE(total_claim_cost < 0, false) OR COALESCE(payer_coverage < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw claim-header row.
WITH typed AS (
    SELECT
        NULLIF(btrim(r."Id"), '') AS claim_id,
        NULLIF(btrim(r."PATIENTID"), '') AS patient_id,
        NULLIF(btrim(r."PROVIDERID"), '') AS provider_id,
        NULLIF(btrim(r."PRIMARYPATIENTINSURANCEID"), '') AS primary_patient_insurance_id,
        NULLIF(btrim(r."SECONDARYPATIENTINSURANCEID"), '') AS secondary_patient_insurance_id,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DEPARTMENTID"), ''), 'integer') THEN btrim(r."DEPARTMENTID")::integer END AS department_id,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."PATIENTDEPARTMENTID"), ''), 'integer') THEN btrim(r."PATIENTDEPARTMENTID")::integer END AS patient_department_id,
        NULLIF(btrim(r."DIAGNOSIS1"), '') AS diagnosis_1,
        NULLIF(btrim(r."DIAGNOSIS2"), '') AS diagnosis_2,
        NULLIF(btrim(r."DIAGNOSIS3"), '') AS diagnosis_3,
        NULLIF(btrim(r."DIAGNOSIS4"), '') AS diagnosis_4,
        NULLIF(btrim(r."DIAGNOSIS5"), '') AS diagnosis_5,
        NULLIF(btrim(r."DIAGNOSIS6"), '') AS diagnosis_6,
        NULLIF(btrim(r."DIAGNOSIS7"), '') AS diagnosis_7,
        NULLIF(btrim(r."DIAGNOSIS8"), '') AS diagnosis_8,
        NULLIF(btrim(r."REFERRINGPROVIDERID"), '') AS referring_provider_id,
        NULLIF(btrim(r."APPOINTMENTID"), '') AS appointment_id,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."CURRENTILLNESSDATE"), ''), 'timestamp with time zone') THEN btrim(r."CURRENTILLNESSDATE")::timestamptz END AS current_illness_at,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."SERVICEDATE"), ''), 'timestamp with time zone') THEN btrim(r."SERVICEDATE")::timestamptz END AS service_at,
        NULLIF(btrim(r."SUPERVISINGPROVIDERID"), '') AS supervising_provider_id,
        NULLIF(btrim(r."STATUS1"), '') AS status_1,
        NULLIF(btrim(r."STATUS2"), '') AS status_2,
        NULLIF(btrim(r."STATUSP"), '') AS status_primary,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."OUTSTANDING1"), ''), 'numeric') THEN btrim(r."OUTSTANDING1")::numeric END AS outstanding_1,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."OUTSTANDING2"), ''), 'numeric') THEN btrim(r."OUTSTANDING2")::numeric END AS outstanding_2,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."OUTSTANDINGP"), ''), 'numeric') THEN btrim(r."OUTSTANDINGP")::numeric END AS outstanding_primary,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."LASTBILLEDDATE1"), ''), 'timestamp with time zone') THEN btrim(r."LASTBILLEDDATE1")::timestamptz END AS last_billed_at_1,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."LASTBILLEDDATE2"), ''), 'timestamp with time zone') THEN btrim(r."LASTBILLEDDATE2")::timestamptz END AS last_billed_at_2,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."LASTBILLEDDATEP"), ''), 'timestamp with time zone') THEN btrim(r."LASTBILLEDDATEP")::timestamptz END AS last_billed_at_primary,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."HEALTHCARECLAIMTYPEID1"), ''), 'integer') THEN btrim(r."HEALTHCARECLAIMTYPEID1")::integer END AS healthcare_claim_type_id_1,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."HEALTHCARECLAIMTYPEID2"), ''), 'integer') THEN btrim(r."HEALTHCARECLAIMTYPEID2")::integer END AS healthcare_claim_type_id_2,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."DEPARTMENTID"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DEPARTMENTID"), 'integer') THEN 'DEPARTMENTID'::text END,
            CASE WHEN NULLIF(btrim(r."PATIENTDEPARTMENTID"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."PATIENTDEPARTMENTID"), 'integer') THEN 'PATIENTDEPARTMENTID'::text END,
            CASE WHEN NULLIF(btrim(r."CURRENTILLNESSDATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."CURRENTILLNESSDATE"), 'timestamp with time zone') THEN 'CURRENTILLNESSDATE'::text END,
            CASE WHEN NULLIF(btrim(r."SERVICEDATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."SERVICEDATE"), 'timestamp with time zone') THEN 'SERVICEDATE'::text END,
            CASE WHEN NULLIF(btrim(r."OUTSTANDING1"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."OUTSTANDING1"), 'numeric') THEN 'OUTSTANDING1'::text END,
            CASE WHEN NULLIF(btrim(r."OUTSTANDING2"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."OUTSTANDING2"), 'numeric') THEN 'OUTSTANDING2'::text END,
            CASE WHEN NULLIF(btrim(r."OUTSTANDINGP"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."OUTSTANDINGP"), 'numeric') THEN 'OUTSTANDINGP'::text END,
            CASE WHEN NULLIF(btrim(r."LASTBILLEDDATE1"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."LASTBILLEDDATE1"), 'timestamp with time zone') THEN 'LASTBILLEDDATE1'::text END,
            CASE WHEN NULLIF(btrim(r."LASTBILLEDDATE2"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."LASTBILLEDDATE2"), 'timestamp with time zone') THEN 'LASTBILLEDDATE2'::text END,
            CASE WHEN NULLIF(btrim(r."LASTBILLEDDATEP"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."LASTBILLEDDATEP"), 'timestamp with time zone') THEN 'LASTBILLEDDATEP'::text END,
            CASE WHEN NULLIF(btrim(r."HEALTHCARECLAIMTYPEID1"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."HEALTHCARECLAIMTYPEID1"), 'integer') THEN 'HEALTHCARECLAIMTYPEID1'::text END,
            CASE WHEN NULLIF(btrim(r."HEALTHCARECLAIMTYPEID2"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."HEALTHCARECLAIMTYPEID2"), 'integer') THEN 'HEALTHCARECLAIMTYPEID2'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_claims r
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
    claim_id IS NOT NULL AND count(*) OVER (PARTITION BY claim_id) > 1,
    patient_id IS NULL,
    patient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_patients p WHERE p.patient_id = typed.patient_id),
    appointment_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_encounters e WHERE e.encounter_id = typed.appointment_id),
    COALESCE(outstanding_1 < 0, false) OR COALESCE(outstanding_2 < 0, false) OR COALESCE(outstanding_primary < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw claim transaction/event line.
WITH typed AS (
    SELECT
        NULLIF(btrim(r."ID"), '') AS transaction_id,
        NULLIF(btrim(r."CLAIMID"), '') AS claim_id,
        NULLIF(btrim(r."CHARGEID"), '') AS charge_id,
        NULLIF(btrim(r."PATIENTID"), '') AS patient_id,
        NULLIF(btrim(r."TYPE"), '') AS transaction_type,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."AMOUNT"), ''), 'numeric') THEN btrim(r."AMOUNT")::numeric END AS amount,
        NULLIF(btrim(r."METHOD"), '') AS method,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."FROMDATE"), ''), 'timestamp with time zone') THEN btrim(r."FROMDATE")::timestamptz END AS from_at,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."TODATE"), ''), 'timestamp with time zone') THEN btrim(r."TODATE")::timestamptz END AS to_at,
        NULLIF(btrim(r."PLACEOFSERVICE"), '') AS place_of_service_id,
        NULLIF(btrim(r."PROCEDURECODE"), '') AS procedure_code,
        NULLIF(btrim(r."MODIFIER1"), '') AS modifier_1,
        NULLIF(btrim(r."MODIFIER2"), '') AS modifier_2,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DIAGNOSISREF1"), ''), 'integer') THEN btrim(r."DIAGNOSISREF1")::integer END AS diagnosis_ref_1,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DIAGNOSISREF2"), ''), 'integer') THEN btrim(r."DIAGNOSISREF2")::integer END AS diagnosis_ref_2,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DIAGNOSISREF3"), ''), 'integer') THEN btrim(r."DIAGNOSISREF3")::integer END AS diagnosis_ref_3,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DIAGNOSISREF4"), ''), 'integer') THEN btrim(r."DIAGNOSISREF4")::integer END AS diagnosis_ref_4,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."UNITS"), ''), 'numeric') THEN btrim(r."UNITS")::numeric END AS units,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."DEPARTMENTID"), ''), 'integer') THEN btrim(r."DEPARTMENTID")::integer END AS department_id,
        NULLIF(btrim(r."NOTES"), '') AS notes,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."UNITAMOUNT"), ''), 'numeric') THEN btrim(r."UNITAMOUNT")::numeric END AS unit_amount,
        NULLIF(btrim(r."TRANSFEROUTID"), '') AS transfer_out_id,
        NULLIF(btrim(r."TRANSFERTYPE"), '') AS transfer_type,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."PAYMENTS"), ''), 'numeric') THEN btrim(r."PAYMENTS")::numeric END AS payments,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."ADJUSTMENTS"), ''), 'numeric') THEN btrim(r."ADJUSTMENTS")::numeric END AS adjustments,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."TRANSFERS"), ''), 'numeric') THEN btrim(r."TRANSFERS")::numeric END AS transfers,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."OUTSTANDING"), ''), 'numeric') THEN btrim(r."OUTSTANDING")::numeric END AS outstanding,
        NULLIF(btrim(r."APPOINTMENTID"), '') AS appointment_id,
        NULLIF(btrim(r."LINENOTE"), '') AS line_note,
        NULLIF(btrim(r."PATIENTINSURANCEID"), '') AS patient_insurance_id,
        NULLIF(btrim(r."FEESCHEDULEID"), '') AS fee_schedule_id,
        NULLIF(btrim(r."PROVIDERID"), '') AS provider_id,
        NULLIF(btrim(r."SUPERVISINGPROVIDERID"), '') AS supervising_provider_id,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."AMOUNT"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."AMOUNT"), 'numeric') THEN 'AMOUNT'::text END,
            CASE WHEN NULLIF(btrim(r."FROMDATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."FROMDATE"), 'timestamp with time zone') THEN 'FROMDATE'::text END,
            CASE WHEN NULLIF(btrim(r."TODATE"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."TODATE"), 'timestamp with time zone') THEN 'TODATE'::text END,
            CASE WHEN NULLIF(btrim(r."DIAGNOSISREF1"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DIAGNOSISREF1"), 'integer') THEN 'DIAGNOSISREF1'::text END,
            CASE WHEN NULLIF(btrim(r."DIAGNOSISREF2"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DIAGNOSISREF2"), 'integer') THEN 'DIAGNOSISREF2'::text END,
            CASE WHEN NULLIF(btrim(r."DIAGNOSISREF3"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DIAGNOSISREF3"), 'integer') THEN 'DIAGNOSISREF3'::text END,
            CASE WHEN NULLIF(btrim(r."DIAGNOSISREF4"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DIAGNOSISREF4"), 'integer') THEN 'DIAGNOSISREF4'::text END,
            CASE WHEN NULLIF(btrim(r."UNITS"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."UNITS"), 'numeric') THEN 'UNITS'::text END,
            CASE WHEN NULLIF(btrim(r."DEPARTMENTID"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."DEPARTMENTID"), 'integer') THEN 'DEPARTMENTID'::text END,
            CASE WHEN NULLIF(btrim(r."UNITAMOUNT"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."UNITAMOUNT"), 'numeric') THEN 'UNITAMOUNT'::text END,
            CASE WHEN NULLIF(btrim(r."PAYMENTS"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."PAYMENTS"), 'numeric') THEN 'PAYMENTS'::text END,
            CASE WHEN NULLIF(btrim(r."ADJUSTMENTS"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."ADJUSTMENTS"), 'numeric') THEN 'ADJUSTMENTS'::text END,
            CASE WHEN NULLIF(btrim(r."TRANSFERS"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."TRANSFERS"), 'numeric') THEN 'TRANSFERS'::text END,
            CASE WHEN NULLIF(btrim(r."OUTSTANDING"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."OUTSTANDING"), 'numeric') THEN 'OUTSTANDING'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_claims_transactions r
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
    transaction_id IS NOT NULL AND count(*) OVER (PARTITION BY transaction_id) > 1,
    claim_id IS NULL,
    claim_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_claims c WHERE c.claim_id = typed.claim_id),
    patient_id IS NULL,
    patient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_patients p WHERE p.patient_id = typed.patient_id),
    appointment_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_encounters e WHERE e.encounter_id = typed.appointment_id),
    from_at IS NOT NULL AND to_at IS NOT NULL AND to_at < from_at,
    COALESCE(amount < 0, false) OR COALESCE(unit_amount < 0, false) OR
        COALESCE(payments < 0, false) OR COALESCE(adjustments < 0, false) OR
        COALESCE(transfers < 0, false) OR COALESCE(outstanding < 0, false),
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw condition occurrence/episode.
WITH typed AS (
    SELECT
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."START"), ''), 'date') THEN btrim(r."START")::date END AS start_date,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."STOP"), ''), 'date') THEN btrim(r."STOP")::date END AS stop_date,
        NULLIF(btrim(r."PATIENT"), '') AS patient_id,
        NULLIF(btrim(r."ENCOUNTER"), '') AS encounter_id,
        NULLIF(btrim(r."SYSTEM"), '') AS code_system,
        NULLIF(btrim(r."CODE"), '') AS condition_code,
        NULLIF(btrim(r."DESCRIPTION"), '') AS condition_description,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."START"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."START"), 'date') THEN 'START'::text END,
            CASE WHEN NULLIF(btrim(r."STOP"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."STOP"), 'date') THEN 'STOP'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_conditions r
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
    patient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_patients p WHERE p.patient_id = typed.patient_id),
    encounter_id IS NULL,
    encounter_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_encounters e WHERE e.encounter_id = typed.encounter_id),
    start_date IS NOT NULL AND stop_date IS NOT NULL AND stop_date < start_date,
    patient_id IS NOT NULL AND encounter_id IS NOT NULL AND start_date IS NOT NULL AND condition_code IS NOT NULL
        AND count(*) OVER (PARTITION BY patient_id, encounter_id, start_date, condition_code) > 1,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

-- One staging row per raw performed procedure occurrence.
WITH typed AS (
    SELECT
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."START"), ''), 'timestamp with time zone') THEN btrim(r."START")::timestamptz END AS start_at,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."STOP"), ''), 'timestamp with time zone') THEN btrim(r."STOP")::timestamptz END AS stop_at,
        NULLIF(btrim(r."PATIENT"), '') AS patient_id,
        NULLIF(btrim(r."ENCOUNTER"), '') AS encounter_id,
        NULLIF(btrim(r."SYSTEM"), '') AS code_system,
        NULLIF(btrim(r."CODE"), '') AS procedure_code,
        NULLIF(btrim(r."DESCRIPTION"), '') AS procedure_description,
        CASE WHEN pg_input_is_valid(NULLIF(btrim(r."BASE_COST"), ''), 'numeric') THEN btrim(r."BASE_COST")::numeric END AS base_cost,
        NULLIF(btrim(r."REASONCODE"), '') AS reason_code,
        NULLIF(btrim(r."REASONDESCRIPTION"), '') AS reason_description,
        md5(row_to_json(r)::text) AS source_row_hash,
        array_remove(ARRAY[
            CASE WHEN NULLIF(btrim(r."START"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."START"), 'timestamp with time zone') THEN 'START'::text END,
            CASE WHEN NULLIF(btrim(r."STOP"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."STOP"), 'timestamp with time zone') THEN 'STOP'::text END,
            CASE WHEN NULLIF(btrim(r."BASE_COST"), '') IS NOT NULL AND NOT pg_input_is_valid(btrim(r."BASE_COST"), 'numeric') THEN 'BASE_COST'::text END
        ], NULL) AS conversion_errors
    FROM raw.synthea_procedures r
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
    patient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_patients p WHERE p.patient_id = typed.patient_id),
    encounter_id IS NULL,
    encounter_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM staging.stg_encounters e WHERE e.encounter_id = typed.encounter_id),
    start_at IS NOT NULL AND stop_at IS NOT NULL AND stop_at < start_at,
    COALESCE(base_cost < 0, false),
    patient_id IS NOT NULL AND encounter_id IS NOT NULL AND start_at IS NOT NULL AND procedure_code IS NOT NULL
        AND count(*) OVER (PARTITION BY patient_id, encounter_id, start_at, procedure_code) > 1,
    conversion_errors,
    cardinality(conversion_errors) > 0
FROM typed;

COMMIT;
