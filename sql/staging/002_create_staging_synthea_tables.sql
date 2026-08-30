-- Hospital360 Synthea V1 STAGING layer.
-- STAGING is typed, normalized, and validated while preserving each source row grain.
-- Candidate keys and relationships are not enforced as final constraints in this layer.

BEGIN;

CREATE TABLE IF NOT EXISTS staging.stg_patients (
    patient_id text,
    birth_date date,
    death_date date,
    ssn text,
    drivers_license text,
    passport_number text,
    name_prefix text,
    first_name text,
    middle_name text,
    last_name text,
    name_suffix text,
    maiden_name text,
    marital_status text,
    race text,
    ethnicity text,
    gender text,
    birthplace text,
    address text,
    city text,
    state text,
    county text,
    fips text,
    zip text,
    latitude numeric,
    longitude numeric,
    healthcare_expenses numeric,
    healthcare_coverage numeric,
    income numeric,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_patient_id boolean,
    dq_duplicate_patient_id boolean,
    dq_invalid_birth_date boolean,
    dq_invalid_death_date boolean,
    dq_death_before_birth boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_patients IS
    'One row per source patient row from raw.synthea_patients; typed and validated without deduplication.';

CREATE TABLE IF NOT EXISTS staging.stg_encounters (
    encounter_id text,
    start_at timestamptz,
    stop_at timestamptz,
    patient_id text,
    organization_id text,
    provider_id text,
    payer_id text,
    encounter_class text,
    encounter_code text,
    encounter_description text,
    base_encounter_cost numeric,
    total_claim_cost numeric,
    payer_coverage numeric,
    reason_code text,
    reason_description text,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_encounter_id boolean,
    dq_duplicate_encounter_id boolean,
    dq_missing_patient_id boolean,
    dq_patient_not_found boolean,
    dq_start_after_stop boolean,
    dq_negative_amount boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_encounters IS
    'One row per source encounter event from raw.synthea_encounters; typed and validated without deduplication.';

CREATE TABLE IF NOT EXISTS staging.stg_claims (
    claim_id text,
    patient_id text,
    provider_id text,
    primary_patient_insurance_id text,
    secondary_patient_insurance_id text,
    department_id integer,
    patient_department_id integer,
    diagnosis_1 text,
    diagnosis_2 text,
    diagnosis_3 text,
    diagnosis_4 text,
    diagnosis_5 text,
    diagnosis_6 text,
    diagnosis_7 text,
    diagnosis_8 text,
    referring_provider_id text,
    appointment_id text,
    current_illness_at timestamptz,
    service_at timestamptz,
    supervising_provider_id text,
    status_1 text,
    status_2 text,
    status_primary text,
    outstanding_1 numeric,
    outstanding_2 numeric,
    outstanding_primary numeric,
    last_billed_at_1 timestamptz,
    last_billed_at_2 timestamptz,
    last_billed_at_primary timestamptz,
    healthcare_claim_type_id_1 integer,
    healthcare_claim_type_id_2 integer,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_claim_id boolean,
    dq_duplicate_claim_id boolean,
    dq_missing_patient_id boolean,
    dq_patient_not_found boolean,
    dq_encounter_not_found boolean,
    dq_negative_amount boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_claims IS
    'One row per source claim header from raw.synthea_claims; APPOINTMENTID is retained as a candidate encounter reference.';

CREATE TABLE IF NOT EXISTS staging.stg_claim_transactions (
    transaction_id text,
    claim_id text,
    charge_id text,
    patient_id text,
    transaction_type text,
    amount numeric,
    method text,
    from_at timestamptz,
    to_at timestamptz,
    place_of_service_id text,
    procedure_code text,
    modifier_1 text,
    modifier_2 text,
    diagnosis_ref_1 integer,
    diagnosis_ref_2 integer,
    diagnosis_ref_3 integer,
    diagnosis_ref_4 integer,
    units numeric,
    department_id integer,
    notes text,
    unit_amount numeric,
    transfer_out_id text,
    transfer_type text,
    payments numeric,
    adjustments numeric,
    transfers numeric,
    outstanding numeric,
    appointment_id text,
    line_note text,
    patient_insurance_id text,
    fee_schedule_id text,
    provider_id text,
    supervising_provider_id text,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_transaction_id boolean,
    dq_duplicate_transaction_id boolean,
    dq_missing_claim_id boolean,
    dq_claim_not_found boolean,
    dq_missing_patient_id boolean,
    dq_patient_not_found boolean,
    dq_encounter_not_found boolean,
    dq_to_before_from boolean,
    dq_negative_amount boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_claim_transactions IS
    'One row per source claim transaction/event line from raw.synthea_claims_transactions; no financial semantic classification is applied.';

CREATE TABLE IF NOT EXISTS staging.stg_condition_occurrences (
    start_date date,
    stop_date date,
    patient_id text,
    encounter_id text,
    code_system text,
    condition_code text,
    condition_description text,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_patient_id boolean,
    dq_patient_not_found boolean,
    dq_missing_encounter_id boolean,
    dq_encounter_not_found boolean,
    dq_stop_before_start boolean,
    dq_duplicate_candidate_key boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_condition_occurrences IS
    'One row per source condition occurrence/episode from raw.synthea_conditions; candidate composite keys are flagged but not enforced.';

CREATE TABLE IF NOT EXISTS staging.stg_procedures (
    start_at timestamptz,
    stop_at timestamptz,
    patient_id text,
    encounter_id text,
    code_system text,
    procedure_code text,
    procedure_description text,
    base_cost numeric,
    reason_code text,
    reason_description text,
    source_system text,
    source_table text,
    source_row_hash text,
    dq_missing_patient_id boolean,
    dq_patient_not_found boolean,
    dq_missing_encounter_id boolean,
    dq_encounter_not_found boolean,
    dq_stop_before_start boolean,
    dq_negative_amount boolean,
    dq_duplicate_candidate_key boolean,
    dq_conversion_errors text[],
    dq_has_conversion_error boolean
);

COMMENT ON TABLE staging.stg_procedures IS
    'One row per source performed procedure occurrence from raw.synthea_procedures; candidate composite keys are flagged but not enforced.';

COMMIT;
